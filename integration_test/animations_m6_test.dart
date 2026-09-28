// M6 (CI 3D) : animations d'exercice et carte « Koach · séance du jour », sur
// émulateur Android (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/animations_m6_test.dart -d emulator-5554
// Captures : pour chaque pilote (traction pronation, dips, back squat), la
// fiche exercice avec le mannequin animé, 8 images d'une boucle (GIF
// assemblé hors de l'émulateur) et une vue 3/4 ; lecture en boucle réelle,
// pause hors de l'écran ; animations réduites (positions clés fixes) ;
// carte Koach de la séance du jour ouverte et repliée, sombre et clair.
// Relevé m6_releve.json (cadre du mannequin dans chaque capture, contrôles
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
import 'package:streetlift_tracker/mannequin_clip.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _ratio = 1.5;
const _limit = Timeout(Duration(minutes: 5));
const _frames = 8;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final m6 = <String, Object?>{};
  binding.reportData = data;

  void record() =>
      data['m6_releve.json'] = const JsonEncoder.withIndent('  ').convert(m6);

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
        if ((r - br).abs() <= 12 && (g - bgG).abs() <= 12 &&
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
    return f.evaluate().isEmpty ? null : tester.state<Mannequin3DState>(f.first);
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
          key: ValueKey('m6-$dark-$reduce-${home.key}'),
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
      ExerciseSheetScreen(key: ValueKey('m6-$id'), id: id),
      true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    expect(find.byType(ExerciseAnimation), findsOneWidget);
    final clip = state.widget.clip!;
    final out = <String, Object?>{
      'vue': state.view.name,
      'materiel': state.scene!.equipmentNames.toList(),
      'duree': clip.duration,
      'tempo': clip.tempo,
    };
    // Lecture réelle : le temps avance.
    await tester.pump(const Duration(seconds: 2));
    final t0 = state.clipTime;
    await tester.pump(const Duration(seconds: 2));
    out['lecture'] = state.clipPlaying;
    out['temps_avance'] = state.clipTime != t0;
    expect(state.clipPlaying, isTrue);
    expect(state.clipTime, isNot(t0));
    expect(state.view.name, clip.view);
    expect(find.byKey(const ValueKey('mannequin-phase')), findsOneWidget);
    // Une boucle en 8 images (pause à chaque instant pour la capture).
    final frames = <Object?>[];
    for (var k = 0; k < _frames; k++) {
      state.seekClip(clip.duration * k / _frames);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 1));
      await shot('m6_${id}_$k');
      final s = await check(tester, true);
      s['phase'] = clip.phaseAt(clip.duration * k / _frames).name;
      frames.add(s);
      expect(s['figure'] as double, greaterThan(.03), reason: '$id $k');
      expect(s['rouge'] as double, greaterThan(.001), reason: '$id $k');
      expect(s['gris'] as double, greaterThan(.01), reason: '$id $k');
    }
    out['boucle'] = frames;
    // Vue 3/4 à la position clé la plus ample.
    state.seekClip(clip.keyPositions.first.$2);
    await tester.tap(find.byKey(const ValueKey('mannequin-view-troisQuarts')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(seconds: 2));
    await shot('m6_${id}_troisquarts');
    out['troisquarts'] = await check(tester, true);
    // Pause hors de l'écran, reprise au retour.
    state.seekClip(0, pause: false);
    await tester.pump(const Duration(seconds: 1));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump(const Duration(seconds: 1));
    out['pause_hors_ecran'] = !state.clipPlaying;
    expect(state.clipPlaying, isFalse);
    scroll.position.jumpTo(0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    out['reprise'] = state.clipPlaying;
    expect(state.clipPlaying, isTrue);
    m6[id] = out;
    record();
  }

  for (final id in const ['traction-pronation', 'dips', 'back-squat']) {
    testWidgets('M6 : $id animé dans sa fiche', (tester) async {
      await pilot(tester, id);
    }, timeout: _limit);
  }

  testWidgets('M6 : animations réduites, positions clés fixes (clair)', (
    tester,
  ) async {
    await pumpHome(
      tester,
      const ExerciseSheetScreen(key: ValueKey('m6-reduit'), id: 'back-squat'),
      false,
      reduce: true,
    );
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    await tester.pump(const Duration(seconds: 2));
    expect(state.clipPlaying, isFalse);
    final chips = find.byKey(const ValueKey('mannequin-key-positions'));
    expect(chips, findsOneWidget);
    final t = state.clipTime;
    await tester.pump(const Duration(seconds: 1));
    expect(state.clipTime, t);
    await tester.ensureVisible(chips);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.descendant(of: chips, matching: find.byType(ChoiceChip)).last);
    await tester.pump(const Duration(seconds: 2));
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pump(const Duration(seconds: 2));
    await shot('m6_reduit_squat_clair');
    m6['reduit'] = {'lecture': state.clipPlaying, 'temps': state.clipTime};
    record();
    SL.dark = true;
  }, timeout: _limit);

  // ------------------------------------------ carte Koach du jour --

  for (final dark in const [true, false]) {
    testWidgets('M6 : carte Koach · séance du jour (${dark ? 'sombre' : 'clair'})',
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
      await shot('m6_koach_${dark ? 'sombre' : 'clair'}_ouverte');
      await tester.tap(find.byKey(const ValueKey('koach-day-toggle')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('koach-day-summary')), findsOneWidget);
      await shot('m6_koach_${dark ? 'sombre' : 'clair'}_repliee');
      m6['koach_${dark ? 'sombre' : 'clair'}'] = tester
          .widget<Text>(find.byKey(const ValueKey('koach-day-summary')))
          .data;
      record();
      store.koach.answers.clear();
      store.storeClock = DateTime.now;
      SL.dark = true;
    }, timeout: _limit);
  }
}
