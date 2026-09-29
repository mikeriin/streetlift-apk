// M4 (CI 3D) : STATS › Performances › Muscles sollicités sur le mannequin
// 3D, sur émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/stats_semaine_test.dart -d emulator-5554
// Captures : semaine type (face, dos, rotation, légende) et semaine vide, en
// sombre et en clair. Mesure du défilement de STATS mannequin à l'écran
// (temps de construction et de dessin des images) comparé à la rotation du
// mannequin, qui redessine la scène à chaque image : si le défilement ne
// redessine pas la scène, ses images restent bien plus courtes. Relevé
// m4_releve.json.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/stats_mannequin.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_performance.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;

/// Semaine type : toutes les séries des trois premières journées du
/// programme validées aujourd'hui (comme test/m4_stats_mannequin_test.dart).
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
  final m4 = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m4_releve.json'] = const JsonEncoder.withIndent('  ').convert(m4);

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

  /// Contrôle sans référence de la vue : figure, gris, rouge de la rampe.
  Future<Map<String, Object?>> pixels(WidgetTester tester, bool dark) async {
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = sceneBackground(dark);
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    var total = 0, figure = 0, red = 0, gray = 0;
    final colors = <int>{};
    final top = (rect.top * _ratio).round().clamp(0, image.height);
    final bottom = (rect.bottom * _ratio).round().clamp(0, image.height);
    final left = (rect.left * _ratio).round().clamp(0, image.width);
    final right = (rect.right * _ratio).round().clamp(0, image.width);
    for (var y = top; y < bottom; y += 2) {
      for (var x = left; x < right; x += 2) {
        final o = (y * image.width + x) * 4;
        final r = rgba.getUint8(o), g = rgba.getUint8(o + 1);
        final b = rgba.getUint8(o + 2);
        total++;
        colors.add((r >> 3) << 10 | (g >> 3) << 5 | (b >> 3));
        final diff = [(r - br).abs(), (g - bgG).abs(), (b - bb).abs()];
        if (diff.reduce((a, c) => a > c ? a : c) <= 12) continue;
        figure++;
        if (r > 90 && r > g + 40 && r > b + 40) red++;
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 40) gray++;
      }
    }
    image.dispose();
    return {
      'pixels': total,
      'figure': total == 0 ? 0 : figure / total,
      'rouge': total == 0 ? 0 : red / total,
      'gris': total == 0 ? 0 : gray / total,
      'couleurs': colors.length,
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

  Finder mannequinFinder() => find.byKey(const ValueKey('stats-mannequin'));

  Finder statsList() => find
      .descendant(
        of: find.byType(StatsPerformance),
        matching: find.byType(Scrollable),
      )
      .first;

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty ? null : tester.state<Mannequin3DState>(f.last);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
  });

  const stats = StatsScreen(
    initialSection: StatsSection.performance,
    standalone: true,
  );

  /// Ouvre STATS › Performances et place le mannequin en haut de l'écran.
  Future<void> openStats(WidgetTester tester, {required bool dark}) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('stats-$dark-${store.logs.length}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          home: stats,
        ),
      ),
    );
    await waitFor(
      tester,
      () => find.byType(StatsPerformance).evaluate().isNotEmpty,
      seconds: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      mannequinFinder(),
      250,
      scrollable: statsList(),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await Scrollable.ensureVisible(
      tester.element(mannequinFinder()),
      alignment: .03,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await waitFor(tester, () => mannequin(tester)?.available != null);
    expect(mannequin(tester)?.available, isTrue, reason: 'pas de 3D');
    // Rendu à la demande stabilisé (compilation des shaders au premier).
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> setView(WidgetTester tester, MannequinView view) async {
    await tester.tap(find.byKey(ValueKey('mannequin-view-${view.name}')));
    await tester.pump(const Duration(seconds: 3));
  }

  /// Temps des images pendant [action] (ms) : construction et dessin.
  Future<Map<String, Object?>> timings(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final frames = <FrameTiming>[];
    void onTimings(List<FrameTiming> t) => frames.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(onTimings);
    await action();
    await tester.pump(const Duration(seconds: 2));
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
    Map<String, Object?> summary(List<double> v) {
      if (v.isEmpty) return {'n': 0};
      v.sort();
      double at(double q) => v[((v.length - 1) * q).round()];
      return {
        'n': v.length,
        'mediane': at(.5).toStringAsFixed(1),
        'p90': at(.9).toStringAsFixed(1),
        'max': v.last.toStringAsFixed(1),
      };
    }

    return {
      'images': frames.length,
      'construction_ms': summary([
        for (final f in frames) f.buildDuration.inMicroseconds / 1000,
      ]),
      'dessin_ms': summary([
        for (final f in frames) f.rasterDuration.inMicroseconds / 1000,
      ]),
      'total_ms': summary([
        for (final f in frames) f.totalSpan.inMicroseconds / 1000,
      ]),
    };
  }

  Future<void> checkWeek(WidgetTester tester, String theme, bool dark) async {
    final state = tester.state<WeeklyMannequinState>(
      find.byType(WeeklyMannequin),
    );
    // 5.5.3 : zone ciblée (muscles du pack des exercices de la semaine).
    final expected = targetedRegionIntensities(
      MannequinMap.loaded!,
      targetedMuscles(ContentLibrary.loaded!, store.weeklyNames()),
    );
    expect(state.intensities, expected);
    expect(expected, isNotEmpty);
    final out = <String, Object?>{
      'series_par_groupe': {
        for (final e in weekly.entries)
          if (e.value > 0) e.key: e.value,
      },
      'regions_allumees': expected.length,
    };
    await shot('m4_stats_semaine_${theme}_face');
    out['face'] = await pixels(tester, dark);
    await setView(tester, MannequinView.dos);
    expect(mannequin(tester)!.view, MannequinView.dos);
    await shot('m4_stats_semaine_${theme}_dos');
    out['dos'] = await pixels(tester, dark);
    for (final v in ['face', 'dos']) {
      final s = out[v]! as Map<String, Object?>;
      expect(s['figure'] as double, greaterThan(.04), reason: '$theme $v');
      expect(s['gris'] as double, greaterThan(.02), reason: '$theme $v');
      expect(s['rouge'] as double, greaterThan(.002), reason: '$theme $v');
    }
    m4['semaine_$theme'] = out;
    record();
  }

  Future<void> checkEmpty(WidgetTester tester, String theme, bool dark) async {
    final state = tester.state<WeeklyMannequinState>(
      find.byType(WeeklyMannequin),
    );
    expect(state.intensities, isEmpty);
    await shot('m4_stats_vide_$theme');
    final s = await pixels(tester, dark);
    m4['vide_$theme'] = s;
    record();
    expect(s['figure'] as double, greaterThan(.04), reason: theme);
    expect(s['rouge'] as double, lessThan(.0005), reason: theme);
    expect(
      find.text('Valide tes séries pour voir ta répartition musculaire.'),
      findsOneWidget,
    );
  }

  testWidgets('M4 : semaine type, thème sombre, bascule, défilement', (
    tester,
  ) async {
    store.logs.clear();
    _fillWeek();
    await openStats(tester, dark: true);
    await checkWeek(tester, 'sombre', true);

    // Rotation au doigt (horizontale) : la scène se redessine à chaque image.
    final rotation = await timings(
      tester,
      () => tester.timedDrag(
        find.byKey(const ValueKey('mannequin-view')),
        const Offset(-160, 0),
        const Duration(milliseconds: 1200),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await shot('m4_stats_semaine_sombre_rotation');

    // Légende chiffrée sous le mannequin.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('stats-muscles-unite'))),
      alignment: .9,
    );
    await tester.pump(const Duration(seconds: 2));
    await shot('m4_stats_semaine_sombre_legende');

    // Défilement de STATS, mannequin à l'écran : la scène n'est pas
    // redessinée (rendu à la demande, frontière de dessin).
    await Scrollable.ensureVisible(
      tester.element(mannequinFinder()),
      alignment: .2,
    );
    await tester.pump(const Duration(seconds: 2));
    final scroll = await timings(tester, () async {
      for (var i = 0; i < 3; i++) {
        await tester.timedDrag(
          statsList(),
          const Offset(0, -120),
          const Duration(milliseconds: 700),
        );
        await tester.timedDrag(
          statsList(),
          const Offset(0, 120),
          const Duration(milliseconds: 700),
        );
      }
    });
    m4['mesure'] = {
      'note':
          'émulateur, rendu logiciel, build debug : seul le rapport '
          'défilement / rotation compte',
      'defilement_mannequin_a_l_ecran': scroll,
      'rotation_du_mannequin': rotation,
    };
    record();
    expect(find.byType(WeeklyMannequin), findsOneWidget);

    // Semaine vide, même thème.
    store.logs.clear();
    store.notifyListeners();
    await openStats(tester, dark: true);
    await checkEmpty(tester, 'sombre', true);
  });

  testWidgets('M4 : semaine type et semaine vide, thème clair', (tester) async {
    store.logs.clear();
    _fillWeek();
    await openStats(tester, dark: false);
    await checkWeek(tester, 'clair', false);
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('stats-muscles-unite'))),
      alignment: .9,
    );
    await tester.pump(const Duration(seconds: 2));
    await shot('m4_stats_semaine_clair_legende');

    store.logs.clear();
    store.notifyListeners();
    await openStats(tester, dark: false);
    await checkEmpty(tester, 'clair', false);
    SL.dark = true;
  });
}
