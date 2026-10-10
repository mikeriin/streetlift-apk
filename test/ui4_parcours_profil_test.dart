// UI4 (refonte UI) — parcours de création du profil : une question par
// écran, progression en segments, « Continuer » fixé en bas (hors de la
// liste qui défile), « Passer » sur les étapes facultatives seulement,
// formulaires (ex-feuilles) en sous-pages, durée « Autre » réglée en place,
// accord santé en segments. Mêmes questions, réponses et effets.
// Données synthétiques ; horloge injectée ; stockage simulé.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_flow.dart';
import 'package:streetlift_tracker/profile_v3.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/ui.dart';

import 'phone_test_support.dart';

/// Brouillon d'un débutant complet et valide (forme générale).
ProfileDraft _beginner() {
  final d = ProfileDraft()
    ..sex = Sex.male
    ..birthYear = '1994'
    ..height = '178'
    ..primary = TrainingDiscipline.generalFitness
    ..experience = ExperienceLevel.beginner
    ..consent = 'refused'
    ..guidance = GuidanceMode.assisted;
  d.addSecondary(TrainingDiscipline.mobility);
  d.goals.add(
    Goal(
      id: 'goal-1',
      kind: GoalKind.habit,
      origin: GoalOrigin.user,
      createdOn: CivilDate(2026, 10, 1),
      sessionsPerWeek: 2,
      weeks: 8,
    ),
  );
  d.days
    ..[2] = 30
    ..[5] = 30;
  d.addPlace(Place.home);
  return d;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 1, 12);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  setUp(() async {
    store.debugWriteHook = null;
    await store.eraseAllData();
    store.storeClock = () => now;
  });
  tearDown(() => store.storeClock = DateTime.now);

  Widget page(Widget child, {bool dark = true}) => MaterialApp(
    theme: buildTheme(dark),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  AthleteProfileFlowState flow(WidgetTester tester) =>
      tester.state<AthleteProfileFlowState>(find.byType(AthleteProfileFlow));

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(ValueKey(key));
    await scrollToAction(tester, f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Ouvre le parcours (création) sur l'étape [step] d'un brouillon.
  Future<void> openAt(
    WidgetTester tester,
    String step, {
    ProfileDraft? draft,
    bool dark = true,
  }) async {
    await store.saveAthleteDraft(
      draft ?? _beginner(),
      step: step,
      mode: 'create',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(const AthleteProfileFlow(), dark: dark));
    await tester.pumpAndSettle();
    expect(flow(tester).step, step);
  }

  int segments() => find
      .byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('flow-progress-'),
      )
      .evaluate()
      .length;

  for (final dark in [true, false]) {
    testWidgets('progression en segments : une pilule par étape montrée, '
        '« Étape n sur N » (${dark ? 'sombre' : 'clair'})', (tester) async {
      phone(tester);
      final semantics = tester.ensureSemantics();
      await openAt(tester, 'identity', dark: dark);
      final st = flow(tester);
      // Accueil exclu ; récapitulatif compris (comme l'ancienne barre).
      final count = st.visibleSteps.length - 1;
      expect(find.byKey(const ValueKey('flow-progress')), findsOneWidget);
      expect(segments(), count);
      expect(find.bySemanticsLabel('Étape 1 sur $count'), findsOneWidget);
      // Pilules séparées de 4 dp.
      final a = tester.getRect(find.byKey(const ValueKey('flow-progress-0')));
      final b = tester.getRect(find.byKey(const ValueKey('flow-progress-1')));
      expect(b.left - a.right, closeTo(KSpacing.s4, .01));
      st.debugGo('availability');
      await tester.pumpAndSettle();
      final i = st.visibleSteps.indexOf('availability');
      expect(segments(), count);
      expect(find.bySemanticsLabel('Étape $i sur $count'), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('« Continuer » fixé en bas, hors de la liste qui défile', (
    tester,
  ) async {
    phone(tester);
    await openAt(tester, 'identity');
    final next = find.byKey(const ValueKey('flow-next-identity'));
    expect(next.hitTestable(), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Scrollable), matching: next),
      findsNothing,
      reason: 'le bouton principal ne défile pas avec la liste',
    );
    expect(find.byType(KPrimaryButton), findsOneWidget);
    final before = tester.getRect(next);
    expect(before.bottom, greaterThan(844 - 100), reason: 'zone du pouce');
    await tester.drag(
      find.byKey(const ValueKey('flow-identity')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(next), before);
    expect(next.hitTestable(), findsOneWidget);
  });

  testWidgets('« Passer » : sur les étapes facultatives seulement', (
    tester,
  ) async {
    phone(tester);
    await openAt(tester, 'identity');
    final st = flow(tester);
    const optional = {'experience', 'levels', 'recovery', 'preferences'};
    for (final step in st.visibleSteps) {
      if (step == 'welcome' || step == 'recap') continue;
      st.debugGo(step);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('flow-skip-$step')),
        optional.contains(step) ? findsOneWidget : findsNothing,
        reason: step,
      );
    }
    for (final step in ['welcome', 'recap']) {
      st.debugGo(step);
      await tester.pumpAndSettle();
      expect(find.text('Passer'), findsNothing, reason: step);
    }
  });

  testWidgets('« Passer » avance d’une étape, la question reste sans '
      'réponse', (tester) async {
    phone(tester);
    await openAt(tester, 'experience');
    expect(flow(tester).draft.experience, ExperienceLevel.beginner);
    await tap(tester, 'flow-skip-experience');
    expect(flow(tester).step, 'levels');
    expect(flow(tester).draft.experience, isNull);
    // Étape suivante facultative : « Passer » encore proposé ; les
    // objectifs, obligatoires, n'en ont pas.
    expect(find.byKey(const ValueKey('flow-skip-levels')), findsOneWidget);
    await tap(tester, 'flow-skip-levels');
    expect(flow(tester).step, 'goals');
    expect(find.byKey(const ValueKey('flow-skip-goals')), findsNothing);
  });

  testWidgets('modifier une rubrique : jamais de « Passer »', (tester) async {
    phone(tester);
    store.saveAthleteProfile(_beginner());
    await tester.pumpWidget(
      page(
        const AthleteProfileFlow(
          mode: AthleteFlowMode.edit,
          editStep: 'experience',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('flow-save')), findsOneWidget);
    expect(find.byKey(const ValueKey('flow-skip-experience')), findsNothing);
    expect(find.byKey(const ValueKey('flow-progress')), findsNothing);
  });

  testWidgets('« Ajouter un record » s’ouvre en sous-page et rend le record '
      'au brouillon', (tester) async {
    phone(tester);
    final d = _beginner()
      ..experience = ExperienceLevel.intermediate
      ..weight = '75'
      ..primary = TrainingDiscipline.streetlifting
      ..secondaries.clear();
    d.addSecondary(TrainingDiscipline.calisthenics);
    await openAt(tester, 'levels', draft: d);
    await tap(tester, 'benchmark-add');
    // Une page (en-tête standard titré du bouton), pas une feuille.
    expect(find.byKey(const ValueKey('benchmark-sheet')), findsOneWidget);
    expect(find.byType(KPage), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.textContaining(RegExp('ajouter un record', caseSensitive: false)),
      findsOneWidget,
    );
    await tap(tester, 'benchmark-exercise');
    expect(find.byKey(const ValueKey('exercise-picker')), findsOneWidget);
    expect(find.text('Rechercher un exercice'), findsOneWidget);
    await tap(tester, 'picker-suggested-sl-traction-lestee');
    await tester.enterText(
      find.byKey(const ValueKey('benchmark-load')),
      '32,5',
    );
    await tester.enterText(find.byKey(const ValueKey('benchmark-reps')), '3');
    await tester.pumpAndSettle();
    await tap(tester, 'benchmark-rir-1');
    await tap(tester, 'benchmark-date-month');
    await tap(tester, 'benchmark-save');
    expect(find.byKey(const ValueKey('benchmark-sheet')), findsNothing);
    final b = flow(tester).draft.benchmarks!.single;
    expect(b.exerciseId, 'sl-traction-lestee');
    expect(b.externalLoadKg, 32.5);
    expect(b.reps, 3);
    expect(b.rir, 1);
    expect(b.date, CivilDate(2026, 10, 1));
    expect(find.byKey(const ValueKey('benchmark-0')), findsOneWidget);
    await store.saveAthleteDraft(null);
  });

  testWidgets('durée « Autre » réglée en place (plus de dialogue)', (
    tester,
  ) async {
    phone(tester);
    await openAt(tester, 'availability');
    expect(find.byType(KStepper), findsNothing);
    await tap(tester, 'flow-min-2-other');
    expect(find.byType(AlertDialog), findsNothing);
    final stepper = find.byKey(const ValueKey('flow-min-2-stepper'));
    expect(stepper, findsOneWidget);
    await scrollToAction(tester, stepper);
    await tester.tap(find.byTooltip('Plus 5 minutes'));
    await tester.pumpAndSettle();
    expect(flow(tester).draft.days[2], 35);
    await tester.tap(find.byTooltip('Moins 5 minutes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Moins 5 minutes'));
    await tester.pumpAndSettle();
    expect(flow(tester).draft.days[2], 25);
    // Une durée proposée referme le réglage.
    await tap(tester, 'flow-min-2-45');
    expect(flow(tester).draft.days[2], 45);
    expect(find.byKey(const ValueKey('flow-min-2-stepper')), findsNothing);
    await store.saveAthleteDraft(null);
  });

  testWidgets('accord santé en segments ; chips du kit pour les choix', (
    tester,
  ) async {
    phone(tester);
    await openAt(tester, 'health');
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    await tap(tester, 'segment-given');
    expect(flow(tester).draft.consent, 'given');
    expect(find.byType(KChip), findsWidgets);
    await tap(tester, 'segment-refused');
    expect(flow(tester).draft.consent, 'refused');
    expect(find.byKey(const ValueKey('flow-refused')), findsOneWidget);
    expect(find.textContaining('Réglages ›'), findsNothing);
    await store.saveAthleteDraft(null);
  });
}
