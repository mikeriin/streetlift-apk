// M1 (mannequin 3D) — écran « Moteur 3D » : calcul de la mesure de
// fluidité, repli sans Flutter GPU (le moteur de test n'en a pas : c'est
// exactement le cas d'un téléphone incompatible), accès depuis
// Réglages › À propos, lisibilité 390 / 320 px et texte 100 / 200 %.
// Le rendu réel (Flutter GPU) est vérifié sur émulateur Android par
// integration_test/moteur_3d_test.dart (voir docs/CI_3D.md).

import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

Future<void> _settle(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 40 && ready.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(ready, findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  Widget page(Widget child, {double scale = 1, bool dark = true}) =>
      MaterialApp(
        theme: buildTheme(dark),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      );

  group('mesure de fluidité', () {
    test('moyenne, 99e centile et images par seconde', () {
      final spans = [
        for (var i = 1; i <= 100; i++) Duration(microseconds: i * 1000),
      ];
      final stats = FrameStats.of(spans, const Duration(seconds: 2));
      expect(stats.frames, 100);
      expect(stats.meanMs, closeTo(50.5, 1e-9));
      expect(stats.p99Ms, closeTo(99, 1e-9));
      expect(stats.fps, closeTo(50, 1e-9));
    });

    test('une seule image : le centile est cette image', () {
      final stats = FrameStats.of(const [
        Duration(microseconds: 16700),
      ], const Duration(seconds: 1));
      expect(stats.p99Ms, closeTo(16.7, 1e-9));
      expect(stats.meanMs, closeTo(16.7, 1e-9));
      expect(stats.fps, 1);
    });

    test('aucune image : zéro partout, sans division par zéro', () {
      final stats = FrameStats.of(const [], Duration.zero);
      expect(stats.frames, 0);
      expect(stats.fps, 0);
      expect(stats.meanMs, 0);
      expect(stats.p99Ms, 0);
    });

    test('temps d’image du moteur : fenêtre de 10 s sur son horloge', () {
      FrameTiming frame(int startMs, int spanMs) => FrameTiming(
        vsyncStart: startMs * 1000,
        buildStart: startMs * 1000,
        buildFinish: startMs * 1000 + 1000,
        rasterStart: startMs * 1000 + 1000,
        rasterFinish: (startMs + spanMs) * 1000,
        rasterFinishWallTime: (startMs + spanMs) * 1000,
      );
      // 61 images toutes les 1/6 s environ à partir de t = 5 s, plus une
      // image arrivée après la fenêtre (t = 15,5 s) : écartée.
      final timings = [
        for (var i = 0; i < 60; i++) frame(5000 + i * 166, 8),
        frame(15500, 30),
      ];
      final stats = FrameStats.fromTimings(
        timings,
        const Duration(seconds: 10),
      );
      expect(stats.frames, 60);
      expect(stats.fps, closeTo(6, 1e-9));
      expect(stats.meanMs, closeTo(8, 1e-9));
      expect(FrameStats.fromTimings(const [], Duration.zero).frames, 0);
    });

    test('seuil de fluidité et durée de la mesure', () {
      expect(kEngine3DFluidFps, 45);
      expect(kEngine3DMeasure, const Duration(seconds: 10));
    });
  });

  test('couleurs : gris mat et fonds de la page de référence', () {
    expect(kMuscleGray, const Color(0xFF8F8B8A));
    expect(sceneBackground(true), const Color(0xFF161414));
    expect(sceneBackground(false), const Color(0xFFEDEBEA));
  });

  test('sans Flutter GPU : « non compatible », sans exception', () async {
    final support = await engine3DSupport();
    expect(support.gpuAvailable, isFalse);
    expect(support.compatible, isFalse);
    expect(support.error, isNotNull);
  });

  for (final (size, scale, dark) in [
    (const Size(390, 844), 1.0, true),
    (const Size(320, 720), 2.0, false),
  ]) {
    testWidgets('écran sans Flutter GPU lisible ${size.width.toInt()} px, '
        'texte ${(scale * 100).round()} %', (tester) async {
      phone(tester, size: size);
      await tester.pumpWidget(
        page(const Engine3DScreen(), scale: scale, dark: dark),
      );
      await _settle(
        tester,
        find.text('La 3D n’est pas disponible sur ce téléphone.'),
      );
      await scrollToAction(tester, find.text('Non compatible'));
      await scrollToAction(tester, find.text('absent'));
      await scrollToAction(
        tester,
        find.text('Mesure impossible sans moteur 3D.'),
      );
      expect(find.byKey(const ValueKey('engine3d-measure')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Réglages › À propos › Moteur 3D ouvre l’écran', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const SettingsScreen(section: 9)));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('about-engine3d'));
    await scrollToAction(tester, tile);
    expect(find.text('Moteur 3D'), findsOneWidget);
    await tester.tap(tile);
    await _settle(tester, find.text('Non compatible'));
    expect(find.text('MOTEUR 3D'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
