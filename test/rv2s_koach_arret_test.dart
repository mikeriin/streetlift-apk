// RV2 (dev7.6.0, zone s, constat S13 de RV1) — arrêt d'urgence de Koach
// (Réglages) pendant que l'écran de séance est ouvert sur une séance que
// Koach sert : l'écran suit le magasin (`koachStop`, retour à la séance
// écrite) : pages de la séance écrite, plus de bilan du jour ni de conduite
// de Koach, séries validées gardées. Avant, l'écran gardait les exercices
// et les cibles de Koach jusqu'à sa fermeture.
// Parcours comme KM3 (bascule forcée un vendredi, S14·J5, bilan « Bien »,
// premier exercice). Données synthétiques ; horloge injectée ; calculs du
// moteur sur place.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final clock = DateTime(2026, 10, 16, 9); // vendredi, S14·J5

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    store.storeClock = () => clock;
    await store.init();
    final b = filledBackup(store);
    final logs = (b['logs'] as Map).cast<String, dynamic>();
    logs.removeWhere((k, _) {
      final w = int.parse(k.substring(1, k.indexOf('-')));
      final j = int.parse(k.substring(k.indexOf('J') + 1));
      return w > 14 || (w == 14 && j >= 5);
    });
    b['programStart'] = {
      'status': 'set',
      'date': '2026-07-13',
      'origin': 'migration',
    };
    expect(await store.importAll(jsonEncode(b)), isTrue);
    store.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(clock),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });

  testWidgets('S13 : arrêt d’urgence écran ouvert : séance écrite à '
      'l’écran, séries validées gardées', (tester) async {
    await tester.runAsync(() async {
      store.koachForceBascule(civilOf(clock));
      await store.koachRefresh();
    });
    expect(store.koachEngine.fromWeek, 14);
    final week = store.program.week(14);
    var j = 5;
    while (week.day(j)?.exercises.isEmpty ?? true) {
      j++;
    }
    final day = week.day(j)!;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionScreen(week: week, day: day),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('feel-4')));
    for (var i = 0; i < 40 && !store.koachOpen(14, j); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (final k in const ['koach-diag-later', 'adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k));
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }
    expect(store.koachOpen(14, j), isTrue);
    await tester.pump(const Duration(milliseconds: 500));
    // Page d'exercices servie par Koach.
    final served = find.byType(SessionExercisePage);
    expect(served, findsWidgets);
    final before = tester.widget<SessionExercisePage>(served.first);
    expect(before.adapt, isTrue);
    // Une série notée avant l'arrêt (gardée telle quelle).
    final ex = before.exs.first;
    final log = store.exLog(14, j, ex);
    log.sets.first
      ..reps = log.sets.first.reps.isEmpty ? '5' : log.sets.first.reps
      ..done = true
      ..completedAt = clock.toIso8601String();
    store.saveLogs();
    final done = jsonEncode(log.sets.first.toJson());
    final key = store.sessionKey(14, j);

    // Arrêt d'urgence (Réglages), écran ouvert.
    store.koachStop();
    expect(store.koachStoppedWeek(14), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // L'écran montre la séance écrite : pages du programme, sans Koach.
    final written = {
      for (final g in store.groups(day, week: 14))
        for (final e in g) e.id,
    };
    final pages = tester.widgetList<SessionExercisePage>(
      find.byType(SessionExercisePage),
    );
    expect(pages, isNotEmpty);
    for (final p in pages) {
      expect(p.adapt, isFalse, reason: 'plus de conduite de Koach');
      expect(identical(p.day, day), isTrue, reason: 'journée écrite');
      for (final e in p.exs) {
        expect(e.engine, isFalse);
        expect(written, contains(e.id));
      }
    }
    expect(find.byKey(const ValueKey('session-health-page')), findsNothing);
    // Série validée avant l'arrêt : gardée.
    final kept = store.logs[key]?.ex[ex.id];
    if (kept != null && kept.sets.isNotEmpty) {
      expect(jsonEncode(kept.sets.first.toJson()), done);
    }
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
