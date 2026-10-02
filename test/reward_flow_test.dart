// Régressions 2.4.1, reprises en G12 avec l'écran de gains du moteur de
// progression (kalis_quest) :
// 1. L'écran de gains s'affiche et s'anime quel que soit l'écran qui a
//    ouvert la séance, et son décompte attend que la séance soit refermée.
// 2. La pastille de niveau suit un passage de niveau sans redémarrer
//    l'application (instances `const` reconstruites).
import 'dart:async';
import 'phone_test_support.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/quest/gains_screen.dart';
import 'package:streetlift_tracker/quest/quest_widgets.dart';
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

/// Registre d'XP de [xp] XP (moteur indisponible : niveau lu au registre).
QuestData _registry(int xp) => QuestData(
  state: kc.QuestState(
    xp: [
      kc.XpEntry(
        sequence: 0,
        date: kc.CivilDate(2026, 9, 20),
        source: kc.XpSource.effort,
        amount: xp,
        sessionId: 'S1-J1',
        reasons: const [],
      ),
    ],
    kredits: const [],
    quests: const [],
    data: const {},
  ),
  seed: 1,
);

String meter(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('gains-xp'))).data!;

/// Sonde minimale : lit le store, instanciée en `const` sous un parent qui ne
/// l'écoute pas.
class _Probe extends StoreWidget {
  const _Probe();
  @override
  Widget build(BuildContext context) =>
      Text('${store.questLevel.totalXp} XP cumulés');
}

final _gains = QuestGains(
  xpBySource: const {kc.XpSource.effort: 100, kc.XpSource.quest: 40},
  kredits: 12,
  before: const kc.LevelState(
    level: 1,
    prestige: 0,
    totalXp: 0,
    xpIntoLevel: 0,
    xpForNextLevel: 30,
  ),
  after: const kc.LevelState(
    level: 3,
    prestige: 0,
    totalXp: 140,
    xpIntoLevel: 20,
    xpForNextLevel: 85,
  ),
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
    store.questData = null;
    store.consumeGains();
    store.notifyListeners();
  });

  testWidgets('la pastille de l’accueil suit un passage de niveau', (
    tester,
  ) async {
    await tester.pumpWidget(page(const HomeScreen()));
    await tester.pumpAndSettle();
    LevelProgressNumber pill() =>
        tester.widget<LevelProgressNumber>(find.byType(LevelProgressNumber));
    expect(pill().level, 1);
    store.questData = _registry(500);
    store.notifyListeners();
    await tester.pump();
    final l = store.questLevel;
    expect(l.level, greaterThan(1));
    expect(pill().level, l.level);
    expect(pill().progress, closeTo(l.xpIntoLevel / l.xpForNextLevel, 1e-9));
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
    expect(find.text('0 XP cumulés'), findsOneWidget);
    store.questData = _registry(300);
    store.notifyListeners();
    await tester.pump();
    expect(find.text('300 XP cumulés'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    // Un écouteur oublié appellerait markNeedsBuild sur un élément démonté.
    store.notifyListeners();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'gains ouverts sans vérification au retour : décompte lancé seulement '
    'après la fermeture de la séance',
    (tester) async {
      phone(tester);
      final closing = Completer<void>();
      await tester.pumpWidget(
        page(GainsScreen(gains: _gains, after: closing.future)),
      );
      await tester.pump();
      expect(meter(tester), '+0 XP');
      // La séance est encore en train de se refermer : rien n'a défilé.
      await tester.pump(const Duration(milliseconds: 400));
      expect(meter(tester), '+0 XP');
      closing.complete();
      await tester.pump();
      final seen = <String>{};
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen.add(meter(tester));
      }
      expect(meter(tester), '+140 XP');
      // Des valeurs intermédiaires : le compteur a réellement défilé.
      expect(seen.length, greaterThanOrEqualTo(4));
      expect(find.byKey(const ValueKey('gains-source-effort')), findsOneWidget);
      expect(find.byKey(const ValueKey('gains-source-quest')), findsOneWidget);
      expect(find.text('Niveau 1 → 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
    store.consumeGains();
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
    await tester.pumpWidget(page(GainsScreen(gains: _gains)));
    expect(meter(tester), '+0 XP');
    await tester.pumpAndSettle();
    expect(meter(tester), '+140 XP');
    expect(find.byKey(const ValueKey('gains-koach')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '« Réduire les animations » affiche les gains finaux sans attendre',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(
        page(GainsScreen(gains: _gains), reduceMotion: true),
      );
      await tester.pump();
      expect(meter(tester), '+140 XP');
      expect(find.byKey(const ValueKey('gains-koach')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.3, 2.0]) {
    testWidgets('gains à 320 px, texte $scale : actions par défilement', (
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
                      builder: (_) => GainsScreen(gains: _gains),
                    ),
                  ),
                  child: const Text('Afficher les gains'),
                ),
              ),
            ),
          ),
          textScale: scale,
        ),
      );
      await tester.tap(find.text('Afficher les gains'));
      await tester.pumpAndSettle();
      expect(meter(tester), '+140 XP');
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('gains-continue')),
      );
      await tester.tap(find.byKey(const ValueKey('gains-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(GainsScreen), findsNothing);
      expect(find.text('Afficher les gains'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('célébrations coupées : message court', () {
    expect(gainsShortText(_gains), '+140 XP · +12 Krédits · niveau 3 !');
  });
}
