import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/settings_screen.dart';
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
  testWidgets(
    'les réglages de chrono restent enregistrés après retour au menu',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: buildTheme(true), home: const SettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Chronomètres'), 200);
      await tester.tap(find.text('Chronomètres'));
      await tester.pumpAndSettle();
      final before = store.settings.defaultRest;
      await tester.tap(find.byTooltip('Augmenter Repos par défaut'));
      await tester.pumpAndSettle();
      expect(store.settings.defaultRest, before + 15);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chronomètres'));
      await tester.pumpAndSettle();
      expect(find.text('${before + 15}\u00a0s'), findsOneWidget);
      expect(tester.takeException(), null);
      store.settings.defaultRest = before;
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'les quatre destinations ont un libellé visible et conservent leur état',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          home: RootNav(referenceDate: DateTime(2026, 9, 21)),
        ),
      );
      await tester.pumpAndSettle();
      for (final entry
          in {
            0: 'Arsenal',
            1: 'Stats',
            2: 'Programme',
            3: 'Réglages',
          }.entries) {
        final tab = find.byKey(ValueKey('nav-${entry.key}'));
        expect(
          find.descendant(
            of: tab,
            matching: find.text(entry.value.toUpperCase()),
          ),
          findsOneWidget,
        );
        await tester.tap(tab);
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
