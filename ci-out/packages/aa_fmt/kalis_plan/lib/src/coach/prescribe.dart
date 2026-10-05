/// Passe 2 du chemin street : le dosage de chaque emplacement, semaine par
/// semaine, selon sa méthode ; puis les garde-fous (plafond et montée du
/// volume, tenues bras tendus, hausse de charge, durée de la séance).
/// Chaque paramètre cite le principe du référentiel de `kalis_bench` qui le
/// fonde (CONTRAT.md, § 12).
library;

import 'package:kalis_core/kalis_core.dart';

import '../assemble.dart';
import '../pass2.dart' show defaultIncrement;
import '../traits.dart';
import '../version.dart';
import 'athlete.dart';
import 'model.dart';
import 'season.dart';
import 'skeleton.dart' show coachPushLadder, coachStepHold;
import 'tables.dart';

/// Codes des notes de coach (`plan.coach_note`, paramètre `note`).
abstract final class CoachNotes {
  /// Montée en charge avant la série de tête (`value` : séries de montée).
  static const String rampWarmup = 'ramp_warmup';

  /// Série de tête puis séries allégées (`value` : baisse en %).
  static const String topSetBackoff = 'top_set_backoff';

  /// Séance légère : vitesse et technique (`value` : part du 1RM).
  static const String speedWork = 'speed_work';

  /// Plan des tentatives : 91 %, 96 %, puis selon la deuxième (`value` :
  /// part du 1RM de la première barre).
  static const String attemptsPlan = 'attempts_plan';

  /// Barre d'ouverture répétée avant l'échéance (`value` : part du 1RM).
  static const String opener = 'opener';

  /// Entretien pendant une spécialisation (`value` : séries par semaine).
  static const String maintenance = 'maintenance';

  /// Départs au chrono (`value` : secondes entre deux départs).
  static const String everyMinute = 'every_minute';

  /// Technique à l'état frais, arrêt dès que la qualité baisse (`value` :
  /// qualité minimale sur 5).
  static const String qualityFirst = 'quality_first';

  /// Maintiens sous-maximaux (`value` : part du maintien maximal).
  static const String submaximalHold = 'submaximal_hold';

  /// Descente freinée (`value` : secondes de descente).
  static const String slowNegative = 'slow_negative';

  /// Traction complète au tempo lent (montée tirée, descente freinée).
  static const String slowTempo = 'slow_tempo';

  /// Jour de l'échéance (`value` : jours entre la séance et l'échéance).
  static const String eventDay = 'event_day';

  /// Séance de récupération après l'échéance (`value` : 0).
  static const String recovery = 'recovery';

  /// Réglage de la charge à la première séance (`value` : RIR visé).
  static const String calibrate = 'calibrate';

  /// Exercices enchaînés (`value` : repos entre les tours, en secondes).
  static const String superset = 'superset';

  /// Allure de conversation (`value` : minutes).
  static const String easyPace = 'easy_pace';

  /// Échauffement général (`value` : minutes).
  static const String generalWarmup = 'general_warmup';

  /// Volume réduit par la tolérance du profil (`value` : facteur).
  static const String toleranceVolume = 'tolerance_volume';

  /// Montée avant la série de tête au poids du corps (`value` : séries).
  static const String rampBodyweight = 'ramp_bodyweight';

  /// Règle d'ajustement de la charge (`value` : pas en %).
  static const String loadAdjust = 'load_adjust';

  /// Règle d'ajustement des répétitions (`value` : séances).
  static const String repsAdjust = 'reps_adjust';

  /// Usage des tests de fin de bloc (`value` : 0).
  static const String testUse = 'test_use';

  /// Simulation de l'épreuve (`value` : repos entre les ateliers, en s).
  static const String eventRehearsal = 'event_rehearsal';

  /// Rôle d'un exercice d'assistance : prévention (`value` : 0).
  static const String rolePrehab = 'role_prehab';

  /// Rôle : tirage horizontal.
  static const String roleRow = 'role_row';

  /// Rôle : chaîne postérieure.
  static const String rolePosterior = 'role_posterior';

  /// Rôle : jambes.
  static const String roleLegs = 'role_legs';

  /// Rôle : tronc.
  static const String roleCore = 'role_core';

  /// Rôle : fléchisseurs du coude.
  static const String roleElbow = 'role_elbow';

  /// Baisse du jour : une série de moins (`value` : séries retirées).
  static const String badDay = 'bad_day';

  /// Séance ou semaine manquée (`value` : baisse de volume à la reprise,
  /// en %).
  static const String missed = 'missed';

  /// Repère d'un test intermédiaire (`value` : valeur attendue).
  static const String checkpoint = 'checkpoint';

  /// Sécurités de la cage ou pareur au squat et au développé couché
  /// lourds (`value` : part du 1RM à partir de laquelle la note s'écrit).
  static const String safetyPins = 'safety_pins';

  /// Repère d'un objectif de répétitions sans lest au matériel (`value` :
  /// valeur attendue) : la surcharge passe par une variante plus dure
  /// (CP2, partie 0, boucle 2).
  static const String checkpointBody = 'checkpoint_body';

  /// Repère d'un objectif de maintien (`value` : secondes attendues) : le
  /// bloc suivant change de dose sur le levier.
  static const String checkpointHold = 'checkpoint_hold';

  /// Repère d'un objectif de 1RM (`value` : charge attendue, kg) : le bloc
  /// suivant est écrit sur le résultat du test.
  static const String checkpointLoad = 'checkpoint_load';

  /// Repère d'un objectif de pompes du débutant (`value` : répétitions
  /// attendues) : l'appui baisse d'un cran.
  static const String checkpointLadder = 'checkpoint_ladder';

  /// Hauteur d'appui de la pompe mains surélevées (`value` : crans de
  /// 10 cm à descendre) quand le maximum sur l'appui dépasse 15.
  static const String pushHeight = 'push_height';

  /// Repos avant un test (`value` : heures sans travail dur).
  static const String testRest = 'test_rest';

  /// Test de la descente la plus lente (`value` : secondes qui ouvrent
  /// l'essai d'une traction stricte).
  static const String negativeGate = 'negative_gate';

  /// Repos avant l'échéance (`value` : jours avant l'échéance).
  static const String restBeforeEvent = 'rest_before_event';

  /// Troisième tentative : la barre de l'objectif (`value` : charge
  /// externe visée, en kg).
  static const String attemptsGoal = 'attempts_goal';

  /// Activation à J−2 d'une épreuve de répétitions (`value` : part du
  /// maximum).
  static const String activation = 'activation';

  /// Reprise : la première semaine sert de test d'entrée (`value` :
  /// répétitions en réserve à garder).
  static const String reentryTest = 'reentry_test';

  /// Charge visée sous le poids du corps : série au poids du corps
  /// (`value` : part réelle du 1RM).
  static const String bodyweightFloor = 'bodyweight_floor';

  /// Amplitude partielle surchargée (`value` : part du 1RM complet).
  static const String overload = 'overload';

  /// Essai de traction stricte après le test de descente (`value` :
  /// répétitions de l'objectif).
  static const String strictAttempt = 'strict_attempt';

  /// Règle de douleur générale, sans zone déclarée (`value` : seuil
  /// d'arrêt sur 10).
  static const String painGeneral = 'pain_general';

  /// Signes d'arrêt immédiat (`value` : 0).
  static const String redFlags = 'red_flags';

  /// Version courte de la séance pour un jour chargé (`value` : minutes).
  static const String shortVersion = 'short_version';

  /// Choix de l'élastique d'assistance (`value` : répétitions du haut de
  /// la plage, + 100 quand l'athlète fait déjà une traction stricte).
  static const String bandChoice = 'band_choice';

  /// Consigne d'exécution (`value` : 1 traction, 2 dips, 3 muscle-up,
  /// 4 front lever, 5 planche, 6 pompe, 7 squat, 8 équilibre).
  static const String cue = 'cue';

  /// Allure des fractions (`value` : secondes pour 400 m).
  static const String intervalPace = 'interval_pace';

  /// Allure de l'objectif de course (`value` : secondes au kilomètre).
  static const String goalPace = 'goal_pace';

  /// Test chronométré de course (`value` : distance en mètres).
  static const String timeTrial = 'time_trial';

  /// Objectif de figure hors de portée du bloc : étape visée (`value` :
  /// semaines minimales par étape).
  static const String skillHorizon = 'skill_horizon';

  /// Marche hebdomadaire pour la perte de poids (`value` : minutes).
  static const String walking = 'walking';

  /// Entretien de la poussée quand l'objectif porte sur le tirage
  /// (`value` : séries par séance).
  static const String pushMaintenance = 'push_maintenance';

  /// Amorçage à l'avant-veille d'une épreuve de force (`value` : part du
  /// 1RM).
  static const String primer = 'primer';

  /// Série de recalage de fin de bloc (`value` : pas en %).
  static const String recalibrate = 'recalibrate';

  /// Étape suivante d'une figure, sous condition (`value` : secondes du
  /// critère de passage).
  static const String stepGate = 'step_gate';

  /// Essai maximal périodique d'un maintien (`value` : semaines entre deux
  /// essais).
  static const String maxAttempt = 'max_attempt';

  /// Maintien à mesurer à la première séance (`value` : part du maximum à
  /// travailler ensuite).
  static const String holdCalibrate = 'hold_calibrate';

  /// Charge de départ estimée d'après le maximum au poids du corps
  /// (`value` : charge externe en kg).
  static const String estimatedLoad = 'estimated_load';

  /// 1RM de travail relevé d'après le maximum de répétitions au poids du
  /// corps (`value` : charge totale retenue, en kg).
  static const String reconciled = 'reconciled';

  /// Charge progressive du tendon (`value` : douleur maximale sur 10).
  static const String tendonLoad = 'tendon_load';

  /// Retour progressif au tirage lesté (`value` : pas en kg).
  static const String pullReturn = 'pull_return';

  /// Séance allégée à deux jours d'un test (`value` : part du travail
  /// habituel).
  static const String easyBeforeTest = 'easy_before_test';

  /// Réductions du profil déjà appliquées aux chiffres (`value` : 0).
  static const String alreadyApplied = 'already_applied';

  /// Dernier lourd avant l'épreuve, dans les conditions du jour J
  /// (`value` : jours avant l'épreuve).
  static const String dressRehearsal = 'dress_rehearsal';

  /// Échelle des variantes de poussée (`value` : répétitions du bas de
  /// la plage).
  static const String pushLadder = 'push_ladder';

  /// Lest réglé sur le lest du 1RM quand la charge visée tombe sous le
  /// poids du corps (`value` : lest en kg).
  static const String smallLoad = 'small_load';

  /// Série d'entrée de reprise, écrite sur la ligne (`value` : réserve).
  static const String entrySet = 'entry_set';

  /// Pompe en descente freinée (`value` : secondes).
  static const String slowNegativePush = 'slow_negative_push';

  /// Rôle : avant-bras (tolérance du coude et du poignet).
  static const String roleForearm = 'role_forearm';

  /// Rôle : renforcement du coureur (mollets, rebonds).
  static const String roleRunner = 'role_runner';

  /// Série en repos-pause vers l'objectif de répétitions (`value` : total
  /// visé).
  static const String restPause = 'rest_pause';

  /// Objectif ambitieux (`value` : résultat probable).
  static const String ambitious = 'ambitious';

  /// Stratégie de la série maximale (`value` : répétition repère).
  static const String maxSetPlan = 'max_set_plan';

  /// Montée avant un maintien maximal (`value` : secondes de la montée).
  static const String holdRamp = 'hold_ramp';

  /// Suivi de l'assiduité et du poids (`value` : séances par semaine).
  static const String tracking = 'tracking';

  /// Catégorie de poids et pesée d'une épreuve de force (`value` : limite
  /// de la catégorie en kg ; négative pour une catégorie « plus de »).
  static const String weightClass = 'weight_class';

  /// Format d'une épreuve de répétitions à saisir (`value` : repos entre
  /// les ateliers supposé en attendant, en s).
  static const String eventFormat = 'event_format';

  /// Figure gardée en volume réduit sur une zone douloureuse au bloc
  /// précédent (`value` : douleur relevée sur 10).
  static const String painTrend = 'pain_trend';

  /// Plateau au dernier test d'un mouvement visé : changement de méthode
  /// (`value` : repère actuel en répétitions).
  static const String plateau = 'plateau';

  /// Séries dans la zone de l'épreuve, objectif de répétitions maximales
  /// (`value` : part du maximum, en %).
  static const String eventZone = 'event_zone';

  /// Montée avant le muscle-up (`value` : séries de tractions faciles).
  static const String rampMuscleUp = 'ramp_muscle_up';

  /// Douleur qui dure ou qui revient : mouvements provocants retirés,
  /// consultation (`value` : rang de la zone dans `BodyZone.values`).
  static const String painStop = 'pain_stop';

  /// Étape plus facile servie parce que la douleur écarte l'étape de
  /// travail (raison et critère de retour écrits ; `value` : 0).
  static const String painStep = 'pain_step';

  /// Reprise graduée après un arrêt (`value` : rang de la zone × 100 +
  /// palier de départ du bloc × 10 + dernier palier du bloc ; part rendue
  /// = 50 % + 10 % par palier).
  static const String painReturn = 'pain_return';

  /// Exercice en reprise graduée cette semaine (`value` : part du volume
  /// habituel).
  static const String painReturnItem = 'pain_return_item';

  /// Tenues vers le critère de passage de l'étape, une séance lourde par
  /// semaine en réalisation (`value` : secondes par tenue ; CP2, partie 0).
  static const String stepCriterion = 'step_criterion';

  /// Série repère de la première séance quand le record n'est pas un test
  /// récent (`value` : répétitions en réserve ; CP2, partie 0).
  static const String entryCheck = 'entry_check';

  /// Simulation du test d'un objectif de répétitions, dix jours avant
  /// (`value` : répétitions visées ; CP2, partie 0).
  static const String repsRehearsal = 'reps_rehearsal';

  /// Tous les codes.
  static const List<String> all = <String>[
    entryCheck,
    repsRehearsal,
    stepCriterion,
    plateau,
    eventZone,
    rampMuscleUp,
    painStop,
    painStep,
    painReturn,
    painReturnItem,
    painTrend,
    weightClass,
    eventFormat,
    entrySet,
    slowNegativePush,
    roleForearm,
    roleRunner,
    restPause,
    ambitious,
    maxSetPlan,
    holdRamp,
    tracking,
    smallLoad,
    pushLadder,
    dressRehearsal,
    primer,
    recalibrate,
    stepGate,
    maxAttempt,
    holdCalibrate,
    estimatedLoad,
    reconciled,
    tendonLoad,
    pullReturn,
    easyBeforeTest,
    alreadyApplied,
    attemptsGoal,
    activation,
    reentryTest,
    bodyweightFloor,
    overload,
    strictAttempt,
    painGeneral,
    redFlags,
    shortVersion,
    bandChoice,
    cue,
    intervalPace,
    goalPace,
    timeTrial,
    skillHorizon,
    walking,
    pushMaintenance,
    negativeGate,
    restBeforeEvent,
    badDay,
    missed,
    checkpoint,
    safetyPins,
    checkpointBody,
    checkpointHold,
    checkpointLoad,
    checkpointLadder,
    pushHeight,
    testRest,
    rampBodyweight,
    loadAdjust,
    repsAdjust,
    testUse,
    eventRehearsal,
    rolePrehab,
    roleRow,
    rolePosterior,
    roleLegs,
    roleCore,
    roleElbow,
    rampWarmup,
    topSetBackoff,
    speedWork,
    attemptsPlan,
    opener,
    maintenance,
    everyMinute,
    qualityFirst,
    submaximalHold,
    slowNegative,
    slowTempo,
    eventDay,
    recovery,
    calibrate,
    superset,
    easyPace,
    generalWarmup,
    toleranceVolume,
  ];
}

/// Exercice du test du chemin vers la première traction : la tenue menton
/// au-dessus de la barre, comptée en secondes (CX, correction 7).
const String coachGateExercise = 'cs-tenue-menton-barre-pronation';

/// Codes des règles de progression (`plan.progression_rule`, paramètre
/// `rule`).
abstract final class CoachRules {
  /// Double progression : monter les répétitions, puis la difficulté.
  static const String doubleProgression = 'double_progression';

  /// Charge : ajouter le pas quand la série de tête laisse la réserve
  /// prévue.
  static const String loadStep = 'load_step';

  /// Répétitions : une de plus par semaine sur la série de tête.
  static const String repStep = 'rep_step';

  /// Maintien : ajouter des secondes, puis passer à l'étape suivante.
  static const String holdStep = 'hold_step';

  /// Densité : une minute de plus par semaine.
  static const String densityStep = 'density_step';

  /// Course : durée +10 % par semaine au plus.
  static const String durationStep = 'duration_step';

  /// Assistance : élastique plus fin (ou appui plus léger) quand le haut
  /// de la plage est tenu.
  static const String assistanceStep = 'assistance_step';

  /// Tous les codes.
  static const List<String> all = <String>[
    assistanceStep,
    doubleProgression,
    loadStep,
    repStep,
    holdStep,
    densityStep,
    durationStep,
  ];
}

/// Plafond de séries dures par groupe et par semaine que le moteur se
/// donne, par niveau : le plafond du débutant (R1-P1 : 12), puis le haut des bornes d'ancienneté (R5-P13 : 16 chez l'intermédiaire,
/// 20 chez l'avancé) et, en élite, le plafond du niveau avancé (R1-P1 : 25 ;
/// 30 n'est admis que sur un ou deux muscles).
const List<double> coachWeeklyCeiling = <double>[12, 16, 20, 25];

/// Part du volume (séries dures) gardée en semaine d'allègement, au plus,
/// rapportée à la semaine la plus chargée des trois précédentes (R3-P11 :
/// décharge de 40 à 60 % ; marge sous le seuil de 70 % du banc).
const double coachDeloadShare = 0.65;

/// Hausse relative maximale du volume d'un groupe d'une semaine à l'autre :
/// 15 % (R5-P22 : +10 à +20 % ; CX, correction 6 : le panel et la
/// relecture documentée demandent des hausses hebdomadaires de 10 à 15 %,
/// Gabbett 2016 : les hausses brusques de charge précèdent les blessures de
/// surmenage).
const double coachVolumeRise = 0.15;

/// Part du 1RM des séances lourdes d'affûtage hors dernier lourd : 85 %
/// au moins sur le mouvement principal jusqu'à la dernière séance (R3-P13 ;
/// Bosquet et al. 2007 : intensité gardée) — doubles, 3 répétitions en
/// réserve environ (R2-P2 : 2 répétitions à 86 % laissent 3 à 4).
const double coachTaperShare = 0.86;

/// Part du maintien testé sous laquelle la hausse plafonnée d'une tenue de
/// débutant ne la laisse pas (CX, correction 1, passe 5 : bas de la
/// fourchette 55-65 % demandée par le panel).
const double coachHoldFloorShare = 0.55;

/// Hausse des secondes de tenue bras tendus par semaine (R5-P22, R4-F10).
const List<double> coachStraightArmRise = <double>[0.20, 0.15, 0.10, 0.10];

/// Hausse maximale de la charge totale d'une semaine à l'autre à
/// répétitions égales (R5-P3, R5-P22).
const List<double> coachLoadRise = <double>[0.10, 0.05, 0.05, 0.05];

/// Écart de charge totale admis par répétition de moins entre deux séries
/// comparées (table de Helms et al. 2016 : environ 2,5 % du 1RM par
/// répétition autour de 1 à 6 répétitions).
const double coachLoadPerRep = 0.025;

/// RIR à partir duquel une série ne compte plus comme série dure.
const double coachHardSetMaxRir = 4;

/// Secondes par répétition, transition entre exercices, échauffement
/// général : les valeurs de l'estimation de durée (R5-P13 ; celles du
/// banc, sauf l'échauffement, compté 8 min au lieu de 5).
const double coachSecondsPerRep = 3;

/// Transition entre deux exercices, en secondes.
const double coachTransitionSeconds = 45;

/// Échauffement général le plus long, en secondes.
const double coachWarmupSeconds = 480;

/// Échauffement général d'une séance de [minutes] minutes, en secondes :
/// 15 % de la séance, entre 3 et 8 minutes.
double coachWarmupFor(int minutes) {
  final seconds = minutes * 9.0;
  return seconds < 180
      ? 180
      : (seconds > coachWarmupSeconds ? coachWarmupSeconds : seconds);
}

/// Vitesse de course prise pour convertir une durée en distance, en m/s.
const double coachRunMetersPerSecond = 2.5;

int _round(double x) => (x + 0.5).floor();

double _round2(double v) => (v * 100).roundToDouble() / 100;

double _round3(double v) => (v * 1000).roundToDouble() / 1000;

int _clampInt(int v, int low, int high) =>
    v < low ? low : (v > high ? high : v);

/// Plafond de séries dures du groupe [g] pour l'athlète [a] : le plafond du
/// niveau, réduit par la tolérance du profil (R5-P21) — tirage et
/// préhension pour le travail physique ou une gêne du membre supérieur,
/// jambes pour le travail physique, l'endurance ou une gêne du membre
/// inférieur.
double coachGroupCap(Athlete a, MuscleGroup g) {
  var cap = coachWeeklyCeiling[a.level] * a.volumeFactor;
  if (g == MuscleGroup.lats ||
      g == MuscleGroup.upperBack ||
      g == MuscleGroup.biceps) {
    cap *= a.pullFactor;
  } else if (g == MuscleGroup.glutes ||
      g == MuscleGroup.quads ||
      g == MuscleGroup.hamstrings ||
      g == MuscleGroup.calves) {
    cap *= a.legsFactor;
  }
  return cap;
}

/// Famille bras tendus de l'exercice [e] : 0 appui (planche, back lever,
/// appuis tendus), 1 suspension (front lever), 2 mixte, ou −1.
int straightArmFamilyOf(CatalogExercise e) {
  // Tenue menton au-dessus de la barre : bras fléchis, hors du budget des
  // tenues bras tendus (le test du chemin vers la traction en était
  // retiré ; panel CX, boucle 1).
  if (e.rootId.startsWith('cs-tenue-menton') ||
      e.id.startsWith('cs-tenue-menton')) {
    return -1;
  }
  if (e.rootId.startsWith('cs-back-lever') ||
      e.id.startsWith('cs-back-lever')) {
    return 0;
  }
  return switch (e.pattern) {
    MovementPattern.figureStatiquePoussee => 0,
    MovementPattern.figureStatiqueTirage => 1,
    MovementPattern.figureStatiqueMixte => 2,
    _ => -1,
  };
}

/// Vrai si un échec sur [e] expose à une chute ou à une articulation en
/// fin d'amplitude (R5-P27, risque élevé) : au moins 2 répétitions en
/// réserve.
bool coachHighRisk(CatalogExercise e) {
  switch (e.pattern) {
    case MovementPattern.equilibreMains:
    case MovementPattern.transitionMuscleUp:
    case MovementPattern.figureStatiquePoussee:
    case MovementPattern.figureStatiqueTirage:
    case MovementPattern.figureStatiqueMixte:
    case MovementPattern.figureDynamiquePoussee:
    case MovementPattern.figureDynamiqueTirage:
    case MovementPattern.freestyle:
    case MovementPattern.halterophilie:
      return true;
    default:
      break;
  }
  if (e.equipment.contains('anneaux') && e.family == MovementFamily.poussee) {
    return true;
  }
  return e.loadType == LoadType.barbell &&
      (e.pattern == MovementPattern.squat ||
          e.pattern == MovementPattern.pousseeHorizontale ||
          e.pattern == MovementPattern.pousseeInclinee);
}

LoadBasis _basisOf(CatalogExercise e) {
  switch (e.loadType) {
    case LoadType.addedWeight:
      return LoadBasis.bodyweightPlusExternal;
    case LoadType.barbell:
    case LoadType.dumbbells:
    case LoadType.kettlebell:
    case LoadType.machine:
    case LoadType.cable:
    case LoadType.other:
      return LoadBasis.external;
    case LoadType.bodyweight:
      return LoadBasis.bodyweight;
    case LoadType.none:
    case LoadType.band:
      return LoadBasis.unloaded;
  }
}

/// Rôle d'une séance dans la semaine de l'échéance.
enum _DayRole {
  /// Séance ordinaire.
  normal,

  /// Trois jours ou plus avant l'échéance : dernier rappel.
  primerFar,

  /// Un ou deux jours avant l'échéance : repos (R3-P14, R2-P10 : arrêt de
  /// 2 à 4 jours), mobilité seulement.
  primerNear,

  /// Jour de l'échéance.
  event,

  /// Après l'échéance : récupération.
  after,
}

/// Prescription en cours de réglage.
final class _Draft {
  _Draft(this.slot, this.slotId, this.e, this.traits);

  final SlotSpec? slot;
  final String slotId;
  final CatalogExercise e;
  final ExerciseTraits traits;

  String method = '';
  int sets = 1;
  int minSets = 1;
  int? repsLow;
  int? repsHigh;
  int? secondsLow;
  int? secondsHigh;
  double? distance;
  double? rir;
  int rest = 90;
  double? load;
  double? percent;
  bool calibrate = false;
  SetKind kind = SetKind.work;
  bool backoff = false;
  int backoffRepsLow = 0;
  int backoffRepsHigh = 0;
  double backoffDrop = 0;
  bool everyMinute = false;
  int interval = 60;
  bool practice = false;
  bool isometric = false;
  Tempo? tempo;
  IntensityTarget? intensity;
  TestSpec? test;
  String? group;
  DayStress? stress;
  RestMode? restMode;
  bool fixed = false;
  bool ramped = false;

  /// Part du 1RM de travail (celui qui règle les répétitions possibles),
  /// quand elle diffère de la part affichée du 1RM déclaré.
  double? share;

  bool get support => slot?.support ?? false;

  bool get keep => slot?.keep ?? false;
  final List<Reason> reasons = <Reason>[];

  bool get isResistance => traits.kind.isResistance;

  bool get hard {
    if (!isResistance || kind == SetKind.warmup) {
      return false;
    }
    final r = rir;
    return r == null || Flames.toRir(Flames.fromRir(r)) <= coachHardSetMaxRir;
  }

  double creditOf(MuscleGroup g) => hard ? sets * traits.creditOf(g) / 2 : 0;

  double get holdSeconds =>
      secondsHigh != null && isResistance ? sets * secondsHigh!.toDouble() : 0;

  double get seconds {
    final sides = e.laterality == Laterality.bilateral ? 1 : 2;
    double effort;
    final reps = repsHigh;
    final hold = secondsHigh;
    final meters = distance;
    if (reps != null) {
      effort = reps * coachSecondsPerRep * sides;
    } else if (hold != null) {
      effort = hold.toDouble() * (isResistance ? sides : 1);
    } else if (meters != null) {
      effort = meters / coachRunMetersPerSecond;
    } else {
      effort = 30;
    }
    return coachTransitionSeconds +
        sets * effort +
        (sets - 1) * rest +
        (ramped ? 180 : 0);
  }
}

/// Mesures d'une semaine déjà prescrite, pour les garde-fous de montée.
final class _WeekTrace {
  _WeekTrace(this.light, {this.restart = false});

  final bool light;

  /// Semaine de transition ou d'introduction (reprise après une échéance
  /// ou une coupure) : la charge qui suit remonte par paliers, même quand
  /// le nombre de répétitions change.
  final bool restart;
  final List<double> groups = List<double>.filled(MuscleGroup.values.length, 0);
  final List<double> straightArm = <double>[0, 0, 0];
  double hard = 0;
  final Map<String, (double, int)> loads = <String, (double, int)>{};

  /// Plus lourde charge totale écrite de la semaine par exercice et par
  /// nombre de répétitions (clé « exercice|répétitions ») : la borne de
  /// hausse tient aussi d'un bloc à l'autre, quand les emplacements
  /// changent.
  final Map<String, double> loadsByExercise = <String, double>{};

  /// Plus lourde charge totale écrite de la semaine par exercice, toutes
  /// répétitions confondues, avec ses répétitions (CP2, partie 0 : borne
  /// de hausse à répétitions différentes).
  final Map<String, (double, int)> heaviest = <String, (double, int)>{};

  /// Tonnage écrit de la semaine par exercice lesté (séries × répétitions
  /// × charge totale), séries de travail seulement.
  final Map<String, double> tonnage = <String, double>{};

  /// Départs au chrono écrits par emplacement.
  final Map<String, int> minutes = <String, int>{};

  /// Répétitions écrites de la semaine par mouvement au poids du corps
  /// (racine de la chaîne de variantes), séries au chrono comprises.
  final Map<String, double> reps = <String, double>{};

  /// Plus longue tenue écrite de la semaine par exercice de maintien du
  /// débutant (secondes par série).
  final Map<String, int> holds = <String, int>{};
}

/// Racine d'un mouvement au poids du corps compté en répétitions, pour le
/// garde-fou du volume de répétitions, ou `null`.
String? _repsRootOf(CatalogExercise e) {
  if (e.unit != MeasureUnit.repetitions ||
      (e.loadType != LoadType.bodyweight && e.loadType != LoadType.none)) {
    return null;
  }
  return e.rootId;
}

/// Prescripteur d'un bloc.
final class Prescriber {
  /// Prescripteur du squelette [skeleton] pour l'athlète [a].
  Prescriber(
    this.a,
    this.skeleton,
    this.blockIndex, {
    this.volumeScale = 1,
    this.kept = const <WeekPrescription>[],
  });

  /// Semaines du bloc en cours déjà écrites et gardées (restructuration en
  /// cours de bloc) : les garde-fous de volume et de charge lisent ces
  /// semaines-là, pas leur réécriture (CX, correction 1 : une
  /// restructuration au milieu du bloc montait le volume sans voir les
  /// semaines faites).
  final List<WeekPrescription> kept;

  /// Facteur de volume du résumé d'adaptation (assiduité, fatigue).
  final double volumeScale;

  /// Athlète.
  final Athlete a;

  /// Squelette.
  final Skeleton skeleton;

  /// Rang du bloc.
  final int blockIndex;

  final List<_WeekTrace> _history = <_WeekTrace>[];

  /// Mouvements dont la série d'entrée de reprise est déjà écrite.
  final Set<String> _entered = <String>{};

  /// Jours d'activation (J−2 d'une épreuve de répétitions) de la semaine
  /// en cours.
  final Set<int> _activation = <int>{};

  /// Premier jour de la semaine en cours de prescription.
  late CivilDate _today = a.start;

  /// Séance en cours de prescription.
  int _dayNow = 0;

  /// Semaines de charge (introduction comprise) déjà prescrites dans le
  /// bloc.
  int _loadedBefore = 0;

  /// Vrai pour la dernière semaine de charge avant un allègement.
  bool _lastLoaded = false;

  /// Semaines de test déjà passées (blocs précédents compris).
  int _testsDone = 0;

  /// Vrai pour un profil dont le volume monte deux fois moins vite : 40 ans
  /// et plus (R5-P21), ou reprise après dix semaines d'arrêt (R5-P6 : le
  /// tendon revient moins vite que le muscle).
  bool get _slow => a.slowRamp || (a.gapWeeks >= 10 && blockIndex <= 2);

  BlockShape get _shape => skeleton.shape;

  int get _level => a.level;

  // ------------------------------------------------------------- utilitaires

  double? _external(CatalogExercise e, double total, double pct) {
    final fraction = e.bodyweightFraction?.value ?? 0;
    final external = total * pct - fraction * a.bodyWeight;
    final (defaultStep, defaultMin) = defaultIncrement(e.loadType);
    var step = defaultStep;
    var least = defaultMin;
    for (final i in a.profile.loadIncrements) {
      if (i.loadType == e.loadType) {
        step = i.stepKg;
        least = i.minKg ?? defaultMin;
      }
    }
    if (step <= 0) {
      step = defaultStep;
    }
    var load = (external / step + 1e-9).floorToDouble() * step;
    if (load < least) {
      load = least;
    }
    if (load < 0) {
      load = 0;
    }
    return _round2(load);
  }

  /// 1RM de charge totale qui règle [e] : le sien, sinon celui de
  /// [referenceId] (variante d'un mouvement de compétition).
  double? _totalFor(CatalogExercise e, String? referenceId) {
    final own = a.totalOneRm(e.id);
    if (own != null) {
      return own;
    }
    if (referenceId == null || e.loadType != LoadType.addedWeight) {
      return null;
    }
    final ref = a.catalog.find(referenceId);
    if (ref == null || ref.loadType != LoadType.addedWeight) {
      return null;
    }
    return a.totalOneRm(referenceId);
  }

  /// Vrai pour la séance facile à deux jours d'un test daté sans pic de
  /// forme (le rôle « dernier rappel » n'existe alors qu'à J−2).
  bool _easyDay(_DayRole role) =>
      (role == _DayRole.primerFar && !(_shape.target?.peak ?? false)) ||
      (role == _DayRole.normal && _soft);

  /// Jours entre la séance en cours et l'échéance, ou `null`.
  int? get _toEventDays {
    final target = _shape.target;
    if (target == null) {
      return null;
    }
    return _today.daysUntil(target.date) - _dayOffset(_dayNow);
  }

  /// Part du 1RM qui permet [reps] répétitions (R2-P2, par interpolation).
  double _pctAt(int reps) {
    const table = <(int, double)>[
      (1, 1.0),
      (2, 0.94),
      (3, 0.91),
      (5, 0.86),
      (8, 0.79),
      (10, 0.75),
      (12, 0.71),
    ];
    if (reps <= 1) {
      return 1;
    }
    for (var i = 1; i < table.length; i++) {
      final (few, high) = table[i - 1];
      final (many, low) = table[i];
      if (reps <= many) {
        return high - (high - low) * (reps - few) / (many - few);
      }
    }
    return 0.71;
  }

  /// RIR plancher de l'exercice [e] : mouvement à risque (R5-P27), zone à
  /// ménager (R5-P23), débutant (R5-P4), reprise (R5-P7).
  double _floorRir(CatalogExercise e, int week) {
    var floor = 0.0;
    if (coachHighRisk(e)) {
      floor = 2;
    }
    if ((_level == 0 || a.cautious) && floor < 2) {
      floor = 2;
    }
    for (final l in a.limits) {
      final joint = l.joint;
      if (joint == null) {
        continue;
      }
      if (e.stressOn(joint) != JointStress.low &&
          (l.recent || l.discomfort >= 2) &&
          floor < 2) {
        floor = 2;
      }
    }
    // R5-P7 : reprise — 3 répétitions en réserve au moins la première
    // semaine (les deux premières après dix semaines d'arrêt, et 4 la
    // toute première après seize).
    if (blockIndex == 0 && a.gapWeeks >= 2) {
      // (quatre semaines après dix semaines d'arrêt ou plus : le tendon
      // revient moins vite que le muscle, R5-P6.)
      // (Tout le premier bloc après dix semaines d'arrêt ou plus : la
      // force revient plus vite que les tissus conjonctifs.)
      final weeks = a.gapWeeks >= 10 ? 99 : (a.gapWeeks >= 4 ? 2 : 1);
      if (week < weeks && floor < 3) {
        floor = 3;
      }
      if (week == 0 && a.gapWeeks >= 16 && floor < 4) {
        floor = 4;
      }
    }
    // R5-P6 : après dix semaines d'arrêt ou plus, tout le premier cycle
    // (trois blocs) garde 2 répétitions en réserve — le tendon revient
    // moins vite que le muscle.
    if (a.gapWeeks >= 10 && blockIndex <= 2 && floor < 2) {
      floor = 2;
    }
    return floor;
  }

  double _rirOf(
    CatalogExercise e,
    double base,
    WeekSpec ws,
    int week, {
    double cap = coachHardSetMaxRir,
  }) {
    var rir = base + a.rirBonus;
    if (ws.kind == WeekKind.intro) {
      rir += 1;
    } else if (ws.intent == WeekIntent.deload ||
        ws.intent == WeekIntent.taper ||
        ws.intent == WeekIntent.transition) {
      if (rir < 3) {
        rir = 3;
      }
    }
    final floor = _floorRir(e, week);
    if (rir < floor) {
      rir = floor;
    }
    // Une série de travail reste une série dure (4 en réserve au plus) ;
    // le volume sous-maximal et la densité vont jusqu'à 5 et plus.
    return rir > cap ? cap : rir;
  }

  /// Part des anciens repères que vise la semaine en cours après une
  /// coupure (R5-P7 : charge −10 % après 2 à 4 semaines d'arrêt, −15 à
  /// −20 % après 4 à 8, −20 à −30 % au-delà ; R5-P6 : retour à 90 % des
  /// repères en un bloc, puis au niveau antérieur).
  double get _regain => _regainAt(_testsDone);

  /// Part des anciens repères après [tests] tests passés.
  double _regainAt(int tests) {
    final gap = a.gapWeeks;
    if (gap < 2) {
      return 1;
    }
    final base = gap < 4 ? 0.90 : (gap < 8 ? 0.82 : 0.75);
    // Le repère ne monte qu'après un test (jamais sur un progrès
    // supposé) : au premier test, à mi-chemin des anciens records ; au
    // deuxième, à 95 % ; au troisième, aux anciens records.
    if (tests <= 0) {
      return base;
    }
    if (tests == 1) {
      return (base + 1) / 2 > 0.92 ? 0.92 : (base + 1) / 2;
    }
    return tests == 2 ? 0.95 : 1;
  }

  int _scaled(int sets, WeekSpec ws, {int min = 1}) {
    var n = _round(sets * ws.volume * volumeScale);
    // Semaine de l'échéance ou du test daté : deux séries au plus par
    // exercice — le volume continue de baisser jusqu'au test (R3-P12).
    if (ws.eventWeek && n > 2) {
      n = 2;
    }
    return n < min ? min : n;
  }

  /// Rang de progression de la semaine [ws] : le rang dans la phase, plus
  /// un cran par bloc déjà fait quand la saison n'a pas de pic (le bloc
  /// suivant repart un cran au-dessus du précédent, R3-P3).
  int _stage(WeekSpec ws) {
    final carry =
        (_shape.model == SeasonModel.general ||
                _shape.model == SeasonModel.linear) &&
            blockIndex > 0
        ? (blockIndex > 3 ? 3 : blockIndex)
        : 0;
    return ws.stage + carry;
  }

  /// Décalage planifié d'une plage de répétitions en double progression :
  /// une répétition de plus toutes les deux semaines de charge (deux au
  /// plus dans le bloc), tant que la réserve prévue est tenue.
  int _shift(WeekSpec ws) {
    if (ws.kind != WeekKind.build) {
      return 0;
    }
    // (Blocs de quatre semaines, à partir du niveau avancé : une
    // répétition de plus chaque semaine de charge après la première.)
    final half = _level >= 2 ? _stage(ws) : _stage(ws) ~/ 2;
    return half > 2 ? 2 : half;
  }

  int _dayOffset(int d) {
    var offset = a.days[d].weekday - a.start.weekday;
    if (offset < 0) {
      offset += 7;
    }
    return offset;
  }

  /// Rôle de chaque séance de la semaine [week].
  List<_DayRole> _roles(int week, WeekSpec ws) {
    _activation.clear();
    final roles = List<_DayRole>.filled(a.dayCount, _DayRole.normal);
    final target = _shape.target;
    if (!ws.eventWeek || target == null) {
      return roles;
    }
    final eventOffset = a.start.daysUntil(target.date) - 7 * week;
    var eventDay = -1;
    var best = -1;
    for (var d = 0; d < a.dayCount; d++) {
      final offset = _dayOffset(d);
      if (offset <= eventOffset && offset > best) {
        best = offset;
        eventDay = d;
      }
    }
    if (eventDay < 0) {
      // L'échéance précède toutes les séances de la semaine : la première
      // séance la porte.
      var first = 0;
      for (var d = 1; d < a.dayCount; d++) {
        if (_dayOffset(d) < _dayOffset(first)) {
          first = d;
        }
      }
      eventDay = first;
      best = _dayOffset(first);
    }
    for (var d = 0; d < a.dayCount; d++) {
      final offset = _dayOffset(d);
      if (d == eventDay) {
        roles[d] = _DayRole.event;
      } else if (offset > best) {
        // Après l'épreuve ou le test daté : récupération.
        roles[d] = _DayRole.after;
      } else if (target.peak) {
        // R3-P14 : dernière séance à J−3 ou J−4 avant une épreuve de force
        // (arrêt de 2 à 4 jours) ; R3-P21 : repos complet d'un à deux
        // jours avant une épreuve de répétitions.
        // (Épreuve de répétitions : à J−2, une activation courte et
        // facile ; repos complet la veille.)
        roles[d] = best - offset > 2 ? _DayRole.primerFar : _DayRole.primerNear;
        if (best - offset == 2) {
          _activation.add(d);
        }
      } else {
        // Test daté sans pic de forme : semaine allégée ordinaire ; à deux
        // jours du test, une séance facile (48 h sans travail dur du
        // mouvement testé) ; repos la veille.
        roles[d] = best - offset > 2
            ? _DayRole.normal
            : (best - offset == 2 ? _DayRole.primerFar : _DayRole.primerNear);
      }
    }
    return roles;
  }

  Reason _note(String note, num value) => reason(
    ReasonCodes.planCoachNote,
    <String, Object?>{'note': note, 'value': value.toDouble()},
  );

  Reason _rule(String rule, num step, String unit) => reason(
    ReasonCodes.planProgressionRule,
    <String, Object?>{'rule': rule, 'step': step.toDouble(), 'unit': unit},
  );

  _Draft _new(SlotSpec s) {
    final e = a.catalog.exercise(s.exerciseId);
    return _Draft(s, s.slotId, e, a.traits.of(e.id))
      ..method = s.method
      ..group = s.group
      ..stress = s.stress;
  }

  // ------------------------------------------------------------ force lestée

  /// Charge, part du 1RM et intensité d'un item à [pct] du 1RM de
  /// référence ; sans 1RM connu, charge à régler à la première séance.
  void _loadAt(_Draft x, double pct, String? referenceId, {bool over = false}) {
    final e = x.e;
    var total = _totalFor(e, referenceId);
    // 1RM de travail relevé d'après le maximum au poids du corps quand il
    // le dépasse (table R2-P2 jusqu'à 12 répétitions, Epley au-delà, borné
    // à 20) : un 1RM lesté sous-estimé ne doit pas ramener la séance lourde
    // au poids du corps avec une réserve fausse (panel CX, boucle 4 :
    // « traction lestée » du vendredi à 6 ou 7 répétitions de réserve).
    final bwId = _bodyweightOf[e.id];
    final bwMax = bwId == null ? 0 : (a.reps[bwId] ?? 0);
    final weight = (e.bodyweightFraction?.value ?? 0) * a.bodyWeight;
    // (Jamais sur un 1RM mesuré par un test ou une compétition : le
    // résultat fait foi — CX, correction 1, `street_12`. Un record déclaré
    // ou une estimation peuvent dater : le maximum au poids du corps les
    // relève — passe 7 du panel, `street_11` : un 1RM déclaré de 88,5 kg
    // pour 10 tractions mettait la séance lourde au poids du corps, à 7
    // répétitions de réserve.)
    final source = a.totalOneRm(e.id) != null ? e.id : referenceId;
    if (total != null &&
        bwMax >= 3 &&
        weight > 0 &&
        (source == null || !a.measuredOneRm.contains(source))) {
      final fromReps = bwMax <= 12
          ? weight / _pctAt(bwMax)
          : weight * (1 + (bwMax > 20 ? 20 : bwMax) / 30);
      if (fromReps > total) {
        total = fromReps;
      }
    }
    if (_basisOf(e) == LoadBasis.unloaded ||
        _basisOf(e) == LoadBasis.bodyweight) {
      return;
    }
    if (total == null) {
      x
        ..calibrate = true
        ..reasons.add(reason(ReasonCodes.planToCalibrate))
        ..reasons.add(_note(CoachNotes.calibrate, x.rir ?? 3));
      return;
    }
    final regained = pct * _regain;
    var p = regained > 1 && !over ? 1.0 : regained;
    // Reprise graduée après une douleur qui dure : vers 67,5 % du 1RM,
    // puis +2,5 % par semaine de charge au plus (relecture documentée CX,
    // `street_12` : retour du mouvement lesté vers 65 à 70 %, +2,5 kg par
    // semaine au plus).
    final back = a.returnShareOf(e, _returnWeek);
    if (back != null && x.kind == SetKind.work) {
      final cap = 0.675 + 0.25 * (back - coachPainReturnStart) + 1e-9;
      if (p > cap) {
        p = cap;
      }
    }
    if (a.cautious && p > 0.85) {
      // Mode prudent (questionnaire santé, moins de 18 ans, 65 ans et
      // plus) : intensité modérée, 85 % au plus.
      p = 0.85;
    }
    // Mouvement lesté dont la charge visée tombe sous le poids du corps :
    // la série se fait au poids du corps, à sa vraie part du 1RM, avec
    // moins de répétitions (formule d'Epley) pour garder la réserve.
    final floor = (e.bodyweightFraction?.value ?? 0) * a.bodyWeight / total;
    var atFloor = false;
    if (floor > 0 &&
        (p < floor - 1e-9 || floor >= 0.78) &&
        _shape.model != SeasonModel.strengthPeak &&
        x.kind == SetKind.work &&
        !over) {
      // Hors préparation d'une épreuve de force : un 1RM lesté proche du
      // poids du corps ne se travaille pas en pourcentage affiché (la
      // charge visée tomberait sous le poids du corps).
      // Le lest de départ est celui que la table R2-P2 donne pour les
      // répétitions écrites plus la réserve (jamais une série plus dure
      // que son étiquette) ; s'il tombe sous le plus petit pas, la série
      // se fait au poids du corps (ci-dessous).
      final added = total - floor * total;
      final reps = x.repsHigh ?? 5;
      final kept = (x.rir ?? 3).ceil();
      final lest = _external(e, total, _pctAt(reps + kept));
      final raw = total * _pctAt(reps + kept) - floor * total;
      // La note « 1RM lesté proche du poids du corps » ne vaut que
      // lorsqu'il l'est vraiment (poids du corps à 78 % du 1RM ou plus) ;
      // une semaine légère dont la part tombe sous le poids du corps se
      // fait au poids du corps (ci-dessous ; panel CX, boucle 1).
      if (floor >= 0.78 && added > 0 && raw > 0 && lest != null && lest > 0) {
        x
          ..load = lest
          ..reasons.add(_note(CoachNotes.smallLoad, lest));
        return;
      }
      // 1RM lesté de 70 à 78 % au-dessus du poids du corps : la séance
      // lourde reste lestée — moins de répétitions (3 au moins), avec le
      // lest que la table donne pour ces répétitions et la réserve, plutôt
      // qu'une série au poids du corps nommée « lestée » (CP2, partie 0 ;
      // panel CX correction 1, `street_11` : « 4 × 3-4 avec +2,5 à +5 kg à
      // 2-3 en réserve »).
      // (Seulement quand la part visée est à 5 points du poids du corps au
      // plus : une semaine légère reste au poids du corps.)
      if (floor >= 0.70 && p >= floor - 0.05 && added > 0 && !x.fixed) {
        final top = x.repsHigh ?? 5;
        for (var r = top; r >= 3; r--) {
          final share = _pctAt(r + kept);
          final l = _external(e, total, share);
          final rawLoad = total * share - floor * total;
          if (l != null && l > 0 && rawLoad + 1e-9 >= l) {
            x
              ..load = l
              ..repsLow = r
              ..repsHigh = r
              ..reasons.add(_note(CoachNotes.smallLoad, l));
            return;
          }
        }
      }
      // Lest sous le plus petit pas : la série s'écrit au poids du corps,
      // avec les répétitions que sa vraie part du 1RM laisse à la réserve
      // visée (CX, correction 6 : une charge chiffrée dès que le 1RM est
      // connu, plus de « à calibrer »).
      atFloor = true;
    }
    if (floor > 0 && (p < floor - 1e-9 || atFloor)) {
      p = floor;
      // Répétitions possibles au poids du corps : la formule d'Epley sur
      // la vraie part du 1RM, ou le maximum mesuré au poids du corps s'il
      // est plus haut (un 1RM lesté estimé bas ne doit pas réduire la
      // série à 2 ou 3 répétitions faciles ; panel CX, boucle 1). La série
      // garde la réserve visée, jusqu'à 8 répétitions (zone de force).
      final epley = (30 * (1 / p - 1)).floor();
      final bodyweightMax = a.reps[_bodyweightOf[e.id] ?? ''] ?? 0;
      final possible = bodyweightMax > epley ? bodyweightMax : epley;
      final high = x.repsHigh;
      final reserve = (x.rir ?? 3).ceil();
      if (high != null) {
        final reach = possible - reserve;
        // (Rappel, amorçage et simples gardent leurs répétitions écrites.)
        final open = !x.fixed && high >= 3 && reach > high;
        final reps = _clampInt(reach, 1, open ? 8 : high);
        x
          ..repsLow = reps
          ..repsHigh = reps;
      }
      x.reasons.add(_note(CoachNotes.bodyweightFloor, p));
    }
    if (over) {
      // Amplitude partielle : la consigne de montage accompagne chaque
      // séance, que la charge dépasse ou non le 1RM complet.
      x.reasons.add(_note(CoachNotes.overload, p));
    }
    if (p > 1) {
      // Amplitude partielle surchargée : au-dessus du 1RM complet.
      x.load = _external(e, total, p);
      return;
    }
    x
      ..load = _external(e, total, p)
      ..reasons.add(
        reason(ReasonCodes.planPercentBased, <String, Object?>{
          'pct': _round3(p),
        }),
      );
    final declared = a.totalOneRm(e.id);
    if (declared != null) {
      // Part affichée : celle de la charge écrite (arrondie au pas), sur le
      // 1RM de travail — un seul repère par bloc, que l'export redonne en
      // kilos (CX, correction 1, panel : 1RM de référence qui variait de
      // 121,5 à 123 kg d'une ligne à l'autre).
      final load = x.load;
      final shown = load == null
          ? p
          : (load + (e.bodyweightFraction?.value ?? 0) * a.bodyWeight) / total;
      x
        ..percent = _round3(shown)
        ..share = p
        ..intensity = IntensityTarget(
          basis: IntensityBasis.percentOneRm,
          value: _round3(shown),
        );
    } else {
      x.intensity = IntensityTarget(
        basis: IntensityBasis.percentOneRm,
        value: _round3(p),
        referenceExerciseId: referenceId,
      );
    }
  }

  /// Mouvement au poids du corps d'un mouvement lesté.
  static const Map<String, String> _bodyweightOf = <String, String>{
    Ids.weightedPull: Ids.pull,
    Ids.weightedDip: Ids.dip,
  };

  /// Vrai quand l'échéance du bloc vise des maxima de répétitions (objectifs
  /// datés en répétitions, ou épreuve de répétitions) et aucune charge
  /// maximale.
  bool get _repsAim {
    final target = _shape.target;
    if (target == null) {
      return false;
    }
    if (target.event != null) {
      return isRepsTarget(target);
    }
    return target.goals.isNotEmpty &&
        target.goals.every((g) => g.metric == GoalMetric.maxReps);
  }

  /// Séries d'un mouvement lourd en intensification et en réalisation :
  /// trois au moins (une série de tête et deux séries allégées à −5 %, soit
  /// trois séries à 85 % et plus : R2-P8, 3 à 6 séries à 85 % et plus par
  /// semaine ; CX, correction 4), sauf semaine allégée.
  int _heavySets(int base, WeekSpec ws) {
    final sets = _scaled(base, ws, min: 2);
    return ws.light || sets >= 3 ? sets : 3;
  }

  void _topSet(
    _Draft x, {
    required int sets,
    required int reps,
    required double pct,
    required double rir,
    required double drop,
    required WeekSpec ws,
    required int week,
  }) {
    // Muscle-up lesté : séries de trois au plus (mouvement technique à
    // risque, R5-P27 — la réserve doit rester réelle).
    final count = _muscleUp(x.e) && reps > 3 ? 3 : reps;
    x
      ..sets = sets
      ..minSets = 2
      ..repsLow = count
      ..repsHigh = count
      ..rir = _rirOf(x.e, rir, ws, week)
      ..rest = _level >= 2 ? 240 : 180
      ..ramped = true;
    _loadAt(x, pct, x.slot?.referenceId);
    _honest(x, week);
    final done = x.repsHigh ?? count;
    if (sets >= 2) {
      // Les séries allégées ne descendent pas sous le poids du corps.
      var lighter = drop;
      final total = _totalFor(x.e, x.slot?.referenceId);
      final load = x.load;
      if (total != null && load != null && total > 0) {
        final room =
            load / (load + (x.e.bodyweightFraction?.value ?? 0) * a.bodyWeight);
        if (lighter > room) {
          lighter = (room * 20).floorToDouble() / 20;
        }
      }
      x
        ..backoff = true
        ..backoffRepsLow = done
        ..backoffRepsHigh = done
        ..backoffDrop = lighter
        ..reasons.add(_note(CoachNotes.topSetBackoff, lighter * 100));
    }
    x.reasons.add(_note(CoachNotes.rampWarmup, 4));
  }

  _Draft? _liftHeavy(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    final stage = _stage(ws);
    final maintain = s.method == Method.liftMaintain;
    final base = s.sets;
    // R5-P24 : zone à ménager — la charge repart plus bas et rejoint le
    // plan en trois semaines (retour par paliers de 10 à 20 %).
    var spared = false;
    for (final l in a.limits) {
      final joint = l.joint;
      if (joint != null &&
          x.e.stressOn(joint) != JointStress.low &&
          (l.recent || l.discomfort >= 2)) {
        spared = true;
      }
    }
    final ease = !spared || blockIndex > 0
        ? 0.0
        : (week <= 1 ? 0.06 : (week == 2 ? 0.03 : 0.0));
    final dated = _shape.target;
    if (ws.eventWeek &&
        role == _DayRole.normal &&
        dated != null &&
        !dated.peak &&
        !maintain &&
        a.aimsAt(x.e.id) &&
        (_toEventDays ?? 0) >= 4) {
      // Test daté d'un 1RM, sans pic de forme : un dernier rappel lourd et
      // court à J−4 à J−6 (simple à 88 %, deux doubles à 85 % environ),
      // pour arriver au test avec une exposition récente au lourd
      // (R3-P13, R3-P14).
      _topSet(
        x,
        sets: 3,
        reps: 1,
        pct: 0.88,
        rir: 3,
        drop: 0.05,
        ws: ws,
        week: week,
      );
      x
        ..backoffRepsLow = 2
        ..backoffRepsHigh = 2
        ..reasons.add(_note(CoachNotes.opener, 0.88));
      return x;
    }
    if (_easyDay(role)) {
      // À deux jours d'un test sans pic de forme : deux séries légères et
      // rapides, rien de fatigant (R3-P14).
      x
        ..sets = 2
        ..repsLow = 2
        ..repsHigh = 2
        ..rir = 5
        ..rest = 120
        ..fixed = true
        ..reasons.add(_note(CoachNotes.speedWork, 0.7));
      _loadAt(x, 0.70, s.referenceId);
      return x;
    }
    if (role == _DayRole.primerFar && !maintain) {
      // R3-P13 : dernier rappel lourd et court, 3 à 5 jours avant.
      // (R3-P14 : le dernier lourd est passé, à J−7 à J−10 ; ce rappel
      // reste facile et rapide, à 85 %.)
      _topSet(
        x,
        sets: 2,
        reps: 1,
        pct: 0.85,
        rir: 4,
        drop: 0.10,
        ws: ws,
        week: week,
      );
      x
        ..backoffRepsLow = 2
        ..backoffRepsHigh = 2
        ..reasons.add(_note(CoachNotes.opener, 0.85));
      return x;
    }
    if (role == _DayRole.primerNear) {
      x
        ..sets = 2
        ..repsLow = 2
        ..repsHigh = 2
        ..rir = 5
        ..rest = 120
        ..fixed = true
        ..reasons.add(_note(CoachNotes.speedWork, 0.7));
      _loadAt(x, 0.70, s.referenceId);
      return x;
    }
    if (maintain) {
      // R4-H3 : entretien au tiers du volume, intensité gardée.
      final heavy = s.stress == DayStress.heavy;
      if (role != _DayRole.normal || ws.eventWeek) {
        // Semaine de l'échéance : le mouvement en entretien ne prend rien
        // à l'épreuve — deux séries légères.
        x
          ..sets = 2
          ..minSets = 1
          ..repsLow = 3
          ..repsHigh = 3
          ..rir = 4
          ..rest = 150
          ..reasons.add(_note(CoachNotes.maintenance, 2));
        _loadAt(x, 0.75, s.referenceId);
        return x;
      }
      x
        ..sets = ws.light ? 2 : base
        ..minSets = 2
        ..repsLow = heavy ? 3 : 5
        ..repsHigh = heavy ? 3 : 5
        ..rir = _rirOf(x.e, 3, ws, week)
        ..rest = 180
        ..ramped = heavy
        ..reasons.add(_note(CoachNotes.maintenance, base));
      _loadAt(x, heavy ? 0.83 : 0.76, s.referenceId);
      _honest(x, week);
      return x;
    }
    switch (ws.intent) {
      case WeekIntent.intro:
        _topSet(
          x,
          sets: _scaled(base, ws, min: 2),
          reps: 5,
          pct: 0.76,
          rir: 3,
          drop: 0.08,
          ws: ws,
          week: week,
        );
      case WeekIntent.accumulation || WeekIntent.maintenance:
        // R3-P4 : accumulation à 80 à 84 % en séries de 5.
        var pct = 0.80 + 0.015 * stage;
        if (pct > 0.845) {
          pct = 0.845;
        }
        pct -= ease;
        _topSet(
          x,
          sets: _scaled(base, ws, min: 2),
          reps: 5,
          pct: pct,
          rir: 2,
          drop: 0.08,
          ws: ws,
          week: week,
        );
      case WeekIntent.intensification:
        // R3-P4 : intensification à 86 à 90 % en séries de 3.
        var pct = 0.86 + 0.015 * stage;
        if (pct > 0.90) {
          pct = 0.90;
        }
        pct -= ease;
        // R2-P8 : 3 à 6 séries à 85 % et plus par semaine en
        // intensification — les séries allégées restent à −5 %, et la
        // séance en compte trois au moins (série de tête et deux séries
        // allégées : CX, correction 4).
        _topSet(
          x,
          sets: _heavySets(base, ws),
          reps: 3,
          pct: pct,
          rir: ease > 0 ? 3 : 2,
          drop: 0.05,
          ws: ws,
          week: week,
        );
      case WeekIntent.realization:
        // R3-P4 : réalisation à 91 à 94 %, doubles puis simples.
        // R2-P1 : l'intermédiaire plafonne à 90 % en fin de bloc.
        // La charge monte d'un cran par semaine dans la phase (doubles de
        // 87 à 90 % chez l'intermédiaire ; 91 %, puis simples de 93 à 95 %
        // ensuite).
        final single = ws.stage >= 1 && _level >= 2;
        final step = ws.stage > 3 ? 3 : ws.stage;
        final heavy = single
            ? 0.93 + 0.01 * (step - 1)
            : (_level >= 2 ? 0.91 : 0.87 + 0.01 * step);
        // Séries allégées à −5 % (CX, correction 4 : −10 à −15 % les
        // sortait de la zone de réalisation ; R2-P8, R3-P4 : le travail de
        // réalisation se fait à 85 % et plus), trois séries au moins.
        _topSet(
          x,
          sets: _heavySets(base, ws),
          reps: single ? 1 : 2,
          pct: heavy - ease,
          rir: single ? 1 : 2,
          drop: 0.05,
          ws: ws,
          week: week,
        );
        x
          ..backoffRepsLow = 2
          ..backoffRepsHigh = 2;
      case WeekIntent.taper:
        // R3-P12, P13 : volume −40 à −60 %, intensité gardée. R3-P14 : le
        // dernier lourd tombe à J−7 à J−10 — la séance du mouvement la
        // mieux placée le porte ; les autres restent modérées.
        if (_lastHeavyDay(x.e.id) == _dayNow) {
          _lastHeavy(x, ws, week);
        } else {
          // (Doubles à 86 % : jamais sous 85 % sur le mouvement principal
          // avant la dernière séance, R3-P13 ; panel CX, correction 1 :
          // 2 × 3 à 79-80 % pendant l'affûtage.)
          x
            ..sets = 2
            ..minSets = 2
            ..repsLow = 2
            ..repsHigh = 2
            ..rir = _rirOf(x.e, 3, ws, week)
            ..rest = 180
            ..ramped = true;
          _loadAt(x, coachTaperShare, s.referenceId);
          _honest(x, week);
        }
      case WeekIntent.deload ||
          WeekIntent.test ||
          WeekIntent.competition ||
          WeekIntent.transition:
        // R3-P9 : allègement — séries −40 à −50 %, charge un peu sous
        // celle du bloc, même format de répétitions.
        final reps =
            _shape.phase == SeasonPhaseKind.intensification ||
                _shape.phase == SeasonPhaseKind.realization
            ? 3
            : 5;
        final pct = ws.intent == WeekIntent.transition
            ? 0.65
            : (reps == 3 ? 0.80 : 0.75);
        x
          ..sets = base >= 4 ? 3 : 2
          ..minSets = 2
          ..repsLow = _muscleUp(x.e) && reps > 3 ? 3 : reps
          ..repsHigh = _muscleUp(x.e) && reps > 3 ? 3 : reps
          ..rir = _rirOf(x.e, 4, ws, week)
          ..rest = 180;
        _loadAt(x, pct, s.referenceId);
    }
    if (_lastLoaded && role == _DayRole.normal && !x.calibrate) {
      // Dernière semaine de charge du bloc : la série de tête sert de
      // recalage (R3-P16, R2-P20 : la charge suit la réserve mesurée).
      x.reasons.add(_note(CoachNotes.recalibrate, 2.5));
    }
    return x;
  }

  /// Séance du mouvement [id] qui porte le dernier lourd de la semaine
  /// d'affûtage : celle qui tombe à J−7 à J−10 (la plus proche de J−8),
  /// sinon la plus éloignée de l'échéance à cinq jours ou plus ; −1 sans
  /// échéance.
  int _lastHeavyDay(String id) {
    final target = _shape.target;
    if (target == null || !_eventExercises().contains(id)) {
      return -1;
    }
    var best = -1;
    var bestScore = 1000;
    for (final d in skeleton.days) {
      if (!d.slots.any(
        (s) =>
            s.exerciseId == id &&
            (s.method == Method.liftHeavy || s.method == Method.liftVolume),
      )) {
        continue;
      }
      final left = _today.daysUntil(target.date) - _dayOffset(d.dayIndex);
      if (left < 5) {
        continue;
      }
      final gap = left > 8 ? left - 8 : 8 - left;
      final score = left >= 7 && left <= 10 ? gap : 10 + gap;
      if (score < bestScore) {
        bestScore = score;
        best = d.dayIndex;
      }
    }
    return best;
  }

  /// Dernier lourd avant l'échéance : un simple à 90 %, deux séries
  /// allégées.
  void _lastHeavy(_Draft x, WeekSpec ws, int week) {
    _topSet(
      x,
      sets: 3,
      reps: 1,
      pct: 0.90,
      rir: 2,
      drop: 0.08,
      ws: ws,
      week: week,
    );
    final back = _muscleUp(x.e) ? 1 : 2;
    x
      ..backoffRepsLow = back
      ..backoffRepsHigh = back
      ..reasons.add(_note(CoachNotes.dressRehearsal, _toEventDays ?? 8));
  }

  _Draft? _liftVolume(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final dated = _shape.target;
    if (ws.eventWeek &&
        role == _DayRole.normal &&
        dated != null &&
        !dated.peak &&
        s.method != Method.liftMaintain &&
        a.aimsAt(s.exerciseId) &&
        (_toEventDays ?? 0) >= 4) {
      return _liftHeavy(s, ws, week, role);
    }
    if (role == _DayRole.primerNear) {
      return null;
    }
    final x = _new(s);
    if (ws.intent == WeekIntent.taper &&
        role == _DayRole.normal &&
        _lastHeavyDay(x.e.id) == _dayNow) {
      // R3-P14 : dernier lourd à J−7 à J−10.
      _lastHeavy(x, ws, week);
      return x;
    }
    final stage = _stage(ws);
    var reps = 6;
    var pct = 0.72 + 0.015 * stage;
    var rir = 3.0;
    var sets = _scaled(s.sets, ws, min: 2);
    switch (ws.intent) {
      case WeekIntent.intro:
        pct = 0.70;
        rir = 3;
      case WeekIntent.accumulation || WeekIntent.maintenance:
        if (_level >= 2) {
          // Avancé et élite : séries de 5 à 75 à 80 %, 2 à 3 répétitions en
          // réserve (CX, panel : 6 répétitions à 72 % laissaient 5 à 6
          // répétitions en réserve ; R2-P2, R1-P11).
          reps = 5;
          pct = 0.75 + 0.015 * stage;
          if (pct > 0.80) {
            pct = 0.80;
          }
          rir = 2;
        } else if (pct > 0.78) {
          pct = 0.78;
        }
      case WeekIntent.intensification || WeekIntent.realization when _repsAim:
        // Objectif de répétitions maximales (sans épreuve de force) : le
        // lest garde des séries de 5 à 75 à 80 % — la réserve de force sert
        // l'endurance de force, le travail spécifique se fait au poids du
        // corps (CX, panel : 4 × 3 lourd en réalisation ne transfère pas
        // vers un maximum de répétitions ; R4-G1, R4-G2).
        reps = 5;
        pct = 0.75 + 0.015 * stage;
        if (pct > 0.80) {
          pct = 0.80;
        }
        rir = 3;
      case WeekIntent.intensification:
        reps = 4;
        pct = 0.78 + 0.015 * stage;
        if (pct > 0.84) {
          pct = 0.84;
        }
        rir = 3;
      case WeekIntent.realization:
        reps = 3;
        pct = 0.82;
        rir = 3;
      case WeekIntent.taper:
        reps = 2;
        pct = coachTaperShare;
        sets = 2;
      case WeekIntent.deload ||
          WeekIntent.test ||
          WeekIntent.competition ||
          WeekIntent.transition:
        reps =
            _shape.phase == SeasonPhaseKind.intensification ||
                _shape.phase == SeasonPhaseKind.realization
            ? 4
            : 6;
        pct = ws.intent == WeekIntent.transition
            ? 0.60
            : (reps == 4 ? 0.72 : 0.67);
        sets = 2;
        rir = 4;
    }
    if (role == _DayRole.primerFar) {
      if (_easyDay(role)) {
        return null;
      }
      reps = 3;
      pct = 0.78;
      sets = 2;
      rir = 4;
    }
    if (_muscleUp(x.e) && reps > 3) {
      reps = 3;
    }
    x
      ..sets = sets
      ..minSets = 2
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = _rirOf(x.e, rir, ws, week)
      ..rest = 180
      ..ramped = true;
    _loadAt(x, pct, s.referenceId);
    _honest(x, week);
    if (!x.calibrate && ws.kind == WeekKind.build) {
      x.reasons.add(_rule(CoachRules.loadStep, 1.5, 'pct'));
    }
    return x;
  }

  _Draft? _liftLight(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role != _DayRole.normal ||
        ws.intent == WeekIntent.taper ||
        ws.intent == WeekIntent.transition) {
      return null;
    }
    // R2-P7, R3-P3 : séance légère à 65 à 70 %, loin de l'échec, pour la
    // technique et la vitesse.
    final x = _new(s);
    final pct = ws.light ? 0.65 : 0.70;
    // Muscle-up lesté : doubles techniques (deuxième exposition de la
    // semaine, à l'état frais).
    final reps = _muscleUp(x.e) ? 2 : 3;
    x
      ..sets = ws.light ? 2 : s.sets
      ..minSets = 2
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = 5
      ..rest = 120;
    _loadAt(x, pct, s.referenceId);
    // (La note donne la part réelle : poids du corps compris, elle peut
    // dépasser la part visée.)
    x.reasons.add(_note(CoachNotes.speedWork, x.percent ?? pct));
    return x;
  }

  _Draft? _liftVariant(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    // R3-P13, R2-P9 : les variantes ciblées s'arrêtent à l'approche de
    // l'échéance (spécificité).
    if (role != _DayRole.normal ||
        ws.intent == WeekIntent.taper ||
        ws.intent == WeekIntent.competition ||
        ws.intent == WeekIntent.transition) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final weak = s.weak;
    final referenceId = s.referenceId;
    if (weak != null && referenceId != null) {
      x.reasons.add(
        reason(ReasonCodes.planWeakPoint, <String, Object?>{
          'exerciseId': referenceId,
          'kind': weak.code,
        }),
      );
    }
    if (e.unit == MeasureUnit.seconds) {
      x
        ..sets = ws.light ? 2 : s.sets
        ..secondsLow = 15
        ..secondsHigh = 25
        ..isometric = true
        ..rir = _rirOf(e, 3, ws, week)
        ..rest = 120;
      return x;
    }
    final stage = _stage(ws);
    final intense =
        ws.intent == WeekIntent.intensification ||
        ws.intent == WeekIntent.realization;
    final partial = e.id.contains('partiel');
    if (partial &&
        (ws.light ||
            ws.intent == WeekIntent.realization ||
            (ws.weeksToEvent ?? 99) <= 4)) {
      // Semaine allégée : pas d'amplitude partielle surchargée (la charge
      // la plus lourde du programme ne va pas dans un allègement) ; ni
      // dans les quatre dernières semaines avant l'échéance (CX : le pic
      // se prépare sur le mouvement complet, R3-P13, et le coude n'a pas
      // à porter la charge la plus lourde de la saison au moment du pic).
      return null;
    }
    // Amplitude partielle (verrouillage) : elle n'a de sens qu'au niveau
    // du 1RM complet et au-dessus (pratique de terrain, CALIBRAGE_CP1 C :
    // 100 à 110 %) — 105 % au plus quand le coude a un antécédent ; les
    // autres variantes restent sous le mouvement de compétition.
    // Coude à antécédent : 90 à 95 % du 1RM complet, jamais au-dessus (CX,
    // panel : des charges supramaximales répétées sur l'extension du coude
    // d'un athlète à antécédent, R5-P24).
    final elbowHistory = a.limitOn(Joint.elbow) != null;
    final top = partial ? (elbowHistory ? 0.95 : 1.10) : 0.80;
    // (Entrée graduée et monotone : 95 % la première semaine, +2,5 % par
    // semaine de charge, et chaque bloc repart du sommet du précédent ;
    // R5-P24.)
    final steps = stage > 2 ? 2 : stage;
    // Coude à antécédent : entrée à 82,5 %, +2,5 % par semaine de charge
    // (82,5, 85, 87,5 %), chaque bloc un cran plus haut, 95 % au plus
    // (R5-P24 : retour par paliers ; panel CX, boucle 1).
    // (Après quatre semaines au moins sans l'amplitude partielle — affûtage,
    // échéance, transition —, elle repart de l'entrée, sans le cran des
    // blocs d'avant : panel CX, correction 1, `street_09`, 95 % repris
    // d'emblée après sept semaines d'absence ; R5-P24.)
    var recent = false;
    for (var k = _history.length - 4; k < _history.length; k++) {
      if (k >= 0 &&
          _history[k].loads.keys.any((key) => key.endsWith('|${e.id}'))) {
        recent = true;
      }
    }
    final carried = recent ? (blockIndex > 2 ? 2 : blockIndex) : 0;
    var pct = partial
        ? (elbowHistory ? 0.825 : 0.95) + 0.05 * carried + 0.025 * steps
        : (intense ? 0.74 : 0.70) + 0.01 * stage;
    if (pct > top) {
      pct = top;
    }
    if (ws.light) {
      pct -= 0.05;
    }
    final reps = intense ? 3 : 4;
    if (referenceId == Ids.weightedMuscleUp &&
        e.rootId != Ids.weightedMuscleUp &&
        a.totalOneRm(e.id) == null) {
      // Éducatif du muscle-up sans record propre : la charge ne se déduit
      // pas du 1RM du muscle-up — elle se règle à la première séance.
      x
        ..sets = ws.light ? 2 : _scaled(s.sets, ws, min: 2)
        ..minSets = 1
        ..repsLow = 4
        ..repsHigh = 6
        ..rir = _rirOf(e, 3, ws, week)
        ..rest = 150;
      if (_basisOf(e) != LoadBasis.bodyweight &&
          _basisOf(e) != LoadBasis.unloaded) {
        x
          ..calibrate = true
          ..reasons.add(reason(ReasonCodes.planToCalibrate));
      }
      return x;
    }
    x
      ..sets = ws.light || ws.intent == WeekIntent.realization
          ? 2
          : _scaled(s.sets, ws, min: 2)
      ..minSets = 1
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = _rirOf(e, 3, ws, week)
      ..rest = 150;
    _loadAt(x, pct, referenceId, over: partial);
    if (!partial) {
      _honest(x, week);
    }
    return x;
  }

  // ------------------------------------------------------------ répétitions

  /// Maximum de répétitions qui règle l'emplacement [s] : le record,
  /// ramené à ce que la reprise permet après une coupure.
  int _maxOf(SlotSpec s, {bool expected = false}) {
    final own = a.reps[s.exerciseId];
    if (own == null) {
      return 0;
    }
    if (a.gapWeeks < 2) {
      // Séries de travail : le dernier repère mesuré, jamais un progrès
      // supposé (CX, boucle 2 : des blocs restaient écrits sur le repère
      // attendu au test du bloc). Seule la cible d'un test (`expected`)
      // vise le repère attendu ce jour-là.
      if (!expected) {
        return own;
      }
      final day = _today;
      if (_measuredAt(s.exerciseId, day)) {
        return own;
      }
      final gain = a.plannedGain(s.exerciseId, GoalMetric.maxReps, own, day);
      return (own * (1 + gain) + 1e-9).floor();
    }
    // Repère mesuré depuis la reprise (test guidé ou compétition daté du
    // début du programme ou après) : c'est le niveau actuel, sans part de
    // reprise (CX, correction 1, panel : `street_04` restait à 9 après deux
    // tests à 11).
    if (!expected && _testedSinceReturn(s.exerciseId)) {
      return own;
    }
    // (Un exercice qui n'a pas été testé garde son repère de reprise : il
    // ne monte jamais sur un progrès supposé.)
    // (Un test seulement écrit n'est pas un test fait : sans mesure depuis
    // la reprise, le repère reste celui de la reprise — panel CX
    // correction 1, `street_04` : dips recalés de 15 à 17 sans test.)
    final regained = (own * (expected ? _regain : _regainAt(0))).floor();
    return regained < 1 ? 1 : regained;
  }

  /// Vrai si le repère de l'exercice [id] est le résultat mesuré du test
  /// du [day] (résultat daté de la semaine qui précède ce jour, ou plus
  /// récent) : le bloc part alors du résultat réel, sans gain supposé
  /// (CX, correction 1).
  /// Plus forte charge totale d'une série de 1 ou 2 répétitions écrite
  /// pour [id] dans les trois semaines d'avant, ou `null`.
  double? _recentHeavyTotal(String id) {
    double? best;
    for (var k = _history.length - 3; k < _history.length; k++) {
      if (k < 0) {
        continue;
      }
      for (final entry in _history[k].loads.entries) {
        final (total, reps) = entry.value;
        if (entry.key.endsWith('|$id') &&
            reps <= 2 &&
            (best == null || total > best)) {
          best = total;
        }
      }
    }
    return best;
  }

  bool _testedSinceReturn(String id) {
    final from = a.profile.createdOn;
    for (final b in a.profile.benchmarks ?? const <Benchmark>[]) {
      final when = b.date;
      if (b.exerciseId == id &&
          when != null &&
          (b.source == BenchmarkSource.guidedTest ||
              b.source == BenchmarkSource.competition) &&
          (b.kind == BenchmarkKind.maxReps ||
              b.kind == BenchmarkKind.maxHold) &&
          when.compareTo(from) >= 0) {
        return true;
      }
    }
    return false;
  }

  bool _measuredAt(String id, CivilDate day) {
    final measured = a.recordDay[id];
    return measured != null && measured.daysUntil(day) <= 7;
  }

  /// Maintien maximal prévu de l'exercice [id] la semaine en cours, ou 0.
  int _holdOf(String id, {bool expected = false}) {
    final own = a.holds[id] ?? 0;
    if (own <= 0) {
      return 0;
    }
    if (!expected || a.gapWeeks >= 2 || _measuredAt(id, _today)) {
      return own;
    }
    final day = _today;
    final gain = a.plannedGain(id, GoalMetric.maxHoldSeconds, own, day);
    return (own * (1 + gain) + 1e-9).floor();
  }

  /// Répétitions possibles à la part [pct] du 1RM (R2-P2 : 1 répétition à
  /// 100 %, 2 à 94 %, 3 à 91 %, 5 à 86 %, 8 à 79 %, 10 à 75 %, 12 à 71 %),
  /// par interpolation.
  double _rmAt(double pct) {
    const table = <(double, double)>[
      (1.0, 1),
      (0.94, 2),
      (0.91, 3),
      (0.86, 5),
      (0.79, 8),
      (0.75, 10),
      (0.71, 12),
    ];
    if (pct >= 1) {
      return 1;
    }
    for (var i = 1; i < table.length; i++) {
      final (high, few) = table[i - 1];
      final (low, many) = table[i];
      if (pct >= low) {
        return few + (many - few) * (high - pct) / (high - low);
      }
    }
    return 12 + (0.71 - pct) / 0.02;
  }

  /// Met d'accord les répétitions, la part du 1RM et la réserve écrite
  /// (R2-P2) : si la série prévue laisserait nettement moins que la réserve
  /// voulue, elle perd des répétitions ; la réserve écrite est celle que la
  /// table donne, jamais plus que celle voulue.
  void _honest(_Draft x, int week) {
    final reps = x.repsHigh;
    final wanted = x.rir;
    final target = x.intensity;
    if (reps == null ||
        wanted == null ||
        wanted >= 5 ||
        target == null ||
        target.basis != IntensityBasis.percentOneRm ||
        x.kind != SetKind.work) {
      return;
    }
    final pct = x.share ?? target.value;
    if (pct <= 0 || pct > 1) {
      return;
    }
    final possible = _rmAt(pct);
    final floor = _floorRir(x.e, week);
    final least = (floor > wanted - 1 ? floor : wanted - 1) - 0.25;
    var kept = reps;
    while (kept > 1 && possible - kept < least) {
      kept--;
    }
    var real = (possible - kept + 0.5).floorToDouble();
    if (real > wanted) {
      real = wanted;
    }
    if (real < floor) {
      real = floor;
    }
    if (kept == 1 && possible - 1 < floor - 0.25) {
      // La réserve plancher n'existe pas à cette charge, même sur une
      // seule répétition : la charge descend jusqu'à la part qui la
      // laisse (R2-P2) — l'étiquette ne ment pas.
      final total = _totalFor(x.e, x.slot?.referenceId);
      final lower = _pctAt(1 + floor.ceil());
      if (total != null && lower < pct) {
        x
          ..load = _external(x.e, total, lower)
          ..share = lower
          ..intensity = target.copyWith(value: _round3(lower))
          ..reasons.removeWhere((r) => r.code == ReasonCodes.planPercentBased)
          ..reasons.add(
            reason(ReasonCodes.planPercentBased, <String, Object?>{
              'pct': _round3(lower),
            }),
          );
        if (x.percent != null) {
          x.percent = _round3(lower);
        }
      }
    }
    x
      ..repsLow = kept
      ..repsHigh = kept
      ..rir = real;
    if (x.backoff && x.backoffRepsHigh > kept && _muscleUp(x.e)) {
      x
        ..backoffRepsLow = kept
        ..backoffRepsHigh = kept;
    }
  }

  /// Vrai pour le muscle-up lesté et ses variantes.
  bool _muscleUp(CatalogExercise e) =>
      e.id == Ids.weightedMuscleUp || e.rootId == Ids.weightedMuscleUp;

  IntensityTarget _shareOf(String exerciseId, int reps, int max) =>
      IntensityTarget(
        basis: IntensityBasis.percentBenchmark,
        value: _round3(reps / max > 1 ? 1 : reps / max),
        referenceExerciseId: exerciseId,
        referenceKind: BenchmarkKind.maxReps,
      );

  _Draft? _repsTop(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    final e = x.e;
    final max = _maxOf(s);
    if (max < 4) {
      return _repsStrength(s, ws, week, role);
    }
    final risk = coachHighRisk(e);
    final stage = _stage(ws);
    if (ws.light &&
        ws.intent != WeekIntent.intro &&
        ws.intent != WeekIntent.taper) {
      final reps = _clampInt(_round(max * 0.6), 1, max);
      x
        ..sets = 2
        ..minSets = 2
        ..repsLow = reps
        ..repsHigh = reps
        ..rir = _rirOf(e, 4, ws, week)
        ..rest = 150
        ..intensity = _shareOf(e.id, reps, max);
      return x;
    }
    // R4-G3 : une série longue à 1 à 3 répétitions de l'échec, puis des
    // séries à 60 à 70 % du maximum.
    // R4-G3 : 2 répétitions en réserve sur la série de tête ; une seule
    // semaine sur deux descend à 1, en réalisation seulement (la proximité
    // de l'échec ajoute de la fatigue, pas de force). Sur les séries
    // longues, la réserve se lit mal : la marge vaut au moins 8 % du
    // maximum.
    final realization = ws.intent == WeekIntent.realization;
    var margin = realization
        ? (ws.stage.isOdd && _level >= 2 ? 1 : 2)
        : 3 - (stage > 1 ? 1 : stage);
    if (ws.intent == WeekIntent.intro) {
      margin = 4;
    }
    // Séries longues (15 répétitions et plus de maximum) : la réserve dite
    // n'est plus fiable au-delà d'une douzaine de répétitions (Zourdos et
    // al. 2021 ; Halperin et al. 2022) — hors réalisation, la série de tête
    // se pilote à 88 % du maximum environ (marge de 12 %), pas au ressenti
    // (CX, correction 1 : 25 tractions finies à 0,4 en réserve pour 2
    // visées).
    final relative = _round(max * (realization || max < 15 ? 0.08 : 0.12));
    if (margin < relative) {
      margin = relative;
    }
    if (ws.intent == WeekIntent.taper) {
      // R3-P13, R3-P21 : à l'affûtage, les séries tombent et la série de
      // tête reste à 85 % du maximum environ, loin de l'échec.
      margin = _round(max * 0.15) < 3 ? 3 : _round(max * 0.15);
    }
    var floor = risk || _level == 0 ? 2 : 1;
    // La réserve écrite est la vraie : les planchers (reprise, zone à
    // ménager, risque) règlent les répétitions, pas seulement l'étiquette.
    final kept = _floorRir(e, week).ceil();
    if (floor < kept) {
      floor = kept;
    }
    if (margin < floor) {
      margin = floor;
    }
    final bonus = a.rirBonus.round();
    final top = _clampInt(max - margin - bonus, 1, max);
    // Séries allégées : +3 % du maximum par semaine de charge (une
    // répétition environ), 74 % au plus — la seule variable qui monte quand
    // la série de tête reste (CX, correction 1, panel : séries principales
    // identiques quatre semaines de suite ; R4-G8).
    final lift = ws.kind == WeekKind.build
        ? 0.03 * (ws.stage > 3 ? 3 : ws.stage)
        : 0.0;
    // (Les séries allégées restent au moins une répétition sous la série de
    // tête : à repos incomplet, la même plage ne garde pas la réserve —
    // panel CX correction 1, « 1 × 6, puis 2 × 6 » sur un maximum de 9.)
    final back = _clampInt(
      _round(max * (0.65 + lift)),
      1,
      top >= 3 ? top - 1 : top,
    );
    final sets = ws.intent == WeekIntent.taper
        ? 2
        : _scaled(s.sets, ws, min: 2);
    x
      ..sets = sets
      ..minSets = 2
      ..repsLow = top
      ..repsHigh = top
      // La réserve écrite est la vraie : maximum moins répétitions.
      ..rir = max - top > coachHardSetMaxRir
          ? coachHardSetMaxRir
          : (max - top < floor ? floor.toDouble() : (max - top).toDouble())
      // Phase spécifique d'une échéance de répétitions : repos de 2 min
      // entre les séries (R4-G4 : endurance de force, 15 à 60 s chez
      // l'avancé ; panel CX correction 1 : séries allégées à 3 min et très
      // loin de l'échec, sans effet sur l'endurance spécifique).
      ..rest =
          _repsAim && (realization || ws.intent == WeekIntent.intensification)
          ? 120
          : 180
      ..backoff = true
      ..backoffRepsLow = back
      ..backoffRepsHigh = back
      ..intensity = _shareOf(e.id, top, max)
      ..reasons.add(
        _note(
          e.id == Ids.muscleUp || e.rootId == Ids.muscleUp
              ? CoachNotes.rampMuscleUp
              : CoachNotes.rampBodyweight,
          2,
        ),
      )
      ..reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
    // Objectif de série longue (15 répétitions et plus) : à partir du
    // deuxième bloc, la dernière série de la séance lourde se finit en
    // repos-pause jusqu'au total visé (R4-G6, R4-G7 : endurance de la fin
    // de série, au format de l'épreuve) — pas sur un mouvement à risque,
    // ni avec une zone à ménager.
    final wanted = a.goalOn(e.id, GoalMetric.maxReps)?.targetValue;
    if (wanted != null &&
        wanted >= 8 &&
        wanted > max &&
        !risk &&
        kept < 2 &&
        // (Repos-pause sur le mouvement principal : avancé et élite ;
        // l'intermédiaire seulement en réalisation, une fois par semaine —
        // CP2, partie 0 : panel CX correction 1, `street_06`, 11, 14, 15, 17
        // : « une série au maximum − 2 suivie de mini-séries » ; R2-P13,
        // R4-G6, R4-G7.)
        (_level >= 2 || (_level == 1 && realization)) &&
        ws.kind == WeekKind.build &&
        (ws.stage >= 1 || realization) &&
        (blockIndex >= 1 || realization) &&
        // Un seul mouvement en repos-pause par semaine : le tirage les
        // semaines impaires du bloc, la poussée les semaines paires.
        ((e.pattern == MovementPattern.tirageVertical) == ws.stage.isOdd ||
            !_twoLongGoals)) {
      x.reasons.add(_note(CoachNotes.restPause, 3));
    }
    // Simulation du test d'un objectif de répétitions, à dix jours environ
    // (dernière semaine de réalisation avant l'affûtage ou le test) : la
    // série de tête se fait au format du test, jusqu'à une répétition de
    // l'échec (R3-P20 ; panel CX correction 1, `street_11`, 13, 14 : « une
    // simulation de série longue au format du test à J−10 »). Pas sur un
    // mouvement à risque ni une zone à ménager.
    final next = week + 1 < _shape.weeks.length ? _shape.weeks[week + 1] : null;
    if (wanted != null &&
        wanted > max &&
        realization &&
        ws.kind == WeekKind.build &&
        next != null &&
        (next.intent == WeekIntent.taper || next.testWeek) &&
        !risk &&
        kept < 2 &&
        _level >= 1 &&
        max >= 6) {
      final rehearsal = max - 1;
      x
        ..sets = 1
        ..minSets = 1
        ..backoff = false
        ..repsLow = rehearsal
        ..repsHigh = rehearsal
        ..rir = 1
        ..rest = 180
        ..intensity = _shareOf(e.id, rehearsal, max)
        ..reasons.removeWhere(
          (r) =>
              r.code == ReasonCodes.planCoachNote &&
              r.params['note'] == CoachNotes.restPause,
        )
        ..reasons.add(_note(CoachNotes.repsRehearsal, rehearsal));
    }
    return x;
  }

  _Draft? _repsVolume(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.primerNear) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final max = _maxOf(s);
    final stage = _stage(ws);
    final sets = _scaled(s.sets, ws, min: 2);
    x
      ..sets = role == _DayRole.primerFar ? 2 : sets
      ..minSets = 2
      // R4-G4 : repos de l'endurance de force — au moins 90 s chez le
      // débutant, 45 à 90 s chez l'intermédiaire, 15 à 60 s ensuite.
      ..rest = s.group != null
          ? 60
          : (_level == 0 ? 120 : (_level == 1 ? 90 : 60));
    if (max <= 0) {
      x
        ..repsLow = 5
        ..repsHigh = 8
        ..rir = _rirOf(e, 3, ws, week)
        ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
      if (s.note == 'pull_return') {
        x.reasons.add(_note(CoachNotes.pullReturn, 2.5));
      }
      return x;
    }
    // R4-G4 : volume sous-maximal à 50 à 70 % du maximum, 3 répétitions en
    // réserve au moins.
    var share = (max >= 12 ? 0.60 : 0.55) + 0.03 * stage;
    if (share > 0.70) {
      share = 0.70;
    }
    final specific =
        ws.intent == WeekIntent.intensification ||
        ws.intent == WeekIntent.realization;
    if (specific && _repsAim) {
      // Phase spécifique d'une échéance de répétitions : séries
      // sous-maximales de 65 à 75 % du maximum, une marche par semaine
      // (R3-P20, R4-G3 ; panel CX, boucle 1 : le bloc de réalisation ne
      // doit pas être plus léger que la construction).
      share = 0.65 + 0.03 * (ws.stage > 3 ? 3 : ws.stage);
      if (share > 0.75) {
        share = 0.75;
      }
    }
    // Réalisation d'un objectif de répétitions maximales, sur le mouvement
    // visé : séries dans la zone de l'épreuve — 72 à 80 % du maximum,
    // repos court, 2 répétitions en réserve (R4-G1 : la moitié au moins du
    // bloc spécifique dans la zone de l'épreuve ; R4-G4 : 45 à 90 s de
    // repos ; panel et relecture documentée CX, correction 1 : bloc de
    // réalisation identique à la construction).
    final eventZone =
        ws.intent == WeekIntent.realization &&
        ws.kind == WeekKind.build &&
        _repsAim &&
        role == _DayRole.normal &&
        s.group == null &&
        max >= 6 &&
        a.goalOn(e.id, GoalMetric.maxReps) != null;
    if (eventZone) {
      share = 0.72 + 0.03 * (ws.stage > 2 ? 2 : ws.stage);
      if (share > 0.80) {
        share = 0.80;
      }
    }
    if (ws.intent == WeekIntent.intro && role != _DayRole.primerFar) {
      // Introduction : une marche sous la semaine suivante, pas une moitié
      // (panel CX, boucle 4 : 3 × 25 puis 4 × 34 d'une semaine à l'autre ;
      // R5-P22, +10 à 20 %).
      share -= 0.05;
    } else if (role == _DayRole.primerFar ||
        (ws.light && ws.intent != WeekIntent.taper)) {
      // (Affûtage : l'intensité reste, seules les séries baissent — R3-P13 ;
      // panel CX, correction 1 : séries à 40-50 % en semaine d'affûtage.)
      share = 0.5;
    }
    final reps = _clampInt(_round(max * share), 1, max);
    if (reps >= 20 && x.rest < 120 && s.group == null) {
      // Séries très longues : deux minutes de repos, sinon la réserve
      // prévue ne tient pas sur les dernières séries.
      x.rest = 120;
    }
    x
      ..repsLow = reps
      ..repsHigh = reps
      // R4-G3, R4-G4 : 3 répétitions en réserve au moins. Sous douze
      // répétitions de maximum, la réserve se lit dès la première série ;
      // au-delà, les séries longues à repos court se cumulent et c'est sur
      // les dernières séries que la réserve tombe à 3 ou 4.
      ..rir = max >= 12
          ? _rirOf(e, 3, ws, week)
          // (Sous douze : la réserve écrite est la vraie, maximum moins
          // répétitions.)
          : (max - reps > coachHardSetMaxRir
                ? (max - reps).toDouble()
                : (max - reps < _floorRir(e, week)
                      ? _floorRir(e, week)
                      : (max - reps).toDouble()))
      ..intensity = _shareOf(e.id, reps, max);
    if (e.pattern == MovementPattern.tirageVertical &&
        s.group == null &&
        x.rest < 120 &&
        !eventZone) {
      // Tirage vertical : deux minutes entre les séries (R1-P16).
      x.rest = 120;
    }
    if (eventZone) {
      final rir = _rirOf(e, 2, ws, week);
      // (Répétitions + réserve jamais au-dessus du maximum : « série =
      // maximum − 2 » — panel CX, correction 1, passe 5 : 3 × 7 à 3 en
      // réserve sur un maximum de 9.)
      final top = max - rir.round();
      if (top >= 1 && reps > top) {
        x
          ..repsLow = top
          ..repsHigh = top
          ..intensity = _shareOf(e.id, top, max);
      }
      // (La part dite dans la note est celle des répétitions écrites —
      // passe 7 du panel, `street_15` : note à 75 % pour 3 × 5 à 63 %.)
      final shown = (x.repsHigh ?? reps) / max;
      // Repos raccourci de 15 s par semaine de réalisation (75-90 s, puis
      // 60-75 s, 45 s au plus court) : la densité monte, une variable à la
      // fois (R4-G4 : 45 à 90 s ; panel CX correction 1, `street_06` :
      // « repos réduit de 15 s par semaine sur les séries de la zone de
      // l'épreuve »).
      final shorter = 15 * (ws.stage > 2 ? 2 : ws.stage);
      final rest = (_level >= 2 ? 75 : 90) - shorter;
      x
        ..rest = rest < 45 ? 45 : rest
        ..rir = rir
        ..reasons.add(_note(CoachNotes.eventZone, _round(shown * 100)));
    }
    if (ws.kind == WeekKind.build) {
      x.reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
    }
    if (s.note == 'pull_return') {
      x.reasons.add(_note(CoachNotes.pullReturn, 2.5));
    }
    return x;
  }

  _Draft? _repsDensity(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if ((role != _DayRole.normal && role != _DayRole.primerFar) ||
        ws.intent == WeekIntent.transition) {
      return null;
    }
    final max = _maxOf(s);
    if (max < 7 || role == _DayRole.primerFar) {
      // (Semaine de l'échéance : deux séries courtes à la place du chrono.)
      return _repsVolume(s, ws, week, role);
    }
    final x = _new(s);
    final e = x.e;
    // R4-G6 : densité — départs au chrono à 30 à 50 % du maximum (40 %
    // chez l'intermédiaire, 40 à 50 % ensuite) ; on ajoute des séries
    // avant d'ajouter des répétitions.
    var share = _level >= 2 ? 0.45 : 0.40;
    if (coachHighRisk(e)) {
      share = 0.30;
    } else if ((ws.intent == WeekIntent.intensification ||
            ws.intent == WeekIntent.realization) &&
        _repsAim &&
        !ws.light) {
      // Phase spécifique d'une échéance de répétitions : les départs
      // montent de 5 % du maximum par semaine, jusqu'à 55 % (R4-G6 : 30 à
      // 50 %, puis la densité de l'épreuve ; panel CX, boucle 1 : départs
      // figés quatre semaines).
      share += 0.05 * (ws.stage > 2 ? 2 : ws.stage) + 0.05;
      if (share > 0.55) {
        share = 0.55;
      }
    }
    // (Une répétition de plus par départ vaut plus de 10 % du maximum sous
    // dix répétitions : la densité monte alors par les départs, jamais par
    // les répétitions — R5-P22 ; panel CX, correction 1 : 2 puis 3
    // répétitions par départ pour un maximum de 5, +50 % de volume.)
    if (max < 10 && !coachHighRisk(e)) {
      share = _level >= 2 ? 0.45 : 0.40;
    }
    var reps = _clampInt(_round(max * share), 1, max);
    // (Départ loin de l'échec, comme l'écrit la consigne : 5 répétitions en
    // réserve au moins sur le premier — panel CX, correction 1 : « 5 en
    // réserve ou plus » écrit pour 4 répétitions sur un maximum de 8 ;
    // sous 7 répétitions de maximum, la densité cède la place au volume.)
    if (reps > max - 5) {
      reps = max - 5 < 1 ? 1 : max - 5;
    }
    // R5-P22 : +10 à 20 % par semaine au plus — un départ de plus toutes
    // les deux semaines de charge (toutes les trois à 40 ans et plus), deux
    // au plus dans le bloc ; aucun tant que le profil gèle le volume.
    // (Le compte part d'un départ sous la base, monte d'un départ toutes
    // les deux semaines de charge du bloc, et d'un départ par bloc.)
    var minutes = s.sets - 1 + (blockIndex > 2 ? 2 : blockIndex);
    // Une seule variable à la fois (CX, correction 1 : départs et
    // répétitions par départ montaient la même semaine) : quand les
    // répétitions par départ montent avec la phase spécifique, le nombre
    // de départs reste.
    final repsRise =
        (ws.intent == WeekIntent.intensification ||
            ws.intent == WeekIntent.realization) &&
        _repsAim &&
        !ws.light &&
        max >= 10 &&
        !coachHighRisk(e);
    if (ws.kind == WeekKind.build || ws.kind == WeekKind.intro) {
      final step = a.freezeVolume || repsRise
          ? 0
          : (_slow ? _loadedBefore ~/ 3 : _loadedBefore ~/ 2);
      minutes += step > 2 ? 2 : step;
    } else {
      minutes = _round(minutes * ws.volume);
    }
    if (role == _DayRole.primerFar && minutes > 4) {
      minutes = 4;
    }
    if (minutes < 4) {
      minutes = 4;
    }
    if (minutes > 10) {
      minutes = 10;
    }
    // Départs au chrono : l'effort tient dans la moitié de l'intervalle.
    final work = (reps * coachSecondsPerRep).round();
    var interval = ((work * 2 + 29) ~/ 30) * 30;
    if (interval < 60) {
      interval = 60;
    }
    if (interval > 180) {
      interval = 180;
    }
    x
      ..sets = minutes
      ..minSets = 4
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = 5
      ..rest = interval - work < 15 ? 15 : interval - work
      ..everyMinute = true
      ..interval = interval
      ..intensity = _shareOf(e.id, reps, max)
      ..reasons.add(_note(CoachNotes.everyMinute, interval))
      ..reasons.add(_rule(CoachRules.densityStep, 1, 'min'));
    if (e.id == Ids.muscleUp || e.rootId == Ids.muscleUp) {
      x.reasons.add(_note(CoachNotes.rampMuscleUp, 2));
    }
    return x;
  }

  _Draft? _repsStrength(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.primerNear) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final max = _maxOf(s);
    final sets = _scaled(s.sets, ws, min: 2);
    x
      ..sets = role == _DayRole.primerFar ? 2 : sets
      ..minSets = 2
      ..rest = s.group != null ? 75 : 180;
    if (_basisOf(e) == LoadBasis.bodyweightPlusExternal ||
        _basisOf(e) == LoadBasis.external) {
      // Lest sans record : séries de 5, charge réglée à la première séance.
      x
        ..repsLow = 5
        ..repsHigh = 5
        ..rir = _rirOf(e, 3, ws, week);
      final baseId = s.referenceId;
      final known = baseId == null ? 0 : (a.reps[baseId] ?? 0);
      final weight = (e.bodyweightFraction?.value ?? 0) * a.bodyWeight;
      if (_totalFor(e, baseId) == null && known >= 3 && weight > 0) {
        // Charge de départ estimée d'après le maximum au poids du corps :
        // table R2-P2 jusqu'à 12 répétitions ; au-delà, formule d'Epley
        // bornée à 20 répétitions (estimation prudente, à ajuster à la
        // première séance). 5 répétitions à 3 de l'échec, puis +1,5 % par
        // semaine de charge.
        final stage = _stage(ws);
        final total = known <= 12
            ? weight / _pctAt(known)
            : weight * (1 + (known > 20 ? 20 : known) / 30);
        var pct = 0.77 + 0.015 * (stage > 4 ? 4 : stage);
        // (Jamais plus lourd que ce que la table donne pour 5 répétitions
        // plus la réserve écrite.)
        final honest = _pctAt(5 + (x.rir ?? 3).ceil());
        if (pct > honest) {
          pct = honest;
        }
        if (ws.light) {
          // Allègement : les séries tombent, la charge reste à 3 % près
          // (le retour à la charge du bloc reste sous +5 %).
          pct -= 0.03;
        }
        final load = _external(e, total, pct);
        x
          ..load = load
          ..reasons.add(_rule(CoachRules.loadStep, 1.5, 'pct'));
        if (blockIndex == 0 && week == 0) {
          x.reasons.add(_note(CoachNotes.estimatedLoad, load ?? 0));
        }
        return x;
      }
      _loadAt(x, 0.78, s.referenceId);
      if (!x.calibrate) {
        x.reasons.add(_rule(CoachRules.loadStep, 1.5, 'pct'));
      }
      return x;
    }
    if (max > 0) {
      // R4-G2 : sous 8 répétitions, la force d'abord — séries courtes à 2
      // répétitions de l'échec.
      // (3 en réserve en semaine d'introduction ou allégée, 2 ensuite : la
      // progression vient de la réserve, pas d'un progrès supposé. La
      // première semaine de charge d'un bloc spécifique garde 2 en réserve —
      // CX, correction 1, panel : 3 × 2 à 40 % au début du bloc de
      // réalisation, moins que la construction.)
      var margin =
          2 +
          ((ws.light && ws.intent != WeekIntent.taper) ||
                  ws.kind == WeekKind.intro
              ? 1
              : 0) +
          a.rirBonus.round();
      final kept = _floorRir(e, week).ceil();
      if (margin < kept) {
        margin = kept;
      }
      final reps = _clampInt(max - margin, 1, max);
      // La réserve écrite est la vraie (maximum moins répétitions), sans
      // bonus d'introduction : les répétitions ne changent pas.
      final real = (max - reps).toDouble();
      // (Plage d'une répétition en semaine de charge : la répétition de
      // plus se prend quand la réserve le permet, elle n'est pas supposée.)
      final open = ws.kind == WeekKind.build && ws.stage >= 1 && reps < max - 1;
      x
        ..repsLow = reps
        ..repsHigh = open ? reps + 1 : reps
        ..rir = real < kept
            ? kept.toDouble()
            : (real > coachHardSetMaxRir ? coachHardSetMaxRir : real)
        ..intensity = _shareOf(e.id, reps, max)
        ..reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
      return x;
    }
    // Variante dure sans record : plage réglée sur le maximum du geste de
    // base (une variante dure vaut environ 60 % de ce maximum — choix
    // raisonné), 2 en réserve ; sans repère, 3 à 6 répétitions.
    final referenceId = s.referenceId;
    final base = referenceId == null
        ? 0
        : _maxOf(
            SlotSpec(exerciseId: referenceId, role: s.role, method: s.method),
          );
    var high = 6;
    if (base > 0) {
      high = _clampInt(_round(base * 0.6) - 2, 4, 12);
    }
    if (e.id.contains('tempo-excentrique')) {
      // Traction complète au tempo lent : montée tirée, 2 s tenues en haut,
      // descente en 4 s — environ 45 % du maximum au tempo normal, 4 à 10
      // répétitions (CX, correction 1, panel : à 3 à 6 répétitions, un
      // athlète à 18 tractions finissait à 8 de réserve ; la montée n'est
      // pas sautée).
      high = _clampInt(_round(base * 0.45), 4, 10);
      x
        ..tempo = const Tempo(
          eccentricSeconds: 4,
          bottomPauseSeconds: 0,
          concentricSeconds: 0,
          topPauseSeconds: 2,
        )
        ..reasons.add(_note(CoachNotes.slowTempo, 4));
    }
    x
      ..repsLow = (high - 2 < 3 ? 3 : high - 2) + _shift(ws)
      ..repsHigh = high + _shift(ws)
      ..rir = _rirOf(e, 2, ws, week)
      ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
    return x;
  }

  _Draft? _repsTechnique(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.primerNear || role == _DayRole.after) {
      return null;
    }
    if (s.role == SlotRole.secondary &&
        s.exerciseId == Ids.pull &&
        (ws.testWeek || ws.eventWeek)) {
      // Exposition légère de traction : elle saute en semaine de test (48 h
      // sans tirage avant le test).
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final max = _maxOf(s);
    // R4-F1, R5-P27 : technique à l'état frais, séries très courtes, 2
    // répétitions en réserve au moins, arrêt dès que la qualité baisse.
    final reps = max <= 3 ? 1 : (max <= 5 ? 2 : _round(max * 0.5));
    if (max > 0 && max - reps < _floorRir(e, week)) {
      // La réserve demandée (mouvement à risque, reprise) n'existe pas
      // encore sur le geste complet : il attend, le travail passe par les
      // éducatifs et le tirage.
      return null;
    }
    final sets = _scaled(s.sets + (max <= 3 ? 1 : 0), ws, min: 2);
    x
      ..sets = sets
      ..minSets = 3
      ..repsLow = reps
      ..repsHigh = reps
      // La réserve écrite est la vraie : maximum moins répétitions.
      // (Pas de bonus d'introduction ici : les répétitions ne changent pas,
      // l'étiquette non plus.)
      ..rir = max <= 0
          ? _rirOf(e, 3, ws, week)
          : (max - reps > 4 ? 4.0 : (max - reps).toDouble())
      ..rest = 150
      ..practice = true
      ..reasons.add(_note(CoachNotes.qualityFirst, 4));
    if (max > 0) {
      x.intensity = _shareOf(e.id, reps, max);
    }
    if (e.id == Ids.muscleUp || e.rootId == Ids.muscleUp) {
      x.reasons.add(_note(CoachNotes.rampMuscleUp, 2));
    }
    return x;
  }

  // --------------------------------------------------------------- débutant

  _Draft? _beginnerMain(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    final e = x.e;
    var sets = _scaled(s.sets, ws, min: s.sets >= 3 ? 2 : 1);
    if (blockIndex == 0 && week < 2 && sets > 2) {
      // R5-P1, R5-P22 : les deux premières semaines à deux séries par
      // exercice, puis trois — le volume monte avant l'effort.
      sets = 2;
    }
    x
      ..sets = sets
      ..minSets = 1
      ..rest = 120;
    if (e.unit == MeasureUnit.seconds) {
      final known = a.holds[e.id] ?? 0;
      final hold = known > 0 ? _clampInt(_round(known * 0.6), 8, 40) : 15;
      x
        ..secondsLow = hold
        ..secondsHigh = hold + 10
        ..isometric = true
        ..rir = _rirOf(e, 3, ws, week)
        ..reasons.add(_rule(CoachRules.holdStep, 5, 's'));
      return x;
    }
    final max = _maxOf(s);
    final firm = blockIndex > 0 ? 2.0 : 3.0;
    if (max >= 1 && max < 6) {
      // Geste tout juste acquis : séries très courtes, deux répétitions
      // sous le maximum mesuré, et de plus en plus nombreuses (la
      // progression vient des séries — trois, puis quatre, puis cinq —,
      // pas d'un progrès supposé ; R5-P3).
      final stage = ws.kind == WeekKind.build ? _stage(ws) : 0;
      final more = sets + 1 + (stage >= 2 ? 1 : 0) + (stage >= 4 ? 1 : 0);
      final kept = _floorRir(e, week).ceil() < 2
          ? 2
          : _floorRir(e, week).ceil();
      final reps = max - kept < 1 ? 1 : max - kept;
      // Plage ouverte vers le haut (double progression, R5-P3) : une
      // répétition de plus dès que toutes les séries passent avec la
      // réserve prévue — la progression suit ce qui est réussi, elle
      // n'est pas supposée.
      // Pompe au sol d'un objectif de pompes : des séries courtes répétées
      // (5 × 1-2, grappes ; panel CX, boucle 4), pas une ou deux
      // répétitions isolées.
      final clusters = e.id == Ids.pushUp && a.aimsAt(Ids.pushUp) && !ws.light;
      x
        ..sets = clusters
            ? 5
            : (ws.light || blockIndex == 0 ? sets : (more > 4 ? 4 : more))
        ..repsLow = reps
        // Le haut de la plage s'ouvre d'une répétition toutes les deux
        // semaines de charge : le bas reste sûr (maximum moins la
        // réserve), le haut donne la cible de la semaine.
        ..repsHigh = ws.light ? reps : reps + 2 + _shift(ws)
        ..rir = max - reps < kept ? kept.toDouble() : (max - reps).toDouble()
        ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
      return x;
    }
    if (max >= 6) {
      // R5-P2, R5-P4 : 50 à 70 % du maximum, 3 répétitions en réserve.
      // 50 à 70 % du maximum, sans jamais dépasser le maximum moins trois
      // (la réserve demandée doit exister).
      final shift = _shift(ws);
      final top = max - 3 < 1 ? 1 : max - 3;
      var high = _clampInt(_round(max * 0.7) + shift, 1, top);
      var low = _clampInt(_round(max * 0.5) + shift, 1, high);
      final ladderStep =
          s.referenceId == Ids.pushUp &&
          e.id != Ids.pushUp &&
          coachPushLadder.contains(e.id);
      if (ladderStep && high > 12) {
        // Palier de l'échelle de poussée : la variante facile ne devient
        // pas une série d'endurance — au-delà de 3 × 10 propres, l'appui
        // baisse d'un cran (mains plus basses) et la plage reste à 8-12
        // (R5-P9 ; panel CX, boucle 1).
        high = 12;
        low = low > 8 ? 8 : low;
      }
      // Maximum de plus de 15 sur l'appui mains surélevées : l'appui
      // descend dès ce bloc, d'un cran de 10 cm par tranche de 5
      // répétitions au-delà de 13, et les séries sont écrites pour le
      // nouvel appui (12 à 14 au maximum : 8 à 11 répétitions, 2 à 3 en
      // réserve — R5-P9 ; CP2, partie 0, boucle 2 ; panel p1, `street_02` :
      // 15 semaines sur le même appui, test à 26-28).
      final lower = ladderStep && e.id == 'sw-pompe-inclinee' && max > 15;
      if (lower) {
        high = 11;
        low = 8;
        // (Une seule consigne, à la première semaine du bloc — panel p2,
        // `street_02`, `street_03`.)
        if (week == 0) {
          x.reasons.add(
            _note(
              CoachNotes.pushHeight,
              _clampInt(((max - 13) / 5).ceil(), 1, 3),
            ),
          );
        }
      }
      x
        ..repsLow = low
        ..repsHigh = high
        // 3 en réserve le premier bloc (R5-P4), 2 ensuite.
        ..rir = _rirOf(e, firm, ws, week);
      // Palier de l'échelle de poussée : un seul critère de passage, celui
      // de l'échelle (CP2, partie 0 ; panel CX correction 1, `street_02`,
      // `street_03` : la double progression et l'échelle se contredisaient).
      x.reasons.add(
        ladderStep
            ? _note(CoachNotes.pushLadder, 12)
            : _rule(CoachRules.doubleProgression, 1, 'reps'),
      );
      return x;
    }
    // R5-P9 : une variante qui permet 6 à 10 répétitions avec 3 en réserve.
    if (e.assisted) {
      x.reasons.add(_rule(CoachRules.assistanceStep, 1, 'cran'));
    }
    final ladder = s.referenceId == Ids.pushUp && e.id != Ids.pushUp;
    final lower =
        e.family == MovementFamily.jambesGenou ||
        e.family == MovementFamily.jambesHanche;
    x
      ..repsLow = (lower ? 8 : 6) + _shift(ws)
      ..repsHigh = (lower ? 10 : 8) + _shift(ws)
      ..rir = _rirOf(e, 3, ws, week)
      ..reasons.add(
        ladder
            ? _note(CoachNotes.pushLadder, 12)
            : _rule(CoachRules.doubleProgression, 1, 'reps'),
      );
    return x;
  }

  _Draft? _beginnerNegative(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    // R5-P10 : descentes freinées de 3 à 5 s, peu de répétitions, jamais
    // jusqu'à la perte de contrôle.
    // (R5-P8 : 2 à 3 × 2 à 3, puis 3 × 5 de 5 s ; 15 excentriques par
    // séance au plus.)
    // L'effort d'une descente freinée se règle au contrôle de la descente,
    // pas à la réserve : elle a son propre plafond (15 par séance) et ne
    // compte pas parmi les séries dures.
    // Premier bloc : 4 puis 5 s, 3 puis 4 descentes.
    // CX (panel, saisons) : à partir du deuxième bloc, le nombre de
    // descentes monte vers 3 × 5 de 5 s (R5-P8 ; R2-P17 : 3 à 5 × 3 à 5
    // descentes de 3 à 5 s chez le débutant), au lieu d'allonger la
    // descente à nombre égal — le plafond de 15 par séance reste.
    final stage = ws.stage;
    final push = x.e.id == 'sw-pompe-negative';
    final later = blockIndex > 0 && !push;
    final seconds = later
        ? 5
        : (push ? (stage >= 2 ? 4 : 3) : (stage >= 2 ? 5 : 4));
    final reps = ws.light
        ? 2
        : (later ? (stage >= 2 ? 5 : 4) : (stage >= 3 ? 4 : 3));
    x
      // (Bloc suivant : trois séries un seul jour par semaine, deux
      // l'autre — une dizaine de séries de tirage vertical direct par
      // semaine chez le débutant, R1-P1.)
      ..sets = ws.light
          ? 2
          : (later && (push || _dayNow == _firstNegativeDay) ? 3 : s.sets)
      ..minSets = 1
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = 5
      ..rest = 120
      ..tempo = Tempo(
        eccentricSeconds: seconds,
        bottomPauseSeconds: 0,
        concentricSeconds: 0,
        topPauseSeconds: later ? 2 : 0,
      )
      ..reasons.add(
        _note(
          push ? CoachNotes.slowNegativePush : CoachNotes.slowNegative,
          seconds,
        ),
      );
    if (push) {
      x.rest = 90;
    }
    return x;
  }

  _Draft? _hold(
    SlotSpec s,
    WeekSpec ws,
    int week,
    _DayRole role, {
    required double share,
    required int low,
    required int high,
    required int fallback,
  }) {
    final x = _new(s);
    final e = x.e;
    if (e.unit != MeasureUnit.seconds) {
      // Étape dynamique d'une figure : séries courtes, loin de l'échec.
      x
        ..sets = _scaled(s.sets, ws, min: 2)
        ..minSets = 2
        ..repsLow = 2
        ..repsHigh = 4
        ..rir = _rirOf(e, 3, ws, week)
        ..rest = 120
        ..practice = true;
      return x;
    }
    final known = _holdOf(e.id);
    final stage = _stage(ws);
    // R4-F2, R4-F6 : 50 à 70 % du dernier maintien maximal mesuré ; la
    // séance lourde d'une figure (une séance sur deux) se fait à 75 à 85 %
    // (CX, correction 3 : R4-F6, 70 % et plus pour le tendon ; Oranchuk et
    // al. 2019, revue systématique : l'isométrie adapte le tendon à haute
    // intensité, au-delà de 70 % de l'effort maximal ; Bohm et al. 2015,
    // méta-analyse : charges élevées et répétées). La part monte au fil des
    // semaines de charge, jamais sous celle de l'introduction.
    // CX, correction 1 : les tenues de travail restent à 50 à 70 % du
    // maximum (R4-F2 ; panel CX : à 82 %, chaque séance finissait en
    // position dégradée et les maxima baissaient) ; la séance lourde monte
    // avec la phase — construction 60 %, intensification 65 %, réalisation
    // 70 %, jusqu'à 75 % avec les semaines de charge — pour que le contenu suive le nom de la phase ; le volume se
    // compte en secondes propres cumulées.
    final intense =
        s.method == Method.skillHold &&
        s.stress == DayStress.heavy &&
        _level >= 1;
    var part = share;
    if (intense) {
      // (65 % puis 70 % : panel CX correction 1, plafond écrit de 80 %
      // dépassé en réalisation après arrondi.)
      part = switch (ws.intent) {
        WeekIntent.intensification => 0.65,
        WeekIntent.realization => 0.70,
        _ => 0.60,
      };
    }
    if (ws.kind == WeekKind.build && known > 0) {
      part += 0.02 * (stage > 2 ? 2 : stage);
      final top = intense ? 0.75 : 0.70;
      if (part > top) {
        part = top;
      }
    }
    // (Arrondi au plus proche tant que la tenue reste à 8 points de la
    // part visée et à 76 % du maximum au plus : sur un maximum de 6 s,
    // l'arrondi par défaut faisait d'une tenue « à 60 % » une tenue à
    // 50 % — passe 7 du panel, `street_10`.)
    var hold = known > 0 ? (known * part + 1e-9).round() : fallback;
    if (known > 0 &&
        (hold > known * (part + 0.08) + 1e-9 || hold > known * 0.76 + 1e-9)) {
      hold = (known * part + 1e-9).floor();
    }
    if (known <= 0 && ws.kind == WeekKind.build && stage >= 2) {
      hold += 1;
    }
    hold = _clampInt(hold, low, high);
    var sets = role == _DayRole.primerFar || role == _DayRole.primerNear
        ? 2
        : _scaled(s.sets, ws, min: 2);
    if (role == _DayRole.normal &&
        (s.method == Method.skillHold || s.method == Method.skillEasyHold)) {
      // R4-F2 : secondes propres cumulées par séance et par figure — 20 à
      // 40 chez le débutant, 30 à 60 chez l'intermédiaire, 40 à 60 chez
      // l'avancé, 40 à 75 en élite. R4-F6 : un levier est utile quand son
      // maintien maximal vaut 8 à 25 s ; en dessous, l'étape actuelle se
      // limite à trois essais courts et le temps se fait sur l'étape plus
      // facile.
      const cumulative = <int>[30, 45, 50, 60];
      final paired = skeleton.days.any(
        (d) =>
            d.slots.contains(s) &&
            d.slots.any(
              (o) =>
                  o != s &&
                  o.skillTargetId == s.skillTargetId &&
                  (o.method == Method.skillHold ||
                      o.method == Method.skillEasyHold),
            ),
      );
      // Étape actuelle et étape plus facile le même jour : l'essentiel des
      // secondes va à l'étape actuelle (c'est elle qui charge le tendon à
      // 70 % et plus, R4-F6) ; l'étape plus facile garde deux à trois
      // tenues longues.
      if (s.method == Method.skillEasyHold && paired) {
        sets = ws.light ? 2 : (hold >= 10 ? 2 : 3);
      } else {
        final part = paired ? 0.6 : 1.0;
        final wanted = cumulative[_level] * part * ws.volume * volumeScale;
        // (Tenues courtes, 5 s au plus, sur un levier dur : jusqu'à dix
        // tenues pour atteindre les secondes cumulées — relecture
        // documentée CX : 30 à 60 s de tenue totale par séance.)
        sets = _clampInt(
          _round(wanted / hold),
          paired ? 3 : 2,
          hold <= 5 && _level >= 2 ? 10 : 6,
        );
      }
      if (ws.eventWeek && sets > 3) {
        sets = 3;
      }
      // Séance légère de la figure (pratique distribuée, R4-F1) : trois
      // tenues au plus.
      if (s.stress == DayStress.light && sets > 3) {
        sets = 3;
      }
    }
    // Progression des tenues vers le critère de passage (CP2, partie 0 ;
    // panel CX correction 1, `street_05` et `street_10` : le critère n'était
    // jamais travaillé, les tenues restaient à 60-70 % du maximum) : en
    // réalisation, la séance lourde qui porte l'essai maximal fait trois
    // tenues longues, à la durée du critère, sans dépasser 85 % du dernier
    // maintien mesuré (R4-F6 ; Oranchuk et al. 2019 : 70 % et plus de
    // l'effort maximal pour le tendon ; R4-F2 : jamais jusqu'à l'échec).
    // Repère de la figure manqué au dernier test (maintien qui ne dépasse
    // pas le précédent) : la dose change, comme la note du repère
    // l'annonce — des tenues plus courtes (60 %) et plus nombreuses, au
    // même temps total, repos complets (CP2, partie 0, boucle 2 ; panel
    // p1, `street_10` : « grappes plus courtes, volume cumulé gardé » ;
    // R1-P16 : 2 à 5 min sur les isométries dures).
    var regroup = false;
    if (known > 0 &&
        a.stalled.contains(e.id) &&
        role == _DayRole.normal &&
        !ws.light &&
        s.method == Method.skillHold &&
        hold >= 5) {
      // (75 % de la tenue, 3 s au moins, jusqu'à quinze tenues : le temps
      // total reste — panel p2, `street_10` : 10 × 2 s ne gardaient que
      // 20 s, et `street_05` : tenues à 44 % du maintien.)
      final shorter = _clampInt((hold * 0.75).round(), 3, hold - 1);
      final total = hold * sets;
      sets = _clampInt((total / shorter).ceil(), sets, 15);
      hold = shorter;
      regroup = true;
    }
    var criterion = false;
    if (!regroup &&
        intense &&
        known > 0 &&
        ws.kind == WeekKind.build &&
        ws.intent == WeekIntent.realization &&
        role == _DayRole.normal &&
        _maxAttemptDay(s) == _dayNow &&
        _isLadderStep(s.skillTargetId, e.id)) {
      final goal = coachStepHold(_level);
      final most = (known * 0.85 + 1e-9).floor();
      final rehearsal = goal < most ? goal : most;
      if (rehearsal > hold) {
        hold = rehearsal;
        sets = 3;
        criterion = true;
      }
    }
    x
      ..sets = sets < 2 ? 2 : sets
      ..minSets = 2
      ..secondsLow = hold
      ..secondsHigh = hold
      ..isometric = true
      // R4-F2 : maintiens sous-maximaux (50 à 70 % du maintien maximal),
      // jamais jusqu'à l'échec — ce ne sont pas des séries dures ; leur
      // dose se compte en secondes cumulées (budget bras tendus).
      ..rir = 5
      // R1-P16 : 2 à 5 min de repos complet sur les isométries dures ;
      // tenues courtes (5 s au plus) en séries nombreuses : 90 s.
      // (Tenues courtes en séries nombreuses : 2 min — panel p1,
      // `street_10` : à 90 s, les dernières tenues tombaient à 1-3 s.)
      ..rest = regroup
          ? 150
          : (hold <= 5 && sets > 6 ? 120 : (_level >= 2 ? 180 : 150))
      ..calibrate = known <= 0 && blockIndex == 0 && week == 0
      ..reasons.add(_note(CoachNotes.submaximalHold, 0.7))
      ..reasons.add(_rule(CoachRules.holdStep, 1, 's'));
    if (criterion) {
      x
        ..rest = 180
        ..reasons.add(_note(CoachNotes.stepCriterion, hold));
    }
    if (known > 0) {
      x.intensity = IntensityTarget(
        basis: IntensityBasis.percentBenchmark,
        value: _round3(hold / known > 1 ? 1 : hold / known),
        referenceExerciseId: e.id,
        referenceKind: BenchmarkKind.maxHold,
      );
      // R4-F2 : essai maximal toutes les une à deux semaines en élite (le
      // repère se mesure, il ne se suppose pas) ; aux autres niveaux, le
      // test de fin de bloc suffit.
      if (intense &&
          _level >= 3 &&
          ws.kind == WeekKind.build &&
          ws.stage.isOdd &&
          role == _DayRole.normal &&
          _maxAttemptDay(s) == _dayNow) {
        x.reasons.add(_note(CoachNotes.maxAttempt, 2));
      }
    } else if (blockIndex == 0 && week == 0) {
      // Maintien sans repère : il se mesure à la première séance.
      x.reasons.add(_note(CoachNotes.holdCalibrate, share));
    }
    return x;
  }

  /// Vrai si [id] est l'étape actuelle (premier rang) de l'échelle écrite
  /// de la figure [targetId].
  bool _isLadderStep(String? targetId, String id) {
    if (targetId == null) {
      return false;
    }
    for (final l in skeleton.ladders) {
      if (l.targetExerciseId == targetId &&
          l.steps.isNotEmpty &&
          l.steps.first.exerciseId == id) {
        return true;
      }
    }
    return false;
  }

  /// Première séance lourde de la semaine pour la figure de [s] (celle qui
  /// porte l'essai maximal périodique).
  int _maxAttemptDay(SlotSpec s) {
    for (final d in skeleton.days) {
      for (final o in d.slots) {
        if (o.method == Method.skillHold &&
            o.stress == DayStress.heavy &&
            o.skillTargetId == s.skillTargetId) {
          return d.dayIndex;
        }
      }
    }
    return -1;
  }

  /// Étape suivante d'une figure, sous condition : entrées de 2 à 3 s,
  /// très loin de la limite, seulement si le critère de passage est validé
  /// au dernier test (R4-F7, R4-F9 : un seul changement à la fois).
  _Draft? _skillAttempt(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role != _DayRole.normal || ws.light) {
      return null;
    }
    final x = _new(s);
    if (x.e.unit != MeasureUnit.seconds) {
      return _skillDynamic(s, ws, week, role);
    }
    x
      ..sets = _loadedBefore >= 2 && s.sets < 3 ? s.sets + 1 : s.sets
      ..minSets = 2
      ..secondsLow = 2
      ..secondsHigh = 3
      ..isometric = true
      ..rir = 5
      ..rest = _level >= 2 ? 180 : 150
      ..reasons.add(_note(CoachNotes.stepGate, coachStepHold(_level)));
    return x;
  }

  _Draft? _skillBalance(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.after) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final known = a.holds[e.id] ?? 0;
    // R4-F2 : équilibre — pratique fréquente et courte, moitié du maintien
    // maximal, arrêt avant la perte de forme.
    final stage = ws.kind == WeekKind.build ? _stage(ws) : 0;
    final part = 0.5 + 0.03 * (stage > 3 ? 3 : stage);
    final hold = _clampInt(
      known > 0 ? _round(known * part) : 15 + 2 * (stage > 3 ? 3 : stage),
      8,
      45,
    );
    x
      ..sets = _scaled(s.sets, ws, min: 2)
      ..minSets = 2
      ..secondsLow = hold
      ..secondsHigh = hold
      ..practice = true
      ..rir = 5
      ..rest = 90
      ..reasons.add(_note(CoachNotes.qualityFirst, 4));
    return x;
  }

  _Draft? _skillDynamic(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role != _DayRole.normal || ws.intent == WeekIntent.taper) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final weak = s.weak;
    final referenceId = s.referenceId;
    if (weak != null && referenceId != null) {
      x.reasons.add(
        reason(ReasonCodes.planWeakPoint, <String, Object?>{
          'exerciseId': referenceId,
          'kind': weak.code,
        }),
      );
    }
    final sets = _scaled(s.sets, ws, min: 2);
    x
      ..sets = sets
      ..minSets = 1
      ..rest = 120;
    if (e.unit == MeasureUnit.seconds) {
      x
        ..secondsLow = 5
        ..secondsHigh = 8
        ..isometric = true
        ..rir = _rirOf(e, 3, ws, week);
      return x;
    }
    final max = a.reps[e.id] ?? 0;
    if (max >= 3) {
      final reps = _clampInt(_round(max * 0.6), 1, max);
      x
        ..repsLow = reps
        ..repsHigh = reps
        ..rir = _rirOf(e, (max - reps).toDouble(), ws, week);
      return x;
    }
    // R4-F5 : dynamique dans le schéma de la figure, 3 à 5 répétitions
    // propres. Les descentes freinées se comptent à l'unité.
    final negative = e.id.contains('negati');
    x
      ..repsLow = (negative ? 2 : 3) + (_shift(ws) > 0 ? 1 : 0)
      ..repsHigh = (negative ? 3 : 5) + (_shift(ws) > 0 ? 1 : 0)
      ..rir = _rirOf(e, 3, ws, week);
    if (negative) {
      x
        ..tempo = const Tempo(
          eccentricSeconds: 4,
          bottomPauseSeconds: 0,
          concentricSeconds: 0,
          topPauseSeconds: 0,
        )
        ..reasons.add(_note(CoachNotes.slowNegative, 4));
    }
    return x;
  }

  // ------------------------------------------------------------- assistance

  _Draft? _accessory(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final method = s.method;
    final prehab = method == Method.accessoryPrehab;
    if (role == _DayRole.event ||
        (role != _DayRole.normal &&
            !prehab &&
            method != Method.accessoryCore)) {
      return null;
    }
    final sharpening =
        ws.intent == WeekIntent.taper || ws.intent == WeekIntent.competition;
    if (sharpening &&
        (method == Method.accessoryIsolation ||
            s.support ||
            (_shape.model == SeasonModel.strengthPeak &&
                !prehab &&
                method != Method.accessoryCore &&
                !s.keep))) {
      // R3-P13 : à l'affûtage, on coupe d'abord les accessoires (tous,
      // hors prévention et tronc, avant une épreuve de force).
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final easy = ws.light && ws.intent != WeekIntent.intro;
    var sets = _scaled(s.sets, ws);
    if (easy && (method == Method.accessoryIsolation || s.support)) {
      // Semaine allégée : la séance raccourcit, les compléments sautent.
      return null;
    }
    if (ws.intent == WeekIntent.taper || ws.intent == WeekIntent.competition) {
      sets = sets > 2 ? 2 : sets;
    }
    final legs =
        e.family == MovementFamily.jambesGenou ||
        e.family == MovementFamily.jambesHanche;
    final factor = legs ? a.legsFactor : 1.0;
    if (factor < 1 && sets > 2) {
      sets = _round(sets * factor);
    }
    // Jamais une série isolée d'assistance : deux, ou rien. En reprise,
    // tant que le volume est sous les trois quarts, l'assistance attend
    // (l'essentiel d'abord, R5-P7).
    if (sets < 2 &&
        ws.phase == SeasonPhaseKind.reintroduction &&
        ws.volume < 0.75 &&
        !s.keep &&
        !prehab &&
        // (le tronc aussi : il tient la position à la barre.)
        method != Method.accessoryCore &&
        // (les jambes gardent deux séries dès la première semaine : tous
        // les grands groupes reprennent ensemble.)
        e.family != MovementFamily.jambesGenou) {
      return null;
    }
    x
      ..sets = sets < 2 ? 2 : sets
      ..minSets = 2;
    final stage = _stage(ws);
    if (e.id == 'cf-pogo-jumps' || e.id.startsWith('ca-corde')) {
      // Rebonds courts : dose fixe et brève (la raideur élastique, pas
      // l'endurance du mollet), la même en semaine allégée.
      x
        ..sets = 2
        ..rir = 5
        ..rest = 60;
      if (e.unit == MeasureUnit.seconds) {
        x
          ..secondsLow = 20
          ..secondsHigh = 20;
      } else {
        x
          ..repsLow = 15
          ..repsHigh = 20;
      }
      _roleNote(x);
      return x;
    }
    if (e.unit == MeasureUnit.seconds) {
      final known = a.holds[e.id] ?? 0;
      final straight = straightArmFamilyOf(e) >= 0;
      var hold = known > 0
          ? _round(known * 0.6)
          : (straight ? 8 : 20 + 5 * (stage > 3 ? 3 : stage));
      hold = _clampInt(hold, straight ? 5 : 15, straight ? 20 : 45);
      x
        ..secondsLow = hold
        ..secondsHigh = hold
        ..isometric = true
        ..rir = _rirOf(e, 3, ws, week)
        ..rest = 60
        ..reasons.add(_rule(CoachRules.holdStep, straight ? 1 : 5, 's'));
      _roleNote(x);
      return x;
    }
    switch (method) {
      case Method.accessoryPrehab:
        // R5-P24 : prévention — séries faciles, loin de l'échec.
        x
          ..repsLow = 12
          ..repsHigh = 15
          ..rir = 5
          ..rest = 45;
      case Method.accessoryIsolation:
        x
          ..repsLow = 10
          ..repsHigh = 15
          // (3 en réserve sur les fléchisseurs du coude quand le coude a
          // un antécédent, R5-P24.)
          ..rir = _rirOf(
            e,
            e.pattern == MovementPattern.isolationBiceps &&
                    a.limitOn(Joint.elbow) != null
                ? 3
                : 2,
            ws,
            week,
          )
          ..rest = 75;
      case Method.accessoryCore:
        x
          ..repsLow = 8 + _shift(ws)
          ..repsHigh = 12 + _shift(ws)
          ..rir = _rirOf(e, 3, ws, week)
          ..rest = 60;
      case Method.accessoryLegs:
        final best = a.reps[e.id] ?? 0;
        if (best >= 3) {
          // Mouvement à record (pistol, shrimp) : 50 à 65 % du maximum.
          final high = _clampInt(_round(best * 0.65) + _shift(ws), 1, best - 2);
          x
            ..repsLow = high - 1 < 1 ? 1 : high - 1
            ..repsHigh = high
            ..rir = _rirOf(e, (best - high).toDouble(), ws, week)
            ..rest = 90;
        } else {
          x
            ..repsLow = 6 + _shift(ws)
            ..repsHigh = 8 + _shift(ws)
            ..rir = _rirOf(e, 3, ws, week)
            ..rest = 90;
        }
      default:
        x
          ..repsLow = 8 + _shift(ws)
          ..repsHigh = 10 + _shift(ws)
          ..rir = _rirOf(e, _level == 0 ? 3 : 2, ws, week)
          ..rest = 105;
    }
    if (e.id.contains('nordic')) {
      // Excentrique des ischio-jambiers : entrée très progressive, 2 × 5
      // la première semaine, une répétition de plus toutes les deux
      // semaines (protocole de prévention usuel ; R5-P22 : exercice
      // nouveau à 50 à 60 % de la dose cible).
      x
        ..sets = x.sets > 2 ? 2 : x.sets
        ..repsLow = 5 + _shift(ws)
        ..repsHigh = 5 + _shift(ws)
        ..rir = _rirOf(e, 3, ws, week);
    }
    final basis = _basisOf(e);
    if (basis == LoadBasis.external ||
        basis == LoadBasis.bodyweightPlusExternal) {
      final total = a.totalOneRm(e.id);
      if (total != null) {
        // 8 à 12 répétitions à 2 ou 3 de l'échec : environ 70 % du 1RM.
        _loadAt(x, 0.68, null);
      } else {
        x
          ..calibrate = true
          ..reasons.add(reason(ReasonCodes.planToCalibrate));
      }
    }
    x.reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
    if (s.note == 'tendon') {
      // R5-P24 : charge progressive du tendon — trois séries à partir de
      // la troisième semaine de charge, effort modéré, sous le seuil de
      // douleur ; à valider avec le professionnel qui suit la zone.
      x
        ..sets = stage >= 2 && !ws.light ? 3 : 2
        ..minSets = 2
        ..rir = 3
        ..reasons.add(_note(CoachNotes.tendonLoad, 3));
      return x;
    }
    _roleNote(x);
    return x;
  }

  /// Note de rôle d'un exercice d'assistance (pourquoi il est là).
  void _roleNote(_Draft x) {
    final e = x.e;
    String? note;
    if (e.id.contains('wrist-curl')) {
      note = CoachNotes.roleForearm;
    } else if (e.id.contains('mollets') ||
        e.id == 'cf-pogo-jumps' ||
        e.id.startsWith('ca-corde')) {
      note = CoachNotes.roleRunner;
    } else if (x.method == Method.accessoryPrehab) {
      note = CoachNotes.rolePrehab;
    } else if (e.pattern == MovementPattern.tirageHorizontal) {
      note = CoachNotes.roleRow;
    } else if (e.pattern == MovementPattern.charniereHanche ||
        e.pattern == MovementPattern.flexionGenou ||
        e.pattern == MovementPattern.extensionHanche) {
      note = CoachNotes.rolePosterior;
    } else if (e.pattern == MovementPattern.isolationBiceps) {
      note = CoachNotes.roleElbow;
    } else if (x.method == Method.accessoryCore) {
      note = CoachNotes.roleCore;
    } else if (x.method == Method.accessoryLegs) {
      note = CoachNotes.roleLegs;
    }
    if (note != null) {
      x.reasons.add(_note(note, 0));
    }
  }

  _Draft? _warmup(SlotSpec s, WeekSpec ws, _DayRole role) {
    if (role == _DayRole.after) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    x
      ..kind = SetKind.warmup
      ..sets = s.sets
      ..minSets = 1
      ..rest = 30
      ..fixed = true;
    if (e.unit == MeasureUnit.seconds) {
      x
        ..secondsLow = 15
        ..secondsHigh = 20;
    } else {
      x
        ..repsLow = 8
        ..repsHigh = 10;
    }
    return x;
  }

  _Draft? _mobility(SlotSpec s, WeekSpec ws, _DayRole role) {
    if (role == _DayRole.event) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    x
      ..sets = e.unit == MeasureUnit.seconds ? 2 : 1
      ..minSets = 1
      ..rest = 20;
    if (e.unit == MeasureUnit.seconds) {
      x
        ..secondsLow = 30
        ..secondsHigh = 45;
    } else {
      x
        ..repsLow = 8
        ..repsHigh = 10;
    }
    return x;
  }

  // ------------------------------------------------------------------ course

  _Draft? _run(SlotSpec s, int day, WeekSpec ws, _DayRole role) {
    if (role == _DayRole.event) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final budget = a.days[day].minutes;
    final stage = _stage(ws);
    final easy = ws.light && ws.intent != WeekIntent.intro;
    x
      ..minSets = 1
      ..fixed = true;
    // Objectif chronométré : une semaine de charge sur deux, la séance de
    // qualité se court à l'allure de l'objectif sur des fractions longues
    // (R6-P14 : spécificité de l'allure).
    final goal = a.runGoal;
    final paced = skeleton.days.any(
      (d) => d.slots.any((o) => o.note == 'goal_pace'),
    );
    final alternate =
        goal != null && paced && ws.kind == WeekKind.build && stage.isOdd;
    if (s.note == 'goal_pace') {
      if (goal == null || !alternate || role != _DayRole.normal) {
        return null;
      }
      final more = (stage ~/ 2 > 2 ? 2 : stage ~/ 2) + (blockIndex > 0 ? 1 : 0);
      final reps = 3 + (more > 3 ? 3 : more);
      x
        ..sets = reps
        ..rir = 3
        ..restMode = RestMode.jog
        ..distance = 1000
        ..rest = 90
        ..reasons.add(_note(CoachNotes.goalPace, goal.$2 / goal.$1 * 1000));
      return x;
    }
    if (s.method == Method.runQuality && alternate) {
      return null;
    }
    // Test chronométré : la sortie longue de la semaine de test devient le
    // test de l'objectif (la moitié de la distance à mi-parcours).
    if (goal != null &&
        s.method == Method.runLong &&
        ws.testWeek &&
        role != _DayRole.event) {
      final last = ws.eventWeek || ws.intent == WeekIntent.test;
      final meters = last ? goal.$1 : goal.$1 / 2;
      x
        ..kind = SetKind.test
        ..sets = 1
        ..rest = 0
        ..distance = (meters / 100).roundToDouble() * 100
        ..stress = DayStress.heavy
        ..reasons.add(
          reason(ReasonCodes.planTestScheduled, <String, Object?>{
            'testKind': TestKind.timeTrial.code,
          }),
        )
        ..reasons.add(_note(CoachNotes.timeTrial, meters));
      if (last) {
        x.reasons.add(_note(CoachNotes.goalPace, goal.$2 / goal.$1 * 1000));
      }
      x.test = const TestSpec(
        kind: TestKind.timeTrial,
        attempts: 1,
        benchmarkKind: BenchmarkKind.timeTrial,
      );
      return x;
    }
    if (s.method == Method.runQuality &&
        s.note != 'goal_pace' &&
        (role == _DayRole.normal || role == _DayRole.primerFar)) {
      // R6-P15 : une séance de qualité par semaine ; R6-P16 : fractions
      // courtes, récupération égale à l'effort. R6-P20 : +10 % par semaine
      // au plus — une fraction de plus toutes les deux semaines ; en
      // semaine allégée, la séance reste, plus courte.
      final meters = x.traits.intervalMeters;
      var reps = s.sets + (stage ~/ 2 > 3 ? 3 : stage ~/ 2);
      if (easy) {
        reps = 4;
      }
      if (reps < 4) {
        reps = 4;
      }
      if (role == _DayRole.primerFar) {
        // Semaine de l'épreuve : trois fractions, pour garder l'allure
        // sans fatigue (R6-P20, affûtage).
        reps = 3;
      }
      x
        ..sets = reps
        ..rir = 2
        ..restMode = RestMode.jog;
      // Fractions courtes à l'allure du 3 km (plus vite que les fractions
      // longues à l'allure de l'objectif) : stimulus de vitesse aérobie.
      final three = a.runTimeOn(3000);
      if (meters > 0 && three != null) {
        x.reasons.add(_note(CoachNotes.intervalPace, three / 3000 * meters));
      }
      if (meters > 0) {
        x
          ..distance = meters.toDouble()
          ..rest = 90;
      } else if (e.id.contains('30-30')) {
        x
          ..sets = reps * 2
          ..secondsLow = 30
          ..secondsHigh = 30
          ..rest = 30;
      } else {
        x
          ..sets = 1
          ..secondsLow = 20 * 60
          ..secondsHigh = 20 * 60
          ..rest = 0
          ..restMode = null;
      }
      return x;
    }
    // R6-P14 : endurance fondamentale, allure de conversation ; durée +10 %
    // par semaine au plus (R6-P20).
    final long = s.method == Method.runLong;
    final warm =
        s.note == 'run_warmup' || s.note == 'walk' || s.note == 'run_extra';
    var minutes = s.note == 'walk'
        ? 10.0
        : s.note == 'run_extra'
        ? 20.0
        : warm
        ? 12.0
        : (long ? 45.0 : 30.0) * (1 + 0.08 * (stage > 4 ? 4 : stage));
    if (!warm) {
      minutes *= easy ? 0.7 : 1;
      if (role != _DayRole.normal) {
        minutes = 20;
      }
      final cap = budget - 8.0;
      if (minutes > cap) {
        minutes = cap;
      }
      if (minutes < 10) {
        minutes = 10;
      }
    }
    final whole = minutes.floor();
    x
      ..sets = 1
      ..rir = 5
      ..rest = 0
      ..reasons.add(_note(CoachNotes.easyPace, whole));
    if (e.unit == MeasureUnit.distance) {
      x.distance =
          (whole * 60 * coachRunMetersPerSecond / 100).floorToDouble() * 100;
    } else {
      x
        ..secondsLow = whole * 60
        ..secondsHigh = whole * 60;
    }
    if (!warm && ws.kind == WeekKind.build) {
      x.reasons.add(_rule(CoachRules.durationStep, 10, 'pct'));
    }
    return x;
  }

  // ------------------------------------------------------------------ tests

  _Draft _testOf(
    String slotId,
    SlotSpec? slot,
    CatalogExercise e,
    WeekSpec ws, {
    required bool event,
  }) {
    final x = _Draft(slot, slotId, e, a.traits.of(e.id))
      ..method = slot?.method ?? Method.liftHeavy
      ..kind = SetKind.test
      ..fixed = true
      ..stress = DayStress.heavy;
    final target = _shape.target;
    final eventId = target?.eventId;
    final total = a.totalOneRm(e.id);
    TestKind kind;
    if (e.unit == MeasureUnit.seconds) {
      final known = _holdOf(e.id, expected: true);
      final goal = a.goalOn(e.id, GoalMetric.maxHoldSeconds)?.targetValue;
      final aim = goal != null && goal > known ? goal.round() : known + 5;
      final hang = straightArmFamilyOf(e) < 0;
      kind = TestKind.maxHold;
      x
        ..sets = 1
        // (Tenue bras tendus sans repère : un essai court, 3 à 5 s — pas
        // de saut de charge sur les tendons le jour du test.)
        ..secondsLow = known > 0 ? known : (hang ? 15 : 3)
        ..secondsHigh = known > 0 ? aim : (hang ? 45 : 5)
        ..rest = 180;
      x.test = const TestSpec(
        kind: TestKind.maxHold,
        targetRir: 1,
        attempts: 2,
        benchmarkKind: BenchmarkKind.maxHold,
      );
    } else if (total != null &&
        _basisOf(e) != LoadBasis.bodyweight &&
        _basisOf(e) != LoadBasis.unloaded) {
      if (event && _level >= 1 && !a.cautious) {
        // R3-P15 : trois tentatives — 91 %, 96 %, puis selon la deuxième.
        kind = TestKind.oneRm;
        x
          ..sets = 3
          ..repsLow = 1
          ..repsHigh = 1
          ..rest = 300
          ..ramped = true
          ..load = _external(e, total, 0.91)
          ..percent = 0.91
          ..intensity = const IntensityTarget(
            basis: IntensityBasis.percentOneRm,
            value: 0.91,
            valueHigh: 1,
          )
          ..rest = 360
          ..reasons.add(_note(CoachNotes.attemptsPlan, 0.91));
        // Le dernier lourd fixe la première barre (R3-P14) : jamais sous
        // 98 % du plus lourd simple ou double écrit dans les trois semaines
        // d'avant (CX, correction 1, panel : ouverture à 15 kg sous les
        // simples d'entraînement après un 1RM recalé à la baisse).
        final last = _recentHeavyTotal(e.id);
        final opener = x.load;
        if (last != null && opener != null) {
          final fraction = e.bodyweightFraction?.value ?? 0;
          final floor = _external(e, last * 0.98, 1);
          if (floor != null && floor > opener) {
            final share = (floor + fraction * a.bodyWeight) / total;
            final shown = _round3(share > 1 ? 1 : share);
            x
              ..load = floor
              ..percent = shown
              ..intensity = IntensityTarget(
                basis: IntensityBasis.percentOneRm,
                value: shown,
                valueHigh: 1,
              );
            x.reasons.removeWhere(
              (r) =>
                  r.code == ReasonCodes.planCoachNote &&
                  r.params['note'] == CoachNotes.attemptsPlan,
            );
            x.reasons.add(_note(CoachNotes.attemptsPlan, shown));
          }
        }
        // Troisième barre : l'objectif déclaré, s'il est à portée (au plus
        // 106 % du 1RM de départ), quand la deuxième est rapide.
        final wanted = _targetKg(e.id);
        if (wanted != null) {
          final fraction = e.bodyweightFraction?.value ?? 0;
          final ratio = (wanted + fraction * a.bodyWeight) / total;
          if (ratio > 1.0 && ratio <= 1.07) {
            x.reasons.add(_note(CoachNotes.attemptsGoal, wanted));
          }
        }
        x.test = const TestSpec(
          kind: TestKind.oneRm,
          attempts: 3,
          benchmarkKind: BenchmarkKind.loadReps,
        );
      } else {
        // R3-P16 : hors compétition, un 3RM avec une répétition en réserve
        // estime le 1RM sans le risque d'un maximum.
        kind = TestKind.repMax;
        x
          ..sets = 1
          ..repsLow = 3
          ..repsHigh = 3
          ..rest = 240
          ..ramped = true
          // (Mode prudent : 85 % au plus, comme les charges de travail.)
          ..load = _external(e, total, a.cautious ? 0.85 : 0.88)
          ..percent = a.cautious ? 0.85 : 0.88
          ..intensity = IntensityTarget(
            basis: IntensityBasis.percentOneRm,
            value: a.cautious ? 0.85 : 0.88,
          );
        x.test = const TestSpec(
          kind: TestKind.repMax,
          targetRir: 1,
          attempts: 2,
          benchmarkKind: BenchmarkKind.loadReps,
        );
      }
    } else if (_basisOf(e) == LoadBasis.bodyweightPlusExternal ||
        _basisOf(e) == LoadBasis.external) {
      kind = TestKind.repMax;
      x
        ..sets = 1
        ..repsLow = 5
        ..repsHigh = 5
        ..rest = 240
        ..calibrate = true
        ..ramped = true;
      x.test = const TestSpec(
        kind: TestKind.repMax,
        targetRir: 1,
        attempts: 2,
        benchmarkKind: BenchmarkKind.loadReps,
      );
    } else {
      // Repère : le maximum prévu par la trajectoire ce jour-là (le record
      // de départ, puis la part du chemin vers l'objectif).
      final own = a.reps[e.id] ?? 0;
      final max = own <= 0
          ? 0
          : _maxOf(
              SlotSpec(exerciseId: e.id, role: SlotRole.main, method: ''),
              expected: true,
            );
      final goal = a.goalOn(e.id, GoalMetric.maxReps)?.targetValue;
      // Variante sans record (pompe adaptée, tirage assisté) : une série
      // maximale propre, elle devient le repère du bloc suivant.
      final variant = own <= 0 && (goal == null || goal < 1);
      kind = TestKind.maxReps;
      x
        ..sets = 1
        ..repsLow = max > 0 ? max : (variant ? 8 : 1)
        ..repsHigh = max > 0
            ? (goal != null && goal > max + 2 ? goal.round() : max + 2)
            : (variant || goal == null ? 15 : goal.round())
        ..rest = 240;
      x.test = TestSpec(
        kind: TestKind.maxReps,
        targetRir: coachHighRisk(e) || _level == 0 ? 1 : 0,
        attempts: 1,
        benchmarkKind: BenchmarkKind.maxReps,
      );
    }
    x.reasons.add(
      reason(ReasonCodes.planTestScheduled, <String, Object?>{
        'testKind': kind.code,
      }),
    );
    if (kind == TestKind.maxHold && straightArmFamilyOf(e) >= 0) {
      // Maintien maximal d'une figure : jamais à froid.
      x.reasons.add(_note(CoachNotes.holdRamp, 3));
    }
    if (kind == TestKind.maxReps && (a.reps[e.id] ?? 0) >= 4) {
      // Série maximale : approche courte et stratégie de série (R4-G7).
      final best = _maxOf(
        SlotSpec(exerciseId: e.id, role: SlotRole.main, method: ''),
        expected: true,
      );
      x.reasons.add(_note(CoachNotes.maxSetPlan, best >= 12 ? best ~/ 2 : 0));
    }
    final marker = _checkpoint(e, ws);
    // (Le jour de l'échéance, plus de repère de parcours : c'est le test
    // de l'objectif lui-même.)
    if (marker != null && !event) {
      x.reasons.add(_note(_checkpointCode(e), marker));
    }
    if (event && eventId != null) {
      x.reasons.add(
        reason(ReasonCodes.planEventSpecific, <String, Object?>{
          'eventId': eventId,
        }),
      );
    }
    return x;
  }

  /// Note du repère de mi-parcours de [e], selon ce que le programme peut
  /// réellement changer au bloc suivant (CP2, partie 0, boucle 2 ; panel
  /// p1 : la règle « départs au chrono → surcharge, lest » était
  /// inapplicable sans séance au chrono, sans lest, sur une figure ou chez
  /// le débutant — `street_03`, 10, 13, 14, 15, 16, 17).
  String _checkpointCode(CatalogExercise e) {
    for (final g in a.profile.goals) {
      if (g.kind != GoalKind.performance || g.exerciseId != e.id) {
        continue;
      }
      switch (g.metric) {
        case GoalMetric.oneRmKg:
          return CoachNotes.checkpointLoad;
        case GoalMetric.maxHoldSeconds:
          return CoachNotes.checkpointHold;
        default:
          break;
      }
    }
    if (a.level == 0 && e.id == Ids.pushUp) {
      return CoachNotes.checkpointLadder;
    }
    final weighted = e.id == Ids.pull
        ? Ids.weightedPull
        : (e.id == Ids.dip ? Ids.weightedDip : null);
    var loadable = false;
    if (weighted != null) {
      for (var d = 0; d < a.days.length; d++) {
        if (a.can(weighted, d)) {
          loadable = true;
        }
      }
    }
    return loadable ? CoachNotes.checkpoint : CoachNotes.checkpointBody;
  }

  /// Charge externe visée sur l'exercice [id] (barre annoncée pour
  /// l'échéance, ou objectif de 1RM), en kg, ou `null`.
  double? _targetKg(String id) {
    final event = _shape.target?.event;
    for (final l in event?.lifts ?? const <CompetitionLift>[]) {
      final kg = l.targetKg;
      if (l.exerciseId == id && kg != null) {
        return kg;
      }
    }
    return a.goalOn(id, GoalMetric.oneRmKg)?.targetValue;
  }

  /// Repère attendu au test de la semaine [ws] pour l'exercice [e] : la
  /// part du chemin vers l'objectif daté du profil qui correspond au temps
  /// écoulé (progression supposée régulière), ou `null` sans objectif
  /// chiffré.
  double? _checkpoint(CatalogExercise e, WeekSpec ws) {
    for (final g in a.profile.goals) {
      final target = g.targetValue;
      final date = g.targetDate;
      if (g.kind != GoalKind.performance ||
          g.exerciseId != e.id ||
          target == null ||
          date == null) {
        continue;
      }
      double? current;
      switch (g.metric) {
        case GoalMetric.maxReps:
          current = a.reps[e.id]?.toDouble();
        case GoalMetric.maxHoldSeconds:
          current = a.holds[e.id]?.toDouble();
        case GoalMetric.oneRmKg:
          current = a.oneRm[e.id];
        default:
          current = null;
      }
      final total = a.profile.createdOn.daysUntil(date);
      final index = _shape.weeks.indexOf(ws);
      final elapsed = a.profile.createdOn.daysUntil(a.start) + 7 * (index + 1);
      if (current == null || total <= 0 || target <= current) {
        continue;
      }
      final share = elapsed >= total ? 1.0 : elapsed / total;
      final value = current + (target - current) * share;
      return g.metric == GoalMetric.oneRmKg
          ? (value / 2.5).floorToDouble() * 2.5
          : value.floorToDouble();
    }
    return null;
  }

  /// Exercices de l'échéance, dans l'ordre de l'épreuve.
  List<String> _eventExercises() {
    final target = _shape.target;
    final out = <String>[];
    void add(String? given) {
      if (given == null) {
        return;
      }
      var id = given;
      // Figure : le test porte sur l'étape réellement travaillée, pas sur
      // une figure jamais entraînée — jamais sur un remplaçant d'une autre
      // famille (douleur : un support aux anneaux n'est pas la planche ; CX,
      // correction 1, panel : le test de l'objectif doit mesurer la figure).
      final root = a.catalog.find(given)?.rootId;
      for (final d in skeleton.days) {
        for (final s in d.slots) {
          if (s.skillTargetId == given &&
              s.method == Method.skillHold &&
              (root == null || a.catalog.find(s.exerciseId)?.rootId == root)) {
            id = s.exerciseId;
          }
        }
      }
      if (a.catalog.contains(id) && !out.contains(id)) {
        out.add(id);
      }
    }

    final event = target?.event;
    if (event != null) {
      for (final l in event.lifts ?? const <CompetitionLift>[]) {
        add(l.exerciseId);
      }
      for (final s in event.stations ?? const <EventStation>[]) {
        add(s.exerciseId);
      }
      final ids = <String>{...?event.goalIds};
      for (final g in a.profile.goals) {
        if (ids.contains(g.id)) {
          add(g.exerciseId);
        }
      }
    }
    for (final g in target?.goals ?? const <Goal>[]) {
      add(g.exerciseId);
    }
    // Objectif daté sans épreuve inscrite : chaque figure visée se teste le
    // jour du test de l'objectif (CX, correction 1, panel : `street_10`
    // finissait sans mesure du front lever).
    if (event == null && out.isNotEmpty) {
      for (final d in skeleton.days) {
        for (final s in d.slots) {
          final aim = s.skillTargetId;
          if (s.method == Method.skillHold && aim != null && a.aimsAt(aim)) {
            add(aim);
          }
        }
      }
    }
    if (out.isEmpty) {
      for (final method in const <String>[
        Method.liftHeavy,
        Method.repsTop,
        Method.skillHold,
        Method.beginnerMain,
      ]) {
        for (final d in skeleton.days) {
          for (final s in d.slots) {
            if (s.method == method) {
              add(s.exerciseId);
            }
          }
        }
        if (out.isNotEmpty) {
          break;
        }
      }
    }
    // Les épreuves de course se courent sur la séance de course, pas ici.
    out.removeWhere((id) {
      final unit = a.catalog.find(id)?.unit;
      final resistance = a.traits.find(id)?.kind.isResistance ?? false;
      return !resistance ||
          unit == MeasureUnit.distance ||
          unit == MeasureUnit.calories;
    });
    // Streetlifting : ordre usuel des fédérations (muscle-up, traction,
    // dips, squat) quand le règlement n'en donne pas d'autre.
    if (event?.kind == EventKind.strengthCompetition ||
        (event?.lifts ?? const <CompetitionLift>[]).isNotEmpty) {
      int rank(String id) {
        final root = a.catalog.find(id)?.rootId ?? id;
        if (id == Ids.weightedMuscleUp || root == Ids.weightedMuscleUp) {
          return 0;
        }
        if (id == Ids.weightedPull || root == Ids.weightedPull) {
          return 1;
        }
        if (id == Ids.weightedDip || root == Ids.weightedDip) {
          return 2;
        }
        if (id == Ids.squat || root == Ids.squat) {
          return 3;
        }
        return 4;
      }

      final ordered = <String>[...out];
      for (var i = 1; i < ordered.length; i++) {
        final id = ordered[i];
        var j = i - 1;
        while (j >= 0 && rank(ordered[j]) > rank(id)) {
          ordered[j + 1] = ordered[j];
          j--;
        }
        ordered[j + 1] = id;
      }
      out
        ..clear()
        ..addAll(ordered);
    }
    return out.length > 5 ? out.sublist(0, 5) : out;
  }

  // -------------------------------------------------------------- une séance

  _Draft? _draft(SlotSpec s, int day, int week, WeekSpec ws, _DayRole role) {
    if (week < s.fromWeek || week > s.untilWeek) {
      return null;
    }
    if (role == _DayRole.after) {
      // Après l'échéance : récupération — préparation, tirage facile,
      // mobilité (R3-P19).
      if (s.method == Method.warmupPrep) {
        return _warmup(s, ws, _DayRole.normal);
      }
      if (s.method == Method.mobility) {
        return _mobility(s, ws, role);
      }
      if (s.method == Method.accessoryPrehab ||
          s.method == Method.accessoryCompound ||
          s.method == Method.accessoryCore) {
        final x = _accessory(s, ws, week, _DayRole.normal);
        if (x != null) {
          x
            ..sets = x.sets > 2 ? 2 : x.sets
            ..rir = 5;
        }
        return x;
      }
      if (s.method == Method.runEasy || s.method == Method.runLong) {
        return _run(s, day, ws, role);
      }
      return null;
    }
    if (role == _DayRole.event) {
      return s.method == Method.warmupPrep ? _warmup(s, ws, role) : null;
    }
    if (role == _DayRole.primerNear) {
      // R3-P14, R2-P10 : arrêt de 2 à 4 jours avant l'échéance — la
      // séance se réduit à la préparation articulaire et à la mobilité.
      if (s.method == Method.warmupPrep) {
        final x = _warmup(s, ws, _DayRole.normal);
        x
          ?..kind = SetKind.work
          ..rir = 5
          ..reasons.add(_note(CoachNotes.restBeforeEvent, 2));
        return x;
      }
      if (_activation.contains(day) &&
          (s.method == Method.repsTop ||
              s.method == Method.repsVolume ||
              s.method == Method.repsDensity) &&
          _eventExercises().contains(s.exerciseId)) {
        // R3-P21 : deux séries faciles par atelier, pour garder le geste.
        final max = _maxOf(s);
        if (max >= 5) {
          final reps = _clampInt(_round(max * 0.4), 1, max);
          return _new(s)
            ..sets = 2
            ..minSets = 1
            ..repsLow = reps
            ..repsHigh = reps
            ..rir = 5
            ..rest = 120
            ..fixed = true
            ..intensity = _shareOf(s.exerciseId, reps, max)
            ..reasons.add(_note(CoachNotes.activation, 0.4));
        }
      }
      return s.method == Method.mobility ? _mobility(s, ws, role) : null;
    }
    final unit = a.catalog.find(s.exerciseId)?.unit;
    if (unit == MeasureUnit.distance || unit == MeasureUnit.calories) {
      return _run(s, day, ws, role);
    }
    // Épreuve de répétitions, phase de réalisation : la première séance de
    // la semaine répète l'épreuve — une série longue par atelier, dans
    // l'ordre, repos complets (R4-G1, R3-P20).
    final ahead = _toEventDays;
    if (_shape.model == SeasonModel.repsPeak &&
        role == _DayRole.normal &&
        (s.method == Method.repsDensity ||
            s.method == Method.repsVolume ||
            s.method == Method.repsTop) &&
        // R4-G7 : une simulation toutes les deux semaines chez l'avancé,
        // chaque semaine en élite ; la dernière à J−9 ou J−10, aucune
        // ensuite.
        ((ws.intent == WeekIntent.realization &&
                (_level >= 3 || ws.stage.isEven)) ||
            (ws.intent == WeekIntent.taper && ahead != null && ahead >= 9)) &&
        day == _rehearsalDay &&
        _eventExercises().contains(s.exerciseId)) {
      final top = SlotSpec(
        exerciseId: s.exerciseId,
        role: s.role,
        method: Method.repsTop,
        sets: 3,
        stress: DayStress.heavy,
      )..slotId = s.slotId;
      final x = _repsTop(top, ws, week, role);
      // Au format du jour J : une seule série longue par atelier, sans
      // séries de recul.
      x
        ?..sets = 1
        ..minSets = 1
        ..backoff = false
        ..fixed = true
        ..rest = 300
        ..reasons.add(_note(CoachNotes.eventRehearsal, 300));
      return x;
    }
    final x = _dosed(s, day, week, ws, role);
    if (x != null && s.note == 'pain_step' && x.e.id == s.exerciseId) {
      // (Recul d'étape pour douleur : la raison et le retour sont écrits —
      // panel CX, correction 1, passe 5, `street_10`.)
      x.reasons.add(_note(CoachNotes.painStep, 0));
    }
    if (x != null &&
        x.kind == SetKind.work &&
        _eveOfTest(day, week) &&
        (x.e.pattern == MovementPattern.tirageVertical ||
            x.e.rootId == Ids.muscleUp)) {
      // Veille d'un test de tirage (premier jour de la semaine de test) :
      // 48 h sans travail dur du mouvement — le tirage de ce jour saute.
      return null;
    }
    if (x != null &&
        _easyDay(role) &&
        x.kind == SetKind.work &&
        x.isResistance &&
        s.method != Method.liftHeavy &&
        s.method != Method.liftMaintain) {
      // À deux jours d'un test : deux séries au plus, à 60 % des
      // répétitions prévues, très loin de l'échec.
      final reps = x.repsHigh;
      if (reps != null && !x.practice) {
        final easy = _clampInt(_round(reps * 0.6), 1, reps);
        final target = x.intensity;
        if (target != null && target.basis == IntensityBasis.percentBenchmark) {
          x.intensity = target.copyWith(
            value: _round3(target.value * easy / reps),
          );
        }
        x
          ..repsLow = easy
          ..repsHigh = easy;
      }
      x
        ..sets = x.sets > 2 ? 2 : x.sets
        ..backoff = false
        ..everyMinute = false
        ..rir = 5
        ..reasons.add(_note(CoachNotes.easyBeforeTest, 0.6));
    }
    return x;
  }

  /// Vrai si la séance [day] peut porter un test de fin de bloc : trois
  /// jours au moins après le début de la semaine allégée, soit quatre à
  /// sept jours sans travail dur depuis la dernière séance chargée (CX,
  /// correction 1 : jamais au début de l'allègement ni juste après le pic ;
  /// Bosquet et al. 2007, la forme revient après quelques jours légers) —
  /// à partir du troisième jour quand la semaine n'a pas deux séances
  /// assez tardives.
  bool _testDayOk(int day) {
    var late = 0;
    var mid = 0;
    var after = 0;
    for (var d = 0; d < a.dayCount; d++) {
      if (_dayOffset(d) >= 3) {
        late++;
      }
      if (_dayOffset(d) >= 2) {
        mid++;
      }
      if (_dayOffset(d) >= 1) {
        after++;
      }
    }
    // (Jamais le premier jour de la semaine quand un jour plus tardif
    // existe — relecture indépendante du code.)
    final from = late >= 2 ? 3 : (mid >= 1 ? 2 : (after >= 1 ? 1 : 0));
    return _dayOffset(day) >= from;
  }

  /// Vrai si l'exercice [id] a une séance plus tard dans la semaine que
  /// [day] (son test s'y fera).
  bool _laterSlot(String id, int day) {
    for (final d in skeleton.days) {
      if (_dayOffset(d.dayIndex) > _dayOffset(day) &&
          d.slots.any((s) => s.exerciseId == id) &&
          _testDayOk(d.dayIndex)) {
        return true;
      }
    }
    return false;
  }

  /// Séance légère avant les tests de fin de bloc : à un ou deux jours du
  /// premier jour de test, sans en être un (48 h sans travail dur).
  bool _softBeforeTests(int day, WeekSpec ws) {
    if (!_blockTests(ws) || _testDayOk(day)) {
      return false;
    }
    // (Premier jour qui porte vraiment un test : jour admis qui a un
    // mouvement principal — panel CX correction 1 : la note « à deux jours
    // du test » tombait le mardi pour un test le samedi.)
    var first = 99;
    for (final d in skeleton.days) {
      final main = d.slots.any(
        (s) =>
            s.method == Method.liftHeavy ||
            s.method == Method.repsTop ||
            s.method == Method.skillHold ||
            (s.method == Method.beginnerMain && s.role == SlotRole.main) ||
            (s.method == Method.repsStrength && s.role == SlotRole.main),
      );
      if (main && _testDayOk(d.dayIndex) && _dayOffset(d.dayIndex) < first) {
        first = _dayOffset(d.dayIndex);
      }
    }
    final gap = first - _dayOffset(day);
    return gap >= 1 && gap <= 2;
  }

  /// Vrai pour la séance en cours quand elle précède de 48 h au plus les
  /// tests de fin de bloc.
  bool _soft = false;

  /// Première séance de la semaine qui porte des descentes freinées.
  int get _firstNegativeDay {
    for (final d in skeleton.days) {
      if (d.slots.any((o) => o.exerciseId == 'sw-traction-negative')) {
        return d.dayIndex;
      }
    }
    return -1;
  }

  /// Vrai si deux objectifs de série longue (15 répétitions et plus)
  /// coexistent.
  bool get _twoLongGoals {
    var n = 0;
    for (final g in a.profile.goals) {
      final v = g.targetValue;
      if (g.metric == GoalMetric.maxReps && v != null && v >= 15) {
        n++;
      }
    }
    return n >= 2;
  }

  /// Vrai si la séance [day] de la semaine [week] précède de moins de 48 h
  /// un test de tirage placé à la première séance de la semaine suivante.
  bool _eveOfTest(int day, int week) {
    if (week + 1 >= _shape.weeks.length) {
      return false;
    }
    final next = _shape.weeks[week + 1];
    if (!_blockTests(next)) {
      return false;
    }
    var first = 0;
    for (var d = 1; d < a.dayCount; d++) {
      if (_dayOffset(d) < _dayOffset(first)) {
        first = d;
      }
    }
    if (_dayOffset(first) + 7 - _dayOffset(day) > 1) {
      return false;
    }
    return skeleton.days[first].slots.any(
      (o) =>
          (o.method == Method.repsTop ||
              o.method == Method.liftHeavy ||
              o.method == Method.repsStrength ||
              o.method == Method.beginnerMain) &&
          a.catalog.find(o.exerciseId)?.pattern ==
              MovementPattern.tirageVertical,
    );
  }

  /// Haut de la plage du test de la tenue menton au-dessus de la barre.
  int _gateHigh() {
    final known = a.holds[coachGateExercise] ?? 0;
    final wide = _round(known * 1.5);
    return wide > 30 ? wide : 30;
  }

  /// Dosage ordinaire de l'emplacement [s] selon sa méthode.
  _Draft? _dosed(SlotSpec s, int day, int week, WeekSpec ws, _DayRole role) {
    switch (s.method) {
      case Method.liftHeavy || Method.liftMaintain:
        return _liftHeavy(s, ws, week, role);
      case Method.liftVolume:
        return _liftVolume(s, ws, week, role);
      case Method.liftLight:
        return _liftLight(s, ws, week, role);
      case Method.liftVariant:
        return _liftVariant(s, ws, week, role);
      case Method.repsTop || Method.repsEvent:
        return _repsTop(s, ws, week, role);
      case Method.repsVolume:
        return _repsVolume(s, ws, week, role);
      case Method.repsDensity:
        return _repsDensity(s, ws, week, role);
      case Method.repsStrength:
        return _repsStrength(s, ws, week, role);
      case Method.repsTechnique:
        return _repsTechnique(s, ws, week, role);
      case Method.beginnerMain:
        if (s.exerciseId == 'sw-traction-negative' ||
            s.exerciseId == 'sw-dips-negatifs') {
          // Repli sur un excentrique (ni élastique ni barre basse) : il
          // se dose comme une descente freinée (plafond R5-P8), jamais
          // en séries de 6 à 8 ; pas d'excentrique en surpoids.
          return role == _DayRole.normal && !a.heavyImpactBanned
              ? _beginnerNegative(s, ws, week, role)
              : null;
        }
        return role == _DayRole.primerNear
            ? null
            : _beginnerMain(s, ws, week, role);
      case Method.beginnerNegative:
        return role == _DayRole.normal
            ? _beginnerNegative(s, ws, week, role)
            : null;
      case Method.beginnerHold:
        // Appui bras tendus du débutant : tenues courtes et faciles (4 à 6
        // fois 10 s dans la pratique de terrain, CALIBRAGE_CP1 A-18), loin
        // de la limite — elles ne comptent pas comme séries dures.
        final chin = s.exerciseId.startsWith('cs-tenue-menton');
        return _hold(
          s,
          ws,
          week,
          role,
          share: 0.6,
          low: chin ? 3 : 8,
          // (Tenue menton : 60 à 70 % du maintien mesuré, jusqu'à 25 s ;
          // panel CX, boucle 2 — un plafond de 15 s la laissait à 46 % d'un
          // maintien de 33 s.)
          high: chin ? 25 : 30,
          fallback: chin ? 5 : 10,
        )?..rir = 5;
      case Method.skillHold:
        // R4-F6 : maintiens à 50 à 70 % du maintien maximal.
        return _hold(
          s,
          ws,
          week,
          role,
          share: 0.6,
          low: 3,
          high: 20,
          fallback: 5,
        );
      case Method.skillEasyHold:
        if (role != _DayRole.normal) {
          return null;
        }
        return _hold(
          s,
          ws,
          week,
          role,
          share: 0.6,
          low: 5,
          // (Étape plus facile tenue longtemps : 60 % de son maintien
          // jusqu'à 40 s ; panel CX, boucle 2.)
          high: 40,
          fallback: 10,
        );
      case Method.skillAttempt:
        return _skillAttempt(s, ws, week, role);
      case Method.skillDynamic:
        return _skillDynamic(s, ws, week, role);
      case Method.skillBalance:
        return _skillBalance(s, ws, week, role);
      case Method.warmupPrep:
        return _warmup(s, ws, role);
      case Method.mobility:
        return _mobility(s, ws, role);
      case Method.runEasy || Method.runLong || Method.runQuality:
        return _run(s, day, ws, role);
      default:
        return _accessory(s, ws, week, role);
    }
  }

  /// Test du chemin vers la première traction : la descente la plus lente
  /// possible, puis — quand la traction est un objectif et que la semaine
  /// porte un test — l'essai strict dans la même séance. `null` si la
  /// descente freinée n'est pas admise ce jour-là.
  _Draft? _gate(SlotSpec? s, String slotId, int day) {
    // Test compté en secondes sur un exercice compté en secondes (CX,
    // correction 7 : la descente freinée est comptée en répétitions par le
    // catalogue, son temps ne pouvait pas être relevé) : la tenue menton
    // au-dessus de la barre, bras fléchis — le test de la position haute
    // des débutants sans traction (Davis 2000 : 6 à 8 s en moyenne chez
    // l'homme, 3 à 4 s chez la femme ; « excellent » au-delà de 13 et 6 s).
    // Il mesure un progrès d'un test à l'autre ; son lien avec la première
    // traction est faible (r 0,25 à 0,36, rapport des Marines 2011) : ce
    // n'est pas un critère d'accès à la traction.
    const hang = coachGateExercise;
    if (a.heavyImpactBanned || a.rejection(hang, day) != null) {
      return null;
    }
    final attempt = a.aimsAt(Ids.pull);
    final gate = _Draft(s, slotId, a.catalog.exercise(hang), a.traits.of(hang))
      ..method = s?.method ?? Method.beginnerMain
      ..kind = SetKind.test
      ..fixed = true
      ..sets = 2
      ..secondsLow = 5
      // (Le haut de la plage ne borne pas le test : au moins une fois et
      // demie le dernier maintien mesuré — CX, correction 1, panel : test
      // borné à 30 s pour un maintien réel de 34 à 36 s.)
      ..secondsHigh = _gateHigh()
      ..rest = 180
      ..stress = DayStress.heavy
    // Valeur négative : l'essai strict suit dans la même séance (une
    // seule consigne).
    ;
    gate.test = const TestSpec(
      kind: TestKind.maxHold,
      targetRir: 1,
      attempts: 2,
    );
    if (attempt) {
      // L'essai strict d'abord, frais ; la descente chronométrée ensuite,
      // seulement si la traction n'est pas passée (elle mesure alors le
      // progrès sans coûter la répétition visée).
      final goal = a.goalOn(Ids.pull, GoalMetric.maxReps)?.targetValue;
      gate.reasons.add(_note(CoachNotes.strictAttempt, goal ?? 1));
    }
    gate.reasons.add(_note(CoachNotes.negativeGate, attempt ? -10 : 10));
    return gate;
  }

  /// Figure sur une zone douloureuse au bloc précédent (douleur relevée
  /// par le moteur d'évolution, sous le seuil d'arrêt) : gardée, environ
  /// 40 % de volume en moins (R5-P23 : −30 à −50 %), sans hausse.
  void _painTrend(_Draft x) {
    if (x.kind == SetKind.test || !coachFigurePatterns.contains(x.e.pattern)) {
      return;
    }
    var worst = 0;
    BodyZone? stopped;
    for (final l in a.limits) {
      final joint = l.joint;
      if (!l.trend ||
          joint == null ||
          l.discomfort < 3 ||
          x.e.stressOn(joint) == JointStress.low) {
        continue;
      }
      if (a.stopZones.contains(l.zone)) {
        // Zone à l'arrêt : seule une variante qui ne la provoque pas (prise
        // neutre) reste ; elle garde le volume réduit, et la note d'arrêt
        // (consulter, reprise après deux semaines à 2/10) remplace celle de
        // la douleur relevée — jamais deux consignes contraires (CX,
        // correction 1, panel : « la figure reste au programme à 4/10 »
        // à côté de l'arrêt).
        stopped = l.zone;
      }
      if (l.discomfort > worst) {
        worst = l.discomfort;
      }
    }
    if (worst == 0) {
      return;
    }
    final kept = _round(x.sets * coachTrendPainShare);
    x.sets = kept < 1 ? 1 : kept;
    if (x.minSets > x.sets) {
      x.minSets = x.sets;
    }
    x.reasons.add(
      stopped != null
          ? _note(CoachNotes.painStop, stopped.index)
          : _note(CoachNotes.painTrend, worst),
    );
  }

  /// Rang de la semaine de charge en cours dans le bloc, pour la reprise
  /// graduée : une semaine allégée garde la part de la dernière semaine de
  /// charge (une restriction n'est jamais levée sur un allègement).
  int _returnWeek = 0;

  /// Exercice en reprise graduée après une douleur qui dure (CX,
  /// correction 1, sécurité) : la moitié du volume habituel la première
  /// semaine de charge, +10 % par semaine de charge (Soligard et al. 2016 :
  /// petites hausses régulières), loin de l'échec (3 répétitions en réserve
  /// au moins) ; la charge d'un mouvement lesté repart vers 67,5 % du 1RM
  /// et monte de 2,5 % par semaine au plus (`_loadAt`).
  void _painReturn(_Draft x) {
    if (x.kind != SetKind.work) {
      return;
    }
    final share = a.returnShareOf(x.e, _returnWeek);
    if (share == null) {
      return;
    }
    final kept = _round(x.sets * share);
    x.sets = kept < 1 ? 1 : kept;
    if (x.minSets > x.sets) {
      x.minSets = x.sets;
    }
    final rir = x.rir;
    if (x.isResistance && rir != null && rir < 3) {
      x.rir = 3;
    }
    x.reasons.add(_note(CoachNotes.painReturnItem, _round2(share)));
  }

  /// Consigne d'exécution du mouvement principal de [x] (R4-F4 : une
  /// consigne externe par série).
  void _cue(_Draft x) {
    if (x.kind == SetKind.warmup || x.support) {
      return;
    }
    final m = x.method;
    final main =
        m == Method.liftHeavy ||
        m == Method.liftVolume ||
        m == Method.repsTop ||
        m == Method.repsStrength ||
        m == Method.repsVolume ||
        m == Method.repsTechnique ||
        m == Method.skillHold ||
        m == Method.skillBalance ||
        m == Method.beginnerMain;
    if (!main) {
      return;
    }
    final e = x.e;
    final root = e.rootId;
    int? code;
    if (root == Ids.muscleUp || root == Ids.weightedMuscleUp) {
      code = 3;
    } else if (e.id.contains('chest-to-bar') ||
        e.id.contains('poitrine-barre')) {
      code = 9;
    } else if (e.id == 'sw-pompe-genoux') {
      code = 10;
    } else if (e.pattern == MovementPattern.tirageVertical) {
      code = 1;
    } else if (root == Ids.dip || root == Ids.weightedDip) {
      // Débutant ou dips assistés : amplitude progressive (relecture
      // documentée CX : l'épaule sous le coude d'emblée, pour qui ne fait
      // aucun dip, charge l'avant de l'épaule en fin d'amplitude).
      code = _level == 0 || e.assisted ? 11 : 2;
    } else if (e.pattern == MovementPattern.figureStatiqueTirage) {
      code = 4;
    } else if (e.pattern == MovementPattern.figureStatiquePoussee) {
      code = 5;
    } else if (root == Ids.pushUp) {
      code = 6;
    } else if (root == Ids.squat) {
      code = 7;
    } else if (e.pattern == MovementPattern.equilibreMains) {
      code = 8;
    }
    if (code != null) {
      x.reasons.add(_note(CoachNotes.cue, code));
    }
  }

  /// Séance qui répète l'épreuve : la première qui porte une série longue.
  int get _rehearsalDay {
    for (final d in skeleton.days) {
      if (d.slots.any((s) => s.method == Method.repsTop)) {
        return d.dayIndex;
      }
    }
    return -1;
  }

  /// Vrai si la semaine [ws] porte des tests hors échéance (fin de bloc).
  bool _blockTests(WeekSpec ws) =>
      ws.testWeek && !ws.eventWeek && !_eventPassed(ws);

  /// Vrai si la semaine [ws] suit la semaine de l'échéance dans le bloc :
  /// aucun test dans les jours qui suivent une épreuve.
  bool _eventPassed(WeekSpec ws) {
    for (final w in _shape.weeks) {
      if (identical(w, ws)) {
        return false;
      }
      if (w.eventWeek) {
        return true;
      }
    }
    return false;
  }

  /// Vrai si l'emplacement principal [s] est testé la semaine [ws] : les
  /// mouvements de l'objectif d'abord ; en semaine d'allègement, deux tests
  /// au plus (un seul sans objectif), pour que l'allègement en reste un ;
  /// jamais une variante sans record (son repère n'aurait pas de sens).
  bool _testable(SlotSpec s, WeekSpec ws, Set<String> tested) {
    final e = a.catalog.find(s.exerciseId);
    if (e == null) {
      return false;
    }
    // Mouvement en reprise graduée après une douleur qui dure : pas de
    // test maximal tant que la reprise n'est pas finie.
    if (a.returnShareOf(e, 0) != null) {
      return false;
    }
    if (s.method == Method.repsStrength &&
        s.referenceId != null &&
        s.referenceId != s.exerciseId &&
        (a.reps[s.exerciseId] ?? 0) <= 0 &&
        a.totalOneRm(s.exerciseId) == null) {
      return false;
    }
    bool aimed(SlotSpec o) =>
        a.aimsAt(o.exerciseId) ||
        (o.referenceId != null && a.aimsAt(o.referenceId!)) ||
        (o.skillTargetId != null && a.aimsAt(o.skillTargetId!));
    var anyAimed = false;
    for (final d in skeleton.days) {
      for (final o in d.slots) {
        if (aimed(o)) {
          anyAimed = true;
        }
      }
    }
    if (ws.intent == WeekIntent.test) {
      return !anyAimed || aimed(s) || tested.length < 3;
    }
    // Les mouvements de l'objectif d'abord (ils arrivent en premier dans
    // la semaine quand ils ouvrent la séance), puis les autres piliers.
    if (anyAimed && !aimed(s) && tested.isEmpty) {
      var pending = false;
      for (final d in skeleton.days) {
        for (final o in d.slots) {
          if (aimed(o) && !tested.contains(o.exerciseId)) {
            pending = true;
          }
        }
      }
      if (pending) {
        return false;
      }
    }
    return tested.length < 3;
  }

  List<_Draft> _dayDrafts(
    int day,
    int week,
    WeekSpec ws,
    _DayRole role,
    Set<String> tested,
  ) {
    final spec = skeleton.days[day];
    final out = <_Draft>[];
    var gated = false;
    _dayNow = day;
    _soft = role == _DayRole.normal && _softBeforeTests(day, ws);
    for (final s in spec.slots) {
      final main =
          s.method == Method.liftHeavy ||
          s.method == Method.repsTop ||
          s.method == Method.skillHold ||
          (s.method == Method.beginnerMain && s.role == SlotRole.main) ||
          (s.method == Method.repsStrength && s.role == SlotRole.main);
      if (_blockTests(ws) &&
          main &&
          role == _DayRole.normal &&
          _testDayOk(day) &&
          week >= s.fromWeek &&
          week <= s.untilWeek &&
          _testable(s, ws, tested) &&
          tested.add(s.exerciseId)) {
        // Fin de bloc : le test remplace le travail du mouvement principal
        // (R3-P16) ; il mesure le progrès et règle le bloc suivant.
        final e = a.catalog.exercise(s.exerciseId);
        // Variante d'un geste visé déjà acquis (pompe adaptée quand
        // l'objectif porte sur la pompe) : le test porte sur le geste
        // visé, c'est lui qui recale la suite.
        final goalId = s.referenceId;
        if (goalId != null &&
            goalId != s.exerciseId &&
            a.aimsAt(goalId) &&
            (a.reps[goalId] ?? 0) > 0 &&
            a.rejection(goalId, day) == null &&
            !tested.contains(goalId)) {
          final goal = a.catalog.exercise(goalId);
          out.add(
            _testOf(
              slotIdFor(day, 70 + tested.length),
              null,
              goal,
              ws,
              event: false,
            )..group = null,
          );
          tested.add(goalId);
          continue;
        }
        // Débutant sans répétition acquise : pas de test maximal.
        // (une traction assistée ne se teste pas au maximum : son test
        // est la descente freinée ; les autres variantes se testent sur
        // une série maximale propre, qui devient leur repère).
        final skip =
            _level == 0 &&
            e.unit != MeasureUnit.seconds &&
            (a.reps[e.id] ?? 0) <= 0 &&
            s.referenceId == Ids.pull;
        if (!skip) {
          out.add(_testOf(s.slotId, s, e, ws, event: false)..group = null);
          continue;
        }
        // Chemin vers la première traction : le test est la descente la
        // plus lente possible ; dix secondes tenues ouvrent l'essai strict
        // (R5-P8).
        final gate = _gate(s, s.slotId, day);
        if (gate != null) {
          out.add(gate);
          gated = true;
          continue;
        }
        // Surpoids : pas de descente freinée — le test est la suspension
        // la plus longue.
        const hang = 'sw-dead-hang';
        if (a.rejection(hang, day) == null && !out.any((x) => x.e.id == hang)) {
          out.add(
            _testOf(s.slotId, s, a.catalog.exercise(hang), ws, event: false)
              ..group = null,
          );
          continue;
        }
      }
      if (gated && s.exerciseId == 'sw-traction-negative') {
        continue;
      }
      final x = _draft(s, day, week, ws, role);
      if (x != null) {
        _cue(x);
        _painTrend(x);
        _painReturn(x);
        out.add(x);
      }
    }
    // Jour de test de fin de bloc : les mouvements principaux qui n'ont pas
    // de séance ce jour-là (ni plus tard dans la semaine) s'y testent aussi
    // (CX, correction 1 : les tests se font en fin de semaine allégée).
    if (_blockTests(ws) && role == _DayRole.normal && _testDayOk(day)) {
      for (final d in skeleton.days) {
        for (final s in d.slots) {
          final e = a.catalog.find(s.exerciseId);
          final main =
              s.method == Method.liftHeavy ||
              s.method == Method.repsTop ||
              s.method == Method.skillHold ||
              (s.method == Method.repsStrength && s.role == SlotRole.main);
          if (e == null ||
              !main ||
              tested.contains(s.exerciseId) ||
              out.any(
                (x) => x.e.id == s.exerciseId && x.kind == SetKind.test,
              ) ||
              week < s.fromWeek ||
              week > s.untilWeek ||
              a.rejection(s.exerciseId, day) != null ||
              _laterSlot(s.exerciseId, day) ||
              ((a.reps[e.id] ?? 0) <= 0 &&
                  (a.holds[e.id] ?? 0) <= 0 &&
                  a.totalOneRm(e.id) == null) ||
              !_testable(s, ws, tested)) {
            continue;
          }
          tested.add(s.exerciseId);
          // (Le travail ordinaire du mouvement ce jour-là cède au test.)
          out.removeWhere(
            (x) => x.e.id == s.exerciseId && x.kind != SetKind.test,
          );
          out.add(
            _testOf(slotIdFor(day, 60 + tested.length), s, e, ws, event: false)
              ..group = null,
          );
        }
      }
    }
    if (blockIndex == 0 && week == 0 && a.gapWeeks >= 2) {
      // Reprise : la série d'entrée est écrite sur la ligne, à la première
      // séance qui porte le mouvement.
      for (final x in out) {
        final m = x.method;
        if (x.kind == SetKind.work &&
            (m == Method.repsTop ||
                m == Method.repsStrength ||
                m == Method.repsVolume ||
                m == Method.repsDensity) &&
            (a.reps[x.e.id] ?? 0) > 0 &&
            _entered.add(x.e.id)) {
          x.reasons.add(_note(CoachNotes.entrySet, a.gapWeeks >= 16 ? 4 : 3));
        }
      }
    }
    if (blockIndex == 0 && week == 0 && a.gapWeeks < 2 && _level >= 1) {
      // Test d'entrée sur un record déclaré (CP2, partie 0 ; relecture
      // documentée CX, `street_06`, 07, 08, 12 ; Helms et al. 2016,
      // Zourdos et al. 2016 : une série à 1 à 3 répétitions de l'échec
      // estime le maximum du jour) : la première séance qui porte un
      // mouvement principal dont le record n'est pas un test récent (daté
      // de six semaines au plus) fait de sa première série une série repère,
      // jusqu'à 2 répétitions de l'échec ; les séries de la semaine se
      // recalent dessus quand elle sort nettement sous le repère. Un record
      // déclaré n'est un repère qu'une fois testé ou recoupé.
      for (final x in out) {
        final m = x.method;
        final reps =
            (m == Method.repsTop ||
                m == Method.repsStrength ||
                m == Method.repsVolume) &&
            (a.reps[x.e.id] ?? 0) > 0;
        final lift =
            (m == Method.liftHeavy || m == Method.liftVolume) &&
            x.load != null &&
            a.oneRm[x.e.id] != null;
        // (Seul un test guidé ou de compétition daté de six semaines au
        // plus dispense de la série repère : un record déclaré prend la date
        // du profil, ce n'est pas une mesure.)
        var recent = false;
        for (final b in a.profile.benchmarks ?? const <Benchmark>[]) {
          final when = b.date;
          if (b.exerciseId == x.e.id &&
              when != null &&
              (b.source == BenchmarkSource.guidedTest ||
                  b.source == BenchmarkSource.competition) &&
              when.daysUntil(a.start) <= 42) {
            recent = true;
          }
        }
        if (x.kind == SetKind.work &&
            (reps || lift) &&
            !recent &&
            _entered.add(x.e.id)) {
          x.reasons.add(_note(CoachNotes.entryCheck, 2));
        }
      }
    }
    if (gated) {
      // Le test de descente remplace les descentes de la séance.
      out.removeWhere(
        (x) => x.kind != SetKind.test && x.e.id == 'sw-traction-negative',
      );
    }
    if (role == _DayRole.event) {
      var k = 0;
      for (final id in _eventExercises()) {
        if (id == Ids.pull &&
            (a.reps[Ids.pull] ?? 0) <= 0 &&
            !out.any((x) => x.e.id == coachGateExercise)) {
          // Objectif de première traction : le jour de l'échéance, la
          // descente freinée puis l'essai strict (le geste non acquis ne
          // se prescrit pas comme un exercice : c'est un essai).
          final gate = _gate(null, slotIdFor(day, 90 + k), day);
          if (gate != null) {
            k++;
            out.add(gate);
          }
          continue;
        }
        if (a.rejection(id, day) != null) {
          continue;
        }
        final e = a.catalog.exercise(id);
        SlotSpec? own;
        for (final s in spec.slots) {
          if (s.exerciseId == id) {
            own = s;
          }
        }
        final slotId = own?.slotId ?? slotIdFor(day, 90 + k);

        if (out.any((x) => x.slotId == slotId)) {
          continue;
        }
        k++;
        final target = _shape.target;
        // Un objectif daté (sans épreuve inscrite) se teste sur la séance
        // elle-même ; seule une vraie épreuve déplace la séance à son jour.
        final offset = target == null || target.event == null
            ? 0
            : a.start.daysUntil(target.date) - 7 * week - _dayOffset(day);
        out.add(
          _testOf(slotId, own, e, ws, event: true)
            ..group = null
            ..reasons.add(_note(CoachNotes.eventDay, offset)),
        );
      }
    }
    if (role == _DayRole.primerNear &&
        _activation.contains(day) &&
        _shape.model == SeasonModel.strengthPeak) {
      // Amorçage à l'avant-veille d'une épreuve de force : deux simples
      // légers et rapides par mouvement, dans l'ordre de l'épreuve
      // (CALIBRAGE_CP1, G : séance d'amorçage à 30 à 65 % du 1RM, un à
      // deux jours avant).
      var k = 0;
      var at = out.length;
      for (var i = 0; i < out.length; i++) {
        if (out[i].method == Method.mobility) {
          at = i;
          break;
        }
      }
      for (final id in _eventExercises()) {
        if (a.rejection(id, day) != null || a.totalOneRm(id) == null) {
          continue;
        }
        final x =
            _Draft(
                null,
                slotIdFor(day, 80 + k),
                a.catalog.exercise(id),
                a.traits.of(id),
              )
              ..method = Method.liftLight
              ..sets = 2
              ..minSets = 1
              ..repsLow = 1
              ..repsHigh = 1
              ..rir = 5
              ..rest = 120
              ..fixed = true
              ..stress = DayStress.light
              ..reasons.add(_note(CoachNotes.primer, 0.65));
        _loadAt(x, 0.65, null);
        out.insert(at + k, x);
        k++;
      }
    }
    // Les tests se font frais : juste après l'échauffement.
    if (role != _DayRole.event && out.any((x) => x.kind == SetKind.test)) {
      // (Le test de l'objectif d'abord, frais ; les autres ensuite ; panel
      // CX, boucle 2 : le test de traction venait après la série maximale
      // de pompes.)
      bool goal(_Draft x) =>
          a.aimsAt(x.e.id) ||
          (x.e.id == coachGateExercise && a.aimsAt(Ids.pull));
      final ordered = <_Draft>[
        for (final x in out)
          if (x.kind == SetKind.warmup) x,
        for (final x in out)
          if (x.kind == SetKind.test && goal(x)) x,
        for (final x in out)
          if (x.kind == SetKind.test && !goal(x)) x,
        for (final x in out)
          if (x.kind != SetKind.warmup && x.kind != SetKind.test) x,
      ];
      out
        ..clear()
        ..addAll(ordered);
    }
    if (out.every((x) => x.kind == SetKind.warmup)) {
      // Séance qui serait vide (récupération sans tirage ni mobilité au
      // squelette) : un travail facile du premier emplacement.
      for (final s in spec.slots) {
        if (s.method == Method.warmupPrep) {
          continue;
        }
        final x =
            _draft(s, day, week, ws, _DayRole.primerFar) ??
            _draft(s, day, week, ws, _DayRole.normal);
        if (x != null) {
          x
            ..sets = x.sets > 2 ? 2 : x.sets
            ..rir = x.kind == SetKind.work ? 5 : x.rir
            ..backoff = false
            ..everyMinute = false
            ..reasons.add(_note(CoachNotes.recovery, 0));
          out.add(x);
          break;
        }
      }
    }
    if (out.isEmpty) {
      for (final s in spec.slots) {
        final x = _warmup(s, ws, _DayRole.normal);
        if (x != null) {
          out.add(x..kind = SetKind.work);
          break;
        }
      }
    }
    // Un autre test de tirage le même jour : un seul essai de descente.
    final otherPull = out.any(
      (x) =>
          x.kind == SetKind.test &&
          x.e.id != coachGateExercise &&
          (x.e.pattern == MovementPattern.tirageVertical ||
              x.e.rootId == Ids.muscleUp),
    );
    if (otherPull) {
      for (final x in out) {
        if (x.kind == SetKind.test && x.e.id == coachGateExercise) {
          x.sets = 1;
        }
      }
    }
    return out;
  }

  // -------------------------------------------------------------- garde-fous

  double _daySeconds(List<_Draft> items, int minutes) {
    var total = 0.0;
    var resistance = false;
    for (final x in items) {
      total += x.seconds;
      resistance = resistance || x.isResistance;
    }
    return total + (resistance ? coachWarmupFor(minutes) : 0);
  }

  /// Ramène la séance sous le temps du jour : séries retirées aux
  /// emplacements les moins prioritaires, puis emplacements retirés
  /// (`Method.cutOrder`).
  void _fitTime(List<_Draft> items, int minutes) {
    final budget = minutes * 60.0;
    int rank(_Draft x) => x.keep
        ? Method.cutRank(Method.repsVolume)
        : (x.support
              ? Method.cutRank(Method.accessoryCompound)
              : Method.cutRank(x.method));
    // 0. La marche de fin de séance prend le temps qui reste, rien de plus.
    for (final x in <_Draft>[...items]) {
      if (x.slot?.note != 'walk' && x.slot?.note != 'run_extra') {
        continue;
      }
      final over = _daySeconds(items, minutes) - budget;
      final high = x.secondsHigh;
      if (over <= 0 || high == null) {
        continue;
      }
      final kept = ((high - over) ~/ 60) * 60;
      if (kept < 300) {
        items.remove(x);
      } else {
        x
          ..secondsLow = kept
          ..secondsHigh = kept;
      }
    }
    var guard = 0;
    while (_daySeconds(items, minutes) > budget && guard < 200) {
      guard++;
      _Draft? pick;
      // 1. Une série en moins, au plus bas de l'ordre de retrait, sans
      // descendre sous deux séries.
      for (final x in items) {
        if (x.fixed || x.sets <= 2 || x.sets <= x.minSets) {
          continue;
        }
        if (pick == null ||
            rank(x) < rank(pick) ||
            (rank(x) == rank(pick) && x.sets > pick.sets)) {
          pick = x;
        }
      }
      if (pick != null) {
        pick.sets--;
        continue;
      }
      // 2. Un emplacement d'assistance en moins.
      for (final x in items) {
        if (x.fixed || x.kind == SetKind.test) {
          continue;
        }
        if (rank(x) > Method.cutRank(Method.liftVariant)) {
          continue;
        }
        if (pick == null || rank(x) < rank(pick)) {
          pick = x;
        }
      }
      if (pick != null && items.length > 1) {
        items.remove(pick);
        continue;
      }
      // 3. Une série en moins sur le travail principal.
      pick = null;
      for (final x in items) {
        if (x.fixed || x.sets <= 1 || x.sets <= x.minSets) {
          continue;
        }
        if (pick == null || rank(x) < rank(pick)) {
          pick = x;
        }
      }
      if (pick != null) {
        pick.sets--;
        continue;
      }
      // 4. Le dernier emplacement non essentiel.
      for (final x in items.reversed) {
        if (!x.fixed && x.kind == SetKind.work && items.length > 1) {
          pick = x;
          break;
        }
      }
      if (pick == null) {
        // 5. Durées fixes (course) : on raccourcit.
        var cut = false;
        for (final x in items) {
          final hold = x.secondsHigh;
          final meters = x.distance;
          if (!x.isResistance && hold != null && hold > 600) {
            x
              ..secondsLow = hold - 120
              ..secondsHigh = hold - 120;
            cut = true;
            break;
          }
          if (!x.isResistance &&
              x.kind != SetKind.test &&
              meters != null &&
              meters > 1500 &&
              x.sets == 1) {
            x.distance = meters - 300;
            cut = true;
            break;
          }
          if (x.sets > 1 && x.kind != SetKind.test) {
            x.sets--;
            cut = true;
            break;
          }
        }
        if (!cut) {
          // 6. Séance très courte : la préparation spécifique saute.
          _Draft? prep;
          for (final x in items) {
            if (x.kind == SetKind.warmup && items.length > 1) {
              prep = x;
            }
          }
          if (prep != null) {
            items.remove(prep);
            continue;
          }
          // 7. Créneau trop court pour toutes les épreuves : la dernière
          // attend la séance suivante.
          _Draft? last;
          var tests = 0;
          for (final x in items) {
            if (x.kind == SetKind.test) {
              tests++;
              last = x;
            }
          }
          if (last == null || tests <= 1) {
            if (last != null && last.sets > 1) {
              last.sets--;
              continue;
            }
            break;
          }
          items.remove(last);
        }
        continue;
      }
      items.remove(pick);
    }
    // Dernier recours (créneaux de 10 à 15 minutes) : on ne garde que le
    // début de la séance, puis on raccourcit ce qui reste.
    while (_daySeconds(items, minutes) > budget && items.length > 1) {
      _Draft? last;
      for (final x in items) {
        if (x.kind != SetKind.test) {
          last = x;
        }
      }
      items.remove(last ?? items.last);
    }
    if (items.length == 1 && _daySeconds(items, minutes) > budget) {
      final x = items.first;
      while (x.sets > 1 && _daySeconds(items, minutes) > budget) {
        x.sets--;
      }
      final over = _daySeconds(items, minutes) - budget;
      final hold = x.secondsHigh;
      final meters = x.distance;
      if (over > 0 && !x.isResistance && hold != null && hold > 300) {
        final kept = hold - over.ceil() < 300 ? 300 : hold - over.ceil();
        x
          ..secondsLow = kept
          ..secondsHigh = kept;
      } else if (over > 0 &&
          !x.isResistance &&
          x.kind != SetKind.test &&
          meters != null) {
        final kept = meters - over * coachRunMetersPerSecond;
        x.distance = kept < 800 ? 800 : (kept / 100).floorToDouble() * 100;
      }
    }
  }

  double _limit(
    List<double> series,
    List<bool> light,
    int index,
    double rise,
    double tolerance,
  ) {
    var loaded = 0.0;
    var easy = 0.0;
    var anyLoaded = false;
    for (var k = index - 3; k < index; k++) {
      if (k < 0) {
        continue;
      }
      if (light[k]) {
        if (series[k] > easy) {
          easy = series[k];
        }
      } else {
        anyLoaded = true;
        if (series[k] > loaded) {
          loaded = series[k];
        }
      }
    }
    double step(double reference) {
      final relative = reference * (1 + rise);
      final absolute = reference + tolerance;
      return relative > absolute ? relative : absolute;
    }

    if (anyLoaded) {
      return step(loaded > easy ? loaded : easy);
    }
    final stepped = step(easy);
    final resumed = easy / 0.5;
    return stepped > resumed ? stepped : resumed;
  }

  /// Retire une série dure créditée au groupe [g] (ou une tenue de la
  /// famille [family]) à l'emplacement le moins prioritaire. Rend faux si
  /// plus rien ne peut être retiré.
  bool _trim(
    List<List<_Draft>> days, {
    MuscleGroup? g,
    int family = -1,
    bool any = false,
  }) {
    _Draft? pick;
    List<_Draft>? home;
    final beginner = _level == 0;
    for (final items in days) {
      for (final x in items) {
        if (x.kind == SetKind.test) {
          continue;
        }
        final counts = any
            ? x.hard
            : (g != null
                  ? x.creditOf(g) > 0
                  : (straightArmFamilyOf(x.e) == family && x.holdSeconds > 0));
        if (!counts) {
          continue;
        }
        // Le tirage horizontal gardé pour l'équilibre des épaules ne
        // descend pas sous deux séries.
        if (x.keep && x.sets <= 2) {
          continue;
        }
        final pass = Method.trimPass(
          x.method,
          x.sets,
          beginner: beginner,
          support: x.support,
          keep: x.keep,
        );
        if ((pass == 4 || pass == 7) && items.length <= 1) {
          continue;
        }
        final current = pick;
        var before =
            current == null ||
            Method.trimBefore(
              x.method,
              x.sets,
              current.method,
              current.sets,
              beginner: beginner,
              support: x.support,
              otherSupport: current.support,
              keep: x.keep,
              otherKeep: current.keep,
            );
        if (current != null && g != null) {
          // À passe égale, la série retirée est celle qui compte le plus
          // pour le groupe en trop (crédit principal avant crédit
          // secondaire) : on ne retire pas deux séries d'un mouvement
          // voisin pour en économiser une.
          final passX = Method.trimPass(
            x.method,
            x.sets,
            beginner: beginner,
            support: x.support,
            keep: x.keep,
          );
          final passC = Method.trimPass(
            current.method,
            current.sets,
            beginner: beginner,
            support: current.support,
            keep: current.keep,
          );
          final creditX = x.traits.creditOf(g);
          final creditC = current.traits.creditOf(g);
          if (passX == passC && creditX != creditC) {
            before = creditX > creditC;
          }
        }
        if (before) {
          pick = x;
          home = items;
        }
      }
    }
    if (pick == null || home == null) {
      return false;
    }
    final pass = Method.trimPass(
      pick.method,
      pick.sets,
      beginner: beginner,
      support: pick.support,
      keep: pick.keep,
    );
    if (pass == 4 || pass == 7) {
      home.remove(pick);
    } else {
      pick.sets--;
    }
    return true;
  }

  void _fitVolume(List<List<_Draft>> days, WeekSpec ws) {
    final index = _history.length;
    final light = <bool>[for (final h in _history) h.light, ws.light];
    // (Reprise longue : les cinq premières semaines remontent du demi-
    // volume au plein volume par hausses de 20 % au plus ; ensuite la
    // montée lente reprend.)
    final regaining = blockIndex == 0 && a.gapWeeks >= 10 && index <= 4;
    final rise = _slow && !regaining ? coachVolumeRise / 2 : coachVolumeRise;
    final tolerance = _slow && !regaining ? 1.0 : 2.0;
    for (final g in MuscleGroup.values) {
      if (!g.major) {
        continue;
      }
      var guard = 0;
      while (guard < 60) {
        guard++;
        var sets = 0.0;
        for (final items in days) {
          for (final x in items) {
            sets += x.creditOf(g);
          }
        }
        var limit = coachGroupCap(a, g);
        if (index > 0) {
          final series = <double>[
            for (final h in _history) h.groups[g.index],
            sets,
          ];
          final ramp = _limit(series, light, index, rise, tolerance);
          if (ramp < limit) {
            limit = ramp;
          }
          if (index > 1 &&
              !light[index] &&
              !light[index - 1] &&
              !light[index - 2] &&
              series[index - 2] > 0) {
            final before = series[index - 2];
            final two = before * 1.3 > before + 4 ? before * 1.3 : before + 4;
            if (two < limit) {
              limit = two;
            }
          }
        }
        if (sets <= limit + 1e-9) {
          break;
        }
        if (_trim(days, g: g)) {
          continue;
        }
        // Plus rien à retirer (séances d'un seul exercice) : l'exercice
        // reste facile cette semaine-là, à 5 répétitions en réserve.
        _Draft? ease;
        for (final items in days) {
          for (final x in items) {
            if (x.kind != SetKind.test &&
                x.creditOf(g) > 0 &&
                (ease == null ||
                    Method.cutRank(x.method) < Method.cutRank(ease.method))) {
              ease = x;
            }
          }
        }
        if (ease == null) {
          break;
        }
        ease.rir = 5;
      }
    }
    // Total des séries dures de la semaine (R5-P22 : +10 à +20 % par
    // semaine au plus, deux fois moins vite pour un profil lent ou une
    // reprise longue) : la somme ne monte pas plus vite que chaque groupe.
    var guardAll = 0;
    while (guardAll < 80 && index > 0) {
      guardAll++;
      var total = 0.0;
      for (final items in days) {
        for (final x in items) {
          if (x.hard) {
            total += x.sets;
          }
        }
      }
      final series = <double>[for (final h in _history) h.hard, total];
      final limit = _limit(series, light, index, rise, 2);
      if (total <= limit + 1e-9 || !_trim(days, any: true)) {
        break;
      }
    }
    // Semaine d'allègement : 65 % au plus du plus haut des trois semaines
    // précédentes du bloc (R3-P11 : décharge de 40 à 60 % du volume ; le
    // plancher de deux séries par exercice la laissait parfois à 75 % sur
    // les programmes à nombreux exercices ; panel et banc CX, boucle 2).
    if (ws.kind == WeekKind.deload &&
        ws.intent == WeekIntent.deload &&
        index > 0) {
      var peak = 0.0;
      for (var k = index - 3; k < index; k++) {
        if (k >= 0 && _history[k].hard > peak) {
          peak = _history[k].hard;
        }
      }
      var guardRelief = 0;
      while (guardRelief < 80 && peak > 0) {
        guardRelief++;
        var total = 0.0;
        for (final items in days) {
          for (final x in items) {
            if (x.hard) {
              total += x.sets;
            }
          }
        }
        if (total <= peak * coachDeloadShare + 1e-9 ||
            !_trim(days, any: true)) {
          break;
        }
      }
    }
    // Répétitions écrites par mouvement au poids du corps, séries au chrono
    // comprises (CX, correction 1 : +35 % de dips d'une semaine à l'autre
    // en début de bloc) : +15 % au plus sur la plus chargée des trois
    // semaines précédentes, quelle qu'en soit la nature (Soligard et al.
    // 2016, consensus du CIO : hausses de moins de 10 à 15 % par semaine ;
    // Gabbett 2016). Un mouvement nouveau n'est pas borné.
    _fitReps(days, index);
    // Tenues bras tendus (R4-F10, R5-P22).
    final armRise = coachStraightArmRise[_level];
    for (var family = 0; family < 3; family++) {
      var guard = 0;
      while (guard < 60 && index > 0) {
        guard++;
        var seconds = 0.0;
        for (final items in days) {
          for (final x in items) {
            if (straightArmFamilyOf(x.e) == family) {
              seconds += x.holdSeconds;
            }
          }
        }
        final series = <double>[
          for (final h in _history) h.straightArm[family],
          seconds,
        ];
        final limit = _limit(series, light, index, armRise, 5);
        if (seconds <= limit + 1e-9) {
          break;
        }
        if (_trim(days, family: family)) {
          continue;
        }
        // Plus de série à retirer : les tenues raccourcissent d'une seconde.
        _Draft? longest;
        for (final items in days) {
          for (final x in items) {
            final hold = x.secondsHigh;
            if (straightArmFamilyOf(x.e) == family &&
                x.kind != SetKind.test &&
                hold != null &&
                hold > 3 &&
                (longest == null || hold > longest.secondsHigh!)) {
              longest = x;
            }
          }
        }
        if (longest == null) {
          // Dernier recours : le test de maintien de la famille attend un
          // autre bloc (le budget tendineux passe avant la mesure).
          _Draft? test;
          List<_Draft>? home;
          for (final items in days) {
            for (final x in items) {
              if (x.kind == SetKind.test &&
                  straightArmFamilyOf(x.e) == family &&
                  items.length > 1) {
                test = x;
                home = items;
              }
            }
          }
          if (test == null || home == null) {
            break;
          }
          home.remove(test);
          continue;
        }
        final hold = longest.secondsHigh! - 1;
        final low = longest.secondsLow;
        longest
          ..secondsHigh = hold
          ..secondsLow = low != null && low > hold ? hold : low;
      }
    }
  }

  /// Garde-fou du volume de répétitions (voir `_fitVolume`).
  void _fitReps(List<List<_Draft>> days, int index) {
    if (index <= 0) {
      return;
    }
    double sumOf(String root) {
      var total = 0.0;
      for (final items in days) {
        for (final x in items) {
          final high = x.repsHigh;
          if (high != null &&
              x.kind == SetKind.work &&
              x.isResistance &&
              _repsRootOf(x.e) == root) {
            total += x.sets * high;
          }
        }
      }
      return total;
    }

    final roots = <String>{
      for (final items in days)
        for (final x in items)
          if (_repsRootOf(x.e) case final root?) root,
    }.toList()..sort();
    for (final root in roots) {
      var reference = 0.0;
      for (var k = index - 3; k < index; k++) {
        if (k >= 0) {
          final v = _history[k].reps[root] ?? 0;
          if (v > reference) {
            reference = v;
          }
        }
      }
      if (reference <= 0) {
        continue;
      }
      final limit = reference * (1 + coachVolumeRise);
      var guard = 0;
      while (sumOf(root) > limit + 1e-9 && guard < 80) {
        guard++;
        // Une série en moins à l'emplacement le moins prioritaire (départs
        // au chrono d'abord, puis volume, puis séries de recul).
        _Draft? pick;
        for (final items in days) {
          for (final x in items) {
            if (x.kind != SetKind.work ||
                x.fixed ||
                x.repsHigh == null ||
                _repsRootOf(x.e) != root ||
                x.sets <= x.minSets ||
                x.sets <= 1) {
              continue;
            }
            if (pick == null ||
                Method.cutRank(x.method) < Method.cutRank(pick.method) ||
                (Method.cutRank(x.method) == Method.cutRank(pick.method) &&
                    x.sets * x.repsHigh! > pick.sets * pick.repsHigh!)) {
              pick = x;
            }
          }
        }
        if (pick != null) {
          pick.sets--;
          continue;
        }
        // Plus de série à retirer : une répétition de moins par série à
        // l'emplacement le plus long (hors série de tête).
        _Draft? longest;
        for (final items in days) {
          for (final x in items) {
            final high = x.repsHigh;
            if (x.kind != SetKind.work ||
                x.fixed ||
                high == null ||
                high <= 1 ||
                _repsRootOf(x.e) != root ||
                x.backoff ||
                (longest != null && high <= longest.repsHigh!)) {
              continue;
            }
            longest = x;
          }
        }
        if (longest == null) {
          break;
        }
        final before = longest.repsHigh!;
        final after = before - 1;
        longest
          ..repsHigh = after
          ..repsLow = (longest.repsLow ?? after) > after
              ? after
              : longest.repsLow;
        final target = longest.intensity;
        if (target != null && target.basis == IntensityBasis.percentBenchmark) {
          longest.intensity = target.copyWith(
            value: _round3(target.value * after / before),
          );
        }
      }
    }
  }

  /// Semaines allégées : les séries dures restent sous 55 % du pic des six
  /// semaines précédentes la semaine de l'échéance (R3-P12, R3-P21 : volume
  /// −40 à −60 %), sous 65 % du pic des trois semaines précédentes en
  /// allègement, affûtage ou transition (R3-P9 : séries −40 à −50 %).
  void _fitTaper(List<List<_Draft>> days, WeekSpec ws) {
    final relief =
        ws.intent == WeekIntent.deload ||
        ws.intent == WeekIntent.taper ||
        ws.intent == WeekIntent.transition;
    if (!ws.eventWeek && !relief) {
      return;
    }
    final window = ws.eventWeek ? 6 : 3;
    var peak = 0.0;
    for (var k = _history.length - window; k < _history.length; k++) {
      if (k >= 0 && _history[k].hard > peak) {
        peak = _history[k].hard;
      }
    }
    if (peak <= 0) {
      return;
    }
    // Affûtage : −45 % au moins (Bosquet 2007 : optimum −41 à −60 %,
    // intensité et fréquence gardées) ; allègement ordinaire : −35 %.
    final limit =
        peak *
        // (Débutant : la fatigue se dissipe en quelques jours, l'affûtage
        // reste court et léger — −30 %, R3-P12, R3-P21.)
        (_level == 0
            ? (ws.eventWeek ? 0.6 : 0.7)
            : (ws.eventWeek || ws.intent == WeekIntent.taper ? 0.55 : 0.65));
    var guard = 0;
    while (guard < 80) {
      guard++;
      var total = 0.0;
      for (final items in days) {
        for (final x in items) {
          if (x.hard) {
            total += x.sets;
          }
        }
      }
      if (total <= limit + 1e-9) {
        break;
      }
      _Draft? pick;
      List<_Draft>? home;
      for (final items in days) {
        for (final x in items) {
          if (!x.hard || x.kind == SetKind.test) {
            continue;
          }
          if (x.sets <= 1 && items.length <= 1) {
            continue;
          }
          if (pick == null ||
              Method.cutRank(x.method) < Method.cutRank(pick.method) ||
              (Method.cutRank(x.method) == Method.cutRank(pick.method) &&
                  x.sets > pick.sets)) {
            pick = x;
            home = items;
          }
        }
      }
      if (pick == null || home == null) {
        break;
      }
      final essential = Method.essential(
        pick.method,
        support: pick.support,
        keep: pick.keep,
      );
      if (pick.sets > 2 || (essential && pick.sets > 1)) {
        pick.sets--;
      } else if (home.length > 1) {
        home.remove(pick);
      } else {
        pick.sets = 1;
        break;
      }
    }
  }

  /// Reprise après dix semaines d'arrêt ou plus (R5-P7, R5-P22) : la
  /// première semaine à la moitié des séries dures, puis 57 %, 66 % et
  /// 76 % (hausses de 10 à 15 %) — le plein volume ensuite, sous le
  /// garde-fou de +20 % par semaine.
  void _fitReturn(List<List<_Draft>> days, int week) {
    if (blockIndex != 0 || a.gapWeeks < 10 || week >= 4) {
      return;
    }
    final factor = const <double>[0.5, 0.57, 0.66, 0.76][week];
    double total() {
      var t = 0.0;
      for (final items in days) {
        for (final x in items) {
          if (x.hard) {
            t += x.sets;
          }
        }
      }
      return t;
    }

    final limit = total() * factor;
    var guard = 0;
    while (total() > limit + 1e-9 && guard < 120) {
      guard++;
      _Draft? pick;
      for (final items in days) {
        for (final x in items) {
          if (!x.hard || x.kind == SetKind.test) {
            continue;
          }
          final least = x.everyMinute ? 3 : 1;
          if (x.sets <= least) {
            continue;
          }
          if (pick == null ||
              x.sets > pick.sets ||
              (x.sets == pick.sets &&
                  Method.cutRank(x.method) < Method.cutRank(pick.method))) {
            pick = x;
          }
        }
      }
      if (pick == null) {
        break;
      }
      pick.sets--;
      if (pick.minSets > pick.sets) {
        pick.minSets = pick.sets;
      }
      if (pick.backoff && pick.sets < 2) {
        pick.backoff = false;
      }
    }
  }

  /// Plancher de la semaine de l'échéance, avant les garde-fous de volume
  /// (qui gardent le dernier mot).
  void _floorEvent(List<List<_Draft>> days, WeekSpec ws) {
    // (Échéances avec pic de forme seulement : avant un simple test daté,
    // le volume continue de baisser jusqu'au test.)
    if (!ws.eventWeek || !(_shape.target?.peak ?? false)) {
      return;
    }
    var peak = 0.0;
    for (var k = _history.length - 6; k < _history.length; k++) {
      if (k >= 0 && _history[k].hard > peak) {
        peak = _history[k].hard;
      }
    }
    if (peak <= 0) {
      return;
    }
    var guard = 0;
    // R3-P12, R3-P21 : l'affûtage garde l'intensité et 40 à 60 % du volume ;
    // une semaine d'échéance trop vide désentraîne. Sous 42 % du pic, les
    // une semaine d'échéance trop vide désentraîne. Sous 36 % du pic, les
    // rappels des jours éloignés de l'épreuve reprennent une série (trois
    // au plus), le travail le plus spécifique d'abord.
    final floor = peak * (_shape.model == SeasonModel.repsPeak ? 0.37 : 0.42);
    final closed = <_Draft>{};
    while (guard < 60) {
      guard++;
      var total = 0.0;
      for (final items in days) {
        for (final x in items) {
          if (x.hard) {
            total += x.sets;
          }
        }
      }
      if (total >= floor - 1e-9) {
        break;
      }
      _Draft? pick;
      var home = -1;
      for (var d = 0; d < days.length; d++) {
        for (final x in days[d]) {
          if (!x.hard ||
              x.fixed ||
              x.kind != SetKind.work ||
              x.sets >= (_shape.model == SeasonModel.strengthPeak ? 4 : 3) ||
              closed.contains(x) ||
              !Method.essential(x.method, support: x.support, keep: x.keep)) {
            continue;
          }
          if (pick == null ||
              x.sets < pick.sets ||
              (x.sets == pick.sets &&
                  Method.cutRank(x.method) > Method.cutRank(pick.method))) {
            pick = x;
            home = d;
          }
        }
      }
      if (pick == null) {
        break;
      }
      pick.sets++;
      if (_daySeconds(days[home], a.days[home].minutes) >
          a.days[home].minutes * 60.0) {
        pick.sets--;
        closed.add(pick);
      }
    }
  }

  /// Borne la hausse de charge d'une semaine à l'autre (R5-P3, R5-P22) :
  /// au plus `coachLoadRise` au-dessus de la charge de la semaine d'avant
  /// sur le même emplacement, corrigée de 2,5 % par répétition de moins.
  /// Après une semaine de transition ou d'introduction, l'écart de
  /// répétitions compte en entier (CX, correction 1) ; ailleurs, deux
  /// répétitions au plus (CP2, partie 0, constat de charge de `street_08` :
  /// la charge totale montait de 67 à 79 % du 1RM en une semaine quand les
  /// répétitions passaient de 6 à 5 après un allègement, faute de borne à
  /// répétitions différentes). Une semaine allégée ou de test n'est pas
  /// une référence : la borne se prend sur la dernière semaine de charge
  /// (sinon la charge resterait collée à celle de l'allègement). Antécédent
  /// ou gêne au coude : +2,5 kg de charge totale par semaine au plus sur un
  /// mouvement lesté qui charge le coude (paliers de reprise, R5-P20,
  /// R5-P22 ; relecture documentée CX, `street_12`). Le tonnage écrit d'un
  /// exercice lesté (séries × répétitions × charge) ne monte pas de plus de
  /// `coachVolumeRise` sur la semaine de charge de référence ; au-delà, des
  /// séries sont retirées (jamais sous le minimum de l'emplacement).
  void _fitLoads(List<List<_Draft>> days, _WeekTrace trace, WeekSpec ws) {
    final rise = coachLoadRise[_level];
    // Pic de forme (réalisation, affûtage, échéance) : les répétitions
    // baissent par dessein (simples et doubles lourds) ; l'écart de
    // répétitions compte alors en entier, borné comme après une transition.
    final peaking =
        ws.intent == WeekIntent.realization ||
        ws.intent == WeekIntent.taper ||
        ws.intent == WeekIntent.competition ||
        ws.eventWeek;
    final last = _history.isEmpty ? null : _history.last;
    // Semaine de charge de référence : la plus récente des trois dernières
    // qui n'est ni allégée ni de test ; après une transition ou une
    // introduction, la semaine d'avant elle-même.
    _WeekTrace? reference;
    if (last != null && last.restart) {
      reference = last;
    } else {
      for (var k = _history.length - 1; k >= 0; k--) {
        if (k < _history.length - 3) {
          break;
        }
        if (!_history[k].light) {
          reference = _history[k];
          break;
        }
      }
    }
    // (Coude : gêne actuelle, ou antécédent de moins de douze mois.)
    final elbowLimit = a.limitOn(Joint.elbow);
    final elbow =
        elbowLimit != null && (elbowLimit.recent || elbowLimit.discomfort >= 2);
    double factorOf(int beforeReps, int reps, {required bool restart}) {
      var delta = beforeReps - reps;
      if (!restart && !peaking && delta > 2) {
        delta = 2;
      }
      var factor = 1 + rise + coachLoadPerRep * delta;
      // (Quatre répétitions d'écart comptées au plus : panel p2,
      // `street_08` — +20 % de charge totale en une semaine d'affûtage.)
      if (factor > 1 + rise + coachLoadPerRep * 4) {
        factor = 1 + rise + coachLoadPerRep * 4;
      }
      return factor;
    }

    for (var d = 0; d < days.length; d++) {
      for (final x in days[d]) {
        final load = x.load;
        final reps = x.repsHigh;
        if (load == null || reps == null) {
          continue;
        }
        final fraction = x.e.bodyweightFraction?.value ?? 0;
        var total = load + fraction * a.bodyWeight;
        final key = '$d|${x.slotId}|${x.e.id}';
        double? allowed;
        double? capped(double? now, double v) =>
            now == null || v < now ? v : now;

        // Même emplacement, semaine d'avant (allégée comprise : la charge
        // remonte par paliers après un allègement ; en pic de forme après
        // une semaine allégée, la dernière semaine de charge) : à
        // répétitions égales ou après une transition, l'écart de
        // répétitions compte en entier ; à répétitions différentes, deux
        // répétitions au plus.
        final src = last != null && last.light && !last.restart && peaking
            ? (reference ?? last)
            : last;
        // (À répétitions égales, la semaine d'avant fait toujours foi,
        // allègement compris : le banc borne la hausse d'un emplacement
        // d'une semaine à l'autre à schéma égal — CP2, partie 0, boucle 2 :
        // +6,9 % après l'allègement de `street_07`.)
        final lastSame = last?.loads[key];
        final equal =
            lastSame != null && lastSame.$1 > 0 && lastSame.$2 == reps;
        if (equal) {
          allowed = capped(allowed, lastSame.$1 * (1 + rise));
        }
        final before = src?.loads[key];
        if (!equal && src != null && before != null && before.$1 > 0) {
          allowed = capped(
            allowed,
            before.$1 *
                factorOf(
                  before.$2,
                  reps,
                  restart: src.restart || before.$2 == reps,
                ),
          );
        }
        // Même exercice à répétitions égales, quel que soit l'emplacement :
        // +`coachLoadRise` au plus sur la semaine d'avant (CX, correction 1).
        // (Emplacement nouveau seulement : une série légère du même
        // exercice ailleurs dans la semaine ne bride pas la séance lourde —
        // CP2, partie 0, boucle 3 ; panel p2, `street_07`, `street_09` :
        // dips du jeudi à 68 % en intensification, bridés par le triple
        // léger du vendredi de l'allègement.)
        final same = before == null
            ? src?.loadsByExercise['${x.e.id}|$reps']
            : null;
        if (same != null && same > 0) {
          allowed = capped(allowed, same * (1 + rise));
        }
        // Nouvel emplacement (début de bloc, après un allègement ou un
        // test) : même borne sur la plus lourde charge du même exercice la
        // semaine d'avant, toutes répétitions (passe 7 du panel CX,
        // `street_08` : dips lestés de 67 à 79 % du 1RM en une semaine,
        // juste après l'allègement).
        final top = src?.heaviest[x.e.id];
        if (before == null && src != null && top != null && top.$1 > 0) {
          allowed = capped(
            allowed,
            top.$1 * factorOf(top.$2, reps, restart: src.restart),
          );
        }
        if (elbow &&
            x.e.stressOn(Joint.elbow) != JointStress.low &&
            x.e.loadType == LoadType.addedWeight) {
          var most = 0.0;
          for (var k = _history.length - 3; k < _history.length; k++) {
            final v = k < 0 ? null : _history[k].heaviest[x.e.id];
            if (v != null && v.$1 > most) {
              most = v.$1;
            }
          }
          // (Pic de forme : un simple ou un double lourd peut dépasser de
          // 5 kg au plus la plus lourde charge des trois semaines d'avant.)
          final step = peaking ? 5.0 : 2.5;
          if (most > 0 && (allowed == null || most + step < allowed)) {
            allowed = most + step;
          }
        }
        if (allowed != null &&
            x.kind != SetKind.test &&
            total > allowed + 1e-9) {
          final capped = _external(x.e, allowed, 1);
          if (capped != null && capped < load) {
            // La réserve écrite suit la charge baissée : environ une
            // répétition de plus par 3 % de charge en moins (R1-P11 ;
            // panel p2, `street_07`, `street_09` : « 1 RIR à 71 % × 3 »).
            final rir = x.rir;
            final drop = 1 - (capped + fraction * a.bodyWeight) / total;
            if (rir != null && drop > 0.03) {
              final more = rir + (drop / 0.03).floorToDouble();
              x.rir = more > 5 ? 5 : more;
            }
            x.load = capped;
            total = capped + fraction * a.bodyWeight;
            final oneRm = a.totalOneRm(x.e.id);
            if (oneRm != null && x.percent != null) {
              final pct = _round3(total / oneRm > 1 ? 1 : total / oneRm);
              x.percent = pct;
              final intensity = x.intensity;
              if (intensity != null) {
                x.intensity = intensity.copyWith(value: pct);
              }
            }
          }
        }
        if (x.kind != SetKind.test && total > 0) {
          trace.loads[key] = (total, reps);
          final ex = '${x.e.id}|$reps';
          final most = trace.loadsByExercise[ex];
          if (most == null || total > most) {
            trace.loadsByExercise[ex] = total;
          }
          final heavy = trace.heaviest[x.e.id];
          if (heavy == null || total > heavy.$1) {
            trace.heaviest[x.e.id] = (total, reps);
          }
        }
      }
    }
    // Tonnage par exercice lesté.
    final drafts = <String, List<_Draft>>{};
    for (final items in days) {
      for (final x in items) {
        if (x.load != null &&
            x.repsHigh != null &&
            x.kind == SetKind.work &&
            x.e.loadType == LoadType.addedWeight) {
          drafts.putIfAbsent(x.e.id, () => <_Draft>[]).add(x);
        }
      }
    }
    double tonnageOf(List<_Draft> xs) {
      var t = 0.0;
      for (final x in xs) {
        final fraction = x.e.bodyweightFraction?.value ?? 0;
        t += x.sets * x.repsHigh! * (x.load! + fraction * a.bodyWeight);
      }
      return t;
    }

    for (final entry in drafts.entries) {
      final before = reference?.tonnage[entry.key];
      var now = tonnageOf(entry.value);
      if (before != null && before > 0 && !(reference?.restart ?? false)) {
        final limit = before * (1 + coachVolumeRise);
        // Séries retirées d'abord aux emplacements les plus fournis, jamais
        // sous leur minimum ni dans un groupe enchaîné.
        var guard = 0;
        while (now > limit + 1e-6 && guard < 20) {
          guard++;
          _Draft? pick;
          for (final x in entry.value) {
            if (x.group != null || x.sets <= x.minSets || x.sets <= 1) {
              continue;
            }
            if (pick == null || x.sets > pick.sets) {
              pick = x;
            }
          }
          if (pick == null) {
            break;
          }
          pick.sets--;
          now = tonnageOf(entry.value);
        }
      }
      trace.tonnage[entry.key] = now;
    }
  }

  /// Départs au chrono : un de plus par semaine au plus sur le plus haut
  /// des trois semaines d'avant, et un au plus en deux semaines (règle
  /// écrite du programme, R5-P22 ; panel CX correction 1, `street_04` :
  /// deux départs de plus en une semaine au retour d'une coupure).
  void _fitMinutes(List<List<_Draft>> days, _WeekTrace trace) {
    for (var d = 0; d < days.length; d++) {
      for (final x in days[d]) {
        if (!x.everyMinute || x.kind != SetKind.work) {
          continue;
        }
        final key = '$d|${x.slotId}|${x.e.id}';
        int? most;
        for (var k = _history.length - 3; k < _history.length; k++) {
          final v = k < 0 ? null : _history[k].minutes[key];
          if (v != null && (most == null || v > most)) {
            most = v;
          }
        }
        final last = _history.isEmpty
            ? null
            : _history[_history.length - 1].minutes[key];
        final two = _history.length >= 2
            ? _history[_history.length - 2].minutes[key]
            : null;
        var allowed = most == null ? null : most + 1;
        // (Un départ de plus en deux semaines : la borne porte sur la
        // hausse, jamais sous la semaine d'avant.)
        if (two != null) {
          final pace = last != null && last > two + 1 ? last : two + 1;
          if (allowed == null || pace < allowed) {
            allowed = pace;
          }
        }
        if (allowed != null && x.sets > allowed) {
          x.sets = allowed < x.minSets ? x.minSets : allowed;
        }
        trace.minutes[key] = x.sets;
      }
    }
  }

  /// Garde-fou des tenues du débutant (tenue menton au-dessus de la barre,
  /// suspension, appui) : la tenue écrite par série ne monte pas de plus de
  /// 15 % (2 s au moins) sur la plus longue des trois semaines d'avant
  /// (R5-P22 : +10 à 20 % par semaine), sauf pour rejoindre 55 % du
  /// maintien testé (`coachHoldFloorShare`, passe 5 du panel : tenues à 30
  /// à 45 % du test pendant des semaines).
  void _fitHolds(List<List<_Draft>> days, _WeekTrace trace) {
    for (final items in days) {
      for (final x in items) {
        final high = x.secondsHigh;
        if (x.method != Method.beginnerHold ||
            x.kind == SetKind.test ||
            high == null) {
          continue;
        }
        int? most;
        for (var k = _history.length - 3; k < _history.length; k++) {
          final v = k < 0 ? null : _history[k].holds[x.e.id];
          if (v != null && (most == null || v > most)) {
            most = v;
          }
        }
        if (most != null) {
          final rise = _round(most * (1 + coachVolumeRise));
          var allowed = rise > most + 2 ? rise : most + 2;
          // (Jamais sous 55 % du maintien testé : après un test qui saute,
          // la tenue rejoint la règle 60-70 % sans traîner des semaines à
          // 30-45 % — panel CX, correction 1, passe 5.)
          final t0 = x.intensity;
          if (t0 != null && t0.value > 0) {
            final floor = _round(high / t0.value * coachHoldFloorShare);
            if (floor > allowed) {
              allowed = floor < high ? floor : high;
            }
          }
          if (high > allowed) {
            x.secondsHigh = allowed;
            final low = x.secondsLow;
            if (low != null && low > allowed) {
              x.secondsLow = allowed;
            }
            // (La part affichée suit la tenue écrite : le repère reste le
            // dernier maintien mesuré.)
            final t = x.intensity;
            if (t != null && t.value > 0) {
              final known = high / t.value;
              x.intensity = IntensityTarget(
                basis: t.basis,
                value: _round2(allowed / known),
                referenceExerciseId: t.referenceExerciseId,
                referenceKind: t.referenceKind,
                eventId: t.eventId,
                rirCap: t.rirCap,
              );
            }
          }
        }
        final now = x.secondsHigh!;
        final before = trace.holds[x.e.id];
        if (before == null || now > before) {
          trace.holds[x.e.id] = now;
        }
      }
    }
  }

  /// Séries au poids du corps sur un maximum de répétitions : répétitions
  /// + réserve écrite jamais au-dessus du repère (la réserve se lit dès la
  /// première série). Une série qui dépasse perd des répétitions ; une
  /// pratique d'une répétition garde sa réserve (elle reste loin de
  /// l'échec). (R1-P14 ; panel CX, correction 1, passe 5 : 3 × 4 à 5 à 2 en
  /// réserve sur un maximum de 6, contraire à la règle « maximum − 2 » du
  /// programme.)
  void _fitReserve(List<List<_Draft>> days) {
    for (final items in days) {
      for (final x in items) {
        final slot = x.slot;
        final high = x.repsHigh;
        final rir = x.rir;
        final t = x.intensity;
        if (slot == null ||
            slot.exerciseId != x.e.id ||
            high == null ||
            rir == null ||
            t == null ||
            t.basis != IntensityBasis.percentBenchmark ||
            t.referenceKind == BenchmarkKind.maxHold ||
            x.kind == SetKind.test ||
            x.kind == SetKind.calibration ||
            x.kind == SetKind.warmup ||
            x.load != null ||
            x.percent != null ||
            x.isometric ||
            x.everyMinute) {
          continue;
        }
        final max = _maxOf(slot);
        final top = max - rir.round();
        if (max <= 0 || top < 1 || high <= top) {
          continue;
        }
        final low = x.repsLow;
        x
          ..repsHigh = top
          ..repsLow = low == null || low > top ? top : low;
        if (x.backoffRepsHigh > top) {
          x.backoffRepsHigh = top;
        }
        if (x.backoffRepsLow > x.backoffRepsHigh) {
          x.backoffRepsLow = x.backoffRepsHigh;
        }
        x.intensity = _shareOf(x.e.id, x.repsLow!, max);
      }
    }
  }

  // ------------------------------------------------------------------ sortie

  ExercisePrescription _freeze(_Draft x, String? groupId) {
    final rir = x.rir;
    SetTechnique? technique;
    final rules = <AutoregulationRule>[];
    if (x.backoff && x.sets >= 2) {
      technique = SetTechnique(
        kind: SetTechniqueKind.topSetBackoff,
        backoffSets: x.sets - 1,
        backoffDropPct: x.load != null || x.calibrate ? x.backoffDrop : 0,
        backoffRepsLow: x.backoffRepsLow,
        backoffRepsHigh: x.backoffRepsHigh,
      );
      if ((x.load != null || x.calibrate) && x.backoffDrop > 0) {
        rules.add(
          AutoregulationRule(
            kind: AutoregulationKind.backoffFromTopSet,
            pct: x.backoffDrop,
          ),
        );
      }
    } else if (x.everyMinute) {
      technique = SetTechnique(
        kind: SetTechniqueKind.emom,
        intervalSeconds: x.interval,
        intervals: x.sets,
      );
      rules.add(
        const AutoregulationRule(
          kind: AutoregulationKind.stopOnRepDrop,
          repDrop: 1,
        ),
      );
    } else if (x.practice) {
      technique = const SetTechnique(
        kind: SetTechniqueKind.skillPractice,
        qualityFloor: 4,
      );
      rules.add(
        const AutoregulationRule(
          kind: AutoregulationKind.stopOnQualityDrop,
          qualityFloor: 4,
        ),
      );
    } else if (x.isometric) {
      technique = const SetTechnique(kind: SetTechniqueKind.isometricHold);
    }
    if (rir != null &&
        x.kind == SetKind.work &&
        !x.everyMinute &&
        rir < 5 &&
        x.isResistance) {
      rules.add(
        AutoregulationRule(kind: AutoregulationKind.stopAtRir, rirFloor: rir),
      );
    }
    final basis = _basisOf(x.e);
    return ExercisePrescription(
      slotId: x.slotId,
      exerciseId: x.e.id,
      sets: x.sets,
      repsLow: x.repsLow,
      repsHigh: x.repsHigh,
      secondsLow: x.secondsLow,
      secondsHigh: x.secondsHigh,
      distanceMeters: x.distance,
      targetFlames: rir == null ? null : Flames.fromRir(rir),
      restSeconds: x.rest,
      startLoadKg: basis == LoadBasis.unloaded ? null : x.load,
      percentOfOneRm: x.percent,
      toCalibrate: x.calibrate,
      loadBasis: basis,
      groupId: groupId,
      kind: x.kind,
      reasons: x.reasons,
      technique: technique,
      tempo: x.tempo,
      intensity: x.intensity,
      autoregulation: rules.isEmpty ? null : rules,
      test: x.test,
      dayStress: x.stress,
      skillTargetId: x.slot?.skillTargetId,
      restMode: x.restMode,
    );
  }

  /// Donne le même nombre de tours aux exercices enchaînés d'une séance.
  void _equalize(List<_Draft> items) {
    final rounds = <String, int>{};
    final count = <String, int>{};
    for (final x in items) {
      final g = x.group;
      if (g != null && x.kind == SetKind.work) {
        final before = rounds[g];
        rounds[g] = before == null || x.sets < before ? x.sets : before;
        count[g] = (count[g] ?? 0) + 1;
      }
    }
    for (final x in items) {
      final g = x.group;
      if (g != null && x.kind == SetKind.work && (count[g] ?? 0) >= 2) {
        x
          ..sets = rounds[g]!
          ..rest = x.rest > 75 ? 75 : x.rest
          ..backoff = false
          ..everyMinute = false;
      }
    }
  }

  DayPrescription _freezeDay(int day, List<_Draft> items, WeekSpec ws) {
    // Enchaînements : au moins deux membres, même nombre de tours.
    final members = <String, List<_Draft>>{};
    for (final x in items) {
      final g = x.group;
      if (g != null && x.kind == SetKind.work) {
        members.putIfAbsent(g, () => <_Draft>[]).add(x);
      }
    }
    final groups = <GroupSpec>[];
    final groupOf = <_Draft, String>{};
    for (final entry in members.entries) {
      final list = entry.value;
      if (list.length < 2) {
        continue;
      }
      var rounds = list.first.sets;
      for (final x in list) {
        if (x.sets < rounds) {
          rounds = x.sets;
        }
      }
      final id = 'd$day.${entry.key}';
      for (final x in list) {
        x
          ..sets = rounds
          ..backoff = false
          ..everyMinute = false;
        groupOf[x] = id;
      }
      // Une seule consigne de repos : celle de l'enchaînement.
      for (final x in list) {
        x.rest = 90;
      }
      list.first.reasons.add(_note(CoachNotes.superset, 90));
      groups.add(
        GroupSpec(
          groupId: id,
          format: GroupFormat.superset,
          rounds: rounds,
          restBetweenRoundsSeconds: 90,
        ),
      );
    }
    // Squat et développé couché à 85 % du 1RM et plus : sécurités de la
    // cage ou pareur, et barrière de forme du jour (CP2, partie 0, boucle
    // 2 ; panel p1, `street_09` : échec sous la barre de squat sans
    // sécurité écrite ; NSCA, Essentials of Strength Training and
    // Conditioning, 4e éd. : pareur ou sécurités pour les mouvements
    // au-dessus du visage ou chargés sur le dos).
    var pinned = false;
    for (final x in items) {
      final pct = x.percent;
      if (!pinned &&
          x.kind == SetKind.work &&
          pct != null &&
          pct >= 0.85 &&
          (x.e.id.contains('squat') || x.e.id.contains('developpe-couche'))) {
        x.reasons.add(_note(CoachNotes.safetyPins, 85));
        pinned = true;
      }
    }
    DayStress? stress;
    for (final x in items) {
      final s = x.stress;
      if (s != null && x.kind != SetKind.warmup) {
        if (stress == null || s.index < stress.index) {
          stress = s;
        }
      }
    }
    if (ws.light && ws.intent != WeekIntent.intro && !ws.eventWeek) {
      stress = DayStress.light;
    }
    return DayPrescription(
      dayIndex: day,
      items: <ExercisePrescription>[
        for (final x in items) _freeze(x, groupOf[x]),
      ],
      stress: stress,
      groups: groups.isEmpty ? null : groups,
    );
  }

  /// Charge l'historique des garde-fous avec les semaines du bloc
  /// précédent [weeks].
  void seed(List<WeekPrescription> weeks) {
    for (var i = 0; i < weeks.length; i++) {
      var tested = false;
      for (final d in weeks[i].days) {
        for (final p in d.items) {
          if (p.kind == SetKind.test) {
            tested = true;
          }
        }
      }
      if (tested) {
        _testsDone++;
      }
    }
    for (final w in weeks) {
      _history.add(_traceOf(w));
    }
  }

  /// Trace des garde-fous d'une semaine déjà écrite [w].
  _WeekTrace _traceOf(WeekPrescription w) {
    final trace = _WeekTrace(
      w.kind == WeekKind.intro ||
          w.kind == WeekKind.deload ||
          w.kind == WeekKind.test,
      restart:
          w.kind == WeekKind.intro ||
          w.intent == WeekIntent.transition ||
          w.intent == WeekIntent.intro,
    );
    for (final d in w.days) {
      for (final p in d.items) {
        final t = a.traits.find(p.exerciseId);
        if (t == null) {
          continue;
        }
        final flames = p.targetFlames;
        final hard =
            t.kind.isResistance &&
            p.kind != SetKind.warmup &&
            (flames == null ||
                !Flames.isValid(flames) ||
                Flames.toRir(flames) <= coachHardSetMaxRir);
        if (hard) {
          trace.hard += p.sets;
          for (final g in MuscleGroup.values) {
            trace.groups[g.index] += p.sets * t.creditOf(g) / 2;
          }
        }
        final family = straightArmFamilyOf(t.exercise);
        final hold = p.secondsHigh;
        if (family >= 0 && hold != null && t.kind.isResistance) {
          trace.straightArm[family] += p.sets * hold.toDouble();
        }
        if (hold != null && p.kind != SetKind.test) {
          final before = trace.holds[p.exerciseId];
          if (before == null || hold > before) {
            trace.holds[p.exerciseId] = hold;
          }
        }
        final root = _repsRootOf(t.exercise);
        final high = p.repsHigh;
        if (root != null &&
            high != null &&
            p.kind == SetKind.work &&
            t.kind.isResistance) {
          trace.reps[root] = (trace.reps[root] ?? 0) + p.sets * high;
        }
        final load = p.startLoadKg;
        final reps = p.repsHigh;
        if (load != null && reps != null && p.kind != SetKind.test) {
          final fraction = t.exercise.bodyweightFraction?.value ?? 0;
          final total = load + fraction * a.bodyWeight;
          trace.loads['${d.dayIndex}|${p.slotId}|${p.exerciseId}'] = (
            total,
            reps,
          );
          final ex = '${p.exerciseId}|$reps';
          final most = trace.loadsByExercise[ex];
          if (most == null || total > most) {
            trace.loadsByExercise[ex] = total;
          }
          final top = trace.heaviest[p.exerciseId];
          if (top == null || total > top.$1) {
            trace.heaviest[p.exerciseId] = (total, reps);
          }
          if (p.kind == null || p.kind == SetKind.work) {
            trace.tonnage[p.exerciseId] =
                (trace.tonnage[p.exerciseId] ?? 0) + p.sets * reps * total;
          }
        }
        if ((p.kind == null || p.kind == SetKind.work) &&
            p.reasons.any(
              (r) =>
                  r.code == ReasonCodes.planCoachNote &&
                  r.params['note'] == CoachNotes.everyMinute,
            )) {
          trace.minutes['${d.dayIndex}|${p.slotId}|${p.exerciseId}'] = p.sets;
        }
      }
    }
    return trace;
  }

  /// Semaines du bloc.
  List<WeekPrescription> build() {
    final out = <WeekPrescription>[];
    for (var w = 0; w < _shape.weeks.length; w++) {
      final ws = _shape.weeks[w];
      _today = a.start.addDays(7 * w);
      if (w == 0) {
        _loadedBefore = 0;
      }
      _returnWeek = ws.kind == WeekKind.build || ws.kind == WeekKind.intro
          ? _loadedBefore
          : (_loadedBefore > 0 ? _loadedBefore - 1 : 0);
      _lastLoaded =
          ws.kind == WeekKind.build &&
          w + 1 < _shape.weeks.length &&
          _shape.weeks[w + 1].kind == WeekKind.deload &&
          _shape.weeks[w + 1].intent == WeekIntent.deload;
      var roles = _roles(w, ws);
      if (_eventPassed(ws)) {
        // Semaine qui suit l'échéance dans le bloc : récupération (ni test,
        // ni travail dur, ni tenue bras tendus).
        roles = List<_DayRole>.filled(a.dayCount, _DayRole.after);
      }
      final tested = <String>{};
      final days = <List<_Draft>>[
        for (var d = 0; d < a.dayCount; d++)
          _dayDrafts(d, w, ws, roles[d], tested),
      ];
      for (var d = 0; d < a.dayCount; d++) {
        _equalize(days[d]);
        _fitTime(days[d], a.days[d].minutes);
      }
      _floorEvent(days, ws);
      _fitReturn(days, w);
      _fitVolume(days, ws);
      _fitTaper(days, ws);
      days.forEach(_equalize);
      final trace = _WeekTrace(
        ws.light,
        restart:
            ws.kind == WeekKind.intro ||
            ws.intent == WeekIntent.transition ||
            ws.intent == WeekIntent.intro,
      );
      _fitLoads(days, trace, ws);
      _fitMinutes(days, trace);
      _fitHolds(days, trace);
      _fitReserve(days);
      for (final items in days) {
        for (final x in items) {
          for (final g in MuscleGroup.values) {
            trace.groups[g.index] += x.creditOf(g);
          }
          if (x.hard) {
            trace.hard += x.sets;
          }
          final family = straightArmFamilyOf(x.e);
          if (family >= 0) {
            trace.straightArm[family] += x.holdSeconds;
          }
          final root = _repsRootOf(x.e);
          final high = x.repsHigh;
          if (root != null &&
              high != null &&
              x.kind == SetKind.work &&
              x.isResistance) {
            trace.reps[root] = (trace.reps[root] ?? 0) + x.sets * high;
          }
        }
      }
      // Raison de la semaine, portée par le premier exercice de travail.
      final target = _shape.target;
      for (var d = 0; d < a.dayCount; d++) {
        for (final x in days[d]) {
          if (x.kind == SetKind.warmup) {
            continue;
          }
          x.reasons.insert(
            0,
            reason(ReasonCodes.planWeekKind, <String, Object?>{
              'kind': ws.kind.code,
            }),
          );
          final left = ws.weeksToEvent;
          if (ws.intent == WeekIntent.taper && target != null && left != null) {
            x.reasons.add(
              reason(ReasonCodes.planTaper, <String, Object?>{
                // Part réelle des séries dures de la semaine de pointe
                // (la note dit ce que les tableaux montrent).
                'volumeFactor': () {
                  var peak = 0.0;
                  for (final t in _history) {
                    if (t.hard > peak) {
                      peak = t.hard;
                    }
                  }
                  return peak > 0 && trace.hard > 0
                      ? _round2((trace.hard / peak * 20).round() / 20)
                      : _round2(ws.volume);
                }(),
                'daysToEvent': left * 7,
              }),
            );
          }
          break;
        }
      }
      _history.add(w < kept.length ? _traceOf(kept[w]) : trace);
      if (ws.kind == WeekKind.build || ws.kind == WeekKind.intro) {
        _loadedBefore++;
      }
      var anyTest = false;
      for (final items in days) {
        for (final x in items) {
          if (x.kind == SetKind.test) {
            // Le test recale le repère de l'exercice pour la suite.
            anyTest = true;
          }
        }
      }
      if (anyTest) {
        _testsDone++;
      }
      out.add(
        WeekPrescription(
          weekIndex: w,
          kind: ws.kind,
          intent: ws.intent,
          days: <DayPrescription>[
            for (var d = 0; d < a.dayCount; d++) _freezeDay(d, days[d], ws),
          ],
        ),
      );
    }
    return out;
  }
}

/// Limites des catégories de poids d'une épreuve de streetlifting
/// (règlement FinalRep, lu en partie le 04/10/2026), hommes puis femmes.
const List<double> coachMenClasses = <double>[66, 73, 80, 87, 94, 101];

/// Catégories des femmes.
const List<double> coachWomenClasses = <double>[52, 57, 63, 70];

/// Catégorie de poids d'un athlète de [bodyWeight] kg : la limite de la
/// première catégorie qui le contient (tolérance de 0,1 kg), négative pour
/// la catégorie ouverte ; `null` quand le sexe n'est pas dit.
double? coachWeightClassOf(Sex? sex, double bodyWeight) {
  final table = switch (sex) {
    Sex.male => coachMenClasses,
    Sex.female => coachWomenClasses,
    _ => null,
  };
  if (table == null) {
    return null;
  }
  for (final limit in table) {
    if (bodyWeight <= limit + 0.1 + 1e-9) {
      return limit;
    }
  }
  return -table.last;
}

/// Raisons du bloc : phase, échéance, lecture du profil, règles de douleur.
List<Reason> blockReasonsOf(Athlete a, Skeleton skeleton) {
  final shape = skeleton.shape;
  final target = shape.target;
  final eventId = target?.eventId;
  final profile = a.profile;
  final out = <Reason>[
    if (a.cautious) reason(ReasonCodes.planCautiousHealth),
    reason(ReasonCodes.planSeasonPhase, <String, Object?>{
      'phase': shape.phase.code,
      'weeksToEvent': shape.weeksToEvent ?? 0,
    }),
    if (eventId != null)
      reason(ReasonCodes.planPeakEvent, <String, Object?>{'eventId': eventId}),
    // L'horizon d'une figure se lit d'abord.
    for (final r in skeleton.reasons)
      if (r.params['note'] == CoachNotes.skillHorizon) r,
    reason(ReasonCodes.planCoachNote, <String, Object?>{
      'note': CoachNotes.generalWarmup,
      'value': coachWarmupSeconds / 60,
    }),
  ];
  final tests = shape.weeks.any((w) => w.testWeek);
  Reason note(String code, double value) => reason(
    ReasonCodes.planCoachNote,
    <String, Object?>{'note': code, 'value': value},
  );
  // Épreuve de force : catégorie de poids et pesée (CX, correction 5 ;
  // règlement FinalRep : catégories −66 à +101 kg chez l'homme, −52 à
  // +70 kg chez la femme, pesée 2 h avant la première vague, tolérance de
  // 0,1 kg). La catégorie déclarée prime ; sinon celle du poids actuel.
  final event = target?.event;
  if (event != null &&
      event.kind == EventKind.strengthCompetition &&
      (event.lifts ?? const <CompetitionLift>[]).isNotEmpty) {
    final declared = event.weightClassKg;
    final open = event.openWeightClass ?? false;
    final limit = declared != null
        ? (open ? -declared : declared)
        : coachWeightClassOf(profile.sex, a.bodyWeight);
    if (limit != null) {
      out.add(note(CoachNotes.weightClass, limit));
    }
  }
  // Épreuve de répétitions sans format connu : le dire, et dire ce que le
  // programme suppose en attendant (aucun règlement unifié : CQ.6 ;
  // recherche CX, boucle 0).
  if (event != null &&
      event.kind == EventKind.repsCompetition &&
      event.formatKnown != true) {
    out.add(note(CoachNotes.eventFormat, 300));
  }
  // Objectif de répétitions au-dessus du rythme habituel (R4-G8 : environ
  // +15 % en 12 semaines chez un pratiquant entraîné) : on le dit, avec
  // une fourchette probable — l'objectif reste visé, mais un résultat
  // en dessous n'est pas un échec du plan.
  final firstPull = a.goalOn(Ids.pull, GoalMetric.maxReps)?.targetValue;
  if ((a.reps[Ids.pull] ?? 0) <= 0 && firstPull != null && firstPull >= 2) {
    // Plusieurs tractions en partant de zéro : possible, pas garanti.
    out.add(note(CoachNotes.ambitious, 1000.0 + (firstPull >= 3 ? 2 : 1)));
  }
  if (a.level >= 1) {
    for (final g in profile.goals) {
      final id = g.exerciseId;
      final wanted = g.targetValue;
      final deadline = g.targetDate;
      if (id == null ||
          wanted == null ||
          deadline == null ||
          g.metric != GoalMetric.maxReps) {
        continue;
      }
      final own = a.reps[id] ?? 0;
      final weeks = a.start.daysUntil(deadline) / 7;
      if (own < 4 || weeks < 4 || wanted <= own) {
        continue;
      }
      final rate = (wanted / own - 1) / weeks;
      if (rate <= (a.level >= 2 ? 0.015 : 0.02)) {
        continue;
      }
      var low = (own * (1 + 0.15 * weeks / 12)).round();
      if (low <= own) {
        low = own + 1;
      }
      var high = (own + 0.7 * (wanted - own)).round();
      if (high <= low) {
        high = low + 1;
      }
      if (high >= wanted) {
        continue;
      }
      out.add(note(CoachNotes.ambitious, low * 1000.0 + high));
    }
  }
  final loaded = skeleton.days.any(
    (d) => d.slots.any(
      (s) =>
          s.method == Method.liftHeavy ||
          s.method == Method.liftVolume ||
          s.method == Method.liftMaintain,
    ),
  );
  if (loaded) {
    out.add(note(CoachNotes.loadAdjust, 2.5));
  }
  var shortest = 300;
  for (final d in a.days) {
    if (d.minutes < shortest) {
      shortest = d.minutes;
    }
  }
  final assisted = skeleton.days.any(
    (d) => d.slots.any(
      (s) =>
          s.exerciseId.contains('assiste') &&
          s.exerciseId.contains('elastique'),
    ),
  );
  out
    ..add(note(CoachNotes.repsAdjust, 2))
    // Sommeil court habituel : la baisse du jour se déclenche sur une nuit
    // nettement pire que d'habitude (valeur 2), pas sur la nuit ordinaire.
    ..add(
      note(CoachNotes.badDay, profile.sleep == SleepBand.under6Hours ? 2 : 1),
    )
    ..add(note(CoachNotes.shortVersion, shortest >= 50 ? 25 : 15))
    ..add(note(CoachNotes.redFlags, 0))
    ..add(note(CoachNotes.missed, 20));
  if (tests) {
    out
      ..add(note(CoachNotes.testUse, 0))
      ..add(note(CoachNotes.testRest, 48));
  }
  final age = profile.trainingAge;
  if (age != null) {
    out.add(
      reason(ReasonCodes.planTrainingAge, <String, Object?>{'band': age.code}),
    );
  }
  final gap = profile.trainingGap;
  if (gap != null && a.gapWeeks >= 2) {
    out.add(
      reason(ReasonCodes.planReturnFromGap, <String, Object?>{'gap': gap.code}),
    );
    if (a.gapWeeks >= 4) {
      out.add(note(CoachNotes.reentryTest, a.gapWeeks >= 16 ? 4 : 3));
    }
  }
  final sleep = profile.sleep;
  if (sleep == SleepBand.under6Hours) {
    out.add(
      reason(ReasonCodes.planRecoveryProfile, <String, Object?>{
        'factor': 'sleep',
        'level': SleepBand.under6Hours.code,
      }),
    );
  }
  final stress = profile.stress;
  if (stress == StressBand.high) {
    out.add(
      reason(ReasonCodes.planRecoveryProfile, <String, Object?>{
        'factor': 'stress',
        'level': StressBand.high.code,
      }),
    );
  }
  final job = profile.occupationalLoad;
  if (job == OccupationalLoad.heavy) {
    out.add(
      reason(ReasonCodes.planRecoveryProfile, <String, Object?>{
        'factor': 'occupational_load',
        'level': OccupationalLoad.heavy.code,
      }),
    );
  }
  if (a.age >= 40) {
    out.add(
      reason(ReasonCodes.planRecoveryProfile, <String, Object?>{
        'factor': 'age',
        'level': a.age >= 60 ? '60_plus' : '40_plus',
      }),
    );
  }
  if (a.volumeFactor < 1) {
    out.add(
      reason(ReasonCodes.planCoachNote, <String, Object?>{
        'note': CoachNotes.toleranceVolume,
        'value': _round2(a.volumeFactor),
      }),
    );
  }
  if (a.volumeFactor < 1 ||
      a.pullFactor < 1 ||
      a.legsFactor < 1 ||
      a.rirBonus > 0 ||
      a.slowRamp) {
    out.add(note(CoachNotes.alreadyApplied, 0));
  }
  for (final s in profile.otherSports ?? const <OtherSport>[]) {
    if (s.sessionsPerWeek > 0) {
      out.add(
        reason(ReasonCodes.planConcurrentSport, <String, Object?>{
          'sport': s.kind.code,
          'sessions': s.sessionsPerWeek,
        }),
      );
    }
  }
  final special = profile.specialization;
  if (special != null) {
    out.add(
      reason(ReasonCodes.planSpecialization, <String, Object?>{
        'target':
            special.exerciseId ??
            special.muscle ??
            special.pattern?.code ??
            special.kind.code,
        'weeks': special.weeks ?? shape.weeks.length,
      }),
    );
  }
  if (assisted) {
    // (Les essais isolés de traction stricte ne s'écrivent que pour qui
    // n'en a pas encore une : `value` 108 pour un athlète qui en fait déjà
    // — CX, correction 1, panel `street_13` : règle de débutant servie à
    // une pratiquante à 6 tractions.)
    final strict = (a.reps[Ids.pull] ?? 0) >= 1;
    out.add(note(CoachNotes.bandChoice, strict ? 108 : 8));
  }
  if (a.limits.isEmpty) {
    out.add(note(CoachNotes.painGeneral, 6));
  }
  if (profile.bodyWeightGoal == BodyWeightGoal.lose) {
    // Perte de poids : le renforcement garde le muscle, la dépense vient
    // surtout de la marche (CALIBRAGE_CP1, A-21).
    out
      ..add(note(CoachNotes.walking, 30))
      ..add(note(CoachNotes.tracking, a.dayCount.toDouble()));
  }
  // R5-P23 : règle de douleur — continuer jusqu'à 3 sur 10, régresser à 4
  // ou 5, arrêter à 6.
  final seen = <BodyZone>{};
  for (final l in a.limits) {
    if (!seen.add(l.zone)) {
      continue;
    }
    final since = l.since;
    if (since != null) {
      out.add(
        reason(ReasonCodes.planConstraintHistory, <String, Object?>{
          'zone': l.zone.code,
          'since': since.code,
        }),
      );
    }
    out.add(
      reason(ReasonCodes.planPainRule, <String, Object?>{
        'zone': l.zone.code,
        'continueBelow': 3,
        'regressAt': 4,
        'stopAt': 6,
      }),
    );
  }
  // Plateau au dernier test d'un mouvement visé : le bloc change de
  // méthode, dit en clair avec la cible du prochain test (CX, correction 1).
  final flat = <String>[
    for (final id in a.stalled)
      if (a.aimsAt(id) && (a.reps[id] ?? 0) > 0) id,
  ]..sort();
  for (final id in flat) {
    out.add(note(CoachNotes.plateau, (a.reps[id] ?? 0).toDouble()));
  }
  // Douleur qui dure ou qui revient (CX, correction 1, sécurité) : arrêt
  // des mouvements provocants et consultation ; puis reprise graduée,
  // palier par palier, d'un bloc à l'autre.
  final zones = <BodyZone>[...a.stopZones]
    ..sort((x, y) => x.index.compareTo(y.index));
  for (final z in zones) {
    out.add(note(CoachNotes.painStop, z.index.toDouble()));
  }
  final back = a.returnSteps.keys.toList()
    ..sort((x, y) => x.index.compareTo(y.index));
  var loadedWeeks = 0;
  for (final w in shape.weeks) {
    if (w.kind == WeekKind.build || w.kind == WeekKind.intro) {
      loadedWeeks++;
    }
  }
  for (final z in back) {
    final start = a.returnSteps[z]!;
    var end = start + (loadedWeeks > 0 ? loadedWeeks - 1 : 0);
    if (end > 9) {
      end = 9;
    }
    out.add(
      note(CoachNotes.painReturn, (z.index * 100 + start * 10 + end) * 1.0),
    );
  }
  out.addAll(<Reason>[
    for (final r in skeleton.reasons)
      if (r.params['note'] != CoachNotes.skillHorizon) r,
  ]);
  return out;
}

/// Passe 2 du bloc [blockId] : [skeleton] dosé semaine par semaine, à la
/// suite des semaines [previous] du bloc précédent.
Pass2Plan prescribeBlock(
  Athlete a,
  Skeleton skeleton, {
  required String blockId,
  required int blockIndex,
  List<WeekPrescription> previous = const <WeekPrescription>[],
  List<WeekPrescription> kept = const <WeekPrescription>[],
  double volumeScale = 1,
}) {
  final prescriber = Prescriber(
    a,
    skeleton,
    blockIndex,
    volumeScale: volumeScale,
    kept: kept,
  )..seed(previous);
  return Pass2Plan(
    blockId: blockId,
    engineVersion: kalisPlanVersion,
    weeks: prescriber.build(),
    reasons: blockReasonsOf(a, skeleton),
  );
}

/// Séries dures par semaine de la passe 2 [weeks] (toutes séances), pour
/// les tests et l'inspecteur.
List<double> hardSetsByWeek(Catalog catalog, List<WeekPrescription> weeks) {
  final traits = CatalogTraits.of(catalog);
  final out = <double>[];
  for (final w in weeks) {
    var total = 0.0;
    for (final d in w.days) {
      for (final p in d.items) {
        final t = traits.find(p.exerciseId);
        final flames = p.targetFlames;
        if (t == null || !t.kind.isResistance || p.kind == SetKind.warmup) {
          continue;
        }
        if (flames != null &&
            Flames.isValid(flames) &&
            Flames.toRir(flames) > coachHardSetMaxRir) {
          continue;
        }
        total += p.sets;
      }
    }
    out.add(total);
  }
  return out;
}

/// Identifiants des mouvements piliers (pour l'inspecteur).
const List<String> coachPillars = <String>[
  Ids.weightedPull,
  Ids.weightedDip,
  Ids.weightedMuscleUp,
  Ids.squat,
  Ids.pull,
  Ids.dip,
  Ids.pushUp,
  Ids.muscleUp,
];
