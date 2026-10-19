// Correctif 20/10/2026 (dev7.2.4) : GtG hors séance (carte du jour,
// rappels toutes les 2 h), accessoires servis en plage par Koach 1.0,
// charge en grand = cible de la série à faire, séries validées et notées
// en ligne compacte. Données synthétiques uniquement.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Widget _page(Widget child) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void _size(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 1600);
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

Exercise _exercise(
  String id,
  String name,
  String sets, {
  int count = 1,
  String intensity = 'RIR 2',
}) => Exercise.manual(
  id: id,
  name: name,
  setsText: sets,
  forcedSets: count,
  intensity: intensity,
);

kc.ExercisePrescription _item({
  int reps = 15,
  int? high,
  kc.SetTechnique? technique,
  kc.SetKind? kind,
}) => kc.ExercisePrescription(
  slotId: 's1',
  exerciseId: 'mu-face-pull-corde',
  sets: 3,
  repsLow: reps,
  repsHigh: high ?? reps,
  targetFlames: 7,
  toCalibrate: false,
  loadBasis: kc.LoadBasis.external,
  reasons: const [],
  technique: technique,
  kind: kind,
);

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
    tzdata.initializeTimeZones();
  });

  group('plage des accessoires (Koach 1.0)', () {
    test('accessoire à reps fixes : écrit −2 à +4', () {
      final it = withAccessoryRange(_item(), kc.SlotRole.accessory);
      expect((it.repsLow, it.repsHigh), (13, 19));
      final sec = withAccessoryRange(_item(reps: 8), kc.SlotRole.secondary);
      expect((sec.repsLow, sec.repsHigh), (6, 12));
    });

    test('lift principal, technique, test, peu de reps : inchangés', () {
      expect(withAccessoryRange(_item(), kc.SlotRole.main).repsHigh, 15);
      expect(withAccessoryRange(_item(), null).repsHigh, 15);
      expect(
        withAccessoryRange(
          _item(
            technique: const kc.SetTechnique(kind: kc.SetTechniqueKind.emom),
          ),
          kc.SlotRole.accessory,
        ).repsHigh,
        15,
      );
      expect(
        withAccessoryRange(
          _item(kind: kc.SetKind.test),
          kc.SlotRole.accessory,
        ).repsHigh,
        15,
      );
      expect(
        withAccessoryRange(_item(reps: 5), kc.SlotRole.accessory).repsHigh,
        5,
      );
      // Plage déjà écrite : gardée.
      final written = withAccessoryRange(
        _item(reps: 8, high: 12),
        kc.SlotRole.accessory,
      );
      expect((written.repsLow, written.repsHigh), (8, 12));
    });

    test('cible de série : reps fixes → plage, série repère gardée', () {
      final it = withAccessoryRange(_item(reps: 8), kc.SlotRole.accessory);
      final fixed = accessoryRangeTarget(
        const kc.SetTarget(repsLow: 8, repsHigh: 8, loadKg: 82.5),
        it,
      );
      expect((fixed.repsLow, fixed.repsHigh, fixed.loadKg), (6, 12, 82.5));
      final probe = accessoryRangeTarget(
        const kc.SetTarget(repsLow: 8, repsHigh: 14),
        it,
      );
      expect((probe.repsLow, probe.repsHigh), (6, 14));
      final top = accessoryRangeTarget(
        const kc.SetTarget(repsLow: 8, repsHigh: 8, role: kc.SetRole.top),
        it,
      );
      expect(top.repsHigh, 8);
    });
  });

  group('GtG hors séance', () {
    Exercise gtg() =>
        _exercise('G-1', 'GtG muscle-up — dans la journée', '3×4', count: 3);

    test('la ligne GtG sort de la séance, pas des semaines d’avant', () {
      expect(gtg().isGtg, isTrue);
      expect(_exercise('X', 'Muscle-up lesté', '6×2').isGtg, isFalse);
      final day = DayPlan.manual(
        j: 3,
        title: 'Jambes',
        exercises: [_exercise('S-1', 'Back squat', '5×5'), gtg()],
      );
      final out = DayPlan.withoutGtg(day);
      expect(out.exercises.map((e) => e.id), ['S-1']);
      expect(out.gtg.map((e) => e.id), ['G-1']);
      expect(DayPlan.adapted(out, out.exercises).gtg.length, 1);
      expect(store.gtgText(out), 'GtG muscle-up · 3 × 4');
      expect(store.gtgText(out, short: true), 'GtG');
      expect(store.gtgText(day), isNull);
      expect(store.gtgReps(gtg()), 4);
    });

    test('rappels toutes les 2 h les jours de GtG (9 h → 21 h)', () {
      final app = store;
      final saved = (app.settings.notifOn, app.program.start);
      final w = app.program.weeks.first;
      final index = w.days.indexWhere((d) => d.exercises.isNotEmpty);
      final before = w.days[index];
      addTearDown(() {
        w.days[index] = before;
        app.settings.notifOn = saved.$1;
        app.program.start = saved.$2;
      });
      app.settings.notifOn = true;
      w.days[index] = DayPlan.manual(
        j: before.j,
        title: before.title,
        exercises: before.exercises,
        gtg: [gtg()],
      );
      final paris = tz.getLocation('Europe/Paris');
      app.program.start = DateTime(2026, 10, 19);
      final date = app.program.dateFor(w.n, before.j);
      final now = DateTime(date.year, date.month, date.day, 12, 30);
      final plan = planGtgReminders(app, now, location: paris);
      expect(plan.map((r) => r.at.hour), [13, 15, 17, 19, 21]);
      expect(plan.first.title, 'GtG — GtG muscle-up : 4 reps propres');
      expect(plan.first.payload, 'S${w.n}-J${before.j}');
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(
        plan.every(
          (r) => r.id >= gtgReminderFirstId && r.id <= gtgReminderLastId,
        ),
        isTrue,
      );
      // Hors fenêtre de 14 jours ou rappels coupés : rien.
      expect(
        planGtgReminders(
          app,
          now.subtract(const Duration(days: 20)),
          location: paris,
        ),
        isEmpty,
      );
      app.settings.notifOn = false;
      expect(planGtgReminders(app, now, location: paris), isEmpty);
    });
  });

  group('séries compactes en séance', () {
    testWidgets('validée et notée : ligne compacte, appui long annule', (
      tester,
    ) async {
      _size(tester);
      final week = _week(9801, 'Compact', [
        _exercise('CP-1', 'Curl marteau', '2×10', count: 2),
      ]);
      final day = week.days.single;
      await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Valider la série 1').first);
      await tester.pumpAndSettle();
      final log = store.exLog(week.n, day.j, day.exercises.single);
      expect(log.sets[0].done, isTrue);
      expect(find.byKey(const ValueKey('set-compact-CP-1-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-compact-CP-1-1')), findsNothing);
      expect(find.byKey(const ValueKey('set-flame-1')), findsOneWidget);
      await tester.longPress(find.byKey(const ValueKey('set-compact-CP-1-0')));
      await tester.pumpAndSettle();
      expect(log.sets[0].done, isFalse);
      expect(find.byKey(const ValueKey('set-compact-CP-1-0')), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('enchaînement : compact quand tout le tour est fait', (
      tester,
    ) async {
      _size(tester);
      final week = _week(9802, 'Tour compact', [
        _exercise('TC-1', 'Face pulls (poulie)', '2×15', count: 2),
        _exercise('TC-2', 'Curl marteau enchaîné', '2×10', count: 2),
      ]);
      final day = week.days.single;
      await tester.pumpWidget(_page(SessionScreen(week: week, day: day)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Valider la série A·1').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('set-compact-TC-1-0')), findsNothing);
      await tester.tap(find.byTooltip('Valider la série B·1').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('set-compact-TC-1-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-compact-TC-2-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('set-compact-TC-1-1')), findsNothing);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
