import 'dart:convert';
import 'dart:io' show gzip;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
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
    // G2 : séance du programme (les séances perso n'existent plus).
    final week = WeekPlan.manual(
      n: 8,
      block: 'Test saisie',
      color: const Color(0xFF4FA3C7),
      days: [
        DayPlan.manual(
          j: 1,
          title: 'Test saisie',
          exercises: [
            Exercise.manual(
              id: 'T-999-0',
              name: 'Pompes',
              setsText: '1×8',
              forcedSets: 1,
            ),
          ],
        ),
      ],
    );
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
    final log = SessionLog.fromJson(saved['logs']['S8-J1']);
    expect(log.ex.values.single.sets.single.reps, '12');
    expect(log.ex.values.single.note, 'Saisie conservée');
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
