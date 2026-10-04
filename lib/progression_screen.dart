import 'package:flutter/material.dart';
import 'stats_navigation.dart';
import 'stats_screen.dart';

void openProgression(BuildContext context) {
  if (StatsNavigation.open(context, StatsSection.journey)) return;
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const ProgressionScreen()));
}

/// Compatibilité des raccourcis : la même interface STATS, sans ancien écran isolé.
class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const StatsScreen(initialSection: StatsSection.journey, standalone: true);
}
