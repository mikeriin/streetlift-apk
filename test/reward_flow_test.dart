// Régressions 2.4.1.
// 1. L'écran de récompenses s'affiche et s'anime quel que soit l'écran qui a
//    ouvert la séance (une séance ouverte par un rappel ne le montrait pas),
//    et son décompte attend que la séance soit refermée.
// 2. La pastille de niveau et les cartes « jeu » suivent un passage de niveau
//    sans redémarrer l'application (instances `const` jamais reconstruites
//    auparavant). G2 : plus de solde de crédits WOD.
import 'dart:async';
import 'phone_test_support.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/game_widgets.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/levelup.dart';
import 'package:streetlift_tracker/rewards.dart';
import 'package:streetlift_tracker/session_history.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/store_widget.dart';

Widget page(
  Widget child, {
  GlobalKey<NavigatorState>? navigator,
  bool reduceMotion = false,
  double textScale = 1,
}) => MaterialApp(
  navigatorKey: navigator,
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: child,
);

/// Valide des journées d'entraînement du programme jusqu'au niveau suivant.
void gainLevel() {
  final target = store.level + 1;
  for (final w in store.program.weeks) {
    for (final d in w.days) {
      if (d.exercises.isEmpty || store.isDone(w.n, d.j)) continue;
      store.markSessionDone(w.n, d.j, true, title: 'S${w.n} · J${d.j}');
      store.consumeReward();
      if (store.level >= target) return;
    }
  }
  fail('Niveau $target jamais atteint');
}

String meter(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('reward-xp'))).data!;

/// Sonde minimale : lit le store, instanciée en `const` sous un parent qui ne
/// l'écoute pas.
class _Probe extends StoreWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) => Text('${store.xp} XP cumulés');
}

const _reward = RewardSummary(
  heading: 'Séance validée',
  title: 'S8 · J1',
  xpBefore: 100,
  xpAfter: 240,
  levelBefore: 1,
  levelAfter: 2,
  rankBefore: 'Recrue',
  rankAfter: 'Recrue',
  lines: [
    RewardLine('Journée du programme', 100, 'base'),
    RewardLine('Badge « Premier pas » · Commun', 40, 'badge'),
  ],
  records: [],
);

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
  setUp(() {
    store.logs.clear();
    store.consumeReward();
    store.notifyListeners();
  });

  testWidgets('la pastille de l’accueil suit un passage de niveau', (
    tester,
  ) async {
    await tester.pumpWidget(page(const HomeScreen()));
    await tester.pumpAndSettle();
    LevelProgressNumber pill() =>
        tester.widget<LevelProgressNumber>(find.byType(LevelProgressNumber));
    final start = store.level;
    expect(pill().level, start);
    gainLevel();
    await tester.pump();
    final progress = store.levelProgress;
    expect(store.level, greaterThan(start));
    expect(pill().level, store.level);
    expect(pill().progress, closeTo(progress.inLevel / progress.need, 1e-9));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('la carte d’objectif hebdo de l’Aperçu suit une séance validée', (
    tester,
  ) async {
    await tester.pumpWidget(page(const Scaffold(body: WeeklyGoalCard())));
    await tester.pumpAndSettle();
    expect(find.text('0/${store.game.weekly.target}'), findsOneWidget);
    final week = store.program.weeks.firstWhere(
      (w) => w.days.any((d) => d.exercises.isNotEmpty),
    );
    final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
    store.markSessionDone(week.n, day.j, true, title: 'S${week.n} · J${day.j}');
    store.consumeReward();
    await tester.pump();
    expect(store.game.weekly.done, 1);
    expect(find.text('1/${store.game.weekly.target}'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('un StoreWidget const se reconstruit puis se désabonne', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(const Scaffold(body: Center(child: _Probe()))),
    );
    final before = store.xp;
    expect(find.text('$before XP cumulés'), findsOneWidget);
    gainLevel();
    await tester.pump();
    expect(store.xp, greaterThan(before));
    expect(find.text('${store.xp} XP cumulés'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Un écouteur oublié appellerait markNeedsBuild sur un élément démonté.
    store.notifyListeners();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fin de séance ouverte sans vérification au retour : bilan affiché, '
    'décompte lancé après la fermeture de la séance',
    (tester) async {
      phone(tester);
      // G2 : plus de séance manuelle, journée d'entraînement du programme.
      final week = store.program.weeks.firstWhere(
        (w) => w.days.any((d) => d.exercises.isNotEmpty),
      );
      final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
      await tester.pumpWidget(
        page(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  // Ouverture « nue », comme un rappel avant 2.4.1 :
                  // personne n'appelle checkLevelUp au retour.
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SessionScreen(week: week, day: day),
                    ),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      // Le bilan est la dernière page : accès par le sélecteur d'exercices.
      await tester.tap(find.text('Exercices'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bilan de séance').last);
      await tester.pumpAndSettle();
      await scrollToAction(tester, find.text('Terminer la séance'));
      await tester.tap(find.text('Terminer la séance'));
      // Deux images : la première image d'une page poussée est hors scène
      // (contrôleur de héros), la deuxième la met en place.
      await tester.pump();
      await tester.pump();

      expect(find.byType(RewardScreen), findsOneWidget);
      final reward = tester
          .widget<RewardScreen>(find.byType(RewardScreen))
          .reward;
      // Journée du programme : 100 XP de base (60 pour l'ancienne séance
      // manuelle).
      expect(reward.xpGained, greaterThanOrEqualTo(100));
      expect(store.consumeReward(), isNull);
      expect(meter(tester), '+0 XP');

      // La séance est encore en train de se refermer : rien n'a défilé.
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SessionScreen), findsOneWidget);
      expect(meter(tester), '+0 XP');

      final seen = <String>{};
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen.add(meter(tester));
      }
      expect(find.byType(SessionScreen), findsNothing);
      expect(meter(tester), '+${reward.xpGained} XP');
      // Des valeurs intermédiaires : le compteur a réellement défilé.
      expect(seen.length, greaterThanOrEqualTo(4));

      await scrollToAction(
        tester,
        find.byKey(const ValueKey('reward-continue')),
      );
      await tester.tap(find.byKey(const ValueKey('reward-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(RewardScreen), findsNothing);
      expect(find.text('Ouvrir'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('un rappel ouvre la séance, ou son historique une fois faite', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      page(const Scaffold(body: SizedBox()), navigator: navigator),
    );
    final week = store.program.weeks.firstWhere(
      (w) => w.days.any((d) => d.exercises.isNotEmpty),
    );
    final day = week.days.firstWhere((d) => d.exercises.isNotEmpty);
    unawaited(openProgramDay(navigator.currentState!, week, day));
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionScreen), findsNothing);

    store.markSessionDone(week.n, day.j, true, title: 'S${week.n} · J${day.j}');
    store.consumeReward();
    unawaited(openProgramDay(navigator.currentState!, week, day));
    await tester.pumpAndSettle();
    expect(find.byType(SessionHistoryScreen), findsOneWidget);
    expect(find.byType(SessionScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('le décompte part de zéro et va jusqu’au gain complet', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(page(const RewardScreen(reward: _reward)));
    expect(meter(tester), '+0 XP');
    await tester.pumpAndSettle();
    expect(meter(tester), '+140 XP');
    await scrollToAction(tester, find.byKey(const ValueKey('reward-ceremony')));
    expect(find.byKey(const ValueKey('reward-ceremony')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '« Réduire les animations » affiche le bilan final sans attendre',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        page(const RewardScreen(reward: _reward), reduceMotion: true),
      );
      await tester.pump();
      expect(meter(tester), '+140 XP');
      final ceremony = find.byKey(const ValueKey('reward-ceremony'));
      await scrollToAction(tester, ceremony);
      expect(ceremony, findsOneWidget);
      final reveal = tester.widget<Opacity>(
        find.ancestor(of: ceremony, matching: find.byType(Opacity)).first,
      );
      expect(reveal.opacity, 1);
      expect(tester.takeException(), isNull);
    },
  );
  for (final scale in [1.3, 2.0]) {
    testWidgets('récompense à 320 px, texte $scale : actions par défilement', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      await tester.pumpWidget(
        page(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RewardScreen(reward: _reward),
                    ),
                  ),
                  child: const Text('Afficher la récompense'),
                ),
              ),
            ),
          ),
          textScale: scale,
        ),
      );
      await tester.tap(find.text('Afficher la récompense'));
      await tester.pumpAndSettle();
      expect(meter(tester), '+140 XP');
      expect(
        find.byKey(const ValueKey('reward-continue')).hitTestable(),
        findsNothing,
      );
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('reward-ceremony')),
      );
      expect(find.byKey(const ValueKey('reward-ceremony')), findsOneWidget);
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('reward-continue')),
      );
      await tester.tap(find.byKey(const ValueKey('reward-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(RewardScreen), findsNothing);
      expect(find.text('Afficher la récompense'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
