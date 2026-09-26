import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ui.dart';

String statsNumber(num value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
String statsDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

class StatsBar extends StatelessWidget {
  final double value;
  final String label;
  final String? description;
  final Color? color;
  const StatsBar({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.color,
  });
  @override
  Widget build(BuildContext context) => KProgressBar(
    value: value,
    height: 5,
    color: color,
    track: color == null ? SL.progressTrack : color!.withValues(alpha: .18),
    semanticsLabel: label,
    semanticsValue: description ?? '${(value.clamp(0.0, 1.0) * 100).round()} %',
  );
}

class StatsMetric extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const StatsMetric(this.value, this.label, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => KCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: SL.text,
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Icon(icon, color: SL.accent, size: 20),
          ],
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: SL.dim, fontSize: 12, height: 1.3)),
      ],
    ),
  );
}

class StatsGrid extends StatelessWidget {
  final List<Widget> children;
  const StatsGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 21;
      final count = large || bounds.maxWidth < 240 ? 1 : 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final child in children)
            SizedBox(
              width: (bounds.maxWidth - 10 * (count - 1)) / count,
              child: child,
            ),
        ],
      );
    },
  );
}

Future<void> statsSheet(
  BuildContext context,
  String title,
  List<Widget> children,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder:
      (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        minChildSize: .35,
        builder:
            (context, controller) => KList(
              controller: controller,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                ...children,
              ],
            ),
      ),
);
