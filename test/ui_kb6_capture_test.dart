// KB6 (dev7.8.0, Koach 1.0.9, C17.54-55) — rendus de test : écran
// « Remplacer pour aujourd'hui » du dip lesté de la J5 avec les
// propositions de Koach (mode libre : « Pourquoi ? › Pas de matériel › Il
// me manque : ceinture de lest », propositions étiquetées, recherche en
// dessous ; mode assisté : propositions seules) et carte du bilan du jour
// en mode libre (« Koach note ta forme du jour même si tu gardes
// l'écrit ») ; sombre et clair × `bordeaux` et `violet`, 390 dp. Lancé par la
// CI avec --dart-define=KALIS_CAPTURE=true ; fichiers
// validation/UI/kb6_<état>_<palette>_<thème>.png. Données synthétiques
// (programme PR2), bilan bas 1/1/1.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/koach1/koach1_widgets.dart';
import 'package:streetlift_tracker/koach1/koach_moteur.dart';
import 'package:streetlift_tracker/session_replace_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'kb2c1_fixtures.dart';
import 'support/ui_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();
  var clock = DateTime(2026, 10, 23, 7); // vendredi, S15·J5

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    KoachCalcul.isolat = false;
    debugKoachBasculeAutorisee = true;
    debugResetKoachTakeoverWait();
    store.storeClock = () => clock;
    await store.init();
    await importPr2Nouveau(store, firstWeek: 12);
    store.koachNoteInstall();
    await store.koachRefresh();
    await loadUiFonts();
  });
  tearDownAll(() => debugKoachBasculeAutorisee = false);

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    required bool dark,
    required String palette,
    double height = 900,
  }) async {
    tester.view.physicalSize = Size(390, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    store.settings.theme = dark ? 'dark' : 'light';
    store.settings.accent = palette;
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          key: UniqueKey(),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark, KAccentSpec.byId(palette)),
          home: home,
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: name);
    if (uiCaptureEnabled) {
      await saveUiPng(tester, root, name, pixelRatio: 1.5);
    }
  }

  const variants = [(true, 'bordeaux'), (false, 'violet')];
  String suffix(bool dark, String p) => '${p}_${dark ? 'sombre' : 'clair'}';

  testWidgets('remplaçants de Koach du dip lesté (J5) : libre et assisté', (
    tester,
  ) async {
    final base = store.program.week(15).day(5)!;
    await tester.runAsync(() async {
      await store.koachRefresh();
      store.adaptOpen(15, base);
    });
    final a = store.sessionAdapt(15, 5)!;
    final day = store.adaptDay(15, base, a);
    final dip = day.exercises.firstWhere(
      (e) => e.name.toUpperCase().startsWith('DIP LESTÉ'),
    );
    Widget page(bool free) => ReplaceExercisePage(
      fromName: store.splitName(dip.name).$1,
      free: free,
      options: (reason, missing) => store.dayReplaceOptions(
        15,
        day,
        dip,
        reason: reason,
        missing: missing,
      ),
      missingChoices: store.dayMissingChoices(15, 5, dip),
      departOf: (id) => store.dayDepartFor(15, day, dip, id),
      kgLabel: (kg) => store.massLabel(kg, engine: true),
    );
    for (final (dark, p) in variants) {
      store.setGuidanceMode('free');
      await show(tester, page(true), dark: dark, palette: p);
      expect(find.byKey(const ValueKey('replace-why')), findsOneWidget);
      await shot(tester, 'kb6_remplacer_libre_${suffix(dark, p)}');
      await tester.tap(
        find.byKey(const ValueKey('replace-why-pas_de_materiel')),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final belt = find.byKey(
        const ValueKey('replace-missing-ceinture de lest'),
      );
      expect(belt, findsOneWidget);
      await tester.tap(belt);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('replace-group-sans_materiel')),
        findsOneWidget,
      );
      await shot(tester, 'kb6_remplacer_ceinture_${suffix(dark, p)}');
      store.setGuidanceMode('assisted');
      await show(tester, page(false), dark: dark, palette: p);
      expect(find.byKey(const ValueKey('replace-free-hint')), findsOneWidget);
      await shot(tester, 'kb6_remplacer_assiste_${suffix(dark, p)}');
    }
  });

  testWidgets('carte du bilan du jour (libre) : forme du jour notée', (
    tester,
  ) async {
    store.setGuidanceMode('free');
    int? jour;
    for (var j = 1; j <= 6 && jour == null; j++) {
      final base = store.program.week(15).day(j);
      if (base == null || base.exercises.isEmpty) continue;
      if (store.sessionAdapt(15, j)?.koach?['state'] == 'open') continue;
      clock = DateTime(2026, 10, 18 + j, 7);
      await tester.runAsync(() async {
        await store.koachRefresh();
        store.adaptOpen(15, base);
        store.adaptAnswer(
          15,
          base,
          const kc.HealthCheck(overall: 1, sleepQuality: 1, energy: 1),
        );
        await store.koachStart(15, base);
      });
      if (store.koachBilan(15, j) != null) jour = j;
    }
    expect(jour, isNotNull, reason: 'aucune ligne changée par le bilan bas');
    for (final (dark, p) in variants) {
      await show(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              KoachBilanCard(
                week: 15,
                day: store.program.week(15).day(jour!)!,
                onChanged: () {},
              ),
            ],
          ),
        ),
        dark: dark,
        palette: p,
        height: 460,
      );
      expect(
        find.byKey(const ValueKey('koach-bilan-forme-notee')),
        findsOneWidget,
      );
      await shot(tester, 'kb6_bilan_libre_${suffix(dark, p)}');
    }
  });
}
