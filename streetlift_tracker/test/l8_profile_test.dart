// L8 — profil, mode prudent, consentement, questions progressives et
// migration côté modèle et store (KT-038 à KT-043).
//
// Stockage simulé, horloge injectée, données synthétiques (aucune donnée
// réelle). « Relance » = nouvelle instance du store sur le même stockage.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _at = '2026-09-26T10:00:00';

UserProfile _profile({
  String? consent = 'given',
  Map<String, bool>? answers,
  int birthYear = 1990,
}) {
  final p = UserProfile(origin: 'onboarding', createdAt: _at);
  p.health
    ..consent = consent
    ..consentAt = consent == null ? null : _at;
  if (consent == 'given') {
    final a = answers ?? {for (final q in kHealthQuestions) q.id: false};
    p.health.answers.addAll(a);
    if (a.isNotEmpty) p.health.answeredAt = _at;
  }
  p.setField('birthYear', birthYear, _at);
  p.setField('goalPrimary', 'health', _at);
  p.setField('days', [1, 3, 5], _at);
  p.setField('sessionMinutes', 45, _at);
  p.setField('places', {
    'park': ['pullup_bar', 'dip_bars'],
  }, _at);
  p.setField('benchmarks', {'pushups': 2}, _at);
  p.setField('autonomy', 'assisted', _at);
  p.setField('tone', 'neutral', _at);
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 26, 12);

  group('modèle (KT-038)', () {
    test('aller-retour JSON identique, sources et dates conservées', () {
      final p = _profile()..addEvent(_at, ['days']);
      p.setField(
        'eventGoal',
        {
          'date': '2027-06-01',
          'items': [
            {'id': 'pull_1rm', 'target': 40.0},
          ],
        },
        _at,
        source: 'estimated',
      );
      final json = jsonEncode(p.toJson());
      final back = UserProfile.fromJson(jsonDecode(json), strict: true)!;
      expect(jsonEncode(back.toJson()), json);
      expect(back.fields['eventGoal']!.source, 'estimated');
      expect(back.fields['days']!.at, _at);
    });

    test('import strict : une valeur hors contrat refuse le profil', () {
      final raw = _profile().toJson();
      (raw['fields'] as Map)['sessionMinutes'] = {
        'v': 999,
        'at': _at,
        'src': 'declared',
      };
      expect(
        () => UserProfile.fromJson(raw, strict: true),
        throwsFormatException,
      );
      final issues = <String>[];
      final tolerant = UserProfile.fromJson(raw, issues: issues)!;
      expect(tolerant.fields.containsKey('sessionMinutes'), isFalse);
      expect(tolerant.fields.containsKey('days'), isTrue);
      expect(issues, hasLength(1));
    });

    test('champs de santé refusés sans consentement', () {
      final p = _profile(consent: 'refused');
      expect(p.setField('sleep', '6to7', _at), isFalse);
      expect(p.fields.containsKey('sleep'), isFalse);
      final raw = _profile().toJson();
      (raw['fields'] as Map)['sleep'] = {
        'v': '6to7',
        'at': _at,
        'src': 'declared',
      };
      (raw['health'] as Map).remove('answers');
      (raw['health'] as Map)['consent'] = {'status': 'refused', 'at': _at};
      expect(
        () => UserProfile.fromJson(raw, strict: true),
        throwsFormatException,
      );
    });

    test('valeurs par défaut du mode et du ton selon le repère', () {
      expect(defaultsForLevel('beginner'), (autonomy: 'guided', tone: 'kind'));
      expect(defaultsForLevel('novice'), (autonomy: 'guided', tone: 'kind'));
      expect(defaultsForLevel('intermediate'), (
        autonomy: 'assisted',
        tone: 'neutral',
      ));
      expect(defaultsForLevel('advanced'), (
        autonomy: 'assisted',
        tone: 'demanding',
      ));
      expect(defaultsForLevel('expert').autonomy, isNot('expert'));
      expect(levelFromBenchmarks({'pushups': 3, 'pullups': 1}), 'novice');
      expect(benchmarkBand('pushups', 65), 4);
      expect(benchmarkBand('pullups', 4), 1);
      expect(kGoals.first.id, 'health');
      expect(
        kGoals.where((g) => !g.active).map((g) => g.id),
        containsAll(['muscle', 'skills', 'energy']),
      );
    });
  });

  group('mode prudent (KT-041)', () {
    test('aucun déclencheur : pas de mode prudent', () {
      final c = evaluateCaution(_profile(), now);
      expect(c.active, isFalse);
      expect(c.reasons, isEmpty);
    });

    test('chaque déclencheur active le mode prudent', () {
      for (final q in kHealthQuestions) {
        final a = {for (final x in kHealthQuestions) x.id: x.id == q.id};
        final c = evaluateCaution(_profile(answers: a), now);
        expect(c.active, isTrue, reason: q.id);
        expect(c.reasons, contains('answer_yes'));
        if (q.id == 'heart') expect(c.reasons, contains('heart'));
        if (q.id == 'pregnancy') expect(c.reasons, contains('pregnancy'));
      }
      // 65 ans et plus (année civile).
      expect(
        evaluateCaution(_profile(birthYear: 1961), now).reasons,
        contains('age65'),
      );
      expect(evaluateCaution(_profile(birthYear: 1962), now).active, isFalse);
      // Gêne > 3/10 (3 ne déclenche pas).
      final p3 =
          _profile()
            ..health.injuries.add(const Injury('knee', 3, '2026-09-01', _at));
      expect(evaluateCaution(p3, now).active, isFalse);
      final p4 =
          _profile()
            ..health.injuries.add(const Injury('knee', 4, '2026-09-01', _at));
      expect(evaluateCaution(p4, now).reasons, ['discomfort']);
      // Questionnaire sans réponse, consentement refusé.
      expect(
        evaluateCaution(_profile(answers: {}), now).reasons,
        contains('unanswered'),
      );
      final refused = evaluateCaution(_profile(consent: 'refused'), now);
      expect(refused.active, isTrue);
      expect(refused.clearable, isFalse);
      expect(evaluateCaution(_profile(consent: null), now).active, isTrue);
    });

    test('accord du médecin daté : lève, puis une nouvelle gêne remet', () {
      final p = _profile(
        answers: {for (final q in kHealthQuestions) q.id: q.id == 'joint'},
      );
      expect(evaluateCaution(p, now).clearable, isTrue);
      p.health.clearanceAt = '2026-09-26T11:00:00';
      final c = evaluateCaution(p, now);
      expect(c.active, isFalse);
      expect(c.cleared, isTrue);
      p.health.injuries.add(
        const Injury('shoulder', 6, '2026-09-20', '2026-09-26T11:30:00'),
      );
      expect(evaluateCaution(p, now).active, isTrue);
    });

    test('plafond 80 % et repérage des tests maximaux', () {
      expect(cautionPct(.9, mainLift: true, active: true), .8);
      expect(cautionPct(.9, mainLift: false, active: true), .9);
      expect(cautionPct(.9, mainLift: true, active: false), .9);
      expect(cautionPct(.7, mainLift: true, active: true), .7);
      expect(isMaxTest('TEST 1RM DIP LESTÉ', 'Maximum'), isTrue);
      expect(isMaxTest('Dips', 'RIR 2'), isFalse);
    });
  });

  group('questions progressives (KT-040)', () {
    test('ordre, une par séance, plus tard, ne plus demander', () {
      final p = _profile();
      expect(nextProgressiveQuestion(p, 'S1-J1', now), 'experience');
      p.lastAskedSession = 'S1-J1';
      expect(nextProgressiveQuestion(p, 'S1-J1', now), isNull);
      p.never.add('experience');
      expect(nextProgressiveQuestion(p, 'S1-J2', now), 'disliked');
      p.later['disliked'] = profileAt(now);
      expect(nextProgressiveQuestion(p, 'S1-J2', now), 'liked');
      expect(
        nextProgressiveQuestion(p, 'S2-J1', now.add(const Duration(days: 8))),
        'disliked',
      );
      expect(nextProgressiveQuestion(null, 'S1-J1', now), isNull);
    });

    test('questions de santé seulement avec consentement', () {
      final p = _profile(consent: 'refused')
        ..never.addAll(['experience', 'disliked', 'liked']);
      expect(nextProgressiveQuestion(p, 'S1-J1', now), 'physicalJob');
      final q = _profile()..never.addAll(['experience', 'disliked', 'liked']);
      expect(nextProgressiveQuestion(q, 'S1-J1', now), 'sleep');
    });
  });

  group('store', () {
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

    void setRefs() {
      app.program.start = DateTime(2026, 7, 13);
      app.startOrigin = 'user';
      for (final e
          in {
            'B4': 72.0,
            'B8': 40.0,
            'B9': 50.0,
            'B10': 10.0,
            'B11': 120.0,
            'B17': 20.0,
            'B19': 40.0,
          }.entries) {
        app.values[e.key] = e.value;
        app.refStatus[e.key] = 'set';
      }
    }

    Map<String, String> loads() => {
      for (final w in app.program.weeks)
        for (final d in w.days)
          for (final e in d.exercises)
            '${w.n}-${d.j}-${e.id}': app.loadLabel(e),
    };

    test('installation neuve sans profil : export identique à 3.0.x', () {
      expect(app.isFreshInstall, isTrue);
      expect(app.profile, isNull);
      expect(backupOf(app).containsKey('profile'), isFalse);
      expect(app.caution.active, isFalse);
    });

    test('profil enregistré, relu après relance, événement daté', () async {
      app.saveProfile(_profile());
      expect(app.profile!.events, hasLength(1));
      expect(app.profile!.events.single.fields, contains('birthYear'));
      final next = await relaunch();
      expect(next.profile, isNotNull);
      expect(
        jsonEncode(next.profile!.toJson()),
        jsonEncode(app.profile!.toJson()),
      );
      // Modification : un seul événement, champs modifiés seulement.
      final p = app.profile!.copy();
      p.setField('sessionMinutes', 60, profileAt(clock));
      app.saveProfile(p);
      expect(app.profile!.events.last.fields, ['sessionMinutes']);
    });

    test('mode prudent : charges des mouvements principaux ≤ 80 %, '
        'identiques sans profil ou sans déclencheur', () {
      setRefs();
      final before = loads();
      app.saveProfile(_profile());
      expect(loads(), before, reason: 'profil sans déclencheur');
      app.saveProfile(_profile(consent: 'refused'));
      expect(app.caution.active, isTrue);
      final after = loads();
      var capped = 0;
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          for (final e in d.exercises) {
            final s = e.load;
            final key = '${w.n}-${d.j}-${e.id}';
            final main =
                (s.type == 'system' || s.type == 'barbell') &&
                {'B8', 'B9', 'B10', 'B11'}.contains(s.ref ?? 'B11');
            if (main && s.pct! > .8) {
              capped++;
              final expected =
                  s.type == 'barbell'
                      ? (app.values[s.ref ?? 'B11']! * .8 / 2.5).round() * 2.5
                      : (((72 + app.values[s.ref!]!) * .8 - 72) / 2.5).round() *
                          2.5;
              expect(
                app.loadFor(e),
                expected < 0 ? 0.0 : expected,
                reason: key,
              );
            } else {
              expect(after[key], before[key], reason: key);
            }
          }
        }
      }
      expect(capped, greaterThan(0));
      // Tests maximaux signalés, mouvements principaux avec RIR ≥ 3.
      final test1 = app.program.week(1).day(1)!.exercises.first;
      expect(app.cautionNote(test1), contains('pas de test maximal'));
      // Levée par l'accord du médecin : impossible sans consentement.
      app.declareDoctorClearance();
      expect(app.caution.active, isTrue);
    });

    test('levée par accord médical daté', () {
      setRefs();
      final before = loads();
      app.saveProfile(
        _profile(
          answers: {for (final q in kHealthQuestions) q.id: q.id == 'heart'},
        ),
      );
      expect(app.caution.active, isTrue);
      expect(loads(), isNot(before));
      clock = clock.add(const Duration(minutes: 5));
      app.declareDoctorClearance();
      expect(app.caution.active, isFalse);
      expect(app.caution.cleared, isTrue);
      expect(loads(), before);
      expect(app.profile!.events.last.fields, ['clearance']);
    });

    test('refus puis retrait du consentement : santé effacée, prudent', () {
      final p =
          _profile()
            ..health.injuries.add(const Injury('knee', 2, '2026-09-01', _at));
      p.setField('sleep', '7to8', _at);
      app.saveProfile(p);
      expect(app.profile!.health.hasHealthContent, isTrue);
      clock = clock.add(const Duration(minutes: 1));
      app.setHealthConsent(false);
      final h = app.profile!.health;
      expect(h.consent, 'withdrawn');
      expect(h.hasHealthContent, isFalse);
      expect(app.profile!.fields.containsKey('sleep'), isFalse);
      expect(app.caution.active, isTrue);
      final json = jsonEncode(backupOf(app)['profile']);
      expect(json.contains('7to8'), isFalse);
      expect(json.contains('knee'), isFalse);
    });

    test('export, import, sauvegarde 3.0.0 sans profil, effacement', () async {
      setRefs();
      app.saveProfile(_profile());
      final exported = app.exportAll();
      expect(backupOf(app)['profile'], isNotNull);
      final preview = app.previewImport(exported).preview!;
      expect(preview.profilePresent, isTrue);
      expect(preview.profileHealth, isTrue);
      // Sauvegarde 3.0.0 : même format, sans section profil.
      final old = backupOf(app)..remove('profile');
      expect(await app.importBackup(jsonEncode(old)), ImportStatus.success);
      expect(app.profile, isNull);
      expect(app.needsProfileConfirmation, isTrue);
      expect(app.program.start, DateTime(2026, 7, 13));
      // Réimport de l'export avec profil.
      expect(await app.importBackup(exported), ImportStatus.success);
      expect(app.profile, isNotNull);
      // Profil hors contrat : import refusé, rien modifié.
      final bad = jsonDecode(exported) as Map<String, dynamic>;
      (bad['profile'] as Map)['origin'] = 'pirate';
      expect(await app.importBackup(jsonEncode(bad)), ImportStatus.invalid);
      expect(app.profile, isNotNull);
      // Effacement : profil supprimé.
      await app.eraseAllData();
      expect(app.profile, isNull);
      expect(backupOf(app).containsKey('profile'), isFalse);
    });

    test('questions progressives : au plus une par séance, persistées', () {
      app.saveProfile(_profile());
      expect(app.progressiveQuestionFor('S3-J1'), 'experience');
      app.answerProgressive('experience', 'S3-J1', value: '2to5y');
      expect(app.progressiveQuestionFor('S3-J1'), isNull);
      expect(app.progressiveQuestionFor('S3-J2'), 'disliked');
      app.answerProgressive('disliked', 'S3-J2', never: true);
      app.answerProgressive('liked', 'S3-J3', later: true);
      expect(app.progressiveQuestionFor('S3-J4'), 'sleep');
      expect(app.profile!.stringValue('experience'), '2to5y');
      expect(app.profile!.never, {'disliked'});
    });

    test(
      'migration du propriétaire (KT-043) : pré-rempli, rien modifié',
      () async {
        // État réel type 3.0.0 : historique complet, références, départ
        // d'origine, objectifs Koach (étape 13/07/2027, final 31/12/2027).
        final state = filledBackup(app);
        state['programStart'] = {
          'status': 'set',
          'date': '2026-07-13',
          'origin': 'migration',
        };
        expect(await app.importBackup(jsonEncode(state)), ImportStatus.success);
        for (final e in {'B4': 72.0, 'B17': 30.0, 'B19': 65.0}.entries) {
          app.values[e.key] = e.value;
          app.refStatus[e.key] = 'set';
        }
        for (final ref in ['B8', 'B9', 'B10', 'B11']) {
          app.setKoachObjective(ref, 'final', 100, DateTime(2027, 12, 31));
        }
        await app.flush();
        final before = backupOf(app);
        expect(app.needsProfileConfirmation, isTrue);
        final draft = app.ownerDraft();
        expect(jsonEncode(backupOf(app)), jsonEncode(before));
        expect(draft.origin, 'migration');
        expect(draft.stringValue('goalPrimary'), 'event');
        final ev = draft.value('eventGoal') as Map;
        expect(ev['date'], '2027-12-31');
        expect((ev['items'] as List).length, 4);
        expect(draft.fields['eventGoal']!.source, 'estimated');
        expect(draft.benchmarks, isNotEmpty);
        expect(draft.intValue('birthYear'), isNull);
        // Confirmation : seul le profil s'ajoute.
        draft.setField('birthYear', 1990, profileAt(clock));
        draft.health
          ..consent = 'given'
          ..consentAt = profileAt(clock)
          ..answeredAt = profileAt(clock)
          ..answers.addAll({for (final q in kHealthQuestions) q.id: false});
        app.saveProfile(draft);
        final after = backupOf(app);
        expect(after.remove('profile'), isNotNull);
        expect(jsonEncode(after), jsonEncode(before));
        expect(app.caution.active, isFalse);
        final next = await relaunch();
        expect(next.profile!.origin, 'migration');
        expect(next.program.start, DateTime(2026, 7, 13));
      },
    );

    test(
      'étape par défaut sans objectif final : date 12 mois après le départ',
      () {
        setRefs();
        app.logs['S1-J1'] = SessionLog(
          done: true,
          finishedAt: '2026-07-13T18:00:00',
        );
        final d = app.ownerDraft();
        expect((d.value('eventGoal') as Map)['date'], '2027-07-13');
      },
    );
  });
}
