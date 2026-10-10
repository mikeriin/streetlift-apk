// M1 (CI 3D) : rendu réel de l'écran « Moteur 3D » sur émulateur Android
// (Flutter GPU / Impeller), lancé par .github/workflows/ci-3d.yml :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/moteur_3d_test.dart -d emulator-5554
// Captures PNG (application entière, thème sombre et clair) et relevé JSON
// (compatibilité, API graphique, images/s, temps d'image) écrits par le
// pilote dans build/ci3d/. Méthode documentée dans docs/CI_3D.md.
// M2 → M8 (5.9.0) : l'écran Anatomie montre la carte 2D des groupes (plus
// de 3D) : sa partie est retirée d'ici (carte 2D : carte_2d_m8_test.dart).
// La mesure des deux organisations du modèle est dans
// mannequin_mesure_test.dart.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Images réelles produites par le moteur (ticker du rendu 3D, mesure).
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final report = <String, Object?>{};
  binding.reportData = data;

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: _ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  /// Contrôle sans référence du rendu 3D : la figure couvre le centre, le
  /// gris et le rouge historique sont présents, l'image n'est pas uniforme.
  Future<Map<String, Object?>> sceneStats(
    WidgetTester tester,
    bool dark, {
    Key key = const ValueKey('engine3d-view'),
  }) async {
    final rect = tester.getRect(find.byKey(key).first);
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = sceneBackground(dark);
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    var total = 0, figure = 0, red = 0, gray = 0;
    final colors = <int>{};
    final left = (rect.left * _ratio).round(),
        top = (rect.top * _ratio).round();
    final right = (rect.right * _ratio).round();
    final bottom = (rect.bottom * _ratio).round();
    for (var y = top; y < bottom; y += 2) {
      for (var x = left; x < right; x += 2) {
        final o = (y * image.width + x) * 4;
        final r = rgba.getUint8(o), g = rgba.getUint8(o + 1);
        final b = rgba.getUint8(o + 2);
        total++;
        colors.add((r >> 3) << 10 | (g >> 3) << 5 | (b >> 3));
        final diff = [(r - br).abs(), (g - bgG).abs(), (b - bb).abs()];
        if (diff.reduce((a, c) => a > c ? a : c) <= 12) continue;
        figure++;
        if (r > 110 && r > g + 50 && r > b + 50) red++;
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 40) gray++;
      }
    }
    image.dispose();
    return {
      'pixels': total,
      'figure': figure / total,
      'rouge': red / total,
      'gris': gray / total,
      'couleurs': colors.length,
    };
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() done, {
    int seconds = 30,
  }) async {
    for (var i = 0; i < seconds * 10 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Engine3DScreenState screen(WidgetTester tester) =>
      tester.state<Engine3DScreenState>(find.byType(Engine3DScreen));

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  Future<void> openApp(WidgetTester tester, String theme) async {
    store.settings
      ..theme = theme
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    await tester.pumpWidget(RepaintBoundary(key: _root, child: const SLApp()));
    await tester.pumpAndSettle();
  }

  void check(Map<String, Object?> stats, String label) {
    expect(
      stats['figure'] as double,
      greaterThan(.08),
      reason: '$label : la figure ne couvre pas la vue (rendu vide ?)',
    );
    expect(
      stats['rouge'] as double,
      greaterThan(.004),
      reason: '$label : calotte rouge absente',
    );
    expect(
      stats['gris'] as double,
      greaterThan(.03),
      reason: '$label : musculature grise absente',
    );
    expect(stats['couleurs'] as int, greaterThan(12), reason: label);
  }

  testWidgets('Réglages › Aide et à propos › Diagnostic 3D, thème sombre', (
    tester,
  ) async {
    await openApp(tester, 'dark');
    appNavigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(page: SettingsPage.about),
      ),
    );
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('about-engine3d'));
    await tester.scrollUntilVisible(
      tile,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await shot('m1_1_reglages_a_propos');
    await tester.tap(tile);
    await waitFor(
      tester,
      () =>
          find.byType(Engine3DScreen).evaluate().isNotEmpty &&
          screen(tester).support != null,
    );
    final state = screen(tester);
    report['compatible'] = state.support?.compatible;
    report['erreur'] = state.support?.error;
    report['appareil'] = state.info.map((k, v) => MapEntry(k, '$v'));
    data['m1_releve.json'] = const JsonEncoder.withIndent('  ').convert(report);
    expect(
      state.support!.compatible,
      isTrue,
      reason: 'Flutter GPU indisponible : ${state.support!.error}',
    );
    // Laisse le premier rendu se stabiliser (compilation des shaders).
    await tester.pump(const Duration(seconds: 2));
    await shot('m1_2_moteur3d_sombre');
    final dark = await sceneStats(tester, true);
    report['rendu_sombre'] = dark;
    data['m1_releve.json'] = const JsonEncoder.withIndent('  ').convert(report);
    check(dark, 'sombre');

    // Rotation au doigt.
    await tester.timedDrag(
      find.byKey(const ValueKey('engine3d-view')),
      const Offset(-160, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await shot('m1_3_moteur3d_rotation');

    // Mesure automatique de 10 s.
    await waitFor(tester, () => screen(tester).stats != null, seconds: 45);
    final stats = screen(tester).stats;
    expect(stats, isNotNull, reason: 'mesure de fluidité non terminée');
    report['mesure'] = {
      'images': stats!.frames,
      'duree_ms': stats.window.inMilliseconds,
      'images_par_s': stats.fps,
      'temps_moyen_ms': stats.meanMs,
      'p99_ms': stats.p99Ms,
    };
    data['m1_releve.json'] = const JsonEncoder.withIndent('  ').convert(report);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('engine3d-perf')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await shot('m1_4_moteur3d_mesure');
    // Pas d'exigence sur le nombre d'images : l'émulateur rend en logiciel
    // (≈ 1 image/s, temps d'image livrés par lots rares en mode debug) ;
    // le relevé est consigné, la mesure qui compte est celle du téléphone.
  });

  testWidgets('Moteur 3D, thème clair', (tester) async {
    // Thème clair appliqué directement (le réglage de l'application est
    // couvert par les tests de thème) : même écran, fond de scène clair.
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(false),
          home: const Engine3DScreen(autoMeasure: false),
        ),
      ),
    );
    await waitFor(
      tester,
      () =>
          find.byType(Engine3DScreen).evaluate().isNotEmpty &&
          screen(tester).support != null,
    );
    await tester.pump(const Duration(seconds: 3));
    await shot('m1_5_moteur3d_clair');
    final light = await sceneStats(tester, false);
    report['rendu_clair'] = light;
    data['m1_releve.json'] = const JsonEncoder.withIndent('  ').convert(report);
    check(light, 'clair');
    expect(
      light['figure'] as double,
      lessThan(.7),
      reason: 'fond clair absent',
    );
  });
}
