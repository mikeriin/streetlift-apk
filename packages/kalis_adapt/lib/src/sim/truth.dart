/// Athlète simulé à vérité connue : capacités vraies, courbe répétitions ↔
/// charge propre, forme du jour, fatigue, erreur de report du RIR, notes
/// paresseuses, absences, maladie, douleur, changement de lieu.
///
/// Le modèle de vérité est **volontairement différent** du modèle du
/// moteur (courbe exponentielle et non hyperbolique, fatigue à d'autres
/// constantes, biais de note individuel) : le moteur n'est pas jugé sur
/// ses propres hypothèses. Voir `docs/VALIDATION.md`.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show MuscleGroup;

import '../book.dart';
import '../filter.dart';
import '../numeric.dart';
import 'rng.dart';

/// Physiologie et comportement d'un athlète simulé.
final class AthleteSpec {
  /// Athlète.
  const AthleteSpec({
    required this.key,
    required this.profileKey,
    required this.level,
    required this.weeklyGain,
    this.ratingNoise = 1,
    this.rirBias = 0.25,
    this.rirBiasSd = 0.18,
    this.lazy = 0.1,
    this.skipRating = 0,
    this.missRate = 0.08,
    this.breakFromDay,
    this.breakDays = 0,
    this.illnessFromDay,
    this.illnessDays = 0,
    this.painZone,
    this.painFromDay,
    this.painDays = 0,
    this.painIntensity = 5,
    this.otherPlace,
    this.otherPlaceFromDay,
    this.otherPlaceDays = 0,
    this.daySd = 0.025,
    this.healthAnswerRate = 0.7,
    this.shortTimeRate = 0.05,
  });

  /// Clé du profil d'athlète simulé.
  final String key;

  /// Clé du profil type de kalis_core.
  final String profileKey;

  /// Niveau (0 débutant … 3 élite) de la vérité.
  final int level;

  /// Gain hebdomadaire de base (`ln` capacité), à dose pleine.
  final double weeklyGain;

  /// Multiplicateur du bruit de perception du RIR.
  final double ratingNoise;

  /// Biais moyen de report : RIR réel = RIR perçu × (1 + biais).
  final double rirBias;

  /// Écart-type du biais entre personnes.
  final double rirBiasSd;

  /// Probabilité de confirmer la note pré-remplie sans y penser.
  final double lazy;

  /// Probabilité de ne pas noter une série.
  final double skipRating;

  /// Probabilité de manquer une séance.
  final double missRate;

  /// Début d'une coupure (jour depuis le début), ou `null`.
  final int? breakFromDay;

  /// Durée de la coupure, en jours.
  final int breakDays;

  /// Début d'une maladie, ou `null`.
  final int? illnessFromDay;

  /// Durée de la maladie, en jours.
  final int illnessDays;

  /// Zone d'un épisode de douleur, ou `null`.
  final BodyZone? painZone;

  /// Début de l'épisode.
  final int? painFromDay;

  /// Durée de l'épisode, en jours.
  final int painDays;

  /// Intensité de la douleur, sur 10.
  final int painIntensity;

  /// Autre lieu d'entraînement pendant une période, ou `null`.
  final Place? otherPlace;

  /// Début de la période dans l'autre lieu.
  final int? otherPlaceFromDay;

  /// Durée de la période, en jours.
  final int otherPlaceDays;

  /// Écart-type de l'effet de jour.
  final double daySd;

  /// Part des séances avec un bilan santé rempli.
  final double healthAnswerRate;

  /// Part des séances où le temps manque.
  final double shortTimeRate;
}

/// Vérité d'un exercice pour un athlète.
final class TruthExercise {
  /// Vérité de l'exercice [info].
  TruthExercise(this.info, this.mode);

  /// Exercice.
  final ExerciseInfo info;

  /// Mode de capacité.
  final CapacityMode mode;

  /// Capacité vraie : 1RM de charge totale, répétitions ou secondes max.
  double capacity = 0;

  /// Capacité au début de la simulation.
  double startCapacity = 0;

  /// Asymptote de la courbe répétitions ↔ charge.
  double curveA = 0.3;

  /// Vitesse de la courbe.
  double curveB = 0.044;

  /// Échelle individuelle de la fatigue intra-séance.
  double fatigueScale = 1;

  /// Part de la tenue maximale que vaut une répétition en réserve.
  double holdShare = 0.1;

  /// Effet de jour de la séance en cours.
  double day = 0;

  /// Pertes relatives laissées par les séries de la séance.
  List<double> setFatigue = <double>[];

  /// Stimulus de la semaine.
  double stimulus = 0;

  /// Jour de la dernière série.
  int? lastDay;

  /// Charge externe de la séance précédente.
  double? lastLoad;

  /// Charge externe la plus haute de la séance en cours.
  double? sessionLoad;

  /// Séances faites.
  int sessions = 0;

  /// Jour de la première séance.
  int? firstDay;

  /// Capacité à la première séance.
  double firstCapacity = 0;

  /// Capacité à la dernière séance.
  double lastCapacity = 0;

  /// Part du 1RM soulevable [n] fois.
  double share(double n) => curveA + (1 - curveA) * exp(-curveB * (n - 1));

  /// Répétitions possibles à la part [share] du 1RM.
  double repsAtShare(double share) {
    if (share >= 1) {
      return 1 - (share - 1) * 20;
    }
    if (share <= curveA + 1e-6) {
      return 100;
    }
    final n = 1 - ln((share - curveA) / (1 - curveA)) / curveB;
    return n > 100 ? 100 : n;
  }

  /// Perte relative de capacité de la série à venir.
  double fatigueNow() {
    var total = 0.0;
    final n = setFatigue.length;
    for (var i = 0; i < n; i++) {
      total += setFatigue[i] * exp((n - 1 - i) / 2 * ln(0.5));
    }
    return total > 0.8 ? 0.8 : total;
  }
}

/// Résultat d'une série simulée.
final class SetOutcome {
  /// Série.
  const SetOutcome({
    required this.amount,
    required this.flames,
    required this.trueRir,
    required this.failed,
  });

  /// Répétitions ou secondes faites.
  final int amount;

  /// Note donnée, ou `null`.
  final int? flames;

  /// Répétitions réellement en réserve à la fin de la série.
  final double trueRir;

  /// Série manquée (échec).
  final bool failed;
}

const List<double> _levelScale = <double>[0.62, 1.0, 1.3, 1.5];
const List<double> _levelAbility = <double>[3, 5, 7, 9];
const List<double> _weeksTrained = <double>[8, 60, 200, 400];

/// Rapport du 1RM de charge totale au poids du corps, niveau
/// intermédiaire (ordre de grandeur pour la simulation seulement).
double _ratioOf(CatalogExercise e) {
  final t = e.loadType;
  double pick(double barbell, double dumbbell, double machine, double cable) {
    switch (t) {
      case LoadType.barbell:
        return barbell;
      case LoadType.dumbbells:
      case LoadType.kettlebell:
        return dumbbell;
      case LoadType.machine:
        return machine;
      case LoadType.cable:
        return cable;
      case LoadType.addedWeight:
      case LoadType.other:
      case LoadType.none:
      case LoadType.bodyweight:
      case LoadType.band:
        return barbell;
    }
  }

  switch (e.pattern) {
    case MovementPattern.squat:
      return pick(1.25, 0.35, 2.2, 1.0);
    case MovementPattern.charniereHanche:
      return pick(1.5, 0.42, 1.0, 0.8);
    case MovementPattern.fente:
      return t == LoadType.addedWeight ? 1.25 : pick(0.8, 0.25, 0.8, 0.5);
    case MovementPattern.pousseeHorizontale:
      return t == LoadType.addedWeight ? 1.15 : pick(1.0, 0.38, 0.9, 0.5);
    case MovementPattern.pousseeInclinee:
      return pick(0.85, 0.33, 0.8, 0.45);
    case MovementPattern.pousseeVerticaleHaute:
      return pick(0.65, 0.25, 0.6, 0.35);
    case MovementPattern.pousseeVerticaleBasse:
      return t == LoadType.addedWeight ? 1.6 : 1.0;
    case MovementPattern.tirageVertical:
      return t == LoadType.addedWeight ? 1.45 : 0.9;
    case MovementPattern.tirageHorizontal:
      return t == LoadType.addedWeight ? 1.2 : pick(0.9, 0.40, 0.9, 0.8);
    case MovementPattern.transitionMuscleUp:
      return 1.15;
    case MovementPattern.isolationBiceps:
      return pick(0.45, 0.20, 0.4, 0.35);
    case MovementPattern.isolationTriceps:
      return pick(0.40, 0.15, 0.4, 0.35);
    case MovementPattern.isolationEpaules:
      return pick(0.3, 0.12, 0.4, 0.12);
    case MovementPattern.isolationPectoraux:
      return pick(0.5, 0.2, 0.6, 0.25);
    case MovementPattern.isolationDos:
      return pick(0.5, 0.25, 0.6, 0.4);
    case MovementPattern.isolationTrapezes:
      return pick(1.0, 0.4, 0.8, 0.6);
    case MovementPattern.extensionGenou:
      return 0.8;
    case MovementPattern.flexionGenou:
      return 0.6;
    case MovementPattern.mollets:
      return pick(1.2, 0.4, 1.5, 0.8);
    case MovementPattern.extensionHanche:
      return pick(1.4, 0.4, 0.8, 0.5);
    case MovementPattern.adducteursAbducteurs:
      return 0.8;
    case MovementPattern.halterophilie:
      return pick(0.8, 0.3, 0.6, 0.4);
    case MovementPattern.autoMassage:
    case MovementPattern.balistique:
    case MovementPattern.cardioContinu:
    case MovementPattern.cardioFractionne:
    case MovementPattern.compression:
    case MovementPattern.conditionnement:
    case MovementPattern.cordeASauter:
    case MovementPattern.cou:
    case MovementPattern.equilibreMains:
    case MovementPattern.etirementDynamique:
    case MovementPattern.etirementStatique:
    case MovementPattern.extensionRachis:
    case MovementPattern.figureDynamiquePoussee:
    case MovementPattern.figureDynamiqueTirage:
    case MovementPattern.figureStatiqueMixte:
    case MovementPattern.figureStatiquePoussee:
    case MovementPattern.figureStatiqueTirage:
    case MovementPattern.flexionHanche:
    case MovementPattern.flexionTronc:
    case MovementPattern.freestyle:
    case MovementPattern.gainageAntiExtension:
    case MovementPattern.gainageAntiFlexionLaterale:
    case MovementPattern.gainageAntiRotation:
    case MovementPattern.gymnastiqueCrossfit:
    case MovementPattern.marche:
    case MovementPattern.mobiliteArticulaire:
    case MovementPattern.pliometrie:
    case MovementPattern.porte:
    case MovementPattern.prehension:
    case MovementPattern.preparationScapulaire:
    case MovementPattern.respiration:
    case MovementPattern.rotationTronc:
    case MovementPattern.souplesse:
    case MovementPattern.sprint:
      return t == LoadType.addedWeight ? 1.3 : pick(0.5, 0.2, 0.5, 0.4);
  }
}

/// Athlète simulé.
final class SimAthlete {
  /// Athlète [spec] de profil [profile], pour la graine [seed].
  SimAthlete(this.spec, this.profile, this.book, this.seed) {
    final r = SimRandom.of(seed, 'athlete');
    bodyWeightKg = profile.bodyWeightKg ?? 72;
    sensAcute = 0.004 * exp(0.4 * r.gauss());
    sensChronic = 0.0006 * exp(0.4 * r.gauss());
    beta = clampDouble(spec.rirBias + spec.rirBiasSd * r.gauss(), -0.15, 0.8);
    noise = spec.ratingNoise * exp(0.15 * r.gauss());
    weeksTrained = _weeksTrained[spec.level];
  }

  /// Comportement et physiologie.
  final AthleteSpec spec;

  /// Profil déclaré.
  final AthleteProfile profile;

  /// Informations par exercice.
  final ExerciseBook book;

  /// Graine.
  final int seed;

  /// Poids de corps réel, en kg.
  late final double bodyWeightKg;

  /// Sensibilité à la fatigue aiguë.
  late final double sensAcute;

  /// Sensibilité à la fatigue accumulée.
  late final double sensChronic;

  /// Biais de report du RIR.
  late final double beta;

  /// Bruit de perception.
  late final double noise;

  /// Semaines d'entraînement (rendements décroissants).
  late double weeksTrained;

  final Map<String, TruthExercise?> _truth = <String, TruthExercise?>{};
  final List<double> _acute = List<double>.filled(MuscleGroup.values.length, 0);
  double _chronic = 0;
  double _life = 0;
  int _day = 0;
  int _weeks = 0;

  /// Fin de l'épisode de douleur (jour), ou −1.
  int painUntil = -1;

  /// Intensité courante de la douleur.
  int painIntensity = 0;

  /// Hausses de charge faites sur la zone douloureuse après que la douleur
  /// a été signalée (les séances d'avant le premier signalement ne
  /// comptent pas : personne ne pouvait savoir).
  int painAggravations = 0;

  bool _painKnown = false;

  /// Vérités connues (exercices déjà rencontrés).
  Iterable<TruthExercise> get truths =>
      _truth.values.whereType<TruthExercise>();

  /// Vérité de l'exercice [id], ou `null` s'il n'est pas modélisé.
  TruthExercise? truthOf(String id) {
    if (_truth.containsKey(id)) {
      return _truth[id];
    }
    final info = book.find(id);
    final mode = info?.mode;
    if (info == null || mode == null) {
      _truth[id] = null;
      return null;
    }
    final r = SimRandom.of(seed, 'truth|$id');
    final t = TruthExercise(info, mode);
    final e = info.exercise;
    double? declared;
    for (final level in profile.movementLevels) {
      final low = level.low;
      final high = level.high;
      if (level.exerciseId != id ||
          !level.known ||
          low == null ||
          high == null) {
        continue;
      }
      final wanted = mode == CapacityMode.loaded
          ? LevelMeasure.oneRmKg
          : (mode == CapacityMode.hold
                ? LevelMeasure.maxHoldSeconds
                : LevelMeasure.maxReps);
      if (level.measure != wanted || low <= 0) {
        continue;
      }
      final center = sqrt(low * high);
      declared = mode == CapacityMode.loaded
          ? info.totalLoad(center, bodyWeightKg)
          : center;
    }
    final lower = info.lowerBody;
    final female = profile.sex == Sex.female;
    switch (mode) {
      case CapacityMode.loaded:
        if (declared != null) {
          t.capacity = declared * exp(0.08 * r.gauss());
        } else {
          final sexFactor = female ? (lower ? 0.75 : 0.65) : 1.0;
          var total =
              _ratioOf(e) * bodyWeightKg * _levelScale[spec.level] * sexFactor;
          total *= exp(0.12 * r.gauss());
          t.capacity = total;
        }
        final floor = info.fraction * bodyWeightKg * 1.15;
        if (t.capacity < floor) {
          t.capacity = floor;
        }
        // Courbe propre à l'athlète, autour des moyennes publiées (Nuzzo
        // et al. 2024 : environ 5 répétitions à 90 %, 10 à 77 %, 15 à 70 %,
        // 20 à 60 % ; plus de répétitions au bas du corps).
        t.curveB = (lower ? 0.036 : 0.044) * exp(0.20 * r.gauss());
        t.curveA = clampDouble(0.30 + 0.04 * r.gauss(), 0.2, 0.4);
      case CapacityMode.reps:
        if (declared != null) {
          t.capacity = declared * exp(0.10 * r.gauss());
        } else {
          final margin = _levelAbility[spec.level] - e.difficulty;
          t.capacity = clampDouble(
            12 * exp(margin * ln(1.35)) * exp(0.25 * r.gauss()),
            2,
            60,
          );
        }
      case CapacityMode.hold:
        if (declared != null) {
          t.capacity = declared * exp(0.10 * r.gauss());
        } else {
          final margin = _levelAbility[spec.level] - e.difficulty;
          t.capacity = clampDouble(
            30 * exp(margin * ln(1.35)) * exp(0.25 * r.gauss()),
            5,
            180,
          );
        }
        t.holdShare = 0.1 * exp(0.2 * r.gauss());
    }
    t.fatigueScale = exp(0.35 * r.gauss());
    t.startCapacity = t.capacity;
    _truth[id] = t;
    return t;
  }

  /// Avance jusqu'au jour [day] (jours depuis le début).
  void advance(int day) {
    final dt = day - _day;
    if (dt <= 0) {
      return;
    }
    final r = SimRandom.of(seed, 'life|$day');
    for (var i = 0; i < dt; i++) {
      _life = 0.7 * _life + spec.daySd * 0.75 * 0.714 * r.gauss();
    }
    final ea = exp(-dt / 1.5);
    for (var i = 0; i < _acute.length; i++) {
      _acute[i] *= ea;
    }
    _chronic *= exp(-dt / 6);
    for (final t in truths) {
      final last = t.lastDay;
      if (last != null && day - last > 21) {
        final over = dt < day - last - 21 ? dt : day - last - 21;
        t.capacity *= exp(-0.01 * over / 7);
      }
    }
    _day = day;
    final painFrom = spec.painFromDay;
    if (painFrom != null && day >= painFrom && painUntil < 0) {
      painUntil = painFrom + spec.painDays;
      painIntensity = spec.painIntensity;
    }
    if (painUntil >= 0 && day > painUntil) {
      painIntensity = 0;
    }
  }

  /// Vrai si l'athlète est malade au jour courant.
  bool get ill {
    final from = spec.illnessFromDay;
    return from != null && _day >= from && _day < from + spec.illnessDays;
  }

  /// Vrai si l'épisode de douleur est en cours.
  bool get inPain => painIntensity > 0 && _day <= painUntil;

  double _globalReadiness() {
    var r = _life - sensChronic * _chronic;
    if (ill) {
      r -= 0.08;
    }
    return r;
  }

  double _readiness(ExerciseInfo info) {
    var a = 0.0;
    var total = 0.0;
    for (var i = 0; i < info.groups.length; i++) {
      a += _acute[info.groups[i].index] * info.groupWeights[i];
      total += info.groupWeights[i];
    }
    if (total > 0) {
      a /= total;
    }
    return _globalReadiness() - sensAcute * a;
  }

  /// Bilan santé du jour (ou `null` s'il n'est pas rempli) ; [budget] est
  /// la durée prévue de la séance, en minutes.
  HealthCheck? healthCheck(int budget) {
    final r = SimRandom.of(seed, 'health|$_day');
    if (r.next() > spec.healthAnswerRate) {
      return null;
    }
    final readiness = _globalReadiness();
    var overall = (4 + readiness / 0.02 + 0.7 * r.gauss()).round();
    if (overall < 1) {
      overall = 1;
    }
    if (overall > 5) {
      overall = 5;
    }
    final short = r.next() < spec.shortTimeRate;
    if (overall > 2 && !short) {
      return HealthCheck(overall: overall);
    }
    // Réponse basse : le détail est demandé (D5.8).
    if (inPain && spec.painZone != null) {
      _painKnown = true;
    }
    return HealthCheck(
      overall: overall,
      sleepQuality: overall <= 2 ? (r.next() < 0.6 ? 2 : 3) : null,
      energy: overall <= 2 ? 2 : null,
      minutesAvailable: short ? (budget * 0.6).round() : null,
      pains: <PainReport>[
        if (inPain && spec.painZone != null)
          PainReport(
            zone: spec.painZone!,
            side: BodySide.both,
            intensity: painIntensity,
            phase: PainPhase.before,
          ),
      ],
    );
  }

  /// Douleurs signalées pendant la séance (à appeler en fin de séance).
  List<PainReport> sessionPains() {
    final zone = spec.painZone;
    if (!inPain || zone == null) {
      return const <PainReport>[];
    }
    _painKnown = true;
    return <PainReport>[
      PainReport(
        zone: zone,
        side: BodySide.both,
        intensity: painIntensity,
        phase: PainPhase.during,
      ),
    ];
  }

  /// Ouvre l'exercice [t] dans la séance du jour.
  void beginExercise(TruthExercise t, String slotKey) {
    final r = SimRandom.of(seed, 'day|$_day|$slotKey|${t.info.id}');
    t.day = _readiness(t.info) + spec.daySd * 0.66 * r.gauss();
    t.setFatigue = <double>[];
    t.sessionLoad = null;
  }

  /// Ferme l'exercice [t] après ses séries.
  void endExercise(TruthExercise t) {
    final load = t.sessionLoad;
    if (load != null) {
      t.lastLoad = load;
    }
    if (t.firstDay == null) {
      t.firstDay = _day;
      t.firstCapacity = t.capacity;
    }
    t.lastCapacity = t.capacity;
    t.sessions++;
  }

  /// Capacité du moment : répétitions possibles à la charge [loadKg]
  /// (mode chargé), répétitions ou secondes maximales sinon.
  double capacityNow(TruthExercise t, double? loadKg) {
    final keep = 1 - t.fatigueNow();
    switch (t.mode) {
      case CapacityMode.loaded:
        final total = t.info.totalLoad(loadKg ?? 0, bodyWeightKg);
        return t.repsAtShare(total / (t.capacity * exp(t.day))) * keep;
      case CapacityMode.reps:
      case CapacityMode.hold:
        return t.capacity * exp(t.day) * keep;
    }
  }

  /// Haut de plage jusqu'où une prescription peut s'étendre quand la
  /// charge ne peut pas monter (mêmes bornes que le moteur).
  static int extendedTop(int high) {
    final a = high + (high + 2) ~/ 3;
    final b = 2 * high > 30 ? 30 : 2 * high;
    return a > b ? a : b;
  }

  /// Vrai si, aujourd'hui, une charge de la grille (ou, sans charge, la
  /// capacité elle-même) permet de finir une série de la plage [low] à
  /// [high] — étendue comme le moteur sait l'étendre — à [rir]
  /// répétitions de l'échec. Faux : l'exercice est trop facile ou trop dur
  /// pour cette plage avec ce matériel, quelle que soit la politique.
  bool reachable(TruthExercise t, int low, int high, double rir) {
    final fresh = t.capacity * exp(t.day);
    switch (t.mode) {
      case CapacityMode.hold:
        final seconds = fresh * (1 - t.holdShare * (rir > 6 ? 6 : rir));
        return seconds >= 0.7 * low && seconds <= 1.5 * high;
      case CapacityMode.reps:
        final reps = fresh - rir;
        return reps >= low - 2 && reps <= extendedTop(high);
      case CapacityMode.loaded:
        final grid = t.info.grid;
        final top = extendedTop(high);
        var kg = grid.minimum;
        for (var i = 0; i < 2000; i++) {
          final total = t.info.totalLoad(kg, bodyWeightKg);
          final reps = (total <= 0 ? 100.0 : t.repsAtShare(total / fresh)) - rir;
          if (reps < low - 2) {
            return false;
          }
          if (reps <= top) {
            return true;
          }
          final next = grid.next(kg, up: true);
          if (next <= kg) {
            return false;
          }
          kg = next;
        }
        return false;
    }
  }

  /// Charge choisie au jugé pour une première série de [reps] répétitions
  /// à [rir] en réserve : prudente, avec 15 % d'erreur.
  double selfSelect(TruthExercise t, int reps, double rir) {
    final r = SimRandom.of(seed, 'select|${t.info.id}|$_day');
    final total = t.capacity * t.share(reps + rir + 2) * exp(0.15 * r.gauss());
    final ext = total - t.info.fraction * bodyWeightKg;
    final grid = t.info.grid;
    return grid.floor(ext < grid.minimum ? grid.minimum : ext);
  }

  /// Exécute une série : [loadKg] charge externe, cible de [low] à [high]
  /// (répétitions ou secondes) à [flamesTarget] flammes, suivie de
  /// [restSeconds] de repos ; [noiseKey] identifie la série pour les aléas
  /// communs.
  ///
  /// L'athlète fait ce qui est demandé, mais s'arrête de lui-même quand la
  /// série devient nettement plus dure que prévu (RIR perçu 1,5 sous la
  /// cible, jamais au-dessus de 0,5) ; quand la cible est une plage, il
  /// s'arrête au RIR visé perçu.
  SetOutcome perform(
    TruthExercise t, {
    required double? loadKg,
    required int low,
    required int high,
    required int flamesTarget,
    required int restSeconds,
    required String noiseKey,
  }) {
    final r = SimRandom.of(seed, 'set|$noiseKey');
    final hold = t.mode == CapacityMode.hold;
    final capacity = capacityNow(t, loadKg);
    // Répétitions en réserve qu'il reste après `amount`.
    double rirAfter(double amount) => hold
        ? (capacity <= 0 ? 0 : (1 - amount / capacity) / t.holdShare)
        : capacity - amount;
    double amountAt(double rir) =>
        hold ? capacity * (1 - t.holdShare * rir) : capacity - rir;
    final long = hold ? 1.0 : 1 + (capacity > 12 ? (capacity - 12) / 12 : 0);
    final bias = hold
        ? beta
        : beta * (1 + (capacity > 12 ? (capacity - 12) / 24 : 0));
    final targetRir = Flames.toRir(flamesTarget);
    final byFeel = high > low;
    final stopRir = byFeel
        ? targetRir
        : (targetRir - 1.5 < 0.5 ? 0.5 : targetRir - 1.5);
    final stopError = noise * (0.3 + 0.2 * stopRir) * long * r.gauss();
    final stop = amountAt(stopRir * (1 + bias) - stopError);
    var wanted = stop.round();
    if (byFeel) {
      if (wanted < low) {
        wanted = low;
      }
    } else if (wanted < 1) {
      wanted = 1;
    }
    if (wanted > high) {
      wanted = high;
    }
    final most = (capacity + 1e-9).floor();
    int amount;
    int? flames;
    double trueRir;
    var failed = false;
    if (most < wanted) {
      amount = most < 0 ? 0 : most;
      failed = true;
      trueRir = rirAfter(amount.toDouble());
      if (trueRir < 0) {
        trueRir = 0;
      }
      flames = Flames.failure;
    } else {
      amount = wanted;
      trueRir = rirAfter(amount.toDouble());
      var perceived = trueRir / (1 + bias);
      perceived +=
          noise * (0.3 + 0.2 * (trueRir > 6 ? 6 : trueRir)) * long * r.gauss();
      if (perceived < 0) {
        perceived = 0;
      }
      var said = Flames.fromRir(perceived);
      if (said == Flames.failure && trueRir >= 0.75) {
        said = 9;
      }
      final gap = (said - flamesTarget).abs();
      var q = spec.lazy * (gap <= 2 ? 1.0 : (gap <= 4 ? 0.5 : 0.25));
      if (amount < low) {
        q *= 0.5;
      }
      if (r.next() < q) {
        said = flamesTarget;
      }
      flames = r.next() < spec.skipRating ? null : said;
    }
    // Fatigue laissée par la série (vérité : RIR réel et repos).
    final base =
        0.85 *
        exp(-restSeconds / 160) *
        exp(-(trueRir > 8 ? 8 : trueRir) / 1.4);
    t.setFatigue.add(base * t.fatigueScale * exp(0.2 * r.gauss()));
    var w = 1 - (trueRir > 6 ? 6 : trueRir) / 8;
    if (w < 0.3) {
      w = 0.3;
    }
    if (failed) {
      w += 0.5;
    }
    final info = t.info;
    for (var i = 0; i < info.groups.length; i++) {
      _acute[info.groups[i].index] +=
          w * info.groupWeights[i] * info.exercise.localFatigue / 3;
    }
    _chronic += w * info.exercise.systemicFatigue / 3;
    // Stimulus : séries à cinq répétitions de l'échec ou moins, charge
    // d'au moins 55 % du 1RM.
    var heavy = true;
    if (t.mode == CapacityMode.loaded) {
      heavy = info.totalLoad(loadKg ?? 0, bodyWeightKg) / t.capacity >= 0.55;
    }
    if (amount > 0 && trueRir <= 5 && heavy) {
      t.stimulus += 1 - 0.1 * (trueRir > 2 ? trueRir - 2 : 0);
    }
    t.lastDay = _day;
    if (loadKg != null) {
      final before = t.sessionLoad;
      if (before == null || loadKg > before) {
        t.sessionLoad = loadKg;
      }
      // Douleur : une charge accrue sur la zone aggrave et prolonge.
      final zone = spec.painZone;
      final last = t.lastLoad;
      if (inPain &&
          _painKnown &&
          zone != null &&
          last != null &&
          loadKg > last + 1e-9 &&
          info.zoneLevel(zone) >= 0.5 &&
          before == null) {
        painAggravations++;
        painUntil += 7;
        if (painIntensity < 8) {
          painIntensity++;
        }
      }
    }
    return SetOutcome(
      amount: amount,
      flames: flames,
      trueRir: trueRir,
      failed: failed,
    );
  }

  /// Fin de semaine : gains selon la dose de stimulus, réduits par la
  /// surcharge ; rendements décroissants avec l'ancienneté.
  void endWeek() {
    _weeks++;
    final over = (_chronic > 14 ? _chronic - 14 : 0) / 14;
    final rate = spec.weeklyGain / (1 + _weeks / 40);
    for (final t in truths) {
      final s = t.stimulus;
      var dose = s <= 0 ? 0.0 : s / (s + 3) / (6 / 9);
      if (dose > 1.3) {
        dose = 1.3;
      }
      final fast = t.mode == CapacityMode.loaded ? 1.0 : 2.0;
      var keep = 1 - 0.5 * over;
      if (keep < 0.2) {
        keep = 0.2;
      }
      t.capacity *= exp(rate * fast * dose * keep);
      t.stimulus = 0;
    }
  }
}
