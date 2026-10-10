import 'package:flutter/material.dart';
import 'dev/dev_widgets.dart' show HeaderLogo;
import 'kit/kit.dart';
import 'store_widget.dart';
import 'stats_navigation.dart';
import 'stats_overview.dart';
import 'stats_progression.dart';
import 'stats_performance.dart';
import 'stats_history.dart';

/// Onglet Stats (UI3) : page racine à grand titre et une phrase (C1), quatre
/// rubriques (Aperçu, Parcours, Performances, Historique). [standalone] :
/// ouverte depuis une autre page (raccourcis de progression), en sous-page
/// à en-tête standard.
class StatsScreen extends StatefulWidget {
  final StatsSection initialSection;
  final bool standalone;
  const StatsScreen({
    super.key,
    this.initialSection = StatsSection.overview,
    this.standalone = false,
  });
  @override
  State<StatsScreen> createState() => StatsScreenState();
}

/// Libellés des rubriques, dans l'ordre de [StatsSection].
const statsSectionLabels = ['Aperçu', 'Parcours', 'Performances', 'Historique'];

class StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  TabController? _controller;
  TabController get _tabs => _controller!;
  bool? _reduceMotion;
  late int _index;
  final Set<int> _visited = {};
  @override
  void initState() {
    super.initState();
    _index = widget.initialSection.index;
    _visited.add(_index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    _controller?.dispose();
    _controller = TabController(
      length: StatsSection.values.length,
      vsync: this,
      initialIndex: _index,
      animationDuration: KMotion.fast.durationIn(context),
    )..addListener(_changed);
  }

  void _changed() {
    if (_index == _tabs.index) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _index = _tabs.index;
      _visited.add(_index);
    });
  }

  void selectSection(StatsSection section) => _tabs.animateTo(
    section.index,
    duration: KMotion.fast.durationIn(context),
    curve: KMotion.fast.curve,
  );
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    // L6 : seules les sections lisent le store. Chacune se reconstruit à
    // chaque notification tant qu'elle est affichée ; une section ou un
    // onglet Stats masqué diffère jusqu'à son retour à l'écran (voir
    // store_widget.dart).
    final pages = <Widget>[
      StoreBuilder(builder: (_) => StatsOverview(onSection: selectSection)),
      // ignore: prefer_const_constructors
      StoreBuilder(builder: (_) => StatsProgression()),
      // ignore: prefer_const_constructors
      StoreBuilder(builder: (_) => StatsPerformance()),
      // ignore: prefer_const_constructors
      StoreBuilder(builder: (_) => StatsHistory()),
    ];
    final help = KIconButton(
      icon: Icons.info_outline_rounded,
      tooltip: 'Comprendre les XP',
      onPressed: () => showStatsRules(context),
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.standalone) _RootHeader(action: help),
        _StatsTabs(controller: _tabs),
        Expanded(
          child: KContentTransition(
            key: const ValueKey('stats-transition'),
            position: _index,
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < pages.length; i++)
                  _visited.contains(i)
                      ? TickerMode(enabled: i == _index, child: pages[i])
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      backgroundColor: k.fond,
      appBar: widget.standalone
          ? KTopBar.sub(title: 'Stats', action: help)
          : null,
      body: SafeArea(
        top: !widget.standalone,
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: KSpacing.maxWidth),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// En-tête de l'onglet (page racine, C1) : grand titre (capitales selon
/// U3) et une phrase ; l'aide « Comprendre les XP » à droite.
class _RootHeader extends StatelessWidget {
  final Widget action;
  const _RootHeader({required this.action});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        KSpacing.page + KSpacing.s4,
        KSpacing.s8,
        KSpacing.s12,
        KSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: KFitTitle(
                    k.title('Stats'),
                    style: k.titleStyle(
                      KType.titreRacine.copyWith(color: k.texte),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: KSpacing.s8),
              action,
              // Logo à sa place historique (cahier §1 ; gestes du mode dev).
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  start: KSpacing.s4,
                  end: KSpacing.s8,
                ),
                child: HeaderLogo(),
              ),
            ],
          ),
          // La phrase prend toute la largeur (grand texte).
          Padding(
            padding: const EdgeInsetsDirectional.only(end: KSpacing.s8),
            child: Text(
              'Chaque effort construit la suite.',
              style: KType.corps.copyWith(color: k.texte2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rubriques : rangée défilante, rubrique active en pilule `pleine` (même
/// forme choisie ou non, seule la couleur change), cibles de 48 dp.
class _StatsTabs extends StatelessWidget {
  final TabController controller;
  const _StatsTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final k = KTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: KSpacing.s4),
      // Fondu sur les bords : on devine que la rangée défile (grand texte).
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          colors: [
            k.fond.withValues(alpha: 0),
            k.fond,
            k.fond,
            k.fond.withValues(alpha: 0),
          ],
          stops: [
            0,
            KSpacing.s12 / rect.width,
            1 - KSpacing.s12 / rect.width,
            1,
          ],
        ).createShader(rect),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: KSpacing.s12),
          labelPadding: EdgeInsets.zero,
          indicator: ShapeDecoration(color: k.pleine, shape: KRadius.pill),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(vertical: KSpacing.s4),
          dividerHeight: 0,
          labelColor: k.surPleine,
          unselectedLabelColor: k.texte2,
          labelStyle: KType.libelle,
          unselectedLabelStyle: KType.libelle,
          splashBorderRadius: const BorderRadius.all(
            Radius.circular(KSize.target / 2),
          ),
          tabs: [
            for (final entry in statsSectionLabels.asMap().entries)
              Tab(
                key: ValueKey('stats-section-${entry.key}'),
                height: KSize.target,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpacing.s8),
                  child: Text(entry.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
