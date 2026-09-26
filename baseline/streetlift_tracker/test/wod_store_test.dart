// Boutique de WODs 2.5.0 : barème et remises, essai du jour, vitrine de la
// semaine, sélection « à ta mesure », liste d'envies persistée, vitrine du
// catalogue, fiche produit (essai, achat, révélation) et rendu 320 px / 130 %.
import 'package:flutter/material.dart';
import 'phone_test_support.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/progression.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';
import 'package:streetlift_tracker/wod_models.dart';
import 'package:streetlift_tracker/wod_preview.dart';
import 'package:streetlift_tracker/wod_screen.dart';
import 'package:streetlift_tracker/wod_store.dart';

Widget page(Widget child, {double textScale = 1}) => MaterialApp(
  theme: buildTheme(true),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder:
      (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
  home: child,
);

void screen(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Jeudi 24 septembre 2026, 10 h : quatre jours avant le lundi suivant.
DateTime thursday() => DateTime(2026, 9, 24, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('économie', () {
    late AppStore app;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      app = AppStore();
      await app.init();
      app.settings.sound = app.settings.vibration = false;
      app.storeClock = thursday;
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('paliers, prix de base et plancher à 1 crédit', () {
      for (final w in app.wods.where(app.isCatalog)) {
        final expected =
            w.level <= 3
                ? 1
                : w.level <= 6
                ? 2
                : w.level <= 8
                ? 3
                : 4;
        expect(app.basePrice(w), expected, reason: w.id);
        expect(app.wodCost(w), greaterThanOrEqualTo(1), reason: w.id);
        expect(app.wodCost(w), lessThanOrEqualTo(app.basePrice(w)));
        expect(tierOf(w.level), expected);
      }
      expect(app.credits, Progression.creditsForLevel(1));
    });

    test('essai du jour : verrouillé, jouable, stable dans la journée', () {
      expect(app.trialWod, isNotNull);
      final trial = app.trialWod!;
      expect(app.unlocked(trial), isFalse);
      expect(app.isTrial(trial), isTrue);
      expect(app.canRun(trial), isTrue);
      expect(trial.results, isEmpty);
      expect((trial.level - app.targetWodLevel).abs(), lessThanOrEqualTo(1));
      // Même sélection après une notification et après un résultat du jour.
      app.notifyListeners();
      expect(app.trialWod!.id, trial.id);
      final base = app.basePrice(trial);
      app.addWodResult(
        trial,
        WodResult(
          at: thursday().toIso8601String(),
          score: '4:00',
          seconds: 240,
        ),
      );
      app.consumeReward();
      expect(app.trialWod!.id, trial.id);
      expect(app.unlocked(trial), isFalse);
      expect(app.triedAndDone(trial), isTrue);
      expect(app.wodCost(trial), base == 1 ? 1 : base - 1);
      expect(app.discountOf(trial), base == 1 ? 0 : 1);
      // Le lendemain, un autre WOD prend l'affiche.
      app.storeClock = () => DateTime(2026, 9, 25, 10);
      expect(app.trialWod!.id, isNot(trial.id));
    });

    test(
      'vitrine de la semaine : trois formats, −1 crédit, même toute la semaine',
      () {
        final picks = app.weeklyPicks;
        expect(picks, hasLength(3));
        expect(picks.map((w) => w.type).toSet(), hasLength(3));
        expect(picks.map((w) => w.id).toSet(), app.weeklyIds);
        for (final w in picks) {
          expect(app.unlocked(w), isFalse);
          expect(app.isTrial(w), isFalse);
          expect(
            app.wodCost(w),
            app.basePrice(w) == 1 ? 1 : app.basePrice(w) - 1,
          );
        }
        final ids = picks.map((w) => w.id).toList();
        app.storeClock = () => DateTime(2026, 9, 27, 23);
        app.notifyListeners();
        expect(app.weeklyPicks.map((w) => w.id).toList(), ids);
        expect(app.daysUntilNewWeek, 1);
        app.storeClock = thursday;
        expect(app.daysUntilNewWeek, 4);
        expect(app.untilMidnight.inHours, 14);
      },
    );

    test(
      'à ta mesure : verrouillés, autour du niveau, hors essai et vitrine',
      () {
        final reco = app.recommended();
        expect(reco, isNotEmpty);
        expect(reco.length, lessThanOrEqualTo(8));
        final excluded = {...app.weeklyIds, app.trialWod!.id};
        for (final w in reco) {
          expect(app.unlocked(w), isFalse);
          expect(excluded, isNot(contains(w.id)));
        }
        expect(reco.map((w) => w.id).toSet(), hasLength(reco.length));
        final ids = reco.map((w) => w.id).toList();
        app.notifyListeners();
        expect(app.recommended().map((w) => w.id).toList(), ids);
      },
    );

    test('un achat fige le prix remisé et vide la liste d’envies', () async {
      final pick = app.weeklyPicks.firstWhere(
        (w) => app.wodCost(w) <= app.credits,
      );
      final cost = app.wodCost(pick);
      final before = app.credits;
      app.toggleWish(pick);
      expect(app.wished(pick), isTrue);
      expect(
        (await app.purchaseWod(pick, acceptedCost: cost)).status,
        PurchaseStatus.success,
      );
      expect(app.wished(pick), isFalse);
      expect(app.unlockedWods[pick.id], cost);
      expect(app.credits, before - cost);
      expect(app.weeklyIds, isNot(contains(pick.id)));
      expect(app.weeklyPicks, hasLength(3));
      // La remise passée ne bouge pas, même quand la vitrine change.
      app.storeClock = () => DateTime(2026, 10, 5, 10);
      app.notifyListeners();
      expect(app.credits, before - cost);
    });

    test(
      'liste d’envies : prochain objectif, persistance, sauvegarde',
      () async {
        final locked = app.wods.where((w) => app.isCatalog(w)).toList();
        final cheap = locked.firstWhere((w) => app.basePrice(w) == 1);
        final dear = locked.firstWhere((w) => app.basePrice(w) == 4);
        expect(app.wishTarget, isNull);
        app.toggleWish(dear);
        app.toggleWish(cheap);
        expect(app.wishedWods.map((w) => w.id).toList(), [cheap.id, dear.id]);
        expect(app.wishTarget!.id, cheap.id);
        expect(app.missingFor(cheap), 0);
        expect(app.missingFor(dear), 4 - app.credits);
        await app.flush();
        final reloaded = AppStore();
        await reloaded.init();
        expect(reloaded.wishlist, {dear.id, cheap.id});
        final backup = reloaded.exportAll();
        await reloaded.flush();
        reloaded.dispose();
        final imported = AppStore();
        await imported.init();
        expect(await imported.importAll(backup), isTrue);
        expect(imported.wishlist, {dear.id, cheap.id});
        imported.toggleWish(cheap);
        expect(imported.wishlist, {dear.id});
        await imported.flush();
        imported.dispose();
      },
    );
  });

  group('écrans', () {
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
      store.wishlist.clear();
      store.logs.clear();
      store.wods.removeWhere((w) => !store.isCatalog(w));
      for (final w in store.wods) {
        w.results.clear();
      }
      store.consumeReward();
      store.notifyListeners();
    });

    testWidgets(
      'la vitrine ouvre le catalogue et s’efface devant une recherche',
      (tester) async {
        screen(tester);
        await tester.pumpWidget(page(const WodCatalogScreen()));
        await tester.pumpAndSettle();
        expect(find.text('WODs · 1000'), findsOneWidget);
        expect(find.byType(CreditsCard), findsOneWidget);
        expect(find.textContaining('Achète un WOD'), findsOneWidget);
        await scrollToAction(tester, find.text('Essayer · offert'));
        expect(find.byType(WodHero), findsOneWidget);
        expect(find.text('À L\u2019AFFICHE'), findsOneWidget);
        expect(find.text('Essayer · offert'), findsOneWidget);
        await scrollToAction(
          tester,
          find.textContaining('VITRINE DE LA SEMAINE'),
        );
        expect(find.textContaining('VITRINE DE LA SEMAINE'), findsOneWidget);
        expect(find.byType(WishGoalCard), findsNothing);
        // Liste d'envies : le prochain objectif apparaît en tête.
        final wished = store.wods.firstWhere(
          (w) => store.isCatalog(w) && !store.isTrial(w),
        );
        store.toggleWish(wished);
        await tester.pumpAndSettle();
        await scrollToAction(tester, find.text('PROCHAIN OBJECTIF'), up: true);
        expect(find.byType(WishGoalCard), findsOneWidget);
        expect(find.text('PROCHAIN OBJECTIF'), findsOneWidget);
        // Une recherche remplace la vitrine par les résultats.
        await tester.enterText(find.byType(TextField), 'introuvable-12345');
        await tester.pumpAndSettle();
        expect(find.text('WODs · 0'), findsOneWidget);
        expect(find.byType(WodHero), findsNothing);
        expect(find.byType(CreditsCard), findsNothing);
        expect(find.textContaining('disponible'), findsOneWidget);
        expect(find.text('Aucun WOD trouvé'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'l’essai du jour se lance sans achat depuis sa fiche, texte $scale',
        (tester) async {
          screen(
            tester,
            size: scale == 1 ? const Size(390, 844) : const Size(320, 720),
          );
          final trial = store.trialWod!;
          final credits = store.credits;
          await tester.pumpWidget(
            page(WodPreviewScreen(wodId: trial.id), textScale: scale),
          );
          await tester.pumpAndSettle();
          expect(find.text('ESSAI DU JOUR · OFFERT'), findsOneWidget);
          expect(
            find.text('Essayer · offert jusqu\u2019à minuit'),
            findsOneWidget,
          );
          expect(find.text('Lancer le WOD'), findsNothing);
          await tester.tap(find.text('Essayer · offert jusqu\u2019à minuit'));
          await tester.pumpAndSettle();
          expect(find.byType(WodRunScreen), findsOneWidget);
          expect(find.text('Démarrer'), findsOneWidget);
          expect(store.unlocked(trial), isFalse);
          expect(store.credits, credits);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );

      testWidgets(
        'achat : révélation en place, puis lancement, liste vidée, texte $scale',
        (tester) async {
          screen(
            tester,
            size: scale == 1 ? const Size(390, 844) : const Size(320, 720),
          );
          final wod = store.wods.firstWhere(
            (w) =>
                store.isCatalog(w) &&
                !store.isTrial(w) &&
                store.wodCost(w) <= store.credits,
          );
          store.toggleWish(wod);
          final cost = store.wodCost(wod);
          final before = store.credits;
          await tester.pumpWidget(
            page(WodPreviewScreen(wodId: wod.id), textScale: scale),
          );
          await tester.pumpAndSettle();
          expect(find.byTooltip('Liste d\u2019envies'), findsOneWidget);
          expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
          await scrollToAction(tester, find.text('MOUVEMENTS'));
          expect(find.text('MOUVEMENTS'), findsOneWidget);
          await scrollToAction(tester, find.text('POURQUOI ÇA COMPTE'));
          expect(find.text('POURQUOI ÇA COMPTE'), findsOneWidget);
          await scrollToAction(
            tester,
            find.text('Acheter · ${creditsLabel(cost)}'),
          );
          await scrollToAction(tester, find.byType(WodCover), up: true);
          await tester.tap(find.text('Acheter · ${creditsLabel(cost)}'));
          await tester.pump();
          expect(store.unlocked(wod), isTrue);
          expect(store.credits, before - cost);
          expect(store.wished(wod), isFalse);
          expect(find.byType(UnlockReveal), findsOneWidget);
          await tester.pumpAndSettle();
          expect(find.text('Lancer le WOD'), findsOneWidget);
          expect(find.byTooltip('Liste d\u2019envies'), findsNothing);
          expect(find.textContaining('Acheter ·'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
    for (final scale in [1.3, 2.0]) {
      testWidgets('boutique et fiches à 320 px, texte $scale', (tester) async {
        screen(tester, size: const Size(320, 720));
        final trial = store.trialWod!;
        final pick = store.weeklyPicks.first;
        store.toggleWish(pick);
        for (final w in <Widget>[
          const WodCatalogScreen(),
          WodPreviewScreen(wodId: trial.id),
          WodPreviewScreen(wodId: pick.id),
        ]) {
          await tester.pumpWidget(page(w, textScale: scale));
          await tester.pumpAndSettle();
          await scrollToAction(
            tester,
            w is WodCatalogScreen
                ? find.text('Essayer · offert')
                : find.text('POURQUOI ÇA COMPTE'),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: w.runtimeType.toString(),
          );
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      });
    }
  });
}
