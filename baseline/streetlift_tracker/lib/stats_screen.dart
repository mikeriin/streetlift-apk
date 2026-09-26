import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'store.dart';
import 'ui.dart';
import 'motion.dart';
import 'stats_navigation.dart';
import 'stats_overview.dart';
import 'stats_progression.dart';
import 'stats_performance.dart';
import 'stats_history.dart';

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
      animationDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
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
    duration:
        MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
  );
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final pages = <Widget>[
        StatsOverview(onSection: selectSection),
        // ignore: prefer_const_constructors
        StatsProgression(),
        // ignore: prefer_const_constructors
        StatsPerformance(),
        // ignore: prefer_const_constructors
        StatsHistory(),
      ];
      final help = IconButton(
        tooltip: 'Comprendre les XP',
        icon: const Icon(Icons.info_outline_rounded),
        onPressed: () => showStatsRules(context),
      );
      return KScreen(
        appBar:
            widget.standalone
                ? AppBar(title: const Text('STATS'), actions: [help])
                : KTopBar(
                  leading: Text(
                    'STATS',
                    style: TextStyle(
                      color: SL.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  actions: [help],
                ),
        body: Column(
          children: [
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: [
                for (final entry
                    in [
                      'Aperçu',
                      'Parcours',
                      'Performances',
                      'Historique',
                    ].asMap().entries)
                  Tab(
                    key: ValueKey('stats-section-${entry.key}'),
                    text: entry.value,
                  ),
              ],
            ),
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
        ),
      );
    },
  );
}
