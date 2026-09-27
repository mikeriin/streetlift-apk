// L13 — santé, sécurité et conformité côté règles et store (KT-072 à
// KT-078). Stockage simulé, horloge injectée, données synthétiques.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart' show wellnessWording;
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

const _at = '2026-09-27T10:00:00';

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

Map<String, bool> _allNo() => {for (final q in kHealthQuestions) q.id: false};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 27, 12);

  group('douleur (KT-073)', () {
    test('série de douleurs au-dessus de 3/10, les plus récentes', () {
      expect(painStreak(const []), 0);
      expect(painStreak(const [5, 5, 2]), 0);
      expect(painStreak(const [2, 4, 5]), 2);
      expect(painStreak(const [6, 2, 4, 5, 7]), 3);
      expect(painStreak(const [3, 3, 3]), 0, reason: '3/10 n’est pas > 3');
      expect(painNeedsReferral(const [4, 5]), isFalse);
      expect(painNeedsReferral(const [4, 5, 6]), isTrue);
      expect(painNeedsReferral(const [4, 5, 6, 1]), isFalse);
    });

    test(
      'signaux d’alerte : poitrine, malaise, essoufflement, irradiation',
      () {
        final all = kAlertSignals.join(' ');
        for (final w in ['poitrine', 'malaise', 'essoufflement', 'irradie']) {
          expect(all, contains(w));
        }
        expect(kAlertAdvice, contains('Arrête l’effort'));
        expect(kAlertAdvice, contains('médecin'));
        expect(kPainReferral, contains('professionnel de santé'));
      },
    );
  });

  group('situations particulières (KT-073)', () {
    UserProfile withAnswer(String id) =>
        _profile(answers: {..._allNo(), id: true});

    test('grossesse, tension ou cœur, 65 ans, gêne : mode prudent', () {
      final cases = <String, UserProfile>{
        'pregnancy': withAnswer('pregnancy'),
        'heart': withAnswer('heart'),
        'age65': _profile(birthYear: 1958),
        'discomfort':
            _profile()
              ..health.injuries.add(const Injury('knee', 5, '2026-09-01', _at)),
      };
      for (final s in kSpecialSituations) {
        final p = cases[s.cautionReason]!;
        final c = evaluateCaution(p, now);
        expect(c.active, isTrue, reason: s.id);
        expect(c.reasons, contains(s.cautionReason), reason: s.id);
        expect(s.text.toLowerCase(), contains('prudent'), reason: s.id);
      }
      expect(evaluateCaution(_profile(), now).active, isFalse);
    });

    test('avis médical conseillé, aucun programme spécifique promis', () {
      for (final s in kSpecialSituations.where((s) => s.id != 'injury')) {
        expect(s.text, contains('avis'), reason: s.id);
      }
      expect(
        kSpecialSituations.firstWhere((s) => s.id == 'pregnancy').text,
        contains('ne propose pas de programme'),
      );
    });
  });

  group('récupération (KT-072)', () {
    test('conseils généraux : aucun chiffre, aucun calcul, aucun objectif', () {
      expect(kRecoveryTips.map((t) => t.id), [
        'protein',
        'water',
        'sleep',
        'regularity',
        'food',
        'listen',
      ]);
      for (final t in kRecoveryTips) {
        expect(RegExp(r'\d').hasMatch(t.text), isFalse, reason: t.id);
        expect(t.text.toLowerCase(), isNot(contains('kcal')));
        expect(t.text.toLowerCase(), isNot(contains('régime')));
      }
      expect(
        kRecoveryTips.firstWhere((t) => t.id == 'food').text,
        contains('ne calcule ni calories'),
      );
      expect(
        kRecoveryTips.firstWhere((t) => t.id == 'listen').text,
        contains('facultatif'),
      );
    });

    test('réponses Koach facultatives : une séance sans réponse est vide', () {
      expect(SessionAnswers().isEmpty, isTrue);
      expect(SessionAnswers().toJson(), isEmpty);
    });
  });

  group('avertissement (KT-074)', () {
    test('finalité bien-être, pas de dispositif médical ni de promesse', () {
      expect(kWellnessDisclaimer, contains('n’est pas un dispositif médical'));
      expect(kWellnessDisclaimer, contains('aucun diagnostic'));
      expect(kWellnessDisclaimer, contains('aucun résultat'));
    });

    test('note du programme figé reformulée à l’affichage', () {
      expect(
        wellnessWording(
          'Ischios : assurance anti-blessure sur le squat lourd.',
        ),
        isNot(contains('blessure')),
      );
      expect(wellnessWording('Autre note.'), 'Autre note.');
    });
  });

  group('retour de test (KT-078)', () {
    test('seuls les champs remplis et les informations cochées', () {
      final d =
          FeedbackDraft()
            ..scenario = 'pain'
            ..includeVersion = false;
      var text = feedbackText(
        d,
        appVersion: '4.3.0',
        level: 'intermédiaire',
        caution: true,
      );
      expect(text, contains('Scénario : Douleur notée'));
      for (final absent in [
        'Version',
        'Niveau',
        'Mode prudent',
        'Note',
        'Ce qui marche',
        'Ce qui bloque',
        'Autre :',
      ]) {
        expect(text, isNot(contains(absent)), reason: absent);
      }
      d
        ..rating = 4
        ..blocked = '  Le chrono  '
        ..includeVersion = true
        ..includeLevel = true;
      text = feedbackText(
        d,
        appVersion: '4.3.0',
        level: 'intermédiaire',
        caution: true,
      );
      expect(text, contains('Note : 4/5'));
      expect(text, contains('Ce qui bloque : Le chrono'));
      expect(text, contains('Version : 4.3.0'));
      expect(text, contains('Niveau : intermédiaire'));
      expect(text, isNot(contains('Mode prudent')));
      expect(text, isNot(contains('Ce qui marche')));
    });

    test('texte borné à 2 000 caractères par champ', () {
      final d = FeedbackDraft()..other = 'a' * 5000;
      final text = feedbackText(d, appVersion: '4.3.0');
      expect(text.length, lessThan(2200));
    });

    test('scénarios par profil : débutant, intermédiaire, expert, senior', () {
      final profiles = {for (final s in kTestScenarios) s.$2};
      expect(
        profiles,
        containsAll(['débutant', 'intermédiaire', 'expert', 'senior']),
      );
    });
  });

  group('store', () {
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

    void done(String key, String finishedAt) {
      app.logs[key] = SessionLog(done: true, finishedAt: finishedAt);
    }

    test('douleur > 3/10 sur 3 séances de suite : renvoi (ordre réel)', () {
      done('S3-J1', '2026-09-01T18:00:00.000');
      done('S3-J3', '2026-09-03T18:00:00.000');
      done('S4-J1', '2026-09-08T18:00:00.000');
      done('S4-J3', '2026-09-10T18:00:00.000');
      // Saisies dans le désordre : l'ordre suit les dates de fin.
      app.setKoachPain('S4-J1', 'pull', 6);
      app.setKoachPain('S3-J1', 'pull', 2);
      app.setKoachPain('S3-J3', 'pull', 5);
      expect(app.painHistory('pull'), [2, 5, 6]);
      expect(app.painNeedsReferralFor('pull'), isFalse);
      app.setKoachPain('S4-J3', 'pull', 4);
      expect(app.painHistory('pull'), [2, 5, 6, 4]);
      expect(app.painNeedsReferralFor('pull'), isTrue);
      expect(app.painReferralMovements, ['pull']);
      // Une séance sans douleur interrompt la série.
      done('S5-J1', '2026-09-15T18:00:00.000');
      app.setKoachPain('S5-J1', 'pull', 1);
      expect(app.painNeedsReferralFor('pull'), isFalse);
      expect(app.painReferralMovements, isEmpty);
    });

    test('consentement refusé, puis accordé, puis retiré (KT-075)', () {
      app.saveProfile(_profile(consent: 'refused'));
      expect(app.profile!.health.consent, 'refused');
      expect(app.caution.active, isTrue);
      expect(app.caution.reasons, contains('no_consent'));
      var json = jsonEncode(backupOf(app)['profile']);
      expect(json.contains('"answers"'), isFalse);

      clock = clock.add(const Duration(minutes: 1));
      app.setHealthConsent(true);
      expect(app.profile!.health.consent, 'given');
      final p =
          app.profile!.copy()
            ..health.answers.addAll(_allNo())
            ..health.answeredAt = profileAt(clock)
            ..health.injuries.add(const Injury('knee', 2, '2026-09-01', _at));
      p.setField('sleep', '7to8', profileAt(clock));
      app.saveProfile(p);
      expect(app.caution.active, isFalse);
      json = jsonEncode(backupOf(app)['profile']);
      expect(json.contains('"answers"'), isTrue);
      expect(json.contains('knee'), isTrue);
      expect(json.contains('7to8'), isTrue);

      clock = clock.add(const Duration(minutes: 1));
      app.setHealthConsent(false);
      expect(app.profile!.health.consent, 'withdrawn');
      expect(app.profile!.health.hasHealthContent, isFalse);
      expect(app.caution.active, isTrue);
      json = jsonEncode(backupOf(app)['profile']);
      expect(json.contains('"answers"'), isFalse);
      expect(json.contains('knee'), isFalse);
      expect(json.contains('7to8'), isFalse);
    });

    test('export puis suppression complète des données de santé', () async {
      final p =
          _profile()
            ..health.injuries.add(
              const Injury('shoulder', 5, '2026-09-01', _at),
            )
            ..health.clearanceAt = _at;
      p.setField('stress', 'high', _at);
      app.saveProfile(p);
      done('S3-J1', '2026-09-01T18:00:00.000');
      app.setKoachPain('S3-J1', 'dip', 7);
      app.setKoachAnswers('S3-J1', sleep: 6.0);
      // Export : tout est présent (portabilité).
      final exported = backupOf(app);
      final profileJson = jsonEncode(exported['profile']);
      expect(profileJson, contains('shoulder'));
      expect(profileJson, contains('"clearance"'));
      expect(profileJson, contains('high'));
      expect(jsonEncode(exported['koach']), contains('"pain"'));
      // Suppression des réponses de santé (profil) et des réponses Koach.
      app.deleteHealthData();
      app.clearKoachAnswers();
      final after = backupOf(app);
      // Le journal « profil modifié » garde seulement les noms des champs
      // modifiés (« clearance ») : on contrôle la section santé et les
      // valeurs.
      final afterHealth = (after['profile'] as Map)['health'] as Map;
      expect(afterHealth.containsKey('clearance'), isFalse);
      expect(afterHealth.containsKey('answers'), isFalse);
      expect(afterHealth.containsKey('injuries'), isFalse);
      final afterFields = (after['profile'] as Map)['fields'] as Map;
      expect(afterFields.containsKey('stress'), isFalse);
      final afterProfile = jsonEncode(after['profile']);
      expect(afterProfile.contains('shoulder'), isFalse);
      expect(afterProfile.contains('high'), isFalse);
      expect(jsonEncode(after['koach'] ?? {}).contains('"pain"'), isFalse);
      // Suppression complète : plus rien.
      await app.eraseAllData();
      final erased = jsonEncode(backupOf(app));
      expect(erased.contains('shoulder'), isFalse);
      expect(erased.contains('"health"'), isFalse);
      expect(erased.contains('"pain"'), isFalse);
    });

    test(
      '18 ans et plus : un profil importé plus jeune bloque (KT-075)',
      () async {
        app.saveProfile(_profile(birthYear: 1990));
        expect(app.profileIsMinor, isFalse);
        final raw = backupOf(app);
        final fields = (raw['profile'] as Map)['fields'] as Map;
        (fields['birthYear'] as Map)['v'] = 2012;
        expect(await app.importBackup(jsonEncode(raw)), ImportStatus.success);
        expect(app.profileIsMinor, isTrue);
        // 18 ans dans l'année : accepté (la question a été posée).
        (fields['birthYear'] as Map)['v'] = 2008;
        expect(await app.importBackup(jsonEncode(raw)), ImportStatus.success);
        expect(app.profileIsMinor, isFalse);
        // Sans profil : pas de blocage.
        await app.eraseAllData();
        expect(app.profileIsMinor, isFalse);
      },
    );
  });
}
