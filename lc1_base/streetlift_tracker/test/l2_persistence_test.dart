// L2 — Sauvegarde et achats : KT-002, KT-013, KT-014, KT-015, scénarios KT-005.
// Stockage simulé (SharedPreferences en mémoire) ; les erreurs d'écriture
// sont injectées par `debugWriteHook`. « Relance » = nouvelle instance qui
// relit ce stockage simulé : ce n'est ni un arrêt brutal ni un appareil réel.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';

import 'l2_fixtures.dart';

const _key = 'kalis_state_v3';

String _decode(String stored) =>
    stored.startsWith('gz:')
        ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
        : stored;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppStore app;
  final others = <AppStore>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore();
    await app.init();
    app.settings.sound = app.settings.vibration = false;
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

  Future<AppStore> relaunch() async {
    final next = AppStore();
    await next.init();
    others.add(next);
    return next;
  }

  Future<String?> disk() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  /// Écritures suspendues jusqu'à la décision du test.
  Completer<bool> holdWrites(AppStore target) {
    final gate = Completer<bool>();
    target.debugWriteHook = (encoded) async {
      final ok = await gate.future;
      if (ok) {
        await (await SharedPreferences.getInstance()).setString(_key, encoded);
      }
      return ok;
    };
    return gate;
  }

  Wod affordable(AppStore a, {int? cost}) => a.wods.firstWhere(
    (w) =>
        a.isCatalog(w) &&
        !a.unlocked(w) &&
        a.wodCost(w) <= a.credits &&
        (cost == null || a.wodCost(w) == cost),
  );

  group('KT-002 achats', () {
    test('achat normal au prix accepté, conservé après relance', () async {
      final w = affordable(app);
      final cost = app.wodCost(w);
      final before = app.credits;
      final result = await app.purchaseWod(w, acceptedCost: cost);
      expect(result.status, PurchaseStatus.success);
      expect(result.cost, cost);
      expect(app.unlockedWods[w.id], cost);
      expect(app.credits, before - cost);
      expect(app.hasUnsavedChanges, isFalse);
      final next = await relaunch();
      expect(next.unlockedWods[w.id], cost);
      expect(next.credits, before - cost);
    });

    test('crédits insuffisants : aucun débit, stockage inchangé', () async {
      final w = app.wods.firstWhere(
        (w) => app.isCatalog(w) && app.wodCost(w) > app.credits,
      );
      final stored = await disk();
      final before = app.credits;
      final result = await app.purchaseWod(w);
      expect(result.status, PurchaseStatus.insufficientCredits);
      expect(app.unlocked(w), isFalse);
      expect(app.credits, before);
      expect(await disk(), stored);
    });

    test('prix modifié depuis l’offre : aucun débit', () async {
      final w = affordable(app);
      final cost = app.wodCost(w);
      final result = await app.purchaseWod(w, acceptedCost: cost + 1);
      expect(result.status, PurchaseStatus.priceChanged);
      expect(result.cost, cost);
      expect(app.unlocked(w), isFalse);
    });

    test(
      'double appui : un seul débit, rien d’annoncé avant l’écriture',
      () async {
        final w = affordable(app);
        final cost = app.wodCost(w);
        final before = app.credits;
        final gate = holdWrites(app);
        final first = app.purchaseWod(w, acceptedCost: cost);
        final second = app.purchaseWod(w, acceptedCost: cost);
        expect((await second).status, PurchaseStatus.pending);
        expect(app.purchasePending(w), isTrue);
        expect(app.unlocked(w), isFalse);
        expect(app.credits, before - cost);
        gate.complete(true);
        expect((await first).status, PurchaseStatus.success);
        expect(app.purchasePending(w), isFalse);
        expect(app.unlocked(w), isTrue);
        expect(app.credits, before - cost);
        expect((await app.purchaseWod(w)).status, PurchaseStatus.alreadyOwned);
        expect(app.credits, before - cost);
      },
    );

    test(
      'deux WODs : le solde réservé empêche une dépense excessive',
      () async {
        expect(app.credits, 3);
        final pair =
            app.wods
                .where((w) => app.isCatalog(w) && app.wodCost(w) == 2)
                .take(2)
                .toList();
        final gate = holdWrites(app);
        final first = app.purchaseWod(pair[0], acceptedCost: 2);
        final second = await app.purchaseWod(pair[1], acceptedCost: 2);
        expect(second.status, PurchaseStatus.insufficientCredits);
        gate.complete(true);
        expect((await first).status, PurchaseStatus.success);
        expect(app.credits, 1);
        expect(app.unlocked(pair[1]), isFalse);
      },
    );

    test('deux WODs abordables ensemble : deux débits exacts', () async {
      final one = affordable(app, cost: 1);
      final two = app.wods.firstWhere(
        (w) => app.isCatalog(w) && w.id != one.id && app.wodCost(w) == 2,
      );
      final gate = holdWrites(app);
      final a = app.purchaseWod(one, acceptedCost: 1);
      final b = app.purchaseWod(two, acceptedCost: 2);
      expect(app.credits, 0);
      gate.complete(true);
      expect((await a).status, PurchaseStatus.success);
      expect((await b).status, PurchaseStatus.success);
      expect(app.credits, 0);
      final next = await relaunch();
      expect(next.unlockedWods, {one.id: 1, two.id: 2});
    });

    test('écriture refusée puis nouvelle tentative réussie', () async {
      final w = affordable(app);
      final cost = app.wodCost(w);
      final other = app.wods.firstWhere(
        (x) => app.isCatalog(x) && x.id != w.id && !app.wished(x),
      );
      final before = app.credits;
      final stored = await disk();
      final prefs = await SharedPreferences.getInstance();
      // Cache mis à jour puis refus natif, comme SharedPreferences.
      app.debugWriteHook = (encoded) async {
        await prefs.setString(_key, encoded);
        return false;
      };
      final buying = app.purchaseWod(w, acceptedCost: cost);
      app.toggleWish(other); // modification légitime pendant l'achat
      final failed = await buying;
      await app.flush();
      expect(failed.status, PurchaseStatus.failed);
      expect(app.unlocked(w), isFalse);
      expect(app.unlockedWods.containsKey(w.id), isFalse);
      expect(app.credits, before);
      expect(app.wished(other), isTrue);
      expect(app.hasUnsavedChanges, isTrue);
      expect(app.persistenceError.value, isNotNull);
      expect(await disk(), stored);
      app.debugWriteHook = null;
      final retried = await app.purchaseWod(w, acceptedCost: cost);
      expect(retried.status, PurchaseStatus.success);
      expect(app.persistenceError.value, isNull);
      final next = await relaunch();
      expect(next.unlockedWods[w.id], cost);
      expect(
        next.wished(next.wods.firstWhere((x) => x.id == other.id)),
        isTrue,
      );
    });

    test('un droit acquis n’est jamais retiré par un achat échoué', () async {
      final owned = affordable(app, cost: 1);
      expect((await app.purchaseWod(owned)).status, PurchaseStatus.success);
      final w = affordable(app);
      app.debugWriteHook = (_) async => false;
      expect((await app.purchaseWod(w)).status, PurchaseStatus.failed);
      expect(app.unlocked(owned), isTrue);
      expect(app.unlockedWods[owned.id], 1);
    });
  });

  group('KT-013 écritures et imports', () {
    test(
      'deux imports rapprochés : le dernier gagne, copies gardées',
      () async {
        final original = app.values['B4'];
        final a = backupOf(app)..['pilotage'] = {'B4': 81};
        final b = backupOf(app)..['pilotage'] = {'B4': 82};
        final first = app.importBackup(jsonEncode(a));
        final second = app.importBackup(jsonEncode(b));
        expect(await first, ImportStatus.success);
        expect(await second, ImportStatus.success);
        expect(app.values['B4'], 82);
        expect(_decode((await disk())!), app.exportAll());
        expect(app.recoveryCopies, hasLength(2));
        expect(jsonDecode(app.recoveryState(0)!)['pilotage']['B4'], 81);
        expect(jsonDecode(app.recoveryState(1)!)['pilotage']['B4'], original);
        final next = await relaunch();
        expect(next.values['B4'], 82);
      },
    );

    test('au plus trois copies de récupération', () async {
      for (final weight in [71, 72, 73, 74]) {
        final data = backupOf(app)..['pilotage'] = {'B4': weight};
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      }
      expect(app.recoveryCopies, hasLength(3));
      expect(jsonDecode(app.recoveryState(0)!)['pilotage']['B4'], 73);
    });

    test(
      'un état ancien n’est pas écrit après un import plus récent',
      () async {
        final base = backupOf(app)..['pilotage'] = {'B4': 91};
        final gate = holdWrites(app);
        app.markSessionDone(8, 1, true); // écriture bloquée
        final importing = app.importBackup(jsonEncode(base));
        final w = app.wods.firstWhere(app.isCatalog);
        app.toggleWish(w); // édition pendant l'import
        gate.complete(true);
        expect(await importing, ImportStatus.success);
        await app.flush();
        expect(app.values['B4'], 91);
        expect(_decode((await disk())!), app.exportAll());
        final next = await relaunch();
        expect(next.values['B4'], 91);
        expect(next.exportAll(), app.exportAll());
      },
    );

    test('import pendant un flush : ordre conservé', () async {
      final data = backupOf(app)..['pilotage'] = {'B4': 88};
      final gate = holdWrites(app);
      app.markSessionDone(8, 2, true);
      final flushing = app.flush();
      final importing = app.importBackup(jsonEncode(data));
      gate.complete(true);
      await flushing;
      expect(await importing, ImportStatus.success);
      expect(app.isDone(8, 2), isFalse);
      expect(_decode((await disk())!), app.exportAll());
    });

    test('achat pendant une sauvegarde : les deux sont écrits', () async {
      final w = affordable(app);
      final wish = app.wods.firstWhere((x) => app.isCatalog(x) && x.id != w.id);
      final gate = holdWrites(app);
      app.toggleWish(wish);
      final buying = app.purchaseWod(w, acceptedCost: app.wodCost(w));
      gate.complete(true);
      expect((await buying).status, PurchaseStatus.success);
      await app.flush();
      final next = await relaunch();
      expect(next.unlockedWods.containsKey(w.id), isTrue);
      expect(next.wishlist, contains(wish.id));
    });

    test('échec d’écriture : mémoire gardée, reprise explicite', () async {
      final stored = await disk();
      app.debugWriteHook = (_) async => false;
      app.markSessionDone(8, 1, true);
      await app.flush();
      expect(app.isDone(8, 1), isTrue);
      expect(app.hasUnsavedChanges, isTrue);
      expect(app.persistenceError.value, isNotNull);
      expect(await disk(), stored);
      // Relance sans reprise : la modification non acceptée n'existe pas.
      final lost = await relaunch();
      expect(lost.isDone(8, 1), isFalse);
      app.debugWriteHook = null;
      expect(await app.retrySave(), isTrue);
      expect(app.hasUnsavedChanges, isFalse);
      expect(app.persistenceError.value, isNull);
      final kept = await relaunch();
      expect(kept.isDone(8, 1), isTrue);
    });

    test('import refusé à l’écriture : état et stockage inchangés', () async {
      final before = app.exportAll();
      final stored = await disk();
      final data = backupOf(app)..['pilotage'] = {'B4': 90};
      app.debugWriteHook = (_) async => false;
      expect(
        await app.importBackup(jsonEncode(data)),
        ImportStatus.writeFailed,
      );
      expect(app.exportAll(), before);
      expect(await disk(), stored);
    });

    test('import dégradé : rejet complet, aucune copie ni écriture', () async {
      app.markSessionDone(8, 1, true);
      await app.flush();
      final before = app.exportAll();
      final stored = await disk();
      final data = filledBackup(app);
      final logs = data['logs'] as Map<String, dynamic>;
      final first = logs.values.first as Map<String, dynamic>;
      final ex = (first['ex'] as Map<String, dynamic>).values.first as Map;
      ((ex['sets'] as List).first as Map)['completedAt'] = 'hier';
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.invalid);
      expect(app.exportAll(), before);
      expect(await disk(), stored);
      expect(app.recoveryCopies, isEmpty);
    });

    test('liste de copies illisible : import suspendu, rien écrasé', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kalis_recovery_v1', '{cassé');
      final stored = await disk();
      final data = backupOf(app)..['pilotage'] = {'B4': 85};
      expect(
        await app.importBackup(jsonEncode(data)),
        ImportStatus.writeFailed,
      );
      expect(prefs.getString('kalis_recovery_v1'), '{cassé');
      expect(await disk(), stored);
    });
  });

  group('KT-014 droits WOD historiques', () {
    test('migration crédits v1 : coût 0 conservé à part, sans accès', () async {
      final ids = legacyIds(app);
      await app.flush();
      app.dispose();
      SharedPreferences.setMockInitialValues({
        'unlocked_wods_v1': jsonEncode({ids.free: 0, ids.paid: 1}),
        'credits_v': 1,
      });
      app = AppStore();
      await app.init();
      final before = {ids.free: 0, ids.paid: 1};
      expect(app.unlockedWods, {ids.paid: 1});
      expect(app.legacyGrants, {ids.free: 'credits_v1'});
      expect(
        {...app.unlockedWods.keys, ...app.legacyGrants.keys},
        {...before.keys},
      );
      expect(app.unlocked(app.wods.firstWhere((w) => w.id == ids.free)), false);
      expect(app.creditsSpent, 1);
      final saved = backupOf(app);
      expect(saved['legacyGrants'], {ids.free: 'credits_v1'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unlocked_wods_v1'), isNotNull);
      final next = await relaunch();
      expect(next.legacyGrants, {ids.free: 'credits_v1'});
      expect(next.unlockedWods, {ids.paid: 1});
    });

    test('migration crédits v1 : un WOD joué reste acquis à coût 0', () async {
      final ids = legacyIds(app);
      await app.flush();
      app.dispose();
      SharedPreferences.setMockInitialValues({
        'unlocked_wods_v1': jsonEncode({ids.free: 0, ids.paid: 0}),
        'wod_results_v2': jsonEncode({
          ids.paid: [
            WodResult(at: '2025-05-01T10:00:00', score: '9:30').toJson(),
          ],
        }),
        'credits_v': 1,
      });
      app = AppStore();
      await app.init();
      expect(app.unlockedWods, {ids.paid: 0});
      expect(app.legacyGrants, {ids.free: 'credits_v1'});
      expect(app.unlocked(app.wods.firstWhere((w) => w.id == ids.paid)), true);
      expect(app.creditsSpent, 0);
    });

    test('import format 2 : WOD joué acquis, non joué archivé', () async {
      final ids = legacyIds(app);
      final data = formatV2(app, {ids.free: 0, ids.paid: 0});
      for (final w in data['wods'] as List) {
        if ((w as Map)['id'] == ids.paid) {
          w['results'] = [
            WodResult(at: '2025-05-01T10:00:00', score: '9:30').toJson(),
          ];
        }
      }
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.unlockedWods, {ids.paid: 0});
      expect(app.legacyGrants, {ids.free: 'import_format_2'});
    });

    test('import format 2 : coût 0 isolé, prix payés conservés', () async {
      final ids = legacyIds(app);
      final data = formatV2(app, {ids.free: 0, ids.paid: 2});
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.unlockedWods, {ids.paid: 2});
      expect(app.legacyGrants, {ids.free: 'import_format_2'});
      expect(app.values['B4'], 78);
      expect(app.isDone(8, 1), isTrue);
    });

    test('format 3 : un droit établi à coût 0 reste acquis', () async {
      final ids = legacyIds(app);
      final data = backupOf(app)..['unlocked'] = {ids.free: 0};
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.unlockedWods, {ids.free: 0});
      expect(app.legacyGrants, isEmpty);
    });

    test('format 1 importable', () async {
      expect(
        await app.importBackup(jsonEncode(formatV1(app))),
        ImportStatus.success,
      );
      expect(app.values['B4'], 77);
      expect(app.isDone(9, 2), isTrue);
    });

    test('achats normaux et remisés : aller-retour exact', () async {
      final paid = purchases(app);
      final data = backupOf(app)..['unlocked'] = paid;
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.creditsSpent, 5);
      final copy = app.exportCompact();
      final next = await relaunch();
      expect(next.unlockedWods, paid);
      expect(await next.importBackup(copy), ImportStatus.success);
      expect(next.unlockedWods, paid);
    });

    test('droits anciens : aller-retour sans perte', () async {
      final ids = legacyIds(app);
      final data = backupOf(app)..['legacyGrants'] = {ids.free: 'credits_v1'};
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      final copy = app.exportAll();
      expect(await app.importBackup(copy), ImportStatus.success);
      expect(app.legacyGrants, {ids.free: 'credits_v1'});
    });

    test('utilisateur neuf : export réimporté à l’identique', () async {
      final before = app.exportAll();
      expect(await app.importBackup(before), ImportStatus.success);
      expect(app.exportAll(), before);
    });

    test('séances perso répétées : archives et XP conservées', () async {
      final data = filledBackup(app);
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      final xp = app.xp;
      final keys = app.logs.keys.where((k) => k.contains('@')).length;
      expect(keys, 20);
      expect(app.customSessions, hasLength(60));
      final next = await relaunch();
      expect(next.xp, xp);
      expect(next.logs.keys.where((k) => k.contains('@')).length, 20);
    });
  });

  group('KT-015 imports bornés', () {
    const tiny = ImportLimits(
      maxInputChars: 4096,
      maxJsonBytes: 64 * 1024,
      maxNodes: 50,
      maxStringChars: 10,
      maxLogs: 10,
      maxSets: 100,
      maxResults: 10,
      maxEntries: 10,
    );

    Future<void> rejected(
      String raw,
      ImportStatus expected, {
      ImportLimits limits = ImportLimits.standard,
    }) async {
      final before = app.exportAll();
      final stored = await disk();
      expect(await app.importBackup(raw, limits: limits), expected);
      expect(app.exportAll(), before);
      expect(await disk(), stored);
    }

    test('sauvegarde représentative acceptée, marges mesurées', () async {
      final json = jsonEncode(filledBackup(app));
      final compact = gzText(json);
      var nodes = 0;
      jsonDecode(
        json,
        reviver: (_, value) {
          nodes++;
          return value;
        },
      );
      // ignore: avoid_print
      print(
        'L2 représentatif : JSON ${json.length} o, compact ${compact.length} car., $nodes valeurs',
      );
      const limits = ImportLimits.standard;
      expect(json.length * 10, lessThan(limits.maxJsonBytes));
      expect(compact.length * 10, lessThan(limits.maxInputChars));
      expect(nodes * 10, lessThan(limits.maxNodes));
      expect(await app.importBackup(compact), ImportStatus.success);
      expect(await app.importBackup(json), ImportStatus.success);
      final next = await relaunch();
      expect(next.logs.length, app.logs.length);
    });

    test('texte trop long', () async {
      await rejected('x' * 5000, ImportStatus.tooLarge, limits: tiny);
    });

    test('décompression excessive arrêtée pendant le flux', () async {
      final bomb = compressibleBomb(1024 * 1024);
      expect(bomb.length, lessThan(4096));
      await rejected(bomb, ImportStatus.tooLarge, limits: tiny);
    });

    test('gzip tronqué, base64 invalide, JSON mal formé', () async {
      final valid = gzip.encode(utf8.encode(app.exportAll()));
      final truncated =
          'gz:${base64Encode(valid.sublist(0, valid.length ~/ 2))}';
      await rejected(truncated, ImportStatus.invalid);
      await rejected('gz:@@@', ImportStatus.invalid);
      await rejected('{"kalisTrack":1,', ImportStatus.invalid);
      await rejected('[]', ImportStatus.invalid);
    });

    test('structure invalide', () async {
      final data = backupOf(app)..['logs'] = [];
      await rejected(jsonEncode(data), ImportStatus.invalid);
      final other = backupOf(app)..['pilotage'] = 'lourd';
      await rejected(jsonEncode(other), ImportStatus.invalid);
    });

    test('trop de valeurs, textes trop longs', () async {
      final raw = app.exportAll();
      await rejected(
        raw,
        ImportStatus.tooLarge,
        limits: const ImportLimits(maxNodes: 50),
      );
      await rejected(
        raw,
        ImportStatus.tooLarge,
        limits: const ImportLimits(maxStringChars: 3),
      );
    });

    test('trop de séances, séries, résultats ou entrées', () async {
      final raw = jsonEncode(filledBackup(app));
      for (final limits in const [
        ImportLimits(maxLogs: 10),
        ImportLimits(maxSets: 100),
        ImportLimits(maxResults: 10),
        ImportLimits(maxEntries: 10),
      ]) {
        await rejected(raw, ImportStatus.tooLarge, limits: limits);
      }
    });

    test('limites standard documentées', () {
      const limits = ImportLimits.standard;
      expect(limits.maxInputChars, 8 * 1024 * 1024);
      expect(limits.maxJsonBytes, 32 * 1024 * 1024);
      expect(limits.maxNodes, 2000000);
      expect(limits.maxStringChars, 100000);
      expect(limits.maxLogs, 20000);
      expect(limits.maxSets, 500000);
      expect(limits.maxResults, 100000);
      expect(limits.maxEntries, 20000);
    });
  });

  group('KT-005 crédits jamais repris (option C)', () {
    /// Journées validées jusqu'au niveau 2, dans l'ordre du programme.
    List<(int, int)> reachLevel2(AppStore a) {
      final done = <(int, int)>[];
      for (final week in a.program.weeks) {
        for (final day in week.days) {
          if (a.level >= 2) return done;
          if (day.exercises.isEmpty) continue;
          a.markSessionDone(week.n, day.j, true);
          done.add((week.n, day.j));
        }
      }
      return done;
    }

    test('supprimer baisse XP et niveau, pas les crédits gagnés', () async {
      final days = reachLevel2(app);
      await app.flush();
      final earned = app.creditsEarned;
      expect(earned, greaterThan(Progression.creditsForLevel(1)));
      final w = affordable(app);
      expect((await app.purchaseWod(w)).status, PurchaseStatus.success);
      final balance = app.credits;
      for (final (week, day) in days) {
        app.deleteLog(app.sessionKey(week, day));
      }
      await app.flush();
      expect(app.level, 1);
      expect(app.creditsFromJournal, lessThan(earned));
      expect(app.creditsEarned, earned);
      expect(app.credits, balance);
      expect(app.unlocked(w), isTrue);
      final next = await relaunch();
      expect(next.level, 1);
      expect(next.credits, balance);
    });

    test('refaire une performance supprimée ne redonne rien', () async {
      final days = reachLevel2(app);
      await app.flush();
      final earned = app.creditsEarned;
      for (final (week, day) in days) {
        app.deleteLog(app.sessionKey(week, day));
      }
      await app.flush();
      reachLevel2(app);
      await app.flush();
      expect(app.creditsEarned, earned);
    });

    test('corriger une séance ne fait pas varier les crédits', () async {
      final days = reachLevel2(app);
      await app.flush();
      final credits = app.credits;
      final key = app.sessionKey(days.last.$1, days.last.$2);
      expect(app.reopenSession(key), isTrue);
      await app.flush();
      expect(app.credits, credits);
      app.markSessionDone(days.last.$1, days.last.$2, true);
      await app.flush();
      expect(app.credits, credits);
    });

    test(
      'migration : le plus haut part du journal, sans créer ni retirer',
      () async {
        final saved = backupOf(app);
        expect(saved['creditsEarnedMax'], app.creditsFromJournal);
        final old = Map<String, dynamic>.of(saved)..remove('creditsEarnedMax');
        expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
        expect(app.creditsEarned, app.creditsFromJournal);
      },
    );

    test(
      'import d’une sauvegarde L2 : son plus haut remplace le courant',
      () async {
        // Sauvegarde L2 : pas encore de registre des gains (L3).
        final data =
            backupOf(app)
              ..remove('creditGrants')
              ..['creditsEarnedMax'] = 20;
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
        expect(app.creditsEarned, 20);
        final lower =
            backupOf(app)
              ..remove('creditGrants')
              ..['creditsEarnedMax'] = 3;
        expect(await app.importBackup(jsonEncode(lower)), ImportStatus.success);
        expect(app.creditsEarned, app.creditsFromJournal);
      },
    );

    test('plus haut invalide : import refusé', () async {
      for (final bad in [-1, 'dix', 1000001]) {
        final data = backupOf(app)..['creditsEarnedMax'] = bad;
        expect(await app.importBackup(jsonEncode(data)), ImportStatus.invalid);
      }
    });
  });
}
