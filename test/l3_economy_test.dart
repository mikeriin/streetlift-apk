// L3 — Économie et essai WOD : KT-003 (terminer une tentative commencée
// avant minuit), KT-004 (essai du jour et vitrine stables), KT-005 (registre
// des gains, déficit visible, imports). Horloge de la boutique contrôlée ;
// stockage simulé. « Relance » = nouvelle instance relisant ce stockage.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_screen.dart';

import 'l2_fixtures.dart';
import 'support/score_sheet.dart';

DateTime Function() at(int y, int m, int d, [int h = 10, int min = 0]) =>
    () => DateTime(y, m, d, h, min);

Map<String, dynamic> business(AppStore a) =>
    jsonDecode(a.exportAll()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Store L3 (instances isolées, horloge contrôlée)', () {
    late AppStore app;
    final others = <AppStore>[];
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
      app.settings.sound = app.settings.vibration = false;
      app.storeClock = at(2026, 9, 24);
    });
    tearDown(() async {
      app.debugWriteHook = null;
      await app.flush();
      app.dispose();
      for (final other in others) {
        other.dispose();
      }
      others.clear();
    });

    Future<AppStore> relaunch(DateTime Function() clock) async {
      await app.flush();
      final next = AppStore();
      await next.init();
      next.storeClock = clock;
      others.add(next);
      return next;
    }

    /// Journée d'entraînement terminée à une date donnée.
    void session(AppStore a, int week, int day, String iso) {
      a.logs[a.sessionKey(week, day)] = SessionLog(done: true, finishedAt: iso);
    }

    List<(int, int)> trainingDays(AppStore a) => [
      for (final w in a.program.weeks)
        for (final d in w.days)
          if (d.exercises.isNotEmpty) (w.n, d.j),
    ];

    // ---------------- KT-004 : essai du jour ----------------

    test(
      'essai du jour : jamais tenté, fixé malgré niveau, référence, notification',
      () async {
        final trial = app.trialWod!;
        expect(trial.results, isEmpty);
        expect(app.unlocked(trial), isFalse);
        expect(app.weeklyIds, isNot(contains(trial.id)));
        app.notifyListeners();
        app.setValue('B4', 70);
        for (final (w, d) in trainingDays(app).take(3)) {
          session(app, w, d, '2026-09-24T09:00:00');
        }
        app.notifyListeners();
        expect(app.level, greaterThanOrEqualTo(2));
        expect(app.trialWod!.id, trial.id);
        final next = await relaunch(at(2026, 9, 24, 20));
        expect(next.trialWod!.id, trial.id);
      },
    );

    test('tentatives illimitées le jour même, résultat ne change rien', () {
      final trial = app.trialWod!;
      for (var i = 0; i < 3; i++) {
        final attempt = app.startAttempt(trial);
        expect(attempt, isNotNull);
        app.abandonAttempt(attempt);
      }
      app.addWodResult(
        trial,
        WodResult(at: '2026-09-24T11:00:00', score: '5:00', seconds: 300),
      );
      expect(app.trialWod!.id, trial.id);
      expect(app.canRun(trial), isTrue);
      expect(app.startAttempt(trial), isNotNull);
    });

    test(
      'achat de l’essai : acquis aussitôt, aucun second essai gratuit',
      () async {
        final trial = app.trialWod!;
        final cost = app.wodCost(trial);
        expect(cost, lessThanOrEqualTo(app.credits));
        final result = await app.purchaseWod(trial, acceptedCost: cost);
        expect(result.status, PurchaseStatus.success);
        expect(app.unlocked(trial), isTrue);
        expect(app.trialWod!.id, trial.id);
        final free = app.wods.where((w) => app.canRun(w) && !app.unlocked(w));
        expect(free, isEmpty);
        app.notifyListeners();
        expect(
          app.wods.where((w) => app.canRun(w) && !app.unlocked(w)),
          isEmpty,
        );
      },
    );

    test(
      'essai terminé puis acheté : remise d’essai appliquée, prix figé',
      () async {
        final trial = app.trialWod!;
        final base = app.basePrice(trial);
        app.addWodResult(
          trial,
          WodResult(at: '2026-09-24T11:00:00', score: '5:00', seconds: 300),
        );
        final cost = app.wodCost(trial);
        expect(cost, base == 1 ? 1 : base - 1);
        if (cost <= app.credits) {
          expect(
            (await app.purchaseWod(trial, acceptedCost: cost)).status,
            PurchaseStatus.success,
          );
          expect(app.unlockedWods[trial.id], cost);
          expect(app.trialWod!.id, trial.id);
        }
      },
    );

    test('jour suivant, recul d’horloge, heure d’hiver, année', () {
      final day1 = app.trialWod!.id;
      app.storeClock = at(2026, 9, 24, 23, 59);
      expect(app.trialWod!.id, day1);
      app.storeClock = at(2026, 9, 25, 0, 1);
      final day2 = app.trialWod!.id;
      expect(day2, isNot(day1));
      // Recul (fuseau vers l'ouest, horloge reculée) : pas de nouveau tirage.
      app.storeClock = at(2026, 9, 24, 18);
      expect(app.trialWod!.id, day2);
      // Nuit du passage à l'heure d'hiver : une seule journée civile.
      app.storeClock = at(2026, 10, 25, 1, 59);
      final dst = app.trialWod!.id;
      app.storeClock = at(2026, 10, 25, 3, 5);
      expect(app.trialWod!.id, dst);
      // Changement d'année.
      app.storeClock = at(2026, 12, 31, 23, 50);
      final dec = app.trialWod!.id;
      app.storeClock = at(2027, 1, 1, 0, 10);
      expect(app.trialWod!.id, isNot(dec));
    });

    test(
      'aucun candidat : pas d’essai, aucun WOD déjà tenté proposé',
      () async {
        for (final w in app.wods.where(app.isCatalog)) {
          w.results.add(
            WodResult(at: '2026-09-20T10:00:00', score: '1:00', seconds: 60),
          );
        }
        app.notifyListeners();
        app.storeClock = at(2026, 9, 25);
        expect(app.trialWod, isNull);
        expect(app.noTrialToday, isTrue);
        expect(
          app.wods.where((w) => app.canRun(w) && !app.unlocked(w)),
          isEmpty,
        );
      },
    );

    test('niveau élargi (±2 puis catalogue) avant l’absence d’essai', () {
      final t = app.targetWodLevel;
      for (final w in app.wods.where(app.isCatalog)) {
        if ((w.level - t).abs() <= 1) {
          w.results.add(
            WodResult(at: '2026-09-20T10:00:00', score: '1:00', seconds: 60),
          );
        }
      }
      app.notifyListeners();
      app.storeClock = at(2026, 9, 26);
      final trial = app.trialWod!;
      expect(trial.results, isEmpty);
      expect((trial.level - t).abs(), greaterThan(1));
    });

    test(
      'ancienne sauvegarde sans sélection : WOD joué aujourd’hui gardé',
      () async {
        final w = app.wods.firstWhere(
          (x) => app.isCatalog(x) && x.results.isEmpty && !app.unlocked(x),
        );
        final data = backupOf(app)
          ..remove('trialOfDay')
          ..remove('weeklyShowcase');
        final wods =
            ((data['catalog'] as Map)['results'] as Map<String, dynamic>);
        wods[w.id] = [
          WodResult(
            at: '2026-09-24T08:00:00',
            score: '3:00',
            seconds: 180,
          ).toJson(),
        ];
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        final results = app.wods.fold(0, (n, x) => n + x.results.length);
        expect(app.trialWod!.id, w.id);
        expect(app.wods.fold(0, (n, x) => n + x.results.length), results);
      },
    );

    // ---------------- KT-004 : vitrine ----------------

    test(
      'vitrine : fixée malgré niveau et relance, remplacement après achat',
      () async {
        final ids = app.weeklyPicks.map((w) => w.id).toList();
        expect(ids, hasLength(3));
        for (final (w, d) in trainingDays(app).take(3)) {
          session(app, w, d, '2026-09-22T09:00:00');
        }
        app.notifyListeners();
        expect(app.weeklyPicks.map((w) => w.id).toList(), ids);
        final pick = app.weeklyPicks.firstWhere(
          (w) => app.wodCost(w) <= app.credits,
        );
        final cost = app.wodCost(pick);
        expect(cost, app.basePrice(pick) == 1 ? 1 : app.basePrice(pick) - 1);
        expect(
          (await app.purchaseWod(pick, acceptedCost: cost)).status,
          PurchaseStatus.success,
        );
        expect(app.unlockedWods[pick.id], cost);
        final after = app.weeklyPicks.map((w) => w.id).toList();
        expect(after, hasLength(3));
        expect(after, isNot(contains(pick.id)));
        expect(after, isNot(contains(app.trialWod!.id)));
        expect(after.where(ids.contains), hasLength(2));
        final next = await relaunch(at(2026, 9, 27, 22));
        expect(next.weeklyPicks.map((w) => w.id).toList(), after);
        next.storeClock = at(2026, 9, 28, 8);
        expect(next.weeklyPicks.map((w) => w.id).toList(), isNot(after));
        expect(next.unlockedWods[pick.id], cost);
      },
    );

    test('vitrine : changement d’année (lundi 28/12 → lundi 04/01)', () {
      app.storeClock = at(2026, 12, 30);
      final dec = app.weeklyPicks.map((w) => w.id).toList();
      app.storeClock = at(2027, 1, 3, 23);
      expect(app.weeklyPicks.map((w) => w.id).toList(), dec);
      app.storeClock = at(2027, 1, 4, 0, 5);
      expect(app.weeklyPicks.map((w) => w.id).toList(), isNot(dec));
    });

    test('export/import : essai et vitrine conservés à l’identique', () async {
      final trial = app.trialWod!.id;
      final weekly = app.weeklyPicks.map((w) => w.id).toList();
      final file = app.exportForFile(appVersion: 'test');
      final meta = jsonDecode(file) as Map<String, dynamic>;
      expect(meta['trialOfDay'], {'day': '2026-09-24', 'wod': trial});
      expect((meta['weeklyShowcase'] as Map)['ids'], weekly);
      SharedPreferences.setMockInitialValues({});
      final other = await relaunch(at(2026, 9, 24, 21));
      expect(await other.importBackup(file), ImportStatus.success);
      expect(other.trialWod!.id, trial);
      expect(other.weeklyPicks.map((w) => w.id).toList(), weekly);
    });

    test('sélections invalides refusées à l’import', () async {
      for (final bad in [
        {'trialOfDay': 'hier'},
        {
          'trialOfDay': {'day': '24/09/2026', 'wod': 'x'},
        },
        {
          'weeklyShowcase': {
            'week': '2026-09-21',
            'ids': [1, 2],
          },
        },
        {
          'weeklyShowcase': {
            'week': '2026-09-21',
            'ids': ['a', 'b', 'c', 'd'],
          },
        },
        {
          'creditGrants': {'bonus:x': 99},
        },
        {
          'creditGrants': {'level:2': -2},
        },
      ]) {
        final data = backupOf(app)..addAll(bad);
        expect(
          await app.importBackup(jsonEncode(data)),
          ImportStatus.invalid,
          reason: '$bad',
        );
      }
    });

    // ---------------- KT-003 : tentative à cheval sur minuit ----------------

    test(
      'tentative lancée à 23 h 59, validée à 00 h 01 : un seul résultat',
      () async {
        app.storeClock = at(2026, 9, 24, 23, 59);
        final trial = app.trialWod!;
        final attempt = app.startAttempt(trial)!;
        app.storeClock = at(2026, 9, 25, 0, 1);
        expect(app.trialWod!.id, isNot(trial.id));
        expect(app.canRun(trial), isFalse);
        expect(app.canFinish(trial, attempt), isTrue);
        expect(app.canFinish(trial, 'autre'), isFalse);
        final r = WodResult(
          at: '2026-09-25T00:01:00',
          score: '8:00',
          seconds: 480,
        );
        expect(
          await app.recordWodResult(trial, r, attempt: attempt),
          ResultSave.saved,
        );
        expect(trial.results.single.attempt, attempt);
        // Double validation de la même tentative : aucun second résultat.
        final again = WodResult(at: '2026-09-25T00:01:02', score: '8:00');
        expect(
          await app.recordWodResult(trial, again, attempt: attempt),
          ResultSave.saved,
        );
        expect(trial.results, hasLength(1));
        expect(app.canFinish(trial, attempt), isFalse);
        expect(app.unlocked(trial), isFalse);
        final next = await relaunch(at(2026, 9, 25, 9));
        final saved = next.wods.firstWhere((w) => w.id == trial.id);
        expect(saved.results.single.attempt, attempt);
      },
    );

    test(
      'après minuit sans tentative ouverte : refus, rien enregistré',
      () async {
        app.storeClock = at(2026, 9, 24, 23, 59);
        final trial = app.trialWod!;
        final attempt = app.startAttempt(trial)!;
        app.abandonAttempt(attempt);
        app.storeClock = at(2026, 9, 25, 0, 1);
        final r = WodResult(at: '2026-09-25T00:01:00', score: '8:00');
        expect(
          await app.recordWodResult(trial, r, attempt: attempt),
          ResultSave.denied,
        );
        expect(trial.results, isEmpty);
        expect(app.startAttempt(trial), isNull);
      },
    );

    test(
      'écriture refusée puis reprise : un résultat, une récompense',
      () async {
        app.storeClock = at(2026, 9, 24, 23, 59);
        final trial = app.trialWod!;
        final attempt = app.startAttempt(trial)!;
        app.storeClock = at(2026, 9, 25, 0, 1);
        app.debugWriteHook = (_) async => false;
        final r = WodResult(
          at: '2026-09-25T00:01:00',
          score: '8:00',
          seconds: 480,
        );
        expect(
          await app.recordWodResult(trial, r, attempt: attempt),
          ResultSave.unsaved,
        );
        expect(trial.results, hasLength(1));
        final reward = app.consumeReward();
        app.debugWriteHook = null;
        expect(
          await app.recordWodResult(
            trial,
            WodResult(at: '2026-09-25T00:02:00', score: '8:00'),
            attempt: attempt,
          ),
          ResultSave.saved,
        );
        expect(trial.results, hasLength(1));
        expect(app.consumeReward(), isNull);
        expect(reward, isNotNull);
      },
    );

    test('achat du WOD pendant la tentative : validation normale', () async {
      final trial = app.trialWod!;
      final attempt = app.startAttempt(trial)!;
      expect(
        (await app.purchaseWod(trial, acceptedCost: app.wodCost(trial))).status,
        PurchaseStatus.success,
      );
      app.storeClock = at(2026, 9, 25, 0, 1);
      expect(
        await app.recordWodResult(
          trial,
          WodResult(at: '2026-09-25T00:01:00', score: '6:00'),
          attempt: attempt,
        ),
        ResultSave.saved,
      );
      expect(app.canRun(trial), isTrue);
    });

    // ---------------- KT-005 : registre des gains ----------------

    test(
      'registre : 3 crédits offerts enregistrés, notifications sans effet',
      () async {
        await app.flush();
        expect(app.creditGrants, {'level:1': 3});
        for (var i = 0; i < 5; i++) {
          app.notifyListeners();
        }
        await app.flush();
        expect(app.creditGrants, {'level:1': 3});
        expect(app.creditsEarned, 3);
      },
    );

    test('suppression puis réintroduction : aucun gain repayé', () async {
      final days = trainingDays(app).take(3).toList();
      for (final (w, d) in days) {
        session(app, w, d, '2026-08-31T18:00:00');
      }
      app.notifyListeners();
      await app.flush();
      final earned = app.creditsEarned;
      final grants = Map<String, int>.of(app.creditGrants);
      expect(grants['week:2026-08-31'], 1);
      expect(grants.keys, contains('level:2'));
      for (final (w, d) in days) {
        app.deleteLog(app.sessionKey(w, d));
      }
      await app.flush();
      expect(app.level, 1);
      expect(app.creditsEarned, earned);
      for (final (w, d) in days) {
        session(app, w, d, '2026-08-31T18:00:00');
      }
      app.notifyListeners();
      await app.flush();
      expect(app.creditsEarned, earned);
      expect(app.creditGrants, grants);
    });

    test('nouvelle semaine réelle après une suppression : +1 payé', () async {
      final days = trainingDays(app).toList();
      for (final (w, d) in days.take(3)) {
        session(app, w, d, '2026-08-31T18:00:00');
      }
      app.notifyListeners();
      await app.flush();
      final earned = app.creditsEarned;
      for (final (w, d) in days.take(3)) {
        app.deleteLog(app.sessionKey(w, d));
      }
      await app.flush();
      // Trois nouvelles séances, une autre semaine, toujours sous le total.
      for (final (w, d) in days.skip(3).take(3)) {
        session(app, w, d, '2026-09-07T18:00:00');
      }
      app.notifyListeners();
      await app.flush();
      expect(app.creditGrants['week:2026-09-07'], 1);
      expect(app.creditsEarned, earned + 1);
    });

    test(
      'palier baissé puis atteint de nouveau : payé une seule fois',
      () async {
        final days = trainingDays(app).take(6).toList();
        for (final (w, d) in days) {
          session(
            app,
            w,
            d,
            '2026-08-${10 + days.indexOf((w, d)) * 7}T18:00:00',
          );
        }
        app.notifyListeners();
        await app.flush();
        final level = app.level;
        expect(level, greaterThanOrEqualTo(3));
        final earned = app.creditsEarned;
        for (final (w, d) in days) {
          app.deleteLog(app.sessionKey(w, d));
        }
        await app.flush();
        expect(app.level, 1);
        for (final (w, d) in days) {
          session(
            app,
            w,
            d,
            '2026-08-${10 + days.indexOf((w, d)) * 7}T18:00:00',
          );
        }
        app.notifyListeners();
        await app.flush();
        expect(app.level, level);
        expect(app.creditsEarned, earned);
      },
    );

    test(
      'correction de séance : XP retirée puis rendue, crédits stables',
      () async {
        final days = trainingDays(app).take(2).toList();
        for (final (w, d) in days) {
          session(app, w, d, '2026-09-01T18:00:00');
        }
        app.notifyListeners();
        await app.flush();
        final credits = app.credits;
        final xp = app.xp;
        final key = app.sessionKey(days.first.$1, days.first.$2);
        expect(app.reopenSession(key), isTrue);
        await app.flush();
        expect(app.xp, lessThan(xp));
        expect(app.credits, credits);
        app.markSessionDone(days.first.$1, days.first.$2, true);
        await app.flush();
        expect(app.xp, xp);
        expect(app.credits, credits);
      },
    );

    test('import répété du même état : aucun nouveau gain', () async {
      for (final (w, d) in trainingDays(app).take(3)) {
        session(app, w, d, '2026-08-31T18:00:00');
      }
      app.notifyListeners();
      await app.flush();
      final file = app.exportForFile(appVersion: 'test');
      final earned = app.creditsEarned;
      for (var i = 0; i < 3; i++) {
        expect(await app.importBackup(file), ImportStatus.success);
        await app.flush();
        expect(app.creditsEarned, earned);
      }
    });

    test(
      'import d’un état plus ancien : remplacement, pas de fusion',
      () async {
        final older = app.exportForFile(appVersion: 'test');
        for (final (w, d) in trainingDays(app).take(3)) {
          session(app, w, d, '2026-08-31T18:00:00');
        }
        app.notifyListeners();
        await app.flush();
        expect(app.creditsEarned, greaterThan(3));
        expect(await app.importBackup(older), ImportStatus.success);
        expect(app.creditsEarned, 3);
        expect(app.creditGrants, {'level:1': 3});
      },
    );

    test(
      'migration L2 : surplus conservé, répétable sans nouveau gain',
      () async {
        final data = backupOf(app)
          ..remove('creditGrants')
          ..['creditsEarnedMax'] = 17;
        for (var i = 0; i < 2; i++) {
          expect(
            await app.importBackup(jsonEncode(data)),
            ImportStatus.success,
          );
          expect(app.creditGrants, {'level:1': 3, 'carry:l2': 14});
          expect(app.creditsEarned, 17);
        }
        final old = backupOf(app)
          ..remove('creditGrants')
          ..remove('creditsEarnedMax');
        expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
        expect(app.creditGrants, {'level:1': 3});
      },
    );

    test('ancien format 2 : registre reconstruit depuis son journal', () async {
      final data = formatV2(app, {});
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.creditGrants.keys, contains('level:1'));
      expect(app.creditsEarned, app.creditsFromJournal);
    });

    test(
      'état incohérent : déficit visible, droits gardés, achat bloqué',
      () async {
        final paid = purchases(app); // 3 + 2 = 5 crédits dépensés
        final data = backupOf(app)..['unlocked'] = paid;
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.creditsEarned, 3);
        expect(app.creditsSpent, 5);
        expect(app.credits, -2);
        expect(creditDeficitLabel(app.credits), 'déficit de 2 crédits');
        for (final id in paid.keys) {
          expect(app.unlocked(app.wods.firstWhere((w) => w.id == id)), isTrue);
        }
        final cheap = app.wods.firstWhere(
          (w) => app.isCatalog(w) && !app.unlocked(w) && app.wodCost(w) == 1,
        );
        expect(
          (await app.purchaseWod(cheap)).status,
          PurchaseStatus.insufficientCredits,
        );
      },
    );

    test('suppression locale : registre et sélections non restaurés', () async {
      for (final (w, d) in trainingDays(app).take(3)) {
        session(app, w, d, '2026-08-31T18:00:00');
      }
      app.notifyListeners();
      app.trialWod;
      await app.flush();
      expect(app.creditGrants.length, greaterThan(1));
      expect((await app.eraseAllData()).status, EraseStatus.success);
      expect(app.creditGrants, {'level:1': 3});
      final next = await relaunch(at(2026, 9, 24, 12));
      expect(next.creditGrants, {'level:1': 3});
      expect(next.credits, 3);
      expect(business(next)['creditGrants'], {'level:1': 3});
    });
  });

  group('Écran WOD : tentative à cheval sur minuit', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false;
    });
    tearDown(() {
      store.storeClock = DateTime.now;
      store.debugWriteHook = null;
    });

    Widget page(Widget child) => MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    testWidgets('écran reconstruit après minuit, score enregistré une fois', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      store.storeClock = at(2030, 3, 14, 23, 59);
      final trial = store.trialWod!;
      await tester.pumpWidget(page(WodRunScreen(wodId: trial.id)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Démarrer'));
      await tester.pump(const Duration(seconds: 2));
      store.storeClock = at(2030, 3, 15, 0, 1);
      expect(store.isTrial(trial), isFalse);
      store.notifyListeners();
      await tester.pump();
      expect(find.byType(WodPreviewScreen), findsNothing);
      await tester.ensureVisible(find.text('Terminer'));
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      // Feuille de score L3b : champs selon le format de l'essai du jour.
      await fillScoreSheet(tester);
      final save = find.text('Enregistrer');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(save, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(trial.results, hasLength(1));
      expect(trial.results.single.attempt, isNotNull);
      store.consumeReward();
      store.consumeLevelUp();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      // Tentative fermée : nouvelle ouverture après minuit = fiche d'achat.
      await tester.pumpWidget(page(WodRunScreen(wodId: trial.id)));
      await tester.pumpAndSettle();
      expect(find.byType(WodPreviewScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
