// M5 (CI 3D) : squelette d'animation et peau du mannequin, sur émulateur
// Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/postures_m5_test.dart -d emulator-5554
// Captures : les 4 postures de référence (debout, suspendu à la barre, squat
// bas, planche de gainage) sous les 4 vues, quadriceps et dos allumés ;
// écran Anatomie avec le sélecteur « Posture » (squat bas, sombre ; planche,
// clair) et une image au milieu d'une transition. Contrôles : figure, gris,
// rouge ; accord du toucher (peau calculée sur le processeur) et du rendu
// (peau du GPU) : là où le toucher trouve un muscle allumé, l'image est
// rouge ; là où il ne trouve rien, c'est le fond. Relevé m5_releve.json.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _limit = Timeout(Duration(minutes: 5));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m5 = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m5_releve.json'] = const JsonEncoder.withIndent('  ').convert(m5);

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: _ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  bool isRed(int r, int g, int b) => r > 90 && r > g + 40 && r > b + 40;

  /// Contrôles sans référence de la vue et accord toucher / rendu.
  Future<Map<String, Object?>> check(
    WidgetTester tester,
    Mannequin3DState state,
    bool dark,
  ) async {
    final rect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = sceneBackground(dark);
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    (int, int, int) at(double x, double y) {
      final px = (x * _ratio).round().clamp(0, image.width - 1);
      final py = (y * _ratio).round().clamp(0, image.height - 1);
      final o = (py * image.width + px) * 4;
      return (rgba.getUint8(o), rgba.getUint8(o + 1), rgba.getUint8(o + 2));
    }

    bool isBg((int, int, int) c) =>
        (c.$1 - br).abs() <= 12 &&
        (c.$2 - bgG).abs() <= 12 &&
        (c.$3 - bb).abs() <= 12;
    var total = 0, figure = 0, red = 0, gray = 0;
    for (var y = rect.top; y < rect.bottom; y += 2) {
      for (var x = rect.left; x < rect.right; x += 2) {
        final c = at(x, y);
        total++;
        if (isBg(c)) continue;
        figure++;
        if (isRed(c.$1, c.$2, c.$3)) red++;
        if ((c.$1 - c.$2).abs() < 24 && (c.$2 - c.$3).abs() < 24 && c.$1 > 30) {
          gray++;
        }
      }
    }
    // Accord toucher / rendu sur une grille de la vue (bords exclus : un
    // pixel du contour peut tomber d'un côté ou de l'autre).
    final scene = state.scene!;
    var litHits = 0, litRed = 0, emptyHits = 0, emptyBg = 0;
    for (var j = 1; j < 20; j++) {
      for (var i = 1; i < 12; i++) {
        final p = Offset(rect.width * i / 12, rect.height * j / 20);
        final r = scene.pick(state.camera!, p, state.viewSize);
        final c = at(rect.left + p.dx, rect.top + p.dy);
        if (r == null) {
          // Vide : le fond, à 3 pixels près (contours).
          var near = false;
          for (final d in const [Offset(3, 3), Offset(-3, -3)]) {
            if (scene.pick(state.camera!, p + d, state.viewSize) != null) {
              near = true;
            }
          }
          if (near) continue;
          emptyHits++;
          if (isBg(c)) emptyBg++;
        } else if (const {'quadriceps', 'dos'}.contains(r.groupe) &&
            r.couche != 'volume') {
          litHits++;
          if (isRed(c.$1, c.$2, c.$3)) litRed++;
        }
      }
    }
    image.dispose();
    return {
      'figure': total == 0 ? 0 : figure / total,
      'rouge': total == 0 ? 0 : red / total,
      'gris': total == 0 ? 0 : gray / total,
      'toucher_allume': litHits,
      'toucher_allume_rouge': litHits == 0 ? 0 : litRed / litHits,
      'toucher_vide': emptyHits,
      'toucher_vide_fond': emptyHits == 0 ? 0 : emptyBg / emptyHits,
    };
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() done, {
    int seconds = 60,
  }) async {
    for (var i = 0; i < seconds * 20 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty ? null : tester.state<Mannequin3DState>(f.last);
  }

  Future<void> ready(WidgetTester tester) async {
    await waitFor(tester, () => mannequin(tester)?.available != null);
    expect(mannequin(tester)?.available, isTrue, reason: 'pas de 3D');
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> setView(WidgetTester tester, MannequinView view) async {
    await tester.tap(find.byKey(ValueKey('mannequin-view-${view.name}')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpHome(WidgetTester tester, Widget home, bool dark) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m5-$dark-${home.key}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          home: home,
        ),
      ),
    );
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
  });

  // ------------------------------------------- 4 postures sous 4 vues --

  Future<void> postureViews(WidgetTester tester, String posture) async {
    final map = await MannequinMap.load();
    final lit = map.fromGroups({'quadriceps': 1, 'dos': kIntensitySecondary});
    await pumpHome(
      tester,
      Scaffold(
        key: ValueKey('m5-$posture'),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Mannequin3D(
                posture: posture,
                intensities: lit,
                height: 520,
                semanticLabel: 'Posture $posture',
              ),
            ),
          ),
        ),
      ),
      true,
    );
    await ready(tester);
    final state = mannequin(tester)!;
    expect(state.scene!.jointNames, hasLength(40));
    expect(state.posture, posture);
    final out = <String, Object?>{};
    for (final v in MannequinView.values) {
      await setView(tester, v);
      await shot('m5_${posture}_${v.name}');
      final s = await check(tester, state, true);
      out[v.name] = s;
      m5[posture] = out;
      record();
      expect(s['figure'] as double, greaterThan(.03), reason: v.name);
      expect(s['gris'] as double, greaterThan(.01), reason: v.name);
      expect(s['rouge'] as double, greaterThan(.002), reason: v.name);
      expect(
        s['toucher_vide_fond'] as double,
        greaterThan(.85),
        reason: v.name,
      );
      if ((s['toucher_allume'] as int) >= 10) {
        expect(
          s['toucher_allume_rouge'] as double,
          greaterThan(.4),
          reason: v.name,
        );
      }
    }
  }

  for (final posture in const ['debout', 'suspendu', 'squat_bas', 'planche']) {
    testWidgets('M5 : posture $posture, 4 vues', (tester) async {
      await postureViews(tester, posture);
    }, timeout: _limit);
  }

  // ------------------------------------------------------ écran Anatomie --

  testWidgets('M5 : écran Anatomie, sélecteur « Posture », transition', (
    tester,
  ) async {
    AnatomyScreen.session = null;
    AnatomyScreen.sessionPosture = 'debout';
    await pumpHome(
      tester,
      const AnatomyScreen(
        key: ValueKey('m5-anatomie'),
        initialGroup: 'quadriceps',
      ),
      true,
    );
    await ready(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('anatomy-posture-squat_bas')),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('anatomy-posture-squat_bas')));
    // Milieu de la transition (750 ms).
    await tester.pump(const Duration(milliseconds: 300));
    final mid = mannequin(tester)!;
    m5['transition_en_cours'] = mid.posing;
    await shot('m5_anatomie_transition');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
    expect(mannequin(tester)!.posing, isFalse);
    expect(mannequin(tester)!.view, MannequinView.troisQuarts);
    await shot('m5_anatomie_squat_sombre');
    final s = await check(tester, mannequin(tester)!, true);
    m5['anatomie_squat'] = s;
    record();
    expect(s['rouge'] as double, greaterThan(.002));
    // Toucher sur le modèle déformé : un point d'un quadriceps.
    final state = mannequin(tester)!;
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    Offset? target;
    for (var j = 0; j < 30 && target == null; j++) {
      for (var i = 0; i < 20 && target == null; i++) {
        final p = Offset(rect.width * i / 20, rect.height * j / 30);
        final r = state.scene!.pick(state.camera!, p, state.viewSize);
        if (r != null && r.groupe == 'quadriceps') target = p;
      }
    }
    expect(target, isNotNull, reason: 'aucun point sur un quadriceps');
    await tester.tapAt(rect.topLeft + target!);
    await tester.pump(const Duration(seconds: 2));
    m5['toucher_squat'] = mannequin(tester)!.touched?.label;
    record();
    await shot('m5_anatomie_squat_toucher');
    expect(mannequin(tester)!.touched?.groupe, 'quadriceps');
    AnatomyScreen.sessionPosture = 'debout';
  }, timeout: _limit);

  testWidgets('M5 : écran Anatomie, planche, clair', (tester) async {
    AnatomyScreen.session = null;
    AnatomyScreen.sessionPosture = 'debout';
    await pumpHome(
      tester,
      const AnatomyScreen(
        key: ValueKey('m5-anatomie-clair'),
        initialGroup: 'gainage',
      ),
      false,
    );
    await ready(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('anatomy-posture-planche')),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('anatomy-posture-planche')));
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(seconds: 2));
    expect(mannequin(tester)!.view, MannequinView.profil);
    await shot('m5_anatomie_planche_clair');
    AnatomyScreen.sessionPosture = 'debout';
    SL.dark = true;
  }, timeout: _limit);
}
