import 'dart:async';

import 'package:flutter/material.dart';
import 'device.dart';

import 'timers.dart';
export 'timers.dart' show WodClock;
import 'levelup.dart';
import 'app_theme.dart';
import 'ui.dart';
import 'store.dart';
import 'wod_formats.dart';
import 'wod_models.dart';
import 'wod_preview.dart';

/// Les formats chronométrés portent l'accent de la charte ; une routine sans
/// chrono reste neutre. Le vert est réservé à la validation.
Color wodColor(String type) => type == 'routine' ? SL.dim : SL.accent;

String fmtT(int s) => clockText(s);

/// Nombre entier saisi : chiffres seulement (espaces autour tolérés), de 0
/// à [max]. Vide, signe, décimale, texte ou valeur trop grande : null.
int? parseCount(String? text, {int max = 1000000}) {
  final t = (text ?? '').trim();
  if (!RegExp(r'^\d{1,7}$').hasMatch(t)) return null;
  final n = int.parse(t);
  return n > max ? null : n;
}

int? parseT(String text) {
  final normalized = text
      .trim()
      .replaceAll('’', ':')
      .replaceAll("'", ':')
      .replaceAll('"', '');
  if (!RegExp(r'^\d+(?::\d{1,2}){0,2}$').hasMatch(normalized)) return null;
  final parts = normalized.split(':').map(int.parse).toList();
  if (parts.skip(1).any((v) => v >= 60)) return null;
  final seconds = parts.fold(0, (sum, part) => sum * 60 + part);
  return seconds > 86400 ? null : seconds;
}

// ============================ EXÉCUTION ================================

class WodRunScreen extends StatefulWidget {
  final String wodId;
  const WodRunScreen({super.key, required this.wodId});
  @override
  State<WodRunScreen> createState() => _WodRunScreenState();
}

class _WodRunScreenState extends State<WodRunScreen> {
  /// Horloge du store : contrôlable en test, comme la date des résultats.
  final clock = WodClock(now: () => store.storeClock());

  /// Tentative autorisée au lancement du chrono (KT-003) : elle garde le
  /// droit de valider son score même si l'essai du jour change à minuit.
  String? _attempt;

  Wod get w => store.wods.firstWhere((x) => x.id == widget.wodId);

  @override
  void initState() {
    super.initState();
    if (store.settings.wakelock &&
        store.wods.any((w) => w.id == widget.wodId && store.canRun(w))) {
      keepAwake(true);
    }
    clock.addListener(_onClock);
  }

  @override
  void dispose() {
    store.abandonAttempt(_attempt);
    keepAwake(false);
    clock.removeListener(_onClock);
    clock.dispose();
    super.dispose();
  }

  bool _prompted = false;
  bool _scoreOpen = false;
  bool _allowExit = false;
  void _onClock() {
    if (mounted && clock.finished && !_prompted && !_scoreOpen) {
      _prompted = true;
      Future.microtask(() {
        if (mounted) _score();
      });
    }
  }

  void _start() {
    if (!store.canFinish(w, _attempt)) return;
    _attempt ??= store.startAttempt(w);
    if (_attempt == null) return;
    _prompted = false;
    final wod = w;
    final phases = phasesOf(wod);
    if (phases != null) {
      clock.startPhases(phases, prep: store.settings.prepSec);
    } else if (wod.type == 'amrap') {
      clock.startCountdown(wod.minutes * 60);
    } else if (wod.type == 'emom') {
      clock.startEmom(wod.rounds, wod.interval);
    } else {
      clock.startStopwatch(cap: wod.minutes * 60);
    }
  }

  void _round() {
    final wod = w;
    if (!clock.running || clock.restLeft > 0) return;
    final finalRound = wod.type == 'rounds' && clock.round + 1 >= wod.rounds;
    clock.lap(rest: finalRound ? 0 : wod.restSec);
    if (wod.type == 'rounds' && wod.rounds > 0 && clock.round >= wod.rounds) {
      clock.stop();
      _score();
    }
  }

  Future<void> _score() async {
    if (!mounted || _scoreOpen || !store.canFinish(w, _attempt)) return;
    _scoreOpen = true;
    clock.stop();
    final wod = w;
    final result = await showModalBottomSheet<WodResult>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => ScoreSheet(
            wod: wod,
            elapsed: clock.phased ? clock.workElapsed : clock.elapsed,
            laps: clock.round,
            clockFinished: clock.finished,
            capHit: clock.capHit,
          ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _scoreOpen = false);
      return;
    }
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // La feuille reste « ouverte » pendant l'enregistrement : pas de second
    // score pour la même tentative.
    final saved = await store.recordWodResult(wod, result, attempt: _attempt);
    if (!mounted) return;
    setState(() => _scoreOpen = false);
    if (saved == ResultSave.denied) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Score non enregistré : cette tentative n’est plus ouverte.',
          ),
        ),
      );
      return;
    }
    _attempt = null;
    clock.reset();
    if (saved == ResultSave.saved) {
      checkLevelUp(context);
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        content: const Text(
          'Score gardé mais pas encore enregistré sur le téléphone : réessaie avant de fermer l’application.',
        ),
        action: SnackBarAction(
          label: 'Réessayer',
          onPressed: () async {
            if (await store.retrySave() && nav.mounted) {
              checkLevelUp(nav.context);
            }
          },
        ),
      ),
    );
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Quitter le WOD ?'),
            content: const Text(
              'Le chrono sera arrêté. Enregistre ton score avant de quitter si tu veux le conserver.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuer'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Quitter'),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      store.abandonAttempt(_attempt);
      _attempt = null;
      setState(() => _allowExit = true);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.wods.any((x) => x.id == widget.wodId)) {
          return const KScreen(body: SizedBox.shrink());
        }
        final wod = w;
        // Débloqué, essai du jour ou tentative déjà autorisée : sinon la fiche
        // d'achat tient lieu d'accès.
        if (!store.canFinish(wod, _attempt)) {
          return WodPreviewScreen(wodId: wod.id);
        }
        final c = wodColor(wod.type);
        final best = wod.best();
        final results = wod.results.reversed.toList();
        return ListenableBuilder(
          listenable: clock.active,
          builder:
              (context, _) => PopScope(
                canPop: _allowExit || !clock.started,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop) _leave();
                },
                child: KScreen(
                  appBar: AppBar(
                    title: Text(
                      wod.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Aperçu : volume, charge, muscles',
                        icon: const Icon(Icons.insights),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => WodPreviewScreen(
                                      wodId: wod.id,
                                      fromRunner: true,
                                    ),
                              ),
                            ),
                      ),
                    ],
                  ),
                  body: KList(
                    children: [
                      // ----- chrono -----
                      ListenableBuilder(
                        listenable: clock,
                        builder: (context, _) {
                          final phase = clock.phase;
                          final main =
                              phase != null && !clock.finished
                                  ? clock.phaseRemaining
                                  : clock.countdown
                                  ? clock.remaining
                                  : clock.elapsed;
                          // Chiffres blanc cassé au repos ou à l'arrêt, accent
                          // pendant l'effort, alerte au time cap.
                          final col =
                              clock.capHit
                                  ? SL.danger
                                  : (clock.running && clock.restLeft == 0
                                      ? c
                                      : SL.text);
                          String sub = '';
                          if (phase != null) {
                            sub =
                                clock.finished
                                    ? 'TERMINÉ'
                                    : 'Reste au total ${fmtT(clock.remaining)}';
                          } else if (wod.type == 'emom' && clock.started) {
                            sub =
                                'Minute ${clock.emomRound}/${clock.emomRounds}';
                          } else if (wod.type == 'rounds' && wod.rounds > 0) {
                            sub = 'Round ${clock.round}/${wod.rounds}';
                          } else if (clock.round > 0) {
                            sub =
                                '${clock.round} round${clock.round > 1 ? 's' : ''}';
                          }
                          if (clock.restLeft > 0) {
                            sub = 'REPOS ${fmtT(clock.restLeft)}  ·  $sub';
                          }
                          if (clock.capHit) sub = 'TIME CAP  ·  $sub';
                          return KCard(
                            outline: clock.capHit ? SL.action : null,
                            child: Column(
                              children: [
                                if (phase != null && !clock.finished) ...[
                                  // Phase nommée en toutes lettres : jamais
                                  // par la seule couleur. Annoncée une fois
                                  // par changement (pas chaque seconde).
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      phaseTitle(wod, phase),
                                      key: const ValueKey('wod-phase'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            phase.kind == PhaseKind.work
                                                ? c
                                                : SL.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    phaseDetail(wod, phase),
                                    key: const ValueKey('wod-phase-detail'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: SL.dim),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    fmtT(main),
                                    key: const ValueKey('wod-clock'),
                                    style: TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.w500,
                                      color: col,
                                      height: 1,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                if (sub.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      sub,
                                      style: TextStyle(
                                        color: SL.dim,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                KActionRow(
                                  children: [
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            clock.running
                                                ? SL.card
                                                : SL.bordeaux,
                                        foregroundColor:
                                            clock.running
                                                ? SL.text
                                                : Colors.white,
                                        side:
                                            clock.running
                                                ? BorderSide(
                                                  color: SL.formBorder,
                                                )
                                                : null,
                                      ),
                                      icon: Icon(
                                        clock.running
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      label: Text(
                                        clock.finished
                                            ? 'Terminé'
                                            : clock.started
                                            ? (clock.running
                                                ? 'Pause'
                                                : 'Reprendre')
                                            : 'Démarrer',
                                      ),
                                      onPressed:
                                          clock.finished
                                              ? null
                                              : () =>
                                                  clock.started
                                                      ? clock.toggle()
                                                      : _start(),
                                    ),
                                    if (wod.type != 'emom' && phasesOf(wod) == null)
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: SL.accent,
                                        ),
                                        icon: const Icon(Icons.flag),
                                        label: const Text('Valider round'),
                                        onPressed:
                                            clock.running && clock.restLeft == 0
                                                ? _round
                                                : null,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: KControl.gap),
                                KActionRow(
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: SL.success,
                                      ),
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Terminer'),
                                      onPressed: clock.started ? _score : null,
                                    ),
                                    TextButton.icon(
                                      onPressed:
                                          clock.started ? clock.reset : null,
                                      icon: const Icon(Icons.restart_alt),
                                      label: const Text('Réinitialiser'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // ----- entête + mouvements -----
                      KCard(
                        accent: c,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${wod.typeLabel}${wod.header().isNotEmpty ? '  ·  ${wod.header()}' : ''}',
                              style: TextStyle(
                                color: c,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final l in wod.lines)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  l,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            if (wod.notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                wod.notes,
                                style: TextStyle(
                                  color: SL.dim,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              ruleText(wod),
                              key: const ValueKey('wod-rule'),
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: SL.text,
                              ),
                            ),
                            if (wod.source.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '@${wod.source}',
                                  style: TextStyle(color: SL.dim, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // ----- résultats -----
                      const KSection('Résultats'),
                      if (results.isEmpty)
                        const KEmpty(
                          icon: Icons.emoji_events_outlined,
                          title: 'Ton premier score',
                          message:
                              'Termine ce WOD pour enregistrer un résultat et suivre tes records.',
                        ),
                      for (final r in results)
                        KCard(
                          padding: EdgeInsets.zero,
                          child: ListTile(
                            leading:
                                identical(r, best)
                                    ? CircleAvatar(
                                      backgroundColor: SL.action,
                                      foregroundColor: KPalette.light,
                                      child: const Icon(Icons.emoji_events),
                                    )
                                    : Icon(Icons.timer_outlined, color: SL.dim),
                            title: Text(
                              r.score,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: identical(r, best) ? SL.accent : SL.text,
                              ),
                            ),
                            subtitle: Text(
                              [
                                '${_date(r.at)}${r.notes.isNotEmpty ? ' · ${r.notes}' : ''}',
                                if (historicalNote(wod, r) case final note?)
                                  note,
                              ].join('\n'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              tooltip: 'Supprimer ce résultat',
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: SL.dim,
                              ),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: const Text(
                                          'Supprimer ce résultat ?',
                                        ),
                                        content: Text(r.score),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, false),
                                            child: const Text('Annuler'),
                                          ),
                                          FilledButton(
                                            onPressed:
                                                () => Navigator.pop(ctx, true),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirmed == true) {
                                  store.deleteWodResult(wod, r);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }

  String _date(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

/// Saisie du score selon la règle du WOD (`wod_formats.dart`). Rien n'est
/// rempli à la place de l'utilisateur, sauf ce que l'écran a réellement
/// observé : le temps du chrono et les rounds validés d'un appui.
class ScoreSheet extends StatefulWidget {
  final Wod wod;
  final int elapsed, laps;
  final bool clockFinished, capHit;
  const ScoreSheet({
    super.key,
    required this.wod,
    required this.elapsed,
    this.laps = 0,
    this.clockFinished = false,
    this.capHit = false,
  });
  @override
  State<ScoreSheet> createState() => ScoreSheetState();
}

class ScoreSheetState extends State<ScoreSheet> {
  final form = GlobalKey<FormState>();
  late final ScoreRule rule = ruleFor(widget.wod);
  late final WodFormat? format = structuredFormat(widget.wod);
  late final time = TextEditingController(
    text: widget.elapsed > 0 ? fmtT(widget.elapsed) : '',
  );
  late final main = TextEditingController(
    text: (rule == ScoreRule.amrap && widget.laps > 0) ? '${widget.laps}' : '',
  );
  final reps = TextEditingController();
  final notes = TextEditingController();
  late final List<List<TextEditingController>> cells = [
    if (format?.kind == 'tabata')
      for (var b = 0; b < format!.movements.length; b++)
        [for (var i = 0; i < format!.sets; i++) TextEditingController()],
  ];

  /// Réalisation : `null` tant que ni l'écran ni l'utilisateur ne l'a fixée.
  late bool? completed = _initialCompletion();

  bool? _initialCompletion() {
    final w = widget.wod;
    switch (rule) {
      case ScoreRule.time:
        if (widget.capHit) return false;
        if (w.type == 'rounds' && w.rounds > 0 && widget.laps >= w.rounds) {
          return true;
        }
        return null; // For Time : choix explicite, jamais supposé.
      case ScoreRule.none:
        return !widget.capHit;
      case ScoreRule.deathBy:
        return true; // l'échec est la fin normale
      default:
        return widget.clockFinished;
    }
  }

  @override
  void dispose() {
    for (final c in [time, main, reps, notes, for (final b in cells) ...b]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _sent = false;

  List<List<int?>> get _intervals => [
    for (final b in cells) [for (final c in b) parseCount(c.text, max: 999)],
  ];

  bool get _tabataFilled =>
      cells.every((b) => b.every((c) => c.text.trim().isNotEmpty));

  String? _countValidator(String? text, {int max = 1000000}) =>
      parseCount(text, max: max) == null ? 'Nombre entier de 0 à $max' : null;

  WodResult? _build() {
    final w = widget.wod;
    final at = store.storeClock().toIso8601String();
    final done = completed ?? false;
    WodResult r;
    switch (rule) {
      case ScoreRule.time:
      case ScoreRule.none:
        final text = time.text.trim();
        r = WodResult(
          at: at,
          score: '',
          seconds: text.isEmpty ? null : parseT(text),
          rounds: widget.laps,
          completed: done,
        );
      case ScoreRule.amrap:
        r = WodResult(
          at: at,
          score: '',
          seconds: widget.elapsed,
          rounds: parseCount(main.text),
          reps: parseCount(reps.text),
          completed: done,
        );
      case ScoreRule.emomMinutes:
      case ScoreRule.deathBy:
      case ScoreRule.amrapBlocks:
        r = WodResult(
          at: at,
          score: '',
          seconds: widget.elapsed,
          rounds: parseCount(main.text),
          completed: done,
        );
      case ScoreRule.emomReps:
        r = WodResult(
          at: at,
          score: '',
          seconds: widget.elapsed,
          reps: parseCount(main.text),
          completed: done,
        );
      case ScoreRule.tabata:
        final intervals = _intervals;
        final minima = tabataMinima(
          WodResult(at: at, score: '', intervals: intervals),
        );
        final total =
            minima.any((m) => m == null)
                ? null
                : minima.fold<int>(0, (a, b) => a + b!);
        r = WodResult(
          at: at,
          score: '',
          seconds: widget.elapsed > 0 ? widget.elapsed : null,
          reps: done ? total : null,
          completed: done,
          intervals: intervals,
        );
    }
    r
      ..scoring = rule.id
      ..notes = notes.text.trim();
    r.score = scoreText(w, r);
    return r;
  }

  void _save() {
    // Double appui : un seul score renvoyé, la feuille ne se ferme qu'une fois.
    if (_sent || !form.currentState!.validate()) return;
    _sent = true;
    Navigator.pop(context, _build());
  }

  Widget _completion() {
    final ranked = rule.ranked;
    return FormField<bool>(
      validator: (_) {
        if (completed == null) {
          return 'Indique si le WOD a été terminé en entier.';
        }
        if (completed == true && rule == ScoreRule.tabata && !_tabataFilled) {
          return 'Intervalles non renseignés : complète-les ou choisis « Incomplet ».';
        }
        return null;
      },
      builder:
          (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                value: true,
                groupValue: completed,
                title: Text(
                  rule == ScoreRule.tabata
                      ? 'Tabata terminé, tous les intervalles saisis'
                      : 'Terminé en entier',
                ),
                onChanged: (v) {
                  setState(() => completed = v);
                  field.didChange(v);
                },
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                value: false,
                groupValue: completed,
                title: const Text('Incomplet'),
                subtitle: Text(
                  ranked
                      ? 'Gardé dans l’historique, ne compte pas comme record.'
                      : 'Gardé dans l’historique.',
                ),
                onChanged: (v) {
                  setState(() => completed = v);
                  field.didChange(v);
                },
              ),
              if (field.hasError)
                Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
    );
  }

  List<Widget> _fields() {
    final w = widget.wod;
    switch (rule) {
      case ScoreRule.time:
      case ScoreRule.none:
        final optional = rule == ScoreRule.none;
        return [
          TextFormField(
            controller: time,
            keyboardType: TextInputType.datetime,
            style: KControl.numberStyle,
            decoration: InputDecoration(
              labelText:
                  optional
                      ? 'Temps (mm:ss, facultatif)'
                      : 'Temps (mm:ss ou hh:mm:ss)',
            ),
            validator: (text) {
              final t = (text ?? '').trim();
              if (optional && t.isEmpty) return null;
              final seconds = parseT(t) ?? 0;
              if (seconds <= 0) {
                return 'Saisis un temps valide supérieur à zéro.';
              }
              if (rule == ScoreRule.time &&
                  completed == true &&
                  w.minutes > 0 &&
                  seconds > w.minutes * 60) {
                return 'Au-delà du time cap (${w.minutes} min) : choisis « Incomplet ».';
              }
              return null;
            },
          ),
        ];
      case ScoreRule.amrap:
        return [
          KFieldGrid(
            children: [
              TextFormField(
                controller: main,
                keyboardType: TextInputType.number,
                style: KControl.numberStyle,
                decoration: const InputDecoration(labelText: 'Rounds complets'),
                validator: _countValidator,
              ),
              TextFormField(
                controller: reps,
                keyboardType: TextInputType.number,
                style: KControl.numberStyle,
                decoration: const InputDecoration(
                  labelText: '+ reps du round en cours',
                ),
                validator: _countValidator,
              ),
            ],
          ),
        ];
      case ScoreRule.emomMinutes:
      case ScoreRule.deathBy:
        final label =
            rule == ScoreRule.deathBy
                ? 'Dernière minute réussie (0 à ${w.rounds})'
                : 'Minutes tenues (0 à ${w.rounds})';
        return [
          TextFormField(
            controller: main,
            keyboardType: TextInputType.number,
            style: KControl.numberStyle,
            decoration: InputDecoration(labelText: label),
            validator: (t) => _countValidator(t, max: w.rounds),
          ),
        ];
      case ScoreRule.emomReps:
        return [
          TextFormField(
            controller: main,
            keyboardType: TextInputType.number,
            style: KControl.numberStyle,
            decoration: InputDecoration(labelText: 'Total de ${format!.unit}'),
            validator: _countValidator,
          ),
        ];
      case ScoreRule.amrapBlocks:
        return [
          TextFormField(
            controller: main,
            keyboardType: TextInputType.number,
            style: KControl.numberStyle,
            decoration: const InputDecoration(
              labelText: 'Rounds au total (tous blocs)',
            ),
            validator: _countValidator,
          ),
        ];
      case ScoreRule.tabata:
        final f = format!;
        return [
          for (var b = 0; b < f.movements.length; b++) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                '${b + 1}. ${f.movements[b]} — ${_minLabel(b)}',
                key: ValueKey('tabata-block-$b'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < f.sets; i++)
                  SizedBox(
                    width: 76,
                    child: Semantics(
                      label:
                          '${f.movements[b]}, intervalle ${i + 1} sur ${f.sets}',
                      child: TextFormField(
                        key: ValueKey('tabata-$b-$i'),
                        controller: cells[b][i],
                        keyboardType: TextInputType.number,
                        style: KControl.numberStyle,
                        decoration: InputDecoration(labelText: '${i + 1}'),
                        onChanged: (_) => setState(() {}),
                        validator: (t) {
                          if ((t ?? '').trim().isEmpty) return null;
                          return parseCount(t, max: 999) == null
                              ? '0-999'
                              : null;
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ];
    }
  }

  String _minLabel(int b) {
    final values = [for (final c in cells[b]) parseCount(c.text, max: 999)];
    if (values.any((v) => v == null)) {
      final filled = values.where((v) => v != null).length;
      return '$filled/${values.length} intervalles saisis';
    }
    return 'plus faible : ${values.cast<int>().reduce((a, b) => a < b ? a : b)}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        KSpace.page,
        KControl.formGap,
        KSpace.page,
        MediaQuery.viewInsetsOf(context).bottom + KSpace.page,
      ),
      child: Form(
        key: form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SCORE',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              ruleText(widget.wod),
              key: const ValueKey('score-rule'),
              style: TextStyle(color: SL.dim, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 8),
            ..._fields(),
            _completion(),
            const SizedBox(height: KControl.formGap),
            TextField(
              controller: notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (RX, adaptation, pénalités…)',
              ),
            ),
            const SizedBox(height: 14),
            KActionRow(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
