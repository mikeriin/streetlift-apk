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
  /// la plage).
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

  /// Tous les codes.
  static const List<String> all = <String>[
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
    eventDay,
    recovery,
    calibrate,
    superset,
    easyPace,
    generalWarmup,
    toleranceVolume,
  ];
}

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

/// Hausse relative maximale du volume d'un groupe d'une semaine à l'autre
/// (R5-P22 : +10 à +20 %).
const double coachVolumeRise = 0.20;

/// Hausse des secondes de tenue bras tendus par semaine (R5-P22, R4-F10).
const List<double> coachStraightArmRise = <double>[0.20, 0.15, 0.10, 0.10];

/// Hausse maximale de la charge totale d'une semaine à l'autre à
/// répétitions égales (R5-P3, R5-P22).
const List<double> coachLoadRise = <double>[0.10, 0.05, 0.05, 0.05];

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
  _WeekTrace(this.light);

  final bool light;
  final List<double> groups = List<double>.filled(MuscleGroup.values.length, 0);
  final List<double> straightArm = <double>[0, 0, 0];
  double hard = 0;
  final Map<String, (double, int)> loads = <String, (double, int)>{};
}

/// Prescripteur d'un bloc.
final class Prescriber {
  /// Prescripteur du squelette [skeleton] pour l'athlète [a].
  Prescriber(this.a, this.skeleton, this.blockIndex, {this.volumeScale = 1});

  /// Facteur de volume du résumé d'adaptation (assiduité, fatigue).
  final double volumeScale;

  /// Athlète.
  final Athlete a;

  /// Squelette.
  final Skeleton skeleton;

  /// Rang du bloc.
  final int blockIndex;

  final List<_WeekTrace> _history = <_WeekTrace>[];

  /// Jours d'activation (J−2 d'une épreuve de répétitions) de la semaine
  /// en cours.
  final Set<int> _activation = <int>{};

  /// Premier jour de la semaine en cours de prescription.
  late CivilDate _today = a.start;

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

  /// RIR plancher de l'exercice [e] : mouvement à risque (R5-P27), zone à
  /// ménager (R5-P23), débutant (R5-P4), reprise (R5-P7).
  double _floorRir(CatalogExercise e, int week) {
    var floor = 0.0;
    if (coachHighRisk(e)) {
      floor = 2;
    }
    if (_level == 0 && floor < 2) {
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
      final weeks = a.gapWeeks >= 10 ? 4 : (a.gapWeeks >= 4 ? 2 : 1);
      if (week < weeks && floor < 3) {
        floor = 3;
      }
      if (week == 0 && a.gapWeeks >= 16 && floor < 4) {
        floor = 4;
      }
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
  double get _regain {
    final gap = a.gapWeeks;
    if (gap < 2) {
      return 1;
    }
    final base = gap < 4 ? 0.90 : (gap < 8 ? 0.82 : 0.75);
    final done = _history.length;
    if (done <= 5) {
      final value = base + (0.92 - base) * done / 5;
      return value > 1 ? 1 : value;
    }
    final value = 0.92 + 0.02 * (done - 5);
    return value > 1 ? 1 : value;
  }

  int _scaled(int sets, WeekSpec ws, {int min = 1}) {
    final n = _round(sets * ws.volume * volumeScale);
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
    final half = _stage(ws) ~/ 2;
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
        roles[d] = target.peak ? _DayRole.after : _DayRole.normal;
      } else if (target.peak) {
        // R3-P14 : dernière séance à J−3 ou J−4 avant une épreuve de force
        // (arrêt de 2 à 4 jours) ; R3-P21 : repos complet d'un à deux
        // jours avant une épreuve de répétitions.
        // (Épreuve de répétitions : à J−2, une activation courte et
        // facile ; repos complet la veille.)
        roles[d] = best - offset > 2 ? _DayRole.primerFar : _DayRole.primerNear;
        if (best - offset == 2 && _shape.model == SeasonModel.repsPeak) {
          _activation.add(d);
        }
      } else {
        // Test daté sans pic de forme : semaine allégée ordinaire, repos
        // la veille du test.
        roles[d] = best - offset >= 2 ? _DayRole.normal : _DayRole.primerNear;
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
    final total = _totalFor(e, referenceId);
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
    // Mouvement lesté dont la charge visée tombe sous le poids du corps :
    // la série se fait au poids du corps, à sa vraie part du 1RM, avec
    // moins de répétitions (formule d'Epley) pour garder la réserve.
    final floor = (e.bodyweightFraction?.value ?? 0) * a.bodyWeight / total;
    if (floor > 0 && p < floor - 1e-9) {
      p = floor;
      final possible = (30 * (1 / p - 1)).floor();
      final high = x.repsHigh;
      final reserve = (x.rir ?? 3).ceil();
      if (high != null) {
        final reps = _clampInt(possible - reserve, 1, high);
        x
          ..repsLow = reps
          ..repsHigh = reps;
      }
      x.reasons.add(_note(CoachNotes.bodyweightFloor, p));
    }
    if (p > 1) {
      // Amplitude partielle surchargée : au-dessus du 1RM complet.
      x
        ..load = _external(e, total, p)
        ..reasons.add(_note(CoachNotes.overload, p));
      return;
    }
    x
      ..load = _external(e, total, p)
      ..reasons.add(
        reason(ReasonCodes.planPercentBased, <String, Object?>{
          'pct': _round3(p),
        }),
      );
    final own = a.totalOneRm(e.id) != null;
    if (own) {
      x
        ..percent = _round3(p)
        ..intensity = IntensityTarget(
          basis: IntensityBasis.percentOneRm,
          value: _round3(p),
        );
    } else {
      x.intensity = IntensityTarget(
        basis: IntensityBasis.percentOneRm,
        value: _round3(p),
        referenceExerciseId: referenceId,
      );
    }
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
    x
      ..sets = sets
      ..minSets = 2
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = _rirOf(x.e, rir, ws, week)
      ..rest = _level >= 2 ? 240 : 180
      ..ramped = true;
    _loadAt(x, pct, x.slot?.referenceId);
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
        ..backoffRepsLow = reps
        ..backoffRepsHigh = reps
        ..backoffDrop = lighter
        ..reasons.add(_note(CoachNotes.topSetBackoff, lighter * 100));
    }
    x.reasons.add(_note(CoachNotes.rampWarmup, 3));
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
    if (role == _DayRole.primerFar && !maintain) {
      // R3-P13 : dernier rappel lourd et court, 3 à 5 jours avant.
      _topSet(
        x,
        sets: 2,
        reps: 1,
        pct: 0.88,
        rir: 3,
        drop: 0.10,
        ws: ws,
        week: week,
      );
      x
        ..backoffRepsLow = 2
        ..backoffRepsHigh = 2
        ..reasons.add(_note(CoachNotes.opener, 0.88));
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
          ..rir = 5
          ..rest = 120
          ..reasons.add(_note(CoachNotes.maintenance, 2));
        _loadAt(x, 0.72, s.referenceId);
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
          drop: 0.10,
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
          drop: 0.10,
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
        _topSet(
          x,
          sets: _scaled(base, ws, min: 2),
          reps: 3,
          pct: pct,
          rir: ease > 0 ? 3 : 2,
          drop: 0.10,
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
        _topSet(
          x,
          sets: _scaled(base, ws, min: 2),
          reps: single ? 1 : 2,
          pct: heavy - ease,
          rir: single ? 1 : 2,
          drop: 0.15,
          ws: ws,
          week: week,
        );
        x
          ..backoffRepsLow = 2
          ..backoffRepsHigh = 2;
      case WeekIntent.taper:
        // R3-P12, P13 : volume −40 à −60 %, intensité gardée.
        _topSet(
          x,
          sets: 3,
          reps: 1,
          pct: 0.90,
          rir: 2,
          drop: 0.10,
          ws: ws,
          week: week,
        );
        x
          ..backoffRepsLow = 2
          ..backoffRepsHigh = 2;
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
          ..repsLow = reps
          ..repsHigh = reps
          ..rir = _rirOf(x.e, 4, ws, week)
          ..rest = 180;
        _loadAt(x, pct, s.referenceId);
    }
    return x;
  }

  _Draft? _liftVolume(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.primerNear) {
      return null;
    }
    final x = _new(s);
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
        if (pct > 0.78) {
          pct = 0.78;
        }
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
        reps = 3;
        pct = 0.80;
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
      reps = 3;
      pct = 0.78;
      sets = 2;
      rir = 4;
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
    x
      ..sets = ws.light ? 2 : s.sets
      ..minSets = 2
      ..repsLow = 3
      ..repsHigh = 3
      ..rir = 5
      ..rest = 120
      ..reasons.add(_note(CoachNotes.speedWork, pct));
    _loadAt(x, pct, s.referenceId);
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
    // Amplitude partielle (verrouillage) : surcharge au-dessus du 1RM
    // complet — 100 à 110 % (pratique de terrain, CALIBRAGE_CP1 C) ; les
    // autres variantes restent sous le mouvement de compétition.
    var pct = partial
        ? 1.0 + 0.02 * stage
        : (intense ? 0.74 : 0.70) + 0.01 * stage;
    if (pct > (partial ? 1.10 : 0.80)) {
      pct = partial ? 1.10 : 0.80;
    }
    if (ws.light) {
      pct -= partial ? 0.10 : 0.05;
    }
    final reps = intense ? 3 : 4;
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
    return x;
  }

  // ------------------------------------------------------------ répétitions

  /// Maximum de répétitions qui règle l'emplacement [s] : le record,
  /// ramené à ce que la reprise permet après une coupure.
  int _maxOf(SlotSpec s) {
    final own = a.reps[s.exerciseId];
    if (own == null) {
      return 0;
    }
    if (a.gapWeeks < 2) {
      // Trajectoire prévue vers l'objectif (ou progression plausible du
      // niveau) : le repère de la semaine monte avec le plan, chaque test
      // le recale.
      final gain = a.plannedGain(s.exerciseId, GoalMetric.maxReps, own, _today);
      return (own * (1 + gain) + 1e-9).floor();
    }
    final regained = (own * _regain).floor();
    return regained < 1 ? 1 : regained;
  }

  /// Maintien maximal prévu de l'exercice [id] la semaine en cours, ou 0.
  int _holdOf(String id) {
    final own = a.holds[id] ?? 0;
    if (own <= 0) {
      return 0;
    }
    final gain = a.plannedGain(id, GoalMetric.maxHoldSeconds, own, _today);
    return (own * (1 + gain) + 1e-9).floor();
  }

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
    final realization = ws.intent == WeekIntent.realization;
    var margin = realization ? 1 : 3 - (stage > 2 ? 2 : stage);
    if (ws.intent == WeekIntent.intro) {
      margin = 4;
    }
    if (ws.intent == WeekIntent.taper) {
      // R3-P13 : à l'affûtage, l'intensité reste, les séries tombent.
      margin = 2;
    }
    final floor = risk || _level == 0 ? 2 : 1;
    if (margin < floor) {
      margin = floor;
    }
    final bonus = a.rirBonus.round();
    final top = _clampInt(max - margin - bonus, 1, max);
    final back = _clampInt(_round(max * 0.65), 1, top);
    final sets = ws.intent == WeekIntent.taper
        ? 2
        : _scaled(s.sets, ws, min: 2);
    x
      ..sets = sets
      ..minSets = 2
      ..repsLow = top
      ..repsHigh = top
      ..rir = _rirOf(e, (max - top).toDouble() - a.rirBonus, ws, week)
      ..rest = 180
      ..backoff = true
      ..backoffRepsLow = back
      ..backoffRepsHigh = back
      ..intensity = _shareOf(e.id, top, max)
      ..reasons.add(_note(CoachNotes.rampBodyweight, 2))
      ..reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
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
      return x;
    }
    // R4-G4 : volume sous-maximal à 50 à 70 % du maximum, 3 répétitions en
    // réserve au moins.
    var share = (max >= 12 ? 0.60 : 0.55) + 0.03 * stage;
    if (share > 0.70) {
      share = 0.70;
    }
    if (ws.light || role == _DayRole.primerFar) {
      share = 0.5;
    }
    final reps = _clampInt(_round(max * share), 1, max);
    x
      ..repsLow = reps
      ..repsHigh = reps
      // R4-G3, R4-G4 : 3 répétitions en réserve au moins. Sous douze
      // répétitions de maximum, la réserve se lit dès la première série ;
      // au-delà, les séries longues à repos court se cumulent et c'est sur
      // les dernières séries que la réserve tombe à 3 ou 4.
      ..rir = _rirOf(
        e,
        max >= 12
            ? 3
            : ((max - reps - 1) < 3 ? 3 : (max - reps - 1).toDouble()),
        ws,
        week,
      )
      ..intensity = _shareOf(e.id, reps, max);
    if (ws.kind == WeekKind.build) {
      x.reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
    }
    return x;
  }

  _Draft? _repsDensity(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if ((role != _DayRole.normal && role != _DayRole.primerFar) ||
        ws.intent == WeekIntent.transition) {
      return null;
    }
    final max = _maxOf(s);
    if (max < 5) {
      return _repsVolume(s, ws, week, role);
    }
    final x = _new(s);
    final e = x.e;
    // R4-G6 : densité — départs au chrono à 30 à 50 % du maximum (40 %
    // chez l'intermédiaire, 40 à 50 % ensuite) ; on ajoute des séries
    // avant d'ajouter des répétitions.
    final stage = _stage(ws);
    var share = _level >= 2 ? 0.45 : 0.40;
    if (coachHighRisk(e)) {
      share = 0.30;
    }
    final reps = _clampInt(_round(max * share), 1, max);
    // R5-P22 : +10 à 20 % par semaine au plus — un départ de plus toutes
    // les deux semaines de charge (toutes les trois à 40 ans et plus), deux
    // au plus dans le bloc ; aucun tant que le profil gèle le volume.
    var minutes = s.sets;
    if (ws.kind == WeekKind.build) {
      final step = a.freezeVolume ? 0 : (a.slowRamp ? stage ~/ 3 : stage ~/ 2);
      minutes += step > 2 ? 2 : step;
    } else if (ws.kind == WeekKind.intro) {
      minutes -= 1;
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
      _loadAt(x, 0.78, s.referenceId);
      if (!x.calibrate) {
        x.reasons.add(_rule(CoachRules.loadStep, 1.5, 'pct'));
      }
      return x;
    }
    if (max > 0) {
      // R4-G2 : sous 8 répétitions, la force d'abord — séries courtes à 2
      // répétitions de l'échec.
      final margin = 2 + (ws.light ? 1 : 0) + a.rirBonus.round();
      final reps = _clampInt(max - margin, 1, max);
      x
        ..repsLow = reps
        ..repsHigh = reps
        ..rir = _rirOf(e, (max - reps).toDouble() - a.rirBonus, ws, week)
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
    x
      ..repsLow = high - 2 < 3 ? 3 : high - 2
      ..repsHigh = high
      ..rir = _rirOf(e, 2, ws, week)
      ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
    return x;
  }

  _Draft? _repsTechnique(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    if (role == _DayRole.primerNear || role == _DayRole.after) {
      return null;
    }
    final x = _new(s);
    final e = x.e;
    final max = _maxOf(s);
    // R4-F1, R5-P27 : technique à l'état frais, séries très courtes, 2
    // répétitions en réserve au moins, arrêt dès que la qualité baisse.
    final reps = max <= 3 ? 1 : (max <= 5 ? 2 : _round(max * 0.5));
    final sets = _scaled(s.sets + (max <= 3 ? 1 : 0), ws, min: 2);
    x
      ..sets = sets
      ..minSets = 3
      ..repsLow = reps
      ..repsHigh = reps
      // La réserve écrite est la vraie : maximum moins répétitions.
      ..rir = _rirOf(e, max <= 0 ? 3 : (max - reps).toDouble(), ws, week)
      ..rest = 150
      ..practice = true
      ..reasons.add(_note(CoachNotes.qualityFirst, 4));
    if (max > 0) {
      x.intensity = _shareOf(e.id, reps, max);
    }
    return x;
  }

  // --------------------------------------------------------------- débutant

  _Draft? _beginnerMain(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    final e = x.e;
    final sets = _scaled(s.sets, ws, min: s.sets >= 3 ? 2 : 1);
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
    if (max >= 1 && max < 4) {
      // Geste tout juste acquis : séries très courtes et nombreuses, une
      // répétition sous le maximum (spécificité du geste complet).
      x
        ..sets = sets + 1
        ..repsLow = max - 2 < 1 ? 1 : max - 2
        ..repsHigh = max - 2 < 1 ? 1 : max - 2
        ..rir = _rirOf(e, 2, ws, week)
        ..reasons.add(_rule(CoachRules.repStep, 1, 'reps'));
      return x;
    }
    if (max >= 4) {
      // R5-P2, R5-P4 : 50 à 70 % du maximum, 3 répétitions en réserve.
      // 50 à 70 % du maximum, sans jamais dépasser le maximum moins trois
      // (la réserve demandée doit exister).
      final shift = _shift(ws);
      final top = max - 3 < 1 ? 1 : max - 3;
      final high = _clampInt(_round(max * 0.7) + shift, 1, top);
      final low = _clampInt(_round(max * 0.5) + shift, 1, high);
      x
        ..repsLow = low
        ..repsHigh = high
        // 3 en réserve le premier bloc (R5-P4), 2 ensuite.
        ..rir = _rirOf(e, firm, ws, week)
        ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
      return x;
    }
    // R5-P9 : une variante qui permet 6 à 10 répétitions avec 3 en réserve.
    if (e.assisted) {
      x.reasons.add(_rule(CoachRules.assistanceStep, 1, 'cran'));
    }
    final lower =
        e.family == MovementFamily.jambesGenou ||
        e.family == MovementFamily.jambesHanche;
    x
      ..repsLow = (lower ? 8 : 6) + _shift(ws)
      ..repsHigh = (lower ? 10 : 8) + _shift(ws)
      ..rir = _rirOf(e, 3, ws, week)
      ..reasons.add(_rule(CoachRules.doubleProgression, 1, 'reps'));
    return x;
  }

  _Draft? _beginnerNegative(SlotSpec s, WeekSpec ws, int week, _DayRole role) {
    final x = _new(s);
    // R5-P10 : descentes freinées de 3 à 5 s, peu de répétitions, jamais
    // jusqu'à la perte de contrôle.
    // (R5-P8 : 2 à 3 × 2 à 3, puis 3 × 5 de 5 s ; 15 excentriques par
    // séance au plus.)
    final stage = _stage(ws);
    final seconds = stage >= 3 ? 5 : 4;
    final reps = ws.light ? 2 : (stage >= 6 ? 5 : (stage >= 4 ? 4 : 3));
    x
      ..sets = ws.light ? 2 : (stage >= 3 ? 3 : s.sets)
      ..minSets = 1
      ..repsLow = reps
      ..repsHigh = reps
      ..rir = _rirOf(x.e, 3, ws, week)
      ..rest = 120
      ..tempo = Tempo(
        eccentricSeconds: seconds,
        bottomPauseSeconds: 0,
        concentricSeconds: 0,
        topPauseSeconds: 0,
      )
      ..reasons.add(_note(CoachNotes.slowNegative, seconds));
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
    // R4-F6 : 50 à 70 % du maintien maximal — la part monte au fil des
    // semaines de charge du bloc (de la valeur de départ à 70 %), sur un
    // maintien maximal qui suit lui-même la trajectoire prévue.
    var part = share;
    if (ws.kind == WeekKind.build && known > 0) {
      part = share - 0.05 + 0.04 * stage;
      if (part > 0.70) {
        part = 0.70;
      }
    }
    var hold = known > 0 ? _round(known * part) : fallback;
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
      if (s.method == Method.skillHold && paired) {
        sets = ws.light ? 2 : 3;
      } else {
        final part = paired ? 0.75 : 1.0;
        final wanted = cumulative[_level] * part * ws.volume * volumeScale;
        sets = _clampInt(_round(wanted / hold), 2, 6);
      }
      // Séance légère de la figure (pratique distribuée, R4-F1) : trois
      // tenues au plus.
      if (s.stress == DayStress.light && sets > 3) {
        sets = 3;
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
      // R1-P16 : 2 à 5 min de repos complet sur les isométries dures.
      ..rest = _level >= 2 ? 180 : 150
      ..calibrate = known <= 0
      ..reasons.add(_note(CoachNotes.submaximalHold, part))
      ..reasons.add(_rule(CoachRules.holdStep, 1, 's'));
    if (known > 0) {
      x.intensity = IntensityTarget(
        basis: IntensityBasis.percentBenchmark,
        value: _round3(hold / known > 1 ? 1 : hold / known),
        referenceExerciseId: e.id,
        referenceKind: BenchmarkKind.maxHold,
      );
    } else {
      x.reasons.add(reason(ReasonCodes.planToCalibrate));
    }
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
    final hold = _clampInt(known > 0 ? _round(known * 0.5) : 15, 8, 45);
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
    if (sharpening && (method == Method.accessoryIsolation || s.support)) {
      // R3-P13 : à l'affûtage, on coupe d'abord les accessoires.
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
    // Jamais une série isolée d'assistance : deux, ou rien.
    x
      ..sets = sets < 2 ? 2 : sets
      ..minSets = 2;
    final stage = _stage(ws);
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
          ..rir = _rirOf(e, 2, ws, week)
          ..rest = 75;
      case Method.accessoryCore:
        x
          ..repsLow = 8
          ..repsHigh = 12
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
    _roleNote(x);
    return x;
  }

  /// Note de rôle d'un exercice d'assistance (pourquoi il est là).
  void _roleNote(_Draft x) {
    final e = x.e;
    String? note;
    if (x.method == Method.accessoryPrehab) {
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
      final reps = 3 + (stage ~/ 2 > 2 ? 2 : stage ~/ 2);
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
    if (s.method == Method.runQuality && role == _DayRole.normal) {
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
      x
        ..sets = reps
        ..rir = 2
        ..restMode = RestMode.jog;
      final five = a.runTimeOn(5000);
      if (meters > 0 && five != null) {
        x.reasons.add(_note(CoachNotes.intervalPace, five / 5000 * meters));
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
      final known = a.holds[e.id] ?? 0;
      kind = TestKind.maxHold;
      x
        ..sets = 1
        ..secondsLow = known > 0 ? known : 5
        ..secondsHigh = known > 0 ? known + 5 : 15
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
      if (event && _level >= 1) {
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
          ..load = _external(e, total, 0.88)
          ..percent = 0.88
          ..intensity = const IntensityTarget(
            basis: IntensityBasis.percentOneRm,
            value: 0.88,
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
          : _maxOf(SlotSpec(exerciseId: e.id, role: SlotRole.main, method: ''));
      final goal = a.goalOn(e.id, GoalMetric.maxReps)?.targetValue;
      kind = TestKind.maxReps;
      x
        ..sets = 1
        ..repsLow = max > 0 ? max : 1
        ..repsHigh = max > 0
            ? max + 2
            : (goal != null && goal >= 1 ? goal.round() : 3)
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
    final marker = _checkpoint(e, ws);
    if (marker != null) {
      x.reasons.add(_note(CoachNotes.checkpoint, marker));
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
      // une figure jamais entraînée.
      for (final d in skeleton.days) {
        for (final s in d.slots) {
          if (s.skillTargetId == id && s.method == Method.skillHold) {
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
      return unit == MeasureUnit.distance || unit == MeasureUnit.calories;
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
    if (_shape.model == SeasonModel.repsPeak &&
        ws.intent == WeekIntent.realization &&
        role == _DayRole.normal &&
        (s.method == Method.repsDensity || s.method == Method.repsVolume) &&
        // R4-G7 : une simulation toutes les deux semaines chez l'avancé,
        // chaque semaine en élite ; aucune dans les 7 à 10 derniers jours.
        (_level >= 3 || ws.stage.isEven) &&
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
      x?.reasons.add(_note(CoachNotes.eventRehearsal, 300));
      x?.rest = 300;
      return x;
    }
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
          high: chin ? 15 : 30,
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
          high: 25,
          fallback: 10,
        );
      case Method.skillAttempt || Method.skillDynamic:
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
    } else if (e.pattern == MovementPattern.tirageVertical) {
      code = 1;
    } else if (root == Ids.dip || root == Ids.weightedDip) {
      code = 2;
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
  bool _blockTests(WeekSpec ws) => ws.testWeek && !ws.eventWeek;

  /// Vrai si l'emplacement principal [s] est testé la semaine [ws] : les
  /// mouvements de l'objectif d'abord ; en semaine d'allègement, deux tests
  /// au plus (un seul sans objectif), pour que l'allègement en reste un ;
  /// jamais une variante sans record (son repère n'aurait pas de sens).
  bool _testable(SlotSpec s, WeekSpec ws, Set<String> tested) {
    final e = a.catalog.find(s.exerciseId);
    if (e == null) {
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
    if (anyAimed && !aimed(s)) {
      return false;
    }
    if (ws.intent == WeekIntent.test) {
      return true;
    }
    return tested.length < (anyAimed ? 2 : 1);
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
          week >= s.fromWeek &&
          week <= s.untilWeek &&
          _testable(s, ws, tested) &&
          tested.add(s.exerciseId)) {
        // Fin de bloc : le test remplace le travail du mouvement principal
        // (R3-P16) ; il mesure le progrès et règle le bloc suivant.
        final e = a.catalog.exercise(s.exerciseId);
        // Débutant sans répétition acquise : pas de test maximal.
        final skip =
            _level == 0 &&
            e.unit != MeasureUnit.seconds &&
            (a.reps[e.id] ?? 0) <= 0;
        if (!skip) {
          out.add(_testOf(s.slotId, s, e, ws, event: false)..group = null);
          continue;
        }
        // Chemin vers la première traction : le test est la descente la
        // plus lente possible ; dix secondes tenues ouvrent l'essai strict
        // (R5-P8).
        const negative = 'sw-traction-negative';
        if (s.referenceId == Ids.pull &&
            !a.heavyImpactBanned &&
            a.rejection(negative, day) == null) {
          final n = a.catalog.exercise(negative);
          final gate = _Draft(s, s.slotId, n, a.traits.of(negative))
            ..method = s.method
            ..kind = SetKind.test
            ..fixed = true
            ..sets = 2
            ..secondsLow = 5
            ..secondsHigh = 10
            ..rest = 180
            ..stress = DayStress.heavy
            ..reasons.add(_note(CoachNotes.negativeGate, 10));
          gate.test = const TestSpec(
            kind: TestKind.maxHold,
            targetRir: 1,
            attempts: 2,
          );
          out.add(gate);
          gated = true;
          // Objectif de traction : en semaine de test, l'essai strict suit
          // la descente dans la même épreuve (le geste non acquis n'est pas
          // prescrit comme un exercice : c'est un essai, écrit en note).
          if (a.aimsAt(Ids.pull) && ws.intent == WeekIntent.test) {
            final goal = a.goalOn(Ids.pull, GoalMetric.maxReps)?.targetValue;
            gate.reasons.add(_note(CoachNotes.strictAttempt, goal ?? 1));
          }
          continue;
        }
      }
      if (gated && s.exerciseId == 'sw-traction-negative') {
        continue;
      }
      final x = _draft(s, day, week, ws, role);
      if (x != null) {
        _cue(x);
        out.add(x);
      }
    }
    if (role == _DayRole.event) {
      var k = 0;
      for (final id in _eventExercises()) {
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
        final offset = target == null
            ? 0
            : a.start.daysUntil(target.date) - 7 * week - _dayOffset(day);
        out.add(
          _testOf(slotId, own, e, ws, event: true)
            ..group = null
            ..reasons.add(_note(CoachNotes.eventDay, offset)),
        );
      }
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
  bool _trim(List<List<_Draft>> days, {MuscleGroup? g, int family = -1}) {
    _Draft? pick;
    List<_Draft>? home;
    final beginner = _level == 0;
    for (final items in days) {
      for (final x in items) {
        if (x.kind == SetKind.test) {
          continue;
        }
        final counts = g != null
            ? x.creditOf(g) > 0
            : (straightArmFamilyOf(x.e) == family && x.holdSeconds > 0);
        if (!counts) {
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
        if (current == null ||
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
            )) {
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
    final rise = a.slowRamp ? coachVolumeRise / 2 : coachVolumeRise;
    final tolerance = a.slowRamp ? 1.0 : 2.0;
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
    final limit = peak * (ws.eventWeek ? 0.55 : 0.65);
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

  /// Plancher de la semaine de l'échéance, avant les garde-fous de volume
  /// (qui gardent le dernier mot).
  void _floorEvent(List<List<_Draft>> days, WeekSpec ws) {
    if (!ws.eventWeek) {
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
    final floor = peak * 0.36;
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
              x.sets >= 3 ||
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

  /// Borne la hausse de charge d'une semaine à l'autre à répétitions
  /// égales (R5-P3, R5-P22).
  void _fitLoads(List<List<_Draft>> days, _WeekTrace trace) {
    final previous = _history.isEmpty ? null : _history.last;
    final rise = coachLoadRise[_level];
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
        final before = previous?.loads[key];
        if (before != null &&
            x.kind != SetKind.test &&
            before.$2 == reps &&
            before.$1 > 0 &&
            total > before.$1 * (1 + rise) + 1e-9) {
          final capped = _external(x.e, before.$1 * (1 + rise), 1);
          if (capped != null && capped < load) {
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
        }
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
    for (final w in weeks) {
      final trace = _WeekTrace(
        w.kind == WeekKind.intro ||
            w.kind == WeekKind.deload ||
            w.kind == WeekKind.test,
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
          final load = p.startLoadKg;
          final reps = p.repsHigh;
          if (load != null && reps != null && p.kind != SetKind.test) {
            final fraction = t.exercise.bodyweightFraction?.value ?? 0;
            trace.loads['${d.dayIndex}|${p.slotId}|${p.exerciseId}'] = (
              load + fraction * a.bodyWeight,
              reps,
            );
          }
        }
      }
      _history.add(trace);
    }
  }

  /// Semaines du bloc.
  List<WeekPrescription> build() {
    final out = <WeekPrescription>[];
    for (var w = 0; w < _shape.weeks.length; w++) {
      final ws = _shape.weeks[w];
      _today = a.start.addDays(7 * w);
      final roles = _roles(w, ws);
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
      _fitVolume(days, ws);
      _fitTaper(days, ws);
      days.forEach(_equalize);
      final trace = _WeekTrace(ws.light);
      _fitLoads(days, trace);
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
                'volumeFactor': _round2(ws.volume),
                'daysToEvent': left * 7,
              }),
            );
          }
          break;
        }
      }
      _history.add(trace);
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
    reason(ReasonCodes.planCoachNote, <String, Object?>{
      'note': CoachNotes.generalWarmup,
      'value': coachWarmupSeconds / 60,
    }),
  ];
  Reason note(String code, double value) => reason(
    ReasonCodes.planCoachNote,
    <String, Object?>{'note': code, 'value': value},
  );
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
    ..add(note(CoachNotes.missed, 20))
    ..add(note(CoachNotes.testUse, 0))
    ..add(note(CoachNotes.testRest, 48));
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
      out.add(note(CoachNotes.reentryTest, 3));
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
    out.add(note(CoachNotes.bandChoice, 8));
  }
  if (a.limits.isEmpty) {
    out.add(note(CoachNotes.painGeneral, 6));
  }
  if (profile.bodyWeightGoal == BodyWeightGoal.lose) {
    // Perte de poids : le renforcement garde le muscle, la dépense vient
    // surtout de la marche (CALIBRAGE_CP1, A-21).
    out.add(note(CoachNotes.walking, 30));
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
  out.addAll(skeleton.reasons);
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
  double volumeScale = 1,
}) {
  final prescriber = Prescriber(
    a,
    skeleton,
    blockIndex,
    volumeScale: volumeScale,
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
