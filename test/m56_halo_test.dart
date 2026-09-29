// 5.5.4 (M56 correction 4) : halo des muscles sollicités dessiné par-dessus
// la vue — projection écran étalonnée sur les rayons de la caméra (mêmes
// repères que le toucher), silhouette des triangles tournés vers la caméra.
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_gestures.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  const size = Size(360, 480);
  final camera = PerspectiveCamera(
    fovRadiansY: kMannequinFovY,
    position: vm.Vector3(.4, 1.2, 3),
    target: vm.Vector3(0, .9, 0),
  );

  test('projection : le rayon du point écran repasse par le point', () {
    final proj = HaloProjection.of(camera, size)!;
    for (final p in [
      vm.Vector3(0, .9, 0),
      vm.Vector3(.3, 1.4, .1),
      vm.Vector3(-.25, .3, -.2),
    ]) {
      final s = proj.project(p.x, p.y, p.z)!;
      final ray = camera.screenPointToRay(s, size);
      final d = (p - ray.origin)..normalize();
      expect(d.dot(ray.direction.normalized()), closeTo(1, 1e-4), reason: '$p');
    }
    // Derrière la caméra : rien.
    expect(proj.project(0, 1, 6), isNull);
  });

  test('silhouette : triangle tourné vers la caméra seulement', () {
    final proj = HaloProjection.of(camera, size)!;
    // Triangle dans le plan z = 0, sens direct vu de +z (vers la caméra).
    final p = Float32List.fromList([-.1, .8, 0, .1, .8, 0, 0, 1, 0]);
    const front = [0, 1, 2], back = [0, 2, 1];
    expect(proj.silhouette(p, front), isNotNull);
    expect(proj.silhouette(p, back), isNull);
    expect(proj.silhouette(p, back, outward: false), isNotNull);
    final bounds = proj.silhouette(p, front)!.getBounds();
    expect(bounds.width, greaterThan(5));
    expect(bounds.center.dx, closeTo(size.width / 2, 60));
  });

  test('opacité du halo croît avec l’intensité', () {
    expect(MannequinHaloPainter.alphaFor(0), lessThan(.2));
    expect(
      MannequinHaloPainter.alphaFor(1),
      greaterThan(MannequinHaloPainter.alphaFor(.35)),
    );
    expect(MannequinHaloPainter.alphaFor(1), lessThanOrEqualTo(.5));
  });
}
