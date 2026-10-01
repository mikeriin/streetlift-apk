// L2 — Sauvegarde : KT-013, KT-015, formats historiques. G2 : achats
// (KT-002), droits WOD (KT-014) et crédits (KT-005) retirés avec les WOD.
// Stockage simulé (SharedPreferences en mémoire) ; les erreurs d'écriture
// sont injectées par `debugWriteHook`. « Relance » = nouvelle instance qui
// relit ce stockage simulé : ce n'est ni un arrêt brutal ni un appareil réel.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _key = 'kalis_state_v3';

String _decode(String stored) => stored.startsWith('gz:')
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
        // Édition pendant l'import.
        app.addUserExercise('Planche lestée', 'Épaules', 'Lest');
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

    test(
      'deux modifications pendant une sauvegarde : les deux sont écrites',
      () async {
        final gate = holdWrites(app);
        app.addUserExercise('Planche lestée', 'Épaules', 'Lest');
        app.markSessionDone(8, 1, true);
        gate.complete(true);
        await app.flush();
        expect(app.hasUnsavedChanges, isFalse);
        final next = await relaunch();
        expect(next.isDone(8, 1), isTrue);
        expect(
          next.userExercises.map((e) => e['n']),
          contains('Planche lestée'),
        );
      },
    );

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

  group('Formats historiques (G2 : WOD et séances perso ignorés)', () {
    test('import format 2 : importable, WOD et droits ignorés', () async {
      final data = formatV2();
      final preview = app.previewImport(jsonEncode(data)).preview!;
      expect(preview.ignored.wodResults, 1);
      expect(preview.ignored.hasUserData, isTrue);
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.values['B4'], 78);
      expect(app.isDone(8, 1), isTrue);
      final saved = backupOf(app);
      expect(saved.containsKey('wods'), isFalse);
      expect(saved.containsKey('unlocked'), isFalse);
    });

    test('format 1 importable', () async {
      expect(
        await app.importBackup(jsonEncode(formatV1())),
        ImportStatus.success,
      );
      expect(app.values['B4'], 77);
      expect(app.isDone(9, 2), isTrue);
    });

    test('utilisateur neuf : export réimporté à l’identique', () async {
      final before = app.exportAll();
      expect(await app.importBackup(before), ImportStatus.success);
      expect(app.exportAll(), before);
    });

    test(
      'sauvegarde 6.0.x : historique du programme et XP conservés',
      () async {
        final legacy = filledLegacyBackup(app);
        final current = filledBackup(app);
        expect(
          await app.importBackup(jsonEncode(current)),
          ImportStatus.success,
        );
        final xp = app.xp;
        final logs = app.logs.length;
        expect(
          await app.importBackup(jsonEncode(legacy)),
          ImportStatus.success,
        );
        // Séances perso (S0-…, archives comprises) ignorées ; aucune
        // section retirée réécrite.
        expect(app.logs.keys.where((k) => k.startsWith('S0-')), isEmpty);
        expect(app.logs.length, logs);
        expect(app.xp, xp);
        final saved = backupOf(app);
        for (final k in ['custom', 'catalog', 'unlocked']) {
          expect(saved.containsKey(k), isFalse, reason: k);
        }
        final next = await relaunch();
        expect(next.xp, xp);
        expect(next.logs.length, logs);
      },
    );
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
      // Sauvegarde 6.0.x : la plus volumineuse encore importable.
      final json = jsonEncode(filledLegacyBackup(app));
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
      // L4 : références saisies (état neuf = aucune référence), pour un
      // export de taille comparable à celui d'avant L4.
      for (final ref in app.referenceRefs) {
        app.setValue(ref, 1);
      }
      await app.flush();
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
      // Résultats de WOD et séances perso : sections ignorées depuis G2,
      // mais encore bornées avant toute lecture.
      final raw = jsonEncode(filledLegacyBackup(app));
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
}
