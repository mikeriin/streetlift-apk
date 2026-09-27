// L9b (KT-080) — coût du rendu des démonstrations et de la liste la plus
// longue, mesuré dans l'environnement de test (JIT, machine de CI). Ce n'est
// pas une mesure en mode profile sur téléphone (reste à valider sur appareil) :
// les seuils sont larges et servent de garde-fou contre une régression grave.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/pose_engine.dart';
import 'package:streetlift_tracker/pose_painter.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calcul + dessin d\'une image : toutes les démonstrations', () {
    final poses =
        jsonDecode(
              utf8.decode(
                gzip.decode(
                  File('assets/content/poses.json.gz').readAsBytesSync(),
                ),
              ),
            )
            as Map<String, dynamic>;
    final gabarits = poses['gabarits'] as Map<String, dynamic>;
    final roles = PoseRoles.of(KAccentSpec.rouge, true);
    final watch = Stopwatch()..start();
    var frames = 0;
    for (final e in (poses['exercices'] as Map<String, dynamic>).values) {
      final m = e as Map<String, dynamic>;
      if (m['statut'] == 'indisponible') continue;
      final anim = PoseAnimation.fromPack(
        gabarits[m['gabarit']] as Map<String, dynamic>,
        m,
      );
      final vb = poseBBox(anim);
      final d = poseDuration(anim);
      for (var i = 0; i < 10; i++) {
        final recorder = ui.PictureRecorder();
        PosePainter(
          pose: anim,
          joints: poseJointsAt(anim, d * i / 10),
          viewBox: vb,
          roles: roles,
        ).paint(Canvas(recorder), const Size(360, 220));
        recorder.endRecording().dispose();
        frames++;
      }
    }
    watch.stop();
    final perFrame = watch.elapsedMicroseconds / frames;
    // ignore: avoid_print
    print(
      'L9B_PERF demo_frames=$frames moyenne_us=${perFrame.toStringAsFixed(1)}',
    );
    expect(frames, greaterThan(6000));
    // Budget d'une image à 60 i/s : 16 667 µs ; garde-fou large.
    expect(perFrame, lessThan(4000));
  });

  testWidgets('liste la plus longue : 625 exercices, défilement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(store.init);
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(true), home: const ExerciseLibraryScreen()),
    );
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).first;
    final watch = Stopwatch()..start();
    var frames = 0;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump();
      frames++;
    }
    watch.stop();
    // ignore: avoid_print
    print(
      'L9B_PERF liste_frames=$frames moyenne_ms='
      '${(watch.elapsedMicroseconds / frames / 1000).toStringAsFixed(2)}',
    );
    expect(tester.takeException(), null);
  });
}
