// L5-C — Rendus Flutter de test du Rouge Kalis (couleur par défaut), écrits
// pour tourner à l'identique sur la base 3.0.1 et sur L5-C : ils servent à
// comparer « avant / après » avec la même fixture, la même taille, le même
// texte et le même mode. Désactivé sans --dart-define=KALIS_CAPTURE=true.
//
// Données synthétiques : installation neuve, départ au 13/07/2026, date de
// référence 30/09/2026 (S12 · J3). Aucune donnée personnelle.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/capture_support.dart';

const _tag = String.fromEnvironment('KALIS_CAPTURE_TAG', defaultValue: 'apres');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'rouge par défaut : rendus comparables avant / après L5-C',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = false;
      store.program.start = DateTime(2026, 7, 13);
      await loadCaptureFonts();
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final boundary = GlobalKey();
      var serial = 0;
      Future<void> show(Widget home, bool dark) async {
        store.settings.theme = dark ? 'dark' : 'light';
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              key: ValueKey(serial++),
              locale: const Locale('fr'),
              supportedLocales: const [Locale('fr')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              debugShowCheckedModeBanner: false,
              theme: buildTheme(dark),
              home: home,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await precacheCaptureImages(tester);
        expect(tester.takeException(), isNull);
      }

      for (final dark in [true, false]) {
        final mode = dark ? 'sombre' : 'clair';
        await show(RootNav(referenceDate: DateTime(2026, 9, 30, 9)), dark);
        for (final tab
            in {
              2: 'programme',
              0: 'arsenal',
              1: 'stats',
              3: 'reglages',
            }.entries) {
          await tester.tap(find.byKey(ValueKey('nav-${tab.key}')));
          await tester.pumpAndSettle();
          if (captureEnabled) {
            await savePng(tester, boundary, '${_tag}_rouge_${tab.value}_$mode');
          }
        }
        final week = store.program.week(12);
        await show(SessionScreen(week: week, day: week.day(4)!), dark);
        if (captureEnabled) {
          await savePng(tester, boundary, '${_tag}_rouge_seance_$mode');
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    skip: !captureEnabled,
  );
}
