import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:flutter/services.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/estimate_view.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/ui_capture.dart' show loadUiFonts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // UI1 : polices réelles (Barlow) : les mesures de mise en page (semaine
    // entière visible, L5) se font sur le rendu du téléphone, pas sur la
    // police de test où chaque lettre est un carré (les titres, jamais
    // coupés depuis C3, y passeraient tous sur deux lignes).
    await loadUiFonts();
    SharedPreferences.setMockInitialValues({});
    await store.init();
    // L4 : ces parcours portent sur une installation existante, sur le
    // calendrier d'origine (départ 13/07/2026).
    store.program.start = DateTime(2026, 7, 13);
    store.startOrigin = 'migration';
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });
  setUp(() => store.logs.clear());

  Future<void> open(
    WidgetTester tester, {
    double width = 360,
    double height = 760,
    double scale = 1,
    bool dark = true,
    int day = 4,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
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
        home: RootNav(referenceDate: store.program.dateFor(8, day)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealCard(WidgetTester tester, int day) async {
    final scrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('programme-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('programme-day-$day')),
      220,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sept cartes accessibles, séance du jour développée et appui court direct',
    (tester) async {
      await open(tester);
      expect(find.text('S8'), findsOneWidget);
      expect(find.textContaining('AUJOURD’HUI'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byType(MuscleMap2D), findsOneWidget);
      // 5.10.1 : carte du jour aux couleurs de l'Anatomie (non teintée)
      expect(tester.widget<MuscleMap2D>(find.byType(MuscleMap2D)).tint, isNull);
      for (final caption in ['AVANT', 'ARRIÈRE', 'ARRIERE', 'FACE', 'DOS']) {
        expect(find.text(caption), findsNothing);
      }
      expect(
        tester.getSize(find.byKey(const ValueKey('programme-day-4'))).height,
        greaterThan(100),
      );
      for (final j in [1, 2, 3, 4, 5, 6, 7]) {
        await revealCard(tester, j);
        final card = find.byKey(ValueKey('programme-day-$j'));
        expect(card, findsOneWidget);
        expect(tester.getSize(card).height, greaterThanOrEqualTo(44));
      }
      expect(
        find.byKey(const ValueKey('programme-day-7')).hitTestable(),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('programme-day-7'))).bottom,
        lessThan(tester.getRect(find.byType(HeroNavBar)).top),
      );
      await revealCard(tester, 2);
      await revealCard(tester, 2);
      await tester.tap(find.byKey(const ValueKey('programme-day-2')));
      await tester.pumpAndSettle();
      final session = tester.widget<SessionScreen>(find.byType(SessionScreen));
      expect(session.week.n, 8);
      expect(session.day.j, 2);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'la semaine complète reste visible et ordonnée, avec ses statuts',
    (tester) async {
      store.sessionLog(8, 1).done = true;
      store.sessionLog(8, 2).done = true;
      await open(tester, width: 390, height: 844);
      final dockTop = tester.getRect(find.byType(HeroNavBar)).top;
      var previousBottom = 0.0;
      for (var day = 1; day <= 7; day++) {
        final card = find.byKey(ValueKey('programme-day-$day'));
        final rect = tester.getRect(card);
        expect(
          card.hitTestable(),
          findsOneWidget,
          reason: 'J$day : $rect ; dock à $dockTop',
        );
        expect(rect.top, greaterThanOrEqualTo(previousBottom));
        expect(rect.bottom, lessThan(dockTop));
        // UI1 : ligne de jour de 48 dp (56 pour un titre sur deux lignes,
        // jamais coupé, C3) ; la semaine entière reste visible (L5).
        if (day != 4) expect(rect.height, lessThanOrEqualTo(56));
        final expected = day <= 2
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded;
        expect(
          find.descendant(of: card, matching: find.byIcon(expected)),
          findsOneWidget,
        );
        previousBottom = rect.bottom;
      }
      expect(find.text('Niv.'), findsOneWidget);
      expect(find.text('Ouvrir la séance'), findsNothing);
      expect(find.byTooltip('Semaine précédente'), findsNothing);
      expect(find.byTooltip('Semaine suivante'), findsNothing);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('appui long sur le slider choisit directement une semaine', (
    tester,
  ) async {
    await open(tester);
    await tester.longPress(find.byKey(const ValueKey('selected-week')));
    await tester.pumpAndSettle();
    expect(find.text('Choisir une semaine'), findsOneWidget);
    // UI1 : feuille de liste du kit, ouverte sur la semaine affichée (S8) ;
    // « Semaine 9 », dates et bloc dessous.
    await tester.tap(find.text('Semaine 9'));
    await tester.pumpAndSettle();
    expect(find.text('S9'), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byType(SessionScreen), findsNothing);
    expect(tester.takeException(), null);
  });

  testWidgets(
    'appui court sur une séance faite ouvre son historique sans modifier les saisies',
    (tester) async {
      final exercise = store.program.week(8).day(2)!.exercises.first;
      final entry = store.exLog(8, 2, exercise);
      entry.sets.first
        ..kg = '12.5'
        ..reps = '7'
        ..done = true;
      entry.note = 'Note conservée';
      final log = store.sessionLog(8, 2)
        ..done = true
        ..title = 'S8 · J2';
      final before = jsonEncode(log.toJson());
      await open(tester);
      await revealCard(tester, 2);
      await tester.tap(find.byKey(const ValueKey('programme-day-2')));
      await tester.pumpAndSettle();
      expect(find.byType(SessionHistoryScreen), findsOneWidget);
      expect(find.byType(SessionScreen), findsNothing);
      // G9 correction 2 : séries en une ligne en relecture.
      expect(find.text('12,5 kg × 7 reps'), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Note conservée'), findsOneWidget);
      expect(jsonEncode(log.toJson()), before);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'appui long sur une carte compacte ouvre le résumé sans lancer ni effacer',
    (tester) async {
      final log = store.sessionLog(8, 1)..title = 'À conserver';
      final before = jsonEncode(log.toJson());
      await open(tester);
      await revealCard(tester, 1);
      await tester.longPress(find.byKey(const ValueKey('programme-day-1')));
      await tester.pumpAndSettle();
      expect(find.text('Résumé · S8 · J1'), findsOneWidget);
      expect(find.byType(EstimateView), findsOneWidget);
      expect(find.byType(SessionScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(jsonEncode(store.sessionLog(8, 1).toJson()), before);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'appui court ouvre le détail ; glisser atteint les bornes sans ouvrir de fiche',
    (tester) async {
      await open(tester);
      final label = find.byKey(const ValueKey('selected-week'));
      await tester.tapAt(tester.getCenter(label));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('Semaine 8'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.textContaining('journées validées'),
        ),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byType(DraggableScrollableSheet))).pop();
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getCenter(label), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(find.text('S40'), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      await tester.tapAt(tester.getCenter(label));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('Semaine 40'),
        ),
        findsOneWidget,
      );
      Navigator.of(tester.element(find.byType(DraggableScrollableSheet))).pop();
      await tester.pumpAndSettle();
      await tester.dragFrom(tester.getCenter(label), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('S1'), findsOneWidget);
      await tester.tapAt(tester.getCenter(label));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('Semaine 1'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'la fiche semaine donne accès au choix de semaine et conserve les gestes des cartes',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('selected-week')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Choisir une semaine'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Choisir une semaine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semaine 9'));
      await tester.pumpAndSettle();
      expect(find.text('S9'), findsOneWidget);
      expect(find.byType(MuscleMap2D), findsNothing);
      await revealCard(tester, 2);
      await tester.longPress(find.byKey(const ValueKey('programme-day-2')));
      await tester.pumpAndSettle();
      expect(find.text('Résumé · S9 · J2'), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'balayage, clavier et conservation de la semaine dans les onglets',
    (tester) async {
      await open(tester);
      final body = find.byKey(const ValueKey('programme-weeks'));
      await tester.drag(body, const Offset(-160, 0));
      await tester.pumpAndSettle();
      expect(find.text('S9'), findsOneWidget);
      await tester.drag(body, const Offset(160, 0));
      await tester.pumpAndSettle();
      expect(find.text('S8'), findsOneWidget);
      final slider = find.byKey(const ValueKey('week-slider'));
      Focus.of(tester.element(slider)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('S9'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.drag(body, const Offset(-180, 0));
      await tester.pumpAndSettle();
      expect(find.text('S40'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.drag(body, const Offset(180, 0));
      await tester.pumpAndSettle();
      expect(find.text('S1'), findsOneWidget);
      for (final i in [0, 1, 3, 2]) {
        await tester.tap(find.byKey(ValueKey('nav-$i')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
      }
      expect(find.text('S1'), findsOneWidget);
      final footer = find.byType(HeroNavBar);
      expect(
        find.descendant(of: footer, matching: find.byType(Text)),
        findsNWidgets(4),
      );
      expect(
        find.descendant(of: footer, matching: find.byType(BackdropFilter)),
        findsWidgets,
      );
      final bounds = tester.getRect(
        find.byKey(const PageStorageKey('programme-scroll')),
      );
      expect(bounds.bottom, greaterThan(tester.getRect(footer).top));
      // Le focus est volontairement géré par chaque onglet ; réactivation explicite.
      Focus.of(tester.element(slider)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text('Semaine 1'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('la navigation libère la place du clavier dans STATS', (
    tester,
  ) async {
    await open(tester, width: 320, scale: 1.3);
    await tester.tap(find.byKey(const ValueKey('nav-1')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(HeroNavBar), findsNothing);
    expect(tester.takeException(), null);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(HeroNavBar), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    expect(find.text('S8'), findsOneWidget);
    expect(tester.takeException(), null);
  });

  for (final dark in [true, false]) {
    testWidgets('résumé à 320 px avec texte 130 %, thème $dark', (
      tester,
    ) async {
      await open(tester, width: 320, scale: 1.3, dark: dark);
      await revealCard(tester, 4);
      await tester.longPressAt(
        tester.getTopLeft(find.byKey(const ValueKey('programme-day-4'))) +
            const Offset(30, 30),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EstimateView), findsOneWidget);
      expect(find.text('Effort'), findsOneWidget);
      expect(find.text('Repos'), findsOneWidget);
      expect(tester.takeException(), null);
    });
  }

  testWidgets(
    'un jour de récupération garde un résumé lisible et reste ouvrable',
    (tester) async {
      await open(tester, day: 7);
      await revealCard(tester, 7);
      await tester.longPress(find.byKey(const ValueKey('programme-day-7')));
      await tester.pumpAndSettle();
      expect(find.text('Résumé · S8 · J7'), findsOneWidget);
      expect(find.byType(EstimateView), findsNothing);
      expect(tester.takeException(), null);
      Navigator.of(tester.element(find.text('Résumé · S8 · J7'))).pop();
      await tester.pumpAndSettle();
      await revealCard(tester, 7);
      await tester.tap(find.byKey(const ValueKey('programme-day-7')));
      await tester.pumpAndSettle();
      expect(find.byType(SessionScreen), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      store.sessionLog(8, 7).done = true;
      await open(tester, day: 7);
      await revealCard(tester, 7);
      await tester.tap(find.byKey(const ValueKey('programme-day-7')));
      await tester.pumpAndSettle();
      expect(find.byType(SessionHistoryScreen), findsOneWidget);
      expect(
        find.text('Aucune série enregistrée pour cette séance.'),
        findsOneWidget,
      );
      expect(tester.takeException(), null);
    },
  );
}
