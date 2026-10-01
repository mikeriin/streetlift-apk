/// Contexte d'une génération : ce que le profil, les verrous et le résumé
/// d'adaptation imposent au catalogue. C'est ici que vivent les
/// contraintes dures (matériel, lieu, niveau, prérequis, articulations,
/// exclusions) : la recherche ne voit que des exercices admissibles.
library;

import 'package:kalis_core/kalis_core.dart';

import 'hash.dart';
import 'params.dart';
import 'scheme.dart';
import 'similarity.dart';
import 'traits.dart';

/// Classe de discipline : à quoi sert un exercice dans le programme, et
/// unité du dosage. La forme générale se répartit entre son renforcement
/// ([generalFitness]), le cardio et la mobilité.
enum DisciplineClass {
  /// Musculation.
  musculation(TrainingDiscipline.musculation, 1.0),

  /// Street workout (sets & reps).
  streetWorkout(TrainingDiscipline.streetWorkout, 1.0),

  /// Streetlifting.
  streetlifting(TrainingDiscipline.streetlifting, 1.0),

  /// Calisthénie (figures).
  calisthenics(TrainingDiscipline.calisthenics, 1.0),

  /// CrossFit.
  crossfit(TrainingDiscipline.crossfit, 0.6),

  /// Cardio.
  cardio(TrainingDiscipline.cardio, 0.0),

  /// Mobilité.
  mobility(TrainingDiscipline.mobility, 0.0),

  /// Renforcement de la forme générale.
  generalFitness(TrainingDiscipline.generalFitness, 1.0);

  const DisciplineClass(this.discipline, this.resistanceShare);

  /// Discipline du profil à laquelle la classe se rattache.
  final TrainingDiscipline discipline;

  /// Part de renforcement musculaire dans le temps de la classe.
  final double resistanceShare;
}

/// Affinité (de 0 à 100) d'une classe de discipline pour une discipline de
/// la base : 100 = exercice propre à la discipline, moins = exercice
/// d'appoint, 0 = hors de la discipline. Lignes : [DisciplineClass] ;
/// colonnes : [CatalogDiscipline] (musculation, street workout,
/// streetlifting, calisthénie statique, calisthénie dynamique, CrossFit,
/// cardio, mobilité).
const List<List<int>> disciplineAffinity = <List<int>>[
  <int>[100, 60, 50, 0, 0, 0, 0, 0],
  <int>[40, 100, 50, 30, 60, 0, 0, 0],
  <int>[60, 60, 100, 20, 30, 0, 0, 0],
  <int>[30, 60, 30, 100, 100, 0, 0, 0],
  <int>[60, 50, 0, 20, 40, 100, 50, 0],
  <int>[0, 0, 0, 0, 0, 0, 100, 0],
  <int>[0, 0, 0, 0, 0, 0, 0, 100],
  <int>[90, 90, 0, 0, 0, 0, 0, 0],
];

/// Affinité d'un exercice de repli (séance qui, sinon, serait vide).
const int fallbackAffinity = 10;

/// Catégorie de la base des quatre mouvements de compétition du
/// streetlifting.
const String competitionCategory = 'Mouvement de compétition';

/// Pourquoi un exercice n'est pas admissible pour un profil.
abstract final class Rejections {
  /// Hors des disciplines du profil.
  static const String discipline = 'discipline';

  /// Détesté, non su, écarté par un verrou ou mal toléré.
  static const String excluded = 'excluded';

  /// Trop difficile pour le niveau du groupe de mouvements.
  static const String level = 'level';

  /// Un palier précédent n'est pas acquis.
  static const String prerequisite = 'prerequisite';

  /// Trop facile pour le niveau du groupe de mouvements.
  static const String tooEasy = 'too_easy';

  /// Exercice réservé (haltérophilie, pliométrie et balistique hors
  /// CrossFit, souplesse avancée).
  static const String reserved = 'reserved';

  /// Écarté par la prudence (impact, fatigue maximale).
  static const String cautious = 'cautious';

  /// Contrainte sur une articulation ou une zone limitée.
  static const String joint = 'joint';

  /// Matériel ou lieu absent tous les jours.
  static const String equipment = 'equipment';

  /// Ne tient dans le temps d'aucun jour.
  static const String time = 'time';
}

/// Jour d'entraînement.
final class DayInfo {
  /// Jour de rang [index].
  const DayInfo({
    required this.index,
    required this.weekday,
    required this.minutes,
    required this.place,
    required this.equipment,
    required this.maxWorkSlots,
  });

  /// Rang dans la semaine d'entraînement (0 = premier).
  final int index;

  /// Jour ISO (1 = lundi).
  final int weekday;

  /// Minutes disponibles.
  final int minutes;

  /// Lieu imposé, ou `null`.
  final Place? place;

  /// Matériel disponible ce jour-là.
  final Set<String> equipment;

  /// Nombre maximal d'exercices hors mobilité.
  final int maxWorkSlots;

  /// Secondes disponibles.
  int get seconds => minutes * 60;

  /// Temps d'échauffement général réservé quand la séance en demande un.
  int get warmupSeconds => minutes <= 20 ? 120 : (minutes <= 35 ? 180 : 300);
}

/// Objectif servi par le programme : objectif de performance du profil, ou
/// mouvement de compétition de la discipline.
final class GoalTarget {
  /// Objectif sur [exercise].
  const GoalTarget({
    required this.goalId,
    required this.exercise,
    required this.weight,
    required this.goal,
  });

  /// Identifiant de l'objectif du profil, ou `null` (objectif implicite).
  final String? goalId;

  /// Exercice visé.
  final CatalogExercise exercise;

  /// Poids dans la composante d'objectifs.
  final double weight;

  /// Objectif du profil, ou `null`.
  final Goal? goal;
}

/// Limitation appliquée : articulation ou zone, et gêne.
final class _Limit {
  const _Limit(this.joint, this.groups, this.discomfort);

  final Joint? joint;
  final List<MuscleGroup> groups;
  final int discomfort;
}

/// Exercice admissible (ou imposé) et ce que le moteur en sait pour ce
/// profil.
final class PoolEntry {
  PoolEntry._({
    required this.index,
    required this.traits,
    required this.cls,
    required this.affinity,
    required this.scheme,
    required this.dayMask,
    required this.selectable,
    required this.goalSupport,
    required this.liked,
    required this.known,
    required this.novel,
    required this.jointPenalty,
    required this.fit,
    required this.staple,
    required this.fallback,
    required this.prioritySkill,
    required this.rootIndex,
    required this.creditGroups,
    required this.creditValues,
    required this.heavyWeight,
    required this.pushUnits,
    required this.pullUnits,
    required this.kneeUnits,
    required this.hipUnits,
    required this.coverBits,
    required this.needsWarmup,
    required this.level,
    required this.margin,
    required this.goalLift,
    required this.oneRmTotalKg,
    required this.oneRmEstimated,
    required this.knownMaxReps,
    required this.knownMaxHoldSeconds,
    required this.tieBreak,
  }) : practice =
           scheme.kind == SchemeKind.strengthMain ||
           scheme.kind == SchemeKind.skillHold ||
           scheme.kind == SchemeKind.skillReps ||
           scheme.kind == SchemeKind.power ||
           scheme.kind == SchemeKind.plyometric ||
           scheme.kind == SchemeKind.ballistic;

  /// Rang dans le vivier.
  final int index;

  /// Traits de l'exercice.
  final ExerciseTraits traits;

  /// Classe de discipline servie.
  final DisciplineClass cls;

  /// Affinité de la classe pour l'exercice, de 0 à 100.
  final int affinity;

  /// Prescription de référence.
  final Scheme scheme;

  /// Travail de pratique : séries courtes loin de l'échec (force maximale
  /// sur un mouvement d'objectif, figures, puissance). Ses séries comptent
  /// pour moitié dans le volume par muscle, dont les bandes viennent
  /// d'études sur des séries proches de l'échec.
  final bool practice;

  /// Jours où l'exercice est faisable (bit du rang du jour).
  final int dayMask;

  /// Faux pour un exercice imposé (verrou, ajout de l'utilisateur) que la
  /// recherche ne choisit pas d'elle-même.
  final bool selectable;

  /// Soutien de chaque objectif de [PlanContext.goals], de 0 à 100.
  final List<int> goalSupport;

  /// Exercice aimé.
  final bool liked;

  /// Exercice que l'utilisateur sait faire (niveau déclaré ou validé).
  final bool known;

  /// Nouveauté technique.
  final bool novel;

  /// Contrainte sur les zones limitées, de 0 à 1.
  final double jointPenalty;

  /// Adéquation de l'exercice, de 0 à 1 : mouvement de base de sa famille
  /// (racine `variante_de`), ni trop facile ni assisté sans besoin, connu
  /// de l'utilisateur.
  final double fit;

  /// Valeur d'ancrage d'une séance, de 0 à 1 : mouvement de base (racine
  /// d'une chaîne fournie) ou mouvement d'un objectif ; 0 hors
  /// polyarticulaires, puissance et figures.
  final double staple;

  /// Exercice de repli : hors des disciplines du profil, admis seulement
  /// les jours où rien d'autre n'est possible.
  final bool fallback;

  /// Figure prioritaire : connue de l'utilisateur ou palier d'un objectif.
  final bool prioritySkill;

  /// Rang dense de la racine `variante_de` dans le vivier.
  final int rootIndex;

  /// Groupes musculaires crédités (rang de `MuscleGroup`).
  final List<int> creditGroups;

  /// Crédit par série, en demi-séries, aligné sur [creditGroups].
  final List<int> creditValues;

  /// Poids dans la règle des 48 heures : 2 renforcement, 1 figure, 0 sinon.
  final int heavyWeight;

  /// Demi-séries de poussée par série.
  final int pushUnits;

  /// Demi-séries de tirage par série.
  final int pullUnits;

  /// Demi-séries à dominante genou par série.
  final int kneeUnits;

  /// Demi-séries de chaîne postérieure par série.
  final int hipUnits;

  /// Schémas de base couverts (bits : poussée horizontale, poussée
  /// verticale, tirage horizontal, tirage vertical, genou, hanche, tronc).
  final int coverBits;

  /// Demande un échauffement général.
  final bool needsWarmup;

  /// Niveau de l'athlète sur le groupe de l'exercice (0 à 3).
  final int level;

  /// Niveau de l'athlète moins difficulté de l'exercice.
  final int margin;

  /// Mouvement de compétition ou exercice d'un objectif de force.
  final bool goalLift;

  /// 1RM de charge totale connu (déclaré, borne basse, ou estimé), en kg.
  final double? oneRmTotalKg;

  /// Vrai si [oneRmTotalKg] vient du moteur dynamique.
  final bool oneRmEstimated;

  /// Répétitions maximales connues sur cet exercice (déclarées ou
  /// estimées), ou `null`.
  final int? knownMaxReps;

  /// Tenue maximale connue sur cet exercice, en secondes, ou `null`.
  final int? knownMaxHoldSeconds;

  /// Départage stable, de 0 à 1 (FNV-1a de la graine et de l'identifiant).
  final double tieBreak;

  /// Exercice.
  CatalogExercise get exercise => traits.exercise;

  /// Identifiant de l'exercice.
  String get id => traits.exercise.id;

  /// Nature dans la séance.
  SlotKind get kind => traits.kind;

  /// Vrai si l'exercice est faisable le jour de rang [day].
  bool feasibleOn(int day) => (dayMask >> day) & 1 == 1;
}

/// Entrées de la construction d'un contexte.
final class ContextInputs {
  /// Entrées.
  const ContextInputs({
    required this.catalog,
    required this.profile,
    required this.startDate,
    required this.seed,
    this.locks = const <PlanLock>[],
    this.adaptation,
    this.extraExcluded = const <String>{},
    this.extraPains = const <(BodyZone, int)>[],
    this.forcedIds = const <String>{},
    this.minutesOverride = const <int, int>{},
    this.volumeScale = 1.0,
    this.params = PlanParams.standard,
  });

  /// Catalogue.
  final Catalog catalog;

  /// Profil.
  final AthleteProfile profile;

  /// Premier jour du bloc.
  final CivilDate startDate;

  /// Graine (départage).
  final int seed;

  /// Verrous.
  final List<PlanLock> locks;

  /// Résumé d'adaptation.
  final AdaptationSummary? adaptation;

  /// Exercices écartés en plus de ceux du profil et des verrous.
  final Set<String> extraExcluded;

  /// Zones douloureuses en plus des limitations du profil (zone, gêne).
  final List<(BodyZone, int)> extraPains;

  /// Exercices à garder dans le vivier même s'ils ne sont pas admissibles
  /// (déjà présents dans le programme, ajoutés par l'utilisateur).
  final Set<String> forcedIds;

  /// Minutes imposées pour un jour (rang du jour → minutes).
  final Map<int, int> minutesOverride;

  /// Facteur appliqué aux bandes de volume.
  final double volumeScale;

  /// Paramètres.
  final PlanParams params;
}

const Map<BodyZone, List<MuscleGroup>> _zoneGroups =
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

/// Bandes de volume hebdomadaire par groupe majeur, en séries
/// fractionnaires, par niveau (débutant, intermédiaire, avancé, élite).
const List<(int, int)> volumeBandsByLevel = <(int, int)>[
  (4, 10),
  (8, 16),
  (12, 20),
  (12, 20),
];

/// Niveau (0 à 3) d'une difficulté maîtrisée de 1 à 10.
int levelOfAbility(int ability) =>
    ability <= 3 ? 0 : (ability <= 6 ? 1 : (ability <= 8 ? 2 : 3));

List<double>? _ratioThresholds(CatalogExercise e) {
  final bodyweight = e.bodyweightFraction != null;
  switch (e.pattern) {
    case MovementPattern.squat:
      return bodyweight ? null : const <double>[0.75, 1.25, 1.75];
    case MovementPattern.charniereHanche:
      return const <double>[1.0, 1.5, 2.0];
    case MovementPattern.pousseeHorizontale:
    case MovementPattern.pousseeInclinee:
      return bodyweight ? null : const <double>[0.6, 1.0, 1.4];
    case MovementPattern.pousseeVerticaleHaute:
      return bodyweight ? null : const <double>[0.4, 0.65, 0.9];
    case MovementPattern.tirageVertical:
      return bodyweight
          ? const <double>[1.1, 1.3, 1.55]
          : const <double>[0.6, 0.9, 1.2];
    case MovementPattern.pousseeVerticaleBasse:
      return bodyweight ? const <double>[1.15, 1.45, 1.75] : null;
    case MovementPattern.transitionMuscleUp:
      return bodyweight ? const <double>[1.02, 1.1, 1.2] : null;
    case MovementPattern.tirageHorizontal:
    case MovementPattern.halterophilie:
      return bodyweight ? null : const <double>[0.5, 0.8, 1.1];
    default:
      return null;
  }
}

int _clampAbility(int v) => v < 1 ? 1 : (v > 10 ? 10 : v);

/// Contexte d'une génération.
final class PlanContext {
  PlanContext._({
    required this.catalog,
    required this.traits,
    required this.profile,
    required this.params,
    required this.seed,
    required this.startDate,
    required this.days,
    required this.targets,
    required this.pool,
    required this.goals,
    required this.goalExposureTarget,
    required this.ability,
    required this.globalLevel,
    required this.cautious,
    required this.senior,
    required this.bandLow,
    required this.bandHigh,
    required this.groupWeight,
    required this.resistanceShare,
    required this.adjacentPairs,
    required this.requiredIds,
    required this.excludedIds,
    required this.likedCount,
    required this.knownCount,
    required this.hasPrioritySkill,
    required this.goalExactSelectable,
    required this.goalBestSupport,
    required this.goalWeights,
    required this.rejections,
    required this.noveltyAllowance,
    required this.rootCount,
    required this.coverableBits,
    required Map<String, int> indexById,
  }) : _indexById = indexById,
       _neighbours = List<List<int>?>.filled(pool.length, null);

  /// Construit le contexte de [inputs].
  factory PlanContext.build(ContextInputs inputs) => _build(inputs);

  /// Catalogue.
  final Catalog catalog;

  /// Traits du catalogue.
  final CatalogTraits traits;

  /// Profil.
  final AthleteProfile profile;

  /// Paramètres.
  final PlanParams params;

  /// Graine.
  final int seed;

  /// Premier jour du bloc.
  final CivilDate startDate;

  /// Jours d'entraînement, par jour ISO croissant.
  final List<DayInfo> days;

  /// Part visée du temps par classe de discipline (somme 1), indexée par
  /// `DisciplineClass.index`.
  final List<double> targets;

  /// Vivier : exercices admissibles, puis exercices imposés.
  final List<PoolEntry> pool;

  /// Objectifs servis.
  final List<GoalTarget> goals;

  /// Expositions hebdomadaires visées par objectif.
  final double goalExposureTarget;

  /// Difficulté maîtrisée par groupe de niveau, de 1 à 10.
  final Map<AbilityGroup, int> ability;

  /// Niveau global (0 à 3) : fixe les bandes de volume.
  final int globalLevel;

  /// Programme prudent.
  final bool cautious;

  /// 65 ans et plus.
  final bool senior;

  /// Bas de la bande de volume par groupe, en demi-séries.
  final List<int> bandLow;

  /// Haut de la bande de volume par groupe, en demi-séries.
  final List<int> bandHigh;

  /// Poids de chaque groupe dans la composante de volume.
  final List<double> groupWeight;

  /// Part du temps consacrée au renforcement, de 0 à 1.
  final double resistanceShare;

  /// Paires de jours d'entraînement séparés de moins de 48 heures.
  final List<(int, int)> adjacentPairs;

  /// Exercices exigés par un verrou.
  final Set<String> requiredIds;

  /// Exercices écartés (détestés, non sus, verrous, mal tolérés).
  final Set<String> excludedIds;

  /// Nombre d'exercices aimés présents dans le vivier (plafonné à 4).
  final int likedCount;

  /// Nombre d'exercices sus présents dans le vivier (plafonné à 6).
  final int knownCount;

  /// Vrai si le vivier contient une figure prioritaire.
  final bool hasPrioritySkill;

  /// Pour chaque objectif : l'exercice visé lui-même est admissible.
  final List<bool> goalExactSelectable;

  /// Meilleur soutien de chaque objectif parmi les exercices choisissables
  /// (100 = l'exercice même).
  final List<int> goalBestSupport;

  /// Poids effectif de chaque objectif dans la note.
  final List<double> goalWeights;

  /// Pourquoi un exercice du catalogue n'est pas admissible (identifiant →
  /// code de [Rejections]) ; un exercice absent de la table est admissible.
  final Map<String, String> rejections;

  /// Nouveautés techniques admises à la fois.
  final int noveltyAllowance;

  /// Nombre de racines `variante_de` distinctes du vivier.
  final int rootCount;

  /// Schémas de base que le vivier permet de couvrir (bits).
  final int coverableBits;

  final Map<String, int> _indexById;
  final List<List<int>?> _neighbours;

  /// Nombre de jours.
  int get dayCount => days.length;

  /// Rang dans le vivier de l'exercice [id], ou −1.
  int indexOf(String id) => _indexById[id] ?? -1;

  /// Entrée du vivier de l'exercice [id], ou `null`.
  PoolEntry? entryOf(String id) {
    final at = _indexById[id];
    return at == null ? null : pool[at];
  }

  /// Séries par défaut de [entry] le jour [day] (semaine de référence).
  int defaultSets(PoolEntry entry, int day) {
    final scheme = entry.scheme;
    final minutes = days[day].minutes;
    if (scheme.continuous) {
      final room = (minutes * 54) ~/ Scheme.continuousUnitSeconds;
      var sets = scheme.sets > room ? room : scheme.sets;
      if (sets < scheme.minSets) {
        sets = scheme.minSets;
      }
      return sets;
    }
    final cap = minutes <= 20 ? 2 : (minutes <= 35 ? 3 : 20);
    final sets = scheme.sets > cap ? cap : scheme.sets;
    return sets < scheme.minSets ? scheme.minSets : sets;
  }

  /// Les exercices choisissables les plus proches de l'entrée [index]
  /// (elle exclue), par proximité décroissante puis par identifiant.
  List<int> neighbours(int index) {
    final cached = _neighbours[index];
    if (cached != null) {
      return cached;
    }
    final self = pool[index].exercise;
    final scored = <(double, int)>[];
    for (final other in pool) {
      if (other.index == index || !other.selectable) {
        continue;
      }
      final s = planSimilarity(self, other.exercise);
      if (s >= 0.35) {
        scored.add((s, other.index));
      }
    }
    scored.sort((a, b) {
      final by = b.$1.compareTo(a.$1);
      return by != 0 ? by : pool[a.$2].id.compareTo(pool[b.$2].id);
    });
    final limit = params.neighbourCount;
    final out = List<int>.unmodifiable(<int>[
      for (var i = 0; i < scored.length && i < limit; i++) scored[i].$2,
    ]);
    _neighbours[index] = out;
    return out;
  }
}

int _lowerMedian(List<int> values) {
  final sorted = <int>[...values]..sort();
  return sorted[(sorted.length - 1) ~/ 2];
}

/// Difficulté maîtrisée que révèle une performance sur [e].
///
/// Rend aussi, par [cannot], si la performance dit que l'exercice n'est pas
/// encore acquis (moins d'une répétition).
int abilityFromPerformance({
  required CatalogExercise e,
  required LevelMeasure measure,
  required double value,
  required double? bodyWeightKg,
  required Sex sex,
  required AbilityGroup group,
  void Function()? cannot,
}) {
  final d = e.difficulty;
  switch (measure) {
    case LevelMeasure.maxReps:
      if (value < 1) {
        cannot?.call();
        return _clampAbility(d - 2);
      }
      if (value < 5) {
        return d;
      }
      if (value < 10) {
        return _clampAbility(d + 1);
      }
      if (value < 20) {
        return _clampAbility(d + 2);
      }
      return _clampAbility(d + 3);
    case LevelMeasure.maxHoldSeconds:
      if (value < 3) {
        return _clampAbility(d - 1);
      }
      if (value < 10) {
        return d;
      }
      if (value < 20) {
        return _clampAbility(d + 1);
      }
      if (value < 45) {
        return _clampAbility(d + 2);
      }
      return _clampAbility(d + 3);
    case LevelMeasure.timeSeconds:
      // Qui connaît son temps sur une distance s'entraîne déjà de façon
      // structurée : au moins le niveau des séances fractionnées.
      return _clampAbility(d + 2 < 5 ? 5 : d + 2);
    case LevelMeasure.oneRmKg:
      final thresholds = _ratioThresholds(e);
      if (thresholds == null || bodyWeightKg == null || bodyWeightKg <= 0) {
        return _clampAbility(d + 1);
      }
      final fraction = e.bodyweightFraction?.value ?? 0;
      final ratio = (value + fraction * bodyWeightKg) / bodyWeightKg;
      final lower = group == AbilityGroup.legs || group == AbilityGroup.power;
      final factor = switch (sex) {
        Sex.male => 1.0,
        Sex.female => lower ? 0.75 : 0.65,
        Sex.undisclosed => 0.85,
      };
      var rank = 0;
      for (final t in thresholds) {
        // Pour un exercice lesté, le seuil porte sur ce qui dépasse le
        // poids du corps : le facteur ne s'applique qu'à cette part.
        final threshold = fraction > 0 ? 1 + (t - 1) * factor : t * factor;
        if (ratio >= threshold) {
          rank++;
        }
      }
      const byRank = <int>[3, 4, 6, 8];
      final fromRatio = byRank[rank];
      return fromRatio > d ? fromRatio : d;
  }
}

PlanContext _build(ContextInputs inputs) {
  final catalog = inputs.catalog;
  final profile = inputs.profile;
  final params = inputs.params;
  final traits = CatalogTraits.of(catalog);
  final adaptation = inputs.adaptation;

  // Jours.
  final slots = <DaySlot>[...profile.availability]
    ..sort((a, b) => a.weekday.compareTo(b.weekday));
  final allEquipment = profile.equipment.toSet();
  final byPlace = <Place, Set<String>>{};
  final equipmentByPlace = profile.equipmentByPlace;
  if (equipmentByPlace != null) {
    for (final pe in equipmentByPlace) {
      byPlace[pe.place] = pe.equipment.toSet();
    }
  }
  final days = <DayInfo>[];
  for (var i = 0; i < slots.length; i++) {
    final slot = slots[i];
    final minutes = inputs.minutesOverride[i] ?? slot.minutes;
    final place = slot.place;
    final equipment = place != null && byPlace.containsKey(place)
        ? byPlace[place]!
        : allEquipment;
    var maxWork = minutes ~/ params.minutesPerWorkSlot + 1;
    if (maxWork > params.maxWorkSlotsPerDay) {
      maxWork = params.maxWorkSlotsPerDay;
    }
    days.add(
      DayInfo(
        index: i,
        weekday: slot.weekday,
        minutes: minutes < 1 ? 1 : minutes,
        place: place,
        equipment: equipment,
        maxWorkSlots: maxWork,
      ),
    );
  }
  final adjacent = <(int, int)>[];
  final gapDays = (params.recoveryHours + 23) ~/ 24;
  for (var i = 0; i < days.length; i++) {
    for (var j = i + 1; j < days.length; j++) {
      final gap = days[j].weekday - days[i].weekday;
      final wrap = 7 - gap;
      if (gap < gapDays || wrap < gapDays) {
        adjacent.add((i, j));
      }
    }
  }

  // Dosage par classe de discipline.
  final targets = List<double>.filled(DisciplineClass.values.length, 0);
  void addShare(TrainingDiscipline discipline, int pct) {
    if (discipline == TrainingDiscipline.generalFitness) {
      targets[DisciplineClass.generalFitness.index] +=
          pct * params.generalFitnessResistancePct / 10000;
      targets[DisciplineClass.cardio.index] +=
          pct * params.generalFitnessCardioPct / 10000;
      targets[DisciplineClass.mobility.index] +=
          pct * params.generalFitnessMobilityPct / 10000;
      return;
    }
    for (final c in DisciplineClass.values) {
      if (c.discipline == discipline) {
        targets[c.index] += pct / 100;
      }
    }
  }

  addShare(profile.disciplines.primary, profile.disciplines.primaryPct);
  for (final s in profile.disciplines.secondaries) {
    addShare(s.discipline, s.pct);
  }
  var targetSum = 0.0;
  for (final t in targets) {
    targetSum += t;
  }
  if (targetSum <= 0) {
    targets[DisciplineClass.generalFitness.index] = 1;
    targetSum = 1;
  }
  var resistanceShare = 0.0;
  for (final c in DisciplineClass.values) {
    targets[c.index] = targets[c.index] / targetSum;
    resistanceShare += targets[c.index] * c.resistanceShare;
  }
  DisciplineClass primaryClass = DisciplineClass.generalFitness;
  for (final c in DisciplineClass.values) {
    if (c.discipline == profile.disciplines.primary) {
      primaryClass = c;
    }
  }

  // Prudence.
  final age = inputs.startDate.year - profile.birthYear;
  final screening = profile.healthScreening?.outcome;
  final senior = age >= params.seniorAge;
  final cautious =
      screening == HealthScreeningOutcome.cautious ||
      screening == HealthScreeningOutcome.notAnswered ||
      senior ||
      age < params.adultAge;

  // Niveau par groupe.
  final declaredAbility = <AbilityGroup, int>{};
  final declaredValues = <int>[];
  final knownIds = <String>{...?profile.knownExerciseIds};
  final cannotIds = <String>{...?profile.cannotDoExerciseIds};
  final maxRepsOf = <String, int>{};
  final maxHoldOf = <String, int>{};
  final oneRmOf = <String, double>{};
  final oneRmEstimated = <String>{};
  final capOf = <AbilityGroup, int>{};
  void learn(
    CatalogExercise e,
    LevelMeasure measure,
    double value,
    bool estimated,
  ) {
    final group = abilityGroupOf(e);
    var notYet = false;
    final a0 = abilityFromPerformance(
      e: e,
      measure: measure,
      value: value,
      bodyWeightKg: profile.bodyWeightKg,
      sex: profile.sex,
      group: group,
      cannot: () => notYet = true,
    );
    // Une tenue sur un exercice d'appoint (suspension, gainage) ne dit pas
    // la force du groupe : elle ne vaut pas plus d'un palier au-dessus.
    final kind = slotKindOf(e);
    final modest =
        measure == LevelMeasure.maxHoldSeconds &&
        (kind == SlotKind.accessory || kind == SlotKind.core) &&
        a0 > e.difficulty + 1;
    final a = modest ? e.difficulty + 1 : a0;
    if (notYet) {
      // Pas une répétition : l'exercice n'est pas acquis, et le groupe ne
      // dépasse pas le palier juste en dessous tant que rien d'autre ne
      // dit mieux.
      cannotIds.add(e.id);
      final cap = e.difficulty - 1;
      final previousCap = capOf[group];
      if (previousCap == null || cap < previousCap) {
        capOf[group] = cap;
      }
      return;
    }
    declaredValues.add(a);
    final previous = declaredAbility[group];
    if (previous == null || a > previous) {
      declaredAbility[group] = a;
    }
    switch (measure) {
      case LevelMeasure.maxReps:
        if (value >= 1) {
          knownIds.add(e.id);
          maxRepsOf[e.id] = value.floor();
        }
      case LevelMeasure.maxHoldSeconds:
        if (value >= 3) {
          knownIds.add(e.id);
        }
        maxHoldOf[e.id] = value.floor();
      case LevelMeasure.oneRmKg:
        knownIds.add(e.id);
        final fraction = e.bodyweightFraction?.value ?? 0;
        final bw = profile.bodyWeightKg ?? 0;
        if (estimated) {
          oneRmOf[e.id] = value;
          oneRmEstimated.add(e.id);
        } else if (fraction <= 0 || bw > 0) {
          oneRmOf[e.id] = value + fraction * bw;
        }
      case LevelMeasure.timeSeconds:
        knownIds.add(e.id);
    }
  }

  for (final level in profile.movementLevels) {
    final e = catalog.find(level.exerciseId);
    final low = level.low;
    if (e == null || !level.known || low == null) {
      continue;
    }
    learn(e, level.measure, low, false);
  }
  if (adaptation != null) {
    for (final est in adaptation.estimates) {
      final e = catalog.find(est.exerciseId);
      if (e == null || est.observations < 3) {
        continue;
      }
      final prudent = est.capacity - est.standardError;
      if (prudent <= 0) {
        continue;
      }
      switch (est.unit) {
        case CapacityUnit.oneRmKg:
          // Capacité en charge TOTALE : on retire la part du poids du
          // corps pour retrouver la convention des niveaux déclarés.
          final fraction = e.bodyweightFraction?.value ?? 0;
          final bw = profile.bodyWeightKg ?? 0;
          final external = prudent - fraction * bw;
          learn(e, LevelMeasure.oneRmKg, external < 0 ? 0 : external, false);
          oneRmOf[e.id] = prudent;
          oneRmEstimated.add(e.id);
        case CapacityUnit.maxReps:
          learn(e, LevelMeasure.maxReps, prudent, true);
        case CapacityUnit.maxHoldSeconds:
          learn(e, LevelMeasure.maxHoldSeconds, prudent, true);
        case CapacityUnit.metersPerSecond:
          break;
      }
    }
  }
  // Un objectif « première répétition » ou « figure à débloquer » sur un
  // exercice sans niveau déclaré dit que l'exercice n'est pas acquis : il
  // se prépare par ses paliers, il ne se programme pas.
  for (final g in profile.goals) {
    final id = g.exerciseId;
    if (g.kind != GoalKind.performance || id == null || knownIds.contains(id)) {
      continue;
    }
    final e = catalog.find(id);
    if (e == null) {
      continue;
    }
    final target = g.targetValue;
    final first =
        g.metric == GoalMetric.skillUnlocked ||
        (g.metric == GoalMetric.maxReps && target != null && target <= 2);
    if (!first) {
      continue;
    }
    cannotIds.add(id);
    final group = abilityGroupOf(e);
    final cap = e.difficulty - 1;
    final previousCap = capOf[group];
    if (previousCap == null || cap < previousCap) {
      capOf[group] = cap;
    }
  }
  final experience = profile.experience;
  int base;
  if (experience != null) {
    base = const <int>[3, 5, 8, 10][experience.index];
  } else if (declaredValues.isNotEmpty) {
    final median = _lowerMedian(declaredValues);
    base = median < 3 ? 3 : (median > 6 ? 6 : median);
  } else {
    base = 3;
  }
  final ability = <AbilityGroup, int>{};
  for (final g in AbilityGroup.values) {
    var a = declaredAbility[g];
    if (a == null) {
      a = base;
      if (g == AbilityGroup.mobility || g == AbilityGroup.cardio) {
        a = a > 4 ? 4 : a;
      } else if (g == AbilityGroup.power || g == AbilityGroup.core) {
        a = a > 6 ? 6 : a;
      }
      final cap = capOf[g];
      if (cap != null && cap < a) {
        a = cap;
      }
    }
    if (cautious) {
      a = a - 1 < 2 ? 2 : a - 1;
    }
    ability[g] = _clampAbility(a);
  }
  int globalLevel;
  if (experience != null) {
    globalLevel = experience.index;
  } else {
    globalLevel = levelOfAbility(
      _lowerMedian(<int>[
        ability[AbilityGroup.push]!,
        ability[AbilityGroup.pull]!,
        ability[AbilityGroup.legs]!,
      ]),
    );
  }
  if (cautious && globalLevel > 1) {
    globalLevel = 1;
  }

  // Exclusions.
  final excluded = <String>{
    ...profile.dislikedExerciseIds,
    ...inputs.extraExcluded,
    ...cannotIds,
  };
  final required = <String>{};
  for (final lock in inputs.locks) {
    final id = lock.exerciseId;
    if (id == null) {
      continue;
    }
    if (lock.kind == LockKind.excludeExercise) {
      excluded.add(id);
    } else if (lock.kind == LockKind.requireExercise) {
      required.add(id);
    }
  }
  if (adaptation != null) {
    excluded.addAll(adaptation.avoidedExerciseIds);
  }
  final forced = <String>{...inputs.forcedIds, ...required};
  for (final lock in inputs.locks) {
    final id = lock.exerciseId;
    if (lock.kind == LockKind.keepSlot && id != null) {
      forced.add(id);
    }
  }
  excluded.removeAll(required);

  // Limitations.
  final limits = <_Limit>[];
  void addLimit(BodyZone zone, Joint? joint, int discomfort) {
    if (discomfort <= 0) {
      return;
    }
    limits.add(
      _Limit(
        joint ?? zone.joint,
        _zoneGroups[zone] ?? const <MuscleGroup>[],
        discomfort,
      ),
    );
  }

  for (final l in profile.limitations) {
    addLimit(l.zone, l.joint, l.discomfort);
  }
  for (final (zone, discomfort) in inputs.extraPains) {
    addLimit(zone, null, discomfort);
  }
  if (adaptation != null) {
    for (final pain in adaptation.pains) {
      addLimit(pain.zone, null, pain.lastIntensity);
    }
  }

  // Objectifs.
  final goals = <GoalTarget>[];
  final goalIds = <String>{};
  for (final g in profile.goals) {
    final id = g.exerciseId;
    if (g.kind != GoalKind.performance || id == null) {
      continue;
    }
    final e = catalog.find(id);
    if (e == null || goals.length >= 8) {
      continue;
    }
    goals.add(GoalTarget(goalId: g.id, exercise: e, weight: 1, goal: g));
    goalIds.add(id);
  }
  if (targets[DisciplineClass.streetlifting.index] > 0) {
    for (final e in catalog.byCategory(competitionCategory)) {
      if (e.discipline == CatalogDiscipline.streetlifting &&
          !goalIds.contains(e.id) &&
          goals.length < 12) {
        goals.add(
          GoalTarget(goalId: null, exercise: e, weight: 0.5, goal: null),
        );
        goalIds.add(e.id);
      }
    }
  }
  final strengthGoalRoots = <String>{};
  for (final g in goals) {
    final metric = g.goal?.metric;
    if (g.goal == null || metric == GoalMetric.oneRmKg) {
      strengthGoalRoots.add(g.exercise.rootId);
    }
  }

  // Vivier.
  final liked = profile.likedExerciseIds.toSet();
  final pool = <PoolEntry>[];
  final indexById = <String, int>{};
  final rootIndex = <String, int>{};
  final rejections = <String, String>{};
  final exactSelectable = List<bool>.filled(goals.length, false);
  final goalBest = List<int>.filled(goals.length, 0);
  final trainable = <int>{};
  var coverable = 0;
  var likedInPool = 0;
  var knownInPool = 0;
  final crossfitWanted = targets[DisciplineClass.crossfit.index] > 0;
  final flexibilityWanted =
      targets[DisciplineClass.mobility.index] >= 0.3 ||
      targets[DisciplineClass.calisthenics.index] > 0;
  // Manche 0 : le vivier des disciplines du profil. Manches 1 et 2, pour
  // les seuls jours restés sans aucun exercice choisissable (discipline
  // rendue impraticable par une limitation, un lieu sans matériel) : une
  // séance de repli — mobilité et marche d'abord, puis tout exercice
  // admissible — plutôt qu'une séance vide.
  var fallbackDays = 0;
  for (var round = 0; round < 3; round++) {
    if (round > 0) {
      var covered = 0;
      for (final entry in pool) {
        if (entry.selectable) {
          covered |= entry.dayMask;
        }
      }
      fallbackDays = ((1 << days.length) - 1) & ~covered;
      if (fallbackDays == 0) {
        break;
      }
    }
    for (final t in traits.all) {
      final e = t.exercise;
      final isForced = forced.contains(e.id);
      String? rejection;
      if (round > 0 &&
          (indexById.containsKey(e.id) ||
              rejections[e.id] != Rejections.discipline ||
              (round == 1 &&
                  t.kind != SlotKind.mobility &&
                  e.pattern != MovementPattern.marche))) {
        continue;
      }

      // Classe de discipline.
      DisciplineClass? cls;
      var affinity = 0;
      for (final c in DisciplineClass.values) {
        final target = targets[c.index];
        if (target <= 0) {
          continue;
        }
        final a = disciplineAffinity[c.index][e.discipline.index];
        if (a > affinity ||
            (a == affinity && a > 0 && target > targets[cls!.index])) {
          affinity = a;
          cls = c;
        }
      }
      if (cls == DisciplineClass.crossfit &&
          e.discipline != CatalogDiscipline.crossfit) {
        // Le CrossFit puise sa force dans les barres, les haltères et les
        // kettlebells, sa gymnastique dans le street workout et la
        // calisthénie dynamique ; l'isolation n'est qu'un appoint.
        final free =
            e.loadType == LoadType.barbell ||
            e.loadType == LoadType.dumbbells ||
            e.loadType == LoadType.kettlebell;
        if (t.kind == SlotKind.accessory) {
          affinity = 20;
        } else if (e.discipline == CatalogDiscipline.musculation &&
            (t.kind == SlotKind.power ||
                (t.kind == SlotKind.compound && free))) {
          affinity = 90;
        } else if (e.discipline == CatalogDiscipline.streetWorkout ||
            e.discipline == CatalogDiscipline.calisthenicsDynamic) {
          affinity = 70;
        }
      }
      if (round > 0) {
        cls = t.kind == SlotKind.mobility
            ? DisciplineClass.mobility
            : (t.kind.isCardio
                  ? DisciplineClass.cardio
                  : DisciplineClass.generalFitness);
        affinity = fallbackAffinity;
      }
      if (affinity <= 0) {
        rejection = Rejections.discipline;
      } else if (excluded.contains(e.id)) {
        rejection = Rejections.excluded;
      }

      // Soutien des objectifs.
      var goalLift = false;
      var bestSupport = 0;
      final support = List<int>.filled(goals.length, 0);
      for (var j = 0; j < goals.length; j++) {
        final target = goals[j].exercise;
        var s = 0;
        if (target.id == e.id) {
          s = 100;
          final metric = goals[j].goal?.metric;
          if (goals[j].goal == null || metric == GoalMetric.oneRmKg) {
            goalLift = true;
          }
        } else if (target.rootId == e.rootId) {
          // Palier de la même chaîne : d'autant plus utile qu'il est proche
          // de l'exercice visé.
          var gap = (target.difficulty - e.difficulty).abs();
          if (gap > 5) {
            gap = 5;
          }
          s = 90 - 6 * gap;
        } else if (target.pattern == e.pattern) {
          final cosine = target.muscleCosine(e);
          s = cosine >= 0.7 ? 50 : (cosine >= 0.4 ? 30 : 0);
          if (isLoadAdjustable(target.loadType) !=
              isLoadAdjustable(e.loadType)) {
            // Un exercice sans charge réglable sert peu un objectif de
            // charge, et inversement.
            s ~/= 2;
          }
        }
        support[j] = s;
        if (s > bestSupport) {
          bestSupport = s;
        }
      }

      // Niveau, prérequis.
      final group = t.ability;
      final a = ability[group]!;
      final known = knownIds.contains(e.id);
      final wanted = known || liked.contains(e.id) || bestSupport >= 60;
      if (rejection == null && !known && e.difficulty > a) {
        rejection = Rejections.level;
      }
      if (rejection == null) {
        for (final p in e.prerequisites) {
          if (cannotIds.contains(p)) {
            rejection = Rejections.prerequisite;
          }
        }
        for (final c in cannotIds) {
          if (c == e.id) {
            continue;
          }
          final harder = catalog.find(c);
          if (harder != null &&
              harder.rootId == e.rootId &&
              e.difficulty >= harder.difficulty &&
              _descendsFrom(catalog, e, c)) {
            rejection = Rejections.prerequisite;
          }
        }
      }

      // Exercices réservés : l'haltérophilie ne se programme d'office qu'en
      // CrossFit, la souplesse avancée qu'avec une vraie part de mobilité ou
      // de calisthénie — sauf exercice connu, aimé ou lié à un objectif.
      if (rejection == null && !wanted) {
        final explosive =
            e.pattern == MovementPattern.halterophilie ||
            e.pattern == MovementPattern.pliometrie ||
            e.pattern == MovementPattern.balistique;
        if (explosive && !crossfitWanted) {
          rejection = Rejections.reserved;
        }
        if (e.pattern == MovementPattern.souplesse && !flexibilityWanted) {
          rejection = Rejections.reserved;
        }
        // Le travail direct du cou ne se programme pas d'office.
        if (e.family == MovementFamily.cou) {
          rejection = Rejections.reserved;
        }
      }

      // Trop facile : un polyarticulaire ou une figure sans charge réglable,
      // trois paliers sous le niveau du groupe (ou assisté, deux paliers
      // sous ce niveau), n'entraîne plus — sauf exercice connu, aimé ou
      // exercice même d'un objectif.
      if (rejection == null &&
          !(known || liked.contains(e.id) || bestSupport == 100)) {
        final below = a - e.difficulty;
        final unloaded =
            (t.kind == SlotKind.compound || t.kind.isSkill) &&
            !isLoadAdjustable(e.loadType);
        if ((unloaded && below >= 3) ||
            (e.assisted && t.kind.isResistance && below >= 2)) {
          rejection = Rejections.tooEasy;
        }
      }

      // Prudence.
      if (rejection == null &&
          cautious &&
          (t.impact || e.systemicFatigue >= 5)) {
        rejection = Rejections.cautious;
      }

      // Articulations et zones limitées.
      var penalty = 0.0;
      for (final limit in limits) {
        var level = 0.0;
        final joint = limit.joint;
        if (joint != null) {
          final stress = e.stressOn(joint);
          level = stress == JointStress.high
              ? 1.0
              : (stress == JointStress.moderate ? 0.5 : 0.0);
        }
        for (final g in limit.groups) {
          final credit = t.groupCredits[g.index] / 2;
          if (credit > level) {
            level = credit;
          }
        }
        if ((level >= 1 && limit.discomfort >= params.hardJointDiscomfort) ||
            (level >= 0.5 &&
                limit.discomfort >= params.severeJointDiscomfort)) {
          rejection ??= Rejections.joint;
        }
        final p = level * limit.discomfort / 10;
        if (p > penalty) {
          penalty = p;
        }
      }
      if (rejection != null && !isForced) {
        if (round == 0) {
          rejections[e.id] = rejection;
        }
        continue;
      }

      // Prescription de référence.
      final margin = known && e.difficulty > a ? 0 : a - e.difficulty;
      final resolvedClass = cls ?? primaryClass;
      final strengthFocus =
          resolvedClass == DisciplineClass.streetlifting ||
          resolvedClass == DisciplineClass.crossfit ||
          strengthGoalRoots.contains(e.rootId);
      final scheme = schemeFor(
        t,
        SchemeInputs(
          level: levelOfAbility(a),
          margin: margin,
          strengthFocus: strengthFocus,
          goalLift: goalLift,
          cautious: cautious,
          senior: senior,
          maxReps: maxRepsOf[e.id],
          maxHoldSeconds: maxHoldOf[e.id],
        ),
        params,
      );

      // Jours faisables : matériel, lieu, durée minimale.
      final needsWarmup =
          t.kind.isResistance ||
          t.kind == SlotKind.conditioning ||
          t.kind == SlotKind.cardioHard;
      var mask = 0;
      var equipped = false;
      for (final day in days) {
        final place = day.place;
        final placeOk = place == null
            ? e.places.any(profile.places.contains)
            : e.places.contains(place);
        if (!placeOk || !e.feasibleWith(day.equipment)) {
          continue;
        }
        equipped = true;
        final least =
            scheme.secondsFor(scheme.minSets) +
            (needsWarmup ? day.warmupSeconds : 0);
        if (least <= day.seconds) {
          mask |= 1 << day.index;
        }
      }
      if (round > 0) {
        mask &= fallbackDays;
      }
      if (rejection == null && mask == 0) {
        rejection = equipped ? Rejections.time : Rejections.equipment;
      }
      final why = rejection;
      final selectable = why == null;
      if (why != null) {
        if (round == 0) {
          rejections[e.id] = why;
        }
        if (!isForced) {
          continue;
        }
      } else if (round > 0) {
        rejections.remove(e.id);
      }

      final groupsOut = <int>[];
      final valuesOut = <int>[];
      if (t.kind.isResistance) {
        for (final g in MuscleGroup.values) {
          final credit = t.groupCredits[g.index];
          if (credit <= 0) {
            continue;
          }
          // Les muscles secondaires ne comptent (pour une demi-série) que
          // dans les mouvements polyarticulaires, où ils sont de vrais
          // synergistes ; un gainage ou une isolation ne crédite que ses
          // muscles principaux.
          if (credit < 2 &&
              (t.kind == SlotKind.core || t.kind == SlotKind.accessory)) {
            continue;
          }
          groupsOut.add(g.index);
          valuesOut.add(credit);
        }
      }
      var push = 0;
      var pull = 0;
      var knee = 0;
      var hip = 0;
      var cover = 0;
      switch (t.balance) {
        case BalanceClass.pushHorizontal:
          push = 2;
          cover = 1;
        case BalanceClass.pushVertical:
          push = 2;
          cover = 2;
        case BalanceClass.pullHorizontal:
          pull = 2;
          cover = 4;
        case BalanceClass.pullVertical:
          pull = 2;
          cover = 8;
        case BalanceClass.pullThenPush:
          push = 1;
          pull = 1;
          cover = 8;
        case BalanceClass.knee:
          knee = 2;
          cover = 16;
        case BalanceClass.hip:
          hip = 2;
          cover = 32;
        case BalanceClass.core:
          cover = 64;
        case BalanceClass.none:
          break;
      }
      if (selectable) {
        coverable |= cover;
        if (liked.contains(e.id)) {
          likedInPool++;
        }
        if (known) {
          knownInPool++;
        }
        for (var j = 0; j < goals.length; j++) {
          if (support[j] == 100) {
            exactSelectable[j] = true;
          }
          if (support[j] > goalBest[j]) {
            goalBest[j] = support[j];
          }
        }
        for (var k = 0; k < groupsOut.length; k++) {
          if (valuesOut[k] == 2) {
            trainable.add(groupsOut[k]);
          }
        }
      }

      // Adéquation : mouvement de base de sa famille, ni trop facile ni
      // assisté sans besoin.
      // Mouvement de base : racine de sa chaîne (ou proche), et chaîne
      // fournie — neuf variantes et plus valent 1, un exercice seul 0,5.
      final depthFactor = e.depth == 0 ? 1.0 : (e.depth == 1 ? 0.7 : 0.5);
      final size = t.familySize > 8 ? 8 : t.familySize;
      final canonical = depthFactor * (0.5 + 0.5 * (size - 1) / 7);
      var challenge = 1.0;
      if (t.kind.isResistance && !scheme.loaded) {
        challenge = margin <= 2
            ? 1.0
            : (margin == 3 ? 0.7 : (margin == 4 ? 0.4 : 0.2));
        if (e.assisted && margin >= 2) {
          challenge *= 0.5;
        }
      }

      final root = rootIndex.putIfAbsent(e.rootId, () => rootIndex.length);
      final hash = fnvMix(fnv1a32(e.id), inputs.seed);
      final entry = PoolEntry._(
        index: pool.length,
        traits: t,
        cls: resolvedClass,
        affinity: affinity,
        scheme: scheme,
        dayMask: mask,
        selectable: selectable,
        goalSupport: List<int>.unmodifiable(support),
        liked: liked.contains(e.id),
        known: known,
        novel: t.technical && !known && e.difficulty >= a - 1,
        jointPenalty: penalty > 1 ? 1 : penalty,
        fit: 0.4 * canonical + 0.4 * challenge + (known ? 0.2 : 0.0),
        fallback: round > 0,
        staple:
            t.kind == SlotKind.compound ||
                t.kind == SlotKind.power ||
                t.kind.isSkill
            ? (goalLift || bestSupport >= 80 ? 1.0 : canonical)
            : 0.0,
        prioritySkill: t.kind.isSkill && (known || bestSupport >= 60),
        rootIndex: root,
        creditGroups: List<int>.unmodifiable(groupsOut),
        creditValues: List<int>.unmodifiable(valuesOut),
        heavyWeight: t.kind.isSkill
            ? 1
            : (t.kind.isResistance && t.kind != SlotKind.core ? 2 : 0),
        pushUnits: push,
        pullUnits: pull,
        kneeUnits: knee,
        hipUnits: hip,
        coverBits: cover,
        needsWarmup: needsWarmup,
        level: levelOfAbility(a),
        margin: margin,
        goalLift: goalLift,
        oneRmTotalKg: oneRmOf[e.id],
        oneRmEstimated: oneRmEstimated.contains(e.id),
        knownMaxReps: maxRepsOf[e.id],
        knownMaxHoldSeconds: maxHoldOf[e.id],
        tieBreak: hash / 4294967296.0,
      );
      indexById[e.id] = entry.index;
      pool.add(entry);
    }
  }

  // Bandes de volume.
  final bandLevel = cautious && globalLevel > 1 ? 1 : globalLevel;
  final (baseLow, baseHigh) = volumeBandsByLevel[bandLevel];
  var totalMinutes = 0;
  for (final d in days) {
    totalMinutes += d.minutes;
  }
  var weightSum = 0.0;
  for (final g in MuscleGroup.values) {
    if (g.major) {
      weightSum += g.weight;
    }
  }
  final capacity =
      totalMinutes * resistanceShare * params.creditsPerMinute / weightSum;
  final mid = (baseLow + baseHigh) / 2;
  var timeScale = capacity / mid;
  if (timeScale > 1) {
    timeScale = 1;
  }
  final scale = timeScale * inputs.volumeScale;
  final priority = <int>{};
  for (final g in goals) {
    if (g.goal == null) {
      continue;
    }
    final t = traits.of(g.exercise.id);
    for (final mg in MuscleGroup.values) {
      if (t.groupCredits[mg.index] == 2) {
        priority.add(mg.index);
      }
    }
  }
  final bandLow = <int>[];
  final bandHigh = <int>[];
  final groupWeight = <double>[];
  for (final g in MuscleGroup.values) {
    final high = (baseHigh * scale * 2).round();
    // Un groupe qu'aucun exercice admissible ne travaille directement
    // (matériel, niveau) n'a ni plancher ni poids : il ne peut pas compter.
    final reachable = trainable.contains(g.index);
    final low = g.major && reachable ? (baseLow * scale * 2).round() : 0;
    bandLow.add(low);
    // Jamais moins de cinq séries : la dose d'un seul exercice ne doit pas
    // déjà dépasser la bande d'un programme court.
    bandHigh.add(high < 10 ? 10 : high);
    groupWeight.add(
      !reachable
          ? 0
          : (g.major
                ? g.weight * (priority.contains(g.index) ? 1.5 : 1)
                : 0.25),
    );
  }

  return PlanContext._(
    catalog: catalog,
    traits: traits,
    profile: profile,
    params: params,
    seed: inputs.seed,
    startDate: inputs.startDate,
    days: List<DayInfo>.unmodifiable(days),
    targets: List<double>.unmodifiable(targets),
    pool: List<PoolEntry>.unmodifiable(pool),
    goals: List<GoalTarget>.unmodifiable(goals),
    goalExposureTarget: days.length >= 3 ? params.goalExposures : 1.0,
    ability: Map<AbilityGroup, int>.unmodifiable(ability),
    globalLevel: globalLevel,
    cautious: cautious,
    senior: senior,
    bandLow: List<int>.unmodifiable(bandLow),
    bandHigh: List<int>.unmodifiable(bandHigh),
    groupWeight: List<double>.unmodifiable(groupWeight),
    resistanceShare: resistanceShare,
    adjacentPairs: List<(int, int)>.unmodifiable(adjacent),
    requiredIds: Set<String>.unmodifiable(required),
    excludedIds: Set<String>.unmodifiable(excluded),
    likedCount: likedInPool > 4 ? 4 : likedInPool,
    knownCount: knownInPool > 6 ? 6 : knownInPool,
    hasPrioritySkill: pool.any((e) => e.selectable && e.prioritySkill),
    goalExactSelectable: List<bool>.unmodifiable(exactSelectable),
    goalBestSupport: List<int>.unmodifiable(goalBest),
    goalWeights: List<double>.unmodifiable(<double>[
      for (var j = 0; j < goals.length; j++)
        // Un objectif que rien dans le vivier ne sert ne pèse pas ; un
        // mouvement de compétition hors de portée pèse à la mesure de son
        // meilleur palier.
        goals[j].goalId != null
            ? (goalBest[j] >= 30 ? goals[j].weight : 0.0)
            : (goalBest[j] >= 50 ? goals[j].weight * goalBest[j] / 100 : 0.0),
    ]),
    rejections: Map<String, String>.unmodifiable(rejections),
    noveltyAllowance: globalLevel == 0 ? 2 : 3,
    rootCount: rootIndex.length,
    coverableBits: coverable,
    indexById: indexById,
  );
}

bool _descendsFrom(Catalog catalog, CatalogExercise e, String ancestorId) {
  var current = e;
  var steps = 0;
  while (current.variantOf != null && steps < 64) {
    if (current.variantOf == ancestorId) {
      return true;
    }
    current = catalog.exercise(current.variantOf!);
    steps++;
  }
  return false;
}

/// Facteur appliqué aux bandes de volume d'après le résumé d'adaptation :
/// 0,85 si l'assiduité est sous 60 % ou la forme sous 0,4 ; 1,1 si
/// l'assiduité atteint 90 %, la confiance 0,5 et la forme 0,6 ; 1 sinon.
double adaptationVolumeScale(AdaptationSummary? adaptation) {
  if (adaptation == null || adaptation.sessionsPlanned <= 0) {
    return 1;
  }
  final adherence = adaptation.sessionsCompleted / adaptation.sessionsPlanned;
  final readiness = adaptation.fatigue?.readiness;
  if (adherence < 0.6 || (readiness != null && readiness < 0.4)) {
    return 0.85;
  }
  if (adherence >= 0.9 &&
      adaptation.confidence >= 0.5 &&
      (readiness == null || readiness >= 0.6)) {
    return 1.1;
  }
  return 1;
}
