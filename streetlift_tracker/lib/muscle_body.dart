// Carte des groupes musculaires (STATS, accueil, WOD) — L9b : dessinée avec
// l'atlas du pack de contenu (lib/atlas_data.dart) à la place des calques PNG.
// Données inchangées : agrégation par les 11 groupes de l'application, même
// rampe d'intensité ; chaque muscle de l'atlas est rattaché à son groupe.
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas.dart';
import 'atlas_data.dart';

/// Rampe d'intensité de la charte : bordeaux (léger) → rouge (intense).
/// En sombre, le haut de la rampe prend la teinte d'accent pour rester visible.
Color heat(double t) {
  final v = t.clamp(0.0, 1.0);
  if (v <= 0) return SL.faint;
  // Échelle de données : rouge historique, indépendant de la dominante.
  final top = SL.dark ? KPalette.lightRed : KPalette.actionRed;
  return Color.lerp(KPalette.burgundy, top, .15 + .85 * v)!;
}

/// Groupes réellement dessinés dans chaque vue de l'atlas.
final muscleMasks = {
  'front': atlasGroupsIn('face'),
  'back': atlasGroupsIn('dos'),
};

const _atlasView = {'front': 'face', 'back': 'dos'};

/// Remplissages de l'atlas pour une intensité par groupe (0-1).
Map<String, List<AtlasFill>> heatAtlasFills(
  Map<String, double> t, {
  Color? tint,
  bool glow = false,
}) {
  final out = <String, List<AtlasFill>>{};
  for (final e in atlasMuscles.entries) {
    final v = t[e.value.groupe] ?? 0;
    if (v <= 0.02) continue;
    final color =
        tint == null ? heat(v) : Color.lerp(KPalette.gray, tint, .45 + .55 * v)!;
    out[e.key] = [
      if (glow && v > 0.35) AtlasFill(color, opacity: .45 * v, blur: true),
      AtlasFill(color),
    ];
  }
  return out;
}

class MuscleHeatmap extends StatelessWidget {
  final Map<String, double> data;
  final double height;
  final bool labels;
  final Color? tint;
  final bool glow;
  const MuscleHeatmap({
    super.key,
    required this.data,
    this.height = 300,
    this.labels = true,
    this.tint,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final max = data.values.fold<double>(0, (a, b) => b > a ? b : a);
    final t = {
      for (final e in data.entries) e.key: max == 0 ? 0.0 : e.value / max,
    };
    final fills = heatAtlasFills(t, tint: tint, glow: glow);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: _View(view: 'front', fills: fills, labels: labels)),
          Expanded(child: _View(view: 'back', fills: fills, labels: labels)),
        ],
      ),
    );
  }
}

class _View extends StatelessWidget {
  final String view;
  final Map<String, List<AtlasFill>> fills;
  final bool labels;
  const _View({required this.view, required this.fills, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: atlasViewWidth / atlasViewHeight,
              child: CustomPaint(
                size: Size.infinite,
                painter: AtlasPainter(
                  view: _atlasView[view]!,
                  fills: fills,
                  body: KPalette.gray,
                  marks: SL.text,
                ),
              ),
            ),
          ),
        ),
        if (labels)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              view == 'front' ? 'FACE' : 'DOS',
              style: TextStyle(
                color: SL.dim,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

/// Légende : groupes classés, puce colorée selon l'intensité relative.
class MuscleLegend extends StatelessWidget {
  final Map<String, double> data;
  const MuscleLegend({super.key, required this.data});
  @override
  Widget build(BuildContext context) {
    final ranked =
        data.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) return const SizedBox.shrink();
    final max = ranked.first.value;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in ranked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: SL.faint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: heat(e.value / max),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: SL.text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
