// M7b (mannequin 3D) — animations de Koach en mascotte : registre (9 clips,
// 3 familles, jamais sur une fiche), clips (décodage, pieds fixes, même
// pose de départ et d'arrivée pour enchaîner), écran « Koach (aperçu) » et
// son entrée dans l'écran Anatomie. Le moteur de test n'a pas Flutter GPU :
// le rendu animé est vérifié sur émulateur (integration_test/koach_m7b_test.dart).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/koach_preview_screen.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_player.dart';
import 'package:streetlift_tracker/mannequin_rig.dart';
import 'package:streetlift_tracker/store.dart';

const _ids = [
  'koach_attente_respiration',
  'koach_attente_regard',
  'koach_attente_etirement',
  'koach_parle_une_main',
  'koach_parle_deux_mains',
  'koach_parle_montre',
  'koach_felicite_applaudit',
  'koach_felicite_poing',
  'koach_felicite_pouce',
];

double _angle(RigPose a, RigPose b, String bone) {
  final qa = a.rotationOf(bone), qb = b.rotationOf(bone);
  final dot = (qa.x * qb.x + qa.y * qb.y + qa.z * qb.z + qa.w * qb.w).abs();
  return 2 * math.acos(dot.clamp(0.0, 1.0)) * 180 / math.pi;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClipRegistry registry;
  late MannequinRig rig;
  final clips = <String, MannequinClip>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
    await MannequinMap.load();
    registry = await ClipRegistry.load();
    rig = await MannequinRig.loadMixamo();
    for (final c in registry.koachClips) {
      clips[c.id] = await MannequinClip.load(c, rig);
    }
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  Future<void> settle(WidgetTester tester, [int n = 10]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  group('registre', () {
    test('9 animations de Koach, 3 familles, dans l’ordre', () {
      final koach = registry.koachClips;
      expect([for (final c in koach) c.id], _ids);
      expect([for (final c in koach) c.family], [
        ...List.filled(3, 'attente'),
        ...List.filled(3, 'parle'),
        ...List.filled(3, 'felicite'),
      ]);
      for (final c in koach) {
        expect(c.mascot, isTrue, reason: c.id);
        expect(c.debug, isFalse, reason: c.id);
        expect(c.exercises, isEmpty, reason: c.id);
        expect(c.muscles, isNull, reason: 'mannequin neutre : ${c.id}');
        expect(c.duration, inInclusiveRange(3, 6), reason: c.id);
        expect(c.fps, 30);
        expect(c.bytes, lessThanOrEqualTo(12 * 1024), reason: c.id);
        expect(c.loop, c.family != 'felicite', reason: c.id);
        expect(c.name, isNotEmpty);
        expect(c.phases.first.start, 0);
        expect(c.phases.last.end, closeTo(c.duration, .05));
      }
    });

    test('jamais sur une fiche ni comme animation de test', () {
      expect(registry.debugClip!.id, 'debug_squat');
      for (final id in _ids) {
        expect(registry.forExercise(id), isNull);
      }
      expect(registry.forExercise('back-squat'), isNull);
    });
  });

  group('clips', () {
    test('décodage : images, doigts, bassin', () {
      for (final c in registry.koachClips) {
        final clip = clips[c.id]!;
        expect(clip.frames, c.frames, reason: c.id);
        expect(clip.duration, closeTo(c.duration, 1e-6), reason: c.id);
        expect(clip.animatedBones, contains('Hips'), reason: c.id);
        expect(clip.animatedBones, contains('Head'), reason: c.id);
      }
      // poing et pouce : doigts du squelette Mixamo refermés
      for (final id in ['koach_felicite_poing', 'koach_felicite_pouce']) {
        expect(
          clips[id]!.animatedBones,
          containsAll(['RightHandIndex2', 'RightHandThumb1']),
          reason: id,
        );
      }
      expect(
        clips['koach_parle_montre']!.animatedBones,
        containsAll(['LeftHandMiddle2', 'LeftHandIndex1']),
      );
    });

    test('même pose de départ et d’arrivée : transitions entre elles', () {
      final ref = clips[_ids.first]!.sample(0);
      for (final id in _ids) {
        final clip = clips[id]!;
        final a = clip.sample(0), b = clip.sample(clip.duration);
        for (final bone in rig.bones) {
          expect(_angle(a, b, bone), lessThan(2.5), reason: '$id $bone');
          expect(_angle(a, ref, bone), lessThan(3), reason: '$id $bone');
        }
        expect((a.translation - ref.translation).length, lessThan(.006));
      }
    });

    test('pieds fixes (squelette du processeur)', () {
      for (final id in _ids) {
        final clip = clips[id]!;
        final start = rig.globals(clip.sample(0));
        for (var t = 0.0; t <= clip.duration; t += .1) {
          final g = rig.globals(clip.sample(t));
          for (final foot in ['LeftFoot', 'RightFoot', 'LeftToeBase']) {
            final i = rig.index[foot]!;
            final d = g[i].getTranslation() - start[i].getTranslation();
            expect(d.length, lessThan(.012), reason: '$id $foot $t');
          }
        }
      }
    });
  });

  group('écrans', () {
    testWidgets('Koach (aperçu) : 9 animations au choix, en boucle', (
      tester,
    ) async {
      await tester.pumpWidget(page(const KoachPreviewScreen()));
      await settle(tester);
      expect(find.text('KOACH (APERÇU)'), findsOneWidget);
      for (final l in kKoachFamilies.values) {
        expect(find.text(l), findsOneWidget);
      }
      for (final id in _ids) {
        expect(find.byKey(ValueKey('koach-chip-$id')), findsOneWidget);
      }
      final state = tester.state<KoachPreviewScreenState>(
        find.byType(KoachPreviewScreen),
      );
      expect(state.selected!.id, _ids.first);
      expect(find.byType(MannequinPlayer), findsOneWidget);
      // Sans Flutter GPU : message, pas de lecteur vide.
      expect(find.byKey(const ValueKey('player-play')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('koach-chip-koach_felicite_pouce')));
      await settle(tester, 5);
      expect(state.selected!.id, 'koach_felicite_pouce');
      expect(find.text('Pouce levé'), findsWidgets);
      expect(
        find.textContaining('revient à la pose d’attente'),
        findsOneWidget,
      );
      state.select('koach_parle_montre');
      await settle(tester, 5);
      expect(find.textContaining('Koach parle ·'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Anatomie › Koach (aperçu)', (tester) async {
      await tester.pumpWidget(page(const AnatomyScreen()));
      await settle(tester, 5);
      final tile = find.byKey(const ValueKey('anatomy-koach-preview'));
      await tester.scrollUntilVisible(tile, 200);
      expect(find.text('Koach (aperçu)'), findsOneWidget);
      await tester.tap(tile);
      await settle(tester, 5);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(KoachPreviewScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('lecteur : les félicitations bouclent aussi dans l’aperçu', () {
    final c = registry.koachClips.firstWhere((c) => !c.loop);
    final p = ClipPlayback(c)..play();
    for (var i = 0; i < 200; i++) {
      p.advance(.05);
    }
    expect(p.time, lessThan(c.duration));
    expect(p.playing, isTrue);
  });
}
