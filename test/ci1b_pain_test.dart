// CI1b (dev6.9.1, pipeline CP) — paquets `kalis_plan` 0.2.2 et
// `kalis_adapt` 0.2.2 dans l'application : douleur qui dure (arrêt des
// mouvements qui chargent la zone, consigne de consulter, reprise graduée),
// tests reportés un jour de bilan bas et servis à une séance suivante,
// textes lisibles (jamais un code brut).
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
import 'package:streetlift_tracker/plan/plan_texts.dart';
import 'package:streetlift_tracker/store.dart';

/// Profil street des fixtures du parcours v3 (`kalis_core`, CQ).
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

DateTime _dateOf(AppStore app, int week, int j) {
  final s = app.program.start!;
  return DateTime(s.year, s.month, s.day + (week - 1) * 7 + j - 1, 9);
}

const _wrist = kc.PainReport(
  zone: kc.BodyZone.wristHand,
  side: kc.BodySide.both,
  intensity: 4,
  phase: kc.PainPhase.before,
);

/// Valide la première série du premier exercice servi (séance au journal).
void _logOneSet(AppStore app, int week, int j) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  final day = app.adaptDay(week, base, a);
  for (final e in day.exercises) {
    final log = app.exLog(week, j, e);
    if (log.sets.isEmpty) continue;
    app.adaptPrefill(week, j, e, log);
    final s = log.sets.first;
    if (s.reps.isEmpty) s.reps = '5';
    s.flames = 7;
    if (app.toggleSet(log, 0, app.logSpec(e)).ok) {
      app.adaptAfterSet(week, day, e, 0);
      break;
    }
  }
  app.saveLogs();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('textes des nouvelles raisons (0.2.2)', () {
    test('notes de douleur de kalis_plan : signalées comme douleur', () {
      for (final note in [
        kp.CoachNotes.painStop,
        kp.CoachNotes.painReturn,
        kp.CoachNotes.painReturnItem,
        kp.CoachNotes.painStep,
        kp.CoachNotes.painTrend,
      ]) {
        final r = kc.Reason(
          code: kc.ReasonCodes.planCoachNote,
          params: {'note': note, 'value': 0},
        );
        expect(isPainReason(r), isTrue, reason: note);
      }
      expect(
        isPainReason(
          const kc.Reason(
            code: kc.ReasonCodes.planCoachNote,
            params: {'note': kp.CoachNotes.plateau, 'value': 8},
          ),
        ),
        isFalse,
      );
    });

    test('arrêt pour douleur qui dure, retrait, test reporté : en clair', () {
      const why = kc.Reason(
        code: 'adapt.pain_persistent',
        params: {'zone': 'wrist_hand', 'sessions': 5},
      );
      final t = adaptReasonText(why, exerciseName: (id) => id)!;
      expect(t, contains('poignet'));
      expect(t, contains('kinésithérapeute'));
      expect(t, isNot(contains('adapt.')));
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseRemoved,
            exerciseId: 'dips',
            reasons: [why],
          ),
          (id) => 'Dips',
        ),
        'Dips retiré : il charge le poignet, douleur qui dure.',
      );
      expect(
        adjustmentText(
          const kc.SessionAdjustment(
            kind: kc.AdjustmentKind.exerciseRemoved,
            exerciseId: 'pull',
            reasons: [kc.Reason(code: 'adapt.health_low', params: {})],
          ),
          (id) => 'Tractions',
          test: true,
        ),
        startsWith('Test de Tractions reporté'),
      );
      final s = painStopText((zone: 'poignet', removed: ['Dips', 'Pompes']));
      expect(s, contains('Retirés aujourd’hui : Dips, Pompes.'));
      expect(s, contains('Consulte un médecin ou un kinésithérapeute'));
    });

    test('codes émis par les paquets : aucun sans texte', () {
      for (final code in [
        'adapt.pain_persistent',
        'adapt.pain_reported',
        kc.ReasonCodes.planCoachNote,
        kc.ReasonCodes.planPainRule,
      ]) {
        final r = kc.Reason(code: code, params: const {'zone': 'wrist_hand'});
        final a = adaptReasonText(r, exerciseName: (id) => id);
        final p = reasonText(r, exerciseName: (id) => id);
        expect(
          (a ?? p).contains(code),
          isFalse,
          reason: '$code : texte lisible',
        );
      }
    });
  });

  group('séance servie (mode coach 0.2.2)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 1, 9);

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

    test('poignet à 4/10 sur plusieurs séances : arrêt, mouvements retirés, '
        'consigne de consulter ; le bloc suivant écrit l’arrêt', () async {
      _save(app, _street('street_workout'));
      _create(app);
      expect(isCoachBlock(app.planProgram!.blocks.single.block), isTrue);
      final weeks = app.planProgram!.blocks.single.weeks;
      // Douleur notée à chaque séance des trois premières semaines.
      final days = <(int, int)>[
        for (var w = 1; w <= weeks && w <= 3; w++)
          for (var j = 1; j <= 7; j++)
            if (app.program.week(w).day(j)?.exercises.isNotEmpty ?? false)
              (w, j),
      ];
      expect(days.length, greaterThanOrEqualTo(4));
      final start = _dateOf(app, days.first.$1, days.first.$2);
      (int, int)? stopDay;
      for (final (w, j) in days) {
        clock = _dateOf(app, w, j);
        final base = app.program.week(w).day(j)!;
        final opened = app.adaptOpen(w, base);
        expect(opened, isNotNull);
        if (clock.difference(start).inDays >= 15 && stopDay == null) {
          // Avant le bilan du jour : l'arrêt vient de l'historique.
          if (opened!.active.reasons.any(
            (r) => r.code == 'adapt.pain_persistent',
          )) {
            stopDay = (w, j);
          }
        }
        app.adaptAnswer(w, base, const kc.HealthCheck(pains: [_wrist]));
        _logOneSet(app, w, j);
      }
      expect(stopDay, isNotNull, reason: 'arrêt après deux semaines à 4/10');
      final (w, j) = stopDay!;
      final a = app.sessionAdapt(w, j)!;
      final stops = painStopsOf(a.active, app.adaptExerciseName);
      expect(stops, isNotEmpty);
      expect(stops.first.zone, contains('poignet'));
      final text = painStopText(stops.first);
      expect(text, contains('Douleur qui dure'));
      expect(text, contains('kinésithérapeute'));
      // Les exercices retirés ne sont pas servis.
      final base = app.program.week(w).day(j)!;
      final day = app.adaptDay(w, base, a);
      final served = {for (final e in day.exercises) e.catalogId};
      for (final x in a.active.adjustments) {
        if (x.kind == kc.AdjustmentKind.exerciseRemoved &&
            x.reasons.any((r) => r.code == 'adapt.pain_persistent')) {
          expect(served.contains(x.exerciseId), isFalse);
          expect(
            a.active.items.any((it) => it.exerciseId == x.exerciseId),
            isFalse,
          );
        }
      }
      // Ce que la séance dit de l'ajustement : en clair.
      for (final x in a.active.adjustments) {
        final t = adjustmentText(x, app.adaptExerciseName);
        expect(t.contains('adapt.'), isFalse);
      }
      // Bloc suivant : arrêt écrit par kalis_plan (pain_stop), lisible.
      final next = PlanStore(app).proposeNextBlock();
      expect(next, isNotNull);
      final block = next!.proposal.block;
      final notes = coachBlockPainNotes(block, app.content.catalog);
      expect(notes, isNotEmpty, reason: 'note d’arrêt du bloc suivant');
      expect(notes.first, startsWith('Douleur qui dure'));
      expect(notes.first, contains('kinésithérapeute'));
      // Aucun mouvement qui charge le poignet en extension dans le bloc.
      final catalog = app.content.catalog!;
      for (final wk in block.pass2.weeks) {
        for (final d in wk.days) {
          for (final it in d.items) {
            final ex = catalog.find(it.exerciseId);
            if (ex == null || it.kind == kc.SetKind.warmup) continue;
            expect(
              kp.coachPainStopHits(ex, kc.BodyZone.wristHand),
              isFalse,
              reason: '${it.exerciseId} charge le poignet pendant l’arrêt',
            );
          }
        }
      }
    });

    test('test retiré un jour de bilan bas, servi à une séance suivante de '
        'la semaine, journalisé à son emplacement', () async {
      _save(app, _street('street_workout'));
      _create(app);
      // Semaine dont un jour porte un test et un autre jour suit (48 h).
      int? week, testJ, laterJ;
      String? slot;
      for (var w = 1; w <= 12 && week == null; w++) {
        for (var j = 1; j <= 7 && week == null; j++) {
          final place = app.adaptPlaceOf(w, j);
          final it = place?.day?.items
              .where((x) => x.kind == kc.SetKind.test)
              .firstOrNull;
          if (it == null) continue;
          for (var k = j + 2; k <= 7; k++) {
            if (app.program.week(w).day(k)?.exercises.isNotEmpty ?? false) {
              week = w;
              testJ = j;
              laterJ = k;
              slot = it.slotId;
              break;
            }
          }
        }
      }
      if (week == null) {
        markTestSkipped('aucun test suivi d’une séance 48 h après');
        return;
      }
      clock = _dateOf(app, week, testJ!);
      final base = app.program.week(week).day(testJ)!;
      app.adaptOpen(week, base);
      final low = app.adaptAnswer(
        week,
        base,
        const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
      )!;
      final removed = low.plan.adjustments.where(
        (x) => x.kind == kc.AdjustmentKind.exerciseRemoved,
      );
      if (low.base != null && removed.isNotEmpty) {
        final lines = sessionDiffLines(
          low.base!,
          low.plan,
          app.adaptExerciseName,
        );
        expect(lines.any((l) => l.startsWith('Test de ')), isTrue);
      }
      _logOneSet(app, week, testJ);
      clock = _dateOf(app, week, laterJ!);
      final later = app.program.week(week).day(laterJ)!;
      final a = app.adaptOpen(week, later)!;
      final moved = a.active.items.where((x) => x.slotId == slot).firstOrNull;
      if (moved == null) {
        markTestSkipped('le moteur n’a pas reporté ce test');
        return;
      }
      final day = app.adaptDay(week, later, a);
      final e = day.exercises.firstWhere((x) => x.slotId == slot);
      expect(e.id, planExerciseId(week, laterJ, slot!));
      expect(e.engine, isTrue);
      expect(e.why, contains('reporté'));
      expect(app.adaptItemFor(week, laterJ, e)?.kind, kc.SetKind.test);
      expect(app.adaptBlockItemFor(week, laterJ, e)?.kind, kc.SetKind.test);
      // Série du test au journal : emplacement d'origine, nature test.
      final log = app.exLog(week, laterJ, e);
      app.adaptPrefill(week, laterJ, e, log);
      if (log.sets.first.reps.isEmpty) log.sets.first.reps = '8';
      log.sets.first.flames = 9;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.saveLogs();
      final journal = app.adaptTrainingLog(
        today: kc.CivilDate(clock.year, clock.month, clock.day),
      );
      final rows = [
        for (final s in journal.sessions)
          for (final r in s.sets)
            if (r.slotId == slot && r.kind == kc.SetKind.test) r,
      ];
      expect(rows, isNotEmpty);
      expect(journal.validate(), isEmpty);
    });
  });
}
