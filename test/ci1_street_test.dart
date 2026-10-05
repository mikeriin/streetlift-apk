// CI1 (dev6.9.0, pipeline CP) — intégration du street calibré : un profil
// street au profil v3 complet passe par le chemin calibré de `kalis_plan`
// 0.2 (plan de saison, bloc au contrat 0.4.0) et par le mode coach de
// `kalis_adapt` 0.2 ; prescriptions avancées guidées et journalisées (rôles
// des lignes, chronos), vue de la saison, migration d'un programme 0.1
// (passage proposé à la fin du bloc, jamais imposé), résultats des tests
// reportés au profil, textes des nouveaux codes de raison, programme du
// propriétaire et autres disciplines inchangés.
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:kalis_plan/kalis_plan.dart' as kp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/plan/coach_texts.dart';
import 'package:streetlift_tracker/plan/plan_program.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/store.dart';

/// Profils types du parcours v3 (`kalis_core`, CQ).
List<kc.AthleteProfile> _fixtures() {
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
  ];
}

kc.AthleteProfile _street(String primary) =>
    _fixtures().firstWhere((p) => p.disciplines.primary.code == primary);

/// Débutant de calisthénie : profil street des fixtures ramené au début.
kc.AthleteProfile _beginner() => _street('street_workout').copyWith(
  experience: kc.ExperienceLevel.beginner,
  trainingAge: kc.TrainingAge.under6Months,
  events: const <kc.SeasonEvent>[],
);

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

/// Première journée (semaine, jour) dont le bloc écrit une prescription
/// qui vérifie [test].
({int week, int j, kc.ExercisePrescription item})? _find(
  AppStore app,
  bool Function(kc.ExercisePrescription) test, {
  int weeks = 6,
}) {
  for (var w = 1; w <= weeks; w++) {
    for (var j = 1; j <= 7; j++) {
      final place = app.adaptPlaceOf(w, j);
      for (final it in place?.day?.items ?? const <kc.ExercisePrescription>[]) {
        if (test(it)) return (week: w, j: j, item: it);
      }
    }
  }
  return null;
}

/// Vue de la saison du programme de [app] (null : pas de saison).
SeasonOverview? _view(AppStore app) {
  final plan = app.planProgram;
  if (plan == null) return null;
  final n = app.storeClock();
  return seasonOverview(
    plan,
    events: app.athlete?.profile.events ?? const <kc.SeasonEvent>[],
    today: DateTime(n.year, n.month, n.day),
    programStart: app.program.start,
    catalog: app.content.catalog,
  );
}

DateTime _dateOf(AppStore app, int week, int j) {
  final s = app.program.start!;
  return DateTime(s.year, s.month, s.day + (week - 1) * 7 + j - 1, 9);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chemin calibré', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 1, 9);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 1, 9);
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

    test('compétiteur de streetlifting : bloc calibré, saison, phases, '
        'échéance ; relu à l’identique après redémarrage', () async {
      _save(app, _street('streetlifting'));
      expect(PlanStore(app).planCoachEligible, isTrue);
      _create(app);
      final plan = app.planProgram!;
      expect(isCoachBlock(plan.blocks.single.block), isTrue);
      expect(plan.season, isNotNull);
      expect(plan.season!.phases, isNotEmpty);
      expect(plan.season!.validate(), isEmpty);
      final view = _view(app)!;
      expect(view.phases.length, plan.season!.phases.length);
      expect(view.phases.where((p) => p.current).length, lessThanOrEqualTo(1));
      expect(view.daysToEvent, isNotNull);
      expect(
        view.blockWeeks.length,
        plan.blocks.single.block.pass2.weeks.length,
      );
      expect(view.rules, isNotEmpty);
      // Section relue à l'identique.
      final json = jsonEncode(plan.toJson());
      expect(jsonEncode(PlanProgram.fromJson(jsonDecode(json)).toJson()), json);
      await app.flush();
      final next = AppStore()..storeClock = () => clock;
      await next.init();
      others.add(next);
      expect(jsonEncode(next.planProgram!.toJson()), json);
    });

    test('débutant de calisthénie : chemin calibré aussi, sans technique '
        'au-dessus de son niveau', () async {
      _save(app, _beginner());
      expect(PlanStore(app).planCoachEligible, isTrue);
      _create(app);
      final block = app.planProgram!.blocks.single.block;
      expect(isCoachBlock(block), isTrue);
      for (final w in block.pass2.weeks) {
        for (final d in w.days) {
          for (final it in d.items) {
            final k = it.technique?.kind;
            expect(
              k == null ||
                  k == kc.SetTechniqueKind.standard ||
                  k == kc.SetTechniqueKind.isometricHold ||
                  k == kc.SetTechniqueKind.skillPractice ||
                  k == kc.SetTechniqueKind.accentuatedEccentric ||
                  k == kc.SetTechniqueKind.emom ||
                  it.technique?.lastSetOnly == true,
              isTrue,
              reason: '${it.exerciseId} : ${k?.code}',
            );
            // Chaque prescription se lit en clair.
            expect(coachVolumeText(it), isNotEmpty);
          }
        }
      }
    });

    test('profils street d’exemple (session de test, émulateur) : valides, '
        'chemin calibré', () async {
      for (final b in [false, true]) {
        final p = sampleStreetProfile(beginner: b);
        expect(p.validate(), isEmpty, reason: 'débutant : $b');
        expect(app.content.catalog!.checkProfile(p), isEmpty);
        expect(kp.coachEligible(p), isTrue);
      }
      _save(app, sampleStreetProfile());
      _create(app);
      expect(app.planProgram!.season, isNotNull);
      expect(_view(app)?.event?.id, 'ci1-competition');
    });

    test(
      'autre discipline (musculation) : chemin 0.1, pas de saison',
      () async {
        _save(app, _street('musculation'));
        expect(PlanStore(app).planCoachEligible, isFalse);
        _create(app);
        final plan = app.planProgram!;
        expect(isCoachBlock(plan.blocks.single.block), isFalse);
        expect(plan.season, isNull);
        expect(_view(app), isNull);
      },
    );

    test('séance : série de tête puis séries allégées guidées, lignes '
        'nommées, journal avec les rôles', () async {
      _save(app, _street('streetlifting'));
      _create(app);
      final hit = _find(
        app,
        (it) => it.technique?.kind == kc.SetTechniqueKind.topSetBackoff,
      );
      expect(hit, isNotNull, reason: 'le bloc écrit une série de tête');
      clock = _dateOf(app, hit!.week, hit.j);
      final base = app.program.week(hit.week).day(hit.j)!;
      final a = app.adaptOpen(hit.week, base)!;
      final day = app.adaptDay(hit.week, base, a);
      final e = day.exercises.firstWhere((x) => x.slotId == hit.item.slotId);
      expect(e.engine, isTrue);
      final it = app.adaptItemFor(hit.week, hit.j, e)!;
      if (it.technique?.kind != kc.SetTechniqueKind.topSetBackoff) {
        // Technique retenue par le moteur ce jour-là (bilan, prérequis) :
        // séries classiques au même travail.
        expect(app.adaptRowLabel(hit.week, hit.j, e, 0), isNull);
        return;
      }
      expect(app.adaptRowLabel(hit.week, hit.j, e, 0), 'Tête');
      expect(app.adaptRowLabel(hit.week, hit.j, e, 1), 'A1');
      expect(app.adaptGoal(hit.week, hit.j, e, 0)!.role, kc.SetRole.top);
      expect(app.adaptGoal(hit.week, hit.j, e, 1)!.role, kc.SetRole.backOff);
      expect(coachVolumeText(it), contains('série de tête'));
      final log = app.exLog(hit.week, hit.j, e);
      expect(log.sets.length, it.sets);
      app.adaptPrefill(hit.week, hit.j, e, log);
      for (var i = 0; i < 2; i++) {
        if (log.sets[i].reps.isEmpty) log.sets[i].reps = '3';
        log.sets[i].flames = 7;
        expect(app.toggleSet(log, i, app.logSpec(e)).ok, isTrue);
        app.adaptAfterSet(hit.week, day, e, i);
      }
      app.saveLogs();
      final journal = app.adaptTrainingLog(
        today: kc.CivilDate(clock.year, clock.month, clock.day),
      );
      final rows = [
        for (final s in journal.sessions)
          for (final r in s.sets)
            if (r.slotId == it.slotId) r,
      ];
      expect(rows.length, 2);
      expect(rows[0].role, kc.SetRole.top);
      expect(rows[1].role, kc.SetRole.backOff);
      expect(journal.validate(), isEmpty);
    });

    test('maintien chronométré : ligne en secondes avec chrono, '
        'consigne de la technique', () async {
      _save(app, _street('street_workout'));
      _create(app);
      final hit = _find(
        app,
        (it) =>
            it.technique?.kind == kc.SetTechniqueKind.isometricHold &&
            it.secondsHigh != null,
      );
      if (hit == null) {
        markTestSkipped('aucun maintien chronométré dans ce bloc');
        return;
      }
      clock = _dateOf(app, hit.week, hit.j);
      final base = app.program.week(hit.week).day(hit.j)!;
      final a = app.adaptOpen(hit.week, base)!;
      final day = app.adaptDay(hit.week, base, a);
      final e = day.exercises.firstWhere((x) => x.slotId == hit.item.slotId);
      final sp = app.logSpec(e);
      expect(sp.kind == 'hold' || sp.kind == 'holdMax', isTrue);
      final it = app.adaptItemFor(hit.week, hit.j, e)!;
      expect(techniqueHint(it), isNotNull);
    });

    test('EMOM : chrono de l’application, lignes « M1 », aucun repos entre '
        'les minutes', () async {
      for (final key in ['street_workout', 'streetlifting']) {
        SharedPreferences.setMockInitialValues({});
        final s = AppStore()..storeClock = () => clock;
        await s.init();
        others.add(s);
        _save(s, _street(key));
        _create(s);
        final hit = _find(
          s,
          (it) => it.technique?.kind == kc.SetTechniqueKind.emom,
          weeks: 12,
        );
        if (hit == null) continue;
        clock = _dateOf(s, hit.week, hit.j);
        final base = s.program.week(hit.week).day(hit.j)!;
        final a = s.adaptOpen(hit.week, base)!;
        final day = s.adaptDay(hit.week, base, a);
        final e = day.exercises.firstWhere((x) => x.slotId == hit.item.slotId);
        final it = s.adaptItemFor(hit.week, hit.j, e)!;
        if (it.technique?.kind != kc.SetTechniqueKind.emom) continue;
        expect(e.timer?['type'], 'emom');
        expect(s.adaptRowLabel(hit.week, hit.j, e, 0), 'M1');
        expect(s.adaptRestAfter(hit.week, hit.j, e, 0), 0);
        return;
      }
      markTestSkipped('aucun EMOM dans ces blocs');
    });

    test('migration : programme 0.1 en cours gardé ; à la fin du bloc, '
        'passage proposé, « garder » reste au chemin 0.1', () async {
      // Profil sans ancienneté : chemin 0.1 (comme avant la mise à jour).
      _save(app, _street('streetlifting').copyWith(trainingAge: null));
      expect(PlanStore(app).planCoachEligible, isFalse);
      _create(app);
      final before = jsonEncode(app.planProgram!.toJson());
      expect(isCoachBlock(app.planProgram!.blocks.single.block), isFalse);
      // Le profil se complète (CU) : le bloc en cours ne change pas.
      _save(app, _street('streetlifting'));
      expect(PlanStore(app).planCoachEligible, isTrue);
      expect(jsonEncode(app.planProgram!.toJson()), before);
      expect(PlanStore(app).planOnLegacyEngine, isTrue);
      // « Garder le moteur actuel » : le bloc suivant reste au chemin 0.1.
      PlanStore(app).setPlanKeepLegacyEngine(true);
      expect(kp.coachEligible(PlanStore(app).planNextBlockProfile!), isFalse);
      // L'expérience déclarée reste (le chemin 0.1 la lit).
      expect(
        PlanStore(app).planNextBlockProfile!.experience,
        app.athlete!.profile.experience,
      );
      final kept = PlanStore(app).proposeNextBlock()!;
      expect(isCoachBlock(kept.proposal.block), isFalse);
      // « Passer au moteur calibré » : bloc suivant calibré.
      PlanStore(app).setPlanKeepLegacyEngine(false);
      expect(kp.coachEligible(PlanStore(app).planNextBlockProfile!), isTrue);
      final moved = PlanStore(app).proposeNextBlock()!;
      expect(isCoachBlock(moved.proposal.block), isTrue);
    });

    test(
      'programme du propriétaire : pas de saison, jamais régénéré',
      () async {
        expect(app.planProgram, isNull);
        final weeks = jsonEncode([for (final w in app.program.weeks) w.n]);
        expect(_view(app), isNull);
        expect(PlanStore(app).planOnLegacyEngine, isFalse);
        expect(jsonEncode([for (final w in app.program.weeks) w.n]), weeks);
      },
    );

    test('résultats des tests du moteur reportés au profil, une seule '
        'fois', () async {
      _save(app, _street('streetlifting'));
      final before = app.athlete!.profile.benchmarks?.length ?? 0;
      final b = kc.Benchmark(
        exerciseId: 'sl-traction-lestee',
        kind: kc.BenchmarkKind.loadReps,
        date: kc.CivilDate(2026, 10, 1),
        source: kc.BenchmarkSource.guidedTest,
        externalLoadKg: 70,
        reps: 3,
      );
      final review = kc.AdaptReview(
        state: const {},
        summary: kc.AdaptationSummary(
          asOf: kc.CivilDate(2026, 10, 1),
          weeksObserved: 1,
          sessionsPlanned: 1,
          sessionsCompleted: 1,
          unlockLevel: kc.UnlockLevel.loadsReps,
          confidence: 0,
          estimates: const [],
          pains: const [],
          avoidedExerciseIds: const [],
          reasons: const [],
        ),
        proposals: const [],
        log: const [],
        testResults: [b],
      );
      expect(AthleteProfileStore(app).reportEngineResults(review), isTrue);
      expect(app.athlete!.profile.benchmarks!.length, before + 1);
      expect(AthleteProfileStore(app).reportEngineResults(review), isFalse);
      expect(app.athlete!.profile.benchmarks!.length, before + 1);
      // Même test relu avec un autre poids de corps : pas de doublon ; test
      // d'avant le bloc : ignoré.
      final again = kc.AdaptReview(
        state: const {},
        summary: review.summary,
        proposals: const [],
        log: const [],
        testResults: [
          b.copyWith(bodyWeightKg: 80.0),
          b.copyWith(date: kc.CivilDate(2026, 9, 1), reps: 5),
        ],
      );
      expect(
        AthleteProfileStore(
          app,
        ).reportEngineResults(again, since: kc.CivilDate(2026, 9, 28)),
        isFalse,
      );
      expect(app.athlete!.profile.benchmarks!.length, before + 1);
    });
  });

  group('relevé', () {
    test('techniques écrites et servies par profil (journal du test)', () async {
      for (final (key, profile) in [
        ('competiteur', sampleStreetProfile()),
        ('debutant', sampleStreetProfile(beginner: true)),
        ('sets_reps', _street('street_workout')),
        ('elite', _street('streetlifting')),
      ]) {
        SharedPreferences.setMockInitialValues({});
        var clock = DateTime(2026, 10, 1, 9);
        final app = AppStore()..storeClock = () => clock;
        await app.init();
        _save(app, profile);
        _create(app);
        final block = app.planProgram!.blocks.single.block;
        final kinds = <String, int>{};
        for (final w in block.pass2.weeks) {
          for (final d in w.days) {
            for (final it in d.items) {
              final k = it.kind == kc.SetKind.test
                  ? 'test:${it.test?.kind.code}'
                  : (it.technique?.kind.code ?? 'classique');
              kinds[k] = (kinds[k] ?? 0) + 1;
            }
          }
        }
        // ignore: avoid_print
        print(
          'CI1 $key : ${block.pass2.weeks.length} semaines, '
          'phases ${app.planProgram!.season?.phases.map((p) => '${p.kind.code}/${p.weeks}').join(' ')} ; $kinds',
        );
        final hit = _find(app, (it) => it.technique != null, weeks: 2);
        if (hit != null) {
          clock = _dateOf(app, hit.week, hit.j);
          final base = app.program.week(hit.week).day(hit.j)!;
          final a = app.adaptOpen(hit.week, base);
          if (a != null) {
            final day = app.adaptDay(hit.week, base, a);
            for (final e in day.exercises.where((x) => x.engine)) {
              final it = app.adaptItemFor(hit.week, hit.j, e)!;
              // ignore: avoid_print
              print(
                '  S${hit.week}J${hit.j} ${e.name} : ${it.technique?.kind.code ?? '-'} '
                '${app.setsLabel(e)} lignes ${[for (var i = 0; i < it.sets; i++) app.adaptRowLabel(hit.week, hit.j, e, i) ?? '${i + 1}'].join(',')} '
                'chrono ${e.timer?['type']} mesure ${app.logSpec(e).kind}',
              );
            }
          }
        }
        await app.flush();
        app.dispose();
      }
    });
  });

  group('textes', () {
    test('chaque code de raison a une phrase (plan ou moteur dynamique)', () {
      for (final spec in kc.reasonRegistry) {
        final r = kc.Reason(code: spec.code, params: const {});
        final t = spec.code.startsWith('adapt.') ? adaptReasonText(r) : null;
        if (spec.code.startsWith('adapt.') && t == null) {
          // Codes internes 0.1 : rien à dire à l'utilisateur.
          continue;
        }
        expect(t ?? 'plan', isNot(contains('{')), reason: spec.code);
      }
      // Paramètres rendus en clair, pas en code.
      final t = adaptReasonText(
        const kc.Reason(
          code: 'plan.technique_withheld',
          params: {'technique': 'top_set_backoff', 'cause': 'level'},
        ),
      );
      expect(t, isNot(contains('top_set_backoff')));
      expect(t, contains('niveau'));
    });

    test('rôles des lignes et techniques : libellés', () {
      const p = kc.ExercisePrescription(
        slotId: 's',
        exerciseId: 'sl-traction-lestee',
        sets: 4,
        repsLow: 3,
        repsHigh: 3,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.bodyweightPlusExternal,
        technique: kc.SetTechnique(
          kind: kc.SetTechniqueKind.topSetBackoff,
          backoffSets: 3,
          backoffDropPct: .08,
          backoffRepsLow: 5,
          backoffRepsHigh: 5,
        ),
        reasons: [],
      );
      expect(p.validate(), isEmpty);
      expect(prescriptionRow(p, 0).role, kc.SetRole.top);
      expect(prescriptionRow(p, 2).role, kc.SetRole.backOff);
      expect(prescriptionRow(p, 2).low, 5);
      expect(planGoal(p, 1).role, kc.SetRole.backOff);
      expect(planGoal(p, 1).low, 5);
      expect(planGoal(p, 1).toTarget().role, kc.SetRole.backOff);
      expect(coachVolumeText(p), contains('−8'));
      for (final k in kc.SetTechniqueKind.values) {
        if (k == kc.SetTechniqueKind.standard) {
          expect(techniqueLabel(k), isNull);
        } else {
          expect(techniqueLabel(k), isNotEmpty);
        }
      }
      for (final k in kc.SeasonPhaseKind.values) {
        expect(phaseLabel(k.code), isNot(contains('_')));
      }
    });
  });
}
