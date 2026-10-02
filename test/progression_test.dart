import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/store.dart';

SessionLog session(DateTime at, {int sets = 1}) => SessionLog(
  done: true,
  finishedAt: at.toIso8601String(),
  ex: {
    'pushup': ExerciseLog(
      sets: List.generate(
        sets,
        (_) =>
            SetEntry(done: true, reps: '10', completedAt: at.toIso8601String()),
      ),
    ),
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore app;
  final now = DateTime(2026, 9, 20, 18);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore();
    await app.init();
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
  });
  Progression calculate() =>
      Progression.calculate(logs: app.logs, program: app.program, now: now);
  // G2 : seules les journées d'entraînement du programme comptent (plus de
  // séances manuelles « S0- ») ; la date vient de finishedAt.
  String dayKey(int i) => [
    for (final w in app.program.weeks)
      for (final d in w.days)
        if (d.exercises.isNotEmpty) 'S${w.n}-J${d.j}',
  ][i];

  test('les seuils de niveaux conservent exactement la courbe existante', () {
    var sum = 0;
    for (var level = 1; level <= 200; level++) {
      expect(Progression.xpAtLevel(level), sum);
      expect(Progression.needFor(level), 150 + 50 * (level - 1));
      sum += Progression.needFor(level);
    }
  });
  test('un profil vide commence au niveau 1 sans récompenses fantômes', () {
    final p = calculate();
    expect(p.totalXp, 0);
    expect(p.level, 1);
    expect(p.need, 150);
    expect(p.earnedBadges, 0);
    expect(p.rank.title, 'Recrue');
  });
  test(
    'une journée de repos conserve le barème historique mais ne donne pas de bonus sportif',
    () {
      final week = app.program.weeks.firstWhere(
        (w) => w.days.any((d) => d.exercises.isEmpty),
      );
      final day = week.days.firstWhere((d) => d.exercises.isEmpty);
      app.logs['S${week.n}-J${day.j}'] = SessionLog(
        done: true,
        finishedAt: '2026-09-14T12:00:00',
      );
      final p = calculate();
      expect(p.programXp, 100);
      expect(p.sessions, 0);
      expect(p.week.activeDays, isEmpty);
      expect(p.badgeXp, 0);
    },
  );
  test(
    'les trois missions se cumulent une seule fois et comptent des jours distincts',
    () {
      app.logs[dayKey(0)] = session(DateTime(2026, 9, 14, 12), sets: 10);
      app.logs[dayKey(1)] = session(DateTime(2026, 9, 16, 12), sets: 10);
      app.logs[dayKey(2)] = session(DateTime(2026, 9, 18, 12));
      final p = calculate();
      expect(p.week.activeDays.length, 3);
      expect(p.week.missions.length, 3);
      expect(p.week.missions.every((m) => m.complete), true);
      expect(p.weeklyXp, 175);
      expect(calculate().totalXp, p.totalXp);
      app.logs[dayKey(3)] = session(DateTime(2026, 9, 14, 18));
      expect(calculate().week.activeDays.length, 3);
      expect(calculate().weeklyXp, 175);
    },
  );
  test(
    'les bonus des semaines précédentes restent présents au changement de semaine',
    () {
      app.logs[dayKey(0)] = session(DateTime(2026, 9, 7, 12));
      app.logs[dayKey(1)] = session(DateTime(2026, 9, 10, 12));
      final p = calculate();
      expect(p.week.activeDays, isEmpty);
      expect(p.weeklyXp, 75);
      expect(p.currentStreak, 1);
      expect(p.bestStreak, 1);
    },
  );
  test('la régularité accepte les repos et donne le badge quatre semaines', () {
    var id = 0;
    for (var i = 0; i < 4; i++) {
      final monday = DateTime(2026, 8, 24 + i * 7, 12);
      app.logs[dayKey(id++)] = session(monday);
      app.logs[dayKey(id++)] = session(monday.add(const Duration(days: 3)));
    }
    final p = calculate();
    expect(p.currentStreak, 4);
    expect(p.bestStreak, 4);
    expect(p.badges.singleWhere((b) => b.badge.id == 'streak4').earned, true);
    expect(p.totalXp, 1300);
  });
  test(
    'une semaine entièrement manquée coupe la série actuelle, pas le meilleur historique',
    () {
      app.logs[dayKey(0)] = session(DateTime(2026, 8, 31, 12));
      app.logs[dayKey(1)] = session(DateTime(2026, 9, 3, 12));
      final p = calculate();
      expect(p.currentStreak, 0);
      expect(p.bestStreak, 1);
    },
  );
  test(
    'les dates futures ne donnent pas de badges ou de missions en avance',
    () {
      app.logs[dayKey(0)] = session(DateTime(2027, 1, 1));
      final p = calculate();
      expect(p.sessions, 0);
      expect(p.sets, 0);
      expect(p.weeklyXp, 0);
      expect(p.badgeXp, 0);
    },
  );
  test(
    'la suppression d’un événement retire ses bonus sans état de récompense dupliqué',
    () {
      app.logs[dayKey(0)] = session(DateTime(2026, 9, 14, 12));
      app.logs[dayKey(1)] = session(DateTime(2026, 9, 16, 12));
      expect(calculate().weeklyXp, 75);
      app.logs.remove(dayKey(1));
      expect(calculate().weeklyXp, 0);
      app.logs.clear();
      expect(calculate().totalXp, 0);
    },
  );
  test(
    'la migration conserve données, XP de base et bonus après deux imports',
    () async {
      app.logs[dayKey(0)] = session(DateTime(2026, 8, 31, 12));
      app.notifyListeners();
      final raw = app.exportAll();
      final before = app.xp;
      expect(await app.importAll(raw), true);
      expect(app.xp, before);
      expect(app.progression.programXp, 100);
      expect(await app.importAll(raw), true);
      expect(app.xp, before);
      final saved = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(saved['format'], 3);
      final reloaded = AppStore();
      await reloaded.init();
      expect(reloaded.xp, before);
      expect(reloaded.logs.keys, app.logs.keys);
      reloaded.dispose();
    },
  );
  test('le cache se met à jour après une validation et son annulation', () {
    expect(app.xp, 0);
    app.markSessionDone(8, 1, true);
    expect(app.xp, greaterThanOrEqualTo(100));
    app.markSessionDone(8, 1, false);
    expect(app.xp, 0);
  });
  test(
    'les semaines civiles restent correctes autour du passage à l’heure d’hiver',
    () {
      expect(mondayOf(DateTime(2026, 10, 25, 12)), DateTime.utc(2026, 10, 19));
      expect(mondayOf(DateTime(2026, 10, 26, 12)), DateTime.utc(2026, 10, 26));
    },
  );
}
