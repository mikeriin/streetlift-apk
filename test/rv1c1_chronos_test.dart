// RV1c1 (dev7.5.1, pipeline CP, DECISIONS_CP.md C17.45) — chronos des
// groupes au chrono : constats du propriétaire du 21/10/2026 (dev7.4.0).
//
// (a) S1·J3, squat E3MOM 6 × 3 avec dead hang 30 s dans la pause : le
//     sablier de la tenue remplaçait le chrono des tours (« Repos 1:43 »).
//     Le chrono d'un groupe (EMOM, E2MOM, E3MOM, E90s, intervalles, AMRAP,
//     pour le temps) n'est plus jamais remplacé : la tenue a un chrono
//     secondaire au-dessus de la barre du groupe ; repos automatique,
//     −15 s / +15 s, mini-repos ne touchent plus au chrono du groupe.
// (b) finisher « Intervalles · 8 × 30 s, récupération 30 s » : aucun
//     sablier par tour, exercice remplacé compris.
// Hors groupe au chrono, le sablier d'une tenue garde son comportement.
//
// Données synthétiques seulement (C17.33.2) ; horloge simulée.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chrono du groupe (contrôleur)', () {
    setUp(() {
      store.settings.sound = store.settings.vibration = false;
      store.settings.prepSec = 0;
    });

    test('E3MOM 6 × 3 : tenue lancée au tour 3 → chrono secondaire ; le '
        'tour 4 part à 9:00', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 10, 21, 18);
        final c = TimerCtl(now: () => wall);
        void avance(int s) {
          wall = wall.add(Duration(seconds: s));
          async.elapse(Duration(seconds: s));
        }

        c.emom(6, 180);
        expect(c.groupRunning, isTrue);
        avance(2 * 180 + 20);
        expect(c.label, 'TOUR 3/6');
        c.solo('TENUE', 30);
        expect(c.label, 'TOUR 3/6', reason: 'chrono des tours intact');
        expect(c.side.running, isTrue);
        expect(c.side.label, 'TENUE');
        expect(c.side.remaining, 30);
        avance(30);
        expect(c.side.running, isFalse);
        expect(c.side.label, 'TERMINÉ', reason: 'tenue comptée');
        expect(c.side.alerts, 1);
        expect(c.label, 'TOUR 3/6');
        // Repos automatique, −15 s / +15 s, mini-repos : sans effet sur le
        // chrono du groupe.
        final before = c.remaining;
        c.startRest(90);
        c.add(15);
        c.add(-15);
        expect(c.label, 'TOUR 3/6');
        expect(c.remaining, before);
        c.solo('INTRA', 15, prepare: false);
        expect(c.label, 'TOUR 3/6');
        expect(c.side.label, 'INTRA');
        avance(3 * 180 - (2 * 180 + 20 + 30));
        expect(c.label, 'TOUR 4/6', reason: 'tour 4 au bon moment');
        expect(c.remaining, 180);
        c.dispose();
      });
    });

    test('tenue au maximum pendant le groupe : chrono montant secondaire ; '
        'un second appui le fige', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 10, 21, 18);
        final c = TimerCtl(now: () => wall);
        c.emom(8, 120);
        c.soloStopwatch('MAX');
        expect(c.label, 'TOUR 1/8');
        expect(c.side.up, isTrue);
        wall = wall.add(const Duration(seconds: 41));
        async.elapse(const Duration(seconds: 1));
        c.soloStopwatch('MAX');
        expect(c.side.elapsed, 41);
        expect(c.side.label, 'TERMINÉ');
        expect(c.label, 'TOUR 1/8');
        c.dispose();
      });
    });

    test('second appui sur le sablier : la tenue secondaire s’arrête', () {
      fakeAsync((async) {
        final c = TimerCtl(now: async.getClock(DateTime(2026)).now);
        c.startInterval(8, 30, 30);
        c.solo('TENUE', 30);
        expect(c.side.running, isTrue);
        c.solo('TENUE', 30);
        expect(c.side.visible, isFalse);
        expect(c.label, 'EFFORT 1/8');
        c.dispose();
      });
    });

    test('intervalles, AMRAP, pour le temps : chronos de groupe protégés ; '
        'arrêtés par l’athlète, le repos repart', () {
      fakeAsync((async) {
        final c = TimerCtl(now: async.getClock(DateTime(2026)).now);
        c.startInterval(8, 30, 30);
        c.startRest(60);
        expect(c.label, 'EFFORT 1/8');
        c.single('AMRAP', 600, group: true);
        expect(c.groupRunning, isTrue);
        c.startRest(60);
        expect(c.label, 'AMRAP');
        c.stopwatch('CHRONO', group: true);
        c.startRest(60);
        expect(c.label, 'CHRONO');
        c.stop(); // figé (lecture du temps) : plus un chrono en cours
        expect(c.groupRunning, isFalse);
        c.stop();
        c.startRest(60);
        expect(c.label, 'REPOS');
        expect(c.remaining, 60);
        c.dispose();
      });
    });

    test('hors groupe au chrono : la tenue prend le chrono principal, '
        'comme avant ; un repos le remplace, comme avant', () {
      fakeAsync((async) {
        final c = TimerCtl(now: async.getClock(DateTime(2026)).now);
        c.solo('TENUE', 30);
        expect(c.label, 'TENUE');
        expect(c.groupClock, isFalse);
        expect(c.shown, isTrue);
        expect(c.side.visible, isFalse);
        c.add(15);
        expect(c.remaining, 45);
        c.startRest(90);
        expect(c.label, 'REPOS');
        c.soloStopwatch('MAX');
        expect(c.label, 'MAX');
        expect(c.up, isTrue);
        c.dispose();
      });
    });
  });

  group('écran de séance', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
    });
    setUp(() {
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false
        ..autoTimer = true
        ..defaultRest = 90
        ..prepSec = 0
        ..prefill = true;
    });

    (WeekPlan, DayPlan) semaine(int j, List<Exercise> exs) {
      final week = WeekPlan.manual(
        n: 0,
        block: 'RV1c1',
        color: const Color(0xFF4FA3C7),
        days: [DayPlan.manual(j: j, title: 'RV1c1', exercises: exs)],
      );
      return (week, week.days.single);
    }

    Future<void> ouvrir(
      WidgetTester tester,
      WeekPlan week,
      DayPlan day,
      TimerCtl ctl,
    ) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: SessionScreen(week: week, day: day, timer: ctl),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder inSide(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('side-clock')),
      matching: f,
    );
    Finder inBar(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('timer-bar-clock')),
      matching: f,
    );

    Future<void> tapVisible(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pump();
      await tester.tap(f);
      await tester.pump();
    }

    Future<void> fermer(WidgetTester tester, TimerCtl ctl) async {
      ctl.stop();
      ctl.side.stop();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      ctl.dispose();
    }

    testWidgets('E3MOM avec dead hang dans la pause : sablier au tour 3, '
        'série validée, chrono des tours intact, tour 4 au bon moment', (
      tester,
    ) async {
      var wall = DateTime(2026, 10, 21, 18);
      final ctl = TimerCtl(now: () => wall);
      Future<void> avance(int s) async {
        wall = wall.add(Duration(seconds: s));
        await tester.pump(const Duration(seconds: 1));
      }

      final squat = Exercise.manual(
        id: 'C1-SQ',
        name: 'Squat',
        setsText: '6×3 · E3MOM',
        kg: 95,
      );
      final hang = Exercise.manual(
        id: 'C1-DH',
        name: 'Dead hang — enchaîné dans la pause',
        setsText: '6×30 s',
      );
      final (week, day) = semaine(9821, [squat, hang]);
      await ouvrir(tester, week, day, ctl);
      final launch = find.textContaining('Lancer l’E3MOM');
      expect(launch, findsOneWidget);
      await tapVisible(tester, launch);
      expect(ctl.label, 'TOUR 1/6');
      expect(ctl.groupRunning, isTrue);
      // Barre du groupe : pas de −15 s / +15 s.
      expect(find.byKey(const ValueKey('timer-bar-clock')), findsOneWidget);
      expect(find.text('+15 s'), findsNothing);
      await avance(2 * 180 + 20);
      expect(ctl.label, 'TOUR 3/6');
      expect(inBar(find.text('Tour 3/6')), findsOneWidget);
      // Sablier de la 3e tenue (ligne B·3).
      final hourglass = find.byTooltip('Compte à rebours');
      expect(hourglass, findsNWidgets(6));
      await tapVisible(tester, hourglass.at(2));
      expect(ctl.label, 'TOUR 3/6', reason: 'chrono des tours intact');
      expect(inBar(find.text('Tour 3/6')), findsOneWidget);
      expect(find.byKey(const ValueKey('side-clock')), findsOneWidget);
      expect(inSide(find.text('Tenue')), findsOneWidget);
      expect(inSide(find.text('0:30')), findsOneWidget);
      // Série B·1 validée (repos automatique réglé à 90 s) : le repos ne
      // remplace pas le chrono du groupe.
      await tapVisible(tester, find.byTooltip('Valider la série B·1'));
      expect(store.exLog(week.n, day.j, hang).sets.first.done, isTrue);
      expect(ctl.label, 'TOUR 3/6');
      await avance(30);
      expect(ctl.side.label, 'TERMINÉ', reason: 'tenue comptée');
      expect(inSide(find.byTooltip('Fermer')), findsOneWidget);
      await avance(3 * 180 - (2 * 180 + 20 + 30));
      expect(ctl.label, 'TOUR 4/6', reason: 'tour 4 au bon moment');
      expect(inBar(find.text('Tour 4/6')), findsOneWidget);
      // Fermer le chrono secondaire : la barre du groupe reste.
      await tester.tap(inSide(find.byTooltip('Fermer')));
      await tester.pump();
      expect(find.byKey(const ValueKey('side-clock')), findsNothing);
      expect(inBar(find.text('Tour 4/6')), findsOneWidget);
      expect(tester.takeException(), null);
      await fermer(tester, ctl);
    });

    testWidgets('intervalles 8 × 30 s / 30 s (exercice remplacé) : aucun '
        'sablier par tour ; Lancer rythme effort et récupération', (
      tester,
    ) async {
      var wall = DateTime(2026, 10, 21, 19);
      final ctl = TimerCtl(now: () => wall);
      for (final name in const ['Burpees', 'Mountain climbers']) {
        final e = Exercise.manual(
          id: 'C1-IV-$name',
          name: name,
          setsText: '8× (30 s effort / 30 s repos)',
        );
        final (week, day) = semaine(9822 + name.length, [e]);
        await ouvrir(tester, week, day, ctl);
        expect(find.byTooltip('Compte à rebours'), findsNothing);
        expect(find.byTooltip('Chrono montant'), findsNothing);
        final launch = find.textContaining('Lancer 8 × 30');
        expect(launch, findsOneWidget);
        await tapVisible(tester, launch);
        expect(ctl.label, 'EFFORT 1/8');
        expect(ctl.groupRunning, isTrue);
        await tapVisible(tester, find.byTooltip('Valider la série 1').first);
        expect(ctl.label, 'EFFORT 1/8', reason: 'aucun repos par tour');
        wall = wall.add(const Duration(seconds: 31));
        await tester.pump(const Duration(seconds: 1));
        expect(ctl.label, 'REPOS 1/8');
        wall = wall.add(const Duration(seconds: 30));
        await tester.pump(const Duration(seconds: 1));
        expect(ctl.label, 'EFFORT 2/8');
        expect(tester.takeException(), null);
        ctl.stop();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
      ctl.dispose();
    });

    testWidgets('tenue hors groupe : le sablier lance le chrono principal, '
        'comme avant (−15 s / +15 s)', (tester) async {
      final ctl = TimerCtl(now: () => DateTime(2026, 10, 21, 20));
      final e = Exercise.manual(
        id: 'C1-PL',
        name: 'Planche',
        setsText: '3×30 s',
      );
      final (week, day) = semaine(9831, [e]);
      await ouvrir(tester, week, day, ctl);
      final hourglass = find.byTooltip('Compte à rebours');
      expect(hourglass, findsNWidgets(3));
      await tapVisible(tester, hourglass.first);
      expect(ctl.label, 'TENUE');
      expect(ctl.groupClock, isFalse);
      expect(find.byKey(const ValueKey('side-clock')), findsNothing);
      expect(find.byKey(const ValueKey('timer-bar-rest')), findsOneWidget);
      expect(find.text('+15 s'), findsOneWidget);
      expect(tester.takeException(), null);
      await fermer(tester, ctl);
    });
  });
}
