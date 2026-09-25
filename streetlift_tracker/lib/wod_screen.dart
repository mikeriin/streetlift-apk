import 'dart:async';

import 'package:flutter/material.dart';
import 'device.dart';

import 'timers.dart';
export 'timers.dart' show WodClock;
import 'levelup.dart';
import 'app_theme.dart';
import 'ui.dart';
import 'store.dart';
import 'wod_models.dart';
import 'wod_preview.dart';

/// Les formats chronométrés portent l'accent de la charte ; une routine sans
/// chrono reste neutre. Le vert est réservé à la validation.
Color wodColor(String type) => type == 'routine' ? SL.dim : SL.accent;

String fmtT(int s) {
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
  final ss = r.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
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
  final clock = WodClock();

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
    if (wod.type == 'amrap') {
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
          (_) => _ScoreSheet(
            wod: wod,
            elapsed: clock.elapsed,
            rounds:
                wod.type == 'emom'
                    ? clock.elapsed ~/ wod.interval
                    : clock.round,
            completed:
                !clock.capHit &&
                (wod.type != 'rounds' || clock.round >= wod.rounds),
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
                          final main =
                              clock.countdown ? clock.remaining : clock.elapsed;
                          // Chiffres blanc cassé au repos ou à l'arrêt, accent
                          // pendant l'effort, alerte au time cap.
                          final col =
                              clock.capHit
                                  ? SL.danger
                                  : (clock.running && clock.restLeft == 0
                                      ? c
                                      : SL.text);
                          String sub = '';
                          if (wod.type == 'emom' && clock.started) {
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
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    fmtT(main),
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
                                    if (wod.type != 'emom')
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
                              '${_date(r.at)}${r.notes.isNotEmpty ? ' · ${r.notes}' : ''}',
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

class _ScoreSheet extends StatefulWidget {
  final Wod wod;
  final int elapsed, rounds;
  final bool completed;
  const _ScoreSheet({
    required this.wod,
    required this.elapsed,
    required this.rounds,
    required this.completed,
  });
  @override
  State<_ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<_ScoreSheet> {
  final form = GlobalKey<FormState>();
  late final time = TextEditingController(text: fmtT(widget.elapsed));
  late final rounds = TextEditingController(text: '${widget.rounds}');
  final reps = TextEditingController(text: '0');
  final notes = TextEditingController();
  late bool completed = widget.completed;

  @override
  void dispose() {
    for (final c in [time, rounds, reps, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _count(String? text) {
    final n = int.tryParse(text ?? '');
    return n == null || n < 0 || n > 1000000
        ? 'Nombre entier positif ou nul'
        : null;
  }

  bool _sent = false;

  void _save() {
    // Double appui : un seul score renvoyé, la feuille ne se ferme qu'une fois.
    if (_sent || !form.currentState!.validate()) return;
    _sent = true;
    final at = store.storeClock().toIso8601String();
    if (widget.wod.timed) {
      final seconds = parseT(time.text)!;
      Navigator.pop(
        context,
        WodResult(
          at: at,
          seconds: seconds,
          rounds: widget.rounds,
          score: '${completed ? '' : 'Incomplet · '}${fmtT(seconds)}',
          completed: completed,
          notes: notes.text.trim(),
        ),
      );
    } else {
      final rd = int.parse(rounds.text), rp = int.parse(reps.text);
      Navigator.pop(
        context,
        WodResult(
          at: at,
          seconds: widget.elapsed,
          rounds: rd,
          reps: rp,
          notes: notes.text.trim(),
          score: '$rd round${rd > 1 ? 's' : ''}${rp > 0 ? ' + $rp' : ''}',
        ),
      );
    }
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
            const SizedBox(height: 8),
            if (widget.wod.timed) ...[
              TextFormField(
                controller: time,
                keyboardType: TextInputType.datetime,
                style: KControl.numberStyle,
                decoration: const InputDecoration(
                  labelText: 'Temps (mm:ss ou hh:mm:ss)',
                ),
                validator:
                    (text) =>
                        (parseT(text ?? '') ?? 0) <= 0
                            ? 'Saisis un temps valide supérieur à zéro.'
                            : null,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: completed,
                title: const Text('WOD entièrement terminé'),
                subtitle: const Text(
                  'Un résultat incomplet ne compte pas comme record.',
                ),
                onChanged:
                    (value) => setState(() => completed = value ?? false),
              ),
            ] else
              KFieldGrid(
                children: [
                  TextFormField(
                    controller: rounds,
                    keyboardType: TextInputType.number,
                    style: KControl.numberStyle,
                    decoration: const InputDecoration(
                      labelText: 'Rounds terminés',
                    ),
                    validator: _count,
                  ),
                  TextFormField(
                    controller: reps,
                    keyboardType: TextInputType.number,
                    style: KControl.numberStyle,
                    decoration: const InputDecoration(labelText: '+ reps'),
                    validator: _count,
                  ),
                ],
              ),
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
