import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

Widget app(Widget page, {bool dark = true}) =>
    MaterialApp(theme: buildTheme(dark), home: page);

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
    'tous les groupes musculaires utilisent seulement les masques existants',
    (tester) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: MuscleHeatmap(
              data: {for (final group in AppStore.muscleGroups) group: 1.0},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    },
  );

  testWidgets('un jour de repos actualise son bouton immédiatement', (
    tester,
  ) async {
    final week = store.program.week(8);
    store.clearSession(8, 7);
    await tester.pumpWidget(app(SessionScreen(week: week, day: week.day(7)!)));
    await tester.tap(find.text('Marquer comme fait'));
    await tester.pumpAndSettle();
    expect(find.text('Marqué fait'), findsOneWidget);
    await tester.tap(find.text('Marqué fait'));
    await tester.pumpAndSettle();
    expect(find.text('Marquer comme fait'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('le chrono long tient sur un écran de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    store.settings.prepSec = 0;
    // Tenue chronométrée de 3600 s dans une séance construite à la main
    // (les séances manuelles ont disparu en G2, le chrono de tenue reste).
    final week = WeekPlan.manual(
      n: 0,
      block: 'Tenue',
      color: const Color(0xFF4FA3C7),
      days: [
        DayPlan.manual(
          j: 987,
          title: 'Tenue',
          exercises: [
            Exercise.manual(
              id: 'CU-0',
              name: 'Gainage',
              setsText: '1×3600 s',
              forcedSets: 1,
              timer: {'type': 'hold', 'sec': 3600},
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      app(SessionScreen(week: week, day: week.days.single)),
    );
    await tester.tap(find.textContaining('Chrono 3600'));
    await tester.pump();
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final dark in [true, false]) {
    testWidgets(
      'écrans principaux à 320 px, thème ${dark ? 'sombre' : 'clair'}',
      (tester) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final page in [
          const HomeScreen(),
          const SettingsScreen(),
          const RecordsScreen(),
        ]) {
          await tester.pumpWidget(app(page, dark: dark));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            null,
            reason: page.runtimeType.toString(),
          );
        }
      },
    );
  }
}
