import 'dart:convert';
import 'dart:io' show gzip;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

Widget app(Widget page) => MaterialApp(theme: buildTheme(true), home: page);
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
  testWidgets('saisie et notes sont enregistrées sans changer de page', (
    tester,
  ) async {
    final session = CustomSession(
      id: '999',
      name: 'Test saisie',
      items: [
        CustomExercise(name: 'Pompes', p: {'series': 1, 'reps': 8}),
      ],
    );
    store.upsertSession(session);
    final week = session.toWeekPlan();
    await tester.pumpWidget(
      app(SessionScreen(week: week, day: week.days.single)),
    );
    await tester.enterText(find.byType(TextField).first, '12');
    await tester.tap(
      find.byKey(
        ValueKey('${week.days.single.exercises.single.id}-note-toggle'),
      ),
    );
    await tester.pump();
    final notes = find.byType(TextField).last;
    await tester.enterText(notes, 'Saisie conservée');
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString('kalis_state_v3')!;
    if (raw.startsWith('gz:')) {
      raw = utf8.decode(gzip.decode(base64Decode(raw.substring(3))));
    }
    final saved = jsonDecode(raw);
    final log = SessionLog.fromJson(saved['logs']['S0-J999']);
    expect(log.ex.values.single.sets.single.reps, '12');
    expect(log.ex.values.single.note, 'Saisie conservée');
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
