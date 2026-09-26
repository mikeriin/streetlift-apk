// Carte des groupes musculaires — illustration anatomique (face / dos) :
// image de base grise + un calque de teinte par groupe (assets/muscles/*.png),
// coloré selon l'intensité avec un halo doux.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Rampe d'intensité de la charte : bordeaux (léger) → rouge (intense).
/// En sombre, le haut de la rampe prend la teinte d'accent pour rester visible.
Color heat(double t) {
  final v = t.clamp(0.0, 1.0);
  if (v <= 0) return SL.faint;
  // Échelle de données : rouge historique, indépendant de la dominante.
  final top = SL.dark ? KPalette.lightRed : KPalette.actionRed;
  return Color.lerp(KPalette.burgundy, top, .15 + .85 * v)!;
}

const _fileKeys = {
  'pectoraux': 'pectoraux',
  'épaules': 'epaules',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'avant-bras': 'avant_bras',
  'gainage': 'gainage',
  'dos': 'dos',
  'quadriceps': 'quadriceps',
  'ischios': 'ischios',
  'fessiers': 'fessiers',
  'mollets': 'mollets',
};
const _ratio = {'front': 281 / 760, 'back': 283 / 760};

// Seuls ces masques existent dans l'atlas : pas de biceps au dos, par exemple.
const muscleMasks = {
  'front': {
    'pectoraux',
    'épaules',
    'biceps',
    'avant-bras',
    'gainage',
    'dos',
    'quadriceps',
    'mollets',
  },
  'back': {
    'épaules',
    'triceps',
    'avant-bras',
    'dos',
    'ischios',
    'fessiers',
    'mollets',
  },
};

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
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _View(
              view: 'front',
              t: t,
              labels: labels,
              tint: tint,
              glow: glow,
            ),
          ),
          Expanded(
            child: _View(
              view: 'back',
              t: t,
              labels: labels,
              tint: tint,
              glow: glow,
            ),
          ),
        ],
      ),
    );
  }
}

class _View extends StatelessWidget {
  final String view;
  final Map<String, double> t;
  final bool labels;
  final Color? tint;
  final bool glow;
  const _View({
    required this.view,
    required this.t,
    required this.labels,
    this.tint,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final entries =
        t.entries
            .where((e) => e.value > 0.02 && muscleMasks[view]!.contains(e.key))
            .toList();
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _ratio[view]!,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/muscles/${view}_base.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                  ),
                  // halo sous les groupes chauds
                  for (final e in entries)
                    if (glow && e.value > 0.35)
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                        child: Opacity(
                          opacity: 0.45 * e.value,
                          child: Image.asset(
                            'assets/muscles/${view}_${_fileKeys[e.key]}.png',
                            fit: BoxFit.fill,
                            color:
                                tint == null
                                    ? heat(e.value)
                                    : Color.lerp(
                                      KPalette.gray,
                                      tint,
                                      .45 + .55 * e.value,
                                    ),
                            colorBlendMode: BlendMode.modulate,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                  // calques teintés (le modelé de l'illustration est conservé par modulation)
                  for (final e in entries)
                    Image.asset(
                      'assets/muscles/${view}_${_fileKeys[e.key]}.png',
                      fit: BoxFit.fill,
                      color:
                          tint == null
                              ? heat(e.value)
                              : Color.lerp(
                                KPalette.gray,
                                tint,
                                .45 + .55 * e.value,
                              ),
                      colorBlendMode: BlendMode.modulate,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
                ],
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
