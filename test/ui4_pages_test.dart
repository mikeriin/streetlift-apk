// UI4 (refonte UI) : pages d'aide, départ du programme, tests guidés et
// création du programme — titres qui reprennent le libellé d'entrée (R3),
// culs-de-sac résolus (R6), confirmation de remplacement au gabarit (§4.5),
// « Mes références (facultatif) » au premier départ (R1, R2).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/guided_tests.dart';
import 'package:streetlift_tracker/kit/kit.dart'
    show KConfirm, KPage, KTextButton, KTopBar;
import 'package:streetlift_tracker/plan/plan_screens.dart';
import 'package:streetlift_tracker/program_start.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wellbeing_screens.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 9);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });
  setUp(() async {
    await store.eraseAllData();
    store.storeClock = () => now;
  });
  tearDown(() => store.storeClock = DateTime.now);

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  /// Écran ouvert par-dessus une page, pour tester le retour.
  Widget host(Widget screen) => Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<bool>(builder: (_) => screen)),
          child: const Text('ouvrir'),
        ),
      ),
    ),
  );

  String topTitle(WidgetTester tester) =>
      tester.widget<KTopBar>(find.byType(KTopBar).last).title!;

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await scrollToAction(tester, f);
    await tester.tap(f.hitTestable().last);
    await tester.pumpAndSettle();
  }

  group('R3 : le titre reprend le libellé d’entrée', () {
    testWidgets('pages d’aide', (tester) async {
      phone(tester);
      await tester.pumpWidget(page(const SafetyScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Santé et sécurité');
      expect(find.byType(KPage), findsOneWidget);

      await tester.pumpWidget(page(const RecoveryScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Récupération');
      expect(find.text('Récupérer'), findsNothing);

      await tester.pumpWidget(page(const PrivacyPolicyScreen()));
      await tester.pump();
      expect(topTitle(tester), 'Politique de confidentialité');
      expect(find.text('CONFIDENTIALITÉ'), findsNothing);

      await tester.pumpWidget(page(const FeedbackScreen(appVersion: '6.11.1')));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Donner mon avis');
      expect(find.text('Ton avis'), findsNothing);
    });

    testWidgets('départ du programme : « Mes références (facultatif) »', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        page(ProgramStartScreen(initialDate: DateTime(2026, 10, 1))),
      );
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Départ du programme');
      final refs = find.text('Mes références (facultatif)');
      await tester.scrollUntilVisible(
        refs,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(refs, findsOneWidget);
      expect(find.text('Tes références (facultatif)'), findsNothing);
    });

    testWidgets('création du programme : « Créer mon programme »', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const PlanCreationScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Créer mon programme');
    });
  });

  group('R6 : aucun cul-de-sac', () {
    testWidgets('création sans profil : « Créer mon profil » ouvre le '
        'parcours du profil, sans chemin écrit', (tester) async {
      phone(tester);
      expect(store.athlete, isNull);
      await tester.pumpWidget(page(const PlanCreationScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Réglages ›'), findsNothing);
      final create = find.byKey(const ValueKey('plan-no-profile-create'));
      expect(create, findsOneWidget);
      expect(find.text('Créer mon profil'), findsOneWidget);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.byType(AthleteProfileFlow), findsOneWidget);
    });

    testWidgets('tests guidés sans proposition : une action qui résout', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const GuidedTestsScreen()));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Tests guidés');
      expect(currentTestProposals(), isEmpty);
      final action = find.byKey(const ValueKey('guided-tests-empty-action'));
      expect(action, findsOneWidget);
      // Sans profil : « Créer mon profil » ouvre la page Profil.
      expect(find.text('Créer mon profil'), findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('bloc suivant indisponible : « Revenir à Mon programme »', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(host(const NextBlockUnavailable())));
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      expect(topTitle(tester), 'Bloc suivant');
      await tester.tap(
        find.byKey(const ValueKey('next-block-unavailable-back')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NextBlockUnavailable), findsNothing);
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('programme terminé : « Créer un nouveau programme »', (
      tester,
    ) async {
      phone(tester);
      store.program.start = DateTime(2025, 1, 6);
      await tester.pumpWidget(
        page(Scaffold(body: ProgramStartBanner(now: now))),
      );
      await tester.pumpAndSettle();
      final action = find.descendant(
        of: find.byKey(const ValueKey('program-start-banner')),
        matching: find.widgetWithText(
          KTextButton,
          'Créer un nouveau programme',
        ),
      );
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(PlanCreationScreen), findsOneWidget);
      store.program.start = null;
    });
  });

  testWidgets('remplacer le programme : confirmation au gabarit '
      '(« Annuler » garde, « Remplacer » remplace)', (tester) async {
    phone(tester);
    store.seedSampleAthleteProfile();
    // Un programme existe déjà : la validation demande confirmation.
    store.program.start = DateTime(2026, 10, 1);
    expect(PlanStore(store).planStartFor().replacing, isTrue);
    await tester.pumpWidget(page(host(const PlanCreationScreen())));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tap(tester, 'plan-review');
    await tap(tester, 'plan-review-recap');
    await tap(tester, 'plan-validate-exercises');
    expect(find.byKey(const ValueKey('plan-pass2')), findsOneWidget);
    await tap(tester, 'plan-validate');
    expect(find.byType(KConfirm), findsOneWidget);
    expect(find.text('Remplacer ton programme ?'), findsOneWidget);
    expect(find.text('Remplacer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(KConfirm), findsNothing);
    expect(PlanStore(store).programPlanned, isFalse);
    await tap(tester, 'plan-validate');
    await tester.tap(find.byKey(const ValueKey('confirm-ok')));
    await tester.pumpAndSettle();
    expect(PlanStore(store).programPlanned, isTrue);
    expect(find.byType(PlanCreationScreen), findsNothing);
  });
}
