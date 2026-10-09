// L6 (KT-023) — Non-régression des optimisations : zones masquées à jour
// dès qu'elles redeviennent visibles. Ces tests comptent des opérations ;
// ils ne mesurent aucune durée (voir test/l6_perf_bench_test.dart pour le
// banc). G2 : les caches WOD et leurs tests ont été retirés avec les WOD.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/store_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('zones masquées (store global)', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false
        ..celebrations = false;
      store.program.start = DateTime(2026, 7, 13);
    });

    SessionLog doneLog(String title) => SessionLog(
      done: true,
      finishedAt: DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      title: title,
    );

    Finder entry(String key) =>
        find.byKey(ValueKey('stats-log-$key'), skipOffstage: false);

    testWidgets('STATS masqué : notification différée, à jour dès la '
        'première image après le retour sur l’onglet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('stats-section-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stats-section-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();

      StoreRebuildStats.reset();
      store.logs['S0-J9601'] = doneLog('Masquée L6');
      store.saveLogs(immediate: true);
      await tester.pump();
      expect(StoreRebuildStats.deferred, greaterThan(0));
      // Travail évité : l'onglet masqué n'a pas été reconstruit.
      expect(entry('S0-J9601'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pump();
      expect(entry('S0-J9601'), findsOneWidget);

      // Section visible : reconstruite aussitôt (les zones encore masquées,
      // PROGRAMME et la section Aperçu, continuent de différer).
      final rebuilt = StoreRebuildStats.rebuilds;
      store.logs['S0-J9602'] = doneLog('Visible L6');
      store.saveLogs(immediate: true);
      await tester.pump();
      expect(entry('S0-J9602'), findsOneWidget);
      expect(StoreRebuildStats.rebuilds, greaterThan(rebuilt));

      store.logs
        ..remove('S0-J9601')
        ..remove('S0-J9602');
      store.saveLogs(immediate: true);
      await tester.pumpAndSettle();
      await tester.runAsync(store.flush);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('séance par-dessus les onglets : les frappes ne '
        'reconstruisent pas les onglets masqués ; au retour, chaque onglet '
        'est à jour une fois', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      for (final tab in [1, 0, 3, 2]) {
        await tester.tap(find.byKey(ValueKey('nav-$tab')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('stats-section-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stats-section-3')));
      await tester.pumpAndSettle();

      final week = store.program.weeks[11];
      final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SessionScreen(week: week, day: day),
        ),
      );
      await tester.pumpAndSettle();
      final log = store.exLog(week.n, day.j, day.exercises.first);

      StoreRebuildStats.reset();
      for (var i = 0; i < 10; i++) {
        log.sets.first.reps = '${i + 1}';
        store.saveLogs(affectsProgression: false);
        await tester.pump();
      }
      // Quatre onglets (PROGRAMME, STATS, ARSENAL, RÉGLAGES) masqués sous
      // la séance : dix notifications différées pour chacun au moins.
      expect(StoreRebuildStats.deferred, greaterThanOrEqualTo(40));
      final rebuildsDuringSession = StoreRebuildStats.rebuilds;

      store.logs['S0-J9603'] = doneLog('Pendant la séance L6');
      store.saveLogs(immediate: true);
      await tester.pump();
      expect(entry('S0-J9603'), findsNothing);

      appNavigator.currentState!.pop();
      await tester.pump();
      // Dès la première image du retour, l'historique est à jour.
      expect(entry('S0-J9603'), findsOneWidget);
      await tester.pumpAndSettle();
      // Chaque zone masquée n'est reconstruite qu'une fois au retour (et
      // non onze fois) : l'écart reste inférieur au nombre de frappes.
      expect(
        StoreRebuildStats.rebuilds - rebuildsDuringSession,
        lessThan(StoreRebuildStats.deferred),
      );

      store.logs
        ..remove('S0-J9603')
        ..remove(store.sessionKey(week.n, day.j));
      store.saveLogs(immediate: true);
      await tester.pumpAndSettle();
      await tester.runAsync(store.flush);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
