// M2 (CI 3D) : mesure des deux organisations du modèle anatomique sur
// émulateur Android (Flutter GPU), lancée après moteur_3d_test.dart par
// tools/ci3d_drive.sh (cible séparée : un plantage de la mesure ne fait pas
// perdre les captures du premier passage). Relevé m2_mesure.json et deux
// captures (même vue, même caméra), écrits par le pilote dans build/ci3d/.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Material;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/main.dart' show SL, buildTheme;
import 'package:streetlift_tracker/mannequin_3d.dart';

final _root = GlobalKey();

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m2 = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m2_mesure.json'] = const JsonEncoder.withIndent('  ').convert(m2);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  // Organisation du modèle : (a) une maille par muscle et par côté (modèle
  // livré) ou (b) maillage fusionné, identifiant de muscle par sommet
  // (couleur de sommet ; mesure du coût des appels de dessin, le matériau
  // .fmat n'est construit que si (b) l'emporte). Même scène, même caméra en
  // rotation, 12 s chacune ; temps de construction (UI) et de rendu (GPU).
  Future<Map<String, Object?>> measure(WidgetTester tester, bool merged) async {
    final ms = await MannequinScene.create();
    final demo = ms.map.fromGroups(const {
      'dos': 1,
      'biceps': .62,
      'avant-bras': .35,
    });
    ms.configure(dark: true, intensities: demo, bones: true, halo: true);
    var draws = 0;
    if (merged) {
      final parts = <MeshData>[];
      void visit(Node n) {
        for (final c in [...n.children]) {
          visit(c);
        }
        final r = ms.map.byId[n.name];
        if (r == null || r.couche == 'volume' || n.mesh == null) return;
        final d = n.extractMeshData(transform: n.globalTransform);
        final v = demo[n.name] ?? 0;
        final c = v > 0 ? mannequinHeat(v, true) : kMuscleGray;
        double lin(double x) => x <= .04045
            ? x / 12.92
            : math.pow((x + .055) / 1.055, 2.4).toDouble();
        final colors = Float32List(d.vertexCount * 4);
        for (var i = 0; i < d.vertexCount; i++) {
          colors[i * 4] = lin(c.r);
          colors[i * 4 + 1] = lin(c.g);
          colors[i * 4 + 2] = lin(c.b);
          colors[i * 4 + 3] = 1;
        }
        parts.add(
          MeshData(
            positions: d.positions,
            vertexCount: d.vertexCount,
            normals: d.normals,
            colors: colors,
            indices: d.indices,
          ),
        );
        n.visible = false;
      }

      visit(ms.model);
      final material = PhysicallyBasedMaterial()
        ..metallicFactor = 0
        ..roughnessFactor = .78;
      ms.scene.add(
        Node(
          name: 'fusion',
          mesh: Mesh(
            MeshGeometry.fromMeshData(MeshData.merge(parts)),
            material,
          ),
        ),
      );
    }
    void count(Node n) {
      if (!n.visible) return;
      draws += n.mesh?.primitives.length ?? 0;
      for (final c in n.children) {
        count(c);
      }
    }

    count(ms.scene.root);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(true),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: const ValueKey('mesure-vue'),
                width: 360,
                height: 640,
                child: SceneView(
                  ms.scene,
                  autoTick: true,
                  cameraBuilder: (e) => ms.camera(
                    e.inMicroseconds / 1e6 * .45,
                    .06,
                    ms.fitDistance(360 / 640),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await shot('m2_organisation_${merged ? 'b_fusion' : 'a_par_muscle'}');
    final timings = <FrameTiming>[];
    var first = true;
    void onTimings(List<FrameTiming> t) {
      if (first) {
        first = false;
        return;
      }
      timings.addAll(t);
    }

    SchedulerBinding.instance.addTimingsCallback(onTimings);
    for (var i = 0; i < 12 * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(seconds: 2));
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
    double mean(List<double> v) =>
        v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
    final build = [
      for (final t in timings) t.buildDuration.inMicroseconds / 1000,
    ];
    final raster = [
      for (final t in timings) t.rasterDuration.inMicroseconds / 1000,
    ];
    final stats = FrameStats.fromTimings(timings, const Duration(seconds: 12));
    return {
      'appels_de_dessin': draws,
      'images': stats.frames,
      'images_par_s': stats.fps,
      'temps_moyen_ms': stats.meanMs,
      'p99_ms': stats.p99Ms,
      'construction_ui_moyenne_ms': mean(build),
      'rendu_gpu_moyen_ms': mean(raster),
    };
  }

  testWidgets('M2 : organisation du modèle, (a) par muscle / (b) fusionné', (
    tester,
  ) async {
    SL.dark = true;
    final support = await engine3DSupport();
    expect(support.compatible, isTrue, reason: '${support.error}');
    final a = await measure(tester, false);
    m2['organisation_a_par_muscle'] = a;
    record();
    final b = await measure(tester, true);
    m2['organisation_b_fusion'] = b;
    record();
    expect(
      a['appels_de_dessin'] as int,
      greaterThan(b['appels_de_dessin'] as int),
    );
  });
}
