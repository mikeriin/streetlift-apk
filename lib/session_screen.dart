import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalis_core/kalis_core.dart'
    as kc
    show Flames, IntraSessionAction, Place, SetKind, SetTechniqueKind;
import 'package:kalis_koach/kalis_koach.dart' show KoachUsage;
import 'device.dart';

import 'adapt/adapt_summary_screen.dart';
import 'adapt/adapt_texts.dart';
import 'adapt/flame_track.dart';
import 'adapt/health_check.dart';
import 'plan/coach_texts.dart' as ct;
import 'koach/koach_bubble.dart'
    show
        KoachSays,
        KoachToastColors,
        koachLargeText,
        koachPose,
        koachSnackBar,
        showKoachSheet;

import 'timers.dart';
export 'timers.dart' show TimerCtl;
import 'app_theme.dart';
import 'ui.dart';
import 'wellbeing_screens.dart' show SafetyScreen;
import 'models.dart';
import 'rewards.dart' show checkLevelUp;
import 'store.dart';
import 'estimate_view.dart';
import 'pilotage_screen.dart';
import 'set_validation.dart' show checkSet;

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

/// Écrans de journée ouverts (séance ou historique), du plus ancien au plus
/// récent : une notification ou un appui répété ramène à l'écran existant au
/// lieu d'empiler une seconde séance (KT-018).
final List<({String key, Route<dynamic> route})> openDayRoutes = [];

/// Enregistre l'écran de journée [key] (si ce n'est déjà fait).
void registerDayRoute(String key, Route<dynamic>? route) {
  if (route == null || openDayRoutes.any((e) => identical(e.route, route))) {
    return;
  }
  openDayRoutes.add((key: key, route: route));
}

void unregisterDayRoute(Route<dynamic>? route) =>
    openDayRoutes.removeWhere((e) => identical(e.route, route));

class SessionScreen extends StatefulWidget {
  final WeekPlan week;
  final DayPlan day;

  /// Ouvrir sur l'exercice en cours (reprise). Faux pour une correction
  /// depuis l'historique : on repart du premier exercice.
  final bool resume;
  const SessionScreen({
    super.key,
    required this.week,
    required this.day,
    this.resume = true,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final ctl = TimerCtl();
  late final PageController pageCtl;
  late List<List<Exercise>> groups;
  int page = 0;
  Route<dynamic>? _route;

  /// Page « Bilan du jour » avant l'exercice 1 (G9) : seulement dans une
  /// séance servie par le moteur dynamique (G10 : la page « Koach · séance
  /// du jour » de L7/L11 est retirée).
  late final bool koachPage;
  int get koachPages => koachPage ? 1 : 0;

  /// Nombre de pages d'exercices (hors page Koach et bilan).
  int get nPages => groups.length;

  /// Index de la page du bilan.
  int get bilanPage => koachPages + nPages;

  /// Index de l'exercice de la page courante (−1 sur la page Koach).
  int get exerciseIndex => page - koachPages;

  /// G9 : séance servie par `kalis_adapt` (bilan santé, charges du moteur,
  /// flammes et conseils) ; décidé une fois à l'ouverture.
  late final bool adaptOn;

  /// G9 : journée servie par le moteur dynamique ; sinon celle du
  /// programme.
  DayPlan get _day {
    if (adaptOn) {
      final a = store.sessionAdapt(widget.week.n, widget.day.j);
      if (a != null) return store.adaptDay(widget.week.n, widget.day, a);
    }
    return widget.day;
  }

  List<List<Exercise>> _groups() => store.groups(_day);

  /// Séance adaptée (bilan, temps, lieu) : pages recalculées.
  void _adapted(bool changed) {
    if (!changed || !mounted) return;
    setState(() {
      groups = _groups();
      if (page > bilanPage) page = bilanPage;
    });
    if (pageCtl.hasClients) pageCtl.jumpToPage(page);
  }

  @override
  void initState() {
    super.initState();
    // CI1c : une séance non commencée est recalculée à chaque ouverture
    // d'après l'état courant (programme, ajustements, réglages).
    store.refreshUnstartedSession(widget.week.n, widget.day);
    adaptOn = store.adaptOpen(widget.week.n, widget.day) != null;
    groups = _groups();
    koachPage = adaptOn;
    // Reprise : même occurrence (même clé de journal), ouverte sur
    // l'exercice en cours (une séance entamée saute la page Koach). Le
    // repos n'est pas relancé (décision 26/09).
    final resumed = widget.resume
        ? store.resumePage(widget.week.n, widget.day.j, groups)
        : 0;
    page = resumed > 0 ? koachPages + resumed : 0;
    pageCtl = PageController(initialPage: page);
    if (store.settings.wakelock) keepAwake(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
    registerDayRoute(store.sessionKey(widget.week.n, widget.day.j), _route);
  }

  @override
  void dispose() {
    unregisterDayRoute(_route);
    keepAwake(false);
    // CI1c : une simple consultation ne laisse aucune entrée d'historique.
    store.forgetConsultation(widget.week.n, widget.day.j);
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
      builder: (ctx) => AlertDialog(
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
              backgroundColor: SL.alert,
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
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .65,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Dans cette séance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            if (koachPage)
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Bilan du jour'),
                selected: page == 0,
                onTap: () => Navigator.pop(context, 0),
              ),
            for (var i = 0; i < nPages; i++)
              ListTile(
                selected: i == exerciseIndex,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(
                  groups[i].map((e) => store.splitName(e.name).$1).join(' + '),
                ),
                subtitle: groups[i].length > 1
                    ? const Text('Exercices enchaînés')
                    : null,
                onTap: () => Navigator.pop(context, koachPages + i),
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Bilan de séance'),
              selected: page == bilanPage,
              onTap: () => Navigator.pop(context, bilanPage),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) _go(selected);
  }

  /// G9 : « J'ai seulement… minutes » → temps disponible du bilan.
  Future<void> _adaptMinutes() async {
    final a = store.sessionAdapt(widget.week.n, widget.day.j);
    final m = await showMinutesSheet(context, a?.check?.minutesAvailable);
    if (m == null || !mounted) return;
    store.adaptSetMinutes(widget.week.n, widget.day, m == 0 ? null : m);
    _adapted(true);
    _go(0);
  }

  /// G9 : « Je m'entraîne ailleurs » → lieu du jour du moteur.
  Future<void> _adaptPlace() async {
    final a = store.sessionAdapt(widget.week.n, widget.day.j);
    final code = await showPlaceChoiceSheet(context, a?.place);
    if (code == null || !mounted) return;
    kc.Place? place;
    for (final p in kc.Place.values) {
      if (p.code == code) place = p;
    }
    store.adaptSetPlace(widget.week.n, widget.day, place);
    _adapted(true);
    _go(0);
  }

  void _instructions() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
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
              if (value == 'bilan') _go(0);
              // G9 : temps et lieu du jour passés au moteur dynamique.
              if (adaptOn && value == 'compress') {
                _adaptMinutes();
                return;
              }
              if (adaptOn && value == 'place') {
                _adaptPlace();
                return;
              }
              // Report d'un test (S2, S12…) dans la feuille Pilotage sans
              // quitter la séance : même écran que depuis STATS.
              // L13 (KT-073) : douleur ou signal d'alerte pendant la séance.
              if (value == 'safety') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SafetyScreen()),
                );
              }
              if (value == 'pilotage') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PilotageScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              if (d.conduite.isNotEmpty)
                const PopupMenuItem(
                  value: 'instructions',
                  child: Text('Consignes de séance'),
                ),
              if (adaptOn)
                const PopupMenuItem(
                  value: 'bilan',
                  child: Text('Bilan du jour'),
                ),
              // G10 : seulement dans une séance servie par le moteur (les
              // adaptations de L11 sont retirées).
              if (adaptOn && w.n >= 1 && !restDay) ...[
                const PopupMenuItem(
                  value: 'compress',
                  child: Text('J’ai seulement… minutes'),
                ),
                const PopupMenuItem(
                  value: 'place',
                  child: Text('Je m’entraîne ailleurs'),
                ),
              ],
              const PopupMenuItem(
                value: 'safety',
                child: Text('Douleur ou malaise ?'),
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
      body: restDay
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
                              page == bilanPage
                                  ? 'Bilan de séance'
                                  : exerciseIndex < 0
                                  ? 'Bilan du jour'
                                  : '${groups[exerciseIndex].length > 1 ? 'Enchaînement' : 'Exercice'} ${exerciseIndex + 1} / $nPages',
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
                        count: bilanPage + 1,
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
                    itemCount: bilanPage + 1,
                    itemBuilder: (_, i) => i < koachPages
                        ? HealthCheckPage(
                            key: const ValueKey('session-health-page'),
                            week: w,
                            base: widget.day,
                            onChanged: () => _adapted(true),
                            onStart: () => _go(koachPages),
                          )
                        : i < bilanPage
                        ? SessionExercisePage(
                            key: ValueKey(
                              '${groups[i - koachPages].first.id}|${groups[i - koachPages].length}|${store.setCount(groups[i - koachPages].first)}',
                            ),
                            week: w,
                            day: _day,
                            exs: groups[i - koachPages],
                            timer: ctl,
                            baseDay: widget.day,
                            adapt: adaptOn,
                            onSessionChanged: () => setState(() {}),
                          )
                        : _FinishPage(
                            week: w,
                            day: _day,
                            base: widget.day,
                            adapt: adaptOn,
                          ),
                  ),
                ),
                _TimerBar(ctl: ctl),
              ],
            ),
      // 5.5.2 (demande du propriétaire, 29/09/2026) : plus de boutons
      // Précédent / Suivant, le glissement d'une page à l'autre suffit ; le
      // bouton « Exercices » et les points restent pour se repérer.
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
                duration: MediaQuery.of(context).disableAnimations
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

  /// Séance du programme avant l'ajustement du moteur, et rappel quand la
  /// séance change.
  final DayPlan? baseDay;
  final VoidCallback? onSessionChanged;

  /// G9 : séance servie par `kalis_adapt` (charges et cibles du moteur,
  /// conseils après chaque série).
  final bool adapt;
  bool get readOnly => history != null;
  const SessionExercisePage({
    super.key,
    required this.week,
    required this.day,
    required this.exs,
    required this.timer,
    this.history,
    this.unresolvedIds = const {},
    this.baseDay,
    this.onSessionChanged,
    this.adapt = false,
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
    for (final e in widget.exs)
      '${store.setsLabel(e)}|${store.loadLabel(e, week: widget.week.n, day: widget.day.j)}',
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
    if (widget.readOnly) return;
    // G9 : cibles du moteur, série par série (toujours pré-remplies : la
    // séance du jour est celle du moteur).
    if (ex.engine) {
      store.adaptPrefill(widget.week.n, widget.day.j, ex, log);
      return;
    }
    if (!store.settings.prefill) return;
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
    final kg = store.sessionLoad(widget.week.n, ex, day: widget.day.j);
    if (kg != null && kg > 0) {
      final t = store.kgFieldText(kg);
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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PilotageScreen()),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Problème de saisie affiché sous une série (KT-009) : (exercice, série).
  final Map<(int, int), SetCheck> _issues = {};

  /// G9 correction 1 : série validée ouverte (ligne des flammes) par
  /// exercice ; les autres séries validées sont résumées en une ligne. -1 :
  /// aucune. Absente : la dernière validée tant que l'exercice n'est pas
  /// fini (série n − 1 ouverte, n − 2 et avant résumées).
  final Map<int, int> _openSet = {};

  /// Première notation en flammes : l'échelle expliquée sous cette série.
  (int, int)? _introAt;

  int _openOf(int k) {
    final o = _openSet[k];
    if (o != null) return o;
    final sets = logs[k].sets;
    if (!sets.any((s) => !s.done)) return -1;
    for (var i = sets.length - 1; i >= 0; i--) {
      if (sets[i].done) return i;
    }
    return -1;
  }

  // ---- Flammes (G9, D5.3-D5.5) ----

  /// La série se note en flammes : répétitions ou tenues, hors
  /// échauffement et mobilité (et, servie par le moteur, quand une
  /// difficulté est visée).
  bool _needsFlames(Exercise ex, LogSpec sp) {
    const kinds = {'reps', 'repsMax', 'hold', 'holdMax'};
    if (!kinds.contains(sp.kind)) return false;
    const roles = {'warmup', 'mobility', 'cooldown', 'ramp'};
    if (roles.contains(ex.role)) return false;
    if (ex.name.toLowerCase().contains('échauffement')) return false;
    if (ex.engine) {
      final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
      if (it != null && it.targetFlames == null && it.kind == null) {
        return false;
      }
    }
    return true;
  }

  /// Flammes visées de la série [i] : celles du moteur, sinon le RIR de la
  /// consigne, 10 pour un test au maximum.
  int? _targetFlames(Exercise ex, LogSpec sp, int i) {
    final g = store.adaptGoal(widget.week.n, widget.day.j, ex, i);
    if (g?.flames != null) return g!.flames;
    if (sp.kind == 'repsMax' || sp.kind == 'holdMax') return kc.Flames.failure;
    final m = RegExp(
      r'RIR\s*(\d+(?:[.,]\d+)?)(?:\s*-\s*(\d+(?:[.,]\d+)?))?',
    ).firstMatch(ex.intensity);
    if (m == null) return null;
    final a = double.parse(m.group(1)!.replaceAll(',', '.'));
    final b = m.group(2) == null
        ? a
        : double.parse(m.group(2)!.replaceAll(',', '.'));
    return kc.Flames.fromRir((a + b) / 2);
  }

  /// Note d'une série enregistrée (flammes, sinon ancienne difficulté ou
  /// RIR convertis comme le journal du moteur, règle C9).
  static int? flamesOf(SetEntry s) => setFlamesOf(s);

  Future<void> _checkSet(int k, int i) async {
    if (widget.readOnly) return;
    final ex = widget.exs[k];
    final sp = specs[k];
    final log = logs[k];
    final s = log.sets[i];
    // G9 correction 1 : saisie valide d'abord ; la coche valide la série
    // avec la flamme visée déjà placée sur la ligne ouverte sous la série,
    // où elle se corrige.
    if (!s.done) {
      final pre = checkSet(sp, s, rpe: store.settings.rpe);
      if (!pre.ok) {
        setState(() => _issues[(k, i)] = pre);
        if (store.settings.vibration) HapticFeedback.heavyImpact();
        return;
      }
      if (_needsFlames(ex, sp)) {
        _introAt = null;
        if (!store.flamesIntroSeen) {
          _introAt = (k, i);
          unawaited(store.markFlamesIntroSeen());
        }
        if (s.flames == null && !s.flamesUnknown) {
          s.flames = _targetFlames(ex, sp, i);
        }
        s.effort = s.flames == null ? null : kc.Flames.toRir(s.flames!);
      }
    }
    // Validation métier (store) : la coche n'est acceptée qu'avec une saisie
    // valide ; sinon le texte reste tel quel et le champ est nommé.
    final check = store.toggleSet(log, i, sp);
    setState(() {
      if (check.ok) {
        _issues.remove((k, i));
        if (s.done) _openSet[k] = i;
        if (!s.done && _openSet[k] == i) _openSet.remove(k);
      } else {
        _issues[(k, i)] = check;
      }
    });
    if (!check.ok) {
      if (store.settings.vibration) HapticFeedback.heavyImpact();
      return;
    }
    if (store.settings.vibration) HapticFeedback.lightImpact();
    int? adviceRest;
    if (s.done && widget.adapt && ex.engine) {
      log.prescribed ??= store.adaptPrescribedText(
        widget.week.n,
        widget.day.j,
        ex,
      );
      adviceRest = _adaptAdvice(k, i);
    }
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
    final rest =
        adviceRest ??
        (widget.adapt && ex.engine
            ? store.adaptRestAfter(widget.week.n, widget.day.j, ex, i)
            : null) ??
        store.restAfterSet(ex, sp, i, log.sets.length);
    if (rest != null && rest > 0) widget.timer.startRest(rest);
  }

  /// G9 : conseil du moteur après la série [i] de l'exercice [k]. Mode
  /// assisté : appliqué aux séries suivantes, message de Koach et
  /// « Annuler » ; mode libre : proposition dans la carte de l'exercice.
  /// Renvoie le repos conseillé quand il diffère du repos prévu.
  int? _adaptAdvice(int k, int i, {bool revise = false}) {
    final ex = widget.exs[k];
    final r = revise
        ? store.adaptReviseAfterSet(widget.week.n, widget.day, ex, i)
        : store.adaptAfterSet(widget.week.n, widget.day, ex, i);
    if (r == null) return null;
    final seconds = specs[k].kind == 'hold' || specs[k].kind == 'holdMax';
    final text = adviceText(r.advice, seconds: seconds);
    final step = r.step;
    final changedRest =
        r.advice.action == kc.IntraSessionAction.restMore ||
        r.advice.reasons.any((x) => x.code == 'adapt.set_failed');
    final rest = changedRest ? r.advice.restSeconds : null;
    if (text == null) return rest;
    if (step != null) setState(() => epoch++);
    if (step != null && step.status == 'pending') return rest;
    final messenger = ScaffoldMessenger.of(context);
    final colors = KoachToastColors.of(context);
    final large = koachLargeText(context);
    final base = koachSnackBar(
      colors,
      'Koach : $text',
      pose: koachPose(KoachUsage.adjustment),
      large: large,
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const ValueKey('adapt-advice-toast'),
          duration: const Duration(seconds: 6),
          content: base.content,
          action: step == null
              ? null
              : SnackBarAction(
                  label: 'Annuler',
                  onPressed: () {
                    store.adaptAdviceDecision(
                      widget.week.n,
                      widget.day,
                      ex,
                      'undone',
                    );
                    if (mounted) setState(() => epoch++);
                  },
                ),
        ),
      );
    return rest;
  }

  /// Proposition en attente du moteur (mode libre) pour l'exercice [k].
  Widget? _adaptPendingCard(int k) {
    final ex = widget.exs[k];
    final step = store.adaptPendingAdvice(widget.week.n, widget.day.j, ex);
    if (step == null) return null;
    final seconds = specs[k].kind == 'hold' || specs[k].kind == 'holdMax';
    final amount = adaptAmount(step.low, step.high, seconds: seconds);
    final target = [
      if (step.kg != null && step.kg! > 0) adaptKg(step.kg!),
      if (amount.isNotEmpty) amount,
    ].join(' × ');
    void decide(String status) {
      store.adaptAdviceDecision(widget.week.n, widget.day, ex, status);
      setState(() => epoch++);
    }

    return Container(
      key: ValueKey('adapt-pending-${ex.id}'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SL.accent.withValues(alpha: SL.dark ? .10 : .07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: KoachSays(
        pose: koachPose(KoachUsage.proposal),
        koachHeight: 44,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Je te propose pour la série suivante : $target.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final r in step.reasons)
              if (adaptReasonText(r, exerciseName: store.adaptExerciseName)
                  case final t?)
                Text(t, style: TextStyle(color: SL.dim, fontSize: 12.5)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  key: ValueKey('adapt-accept-${ex.id}'),
                  onPressed: () => decide('accepted'),
                  child: const Text('Accepter'),
                ),
                TextButton(
                  key: ValueKey('adapt-keep-${ex.id}'),
                  onPressed: () => decide('kept'),
                  child: const Text('Garder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// CI1 : la prescription du chemin calibré, en clair : technique
  /// (série de tête et séries allégées, maintien, EMOM, densité…),
  /// intensité, tempo, test ; règle de douleur du programme toujours
  /// visible ; notes de coach dans la feuille de Koach.
  List<Widget> _coachPanel(Exercise ex) {
    final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
    if (it == null) return const [];
    final block = store.adaptBlockItemFor(widget.week.n, widget.day.j, ex);
    final catalog = store.content.catalog;
    final technique = it.technique?.kind;
    final label = it.kind == kc.SetKind.test
        ? 'Test'
        : technique == null
        ? null
        : ct.techniqueLabel(technique);
    final lines = <String>[
      if (label != null) '$label : ${ct.coachVolumeText(it)}',
      if (ct.coachIntensityText(it) case final t?) t,
      if (ct.techniqueHint(it) case final t?) t,
    ];
    final reasons = [...?block?.reasons, ...it.reasons];
    // CI1d (`kalis_adapt` 0.2.3) : le renvoi vers un professionnel n'est
    // dit qu'aux jours où le moteur le met dans la séance (début de
    // l'arrêt, puis une fois par semaine) ; les autres jours, l'arrêt seul.
    final served = store.sessionAdapt(widget.week.n, widget.day.j)?.active;
    final noticeCodes = served == null
        ? const <String>{}
        : {
            for (final r in served.reasons)
              if (r.code == 'adapt.pain_persistent' &&
                  r.params['zone'] is String)
                r.params['zone']! as String,
          };
    final pain = <String>[];
    for (final r in reasons) {
      if (!ct.isPainReason(r)) continue;
      final t = r.code == 'adapt.pain_persistent' &&
              !noticeCodes.contains(r.params['zone'])
          ? painStopShortText(r)
          : ct.coachText(r, catalog) ??
                adaptReasonText(r, exerciseName: store.adaptExerciseName);
      if (t != null && !pain.contains(t)) pain.add(t);
    }
    final notes = [
      for (final n
          in block == null
              ? const <String>[]
              : ct.coachItemNotes(block, catalog))
        if (!pain.contains(n)) n,
    ];
    if (lines.isEmpty && pain.isEmpty && notes.isEmpty) return const [];
    final intra = switch (technique) {
      kc.SetTechniqueKind.cluster ||
      kc.SetTechniqueKind.restPause ||
      kc.SetTechniqueKind.myoReps => it.technique?.intraRestSeconds,
      _ => null,
    };
    final dim = TextStyle(color: SL.dim, fontSize: 12.5);
    return [
      const SizedBox(height: 6),
      Semantics(
        container: true,
        child: InkWell(
          key: ValueKey('coach-panel-${ex.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: notes.isEmpty && lines.length < 2
              ? null
              : () => showKoachSheet<void>(
                  context,
                  pose: koachPose(KoachUsage.explanation),
                  title: store.splitName(ex.name).$1,
                  text: [...lines, ...pain, ...notes].join('\n\n'),
                ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label.toUpperCase(),
                    key: ValueKey('coach-technique-${ex.id}'),
                    style: TextStyle(
                      color: SL.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                for (final l in lines)
                  Text(
                    label != null && l.startsWith('$label : ')
                        ? l.substring(label.length + 3)
                        : l,
                    style: dim,
                  ),
                for (final p in pain)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      key: ValueKey('coach-pain-${ex.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: SL.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(p, style: dim.copyWith(color: SL.text)),
                        ),
                      ],
                    ),
                  ),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined, size: 16, color: SL.dim),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            notes.length == 1
                                ? 'Note du coach : touche pour la lire'
                                : '${notes.length} notes du coach : touche pour les lire',
                            style: dim,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (intra != null && intra > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: OutlinedButton.icon(
            key: ValueKey('coach-intra-${ex.id}'),
            icon: const Icon(Icons.av_timer),
            label: Text('Mini-repos $intra\u00A0s'),
            onPressed: () =>
                widget.timer.single('INTRA', intra, prepare: false),
          ),
        ),
    ];
  }

  /// Ce que le moteur dit de la séance du jour pour un exercice servi :
  /// calibrage, hausse ou baisse, charge gardée, zone épargnée.
  List<Widget> _adaptNotes(Exercise ex) {
    final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
    if (it == null) return const [];
    final lines = <String>[];
    for (final r in it.reasons) {
      final t = adaptReasonText(r, exerciseName: store.adaptExerciseName);
      if (t == null || lines.contains(t)) continue;
      // Calibrage d'abord : c'est ce qui explique la charge du jour.
      if (r.code == 'adapt.calibration') {
        lines.insert(0, t);
      } else {
        lines.add(t);
      }
    }
    if (it.toCalibrate && !lines.any((l) => l.startsWith('Calibrage'))) {
      lines.insert(
        0,
        'Calibrage : je cale la charge sur tes premières séances.',
      );
    }
    if (lines.isEmpty && !it.toCalibrate) return const [];
    return [
      const SizedBox(height: 6),
      InkWell(
        key: ValueKey('adapt-notes-${ex.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => showKoachSheet<void>(
          context,
          pose: koachPose(
            it.toCalibrate ? KoachUsage.calibration : KoachUsage.explanation,
          ),
          title: store.splitName(ex.name).$1,
          text: [
            if (it.toCalibrate)
              'Je ne connais pas encore bien ta charge sur cet exercice : '
                  'je la cale sur tes 2 ou 3 premières séances. Note bien '
                  'chaque série, c’est ce qui me règle.',
            ...lines,
          ].join('\n'),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: SL.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lines.take(2).join(' · '),
                  style: TextStyle(color: SL.dim, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
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
              Icon(Icons.emoji_events_rounded, color: SL.onBrand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'RECORD · ${store.splitName(ex.name).$1} · ${hit.label}',
                  style: TextStyle(
                    color: SL.onBrand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// Une série déjà validée puis modifiée repasse « non validée » si sa
  /// saisie n'est plus valide ; un problème affiché disparaît dès la frappe.
  void _edited(int k, int i) {
    final check = store.revalidateSet(logs[k], i, specs[k]);
    if (check == null && !_issues.containsKey((k, i))) return;
    setState(() {
      if (check == null) {
        _issues.remove((k, i));
      } else {
        _issues[(k, i)] = SetCheck.error(
          check.field!,
          'Série repassée non validée. ${check.message}',
        );
      }
    });
  }

  // ---- Flammes sous la série (G9 correction 1) ----
  /// Note de la série validée [i] changée sur sa ligne : [flames] (null avec
  /// [unknown] : « Je ne sais pas »). Dernière série validée d'un exercice
  /// servi par le moteur : son conseil est recalculé.
  void _setFlames(int k, int i, int? flames, {bool unknown = false}) {
    final log = logs[k];
    final s = log.sets[i];
    if (!s.done) return;
    s.flames = flames;
    s.flamesUnknown = unknown;
    final rir = flames == null ? null : kc.Flames.toRir(flames);
    if (rir != s.effort) {
      store.setEffort(log, i, rir);
    } else {
      store.saveLogs(affectsProgression: false);
    }
    final ex = widget.exs[k];
    final latest = !log.sets.skip(i + 1).any((x) => x.done);
    setState(() {});
    if (widget.adapt && ex.engine && latest) {
      _adaptAdvice(k, i, revise: true);
    }
  }

  void _toggleExcluded(int k, int i) {
    store.toggleExcluded(logs[k], i);
    setState(() {});
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
      if (p.kg.isNotEmpty || p.reps.isNotEmpty) s.edited = true;
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
      builder: (context) => SingleChildScrollView(
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
            // L10 (KT-057) : pourquoi cet exercice (programme généré).
            if (ex.why.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Pourquoi : ${ex.why}',
                key: ValueKey('${ex.id}-why'),
                style: TextStyle(color: SL.dim),
              ),
            ],
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
    final accent = ex.main
        ? SL.accent
        : ex.prevention
        ? SL.prevViolet
        : SL.text;
    final finalRest = !readOnly && sp.myo
        ? store.restAfterSet(ex, sp, log.sets.length - 1, log.sets.length)
        : null;
    final (title, subtitle) = store.splitName(ex.name);
    final interval = ex.interval;
    final noLoad =
        sp.kind == 'duration' ||
        sp.kind == 'interval' ||
        sp.kind == 'emom' ||
        sp.kind == 'amrap';
    final showKg = readOnly
        ? log.sets.any((s) => s.kg.isNotEmpty)
        : !noLoad && store.showKgFor(ex, log);
    // G9 (D5.4) : la note en flammes remplace la saisie du RIR partout ;
    // les anciennes séances sont affichées en flammes (conversion C9).
    final flameSets = readOnly
        ? log.sets.any(
            (s) => flamesOf(s) != null || s.flamesUnknown || s.excluded,
          )
        : _needsFlames(ex, sp);
    const showRir = false;
    final showV = readOnly
        ? log.sets.any((s) => s.v.isNotEmpty)
        : sp.kind == 'reps' && store.showVFor(ex, log);
    final recordedLoads = log.sets
        .map((s) => s.kg)
        .where((s) => s.isNotEmpty)
        .toSet();
    final loadLabel = readOnly
        ? (recordedLoads.length == 1 ? '${recordedLoads.single} kg' : '—')
        : store.loadLabel(ex, week: widget.week.n, day: widget.day.j);
    final showBigLoad =
        (readOnly || !noLoad) &&
        loadLabel != '—' &&
        (loadLabel != 'PdC' || showKg);
    final kindLabel = _kindLabel(sp);
    final showIntensity =
        ex.intensity.isNotEmpty &&
        !kindLabel.toLowerCase().startsWith(ex.intensity.toLowerCase());
    final prev = !readOnly && widget.week.n > 0
        ? store.previousLog(widget.week.n, widget.day.j, ex)
        : null;
    // CI1 : lignes nommées par leur rôle dans la technique servie (série
    // de tête, allégées, montées, tentatives, intervalles).
    String rowLabel(int i) =>
        (widget.adapt && ex.engine
            ? store.adaptRowLabel(widget.week.n, widget.day.j, ex, i)
            : null) ??
        store.setLabel(sp, i);

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
                // L8 (KT-041) : consigne du mode prudent.
                // G9 : exercice servi par le moteur, la prudence est dans
                // ses cibles (pas de seconde règle de charge).
                if (!readOnly && !ex.engine && store.cautionNote(ex) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: SL.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            store.cautionNote(ex)!,
                            key: ValueKey('caution-${ex.id}'),
                            style: TextStyle(color: SL.dim, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (readOnly &&
                    (log.prescribed != null || log.koach != null)) ...[
                  const SizedBox(height: 6),
                  if (log.prescribed != null)
                    Text(
                      'Prescrit ce jour-là : ${log.prescribed}',
                      key: ValueKey('prescribed-${ex.id}'),
                      style: TextStyle(color: SL.dim, fontSize: 12.5),
                    ),
                  if (log.koach != null)
                    Text(
                      log.koach!,
                      style: TextStyle(color: SL.dim, fontSize: 12.5),
                    ),
                ],
                if (!readOnly && widget.adapt && ex.engine) ..._coachPanel(ex),
                if (!readOnly && widget.adapt && ex.engine) ..._adaptNotes(ex),
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
          // G9 correction 1 : sans ligne de saisie visible (toutes les
          // séries résumées), pas d'en-tête de colonnes.
          if ([
            for (var i = 0; i < log.sets.length; i++)
              !log.sets[i].done || (!readOnly && i == _openOf(k)),
          ].any((x) => x))
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
            // G9 correction 1 : séries validées résumées en une ligne, sauf
            // la série ouverte (la dernière validée) ; toutes résumées en
            // lecture (fin de séance, historique). Correction 2 : aussi
            // pour les exercices sans flammes.
            if (log.sets[i].done && (readOnly || i != _openOf(k)))
              SetSummaryLine(
                setLabel: rowLabel(i),
                done: setDoneText(log.sets[i], sp, units: !unresolved),
                flames: flamesOf(log.sets[i]),
                unknown: log.sets[i].flamesUnknown,
                excluded: log.sets[i].excluded,
                onTap: readOnly ? null : () => setState(() => _openSet[k] = i),
              )
            else ...[
              _SetRow(
                key: ValueKey('${ex.id}-$i-$epoch'),
                label: rowLabel(i),
                entry: log.sets[i],
                spec: sp,
                showKg: showKg,
                showRir: showRir,
                showV: showV,
                readOnly: readOnly,
                issue: _issues[(k, i)],
                onEdited: readOnly ? null : () => _edited(k, i),
                onCheck: readOnly ? null : () => _checkSet(k, i),
                onLongPressLabel: !readOnly && log.sets[i].done
                    ? () => setState(() => _openSet[k] = i)
                    : null,
                onTimer: readOnly
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
              if (flameSets && log.sets[i].done && !readOnly)
                FlameTrack(
                  setLabel: rowLabel(i),
                  value: flamesOf(log.sets[i]),
                  unknown: log.sets[i].flamesUnknown,
                  excluded: log.sets[i].excluded,
                  intro: _introAt == (k, i),
                  onChanged: (f) => _setFlames(k, i, f),
                  onUnknown: () => _setFlames(k, i, null, unknown: true),
                  onToggleExcluded: () => _toggleExcluded(k, i),
                ),
            ],
          if (!readOnly && widget.adapt)
            if (_adaptPendingCard(k) case final card?) card,
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
                    tooltip: _notesOpen.contains(k)
                        ? 'Masquer la note'
                        : log.note.isEmpty
                        ? 'Ajouter une note'
                        : 'Afficher la note',
                    icon: Icon(
                      log.note.isEmpty ? Icons.note_add_outlined : Icons.notes,
                      size: 20,
                      color: _notesOpen.contains(k) || log.note.isNotEmpty
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
                          if (v == 'v') log.showV = !showV;
                        });
                        store.saveLogs(affectsProgression: false);
                      },
                      itemBuilder: (_) => [
                        CheckedPopupMenuItem(
                          value: 'kg',
                          checked: showKg,
                          child: const Text('Charge (kg)'),
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
            foregroundColor: SL.onFill(c),
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
    final second = k == 'hold' || k == 'holdMax'
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

  /// Saisie refusée à la coche (KT-009) : champ et explication.
  final SetCheck? issue;
  final VoidCallback? onEdited;

  /// Koach (D11) : appui long sur le numéro d'une série validée.
  final VoidCallback? onLongPressLabel;
  const _SetRow({
    super.key,
    this.issue,
    this.onEdited,
    this.onLongPressLabel,
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
                // CI1c : saisie de l'utilisateur (brouillon gardé, jamais
                // refaite à la réouverture).
                widget.entry.edited = true;
                store.saveLogs(affectsProgression: false);
                widget.onEdited?.call();
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
                child: GestureDetector(
                  onLongPress: widget.onLongPressLabel,
                  child: Semantics(
                    onLongPressHint: widget.onLongPressLabel == null
                        ? null
                        : 'difficulté ou série écartée',
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
                    tooltip: k == 'holdMax'
                        ? 'Chrono montant'
                        : 'Compte à rebours',
                  ),
                ),
                _gap,
              ],
              SizedBox(
                width: _wBtn,
                height: _wBtn,
                child: widget.readOnly
                    ? Semantics(
                        label:
                            'Série ${widget.label} ${done ? "validée" : "non validée"}',
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: done
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
                        message: done
                            ? 'Annuler la série ${widget.label}'
                            : 'Valider la série ${widget.label}',
                        child: Center(
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: done
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
          if (widget.issue?.message case final message?)
            Padding(
              padding: const EdgeInsets.fromLTRB(_wLabel + 6, 2, 0, 2),
              child: Semantics(
                container: true,
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 16, color: SL.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message,
                        key: ValueKey('set-issue-${widget.label}'),
                        style: TextStyle(color: SL.danger, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
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
        final frac = ctl.up
            ? 1.0
            : (ctl.total == 0 ? 0.0 : ctl.remaining / ctl.total);
        final effort =
            ctl.label.startsWith('EFFORT') ||
            ctl.label == 'TENUE' ||
            ctl.label == 'MAX';
        // Chiffres en blanc cassé (charte) ; le libellé porte l'état :
        // vert = terminé, rouge d'alerte = effort, accent = repos. Couleurs
        // de phase fixes : elles ne suivent pas la couleur dominante (L5-C).
        final labelColor = done
            ? SL.success
            : effort
            ? SL.danger
            : SL.redAccent;
        final fill = done
            ? SL.success
            : effort
            ? SL.alert
            : null;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          decoration: BoxDecoration(
            color: SL.surface,
            border: effort && ctl.running
                ? Border.all(color: SL.alert, width: 2)
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
                  gradient: KPalette.redGradient,
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

class _FinishPage extends StatefulWidget {
  final WeekPlan week;
  final DayPlan day;

  /// G9 : journée du programme (avant le moteur) et séance servie par
  /// `kalis_adapt` (résumé de Koach en fin de séance).
  final DayPlan base;
  final bool adapt;
  const _FinishPage({
    required this.week,
    required this.day,
    required this.base,
    this.adapt = false,
  });

  @override
  State<_FinishPage> createState() => _FinishPageState();
}

class _FinishPageState extends State<_FinishPage> {
  WeekPlan get week => widget.week;
  DayPlan get day => widget.day;

  /// Enregistrement en cours : un second appui ne relance rien.
  bool _saving = false;

  /// Séance terminée en mémoire mais écriture refusée : à réessayer.
  bool _unsaved = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => _build(context),
  );

  /// Fin de séance : le bilan n'est présenté qu'après l'écriture acceptée.
  Future<void> _finish(String title) async {
    if (_saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final closing = ModalRoute.of(context)?.completed;
    final result = await store.finishSession(week.n, day.j, title: title);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _unsaved = result != ResultSave.saved;
    });
    if (result != ResultSave.saved) {
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Séance terminée mais pas encore enregistrée sur le téléphone : '
            'tes séries sont gardées. Réessaie avant de fermer l’application.',
          ),
        ),
      );
      return;
    }
    // Le bilan part d'ici, quel que soit l'écran qui a ouvert la séance
    // (accueil, Arsenal, notification de rappel). Son décompte attend que la
    // séance soit refermée et sauvegardée.
    nav.pop();
    // G9 : séance servie par kalis_adapt → résumé de Koach (calibrage,
    // progrès, prochaine fois) ; L7 et L11 ne s'appliquent pas.
    if (widget.adapt) {
      await closing;
      if (!nav.mounted) return;
      await nav.push(
        MaterialPageRoute<void>(
          builder: (_) => AdaptSummaryScreen(week: week, base: widget.base),
        ),
      );
      if (!nav.mounted) return;
      checkLevelUp(nav.context, after: closing);
      return;
    }
    checkLevelUp(nav.context, after: closing);
  }

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
                  : '+100 XP de base + bonus éventuels',
              style: TextStyle(
                color: SL.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            if (log.done && _unsaved)
              FilledButton.icon(
                key: const ValueKey('finish-retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: SL.bordeaux,
                  foregroundColor: SL.onBrand,
                  minimumSize: const Size(220, KControl.buttonHeight),
                ),
                icon: const Icon(Icons.sync_problem),
                label: Text(
                  _saving ? 'Enregistrement…' : 'Réessayer l’enregistrement',
                ),
                onPressed: _saving ? null : () => _finish(title),
              )
            else
              FilledButton.icon(
                key: const ValueKey('finish-session'),
                style: FilledButton.styleFrom(
                  backgroundColor: log.done ? SL.card : SL.bordeaux,
                  foregroundColor: log.done ? SL.dim : SL.onBrand,
                  minimumSize: const Size(220, KControl.buttonHeight),
                ),
                icon: Icon(log.done ? Icons.undo : Icons.check_circle),
                label: Text(
                  _saving
                      ? 'Enregistrement…'
                      : log.done
                      ? 'Repasser en « à faire »'
                      : 'Terminer la séance',
                ),
                onPressed: _saving
                    ? null
                    : log.done
                    ? () => store.markSessionDone(
                        week.n,
                        day.j,
                        false,
                        title: title,
                      )
                    : () => _finish(title),
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
              onPressed: () => store.markSessionDone(
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
