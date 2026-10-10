// L2b — Contrôle des données : export par fichier, import avec aperçu et
// confirmation, suppression locale. Sélecteur de fichiers SIMULÉ
// (FakeBackupFiles) et stockage simulé : ces tests ne prouvent ni l'accès
// natif aux fichiers, ni un redémarrage réel, ni la restauration Android.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/backup_files.dart';
import 'package:streetlift_tracker/data_control.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _key = 'kalis_state_v3';

String _decode(String stored) => stored.startsWith('gz:')
    ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
    : stored;

/// Contenu métier d'une sauvegarde : sans les métadonnées datées du fichier.
Map<String, dynamic> business(String json) {
  final m = jsonDecode(json) as Map<String, dynamic>;
  m.remove('exportedAt');
  m.remove('appVersion');
  return m;
}

class FakeBackupFiles implements BackupFiles {
  final files = <String, Uint8List>{};
  FileSaveResult Function(String name, Uint8List bytes)? onSave;
  Future<FileOpenResult> Function(int maxBytes)? onOpen;
  int saves = 0;

  @override
  Future<FileSaveResult> save(String name, Uint8List bytes) async {
    saves++;
    final result =
        onSave?.call(name, bytes) ??
        FileSaveResult(FileSaveStatus.saved, name: name, bytes: bytes.length);
    if (result.status == FileSaveStatus.saved) files[name] = bytes;
    return result;
  }

  @override
  Future<FileOpenResult> open(int maxBytes) => onOpen!(maxBytes);

  void serve(String text) {
    onOpen = (_) async => FileOpenResult(
      FileOpenStatus.opened,
      bytes: Uint8List.fromList(utf8.encode(text)),
      name: 'sauvegarde-test.json',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Store L2b (instances isolées)', () {
    late AppStore app;
    final others = <AppStore>[];
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() async {
      app.debugWriteHook = null;
      app.debugRemoveHook = null;
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

    Completer<bool> holdWrites(AppStore target) {
      final gate = Completer<bool>();
      target.debugWriteHook = (encoded) async {
        final ok = await gate.future;
        if (ok) {
          await (await SharedPreferences.getInstance()).setString(
            _key,
            encoded,
          );
        }
        return ok;
      };
      return gate;
    }

    /// Utilisateur venu de 6.0.x : WOD, séances perso, droits anciens et
    /// envies du fichier ignorés depuis G2.
    Future<void> seed(AppStore a) async {
      final data = filledLegacyBackup(a);
      data['legacyGrants'] = {'seed9': 'credits_v1'};
      data['wishlist'] = ['seed1'];
      expect(await a.importBackup(jsonEncode(data)), ImportStatus.success);
    }

    test(
      'export fichier : format 3 daté, réimporté dans un état distinct',
      () async {
        await seed(app);
        final at = DateTime(2026, 9, 25, 20, 36);
        final file = app.exportForFile(appVersion: '2.5.3', at: at);
        final meta = jsonDecode(file) as Map<String, dynamic>;
        expect(meta['format'], 3);
        expect(meta['exportedAt'], at.toIso8601String());
        expect(meta['appVersion'], '2.5.3');
        final source = business(app.exportAll());
        // État de test distinct : autre stockage simulé, autre instance.
        SharedPreferences.setMockInitialValues({});
        final other = await relaunch();
        final checked = other.previewImport(file);
        expect(checked.status, ImportStatus.success);
        final preview = checked.preview!;
        expect(preview.format, 3);
        expect(preview.exportedAt, at);
        expect(preview.appVersion, '2.5.3');
        expect(
          preview.sessionsDone,
          app.logs.values.where((l) => l.done).length,
        );
        // G2 : l'export ne contient plus aucune donnée retirée.
        expect(preview.ignored.hasUserData, isFalse);
        expect(preview.level, app.level);
        expect(await other.applyImport(preview), ImportStatus.success);
        expect(business(other.exportAll()), source);
        final again = await relaunch();
        expect(business(again.exportAll()), source);
      },
    );

    test('aperçu : aucune modification, date absente non inventée', () async {
      await app.flush();
      final before = app.exportAll();
      final stored = await disk();
      final revision = app.dataRevision;
      final old = formatV2();
      final checked = app.previewImport(jsonEncode(old));
      expect(checked.preview!.format, 2);
      expect(checked.preview!.exportedAt, isNull);
      expect(checked.preview!.appVersion, isNull);
      expect(app.exportAll(), before);
      expect(await disk(), stored);
      expect(app.dataRevision, revision);
      expect(app.recoveryCopies, isEmpty);
    });

    test('formats historiques et sauvegarde L2 acceptés', () async {
      for (final data in [
        formatV1(),
        formatV2(),
        // Sauvegarde L2 : plus haut de crédits, ignoré depuis G2.
        backupOf(app)..['creditsEarnedMax'] = 9,
      ]) {
        final preview = app.previewImport(jsonEncode(data)).preview!;
        expect(await app.applyImport(preview), ImportStatus.success);
      }
      expect(backupOf(app).containsKey('creditsEarnedMax'), isFalse);
      final compact = gzText(app.exportAll());
      expect(app.previewImport(compact).preview, isNotNull);
    });

    test('fichiers invalides, tronqués, trop gros ou format inconnu', () async {
      final before = app.exportAll();
      final valid = gzip.encode(utf8.encode(before));
      final cases = {
        '{"kalisTrack":1,': ImportStatus.invalid,
        'gz:${base64Encode(valid.sublist(0, valid.length ~/ 2))}':
            ImportStatus.invalid,
        jsonEncode(backupOf(app)..['format'] = 999): ImportStatus.invalid,
        jsonEncode({'autre': 'application'}): ImportStatus.invalid,
        'x' * (ImportLimits.standard.maxInputChars + 1): ImportStatus.tooLarge,
      };
      for (final entry in cases.entries) {
        expect(app.previewImport(entry.key).status, entry.value);
      }
      expect(app.exportAll(), before);
    });

    test(
      'données modifiées pendant l’aperçu : conflit sans mutation',
      () async {
        final data = backupOf(app)..['pilotage'] = {'B4': 91};
        final preview = app.previewImport(jsonEncode(data)).preview!;
        app.addUserExercise('Planche lestée', 'Épaules', 'Lest');
        final changed = app.exportAll();
        expect(await app.applyImport(preview), ImportStatus.conflict);
        expect(app.exportAll(), changed);
        final fresh = app.previewImport(jsonEncode(data)).preview!;
        expect(await app.applyImport(fresh), ImportStatus.success);
        expect(app.values['B4'], 91);
      },
    );

    test('un simple enregistrement ne crée pas de conflit', () async {
      final data = backupOf(app)..['pilotage'] = {'B4': 92};
      final preview = app.previewImport(jsonEncode(data)).preview!;
      await app.flush(); // passage en arrière-plan pendant le sélecteur
      expect(await app.applyImport(preview), ImportStatus.success);
    });

    test('import avec une écriture en attente : disque = mémoire', () async {
      final data = backupOf(app)..['pilotage'] = {'B4': 93};
      final preview = app.previewImport(jsonEncode(data)).preview!;
      final gate = holdWrites(app);
      final importing = app.applyImport(preview);
      gate.complete(true);
      expect(await importing, ImportStatus.success);
      await app.flush();
      expect(_decode((await disk())!), app.exportAll());
    });

    test('restauration : ni cérémonie, ni bilan', () async {
      for (final week in app.program.weeks) {
        for (final day in week.days) {
          if (app.level >= 2) break;
          if (day.exercises.isEmpty) continue;
          app.markSessionDone(week.n, day.j, true);
        }
      }
      app.consumeLevelUp();
      app.consumeReward();
      final file = app.exportForFile(appVersion: 'test');
      final level = app.level;
      expect((await app.eraseAllData()).status, EraseStatus.success);
      expect(app.level, 1);
      final preview = app.previewImport(file).preview!;
      expect(await app.applyImport(preview), ImportStatus.success);
      expect(app.level, level);
      expect(app.consumeLevelUp(), isNull);
      expect(app.consumeReward(), isNull);
    });

    test('suppression : tout est retiré, aucune résurrection', () async {
      await seed(app);
      final data = backupOf(app)..['pilotage'] = {'B4': 70};
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      expect(app.recoveryCopies, isNotEmpty);
      final prefs = await SharedPreferences.getInstance();
      // Anciennes clés de migration encore présentes.
      await prefs.setString(
        'logs_v1',
        jsonEncode({'S9-J1': SessionLog(done: true).toJson()}),
      );
      await prefs.setString('unlocked_wods_v1', jsonEncode({'seed1': 1}));
      await prefs.setInt('credits_v', 1);
      final result = await app.eraseAllData();
      expect(result.status, EraseStatus.success);
      expect(app.storedKeys, {_key});
      expect(app.logs, isEmpty);
      expect(app.level, 1);
      expect(app.recoveryCopies, isEmpty);
      final next = await relaunch();
      expect(next.logs, isEmpty);
      expect(next.isDone(9, 1), isFalse);
      // L4 (KT-006/007) : l'état d'installation n'a ni départ ni références ;
      // les valeurs embarquées ne sont plus présentées comme les siennes.
      expect(next.values, isEmpty);
      expect(next.program.scheduled, isFalse);
      expect(next.settings.toJson(), AppSettings().toJson());
      expect(next.storedKeys, {_key});
    });

    test(
      'suppression avec écriture en attente : l’ancien état n’est pas réécrit',
      () async {
        await seed(app);
        final gate = holdWrites(app);
        app.markSessionDone(8, 1, true); // écriture bloquée
        app.saveLogs(); // minuterie de sauvegarde différée
        final erasing = app.eraseAllData();
        gate.complete(true);
        expect((await erasing).status, EraseStatus.success);
        app.debugWriteHook = null;
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await app.flush();
        final saved = jsonDecode(_decode((await disk())!)) as Map;
        expect(saved['logs'], isEmpty);
        final next = await relaunch();
        expect(next.logs, isEmpty);
      },
    );

    test('suppression partielle signalée, puis reprise complète', () async {
      await seed(app);
      final data = backupOf(app)..['pilotage'] = {'B4': 71};
      expect(await app.importBackup(jsonEncode(data)), ImportStatus.success);
      app.debugRemoveHook = (key) async => key == 'kalis_recovery_v1'
          ? false
          : (await SharedPreferences.getInstance()).remove(key);
      final partial = await app.eraseAllData();
      expect(partial.status, EraseStatus.partial);
      expect(partial.remaining, ['kalis_recovery_v1']);
      expect(app.logs, isEmpty);
      app.debugRemoveHook = null;
      final done = await app.eraseAllData();
      expect(done.status, EraseStatus.success);
      expect(app.storedKeys, {_key});
    });

    test('suppression refusée à l’écriture : données intactes', () async {
      await seed(app);
      final before = app.exportAll();
      final stored = await disk();
      app.debugWriteHook = (_) async => false;
      expect((await app.eraseAllData()).status, EraseStatus.failed);
      expect(app.exportAll(), before);
      expect(await disk(), stored);
    });

    test('nom de fichier daté, sans donnée personnelle', () {
      final name = backupFileName(DateTime(2026, 9, 5, 7, 4));
      expect(name, 'kalis-track-sauvegarde-2026-09-05-0704.json');
      expect(
        RegExp(
          r'^kalis-track-sauvegarde-\d{4}-\d{2}-\d{2}-\d{4}\.json$',
        ).hasMatch(name),
        isTrue,
      );
    });
  });

  group('Parcours à l’écran', () {
    late FakeBackupFiles files;
    late String seedFile;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false;
      rescheduleReminders = () async {};
      final data = filledBackup(store);
      seedFile = jsonEncode(data);
    });

    setUp(() async {
      files = FakeBackupFiles();
      backupFiles = files;
      store.debugWriteHook = null;
      await store.eraseAllData();
      expect(await store.importBackup(seedFile), ImportStatus.success);
    });

    Widget page(Widget child, {bool dark = true, double scale = 1}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: inner!,
          ),
          home: child,
        );

    /// Bouton de test qui lance un parcours avec un vrai BuildContext.
    Widget launcher(Future<void> Function(BuildContext) run) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => run(context),
            child: const Text('Lancer'),
          ),
        ),
      ),
    );

    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> start(
      WidgetTester tester,
      Future<void> Function(BuildContext) run, {
      bool dark = true,
      double scale = 1,
    }) async {
      phone(tester);
      await tester.pumpWidget(page(launcher(run), dark: dark, scale: scale));
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
    }

    Future<void> end(WidgetTester tester) async {
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }

    // UI4 : aperçu et suppression sont des sous-pages à liste paresseuse :
    // la cible est atteinte par défilement (elle n'est pas encore construite).
    Future<void> tapVisible(WidgetTester tester, Finder target) async {
      await scrollToAction(tester, target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    testWidgets('export réussi : fichier daté, contenu métier identique', (
      tester,
    ) async {
      await start(tester, (c) => exportBackupFile(c, appVersion: 'test'));
      expect(files.files, hasLength(1));
      final name = files.files.keys.single;
      expect(name, startsWith('kalis-track-sauvegarde-'));
      final json = utf8.decode(files.files[name]!);
      expect(business(json), business(store.exportAll()));
      expect(find.textContaining('Sauvegarde enregistrée'), findsOneWidget);
      expect(find.textContaining('non chiffré'), findsOneWidget);
      await end(tester);
    });

    for (final (result, text) in [
      (const FileSaveResult(FileSaveStatus.cancelled), 'Export annulé'),
      (
        const FileSaveResult(
          FileSaveStatus.failed,
          error: 'denied',
          deleted: true,
        ),
        'accès refusé',
      ),
      (
        const FileSaveResult(FileSaveStatus.failed, error: 'unavailable'),
        'indisponible',
      ),
      (const FileSaveResult(FileSaveStatus.unverified), 'non relu'),
    ]) {
      testWidgets('export ${result.status.name} : $text', (tester) async {
        files.onSave = (_, __) => result;
        final before = store.exportAll();
        await start(tester, (c) => exportBackupFile(c, appVersion: 'test'));
        expect(find.textContaining(text), findsOneWidget);
        expect(find.textContaining('Sauvegarde enregistrée'), findsNothing);
        expect(store.exportAll(), before);
        await end(tester);
      });
    }

    for (final (open, text) in [
      (const FileOpenResult(FileOpenStatus.cancelled), 'Import annulé'),
      (const FileOpenResult(FileOpenStatus.tooLarge), 'trop volumineux'),
      (
        const FileOpenResult(FileOpenStatus.failed, error: 'denied'),
        'Lecture impossible',
      ),
      (
        FileOpenResult(
          FileOpenStatus.opened,
          bytes: Uint8List.fromList([0xff, 0xfe, 0x00]),
        ),
        'pas une sauvegarde',
      ),
    ]) {
      testWidgets('import ${open.status.name} : aucune mutation', (
        tester,
      ) async {
        files.onOpen = (_) async => open;
        final before = store.exportAll();
        await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
        expect(find.textContaining(text), findsOneWidget);
        expect(find.byType(ImportPreviewDialog), findsNothing);
        expect(store.exportAll(), before);
        await end(tester);
      });
    }

    testWidgets('fichier non Kalis Track : refusé sans aperçu', (tester) async {
      files.serve(jsonEncode({'kalisTrack': 1, 'format': 999}));
      final before = store.exportAll();
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      expect(find.textContaining('pas une sauvegarde'), findsOneWidget);
      expect(store.exportAll(), before);
      await end(tester);
    });

    testWidgets('aperçu annulé puis bouton retour : aucune mutation', (
      tester,
    ) async {
      final other = backupOf(store)..['pilotage'] = {'B4': 66};
      files.serve(jsonEncode(other));
      final before = store.exportAll();
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      expect(find.byType(ImportPreviewDialog), findsOneWidget);
      await tapVisible(tester, find.text('Annuler'));
      expect(find.textContaining('Import annulé'), findsOneWidget);
      expect(store.exportAll(), before);
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      expect(find.byType(ImportPreviewDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ImportPreviewDialog), findsNothing);
      expect(store.exportAll(), before);
      await end(tester);
    });

    testWidgets('sauvegarde préalable échouée : import non effectué', (
      tester,
    ) async {
      final other = backupOf(store)..['pilotage'] = {'B4': 67};
      files.serve(jsonEncode(other));
      files.onSave = (_, __) => const FileSaveResult(FileSaveStatus.cancelled);
      final before = store.exportAll();
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      expect(find.text('Sauvegarder puis remplacer'), findsOneWidget);
      await tapVisible(tester, find.text('Sauvegarder puis remplacer'));
      expect(find.textContaining('Import non effectué'), findsOneWidget);
      expect(store.exportAll(), before);
      await end(tester);
    });

    testWidgets('sauvegarde préalable puis remplacement confirmé', (
      tester,
    ) async {
      final other = backupOf(store)..['pilotage'] = {'B4': 68};
      files.serve(jsonEncode(other));
      final before = business(store.exportAll());
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      await tapVisible(tester, find.text('Sauvegarder puis remplacer'));
      expect(files.files, hasLength(1));
      expect(business(utf8.decode(files.files.values.single)), before);
      expect(store.values['B4'], 68);
      expect(find.textContaining('Import réussi'), findsOneWidget);
      await end(tester);
    });

    testWidgets('remplacement sans sauvegarde : choix explicite', (
      tester,
    ) async {
      final other = backupOf(store)..['pilotage'] = {'B4': 69};
      files.serve(jsonEncode(other));
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      await tapVisible(
        tester,
        find.text(
          'Sauvegarder d’abord mes données actuelles dans un fichier (recommandé)',
        ),
      );
      expect(find.text('Remplacer sans sauvegarde'), findsOneWidget);
      await tapVisible(tester, find.text('Remplacer sans sauvegarde'));
      expect(files.saves, 0);
      expect(store.values['B4'], 69);
      await end(tester);
    });

    testWidgets('données modifiées pendant l’aperçu : reconfirmation', (
      tester,
    ) async {
      final other = backupOf(store)..['pilotage'] = {'B4': 64};
      files.serve(jsonEncode(other));
      await start(tester, (c) => importBackupFile(c, appVersion: 'test'));
      expect(find.byType(ImportPreviewDialog), findsOneWidget);
      store.addUserExercise('Planche lestée', 'Épaules', 'Lest');
      await tapVisible(
        tester,
        find.text(
          'Sauvegarder d’abord mes données actuelles dans un fichier (recommandé)',
        ),
      );
      await tapVisible(tester, find.text('Remplacer sans sauvegarde'));
      expect(find.text('Tes données ont changé'), findsOneWidget);
      expect(store.values['B4'], isNot(64));
      await tapVisible(tester, find.text('Revoir l’aperçu'));
      expect(find.byType(ImportPreviewDialog), findsOneWidget);
      await tapVisible(
        tester,
        find.text(
          'Sauvegarder d’abord mes données actuelles dans un fichier (recommandé)',
        ),
      );
      await tapVisible(tester, find.text('Remplacer sans sauvegarde'));
      expect(store.values['B4'], 64);
      await end(tester);
    });

    testWidgets('suppression : annulation, confirmation tapée, effacement', (
      tester,
    ) async {
      final before = store.exportAll();
      await start(tester, (c) => eraseAppData(c, appVersion: 'test'));
      expect(find.byType(EraseDataDialog), findsOneWidget);
      await tapVisible(tester, find.text('Annuler'));
      expect(find.textContaining('Suppression annulée'), findsOneWidget);
      expect(store.exportAll(), before);
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();
      final erase = find.widgetWithText(FilledButton, 'Supprimer');
      await scrollToAction(tester, find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'supprime');
      await tester.pump();
      expect(tester.widget<FilledButton>(erase).onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.pump();
      await tapVisible(tester, erase);
      // Export préalable coché par défaut, puis suppression.
      expect(files.files, hasLength(1));
      expect(store.logs, isEmpty);
      expect(store.storedKeys, {_key});
      expect(
        find.textContaining('revenue à son état d’installation'),
        findsOneWidget,
      );
      await end(tester);
    });

    testWidgets('suppression : export préalable annulé, rien supprimé', (
      tester,
    ) async {
      files.onSave = (_, __) => const FileSaveResult(FileSaveStatus.cancelled);
      final before = store.exportAll();
      await start(tester, (c) => eraseAppData(c, appVersion: 'test'));
      await scrollToAction(tester, find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'SUPPRIMER');
      await tester.pump();
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Supprimer'));
      expect(find.textContaining('Suppression non effectuée'), findsOneWidget);
      expect(store.exportAll(), before);
      await end(tester);
    });

    for (final dark in [true, false]) {
      testWidgets('dialogues à 320 px, texte 200 %, thème sombre $dark', (
        tester,
      ) async {
        final other = backupOf(store)..['pilotage'] = {'B4': 63};
        files.serve(jsonEncode(other));
        await start(
          tester,
          (c) => importBackupFile(c, appVersion: 'test'),
          dark: dark,
          scale: 2,
        );
        expect(find.byType(ImportPreviewDialog), findsOneWidget);
        await tester.ensureVisible(find.text('Sauvegarder puis remplacer'));
        await tester.pumpAndSettle();
        expect(
          find.text('Sauvegarder puis remplacer').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          page(
            launcher((c) => eraseAppData(c, appVersion: 'test')),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.tap(find.text('Lancer'));
        await tester.pumpAndSettle();
        expect(find.byType(EraseDataDialog), findsOneWidget);
        await scrollToAction(tester, find.byType(TextField));
        await tester.pumpAndSettle();
        expect(find.byType(TextField).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(EraseDataDialog), findsNothing);
        await end(tester);
      });
    }

    testWidgets('Réglages : actions présentes, zone sensible séparée', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        page(const SettingsScreen(page: SettingsPage.data), scale: 1.3),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Exporter une sauvegarde',
        'Importer une sauvegarde',
        'Copier la sauvegarde',
        'Coller une sauvegarde',
        'Sauvegarde Android',
        // UI0 (refonte UI, C6) : titres de section sans capitales.
        'Zone sensible',
        'Supprimer les données de l’application',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
