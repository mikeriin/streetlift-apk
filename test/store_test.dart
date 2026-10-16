import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_generator.dart';
import 'package:streetlift_tracker/wod_models.dart';

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
    'un achat WOD ne débite qu’une fois et reste acquis après rechargement',
    () async {
      final wod = app.wods.firstWhere((w) => app.wodCost(w) <= app.credits);
      final before = app.credits;
      final cost = app.wodCost(wod);
      expect((await app.purchaseWod(wod)).status, PurchaseStatus.success);
      expect((await app.purchaseWod(wod)).status, PurchaseStatus.alreadyOwned);
      await app.flush();
      final reloaded = AppStore();
      await reloaded.init();
      final owned = reloaded.wods.firstWhere((w) => w.id == wod.id);
      expect(reloaded.unlocked(owned), isTrue);
      expect(reloaded.credits, before - cost);
      expect((await reloaded.purchaseWod(owned)).owned, isTrue);
      expect(reloaded.credits, before - cost);
      await reloaded.flush();
      reloaded.dispose();
    },
  );

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

  test('le catalogue de 1 000 WODs est classé avant utilisation', () {
    expect(app.wods.length, 1000);
    expect(app.wods.map((w) => w.id).toSet().length, 1000);
    expect(
      app.wods.map((w) => w.level).toSet(),
      containsAll(List.generate(10, (i) => i + 1)),
    );
    for (final w in app.wods) {
      expect(app.wodStats(w).points, greaterThan(0), reason: w.name);
      expect(app.wodStats(w).minutes, greaterThan(0), reason: w.name);
    }
  });

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
    bad['unlocked'] = {'seed1': -1};
    expect(await app.importAll(jsonEncode(bad)), false);
    expect(app.exportAll(), before);
    expect(prefs.getString('kalis_state_v3'), disk);
  });

  test(
    'la sauvegarde compacte conserve les modifications, scores et crédits',
    () async {
      final wod = app.wods.firstWhere((w) => app.wodCost(w) <= app.credits);
      expect((await app.purchaseWod(wod)).owned, true);
      wod.lines = ['10 push-ups'];
      app.upsertWod(wod);
      app.addWodResult(
        wod,
        WodResult(at: '2026-09-13T10:00:00', score: '2:00', seconds: 120),
      );
      app.addUserExercise('Mon exercice', 'dos', 'barre');
      final backup = app.exportCompact();
      expect(backup.length, lessThan(10000));
      expect(await app.importAll(backup), true);
      await app.flush();
      final reloaded = AppStore();
      await reloaded.init();
      expect(reloaded.wods.firstWhere((w) => w.id == wod.id).lines, [
        '10 push-ups',
      ]);
      expect(
        reloaded.wods.firstWhere((w) => w.id == wod.id).results.single.seconds,
        120,
      );
      expect(reloaded.unlockedWods, app.unlockedWods);
      expect(reloaded.allExercises.last['n'], 'Mon exercice');
      reloaded.dispose();
    },
  );

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
      'wods': app.wods.map((w) => w.toJson()).toList(),
    };
    expect(await app.importAll(jsonEncode(old)), true);
    expect(app.values['B4'], 79);
    expect(app.isDone(8, 1), true);
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
    expect(app.unlockedWods['seed1'], 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kalis_state_v3'), isNotNull);
    expect(prefs.getString('logs_v1'), isNotNull);
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

  test(
    'une séance perso répétée conserve les deux occurrences et leurs XP',
    () {
      final session = CustomSession(
        id: app.newSessionId(),
        name: 'Tractions',
        items: [CustomExercise(name: 'Tractions')],
      );
      app.upsertSession(session);
      final day = session.toWeekPlan().days.single;
      final log = app.exLog(0, day.j, day.exercises.single);
      log.sets.first
        ..done = true
        ..reps = '8'
        ..completedAt = '2026-09-13T08:00:00';
      app.markSessionDone(0, day.j, true, title: session.name);
      expect(app.progression.customXp, 60);
      app.restartCustomSession(session);
      expect(app.isDone(0, day.j), false);
      expect(app.logs.values.single.ex.values.single.sets.first.reps, '8');
      app.markSessionDone(0, day.j, true, title: session.name);
      expect(app.progression.customXp, 120);
      expect(app.logs.values.where((s) => s.done).length, 2);
      expect(app.completedCount, 0);
    },
  );

  test(
    'l’avancement du programme exclut les séances perso et les clés hors programme',
    () {
      app.markSessionDone(8, 1, true);
      app.markSessionDone(0, 123, true);
      app.markSessionDone(100, 1, true);
      expect(app.completedCount, 1);
    },
  );

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

  test('les nouveaux identifiants sont uniques sans délai entre créations', () {
    expect(
      List.generate(100, (_) => CustomExercise(name: 'x').uid).toSet().length,
      100,
    );
    final sessions = List.generate(100, (_) {
      final s = CustomSession(id: app.newSessionId(), name: 'x');
      app.customSessions.add(s);
      return s.id;
    });
    expect(sessions.toSet().length, 100);
  });

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

  test('le micro-repos personnalisé est distinct du repos entre séries', () {
    final e = CustomExercise(
      name: 'Pompes',
      mode: 'myo',
      rest: 90,
      p: {'intra': 15},
    ).toExercise(0);
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

  test(
    'modifier une ligne de matériel invalide le cache à longueur identique',
    () {
      final w = Wod(id: 'seed1', name: 'Test', lines: ['10 push-ups']);
      expect(equipmentOf(w), {'pdc'});
      w.lines = ['10 pull-ups'];
      expect(equipmentOf(w), contains('barre'));
    },
  );

  test('les déciles ne dépendent pas des suppressions personnelles', () {
    final level = app.wods[300].level;
    final id = app.wods[300].id;
    app.wods.removeRange(0, 200);
    app.rankCatalog();
    expect(app.wods.firstWhere((w) => w.id == id).level, level);
  });

  test('le parseur ignore les numéros de minute', () {
    final a = Wod(
      id: 'testa',
      name: 'A',
      type: 'emom',
      rounds: 10,
      lines: ['min 1, 4, 7… : 10 push-ups'],
    );
    final b = Wod(
      id: 'testb',
      name: 'B',
      type: 'emom',
      rounds: 10,
      lines: ['10 push-ups'],
    );
    expect(app.wodStats(a).points, app.wodStats(b).points);
  });

  test('les décimales, blocs multipliés et abréviations MU sont reconnus', () {
    final a = Wod(id: 'a', name: 'A', lines: ['1 muscle-up 2,5 kg']);
    final b = Wod(id: 'b', name: 'B', lines: ['1 MU 2.5 kg']);
    expect(app.wodStats(a).points, app.wodStats(b).points);
    final c = Wod(
      id: 'c',
      name: 'C',
      lines: ['3 × (10 push-ups + 20 air squats)'],
    );
    final d = Wod(id: 'd', name: 'D', lines: ['30 push-ups + 60 air squats']);
    expect(app.wodStats(c).points, app.wodStats(d).points);
  });

  test('import refuse les versions futures et chronos invalides', () async {
    final data = jsonDecode(app.exportAll());
    data['format'] = 999;
    expect(await app.importAll(jsonEncode(data)), false);
    data['format'] = 3;
    data['catalog']['user'] = [
      Wod(
        id: 'wtest',
        name: 'Invalide',
        type: 'emom',
        rounds: 10,
        interval: 0,
      ).toJson(),
    ];
    expect(await app.importAll(jsonEncode(data)), false);
  });
}
