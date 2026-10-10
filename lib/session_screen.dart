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
import 'adapt/widgets/session_kit.dart';
import 'exercise_screens.dart' show openExerciseSheet;
import 'plan/coach_texts.dart' as ct;
import 'koach/koach_bubble.dart'
    show KoachSays, koachLargeText, koachPose, showKoachSheet;
import 'koach/koach_view.dart' show KoachColors, KoachView;

import 'timers.dart';
export 'timers.dart' show TimerCtl;
import 'kit/kit.dart';
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

/// Espace insécable avant les unités (« 3 min », « 90 s »).
String nbsp(String t) => t.replaceAllMapped(
  RegExp(r'(\d) (kg|s|min|reps|lb)\b'),
  (m) => '${m[1]} ${m[2]}',
);

/// UI2 : repère de la journée affiché sous le titre (« S1, J2 » ; le nom du
/// bloc pour une séance hors semaine). Le titre enregistré dans le journal
/// (« S1 · J2 ») ne change pas.
String sessionPlace(WeekPlan w, DayPlan d) =>
    w.n == 0 ? w.block : 'S${w.n}, J${d.j}';

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

/// UI2 (C8) : hauteur occupée en bas de la séance par la barre de chrono ;
/// un message court (Koach, record, enchaînement) se pose au-dessus.
class SessionBottomInset extends InheritedWidget {
  final double Function() height;
  const SessionBottomInset({
    super.key,
    required this.height,
    required super.child,
  });

  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SessionBottomInset>()
          ?.height() ??
      0;

  @override
  bool updateShouldNotify(SessionBottomInset oldWidget) => false;
}

/// UI2 (C1) : en-tête de la séance — retour, titre en capitales (U3) jamais
/// coupé, repère de la journée, une seule action (⋮).
class SessionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  const SessionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KSize.dock),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpacing.s8),
        child: Row(
          children: [
            KIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Retour',
              onPressed: () => Navigator.maybePop(context),
            ),
            const SizedBox(width: KSpacing.s4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KSpacing.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      header: true,
                      child: KFitTitle(
                        k.title(title),
                        style: k.titleStyle(
                          KType.titreSeance.copyWith(color: k.texte),
                        ),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: KType.detail.copyWith(color: k.texte2),
                      ),
                  ],
                ),
              ),
            ),
            if (action != null) action! else const SizedBox(width: KSize.target),
          ],
        ),
      ),
    );
  }
}

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
    if (adaptOn) {
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
  double _barHeight() =>
      ctl.visible ? (_barKey.currentContext?.size?.height ?? 0) : 0;

  /// « Supprimer l'historique de cette séance » (R8 : verbe exact,
  /// confirmation, `danger`).
  Future<void> _confirmClear() async {
    final w = widget.week;
    final d = widget.day;
    final head = w.n == 0 ? w.block : 'S${w.n} · J${d.j}';
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
          '${duration.isEmpty ? '' : ', ${nbsp(duration)}'}',
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
    subtitle: '${widget.day.title}, ${sessionPlace(widget.week, widget.day)}',
    builder: (ctx) => Text(widget.day.conduite),
  );

  /// Menu ⋮ de la séance : feuille d'actions au contenu du §4.1.
  Future<void> _menu() async {
    final w = widget.week;
    final d = widget.day;
    final restDay = d.exercises.isEmpty;
    final choice = await showKActionSheet<String>(
      context,
      title: 'Séance',
      subtitle: '${restDay ? 'Récupération' : d.title}, ${sessionPlace(w, d)}',
      groups: [
        [
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
    final header = SessionHeader(
      title: restDay ? 'Récupération' : d.title,
      subtitle: sessionPlace(w, d),
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
            child: SessionBottomInset(
              height: _barHeight,
              child: Column(
                children: [
                  header,
                  if (restDay)
                    Expanded(child: _RestDay(week: w, day: d))
                  else ...[
                    _strip(k),
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
                    _TimerBar(key: _barKey, ctl: ctl),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      // 5.5.2 (demande du propriétaire, 29/09/2026) : plus de boutons
      // Précédent / Suivant, le glissement d'une page à l'autre suffit ; le
      // bouton « Exercices » et les points restent pour se repérer.
    );
  }

  /// Repère de page (« Exercice 3 sur 7 »), lien « Exercices », points.
  Widget _strip(KTokens k) {
    final where = page == bilanPage
        ? 'Bilan de séance'
        : exerciseIndex < 0
        ? 'Bilan du jour'
        : '${groups[exerciseIndex].length > 1 ? 'Enchaînement' : 'Exercice'} '
              '${exerciseIndex + 1} sur $nPages';
    return Padding(
      padding: const EdgeInsets.only(
        left: KSpacing.page,
        right: KSpacing.s12,
        bottom: KSpacing.s8,
      ),
      child: Column(
        children: [
          // Texte agrandi (200 %) sur 320 dp : le lien passe sous le repère
          // au lieu de faire déborder la ligne.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KSpacing.s8,
            children: [
              Text(where, style: KType.section.copyWith(color: k.texte2)),
              KTextButton(
                label: 'Exercices',
                icon: Icons.format_list_numbered_rounded,
                onPressed: _chooseExercise,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: KSpacing.s8),
            child: SessionProgressDots(count: bilanPage + 1, index: page),
          ),
        ],
      ),
    );
  }
}

/// Points de progression de la séance : page courante en pilule `encre`,
/// pages passées en `texte2`, suivantes en `texte3`.
class SessionProgressDots extends StatelessWidget {
  final int count;
  final int index;

  /// Couleur de la page courante (par défaut `encre`).
  final Color? color;

  const SessionProgressDots({
    super.key,
    required this.count,
    required this.index,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final motion = KMotion.fast;
    return Semantics(
      label: 'Étape ${index + 1} sur $count',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: KSpacing.s4,
          runSpacing: KSpacing.s4,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: motion.durationIn(context),
                curve: motion.curve,
                width: i == index ? KSpacing.s20 : KSpacing.s8,
                height: KSpacing.s8 * .75,
                decoration: ShapeDecoration(
                  color: i == index
                      ? (color ?? k.encre)
                      : i < index
                      ? k.texte2
                      : k.texte3,
                  shape: KRadius.pill,
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
      showKSnack(
        context,
        message: 'Enchaîne : ${store.splitName(widget.exs[1].name).$1}',
        bottom: SessionBottomInset.of(context),
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
    final text = adviceText(r.advice, seconds: seconds);
    final step = r.step;
    final changedRest =
        r.advice.action == kc.IntraSessionAction.restMore ||
        r.advice.reasons.any((x) => x.code == 'adapt.set_failed');
    final rest = changedRest ? r.advice.restSeconds : null;
    if (text == null) return rest;
    if (step != null) setState(() => epoch++);
    if (step != null && step.status == 'pending') return rest;
    // C8 : le message de Koach se pose au-dessus de la barre de repos.
    final k = KTokens.of(context);
    final large = koachLargeText(context);
    showKSnack(
      context,
      message: 'Koach : $text',
      bottom: SessionBottomInset.of(context),
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
                colors: KoachColors.onColor(k.texte),
              ),
      ),
      actionLabel: step == null ? null : 'Annuler',
      onAction: step == null
          ? null
          : () {
              store.adaptAdviceDecision(widget.week.n, widget.day, ex, 'undone');
              if (mounted) setState(() => epoch++);
            },
    );
    return rest;
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
      if (step.kg != null && step.kg! > 0) adaptKg(step.kg!),
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
                  if (adaptReasonText(r, exerciseName: store.adaptExerciseName)
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
            horizontal: KSpacing.s14,
            vertical: KSpacing.s8,
          ),
          child: Row(
            children: [
              Icon(icon, size: KSize.iconSmall, color: t.texte2),
              const SizedBox(width: KSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KType.corps.copyWith(color: t.texte)),
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
  (List<Widget>, Widget?) _coachPanel(Exercise ex) {
    final it = store.adaptItemFor(widget.week.n, widget.day.j, ex);
    if (it == null) return (const [], null);
    final kt = KTokens.of(context);
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
    if (wristBarPushUp(it.exerciseId, it.reasons) &&
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
      return (const [], null);
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
    final body = label != null
        ? [
            for (final l in lines)
              l.startsWith('$label : ') ? l.substring(label.length + 3) : l,
          ]
        : lines;
    // Une note au moins, ou deux lignes de consigne : la feuille de Koach
    // les reprend toutes (comme l'appui sur le panneau d'avant).
    final row = notes.isEmpty && lines.length < 2
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
      [
        const SizedBox(height: KSpacing.s12),
        Semantics(
          container: true,
          child: Column(
            key: ValueKey('coach-panel-${ex.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label,
                  key: ValueKey('coach-technique-${ex.id}'),
                  style: KType.section.copyWith(color: kt.encre),
                ),
              for (var i = 0; i < body.length; i++)
                Text(
                  body[i],
                  style: i == 0
                      ? KType.corps.copyWith(color: kt.texte)
                      : KType.detail.copyWith(color: kt.texte2),
                ),
              for (final p in pain)
                Padding(
                  padding: const EdgeInsets.only(top: KSpacing.s8),
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
        if (intra != null && intra > 0)
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: KTonalButton(
                key: ValueKey('coach-intra-${ex.id}'),
                icon: Icons.av_timer_rounded,
                label: 'Mini-repos $intra s',
                onPressed: () =>
                    widget.timer.single('INTRA', intra, prepare: false),
              ),
            ),
          ),
      ],
      row,
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
    if (lines.isEmpty && !it.toCalibrate) return null;
    return _openRow(
      key: ValueKey('adapt-notes-${ex.id}'),
      icon: Icons.auto_awesome_outlined,
      title: lines.first,
      detail: lines.length > 1 ? lines[1] : null,
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
      bottom: SessionBottomInset.of(context),
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
  void _showCue(Exercise ex) {
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
            if (ex.cue.isNotEmpty) Text(ex.cue),
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
    padding: const EdgeInsets.fromLTRB(
      KSpacing.page,
      KSpacing.s4,
      KSpacing.page,
      KSpacing.s24,
    ),
    children: [
      if (_group case final g?) ...[
        _GroupCard(
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
        ),
        const SizedBox(height: KSpacing.cardGap),
      ],
      for (var k = 0; k < widget.exs.length; k++) ...[
        if (k > 0) const SizedBox(height: KSpacing.cardGap),
        _block(k),
      ],
    ],
  );

  Widget _block(int k) {
    final t = KTokens.of(context);
    final ex = widget.exs[k];
    final sp = specs[k];
    final log = logs[k];
    final chained = widget.exs.length == 2;
    final readOnly = widget.readOnly;
    final unresolved = widget.unresolvedIds.contains(ex.id);
    final finalRest = !readOnly && sp.myo
        ? store.restAfterSet(ex, sp, log.sets.length - 1, log.sets.length)
        : null;
    final (title, subtitle) = store.splitName(ex.name);
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
    final missing = _missingReference(ex, readOnly);
    final (coach, coachRow) = !readOnly && widget.adapt && ex.engine
        ? _coachPanel(ex)
        : (const <Widget>[], null);
    final notesRow = !readOnly && widget.adapt && ex.engine
        ? _adaptNotes(ex)
        : null;
    final openRows = [?coachRow, ?notesRow];
    // Ligne courante (contour `encre`) : la première série à faire.
    final current = readOnly ? -1 : log.sets.indexWhere((s) => !s.done);
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

    return KCard(
      key: ValueKey('exercise-card-${ex.id}'),
      padding: const EdgeInsets.fromLTRB(
        KSpacing.s16,
        KSpacing.s16,
        KSpacing.s12,
        KSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ----- Prescription -----
          Padding(
            padding: const EdgeInsets.only(right: KSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chained && _group == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: KSpacing.s8),
                    child: KChip(k == 0 ? 'Enchaîné, A' : 'Enchaîné, B'),
                  ),
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
                            KFitTitle(
                              t.title(title),
                              style: t.titleStyle(
                                KType.titreSeance.copyWith(color: t.texte),
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: KSpacing.s4,
                                ),
                                child: Text(subtitle, style: detailStyle),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (!readOnly || (!unresolved && ex.cue.isNotEmpty))
                      KIconButton(
                        key: ValueKey('${ex.id}-instructions'),
                        icon: Icons.info_outline_rounded,
                        tooltip: 'Consignes de l’exercice',
                        color: t.texte2,
                        onPressed: () => _showCue(ex),
                      ),
                  ],
                ),
                const SizedBox(height: KSpacing.s8),
                // Prescription : la charge (ou, sans charge, le volume) en
                // grand chiffre `encre`, puis les puces neutres (C5).
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: KSpacing.s12,
                  runSpacing: KSpacing.s4,
                  children: [
                    if (showBigLoad)
                      Text(
                        loadLabel,
                        style: KType.chiffre.copyWith(color: t.encre),
                      ),
                    Text(
                      readOnly
                          ? '${log.sets.where((s) => s.done).length} / ${log.sets.length} séries validées'
                          : nbsp(store.setsLabel(ex)),
                      style: showBigLoad || readOnly
                          ? KType.corpsFort.copyWith(color: t.texte)
                          : KType.chiffre.copyWith(color: t.encre),
                    ),
                  ],
                ),
                if (missing != null) missing,
                const SizedBox(height: KSpacing.s8),
                Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s8,
                  children: [
                    // « Reps » redit l'en-tête de colonne : la puce ne
                    // nomme que les autres mesures.
                    if (!unresolved && (sp.kind != 'reps' || sp.myo || sp.cluster))
                      KChip(kindLabel),
                    if (readOnly)
                      KChip('Enregistré', icon: Icons.check_rounded),
                    if (!readOnly && showIntensity) KChip(nbsp(ex.intensity)),
                    if (!readOnly && ex.tempo.isNotEmpty)
                      KChip('Tempo ${nbsp(ex.tempo)}'),
                    if (!readOnly && ex.rest.isNotEmpty && ex.rest != '—')
                      KChip('Repos ${nbsp(ex.rest)}'),
                    if (finalRest != null)
                      KChip('Repos final ${fmt(finalRest)}'),
                  ],
                ),
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
                if (readOnly &&
                    (log.prescribed != null || log.koach != null)) ...[
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
                // CI1f : « N × ? reps » servi sur une référence estimée.
                if (!readOnly)
                  if (store.referenceEstimateText(
                        widget.adapt && ex.engine
                            ? (store.programExerciseOf(
                                    widget.week.n,
                                    widget.day.j,
                                    ex,
                                  ) ??
                                  ex)
                            : ex,
                      )
                      case final x?)
                    Padding(
                      key: ValueKey('reference-estimate-${ex.id}'),
                      padding: const EdgeInsets.only(top: KSpacing.s8),
                      child: Text(x, style: detailStyle),
                    ),
                // Notes du coach et calibrage : deux lignes ouvrables.
                if (openRows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: KSpacing.s12),
                    child: Material(
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
                  ),
                if (prev != null)
                  Padding(
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
                            'S${prev.week} : ${store.summarize(prev.log, kg: showKg)}',
                            style: detailStyle.copyWith(
                              fontFeatures: KFont.tabular,
                            ),
                          ),
                        ),
                        KTextButton(
                          label: 'Reprendre',
                          dense: true,
                          onPressed: () => _reusePrevious(k, prev.log),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: KSpacing.s12),
          // ----- Chronos de mode -----
          if (!readOnly &&
              interval != null &&
              ex.timer == null &&
              _group == null)
            _big(
              Icons.timer_outlined,
              'Lancer ${interval.rounds} × ${interval.work} s / ${interval.rest} s',
              () => widget.timer.startInterval(
                interval.rounds,
                interval.work,
                interval.rest,
              ),
            ),
          if (!readOnly && ex.timer != null && !sp.cluster && _group == null)
            _modeButton(ex),
          if (!readOnly &&
              ex.timer == null &&
              sp.kind == 'emom' &&
              _group == null)
            _big(
              Icons.timer_outlined,
              'Lancer l’EMOM de ${sp.seconds! ~/ 60} min',
              () => widget.timer.emom(sp.seconds! ~/ 60, 60),
            ),
          if (!readOnly && ex.timer == null && sp.kind == 'duration')
            _big(
              Icons.timer_outlined,
              'Lancer ${sp.seconds! ~/ 60} min',
              () => widget.timer.single('DURÉE', sp.seconds!),
            ),
          if (!readOnly && sp.cluster && sp.intra != null)
            _big(
              Icons.av_timer_rounded,
              'Mini-repos du cluster, ${sp.intra} s',
              () => widget.timer.single('INTRA', sp.intra!, prepare: false),
            ),
          // ----- Tableau des séries : en-tête de colonnes + lignes -----
          // G9 correction 1 : sans ligne de saisie visible (toutes les
          // séries résumées), pas d'en-tête de colonnes.
          if ([
            for (var i = 0; i < log.sets.length; i++)
              !log.sets[i].done || (!readOnly && i == _openOf(k)),
          ].any((x) => x))
            KSetTable(
              columns: columns,
              rows: const [],
              actionCount: actions,
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
                    onChanged: () {
                      log.sets[i].edited = true;
                      store.saveLogs(affectsProgression: false);
                      setState(() => epoch++);
                    },
                    onIntra: (sec) =>
                        widget.timer.single('INTRA', sec, prepare: false),
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
              padding: const EdgeInsets.symmetric(vertical: KSpacing.s12),
              child: Text(
                'Aucune série enregistrée.',
                style: KType.corps.copyWith(color: t.texte2),
              ),
            ),
          // ----- Barre d'outils de la série (C13 : 48 dp) -----
          if (!readOnly) ...[
            const SizedBox(height: KSpacing.s8),
            Divider(height: 1, thickness: 1, color: t.filet),
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s4),
              child: Row(
                children: [
                  KIconButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Retirer une série',
                    onPressed: () {
                      if (log.removeLastSet()) {
                        store.saveLogs(affectsProgression: false);
                        setState(() {});
                      }
                    },
                  ),
                  KIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Ajouter une série',
                    onPressed: () {
                      log.addSet();
                      _prefill(ex, sp, log);
                      store.saveLogs(affectsProgression: false);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: KSpacing.s4),
                  Expanded(
                    child: Text(
                      '${log.sets.length} série${log.sets.length > 1 ? 's' : ''}',
                      style: KType.libelle.copyWith(color: t.texte2),
                    ),
                  ),
                  KIconButton(
                    key: ValueKey('${ex.id}-note-toggle'),
                    tooltip: _notesOpen.contains(k)
                        ? 'Masquer la note'
                        : log.note.isEmpty
                        ? 'Ajouter une note'
                        : 'Afficher la note',
                    icon: log.note.isEmpty
                        ? Icons.note_add_outlined
                        : Icons.notes_rounded,
                    color: _notesOpen.contains(k) || log.note.isNotEmpty
                        ? t.encre
                        : t.texte2,
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        if (!_notesOpen.add(k)) _notesOpen.remove(k);
                      });
                    },
                  ),
                  if (!noLoad)
                    KIconButton(
                      icon: Icons.tune_rounded,
                      tooltip: 'Colonnes',
                      color: t.texte2,
                      onPressed: () => _columns(k, sp, showKg, showV),
                    ),
                ],
              ),
            ),
          ],
          if (_notesOpen.contains(k)) ...[
            const SizedBox(height: KSpacing.s8),
            if (readOnly)
              InputDecorator(
                decoration: _noteDecoration(t, label: 'Notes'),
                child: Text(log.note, style: KType.corps.copyWith(color: t.texte)),
              )
            else
              TextFormField(
                key: ValueKey('${ex.id}-note'),
                initialValue: log.note,
                minLines: 1,
                maxLines: 3,
                textAlign: TextAlign.left,
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
        ],
      ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KSpacing.s16,
        vertical: KSpacing.s12,
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
    IconData box(bool on) => on
        ? Icons.check_box_rounded
        : Icons.check_box_outline_blank_rounded;
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

  Widget _modeButton(Exercise ex) {
    final tm = ex.timer!;
    switch (tm['type'] as String) {
      case 'emom':
        final r = tm['rounds'] as int, itv = tm['interval'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer l’EMOM, $r × $itv s',
          () => widget.timer.emom(r, itv),
        );
      case 'amrap':
        final s = tm['sec'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer l’AMRAP de ${s ~/ 60} min',
          () => widget.timer.single('AMRAP', s),
        );
      case 'hiit':
        final r = tm['rounds'] as int,
            wk = tm['work'] as int,
            rs = tm['rest'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer $r × $wk s / $rs s',
          () => widget.timer.startInterval(r, wk, rs),
        );
      case 'hold':
        final s = tm['sec'] as int;
        return _big(
          Icons.timer_outlined,
          'Lancer le chrono de $s s',
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
    if (sp.myo) return 'Myo-reps, mini-repos ${sp.intra} s';
    if (sp.cluster) return 'Clusters, mini-repos ${sp.intra} s';
    return labels[sp.kind] ?? sp.kind;
  }
}

// --- Tableau des séries : mêmes mesures que `KSetTable` / `KSetRow` du kit
// (numéro 44, cellules égales séparées de 8, actions de 48), avec des champs
// de saisie, un numéro qui se réduit au lieu de se couper et l'appui long.

/// Champ de saisie d'une série : pilule de 48 dp, chiffre centré
/// (`chiffreMoyen`), `surface` sur la ligne courante, `haute` ailleurs ;
/// contour `danger` quand la saisie est refusée.
class _SetField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool decimal, current, error, readOnly, dimmed;
  final String semanticLabel;
  const _SetField({
    required this.controller,
    required this.onChanged,
    required this.semanticLabel,
    this.decimal = true,
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
  void dispose() {
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
    final shape = StadiumBorder(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: _selectAll,
      child: Material(
        color: color,
        shape: shape,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KSize.target),
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: TextInputType.numberWithOptions(
                decimal: widget.decimal,
              ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: KSpacing.s8,
                  vertical: KSpacing.s12,
                ),
              ),
              onTap: _selectAll,
              onChanged: widget.onChanged,
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
      KSize.target -
      KSize.target * (hasTimer ? 2 : 1) -
      count * KSpacing.s8;
  return count > 2 &&
      available / count < MediaQuery.textScalerOf(context).scale(64);
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
  const _SetRow({
    super.key,
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
    kg = TextEditingController(text: widget.entry.kg);
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
    bool locked = false,
  }) {
    final done = widget.entry.done;
    return _SetField(
      controller: c,
      semanticLabel: '$name, série ${widget.label}',
      decimal: decimal,
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
        _f(kg, (t) => e.kg = t, name: 'Charge en kg', field: SetField.kg),
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
        _f(
          v,
          (t) => e.v = t,
          name: 'Vitesse en m/s',
          field: SetField.velocity,
        ),
    ];
    final check = widget.readOnly
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
              minimumSize: const Size(KSize.target, KSize.target),
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
                tooltip: kind == 'holdMax' ? 'Chrono montant' : 'Compte à rebours',
                style: IconButton.styleFrom(
                  backgroundColor: widget.current ? k.surface : k.haute,
                  foregroundColor: k.texte,
                  minimumSize: const Size(KSize.target, KSize.target),
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
        SizedBox(width: KSize.target, child: Center(child: check)),
      ],
    );
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpacing.s8,
        KSpacing.s4,
        KSpacing.s4,
        KSpacing.s4,
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

String _minutes(int s) => s % 60 == 0 ? '${s ~/ 60}\u00A0min' : _mmss(s);

/// CI1f : libellé d'un groupe (« EMOM 12 min », « Circuit · 3 tours »…).
String groupTitle(kc.GroupSpec g) {
  final rounds = g.rounds;
  final rest = g.restBetweenRoundsSeconds;
  final restText = rest == null || rest == 0
      ? ''
      : ' · ${rest >= 60 ? _minutes(rest) : '$rest\u00A0s'} entre deux tours';
  return switch (g.format) {
    kc.GroupFormat.superset =>
      'Superset${rounds == null ? '' : ' · $rounds tours'}$restText',
    kc.GroupFormat.circuit => 'Circuit · ${rounds ?? 1} tours$restText',
    kc.GroupFormat.roundsForTime =>
      '${rounds ?? 1} tours pour le temps'
          '${g.timeCapSeconds == null ? '' : ' (limite ${_minutes(g.timeCapSeconds!)})'}',
    kc.GroupFormat.amrap =>
      'AMRAP ${_minutes(g.durationSeconds ?? 60)} : un maximum de tours',
    kc.GroupFormat.emom =>
      'EMOM ${_minutes(g.durationSeconds ?? 60)}'
          '${(g.intervalSeconds ?? 60) == 60 ? '' : ' (départ toutes les ${g.intervalSeconds}\u00A0s)'}',
    kc.GroupFormat.chipper =>
      'Chipper : tout, une fois, au meilleur temps'
          '${g.timeCapSeconds == null ? '' : ' (limite ${_minutes(g.timeCapSeconds!)})'}',
    kc.GroupFormat.intervals =>
      'Intervalles · ${rounds ?? 1} × ${g.intervalSeconds ?? 60}\u00A0s'
          '${rest == null || rest == 0 ? '' : ', récupération $rest\u00A0s'}',
  };
}

/// Consigne courte d'un groupe.
String groupHint(kc.GroupSpec g, int members) => switch (g.format) {
  kc.GroupFormat.emom =>
    members > 1
        ? 'Chaque minute, enchaîne les exercices dans l’ordre ; le repos '
              'est ce qui reste de la minute.'
        : 'Chaque minute, fais tes répétitions ; le repos est ce qui reste '
              'de la minute.',
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
  const _GroupCard({
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
  int? get _planned => switch (g.format) {
    kc.GroupFormat.amrap || kc.GroupFormat.chipper => null,
    kc.GroupFormat.emom =>
      ((g.durationSeconds ?? 60) / (g.intervalSeconds ?? 60)).round(),
    _ => g.rounds ?? 1,
  };

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
    kc.GroupFormat.emom => 'Lancer l’EMOM',
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
    return KCard(
      key: ValueKey('group-card-${g.groupId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enchaînement', style: KType.section.copyWith(color: k.encre)),
          const SizedBox(height: KSpacing.s4),
          Text(
            groupTitle(g),
            key: ValueKey('group-title-${g.groupId}'),
            style: KType.titreCarte.copyWith(color: k.texte),
          ),
          if (names.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < names.length; i++)
                    Text(
                      '${i + 1}. ${names[i]}',
                      style: KType.corps.copyWith(color: k.texte),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: KSpacing.s8),
            child: Text(
              groupHint(g, names.length),
              style: KType.detail.copyWith(color: k.texte2),
            ),
          ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s12),
              child: KTonalButton(
                key: ValueKey('group-clock-${g.groupId}'),
                icon: Icons.timer_outlined,
                label: _clockLabel,
                expand: true,
                onPressed: _startClock,
              ),
            ),
          const SizedBox(height: KSpacing.s16),
          Text(
            'Résultat du groupe',
            style: KType.corpsFort.copyWith(color: k.texte),
          ),
          if (g.format != kc.GroupFormat.chipper)
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
                        hintStyle: KType.chiffreMoyen.copyWith(
                          color: k.texte3,
                        ),
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
      ),
    );
  }
}

// ------------------------------ MINI-SÉRIES ------------------------------

/// CI1f : saisie d'une série mini-série par mini-série (cluster,
/// rest-pause, myo-reps) : chaque mini-série s'ajoute une à une (valeur
/// proposée, −/+), le mini-repos se lance, le total remplit la série.
class _MiniSetStrip extends StatefulWidget {
  final String id;
  final MiniSetPlan plan;
  final SetEntry entry;
  final VoidCallback onChanged;
  final void Function(int seconds) onIntra;
  const _MiniSetStrip({
    super.key,
    required this.id,
    required this.plan,
    required this.entry,
    required this.onChanged,
    required this.onIntra,
  });

  @override
  State<_MiniSetStrip> createState() => _MiniSetStripState();
}

class _MiniSetStripState extends State<_MiniSetStrip> {
  late int value;

  List<SetPartEntry> get _parts => widget.entry.parts ?? const [];

  @override
  void initState() {
    super.initState();
    value = widget.plan.suggested(_parts.length);
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

  String get _title => switch (widget.plan.kind) {
    kc.SetTechniqueKind.myoReps => 'Myo-reps : activation, puis mini-séries',
    kc.SetTechniqueKind.cluster =>
      'Cluster : ${widget.plan.cap + 1} mini-séries de ${widget.plan.next}',
    _ => 'Rest-pause : série, puis relances',
  };

  String _partLabel(int i) => switch (widget.plan.kind) {
    kc.SetTechniqueKind.myoReps => i == 0 ? 'Act.' : 'M$i',
    kc.SetTechniqueKind.restPause => i == 0 ? 'Série' : 'R$i',
    _ => 'M${i + 1}',
  };

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final plan = widget.plan;
    final parts = _parts;
    final left = plan.left(parts.length);
    final unit = plan.seconds ? ' s' : '';
    final dim = KType.detail.copyWith(color: k.texte2);
    final advice = left == 0
        ? (plan.exact
              ? 'Toutes les mini-séries sont faites : valide la série.'
              : 'Plafond atteint : valide la série.')
        : parts.isEmpty
        ? (plan.kind == kc.SetTechniqueKind.myoReps
              ? 'Note l’activation, puis chaque mini-série.'
              : 'Note chaque mini-série à la fin de son effort.')
        : plan.exact
        ? 'Encore $left mini-série${left > 1 ? 's' : ''} '
              '(${plan.intra} s entre deux).'
        : 'Encore $left mini-série${left > 1 ? 's' : ''} au plus '
              '(${plan.intra} s entre deux) ; arrête dès qu’une '
              'mini-série n’atteint plus ${plan.next}$unit.';
    final noteLabel = parts.isEmpty
        ? (plan.kind == kc.SetTechniqueKind.myoReps
              ? 'Noter l’activation'
              : 'Noter la première mini-série')
        : 'Noter la mini-série';
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: KSize.target + KSpacing.s4,
        top: KSpacing.s8,
        bottom: KSpacing.s8,
      ),
      child: Semantics(
        container: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title, style: KType.section.copyWith(color: k.encre)),
            if (parts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s8,
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      KChip(
                        '${_partLabel(i)} : ${parts[i].value}$unit',
                        key: ValueKey('miniset-part-${widget.id}-$i'),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: KSpacing.s8),
              child: Text(
                advice,
                key: ValueKey('miniset-advice-${widget.id}'),
                style: dim,
              ),
            ),
            if (left > 0)
              Padding(
                padding: const EdgeInsets.only(top: KSpacing.s8),
                child: Wrap(
                  spacing: KSpacing.s8,
                  runSpacing: KSpacing.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    KeyedSubtree(
                      key: ValueKey('miniset-value-${widget.id}'),
                      child: KStepper(
                        value: '$value$unit',
                        semanticLabel: 'Mini-série',
                        decrementLabel: 'Une de moins',
                        incrementLabel: 'Une de plus',
                        onDecrement: value > 0
                            ? () => setState(() => value--)
                            : null,
                        onIncrement: value < 1000
                            ? () => setState(() => value++)
                            : null,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: noteLabel,
                      excludeSemantics: true,
                      onTap: _add,
                      child: KTonalButton(
                        key: ValueKey('miniset-add-${widget.id}'),
                        label: 'Noter',
                        onPressed: _add,
                      ),
                    ),
                  ],
                ),
              ),
            if (parts.isNotEmpty)
              KTextButton(
                key: ValueKey('miniset-undo-${widget.id}'),
                label: 'Retirer la dernière mini-série',
                alignStart: true,
                onPressed: _removeLast,
              ),
          ],
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
        return Padding(
          padding: EdgeInsets.fromLTRB(
            KSpacing.s16,
            KSpacing.s4,
            KSpacing.s16,
            KSpacing.s12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: bar,
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
                      child: ColoredBox(
                        color: done ? k.validation : k.encre,
                      ),
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
    final title = week.n == 0 ? week.block : 'S${week.n} · J${day.j}';
    final goal = store.game.sessionGoal;
    final reached = totalSets > 0 && doneSets / totalSets >= goal - 1e-9;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24,
      ),
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
                        '${(goal * 100).round()} % des séries, '
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KSpacing.page,
        KSpacing.s8,
        KSpacing.page,
        KSpacing.s24,
      ),
      children: [
        KCard(
          padding: const EdgeInsets.all(KSpacing.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bedtime_outlined, size: KSize.target, color: k.encre),
              const SizedBox(height: KSpacing.s12),
              Text(
                k.title('Repos complet'),
                style: k.titleStyle(KType.titreCarte.copyWith(color: k.texte)),
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
    );
  }
}
