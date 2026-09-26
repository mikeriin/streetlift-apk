// L4b — Séances et reprise : KT-009 (validation des saisies) et KT-018
// (chronos, reprise après interruption, fin de séance, notifications).
// Décisions du 26/09/2026 : valeur obligatoire pour valider une série ;
// repos non relancé après destruction ; WOD repris en pause au dernier point
// sûr ; plusieurs brouillons possibles, un seul WOD chronométré à la fois.
//
// Horloges contrôlées (murale + monotone injectées), stockage simulé,
// données synthétiques. « Relance » = nouvelle instance du store sur le même
// stockage simulé : ce n'est ni une destruction Android, ni un redémarrage.

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/resume_banner.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/set_validation.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/timers.dart';
import 'package:streetlift_tracker/wod_formats.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_screen.dart';

const _key = 'kalis_state_v3';

/// Première journée d'entraînement dont le premier exercice est en reps.
(WeekPlan, DayPlan) _repsDay(AppStore app) {
  for (final w in app.program.weeks) {
    for (final d in w.days) {
      if (d.exercises.isEmpty) continue;
      if (app.logSpec(d.exercises.first).kind == 'reps') return (w, d);
    }
  }
  throw StateError('aucune journée en reps');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  group('A. Saisie : règles de format (KT-009)', () {
    test('charge : virgule, point, blancs, assistance ; ambigus refusés', () {
      expect(parseLoadKg('72,5'), 72.5);
      expect(parseLoadKg('72.5'), 72.5);
      expect(parseLoadKg(' 72,5 '), 72.5);
      expect(parseLoadKg(' 72,5 '), 72.5);
      expect(parseLoadKg('-10'), -10);
      expect(parseLoadKg('−7,5'), -7.5);
      expect(parseLoadKg('0'), 0);
      expect(parseLoadKg('-0'), 0);
      expect(parseLoadKg('10000'), 10000);
      for (final bad in [
        '1.250', // séparateur ambigu : jamais 1250 ni 1,25 en silence
        '72 5',
        '1e3',
        'NaN',
        'Infinity',
        '72,5 kg',
        '--5',
        '10000,01',
        '',
        ',5',
      ]) {
        expect(parseLoadKg(bad), isNull, reason: bad);
      }
    });

    test('reps, secondes, minutes : entiers sans unité', () {
      expect(parseWholeNumber('8'), 8);
      expect(parseWholeNumber(' 12 '), 12);
      for (final bad in ['7,5', '8 reps', '-3', '1e2', '', '３']) {
        expect(parseWholeNumber(bad), isNull, reason: bad);
      }
    });

    test('RIR et RPE : échelles distinctes, pas de 0,5', () {
      expect(parseEffort('0', rpe: false), 0);
      expect(parseEffort('2,5', rpe: false), 2.5);
      expect(parseEffort('12', rpe: false), 12);
      expect(parseEffort('2,3', rpe: false), isNull);
      expect(parseEffort('-1', rpe: false), isNull);
      expect(parseEffort('0', rpe: true), isNull);
      expect(parseEffort('8,5', rpe: true), 8.5);
      expect(parseEffort('10', rpe: true), 10);
      expect(parseEffort('11', rpe: true), isNull);
      expect(parseVelocity('0,45'), 0.45);
      expect(parseVelocity('0'), isNull);
      expect(parseVelocity('1.2345'), isNull);
    });

    test('valeur obligatoire ; zéro seulement pour un test max', () {
      SetCheck check(String kind, SetEntry e) =>
          checkSet(LogSpec(kind), e, rpe: false);
      expect(check('reps', SetEntry()).field, SetField.value);
      expect(check('reps', SetEntry(reps: '8')).ok, isTrue);
      expect(check('reps', SetEntry(reps: '0')).field, SetField.value);
      expect(check('repsMax', SetEntry(reps: '0')).ok, isTrue);
      expect(check('hold', SetEntry(reps: '0')).field, SetField.value);
      expect(check('holdMax', SetEntry(reps: '0')).ok, isTrue);
      expect(check('duration', SetEntry(reps: '12')).ok, isTrue);
      expect(check('reps', SetEntry(reps: '7,5')).field, SetField.value);
      expect(check('reps', SetEntry(reps: '8', kg: 'abc')).field, SetField.kg);
      expect(check('reps', SetEntry(reps: '8', kg: '-15')).ok, isTrue);
      expect(
        check('reps', SetEntry(reps: '8', rir: '2,3')).field,
        SetField.effort,
      );
      expect(
        check('reps', SetEntry(reps: '8', v: '0')).field,
        SetField.velocity,
      );
      expect(
        checkSet(
          const LogSpec('reps'),
          SetEntry(reps: '8', rir: '0'),
          rpe: true,
        ).field,
        SetField.effort,
      );
      expect(
        check('hold', SetEntry()).message,
        'Indique le nombre de secondes pour valider la série.',
      );
    });
  });

  // ===================================================================
  group('A/B/D. Store : coche, reprise, fin', () {
    late AppStore app;
    var now = DateTime(2026, 9, 26, 18);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 9, 26, 18);
      app = AppStore()..storeClock = () => now;
      await app.init();
      app.settings.sound = app.settings.vibration = false;
      app.program.start = DateTime(2026, 7, 13);
    });
    tearDown(() async {
      app.debugWriteHook = null;
      await app.flush();
      app.dispose();
      for (final o in others) {
        o.dispose();
      }
      others.clear();
    });

    Future<AppStore> relaunch() async {
      final next = AppStore()..storeClock = () => now;
      await next.init();
      others.add(next);
      return next;
    }

    test('coche refusée : rien validé, texte gardé ; puis acceptée', () async {
      final (w, d) = _repsDay(app);
      final ex = d.exercises.first;
      final log = app.exLog(w.n, d.j, ex);
      final spec = app.logSpec(ex);
      final xp = app.xp;
      log.sets[0].reps = '8 reps';
      final refused = app.toggleSet(log, 0, spec);
      expect(refused.field, SetField.value);
      expect(log.sets[0].done, isFalse);
      expect(log.sets[0].completedAt, isNull);
      expect(log.sets[0].reps, '8 reps');
      log.sets[0].reps = '8';
      log.sets[0].kg = '-10'; // assistance
      expect(app.toggleSet(log, 0, spec).ok, isTrue);
      expect(log.sets[0].done, isTrue);
      expect(log.sets[0].completedAt, now.toIso8601String());
      expect(log.sets[0].kg, '-10');
      // Décocher puis recocher : aucun gain supplémentaire.
      final after = app.xp;
      app.toggleSet(log, 0, spec);
      app.toggleSet(log, 0, spec);
      expect(app.xp, after);
      expect(after, xp); // XP de séance au moment de la fin, pas par série
      await app.flush();
      final next = await relaunch();
      expect(
        next.logs[app.sessionKey(w.n, d.j)]!.ex[ex.id]!.sets[0].done,
        isTrue,
      );
    });

    test('série validée puis modifiée : repasse non validée si invalide', () {
      final (w, d) = _repsDay(app);
      final ex = d.exercises.first;
      final log = app.exLog(w.n, d.j, ex);
      final spec = app.logSpec(ex);
      log.sets[0].reps = '8';
      expect(app.toggleSet(log, 0, spec).ok, isTrue);
      log.sets[0].reps = '9';
      expect(app.revalidateSet(log, 0, spec), isNull);
      expect(log.sets[0].done, isTrue);
      log.sets[0].reps = '9,';
      final issue = app.revalidateSet(log, 0, spec);
      expect(issue?.field, SetField.value);
      expect(log.sets[0].done, isFalse);
      expect(log.sets[0].reps, '9,');
    });

    test('suggestion affichée ≠ performance ; livres sans conversion', () {
      final (w, d) = _repsDay(app);
      final ex = d.exercises.first;
      final log = app.exLog(w.n, d.j, ex);
      log.sets[0].reps = '8'; // pré-remplissage : brouillon
      log.sets[0].kg = '20';
      final key = app.sessionKey(w.n, d.j);
      expect(app.inProgress(key), isFalse);
      expect(app.progression.sets, 0);
      app.settings.lb = true;
      app.saveSettings();
      expect(log.sets[0].kg, '20');
      expect(app.toggleSet(log, 0, app.logSpec(ex)).ok, isTrue);
      expect(app.progression.sets, 1);
      expect(log.sets[0].kg, '20');
    });

    test('séance en cours : même occurrence, page de reprise, bandeau', () async {
      final (w, d) = _repsDay(app);
      final groups = app.groups(d);
      final key = app.sessionKey(w.n, d.j);
      for (final ex in groups.first) {
        final log = app.exLog(w.n, d.j, ex);
        for (var i = 0; i < log.sets.length; i++) {
          log.sets[i].reps = '5';
          now = now.add(const Duration(minutes: 2));
          expect(app.toggleSet(log, i, app.logSpec(ex)).ok, isTrue);
        }
      }
      if (groups.length > 1) {
        final ex = groups[1].first;
        final log = app.exLog(w.n, d.j, ex);
        log.sets[0].reps = '5';
        now = now.add(const Duration(minutes: 2));
        app.toggleSet(log, 0, app.logSpec(ex));
      }
      await app.flush();
      final next = await relaunch();
      expect(next.inProgress(key), isTrue);
      expect(next.resumePage(w.n, d.j, next.groups(d)), 1);
      final resume = next.sessionsInProgress.single;
      expect(resume.key, key);
      expect(resume.done, greaterThan(0));
      expect(resume.day.j, d.j);
      // Une séance seulement ouverte (brouillon pré-rempli) n'est pas en cours.
      final (w2, d2) = (
        next.program.week(w.n + 1),
        next.program
            .week(w.n + 1)
            .days
            .firstWhere((x) => x.exercises.isNotEmpty),
      );
      next.exLog(w2.n, d2.j, d2.exercises.first).sets.first.reps = '8';
      expect(next.inProgress(next.sessionKey(w2.n, d2.j)), isFalse);
      expect(next.sessionsInProgress, hasLength(1));
    });

    test('fin : un seul bilan, double appel sans double gain', () async {
      final (w, d) = _repsDay(app);
      final ex = d.exercises.first;
      final log = app.exLog(w.n, d.j, ex);
      log.sets[0].reps = '8';
      app.toggleSet(log, 0, app.logSpec(ex));
      final credits = app.credits;
      final results = await Future.wait([
        app.finishSession(w.n, d.j, title: 'S${w.n} · J${d.j}'),
        app.finishSession(w.n, d.j, title: 'S${w.n} · J${d.j}'),
      ]);
      expect(results, [ResultSave.saved, ResultSave.saved]);
      expect(app.consumeReward(), isNotNull);
      expect(app.consumeReward(), isNull);
      final xp = app.xp;
      final finished = app.logs[app.sessionKey(w.n, d.j)]!.finishedAt;
      expect(finished, now.toIso8601String());
      expect(await app.finishSession(w.n, d.j), ResultSave.saved);
      expect(app.consumeReward(), isNull);
      expect(app.credits, greaterThanOrEqualTo(credits));
      final grants = Map.of(app.creditGrants);
      await app.finishSession(w.n, d.j);
      expect(app.creditGrants, grants);
      expect(app.xp, xp);
      expect(app.logs[app.sessionKey(w.n, d.j)]!.finishedAt, finished);
    });

    test(
      'écriture refusée : pas de bilan, séries gardées ; nouvel essai',
      () async {
        final (w, d) = _repsDay(app);
        final ex = d.exercises.first;
        final log = app.exLog(w.n, d.j, ex);
        log.sets[0].reps = '8';
        app.toggleSet(log, 0, app.logSpec(ex));
        await app.flush();
        final stored = (await SharedPreferences.getInstance()).getString(_key);
        app.debugWriteHook = (_) async => false;
        expect(await app.finishSession(w.n, d.j), ResultSave.unsaved);
        expect(app.consumeReward(), isNull);
        expect(log.sets[0].done, isTrue);
        expect((await SharedPreferences.getInstance()).getString(_key), stored);
        // Fermeture à ce moment : le dernier état confirmé = séance en cours.
        final crashed = await relaunch();
        expect(crashed.isDone(w.n, d.j), isFalse);
        expect(crashed.inProgress(crashed.sessionKey(w.n, d.j)), isTrue);
        app.debugWriteHook = null;
        expect(await app.finishSession(w.n, d.j), ResultSave.saved);
        final reward = app.consumeReward();
        expect(reward, isNotNull);
        expect(app.consumeReward(), isNull);
        // Fermeture après l'écriture, avant l'affichage du bilan : séance
        // terminée, gains au registre ; aucun gain supplémentaire au relancement.
        final after = await relaunch();
        expect(after.isDone(w.n, d.j), isTrue);
        expect(after.xp, app.xp);
        expect(after.credits, app.credits);
        expect(after.consumeReward(), isNull);
        expect(await after.finishSession(w.n, d.j), ResultSave.saved);
        expect(after.consumeReward(), isNull);
        expect(after.xp, app.xp);
      },
    );

    test(
      'reprise après minuit : dates de séries gardées, fin datée à la fin',
      () async {
        final (w, d) = _repsDay(app);
        final ex = d.exercises.first;
        final log = app.exLog(w.n, d.j, ex);
        now = DateTime(2026, 9, 26, 23, 50);
        log.sets[0].reps = '8';
        app.toggleSet(log, 0, app.logSpec(ex));
        await app.flush();
        now = DateTime(2026, 9, 27, 0, 10);
        final next = await relaunch();
        final key = next.sessionKey(w.n, d.j);
        expect(
          next.logs[key]!.ex[ex.id]!.sets[0].completedAt,
          '2026-09-26T23:50:00.000',
        );
        await next.finishSession(w.n, d.j);
        expect(next.logs[key]!.finishedAt, '2026-09-27T00:10:00.000');
        expect(
          next.logs[key]!.ex[ex.id]!.sets[0].completedAt,
          '2026-09-26T23:50:00.000',
        );
        expect(next.program.start, DateTime(2026, 7, 13)); // calendrier L4
      },
    );

    test(
      'séance perso répétée : ancienne occurrence archivée, jamais écrasée',
      () async {
        final session = CustomSession(
          id: app.newSessionId(),
          name: 'Perso test',
          items: [CustomExercise(uid: 'a1', name: 'Tractions')],
        );
        app.upsertSession(session);
        final plan = session.toWeekPlan();
        final day = plan.days.first;
        final ex = day.exercises.first;
        final log = app.exLog(0, day.j, ex);
        log.sets[0].reps = '10';
        app.toggleSet(log, 0, app.logSpec(ex));
        expect(await app.finishSession(0, day.j), ResultSave.saved);
        app.consumeReward();
        final first = jsonEncode(app.logs['S0-J${session.id}']!.toJson());
        app.restartCustomSession(session);
        session.items.first.name = 'Tractions modifiées';
        app.upsertSession(session);
        final archives = app.logs.keys.where(
          (k) => k.startsWith('S0-J${session.id}@'),
        );
        expect(archives, hasLength(1));
        expect(jsonEncode(app.logs[archives.single]!.toJson()), first);
        expect(app.logs.containsKey('S0-J${session.id}'), isFalse);
        final again = app.exLog(0, day.j, ex);
        expect(again.sets.every((s) => !s.done), isTrue);
      },
    );
  });

  // ===================================================================
  group('C. Temps : horloge murale bornée par l’horloge monotone', () {
    setUp(() {
      store.settings.sound = store.settings.vibration = false;
      store.settings.prepSec = 0;
    });

    test('heure reculée d’une heure : le repos continue de décompter', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 9, 26, 12);
        var mono = 0;
        final c = TimerCtl(now: () => wall, mono: () => mono);
        c.startRest(90);
        wall = wall.subtract(const Duration(hours: 1));
        mono += 10 * 1000000;
        async.elapse(const Duration(seconds: 1));
        expect(c.remaining, 80);
        c.dispose();
      });
    });

    test('veille de l’appareil : l’heure murale compte le temps passé', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 9, 26, 12);
        var mono = 0;
        final c = WodClock(now: () => wall, mono: () => mono);
        c.startStopwatch();
        wall = wall.add(const Duration(minutes: 5)); // monotone arrêtée
        mono += 1000000;
        async.elapse(const Duration(milliseconds: 200));
        expect(c.elapsed, 300);
        c.dispose();
      });
    });

    test('rafraîchissements manqués : bonne phase, aucune rafale', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 9, 26, 12);
        final c = TimerCtl(now: () => wall);
        c.startInterval(4, 20, 10); // 20/10 × 4
        wall = wall.add(const Duration(seconds: 95));
        async.elapse(const Duration(seconds: 1));
        expect(c.label, 'REPOS 3/4');
        expect(c.remaining, 5);
        expect(c.alerts, 0); // transitions anciennes : pas de bip
        wall = wall.add(const Duration(seconds: 5));
        async.elapse(const Duration(seconds: 1));
        expect(c.label, 'EFFORT 4/4');
        expect(c.alerts, 1);
        c.dispose();
      });
    });

    test('pauses répétées et frontière de phase exacte', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 9, 26, 12);
        final c = WodClock(now: () => wall);
        c.startPhases(const [
          WodPhase(PhaseKind.work, 20),
          WodPhase(PhaseKind.rest, 10),
          WodPhase(PhaseKind.work, 20),
        ]);
        for (var i = 0; i < 4; i++) {
          wall = wall.add(const Duration(seconds: 4));
          async.elapse(const Duration(milliseconds: 200));
          c.toggle(); // pause
          wall = wall.add(const Duration(minutes: 3));
          async.elapse(const Duration(milliseconds: 200));
          c.toggle(); // reprise
        }
        expect(c.phaseIndex, 0);
        wall = wall.add(const Duration(milliseconds: 3999));
        async.elapse(const Duration(milliseconds: 200));
        expect(c.phaseIndex, 0);
        wall = wall.add(const Duration(milliseconds: 1));
        async.elapse(const Duration(milliseconds: 200));
        expect(c.phaseIndex, 1);
        expect(c.beeps, 1);
        c.dispose();
      });
    });

    test(
      'point sûr : reprise en pause, absence non comptée, aucune alerte',
      () {
        fakeAsync((async) {
          var wall = DateTime(2026, 9, 26, 12);
          final c = WodClock(now: () => wall);
          const phases = [
            WodPhase(PhaseKind.work, 20),
            WodPhase(PhaseKind.rest, 10),
            WodPhase(PhaseKind.work, 20),
          ];
          c.startPhases(phases);
          wall = wall.add(const Duration(seconds: 25));
          async.elapse(const Duration(milliseconds: 200));
          final point = c.checkpoint();
          expect(point['ms'], 25000);
          expect(point.keys, isNot(contains('startedAt')));
          c.dispose();
          // Nouveau processus, 2 h plus tard, horloge monotone repartie de 0 :
          // aucun repère ancien n'est réutilisé.
          wall = wall.add(const Duration(hours: 2));
          final d = WodClock(now: () => wall, mono: () => 0);
          d.startPhases(phases);
          d.resumePaused(ms: point['ms'] as int);
          expect(d.running, isFalse);
          expect(d.started, isTrue);
          expect(d.phaseIndex, 1);
          expect(d.phaseRemaining, 5);
          expect(d.beeps + d.alarms, 0);
          wall = wall.add(const Duration(seconds: 3));
          async.elapse(const Duration(seconds: 1));
          expect(d.phaseRemaining, 5); // en pause
          d.toggle();
          wall = wall.add(const Duration(seconds: 5));
          async.elapse(const Duration(milliseconds: 200));
          expect(d.phaseIndex, 2);
          expect(d.beeps, 1);
          d.dispose();
        });
      },
    );

    test('chrono de tenue terminé : la série n’est pas validée', () {
      fakeAsync((async) {
        var wall = DateTime(2026, 9, 26, 12);
        final entry = SetEntry(reps: '30');
        final c = TimerCtl(now: () => wall);
        c.single('TENUE', 30, prepare: false);
        wall = wall.add(const Duration(seconds: 31));
        async.elapse(const Duration(seconds: 1));
        expect(c.label, 'TERMINÉ');
        expect(entry.done, isFalse);
        c.dispose();
      });
    });
  });

  // ===================================================================
  group('F/G. WOD en cours : persistance, import, minuit', () {
    late AppStore app;
    var now = DateTime(2026, 9, 26, 23, 50);
    final others = <AppStore>[];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      now = DateTime(2026, 9, 26, 23, 50);
      app = AppStore()..storeClock = () => now;
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
      final next = AppStore()..storeClock = () => now;
      await next.init();
      others.add(next);
      return next;
    }

    test(
      'essai lancé avant minuit, processus détruit, fini après minuit',
      () async {
        final trial = app.trialWod!;
        final attempt = app.startAttempt(trial)!;
        app.checkpointWod(attempt, {
          'ms': 400000,
          'laps': <int>[120, 250],
          'round': 2,
          'capHit': false,
          'finished': false,
        }, app.dataEpoch);
        await app.flush();
        now = DateTime(2026, 9, 27, 0, 20);
        final next = await relaunch();
        final w = next.wods.firstWhere((x) => x.id == trial.id);
        expect(next.activeWod?.attempt, attempt);
        expect(next.activeWod?.ms, 400000);
        expect(next.activeWod?.laps, [120, 250]);
        expect(next.canFinish(w, attempt), isTrue); // droit de finir gardé
        final before = w.results.length;
        final r = WodResult(
          at: now.toIso8601String(),
          score: '6:40',
          seconds: 400,
        );
        expect(
          await next.recordWodResult(w, r, attempt: attempt),
          ResultSave.saved,
        );
        expect(next.activeWod, isNull);
        expect(
          await next.recordWodResult(
            w,
            WodResult(at: now.toIso8601String(), score: '6:40', seconds: 400),
            attempt: attempt,
          ),
          ResultSave.saved,
        );
        expect(w.results.length, before + 1); // une tentative, un résultat
        expect(next.unlocked(w), isFalse); // aucune acquisition
        final again = await relaunch();
        expect(again.activeWod, isNull);
      },
    );

    test('un seul WOD chronométré à la fois ; abandon explicite', () async {
      final a = app.wods.firstWhere(app.isCatalog);
      final b = app.wods.where(app.isCatalog).skip(1).first;
      app.unlockedWods[a.id] = 0;
      app.unlockedWods[b.id] = 0;
      final first = app.startAttempt(a)!;
      expect(app.startAttempt(b), isNull);
      expect(app.activeWod?.attempt, first);
      final second = app.startAttempt(b, replace: true)!;
      expect(app.activeWod?.attempt, second);
      expect(app.canFinish(a, first), isTrue); // débloqué : toujours jouable
      app.abandonAttempt(second);
      expect(app.activeWod, isNull);
    });

    test(
      'export sans chrono ; import et effacement l’annulent ; point obsolète ignoré',
      () async {
        final w = app.wods.firstWhere(app.isCatalog);
        app.unlockedWods[w.id] = 0;
        final attempt = app.startAttempt(w)!;
        final epoch = app.dataEpoch;
        await app.flush();
        final state =
            jsonDecode(
                  utf8.decode(
                    gzip.decode(
                      base64Decode(
                        (await SharedPreferences.getInstance())
                            .getString(_key)!
                            .substring(3),
                      ),
                    ),
                  ),
                )
                as Map<String, dynamic>;
        expect(state['activeWod']?['attempt'], attempt);
        final exported = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        expect(exported.containsKey('activeWod'), isFalse);
        // Un fichier contenant quand même un chrono : ignoré à l'import.
        exported['activeWod'] = state['activeWod'];
        expect(
          await app.importBackup(jsonEncode(exported)),
          ImportStatus.success,
        );
        expect(app.activeWod, isNull);
        expect(app.canFinish(w, attempt), isTrue); // débloqué dans le fichier
        app.checkpointWod(attempt, {
          'ms': 5000,
          'laps': <int>[],
          'round': 0,
          'capHit': false,
          'finished': false,
        }, epoch);
        expect(app.activeWod, isNull); // écran de l'ancien état : ignoré
        final other = app.startAttempt(w)!;
        expect(app.activeWod?.attempt, other);
        expect((await app.eraseAllData()).status, EraseStatus.success);
        expect(app.activeWod, isNull);
        final next = await relaunch();
        expect(next.activeWod, isNull);
      },
    );

    test('chrono illisible : ignoré, le reste des données chargé', () async {
      final (w, d) = _repsDay(app);
      final ex = d.exercises.first;
      final log = app.exLog(w.n, d.j, ex);
      log.sets[0].reps = '8';
      app.toggleSet(log, 0, app.logSpec(ex));
      await app.flush();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key)!;
      final m =
          jsonDecode(utf8.decode(gzip.decode(base64Decode(raw.substring(3)))))
              as Map<String, dynamic>;
      m['activeWod'] = {'v': 1, 'attempt': 'x', 'wod': 'inconnu', 'ms': -5};
      await prefs.setString(_key, jsonEncode(m));
      final next = await relaunch();
      expect(next.activeWod, isNull);
      expect(next.activeWodUnreadable, isTrue);
      expect(
        next.logs[next.sessionKey(w.n, d.j)]!.ex[ex.id]!.sets[0].done,
        isTrue,
      );
    });

    test(
      'ancienne sauvegarde sans chrono : importée, rien de synthétisé',
      () async {
        final (w, d) = _repsDay(app);
        final old = jsonDecode(app.exportAll()) as Map<String, dynamic>;
        old['logs'] = {
          app.sessionKey(w.n, d.j):
              SessionLog(
                done: true,
                finishedAt: '2026-08-01T18:00:00.000',
              ).toJson(),
        };
        expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
        expect(app.activeWod, isNull);
        expect(app.sessionsInProgress, isEmpty);
      },
    );
  });

  // ===================================================================
  group('Écrans', () {
    var now = DateTime(2026, 9, 26, 18);
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await store.init();
      store.settings
        ..sound = false
        ..vibration = false
        ..autoTimer = false
        ..wakelock = false
        ..prefill = true
        ..prepSec = 0
        ..celebrations = false;
      store.program.start = DateTime(2026, 7, 13);
      store.startOrigin = 'migration';
    });
    setUp(() {
      now = DateTime(2026, 9, 26, 18);
      store.storeClock = () => now;
      store.debugWriteHook = null;
      store.logs.clear();
      store.consumeReward();
      openDayRoutes.clear();
    });
    tearDown(() => store.storeClock = DateTime.now);

    Widget page(Widget child, {double scale = 1, bool dark = true}) =>
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
          home: child,
        );

    void phone(WidgetTester tester, Size size, {double keyboard = 0}) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
    }

    Finder cell(String exId, int set, {int column = 0}) => find
        .descendant(
          of: find.byKey(ValueKey('$exId-$set-0')),
          matching: find.byType(TextField),
        )
        .at(column);

    testWidgets('coche refusée : message nommant le champ, saisie gardée', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      final (w, d) = _repsDay(store);
      final ex = d.exercises.first;
      await tester.pumpWidget(page(SessionScreen(week: w, day: d)));
      await tester.pumpAndSettle();
      final showKg = store.showKgFor(ex, store.exLog(w.n, d.j, ex));
      final reps = cell(ex.id, 0, column: showKg ? 1 : 0);
      await tester.enterText(reps, '8 reps');
      await tester.pump();
      await tester.tap(find.byTooltip('Valider la série 1').first);
      await tester.pump();
      expect(find.textContaining('Reps : nombre entier'), findsOneWidget);
      expect(store.exLog(w.n, d.j, ex).sets[0].done, isFalse);
      expect(tester.widget<TextField>(reps).controller!.text, '8 reps');
      // Correction : le message disparaît à la frappe, la coche passe.
      await tester.enterText(reps, '8');
      await tester.pump();
      expect(find.textContaining('Reps : nombre entier'), findsNothing);
      await tester.tap(find.byTooltip('Valider la série 1').first);
      await tester.pump();
      expect(store.exLog(w.n, d.j, ex).sets[0].done, isTrue);
      // Modifiée après la coche avec une valeur invalide : non validée.
      await tester.enterText(reps, '8,5');
      await tester.pump();
      expect(store.exLog(w.n, d.j, ex).sets[0].done, isFalse);
      expect(find.textContaining('Série repassée non validée'), findsOneWidget);
      expect(tester.widget<TextField>(reps).controller!.text, '8,5');
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => store.flush());
    });

    testWidgets(
      'reprise : rouverte sur l’exercice en cours, badge et bandeau',
      (tester) async {
        phone(tester, const Size(390, 844));
        final (w, d) = _repsDay(store);
        final groups = store.groups(d);
        if (groups.length < 2) return;
        for (final ex in groups.first) {
          final log = store.exLog(w.n, d.j, ex);
          for (var i = 0; i < log.sets.length; i++) {
            log.sets[i].reps = '5';
            now = now.add(const Duration(minutes: 1));
            store.toggleSet(log, i, store.logSpec(ex));
          }
        }
        final key = store.sessionKey(w.n, d.j);
        expect(store.inProgress(key), isTrue);
        await tester.pumpWidget(page(SessionScreen(week: w, day: d)));
        await tester.pumpAndSettle();
        expect(find.textContaining('2 / ${groups.length}'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(page(const Scaffold(body: ResumeBanner())));
        await tester.pump();
        expect(find.byKey(ValueKey('resume-$key')), findsOneWidget);
        expect(
          find.textContaining(RegExp(r'\d+/\d+ séries validées')),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => store.flush());
      },
    );

    testWidgets('fin : écriture refusée → réessayer ; bilan une seule fois', (
      tester,
    ) async {
      phone(tester, const Size(390, 844));
      final (w, d) = _repsDay(store);
      final ex = d.exercises.first;
      final log = store.exLog(w.n, d.j, ex);
      log.sets[0].reps = '8';
      store.toggleSet(log, 0, store.logSpec(ex));
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => SessionScreen(week: w, day: d)),
      );
      await tester.pumpAndSettle();
      final groups = store.groups(d);
      final pageCtl =
          tester.widget<PageView>(find.byType(PageView)).controller!;
      pageCtl.jumpToPage(groups.length);
      await tester.pumpAndSettle();
      store.debugWriteHook = (_) async => false;
      await tester.tap(find.byKey(const ValueKey('finish-session')));
      await tester.tap(
        find.byKey(const ValueKey('finish-session')),
        warnIfMissed: false,
      );
      await tester.runAsync(() => store.flush());
      await tester.pumpAndSettle();
      expect(find.byType(SessionScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('finish-retry')), findsOneWidget);
      expect(find.textContaining('pas encore enregistrée'), findsOneWidget);
      store.debugWriteHook = null;
      await tester.tap(find.byKey(const ValueKey('finish-retry')));
      await tester.runAsync(() => store.flush());
      await tester.pumpAndSettle();
      expect(find.byType(SessionScreen), findsNothing);
      expect(store.isDone(w.n, d.j), isTrue);
      expect(
        store.consumeReward(),
        isNull,
      ); // déjà présenté (réglage : bandeau)
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'notification répétée : une seule séance ouverte ; journée faite → historique',
      (tester) async {
        phone(tester, const Size(390, 844));
        final (w, d) = _repsDay(store);
        final nav = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: nav,
            theme: buildTheme(true),
            locale: const Locale('fr'),
            supportedLocales: const [Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const Scaffold(body: SizedBox()),
          ),
        );
        final before = store.exportAll();
        openProgramDay(nav.currentState!, w, d);
        openProgramDay(nav.currentState!, w, d); // même frame
        await tester.pumpAndSettle();
        openProgramDay(nav.currentState!, w, d); // à chaud, déjà ouverte
        await tester.pumpAndSettle();
        expect(find.byType(SessionScreen), findsOneWidget);
        // Une autre journée : la première est refermée (brouillon gardé).
        final other = w.days.lastWhere(
          (x) => x.exercises.isNotEmpty && x.j != d.j,
        );
        openProgramDay(nav.currentState!, w, other);
        await tester.pumpAndSettle();
        expect(find.byType(SessionScreen), findsOneWidget);
        nav.currentState!.pop();
        await tester.pumpAndSettle();
        // Journée faite : historique, sans nouvelle occurrence ni écriture.
        store.logs[store.sessionKey(w.n, d.j)] = SessionLog(
          done: true,
          finishedAt: '2026-09-20T18:00:00.000',
        );
        final done = store.exportAll();
        openProgramDay(nav.currentState!, w, d);
        await tester.pumpAndSettle();
        expect(find.byType(SessionHistoryScreen), findsOneWidget);
        openProgramDay(nav.currentState!, w, d);
        await tester.pumpAndSettle();
        expect(find.byType(SessionHistoryScreen), findsOneWidget);
        expect(store.exportAll(), done);
        expect(before, isNotEmpty);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => store.flush());
      },
    );

    testWidgets(
      'historique : consulter, défiler, changer de thème ne modifie rien',
      (tester) async {
        phone(tester, const Size(320, 720));
        final (w, d) = _repsDay(store);
        final ex = d.exercises.first;
        final log = store.exLog(w.n, d.j, ex);
        log.sets[0]
          ..reps = '8'
          ..kg = '20';
        store.toggleSet(log, 0, store.logSpec(ex));
        log.note = 'note témoin';
        await tester.runAsync(() => store.finishSession(w.n, d.j));
        store.consumeReward();
        await tester.runAsync(() => store.flush());
        final before = store.exportAll();
        final saved = (await tester.runAsync(
          () async => (await SharedPreferences.getInstance()).getString(_key),
        ));
        final entry = store.logs[store.sessionKey(w.n, d.j)]!;
        for (final dark in [true, false]) {
          await tester.pumpWidget(
            page(
              SessionHistoryScreen(log: entry, week: w, day: d),
              dark: dark,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          await tester.drag(find.byType(PageView), const Offset(-300, 0));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(store.exportAll(), before);
        final after = await tester.runAsync(
          () async => (await SharedPreferences.getInstance()).getString(_key),
        );
        expect(after, saved);
      },
    );

    testWidgets('WOD retrouvé en pause au dernier point sûr (Tabata)', (
      tester,
    ) async {
      phone(tester, const Size(320, 640));
      final w = store.wods.firstWhere((x) => x.id == 'genx100');
      store.unlockedWods[w.id] = 0;
      w.results.clear();
      // Point sûr d'une tentative interrompue : 25 s (repos, intervalle 1).
      final attempt = store.startAttempt(w)!;
      store.checkpointWod(attempt, {
        'ms': 25000,
        'laps': <int>[],
        'round': 0,
        'capHit': false,
        'finished': false,
      }, store.dataEpoch);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => WodRunScreen(wodId: w.id)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('wod-restored')), findsOneWidget);
      expect(
        find.textContaining('Chrono retrouvé en pause à 0:25'),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('wod-phase'))).data,
        'REPOS',
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('wod-clock'))).data,
        '0:05',
      );
      expect(find.text('Reprendre'), findsOneWidget);
      now = now.add(const Duration(minutes: 30));
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('wod-clock'))).data,
        '0:05',
      );
      await tester.tap(find.text('Reprendre'));
      now = now.add(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('wod-phase'))).data,
        'EFFORT',
      );
      expect(find.byKey(const ValueKey('wod-restored')), findsNothing);
      expect(store.activeWod?.attempt, attempt);
      expect(store.activeWod!.ms, greaterThanOrEqualTo(25000));
      // Sortie confirmée : abandon explicite, plus de reprise.
      await nav.currentState!.maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      expect(find.byType(WodRunScreen), findsNothing);
      expect(store.activeWod, isNull);
      await tester.pumpWidget(const SizedBox());
      expect(w.results, isEmpty);
    });

    for (final (size, scale, dark) in [
      (const Size(320, 720), 1.3, false),
      (const Size(320, 720), 2.0, true),
    ]) {
      testWidgets(
        'rendu ${size.width.toInt()} px · ${(scale * 100).round()} % : message d’erreur, bandeau, clavier',
        (tester) async {
          phone(tester, size, keyboard: 280);
          final (w, d) = _repsDay(store);
          final ex = d.exercises.first;
          final log = store.exLog(w.n, d.j, ex);
          log.sets[0].reps = '';
          store.settings.prefill = false;
          await tester.pumpWidget(
            page(SessionScreen(week: w, day: d), scale: scale, dark: dark),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byTooltip('Valider la série 1').first,
          );
          await tester.tap(find.byTooltip('Valider la série 1').first);
          await tester.pump();
          expect(find.textContaining('pour valider la série'), findsOneWidget);
          expect(tester.takeException(), isNull);
          store.settings.prefill = true;
          log.sets[0].reps = '5';
          store.toggleSet(log, 0, store.logSpec(ex));
          await tester.pumpWidget(
            page(
              const Scaffold(
                body: SingleChildScrollView(child: ResumeBanner()),
              ),
              scale: scale,
              dark: dark,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() => store.flush());
        },
      );
    }
  });
}
