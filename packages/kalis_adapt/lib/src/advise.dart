/// Conseil pour la série suivante : mise à jour après chaque série et
/// ajustement quand l'écart aux flammes visées atteint le seuil (D5).
library;

import 'package:kalis_core/kalis_core.dart';

import 'book.dart';
import 'coach.dart';
import 'coach_advice.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'params.dart';
import 'replay.dart';
import 'session.dart';
import 'skills.dart';

ExercisePrescription? _itemOf(SessionPlan session, String? slotId, String id) {
  if (slotId != null) {
    for (final it in session.items) {
      if (it.slotId == slotId) {
        return it;
      }
    }
  }
  for (final it in session.items) {
    if (it.exerciseId == id) {
      return it;
    }
  }
  return null;
}

/// Cibles de la séance pour l'exercice de la prescription [item].
List<SetPlan?> _plansOf(ExercisePrescription item, {required bool hold}) {
  final targets = item.setTargets;
  if (targets == null) {
    return <SetPlan?>[];
  }
  return <SetPlan?>[for (final t in targets) planOfTarget(t, hold: hold)];
}

/// Emplacement de [info] dans la séance en cours : la cible de base vient
/// du bloc (les bonus du jour sont rejoués par le modèle), le nombre de
/// séries de la séance du jour.
SlotSpec _specOf(
  BlockView view,
  SessionPlan session,
  ExerciseInfo info,
  ExercisePrescription? sessionItem,
  String? slotId,
  int day,
) {
  final ref = ProgramRef(
    blockId: session.blockId,
    weekIndex: session.weekIndex,
    dayIndex: session.dayIndex,
  );
  final kind = view.week(session.weekIndex)?.kind;
  final blockItem = slotId == null
      ? null
      : view.item(ref, slotId, sessionItem?.exerciseId ?? info.id);
  final base = view.specOf(
    info,
    blockItem != null && blockItem.slotId == slotId ? blockItem : sessionItem,
    kind,
    weekIndex: session.weekIndex,
    day: day,
  );
  final sets = sessionItem?.sets ?? base.sets;
  return SlotSpec(
    low: base.low,
    high: base.high,
    rir: base.rir,
    sets: sets,
    restSeconds: base.restSeconds,
    main: base.main,
    benchmarkOk: base.benchmarkOk,
    hasTarget: base.hasTarget,
    test: base.test,
    coach: base.coach,
    coachRead: base.coachRead,
  );
}

/// Conseil pour la série suivante de l'emplacement demandé par [request].
IntraSessionAdvice buildAdvice(
  EngineContext ctx,
  BlockView view,
  Replayed replayed,
  AdviceRequest request,
) {
  final p = ctx.params;
  final session = request.session;
  final day = request.input.today.dayNumber;
  final state = replayed.state.fork();
  final check = request.healthCheck;
  var health = readHealth(check, p);
  if (check == null) {
    // Appelant d'avant kalis_core 0.2.0 : le bilan du jour n'est pas
    // redonné. Les verrous de la séance sont relus dans ses raisons —
    // bilan bas (palier et forme du jour) et zones douloureuses.
    health = _healthOf(session, state, day, p);
    _painsOf(session, state, day, p);
  } else {
    notePains(state, check, const <PainReport>[], day, p);
  }
  final run = SessionRun(
    ctx,
    state,
    day: day,
    health: health,
    bodyWeightKg: bodyWeightOf(null, ctx.profile, p),
    extraRir: health.level * p.healthRirBonus,
    noIncrease: health.level >= 1,
  );
  final wanted = _itemOf(session, request.slotId, '');
  if (wanted == null) {
    throw ArgumentError.value(request.slotId, 'slotId', 'emplacement inconnu');
  }

  String? openKey;
  final bySlot = <String, ExerciseRun>{};
  for (final set in request.done) {
    if (!set.isUsable || set.kind == SetKind.warmup) {
      continue;
    }
    final info = ctx.book.find(set.exerciseId);
    if (info == null || info.mode == null) {
      continue;
    }
    final hold = info.mode == CapacityMode.hold;
    final item = _itemOf(session, set.slotId, set.exerciseId);
    final reading = readLine(set, hold: hold, item: item);
    if (reading != null && reading.skip) {
      continue;
    }
    final amount = reading?.amount ?? (hold ? set.seconds : set.reps);
    if (amount == null) {
      continue;
    }
    final loadKg = reading?.loadKg ?? set.externalLoadKg;
    if (info.mode == CapacityMode.loaded &&
        info.totalLoad(loadKg ?? 0, run.bodyWeightKg) <= 0) {
      continue;
    }
    final key = '${set.slotId ?? ''}|${set.exerciseId}|${set.exerciseOrder}';
    if (key != openKey) {
      openKey = key;
      final slot = item?.slotId ?? set.slotId;
      final exercise = run.begin(
        info,
        _specOf(view, session, info, item, slot, day),
        key: key,
      );
      if (item != null && exercise.observed.isEmpty) {
        exercise.plan = _plansOf(item, hold: hold);
      }
      if (slot != null) {
        bySlot[slot] = exercise;
      }
    }
    final exercise = run.current!;
    final index = exercise.observed.length;
    final target =
        planOfTarget(set.target, hold: hold) ??
        (index < exercise.plan.length ? exercise.plan[index] : null);
    final unclean = reading != null && reading.unclean;
    run.observe(
      loadKg: loadKg,
      amount: amount,
      flames: unclean ? Flames.failure : set.flames,
      missed: !set.success,
      target: target,
      test: set.kind == SetKind.test,
      boundOnly: reading != null && reading.boundOnly,
      quality: set.quality,
      role: set.role,
      lineAmount: hold ? set.seconds : set.reps,
    );
  }

  final info = ctx.book.find(wanted.exerciseId);
  final rest = wanted.restSeconds;
  // Le déroulement de l'emplacement demandé, même si d'autres exercices
  // ont été faits depuis (séries enchaînées).
  ExerciseRun? exercise = bySlot[wanted.slotId];
  if (exercise != null &&
      (exercise.observed.isEmpty || exercise.info.id != wanted.exerciseId)) {
    exercise = null;
  }
  if (exercise != null && exercise.closed) {
    // Le même exercice a été repris à un autre emplacement entre-temps :
    // le déroulement est rouvert avec ce qu'il a déjà vu.
    final again = run.begin(exercise.info, exercise.spec, key: exercise.key);
    if (!identical(again, exercise)) {
      again.observed.addAll(exercise.observed);
      again.plan = exercise.plan;
      again.fails = exercise.fails;
      again.ratedSets = exercise.ratedSets;
      again.easySets = exercise.easySets;
      again.lastRatedEasy = exercise.lastRatedEasy;
    }
    exercise = again;
  }
  if (info == null || info.mode == null) {
    return IntraSessionAdvice(
      exerciseId: wanted.exerciseId,
      action: IntraSessionAction.keep,
      slotId: wanted.slotId,
      restSeconds: rest,
      confidence: 0,
      reasons: const <Reason>[],
    );
  }
  final hold = info.mode == CapacityMode.hold;
  if (exercise == null) {
    // Aucune série encore faite à cet emplacement : la première cible de
    // la séance, telle quelle.
    final plans = _plansOf(wanted, hold: hold);
    final first = plans.isEmpty ? null : plans.first;
    return IntraSessionAdvice(
      exerciseId: wanted.exerciseId,
      action: IntraSessionAction.keep,
      nextLoadKg: first?.loadKg ?? wanted.startLoadKg,
      nextRepsLow: hold ? null : (first?.low ?? wanted.repsLow),
      nextRepsHigh: hold ? null : (first?.high ?? wanted.repsHigh),
      nextSeconds: hold ? (first?.high ?? wanted.secondsHigh) : null,
      slotId: wanted.slotId,
      restSeconds: rest,
      confidence: session.confidence,
      reasons: const <Reason>[],
    );
  }
  final track = exercise.track;
  final previous = exercise.observed.last;
  final index = exercise.observed.length;
  if (track == null) {
    return IntraSessionAdvice(
      exerciseId: wanted.exerciseId,
      action: IntraSessionAction.keep,
      slotId: wanted.slotId,
      restSeconds: rest,
      confidence: 0,
      reasons: const <Reason>[],
    );
  }
  final coached = exercise.spec.coach == null
      ? null
      : coachAdvise(
          run,
          exercise,
          index,
          wanted,
          SkillBoard.of(ctx, view, state, replayed.digests, day),
        );
  var (next, action) = coached == null
      ? run.advise(exercise, index)
      : (coached.next, coached.action);
  if (coached == null && exercise.spec.coach != null) {
    // Bloc au contrat 0.4.0 servi par la règle générale : mêmes verrous.
    final clamped = clampLocked(run, exercise, next);
    if (clamped != null) {
      next = clamped;
      action = IntraSessionAction.keep;
    }
  }
  final reasons = <Reason>[...?coached?.reasons];
  final previousTarget = previous.target;
  final rated = previous.flames;
  if (previous.failed && previous.unplannedFail) {
    final aimed = previousTarget?.high ?? previous.amount;
    final missing = aimed - previous.amount;
    reasons.add(
      reason(ReasonCodes.adaptSetFailed, <String, Object?>{
        'missingReps': missing < 0 ? 0 : missing,
      }),
    );
  } else if (rated == null) {
    reasons.add(
      reason(ReasonCodes.adaptNoRating, <String, Object?>{'sets': 1}),
    );
  } else if (previousTarget != null) {
    // Mode coach : deux notes au-delà du seuil « loin de l'échec » ne se
    // comparent pas (ni plus dur, ni plus facile que prévu).
    final far =
        exercise.spec.coach != null &&
        rirOfFlames(rated) >= run.state.rater.ceiling(p) &&
        rirOfFlames(previousTarget.flames) >= run.state.rater.ceiling(p);
    final delta = far ? 0 : rated - previousTarget.flames;
    // Mode coach : une note isolée plus dure sur une série menée au haut
    // de sa plage, que le modèle juge nettement plus facile que visé, ne
    // se dit pas « plus dure que prévu » (CX, correction 1).
    final doubtful =
        exercise.spec.coach != null &&
        previous.amount >= previousTarget.high &&
        previous.rir - rirOfFlames(previousTarget.flames) >= 2 &&
        delta < p.adviceGapFlames + 2;
    if (delta >= p.adviceGapFlames && !doubtful) {
      reasons.add(
        reason(ReasonCodes.adaptFlamesAboveTarget, <String, Object?>{
          'delta': delta.toDouble(),
          'sets': 1,
        }),
      );
    } else if (-delta >= p.adviceGapFlames) {
      reasons.add(
        reason(ReasonCodes.adaptFlamesBelowTarget, <String, Object?>{
          'delta': (-delta).toDouble(),
          'sets': 1,
        }),
      );
    }
  }
  final lastLoad = previous.loadKg;
  final nextLoad = next.loadKg;
  if (lastLoad != null && nextLoad != null) {
    final delta = roundTo(nextLoad - lastLoad, 2);
    if (delta > 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadUp, <String, Object?>{'deltaKg': delta}),
      );
    } else if (delta < 0) {
      reasons.add(
        reason(ReasonCodes.adaptLoadDown, <String, Object?>{'deltaKg': -delta}),
      );
    }
  }
  final before = index < exercise.plan.length
      ? (previousTarget?.high ?? previous.amount)
      : previous.amount;
  if (action == IntraSessionAction.repsUp) {
    reasons.add(
      reason(ReasonCodes.adaptRepsUp, <String, Object?>{
        'delta': next.low - before < 1 ? 1 : next.low - before,
      }),
    );
  } else if (action == IntraSessionAction.repsDown) {
    reasons.add(
      reason(ReasonCodes.adaptRepsDown, <String, Object?>{
        'delta': before - next.low < 1 ? 1 : before - next.low,
      }),
    );
  }
  if (exercise.calibrating) {
    reasons.add(
      reason(ReasonCodes.adaptCalibration, <String, Object?>{
        'session': track.filter.sessions + 1,
      }),
    );
  }
  if (next.benchmark) {
    reasons.add(
      reason(ReasonCodes.adaptBenchmarkSet, <String, Object?>{
        'rir': rirOfFlames(next.flames),
      }),
    );
  }
  final sd = track.filter.loadSd(exercise.nPlan);
  var restNext = rest;
  if (previous.unplannedFail && rest != null) {
    restNext = rest + 60 > 900 ? 900 : rest + 60;
  }
  return IntraSessionAdvice(
    exerciseId: wanted.exerciseId,
    action: action,
    nextLoadKg: nextLoad == null ? null : roundTo(nextLoad, 2),
    nextRepsLow: hold ? null : next.low,
    nextRepsHigh: hold ? null : next.high,
    nextSeconds: hold ? next.high : null,
    slotId: wanted.slotId,
    restSeconds: restNext,
    confidence: roundTo(clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1), 3),
    reasons: reasons,
    miniSetsLeft: coached?.miniSetsLeft,
    stepExerciseId: coached?.stepExerciseId,
  );
}

/// Lecture du bilan du jour d'après la séance prescrite, quand le bilan
/// lui-même n'est pas redonné : palier (raison `adapt.load_held` de cause
/// `health` ou `health_strong`) et effet sur la capacité (forme du jour de
/// la raison `adapt.readiness`, moins la fatigue modélisée).
HealthReading _healthOf(
  SessionPlan session,
  ModelState state,
  int day,
  AdaptParams p,
) {
  var level = 0;
  double? readiness;
  for (final r in session.reasons) {
    if (r.code == ReasonCodes.adaptLoadHeld) {
      final cause = r.params['cause'];
      if (cause == 'health_strong') {
        level = 2;
      } else if (cause == 'health' && level < 1) {
        level = 1;
      }
    } else if (r.code == ReasonCodes.adaptReadiness) {
      final value = r.params['readiness'];
      if (value is num) {
        readiness = value.toDouble();
      }
    }
  }
  if (level == 0) {
    return HealthReading.none;
  }
  var shift = level >= 2 ? p.healthLevel2 : p.healthLevel1;
  if (readiness != null && readiness > 0) {
    final fatigue = state.fatigue.fork()..advance(day, p);
    final fromReadiness =
        (readiness - 1) * p.readinessSpan - fatigue.globalShift(p);
    if (fromReadiness < shift) {
      shift = fromReadiness;
    }
  }
  return HealthReading(clampDouble(shift, p.healthFloor, 0), level, 0);
}

/// Note dans [state] les zones douloureuses que la séance prescrite a
/// retenues (raisons `adapt.pain_reported` de ses exercices et de ses
/// ajustements).
void _painsOf(SessionPlan session, ModelState state, int day, AdaptParams p) {
  final worst = <BodyZone, int>{};
  void read(List<Reason> reasons) {
    for (final r in reasons) {
      if (r.code != ReasonCodes.adaptPainReported) {
        continue;
      }
      final code = r.params['zone'];
      final intensity = r.params['intensity'];
      if (code is! String || intensity is! num) {
        continue;
      }
      for (final zone in BodyZone.values) {
        if (zone.code == code) {
          final old = worst[zone];
          if (old == null || intensity > old) {
            worst[zone] = intensity.toInt();
          }
        }
      }
    }
  }

  for (final item in session.items) {
    read(item.reasons);
  }
  for (final adjustment in session.adjustments) {
    read(adjustment.reasons);
  }
  for (final zone in BodyZone.values) {
    final intensity = worst[zone];
    if (intensity != null && intensity > p.painThreshold) {
      state.notePain(
        zone,
        state.pains[zone]?.side ?? BodySide.both,
        intensity,
        day,
        p,
      );
    }
  }
}
