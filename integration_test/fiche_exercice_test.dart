// M3 (CI 3D) : fiche exercice avec le mannequin 3D sur émulateur Android
// (Flutter GPU), lancé par tools/ci3d_drive.sh après moteur_3d_test.dart :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/fiche_exercice_test.dart -d emulator-5554
// Captures de 6 fiches variées (tirage, poussée, jambes, gainage, figure,
// isolation) en sombre et en clair, fiche avec muscles étirés, nom au toucher
// (réglage activé puis désactivé), ouverture de 20 fiches d'affilée (temps
// jusqu'au mannequin prêt, mémoire du processus). Relevé m3_releve.json.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;

/// Six fiches variées (famille → exercice).
const _fiches = {
  'tirage': 'traction-pronation',
  'poussee': 'dips',
  'jambes': 'souleve-de-terre-roumain',
  'gainage': 'planche-gainage',
  'figure': 'front-lever-tuck',
  'isolation': 'curl-halteres',
};

/// Fiche avec muscles étirés (teinte distincte).
const _etires = 'etirements-flechisseurs-de-hanche';

/// Fiche avec des muscles absents du modèle (liste sous le mannequin). M4b :
/// les muscles profonds sont remis (rowing australien : rhomboïdes allumés),
/// seuls les muscles absents du modèle source restent listés à part.
const _profonds = 'hollow-body-hold';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m3 = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m3_releve.json'] = const JsonEncoder.withIndent('  ').convert(m3);

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

  /// Contrôle sans référence de la vue du mannequin : figure, gris, rouge de
  /// la rampe, bleu des étirés.
  Future<Map<String, Object?>> stats(WidgetTester tester, bool dark) async {
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = sceneBackground(dark);
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    var total = 0, figure = 0, red = 0, gray = 0, blue = 0;
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
        if (b > r + 25 && b > 60) blue++;
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 40) gray++;
      }
    }
    image.dispose();
    return {
      'pixels': total,
      'figure': total == 0 ? 0 : figure / total,
      'rouge': total == 0 ? 0 : red / total,
      'bleu': total == 0 ? 0 : blue / total,
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

  Finder mannequinFinder() => find.byKey(const ValueKey('fiche-mannequin'));

  /// Liste défilante de la fiche au premier plan.
  Finder sheetList() => find
      .descendant(
        of: find.byType(ExerciseSheetScreen).last,
        matching: find.byType(Scrollable),
      )
      .first;

  bool sheetReady() =>
      find.byType(ExerciseSheetScreen).evaluate().length == 1 &&
      find
          .descendant(
            of: find.byType(ExerciseSheetScreen),
            matching: find.byType(Scrollable),
          )
          .evaluate()
          .isNotEmpty;

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty ? null : tester.state<Mannequin3DState>(f.last);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
  });

  Future<void> openDark(WidgetTester tester) async {
    SL.dark = true;
    store.settings
      ..theme = 'dark'
      ..sound = false
      ..vibration = false
      ..wakelock = false;
    await tester.pumpWidget(RepaintBoundary(key: _root, child: const SLApp()));
    await tester.pumpAndSettle();
  }

  /// Ouvre la fiche [id] et fait défiler jusqu'au mannequin, placé en haut
  /// de l'écran avec la légende et la liste en texte en dessous.
  Future<void> openSheet(
    WidgetTester tester,
    String id, {
    required bool dark,
  }) async {
    if (dark) {
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => ExerciseSheetScreen(id: id)),
      );
    } else {
      // Thème clair appliqué directement (comme M1-M2) : un SLApp déjà
      // monté ne relit pas le réglage de thème.
      SL.dark = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: _root,
          child: MaterialApp(
            key: ValueKey('clair-$id'),
            debugShowCheckedModeBanner: false,
            theme: buildTheme(false),
            home: ExerciseSheetScreen(id: id),
          ),
        ),
      );
    }
    // Émulateur lent : attendre la fiche construite (transition finie).
    await waitFor(tester, sheetReady, seconds: 30);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      mannequinFinder(),
      250,
      scrollable: sheetList(),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await Scrollable.ensureVisible(
      tester.element(mannequinFinder()),
      alignment: .04,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await waitFor(tester, () => mannequin(tester)?.available != null);
    expect(mannequin(tester)?.available, isTrue, reason: '$id : pas de 3D');
    // Rendu à la demande stabilisé (compilation des shaders au premier).
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> closeSheet(WidgetTester tester) async {
    appNavigator.currentState!.pop();
    await waitFor(
      tester,
      () => find.byType(ExerciseSheetScreen).evaluate().isEmpty,
      seconds: 30,
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<Map<String, Object?>> checkSheet(
    WidgetTester tester,
    String name,
    String id, {
    required bool dark,
  }) async {
    final s = await stats(tester, dark);
    final state = tester.state<ExerciseMannequinState>(
      find.byType(ExerciseMannequin),
    );
    final d = ContentLibrary.loaded!.detail(id)!;
    final out = <String, Object?>{
      'exercice': id,
      'vue': mannequin(tester)!.view.name,
      'vue_attendue': exerciseStartView(d.primaires, d.secondaires).name,
      'regions_allumees': state.muscles.intensities.length,
      'regions_etirees': state.muscles.stretched.length,
      'profonds': state.muscles.hidden,
      ...s,
    };
    expect(s['figure'] as double, greaterThan(.04), reason: name);
    expect(s['gris'] as double, greaterThan(.02), reason: name);
    expect(s['rouge'] as double, greaterThan(.002), reason: name);
    expect(s['couleurs'] as int, greaterThan(12), reason: name);
    expect(out['vue'], out['vue_attendue'], reason: name);
    return out;
  }

  testWidgets('M3 : 6 fiches, thème sombre, étirés, profonds, toucher', (
    tester,
  ) async {
    await openDark(tester);
    final fiches = <String, Object?>{};
    for (final e in _fiches.entries) {
      await openSheet(tester, e.value, dark: true);
      await shot('m3_fiche_${e.key}_sombre');
      fiches[e.key] = await checkSheet(tester, e.key, e.value, dark: true);
      m3['fiches_sombre'] = fiches;
      record();
      await closeSheet(tester);
    }

    // Muscles étirés : teinte bleue distincte.
    await openSheet(tester, _etires, dark: true);
    await shot('m3_fiche_etires_sombre');
    final s = await stats(tester, true);
    m3['etires'] = s;
    record();
    expect(s['bleu'] as double, greaterThan(.002), reason: 'étirés absents');
    expect(find.byType(AtlasRoleLegend), findsOneWidget);
    await closeSheet(tester);

    // Muscles profonds : listés sous le mannequin.
    await openSheet(tester, _profonds, dark: true);
    await shot('m3_fiche_profonds_sombre');
    final hidden = find.byKey(const ValueKey('fiche-mannequin-profonds'));
    m3['profonds'] = hidden.evaluate().isEmpty
        ? null
        : tester.widget<Text>(hidden).data;
    record();
    expect(hidden, findsOneWidget);

    // Toucher : nom du muscle (réglage activé), puis rien (désactivé).
    final rect = tester.getRect(find.byKey(const ValueKey('mannequin-view')));
    final at = Offset(
      rect.center.dx + rect.width * .07,
      rect.top + rect.height * .3,
    );
    await tester.tapAt(at);
    await tester.pump(const Duration(seconds: 2));
    final touched = mannequin(tester)!.touched;
    m3['toucher'] = touched?.label;
    record();
    await shot('m3_fiche_toucher');
    expect(touched, isNotNull, reason: 'aucun muscle touché');
    expect(find.byKey(const ValueKey('mannequin-bubble')), findsOneWidget);
    await Display3DSettings.instance.set(touchNames: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(at);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('mannequin-bubble')), findsNothing);
    m3['toucher_desactive'] = 'aucune bulle';
    record();
    await Display3DSettings.instance.set(touchNames: true);
    await tester.pump(const Duration(milliseconds: 300));

    // Rotation horizontale au doigt dans la fiche (la page ne défile pas).
    final before = mannequin(tester)!.view;
    await tester.timedDrag(
      find.byKey(const ValueKey('mannequin-view')),
      const Offset(-140, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump(const Duration(seconds: 2));
    await shot('m3_fiche_rotation');
    m3['rotation'] = 'depuis ${before.name}';
    record();
    await closeSheet(tester);
  });

  testWidgets('M3 : 6 fiches, thème clair', (tester) async {
    final fiches = <String, Object?>{};
    for (final e in _fiches.entries) {
      await openSheet(tester, e.value, dark: false);
      await shot('m3_fiche_${e.key}_clair');
      fiches[e.key] = await checkSheet(tester, e.key, e.value, dark: false);
      m3['fiches_clair'] = fiches;
      record();
    }
    await openSheet(tester, _etires, dark: false);
    await shot('m3_fiche_etires_clair');
    final s = await stats(tester, false);
    m3['etires_clair'] = s;
    record();
    expect(s['bleu'] as double, greaterThan(.002), reason: 'étirés absents');
    SL.dark = true;
  });

  testWidgets('M3 : 20 fiches d’affilée (temps, mémoire)', (tester) async {
    await openDark(tester);
    final ids = [
      ..._fiches.values,
      _etires,
      _profonds,
      'pompes',
      'squat-1-14',
      'rowing-barre-penche',
      'l-sit',
      'elevations-laterales',
      'hip-thrust',
      'face-pulls',
      'pistol-squat',
      'handstand-push-ups-mur',
      'planche-laterale',
      'ab-wheel',
      'muscle-up',
    ];
    expect(ids.length, 20);
    final rows = <Map<String, Object?>>[];
    final rss0 = ProcessInfo.currentRss;
    for (final id in ids) {
      final watch = Stopwatch()..start();
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => ExerciseSheetScreen(id: id)),
      );
      await tester.pump();
      // Liste paresseuse : le mannequin est construit quand l'utilisateur
      // fait défiler la fiche jusqu'à la section Muscles.
      await waitFor(tester, sheetReady, seconds: 30);
      await tester.scrollUntilVisible(
        mannequinFinder(),
        400,
        scrollable: sheetList(),
      );
      final visible = watch.elapsedMilliseconds;
      await waitFor(tester, () => mannequin(tester)?.available != null);
      final ready = watch.elapsedMilliseconds;
      rows.add({
        'exercice': id,
        'mannequin_visible_ms': visible,
        'mannequin_pret_ms': ready,
        'pret_apres_visible_ms': ready - visible,
        'rss_mo': (ProcessInfo.currentRss / 1048576).toStringAsFixed(1),
      });
      m3['vingt_fiches'] = {
        'rss_depart_mo': (rss0 / 1048576).toStringAsFixed(1),
        'fiches': rows,
      };
      record();
      expect(mannequin(tester)?.available, isTrue, reason: id);
      await tester.pump(const Duration(milliseconds: 400));
      await closeSheet(tester);
    }
    final after = <int>[
      for (final r in rows.skip(1)) r['pret_apres_visible_ms']! as int,
    ]..sort();
    m3['vingt_fiches'] = {
      'rss_depart_mo': (rss0 / 1048576).toStringAsFixed(1),
      'rss_fin_mo': (ProcessInfo.currentRss / 1048576).toStringAsFixed(1),
      'rss_max_mo': (ProcessInfo.maxRss / 1048576).toStringAsFixed(1),
      'premiere_fiche_pret_apres_visible_ms':
          rows.first['pret_apres_visible_ms'],
      'suivantes_mediane_ms': after[after.length ~/ 2],
      'suivantes_max_ms': after.last,
      'fiches': rows,
    };
    record();
    await shot('m3_vingt_fiches_fin');

    // Création du mannequin seule (modèle déjà en mémoire) : ce que coûte
    // l'ouverture d'une fiche au fil UI, hors défilement.
    final creations = <int>[];
    for (var i = 0; i < 5; i++) {
      final w = Stopwatch()..start();
      await MannequinScene.create();
      creations.add(w.elapsedMilliseconds);
    }
    m3['creation_mannequin_ms'] = creations;
    record();
  });
}
