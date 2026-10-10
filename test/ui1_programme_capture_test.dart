// UI1 (refonte UI, zone Programme) — captures des écrans du lot
// (PIPELINE_UI.md §3) : sombre et clair, palettes `bordeaux` et `neon` ;
// accueil (haut, bas, feuille de la semaine, choix de semaine) sur le
// programme du propriétaire ; Mon programme, Ma saison, Jour J, Évolution,
// Où j'en suis, « Revenir à un programme précédent » et l'explication du
// programme sur un programme créé avec Koach (profil street, compétition) ;
// accueil et Mon programme à 320 dp et 200 % de texte. Lancé par la CI avec
// --dart-define=KALIS_CAPTURE=true ; fichiers validation/UI/ui1_*.png,
// recopiés dans ci-out/captures-ui/.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/plan/event_day_screen.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/plan/program_position.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();
  final navigator = GlobalKey<NavigatorState>();

  setUpAll(() async {
    await loadUiFonts();
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
  });

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    required bool dark,
    required String palette,
    double width = 390,
    double height = 844,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    store.settings.theme = dark ? 'dark' : 'light';
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          navigatorKey: navigator,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark, KAccentSpec.byId(palette)),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: name);
    await saveUiPng(tester, root, name, pixelRatio: 1.5);
  }

  Future<void> toEnd(WidgetTester tester) async {
    final lists = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    for (var i = 0; i < 20 && lists.evaluate().isNotEmpty; i++) {
      await tester.drag(lists.last, const Offset(0, -600));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('accueil : sombre, clair × bordeaux, neon', (tester) async {
    addTearDown(tester.view.reset);
    store.logs.clear();
    store.program.start = DateTime(2026, 7, 13);
    store.startOrigin = 'migration';
    store.sessionLog(8, 1).done = true;
    store.sessionLog(8, 2).done = true;
    final ref = store.program.dateFor(8, 3);
    for (final palette in ['bordeaux', 'neon']) {
      for (final dark in [true, false]) {
        final tag = '${palette}_${dark ? 'sombre' : 'clair'}';
        await show(
          tester,
          RootNav(referenceDate: ref),
          dark: dark,
          palette: palette,
        );
        await shot(tester, 'ui1_accueil_$tag');
        await toEnd(tester);
        await shot(tester, 'ui1_accueil_bas_$tag');
        await show(
          tester,
          RootNav(referenceDate: ref),
          dark: dark,
          palette: palette,
        );
        await tester.tap(find.byKey(const ValueKey('week-slider')));
        await tester.pumpAndSettle();
        await shot(tester, 'ui1_semaine_$tag');
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('week-choose')));
        await tester.pumpAndSettle();
        await shot(tester, 'ui1_choix_semaine_$tag');
      }
    }
    await show(
      tester,
      RootNav(referenceDate: ref),
      dark: true,
      palette: 'bordeaux',
      width: 320,
      height: 640,
      scale: 2,
    );
    await shot(tester, 'ui1_320_accueil_bordeaux_sombre');
    await toEnd(tester);
    await shot(tester, 'ui1_320_accueil_bas_bordeaux_sombre');
    await show(
      tester,
      RootNav(referenceDate: ref),
      dark: false,
      palette: 'neon',
      width: 320,
      height: 640,
      scale: 2,
    );
    await tester.tap(find.byKey(const ValueKey('week-slider')));
    await tester.pumpAndSettle();
    await shot(tester, 'ui1_320_semaine_neon_clair');
    await tester.pumpWidget(const SizedBox());
  }, skip: !uiCaptureEnabled);

  testWidgets('Mon programme et ses pages : sombre, clair × bordeaux, neon', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    await store.eraseAllData();
    store.storeClock = () => DateTime(2026, 10, 1, 9);
    addTearDown(() => store.storeClock = DateTime.now);
    store.saveAthleteProfile(
      ProfileDraft.of(sampleStreetProfile(on: civilOf(store.storeClock())))
        ..consent = 'refused',
    );
    // Deux programmes créés : le retour à l'ancien est possible (7 jours).
    for (var i = 0; i < 2; i++) {
      final c = PlanStore(store).newPlanCreation(journal: false)!;
      c.start();
      c.createPass2();
      PlanStore(store).applyPlanCreation(c);
    }
    final event = store.athlete!.profile.events!.first;
    for (final palette in ['bordeaux', 'neon']) {
      for (final dark in [true, false]) {
        final tag = '${palette}_${dark ? 'sombre' : 'clair'}';
        Future<void> page(String name, Widget w) async {
          await show(tester, w, dark: dark, palette: palette);
          await shot(tester, 'ui1_${name}_$tag');
        }

        await page('mon_programme', const ProgramScreen());
        await toEnd(tester);
        await shot(tester, 'ui1_mon_programme_bas_$tag');
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('program-revert')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('program-revert')));
        await tester.pumpAndSettle();
        await shot(tester, 'ui1_revenir_$tag');
        await tester.tap(find.byKey(const ValueKey('action-undo')));
        await tester.pumpAndSettle();
        await shot(tester, 'ui1_revenir_confirmation_$tag');
        await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('program-explainer-open')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('program-explainer-open')));
        await tester.pumpAndSettle();
        await shot(tester, 'ui1_explication_$tag');
        await page('ma_saison', const SeasonScreen());
        await toEnd(tester);
        await shot(tester, 'ui1_ma_saison_bas_$tag');
        await page('jour_j', EventDayScreen(event: event));
        await page('evolution', const EvolutionScreen());
        await page('ou_j_en_suis', const ProgramPositionScreen());
      }
    }
    await show(
      tester,
      const ProgramScreen(),
      dark: true,
      palette: 'bordeaux',
      width: 320,
      height: 640,
      scale: 2,
    );
    await shot(tester, 'ui1_320_mon_programme_bordeaux_sombre');
    await show(
      tester,
      const SeasonScreen(),
      dark: false,
      palette: 'neon',
      width: 320,
      height: 640,
      scale: 2,
    );
    await shot(tester, 'ui1_320_ma_saison_neon_clair');
    for (final (name, w) in <(String, Widget)>[
      ('jour_j', EventDayScreen(event: event)),
      ('evolution', const EvolutionScreen()),
      ('ou_j_en_suis', const ProgramPositionScreen()),
    ]) {
      await show(
        tester,
        w,
        dark: true,
        palette: 'bordeaux',
        width: 320,
        height: 640,
        scale: 2,
      );
      await shot(tester, 'ui1_320_${name}_bordeaux_sombre');
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !uiCaptureEnabled);
}
