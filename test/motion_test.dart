import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/main.dart' show RootNav;
import 'package:streetlift_tracker/motion.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false;
  });

  void compact(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  FadeTransition contentFade(WidgetTester tester, String key) =>
      tester.widget<FadeTransition>(
        find
            .descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(FadeTransition),
            )
            .first,
      );

  testWidgets(
    'onglets : transition visible et navigation rapide sans perdre STATS',
    (tester) async {
      compact(tester);
      await tester.pumpWidget(
        MaterialApp(theme: buildTheme(true), home: const RootNav()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        contentFade(tester, 'navigation-transition').opacity.value,
        inExclusiveRange(0, 1),
      );
      final state = tester.state(find.byType(StatsScreen));
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(StatsScreen)), same(state));
      expect(contentFade(tester, 'navigation-transition').opacity.value, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'réduire les animations rend les onglets et le sélecteur STATS immédiats',
    (tester) async {
      compact(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(theme: buildTheme(true), home: const RootNav()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pump();
      expect(contentFade(tester, 'navigation-transition').opacity.value, 1);
      await tester.tap(find.byKey(const ValueKey('stats-section-1')));
      await tester.pump();
      expect(contentFade(tester, 'stats-transition').opacity.value, 1);
      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.controller!.index, 1);
      expect(tabs.controller!.indexIsChanging, isFalse);
      expect(tabs.controller!.animation!.value, 1);
      expect(find.text('Ton arbre de progression'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'une saisie survit au passage en animations réduites pendant une transition de page',
    (tester) async {
      compact(tester);
      final reduced = ValueNotifier(false);
      final nav = GlobalKey<NavigatorState>();
      addTearDown(reduced.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: buildTheme(true),
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: value),
              child: child!,
            ),
          ),
          home: const Scaffold(body: Text('Origine')),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(body: TextField(key: ValueKey('route-note'))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final field = find.byKey(const ValueKey('route-note'));
      final fade = find
          .ancestor(of: field, matching: find.byType(FadeTransition))
          .first;
      expect(
        tester.widget<FadeTransition>(fade).opacity.value,
        inExclusiveRange(0, 1),
      );
      await tester.enterText(field, 'Ma note conservée');
      final state = tester.state(field);
      reduced.value = true;
      await tester.pump();
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
      expect(tester.state(field), same(state));
      expect(find.text('Ma note conservée'), findsOneWidget);
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Origine'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  test('les textes de la palette gardent un contraste minimal de 4,5', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
    }

    for (final dark in [true, false]) {
      final p = KPalette(dark);
      for (final bg in [p.bg, p.surface, p.card, p.formFill, p.fieldFill]) {
        for (final fg in [
          p.text,
          p.dim,
          p.accent,
          p.success,
          p.prevViolet,
          p.danger,
        ]) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$dark : $fg sur $bg',
          );
        }
      }
      expect(contrast(p.logo, p.bg), greaterThanOrEqualTo(4.5));
      expect(contrast(KPalette.light, p.bordeaux), greaterThanOrEqualTo(4.5));
      // Rouge d'action en fond (navigation, segments, achat) et vert de
      // validation en fond (jour de repos) : libellés lisibles.
      expect(contrast(KPalette.light, p.action), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onAccent, p.success), greaterThanOrEqualTo(4.5));
      // Le bout des jauges (rouge d'action) se distingue de la piste.
      expect(contrast(p.action, p.progressTrack), greaterThan(1.5));
    }
    expect(
      buildTheme(true).pageTransitionsTheme.builders[TargetPlatform.android],
      isA<KPageTransitionsBuilder>(),
    );
  });
}
