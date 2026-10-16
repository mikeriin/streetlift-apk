// KM3 (dev7.0.0) — parcours à l'écran d'une séance servie par Koach 1.0,
// comme sur l'émulateur : bascule forcée un vendredi (S14·J5, semaine
// entamée), écran de séance, bilan « Bien », premier exercice : la séance
// commence (`seance_debut`, `plan(seance)`), Koach sert ses items ; le
// diagnostic hors modèle, s'il se pose, se passe par « Plus tard ».
// Données synthétiques ; horloge injectée ; calculs du moteur sur place.
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

  testWidgets('bilan puis premier exercice : la séance de Koach commence', (
    tester,
  ) async {
    await tester.runAsync(() async {
      store.koachForceBascule(civilOf(clock));
      await store.koachRefresh();
    });
    expect(store.koachEngine.snap, isNotNull);
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
    expect(store.koachPending(14, j), isTrue, reason: 'aperçu');
    await tester.tap(find.byKey(const ValueKey('feel-4')));
    final log = <String>[];
    for (var i = 0; i < 40 && !store.koachOpen(14, j); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      for (final k in const ['koach-diag-later', 'adjust-go', 'bilan-start']) {
        final f = find.byKey(ValueKey(k));
        if (f.evaluate().isNotEmpty) {
          log.add(k);
          await tester.tap(f.first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    }
    final st = store.sessionAdapt(14, j)?.koach;
    // ignore: avoid_print
    print(
      'KM3|ecran|S14-J$j|etat=${st?['state']}|appuis=$log|'
      'diag=${store.koachNeedsDiagnostic}|'
      'items=${(st?['items'] as List?)?.length}',
    );
    expect(store.koachOpen(14, j), isTrue, reason: 'état ${st?['state']}');
    expect((st?['items'] as List?) ?? const [], isNotEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
