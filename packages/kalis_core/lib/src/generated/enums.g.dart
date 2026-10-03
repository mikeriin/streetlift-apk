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

/// Mesure d'un niveau déclaré : répétitions max, 1RM de charge externe en kg
/// (lest seul pour un exercice lesté), tenue max, temps sur une distance.
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

/// Grandeur visée par un objectif de performance : 1RM de charge externe en
/// kg, répétitions max (à une charge donnée si `loadKg`), tenue max, figure
/// débloquée, temps sur une distance, distance en une durée.
enum GoalMetric {
  oneRmKg('one_rm_kg'),
  maxReps('max_reps'),
  maxHoldSeconds('max_hold_seconds'),
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

/// Niveau global d'expérience déclaré (ordre croissant).
enum ExperienceLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced'),
  elite('elite');

  const ExperienceLevel(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ExperienceLevel fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ExperienceLevel : code inconnu', code);
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

/// Unité de la capacité estimée d'un exercice : 1RM de charge TOTALE en kg
/// (charge externe + fraction du poids du corps), répétitions max, tenue max,
/// vitesse.
enum CapacityUnit {
  oneRmKg('one_rm_kg'),
  maxReps('max_reps'),
  maxHoldSeconds('max_hold_seconds'),
  metersPerSecond('meters_per_second');

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

/// Suite donnée à une proposition (D5.6) : appliquée automatiquement,
/// acceptée, refusée, annulée.
enum ProposalStatus {
  autoApplied('auto_applied'),
  accepted('accepted'),
  refused('refused'),
  undone('undone');

  const ProposalStatus(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ProposalStatus fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ProposalStatus : code inconnu', code);
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

/// Événement de plaisir (D8.1). Les cinq derniers sont ajoutés en 0.3.0
/// (première fois, passage de niveau, nouveau rang, jalon d'objectif, quête
/// terminée).
enum DelightKind {
  record('record'),
  chest('chest'),
  weekStreak('week_streak'),
  sessionGrade('session_grade'),
  combo('combo'),
  ghost('ghost'),
  firstTime('first_time'),
  levelUp('level_up'),
  rankUp('rank_up'),
  goalMilestone('goal_milestone'),
  questCompleted('quest_completed');

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

/// Nature d'un record (même vocabulaire que les niveaux et les objectifs).
enum RecordKind {
  oneRmKg('one_rm_kg'),
  maxReps('max_reps'),
  maxHoldSeconds('max_hold_seconds'),
  volumeKg('volume_kg'),
  timeSeconds('time_seconds'),
  distanceMeters('distance_meters');

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

/// Motif d'une pause déclarée.
enum BreakReason {
  vacation('vacation'),
  illness('illness'),
  injury('injury'),
  other('other');

  const BreakReason(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BreakReason fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BreakReason : code inconnu', code);
  }
}

/// Ancienneté de pratique régulière de la discipline principale, sans compter
/// les arrêts longs (0.4.0, ordre croissant).
enum TrainingAge {
  under6Months('under_6_months'),
  months6To24('months_6_to_24'),
  years2To5('years_2_to_5'),
  over5Years('over_5_years');

  const TrainingAge(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static TrainingAge fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('TrainingAge : code inconnu', code);
  }
}

/// Interruption en cours au moment de répondre (0.4.0) : aucune (entraînement
/// régulier), entraînement allégé depuis quelques semaines, arrêt de moins de
/// 3 semaines, de 3 à 10 semaines, de 10 semaines à 6 mois, de 6 mois à 2
/// ans, de plus de 2 ans.
enum TrainingGap {
  none('none'),
  reduced('reduced'),
  under3Weeks('under_3_weeks'),
  weeks3To10('weeks_3_to_10'),
  weeks10To26('weeks_10_to_26'),
  months6To24('months_6_to_24'),
  over2Years('over_2_years');

  const TrainingGap(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static TrainingGap fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('TrainingGap : code inconnu', code);
  }
}

/// Séries dures par semaine sur un mouvement (à 3 répétitions ou moins de
/// l'échec) (0.4.0, ordre croissant).
enum HardSetsBand {
  under5('under_5'),
  sets5To9('sets_5_to_9'),
  sets10To14('sets_10_to_14'),
  sets15To20('sets_15_to_20'),
  over20('over_20');

  const HardSetsBand(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static HardSetsBand fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('HardSetsBand : code inconnu', code);
  }
}

/// Ce que l'utilisateur fait en ce moment (0.4.0) : du volume, du lourd, il
/// sort d'un pic ou d'une compétition, sans structure.
enum CurrentPhase {
  volume('volume'),
  heavy('heavy'),
  postPeak('post_peak'),
  unstructured('unstructured');

  const CurrentPhase(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static CurrentPhase fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('CurrentPhase : code inconnu', code);
  }
}

/// Ce que l'utilisateur cherche surtout en musculation (0.4.0) : du muscle,
/// de la force, les deux.
enum TrainingEmphasis {
  muscle('muscle'),
  strength('strength'),
  both('both');

  const TrainingEmphasis(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static TrainingEmphasis fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('TrainingEmphasis : code inconnu', code);
  }
}

/// Distance courue par semaine, en moyenne sur les 4 dernières semaines
/// (0.4.0, ordre croissant).
enum RunVolumeBand {
  none('none'),
  under10Km('under_10_km'),
  km10To20('km_10_to_20'),
  km20To35('km_20_to_35'),
  km35To50('km_35_to_50'),
  over50Km('over_50_km');

  const RunVolumeBand(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static RunVolumeBand fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('RunVolumeBand : code inconnu', code);
  }
}

/// Durée de la plus longue sortie récente (0.4.0, ordre croissant).
enum LongRunBand {
  under30Min('under_30_min'),
  min30To60('min_30_to_60'),
  min60To90('min_60_to_90'),
  over90Min('over_90_min');

  const LongRunBand(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static LongRunBand fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('LongRunBand : code inconnu', code);
  }
}

/// Temps passé à l'étape actuelle d'une figure (0.4.0, ordre croissant).
enum StepTenure {
  under1Month('under_1_month'),
  months1To3('months_1_to_3'),
  months3To6('months_3_to_6'),
  over6Months('over_6_months');

  const StepTenure(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static StepTenure fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('StepTenure : code inconnu', code);
  }
}

/// Durée habituelle de sommeil par nuit (0.4.0). Valeur HABITUELLE : la nuit
/// précédente est dans le bilan de séance (`HealthCheck.sleepHours`).
enum SleepBand {
  under6Hours('under_6_hours'),
  hours6To7('hours_6_to_7'),
  hours7Plus('hours_7_plus');

  const SleepBand(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SleepBand fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SleepBand : code inconnu', code);
  }
}

/// Stress habituel de la vie hors entraînement, ces dernières semaines
/// (0.4.0). Le stress du jour est dans le bilan de séance
/// (`HealthCheck.stress`).
enum StressBand {
  low('low'),
  moderate('moderate'),
  high('high');

  const StressBand(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static StressBand fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('StressBand : code inconnu', code);
  }
}

/// Charge physique habituelle du métier ou des journées (0.4.0) : assis,
/// debout ou en mouvement, travail physique lourd (port de charges).
enum OccupationalLoad {
  seated('seated'),
  onFeet('on_feet'),
  heavy('heavy');

  const OccupationalLoad(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static OccupationalLoad fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('OccupationalLoad : code inconnu', code);
  }
}

/// Évolution voulue du poids de corps en ce moment (0.4.0).
enum BodyWeightGoal {
  lose('lose'),
  maintain('maintain'),
  gain('gain'),
  noGoal('no_goal');

  const BodyWeightGoal(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BodyWeightGoal fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BodyWeightGoal : code inconnu', code);
  }
}

/// Autre sport pratiqué régulièrement en plus du programme (0.4.0).
enum OtherSportKind {
  running('running'),
  cycling('cycling'),
  swimming('swimming'),
  otherEndurance('other_endurance'),
  teamSport('team_sport'),
  combatSport('combat_sport'),
  climbing('climbing'),
  racketSport('racket_sport'),
  otherStrength('other_strength'),
  other('other');

  const OtherSportKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static OtherSportKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('OtherSportKind : code inconnu', code);
  }
}

/// Grande région sollicitée (0.4.0) : jambes, tirage du haut du corps,
/// poussée du haut du corps, tronc, tout le corps.
enum BodyRegion {
  lowerBody('lower_body'),
  upperPull('upper_pull'),
  upperPush('upper_push'),
  trunk('trunk'),
  wholeBody('whole_body');

  const BodyRegion(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BodyRegion fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BodyRegion : code inconnu', code);
  }
}

/// Ancienneté d'une gêne déclarée (0.4.0) ; `past_resolved` : antécédent
/// ancien, sans gêne actuelle.
enum ConstraintSince {
  under6Weeks('under_6_weeks'),
  weeks6To12('weeks_6_to_12'),
  months3To12('months_3_to_12'),
  over12Months('over_12_months'),
  pastResolved('past_resolved');

  const ConstraintSince(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ConstraintSince fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ConstraintSince : code inconnu', code);
  }
}

/// Famille de mouvements qui réveille une gêne (0.4.0) : tirage bras fléchis
/// ; suspension ou tirage bras tendus ; poussée en appui (pompes, haut du
/// dips) ; appui bras tendus (planche, équilibre) ; au-dessus de la tête ;
/// flexion de genou (squat, fente) ; charnière de hanche ; prise ou poignet
/// en extension ; anneaux ; course ou sauts ; épaule en extension profonde
/// (bas du dips, transition du muscle-up, back lever) ; charge sur le dos
/// (barre lourde) ; coude tendu à fond sous charge ; tirage explosif.
enum AggravatingMovement {
  pullBentArm('pull_bent_arm'),
  hangStraightArm('hang_straight_arm'),
  pushSupport('push_support'),
  straightArmSupport('straight_arm_support'),
  overhead('overhead'),
  kneeFlexion('knee_flexion'),
  hipHinge('hip_hinge'),
  wristExtensionGrip('wrist_extension_grip'),
  rings('rings'),
  runningJumping('running_jumping'),
  deepShoulderExtension('deep_shoulder_extension'),
  axialLoading('axial_loading'),
  elbowLockout('elbow_lockout'),
  explosivePull('explosive_pull');

  const AggravatingMovement(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static AggravatingMovement fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('AggravatingMovement : code inconnu', code);
  }
}

/// Nature d'un test ou d'un record (0.4.0) : charge × répétitions (1
/// répétition = maximum), répétitions max, maintien max, temps sur une
/// distance, distance en une durée, volume imposé au meilleur temps.
enum BenchmarkKind {
  loadReps('load_reps'),
  maxReps('max_reps'),
  maxHold('max_hold'),
  timeTrial('time_trial'),
  distanceTrial('distance_trial'),
  repsForTime('reps_for_time');

  const BenchmarkKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BenchmarkKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BenchmarkKind : code inconnu', code);
  }
}

/// Origine d'un test ou d'un record (0.4.0) : déclaré par l'utilisateur, test
/// guidé, compétition, série d'entraînement retenue par le moteur.
enum BenchmarkSource {
  declared('declared'),
  guidedTest('guided_test'),
  competition('competition'),
  trainingSet('training_set');

  const BenchmarkSource(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static BenchmarkSource fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BenchmarkSource : code inconnu', code);
  }
}

/// Nature d'une échéance (0.4.0) : compétition de force à tentatives
/// (streetlifting), compétition de répétitions (sets & reps, endurance de
/// force), freestyle jugé, course, autre compétition, test personnel daté.
enum EventKind {
  strengthCompetition('strength_competition'),
  repsCompetition('reps_competition'),
  freestyleCompetition('freestyle_competition'),
  race('race'),
  otherCompetition('other_competition'),
  personalTest('personal_test');

  const EventKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static EventKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('EventKind : code inconnu', code);
  }
}

/// Priorité d'une échéance dans la saison (0.4.0) : principale (pic de
/// forme), secondaire, préparation (faite sans affûtage).
enum EventPriority {
  main('main'),
  secondary('secondary'),
  preparation('preparation');

  const EventPriority(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static EventPriority fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('EventPriority : code inconnu', code);
  }
}

/// Format d'une épreuve de répétitions (0.4.0) : maximum de répétitions,
/// maximum en un temps limité, volume imposé au meilleur temps, maintien le
/// plus long.
enum RepsEventMode {
  maxReps('max_reps'),
  maxRepsInTime('max_reps_in_time'),
  forTime('for_time'),
  maxHold('max_hold');

  const RepsEventMode(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static RepsEventMode fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('RepsEventMode : code inconnu', code);
  }
}

/// Point faible exprimé simplement (0.4.0) : bas du mouvement, milieu, fin
/// (verrouillage), départ arrêté, transition (muscle-up), prise, fatigue en
/// fin de série, équilibre, mobilité, vitesse.
enum WeakPointKind {
  bottom('bottom'),
  midRange('mid_range'),
  lockout('lockout'),
  deadStart('dead_start'),
  transition('transition'),
  grip('grip'),
  lateSetFatigue('late_set_fatigue'),
  balance('balance'),
  mobility('mobility'),
  speed('speed');

  const WeakPointKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static WeakPointKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('WeakPointKind : code inconnu', code);
  }
}

/// Cible d'une spécialisation (0.4.0) : un mouvement, une figure, un groupe
/// musculaire, un schéma de mouvement.
enum SpecializationKind {
  exercise('exercise'),
  skill('skill'),
  muscle('muscle'),
  pattern('pattern');

  const SpecializationKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SpecializationKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SpecializationKind : code inconnu', code);
  }
}

/// Sort du reste pendant une spécialisation (0.4.0) : entretenu à volume
/// réduit, dose minimale, mis en pause (hors objectifs).
enum MaintenancePolicy {
  maintain('maintain'),
  minimal('minimal'),
  pause('pause');

  const MaintenancePolicy(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static MaintenancePolicy fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('MaintenancePolicy : code inconnu', code);
  }
}

/// Technique de série (0.4.0) : normale, série de tête puis séries allégées,
/// clusters, rest-pause, myo-reps, dégressive, isométrie ou maintien,
/// excentrique accentuée, contraste, vagues, AMRAP, EMOM, densité, échelle,
/// pyramide, pratique de figure, volume imposé au meilleur temps.
enum SetTechniqueKind {
  standard('standard'),
  topSetBackoff('top_set_backoff'),
  cluster('cluster'),
  restPause('rest_pause'),
  myoReps('myo_reps'),
  dropSet('drop_set'),
  isometricHold('isometric_hold'),
  accentuatedEccentric('accentuated_eccentric'),
  contrast('contrast'),
  wave('wave'),
  amrap('amrap'),
  emom('emom'),
  density('density'),
  ladder('ladder'),
  pyramid('pyramid'),
  skillPractice('skill_practice'),
  forTime('for_time');

  const SetTechniqueKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SetTechniqueKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SetTechniqueKind : code inconnu', code);
  }
}

/// Rôle d'une série dans une technique (0.4.0) : normale, série de tête,
/// série allégée, palier de vague, test, tentative de compétition, montée
/// d'échauffement, marche d'échelle ou de pyramide, intervalle.
enum SetRole {
  straight('straight'),
  top('top'),
  backOff('back_off'),
  wave('wave'),
  test('test'),
  attempt('attempt'),
  warmup('warmup'),
  rung('rung'),
  interval('interval');

  const SetRole(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SetRole fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SetRole : code inconnu', code);
  }
}

/// Ce que désigne une intensité (0.4.0) : part du 1RM de charge totale ; part
/// d'un test de référence (répétitions max, maintien max…) ; répétitions en
/// réserve ; part d'une vitesse de référence ; lest en part du poids de corps
/// ; vitesse en mètres par seconde.
enum IntensityBasis {
  percentOneRm('percent_one_rm'),
  percentBenchmark('percent_benchmark'),
  rir('rir'),
  speedFraction('speed_fraction'),
  bodyweightFraction('bodyweight_fraction'),
  absoluteSpeed('absolute_speed');

  const IntensityBasis(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static IntensityBasis fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('IntensityBasis : code inconnu', code);
  }
}

/// Règle d'autorégulation portée par une prescription (0.4.0) : séries
/// allégées calculées sur la série de tête RÉALISÉE ; charge corrigée quand
/// le RIR sort de sa plage ; arrêt des séries quand le RIR passe sous un
/// plancher ; arrêt quand les répétitions chutent ; durée de maintien tirée
/// du meilleur maintien du jour ; dernière série ouverte ; arrêt quand la
/// propreté passe sous un plancher.
enum AutoregulationKind {
  backoffFromTopSet('backoff_from_top_set'),
  loadFromRir('load_from_rir'),
  stopAtRir('stop_at_rir'),
  stopOnRepDrop('stop_on_rep_drop'),
  holdFromBest('hold_from_best'),
  lastSetAmrap('last_set_amrap'),
  stopOnQualityDrop('stop_on_quality_drop');

  const AutoregulationKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static AutoregulationKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('AutoregulationKind : code inconnu', code);
  }
}

/// Nature de la récupération entre deux séries ou deux répétitions de course
/// (0.4.0) : arrêt, marche, trot.
enum RestMode {
  passive('passive'),
  walk('walk'),
  jog('jog');

  const RestMode(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static RestMode fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('RestMode : code inconnu', code);
  }
}

/// Format d'un groupe d'exercices enchaînés (0.4.0) : superset, circuit
/// (tours, repos entre les tours), tours au meilleur temps, maximum de tours
/// en un temps, un passage par intervalle, suite imposée faite une fois au
/// meilleur temps, intervalles (effort, récupération).
enum GroupFormat {
  superset('superset'),
  circuit('circuit'),
  roundsForTime('rounds_for_time'),
  amrap('amrap'),
  emom('emom'),
  chipper('chipper'),
  intervals('intervals');

  const GroupFormat(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static GroupFormat fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('GroupFormat : code inconnu', code);
  }
}

/// Cause d'une tentative manquée (0.4.0) : force, technique, décision
/// d'arbitre.
enum AttemptFailure {
  strength('strength'),
  technique('technique'),
  judging('judging');

  const AttemptFailure(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static AttemptFailure fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('AttemptFailure : code inconnu', code);
  }
}

/// Objectif du jour d'une compétition de force (0.4.0) : assurer un total,
/// viser le plus gros total, tenter un record.
enum EventObjective {
  secureTotal('secure_total'),
  maxTotal('max_total'),
  record('record');

  const EventObjective(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static EventObjective fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('EventObjective : code inconnu', code);
  }
}

/// Série ou séance de test (0.4.0) : série d'estimation sous-maximale
/// (répétitions + RIR), xRM, maximum sur une répétition, répétitions max,
/// maintien max, temps sur une distance, distance en une durée, simulation de
/// tentatives.
enum TestKind {
  amrapEstimate('amrap_estimate'),
  repMax('rep_max'),
  oneRm('one_rm'),
  maxReps('max_reps'),
  maxHold('max_hold'),
  timeTrial('time_trial'),
  distanceTrial('distance_trial'),
  attemptSimulation('attempt_simulation');

  const TestKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static TestKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('TestKind : code inconnu', code);
  }
}

/// Phase d'un plan de saison (0.4.0) ; `reintroduction` : reprise progressive
/// après une coupure.
enum SeasonPhaseKind {
  accumulation('accumulation'),
  intensification('intensification'),
  realization('realization'),
  taper('taper'),
  competition('competition'),
  transition('transition'),
  test('test'),
  deload('deload'),
  maintenance('maintenance'),
  reintroduction('reintroduction');

  const SeasonPhaseKind(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static SeasonPhaseKind fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('SeasonPhaseKind : code inconnu', code);
  }
}

/// Intention d'une semaine (0.4.0) ; complète `WeekKind`, qui reste
/// renseigné.
enum WeekIntent {
  intro('intro'),
  accumulation('accumulation'),
  intensification('intensification'),
  realization('realization'),
  deload('deload'),
  taper('taper'),
  test('test'),
  competition('competition'),
  transition('transition'),
  maintenance('maintenance');

  const WeekIntent(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static WeekIntent fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('WeekIntent : code inconnu', code);
  }
}

/// Ondulation dans la semaine (0.4.0) : jour lourd, moyen ou léger, pour une
/// séance ou pour un mouvement.
enum DayStress {
  heavy('heavy'),
  medium('medium'),
  light('light');

  const DayStress(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static DayStress fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('DayStress : code inconnu', code);
  }
}

/// Modèle d'ondulation d'un bloc (0.4.0) : aucune, d'une semaine à l'autre,
/// d'un jour à l'autre.
enum UndulationModel {
  none('none'),
  weekly('weekly'),
  daily('daily');

  const UndulationModel(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static UndulationModel fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('UndulationModel : code inconnu', code);
  }
}

/// Précision d'une proposition du moteur dynamique (0.4.0) ; complète
/// `ProposalKind`, qui reste renseigné.
enum ProposalDetail {
  skillStepUp('skill_step_up'),
  skillStepDown('skill_step_down'),
  techniqueChange('technique_change'),
  testScheduled('test_scheduled'),
  taperAdjust('taper_adjust'),
  specialization('specialization'),
  seasonUpdate('season_update');

  const ProposalDetail(this.code);

  /// Code stable utilisé dans le JSON.
  final String code;

  /// Valeur d'un code ; [FormatException] si le code est inconnu.
  static ProposalDetail fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('ProposalDetail : code inconnu', code);
  }
}
