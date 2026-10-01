/// Passe 2 (D4.7) : séries, plages, flammes visées, repos et charges de
/// départ, semaine par semaine. Justifications : `CONTRAT.md`,
/// § Prescription.
library;

import 'package:kalis_core/kalis_core.dart';

import 'assemble.dart';
import 'context.dart';
import 'params.dart';
import 'scheme.dart';
import 'score.dart';
import 'state.dart';
import 'traits.dart';
import 'version.dart';

/// Part des séries de référence faites en semaine d'introduction.
const double introVolumeFactor = 0.75;

/// Part des séries de référence faites la première semaine de montée ; la
/// dernière en fait 100 %.
const double buildStartVolumeFactor = 0.85;

/// Part des séries de référence faites en semaine de décharge ou de test.
const double deloadVolumeFactor = 0.6;

/// Répétitions en réserve ajoutées en semaine d'introduction.
const double introRirBonus = 1;

/// Répétitions en réserve ajoutées en semaine de décharge.
const double deloadRirBonus = 2;

/// Nature de chaque semaine d'un bloc de [weeks] semaines.
///
/// Première semaine : introduction. Dernière : test s'il y a un objectif
/// de performance (et que le programme n'est pas prudent), sinon décharge
/// à partir du niveau intermédiaire, sinon montée. Les autres : montée.
List<WeekKind> weekKindsFor({
  required int weeks,
  required int level,
  required bool hasPerformanceGoal,
  required bool cautious,
}) {
  final out = <WeekKind>[];
  for (var w = 0; w < weeks; w++) {
    if (w == 0 && weeks > 1) {
      out.add(WeekKind.intro);
    } else if (w == weeks - 1 && weeks > 2) {
      if (hasPerformanceGoal && !cautious) {
        out.add(WeekKind.test);
      } else if (level >= 1) {
        out.add(WeekKind.deload);
      } else {
        out.add(WeekKind.build);
      }
    } else {
      out.add(WeekKind.build);
    }
  }
  return out;
}

/// Durée par défaut d'un bloc, en semaines, selon le niveau (D4.8 : 4 à 6).
int defaultBlockWeeks(int level) => level <= 0 ? 4 : (level == 1 ? 5 : 6);

/// Pas et minimum de charge par défaut d'un type de charge, en kg.
(double, double) defaultIncrement(LoadType type) {
  switch (type) {
    case LoadType.barbell:
      return (2.5, 20);
    case LoadType.dumbbells:
      return (2, 2);
    case LoadType.kettlebell:
      return (4, 4);
    case LoadType.machine:
      return (5, 5);
    case LoadType.cable:
      return (2.5, 2.5);
    case LoadType.addedWeight:
      return (1.25, 0);
    case LoadType.none:
    case LoadType.bodyweight:
    case LoadType.band:
    case LoadType.other:
      return (1, 0);
  }
}

double _roundDown(double value, double step) =>
    (value / step + 1e-9).floorToDouble() * step;

double _round(double v, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  return (v * scale).roundToDouble() / scale;
}

/// Règle les séries de référence de [state] (exercices fixés) : d'abord
/// pour tenir dans le temps de chaque séance, puis, une série à la fois,
/// tant que la note s'améliore (volume par muscle, temps utilisé, dosage,
/// équilibre, récupération).
void tuneSets(PlanContext ctx, Scorer scorer, PlanState state) {
  final pool = ctx.pool;
  for (var d = 0; d < ctx.dayCount; d++) {
    while (scorer.timeOfDay(state, d) > ctx.days[d].seconds) {
      var at = -1;
      var most = 0;
      for (var i = 0; i < state.count[d]; i++) {
        final spare =
            state.sets[d][i] - pool[state.exercise[d][i]].scheme.minSets;
        if (spare > most) {
          most = spare;
          at = i;
        }
      }
      if (at < 0) {
        break;
      }
      state.sets[d][at]--;
    }
  }
  var current = scorer.evaluate(state);
  final limit = 4 * state.slotCount + 8;
  for (var step = 0; step < limit; step++) {
    var bestDay = -1;
    var bestAt = -1;
    var bestDelta = 0;
    var bestValue = current;
    for (var d = 0; d < ctx.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        final scheme = pool[state.exercise[d][i]].scheme;
        final sets = state.sets[d][i];
        for (final delta in const <int>[1, -1]) {
          final next = sets + delta;
          if (next < scheme.minSets || next > scheme.maxSets) {
            continue;
          }
          state.sets[d][i] = next;
          if (delta < 0 || scorer.timeOfDay(state, d) <= ctx.days[d].seconds) {
            final value = scorer.evaluate(state);
            if (value > bestValue + 1e-9) {
              bestValue = value;
              bestDay = d;
              bestAt = i;
              bestDelta = delta;
            }
          }
          state.sets[d][i] = sets;
        }
      }
    }
    if (bestDay < 0) {
      break;
    }
    state.sets[bestDay][bestAt] += bestDelta;
    current = bestValue;
  }
}

/// Construit la passe 2 du programme [pass1] déjà converti en [state]
/// (séries de référence réglées par [tuneSets]).
Pass2Plan buildPass2(
  PlanContext ctx,
  Scorer scorer,
  PlanState state,
  Pass1Plan pass1,
) {
  final params = ctx.params;
  final profile = ctx.profile;
  var explicitGoal = false;
  for (final g in ctx.goals) {
    if (g.goalId != null) {
      explicitGoal = true;
    }
  }
  final kinds = weekKindsFor(
    weeks: pass1.weeks,
    level: ctx.globalLevel,
    hasPerformanceGoal: explicitGoal,
    cautious: ctx.cautious,
  );
  var buildWeeks = 0;
  for (final k in kinds) {
    if (k == WeekKind.build) {
      buildWeeks++;
    }
  }

  // Emplacement de test de chaque objectif : l'exercice de l'objectif s'il
  // est au programme, sinon son meilleur palier.
  final testGoalOfSlot = <String, int>{};
  final ordered = <List<OrderedSlot>>[
    for (var d = 0; d < ctx.dayCount; d++) orderedDay(ctx, state, d),
  ];
  String slotIdOf(int day, OrderedSlot s) => state.slotIds[s.identity];
  for (var j = 0; j < ctx.goals.length; j++) {
    if (ctx.goals[j].goalId == null) {
      continue;
    }
    var best = 69;
    String? bestSlot;
    for (var d = 0; d < ctx.dayCount; d++) {
      for (final s in ordered[d]) {
        final support = s.entry.goalSupport[j];
        if (support > best) {
          best = support;
          bestSlot = slotIdOf(d, s);
        }
      }
    }
    if (bestSlot != null && !testGoalOfSlot.containsKey(bestSlot)) {
      testGoalOfSlot[bestSlot] = j;
    }
  }

  final increments = <LoadType, LoadIncrement>{
    for (final inc in profile.loadIncrements) inc.loadType: inc,
  };
  final weeksOut = <WeekPrescription>[];
  var buildRank = 0;
  for (var w = 0; w < kinds.length; w++) {
    final kind = kinds[w];
    double factor;
    double rirBonus;
    var lastBuild = false;
    switch (kind) {
      case WeekKind.intro:
        factor = introVolumeFactor;
        rirBonus = introRirBonus;
      case WeekKind.build:
        buildRank++;
        final progress = buildWeeks <= 1 ? 1.0 : buildRank / buildWeeks;
        factor = buildWeeks <= 1
            ? 1.0
            : buildStartVolumeFactor + (1 - buildStartVolumeFactor) * progress;
        final behind = (buildWeeks - buildRank) * 0.5;
        rirBonus = behind > 1 ? 1 : behind;
        lastBuild = buildRank == buildWeeks && buildWeeks >= 2;
      case WeekKind.deload:
      case WeekKind.test:
        factor = deloadVolumeFactor;
        rirBonus = deloadRirBonus;
    }
    final daysOut = <DayPrescription>[];
    for (var d = 0; d < ctx.dayCount; d++) {
      final items = <ExercisePrescription>[];
      var conditioning = 0;
      for (final s in ordered[d]) {
        if (s.entry.kind == SlotKind.conditioning) {
          conditioning++;
        }
      }
      for (final s in ordered[d]) {
        final slotId = slotIdOf(d, s);
        final goalIndex = kind == WeekKind.test ? testGoalOfSlot[slotId] : null;
        final group = s.entry.kind == SlotKind.conditioning && conditioning >= 2
            ? 'wod-d$d'
            : null;
        items.add(
          goalIndex != null
              ? _testItem(ctx, s, slotId, ctx.goals[goalIndex], increments)
              : _workItem(
                  ctx,
                  s,
                  slotId,
                  kind: kind,
                  weekIndex: w,
                  factor: factor,
                  rirBonus: rirBonus,
                  lastBuild: lastBuild,
                  groupId: group,
                  increments: increments,
                  params: params,
                ),
        );
      }
      daysOut.add(DayPrescription(dayIndex: d, items: items));
    }
    weeksOut.add(WeekPrescription(weekIndex: w, kind: kind, days: daysOut));
  }

  final seen = <WeekKind>{};
  final reasons = <Reason>[
    if (ctx.cautious) reason(ReasonCodes.planCautiousHealth),
    for (final k in kinds)
      if (seen.add(k))
        reason(ReasonCodes.planWeekKind, <String, Object?>{'kind': k.code}),
  ];
  return Pass2Plan(
    blockId: pass1.blockId,
    engineVersion: kalisPlanVersion,
    weeks: weeksOut,
    reasons: reasons,
  );
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

/// Charge externe de départ pour [reps] répétitions à [rir] répétitions en
/// réserve, ou `null` si elle ne peut pas être déduite. Rend aussi la part
/// du 1RM visée (repère), ou `null` au-delà du domaine de la formule.
(double?, double?) startLoad({
  required PoolEntry entry,
  required int reps,
  required double rir,
  required double? bodyWeightKg,
  required LoadIncrement? increment,
  required PlanParams params,
}) {
  final toFailure = reps + rir;
  if (!entry.scheme.loaded || toFailure > params.maxEpleyReps) {
    return (null, null);
  }
  final share = 1 / (1 + toFailure / params.epleyDivisor);
  final oneRm = entry.oneRmTotalKg;
  if (oneRm == null) {
    return (null, share);
  }
  final e = entry.exercise;
  final fraction = e.bodyweightFraction?.value ?? 0;
  if (fraction > 0 && bodyWeightKg == null) {
    return (null, share);
  }
  final prudence = entry.oneRmEstimated
      ? params.startLoadFractionEstimated
      : params.startLoadFraction;
  final external = oneRm * share * prudence - fraction * (bodyWeightKg ?? 0);
  final (defaultStep, defaultMin) = defaultIncrement(e.loadType);
  final step = increment?.stepKg ?? defaultStep;
  final least = increment?.minKg ?? defaultMin;
  var load = _roundDown(external, step);
  if (load < least) {
    load = least;
  }
  if (load < 0) {
    load = 0;
  }
  return (_round(load, 2), share);
}

ExercisePrescription _workItem(
  PlanContext ctx,
  OrderedSlot s,
  String slotId, {
  required WeekKind kind,
  required int weekIndex,
  required double factor,
  required double rirBonus,
  required bool lastBuild,
  required String? groupId,
  required Map<LoadType, LoadIncrement> increments,
  required PlanParams params,
}) {
  final entry = s.entry;
  final e = entry.exercise;
  final scheme = entry.scheme;
  final reasons = <Reason>[
    reason(ReasonCodes.planWeekKind, <String, Object?>{'kind': kind.code}),
  ];
  var count = (s.sets * factor).round();
  if (count < 1) {
    count = 1;
  }
  if (count > s.sets) {
    count = s.sets;
  }
  final light = kind == WeekKind.deload || kind == WeekKind.test;
  if (!light && count < scheme.minSets && scheme.minSets <= s.sets) {
    count = scheme.minSets;
  }

  int? flames;
  double? rir;
  final baseRir = scheme.rir;
  if (baseRir != null) {
    rir = baseRir + rirBonus;
    if (rir > 5) {
      rir = 5;
    }
    flames = Flames.fromRir(rir);
  }

  if (scheme.continuous) {
    final seconds = count * Scheme.continuousUnitSeconds;
    final low = (seconds * 9) ~/ 10;
    return ExercisePrescription(
      slotId: slotId,
      exerciseId: e.id,
      sets: 1,
      secondsLow: low < 1 ? 1 : low,
      secondsHigh: seconds,
      restSeconds: 0,
      toCalibrate: false,
      loadBasis: LoadBasis.unloaded,
      format: scheme.format,
      reasons: reasons,
    );
  }

  final resistance = entry.kind.isResistance;
  final basis = _basisOf(e);
  switch (scheme.unit) {
    case MeasureUnit.repetitions:
      var low = scheme.low;
      var high = scheme.high;
      if (lastBuild && scheme.kind == SchemeKind.strengthMain && low > 1) {
        low--;
        high--;
      }
      double? load;
      double? share;
      if (rir != null) {
        (load, share) = startLoad(
          entry: entry,
          reps: high,
          rir: rir,
          bodyWeightKg: ctx.profile.bodyWeightKg,
          increment: increments[e.loadType],
          params: params,
        );
      }
      final calibrate = resistance && !entry.oneRmEstimated;
      if (load != null) {
        reasons.add(
          reason(ReasonCodes.planStartLoadConservative, <String, Object?>{
            'fractionOfEstimate': entry.oneRmEstimated
                ? params.startLoadFractionEstimated
                : params.startLoadFraction,
          }),
        );
      }
      if (calibrate) {
        reasons.add(reason(ReasonCodes.planToCalibrate));
      }
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: count,
        repsLow: low,
        repsHigh: high,
        targetFlames: flames,
        restSeconds: scheme.restSeconds,
        startLoadKg: basis == LoadBasis.unloaded ? null : load,
        percentOfOneRm: share == null ? null : _round(share, 3),
        toCalibrate: calibrate,
        loadBasis: basis,
        groupId: groupId,
        format: scheme.format,
        kind: calibrate && scheme.loaded && load == null && weekIndex == 0
            ? SetKind.calibration
            : null,
        reasons: reasons,
      );
    case MeasureUnit.seconds:
      final calibrate = resistance && !entry.oneRmEstimated;
      if (calibrate) {
        reasons.add(reason(ReasonCodes.planToCalibrate));
      }
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: count,
        secondsLow: scheme.low < 1 ? 1 : scheme.low,
        secondsHigh: scheme.high < 1 ? 1 : scheme.high,
        targetFlames: flames,
        restSeconds: scheme.restSeconds,
        toCalibrate: calibrate,
        loadBasis: basis,
        groupId: groupId,
        format: scheme.format,
        reasons: reasons,
      );
    case MeasureUnit.distance:
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: count,
        distanceMeters: scheme.distanceMeters ?? 0,
        targetFlames: flames,
        restSeconds: scheme.restSeconds,
        toCalibrate: false,
        loadBasis: basis,
        groupId: groupId,
        format: scheme.format,
        reasons: reasons,
      );
    case MeasureUnit.calories:
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: count,
        calories: scheme.calories ?? 0,
        targetFlames: flames,
        restSeconds: scheme.restSeconds,
        toCalibrate: false,
        loadBasis: basis,
        groupId: groupId,
        format: scheme.format,
        reasons: reasons,
      );
  }
}

/// Séance de test (« boss ») de l'objectif [goal] sur l'emplacement [s].
ExercisePrescription _testItem(
  PlanContext ctx,
  OrderedSlot s,
  String slotId,
  GoalTarget goal,
  Map<LoadType, LoadIncrement> increments,
) {
  final entry = s.entry;
  final e = entry.exercise;
  final basis = _basisOf(e);
  final reasons = <Reason>[
    reason(ReasonCodes.planWeekKind, <String, Object?>{
      'kind': WeekKind.test.code,
    }),
    reason(ReasonCodes.planGoalSupport, <String, Object?>{
      'goalId': goal.goalId,
    }),
  ];
  final exact = goal.exercise.id == e.id;
  final metric = exact ? goal.goal?.metric : null;
  final target = goal.goal?.targetValue;
  if (metric == GoalMetric.oneRmKg && e.unit == MeasureUnit.repetitions) {
    // Montée vers une série unique lourde, une répétition en réserve : le
    // moteur dynamique en déduit le 1RM sans tentative maximale.
    final oneRm = entry.oneRmTotalKg;
    final bw = ctx.profile.bodyWeightKg;
    final fraction = e.bodyweightFraction?.value ?? 0;
    double? loadAt(double share) {
      if (oneRm == null || (fraction > 0 && bw == null)) {
        return null;
      }
      final (defaultStep, defaultMin) = defaultIncrement(e.loadType);
      final inc = increments[e.loadType];
      final step = inc?.stepKg ?? defaultStep;
      final least = inc?.minKg ?? defaultMin;
      var load = _roundDown(oneRm * share - fraction * (bw ?? 0), step);
      if (load < least) {
        load = least;
      }
      return _round(load < 0 ? 0 : load, 2);
    }

    return ExercisePrescription(
      slotId: slotId,
      exerciseId: e.id,
      sets: 3,
      repsLow: 1,
      repsHigh: 3,
      targetFlames: 9,
      restSeconds: 240,
      toCalibrate: false,
      loadBasis: basis,
      setTargets: <SetTarget>[
        SetTarget(repsLow: 3, repsHigh: 3, loadKg: loadAt(0.8), flames: 5),
        SetTarget(repsLow: 1, repsHigh: 1, loadKg: loadAt(0.9), flames: 7),
        SetTarget(repsLow: 1, repsHigh: 1, loadKg: loadAt(0.96), flames: 9),
      ],
      kind: SetKind.test,
      reasons: reasons,
    );
  }
  switch (e.unit) {
    case MeasureUnit.repetitions:
      var high = entry.scheme.high * 2;
      if (metric == GoalMetric.maxReps && target != null && target > high) {
        high = target.ceil();
      }
      if (metric == GoalMetric.skillUnlocked) {
        return ExercisePrescription(
          slotId: slotId,
          exerciseId: e.id,
          sets: 3,
          repsLow: 1,
          repsHigh: 1,
          targetFlames: 9,
          restSeconds: 180,
          toCalibrate: false,
          loadBasis: basis,
          kind: SetKind.test,
          reasons: reasons,
        );
      }
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: 1,
        repsLow: 1,
        repsHigh: high < 1 ? 1 : (high > 1000 ? 1000 : high),
        targetFlames: 10,
        restSeconds: 180,
        toCalibrate: false,
        loadBasis: basis,
        kind: SetKind.test,
        reasons: reasons,
      );
    case MeasureUnit.seconds:
      if (entry.scheme.continuous) {
        final distance = goal.goal?.distanceMeters;
        if (metric == GoalMetric.timeSeconds && distance != null) {
          return ExercisePrescription(
            slotId: slotId,
            exerciseId: e.id,
            sets: 1,
            distanceMeters: distance,
            restSeconds: 0,
            toCalibrate: false,
            loadBasis: LoadBasis.unloaded,
            kind: SetKind.test,
            reasons: reasons,
          );
        }
        var seconds = s.sets * Scheme.continuousUnitSeconds;
        final duration = goal.goal?.durationSeconds;
        if (metric == GoalMetric.distanceMeters && duration != null) {
          seconds = duration;
        } else if (metric == GoalMetric.timeSeconds &&
            target != null &&
            target >= 60) {
          seconds = target.round();
        }
        if (seconds > 86400) {
          seconds = 86400;
        }
        return ExercisePrescription(
          slotId: slotId,
          exerciseId: e.id,
          sets: 1,
          secondsLow: seconds,
          secondsHigh: seconds,
          restSeconds: 0,
          toCalibrate: false,
          loadBasis: LoadBasis.unloaded,
          format: entry.scheme.format,
          kind: SetKind.test,
          reasons: reasons,
        );
      }
      var high = entry.scheme.high * 2;
      if (metric == GoalMetric.maxHoldSeconds &&
          target != null &&
          target > high) {
        high = target.ceil();
      }
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: 2,
        secondsLow: 1,
        secondsHigh: high < 1 ? 1 : (high > 86400 ? 86400 : high),
        targetFlames: 10,
        restSeconds: 180,
        toCalibrate: false,
        loadBasis: basis,
        kind: SetKind.test,
        reasons: reasons,
      );
    case MeasureUnit.distance:
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: 1,
        distanceMeters:
            goal.goal?.distanceMeters ?? entry.scheme.distanceMeters ?? 0,
        restSeconds: 0,
        toCalibrate: false,
        loadBasis: basis,
        kind: SetKind.test,
        reasons: reasons,
      );
    case MeasureUnit.calories:
      return ExercisePrescription(
        slotId: slotId,
        exerciseId: e.id,
        sets: 1,
        calories: entry.scheme.calories ?? 0,
        restSeconds: 0,
        toCalibrate: false,
        loadBasis: basis,
        kind: SetKind.test,
        reasons: reasons,
      );
  }
}
