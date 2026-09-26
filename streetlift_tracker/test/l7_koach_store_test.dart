// L7 — Koach côté store : données, persistance, migration, règles de séance
// et de bilan (KT-024, KT-025, KT-028 à KT-032, KT-034, KT-036).
//
// Stockage simulé, horloge injectée, données synthétiques (aucune donnée
// réelle). « Relance » = nouvelle instance du store sur le même stockage
// simulé : ce n'est ni une destruction Android, ni un redémarrage.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach_engine.dart' as ke;
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

const _key = 'kalis_state_v3';

/// Égalité profonde des résumés du moteur, au centième.
void _same(Object? a, Object? b, [String path = '']) {
  if (a is num && b is num) {
    expect((a - b).abs() <= 0.01 + 1e-9, isTrue, reason: '$path : $a ≠ $b');
  } else if (a is Map && b is Map) {
    expect(a.keys.toSet(), b.keys.toSet(), reason: path);
    for (final k in a.keys) {
      _same(a[k], b[k], '$path.$k');
    }
  } else if (a is List && b is List) {
    expect(a.length, b.length, reason: path);
    for (var i = 0; i < a.length; i++) {
      _same(a[i], b[i], '$path[$i]');
    }
  } else {
    expect(a, b, reason: path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var now = DateTime(2026, 7, 20, 18);
  final others = <AppStore>[];

  // Semaine 3 (départ le lundi 13/07/2026) : J1 = lundi 27/07.
  // P0-84 muscle-up lesté 4×4 RIR 3 ; P0-85 traction lestée 4×6 RIR 3
  // (repos 5 min) ; P0-86 rowing (accessoire, B25).
  const mu = 'P0-84', pull = 'P0-85', row = 'P0-86';
  final w3d1 = DateTime(2026, 7, 27, 18);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 7, 20, 18);
    app = AppStore()..storeClock = () => now;
    await app.init();
    app.settings.sound = app.settings.vibration = false;
    app.program.start = DateTime(2026, 7, 13);
    app.startOrigin = 'user';
    for (final e
        in {
          'B4': 71.5,
          'B8': 32.5,
          'B9': 45.0,
          'B10': 10.0,
          'B11': 110.0,
          'B16': 10.0,
          'B17': 30.0,
          'B25': 70.0,
        }.entries) {
      app.values[e.key] = e.value;
      app.refStatus[e.key] = 'set';
    }
  });
  tearDown(() async {
    app.debugWriteHook = null;
    await app.flush();
    app.dispose();
    for (final o in others) {
      o.dispose();
    }
    others.clear();
  });

  Future<AppStore> relaunch({bool flush = true}) async {
    if (flush) await app.flush();
    final next = AppStore()..storeClock = () => now;
    await next.init();
    others.add(next);
    return next;
  }

  Exercise ex(int w, int d, String id) =>
      app.program.week(w).day(d)!.exercises.firstWhere((e) => e.id == id);

  /// Séries validées d'un exercice : (kg, reps, difficulté), 5 min d'écart.
  void doSets(int w, int d, String id, List<(String, String, double?)> sets) {
    final e = ex(w, d, id);
    final log = app.exLog(w, d, e);
    final spec = app.logSpec(e);
    for (var i = 0; i < sets.length; i++) {
      final (kg, reps, rir) = sets[i];
      log.sets[i]
        ..kg = kg
        ..reps = reps
        ..effort = rir;
      now = now.add(const Duration(minutes: 5));
      final check = app.toggleSet(log, i, spec, exercise: e, week: w);
      expect(check.ok, isTrue, reason: '$id série ${i + 1} : ${check.message}');
    }
  }

  Future<void> finish(int w, int d) async {
    expect(await app.finishSession(w, d), ResultSave.saved);
  }

  /// Traction S3·J1 et S4·J1 plus fortes que le repère (≈ +8 %).
  Future<void> twoStrongSessions() async {
    now = w3d1;
    doSets(3, 1, pull, [
      ('11', '6', 3),
      ('11', '6', 3),
      ('11', '6', 3),
      ('11', '6', 3),
    ]);
    await finish(3, 1);
    now = DateTime(2026, 8, 3, 18);
    doSets(4, 1, 'B1-7', [
      ('8,75', '8', 3),
      ('8,75', '8', 3),
      ('8,75', '8', 3),
      ('8,75', '8', 3),
    ]);
    await finish(4, 1);
  }

  // =====================================================================
  group('KT-034 — migration, persistance, effacement', () {
    test('désactivé par défaut ; export identique à 2.5.9 tant qu’il n’a '
        'jamais servi', () async {
      expect(app.koach.enabled, isFalse);
      expect(app.koachOn, isFalse);
      expect(app.koachProgram.available, isTrue);
      now = w3d1;
      final e = ex(3, 1, pull);
      final log = app.exLog(3, 1, e);
      log.sets[0]
        ..kg = '5'
        ..reps = '6';
      // Koach désactivé : aucune difficulté exigée, aucune prescription.
      expect(
        app.toggleSet(log, 0, app.logSpec(e), exercise: e, week: 3).ok,
        isTrue,
      );
      final m = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(m.containsKey('koach'), isFalse);
      final exLog = ((m['logs'] as Map)['S3-J1'] as Map)['ex'][pull] as Map;
      expect(exLog.keys.toSet(), {
        'sets',
        'note',
        'showKg',
        'showRir',
        'showV',
      });
      expect((exLog['sets'] as List).first.keys.toSet(), {
        'kg',
        'reps',
        'rir',
        'v',
        'done',
        'completedAt',
      });
    });

    test('état 2.5.x relu : rien de réécrit, Koach désactivé', () async {
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', null), ('5', '6', null)]);
      final legacy = app.exportAll();
      await app.flush();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, legacy);
      final next = await relaunch(flush: false);
      expect(next.koach.enabled, isFalse);
      expect(next.koach.pristine, isTrue);
      expect(next.koachLoadIssues, 0);
      expect(jsonDecode(next.exportAll()), jsonDecode(legacy));
    });

    test('première activation : repère initial daté, première pesée, échelle '
        'figée', () async {
      app.settings.rpe = true;
      app.enableKoach();
      expect(app.koachOn, isTrue);
      expect(app.koach.legacyScale, 'rpe');
      final initial = app.koach.history.where((h) => h.source == 'initial');
      expect(
        initial.map((h) => h.ref).toSet(),
        app.values.keys.toSet()..remove('B4'),
      );
      expect(initial.every((h) => h.at == '2026-07-20T18:00:00'), isTrue);
      expect(app.koach.weighIns.single.date, '2026-07-20');
      expect(app.koach.weighIns.single.kg, 71.5);
      app.settings.rpe = false;
      app.disableKoach();
      app.enableKoach();
      expect(app.koach.legacyScale, 'rpe');
      expect(
        app.koach.history.where((h) => h.source == 'initial').length,
        initial.length,
      );
      final next = await relaunch();
      expect(next.koach.enabled, isTrue);
      expect(next.koach.history.length, app.koach.history.length);
      expect(next.koach.legacyScale, 'rpe');
    });

    test('sauvegarde 3.0.0 : section koach et champs de série, relue à '
        'l’identique', () async {
      app.enableKoach();
      app.setKoachQuestionnaires(true);
      now = w3d1;
      app.setKoachAnswers('S3-J1', sleep: 7.5, form: 6);
      doSets(3, 1, pull, [
        ('5', '6', 3),
        ('5', '6', 2.5),
        ('5', '6', null),
        ('5', '6', 2),
      ]);
      final log = app.exLog(3, 1, ex(3, 1, pull));
      app.toggleExcluded(log, 2);
      await finish(3, 1);
      app.setKoachPain('S3-J1', 'pull', 2);
      app.addWeighIn(DateTime(2026, 7, 26), 72);
      app.toggleKoachLock('B25');
      app.setKoachEquipment('plate', {'step': 2.5});
      final text = app.exportAll();
      final m = jsonDecode(text) as Map<String, dynamic>;
      final koach = m['koach'] as Map<String, dynamic>;
      expect(koach['v'], 1);
      expect(koach['enabled'], isTrue);
      expect(koach['questionnaires'], 'on');
      expect((koach['answers'] as Map)['S3-J1'], {
        'sleep': 7.5,
        'form': 6,
        'pain': {'pull': 2},
      });
      final sets =
          ((m['logs'] as Map)['S3-J1'] as Map)['ex'][pull]['sets'] as List;
      expect([for (final s in sets) (s as Map)['effort']], [3, 2.5, null, 2]);
      expect(
        [for (final s in sets) (s as Map).containsKey('excluded')],
        [false, false, true, false],
      );
      expect(
        ((m['logs'] as Map)['S3-J1'] as Map)['ex'][pull]['prescribed'],
        isA<String>(),
      );
      final next = await relaunch();
      final relaunched = jsonDecode(next.exportAll()) as Map<String, dynamic>;
      expect(relaunched['koach'], m['koach']);
      expect(relaunched['logs'], m['logs']);
      SharedPreferences.setMockInitialValues({});
      final other = AppStore()..storeClock = () => now;
      await other.init();
      others.add(other);
      expect(await other.importBackup(text), ImportStatus.success);
      final imported = jsonDecode(other.exportAll()) as Map<String, dynamic>;
      expect(imported['koach'], m['koach']);
      expect(imported['logs'], m['logs']);
      expect(other.koachOn, isTrue);
    });

    test('sauvegarde 2.x importée : rien de synthétisé ; export 3.0.0 au '
        'format 3', () async {
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', null)]);
      final old = app.exportAll();
      app.enableKoach();
      app.addWeighIn(now, 73);
      expect(await app.importBackup(old), ImportStatus.success);
      expect(app.koach.pristine, isTrue);
      expect(app.koachOn, isFalse);
      final m = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      expect(m['format'], 3);
      expect(m.containsKey('koach'), isFalse);
    });

    test('import : section Koach ou difficulté hors contrat refusée ; '
        'démarrage : entrée illisible ignorée, le reste chargé', () async {
      app.enableKoach();
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', 3)]);
      final good = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final badWeight = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
      ((badWeight['koach'] as Map)['weighIns'] as List).add({
        'date': '2026-07-21',
        'kg': 1000,
      });
      expect(
        app.previewImport(jsonEncode(badWeight)).status,
        ImportStatus.invalid,
      );
      final badEffort = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
      (((badEffort['logs'] as Map)['S3-J1'] as Map)['ex'][pull]['sets']
              as List)[0]['effort'] =
          7;
      expect(
        app.previewImport(jsonEncode(badEffort)).status,
        ImportStatus.invalid,
      );
      expect(app.previewImport(jsonEncode(good)).status, ImportStatus.success);
      // Document de l'application relu au démarrage : entrée illisible
      // ignorée et comptée, rien d'autre de perdu.
      await app.flush();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(badWeight));
      var next = await relaunch(flush: false);
      expect(next.koachLoadIssues, 1);
      expect(next.koach.enabled, isTrue);
      expect(next.koach.weighIns.map((w) => w.kg), [71.5]);
      await prefs.setString(_key, jsonEncode(badEffort));
      next = await relaunch(flush: false);
      expect(next.logs['S3-J1']!.ex[pull]!.sets[0].effort, isNull);
      expect(next.logs['S3-J1']!.ex[pull]!.sets[0].done, isTrue);
    });

    test('effacement des données : Koach remis à l’état neuf', () async {
      app.enableKoach();
      app.setKoachQuestionnaires(true);
      app.setKoachAnswers('S3-J1', sleep: 6.5);
      app.addWeighIn(now, 72);
      final result = await app.eraseAllData();
      expect(result.status, EraseStatus.success);
      expect(app.koach.pristine, isTrue);
      expect(app.koachOn, isFalse);
      expect(jsonDecode(app.exportAll()), isNot(contains('koach')));
    });

    test('KT-036 : réponses supprimables seules, incluses dans l’export', () {
      app.enableKoach();
      app.setKoachQuestionnaires(true);
      app.setKoachAnswers('S3-J1', sleep: 4.5, form: 3);
      app.setKoachPain('S3-J1', 'dip', 6);
      expect(
        ((jsonDecode(app.exportAll()) as Map)['koach'] as Map)['answers'],
        contains('S3-J1'),
      );
      app.clearKoachAnswers();
      expect(app.koach.answers, isEmpty);
      expect(app.koach.enabled, isTrue);
      expect(app.koach.weighIns, isNotEmpty);
    });
  });

  // =====================================================================
  group('D8, D9, D11, D13, D33, D12 — séries et saisies', () {
    test('D8 : difficulté exigée sur la première et la dernière série des '
        'mouvements principaux', () {
      app.enableKoach();
      now = w3d1;
      final e = ex(3, 1, pull);
      final log = app.exLog(3, 1, e);
      final spec = app.logSpec(e);
      for (final s in log.sets) {
        s
          ..kg = '5'
          ..reps = '6';
      }
      final refused = app.toggleSet(log, 0, spec, exercise: e, week: 3);
      expect(refused.field, SetField.effort);
      expect(refused.message, contains('difficulté'));
      expect(log.sets[0].done, isFalse);
      expect(log.sets[0].effort, isNull);
      // Mode avancé : RIR saisi dans la colonne → difficulté.
      log.sets[0].rir = '2';
      expect(app.toggleSet(log, 0, spec, exercise: e, week: 3).ok, isTrue);
      expect(log.sets[0].effort, 2);
      expect(log.prescribed, contains('4×6'));
      // Séries intermédiaires : facultative.
      expect(app.toggleSet(log, 1, spec, exercise: e, week: 3).ok, isTrue);
      expect(app.toggleSet(log, 2, spec, exercise: e, week: 3).ok, isTrue);
      expect(
        app.toggleSet(log, 3, spec, exercise: e, week: 3).field,
        SetField.effort,
      );
      // RPE : RIR = 10 − RPE.
      app.settings.rpe = true;
      log.sets[3].rir = '8,5';
      expect(app.toggleSet(log, 3, spec, exercise: e, week: 3).ok, isTrue);
      expect(log.sets[3].effort, 1.5);
      // Accessoire : jamais exigée.
      final r = ex(3, 1, row);
      final rl = app.exLog(3, 1, r);
      rl.sets[0].reps = '10';
      expect(
        app.toggleSet(rl, 0, app.logSpec(r), exercise: r, week: 3).ok,
        isTrue,
      );
      // Sans l'exercice (appel 2.x) : règle 2.x.
      final m = ex(3, 1, mu);
      final ml = app.exLog(3, 1, m);
      ml.sets[0].reps = '4';
      expect(app.toggleSet(ml, 0, app.logSpec(m)).ok, isTrue);
    });

    test('D9 : RIR/RPE hérités lus avec l’échelle figée ; non '
        'interprétables = borne', () {
      app.settings.rpe = true;
      app.enableKoach();
      expect(app.koachRir(SetEntry(rir: '8')), 2);
      expect(app.koachRir(SetEntry(rir: '7,5')), 2.5);
      expect(app.koachRir(SetEntry(rir: '2-3')), isNull);
      expect(app.koachRir(SetEntry(rir: '8', effort: 4)), 4);
      app.koach.legacyScale = 'rir';
      expect(app.koachRir(SetEntry(rir: '8')), 5);
      expect(app.koachEffortLabel(SetEntry(effort: 2)), 'Dur · encore 2');
      expect(
        app.koachEffortLabel(SetEntry(effort: 5)),
        'Facile · encore 5 ou plus',
      );
    });

    test('D11 : série écartée gardée au journal, XP inchangée, hors '
        'estimation', () async {
      app.enableKoach();
      now = w3d1;
      doSets(3, 1, pull, [
        ('5', '6', 3),
        ('5', '6', 3),
        ('7,5', '6', 1),
        ('5', '6', 3),
      ]);
      await finish(3, 1);
      final xp = app.xp;
      final log = app.exLog(3, 1, ex(3, 1, pull));
      app.toggleExcluded(log, 2);
      expect(log.sets[2].done, isTrue);
      expect(log.sets[2].excluded, isTrue);
      expect(app.xp, xp);
      final inp = app.koachInput();
      final sets =
          ((inp['sessions'] as List).single as Map)['exercises'] as List;
      final pullSets =
          (sets.firstWhere((e) => (e as Map)['id'] == pull) as Map)['sets']
              as List;
      expect((pullSets[2] as Map)['excluded'], isTrue);
      // Écartée = comme non faite pour le moteur (rangs inchangés).
      final undone = jsonDecode(jsonEncode(inp)) as Map<String, dynamic>;
      ((((undone['sessions'] as List).single as Map)['exercises'] as List)
                  .firstWhere((e) => (e as Map)['id'] == pull)
              as Map)['sets'][2]['done'] =
          false;
      _same(ke.summarize(app.koachState()), ke.summarize(ke.replay(undone)));
    });

    test(
      'D13 : repos réel < 80 % du prescrit → série hors estimation',
      () async {
        app.enableKoach();
        now = w3d1;
        final e = ex(3, 1, pull);
        final log = app.exLog(3, 1, e);
        final spec = app.logSpec(e);
        final gaps = [0, 5, 1, 5]; // minutes depuis la série précédente
        for (var i = 0; i < 4; i++) {
          now = now.add(Duration(minutes: gaps[i]));
          log.sets[i]
            ..kg = '5'
            ..reps = '6'
            ..effort = 3;
          expect(app.toggleSet(log, i, spec, exercise: e, week: 3).ok, isTrue);
        }
        await finish(3, 1);
        // Série 3 : 1 min de repos pour 5 min prescrites (< 4 min).
        expect(app.koachState().tracks['pull']!.validSets, 3);
      },
    );

    test('D33 : saisie manuelle = mesure datée, regroupée sur 30 s ; poids '
        'du corps = pesée du jour', () {
      app.enableKoach();
      final before = app.koach.history.length;
      app.setValue('B8', 3);
      now = now.add(const Duration(seconds: 5));
      app.setValue('B8', 35);
      now = now.add(const Duration(seconds: 10));
      app.setValue('B8', 35.5);
      var manual = [
        for (final h in app.koach.history)
          if (h.source == 'manual') h,
      ];
      expect(app.koach.history.length, before + 1);
      expect(manual.single.value, 35.5);
      now = now.add(const Duration(minutes: 2));
      app.setValue('B8', 36);
      manual = [
        for (final h in app.koach.history)
          if (h.source == 'manual') h,
      ];
      expect(manual.map((h) => h.value), [35.5, 36]);
      app.setValue('B4', 72.4);
      expect(app.koach.weighIns.single.kg, 72.4);
      expect(app.koach.history.any((h) => h.ref == 'B4'), isFalse);
    });

    test('D12 : pesée la plus récente = poids du corps ; rappel après 7 '
        'jours', () {
      app.enableKoach();
      expect(app.koachWeighInDue, isFalse);
      app.addWeighIn(DateTime(2026, 7, 10), 70);
      expect(app.values['B4'], 71.5); // plus ancienne : rien ne change
      app.addWeighIn(DateTime(2026, 7, 20), 73);
      expect(app.values['B4'], 73);
      expect(app.koach.weighIns.map((w) => w.date), [
        '2026-07-10',
        '2026-07-20',
      ]);
      expect(app.koachBodyweightNow, 73);
      now = DateTime(2026, 7, 27, 9);
      expect(app.koachWeighInDue, isTrue);
      app.koachWeighInSnooze();
      expect(app.koachWeighInDue, isFalse);
      app.addWeighIn(DateTime(2026, 7, 10), 1000); // hors bornes : refusée
      expect(app.koach.weighIns.first.kg, 70);
    });

    test(
      'D2 : séances perso et WOD ignorés ; cache du store = rejeu complet',
      () async {
        app.enableKoach();
        app.logs['S0-J1'] = SessionLog(
          done: true,
          finishedAt: '2026-07-21T18:00:00.000',
          ex: {
            pull: ExerciseLog(
              sets: [SetEntry(kg: '50', reps: '6', effort: 3, done: true)],
            ),
          },
        );
        await twoStrongSessions();
        final keys = [
          for (final s in app.koachInput()['sessions'] as List)
            (s as Map)['key'],
        ];
        expect(keys, ['S3-J1', 'S4-J1']);
        _same(
          ke.summarize(app.koachState()),
          ke.summarize(ke.replay(app.koachInput())),
        );
        // Pesée rétroactive : même résultat que le rejeu complet.
        app.addWeighIn(DateTime(2026, 7, 26), 75);
        _same(
          ke.summarize(app.koachState()),
          ke.summarize(ke.replay(app.koachInput())),
        );
      },
    );
  });

  // =====================================================================
  group('D24, D7, D6, D25, D26 — pendant la séance', () {
    test(
      'D24 : suggestion après la série 1, appliquée aux séries restantes',
      () {
        app.enableKoach();
        now = w3d1;
        doSets(3, 1, pull, [('5', '6', 5)]);
        final e = ex(3, 1, pull);
        final log = app.exLog(3, 1, e);
        final sug = app.koachSuggestion(3, 1, e, log)!;
        // Facile (5) pour Soutenu visé (3) : +6 % de 76,5 kg, plafond +5 kg,
        // arrondi inférieur à 1,25 kg → 8,75 kg.
        expect(sug.direction, 'up');
        expect(sug.reason, 'easy2');
        expect(sug.from, 5);
        expect(sug.kg, 8.75);
        expect(
          app.koachReason(e, log, sug),
          '+3,75 kg — série 1 à Facile, visé Soutenu',
        );
        app.applyKoachSuggestion(3, 1, e, log, sug);
        expect([for (final s in log.sets) s.kg], ['5', '8.75', '8.75', '8.75']);
        expect(log.koach, contains('appliqué'));
        expect(app.koachSuggestion(3, 1, e, log), isNull);
        expect(app.koach.decisions.last.status, 'accepted');
        // Rien d'autre n'a changé (D4).
        expect(app.values['B8'], 32.5);
      },
    );

    test('D7 : refus mémorisé, hausse non reproposée ; une baisse de sécurité '
        'reste possible', () {
      app.enableKoach();
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', 5)]);
      final e = ex(3, 1, pull);
      final log = app.exLog(3, 1, e);
      final sug = app.koachSuggestion(3, 1, e, log)!;
      app.refuseKoachSuggestion(3, 1, e, log, sug);
      expect(log.koach, contains('charge gardée'));
      expect(app.koachSuggestion(3, 1, e, log), isNull);
      app.toggleSet(log, 0, app.logSpec(e), exercise: e, week: 3);
      app.toggleSet(log, 0, app.logSpec(e), exercise: e, week: 3);
      expect(app.koachSuggestion(3, 1, e, log), isNull);
      // Série 2 ratée (4 reps pour 6) : −3 %, arrondi supérieur.
      log.sets[1]
        ..kg = '5'
        ..reps = '4';
      now = now.add(const Duration(minutes: 5));
      app.toggleSet(log, 1, app.logSpec(e), exercise: e, week: 3);
      final down = app.koachSuggestion(3, 1, e, log)!;
      expect(down.direction, 'down');
      expect(down.reason, 'missed2');
      expect(down.kg, lessThan(5));
    });

    test('D6 : verrou « Garder ma valeur » et Koach désactivé : aucune '
        'suggestion', () {
      app.enableKoach();
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', 5)]);
      final e = ex(3, 1, pull);
      final log = app.exLog(3, 1, e);
      app.toggleKoachLock('B8');
      expect(app.koachSuggestion(3, 1, e, log), isNull);
      app.toggleKoachLock('B8');
      expect(app.koachSuggestion(3, 1, e, log), isNotNull);
      app.disableKoach();
      expect(app.koachSuggestion(3, 1, e, log), isNull);
      expect(
        app.koachFatigueLevel(3, 1, app.program.week(3).day(1)!.exercises),
        0,
      );
    });

    test('D25 : jour de fatigue : séries restantes réduites, charges '
        'gardées, aucune hausse', () {
      app.enableKoach();
      app.setKoachQuestionnaires(true);
      now = w3d1;
      final day = app.program.week(3).day(1)!;
      expect(app.koachAskBefore(3, 1), isTrue);
      app.setKoachAnswers('S3-J1', sleep: 4.5, form: 7);
      final level = app.koachFatigueLevel(3, 1, day.exercises);
      expect(level, 0.3);
      doSets(3, 1, pull, [('5', '6', 5)]);
      expect(app.koachAskBefore(3, 1), isFalse);
      app.acceptKoachFatigue(3, 1, day.exercises, level);
      final e = ex(3, 1, pull);
      final log = app.exLog(3, 1, e);
      expect(log.sets.length, 3); // 4 × 0,7 = 2,8 → 3 séries
      expect(log.sets.first.done, isTrue);
      expect(app.koachSuggestion(3, 1, e, log), isNull);
      expect(app.koachFatigueLevel(3, 1, day.exercises), 0);
    });

    test('D26 : douleur > 3/10 : aucune hausse ; deux séances de suite : '
        'allègement proposé, puis levé', () async {
      app.enableKoach();
      app.setKoachQuestionnaires(true);
      now = w3d1;
      doSets(3, 1, pull, [('5', '6', 3)]);
      await finish(3, 1);
      app.setKoachPain('S3-J1', 'pull', 5);
      expect(app.koachPainBlocks('pull'), isTrue);
      now = DateTime(2026, 8, 3, 18);
      doSets(4, 1, 'B1-7', [('3,75', '8', 5)]);
      final e = ex(4, 1, 'B1-7');
      final log = app.exLog(4, 1, e);
      expect(app.koachSuggestion(4, 1, e, log), isNull);
      await finish(4, 1);
      app.setKoachPain('S4-J1', 'pull', 6);
      final pain =
          app.koachProposals('S4-J1').where((p) => p['kind'] == 'pain').single;
      expect(app.koachProposalText(pain), contains('20 %'));
      expect(app.koachProposalReason(pain), contains('professionnel de santé'));
      // S5·J1 traction 5×8 à 72 % : lest (71,5 + 32,5) × 0,72 − 71,5 =
      // 3,38 kg → 3,75 kg (grille 1,25) ; allégé de 20 % → 2,70 → 2,5 kg.
      final w5pull = ex(5, 1, 'B1-73');
      expect(app.sessionLoad(5, w5pull), 3.75);
      app.acceptKoachProposal(pain);
      expect(app.koach.painRelief.containsKey('pull'), isTrue);
      expect(app.sessionLoad(5, w5pull), 2.5);
      expect(app.loadLabel(w5pull, week: 5), '2,5\u00A0kg');
      expect(app.values['B8'], 32.5); // valeur de pilotage inchangée
      // Douleur redescendue : levée proposée.
      now = DateTime(2026, 8, 10, 18);
      doSets(5, 1, w5pull.id, [('2,5', '5', 3)]);
      await finish(5, 1);
      app.setKoachPain('S5-J1', 'pull', 2);
      final end =
          app
              .koachProposals('S5-J1')
              .where((p) => p['kind'] == 'painEnd')
              .single;
      app.acceptKoachProposal(end);
      expect(app.koach.painRelief, isEmpty);
    });
  });

  // =====================================================================
  group(
    'Bilan (D5 b), historique (KT-029), objectifs (D27), structure (D28)',
    () {
      test('bilan : valeur acceptée d’un tap, datée ; historique des séances '
          'inchangé', () async {
        app.enableKoach();
        await twoStrongSessions();
        final proposals = app.koachProposals('S4-J1');
        final p = proposals.firstWhere((p) => p['ref'] == 'B8');
        expect(p['kind'], 'value');
        expect((p['to'] as num) > (p['from'] as num), isTrue);
        final prescribed = app.logs['S3-J1']!.ex[pull]!.prescribed;
        expect(prescribed, isNotNull);
        final loads = [for (final s in app.logs['S3-J1']!.ex[pull]!.sets) s.kg];
        app.acceptKoachProposal(p);
        expect(app.values['B8'], (p['to'] as num).toDouble());
        expect(app.refStatus['B8'], 'set');
        expect(app.koach.history.last.source, 'koach');
        expect(app.koach.history.last.ref, 'B8');
        expect(
          app.koachProposals('S4-J1').any((q) => q['id'] == p['id']),
          isFalse,
        );
        // Le journal garde ce qui était prescrit et réalisé à la date.
        expect(app.logs['S3-J1']!.ex[pull]!.prescribed, prescribed);
        expect([
          for (final s in app.logs['S3-J1']!.ex[pull]!.sets) s.kg,
        ], loads);
        // Refus : daté, non reproposé.
        for (final q in app.koachProposals('S4-J1')) {
          app.refuseKoachProposal(q);
        }
        expect(app.koachProposals('S4-J1'), isEmpty);
        expect(app.koachLastSession, 'S4-J1');
      });

      test('D27 : étape = cible 12 mois au départ + 12 mois ; objectif final '
          'saisi, modifiable', () {
        app.enableKoach();
        final stage = app.koachObjective('B8', 'stage');
        expect(stage.target, 65);
        expect(stage.date, DateTime(2027, 7, 13));
        expect(app.koachObjective('B8', 'final').target, isNull);
        app.setKoachObjective('B8', 'final', 75, DateTime(2027, 12, 31));
        final fin = app.koachObjective('B8', 'final');
        expect(fin.target, 75);
        expect(fin.date, DateTime(2027, 12, 31));
        app.setKoachObjective('B8', 'stage', 50, DateTime(2027, 1, 31));
        expect(app.koachObjective('B8', 'stage').target, 50);
        app.setKoachObjective('B8', 'stage', null, null);
        expect(app.koachObjective('B8', 'stage').target, 65);
        final inp = app.koachInput();
        expect(((inp['objectives'] as Map)['B8'] as Map)['final'], {
          'target': 75.0,
          'date': '2027-12-31',
        });
      });

      test('D28 : option désactivée par défaut ; adaptation acceptée = couche '
          'datée et réversible', () {
        app.enableKoach();
        expect(app.koach.structure, isFalse);
        expect(app.koachStructureProposals(), isEmpty);
        final day = app.program.week(5).day(1)!;
        final main = ex(5, 1, 'B1-73'); // traction 5×8
        final base = app.setCount(main);
        expect(base, 5);
        app.setKoachStructure(true);
        app.acceptKoachStructure({
          'id': 'W5|sets|pull',
          'week': 5,
          'kind': 'sets',
          'movement': 'pull',
          'exercise': main.id,
          'delta': 1,
        });
        expect(app.koachSetCount(5, main), base + 1);
        expect(app.exLog(5, day.j, main).sets.length, 6);
        expect(app.koachAdaptationText(5, main), '+1 série cette semaine');
        app.setKoachStructure(false);
        expect(app.koachSetCount(5, main), base); // option coupée : programme
        app.setKoachStructure(true);
        final load = app.sessionLoad(5, main)!;
        expect(load, 3.75);
        app.acceptKoachStructure({
          'id': 'W5|deload',
          'week': 5,
          'kind': 'deload',
          'movement': 'pull',
          'sets': 0.6,
          'load': 0.10,
        });
        // Décharge anticipée : 3,38 × 0,9 = 3,04 → 2,5 kg ; 5 × 0,6 = 3 séries.
        expect(app.sessionLoad(5, main), 2.5);
        expect(app.koachSetCount(5, main), 4); // (5 + 1) × 0,6 = 3,6 → 4
        app.revertKoachAdaptation('W5|deload');
        app.revertKoachAdaptation('W5|sets|pull');
        expect(app.koachSetCount(5, main), base);
        expect(app.sessionLoad(5, main), load);
        expect(
          app.koach.adaptations.every((a) => a.status == 'reverted'),
          isTrue,
        );
      });
    },
  );
}
