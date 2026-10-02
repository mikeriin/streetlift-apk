// G10 — build de développement (lancé par `flutter test
// --dart-define=KALIS_DEV=true … test/g10_mode_dev_test.dart`, sauté dans
// le build ordinaire) : simulateur de séances dans la session de test
// (session personnelle intacte), outils de test (simulateur, inspecteur,
// export du journal du moteur dynamique), inspecteur à l'écran.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/dev/dev_flags.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/dev/dev_simulator.dart';
import 'package:streetlift_tracker/dev/dev_widgets.dart';
import 'package:streetlift_tracker/dev/engine_inspector.dart';
import 'package:streetlift_tracker/session_prefs.dart';
import 'package:streetlift_tracker/store.dart';

void _program(AppStore s, kc.GuidanceMode mode) {
  s.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(s.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
  final c = PlanStore(s).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(s).applyPlanCreation(c);
}

Widget _page(Widget child) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('build de développement (G10)', skip: !kDevBuild, () {
    tearDown(() => SessionSpace.devActive = false);

    test('simulateur dans la session de test : séances faites, revue du '
        'moteur ; session personnelle intacte ; journal exportable', () async {
      SharedPreferences.setMockInitialValues({});
      final raw = await SharedPreferences.getInstance();
      final perso = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await perso.init();
      _program(perso, kc.GuidanceMode.assisted);
      await perso.flush();
      final before = jsonEncode(KalisPrefs(raw, dev: false).snapshot());
      perso.dispose();

      SessionSpace.devActive = true;
      final dev = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await dev.init();
      expect(dev.isFreshInstall, isTrue);
      _program(dev, kc.GuidanceMode.free);
      final r = await runDevSimulation(
        dev,
        athleteKey: 'intermediaire_salle',
        weeks: 3,
        seed: 2,
        acceptAll: true,
      );
      expect(r.error, isNull);
      expect(r.sessionsDone, greaterThan(5));
      expect(dev.lastEvolutionReview, isNotNull);
      final journal = dev.evolutionJournalJson!;
      expect(journal['kind'], 'kalis_adapt_journal');
      expect((journal['review'] as Map)['summary'], isNotNull);
      expect(jsonEncode(journal), isNotEmpty);
      await dev.flush();
      expect(jsonEncode(KalisPrefs(raw, dev: false).snapshot()), before);
      dev.dispose();
    });

    testWidgets('outils de test : simulateur, inspecteur, journal du moteur',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      SessionSpace.devActive = true;
      DevSession.active.value = true;
      addTearDown(() => DevSession.active.value = false);
      store = AppStore()..storeClock = () => DateTime(2026, 10, 1, 9);
      await tester.runAsync(store.init);
      _program(store, kc.GuidanceMode.assisted);
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page(const DevToolsSheet()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dev-simulator')), findsOneWidget);
      expect(find.byKey(const ValueKey('dev-inspector')), findsOneWidget);
      expect(find.byKey(const ValueKey('dev-engine-journal')), findsOneWidget);
      // Inspecteur : état du moteur, séance du jour, déblocage.
      await tester.pumpWidget(_page(const EngineInspectorScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('inspector-state')), findsOneWidget);
      expect(find.byKey(const ValueKey('inspector-unlock')), findsOneWidget);
      expect(find.byKey(const ValueKey('inspector-session')), findsOneWidget);
      // Export du journal par le menu de partage.
      String? name, text;
      DevShare.debugHook = (n, t) async {
        name = n;
        text = t;
        return 'shared';
      };
      addTearDown(() => DevShare.debugHook = null);
      await tester.tap(find.byKey(const ValueKey('inspector-export')));
      await tester.pumpAndSettle();
      expect(name, 'kalis_adapt_journal.json');
      expect((jsonDecode(text!) as Map)['kind'], 'kalis_adapt_journal');
      // Simulateur : écran et choix.
      await tester.pumpWidget(_page(const DevSimulatorScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sim-run')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sim-weeks-2')));
      await tester.pumpAndSettle();
      expect(find.text('Simuler 2 semaines'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
