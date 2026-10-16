// Refonte muscles et animations — illustrations anatomiques (face / dos de
// 3.1.0, profil ajouté), calques de groupes (BV11 : démonstrations découpées de l'ancien pack
// retirées avec lui).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/muscle_body_310.dart';

/// Image PNG décodée : largeur, hauteur, octets RGBA.
Future<(int, int, Uint8List)> _png(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final out = (image.width, image.height, data!.buffer.asUint8List());
  image.dispose();
  codec.dispose();
  return out;
}

const _fileKeys = {
  'pectoraux': 'pectoraux',
  'épaules': 'epaules',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'avant-bras': 'avant_bras',
  'gainage': 'gainage',
  'dos': 'dos',
  'quadriceps': 'quadriceps',
  'ischios': 'ischios',
  'fessiers': 'fessiers',
  'mollets': 'mollets',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('illustrations et calques', () {
    test('18 PNG de 3.1.0 restaurés à l\'identique, profil ajouté', () {
      final meta =
          jsonDecode(File('assets/muscles/meta.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(meta['front'], {'w': 281, 'h': 760});
      expect(meta['back'], {'w': 283, 'h': 760});
      expect((meta['profile'] as Map)['h'], 760);
      for (final view in const ['front', 'back', 'profile']) {
        expect(File('assets/muscles/${view}_base.png').existsSync(), isTrue);
        for (final g in muscleMasks[view]!) {
          expect(
            File('assets/muscles/${view}_${_fileKeys[g]}.png').existsSync(),
            isTrue,
            reason: '$view $g',
          );
        }
      }
      // les 11 groupes ont un calque de profil
      expect(muscleMasks['profile'], containsAll(AppStore.muscleGroups));
    });

    test(
      'calques alignés au pixel sur leur illustration, dans la silhouette',
      () async {
        for (final view in const ['front', 'back', 'profile']) {
          final base = await _png('assets/muscles/${view}_base.png');
          for (final g in muscleMasks[view]!) {
            final path = 'assets/muscles/${view}_${_fileKeys[g]}.png';
            final layer = await _png(path);
            expect((layer.$1, layer.$2), (base.$1, base.$2), reason: path);
            var inside = 0, outside = 0;
            for (var i = 3; i < layer.$3.length; i += 4) {
              final a = layer.$3[i];
              if (a < 128) continue;
              if (base.$3[i] >= 128) {
                inside++;
              } else {
                outside++;
              }
            }
            expect(inside, greaterThan(500), reason: path);
            // calque dans la silhouette (tolérance d'anticrénelage)
            expect(outside, lessThan(inside ~/ 200 + 5), reason: path);
          }
        }
      },
    );

    test('profil : fond transparent, bords sans liseré clair', () async {
      final (w, h, px) = await _png('assets/muscles/profile_base.png');
      expect(h, 760);
      int alpha(int x, int y) => px[(y * w + x) * 4 + 3];
      for (final (x, y) in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]) {
        expect(alpha(x, y), 0);
      }
      // pixels de bord (alpha partiel franc) : sombres comme le contour de la
      // face ; un liseré clair (fond blanc mal détouré) serait > 110
      var edge = 0, light = 0, opaque = 0;
      for (var i = 0; i < px.length; i += 4) {
        final a = px[i + 3];
        if (a == 255) opaque++;
        if (a <= 16 || a >= 200) continue;
        edge++;
        if (px[i] > 110) light++;
      }
      expect(opaque, greaterThan(40000));
      expect(edge, greaterThan(100));
      expect(light, lessThan(edge ~/ 100 + 1));
    });
  });

  group('carte musculaire', () {
    test('muscles de l\'atlas → groupes, intensités par rôle', () {
      for (final m in atlasMuscles.values) {
        expect(AppStore.muscleGroups, contains(m.groupe));
      }
      final t = exerciseGroupIntensities(
        primaires: ['grand_dorsal'],
        secondaires: ['biceps_chef_long', 'grand_dorsal'],
        stabilisateurs: ['droit_abdomen'],
        etires: ['grand_pectoral_sterno_costal', 'droit_abdomen'],
      );
      expect(t, {'dos': 1.0, 'biceps': .62, 'gainage': .35, 'pectoraux': .25});
      expect(
        const ExerciseAtlas(primaires: ['grand_dorsal']).groupIntensities,
        {'dos': 1.0},
      );
    });

    for (final dark in const [true, false]) {
      testWidgets(
        'STATS : rendu identique à 3.1.0 (${dark ? 'sombre' : 'clair'})',
        (tester) async {
          SL.dark = dark;
          addTearDown(() => SL.dark = true);
          const data = {
            'dos': 14.0,
            'biceps': 9.0,
            'pectoraux': 10.0,
            'triceps': 8.0,
            'épaules': 7.0,
            'quadriceps': 6.0,
            'gainage': 5.0,
            'avant-bras': 4.0,
            'ischios': 3.0,
            'fessiers': 3.0,
            'mollets': 1.0,
          };
          final images = <Uint8List>[];
          for (final variant in [0, 1]) {
            for (final glow in [false, true]) {
              final key = GlobalKey();
              tester.view.physicalSize = const Size(390, 340);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              await tester.pumpWidget(
                MaterialApp(
                  theme: buildTheme(dark),
                  home: Scaffold(
                    body: RepaintBoundary(
                      key: key,
                      child: variant == 0
                          ? MuscleHeatmap(data: data, height: 320, glow: glow)
                          : MuscleHeatmap310(
                              data: data,
                              height: 320,
                              glow: glow,
                            ),
                    ),
                  ),
                ),
              );
              await tester.runAsync(() async {
                final ctx = tester.element(find.byType(Scaffold));
                for (final f in Directory('assets/muscles').listSync()) {
                  if (f.path.endsWith('.png')) {
                    await precacheImage(AssetImage(f.path), ctx);
                  }
                }
              });
              await tester.pump();
              final render =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await render.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.rawRgba,
                );
                images.add(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
          }
          // mêmes pixels, avec et sans halo ; et le rendu n'est pas vide
          expect(images[0], images[2]);
          expect(images[1], images[3]);
          expect(images[0].toSet().length, greaterThan(20));
        },
      );
    }
  });
}
