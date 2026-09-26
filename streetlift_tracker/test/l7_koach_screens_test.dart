// L7 — Interface Koach (KT-033, KT-036) : difficulté en six boutons à la
// validation (D8, D9), suggestion « Appliquer » / « Garder ma charge »
// (D24), questionnaire et jour de fatigue (D14, D25), bilan (D5 b), écran
// Koach, réglages (D6, KT-036). Téléphone 390 × 844 et 320 × 720, texte à
// 100 %, 130 % et 200 %, défilement réel, libellés d'accessibilité.
// Données synthétiques ; aucun appareil réel (voir LIVRAISON_L7).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/koach_screens.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/settings_screen.dart';
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
        builder:
            (context, child) => MediaQuery(
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

  // S3·J1 : P0-84 muscle-up lesté 4×4 RIR 3 (première page).
  const mu = 'P0-84';

  testWidgets('D8/D9 : validation → six boutons, un tap choisit et valide ; '
      'D24 : suggestion appliquée', (tester) async {
    phone(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    store.enableKoach();
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await tester.pumpAndSettle();
    expect(find.text('Série 1 · difficulté'), findsOneWidget);
    for (var r = 0; r <= 5; r++) {
      expect(find.byKey(ValueKey('effort-$r')), findsOneWidget);
    }
    expect(find.text('Très dur'), findsOneWidget);
    expect(find.text('encore 1'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('effort-5')));
    await tester.pumpAndSettle();
    final log = store.logs['S3-J1']!.ex[mu]!;
    expect(log.sets[0].done, isTrue);
    expect(log.sets[0].effort, 5);
    expect(
      find.bySemanticsLabel(RegExp(r'^Série 1 : Facile · encore 5 ou plus')),
      findsOneWidget,
    );
    // Facile pour Soutenu visé : suggestion pour les séries restantes.
    await scrollToAction(tester, find.byKey(const ValueKey('koach-apply')));
    expect(find.textContaining('au lieu de'), findsOneWidget);
    expect(find.textContaining('série 1 à Facile, visé Soutenu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('koach-apply')));
    await tester.pumpAndSettle();
    expect(log.sets[1].kg, '3.75');
    expect(log.sets[3].kg, '3.75');
    expect(find.byKey(const ValueKey('koach-suggestion')), findsNothing);
    expect(log.koach, contains('appliqué'));
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('fiche fermée sans choix : la série reste non validée ; '
      '« Garder ma charge » retenu', (tester) async {
    phone(tester, const Size(390, 844));
    store.enableKoach();
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler').last);
    await tester.pumpAndSettle();
    final log = store.logs['S3-J1']!.ex[mu]!;
    expect(log.sets[0].done, isFalse);
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('effort-4')));
    await tester.pumpAndSettle();
    await scrollToAction(tester, find.byKey(const ValueKey('koach-keep')));
    await tester.tap(find.byKey(const ValueKey('koach-keep')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-suggestion')), findsNothing);
    expect(log.koach, contains('charge gardée'));
    expect(store.koach.decisions.last.status, 'refused');
    // Série écartée (D11) depuis la ligne Koach de la série validée.
    await scrollToAction(tester, find.byKey(const ValueKey('koach-set-1')));
    await tester.tap(find.byKey(const ValueKey('koach-set-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('effort-exclude')));
    await tester.pumpAndSettle();
    expect(log.sets[0].excluded, isTrue);
    expect(log.sets[0].done, isTrue);
    expect(find.textContaining('série écartée'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('D14/D25 : questionnaire facultatif, jour de fatigue proposé '
      'puis accepté (320 px, texte 200 %)', (tester) async {
    phone(tester, const Size(320, 720));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1), scale: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-questions')), findsOneWidget);
    await tester.tap(find.text('moins de 5 h'));
    await tester.pumpAndSettle();
    expect(store.koach.answers['S3-J1']!.sleep, 4.5);
    await scrollToAction(
      tester,
      find.byKey(const ValueKey('koach-fatigue-accept')),
    );
    expect(find.textContaining('volume de 30 %'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('koach-fatigue-accept')));
    await tester.pumpAndSettle();
    expect(store.logs['S3-J1']!.ex[mu]!.sets.length, 3); // 4 × 0,7 → 3
    expect(find.byKey(const ValueKey('koach-fatigue')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('« Passer » masque le questionnaire pour la séance', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('koach-questions-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('koach-questions')), findsNothing);
    expect(store.koach.answers, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('D5 b : fin de séance → bilan Koach (douleur, propositions), '
      'puis retour', (tester) async {
    phone(tester, const Size(390, 844));
    store.enableKoach();
    store.setKoachQuestionnaires(true);
    final log = store.exLog(3, 1, d1.exercises.first);
    log.sets[0]
      ..reps = '4'
      ..effort = 3;
    store.toggleSet(
      log,
      0,
      store.logSpec(d1.exercises.first),
      exercise: d1.exercises.first,
      week: 3,
    );
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => SessionScreen(week: w3, day: d1),
      ),
    );
    await tester.pumpAndSettle();
    final pageCtl = tester.widget<PageView>(find.byType(PageView)).controller!;
    pageCtl.jumpToPage(store.groups(d1).length);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finish-session')));
    await tester.runAsync(() => store.flush());
    await tester.pumpAndSettle();
    expect(find.byType(KoachReviewScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('koach-pain-mu')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('koach-pain-mu')),
        matching: find.text('5'),
      ),
    );
    await tester.pumpAndSettle();
    expect(store.koach.answers['S3-J1']!.pain['mu'], 5);
    expect(find.textContaining('professionnel de santé'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('koach-review-done')));
    await tester.pumpAndSettle();
    expect(find.byType(KoachReviewScreen), findsNothing);
    expect(find.byType(SessionScreen), findsNothing);
    expect(store.isDone(3, 1), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('D6, KT-036 : activation expliquée ; questionnaires après '
      'information', (tester) async {
    phone(tester, const Size(390, 844));
    await tester.pumpWidget(page(const SettingsScreen(section: 8)));
    await tester.pumpAndSettle();
    expect(find.text('KOACH'), findsOneWidget);
    expect(find.textContaining('Désactivé'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.text('Activer Koach ?'), findsOneWidget);
    expect(find.textContaining('Rien ne change sans ton accord'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('koach-activate')));
    await tester.pumpAndSettle();
    expect(store.koachOn, isTrue);
    await scrollToAction(tester, find.text('Questionnaires (facultatif)'));
    await tester.tap(find.text('Questionnaires (facultatif)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('données de santé'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('koach-questionnaires-accept')));
    await tester.pumpAndSettle();
    expect(store.koach.questionnaires, 'on');
    await scrollToAction(tester, find.text('Confidentialité'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in const [Size(390, 844), Size(320, 720)]) {
    for (final scale in const [1.0, 1.3, 2.0]) {
      testWidgets('écrans Koach sans débordement '
          '${size.width.toInt()} px, texte ${(scale * 100).round()} %', (
        tester,
      ) async {
        phone(tester, size);
        final semantics = tester.ensureSemantics();
        store.enableKoach();
        store.setKoachQuestionnaires(true);
        store.setKoachStructure(true);
        store.setKoachObjective('B8', 'final', 75, DateTime(2027, 12, 31));
        // Deux séances de traction et une proposition en attente.
        for (final (week, id, at) in [
          (3, 'P0-85', DateTime(2026, 7, 27, 18)),
          (4, 'B1-7', DateTime(2026, 8, 3, 18)),
        ]) {
          now = at;
          final e = store.program
              .week(week)
              .day(1)!
              .exercises
              .firstWhere((x) => x.id == id);
          final log = store.exLog(week, 1, e);
          for (var i = 0; i < log.sets.length; i++) {
            log.sets[i]
              ..kg = week == 3 ? '11' : '8,75'
              ..reps = week == 3 ? '6' : '8'
              ..effort = 3;
            now = now.add(const Duration(minutes: 5));
            store.toggleSet(log, i, store.logSpec(e), exercise: e, week: week);
          }
          store.markSessionDone(week, 1, true);
          store.consumeReward();
        }
        store.setKoachPain('S4-J1', 'pull', 2);
        for (final screen in <Widget>[
          const KoachScreen(),
          const KoachReviewScreen(week: 4, day: 1),
          const KoachObjectivesScreen(),
          const KoachEquipmentScreen(),
          const KoachWeighInsScreen(),
          const SettingsScreen(section: 8),
        ]) {
          await tester.pumpWidget(page(screen, scale: scale));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$screen');
          final vertical = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          for (var i = 0; i < 12 && vertical.evaluate().isNotEmpty; i++) {
            await tester.drag(vertical.first, const Offset(0, -400));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull, reason: '$screen défilé');
        }
        expect(find.byType(KoachCurve), findsNothing); // écran quitté
        await tester.pumpWidget(page(const KoachScreen(), scale: scale));
        await tester.pumpAndSettle();
        expect(find.byType(KoachCurve), findsWidgets);
        expect(
          find.bySemanticsLabel(RegExp(r'^Courbe de l’estimation')),
          findsWidgets,
        );
        // Séance : carte de suggestion et lignes de difficulté.
        now = DateTime(2026, 8, 10, 18);
        final w5 = store.program.week(5);
        await tester.pumpWidget(
          page(SessionScreen(week: w5, day: w5.day(1)!), scale: scale),
        );
        await tester.pumpAndSettle();
        await scrollToAction(
          tester,
          find.byTooltip('Valider la série 1').first,
        );
        await tester.tap(find.byTooltip('Valider la série 1').first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('effort-5')));
        await tester.pumpAndSettle();
        await scrollToAction(tester, find.byKey(const ValueKey('koach-apply')));
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() => store.flush());
      });
    }
  }
}
