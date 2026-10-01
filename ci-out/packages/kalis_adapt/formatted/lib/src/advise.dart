/// Conseil pour la série suivante : mise à jour après chaque série et
/// ajustement quand l'écart aux flammes visées atteint le seuil (D5).
library;

import 'package:kalis_core/kalis_core.dart';

import 'book.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'replay.dart';
import 'session.dart';

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
  final health = readHealth(check, p);
  notePains(state, check, const <PainReport>[], day, p);
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
  String? openSlot;
  for (final set in request.done) {
    if (!set.isUsable || set.kind == SetKind.warmup) {
      continue;
    }
    final info = ctx.book.find(set.exerciseId);
    if (info == null || info.mode == null) {
      continue;
    }
    final hold = info.mode == CapacityMode.hold;
    final amount = hold ? set.seconds : set.reps;
    if (amount == null) {
      continue;
    }
    final key = '${set.slotId ?? ''}|${set.exerciseId}|${set.exerciseOrder}';
    if (key != openKey) {
      openKey = key;
      final item = _itemOf(session, set.slotId, set.exerciseId);
      openSlot = item?.slotId ?? set.slotId;
      final exercise = run.begin(
        info,
        _specOf(view, session, info, item, item?.slotId ?? set.slotId),
      );
      if (item != null) {
        exercise.plan = _plansOf(item, hold: hold);
      }
    }
    final exercise = run.current!;
    final index = exercise.observed.length;
    final target =
        planOfTarget(set.target, hold: hold) ??
        (index < exercise.plan.length ? exercise.plan[index] : null);
    run.observe(
      loadKg: set.externalLoadKg,
      amount: amount,
      flames: set.flames,
      missed: !set.success,
      target: target,
      test: set.kind == SetKind.test,
    );
  }

  final info = ctx.book.find(wanted.exerciseId);
  final rest = wanted.restSeconds;
  ExerciseRun? exercise = run.current;
  if (exercise == null ||
      openSlot != wanted.slotId ||
      exercise.observed.isEmpty) {
    exercise = null;
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
  final (next, action) = run.advise(exercise, index);
  final reasons = <Reason>[];
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
    final delta = rated - previousTarget.flames;
    if (delta >= p.adviceGapFlames) {
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
  if (next.open) {
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
  );
}
