// Les interfaces des moteurs sont utilisables telles quelles : une
// réalisation minimale compile et respecte les types d'échange.
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'samples.dart' as samples;
import 'support.dart';

final class _FakePlan implements PlanEngine {
  @override
  String get engineVersion => '0.0.0-test';

  @override
  Pass1Plan createPass1(Catalog catalog, PlanRequest request) {
    return samples.basePass1().copyWith(
          seed: request.seed,
          startDate: request.startDate,
        );
  }

  @override
  Pass2Plan createPass2(Catalog catalog, PlanRequest request, Pass1Plan pass1) {
    return samples.basePass2();
  }

  @override
  ReviewResult review(
    Catalog catalog,
    PlanRequest request,
    Pass1Plan current,
    ReviewAction action,
  ) {
    return ReviewResult(
      plan: current,
      diff: const PlanDiff(changes: <PlanChange>[]),
      locks: request.locks,
      profileDelta: const ProfileDelta(
        knownExerciseIds: <String>[],
        unknownExerciseIds: <String>[],
        likedExerciseIds: <String>[],
        dislikedExerciseIds: <String>[],
      ),
    );
  }

  @override
  VariantSet variants(
    Catalog catalog,
    PlanRequest request,
    Pass1Plan current,
    String slotId,
  ) {
    final slot = current.days
        .expand((d) => d.slots)
        .firstWhere((s) => s.slotId == slotId);
    final close = catalog.mostSimilar(slot.exerciseId, limit: 3);
    return VariantSet(
      slotId: slotId,
      targeted: <Variant>[
        for (final e in close)
          Variant(
            exerciseId: e.id,
            kind: VariantKind.equivalent,
            similarity: catalog.similarity(slot.exerciseId, e.id),
            reasons: <Reason>[
              Reason(
                code: ReasonCodes.planVariantEquivalent,
                params: <String, Object?>{
                  'similarity': catalog.similarity(slot.exerciseId, e.id),
                },
              ),
            ],
          ),
      ],
      all: const <Variant>[],
    );
  }

  @override
  BlockProposal nextBlock(Catalog catalog, NextBlockRequest request) {
    return BlockProposal(
      block: request.previous,
      diff: const PlanDiff(changes: <PlanChange>[]),
    );
  }

  @override
  BlockProposal restructure(Catalog catalog, RestructureRequest request) {
    return BlockProposal(
      block: request.current,
      diff: const PlanDiff(changes: <PlanChange>[]),
    );
  }
}

final class _FakeAdapt implements AdaptEngine {
  @override
  String get engineVersion => '0.0.0-test';

  @override
  SessionPlan prescribeSession(
    Catalog catalog,
    AdaptInput input, {
    required int weekIndex,
    required int dayIndex,
    HealthCheck? healthCheck,
  }) {
    return SessionPlan(
      date: input.today,
      blockId: input.block.pass1.blockId,
      weekIndex: weekIndex,
      dayIndex: dayIndex,
      items: input.block.pass2.weeks[weekIndex].days[dayIndex].items,
      adjustments: const <SessionAdjustment>[],
      confidence: 0,
      reasons: const <Reason>[],
    );
  }

  @override
  IntraSessionAdvice adviseNextSet(
    Catalog catalog,
    AdaptInput input,
    SessionPlan session,
    List<SetRecord> done,
  ) {
    return IntraSessionAdvice(
      exerciseId: session.items.first.exerciseId,
      action: IntraSessionAction.keep,
      confidence: 0,
      reasons: const <Reason>[],
    );
  }

  @override
  AdaptReview review(Catalog catalog, AdaptInput input) {
    return AdaptReview(
      summary: AdaptationSummary(
        asOf: input.today,
        weeksObserved: 0,
        sessionsPlanned: 0,
        sessionsCompleted: input.log.countedSessions.length,
        unlockLevel: UnlockLevel.loadsReps,
        confidence: 0,
        estimates: const <ExerciseEstimate>[],
        pains: const <PainTrend>[],
        avoidedExerciseIds: const <String>[],
        reasons: const <Reason>[],
      ),
      proposals: const <Proposal>[],
      state: const <String, Object?>{},
      log: const <EngineLogEntry>[],
    );
  }
}

final class _FakeQuest implements QuestEngine {
  @override
  String get engineVersion => '0.0.0-test';

  @override
  QuestOutcome evaluate(Catalog catalog, QuestInput input) {
    return QuestOutcome(
      state: input.state.copyWith(lastEvaluatedOn: input.today),
      level: const LevelState(
        level: 1,
        prestige: 0,
        totalXp: 0,
        xpIntoLevel: 0,
        xpForNextLevel: 100,
      ),
      attributes: <AttributeScore>[
        for (final a in AthleteAttribute.values)
          AttributeScore(attribute: a, value: 0),
      ],
      ranks: const <MovementRank>[],
      goals: const <GoalProgress>[],
      events: const <DelightEvent>[],
      kreditBalance: 0,
    );
  }
}

void main() {
  final catalog = loadCatalog();
  final profile = samples.baseProfile();
  final today = CivilDate(2026, 10, 5);

  test('PlanEngine : requête, passes, variantes, bloc suivant', () {
    final PlanEngine engine = _FakePlan();
    final request = PlanRequest(
      profile: profile,
      seed: 7,
      startDate: today,
      locks: const <PlanLock>[],
    );
    expect(request.validate(), isEmpty);
    final pass1 = engine.createPass1(catalog, request);
    final pass2 = engine.createPass2(catalog, request, pass1);
    final block = ProgramBlock(pass1: pass1, pass2: pass2);
    expect(block.validate(), isEmpty);
    expect(pass1.seed, 7);
    final variants = engine.variants(catalog, request, pass1, 'd0s0');
    expect(variants.validate(), isEmpty);
    expect(variants.targeted, hasLength(3));
    final review = engine.review(
      catalog,
      request,
      pass1,
      const ReviewAction(kind: ReviewKind.canDo, slotId: 'd0s0'),
    );
    expect(review.validate(), isEmpty);
    final next = engine.nextBlock(
      catalog,
      NextBlockRequest(
        profile: profile,
        seed: 8,
        startDate: today.addDays(28),
        previous: block,
        adaptation: _FakeAdapt()
            .review(
              catalog,
              AdaptInput(
                profile: profile,
                block: block,
                log: const TrainingLog(sessions: <SessionRecord>[]),
                today: today,
              ),
            )
            .summary,
        locks: const <PlanLock>[],
      ),
    );
    expect(next.validate(), isEmpty);
    // Même requête, même résultat sérialisé.
    expect(engine.createPass1(catalog, request).toJson().toString(),
        pass1.toJson().toString());
  });

  test('AdaptEngine et QuestEngine : entrées et sorties valides', () {
    final block =
        ProgramBlock(pass1: samples.basePass1(), pass2: samples.basePass2());
    final log = TrainingLog(
      sessions: <SessionRecord>[samples.session('a', '2026-10-05')],
    );
    final input = AdaptInput(
      profile: profile,
      block: block,
      log: log,
      today: today,
    );
    expect(input.validate(), isEmpty);
    final AdaptEngine adapt = _FakeAdapt();
    final session = adapt.prescribeSession(
      catalog,
      input,
      weekIndex: 0,
      dayIndex: 0,
      healthCheck: const HealthCheck(pains: <PainReport>[]),
    );
    expect(session.validate(), isEmpty);
    expect(
      adapt.adviseNextSet(catalog, input, session, log.sessions.first.sets)
          .validate(),
      isEmpty,
    );
    final review = adapt.review(catalog, input);
    expect(review.validate(), isEmpty);
    expect(review.summary.sessionsCompleted, 1);

    final QuestEngine quest = _FakeQuest();
    final outcome = quest.evaluate(
      catalog,
      QuestInput(
        profile: profile,
        log: log,
        block: block,
        adaptation: review.summary,
        state: const QuestState(
          xp: <XpEntry>[],
          kredits: <KreditEntry>[],
          quests: <Quest>[],
          data: <String, Object?>{},
        ),
        today: today,
      ),
    );
    expect(outcome.validate(), isEmpty);
    expect(outcome.state.lastEvaluatedOn, today);
    expect(outcome.attributes, hasLength(6));
  });
}
