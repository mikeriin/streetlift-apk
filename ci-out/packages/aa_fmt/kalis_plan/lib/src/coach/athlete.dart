/// Lecture « coach » du profil d'athlète au schéma 3 : niveau, records,
/// acquis, matériel par jour, contraintes, tolérance. C'est tout ce que
/// les règles de programmation du chemin street de `kalis_plan` 0.2 lisent
/// du profil (CONTRAT.md, § 12).
library;

import 'dart:math' as math;

import 'package:kalis_core/kalis_core.dart';

import '../traits.dart';

/// Poids de corps pris quand le profil ne le donne pas, en kg.
const double coachDefaultBodyWeightKg = 75;

/// Jour d'entraînement lu du profil.
final class CoachDay {
  /// Jour.
  const CoachDay({
    required this.index,
    required this.weekday,
    required this.minutes,
    required this.place,
    required this.equipment,
  });

  /// Rang du jour d'entraînement (0 = premier de la semaine).
  final int index;

  /// Jour ISO (1 = lundi).
  final int weekday;

  /// Minutes disponibles.
  final int minutes;

  /// Lieu imposé, ou `null`.
  final Place? place;

  /// Matériel du jour.
  final Set<String> equipment;
}

/// Zone à ménager : gêne actuelle ou antécédent.
final class CoachLimit {
  /// Zone.
  const CoachLimit({
    required this.zone,
    required this.joint,
    required this.discomfort,
    required this.recent,
    required this.since,
  });

  /// Zone du corps.
  final BodyZone zone;

  /// Articulation du catalogue, ou `null`.
  final Joint? joint;

  /// Gêne de 0 à 10 (la plus forte de la gêne du moment et de la gêne à
  /// l'effort).
  final int discomfort;

  /// Vrai pour une gêne ou un antécédent de moins de douze mois.
  final bool recent;

  /// Ancienneté déclarée, ou `null`.
  final ConstraintSince? since;
}

/// Disciplines que le chemin street sait programmer.
const Set<TrainingDiscipline> coachStreetDisciplines = <TrainingDiscipline>{
  TrainingDiscipline.streetWorkout,
  TrainingDiscipline.streetlifting,
  TrainingDiscipline.calisthenics,
};

/// Vrai si [profile] relève du chemin street de `kalis_plan` 0.2 : profil
/// au schéma 3 rempli par le questionnaire 0.4 (expérience et ancienneté
/// renseignées — sans elles le niveau n'est pas lisible et le chemin 0.1
/// s'applique), discipline principale street (streetlifting, sets & reps,
/// calisthénie), disciplines secondaires street, cardio ou mobilité.
bool coachEligible(AthleteProfile profile) {
  if (!profile.isSchema3 ||
      profile.experience == null ||
      profile.trainingAge == null) {
    return false;
  }
  final mix = profile.disciplines;
  if (!coachStreetDisciplines.contains(mix.primary)) {
    return false;
  }
  for (final s in mix.secondaries) {
    if (!coachStreetDisciplines.contains(s.discipline) &&
        s.discipline != TrainingDiscipline.cardio &&
        s.discipline != TrainingDiscipline.mobility) {
      return false;
    }
  }
  return profile.availability.isNotEmpty;
}

double _pow(double x, double y) => math.pow(x, y).toDouble();

/// Rythme le plus rapide que le plan s'autorise pour un maximum de
/// répétitions, en fraction du record par semaine et par niveau (choix
/// raisonné : R5-P13, les gains ralentissent avec l'ancienneté ; le plan
/// ne promet jamais plus, même si l'objectif déclaré le demande).
const List<double> coachPlannedRepsRate = <double>[0.08, 0.03, 0.02, 0.012];

/// Même borne pour un maintien maximal (choix raisonné).
const List<double> coachPlannedHoldRate = <double>[0.05, 0.04, 0.03, 0.02];

/// Profil lu par le coach.
final class Athlete {
  Athlete._({
    required this.catalog,
    required this.traits,
    required this.profile,
    required this.start,
    required this.level,
    required this.bodyWeight,
    required this.age,
    required this.days,
    required this.oneRm,
    required this.reps,
    required this.holds,
    required this.recordDay,
    required this.runTenKSeconds,
    required this.notAcquired,
    required this.known,
    required this.excluded,
    required this.limits,
    required this.cautious,
    required this.volumeFactor,
    required this.pullFactor,
    required this.legsFactor,
    required this.rirBonus,
    required this.freezeVolume,
    required this.slowRamp,
    required this.gapWeeks,
    required this.heavyImpactBanned,
    required this.allImpactBanned,
  });

  /// Lit [profile] pour un bloc qui commence le [start].
  factory Athlete.read(
    Catalog catalog,
    AthleteProfile profile,
    CivilDate start, {
    Set<String> extraExcluded = const <String>{},
    List<(BodyZone, int)> extraPains = const <(BodyZone, int)>[],
    Map<int, int> minutesOverride = const <int, int>{},
  }) {
    final traits = CatalogTraits.of(catalog);
    final bodyWeight = profile.bodyWeightKg ?? coachDefaultBodyWeightKg;
    final age = start.year - profile.birthYear;

    // Jours, triés par jour de la semaine.
    final slots = <DaySlot>[...profile.availability]
      ..sort((a, b) => a.weekday.compareTo(b.weekday));
    final byPlace = <Place, Set<String>>{
      for (final pe in profile.equipmentByPlace ?? const <PlaceEquipment>[])
        pe.place: pe.equipment.toSet(),
    };
    final all = profile.equipment.toSet();
    final days = <CoachDay>[];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      final place = s.place;
      days.add(
        CoachDay(
          index: i,
          weekday: s.weekday,
          minutes: minutesOverride[i] ?? s.minutes,
          place: place,
          equipment: place == null ? all : (byPlace[place] ?? all),
        ),
      );
    }

    // Records : tests datés du schéma 3 d'abord, fourchettes du schéma 2
    // ensuite (borne basse).
    final oneRm = <String, double>{};
    final reps = <String, int>{};
    final holds = <String, int>{};
    final recordDay = <String, CivilDate>{};
    double? runTenK;
    final zero = <String>{};
    for (final l in profile.movementLevels) {
      final low = l.low;
      if (!l.known || low == null) {
        continue;
      }
      switch (l.measure) {
        case LevelMeasure.oneRmKg:
          oneRm[l.exerciseId] = low;
        case LevelMeasure.maxReps:
          if (low <= 0 && (l.high ?? 0) <= 0) {
            zero.add(l.exerciseId);
          } else {
            reps[l.exerciseId] = low.floor();
          }
        case LevelMeasure.maxHoldSeconds:
          if (low > 0) {
            holds[l.exerciseId] = low.floor();
          }
        case LevelMeasure.timeSeconds:
          break;
      }
    }
    for (final b in profile.benchmarks ?? const <Benchmark>[]) {
      switch (b.kind) {
        case BenchmarkKind.loadReps:
          final load = b.externalLoadKg;
          final n = b.reps;
          if (load == null || n == null) {
            break;
          }
          final e = catalog.find(b.exerciseId);
          final fraction = e?.bodyweightFraction?.value ?? 0;
          final total = load + fraction * (b.bodyWeightKg ?? bodyWeight);
          final estimate = estimateOneRm(
            loadKg: total,
            reps: n,
            rir: b.rir ?? 0,
          );
          if (estimate != null) {
            final external = estimate.valueKg - fraction * bodyWeight;
            final before = oneRm[b.exerciseId];
            if (before == null || external > before) {
              oneRm[b.exerciseId] = external;
            }
          }
        case BenchmarkKind.maxReps:
          final n = b.reps;
          if (n != null && (b.externalLoadKg ?? 0) == 0) {
            final before = reps[b.exerciseId];
            if (before == null || n > before) {
              reps[b.exerciseId] = n;
              final day = b.date;
              if (day != null) {
                recordDay[b.exerciseId] = day;
              }
            }
            zero.remove(b.exerciseId);
          }
        case BenchmarkKind.maxHold:
          final s = b.seconds;
          if (s != null && (b.externalLoadKg ?? 0) == 0) {
            final before = holds[b.exerciseId];
            if (before == null || s > before) {
              holds[b.exerciseId] = s;
              final day = b.date;
              if (day != null) {
                recordDay[b.exerciseId] = day;
              }
            }
          }
        case BenchmarkKind.timeTrial:
          final t = b.seconds;
          final meters = b.distanceMeters;
          if (t != null && meters != null && meters >= 1000 && t > 0) {
            // Allure ramenée à 10 km par la formule de Riegel (exposant
            // 1,06).
            final ten = t * _pow(10000 / meters, 1.06);
            if (runTenK == null || ten < runTenK) {
              runTenK = ten;
            }
          }
        default:
          break;
      }
    }
    for (final s in profile.skills ?? const <SkillState>[]) {
      final hold = s.bestHoldSeconds;
      if (hold != null && hold > 0) {
        final before = holds[s.currentExerciseId];
        if (before == null || hold > before) {
          holds[s.currentExerciseId] = hold;
        }
      }
      final n = s.bestReps;
      if (n != null && n > 0) {
        final before = reps[s.currentExerciseId];
        if (before == null || n > before) {
          reps[s.currentExerciseId] = n;
        }
      }
    }

    final cannot = (profile.cannotDoExerciseIds ?? const <String>[]).toSet();
    final notAcquired = <CatalogExercise>[];
    for (final id in <String>{...zero, ...cannot}) {
      final e = catalog.find(id);
      if (e != null) {
        notAcquired.add(e);
      }
    }
    notAcquired.sort((a, b) => a.id.compareTo(b.id));
    final known = <String>{
      ...profile.knownExerciseIds ?? const <String>[],
      ...oneRm.keys,
      ...reps.keys,
      ...holds.keys,
    };
    final excluded = <String>{
      ...profile.dislikedExerciseIds,
      ...cannot,
      ...extraExcluded,
    };

    // Niveau : expérience déclarée, sinon ancienneté.
    var level = 0;
    final experience = profile.experience;
    final trainingAge = profile.trainingAge;
    if (experience != null) {
      level = experience.index;
    } else if (trainingAge != null) {
      level = switch (trainingAge) {
        TrainingAge.under6Months => 0,
        TrainingAge.months6To24 => 1,
        _ => 2,
      };
    }
    if (level > 3) {
      level = 3;
    }

    // Zones à ménager.
    final limits = <CoachLimit>[];
    for (final l in profile.limitations) {
      final effort = l.effortDiscomfort ?? 0;
      final discomfort = effort > l.discomfort ? effort : l.discomfort;
      final since = l.since;
      final recent =
          since == null ||
          (since != ConstraintSince.over12Months &&
              since != ConstraintSince.pastResolved);
      limits.add(
        CoachLimit(
          zone: l.zone,
          joint: l.joint ?? l.zone.joint,
          discomfort: discomfort,
          recent: recent,
          since: since,
        ),
      );
    }
    for (final (zone, pain) in extraPains) {
      limits.add(
        CoachLimit(
          zone: zone,
          joint: zone.joint,
          discomfort: pain,
          recent: true,
          since: null,
        ),
      );
    }

    final screening = profile.healthScreening;
    final cautious =
        screening == null ||
        screening.outcome != HealthScreeningOutcome.standard ||
        age >= 65 ||
        age < 18;

    // Tolérance (R5-P10, P14, P15, P18, P19, P21 : choix raisonnés).
    var volume = 1.0;
    var pull = 1.0;
    var legs = 1.0;
    var rirBonus = 0.0;
    var freeze = false;
    if (age >= 60) {
      volume *= 0.8;
    }
    if (profile.sleep == SleepBand.under6Hours) {
      volume *= 0.85;
      rirBonus = 1;
      freeze = true;
    }
    if (profile.stress == StressBand.high) {
      volume *= 0.9;
      rirBonus = 1;
      freeze = true;
    }
    if (profile.occupationalLoad == OccupationalLoad.heavy) {
      pull *= 0.85;
      legs *= 0.85;
    }
    if (profile.bodyWeightGoal == BodyWeightGoal.lose) {
      freeze = true;
    }
    var enduranceSessions = 0;
    for (final s in profile.otherSports ?? const <OtherSport>[]) {
      if (s.kind == OtherSportKind.running ||
          s.kind == OtherSportKind.cycling ||
          s.kind == OtherSportKind.otherEndurance ||
          s.kind == OtherSportKind.teamSport) {
        enduranceSessions += s.sessionsPerWeek;
      }
    }
    for (final s in profile.disciplines.secondaries) {
      if (s.discipline == TrainingDiscipline.cardio && s.pct >= 30) {
        enduranceSessions += 3;
      }
    }
    if (enduranceSessions >= 3) {
      legs *= 0.7;
    }
    for (final l in limits) {
      if (l.discomfort >= 2 && l.recent) {
        if (l.zone == BodyZone.elbow ||
            l.zone == BodyZone.shoulder ||
            l.zone == BodyZone.wristHand) {
          pull *= 0.6;
        } else if (l.zone == BodyZone.knee ||
            l.zone == BodyZone.hip ||
            l.zone == BodyZone.ankleFoot ||
            l.zone == BodyZone.lowerBack) {
          legs *= 0.7;
        }
      }
    }
    // R5-P21 : le cumul des réductions ne dépasse pas 40 %.
    if (volume < 0.6) {
      volume = 0.6;
    }
    if (volume * pull < 0.6) {
      pull = 0.6 / volume;
    }
    if (volume * legs < 0.6) {
      legs = 0.6 / volume;
    }

    final gap = profile.trainingGap;
    final gapWeeks = gap == null
        ? 0
        : switch (gap) {
            TrainingGap.reduced => 1,
            TrainingGap.under3Weeks => 2,
            TrainingGap.weeks3To10 => 6,
            TrainingGap.weeks10To26 => 16,
            TrainingGap.months6To24 => 36,
            TrainingGap.over2Years => 104,
            _ => 0,
          };

    final height = profile.heightCm / 100;
    final bmi = bodyWeight / (height * height);
    return Athlete._(
      catalog: catalog,
      traits: traits,
      profile: profile,
      start: start,
      level: level,
      bodyWeight: bodyWeight,
      age: age,
      days: days,
      oneRm: oneRm,
      reps: reps,
      holds: holds,
      recordDay: recordDay,
      runTenKSeconds: runTenK,
      notAcquired: notAcquired,
      known: known,
      excluded: excluded,
      limits: limits,
      cautious: cautious,
      volumeFactor: volume,
      pullFactor: pull,
      legsFactor: legs,
      rirBonus: rirBonus,
      freezeVolume: freeze,
      slowRamp: age >= 40,
      gapWeeks: gapWeeks,
      heavyImpactBanned: level == 0 && bmi >= 30,
      allImpactBanned: cautious,
    );
  }

  /// Catalogue.
  final Catalog catalog;

  /// Traits du catalogue.
  final CatalogTraits traits;

  /// Profil.
  final AthleteProfile profile;

  /// Premier jour du bloc.
  final CivilDate start;

  /// Niveau : 0 débutant, 1 intermédiaire, 2 avancé, 3 élite.
  final int level;

  /// Poids de corps, en kg.
  final double bodyWeight;

  /// Âge, en années.
  final int age;

  /// Jours d'entraînement.
  final List<CoachDay> days;

  /// 1RM de charge externe par exercice, en kg.
  final Map<String, double> oneRm;

  /// Maximum de répétitions par exercice (strictement positif).
  final Map<String, int> reps;

  /// Maintien maximal par exercice, en secondes.
  final Map<String, int> holds;

  /// Jour du record (répétitions ou maintien) par exercice, quand il est
  /// connu.
  final Map<String, CivilDate> recordDay;

  /// Temps actuel sur 10 km, en secondes (meilleur chrono déclaré, ramené
  /// à 10 km), ou `null`.
  final double? runTenKSeconds;

  /// Objectif de course chronométré (distance en mètres, temps visé en
  /// secondes), ou `null`.
  (double, double)? get runGoal {
    for (final g in profile.goals) {
      final meters = g.distanceMeters;
      final target = g.targetValue;
      if (g.metric == GoalMetric.timeSeconds &&
          meters != null &&
          target != null &&
          meters >= 1000 &&
          target > 0) {
        return (meters, target);
      }
    }
    return null;
  }

  /// Temps prévu sur [meters] d'après le chrono actuel (formule de Riegel,
  /// exposant 1,06), en secondes, ou `null` sans chrono.
  double? runTimeOn(double meters) {
    final ten = runTenKSeconds;
    return ten == null ? null : ten * _pow(meters / 10000, 1.06);
  }

  /// Exercices déclarés non acquis (zéro répétition, « je ne sais pas
  /// faire »).
  final List<CatalogExercise> notAcquired;

  /// Exercices sus (déclarés, ou avec un record).
  final Set<String> known;

  /// Exercices écartés (non aimés, non sus, verrous d'exclusion).
  final Set<String> excluded;

  /// Zones à ménager.
  final List<CoachLimit> limits;

  /// Mode prudent (questionnaire santé, 65 ans et plus, moins de 18 ans).
  final bool cautious;

  /// Facteur de volume général (au plus 1).
  final double volumeFactor;

  /// Facteur de volume du tirage et de la préhension.
  final double pullFactor;

  /// Facteur de volume des jambes.
  final double legsFactor;

  /// Répétitions en réserve ajoutées (sommeil court, stress élevé).
  final double rirBonus;

  /// Vrai quand le volume ne monte pas d'un bloc à l'autre.
  final bool freezeVolume;

  /// Vrai quand la progression du volume est ralentie (40 ans et plus).
  final bool slowRamp;

  /// Semaines d'arrêt avant le programme (0 : aucune ; 1 : entraînement
  /// allégé).
  final int gapWeeks;

  /// Sauts, corde, balistique et haltérophilie écartés (R5-P9).
  final bool heavyImpactBanned;

  /// Tout exercice à impact écarté (mode prudent).
  final bool allImpactBanned;

  /// Nombre de jours d'entraînement.
  int get dayCount => days.length;

  /// Vrai si le matériel [item] existe le jour [day].
  bool has(int day, String item) => days[day].equipment.contains(item);

  /// Vrai si le matériel [item] existe au moins un jour.
  bool hasAny(String item) => days.any((d) => d.equipment.contains(item));

  /// Zone à ménager la plus gênante sur l'articulation [joint], ou `null`.
  CoachLimit? limitOn(Joint joint) {
    CoachLimit? worst;
    for (final l in limits) {
      if (l.joint == joint &&
          (worst == null || l.discomfort > worst.discomfort)) {
        worst = l;
      }
    }
    return worst;
  }

  /// Objectif chiffré de [metric] sur l'exercice [id], ou `null`.
  Goal? goalOn(String id, GoalMetric metric) {
    for (final g in profile.goals) {
      if (g.exerciseId == id && g.metric == metric && g.targetValue != null) {
        return g;
      }
    }
    return null;
  }

  /// Vrai si un objectif (ou une épreuve de l'échéance) porte sur
  /// l'exercice [id] ou sur une variante de sa chaîne.
  bool aimsAt(String id) {
    final root = catalog.find(id)?.rootId ?? id;
    for (final g in profile.goals) {
      final other = g.exerciseId;
      if (other != null &&
          (other == id || (catalog.find(other)?.rootId ?? other) == root)) {
        return true;
      }
    }
    for (final e in profile.events ?? const <SeasonEvent>[]) {
      for (final l in e.lifts ?? const <CompetitionLift>[]) {
        if (l.exerciseId == id ||
            (catalog.find(l.exerciseId)?.rootId ?? l.exerciseId) == root) {
          return true;
        }
      }
      for (final st in e.stations ?? const <EventStation>[]) {
        if (st.exerciseId == id) {
          return true;
        }
      }
    }
    return false;
  }

  /// Gain prévu du record [record] de l'exercice [id] le [day], en
  /// fraction du record : la trajectoire qui mène à l'objectif déclaré,
  /// bornée par le rythme plausible du niveau, ou la moitié de ce rythme
  /// sans objectif. C'est un plan, pas une mesure : chaque test le recale
  /// (le record et sa date changent, la trajectoire repart de là).
  double plannedGain(String id, GoalMetric metric, num record, CivilDate day) {
    if (record <= 0) {
      return 0;
    }
    final goal = goalOn(id, metric);
    final anchor = recordDay[id] ?? goal?.createdOn;
    if (anchor == null) {
      return 0;
    }
    final weeks = anchor.daysUntil(day) / 7;
    if (weeks <= 0) {
      return 0;
    }
    var cap = (metric == GoalMetric.maxHoldSeconds
        ? coachPlannedHoldRate
        : coachPlannedRepsRate)[level];
    // Petits records : une répétition (ou une seconde) de plus toutes les
    // trois semaines reste plausible à tout niveau.
    if (cap < 1 / (3 * record)) {
      cap = 1 / (3 * record);
    }
    var rate = cap / 2;
    var ceiling = double.infinity;
    final target = goal?.targetValue;
    final deadline = goal?.targetDate;
    if (target != null && target > record) {
      ceiling = target / record - 1;
      if (deadline != null && anchor.daysUntil(deadline) >= 7) {
        final wanted = ceiling / (anchor.daysUntil(deadline) / 7);
        rate = wanted > cap ? cap : wanted;
      } else {
        rate = cap;
      }
    }
    final gain = rate * weeks;
    return gain > ceiling ? ceiling : gain;
  }

  /// 1RM de charge totale (charge externe + part du poids de corps) de
  /// l'exercice [id], ou `null`.
  double? totalOneRm(String id) {
    final external = oneRm[id];
    final e = catalog.find(id);
    if (external == null || e == null) {
      return null;
    }
    return external + (e.bodyweightFraction?.value ?? 0) * bodyWeight;
  }

  /// Raison qui écarte l'exercice [id] le jour [day], ou `null` s'il est
  /// admissible. Codes : `unknown`, `excluded`, `equipment`, `joint`,
  /// `level`, `prerequisite`, `technique`, `impact`.
  String? rejection(String id, int day) {
    final e = catalog.find(id);
    if (e == null) {
      return 'unknown';
    }
    if (excluded.contains(id)) {
      return 'excluded';
    }
    final info = days[day];
    final place = info.place;
    final placeOk = place == null
        ? e.places.any(profile.places.contains)
        : e.places.contains(place);
    if (!placeOk || !e.feasibleWith(info.equipment)) {
      return 'equipment';
    }
    for (final l in limits) {
      final joint = l.joint;
      if (joint == null) {
        continue;
      }
      final stress = e.stressOn(joint);
      if ((stress == JointStress.high && l.discomfort >= 4) ||
          (stress != JointStress.low && l.discomfort >= 6)) {
        return 'joint';
      }
    }
    final isKnown = known.contains(id);
    if (!isKnown && e.level.index > level + 1) {
      return 'level';
    }
    for (final missing in notAcquired) {
      final harder =
          e.rootId == missing.rootId &&
          !e.assisted &&
          e.difficulty >= missing.difficulty;
      if (e.id == missing.id ||
          harder ||
          e.prerequisites.contains(missing.id)) {
        return 'prerequisite';
      }
    }
    if (level < 2 &&
        (id.contains('supramaximal') ||
            id.contains('partielle-haute') ||
            id.contains('partiel-haut') ||
            id.contains('partiel-surcharge') ||
            id.contains('isometrie-lestee'))) {
      return 'technique';
    }
    if (level < 1 && id.contains('chaines')) {
      return 'technique';
    }
    final t = traits.of(id);
    if (allImpactBanned && t.impact) {
      return 'impact';
    }
    if (heavyImpactBanned &&
        (e.pattern == MovementPattern.pliometrie ||
            e.pattern == MovementPattern.cordeASauter ||
            e.pattern == MovementPattern.balistique ||
            e.pattern == MovementPattern.halterophilie)) {
      return 'impact';
    }
    return null;
  }

  /// Vrai si l'exercice [id] est admissible le jour [day].
  bool can(String id, int day) => rejection(id, day) == null;

  /// Premier exercice admissible de [candidates] le jour [day], ou `null`.
  String? pick(List<String> candidates, int day) {
    for (final id in candidates) {
      if (can(id, day)) {
        return id;
      }
    }
    return null;
  }
}
