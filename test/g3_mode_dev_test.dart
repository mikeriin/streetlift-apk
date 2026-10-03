// G3 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true … test/g3_mode_dev_test.dart`, sauté dans le
// build ordinaire) : libellé « dev6.2.0 » (D0.9) ; la session de test a la
// même base d'exercices v1.1 que la session personnelle, et la consulter
// n'écrit rien dans la session personnelle.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G3)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('version affichée : « dev6.8.0 » (CU)', () {
      expect(kAppVersion, 'dev6.8.0');
    });

    test('session de test : même base d\'exercices, session personnelle '
        'intacte', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final perso = AppStore();
      await perso.init();
      final ids = [for (final e in perso.content.entries) e.id];
      await perso.flush();
      final before = {for (final k in raw.getKeys()) k: raw.get(k)};
      perso.dispose();

      SessionSpace.devActive = true;
      final dev = AppStore();
      await dev.init();
      expect([for (final e in dev.content.entries) e.id], ids);
      expect(ids.length, 1039);
      expect(
        searchExercises(
          dev.content,
          'muscle-up',
          const ExerciseFilters(disciplines: {'Calisthénie dynamique'}),
        ),
        isNotEmpty,
      );
      expect(
        dev.exerciseIdFor('Tractions PdC — EMOM'),
        'sw-traction-pronation',
      );
      await dev.flush();
      dev.dispose();

      // Aucune clé personnelle modifiée par la session de test.
      for (final e in before.entries) {
        expect(raw.get(e.key), e.value, reason: e.key);
      }
    });
  });
}
