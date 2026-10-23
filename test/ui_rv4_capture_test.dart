// RV4 (dev7.7.2, C17.51.5, C17.52.4) — rendus de test : écran « Remplacer
// pour aujourd'hui » (mode libre : recherche « hspu mur » ; mode assisté :
// propositions et ligne du choix libre) et carte du bilan du jour sous
// Koach (mode libre : proposé, « Accepter » / « Garder l'écrit » ; mode
// assisté : appliqué, « Annuler ») ; sombre et clair × `bordeaux` et
// `violet`, 390 dp. Lancé par la CI avec --dart-define=KALIS_CAPTURE=true ;
// fichiers validation/UI/rv4_<état>_<palette>_<thème>.png. Données
// synthétiques (programme PR2), bilan bas 1/1/1.
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
  var clock = DateTime(2026, 10, 19, 7); // lundi, S15·J1

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
    double height = 640,
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

  testWidgets('écran « Remplacer pour aujourd’hui » : libre et assisté', (
    tester,
  ) async {
    const proposals = ['sl-dips-leste', 'sl-dips-banc-leste', 'pc-pompes'];
    for (final (dark, p) in variants) {
      await show(
        tester,
        const ReplaceExercisePage(
          fromName: 'DIP LESTÉ',
          proposals: proposals,
          free: true,
        ),
        dark: dark,
        palette: p,
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('replace-search')),
          matching: find.byType(EditableText),
        ),
        'hspu mur',
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('replace-cd-hspu-mur-dos')),
        findsOneWidget,
      );
      await shot(tester, 'rv4_remplacer_libre_${suffix(dark, p)}');
      await show(
        tester,
        const ReplaceExercisePage(
          fromName: 'DIP LESTÉ',
          proposals: proposals,
          free: false,
        ),
        dark: dark,
        palette: p,
      );
      expect(find.byKey(const ValueKey('replace-free-hint')), findsOneWidget);
      await shot(tester, 'rv4_remplacer_assiste_${suffix(dark, p)}');
    }
  });

  testWidgets('carte du bilan du jour : libre (proposé), assisté (appliqué)', (
    tester,
  ) async {
    /// Premier jour de S15 (à partir de [from]) où le bilan bas change une
    /// ligne ; null : aucun.
    Future<int?> servir(int from) async {
      for (var j = from; j <= 6; j++) {
        final base = store.program.week(15).day(j);
        if (base == null || base.exercises.isEmpty) continue;
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
        if (store.koachBilan(15, j) != null) return j;
      }
      return null;
    }

    Widget card(int j) => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          KoachBilanCard(
            week: 15,
            day: store.program.week(15).day(j)!,
            onChanged: () {},
          ),
        ],
      ),
    );

    store.setGuidanceMode('free');
    final j1 = await servir(1);
    expect(j1, isNotNull, reason: 'aucune ligne changée par le bilan bas');
    for (final (dark, p) in variants) {
      await show(tester, card(j1!), dark: dark, palette: p, height: 420);
      expect(
        find.byKey(const ValueKey('koach-bilan-accept-jour')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('koach-bilan-keep-jour')),
        findsOneWidget,
      );
      await shot(tester, 'rv4_bilan_libre_${suffix(dark, p)}');
    }
    store.setGuidanceMode('assisted');
    final j2 = await servir(j1! + 1);
    if (j2 != null) {
      for (final (dark, p) in variants) {
        await show(tester, card(j2), dark: dark, palette: p, height: 420);
        expect(
          find.byKey(const ValueKey('koach-bilan-undo-jour')),
          findsOneWidget,
        );
        await shot(tester, 'rv4_bilan_assiste_${suffix(dark, p)}');
      }
    }
  });
}
