import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/arsenal_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false;
  });
  setUp(() {
    store.unlockedWods.clear();
    store.logs.clear();
    store.wods.removeWhere((w) => !store.isCatalog(w));
    store.notifyListeners();
  });

  Future<void> open(WidgetTester tester, Widget page) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(true), home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('Arsenal propose les séances libres et les WOD du catalogue', (
    tester,
  ) async {
    await open(tester, const ArsenalScreen());
    expect(find.text('Nouvelle séance'), findsOneWidget);
    expect(find.text('Créer un WOD'), findsNothing);
    await tester.ensureVisible(find.text('Catalogue'));
    await tester.tap(find.text('Catalogue'));
    await tester.pumpAndSettle();
    expect(find.byType(WodCatalogScreen), findsOneWidget);
    expect(find.textContaining('Achète un WOD'), findsOneWidget);
    expect(store.wods.where(store.isCatalog), hasLength(1000));
    expect(store.wods.where((w) => store.wodCost(w) <= 0), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('achat en crédits unique, puis lancement sans éditeur', (
    tester,
  ) async {
    final wod = store.wods.firstWhere((w) => store.wodCost(w) <= store.credits);
    final before = store.credits;
    final resultsBefore = wod.results.length;
    final cost = store.wodCost(wod);
    await open(tester, WodPreviewScreen(wodId: wod.id));
    expect(find.text('Lancer le WOD'), findsNothing);
    final buy =
        find
            .ancestor(
              of: find.text('Acheter · $cost crédit${cost > 1 ? 's' : ''}'),
              matching: find.byWidgetPredicate(
                (widget) => widget is FilledButton,
              ),
            )
            .first;
    // Deux activations de la même commande ne facturent jamais deux fois.
    final purchase = tester.widget<FilledButton>(buy).onPressed!;
    purchase();
    purchase();
    await tester.pumpAndSettle();
    expect(store.credits, before - cost);
    expect(store.unlocked(wod), isTrue);
    expect(wod.results.length, resultsBefore);
    expect(find.textContaining('Acheter ·'), findsNothing);
    await tester.tap(find.text('Lancer le WOD'));
    await tester.pumpAndSettle();
    expect(find.text('Démarrer'), findsOneWidget);
    expect(find.byTooltip('Modifier le WOD'), findsNothing);
    expect(store.credits, before - cost);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('sans crédits suffisants, même la route chrono exige un achat', (
    tester,
  ) async {
    // L'essai du jour est jouable sans achat : on prend un autre WOD.
    final wod = store.wods.firstWhere(
      (w) => store.wodCost(w) > store.credits && !store.isTrial(w),
    );
    final before = store.credits;
    await open(tester, WodRunScreen(wodId: wod.id));
    expect(find.byType(WodPreviewScreen), findsOneWidget);
    expect(find.textContaining('Il te manque'), findsOneWidget);
    expect(find.textContaining('Acheter ·'), findsNothing);
    expect(find.text('Démarrer'), findsNothing);
    expect(find.text('Terminer'), findsNothing);
    expect(
      (await store.purchaseWod(wod)).status,
      PurchaseStatus.insufficientCredits,
    );
    expect(store.credits, before);
    expect(store.unlocked(wod), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'les anciens WOD restent jouables avec leurs scores, hors du catalogue',
    (tester) async {
      final legacy = Wod(
        id: 'legacy-personal',
        name: 'Mon ancien défi',
        lines: ['10 push-ups'],
        results: [
          WodResult(at: '2026-09-20T12:00:00', score: '1:20', seconds: 80),
        ],
      );
      store.upsertWod(legacy);
      await open(tester, WodRunScreen(wodId: legacy.id));
      expect(find.text('Démarrer'), findsOneWidget);
      expect(find.byTooltip('Modifier le WOD'), findsNothing);
      expect(legacy.results.single.seconds, 80);
      await tester.pumpWidget(const SizedBox());
      await open(tester, const WodCatalogScreen());
      await tester.enterText(find.byType(TextField), legacy.name);
      await tester.pumpAndSettle();
      expect(find.text('WODs · 0'), findsOneWidget);
      expect(store.wods.any((w) => w.id == legacy.id), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
