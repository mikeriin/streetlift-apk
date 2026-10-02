// G6 (dev6.4.0, D1.6, D3, D5.8, D6) — création du profil d'athlète v2 :
// modèle (étapes, dosages, mouvements de référence, matériel, objectifs
// provisoires), magasin (enregistrement, santé, mode prudent, sauvegarde,
// import, refaire son profil, brouillon) et écrans (parcours complet,
// moins de 18 ans, reprise, texte à 200 %, Réglages › Profil).
// Données synthétiques ; horloge injectée ; stockage simulé.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/goal_suggestions_g6.dart';
import 'package:streetlift_tracker/program_explainer.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'phone_test_support.dart';

/// Brouillon complet et valide (musculation 80 %, mobilité 20 %).
ProfileDraft fullDraft({String consent = 'given'}) {
  final d = ProfileDraft()
    ..displayName = 'Alex'
    ..sex = Sex.female
    ..birthYear = '1992'
    ..height = '168'
    ..weight = '61,5'
    ..primary = TrainingDiscipline.musculation
    ..experience = ExperienceLevel.intermediate
    ..consent = consent
    ..guidance = GuidanceMode.free;
  d.addSecondary(TrainingDiscipline.mobility);
  d.levels['squat'] = 2; // 60 à 80 kg
  d.levels['pullups'] = -1; // je ne sais pas
  d.goals.add(
    Goal(
      id: 'goal-1',
      kind: GoalKind.habit,
      origin: GoalOrigin.user,
      createdOn: CivilDate(2026, 10, 1),
      sessionsPerWeek: 3,
      weeks: 8,
    ),
  );
  d.days
    ..[1] = 60
    ..[4] = 45;
  d.addPlace(Place.gym);
  if (consent == 'given') {
    d.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  }
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 12);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  group('modèle', () {
    late Catalog catalog;
    late List<String> vocabulary;
    setUpAll(() {
      catalog = store.content.catalog!;
      vocabulary = store.content.equipmentVocabulary;
    });

    test('matériel regroupé : tout le vocabulaire de la base, une fois', () {
      expect(vocabulary, hasLength(68));
      expect(kAllGroupedEquipment.toSet(), vocabulary.toSet());
      expect(kAllGroupedEquipment, hasLength(vocabulary.length));
      for (final p in kEquipmentPresets) {
        expect(catalog.checkEquipment(p.equipment), isEmpty, reason: p.id);
      }
    });

    test('mouvements de référence : exercices du catalogue, fourchettes '
        'ordonnées, disciplines couvertes', () {
      for (final m in kLevelMovements) {
        final e = catalog.find(m.exerciseId);
        expect(e, isNotNull, reason: m.key);
        expect(m.bands, isNotEmpty);
        for (final b in m.bands) {
          expect(b.low <= b.high, isTrue, reason: '${m.key} ${b.label}');
        }
        expect(
          m.measure == LevelMeasure.timeSeconds,
          m.distanceMeters != null,
          reason: m.key,
        );
      }
      for (final d in TrainingDiscipline.values) {
        expect(movementsFor([d]), isNotEmpty, reason: d.code);
      }
      final all = movementsFor(TrainingDiscipline.values);
      expect(all.length, kMaxLevelMovements);
      // La principale passe en premier.
      expect(
        movementsFor([
          TrainingDiscipline.mobility,
          TrainingDiscipline.musculation,
        ]).first.key,
        'deep_squat',
      );
    });

    test(
      'dosage : 1 à 2 secondaires, principale la plus grande, somme 100',
      () {
        final d = ProfileDraft()..primary = TrainingDiscipline.musculation;
        d.addSecondary(TrainingDiscipline.mobility);
        expect(d.primaryPct, 80);
        d.addSecondary(TrainingDiscipline.cardio);
        expect(d.primaryPct, 70);
        d.addSecondary(TrainingDiscipline.crossfit);
        expect(d.secondaries, hasLength(2));
        d.setSecondaryPct(TrainingDiscipline.mobility, 60);
        expect(
          d.primaryPct >= d.secondaries[TrainingDiscipline.mobility]!,
          isTrue,
        );
        expect(d.mix!.validate(), isEmpty);
        for (var pct = 0; pct <= 100; pct += 5) {
          d.setSecondaryPct(TrainingDiscipline.cardio, pct);
          expect(d.mix!.validate(), isEmpty, reason: '$pct');
        }
        expect(
          dosageInWords(TrainingDiscipline.mobility, 20),
          contains('1 séance sur 5'),
        );
        // Mode street : principale + deux autres dosées.
        final s = ProfileDraft()..setStreet(true);
        s.setStreetPrimary(StreetStyle.streetlifting);
        expect(s.streetMode!.validate(), isEmpty);
        expect(s.streetMode!.pctOf(StreetStyle.streetlifting), 60);
        s.setStreetPct(StreetStyle.calisthenics, 95);
        expect(s.streetMode!.validate(), isEmpty);
        s
          ..setStreetPct(StreetStyle.calisthenics, 0)
          ..setStreetPct(StreetStyle.setsReps, 0);
        expect(s.stepError('secondary', now), isNotNull);
        expect(s.mix!.primary, TrainingDiscipline.streetlifting);
      },
    );

    test('étapes : chaque réponse obligatoire est demandée', () {
      final d = ProfileDraft();
      expect(d.stepError('identity', now), isNotNull);
      d
        ..sex = Sex.male
        ..birthYear = '2008'
        ..height = '180';
      expect(d.stepError('identity', now), contains('18 ans'));
      d.adult18 = false;
      expect(d.isMinorIn(now.year), isTrue);
      d
        ..birthYear = '1990'
        ..adult18 = null
        ..height = '90';
      expect(d.stepError('identity', now), contains('taille'));
      d
        ..height = '180'
        ..weight = '400';
      expect(d.stepError('identity', now), contains('Poids'));
      d.weight = '';
      expect(d.stepError('identity', now), isNull);
      for (final s in [
        'discipline',
        'goals',
        'availability',
        'places',
        'health',
        'mode',
      ]) {
        expect(d.stepError(s, now), isNotNull, reason: s);
      }
      d.primary = TrainingDiscipline.cardio;
      expect(d.stepError('secondary', now), isNotNull);
      expect(d.build(now), isNull);
      expect(fullDraft().firstIncomplete(now), isNull);
    });

    test('profil v2 construit : contrat, catalogue, matériel par lieu', () {
      final d = fullDraft();
      final p = d.build(now, vocabulary: vocabulary)!;
      expect(p.validate(), isEmpty);
      expect(catalog.checkProfile(p), isEmpty);
      expect(p.bodyWeightKg, 61.5);
      expect(p.disciplines.primaryPct, 80);
      expect(p.equipmentByPlace, isNull);
      expect(p.availability.every((s) => s.place == null), isTrue);
      final squat = p.movementLevels.firstWhere(
        (l) => l.exerciseId == 'mu-back-squat-barre-haute',
      );
      expect((squat.low, squat.high, squat.known), (60.0, 80.0, true));
      expect(
        p.movementLevels
            .firstWhere((l) => l.exerciseId == 'sw-traction-pronation')
            .known,
        isFalse,
      );
      // Deux lieux au matériel différent : matériel par lieu et lieu du jour.
      d
        ..addPlace(Place.home)
        ..dayPlace[1] = Place.home;
      final q = d.build(now, vocabulary: vocabulary)!;
      expect(q.validate(), isEmpty);
      expect(q.equipmentByPlace, hasLength(2));
      expect(q.availability.first.place, Place.home);
      // Gênes : seulement avec l'accord santé.
      d.putLimitation(limitationOf(BodyZone.knee, BodySide.left, 5));
      expect(d.build(now)!.limitations.single.joint, Joint.knee);
      d.consent = 'refused';
      expect(d.build(now)!.limitations, isEmpty);
    });

    test('brouillon et section : aller-retour JSON identique', () {
      final d = fullDraft()
        ..putLimitation(limitationOf(BodyZone.shoulder, BodySide.both, 2));
      final back = ProfileDraft.fromJson(jsonDecode(jsonEncode(d.toJson())))!;
      expect(jsonEncode(back.toJson()), jsonEncode(d.toJson()));
      final p = d.build(now, vocabulary: vocabulary)!;
      final again = (ProfileDraft.of(
        p,
      )..consent = 'given').build(now, vocabulary: vocabulary)!;
      expect(jsonEncode(again.toJson()), jsonEncode(p.toJson()));
      final r = AthleteRecord(
        profile: p,
        savedAt: '2026-10-01T12:00:00',
        birthYearAt: '2026-10-01T12:00:00',
        limitationsAt: const {'shoulder|both': '2026-10-01T12:00:00'},
        changes: const [
          ProfileChange('2026-10-01T12:00:00', ['goals'], true),
        ],
      );
      final read = AthleteRecord.fromJson(jsonDecode(jsonEncode(r.toJson())));
      expect(jsonEncode(read.toJson()), jsonEncode(r.toJson()));
      final bad = r.toJson()..['v'] = 99;
      expect(() => AthleteRecord.fromJson(bad), throwsFormatException);
      final broken = jsonDecode(jsonEncode(r.toJson())) as Map;
      ((broken['profile'] as Map)['disciplines'] as Map)['primaryPct'] = 10;
      expect(() => AthleteRecord.fromJson(broken), throwsFormatException);
    });

    test('objectifs proposés (provisoires, G12) : valides et prudents', () {
      final d = fullDraft()..goals.clear();
      final list = provisionalGoalSuggestions(d, CivilDate(2026, 10, 1));
      expect(list, isNotEmpty);
      for (final g in list) {
        expect(g.validate(), isEmpty);
        expect(g.origin, GoalOrigin.suggested);
      }
      final squat = list.firstWhere((g) => g.metric == GoalMetric.oneRmKg);
      // Borne basse 60 kg : +7,5 % arrondi à 2,5 kg.
      expect(squat.targetValue, 65);
      final habit = list.firstWhere((g) => g.kind == GoalKind.habit);
      expect(habit.sessionsPerWeek, inInclusiveRange(2, 4));
      expect(list.map((g) => g.id).toSet(), hasLength(list.length));
    });

    test('rubriques changées et effet sur le programme', () {
      final a = fullDraft().build(now)!;
      final b =
          (ProfileDraft.of(a)
                ..consent = 'given'
                ..displayName = 'Sam')
              .build(now)!;
      expect(changedRubrics(a, b), {'identity'});
      expect(rubricsAffectProgram({'identity'}, a, b), isFalse);
      final c =
          (ProfileDraft.of(a)
                ..consent = 'given'
                ..days[6] = 30)
              .build(now)!;
      expect(changedRubrics(a, c), {'availability'});
      expect(rubricsAffectProgram({'availability'}, a, c), isTrue);
      final m =
          (ProfileDraft.of(a)
                ..consent = 'given'
                ..guidance = GuidanceMode.assisted)
              .build(now)!;
      expect(rubricsAffectProgram(changedRubrics(a, m), a, m), isFalse);
    });

    test('référence santé : sans réponse, prudent, standard', () {
      final h = HealthData();
      expect(
        healthRefOf(h, CautionStatus.off).outcome,
        HealthScreeningOutcome.notAnswered,
      );
      h
        ..consent = 'given'
        ..answeredAt = '2026-10-01T10:00:00'
        ..answers.addAll({for (final q in kHealthQuestions) q.id: false});
      expect(
        healthRefOf(h, CautionStatus.off).outcome,
        HealthScreeningOutcome.standard,
      );
      expect(
        healthRefOf(
          h,
          const CautionStatus(['discomfort'], true, false, true),
        ).outcome,
        HealthScreeningOutcome.cautious,
      );
      expect(
        healthRefOf(h, CautionStatus.off).answeredOn,
        CivilDate(2026, 10, 1),
      );
    });
  });

  group('magasin', () {
    late AppStore app;
    var clock = now;
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = now;
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

    Future<AppStore> relaunch() async {
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      return next;
    }

    test(
      'installation neuve : profil v2 enregistré, relu, sauvegardé',
      () async {
        expect(app.isFreshInstall, isTrue);
        expect(backupOf(app).containsKey('athleteProfile'), isFalse);
        final res = app.saveAthleteProfile(fullDraft());
        expect(res, isNotNull);
        expect(res!.program, isFalse, reason: 'création, pas de modification');
        expect(app.isFreshInstall, isFalse);
        expect(app.athleteRedoProposed, isFalse);
        final p = app.athleteProfile!;
        expect(p.validate(), isEmpty);
        expect(app.content.catalog!.checkProfile(p), isEmpty);
        expect(p.healthScreening!.outcome, HealthScreeningOutcome.standard);
        // Bloc santé (questionnaire L13) gardé dans la section L8.
        expect(app.profile!.health.consentGiven, isTrue);
        expect(app.profile!.fields, isEmpty);
        // Pesée du poids déclaré.
        expect(app.currentBodyweight, 61.5);
        // Koach actif par défaut, « Koach adapte la structure » aussi.
        expect(app.koach.enabled, isTrue);
        expect(app.koach.structure, isTrue);
        final json = backupOf(app);
        expect(json['athleteProfile']['v'], 1);
        expect(json['athleteProfile']['profile']['schemaVersion'], 2);
        final next = await relaunch();
        expect(
          jsonEncode(next.athlete!.toJson()),
          jsonEncode(app.athlete!.toJson()),
        );
      },
    );

    test('mode prudent avec le profil v2 : âge, gêne, accord daté', () {
      app.saveAthleteProfile(fullDraft());
      expect(app.caution.active, isFalse);
      // Gêne > 3/10 : prudent ; accord du médecin : levé.
      clock = clock.add(const Duration(minutes: 1));
      final d = app.athleteEditDraft()
        ..putLimitation(limitationOf(BodyZone.knee, BodySide.right, 6));
      final res = app.saveAthleteProfile(d)!;
      expect(res.rubrics, {'health'});
      expect(res.program, isTrue);
      expect(app.caution.active, isTrue);
      expect(app.caution.reasons, contains('discomfort'));
      expect(
        app.athleteProfile!.healthScreening!.outcome,
        HealthScreeningOutcome.cautious,
      );
      clock = clock.add(const Duration(minutes: 1));
      app.declareDoctorClearance();
      expect(app.caution.active, isFalse);
      expect(
        app.athleteProfile!.healthScreening!.outcome,
        HealthScreeningOutcome.standard,
      );
      // Nouvelle gêne après l'accord : de nouveau prudent.
      clock = clock.add(const Duration(minutes: 1));
      app.saveAthleteProfile(
        app.athleteEditDraft()
          ..putLimitation(limitationOf(BodyZone.shoulder, BodySide.left, 5)),
      );
      expect(app.caution.active, isTrue);
      // 65 ans (profil v2) : prudent.
      final old = fullDraft()..birthYear = '1955';
      app.saveAthleteProfile(old);
      expect(app.caution.reasons, contains('age65'));
    });

    test('retrait du consentement : gênes v2 effacées, sans réponse', () {
      app.saveAthleteProfile(
        fullDraft()
          ..putLimitation(limitationOf(BodyZone.lowerBack, BodySide.both, 2)),
      );
      expect(app.athleteProfile!.limitations, hasLength(1));
      clock = clock.add(const Duration(minutes: 1));
      app.setHealthConsent(false);
      expect(app.athleteProfile!.limitations, isEmpty);
      expect(
        app.athleteProfile!.healthScreening!.outcome,
        HealthScreeningOutcome.notAnswered,
      );
      expect(app.caution.active, isTrue);
      expect(jsonEncode(backupOf(app)).contains('lower_back'), isFalse);
      expect(app.athlete!.changes.last.rubrics, ['health']);
    });

    test('sauvegardes : ancienne sans profil v2, import strict, section '
        'illisible gardée au démarrage', () async {
      app.saveAthleteProfile(fullDraft());
      final exported = app.exportAll();
      expect(
        app.previewImport(exported).preview!.athleteProfilePresent,
        isTrue,
      );
      final old = backupOf(app)..remove('athleteProfile');
      expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
      expect(app.athlete, isNull);
      expect(app.athleteRedoProposed, isTrue);
      expect(await app.importBackup(exported), ImportStatus.success);
      expect(app.athlete, isNotNull);
      final bad = jsonDecode(exported) as Map<String, dynamic>;
      (bad['athleteProfile'] as Map)['v'] = 7;
      expect(await app.importBackup(jsonEncode(bad)), ImportStatus.invalid);
      expect(app.athlete, isNotNull);
      // Démarrage : section illisible gardée telle quelle (aucune perte).
      final m = backupOf(app);
      (m['athleteProfile'] as Map)['profile'] = {'schemaVersion': 2};
      await app.flush();
      SharedPreferences.setMockInitialValues({'kalis_state_v3': jsonEncode(m)});
      final tolerant = AppStore()..storeClock = () => clock;
      await tolerant.init();
      others.add(tolerant);
      expect(tolerant.athlete, isNull);
      expect(tolerant.athleteLoadIssues, 1);
      expect(backupOf(tolerant)['athleteProfile'], m['athleteProfile']);
      tolerant.saveSettings();
      await tolerant.flush();
      final again = AppStore()..storeClock = () => clock;
      await again.init();
      others.add(again);
      expect(backupOf(again)['athleteProfile'], m['athleteProfile']);
    });

    test(
      'refaire son profil (session personnelle) : rien d’autre ne change',
      () async {
        final state = filledBackup(app);
        expect(await app.importBackup(jsonEncode(state)), ImportStatus.success);
        final legacy = UserProfile(
          origin: 'migration',
          createdAt: '2026-09-26T10:00:00',
        );
        legacy.setField('birthYear', 1990, '2026-09-26T10:00:00');
        legacy.setField('days', [1, 3, 5], '2026-09-26T10:00:00');
        legacy.setField('sessionMinutes', 75, '2026-09-26T10:00:00');
        legacy.setField('places', {
          'park': ['pullup_bar', 'dip_bars', 'weight_belt'],
        }, '2026-09-26T10:00:00');
        app.saveProfile(legacy);
        await app.flush();
        final before = backupOf(app);
        expect(app.athleteRedoProposed, isTrue);
        await app.snoozeAthleteRedo();
        expect(app.athleteRedoProposed, isFalse);
        clock = clock.add(const Duration(days: 1));
        expect(app.athleteRedoProposed, isTrue);
        final d = app.athleteRedoDraft();
        expect(d.birthYear, '1990');
        expect(d.days, {1: 75, 3: 75, 5: 75});
        expect(d.places.keys, [Place.outdoor]);
        expect(
          d.places[Place.outdoor],
          containsAll(['barre fixe', 'barres parallèles', 'ceinture de lest']),
        );
        // Réponses complétées, puis enregistrement.
        d
          ..sex = Sex.male
          ..height = '178'
          ..weight = ''
          ..setStreet(true)
          ..setStreetPrimary(StreetStyle.streetlifting)
          ..guidance = GuidanceMode.assisted
          ..consent = 'refused';
        d.goals.add(
          Goal(
            id: 'goal-1',
            kind: GoalKind.habit,
            origin: GoalOrigin.user,
            createdOn: CivilDate(2026, 10, 2),
            sessionsPerWeek: 3,
            weeks: 12,
          ),
        );
        expect(app.saveAthleteProfile(d), isNotNull);
        final after = backupOf(app);
        expect(after.remove('athleteProfile'), isNotNull);
        final legacyAfter = after.remove('profile') as Map;
        final legacyBefore = before.remove('profile') as Map;
        // Koach (jamais activé) : actif par défaut, structure adaptée.
        after.remove('koach');
        before.remove('koach');
        expect(app.koach.enabled, isTrue);
        expect(app.koach.structure, isTrue);
        expect(
          after,
          before,
          reason: 'programme, historique et réglages intacts',
        );
        // Profil L8 conservé (lecture, import) ; seul le refus santé daté.
        expect(legacyAfter['fields'], legacyBefore['fields']);
        expect(app.athleteRedoProposed, isFalse);
      },
    );

    test(
      'brouillon : hors sauvegarde, repris, effacé avec les données',
      () async {
        final d = fullDraft();
        await app.saveAthleteDraft(d, step: 'places', mode: 'create');
        final back = app.athleteDraft!;
        expect(back.step, 'places');
        expect(back.mode, 'create');
        expect(jsonEncode(back.draft.toJson()), jsonEncode(d.toJson()));
        expect(app.exportAll().contains('athlete_profile_draft'), isFalse);
        await app.eraseAllData();
        expect(app.athleteDraft, isNull);
      },
    );
  });

  group('écrans', () {
    setUp(() async {
      store.debugWriteHook = null;
      await store.eraseAllData();
      store.storeClock = () => now;
      store.settings
        ..sound = false
        ..vibration = false
        ..wakelock = false;
    });
    tearDown(() {
      store.debugWriteHook = null;
      store.storeClock = DateTime.now;
    });

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

    Future<void> type(WidgetTester tester, String key, String text) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.enterText(f, text);
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(ValueKey(key));
      await scrollToAction(tester, f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    AthleteProfileFlowState flow(WidgetTester tester) =>
        tester.state<AthleteProfileFlowState>(find.byType(AthleteProfileFlow));

    /// Parcours complet, réponses les plus courtes ; renvoie les écrans vus.
    Future<Set<String>> runFlow(WidgetTester tester) async {
      final seen = <String>{flow(tester).step};
      Future<void> next(String step) async {
        await tap(tester, 'flow-next-$step');
        final i = kAthleteSteps.indexOf(step);
        expect(flow(tester).step, kAthleteSteps[i + 1], reason: 'après $step');
        seen.add(flow(tester).step);
      }

      await next('welcome');
      await tap(tester, 'flow-sex-female');
      await type(tester, 'flow-year', '1994');
      await type(tester, 'flow-height', '170');
      await tester.pumpAndSettle();
      await next('identity');
      await tap(tester, 'flow-discipline-general_fitness');
      await next('discipline');
      await tap(tester, 'flow-secondary-mobility');
      await next('secondary');
      await tap(tester, 'level-pushups-2');
      await next('levels');
      await tap(tester, 'goal-suggest');
      await tap(tester, 'goal-suggestion-0');
      await tap(tester, 'goal-suggestions-add');
      await next('goals');
      await tap(tester, 'flow-day-2');
      await tap(tester, 'flow-day-5');
      await next('availability');
      await tap(tester, 'flow-place-maison');
      await next('places');
      await tap(tester, 'flow-consent-refused');
      await next('health');
      await next('preferences');
      await tap(tester, 'flow-mode-assisted');
      await next('mode');
      expect(flow(tester).step, 'recap');
      await tap(tester, 'flow-next-recap');
      return seen;
    }

    testWidgets('installation neuve : 12 écrans, profil valide, attente du '
        'programme', (tester) async {
      phone(tester);
      await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('flow-welcome')), findsOneWidget);
      expect(find.byKey(const ValueKey('flow-koach-welcome')), findsOneWidget);
      final seen = await runFlow(tester);
      expect(seen, kAthleteSteps.toSet());
      expect(find.byKey(const ValueKey('flow-done')), findsOneWidget);
      expect(find.textContaining('Ton profil est prêt'), findsOneWidget);
      final p = store.athleteProfile!;
      expect(p.validate(), isEmpty);
      expect(store.content.catalog!.checkProfile(p), isEmpty);
      expect(p.disciplines.primary, TrainingDiscipline.generalFitness);
      expect(p.goals, hasLength(1));
      expect(p.availability.map((s) => s.weekday), [2, 5]);
      expect(p.places, [Place.home]);
      expect(p.guidanceMode, GuidanceMode.assisted);
      expect(store.athleteDraft, isNull);
      await tap(tester, 'flow-done-continue');
      expect(find.text('ACCUEIL'), findsOneWidget);
    });

    testWidgets('moins de 18 ans : message neutre, aucune écriture', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-welcome');
      await tap(tester, 'flow-sex-male');
      await type(tester, 'flow-year', '2012');
      await type(tester, 'flow-height', '160');
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-identity');
      expect(find.byKey(const ValueKey('minor-message')), findsOneWidget);
      expect(store.athleteDraft, isNull);
      expect(store.athlete, isNull);
      expect(store.profile, isNull);
      await tap(tester, 'minor-back');
      expect(flow(tester).step, 'identity');
    });

    testWidgets('fermer pendant la création : reprise à la même étape', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-welcome');
      await tap(tester, 'flow-sex-male');
      await type(tester, 'flow-year', '1990');
      await type(tester, 'flow-height', '181');
      await tester.pumpAndSettle();
      await tap(tester, 'flow-next-identity');
      await tap(tester, 'flow-discipline-cardio');
      // Fermeture (arrière-plan) puis nouvelle ouverture.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(store.athleteDraft!.step, 'discipline');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
      await tester.pumpAndSettle();
      expect(flow(tester).step, 'discipline');
      expect(flow(tester).draft.primary, TrainingDiscipline.cardio);
      expect(flow(tester).draft.heightValue, 181);
    });

    for (final dark in [true, false]) {
      testWidgets(
        'texte à 200 % sans débordement (${dark ? 'sombre' : 'clair'})',
        (tester) async {
          phone(tester, size: const Size(320, 720));
          await tester.pumpWidget(
            page(
              const ProfileGate(child: Text('ACCUEIL')),
              scale: 2,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tap(tester, 'flow-next-welcome');
          expect(tester.takeException(), isNull, reason: 'identité');
          await tap(tester, 'flow-sex-undisclosed');
          await type(tester, 'flow-year', '1985');
          await type(tester, 'flow-height', '175');
          await tester.pumpAndSettle();
          await tap(tester, 'flow-next-identity');
          expect(tester.takeException(), isNull, reason: 'discipline');
          await tap(tester, 'flow-street');
          await tap(tester, 'flow-style-calisthenics');
          await tap(tester, 'flow-next-discipline');
          expect(tester.takeException(), isNull, reason: 'dosage street');
          await scrollToAction(
            tester,
            find.byKey(const ValueKey('flow-slider-streetlifting')),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Réglages › Profil : rubrique modifiée, Koach signale le '
        'programme ; santé', (tester) async {
      phone(tester);
      store.saveAthleteProfile(fullDraft());
      await tester.pumpWidget(page(const ProfileScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-koach')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-rubric-identity')),
        findsOneWidget,
      );
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('profile-rubric-mode')),
      );
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('profile-rubric-identity')),
        up: true,
      );
      await tap(tester, 'profile-edit-availability');
      expect(flow(tester).step, 'availability');
      await tap(tester, 'flow-day-7');
      await tap(tester, 'flow-save');
      expect(find.byKey(const ValueKey('koach-sheet')), findsOneWidget);
      expect(find.textContaining('touche ton programme'), findsOneWidget);
      // G7 : Koach propose de recréer le programme ; « Plus tard ».
      await tap(tester, 'profile-program-later');
      expect(store.athleteProfile!.availability.last.weekday, 7);
      expect(store.athlete!.programChangePending, isTrue);
      // Santé : retrait de l'accord.
      await tap(tester, 'profile-consent-withdraw');
      await tap(tester, 'withdraw-confirm');
      expect(store.profile!.health.consent, 'withdrawn');
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('caution-state')),
        up: true,
      );
      expect(find.text('Mode prudent activé'), findsOneWidget);
    });

    testWidgets('correction 1 : objectif modifié sans être supprimé', (
      tester,
    ) async {
      phone(tester);
      store.saveAthleteProfile(fullDraft());
      await tester.pumpWidget(
        page(
          const AthleteProfileFlow(
            mode: AthleteFlowMode.edit,
            editStep: 'goals',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tap(tester, 'flow-goal-edit-0');
      expect(find.byKey(const ValueKey('goal-habit-sheet')), findsOneWidget);
      await tap(tester, 'goal-weeks-12');
      await tap(tester, 'goal-save');
      expect(flow(tester).draft.goals, hasLength(1));
      await tap(tester, 'flow-save');
      final g = store.athleteProfile!.goals.single;
      expect((g.id, g.weeks, g.sessionsPerWeek), ('goal-1', 12, 3));
    });

    testWidgets('correction 1 : toute la base dans la recherche des '
        'exercices aimés et détestés', (tester) async {
      phone(tester);
      store.saveAthleteProfile(fullDraft());
      await tester.pumpWidget(
        page(
          const AthleteProfileFlow(
            mode: AthleteFlowMode.edit,
            editStep: 'preferences',
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Sans recherche : les exercices des disciplines choisies, par pages.
      expect(find.byKey(const ValueKey('flow-pref-more')), findsOneWidget);
      await type(tester, 'flow-pref-search', 'traction');
      final more = find.byKey(const ValueKey('flow-pref-more'));
      expect(more, findsOneWidget, reason: 'plus de 20 tractions');
      final shown = find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'flow-pref-result-',
                ),
            skipOffstage: false,
          )
          .evaluate()
          .length;
      expect(shown, greaterThan(8));
      await tap(tester, 'flow-pref-more');
      final search = find.byKey(const ValueKey('flow-pref-search'));
      await scrollToAction(tester, search, up: true);
      await tester.enterText(search, 'traction lestée de compétition');
      await tester.pumpAndSettle();
      await tap(tester, 'flow-like-sl-traction-lestee');
      expect(flow(tester).draft.liked, contains('sl-traction-lestee'));
    });

    testWidgets('correction 1 : nouveau profil sans programme, Koach '
        'explique la création et la gestion du programme', (tester) async {
      phone(tester);
      expect(programPendingFor(store), isFalse);
      store.saveAthleteProfile(fullDraft());
      expect(programPendingFor(store), isTrue);
      await tester.pumpWidget(page(const ProgramPendingView()));
      await tester.pumpAndSettle();
      await tap(tester, 'program-explainer-open');
      expect(find.byKey(const ValueKey('program-explainer')), findsOneWidget);
      expect(find.text('2. Tu passes en revue'), findsOneWidget);
      await store.configureStart(DateTime(2026, 10, 5));
      expect(programPendingFor(store), isFalse);
    });

    testWidgets('session personnelle sans profil v2 : Koach propose, « Plus '
        'tard » ouvre l’application', (tester) async {
      phone(tester);
      final legacy = UserProfile(
        origin: 'onboarding',
        createdAt: '2026-09-26T10:00:00',
      )..setField('birthYear', 1990, '2026-09-26T10:00:00');
      store.saveProfile(legacy);
      await tester.pumpWidget(page(const ProfileGate(child: Text('ACCUEIL'))));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('redo-proposal')), findsOneWidget);
      await tap(tester, 'redo-start');
      expect(flow(tester).step, 'welcome');
      expect(flow(tester).draft.birthYear, '1990');
      await tap(tester, 'flow-back');
      expect(find.byKey(const ValueKey('redo-proposal')), findsOneWidget);
      await tap(tester, 'redo-later');
      expect(find.text('ACCUEIL'), findsOneWidget);
    });
  });
}
