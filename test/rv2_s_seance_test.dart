// RV2 (dev7.6.0, zone s : écran de séance) — constats mineurs de la revue
// RV1 corrigés :
// - S6 : message après une série (record, Koach, « Enchaîne ») posé
//   au-dessus de la barre de repos lancée par la même série (avant : lu
//   avant `startRest`, la barre apparue ensuite le masquait) ;
// - S10 : groupe d'intervalles sans récupération écrite : aucune
//   récupération inventée (avant : récupération égale à l'effort) ;
// - S11 : palier de tenue d'un drop set mécanique vérifié en secondes, sans
//   record de répétitions (avant : validé comme des répétitions) ;
// - S15 : « Repos complet » dans la casse du reste de l'application.
// (S13, arrêt d'urgence de Koach écran ouvert : rv2s_koach_arret_test.)
//
// Données synthétiques seulement ; horloge simulée.
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/kit/kit.dart';
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

  group('S10 : intervalles sans récupération écrite', () {
    setUp(() {
      store.settings.sound = store.settings.vibration = false;
      store.settings.prepSec = 0;
    });

    test('récupération du groupe : celle du programme, sinon aucune', () {
      const written = kc.GroupSpec(
        groupId: 'g',
        format: kc.GroupFormat.intervals,
        rounds: 8,
        intervalSeconds: 30,
        restBetweenRoundsSeconds: 20,
      );
      const none = kc.GroupSpec(
        groupId: 'g',
        format: kc.GroupFormat.intervals,
        rounds: 8,
        intervalSeconds: 30,
      );
      expect(groupIntervalRest(written), 20);
      expect(groupIntervalRest(none), 0, reason: 'pas de 30 s inventées');
      // L'en-tête ne dit aucune récupération : le chrono non plus.
      expect(groupTitle(none), isNot(contains('récupération')));
      expect(groupTitle(written), contains('récupération'));
    });

    test('chrono sans récupération : efforts enchaînés, un départ toutes '
        'les 30 s, 3 × 30 s en 90 s', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 10, 22, 18);
        final c = TimerCtl(now: () => wall);
        void avance(int s) {
          wall = wall.add(Duration(seconds: s));
          async.elapse(Duration(seconds: s));
        }

        const g = kc.GroupSpec(
          groupId: 'g',
          format: kc.GroupFormat.intervals,
          rounds: 3,
          intervalSeconds: 30,
        );
        c.startInterval(3, 30, groupIntervalRest(g));
        expect(c.label, 'EFFORT 1/3');
        expect(c.groupRunning, isTrue);
        avance(30);
        expect(c.label, 'EFFORT 2/3', reason: 'aucun « REPOS 1/3 »');
        avance(30);
        expect(c.label, 'EFFORT 3/3');
        avance(30);
        expect(c.running, isFalse);
        expect(c.label, 'TERMINÉ');
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
        ..prefill = true
        ..celebrations = true;
    });

    (WeekPlan, DayPlan) semaine(int j, List<Exercise> exs) {
      final week = WeekPlan.manual(
        n: 0,
        block: 'RV2',
        color: const Color(0xFF4FA3C7),
        days: [DayPlan.manual(j: j, title: 'RV2', exercises: exs)],
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

    /// Séance passée (autre journée) où [ex] est noté : base des records.
    void passe(int j, Exercise ex, String reps) {
      final log = store.exLog(0, j, ex);
      log.sets.first
        ..reps = reps
        ..done = true
        ..completedAt = '2026-10-20T18:00:00.000';
    }

    testWidgets('S6 : record après la série : message posé au-dessus de la '
        'barre de repos lancée par la série', (tester) async {
      final ctl = TimerCtl(now: () => DateTime(2026, 10, 22, 18));
      final ex = Exercise.manual(
        id: 'RV2-TR',
        name: 'Tractions RV2',
        setsText: '3×8',
        rest: '90 s',
        restSec: 90,
      );
      passe(9601, ex, '5');
      final (week, day) = semaine(9602, [ex]);
      await ouvrir(tester, week, day, ctl);
      expect(ctl.shown, isFalse, reason: 'aucune barre avant la série');
      expect(store.exLog(0, 9602, ex).sets.first.reps, '8');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('set-check-RV2-TR-0')),
      );
      expect(store.exLog(0, 9602, ex).sets.first.done, isTrue);
      expect(ctl.label, 'REPOS');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      final snack = find.byType(KSnack);
      expect(snack, findsOneWidget);
      expect(find.textContaining('Record : Tractions RV2'), findsOneWidget);
      final bar = find.byKey(const ValueKey('timer-bar-rest'));
      expect(bar, findsOneWidget);
      expect(
        tester.getRect(snack).bottom,
        lessThanOrEqualTo(tester.getRect(bar).top + 0.5),
        reason: 'le message n’est pas masqué par la barre de repos',
      );
      expect(tester.takeException(), null);
      await fermer(tester, ctl);
    });

    testWidgets('S11 : palier de tenue d’un drop set vérifié en secondes, '
        'sans record de répétitions', (tester) async {
      final ctl = TimerCtl(now: () => DateTime(2026, 10, 22, 19));
      final ex = Exercise.manual(
        id: 'RV2-ZR',
        name: 'ZONE ROUGE — drop set RV2',
        setsText: '2 tours × 4 paliers',
        intensity: 'Échec sur les paliers 3 et 4',
        rest: '3 min',
        restSec: 180,
        cue: _cue,
      );
      // Meilleur passé : 10 au poids du corps (un palier en reps).
      passe(9611, ex, '10');
      final (week, day) = semaine(9612, [ex]);
      await ouvrir(tester, week, day, ctl);
      final log = store.exLog(0, 9612, ex);
      // Palier 3 (tenue) vide : le message parle de secondes.
      log.sets[2].reps = '';
      await tapVisible(
        tester,
        find.byKey(const ValueKey('set-check-RV2-ZR-2')),
      );
      expect(log.sets[2].done, isFalse);
      expect(
        find.textContaining('Indique le nombre de secondes'),
        findsOneWidget,
      );
      expect(find.textContaining('nombre de reps'), findsNothing);
      // 40 s de tenue : validées, sans « record » de 40 répétitions.
      log.sets[2].reps = '40';
      await tapVisible(
        tester,
        find.byKey(const ValueKey('set-check-RV2-ZR-2')),
      );
      expect(log.sets[2].done, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.textContaining('Record :'), findsNothing);
      // Le palier 1 (répétitions) garde sa vérification en répétitions.
      log.sets[0].reps = '';
      await tapVisible(
        tester,
        find.byKey(const ValueKey('set-check-RV2-ZR-0')),
      );
      expect(log.sets[0].done, isFalse);
      expect(find.textContaining('nombre de reps'), findsOneWidget);
      expect(tester.takeException(), null);
      await fermer(tester, ctl);
    });

    testWidgets('S15 : « Repos complet » dans la casse de l’application', (
      tester,
    ) async {
      final ctl = TimerCtl(now: () => DateTime(2026, 10, 22, 20));
      final (week, day) = semaine(9621, const []);
      await ouvrir(tester, week, day, ctl);
      final title = find.byKey(const ValueKey('rest-day-title'));
      expect(title, findsOneWidget);
      expect(tester.widget<Text>(title).data, 'Repos complet');
      expect(find.text('REPOS COMPLET'), findsNothing);
      expect(tester.takeException(), null);
      await fermer(tester, ctl);
    });
  });
}
