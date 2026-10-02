// G10 (D1.4) — séance du programme sans le moteur dynamique (pas de profil
// v2) après le retrait de Koach L7 : flammes à chaque série (G9), série
// écartée, aucune suggestion ni carte de l'ancien Koach, même avec des
// données de L7 dans la sauvegarde. Repris de l7_koach_screens_test
// (retiré avec L7).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
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
    store.koach = KoachData()
      ..enabled = true
      ..introSeen = true;
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

  // S3·J1 : P0-84 muscle-up lesté 4×4 RIR 3 (première page).
  const mu = 'P0-84';

  testWidgets('coche : série validée avec la flamme visée ; correction sur '
      'la ligne ; aucune suggestion de l’ancien Koach', (tester) async {
    phone(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    // Sans moteur : pas de page « Bilan du jour », premier exercice.
    expect(find.byKey(const ValueKey('session-health-page')), findsNothing);
    expect(find.byKey(const ValueKey('session-koach-page')), findsNothing);
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await tester.pumpAndSettle();
    // La coche valide la série avec la flamme visée (RIR 3 → 5) ; la ligne
    // des 10 positions s'ouvre sous la série.
    final log = store.logs['S3-J1']!.ex[mu]!;
    expect(log.sets[0].done, isTrue);
    expect(log.sets[0].flames, 5);
    expect(find.byKey(const ValueKey('flame-track-1')), findsOneWidget);
    for (var f = 1; f <= 10; f++) {
      expect(find.byKey(ValueKey('flame-pos-$f')), findsOneWidget);
    }
    expect(find.text('Soutenu · RIR 3'), findsOneWidget);
    // Repères sous la ligne : le mot de la flamme 1 et de la flamme 10.
    expect(find.text('1 · léger'), findsOneWidget);
    expect(find.text('échec · 10'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('flame-pos-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flame-pos-1')));
    await tester.pumpAndSettle();
    expect(log.sets[0].done, isTrue);
    expect(log.sets[0].flames, 1);
    expect(log.sets[0].effort, 5);
    expect(find.text('Léger · RIR 5 et plus'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Difficulté de la série 1')),
      findsOneWidget,
    );
    // Rien de l'ancien Koach : ni suggestion, ni prescription écrite.
    expect(find.byKey(const ValueKey('koach-apply')), findsNothing);
    expect(find.byKey(const ValueKey('koach-suggestion')), findsNothing);
    expect(log.koach, isNull);
    expect(log.prescribed, isNull);
    expect(log.sets[1].kg, log.sets[2].kg);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('série écartée depuis le menu de la ligne des flammes', (
    tester,
  ) async {
    phone(tester, const Size(390, 844));
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Valider la série 1').first);
    await tester.pumpAndSettle();
    final log = store.logs['S3-J1']!.ex[mu]!;
    expect(log.sets[0].done, isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('flame-pos-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flame-pos-3')));
    await tester.pumpAndSettle();
    expect(log.sets[0].flames, 3);
    await scrollToAction(tester, find.byKey(const ValueKey('flame-menu')));
    await tester.tap(find.byKey(const ValueKey('flame-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flame-exclude')));
    await tester.pumpAndSettle();
    expect(log.sets[0].excluded, isTrue);
    expect(log.sets[0].done, isTrue);
    await tester.tap(find.byKey(const ValueKey('flame-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Réintégrer la série'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });

  testWidgets('menu de séance sans moteur : ni « J’ai seulement… », ni '
      '« Échanger un exercice », ni « Je m’entraîne ailleurs »', (tester) async {
    phone(tester, const Size(390, 844));
    await tester.pumpWidget(page(SessionScreen(week: w3, day: d1)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Options de séance'));
    await tester.pumpAndSettle();
    expect(find.text('J’ai seulement… minutes'), findsNothing);
    expect(find.text('Échanger un exercice'), findsNothing);
    expect(find.text('Je m’entraîne ailleurs'), findsNothing);
    expect(find.text('Douleur ou malaise ?'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.flush());
  });
}
