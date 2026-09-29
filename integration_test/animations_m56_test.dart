// M56 (CI 3D) : écorché acheté (5.5.2), fiches (mannequin fixe et ses
// muscles), carte « Koach · séance du jour » et préchargement, sur
// émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/animations_m56_test.dart -d emulator-5554
// 5.5.2 (décision du propriétaire, 29/09/2026) : plus aucune animation ;
// la fiche montre la démonstration 2D historique et le mannequin 3D avec
// les muscles de l'exercice. Captures : trois fiches (traction pronation,
// dips, back squat), carte Koach (page à part, avant l'exercice 1) ouverte
// et repliée, sombre et clair, écran Anatomie (repos face, dos, profil, 3/4 ;
// groupe Dos allumé dans la couleur dominante), préchargement (ouverture
// d'un mannequin avant / après), Moteur 3D.
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
    // 5.5.4 : fond = couleur du support (carte ou page).
    final bg = mannequin(tester)?.backgroundColor ?? sceneBackground(dark);
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
  });

  // ------------------------------------------------------ fiches --

  /// 5.5.2 : la démonstration 2D ouvre la fiche, le mannequin (section
  /// Muscles) est plus bas dans la liste : on y défile d'abord.
  Future<void> scrollToMannequin(WidgetTester tester) async {
    await waitFor(
      tester,
      () => find.byType(ExerciseSheetScreen).evaluate().length == 1,
      seconds: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    final list = find
        .descendant(
          of: find.byType(ExerciseSheetScreen).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(ExerciseMannequin),
      250,
      scrollable: list,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> fiche(WidgetTester tester, String id) async {
    await pumpHome(
      tester,
      ExerciseSheetScreen(key: ValueKey('m56-$id'), id: id),
      true,
    );
    await scrollToMannequin(tester);
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    expect(find.byType(ExerciseMannequin), findsOneWidget);
    // Plus d'animation : mannequin fixe, muscles de l'exercice.
    await tester.pump(const Duration(seconds: 2));
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('mannequin-view'))),
      alignment: .04,
    );
    await tester.pump(const Duration(seconds: 1));
    await shot('m56_${id}_fiche');
    final s = await check(tester, true);
    expect(s['figure'] as double, greaterThan(.03), reason: id);
    expect(s['rouge'] as double, greaterThan(.001), reason: id);
    expect(s['gris'] as double, greaterThan(.01), reason: id);
    m6[id] = {'vue': state.view.name, 'fiche': s};
    record();
  }

  for (final id in const ['traction-pronation', 'dips', 'back-squat']) {
    testWidgets('M56 : fiche $id, mannequin fixe et muscles', (tester) async {
      await fiche(tester, id);
    }, timeout: _limit);
  }

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

  // ------------------------------------------------ modèle (5.5.2) --

  testWidgets('5.5.2 : écran Anatomie, écorché acheté, vues et groupe', (
    tester,
  ) async {
    AnatomyScreen.session = null;
    await pumpHome(
      tester,
      const AnatomyScreen(key: ValueKey('m56-anat')),
      true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    final out = <String, Object?>{};
    for (final view in MannequinView.values) {
      state.setView(view);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      await shot('m56_anatomie_${view.name}');
      final s = await check(tester, true);
      expect(s['figure'] as double, greaterThan(.03), reason: view.name);
      out[view.name] = s;
    }
    // Groupe Dos allumé (couleur dominante), vue de dos.
    final anatomy = tester.state<AnatomyScreenState>(
      find.byType(AnatomyScreen),
    );
    anatomy.toggleGroup('dos');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
    await shot('m56_anatomie_dos_allume');
    final lit = await check(tester, true);
    expect(lit['rouge'] as double, greaterThan(0), reason: 'dos allumé');
    out['dos_allume'] = lit;
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
      await scrollToMannequin(tester);
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
