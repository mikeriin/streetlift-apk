import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/search.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('courbe par morceaux : bornes et interpolation', () {
    const points = <(num, int)>[(1.0, 10), (2.0, 50), (3.0, 100)];
    expect(curveScore(0.5, points), 10);
    expect(curveScore(1.5, points), 30);
    expect(curveScore(2.5, points), 75);
    expect(curveScore(9, points), 100);
  });

  test(
    'records : 1RM estimé lesté et reps au poids de corps, séance exclue',
    () {
      final logs = <String, SessionLog>{
        'S1-J1': SessionLog(
          done: true,
          finishedAt: '2026-09-01T10:00:00',
          exerciseNames: {'a': 'Dips lestés', 'b': 'Pompes'},
          ex: {
            'a': ExerciseLog(sets: [SetEntry(kg: '20', reps: '5', done: true)]),
            'b': ExerciseLog(sets: [SetEntry(reps: '30', done: true)]),
          },
        ),
        'S2-J1': SessionLog(
          done: true,
          finishedAt: '2026-09-08T10:00:00',
          exerciseNames: {'a': 'Dips lestés'},
          ex: {
            'a': ExerciseLog(sets: [SetEntry(kg: '40', reps: '3', done: true)]),
          },
        ),
      };
      final bests = exerciseBests(logs, excludeKey: 'S2-J1');
      expect(
        bests[normalizeText('Dips lestés')]!.bestE1rm,
        closeTo(20 * (1 + 5 / 30), 1e-9),
      );
      expect(recordFor(bests, 'Dips lestés', '40', '3'), isNotNull);
      expect(recordFor(bests, 'Dips lestés', '20', '5'), isNull);
      expect(recordFor(bests, 'Pompes', '', '31')!.weighted, isFalse);
      expect(recordFor(bests, 'Pompes', '', '30'), isNull);
      expect(recordFor(bests, 'Inconnu', '10', '10'), isNull);
      final all = exerciseBests(logs);
      expect(all[normalizeText('Dips lestés')]!.bestKg, 40);
    },
  );

  test(
    'série avec boucliers : gagnés toutes les 3 semaines, consommés sur un trou',
    () {
      final now = DateTime(2026, 9, 22, 12);
      final thisMonday = mondayOf(now);
      final weeks = <DateTime, TrainingWeek>{};
      void active(int weeksAgo, int days) {
        final monday = thisMonday.subtract(Duration(days: 7 * weeksAgo));
        final w = weeks.putIfAbsent(monday, () => TrainingWeek(monday));
        for (var d = 0; d < days; d++) {
          w.activeDays.add(monday.add(Duration(days: d)));
        }
      }

      // 3 semaines validées (bouclier gagné), 1 semaine manquée (bouclier
      // consommé), 1 validée, semaine en cours vide.
      active(5, 2);
      active(4, 3);
      active(3, 2);
      active(1, 2);
      final s = StreakInfo.compute(weeks, now);
      expect(s.weeks, 4);
      expect(s.shields, 0);
      expect(s.shieldedWeeks.length, 1);
      expect(s.currentValidated, isFalse);
      // Sans bouclier disponible, le trou remet la série à zéro.
      final short = <DateTime, TrainingWeek>{};
      for (final e in weeks.entries) {
        if (e.key.isAfter(thisMonday.subtract(const Duration(days: 22)))) {
          short[e.key] = e.value;
        }
      }
      expect(StreakInfo.compute(short, now).weeks, 1);
      expect(StreakInfo.compute({}, now).weeks, 0);
    },
  );

  test('rareté des badges par bonus', () {
    final rarities = progressionBadges.map(rarityOf).toSet();
    expect(rarities, BadgeRarity.values.toSet());
    expect(rarityOf(progressionBadges.first), BadgeRarity.commun);
    expect(rarityOf(progressionBadges.last), BadgeRarity.legendaire);
  });

  group('avec le programme', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() => app.dispose());

    test('objectif hebdo adaptatif : entre 2 et les journées du programme', () {
      final p = Progression.calculate(
        logs: {},
        catalog: [],
        program: app.program,
        now: DateTime(2026, 9, 22, 12),
      );
      final auto = WeeklyGoal.compute(p, 5, 0);
      expect(auto.target, 2);
      expect(auto.manual, isFalse);
      expect(WeeklyGoal.compute(p, 5, 4).target, 4);
      expect(WeeklyGoal.compute(p, 5, 4).manual, isTrue);
      expect(sessionGoalFraction({}), 0.9);
      expect(app.game.weekly.target, inInclusiveRange(2, 7));
    });

    test(
      'campagne : 6 chapitres, 4 boss, 4 saisons, crédits dérivés à zéro',
      () {
        final g = app.game;
        expect(g.chapters.map((c) => c.key), [
          'P0',
          'B1',
          'B2',
          'B3',
          'B4',
          'B5',
        ]);
        expect(g.chapters.first.name, startsWith('Prologue'));
        expect(g.bosses.length, 4);
        expect(g.bosses.map((b) => b.tests.length), [8, 4, 4, 8]);
        expect(g.seasons.length, 4);
        expect(g.seasons.first.firstWeek, 1);
        expect(g.seasons.last.lastWeek, 40);
        expect(g.bonusCredits, 0);
        expect(g.titles.where((t) => t.earned), isEmpty);
        expect(app.credits, Progression.creditsForLevel(app.level));
        for (final a in g.sheet.attributes) {
          expect(a.score, inInclusiveRange(0, 100));
          expect(a.level, inInclusiveRange(1, 10));
        }
        expect(GameState.prestigeOf(59), 0);
        expect(GameState.prestigeOf(60), 1);
        expect(GameState.prestigeOf(75), 2);
      },
    );

    test('un boss vaincu et un chapitre bouclé donnent titres et crédits', () {
      final boss = app.game.bosses.first;
      for (final (week, day) in boss.tests) {
        app.sessionLog(week, day)
          ..done = true
          ..finishedAt = '2026-07-20T10:00:00';
      }
      final chapter = app.game.chapters[1];
      for (var n = chapter.firstWeek; n <= chapter.lastWeek; n++) {
        for (final d in app.program.week(n).days) {
          if (d.exercises.isEmpty) continue;
          app.sessionLog(n, d.j)
            ..done = true
            ..finishedAt = '2026-08-20T10:00:00';
        }
      }
      app.notifyListeners();
      final g = app.game;
      expect(g.bosses.first.defeated, isTrue);
      expect(g.chapters[1].complete, isTrue);
      // +3 par chapitre, +5 par boss, +1 par semaine à trois entraînements.
      final fullWeeks =
          app.progression.weeks.values
              .where((w) => w.sessions + w.wods >= 3)
              .length;
      expect(fullWeeks, greaterThanOrEqualTo(1));
      expect(g.fullWeeks, fullWeeks);
      expect(g.chapterCredits, GameState.creditsPerChapter);
      expect(g.bossCredits, GameState.creditsPerBoss);
      expect(
        g.bonusCredits,
        GameState.creditsPerChapter + GameState.creditsPerBoss + fullWeeks,
      );
      expect(
        app.credits,
        Progression.creditsForLevel(app.level) + g.bonusCredits,
      );
      final earned = g.earnedTitles.map((t) => t.name).toList();
      expect(earned, containsAll(['Testé au feu', 'Forgeron']));
      expect(app.displayTitle, app.progression.rank.title);
      app.settings.title = 'Forgeron';
      expect(app.displayTitle, 'Forgeron');
      app.settings.title = 'Inconnu';
      expect(app.displayTitle, app.progression.rank.title);
    });

    test('bilan de récompenses : XP, badge, défi et niveau', () {
      final before = app.progression;
      app.sessionLog(8, 1)
        ..done = true
        ..finishedAt =
            DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      app.notifyListeners();
      final after = app.progression;
      final r = RewardSummary.build(
        before: before,
        after: after,
        heading: 'Séance validée',
        title: 'S8 · J1',
        creditsBefore: 1,
        creditsAfter: 1,
        baseXp: 100,
        goalReached: true,
      );
      expect(r.xpGained, after.totalXp - before.totalXp);
      expect(r.lines.first.kind, 'base');
      expect(
        r.lines.any(
          (l) => l.kind == 'badge' && l.label.contains('Premier pas'),
        ),
        isTrue,
      );
      expect(r.lines.any((l) => l.kind == 'goal'), isTrue);
      expect(r.levelBefore, 1);
      expect(r.levelAfter, after.level);
    });

    test('une séance terminée laisse un bilan à consommer une seule fois', () {
      expect(app.consumeReward(), isNull);
      app.markSessionDone(8, 1, true, title: 'S8 · J1');
      final reward = app.consumeReward();
      expect(reward, isNotNull);
      expect(reward!.xpGained, greaterThanOrEqualTo(100));
      expect(reward.heading, 'Séance validée');
      expect(app.consumeReward(), isNull);
      // Un jour de repos ou une semaine hors programme ne produit rien.
      app.markSessionDone(100, 1, true);
      expect(app.consumeReward(), isNull);
    });
  });
}
