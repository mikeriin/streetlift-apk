// M5 (mannequin 3D) — squelette d'animation et peau : lecture de rig.json et
// du fichier de peau, cinématique identique à celle de la fabrication
// (têtes des os de chaque posture), interpolation des postures (os d'aide à
// mi-angle), peau au repos sans effet, sélecteur « Posture » de l'écran
// Anatomie. Le rendu déformé réel est vérifié sur émulateur par
// integration_test/postures_m5_test.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_rig.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> raw;
  late MannequinRig rig;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    raw =
        jsonDecode(File('assets/anatomy/rig.json').readAsStringSync())
            as Map<String, dynamic>;
    final bin = File('assets/anatomy/mannequin_skin.bin').readAsBytesSync();
    rig = MannequinRig.fromJson(raw, ByteData.sublistView(bin));
    await engine3DSupport();
    await MannequinMap.load();
  });

  test('os, postures de l’écran Anatomie, peau', () {
    // M56 : 30 segments, 18 os d'aide (tiers, pronation), 6 gonflements.
    expect(rig.bones.length, 54);
    expect(rig.bones.first.name, 'pelvis');
    expect([for (final p in rig.appPostures) p.key], kAnatomyPostures.keys);
    expect(rig.posture('debout')!.pose.rotations, isEmpty);
    for (final b in rig.bones) {
      if (b.parent != null) {
        expect(rig.index[b.parent]! < rig.index[b.name]!, isTrue);
      }
    }
    final helpers = [
      for (final b in rig.bones)
        if (b.follows != null) b.name,
    ];
    expect(helpers, hasLength(24));
    final bulges = [
      for (final b in rig.bones)
        if (b.bulge > 0) b.name,
    ];
    // Aides du coude, de la hanche et du genou (tiers) et les 6 gonflements.
    expect(bulges, hasLength(18));
    // Peau : 4 influences par sommet, somme 255, os existants.
    var vertices = 0;
    rig.skin.forEach((name, inf) {
      for (var v = 0; v < inf.vertexCount; v++) {
        var sum = 0;
        for (var k = 0; k < 4; k++) {
          sum += inf.weights[v * 4 + k];
          expect(inf.joints[v * 4 + k] < rig.bones.length, isTrue);
        }
        expect(sum, 255, reason: name);
      }
      vertices += inf.vertexCount;
    });
    expect(vertices, 31452);
  });

  test('cinématique identique à la fabrication (têtes des os)', () {
    for (final p in rig.postures) {
      final g = rig.globals(p.pose);
      final heads = (raw['postures'] as Map)[p.key]['tetes'] as Map;
      for (var i = 0; i < rig.bones.length; i++) {
        final want = heads[rig.bones[i].name] as List;
        final got = g[i].getTranslation();
        for (var c = 0; c < 3; c++) {
          expect(
            (got[c] - (want[c] as num)).abs(),
            lessThan(2e-4),
            reason: '${p.key} ${rig.bones[i].name}',
          );
        }
      }
    }
  });

  test('peau au repos : positions inchangées ; posture : déformées', () {
    final rest = Float32List.fromList([
      .08, .86, 0, // près de la hanche gauche
      .2, 1.1, 0, // coude gauche
    ]);
    final name = rig.skin.keys.first;
    final inf = rig.skin[name]!;
    // Maillage fictif de deux sommets : influences des deux premiers sommets.
    final sub = MannequinRig(
      rig.bones,
      rig.postures,
      skin: {
        name: SkinInfluences(
          Uint8List.sublistView(inf.joints, 0, 8),
          Uint8List.sublistView(inf.weights, 0, 8),
        ),
      },
    );
    final same = sub.skinPositions(name, rest, sub.skinMatrices(RigPose.rest));
    for (var i = 0; i < rest.length; i++) {
      expect((same[i] - rest[i]).abs(), lessThan(1e-6));
    }
    final squat = sub.skinPositions(
      name,
      rest,
      sub.skinMatrices(rig.posture('squat_bas')!.pose),
    );
    expect(squat, isNot(equals(rest)));
  });

  test('transition : extrémités exactes, os d’aide aux tiers, gonflement', () {
    final a = rig.posture('debout')!.pose;
    final b = rig.posture('squat_bas')!.pose;
    expect(identical(rig.blend(a, b, 0), a), isTrue);
    expect(identical(rig.blend(a, b, 1), b), isTrue);
    final mid = rig.blend(a, b, .5);
    final knee = mid.rotationOf('shin_l');
    final aux = mid.rotationOf('knee_aux_l');
    final aux2 = mid.rotationOf('knee_aux2_l');
    double angle(vm.Quaternion q) => 2 * math.acos(q.w.abs().clamp(0.0, 1.0));
    expect(angle(aux), closeTo(angle(knee) / 3, 1e-6));
    expect(angle(aux2), closeTo(angle(knee) * 2 / 3, 1e-6));
    expect(angle(knee), closeTo(angle(b.rotationOf('shin_l')) / 2, 1e-3));
    expect(mid.translation.y, closeTo(b.translation.y / 2, 1e-9));
    // M56 : le quadriceps gonfle avec la flexion du genou (1 + 0,045 × angle),
    // perpendiculairement à l'axe du muscle ; l'os de gonflement ne tourne pas.
    final full = rig.withHelpers(b);
    final quads = rig.bones[rig.index['quads_bulge_l']!];
    expect(full.rotationOf('quads_bulge_l'), vm.Quaternion.identity());
    final s = full.scales['quads_bulge_l']!;
    final axis = quads.bulgeAxis!;
    final along = s.transform(axis.clone());
    expect(along.length, closeTo(1, 1e-9));
    final perp = vm.Vector3(1, 0, 0)..sub(axis * axis.x);
    final grown = s.transform(perp.clone()).length / perp.length;
    expect(grown, closeTo(1 + quads.bulge * angle(b.rotationOf('shin_l')), 1e-9));
    expect(grown, greaterThan(1.08));
    expect(full.scales.containsKey('knee_aux_l'), isTrue);
    expect(full.scales.containsKey('shoulder_aux_l'), isFalse);
  });

  Widget page(Widget child) => MaterialApp(
    theme: buildTheme(true),
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: child,
  );

  testWidgets('écran Anatomie : sélecteur « Posture » et vue adaptée', (
    tester,
  ) async {
    phone(tester, size: const Size(320, 720));
    AnatomyScreen.session = null;
    AnatomyScreen.sessionPosture = 'debout';
    await tester.pumpWidget(page(const AnatomyScreen()));
    for (
      var i = 0;
      i < 60 && find.byType(MuscleHeatmap).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    AnatomyScreenState state() =>
        tester.state<AnatomyScreenState>(find.byType(AnatomyScreen));
    for (final label in kAnatomyPostures.values) {
      expect(find.text(label), findsOneWidget);
    }
    expect(state().posture, 'debout');
    await tester.ensureVisible(
      find.byKey(const ValueKey('anatomy-posture-planche')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('anatomy-posture-planche')));
    await tester.pumpAndSettle();
    expect(state().posture, 'planche');
    // Liste construite à la demande : retour au mannequin.
    for (
      var i = 0;
      i < 20 &&
          find.byKey(const ValueKey('anatomy-mannequin')).evaluate().isEmpty;
      i++
    ) {
      await tester.drag(find.byType(Scrollable).last, const Offset(0, 250));
      await tester.pumpAndSettle();
    }
    final m = tester.widget<Mannequin3D>(
      find.byKey(const ValueKey('anatomy-mannequin')),
    );
    expect(m.posture, 'planche');
    expect(m.view, MannequinView.profil);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('anatomy-posture-planche')),
    );
    expect(chip.selected, isTrue);
    // Gardée pendant la session.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(const AnatomyScreen()));
    expect(state().posture, 'planche');
    AnatomyScreen.sessionPosture = 'debout';
    expect(tester.takeException(), isNull);
  });
}
