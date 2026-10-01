/// `KalisPlan` : réalisation de l'interface `PlanEngine` de `kalis_core`.
library;

import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';

import 'assemble.dart';
import 'context.dart';
import 'diff.dart';
import 'hash.dart';
import 'params.dart';
import 'pass2.dart';
import 'score.dart';
import 'search.dart';
import 'state.dart';
import 'traits.dart';
import 'variants.dart';
import 'version.dart';

/// Identifiant du bloc de rang [blockIndex] commençant le [startDate].
String blockIdFor(int blockIndex, CivilDate startDate) =>
    'kp-b$blockIndex-${startDate.iso}';

/// Profil mis à jour par ce qu'une action de revue a appris (à faire par
/// l'application après chaque `review`, INTEGRATION.md de kalis_core).
AthleteProfile applyProfileDelta(AthleteProfile profile, ProfileDelta delta) {
  List<String> merged(List<String>? base, List<String> add, Set<String> drop) {
    final out = <String>[
      for (final id in base ?? const <String>[])
        if (!drop.contains(id)) id,
    ];
    for (final id in add) {
      if (!out.contains(id)) {
        out.add(id);
      }
    }
    return out;
  }

  final known = delta.knownExerciseIds.toSet();
  final unknown = delta.unknownExerciseIds.toSet();
  final liked = delta.likedExerciseIds.toSet();
  final disliked = delta.dislikedExerciseIds.toSet();
  return profile.copyWith(
    knownExerciseIds: merged(
      profile.knownExerciseIds,
      delta.knownExerciseIds,
      unknown,
    ),
    cannotDoExerciseIds: merged(
      profile.cannotDoExerciseIds,
      delta.unknownExerciseIds,
      known,
    ),
    likedExerciseIds: merged(
      profile.likedExerciseIds,
      delta.likedExerciseIds,
      disliked,
    ),
    dislikedExerciseIds: merged(
      profile.dislikedExerciseIds,
      delta.dislikedExerciseIds,
      liked,
    ),
  );
}

/// Résultat d'une revue et programme de référence : le programme juste
/// après l'action de l'utilisateur, avant la ré-optimisation. Sert aux
/// tests (diff minimal) et à l'inspecteur du mode dev.
final class ReviewTrace {
  /// Trace.
  const ReviewTrace({
    required this.result,
    required this.reference,
    required this.profile,
  });

  /// Résultat rendu par `review`.
  final ReviewResult result;

  /// Programme après l'action seule.
  final Pass1Plan reference;

  /// Profil mis à jour par l'action (`applyProfileDelta`).
  final AthleteProfile profile;
}

final class _Chain {
  _Chain(this.key, this.context, this.planner, this.weeks);

  final String key;
  final PlanContext context;
  final Planner planner;
  final int weeks;
  final List<PlanState> proposals = <PlanState>[];
  double bestTotal = 0;
  int bestBucket = 0;
}

/// Programme régénéré à partir d'un programme existant.
final class _Regenerated {
  _Regenerated(this.context, this.scorer, this.state, this.plan, this.reasons);

  final PlanContext context;
  final Scorer scorer;
  final PlanState state;
  final Pass1Plan plan;

  /// Raisons propres à un emplacement (rotation, progression, adaptation).
  final Map<String, List<Reason>> reasons;
}

/// Moteur statique de Kalis Track.
///
/// Fonctions pures : même requête, même résultat à l'octet près. L'instance
/// garde en mémoire la dernière suite de propositions (« Autre
/// proposition ») pour ne pas la recalculer ; ce cache ne change aucun
/// résultat.
final class KalisPlan implements PlanEngine {
  /// Moteur de paramètres [params].
  KalisPlan({this.params = PlanParams.standard});

  /// Paramètres.
  final PlanParams params;

  /// Nombre de propositions distinctes par requête : la graine est lue
  /// modulo ce nombre.
  static const int alternativeCycle = 16;

  _Chain? _chain;

  @override
  String get engineVersion => kalisPlanVersion;

  void _check(Catalog catalog, AthleteProfile profile) {
    final violations = <Violation>[
      ...profile.validate(),
      ...catalog.checkProfile(profile),
    ];
    if (violations.isNotEmpty) {
      final v = violations.first;
      throw ArgumentError(
        'Profil invalide (${violations.length} violation(s)) : '
        '${v.path} ${v.code} ${v.message}',
      );
    }
  }

  // ---------------------------------------------------------------- passe 1

  @override
  Pass1Plan createPass1(Catalog catalog, PlanRequest request) {
    _check(catalog, request.profile);
    final previous = request.previousBlock;
    if (previous != null) {
      return _evolve(
        catalog,
        profile: request.profile,
        seed: request.seed,
        startDate: request.startDate,
        previous: previous,
        adaptation: request.adaptation,
        locks: request.locks,
        blockWeeks: request.blockWeeks,
      ).plan;
    }
    final index = request.seed % alternativeCycle;
    final key = jsonEncode(request.copyWith(seed: 0).toJson());
    var chain = _chain;
    if (chain == null || chain.key != key) {
      chain = _startChain(catalog, request, key);
      _chain = chain;
    }
    while (chain.proposals.length <= index) {
      _extendChain(chain);
    }
    final reasons = <Reason>[
      if (request.adaptation != null)
        reason(ReasonCodes.planAdaptationApplied, <String, Object?>{
          'proposalKind': ProposalKind.volume.code,
        }),
    ];
    return planFromState(
      chain.context,
      chain.proposals[index],
      chain.planner.scorer,
      blockId: blockIdFor(0, request.startDate),
      blockIndex: 0,
      weeks: chain.weeks,
      seed: request.seed,
      blockReasons: reasons,
    );
  }

  _Chain _startChain(Catalog catalog, PlanRequest request, String key) {
    final forced = <String>{
      for (final lock in request.locks)
        if (lock.kind == LockKind.keepSlot && lock.exerciseId != null)
          lock.exerciseId!,
    };
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: request.startDate,
        seed: 0,
        locks: request.locks,
        adaptation: request.adaptation,
        forcedIds: forced,
        volumeScale: adaptationVolumeScale(request.adaptation),
        params: params,
      ),
    );
    final planner = Planner(ctx, 0);
    final state = PlanState(ctx.dayCount, params.maxSlotsPerDay);
    for (final lock in request.locks) {
      final slotId = lock.slotId;
      final exerciseId = lock.exerciseId;
      if (lock.kind != LockKind.keepSlot ||
          slotId == null ||
          exerciseId == null) {
        continue;
      }
      final d = dayOfSlotId(slotId);
      final at = ctx.indexOf(exerciseId);
      if (d == null ||
          d >= ctx.dayCount ||
          at < 0 ||
          state.count[d] >= state.capacity ||
          state.dayHas(d, at) ||
          state.slotIds.contains(slotId)) {
        continue;
      }
      final identity = state.register(slotId, isLocked: true);
      state.add(d, at, ctx.defaultSets(ctx.pool[at], d), identity);
    }
    _placeRequired(ctx, planner, state);
    planner.construct(state);
    planner.anneal(state, params.annealIterations);
    planner.polish(state);
    planner.scorer.evaluate(state);
    final chain =
        _Chain(
            key,
            ctx,
            planner,
            request.blockWeeks ?? defaultBlockWeeks(ctx.globalLevel),
          )
          ..bestTotal = planner.scorer.total
          ..bestBucket = planner.scorer.safetyBucket;
    chain.proposals.add(state);
    planner.addPrevious(state);
    return chain;
  }

  /// Place chaque exercice exigé par un verrou `require_exercise` et
  /// absent du programme, le jour où il nuit le moins à la note.
  void _placeRequired(PlanContext ctx, Planner planner, PlanState state) {
    final required = ctx.requiredIds.toList()..sort();
    for (final id in required) {
      final at = ctx.indexOf(id);
      if (at < 0 || state.occurrences(at) > 0) {
        continue;
      }
      final e = ctx.pool[at];
      var bestDay = -1;
      var bestValue = double.negativeInfinity;
      for (final feasibleOnly in const <bool>[true, false]) {
        for (var d = 0; d < ctx.dayCount; d++) {
          if (state.count[d] >= state.capacity ||
              planner.frozenDays.contains(d) ||
              (feasibleOnly && !e.feasibleOn(d))) {
            continue;
          }
          final pos = state.add(d, at, ctx.defaultSets(e, d), unnamedSlot);
          final value = planner.objective(state);
          state.removeAt(d, pos);
          if (value > bestValue) {
            bestValue = value;
            bestDay = d;
          }
        }
        if (bestDay >= 0) {
          break;
        }
      }
      if (bestDay >= 0) {
        state.add(bestDay, at, ctx.defaultSets(e, bestDay), unnamedSlot);
      }
    }
  }

  /// Proposition suivante de la suite : la plus différente des précédentes
  /// qui garde le palier de sécurité et une note à moins de 3 % de la
  /// meilleure. Si aucune n'atteint un tiers d'exercices différents, la
  /// plus éloignée de celles qui respectent la note est rendue.
  void _extendChain(_Chain chain) {
    final planner = chain.planner;
    final scorer = planner.scorer;
    final rank = chain.proposals.length;
    final base = chain.proposals.first;
    PlanState? chosen;
    var chosenDistance = -1.0;
    const weights = <double>[3, 1, 0.3];
    for (var attempt = 0; attempt < weights.length; attempt++) {
      final candidate = base.copy();
      planner.reseed(rank * 7919 + attempt);
      planner.diversityWeight = weights[attempt];
      planner.anneal(candidate, params.alternativeIterations);
      planner.polish(candidate);
      planner.diversityWeight = 0;
      scorer.evaluate(candidate);
      final ok =
          scorer.safetyBucket >= chain.bestBucket &&
          scorer.total >=
              (1 - params.alternativeTolerance) * chain.bestTotal - 1e-12;
      if (!ok) {
        continue;
      }
      final distance = planner.minDistanceToPrevious(candidate);
      if (distance > chosenDistance) {
        chosen = candidate;
        chosenDistance = distance;
      }
      if (distance >= params.alternativeMinDistance - 1e-12) {
        break;
      }
    }
    final next = chosen ?? base.copy();
    chain.proposals.add(next);
    planner.addPrevious(next);
  }

  // ----------------------------------------------------------------- revue

  @override
  ReviewResult review(Catalog catalog, ReviewRequest request) =>
      reviewTraced(catalog, request).result;

  /// Comme [review], avec le programme de référence (après l'action seule)
  /// et le profil mis à jour.
  ReviewTrace reviewTraced(Catalog catalog, ReviewRequest request) {
    final base = request.request;
    final current = request.current;
    final action = request.action;
    _check(catalog, base.profile);
    final violations = action.validate();
    if (violations.isNotEmpty) {
      throw ArgumentError(
        'Action de revue invalide : ${violations.first.code}',
      );
    }

    PlanSlot? target;
    var targetDay = -1;
    final slotId = action.slotId;
    if (slotId != null) {
      for (final day in current.days) {
        for (final slot in day.slots) {
          if (slot.slotId == slotId) {
            target = slot;
            targetDay = day.dayIndex;
          }
        }
      }
    }
    final needsSlot = action.kind != ReviewKind.add;
    if (needsSlot && target == null) {
      throw ArgumentError.value(slotId, 'slotId', 'emplacement inconnu');
    }
    for (final id in <String?>[
      action.exerciseId,
      action.replacementExerciseId,
    ]) {
      if (id != null && !catalog.contains(id)) {
        throw ArgumentError.value(id, 'exerciseId', 'exercice inconnu');
      }
    }

    final locks = <PlanLock>[...base.locks];
    void addLock(PlanLock lock) {
      if (!locks.contains(lock)) {
        locks.add(lock);
      }
    }

    void dropSlotLocks(String id) {
      locks.removeWhere((l) => l.kind == LockKind.keepSlot && l.slotId == id);
    }

    var delta = const ProfileDelta(
      knownExerciseIds: <String>[],
      unknownExerciseIds: <String>[],
      likedExerciseIds: <String>[],
      dislikedExerciseIds: <String>[],
    );

    // « Je sais faire » : un verrou, rien ne bouge.
    if (action.kind == ReviewKind.canDo) {
      final slot = target!;
      dropSlotLocks(slot.slotId);
      addLock(
        PlanLock(
          kind: LockKind.keepSlot,
          slotId: slot.slotId,
          exerciseId: slot.exerciseId,
        ),
      );
      delta = delta.copyWith(knownExerciseIds: <String>[slot.exerciseId]);
      final plan = current.copyWith(
        days: <PlanDay>[
          for (final day in current.days)
            day.copyWith(
              slots: <PlanSlot>[
                for (final s in day.slots)
                  s.slotId == slot.slotId ? s.copyWith(locked: true) : s,
              ],
            ),
        ],
      );
      return ReviewTrace(
        result: ReviewResult(
          plan: plan,
          diff: const PlanDiff(changes: <PlanChange>[]),
          locks: locks,
          profileDelta: delta,
        ),
        reference: plan,
        profile: applyProfileDelta(base.profile, delta),
      );
    }

    final forced = <String>{
      for (final day in current.days)
        for (final slot in day.slots) slot.exerciseId,
    };
    switch (action.kind) {
      case ReviewKind.cannotDo:
        final slot = target!;
        dropSlotLocks(slot.slotId);
        addLock(
          PlanLock(kind: LockKind.excludeExercise, exerciseId: slot.exerciseId),
        );
        delta = delta.copyWith(unknownExerciseIds: <String>[slot.exerciseId]);
      case ReviewKind.dislike:
        final slot = target!;
        dropSlotLocks(slot.slotId);
        addLock(
          PlanLock(kind: LockKind.excludeExercise, exerciseId: slot.exerciseId),
        );
        delta = delta.copyWith(dislikedExerciseIds: <String>[slot.exerciseId]);
      case ReviewKind.add:
        final id = action.exerciseId!;
        forced.add(id);
        locks.removeWhere(
          (l) => l.kind == LockKind.excludeExercise && l.exerciseId == id,
        );
        delta = delta.copyWith(likedExerciseIds: <String>[id]);
      case ReviewKind.remove:
        dropSlotLocks(target!.slotId);
      case ReviewKind.replace:
        final id = action.replacementExerciseId!;
        forced.add(id);
        locks.removeWhere(
          (l) => l.kind == LockKind.excludeExercise && l.exerciseId == id,
        );
        dropSlotLocks(target!.slotId);
        addLock(
          PlanLock(
            kind: LockKind.keepSlot,
            slotId: target.slotId,
            exerciseId: id,
          ),
        );
      case ReviewKind.canDo:
        break;
    }
    final profile = applyProfileDelta(base.profile, delta);

    // Emplacement de l'ajout : identifiant neuf, verrouillé.
    String? addedSlotId;
    if (action.kind == ReviewKind.add) {
      final d = action.dayIndex!;
      if (d < 0 || d >= current.days.length) {
        throw ArgumentError.value(d, 'dayIndex', 'jour inconnu');
      }
      final existing = <String>{
        for (final day in current.days)
          for (final s in day.slots) s.slotId,
        for (final l in locks)
          if (l.slotId != null) l.slotId!,
      };
      var n = current.days[d].slots.length + 1;
      while (existing.contains(slotIdFor(d, n))) {
        n++;
      }
      addedSlotId = slotIdFor(d, n);
    }

    final lockedSlots = <String>{};
    final lockedDays = <int>{};
    for (final l in locks) {
      if (l.kind == LockKind.keepSlot && l.slotId != null) {
        lockedSlots.add(l.slotId!);
      } else if (l.kind == LockKind.keepDay && l.dayIndex != null) {
        lockedDays.add(l.dayIndex!);
      }
    }
    if (targetDay >= 0) {
      lockedDays.remove(targetDay);
    }
    if (action.kind == ReviewKind.add) {
      lockedDays.remove(action.dayIndex);
    }

    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: profile,
        startDate: base.startDate,
        seed: 0,
        locks: locks,
        adaptation: base.adaptation,
        forcedIds: forced,
        volumeScale: adaptationVolumeScale(base.adaptation),
        params: params,
      ),
    );
    final planner = Planner(ctx, fnv1a32('review:${current.seed}:$slotId'));
    planner.frozenDays = lockedDays;
    final unlockedCurrent =
        action.kind == ReviewKind.replace ||
            action.kind == ReviewKind.remove ||
            action.kind == ReviewKind.cannotDo ||
            action.kind == ReviewKind.dislike
        ? _withSlotUnlocked(current, slotId!)
        : current;
    final state = stateFromPlan(
      ctx,
      unlockedCurrent,
      lockedSlotIds: lockedSlots,
      capacity: capacityFor(params, current) + 1,
    );
    final scorer = planner.scorer;

    // L'action seule.
    final actedReasons = <Reason>[];
    switch (action.kind) {
      case ReviewKind.add:
        final d = action.dayIndex!;
        final at = ctx.indexOf(action.exerciseId!);
        actedReasons.add(reason(ReasonCodes.planUserAdded));
        var existingAt = -1;
        for (var i = 0; i < state.count[d]; i++) {
          if (state.exercise[d][i] == at) {
            existingAt = i;
          }
        }
        if (existingAt >= 0) {
          // Déjà dans la séance : l'emplacement existant est verrouillé.
          final identity = state.uid[d][existingAt];
          state.locked[identity] = true;
          addedSlotId = state.slotIds[identity];
        } else {
          final identity = state.register(addedSlotId!, isLocked: true);
          state.add(d, at, ctx.defaultSets(ctx.pool[at], d), identity);
        }
        addLock(
          PlanLock(
            kind: LockKind.keepSlot,
            slotId: addedSlotId,
            exerciseId: action.exerciseId,
          ),
        );
      case ReviewKind.remove:
        final at = _positionOfSlot(state, targetDay, slotId!);
        actedReasons.add(reason(ReasonCodes.planUserRemoved));
        if (at >= 0) {
          state.removeAt(targetDay, at);
        }
      case ReviewKind.replace:
        final at = _positionOfSlot(state, targetDay, slotId!);
        final to = ctx.indexOf(action.replacementExerciseId!);
        actedReasons.add(reason(ReasonCodes.planUserReplaced));
        if (at >= 0) {
          state.exercise[targetDay][at] = to;
          state.sets[targetDay][at] = ctx.defaultSets(ctx.pool[to], targetDay);
          state.locked[state.uid[targetDay][at]] = true;
        }
      case ReviewKind.cannotDo:
      case ReviewKind.dislike:
        final at = _positionOfSlot(state, targetDay, slotId!);
        final cannot = action.kind == ReviewKind.cannotDo;
        actedReasons.add(
          reason(
            cannot
                ? ReasonCodes.planUserCannotDo
                : ReasonCodes.planUserDislikes,
          ),
        );
        if (at >= 0) {
          final old = ctx.pool[state.exercise[targetDay][at]];
          final picked = _replaceSlot(
            ctx,
            planner,
            state,
            targetDay,
            at,
            easierFirst: cannot,
          );
          if (cannot && picked != null) {
            actedReasons.add(
              reason(ReasonCodes.planVariantEasier, <String, Object?>{
                'difficultyDelta':
                    picked.exercise.difficulty - old.exercise.difficulty,
              }),
            );
          }
        }
      case ReviewKind.canDo:
        break;
    }

    final reference = state.copy();
    final referencePlan = planFromState(
      ctx,
      reference,
      scorer,
      blockId: current.blockId,
      blockIndex: current.blockIndex,
      weeks: current.weeks,
      seed: current.seed,
    );
    final scoreBefore = scorer.total;
    final overBudget = <int>{
      for (var d = 0; d < ctx.dayCount; d++)
        if (scorer.timeOfDay(reference, d) > ctx.days[d].seconds) d,
    };
    // Les emplacements sans nom de la référence reçoivent leur nom avant la
    // recherche : la pénalité de changement les reconnaît.
    _nameUnnamed(state, referencePlan, ctx);
    final named = state.copy();
    planner.setReference(named);
    planner.repair(state);
    planner.anneal(state, params.reviewIterations);
    planner.polish(state);
    planner.revertUnpaidChanges(state, named);

    final plan = planFromState(
      ctx,
      state,
      scorer,
      blockId: current.blockId,
      blockIndex: current.blockIndex,
      weeks: current.weeks,
      seed: current.seed,
    );
    final scoreAfter = scorer.total;
    final actedSlot = action.kind == ReviewKind.add ? addedSlotId : slotId;
    final diff = diffPlans(
      current,
      plan,
      reasons: (kind, changedSlot, from, to) {
        if (changedSlot != null && changedSlot == actedSlot) {
          return actedReasons;
        }
        return <Reason>[
          reason(ReasonCodes.planReoptimized, <String, Object?>{
            'scoreBefore': _round4(scoreBefore),
            'scoreAfter': _round4(scoreAfter),
          }),
          if (changedSlot != null)
            for (final d in overBudget)
              if (dayOfSlotId(changedSlot) == d)
                reason(ReasonCodes.planTimeBudget, <String, Object?>{
                  'minutes': ctx.days[d].minutes,
                }),
        ];
      },
    );
    // Un verrou dont l'emplacement a disparu ne sert plus.
    final alive = <String>{
      for (final day in plan.days)
        for (final s in day.slots) s.slotId,
    };
    locks.removeWhere(
      (l) =>
          l.kind == LockKind.keepSlot &&
          l.slotId != null &&
          !alive.contains(l.slotId),
    );
    return ReviewTrace(
      result: ReviewResult(
        plan: plan,
        diff: diff,
        locks: locks,
        profileDelta: delta,
      ),
      reference: referencePlan,
      profile: profile,
    );
  }

  Pass1Plan _withSlotUnlocked(Pass1Plan plan, String slotId) {
    return plan.copyWith(
      days: <PlanDay>[
        for (final day in plan.days)
          day.copyWith(
            slots: <PlanSlot>[
              for (final s in day.slots)
                s.slotId == slotId ? s.copyWith(locked: false) : s,
            ],
          ),
      ],
    );
  }

  int _positionOfSlot(PlanState state, int day, String slotId) {
    for (var i = 0; i < state.count[day]; i++) {
      final identity = state.uid[day][i];
      if (identity >= 0 && state.slotIds[identity] == slotId) {
        return i;
      }
    }
    return -1;
  }

  /// Donne aux emplacements sans nom de [state] le nom qu'ils portent dans
  /// [plan] (même jour, même exercice).
  void _nameUnnamed(PlanState state, Pass1Plan plan, PlanContext ctx) {
    for (var d = 0; d < state.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        if (state.uid[d][i] >= 0) {
          continue;
        }
        final id = ctx.pool[state.exercise[d][i]].id;
        for (final slot in plan.days[d].slots) {
          if (slot.exerciseId == id) {
            state.uid[d][i] = state.register(slot.slotId, isLocked: false);
            break;
          }
        }
      }
    }
  }

  /// Remplace l'exercice de l'emplacement de rang [at] du jour [day] : par
  /// sa variante plus facile si [easierFirst], sinon par le candidat qui
  /// donne la meilleure note parmi les plus proches. Sans candidat,
  /// l'emplacement est retiré. Rend l'exercice choisi, ou `null`.
  PoolEntry? _replaceSlot(
    PlanContext ctx,
    Planner planner,
    PlanState state,
    int day,
    int at, {
    required bool easierFirst,
  }) {
    final current = ctx.pool[state.exercise[day][at]];
    final candidates = <VariantCandidate>[
      for (final c in admissibleReplacements(
        ctx,
        planner.scorer,
        state,
        day,
        at,
      ))
        if (!planner.banned.contains(c.entry.index)) c,
    ];
    PoolEntry? picked;
    if (easierFirst) {
      picked = easierVariant(ctx.catalog, current, candidates)?.entry;
    }
    if (picked == null) {
      final old = state.exercise[day][at];
      final oldSets = state.sets[day][at];
      var bestValue = double.negativeInfinity;
      var tried = 0;
      for (final c in candidates) {
        if (c.similarity < 0.35 || tried >= 8) {
          break;
        }
        tried++;
        state.exercise[day][at] = c.entry.index;
        state.sets[day][at] = ctx.defaultSets(c.entry, day);
        final value = planner.objective(state) + 0.02 * c.similarity;
        if (value > bestValue) {
          bestValue = value;
          picked = c.entry;
        }
      }
      state.exercise[day][at] = old;
      state.sets[day][at] = oldSets;
    }
    if (picked == null) {
      state.removeAt(day, at);
      return null;
    }
    state.exercise[day][at] = picked.index;
    state.sets[day][at] = ctx.defaultSets(picked, day);
    return picked;
  }

  // -------------------------------------------------------------- variantes

  @override
  VariantSet variants(Catalog catalog, VariantsRequest request) {
    final base = request.request;
    final current = request.current;
    _check(catalog, base.profile);
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: base.profile,
        startDate: base.startDate,
        seed: 0,
        locks: base.locks,
        adaptation: base.adaptation,
        forcedIds: <String>{
          for (final day in current.days)
            for (final slot in day.slots) slot.exerciseId,
        },
        volumeScale: adaptationVolumeScale(base.adaptation),
        params: params,
      ),
    );
    final state = stateFromPlan(ctx, current);
    for (var d = 0; d < state.dayCount; d++) {
      final at = _positionOfSlot(state, d, request.slotId);
      if (at >= 0) {
        return computeVariants(ctx, Scorer(ctx), state, d, at, request.slotId);
      }
    }
    throw ArgumentError.value(request.slotId, 'slotId', 'emplacement inconnu');
  }

  // ---------------------------------------------------------------- passe 2

  @override
  Pass2Plan createPass2(Catalog catalog, Pass2Request request) {
    final base = request.request;
    _check(catalog, base.profile);
    final pass1 = request.pass1;
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: base.profile,
        startDate: pass1.startDate,
        seed: 0,
        locks: base.locks,
        adaptation: base.adaptation,
        forcedIds: <String>{
          for (final day in pass1.days)
            for (final slot in day.slots) slot.exerciseId,
        },
        volumeScale: adaptationVolumeScale(base.adaptation),
        params: params,
      ),
    );
    final scorer = Scorer(ctx);
    final state = stateFromPlan(ctx, pass1);
    tuneSets(ctx, scorer, state);
    return buildPass2(ctx, scorer, state, pass1);
  }

  // ------------------------------------------------------- blocs glissants

  @override
  BlockProposal nextBlock(Catalog catalog, NextBlockRequest request) {
    _check(catalog, request.profile);
    final r = _evolve(
      catalog,
      profile: request.profile,
      seed: request.seed,
      startDate: request.startDate,
      previous: request.previous,
      adaptation: request.adaptation,
      locks: request.locks,
      blockWeeks: null,
    );
    tuneSets(r.context, r.scorer, r.state);
    final pass2 = buildPass2(r.context, r.scorer, r.state, r.plan);
    final diff = diffPlans(
      request.previous.pass1,
      r.plan,
      reasons: (kind, slotId, from, to) {
        final own = slotId == null ? null : r.reasons[slotId];
        if (own != null) {
          return own;
        }
        return <Reason>[
          reason(ReasonCodes.planReoptimized, <String, Object?>{
            'scoreBefore': _round4(request.previous.pass1.score.total),
            'scoreAfter': _round4(r.plan.score.total),
          }),
        ];
      },
    );
    return BlockProposal(
      block: ProgramBlock(pass1: r.plan, pass2: pass2),
      diff: diff,
    );
  }

  /// Passe 1 du bloc qui suit [previous] : les mouvements principaux
  /// restent, une part des exercices d'assistance tourne, les exercices
  /// maîtrisés progressent d'un palier, les exercices mal tolérés ou
  /// devenus inadmissibles sont remplacés, les volumes suivent le résumé
  /// d'adaptation.
  _Regenerated _evolve(
    Catalog catalog, {
    required AthleteProfile profile,
    required int seed,
    required CivilDate startDate,
    required ProgramBlock previous,
    required AdaptationSummary? adaptation,
    required List<PlanLock> locks,
    required int? blockWeeks,
  }) {
    final before = previous.pass1;
    final blockIndex = before.blockIndex + 1;
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: profile,
        startDate: startDate,
        seed: seed,
        locks: locks,
        adaptation: adaptation,
        forcedIds: <String>{
          for (final day in before.days)
            for (final slot in day.slots) slot.exerciseId,
        },
        volumeScale: adaptationVolumeScale(adaptation),
        params: params,
      ),
    );
    final lockedSlots = <String>{};
    final lockedDays = <int>{};
    for (final l in locks) {
      if (l.kind == LockKind.keepSlot && l.slotId != null) {
        lockedSlots.add(l.slotId!);
      } else if (l.kind == LockKind.keepDay && l.dayIndex != null) {
        lockedDays.add(l.dayIndex!);
      }
    }
    // Les validations de la revue du bloc précédent ne gèlent pas le bloc
    // suivant : seuls les verrous de la requête comptent.
    final unlocked = before.copyWith(
      days: <PlanDay>[
        for (final day in before.days)
          day.copyWith(
            slots: <PlanSlot>[
              for (final s in day.slots) s.copyWith(locked: false),
            ],
          ),
      ],
    );
    final planner = Planner(ctx, fnvMix(fnv1a32('next'), seed + blockIndex));
    planner.frozenDays = lockedDays;
    final state = stateFromPlan(
      ctx,
      unlocked,
      lockedSlotIds: lockedSlots,
      lockedDays: lockedDays,
    );
    final reasons = <String, List<Reason>>{};

    bool free(int d, int i) {
      final identity = state.uid[d][i];
      return !lockedDays.contains(d) &&
          !(identity >= 0 && state.locked[identity]);
    }

    // 1. Exercices mal tolérés ou devenus inadmissibles.
    for (var d = 0; d < ctx.dayCount; d++) {
      var i = 0;
      while (i < state.count[d]) {
        final e = ctx.pool[state.exercise[d][i]];
        if (!free(d, i) || (e.selectable && e.feasibleOn(d))) {
          i++;
          continue;
        }
        final slotId = state.slotIds[state.uid[d][i]];
        final painful = e.jointPenalty > 0;
        final picked = _replaceSlot(
          ctx,
          planner,
          state,
          d,
          i,
          easierFirst: false,
        );
        reasons[slotId] = <Reason>[
          reason(ReasonCodes.planAdaptationApplied, <String, Object?>{
            'proposalKind': painful
                ? ProposalKind.painSparing.code
                : ProposalKind.exerciseSwap.code,
          }),
        ];
        if (picked != null) {
          i++;
        }
      }
    }

    // 2. Progression des exercices maîtrisés : un palier plus dur de la
    // même chaîne, s'il est admissible.
    for (var d = 0; d < ctx.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        if (!free(d, i)) {
          continue;
        }
        final e = ctx.pool[state.exercise[d][i]];
        final reps = e.knownMaxReps;
        final hold = e.knownMaxHoldSeconds;
        final mastered =
            !e.scheme.loaded &&
            ((reps != null && reps >= 15) ||
                (hold != null && hold >= (e.kind.isSkill ? 15 : 60)));
        if (!mastered) {
          continue;
        }
        PoolEntry? harder;
        for (final c in admissibleReplacements(
          ctx,
          planner.scorer,
          state,
          d,
          i,
        )) {
          final x = c.entry.exercise;
          final step = x.difficulty - e.exercise.difficulty;
          if (x.rootId != e.exercise.rootId ||
              x.pattern != e.exercise.pattern ||
              step < 1 ||
              step > 2) {
            continue;
          }
          if (harder == null || x.difficulty < harder.exercise.difficulty) {
            harder = c.entry;
          }
        }
        if (harder != null) {
          final slotId = state.slotIds[state.uid[d][i]];
          reasons[slotId] = <Reason>[
            reason(
              ReasonCodes.planProgressionFromPreviousBlock,
              <String, Object?>{'exerciseId': e.id},
            ),
          ];
          state.exercise[d][i] = harder.index;
          state.sets[d][i] = ctx.defaultSets(harder, d);
        }
      }
    }

    // 3. Rotation partielle de l'assistance.
    final rotatable = <(int, String, int)>[];
    for (var d = 0; d < ctx.dayCount; d++) {
      for (var i = 0; i < state.count[d]; i++) {
        final e = ctx.pool[state.exercise[d][i]];
        final slotId = state.slotIds[state.uid[d][i]];
        final assistance =
            e.kind == SlotKind.accessory ||
            e.kind == SlotKind.core ||
            e.kind == SlotKind.mobility ||
            e.kind == SlotKind.conditioning;
        if (!free(d, i) ||
            !assistance ||
            Scorer.repeatAllowed(e) && e.kind != SlotKind.mobility ||
            reasons.containsKey(slotId)) {
          continue;
        }
        rotatable.add((fnv1a32('$seed:$blockIndex:$slotId'), slotId, e.index));
      }
    }
    rotatable.sort((a, b) {
      final by = a.$1.compareTo(b.$1);
      return by != 0 ? by : a.$2.compareTo(b.$2);
    });
    final quota = (rotatable.length * params.rotationShare).ceil();
    final rotatedOut = <int>{};
    for (var k = 0; k < quota && k < rotatable.length; k++) {
      rotatedOut.add(rotatable[k].$3);
    }
    planner.banned.addAll(rotatedOut);
    for (var d = 0; d < ctx.dayCount; d++) {
      var i = 0;
      while (i < state.count[d]) {
        if (!free(d, i) || !rotatedOut.contains(state.exercise[d][i])) {
          i++;
          continue;
        }
        final slotId = state.slotIds[state.uid[d][i]];
        final picked = _replaceSlot(
          ctx,
          planner,
          state,
          d,
          i,
          easierFirst: false,
        );
        reasons[slotId] = <Reason>[reason(ReasonCodes.planVariety)];
        if (picked != null) {
          i++;
        }
      }
    }

    // 4. Ré-optimisation sous pénalité de changement.
    final reference = state.copy();
    planner.setReference(reference);
    planner.repair(state);
    planner.anneal(state, params.reviewIterations);
    planner.polish(state);
    planner.revertUnpaidChanges(state, reference);

    final plan = planFromState(
      ctx,
      state,
      planner.scorer,
      blockId: blockIdFor(blockIndex, startDate),
      blockIndex: blockIndex,
      weeks: blockWeeks ?? defaultBlockWeeks(ctx.globalLevel),
      seed: seed,
      blockReasons: <Reason>[
        if (adaptation != null)
          reason(ReasonCodes.planAdaptationApplied, <String, Object?>{
            'proposalKind': ProposalKind.volume.code,
          }),
      ],
    );
    final renamed = stateFromPlan(ctx, plan, lockedSlotIds: lockedSlots);
    return _Regenerated(ctx, planner.scorer, renamed, plan, reasons);
  }

  // -------------------------------------------------------- restructuration

  @override
  BlockProposal restructure(Catalog catalog, RestructureRequest request) {
    _check(catalog, request.profile);
    final violations = request.validate();
    if (violations.isNotEmpty) {
      throw ArgumentError(
        'Requête de restructuration invalide : ${violations.first.code}',
      );
    }
    final current = request.current;
    final before = current.pass1;
    final weeks = current.pass2.weeks.length;
    var from = request.fromWeekIndex ?? 0;
    if (from < 0) {
      from = 0;
    }
    if (from > weeks) {
      from = weeks;
    }
    final scope = request.scope;
    final day = request.dayIndex;
    if (scope == RestructureScope.session &&
        (day == null || day < 0 || day >= before.days.length)) {
      throw ArgumentError.value(day, 'dayIndex', 'jour inconnu');
    }

    // Ce que disent les raisons du moteur dynamique.
    final excluded = <String>{};
    final pains = <(BodyZone, int)>[];
    final minutes = <int, int>{};
    var scale = adaptationVolumeScale(request.adaptation);
    for (final r in request.reasons) {
      switch (r.code) {
        case ReasonCodes.adaptPainReported:
          final zone = r.params['zone'];
          final intensity = r.params['intensity'];
          if (zone is String && intensity is int) {
            for (final z in BodyZone.values) {
              if (z.code == zone) {
                pains.add((z, intensity));
              }
            }
          }
        case ReasonCodes.adaptExerciseSkipped:
        case ReasonCodes.adaptPlateau:
          final id = r.params['exerciseId'];
          if (id is String && catalog.contains(id)) {
            excluded.add(id);
          }
        case ReasonCodes.adaptTimeShort:
          final available = r.params['minutesAvailable'];
          if (available is int && day != null && available >= 5) {
            minutes[day] = available;
          }
        case ReasonCodes.adaptFatigueHigh:
        case ReasonCodes.adaptHealthLow:
          if (scale > 0.85) {
            scale = 0.85;
          }
      }
    }

    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: before.startDate,
        seed: request.seed,
        locks: request.locks,
        adaptation: request.adaptation,
        extraExcluded: excluded,
        extraPains: pains,
        forcedIds: <String>{
          for (final d in before.days)
            for (final slot in d.slots) slot.exerciseId,
        },
        minutesOverride: minutes,
        volumeScale: scale,
        params: params,
      ),
    );
    final lockedSlots = <String>{};
    final frozen = <int>{};
    for (final l in request.locks) {
      if (l.kind == LockKind.keepSlot && l.slotId != null) {
        lockedSlots.add(l.slotId!);
      } else if (l.kind == LockKind.keepDay && l.dayIndex != null) {
        frozen.add(l.dayIndex!);
      }
    }
    if (scope == RestructureScope.session) {
      for (var d = 0; d < ctx.dayCount; d++) {
        if (d != day) {
          frozen.add(d);
        }
      }
    }
    final planner = Planner(
      ctx,
      fnvMix(fnv1a32('restructure:${scope.code}'), request.seed + from),
    );
    planner.frozenDays = frozen;
    final state = stateFromPlan(ctx, before, lockedSlotIds: lockedSlots);
    final specific = <String, List<Reason>>{};
    final scopeReason = reason(
      ReasonCodes.planRestructureScope,
      <String, Object?>{'scope': scope.code},
    );

    // Exercices à remplacer : écartés, douloureux ou devenus infaisables.
    for (var d = 0; d < ctx.dayCount; d++) {
      if (frozen.contains(d)) {
        continue;
      }
      var i = 0;
      while (i < state.count[d]) {
        final e = ctx.pool[state.exercise[d][i]];
        final identity = state.uid[d][i];
        if (state.locked[identity] || (e.selectable && e.feasibleOn(d))) {
          i++;
          continue;
        }
        final slotId = state.slotIds[identity];
        final painful = e.jointPenalty > 0;
        final picked = _replaceSlot(
          ctx,
          planner,
          state,
          d,
          i,
          easierFirst: false,
        );
        specific[slotId] = <Reason>[
          scopeReason,
          reason(ReasonCodes.planAdaptationApplied, <String, Object?>{
            'proposalKind': painful
                ? ProposalKind.painSparing.code
                : ProposalKind.exerciseSwap.code,
          }),
        ];
        if (picked != null) {
          i++;
        }
      }
    }
    final reference = state.copy();
    planner.setReference(reference);
    planner.repair(state);
    planner.anneal(state, params.reviewIterations);
    planner.polish(state);
    planner.revertUnpaidChanges(state, reference);

    final scoreBefore = before.score.total;
    final after = planFromState(
      ctx,
      state,
      planner.scorer,
      blockId: before.blockId,
      blockIndex: before.blockIndex,
      weeks: before.weeks,
      seed: before.seed,
      blockReasons: <Reason>[scopeReason],
    );
    final renamed = stateFromPlan(ctx, after, lockedSlotIds: lockedSlots);
    tuneSets(ctx, planner.scorer, renamed);
    final fresh = buildPass2(ctx, planner.scorer, renamed, after);

    final weeksOut = <WeekPrescription>[];
    for (var w = 0; w < weeks; w++) {
      final old = current.pass2.weeks[w];
      final replace = scope == RestructureScope.week ? w == from : w >= from;
      if (!replace || w >= fresh.weeks.length) {
        weeksOut.add(old);
        continue;
      }
      final neu = fresh.weeks[w];
      if (scope == RestructureScope.session) {
        weeksOut.add(
          old.copyWith(
            days: <DayPrescription>[
              for (final dp in old.days)
                if (dp.dayIndex == day)
                  neu.days.firstWhere(
                    (x) => x.dayIndex == day,
                    orElse: () => dp,
                  )
                else
                  dp,
            ],
          ),
        );
      } else {
        weeksOut.add(neu.copyWith(kind: old.kind));
      }
    }
    final pass1 = scope == RestructureScope.week ? before : after;
    final diff = diffPlans(
      before,
      after,
      weekIndex: scope == RestructureScope.week ? from : null,
      reasons: (kind, slotId, fromId, toId) {
        final own = slotId == null ? null : specific[slotId];
        if (own != null) {
          return own;
        }
        return <Reason>[
          scopeReason,
          reason(ReasonCodes.planReoptimized, <String, Object?>{
            'scoreBefore': _round4(scoreBefore),
            'scoreAfter': _round4(after.score.total),
          }),
        ];
      },
    );
    return BlockProposal(
      block: ProgramBlock(
        pass1: pass1,
        pass2: current.pass2.copyWith(weeks: weeksOut),
      ),
      diff: diff,
    );
  }
}

double _round4(double v) => (v * 10000).roundToDouble() / 10000;
