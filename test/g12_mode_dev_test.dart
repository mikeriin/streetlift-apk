// G12 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true … test/g12_mode_dev_test.dart`, sauté dans
// le build ordinaire) : outils de la progression dans la session de test
// (« Ajouter 1 000 XP », « Terminer les quêtes du jour »), session
// personnelle intacte.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/dev/dev_widgets.dart';
import 'package:streetlift_tracker/quest/gains_screen.dart';
import 'package:streetlift_tracker/quest/quest_texts.dart' show thousands;
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

void _program(AppStore s) {
  s.saveAthleteProfile(
    ProfileDraft.of(sampleAthleteProfile(on: civilOf(s.storeClock())))
      ..consent = 'refused',
  );
  final c = PlanStore(s).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(s).applyPlanCreation(c);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G12)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('« Ajouter 1 000 XP » et « Terminer les quêtes du jour » : session '
        'de test seulement, payés par le moteur ; session personnelle '
        'intacte', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final perso = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await perso.init();
      _program(perso);
      perso.quest;
      expect(perso.devAddXp(1000), isNull);
      expect(perso.devCompleteDailyQuests(), isNull);
      await perso.flush();
      final before = jsonEncode(KalisPrefs(raw, dev: false).snapshot());
      perso.dispose();

      SessionSpace.devActive = true;
      final dev = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await dev.init();
      _program(dev);
      expect(dev.quest, isNotNull);
      expect(dev.questLevel.level, 1);
      final g = dev.devAddXp(1000)!;
      expect(g.xp, 1000);
      expect(g.levelUp, isTrue);
      expect(dev.questLevel.totalXp, 1000);
      expect(dev.questLevel.level, greaterThan(1));
      // Krédits de niveau payés par le moteur.
      expect(dev.quest!.kreditBalance, greaterThan(0));
      expect(
        g.events.where((e) => e.kind == kc.DelightKind.levelUp),
        isNotEmpty,
      );
      final daily = [
        for (final q in dev.quest!.state.quests)
          if (q.kind == kc.QuestKind.daily &&
              q.status == kc.QuestStatus.active &&
              q.startsOn == civilOf(dev.storeClock()))
            q,
      ];
      expect(daily, isNotEmpty);
      final done = dev.devCompleteDailyQuests()!;
      expect(done.quests.map((q) => q.id).toSet(), daily.map((q) => q.id).toSet());
      for (final q in dev.quest!.state.quests) {
        if (daily.any((d) => d.id == q.id)) {
          expect(q.status, kc.QuestStatus.completed);
        }
      }
      expect(dev.devCompleteDailyQuests(), isNull);
      await dev.flush();
      dev.dispose();
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
    });

    testWidgets('outils de test : boutons de la progression', (tester) async {
      SharedPreferences.setMockInitialValues({});
      SessionSpace.devActive = true;
      store = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await tester.runAsync(store.init);
      _program(store);
      store.quest;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const DevToolsSheet(),
                  ),
                  child: const Text('Outils'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Outils'));
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('dev-add-xp'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.byType(GainsScreen), findsOneWidget);
      expect(find.text('+${thousands(1000)} XP'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
