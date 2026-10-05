/// Mode coach : conseil pour la ligne suivante — règles d'autorégulation
/// portées par la prescription (`AutoregulationRule`), séries allégées
/// calculées sur la série de tête réalisée, tentatives d'un test de
/// maximum. Règles et sources : `CONTRAT.md`, § 11.
library;

import 'package:kalis_core/kalis_core.dart';

import 'coach.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'skills.dart';

Reason _r(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

/// Conseil du mode coach.
final class CoachAdvice {
  /// Conseil.
  CoachAdvice({required this.next, required this.action});

  /// Cible de la ligne suivante (celle prévue quand l'exercice s'arrête).
  final SetPlan next;

  /// Nature du changement.
  final IntraSessionAction action;

  /// Raisons.
  final List<Reason> reasons = <Reason>[];

  /// Mini-séries conseillées dans la ligne suivante, ou `null`.
  int? miniSetsLeft;

  /// Étape de figure plus facile conseillée, ou `null`.
  String? stepExerciseId;
}

/// Réserve de la série [set] telle qu'elle a été notée ; sans note (ou
/// notée « 5 et plus »), celle que le modèle estime.
double _rirOf(ObservedSet set) {
  final flames = set.flames;
  if (flames == null) {
    return set.rir;
  }
  if (flames == Flames.min) {
    return set.rir > 5 ? set.rir : 5.0;
  }
  return rirOfFlames(flames);
}

double _lighter(SessionRun run, ExerciseRun ex, double fromKg, double gapRir) {
  final p = run.ctx.params;
  final grid = ex.info.grid;
  final bw = ex.info.fraction * run.bodyWeightKg;
  final points = gapRir < 1 ? 1.0 : gapRir.floorToDouble();
  var cut = p.coachBreachCut * points;
  if (cut > p.coachBreachCutMax) {
    cut = p.coachBreachCutMax;
  }
  final wanted = (fromKg + bw) * (1 - cut) - bw;
  var kg = grid.floor(wanted < grid.minimum ? grid.minimum : wanted);
  if (kg >= fromKg - 1e-9) {
    // Un cran reste toujours permis.
    kg = grid.next(fromKg, up: false);
  }
  return kg;
}

/// Conseil pour la ligne de rang [index] de l'exercice [ex] en mode coach,
/// d'après ses lignes déjà faites ; `null` : la règle générale de 0.1
/// s'applique (échec non prévu, ligne hors plan, exercice sans lecture
/// coach). [sessionItem] est la prescription de la séance du jour.
CoachAdvice? coachAdvise(
  SessionRun run,
  ExerciseRun ex,
  int index,
  ExercisePrescription sessionItem,
  SkillBoard? skills,
) {
  final advice = _coachAdvise(run, ex, index, sessionItem, skills);
  if (advice == null) {
    return advice;
  }
  final clamped = clampLocked(run, ex, advice.next);
  if (clamped == null) {
    return advice;
  }
  // (Un arrêt reste un arrêt ; la cible rendue avec lui tient les verrous.)
  final held =
      CoachAdvice(
          next: clamped,
          action: advice.action == IntraSessionAction.stopExercise
              ? IntraSessionAction.stopExercise
              : IntraSessionAction.keep,
        )
        ..miniSetsLeft = advice.miniSetsLeft
        ..stepExerciseId = advice.stepExerciseId;
  held.reasons.addAll(advice.reasons);
  return held;
}

/// Invariants de 0.1, quelle que soit la règle suivie : après un échec non
/// prévu dans la séance, sur une zone douloureuse ou un jour de bilan bas,
/// la ligne suivante [next] n'est jamais plus lourde que la précédente ;
/// sans charge, après un échec, jamais plus longue. Rend la cible bornée,
/// ou `null` quand [next] tient déjà (ou pour une tentative, qui suit sa
/// propre règle).
SetPlan? clampLocked(SessionRun run, ExerciseRun ex, SetPlan next) {
  if (next.role == SetRole.attempt || ex.observed.isEmpty) {
    return null;
  }
  final previous = ex.observed.last;
  final locked = ex.fails > 0 || ex.painZones.isNotEmpty || run.noIncrease;
  if (!locked) {
    return null;
  }
  if (ex.info.mode == CapacityMode.loaded) {
    final last = previous.loadKg;
    final kg = next.loadKg;
    if (last != null && kg != null && kg > last + 1e-9) {
      return next.withLoad(last);
    }
    return null;
  }
  if (ex.fails > 0) {
    final cap = previous.amount < 1 ? 1 : previous.amount;
    if (next.high > cap) {
      return SetPlan(
        loadKg: null,
        low: next.low > cap ? cap : next.low,
        high: cap,
        flames: next.flames,
        open: next.open && next.low < cap,
        role: next.role,
      );
    }
  }
  return null;
}

CoachAdvice? _coachAdvise(
  SessionRun run,
  ExerciseRun ex,
  int index,
  ExercisePrescription sessionItem,
  SkillBoard? skills,
) {
  final c = ex.spec.coach;
  final track = ex.track;
  if (c == null || track == null || ex.observed.isEmpty) {
    return null;
  }
  final p = run.ctx.params;
  final previous = ex.observed.last;
  final planned = index < ex.plan.length ? ex.plan[index] : null;
  if (planned == null) {
    return null;
  }
  final info = ex.info;
  final loaded = info.mode == CapacityMode.loaded;
  final hold = info.mode == CapacityMode.hold;
  final served = sessionItem.technique?.kind ?? SetTechniqueKind.standard;
  final rirTarget = ex.rirEff;
  final floor = c.rirFloor ?? rirTarget;
  final free =
      ex.fails == 0 && ex.painZones.isEmpty && !run.noIncrease && !track.noUp;

  // Tentatives d'un test de maximum : la suivante d'après les précédentes
  // et le maximum du jour réestimé.
  if (planned.role == SetRole.attempt && loaded) {
    final done = <(double, bool)>[
      for (final o in ex.observed)
        if (o.role == SetRole.attempt || o.target?.role == SetRole.attempt)
          (o.loadKg ?? 0, !o.failed && o.amount >= 1),
    ];
    final f = track.filter;
    final lift = competitionLiftOf(run.ctx.profile, info.id, run.day);
    final picks = attemptLadder(
      estimateTotal: exp(f.m[0] + f.m[3] + f.gRef),
      relSd: dayRelSd(ex),
      bodyPart: info.fraction * run.bodyWeightKg,
      grid: info.grid,
      attempts: done.length + 1,
      done: done,
      recentBest: recentHeavy(track, run.day, p),
      targetKg: lift?.targetKg,
      objective: null,
      healthLevel: run.health.level,
      prudentCause: ex.painZones.isNotEmpty ? 'pain' : null,
      p: p,
      minIncrementKg: lift?.minIncrementKg,
    );
    if (picks.isEmpty) {
      return null;
    }
    final pick = picks.first;
    final last = previous.loadKg ?? 0;
    final advice = CoachAdvice(
      next: SetPlan(
        loadKg: pick.loadKg,
        low: 1,
        high: 1,
        flames: planned.flames,
        role: SetRole.attempt,
      ),
      action: pick.loadKg > last + 1e-9
          ? IntraSessionAction.loadUp
          : IntraSessionAction.keep,
    );
    advice.reasons.add(
      _r(ReasonCodes.adaptAttemptNext, <String, Object?>{
        'successProbability': roundTo(pick.probability, 3),
      }),
    );
    final cause = pick.cause;
    if (cause != null) {
      advice.reasons.add(
        _r(ReasonCodes.adaptAttemptConservative, <String, Object?>{
          'cause': cause,
        }),
      );
    }
    return advice;
  }

  // Échec non prévu : règle générale (recalcul sans hausse, arrêt après
  // deux échecs).
  if (previous.unplannedFail) {
    return null;
  }

  CoachAdvice stop(String cause) {
    final advice = CoachAdvice(
      next: planned,
      action: IntraSessionAction.stopExercise,
    );
    advice.reasons.add(
      _r(ReasonCodes.adaptMiniSetStop, <String, Object?>{'cause': cause}),
    );
    return advice;
  }

  // Arrêt sur la propreté (figures, maintiens).
  final qualityRule = c.rule(AutoregulationKind.stopOnQualityDrop);
  final qualityFloor =
      qualityRule?.qualityFloor ?? sessionItem.technique?.qualityFloor;
  final quality = previous.quality;
  if (qualityFloor != null && quality != null && quality < qualityFloor) {
    final least = qualityRule?.minSets ?? 1;
    if (index >= least) {
      final advice = stop('quality');
      // Deux premières lignes déjà sales : l'étape est trop dure
      // aujourd'hui, l'étape plus facile est conseillée.
      final target = sessionItem.skillTargetId;
      if (index <= 2 && target != null && skills != null) {
        final easier = skills.easierStep(target, info.id);
        if (easier != null) {
          advice.stepExerciseId = easier;
          advice.reasons.add(
            _r(ReasonCodes.adaptSkillStepDown, <String, Object?>{
              'exerciseId': easier,
            }),
          );
        }
      }
      return advice;
    }
  }

  // Arrêt sur la chute des répétitions (EMOM, densité).
  final dropRule = c.rule(AutoregulationKind.stopOnRepDrop);
  final repDrop = dropRule?.repDrop;
  if (repDrop != null) {
    final first = ex.observed.first.amount;
    final aimed = previous.target?.low ?? first;
    final reference = aimed < first ? aimed : first;
    // (Une chute dite facile — au moins 3 en réserve — n'est pas de la
    // fatigue : le bloc continue.)
    final said = previous.flames;
    final easy = !previous.failed && said != null && rirOfFlames(said) >= 3;
    if (reference - previous.amount >= repDrop &&
        index >= (dropRule?.minSets ?? 1) &&
        !easy) {
      return stop('rep_drop');
    }
  }

  // Plafond d'effort : une ligne finie nettement sous le plancher de
  // réserve allège la suivante ; deux de suite arrêtent l'exercice.
  // Une note au plafond de ce qu'une personne sait dire (« 4 en réserve
  // ou plus ») ne dit pas que la série était trop dure ; des répétitions
  // qui manquent à la cible, si.
  final ceiling = run.state.rater.ceiling(p);
  final floorSaid = floor > ceiling ? ceiling : floor;
  double gapOf(ObservedSet o) {
    var g = floorSaid - _rirOf(o);
    if (g < 0) {
      g = 0;
    }
    // (Maintien : une tenue plus courte que prévu ne compte que si elle
    // est dite dure ; c'est la propreté qui arrête les tenues.)
    final aimed = o.target?.low;
    if (!hold && aimed != null && o.amount < aimed) {
      g += aimed - o.amount;
    }
    return g;
  }

  final gap = gapOf(previous);
  final breach = !previous.failed && gap >= p.coachBreachRir - 1e-9;
  var breaches = 0;
  for (final o in ex.observed.reversed) {
    if (!o.failed && gapOf(o) >= p.coachBreachRir - 1e-9) {
      breaches++;
    } else {
      break;
    }
  }
  final stopRule = c.rule(AutoregulationKind.stopAtRir);
  if (stopRule != null && breach && breaches >= 2) {
    final least = stopRule.minSets ?? p.coachStopMinSets;
    if (index >= least) {
      final advice = CoachAdvice(
        next: planned,
        action: IntraSessionAction.stopExercise,
      );
      advice.reasons.add(
        _r(ReasonCodes.adaptRirCap, <String, Object?>{
          'rir': roundTo(floor, 1),
        }),
      );
      return advice;
    }
  }

  // Séries allégées calculées sur la série de tête réalisée.
  if (served == SetTechniqueKind.topSetBackoff &&
      loaded &&
      planned.role == SetRole.backOff) {
    final top = ex.observed.first;
    final topLoad = top.loadKg;
    final t = sessionItem.technique;
    if (topLoad != null && t != null) {
      var drop =
          c.rule(AutoregulationKind.backoffFromTopSet)?.pct ??
          t.backoffDropPct ??
          0.1;
      final grid = info.grid;
      final bw = info.fraction * run.bodyWeightKg;
      // Baisse prévue le matin (le moteur a pu rapprocher les séries
      // allégées de la série de tête) : elle vaut si elle est plus petite.
      final topPlanned = top.target?.loadKg;
      final backPlanned = planned.loadKg;
      if (topPlanned != null && backPlanned != null && topPlanned + bw > 0) {
        final plannedDrop = 1 - (backPlanned + bw) / (topPlanned + bw);
        if (plannedDrop >= 0 && plannedDrop < drop) {
          drop = plannedDrop;
        }
      }
      final base = (topLoad + bw) * (1 - drop) - bw;
      var kg = grid.floor(base < grid.minimum ? grid.minimum : base);
      if (kg > topLoad) {
        kg = topLoad;
      }
      final topGap = gapOf(top);
      if (!top.failed && topGap >= p.coachBreachRir - 1e-9) {
        // Série de tête plus dure que prévu : 2,5 à 5 % de moins.
        kg = _lighter(run, ex, kg, topGap);
      }
      if (index >= 2 && breach && previous.loadKg != null) {
        final lighter = _lighter(run, ex, previous.loadKg!, gap);
        if (lighter < kg) {
          kg = lighter;
        }
      }
      final plannedLoad = planned.loadKg;
      if (!free && plannedLoad != null && kg > plannedLoad) {
        kg = plannedLoad;
      }
      final advice = CoachAdvice(
        next: planned.withLoad(kg),
        action: plannedLoad == null || (kg - plannedLoad).abs() < 1e-9
            ? IntraSessionAction.keep
            : (kg > plannedLoad
                  ? IntraSessionAction.loadUp
                  : IntraSessionAction.loadDown),
      );
      advice.reasons.add(
        _r(ReasonCodes.adaptBackoffFromTopSet, <String, Object?>{
          'topLoadKg': roundTo(topLoad, 2),
          'pct': roundTo(drop, 3),
        }),
      );
      return advice;
    }
  }

  // Maintien tiré du meilleur maintien du jour.
  final holdRule = c.rule(AutoregulationKind.holdFromBest);
  final holdPct = holdRule?.pct;
  if (hold && holdPct != null) {
    var best = 0;
    for (final o in ex.observed) {
      if (!o.failed && o.amount > best) {
        best = o.amount;
      }
    }
    if (best > 0) {
      var seconds = (holdPct * best + 0.5).floor();
      if (seconds < 1) {
        seconds = 1;
      }
      if (seconds > planned.high && !free) {
        seconds = planned.high;
      }
      return CoachAdvice(
        next: SetPlan(
          loadKg: null,
          low: seconds,
          high: seconds,
          flames: planned.flames,
          role: planned.role,
        ),
        action: seconds > planned.high
            ? IntraSessionAction.repsUp
            : (seconds < planned.high
                  ? IntraSessionAction.repsDown
                  : IntraSessionAction.keep),
      );
    }
  }

  if (breach) {
    // Première ligne sous le plancher : la suivante est allégée.
    final load = previous.loadKg;
    if (loaded && load != null) {
      final base = planned.loadKg == null || planned.loadKg! > load
          ? load
          : planned.loadKg!;
      final kg = _lighter(run, ex, base, gap);
      final advice = CoachAdvice(
        next: planned.withLoad(kg),
        action: IntraSessionAction.loadDown,
      );
      advice.reasons.add(
        _r(ReasonCodes.adaptRirCap, <String, Object?>{
          'rir': roundTo(floor, 1),
        }),
      );
      return advice;
    }
    if (!loaded) {
      final points = gap < 1 ? 1 : gap.floor();
      var amount = hold
          ? (planned.high * (1 - 0.1 * points)).floor()
          : planned.high - points;
      if (amount > previous.amount) {
        amount = previous.amount;
      }
      if (amount < 1) {
        amount = 1;
      }
      final advice = CoachAdvice(
        next: SetPlan(
          loadKg: null,
          low: amount < planned.low ? amount : planned.low,
          high: amount,
          flames: planned.flames,
          open: planned.open && amount > planned.low,
          role: planned.role,
        ),
        action: amount < planned.high
            ? IntraSessionAction.repsDown
            : IntraSessionAction.keep,
      );
      advice.reasons.add(
        _r(ReasonCodes.adaptRirCap, <String, Object?>{
          'rir': roundTo(floor, 1),
        }),
      );
      return advice;
    }
  }

  // Ligne nettement plus facile que visé, en semaine de charge : un cran de
  // plus sur la suivante (jamais pour une série légère, un affûtage, une
  // zone douloureuse ou un jour de bilan bas).
  final rated = previous.flames;
  final load = previous.loadKg;
  final plannedLoad = planned.loadKg;
  if (loaded &&
      load != null &&
      plannedLoad != null &&
      rated != null &&
      free &&
      c.policy.build &&
      !c.light &&
      !c.eventNear &&
      c.level >= 1 &&
      !ex.uncertain &&
      planned.role != SetRole.backOff &&
      previous.amount >= (previous.target?.high ?? previous.amount) &&
      _rirOf(previous) - rirTarget >= p.coachEasyGapRir - 1e-9 &&
      plannedLoad <= load + 1e-9) {
    final grid = info.grid;
    final bw = info.fraction * run.bodyWeightKg;
    final next = grid.next(load, up: true);
    final ceiling = (load + bw) * (1 + p.coachEasyStepShare) - bw;
    if (next <= ceiling + 1e-9 || grid.stepAbove(load) <= grid.step + 1e-9) {
      return CoachAdvice(
        next: planned.withLoad(next),
        action: IntraSessionAction.loadUp,
      );
    }
  }

  // Sinon : la cible prévue — jamais plus lourde que la dernière ligne
  // quand une ligne précédente de l'exercice a dû être allégée.
  var kept = planned;
  var eased = false;
  for (final o in ex.observed) {
    if (!o.failed && gapOf(o) >= p.coachBreachRir - 1e-9) {
      eased = true;
    }
  }
  final lastLoad = previous.loadKg;
  final keptLoad = planned.loadKg;
  if (eased &&
      loaded &&
      lastLoad != null &&
      keptLoad != null &&
      keptLoad > lastLoad + 1e-9) {
    kept = planned.withLoad(lastLoad);
  } else if (eased && !loaded && planned.high > previous.amount) {
    final amount = previous.amount < 1 ? 1 : previous.amount;
    kept = SetPlan(
      loadKg: null,
      low: amount < planned.low ? amount : planned.low,
      high: amount,
      flames: planned.flames,
      open: planned.open && amount > planned.low,
      role: planned.role,
    );
  }
  final advice = CoachAdvice(
    next: kept,
    action: identical(kept, planned)
        ? IntraSessionAction.keep
        : (loaded ? IntraSessionAction.loadDown : IntraSessionAction.repsDown),
  );
  final t = sessionItem.technique;
  if (t != null &&
      (served == SetTechniqueKind.cluster ||
          served == SetTechniqueKind.restPause ||
          served == SetTechniqueKind.myoReps)) {
    advice.miniSetsLeft =
        t.miniSets ?? (served == SetTechniqueKind.myoReps ? 4 : 3);
  }
  return advice;
}
