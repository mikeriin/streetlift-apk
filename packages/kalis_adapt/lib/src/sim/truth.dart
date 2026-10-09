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
import 'package:kalis_plan/kalis_plan.dart' show MuscleGroup, coachPainStopHits;

import '../book.dart';
import '../coach.dart' show tendonLoaded;
import '../filter.dart';
import '../numeric.dart';
import 'rng.dart';

/// Modèle de vérité de l'athlète simulé. Les trois modèles diffèrent par
/// la forme de la courbe répétitions ↔ charge, le bruit et le biais de la
/// note, la réponse à la dose, la fatigue de séance, l'effet de
/// l'affûtage et l'adaptation des tendons (`docs/VALIDATION.md`, § 8) :
/// le moteur est jugé sur tous, aucun n'est le sien.
enum TruthKind {
  /// Modèle de 0.1 : courbe exponentielle, dose saturante, note gaussienne.
  a,

  /// Courbe linéaire (Brzycki), dose logarithmique pondérée par
  /// l'intensité, note arrondie à la répétition et plafonnée, bonus
  /// d'affûtage, tolérance des tendons en retard sur la force.
  b,

  /// Courbe en puissance (Lombardi), forme et fatigue à deux composantes
  /// (performance masquée par la fatigue récente), biais de note selon le
  /// niveau et décalage du jour, perte dès sept jours d'arrêt.
  c,
}

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

  /// Modèle de vérité (forme de la courbe).
  TruthKind kind = TruthKind.a;

  /// Pente de la courbe linéaire (modèle B) : part perdue par répétition.
  double slope = 0.0278;

  /// Exposant de la courbe en puissance (modèle C).
  double power = 0.10;

  /// Part de la fatigue d'une série encore présente deux séries plus tard.
  double carry = 0.5;

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
  double share(double n) {
    switch (kind) {
      case TruthKind.a:
        return curveA + (1 - curveA) * exp(-curveB * (n - 1));
      case TruthKind.b:
        final v = 1 - slope * ((n < 1 ? 1 : n) - 1);
        return v < 0.3 ? 0.3 : v;
      case TruthKind.c:
        return exp(-power * ln(n < 1 ? 1 : n));
    }
  }

  /// Répétitions possibles à la part [share] du 1RM.
  double repsAtShare(double share) {
    if (share >= 1) {
      return 1 - (share - 1) * 20;
    }
    switch (kind) {
      case TruthKind.a:
        if (share <= curveA + 1e-6) {
          return 100;
        }
        final n = 1 - ln((share - curveA) / (1 - curveA)) / curveB;
        return n > 100 ? 100 : n;
      case TruthKind.b:
        final n = 1 + (1 - share) / slope;
        return n > 100 ? 100 : n;
      case TruthKind.c:
        if (share <= 0.05) {
          return 100;
        }
        final n = exp(-ln(share) / power);
        return n > 100 ? 100 : n;
    }
  }

  /// Perte relative de capacité de la série à venir.
  double fatigueNow() {
    var total = 0.0;
    final n = setFatigue.length;
    for (var i = 0; i < n; i++) {
      total += setFatigue[i] * exp((n - 1 - i) / 2 * ln(carry));
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

/// Biais de report du RIR par niveau du modèle C : la prédiction des
/// répétitions restantes s'améliore avec l'expérience (Steele et al. 2017).
const List<double> _levelBias = <double>[0.45, 0.30, 0.20, 0.12];

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
  /// Athlète [spec] de profil [profile], pour la graine [seed], sous le
  /// modèle de vérité [kind].
  SimAthlete(
    this.spec,
    this.profile,
    this.book,
    this.seed, {
    this.kind = TruthKind.a,
  }) {
    final r = SimRandom.of(seed, 'athlete');
    bodyWeightKg = profile.bodyWeightKg ?? 72;
    sensAcute = 0.004 * exp(0.4 * r.gauss());
    sensChronic = 0.0006 * exp(0.4 * r.gauss());
    final draw = r.gauss();
    beta = kind == TruthKind.c
        ? clampDouble(
            _levelBias[spec.level] + spec.rirBiasSd * draw,
            -0.15,
            0.8,
          )
        : clampDouble(spec.rirBias + spec.rirBiasSd * draw, -0.15, 0.8);
    noise = spec.ratingNoise * exp(0.15 * r.gauss());
    weeksTrained = _weeksTrained[spec.level];
  }

  /// Modèle de vérité.
  final TruthKind kind;

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

  // Modèles B et C : zone restée réactive après un épisode de douleur (CA2,
  // partie 0) — séries de la semaine sur chaque zone tendineuse, habitude
  // (moyenne mobile) et tolérance de la zone réactive, fin de la fenêtre.
  final Map<BodyZone, double> _zoneWeek = <BodyZone, double>{};
  final Map<BodyZone, double> _zoneHabit = <BodyZone, double>{};
  final Map<BodyZone, double> _zoneLastWeek = <BodyZone, double>{};
  BodyZone? _reactiveZone;
  double _reactiveTolerance = 0;
  int _reactiveUntil = -1;

  /// Poussées de douleur provoquées par une hausse trop rapide de la charge
  /// d'une zone réactive (modèles B et C).
  int painFlares = 0;

  // Modèles B et C : charge d'entraînement récente (7 jours) et de fond
  // (28 jours), dernier jour d'une série lourde, secondes de tenue en bras
  // tendus de la semaine, tolérance des tendons, décalage de note du jour.
  double _fast = 0;
  double _slow = 0;
  int? _lastHeavyDay;
  double _holdWeek = 0;
  double? _tendon;
  BodyZone? _tendonZone;
  double _ratingOffset = 0;

  /// Zone de l'épisode de douleur en cours : celle de la fiche, sinon celle
  /// d'une surcharge des tendons (modèle B).
  BodyZone? get painZone => spec.painZone ?? _overuseZone ?? _tendonZone;

  // Zone d'une blessure de surcharge d'endurance en cours (CA2, partie 1).
  BodyZone? _overuseZone;

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
    if (kind != TruthKind.a) {
      // Courbes propres aux modèles B (Brzycki 1993 : une répétition de
      // plus coûte 1/36 du 1RM) et C (Lombardi 1989 : 1RM = charge ×
      // répétitions^0,10), avec leur dispersion entre personnes.
      t
        ..kind = kind
        ..slope = (lower ? 0.0236 : 0.0278) * exp(0.18 * r.gauss())
        ..power = (lower ? 0.085 : 0.10) * exp(0.2 * r.gauss())
        ..carry = kind == TruthKind.c ? 0.6 : 0.5;
    }
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
    if (kind != TruthKind.a) {
      _fast *= exp(-dt / 7);
      _slow *= exp(-dt / 28);
      _ratingOffset = kind == TruthKind.c ? 0.6 * r.gauss() : 0;
    }
    for (final t in truths) {
      final last = t.lastDay;
      if (kind == TruthKind.c) {
        // Modèle C : la force maximale baisse dès que l'arrêt dépasse sept
        // jours (R3-P14 : 1 à 4 %), puis continue de baisser.
        if (last != null && day - last > 7) {
          final over = dt < day - last - 7 ? dt : day - last - 7;
          t.capacity *= exp(-0.0025 * over);
        }
      } else if (last != null && day - last > 21) {
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
      final zone = painZone;
      if (kind != TruthKind.a && painIntensity >= 3 && zone != null) {
        // Après un épisode réel, la zone reste réactive douze semaines : sa
        // tolérance repart de la moitié de la charge habituelle d'avant
        // l'épisode, ou de la charge tenue la dernière semaine si elle est
        // plus haute (choix raisonné ; modèle de réponse du tendon à la
        // charge : Cook et Purdam 2009, Silbernagel et al. 2007).
        final half = 0.5 * (_zoneHabit[zone] ?? 0);
        final carried = _zoneLastWeek[zone] ?? 0;
        _reactiveZone = zone;
        _reactiveUntil = day + 84;
        _reactiveTolerance = carried > half ? carried : half;
      }
      painIntensity = 0;
      _overuseZone = null;
    }
  }

  /// Vrai si l'athlète est malade au jour courant.
  bool get ill {
    final from = spec.illnessFromDay;
    return from != null && _day >= from && _day < from + spec.illnessDays;
  }

  /// Vrai si l'épisode de douleur est en cours.
  bool get inPain => painIntensity > 0 && _day <= painUntil;

  /// Blessure de surcharge de course ou de conditionnement (vérité
  /// d'endurance ; CA2, partie 1) : épisode de douleur d'intensité
  /// [intensity] sur [zone] pendant [days] jours, si aucun épisode n'est en
  /// cours et que la fiche n'impose pas sa propre douleur. L'épisode n'est
  /// connu du moteur qu'une fois signalé.
  void overuse(BodyZone zone, int intensity, int days) {
    if (inPain || spec.painZone != null) {
      return;
    }
    _overuseZone = zone;
    painIntensity = intensity;
    painUntil = _day + days;
    _painKnown = false;
  }

  /// Effet de la charge récente sur la performance (modèles B et C) :
  /// rapport de la charge des 7 derniers jours à la charge de fond.
  ///
  /// B : bonus d'affûtage quand la charge récente passe sous la charge de
  /// fond en gardant une série lourde dans les dix jours (R3-P12, R3-P13 ;
  /// Bosquet et al. 2007 : gain de l'ordre de 2 à 3 %), malus sinon.
  /// C : forme masquée par la fatigue récente (Banister ; Busso 2003) —
  /// la performance monte quand la fatigue retombe, baisse en surcharge.
  double _sharpness() {
    if (kind == TruthKind.a || _slow < 4) {
      return 0;
    }
    final ratio = (_fast / 7) / (_slow / 28);
    if (kind == TruthKind.b) {
      var bonus = clampDouble(0.03 * (1 - ratio), -0.01, 0.025);
      final heavy = _lastHeavyDay;
      if (heavy != null && _day - heavy > 10) {
        final late = (_day - heavy - 10) / 10;
        bonus -= 0.02 * (late > 1 ? 1 : late);
      }
      return bonus;
    }
    return clampDouble(-0.02 * ln(ratio < 0.25 ? 0.25 : ratio), -0.015, 0.03);
  }

  double _globalReadiness() {
    var r = _life - sensChronic * _chronic;
    if (ill) {
      r -= 0.08;
    }
    if (kind != TruthKind.a) {
      r += _sharpness();
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
    if (inPain && painZone != null) {
      _painKnown = true;
    }
    return HealthCheck(
      overall: overall,
      sleepQuality: overall <= 2 ? (r.next() < 0.6 ? 2 : 3) : null,
      energy: overall <= 2 ? 2 : null,
      minutesAvailable: short ? (budget * 0.6).round() : null,
      pains: <PainReport>[
        if (inPain && painZone != null)
          PainReport(
            zone: painZone!,
            side: BodySide.both,
            intensity: painIntensity,
            phase: PainPhase.before,
          ),
      ],
    );
  }

  /// Douleurs signalées pendant la séance (à appeler en fin de séance).
  List<PainReport> sessionPains() {
    final zone = painZone;
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
    switch (kind) {
      case TruthKind.a:
        t.day = _readiness(t.info) + spec.daySd * 0.66 * r.gauss();
      case TruthKind.b:
        // Variation d'un jour à l'autre plus large (coefficient de
        // variation médian du 1RM : 4,2 %, Grgic et al. 2020).
        t.day = _readiness(t.info) + spec.daySd * 1.3 * 0.66 * r.gauss();
      case TruthKind.c:
        // Queue lourde : un jour sur dix est nettement mauvais.
        final g = r.gauss();
        final bad = r.next() < 0.1;
        t.day = _readiness(t.info) + spec.daySd * 0.66 * g - (bad ? 0.04 : 0);
    }
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
          final reps =
              (total <= 0 ? 100.0 : t.repsAtShare(total / fresh)) - rir;
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
      final capped = trueRir > 6 ? 6.0 : trueRir;
      switch (kind) {
        case TruthKind.a:
          perceived += noise * (0.3 + 0.2 * capped) * long * r.gauss();
        case TruthKind.b:
          // Note dite en répétitions entières, plafonnée à 4, erreur qui
          // grandit loin de l'échec (Zourdos et al. 2021), une note sur
          // douze franchement fausse.
          perceived += noise * (0.5 + 0.25 * capped) * long * r.gauss();
          if (r.next() < 0.08) {
            perceived += r.next() < 0.5 ? 2 : -2;
          }
          perceived = perceived.roundToDouble();
          if (perceived > 4) {
            perceived = 4;
          }
        case TruthKind.c:
          // Décalage commun aux séries du jour, en plus du bruit par série.
          perceived +=
              _ratingOffset + noise * (0.3 + 0.2 * capped) * long * r.gauss();
      }
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
    final rirCapped = trueRir > 8 ? 8.0 : trueRir;
    final double base;
    switch (kind) {
      case TruthKind.a:
        base = 0.85 * exp(-restSeconds / 160) * exp(-rirCapped / 1.4);
      case TruthKind.b:
        // Récupération hyperbolique avec le repos (chute des répétitions
        // à 1, 3 et 5 min : de Salles et al. 2009).
        base = 0.8 / (1 + restSeconds / 75) / (1 + rirCapped / 1.2);
      case TruthKind.c:
        base = 0.7 * exp(-restSeconds / 200) * exp(-rirCapped / 2);
    }
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
    // Stimulus : une série compte pleinement jusqu'à deux répétitions de
    // l'échec, puis de moins en moins (un cinquième au-delà de dix) ; la
    // charge doit atteindre la moitié du 1RM. La force progresse presque
    // autant loin de l'échec (Pelland et al. 2026, Refalo et al. 2023) :
    // la pente est douce.
    var heavy = true;
    if (t.mode == CapacityMode.loaded) {
      heavy = info.totalLoad(loadKg ?? 0, bodyWeightKg) / t.capacity >= 0.5;
    }
    switch (kind) {
      case TruthKind.a:
        if (amount > 0 && heavy) {
          final value = 1 - 0.1 * (trueRir > 2 ? trueRir - 2 : 0);
          t.stimulus += value < 0.2 ? 0.2 : value;
        }
      case TruthKind.b:
        // La force répond à la charge plus qu'à la proximité de l'échec
        // (R1-P11, R1-P14) : une série compte selon sa part du 1RM.
        if (amount > 0) {
          var value = trueRir <= 4 ? 1.0 : 0.6;
          if (t.mode == CapacityMode.loaded) {
            final part = info.totalLoad(loadKg ?? 0, bodyWeightKg) / t.capacity;
            value = part >= 0.85
                ? 1.5
                : (part >= 0.7 ? 1.0 : (part >= 0.5 ? 0.6 : 0.2));
            if (part >= 0.85) {
              _lastHeavyDay = _day;
            }
          }
          t.stimulus += value;
        }
      case TruthKind.c:
        if (amount > 0 && heavy) {
          final value = 1 - 0.15 * (trueRir > 3 ? trueRir - 3 : 0);
          t.stimulus += value < 0.3 ? 0.3 : value;
        }
    }
    if (kind != TruthKind.a && amount > 0) {
      _fast += w;
      _slow += w;
      if (tendonLoaded(info)) {
        _holdWeek += amount;
      }
      for (final zone in _tendonZones) {
        // (Mouvements qui provoquent la zone au sens de la règle d'arrêt
        // des moteurs : ce que la reprise graduée dose.)
        if (coachPainStopHits(info.exercise, zone)) {
          _zoneWeek[zone] = (_zoneWeek[zone] ?? 0.0) + 1;
        }
      }
    }
    t.lastDay = _day;
    if (loadKg != null) {
      final before = t.sessionLoad;
      if (before == null || loadKg > before) {
        t.sessionLoad = loadKg;
      }
      // Douleur : une charge accrue sur la zone aggrave et prolonge. (Une
      // gêne de 3 sur 10 au plus reste dans la zone où l'activité continue :
      // seule une douleur au-dessus compte — R5-P23, Silbernagel et al.
      // 2007, et le seuil `painThreshold` du moteur.)
      final zone = painZone;
      final last = t.lastLoad;
      if (inPain &&
          painIntensity > 3 &&
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

  static const List<BodyZone> _tendonZones = <BodyZone>[
    BodyZone.elbow,
    BodyZone.shoulder,
    BodyZone.wristHand,
  ];

  /// Zone réactive (modèles B et C) : une semaine nettement au-dessus de la
  /// tolérance de la zone (+50 %) ramène une gêne de 2 sur 10 pendant six
  /// jours, une hausse brutale (le double) une gêne de 3 sur 10 ; la tolérance
  /// suit la charge tenue sans poussée (moyenne mobile de moitié). Les
  /// séries de chaque zone tendineuse forment l'habitude (moyenne mobile
  /// d'un quart) hors épisode. Choix raisonnés du modèle de vérité : la
  /// relecture documentée demande des paliers d'environ 10 % par semaine
  /// (Soligard et al. 2016 : hausses hebdomadaires sous 10 %, rapport de
  /// charge aiguë à chronique au-dessus de 1,5 : risque plus que doublé) ;
  /// une hausse de 50 % en une semaine est nettement au-delà.
  void _reactiveWeek() {
    final zone = _reactiveZone;
    if (zone != null && _day > _reactiveUntil) {
      _reactiveZone = null;
    }
    final reactive = _reactiveZone;
    for (final z in _tendonZones) {
      final week = _zoneWeek[z] ?? 0.0;
      if (z == reactive) {
        final tolerance = _reactiveTolerance < 4 ? 4.0 : _reactiveTolerance;
        if (!inPain && week > 1.5 * tolerance) {
          painFlares++;
          painIntensity = week > 2 * tolerance ? 3 : 2;
          painUntil = _day + 6;
          // (Une nouvelle poussée n'est connue du moteur qu'une fois
          // signalée.)
          _painKnown = false;
        } else if (!inPain && week > _reactiveTolerance) {
          // La tolérance suit la charge tenue sans gêne, sans jamais
          // baisser (une semaine d'allègement ne la fait pas retomber).
          _reactiveTolerance += (week - _reactiveTolerance) / 2;
        }
      } else if (!inPain || painZone != z) {
        final habit = _zoneHabit[z];
        _zoneHabit[z] = habit == null ? week : habit + (week - habit) / 4;
      }
      _zoneLastWeek[z] = week;
      _zoneWeek[z] = 0;
    }
  }

  /// Fin de semaine : gains selon la dose de stimulus, réduits par la
  /// surcharge ; rendements décroissants avec l'ancienneté.
  void endWeek() {
    _weeks++;
    if (kind != TruthKind.a) {
      _reactiveWeek();
    }
    final over = (_chronic > 14 ? _chronic - 14 : 0) / 14;
    final rate = spec.weeklyGain / (1 + _weeks / 40);
    if (kind != TruthKind.a) {
      // Tendons (modèle B) : la tolérance suit la dose de tenues en bras
      // tendus avec retard (R4-F9) ; une semaine très au-dessus déclenche
      // un épisode de gêne au poignet.
      final tolerance = _tendon;
      if (tolerance == null) {
        if (_holdWeek > 0) {
          _tendon = _holdWeek;
        }
      } else {
        if (kind == TruthKind.b &&
            _holdWeek > 1.3 * tolerance + 10 &&
            spec.painZone == null &&
            !inPain) {
          _tendonZone = BodyZone.wristHand;
          painIntensity = 4;
          painUntil = _day + 10;
        }
        _tendon = tolerance + (_holdWeek - tolerance) / 6;
      }
      _holdWeek = 0;
    }
    for (final t in truths) {
      final s = t.stimulus;
      double dose;
      double fast;
      switch (kind) {
        case TruthKind.a:
          dose = s <= 0 ? 0.0 : s / (s + 3) / (6 / 9);
          if (dose > 1.3) {
            dose = 1.3;
          }
          fast = t.mode == CapacityMode.loaded ? 1.0 : 2.0;
        case TruthKind.b:
          // Réponse logarithmique au nombre de séries (rendements
          // décroissants, Ralston et al. 2017).
          dose = s <= 0 ? 0.0 : ln(1 + s) / ln(9);
          if (dose > 1.25) {
            dose = 1.25;
          }
          fast = t.mode == CapacityMode.loaded
              ? 1.0
              : (tendonLoaded(t.info) ? 1.2 : 2.0);
        case TruthKind.c:
          dose = s <= 0 ? 0.0 : (1 - exp(-s / 5)) / (1 - exp(-6 / 5));
          if (dose > 1.2) {
            dose = 1.2;
          }
          fast = t.mode == CapacityMode.loaded
              ? 1.0
              : (tendonLoaded(t.info) ? 1.2 : 1.8);
      }
      var keep = 1 - 0.5 * over;
      if (keep < 0.2) {
        keep = 0.2;
      }
      t.capacity *= exp(rate * fast * dose * keep);
      t.stimulus = 0;
    }
  }

  /// Propreté d'une ligne de figure ou de maintien (1 à 5) : parfaite avec
  /// deux répétitions en réserve et plus, dégradée près de l'échec.
  int qualityOf(SetOutcome outcome) {
    if (outcome.failed) {
      return 2;
    }
    final rir = outcome.trueRir;
    return rir >= 2 ? 5 : (rir >= 1 ? 4 : (rir >= 0.3 ? 3 : 2));
  }

  /// Exécute une descente surchargée ou seule : la capacité excentrique
  /// dépasse la capacité concentrique d'environ 30 % (ordre de grandeur :
  /// 20 à 60 % selon les études, choix raisonné).
  SetOutcome performEccentric(
    TruthExercise t, {
    required double? loadKg,
    required int low,
    required int high,
    required int flamesTarget,
    required int restSeconds,
    required String noiseKey,
  }) {
    final before = t.day;
    t.day = before + ln(1.3);
    final outcome = perform(
      t,
      loadKg: loadKg,
      low: low,
      high: high,
      flamesTarget: flamesTarget,
      restSeconds: restSeconds,
      noiseKey: noiseKey,
    );
    t.day = before;
    return outcome;
  }
}
