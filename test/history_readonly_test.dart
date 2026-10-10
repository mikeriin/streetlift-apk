import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart' show swipePage;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..autoTimer = false
      ..wakelock = false
      ..prefill = true;
  });
  setUp(() => store.logs.clear());

  Future<void> open(
    WidgetTester tester,
    SessionLog log, {
    String? sessionKey,
    bool dark = true,
  }) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(dark),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: SessionHistoryScreen(log: log, sessionKey: sessionKey),
      ),
    );
    await tester.pumpAndSettle();
  }

  String journals() =>
      jsonEncode(store.logs.map((k, v) => MapEntry(k, v.toJson())));

  for (final dark in [true, false]) {
    testWidgets(
      'historique : mêmes cartes, navigation et données intactes à 320 px, thème $dark',
      (tester) async {
        final day = store.program.week(8).day(4)!;
        final exs = day.exercises.take(2).toList();
        final log = store.sessionLog(8, 4)
          ..done = true
          ..finishedAt = '2026-09-19T17:30:00';
        for (final ex in exs) {
          log.exerciseNames[ex.id] = ex.name;
          log.ex[ex.id] = ExerciseLog(
            sets: [
              SetEntry()
                ..kg = '12,5'
                ..reps = '7'
                ..rir = '2'
                ..v = '0.55'
                ..done = true,
              SetEntry(),
            ],
            note: 'Note intacte',
            showKg: false,
            showRir: false,
            showV: false,
          );
        }
        await tester.runAsync(store.flush);
        final prefs = await SharedPreferences.getInstance();
        final persisted = {
          for (final key in prefs.getKeys()) key: prefs.get(key),
        };
        final before = journals();
        var writes = 0;
        void listener() => writes++;
        store.addListener(listener);
        addTearDown(() => store.removeListener(listener));
        await open(tester, log, dark: dark);
        expect(find.byType(SessionExercisePage), findsWidgets);
        expect(find.byType(EditableText), findsNothing);
        expect(find.byTooltip('Ajouter une série'), findsNothing);
        expect(find.byTooltip('Colonnes'), findsNothing);
        // G9 correction 1 : séance relue, séries validées en une ligne
        // (charge, répétitions, vitesse et flammes).
        expect(find.text('12,5 kg × 7 reps · 0,55 m/s'), findsOneWidget);
        expect(find.text('Note intacte'), findsOneWidget);
        expect(
          find.text('–'),
          findsWidgets,
        ); // les blancs ne sont pas préremplis
        // Toucher une valeur ou la coche ne peut pas changer la saisie.
        await tester.tap(find.text('12,5 kg × 7 reps · 0,55 m/s'));
        final check = find.byIcon(Icons.check);
        if (check.evaluate().isNotEmpty) await tester.tap(check.first);
        await swipePage(tester);
        await tester.tap(find.text('Exercices'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bilan de séance').last);
        await tester.pumpAndSettle();
        expect(find.text('2 / 4'), findsOneWidget);
        expect(find.byType(EditableText), findsNothing);
        await swipePage(tester, back: true);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(journals(), before);
        expect(writes, 0);
        expect({
          for (final key in prefs.getKeys()) key: prefs.get(key),
        }, persisted);
        expect(tester.takeException(), null);
      },
    );
  }

  testWidgets(
    'archive : nom et valeurs conservés sans inventer une prescription ou des unités',
    (tester) async {
      // Exercice absent du programme (archive d'une version antérieure).
      final log = SessionLog(
        done: true,
        title: 'Ancienne séance',
        exerciseNames: {'deleted': 'Mon exercice archivé'},
        ex: {
          'deleted': ExerciseLog(
            sets: [
              SetEntry()
                ..reps = '17'
                ..v = '0.42'
                ..done = true,
            ],
          ),
        },
      );
      final before = jsonEncode(log.toJson());
      await open(tester, log, sessionKey: 'archive-old');
      expect(find.text('MON EXERCICE ARCHIVÉ'), findsOneWidget);
      // G9 correction 2 : série en une ligne, valeurs telles quelles, sans
      // unité inventée.
      expect(find.text('17 · 0.42'), findsOneWidget);
      expect(find.textContaining('reps'), findsNothing);
      expect(find.text('REPS'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(store.logs, isEmpty);
      expect(jsonEncode(log.toJson()), before);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('une tenue historique garde ses secondes mais aucun chrono', (
    tester,
  ) async {
    final week = store.program.weeks.first;
    final day = week.days.firstWhere(
      (d) => d.exercises.any((e) => store.logSpec(e).kind == 'hold'),
    );
    final ex = day.exercises.firstWhere((e) => store.logSpec(e).kind == 'hold');
    final log = SessionLog(
      done: true,
      exerciseNames: {ex.id: ex.name},
      ex: {
        ex.id: ExerciseLog(
          sets: [
            SetEntry()
              ..reps = '32'
              ..done = true,
          ],
        ),
      },
    );
    await open(tester, log, sessionKey: store.sessionKey(week.n, day.j));
    // G9 correction 2 : série en une ligne, en secondes.
    expect(find.text('32 s'), findsOneWidget);
    expect(find.byTooltip('Compte à rebours'), findsNothing);
    expect(find.byIcon(Icons.hourglass_bottom), findsNothing);
    expect(find.textContaining('Lancer'), findsNothing);
    expect(store.logs, isEmpty);
    expect(tester.takeException(), null);
  });
}
