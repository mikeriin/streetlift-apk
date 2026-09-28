// M4c (CI 3D) : zoom au pincement du mannequin et filtres normalisés, sur
// émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/zoom_filtres_m4c_test.dart -d emulator-5554
// Captures : écran Anatomie (groupe Avant-bras) en vue d'ensemble, zoomé au
// pincement sur un avant-bras (vrai geste à deux doigts), nom au toucher
// une fois zoomé, déplacement à deux doigts, retour par double toucher ;
// fiche exercice (curl poignet, clair) : glisser vertical = la page défile,
// pincement = zoom sans défilement ; menus « Filtres » ouverts sur la
// bibliothèque d'exercices, le catalogue WOD et l'écran Anatomie, en
// sombre et en clair, puis leurs puces. Relevé m4c_releve.json.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/filter_menu.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_catalog.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _limit = Timeout(Duration(minutes: 5));

/// Fiche dont les muscles principaux sont ceux de l'avant-bras.
const _fiche = 'curl-poignet';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m4c = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m4c_releve.json'] = const JsonEncoder.withIndent('  ').convert(m4c);

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
        final diff = [(r - br).abs(), (g - bgG).abs(), (b - bb).abs()];
        if (diff.reduce((a, c) => a > c ? a : c) <= 12) continue;
        figure++;
        if (r > 90 && r > g + 40 && r > b + 40) red++;
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 30) gray++;
      }
    }
    image.dispose();
    return {
      'figure': total == 0 ? 0 : figure / total,
      'rouge': total == 0 ? 0 : red / total,
      'gris': total == 0 ? 0 : gray / total,
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

  Future<void> settle3d(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> pumpHome(WidgetTester tester, Widget home, bool dark) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m4c-$dark-${home.runtimeType}-${home.key}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          home: home,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Vrai pincement à deux doigts autour de [center] : écart de [from] à
  /// [to] pixels (entre les deux doigts), puis déplacement commun [pan].
  Future<void> pinch(
    WidgetTester tester,
    Offset center, {
    double from = 40,
    double to = 160,
    Offset pan = Offset.zero,
  }) async {
    final a = await tester.startGesture(
      center - Offset(from / 2, 0),
      pointer: 11,
    );
    await tester.pump(const Duration(milliseconds: 30));
    final b = await tester.startGesture(
      center + Offset(from / 2, 0),
      pointer: 12,
    );
    await tester.pump(const Duration(milliseconds: 30));
    const steps = 8;
    final step = (to - from) / 2 / steps;
    for (var i = 0; i < steps; i++) {
      await a.moveBy(Offset(-step, 0) + pan / steps.toDouble());
      await b.moveBy(Offset(step, 0) + pan / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 40));
    }
    await a.up();
    await b.up();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
  });

  // ------------------------------------------------------- zoom Anatomie --

  testWidgets('M4c : zoom au pincement, écran Anatomie, sombre', (
    tester,
  ) async {
    AnatomyScreen.session = const AnatomyFilters(groups: {'avant-bras'});
    await pumpHome(tester, const AnatomyScreen(), true);
    await ready(tester);
    final state = mannequin(tester)!;
    expect(state.view, MannequinView.face);
    await shot('m4c_anatomie_1x');
    final before = await pixels(tester, true);
    // Point au milieu de l'avant-bras de gauche à l'écran (règle du toucher
    // de l'application, sur une grille) : pas un bord, que la moindre
    // imprécision ferait manquer.
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    final hits = <Offset>[];
    for (var j = 0; j < 30; j++) {
      for (var i = 0; i < 30; i++) {
        final q = Offset(
          rect.width * (.05 + .45 * i / 29),
          rect.height * (.25 + .5 * j / 29),
        );
        final r = state.scene!.pick(state.camera!, q, state.viewSize);
        if (r != null && r.groupe == 'avant-bras') hits.add(q);
      }
    }
    expect(hits, isNotEmpty, reason: 'aucun point sur un avant-bras');
    final mean =
        hits.fold(Offset.zero, (a, b) => a + b) / hits.length.toDouble();
    Offset? p;
    for (final h in hits) {
      if (p == null || (h - mean).distance < (p - mean).distance) p = h;
    }
    final r0 = state.scene!.pick(state.camera!, p!, state.viewSize)!;
    m4c['anatomie_1x'] = {...before, 'point': p.toString(), 'muscle': r0.label};
    record();

    // Vrai pincement centré sur l'avant-bras : 40 → 160 px (4×).
    await pinch(tester, rect.topLeft + p);
    await settle3d(tester);
    final z = state.zoom;
    final r1 = state.scene!.pick(state.camera!, p, state.viewSize);
    await shot('m4c_anatomie_zoom');
    final zoomed = await pixels(tester, true);
    m4c['anatomie_zoom'] = {
      ...zoomed,
      'echelle': z.scale,
      'muscle_sous_les_doigts': r1?.label,
    };
    record();
    expect(z.scale, greaterThan(3), reason: 'zoom insuffisant');
    expect(z.scale, lessThanOrEqualTo(4.0001));
    // Point focal stable : le même muscle reste sous les doigts.
    expect(r1?.groupe, 'avant-bras');
    expect(zoomed['rouge'] as double, greaterThan(before['rouge'] as double));

    // Toucher une fois zoomé : le lancer de rayon tient compte du zoom.
    await tester.tapAt(rect.topLeft + p);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2));
    final touched = state.touched;
    m4c['toucher_zoom'] = touched?.label;
    record();
    await shot('m4c_anatomie_zoom_toucher');
    expect(touched?.groupe, 'avant-bras');

    // Déplacement de la vue à deux doigts (sans changer d'échelle).
    final o0 = state.zoom.offset.clone();
    await pinch(
      tester,
      rect.center,
      from: 80,
      to: 80,
      pan: const Offset(0, 90),
    );
    await settle3d(tester);
    final moved = (state.zoom.offset - o0).length;
    m4c['deplacement_deux_doigts'] = moved;
    record();
    await shot('m4c_anatomie_zoom_deplace');
    expect(moved, greaterThan(0));

    // Double toucher : retour à la vue par défaut.
    await tester.tapAt(rect.center);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(rect.center);
    await settle3d(tester);
    m4c['double_toucher'] = state.zoom.isDefault;
    record();
    await shot('m4c_anatomie_double_toucher');
    expect(state.zoom.isDefault, isTrue);

    // Les boutons de vue remettent aussi le zoom par défaut.
    state.pinchTo(3, rect.size.center(Offset.zero));
    await tester.pump(const Duration(seconds: 2));
    expect(state.zoom.scale, closeTo(3, 1e-6));
    final dos = find.byKey(const ValueKey('mannequin-view-dos'));
    await tester.ensureVisible(dos);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(dos);
    await settle3d(tester);
    m4c['bouton_vue_remet_zoom'] = state.zoom.isDefault;
    record();
    await shot('m4c_anatomie_dos_apres_zoom');
    expect(state.zoom.isDefault, isTrue);
    AnatomyScreen.session = null;
  }, timeout: _limit);

  // --------------------------------------------- fiche : page qui défile --

  testWidgets('M4c : fiche exercice, zoom dans une page qui défile, clair', (
    tester,
  ) async {
    await pumpHome(tester, const ExerciseSheetScreen(id: _fiche), false);
    Finder list() => find
        .descendant(
          of: find.byType(ExerciseSheetScreen).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await waitFor(tester, () => list().evaluate().isNotEmpty, seconds: 30);
    await tester.pump(const Duration(milliseconds: 300));
    final m = find.byKey(const ValueKey('fiche-mannequin'));
    await tester.scrollUntilVisible(m, 250, scrollable: list());
    await tester.pump(const Duration(milliseconds: 300));
    await Scrollable.ensureVisible(tester.element(m), alignment: .04);
    await ready(tester);
    final state = mannequin(tester)!;
    double offset() => tester.state<ScrollableState>(list()).position.pixels;
    final view = find.byKey(const ValueKey('mannequin-view'));

    // Un doigt vertical sur le mannequin : la page défile, pas de zoom.
    final o0 = offset();
    await tester.timedDrag(
      view,
      const Offset(0, -120),
      const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(seconds: 1));
    final o1 = offset();
    expect(o1, greaterThan(o0 + 40), reason: 'la page n’a pas défilé');
    expect(state.zoom.isDefault, isTrue);
    await Scrollable.ensureVisible(tester.element(m), alignment: .04);
    await tester.pump(const Duration(seconds: 1));

    // Pincement : zoom, la page ne bouge pas.
    final o2 = offset();
    final rect = tester.getRect(view);
    await pinch(tester, rect.center, from: 50, to: 150);
    await settle3d(tester);
    final o3 = offset();
    m4c['fiche'] = {
      'defilement_un_doigt': o1 - o0,
      'defilement_pendant_pincement': o3 - o2,
      'echelle': state.zoom.scale,
    };
    record();
    await shot('m4c_fiche_zoom_clair');
    expect(state.zoom.scale, greaterThan(2));
    expect((o3 - o2).abs(), lessThan(1), reason: 'la page a défilé');
    SL.dark = true;
  }, timeout: _limit);

  // --------------------------------------------------------- filtres --

  Future<void> openMenu(WidgetTester tester, String prefix) async {
    await tester.tap(find.byKey(ValueKey('$prefix-filters')));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> tapItem(WidgetTester tester, String key) async {
    final item = find.byKey(ValueKey(key)).first;
    await tester.ensureVisible(item);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(item);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> closeMenu(WidgetTester tester) async {
    await tester.tapAt(const Offset(4, 4));
    await tester.pump(const Duration(milliseconds: 600));
  }

  for (final dark in [true, false]) {
    final theme = dark ? 'sombre' : 'clair';
    testWidgets('M4c : menus « Filtres », $theme', (tester) async {
      final out = <String, Object?>{};
      // Bibliothèque d'exercices.
      ExerciseLibraryScreen.session = const FilterSelection();
      await pumpHome(tester, const ExerciseLibraryScreen(), dark);
      await tester.pump(const Duration(seconds: 1));
      await openMenu(tester, 'library');
      await tapItem(tester, 'library-filter-type:tirage_vertical');
      await tapItem(tester, 'library-filter-type:poussee_verticale');
      await tapItem(tester, 'library-filter-cat-materiel');
      await tapItem(tester, 'library-filter-mat:barre_fixe');
      await tester.ensureVisible(
        find.byKey(const ValueKey('library-filter-cat-type')).first,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await shot('m4c_filtres_bibliotheque_$theme');
      expect(find.text('Filtres · 3'), findsOneWidget);
      await closeMenu(tester);
      await shot('m4c_filtres_bibliotheque_puces_$theme');
      out['bibliotheque'] = ExerciseLibraryScreen.session.toString();
      ExerciseLibraryScreen.session = const FilterSelection();

      // Catalogue WOD.
      WodCatalogScreen.session = const FilterSelection();
      await pumpHome(tester, const WodCatalogScreen(), dark);
      await tester.pump(const Duration(seconds: 2));
      await openMenu(tester, 'wod');
      await tapItem(tester, 'wod-filter-st:locked');
      await tapItem(tester, 'wod-filter-cat-format');
      await tapItem(tester, 'wod-filter-ty:amrap');
      await tapItem(tester, 'wod-filter-ty:emom');
      await tester.ensureVisible(
        find.byKey(const ValueKey('wod-filter-cat-acces')).first,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await shot('m4c_filtres_wod_$theme');
      expect(find.text('Filtres · 3'), findsOneWidget);
      await closeMenu(tester);
      await shot('m4c_filtres_wod_puces_$theme');
      out['wod'] = WodCatalogScreen.session.toString();
      WodCatalogScreen.session = const FilterSelection();

      // Écran Anatomie (mannequin 3D sous le menu).
      AnatomyScreen.session = null;
      await pumpHome(tester, const AnatomyScreen(), dark);
      await ready(tester);
      await openMenu(tester, 'anatomy');
      await tapItem(tester, 'anatomy-filter-dos');
      await tapItem(tester, 'anatomy-filter-ischios');
      await tester.ensureVisible(
        find.byKey(const ValueKey('anatomy-filter-cat-groupes')).first,
      );
      await tester.pump(const Duration(seconds: 2));
      await shot('m4c_filtres_anatomie_$theme');
      expect(find.text('Filtres · 4'), findsOneWidget);
      await closeMenu(tester);
      await tester.pump(const Duration(seconds: 2));
      await shot('m4c_filtres_anatomie_puces_$theme');
      out['anatomie'] = AnatomyScreen.session?.orderedGroups;
      m4c['filtres_$theme'] = out;
      record();
      AnatomyScreen.session = null;
      SL.dark = true;
    }, timeout: _limit);
  }
}
