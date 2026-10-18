import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/startup.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    Future<void> initialization, {
    VoidCallback? onReady,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      AppStartup(
        initialization: initialization,
        appBuilder: (_) => MaterialApp(
          home: Scaffold(
            body: TextButton(onPressed: onReady, child: const Text('Accueil')),
          ),
        ),
        errorBuilder: (error, _) => MaterialApp(home: Text('Erreur : $error')),
        isDark: () => true,
        onReady: onReady,
      ),
    );
    await tester.pump();
  }

  final logo = find.byKey(const ValueKey('opening-logo'));

  testWidgets(
    'ouverture deux secondes : drapeau en bas, logo centre puis en-tête, accueil protégé',
    (tester) async {
      var ready = 0;
      await open(tester, Future.value(), onReady: () => ready++);
      expect(find.text('KALIS TRACK'), findsOneWidget);
      final start = tester.getCenter(logo);
      expect(start.dy, inInclusiveRange(350, 410));
      final flag = tester.getRect(find.byKey(const ValueKey('opening-flag')));
      expect(flag.size, const Size(36, 24));
      expect(flag.top, greaterThan(740));
      expect(find.text('Accueil').hitTestable(), findsNothing);
      await tester.pump(const Duration(milliseconds: 1400));
      final midway = tester.getCenter(logo);
      expect(midway.dy, lessThan(start.dy));
      expect(midway.dy, greaterThan(59));
      await tester.pump(const Duration(milliseconds: 440));
      expect(tester.getCenter(logo).dy, closeTo(59, .1));
      expect(tester.getSize(logo), const Size(48, 48));
      expect(tester.getCenter(logo).dx, closeTo(346, .1));
      expect(ready, 0);
      await tester.pump(const Duration(milliseconds: 160));
      expect(logo, findsNothing);
      expect(find.text('Accueil').hitTestable(), findsOneWidget);
      expect(ready, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(ready, 1);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('chargement lent : pas d’accueil prématuré ni saut de logo', (
    tester,
  ) async {
    final load = Completer<void>();
    await open(tester, load.future);
    final start = tester.getCenter(logo);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.getCenter(logo), start);
    expect(find.text('Accueil'), findsNothing);
    load.complete();
    await tester.pump();
    await tester.pump();
    expect(tester.getCenter(logo), start);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getCenter(logo).dy, lessThan(start.dy));
    await tester.pumpAndSettle();
    expect(logo, findsNothing);
    expect(find.text('Accueil').hitTestable(), findsOneWidget);
    expect(tester.takeException(), null);
  });

  testWidgets('une erreur d’initialisation reste visible', (tester) async {
    final load = Completer<void>();
    await open(tester, load.future);
    load.completeError(StateError('Données illisibles'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Données illisibles'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
    expect(logo, findsNothing);
    expect(tester.takeException(), null);
  });

  testWidgets(
    'réduire les animations supprime le déplacement et garde deux secondes',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await open(tester, Future.value());
      final start = tester.getCenter(logo);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(tester.getCenter(logo), start);
      expect(logo, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(logo, findsNothing);
      expect(tester.takeException(), null);
    },
  );
}
