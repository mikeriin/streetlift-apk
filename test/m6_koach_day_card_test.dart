// M6 — carte « Koach · séance du jour » : en tête de la séance, avant les
// pages d'exercices (plus rien de Koach au-dessus du premier exercice),
// même contenu qu'avant (questionnaire D14, jour de fatigue D25, adaptation
// L11), repliable (une ligne de résumé), absente quand Koach n'a rien à dire.
// Aucune logique de Koach modifiée (mêmes actions, mêmes effets).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/koach_day_card.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart' show scrollToAction;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var now = DateTime(2026, 7, 27, 18);
  late WeekPlan w3;
  late DayPlan d1;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..autoTimer = false
      ..wakelock = false
      ..prefill = true
      ..prepSec = 0
      ..celebrations = false;
    w3 = store.program.week(3);
    d1 = w3.day(1)!;
  });

  setUp(() {
    now = DateTime(2026, 7, 27, 18);
    store.storeClock = () => now;
    store.debugWriteHook = null;
    store.logs.clear();
    store.koach = KoachData();
    store.koachSkipped.clear();
    store.koachWeighInLater = false;
    store.consumeReward();
    store.program.start = DateTime(2026, 7, 13);
    store.startOrigin = 'user';
    store.values
      ..clear()
      ..addAll({
        'B4': 71.5,
        'B8': 32.5,
        'B9': 45.0,
        'B10': 10.0,
        'B11': 110.0,
        'B17': 30.0,
        'B25': 70.0,
      });
    store.refStatus
      ..clear()
      ..addAll({for (final k in store.values.keys) k: 'set'});
    openDayRoutes.clear();
  });
  tearDown(() => store.storeClock = DateTime.now);

  Widget page(Widget child, {double scale = 1, bool dark = true}) =>
      MaterialApp(
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

  void phone(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  const mu = 'P0-84';

  setUp(KoachDayCard.debugReset);

  Finder inPages(Finder f) =>
      find.descendant(of: find.byType(PageView), matching: f);

  testWidgets('carte en tête de séance, avant les exercices ; rien de Koach '
      'dans la page du premier exercice', (tester) async {
    phone(tester, const Size(390, 844));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    final card = find.byKey(const ValueKey('koach-day-card'));
    expect(card, findsOneWidget);
    expect(inPages(card), findsNothing);
    expect(inPages(find.byKey(const ValueKey('koach-questions'))), findsNothing);
    expect(inPages(find.byKey(const ValueKey('koach-fatigue'))), findsNothing);
    // Au-dessus de la page d'exercices, sous le compteur.
    final cardBox = tester.getRect(card);
    expect(cardBox.bottom, lessThanOrEqualTo(tester.getRect(find.byType(PageView)).top));
    expect(
      cardBox.top,
      greaterThanOrEqualTo(tester.getRect(find.textContaining('Exercice 1')).bottom),
    );
    expect(find.text('KOACH · SÉANCE DU JOUR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('même contenu qu\'avant : questionnaire, fatigue, actions ; '
      'repli en une ligne (320 px, texte 200 %)', (tester) async {
    phone(tester, const Size(320, 720));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1), scale: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-questions')), findsOneWidget);
    expect(find.text('Sommeil de la nuit'), findsOneWidget);
    expect(find.text('Forme du jour : 0 au plus bas, 10 excellente'), findsOneWidget);
    await tester.tap(find.text('moins de 5 h'));
    await tester.pumpAndSettle();
    expect(store.koach.answers['S3-J1']!.sleep, 4.5);
    await scrollToAction(tester, find.byKey(const ValueKey('koach-fatigue-accept')));
    expect(find.textContaining('−30 % de volume'), findsOneWidget);
    expect(find.text('Continuer comme prévu'), findsOneWidget);
    // Repli : une ligne de résumé, contenu masqué.
    await tester.tap(find.byKey(const ValueKey('koach-day-toggle')));
    await tester.pumpAndSettle();
    final summary = find.byKey(const ValueKey('koach-day-summary'));
    expect(summary, findsOneWidget);
    expect(
      tester.widget<Text>(summary).data,
      'Sommeil moins de 5 h · Fatigue probable : −30 % proposé',
    );
    expect(tester.widget<Text>(summary).maxLines, 1);
    expect(find.byKey(const ValueKey('koach-questions')), findsNothing);
    expect(find.byKey(const ValueKey('koach-fatigue')), findsNothing);
    // Dépli : même contenu, action conservée (mêmes effets qu'en L7).
    await tester.tap(find.byKey(const ValueKey('koach-day-toggle')));
    await tester.pumpAndSettle();
    await scrollToAction(tester, find.byKey(const ValueKey('koach-fatigue-accept')));
    await tester.tap(find.byKey(const ValueKey('koach-fatigue-accept')));
    await tester.pumpAndSettle();
    expect(store.logs['S3-J1']!.ex[mu]!.sets.length, 3);
    expect(find.byKey(const ValueKey('koach-fatigue')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('Koach désactivé et aucune adaptation : pas de carte', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    store.disableKoach();
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-day-card')), findsNothing);
    expect(find.textContaining('KOACH'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Koach actif sans rien à dire (questionnaire passé) : carte '
      'retirée', (tester) async {
    phone(tester, const Size(390, 844));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('koach-questions-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-day-card')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
