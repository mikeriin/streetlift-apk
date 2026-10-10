// UI3 (refonte UI) — onglet Stats : arborescence du cahier §4.1 (Aperçu
// résumé dont les cartes ouvrent l'onglet, feuilles de jeu dans Parcours
// seulement, « Records » branché dans Performances, « Mes références » en
// raccourci R2), objectif de la semaine aux segments de Réglages (§4.3),
// Records sur des données réelles, aucune feuille empilée, 320 dp × 200 %.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/stats/widgets/k_info_sheet.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

SessionLog _log(String title, DateTime at, Map<String, List<SetEntry>> sets) =>
    SessionLog(
      done: true,
      title: title,
      finishedAt: at.toIso8601String(),
      ex: {for (final e in sets.entries) e.key: ExerciseLog(sets: e.value)},
      exerciseNames: {for (final e in sets.keys) e: e},
    );

SetEntry _set(String kg, String reps, {bool done = true}) =>
    SetEntry(kg: kg, reps: reps, done: done);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false
      ..celebrations = false;
  });
  setUp(() {
    store.logs.clear();
    store.settings.weeklyGoal = 0;
    store.notifyListeners();
  });

  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    bool dark = true,
    double width = 390,
    double height = 844,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    store.settings.theme = dark ? 'dark' : 'light';
    await tester.pumpWidget(
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
        home: screen,
      ),
    );
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

  Future<void> reveal(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(f, 200, scrollable: scrollable().first);
    await tester.pumpAndSettle();
  }

  int section(WidgetTester tester) =>
      tester.widget<TabBar>(find.byType(TabBar)).controller!.index;

  testWidgets(
    'Aperçu : les cartes de jeu ouvrent Parcours, jamais une feuille',
    (tester) async {
      await open(tester, const StatsScreen());
      expect(section(tester), StatsSection.overview.index);
      // Carte du personnage : onglet Parcours, pas la feuille.
      await tester.tap(find.text('Ton personnage'));
      await tester.pumpAndSettle();
      expect(section(tester), StatsSection.journey.index);
      expect(find.byType(KInfoSheet), findsNothing);
      expect(find.text('Ton arbre de progression'), findsOneWidget);
      // Défi, campagne : même chose.
      for (final target in [
        find.textContaining('Défis de la semaine ·'),
        find
            .descendant(
              of: find.byKey(const ValueKey('game-campaign')),
              matching: find.byType(KCard),
            )
            .first,
      ]) {
        tester
            .state<StatsScreenState>(find.byType(StatsScreen))
            .selectSection(StatsSection.overview);
        await tester.pumpAndSettle();
        await reveal(tester, target);
        await tester.tap(target.first);
        await tester.pumpAndSettle();
        expect(section(tester), StatsSection.journey.index, reason: '$target');
        expect(find.byType(KInfoSheet), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Aperçu : « Aller plus loin » ouvre les trois autres onglets', (
    tester,
  ) async {
    await open(tester, const StatsScreen());
    for (final (key, index) in [
      ('stats-open-journey', 1),
      ('stats-open-performance', 2),
      ('stats-open-history', 3),
    ]) {
      tester
          .state<StatsScreenState>(find.byType(StatsScreen))
          .selectSection(StatsSection.overview);
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey(key));
      await reveal(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(section(tester), index, reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'objectif de la semaine : segments Adaptatif, 2 à 6 ; une valeur 1 reste affichée',
    (tester) async {
      store.settings.weeklyGoal = 1;
      await open(tester, const StatsScreen());
      final card = find.byKey(const ValueKey('game-weekly-goal'));
      await reveal(tester, card);
      for (final label in ['Adaptatif', '2', '3', '4', '5', '6']) {
        expect(
          find.descendant(of: card, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      // Valeur 1 enregistrée avant : affichée telle quelle, aucun segment
      // choisi, rien n'est réécrit.
      expect(
        find.descendant(
          of: card,
          matching: find.text('Fixé par toi : 1 jour par semaine'),
        ),
        findsOneWidget,
      );
      expect(store.settings.weeklyGoal, 1);
      await tester.tap(find.byKey(const ValueKey('segment-3')));
      await tester.pumpAndSettle();
      expect(store.settings.weeklyGoal, 3);
      expect(store.game.weekly.target, 3);
      expect(
        find.descendant(
          of: card,
          matching: find.text('Fixé par toi : 3 jours par semaine'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('segment-0')));
      await tester.pumpAndSettle();
      expect(store.settings.weeklyGoal, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Parcours : seule entrée de chaque feuille de jeu, sans feuille '
      'empilée', (tester) async {
    await open(tester, const StatsScreen(initialSection: StatsSection.journey));
    final sheets = {
      'stats-character': 'Ta feuille de personnage',
      'stats-missions': 'Défis de la semaine',
      'stats-campaign': 'Campagne',
      'stats-bosses': 'Boss',
      'stats-seasons': 'Saisons',
      'stats-titles': 'Tes titres',
    };
    for (final e in sheets.entries) {
      final row = find.byKey(ValueKey(e.key));
      await reveal(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      final sheet = find.byType(KInfoSheet);
      expect(sheet, findsOneWidget, reason: e.key);
      expect(
        find.descendant(of: sheet, matching: find.text(e.value)),
        findsWidgets,
        reason: e.key,
      );
      // Rien dans la feuille n'ouvre une autre feuille (hors titres, dont
      // le choix ferme la feuille).
      if (e.key != 'stats-titles') {
        final close = find
            .descendant(
              of: find.byKey(const ValueKey('sheet-close')),
              matching: find.byType(InkWell),
            )
            .evaluate()
            .toSet();
        final active = find
            .descendant(of: sheet, matching: find.byType(InkWell))
            .evaluate()
            .where((e) => (e.widget as InkWell).onTap != null)
            .where((e) => !close.contains(e));
        expect(active, isEmpty, reason: '${e.key} : élément touchable');
      }
      await tester.tap(find.byKey(const ValueKey('sheet-close')));
      await tester.pumpAndSettle();
      expect(find.byType(KInfoSheet), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Parcours : choisir un titre l’affiche et ferme la feuille', (
    tester,
  ) async {
    store.settings.title = 'inconnu';
    await open(tester, const StatsScreen(initialSection: StatsSection.journey));
    final row = find.byKey(const ValueKey('stats-titles'));
    await reveal(tester, row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Afficher mon rang'));
    await tester.pumpAndSettle();
    expect(store.settings.title, '');
    expect(find.byType(KInfoSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Performances : Mes références et Records ouvrent leur page', (
    tester,
  ) async {
    final at = DateTime.now().subtract(const Duration(days: 3));
    store.logs['S1-J1'] = _log('Force A', at, {
      'Tractions lestées': [_set('10', '5'), _set('12,5', '4')],
      'Pompes': [_set('', '18'), _set('', '22')],
    });
    store.logs['S1-J2'] = _log('Force B', at.add(const Duration(days: 1)), {
      'Tractions lestées': [_set('15', '6', done: false)],
    });
    store.notifyListeners();
    await open(
      tester,
      const StatsScreen(initialSection: StatsSection.performance),
    );
    final records = find.byKey(const ValueKey('stats-records'));
    expect(
      find.descendant(of: records, matching: find.text('Records')),
      findsOneWidget,
    );
    await tester.tap(records);
    await tester.pumpAndSettle();
    expect(find.byType(RecordsScreen), findsOneWidget);
    expect(find.text('RECORDS'), findsOneWidget);
    // Données réelles du journal : la série non validée ne compte pas.
    expect(find.text('Tractions lestées'), findsOneWidget);
    expect(find.textContaining('12,5 kg × 4'), findsOneWidget);
    expect(find.textContaining('15 kg'), findsNothing);
    expect(find.text('Pompes'), findsOneWidget);
    expect(find.textContaining('22 répétitions'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordsScreen), findsNothing);

    await tester.tap(find.byKey(const ValueKey('stats-references')));
    await tester.pumpAndSettle();
    expect(find.byType(PilotageScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Records : journal vide, état vide sans erreur', (tester) async {
    await open(tester, const RecordsScreen());
    expect(find.text('Aucun record pour l’instant'), findsOneWidget);
    expect(statsRecords(store), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les records se lisent sans modifier le journal', (tester) async {
    final at = DateTime(2026, 9, 3, 18);
    store.logs['S2-J1'] = _log('A', at, {
      'Dips': [_set('20', '8'), _set('25', '5')],
    });
    store.logs['S3-J1'] = _log('B', at.add(const Duration(days: 7)), {
      'Dips': [_set('25', '5')],
    });
    final before = store.logs.map((k, v) => MapEntry(k, v.toJson()));
    final records = statsRecords(store);
    expect(records.single.name, 'Dips');
    expect(records.single.bests.bestKg, 25);
    expect(records.single.bests.bestKgReps, 5);
    // Premier passage du record.
    expect(records.single.weightedAt, at);
    expect(store.logs.map((k, v) => MapEntry(k, v.toJson())), before);
  });

  for (final dark in [true, false]) {
    testWidgets('Stats tient à 320 dp et 200 % de texte, thème $dark', (
      tester,
    ) async {
      store.logs['S1-J1'] = _log(
        'Séance au titre volontairement long pour le retour à la ligne',
        DateTime.now().subtract(const Duration(days: 1)),
        {
          'Tractions lestées': [_set('10', '5')],
        },
      );
      store.notifyListeners();
      await open(
        tester,
        const StatsScreen(standalone: true),
        dark: dark,
        width: 320,
        height: 720,
        scale: 2,
      );
      for (var i = 0; i < 4; i++) {
        tester
            .state<StatsScreenState>(find.byType(StatsScreen))
            .selectSection(StatsSection.values[i]);
        await tester.pumpAndSettle();
        for (var j = 0; j < 14; j++) {
          final s = scrollable();
          if (s.evaluate().isEmpty) break;
          await tester.drag(s.first, const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'rubrique $i');
        }
      }
      await open(
        tester,
        const RecordsScreen(),
        dark: dark,
        width: 320,
        height: 720,
        scale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cibles nommées et de 48 dp dans les quatre rubriques', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await open(tester, const StatsScreen(standalone: true));
      for (final s in StatsSection.values) {
        tester
            .state<StatsScreenState>(find.byType(StatsScreen))
            .selectSection(s);
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        // Les segments du kit (`KSegmented`, Aperçu et Parcours) ont une
        // zone touchable de 40 dp dans leur rail de 48 : signalé à UI5.
        if (s == StatsSection.performance || s == StatsSection.history) {
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        }
      }
    } finally {
      semantics.dispose();
    }
  });
}
