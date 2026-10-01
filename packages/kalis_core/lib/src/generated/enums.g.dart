// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Discipline d'un exercice dans la base v1.1 (8 valeurs).
enum CatalogDiscipline {
  musculation('Musculation'),
  streetWorkout('Street workout'),
  streetlifting('Streetlifting'),
  calisthenicsStatic('Calisthénie statique'),
  calisthenicsDynamic('Calisthénie dynamique'),
  crossfit('CrossFit / WOD'),
  cardio('Cardio'),
  mobility('Mobilité');

  const CatalogDiscipline(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static CatalogDiscipline fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('CatalogDiscipline : code inconnu', code);
  }
}

/// Niveau d'un exercice dans la base (ordre croissant).
enum ExerciseLevel {
  beginner('Débutant'),
  intermediate('Intermédiaire'),
  advanced('Avancé'),
  elite('Élite');

  const ExerciseLevel(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ExerciseLevel fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ExerciseLevel : code inconnu', code);
  }
}

/// Schéma de mouvement calculé (56 valeurs).
enum MovementPattern {
  adducteursAbducteurs('adducteurs_abducteurs'),
  autoMassage('auto_massage'),
  balistique('balistique'),
  cardioContinu('cardio_continu'),
  cardioFractionne('cardio_fractionne'),
  charniereHanche('charniere_hanche'),
  compression('compression'),
  conditionnement('conditionnement'),
  cordeASauter('corde_a_sauter'),
  cou('cou'),
  equilibreMains('equilibre_mains'),
  etirementDynamique('etirement_dynamique'),
  etirementStatique('etirement_statique'),
  extensionGenou('extension_genou'),
  extensionHanche('extension_hanche'),
  extensionRachis('extension_rachis'),
  fente('fente'),
  figureDynamiquePoussee('figure_dynamique_poussee'),
  figureDynamiqueTirage('figure_dynamique_tirage'),
  figureStatiqueMixte('figure_statique_mixte'),
  figureStatiquePoussee('figure_statique_poussee'),
  figureStatiqueTirage('figure_statique_tirage'),
  flexionGenou('flexion_genou'),
  flexionHanche('flexion_hanche'),
  flexionTronc('flexion_tronc'),
  freestyle('freestyle'),
  gainageAntiExtension('gainage_anti_extension'),
  gainageAntiFlexionLaterale('gainage_anti_flexion_laterale'),
  gainageAntiRotation('gainage_anti_rotation'),
  gymnastiqueCrossfit('gymnastique_crossfit'),
  halterophilie('halterophilie'),
  isolationBiceps('isolation_biceps'),
  isolationDos('isolation_dos'),
  isolationEpaules('isolation_epaules'),
  isolationPectoraux('isolation_pectoraux'),
  isolationTrapezes('isolation_trapezes'),
  isolationTriceps('isolation_triceps'),
  marche('marche'),
  mobiliteArticulaire('mobilite_articulaire'),
  mollets('mollets'),
  pliometrie('pliometrie'),
  porte('porte'),
  pousseeHorizontale('poussee_horizontale'),
  pousseeInclinee('poussee_inclinee'),
  pousseeVerticaleBasse('poussee_verticale_basse'),
  pousseeVerticaleHaute('poussee_verticale_haute'),
  prehension('prehension'),
  preparationScapulaire('preparation_scapulaire'),
  respiration('respiration'),
  rotationTronc('rotation_tronc'),
  souplesse('souplesse'),
  sprint('sprint'),
  squat('squat'),
  tirageHorizontal('tirage_horizontal'),
  tirageVertical('tirage_vertical'),
  transitionMuscleUp('transition_muscle_up');

  const MovementPattern(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MovementPattern fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MovementPattern : code inconnu', code);
  }
}

/// Famille de schémas de mouvement (18 valeurs).
enum MovementFamily {
  cardio('cardio'),
  conditionnement('conditionnement'),
  cou('cou'),
  explosif('explosif'),
  figureDynamique('figure_dynamique'),
  figureStatique('figure_statique'),
  gainage('gainage'),
  isolationBras('isolation_bras'),
  isolationHaut('isolation_haut'),
  isolationJambes('isolation_jambes'),
  jambesGenou('jambes_genou'),
  jambesHanche('jambes_hanche'),
  mobilite('mobilite'),
  porte('porte'),
  poussee('poussee'),
  recuperation('recuperation'),
  tirage('tirage'),
  tronc('tronc');

  const MovementFamily(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MovementFamily fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MovementFamily : code inconnu', code);
  }
}

/// Plan dominant du mouvement.
enum MovementPlane {
  sagittal('sagittal'),
  frontal('frontal'),
  transversal('transversal'),
  multiple('multiple');

  const MovementPlane(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MovementPlane fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MovementPlane : code inconnu', code);
  }
}

/// Poly- ou mono-articulaire ; sans objet pour les tenues, le cardio, la
/// mobilité.
enum Articularity {
  multiJoint('polyarticulaire'),
  singleJoint('monoarticulaire'),
  notApplicable('non_applicable');

  const Articularity(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static Articularity fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('Articularity : code inconnu', code);
  }
}

/// Régime de contraction dominant.
enum ContractionMode {
  dynamicEffort('dynamique'),
  isometric('isometrique'),
  eccentric('excentrique'),
  explosive('explosif'),
  cyclic('cyclique'),
  passive('passif');

  const ContractionMode(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ContractionMode fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ContractionMode : code inconnu', code);
  }
}

/// Lieu d'entraînement.
enum Place {
  gym('salle'),
  home('maison'),
  outdoor('exterieur');

  const Place(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static Place fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('Place : code inconnu', code);
  }
}

/// Articulation suivie par les contraintes articulaires (7 valeurs).
enum Joint {
  shoulder('epaule'),
  elbow('coude'),
  wrist('poignet'),
  lumbar('lombaires'),
  knee('genou'),
  hip('hanche'),
  ankle('cheville');

  const Joint(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static Joint fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('Joint : code inconnu', code);
  }
}

/// Niveau de contrainte articulaire (ordre croissant).
enum JointStress {
  low('faible'),
  moderate('moyenne'),
  high('forte');

  const JointStress(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static JointStress fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('JointStress : code inconnu', code);
  }
}

/// Type de charge d'un exercice.
enum LoadType {
  none('aucune'),
  bodyweight('poids_du_corps'),
  addedWeight('lest'),
  barbell('barre'),
  dumbbells('halteres'),
  kettlebell('kettlebell'),
  machine('machine'),
  cable('poulie'),
  band('elastique'),
  other('autre');

  const LoadType(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static LoadType fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('LoadType : code inconnu', code);
  }
}

/// Unité principale d'une série (distance en mètres).
enum MeasureUnit {
  repetitions('repetitions'),
  seconds('secondes'),
  distance('distance'),
  calories('calories');

  const MeasureUnit(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MeasureUnit fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MeasureUnit : code inconnu', code);
  }
}

/// Latéralité de l'exercice.
enum Laterality {
  bilateral('bilateral'),
  unilateral('unilateral'),
  alternating('alterne');

  const Laterality(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static Laterality fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('Laterality : code inconnu', code);
  }
}

/// Origine de la fraction du poids du corps.
enum FractionSource {
  published('publiee'),
  derived('derivee'),
  estimated('estimee');

  const FractionSource(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static FractionSource fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('FractionSource : code inconnu', code);
  }
}

/// Sexe déclaré (standards de rang, D7.5).
enum Sex {
  female('female'),
  male('male'),
  undisclosed('undisclosed');

  const Sex(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static Sex fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('Sex : code inconnu', code);
  }
}

/// Discipline d'entraînement du profil (D3.1, 8 valeurs).
enum TrainingDiscipline {
  musculation('musculation'),
  streetWorkout('street_workout'),
  streetlifting('streetlifting'),
  calisthenics('calisthenics'),
  crossfit('crossfit'),
  cardio('cardio'),
  mobility('mobility'),
  generalFitness('general_fitness');

  const TrainingDiscipline(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static TrainingDiscipline fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('TrainingDiscipline : code inconnu', code);
  }
}

/// Composante du mode street (D3.3).
enum StreetStyle {
  streetlifting('streetlifting'),
  setsReps('sets_reps'),
  calisthenics('calisthenics');

  const StreetStyle(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static StreetStyle fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('StreetStyle : code inconnu', code);
  }
}

/// Mode assisté ou libre (D3.7, D5.6).
enum GuidanceMode {
  assisted('assisted'),
  free('free');

  const GuidanceMode(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static GuidanceMode fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('GuidanceMode : code inconnu', code);
  }
}

/// Zone du corps (blessures, limitations, douleurs).
enum BodyZone {
  neck('neck'),
  shoulder('shoulder'),
  elbow('elbow'),
  wristHand('wrist_hand'),
  upperBack('upper_back'),
  lowerBack('lower_back'),
  chest('chest'),
  abdomen('abdomen'),
  hip('hip'),
  thigh('thigh'),
  knee('knee'),
  lowerLeg('lower_leg'),
  ankleFoot('ankle_foot');

  const BodyZone(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BodyZone fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BodyZone : code inconnu', code);
  }
}

/// Côté du corps.
enum BodySide {
  left('left'),
  right('right'),
  both('both');

  const BodySide(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BodySide fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BodySide : code inconnu', code);
  }
}

/// Mesure d'un niveau déclaré : répétitions max, 1RM en kg, tenue max, temps
/// sur une distance.
enum LevelMeasure {
  maxReps('max_reps'),
  oneRmKg('one_rm_kg'),
  maxHoldSeconds('max_hold_seconds'),
  timeSeconds('time_seconds');

  const LevelMeasure(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static LevelMeasure fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('LevelMeasure : code inconnu', code);
  }
}

/// Nature d'un objectif (D3.8).
enum GoalKind {
  performance('performance'),
  habit('habit');

  const GoalKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static GoalKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('GoalKind : code inconnu', code);
  }
}

/// Objectif saisi ou suggéré par Koach.
enum GoalOrigin {
  user('user'),
  suggested('suggested');

  const GoalOrigin(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static GoalOrigin fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('GoalOrigin : code inconnu', code);
  }
}

/// Grandeur visée par un objectif de performance.
enum GoalMetric {
  oneRmKg('one_rm_kg'),
  maxReps('max_reps'),
  holdSeconds('hold_seconds'),
  skillUnlocked('skill_unlocked'),
  timeSeconds('time_seconds'),
  distanceMeters('distance_meters');

  const GoalMetric(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static GoalMetric fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('GoalMetric : code inconnu', code);
  }
}

/// Résultat du questionnaire santé L13 (référence, aucune réponse n'est
/// copiée).
enum HealthScreeningOutcome {
  standard('standard'),
  cautious('cautious'),
  notAnswered('not_answered');

  const HealthScreeningOutcome(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static HealthScreeningOutcome fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('HealthScreeningOutcome : code inconnu', code);
  }
}

/// Séance du programme, ou reprise de l'ancien journal de l'application.
enum SessionOrigin {
  program('program'),
  imported('imported');

  const SessionOrigin(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SessionOrigin fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SessionOrigin : code inconnu', code);
  }
}

/// Rôle d'une série.
enum SetKind {
  warmup('warmup'),
  work('work'),
  calibration('calibration'),
  test('test');

  const SetKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SetKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SetKind : code inconnu', code);
  }
}

/// Moment où la douleur est signalée.
enum PainPhase {
  before('before'),
  during('during'),
  after('after');

  const PainPhase(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static PainPhase fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('PainPhase : code inconnu', code);
  }
}

/// Rôle d'un exercice dans la séance.
enum SlotRole {
  main('main'),
  secondary('secondary'),
  accessory('accessory'),
  skill('skill'),
  core('core'),
  conditioning('conditioning'),
  mobility('mobility'),
  warmup('warmup'),
  cooldown('cooldown');

  const SlotRole(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SlotRole fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SlotRole : code inconnu', code);
  }
}

/// Verrou posé par la revue (D4.6).
enum LockKind {
  keepSlot('keep_slot'),
  requireExercise('require_exercise'),
  excludeExercise('exclude_exercise'),
  keepDay('keep_day');

  const LockKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static LockKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('LockKind : code inconnu', code);
  }
}

/// Action de revue de la passe 1 (D4.5).
enum ReviewKind {
  canDo('can_do'),
  cannotDo('cannot_do'),
  dislike('dislike'),
  add('add'),
  remove('remove'),
  replace('replace');

  const ReviewKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ReviewKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ReviewKind : code inconnu', code);
  }
}

/// Nature d'une variante proposée (3 ciblées + toutes).
enum VariantKind {
  easier('easier'),
  equivalent('equivalent'),
  otherEquipment('other_equipment'),
  other('other');

  const VariantKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static VariantKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('VariantKind : code inconnu', code);
  }
}

/// Changement typé d'un diff de programme.
enum ChangeKind {
  exerciseAdded('exercise_added'),
  exerciseRemoved('exercise_removed'),
  exerciseReplaced('exercise_replaced'),
  exerciseMoved('exercise_moved'),
  orderChanged('order_changed'),
  prescriptionChanged('prescription_changed'),
  dayAdded('day_added'),
  dayRemoved('day_removed');

  const ChangeKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ChangeKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ChangeKind : code inconnu', code);
  }
}

/// Nature d'une semaine du bloc.
enum WeekKind {
  intro('intro'),
  build('build'),
  deload('deload'),
  test('test');

  const WeekKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static WeekKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('WeekKind : code inconnu', code);
  }
}

/// Ce que désigne la charge d'une prescription.
enum LoadBasis {
  external('external'),
  bodyweight('bodyweight'),
  bodyweightPlusExternal('bodyweight_plus_external'),
  unloaded('unloaded');

  const LoadBasis(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static LoadBasis fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('LoadBasis : code inconnu', code);
  }
}

/// Portée d'une restructuration.
enum RestructureScope {
  session('session'),
  week('week'),
  block('block');

  const RestructureScope(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static RestructureScope fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('RestructureScope : code inconnu', code);
  }
}

/// Type de proposition du moteur dynamique.
enum ProposalKind {
  load('load'),
  reps('reps'),
  volume('volume'),
  exerciseSwap('exercise_swap'),
  sessionRestructure('session_restructure'),
  blockRestructure('block_restructure'),
  deload('deload'),
  painSparing('pain_sparing'),
  schedule('schedule');

  const ProposalKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ProposalKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ProposalKind : code inconnu', code);
  }
}

/// Portée d'une proposition.
enum ProposalScope {
  set('set'),
  exercise('exercise'),
  session('session'),
  week('week'),
  block('block');

  const ProposalScope(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ProposalScope fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ProposalScope : code inconnu', code);
  }
}

/// Niveau de déblocage des propositions (D5.7, ordre croissant).
enum UnlockLevel {
  loadsReps('loads_reps'),
  volume('volume'),
  exerciseSwap('exercise_swap'),
  sessionRestructure('session_restructure'),
  blockRestructure('block_restructure');

  const UnlockLevel(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static UnlockLevel fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('UnlockLevel : code inconnu', code);
  }
}

/// Ajustement d'une séance après le bilan santé.
enum AdjustmentKind {
  loadReduced('load_reduced'),
  setsReduced('sets_reduced'),
  exerciseSwapped('exercise_swapped'),
  exerciseRemoved('exercise_removed'),
  restIncreased('rest_increased'),
  loadIncreased('load_increased');

  const AdjustmentKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static AdjustmentKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('AdjustmentKind : code inconnu', code);
  }
}

/// Conseil pour la série suivante.
enum IntraSessionAction {
  keep('keep'),
  loadUp('load_up'),
  loadDown('load_down'),
  repsUp('reps_up'),
  repsDown('reps_down'),
  stopExercise('stop_exercise'),
  restMore('rest_more');

  const IntraSessionAction(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static IntraSessionAction fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('IntraSessionAction : code inconnu', code);
  }
}

/// Unité de la capacité estimée d'un exercice.
enum CapacityUnit {
  kgOneRm('kg_one_rm'),
  repsMax('reps_max'),
  secondsMax('seconds_max');

  const CapacityUnit(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static CapacityUnit fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('CapacityUnit : code inconnu', code);
  }
}

/// Origine d'un gain d'XP (D7.2).
enum XpSource {
  effort('effort'),
  consistency('consistency'),
  record('record'),
  milestone('milestone'),
  quest('quest');

  const XpSource(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static XpSource fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('XpSource : code inconnu', code);
  }
}

/// Attribut façon RPG (D7.5).
enum AthleteAttribute {
  strength('strength'),
  endurance('endurance'),
  power('power'),
  technique('technique'),
  mobility('mobility'),
  consistency('consistency');

  const AthleteAttribute(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static AthleteAttribute fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('AthleteAttribute : code inconnu', code);
  }
}

/// Rang d'un mouvement (ordre croissant).
enum MovementRankTier {
  unranked('unranked'),
  bronze('bronze'),
  silver('silver'),
  gold('gold'),
  platinum('platinum'),
  diamond('diamond'),
  elite('elite');

  const MovementRankTier(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MovementRankTier fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MovementRankTier : code inconnu', code);
  }
}

/// Famille de quête (D7.6).
enum QuestKind {
  daily('daily'),
  weekly('weekly'),
  campaign('campaign'),
  koach('koach');

  const QuestKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static QuestKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('QuestKind : code inconnu', code);
  }
}

/// État d'une quête.
enum QuestStatus {
  active('active'),
  completed('completed'),
  expired('expired');

  const QuestStatus(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static QuestStatus fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('QuestStatus : code inconnu', code);
  }
}

/// Origine d'un gain de Krédits.
enum KreditSource {
  quest('quest'),
  chest('chest'),
  levelUp('level_up'),
  milestone('milestone'),
  record('record');

  const KreditSource(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static KreditSource fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('KreditSource : code inconnu', code);
  }
}

/// Événement de plaisir (D8.1).
enum DelightKind {
  record('record'),
  chest('chest'),
  weekStreak('week_streak'),
  sessionGrade('session_grade'),
  combo('combo'),
  ghost('ghost');

  const DelightKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static DelightKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('DelightKind : code inconnu', code);
  }
}

/// Note de séance.
enum SessionGrade {
  s('s'),
  a('a'),
  b('b'),
  c('c');

  const SessionGrade(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SessionGrade fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SessionGrade : code inconnu', code);
  }
}

/// Nature d'un record.
enum RecordKind {
  oneRm('one_rm'),
  repMax('rep_max'),
  hold('hold'),
  volume('volume'),
  time('time'),
  distance('distance');

  const RecordKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static RecordKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('RecordKind : code inconnu', code);
  }
}
