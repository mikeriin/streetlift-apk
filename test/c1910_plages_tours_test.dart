// Correctif 19/10/2026 (dev7.2.3) : plage de répétitions sans
// pré-remplissage (haut de la plage en indication et mis en avant dans le
// volume) ; tours d'une carte d'exercices enchaînés intitulés et séparés.
// Données synthétiques uniquement (séance construite à la main).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/session_adapt.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

Widget _page(Widget child) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

WeekPlan _week(int j, String name, List<Exercise> exercises) => WeekPlan.manual(
  n: 0,
  block: name,
  color: const Color(0xFF4FA3C7),
  days: [DayPlan.manual(j: j, title: name, exercises: exercises)],
);

Exercise _exercise(String id, String name, String sets, {int count = 1}) =>
    Exercise.manual(id: id, name: name, setsText: sets, forcedSets: count);

/// Répétitions écrites dans la série [i] de l'exercice [k] du jour.
String _reps(WeekPlan week, int k, int i) {
  final day = week.days.single;
  return store.exLog(week.n, day.j, day.exercises[k]).sets[i].reps;
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
      ..autoTimer = false
      ..prefill = true;
  });

  group('plage de répétitions', () {
    test('lecture du volume', () {
      expect(repRangeOf('1 × 15-21'), (15, 21));
      expect(repRangeOf('3×9–15'), (9, 15));
      expect(repRangeOf('2 × 8-12 reps'), (8, 12));
      expect(repRangeOf('3×8'), isNull);
      expect(repRangeOf('4×12-10-8'), isNull);
      expect(repRangeOf('3×8-10-12'), isNull);
      expect(repRangeOf('3×30-45 s'), isNull);
      expect(repRangeOf('1×15-20 puis 4×(4)'), isNull);
      expect(repRangeOf('3-4 min'), isNull);
    });

    test('cible de Koach : champ vide, haut de plage gardé', () {
      const range = SetGoal(low: 15, high: 21);
      expect(range.repRange, isTrue);
      expect(range.fieldPrefill, isNull);
      expect(range.prefill, 15);
      const fixed = SetGoal(low: 8, high: 8);
      expect(fixed.repRange, isFalse);
      expect(fixed.fieldPrefill, 8);
      const hold = SetGoal(low: 30, high: 45, seconds: true);
      expect(hold.repRange, isFalse);
      expect(hold.fieldPrefill, 30);
      const max = SetGoal(low: 1, high: 999);
      expect(max.repRange, isFalse);
    });

    testWidgets('séance : rien de pré-rempli, « max 21 » en indication', (
      tester,
    ) async {
      _size(tester);
      final week = _week(9701, 'Plage', [
        _exercise('PL-1', 'Face pulls (poulie)', '2×15-21', count: 2),
      ]);
      final day = week.days.single;
      await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      expect(_reps(week, 0, 0), isEmpty);
      expect(_reps(week, 0, 1), isEmpty);
      expect(find.text('max 21'), findsWidgets);
      expect(find.byKey(const ValueKey('range-volume-PL-1')), findsOneWidget);
      expect(find.textContaining('21 max', findRichText: true), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('reps fixes : toujours pré-remplies', (tester) async {
      _size(tester);
      final week = _week(9702, 'Fixe', [
        _exercise('PL-3', 'Curl marteau', '3×10', count: 3),
      ]);
      final day = week.days.single;
      await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      expect(_reps(week, 0, 0), '10');
      expect(find.textContaining('max'), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });

  testWidgets('enchaînement : chaque tour intitulé et séparé', (tester) async {
    _size(tester);
    final week = _week(9703, 'Tours', [
      _exercise('TR-1', 'Face pulls (poulie)', '1×15-21'),
      _exercise('TR-2', 'Curl marteau enchaîné', '3×10', count: 3),
    ]);
    final day = week.days.single;
    await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-card-merged')), findsOneWidget);
    for (final n in [1, 2, 3]) {
      expect(find.byKey(ValueKey('merged-round-$n')), findsOneWidget);
      expect(find.text('Tour $n'), findsOneWidget);
    }
    double y(Finder f) => tester.getTopLeft(f).dy;
    // A·1 et B·1 sous « Tour 1 », B·2 sous « Tour 2 », B·3 sous « Tour 3 ».
    final round2 = y(find.byKey(const ValueKey('merged-round-2')));
    final round3 = y(find.byKey(const ValueKey('merged-round-3')));
    expect(y(find.byKey(const ValueKey('set-check-TR-2-0'))), lessThan(round2));
    expect(
      y(find.byKey(const ValueKey('set-check-TR-2-1'))),
      allOf(greaterThan(round2), lessThan(round3)),
    );
    expect(
      y(find.byKey(const ValueKey('set-check-TR-2-2'))),
      greaterThan(round3),
    );
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
