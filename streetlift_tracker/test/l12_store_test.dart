// L12 — motivation et progression branchées sur le store : niveau de
// détail par profil et nombre de chiffres, poids masqué et export,
// célébrations vues une seule fois sans gain appliqué (barème en attente),
// jour de repos respecté compté, messages de sécurité au ton neutre, bilans
// aux bornes de semaine et de cycle, rappels jamais un jour de repos, image
// de partage sans donnée de santé par défaut, séance de 10 minutes comptée,
// parcours d'habitude. Stockage simulé, horloge injectée.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/koach_adapt.dart' show dayIndex;
import 'package:streetlift_tracker/motivation.dart';
import 'package:streetlift_tracker/notifications.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _refs = <String, double?>{
  'B4': 71.5,
  'B8': 60,
  'B9': 80,
  'B10': 20,
  'B11': 140,
  'B17': 20,
  'B18': 30,
  'B19': 50,
  'B20': 30,
};

const _at = '2026-08-01T10:00:00';

UserProfile _profile(Map<String, int> bands, {String goal = 'health'}) {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.health
    ..consent = 'given'
    ..consentAt = _at
    ..answeredAt = _at;
  p.health.answers.addAll({for (final q in kHealthQuestions) q.id: false});
  p.setField('birthYear', 1990, _at);
  p.setField('goalPrimary', goal, _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', {
    'park': ['pullup_bar', 'dip_bars'],
  }, _at);
  p.setField('benchmarks', bands, _at);
  p.setField('autonomy', 'assisted', _at);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 8, 24, 10);
  final others = <AppStore>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 8, 24, 10);
    app = AppStore()..storeClock = () => clock;
    await app.init();
    // S1·J1 le lundi 10/08.
    await app.configureStart(DateTime(2026, 8, 10), references: _refs);
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

  /// Séance enregistrée directement dans le journal (clé, jour, exercice,
  /// répétitions par série).
  void log(String key, DateTime at, String name, List<int> reps) {
    final iso = at.toIso8601String();
    app.logs[key] = SessionLog(
      done: true,
      finishedAt: iso,
      title: key,
      exerciseNames: {'x1': name},
      ex: {
        'x1': ExerciseLog(
          sets: [
            for (final r in reps)
              SetEntry(reps: '$r', done: true, completedAt: iso),
          ],
        ),
      },
    );
    app.saveLogs(immediate: true);
  }

  int figures(Iterable<String> texts) =>
      texts.fold(0, (n, t) => n + figureCount(t));

  group('niveau de détail (KT-065)', () {
    test('sans profil : intermédiaire ; débutant, novice : victoires ; '
        'avancé : complet ; « Afficher toutes les statistiques »', () {
      expect(app.motivDetail, DetailLevel.simple);
      app.saveProfile(_profile({'pushups': 0, 'pullups': 0}));
      expect(app.motivLevel, 0);
      expect(app.motivDetail, DetailLevel.victories);
      app.saveProfile(_profile({'pushups': 1, 'pullups': 1}));
      expect(app.motivDetail, DetailLevel.victories);
      app.setShowAllStats(true);
      expect(app.motivDetail, DetailLevel.full);
      app.setShowAllStats(false);
      app.saveProfile(_profile({'pushups': 3, 'pullups': 3}));
      expect(app.motivDetail, DetailLevel.full);
    });

    test('débutant : victoires concrètes, au plus 3 chiffres par écran', () {
      app.saveProfile(_profile({'pushups': 0, 'pullups': 0}));
      log('S1-J1', DateTime(2026, 8, 10, 18), 'Pompes', [4, 3, 3]);
      log('S1-J3', DateTime(2026, 8, 12, 18), 'Pompes', [6, 5, 5]);
      log('S2-J1', DateTime(2026, 8, 17, 18), 'Pompes', [10, 8, 8]);
      log('S3-J1', DateTime(2026, 8, 24, 9), 'Traction pronation', [1]);
      final all = app.motivVictories();
      expect(
        all.map((v) => v.text),
        contains('+6 répétitions en pompes depuis ton départ'),
      );
      expect(all.map((v) => v.text), contains('Première traction !'));
      final top = app.motivTopVictories;
      expect(top, isNotEmpty);
      expect(top.length, lessThanOrEqualTo(3));
      expect(
        figures(top.map((v) => v.text)),
        lessThanOrEqualTo(kMaxVictoryFigures),
      );
      expect(top.first.text, 'Première traction !');
    });
  });

  group('poids facultatif et masquable', () {
    test('masqué : réglage persisté et exporté ; section absente sinon', () {
      expect(backupOf(app).containsKey('motiv'), isFalse);
      expect(app.motivBodyweight, 71.5);
      app.setHideBody(true);
      expect(backupOf(app)['motiv'], {'v': 1, 'hideBody': true});
      return relaunch().then((next) {
        expect(next.motiv.hideBody, isTrue);
        next.setHideBody(false);
        expect(backupOf(next).containsKey('motiv'), isFalse);
      });
    });
  });

  group('étapes réelles (KT-067)', () {
    test('record et étape de chaîne célébrés une seule fois ; aucun crédit '
        'ni XP créé tant que le barème n\'est pas validé', () async {
      await app.flush();
      final credits = app.creditsEarned;
      final grants = Map.of(app.creditGrants);
      log('S2-J1', DateTime(2026, 8, 20, 18), 'Pompes', [5, 5, 5]);
      log('S3-J1', DateTime(2026, 8, 24, 9), 'Pompes', [12, 12, 12]);
      final pending = app.motivPending;
      final ids = pending.map((m) => m.id).toList();
      expect(ids, contains('record:pompes:2026-08-24'));
      expect(ids, contains('chain:pompes'));
      final creditsBefore = app.creditsEarned;
      app.acknowledgeMilestones(pending);
      expect(app.motivPending, isEmpty);
      expect(app.creditsEarned, creditsBefore);
      final seen = Map.of(app.motiv.seen);
      app.acknowledgeMilestones(pending);
      expect(app.motiv.seen, seen);
      final next = await relaunch();
      expect(next.motivPending, isEmpty);
      expect(next.motiv.seen.keys, containsAll(ids));
      // Le registre des gains (KT-005) ne contient aucune étape L12.
      expect(
        next.creditGrants.keys.where((k) => !grants.containsKey(k)),
        everyElement(isNot(startsWith('milestone'))),
      );
      expect(credits, lessThanOrEqualTo(next.creditsEarned));
    });

    test('étape ancienne (plus de 7 jours) listée mais non célébrée', () {
      log('S1-J1', DateTime(2026, 8, 10, 18), 'Pompes', [5, 5, 5]);
      log('S1-J3', DateTime(2026, 8, 12, 18), 'Pompes', [12, 12, 12]);
      expect(app.motivMilestones.map((m) => m.id), contains('chain:pompes'));
      expect(app.motivPending, isEmpty);
    });
  });

  group('régularité (KT-067)', () {
    test(
      'jour de repos respecté compté, séance de 10 minutes comptée',
      () async {
        final monday = dayIndex(DateTime(2026, 8, 17));
        final w2 = app.program.week(2);
        final rest = [
          for (final d in w2.days)
            if (d.exercises.isEmpty) d.j,
        ];
        final before = app.motivWeek(monday);
        expect(before.restDays, 7 - before.planned);
        expect(before.restRespected, before.restDays);
        expect(before.done, 0);
        // Séance « 10 minutes, ça compte » un jour prévu.
        final catalog = await app.adaptCatalog();
        final s = app.ensureMinimalSession(catalog);
        expect(s.name, kMinimalSessionName);
        expect(s.items, isNotEmpty);
        expect(app.ensureMinimalSession(catalog).id, s.id);
        final planned = [
          for (final d in w2.days)
            if (d.exercises.isNotEmpty) d.j,
        ];
        final day = app.program.dateFor(2, planned.first);
        log(
          'S0-J${s.id}',
          DateTime(day.year, day.month, day.day, 19),
          s.items.first.name,
          [8, 8],
        );
        final after = app.motivWeek(monday);
        expect(after.done, 1);
        expect(after.plannedDone, 1);
        expect(after.restRespected, before.restRespected);
        if (rest.isNotEmpty) {
          final r = app.program.dateFor(2, rest.first);
          log('S0-J999', DateTime(r.year, r.month, r.day, 19), 'Pompes', [5]);
          final third = app.motivWeek(monday);
          expect(third.restRespected, before.restRespected - 1);
          expect(third.done, 2);
        }
      },
    );
  });

  test('messages de sécurité au ton neutre quel que soit le ton choisi '
      '(KT-068)', () {
    app.setKoachTone('demanding');
    expect(app.koachTone, 'demanding');
    expect(
      app.motivLine('session_done'),
      isNot(koachLine('session_done', 'neutral', 2)),
    );
    for (final c in kSafetyContexts) {
      expect(app.motivLine(c), koachLine(c, 'neutral', 0));
    }
    app.saveProfile(_profile({'pushups': 0, 'pullups': 0}));
    // Profil : ton du profil (réglable), sans profil : choix enregistré.
    app.setKoachTone('kind');
    expect(app.profile!.stringValue('tone'), 'kind');
    expect(app.koachTone, 'kind');
  });

  group('bilans (KT-069)', () {
    test('bilan hebdomadaire : bornes dimanche soir / lundi matin, lu une '
        'fois', () {
      log('S2-J1', DateTime(2026, 8, 17, 18), 'Pompes', [5, 5, 5]);
      log('S3-J1', DateTime(2026, 8, 24, 18), 'Pompes', [6, 6, 6]);
      clock = DateTime(2026, 8, 30, 23, 59);
      var r = app.motivWeekReview;
      expect(r, isNotNull);
      expect(r!.monday, dayIndex(DateTime(2026, 8, 17)));
      expect(r.items.length, lessThanOrEqualTo(3));
      clock = DateTime(2026, 8, 31, 0, 1);
      r = app.motivWeekReview;
      expect(r, isNotNull);
      expect(r!.monday, dayIndex(DateTime(2026, 8, 24)));
      expect(r.items.length, lessThanOrEqualTo(3));
      app.dismissWeekReview(r.monday);
      expect(app.motivWeekReview, isNull);
      clock = DateTime(2026, 9, 7, 9);
      // Semaine du 31/08 sans séance, mais utilisateur actif récemment.
      expect(app.motivWeekReview?.monday, dayIndex(DateTime(2026, 8, 31)));
    });

    test('bilan de fin de cycle : le lendemain du dernier jour du cycle', () {
      final cycles = app.motivCycles();
      expect(cycles, isNotEmpty);
      final cy = cycles.first;
      final last = app.program.dateFor(cy.lastWeek, 7);
      log('S1-J1', DateTime(2026, 8, 10, 18), 'Pompes', [5, 5, 5]);
      clock = DateTime(last.year, last.month, last.day, 20);
      expect(
        app.motivCycleReview == null ||
            app.motivCycleReview!.cycle.index != cy.index,
        isTrue,
      );
      final next = last.add(const Duration(days: 1));
      clock = DateTime(next.year, next.month, next.day, 8);
      final r = app.motivCycleReview;
      expect(r, isNotNull);
      expect(r!.cycle.index, cy.index);
      expect(r.lines.length, greaterThanOrEqualTo(4));
      expect(
        app.motivMilestones.map((m) => m.id),
        contains('cycle:${cy.index}:${cy.firstWeek}'),
      );
      app.dismissCycleReview(cy);
      expect(app.motivCycleReview, isNull);
    });
  });

  group('rappels (KT-070)', () {
    test(
      'jamais un jour de repos, même avec un ancien réglage contraire',
      () async {
        expect(
          AppSettings.fromJson({'notifSkipRest': false}).notifSkipRest,
          isTrue,
        );
        SharedPreferences.setMockInitialValues({
          'settings_v1': jsonEncode({
            ...AppSettings().toJson(),
            'notifOn': true,
            'notifSkipRest': false,
          }),
        });
        final other = AppStore()..storeClock = () => clock;
        await other.init();
        others.add(other);
        expect(other.settings.notifSkipRest, isTrue);
        other.settings.notifOn = true;
        await other.configureStart(DateTime(2026, 8, 10), references: _refs);
        final plan = planReminders(other, clock);
        expect(plan, isNotEmpty);
        for (final r in plan) {
          final m = RegExp(r'S(\d+)-J(\d+)').firstMatch(r.payload)!;
          final d = other.program.week(int.parse(m[1]!)).day(int.parse(m[2]!))!;
          expect(d.exercises, isNotEmpty, reason: r.payload);
        }
      },
    );
  });

  test('image de partage sans donnée de santé ni poids par défaut '
      '(KT-071)', () {
    app.saveProfile(_profile({'pushups': 0, 'pullups': 0}));
    log('S2-J1', DateTime(2026, 8, 20, 18), 'Pompes', [5, 5, 5]);
    log('S3-J1', DateTime(2026, 8, 24, 9), 'Pompes', [12, 12, 12]);
    final data = app.motivShareData;
    expect(data.bodyweight, isNotNull);
    final lines = shareLines(data, ShareOptions());
    expect(lines, isNotEmpty);
    expect(lines.any((l) => l.startsWith('Poids')), isFalse);
    final health = RegExp(
      r'santé|douleur|gêne|maladie|médecin|questionnaire|71,5',
      caseSensitive: false,
    );
    expect(lines.any(health.hasMatch), isFalse);
    expect(
      shareLines(data, ShareOptions(bodyweight: true)),
      contains('Poids de corps : 71,5 kg'),
    );
  });

  group('parcours d\'habitude (KT-071)', () {
    test('débutant, 4 premières semaines : séances ramenées vers 20 minutes, '
        '2 séances visées ; désactivable', () async {
      clock = DateTime(2026, 8, 12, 10);
      app.saveProfile(_profile({'pushups': 0, 'pullups': 0}));
      expect(app.motivHabitEligible, isTrue);
      expect(app.motivHabitActive, isTrue);
      expect(app.motivHabitWeek, 1);
      expect(app.motivHabitMinutes, 20);
      final w = app.program.week(1);
      final d = w.days.firstWhere((x) => x.exercises.isNotEmpty);
      int sets(DayPlan p) =>
          p.exercises.fold<int>(0, (n, e) => n + app.setCount(e));
      final habit = app.sessionDay(1, d);
      expect(sets(habit), lessThan(sets(d)));
      expect(app.motivThisWeek.target, lessThanOrEqualTo(2));
      app.setHabitOff(true);
      expect(app.motivHabitActive, isFalse);
      expect(sets(app.sessionDay(1, d)), sets(d));
      clock = DateTime(2026, 9, 8, 10);
      app.setHabitOff(false);
      expect(app.motivHabitActive, isFalse, reason: 'après 4 semaines');
    });
  });
}
