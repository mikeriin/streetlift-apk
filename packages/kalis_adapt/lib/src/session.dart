/// Prescription de la séance du jour : charges et répétitions tirées du
/// modèle, ajustement gradué au bilan santé, zones douloureuses épargnées,
/// séance raccourcie au temps disponible, lieu du jour (D5.8, D5.9).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show planSimilarity;

import 'book.dart';
import 'fatigue.dart';
import 'filter.dart';
import 'model.dart';
import 'numeric.dart';
import 'params.dart';
import 'replay.dart';

/// Raison de code [code] et de paramètres [params].
Reason reason(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

/// Proximité minimale d'un exercice de remplacement (celle des variantes
/// de `kalis_plan`).
const double substituteMinSimilarity = 0.45;

/// Exercice de la séance en cours de préparation.
final class _Draft {
  _Draft(this.item, this.info, this.role);

  ExercisePrescription item;
  ExerciseInfo? info;
  final SlotRole? role;
  int sets = 0;
  List<SetPlan>? plans;
  ExerciseRun? run;
  final List<Reason> reasons = <Reason>[];
  bool removed = false;
}

/// Matériel disponible aujourd'hui : celui du lieu [place] si le profil le
/// détaille, sinon tout le matériel du profil.
Set<String> equipmentFor(AthleteProfile profile, Place? place) {
  if (place != null) {
    for (final pe in profile.equipmentByPlace ?? const <PlaceEquipment>[]) {
      if (pe.place == place) {
        return pe.equipment.toSet();
      }
    }
  }
  return profile.equipment.toSet();
}

/// Meilleur remplaçant de [original] : même mode de capacité, même unité,
/// même discipline ou même chaîne de variantes, pas plus difficile,
/// faisable avec [equipment] (et au lieu [place]), ni détesté ni déclaré
/// non su, épargnant les zones de [pains], absent de [taken] ; le plus
/// proche au sens de `planSimilarity`, puis par identifiant.
ExerciseInfo? findSubstitute(
  EngineContext ctx,
  ExerciseInfo original, {
  required Set<String> equipment,
  required Place? place,
  required Map<BodyZone, int> pains,
  required Set<String> taken,
}) {
  final p = ctx.params;
  final profile = ctx.profile;
  final banned = <String>{
    ...profile.dislikedExerciseIds,
    ...?profile.cannotDoExerciseIds,
  };
  ExerciseInfo? best;
  var bestScore = substituteMinSimilarity;
  final o = original.exercise;
  for (final e in ctx.catalog.exercises) {
    if (e.id == o.id ||
        taken.contains(e.id) ||
        banned.contains(e.id) ||
        e.unit != o.unit ||
        e.difficulty > o.difficulty ||
        (e.discipline != o.discipline && e.rootId != o.rootId) ||
        !e.feasibleWith(equipment) ||
        (place != null && !e.places.contains(place))) {
      continue;
    }
    final info = ctx.book.find(e.id);
    if (info == null || info.mode != original.mode) {
      continue;
    }
    var spared = true;
    for (final entry in pains.entries) {
      if (info.excludedByPain(
            entry.key,
            entry.value,
            hard: p.painHard,
            severe: p.painSevere,
          ) ||
          info.zoneLevel(entry.key) > original.zoneLevel(entry.key)) {
        spared = false;
        break;
      }
    }
    if (!spared) {
      continue;
    }
    final score = planSimilarity(o, e);
    if (score > bestScore ||
        (score == bestScore && best != null && e.id.compareTo(best.id) < 0)) {
      best = info;
      bestScore = score;
    }
  }
  return best;
}

/// Durée estimée d'un exercice, en secondes (formule de `kalis_plan` :
/// transition + séries × (effort + repos)).
double itemSeconds(ExercisePrescription item, int sets, AdaptParams p) {
  final rest = item.restSeconds ?? p.defaultRestSeconds;
  double effort;
  final seconds = item.secondsHigh;
  final reps = item.repsHigh;
  if (seconds != null) {
    effort = seconds.toDouble();
  } else if (reps != null) {
    effort = (reps * p.repSeconds).toDouble();
  } else {
    effort = 60;
  }
  return p.transitionSeconds + sets * (effort + rest);
}

/// Construit la prescription de la séance demandée par [request] à partir
/// de l'état rejoué [replayed].
SessionPlan buildSessionPlan(
  EngineContext ctx,
  BlockView view,
  Replayed replayed,
  SessionRequest request,
) {
  final p = ctx.params;
  final input = request.input;
  final today = input.today;
  final day = today.dayNumber;
  final dayPrescription = view.day(request.weekIndex, request.dayIndex);
  if (dayPrescription == null) {
    throw ArgumentError(
      'séance inconnue du bloc : semaine ${request.weekIndex}, '
      'jour ${request.dayIndex}',
    );
  }
  final weekKind = view.week(request.weekIndex)?.kind;
  final state = replayed.state.fork();
  final check = request.healthCheck;
  final health = readHealth(check, p);
  notePains(state, check, const <PainReport>[], day, p);
  final painsToday = <BodyZone, int>{};
  for (final s in state.pains.values) {
    if (s.lastIntensity > p.painThreshold && state.painActive(s.zone, day, p)) {
      painsToday[s.zone] = s.lastIntensity;
    }
  }
  final extraRir = health.level * p.healthRirBonus;
  final run = SessionRun(
    ctx,
    state,
    day: day,
    health: health,
    bodyWeightKg: bodyWeightOf(null, ctx.profile, p),
    extraRir: extraRir,
    noIncrease: health.level >= 1,
  );
  final fatigueShift = state.fatigue.globalShift(p);
  final readiness = readinessOf(health.shift + fatigueShift, p);

  final sessionReasons = <Reason>[
    reason(ReasonCodes.adaptReadiness, <String, Object?>{
      'readiness': roundTo(readiness, 3),
    }),
  ];
  final healthReasons = <Reason>[];
  final overall = check?.overall;
  if (overall != null && overall < p.healthNeutral) {
    healthReasons.add(
      reason(ReasonCodes.adaptHealthLow, <String, Object?>{'overall': overall}),
    );
  }
  final sleep = check?.sleepQuality;
  if (sleep != null && sleep <= 2) {
    healthReasons.add(
      reason(ReasonCodes.adaptSleepLow, <String, Object?>{
        'sleepQuality': sleep,
      }),
    );
  }
  if (readinessOf(fatigueShift, p) < p.deloadReadiness) {
    healthReasons.add(
      reason(ReasonCodes.adaptFatigueHigh, <String, Object?>{
        'readiness': roundTo(readinessOf(fatigueShift, p), 3),
      }),
    );
  }
  sessionReasons.addAll(healthReasons);
  if (replayed.digests.isNotEmpty) {
    final gap = day - replayed.digests.last.day;
    if (gap >= 7) {
      sessionReasons.add(
        reason(ReasonCodes.adaptResumeAfterBreak, <String, Object?>{
          'days': gap,
        }),
      );
    }
  }
  final weight = state.rater.weight(p);
  if (weight < p.benchmarkWeight) {
    sessionReasons.add(
      reason(ReasonCodes.adaptRatingsUninformative, <String, Object?>{
        'confirmRate': roundTo(state.rater.confirmRate, 3),
        'sets': state.rater.window.length,
      }),
    );
  }

  final adjustments = <SessionAdjustment>[];
  final place = request.place;
  final equipment = equipmentFor(ctx.profile, place);
  final drafts = <_Draft>[
    for (final item in dayPrescription.items)
      _Draft(item, ctx.book.find(item.exerciseId), view.roleOf(item.slotId))
        ..sets = item.sets,
  ];
  final taken = <String>{for (final d in drafts) d.item.exerciseId};

  // 1. Lieu du jour et zones douloureuses : exercices remplacés ou retirés.
  for (final d in drafts) {
    final info = d.info;
    if (info == null) {
      continue;
    }
    final e = info.exercise;
    final misplaced =
        place != null &&
        (!e.feasibleWith(equipment) || !e.places.contains(place));
    BodyZone? painZone;
    for (final entry in painsToday.entries) {
      if (info.excludedByPain(
        entry.key,
        entry.value,
        hard: p.painHard,
        severe: p.painSevere,
      )) {
        painZone = entry.key;
        break;
      }
    }
    if (!misplaced && painZone == null) {
      continue;
    }
    final why = <Reason>[
      if (painZone != null)
        reason(ReasonCodes.adaptPainReported, <String, Object?>{
          'zone': painZone.code,
          'intensity': painsToday[painZone],
        }),
      if (misplaced)
        reason(ReasonCodes.adaptPlaceChanged, <String, Object?>{
          'place': place.code,
        }),
    ];
    final substitute = info.mode == null
        ? null
        : findSubstitute(
            ctx,
            info,
            equipment: equipment,
            place: place,
            pains: painsToday,
            taken: taken,
          );
    if (substitute == null) {
      d.removed = true;
      adjustments.add(
        SessionAdjustment(
          kind: AdjustmentKind.exerciseRemoved,
          exerciseId: e.id,
          reasons: why,
        ),
      );
      continue;
    }
    taken.add(substitute.id);
    adjustments.add(
      SessionAdjustment(
        kind: AdjustmentKind.exerciseSwapped,
        exerciseId: e.id,
        replacementExerciseId: substitute.id,
        reasons: why,
      ),
    );
    d.reasons.addAll(why);
    d.info = substitute;
    d.item = _retarget(d.item, substitute);
  }

  // 2. Bilan nettement bas : une série de moins par exercice (les
  // mouvements principaux gardent au moins trois séries).
  if (health.level >= 2) {
    for (final d in drafts) {
      if (d.removed || d.item.targetFlames == null) {
        continue;
      }
      final floor = d.role == SlotRole.main ? 3 : 2;
      if (d.sets > floor) {
        d.sets--;
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: d.item.exerciseId,
            setsDelta: -1,
            reasons: healthReasons,
          ),
        );
        d.reasons.addAll(healthReasons);
      }
    }
  }

  // 3. Charges, répétitions et flammes de chaque exercice.
  var confidenceSum = 0.0;
  var confidenceCount = 0;
  for (final d in drafts) {
    if (d.removed) {
      continue;
    }
    final info = d.info;
    final item = d.item;
    if (info == null || info.mode == null) {
      continue;
    }
    final driven =
        item.targetFlames != null ||
        item.percentOfOneRm != null ||
        item.setTargets != null;
    if (!driven) {
      continue;
    }
    final spec = view.specOf(info, item, weekKind);
    final sized = SlotSpec(
      low: spec.low,
      high: spec.high,
      rir: spec.rir,
      sets: d.sets,
      restSeconds: spec.restSeconds,
      main: spec.main,
      benchmarkOk: spec.benchmarkOk,
      hasTarget: spec.hasTarget,
      test: spec.test,
    );
    final exercise = run.begin(info, sized);
    d.run = exercise;
    confidenceCount++;
    final track = exercise.track;
    if (track == null) {
      d.reasons.add(
        reason(ReasonCodes.adaptCalibration, <String, Object?>{'session': 1}),
      );
      continue;
    }
    final sd = track.filter.loadSd(exercise.nPlan, withDay: false);
    confidenceSum += clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1);
    d.plans = _plansFor(run, exercise, item, d.sets);
    if (health.level >= 1 &&
        info.mode == CapacityMode.loaded &&
        health.shift < 0) {
      adjustments.add(
        SessionAdjustment(
          kind: AdjustmentKind.loadReduced,
          exerciseId: info.id,
          loadFactor: roundTo(exp(health.shift), 3),
          reasons: healthReasons,
        ),
      );
    }
  }
  run.closeExercise();

  // 4. Temps disponible aujourd'hui : la séance est raccourcie en gardant
  // les priorités.
  final available = check?.minutesAvailable;
  if (available != null) {
    double total() {
      var sum = 0.0;
      for (final d in drafts) {
        if (!d.removed) {
          sum += itemSeconds(d.item, d.sets, p);
        }
      }
      return sum;
    }

    final planned = (total() / 60).ceil();
    final budget = available * 60.0;
    if (total() > budget) {
      final why = <Reason>[
        reason(ReasonCodes.adaptTimeShort, <String, Object?>{
          'minutesAvailable': available,
          'minutesPlanned': planned,
        }),
      ];
      sessionReasons.addAll(why);
      final cut = <_Draft, int>{};
      bool trim(Set<SlotRole?> roles, int floor) {
        for (final d in drafts.reversed) {
          if (!d.removed && roles.contains(d.role) && d.sets > floor) {
            d.sets--;
            cut[d] = (cut[d] ?? 0) + 1;
            return true;
          }
        }
        return false;
      }

      bool remove(Set<SlotRole?> roles) {
        for (final d in drafts.reversed) {
          if (!d.removed && roles.contains(d.role)) {
            d.removed = true;
            cut.remove(d);
            adjustments.add(
              SessionAdjustment(
                kind: AdjustmentKind.exerciseRemoved,
                exerciseId: d.item.exerciseId,
                reasons: why,
              ),
            );
            return true;
          }
        }
        return false;
      }

      const easy = <SlotRole?>{SlotRole.cooldown, SlotRole.mobility};
      const light = <SlotRole?>{
        SlotRole.accessory,
        SlotRole.core,
        SlotRole.conditioning,
        null,
      };
      const heavy = <SlotRole?>{
        SlotRole.main,
        SlotRole.secondary,
        SlotRole.skill,
      };
      var guard = 0;
      while (total() > budget && guard < 400) {
        guard++;
        if (remove(easy)) {
          continue;
        }
        if (trim(light, 2)) {
          continue;
        }
        if (remove(light)) {
          continue;
        }
        if (trim(heavy, 2)) {
          continue;
        }
        if (remove(const <SlotRole?>{SlotRole.warmup})) {
          continue;
        }
        if (remove(const <SlotRole?>{SlotRole.skill, SlotRole.secondary})) {
          continue;
        }
        if (trim(heavy, 1)) {
          continue;
        }
        break;
      }
      for (final entry in cut.entries) {
        entry.key.reasons.addAll(why);
        adjustments.add(
          SessionAdjustment(
            kind: AdjustmentKind.setsReduced,
            exerciseId: entry.key.item.exerciseId,
            setsDelta: -entry.value,
            reasons: why,
          ),
        );
      }
    }
  }

  // 5. Mise en forme.
  final items = <ExercisePrescription>[
    for (final d in drafts)
      if (!d.removed) _finish(ctx, run, d),
  ];
  return SessionPlan(
    date: today,
    blockId: view.block.pass1.blockId,
    weekIndex: request.weekIndex,
    dayIndex: request.dayIndex,
    items: items,
    adjustments: adjustments,
    confidence: confidenceCount == 0
        ? 0.5
        : roundTo(confidenceSum / confidenceCount, 3),
    reasons: sessionReasons,
  );
}

/// La prescription [item] portée sur l'exercice de remplacement
/// [substitute] : mêmes séries, même plage, même cible ; la charge sera
/// celle du modèle, ou à calibrer.
ExercisePrescription _retarget(
  ExercisePrescription item,
  ExerciseInfo substitute,
) {
  final e = substitute.exercise;
  LoadBasis basis;
  switch (e.loadType) {
    case LoadType.addedWeight:
      basis = LoadBasis.bodyweightPlusExternal;
    case LoadType.barbell:
    case LoadType.dumbbells:
    case LoadType.kettlebell:
    case LoadType.machine:
    case LoadType.cable:
    case LoadType.other:
      basis = LoadBasis.external;
    case LoadType.bodyweight:
      basis = LoadBasis.bodyweight;
    case LoadType.none:
    case LoadType.band:
      basis = LoadBasis.unloaded;
  }
  return ExercisePrescription(
    slotId: item.slotId,
    exerciseId: e.id,
    sets: item.sets,
    repsLow: item.repsLow,
    repsHigh: item.repsHigh,
    secondsLow: item.secondsLow,
    secondsHigh: item.secondsHigh,
    distanceMeters: item.distanceMeters,
    calories: item.calories,
    targetFlames: item.targetFlames,
    restSeconds: item.restSeconds,
    toCalibrate: true,
    loadBasis: basis,
    groupId: item.groupId,
    format: item.format,
    kind: item.kind,
    reasons: item.reasons,
  );
}

/// Cibles des séries d'un exercice suivi : règle générale (RIR visé), ou
/// consignes propres de la prescription (cibles série par série d'un
/// test, part du 1RM d'un programme importé).
List<SetPlan> _plansFor(
  SessionRun run,
  ExerciseRun exercise,
  ExercisePrescription item,
  int sets,
) {
  final p = run.ctx.params;
  final info = exercise.info;
  final track = exercise.track!;
  final f = track.filter;
  final targets = item.setTargets;
  final loaded = info.mode == CapacityMode.loaded;
  final bw = info.fraction * run.bodyWeightKg;
  double capped(double kg) {
    // Mêmes garde-fous que la règle générale : aucune hausse après un échec
    // non prévu, une douleur ou un bilan bas ; plafond de hausse.
    final last = track.lastLoad;
    if (last == null) {
      return kg;
    }
    final floored = info.grid.floor(last);
    final start = floored > last ? last : floored;
    if ((track.noUp || exercise.painZones.isNotEmpty || run.noIncrease) &&
        kg > start) {
      return start;
    }
    final rise = exercise.calibrating
        ? p.maxUpCalibration
        : (exercise.spec.main ? p.maxUpMain : p.maxUpOther);
    final cap = info.grid.floor((last + bw) * (1 + rise) - bw);
    final ceiling = cap < start ? start : cap;
    return kg > ceiling ? ceiling : kg;
  }

  if (loaded && targets != null && targets.isNotEmpty) {
    // Cibles série par série (montée d'un test) : chaque charge est celle
    // que le modèle prévoit pour les répétitions et les flammes dites.
    final out = <SetPlan>[];
    for (var i = 0; i < sets; i++) {
      final t = targets[i < targets.length ? i : targets.length - 1];
      final high = t.repsHigh ?? t.repsLow ?? exercise.spec.high;
      final low = t.repsLow ?? high;
      final flames =
          t.flames ?? item.targetFlames ?? flamesOfRir(exercise.rirEff);
      final rir = rirOfFlames(flames) + (exercise.rirEff - exercise.spec.rir);
      final shift = -run.quantileZ(rir) * f.loadSd(high + rir);
      final ideal = exp(f.logLoadFor(high + rir, shift: shift)) - bw;
      final kg = capped(
        info.grid.floor(ideal < info.grid.minimum ? info.grid.minimum : ideal),
      );
      out.add(SetPlan(loadKg: kg, low: low, high: high, flames: flames));
    }
    exercise.plan = List<SetPlan?>.of(out);
    return out;
  }
  final share = item.percentOfOneRm;
  if (loaded && item.targetFlames == null && share != null) {
    // Programme importé : la charge est la part dite du 1RM estimé ; les
    // flammes pré-remplies sont celles que le modèle prévoit.
    final ideal = share * f.capacity - bw;
    final kg = capped(
      info.grid.nearest(ideal < info.grid.minimum ? info.grid.minimum : ideal),
    );
    final high = exercise.spec.high;
    final possible = f.repsPossible(ln(info.totalLoad(kg, run.bodyWeightKg)));
    final out = <SetPlan>[];
    for (var i = 0; i < sets; i++) {
      final fatigue = plannedFatigue(i, 3, exercise.spec.restSeconds, p);
      final rir = possible * (1 - fatigue) - high;
      out.add(
        SetPlan(
          loadKg: kg,
          low: exercise.spec.low,
          high: high,
          flames: flamesOfRir(rir < 0 ? 0.0 : rir),
        ),
      );
    }
    exercise.plan = List<SetPlan?>.of(out);
    return out;
  }
  return run.planSets(exercise);
}

ExercisePrescription _finish(EngineContext ctx, SessionRun run, _Draft d) {
  final p = ctx.params;
  final item = d.item;
  final plans = d.plans;
  final exercise = d.run;
  final reasons = <Reason>[...item.reasons, ...d.reasons];
  if (plans == null || exercise == null || plans.isEmpty) {
    // Exercice non modélisé, ou sans a priori : la prescription du bloc,
    // au nombre de séries du jour.
    final targets = item.setTargets;
    return item.copyWith(
      sets: d.sets,
      setTargets: targets == null
          ? unset
          : <SetTarget>[
              for (var i = 0; i < d.sets; i++)
                targets[i < targets.length ? i : targets.length - 1],
            ],
      toCalibrate: item.toCalibrate || (exercise != null && !exercise.modelled),
      reasons: reasons,
    );
  }
  final info = exercise.info;
  final track = exercise.track!;
  final used = plans.length > d.sets ? plans.sublist(0, d.sets) : plans;
  final hold = info.mode == CapacityMode.hold;
  final loaded = info.mode == CapacityMode.loaded;
  var low = exercise.spec.low;
  var high = exercise.spec.high;
  for (final s in used) {
    if (s.low < low) {
      low = s.low;
    }
    if (s.high > high) {
      high = s.high;
    }
  }
  final first = used.first;
  final firstLoad = first.loadKg;
  if (exercise.calibrating) {
    reasons.add(
      reason(ReasonCodes.adaptCalibration, <String, Object?>{
        'session': track.filter.sessions + 1,
      }),
    );
  } else if (exercise.uncertain) {
    final sd = track.filter.loadSd(exercise.nPlan, withDay: false);
    reasons.add(
      reason(ReasonCodes.adaptLowConfidence, <String, Object?>{
        'confidence': roundTo(
          clampDouble(1 - sd / (2 * p.calibrationSd), 0, 1),
          3,
        ),
      }),
    );
  }
  final last = track.lastLoad;
  if (loaded && firstLoad != null && last != null) {
    final delta = roundTo(firstLoad - last, 2);
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
  final held = exercise.heldCause;
  if (held != null) {
    reasons.add(
      reason(ReasonCodes.adaptLoadHeld, <String, Object?>{'cause': held}),
    );
  }
  if (exercise.coarse && firstLoad != null) {
    reasons.add(
      reason(ReasonCodes.adaptIncrementCoarse, <String, Object?>{
        'stepKg': roundTo(info.grid.stepAbove(firstLoad), 3),
      }),
    );
  }
  for (final zone in exercise.painZones) {
    final state = run.state.pains[zone];
    final r = reason(ReasonCodes.adaptPainReported, <String, Object?>{
      'zone': zone.code,
      'intensity': state?.lastIntensity ?? 0,
    });
    if (!reasons.contains(r)) {
      reasons.add(r);
    }
  }
  if (used.last.open && !exercise.spec.test) {
    reasons.add(
      reason(ReasonCodes.adaptBenchmarkSet, <String, Object?>{
        'rir': rirOfFlames(used.last.flames),
      }),
    );
  }
  double? share;
  if (loaded && firstLoad != null) {
    final total = info.totalLoad(firstLoad, run.bodyWeightKg);
    final value = total / track.filter.capacity;
    share = roundTo(clampDouble(value, 0, 1.5), 3);
  }
  return ExercisePrescription(
    slotId: item.slotId,
    exerciseId: item.exerciseId,
    sets: used.length,
    repsLow: hold ? null : low,
    repsHigh: hold ? null : high,
    secondsLow: hold ? low : null,
    secondsHigh: hold ? high : null,
    targetFlames: flamesOfRir(exercise.rirEff),
    restSeconds: item.restSeconds,
    startLoadKg: loaded && firstLoad != null ? roundTo(firstLoad, 2) : null,
    percentOfOneRm: share,
    toCalibrate: exercise.uncertain,
    loadBasis: item.loadBasis,
    setTargets: <SetTarget>[
      for (final s in used)
        SetTarget(
          repsLow: hold ? null : s.low,
          repsHigh: hold ? null : s.high,
          secondsLow: hold ? s.low : null,
          secondsHigh: hold ? s.high : null,
          loadKg: s.loadKg == null ? null : roundTo(s.loadKg!, 2),
          flames: s.flames,
        ),
    ],
    groupId: item.groupId,
    format: item.format,
    kind: item.kind,
    reasons: reasons,
  );
}
