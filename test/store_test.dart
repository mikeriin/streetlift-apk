import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/training_estimate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore app;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore();
    await app.init();
    app.settings.sound = app.settings.vibration = false;
  });
  tearDown(() async {
    await app.flush();
    app.dispose();
  });

  test(
    'nouvelle installation sombre, préférences de thème existantes conservées',
    () {
      expect(AppSettings().theme, 'dark');
      expect(AppSettings.fromJson({}).theme, 'dark');
      for (final theme in ['dark', 'light', 'system']) {
        expect(AppSettings.fromJson({'theme': theme}).theme, theme);
      }
    },
  );

  test('les données du programme et chaque prescription sont exploitables', () {
    var count = 0;
    for (final week in app.program.weeks) {
      for (final day in week.days) {
        for (final ex in day.exercises) {
          count++;
          expect(app.setCount(ex), greaterThan(0));
          final load = app.loadFor(ex);
          if (load != null) expect(load.isFinite, isTrue);
          expect(
            app.plannedReps(ex, app.logSpec(ex), app.setCount(ex)).length,
            app.setCount(ex),
          );
        }
      }
    }
    // LC1 (KT-037) : 1 954 − 202 lignes retirées + 66 nouvelles (S12-S19).
    // LC1b : S11·J6 au format du Bloc 2, 1 818 − 7 + 1.
    expect(count, 1812);
  });

  test('les semaines suivent les jours civils aux changements d’heure', () {
    // L4 : calendrier d'une installation existante (départ 13/07/2026).
    app.program.start = DateTime(2026, 7, 13);
    for (var w = 1; w <= 40; w++) {
      expect(app.program.weekFor(app.program.dateFor(w, 1)), w);
      expect(app.program.weekFor(app.program.dateFor(w, 7)), w);
    }
    expect(app.program.weekFor(DateTime(2026, 8, 31)), 8);
    expect(app.program.containsDate(DateTime(2026, 7, 12)), false);
    expect(app.program.containsDate(app.program.dateFor(41, 1)), false);
  });

  test('un import invalide tardif ne modifie aucune donnée', () async {
    app.markSessionDone(8, 1, true);
    await app.flush();
    final before = app.exportAll();
    final prefs = await SharedPreferences.getInstance();
    final disk = prefs.getString('kalis_state_v3');
    final bad = jsonDecode(before) as Map<String, dynamic>;
    bad['pilotage']['B4'] = 81;
    bad['logs'] = {};
    bad['settings']['theme'] = 'violet';
    expect(await app.importAll(jsonEncode(bad)), false);
    expect(app.exportAll(), before);
    expect(prefs.getString('kalis_state_v3'), disk);
  });

  test('la sauvegarde compacte conserve les modifications', () async {
    app.setValue('B4', 80);
    app.markSessionDone(8, 1, true);
    app.addUserExercise('Mon exercice', 'dos', 'barre');
    final backup = app.exportCompact();
    expect(backup.length, lessThan(10000));
    expect(await app.importAll(backup), true);
    await app.flush();
    final reloaded = AppStore();
    await reloaded.init();
    expect(reloaded.values['B4'], 80);
    expect(reloaded.isDone(8, 1), isTrue);
    expect(reloaded.allExercises.last['n'], 'Mon exercice');
    reloaded.dispose();
  });

  test('les anciens exports v2 restent importables', () async {
    final old = {
      'kalisTrack': 1,
      'format': 2,
      'pilotage': {'B4': 79},
      'logs': {
        'S8-J1': SessionLog(
          done: true,
          finishedAt: '2026-09-01T10:00:00',
        ).toJson(),
      },
      'settings': AppSettings().toJson(),
      // G2 : liste des WOD du format 2, ignorée à l'import.
      'wods': [
        {
          'id': 'seed1',
          'name': 'Fran',
          'type': 'fortime',
          'lines': ['21-15-9 thrusters'],
        },
      ],
    };
    expect(await app.importAll(jsonEncode(old)), true);
    expect(app.values['B4'], 79);
    expect(app.isDone(8, 1), true);
    expect(jsonDecode(app.exportAll()), isNot(contains('wods')));
  });

  test('migration des préférences v33 vers la nouvelle sauvegarde', () async {
    await app.flush();
    app.dispose();
    SharedPreferences.setMockInitialValues({
      'pilotage_v1': jsonEncode({'B4': 82}),
      'logs_v1': jsonEncode({
        'S9-J1': SessionLog(done: true, title: 'Ancienne séance').toJson(),
      }),
      'unlocked_wods_v1': jsonEncode({'seed1': 1}),
      'credits_v': 2,
    });
    app = AppStore();
    await app.init();
    expect(app.values['B4'], 82);
    expect(app.isDone(9, 1), true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kalis_state_v3'), isNotNull);
    expect(prefs.getString('logs_v1'), isNotNull);
    // G2 : anciennes clés des WOD ignorées, laissées intactes.
    expect(prefs.getString('unlocked_wods_v1'), isNotNull);
  });

  test(
    'import : caches, thème et champs de Pilotage sont renouvelés',
    () async {
      app.allExercises;
      final before = app.pilotageEpoch;
      final data = jsonDecode(app.exportAll());
      data['userExercises'] = [
        {'n': 'Nouveau', 'g': 'dos', 'eq': 'barre'},
      ];
      data['settings']['theme'] = 'light';
      expect(await app.importAll(jsonEncode(data)), true);
      expect(app.allExercises.last['n'], 'Nouveau');
      expect(app.themeMode.value, 'light');
      expect(app.pilotageEpoch, greaterThan(before));
    },
  );

  test('l’avancement du programme exclut les clés hors programme', () {
    app.markSessionDone(8, 1, true);
    app.markSessionDone(100, 1, true);
    expect(app.completedCount, 1);
  });

  test(
    'les muscles suivent la date réelle, même dans une autre semaine du programme',
    () {
      final ex = app.program.week(1).days.first.exercises.first;
      final log = app.exLog(1, 1, ex);
      log.sets.first
        ..done = true
        ..completedAt = '2026-09-09T10:00:00';
      expect(
        app.weeklyMuscles(DateTime(2026, 9, 13)).values.any((v) => v > 0),
        true,
      );
      log.sets.first.completedAt = '2026-09-14T10:00:00';
      expect(
        app.weeklyMuscles(DateTime(2026, 9, 13)).values.every((v) => v == 0),
        true,
      );
    },
  );

  test('les montées en singles ne sont pas des myo-reps', () {
    final e = Exercise.manual(
      id: 'test',
      name: 'Dips',
      setsText: 'Montée en singles puis 3 tentatives',
    );
    expect(app.logSpec(e).myo, false);
    expect(app.setCount(e), 6);
    expect(app.plannedReps(e, app.logSpec(e), 6), List.filled(6, 1));
  });

  test('le micro-repos des myo-reps est distinct du repos entre séries', () {
    final e = Exercise.manual(
      id: 'test',
      name: 'Pompes',
      setsText: '1×12 puis 4×(4) · 15 s intra',
      rest: '90 s',
      restSec: 90,
      forcedSets: 5,
    );
    final spec = app.logSpec(e);
    expect(spec.intra, 15);
    expect(app.restAfterSet(e, spec, 1, 5), 15);
    // Dernière série : le repos complet de l'exercice, pas le micro-repos.
    expect(app.restAfterSet(e, spec, 4, 5), 90);
  });

  test('Pilotage refuse les valeurs non finies ou négatives', () {
    final before = app.values['B4'];
    for (final v in [double.nan, double.infinity, -1.0, 0.0]) {
      app.setValue('B4', v);
    }
    expect(app.values['B4'], before);
  });

  test('le parseur ignore les numéros de minute', () {
    final a = TrainingEstimator.parseLine('min 1, 4, 7… : 10 push-ups');
    final b = TrainingEstimator.parseLine('10 push-ups');
    expect(a.volume('rep').low, b.volume('rep').low);
    expect(a.volume('rep').low, 10);
    expect(a.work.midpoint, closeTo(b.work.midpoint, 1e-9));
  });

  test('les décimales, blocs multipliés et abréviations MU sont reconnus', () {
    final a = TrainingEstimator.parseLine('1 muscle-up 2,5 kg');
    final b = TrainingEstimator.parseLine('1 MU 2.5 kg');
    expect(a.tonnage.low, closeTo(b.tonnage.low, 1e-9));
    expect(a.tonnage.low, closeTo(2.5, 1e-9));
    expect(a.work.midpoint, closeTo(b.work.midpoint, 1e-9));
    final c = TrainingEstimator.parseLine('3 × (10 push-ups + 20 air squats)');
    final d = TrainingEstimator.parseLine('30 push-ups + 60 air squats');
    expect(c.volume('rep').low, closeTo(d.volume('rep').low, 1e-9));
    expect(c.volume('rep').low, closeTo(90, 1e-9));
    expect(c.work.midpoint, closeTo(d.work.midpoint, 1e-9));
  });

  test('import refuse les versions futures', () async {
    final data = jsonDecode(app.exportAll());
    data['format'] = 999;
    expect(await app.importAll(jsonEncode(data)), false);
  });
}
