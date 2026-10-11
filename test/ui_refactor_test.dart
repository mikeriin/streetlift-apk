import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/arsenal_screen.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart' show swipePage;
import 'support/ui_capture.dart' show loadUiFonts;

Widget page(Widget child, {bool dark = true, double textScale = 1.3}) =>
    MaterialApp(
      theme: buildTheme(dark),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: child,
    );
void small(WidgetTester tester, {Size size = const Size(320, 720)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Séance d'un seul jour construite à la main (semaine 0), pour éprouver le
/// runner hors programme : les séances manuelles ont disparu en G2.
WeekPlan manualWeek(int j, String name, List<Exercise> exercises) =>
    WeekPlan.manual(
      n: 0,
      block: name,
      color: const Color(0xFF4FA3C7),
      days: [DayPlan.manual(j: j, title: name, exercises: exercises)],
    );

Exercise manualExercise(
  String id,
  String name,
  String sets, {
  double? kg,
  int? hold,
}) {
  return Exercise.manual(
    id: id,
    name: name,
    setsText: sets,
    kg: kg,
    forcedSets: 1,
    timer: hold == null ? null : {'type': 'hold', 'sec': hold},
  );
}

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

  testWidgets(
    'les onglets et le changement de thème conservent la semaine choisie',
    (tester) async {
      small(tester);
      await tester.pumpWidget(const SLApp());
      await tester.pumpAndSettle();
      final initialState = tester.state(find.byType(HomeScreen));
      await tester.drag(
        find.byKey(const ValueKey('week-slider')),
        const Offset(-40, 0),
      );
      await tester.pumpAndSettle();
      final week = tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('selected-week')),
              matching: find.byType(Text),
            ),
          )
          .data;
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();
      expect(find.text(week!), findsOneWidget);
      expect(tester.state(find.byType(HomeScreen)), same(initialState));
      await tester.tap(find.byKey(const ValueKey('nav-3')));
      await tester.pumpAndSettle();
      // UI4 : le thème se règle dans Réglages › Apparence.
      await tester.tap(find.byKey(const ValueKey('settings-page-appearance')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clair'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retour').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-2')));
      await tester.pumpAndSettle();
      expect(find.text(week), findsOneWidget);
      expect(tester.state(find.byType(HomeScreen)), same(initialState));
      expect(
        Theme.of(tester.element(find.byType(HomeScreen))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'cartes, notes et saisies survivent aux boutons et au sélecteur d’exercices',
    (tester) async {
      small(tester);
      final week = manualWeek(993, 'Deux exercices', [
        manualExercise('CU-993-0', 'Pompes', '1×8'),
        manualExercise('CU-993-1', 'Squat', '1×10'),
      ]);
      final day = week.days.single;
      await tester.pumpWidget(page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      final first = day.exercises.first;
      expect(find.byKey(ValueKey('exercise-card-${first.id}')), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '14');
      await tester.tap(find.byKey(ValueKey('${first.id}-note-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(ValueKey('${first.id}-note')),
        'Première note',
      );
      await tester.tap(find.byKey(ValueKey('${first.id}-note-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('${first.id}-note')), findsNothing);
      await tester.tap(find.byKey(ValueKey('${first.id}-note-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Première note'), findsOneWidget);
      await swipePage(tester);
      final second = day.exercises.last;
      await tester.tap(find.byKey(ValueKey('${second.id}-note-toggle')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(ValueKey('${second.id}-note')),
        'Seconde note',
      );
      await swipePage(tester, back: true);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Première note'), findsOneWidget);
      await tester.tap(find.text('Exercices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bilan de séance').last);
      await tester.pumpAndSettle();
      expect(find.text('Terminer la séance'), findsOneWidget);
      expect(store.exLog(week.n, day.j, first).note, 'Première note');
      expect(store.exLog(week.n, day.j, second).note, 'Seconde note');
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('les exercices enchaînés ont chacun leur carte et leur note', (
    tester,
  ) async {
    small(tester);
    final week = manualWeek(995, 'Enchaînement', [
      manualExercise('CU-995-0', 'Dips', '1×8'),
      manualExercise('CU-995-1', 'Pompes enchaînées', '1×10'),
    ]);
    final day = week.days.single;
    expect(store.groups(day).single.length, 2);
    await tester.pumpWidget(page(SessionScreen(week: week, day: day)));
    await tester.pumpAndSettle();
    for (var i = 0; i < day.exercises.length; i++) {
      final note = find.byKey(ValueKey('${day.exercises[i].id}-note'));
      final toggle = find.byKey(ValueKey('${day.exercises[i].id}-note-toggle'));
      await tester.scrollUntilVisible(
        toggle.hitTestable(),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.enterText(note, 'Note exercice $i');
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('exercise-card-${day.exercises[i].id}')),
        findsOneWidget,
      );
    }
    await swipePage(tester);
    for (var i = 0; i < day.exercises.length; i++) {
      expect(
        store.exLog(week.n, day.j, day.exercises[i]).note,
        'Note exercice $i',
      );
    }
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('les séances suivent une rotation et une grande largeur', (
    tester,
  ) async {
    small(tester, size: const Size(640, 360));
    final week = manualWeek(996, 'Rotation', [
      manualExercise('CU-996-0', 'Gainage', '1×60 s', hold: 60),
    ]);
    for (final size in [const Size(640, 360), const Size(1024, 768)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        page(SessionScreen(week: week, day: week.days.single)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), null, reason: 'séance à $size');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });

  for (final dark in [true, false]) {
    testWidgets('écrans et formulaires à 320 px, texte 130 %, thème $dark', (
      tester,
    ) async {
      small(tester);
      final week = manualWeek(991, 'Force personnelle', [
        manualExercise('CU-991-0', 'Tractions', '1×6', kg: 12.5),
      ]);
      final day = week.days.single;
      final log = store.exLog(week.n, day.j, day.exercises.first)
        ..showKg = true
        ..showRir = true
        ..showV = true;
      log.note = 'Test des notes';
      for (final screen in <Widget>[
        const RootNav(),
        const ArsenalScreen(),
        const PilotageScreen(),
        const SettingsScreen(),
        const RecordsScreen(),
        SessionScreen(week: week, day: day),
        SessionHistoryScreen(log: store.sessionLog(week.n, day.j)),
      ]) {
        await tester.pumpWidget(page(screen, dark: dark));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          null,
          reason: '${screen.runtimeType}, au chargement',
        );
        final lists = find.byType(ListView);
        if (lists.evaluate().isNotEmpty) {
          for (var i = 0; i < 8; i++) {
            await tester.drag(lists.first, const Offset(0, -360));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              null,
              reason: '${screen.runtimeType}, après défilement',
            );
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets(
    'cinq séries, charge et effort restent visibles sans défilement',
    (tester) async {
      // UI2 : mesure avec les polices réelles (Barlow) : la police de test
      // (un carré par caractère) élargit chaque mot et fait passer à la
      // ligne titres et puces qui tiennent sur une ligne sur le téléphone ;
      // le tableau des séries a maintenant des champs de 48 dp (C13).
      await loadUiFonts();
      small(tester, size: const Size(360, 760));
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPadding);
      final week = store.program.week(8);
      final day = week.day(1)!;
      store.clearSession(8, 1);
      final exercise = day.exercises.first;
      final log = store.exLog(8, 1, exercise)..showRir = true;
      expect(log.sets.length, 5);
      await tester.pumpWidget(
        page(SessionScreen(week: week, day: day), textScale: 1),
      );
      await tester.pumpAndSettle();
      final list = find.byType(ListView).first;
      final viewport = tester.getRect(list);
      for (var i = 0; i < 5; i++) {
        final row = find.byKey(ValueKey('${exercise.id}-$i-0'));
        final button = find.byTooltip('Valider la série ${i + 1}');
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.getRect(row).top, greaterThanOrEqualTo(viewport.top));
        expect(tester.getRect(row).bottom, lessThanOrEqualTo(viewport.bottom));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
      }
      expect(find.byKey(ValueKey('${exercise.id}-note')), findsNothing);
      expect(
        find.byKey(ValueKey('${exercise.id}-note-toggle')).hitTestable(),
        findsOneWidget,
      );
      final instruction = find.byKey(ValueKey('${exercise.id}-instructions'));
      await tester.tap(instruction);
      await tester.pumpAndSettle();
      expect(find.text(exercise.cue), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      // Les marges autour d’une cellule fine restent une zone de saisie.
      final firstRow = find.byKey(ValueKey('${exercise.id}-0-0'));
      final loadField = find
          .descendant(of: firstRow, matching: find.byType(TextField))
          .first;
      final fieldRect = tester.getRect(loadField);
      await tester.tapAt(Offset(fieldRect.center.dx, fieldRect.top - 2));
      await tester.pump();
      final field = tester.widget<TextField>(loadField);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(field.controller!.selection.baseOffset, 0);
      expect(
        field.controller!.selection.extentOffset,
        field.controller!.text.length,
      );
      tester.testTextInput.enterText('3.75');
      await tester.pump();
      expect(log.sets.first.kg, '3.75');
      field.focusNode!.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Valider la série 5'));
      await tester.pumpAndSettle();
      // G9 correction 1 : la ligne des flammes s'ouvre sous la série.
      expect(find.byKey(const ValueKey('flame-track-5')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('flame-pos-7')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('flame-pos-7')));
      await tester.pumpAndSettle();
      expect(log.sets.last.done, isTrue);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('les actions de sauvegarde ouvrent l’export et l’import', (
    tester,
  ) async {
    small(tester);
    String? clipboard;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.pumpWidget(page(const SettingsScreen()));
    await tester.pumpAndSettle();
    // UI4 : les sauvegardes sont dans « Données et confidentialité ».
    await tester.scrollUntilVisible(
      find.text('Données et confidentialité'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Données et confidentialité'));
    await tester.pumpAndSettle();
    expect(find.text('Sauvegardes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Copier la sauvegarde'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    // L5 : titre de page sans mot coupé, la page est plus courte ; le
    // défilement par pas peut s'arrêter sur un élément construit mais sous
    // le bord de l'écran. On l'amène réellement à l'écran avant l'appui.
    await tester.ensureVisible(find.text('Copier la sauvegarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copier la sauvegarde'));
    await tester.pumpAndSettle();
    expect(clipboard, store.exportCompact());
    expect(
      find.text('Sauvegarde copiée dans le presse-papiers.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Coller une sauvegarde'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Coller une sauvegarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coller une sauvegarde'));
    await tester.pumpAndSettle();
    // UI4 : le dialogue devient une sous-page (titre = libellé, R3) ;
    // « Retour » n'importe rien.
    expect(find.byType(PasteBackupPage), findsOneWidget);
    expect(find.text('Colle le texte exporté ici'), findsOneWidget);
    expect(find.text('Voir l’aperçu'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour').last);
    await tester.pumpAndSettle();
    expect(find.byType(PasteBackupPage), findsNothing);
    expect(find.text('Coller une sauvegarde'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
