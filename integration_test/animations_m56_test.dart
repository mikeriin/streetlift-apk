// M56 (CI 3D) : mannequin musclé, postures, démonstrations d'exercice, carte
// « Koach · séance du jour » et préchargement, sur
// émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/animations_m56_test.dart -d emulator-5554
// Correction 1 : plus de boucle ; la fiche montre la position de départ,
// puis la position de fin (puce), avec un fondu doux. Captures : pour
// chaque pilote (traction pronation, dips, back squat), la fiche exercice à
// la position de départ, à mi-fondu, à la position de fin, et une vue 3/4 ;
// animations réduites (passage instantané) ;
// carte Koach de la séance du jour (page à part, avant l'exercice 1) ouverte
// et repliée, sombre et clair.
// Écran Anatomie : 4 postures de référence en 3/4 et le modèle au repos
// (face, dos). Préchargement : ouverture d'un mannequin avant (désactivé) et
// après le préchargement (première image, images perdues).
// Relevé m56_releve.json (cadre du mannequin dans chaque capture, contrôles
// sans référence : figure, gris, rouge).
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/koach_day_card.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/mannequin_preload.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _limit = Timeout(Duration(minutes: 5));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m6 = <String, Object?>{}; // relevé (clé m56_releve.json)
  binding.reportData = data;

  void record() =>
      data['m56_releve.json'] = const JsonEncoder.withIndent('  ').convert(m6);

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

  Future<Map<String, Object?>> check(WidgetTester tester, bool dark) async {
    final rect = tester.getRect(
      find.byKey(const ValueKey('mannequin-view')).first,
    );
    final image = await grab();
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final bg = sceneBackground(dark);
    final br = (bg.r * 255).round(), bgG = (bg.g * 255).round();
    final bb = (bg.b * 255).round();
    var total = 0, figure = 0, red = 0, gray = 0;
    for (var y = rect.top; y < rect.bottom; y += 2) {
      for (var x = rect.left; x < rect.right; x += 2) {
        final px = (x * _ratio).round().clamp(0, image.width - 1);
        final py = (y * _ratio).round().clamp(0, image.height - 1);
        final o = (py * image.width + px) * 4;
        final r = rgba.getUint8(o), g = rgba.getUint8(o + 1);
        final b = rgba.getUint8(o + 2);
        total++;
        if ((r - br).abs() <= 12 &&
            (g - bgG).abs() <= 12 &&
            (b - bb).abs() <= 12) {
          continue;
        }
        figure++;
        if (isRed(r, g, b)) red++;
        if ((r - g).abs() < 24 && (g - b).abs() < 24 && r > 30) gray++;
      }
    }
    image.dispose();
    return {
      'cadre': [rect.left, rect.top, rect.width, rect.height],
      'figure': total == 0 ? 0 : figure / total,
      'rouge': total == 0 ? 0 : red / total,
      'gris': total == 0 ? 0 : gray / total,
    };
  }

  Future<void> waitFor(
    WidgetTester tester,
    bool Function() done, {
    int seconds = 90,
  }) async {
    for (var i = 0; i < seconds * 20 && !done(); i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty
        ? null
        : tester.state<Mannequin3DState>(f.first);
  }

  Future<void> pumpHome(
    WidgetTester tester,
    Widget home,
    bool dark, {
    bool reduce = false,
  }) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m56-$dark-$reduce-${home.key}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: child!,
          ),
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
    await ClipRegistry.load();
  });

  // -------------------------------------------------- pilotes animés --

  Future<void> pilot(WidgetTester tester, String id) async {
    await pumpHome(
      tester,
      ExerciseSheetScreen(key: ValueKey('m56-$id'), id: id),
      true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    expect(find.byType(ExerciseAnimation), findsOneWidget);
    final clip = state.widget.clip!;
    final positions = clip.shownPositions;
    expect(positions.length, 2, reason: 'départ et fin');
    final out = <String, Object?>{
      'vue': state.view.name,
      'materiel': state.scene!.equipmentNames.toList(),
      'tempo': clip.tempo,
      'positions': [for (final p in positions) p.name],
    };
    // Position de départ, immobile.
    await tester.pump(const Duration(seconds: 2));
    expect(state.clipPosition, 0);
    final t0 = state.clipTime;
    await tester.pump(const Duration(seconds: 1));
    expect(state.clipTime, t0);
    expect(state.view.name, clip.view);
    expect(find.byKey(const ValueKey('mannequin-phase')), findsOneWidget);
    final chips = find.byKey(const ValueKey('mannequin-key-positions'));
    expect(chips, findsOneWidget);
    final shots = <String, Object?>{};
    Future<void> capture(String key) async {
      await tester.pump(const Duration(seconds: 1));
      await shot('m56_${id}_$key');
      final s = await check(tester, true);
      s['phase'] = clip.phaseAt(state.clipTime).name;
      shots[key] = s;
      expect(s['figure'] as double, greaterThan(.03), reason: '$id $key');
      expect(s['rouge'] as double, greaterThan(.001), reason: '$id $key');
      expect(s['gris'] as double, greaterThan(.01), reason: '$id $key');
    }

    await capture('depart');
    // Fondu vers la position de fin : image à mi-chemin, puis fin.
    state.showClipPosition(1);
    await tester.pump(const Duration(milliseconds: 375));
    expect(state.posing, isTrue);
    await capture('fondu');
    await tester.pump(const Duration(seconds: 1));
    expect(state.posing, isFalse);
    expect(state.clipPosition, 1);
    expect(state.clipTime, clip.wrap(positions[1].time));
    await capture('fin');
    // Retour au départ par la puce.
    await tester.ensureVisible(chips);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.descendant(of: chips, matching: find.byType(ChoiceChip)).first,
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(state.clipPosition, 0);
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump(const Duration(seconds: 1));
    out['captures'] = shots;
    m6[id] = out;
    record();
    // Vue 3/4 à la position de fin.
    state.showClipPosition(1);
    // Boutons de vue sous l'écran (émulateur 360 × 640 dp) : vue imposée.
    state.setView(MannequinView.troisQuarts);
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
    await shot('m56_${id}_troisquarts');
    out['troisquarts'] = await check(tester, true);
    m6[id] = out;
    record();
  }

  for (final id in const ['traction-pronation', 'dips', 'back-squat']) {
    testWidgets('M56 : $id, positions de départ et de fin dans sa fiche', (
      tester,
    ) async {
      await pilot(tester, id);
    }, timeout: _limit);
  }

  testWidgets('M56 : animations réduites, passage instantané (clair)', (
    tester,
  ) async {
    await pumpHome(
      tester,
      const ExerciseSheetScreen(key: ValueKey('m56-reduit'), id: 'back-squat'),
      false,
      reduce: true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    await tester.pump(const Duration(seconds: 2));
    final chips = find.byKey(const ValueKey('mannequin-key-positions'));
    expect(chips, findsOneWidget);
    await tester.ensureVisible(chips);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.descendant(of: chips, matching: find.byType(ChoiceChip)).last,
    );
    await tester.pump();
    // Sans animation : la position de fin est affichée dès l'image suivante.
    expect(state.posing, isFalse);
    expect(state.clipPosition, 1);
    await tester.pump(const Duration(seconds: 1));
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump(const Duration(seconds: 2));
    await shot('m56_reduit_squat_clair');
    m6['reduit'] = {'position': state.clipPosition, 'temps': state.clipTime};
    record();
    SL.dark = true;
  }, timeout: _limit);

  // ------------------------------------------ carte Koach du jour --

  for (final dark in const [true, false]) {
    testWidgets(
      'M56 : carte Koach · séance du jour (${dark ? 'sombre' : 'clair'})',
      (tester) async {
        store.storeClock = () => DateTime(2026, 7, 27, 18);
        store.program.start = DateTime(2026, 7, 13);
        store.startOrigin = 'user';
        store.enableKoach();
        store.setKoachQuestionnaires(true);
        store.koach.answers.clear();
        store.koachSkipped.clear();
        KoachDayCard.debugReset();
        final WeekPlan w3 = store.program.week(3);
        final d1 = w3.day(1)!;
        await pumpHome(
          tester,
          SessionScreen(key: ValueKey('m6-seance-$dark'), week: w3, day: d1),
          dark,
        );
        await tester.pump(const Duration(seconds: 2));
        expect(find.byKey(const ValueKey('koach-day-card')), findsOneWidget);
        await tester.tap(find.text('moins de 5 h'));
        await tester.pump(const Duration(seconds: 1));
        await shot('m56_koach_${dark ? 'sombre' : 'clair'}_ouverte');
        await tester.tap(find.byKey(const ValueKey('koach-day-toggle')));
        await tester.pump(const Duration(seconds: 1));
        expect(find.byKey(const ValueKey('koach-day-summary')), findsOneWidget);
        await shot('m56_koach_${dark ? 'sombre' : 'clair'}_repliee');
        m6['koach_${dark ? 'sombre' : 'clair'}'] = tester
            .widget<Text>(find.byKey(const ValueKey('koach-day-summary')))
            .data;
        record();
        store.koach.answers.clear();
        store.storeClock = DateTime.now;
        SL.dark = true;
      },
      timeout: _limit,
    );
  }

  // ----------------------------------------- postures et modèle (M56) --

  testWidgets('M56 : écran Anatomie, modèle musclé et postures', (
    tester,
  ) async {
    AnatomyScreen.session = null;
    AnatomyScreen.sessionPosture = 'debout';
    await pumpHome(
      tester,
      const AnatomyScreen(key: ValueKey('m56-anat')),
      true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    final out = <String, Object?>{};
    for (final view in const [MannequinView.face, MannequinView.dos]) {
      state.setView(view);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      await shot('m56_anatomie_debout_${view.name}');
      out['debout_${view.name}'] = await check(tester, false);
    }
    for (final key in const ['suspendu', 'squat_bas', 'planche']) {
      state.setPosture(key);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      state.setView(MannequinView.troisQuarts);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      await shot('m56_anatomie_$key');
      final s = await check(tester, false);
      expect(s['figure'] as double, greaterThan(.03), reason: key);
      out[key] = s;
    }
    m6['anatomie'] = out;
    record();
  }, timeout: _limit);

  // ------------------------------------------------- préchargement --

  testWidgets('M56 : ouverture d’un mannequin avant / après préchargement', (
    tester,
  ) async {
    // Avant : préchargement désactivé, caches vidés par une nouvelle
    // instance impossible ici (modèle déjà chargé par les cas précédents) :
    // la mesure « avant » porte sur l'ouverture sans préchauffage des
    // pipelines d'un écran neuf ; « après » sur la même ouverture une fois
    // le préchargement (chargement + préchauffage) terminé.
    Future<Map<String, Object?>> open(String key) async {
      MannequinPreload.lastOpen.value = null;
      await pumpHome(
        tester,
        ExerciseSheetScreen(key: ValueKey('m56-pre-$key'), id: 'dips'),
        true,
      );
      await waitFor(tester, () => mannequin(tester)?.available != null);
      await waitFor(
        tester,
        () => MannequinPreload.lastOpen.value != null,
        seconds: 30,
      );
      final r = MannequinPreload.lastOpen.value;
      return {
        'premiere_image_ms': r?.firstImageMs,
        'images_perdues': r?.lostFrames,
        'images': r?.frames,
        'precharge': r?.preloaded,
      };
    }

    MannequinPreload.reset();
    MannequinPreload.enabled = false;
    final before = await open('avant');
    MannequinPreload.enabled = true;
    final sw = Stopwatch()..start();
    await tester.runAsync(() => MannequinPreload.start());
    final rep = MannequinPreload.report;
    // Comme sur le téléphone (préchargement au lancement, fiche ouverte
    // plus tard) : le rendu logiciel de l'émulateur termine l'image de
    // préchauffage (≈ 1 s) avant l'ouverture mesurée.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump();
    final after = await open('apres');
    m6['prechargement'] = {
      'avant': before,
      'apres': after,
      'duree_ms': sw.elapsedMilliseconds,
      'chargement_ms': rep?.loadMs,
      'prechauffage_ms': rep?.warmUpMs,
      'memoire_ajoutee_mo': rep == null ? null : rep.addedMb,
      'compatible': rep?.compatible,
    };
    record();
    expect(rep, isNotNull);
    expect(rep!.compatible, isTrue);
    await pumpHome(
      tester,
      const Engine3DScreen(key: ValueKey('m56-moteur'), autoMeasure: false),
      true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    await tester.pump(const Duration(seconds: 2));
    await shot('m56_moteur3d_prechargement');
    record();
  }, timeout: _limit);
}
