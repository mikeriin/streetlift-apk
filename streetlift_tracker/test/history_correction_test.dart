import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

const _finished = '2026-09-19T17:30:00';

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
  setUp(() {
    store.logs.clear();
    store.consumeReward();
  });

  SessionLog doneLog() {
    final ex = store.program.week(8).day(4)!.exercises.first;
    final log =
        store.sessionLog(8, 4)
          ..done = true
          ..finishedAt = _finished;
    log.exerciseNames[ex.id] = ex.name;
    log.ex[ex.id] = ExerciseLog(
      sets: [
        SetEntry()
          ..kg = '12,5'
          ..reps = '7'
          ..done = true,
      ],
    );
    return log;
  }

  Future<void> open(
    WidgetTester tester,
    SessionLog log, {
    String? sessionKey,
  }) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final history = SessionHistoryScreen(log: log, sessionKey: sessionKey);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => history),
                        ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await tester.runAsync(store.flush);
  }

  test('rouvrir puis revalider garde la date et les saisies', () {
    final log = doneLog();
    final key = store.sessionKey(8, 4);
    expect(store.correctionPlan(key)?.day.j, 4);
    expect(store.reopenSession(key), isTrue);
    expect(store.reopenSession(key), isFalse);
    expect(store.isDone(8, 4), isFalse);
    expect(store.correctionPlan(key), isNull);
    expect(log.finishedAt, _finished);
    expect(log.ex.values.single.sets.single.kg, '12,5');
    store.markSessionDone(8, 4, true, title: 'S8 · J4');
    expect(store.isDone(8, 4), isTrue);
    expect(log.finishedAt, _finished);
    // « Repasser en à faire » depuis la séance efface toujours la date.
    store.markSessionDone(8, 4, false);
    expect(log.finishedAt, isNull);
  });

  test('annuler une suppression n’écrase pas une séance reprise', () {
    final log = doneLog();
    final key = store.sessionKey(8, 4);
    expect(store.deleteLog(key), same(log));
    expect(store.logs.containsKey(key), isFalse);
    expect(store.deleteLog(key), isNull);
    expect(store.restoreLog(key, log), isTrue);
    expect(store.logs[key], same(log));
    store.deleteLog(key);
    final restarted = store.sessionLog(8, 4);
    expect(store.restoreLog(key, log), isFalse);
    expect(store.logs[key], same(restarted));
  });

  test('archive, repos ou séance perso disparue : suppression seule', () {
    store.logs['S0-J999'] = SessionLog(done: true);
    store.logs['S0-J999@old'] = SessionLog(done: true);
    expect(store.correctionPlan('S0-J999'), isNull);
    expect(store.correctionPlan('S0-J999@old'), isNull);
    expect(store.correctionPlan('S8-J4'), isNull);
    String? rest;
    for (final week in store.program.weeks) {
      for (final day in week.days) {
        if (day.exercises.isEmpty) rest ??= store.sessionKey(week.n, day.j);
      }
    }
    if (rest != null) {
      store.logs[rest] = SessionLog(done: true);
      expect(store.correctionPlan(rest), isNull);
    }
  });

  test('une séance perso existante peut être rouverte', () {
    final session = CustomSession(
      id: store.newSessionId(),
      name: 'Tractions',
      items: [CustomExercise(name: 'Tractions')],
    );
    store.upsertSession(session);
    addTearDown(() => store.deleteSession(session));
    final key = 'S0-J${session.id}';
    store.logs[key] = SessionLog(done: true, customId: session.id);
    final plan = store.correctionPlan(key);
    expect(plan?.week.n, 0);
    expect(plan?.day.j, int.parse(session.id));
    expect(plan?.day.exercises.single.name, 'Tractions');
  });

  testWidgets('le bilan rouvre la séance modifiable', (tester) async {
    final log = doneLog();
    await open(tester, log);
    await tester.tap(find.text('Exercices'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bilan de séance').last);
    await tester.pumpAndSettle();
    final correct = find.text('Corriger les saisies');
    await tester.ensureVisible(correct);
    await tester.pumpAndSettle();
    await tester.tap(correct);
    await tester.pumpAndSettle();
    expect(find.text('Corriger cette séance ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Corriger'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionHistoryScreen), findsNothing);
    expect(find.byType(SessionScreen), findsOneWidget);
    expect(find.byType(EditableText), findsWidgets);
    expect(store.isDone(8, 4), isFalse);
    expect(log.finishedAt, _finished);
    expect(log.ex.values.single.sets.single.reps, '7');
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('annuler la correction ne modifie rien', (tester) async {
    final log = doneLog();
    await open(tester, log);
    await tester.tap(find.byTooltip('Options de l’historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corriger les saisies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionHistoryScreen), findsOneWidget);
    expect(store.isDone(8, 4), isTrue);
    expect(find.byType(EditableText), findsNothing);
    await close(tester);
  });

  testWidgets('supprimer puis annuler restaure la séance', (tester) async {
    final log = doneLog();
    final key = store.sessionKey(8, 4);
    await open(tester, log);
    await tester.tap(find.byTooltip('Options de l’historique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer de l’historique'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer de l’historique ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(store.logs.containsKey(key), isFalse);
    expect(find.byType(SessionHistoryScreen), findsNothing);
    expect(find.text('Ouvrir'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(store.logs[key], same(log));
    expect(store.isDone(8, 4), isTrue);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('une archive se supprime sans correction', (tester) async {
    final log = SessionLog(
      done: true,
      title: 'Ancien WOD',
      customId: '999',
      exerciseNames: {'old': 'Mon exercice archivé'},
      ex: {
        'old': ExerciseLog(
          sets: [
            SetEntry()
              ..reps = '5'
              ..done = true,
          ],
        ),
      },
    );
    store.logs['S0-J999@old'] = log;
    await open(tester, log, sessionKey: 'S0-J999@old');
    await tester.tap(find.byTooltip('Options de l’historique'));
    await tester.pumpAndSettle();
    final item = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Corriger les saisies'),
    );
    expect(item.enabled, isFalse);
    expect(
      find.text('Supprimer de l’historique'),
      findsOneWidget,
    );
    await close(tester);
  });

  testWidgets('hors journal, aucune action d’écriture', (tester) async {
    final log = SessionLog(done: true, title: 'Hors journal');
    await open(tester, log, sessionKey: 'archive-absente');
    expect(find.byTooltip('Options de l’historique'), findsNothing);
    expect(find.text('Corriger les saisies'), findsNothing);
    await close(tester);
  });
}
