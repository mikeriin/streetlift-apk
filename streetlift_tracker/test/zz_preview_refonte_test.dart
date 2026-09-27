// Aperçu de la branche Codex (refonte muscles / animations) : rendus du vrai
// code Flutter, destinés au propriétaire. Fichier temporaire, hors livraison.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/pose_engine.dart';
import 'package:streetlift_tracker/pose_painter.dart';

import 'support/capture_support.dart';

Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('aperçu refonte', (tester) async {
    await loadCaptureFonts();
    final poses = _gz('assets/content/poses.json.gz');
    final gab = poses['gabarits'] as Map<String, dynamic>;
    final exo = poses['exercices'] as Map<String, dynamic>;
    final rnd = math.Random(20260927);
    String pick(String vue) {
      final ids = [
        for (final e in exo.entries)
          if ((e.value as Map)['statut'] == 'disponible' &&
              (gab[(e.value as Map)['gabarit']] as Map)['vue'] == vue)
            e.key,
      ]..sort();
      return ids[rnd.nextInt(ids.length)];
    }

    final chosen = {'face': pick('face'), 'profil': pick('profil')};
    final profil2 = pick('profil');
    chosen['profil2'] = profil2;
    final log = StringBuffer();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    final theme = buildTheme(true, KAccentSpec.rouge);
    Future<void> show(Widget child, Size size) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: Padding(padding: const EdgeInsets.all(12), child: child),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(Scaffold));
        for (final v in ['front', 'back', 'profile']) {
          for (final f in Directory('assets/muscles')
              .listSync()
              .whereType<File>()
              .where((f) => f.path.contains('/${v}_'))) {
            await precacheImage(AssetImage(f.path), ctx);
          }
        }
      });
      await tester.pump();
    }

    for (final entry in chosen.entries) {
      final id = entry.value;
      final e = exo[id] as Map<String, dynamic>;
      final anim = PoseAnimation.fromPack(
        gab[e['gabarit']] as Map<String, dynamic>,
        e,
      );
      final vb = poseBBox(anim);
      final dur = poseDuration(anim);
      log.writeln('${entry.key} $id vue=${anim.view} gabarit=${e['gabarit']} '
          'duree=${dur.toStringAsFixed(2)} images_cles=${anim.keyframes.length}');
      const n = 24;
      for (var i = 0; i < n; i++) {
        final t = dur * i / n;
        await show(
          SizedBox(
            width: 336,
            height: 336,
            child: CustomPaint(
              painter: PosePainter(
                pose: anim,
                joints: poseJointsAt(anim, t),
                viewBox: vb,
                roles: PoseRoles.of(KAccentSpec.rouge, true),
              ),
              size: Size.infinite,
            ),
          ),
          const Size(360, 360),
        );
        await savePng(tester, boundary,
            'anim_${entry.key}_${id}_${i.toString().padLeft(2, '0')}');
      }
      final muscles = (e['muscles'] as Map?) ?? const {};
      await show(
        ExerciseAtlas(
          primaires: [for (final m in muscles['primaires'] ?? []) '$m'],
          secondaires: [for (final m in muscles['secondaires'] ?? []) '$m'],
          height: 300,
        ),
        const Size(390, 340),
      );
      await savePng(tester, boundary, 'carte_${entry.key}_$id');
    }
    await show(
      const MuscleHeatmap(
        data: {
          'dos': 14,
          'biceps': 9,
          'pectoraux': 10,
          'triceps': 8,
          'épaules': 7,
          'quadriceps': 6,
          'gainage': 5,
          'avant-bras': 4,
          'ischios': 3,
          'fessiers': 3,
          'mollets': 1,
        },
        height: 320,
        glow: true,
      ),
      const Size(390, 360),
    );
    await savePng(tester, boundary, 'stats_semaine');
    File('$captureDir/choix.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(log.toString());
  });
}
