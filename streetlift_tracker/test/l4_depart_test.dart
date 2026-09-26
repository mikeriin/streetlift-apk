// L4 — Départ du programme (KT-006) et références initiales (KT-007).
// Décisions du 26/09/2026 : date choisie = S1 · J1 (tout jour) ; bornes
// −280 jours / +1 an ; références inconnues par défaut (« Je ne sais pas ») ;
// installation existante : calendrier du 13/07/2026 et références gardées
// (« à vérifier »), départ modifiable sans remise à zéro.
// Stockage simulé, horloge contrôlée (`storeClock`), données synthétiques
// uniquement : aucune donnée réelle, aucun appareil.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/data_control.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/program_start.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'support/fake_notifications.dart';

const _key = 'kalis_state_v3';
final _anchor = DateTime(2026, 7, 13);
final _today = DateTime(2026, 9, 26, 10);

Map<String, dynamic> _json(AppStore app) =>
    jsonDecode(app.exportAll()) as Map<String, dynamic>;

/// Exercice du programme dont la charge dépend du poids du corps et d'un 1RM.
Exercise _systemExercise(Program p) =>
    [
      for (final w in p.weeks)
        for (final d in w.days)
          for (final e in d.exercises)
            if (e.load.type == 'system') e,
    ].first;

/// Exercice dont le volume suit un maximum en répétitions.
Exercise _volumeExercise(Program p) =>
    [
      for (final w in p.weeks)
        for (final d in w.days)
          for (final e in d.exercises)
            if (e.sets.type == 'volume') e,
    ].first;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final opened = <AppStore>[];

  Future<AppStore> launch(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final app = AppStore()..storeClock = () => _today;
    await app.init();
    opened.add(app);
    return app;
  }

  /// Relance sur le même stockage simulé.
  Future<AppStore> relaunch() async {
    final app = AppStore()..storeClock = () => _today;
    await app.init();
    opened.add(app);
    return app;
  }

  tearDown(() async {
    for (final app in opened) {
      app.debugWriteHook = null;
      await app.flush();
      app.dispose();
    }
    opened.clear();
  });

  /// État 2.5.7 synthétique (document unique sans `programStart` ni
  /// `referenceStatus`) : références complètes dont deux personnelles,
  /// séances faites avec et sans date.
  Future<Map<String, dynamic>> legacyState() async {
    final base = await launch({
      'settings_v1': jsonEncode(AppSettings().toJson()),
    });
    final m = _json(base);
    m.remove('programStart');
    m.remove('referenceStatus');
    (m['pilotage'] as Map<String, dynamic>)
      ..['B4'] = 81.5
      ..['B8'] = 32.5;
    m['logs'] = {
      'S1-J1':
          SessionLog(
            done: true,
            finishedAt: '2026-07-13T18:10:00.000',
            title: 'S1 · J1',
          ).toJson(),
      'S1-J2': SessionLog(done: true, title: 'S1 · J2').toJson(),
      'S6-J4':
          SessionLog(
            done: true,
            finishedAt: '2026-08-20T19:00:00.000',
            title: 'S6 · J4',
          ).toJson(),
    };
    return m;
  }

  group('Calendrier personnel (modèle)', () {
    late Program p;
    setUpAll(() async {
      p = (await launch({})).program;
    });
    tearDown(() => p.start = null);

    test('sans départ : aucune date inventée, semaine 1 affichée', () {
      p.start = null;
      expect(p.scheduled, isFalse);
      expect(() => p.dateFor(1, 1), throwsStateError);
      expect(p.weekFor(_today), 1);
      expect(p.dayFor(_today), 1);
      expect(p.containsDate(_today), isFalse);
      expect(p.beforeStart(_today), isFalse);
      expect(p.afterEnd(_today), isFalse);
      expect(p.endDate, isNull);
      expect(p.weekDates(1), 'dates à définir');
    });

    test('départ un mercredi : J1 = mercredi, 280 jours, fin S40 · J7', () {
      p.start = DateTime(2026, 9, 30);
      expect(p.dateFor(1, 1), DateTime(2026, 9, 30));
      expect(p.dateFor(1, 7), DateTime(2026, 10, 6));
      expect(p.dateFor(2, 1), DateTime(2026, 10, 7));
      expect(p.weekFor(DateTime(2026, 10, 7, 0, 5)), 2);
      expect(p.dayFor(DateTime(2026, 10, 7, 23, 59)), 1);
      expect(p.endDate, DateTime(2027, 7, 6));
      expect(p.dateFor(40, 7), p.endDate);
      expect(p.containsDate(DateTime(2027, 7, 6, 23, 59)), isTrue);
      expect(p.afterEnd(DateTime(2027, 7, 7)), isTrue);
      expect(p.weekFor(DateTime(2027, 7, 7)), 40); // jamais S41
      expect(p.beforeStart(DateTime(2026, 9, 29, 23, 59)), isTrue);
      expect(p.weekDates(1), '30/09→06/10/2026');
    });

    test('changement d’heure (25/10/2026) : jours civils, pas 24 h', () {
      p.start = DateTime(2026, 10, 19);
      expect(p.dateFor(2, 1), DateTime(2026, 10, 26));
      expect(p.dayFor(DateTime(2026, 10, 25, 23, 30)), 7);
      expect(p.weekFor(DateTime(2026, 10, 26, 0, 30)), 2);
      expect(p.dayFor(DateTime(2026, 10, 26, 0, 30)), 1);
      p.start = DateTime(2027, 3, 22); // passage à l'heure d'été le 28/03
      expect(p.dateFor(2, 1), DateTime(2027, 3, 29));
      expect(p.dayFor(DateTime(2027, 3, 28, 23, 30)), 7);
    });

    test('fin de mois, d’année et 29 février', () {
      p.start = DateTime(2026, 12, 29);
      expect(p.dateFor(1, 4), DateTime(2027, 1, 1));
      p.start = DateTime(2028, 2, 26);
      expect(p.dateFor(1, 4), DateTime(2028, 2, 29));
      expect(p.dateFor(1, 5), DateTime(2028, 3, 1));
      expect(p.dayFor(DateTime(2028, 2, 29, 12)), 4);
      p.start = DateTime(2026, 1, 31);
      expect(p.dateFor(1, 2), DateTime(2026, 2, 1));
    });

    test(
      'ancien journal sans date : ancrage d’origine, indépendant du départ',
      () {
        p.start = DateTime(2026, 9, 30);
        expect(p.legacyDateFor(1, 1), _anchor);
        expect(p.legacyDateFor(3, 2), DateTime(2026, 7, 28));
      },
    );

    test('dates civiles strictes (AAAA-MM-JJ)', () {
      expect(parseCivilDate('2028-02-29'), DateTime(2028, 2, 29));
      expect(parseCivilDate('2027-02-29'), isNull);
      expect(parseCivilDate('2026-13-01'), isNull);
      expect(parseCivilDate('2026-9-1'), isNull);
      expect(parseCivilDate('2026-09-26T00:00'), isNull);
      expect(parseCivilDate(20260926), isNull);
      expect(civilDateString(DateTime(2026, 7, 13, 23, 59)), '2026-07-13');
    });
  });

  group('Installation neuve et installations existantes', () {
    test('installation neuve : non démarrée, références inconnues', () async {
      final app = await launch({});
      expect(app.program.scheduled, isFalse);
      expect(app.startOrigin, '');
      expect(app.values, isEmpty);
      expect(app.refStatus, isEmpty);
      for (final ref in app.referenceRefs) {
        expect(app.refProvenance(ref), 'unknown');
      }
      final m = _json(app);
      expect(m['programStart'], {'status': 'pending'});
      expect(m['pilotage'], isEmpty);
      expect(m['referenceStatus'], isEmpty);
      // Relance : toujours neuve, jamais « migrée ».
      final again = await relaunch();
      expect(again.program.scheduled, isFalse);
      expect(again.values, isEmpty);
    });

    test(
      'première ouverture interrompue avant la sauvegarde : neuve',
      () async {
        final app = await launch({'wods_seed_v': 4, 'credits_v': 2});
        expect(app.program.scheduled, isFalse);
        expect(app.values, isEmpty);
      },
    );

    test(
      'ancienne installation (réglages, aucune séance) : calendrier du 13/07/2026',
      () async {
        final app = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        expect(app.program.start, _anchor);
        expect(app.startOrigin, 'migration');
        expect(app.values.length, app.referenceRefs.length);
        expect(app.refStatus.values.toSet(), {'historic'});
        expect(app.program.weekFor(_today), 11);
        // Migration relancée : même résultat, rien de requalifié.
        final json = (await SharedPreferences.getInstance()).getString(_key);
        final again = await relaunch();
        expect(again.program.start, _anchor);
        expect(again.startOrigin, 'migration');
        expect(again.values, app.values);
        expect(again.refStatus, app.refStatus);
        await again.flush();
        expect((await SharedPreferences.getInstance()).getString(_key), json);
      },
    );

    test(
      'ancienne installation : ses références personnelles priment',
      () async {
        final app = await launch({
          'pilotage_v1': jsonEncode({'B4': 77.0, 'B8': 20.0}),
        });
        expect(app.values['B4'], 77.0);
        expect(app.values['B8'], 20.0);
        expect(app.refProvenance('B4'), 'historic');
        expect(app.program.start, _anchor);
      },
    );

    test(
      'état 2.5.7 : semaine, dates, références, séances, crédits conservés ; migration idempotente',
      () async {
        final legacy = await legacyState();
        final app = await launch({_key: jsonEncode(legacy)});
        expect(app.program.start, _anchor);
        expect(app.startOrigin, 'migration');
        expect(app.program.weekFor(_today), 11); // pas de retour en S1
        expect(app.values['B4'], 81.5);
        expect(app.values['B8'], 32.5);
        expect(app.refProvenance('B4'), 'historic');
        expect(app.refStatus.values.toSet(), {'historic'});
        final pilotage = legacy['pilotage'] as Map<String, dynamic>;
        for (final e in pilotage.entries) {
          expect(app.values[e.key], (e.value as num).toDouble());
        }
        expect(app.logs.keys.toSet(), {'S1-J1', 'S1-J2', 'S6-J4'});
        expect(app.logs['S1-J1']!.finishedAt, '2026-07-13T18:10:00.000');
        expect(app.logs['S1-J2']!.finishedAt, isNull);
        expect(app.logs['S6-J4']!.finishedAt, '2026-08-20T19:00:00.000');
        final before = (
          xp: app.xp,
          level: app.level,
          credits: app.credits,
          grants: Map.of(app.creditGrants),
          unlocked: Map.of(app.unlockedWods),
        );
        // Deuxième lancement : aucun changement supplémentaire.
        await app.flush();
        final stored = (await SharedPreferences.getInstance()).getString(_key);
        final again = await relaunch();
        expect(again.program.start, _anchor);
        expect(again.values, app.values);
        expect(again.refStatus, app.refStatus);
        expect(again.xp, before.xp);
        expect(again.level, before.level);
        expect(again.credits, before.credits);
        expect(again.creditGrants, before.grants);
        expect(again.unlockedWods, before.unlocked);
        await again.flush();
        expect((await SharedPreferences.getInstance()).getString(_key), stored);
      },
    );

    test(
      'effacement complet : programme non démarré, références inconnues',
      () async {
        final app = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        final result = await app.eraseAllData();
        expect(result.status, isNot(EraseStatus.failed));
        expect(app.program.scheduled, isFalse);
        expect(app.values, isEmpty);
        expect(app.refStatus, isEmpty);
        final again = await relaunch();
        expect(again.program.scheduled, isFalse);
        expect(again.values, isEmpty);
      },
    );
  });

  group('Choix du départ', () {
    test('bornes incluses : −280 jours et +365 jours', () async {
      final app = await launch({});
      expect(app.startAllowed(DateTime(2025, 12, 20)), isTrue); // −280
      expect(app.startAllowed(DateTime(2025, 12, 19)), isFalse);
      expect(app.startAllowed(DateTime(2027, 9, 26)), isTrue); // +365
      expect(app.startAllowed(DateTime(2027, 9, 27)), isFalse);
      expect(
        await app.configureStart(DateTime(2025, 12, 19)),
        StartSave.outOfRange,
      );
      expect(app.program.scheduled, isFalse);
      expect(await app.configureStart(DateTime(2025, 12, 20)), StartSave.saved);
      expect(app.program.weekFor(_today), 40);
    });

    test(
      'départ futur non lundi + références partielles : persistés, rien d’autre créé',
      () async {
        final app = await launch({});
        final logs = app.logs.length;
        final xp = app.xp, credits = app.credits;
        final grants = Map.of(app.creditGrants);
        final result = await app.configureStart(
          DateTime(2026, 10, 1, 21, 45), // jeudi, heure ignorée
          references: {'B4': 72.5, 'B8': null},
        );
        expect(result, StartSave.saved);
        expect(app.program.start, DateTime(2026, 10, 1));
        expect(app.startOrigin, 'user');
        expect(app.values, {'B4': 72.5});
        expect(app.refStatus, {'B4': 'set'});
        expect(app.program.beforeStart(_today), isTrue);
        expect(app.logs.length, logs);
        expect(app.xp, xp);
        expect(app.credits, credits);
        expect(app.creditGrants, grants);
        expect(app.hasUnsavedChanges, isFalse);
        final again = await relaunch();
        expect(again.program.start, DateTime(2026, 10, 1));
        expect(again.startOrigin, 'user');
        expect(again.values, {'B4': 72.5});
        expect(again.refStatus, {'B4': 'set'});
        expect(_json(again)['programStart'], {
          'status': 'set',
          'date': '2026-10-01',
          'origin': 'user',
        });
      },
    );

    test('départ passé : reprise à la bonne semaine', () async {
      final app = await launch({});
      expect(await app.configureStart(DateTime(2026, 8, 31)), StartSave.saved);
      expect(app.program.weekFor(_today), 4);
      expect(app.program.dayFor(_today), 6);
    });

    test('référence invalide : rien n’est modifié', () async {
      final app = await launch({});
      for (final bad in [double.nan, double.infinity, -1.0, 10000.5]) {
        expect(
          await app.configureStart(_today, references: {'B8': bad}),
          StartSave.invalid,
        );
      }
      expect(
        await app.configureStart(_today, references: {'B4': 0}),
        StartSave.invalid,
      );
      expect(
        await app.configureStart(_today, references: {'ZZ9': 1}),
        StartSave.invalid,
      );
      expect(app.program.scheduled, isFalse);
      expect(app.values, isEmpty);
    });

    test(
      'écriture refusée : départ non annoncé, état rétabli, nouvel essai',
      () async {
        final app = await launch({});
        final stored = (await SharedPreferences.getInstance()).getString(_key);
        app.debugWriteHook = (_) async => false;
        final failed = await app.configureStart(
          DateTime(2026, 9, 28),
          references: {'B4': 70},
        );
        expect(failed, StartSave.unsaved);
        expect(app.program.scheduled, isFalse);
        expect(app.startOrigin, '');
        expect(app.values, isEmpty);
        expect(app.refStatus, isEmpty);
        expect((await SharedPreferences.getInstance()).getString(_key), stored);
        app.debugWriteHook = null;
        expect(
          await app.configureStart(
            DateTime(2026, 9, 28),
            references: {'B4': 70},
          ),
          StartSave.saved,
        );
        final again = await relaunch();
        expect(again.program.start, DateTime(2026, 9, 28));
        expect(again.values, {'B4': 70.0});
      },
    );

    test(
      'double confirmation : un seul état, aucune séance dupliquée',
      () async {
        final app = await launch({});
        final results = await Future.wait([
          app.configureStart(DateTime(2026, 9, 28)),
          app.configureStart(DateTime(2026, 9, 28)),
        ]);
        expect(results, [StartSave.saved, StartSave.saved]);
        expect(app.program.start, DateTime(2026, 9, 28));
        expect(app.logs, isEmpty);
        final again = await relaunch();
        expect(again.program.start, DateTime(2026, 9, 28));
      },
    );

    test(
      'installation existante : changer la date ne touche ni séances, ni dates réelles, ni récompenses',
      () async {
        final legacy = await legacyState();
        final app = await launch({_key: jsonEncode(legacy)});
        final logsBefore = jsonEncode(
          app.logs.map((k, v) => MapEntry(k, v.toJson())),
        );
        final before = (
          xp: app.xp,
          level: app.level,
          credits: app.credits,
          grants: Map.of(app.creditGrants),
          unlocked: Map.of(app.unlockedWods),
          values: Map.of(app.values),
          status: Map.of(app.refStatus),
          weeks: app.progression.weeks.keys.toList(),
          trial: app.trialWod?.id,
          weekly: [for (final w in app.weeklyPicks) w.id],
        );
        expect(
          await app.configureStart(DateTime(2026, 9, 21)),
          StartSave.saved,
        );
        expect(app.program.weekFor(_today), 1);
        expect(app.startOrigin, 'user');
        expect(
          jsonEncode(app.logs.map((k, v) => MapEntry(k, v.toJson()))),
          logsBefore,
        );
        expect(app.isDone(6, 4), isTrue);
        expect(app.xp, before.xp);
        expect(app.level, before.level);
        expect(app.credits, before.credits);
        expect(app.creditGrants, before.grants);
        expect(app.unlockedWods, before.unlocked);
        expect(app.values, before.values);
        expect(app.refStatus, before.status); // toujours « à vérifier »
        expect(app.progression.weeks.keys.toList(), before.weeks);
        expect(app.trialWod?.id, before.trial);
        expect([for (final w in app.weeklyPicks) w.id], before.weekly);
        // Séance sans date : même semaine civile qu'avant le changement.
        final p = Progression.calculate(
          logs: app.logs,
          catalog: app.wods,
          program: app.program,
          now: _today,
        );
        expect(p.totalXp, before.xp);
      },
    );
  });

  group('Sauvegardes', () {
    test(
      'aller-retour 2.5.8 : départ, provenance et références intacts',
      () async {
        final app = await launch({});
        await app.configureStart(
          DateTime(2026, 10, 5),
          references: {'B4': 68.5, 'B17': 12},
        );
        final exported = app.exportAll();
        final target = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        expect(target.program.start, _anchor);
        final status = await target.importBackup(exported);
        expect(status, ImportStatus.success);
        expect(target.program.start, DateTime(2026, 10, 5));
        expect(target.startOrigin, 'user');
        expect(target.values, {'B4': 68.5, 'B17': 12.0});
        expect(target.refStatus, {'B4': 'set', 'B17': 'set'});
        expect(jsonDecode(target.exportAll())['programStart'], {
          'status': 'set',
          'date': '2026-10-05',
          'origin': 'user',
        });
      },
    );

    test(
      'sauvegarde d’un utilisateur non démarré : restaurée telle quelle',
      () async {
        final app = await launch({});
        final exported = app.exportAll();
        final target = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        expect(await target.importBackup(exported), ImportStatus.success);
        expect(target.program.scheduled, isFalse);
        expect(target.values, isEmpty);
      },
    );

    test(
      'ancienne sauvegarde : migrée (13/07/2026, références « à vérifier »), jamais « aujourd’hui »',
      () async {
        final legacy = await legacyState();
        final target = await launch({});
        final preview = target.previewImport(jsonEncode(legacy)).preview!;
        expect(preview.programStart, _anchor);
        expect(preview.startOrigin, 'migration');
        expect(preview.referencesSet, 0);
        expect(preview.referencesHistoric, target.referenceRefs.length);
        expect(
          await target.importBackup(jsonEncode(legacy)),
          ImportStatus.success,
        );
        expect(target.program.start, _anchor);
        expect(target.startOrigin, 'migration');
        expect(target.values['B4'], 81.5);
        expect(target.refProvenance('B8'), 'historic');
        expect(target.logs['S6-J4']!.finishedAt, '2026-08-20T19:00:00.000');
      },
    );

    test('fichier invalide : refusé, départ et références inchangés', () async {
      final app = await launch({});
      await app.configureStart(DateTime(2026, 9, 28), references: {'B4': 70});
      final good = _json(app);
      Map<String, dynamic> variant(void Function(Map<String, dynamic>) edit) {
        final m = jsonDecode(jsonEncode(good)) as Map<String, dynamic>;
        edit(m);
        return m;
      }

      final bad = [
        variant(
          (m) =>
              m['programStart'] = {
                'status': 'set',
                'date': '2027-02-29',
                'origin': 'user',
              },
        ),
        variant(
          (m) =>
              m['programStart'] = {
                'status': 'set',
                'date': '1999-12-27',
                'origin': 'user',
              },
        ),
        variant(
          (m) =>
              m['programStart'] = {
                'status': 'set',
                'date': '2026-09-28',
                'origin': 'autre',
              },
        ),
        variant((m) => m['programStart'] = {'status': 'set'}),
        variant(
          (m) =>
              m['programStart'] = {'status': 'pending', 'date': '2026-09-28'},
        ),
        variant((m) => m['programStart'] = {'status': 'plus tard'}),
        variant((m) => m['programStart'] = '2026-09-28'),
        variant((m) => m['referenceStatus'] = {'B4': 'confirmed'}),
        variant((m) => m['referenceStatus'] = {'B4': 'set', 'B8': 'set'}),
        variant((m) {
          m['pilotage'] = {'B4': 70, 'ZZ9': 3};
          m['referenceStatus'] = {'B4': 'set', 'ZZ9': 'set'};
        }),
        variant((m) => m['pilotage'] = {'B4': 0}),
      ];
      for (final m in bad) {
        expect(
          await app.importBackup(jsonEncode(m)),
          ImportStatus.invalid,
          reason: jsonEncode(m['programStart']),
        );
        expect(app.program.start, DateTime(2026, 9, 28));
        expect(app.values, {'B4': 70.0});
        expect(app.refStatus, {'B4': 'set'});
      }
      // Valeur sans provenance (fichier retouché) : gardée « à vérifier ».
      final undocumented = variant(
        (m) => m['referenceStatus'] = <String, dynamic>{},
      );
      expect(
        await app.importBackup(jsonEncode(undocumented)),
        ImportStatus.success,
      );
      expect(app.values, {'B4': 70.0});
      expect(app.refStatus, {'B4': 'historic'});
      // Clé d'une ancienne version, gardée « à vérifier » : acceptée.
      final kept = variant((m) {
        m['pilotage'] = {'B4': 70, 'ZZ9': 3};
        m['referenceStatus'] = {'B4': 'set', 'ZZ9': 'historic'};
      });
      expect(await app.importBackup(jsonEncode(kept)), ImportStatus.success);
      expect(app.values['ZZ9'], 3.0);
      final round = app.exportAll();
      expect(await app.importBackup(round), ImportStatus.success);
      expect(app.values['ZZ9'], 3.0);
    });
  });

  group('Références (KT-007)', () {
    test(
      'inconnue : charge et volume « à renseigner », jamais calculés sur 0',
      () async {
        final app = await launch({});
        final load = _systemExercise(app.program);
        final volume = _volumeExercise(app.program);
        expect(app.loadFor(load), isNull);
        expect(app.loadLabel(load), 'à renseigner');
        expect(app.missingReference(load), 'B4');
        expect(app.setsLabel(volume), contains('?'));
        final sp = app.logSpec(volume);
        expect(
          app.plannedReps(volume, sp, app.setCount(volume)).whereType<int>(),
          isEmpty,
        );
        // Partielle : poids du corps seul, 1RM toujours inconnu.
        app.setValue('B4', 75);
        expect(app.loadFor(load), isNull);
        expect(app.missingReference(load), load.load.ref);
        app.setValue(load.load.ref!, 20);
        expect(app.loadFor(load), isNotNull);
        expect(app.loadNeedsReference(load), isFalse);
        app.setValue(volume.sets.ref!, 20);
        expect(app.setsLabel(volume), isNot(contains('?')));
      },
    );

    test(
      'renseignée explicitement, même égale à l’ancienne valeur embarquée',
      () async {
        final legacy = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        final embedded = legacy.values['B8']!;
        final app = await launch({});
        app.setValue('B8', embedded);
        expect(app.refProvenance('B8'), 'set');
        expect(app.values['B8'], embedded);
        await app.flush();
        final again = await relaunch();
        expect(again.refProvenance('B8'), 'set');
      },
    );

    test(
      'historique : confirmée sans changer la valeur, ou « Je ne sais pas »',
      () async {
        final app = await launch({
          'pilotage_v1': jsonEncode({'B4': 77.0}),
        });
        app.confirmReference('B4');
        expect(app.refProvenance('B4'), 'set');
        expect(app.values['B4'], 77.0);
        app.clearReference('B8');
        expect(app.refProvenance('B8'), 'unknown');
        expect(app.values.containsKey('B8'), isFalse);
        app.resetPilotage();
        expect(app.values, isEmpty);
        await app.flush();
        final again = await relaunch();
        expect(again.values, isEmpty);
        expect(again.program.start, _anchor); // calendrier jamais touché
      },
    );

    test('valeurs hors domaine refusées, valeur précédente gardée', () async {
      final app = await launch({});
      app.setValue('B4', 72);
      for (final bad in [double.nan, double.infinity, -3.0, 0.0, 10001.0]) {
        app.setValue('B4', bad);
      }
      expect(app.values['B4'], 72.0);
      app.setValue('ZZ9', 5);
      expect(app.values.containsKey('ZZ9'), isFalse);
    });

    test('saisie : virgule, point, vide, texte, non finie, bornes', () {
      expect(parseReference('72,5', 'B4'), 72.5);
      expect(parseReference(' 72.5 ', 'B4'), 72.5);
      expect(parseReference('0', 'B8'), 0.0);
      expect(parseReference('0', 'B4'), isNull);
      expect(parseReference('', 'B4'), isNull);
      expect(parseReference('abc', 'B4'), isNull);
      expect(parseReference('NaN', 'B4'), isNull);
      expect(parseReference('Infinity', 'B4'), isNull);
      expect(parseReference('1e3', 'B4'), isNull);
      expect(parseReference('-5', 'B8'), isNull);
      expect(parseReference('72,555', 'B4'), isNull);
      expect(parseReference('10000', 'B8'), 10000.0);
      expect(parseReference('10000,5', 'B8'), isNull);
      expect(formatReference(72.5), '72,5');
      expect(formatReference(80), '80');
    });

    test(
      'affichage en livres : les références restent en kg, sans dérive',
      () async {
        final app = await launch({});
        app.setValue('B4', 72.5);
        app.setValue('B8', 17.5);
        final load = _systemExercise(app.program);
        app.setValue(load.load.ref!, 30);
        final kg = app.loadFor(load);
        for (var i = 0; i < 5; i++) {
          app.settings.lb = !app.settings.lb;
          app.saveSettings();
        }
        expect(app.values['B4'], 72.5);
        expect(app.values['B8'], 17.5);
        expect(app.loadFor(load), kg);
        app.settings.lb = true;
        if (kg! > 0) expect(app.loadLabel(load), contains('lb'));
      },
    );
  });

  group('Rappels', () {
    final now = DateTime.utc(2026, 9, 26, 8);
    setUpAll(tzdata.initializeTimeZones);

    test('non démarré : aucun rappel', () async {
      final app = await launch({});
      app.settings.notifOn = true;
      expect(planReminders(app, now), isEmpty);
    });

    test(
      'départ futur : premier rappel le jour de S1 · J1, aucun avant',
      () async {
        final app = await launch({});
        app.settings
          ..notifOn = true
          ..notifSkipRest = false;
        await app.configureStart(DateTime(2026, 10, 1));
        final plan = planReminders(
          app,
          now,
          location: tz.getLocation('Europe/Paris'),
        );
        expect(plan.first.payload, 'S1-J1');
        expect(
          [plan.first.at.year, plan.first.at.month, plan.first.at.day],
          [2026, 10, 1],
        );
        expect(plan.length, 280);
        expect(plan.map((r) => r.id).toSet().length, plan.length);
      },
    );

    test(
      'changement de départ : mêmes identifiants replanifiés, aucun doublon',
      () async {
        final app = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        app.settings
          ..notifOn = true
          ..notifSkipRest = false;
        final backend = FakeNotifications();
        final service = NotificationService(app, backend, now: () => now);
        addTearDown(service.dispose);
        service.bind();
        await service.reschedule();
        final firstIds = Set.of(backend.pending);
        expect(firstIds, isNotEmpty);
        expect(
          await app.configureStart(DateTime(2026, 9, 28)),
          StartSave.saved,
        );
        await service.reschedule();
        final byId = <int, PlannedReminder>{};
        for (final s in backend.scheduled) {
          byId[s.reminder.id] = s.reminder;
        }
        final s1j1 = byId[1001]!;
        expect([s1j1.at.month, s1j1.at.day], [9, 28]);
        expect(backend.pending.every((id) => id >= 1001 && id <= 1280), isTrue);
        expect(backend.pending.length, 280);
      },
    );
  });

  group('Rappels : erreurs et ouverture', () {
    final now = DateTime.utc(2026, 9, 26, 8);
    setUpAll(tzdata.initializeTimeZones);

    test(
      'échec de programmation : visible, départ conservé, reprise possible',
      () async {
        final app = await launch({});
        app.settings.notifOn = true;
        final backend = FakeNotifications()..failSchedule = true;
        final service = NotificationService(app, backend, now: () => now);
        addTearDown(service.dispose);
        expect(
          await app.configureStart(DateTime(2026, 9, 28)),
          StartSave.saved,
        );
        await service.reschedule();
        expect(service.status.value.error, isNotNull);
        expect(app.program.start, DateTime(2026, 9, 28));
        expect(app.hasUnsavedChanges, isFalse);
        backend.failSchedule = false;
        await service.reschedule();
        expect(service.status.value.error, isNull);
        expect(service.status.value.count, greaterThan(0));
        expect(app.program.start, DateTime(2026, 9, 28));
      },
    );

    test(
      'ancienne notification après changement de départ : même journée S · J, à froid et à chaud',
      () async {
        final app = await launch({
          'settings_v1': jsonEncode(AppSettings().toJson()),
        });
        final opened = <(int, int)>[];
        final backend = FakeNotifications()..launchPayload = 'S11-J6';
        final service = NotificationService(app, backend, now: () => now)
          ..onOpen = (w, d) => opened.add((w, d));
        addTearDown(service.dispose);
        expect(
          await app.configureStart(DateTime(2026, 9, 21)),
          StartSave.saved,
        );
        await service.init(); // ouverture à froid
        backend.open!('S2-J3'); // ouverture à chaud
        backend.open!('S41-J1'); // hors programme : ignorée
        backend.open!('2026-09-28'); // format inconnu : ignoré
        expect(opened, [(11, 6), (2, 3)]);
      },
    );
  });

  group('Comparaison avant / après (migration synthétique)', () {
    setUpAll(tzdata.initializeTimeZones);
    test(
      'utilisateur avancé : semaine, dates, séances, références, récompenses, rappels',
      () async {
        final legacy = await legacyState();
        // Utilisateur avancé : S1 à S10 faites à la date prévue d'origine.
        final logs = legacy['logs'] as Map<String, dynamic>;
        final base = (await launch({})).program;
        for (var w = 1; w <= 10; w++) {
          for (final d in base
              .week(w)
              .days
              .where((d) => d.exercises.isNotEmpty)) {
            final date = base.legacyDateFor(w, d.j);
            logs.putIfAbsent(
              'S$w-J${d.j}',
              () =>
                  SessionLog(
                    done: true,
                    finishedAt:
                        DateTime(
                          date.year,
                          date.month,
                          date.day,
                          18,
                        ).toIso8601String(),
                    title: 'S$w · J${d.j}',
                  ).toJson(),
            );
          }
        }
        final app = await launch({_key: jsonEncode(legacy)});
        app.settings
          ..notifOn = true
          ..notifSkipRest = false;
        String snapshot(AppStore a) {
          final plan = planReminders(
            a,
            DateTime.utc(2026, 9, 26, 8),
            location: tz.getLocation('Europe/Paris'),
          );
          return jsonEncode({
            'semaine':
                'S${a.program.weekFor(_today)} · J${a.program.dayFor(_today)}',
            'depart':
                a.program.start == null
                    ? null
                    : civilDateString(a.program.start!),
            'origine': a.startOrigin,
            'datesS11': a.program.weekDates(11),
            'seances': a.logs.length,
            'S6-J4': a.logs['S6-J4']?.finishedAt,
            'S1-J2': a.logs['S1-J2']?.finishedAt,
            'B4': a.values['B4'],
            'B8': a.values['B8'],
            'provenanceB4': a.refProvenance('B4'),
            'xp': a.xp,
            'niveau': a.level,
            'credits': a.credits,
            'gains': a.creditGrants.values.fold<int>(0, (x, y) => x + y),
            'droitsWod': a.unlockedWods.length,
            'rappels': plan.length,
            'premierRappel':
                plan.isEmpty
                    ? null
                    : '${plan.first.payload} ${plan.first.at.toIso8601String().substring(0, 16)}',
          });
        }

        final migrated = snapshot(app);
        await app.flush();
        final relaunched = snapshot(await relaunch());
        expect(relaunched, migrated);
        expect(
          await app.configureStart(DateTime(2026, 9, 21)),
          StartSave.saved,
        );
        final moved = snapshot(app);
        // ignore: avoid_print
        print('L4-COMPARE migration $migrated');
        // ignore: avoid_print
        print('L4-COMPARE relance $relaunched');
        // ignore: avoid_print
        print('L4-COMPARE depart-21-09 $moved');
        final a = jsonDecode(migrated) as Map<String, dynamic>;
        final b = jsonDecode(moved) as Map<String, dynamic>;
        expect(a['semaine'], 'S11 · J6');
        expect(a['depart'], '2026-07-13');
        expect(a['datesS11'], '21/09→27/09/2026');
        expect(b['semaine'], 'S1 · J6');
        for (final k in [
          'seances',
          'S6-J4',
          'S1-J2',
          'B4',
          'B8',
          'provenanceB4',
          'xp',
          'niveau',
          'credits',
          'gains',
          'droitsWod',
        ]) {
          expect(b[k], a[k], reason: k);
        }
      },
    );
  });

  group('Écrans', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.storeClock = () => _today;
      store.settings
        ..sound = false
        ..vibration = false;
    });

    var reschedules = 0;
    setUp(() {
      reschedules = 0;
      rescheduleReminders = () async => reschedules++;
      store.debugWriteHook = null;
      store.program.start = null;
      store.startOrigin = '';
      store.values.clear();
      store.refStatus.clear();
    });

    Widget page(Widget child, {double scale = 1, bool dark = true}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: child,
        );

    void phone(WidgetTester tester, Size size) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    /// Défilement réel jusqu'à l'élément (liste construite à la demande).
    Future<void> reveal(WidgetTester tester, Finder finder) =>
        tester.scrollUntilVisible(
          finder,
          200,
          scrollable: find.byType(Scrollable).first,
        );

    /// Écran ouvert par-dessus une page, pour tester le retour.
    Widget host(DateTime initial) => Builder(
      builder:
          (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<bool>(
                        builder:
                            (_) => ProgramStartScreen(initialDate: initial),
                      ),
                    ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
    );

    testWidgets(
      'premier départ : date, référence saisie, les autres inconnues',
      (tester) async {
        phone(tester, const Size(390, 844));
        await tester.pumpWidget(page(host(DateTime(2026, 9, 30))));
        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();
        expect(find.text('mercredi 30 septembre 2026'), findsOneWidget);
        expect(
          find.textContaining('Fin prévue (S40 · J7) : mardi 6 juillet 2027'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('start-current')), findsNothing);
        await reveal(tester, find.byKey(const ValueKey('start-ref-B4')));
        await tester.enterText(
          find.byKey(const ValueKey('start-ref-B4')),
          '72,5',
        );
        await tester.tap(find.byKey(const ValueKey('start-confirm')));
        await tester.tap(
          find.byKey(const ValueKey('start-confirm')),
          warnIfMissed: false,
        );
        await tester.runAsync(() => store.flush());
        await tester.pumpAndSettle();
        expect(find.byType(ProgramStartScreen), findsNothing);
        expect(store.program.start, DateTime(2026, 9, 30));
        expect(store.startOrigin, 'user');
        expect(store.values, {'B4': 72.5});
        expect(store.refStatus, {'B4': 'set'});
        expect(reschedules, 1);
        expect(find.textContaining('Départ enregistré'), findsOneWidget);
      },
    );

    testWidgets('« Plus tard » et retour système : rien n’est enregistré', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      await tester.pumpWidget(page(host(DateTime(2026, 9, 30))));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('start-ref-B4')));
      await tester.enterText(find.byKey(const ValueKey('start-ref-B4')), '70');
      await tester.tap(find.byKey(const ValueKey('start-later')));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramStartScreen), findsNothing);
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(ProgramStartScreen), findsNothing);
      expect(store.program.scheduled, isFalse);
      expect(store.values, isEmpty);
      expect(reschedules, 0);
    });

    testWidgets('saisie invalide : message, aucun enregistrement', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      await tester.pumpWidget(page(host(DateTime(2026, 9, 30))));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const ValueKey('start-ref-B4')));
      await tester.enterText(find.byKey(const ValueKey('start-ref-B4')), '7O');
      await tester.tap(find.byKey(const ValueKey('start-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Nombre (ex. 72,5) ou vide'), findsOneWidget);
      expect(store.program.scheduled, isFalse);
      expect(find.byType(ProgramStartScreen), findsOneWidget);
    });

    testWidgets('écriture refusée : message, écran conservé, nouvel essai', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      await tester.pumpWidget(page(host(DateTime(2026, 9, 30))));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      store.debugWriteHook = (_) async => false;
      await tester.tap(find.byKey(const ValueKey('start-confirm')));
      await tester.runAsync(() => store.flush());
      await tester.pumpAndSettle();
      expect(find.textContaining('Enregistrement impossible'), findsOneWidget);
      expect(store.program.scheduled, isFalse);
      expect(find.byType(ProgramStartScreen), findsOneWidget);
      expect(reschedules, 0);
      store.debugWriteHook = null;
      await tester.tap(find.byKey(const ValueKey('start-confirm')));
      await tester.runAsync(() => store.flush());
      await tester.pumpAndSettle();
      expect(store.program.start, DateTime(2026, 9, 30));
      expect(reschedules, 1);
    });

    testWidgets('installation existante : aperçu de l’effet, puis changement', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      store.program.start = _anchor;
      store.startOrigin = 'migration';
      store.values['B4'] = 81.5;
      store.refStatus['B4'] = 'historic';
      await tester.pumpWidget(page(host(DateTime(2026, 9, 21))));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-current')), findsOneWidget);
      expect(find.textContaining('Calendrier d’origine'), findsOneWidget);
      expect(find.byKey(const ValueKey('start-ref-B4')), findsNothing);
      await reveal(tester, find.byKey(const ValueKey('start-impact')));
      expect(find.textContaining('S11 · J6 → S1 · J6'), findsOneWidget);
      expect(
        find.textContaining(
          'gardent leur semaine, leur jour et leur date réelle',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('start-confirm')));
      await tester.runAsync(() => store.flush());
      await tester.pumpAndSettle();
      expect(store.program.start, DateTime(2026, 9, 21));
      expect(store.values, {'B4': 81.5});
      expect(store.refStatus, {'B4': 'historic'});
      expect(reschedules, 1);
    });

    testWidgets('même date : bouton inactif, rien à replanifier', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      store.program.start = _anchor;
      store.startOrigin = 'migration';
      await tester.pumpWidget(page(host(_anchor)));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('start-confirm')),
      );
      expect(button.onPressed, isNull);
      expect(find.byKey(const ValueKey('start-impact')), findsNothing);
    });

    testWidgets('bandeau de l’accueil : non démarré, avant, pendant, après', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      Future<void> show(DateTime now) async {
        await tester.pumpWidget(
          page(Scaffold(body: ProgramStartBanner(now: now))),
        );
        await tester.pump();
      }

      await show(_today);
      expect(find.text('Programme non démarré'), findsOneWidget);
      expect(find.text('Choisir mon départ'), findsOneWidget);
      store.program.start = DateTime(2026, 10, 5);
      await show(_today);
      expect(find.text('Départ le lundi 5 octobre 2026'), findsOneWidget);
      expect(find.textContaining('dans 9 jours'), findsOneWidget);
      await show(DateTime(2026, 10, 5, 7));
      expect(find.byKey(const ValueKey('program-start-banner')), findsNothing);
      await show(DateTime(2027, 7, 12));
      expect(
        find.text('Programme terminé le dimanche 11 juillet 2027'),
        findsOneWidget,
      );
      expect(find.textContaining('aucun nouveau cycle'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('program-start-banner')));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramStartScreen), findsNothing);
    });

    testWidgets(
      'Références : inconnue, à vérifier, confirmée, « Je ne sais pas »',
      (tester) async {
        phone(tester, const Size(390, 844));
        store.values['B4'] = 77;
        store.refStatus['B4'] = 'historic';
        await tester.pumpWidget(page(const PilotageScreen()));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('references-historic')),
          findsOneWidget,
        );
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('B4-provenance'))).data,
          'À vérifier · valeur d’une version précédente',
        );
        final lift = store.program.pilotage.mainLifts.first.ref;
        await reveal(tester, find.byKey(ValueKey('$lift-provenance')));
        expect(
          tester.widget<Text>(find.byKey(ValueKey('$lift-provenance'))).data,
          'Non renseigné',
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('B4-confirm')),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('B4-confirm')));
        await tester.pump();
        expect(store.refProvenance('B4'), 'set');
        expect(store.values['B4'], 77.0);
        expect(find.byKey(const ValueKey('B4-provenance')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('B4-unknown')));
        await tester.pump();
        expect(store.refProvenance('B4'), 'unknown');
        await tester.runAsync(() => store.flush());
      },
    );

    for (final (size, scale) in [
      (const Size(320, 720), 2.0),
      (const Size(390, 844), 1.0),
    ]) {
      testWidgets(
        'accueil non démarré ${size.width.toInt()} px · ${(scale * 100).round()} % : bandeau dans la liste, journées accessibles',
        (tester) async {
          phone(tester, size);
          await tester.pumpWidget(
            page(RootNav(referenceDate: _today), scale: scale),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Programme non démarré'), findsOneWidget);
          final list =
              find
                  .descendant(
                    of: find.byKey(const PageStorageKey('programme-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first;
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('programme-day-1')),
            200,
            scrollable: list,
          );
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('program-start-open')),
            -200,
            scrollable: list,
          );
          await tester.tap(find.byKey(const ValueKey('program-start-open')));
          await tester.pumpAndSettle();
          expect(find.byType(ProgramStartScreen), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('start-later')));
          await tester.pumpAndSettle();
          expect(store.program.scheduled, isFalse);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }

    for (final (size, scale, dark) in [
      (const Size(320, 720), 1.3, false),
      (const Size(320, 720), 2.0, true),
      (const Size(320, 720), 2.0, false),
      (const Size(390, 844), 1.0, true),
    ]) {
      testWidgets(
        'rendu ${size.width.toInt()} px · ${(scale * 100).round()} % · ${dark ? 'sombre' : 'clair'} : sans débordement',
        (tester) async {
          phone(tester, size);
          final semantics = tester.ensureSemantics();
          await tester.pumpWidget(
            page(
              ProgramStartScreen(initialDate: DateTime(2026, 9, 30)),
              scale: scale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(RegExp('Confirmer le départ')),
            findsOneWidget,
          );
          await reveal(tester, find.byKey(const ValueKey('start-ref-B4')));
          await tester.showKeyboard(find.byKey(const ValueKey('start-ref-B4')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          store.program.start = _anchor;
          store.startOrigin = 'migration';
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            page(
              ProgramStartScreen(initialDate: DateTime(2026, 9, 21)),
              scale: scale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            find.bySemanticsLabel(RegExp('Changer la date')),
            findsOneWidget,
          );
          await tester.pumpWidget(
            page(
              Scaffold(
                body: ListView(
                  children: [ProgramStartBanner(now: DateTime(2027, 7, 12))],
                ),
              ),
              scale: scale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          store.program.start = null;
          await tester.pumpWidget(
            page(
              Scaffold(
                body: ListView(children: [ProgramStartBanner(now: _today)]),
              ),
              scale: scale,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          store.values['B4'] = 77;
          store.refStatus['B4'] = 'historic';
          await tester.pumpWidget(
            page(const PilotageScreen(), scale: scale, dark: dark),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          semantics.dispose();
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  });
}
