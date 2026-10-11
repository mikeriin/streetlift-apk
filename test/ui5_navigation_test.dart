// UI5 (refonte UI) — changement d'onglet et états vides de Stats (R6) :
// `openTab` ouvre l'onglet Programme depuis Stats (racine) et depuis une
// page empilée ; l'historique vide, les records vides et la quête
// principale sans séance portent « Ouvrir le programme », qui y mène ;
// la relecture d'une séance passée tient à 320 × 640 dp et 200 % de texte
// (« historique_seance », débordement présent depuis UI0).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart' show swipePage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DateTime? start;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false
      ..celebrations = false;
    start = store.program.start;
  });
  setUp(() {
    store.logs.clear();
    store.program.start = start;
    store.notifyListeners();
  });
  tearDown(() {
    store.logs.clear();
    store.program.start = start;
    store.notifyListeners();
  });

  Widget app(Widget home, {bool dark = true, double scale = 1}) => MaterialApp(
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
    home: home,
  );

  Route<void> route(Widget page) =>
      MaterialPageRoute<void>(builder: (_) => page);

  void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Future<void> openRoot(WidgetTester tester) async {
    phone(tester);
    await tester.pumpWidget(app(const RootNav()));
    await tester.pumpAndSettle();
  }

  int tab(WidgetTester tester) =>
      tester.widget<HeroNavBar>(find.byType(HeroNavBar)).index;

  Future<void> openStats(WidgetTester tester, {int? section}) async {
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    expect(tab(tester), AppTab.stats.index);
    if (section != null) {
      await tester.tap(find.byKey(ValueKey('stats-section-$section')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find
      .descendant(
        of: find.byType(StatsScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      )
      .hitTestable();

  /// Bouton « Ouvrir le programme » de l'état vide [empty].
  Finder openProgram(Key empty) => find.descendant(
    of: find.byKey(empty),
    matching: find.widgetWithText(KTonalButton, 'Ouvrir le programme'),
  );

  group('openTab', () {
    test('mêmes onglets, même ordre que le dock', () {
      final labels = [
        for (final t in AppTab.values) HeroNavBar.items[t.index].label,
      ];
      expect(labels, ['Arsenal', 'Stats', 'Programme', 'Réglages']);
    });

    testWidgets('ouvre Programme depuis Stats (racine)', (tester) async {
      await openRoot(tester);
      // Ouverture inchangée : Programme.
      expect(tab(tester), AppTab.program.index);
      await openStats(tester);
      final context = tester.element(find.byType(StatsScreen));
      expect(openTab(context, AppTab.program), isTrue);
      await tester.pumpAndSettle();
      expect(tab(tester), AppTab.program.index);
      // Les autres onglets aussi, clés du dock inchangées.
      expect(openTab(context, AppTab.settings), isTrue);
      await tester.pumpAndSettle();
      expect(tab(tester), AppTab.settings.index);
      expect(find.byKey(const ValueKey('nav-3')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('ouvre Programme depuis une page empilée et la ferme', (
      tester,
    ) async {
      await openRoot(tester);
      await openStats(tester);
      final navigator = Navigator.of(tester.element(find.byType(StatsScreen)));
      unawaited(navigator.push(route(const RecordsScreen())));
      await tester.pumpAndSettle();
      const stackedKey = ValueKey('ui5-stacked');
      const stacked = Scaffold(key: stackedKey, body: Text('Page empilée'));
      unawaited(navigator.push(route(stacked)));
      await tester.pumpAndSettle();
      expect(find.byKey(stackedKey), findsOneWidget);
      final context = tester.element(find.byKey(stackedKey));
      expect(openTab(context, AppTab.program), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(stackedKey), findsNothing);
      expect(find.byType(RecordsScreen), findsNothing);
      expect(tab(tester), AppTab.program.index);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('sans racine montée : rien ne change', (tester) async {
      phone(tester);
      await tester.pumpWidget(app(const RecordsScreen()));
      await tester.pumpAndSettle();
      expect(AppTabs.bound, isFalse);
      final context = tester.element(find.byType(RecordsScreen));
      expect(openTab(context, AppTab.program), isFalse);
      await tester.pumpAndSettle();
      expect(find.byType(RecordsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  });

  group('états vides de Stats : « Ouvrir le programme »', () {
    testWidgets('Historique vide', (tester) async {
      await openRoot(tester);
      await openStats(tester, section: 3);
      const empty = ValueKey('stats-history-empty');
      expect(find.byKey(empty), findsOneWidget);
      expect(find.text('Ton histoire commence ici'), findsOneWidget);
      final action = openProgram(empty);
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(tab(tester), AppTab.program.index);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('Records vides (page empilée)', (tester) async {
      await openRoot(tester);
      await openStats(tester, section: 2);
      final records = find.byKey(const ValueKey('stats-records'));
      await tester.ensureVisible(records);
      await tester.pumpAndSettle();
      await tester.tap(records);
      await tester.pumpAndSettle();
      expect(find.byType(RecordsScreen), findsOneWidget);
      const empty = ValueKey('records-empty');
      expect(find.text('Aucun record pour l’instant'), findsOneWidget);
      final action = openProgram(empty);
      expect(action, findsOneWidget);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(RecordsScreen), findsNothing);
      expect(tab(tester), AppTab.program.index);
      expect(tester.takeException(), isNull);
      await close(tester);
    });

    testWidgets('Quête principale sans séance du programme', (tester) async {
      store.program.start = null;
      store.notifyListeners();
      expect(store.game.programWeek, 0);
      await openRoot(tester);
      await openStats(tester);
      final action = find.byKey(const ValueKey('stats-quest-open-program'));
      await tester.scrollUntilVisible(
        action,
        200,
        scrollable: scrollable().first,
      );
      await tester.pumpAndSettle();
      final label = find.text('Ouvrir le programme');
      expect(find.descendant(of: action, matching: label), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(tab(tester), AppTab.program.index);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  });

  for (final dark in [true, false]) {
    testWidgets(
      'historique d’une séance à 320 × 640 dp, texte 200 %, sans débordement '
      '(thème ${dark ? 'sombre' : 'clair'})',
      (tester) async {
        // Même journal que le rendu « historique_seance » (L5-C) : S11 J1,
        // quatre exercices aux séries validées.
        store.program.start = DateTime(2026, 7, 13);
        final week = store.program.week(11);
        final day = week.day(1)!;
        final done = DateTime(2026, 9, 21, 18);
        store.sessionLog(11, 1)
          ..done = true
          ..finishedAt = done.toIso8601String();
        for (final exercise in day.exercises.take(4)) {
          for (final set in store.exLog(11, 1, exercise).sets) {
            set
              ..done = true
              ..kg = '15'
              ..reps = '6'
              ..completedAt = done.toIso8601String();
          }
        }
        store.notifyListeners();
        phone(tester, size: const Size(320, 640));
        await tester.pumpWidget(
          app(
            SessionHistoryScreen(
              log: store.sessionLog(11, 1),
              week: week,
              day: day,
            ),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SessionHistoryScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Chaque page, jusqu'au bilan.
        for (var page = 0; page < 4; page++) {
          await swipePage(tester);
          expect(tester.takeException(), isNull, reason: 'page ${page + 1}');
        }
        expect(find.text('Bilan de séance'), findsWidgets);
        await close(tester);
      },
    );
  }
}
