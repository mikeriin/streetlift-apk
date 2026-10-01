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
  Pass2Plan createPass2(Catalog catalog, Pass2Request request) {
    return samples.basePass2();
  }

  @override
  ReviewResult review(Catalog catalog, ReviewRequest request) {
    return ReviewResult(
      plan: request.current,
      diff: const PlanDiff(changes: <PlanChange>[]),
      locks: request.request.locks,
      profileDelta: const ProfileDelta(
        knownExerciseIds: <String>[],
        unknownExerciseIds: <String>[],
        likedExerciseIds: <String>[],
        dislikedExerciseIds: <String>[],
      ),
    );
  }

  @override
  VariantSet variants(Catalog catalog, VariantsRequest request) {
    final slot = request.current.days
        .expand((d) => d.slots)
        .firstWhere((s) => s.slotId == request.slotId);
    final close = catalog.mostSimilar(slot.exerciseId, limit: 3);
    return VariantSet(
      slotId: request.slotId,
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
  SessionPlan prescribeSession(Catalog catalog, SessionRequest request) {
    final input = request.input;
    return SessionPlan(
      date: input.today,
      blockId: input.block.pass1.blockId,
      weekIndex: request.weekIndex,
      dayIndex: request.dayIndex,
      items: input
          .block
          .pass2
          .weeks[request.weekIndex]
          .days[request.dayIndex]
          .items,
      adjustments: const <SessionAdjustment>[],
      confidence: 0,
      reasons: const <Reason>[],
    );
  }

  @override
  IntraSessionAdvice adviseNextSet(Catalog catalog, AdviceRequest request) {
    final item = request.session.items.firstWhere(
      (i) => i.slotId == request.slotId,
    );
    return IntraSessionAdvice(
      exerciseId: item.exerciseId,
      action: IntraSessionAction.keep,
      slotId: request.slotId,
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
    final pass2 = engine.createPass2(
      catalog,
      Pass2Request(request: request, pass1: pass1),
    );
    final block = ProgramBlock(pass1: pass1, pass2: pass2);
    expect(block.validate(), isEmpty);
    expect(pass1.seed, 7);
    final variants = engine.variants(
      catalog,
      VariantsRequest(request: request, current: pass1, slotId: 'd0s0'),
    );
    expect(variants.validate(), isEmpty);
    expect(variants.targeted, hasLength(3));
    final review = engine.review(
      catalog,
      ReviewRequest(
        request: request,
        current: pass1,
        action: const ReviewAction(kind: ReviewKind.canDo, slotId: 'd0s0'),
      ),
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
    expect(
      engine.createPass1(catalog, request).toJson().toString(),
      pass1.toJson().toString(),
    );
  });

  test('AdaptEngine et QuestEngine : entrées et sorties valides', () {
    final block = ProgramBlock(
      pass1: samples.basePass1(),
      pass2: samples.basePass2(),
    );
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
    final sessionRequest = SessionRequest(
      input: input,
      weekIndex: 0,
      dayIndex: 0,
      healthCheck: const HealthCheck(),
    );
    expect(sessionRequest.validate(), isEmpty);
    final session = adapt.prescribeSession(catalog, sessionRequest);
    expect(session.validate(), isEmpty);
    final advice = adapt.adviseNextSet(
      catalog,
      AdviceRequest(
        input: input,
        session: session,
        done: log.sessions.first.sets,
        slotId: 'd0s0',
      ),
    );
    expect(advice.validate(), isEmpty);
    expect(advice.slotId, 'd0s0');
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
