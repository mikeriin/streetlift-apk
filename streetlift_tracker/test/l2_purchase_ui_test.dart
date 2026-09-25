// KT-002, interface : attente, refus et erreur présentés sur la fiche WOD ;
// aucune confirmation avant le résultat de l'écriture.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false;
  });
  tearDown(() {
    store.debugWriteHook = null;
    store.persistenceError.value = null;
    store.unlockedWods.clear(); // isolement : chaque test repart du solde initial
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  Wod pick() => store.wods.firstWhere(
    (w) =>
        store.isCatalog(w) &&
        !store.isTrial(w) &&
        !store.unlocked(w) &&
        store.wodCost(w) <= store.credits,
  );

  Future<void> tapBuy(WidgetTester tester, int cost) async {
    final buy = find.text('Acheter · ${creditsLabel(cost)}');
    await scrollToAction(tester, buy);
    await tester.tap(buy);
    await tester.pump();
  }

  testWidgets('attente affichée, rien de confirmé, fermeture sans erreur', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    final wod = pick();
    final cost = store.wodCost(wod);
    final before = store.credits;
    final gate = Completer<bool>();
    store.debugWriteHook = (_) => gate.future;
    await tester.pumpWidget(page(WodPreviewScreen(wodId: wod.id)));
    await tester.pumpAndSettle();
    await tapBuy(tester, cost);
    expect(find.text('Achat en cours…'), findsOneWidget);
    expect(find.textContaining('débloqué'), findsNothing);
    expect(find.text('Lancer le WOD'), findsNothing);
    expect(store.unlocked(wod), isFalse);
    expect(store.credits, before - cost);
    // La fiche est quittée avant la fin de l'écriture.
    await tester.pumpWidget(page(const Scaffold(body: SizedBox())));
    store.debugWriteHook = null;
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(store.unlocked(wod), isTrue);
    expect(store.credits, before - cost);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('écriture refusée : message, WOD verrouillé, achat possible', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    final wod = pick();
    final cost = store.wodCost(wod);
    final before = store.credits;
    store.debugWriteHook = (_) async => false;
    await tester.pumpWidget(page(WodPreviewScreen(wodId: wod.id)));
    await tester.pumpAndSettle();
    await tapBuy(tester, cost);
    await tester.pumpAndSettle();
    expect(find.textContaining('Achat non enregistré'), findsOneWidget);
    expect(store.unlocked(wod), isFalse);
    expect(store.credits, before);
    expect(find.text('Acheter · ${creditsLabel(cost)}'), findsOneWidget);
    expect(find.text('Lancer le WOD'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
