// L5-C — Rendus Flutter de test des six couleurs dominantes (clair/sombre) :
// PROGRAMME et RÉGLAGES → Apparence à 390 × 844, plus le sélecteur à
// 320 px et texte 200 %. Seule la couleur (ou le mode) change entre deux
// rendus d'une même vue. Désactivé sans --dart-define=KALIS_CAPTURE=true.
// Données synthétiques (installation neuve, départ au 13/07/2026).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/capture_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('six couleurs × clair/sombre', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    store.program.start = DateTime(2026, 7, 13);
    // Une séance commencée et une validée : états « en cours » et « fait ».
    store.markSessionDone(12, 1, true);
    final started = store.program.week(12).day(2)!.exercises.first;
    store.exLog(12, 2, started).sets.first.kg = '20';
    store.saveLogs(immediate: true);
    await loadCaptureFonts();
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    var serial = 0;
    Future<void> show(
      Widget home,
      KAccentSpec spec,
      bool dark, {
      Size size = const Size(390, 844),
      double text = 1,
    }) async {
      tester.view.physicalSize = size;
      store.settings
        ..theme = dark ? 'dark' : 'light'
        ..accent = spec.id;
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            key: ValueKey(serial++),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            theme: buildTheme(dark, spec),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(text)),
              child: child!,
            ),
            home: home,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await precacheCaptureImages(tester);
      expect(tester.takeException(), isNull, reason: '${spec.id} $dark');
    }

    for (final spec in KAccentSpec.all) {
      for (final dark in [true, false]) {
        final mode = dark ? 'sombre' : 'clair';
        await show(
          RootNav(referenceDate: DateTime(2026, 9, 30, 9)),
          spec,
          dark,
        );
        if (captureEnabled) {
          await savePng(tester, boundary, 'palette_${spec.id}_programme_$mode');
        }
        await show(const SettingsScreen(), spec, dark);
        if (captureEnabled) {
          await savePng(tester, boundary, 'palette_${spec.id}_reglages_$mode');
        }
      }
    }
    for (final dark in [true, false]) {
      final mode = dark ? 'sombre' : 'clair';
      await show(
        const SettingsScreen(),
        KAccentSpec.jaune,
        dark,
        size: const Size(320, 720),
        text: 2,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('accent-turquoise')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      if (captureEnabled) {
        await savePng(tester, boundary, 'selecteur_320_200pct_$mode');
      }
      await show(
        RootNav(referenceDate: DateTime(2026, 9, 30, 9)),
        KAccentSpec.jaune,
        dark,
        size: const Size(320, 720),
        text: 2,
      );
      if (captureEnabled) {
        await savePng(tester, boundary, 'programme_jaune_320_200pct_$mode');
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }, skip: !captureEnabled);
}
