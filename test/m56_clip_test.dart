// M56 (mannequin 3D, repris du brouillon M6) — animations d'exercice : lecture des clips
// (assets/anatomy/clips), interpolation de l'application (sphérique par os,
// os d'aide recalculés, translation linéaire) rejouée sur toute la boucle
// avec les contacts de la chaîne de calcul (mains sur la prise, pieds fixes,
// ≤ 1 cm), registre, phases et tempo ; fiche : animation 3D pour un
// exercice converti (repli 2D sans Flutter GPU), démonstration 2D sinon.
// Le rendu réel est vérifié sur émulateur (integration_test/animations_m56_test.dart).

import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_rig.dart';
import 'package:streetlift_tracker/pose_painter.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:vector_math/vector_math.dart' as vm;

const pilots = ['traction-pronation', 'dips', 'back-squat'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MannequinRig rig;
  final clips = <String, MannequinClip>{};
  final raw = <String, Map<String, dynamic>>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    rig = MannequinRig.fromJson(
      jsonDecode(await rootBundle.loadString(kRigAsset))
          as Map<String, dynamic>,
    );
    for (final id in pilots) {
      final data = await rootBundle.load(clipAsset(id));
      final bytes = data.buffer.asUint8List();
      clips[id] = MannequinClip.fromGzip(bytes);
      raw[id] =
          jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
    }
    await engine3DSupport();
    await MannequinMap.load();
  });

  test('registre : les trois pilotes sont validés', () async {
    final valid = ClipRegistry.parse(
      await rootBundle.loadString(kClipIndexAsset),
    );
    expect(valid, containsAll(pilots));
  });

  test('clips : vue du plan sagittal, tempo, phases complètes', () {
    for (final id in pilots) {
      final c = clips[id]!;
      expect(c.plane, 'sagittal', reason: id);
      // Plan sagittal → profil, sauf vue imposée par la fiche (M56 : back
      // squat en 3/4, le disque cachant le tronc de profil).
      expect(c.view, id == 'back-squat' ? 'troisQuarts' : 'profil', reason: id);
      expect(c.tempo, matches(RegExp(r'^\d-\d-\d-\d$')), reason: id);
      expect(c.phases.first.start, 0);
      expect(c.phases.last.end, closeTo(c.duration, 1e-9));
      final types = {for (final p in c.phases) p.type};
      expect(
        types,
        containsAll([
          ClipPhaseType.concentrique,
          ClipPhaseType.excentrique,
          ClipPhaseType.isometrique,
        ]),
        reason: id,
      );
      expect(c.keyPositions, isNotEmpty);
      // Correction 1 : positions de départ et de fin montrées par la fiche.
      expect([for (final p in c.shownPositions) p.name], ['Départ', 'Fin']);
      for (final p in c.shownPositions) {
        expect(p.time, inInclusiveRange(0, c.duration));
      }
      expect(c.equipment.map((e) => e.id), contains('sol'));
      expect(c.height, greaterThan(1.0));
      // La boucle revient à sa posture de départ.
      expect(c.timeline.last.$2, c.timeline.first.$2);
    }
    expect(
      clips['back-squat']!.equipment.firstWhere((e) => e.moving).id,
      'barre_olympique',
    );
  });

  test('interpolation de l\'application : contacts tenus à 1 cm sur toute la '
      'boucle (400 instants)', () {
    for (final id in pilots) {
      final c = clips[id]!;
      final contacts = raw[id]!['contacts'] as List;
      var worst = 0.0;
      for (var k = 0; k < 400; k++) {
        final t = c.duration * k / 400;
        final pose = c.poseAt(t, rig);
        final g = rig.globals(pose);
        final moving = c.equipmentAt(t);
        for (final ct in contacts) {
          final bone = rig.index[ct['os'] as String]!;
          final p = ct['point'] as List;
          final world = g[bone].transformed3(
            vm.Vector3(
              (p[0] as num).toDouble(),
              (p[1] as num).toDouble(),
              (p[2] as num).toDouble(),
            ),
          );
          final vm.Vector3 target;
          if (ct['cible'] case final List cible) {
            target = vm.Vector3(
              (cible[0] as num).toDouble(),
              (cible[1] as num).toDouble(),
              (cible[2] as num).toDouble(),
            );
          } else {
            final off = ct['decalage'] as List;
            target =
                moving[ct['element'] as String]! +
                vm.Vector3(
                  (off[0] as num).toDouble(),
                  (off[1] as num).toDouble(),
                  (off[2] as num).toDouble(),
                );
          }
          final e = (world - target).length;
          if (e > worst) worst = e;
        }
      }
      expect(
        worst,
        lessThanOrEqualTo(.0101),
        reason: '$id : ${worst * 100} cm',
      );
    }
  });

  test('temps : boucle, segments, phases', () {
    final c = clips['traction-pronation']!;
    expect(c.wrap(c.duration + 1), closeTo(1, 1e-9));
    expect(c.wrap(-1), closeTo(c.duration - 1, 1e-9));
    expect(c.phaseAt(.1).type, ClipPhaseType.concentrique);
    expect(c.phaseAt(c.duration - .1).type, ClipPhaseType.isometrique);
    // Montée : le bassin monte (M56 : engagement des scapulas coudes tendus
    // sur 0,3 s, puis flexion des coudes ; la tenue en haut est la 3e phase).
    final y0 = c.poseAt(0, rig).translation.y;
    final yActive = c.poseAt(c.phases.first.end, rig).translation.y;
    expect(yActive - y0, greaterThan(.015));
    final y1 = c.poseAt(c.phases[1].end, rig).translation.y;
    expect(y1 - y0, greaterThan(.3));
    // Départ = suspension bras tendus (bas), fin = menton au-dessus (haut).
    final depart = c.shownPositions.first, fin = c.shownPositions.last;
    expect(depart.key, 'bas');
    expect(fin.key, 'haut');
    expect(
      c.poseAt(fin.time, rig).translation.y -
          c.poseAt(depart.time, rig).translation.y,
      greaterThan(.3),
    );
    // Tenue isométrique : posture fixe.
    final p = c.phases[2];
    expect(
      c.poseAt(p.start + .01, rig).translation.y,
      closeTo(c.poseAt(p.end - .01, rig).translation.y, 1e-9),
    );
  });

  group('fiche exercice', () {
    Widget host(Widget page) => MaterialApp(
      theme: buildTheme(true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: page,
    );

    tearDown(() => ClipRegistry.debugSet(null));

    testWidgets('exercice converti : animation 3D (repli 2D sans GPU)', (
      tester,
    ) async {
      ClipRegistry.debugSet({'dips'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const ExerciseSheetScreen(id: 'dips')));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseAnimation), findsOneWidget);
      // Moteur de test sans Flutter GPU : la démonstration 2D reste.
      expect(find.byType(PoseDemo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('exercice non converti : démonstration 2D seule', (
      tester,
    ) async {
      ClipRegistry.debugSet({'dips'});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const ExerciseSheetScreen(id: 'muscle-up')));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseAnimation), findsNothing);
      expect(find.byType(PoseDemo), findsOneWidget);
    });
  });
}
