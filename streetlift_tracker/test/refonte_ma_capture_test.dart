// Refonte muscles et animations — rendus du vrai code Flutter pour la revue
// visuelle : planches d'images clés de TOUS les exercices animés, boucles des
// exercices d'aperçu, résumé STATS, fiche exercice, planche face / dos /
// profil et chaque calque de profil surligné seul. Exécuté seulement avec
// --dart-define=KALIS_CAPTURE=true (rendus écrits dans KALIS_CAPTURE_DIR).
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/pose_cutout.dart';
import 'package:streetlift_tracker/pose_engine.dart';
import 'package:streetlift_tracker/pose_painter.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/capture_support.dart';

Map<String, dynamic> _gz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());
}

/// Graine du tirage des exercices d'aperçu.
const previewSeed = 20260927;

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

  testWidgets('rendus de revue et d\'aperçu', (tester) async {
    await loadCaptureFonts();
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(store.init);
    final sprites = <String, CutoutSprites>{};
    await tester.runAsync(() async {
      for (final v in const ['face', 'dos', 'profil']) {
        sprites[v] = await CutoutSprites.load(v, bundle: _FileBundle());
      }
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    final theme = buildTheme(true);
    final roles = PoseRoles.of(KAccentSpec.rouge, true);

    Future<void> show(Widget child, Size size, {bool reduce = false}) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          builder:
              (context, c) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduce),
                child: c!,
              ),
          home: RepaintBoundary(
            key: boundary,
            child: ColoredBox(color: KPalette.black, child: child),
          ),
        ),
      );
      await precacheCaptureImages(tester);
      await tester.pump();
    }

    Widget tile(PoseAnimation anim, Joints j, List<double> vb, double size) =>
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: PosePainter(
              pose: anim,
              joints: j,
              viewBox: vb,
              roles: roles,
              sprites: sprites[cutoutViewOf(anim)],
            ),
          ),
        );

    const label = TextStyle(
      fontFamily: 'Roboto',
      color: Colors.white,
      fontSize: 12,
      height: 1.2,
    );

    // 1. Planches d'images clés : tous les exercices non indisponibles.
    // statut affiché par l'application : pack + revue (reviewedDemoStatus)
    String statutOf(String id) =>
        reviewedDemoStatus(id, (exercices[id] as Map)['statut'] as String);
    final ids = [
      for (final e in exercices.entries)
        if (statutOf(e.key) != 'indisponible' &&
            gabarits[(e.value as Map)['gabarit']] != null)
          e.key,
    ]..sort();
    final index = StringBuffer();
    // Rangées de 4 cases au plus (un exercice = ses images clés, 4 au plus),
    // 4 rangées par planche.
    const cell = 240.0, perRow = 4, rowsPerSheet = 4;
    final rows = <List<String>>[];
    var used = perRow;
    for (final id in ids) {
      final n =
          statutOf(id) == 'statique'
              ? 1
              : math.min(perRow, animationOf(id).keyframes.length);
      if (used + n > perRow) {
        rows.add([]);
        used = 0;
      }
      rows.last.add(id);
      used += n;
    }
    for (var s = 0; s * rowsPerSheet < rows.length; s++) {
      final sheetRows = rows.skip(s * rowsPerSheet).take(rowsPerSheet);
      final lines = <Widget>[];
      for (final row in sheetRows) {
        final blocks = <Widget>[];
        for (final id in row) {
          final anim = animationOf(id);
          final e = exercices[id] as Map;
          final vb = poseBBox(anim);
          final kfs =
              statutOf(id) == 'statique'
                  ? [anim.keyframes[reviewedStaticKeyframe(id)]]
                  : anim.keyframes.take(perRow).toList();
          index.writeln(
            'planche_${s.toString().padLeft(3, '0')} $id '
            'vue=${cutoutViewOf(anim)} gabarit=${e['gabarit']} '
            'statut=${statutOf(id)} images_cles=${anim.keyframes.length}',
          );
          blocks.add(
            Container(
              width: kfs.length * cell,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ' $id · ${cutoutViewOf(anim)}'
                    '${statutOf(id) == 'statique' ? ' · STATIQUE' : ''}',
                    style: label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                  ),
                  Row(
                    children: [
                      for (final k in kfs)
                        tile(anim, poseOf(k, anim.view), vb, cell - 2),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        lines.add(Row(children: blocks));
      }
      await show(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
        const Size(perRow * cell, rowsPerSheet * (cell + 20)),
      );
      await savePng(
        tester,
        boundary,
        'revue/planche_${s.toString().padLeft(3, '0')}',
        pixelRatio: 1,
      );
    }
    File('$captureDir/revue/index.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(index.toString());

    // 2. Exercices d'aperçu tirés au hasard : face, dos, profil.
    final rnd = math.Random(previewSeed);
    final chosen = <String, String>{};
    for (final view in const ['face', 'dos', 'profil']) {
      final pool = [
        for (final id in ids)
          // exercices réellement animés (au moins deux images clés)
          if (statutOf(id) == 'disponible' &&
              animationOf(id).keyframes.length > 1 &&
              cutoutViewOf(animationOf(id)) == view)
            id,
      ];
      chosen[view] = pool[rnd.nextInt(pool.length)];
    }
    final log = StringBuffer('graine=$previewSeed\n');
    for (final entry in chosen.entries) {
      final anim = animationOf(entry.value);
      final vb = poseBBox(anim);
      final d = poseDuration(anim);
      const n = 36;
      log.writeln(
        '${entry.key} ${entry.value} duree=${d.toStringAsFixed(2)} '
        'images=$n images_cles=${anim.keyframes.length}',
      );
      for (var i = 0; i < n; i++) {
        await show(
          tile(anim, poseJointsAt(anim, d * i / n), vb, 360),
          const Size(360, 360),
        );
        await savePng(
          tester,
          boundary,
          'apercu/boucle_${entry.key}_${i.toString().padLeft(2, '0')}',
        );
      }
      await show(
        Row(
          children: [
            for (final k in anim.keyframes)
              tile(anim, poseOf(k, anim.view), vb, 260),
          ],
        ),
        Size(260.0 * anim.keyframes.length, 260),
      );
      await savePng(tester, boundary, 'apercu/images_cles_${entry.key}');
    }
    File('$captureDir/apercu/choix.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(log.toString());

    // 3. Résumé STATS de la semaine (rendu 3.1.0) et planche face/dos/profil.
    const week = {
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
    await show(
      const Padding(
        padding: EdgeInsets.all(12),
        child: MuscleHeatmap(data: week, height: 320, glow: true),
      ),
      const Size(390, 360),
    );
    await savePng(tester, boundary, 'apercu/stats_semaine');
    await show(
      const Padding(
        padding: EdgeInsets.all(12),
        child: MuscleHeatmap(
          data: {},
          height: 520,
          views: ['front', 'back', 'profile'],
        ),
      ),
      const Size(560, 570),
    );
    await savePng(tester, boundary, 'apercu/planche_face_dos_profil');
    await show(
      Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final g in muscleMasks['profile']!)
              SizedBox(
                width: 120,
                height: 300,
                child: Column(
                  children: [
                    Text(g, style: label),
                    Expanded(
                      child: MuscleHeatmap(
                        data: {g: 1},
                        labels: false,
                        views: const ['profile'],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const Size(780, 640),
    );
    await savePng(tester, boundary, 'apercu/calques_profil');

    // 4. Fiche exercice (exercice de profil tiré), écran long, sans défilement.
    await show(
      ExerciseSheetScreen(id: chosen['profil']!),
      const Size(390, 2600),
      reduce: true,
    );
    await tester.pump(const Duration(milliseconds: 50));
    await savePng(tester, boundary, 'apercu/fiche_${chosen['profil']}');
    expect(tester.takeException(), isNull);
  }, skip: !captureEnabled);
}
