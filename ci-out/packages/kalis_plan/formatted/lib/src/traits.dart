/// Lecture du catalogue par le moteur : groupes musculaires du comptage de
/// volume, nature d'un exercice dans une séance, classes d'équilibre des
/// schémas. Ces traits ne dépendent que du catalogue, jamais du profil.
library;

import 'package:kalis_core/kalis_core.dart';

/// Groupe musculaire du comptage de volume hebdomadaire.
///
/// Les 56 muscles de la base sont regroupés comme les études de
/// dose-réponse comptent les séries (« par groupe musculaire »). Un groupe
/// majeur a une bande de volume ; un groupe mineur n'a qu'un plafond.
enum MuscleGroup {
  /// Pectoraux.
  chest('chest', true, 1.0),

  /// Deltoïde antérieur.
  deltAnterior('delt_anterior', true, 0.5),

  /// Deltoïde moyen.
  deltMiddle('delt_middle', true, 0.75),

  /// Deltoïde postérieur.
  deltPosterior('delt_posterior', true, 0.75),

  /// Grand dorsal et grand rond.
  lats('lats', true, 1.0),

  /// Haut du dos : trapèzes moyen et inférieur, rhomboïdes.
  upperBack('upper_back', true, 1.0),

  /// Fléchisseurs du coude.
  biceps('biceps', true, 0.75),

  /// Triceps.
  triceps('triceps', true, 0.75),

  /// Abdominaux.
  abs('abs', true, 0.75),

  /// Lombaires.
  lowerBack('lower_back', true, 0.5),

  /// Fessiers.
  glutes('glutes', true, 1.0),

  /// Quadriceps.
  quads('quads', true, 1.0),

  /// Ischio-jambiers.
  hamstrings('hamstrings', true, 1.0),

  /// Mollets.
  calves('calves', true, 0.5),

  /// Avant-bras.
  forearms('forearms', false, 0.0),

  /// Adducteurs.
  adductors('adductors', false, 0.0),

  /// Trapèze supérieur.
  upperTraps('upper_traps', false, 0.0);

  const MuscleGroup(this.code, this.major, this.weight);

  /// Code stable (paramètre `muscle` de `plan.muscle_volume`).
  final String code;

  /// Groupe majeur : il a une bande de volume.
  final bool major;

  /// Poids du groupe dans la composante de volume.
  final double weight;
}

/// Groupe de chaque muscle de la base ; un muscle absent n'est pas compté
/// (muscles profonds, du cou, du pied, stabilisateurs de la scapula).
const Map<String, MuscleGroup> muscleGroupOf = <String, MuscleGroup>{
  'grand pectoral (faisceau claviculaire)': MuscleGroup.chest,
  'grand pectoral (faisceau sternal)': MuscleGroup.chest,
  'grand pectoral (faisceau abdominal)': MuscleGroup.chest,
  'deltoïde antérieur': MuscleGroup.deltAnterior,
  'deltoïde moyen': MuscleGroup.deltMiddle,
  'deltoïde postérieur': MuscleGroup.deltPosterior,
  'grand dorsal': MuscleGroup.lats,
  'grand rond': MuscleGroup.lats,
  'trapèze supérieur': MuscleGroup.upperTraps,
  'élévateur de la scapula': MuscleGroup.upperTraps,
  'trapèze moyen': MuscleGroup.upperBack,
  'trapèze inférieur': MuscleGroup.upperBack,
  'rhomboïdes': MuscleGroup.upperBack,
  'érecteurs du rachis': MuscleGroup.lowerBack,
  'multifides': MuscleGroup.lowerBack,
  'carré des lombes': MuscleGroup.lowerBack,
  'biceps brachial': MuscleGroup.biceps,
  'brachial': MuscleGroup.biceps,
  'brachio-radial': MuscleGroup.biceps,
  'triceps brachial (chef long)': MuscleGroup.triceps,
  'triceps brachial (chefs latéral et médial)': MuscleGroup.triceps,
  'fléchisseurs du poignet': MuscleGroup.forearms,
  'extenseurs du poignet': MuscleGroup.forearms,
  'fléchisseurs des doigts': MuscleGroup.forearms,
  "grand droit de l'abdomen": MuscleGroup.abs,
  'obliques externes': MuscleGroup.abs,
  'obliques internes': MuscleGroup.abs,
  "transverse de l'abdomen": MuscleGroup.abs,
  'grand fessier': MuscleGroup.glutes,
  'moyen fessier': MuscleGroup.glutes,
  'petit fessier': MuscleGroup.glutes,
  'adducteurs': MuscleGroup.adductors,
  'quadriceps (droit fémoral)': MuscleGroup.quads,
  'quadriceps (vastes)': MuscleGroup.quads,
  'ischio-jambiers': MuscleGroup.hamstrings,
  'gastrocnémiens': MuscleGroup.calves,
  'soléaire': MuscleGroup.calves,
};

/// Région du corps couverte par un exercice de mobilité.
enum MobilityRegion {
  /// Épaules et poitrine.
  shoulders,

  /// Dos haut, grand dorsal, rachis thoracique.
  upperSpine,

  /// Bas du dos et tronc.
  trunk,

  /// Hanches (fléchisseurs, fessiers, rotateurs).
  hips,

  /// Arrière des cuisses.
  hamstrings,

  /// Avant et intérieur des cuisses.
  thighs,

  /// Mollets, chevilles, pieds.
  ankles,

  /// Poignets, coudes, avant-bras.
  wrists,

  /// Cou.
  neck,
}

const Map<String, MobilityRegion> _regionOfMuscle = <String, MobilityRegion>{
  'grand pectoral (faisceau claviculaire)': MobilityRegion.shoulders,
  'grand pectoral (faisceau sternal)': MobilityRegion.shoulders,
  'grand pectoral (faisceau abdominal)': MobilityRegion.shoulders,
  'petit pectoral': MobilityRegion.shoulders,
  'deltoïde antérieur': MobilityRegion.shoulders,
  'deltoïde moyen': MobilityRegion.shoulders,
  'deltoïde postérieur': MobilityRegion.shoulders,
  'coiffe des rotateurs': MobilityRegion.shoulders,
  'grand dorsal': MobilityRegion.upperSpine,
  'grand rond': MobilityRegion.upperSpine,
  'trapèze moyen': MobilityRegion.upperSpine,
  'trapèze inférieur': MobilityRegion.upperSpine,
  'rhomboïdes': MobilityRegion.upperSpine,
  'dentelé antérieur': MobilityRegion.upperSpine,
  'trapèze supérieur': MobilityRegion.neck,
  'élévateur de la scapula': MobilityRegion.neck,
  'sterno-cléido-mastoïdien': MobilityRegion.neck,
  'fléchisseurs profonds du cou': MobilityRegion.neck,
  'extenseurs du cou': MobilityRegion.neck,
  'érecteurs du rachis': MobilityRegion.trunk,
  'multifides': MobilityRegion.trunk,
  'carré des lombes': MobilityRegion.trunk,
  "grand droit de l'abdomen": MobilityRegion.trunk,
  'obliques externes': MobilityRegion.trunk,
  'obliques internes': MobilityRegion.trunk,
  'psoas-iliaque': MobilityRegion.hips,
  'grand fessier': MobilityRegion.hips,
  'moyen fessier': MobilityRegion.hips,
  'petit fessier': MobilityRegion.hips,
  'tenseur du fascia lata': MobilityRegion.hips,
  'rotateurs externes de hanche': MobilityRegion.hips,
  'ischio-jambiers': MobilityRegion.hamstrings,
  'adducteurs': MobilityRegion.thighs,
  'quadriceps (droit fémoral)': MobilityRegion.thighs,
  'quadriceps (vastes)': MobilityRegion.thighs,
  'gastrocnémiens': MobilityRegion.ankles,
  'soléaire': MobilityRegion.ankles,
  'tibial antérieur': MobilityRegion.ankles,
  'fibulaires': MobilityRegion.ankles,
  'muscles intrinsèques du pied': MobilityRegion.ankles,
  'fléchisseurs du poignet': MobilityRegion.wrists,
  'extenseurs du poignet': MobilityRegion.wrists,
  'fléchisseurs des doigts': MobilityRegion.wrists,
  "pronateurs de l'avant-bras": MobilityRegion.wrists,
  'supinateur': MobilityRegion.wrists,
  'biceps brachial': MobilityRegion.wrists,
  'triceps brachial (chef long)': MobilityRegion.shoulders,
};

/// Nature d'un exercice dans une séance. Elle fixe l'ordre de la séance,
/// le modèle de prescription et le rôle affiché.
enum SlotKind {
  /// Figure statique tenue (planche, front lever, équilibre…).
  skillStatic(0),

  /// Figure ou transition dynamique (muscle-up, HSPU, freestyle).
  skillDynamic(0),

  /// Puissance : haltérophilie, pliométrie, balistique.
  power(1),

  /// Mouvement polyarticulaire de force.
  compound(2),

  /// Isolation et assistance.
  accessory(3),

  /// Tronc et gainage.
  core(4),

  /// Élément d'une pièce de conditionnement (CrossFit).
  conditioning(5),

  /// Cardio à haute intensité (fractionné, sprints, seuil).
  cardioHard(5),

  /// Cardio à basse intensité (endurance fondamentale, marche).
  cardioEasy(5),

  /// Mobilité, étirements, récupération.
  mobility(6);

  const SlotKind(this.orderRank);

  /// Rang dans la séance : figures et puissance, puis polyarticulaires,
  /// isolation, tronc, conditionnement et cardio, mobilité.
  final int orderRank;

  /// Vrai pour un travail de renforcement compté dans les volumes par
  /// muscle et dans la règle des 48 heures.
  bool get isResistance =>
      this == compound ||
      this == accessory ||
      this == core ||
      this == power ||
      this == skillStatic ||
      this == skillDynamic;

  /// Vrai pour une figure (pratique technique).
  bool get isSkill => this == skillStatic || this == skillDynamic;

  /// Vrai pour le cardio.
  bool get isCardio => this == cardioHard || this == cardioEasy;
}

/// Classe d'un exercice dans l'équilibre des schémas.
enum BalanceClass {
  /// Poussée horizontale.
  pushHorizontal,

  /// Poussée verticale (au-dessus de la tête, dips, appui renversé).
  pushVertical,

  /// Tirage horizontal.
  pullHorizontal,

  /// Tirage vertical.
  pullVertical,

  /// Tirage puis poussée (muscle-up).
  pullThenPush,

  /// Dominante genou (squat, fente, extension de genou).
  knee,

  /// Chaîne postérieure (charnière, extension de hanche, ischio-jambiers).
  hip,

  /// Tronc.
  core,

  /// Hors équilibre (isolation des bras, cardio, mobilité…).
  none,
}

/// Groupe de niveau : le niveau déclaré sur un mouvement vaut pour les
/// schémas de son groupe.
enum AbilityGroup {
  /// Poussées.
  push,

  /// Tirages.
  pull,

  /// Jambes.
  legs,

  /// Tronc.
  core,

  /// Puissance et haltérophilie.
  power,

  /// Cardio et conditionnement.
  cardio,

  /// Mobilité.
  mobility,
}

/// Traits d'un exercice du catalogue.
final class ExerciseTraits {
  ExerciseTraits._({
    required this.index,
    required this.exercise,
    required this.kind,
    required this.balance,
    required this.ability,
    required this.groupCredits,
    required this.regionMask,
    required this.stimulusFatigue,
    required this.impact,
    required this.technical,
    required this.mainEquipment,
    required this.intervalMeters,
  });

  /// Rang dans `Catalog.exercises`.
  final int index;

  /// Exercice.
  final CatalogExercise exercise;

  /// Nature dans la séance.
  final SlotKind kind;

  /// Classe d'équilibre des schémas.
  final BalanceClass balance;

  /// Groupe de niveau.
  final AbilityGroup ability;

  /// Crédit de série par groupe musculaire, en demi-séries, indexé par
  /// `MuscleGroup.index` : 2 = muscle principal (série directe), 1 = muscle
  /// secondaire (demi-série), 0 sinon. Les stabilisateurs ne comptent pas.
  final List<int> groupCredits;

  /// Régions de mobilité couvertes (bits de `MobilityRegion.index`).
  final int regionMask;

  /// Rapport stimulus / fatigue, de 0 à 1, ou −1 hors renforcement.
  final double stimulusFatigue;

  /// Exercice à impact ou explosif (sauts, sprints, haltérophilie).
  final bool impact;

  /// Exercice technique : une nouveauté compte pour l'apprentissage.
  final bool technical;

  /// Premier matériel bloquant de l'exercice, ou `null`.
  final String? mainEquipment;

  /// Distance d'une répétition lue dans l'identifiant (`…-400m`), ou 0.
  final int intervalMeters;

  /// Crédit du groupe [group], en demi-séries.
  int creditOf(MuscleGroup group) => groupCredits[group.index];
}

/// Traits de tous les exercices d'un catalogue, calculés une fois.
final class CatalogTraits {
  CatalogTraits._(this.catalog, this.all, this._byId);

  /// Traits du catalogue [catalog] (mis en cache par instance).
  factory CatalogTraits.of(Catalog catalog) {
    final cached = _cache[catalog];
    if (cached != null) {
      return cached;
    }
    final groupOfIndex = <MuscleGroup?>[
      for (final name in catalog.muscles) muscleGroupOf[name],
    ];
    final all = <ExerciseTraits>[];
    final byId = <String, ExerciseTraits>{};
    for (var i = 0; i < catalog.exercises.length; i++) {
      final t = _traitsOf(i, catalog.exercises[i], groupOfIndex);
      all.add(t);
      byId[t.exercise.id] = t;
    }
    final built = CatalogTraits._(
      catalog,
      List<ExerciseTraits>.unmodifiable(all),
      byId,
    );
    _cache[catalog] = built;
    return built;
  }

  static final Expando<CatalogTraits> _cache = Expando<CatalogTraits>();

  /// Catalogue.
  final Catalog catalog;

  /// Traits, dans l'ordre du catalogue.
  final List<ExerciseTraits> all;

  final Map<String, ExerciseTraits> _byId;

  /// Traits de l'exercice [id], ou `null`.
  ExerciseTraits? find(String id) => _byId[id];

  /// Traits de l'exercice [id] ; [ArgumentError] s'il est inconnu.
  ExerciseTraits of(String id) {
    final t = _byId[id];
    if (t == null) {
      throw ArgumentError.value(id, 'id', 'exercice inconnu du catalogue');
    }
    return t;
  }
}

final RegExp _metersPattern = RegExp(r'-(\d{2,4})m$');

ExerciseTraits _traitsOf(
  int index,
  CatalogExercise e,
  List<MuscleGroup?> groupOfIndex,
) {
  final credits = List<int>.filled(MuscleGroup.values.length, 0);
  for (var i = 0; i < e.muscleIndices.length; i++) {
    final group = groupOfIndex[e.muscleIndices[i]];
    if (group == null) {
      continue;
    }
    final w = e.muscleWeights[i];
    final credit = w >= 0.99 ? 2 : (w >= 0.49 ? 1 : 0);
    if (credit > credits[group.index]) {
      credits[group.index] = credit;
    }
  }
  final kind = slotKindOf(e);
  var mask = 0;
  if (kind == SlotKind.mobility) {
    final names = e.stretchedMuscles.isEmpty
        ? e.primaryMuscles
        : e.stretchedMuscles;
    for (final name in names) {
      final region = _regionOfMuscle[name];
      if (region != null) {
        mask |= 1 << region.index;
      }
    }
  }
  var sfr = -1.0;
  if (kind.isResistance) {
    var stimulus = 0.0;
    for (final g in MuscleGroup.values) {
      if (g.major) {
        stimulus += credits[g.index] / 2;
      }
    }
    if (stimulus > 4) {
      stimulus = 4;
    }
    final cost = e.systemicFatigue + 0.5 * (e.localFatigue - 3);
    sfr = stimulus / (cost < 1 ? 1 : cost) / 1.5;
    if (sfr > 1) {
      sfr = 1;
    }
  }
  final p = e.pattern;
  final impact =
      p == MovementPattern.pliometrie ||
      p == MovementPattern.sprint ||
      p == MovementPattern.halterophilie ||
      p == MovementPattern.cordeASauter ||
      e.contractionMode == ContractionMode.explosive;
  String? mainEquipment;
  for (final item in e.equipment) {
    if (!alwaysAvailableEquipment.contains(item)) {
      mainEquipment = item;
      break;
    }
  }
  final meters = _metersPattern.firstMatch(e.id);
  return ExerciseTraits._(
    index: index,
    exercise: e,
    kind: kind,
    balance: balanceClassOf(e, kind),
    ability: abilityGroupOf(e),
    groupCredits: List<int>.unmodifiable(credits),
    regionMask: mask,
    stimulusFatigue: sfr,
    impact: impact,
    technical:
        kind.isSkill ||
        p == MovementPattern.halterophilie ||
        p == MovementPattern.gymnastiqueCrossfit,
    mainEquipment: mainEquipment,
    intervalMeters: meters == null ? 0 : int.parse(meters.group(1)!),
  );
}

const Set<MovementPattern> _corePatterns = <MovementPattern>{
  MovementPattern.gainageAntiExtension,
  MovementPattern.gainageAntiFlexionLaterale,
  MovementPattern.gainageAntiRotation,
  MovementPattern.flexionTronc,
  MovementPattern.rotationTronc,
  MovementPattern.flexionHanche,
  MovementPattern.extensionRachis,
};

const Set<MovementPattern> _powerPatterns = <MovementPattern>{
  MovementPattern.halterophilie,
  MovementPattern.pliometrie,
  MovementPattern.balistique,
};

const Set<MovementPattern> _staticFigures = <MovementPattern>{
  MovementPattern.figureStatiqueMixte,
  MovementPattern.figureStatiquePoussee,
  MovementPattern.figureStatiqueTirage,
};

const Set<MovementPattern> _dynamicFigures = <MovementPattern>{
  MovementPattern.figureDynamiquePoussee,
  MovementPattern.figureDynamiqueTirage,
  MovementPattern.freestyle,
};

/// Nature de l'exercice [e] dans une séance.
SlotKind slotKindOf(CatalogExercise e) {
  final p = e.pattern;
  if (e.discipline == CatalogDiscipline.mobility) {
    return SlotKind.mobility;
  }
  if (e.discipline == CatalogDiscipline.cardio) {
    final hard =
        ((p == MovementPattern.cardioFractionne ||
                p == MovementPattern.sprint) &&
            e.systemicFatigue >= 4) ||
        e.id.contains('seuil') ||
        (p == MovementPattern.cordeASauter && e.difficulty >= 4);
    return hard ? SlotKind.cardioHard : SlotKind.cardioEasy;
  }
  if (e.discipline == CatalogDiscipline.crossfit) {
    return p == MovementPattern.halterophilie
        ? SlotKind.power
        : SlotKind.conditioning;
  }
  final weighted = e.discipline == CatalogDiscipline.streetlifting;
  final held = e.unit == MeasureUnit.seconds;
  if (_staticFigures.contains(p)) {
    return SlotKind.skillStatic;
  }
  if (_dynamicFigures.contains(p)) {
    return SlotKind.skillDynamic;
  }
  if (p == MovementPattern.equilibreMains) {
    return held ? SlotKind.skillStatic : SlotKind.skillDynamic;
  }
  if (p == MovementPattern.transitionMuscleUp) {
    if (weighted) {
      return SlotKind.compound;
    }
    return held ? SlotKind.skillStatic : SlotKind.skillDynamic;
  }
  if (p == MovementPattern.compression) {
    return weighted || !held ? SlotKind.core : SlotKind.skillStatic;
  }
  if (_powerPatterns.contains(p)) {
    return SlotKind.power;
  }
  if (_corePatterns.contains(p)) {
    return SlotKind.core;
  }
  return e.articularity == Articularity.multiJoint
      ? SlotKind.compound
      : SlotKind.accessory;
}

const Map<MovementPattern, BalanceClass> _balanceOfPattern =
    <MovementPattern, BalanceClass>{
      MovementPattern.pousseeHorizontale: BalanceClass.pushHorizontal,
      MovementPattern.pousseeInclinee: BalanceClass.pushHorizontal,
      MovementPattern.isolationPectoraux: BalanceClass.pushHorizontal,
      MovementPattern.figureStatiquePoussee: BalanceClass.pushHorizontal,
      MovementPattern.pousseeVerticaleBasse: BalanceClass.pushVertical,
      MovementPattern.pousseeVerticaleHaute: BalanceClass.pushVertical,
      MovementPattern.figureDynamiquePoussee: BalanceClass.pushVertical,
      MovementPattern.equilibreMains: BalanceClass.pushVertical,
      MovementPattern.tirageHorizontal: BalanceClass.pullHorizontal,
      MovementPattern.isolationDos: BalanceClass.pullHorizontal,
      MovementPattern.figureStatiqueTirage: BalanceClass.pullHorizontal,
      MovementPattern.tirageVertical: BalanceClass.pullVertical,
      MovementPattern.figureDynamiqueTirage: BalanceClass.pullVertical,
      MovementPattern.transitionMuscleUp: BalanceClass.pullThenPush,
      MovementPattern.squat: BalanceClass.knee,
      MovementPattern.fente: BalanceClass.knee,
      MovementPattern.extensionGenou: BalanceClass.knee,
      MovementPattern.charniereHanche: BalanceClass.hip,
      MovementPattern.extensionHanche: BalanceClass.hip,
      MovementPattern.flexionGenou: BalanceClass.hip,
      MovementPattern.gainageAntiExtension: BalanceClass.core,
      MovementPattern.gainageAntiFlexionLaterale: BalanceClass.core,
      MovementPattern.gainageAntiRotation: BalanceClass.core,
      MovementPattern.flexionTronc: BalanceClass.core,
      MovementPattern.rotationTronc: BalanceClass.core,
      MovementPattern.flexionHanche: BalanceClass.core,
      MovementPattern.extensionRachis: BalanceClass.core,
      MovementPattern.compression: BalanceClass.core,
      MovementPattern.figureStatiqueMixte: BalanceClass.core,
    };

/// Classe d'équilibre des schémas de l'exercice [e].
BalanceClass balanceClassOf(CatalogExercise e, SlotKind kind) {
  if (!kind.isResistance) {
    return BalanceClass.none;
  }
  return _balanceOfPattern[e.pattern] ?? BalanceClass.none;
}

const Map<MovementFamily, AbilityGroup> _abilityOfFamily =
    <MovementFamily, AbilityGroup>{
      MovementFamily.poussee: AbilityGroup.push,
      MovementFamily.tirage: AbilityGroup.pull,
      MovementFamily.jambesGenou: AbilityGroup.legs,
      MovementFamily.jambesHanche: AbilityGroup.legs,
      MovementFamily.isolationJambes: AbilityGroup.legs,
      MovementFamily.gainage: AbilityGroup.core,
      MovementFamily.tronc: AbilityGroup.core,
      MovementFamily.cou: AbilityGroup.core,
      MovementFamily.explosif: AbilityGroup.power,
      MovementFamily.porte: AbilityGroup.power,
      MovementFamily.cardio: AbilityGroup.cardio,
      MovementFamily.conditionnement: AbilityGroup.cardio,
      MovementFamily.mobilite: AbilityGroup.mobility,
      MovementFamily.recuperation: AbilityGroup.mobility,
    };

const Map<MovementPattern, AbilityGroup> _abilityOfPattern =
    <MovementPattern, AbilityGroup>{
      MovementPattern.isolationBiceps: AbilityGroup.pull,
      MovementPattern.isolationDos: AbilityGroup.pull,
      MovementPattern.isolationTrapezes: AbilityGroup.pull,
      MovementPattern.prehension: AbilityGroup.pull,
      MovementPattern.preparationScapulaire: AbilityGroup.pull,
      MovementPattern.figureStatiqueTirage: AbilityGroup.pull,
      MovementPattern.figureDynamiqueTirage: AbilityGroup.pull,
      MovementPattern.transitionMuscleUp: AbilityGroup.pull,
      MovementPattern.figureStatiqueMixte: AbilityGroup.core,
      MovementPattern.compression: AbilityGroup.core,
    };

/// Groupe de niveau de l'exercice [e] : par schéma d'abord (figures,
/// isolation), puis par famille ; les poussées par défaut.
AbilityGroup abilityGroupOf(CatalogExercise e) {
  if (e.discipline == CatalogDiscipline.mobility) {
    return AbilityGroup.mobility;
  }
  if (e.discipline == CatalogDiscipline.cardio) {
    return AbilityGroup.cardio;
  }
  return _abilityOfPattern[e.pattern] ??
      _abilityOfFamily[e.family] ??
      AbilityGroup.push;
}
