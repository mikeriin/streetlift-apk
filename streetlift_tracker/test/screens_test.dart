import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_screen.dart';

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

  testWidgets('le bouton effacer vide aussi le champ de recherche', (
    tester,
  ) async {
    await tester.pumpWidget(app(const WodCatalogScreen()));
    final input = find.byType(TextField);
    await tester.enterText(input, 'introuvable-12345');
    await tester.pumpAndSettle();
    expect(find.text('WODs · 0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, '');
    expect(find.text('WODs · 1000'), findsOneWidget);
    expect(tester.takeException(), null);
  });

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
    final session = CustomSession(
      id: '987',
      name: 'Tenue',
      items: [
        CustomExercise(
          name: 'Gainage',
          mode: 'iso',
          p: {'series': 1, 'hold': 3600},
        ),
      ],
    );
    final week = session.toWeekPlan();
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
          WodPreviewScreen(
            wodId: store.wods.firstWhere((w) => w.type == 'rounds').id,
          ),
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

  testWidgets('aperçu depuis le runner revient au même chrono', (tester) async {
    final wod = Wod(id: 'wtest', name: 'Test chrono', lines: ['10 push-ups']);
    store.upsertWod(wod);
    await tester.pumpWidget(app(WodRunScreen(wodId: wod.id)));
    await tester.tap(find.text('Démarrer'));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byIcon(Icons.insights));
    await tester.pumpAndSettle();
    expect(find.text('Revenir au chrono'), findsOneWidget);
    await tester.tap(find.text('Revenir au chrono'));
    await tester.pumpAndSettle();
    expect(find.byType(WodRunScreen), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'score invalide reste ouvert, annulation puis score valide sans doublon',
    (tester) async {
      final wod = Wod(id: 'wscore', name: 'Score', lines: ['10 push-ups']);
      store.upsertWod(wod);
      await tester.pumpWidget(app(WodRunScreen(wodId: wod.id)));
      await tester.tap(find.text('Démarrer'));
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '1:99');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.text('Saisis un temps valide supérieur à zéro.'),
        findsOneWidget,
      );
      expect(wod.results, isEmpty);
      await tester.enterText(find.byType(TextFormField).first, '1:20');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(wod.results.length, 1);
      expect(wod.results.single.seconds, 80);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
