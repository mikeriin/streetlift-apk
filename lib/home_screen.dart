// Onglet Programme (accueil). UI1 (refonte UI, maquette « Accueil ») :
// en-tête niveau, semaine et logo sans troncature ; barre de saison par
// blocs (U7) à la place de la frise de points, mêmes gestes (appui : détail,
// appui long : choix, glisser, clavier) ; lignes de jour et carte du jour
// (Koach et anatomie inchangés) ; bandeaux dans le flux (C8) ; ligne
// permanente « Mon programme » (§4.1) ; feuilles au gabarit (§4.5).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'muscle_map_2d.dart' show MapView;
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'estimate_view.dart';
import 'koach/koach_home_card.dart';
import 'koach/koach_view.dart';
import 'levelup.dart';
import 'models.dart';
import 'plan/widgets/program_widgets.dart';
import 'session_history.dart';
import 'session_screen.dart';
import 'program_explainer.dart';
import 'program_start.dart';
import 'plan/evolution_widgets.dart' show EvolutionHomeCard;
import 'program_screens.dart' show ProgramHomeCard, openMyProgram;
import 'resume_banner.dart';
import 'stats_mannequin.dart';
import 'guided_tests.dart';
import 'profile_completion.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';
import 'motion.dart';
import 'kalis_clock.dart';

/// Route au sommet de [nav] (sans rien refermer).
Route<dynamic>? _topRoute(NavigatorState nav) {
  Route<dynamic>? top;
  nav.popUntil((r) {
    top = r;
    return true;
  });
  return top;
}

/// Ouvre une journée du programme (accueil ou notification de rappel) : son
/// historique si elle est faite, sinon la séance. Le bilan s'affiche depuis
/// la fin de séance ; au retour, le navigateur vérifie un niveau gagné hors
/// bilan (jour de repos validé…) : ce contexte reste valable même si l'écran
/// d'origine a été reconstruit entre-temps.
///
/// UI1 (cahier §4.6) : cette vérification attend que la séance ait fini de
/// se refermer, et n'a lieu que si rien n'a été ouvert par-dessus entre-
/// temps. La fin de séance de Koach (« Fin de séance », séance servie par
/// kalis_adapt) s'ouvre à la fermeture de la séance et présente elle-même
/// les récompenses quand on la quitte : les vérifier dès la fermeture les
/// faisait passer sous elle.
///
/// Une journée déjà ouverte n'est jamais empilée une seconde fois (clic
/// répété, notification à chaud) : on revient à son écran. Une autre
/// journée ouverte est d'abord refermée : son brouillon reste (fermer un
/// écran n'est pas abandonner). Aucune occurrence, série ni récompense
/// n'est créée par l'ouverture.
Future<void> openProgramDay(NavigatorState nav, WeekPlan w, DayPlan d) async {
  final key = store.sessionKey(w.n, d.j);
  final active = [
    for (final e in openDayRoutes)
      if (e.route.isActive && identical(e.route.navigator, nav)) e,
  ];
  final same = active.where((e) => e.key == key).lastOrNull;
  if (same != null) {
    nav.popUntil((r) => identical(r, same.route));
    return;
  }
  if (active.isNotEmpty) {
    final first = active.first.route;
    nav.popUntil((r) => identical(r, first));
    if (first.isCurrent) nav.pop();
  }
  final log = store.logs[key];
  final root = nav.context;
  final below = _topRoute(nav);
  final route = MaterialPageRoute<void>(
    builder: (_) => log?.done == true
        ? SessionHistoryScreen(log: log!, week: w, day: d)
        : SessionScreen(week: w, day: d),
  );
  // Enregistrée avant la première image : un second appel dans la même
  // frame retrouve déjà cette route.
  registerDayRoute(key, route);
  try {
    await nav.push<void>(route);
  } finally {
    unregisterDayRoute(route);
  }
  // Fin de la transition de sortie de la séance.
  await route.completed;
  if (!root.mounted || !nav.mounted) return;
  // Une page ouverte par la fin de séance (« Fin de séance », récompenses)
  // est au sommet : c'est elle qui présente les récompenses, après elle.
  if (!identical(_topRoute(nav), below)) return;
  checkLevelUp(root);
}

class HomeScreen extends StatefulWidget {
  final DateTime? referenceDate;
  const HomeScreen({super.key, this.referenceDate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _evoScheduled = false;

  void _scheduleEvolutionRefresh() {
    if (_evoScheduled) return;
    _evoScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evoScheduled = false;
      if (mounted) store.evolutionRefresh();
    });
  }

  late int week;
  DateTime get now => widget.referenceDate ?? KalisClock.now();
  @override
  void initState() {
    super.initState();
    week = store.program.weekFor(now);
  }

  final ScrollController _scroll = ScrollController();
  double _swipe = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _selectWeek(int value) {
    final next = value.clamp(1, store.program.weeks.length);
    if (next == week) return;
    setState(() => week = next);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  bool _isCurrentWeek(int n) =>
      store.program.containsDate(now) && n == store.program.weekFor(now);

  /// Choix d'une semaine : feuille de liste (§4.5).
  Future<void> _pickWeek() async {
    final weeks = store.program.weeks;
    final selected = await showProgramListSheet(
      context,
      title: 'Choisir une semaine',
      summary: '${weeks.length} semaines',
      initial: weeks.indexWhere((w) => w.n == week),
      items: [
        for (final w in weeks)
          KListItem(
            'Semaine ${w.n}',
            detail: [
              _dates(store.program.weekDates(w.n)),
              w.block,
              if (_isCurrentWeek(w.n)) 'Semaine actuelle',
              '${w.days.where((d) => store.isDone(w.n, d.j)).length} / '
                  '${w.days.length} faites',
            ].join(' · '),
            state: w.n == week
                ? KListState.current
                : w.days.every((d) => store.isDone(w.n, d.j))
                ? KListState.done
                : KListState.todo,
          ),
      ],
    );
    if (selected != null && mounted) _selectWeek(weeks[selected].n);
  }

  /// Détail d'une semaine : jours (appui : ouvrir, ⓘ : résumé, R7),
  /// retour à la semaine actuelle, choix d'une autre semaine.
  Future<void> _weekDetails(WeekPlan w) => showProgramSheet<void>(
    context,
    draggable: true,
    listKey: const ValueKey('week-sheet'),
    title: 'Semaine ${w.n}',
    subtitle: _dates(store.program.weekDates(w.n)),
    gap: KSpacing.s8,
    children: (sheetContext) {
      final k = KTokens.of(sheetContext);
      final done = w.days.where((d) => store.isDone(w.n, d.j)).length;
      return [
        Text(
          [w.block, if (w.days.first.cycle.isNotEmpty) w.days.first.cycle]
              .join(' · '),
          style: KType.corps.copyWith(color: k.texte),
        ),
        Text(
          '$done / ${w.days.length} journées validées',
          style: KType.detail.copyWith(color: k.texte2),
        ),
        const KSectionTitle('Séances de la semaine', top: KSpacing.s8),
        for (final d in w.days)
          ProgramDayRow(
            key: ValueKey('week-sheet-day-${d.j}'),
            day: d.j,
            title: d.title,
            color: k.haute,
            detail: d.exercises.isEmpty
                ? 'Récupération'
                : '${d.exercises.length} exercices, '
                      '${store.dayEstimate(d).durationLabel}',
            status: _status(w, d),
            onTap: () {
              Navigator.pop(sheetContext);
              _open(w, d);
            },
            onLongPress: () => _summary(w, d),
            onInfo: () => _summary(w, d),
          ),
        const SizedBox(height: KSpacing.s4),
        Wrap(
          spacing: KSpacing.s8,
          runSpacing: KSpacing.s8,
          children: [
            if (store.program.containsDate(now) &&
                w.n != store.program.weekFor(now))
              KTonalButton(
                key: const ValueKey('week-sheet-current'),
                label: 'Revenir à la semaine actuelle',
                icon: Icons.today_outlined,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _selectWeek(store.program.weekFor(now));
                },
              ),
            KTonalButton(
              key: const ValueKey('week-sheet-choose'),
              label: 'Choisir une semaine',
              icon: Icons.calendar_month_outlined,
              onPressed: () async {
                Navigator.pop(sheetContext);
                await _pickWeek();
              },
            ),
          ],
        ),
        Center(
          child: KTextButton(
            label: 'Fermer',
            onPressed: () => Navigator.pop(sheetContext),
          ),
        ),
      ];
    },
  );

  Future<void> _open(WeekPlan w, DayPlan d) =>
      openProgramDay(Navigator.of(context), w, d);

  ProgramDayStatus _status(WeekPlan w, DayPlan d) {
    if (store.isDone(w.n, d.j)) return ProgramDayStatus.done;
    if (store.inProgress(store.sessionKey(w.n, d.j))) {
      return ProgramDayStatus.inProgress;
    }
    if (PlanStore(store).isResume(w.n, d.j)) return ProgramDayStatus.resume;
    return ProgramDayStatus.todo;
  }

  void _summary(WeekPlan w, DayPlan d) {
    final done = store.isDone(w.n, d.j);
    final estimate = store.dayEstimate(d);
    final title = 'Résumé · S${w.n} · J${d.j}';
    Widget overview(BuildContext context) {
      final k = KTokens.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d.title, style: KType.corpsFort.copyWith(color: k.texte)),
          const SizedBox(height: KSpacing.s4),
          Text(
            done ? 'Séance effectuée' : 'Séance à faire',
            style: KType.detail.copyWith(
              color: done ? k.validation : k.texte2,
            ),
          ),
          const SizedBox(height: KSpacing.s8),
          if (d.exercises.isEmpty)
            Text(
              'Repos et récupération · GtG suspendu',
              style: KType.corps.copyWith(color: k.texte),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${d.exercises.length} exercices',
                    style: KType.corps.copyWith(color: k.texte),
                  ),
                ),
                // M8 : carte 2D des groupes ciblés (face et dos).
                SizedBox(
                  width: _mapWidth,
                  child: TargetedMuscleMap(
                    names: store.plannedNames(estimate),
                    groups: store.plannedMuscles(estimate),
                    height: _mapWidth,
                    views: const [MapView.face, MapView.dos],
                    viewLabels: false,
                    subject: 'muscles de la séance',
                  ),
                ),
              ],
            ),
        ],
      );
    }

    if (d.exercises.isEmpty) {
      showProgramSheet<void>(
        context,
        title: title,
        children: (context) => [overview(context)],
      );
    } else {
      showEstimate(context, title, estimate, overview: overview(context));
    }
  }

  @override
  // L6 : différé tant que l'onglet est masqué (voir store_widget.dart).
  Widget build(BuildContext context) => StoreBuilder(
    builder: (context) {
      // G6 correction 1 : nouveau profil sans programme → pas de programme
      // embarqué affiché, Koach annonce le programme à venir.
      if (programPendingFor(store)) return const ProgramPendingView();
      // G10 : revue du moteur dynamique (une par état du journal) ; ses
      // propositions apparaissent dans la carte de Koach ci-dessous.
      _scheduleEvolutionRefresh();
      final k = KTokens.of(context);
      final w = store.program.week(week), current = store.program.weekFor(now);
      final today = store.program.containsDate(now) && current == week
          ? store.program.dayFor(now)
          : -1;
      Widget row(DayPlan d) {
        if (d.j == today) {
          return _TodayCard(
            key: ValueKey('programme-day-${d.j}'),
            week: w,
            day: d,
            status: _status(w, d),
            onOpen: () => _open(w, d),
            onSummary: () => _summary(w, d),
          );
        }
        return ProgramDayRow(
          key: ValueKey('programme-day-${d.j}'),
          day: d.j,
          title: d.title,
          status: _status(w, d),
          onTap: () => _open(w, d),
          onLongPress: () => _summary(w, d),
        );
      }

      // Cartes du moment (C8 : toutes dans le flux, au-dessus du dock).
      final moments = <Widget>[
        // G10 : propositions de Koach (évolution du programme).
        if (EvolutionHomeCard.visible) const EvolutionHomeCard(),
        // CU : compléter son profil (une fois) ; test guidé proposé à la
        // première séance.
        if (ProfileCompletionCard.visible) const ProfileCompletionCard(),
        if (GuidedTestHomeCard.visible) const GuidedTestHomeCard(),
        // G7 : Où j'en suis, fin de bloc, retour à l'ancien programme.
        if (ProgramHomeCard.visible) const ProgramHomeCard(),
      ];
      final children = <Widget>[
        _HomeHeader(
          week: w,
          weekInBlock: _weekInBlock(w.n),
          dates: _dates(store.program.weekDates(w.n)),
          onChoose: _pickWeek,
        ),
        const SizedBox(height: KSpacing.s4),
        _WeekSlider(
          week: week,
          count: store.program.weeks.length,
          blocks: _blocks(),
          onChanged: _selectWeek,
          onDetails: () => _weekDetails(w),
          onChoose: _pickWeek,
        ),
        const SizedBox(height: KSpacing.s8),
        // Départ à choisir, à venir ou terminé ; séances à reprendre.
        if (ProgramStartBanner.visible(store.program, now)) ...[
          ProgramStartBanner(now: now, padding: EdgeInsets.zero),
          const SizedBox(height: KSpacing.s12),
        ],
        if (ResumeBanner.visible) ...[
          const ResumeBanner(),
          const SizedBox(height: KSpacing.s12),
        ],
        for (var i = 0; i < w.days.length; i++) ...[
          if (i > 0) const SizedBox(height: KSpacing.s8),
          row(w.days[i]),
        ],
        // §4.1 : place fixe, toujours visible après la liste des jours.
        const SizedBox(height: KSpacing.s16),
        KMenuGroup(
          children: [
            KMenuRow(
              key: const ValueKey('home-my-program'),
              icon: Icons.flag_outlined,
              title: 'Mon programme',
              subtitle: 'Saison, évolution, calendrier, changer de programme',
              onTap: () => openMyProgram(context),
            ),
          ],
        ),
        for (final m in moments) ...[
          const SizedBox(height: KSpacing.s12),
          m,
        ],
      ];
      return Scaffold(
        backgroundColor: k.fond,
        body: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
              child: GestureDetector(
                key: const ValueKey('programme-weeks'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => _swipe = 0,
                onHorizontalDragUpdate: (details) => _swipe += details.delta.dx,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (_swipe.abs() < KSize.target && velocity.abs() < 300) {
                    return;
                  }
                  final direction = _swipe.abs() >= KSize.target
                      ? _swipe
                      : velocity;
                  _selectWeek(week + (direction < 0 ? 1 : -1));
                },
                child: KContentTransition(
                  key: const ValueKey('week-transition'),
                  position: week,
                  child: ListView(
                    key: const PageStorageKey('programme-scroll'),
                    controller: _scroll,
                    padding: EdgeInsets.fromLTRB(
                      KSpacing.page,
                      KSpacing.s8,
                      KSpacing.page,
                      KSpacing.s16 + KNavigationInset.of(context),
                    ),
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  /// Blocs du programme (semaines consécutives d'un même bloc).
  List<KSeasonBlock> _blocks() {
    final out = <KSeasonBlock>[];
    String? name;
    var n = 0;
    for (final w in store.program.weeks) {
      if (w.block != name && n > 0) {
        out.add(KSeasonBlock(n, label: name));
        n = 0;
      }
      name = w.block;
      n++;
    }
    if (n > 0) out.add(KSeasonBlock(n, label: name));
    return out;
  }

  /// Rang de la semaine [n] dans son bloc et longueur du bloc.
  (int, int) _weekInBlock(int n) {
    final weeks = store.program.weeks;
    final i = weeks.indexWhere((w) => w.n == n);
    if (i < 0) return (1, 1);
    final block = weeks[i].block;
    var first = i, last = i;
    while (first > 0 && weeks[first - 1].block == block) {
      first--;
    }
    while (last < weeks.length - 1 && weeks[last + 1].block == block) {
      last++;
    }
    return (i - first + 1, last - first + 1);
  }
}

/// Dates d'une semaine au format de l'interface (« 07/10 – 13/10/2026 »).
String _dates(String raw) => raw.replaceAll('→', ' – ');

/// Largeur de la carte des muscles d'un résumé.
const double _mapWidth = KSize.primary * 2;

/// En-tête de l'accueil (maquette « Accueil ») : niveau, semaine affichée
/// (titre, dates, bloc ; un appui ouvre le choix de la semaine, R7) et logo.
/// Aucun texte coupé (C3) : la semaine passe à la ligne ; en grand texte,
/// niveau et logo restent sur la première ligne et la semaine dessous.
class _HomeHeader extends StatelessWidget {
  final WeekPlan week;
  final (int, int) weekInBlock;
  final String dates;
  final VoidCallback onChoose;
  const _HomeHeader({
    required this.week,
    required this.weekInBlock,
    required this.dates,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final (rank, length) = weekInBlock;
    final block = length > 1
        ? '${week.block}, semaine $rank sur $length'
        : week.block;
    final title = Semantics(
      button: true,
      label: 'Semaine ${week.n}, $dates, $block',
      onTapHint: 'Choisir une semaine',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        shape: KRadius.menuShape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('week-choose'),
          onTap: onChoose,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KSize.target),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          k.title('Semaine ${week.n}'),
                          key: const ValueKey('week-title'),
                          style: k.titleStyle(
                            KType.titreEcran.copyWith(color: k.texte),
                          ),
                        ),
                      ),
                      const SizedBox(width: KSpacing.s4),
                      Icon(
                        Icons.expand_more_rounded,
                        size: KSize.icon,
                        color: k.encre,
                      ),
                    ],
                  ),
                  Text(dates, style: KType.detail.copyWith(color: k.texte2)),
                  Text(block, style: KType.detail.copyWith(color: k.texte2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    if (large) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LevelPill(),
              Spacer(),
              HeaderLogo(),
            ],
          ),
          const SizedBox(height: KSpacing.s8),
          title,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LevelPill(),
        const SizedBox(width: KSpacing.s12),
        Expanded(child: title),
        const SizedBox(width: KSpacing.s12),
        const Padding(
          padding: EdgeInsets.only(top: KSpacing.s4),
          child: HeaderLogo(),
        ),
      ],
    );
  }
}

/// Barre de saison par blocs (U7, `KSeasonBar`) et ses gestes, ceux de
/// l'ancienne frise : appui court, détail de la semaine ; appui long, choix
/// d'une semaine ; glisser, semaine sous le doigt ; clavier : flèches,
/// début, fin, Entrée (détail), F2 (choix). Cible de 48 dp.
class _WeekSlider extends StatefulWidget {
  final int week, count;
  final List<KSeasonBlock> blocks;
  final ValueChanged<int> onChanged;
  final VoidCallback onDetails, onChoose;
  const _WeekSlider({
    required this.week,
    required this.count,
    required this.blocks,
    required this.onChanged,
    required this.onDetails,
    required this.onChoose,
  });
  @override
  State<_WeekSlider> createState() => _WeekSliderState();
}

class _WeekSliderState extends State<_WeekSlider> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _step(int delta) =>
      widget.onChanged((widget.week + delta).clamp(1, widget.count));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final k = KTokens.of(context);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final width = constraints.maxWidth;
      void drag(Offset point) {
        if (widget.count <= 1 || width <= 0) return;
        final x = (point.dx / width).clamp(0.0, 1.0);
        final at = rtl ? 1 - x : x;
        widget.onChanged(
          math.min(widget.count, 1 + (at * widget.count).floor()),
        );
      }

      return Semantics(
        slider: true,
        label: 'Progression du programme',
        value: 'Semaine ${widget.week} sur ${widget.count}',
        increasedValue: widget.week < widget.count
            ? 'Semaine ${widget.week + 1} sur ${widget.count}'
            : null,
        decreasedValue: widget.week > 1
            ? 'Semaine ${widget.week - 1} sur ${widget.count}'
            : null,
        onIncrease: widget.week < widget.count ? () => _step(1) : null,
        onDecrease: widget.week > 1 ? () => _step(-1) : null,
        onTap: widget.onDetails,
        onTapHint: 'Afficher le détail de la semaine',
        onLongPress: widget.onChoose,
        onLongPressHint: 'Choisir une semaine',
        excludeSemantics: true,
        child: Focus(
          focusNode: _focus,
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (_, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.arrowRight) {
              _step(rtl ? -1 : 1);
            } else if (key == LogicalKeyboardKey.arrowLeft) {
              _step(rtl ? 1 : -1);
            } else if (key == LogicalKeyboardKey.home) {
              widget.onChanged(1);
            } else if (key == LogicalKeyboardKey.end) {
              widget.onChanged(widget.count);
            } else if (key == LogicalKeyboardKey.f2) {
              widget.onChoose();
            } else if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.space) {
              widget.onDetails();
            } else {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.handled;
          },
          child: GestureDetector(
            key: const ValueKey('week-slider'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _focus.requestFocus();
              widget.onDetails();
            },
            onLongPress: () {
              _focus.requestFocus();
              widget.onChoose();
            },
            onHorizontalDragStart: (details) {
              _focus.requestFocus();
              drag(details.localPosition);
            },
            onHorizontalDragUpdate: (details) => drag(details.localPosition),
            child: DecoratedBox(
              // Focus clavier : contour de l'élément courant.
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: KRadius.menuRadius,
                  side: _focused
                      ? BorderSide(color: k.encre, width: KSize.current)
                      : BorderSide.none,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: KSize.target),
                child: Center(
                  child: KeyedSubtree(
                    key: const ValueKey('selected-week'),
                    child: KSeasonBar(
                      blocks: widget.blocks,
                      week: widget.week,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Carte du jour (`KCard.day`, aplat de la dominante) : surtitre et état,
/// titre de la séance (jamais coupé), durée estimée, volume ; Koach et la
/// carte des muscles à droite, dessins inchangés (§1).
class _TodayCard extends StatelessWidget {
  final WeekPlan week;
  final DayPlan day;
  final ProgramDayStatus status;
  final VoidCallback onOpen, onSummary;
  const _TodayCard({
    super.key,
    required this.week,
    required this.day,
    required this.status,
    required this.onOpen,
    required this.onSummary,
  });

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    final ink = k.surPleine;
    final compact = MediaQuery.sizeOf(context).height < 800;
    final recovery = day.exercises.isEmpty;
    final estimate = recovery ? null : store.dayEstimate(day);
    final done = status == ProgramDayStatus.done;
    final inProgress = status == ProgramDayStatus.inProgress;
    final statusLabel = switch (status) {
      ProgramDayStatus.done => 'Séance effectuée',
      ProgramDayStatus.inProgress => 'Séance en cours',
      ProgramDayStatus.resume => 'Reprise : séance neutre',
      ProgramDayStatus.todo => 'Séance à faire',
    };
    final written = switch (status) {
      ProgramDayStatus.inProgress => 'En cours',
      ProgramDayStatus.resume => 'Reprise',
      _ => null,
    };
    final icon = Icon(
      switch (status) {
        ProgramDayStatus.done => Icons.check_circle_rounded,
        ProgramDayStatus.inProgress => Icons.timelapse_rounded,
        ProgramDayStatus.resume => Icons.fast_forward_rounded,
        ProgramDayStatus.todo => Icons.radio_button_unchecked_rounded,
      },
      key: ValueKey('day-status-${day.j}'),
      semanticLabel: statusLabel,
      size: KSize.iconSmall,
      color: ink,
    );
    final texts = <Widget>[
      Row(
        children: [
          Flexible(
            child: Text(
              k.title('J${day.j}, aujourd’hui'),
              style: KType.micro.copyWith(
                color: ink,
                letterSpacing: KType.capsSpacing * 2,
              ),
            ),
          ),
          const SizedBox(width: KSpacing.s8),
          if (written != null) ...[
            Text(
              written,
              key: ValueKey(
                inProgress ? 'day-in-progress-${day.j}' : 'day-resume-${day.j}',
              ),
              style: KType.micro.copyWith(color: ink),
            ),
            const SizedBox(width: KSpacing.s4),
          ],
          icon,
        ],
      ),
      const SizedBox(height: KSpacing.s4),
      Text(
        k.title(day.title),
        style: k.titleStyle(KType.titreSeance.copyWith(color: ink)),
      ),
      if (recovery) ...[
        const SizedBox(height: KSpacing.s12),
        Text(
          'Prends le temps de récupérer.',
          style: KType.corps.copyWith(color: ink),
        ),
        const SizedBox(height: KSpacing.s4),
        Text(
          'Repos et récupération · GtG suspendu',
          style: KType.detail.copyWith(color: ink),
        ),
      ],
      if (estimate != null) ...[
        const SizedBox(height: KSpacing.s8),
        Text(estimate.durationLabel, style: KType.chiffre.copyWith(color: ink)),
        Text(
          'Estimé, repos inclus',
          style: KType.detail.copyWith(color: ink),
        ),
        const SizedBox(height: KSpacing.s8),
        Text(
          '${day.exercises.length} exercices, '
          '${estimate.sets.round()} séries',
          style: KType.detail.copyWith(color: ink),
        ),
        Text(estimate.volumeLabel, style: KType.detail.copyWith(color: ink)),
      ],
    ];
    // G5 (D6.4) : Koach sur la carte du jour, sa pose dit la journée
    // (séance, repos, en cours, faite).
    final koach = KoachView(
      key: const ValueKey('koach-today-view'),
      pose: KoachToday(
        day: day,
        done: done,
        inProgress: inProgress,
        today: KalisClock.now(),
      ).pose(),
      height: KSize.primary,
      width: KSpacing.s32 + KSpacing.s8,
      colors: KoachColors.onColor(k.pleine),
    );
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        koach,
        if (estimate != null) ...[
          const SizedBox(height: KSpacing.s8),
          SizedBox(
            width: MediaQuery.sizeOf(context).width < 350
                ? KSize.primary + KSpacing.s32
                : _mapWidth,
            // M8 : carte 2D des muscles ciblés, couleurs de l'Anatomie
            // (5.10.1), dessin inchangé.
            child: TargetedMuscleMap(
              names: store.plannedNames(estimate),
              groups: store.plannedMuscles(estimate),
              height: compact ? KSize.primary + KSpacing.s32 : _mapWidth,
              views: const [MapView.face, MapView.dos],
              viewLabels: false,
              subject: 'muscles de la séance',
            ),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      selected: true,
      label: 'Jour ${day.j} · ${day.title}. $statusLabel. Aujourd’hui',
      value: estimate == null
          ? 'Repos et récupération. GtG suspendu.'
          : '${estimate.durationLabel}, ${day.exercises.length} exercices, '
                '${estimate.sets.round()} séries, ${estimate.volumeLabel}',
      onTap: onOpen,
      onLongPress: onSummary,
      onTapHint: done
          ? 'Afficher l’historique'
          : inProgress
          ? 'Reprendre la séance'
          : 'Ouvrir la séance',
      onLongPressHint: 'Afficher le résumé',
      child: ExcludeSemantics(
        child: KCard.day(
          padding: const EdgeInsets.all(KSpacing.s16),
          onTap: onOpen,
          onLongPress: onSummary,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: texts,
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              side,
            ],
          ),
        ),
      ),
    );
  }
}
