/// Passage entre l'état de la recherche et le contrat (`Pass1Plan`) :
/// ordre de la séance, rôles, thème du jour, raisons, identifiants
/// d'emplacement.
library;

import 'package:kalis_core/kalis_core.dart';

import 'context.dart';
import 'params.dart';
import 'scheme.dart';
import 'score.dart';
import 'state.dart';
import 'traits.dart';
import 'version.dart';

final RegExp _slotIdPattern = RegExp(r'^d(\d+)\.(\d+)$');

/// Identifiant de l'emplacement numéro [number] du jour de rang
/// [dayIndex]. Un emplacement ne change jamais de jour : déplacer un
/// exercice crée un emplacement dans le jour d'arrivée.
String slotIdFor(int dayIndex, int number) => 'd$dayIndex.$number';

/// Rang du jour porté par l'identifiant [slotId], ou `null` s'il n'a pas
/// la forme de [slotIdFor].
int? dayOfSlotId(String slotId) {
  final m = _slotIdPattern.firstMatch(slotId);
  return m == null ? null : int.parse(m.group(1)!);
}

int _numberOfSlotId(String slotId) {
  final m = _slotIdPattern.firstMatch(slotId);
  return m == null ? 0 : int.parse(m.group(2)!);
}

/// Codes du thème d'une séance (`PlanDay.focus`).
abstract final class FocusCodes {
  /// Mobilité.
  static const String mobility = 'mobility';

  /// Cardio en endurance.
  static const String cardioEndurance = 'cardio.endurance';

  /// Cardio fractionné ou intense.
  static const String cardioIntervals = 'cardio.intervals';

  /// Conditionnement (pièce de type WOD).
  static const String conditioning = 'conditioning';

  /// Figures.
  static const String skills = 'skills';

  /// Renforcement du bas du corps.
  static const String lower = 'strength.lower';

  /// Renforcement en poussée.
  static const String push = 'strength.push';

  /// Renforcement en tirage.
  static const String pull = 'strength.pull';

  /// Renforcement du haut du corps.
  static const String upper = 'strength.upper';

  /// Renforcement du corps entier.
  static const String fullBody = 'strength.full_body';

  /// Tous les codes.
  static const List<String> all = <String>[
    mobility,
    cardioEndurance,
    cardioIntervals,
    conditioning,
    skills,
    lower,
    push,
    pull,
    upper,
    fullBody,
  ];
}

/// Emplacement d'une séance, dans l'ordre de la séance.
final class OrderedSlot {
  /// Emplacement de rang [position] dans l'état.
  const OrderedSlot({
    required this.entry,
    required this.sets,
    required this.identity,
    required this.position,
    required this.role,
  });

  /// Exercice.
  final PoolEntry entry;

  /// Séries de référence.
  final int sets;

  /// Identité dans le registre de l'état, ou `unnamedSlot`.
  final int identity;

  /// Rang dans l'état.
  final int position;

  /// Rôle dans la séance.
  final SlotRole role;
}

bool _isDynamicMobility(PoolEntry e) {
  final p = e.exercise.pattern;
  return e.kind == SlotKind.mobility &&
      (p == MovementPattern.mobiliteArticulaire ||
          p == MovementPattern.etirementDynamique);
}

int _orderRank(PoolEntry e, bool cardioFirst, bool hasWork) {
  switch (e.kind) {
    case SlotKind.mobility:
      return hasWork && _isDynamicMobility(e) ? 0 : 90;
    case SlotKind.cardioEasy:
      if (e.scheme.kind == SchemeKind.cardioDrill) {
        return 15;
      }
      return cardioFirst ? 20 : 75;
    case SlotKind.cardioHard:
      return cardioFirst ? 20 : 75;
    case SlotKind.skillStatic:
    case SlotKind.skillDynamic:
      return 30;
    case SlotKind.power:
      return 40;
    case SlotKind.compound:
      return 50;
    case SlotKind.accessory:
      return 60;
    case SlotKind.core:
      return 65;
    case SlotKind.conditioning:
      return 70;
  }
}

int _bestSupport(PoolEntry e) {
  var best = 0;
  for (final s in e.goalSupport) {
    if (s > best) {
      best = s;
    }
  }
  return best;
}

/// Exercices du jour [day] de [state] dans l'ordre de la séance : mobilité
/// dynamique en échauffement, figures et puissance, polyarticulaires,
/// isolation, tronc, conditionnement et cardio, étirements. Quand le
/// cardio est la discipline principale, il passe avant le renforcement
/// (la priorité se travaille en premier).
List<OrderedSlot> orderedDay(PlanContext ctx, PlanState state, int day) {
  final cardioFirst =
      ctx.profile.disciplines.primary == TrainingDiscipline.cardio;
  final n = state.count[day];
  var hasWork = false;
  for (var i = 0; i < n; i++) {
    if (ctx.pool[state.exercise[day][i]].kind != SlotKind.mobility) {
      hasWork = true;
    }
  }
  final order = <int>[for (var i = 0; i < n; i++) i];
  order.sort((a, b) {
    final ea = ctx.pool[state.exercise[day][a]];
    final eb = ctx.pool[state.exercise[day][b]];
    final ra = _orderRank(ea, cardioFirst, hasWork);
    final rb = _orderRank(eb, cardioFirst, hasWork);
    if (ra != rb) {
      return ra.compareTo(rb);
    }
    if (ea.goalLift != eb.goalLift) {
      return ea.goalLift ? -1 : 1;
    }
    final sa = _bestSupport(ea);
    final sb = _bestSupport(eb);
    if (sa != sb) {
      return sb.compareTo(sa);
    }
    final fa = ea.exercise.systemicFatigue;
    final fb = eb.exercise.systemicFatigue;
    if (fa != fb) {
      return fb.compareTo(fa);
    }
    if (ea.exercise.difficulty != eb.exercise.difficulty) {
      return eb.exercise.difficulty.compareTo(ea.exercise.difficulty);
    }
    return ea.id.compareTo(eb.id);
  });
  var mainGiven = false;
  final out = <OrderedSlot>[];
  for (final at in order) {
    final e = ctx.pool[state.exercise[day][at]];
    SlotRole role;
    switch (e.kind) {
      case SlotKind.mobility:
        role = !hasWork
            ? SlotRole.mobility
            : (_isDynamicMobility(e) ? SlotRole.warmup : SlotRole.cooldown);
      case SlotKind.cardioEasy:
      case SlotKind.cardioHard:
      case SlotKind.conditioning:
        role = SlotRole.conditioning;
      case SlotKind.skillStatic:
      case SlotKind.skillDynamic:
        role = SlotRole.skill;
      case SlotKind.power:
      case SlotKind.compound:
        final explosive =
            e.exercise.pattern == MovementPattern.pliometrie ||
            e.exercise.pattern == MovementPattern.balistique;
        if (e.goalLift || (!mainGiven && !explosive)) {
          role = SlotRole.main;
          mainGiven = true;
        } else {
          role = SlotRole.secondary;
        }
      case SlotKind.accessory:
        role = SlotRole.accessory;
      case SlotKind.core:
        role = SlotRole.core;
    }
    out.add(
      OrderedSlot(
        entry: e,
        sets: state.sets[day][at],
        identity: state.uid[day][at],
        position: at,
        role: role,
      ),
    );
  }
  return out;
}

/// Thème du jour [day] de [state].
String focusOfDay(PlanContext ctx, PlanState state, int day) {
  var resistance = 0;
  var skill = 0;
  var cardio = 0;
  var hard = false;
  var conditioning = 0;
  var mobility = 0;
  var push = 0;
  var pull = 0;
  var legs = 0;
  for (var i = 0; i < state.count[day]; i++) {
    final e = ctx.pool[state.exercise[day][i]];
    final sets = state.sets[day][i];
    final seconds = e.scheme.secondsFor(sets);
    switch (e.kind) {
      case SlotKind.mobility:
        mobility += seconds;
      case SlotKind.cardioHard:
        cardio += seconds;
        hard = true;
      case SlotKind.cardioEasy:
        cardio += seconds;
      case SlotKind.conditioning:
        conditioning += seconds;
      case SlotKind.skillStatic:
      case SlotKind.skillDynamic:
        skill += seconds;
      case SlotKind.power:
      case SlotKind.compound:
      case SlotKind.accessory:
      case SlotKind.core:
        resistance += seconds;
    }
    push += sets * e.pushUnits;
    pull += sets * e.pullUnits;
    legs += sets * (e.kneeUnits + e.hipUnits);
  }
  var best = resistance;
  var code = '';
  if (skill > best) {
    best = skill;
    code = FocusCodes.skills;
  }
  if (cardio > best) {
    best = cardio;
    code = hard ? FocusCodes.cardioIntervals : FocusCodes.cardioEndurance;
  }
  if (conditioning > best) {
    best = conditioning;
    code = FocusCodes.conditioning;
  }
  if (mobility > best) {
    best = mobility;
    code = FocusCodes.mobility;
  }
  if (code.isNotEmpty) {
    return code;
  }
  final total = push + pull + legs;
  if (total == 0) {
    return FocusCodes.fullBody;
  }
  if (legs * 10 >= total * 7) {
    return FocusCodes.lower;
  }
  final upper = push + pull;
  if (upper * 10 >= total * 7) {
    if (push * 10 >= upper * 7) {
      return FocusCodes.push;
    }
    if (pull * 10 >= upper * 7) {
      return FocusCodes.pull;
    }
    return FocusCodes.upper;
  }
  return FocusCodes.fullBody;
}

/// Capacité à donner à un état qui doit contenir [plan].
int capacityFor(PlanParams params, Pass1Plan? plan) {
  var capacity = params.maxSlotsPerDay;
  if (plan != null) {
    for (final day in plan.days) {
      if (day.slots.length + 2 > capacity) {
        capacity = day.slots.length + 2;
      }
    }
  }
  return capacity;
}

/// État de la recherche pour le programme [plan]. Un emplacement est
/// verrouillé s'il l'est dans le programme, si un verrou `keep_slot` le
/// désigne ([lockedSlotIds]) ou si son jour est gelé ([lockedDays]). Un
/// exercice absent du vivier est ignoré (le contexte doit avoir été
/// construit avec les exercices du programme en `forcedIds`).
PlanState stateFromPlan(
  PlanContext ctx,
  Pass1Plan plan, {
  Set<String> lockedSlotIds = const <String>{},
  Set<int> lockedDays = const <int>{},
  int? capacity,
}) {
  final state = PlanState(
    ctx.dayCount,
    capacity ?? capacityFor(ctx.params, plan),
  );
  for (final day in plan.days) {
    final d = day.dayIndex;
    if (d < 0 || d >= ctx.dayCount) {
      continue;
    }
    for (final slot in day.slots) {
      final index = ctx.indexOf(slot.exerciseId);
      if (index < 0 || state.count[d] >= state.capacity) {
        continue;
      }
      final locked =
          slot.locked ||
          lockedSlotIds.contains(slot.slotId) ||
          lockedDays.contains(d);
      final identity = state.register(slot.slotId, isLocked: locked);
      state.add(d, index, ctx.defaultSets(ctx.pool[index], d), identity);
    }
  }
  return state;
}

/// Raison au format du registre.
Reason reason(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Raisons du choix de [entry] dans un programme noté par [scorer].
List<Reason> slotReasons(
  PlanContext ctx,
  Scorer scorer,
  PoolEntry entry, {
  required bool locked,
}) {
  final out = <Reason>[];
  if (locked) {
    out.add(reason(ReasonCodes.planLockKept));
  }
  var bestGoal = -1;
  var bestSupport = 69;
  for (var j = 0; j < ctx.goals.length; j++) {
    if (ctx.goals[j].goalId != null && entry.goalSupport[j] > bestSupport) {
      bestSupport = entry.goalSupport[j];
      bestGoal = j;
    }
  }
  if (bestGoal >= 0) {
    out.add(
      reason(ReasonCodes.planGoalSupport, <String, Object?>{
        'goalId': ctx.goals[bestGoal].goalId,
      }),
    );
  }
  if (entry.liked) {
    out.add(reason(ReasonCodes.planUserLikes));
  }
  out.add(
    reason(ReasonCodes.planDisciplineShare, <String, Object?>{
      'discipline': entry.cls.discipline.code,
      'pct': (ctx.targets[entry.cls.index] * 100).round(),
    }),
  );
  if (entry.kind.isResistance) {
    for (var k = 0; k < entry.creditGroups.length; k++) {
      final g = MuscleGroup.values[entry.creditGroups[k]];
      if (entry.creditValues[k] == 2 && g.major) {
        out.add(
          reason(ReasonCodes.planMuscleVolume, <String, Object?>{
            'muscle': g.code,
            'weeklySets': _round2(scorer.weeklySets(g)),
            'targetLow': _round2(ctx.bandLow[g.index] / 2),
            'targetHigh': _round2(ctx.bandHigh[g.index] / 2),
          }),
        );
        break;
      }
    }
  }
  out.add(
    reason(ReasonCodes.planLevelMatch, <String, Object?>{
      'difficulty': entry.exercise.difficulty,
    }),
  );
  return out;
}

/// Note au format du contrat, d'après le dernier `evaluate` de [scorer].
PlanScore planScoreOf(Scorer scorer) {
  final weights = scorer.context.params.weights.values;
  return PlanScore(
    total: _clamp01(scorer.total),
    components: <ScoreComponent>[
      for (var i = 0; i < ScoreWeights.codes.length; i++)
        ScoreComponent(
          code: ScoreWeights.codes[i],
          value: _clamp01(scorer.components[i]),
          weight: weights[i],
        ),
    ],
  );
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Programme de passe 1 de l'état [state]. Les emplacements sans nom
/// reçoivent le plus petit numéro libre de leur jour (jamais celui d'un
/// emplacement connu du registre, même retiré).
Pass1Plan planFromState(
  PlanContext ctx,
  PlanState state,
  Scorer scorer, {
  required String blockId,
  required int blockIndex,
  required int weeks,
  required int seed,
  List<Reason> blockReasons = const <Reason>[],
}) {
  scorer.evaluate(state);
  final next = List<int>.filled(ctx.dayCount, 1);
  for (final id in state.slotIds) {
    final d = dayOfSlotId(id);
    if (d != null && d < ctx.dayCount) {
      final n = _numberOfSlotId(id) + 1;
      if (n > next[d]) {
        next[d] = n;
      }
    }
  }
  final used = <String>{...state.slotIds};
  final days = <PlanDay>[];
  for (var d = 0; d < ctx.dayCount; d++) {
    final slots = <PlanSlot>[];
    for (final s in orderedDay(ctx, state, d)) {
      String slotId;
      var locked = false;
      if (s.identity >= 0) {
        slotId = state.slotIds[s.identity];
        locked = state.locked[s.identity];
      } else {
        slotId = slotIdFor(d, next[d]);
        while (used.contains(slotId)) {
          next[d]++;
          slotId = slotIdFor(d, next[d]);
        }
        used.add(slotId);
        next[d]++;
      }
      slots.add(
        PlanSlot(
          slotId: slotId,
          exerciseId: s.entry.id,
          role: s.role,
          locked: locked,
          reasons: slotReasons(ctx, scorer, s.entry, locked: locked),
        ),
      );
    }
    days.add(
      PlanDay(
        dayIndex: d,
        weekday: ctx.days[d].weekday,
        minutesBudget: ctx.days[d].minutes > 300 ? 300 : ctx.days[d].minutes,
        focus: focusOfDay(ctx, state, d),
        slots: slots,
      ),
    );
  }
  final reasons = <Reason>[
    if (ctx.cautious) reason(ReasonCodes.planCautiousHealth),
    ...blockReasons,
  ];
  return Pass1Plan(
    blockId: blockId,
    blockIndex: blockIndex,
    weeks: weeks,
    startDate: ctx.startDate,
    seed: seed,
    engineVersion: kalisPlanVersion,
    days: days,
    score: planScoreOf(scorer),
    reasons: reasons,
  );
}
