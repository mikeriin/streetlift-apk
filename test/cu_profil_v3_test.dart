// CU (dev6.8.0, PIPELINE_CP) — profil v3 dans l'application (`kalis_core`
// 0.4.0) : parcours adaptatif (questions vues par profil type, chaque
// condition d'apparition), brouillon et profil au schéma 3, réponses
// devenues sans objet, migration v2 → v3, sauvegarde, création d'un
// programme avec les moteurs actuels pour chaque profil type, « Compléter
// mon profil », tests guidés et écrans.
// Données synthétiques ; horloge injectée ; stockage simulé.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/guided_tests.dart';
import 'package:streetlift_tracker/plan/plan_creation.dart';
import 'package:streetlift_tracker/profile_v3.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

Map<String, Object?> _fixtures() =>
    (jsonDecode(
              File(
                'packages/kalis_core/test/fixtures/profiles_v3.json',
              ).readAsStringSync(),
            )
            as Map)
        .cast<String, Object?>();

/// Brouillon d'un débutant complet et valide (forme générale).
ProfileDraft beginnerDraft() {
  final d = ProfileDraft()
    ..sex = Sex.male
    ..birthYear = '1994'
    ..height = '178'
    ..primary = TrainingDiscipline.generalFitness
    ..experience = ExperienceLevel.beginner
    ..consent = 'refused'
    ..guidance = GuidanceMode.assisted;
  d.addSecondary(TrainingDiscipline.mobility);
  d.goals.add(
    Goal(
      id: 'goal-1',
      kind: GoalKind.habit,
      origin: GoalOrigin.user,
      createdOn: CivilDate(2026, 10, 1),
      sessionsPerWeek: 2,
      weeks: 8,
    ),
  );
  d.days
    ..[2] = 30
    ..[5] = 30;
  d.addPlace(Place.home);
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 12);
  late ProfileQuestionnaire parcours;
  late Catalog catalog;
  late Map<String, Object?> fixtures;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    parcours = store.content.questionnaire!;
    catalog = store.content.catalog!;
    fixtures = _fixtures();
  });

  List<String> ids(Iterable<Object> qs) => [
    for (final q in qs)
      if (q is ProfileQuestion) q.id else if (q is GuidedTest) q.id,
  ];

  group('parcours', () {
    test('asset de l’application : copie octet pour octet du paquet', () {
      expect(
        File('assets/catalog/parcours_v3.json').readAsBytesSync(),
        File('packages/kalis_core/data/parcours_v3.json').readAsBytesSync(),
      );
      expect(parcours.questions, hasLength(31));
      for (final s in parcours.screens) {
        final id = s['id']! as String;
        if (id == 'accueil' || id == 'recap') continue;
        expect(stepOfScreen(id), isNotNull, reason: id);
        expect(kAthleteSteps, contains(stepOfScreen(id)));
      }
    });

    test('profils types : questions vues à la création, reportées, tests '
        'permis (PARCOURS_V3.md § 2 et § 5)', () {
      final year = fixtures['todayYear']! as int;
      final counts = <String, int>{};
      for (final f in (fixtures['profiles']! as List).cast<Map>()) {
        final key = f['key'] as String;
        final json = (f['profile'] as Map).cast<String, Object?>();
        final exp = (f['expected'] as Map).cast<String, Object?>();
        final p = AthleteProfile.fromJson(json);
        // Le brouillon de l'application dit la même chose que le profil.
        final d = ProfileDraft.of(p);
        final seen = ids(
          parcours.visibleQuestions(d.conditionJson(), todayYear: year),
        );
        expect(seen, exp['questionIds'], reason: key);
        expect(
          ids(parcours.visibleQuestions(json, todayYear: year)),
          exp['questionIds'],
          reason: key,
        );
        expect(
          ids(parcours.deferredQuestions(json, todayYear: year)),
          exp['deferredIds'],
          reason: key,
        );
        expect(
          ids(parcours.eligibleTests(json, todayYear: year)),
          exp['testIds'],
          reason: key,
        );
        counts[key] = seen.length;
      }
      expect(counts, {
        'v3_debutant_forme_generale': 16,
        'v3_intermediaire_musculation': 27,
        'v3_competiteur_elite_streetlifting': 29,
        'v3_coureuse_10km': 28,
        'v3_sets_reps_avance': 29,
      });
    });

    test('débutant selon la discipline : 16 à 18 questions', () {
      final expected = {
        TrainingDiscipline.generalFitness: 16,
        TrainingDiscipline.mobility: 16,
        TrainingDiscipline.musculation: 17,
        TrainingDiscipline.streetWorkout: 16,
        TrainingDiscipline.crossfit: 17,
        TrainingDiscipline.streetlifting: 17,
        TrainingDiscipline.calisthenics: 17,
        TrainingDiscipline.cardio: 18,
      };
      for (final e in expected.entries) {
        final d = beginnerDraft()
          ..primary = e.key
          ..secondaries.clear();
        d.addSecondary(
          e.key == TrainingDiscipline.mobility
              ? TrainingDiscipline.generalFitness
              : TrainingDiscipline.mobility,
        );
        expect(
          parcours.visibleQuestions(d.conditionJson(), todayYear: 2026).length,
          e.value,
          reason: e.key.code,
        );
      }
    });

    test('chaque condition d’apparition, vue depuis le brouillon', () {
      bool shows(ProfileDraft d, String id, {bool deferred = false}) => ids(
        parcours.visibleQuestions(
          d.conditionJson(),
          todayYear: 2026,
          includeDeferred: deferred,
        ),
      ).contains(id);

      ProfileDraft level(ExperienceLevel? e) => beginnerDraft()..experience = e;
      ProfileDraft discipline(TrainingDiscipline p, [ExperienceLevel? e]) {
        final d = beginnerDraft()
          ..experience = e ?? ExperienceLevel.beginner
          ..primary = p
          ..secondaries.clear();
        d.addSecondary(
          p == TrainingDiscipline.mobility
              ? TrainingDiscipline.generalFitness
              : TrainingDiscipline.mobility,
        );
        return d;
      }

      // Expérience, ancienneté, interruption.
      expect(shows(level(null), 'training_age'), isFalse);
      expect(shows(level(ExperienceLevel.beginner), 'training_age'), isFalse);
      expect(shows(level(ExperienceLevel.intermediate), 'training_age'), isTrue);
      final inter = level(ExperienceLevel.intermediate);
      expect(shows(inter, 'training_gap'), isFalse);
      inter.trainingAge = TrainingAge.under6Months;
      expect(shows(inter, 'training_gap'), isFalse);
      inter.trainingAge = TrainingAge.months6To24;
      expect(shows(inter, 'training_gap'), isTrue);
      // Records, charge actuelle.
      expect(shows(level(ExperienceLevel.beginner), 'benchmarks'), isFalse);
      expect(shows(level(ExperienceLevel.intermediate), 'benchmarks'), isTrue);
      expect(
        shows(level(ExperienceLevel.intermediate), 'recent_training'),
        isFalse,
      );
      expect(shows(level(ExperienceLevel.advanced), 'recent_training'), isTrue);
      // Figures : disciplines, ou part de calisthénie du mode street.
      expect(
        shows(discipline(TrainingDiscipline.musculation), 'skills'),
        isFalse,
      );
      for (final p in [
        TrainingDiscipline.calisthenics,
        TrainingDiscipline.streetlifting,
        TrainingDiscipline.crossfit,
      ]) {
        expect(shows(discipline(p), 'skills'), isTrue, reason: p.code);
      }
      final street = beginnerDraft()
        ..setStreet(true)
        ..setStreetPrimary(StreetStyle.setsReps)
        ..setStreetPct(StreetStyle.calisthenics, 0)
        ..setStreetPct(StreetStyle.streetlifting, 0);
      expect(shows(street, 'skills'), isFalse);
      street.setStreetPct(StreetStyle.calisthenics, 10);
      expect(shows(street, 'skills'), isTrue);
      // Orientation en musculation (principale ou secondaire).
      expect(shows(level(ExperienceLevel.beginner), 'emphasis'), isFalse);
      final secMuscu = beginnerDraft()
        ..secondaries.clear()
        ..addSecondary(TrainingDiscipline.musculation);
      expect(shows(secMuscu, 'emphasis'), isTrue);
      // Échéances : intermédiaire, objectif de performance, ou cardio.
      expect(shows(level(ExperienceLevel.beginner), 'events'), isFalse);
      expect(shows(level(ExperienceLevel.intermediate), 'events'), isTrue);
      final perf = beginnerDraft();
      perf.goals.add(
        Goal(
          id: 'goal-2',
          kind: GoalKind.performance,
          origin: GoalOrigin.user,
          createdOn: CivilDate(2026, 10, 1),
          exerciseId: 'sw-pompe',
          metric: GoalMetric.maxReps,
          targetValue: 20,
          targetDate: CivilDate(2027, 1, 1),
        ),
      );
      expect(shows(perf, 'events'), isTrue);
      expect(shows(discipline(TrainingDiscipline.cardio), 'events'), isTrue);
      // Spécialisation : avancé, ou intermédiaire en musculation.
      expect(
        shows(level(ExperienceLevel.intermediate), 'specialization'),
        isFalse,
      );
      expect(
        shows(
          discipline(
            TrainingDiscipline.musculation,
            ExperienceLevel.intermediate,
          ),
          'specialization',
        ),
        isTrue,
      );
      expect(shows(level(ExperienceLevel.advanced), 'specialization'), isTrue);
      // Points faibles : avancé, disciplines de force.
      expect(
        shows(
          discipline(TrainingDiscipline.cardio, ExperienceLevel.advanced),
          'weak_points',
        ),
        isFalse,
      );
      expect(
        shows(
          discipline(
            TrainingDiscipline.streetlifting,
            ExperienceLevel.intermediate,
          ),
          'weak_points',
        ),
        isFalse,
      );
      expect(
        shows(
          discipline(TrainingDiscipline.streetlifting, ExperienceLevel.advanced),
          'weak_points',
        ),
        isTrue,
      );
      // Course : cardio, ou course en échéance.
      expect(shows(level(ExperienceLevel.intermediate), 'running_base'), isFalse);
      expect(
        shows(discipline(TrainingDiscipline.cardio), 'running_base'),
        isTrue,
      );
      final race = level(ExperienceLevel.intermediate)
        ..events = [
          SeasonEvent(
            id: 'event-1',
            kind: EventKind.race,
            priority: EventPriority.main,
            date: CivilDate(2027, 3, 14),
            distanceMeters: 10000,
          ),
        ];
      expect(shows(race, 'running_base'), isTrue);
      // Récupération : reportée pour un débutant, posée sinon.
      for (final id in ['sleep', 'stress', 'outside_load']) {
        expect(shows(level(ExperienceLevel.beginner), id), isFalse, reason: id);
        expect(
          shows(level(ExperienceLevel.beginner), id, deferred: true),
          isTrue,
          reason: id,
        );
        expect(
          shows(level(ExperienceLevel.intermediate), id),
          isTrue,
          reason: id,
        );
      }
      expect(
        shows(level(ExperienceLevel.beginner), 'body_weight_goal', deferred: true),
        isFalse,
      );
      expect(
        shows(
          discipline(TrainingDiscipline.calisthenics),
          'body_weight_goal',
          deferred: true,
        ),
        isTrue,
      );
      expect(
        shows(discipline(TrainingDiscipline.calisthenics), 'body_weight_goal'),
        isFalse,
      );
      expect(
        shows(level(ExperienceLevel.intermediate), 'body_weight_goal'),
        isTrue,
      );
      // Préférences : masquées pour un débutant.
      expect(shows(level(ExperienceLevel.beginner), 'preferences'), isFalse);
      expect(shows(level(ExperienceLevel.intermediate), 'preferences'), isTrue);
      // Poids obligatoire au poids du corps.
      expect(level(null).weightRequired(parcours, 2026), isFalse);
      expect(
        discipline(TrainingDiscipline.calisthenics).weightRequired(
          parcours,
          2026,
        ),
        isTrue,
      );
      expect(street.weightRequired(parcours, 2026), isTrue);
      final noWeight = discipline(TrainingDiscipline.streetWorkout)
        ..weight = '';
      expect(
        noWeight.stepError('discipline', now, parcours: parcours),
        kWeightRequiredError,
      );
      expect(noWeight.build(now, parcours: parcours), isNull);
      noWeight.weight = '72,5';
      expect(noWeight.stepError('discipline', now, parcours: parcours), isNull);
    });
  });

  group('brouillon et profil v3', () {
    test('réponses du schéma 3 : profil au schéma 3, contrat, catalogue, '
        'aller-retour', () {
      final d = beginnerDraft()
        ..experience = ExperienceLevel.advanced
        ..weight = '74'
        ..primary = TrainingDiscipline.streetlifting
        ..secondaries.clear();
      d.addSecondary(TrainingDiscipline.calisthenics);
      d
        ..trainingAge = TrainingAge.years2To5
        ..trainingGap = TrainingGap.none
        ..benchmarks = [
          Benchmark(
            exerciseId: 'sl-traction-lestee',
            kind: BenchmarkKind.loadReps,
            source: BenchmarkSource.declared,
            externalLoadKg: 40,
            reps: 3,
            rir: 1,
            bodyWeightKg: 74,
            date: CivilDate(2026, 9, 1),
          ),
        ]
        ..sleep = SleepBand.hours7Plus
        ..stress = StressBand.moderate
        ..occupationalLoad = OccupationalLoad.seated
        ..otherSports = const <OtherSport>[]
        ..events = const <SeasonEvent>[]
        ..recentTraining = const [
          RecentTraining(exerciseId: 'sl-traction-lestee', sessionsPerWeek: 3),
        ];
      final p = d.build(
        now,
        vocabulary: store.content.equipmentVocabulary,
        parcours: parcours,
      )!;
      expect(p.schemaVersion, 3);
      expect(p.validate(), isEmpty);
      expect(catalog.checkProfile(p), isEmpty);
      expect(p.benchmarks!.single.externalLoadKg, 40);
      expect(p.events, isEmpty, reason: '« Non » : liste vide');
      expect(p.otherSports, isEmpty);
      expect(p.lifestyleUpdatedOn, CivilDate(2026, 10, 1));
      // Brouillon : aller-retour JSON identique.
      final back = ProfileDraft.fromJson(jsonDecode(jsonEncode(d.toJson())))!;
      expect(jsonEncode(back.toJson()), jsonEncode(d.toJson()));
      // Profil relu en brouillon puis reconstruit : identique, date des
      // réponses datées gardée tant qu'elles ne changent pas.
      final later = DateTime(2026, 11, 2, 9);
      final again = (ProfileDraft.of(p)..consent = 'refused').build(
        later,
        vocabulary: store.content.equipmentVocabulary,
        parcours: parcours,
      )!;
      expect(again.lifestyleUpdatedOn, CivilDate(2026, 10, 1));
      expect(
        jsonEncode(
          again.toJson()
            ..remove('updatedOn'),
        ),
        jsonEncode(p.toJson()..remove('updatedOn')),
      );
      final changed =
          (ProfileDraft.of(p)
                ..consent = 'refused'
                ..sleep = SleepBand.under6Hours)
              .build(later, parcours: parcours)!;
      expect(changed.lifestyleUpdatedOn, CivilDate(2026, 11, 2));
      // « Passer » : champ absent, jamais de valeur par défaut.
      final skipped = ProfileDraft.of(p)
        ..consent = 'refused'
        ..sleep = null;
      expect(skipped.build(later, parcours: parcours)!.sleep, isNull);
    });

    test('réponses devenues sans objet retirées, reportées gardées', () {
      final d = beginnerDraft()
        ..experience = ExperienceLevel.intermediate
        ..trainingAge = TrainingAge.months6To24
        ..trainingGap = TrainingGap.weeks3To10
        ..sleep = SleepBand.hours6To7;
      expect(d.build(now, parcours: parcours)!.trainingGap, isNotNull);
      d.experience = ExperienceLevel.beginner;
      final p = d.build(now, parcours: parcours)!;
      expect(p.trainingAge, isNull);
      expect(p.trainingGap, isNull);
      // Sommeil : reporté pour un débutant, pas retiré.
      expect(p.sleep, SleepBand.hours6To7);
      expect(p.validate(), isEmpty);
    });

    test('fourchettes : 4 mouvements pour un débutant, sans ceux qui ont un '
        'record', () {
      final d = beginnerDraft()
        ..primary = TrainingDiscipline.musculation
        ..secondaries.clear();
      d.addSecondary(TrainingDiscipline.streetWorkout);
      expect(d.shownMovements, hasLength(4));
      d.experience = ExperienceLevel.intermediate;
      expect(d.shownMovements.length, greaterThan(4));
      final squat = d.movements.first.exerciseId;
      d.benchmarks = [
        Benchmark(
          exerciseId: squat,
          kind: BenchmarkKind.loadReps,
          source: BenchmarkSource.declared,
          externalLoadKg: 100,
          reps: 5,
        ),
      ];
      expect(d.shownMovements.map((m) => m.exerciseId), isNot(contains(squat)));
    });

    test('migration v2 → v3 : seul schemaVersion change', () {
      final p2 = sampleAthleteProfile(on: CivilDate(2026, 9, 20));
      final json2 = p2.copyWith(schemaVersion: 2).toJson();
      expect(json2['schemaVersion'], 2);
      final r = AthleteRecord.fromJson({
        'v': 1,
        'profile': json2,
        'savedAt': '2026-09-20T10:00:00',
        'birthYearAt': '2026-09-20T10:00:00',
      });
      expect(r.profile.schemaVersion, 3);
      final json3 = r.profile.toJson();
      expect(json3.remove('schemaVersion'), 3);
      json2.remove('schemaVersion');
      expect(jsonEncode(json3), jsonEncode(json2));
      expect(r.profile.schema3FieldsPresent, isEmpty);
    });
  });

  group('magasin', () {
    late AppStore app;
    var clock = now;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = now;
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('utilisateur existant : profil v2 relu au schéma 3, sans perte ; '
        'programme inchangé ; invitation une seule fois', () async {
      app.saveAthleteProfile(
        ProfileDraft.of(sampleAthleteProfile(on: CivilDate(2026, 9, 20)))
          ..consent = 'refused',
      );
      final state = backupOf(app);
      // Section écrite par dev6.7.0 : profil au schéma 2.
      (state['athleteProfile'] as Map)['profile']['schemaVersion'] = 2;
      await app.flush();
      SharedPreferences.setMockInitialValues({
        'kalis_state_v3': jsonEncode(state),
      });
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      addTearDown(next.dispose);
      expect(next.athleteLoadIssues, 0);
      expect(next.athleteProfile!.schemaVersion, 3);
      final after = backupOf(next);
      final profileAfter =
          (after['athleteProfile'] as Map)['profile'] as Map;
      final profileBefore = (state['athleteProfile'] as Map)['profile'] as Map;
      expect(profileAfter.remove('schemaVersion'), 3);
      profileBefore.remove('schemaVersion');
      expect(jsonEncode(profileAfter), jsonEncode(profileBefore));
      for (final k in state.keys) {
        if (k == 'athleteProfile') continue;
        expect(jsonEncode(after[k]), jsonEncode(state[k]), reason: k);
      }
      // Compléter mon profil : questions du schéma 3, invitation unique.
      expect(next.profilePendingQuestions, isNotEmpty);
      expect(next.profileCreatedByV3, isFalse);
      expect(next.profileInviteVisible, isTrue);
      await next.dismissProfileInvite();
      expect(next.profileInviteVisible, isFalse);
      // Une question passée n'est plus reproposée d'office.
      final first = next.profilePendingQuestions.first.id;
      await next.addSkippedProfileQuestions([first]);
      expect(ids(next.profilePendingQuestions), isNot(contains(first)));
    });

    test('profil créé avec le parcours v3 : questions reportées proposées '
        'après la première semaine', () async {
      final d = beginnerDraft()..weight = '80';
      expect(app.saveAthleteProfile(d, createdByV3: true), isNotNull);
      expect(app.profileCreatedByV3, isTrue);
      expect(
        ids(app.profileDeferredPending),
        containsAll(['sleep', 'stress', 'outside_load']),
      );
      expect(app.profileInviteVisible, isFalse);
      clock = clock.add(const Duration(days: 7));
      expect(app.profileInviteVisible, isTrue);
      await app.dismissProfileInvite();
      expect(app.profileInviteVisible, isFalse);
    });

    test('sauvegarde : réponses du schéma 3 exportées et relues à '
        'l’identique', () async {
      final d = beginnerDraft()
        ..experience = ExperienceLevel.intermediate
        ..weight = '70'
        ..trainingAge = TrainingAge.over5Years
        ..trainingGap = TrainingGap.reduced
        ..sleep = SleepBand.under6Hours
        ..stress = StressBand.high
        ..occupationalLoad = OccupationalLoad.heavy
        ..otherSports = const [
          OtherSport(
            kind: OtherSportKind.combatSport,
            sessionsPerWeek: 2,
            minutesPerSession: 90,
            hard: true,
            regions: [BodyRegion.wholeBody],
          ),
        ]
        ..bodyWeightGoal = BodyWeightGoal.lose
        ..targetBodyWeightKg = 66
        ..events = [
          SeasonEvent(
            id: 'event-1',
            kind: EventKind.race,
            priority: EventPriority.main,
            date: CivilDate(2027, 3, 15),
            dateApproximate: true,
            distanceMeters: 10000,
          ),
        ];
      d.putLimitation(
        limitationOf(BodyZone.elbow, BodySide.left, 0).copyWith(
          since: ConstraintSince.months3To12,
          effortDiscomfort: 5,
          aggravatedBy: const [AggravatingMovement.pullBentArm],
        ),
      );
      d
        ..consent = 'given'
        ..answers.addAll({for (final q in kHealthQuestions) q.id: false});
      expect(app.saveAthleteProfile(d), isNotNull);
      final p = app.athleteProfile!;
      expect(p.validate(), isEmpty);
      expect(p.limitations.single.effortDiscomfort, 5);
      expect(p.otherSports!.single.kind, OtherSportKind.combatSport);
      final exported = app.exportAll();
      SharedPreferences.setMockInitialValues({});
      final fresh = AppStore()..storeClock = () => clock;
      await fresh.init();
      addTearDown(fresh.dispose);
      expect(await fresh.importBackup(exported), ImportStatus.success);
      expect(
        jsonEncode(fresh.athleteProfile!.toJson()),
        jsonEncode(p.toJson()),
      );
    });

    test('moteurs actuels : un programme pour chaque profil type', () {
      for (final f in (fixtures['profiles']! as List).cast<Map>()) {
        final p = AthleteProfile.fromJson(
          (f['profile'] as Map).cast<String, Object?>(),
        );
        final c = PlanCreation(
          catalog: catalog,
          profile: p,
          startDate: CivilDate(2026, 10, 5),
        )..start();
        expect(c.plan.validate(), isEmpty, reason: f['key'] as String);
        final pass2 = c.createPass2();
        expect(pass2.validate(), isEmpty, reason: f['key'] as String);
        expect(pass2.days, isNotEmpty, reason: f['key'] as String);
      }
    });

    test('tests guidés : aucun pour un débutant ; série lourde proposée, '
        'convertie et ajoutée aux records', () {
      final beginner = beginnerDraft()..weight = '80';
      app.saveAthleteProfile(beginner);
      expect(
        proposeTests(
          parcours: parcours,
          profile: app.athleteProfileForEngines!,
          catalog: catalog,
          programIds: const [],
          year: 2026,
          sessionsDone: 0,
        ),
        isEmpty,
      );
      final d = beginnerDraft()
        ..experience = ExperienceLevel.intermediate
        ..weight = '80'
        ..primary = TrainingDiscipline.musculation
        ..secondaries.clear()
        ..consent = 'given';
      d.addSecondary(TrainingDiscipline.mobility);
      d.places.clear();
      d.addPlace(Place.gym);
      d.answers.addAll({for (final q in kHealthQuestions) q.id: false});
      app.saveAthleteProfile(d);
      final profile = app.athleteProfileForEngines!;
      expect(profile.healthScreening!.outcome, HealthScreeningOutcome.standard);
      final props = proposeTests(
        parcours: parcours,
        profile: profile,
        catalog: catalog,
        programIds: const [],
        year: 2026,
        sessionsDone: 0,
      );
      expect(props, isNotEmpty);
      expect(props.length, lessThanOrEqualTo(kMaxTestProposals));
      for (final pr in props) {
        expect(pr.test.stage, 'first_session', reason: pr.key);
      }
      final t1 = props.firstWhere((p) => p.test.id == 't1_serie_lourde');
      final entry = TestEntry()
        ..loadKg = 80
        ..reps = 5
        ..rir = 1;
      final b = benchmarkOfTest(t1.test, t1.exerciseId, entry, civilOf(now))!;
      expect(b.source, BenchmarkSource.guidedTest);
      expect(b.protocolId, 't1_serie_lourde');
      final text = estimateText(
        t1.test,
        catalog.exercise(t1.exerciseId),
        entry,
      )!;
      expect(text, contains(' à '));
      expect(app.addGuidedTestResult(b), isTrue);
      expect(app.athleteProfile!.benchmarks, [b]);
      // Capacité connue : plus de test proposé sur ce mouvement.
      expect(
        proposeTests(
          parcours: parcours,
          profile: app.athleteProfileForEngines!,
          catalog: catalog,
          programIds: const [],
          year: 2026,
          sessionsDone: 0,
        ).map((p) => p.exerciseId),
        isNot(contains(t1.exerciseId)),
      );
    });
  });

  group('écrans', () {
    setUp(() async {
      store.debugWriteHook = null;
      await store.eraseAllData();
      store.storeClock = () => now;
    });
    tearDown(() => store.storeClock = DateTime.now);

    Widget page(Widget child, {double scale = 1, bool dark = true}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        );

    AthleteProfileFlowState flow(WidgetTester tester) =>
        tester.state<AthleteProfileFlowState>(find.byType(AthleteProfileFlow));

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    for (final dark in [true, false]) {
      testWidgets('profils types : le flux montre exactement les questions du '
          'parcours, écran par écran (${dark ? 'sombre' : 'clair'})', (
        tester,
      ) async {
        phone(tester);
        for (final f in (fixtures['profiles']! as List).cast<Map>()) {
          final key = f['key'] as String;
          final p = AthleteProfile.fromJson(
            (f['profile'] as Map).cast<String, Object?>(),
          );
          final exp = ((f['expected'] as Map)['questionIds'] as List)
              .cast<String>();
          await store.saveAthleteDraft(
            ProfileDraft.of(p),
            step: 'identity',
            mode: 'create',
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            page(const AthleteProfileFlow(), dark: dark),
          );
          await tester.pumpAndSettle();
          final st = flow(tester);
          expect(st.visibleQuestionIds, exp.toSet(), reason: key);
          for (final step in st.visibleSteps) {
            if (step == 'welcome' || step == 'recap') continue;
            st.debugGo(step);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$key $step');
            for (final id in exp) {
              final q = parcours.question(id)!;
              if (q.since < 3 || stepOfScreen(q.screen) != step) continue;
              await scrollToAction(tester, find.byKey(ValueKey('q-$id')));
            }
            await scrollToAction(
              tester,
              find.byKey(ValueKey('flow-next-$step')),
            );
          }
          // Écrans sans question visible : pas montrés.
          final steps = st.visibleSteps;
          if (key == 'v3_debutant_forme_generale') {
            expect(steps, isNot(contains('recovery')));
            expect(steps, isNot(contains('preferences')));
          } else {
            expect(steps, contains('recovery'), reason: key);
          }
        }
        await store.saveAthleteDraft(null);
      });
    }

    testWidgets('débutant : record inconnu impossible, aucune question de '
        'récupération ; un pas de plus pour le poids en street', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const AthleteProfileFlow()));
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-welcome');
      await tap(tester, 'flow-sex-male');
      final year = find.byKey(const ValueKey('flow-year'));
      await tester.enterText(year, '1995');
      await tester.enterText(find.byKey(const ValueKey('flow-height')), '180');
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-identity');
      await tap(tester, 'flow-discipline-calisthenics');
      await tap(tester, 'flow-next-discipline');
      // Poids obligatoire : carte sur l'écran de la discipline.
      expect(flow(tester).step, 'discipline');
      expect(find.byKey(const ValueKey('flow-weight-card')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('flow-weight')), '68');
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-discipline');
      expect(flow(tester).step, 'secondary');
      expect(flow(tester).visibleSteps, isNot(contains('recovery')));
      expect(flow(tester).visibleQuestionIds, contains('skills'));
      expect(flow(tester).visibleQuestionIds, isNot(contains('benchmarks')));
      await tap(tester, 'flow-secondary-mobility');
      await tap(tester, 'flow-next-secondary');
      expect(flow(tester).step, 'experience');
      await tap(tester, 'flow-experience-intermediate');
      expect(
        find.byKey(const ValueKey('q-training_age')),
        findsOneWidget,
        reason: 'intermédiaire : ancienneté demandée',
      );
      await tap(tester, 'q-training_age-months_6_to_24');
      expect(find.byKey(const ValueKey('q-training_gap')), findsOneWidget);
      expect(flow(tester).visibleSteps, contains('recovery'));
      // Retour au débutant : questions masquées.
      await tap(tester, 'flow-experience-beginner');
      expect(find.byKey(const ValueKey('q-training_age')), findsNothing);
      expect(flow(tester).visibleSteps, isNot(contains('recovery')));
    });

    testWidgets('records : ajout par la feuille, fourchettes sans le '
        'mouvement', (tester) async {
      phone(tester);
      final d = beginnerDraft()
        ..experience = ExperienceLevel.intermediate
        ..weight = '75'
        ..primary = TrainingDiscipline.streetlifting
        ..secondaries.clear();
      d.addSecondary(TrainingDiscipline.calisthenics);
      await store.saveAthleteDraft(d, step: 'levels', mode: 'create');
      await tester.pumpWidget(page(const AthleteProfileFlow()));
      await tester.pumpAndSettle();
      expect(flow(tester).step, 'levels');
      await tap(tester, 'benchmark-add');
      await tap(tester, 'benchmark-exercise');
      await tap(tester, 'picker-suggested-sl-traction-lestee');
      expect(find.byKey(const ValueKey('benchmark-kind-load_reps')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('benchmark-load')),
        '32,5',
      );
      await tester.enterText(find.byKey(const ValueKey('benchmark-reps')), '3');
      await tester.pumpAndSettle();
      await tap(tester, 'benchmark-rir-1');
      await tap(tester, 'benchmark-date-month');
      await tap(tester, 'benchmark-save');
      final b = flow(tester).draft.benchmarks!.single;
      expect(b.exerciseId, 'sl-traction-lestee');
      expect(b.externalLoadKg, 32.5);
      expect(b.rir, 1);
      expect(b.date, CivilDate(2026, 10, 1));
      expect(b.bodyWeightKg, 75, reason: 'pré-rempli avec le poids du profil');
      expect(find.byKey(const ValueKey('benchmark-0')), findsOneWidget);
      expect(
        flow(tester).draft.shownMovements.map((m) => m.exerciseId),
        isNot(contains('sl-traction-lestee')),
      );
      await store.saveAthleteDraft(null);
    });

    testWidgets('échéance : compétition de force avec un règlement '
        'pré-rempli', (tester) async {
      phone(tester);
      final d = beginnerDraft()
        ..experience = ExperienceLevel.elite
        ..weight = '73'
        ..primary = TrainingDiscipline.streetlifting
        ..secondaries.clear();
      d.addSecondary(TrainingDiscipline.calisthenics);
      await store.saveAthleteDraft(d, step: 'goals', mode: 'create');
      await tester.pumpWidget(page(const AthleteProfileFlow()));
      await tester.pumpAndSettle();
      await tap(tester, 'event-add');
      await tap(tester, 'event-kind-strength_competition');
      await tap(tester, 'event-date-month');
      await tap(tester, 'event-month-6');
      await tap(tester, 'event-priority-main');
      await tap(tester, 'event-preset-final_rep_2lift');
      expect(find.byKey(const ValueKey('event-lift-1')), findsOneWidget);
      await tap(tester, 'event-class-73');
      await tap(tester, 'event-save');
      final e = flow(tester).draft.events!.single;
      expect(e.kind, EventKind.strengthCompetition);
      expect(e.lifts!.map((l) => l.exerciseId), [
        'sl-traction-lestee',
        'sl-dips-leste',
      ]);
      expect(e.weightClassKg, 73);
      expect(e.dateApproximate, isTrue);
      expect(e.date.day, 15);
      expect(e.validate(), isEmpty);
      // Avec une échéance principale, la priorité est un mouvement de
      // compétition.
      expect(
        find.text('Lequel de tes mouvements de compétition est le plus en '
            'retard ?'),
        findsOneWidget,
      );
      await store.saveAthleteDraft(null);
    });

    testWidgets('Compléter mon profil : questions du schéma 3 seulement, '
        'programme inchangé', (tester) async {
      phone(tester);
      store.saveAthleteProfile(
        ProfileDraft.of(sampleAthleteProfile(on: civilOf(now)))
          ..consent = 'refused',
      );
      final programBefore = jsonEncode(backupOf(store)['logs']);
      await tester.pumpWidget(page(const ProfileScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-complete')), findsOneWidget);
      await tap(tester, 'profile-complete');
      final st = flow(tester);
      expect(
        st.visibleQuestionIds.every((id) => parcours.question(id)!.since == 3),
        isTrue,
      );
      expect(st.visibleSteps, isNot(contains('welcome')));
      expect(st.visibleSteps, isNot(contains('identity')));
      final steps = List.of(st.visibleSteps);
      for (final s in steps) {
        expect(flow(tester).step, s);
        if (s == 'recovery') await tap(tester, 'q-sleep-hours_7_plus');
        await tap(
          tester,
          s == steps.last ? 'flow-save' : 'flow-next-$s',
        );
      }
      expect(find.byType(AthleteProfileFlow), findsNothing);
      expect(store.athleteProfile!.sleep, SleepBand.hours7Plus);
      expect(store.athleteProfile!.schemaVersion, 3);
      expect(store.athlete!.programChangePending, isFalse);
      expect(jsonEncode(backupOf(store)['logs']), programBefore);
      // Questions laissées sans réponse : passées, plus reproposées.
      expect(
        store.profilePendingQuestions.map((q) => q.id),
        isNot(contains('stress')),
      );
    });

    for (final dark in [true, false]) {
      testWidgets(
        'texte à 200 % : récupération et records sans débordement '
        '(${dark ? 'sombre' : 'clair'})',
        (tester) async {
          phone(tester, size: const Size(320, 720));
          final d = beginnerDraft()
            ..experience = ExperienceLevel.advanced
            ..weight = '75'
            ..primary = TrainingDiscipline.streetlifting
            ..secondaries.clear();
          d.addSecondary(TrainingDiscipline.cardio);
          for (final step in ['experience', 'levels', 'goals', 'recovery']) {
            await store.saveAthleteDraft(d, step: step, mode: 'create');
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              page(const AthleteProfileFlow(), scale: 2, dark: dark),
            );
            await tester.pumpAndSettle();
            expect(flow(tester).step, step);
            expect(tester.takeException(), isNull, reason: step);
            await scrollToAction(
              tester,
              find.byKey(ValueKey('flow-next-$step')),
            );
            expect(tester.takeException(), isNull, reason: step);
          }
          await store.saveAthleteDraft(null);
        },
      );
    }
  });
}
