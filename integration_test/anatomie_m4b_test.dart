// M4b (CI 3D) : mannequin complet en transparence, sur émulateur Android
// (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/anatomie_m4b_test.dart -d emulator-5554
// Captures : muscles profonds seuls allumés (rhomboïdes, vaste
// intermédiaire, subscapulaire, petit pectoral) vus à travers les autres
// sous les 4 vues en sombre, 2 en clair, bulle « (profond) » au toucher ;
// écran Anatomie avec plusieurs filtres cochés, menu ouvert, muscles
// profonds masqués, en sombre et en clair ; fiche exercice (rowing
// australien : rhomboïdes principaux) et STATS en transparence, sombre et
// clair. Temps d'image de l'écran Moteur 3D avant (muscles opaques, sans les
// muscles cachés au repos : rendu de 5.3.0) et après (5.3.1). Relevé
// m4b_releve.json.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_performance.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _limit = Timeout(Duration(minutes: 5));

/// Muscles profonds allumés seuls : ils ne se voient qu'à travers les
/// muscles superficiels translucides.
const _deepLit = {
  'rhomboid_major_left': kIntensityPrimary,
  'rhomboid_major_right': kIntensityPrimary,
  'rhomboid_minor_left': kIntensityPrimary,
  'rhomboid_minor_right': kIntensityPrimary,
  'vastus_intermedius_left': kIntensityPrimary,
  'vastus_intermedius_right': kIntensityPrimary,
  'subscapularis_left': kIntensitySecondary,
  'subscapularis_right': kIntensitySecondary,
  'pectoralis_minor_left': kIntensitySecondary,
  'pectoralis_minor_right': kIntensitySecondary,
};

/// Fiche dont les principaux comptent un muscle profond (rhomboïdes).
const _fiche = 'rowing-australien-barre-haute';

/// Semaine type (comme integration_test/stats_semaine_test.dart).
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
  final m4b = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m4b_releve.json'] = const JsonEncoder.withIndent('  ').convert(m4b);

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
    final rect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
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
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 30) gray++;
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

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty ? null : tester.state<Mannequin3DState>(f.last);
  }

  Future<void> ready(WidgetTester tester) async {
    await waitFor(tester, () => mannequin(tester)?.available != null);
    expect(mannequin(tester)?.available, isTrue, reason: 'pas de 3D');
    // Rendu à la demande stabilisé (compilation des shaders au premier).
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> setView(WidgetTester tester, MannequinView view) async {
    await tester.tap(find.byKey(ValueKey('mannequin-view-${view.name}')));
    // Transition (520 ms) puis rendu à la demande stabilisé.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpHome(WidgetTester tester, Widget home, bool dark) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m4b-$dark-${home.runtimeType}-${home.key}'),
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
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
  });

  // --------------------------------------------- muscles profonds allumés --

  Future<void> deepViews(
    WidgetTester tester, {
    required bool dark,
    required List<MannequinView> views,
  }) async {
    final theme = dark ? 'sombre' : 'clair';
    await pumpHome(
      tester,
      const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Mannequin3D(
                key: ValueKey('m4b-profonds'),
                intensities: _deepLit,
                view: MannequinView.dos,
                height: 520,
                semanticLabel: 'Muscles profonds allumés',
              ),
            ),
          ),
        ),
      ),
      dark,
    );
    await ready(tester);
    final out = <String, Object?>{};
    for (final v in views) {
      await setView(tester, v);
      await shot('m4b_profonds_${theme}_${v.name}');
      final s = await pixels(tester, dark);
      out[v.name] = s;
      m4b['profonds_$theme'] = out;
      record();
      expect(s['figure'] as double, greaterThan(.04), reason: v.name);
      expect(s['gris'] as double, greaterThan(.02), reason: v.name);
      // Aucun muscle allumé n'est superficiel : le rouge ne peut venir que
      // des muscles profonds vus à travers les autres.
      expect(s['rouge'] as double, greaterThan(.001), reason: v.name);
    }
  }

  testWidgets('M4b : muscles profonds allumés, 4 vues, sombre, toucher', (
    tester,
  ) async {
    await deepViews(tester, dark: true, views: MannequinView.values);
    // Rotation par petits pas (≈ 14° chacun) depuis le dos : tri des
    // surfaces translucides recalculé à chaque image, aucun muscle ne doit
    // disparaître ni clignoter d'une image à l'autre (captures comparées).
    await setView(tester, MannequinView.dos);
    final turn = <Object?>[];
    for (var i = 1; i <= 6; i++) {
      await tester.timedDrag(
        find.byKey(const ValueKey('mannequin-view')),
        const Offset(-20, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pump(const Duration(seconds: 2));
      await shot('m4b_profonds_rotation_$i');
      final s = await pixels(tester, true);
      turn.add(s);
      m4b['rotation'] = turn;
      record();
      expect(s['rouge'] as double, greaterThan(.001), reason: 'pas $i');
      expect(s['gris'] as double, greaterThan(.02), reason: 'pas $i');
    }
    // Toucher : vue de dos, un point où le rayon traverse un rhomboïde
    // (cherché sur une grille avec la règle du toucher de l'application),
    // puis le vrai geste sur l'écran.
    await setView(tester, MannequinView.dos);
    final state = mannequin(tester)!;
    final scene = state.scene!;
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    Offset? target;
    for (var j = 0; j < 24 && target == null; j++) {
      for (var i = 0; i < 16 && target == null; i++) {
        final p = Offset(
          rect.width * (.3 + .4 * i / 15),
          rect.height * (.12 + .25 * j / 23),
        );
        final r = scene.pick(state.camera!, p, state.viewSize);
        if (r != null && r.cle.startsWith('rhomboid')) target = p;
      }
    }
    m4b['toucher_point'] = target?.toString();
    expect(target, isNotNull, reason: 'aucun point sur un rhomboïde');
    await tester.tapAt(rect.topLeft + target!);
    await tester.pump(const Duration(seconds: 2));
    final touched = mannequin(tester)!.touched;
    m4b['toucher'] = touched?.label;
    record();
    await shot('m4b_profonds_toucher');
    expect(touched?.label, contains('(profond)'));
    expect(find.byKey(const ValueKey('mannequin-bubble')), findsOneWidget);
  }, timeout: _limit);

  testWidgets('M4b : muscles profonds allumés, clair', (tester) async {
    await deepViews(
      tester,
      dark: false,
      views: const [MannequinView.dos, MannequinView.face],
    );
    SL.dark = true;
  }, timeout: _limit);

  // ------------------------------------------------------ écran Anatomie --

  // CheckboxMenuButton transmet sa clé à son MenuItemButton : deux widgets.
  Finder filter(String key) =>
      find.byKey(ValueKey('anatomy-filter-$key')).first;

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('anatomy-filters')));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> closeMenu(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapItem(WidgetTester tester, String key) async {
    await tester.ensureVisible(filter(key));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(filter(key));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('M4b : écran Anatomie, filtres à cocher, sombre', (tester) async {
    AnatomyScreen.session = null;
    SL.dark = true;
    store.settings
      ..theme = 'dark'
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    await tester.pumpWidget(RepaintBoundary(key: _root, child: const SLApp()));
    await tester.pumpAndSettle();
    appNavigator.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const AnatomyScreen()),
    );
    await waitFor(
      tester,
      () => find.byType(AnatomyScreen).evaluate().isNotEmpty,
      seconds: 30,
    );
    await ready(tester);
    // Plusieurs filtres cochés en même temps (menu ouvert, capturé).
    await openMenu(tester);
    for (final g in ['pectoraux', 'dos', 'quadriceps']) {
      await tapItem(tester, g);
    }
    await tester.pump(const Duration(seconds: 2));
    await shot('m4b_anatomie_sombre_menu');
    final state = tester.state<AnatomyScreenState>(find.byType(AnatomyScreen));
    m4b['anatomie_filtres'] = state.filters.orderedGroups;
    expect(state.groups, {'pectoraux', 'dos', 'quadriceps'});
    expect(find.text('Filtres · 3'), findsOneWidget); // M6c : sans « Os »
    await closeMenu(tester);
    expect(
      find.byKey(const ValueKey('anatomy-filter-dos')),
      findsNothing,
      reason: 'menu resté ouvert',
    );
    final views = <String, Object?>{};
    for (final v in [MannequinView.troisQuarts, MannequinView.dos]) {
      await setView(tester, v);
      await shot('m4b_anatomie_sombre_multi_${v.name}');
      final s = await pixels(tester, true);
      views[v.name] = s;
      m4b['anatomie_sombre'] = views;
      record();
      expect(s['rouge'] as double, greaterThan(.01), reason: v.name);
      expect(s['gris'] as double, greaterThan(.01), reason: v.name);
    }
    // M6b : filtre « Muscles profonds » retiré (écorché sans couche
    // profonde) : la case n'existe plus, la vue reste la même.
    await openMenu(tester);
    expect(find.byKey(const ValueKey('anatomy-filter-deep')), findsNothing);
    await closeMenu(tester);
    await tester.pump(const Duration(seconds: 2));
    await shot('m4b_anatomie_sombre_sans_profonds');
    views['sans_profonds'] = await pixels(tester, true);
    record();
    // Résumé texte sous les boutons : la liste défile en glissant sur les
    // boutons de vue (glisser sur le mannequin le fait tourner).
    final list = find.byKey(const ValueKey('anatomy-group-list'));
    for (var i = 0; i < 4 && list.evaluate().isEmpty; i++) {
      await tester.drag(
        find.byKey(const ValueKey('mannequin-views')),
        const Offset(0, -300),
      );
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(list, findsOneWidget, reason: 'résumé des groupes absent');
    await Scrollable.ensureVisible(tester.element(list), alignment: .5);
    await tester.pump(const Duration(seconds: 1));
    await shot('m4b_anatomie_sombre_resume');
    AnatomyScreen.session = null;
  }, timeout: _limit);

  testWidgets('M4b : écran Anatomie, filtres à cocher, clair', (tester) async {
    AnatomyScreen.session = const AnatomyFilters(groups: {'dos', 'ischios'});
    await pumpHome(tester, const AnatomyScreen(), false);
    await ready(tester);
    await setView(tester, MannequinView.dos);
    await shot('m4b_anatomie_clair_dos');
    final s = await pixels(tester, false);
    m4b['anatomie_clair'] = s;
    record();
    expect(s['rouge'] as double, greaterThan(.01));
    await openMenu(tester);
    await tester.pump(const Duration(seconds: 1));
    await shot('m4b_anatomie_clair_menu');
    await closeMenu(tester);
    AnatomyScreen.session = null;
    SL.dark = true;
  }, timeout: _limit);

  // ------------------------------------------ fiche exercice et STATS --

  Finder sheetList() => find
      .descendant(
        of: find.byType(ExerciseSheetScreen).last,
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> openSheet(WidgetTester tester, bool dark) async {
    await pumpHome(tester, const ExerciseSheetScreen(id: _fiche), dark);
    await waitFor(
      tester,
      () => find
          .descendant(
            of: find.byType(ExerciseSheetScreen),
            matching: find.byType(Scrollable),
          )
          .evaluate()
          .isNotEmpty,
      seconds: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final m = find.byKey(const ValueKey('fiche-mannequin'));
    await tester.scrollUntilVisible(m, 250, scrollable: sheetList());
    await tester.pump(const Duration(milliseconds: 300));
    await Scrollable.ensureVisible(tester.element(m), alignment: .04);
    await ready(tester);
  }

  testWidgets('M4b : fiche exercice en transparence, sombre et clair', (
    tester,
  ) async {
    final out = <String, Object?>{};
    for (final dark in [true, false]) {
      final theme = dark ? 'sombre' : 'clair';
      await openSheet(tester, dark);
      await shot('m4b_fiche_$theme');
      final s = await pixels(tester, dark);
      final state = mannequin(tester)!;
      out[theme] = {
        ...s,
        'vue': state.view.name,
        'rhomboides_allumes': [
          for (final id in _deepLit.keys)
            if (id.startsWith('rhomboid')) id,
        ].every((id) => state.widget.intensities[id] == kIntensityPrimary),
      };
      m4b['fiche'] = out;
      record();
      expect(s['rouge'] as double, greaterThan(.005), reason: theme);
      expect(
        (out[theme]! as Map)['rhomboides_allumes'],
        isTrue,
        reason: 'rhomboïdes (profonds) non allumés',
      );
    }
    SL.dark = true;
  }, timeout: _limit);

  testWidgets('M4b : STATS en transparence, sombre et clair', (tester) async {
    _fillWeek();
    const stats = StatsScreen(
      initialSection: StatsSection.performance,
      standalone: true,
    );
    final out = <String, Object?>{};
    for (final dark in [true, false]) {
      final theme = dark ? 'sombre' : 'clair';
      await pumpHome(tester, stats, dark);
      await waitFor(
        tester,
        () => find.byType(StatsPerformance).evaluate().isNotEmpty,
        seconds: 30,
      );
      await tester.pump(const Duration(milliseconds: 300));
      final m = find.byKey(const ValueKey('stats-mannequin'));
      await tester.scrollUntilVisible(
        m,
        250,
        scrollable: find
            .descendant(
              of: find.byType(StatsPerformance),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      await Scrollable.ensureVisible(tester.element(m), alignment: .03);
      await ready(tester);
      await setView(tester, MannequinView.dos);
      await shot('m4b_stats_$theme');
      final s = await pixels(tester, dark);
      out[theme] = s;
      m4b['stats'] = out;
      record();
      expect(s['rouge'] as double, greaterThan(.01), reason: theme);
    }
    SL.dark = true;
  }, timeout: _limit);

  // ---------------------------------------------- Moteur 3D avant / après --

  Engine3DScreenState engine(WidgetTester tester) =>
      tester.state<Engine3DScreenState>(find.byType(Engine3DScreen));

  Future<Map<String, Object?>> measure(WidgetTester tester, String name) async {
    await pumpHome(
      tester,
      Engine3DScreen(key: ValueKey(name), autoMeasure: false),
      true,
    );
    await waitFor(
      tester,
      () =>
          find.byType(Engine3DScreen).evaluate().isNotEmpty &&
          engine(tester).ready,
    );
    expect(engine(tester).ready, isTrue, reason: '$name : pas de 3D');
    await tester.pump(const Duration(seconds: 3));
    await shot('m4b_moteur3d_$name');
    engine(tester).startMeasure();
    await waitFor(tester, () => engine(tester).stats != null, seconds: 45);
    final st = engine(tester).stats;
    expect(st, isNotNull, reason: '$name : mesure non terminée');
    return {
      'images': st!.frames,
      'images_par_s': st.fps,
      'temps_moyen_ms': st.meanMs,
      'p99_ms': st.p99Ms,
    };
  }

  testWidgets('M4b : Moteur 3D, temps d’image avant / après', (tester) async {
    final out = <String, Object?>{
      'note':
          'émulateur, rendu logiciel, build debug : comparaison seulement ; '
          'la mesure qui compte est celle du téléphone',
    };
    // Avant (rendu de 5.3.0) : muscles opaques, sans les régions cachées
    // au repos ni le platysma (absents du modèle jusqu'à 5.3.0).
    MannequinScene.debugOpacity = 1;
    MannequinScene.debugHidden = (map) => {
      ...map.hiddenAtRest,
      'platysma_left',
      'platysma_right',
    };
    try {
      out['avant_opaque_5_3_0'] = await measure(tester, 'avant');
    } finally {
      MannequinScene.debugOpacity = null;
      MannequinScene.debugHidden = null;
    }
    m4b['moteur3d'] = out;
    record();
    out['apres_transparent_5_3_1'] = await measure(tester, 'apres');
    m4b['moteur3d'] = out;
    record();
  }, timeout: _limit);
}
