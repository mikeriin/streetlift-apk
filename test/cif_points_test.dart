// CIF (dev6.18.0, pipeline CP, lot CI final, DECISIONS_CP.md C17) — limites
// restantes de l'intégration (LIVRAISON_CI1*.md, parties « Limites ») :
// tentatives du jour J au journal (1), mini-séries au journal (2), conseils
// `miniSetsLeft` / `stepExerciseId` (3), série repère d'un maintien en
// secondes (4), simulateur du mode dev qui joue les techniques (5), règle
// CI1.4 retirée (7), carte « Pas encore » (8), contre-la-montre et test de
// course borné (9), migration depuis dev6.17.3 (programme de 40 semaines,
// C11.2). Le test reporté (6) est dans `cif_report_test.dart`, les écrans
// (8, 12) dans `cif_seance_test.dart`.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/adapt/clearance.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/journal_adapter.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

/// Profils types du parcours v3 (`kalis_core`, CQ).
kc.AthleteProfile _street(String primary) {
  final raw =
      jsonDecode(
            File(
              'packages/kalis_core/test/fixtures/profiles_v3.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>;
  return [
    for (final p in raw['profiles']! as List)
      kc.AthleteProfile.fromJson(
        ((p as Map)['profile'] as Map).cast<String, Object?>(),
      ),
  ].firstWhere((p) => p.disciplines.primary.code == primary);
}

void _save(AppStore app, kc.AthleteProfile p) {
  final r = app.saveAthleteProfile(ProfileDraft.of(p)..consent = 'refused');
  expect(r, isNotNull, reason: 'profil enregistré');
}

void _create(AppStore app) {
  final c = PlanStore(app).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(app).applyPlanCreation(c);
}

/// Programme de 40 semaines du propriétaire (fixture), journal jusqu'à
/// S[lastWeek]·J[lastJ], départ le 13/07/2026.
Future<void> _ownerAt(AppStore app, {int lastWeek = 13, int lastJ = 4}) async {
  final filled = filledBackup(app);
  final logs = (filled['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ);
  });
  filled['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(filled)), isTrue);
}

/// Profil d'exemple, avancé (mini-séries servies à partir d'« avancé »).
void _advanced(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: mode,
      ).copyWith(experience: kc.ExperienceLevel.advanced),
    )..consent = 'refused',
  );
}

const _s = kc.SetKind.work;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('textes (3, 4, 8, 9)', () {
    test('4 : série repère d’un maintien dite en secondes', () {
      const r = kc.Reason(code: 'adapt.benchmark_set', params: {'rir': 2.0});
      final reps = adaptReasonText(r)!;
      final hold = adaptReasonText(r, seconds: true)!;
      // ignore: avoid_print
      print('CIF4|$reps|$hold');
      expect(reps, contains('répétitions'));
      expect(hold, isNot(contains('répétitions')));
      expect(hold, contains('aussi longtemps que possible'));
      expect(hold, contains('2 en réserve'));
    });

    test('3 : mini-séries conseillées, étape plus facile, arrêt des '
        'mini-séries', () {
      const keep = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.keep,
        reasons: [],
        miniSetsLeft: 3,
      );
      expect(adviceText(keep, seconds: false), contains('3 mini-séries'));
      const keepNone = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.keep,
        reasons: [],
      );
      expect(adviceText(keepNone, seconds: false), isNull);
      const down = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.repsDown,
        reasons: [],
        nextRepsLow: 6,
        nextRepsHigh: 8,
        miniSetsLeft: 2,
      );
      expect(adviceText(down, seconds: false), contains('2 mini-séries'));
      const step = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.stopExercise,
        reasons: [
          kc.Reason(code: 'adapt.mini_set_stop', params: {'cause': 'quality'}),
          kc.Reason(
            code: 'adapt.skill_step_down',
            params: {'exerciseId': 'sw-tuck-planche'},
          ),
        ],
        stepExerciseId: 'sw-tuck-planche',
      );
      final t = adviceText(
        step,
        seconds: true,
        exerciseName: (id) => id == 'sw-tuck-planche' ? 'Tuck planche' : id,
      )!;
      // ignore: avoid_print
      print('CIF3|$t');
      expect(t, contains('Tuck planche'));
      expect(t, isNot(contains('Deux séries manquées')));
      const drop = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.stopExercise,
        reasons: [
          kc.Reason(
            code: 'adapt.mini_set_stop',
            params: {'cause': 'rep_drop'},
          ),
        ],
      );
      expect(adviceText(drop, seconds: false), contains('mini-séries'));
      expect(
        adviceText(drop, seconds: false),
        isNot(contains('Deux séries manquées')),
      );
      const failed = kc.IntraSessionAdvice(
        exerciseId: 'x',
        confidence: 1,
        action: kc.IntraSessionAction.stopExercise,
        reasons: [kc.Reason(code: 'adapt.set_failed', params: {})],
      );
      expect(
        adviceText(failed, seconds: false),
        contains('Deux séries manquées'),
      );
    });

    test('8 : la note qui dit déjà « En attendant » n’est pas répétée', () {
      expect(
        clearanceSaysWaiting(
          'Gêne déclarée à 6/10. En attendant, seuls les mouvements qui ne '
          'réveillent pas la douleur se font.',
        ),
        isTrue,
      );
      expect(
        clearanceSaysWaiting(
          'Avant la première semaine, prends l’avis d’un médecin.',
        ),
        isFalse,
      );
    });

    test('9 : contre-la-montre noté au chrono montant, distance gardée', () {
      const trial = kc.ExercisePrescription(
        slotId: 's1',
        exerciseId: 'ca-course',
        kind: kc.SetKind.test,
        sets: 1,
        distanceMeters: 5000,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.unloaded,
        reasons: [],
      );
      expect(prescriptionTimeTrial(trial), isTrue);
      expect(prescriptionInMeters(trial), isFalse);
      expect(adaptSetsText(trial), '1 × 5000 m chrono');
      const run = kc.ExercisePrescription(
        slotId: 's2',
        exerciseId: 'ca-course',
        kind: _s,
        sets: 1,
        distanceMeters: 3000,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.unloaded,
        reasons: [],
      );
      expect(prescriptionTimeTrial(run), isFalse);
      expect(adaptSetsText(run), '1 × 3000 m');
      expect(kRunTestCappedText, startsWith('Test reporté'));
    });
  });

  group('journal et profil (1, 2, 7, 9)', () {
    var clock = DateTime(2026, 10, 1, 9);
    late AppStore app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 1, 9);
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });

    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('1 : tentatives du jour J gardées et écrites au journal (rôle '
        '`attempt`, rang, `eventId`), une seule fois au moteur du jour J', () async {
      _save(app, _street('streetlifting'));
      _create(app);
      final e1 = app.athlete!.profile.events!.firstWhere((e) => e.id == 'e1');
      app.setEventAttempts('e1', const [
        kc.AttemptResult(
          exerciseId: 'sl-dips-leste',
          index: 0,
          loadKg: 100,
          success: true,
        ),
        kc.AttemptResult(
          exerciseId: 'sl-dips-leste',
          index: 1,
          loadKg: 107.5,
          success: false,
        ),
        kc.AttemptResult(
          exerciseId: 'sl-traction-lestee',
          index: 0,
          loadKg: 72.5,
          success: true,
        ),
      ]);
      await app.flush();
      // Relecture après redémarrage.
      final again = AppStore()..storeClock = () => clock;
      await again.init();
      expect(again.eventAttemptsOf('e1'), hasLength(3));
      expect(again.eventAttemptsOf('e2'), isEmpty);
      again.dispose();
      // Avant le jour J : rien au journal.
      expect(
        app.adaptTrainingLog().sessions.where((s) => s.eventId != null),
        isEmpty,
      );
      final log = app.adaptTrainingLog(today: e1.date.addDays(1));
      final ev = log.sessions.singleWhere((s) => s.id == 'event-e1');
      expect(ev.eventId, 'e1');
      expect(ev.date, e1.date);
      expect(
        [for (final x in ev.sets) (x.exerciseId, x.role, x.attemptIndex)],
        [
          ('sl-dips-leste', kc.SetRole.attempt, 0),
          ('sl-dips-leste', kc.SetRole.attempt, 1),
          ('sl-traction-lestee', kc.SetRole.attempt, 0),
        ],
      );
      expect(ev.sets.map((x) => x.success), [true, false, true]);
      expect(ev.sets.every((x) => x.kind == kc.SetKind.test), isTrue);
      expect(log.validate(), isEmpty);
      // Effacées : plus rien.
      app.setEventAttempts('e1', const []);
      expect(
        app
            .adaptTrainingLog(today: e1.date.addDays(1))
            .sessions
            .where((s) => s.id == 'event-e1'),
        isEmpty,
      );
    });

    test('1 : séance faite le jour d’une épreuve : `eventId` posé', () async {
      _save(app, _street('streetlifting'));
      _create(app);
      // Première journée servie par le moteur, une série validée.
      int? w0, j0;
      for (var w = 1; w <= 2 && w0 == null; w++) {
        for (var j = 1; j <= 7 && w0 == null; j++) {
          final d = app.program.week(w).day(j);
          if (d != null && d.exercises.isNotEmpty) {
            w0 = w;
            j0 = j;
          }
        }
      }
      final w = w0!, j = j0!;
      final s = app.program.start!;
      clock = DateTime(s.year, s.month, s.day + (w - 1) * 7 + j - 1, 9);
      final base = app.program.week(w).day(j)!;
      final a = app.adaptOpen(w, base)!;
      final day = app.adaptDay(w, base, a);
      var logged = false;
      for (final e in day.exercises) {
        final log = app.exLog(w, j, e);
        if (log.sets.isEmpty) continue;
        app.adaptPrefill(w, j, e, log);
        if (log.sets.first.reps.isEmpty) log.sets.first.reps = '5';
        log.sets.first.flames = 7;
        if (app.toggleSet(log, 0, app.logSpec(e)).ok) {
          logged = true;
          break;
        }
      }
      expect(logged, isTrue);
      app.saveLogs();
      final today = kc.CivilDate(clock.year, clock.month, clock.day);
      expect(
        app.adaptTrainingLog(today: today).sessions.last.eventId,
        isNull,
      );
      // Épreuve ce jour-là (préparation) : la séance la porte.
      final p = app.athlete!.profile;
      _save(
        app,
        p.copyWith(
          events: [
            for (final e in p.events!)
              e.id == 'e2' ? e.copyWith(date: today) : e,
          ],
        ),
      );
      final tl = app.adaptTrainingLog(today: today);
      expect(tl.sessions.last.eventId, 'e2');
      expect(tl.validate(), isEmpty);
    });

    test('7 : débutant sans ancienneté donné tel quel aux moteurs, chemin '
        'calibré ; passage d’un bloc 0.1 au chemin calibré gardé', () async {
      final beginner = _street('street_workout').copyWith(
        experience: kc.ExperienceLevel.beginner,
        trainingAge: null,
        events: const <kc.SeasonEvent>[],
      );
      _save(app, beginner);
      expect(app.athlete!.profile.trainingAge, isNull);
      expect(app.athleteProfileForEngines!.trainingAge, isNull);
      expect(PlanStore(app).planCoachEligible, isTrue);
      _create(app);
      expect(isCoachBlock(app.planProgram!.blocks.single.block), isTrue);
      final before = jsonEncode(app.planProgram!.toJson());
      final profile = jsonEncode(app.athlete!.profile.toJson());
      await app.flush();
      // Migration : relu tel quel (profil et bloc), suite au chemin calibré.
      final again = AppStore()..storeClock = () => clock;
      await again.init();
      expect(jsonEncode(again.athlete!.profile.toJson()), profile);
      expect(jsonEncode(again.planProgram!.toJson()), before);
      expect(again.athlete!.profile.trainingAge, isNull);
      final next = PlanStore(again).proposeNextBlock()!;
      expect(isCoachBlock(next.proposal.block), isTrue);
      again.dispose();
    });

    test('7 : bloc 0.1 d’un débutant sans ancienneté : « garder » reste au '
        '0.1, « passer » va au chemin calibré', () async {
      // Bloc 0.1 créé quand le profil n’était pas éligible (sans ancienneté,
      // intermédiaire), puis profil passé en débutant sans ancienneté.
      _save(app, _street('streetlifting').copyWith(trainingAge: null));
      expect(PlanStore(app).planCoachEligible, isFalse);
      _create(app);
      expect(isCoachBlock(app.planProgram!.blocks.single.block), isFalse);
      _save(
        app,
        _street('streetlifting').copyWith(
          trainingAge: null,
          experience: kc.ExperienceLevel.beginner,
        ),
      );
      expect(PlanStore(app).planCoachEligible, isTrue);
      expect(PlanStore(app).planOnLegacyEngine, isTrue);
      PlanStore(app).setPlanKeepLegacyEngine(true);
      expect(isCoachBlock(PlanStore(app).proposeNextBlock()!.proposal.block),
          isFalse);
      PlanStore(app).setPlanKeepLegacyEngine(false);
      expect(
        PlanStore(app).planNextBlockProfile!.trainingAge,
        kc.TrainingAge.under6Months,
      );
      expect(isCoachBlock(PlanStore(app).proposeNextBlock()!.proposal.block),
          isTrue);
      // Le profil enregistré n’est pas modifié.
      expect(app.athlete!.profile.trainingAge, isNull);
      expect(kp.coachEligible(app.athleteProfileForEngines!), isTrue);
    });

    test('9 : contre-la-montre du journal écrit au profil (`time_trial`, '
        'compétition le jour d’une épreuve)', () {
      final log = kc.TrainingLog(
        sessions: [
          kc.SessionRecord(
            id: 'a',
            date: kc.CivilDate(2026, 10, 3),
            origin: kc.SessionOrigin.program,
            resume: false,
            completed: true,
            sets: const [
              kc.SetRecord(
                exerciseId: 'ca-course',
                exerciseOrder: 0,
                setIndex: 0,
                kind: kc.SetKind.test,
                seconds: 1500,
                distanceMeters: 5000,
                success: true,
                excluded: false,
              ),
              // Trop court pour un repère d’allure.
              kc.SetRecord(
                exerciseId: 'ca-course',
                exerciseOrder: 0,
                setIndex: 1,
                kind: kc.SetKind.test,
                seconds: 120,
                distanceMeters: 400,
                success: true,
                excluded: false,
              ),
            ],
            pains: const [],
          ),
          kc.SessionRecord(
            id: 'b',
            date: kc.CivilDate(2026, 10, 10),
            origin: kc.SessionOrigin.program,
            resume: false,
            completed: true,
            eventId: 'r1',
            sets: const [
              kc.SetRecord(
                exerciseId: 'ca-course',
                exerciseOrder: 0,
                setIndex: 0,
                kind: kc.SetKind.test,
                seconds: 2950,
                distanceMeters: 10000,
                success: true,
                excluded: false,
              ),
            ],
            pains: const [],
          ),
        ],
      );
      final b = app.timeTrialBenchmarks(log);
      expect(b, hasLength(2));
      expect(b.first.kind, kc.BenchmarkKind.timeTrial);
      expect(b.first.source, kc.BenchmarkSource.guidedTest);
      expect((b.first.seconds, b.first.distanceMeters), (1500, 5000.0));
      expect(b.last.source, kc.BenchmarkSource.competition);
      for (final x in b) {
        expect(x.validate(), isEmpty);
      }
    });

    test('9 : temps d’un contre-la-montre journalisé avec sa distance', () {
      final doc = <String, dynamic>{
        'programStart': {'date': '2026-10-01'},
        'logs': {
          'S1-J3': {
            'done': true,
            'ex': {
              'x': {
                'sets': [
                  {'kg': '', 'reps': '1520', 'done': true},
                ],
              },
            },
            'exerciseNames': {'x': 'Course'},
          },
        },
      };
      final out = convertLegacyJournal(
        doc,
        exerciseId: (_) => 'ca-course',
        usesSeconds: (_) => false,
        dayOrder: (_, _) => const ['x'],
        legacyDate: (_, _) => DateTime(2026, 10, 3),
        testOf: (_, _, _) => true,
        lineOf: (_, _, _, _) => (
          exerciseId: null,
          seconds: true,
          scale: 1,
          technique: null,
          meters: false,
        ),
        distanceOf: (_, _, _) => 5000,
      );
      final r = out.log.sessions.single.sets.single;
      expect((r.kind, r.seconds, r.distanceMeters, r.reps), (
        kc.SetKind.test,
        1520,
        5000.0,
        null,
      ));
    });
  });

  group('programme de 40 semaines (2, 5, migration)', () {
    var clock = DateTime(2026, 10, 9, 9);
    late AppStore app;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 9, 9); // vendredi, S13·J5
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });

    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('2 : mini-séries corrigées (ordre changé) : le journal du moteur '
        'suit la saisie', () async {
      await _ownerAt(app);
      _advanced(app, kc.GuidanceMode.assisted);
      final base = app.program.week(13).day(5)!;
      final a = app.adaptOpen(13, base)!;
      final day = app.adaptDay(13, base, a);
      final e = day.exercises.firstWhere((x) => x.id.startsWith('B2-119'));
      final plan = app.miniSetPlanFor(13, 5, e, 0)!;
      final log = app.exLog(13, 5, e);
      final s = log.sets.first;
      s.parts = [
        SetPartEntry(plan.suggested(0)),
        SetPartEntry(4, restBefore: plan.intra),
        SetPartEntry(3, restBefore: plan.intra),
      ];
      s.reps = '${s.partsTotal}';
      s.flames = 9;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.saveLogs();
      List<int?> parts() => app
          .adaptTrainingLog(today: kc.CivilDate(2026, 10, 9))
          .sessions
          .where((x) => x.id == 'legacy-S13-J5')
          .expand((x) => x.sets)
          .firstWhere((x) => x.parts != null)
          .parts!
          .map((p) => p.reps)
          .toList();
      expect(parts(), [plan.suggested(0), 4, 3]);
      // Mêmes nombre et total, autre ordre : relu.
      s.parts = [
        SetPartEntry(plan.suggested(0)),
        SetPartEntry(3, restBefore: plan.intra),
        SetPartEntry(4, restBefore: plan.intra),
      ];
      app.saveLogs();
      expect(parts(), [plan.suggested(0), 3, 4]);
    });

    test('2 : ligne servie telle qu’écrite : pas de bandeau de mini-séries', () async {
      await _ownerAt(app, lastWeek: 20, lastJ: 0);
      _advanced(app, kc.GuidanceMode.assisted);
      var written = 0;
      for (var w = 13; w <= 26; w++) {
        for (var j = 1; j <= 7; j++) {
          final base = app.program.week(w).day(j);
          if (base == null) continue;
          for (final e in base.exercises) {
            if (!app.adaptAsWritten(w, e.slotId)) continue;
            written++;
            expect(app.miniSetPlanFor(w, j, e, 0), isNull, reason: e.id);
          }
        }
      }
      // ignore: avoid_print
      print('CIF2|lignes telles qu’écrites $written');
    });

    test('5 : simulateur du mode dev : mini-séries notées une à une, '
        'groupes notés par leur résultat', () async {
      await app.configureStart(DateTime(2026, 10, 9 - 19 * 7));
      _advanced(app, kc.GuidanceMode.assisted);
      final r = await runDevSimulation(
        app,
        athleteKey: 'avance_street',
        weeks: 1,
        seed: 3,
      );
      expect(r.error, isNull);
      var parts = 0, groups = 0;
      for (final l in app.logs.values) {
        groups += l.groups.length;
        for (final x in l.ex.values) {
          for (final s in x.sets) {
            if (s.done && (s.parts?.isNotEmpty ?? false)) {
              parts++;
              expect(s.partsTotal, int.parse(s.reps));
            }
          }
        }
      }
      // ignore: avoid_print
      print('CIF5|séances ${r.sessionsDone}|séries à mini-séries $parts|'
          'groupes $groups');
      expect(r.sessionsDone, greaterThan(0));
      expect(parts, greaterThan(0));
      expect(groups, greaterThan(0));
      final tl = app.adaptTrainingLog();
      expect(tl.validate(), isEmpty);
      expect(tl.sessions.expand((s) => s.sets).any((x) => x.parts != null),
          isTrue);
    });

    test('migration depuis dev6.17.3 : séances faites et sauvegarde '
        'd’origine intactes, réglages relus à l’identique', () async {
      await _ownerAt(app);
      _advanced(app, kc.GuidanceMode.assisted);
      app.captureProgramOrigin();
      await app.flush();
      final export = jsonDecode(app.exportAll()) as Map<String, dynamic>;
      final logs = jsonEncode(export['logs']);
      final origin = jsonEncode(app.programOrigin);
      final settings = jsonEncode(app.settings.toJson());
      expect(app.settings.toJson().containsKey('eventAttempts'), isFalse);
      final again = AppStore()..storeClock = () => clock;
      await again.init();
      final back = jsonDecode(again.exportAll()) as Map<String, dynamic>;
      expect(jsonEncode(back['logs']), logs);
      expect(jsonEncode(again.programOrigin), origin);
      expect(jsonEncode(again.settings.toJson()), settings);
      expect(again.canRestoreProgramOrigin, isTrue);
      again.dispose();
    });
  });
}
