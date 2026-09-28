// M4 (mannequin 3D) : résumé hebdomadaire de STATS sur le mannequin.
//
// Les chiffres ne changent pas : séries pondérées par groupe de
// `AppStore.weeklyMuscles` (inchangé), ramenées au maximum de la semaine
// et filtrées sous 2 % exactement comme la carte 2D historique
// (`heatmapIntensities`, `kHeatmapMinIntensity`). Chaque muscle d'un groupe
// prend l'intensité de son groupe (rampe et halo du mannequin). Vues Face /
// Dos (bascule) et rotation horizontale au doigt (la page défile au
// glissement vertical). Rendu à la demande, isolé par une frontière de
// dessin : le défilement de STATS ne redessine pas la scène (mesure dans
// integration_test/stats_semaine_test.dart). Sans Flutter GPU : carte 2D
// historique, identique à 5.2.0.
import 'dart:async';

import 'package:flutter/material.dart';

import 'engine3d.dart';
import 'mannequin_3d.dart';
import 'muscle_body.dart';

/// Intensité (0-1) par région du mannequin pour les séries de la semaine par
/// groupe : même normalisation et même seuil que la carte 2D. Les volumes
/// sombres des mains et des pieds (groupes avant-bras et mollets) restent
/// sombres : le résumé colore des muscles, pas des extrémités.
Map<String, double> weeklyRegionIntensities(
  MannequinMap map,
  Map<String, double> weekly,
) {
  final t = heatmapIntensities(weekly);
  return {
    for (final r in map.regions)
      if (r.couche != 'volume' && (t[r.groupe] ?? 0) > kHeatmapMinIntensity)
        r.id: t[r.groupe]!,
  };
}

/// Mannequin 3D des groupes travaillés dans la semaine (STATS ›
/// Performances › Muscles sollicités).
class WeeklyMannequin extends StatefulWidget {
  /// Séries pondérées par groupe (`AppStore.weeklyMuscles`).
  final Map<String, double> data;
  final double height;

  const WeeklyMannequin({super.key, required this.data, this.height = 330});

  /// Hauteur de la carte 2D de repli (celle de 5.2.0).
  static const fallbackHeight = 220.0;

  @override
  State<WeeklyMannequin> createState() => WeeklyMannequinState();
}

class WeeklyMannequinState extends State<WeeklyMannequin> {
  MannequinMap? _map = MannequinMap.loaded;

  /// Intensités par région passées au mannequin (tests d'intégration).
  Map<String, double> get intensities =>
      _map == null ? const {} : weeklyRegionIntensities(_map!, widget.data);

  @override
  void initState() {
    super.initState();
    // Carte des régions chargée seulement si le mannequin 3D peut
    // s'afficher (sinon la carte 2D n'en a pas besoin).
    if (_map == null) unawaited(_loadMap());
  }

  Future<void> _loadMap() async {
    try {
      if (!(await engine3DSupport()).compatible) return;
      final map = await MannequinMap.load();
      if (mounted) setState(() => _map = map);
    } catch (_) {
      // Modèle illisible : le mannequin passe lui-même en repli 2D.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = heatmapIntensities(widget.data);
    final ranked =
        t.entries.where((e) => e.value > kHeatmapMinIntensity).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final names = [
      for (final e in ranked) '${e.key[0].toUpperCase()}${e.key.substring(1)}',
    ];
    return RepaintBoundary(
      child: Mannequin3D(
        key: const ValueKey('stats-mannequin'),
        intensities: intensities,
        view: MannequinView.face,
        views: const [MannequinView.face, MannequinView.dos],
        height: widget.height,
        horizontalDragOnly: true,
        semanticLabel: names.isEmpty
            ? 'Mannequin anatomique en 3D, aucun muscle travaillé cette semaine'
            : 'Mannequin anatomique en 3D, muscles de la semaine : '
                  '${names.join(', ')}',
        fallback: MuscleHeatmap(
          data: widget.data,
          height: WeeklyMannequin.fallbackHeight,
        ),
      ),
    );
  }
}
