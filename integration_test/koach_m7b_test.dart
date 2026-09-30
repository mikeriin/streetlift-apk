// M7b (CI 3D) : animations de Koach et écran « Koach (aperçu) » sur
// émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/koach_m7b_test.dart \
//     --dart-define=M6B_PART=a -d emulator-5554
// a = Anatomie › Koach (aperçu) : entrée, puces, pose forte de chacune des
//     9 animations (Face), trois d'entre elles aussi en 3/4, lecture ;
// b, c, d = images des GIF (8 par animation, Face) : attente, parle,
//     félicite.
// Relevé `m7b_releve_<partie>.json`. Émulateur sans GPU (PIPELINE_3D.md
// §4) : aucun `pumpAndSettle`, nombre fixe de `pump`, 5 min par test.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/koach_preview_screen.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_player.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
bool _skip(String part) => _part != part;
const _limit = Timeout(Duration(minutes: 5));

/// Pose forte de chaque animation (s) : capture de la partie a.
const _strong = {
  'koach_attente_respiration': .94,
  'koach_attente_regard': .76,
  'koach_attente_etirement': 1.3,
  'koach_parle_une_main': .76,
  'koach_parle_deux_mains': 2.04,
  'koach_parle_montre': .86,
  'koach_felicite_applaudit': .7,
  'koach_felicite_poing': .82,
  'koach_felicite_pouce': .76,
};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final releve = <String, Object?>{};
  binding.reportData = data;
  var ratio = 1.5;

  void record() => data['m7b_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['m7b_$name.png'] = base64Encode(png.buffer.asUint8List());
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

  /// Part de la vue couverte par la figure (fond exclu) : rendu présent.
  Future<double> figure(WidgetTester tester) async {
    final rect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = tester
        .state<Mannequin3DState>(find.byType(Mannequin3D).first)
        .backgroundColor;
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    var total = 0, fig = 0;
    for (var y = rect.top; y < rect.bottom; y += 3) {
      for (var x = rect.left; x < rect.right; x += 3) {
        final px = (x * ratio).round().clamp(0, image.width - 1);
        final py = (y * ratio).round().clamp(0, image.height - 1);
        final o = (py * image.width + px) * 4;
        total++;
        if ((rgba.getUint8(o) - br).abs() > 12 ||
            (rgba.getUint8(o + 1) - bgG).abs() > 12 ||
            (rgba.getUint8(o + 2) - bb).abs() > 12) {
          fig++;
        }
      }
    }
    image.dispose();
    return total == 0 ? 0 : fig / total;
  }

  /// Démarcation : écart moyen des pixels de part et d'autre des bords
  /// gauche et droit de la vue 3D (0 attendu : fond = couleur de la page).
  Future<double> demarcation(WidgetTester tester) async {
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
    return n == 0 ? 0 : edge / n;
  }

  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    SL.dark = true;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m7b-$_part-${home.runtimeType}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(true),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // L'émulateur de la CI coupe les animations du système : lecture
          // normale ici (les animations réduites sont testées en M7).
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
  }

  KoachPreviewScreenState screen(WidgetTester tester) =>
      tester.state<KoachPreviewScreenState>(find.byType(KoachPreviewScreen));

  /// Lecteur de l'animation en cours, prêt (3D chargée, clip décodé).
  Future<MannequinPlayerState> ready(WidgetTester tester) async {
    await waitFor(tester, () => screen(tester).player?.ready != null);
    final p = screen(tester).player!;
    expect(p.ready, isTrue, reason: 'pas de 3D ou clip illisible');
    return p;
  }

  Future<void> scrollToPlayer(WidgetTester tester) async {
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(70);
    await tester.pump(const Duration(milliseconds: 500));
  }

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

  Future<MannequinPlayerState> choose(WidgetTester tester, String id) async {
    screen(tester).select(id);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    return ready(tester);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
    await ClipRegistry.load();
  });

  testWidgets(
    'a : Anatomie › Koach (aperçu), poses fortes',
    (tester) async {
      final out = <String, Object?>{};
      await pumpApp(tester, const AnatomyScreen());
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      final tile = find.byKey(const ValueKey('anatomy-koach-preview'));
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(10000);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      out['entree'] = tile.evaluate().length;
      await shot('anatomie_entree');
      await tester.tap(tile);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      var p = await ready(tester);
      out['lecture_auto'] = p.playback!.playing;
      out['puces'] = screen(tester).clips.length;
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await shot('apercu_haut');
      final t0 = p.playback!.time;
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      out['lecture'] = {
        'avant': t0,
        'apres': p.playback!.time,
        'images_s': p.fps,
      };
      for (final e in _strong.entries) {
        p = await choose(tester, e.key);
        await scrollToPlayer(tester);
        await at(tester, p, e.value);
        out[e.key] = {
          't': p.playback!.time,
          'figure': await figure(tester),
          'demarcation': await demarcation(tester),
        };
        await shot('pose_${e.key}');
        if (e.key.endsWith('montre') ||
            e.key.endsWith('pouce') ||
            e.key.endsWith('poing')) {
          await view(tester, p, MannequinView.troisQuarts);
          await shot('pose_34_${e.key}');
        }
      }
      releve['a'] = out;
      record();
      expect(out['puces'], 9);
      // 5.8.1 : aucun cadre autour de Koach (fond = couleur de la page).
      for (final id in _strong.keys) {
        final d = (out[id]! as Map)['demarcation'] as double;
        expect(d, lessThan(3), reason: id);
      }
      expect(out['lecture_auto'], isTrue);
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  for (final (part, family) in [
    ('b', 'attente'),
    ('c', 'parle'),
    ('d', 'felicite'),
  ]) {
    final ids = [
      for (final id in _strong.keys)
        if (id.startsWith('koach_$family')) id,
    ];
    for (final id in ids) {
      testWidgets(
        '$part : images du GIF, $id',
        (tester) async {
          await pumpApp(tester, KoachPreviewScreen(initialClip: id));
          final p = await ready(tester);
          await scrollToPlayer(tester);
          ratio = .75;
          final out = <String, Object?>{};
          final d = p.playback!.duration;
          for (var k = 0; k < 8; k++) {
            final t = d * k / 8;
            await at(tester, p, t);
            out['gif_$k'] = {'t': t, 'figure': await figure(tester)};
            await shot('gif_${id}_$k');
          }
          releve[id] = out;
          record();
        },
        timeout: _limit,
        skip: _skip(part),
      );
    }
  }
}
