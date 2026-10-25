/// Fiches des remplaçants de Koach 1.0.9 (lot KM7, `koachRemplacants` de
/// `package:kalis_adapt/koach.dart`) : ce que la règle des remplaçants lit
/// d'un exercice du catalogue, au format de
/// `reference/donnees/catalogue_infos.json.gz` (champs du même nom, mêmes
/// valeurs : `kmExerciseInfo` de kalis_bench, testé).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show coachPainStopHits;

import 'book.dart';

/// Fiche de remplacement de l'exercice [info].
Map<String, Object?> koachInfoRemplacement(ExerciseInfo info) {
  final e = info.exercise;
  return <String, Object?>{
    'id': e.id,
    'name': e.name,
    'mode': info.mode?.name,
    'fraction': info.fraction,
    'groups': <int>[for (final g in info.groups) g.index],
    'groupWeights': info.groupWeights,
    'difficulty': e.difficulty,
    'assisted': e.assisted,
    'loadType': e.loadType.name,
    'pattern': e.pattern.name,
    'family': e.family.name,
    'unit': e.unit.name,
    'zoneLevels': <String, double>{
      for (final z in BodyZone.values) z.code: info.zoneLevel(z),
    },
    'painStopHits': <String>[
      for (final z in BodyZone.values)
        if (coachPainStopHits(e, z)) z.code,
    ],
    'gridStep': info.grid.step,
    'gridMinimum': info.grid.minimum,
    'gridDumbbell': info.grid.dumbbellRule,
    'slotKind': info.traits.kind.name,
    'level': e.level.index,
    'rootId': e.rootId,
    'depth': e.depth,
    'equipment': <String>[...e.equipment],
    'places': <String>[for (final p in e.places) p.code],
    'contractionMode': e.contractionMode.name,
  };
}

/// Fiches de remplacement de tous les exercices du catalogue suivis par le
/// moteur (grilles du profil [profile] s'il est donné, sinon par défaut).
List<Map<String, Object?>> koachInfosRemplacement(
  Catalog catalog, [
  AthleteProfile? profile,
]) {
  final book = ExerciseBook(catalog, profile);
  return <Map<String, Object?>>[
    for (final e in catalog.exercises)
      if (book.find(e.id) case final info?) koachInfoRemplacement(info),
  ];
}
