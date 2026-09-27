// L11 — écrans de l'adaptation au jour le jour : « J'ai seulement N
// minutes » depuis la séance (aperçu puis application, bandeau), écran
// « Adaptation au quotidien » (modes, pause, historique), carte de pause de
// l'accueil et question de difficulté de fin de séance. Fenêtres de
// téléphone réelles (390 × 844, 320 × 720), texte 130 et 200 %, thèmes
// clair et sombre, défilement par gestes.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt_screens.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 8, 24, 10);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ProgramAssets.load();
  });
  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.storeClock = () => now;
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    await store.configureStart(
      DateTime(2026, 8, 10),
      references: const {
        'B4': 71.5,
        'B8': 60,
        'B9': 80,
        'B10': 20,
        'B11': 140,
        'B17': 20,
        'B18': 30,
        'B19': 50,
        'B20': 30,
      },
    );
  });
  tearDown(() {
    store.debugWriteHook = null;
    store.storeClock = DateTime.now;
  });

  Widget page(Widget child, {double scale = 1, bool dark = true}) =>
      MaterialApp(
        theme: buildTheme(dark),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
        home: child,
      );

  for (final size in const [Size(390, 844), Size(320, 720)]) {
    for (final scale in const [1.3, 2.0]) {
      for (final dark in const [true, false]) {
        testWidgets('séance recomposée pour 30 min : ${size.width.toInt()} px, '
            'texte ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'}', (
          tester,
        ) async {
          phone(tester, size: size);
          final w = store.program.week(3);
          final d = w.day(1)!;
          await tester.pumpWidget(
            page(SessionScreen(week: w, day: d), scale: scale, dark: dark),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Options de séance'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('J’ai seulement… minutes'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('adapt-compress-sheet')),
            findsOneWidget,
          );
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-minutes-30')),
          );
          await tester.tap(find.byKey(const ValueKey('adapt-minutes-30')));
          await tester.pumpAndSettle();
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-compress-duration')),
          );
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-compress-apply')),
          );
          await tester.tap(find.byKey(const ValueKey('adapt-compress-apply')));
          await tester.pumpAndSettle();
          expect(store.adaptCompressed(3, 1), 30);
          expect(
            find.byKey(const ValueKey('adapt-session-banner')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('Adaptation au quotidien : ${size.width.toInt()} px, '
            'texte ${(scale * 100).round()} %, ${dark ? 'sombre' : 'clair'}', (
          tester,
        ) async {
          phone(tester, size: size);
          await tester.pumpWidget(
            page(const AdaptScreen(), scale: scale, dark: dark),
          );
          await tester.pumpAndSettle();
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-mode-guided')),
          );
          await tester.tap(find.byKey(const ValueKey('adapt-mode-guided')));
          await tester.pumpAndSettle();
          expect(store.autonomyMode, 'guided');
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-vacation')),
          );
          await tester.tap(find.byKey(const ValueKey('adapt-vacation')));
          await tester.pumpAndSettle();
          expect(store.adapt.pause?.kind, 'vacation');
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-pause-end')),
          );
          await tester.tap(find.byKey(const ValueKey('adapt-pause-end')));
          await tester.pumpAndSettle();
          expect(store.adapt.pause, isNull);
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('adapt-shorter')),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('carte de pause de l\'accueil (320 px, 200 %)', (tester) async {
    phone(tester, size: const Size(320, 720));
    store.startPause('illness');
    await tester.pumpWidget(
      page(
        Scaffold(
          body: ListView(children: const [AdaptHomeCard(pauseOnly: true)]),
        ),
        scale: 2.0,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adapt-pause-card')), findsOneWidget);
    await scrollToAction(tester, find.byKey(const ValueKey('adapt-pause-end')));
    await tester.tap(find.byKey(const ValueKey('adapt-pause-end')));
    await tester.pumpAndSettle();
    expect(store.adapt.pause, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('difficulté globale : une question, « Passer » possible', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    await tester.pumpWidget(
      page(
        Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showSessionDifficulty(context, 'S3-J1'),
                    child: const Text('ouvrir'),
                  ),
                ),
              ),
        ),
        scale: 2.0,
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('adapt-difficulty-sheet')), findsOneWidget);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('adapt-difficulty-6')),
    );
    await tester.tap(find.byKey(const ValueKey('adapt-difficulty-6')));
    await tester.pumpAndSettle();
    expect(store.adapt.difficulty['S3-J1']!['rpe'], 6);
    expect(tester.takeException(), isNull);
  });
}
