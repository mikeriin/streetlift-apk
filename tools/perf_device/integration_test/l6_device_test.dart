// L6 (KT-023) — Mesure DANS L'APPLICATION sur émulateur ou téléphone, en
// mode profile (code compilé AOT), avec `integration_test`.
//
// Ce fichier n'est pas compilé avec l'application : `tools/perf_device/
// run_device_bench.sh` copie le projet dans un dossier temporaire, y ajoute
// les dépendances de test `integration_test` et `flutter_driver` (fournies
// par le SDK Flutter), puis construit un APK profile dont ce test est le
// point d'entrée (mode « apk », résultats lus dans logcat) ou lance
// `flutter drive --profile` (mode « drive », téléphone physique). Le projet
// livré, son pubspec et son pubspec.lock ne sont pas modifiés.
//
// Données : profils synthétiques de test/support/perf_fixtures.dart, dans un
// stockage en mémoire (SharedPreferences simulé) : l'installation réelle
// n'est jamais lue ni modifiée. Durées : chronomètre Dart (Stopwatch) et
// minutages d'images du moteur (FrameTiming : construction et rastérisation).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import '../test/support/perf_fixtures.dart';

const _label = String.fromEnvironment('KALIS_PERF_LABEL', defaultValue: '?');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final report = <String, Object?>{'label': _label};
  final stopwatch = <String, List<double>>{};

  double ms(Stopwatch sw) => sw.elapsedMicroseconds / 1000.0;

  testWidgets('L6 appareil : démarrage, séance, retour, catalogue', (
    tester,
  ) async {
    // Documents des profils, produits par l'application elle-même.
    SharedPreferences.setMockInitialValues({});
    final seed = AppStore();
    await seed.init();
    final exports = <String, String>{};
    final stored = <String, String>{};
    for (final profile in ['long', 'charge']) {
      final doc = perfBackup(seed, profile)!;
      SharedPreferences.setMockInitialValues({});
      final app = AppStore();
      await app.init();
      expect(await app.importAll(jsonEncode(doc)), isTrue);
      await app.flush();
      stored[profile] =
          (await SharedPreferences.getInstance()).getString(
            'kalis_state_v3',
          )!;
      exports[profile] = app.exportAll();
      app.dispose();
    }
    await seed.flush();
    seed.dispose();

    // Démarrage des données (lecture, migrations, catalogue), 5 fois.
    for (final profile in ['neuf', 'long', 'charge']) {
      final values = <double>[];
      for (var i = 0; i < 6; i++) {
        SharedPreferences.setMockInitialValues({
          if (stored[profile] != null) 'kalis_state_v3': stored[profile]!,
        });
        final app = AppStore();
        final sw = Stopwatch()..start();
        await app.init();
        sw.stop();
        await app.flush();
        app.dispose();
        if (i > 0) values.add(ms(sw));
      }
      stopwatch['store.init.$profile'] = values;
    }

    SharedPreferences.setMockInitialValues({
      'kalis_state_v3': stored['long']!,
    });
    await store.init();
    for (final profile in ['long', 'charge']) {
      expect(await store.importAll(exports[profile]!), isTrue);
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false
        ..celebrations = false;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      for (final tab in [1, 0, 3, 2]) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      for (var i = 1; i < 4; i++) {
        await tester.ensureVisible(find.byKey(ValueKey('stats-section-$i')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('stats-section-$i')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();

      // Séance par-dessus les quatre onglets visités.
      final week = store.program.weeks.last;
      final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
      final exercise = day.exercises.first;
      final keystroke = <double>[], popFirst = <double>[];
      for (var k = 0; k < 3; k++) {
        store.logs.remove(store.sessionKey(week.n, day.j));
        appNavigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => SessionScreen(week: week, day: day),
          ),
        );
        await tester.pumpAndSettle();
        final log = store.exLog(week.n, day.j, exercise);
        await binding.watchPerformance(() async {
          for (var i = 0; i < 10; i++) {
            log.sets.first.reps = '${i + 1}';
            final sw = Stopwatch()..start();
            store.saveLogs(affectsProgression: false);
            await tester.pump();
            sw.stop();
            keystroke.add(ms(sw));
          }
        }, reportKey: 'frames.keystroke.$profile.$k');
        await tester.pump(const Duration(seconds: 1));
        await store.flush();
        await binding.watchPerformance(() async {
          appNavigator.currentState!.pop();
          final sw = Stopwatch()..start();
          await tester.pump();
          sw.stop();
          popFirst.add(ms(sw));
          await tester.pumpAndSettle();
        }, reportKey: 'frames.pop.$profile.$k');
      }
      stopwatch['session.keystroke.$profile'] = keystroke;
      stopwatch['session.popFirstFrame.$profile'] = popFirst;

    }
    await store.flush();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    report['stopwatch'] = stopwatch;
    final existing = binding.reportData ?? <String, dynamic>{};
    final all = {...existing, ...report};
    binding.reportData = all;
    // Sans pilote (APK lancé directement, par ex. sur émulateur où
    // `flutter drive --profile` est refusé) : résultats écrits dans le
    // journal Android, par morceaux (une ligne logcat est limitée).
    final text = jsonEncode(all);
    const size = 700;
    final count = (text.length / size).ceil();
    for (var i = 0; i < count; i++) {
      final end = (i + 1) * size < text.length ? (i + 1) * size : text.length;
      // ignore: avoid_print
      print('KALIS_DEVICE ${i + 1}/$count ${text.substring(i * size, end)}');
    }
    // ignore: avoid_print
    print('KALIS_DEVICE_DONE $_label');
  });
}
