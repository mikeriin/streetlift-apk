import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device.dart';

import 'timers.dart';
export 'timers.dart' show TimerCtl;
import 'app_theme.dart';
import 'ui.dart';
import 'models.dart';
import 'rewards.dart' show checkLevelUp;
import 'store.dart';
import 'estimate_view.dart';
import 'pilotage_screen.dart';

const _tab = [FontFeature.tabularFigures()];

// ============================= TIMER =====================================
// Basé sur l'horloge murale : reste juste même si l'app passe en arrière-plan.

String fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Espace insécable avant les unités (« 3\u00A0min », « 90\u00A0s »).
String nbsp(String t) => t.replaceAllMapped(
  RegExp(r'(\d) (kg|s|min|reps|lb)\b'),
  (m) => '${m[1]}\u00A0${m[2]}',
);

// ============================ SÉANCE =====================================

class SessionScreen extends StatefulWidget {
  final WeekPlan week;
  final DayPlan day;
  const SessionScreen({super.key, required this.week, required this.day});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final ctl = TimerCtl();
  final pageCtl = PageController();
  late final List<List<Exercise>> groups;
  int page = 0;

  int get nPages => groups.length;

  @override
  void initState() {
    super.initState();
    groups = store.groups(widget.day);
    if (store.settings.wakelock) keepAwake(true);
  }

  @override
  void dispose() {
    keepAwake(false);
    store.flush();
    ctl.dispose();
    pageCtl.dispose();
    super.dispose();
  }

  void _confirmClear() {
    final w = widget.week;
    final d = widget.day;
    final head = w.n == 0 ? w.block : 'S${w.n} · J${d.j}';
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Supprimer l\u2019historique ?'),
            content: Text(
              '$head — séries, notes et statut « fait » seront effacés. Action irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: SL.action,
                  foregroundColor: KPalette.light,
                ),
                onPressed: () {
                  store.clearSession(w.n, d.j);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Historique de $head supprimé.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  void _go(int target) {
    FocusManager.instance.primaryFocus?.unfocus();
    store.saveLogs(affectsProgression: false);
    if (MediaQuery.of(context).disableAnimations) {
      pageCtl.jumpToPage(target);
    } else {
      pageCtl.animateToPage(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _chooseExercise() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: .65,
            builder:
                (context, controller) => ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Dans cette séance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (var i = 0; i < nPages; i++)
                      ListTile(
                        selected: i == page,
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(
                          groups[i]
                              .map((e) => store.splitName(e.name).$1)
                              .join(' + '),
                        ),
                        subtitle:
                            groups[i].length > 1
                                ? const Text('Exercices enchaînés')
                                : null,
                        onTap: () => Navigator.pop(context, i),
                      ),
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text('Bilan de séance'),
                      selected: page == nPages,
                      onTap: () => Navigator.pop(context, nPages),
                    ),
                  ],
                ),
          ),
    );
    if (selected != null && mounted) _go(selected);
  }

  void _instructions() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consignes de séance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(widget.day.conduite),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
  );

  @override
  Widget build(BuildContext context) {
    final w = widget.week;
    final d = widget.day;
    final restDay = d.exercises.isEmpty;
    final head = w.n == 0 ? w.block : 'S${w.n} · J${d.j}';
    return KScreen(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restDay ? 'Récupération' : d.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              head,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options de séance',
            onSelected: (value) {
              if (value == 'clear') _confirmClear();
              if (value == 'instructions') _instructions();
              // Report d'un test (S2, S12…) dans la feuille Pilotage sans
              // quitter la séance : même écran que depuis STATS.
              if (value == 'pilotage') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PilotageScreen()),
                );
              }
            },
            itemBuilder:
                (_) => [
                  if (d.conduite.isNotEmpty)
                    const PopupMenuItem(
                      value: 'instructions',
                      child: Text('Consignes de séance'),
                    ),
                  const PopupMenuItem(
                    value: 'pilotage',
                    child: Text('Références (feuille Pilotage)'),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('Effacer l’historique'),
                  ),
                ],
          ),
        ],
      ),
      body:
          restDay
              ? _RestDay(week: w, day: d)
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.page,
                      0,
                      KSpace.page,
                      4,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                page == nPages
                                    ? 'Bilan de séance'
                                    : '${groups[page].length > 1 ? 'Enchaînement' : 'Exercice'} ${page + 1} / $nPages',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            // Texte agrandi (200 %) sur 320 px : le bouton
                            // partage la ligne au lieu de la faire déborder.
                            Flexible(
                              child: TextButton.icon(
                                onPressed: _chooseExercise,
                                icon: const Icon(Icons.list_alt, size: 18),
                                label: const Text(
                                  'Exercices',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SessionProgressDots(
                          count: nPages + 1,
                          index: page,
                          color: SL.action,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pageCtl,
                      onPageChanged: (i) {
                        store.saveLogs(affectsProgression: false);
                        setState(() => page = i);
                      },
                      itemCount: nPages + 1,
                      itemBuilder:
                          (_, i) =>
                              i < nPages
                                  ? SessionExercisePage(
                                    key: ValueKey(groups[i].first.id),
                                    week: w,
                                    day: d,
                                    exs: groups[i],
                                    timer: ctl,
                                  )
                                  : _FinishPage(week: w, day: d),
                    ),
                  ),
                  _TimerBar(ctl: ctl),
                ],
              ),
      bottomNavigationBar:
          restDay || MediaQuery.of(context).viewInsets.bottom > 0
              ? null
              : KBottomActions(
                child: KActionRow(
                  children: [
                    OutlinedButton.icon(
                      onPressed: page > 0 ? () => _go(page - 1) : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Précédent'),
                    ),
                    FilledButton.icon(
                      onPressed: page < nPages ? () => _go(page + 1) : null,
                      icon: const Icon(Icons.chevron_right),
                      iconAlignment: IconAlignment.end,
                      label: Text(page == nPages - 1 ? 'Bilan' : 'Suivant'),
                    ),
                  ],
                ),
              ),
    );
  }
}

class SessionProgressDots extends StatelessWidget {
  final int count;
  final int index;
  final Color color;

  const SessionProgressDots({
    super.key,
    required this.count,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${index + 1} sur $count',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 5,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration:
                    MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: i == index ? 26 : 7,
                height: 5,
                decoration: BoxDecoration(
                  color: i == index ? color : SL.dot,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------- PAGE EXERCICE(S) ------------------------------
// Une page = un exercice, ou une paire enchaînée (ex. dips → pompes).

class SessionExercisePage extends StatefulWidget {
  final WeekPlan week;
  final DayPlan day;
  final List<Exercise> exs;
  final TimerCtl timer;
  final SessionLog? history;
  final Set<String> unresolvedIds;
  bool get readOnly => history != null;
  const SessionExercisePage({
    super.key,
    required this.week,
    required this.day,
    required this.exs,
    required this.timer,
    this.history,
    this.unresolvedIds = const {},
  });

  @override
  State<SessionExercisePage> createState() => SessionExercisePageState();
}

class SessionExercisePageState extends State<SessionExercisePage> {
  late final List<ExerciseLog> logs;
  late final List<LogSpec> specs;
  final Set<int> _notesOpen = {};
  int epoch = 0; // force la recréation des champs (reprise du précédent…)

  @override
  void initState() {
    super.initState();
    logs = [
      for (final e in widget.exs)
        if (widget.readOnly)
          widget.history!.ex[e.id] ?? ExerciseLog()
        else
          store.exLog(widget.week.n, widget.day.j, e),
    ];
    specs = [for (final e in widget.exs) store.logSpec(e)];
    for (var k = 0; k < widget.exs.length; k++) {
      if (!widget.readOnly) _prefill(widget.exs[k], specs[k], logs[k]);
      if (logs[k].note.isNotEmpty) _notesOpen.add(k);
    }
    if (!widget.readOnly) {
      _planned = [
        for (var k = 0; k < widget.exs.length; k++)
          store.plannedReps(widget.exs[k], specs[k], logs[k].sets.length),
      ];
      _signature = _labels();
      store.addListener(_onStore);
    }
  }

  @override
  void dispose() {
    if (!widget.readOnly) store.removeListener(_onStore);
    super.dispose();
  }

  // ---- Feuille Pilotage modifiée pendant la séance (LC1) ----
  // Les volumes (séries continues, séries de référence, clusters) suivent
  // les maxima : la page se recalcule aussitôt, et les reps pré-remplies des
  // séries non validées suivent le nouveau volume. Une saisie de
  // l'utilisateur (valeur différente du pré-remplissage) n'est jamais écrasée.
  List<List<int?>> _planned = const [];
  String _signature = '';

  String _labels() => [
    for (final e in widget.exs) '${store.setsLabel(e)}|${store.loadLabel(e)}',
  ].join('\n');

  void _onStore() {
    if (!mounted) return;
    final signature = _labels();
    if (signature == _signature) return;
    _signature = signature;
    var changed = false;
    for (var k = 0; k < widget.exs.length; k++) {
      if (widget.exs[k].sets.type != 'volume') continue;
      final next = store.plannedReps(
        widget.exs[k],
        specs[k],
        logs[k].sets.length,
      );
      final previous = _planned[k];
      for (var i = 0; i < logs[k].sets.length; i++) {
        final set = logs[k].sets[i];
        if (set.done || i >= previous.length || i >= next.length) continue;
        if (previous[i] != null &&
            next[i] != null &&
            set.reps == '${previous[i]}' &&
            previous[i] != next[i]) {
          set.reps = '${next[i]}';
          changed = true;
        }
      }
      _planned[k] = next;
    }
    setState(() {
      if (changed) epoch++;
    });
    if (changed) store.saveLogs(affectsProgression: false);
  }

  void _prefill(Exercise ex, LogSpec sp, ExerciseLog log) {
    if (widget.readOnly || !store.settings.prefill) return;
    if (sp.kind == 'hold' && sp.seconds != null) {
      for (final s in log.sets) {
        if (s.reps.isEmpty && !s.done) s.reps = '${sp.seconds}';
      }
    } else if (sp.kind == 'duration' && sp.seconds != null) {
      for (final s in log.sets) {
        if (s.reps.isEmpty && !s.done) s.reps = '${sp.seconds! ~/ 60}';
      }
    }
    if (sp.kind == 'reps' || sp.kind == 'emom') {
      final planned = store.plannedReps(ex, sp, log.sets.length);
      for (var i = 0; i < log.sets.length; i++) {
        final s = log.sets[i];
        if (s.reps.isEmpty && !s.done && planned[i] != null) {
          s.reps = '${planned[i]}';
        }
      }
    }
    if (sp.kind == 'duration' || sp.kind == 'interval') return;
    final kg = store.loadFor(ex);
    if (kg != null && kg > 0) {
      final t =
          kg == kg.roundToDouble()
              ? kg.toInt().toString()
              : kg.toStringAsFixed(1);
      for (final s in log.sets) {
        if (s.kg.isEmpty && !s.done) s.kg = t;
      }
    }
  }

  /// Charge ou volume sans sa référence (KT-007) : « à renseigner » / « ? »
  /// reste à sa place (pas de ligne en plus) ; la référence manquante est
  /// nommée pour le lecteur d'écran et l'infobulle, et un appui ouvre
  /// Références. Rien n'est calculé à sa place.
  Widget _missingReference(Exercise ex, bool readOnly, Widget child) {
    final ref = readOnly ? null : store.missingReference(ex);
    if (ref == null) return child;
    final message =
        'Référence non renseignée : ${store.referenceLabel(ref)}. '
        'Touche pour ouvrir Références.';
    return Tooltip(
      key: ValueKey('missing-ref-${ex.id}'),
      message: message,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: message,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PilotageScreen()),
              ),
          child: child,
        ),
      ),
    );
  }

  void _checkSet(int k, int i) {
    if (widget.readOnly) return;
    final ex = widget.exs[k];
    final sp = specs[k];
    final log = logs[k];
    final s = log.sets[i];
    setState(() {
      s.done = !s.done;
      s.completedAt = s.done ? DateTime.now().toIso8601String() : null;
    });
    if (store.settings.vibration) HapticFeedback.lightImpact();
    store.saveLogs();
    if (s.done) _celebrateRecord(ex, s);
    if (!s.done || !store.settings.autoTimer) return;
    if (widget.exs.length == 2 && k == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              'Enchaîne : ${store.splitName(widget.exs[1].name).$1}',
            ),
          ),
        );
      return;
    }
    final rest = store.restAfterSet(ex, sp, i, log.sets.length);
    if (rest != null && rest > 0) widget.timer.startRest(rest);
  }

  /// Record en direct : la série validée bat le meilleur 1RM estimé (ou le
  /// maximum de reps au poids de corps) de cet exercice dans les autres
  /// séances. Bannière courte, retour haptique plus marqué.
  void _celebrateRecord(Exercise ex, SetEntry s) {
    if (!store.settings.celebrations) return;
    final hit = store.liveRecord(
      store.sessionKey(widget.week.n, widget.day.j),
      ex.name,
      s.kg,
      s.reps,
    );
    if (hit == null || !mounted) return;
    if (store.settings.vibration) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: SL.bordeaux,
          content: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RECORD · ${store.splitName(ex.name).$1} · ${hit.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  void _reusePrevious(int k, ExerciseLog prev) {
    if (widget.readOnly) return;
    final log = logs[k];
    for (var i = 0; i < log.sets.length && i < prev.sets.length; i++) {
      final s = log.sets[i];
      if (s.done) continue;
      final p = prev.sets[i];
      if (p.kg.isNotEmpty) s.kg = p.kg;
      if (p.reps.isNotEmpty) s.reps = p.reps;
    }
    store.saveLogs(affectsProgression: false);
    setState(() => epoch++);
  }

  void _showCue(Exercise ex) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (context) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consignes · ${store.splitName(ex.name).$1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (ex.cue.isNotEmpty) Text(ex.cue),
                const SizedBox(height: 12),
                if (!widget.readOnly)
                  EstimateView(estimate: store.exerciseEstimate(ex)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: PageStorageKey('exercise-scroll-${widget.exs.first.id}'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(KSpace.page, 2, KSpace.page, 10),
    children: [
      for (var k = 0; k < widget.exs.length; k++) ...[
        if (k > 0) const SizedBox(height: 12),
        _block(k),
      ],
    ],
  );

  Widget _block(int k) {
    final ex = widget.exs[k];
    final sp = specs[k];
    final log = logs[k];
    final chained = widget.exs.length == 2;
    final readOnly = widget.readOnly;
    final unresolved = widget.unresolvedIds.contains(ex.id);
    // Lift principal en rouge d'accent ; prévention en gris ; le reste neutre.
    final accent =
        ex.main
            ? SL.accent
            : ex.prevention
            ? SL.prevViolet
            : SL.text;
    final finalRest =
        !readOnly && sp.myo
            ? store.restAfterSet(ex, sp, log.sets.length - 1, log.sets.length)
            : null;
    final (title, subtitle) = store.splitName(ex.name);
    final interval = ex.interval;
    final noLoad =
        sp.kind == 'duration' ||
        sp.kind == 'interval' ||
        sp.kind == 'emom' ||
        sp.kind == 'amrap';
    final showKg =
        readOnly
            ? log.sets.any((s) => s.kg.isNotEmpty)
            : !noLoad && store.showKgFor(ex, log);
    final showRir =
        readOnly
            ? log.sets.any((s) => s.rir.isNotEmpty)
            : sp.kind == 'reps' && store.showRirFor(log);
    final showV =
        readOnly
            ? log.sets.any((s) => s.v.isNotEmpty)
            : sp.kind == 'reps' && store.showVFor(ex, log);
    final recordedLoads =
        log.sets.map((s) => s.kg).where((s) => s.isNotEmpty).toSet();
    final loadLabel =
        readOnly
            ? (recordedLoads.length == 1 ? '${recordedLoads.single} kg' : '—')
            : store.loadLabel(ex);
    final showBigLoad =
        (readOnly || !noLoad) &&
        loadLabel != '—' &&
        (loadLabel != 'PdC' || showKg);
    final kindLabel = _kindLabel(sp);
    final showIntensity =
        ex.intensity.isNotEmpty &&
        !kindLabel.toLowerCase().startsWith(ex.intensity.toLowerCase());
    final prev =
        !readOnly && widget.week.n > 0
            ? store.previousLog(widget.week.n, widget.day.j, ex)
            : null;

    return KCard(
      key: ValueKey('exercise-card-${ex.id}'),
      accent: accent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- Carte prescription -----
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chained)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _chip(
                      k == 0 ? 'ENCHAÎNÉ · A' : 'ENCHAÎNÉ · B',
                      SL.accent,
                      small: true,
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.2,
                              color: SL.text,
                            ),
                          ),
                          if (subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: SL.dim,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!readOnly || (!unresolved && ex.cue.isNotEmpty))
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: IconButton(
                          key: ValueKey('${ex.id}-instructions'),
                          tooltip: 'Consignes de l’exercice',
                          icon: Icon(
                            Icons.info_outline,
                            size: 20,
                            color: SL.dim,
                          ),
                          onPressed: () => _showCue(ex),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                _missingReference(
                  ex,
                  readOnly,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showBigLoad) ...[
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              loadLabel,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                color: accent,
                                height: 1,
                                fontFeatures: _tab,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          readOnly
                              ? '${log.sets.where((s) => s.done).length} / ${log.sets.length} séries validées'
                              : nbsp(store.setsLabel(ex)),
                          style: TextStyle(
                            fontSize: showBigLoad ? 16 : 20,
                            fontWeight: FontWeight.w600,
                            color: showBigLoad ? SL.text : accent,
                            fontFeatures: _tab,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (!unresolved) _chip(kindLabel, SL.accent),
                    if (readOnly) _chip('Enregistré', SL.success),
                    if (!readOnly && showIntensity)
                      _chip(nbsp(ex.intensity), accent),
                    if (!readOnly && ex.tempo.isNotEmpty)
                      _chip(nbsp(ex.tempo), SL.dim),
                    if (!readOnly && ex.rest.isNotEmpty && ex.rest != '—')
                      _chip('Repos ${nbsp(ex.rest)}', SL.dim),
                    if (finalRest != null)
                      _chip('Repos final ${fmt(finalRest)}', SL.dim),
                  ],
                ),
                if (prev != null) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _reusePrevious(k, prev.log),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 15, color: SL.dim),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'S${prev.week} · ${store.summarize(prev.log, kg: showKg)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: SL.dim,
                                fontSize: 12.5,
                                fontFeatures: _tab,
                              ),
                            ),
                          ),
                          Text(
                            'Reprendre',
                            style: TextStyle(
                              color: SL.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ----- Chronos de mode -----
          if (!readOnly && interval != null && ex.timer == null)
            _big(
              SL.bordeaux,
              Icons.timer,
              'Lancer ${interval.rounds}× ${interval.work}\u00A0s / ${interval.rest}\u00A0s',
              () => widget.timer.startInterval(
                interval.rounds,
                interval.work,
                interval.rest,
              ),
            ),
          if (!readOnly && ex.timer != null && !sp.cluster)
            _modeButton(ex, SL.bordeaux),
          if (!readOnly && ex.timer == null && sp.kind == 'emom')
            _big(
              SL.bordeaux,
              Icons.timer,
              'Lancer EMOM ${sp.seconds! ~/ 60}\u00A0min',
              () => widget.timer.emom(sp.seconds! ~/ 60, 60),
            ),
          if (!readOnly && ex.timer == null && sp.kind == 'duration')
            _big(
              SL.bordeaux,
              Icons.timer,
              'Lancer ${sp.seconds! ~/ 60}\u00A0min',
              () => widget.timer.single('DURÉE', sp.seconds!),
            ),
          if (!readOnly && sp.cluster && sp.intra != null)
            _big(
              SL.action,
              Icons.av_timer,
              'Intra-cluster ${sp.intra}\u00A0s',
              () => widget.timer.single('INTRA', sp.intra!, prepare: false),
            ),
          // ----- Logger : en-tête de colonnes + lignes -----
          _HeaderRow(
            spec: sp,
            showKg: showKg,
            showRir: showRir,
            showV: showV,
            hasTimer: !readOnly && sp.timed,
            valueLabel: unresolved ? 'VALEUR' : null,
            effortLabel: readOnly ? 'EFFORT' : null,
          ),
          for (var i = 0; i < log.sets.length; i++)
            _SetRow(
              key: ValueKey('${ex.id}-$i-$epoch'),
              label: store.setLabel(sp, i),
              entry: log.sets[i],
              spec: sp,
              showKg: showKg,
              showRir: showRir,
              showV: showV,
              readOnly: readOnly,
              onCheck: readOnly ? null : () => _checkSet(k, i),
              onTimer:
                  readOnly
                      ? null
                      : sp.kind == 'hold'
                      ? () => widget.timer.single(
                        'TENUE',
                        int.tryParse(log.sets[i].reps) ?? sp.seconds ?? 30,
                      )
                      : sp.kind == 'holdMax'
                      ? () => widget.timer.stopwatch('MAX')
                      : sp.kind == 'duration'
                      ? () => widget.timer.single(
                        'DURÉE',
                        (int.tryParse(log.sets[i].reps) ??
                                (sp.seconds! ~/ 60)) *
                            60,
                      )
                      : null,
            ),
          if (readOnly && log.sets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune série enregistrée.',
                style: TextStyle(color: SL.dim),
              ),
            ),
          if (!readOnly)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retirer une série',
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (log.removeLastSet()) {
                        store.saveLogs(affectsProgression: false);
                        setState(() {});
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Ajouter une série',
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      log.addSet();
                      _prefill(ex, sp, log);
                      store.saveLogs(affectsProgression: false);
                      setState(() {});
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${log.sets.length} séries',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('${ex.id}-note-toggle'),
                    tooltip:
                        _notesOpen.contains(k)
                            ? 'Masquer la note'
                            : log.note.isEmpty
                            ? 'Ajouter une note'
                            : 'Afficher la note',
                    icon: Icon(
                      log.note.isEmpty ? Icons.note_add_outlined : Icons.notes,
                      size: 20,
                      color:
                          _notesOpen.contains(k) || log.note.isNotEmpty
                              ? SL.accent
                              : SL.dim,
                    ),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        if (!_notesOpen.add(k)) _notesOpen.remove(k);
                      });
                    },
                  ),
                  if (!noLoad)
                    PopupMenuButton<String>(
                      tooltip: 'Colonnes',
                      icon: Icon(Icons.tune, size: 20, color: SL.dim),
                      onSelected: (v) {
                        setState(() {
                          if (v == 'kg') log.showKg = !showKg;
                          if (v == 'rir') log.showRir = !showRir;
                          if (v == 'v') log.showV = !showV;
                        });
                        store.saveLogs(affectsProgression: false);
                      },
                      itemBuilder:
                          (_) => [
                            CheckedPopupMenuItem(
                              value: 'kg',
                              checked: showKg,
                              child: const Text('Charge (kg)'),
                            ),
                            if (sp.kind == 'reps')
                              CheckedPopupMenuItem(
                                value: 'rir',
                                checked: showRir,
                                child: Text(store.settings.rpe ? 'RPE' : 'RIR'),
                              ),
                            if (sp.kind == 'reps')
                              CheckedPopupMenuItem(
                                value: 'v',
                                checked: showV,
                                child: const Text('Vitesse (m/s)'),
                              ),
                          ],
                    ),
                ],
              ),
            ),
          if (_notesOpen.contains(k)) ...[
            const SizedBox(height: 4),
            if (readOnly)
              InputDecorator(
                decoration: logDeco().copyWith(labelText: 'Notes'),
                child: Text(log.note, style: TextStyle(color: SL.text)),
              )
            else
              TextFormField(
                key: ValueKey('${ex.id}-note'),
                initialValue: log.note,
                minLines: 1,
                maxLines: 3,
                textAlign: TextAlign.left,
                decoration: logDeco(
                  hint: 'Sensations, ajustements…',
                ).copyWith(labelText: 'Notes'),
                onChanged: (value) {
                  log.note = value;
                  store.saveLogs(affectsProgression: false);
                },
              ),
          ],
        ],
      ),
    );
  }

  /// Bouton plein de la charte : fond bordeaux ou rouge, texte blanc cassé.
  Widget _big(Color c, IconData ic, String label, VoidCallback action) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: c,
            foregroundColor: KPalette.light,
          ),
          icon: Icon(ic),
          label: Text(label),
          onPressed: action,
        ),
      );

  Widget _modeButton(Exercise ex, Color accent) {
    final tm = ex.timer!;
    switch (tm['type'] as String) {
      case 'emom':
        final r = tm['rounds'] as int, itv = tm['interval'] as int;
        return _big(
          accent,
          Icons.timer,
          'Lancer EMOM $r × $itv\u00A0s',
          () => widget.timer.emom(r, itv),
        );
      case 'amrap':
        final s = tm['sec'] as int;
        return _big(
          accent,
          Icons.timer,
          'Lancer AMRAP ${s ~/ 60}\u00A0min',
          () => widget.timer.single('AMRAP', s),
        );
      case 'hiit':
        final r = tm['rounds'] as int,
            wk = tm['work'] as int,
            rs = tm['rest'] as int;
        return _big(
          accent,
          Icons.timer,
          'Lancer $r× $wk\u00A0s / $rs\u00A0s',
          () => widget.timer.startInterval(r, wk, rs),
        );
      case 'hold':
        final s = tm['sec'] as int;
        return _big(
          accent,
          Icons.timer,
          'Chrono $s\u00A0s',
          () => widget.timer.single('TENUE', s),
        );
    }
    return const SizedBox.shrink();
  }

  String _kindLabel(LogSpec sp) {
    const labels = {
      'reps': 'Reps',
      'repsMax': 'Max de reps',
      'hold': 'Tenue chronométrée',
      'holdMax': 'Max de temps',
      'duration': 'Durée',
      'interval': 'Intervalles',
      'emom': 'EMOM',
      'amrap': 'AMRAP',
    };
    if (sp.myo) return 'Myo-reps · intra ${sp.intra}\u00A0s';
    if (sp.cluster) return 'Clusters · intra ${sp.intra}\u00A0s';
    return labels[sp.kind] ?? sp.kind;
  }

  Widget _chip(String t, Color c, {bool small = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9, vertical: 2),
    decoration: BoxDecoration(
      color: c.withValues(alpha: SL.dark ? 0.09 : 0.07),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      t,
      style: TextStyle(
        fontSize: small ? 10 : 11.5,
        fontWeight: FontWeight.w400,
        color: c,
        letterSpacing: small ? 0.5 : 0,
      ),
    ),
  );
}

// --- Disposition commune en-tête / lignes : mêmes flex, mêmes largeurs fixes.
const double _wLabel = 26;
const double _wBtn = 44;
const _gap = SizedBox(width: 6);

bool _splitColumns(
  BuildContext context,
  bool kg,
  bool rir,
  bool velocity,
  bool hasTimer,
) {
  final count = 1 + (kg ? 1 : 0) + (rir ? 1 : 0) + (velocity ? 1 : 0);
  final width = MediaQuery.sizeOf(context).width.clamp(0.0, KSpace.maxWidth);
  final available =
      width -
      2 * KSpace.page -
      24 -
      _wLabel -
      _wBtn -
      (hasTimer ? _wBtn + 6 : 0) -
      (count + 1) * 6;
  return count > 2 &&
      available / count < MediaQuery.textScalerOf(context).scale(64);
}

class _HeaderRow extends StatelessWidget {
  final LogSpec spec;
  final bool showKg, showRir, showV, hasTimer;
  final String? valueLabel, effortLabel;
  const _HeaderRow({
    required this.spec,
    required this.showKg,
    required this.showRir,
    required this.showV,
    required this.hasTimer,
    this.valueLabel,
    this.effortLabel,
  });

  @override
  Widget build(BuildContext context) {
    final k = spec.kind;
    final second =
        k == 'hold' || k == 'holdMax'
            ? 'S'
            : k == 'duration'
            ? 'MIN'
            : k == 'repsMax'
            ? 'REPS MAX'
            : 'REPS';
    final compact = _splitColumns(context, showKg, showRir, showV, hasTimer);
    final st = TextStyle(
      color: SL.dim,
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
    );
    Widget h(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t, textAlign: TextAlign.center, style: st),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
      child: Row(
        children: [
          SizedBox(
            width: _wLabel,
            child: Text(
              'N°',
              semanticsLabel: 'Numéro de série',
              textAlign: TextAlign.center,
              style: st,
            ),
          ),
          _gap,
          if (showKg) ...[h('kg', 3), _gap],
          h(valueLabel ?? second, k == 'repsMax' ? 4 : 3),
          if (showRir && !compact) ...[
            _gap,
            h(effortLabel ?? store.effortLabel.toUpperCase(), 2),
          ],
          if (showV && !compact) ...[_gap, h('M/S', 3)],
          _gap,
          if (hasTimer) ...[const SizedBox(width: _wBtn), _gap],
          const SizedBox(width: _wBtn),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final String label;
  final SetEntry entry;
  final LogSpec spec;
  final bool showKg, showRir, showV;
  final bool readOnly;
  final VoidCallback? onCheck;
  final VoidCallback? onTimer;
  const _SetRow({
    super.key,
    required this.label,
    required this.entry,
    required this.spec,
    required this.showKg,
    required this.showRir,
    required this.showV,
    required this.onCheck,
    this.readOnly = false,
    this.onTimer,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController kg, reps, rir, v;
  final _fieldFocus = <TextEditingController, FocusNode>{};

  @override
  void initState() {
    super.initState();
    kg = TextEditingController(text: widget.entry.kg);
    reps = TextEditingController(text: widget.entry.reps);
    rir = TextEditingController(text: widget.entry.rir);
    v = TextEditingController(text: widget.entry.v);
  }

  @override
  void dispose() {
    for (final focus in _fieldFocus.values) {
      focus.dispose();
    }
    for (final c in [kg, reps, rir, v]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _f(
    TextEditingController c,
    void Function(String) on, {
    int flex = 3,
    bool decimal = true,
    String? label,
  }) {
    if (widget.readOnly) {
      return Flexible(
        flex: flex,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            heightFactor: 1,
            child: InputDecorator(
              decoration: logDeco().copyWith(labelText: label),
              child: Text(
                c.text.isEmpty ? '–' : c.text,
                textAlign: TextAlign.center,
                style: KControl.numberStyle.copyWith(color: SL.text),
              ),
            ),
          ),
        ),
      );
    }
    final focus = _fieldFocus.putIfAbsent(c, FocusNode.new);
    void selectAll() {
      focus.requestFocus();
      c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
    }

    return Flexible(
      flex: flex,
      // La cellule visible fait 36 px ; ses marges restent touchables.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: selectAll,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            heightFactor: 1,
            child: TextField(
              controller: c,
              focusNode: focus,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: KControl.numberStyle.copyWith(color: SL.text),
              decoration: logDeco(hint: '–').copyWith(labelText: label),
              onTap: selectAll,
              onChanged: (text) {
                on(text);
                store.saveLogs(affectsProgression: false);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final k = widget.spec.kind;
    final done = e.done;
    final compact = _splitColumns(
      context,
      widget.showKg,
      widget.showRir,
      widget.showV,
      widget.onTimer != null,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: _wLabel,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: done ? SL.success : SL.dim,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                    fontFeatures: _tab,
                  ),
                ),
              ),
              _gap,
              if (widget.showKg) ...[_f(kg, (t) => e.kg = t), _gap],
              _f(
                reps,
                (t) => e.reps = t,
                flex: k == 'repsMax' ? 4 : 3,
                decimal: false,
              ),
              if (widget.showRir && !compact) ...[
                _gap,
                _f(rir, (t) => e.rir = t, flex: 2),
              ],
              if (widget.showV && !compact) ...[_gap, _f(v, (t) => e.v = t)],
              _gap,
              if (widget.onTimer != null) ...[
                SizedBox(
                  width: _wBtn,
                  height: _wBtn,
                  child: IconButton(
                    onPressed: widget.onTimer,
                    icon: Icon(
                      k == 'holdMax'
                          ? Icons.timer_outlined
                          : Icons.hourglass_bottom,
                      size: KControl.iconSize,
                    ),
                    color: SL.accent,
                    tooltip:
                        k == 'holdMax' ? 'Chrono montant' : 'Compte à rebours',
                  ),
                ),
                _gap,
              ],
              SizedBox(
                width: _wBtn,
                height: _wBtn,
                child:
                    widget.readOnly
                        ? Semantics(
                          label:
                              'Série ${widget.label} ${done ? "validée" : "non validée"}',
                          child: Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    done
                                        ? SL.success.withValues(alpha: .14)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Icon(
                                done ? Icons.check : Icons.remove,
                                size: KControl.iconSize,
                                color: done ? SL.success : SL.dim,
                              ),
                            ),
                          ),
                        )
                        : Tooltip(
                          message:
                              done
                                  ? 'Annuler la série ${widget.label}'
                                  : 'Valider la série ${widget.label}',
                          child: Center(
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    done
                                        ? SL.success.withValues(alpha: 0.14)
                                        : Colors.transparent,
                                foregroundColor: done ? SL.success : SL.dim,
                              ),
                              isSelected: done,
                              icon: const Icon(
                                Icons.check,
                                size: KControl.iconSize,
                              ),
                              onPressed: widget.onCheck,
                            ),
                          ),
                        ),
              ),
            ],
          ),
          if (compact && (widget.showRir || widget.showV)) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const SizedBox(width: _wLabel + 6),
                if (widget.showRir)
                  _f(
                    rir,
                    (t) => e.rir = t,
                    label: widget.readOnly ? 'Effort' : store.effortLabel,
                  ),
                if (widget.showRir && widget.showV) _gap,
                if (widget.showV) _f(v, (t) => e.v = t, label: 'Vitesse (m/s)'),
                SizedBox(
                  width: _wBtn + 6 + (widget.onTimer != null ? _wBtn + 6 : 0),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// --------------------------- BARRE TIMER ---------------------------------

class _TimerBar extends StatelessWidget {
  final TimerCtl ctl;
  const _TimerBar({required this.ctl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) {
        if (!ctl.visible) return const SizedBox.shrink();
        final done = !ctl.running;
        final frac =
            ctl.up ? 1.0 : (ctl.total == 0 ? 0.0 : ctl.remaining / ctl.total);
        final effort =
            ctl.label.startsWith('EFFORT') ||
            ctl.label == 'TENUE' ||
            ctl.label == 'MAX';
        // Chiffres en blanc cassé (charte) ; le libellé porte l'état :
        // vert = terminé, rouge d'alerte = effort, accent = repos.
        final labelColor =
            done
                ? SL.success
                : effort
                ? SL.danger
                : SL.accent;
        final fill =
            done
                ? SL.success
                : effort
                ? SL.action
                : null;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          decoration: BoxDecoration(
            color: SL.surface,
            border:
                effort && ctl.running
                    ? Border.all(color: SL.action, width: 2)
                    : null,
            borderRadius: BorderRadius.circular(28),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KProgressBar(
                  value: done ? 1 : frac,
                  height: 5,
                  color: fill,
                  track: SL.progressTrack,
                  semanticsLabel: 'Chrono ${ctl.label}',
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        ctl.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          ctl.up
                              ? fmt(ctl.elapsed)
                              : (done ? '0:00' : fmt(ctl.remaining)),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: done ? SL.success : SL.text,
                            fontFeatures: _tab,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!ctl.up) ...[
                      TextButton(
                        onPressed: done ? null : () => ctl.add(-15),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: const Text('\u221215'),
                      ),
                      TextButton(
                        onPressed: done ? null : () => ctl.add(15),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: const Text('+15'),
                      ),
                    ],
                    IconButton(
                      onPressed: ctl.stop,
                      icon: Icon(
                        done ? Icons.close : Icons.stop_circle,
                        size: KControl.iconSize,
                      ),
                      tooltip: done ? 'Fermer' : 'Arrêter',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------- FIN & JOUR DE REPOS ---------------------------

class _FinishPage extends StatelessWidget {
  final WeekPlan week;
  final DayPlan day;
  const _FinishPage({required this.week, required this.day});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final log = store.sessionLog(week.n, day.j);
    var doneSets = 0;
    var totalSets = 0;
    for (final ex in day.exercises) {
      final l = store.exLog(week.n, day.j, ex);
      totalSets += l.sets.length;
      doneSets += l.sets.where((s) => s.done).length;
    }
    final title = week.n == 0 ? week.block : 'S${week.n} · J${day.j}';
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              log.done ? Icons.emoji_events : Icons.flag,
              size: 64,
              color: SL.accent,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$doneSets / $totalSets séries validées',
              style: TextStyle(color: SL.dim, fontFeatures: _tab),
            ),
            if (totalSets > 0) ...[
              const SizedBox(height: 4),
              Builder(
                builder: (context) {
                  final goal = store.game.sessionGoal;
                  final reached = doneSets / totalSets >= goal - 1e-9;
                  return Text(
                    'Objectif de séance : ≥ ${(goal * 100).round()} % des séries · ${reached ? 'atteint' : 'pas encore'}',
                    style: TextStyle(
                      color: reached ? SL.success : SL.dim,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 6),
            Text(
              log.done
                  ? 'XP et bonus ajoutés à ta progression'
                  : '+${week.n == 0 ? 60 : 100} XP de base + bonus éventuels',
              style: TextStyle(
                color: SL.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: log.done ? SL.card : SL.bordeaux,
                foregroundColor: log.done ? SL.dim : Colors.white,
                minimumSize: const Size(220, KControl.buttonHeight),
              ),
              icon: Icon(log.done ? Icons.undo : Icons.check_circle),
              label: Text(
                log.done ? 'Repasser en « à faire »' : 'Terminer la séance',
              ),
              onPressed: () {
                final wasDone = log.done;
                store.markSessionDone(week.n, day.j, !wasDone, title: title);
                if (wasDone) return;
                // Le bilan part d'ici, quel que soit l'écran qui a ouvert la
                // séance (accueil, Arsenal, notification de rappel) : il ne
                // dépend plus d'un appel au retour. Son décompte attend que
                // la séance soit refermée et sauvegardée.
                final nav = Navigator.of(context);
                final closing = ModalRoute.of(context)?.completed;
                nav.pop();
                checkLevelUp(nav.context, after: closing);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  final WeekPlan week;
  final DayPlan day;
  const _RestDay({required this.week, required this.day});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final done = store.isDone(week.n, day.j);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 60, color: SL.accent),
            const SizedBox(height: 14),
            const Text(
              'REPOS COMPLET',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              day.conduite.isEmpty
                  ? 'Marche, mobilité légère, sommeil maximal. GtG suspendu. Note ta HRV et ta FC de repos.'
                  : day.conduite,
              textAlign: TextAlign.center,
              style: TextStyle(color: SL.dim, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: done ? SL.card : SL.success,
                foregroundColor: done ? SL.dim : SL.onAccent,
                minimumSize: const Size(220, KControl.buttonHeight),
              ),
              icon: Icon(done ? Icons.undo : Icons.check),
              label: Text(done ? 'Marqué fait' : 'Marquer comme fait'),
              onPressed:
                  () => store.markSessionDone(
                    week.n,
                    day.j,
                    !done,
                    title: 'S${week.n} · J${day.j}',
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
