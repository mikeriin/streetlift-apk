import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalis_core/kalis_core.dart'
    as kc
    show
        Flames,
        GroupFormat,
        GroupSpec,
        IntraSessionAction,
        Place,
        SetKind,
        SetTechniqueKind;
import 'package:kalis_koach/kalis_koach.dart' show KoachUsage;
import 'device.dart';

import 'adapt/adapt_summary_screen.dart';
import 'adapt/adapt_texts.dart';
import 'adapt/clearance.dart';
import 'adapt/flame_track.dart';
import 'adapt/health_check.dart';
import 'exercise_screens.dart' show openExerciseSheet;
import 'plan/coach_texts.dart' as ct;
import 'koach/koach_bubble.dart'
    show KoachSays, koachLargeText, koachPose, showKoachSheet;
import 'koach/koach_explanations.dart' show koachGuided;
import 'koach/koach_view.dart' show KoachColors, KoachView;

import 'timers.dart';
export 'timers.dart' show TimerCtl;
import 'kit/kit.dart';
import 'koach1/koach1_widgets.dart';
import 'wellbeing_screens.dart' show SafetyScreen;
import 'models.dart';
import 'rewards.dart' show checkLevelUp;
import 'store.dart';
import 'estimate_view.dart';
import 'pilotage_screen.dart';
import 'set_validation.dart' show checkSet;

// ============================= TIMER =====================================
// Basé sur l'horloge murale : reste juste même si l'app passe en arrière-plan.

String fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Espace fine insécable (C9, [kUnitSpace]) avant les unités (« 3 min »,
/// « 90 s ») d'un texte du programme.
String nbsp(String t) => t.replaceAllMapped(
  RegExp(r'(\d) (kg|s|min|reps|lb)\b'),
  (m) => '${m[1]}$kUnitSpace${m[2]}',
);

/// UI2 : repère de la journée affiché sous le titre (« S1, J2 » ; le nom du
/// bloc pour une séance hors semaine). Le titre enregistré dans le journal
/// (« S1 · J2 ») ne change pas.
/// PR10 : volume affiché sur la carte : « 8 × 3 » (espaces autour du ×,
/// comme les lignes servies par Koach) ; sans le format au temps quand
/// l'en-tête de la carte le dit déjà (« 8 × 3 · E2MOM » → « 8 × 3 »).
String volumeText(String raw, {bool timed = false}) {
  var s = raw.replaceAllMapped(
    RegExp(r'(\d|\?)\s*[×x]\s*(?=[\d?(])'),
    (m) => '${m[1]} × ',
  );
  if (timed) {
    s = s.replaceFirst(
      RegExp(r'\s*·\s*E(?:\d*MOM|\d+\s*s)\s*$', caseSensitive: false),
      '',
    );
  }
  return s;
}

String sessionPlace(WeekPlan w, DayPlan d) =>
    w.n == 0 ? w.block : store.program.sessionLabel(w.n, d.j);

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

  /// Barre de chrono (hauteur lue pour poser les messages au-dessus, C8).
  final _barKey = GlobalKey();

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
    // KB2 correction 1 : arrêt d'urgence pendant la séance : séance écrite.
    if (adaptOn && !store.koachStoppedWeek(widget.week.n)) {
      final a = store.sessionAdapt(widget.week.n, widget.day.j);
      if (a != null) return store.adaptDay(widget.week.n, widget.day, a);
    }
    return widget.day;
  }

  List<List<Exercise>> _groups() => store.groups(_day, week: widget.week.n);

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
    // CI1g (`kalis_plan` 0.3.1) : avis médical demandé par le bloc, à
    // confirmer avant la première séance (pas dans une séance commencée).
    final log = store.logs[store.sessionKey(widget.week.n, widget.day.j)];
    final started =
        log != null &&
        (log.done || log.ex.values.any((x) => x.sets.any((s) => s.done)));
    if (adaptOn && !started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) askClearance(context, widget.week.n, widget.day.j);
      });
    }
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

  /// Hauteur de la barre de chrono quand elle est affichée.
  double _barHeight() => ctl.visible && page != bilanPage
      ? (_barKey.currentContext?.size?.height ?? 0)
      : 0;

  /// « Supprimer l'historique de cette séance » (R8 : verbe exact,
  /// confirmation, `danger`).
  Future<void> _confirmClear() async {
    final w = widget.week;
    final d = widget.day;
    final head = w.n == 0 ? w.block : store.program.sessionLabel(w.n, d.j);
    final ok = await showKConfirm(
      context,
      title: 'Supprimer l’historique de cette séance ?',
      message:
          '${sessionPlace(w, d)} : séries, notes et statut « fait » seront '
          'effacés. Action irréversible.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!ok || !mounted) return;
    store.clearSession(w.n, d.j);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Historique de $head supprimé.')),
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
        duration: KMotion.standard.duration,
        curve: KMotion.standard.curve,
      );
    }
  }

  /// Toutes les séries de la page [i] (exercices) sont validées.
  bool _pageDone(int i) {
    var any = false;
    for (final e in groups[i]) {
      final sets = store.exLog(widget.week.n, widget.day.j, e).sets;
      if (sets.isEmpty) return false;
      if (sets.any((s) => !s.done)) return false;
      any = true;
    }
    return any;
  }

  /// Liste des exercices (feuille de liste, cahier §4.5).
  Future<void> _chooseExercise() async {
    final count = groups.fold<int>(0, (n, g) => n + g.length);
    final duration = store.dayEstimate(_day).durationLabel;
    final items = <KListItem>[
      if (koachPage)
        KListItem(
          'Bilan du jour',
          detail: 'Ressenti et changements de Koach',
          icon: Icons.favorite_outline_rounded,
          state: page == 0 ? KListState.current : KListState.todo,
        ),
      for (var i = 0; i < nPages; i++)
        KListItem(
          groups[i].map((e) => store.splitName(e.name).$1).join(' + '),
          detail: groups[i].length > 1
              ? 'Exercices enchaînés'
              : nbsp(store.setsLabel(groups[i].first)),
          state: i == exerciseIndex
              ? KListState.current
              : _pageDone(i)
              ? KListState.done
              : KListState.todo,
        ),
      KListItem(
        'Bilan de séance',
        detail: 'Séries validées et fin de séance',
        icon: Icons.flag_outlined,
        state: page == bilanPage ? KListState.current : KListState.todo,
      ),
    ];
    final selected = await showKListSheet(
      context,
      title: 'Dans cette séance',
      summary:
          '$count exercice${count > 1 ? 's' : ''}'
          '${duration.isEmpty ? '' : ', ${estimateLabelText(duration)}'}',
      items: items,
    );
    if (selected != null && mounted) _go(selected);
  }

  /// G9 : « J'ai seulement… minutes » → temps disponible du bilan. UI2
  /// (§4.6) : on reste sur la page d'où l'on vient.
  Future<void> _adaptMinutes() async {
    final a = store.sessionAdapt(widget.week.n, widget.day.j);
    final m = await showMinutesSheet(context, a?.check?.minutesAvailable);
    if (m == null || !mounted) return;
    final from = _currentKey();
    store.adaptSetMinutes(widget.week.n, widget.day, m == 0 ? null : m);
    _adapted(true);
    _restore(from);
  }

  /// G9 : « Je m'entraîne ailleurs » → lieu du jour du moteur. UI2 (§4.6) :
  /// on reste sur la page d'où l'on vient.
  Future<void> _adaptPlace() async {
    final a = store.sessionAdapt(widget.week.n, widget.day.j);
    final code = await showPlaceChoiceSheet(context, a?.place);
    if (code == null || !mounted) return;
    kc.Place? place;
    for (final p in kc.Place.values) {
      if (p.code == code) place = p;
    }
    final from = _currentKey();
    store.adaptSetPlace(widget.week.n, widget.day, place);
    _adapted(true);
    _restore(from);
  }

  bool _koachStarting = false;

  /// KM3 : début réel de la séance servie par Koach 1.0 : diagnostic hors
  /// modèle s'il le faut (trois questions au plus), puis `seance_debut` et
  /// `plan(seance)` ; les pages suivent la séance servie.
  Future<void> _koachBegin() async {
    if (_koachStarting) return;
    _koachStarting = true;
    try {
      await store.koachRefresh();
      if (!mounted) return;
      Map<String, Object?>? diagnostic;
      if (store.koachNeedsDiagnostic) {
        diagnostic = await showKoachDiagnostic(context);
        if (!mounted) return;
      }
      final from = _currentKey();
      final ok = await store.koachStart(
        widget.week.n,
        widget.day,
        diagnostic: diagnostic,
      );
      if (!mounted) return;
      // KB2 correction 1 (C17.36) : réponse refusée : message clair, séance
      // écrite servie, question reposée à la séance suivante.
      if (!ok && store.koachAnswerRefused(widget.week.n, widget.day.j)) {
        _adapted(true);
        _restore(from);
        showKSnack(
          context,
          message:
              'Koach n’a pas pu prendre ta réponse en compte : tu fais la '
              'séance écrite aujourd’hui. Il te reposera la question à la '
              'prochaine séance.',
          bottom: KBottomInset.of(context),
          duration: const Duration(seconds: 6),
        );
        return;
      }
      if (!ok) return;
      _adapted(true);
      _restore(from);
    } finally {
      _koachStarting = false;
    }
  }

  /// Repère de la page courante, qui survit à un recalcul de la séance :
  /// page du bilan, page de fin, ou identifiant du premier exercice.
  Object _currentKey() {
    if (page < koachPages) return 'bilan';
    if (page >= bilanPage) return 'fin';
    return groups[exerciseIndex].first.id;
  }

  /// Revient à la page repérée par [key] après un recalcul (l'exercice a pu
  /// être remplacé ou retiré : on garde alors le même rang).
  void _restore(Object key) {
    var target = page;
    if (key == 'bilan') {
      target = 0;
    } else if (key == 'fin') {
      target = bilanPage;
    } else {
      for (var i = 0; i < nPages; i++) {
        if (groups[i].any((e) => e.id == key)) target = koachPages + i;
      }
    }
    target = target.clamp(0, bilanPage);
    if (target == page) return;
    setState(() => page = target);
    if (pageCtl.hasClients) pageCtl.jumpToPage(target);
  }

  /// « Douleur ou malaise ? » (§4.1) : le Bilan du jour détaillé, ouvert
  /// sur la section Douleur ; séance sans moteur : la page de santé et
  /// sécurité.
  Future<void> _pain() async {
    if (!adaptOn) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SafetyScreen()),
      );
      return;
    }
    final from = _currentKey();
    final changed = await reportSessionPain(context, widget.week, widget.day);
    if (!changed || !mounted) return;
    _adapted(true);
    _restore(from);
  }

  void _instructions() => showKContentSheet<void>(
    context,
    title: 'Consignes de séance',
    subtitle: '${widget.day.title} · ${sessionPlace(widget.week, widget.day)}',
    builder: (ctx) => Text(contentText(widget.day.conduite)),
  );

  /// Menu ⋮ de la séance : feuille d'actions au contenu du §4.1.
  Future<void> _menu() async {
    final w = widget.week;
    final d = widget.day;
    final restDay = d.exercises.isEmpty;
    final choice = await showKActionSheet<String>(
      context,
      title: 'Séance',
      subtitle: '${restDay ? 'Récupération' : d.title} · ${sessionPlace(w, d)}',
      groups: [
        [
          if (!restDay)
            const KAction(
              icon: Icons.format_list_numbered_rounded,
              label: 'Liste des exercices',
              value: 'list',
            ),
          if (d.conduite.isNotEmpty)
            const KAction(
              icon: Icons.menu_book_outlined,
              label: 'Consignes de séance',
              value: 'instructions',
            ),
          if (adaptOn)
            const KAction(
              icon: Icons.favorite_outline_rounded,
              label: 'Bilan du jour',
              value: 'bilan',
            ),
          // G10 : seulement dans une séance servie par le moteur (les
          // adaptations de L11 sont retirées).
          if (adaptOn && w.n >= 1 && !restDay) ...[
            const KAction(
              icon: Icons.timer_outlined,
              label: 'J’ai seulement… minutes',
              value: 'compress',
            ),
            const KAction(
              icon: Icons.place_outlined,
              label: 'Je m’entraîne ailleurs',
              value: 'place',
            ),
          ],
        ],
        [
          // L13 (KT-073) : douleur ou signal d'alerte pendant la séance.
          const KAction(
            icon: Icons.warning_amber_rounded,
            label: 'Douleur ou malaise ?',
            value: 'safety',
            tone: KActionTone.warning,
          ),
          // Report d'un test (S2, S12…) dans les références sans quitter la
          // séance : même page que depuis Réglages (R1, R2).
          const KAction(
            icon: Icons.tune_rounded,
            label: 'Mes références',
            value: 'pilotage',
          ),
        ],
        [
          const KAction(
            icon: Icons.delete_outline_rounded,
            label: 'Supprimer l’historique de cette séance',
            value: 'clear',
            danger: true,
          ),
        ],
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'list':
        await _chooseExercise();
      case 'instructions':
        _instructions();
      case 'bilan':
        _go(0);
      case 'compress':
        // G9 : temps et lieu du jour passés au moteur dynamique.
        await _adaptMinutes();
      case 'place':
        await _adaptPlace();
      case 'safety':
        await _pain();
      case 'pilotage':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PilotageScreen()),
        );
      case 'clear':
        await _confirmClear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final w = widget.week;
    final d = widget.day;
    final restDay = d.exercises.isEmpty;
    // KS1A : type du jour en tête de séance (« Tirage — force »).
    final type = restDay ? null : store.dayTypeLabelOf(d);
    final header = KSessionHeader(
      key: const ValueKey('session-header'),
      title: restDay ? 'Récupération' : d.title,
      subtitle: type == null
          ? sessionPlace(w, d)
          : '$type · ${sessionPlace(w, d)}',
      // Correctifs UI (11/10/2026) : le titre ouvre la liste des exercices
      // (appui ou appui long), à la place du bouton « Exercices ».
      onTitleTap: restDay ? null : _chooseExercise,
      titleTapHint: 'Voir la liste des exercices',
      action: KIconButton(
        icon: Icons.more_vert_rounded,
        tooltip: 'Options de séance',
        onPressed: _menu,
      ),
    );
    return Scaffold(
      backgroundColor: k.fond,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
            child: KBottomInset(
              height: _barHeight,
              child: Column(
                children: [
                  header,
                  if (restDay)
                    Expanded(
                      child: _RestDay(week: w, day: d),
                    )
                  else ...[
                    _strip(k),
                    Expanded(
                      child: KSessionPager(
                        controller: pageCtl,
                        onPageChanged: (i) {
                          store.saveLogs(affectsProgression: false);
                          setState(() => page = i);
                          // KM3 : début réel de la séance de Koach (bilan
                          // réglé, premier exercice).
                          if (i >= koachPages &&
                              adaptOn &&
                              store.koachPending(w.n, d.j)) {
                            unawaited(_koachBegin());
                          }
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
                    // Page de fin : pas de barre de repos (le chrono continue,
                    // son signal de fin aussi) ; un seul aplat, « Terminer la
                    // séance » (C2).
                    Offstage(
                      offstage: page == bilanPage,
                      child: _TimerBar(key: _barKey, ctl: ctl),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      // 5.5.2 (demande du propriétaire, 29/09/2026) : plus de boutons
      // Précédent / Suivant, le glissement d'une page à l'autre suffit ; le
      // repère « Exercice n sur N » (et le titre) ouvre la liste.
    );
  }

  /// Repère de page (« Exercice 3 sur 7 ») et points sur une ligne ; le
  /// repère ouvre la liste des exercices (correctifs UI, 11/10/2026).
  Widget _strip(KTokens k) {
    final where = page == bilanPage
        ? 'Bilan de séance'
        : exerciseIndex < 0
        ? 'Bilan du jour'
        : '${groups[exerciseIndex].length > 1 ? 'Enchaînement' : 'Exercice'} '
              '${exerciseIndex + 1} sur $nPages';
    return Padding(
      padding: const EdgeInsets.only(left: KSpacing.s12, right: KSpacing.page),
      child: KPageStrip(
        label: where,
        count: bilanPage + 1,
        index: page,
        onList: _chooseExercise,
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

/// PR4 : morceaux de la carte d'un exercice : prescription, en-tête du
/// tableau, lignes de séries, barre d'outils et notes.
typedef _BlockParts = ({
  List<Widget> head,
  List<Widget> header,
  List<String> columns,
  List<Widget> Function(int i) row,
  int count,
  List<Widget> tail,
  bool lead,
});

class SessionExercisePageState extends State<SessionExercisePage> {
  late final List<ExerciseLog> logs;
  late final List<LogSpec> specs;
  final Set<int> _notesOpen = {};

  /// Exercices dont la séance précédente est affichée (correctifs UI).
  final Set<int> _prevOpen = {};

  /// PR4 : plusieurs exercices sur la page : une seule carte (PR4).
  bool get _merged => widget.exs.length > 1;

  /// PR3 : prochaine étape d'une page d'exercices enchaînés, faits tour par
  /// tour (A1, B1, A2, B2…) : (exercice, série) ; null : tout est fait.
  (int, int)? _nextStep() {
    var rounds = 0;
    for (final l in logs) {
      if (l.sets.length > rounds) rounds = l.sets.length;
    }
    for (var i = 0; i < rounds; i++) {
      for (var k = 0; k < logs.length; k++) {
        final sets = logs[k].sets;
        if (i < sets.length && !sets[i].done) return (k, i);
      }
    }
    return null;
  }

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
  /// reste à sa place ; UI2 (R2) : la référence manquante est nommée dans un
  /// lien visible sous la prescription, qui ouvre « Mes références » (même
  /// page que depuis Réglages). Rien n'est calculé à sa place.
  Widget? _missingReference(Exercise ex, bool readOnly) {
    final ref = readOnly ? null : store.missingReference(ex);
    if (ref == null) return null;
    final k = KTokens.of(context);
    final label = store.referenceLabel(ref);
    final message =
        'Référence non renseignée : $label. '
        'Touche pour ouvrir Mes références.';
    return Semantics(
      button: true,
      label: message,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('missing-ref-${ex.id}'),
        customBorder: KRadius.menuShape,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PilotageScreen()),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.target),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: KSize.iconSmall,
                color: k.encre,
              ),
              const SizedBox(width: KSpacing.s8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'À renseigner : $label. ',
                        style: KType.detail.copyWith(color: k.texte2),
                      ),
                      TextSpan(
                        text: 'Mes références',
                        style: KType.libelle.copyWith(color: k.encre),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: KSize.chevron,
                color: k.texte2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Problème de saisie affiché sous une série (KT-009) : (exercice, série).
  final Map<(int, int), SetCheck> _issues = {};

  /// Première notation en flammes : l'échelle expliquée dans la popup de
  /// cette série (PR5).
  (int, int)? _introAt;

  /// PR5 : note de la série validée [i] en popup (même curseur), validée
  /// au lâcher.
  void _openFlames(int k, int i, String label) {
    final s = logs[k].sets[i];
    if (!s.done) return;
    final intro = _introAt == (k, i);
    _introAt = null;
    unawaited(
      showFlamePopup(
        context,
        setLabel: label,
        value: flamesOf(s),
        unknown: s.flamesUnknown,
        excluded: s.excluded,
        intro: intro,
        onChanged: (f) => _setFlames(k, i, f),
        onUnknown: () => _setFlames(k, i, null, unknown: true),
        onToggleExcluded: () => _toggleExcluded(k, i),
      ),
    );
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
    // avec la flamme visée déjà placée ; PR5 : elle se corrige d'un appui
    // sur la flamme (popup).
    if (!s.done) {
      // CI1f : série notée par mini-séries : le total fait foi ; durée
      // notée en minutes (marquée pour le journal).
      if (s.partsTotal case final total?) s.reps = '$total';
      s.minutes = sp.kind == 'duration';
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
      } else {
        _issues[(k, i)] = check;
      }
    });
    if (!check.ok) {
      if (store.settings.vibration) HapticFeedback.heavyImpact();
      return;
    }
    _recordGroupRounds();
    if (store.settings.vibration) HapticFeedback.lightImpact();
    int? adviceRest;
    if (s.done && widget.adapt && ex.engine) {
      log.prescribed ??= store.adaptPrescribedText(
        widget.week.n,
        widget.day.j,
        ex,
      );
      // KM3 : séance servie par Koach 1.0 : cible de la série suivante.
      if (store.koachOpen(widget.week.n, widget.day.j)) {
        _koachNews(k, i);
      } else {
        adviceRest = _adaptAdvice(k, i);
      }
    }
    if (s.done) _celebrateRecord(ex, s);
    if (!s.done || !store.settings.autoTimer) return;
    if (widget.exs.length == 2 && k == 0) {
      showKSnack(
        context,
        message: 'Enchaîne : ${store.splitName(widget.exs[1].name).$1}',
        bottom: KBottomInset.of(context),
        duration: const Duration(seconds: 2),
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
    final text = adviceText(
      r.advice,
      seconds: seconds,
      exerciseName: store.adaptExerciseName,
    );
    final step = r.step;
    final changedRest =
        r.advice.action == kc.IntraSessionAction.restMore ||
        r.advice.reasons.any((x) => x.code == 'adapt.set_failed');
    final rest = changedRest ? r.advice.restSeconds : null;
    if (text == null) return rest;
    if (step != null) setState(() => epoch++);
    if (step != null && step.status == 'pending') return rest;
    // C8 : le message de Koach se pose au-dessus de la barre de repos.
    final kt = KTokens.of(context);
    final large = koachLargeText(context);
    showKSnack(
      context,
      message: 'Koach : $text',
      bottom: KBottomInset.of(context),
      duration: const Duration(seconds: 6),
      // Grand texte : le message garde toute la largeur, Koach s'efface.
      leading: KeyedSubtree(
        key: const ValueKey('adapt-advice-toast'),
        child: large
            ? const SizedBox.shrink()
            : KoachView(
                pose: koachPose(KoachUsage.adjustment),
                height: KSpacing.s32,
                width: KSpacing.s24 + KSpacing.s4,
                colors: KoachColors.onColor(kt.texte),
              ),
      ),
      actionLabel: step == null ? null : 'Annuler',
      onAction: step == null
          ? null
          : () {
              store.adaptAdviceDecision(
                widget.week.n,
                widget.day,
                ex,
                'undone',
              );
              if (mounted) setState(() => epoch++);
            },
    );
    return rest;
  }

  /// KM3 : après une série validée, Koach donne la cible de la suivante
  /// (et peut arrêter l'exercice) : message au-dessus de la barre de repos.
  void _koachNews(int k, int i) {
    final ex = widget.exs[k];
    final news = store.koachAfterSet(
      widget.week.n,
      widget.baseDay ?? widget.day,
      ex,
      i,
    );
    if (news == null) return;
    setState(() => epoch++);
    final kt = KTokens.of(context);
    final large = koachLargeText(context);
    showKSnack(
      context,
      message: 'Koach : ${news.text}',
      bottom: KBottomInset.of(context),
      duration: const Duration(seconds: 5),
      leading: KeyedSubtree(
        key: const ValueKey('koach-set-news'),
        child: large
            ? const SizedBox.shrink()
            : KoachView(
                pose: koachPose(
                  news.stop ? KoachUsage.care : KoachUsage.adjustment,
                ),
                height: KSpacing.s32,
                width: KSpacing.s24 + KSpacing.s4,
                colors: KoachColors.onColor(kt.texte),
              ),
      ),
    );
  }

  /// Proposition en attente du moteur (mode libre) pour l'exercice [k].
  Widget? _adaptPendingCard(int k) {
    final ex = widget.exs[k];
    final step = store.adaptPendingAdvice(widget.week.n, widget.day.j, ex);
    if (step == null) return null;
    final t = KTokens.of(context);
    final seconds = specs[k].kind == 'hold' || specs[k].kind == 'holdMax';
    final amount = adaptAmount(step.low, step.high, seconds: seconds);
    final target = [
      if (step.kg != null && step.kg! > 0) adaptKgLabel(step.kg!),
      if (amount.isNotEmpty) amount,
    ].join(' × ');
    void decide(String status) {
      store.adaptAdviceDecision(widget.week.n, widget.day, ex, status);
      setState(() => epoch++);
    }

    // Proposition de Koach dans la carte de l'exercice : groupe cerné d'un
    // filet (pas une carte dans la carte, C7).
    return Padding(
      key: ValueKey('adapt-pending-${ex.id}'),
      padding: const EdgeInsets.only(top: KSpacing.s8),
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: KRadius.menuRadius,
          side: BorderSide(color: t.filet),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpacing.s12),
          child: KoachSays(
            pose: koachPose(KoachUsage.proposal),
            koachHeight: KSize.menuIcon + KSpacing.s4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Je te propose pour la série suivante : $target.',
                  style: KType.corpsFort.copyWith(color: t.texte),
                ),
                for (final r in step.reasons)
                  if (adaptReasonText(
                        r,
                        exerciseName: store.adaptExerciseName,
                        seconds: seconds,
                      )
                      case final x?)
                    Text(x, style: KType.detail.copyWith(color: t.texte2)),
                const SizedBox(height: KSpacing.s8),
                Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s8,
                  children: [
                    KPrimaryButton(
                      key: ValueKey('adapt-accept-${ex.id}'),
                      label: 'Accepter',
                      expand: false,
                      onPressed: () => decide('accepted'),
                    ),
                    KTonalButton(
                      key: ValueKey('adapt-keep-${ex.id}'),
                      label: 'Garder',
                      onPressed: () => decide('kept'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Groupe de lignes ouvrables d'une carte d'exercice (notes du coach,
  /// calibrage) : fond `haute`, rayon des menus, séparateurs (maquette
  /// « Séance »).
  Widget _openRow({
    required Key key,
    required IconData icon,
    required String title,
    String? detail,
    required VoidCallback onTap,
  }) {
    final t = KTokens.of(context);
    return InkWell(
      key: key,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KSize.target),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpacing.s12,
            vertical: KSpacing.s4,
          ),
          child: Row(
            children: [
              Icon(icon, size: KSize.iconSmall, color: t.encre),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KType.detail.copyWith(color: t.texte)),
                    if (detail != null)
                      Text(
                        detail,
                        style: KType.detail.copyWith(color: t.texte2),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              Icon(
                Icons.chevron_right_rounded,
                size: KSize.chevron,
                color: t.texte2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// CI1 : la prescription du chemin calibré, en clair : technique
  /// (série de tête et séries allégées, maintien, EMOM, densité…),
  /// intensité, tempo, test ; règle de douleur du programme toujours
  /// visible ; notes de coach dans la feuille de Koach.
  ///
  /// UI2 (C5) : le titre de la consigne en `encre`, sans capitales, le
  /// texte en texte courant ; les notes du coach et le calibrage forment un
  /// groupe de lignes ouvrables ([_openRows]).
  ///
  /// PR7 : carte compacte : seules la règle de douleur et l'action
  /// (mini-repos) restent sur la carte ; la consigne ([info]) passe dans
  /// la feuille ⓘ de l'exercice.
  ({List<Widget> card, Widget? row, List<String> info}) _coachPanel(
    Exercise ex, {
    bool intraButton = true,
  }) {
    final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
    if (it == null) return (card: const [], row: null, info: const []);
    final kt = KTokens.of(context);
    final block = store.adaptBlockItemFor(widget.week.n, widget.day.j, ex);
    final catalog = store.content.catalog;
    final technique = it.technique?.kind;
    final label = it.kind == kc.SetKind.test
        ? 'Test'
        : technique == null
        ? null
        : ct.techniqueLabel(
            technique,
            every: it.technique?.intervalSeconds ?? 60,
          );
    // PR5 : départs chronométrés déjà dits par l'en-tête du groupe : pas
    // de seconde ligne sur l'exercice.
    final timedByGroup =
        _group != null && technique == kc.SetTechniqueKind.emom;
    final lines = <String>[
      if (label != null && !timedByGroup) '$label : ${ct.coachVolumeText(it)}',
      if (ct.coachIntensityText(it) case final t?) t,
      if (!timedByGroup)
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
      final x =
          r.code == 'adapt.pain_persistent' &&
              !noticeCodes.contains(r.params['zone'])
          ? painStopShortText(r)
          : ct.coachText(r, catalog) ??
                adaptReasonText(r, exerciseName: store.adaptExerciseName);
      if (x != null && !pain.contains(x)) pain.add(x);
    }
    // CI1g (`kalis_adapt` 0.3.1, point imposé par CY) : pompe sur barre
    // basse servie pour une gêne du poignet : la consigne est dite.
    if ((wristBarPushUp(it.exerciseId, it.reasons) ||
            wristBarPushUpWritten(it.exerciseId, store.adaptProfile)) &&
        !pain.contains(kWristBarPushUpCue)) {
      pain.add(kWristBarPushUpCue);
    }
    // CI1g : avis médical pas encore confirmé (« Pas encore ») : rappel
    // sous chaque exercice (une séance reprise saute la page du bilan).
    if (store.clearancePending(widget.week.n, widget.day.j) != null) {
      pain.add(kClearanceWaiting);
    }
    final notes = [
      for (final n
          in block == null
              ? const <String>[]
              : ct.coachItemNotes(block, catalog))
        if (!pain.contains(n)) n,
    ];
    if (lines.isEmpty && pain.isEmpty && notes.isEmpty) {
      return (card: const [], row: null, info: const []);
    }
    final intra = switch (technique) {
      kc.SetTechniqueKind.cluster ||
      kc.SetTechniqueKind.restPause ||
      kc.SetTechniqueKind.myoReps => it.technique?.intraRestSeconds,
      _ => null,
    };
    void sheet() => showKoachSheet<void>(
      context,
      pose: koachPose(KoachUsage.explanation),
      title: store.splitName(ex.name).$1,
      text: [...lines, ...pain, ...notes].join('\n\n'),
    );
    final all = label != null && !timedByGroup
        ? [
            for (final l in lines)
              l.startsWith('$label : ') ? l.substring(label.length + 3) : l,
          ]
        : lines;
    // Une note au moins, ou deux lignes de consigne : la feuille de Koach
    // les reprend toutes (comme l'appui sur le panneau d'avant).
    final row = notes.isEmpty && (lines.length < 2 || !koachGuided)
        ? null
        : _openRow(
            key: ValueKey('coach-notes-${ex.id}'),
            icon: Icons.menu_book_outlined,
            title: notes.isEmpty
                ? 'Consigne du coach'
                : notes.length == 1
                ? 'Note du coach'
                : '${notes.length} notes du coach',
            onTap: sheet,
          );
    return (
      card: [
        if (pain.isNotEmpty) ...[
          const SizedBox(height: KSpacing.s8),
          // L'appui ouvre la feuille de Koach (consigne complète).
          GestureDetector(
            key: ValueKey('coach-panel-${ex.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: sheet,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in pain)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpacing.s4),
                    child: Row(
                      key: ValueKey('coach-pain-${ex.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: KSize.iconSmall,
                          color: kt.avertissement,
                        ),
                        const SizedBox(width: KSpacing.s8),
                        Expanded(
                          child: Text(
                            p,
                            style: KType.detail.copyWith(color: kt.texte),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (intraButton && intra != null && intra > 0)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: KTonalButton(
                key: ValueKey('coach-intra-${ex.id}'),
                icon: Icons.av_timer_rounded,
                label: 'Mini-repos $intra s',
                onPressed: () =>
                    widget.timer.single('INTRA', intra, prepare: false),
              ),
            ),
          ),
      ],
      row: row,
      info: [if (label != null && !timedByGroup) label, ...all],
    );
  }

  /// Ce que le moteur dit de la séance du jour pour un exercice servi :
  /// calibrage, hausse ou baisse, charge gardée, zone épargnée. UI2 : une
  /// ligne ouvrable (la feuille de Koach donne tout).
  Widget? _adaptNotes(Exercise ex) {
    final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
    if (it == null) return null;
    final lines = <String>[];
    for (final r in it.reasons) {
      final t = adaptReasonText(
        r,
        exerciseName: store.adaptExerciseName,
        seconds: prescriptionInSeconds(it),
      );
      if (t == null || lines.contains(t)) continue;
      // Calibrage d'abord : c'est ce qui explique la charge du jour.
      if (r.code == 'adapt.calibration') {
        lines.insert(0, t);
      } else {
        lines.add(t);
      }
    }
    // KM3 : raison de Koach pour cet exercice (une ligne, texte lisible).
    if (store.koachReasonLine(widget.week.n, widget.day.j, ex)
        case final line?) {
      if (!lines.contains(line)) lines.insert(0, line);
    }
    // CIF (point 9) : test de course borné : le report est dit.
    if (store.adaptRunTestCapped(widget.week.n, widget.day.j, ex)) {
      lines.insert(0, kRunTestCappedText);
    }
    if (it.toCalibrate && !lines.any((l) => l.startsWith('Calibrage'))) {
      lines.insert(
        0,
        'Calibrage : je cale la charge sur tes premières séances.',
      );
    }
    if (lines.isEmpty && !it.toCalibrate) return null;
    return _openRow(
      key: ValueKey('adapt-notes-${ex.id}'),
      icon: Icons.auto_awesome_outlined,
      title: lines.first,
      // Correctifs UI : le détail en mode guidé seulement (feuille sinon).
      detail: koachGuided && lines.length > 1 ? lines[1] : null,
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
    );
  }

  /// Record en direct : la série validée bat le meilleur 1RM estimé (ou le
  /// maximum de reps au poids de corps) de cet exercice dans les autres
  /// séances. Message court au-dessus de la barre de repos, retour haptique
  /// plus marqué.
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
    final k = KTokens.of(context);
    showKSnack(
      context,
      message: 'Record : ${store.splitName(ex.name).$1}, ${hit.label}',
      bottom: KBottomInset.of(context),
      duration: const Duration(seconds: 3),
      leading: Icon(
        Icons.emoji_events_rounded,
        color: k.fond,
        size: KSize.icon,
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

  /// ⓘ d'un exercice : consignes, pourquoi, estimation et, quand
  /// l'exercice est dans la base, « Voir la fiche » (cahier §4.1 : fiche
  /// d'Arsenal en 2 appuis depuis la séance).
  /// PR7 : options de l'exercice (séance précédente, note, colonnes) dans
  /// une feuille d'actions : la barre d'outils sous les séries disparaît
  /// (le nombre de séries suit le programme, il ne se règle plus).
  Future<void> _exerciseMenu(
    int k, {
    required bool hasPrevious,
    required bool columns,
    required LogSpec sp,
    required bool showKg,
    required bool showV,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final log = logs[k];
    final v = await showKActionSheet<String>(
      context,
      title: store.splitName(widget.exs[k].name).$1,
      groups: [
        [
          if (hasPrevious)
            KAction(
              icon: Icons.history_rounded,
              label: _prevOpen.contains(k)
                  ? 'Masquer la séance précédente'
                  : 'Séance précédente',
              value: 'previous',
            ),
          KAction(
            icon: log.note.isEmpty
                ? Icons.note_add_outlined
                : Icons.notes_rounded,
            label: _notesOpen.contains(k)
                ? 'Masquer la note'
                : log.note.isEmpty
                ? 'Ajouter une note'
                : 'Afficher la note',
            value: 'note',
          ),
          if (columns)
            const KAction(
              icon: Icons.tune_rounded,
              label: 'Colonnes',
              value: 'columns',
            ),
        ],
      ],
    );
    if (!mounted || v == null) return;
    switch (v) {
      case 'previous':
        setState(() {
          if (!_prevOpen.add(k)) _prevOpen.remove(k);
        });
      case 'note':
        setState(() {
          if (!_notesOpen.add(k)) _notesOpen.remove(k);
        });
      case 'columns':
        await _columns(k, sp, showKg, showV);
    }
  }

  /// PR7 : départ chronométré commun à tous les exercices de la page (hors
  /// groupe du moteur) : un en-tête de carte le porte, avec son chrono.
  int? get _sharedEvery {
    final e = specs.first.every;
    if (e == null || widget.exs.any((x) => x.timer != null)) return null;
    return specs.every((x) => x.every == e) ? e : null;
  }

  /// PR7 : en-tête de la carte : le groupe du moteur (format, chrono), ou
  /// le départ chronométré écrit (« E2MOM · 8 tours · 16 min » et son
  /// chrono) ; null : rien à dire.
  Widget? _timingHeader() {
    if (_group case final g?) return _groupCard(g, bare: true);
    final every = _sharedEvery;
    if (every == null || widget.readOnly) return null;
    var n = 0;
    for (final l in logs) {
      if (l.sets.length > n) n = l.sets.length;
    }
    final k = KTokens.of(context);
    return Row(
      key: const ValueKey('timing-header'),
      children: [
        Expanded(
          child: Text(
            '${ct.everyFormatName(every)} · $n tours · ${_minutes(n * every)}',
            style: KType.corpsFort.copyWith(color: k.encre),
          ),
        ),
        const SizedBox(width: KSpacing.s8),
        KTonalButton(
          key: const ValueKey('timing-clock'),
          icon: Icons.timer_outlined,
          label: 'Lancer',
          onPressed: () => widget.timer.emom(n, every),
        ),
      ],
    );
  }

  /// PR7 : tours d'un groupe au temps (EMOM, superset, circuit,
  /// intervalles) : comptés sur les séries validées, jamais saisis.
  void _recordGroupRounds() {
    final g = _group;
    if (g == null || widget.readOnly || !groupAutoRounds(g.format)) return;
    var n = -1;
    for (final l in logs) {
      if (n < 0 || l.sets.length < n) n = l.sets.length;
    }
    var rounds = 0;
    for (var i = 0; i < n; i++) {
      if (logs.every((l) => l.sets[i].done)) rounds++;
    }
    final planned = groupPlannedRounds(g) ?? n;
    store.sessionLog(widget.week.n, widget.day.j).groups[g.groupId] = {
      'rounds': rounds,
      'completed': rounds >= planned,
    };
    store.saveLogs(affectsProgression: false);
  }

  void _showCue(Exercise ex, {List<Widget> info = const []}) {
    FocusManager.instance.primaryFocus?.unfocus();
    final id = ex.catalogId ?? store.content.idFor(ex.name);
    final sheetId = id != null && store.content.byId.containsKey(id)
        ? id
        : null;
    showKContentSheet<void>(
      context,
      title: store.splitName(ex.name).$1,
      subtitle: 'Consignes de l’exercice',
      builder: (ctx) {
        final k = KTokens.of(ctx);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PR7 : ce qui ne tient plus sur la carte compacte (rôle,
            // repères, consigne du coach, notes de Koach).
            for (var i = 0; i < info.length; i++) ...[
              if (i > 0) const SizedBox(height: KSpacing.s8),
              info[i],
            ],
            if (info.isNotEmpty && ex.cue.isNotEmpty)
              const SizedBox(height: KSpacing.s12),
            if (ex.cue.isNotEmpty) Text(contentText(ex.cue)),
            // L10 (KT-057) : pourquoi cet exercice (programme généré).
            if (ex.why.isNotEmpty) ...[
              const SizedBox(height: KSpacing.s8),
              Text(
                'Pourquoi : ${ex.why}',
                key: ValueKey('${ex.id}-why'),
                style: KType.corps.copyWith(color: k.texte2),
              ),
            ],
            if (!widget.readOnly) ...[
              const SizedBox(height: KSpacing.s12),
              EstimateView(estimate: store.exerciseEstimate(ex)),
            ],
            if (sheetId != null) ...[
              const SizedBox(height: KSpacing.s16),
              KTonalButton(
                key: ValueKey('${ex.id}-sheet'),
                icon: Icons.menu_book_outlined,
                label: 'Voir la fiche',
                expand: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  openExerciseSheet(context, sheetId);
                },
              ),
            ],
          ],
        );
      },
    );
  }

  /// CI1f : groupe d'exercices enchaînés de la page (tous ses exercices
  /// en font partie) ; null : page ordinaire.
  kc.GroupSpec? get _group {
    if (widget.week.n < 1) return null;
    kc.GroupSpec? g;
    for (final e in widget.exs) {
      final x = store.exerciseGroupOf(widget.week.n, widget.day.j, e);
      if (x == null || (g != null && x.groupId != g.groupId)) return null;
      g = x;
    }
    return g;
  }

  @override
  Widget build(BuildContext context) => ListView(
    key: PageStorageKey('exercise-scroll-${widget.exs.first.id}'),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    // 6.17.0 : de quoi sortir de la bande floutée de la barre de repos.
    padding: const EdgeInsets.fromLTRB(
      KSpacing.page,
      KSpacing.s4,
      KSpacing.page,
      KSpacing.s24 + KSpacing.s32,
    ),
    children: [
      // PR7 : l'en-tête du groupe est toujours dans la carte de
      // l'exercice (une seule carte par page).
      if (_merged)
        _mergedCard()
      else
        for (var k = 0; k < widget.exs.length; k++) ...[
          if (k > 0) const SizedBox(height: KSpacing.cardGap),
          _block(k),
        ],
    ],
  );

  /// CI1f : en-tête du groupe (format, chrono, résultat) ; PR5 : [bare],
  /// en tête de la carte de l'exercice.
  Widget _groupCard(kc.GroupSpec g, {bool bare = false}) => _GroupCard(
    bare: bare,
    group: g,
    names: [for (final e in widget.exs) store.splitName(e.name).$1],
    result: widget.readOnly
        ? widget.history!.groups[g.groupId]
        : store.sessionLog(widget.week.n, widget.day.j).groups[g.groupId],
    readOnly: widget.readOnly,
    timer: widget.timer,
    onResult: (r) {
      store.sessionLog(widget.week.n, widget.day.j).groups[g.groupId] = r;
      store.saveLogs(affectsProgression: false);
      setState(() {});
    },
  );

  Widget _block(int k) {
    final t = KTokens.of(context);
    final p = _parts(k);
    final top = _timingHeader();
    return KCard(
      key: ValueKey('exercise-card-${widget.exs[k].id}'),
      outline: p.lead ? t.encre.withValues(alpha: .55) : null,
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s8,
        KSpacing.s8,
        KSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (top != null) ...[
            const SizedBox(height: KSpacing.s8),
            top,
            Divider(height: KSpacing.s16, color: t.filet),
          ],
          ...p.head,
          ...p.header,
          for (var i = 0; i < p.count; i++) ...p.row(i),
          ...p.tail,
        ],
      ),
    );
  }

  /// PR4 : page de plusieurs exercices enchaînés : une seule carte. La
  /// prescription de chaque exercice (A, B…), puis toutes les séries dans
  /// l'ordre d'exécution, tour par tour (A·1, B·1, A·2…), chacune avec sa
  /// coche et sa note en flammes. Purement visuel : la saisie ne change
  /// pas.
  Widget _mergedCard() {
    final t = KTokens.of(context);
    final parts = [for (var k = 0; k < widget.exs.length; k++) _parts(k)];
    var rounds = 0;
    for (final p in parts) {
      if (p.count > rounds) rounds = p.count;
    }
    // En-tête de colonnes commun quand les exercices partagent les mêmes
    // colonnes ; sinon, chaque ligne garde ses champs sans en-tête.
    final same = parts.every(
      (p) => p.columns.join('|') == parts.first.columns.join('|'),
    );
    final header = same
        ? parts
              .map((p) => p.header)
              .firstWhere((h) => h.isNotEmpty, orElse: () => const <Widget>[])
        : const <Widget>[];
    return KCard(
      key: const ValueKey('exercise-card-merged'),
      outline: parts.any((p) => p.lead) ? t.encre.withValues(alpha: .55) : null,
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s8,
        KSpacing.s8,
        KSpacing.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PR5 : l'en-tête du groupe (format, chrono) ouvre la carte ;
          // PR7 : ou le départ chronométré commun.
          if (_timingHeader() case final top?) ...[
            const SizedBox(height: KSpacing.s8),
            top,
            Divider(height: KSpacing.s16, color: t.filet),
          ],
          for (var k = 0; k < parts.length; k++) ...[
            if (k > 0) Divider(height: KSpacing.s16, color: t.filet),
            KeyedSubtree(
              key: ValueKey('exercise-card-${widget.exs[k].id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...parts[k].head, ...parts[k].tail],
              ),
            ),
          ],
          Divider(height: KSpacing.s16, color: t.filet),
          ...header,
          // PR5 : un espace entre deux tours (A·1, B·1 | A·2, B·2…).
          for (var i = 0; i < rounds; i++) ...[
            if (i > 0) const SizedBox(height: KSpacing.s12),
            for (var k = 0; k < parts.length; k++)
              if (i < parts[k].count) ...parts[k].row(i),
          ],
        ],
      ),
    );
  }

  _BlockParts _parts(int k) {
    final t = KTokens.of(context);
    final ex = widget.exs[k];
    final sp = specs[k];
    final log = logs[k];
    final readOnly = widget.readOnly;
    final unresolved = widget.unresolvedIds.contains(ex.id);
    final finalRest = !readOnly && sp.myo
        ? store.restAfterSet(ex, sp, log.sets.length - 1, log.sets.length)
        : null;
    final (title, rawSubtitle) = store.splitName(ex.name);
    // PR10 : en séance, le matériel entre parenthèses (« (par haltère) »)
    // reste dans la feuille ⓘ : titre sur une ligne.
    final bare = title.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '');
    final shownTitle = readOnly || bare.isEmpty ? title : bare;
    // PR5 : pas de répétition sur la carte : « enchaîné » est dit par la
    // carte commune, « lift principal » par le surtitre.
    var subtitle = _merged
        ? rawSubtitle
              .replaceAll(RegExp(r',?\s*enchaîn\S*', caseSensitive: false), '')
              .replaceAll(RegExp(r'^[\s,·]+|[\s,·]+$'), '')
        : rawSubtitle;
    if (ex.main && subtitle.toLowerCase() == 'lift principal') subtitle = '';
    final interval = ex.interval;
    final noLoad =
        sp.kind == 'duration' ||
        sp.kind == 'distance' ||
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
    final recordedLoad = recordedLoads.length == 1
        ? unitText(decimalFieldText(recordedLoads.single), 'kg')
        : '—';
    final loadLabel = readOnly
        ? recordedLoad
        : store.loadLabel(ex, week: widget.week.n, day: widget.day.j);
    final shownLoad =
        (readOnly || !noLoad) &&
        loadLabel != '—' &&
        (loadLabel != 'PdC' || showKg);
    // Une charge chiffrée en grand ; « à renseigner » ou « ? » passe dans
    // le lien vers « Mes références » (ou une puce), le volume prend alors
    // le grand chiffre.
    final numericLoad = RegExp(r'\d').hasMatch(loadLabel);
    final showBigLoad = shownLoad && numericLoad;
    final kindLabel = _kindLabel(sp);
    // PR6 : carte commune : un exercice au même départ chronométré qu'un
    // exercice d'avant n'en répète ni le format ni le chrono.
    final sameTiming =
        _merged &&
        sp.every != null &&
        specs.take(k).any((x) => x.every == sp.every);
    final showIntensity =
        ex.intensity.isNotEmpty &&
        !kindLabel.toLowerCase().startsWith(ex.intensity.toLowerCase());
    final prev = !readOnly && widget.week.n > 0
        ? store.previousLog(widget.week.n, widget.day.j, ex)
        : null;
    // CI1 : lignes nommées par leur rôle dans la technique servie (série
    // de tête, allégées, montées, tentatives, intervalles).
    String baseLabel(int i) =>
        (widget.adapt && ex.engine
            ? store.adaptRowLabel(widget.week.n, widget.day.j, ex, i)
            : null) ??
        store.setLabel(sp, i);
    // Un rôle répété sur plusieurs lignes (« Test ») est numéroté : chaque
    // ligne du tableau se distingue.
    final baseLabels = [for (var i = 0; i < log.sets.length; i++) baseLabel(i)];
    String ownLabel(int i) {
      final label = i < baseLabels.length ? baseLabels[i] : baseLabel(i);
      final same = [
        for (var j = 0; j < baseLabels.length; j++)
          if (baseLabels[j] == label) j,
      ];
      if (same.length < 2 || RegExp(r'\d').hasMatch(label)) return label;
      return '$label ${same.indexOf(i) + 1}';
    }

    // PR4 : carte commune d'exercices enchaînés : lettre de l'exercice.
    String rowLabel(int i) =>
        _merged ? '${String.fromCharCode(65 + k)}·${ownLabel(i)}' : ownLabel(i);

    final missing = _missingReference(ex, readOnly);
    // Bandeau des mini-séries présent (cluster, myo-reps, rest-pause servis
    // par le moteur) : il porte le mini-repos.
    // CIF (point 12) : décidé sur toutes les lignes de l'exercice, pas
    // seulement la première ouverte : le bouton du mini-repos n'apparaît
    // plus au-dessus du tableau une fois la dernière série validée (saut de
    // hauteur de la carte).
    final miniSets =
        !readOnly &&
        widget.adapt &&
        ex.engine &&
        [
          for (var i = 0; i < log.sets.length; i++)
            store.miniSetPlanFor(widget.week.n, widget.day.j, ex, i),
        ].any((p) => p != null);
    final panel = !readOnly && widget.adapt && ex.engine
        ? _coachPanel(ex, intraButton: !miniSets)
        : null;
    final coach = panel?.card ?? const <Widget>[];
    final coachRow = panel?.row;
    final notesRow = !readOnly && widget.adapt && ex.engine
        ? _adaptNotes(ex)
        : null;
    final openRows = [?coachRow, ?notesRow];
    // Ligne courante (contour `encre`) : la première série à faire.
    // PR4 : carte commune : seule l'étape suivante, tour par tour.
    final next = _merged ? _nextStep() : null;
    final current = readOnly
        ? -1
        : next != null
        ? (next.$1 == k ? next.$2 : -1)
        : log.sets.indexWhere((s) => !s.done);
    final hasTimer = !readOnly && sp.timed;
    final valueColumn = unresolved ? 'Valeur' : _valueColumn(sp.kind);
    final compact = _splitColumns(context, showKg, showRir, showV, hasTimer);
    final columns = [
      if (showKg) 'kg',
      valueColumn,
      if (showV && !compact) 'm/s',
    ];
    final actions = 1 + (hasTimer ? 1 : 0);
    final detailStyle = KType.detail.copyWith(color: t.texte2);
    // Cible de réserve lue dans l'intensité (« Difficulté visée 7/10 ·
    // RIR 2 ») : badge à droite de la charge ; autre intensité : repère.
    final rirMatch = RegExp(r'RIR\s*(\S+)').firstMatch(ex.intensity);
    final levelMatch = RegExp(r'(\d+)\s*/\s*10').firstMatch(ex.intensity);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    // PR10 : sans « x/10 » écrit, la difficulté se déduit du RIR (même
    // pastille que les lignes servies par Koach).
    String? levelOfRir(String rir) {
      final v = double.tryParse(
        RegExp(r'\d+(?:[.,]\d+)?').stringMatch(rir)?.replaceAll(',', '.') ?? '',
      );
      return v == null ? null : '${kc.Flames.fromRir(v)}';
    }

    final target = !readOnly && showIntensity && rirMatch != null
        ? (
            rirMatch.group(1)!,
            levelMatch?.group(1) ?? levelOfRir(rirMatch.group(1)!),
          )
        : null;
    final meta = <Widget>[
      if (shownLoad && !numericLoad && missing == null)
        _Meta(Icons.fitness_center_rounded, 'Charge : $loadLabel'),
      // « Reps » redit l'en-tête de colonne : le repère ne nomme que les
      // autres mesures.
      if (!unresolved && (sp.kind != 'reps' || sp.special) && !sameTiming)
        _Meta(Icons.repeat_rounded, kindLabel),
      if (!readOnly && showIntensity && target == null)
        _Meta(Icons.local_fire_department_outlined, nbsp(ex.intensity)),
      if (!readOnly && ex.tempo.isNotEmpty)
        _Meta(Icons.bolt_rounded, nbsp(ex.tempo)),
      // PR6 : départs chronométrés : le format dit déjà le repos.
      if (!readOnly && ex.rest.isNotEmpty && ex.rest != '—' && sp.every == null)
        _Meta(Icons.timer_outlined, 'Repos ${nbsp(ex.rest)}'),
      if (finalRest != null)
        _Meta(Icons.timer_outlined, 'Repos final ${fmt(finalRest)}'),
    ];

    // 6.15.0 : le lift principal se distingue — contour et surtitre en
    // `encre`, charge et cible en `encre` ; les autres exercices gardent
    // une carte neutre (charge en `texte`, cible sur `haute`).
    final lead = ex.main && !readOnly;
    final ink = lead ? t.encre : t.texte;
    // PR7 : carte compacte en séance : rôle, repères (tempo, repos,
    // technique), consigne du coach, notes de Koach et référence estimée
    // passent dans la feuille ⓘ de l'exercice.
    final estimate = readOnly
        ? null
        : store.referenceEstimateText(
            widget.adapt && ex.engine
                ? (store.programExerciseOf(widget.week.n, widget.day.j, ex) ??
                      ex)
                : ex,
          );
    final info = <Widget>[
      if (subtitle.isNotEmpty) Text(subtitle, style: detailStyle),
      if (meta.isNotEmpty)
        Wrap(spacing: KSpacing.s12, runSpacing: KSpacing.s4, children: meta),
      for (final l in panel?.info ?? const <String>[])
        Text(l, style: KType.corps.copyWith(color: t.texte)),
      if (estimate != null)
        Text(
          estimate,
          key: ValueKey('reference-estimate-${ex.id}'),
          style: detailStyle,
        ),
      // Notes du coach et calibrage : deux lignes ouvrables.
      if (openRows.isNotEmpty)
        Material(
          color: t.haute,
          shape: KRadius.menuShape,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < openRows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: KSpacing.s14,
                    endIndent: KSpacing.s14,
                    color: t.filet,
                  ),
                openRows[i],
              ],
            ],
          ),
        ),
    ];
    final head = <Widget>[
      // ----- Prescription -----
      Padding(
        padding: const EdgeInsets.only(right: KSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: KSpacing.s8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // C3 : jamais coupé ; C4 : capitales du titre
                        // par le jeton (U3).
                        // PR5 : carte commune : la lettre de l'exercice
                        // (A, B…) devant son nom.
                        KFitTitle(
                          _merged
                              ? '${String.fromCharCode(65 + k)} · ${t.title(shownTitle)}'
                              : t.title(shownTitle),
                          style: t.titleStyle(
                            KType.titreSeance.copyWith(color: t.texte),
                          ),
                        ),
                        // PR7 : en séance, le rôle est dans la feuille ⓘ.
                        if (readOnly && subtitle.isNotEmpty)
                          Text(subtitle, style: detailStyle),
                      ],
                    ),
                  ),
                ),
                // PR7 : séance précédente, note et colonnes dans le menu de
                // l'exercice (plus de barre d'outils sous les séries).
                if (!readOnly)
                  KIconButton(
                    key: ValueKey('${ex.id}-menu'),
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'Plus d’options',
                    color: log.note.isNotEmpty || _notesOpen.contains(k)
                        ? t.encre
                        : t.texte2,
                    onPressed: () => _exerciseMenu(
                      k,
                      hasPrevious: prev != null,
                      columns: !noLoad,
                      sp: sp,
                      showKg: showKg,
                      showV: showV,
                    ),
                  ),
                if (!readOnly || (!unresolved && ex.cue.isNotEmpty))
                  KIconButton(
                    key: ValueKey('${ex.id}-instructions'),
                    icon: Icons.info_outline_rounded,
                    tooltip: 'Consignes de l’exercice',
                    color: t.texte2,
                    onPressed: () => _showCue(ex, info: info),
                  ),
              ],
            ),
            const SizedBox(height: KSpacing.s4),
            // Correctifs UI (11/10/2026) : ce qui compte d'un coup d'œil
            // sur une ligne — charge en grand (`encre`), volume, cible
            // de réserve (RIR) mise en avant à droite ; le reste en
            // repères discrets dessous (repos, tempo, technique).
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: KSpacing.s8,
                    runSpacing: KSpacing.s4,
                    children: [
                      if (showBigLoad)
                        Text(
                          frenchNumbersText(loadLabel),
                          style: KType.chiffre.copyWith(color: ink),
                        ),
                      Text(
                        readOnly
                            ? '${log.sets.where((s) => s.done).length} / ${log.sets.length} séries validées'
                            : nbsp(
                                volumeText(
                                  store.setsLabel(ex),
                                  timed: _group != null || _sharedEvery != null,
                                ),
                              ),
                        // PR10 : volume toujours au même corps (chiffres
                        // moyens), avec ou sans charge : les exercices
                        // d'une carte commune s'alignent.
                        style: readOnly
                            ? KType.corpsFort.copyWith(color: t.texte)
                            : KType.chiffreMoyen.copyWith(
                                color: showBigLoad ? t.texte : ink,
                              ),
                      ),
                      // Grand texte : la cible passe sous la charge.
                      if (target case (final rir, final level) when largeText)
                        _TargetBadge(
                          key: ValueKey('target-${ex.id}'),
                          rir: rir,
                          level: level,
                          lead: lead,
                        ),
                      // État (C5) : texte et icône en `validation`.
                      if (readOnly)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: KSize.iconSmall,
                              color: t.validation,
                            ),
                            const SizedBox(width: KSpacing.s4),
                            Flexible(
                              child: Text(
                                'Enregistré',
                                style: KType.libelle.copyWith(
                                  color: t.validation,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (target case (final rir, final level) when !largeText)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: KSpacing.s8,
                      end: KSpacing.s4,
                    ),
                    child: _TargetBadge(
                      key: ValueKey('target-${ex.id}'),
                      rir: rir,
                      level: level,
                      lead: lead,
                    ),
                  ),
              ],
            ),
            if (readOnly && meta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Wrap(
                  spacing: KSpacing.s12,
                  runSpacing: KSpacing.s4,
                  children: meta,
                ),
              ),
            if (missing != null) missing,
            // L8 (KT-041) : consigne du mode prudent.
            // G9 : exercice servi par le moteur, la prudence est dans
            // ses cibles (pas de seconde règle de charge).
            if (!readOnly && !ex.engine && store.cautionNote(ex) != null)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: KSize.iconSmall,
                      color: t.avertissement,
                    ),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(
                      child: Text(
                        store.cautionNote(ex)!,
                        key: ValueKey('caution-${ex.id}'),
                        style: KType.detail.copyWith(color: t.texte),
                      ),
                    ),
                  ],
                ),
              ),
            if (readOnly && (log.prescribed != null || log.koach != null)) ...[
              const SizedBox(height: KSpacing.s8),
              if (log.prescribed != null)
                Text(
                  'Prescrit ce jour-là : ${log.prescribed}',
                  key: ValueKey('prescribed-${ex.id}'),
                  style: detailStyle,
                ),
              if (log.koach != null) Text(log.koach!, style: detailStyle),
            ],
            ...coach,
            // Séance précédente : affichée à la demande (menu de
            // l'exercice), correctifs UI.
            if (prev != null && _prevOpen.contains(k))
              Padding(
                key: ValueKey('previous-${ex.id}'),
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: KSize.chevron,
                      color: t.texte2,
                    ),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(
                      child: Text(
                        '${store.program.weekLabel(prev.week)} : ${frenchNumbersText(store.summarize(prev.log, kg: showKg))}',
                        style: detailStyle.copyWith(
                          fontFeatures: KFont.tabular,
                        ),
                      ),
                    ),
                    KTonalButton(
                      label: 'Reprendre',
                      onPressed: () => _reusePrevious(k, prev.log),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: KSpacing.s8),
      // ----- Chronos de mode -----
      if (!readOnly && interval != null && ex.timer == null && _group == null)
        _big(
          Icons.timer_outlined,
          'Lancer ${interval.rounds} × ${interval.work} s / ${interval.rest} s',
          () => widget.timer.startInterval(
            interval.rounds,
            interval.work,
            interval.rest,
          ),
        ),
      if (!readOnly && ex.timer != null && !sp.cluster && _group == null)
        _modeButton(ex),
      if (!readOnly && ex.timer == null && sp.kind == 'emom' && _group == null)
        _big(
          Icons.timer_outlined,
          'Lancer l’EMOM de ${sp.seconds! ~/ 60} min',
          () => widget.timer.emom(sp.seconds! ~/ 60, 60),
        ),
      // PR1 : séries au départ chronométré (E2MOM, E90s…).
      // PR6 : carte commune : un seul chrono pour les exercices au même
      // départ.
      if (!readOnly &&
          ex.timer == null &&
          sp.every != null &&
          _group == null &&
          _sharedEvery == null &&
          !sameTiming)
        _everyButton(sp, log.sets.length),
      if (!readOnly && ex.timer == null && sp.kind == 'duration')
        _big(
          Icons.timer_outlined,
          'Lancer ${sp.seconds! ~/ 60} min',
          () => widget.timer.single('DURÉE', sp.seconds!),
        ),
      // Correctifs UI : le mini-repos d'un cluster servi par le moteur
      // part du bandeau des mini-séries ; pas de second bouton.
      if (!readOnly && sp.cluster && sp.intra != null && !miniSets)
        _big(
          Icons.av_timer_rounded,
          'Mini-repos du cluster, ${sp.intra} s',
          () => widget.timer.single('INTRA', sp.intra!, prepare: false),
        ),
      // KM3 : suggestion de Koach (charge de la première série, test
      // court), validée d'un tap ou refusée avec une raison.
      if (!readOnly && widget.adapt && ex.engine)
        KoachSuggestionCard(
          key: ValueKey('koach-card-${ex.id}-$epoch'),
          week: widget.week.n,
          day: widget.baseDay ?? widget.day,
          exercise: ex,
          onChanged: () => setState(() => epoch++),
        ),
    ];
    final header = <Widget>[
      // ----- Tableau des séries : en-tête de colonnes + lignes -----
      // G9 correction 1 : sans ligne de saisie visible (toutes les
      // séries résumées, en lecture), pas d'en-tête de colonnes. PR5 :
      // en séance, les séries validées gardent leur ligne.
      if (readOnly ? log.sets.any((s) => !s.done) : log.sets.isNotEmpty)
        KSetTable(columns: columns, rows: const [], actionCount: actions),
    ];
    List<Widget> row(int i) => [
      // G9 correction 1 : en lecture (fin de séance, historique), les
      // séries validées résumées en une ligne. PR5 : en séance, chaque
      // série garde sa ligne ; validée, sa flamme remplace la coche.
      if (log.sets[i].done && readOnly)
        SetSummaryLine(
          setLabel: rowLabel(i),
          done: setDoneText(log.sets[i], sp, units: !unresolved),
          flames: flamesOf(log.sets[i]),
          unknown: log.sets[i].flamesUnknown,
          excluded: log.sets[i].excluded,
        )
      else ...[
        Padding(
          padding: const EdgeInsets.only(top: KSpacing.s4),
          child: _SetRow(
            key: ValueKey('${ex.id}-$i-$epoch'),
            checkKey: ValueKey('set-check-${ex.id}-$i'),
            label: rowLabel(i),
            current: i == current,
            lockReps: (log.sets[i].parts?.isNotEmpty ?? false),
            entry: log.sets[i],
            spec: sp,
            showKg: showKg,
            showRir: showRir,
            showV: showV,
            readOnly: readOnly,
            issue: _issues[(k, i)],
            onEdited: readOnly ? null : () => _edited(k, i),
            onCheck: readOnly ? null : () => _checkSet(k, i),
            // PR5 : flamme à la place de la coche (série validée notée).
            onFlame: !readOnly && flameSets && log.sets[i].done
                ? () => _openFlames(k, i, rowLabel(i))
                : null,
            onUncheck: readOnly ? null : () => _checkSet(k, i),
            onLongPressLabel: !readOnly && flameSets && log.sets[i].done
                ? () => _openFlames(k, i, rowLabel(i))
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
                    (int.tryParse(log.sets[i].reps) ?? (sp.seconds! ~/ 60)) *
                        60,
                  )
                : null,
          ),
        ),
        // CI1f : mini-séries de la série en cours (la première non
        // validée), ou d'une série déjà commencée.
        if (!readOnly &&
            !log.sets[i].done &&
            widget.adapt &&
            ex.engine &&
            (i == log.sets.indexWhere((s) => !s.done) ||
                (log.sets[i].parts?.isNotEmpty ?? false)))
          if (store.miniSetPlanFor(widget.week.n, widget.day.j, ex, i)
              case final plan?)
            _MiniSetStrip(
              key: ValueKey('miniset-${ex.id}-$i-$epoch'),
              id: '${ex.id}-$i',
              plan: plan,
              entry: log.sets[i],
              target: store
                  .adaptGoal(widget.week.n, widget.day.j, ex, i)
                  ?.prefill,
              onChanged: () {
                log.sets[i].edited = true;
                store.saveLogs(affectsProgression: false);
                setState(() => epoch++);
              },
              onIntra: (sec) =>
                  widget.timer.single('INTRA', sec, prepare: false),
            ),
      ],
    ];
    final tail = <Widget>[
      if (!readOnly && widget.adapt)
        if (_adaptPendingCard(k) case final card?) card,
      if (readOnly && log.sets.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: KSpacing.s12),
          child: Text(
            'Aucune série enregistrée.',
            style: KType.corps.copyWith(color: t.texte2),
          ),
        ),
      if (_notesOpen.contains(k)) ...[
        const SizedBox(height: KSpacing.s8),
        if (readOnly)
          Material(
            color: t.haute,
            shape: KRadius.menuShape,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KSpacing.s16,
                vertical: KSpacing.s12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: KType.detail.copyWith(color: t.texte2)),
                  Text(log.note, style: KType.corps.copyWith(color: t.texte)),
                ],
              ),
            ),
          )
        else
          _NoteField(
            fieldKey: ValueKey('${ex.id}-note'),
            initial: log.note,
            style: KType.corps.copyWith(color: t.texte),
            decoration: _noteDecoration(
              t,
              label: 'Notes',
              hint: 'Sensations, ajustements…',
            ),
            onChanged: (value) {
              log.note = value;
              store.saveLogs(affectsProgression: false);
            },
          ),
        const SizedBox(height: KSpacing.s8),
      ],
    ];
    return (
      head: head,
      header: header,
      columns: columns,
      row: row,
      count: log.sets.length,
      tail: tail,
      lead: lead,
    );
  }

  /// Champ de note de l'exercice : `haute`, rayon des menus, sans cadre.
  InputDecoration _noteDecoration(
    KTokens t, {
    required String label,
    String? hint,
  }) {
    final border = OutlineInputBorder(
      borderRadius: KRadius.menuRadius,
      borderSide: t.controlSide,
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: t.haute,
      labelStyle: KType.detail.copyWith(color: t.texte2),
      hintStyle: KType.corps.copyWith(color: t.texte3),
      contentPadding: EdgeInsets.symmetric(
        horizontal: KSpacing.s16,
        vertical: KDensity.of(KSpacing.s12),
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: KRadius.menuRadius,
        borderSide: BorderSide(color: t.encre, width: KSize.current),
      ),
    );
  }

  /// Colonnes affichées (charge, vitesse) : feuille d'actions (C10).
  Future<void> _columns(int k, LogSpec sp, bool showKg, bool showV) async {
    final log = logs[k];
    IconData box(bool on) =>
        on ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded;
    final v = await showKActionSheet<String>(
      context,
      title: 'Colonnes',
      subtitle: store.splitName(widget.exs[k].name).$1,
      groups: [
        [
          KAction(
            icon: box(showKg),
            label: 'Charge (kg)',
            detail: showKg ? 'Affichée' : 'Masquée',
            value: 'kg',
          ),
          if (sp.kind == 'reps')
            KAction(
              icon: box(showV),
              label: 'Vitesse (m/s)',
              detail: showV ? 'Affichée' : 'Masquée',
              value: 'v',
            ),
        ],
      ],
    );
    if (v == null || !mounted) return;
    setState(() {
      if (v == 'kg') log.showKg = !showKg;
      if (v == 'v') log.showV = !showV;
    });
    store.saveLogs(affectsProgression: false);
  }

  /// Chrono de mode : bouton tonal pleine largeur (l'action principale de
  /// la page reste la validation des séries, C2).
  Widget _big(IconData ic, String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(bottom: KSpacing.s12),
    child: KTonalButton(
      icon: ic,
      label: label,
      expand: true,
      onPressed: action,
    ),
  );

  /// PR1 : chrono des départs (« Lancer l’E2MOM, 8 × 120 s »).
  Widget _everyButton(LogSpec sp, int n) {
    final s = sp.every!;
    return _big(
      Icons.timer_outlined,
      'Lancer l’${ct.everyFormatName(s)}, $n × $s s',
      () => widget.timer.emom(n, s),
    );
  }

  Widget _modeButton(Exercise ex) {
    final tm = ex.timer!;
    switch (tm['type'] as String) {
      case 'emom':
        final r = tm['rounds'] as int, itv = tm['interval'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer l’EMOM, $r × $itv s',
          () => widget.timer.emom(r, itv),
        );
      case 'amrap':
        final s = tm['sec'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer l’AMRAP de ${s ~/ 60} min',
          () => widget.timer.single('AMRAP', s),
        );
      case 'hiit':
        final r = tm['rounds'] as int,
            wk = tm['work'] as int,
            rs = tm['rest'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer $r × $wk s / $rs s',
          () => widget.timer.startInterval(r, wk, rs),
        );
      case 'hold':
        final s = tm['sec'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer le chrono de $s s',
          () => widget.timer.single('TENUE', s),
        );
    }
    return const SizedBox.shrink();
  }

  /// En-tête de la colonne de valeur (sans capitales, C4).
  static String _valueColumn(String kind) => switch (kind) {
    'hold' || 'holdMax' => 's',
    'duration' => 'min',
    'distance' => 'm',
    'repsMax' => 'Reps max',
    _ => 'Reps',
  };

  String _kindLabel(LogSpec sp) {
    const labels = {
      'reps': 'Reps',
      'repsMax': 'Max de reps',
      'hold': 'Tenue chronométrée',
      'holdMax': 'Max de temps',
      'duration': 'Durée',
      'distance': 'Distance',
      'interval': 'Intervalles',
      'emom': 'EMOM',
      'amrap': 'AMRAP',
    };
    if (sp.restPause) return 'Rest-pause, mini-repos ${sp.intra} s';
    if (sp.myo) return 'Myo-reps, mini-repos ${sp.intra} s';
    // PR6 : « E2MOM · départ toutes les 2 min », « E90s · départ toutes
    // les 90 s ».
    if (sp.every case final e?) {
      return '${ct.everyFormatName(e)} · départ toutes les '
          '${e % 60 == 0 ? '${e ~/ 60} min' : '$e s'}';
    }
    if (sp.stages != null) {
      return 'Drop set mécanique, ${sp.stages} paliers enchaînés';
    }
    if (sp.cluster) return 'Clusters, mini-repos ${sp.intra} s';
    return labels[sp.kind] ?? sp.kind;
  }
}

// --- Tableau des séries : mêmes mesures que `KSetTable` / `KSetRow` du kit
// (numéro 44, cellules égales séparées de 8, actions de 48), avec des champs
// de saisie, un numéro qui se réduit au lieu de se couper et l'appui long.

/// Champ de saisie d'une série : pilule de 48 dp, chiffre centré
/// (`chiffreMoyen`), `surface` sur la ligne courante, `haute` ailleurs ;
/// contour `danger` quand la saisie est refusée.
/// U0.19 : dans un champ de charge, un point tapé s'affiche en virgule
/// (même longueur : curseur et sélection gardés).
final _decimalComma = TextInputFormatter.withFunction(
  (_, value) => value.copyWith(text: decimalFieldText(value.text)),
);

class _SetField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool decimal, current, error, readOnly, dimmed;

  /// U0.19 : un point tapé s'affiche en virgule (champ de charge).
  final bool decimalComma;
  final String semanticLabel;
  const _SetField({
    required this.controller,
    required this.onChanged,
    required this.semanticLabel,
    this.decimal = true,
    this.decimalComma = false,
    this.current = false,
    this.error = false,
    this.readOnly = false,
    this.dimmed = false,
  });

  @override
  State<_SetField> createState() => _SetFieldState();
}

class _SetFieldState extends State<_SetField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  void _selectAll() {
    _focus.requestFocus();
    final c = widget.controller;
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    // Correctifs UI (11/10/2026) : champ au rayon des groupes (12), plus
    // une grande pilule.
    final shape = RoundedRectangleBorder(
      borderRadius: KRadius.menuRadius,
      side: widget.error
          ? BorderSide(color: k.danger, width: KSize.current)
          : widget.current
          ? BorderSide.none
          : k.controlSide,
    );
    final color = widget.current ? k.surface : k.haute;
    final style = KType.chiffreMoyen.copyWith(
      color: widget.dimmed ? k.texte2 : k.texte,
    );
    if (widget.readOnly) {
      return KSetField(
        widget.controller.text.isEmpty ? '–' : widget.controller.text,
        semanticLabel: widget.semanticLabel,
        dimmed: widget.dimmed,
      );
    }
    // La pilule entière est touchable (48 dp) : un appui sélectionne tout.
    // Un nombre reste entier dans sa pilule (cahier §5.2) : au-delà de
    // 130 % de texte, le chiffre du champ n'est plus agrandi.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _selectAll,
        child: Material(
          color: color,
          shape: shape,
          child: ConstrainedBox(
            // 6.15.0 : hauteur selon les espacements choisis.
            constraints: BoxConstraints(
              minHeight: KDensity.field(KSize.target),
            ),
            // Champ sans focus : les gestes vont à la pilule (un appui
            // sélectionne tout, un glissement horizontal change de page) ;
            // avec le focus, au champ (curseur, sélection).
            child: Center(
              child: IgnorePointer(
                ignoring: !_focus.hasFocus,
                // Même seuil de glissement que la vue paginée : un
                // glissement commencé sur un champ actif change de page.
                child: KPagerSlop(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.decimal,
                    ),
                    inputFormatters: widget.decimalComma
                        ? [_decimalComma]
                        : null,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: style,
                    cursorColor: k.encre,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '–',
                      hintStyle: style.copyWith(color: k.texte3),
                      semanticCounterText: '',
                      // Le texte occupe le milieu de la pilule ; ses marges
                      // restent touchables (un appui au bord sélectionne
                      // aussi tout).
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KSpacing.s8,
                        vertical: KSpacing.s4,
                      ),
                    ),
                    onTap: _selectAll,
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une colonne de [_SetRow] de plus quand la place manque : la vitesse
/// passe sous la ligne (largeur à texte agrandi).
bool _splitColumns(
  BuildContext context,
  bool kg,
  bool rir,
  bool velocity,
  bool hasTimer,
) {
  final count = 1 + (kg ? 1 : 0) + (rir ? 1 : 0) + (velocity ? 1 : 0);
  final width = MediaQuery.sizeOf(context).width.clamp(0.0, KSpacing.maxWidth);
  final available =
      width -
      2 * KSpacing.page -
      KSpacing.s16 -
      KSpacing.s12 -
      KSpacing.s12 -
      (KSize.target - KSpacing.s4) -
      KSize.target * (hasTimer ? 2 : 1) -
      count * KSpacing.s8;
  return count > 2 &&
      available / count <
          MediaQuery.textScalerOf(context).scale(KSize.target + KSpacing.s4);
}

class _SetRow extends StatefulWidget {
  final String label;
  final SetEntry entry;
  final LogSpec spec;
  final bool showKg, showRir, showV;
  final bool readOnly;
  final VoidCallback? onCheck;
  final VoidCallback? onTimer;

  /// Ligne courante (première série à faire) : fond `haute`, contour
  /// `encre`.
  final bool current;

  /// Saisie refusée à la coche (KT-009) : champ et explication.
  final SetCheck? issue;
  final VoidCallback? onEdited;

  /// Koach (D11) : appui long sur le numéro d'une série validée.
  final VoidCallback? onLongPressLabel;

  /// CI1f : série notée mini-série par mini-série : le total se calcule
  /// (champ des répétitions en lecture).
  final bool lockReps;

  /// Clé du bouton de validation (tests).
  final Key? checkKey;

  /// PR5 : série validée notée en flammes : la flamme remplace la coche ;
  /// un appui ([onFlame]) ouvre la note en popup, un appui long
  /// ([onUncheck]) annule la validation. Null : la coche reste.
  final VoidCallback? onFlame;
  final VoidCallback? onUncheck;
  const _SetRow({
    super.key,
    this.onFlame,
    this.onUncheck,
    this.lockReps = false,
    this.checkKey,
    this.issue,
    this.onEdited,
    this.onLongPressLabel,
    this.current = false,
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

  @override
  void initState() {
    super.initState();
    // U0.19 : charge montrée avec la virgule (« 62,5 ») ; le journal garde
    // le point (« 62.5 »).
    kg = TextEditingController(text: decimalFieldText(widget.entry.kg));
    reps = TextEditingController(text: widget.entry.reps);
    rir = TextEditingController(text: widget.entry.rir);
    v = TextEditingController(text: widget.entry.v);
  }

  @override
  void dispose() {
    for (final c in [kg, reps, rir, v]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _f(
    TextEditingController c,
    void Function(String) on, {
    required String name,
    required SetField field,
    bool decimal = true,
    bool decimalComma = false,
    bool locked = false,
  }) {
    final done = widget.entry.done;
    return _SetField(
      controller: c,
      semanticLabel: '$name, série ${widget.label}',
      decimal: decimal,
      decimalComma: decimalComma,
      current: widget.current,
      readOnly: widget.readOnly || locked,
      error: widget.issue?.field == field,
      dimmed: !widget.current && !done && !widget.readOnly,
      onChanged: (text) {
        on(text);
        // CI1c : saisie de l'utilisateur (brouillon gardé, jamais refaite
        // à la réouverture).
        widget.entry.edited = true;
        store.saveLogs(affectsProgression: false);
        widget.onEdited?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final e = widget.entry;
    final kind = widget.spec.kind;
    final done = e.done;
    final compact = _splitColumns(
      context,
      widget.showKg,
      widget.showRir,
      widget.showV,
      widget.onTimer != null,
    );
    final value = switch (kind) {
      'hold' || 'holdMax' => 'Secondes',
      'duration' => 'Minutes',
      'distance' => 'Mètres',
      _ => 'Répétitions',
    };
    final cells = <Widget>[
      if (widget.showKg)
        _f(
          kg,
          (t) => e.kg = decimalStoredText(t),
          name: 'Charge en kg',
          field: SetField.kg,
          decimalComma: true,
        ),
      _f(
        reps,
        (t) => e.reps = t,
        name: value,
        field: SetField.value,
        decimal: false,
        locked: widget.lockReps && !widget.readOnly,
      ),
      if (widget.showRir && !compact)
        _f(rir, (t) => e.rir = t, name: 'Effort', field: SetField.effort),
      if (widget.showV && !compact)
        _f(v, (t) => e.v = t, name: 'Vitesse en m/s', field: SetField.velocity),
    ];
    final flame = widget.onFlame;
    final check = !widget.readOnly && done && flame != null
        ? FlameSetButton(
            key: ValueKey('set-flame-${widget.label}'),
            setLabel: widget.label,
            value: setFlamesOf(e),
            unknown: e.flamesUnknown,
            excluded: e.excluded,
            onTap: flame,
            onLongPress: widget.onUncheck ?? widget.onCheck ?? () {},
          )
        : widget.readOnly
        ? Semantics(
            label: 'Série ${widget.label} ${done ? "validée" : "non validée"}',
            excludeSemantics: true,
            child: Container(
              width: KSpacing.s32 + KSpacing.s4,
              height: KSpacing.s32 + KSpacing.s4,
              decoration: ShapeDecoration(
                color: done
                    ? k.validation.withValues(alpha: .14)
                    : Colors.transparent,
                shape: KRadius.pill,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.remove_rounded,
                size: KSize.icon,
                color: done ? k.validation : k.texte2,
              ),
            ),
          )
        : IconButton(
            key: widget.checkKey,
            tooltip: done
                ? 'Annuler la série ${widget.label}'
                : 'Valider la série ${widget.label}',
            style: IconButton.styleFrom(
              backgroundColor: done
                  ? k.validation.withValues(alpha: .14)
                  : Colors.transparent,
              foregroundColor: done ? k.validation : k.texte2,
              minimumSize: Size(KSize.target, KDensity.field(KSize.target)),
              tapTargetSize: KDensity.factor < 1
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
              shape: KRadius.pill,
            ),
            isSelected: done,
            icon: const Icon(Icons.check_rounded, size: KSize.icon),
            onPressed: widget.onCheck,
          );
    final row = Row(
      children: [
        SizedBox(
          width: KSize.target - KSpacing.s4,
          child: GestureDetector(
            onLongPress: widget.onLongPressLabel,
            child: Semantics(
              onLongPressHint: widget.onLongPressLabel == null
                  ? null
                  : 'difficulté ou série écartée',
              // Un libellé (« Tête », « Éc10 ») reste entier : il se
              // réduit plutôt que de passer à la ligne.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  style: KType.chiffrePetit.copyWith(
                    color: done
                        ? k.validation
                        : widget.current
                        ? k.texte
                        : k.texte2,
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final c in cells) ...[
          Expanded(child: c),
          const SizedBox(width: KSpacing.s8),
        ],
        if (widget.onTimer != null)
          SizedBox(
            width: KSize.target,
            child: Center(
              child: IconButton(
                onPressed: widget.onTimer,
                tooltip: kind == 'holdMax'
                    ? 'Chrono montant'
                    : 'Compte à rebours',
                style: IconButton.styleFrom(
                  backgroundColor: widget.current ? k.surface : k.haute,
                  foregroundColor: k.texte,
                  minimumSize: Size(KSize.target, KDensity.field(KSize.target)),
                  tapTargetSize: KDensity.factor < 1
                      ? MaterialTapTargetSize.shrinkWrap
                      : null,
                  shape: KRadius.pill,
                ),
                icon: Icon(
                  kind == 'holdMax'
                      ? Icons.timer_outlined
                      : Icons.hourglass_bottom_rounded,
                  size: KSize.iconSmall,
                ),
              ),
            ),
          ),
        SizedBox(
          width: KSize.target,
          child: Center(child: check),
        ),
      ],
    );
    // Ligne courante : fond et contour, avec un peu d'air ; les autres
    // lignes restent serrées (cinq séries visibles sans défilement).
    return Container(
      padding: widget.current
          ? const EdgeInsetsDirectional.fromSTEB(
              KSpacing.s8,
              KSpacing.s4,
              KSpacing.s4,
              KSpacing.s4,
            )
          : const EdgeInsetsDirectional.only(
              start: KSpacing.s8,
              end: KSpacing.s4,
            ),
      decoration: widget.current
          ? ShapeDecoration(
              color: k.haute,
              shape: RoundedRectangleBorder(
                borderRadius: KRadius.menuRadius,
                side: BorderSide(color: k.encre, width: KSize.current),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          if (compact && (widget.showRir || widget.showV)) ...[
            const SizedBox(height: KSpacing.s4),
            Row(
              children: [
                const SizedBox(width: KSize.target - KSpacing.s4),
                if (widget.showRir)
                  Expanded(
                    child: _CompactField(
                      label: widget.readOnly ? 'Effort' : store.effortLabel,
                      child: _f(
                        rir,
                        (t) => e.rir = t,
                        name: 'Effort',
                        field: SetField.effort,
                      ),
                    ),
                  ),
                if (widget.showRir && widget.showV)
                  const SizedBox(width: KSpacing.s8),
                if (widget.showV)
                  Expanded(
                    child: _CompactField(
                      label: 'Vitesse (m/s)',
                      child: _f(
                        v,
                        (t) => e.v = t,
                        name: 'Vitesse en m/s',
                        field: SetField.velocity,
                      ),
                    ),
                  ),
                SizedBox(
                  width:
                      KSpacing.s8 +
                      KSize.target * (widget.onTimer != null ? 2 : 1),
                ),
              ],
            ),
          ],
          if (widget.issue?.message case final message?)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: KSize.target - KSpacing.s4,
                top: KSpacing.s4,
                bottom: KSpacing.s4,
              ),
              child: Semantics(
                container: true,
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: KSize.iconSmall,
                      color: k.danger,
                    ),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(
                      child: Text(
                        message,
                        key: ValueKey('set-issue-${widget.label}'),
                        style: KType.detail.copyWith(color: k.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Champ de la seconde ligne (vitesse, effort) : son nom au-dessus.
class _CompactField extends StatelessWidget {
  final String label;
  final Widget child;
  const _CompactField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: KType.detail.copyWith(color: KTokens.of(context).texte2),
      ),
      child,
    ],
  );
}

// -------------------------------- GROUPES --------------------------------

String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

String _minutes(int s) =>
    s % 60 == 0 ? unitText('${s ~/ 60}', 'min') : _mmss(s);

/// CI1f : libellé d'un groupe (« EMOM 12 min », « Circuit · 3 tours »…).
String groupTitle(kc.GroupSpec g) {
  final rounds = g.rounds;
  final rest = g.restBetweenRoundsSeconds;
  final restText = rest == null || rest == 0
      ? ''
      : ' · ${rest >= 60 ? _minutes(rest) : unitText('$rest', 's')} entre deux tours';
  return switch (g.format) {
    kc.GroupFormat.superset =>
      'Superset${rounds == null ? '' : ' · $rounds tours'}$restText',
    kc.GroupFormat.circuit => 'Circuit · ${rounds ?? 1} tours$restText',
    kc.GroupFormat.roundsForTime =>
      '${rounds ?? 1} tours pour le temps'
          '${g.timeCapSeconds == null ? '' : ' (limite ${_minutes(g.timeCapSeconds!)})'}',
    kc.GroupFormat.amrap =>
      'AMRAP ${_minutes(g.durationSeconds ?? 60)} : un maximum de tours',
    // PR5 : E2MOM, E90s… nommés par leur intervalle ; PR7 : le nom dit
    // déjà l'intervalle (« E2MOM · 8 tours · 16 min »).
    kc.GroupFormat.emom =>
      (g.intervalSeconds ?? 60) == 60
          ? 'EMOM · ${_minutes(g.durationSeconds ?? 60)}'
          : '${ct.everyFormatName(g.intervalSeconds!)} · '
                '${groupPlannedRounds(g)} tours · '
                '${_minutes(g.durationSeconds ?? 60)}',
    kc.GroupFormat.chipper =>
      'Chipper : tout, une fois, au meilleur temps'
          '${g.timeCapSeconds == null ? '' : ' (limite ${_minutes(g.timeCapSeconds!)})'}',
    kc.GroupFormat.intervals =>
      'Intervalles · ${rounds ?? 1} × ${unitText('${g.intervalSeconds ?? 60}', 's')}'
          '${rest == null || rest == 0 ? '' : ', récupération ${unitText('$rest', 's')}'}',
  };
}

/// Tours prévus d'un groupe (null : maximum, AMRAP ; une fois, chipper).
int? groupPlannedRounds(kc.GroupSpec g) => switch (g.format) {
  kc.GroupFormat.amrap || kc.GroupFormat.chipper => null,
  kc.GroupFormat.emom =>
    ((g.durationSeconds ?? 60) / (g.intervalSeconds ?? 60)).round(),
  _ => g.rounds ?? 1,
};

/// PR7 : tours comptés sur les séries validées (rien à saisir) ; AMRAP,
/// tours pour le temps et chipper gardent leur saisie (tours entamés,
/// temps).
bool groupAutoRounds(kc.GroupFormat f) => switch (f) {
  kc.GroupFormat.amrap ||
  kc.GroupFormat.roundsForTime ||
  kc.GroupFormat.chipper => false,
  _ => true,
};

/// Consigne courte d'un groupe.
String groupHint(kc.GroupSpec g, int members) => switch (g.format) {
  kc.GroupFormat.emom =>
    members > 1
        ? 'À chaque départ, enchaîne les exercices dans l’ordre ; le repos '
              'est ce qui reste de l’intervalle.'
        : 'À chaque départ, fais tes répétitions ; le repos est ce qui '
              'reste de l’intervalle.',
  kc.GroupFormat.amrap =>
    'Enchaîne les exercices dans l’ordre, tour après tour, jusqu’au bout '
        'du chrono, à un rythme tenable.',
  kc.GroupFormat.roundsForTime || kc.GroupFormat.chipper =>
    'Lance le chrono, enchaîne dans l’ordre, note ton temps à la fin.',
  kc.GroupFormat.intervals =>
    'Effort pendant le temps donné, puis récupération ; garde le même '
        'rythme du premier au dernier tour.',
  _ =>
    members > 1
        ? 'Enchaîne les exercices dans l’ordre, puis récupère entre deux '
              'tours.'
        : 'Un tour, puis la récupération prévue.',
};

/// CI1f : en-tête d'un groupe d'exercices enchaînés (format, ordre,
/// chrono du groupe) et son résultat (tours, temps), journalisé avec le
/// groupe.
class _GroupCard extends StatefulWidget {
  final kc.GroupSpec group;
  final List<String> names;
  final Map<String, dynamic>? result;
  final bool readOnly;
  final TimerCtl timer;
  final void Function(Map<String, dynamic> result) onResult;

  /// PR5 : sans carte (en tête de la carte commune des exercices).
  final bool bare;
  const _GroupCard({
    this.bare = false,
    required this.group,
    required this.names,
    required this.result,
    required this.readOnly,
    required this.timer,
    required this.onResult,
  });

  @override
  State<_GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<_GroupCard> {
  late int rounds;
  late int extra;
  late final TextEditingController time;

  kc.GroupSpec get g => widget.group;

  bool get _timed =>
      g.format == kc.GroupFormat.roundsForTime ||
      g.format == kc.GroupFormat.chipper;

  /// Tours prévus (null : maximum, AMRAP ; une fois, chipper).
  int? get _planned => groupPlannedRounds(g);

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    rounds = r?['rounds'] is int ? r!['rounds'] as int : (_planned ?? 0);
    extra = r?['extraReps'] is int ? r!['extraReps'] as int : 0;
    final e = r?['elapsed'];
    time = TextEditingController(text: e is int ? _mmss(e) : '');
  }

  @override
  void dispose() {
    time.dispose();
    super.dispose();
  }

  int? _elapsed() {
    final m = RegExp(r'^(\d+)(?::(\d{1,2}))?$').firstMatch(time.text.trim());
    if (m == null) return null;
    final a = int.parse(m.group(1)!);
    final b = m.group(2) == null ? null : int.parse(m.group(2)!);
    final s = b == null ? a * 60 : a * 60 + b;
    return s > 86400 ? null : s;
  }

  void _save() {
    final planned = _planned;
    final elapsed = _timed ? _elapsed() : null;
    final cap = g.timeCapSeconds;
    widget.onResult({
      if (g.format != kc.GroupFormat.chipper) 'rounds': rounds,
      if (g.format == kc.GroupFormat.amrap) 'extraReps': extra,
      if (elapsed != null) 'elapsed': elapsed,
      'completed': switch (g.format) {
        kc.GroupFormat.amrap => true,
        kc.GroupFormat.chipper =>
          elapsed != null && (cap == null || elapsed <= cap),
        kc.GroupFormat.roundsForTime =>
          rounds >= (planned ?? 1) &&
              (cap == null || elapsed == null || elapsed <= cap),
        _ => rounds >= (planned ?? 1),
      },
    });
  }

  void _startClock() {
    final interval = g.intervalSeconds ?? 60;
    switch (g.format) {
      case kc.GroupFormat.emom:
        widget.timer.emom(
          ((g.durationSeconds ?? 60) / interval).round().clamp(1, 240),
          interval,
        );
      case kc.GroupFormat.amrap:
        widget.timer.single('AMRAP', g.durationSeconds ?? 60);
      case kc.GroupFormat.intervals:
        widget.timer.startInterval(
          g.rounds ?? 1,
          interval,
          g.restBetweenRoundsSeconds ?? interval,
        );
      case kc.GroupFormat.roundsForTime || kc.GroupFormat.chipper:
        widget.timer.stopwatch('CHRONO');
      default:
        final rest = g.restBetweenRoundsSeconds;
        if (rest != null && rest > 0) widget.timer.startRest(rest);
    }
  }

  String get _clockLabel => switch (g.format) {
    kc.GroupFormat.emom =>
      'Lancer l’${ct.everyFormatName(g.intervalSeconds ?? 60)}',
    kc.GroupFormat.amrap => 'Lancer l’AMRAP',
    kc.GroupFormat.intervals => 'Lancer les intervalles',
    kc.GroupFormat.roundsForTime ||
    kc.GroupFormat.chipper => 'Lancer le chrono',
    _ => 'Récupération entre deux tours',
  };

  Widget _stepper(String label, int value, void Function(int) on, Key key) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.s8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: KType.corps.copyWith(color: k.texte2)),
          ),
          const SizedBox(width: KSpacing.s8),
          KeyedSubtree(
            key: key,
            child: KStepper(
              value: '$value',
              semanticLabel: label,
              decrementLabel: '$label : un de moins',
              incrementLabel: '$label : un de plus',
              onDecrement: widget.readOnly || value <= 0
                  ? null
                  : () {
                      setState(() => on(value - 1));
                      _save();
                    },
              onIncrement: widget.readOnly || value >= 1000
                  ? null
                  : () {
                      setState(() => on(value + 1));
                      _save();
                    },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final names = widget.names;
    final planned = _planned;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(KSize.target / 2)),
      borderSide: k.controlSide,
    );
    // PR5 : en-tête compact : le format sur une ligne avec son chrono,
    // puis le résultat ; les exercices (A, B…) suivent dans la carte. La
    // consigne n'est dite que là où le résultat se note autrement (AMRAP,
    // temps).
    final hint = switch (g.format) {
      kc.GroupFormat.amrap ||
      kc.GroupFormat.roundsForTime ||
      kc.GroupFormat.chipper => groupHint(g, names.length),
      _ => null,
    };
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: _clockLabel,
                child: Text(
                  groupTitle(g),
                  key: ValueKey('group-title-${g.groupId}'),
                  style: KType.corpsFort.copyWith(color: k.encre),
                ),
              ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(width: KSpacing.s8),
              KTonalButton(
                key: ValueKey('group-clock-${g.groupId}'),
                icon: Icons.timer_outlined,
                label: switch (g.format) {
                  kc.GroupFormat.superset || kc.GroupFormat.circuit => 'Repos',
                  _ => 'Lancer',
                },
                onPressed: _startClock,
              ),
            ],
          ],
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s4),
            child: Text(hint, style: KType.detail.copyWith(color: k.texte2)),
          ),
        // PR7 : tours comptés sur les séries validées (EMOM, superset,
        // circuit, intervalles) : pas de saisie.
        if (g.format != kc.GroupFormat.chipper && !groupAutoRounds(g.format))
          _stepper(
            planned == null ? 'Tours complets' : 'Tours faits (sur $planned)',
            rounds,
            (v) => rounds = v,
            ValueKey('group-rounds-${g.groupId}'),
          ),
        if (g.format == kc.GroupFormat.amrap)
          _stepper(
            'Répétitions du tour entamé',
            extra,
            (v) => extra = v,
            ValueKey('group-extra-${g.groupId}'),
          ),
        if (_timed)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Temps (min:s)',
                    style: KType.corps.copyWith(color: k.texte2),
                  ),
                ),
                SizedBox(
                  width: KSize.target * 2,
                  child: TextField(
                    key: ValueKey('group-time-${g.groupId}'),
                    controller: time,
                    enabled: !widget.readOnly,
                    keyboardType: TextInputType.datetime,
                    textAlign: TextAlign.center,
                    style: KType.chiffreMoyen.copyWith(color: k.texte),
                    decoration: InputDecoration(
                      hintText: '12:30',
                      hintStyle: KType.chiffreMoyen.copyWith(color: k.texte3),
                      filled: true,
                      fillColor: k.haute,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KSpacing.s8,
                        vertical: KSpacing.s12,
                      ),
                      border: border,
                      enabledBorder: border,
                      disabledBorder: border,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(KSize.target / 2),
                        ),
                        borderSide: BorderSide(
                          color: k.encre,
                          width: KSize.current,
                        ),
                      ),
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    // PR5 : dans la carte commune des exercices enchaînés, sans carte à
    // part.
    if (widget.bare) {
      return KeyedSubtree(
        key: ValueKey('group-card-${g.groupId}'),
        child: content,
      );
    }
    return KCard(key: ValueKey('group-card-${g.groupId}'), child: content);
  }
}

// ------------------------------ MINI-SÉRIES ------------------------------

/// CI1f : saisie d'une série mini-série par mini-série (cluster,
/// rest-pause, myo-reps) : chaque mini-série s'ajoute une à une (valeur
/// proposée, −/+), le mini-repos se lance, le total remplit la série.
/// Note d'un exercice (correctifs UI, 11/10/2026) : comme les champs de
/// série, sans focus les gestes vont au cadre — un appui ouvre la saisie,
/// un glissement horizontal change de page ; avec le focus, au champ.
class _NoteField extends StatefulWidget {
  final Key fieldKey;
  final String initial;
  final TextStyle style;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  const _NoteField({
    required this.fieldKey,
    required this.initial,
    required this.style,
    required this.decoration,
    required this.onChanged,
  });

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: _focus.requestFocus,
    child: IgnorePointer(
      ignoring: !_focus.hasFocus,
      child: KPagerSlop(
        child: TextFormField(
          key: widget.fieldKey,
          focusNode: _focus,
          initialValue: widget.initial,
          minLines: 1,
          maxLines: 3,
          textAlign: TextAlign.left,
          style: widget.style,
          decoration: widget.decoration,
          onChanged: widget.onChanged,
        ),
      ),
    ),
  );
}

/// Repère discret d'une carte d'exercice (repos, tempo, technique) : icône
/// et texte `texte2`, sans fond (correctifs UI, 11/10/2026 : les puces
/// faisaient autant de boutons qui n'en étaient pas).
class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Meta(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: KSize.chevron - KSpacing.s4, color: k.texte2),
        const SizedBox(width: KSpacing.s4),
        Flexible(
          child: Text(text, style: KType.detail.copyWith(color: k.texte2)),
        ),
      ],
    );
  }
}

/// Cible de réserve d'un exercice (« RIR 2 », difficulté 7/10) : le chiffre
/// à viser en `encre`, sur une pastille tonale (correctifs UI, 11/10/2026 :
/// « le RIR cible pas assez visible »).
class _TargetBadge extends StatelessWidget {
  final String rir;
  final String? level;

  /// Lift principal : pastille tonale `encre` ; sinon `haute`, chiffre en
  /// `texte` (6.15.0).
  final bool lead;
  const _TargetBadge({
    super.key,
    required this.rir,
    this.level,
    this.lead = true,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Semantics(
      label:
          'Cible : $rir répétition${rir == '1' || rir == '0' ? '' : 's'} en '
          'réserve${level == null ? '' : ', difficulté $level sur 10'}',
      excludeSemantics: true,
      child: Material(
        color: lead ? k.encre.withValues(alpha: .14) : k.haute,
        shape: RoundedRectangleBorder(
          borderRadius: KRadius.menuRadius,
          side: lead
              ? BorderSide(color: k.encre.withValues(alpha: .5))
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpacing.s12,
            vertical: KSpacing.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RIR $rir',
                maxLines: 1,
                style: KType.chiffreMoyen.copyWith(
                  color: lead ? k.encre : k.texte,
                ),
              ),
              if (level != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: KSpacing.s14,
                      color: lead ? k.encre : k.texte2,
                    ),
                    const SizedBox(width: KSpacing.s4 / 2),
                    Text(
                      '$level/10',
                      style: KType.micro.copyWith(color: k.texte2),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSetStrip extends StatefulWidget {
  final String id;
  final MiniSetPlan plan;
  final SetEntry entry;

  /// Répétitions (ou secondes) visées pour la série entière (cible de la
  /// ligne) : un cluster les répartit en blocs. Null : cible inconnue.
  final int? target;
  final VoidCallback onChanged;
  final void Function(int seconds) onIntra;
  const _MiniSetStrip({
    super.key,
    required this.id,
    required this.plan,
    required this.entry,
    required this.onChanged,
    required this.onIntra,
    this.target,
  });

  @override
  State<_MiniSetStrip> createState() => _MiniSetStripState();
}

/// Répartition d'un cluster (6.15.0) : la cible de la série en [blocks]
/// blocs aussi égaux que possible, les plus gros d'abord (3 en 2 : 2 + 1).
/// Cible plus petite que le nombre de blocs : un par bloc.
List<int> clusterSplit(int target, int blocks) {
  final n = blocks < 1 ? 1 : blocks;
  if (target < n) return List.filled(n, 1);
  final base = target ~/ n, extra = target % n;
  return [for (var b = 0; b < n; b++) base + (b < extra ? 1 : 0)];
}

class _MiniSetStripState extends State<_MiniSetStrip> {
  late int value;

  List<SetPartEntry> get _parts => widget.entry.parts ?? const [];

  /// Valeur prévue de chaque bloc (cluster : cible de la série répartie ;
  /// myo-reps, rest-pause : activation puis mini-séries).
  List<int> get _planned {
    final p = widget.plan;
    final slots = p.cap + 1;
    if (p.kind == kc.SetTechniqueKind.cluster) {
      return clusterSplit(widget.target ?? slots * p.next, slots);
    }
    return [for (var b = 0; b < slots; b++) b == 0 ? p.first : p.next];
  }

  int _suggested(int done) {
    final planned = _planned;
    return done < planned.length ? planned[done] : widget.plan.next;
  }

  @override
  void initState() {
    super.initState();
    value = _suggested(_parts.length);
  }

  void _add() {
    final parts = [...?widget.entry.parts];
    parts.add(
      SetPartEntry(value, restBefore: parts.isEmpty ? null : widget.plan.intra),
    );
    widget.entry.parts = parts;
    widget.entry.reps = '${widget.entry.partsTotal}';
    if (store.settings.vibration) HapticFeedback.lightImpact();
    final left = widget.plan.left(parts.length);
    if (left > 0 && store.settings.autoTimer) {
      widget.onIntra(widget.plan.intra);
    }
    widget.onChanged();
  }

  void _removeLast() {
    final parts = [...?widget.entry.parts];
    if (parts.isEmpty) return;
    parts.removeLast();
    widget.entry.parts = parts.isEmpty ? null : parts;
    final t = widget.entry.partsTotal;
    widget.entry.reps = t == null ? '' : '$t';
    widget.onChanged();
  }

  /// Titre court, dans les mots de la ligne (6.15.0) : un cluster dit la
  /// cible de la série et sa répartition (« 3 reps en 2 blocs »).
  String get _title {
    final p = widget.plan;
    final unit = p.seconds ? ' s' : ' reps';
    final planned = _planned;
    final total = planned.fold<int>(0, (a, b) => a + b);
    return switch (p.kind) {
      // KM3 (aide des clusters, question du propriétaire du 12/10) : la
      // cible de RIR vaut pour chaque bloc, la série reçoit une note.
      kc.SetTechniqueKind.cluster =>
        'Cluster · $total$unit en ${planned.length} blocs, ${p.intra} s entre'
            ' · RIR visé sur chaque bloc · note la série au bloc le plus dur',
      kc.SetTechniqueKind.myoReps =>
        'Myo-reps · activation puis mini-séries, ${p.intra} s entre',
      _ => 'Rest-pause · série puis relances, ${p.intra} s entre',
    };
  }

  String _partLabel(int i) => switch (widget.plan.kind) {
    kc.SetTechniqueKind.myoReps => i == 0 ? 'Activation' : 'Mini-série $i',
    kc.SetTechniqueKind.restPause => i == 0 ? 'Série' : 'Relance $i',
    _ => 'Bloc ${i + 1}',
  };

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final plan = widget.plan;
    final parts = _parts;
    final left = plan.left(parts.length);
    final unit = plan.seconds ? ' s' : '';
    final planned = _planned;
    final slots = plan.cap + 1;
    // Consigne en mode guidé ; sinon seulement ce qui demande une action.
    // CIF (point 12) : les deux textes gardent leur place (pile, le texte
    // caché garde sa taille) : la ligne du bas ne naît plus au dernier
    // bloc et ne change plus de hauteur en mode guidé.
    final doneText = plan.exact
        ? 'Tous les blocs sont faits : valide la série.'
        : 'Plafond atteint : valide la série.';
    final guide = !koachGuided
        ? null
        : plan.kind == kc.SetTechniqueKind.cluster
        ? 'Fais chaque bloc, souffle ${plan.intra} s, puis le suivant ; '
              'touche ✓ à la fin de chaque bloc.'
        : 'Note chaque mini-série à la fin de son effort ; arrête dès '
              'qu’une mini-série n’atteint plus ${plan.next}$unit.';
    final noteLabel =
        'Noter ${_partLabel(parts.length).toLowerCase()} : $value$unit';
    // Bloc fait (valeur réelle, aplat `encre`), suivant (contour `encre`),
    // à venir (contour `filet`) ; chaque case porte sa valeur prévue.
    Widget slot(int i) {
      final done = i < parts.length;
      final next = i == parts.length;
      final shown = done
          ? parts[i].value
          : (i < planned.length ? planned[i] : plan.next);
      return Semantics(
        key: done ? ValueKey('miniset-part-${widget.id}-$i') : null,
        label: done
            ? '${_partLabel(i)} : $shown$unit'
            : '${_partLabel(i)} à faire : $shown$unit',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: KSpacing.s32,
            minHeight: KSpacing.s32,
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: done ? k.encre : null,
              shape: RoundedRectangleBorder(
                borderRadius: KRadius.menuRadius,
                side: done
                    ? BorderSide.none
                    : BorderSide(
                        color: next ? k.encre : k.filet,
                        width: next ? KSize.current : 1,
                      ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpacing.s8),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '$shown$unit',
                  style: KType.libelle.copyWith(
                    color: done
                        ? k.roles.surEncre
                        : (next ? k.encre : k.texte3),
                    fontFeatures: KFont.tabular,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget small(IconData icon, String tip, VoidCallback? onTap) => Tooltip(
      message: tip,
      child: InkWell(
        customBorder: KRadius.pill,
        onTap: onTap,
        child: SizedBox(
          width: KSize.target,
          height: KDensity.field(KSize.target),
          child: Icon(
            icon,
            size: KSize.iconSmall,
            color: onTap == null ? k.texte3 : k.texte,
          ),
        ),
      ),
    );

    // 6.15.0 : deux lignes au plus — titre, puis blocs et saisie du bloc
    // suivant côte à côte (− valeur + ✓).
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.s4, bottom: KSpacing.s4),
      child: Semantics(
        container: true,
        child: Material(
          color: k.haute,
          shape: KRadius.menuShape,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpacing.s12,
              KSpacing.s8,
              KSpacing.s4,
              KSpacing.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: KType.detail.copyWith(color: k.texte2),
                      ),
                    ),
                    // 6.17.0 : place gardée même sans bloc noté, pour que
                    // le bandeau ne grandisse pas au premier bloc.
                    Visibility(
                      visible: parts.isNotEmpty,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: small(
                        Icons.undo_rounded,
                        'Retirer le dernier bloc',
                        parts.isEmpty ? null : _removeLast,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: KSpacing.s4,
                  runSpacing: KSpacing.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (var i = 0; i < slots; i++) slot(i),
                    // Tous les blocs notés : même hauteur de ligne. CIF
                    // (point 12) : la saisie garde aussi sa largeur (place
                    // gardée, invisible) : le retour à la ligne des blocs
                    // ne change pas au dernier bloc.
                    if (left == 0)
                      ExcludeSemantics(
                        child: Visibility(
                          visible: false,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: KSpacing.s8),
                              small(Icons.remove_rounded, 'Une de moins', null),
                              Text(
                                '$value$unit',
                                style: KType.chiffreMoyen.copyWith(
                                  color: k.texte,
                                ),
                              ),
                              small(Icons.add_rounded, 'Une de plus', null),
                              SizedBox(
                                width: KSize.target,
                                height: KDensity.field(KSize.target),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (left > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: KSpacing.s8),
                          KeyedSubtree(
                            key: ValueKey('miniset-value-${widget.id}'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                small(
                                  Icons.remove_rounded,
                                  'Une de moins',
                                  value > 0
                                      ? () => setState(() => value--)
                                      : null,
                                ),
                                Semantics(
                                  label: 'Bloc suivant',
                                  value: '$value$unit',
                                  child: Text(
                                    '$value$unit',
                                    style: KType.chiffreMoyen.copyWith(
                                      color: k.texte,
                                    ),
                                  ),
                                ),
                                small(
                                  Icons.add_rounded,
                                  'Une de plus',
                                  value < 1000
                                      ? () => setState(() => value++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            button: true,
                            label: noteLabel,
                            excludeSemantics: true,
                            onTap: _add,
                            child: Tooltip(
                              message: noteLabel,
                              child: Material(
                                color: k.encre,
                                shape: KRadius.pill,
                                child: InkWell(
                                  key: ValueKey('miniset-add-${widget.id}'),
                                  customBorder: KRadius.pill,
                                  onTap: _add,
                                  child: SizedBox(
                                    width: KSize.target,
                                    height: KDensity.field(KSize.target),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: KSize.icon,
                                      color: k.roles.surEncre,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Padding(
                  key: ValueKey('miniset-note-slot-${widget.id}'),
                  padding: const EdgeInsets.only(
                    top: KSpacing.s4,
                    bottom: KSpacing.s4,
                    right: KSpacing.s8,
                  ),
                  child: Stack(
                    children: [
                      if (guide != null)
                        Visibility(
                          visible: left > 0,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: Text(
                            guide,
                            key: left > 0
                                ? ValueKey('miniset-advice-${widget.id}')
                                : null,
                            style: KType.detail.copyWith(color: k.texte2),
                          ),
                        ),
                      Visibility(
                        visible: left == 0,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Text(
                          doneText,
                          key: left == 0
                              ? ValueKey('miniset-advice-${widget.id}')
                              : null,
                          style: KType.detail.copyWith(color: k.texte2),
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
    );
  }
}

// --------------------------- BARRE TIMER ---------------------------------

/// UI2 : libellé de phase du chrono en texte courant (C4) ; les phases de
/// `timers.dart` restent écrites en capitales (« REPOS 3/4 »).
String phaseLabel(String raw) {
  if (raw.isEmpty) return raw;
  final parts = raw.split(' ');
  final head = switch (parts.first) {
    'INTRA' => 'Mini-repos',
    'MAX' => 'Tenue au maximum',
    'AMRAP' || 'EMOM' => parts.first,
    final w => '${w[0]}${w.substring(1).toLowerCase()}',
  };
  return [head, ...parts.skip(1)].join(' ');
}

/// Barre de chrono flottante en bas de la séance (C8) : la barre de repos
/// du kit ([KRestBar]) pour tout décompte ; chronomètre montant ou décompte
/// terminé : même barre sans le groupe −15 s / +15 s.
class _TimerBar extends StatelessWidget {
  final TimerCtl ctl;
  const _TimerBar({super.key, required this.ctl});

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
        final time = ctl.up
            ? fmt(ctl.elapsed)
            : (done ? '0:00' : fmt(ctl.remaining));
        final label = phaseLabel(ctl.label);
        final bar = done || ctl.up
            ? _ClockBar(
                label: label,
                time: time,
                progress: done ? 1 : frac,
                done: done,
                onStop: ctl.stop,
              )
            : KRestBar(
                label: label,
                remaining: time,
                progress: frac,
                onMinus: () => ctl.add(-15),
                onPlus: () => ctl.add(15),
                onStop: ctl.stop,
                stopLabel: 'Arrêter',
              );
        // 6.17.0 : le contenu qui arrive sous la barre se floute
        // progressivement.
        return KFloatingBottom(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              KSpacing.s16,
              KSpacing.s4,
              KSpacing.s16,
              KSpacing.s12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: bar,
          ),
        );
      },
    );
  }
}

/// Barre de chrono sans réglage du temps (chronomètre montant, décompte
/// terminé) : mêmes mesures que [KRestBar] (à promouvoir : un paramètre
/// `adjustable` de KRestBar).
class _ClockBar extends StatelessWidget {
  final String label, time;
  final double progress;
  final bool done;
  final VoidCallback onStop;
  const _ClockBar({
    required this.label,
    required this.time,
    required this.progress,
    required this.done,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final stopLabel = done ? 'Fermer' : 'Arrêter';
    final v = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);
    return Material(
      color: k.haute,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.cardRadius,
        side: BorderSide(color: k.filet),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: KSpacing.s20,
              top: KSpacing.s12,
              right: KSpacing.s20,
            ),
            child: SizedBox(
              height: KSpacing.s4,
              child: ClipPath(
                clipper: const ShapeBorderClipper(shape: KRadius.pill),
                child: ColoredBox(
                  color: k.filet,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: ColoredBox(color: done ? k.validation : k.encre),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              KSpacing.s20,
              KSpacing.s8,
              KSpacing.s12,
              KSpacing.s12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: label,
                    value: time,
                    liveRegion: done,
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: KType.micro.copyWith(
                            color: done ? k.validation : k.texte2,
                          ),
                        ),
                        Text(
                          time,
                          style: KType.chrono.copyWith(color: k.texte),
                        ),
                      ],
                    ),
                  ),
                ),
                Tooltip(
                  message: stopLabel,
                  child: Semantics(
                    button: true,
                    label: stopLabel,
                    excludeSemantics: true,
                    onTap: onStop,
                    child: Material(
                      color: done ? k.surface : k.pleine,
                      shape: done ? k.controlPill : KRadius.pill,
                      child: InkWell(
                        customBorder: KRadius.pill,
                        onTap: onStop,
                        child: SizedBox.square(
                          dimension: KSize.target,
                          child: Icon(
                            done ? Icons.close_rounded : Icons.stop_rounded,
                            color: done ? k.texte : k.surPleine,
                            size: KSize.icon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  /// « Repasser en « à faire » » retire les XP de la séance : confirmé
  /// (R8).
  Future<void> _undo(String title) async {
    final ok = await showKConfirm(
      context,
      title: 'Repasser la séance en « à faire » ?',
      message:
          'Elle ne comptera plus comme faite : ses XP et ses bonus sont '
          'retirés de ta progression. Tes séries restent enregistrées.',
      confirmLabel: 'Repasser',
    );
    if (!ok || !mounted) return;
    store.markSessionDone(week.n, day.j, false, title: title);
  }

  Widget _build(BuildContext context) {
    final k = KTokens.of(context);
    final log = store.sessionLog(week.n, day.j);
    var doneSets = 0;
    var totalSets = 0;
    for (final ex in day.exercises) {
      final l = store.exLog(week.n, day.j, ex);
      totalSets += l.sets.length;
      doneSets += l.sets.where((s) => s.done).length;
    }
    final title = week.n == 0
        ? week.block
        : store.program.sessionLabel(week.n, day.j);
    final goal = store.game.sessionGoal;
    final reached = totalSets > 0 && doneSets / totalSets >= goal - 1e-9;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KCard(
            padding: const EdgeInsets.all(KSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sessionPlace(week, day),
                        style: KType.titreCarte.copyWith(color: k.texte),
                      ),
                    ),
                    Icon(
                      log.done
                          ? Icons.emoji_events_rounded
                          : Icons.flag_outlined,
                      size: KSize.target,
                      color: log.done ? k.accent : k.texte2,
                    ),
                  ],
                ),
                const SizedBox(height: KSpacing.s12),
                Text(
                  '$doneSets / $totalSets',
                  style: KType.chiffre.copyWith(color: k.encre),
                ),
                Text(
                  'séries validées',
                  style: KType.corps.copyWith(color: k.texte2),
                ),
                if (totalSets > 0) ...[
                  const SizedBox(height: KSpacing.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        reached
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: KSize.iconSmall,
                        color: reached ? k.validation : k.texte2,
                      ),
                      const SizedBox(width: KSpacing.s8),
                      Expanded(
                        child: Text(
                          'Objectif de séance : au moins '
                          '${(goal * 100).round()} % des séries, '
                          '${reached ? 'atteint' : 'pas encore'}',
                          style: KType.detail.copyWith(color: k.texte),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: KSpacing.s8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: KSize.iconSmall,
                      color: k.accent,
                    ),
                    const SizedBox(width: KSpacing.s8),
                    Expanded(
                      child: Text(
                        log.done
                            ? 'XP et bonus ajoutés à ta progression'
                            : '+100 XP de base, plus les bonus éventuels',
                        style: KType.detail.copyWith(color: k.texte),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.s24),
          if (log.done && _unsaved)
            KPrimaryButton(
              key: const ValueKey('finish-retry'),
              icon: Icons.sync_problem_rounded,
              label: _saving ? 'Enregistrement…' : 'Réessayer l’enregistrement',
              onPressed: _saving ? null : () => _finish(title),
            )
          else if (log.done)
            KTonalButton(
              key: const ValueKey('finish-session'),
              icon: Icons.undo_rounded,
              label: _saving ? 'Enregistrement…' : 'Repasser en « à faire »',
              expand: true,
              onPressed: _saving ? null : () => _undo(title),
            )
          else
            KPrimaryButton(
              key: const ValueKey('finish-session'),
              icon: Icons.check_circle_rounded,
              label: _saving ? 'Enregistrement…' : 'Terminer la séance',
              onPressed: _saving ? null : () => _finish(title),
            ),
        ],
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
    final k = KTokens.of(context);
    final done = store.isDone(week.n, day.j);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KCard(
            padding: const EdgeInsets.all(KSpacing.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.bedtime_outlined,
                  size: KSize.target,
                  color: k.encre,
                ),
                const SizedBox(height: KSpacing.s12),
                Text(
                  k.title('Repos complet'),
                  style: k.titleStyle(
                    KType.titreCarte.copyWith(color: k.texte),
                  ),
                ),
                const SizedBox(height: KSpacing.s8),
                Text(
                  day.conduite.isEmpty
                      ? 'Marche, mobilité légère, sommeil maximal. GtG suspendu. Note ta HRV et ta FC de repos.'
                      : day.conduite,
                  style: KType.corps.copyWith(color: k.texte2),
                ),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.s24),
          if (done)
            KTonalButton(
              icon: Icons.undo_rounded,
              label: 'Marqué fait',
              expand: true,
              onPressed: () => store.markSessionDone(
                week.n,
                day.j,
                false,
                title: 'S${week.n} · J${day.j}',
              ),
            )
          else
            KPrimaryButton(
              icon: Icons.check_rounded,
              label: 'Marquer comme fait',
              onPressed: () => store.markSessionDone(
                week.n,
                day.j,
                true,
                title: 'S${week.n} · J${day.j}',
              ),
            ),
        ],
      ),
    );
  }
}
