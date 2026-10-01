// G2 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true test/g1_mode_dev_test.dart
// test/g2_mode_dev_test.dart`, sauté dans le build ordinaire) :
// - libellé « dev6.1.0 » (D0.9) ;
// - copie avant suppression des WOD propre à chaque session : la session de
//   test copie et nettoie ses données sans toucher à la session
//   personnelle, et inversement.

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/retired_data.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/retired_fixtures.dart';

const _key = 'kalis_state_v3';

Map<String, dynamic> _decode(String stored) =>
    jsonDecode(
          stored.startsWith('gz:')
              ? utf8.decode(gzip.decode(base64Decode(stored.substring(3))))
              : stored,
        )
        as Map<String, dynamic>;

Map<String, dynamic> _document(String theme) => withRetiredData({
  'kalisTrack': 1,
  'format': 3,
  'pilotage': <String, Object?>{},
  'referenceStatus': <String, Object?>{},
  'programStart': {'status': 'pending'},
  'logs': <String, Object?>{},
  'settings': (AppSettings()..theme = theme).toJson(),
  'userExercises': <Object?>[],
  'lastLevel': 1,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G2)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('version affichée : « dev6.2.0 » (G3)', () {
      expect(kAppVersion, 'dev$kVersion');
      expect(kAppVersion, 'dev6.2.0');
    });

    test('copie et suppression séparées par session', () async {
      final perso = _document('dark');
      final test = _document('light');
      SharedPreferences.setMockInitialValues({
        _key: jsonEncode(perso),
        '${SessionSpace.devPrefix}$_key': jsonEncode(test),
      });
      final raw = await SharedPreferences.getInstance();

      // Session de test : sa copie, sous son préfixe ; la session
      // personnelle reste telle quelle (WOD compris) tant qu'elle n'a pas
      // été ouverte.
      SessionSpace.devActive = true;
      final dev = AppStore();
      await dev.init();
      expect(dev.retiredNotice, isNotNull);
      final devCopy = jsonDecode(dev.retiredCopy!) as Map<String, dynamic>;
      expect(devCopy['sessionDeTest'], isTrue);
      expect((devCopy['settings'] as Map)['theme'], 'light');
      expect(
        dev.retiredNotice!.fileName(devSession: true),
        startsWith('kalis-track-session-de-test-copie-avant-g2-'),
      );
      expect(
        raw.getString('${SessionSpace.devPrefix}${AppStore.kRetiredCopyKey}'),
        isNotNull,
      );
      expect(raw.getString(AppStore.kRetiredCopyKey), isNull);
      expect(jsonEncode(_decode(raw.getString(_key)!)), jsonEncode(perso));
      final devDoc = _decode(raw.getString('${SessionSpace.devPrefix}$_key')!);
      expect(devDoc.keys.any(kRetiredSections.contains), isFalse);
      dev.dispose();

      // Session personnelle : sa propre copie, sans marque de test.
      SessionSpace.devActive = false;
      final me = AppStore();
      await me.init();
      final copy = jsonDecode(me.retiredCopy!) as Map<String, dynamic>;
      expect(copy.containsKey('sessionDeTest'), isFalse);
      expect((copy['settings'] as Map)['theme'], 'dark');
      expect(copy['catalog'], perso['catalog']);
      final doc = _decode(raw.getString(_key)!);
      expect(doc.keys.any(kRetiredSections.contains), isFalse);
      me.dispose();
    });
  });
}
