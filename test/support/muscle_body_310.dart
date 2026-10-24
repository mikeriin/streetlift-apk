// Copie conforme du widget de carte musculaire de Kalis Track 3.1.0
// (lib/muscle_body.dart, commit 620752e), seulement renommée : référence du
// test « STATS identique à 3.1.0 » de la refonte muscles et animations.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/muscle_body.dart' show heat;

const _fileKeys310 = {
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
const _ratio310 = {'front': 281 / 760, 'back': 283 / 760};

// Seuls ces masques existent dans l'atlas : pas de biceps au dos, par exemple.
const _masks310 = {
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

class MuscleHeatmap310 extends StatelessWidget {
  final Map<String, double> data;
  final double height;
  final bool labels;
  final Color? tint;
  final bool glow;
  const MuscleHeatmap310({
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
            child: _View310(
              view: 'front',
              t: t,
              labels: labels,
              tint: tint,
              glow: glow,
            ),
          ),
          Expanded(
            child: _View310(
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

class _View310 extends StatelessWidget {
  final String view;
  final Map<String, double> t;
  final bool labels;
  final Color? tint;
  final bool glow;
  const _View310({
    required this.view,
    required this.t,
    required this.labels,
    this.tint,
    required this.glow,
  });

  @override
  Widget build(BuildContext context) {
    final entries = t.entries
        .where((e) => e.value > 0.02 && _masks310[view]!.contains(e.key))
        .toList();
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _ratio310[view]!,
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
                            'assets/muscles/${view}_${_fileKeys310[e.key]}.png',
                            fit: BoxFit.fill,
                            color: tint == null
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
                      'assets/muscles/${view}_${_fileKeys310[e.key]}.png',
                      fit: BoxFit.fill,
                      color: tint == null
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
