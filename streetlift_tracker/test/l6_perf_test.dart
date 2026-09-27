// L6 (KT-023) — Non-régression des optimisations : équivalence des
// résultats et invalidation des caches après chaque mutation pertinente,
// zones masquées à jour dès qu'elles redeviennent visibles. Ces tests
// comptent des opérations ou vérifient des égalités ; ils ne mesurent
// aucune durée (voir test/l6_perf_bench_test.dart pour le banc).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/store_widget.dart';
import 'package:streetlift_tracker/training_estimate.dart';
import 'package:streetlift_tracker/wod_models.dart';

Map<String, dynamic> _catalogOf(AppStore app) =>
    (jsonDecode(app.exportAll()) as Map<String, dynamic>)['catalog']
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('caches WOD (store isolé)', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('export : une modification d’un WOD du catalogue, même à nombre de '
        'lignes constant, devient une modification ; son retour à '
        'l’identique la retire', () async {
      expect(_catalogOf(app)['edits'], isEmpty);
      final w = app.wods.firstWhere(app.isCatalog);
      final name = w.name, line = w.lines.first, interval = w.interval;

      w.name = '$name (L6)';
      expect((_catalogOf(app)['edits'] as Map).keys, [w.id]);
      w.name = name;
      expect(_catalogOf(app)['edits'], isEmpty);

      w.lines[0] = '$line x';
      expect(
        ((_catalogOf(app)['edits'] as Map)[w.id] as Map)['lines'],
        w.lines,
      );
      w.lines[0] = line;
      expect(_catalogOf(app)['edits'], isEmpty);

      w.interval = interval + 1;
      expect((_catalogOf(app)['edits'] as Map).keys, [w.id]);
      w.interval = interval;
      expect(_catalogOf(app)['edits'], isEmpty);

      // Le niveau et les résultats ne font pas partie de la définition.
      w.level = w.level == 10 ? 1 : w.level + 1;
      w.results.add(WodResult(at: '2026-09-01T10:00:00', score: '10:00'));
      expect(_catalogOf(app)['edits'], isEmpty);
    });

    test('estimation WOD : réutilisée tant que rien ne change, recalculée '
        'après chaque mutation de la prescription ou des résultats', () {
      final w = app.wods.firstWhere(
        (w) => app.isCatalog(w) && w.type == 'fortime',
      );
      final first = app.wodEstimate(w);
      expect(identical(app.wodEstimate(w), first), isTrue);

      TrainingEstimate changed(void Function() mutate) {
        final before = app.wodEstimate(w);
        mutate();
        final after = app.wodEstimate(w);
        expect(identical(after, before), isFalse);
        // Même valeur qu'un calcul direct, sans cache.
        final fresh = TrainingEstimator.wod(w);
        expect(after.durationLabel, fresh.durationLabel);
        expect(after.elapsed.midpoint, fresh.elapsed.midpoint);
        expect(identical(app.wodEstimate(w), after), isTrue);
        return after;
      }

      final line = w.lines.first;
      changed(() => w.lines[0] = '$line + 10 burpees');
      changed(() => w.lines[0] = line);
      changed(() => w.interval += 30);
      changed(() => w.notes = '${w.notes} L6');
      changed(() => w.rounds += 1);
      changed(
        () => w.results.add(
          WodResult(at: '2026-09-01T10:00:00', score: '12:00', seconds: 720),
        ),
      );
      // Même nombre de résultats : modification sur place.
      changed(() => w.results.first.seconds = 600);
      changed(() => w.results.first.notes = 'corrigé');
      changed(() => w.results.first.completed = false);
      changed(
        () =>
            w.results.first.intervals = [
              [1, null, 3],
            ],
      );
      changed(() => w.results.first.intervals![0][1] = 2);
      changed(() => w.results.removeLast());
      // Le nom ne fait pas partie de la clé d'origine (inchangé en L6).
      final kept = app.wodEstimate(w);
      w.name = '${w.name} bis';
      expect(identical(app.wodEstimate(w), kept), isTrue);
    });

    test('estimation WOD : plus de 1 024 WOD, un second passage complet '
        'réutilise toutes les estimations', () {
      for (var i = 0; i < 60; i++) {
        app.upsertWod(
          Wod(
            id: 'l6perso$i',
            name: 'WOD perso $i',
            rounds: 3,
            type: 'rounds',
            lines: ['${10 + i % 7} pompes', '10 squats'],
          ),
        );
      }
      expect(app.wods.length, greaterThan(1024));
      final first = [for (final w in app.wods) app.wodEstimate(w)];
      final second = [for (final w in app.wods) app.wodEstimate(w)];
      for (var i = 0; i < first.length; i++) {
        expect(identical(first[i], second[i]), isTrue, reason: app.wods[i].id);
      }
    });

    test('statistiques WOD et niveaux : recalculés après une modification, '
        'identiques au calcul direct', () {
      final w = app.wods.firstWhere(
        (w) => app.isCatalog(w) && w.lines.length > 1,
      );
      final before = app.wodStats(w);
      final line = w.lines.first;
      w.lines[0] = '100 burpees';
      final after = app.wodStats(w);
      expect(after.points, app.difficultyScore(w).round());
      expect(after.points, isNot(before.points));
      w.lines[0] = line;
      expect(app.wodStats(w).points, before.points);

      // Classement : niveau de chaque WOD = calcul direct, y compris un WOD
      // du catalogue modifié et un WOD personnel.
      w.lines[0] = '150 burpees';
      app.upsertWod(
        Wod(id: 'l6rang', name: 'Rang', lines: ['50 tractions', '100 dips']),
      );
      app.rankCatalog();
      for (final x in app.wods) {
        expect(x.level, app.levelFor(x), reason: x.id);
      }
      w.lines[0] = line;
      app.rankCatalog();
      for (final x in app.wods) {
        expect(x.level, app.levelFor(x), reason: x.id);
      }
    });
  });

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
      finishedAt:
          DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
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
