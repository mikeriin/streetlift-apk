/// Jour d'une échéance (`EventDayAdvisor`, kalis_core 0.4.0) : tentatives
/// d'une compétition de force — ouverture, deuxième, troisième barre selon
/// le maximum estimé et son incertitude — et rythme d'une épreuve de
/// répétitions. Règles et sources : `CONTRAT.md`, § 11.6.
library;

import 'package:kalis_core/kalis_core.dart';

import 'coach.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'replay.dart';
import 'session.dart' show reason;

/// Marches de la montée d'échauffement avant l'ouverture : part de la
/// charge totale de l'ouverture, répétitions, repos (choix raisonné :
/// volume décroissant, dernière marche proche de l'ouverture).
const List<(double, int, int)> warmupSteps = <(double, int, int)>[
  (0.50, 5, 120),
  (0.65, 3, 120),
  (0.78, 2, 150),
  (0.88, 1, 180),
  (0.94, 1, 240),
];

/// Plan du jour de l'échéance demandée par [request].
EventDayPlan buildEventDay(
  EngineContext ctx,
  BlockView view,
  Replayed replayed,
  EventDayRequest request,
) {
  final p = ctx.params;
  final input = request.input;
  final day = input.today.dayNumber;
  SeasonEvent? found;
  for (final e in input.profile.events ?? const <SeasonEvent>[]) {
    if (e.id == request.eventId) {
      found = e;
    }
  }
  final event = found;
  if (event == null) {
    throw ArgumentError.value(
      request.eventId,
      'eventId',
      'échéance inconnue du profil',
    );
  }
  final state = replayed.state.fork();
  final check = request.healthCheck;
  final health = readHealth(check, p);
  notePains(state, check, const <PainReport>[], day, p);
  final usual = bodyWeightOf(null, ctx.profile, p);
  final weighed = request.bodyWeightKg;
  final bodyWeight = weighed ?? usual;
  final run = SessionRun(
    ctx,
    state,
    day: day,
    health: health,
    bodyWeightKg: bodyWeight,
    noIncrease: health.level >= 1,
  );
  final readiness = readinessOf(health.shift + state.fatigue.globalShift(p), p);
  final reasons = <Reason>[
    reason(ReasonCodes.adaptReadiness, <String, Object?>{
      'readiness': roundTo(readiness, 3),
    }),
  ];
  // Pesée nettement sous le poids habituel : la force peut en souffrir.
  final cut = weighed != null && weighed < usual * 0.98;

  final lifts = <LiftAttempts>[];
  var confidenceSum = 0.0;
  var confidenceCount = 0;
  for (final lift in event.lifts ?? const <CompetitionLift>[]) {
    final info = ctx.book.find(lift.exerciseId);
    if (info == null || info.mode != CapacityMode.loaded) {
      continue;
    }
    final ex = run.begin(
      info,
      SlotSpec(
        low: 1,
        high: 1,
        rir: 0,
        sets: lift.attempts,
        restSeconds: 300,
        main: true,
        benchmarkOk: false,
        hasTarget: false,
        test: true,
      ),
      key: 'event|${lift.exerciseId}',
    );
    final done = <(double, bool)>[];
    for (final a in request.done) {
      if (a.exerciseId != lift.exerciseId) {
        continue;
      }
      done.add((a.loadKg, a.success));
      // Une barre refusée pour la technique ou par l'arbitre ne dit rien
      // de la force.
      final strength = a.success || a.failure != AttemptFailure.technique;
      final judged = !a.success && a.failure == AttemptFailure.judging;
      if (strength && !judged) {
        run.observe(
          loadKg: a.loadKg,
          amount: a.success ? 1 : 0,
          flames: null,
          missed: !a.success,
          target: null,
          test: true,
          role: SetRole.attempt,
        );
      }
    }
    final track = ex.track;
    if (track == null || done.length >= lift.attempts) {
      lifts.add(
        LiftAttempts(
          exerciseId: lift.exerciseId,
          attempts: const <AttemptSuggestion>[],
        ),
      );
      continue;
    }
    final f = track.filter;
    final bodyPart = info.fraction * bodyWeight;
    // (Après un affûtage, le maximum du jour compte son gain : CA2,
    // partie 0 ; Travis et al. 2020.)
    // (Avant la première barre seulement : relecture indépendante du code,
    // CA2.)
    final gain = view.taperedAt(day) && done.isEmpty
        ? 1 + p.coachTaperGain
        : 1.0;
    final estimate = exp(f.m[0] + f.m[3] + f.gRef) * gain;
    final relSd = f.loadSd(1);
    final picks = attemptLadder(
      estimateTotal: estimate,
      relSd: relSd,
      bodyPart: bodyPart,
      grid: info.grid,
      attempts: lift.attempts,
      done: done,
      recentBest: recentHeavy(track, run.day, p),
      targetKg: lift.targetKg,
      objective: request.objective,
      healthLevel: health.level,
      prudentCause: ex.painZones.isNotEmpty
          ? 'pain'
          : (cut ? 'weigh_in' : null),
      p: p,
      minIncrementKg: lift.minIncrementKg,
    );
    final attempts = <AttemptSuggestion>[];
    for (final pick in picks) {
      final cause = pick.cause;
      attempts.add(
        AttemptSuggestion(
          index: pick.index,
          loadKg: roundTo(pick.loadKg, 2),
          successProbability: roundTo(pick.probability, 3),
          reasons: <Reason>[
            if (pick.index == 0)
              reason(ReasonCodes.adaptAttemptOpener, <String, Object?>{
                'pct': roundTo(pick.share, 3),
              })
            else
              reason(ReasonCodes.adaptAttemptNext, <String, Object?>{
                'successProbability': roundTo(pick.probability, 3),
              }),
            if (cause != null)
              reason(ReasonCodes.adaptAttemptConservative, <String, Object?>{
                'cause': cause,
              }),
          ],
        ),
      );
    }
    List<WarmupStep>? warmup;
    if (done.isEmpty && picks.isNotEmpty) {
      final opener = picks.first.loadKg;
      final steps = <WarmupStep>[];
      for (final (share, reps, rest) in warmupSteps) {
        final wanted = share * (opener + bodyPart) - bodyPart;
        final kg = info.grid.floor(
          wanted < info.grid.minimum ? info.grid.minimum : wanted,
        );
        if (kg >= opener - 1e-9) {
          continue;
        }
        if (steps.isNotEmpty && (steps.last.loadKg - kg).abs() < 1e-9) {
          steps.removeLast();
        }
        steps.add(
          WarmupStep(loadKg: roundTo(kg, 2), reps: reps, restSeconds: rest),
        );
      }
      warmup = steps.isEmpty ? null : steps;
    }
    lifts.add(
      LiftAttempts(
        exerciseId: lift.exerciseId,
        estimateKg: roundTo(estimate - bodyPart, 2),
        standardErrorKg: roundTo(estimate * relSd, 2),
        attempts: attempts,
        warmup: warmup,
      ),
    );
    confidenceSum += clampDouble(
      1 - f.loadSd(1, withDay: false) / (2 * p.calibrationSd),
      0,
      1,
    );
    confidenceCount++;
  }

  // Épreuve de répétitions : objectif et rythme par poste (R4-G7 : pas
  // d'échec avant la dernière série, première série à 60–70 % du maximum,
  // pauses courtes planifiées).
  final pacing = <PacingSegment>[];
  var total = 0;
  var seconds = 0;
  var timed = false;
  final stations = event.stations ?? const <EventStation>[];
  final rounds = event.rounds ?? 1;
  for (var i = 0; i < stations.length; i++) {
    final station = stations[i];
    final info = ctx.book.find(station.exerciseId);
    if (info == null || info.mode == null || info.mode == CapacityMode.hold) {
      continue;
    }
    final ex = run.begin(
      info,
      const SlotSpec(
        low: 1,
        high: 1,
        rir: 0,
        sets: 1,
        restSeconds: 60,
        main: true,
        benchmarkOk: false,
        hasTarget: false,
        test: true,
      ),
      key: 'station|$i|${station.exerciseId}',
    );
    if (ex.track == null) {
      continue;
    }
    final double capacity;
    if (info.mode == CapacityMode.loaded) {
      capacity = run.predictedReps(ex, station.externalLoadKg ?? 0, 0, 0);
    } else {
      capacity = run.predictedAmount(ex, 0, 0);
    }
    var most = capacity.floor();
    if (most < 1) {
      most = 1;
    }
    final imposed = station.reps;
    final limit = station.timeLimitSeconds ?? event.timeLimitSeconds;
    final sets = <int>[];
    var used = 0;
    if (imposed != null) {
      // Volume imposé : première série à la part prévue du maximum, puis
      // des séries de moitié, jusqu'au compte.
      var left = imposed;
      var size = (p.pacingFirstShare * most).floor();
      while (left > 0 && sets.length < 60) {
        if (size < 1) {
          size = 1;
        }
        final n = size > left ? left : size;
        sets.add(n);
        left -= n;
        used += n * p.repSeconds;
        if (left > 0) {
          used += p.pacingRestSeconds;
        }
        size = (p.pacingNextShare * size).floor();
      }
      timed = true;
    } else if (limit != null &&
        event.mode == RepsEventMode.maxRepsInTime &&
        station.unbroken != true) {
      var size = (p.pacingFirstShare * most).floor();
      while (sets.length < 60) {
        if (size < 1) {
          size = 1;
        }
        final cost =
            size * p.repSeconds + (sets.isEmpty ? 0 : p.pacingRestSeconds);
        if (used + cost > limit) {
          break;
        }
        sets.add(size);
        used += cost;
        size = (p.pacingNextShare * size).floor();
      }
      if (sets.isEmpty) {
        sets.add(1);
      }
    } else {
      // Maximum d'une traite : la capacité prudente du jour.
      sets.add(most);
      used = most * p.repSeconds;
    }
    var sum = 0;
    for (final n in sets) {
      sum += n;
    }
    total += sum * rounds;
    seconds += used * rounds;
    pacing.add(
      PacingSegment(
        exerciseId: station.exerciseId,
        setReps: sets,
        restSeconds: sets.length > 1 ? p.pacingRestSeconds : null,
        targetSeconds: imposed != null && used > 0 ? used : null,
        stationIndex: i,
      ),
    );
    confidenceSum += clampDouble(
      1 - ex.track!.filter.loadSd(1, withDay: false) / (2 * p.calibrationSd),
      0,
      1,
    );
    confidenceCount++;
  }
  if (pacing.isNotEmpty) {
    reasons.add(
      reason(ReasonCodes.adaptPacing, <String, Object?>{'targetReps': total}),
    );
  }
  run.closeAll();
  return EventDayPlan(
    eventId: event.id,
    lifts: lifts,
    pacing: pacing.isEmpty ? null : pacing,
    targetTotalReps: pacing.isEmpty ? null : total,
    targetSeconds: timed && seconds > 0 ? seconds : null,
    confidence: confidenceCount == 0
        ? 0.0
        : roundTo(confidenceSum / confidenceCount, 3),
    reasons: reasons,
  );
}
