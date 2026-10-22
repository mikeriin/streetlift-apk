// RV2 (dev7.6.0, zone pf : programme créé et profil) — tests de
// non-régression des constats de RV1 corrigés :
//
// - P1 : départ affiché d'un programme repris en cours de route (PR2,
//   `firstShownWeek`) gardé par le programme créé (`PlanProgram`) : nouveau
//   programme, bloc suivant, redémarrage, export et import ;
// - P3 : jours J d'un programme créé fixes quand le départ change de jour
//   de la semaine (séance J3 reste J3, journal à sa place) ;
// - F4 : baisser son expérience (profil v3) : avertissement avant
//   d'effacer records et échéances (« Annuler » ne change rien,
//   « Continuer » applique) ; rien à effacer : pas d'avertissement.
//
// Données synthétiques seulement ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/profile_v3.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'phone_test_support.dart';

/// Libellés affichés des semaines montrées (« S1 », « S2 »…).
List<String> _labels(AppStore app) => [
  for (final w in app.program.shownWeeks) app.program.weekLabel(w.n),
];

/// Séances de la semaine [week] : J → identifiants des exercices.
Map<int, List<String>> _seances(AppStore app, int week) => {
  for (final d in app.program.week(week).days)
    if (d.exercises.isNotEmpty) d.j: [for (final e in d.exercises) e.id],
};

/// Place de chaque séance de la semaine [week] dans le bloc du moteur.
Map<int, int?> _places(AppStore app, int week) => {
  for (final j in _seances(app, week).keys)
    j: app.adaptPlaceOf(week, j)?.dayIndex,
};

/// Brouillon complet d'un intermédiaire (forme générale) avec un record,
/// une échéance et son ancienneté.
ProfileDraft _intermediaire() {
  final d = ProfileDraft()
    ..sex = kc.Sex.male
    ..birthYear = '1994'
    ..height = '178'
    ..weight = '70'
    ..primary = kc.TrainingDiscipline.generalFitness
    ..experience = kc.ExperienceLevel.intermediate
    ..consent = 'refused'
    ..guidance = kc.GuidanceMode.assisted;
  d.addSecondary(kc.TrainingDiscipline.mobility);
  d.goals.add(
    kc.Goal(
      id: 'goal-1',
      kind: kc.GoalKind.habit,
      origin: kc.GoalOrigin.user,
      createdOn: kc.CivilDate(2026, 10, 1),
      sessionsPerWeek: 2,
      weeks: 8,
    ),
  );
  d.days
    ..[2] = 30
    ..[5] = 30;
  d.addPlace(kc.Place.home);
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1 : départ affiché (PR2) gardé par le programme créé', () {
    late AppStore app;
    final others = <AppStore>[];
    var clock = DateTime(2026, 10, 21, 9);

    setUp(() async {
      KoachCalcul.isolat = false;
      clock = DateTime(2026, 10, 21, 9);
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
      await importPr2Nouveau(app);
      expect(app.program.firstShown, 15);
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
      for (final o in others) {
        o.dispose();
      }
      others.clear();
    });

    Future<AppStore> relaunch() async {
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      return next;
    }

    Future<AppStore> roundTrip() async {
      final text = app.exportAll();
      SharedPreferences.setMockInitialValues({});
      final fresh = AppStore()..storeClock = () => clock;
      await fresh.init();
      others.add(fresh);
      expect(await fresh.importAll(text), isTrue);
      return fresh;
    }

    test('PlanProgram : semaine affichée écrite, relue, gardée par '
        'copyWith ; hors bornes refusée', () {
      Map<String, Object?> raw(int shown) => {
        'v': 1,
        'origin': 'replace',
        'createdAt': '2026-10-21T09:00:00',
        'updatedAt': '2026-10-21T09:00:00',
        'firstWeek': 1,
        'blocks': const <Object?>[],
        if (shown != 1) 'firstShownWeek': shown,
      };
      // Bornes lues avant les blocs : semaine affichée après la première
      // semaine du programme refusée.
      expect(
        () => PlanProgram.fromJson(raw(2)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('semaine affichée'),
          ),
        ),
      );
      expect(
        () => PlanProgram.fromJson({...raw(1), 'firstShownWeek': 'S3'}),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('semaine affichée'),
          ),
        ),
      );
    });

    test('nouveau programme créé en cours de route : S1 affichée '
        'inchangée ; redémarrage, export et import', () async {
      final before = _labels(app);
      expect(before.first, 'S1');
      expect(app.program.weekLabel(15), 'S1');
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      final s = PlanStore(app).planStartFor();
      expect(s.firstWeek, 16);
      PlanStore(app).applyPlanCreation(c, startAt: s);
      final plan = app.planProgram!;
      expect(plan.firstWeek, 16);
      expect(plan.firstShown, 15);
      expect(plan.toJson()['firstShownWeek'], 15);
      expect(app.program.firstShown, 15);
      expect(app.program.weekLabel(15), 'S1');
      expect(app.program.weekLabel(16), 'S2');
      expect(app.program.weekLabel(14), 'S14 (ancien)');
      final after = _labels(app);
      expect(after.take(2), before.take(2));
      expect(after.first, 'S1');
      // Relu à l'identique.
      final again = PlanProgram.fromJson(jsonDecode(jsonEncode(plan.toJson())));
      expect(again.firstShown, 15);
      expect(again.copyWith(updatedAt: 'x').firstShown, 15);
      final next = await relaunch();
      expect(next.planProgram!.firstShown, 15);
      expect(next.program.firstShown, 15);
      expect(_labels(next), after);
      final fresh = await roundTrip();
      expect(fresh.planProgram!.firstShown, 15);
      expect(fresh.program.firstShown, 15);
      expect(_labels(fresh), after);
    });

    test('bloc suivant depuis l’instance générée, puis bloc suivant du '
        'programme créé : numérotation affichée inchangée', () async {
      // Dernière semaine du premier bloc écrit (S15 à S19).
      clock = DateTime(2026, 11, 16, 9);
      expect(PlanStore(app).planImportedSegment, isNotNull);
      final before = _labels(app);
      final c = PlanStore(app).newNextBlockCreation(journal: false)!;
      c.createPass2();
      PlanStore(app).applyNextBlockCreation(c);
      final plan = app.planProgram!;
      expect(plan.firstWeek, greaterThan(15));
      expect(plan.firstShown, 15);
      expect(app.program.firstShown, 15);
      expect(app.program.weekLabel(15), 'S1');
      expect(app.program.weekLabel(plan.firstWeek), 'S${plan.firstWeek - 14}');
      final after = _labels(app);
      final kept = plan.firstWeek - 15;
      expect(after.take(kept), before.take(kept));
      // Bloc suivant du programme créé (fin du bloc) : toujours S1 en S15.
      final end = app.program.start!;
      clock = DateTime(
        end.year,
        end.month,
        end.day + (plan.totalWeeks - 1) * 7,
        9,
      );
      expect(PlanStore(app).planBlockEnding, isTrue);
      final c2 = PlanStore(app).newNextBlockCreation(journal: false)!;
      c2.createPass2();
      PlanStore(app).applyNextBlockCreation(c2);
      expect(app.planProgram!.blocks, hasLength(2));
      expect(app.planProgram!.firstShown, 15);
      expect(app.program.firstShown, 15);
      expect(_labels(app).take(after.length), after);
      final next = await relaunch();
      expect(next.program.firstShown, 15);
      final fresh = await roundTrip();
      expect(fresh.program.firstShown, 15);
      expect(fresh.program.weekLabel(15), 'S1');
    });
  });

  group('P3 : jours J d’un programme créé fixes', () {
    late AppStore app;
    final others = <AppStore>[];
    var clock = DateTime(2026, 10, 1, 9);

    setUp(() async {
      KoachCalcul.isolat = false;
      clock = DateTime(2026, 10, 1, 9); // jeudi
      SharedPreferences.setMockInitialValues({});
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
      for (final o in others) {
        o.dispose();
      }
      others.clear();
    });

    test('départ déplacé du jeudi au vendredi : séances, places dans le '
        'bloc et journal gardés ; dates décalées d’un jour', () async {
      app.saveAthleteProfile(
        ProfileDraft.of(
          sampleAthleteProfile(
            on: civilOf(clock),
            guidance: kc.GuidanceMode.assisted,
          ),
        )..consent = 'refused',
      );
      final c = PlanStore(app).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(app).applyPlanCreation(c);
      expect(app.program.start, DateTime(2026, 10, 1));
      final seances = _seances(app, 1);
      final places = _places(app, 1);
      expect(seances, isNotEmpty);
      expect(places.values, everyElement(isNotNull));
      final j = seances.keys.first;
      final date = app.program.dateFor(1, j);
      expect(await app.configureStart(DateTime(2026, 10, 2)), StartSave.saved);
      // Même séance au même J, tout de suite (moteurs) et après un
      // redémarrage (programme affiché).
      expect(_seances(app, 1), seances);
      expect(_places(app, 1), places);
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      expect(next.program.start, DateTime(2026, 10, 2));
      expect(_seances(next, 1), seances);
      expect(_places(next, 1), places);
      expect(next.program.dateFor(1, j), date.add(const Duration(days: 1)));
      // Export et import : idem.
      final text = next.exportAll();
      SharedPreferences.setMockInitialValues({});
      final fresh = AppStore()..storeClock = () => clock;
      await fresh.init();
      others.add(fresh);
      expect(await fresh.importAll(text), isTrue);
      expect(_seances(fresh, 1), seances);
      expect(_places(fresh, 1), places);
    });
  });

  group('F4 : baisser son expérience', () {
    final now = DateTime(2026, 10, 1, 12);

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
    });
    setUp(() async {
      store.debugWriteHook = null;
      await store.eraseAllData();
      store.storeClock = () => now;
    });
    tearDown(() => store.storeClock = DateTime.now);

    Widget page(Widget child) => MaterialApp(
      theme: buildTheme(true),
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: child,
    );

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    void saveIntermediaire() {
      final d = _intermediaire()
        ..trainingAge = kc.TrainingAge.over5Years
        ..benchmarks = [
          kc.Benchmark(
            exerciseId: 'sl-traction-lestee',
            kind: kc.BenchmarkKind.loadReps,
            source: kc.BenchmarkSource.declared,
            externalLoadKg: 20,
            reps: 3,
            rir: 1,
            bodyWeightKg: 70,
            date: kc.CivilDate(2026, 9, 1),
          ),
        ]
        ..events = [
          kc.SeasonEvent(
            id: 'event-1',
            kind: kc.EventKind.race,
            priority: kc.EventPriority.main,
            date: kc.CivilDate(2027, 3, 15),
            dateApproximate: true,
            distanceMeters: 10000,
          ),
        ];
      expect(store.saveAthleteProfile(d), isNotNull);
      final p = store.athleteProfile!;
      expect(p.experience, kc.ExperienceLevel.intermediate);
      expect(p.benchmarks, hasLength(1));
      expect(p.events, hasLength(1));
    }

    test('réponses effacées listées sans toucher au brouillon', () {
      saveIntermediaire();
      final d = store.athleteEditDraft()
        ..experience = kc.ExperienceLevel.beginner;
      final parcours = store.content.questionnaire!;
      final before = jsonEncode(d.v3);
      final lost = d.prunedAnswers(parcours, now.year);
      expect(
        lost.map((q) => q.id),
        containsAll(['training_age', 'benchmarks', 'events']),
      );
      expect(jsonEncode(d.v3), before);
      final records = lost.firstWhere((q) => q.id == 'benchmarks');
      expect(prunedAnswerLabel(records, d), 'tes records (1)');
      // Niveau monté : rien à effacer.
      d.experience = kc.ExperienceLevel.advanced;
      expect(d.prunedAnswers(parcours, now.year), isEmpty);
    });

    testWidgets('avertissement : « Annuler » ne change rien, « Continuer » '
        'efface records et échéances', (tester) async {
      phone(tester);
      saveIntermediaire();
      final saved = jsonEncode(store.athleteProfile!.toJson());
      await tester.pumpWidget(
        page(
          const AthleteProfileFlow(
            mode: AthleteFlowMode.edit,
            editStep: 'experience',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'flow-experience-beginner');
      await tap(tester, 'flow-save');
      expect(find.byKey(const ValueKey('pruned-answers')), findsOneWidget);
      expect(find.byKey(const ValueKey('pruned-benchmarks')), findsOneWidget);
      expect(find.byKey(const ValueKey('pruned-events')), findsOneWidget);
      expect(find.text('• tes records (1)'), findsOneWidget);
      expect(find.text('• tes échéances (1)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pruned-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pruned-answers')), findsNothing);
      expect(find.byType(AthleteProfileFlow), findsOneWidget);
      expect(jsonEncode(store.athleteProfile!.toJson()), saved);
      // « Continuer » : la règle C1.6 s'applique.
      await tap(tester, 'flow-save');
      expect(find.byKey(const ValueKey('pruned-answers')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pruned-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pruned-answers')), findsNothing);
      final p = store.athleteProfile!;
      expect(p.experience, kc.ExperienceLevel.beginner);
      expect(p.benchmarks, isNull);
      expect(p.events, isNull);
      expect(p.trainingAge, isNull);
    });

    testWidgets('rien à effacer (niveau monté) : enregistré sans '
        'avertissement', (tester) async {
      phone(tester);
      saveIntermediaire();
      await tester.pumpWidget(
        page(
          const AthleteProfileFlow(
            mode: AthleteFlowMode.edit,
            editStep: 'experience',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'flow-experience-advanced');
      await tap(tester, 'flow-save');
      expect(find.byKey(const ValueKey('pruned-answers')), findsNothing);
      final p = store.athleteProfile!;
      expect(p.experience, kc.ExperienceLevel.advanced);
      expect(p.benchmarks, hasLength(1));
      expect(p.events, hasLength(1));
    });
  });
}
