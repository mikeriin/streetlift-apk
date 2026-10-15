// G7 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true … test/g7_mode_dev_test.dart`, sauté dans le
// build ordinaire) : le programme créé dans la session de test et le
// journal du moteur restent dans la session de test, sans fuite vers la
// session personnelle (son programme et son départ ne changent pas).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G7)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('programme créé dans la session de test : session personnelle '
        'intacte, journal du moteur propre à la session de test', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final perso = AppStore();
      await perso.init();
      await perso.configureStart(DateTime(2026, 9, 1));
      perso.seedSampleAthleteProfile();
      await perso.flush();
      final before = jsonEncode(KalisPrefs(raw, dev: false).snapshot());
      perso.dispose();

      SessionSpace.devActive = true;
      final dev = AppStore();
      await dev.init();
      expect(dev.isFreshInstall, isTrue);
      dev.seedSampleAthleteProfile();
      final c = PlanStore(dev).newPlanCreation()!;
      expect(c.journalOn, isTrue);
      c.start();
      c.canDo(c.plan.days.first.slots.first.slotId);
      c.createPass2();
      PlanStore(dev).applyPlanCreation(c);
      await dev.flush();
      await Future<void>.delayed(Duration.zero);
      expect(PlanStore(dev).programPlanned, isTrue);
      final journal = jsonDecode(PlanStore(dev).planJournalText!) as Map;
      expect(journal['kind'], 'kalis_plan_journal');
      expect([
        for (final e in journal['entries'] as List) (e as Map)['op'],
      ], containsAll(['createPass1', 'review', 'createPass2']));
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
      dev.dispose();

      SessionSpace.devActive = false;
      final back = AppStore();
      await back.init();
      expect(PlanStore(back).programPlanned, isFalse);
      expect(PlanStore(back).planJournalText, isNull);
      expect(back.program.start, DateTime(2026, 9, 1));
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
      back.dispose();
    });
  });
}
