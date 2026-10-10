// UI0 (refonte UI) — captures des composants du kit (PIPELINE_UI.md §3) :
// chaque section du catalogue en sombre et clair, palettes `bordeaux` et
// `neon` ; jetons et sélecteur dans les 8 palettes et en contraste renforcé ;
// sections denses à 320 dp et 200 % de texte. Lancé par la CI avec
// --dart-define=KALIS_CAPTURE=true ; fichiers validation/UI/ui0_*.png,
// recopiés dans ci-out/captures-ui/.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/kit/catalog.dart';
import 'package:streetlift_tracker/kit/kit.dart';

import 'support/ui_capture.dart';

void main() {
  final root = GlobalKey();

  Future<void> capture(
    WidgetTester tester,
    KitSample s,
    String name, {
    required bool dark,
    required String palette,
    bool contrast = false,
    double width = 360,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kitTheme(dark: dark, paletteId: palette, contrast: contrast),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  child: RepaintBoundary(key: root, child: KitSampleView(s)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: name);
    await saveUiPng(tester, root, name);
  }

  setUpAll(loadUiFonts);

  testWidgets('kit : sections × sombre, clair × bordeaux, neon', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final s in kitSamples) {
      for (final palette in ['bordeaux', 'neon']) {
        for (final dark in [true, false]) {
          await capture(
            tester,
            s,
            'ui0_${s.id}_${palette}_${dark ? 'sombre' : 'clair'}',
            dark: dark,
            palette: palette,
          );
        }
      }
    }
  }, skip: !uiCaptureEnabled);

  testWidgets(
    'kit : jetons et palette dans les 8 palettes, contraste renforcé',
    (tester) async {
      addTearDown(tester.view.reset);
      final tokens = kitSamples.firstWhere((s) => s.id == 'jetons');
      final picker = kitSamples.firstWhere((s) => s.id == 'palettes');
      for (final p in kPaletteSources) {
        for (final dark in [true, false]) {
          final mode = dark ? 'sombre' : 'clair';
          await capture(
            tester,
            tokens,
            'ui0_8p_jetons_${p.id}_$mode',
            dark: dark,
            palette: p.id,
          );
          await capture(
            tester,
            picker,
            'ui0_8p_palette_${p.id}_$mode',
            dark: dark,
            palette: p.id,
          );
          await capture(
            tester,
            tokens,
            'ui0_8p_jetons_${p.id}_${mode}_renforce',
            dark: dark,
            palette: p.id,
            contrast: true,
          );
        }
      }
    },
    skip: !uiCaptureEnabled,
  );

  testWidgets('kit : 320 dp et 200 % de texte', (tester) async {
    addTearDown(tester.view.reset);
    for (final s in kitSamples) {
      if (s.id == 'jetons' || s.id == 'typo') continue;
      await capture(
        tester,
        s,
        'ui0_320_${s.id}_bordeaux_sombre',
        dark: true,
        palette: 'bordeaux',
        width: 320,
        scale: 2,
      );
    }
  }, skip: !uiCaptureEnabled);
}
