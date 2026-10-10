// UI1 (refonte UI, zone Programme) : comportements ajoutés ou déplacés par
// le lot (cahier §4.1, §4.3, §4.6, R4 à R8, C3, C13).
// - récompenses présentées après « Fin de séance » (§4.6) ;
// - ligne « Mon programme » permanente de l'accueil (1 appui), Ma saison et
//   Évolution à 2 appuis, Jour J à 3 (§6.3) ;
// - ⓘ par jour dans la feuille de la semaine (R7), choix de semaine en
//   feuille de liste ;
// - « Revenir à un programme précédent » : feuille d'actions et
//   confirmation (R8) ;
// - états vides avec leur action (R6) ;
// - ni débordement ni titre coupé à 320 dp et 200 % de texte, cibles de
//   48 dp nommées.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/event_day_screen.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/plan/program_position.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/rewards.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

Widget page(
  Widget child, {
  bool dark = true,
  double scale = 1,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: buildTheme(dark),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

/// Profil street (compétition dans 12 semaines), programme créé avec Koach
/// et validé : saison, Jour J, retour à l'ancien programme possible.
void streetProgram() {
  store.saveAthleteProfile(
    ProfileDraft.of(sampleStreetProfile(on: civilOf(store.storeClock())))
      ..consent = 'refused',
  );
  final c = PlanStore(store).newPlanCreation(journal: false)!;
  c.start();
  c.createPass2();
  PlanStore(store).applyPlanCreation(c);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await scrollToAction(tester, f);
  await tester.tap(f.hitTestable().last);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });

  group('accueil (programme du propriétaire)', () {
    setUp(() {
      store.logs.clear();
      store.program.start = DateTime(2026, 7, 13);
      store.startOrigin = 'migration';
    });

    Future<void> openHome(
      WidgetTester tester, {
      Size size = const Size(390, 844),
      double scale = 1,
      bool dark = true,
    }) async {
      phone(tester, size: size);
      await tester.pumpWidget(
        page(
          RootNav(referenceDate: store.program.dateFor(8, 4)),
          scale: scale,
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('« Mon programme » : ligne permanente, ouverte en un appui', (
      tester,
    ) async {
      await openHome(tester);
      final row = find.byKey(const ValueKey('home-my-program'));
      expect(row, findsOneWidget);
      expect(find.text('Mon programme'), findsOneWidget);
      expect(
        find.text('Saison, évolution, calendrier, changer de programme'),
        findsOneWidget,
      );
      await scrollToAction(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(ProgramScreen), findsOneWidget);
      for (final t in ['Calendrier', 'Changer de programme', 'Aide']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Départ du programme'), findsOneWidget);
      expect(find.text('Comment marche ton programme ?'), findsOneWidget);
      // Retour : l'accueil, à la même semaine.
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramScreen), findsNothing);
      expect(find.text('S8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semaine : titre « Semaine n ▾ » vers le choix, ⓘ par jour '
        'vers le résumé (R7)', (tester) async {
      await openHome(tester);
      await tester.tap(find.byKey(const ValueKey('week-choose')));
      await tester.pumpAndSettle();
      expect(find.text('Choisir une semaine'), findsOneWidget);
      await tester.tap(find.text('Semaine 9'));
      await tester.pumpAndSettle();
      expect(find.text('S9'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('week-slider')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('week-sheet')), findsOneWidget);
      expect(find.text('Semaine 9'), findsOneWidget);
      final info = find.byKey(const ValueKey('day-info-1'));
      await tester.ensureVisible(info);
      await tester.tap(info);
      await tester.pumpAndSettle();
      expect(find.text('Résumé · S9 · J1'), findsOneWidget);
      expect(find.byType(SessionScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    for (final dark in [true, false]) {
      testWidgets('accueil à 320 dp et 200 % : rien de coupé ni de '
          'débordant (${dark ? 'sombre' : 'clair'})', (tester) async {
        await openHome(
          tester,
          size: const Size(320, 640),
          scale: 2,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('SEMAINE 8'), findsOneWidget);
        final row = find.byKey(const ValueKey('home-my-program'));
        await scrollToAction(tester, row);
        expect(tester.takeException(), isNull);
        // Rien sous le dock : la ligne s'arrête au-dessus (C8).
        expect(
          tester.getRect(row).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(HeroNavBar)).top),
        );
      });
    }

    testWidgets('accueil : cibles de 48 dp et boutons nommés (C13)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openHome(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  testWidgets('§4.6 : les récompenses viennent après « Fin de séance »', (
    tester,
  ) async {
    phone(tester);
    store.logs.clear();
    store.consumeReward();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      page(const Scaffold(body: Text('Accueil')), navigator: navigator),
    );
    final week = store.program.weeks.firstWhere(
      (w) => w.days.any((d) => d.exercises.isNotEmpty),
    );
    final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
    final nav = navigator.currentState!;
    unawaited(openProgramDay(nav, week, day));
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);

    // Comme la fin d'une séance servie par Koach (session_screen.dart,
    // `_finish`) : séance enregistrée (récompense en attente), séance
    // refermée, puis « Fin de séance » ouverte à la fin de la fermeture.
    store.markSessionDone(week.n, day.j, true, title: 'S${week.n} · J${day.j}');
    final session =
        ModalRoute.of(tester.element(find.byType(SessionScreen)))!;
    final closing = session.completed;
    nav.pop();
    unawaited(
      closing.then(
        (_) => nav.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Fin de séance')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fin de séance'), findsOneWidget);
    // Avant UI1 : l'accueil ouvrait les récompenses dès la fermeture de la
    // séance, sous « Fin de séance ».
    expect(find.byType(RewardScreen, skipOffstage: false), findsNothing);

    // On quitte « Fin de séance » : elle présente les récompenses.
    nav.pop();
    await tester.pumpAndSettle();
    checkLevelUp(nav.context);
    await tester.pump();
    await tester.pump();
    expect(find.byType(RewardScreen), findsOneWidget);
    expect(find.text('Fin de séance'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('sortie d\'une séance sans fin de séance : la vérification de '
      'niveau a toujours lieu au retour', (tester) async {
    phone(tester);
    store.logs.clear();
    store.consumeReward();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      page(const Scaffold(body: Text('Accueil')), navigator: navigator),
    );
    final week = store.program.weeks.firstWhere(
      (w) => w.days.any((d) => d.exercises.isNotEmpty),
    );
    final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
    final nav = navigator.currentState!;
    unawaited(openProgramDay(nav, week, day));
    await tester.pumpAndSettle();
    // Récompense gagnée hors bilan pendant que la séance est ouverte.
    store.markSessionDone(week.n, day.j, true, title: 'S${week.n} · J${day.j}');
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.byType(RewardScreen, skipOffstage: false), findsOneWidget);
    expect(store.consumeReward(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  group('programme créé avec Koach (profil street, compétition)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await store.eraseAllData();
      store.storeClock = () => DateTime(2026, 10, 1, 9);
      streetProgram();
    });
    tearDown(() => store.storeClock = DateTime.now);

    testWidgets('Ma saison en 2 appuis, Jour J en 3 depuis l\'accueil', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        page(RootNav(referenceDate: store.storeClock())),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'home-my-program');
      expect(find.byType(ProgramScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('season-countdown')), findsOneWidget);
      await tapKey(tester, 'season-open');
      expect(find.byType(SeasonScreen), findsOneWidget);
      expect(find.text('Phases'), findsOneWidget);
      await tapKey(tester, 'season-event-day');
      expect(find.byType(EventDayScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Évolution en 2 appuis ; mode réglé par segments', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        page(RootNav(referenceDate: store.storeClock())),
      );
      await tester.pumpAndSettle();
      await tapKey(tester, 'home-my-program');
      await tapKey(tester, 'program-evolution-open');
      expect(find.byType(EvolutionScreen), findsOneWidget);
      await tester.tap(find.text('Libre'));
      await tester.pumpAndSettle();
      expect(store.adaptMode, 'free');
      await tester.tap(find.text('Assisté'));
      await tester.pumpAndSettle();
      expect(store.adaptMode, 'assisted');
    });

    testWidgets('« Revenir à un programme précédent » : feuille d\'actions, '
        'confirmation, « Annuler » ne change rien (R8)', (tester) async {
      phone(tester);
      expect(PlanStore(store).planCanUndo, isTrue);
      await tester.pumpWidget(page(const ProgramScreen()));
      await tester.pumpAndSettle();
      await tapKey(tester, 'program-revert');
      expect(find.text('Revenir à l’ancien programme'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('action-undo')));
      await tester.pumpAndSettle();
      expect(find.text('Revenir à l’ancien programme ?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
      await tester.pumpAndSettle();
      expect(store.planProgram, isNotNull);
      await tapKey(tester, 'program-revert');
      await tester.tap(find.byKey(const ValueKey('action-undo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-ok')));
      await tester.pumpAndSettle();
      expect(store.planProgram, isNull);
      expect(tester.takeException(), isNull);
    });

    for (final dark in [true, false]) {
      testWidgets('320 dp et 200 % : Mon programme, Ma saison, Jour J, '
          'Évolution, Où j\'en suis (${dark ? 'sombre' : 'clair'})', (
        tester,
      ) async {
        phone(tester, size: const Size(320, 640));
        final event = store.athlete!.profile.events!.first;
        for (final screen in <Widget>[
          const ProgramScreen(),
          const SeasonScreen(),
          EventDayScreen(event: event),
          const EvolutionScreen(),
          const ProgramPositionScreen(),
        ]) {
          await tester.pumpWidget(page(screen, scale: 2, dark: dark));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$screen');
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await tester.drag(list.first, const Offset(0, -3000));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$screen (bas)');
          }
        }
      });
    }

    testWidgets('Mon programme : cibles de 48 dp et boutons nommés (C13)', (
      tester,
    ) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(page(const ProgramScreen()));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('états vides (R6)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await store.eraseAllData();
    });

    testWidgets('Évolution sans profil : « Créer mon profil »', (
      tester,
    ) async {
      phone(tester);
      expect(store.athlete, isNull);
      await tester.pumpWidget(page(const EvolutionScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('evo-no-profile')), findsOneWidget);
      expect(find.text('Créer mon profil'), findsOneWidget);
    });

    testWidgets('Ma saison sans saison : une action, jamais un cul-de-sac', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const SeasonScreen()));
      await tester.pumpAndSettle();
      if (storeSeasonOverview() == null) {
        expect(find.byKey(const ValueKey('season-empty')), findsOneWidget);
        expect(find.text('Créer mon profil'), findsOneWidget);
      } else {
        expect(find.byKey(const ValueKey('season-screen')), findsOneWidget);
      }
    });

    testWidgets('Mon programme sans profil : « Créer mon profil »', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(page(const ProgramScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('program-no-profile')), findsOneWidget);
      expect(find.byKey(const ValueKey('program-create-open')), findsNothing);
    });
  });

  test('compte à rebours en deux parties (C9)', () {
    final today = DateTime(2026, 10, 1);
    expect(
      countdownParts(84, 'Championnat', DateTime(2026, 12, 24), today),
      (
        '12\u00a0semaines',
        'avant Championnat, le 24\u00a0décembre (84\u00a0jours)',
      ),
    );
    expect(countdownParts(1, 'Test', DateTime(2026, 10, 2), today).$1, 'Demain');
    expect(
      countdownParts(5, 'Course', DateTime(2027, 1, 1), today).$2,
      'avant Course, le 1er\u00a0janvier\u00a02027',
    );
  });
}
