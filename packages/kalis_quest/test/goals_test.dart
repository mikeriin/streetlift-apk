// Objectifs : avancement, jalons, prédiction, retard, habitude,
// suggestions, calibrage de l'intervalle de prédiction.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart' show SimRng;
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final base = profileOf(scenarioProfile);
  final engine = KalisQuest();

  Goal performance(double target, {int days = 84}) => Goal(
    id: 'g1',
    kind: GoalKind.performance,
    origin: GoalOrigin.user,
    createdOn: monday,
    exerciseId: bench,
    metric: GoalMetric.oneRmKg,
    targetValue: target,
    targetDate: monday.addDays(days),
  );

  // Une séance par semaine : 5 répétitions à 9 flammes, +2,5 kg par semaine
  // (1RM impliqué : 70 ; 72,9 ; 75,8 ; 78,8 ; … kg).
  List<SessionRecord> rising(int weeks) => <SessionRecord>[
    for (var k = 0; k < weeks; k++)
      sessionOf(
        'r$k',
        monday.addDays(7 * k),
        benchSets(3, load: 60 + 2.5 * k, reps: 5, flames: 9, target: 9),
        planned: 3,
      ),
  ];

  group('objectif de performance', () {
    final profile = base.copyWith(goals: <Goal>[performance(100)]);

    test('départ, jalons le long de la courbe prévue, atteinte', () {
      var o = run(engine, profile, const <SessionRecord>[], emptyState, monday);
      final reached = <int, CivilDate>{};
      for (var k = 0; k < 12; k++) {
        o = run(engine, profile, rising(k + 1), o.state, monday.addDays(7 * k));
        final g = o.goals.single;
        expect(g.baseline, 70);
        expect(g.target, 100);
        expect(g.milestones, hasLength(4));
        for (var i = 0; i < 4; i++) {
          final on = g.milestones[i].reachedOn;
          if (on != null) {
            reached.putIfAbsent(i, () => on);
            expect(on, reached[i]);
          }
        }
      }
      final g = o.goals.single;
      // Étapes d'égale durée le long d'une tendance amortie : parts
      // croissantes, un peu au-dessus du quart, de la moitié, des trois
      // quarts.
      final fractions = <double>[for (final m in g.milestones) m.fraction];
      expect(fractions, <double>[0.29, 0.55, 0.78, 1]);
      expect(reached[0], monday.addDays(21));
      expect(reached[1], monday.addDays(42));
      expect(reached[2], monday.addDays(63));
      expect(reached[3], monday.addDays(77));
      expect(g.achievedOn, monday.addDays(77));
      expect(g.fraction, 1);
      expect(g.prediction, isNull);
      expect(g.overdue, isNull);
      // Écart de 43 % : objectif pleinement ambitieux, 30 + 30 + 30 + 100.
      expect(xpOf(o.state, XpSource.milestone), 190);
      expect(
        o.state.xp.where((e) => e.source == XpSource.milestone),
        hasLength(4),
      );
      expect(o.validate(), isEmpty);
    });

    test('prédiction : médiane entre les bornes, méthode du journal', () {
      final o = run(
        engine,
        profile,
        rising(6),
        run(engine, profile, const <SessionRecord>[], emptyState, monday).state,
        monday.addDays(36),
      );
      final g = o.goals.single;
      final p = g.prediction!;
      expect(p.method, PredictionMethods.journal);
      expect(p.earliestOn <= p.expectedOn, isTrue);
      expect(p.expectedOn <= p.latestOn, isTrue);
      expect(p.expectedOn > monday.addDays(36), isTrue);
      expect(p.confidence, inInclusiveRange(0, 1));
      expect(g.overdue, isFalse);
      expect(g.fraction, inInclusiveRange(0.4, 0.6));
      expect(
        g.reasons!.map((r) => r.code),
        contains(ReasonCodes.questPredictionUpdated),
      );
    });

    test('objectif en retard : date ou cible ajustée proposée', () {
      final behind = base.copyWith(goals: <Goal>[performance(150)]);
      final o = run(
        engine,
        behind,
        rising(6),
        run(engine, behind, const <SessionRecord>[], emptyState, monday).state,
        monday.addDays(36),
      );
      final g = o.goals.single;
      expect(g.overdue, isTrue);
      expect(
        g.reasons!.map((r) => r.code),
        contains(ReasonCodes.questGoalLate),
      );
      final target = g.suggestedTarget!;
      expect(target, greaterThan(g.current));
      expect(target, lessThan(150));
      expect(target % 2.5, 0);
      final date = g.suggestedDate;
      if (date != null) {
        expect(date > monday.addDays(84), isTrue);
      }
      expect(o.validate(), isEmpty);
    });

    test('un objectif déjà atteint à sa création ne paie aucun jalon', () {
      final easy = base.copyWith(goals: <Goal>[performance(65)]);
      final o = run(
        engine,
        easy,
        rising(3),
        run(engine, easy, const <SessionRecord>[], emptyState, monday).state,
        monday.addDays(14),
      );
      expect(o.goals.single.fraction, 1);
      expect(xpOf(o.state, XpSource.milestone), 0);
    });

    test('plafond hebdomadaire d\'XP de jalons', () {
      final many = base.copyWith(
        goals: <Goal>[
          for (var i = 0; i < 5; i++) performance(75).copyWith(id: 'many$i'),
        ],
      );
      final o = run(
        engine,
        many,
        rising(4),
        run(engine, many, const <SessionRecord>[], emptyState, monday).state,
        monday.addDays(21),
      );
      final byWeek = <int, int>{};
      for (final e in o.state.xp) {
        if (e.source == XpSource.milestone) {
          byWeek.update(
            mondayOf(e.date.dayNumber),
            (n) => n + e.amount,
            ifAbsent: () => e.amount,
          );
        }
      }
      expect(byWeek, isNotEmpty);
      for (final amount in byWeek.values) {
        expect(
          amount,
          lessThanOrEqualTo(QuestParams.standard.milestoneWeekCapXp),
        );
      }
    });
  });

  group('objectif d\'habitude', () {
    final profile = base.copyWith(
      goals: <Goal>[
        Goal(
          id: 'h',
          kind: GoalKind.habit,
          origin: GoalOrigin.user,
          createdOn: monday,
          sessionsPerWeek: 3,
          weeks: 4,
        ),
      ],
    );

    test('séances comptées, au plus 3 par semaine', () {
      final sessions = <SessionRecord>[
        for (var w = 0; w < 4; w++)
          for (final d in <int>[0, 1, 2, 4])
            sessionOf(
              'h$w-$d',
              monday.addDays(7 * w + d),
              benchSets(4),
              planned: 4,
            ),
      ];
      final start = run(
        engine,
        profile,
        const <SessionRecord>[],
        emptyState,
        monday,
      ).state;
      final mid = run(engine, profile, sessions, start, monday.addDays(13));
      final g = mid.goals.single;
      expect(g.current, 6);
      expect(g.target, 12);
      expect(g.fraction, 0.5);
      expect(g.milestones[1].reachedOn, monday.addDays(9));
      expect(g.prediction!.method, PredictionMethods.habit);
      final end = run(engine, profile, sessions, mid.state, monday.addDays(28));
      expect(end.goals.single.current, 12);
      expect(end.goals.single.achievedOn, monday.addDays(23));
      expect(xpOf(end.state, XpSource.milestone), greaterThan(0));
    });
  });

  group('objectifs suggérés', () {
    final profile = base.copyWith(goals: const <Goal>[]);
    AdaptationSummary summary(double trend) => AdaptationSummary(
      asOf: monday,
      weeksObserved: 12,
      sessionsPlanned: 36,
      sessionsCompleted: 34,
      unlockLevel: UnlockLevel.exerciseSwap,
      confidence: 0.8,
      estimates: <ExerciseEstimate>[
        ExerciseEstimate(
          exerciseId: bench,
          unit: CapacityUnit.oneRmKg,
          capacity: 100,
          standardError: 2,
          weeklyTrend: trend,
          observations: 40,
        ),
      ],
      pains: const <PainTrend>[],
      avoidedExerciseIds: const <String>[],
      reasons: const <Reason>[],
    );

    test('la cible proposée a au moins 60 % de chances d\'être atteinte', () {
      final input = QuestInput(
        profile: profile,
        log: const TrainingLog(sessions: <SessionRecord>[]),
        adaptation: summary(0.8),
        state: emptyState,
        today: monday,
      );
      final o = engine.evaluate(catalog, input);
      final goal = o.suggestedGoals!.single;
      expect(goal.origin, GoalOrigin.suggested);
      expect(goal.exerciseId, bench);
      expect(goal.metric, GoalMetric.oneRmKg);
      expect(goal.targetValue, 105);
      expect(goal.targetDate, monday.addDays(56));
      expect(goal.validate(), isEmpty);
      final keeper = GoalKeeper(World(catalog, input, engine.params));
      const estimate = TrendEstimate(100, 2, 0.8, PredictionMethods.adapt);
      expect(
        keeper.probabilityBy(estimate, goal.targetValue!, 56),
        greaterThanOrEqualTo(0.6),
      );
      // Une marche plus haut, la probabilité passe sous 60 %.
      expect(keeper.probabilityBy(estimate, 107.5, 56), lessThan(0.6));
    });

    test('sans tendance positive, ou si l\'exercice a déjà un objectif : '
        'rien', () {
      final flat = engine.evaluate(
        catalog,
        QuestInput(
          profile: profile,
          log: const TrainingLog(sessions: <SessionRecord>[]),
          adaptation: summary(0),
          state: emptyState,
          today: monday,
        ),
      );
      expect(flat.suggestedGoals, isNull);
      final taken = engine.evaluate(
        catalog,
        QuestInput(
          profile: base.copyWith(goals: <Goal>[performance(120)]),
          log: const TrainingLog(sessions: <SessionRecord>[]),
          adaptation: summary(0.8),
          state: emptyState,
          today: monday,
        ),
      );
      expect(taken.suggestedGoals, isNull);
    });

    test('le gain proposé est borné par le niveau déclaré', () {
      final elite = engine.evaluate(
        catalog,
        QuestInput(
          profile: profile.copyWith(experience: ExperienceLevel.elite),
          log: const TrainingLog(sessions: <SessionRecord>[]),
          adaptation: summary(3),
          state: emptyState,
          today: monday,
        ),
      );
      final goals = elite.suggestedGoals;
      if (goals != null) {
        expect(goals.single.targetValue!, lessThanOrEqualTo(102));
      }
    });
  });

  group('calibrage de la prédiction', () {
    test('intervalle à 80 % sur des trajectoires à tendance amortie '
        'bruitées', () {
      final profile = base.copyWith(goals: <Goal>[performance(100)]);
      const cases = 240;
      var predicted = 0;
      var inside = 0;
      var tooEarly = 0;
      var tooLate = 0;
      var medianError = 0.0;
      for (var seed = 0; seed < cases; seed++) {
        final rng = SimRng(seed, 'calibrage');
        final start = 60 + 40 * rng.next();
        final weekly = 0.4 + 1.6 * rng.next();
        final noise = 0.006 + 0.008 * rng.next();
        final horizon = 12 + (12 * rng.next()).floor();
        double truth(int week) =>
            start + weekly * dampedGain(week.toDouble(), 0.97);
        final observed = <double>[
          for (var week = 0; week <= 40; week++)
            truth(week) * (1 + noise * rng.gauss()),
        ];
        final target = (truth(horizon) / 0.5).roundToDouble() * 0.5;
        // 1RM impliqué par 1 répétition à l'échec = la charge.
        List<SessionRecord> upTo(int weeks) => <SessionRecord>[
          for (var k = 0; k <= weeks; k++)
            sessionOf('c$k', monday.addDays(7 * k), <SetRecord>[
              setOf(
                bench,
                0,
                load: observed[k],
                reps: 1,
                flames: 10,
                target: 10,
              ),
            ], planned: 1),
        ];
        final goal = performance(target, days: 7 * horizon);
        final p = profile.copyWith(goals: <Goal>[goal]);
        final today = monday.addDays(7 * 8 + 1);
        final input = QuestInput(
          profile: p,
          log: TrainingLog(sessions: upTo(8)),
          state: emptyState,
          today: today,
        );
        final result = GoalKeeper(
          World(catalog, input, engine.params),
        ).performance(goal);
        final prediction = result.progress.prediction;
        if (result.progress.achievedOn != null || prediction == null) {
          continue;
        }
        int? actual;
        var best = 0.0;
        for (var week = 0; week <= 40; week++) {
          final value = (observed[week] * 10).roundToDouble() / 10;
          if (value > best) {
            best = value;
          }
          if (week > 8 && best >= target) {
            actual = monday.addDays(7 * week).dayNumber;
            break;
          }
        }
        if (actual == null) {
          continue;
        }
        predicted++;
        if (actual < prediction.earliestOn.dayNumber) {
          tooEarly++;
        } else if (actual > prediction.latestOn.dayNumber) {
          tooLate++;
        } else {
          inside++;
        }
        medianError += (actual - prediction.expectedOn.dayNumber).abs();
      }
      final coverage = inside / predicted;
      // Trace lue dans le journal de la CI et reportée dans VALIDATION.md.
      // ignore: avoid_print
      print(
        'calibrage : $predicted prédictions, couverture '
        '${(coverage * 100).toStringAsFixed(1)} %, trop tôt $tooEarly, trop tard '
        '$tooLate, écart absolu moyen à la médiane '
        '${(medianError / predicted).toStringAsFixed(1)} jours',
      );
      expect(predicted, greaterThan(cases ~/ 3));
      expect(coverage, inInclusiveRange(0.7, 0.92));
    });
  });
}
