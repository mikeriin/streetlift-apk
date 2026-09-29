// M7 (mannequin 3D) — lecteur d'animation, clips, intensité par phase,
// animations réduites, fiches sans animation inchangées, écran « Animation
// de test ». Le moteur de test n'a pas Flutter GPU : le rendu animé est
// vérifié sur émulateur (integration_test/animation_m7_test.dart).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/animation_test_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_player.dart';
import 'package:streetlift_tracker/mannequin_rig.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipRegistry registry;
  late ClipEntry debug;
  late MannequinRig rig;
  late MannequinClip clip;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    // Caches globaux remplis hors des zones de temps simulé.
    await engine3DSupport();
    await MannequinMap.load();
    registry = await ClipRegistry.load();
    debug = registry.debugClip!;
    rig = await MannequinRig.loadMixamo();
    clip = await MannequinClip.load(debug, rig);
  });

  Widget page(Widget child, {bool reduce = false}) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: child!,
    ),
    home: child,
  );

  group('registre', () {
    test('animation de test, jamais sur une fiche', () {
      expect(debug.id, 'debug_squat');
      expect(debug.debug, isTrue);
      expect(debug.exercises, isEmpty);
      expect(debug.fps, 30);
      expect(debug.frames, 181);
      expect(debug.duration, 6);
      expect(debug.bytes, lessThanOrEqualTo(5 * 1024));
      expect(registry.forExercise('back-squat'), isNull);
      expect(registry.forExercise('squat-au-poids-de-corps'), isNull);
      expect(registry.forExercise(null), isNull);
      expect(debug.muscles!.primaires, contains('grand_fessier'));
    });

    test('phases et tempo', () {
      expect(
        [for (final p in debug.phases) p.label],
        [
          'Descente · 3 s',
          'Pause basse · 1 s',
          'Montée · 1 s',
          'Pause haute · 1 s',
        ],
      );
      expect(
        [for (final p in debug.phases) p.kind],
        [
          PhaseKind.excentrique,
          PhaseKind.isometrique,
          PhaseKind.concentrique,
          PhaseKind.isometrique,
        ],
      );
      expect(debug.phaseAt(0).name, 'Descente');
      expect(debug.phaseAt(3.5).name, 'Pause basse');
      expect(debug.phaseAt(4.2).name, 'Montée');
      expect(debug.phaseAt(6).name, 'Pause haute');
      expect(debug.keyTimes, [0, 3, 4, 5, 6]);
      expect(
        const ClipPhase('X', PhaseKind.concentrique, 0, 1.5).tempo,
        '1,5 s',
      );
    });

    test('une animation du propriétaire va sur sa fiche', () {
      final r = ClipRegistry([
        debug,
        ClipEntry(
          id: 'back-squat',
          asset: debug.asset,
          name: 'Back squat',
          exercises: const ['back-squat', 'squat-pause'],
          debug: false,
          fps: 30,
          frames: 181,
          bytes: debug.bytes,
          duration: 6,
          phases: debug.phases,
        ),
      ]);
      expect(r.forExercise('squat-pause')!.id, 'back-squat');
      expect(r.debugClip!.id, 'debug_squat');
    });
  });

  group('clip', () {
    test('décodage et échantillonnage', () {
      expect(clip.frames, 181);
      expect(clip.duration, 6);
      expect(clip.trackCount, inInclusiveRange(10, 30));
      expect(clip.animatedBones, containsAll(['Hips', 'LeftUpLeg', 'LeftLeg']));
      // debout au départ, bassin descendu de 48 cm au plus bas (3 s)
      expect(clip.sample(0).translation.length, lessThan(.005));
      final bottom = clip.sample(3.5);
      expect(bottom.translation.y, closeTo(-.48, .01));
      expect(bottom.translation.z, closeTo(-.2, .01));
      // boucle : fin = début
      final a = clip.sample(0), b = clip.sample(6);
      for (final bone in clip.animatedBones) {
        final qa = a.rotationOf(bone), qb = b.rotationOf(bone);
        final dot = (qa.x * qb.x + qa.y * qb.y + qa.z * qb.z + qa.w * qb.w)
            .abs();
        expect(2 * math.acos(dot.clamp(0.0, 1.0)), lessThan(.01), reason: bone);
      }
      // hors bornes : bornée
      expect(clip.sample(99).translation.y, closeTo(b.translation.y, 1e-9));
    });

    test('pieds fixes pendant le squat (peau du processeur)', () {
      final rest = rig.globals(clip.sample(0));
      final low = rig.globals(clip.sample(3));
      for (final foot in ['LeftFoot', 'RightFoot', 'LeftToeBase']) {
        final i = rig.index[foot]!;
        final d = rest[i].getTranslation() - low[i].getTranslation();
        expect(d.length, lessThan(.01), reason: foot);
      }
      final hips = rig.index['Hips']!;
      expect(
        rest[hips].getTranslation().y - low[hips].getTranslation().y,
        greaterThan(.4),
      );
    });

    test('en-tête invalide refusé', () {
      expect(
        () => MannequinClip.decode(Uint8List.fromList(const [1, 2, 3]), const [
          'Hips',
        ]),
        throwsA(anything),
      );
    });
  });

  group('intensité par phase', () {
    test(
      'vif en concentrique, doux en excentrique, pulsation en isométrie',
      () {
        final ph = debug.phases;
        expect(phaseHaloGain(ph, 1.5), closeTo(kGainEccentric, 1e-9));
        expect(phaseHaloGain(ph, 4.5), closeTo(kGainConcentric, 1e-9));
        expect(phaseHaloGain(ph, 1.5), lessThan(phaseHaloGain(ph, 4.5)));
        // pulsation lente autour de 0,8 en isométrie
        final iso = [
          for (var t = 3.25; t < 3.75; t += .05) phaseHaloGain(ph, t),
        ];
        expect(iso.reduce(math.max) - iso.reduce(math.min), greaterThan(.02));
        for (final g in iso) {
          expect(
            g,
            inInclusiveRange(kGainIsometric - .08, kGainIsometric + .08),
          );
        }
      },
    );

    test('jamais de saut ni de clignotement', () {
      final ph = debug.phases;
      const dt = 1 / 240;
      var prev = phaseHaloGain(ph, 0);
      var maxRate = 0.0;
      for (var t = dt; t <= 6 + 1e-9; t += dt) {
        final g = phaseHaloGain(ph, t);
        maxRate = math.max(maxRate, (g - prev).abs() / dt);
        prev = g;
      }
      expect(maxRate, lessThan(2), reason: 'variation ≤ 2 par seconde');
      // boucle : la fin se fond dans le début
      expect(
        (phaseHaloGain(ph, 6 - 1e-6) - phaseHaloGain(ph, 0)).abs(),
        lessThan(.01),
      );
      // pulsation à 0,5 Hz (< 3 éclats par seconde)
      expect(1 / kIsometricPeriod, lessThan(3));
    });

    test('animations réduites : aucune pulsation', () {
      final ph = debug.phases;
      final values = {
        for (var t = 3.25; t < 3.75; t += .05)
          phaseHaloGain(ph, t, reduceMotion: true).toStringAsFixed(6),
      };
      expect(values, hasLength(1));
    });
  });

  group('lecture', () {
    test('lecture, pause, boucle, pas de saut', () {
      final p = ClipPlayback(debug);
      expect(p.playing, isFalse);
      p.advance(.05);
      expect(p.time, 0);
      p.play();
      p.advance(.05);
      expect(p.time, closeTo(.05, 1e-9));
      // image perdue ou page cachée : avance bornée à 0,1 s
      p.advance(5);
      expect(p.time, closeTo(.15, 1e-9));
      p.seek(5.95);
      p.advance(.1);
      expect(p.time, closeTo(.05, 1e-9));
      p.pause();
      expect(p.playing, isFalse);
      expect(p.autoPause, isNull);
    });

    test('curseur ↔ temps et phase', () {
      final p = ClipPlayback(debug);
      p.seek(3.5);
      expect(p.time, 3.5);
      expect(p.phase.name, 'Pause basse');
      p.seek(-1);
      expect(p.time, 0);
      p.seek(99);
      expect(p.time, 6);
      expect(playerSeconds(1.25), '1,3 s');
    });

    test('pauses automatiques et reprise', () {
      final p = ClipPlayback(debug)..play();
      p.pause(PlayerPause.offscreen);
      expect(p.autoPause, PlayerPause.offscreen);
      expect(p.resumeFrom(PlayerPause.background), isFalse);
      expect(p.resumeFrom(PlayerPause.offscreen), isTrue);
      expect(p.playing, isTrue);
      p.pause(PlayerPause.idle);
      expect(p.autoPause!.label, '60 s sans interaction');
      expect(kPlayerIdlePause, const Duration(seconds: 60));
    });

    test('animations réduites : images clés seulement, pas de lecture', () {
      final p = ClipPlayback(debug, reduceMotion: true);
      p.play();
      expect(p.playing, isFalse);
      p.seek(2.2);
      expect(p.time, 3);
      p.seek(.4);
      expect(p.time, 0);
      p.seekKey(3);
      expect(p.time, 5);
      expect(p.keyIndex, 3);
      p.seekKey(99);
      expect(p.time, 6);
    });
  });

  group('écrans', () {
    testWidgets('fiche sans animation : mannequin fixe inchangé', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          const Scaffold(
            body: SingleChildScrollView(
              child: ExerciseMannequin(
                exerciseId: 'back-squat',
                primaires: ['vaste_lateral'],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('fiche-mannequin')), findsOneWidget);
      expect(find.byKey(const ValueKey('fiche-mannequin-anime')), findsNothing);
      expect(find.byType(MannequinPlayer), findsNothing);
      expect(find.byKey(const ValueKey('player-play')), findsNothing);
    });

    testWidgets(
      'fiche animée sans Flutter GPU : repli 2D, aucun lecteur vide',
      (tester) async {
        final saved = ClipRegistry.loaded;
        ClipRegistry.loaded = ClipRegistry([
          ClipEntry(
            id: 'back-squat',
            asset: debug.asset,
            name: 'Back squat',
            exercises: const ['back-squat'],
            debug: false,
            fps: 30,
            frames: 181,
            bytes: debug.bytes,
            duration: 6,
            phases: debug.phases,
          ),
        ]);
        addTearDown(() => ClipRegistry.loaded = saved);
        await tester.pumpWidget(
          page(
            const Scaffold(
              body: SingleChildScrollView(
                child: ExerciseMannequin(
                  exerciseId: 'back-squat',
                  primaires: ['vaste_lateral'],
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        expect(
          find.byKey(const ValueKey('fiche-mannequin-anime')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('player-play')), findsNothing);
        expect(find.byKey(const ValueKey('player-slider')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('écran Animation de test, libellé comme test', (tester) async {
      await tester.pumpWidget(page(const AnimationTestScreen()));
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      expect(find.text('ANIMATION DE TEST'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('animation-test-banner')),
        findsOneWidget,
      );
      expect(
        find.textContaining('ce n’est pas la démonstration d’un exercice'),
        findsOneWidget,
      );
      expect(find.byType(MannequinPlayer), findsOneWidget);
      // Sans Flutter GPU : message, pas de lecteur vide.
      expect(find.byKey(const ValueKey('player-play')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('animation-test-checklist')),
        200,
      );
      expect(
        find.textContaining('Descente · 3 s — excentrique'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Moteur 3D › Animation de test', (tester) async {
      await tester.pumpWidget(page(const Engine3DScreen(autoMeasure: false)));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      final tile = find.byKey(const ValueKey('engine3d-animation-test'));
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AnimationTestScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('assets du lecteur déclarés', () async {
    for (final a in [kMixamoRigAsset, kMixamoSkinAsset, kClipIndexAsset]) {
      expect(
        (await rootBundle.load(a)).lengthInBytes,
        greaterThan(0),
        reason: a,
      );
    }
    expect(rig.bones, hasLength(65));
    expect(rig.posture('affichage'), isNotNull);
  });
}
