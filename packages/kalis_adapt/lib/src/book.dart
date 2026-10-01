/// Lecture du catalogue par le moteur dynamique : comment la capacité d'un
/// exercice se mesure, quels groupes musculaires il charge, quelles zones
/// du corps il sollicite.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart'
    show CatalogTraits, ExerciseTraits, MuscleGroup;

import 'filter.dart';
import 'grid.dart';

/// Ce que le moteur sait d'un exercice du catalogue.
final class ExerciseInfo {
  ExerciseInfo._({
    required this.exercise,
    required this.traits,
    required this.mode,
    required this.fraction,
    required this.grid,
    required this.lowerBody,
    required this.groups,
    required this.groupWeights,
  });

  /// Exercice du catalogue.
  final CatalogExercise exercise;

  /// Traits de `kalis_plan` (nature, crédits par groupe musculaire).
  final ExerciseTraits traits;

  /// Mode de capacité, ou `null` si l'exercice n'est pas modélisé (cardio,
  /// mobilité, conditionnement, distance, calories).
  final CapacityMode? mode;

  /// Fraction du poids du corps portée (0 pour une charge externe seule).
  final double fraction;

  /// Grille de charge du matériel.
  final LoadGrid grid;

  /// Polyarticulaire du bas du corps (courbe plus endurante a priori).
  final bool lowerBody;

  /// Groupes musculaires chargés (principaux et secondaires).
  final List<MuscleGroup> groups;

  /// Poids de chaque groupe : 1 principal, 0,5 secondaire.
  final List<double> groupWeights;

  /// Identifiant de l'exercice.
  String get id => exercise.id;

  /// Charge totale d'une charge externe [externalKg] pour un poids de corps
  /// [bodyWeightKg].
  double totalLoad(double externalKg, double bodyWeightKg) =>
      externalKg + fraction * bodyWeightKg;

  /// Niveau de sollicitation de la zone [zone] : 1 contrainte forte ou
  /// travail direct, 0,5 contrainte moyenne ou travail indirect, 0 sinon
  /// (même règle que `kalis_plan`).
  double zoneLevel(BodyZone zone) {
    var level = 0.0;
    final joint = zone.joint;
    if (joint != null) {
      final stress = exercise.stressOn(joint);
      level = stress == JointStress.high
          ? 1.0
          : (stress == JointStress.moderate ? 0.5 : 0.0);
    }
    for (final g in zoneGroups[zone] ?? const <MuscleGroup>[]) {
      final credit = traits.groupCredits[g.index] / 2;
      if (credit > level) {
        level = credit;
      }
    }
    return level;
  }

  /// Vrai si une douleur d'intensité [intensity] dans la zone [zone] écarte
  /// l'exercice (seuils [hard] et [severe] de `kalis_plan`).
  bool excludedByPain(
    BodyZone zone,
    int intensity, {
    required int hard,
    required int severe,
  }) {
    final level = zoneLevel(zone);
    return (level >= 1 && intensity >= hard) ||
        (level >= 0.5 && intensity >= severe);
  }
}

/// Groupes musculaires d'une zone sans articulation suivie (table de
/// `kalis_plan`).
const Map<BodyZone, List<MuscleGroup>> zoneGroups =
    <BodyZone, List<MuscleGroup>>{
      BodyZone.upperBack: <MuscleGroup>[
        MuscleGroup.upperBack,
        MuscleGroup.lats,
      ],
      BodyZone.chest: <MuscleGroup>[MuscleGroup.chest],
      BodyZone.abdomen: <MuscleGroup>[MuscleGroup.abs],
      BodyZone.thigh: <MuscleGroup>[
        MuscleGroup.quads,
        MuscleGroup.hamstrings,
        MuscleGroup.adductors,
      ],
      BodyZone.lowerLeg: <MuscleGroup>[MuscleGroup.calves],
      BodyZone.neck: <MuscleGroup>[MuscleGroup.upperTraps],
    };

/// Informations par exercice pour un catalogue et un profil.
final class ExerciseBook {
  /// Livre du catalogue [catalog] pour le profil [profile].
  ExerciseBook(this.catalog, this.profile)
    : _traits = CatalogTraits.of(catalog);

  /// Catalogue.
  final Catalog catalog;

  /// Profil (incréments de charge).
  final AthleteProfile? profile;

  final CatalogTraits _traits;
  final Map<String, ExerciseInfo?> _cache = <String, ExerciseInfo?>{};

  /// Informations de l'exercice [id], ou `null` s'il est inconnu du
  /// catalogue.
  ExerciseInfo? find(String id) {
    if (_cache.containsKey(id)) {
      return _cache[id];
    }
    final e = catalog.find(id);
    final t = _traits.find(id);
    final info = e == null || t == null ? null : _build(e, t);
    _cache[id] = info;
    return info;
  }

  ExerciseInfo _build(CatalogExercise e, ExerciseTraits t) {
    final groups = <MuscleGroup>[];
    final weights = <double>[];
    for (final g in MuscleGroup.values) {
      final credit = t.groupCredits[g.index];
      if (credit > 0) {
        groups.add(g);
        weights.add(credit / 2);
      }
    }
    return ExerciseInfo._(
      exercise: e,
      traits: t,
      mode: modeOf(e),
      fraction: e.bodyweightFraction?.value ?? 0,
      grid: LoadGrid.of(e.loadType, profile),
      lowerBody:
          e.articularity == Articularity.multiJoint &&
          (e.family == MovementFamily.jambesGenou ||
              e.family == MovementFamily.jambesHanche),
      groups: List<MuscleGroup>.unmodifiable(groups),
      groupWeights: List<double>.unmodifiable(weights),
    );
  }

  /// Mode de capacité de l'exercice [e], ou `null` s'il n'est pas modélisé.
  static CapacityMode? modeOf(CatalogExercise e) {
    switch (e.family) {
      case MovementFamily.cardio:
      case MovementFamily.conditionnement:
      case MovementFamily.mobilite:
      case MovementFamily.recuperation:
        return null;
      case MovementFamily.cou:
      case MovementFamily.explosif:
      case MovementFamily.figureDynamique:
      case MovementFamily.figureStatique:
      case MovementFamily.gainage:
      case MovementFamily.isolationBras:
      case MovementFamily.isolationHaut:
      case MovementFamily.isolationJambes:
      case MovementFamily.jambesGenou:
      case MovementFamily.jambesHanche:
      case MovementFamily.porte:
      case MovementFamily.poussee:
      case MovementFamily.tirage:
      case MovementFamily.tronc:
        break;
    }
    switch (e.unit) {
      case MeasureUnit.distance:
      case MeasureUnit.calories:
        return null;
      case MeasureUnit.seconds:
        return CapacityMode.hold;
      case MeasureUnit.repetitions:
        if (e.assisted) {
          return CapacityMode.reps;
        }
        switch (e.loadType) {
          case LoadType.addedWeight:
          case LoadType.barbell:
          case LoadType.dumbbells:
          case LoadType.kettlebell:
          case LoadType.machine:
          case LoadType.cable:
          case LoadType.other:
            return CapacityMode.loaded;
          case LoadType.none:
          case LoadType.bodyweight:
          case LoadType.band:
            return CapacityMode.reps;
        }
    }
  }
}
