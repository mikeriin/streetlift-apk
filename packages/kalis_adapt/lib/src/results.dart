/// Résultats de tests, repères d'entraînement et volume toléré : ce que le
/// moteur rend à l'application (`AdaptReview.testResults`) et au moteur
/// statique (`AdaptationSummary.benchmarks`, `volumeTolerance`).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show MuscleGroup;

import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'replay.dart';
import 'review.dart' show weekOfDay;

Reason _r(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

bool _isTest(SetRecord set) =>
    set.kind == SetKind.test ||
    set.role == SetRole.test ||
    set.role == SetRole.attempt;

/// Résultat de chaque test du journal [log] jusqu'au jour [untilDay] : par
/// séance et par exercice, la meilleure ligne de test menée à bien (plus
/// forte charge, plus de répétitions, plus long maintien). Les 200 plus
/// récents.
/// Valeur d'un repère pour la comparaison à un repère du même exercice
/// et de la même nature (lest, répétitions ou secondes).
double _benchmarkValue(Benchmark b) => switch (b.kind) {
  BenchmarkKind.maxReps => (b.reps ?? 0).toDouble(),
  BenchmarkKind.maxHold => (b.seconds ?? 0).toDouble(),
  _ => b.externalLoadKg ?? 0,
};

/// Vrai si le repère [b] est sous le meilleur repère connu du même
/// exercice et de la même nature parmi [known].
bool _below(Benchmark b, List<Benchmark> known) {
  for (final k in known) {
    // Repères chargés : comparés à répétitions égales seulement.
    if (k.exerciseId == b.exerciseId &&
        k.kind == b.kind &&
        (b.kind != BenchmarkKind.loadReps || k.reps == b.reps) &&
        _benchmarkValue(k) > _benchmarkValue(b)) {
      return true;
    }
  }
  return false;
}

List<Benchmark> testBenchmarks(
  EngineContext ctx,
  TrainingLog log,
  int untilDay,
) {
  final p = ctx.params;
  final out = <Benchmark>[];
  for (final session in log.countedSessions) {
    if (session.date.dayNumber > untilDay) {
      continue;
    }
    final best = <String, SetRecord>{};
    final order = <String>[];
    for (final set in session.sets) {
      if (!set.isUsable || !_isTest(set) || !set.success) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      final mode = info?.mode;
      if (info == null || mode == null) {
        continue;
      }
      final old = best[set.exerciseId];
      bool better;
      if (old == null) {
        better = true;
        order.add(set.exerciseId);
      } else if (mode == CapacityMode.loaded) {
        final a = set.externalLoadKg ?? 0;
        final b = old.externalLoadKg ?? 0;
        better = a > b || (a == b && (set.reps ?? 0) > (old.reps ?? 0));
      } else if (mode == CapacityMode.hold) {
        better = (set.seconds ?? 0) > (old.seconds ?? 0);
      } else {
        better = (set.reps ?? 0) > (old.reps ?? 0);
      }
      if (better) {
        best[set.exerciseId] = set;
      }
    }
    final source = session.eventId != null
        ? BenchmarkSource.competition
        : BenchmarkSource.guidedTest;
    final found = <Benchmark>[];
    for (final id in order) {
      final set = best[id]!;
      final mode = ctx.book.find(id)!.mode!;
      final flames = set.flames;
      switch (mode) {
        case CapacityMode.loaded:
          final reps = set.reps;
          if (reps == null || reps < 1) {
            continue;
          }
          found.add(
            Benchmark(
              exerciseId: id,
              kind: BenchmarkKind.loadReps,
              source: source,
              date: session.date,
              externalLoadKg: set.externalLoadKg ?? 0,
              reps: reps,
              // Une tentative ne se lit pas comme une réserve mesurée.
              rir:
                  flames == null ||
                      flames == Flames.min ||
                      set.role == SetRole.attempt
                  ? null
                  : rirOfFlames(flames),
              bodyWeightKg: bodyWeightOf(session, ctx.profile, p),
              competitionStandard: set.role == SetRole.attempt ? true : null,
            ),
          );
        case CapacityMode.reps:
          final reps = set.reps;
          if (reps == null || reps < 1) {
            continue;
          }
          found.add(
            Benchmark(
              exerciseId: id,
              kind: BenchmarkKind.maxReps,
              source: source,
              date: session.date,
              reps: reps,
            ),
          );
        case CapacityMode.hold:
          final seconds = set.seconds;
          if (seconds == null || seconds < 1) {
            continue;
          }
          found.add(
            Benchmark(
              exerciseId: id,
              kind: BenchmarkKind.maxHold,
              source: source,
              date: session.date,
              seconds: seconds,
            ),
          );
      }
    }
    // Test fait un jour de bilan nettement bas, hors compétition : il ne
    // fait pas baisser le repère (un coach refait le test un bon jour) ;
    // un résultat au niveau du repère connu, ou au-dessus, est gardé.
    final lowDay =
        session.eventId == null &&
        readHealth(session.healthCheck, p).level >= 2;
    for (final b in found) {
      if (lowDay && _below(b, <Benchmark>[...?ctx.profile.benchmarks, ...out])) {
        continue;
      }
      out.add(b);
    }
  }
  return out.length > 200 ? out.sublist(out.length - 200) : out;
}

/// Repères tirés des séries d'entraînement des 42 derniers jours : pour
/// chaque exercice chargé, la série courte et proche de l'échec qui
/// implique le plus fort 1RM (R2-P5 : séries courtes seulement).
List<Benchmark> trainingBenchmarks(
  EngineContext ctx,
  TrainingLog log,
  int day,
) {
  final p = ctx.params;
  final best = <String, (double, Benchmark)>{};
  for (final session in log.countedSessions) {
    final when = session.date.dayNumber;
    if (when > day || day - when > p.attemptRecentDays) {
      continue;
    }
    final bw = bodyWeightOf(session, ctx.profile, p);
    for (final set in session.sets) {
      final reps = set.reps;
      final flames = set.flames;
      if (!set.isUsable ||
          set.kind == SetKind.warmup ||
          _isTest(set) ||
          set.parts != null ||
          !set.success ||
          reps == null ||
          reps < 1 ||
          reps > p.trainingSetMaxReps ||
          flames == null) {
        continue;
      }
      final rir = rirOfFlames(flames);
      if (flames == Flames.min || rir > p.trainingSetMaxRir) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      if (info == null || info.mode != CapacityMode.loaded) {
        continue;
      }
      final total = info.totalLoad(set.externalLoadKg ?? 0, bw);
      if (total <= 0) {
        continue;
      }
      final k = info.lowerBody ? p.kLowerBody : p.kGeneral;
      final implied = total * (1 + (reps + rir - 1) / k);
      final old = best[info.id];
      if (old == null || implied > old.$1) {
        best[info.id] = (
          implied,
          Benchmark(
            exerciseId: info.id,
            kind: BenchmarkKind.loadReps,
            source: BenchmarkSource.trainingSet,
            date: session.date,
            externalLoadKg: set.externalLoadKg ?? 0,
            reps: reps,
            rir: rir,
            bodyWeightKg: bw,
          ),
        );
      }
    }
  }
  final ids = best.keys.toList()..sort();
  return <Benchmark>[for (final id in ids) best[id]!.$2];
}

/// Raisons `adapt.test_result` des tests des 14 derniers jours : maximum
/// estimé après le test (charge externe, répétitions ou secondes) et son
/// écart-type.
List<Reason> testResultReasons(
  EngineContext ctx,
  ModelState state,
  List<Benchmark> tests,
  int day,
) {
  final seen = <String>{};
  final out = <Reason>[];
  final bw = ctx.profile.bodyWeightKg ?? ctx.params.referenceBodyWeightKg;
  for (final b in tests.reversed) {
    final date = b.date;
    if (date == null || day - date.dayNumber > 14 || !seen.add(b.exerciseId)) {
      continue;
    }
    final track = state.tracks[b.exerciseId];
    if (track == null) {
      continue;
    }
    final f = track.filter;
    final capacity = f.capacity;
    final value = f.mode == CapacityMode.loaded
        ? capacity - track.info.fraction * bw
        : capacity;
    out.add(
      _r(ReasonCodes.adaptTestResult, <String, Object?>{
        'exerciseId': b.exerciseId,
        'value': roundTo(value, 2),
        'standardError': roundTo(capacity * f.capacityRelSd, 2),
      }),
    );
  }
  return out;
}

/// Volume hebdomadaire toléré par groupe musculaire : plage des séries
/// fractionnées des semaines récentes dont les performances n'ont pas
/// baissé. Vide tant que [minWeeks] semaines de données ne sont pas là.
List<VolumeTolerance> volumeToleranceOf(
  EngineContext ctx,
  List<SessionDigest> digests,
  int day,
) {
  final p = ctx.params;
  final thisWeek = weekOfDay(day);
  final sets = <int, List<double>>{};
  final residualSum = <int, double>{};
  final residualCount = <int, int>{};
  for (final d in digests) {
    final week = weekOfDay(d.day);
    if (thisWeek - week > 8 || week > thisWeek || d.workSets == 0) {
      continue;
    }
    final row = sets.putIfAbsent(
      week,
      () => List<double>.filled(MuscleGroup.values.length, 0),
    );
    residualSum[week] = (residualSum[week] ?? 0) + d.residual;
    residualCount[week] = (residualCount[week] ?? 0) + 1;
    for (final set in d.session.sets) {
      if (!set.isUsable || set.kind == SetKind.warmup) {
        continue;
      }
      final info = ctx.book.find(set.exerciseId);
      if (info == null || info.mode == null) {
        continue;
      }
      for (var i = 0; i < info.groups.length; i++) {
        row[info.groups[i].index] += info.groupWeights[i];
      }
    }
  }
  final weeks = sets.keys.toList()..sort();
  if (weeks.length < p.toleranceMinWeeks) {
    return const <VolumeTolerance>[];
  }
  final out = <VolumeTolerance>[];
  for (final g in MuscleGroup.values) {
    if (!g.major) {
      continue;
    }
    double? low;
    double? high;
    var kept = 0;
    for (final week in weeks) {
      final value = sets[week]![g.index];
      final residual = residualSum[week]! / residualCount[week]!;
      if (value <= 0 || residual < -0.01) {
        continue;
      }
      kept++;
      if (low == null || value < low) {
        low = value;
      }
      if (high == null || value > high) {
        high = value;
      }
    }
    if (low == null || high == null || kept < p.toleranceMinWeeks) {
      continue;
    }
    out.add(
      VolumeTolerance(
        muscle: g.code,
        weeklySetsLow: roundTo(low, 1),
        weeklySetsHigh: roundTo(high, 1),
        confidence: roundTo(clampDouble(kept / 8, 0, 1), 3),
      ),
    );
  }
  return out;
}
