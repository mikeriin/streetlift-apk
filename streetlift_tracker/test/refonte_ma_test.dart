// Refonte muscles et animations — illustrations anatomiques (face / dos de
// 3.1.0, profil ajouté), calques de groupes, démonstrations découpées.
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
import 'package:streetlift_tracker/pose_cutout.dart';
import 'package:streetlift_tracker/pose_engine.dart';
import 'package:streetlift_tracker/pose_painter.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/muscle_body_310.dart';

Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

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
  final poses = _gz('assets/content/poses.json.gz');
  final gabarits = poses['gabarits'] as Map<String, dynamic>;
  final exercices = poses['exercices'] as Map<String, dynamic>;

  PoseAnimation animationOf(String id) {
    final e = exercices[id] as Map<String, dynamic>;
    return PoseAnimation.fromPack(
      gabarits[e['gabarit']] as Map<String, dynamic>,
      e,
    );
  }

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
                      child:
                          variant == 0
                              ? MuscleHeatmap(
                                data: data,
                                height: 320,
                                glow: glow,
                              )
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

  group('démonstrations découpées', () {
    test('choix de la vue : profil, face ou dos selon les muscles', () {
      var profil = 0, face = 0, dos = 0;
      for (final id in exercices.keys) {
        if (gabarits[(exercices[id] as Map)['gabarit']] == null) continue;
        final a = animationOf(id);
        final v = cutoutViewOf(a);
        if (!a.isFace) {
          expect(v, 'profil', reason: id);
          profil++;
        } else {
          expect(v, anyOf('face', 'dos'), reason: id);
          v == 'dos' ? dos++ : face++;
        }
      }
      expect(profil, greaterThan(500));
      expect(face + dos, 23);
      // exemples réels : côté des muscles principaux
      expect(cutoutViewOf(animationOf('side-bend-haltere')), 'dos');
      expect(cutoutViewOf(animationOf('jumping-jacks')), 'face');
      expect(cutoutViewOf(animationOf('human-flag-drapeau')), 'face');
      expect(dos, greaterThan(0));
      // principaux postérieurs (grand dorsal) → dos ; obliques → face
      expect(
        cutoutViewOf(
          const PoseAnimation(
            view: 'face',
            loop: 'cycle',
            keyframes: [],
            props: [],
            primaires: ['grand_dorsal', 'oblique_externe', 'trapeze_moyen'],
          ),
        ),
        'dos',
      );
      expect(
        cutoutViewOf(
          const PoseAnimation(
            view: 'face',
            loop: 'cycle',
            keyframes: [],
            props: [],
            primaires: ['oblique_externe', 'droit_abdomen'],
          ),
        ),
        'face',
      );
    });

    test('segments posés exactement sur les articulations du modèle', () async {
      for (final view in const ['face', 'dos', 'profil']) {
        final sprites = await CutoutSprites.load(view, bundle: _FileBundle());
        final ref = sprites.rig.joints;
        final k = 1 / sprites.pixelsPerUnit;
        final id =
            view == 'profil' ? 'squat-au-poids-de-corps' : 'jumping-jacks';
        final anim = animationOf(id);
        final j = poseJointsAt(anim, poseDuration(anim) * .37);
        final placed = {
          for (final p in cutoutLayout(sprites.rig, k, j))
            '${p.name}${p.far ? '*' : ''}': p.toModel,
        };
        void near(ui.Offset a, ui.Offset b, String why) =>
            expect((a - b).distance, lessThan(1e-9), reason: why);
        if (view == 'profil') {
          for (final (s, key) in const [('d', ''), ('g', '*')]) {
            near(
              placed['avant_bras$key']!.apply(ref['coude']!),
              j['coude_$s']!,
              'coude',
            );
            near(
              placed['avant_bras$key']!.apply(ref['poignet']!),
              j['poignet_$s']!,
              'poignet',
            );
            near(
              placed['main$key']!.apply(ref['poignet']!),
              j['poignet_$s']!,
              'main',
            );
            near(
              placed['jambe$key']!.apply(ref['genou']!),
              j['genou_$s']!,
              'genou',
            );
            near(
              placed['jambe$key']!.apply(ref['cheville']!),
              j['cheville_$s']!,
              'cheville',
            );
            near(
              placed['pied$key']!.apply(ref['cheville']!),
              j['cheville_$s']!,
              'pied',
            );
            near(
              placed['cuisse$key']!.apply(ref['genou']!),
              j['genou_$s']!,
              'cuisse',
            );
            near(
              placed['bras$key']!.apply(ref['coude']!),
              j['coude_$s']!,
              'bras',
            );
          }
          near(placed['tronc']!.apply(ref['bassin']!), j['bassin']!, 'bassin');
          near(placed['tronc']!.apply(ref['cou']!), j['cou']!, 'cou');
        } else {
          for (final s in const ['g', 'd']) {
            near(
              placed['avant_bras_$s']!.apply(ref['poignet_$s']!),
              j['poignet_$s']!,
              'poignet',
            );
            near(
              placed['main_$s']!.apply(ref['poignet_$s']!),
              j['poignet_$s']!,
              'main',
            );
            near(
              placed['jambe_$s']!.apply(ref['cheville_$s']!),
              j['cheville_$s']!,
              'cheville',
            );
            near(
              placed['cuisse_$s']!.apply(ref['genou_$s']!),
              j['genou_$s']!,
              'genou',
            );
            near(
              placed['bras_$s']!.apply(ref['coude_$s']!),
              j['coude_$s']!,
              'coude',
            );
          }
          near(placed['tronc']!.apply(ref['cou']!), j['cou']!, 'cou');
        }
      }
    });

    test('rendu sans exception de chaque animation, corps dessiné', () async {
      final sprites = {
        for (final v in const ['face', 'dos', 'profil'])
          v: await CutoutSprites.load(v, bundle: _FileBundle()),
      };
      final roles = PoseRoles.of(KAccentSpec.rouge, true);
      var n = 0;
      for (final e in exercices.entries) {
        if ((e.value as Map)['statut'] == 'indisponible') continue;
        final anim = animationOf(e.key);
        final vb = poseBBox(anim);
        final d = poseDuration(anim);
        for (final f in const [0.0, .3, .6]) {
          final recorder = ui.PictureRecorder();
          PosePainter(
            pose: anim,
            joints: poseJointsAt(anim, f * d),
            viewBox: vb,
            roles: roles,
            sprites: sprites[cutoutViewOf(anim)],
          ).paint(Canvas(recorder), const Size(160, 160));
          recorder.endRecording().dispose();
        }
        n++;
      }
      expect(n, greaterThan(600));
      // une image : le corps occupe des pixels de l'illustration
      final anim = animationOf('pompes');
      final recorder = ui.PictureRecorder();
      PosePainter(
        pose: anim,
        joints: poseJointsAt(anim, 0),
        viewBox: poseBBox(anim),
        roles: roles,
        background: true,
        sprites: sprites['profil'],
      ).paint(Canvas(recorder), const Size(240, 240));
      final image = await recorder.endRecording().toImage(240, 240);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      image.dispose();
      var body = 0;
      for (var i = 0; i < bytes.lengthInBytes; i += 4) {
        final r = bytes.getUint8(i), g = bytes.getUint8(i + 1);
        final b = bytes.getUint8(i + 2);
        // gris de l'illustration (hors fond noir et hors rouge)
        if (r > 60 && (r - g).abs() < 6 && (g - b).abs() < 6 && r < 200) {
          body++;
        }
      }
      expect(body, greaterThan(300));
    });

    test('coût : images par seconde (test) et mémoire des textures', () async {
      final sprites = {
        for (final v in const ['face', 'dos', 'profil'])
          v: await CutoutSprites.load(v, bundle: _FileBundle()),
      };
      final memory = sprites.values.fold<int>(0, (s, x) => s + x.textureBytes);
      final roles = PoseRoles.of(KAccentSpec.rouge, true);
      final watch = Stopwatch()..start();
      var frames = 0;
      for (final id in const [
        'pompes',
        'squat-au-poids-de-corps',
        'jumping-jacks',
        'muscle-up',
      ]) {
        if (!exercices.containsKey(id)) continue;
        final anim = animationOf(id);
        final vb = poseBBox(anim);
        final d = poseDuration(anim);
        for (var i = 0; i < 60; i++) {
          final recorder = ui.PictureRecorder();
          PosePainter(
            pose: anim,
            joints: poseJointsAt(anim, d * i / 60),
            viewBox: vb,
            roles: roles,
            sprites: sprites[cutoutViewOf(anim)],
          ).paint(Canvas(recorder), const Size(360, 220));
          final picture = recorder.endRecording();
          final image = await picture.toImage(360, 220);
          image.dispose();
          picture.dispose();
          frames++;
        }
      }
      watch.stop();
      final perFrame = watch.elapsedMicroseconds / frames;
      // ignore: avoid_print
      print(
        'REFONTE_PERF images=$frames moyenne_us=${perFrame.toStringAsFixed(0)} '
        'ips=${(1e6 / perFrame).toStringAsFixed(0)} '
        'textures_octets=$memory',
      );
      expect(frames, greaterThanOrEqualTo(180));
      // garde-fou large (machine de CI, rendu logiciel) : ≥ 30 images/s
      expect(perFrame, lessThan(33000));
      // les trois vues décodées tiennent sous 16 Mo
      expect(memory, lessThan(16 * 1024 * 1024));
    });
  });
}

/// Lecture des assets depuis le disque (tests unitaires hors widgets).
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}
