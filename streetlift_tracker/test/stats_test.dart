import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });
  setUp(() {
    store.logs.clear();
    store.wods.removeWhere((w) => w.id.startsWith('stats-fixture'));
    store.notifyListeners();
  });

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    bool dark = true,
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    store.settings.theme = dark ? 'dark' : 'light';
    await tester.pumpWidget(
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
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> section(WidgetTester tester, int index) async {
    final tab = find.byKey(ValueKey('stats-section-$index'));
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  String fingerprint() => jsonEncode({
    'logs': store.logs.map((key, value) => MapEntry(key, value.toJson())),
    'results': {
      for (final w in store.wods.where((w) => w.results.isNotEmpty))
        w.id: w.results.map((r) => r.toJson()).toList(),
    },
  });

  test(
    'le journal fusionne séances et WOD sans supprimer les dates manquantes',
    () {
      final now = DateTime.now();
      store.logs['S8-J1'] = SessionLog(done: true, title: 'Ancienne séance');
      store.logs['S8-J2'] = SessionLog(
        done: true,
        title: 'Séance récente',
        finishedAt: now.toIso8601String(),
      );
      store.logs['S8-J3'] = SessionLog(done: false, title: 'En cours');
      final wod = Wod(
        id: 'stats-fixture-history',
        name: 'Test WOD',
        results: [
          WodResult(
            at: now.subtract(const Duration(days: 1)).toIso8601String(),
            score: '8:40',
            completed: false,
          ),
        ],
      );
      store.wods.add(wod);
      final before = fingerprint();
      final history = statsHistory(store);
      expect(history.map((e) => e.title), [
        'Séance récente',
        'Test WOD',
        'Ancienne séance',
      ]);
      expect(history.last.at, isNull);
      expect(history[1].result, same(wod.results.first));
      expect(fingerprint(), before);
    },
  );

  testWidgets('le niveau ouvre Parcours dans le seul onglet STATS', (
    tester,
  ) async {
    await open(tester, const RootNav());
    await tester.tap(find.byTooltip('Ouvrir ma progression'));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    expect(find.text('Ton arbre de progression'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.byKey(const ValueKey('nav-4')), findsNothing);
    expect(find.text('SUIVI'), findsNothing);
    expect(find.text('PILOTAGE'), findsNothing);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'recherche, filtre et rubrique STATS survivent aux changements d’onglet',
    (tester) async {
      store.logs['S8-J1'] = SessionLog(
        done: true,
        title: 'Tractions du matin',
        finishedAt: DateTime.now().toIso8601String(),
      );
      await open(tester, const RootNav());
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      await section(tester, 3);
      await tester.enterText(
        find.byKey(const ValueKey('stats-history-search')),
        'Tractions',
      );
      await tester.tap(find.byKey(const ValueKey('history-filter-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('stats-history-search')),
            )
            .controller!
            .text,
        'Tractions',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('history-filter-1')))
            .selected,
        isTrue,
      );
      expect(find.text('Tractions du matin'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('historique : filtres WOD, notes et lecture seule des séances', (
    tester,
  ) async {
    final now = DateTime.now();
    final ex = store.program.week(8).day(2)!.exercises.first;
    final log =
        store.sessionLog(8, 2)
          ..done = true
          ..title = 'Séance témoin'
          ..finishedAt = now.toIso8601String();
    final entry = store.exLog(8, 2, ex)..note = 'Amplitude contrôlée';
    entry.sets.first
      ..kg = '12.5'
      ..reps = '7'
      ..done = true;
    store.wods.add(
      Wod(
        id: 'stats-fixture-notes',
        name: 'WOD témoin',
        results: [
          WodResult(
            at: now.toIso8601String(),
            score: '7 tours',
            rounds: 7,
            notes: 'Allure régulière',
          ),
        ],
      ),
    );
    final before = fingerprint();
    await open(
      tester,
      const StatsScreen(initialSection: StatsSection.history, standalone: true),
    );
    await tester.tap(find.byKey(const ValueKey('history-filter-2')));
    await tester.pumpAndSettle();
    expect(find.text('Séance témoin'), findsNothing);
    await tester.tap(find.text('WOD témoin'));
    await tester.pumpAndSettle();
    expect(find.text('Allure régulière'), findsOneWidget);
    Navigator.of(tester.element(find.text('Allure régulière'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('history-filter-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Séance témoin'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionHistoryScreen), findsOneWidget);
    expect(find.text('Amplitude contrôlée'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(fingerprint(), before);
    expect(log.done, isTrue);
    expect(tester.takeException(), null);
  });

  testWidgets(
    'les références restent modifiables et reviennent aux performances',
    (tester) async {
      // L4 : références inconnues sur une installation neuve ; ce scénario
      // modifie une référence déjà renseignée.
      store.setValue('B8', 30);
      final original = store.values['B8']!;
      await open(
        tester,
        const StatsScreen(
          initialSection: StatsSection.performance,
          standalone: true,
        ),
      );
      await tester.tap(find.text('Modifier mes références'));
      await tester.pumpAndSettle();
      expect(find.byType(PilotageScreen), findsOneWidget);
      final input = find.byKey(ValueKey('B8-${store.pilotageEpoch}'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '62,5');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(store.values['B8'], 62.5);
      expect(find.textContaining('62,5'), findsWidgets);
      expect(find.byType(PilotageScreen), findsNothing);
      expect(tester.takeException(), null);
      store.setValue('B8', original);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'un palier se met à jour depuis les séances, sa consultation ne donne pas de XP',
    (tester) async {
      await open(
        tester,
        const StatsScreen(
          initialSection: StatsSection.journey,
          standalone: true,
        ),
      );
      final node = find.byKey(const ValueKey('badge-session1'));
      await tester.ensureVisible(node);
      expect(
        find.descendant(of: node, matching: find.text('Prochain palier')),
        findsOneWidget,
      );
      store.sessionLog(8, 1)
        ..done = true
        ..finishedAt =
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      store.notifyListeners();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: node, matching: find.text('Obtenu')),
        findsOneWidget,
      );
      final xp = store.xp;
      final before = fingerprint();
      await tester.tap(node);
      await tester.pumpAndSettle();
      expect(find.text('+40 XP déjà inclus dans ton total.'), findsOneWidget);
      expect(store.xp, xp);
      expect(fingerprint(), before);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'les commandes STATS et les paliers sont nommés pour le lecteur d’écran',
    (tester) async {
      final semantics = tester.ensureSemantics();

      try {
        await open(tester, const StatsScreen(standalone: true));
        expect(tester, meetsGuideline(labeledTapTargetGuideline));
        await section(tester, 1);
        expect(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(tester.takeException(), null);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final dark in [true, false]) {
    testWidgets('STATS lisible à 320 px et texte 130 %, thème $dark', (
      tester,
    ) async {
      await open(
        tester,
        const StatsScreen(standalone: true),
        dark: dark,
        width: 320,
        scale: 1.3,
      );
      for (var i = 0; i < 4; i++) {
        await section(tester, i);
        final list = find.byType(ListView).last;
        for (var j = 0; j < 10; j++) {
          await tester.drag(list, const Offset(0, -420));
          await tester.pumpAndSettle();
          expect(tester.takeException(), null);
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
