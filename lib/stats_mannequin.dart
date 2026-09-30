// M4 (mannequin 3D) : résumé hebdomadaire de STATS sur le mannequin.
//
// Les chiffres ne changent pas : séries pondérées par groupe de
// `AppStore.weeklyMuscles` (inchangé), ramenées au maximum de la semaine
// et filtrées sous 2 % exactement comme la carte 2D historique
// (`heatmapIntensities`, `kHeatmapMinIntensity`). Vues Face / Dos (bascule).
// Rendu à la demande, isolé par une frontière de dessin : le défilement de
// STATS ne redessine pas la scène (mesure dans
// integration_test/stats_semaine_test.dart). Sans Flutter GPU : carte 2D
// historique, identique à 5.2.0.
//
// 5.5.3 (M56 correction 3, décision du propriétaire du 29/09/2026) : la
// **zone ciblée** plutôt que le groupe entier. Quand un exercice a une fiche
// du pack, ce sont ses muscles principaux (1) et secondaires (0,6) qui
// s'allument, pondérés par ses séries ; un exercice sans fiche allume ses
// groupes comme avant. Même mannequin (`TargetedMannequin`) pour la séance
// du jour (accueil), l'aperçu d'un WOD et la semaine de STATS ; la carte 2D
// reste le repli sans Flutter GPU.
import 'dart:async';

import 'package:flutter/material.dart';

import 'content_pack.dart';
import 'engine3d.dart';
import 'mannequin_3d.dart';
import 'muscle_body.dart';
import 'store.dart';

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

/// Poids par muscle du pack (ou par groupe, clé `groupe:<g>`, pour un
/// exercice sans fiche) des exercices [names] (nom → poids : séries, tours,
/// 1 pour une séance prévue). Principaux 1, secondaires 0,6.
Map<String, double> targetedMuscles(
  ContentLibrary lib,
  Map<String, double> names,
) {
  final out = <String, double>{};
  void add(String key, double w) => out[key] = (out[key] ?? 0) + w;
  names.forEach((name, w) {
    final id = store.exerciseIdFor(name);
    final d = id == null ? null : lib.detail(id);
    if (d != null && (d.primaires.isNotEmpty || d.secondaires.isNotEmpty)) {
      for (final m in d.primaires) {
        add(m, w);
      }
      for (final m in d.secondaires) {
        add(m, .6 * w);
      }
    } else {
      final gs = store.groupsFor(name);
      for (var i = 0; i < gs.length; i++) {
        add('groupe:${gs[i]}', w * (i == 0 ? 1.0 : .6));
      }
    }
  });
  return out;
}

/// Intensité (0-1) par région pour des poids par muscle du pack ou par
/// groupe ([targetedMuscles]) : ramenés au maximum, seuil de 2 % ; une
/// région prend le plus fort de ses muscles ; mains et pieds restent
/// sombres.
Map<String, double> targetedRegionIntensities(
  MannequinMap map,
  Map<String, double> targets,
) {
  final t = heatmapIntensities(targets);
  final out = <String, double>{};
  for (final r in map.regions) {
    if (r.couche == 'volume') continue;
    var v = t['groupe:${r.groupe}'] ?? 0;
    for (final p in r.pack) {
      final w = t[p] ?? 0;
      if (w > v) v = w;
    }
    if (v > kHeatmapMinIntensity) out[r.id] = v;
  }
  return out;
}

/// Mannequin 3D des muscles ciblés par des exercices : semaine de STATS
/// (séries validées), séance du jour, aperçu d'un WOD. [names] : exercices
/// (nom → poids) ; [groups] : les mêmes par groupe (carte 2D de repli, et
/// mannequin tant que les fiches ne sont pas lues).
class TargetedMannequin extends StatefulWidget {
  final Map<String, double> names;
  final Map<String, double> groups;
  final double height;

  /// Vue de départ et boutons de vue (aucun bouton en carte compacte).
  final MannequinView view;
  final bool viewButtons;
  final double? fallbackHeight;
  final Color? fallbackTint;
  final bool fallbackGlow;
  final String subject;

  /// 5.5.4 : couleur du support (fond de la scène sans démarcation).
  final Color? background;

  /// M6b : couleur du halo sur un support de la couleur dominante.
  final Color? haloColor;

  const TargetedMannequin({
    super.key,
    required this.names,
    required this.groups,
    this.height = 330,
    this.view = MannequinView.face,
    this.viewButtons = true,
    this.fallbackHeight,
    this.fallbackTint,
    this.fallbackGlow = true,
    this.subject = 'muscles ciblés',
    this.background,
    this.haloColor,
  });

  @override
  State<TargetedMannequin> createState() => TargetedMannequinState();
}

class TargetedMannequinState extends State<TargetedMannequin> {
  MannequinMap? _map = MannequinMap.loaded;
  ContentLibrary? _lib = ContentLibrary.loaded;

  /// Intensités par région passées au mannequin (tests d'intégration).
  Map<String, double> get intensities {
    final map = _map;
    if (map == null) return const {};
    final lib = _lib;
    if (lib == null) return weeklyRegionIntensities(map, widget.groups);
    return targetedRegionIntensities(map, targetedMuscles(lib, widget.names));
  }

  @override
  void initState() {
    super.initState();
    // Carte des régions et fiches chargées seulement si le mannequin 3D
    // peut s'afficher (sinon la carte 2D n'en a pas besoin).
    if (_map == null || _lib == null) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      if (!(await engine3DSupport()).compatible) return;
      final results = await Future.wait<Object>([
        MannequinMap.load(),
        ContentLibrary.load(),
      ]);
      if (!mounted) return;
      setState(() {
        _map = results[0] as MannequinMap;
        _lib = results[1] as ContentLibrary;
      });
    } catch (_) {
      // Modèle illisible : le mannequin passe lui-même en repli 2D.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = heatmapIntensities(widget.groups);
    final ranked =
        t.entries.where((e) => e.value > kHeatmapMinIntensity).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final names = [
      for (final e in ranked) '${e.key[0].toUpperCase()}${e.key.substring(1)}',
    ];
    return RepaintBoundary(
      child: Mannequin3D(
        intensities: intensities,
        view: widget.view,
        views: const [MannequinView.face, MannequinView.dos],
        viewButtons: widget.viewButtons,
        interactive: widget.viewButtons,
        background: widget.background,
        haloColor: widget.haloColor,
        height: widget.height,
        semanticLabel: names.isEmpty
            ? 'Mannequin anatomique en 3D, aucun muscle sollicité'
            : 'Mannequin anatomique en 3D, ${widget.subject} : '
                  '${names.join(', ')}',
        fallback: MuscleHeatmap(
          data: widget.groups,
          height: widget.fallbackHeight ?? widget.height,
          labels: widget.viewButtons,
          tint: widget.fallbackTint,
          glow: widget.fallbackGlow,
        ),
      ),
    );
  }
}

/// Mannequin 3D des groupes travaillés dans la semaine (STATS ›
/// Performances › Muscles sollicités) : [TargetedMannequin] de la semaine.
class WeeklyMannequin extends TargetedMannequin {
  /// [data] : séries pondérées par groupe (`AppStore.weeklyMuscles`,
  /// exposé par [groups]) ; [names] : exercices de la semaine
  /// (`AppStore.weeklyNames`, 5.5.3).
  const WeeklyMannequin({
    super.key,
    required Map<String, double> data,
    super.names = const {},
    super.height,
    super.background,
  }) : super(
         groups: data,
         fallbackHeight: fallback2dHeight,
         subject: 'muscles de la semaine',
       );

  /// Hauteur de la carte 2D de repli (celle de 5.2.0).
  static const fallback2dHeight = 220.0;
}

typedef WeeklyMannequinState = TargetedMannequinState;
