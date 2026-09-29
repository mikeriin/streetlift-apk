// M7 (CI 3D) : lecteur d'animation et animation de test sur émulateur
// Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/animation_m7_test.dart \
//     --dart-define=M6B_PART=a -d emulator-5554
// a = écran « Animation de test » en sombre : phases (0 ; 1,5 ; 3,5 ; 4,5 ;
//     5,5 s), vues Profil / Face / 3/4 / Dos au plus bas, zoom, toucher sur
//     le corps déformé, lecture (temps qui avance, images/s), pause ;
// b = clair et animations réduites (pas de lecture, images clés) ;
// c = images du GIF (12 images sur les 6 s, vue Profil) et relevé du halo
//     par phase.
// Relevé `m7_releve_<partie>.json`. Émulateur sans GPU (PIPELINE_3D.md
// §4) : aucun `pumpAndSettle`, nombre fixe de `pump`, 5 min par test.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/animation_test_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_player.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
bool _skip(String part) => _part != part;
const _limit = Timeout(Duration(minutes: 5));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final releve = <String, Object?>{};
  binding.reportData = data;
  var ratio = 1.5;

  void record() => data['m7_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['m7_$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() done, {
    int seconds = 120,
  }) async {
    for (var i = 0; i < seconds * 20 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Figure, halo (pixels saturés du côté de la couleur dominante), gris,
  /// démarcation (bords de la vue) dans `mannequin-view`.
  Future<Map<String, Object?>> check(WidgetTester tester) async {
    final rect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    (int, int, int) at(double x, double y) {
      final px = (x * ratio).round().clamp(0, image.width - 1);
      final py = (y * ratio).round().clamp(0, image.height - 1);
      final o = (py * image.width + px) * 4;
      return (rgba.getUint8(o), rgba.getUint8(o + 1), rgba.getUint8(o + 2));
    }

    final bg = tester
        .state<Mannequin3DState>(find.byType(Mannequin3D).first)
        .backgroundColor;
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    final accent = SL.accentSpec.principal;
    final ar = (accent.r * 255).round(), ag = (accent.g * 255).round();
    final ab = (accent.b * 255).round();
    var total = 0, figure = 0, halo = 0, gray = 0;
    for (var y = rect.top; y < rect.bottom; y += 2) {
      for (var x = rect.left; x < rect.right; x += 2) {
        final (r, g, b) = at(x, y);
        total++;
        if ((r - br).abs() <= 12 &&
            (g - bgG).abs() <= 12 &&
            (b - bb).abs() <= 12) {
          continue;
        }
        figure++;
        final sat =
            [r, g, b].reduce((a, c) => a > c ? a : c) -
            [r, g, b].reduce((a, c) => a < c ? a : c);
        final dot =
            (r - br) * (ar - br) + (g - bgG) * (ag - bgG) + (b - bb) * (ab - bb);
        if (sat > 40 && dot > 0) halo++;
        if (sat < 24 && r > 30) gray++;
      }
    }
    var edge = 0.0, n = 0;
    for (var y = rect.top + 8; y < rect.top + rect.height / 2; y += 4) {
      for (final (xi, xo) in [
        (rect.left + 3, rect.left - 3),
        (rect.right - 3, rect.right + 3),
      ]) {
        final (r1, g1, b1) = at(xi, y);
        final (r2, g2, b2) = at(xo, y);
        edge += ((r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs()) / 3;
        n++;
      }
    }
    image.dispose();
    return {
      'figure': total == 0 ? 0 : figure / total,
      'halo': total == 0 ? 0 : halo / total,
      'gris': total == 0 ? 0 : gray / total,
      'demarcation': n == 0 ? 0 : edge / n,
    };
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    bool dark, {
    bool reduce = false,
  }) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m7-$dark-$reduce-$_part'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: child!,
          ),
          home: const AnimationTestScreen(),
        ),
      ),
    );
  }

  Future<MannequinPlayerState> ready(WidgetTester tester) async {
    MannequinPlayerState? player() {
      final f = find.byType(MannequinPlayer);
      return f.evaluate().isEmpty
          ? null
          : tester.state<MannequinPlayerState>(f.first);
    }

    await waitFor(tester, () => player()?.ready != null);
    final p = player()!;
    expect(p.ready, isTrue, reason: 'pas de 3D ou clip illisible');
    await tester.pump(const Duration(seconds: 1));
    return p;
  }

  /// Place le lecteur (en pause) au temps [t] et laisse le rendu se faire.
  Future<void> at(WidgetTester tester, MannequinPlayerState p, double t) async {
    if (p.playback!.playing) p.toggle();
    p.seek(t);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> view(
    WidgetTester tester,
    MannequinPlayerState p,
    MannequinView v,
  ) async {
    p.mannequin!.setView(v);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Map<String, Object?> state(MannequinPlayerState p) {
    final pb = p.playback!;
    final scene = p.mannequin!.scene!;
    return {
      't': pb.time,
      'phase': pb.phase.label,
      'gain': pb.haloGain,
      'lecture': pb.playing,
      'bassin_y': scene.pose.translation.y,
      'poseVersion': scene.poseVersion,
    };
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
    await ClipRegistry.load();
  });

  testWidgets('a : phases, vues, zoom, toucher, lecture (sombre)', (
    tester,
  ) async {
    await pumpScreen(tester, true);
    final p = await ready(tester);
    final out = <String, Object?>{};
    out['cadrage'] = {
      'hauteur': p.framing!.height,
      'largeur': p.framing!.width,
    };
    // Lecture automatique au démarrage.
    out['lecture_auto'] = p.playback!.playing;
    await view(tester, p, MannequinView.profil);
    for (final (name, t) in [
      ('t0_depart', 0.0),
      ('t1_descente', 1.5),
      ('t2_pause_basse', 3.5),
      ('t3_montee', 4.5),
      ('t4_pause_haute', 5.5),
    ]) {
      await at(tester, p, t);
      out[name] = {...state(p), ...await check(tester)};
      await shot('sombre_profil_$name');
    }
    await at(tester, p, 3.5);
    for (final v in [MannequinView.face, MannequinView.troisQuarts, MannequinView.dos]) {
      await view(tester, p, v);
      out['bas_${v.name}'] = await check(tester);
      await shot('sombre_bas_${v.name}');
    }
    // Toucher sur le corps déformé : centre du vaste latéral gauche posé.
    await view(tester, p, MannequinView.troisQuarts);
    final m = p.mannequin!;
    final scene = m.scene!;
    final pos = scene.haloPositions('vastus_lateralis_left')!;
    var sx = 0.0, sy = 0.0, sz = 0.0;
    final nv = pos.length ~/ 3;
    for (var i = 0; i < nv; i++) {
      sx += pos[i * 3];
      sy += pos[i * 3 + 1];
      sz += pos[i * 3 + 2];
    }
    final proj = HaloProjection.of(m.camera!, m.viewSize)!;
    final screen = proj.project(sx / nv, sy / nv, sz / nv);
    final viewRect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
    if (screen != null) {
      await tester.tapAt(viewRect.topLeft + screen);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }
    out['toucher'] = {'point': screen?.toString(), 'region': m.touched?.id};
    await shot('sombre_toucher');
    // Zoom au pincement sur les genoux.
    m.pinchTo(2.2, viewRect.size.center(Offset.zero) + const Offset(0, 60));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    out['zoom'] = {'echelle': m.zoom.scale, ...await check(tester)};
    await shot('sombre_zoom');
    m.resetZoom();
    // Lecture : le temps avance, images/s mesurées.
    await view(tester, p, MannequinView.profil);
    p.toggle();
    final t0 = p.playback!.time;
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    out['lecture'] = {
      'avant': t0,
      'apres': p.playback!.time,
      'en_cours': p.playback!.playing,
      'images_s': p.fps,
    };
    await shot('sombre_lecture');
    p.toggle();
    await tester.pump(const Duration(milliseconds: 500));
    out['pause'] = p.playback!.playing;
    releve['a'] = out;
    record();
    expect(out['lecture_auto'], isTrue);
    expect((out['lecture']! as Map)['apres'], isNot(t0));
  }, timeout: _limit, skip: _skip('a'));

  testWidgets('b : clair, animations réduites', (tester) async {
    await pumpScreen(tester, false);
    var p = await ready(tester);
    final out = <String, Object?>{};
    await view(tester, p, MannequinView.troisQuarts);
    for (final (name, t) in [('descente', 1.5), ('pause_basse', 3.5)]) {
      await at(tester, p, t);
      out['clair_$name'] = {...state(p), ...await check(tester)};
      await shot('clair_34_$name');
    }
    // Animations réduites : pas de lecture, images clés au curseur.
    await pumpScreen(tester, true, reduce: true);
    p = await ready(tester);
    await tester.pump(const Duration(seconds: 2));
    out['reduit_depart'] = {
      ...state(p),
      'bouton_lecture': find.byKey(const ValueKey('player-play')).evaluate().length,
    };
    await shot('reduit_depart');
    p.seek(3.2);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    out['reduit_image_cle'] = state(p);
    await shot('reduit_image_cle');
    releve['b'] = out;
    record();
    expect(p.playback!.playing, isFalse);
    expect(p.playback!.time, 3);
  }, timeout: _limit, skip: _skip('b'));

  testWidgets('c : images du GIF et halo par phase', (tester) async {
    await pumpScreen(tester, true);
    final p = await ready(tester);
    await view(tester, p, MannequinView.profil);
    ratio = .75;
    final out = <String, Object?>{};
    for (var k = 0; k < 12; k++) {
      final t = k * .5;
      await at(tester, p, t);
      out['gif_$k'] = {...state(p), ...await check(tester)};
      await shot('gif_${k.toString().padLeft(2, '0')}');
    }
    releve['c'] = out;
    record();
  }, timeout: _limit, skip: _skip('c'));
}
