import 'package:flutter/material.dart';
import 'stats_screen.dart';

/// Ancien point d'entrée conservé pour compatibilité ; le suivi vit dans STATS.
class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});
  @override
  Widget build(BuildContext context) => const StatsScreen(standalone: true);
}
