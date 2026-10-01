// Carte des groupes musculaires — illustrations anatomiques historiques
// (face / dos de 3.1.0, profil ajouté par la refonte muscles et animations) :
// image de base grise + un calque de teinte par groupe (assets/muscles/*.png),
// coloré selon l'intensité avec un halo doux. STATS et accueil gardent
// le rendu 3.1.0 (face + dos) ; la fiche exercice ajoute le profil.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'atlas.dart';
import 'atlas_data.dart';
import 'muscle_map_2d.dart' show mapHeat;

/// Rampe d'intensité des muscles : principale (léger) → vive (intense).
/// 5.5.2 (décision du propriétaire, 29/09/2026) : la rampe suit la couleur
/// dominante choisie dans les réglages (avant : rouge historique fixe). En
/// sombre, le haut de la rampe prend la teinte claire pour rester visible.
Color heat(double t) {
  final v = t.clamp(0.0, 1.0);
  if (v <= 0) return SL.faint;
  final a = SL.accentSpec;
  final top = SL.dark ? a.bright : (a.vividLight ?? a.vivid);
  return Color.lerp(a.principal, top, .15 + .85 * v)!;
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
const _ratio = {'front': 281 / 760, 'back': 283 / 760, 'profile': 142 / 760};

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
  // profil (personnage tourné vers la gauche) : les 11 groupes ont un calque
  'profile': {
    'pectoraux',
    'épaules',
    'biceps',
    'triceps',
    'avant-bras',
    'gainage',
    'dos',
    'quadriceps',
    'ischios',
    'fessiers',
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

/// Remplissages de l'atlas vectoriel du pack (L9b) pour une intensité par
/// groupe (0-1) : conservé pour l'atlas vectoriel ([AtlasPainter]), même
/// rampe que les calques anatomiques.
Map<String, List<AtlasFill>> heatAtlasFills(
  Map<String, double> t, {
  Color? tint,
  bool glow = false,
}) {
  final out = <String, List<AtlasFill>>{};
  for (final e in atlasMuscles.entries) {
    final v = t[e.value.groupe] ?? 0;
    if (v <= 0.02) continue;
    final color = tint == null
        ? heat(v)
        : Color.lerp(KPalette.gray, tint, .45 + .55 * v)!;
    out[e.key] = [
      if (glow && v > 0.35) AtlasFill(color, opacity: .45 * v, blur: true),
      AtlasFill(color),
    ];
  }
  return out;
}

/// Seuil d'affichage de la carte : un groupe sous 2 % du maximum n'est pas
/// coloré (carte 2D historique et, depuis M4, mannequin 3D de STATS).
const kHeatmapMinIntensity = .02;

/// Intensités affichées par la carte des groupes (0-1) : valeurs ramenées au
/// maximum de la semaine ([normalize], STATS) ou lues telles quelles. Même
/// calcul pour la carte 2D et le mannequin 3D de STATS (M4).
Map<String, double> heatmapIntensities(
  Map<String, double> data, {
  bool normalize = true,
}) {
  final max = normalize
      ? data.values.fold<double>(0, (a, b) => b > a ? b : a)
      : 1.0;
  return {for (final e in data.entries) e.key: max == 0 ? 0.0 : e.value / max};
}

class MuscleHeatmap extends StatelessWidget {
  final Map<String, double> data;
  final double height;
  final bool labels;
  final Color? tint;
  final bool glow;

  /// Vues dessinées, de gauche à droite : 'front', 'back', 'profile'.
  final List<String> views;

  /// Intensités ramenées au maximum (STATS) ; sinon lues telles quelles (0-1).
  final bool normalize;
  const MuscleHeatmap({
    super.key,
    required this.data,
    this.height = 300,
    this.labels = true,
    this.tint,
    this.glow = false,
    this.views = const ['front', 'back'],
    this.normalize = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = heatmapIntensities(data, normalize: normalize);
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final view in views)
            Expanded(
              // Face + dos : colonnes égales (rendu 3.1.0) ; avec le profil,
              // largeur proportionnelle à chaque illustration.
              flex: views.contains('profile')
                  ? (_ratio[view]! * 1000).round()
                  : 1,
              child: _View(
                view: view,
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
    final entries = t.entries
        .where(
          (e) =>
              e.value > kHeatmapMinIntensity &&
              muscleMasks[view]!.contains(e.key),
        )
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
                      'assets/muscles/${view}_${_fileKeys[e.key]}.png',
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
              switch (view) {
                'front' => 'FACE',
                'back' => 'DOS',
                _ => 'PROFIL',
              },
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

  /// M4 (STATS) : valeur de chaque groupe écrite après son nom
  /// (« Dos · 12,6 ») ; la couleur n'est jamais la seule information.
  final bool values;
  const MuscleLegend({super.key, required this.data, this.values = false});

  /// Valeur lisible : entier sans décimale, sinon une décimale à la française.
  static String format(double v) {
    final r = (v * 10).round() / 10;
    return r == r.roundToDouble()
        ? r.round().toString()
        : r.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final ranked = data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty) return const SizedBox.shrink();
    final max = ranked.first.value;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final e in ranked)
          Container(
            key: ValueKey('muscle-legend-${e.key}'),
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
                    // M8 : couleurs de la carte 2D des groupes.
                    color: mapHeat(
                      e.value / max,
                      Theme.of(context).brightness == Brightness.dark,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key[0].toUpperCase()}${e.key.substring(1)}'
                  '${values ? ' · ${format(e.value)}' : ''}',
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
