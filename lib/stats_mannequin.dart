// Muscles ciblés par des exercices : semaine de STATS, séance du jour
// (accueil), aperçu d'un WOD.
//
// M4 → M56 correction 3 (5.5.3) : la **zone ciblée** plutôt que le groupe
// entier. Quand un exercice a une fiche du pack, ce sont ses muscles
// principaux (1) et secondaires (0,6) qui comptent, pondérés par ses séries
// ; un exercice sans fiche compte pour ses groupes (`groupe:<g>`).
//
// M8 (5.9.0, changement de plan du propriétaire du 30/09/2026) : la 3D est
// réservée à la démonstration des exercices et à Koach. Ces résumés
// s'affichent sur la carte 2D des 15 groupes (muscle_map_2d.dart) : groupes
// travaillés dans la couleur dominante (intensité ramenée au plus fort,
// seuil de 2 %), les autres en gris ; fond transparent (couleur du
// support).
import 'dart:async';

import 'package:flutter/material.dart';

import 'content_pack.dart';
import 'muscle_map_2d.dart';
import 'store.dart';

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

/// Intensité par groupe de la carte des exercices [names] ; [groups] (les
/// mêmes par groupe de l'application) sert tant que les fiches ne sont pas
/// lues.
Map<String, double> targetedMapIntensities(
  ContentLibrary? lib,
  Map<String, double> names,
  Map<String, double> groups,
) {
  if (lib == null || names.isEmpty) {
    return mapIntensitiesFromWeights({
      for (final e in groups.entries) 'groupe:${e.key}': e.value,
    });
  }
  return mapIntensitiesFromWeights(targetedMuscles(lib, names));
}

/// Carte 2D des muscles ciblés par des exercices (M8) : semaine de STATS
/// (séries validées), séance du jour, aperçu d'un WOD. [names] : exercices
/// (nom → poids) ; [groups] : les mêmes par groupe (en attendant les
/// fiches).
class TargetedMuscleMap extends StatefulWidget {
  final Map<String, double> names;
  final Map<String, double> groups;
  final double height;
  final List<MapView> views;
  final bool viewLabels;

  /// Support de la couleur dominante (carte du jour) : carte teintée.
  final Color? tint;
  final String subject;

  const TargetedMuscleMap({
    super.key,
    required this.names,
    required this.groups,
    this.height = 240,
    this.views = MapView.values,
    this.viewLabels = true,
    this.tint,
    this.subject = 'muscles ciblés',
  });

  @override
  State<TargetedMuscleMap> createState() => TargetedMuscleMapState();
}

class TargetedMuscleMapState extends State<TargetedMuscleMap> {
  ContentLibrary? _lib = ContentLibrary.loaded;

  /// Intensités par groupe de la carte (contrôles).
  Map<String, double> get intensities =>
      targetedMapIntensities(_lib, widget.names, widget.groups);

  @override
  void initState() {
    super.initState();
    if (_lib == null) unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final lib = await ContentLibrary.load();
      if (mounted) setState(() => _lib = lib);
    } catch (_) {
      // Fiches illisibles : la carte reste sur les groupes.
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: MuscleMap2D(
      intensities: intensities,
      views: widget.views,
      height: widget.height,
      viewLabels: widget.viewLabels,
      tint: widget.tint,
      semanticLabel: 'Carte des groupes musculaires, ${widget.subject}',
    ),
  );
}
