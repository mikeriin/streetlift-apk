// G6 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true … test/g6_mode_dev_test.dart`, sauté dans le
// build ordinaire) : la session de test démarre comme une installation
// neuve (création du profil) ; le profil v2, son brouillon et le report de
// la proposition restent dans la session de test, sans fuite vers la
// session personnelle, et disparaissent avec elle.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G6)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('profil créé dans la session de test : session personnelle '
        'intacte, rien ne passe de l’une à l’autre', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final perso = AppStore();
      await perso.init();
      // Session personnelle : ancien profil (L8), sans profil v2.
      perso.saveProfile(
        UserProfile(origin: 'onboarding', createdAt: '2026-09-26T10:00:00')
          ..setField('birthYear', 1990, '2026-09-26T10:00:00'),
      );
      await perso.flush();
      expect(perso.athleteRedoProposed, isTrue);
      final before = jsonEncode(KalisPrefs(raw, dev: false).snapshot());
      perso.dispose();

      SessionSpace.devActive = true;
      final dev = AppStore();
      await dev.init();
      expect(dev.isFreshInstall, isTrue);
      expect(dev.athleteRedoProposed, isFalse);
      final d = ProfileDraft.of(sampleAthleteProfile())..consent = 'refused';
      await dev.saveAthleteDraft(d, step: 'goals', mode: 'create');
      expect(dev.saveAthleteProfile(d), isNotNull);
      expect(dev.athleteProfile!.validate(), isEmpty);
      expect(dev.athleteProfile!.disciplines.primary, TrainingDiscipline.streetlifting);
      await dev.flush();
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
      expect(
        raw.getKeys().where((k) => k.startsWith(SessionSpace.devPrefix)),
        isNotEmpty,
      );
      dev.dispose();

      SessionSpace.devActive = false;
      final back = AppStore();
      await back.init();
      expect(back.athlete, isNull);
      expect(back.athleteDraft, isNull);
      expect(back.athleteRedoProposed, isTrue);
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
      back.dispose();
    });
  });
}
