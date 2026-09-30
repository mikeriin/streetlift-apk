// M8 (CI 3D) : carte 2D des 15 groupes musculaires sur émulateur Android,
// lancée par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/carte_2d_m8_test.dart \
//     --dart-define=M6B_PART=a -d emulator-5554
// a = thème sombre, b = thème clair. Écrans : Anatomie (aucun groupe, tous,
// Dorsaux + toucher), section « Muscles » de deux fiches (traction, back
// squat), STATS (semaine type), accueil (carte du jour), aperçu de WOD.
// Relevé `m8_releve_<partie>.json` : part de la figure, part en couleur
// dominante, part en gris, démarcation entre la carte et son support,
// couleur lue au centre d'un groupe travaillé, aucune vue 3D sur ces
// écrans (3D réservée à la démonstration et à Koach).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_performance.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_preview.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
const _dark = _part != 'b';
const _theme = _dark ? 'sombre' : 'clair';
const _limit = Timeout(Duration(minutes: 5));

void _fillWeek() {
  final now = DateTime.now().toIso8601String();
  for (var day = 1; day <= 3; day++) {
    final plan = store.program.week(1).day(day);
    if (plan == null) continue;
    for (final ex in plan.exercises) {
      for (final set in store.exLog(1, day, ex).sets) {
        set
          ..done = true
          ..completedAt = now;
      }
    }
  }
  store.notifyListeners();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final releve = <String, Object?>{};
  binding.reportData = data;

  void record() => data['m8_releve_$_part.json'] = const JsonEncoder.withIndent(
    '  ',
  ).convert(releve);

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: _ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['m8_$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpHome(WidgetTester tester, Widget home) async {
    SL.dark = _dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m8-$_part-${home.key}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(_dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: home,
        ),
      ),
    );
    // Masques décodés (préchargés au lancement dans l'application).
    await precacheMuscleMap(_root.currentContext!);
    await wait(tester);
  }

  /// Mesures dans le cadre de la carte [map] : figure (pixels hors du
  /// support), couleur dominante (saturés), gris ; démarcation : écart
  /// moyen des pixels de part et d'autre des bords gauche et droit, en haut
  /// du cadre (0 : carte transparente, support visible).
  Future<Map<String, Object?>> check(WidgetTester tester, Finder map) async {
    final rect = tester.getRect(map.first);
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    (int, int, int) at(double x, double y) {
      final px = (x * _ratio).round().clamp(0, image.width - 1);
      final py = (y * _ratio).round().clamp(0, image.height - 1);
      final o = (py * image.width + px) * 4;
      return (rgba.getUint8(o), rgba.getUint8(o + 1), rgba.getUint8(o + 2));
    }

    // Support : pixel juste au-dessus à gauche du cadre.
    final (br, bgG, bb) = at(rect.left + 1, rect.top + 1);
    var total = 0, figure = 0, color = 0, gray = 0;
    for (var y = rect.top; y < rect.bottom; y += 2) {
      for (var x = rect.left; x < rect.right; x += 2) {
        final (r, g, b) = at(x, y);
        total++;
        if ((r - br).abs() <= 6 &&
            (g - bgG).abs() <= 6 &&
            (b - bb).abs() <= 6) {
          continue;
        }
        figure++;
        final sat =
            [r, g, b].reduce((a, c) => a > c ? a : c) -
            [r, g, b].reduce((a, c) => a < c ? a : c);
        if (sat > 40) color++;
        if (sat < 16) gray++;
      }
    }
    var edge = 0.0, n = 0;
    // Bande haute (au-dessus des épaules : la figure ne touche pas les
    // bords du cadre ; plus bas, un bras peut les toucher quand la carte
    // occupe toute la largeur).
    for (var y = rect.top + 2; y < rect.top + rect.height * .08; y += 2) {
      for (final (xi, xo) in [
        (rect.left + 2, rect.left - 2),
        (rect.right - 2, rect.right + 2),
      ]) {
        final (r1, g1, b1) = at(xi, y);
        final (r2, g2, b2) = at(xo, y);
        edge += ((r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs()) / 3;
        n++;
      }
    }
    image.dispose();
    return {
      'cadre': [rect.left, rect.top, rect.width, rect.height],
      'figure': total == 0 ? 0 : figure / total,
      'couleur': total == 0 ? 0 : color / total,
      'gris': total == 0 ? 0 : gray / total,
      'demarcation': n == 0 ? 0 : edge / n,
    };
  }

  /// Point (fraction de la vue) au cœur d'un groupe : étiquette identique
  /// sur un voisinage de 3 % (pas un bord adouci).
  Future<Offset?> coreOf(MapView view, String group) async {
    for (var fy = .1; fy < .95; fy += .01) {
      for (var fx = .05; fx < .95; fx += .01) {
        if (await mapGroupAt(view, fx, fy) != group) continue;
        var ok = true;
        for (final (dx, dy) in const [
          (-.03, 0.0),
          (.03, 0.0),
          (0.0, -.03),
          (0.0, .03),
        ]) {
          if (await mapGroupAt(view, fx + dx, fy + dy) != group) ok = false;
        }
        if (ok) return Offset(fx, fy);
      }
    }
    return null;
  }

  Future<List<int>> pixel(Offset p) async {
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final px = (p.dx * _ratio).round().clamp(0, image.width - 1);
    final py = (p.dy * _ratio).round().clamp(0, image.height - 1);
    final o = (py * image.width + px) * 4;
    final out = [rgba.getUint8(o), rgba.getUint8(o + 1), rgba.getUint8(o + 2)];
    image.dispose();
    return out;
  }

  List<int> rgb(Color c) => [
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
  ];

  double distance(List<int> a, List<int> b) =>
      ((a[0] - b[0]).abs() + (a[1] - b[1]).abs() + (a[2] - b[2]).abs()) / 3;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
  });

  testWidgets('Anatomie ($_theme) : aucun groupe, tous, Dorsaux + toucher', (
    tester,
  ) async {
    final out = <String, Object?>{};
    AnatomyScreen.session = null;
    await pumpHome(tester, const AnatomyScreen(key: ValueKey('a1')));
    final map = find.byKey(const ValueKey('anatomy-map'));
    out['vues_3d'] = find.byType(Mannequin3D).evaluate().length;
    out['aucun'] = await check(tester, map);
    await shot('anatomie_${_theme}_aucun');
    final screen = tester.state<AnatomyScreenState>(find.byType(AnatomyScreen));
    screen.checkAll();
    await wait(tester);
    out['tous'] = await check(tester, map);
    await shot('anatomie_${_theme}_tous');
    screen.uncheckAll();
    screen.toggleGroup('dorsaux');
    await wait(tester);
    out['dorsaux'] = await check(tester, map);
    // Couleur lue au cœur du grand dorsal (vue de dos) : couleur
    // dominante vive ; au cœur des pectoraux (vue de face) : gris.
    final dos = tester.getRect(find.byKey(const ValueKey('map-dos')));
    final face = tester.getRect(find.byKey(const ValueKey('map-face')));
    final lat = (await coreOf(MapView.dos, 'dorsaux'))!;
    final pec = (await coreOf(MapView.face, 'pectoraux'))!;
    final latPt = dos.topLeft + Offset(lat.dx * dos.width, lat.dy * dos.height);
    final pecPt =
        face.topLeft + Offset(pec.dx * face.width, pec.dy * face.height);
    final latRgb = await pixel(latPt);
    final pecRgb = await pixel(pecPt);
    final hot = rgb(mapHeat(kMapPrimary, _dark));
    final grey = rgb(mapMuscleGray(_dark));
    out['dorsaux_pixel'] = {'lu': latRgb, 'attendu': hot};
    out['pectoraux_pixel'] = {'lu': pecRgb, 'attendu': grey};
    await shot('anatomie_${_theme}_dorsaux');
    // Toucher : nom du groupe sous le doigt.
    await tester.tapAt(latPt);
    await wait(tester, 1000);
    out['toucher'] = screen.touched;
    out['toucher_nom'] = find
        .byKey(const ValueKey('anatomy-touched'))
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .join();
    await shot('anatomie_${_theme}_toucher');
    releve['anatomie'] = out;
    record();
    expect(out['vues_3d'], 0);
    // 5.9.1 : modelé de l'image (noir translucide) par-dessus : la couleur
    // lue est celle du groupe, plus ou moins assombrie.
    int sat(List<int> c) =>
        c.reduce((a, b) => a > b ? a : b) - c.reduce((a, b) => a < b ? a : b);
    expect(
      distance(latRgb, hot),
      lessThan(distance(latRgb, grey)),
      reason: 'dorsaux en couleur dominante',
    );
    expect(sat(latRgb), greaterThan(40), reason: 'dorsaux');
    expect(sat(pecRgb), lessThan(16), reason: 'pectoraux gris');
    expect(screen.touched, 'dorsaux');
    expect(out['toucher_nom'], 'Dorsaux');
    for (final k in ['aucun', 'tous', 'dorsaux']) {
      final m = out[k]! as Map;
      expect(m['demarcation'] as double, lessThan(2), reason: k);
      expect(m['figure'] as double, greaterThan(.08), reason: k);
    }
    expect((out['aucun']! as Map)['couleur'] as double, lessThan(.01));
    expect((out['tous']! as Map)['couleur'] as double, greaterThan(.06));
    AnatomyScreen.session = null;
  }, timeout: _limit);

  testWidgets('fiches ($_theme) : section Muscles', (tester) async {
    final out = <String, Object?>{};
    for (final id in const ['traction-pronation', 'back-squat']) {
      await pumpHome(
        tester,
        ExerciseSheetScreen(key: ValueKey('m8-$id'), id: id),
      );
      final map = find.byKey(ValueKey('fiche-muscle-map-$id'));
      await tester.scrollUntilVisible(
        map,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await Scrollable.ensureVisible(tester.element(map), alignment: .15);
      await wait(tester);
      out[id] = {
        ...await check(tester, map),
        'vues_3d': find.byType(Mannequin3D).evaluate().length,
        'intensites': tester.widget<MuscleMap2D>(map).intensities,
      };
      await shot('fiche_${id}_$_theme');
      releve['fiches'] = out;
      record();
    }
    for (final id in out.keys) {
      final m = out[id]! as Map;
      expect(m['vues_3d'], 0, reason: id);
      expect(m['demarcation'] as double, lessThan(2), reason: id);
      expect(m['couleur'] as double, greaterThan(.02), reason: id);
    }
  }, timeout: _limit);

  testWidgets('STATS, accueil et WOD ($_theme)', (tester) async {
    final out = <String, Object?>{};
    _fillWeek();
    await pumpHome(
      tester,
      const StatsScreen(
        key: ValueKey('m8-stats'),
        initialSection: StatsSection.performance,
        standalone: true,
      ),
    );
    final stats = find.byKey(const ValueKey('stats-muscle-map'));
    await tester.scrollUntilVisible(
      stats,
      250,
      scrollable: find
          .descendant(
            of: find.byType(StatsPerformance),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(stats), alignment: .1);
    await wait(tester);
    out['stats'] = await check(tester, stats);
    await shot('stats_$_theme');

    store.storeClock = () => DateTime(2026, 7, 27, 9);
    store.program.start = DateTime(2026, 7, 13);
    store.startOrigin = 'user';
    await pumpHome(
      tester,
      HomeScreen(
        key: const ValueKey('m8-home'),
        referenceDate: DateTime(2026, 7, 27, 9),
      ),
    );
    await wait(tester, 2000);
    final home = find.byType(MuscleMap2D);
    out['accueil'] = {
      'cartes': home.evaluate().length,
      if (home.evaluate().isNotEmpty) ...await check(tester, home),
    };
    await shot('accueil_$_theme');

    final wod = store.wods.firstWhere((w) => store.isCatalog(w));
    await pumpHome(
      tester,
      WodPreviewScreen(key: const ValueKey('m8-wod'), wodId: wod.id),
    );
    final wodMap = find.byKey(const ValueKey('wod-muscle-map'));
    await tester.scrollUntilVisible(
      wodMap,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(tester.element(wodMap), alignment: .1);
    await wait(tester);
    out['wod'] = {'id': wod.id, ...await check(tester, wodMap)};
    await shot('wod_$_theme');
    out['vues_3d'] = find.byType(Mannequin3D).evaluate().length;
    store.storeClock = DateTime.now;
    releve['stats_accueil_wod'] = out;
    record();
    expect(out['vues_3d'], 0);
    expect((out['stats']! as Map)['couleur'] as double, greaterThan(.02));
    expect((out['accueil']! as Map)['cartes'] as int, greaterThan(0));
    for (final k in ['stats', 'wod']) {
      expect((out[k]! as Map)['demarcation'] as double, lessThan(2), reason: k);
    }
  }, timeout: _limit);
}
