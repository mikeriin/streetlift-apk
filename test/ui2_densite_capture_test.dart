// UI2 (refonte UI, séance) — capture de densité : programme par défaut,
// S8·J1, 360 × 760 dp avec barres système (24 dp), texte 100 % : les cinq
// séries du premier exercice et la barre d'outils tiennent sans défilement
// (exigence de `ui_refactor_test.dart`). Ignoré sans KALIS_CAPTURE.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();

  testWidgets('densité de la page d’exercice', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    await loadUiFonts();
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final week = store.program.week(8);
    final day = week.day(1)!;
    store.clearSession(8, 1);
    for (final dark in [true, false]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: root,
          child: MaterialApp(
            key: UniqueKey(),
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: buildTheme(dark),
            home: SessionScreen(week: week, day: day),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await saveUiPng(
        tester,
        root,
        'ui2_densite_bordeaux_${dark ? 'sombre' : 'clair'}_360',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    store.clearSession(8, 1);
    await tester.runAsync(() => store.flush());
  }, skip: !uiCaptureEnabled);
}
