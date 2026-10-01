import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'adapt_screens.dart';
import 'muscle_map_2d.dart' show MapView;
import 'app_theme.dart';
import 'estimate_view.dart';
import 'koach/koach_home_card.dart';
import 'koach/koach_view.dart';
import 'koach_widgets.dart' show KoachWeighInBanner;
import 'levelup.dart';
import 'models.dart';
import 'session_history.dart';
import 'session_screen.dart';
import 'program_start.dart';
import 'program_screens.dart' show ProgramHomeCard;
import 'resume_banner.dart';
import 'stats_mannequin.dart';
import 'store.dart';
import 'store_widget.dart';
import 'ui.dart';
import 'motion.dart';
import 'kalis_clock.dart';

/// Ouvre une journée du programme (accueil ou notification de rappel) : son
/// historique si elle est faite, sinon la séance. Le bilan s'affiche depuis
/// la fin de séance ; au retour, le navigateur vérifie un niveau gagné hors
/// bilan (jour de repos validé…) : ce contexte reste valable même si l'écran
/// d'origine a été reconstruit entre-temps.
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
  if (root.mounted) checkLevelUp(root);
}

class HomeScreen extends StatefulWidget {
  final DateTime? referenceDate;
  const HomeScreen({super.key, this.referenceDate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _pickWeek() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .95,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: store.program.weeks.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choisir une semaine',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              );
            }
            final w = store.program.weeks[i - 1];
            final done = w.days.where((d) => store.isDone(w.n, d.j)).length;
            return ListTile(
              selected: w.n == week,
              leading: CircleAvatar(child: Text('${w.n}')),
              title: Text('Semaine ${w.n} · ${store.program.weekDates(w.n)}'),
              subtitle: Text(
                store.program.containsDate(now) &&
                        w.n == store.program.weekFor(now)
                    ? '${w.block} · Semaine actuelle'
                    : w.block,
              ),
              trailing: Text('$done / ${w.days.length}'),
              onTap: () => Navigator.pop(context, w.n),
            );
          },
        ),
      ),
    );
    if (selected != null && mounted) _selectWeek(selected);
  }

  Future<void> _weekDetails(WeekPlan w) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .94,
      builder: (context, controller) => KList(
        controller: controller,
        children: [
          Text('Semaine ${w.n}', style: Theme.of(context).textTheme.titleLarge),
          Text(store.program.weekDates(w.n).replaceAll('→', ' au ')),
          Text(w.block, style: TextStyle(color: SL.accent)),
          if (w.days.first.cycle.isNotEmpty) Text(w.days.first.cycle),
          Text(
            '${w.days.where((d) => store.isDone(w.n, d.j)).length} / ${w.days.length} journées validées',
          ),
          const KSection('Séances de la semaine'),
          for (final d in w.days)
            KCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Text('J${d.j}'),
                title: Text(d.title),
                subtitle: Text(
                  d.exercises.isEmpty
                      ? 'Récupération'
                      : '${d.exercises.length} exercices · ${store.dayEstimate(d).durationLabel}',
                ),
                trailing: Icon(
                  store.isDone(w.n, d.j)
                      ? Icons.check_circle_outline
                      : Icons.chevron_right,
                  size: 18,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(w, d);
                },
              ),
            ),
          if (store.program.containsDate(now) &&
              w.n != store.program.weekFor(now))
            TextButton(
              onPressed: () {
                Navigator.pop(sheetContext);
                _selectWeek(store.program.weekFor(now));
              },
              child: const Text('Revenir à la semaine actuelle'),
            ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(sheetContext);
              await _pickWeek();
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Choisir une semaine'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Fermer'),
          ),
        ],
      ),
    ),
  );

  Future<void> _open(WeekPlan w, DayPlan d) =>
      openProgramDay(Navigator.of(context), w, d);

  void _summary(WeekPlan w, DayPlan d) {
    final done = store.isDone(w.n, d.j);
    final estimate = store.dayEstimate(d);
    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          done ? 'Séance effectuée' : 'Séance à faire',
          style: TextStyle(color: done ? SL.success : SL.dim),
        ),
        const SizedBox(height: 8),
        if (d.exercises.isEmpty)
          const Text('Repos et récupération · GtG suspendu')
        else
          Row(
            children: [
              Expanded(child: Text('${d.exercises.length} exercices')),
              // M8 : carte 2D des groupes ciblés (face et dos).
              SizedBox(
                width: 110,
                child: TargetedMuscleMap(
                  names: store.plannedNames(estimate),
                  groups: store.plannedMuscles(estimate),
                  height: 110,
                  views: const [MapView.face, MapView.dos],
                  viewLabels: false,
                  subject: 'muscles de la séance',
                ),
              ),
            ],
          ),
      ],
    );
    if (d.exercises.isEmpty) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résumé · S${w.n} · J${d.j}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              overview,
            ],
          ),
        ),
      );
    } else {
      showEstimate(
        context,
        'Résumé · S${w.n} · J${d.j}',
        estimate,
        overview: overview,
      );
    }
  }

  @override
  // L6 : différé tant que l'onglet est masqué (voir store_widget.dart).
  Widget build(BuildContext context) => StoreBuilder(
    builder: (context) {
      final w = store.program.week(week), current = store.program.weekFor(now);
      final colors = ProgrammeColors.of(context);
      final compactHeader = MediaQuery.textScalerOf(context).scale(10) <= 13;
      final header = _WeekHeader(
        week: w,
        dates: store.program.weekDates(w.n),
        onChoose: _pickWeek,
        compact: compactHeader,
      );
      final today = store.program.containsDate(now) && current == week
          ? store.program.dayFor(now)
          : -1;
      Widget card(DayPlan d) => _DayCard(
        week: w,
        day: d,
        isToday: d.j == today,
        done: store.isDone(w.n, d.j),
        inProgress: store.inProgress(store.sessionKey(w.n, d.j)),
        onOpen: () => _open(w, d),
        onSummary: () => _summary(w, d),
      );
      return KScreen(
        // L5 : semaine, bloc et dates visibles, choix d'une semaine en un
        // appui. Dans l'en-tête à taille de texte courante (la semaine
        // entière reste visible) ; en tête de liste avec un grand texte.
        appBar: KTopBar(
          leading: compactHeader
              ? Row(
                  children: [
                    const LevelPill(),
                    const SizedBox(width: 12),
                    Expanded(child: header),
                  ],
                )
              : const LevelPill(),
          height: LevelProgressNumber.headerHeight(context),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.page),
              child: _WeekSlider(
                week: week,
                count: store.program.weeks.length,
                color: colors.slider,
                onChanged: _selectWeek,
                onDetails: () => _weekDetails(w),
                onChoose: _pickWeek,
              ),
            ),
            Expanded(
              child: GestureDetector(
                key: const ValueKey('programme-weeks'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => _swipe = 0,
                onHorizontalDragUpdate: (details) => _swipe += details.delta.dx,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (_swipe.abs() < 48 && velocity.abs() < 300) return;
                  final direction = _swipe.abs() >= 48 ? _swipe : velocity;
                  _selectWeek(week + (direction < 0 ? 1 : -1));
                },
                child: KContentTransition(
                  key: const ValueKey('week-transition'),
                  position: week,
                  child: KList(
                    key: const PageStorageKey('programme-scroll'),
                    controller: _scroll,
                    gap: MediaQuery.sizeOf(context).height < 800 ? 4 : 8,
                    padding: const EdgeInsets.fromLTRB(
                      KSpace.page,
                      8,
                      KSpace.page,
                      12,
                    ),
                    children: [
                      if (!compactHeader) header,
                      // Dans la liste : lisible à 200 % sans écraser les
                      // journées (départ à choisir, à venir, terminé).
                      if (ProgramStartBanner.visible(store.program, now))
                        ProgramStartBanner(now: now, padding: EdgeInsets.zero),
                      // L10 : profil modifié ou programme régénéré.
                      if (ProgramHomeCard.visible) const ProgramHomeCard(),
                      if (ResumeBanner.visible) const ResumeBanner(),
                      if (store.koachWeighInDue) const KoachWeighInBanner(),
                      // L11 (KT-060) : pause en cours, en tête.
                      if (store.adapt.pause != null)
                        const AdaptHomeCard(pauseOnly: true),
                      for (final d in w.days) card(d),
                      // L11 (KT-060 à KT-064) : plan qui glisse, assiduité,
                      // plateau, prudence ; après les journées.
                      if (store.adaptProposals.isNotEmpty)
                        const AdaptHomeCard(proposalsOnly: true),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Titre de la semaine affichée (L5) : numéro, dates et bloc ; un appui
/// ouvre le choix de la semaine. Version compacte dans l'en-tête (deux
/// lignes, flèche de liste déroulante) ; avec un grand texte, ligne pleine
/// en tête de liste avec le bouton « Semaines ».
class _WeekHeader extends StatelessWidget {
  final WeekPlan week;
  final String dates;
  final VoidCallback onChoose;
  final bool compact;
  const _WeekHeader({
    required this.week,
    required this.dates,
    required this.onChoose,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Tiret demi-cadratin : présent dans toutes les polices de l'interface.
    final label = dates.replaceAll('→', ' – ');
    if (compact) {
      return Semantics(
        button: true,
        label: 'Semaine ${week.n}, $label, ${week.block}',
        onTapHint: 'Choisir une semaine',
        excludeSemantics: true,
        child: InkWell(
          key: const ValueKey('week-choose'),
          onTap: onChoose,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'SEMAINE ${week.n}',
                          key: const ValueKey('week-title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SL.text,
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 22,
                        color: SL.accent,
                      ),
                    ],
                  ),
                  Text(
                    '$label · ${week.block}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: SL.dim, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEMAINE ${week.n}',
          key: const ValueKey('week-title'),
          style: TextStyle(
            color: SL.text,
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
          ),
        ),
        Text(
          '${week.block} · $label',
          style: TextStyle(color: SL.dim, fontSize: 12.5, height: 1.3),
        ),
        TextButton.icon(
          key: const ValueKey('week-choose'),
          onPressed: onChoose,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Semaines'),
        ),
      ],
    );
  }
}

/// Appui court : détails ; long : choix. Glissement et clavier : semaine.
class _WeekSlider extends StatefulWidget {
  final int week, count;
  final Color color;
  final ValueChanged<int> onChanged;
  final VoidCallback onDetails, onChoose;
  const _WeekSlider({
    required this.week,
    required this.count,
    required this.color,
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
      const target = 48.0;
      final fraction = widget.count <= 1
          ? 0.0
          : (widget.week - 1) / (widget.count - 1);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final trackWidth = constraints.maxWidth - target;
      void drag(Offset point) {
        if (widget.count <= 1 || trackWidth <= 0) return;
        final x = ((point.dx - target / 2) / trackWidth).clamp(0.0, 1.0);
        widget.onChanged(1 + ((rtl ? 1 - x : x) * (widget.count - 1)).round());
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
            child: SizedBox(
              height: target,
              child: Stack(
                children: [
                  Positioned(
                    left: target / 2 - 2,
                    right: target / 2 - 2,
                    top: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 1; i <= widget.count; i++)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= widget.week ? widget.color : SL.dot,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    start: target / 2,
                    top: 22.5,
                    width: trackWidth * fraction,
                    height: 3,
                    child: ColoredBox(color: widget.color),
                  ),
                  PositionedDirectional(
                    start: trackWidth * fraction,
                    top: 0,
                    width: target,
                    height: target,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(20),
                          border: _focused
                              ? Border.all(color: SL.text, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          'S${widget.week}',
                          key: const ValueKey('selected-week'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.5),
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: ProgrammeColors.of(context).onSlider,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DayCard extends StatelessWidget {
  final WeekPlan week;
  final DayPlan day;
  final bool isToday, done, inProgress;
  final VoidCallback onOpen, onSummary;
  const _DayCard({
    required this.week,
    required this.day,
    required this.isToday,
    required this.done,
    this.inProgress = false,
    required this.onOpen,
    required this.onSummary,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 800;
    final recovery = day.exercises.isEmpty;
    final estimate = isToday && !recovery ? store.dayEstimate(day) : null;
    final foreground = isToday ? SL.onBrand : SL.text;
    final secondary = isToday ? SL.onBrandSoft : SL.dim;
    final status = done
        ? 'Séance effectuée'
        : inProgress
        ? 'Séance en cours'
        : 'Séance à faire';
    final statusColor = done
        ? (isToday ? SL.onBrandSoft : SL.success)
        : inProgress
        ? (isToday ? SL.onBrandSoft : SL.accent)
        : secondary;
    final icon = Icon(
      done
          ? Icons.check_circle_rounded
          : inProgress
          ? Icons.timelapse_rounded
          : Icons.radio_button_unchecked_rounded,
      key: ValueKey('day-status-${day.j}'),
      semanticLabel: status,
      size: 20,
      color: statusColor,
    );
    // L5 : une séance commencée est écrite, pas seulement signalée par
    // l'icône (fait / à faire restent des icônes, lues par TalkBack).
    final statusIcon = inProgress && !done
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'En cours',
                key: ValueKey('day-in-progress-${day.j}'),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              icon,
            ],
          )
        : icon;
    // Titre sur une ligne dans la mise en page de référence (la semaine
    // entière tient à l'écran) ; deux lignes sur écran étroit ou grand texte.
    final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
    final titleLines = textScale > 1.5
        ? 3
        : MediaQuery.sizeOf(context).width < 360 || textScale > 1.1
        ? 2
        : 1;
    return Semantics(
      button: true,
      selected: isToday,
      label:
          'Jour ${day.j} · ${day.title}. $status${isToday ? ". Aujourd’hui" : ""}',
      value: !isToday
          ? null
          : estimate == null
          ? 'Repos et récupération. GtG suspendu.'
          : '${estimate.durationLabel}, ${day.exercises.length} exercices, ${estimate.sets.round()} séries, ${estimate.volumeLabel}',
      onTap: onOpen,
      onLongPress: onSummary,
      onTapHint: done
          ? 'Afficher l’historique'
          : inProgress
          ? 'Reprendre la séance'
          : 'Ouvrir la séance',
      onLongPressHint: 'Afficher le résumé',
      child: ExcludeSemantics(
        child: KCard(
          key: ValueKey('programme-day-${day.j}'),
          color: isToday ? SL.bordeaux : SL.card,
          onTap: onOpen,
          onLongPress: onSummary,
          padding: isToday
              ? EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: compact ? 12 : 16,
                )
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: isToday
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'J${day.j} · AUJOURD’HUI',
                                      style: TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .9,
                                      ),
                                    ),
                                  ),
                                  statusIcon,
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // G5 (D6.4) : Koach sur la carte du jour, sa pose
                        // dit la journée (séance, repos, en cours, faite).
                        const SizedBox(width: 8),
                        KoachView(
                          key: const ValueKey('koach-today-view'),
                          pose: KoachToday(
                            day: day,
                            done: done,
                            inProgress: inProgress,
                            today: KalisClock.now(),
                          ).pose(),
                          height: 44,
                          width: 40,
                          colors: KoachColors.onColor(SL.bordeaux),
                        ),
                      ],
                    ),
                    if (recovery) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Prends le temps de récupérer.',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Repos et récupération · GtG suspendu',
                        style: TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                    if (estimate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  estimate.durationLabel,
                                  style: TextStyle(
                                    color: SL.onBrand,
                                    fontSize: 25,
                                    height: 1.15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -.5,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Estimé · repos inclus',
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${day.exercises.length} exercices · ${estimate.sets.round()} séries',
                                  style: TextStyle(
                                    color: foreground,
                                    fontSize: 12,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  estimate.volumeLabel,
                                  style: TextStyle(
                                    color: secondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width < 350
                                ? 88
                                : 106,
                            // M8 : carte 2D des muscles ciblés. 5.10.1
                            // (propriétaire : « trop claire et flashy ») :
                            // mêmes couleurs que l'écran Anatomie, aussi sur
                            // la carte du jour (gris, couleur dominante).
                            child: TargetedMuscleMap(
                              names: store.plannedNames(estimate),
                              groups: store.plannedMuscles(estimate),
                              height: compact ? 90 : 110,
                              views: const [MapView.face, MapView.dos],
                              viewLabels: false,
                              subject: 'muscles de la séance',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 24),
                  child: Row(
                    children: [
                      Text(
                        'J${day.j}',
                        style: TextStyle(
                          color: SL.dim,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          day.title,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      statusIcon,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
