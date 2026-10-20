// Correctif 20/10/2026 (dev7.2.6) : drop set mécanique (« zone rouge ») :
// chaque palier nommé d'après la consigne, en secondes pour une tenue.
// Données synthétiques uniquement.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

const _cue =
    'Dernier exercice. Un tour = 4 paliers enchaînés en moins de 10 s : '
    '1. tractions pronation PdC jusqu’à RIR 1 → 2. rows australiens jusqu’à '
    'RIR 1 → 3. tenue menton au-dessus de la barre jusqu’à l’échec → 4. dead '
    'hang jusqu’à l’échec. Note les reps (paliers 1-2) et les secondes '
    '(paliers 3-4) sur chaque ligne. 3 min entre les tours.';

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

  test('paliers lus dans la consigne', () {
    final s = dropStages(_cue, 4)!;
    expect(s.map((x) => x.name), [
      'tractions pronation PdC',
      'rows australiens',
      'tenue menton au-dessus de la barre',
      'dead hang',
    ]);
    expect(s.map((x) => x.seconds), [false, false, true, true]);
    expect(s.first.target, 'jusqu’à RIR 1');
    expect(s.last.target, 'jusqu’à l’échec');
    // Nombre de paliers différent de la consigne : rien.
    expect(dropStages(_cue, 5), isNull);
    expect(dropStages('Enchaîne sans repos.', 4), isNull);
  });

  testWidgets('carte : palier nommé et unité sur chaque ligne', (tester) async {
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final week = WeekPlan.manual(
      n: 0,
      block: 'Zone rouge',
      color: const Color(0xFF4FA3C7),
      days: [
        DayPlan.manual(
          j: 9901,
          title: 'Zone rouge',
          exercises: [
            Exercise.manual(
              id: 'ZR-1',
              name: 'ZONE ROUGE — drop set mécanique tirage',
              setsText: '2 tours × 4 paliers',
              intensity: 'Échec sur les paliers 3 et 4',
              cue: _cue,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: SessionScreen(week: week, day: week.days.single),
      ),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(ValueKey('drop-stage-ZR-1-$i')), findsOneWidget);
    }
    expect(
      find.textContaining('1.1 · tractions pronation PdC'),
      findsOneWidget,
    );
    expect(find.textContaining('2.4 · dead hang'), findsOneWidget);
    expect(find.text('secondes'), findsNWidgets(4));
    expect(find.text('reps'), findsNWidgets(4));
    expect(find.text('Reps ou s'), findsOneWidget);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
