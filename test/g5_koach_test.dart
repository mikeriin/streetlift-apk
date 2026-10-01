// G5 (dev6.3.0, D1.5, D5.3, D5.5, D6) — Koach 2D dans l'application :
// rendu des 36 poses (chemins, couleurs inversées selon le thème), micro-
// animations (rebond, transition, clignement, respiration ; « Réduire les
// animations » = pose fixe ; rien ne reste programmé après démontage),
// flammes (dégradé, libellés « Difficulté n sur 10, RIR … », sélecteur),
// bulle et « Pourquoi ? », Galerie de Koach, carte du jour de l'accueil,
// Koach dans les cartes qui parlaient déjà, Koach 3D (M7b) retiré.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' show Flames;
import 'package:kalis_koach/kalis_koach.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/dev/dev_widgets.dart' show SessionToast;
import 'package:streetlift_tracker/engine3d.dart' show engine3DSupport;
import 'package:streetlift_tracker/koach/flame_icon.dart';
import 'package:streetlift_tracker/koach/koach_bubble.dart';
import 'package:streetlift_tracker/koach/koach_gallery_screen.dart';
import 'package:streetlift_tracker/koach/koach_home_card.dart';
import 'package:streetlift_tracker/koach/koach_view.dart';
import 'package:streetlift_tracker/koach_widgets.dart';
import 'package:streetlift_tracker/mannequin_3d.dart' show MannequinMap;
import 'package:streetlift_tracker/store.dart';

Widget _page(
  Widget child, {
  bool dark = true,
  KAccentSpec accent = KAccentSpec.rouge,
  bool reduce = false,
  double scale = 1,
}) => MaterialApp(
  theme: buildTheme(dark, accent),
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: reduce,
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await engine3DSupport();
    await MannequinMap.load();
  });

  tearDown(() => KoachMotion.idle = false);

  group('intégration du paquet', () {
    test('kalis_koach 0.1.0 par chemin, 36 poses, 10 flammes', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('kalis_koach:\n    path: packages/kalis_koach'));
      expect(kalisKoachVersion, '0.1.0');
      expect(KoachPose.values, hasLength(36));
      expect(koachFlameLevels, 10);
    });

    test('chaque pose devient trois chemins Flutter dans sa boîte', () {
      for (final p in KoachPose.values) {
        final paths = KoachPaths.of(p);
        final b = paths.ink.getBounds();
        final art = p.art.bounds;
        // Les points de contrôle peuvent déborder de la courbe : 3 unités.
        expect(b.left, closeTo(art.left, 3), reason: p.id);
        expect(b.right, closeTo(art.right, 3), reason: p.id);
        expect(b.top, closeTo(art.top, 3), reason: p.id);
        expect(b.bottom, closeTo(art.bottom, 3), reason: p.id);
        expect(paths.ink.fillType, PathFillType.evenOdd);
        expect(paths.eyeBoxes.length, p.art.eyesOpen ? 2 : 0, reason: p.id);
        expect(identical(KoachPaths.of(p), paths), isTrue, reason: 'cache');
      }
      expect(KoachPaths.cached, 36);
    });

    test('cadres : même échelle du corps en cadre serré, cadre commun', () {
      for (final p in KoachPose.values) {
        final r = koachFrameOf(p, KoachFrame.pose);
        expect(r.height, koachFrameOf(KoachPose.wave, KoachFrame.pose).height);
        expect(r.left, lessThan(p.art.bounds.left));
        expect(r.right, greaterThan(p.art.bounds.right));
        final stage = koachFrameOf(p, KoachFrame.stage);
        expect(stage.left, lessThanOrEqualTo(p.art.bounds.left));
        expect(stage.right, greaterThanOrEqualTo(p.art.bounds.right));
      }
    });
  });

  group('couleurs (D6.2)', () {
    test('sombre : encre #F4F4F4, papier percé (fond du support)', () {
      expect(KoachColors.forSurface(dark: true).ink, const Color(0xFFF4F4F4));
      expect(KoachColors.forSurface(dark: true).paper, isNull);
    });

    test('clair : encre quasi-noire, papier blanc', () {
      final c = KoachColors.forSurface(dark: false);
      expect(c.ink.computeLuminance(), lessThan(.01));
      expect(c.paper, const Color(0xFFFFFFFF));
      expect(KoachColors.onColor(const Color(0xF0202020)), KoachColors.onDark);
      expect(KoachColors.onColor(Colors.white), KoachColors.onLight);
    });

    for (final dark in [true, false]) {
      testWidgets('rendu ${dark ? 'sombre' : 'clair'} : silhouette et yeux '
          'de la couleur du support', (tester) async {
        final key = GlobalKey();
        final bg = dark ? const Color(0xFF1E1E1E) : Colors.white;
        await tester.pumpWidget(
          _page(
            Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: bg,
                  child: const KoachView(
                    pose: KoachPose.wave,
                    height: 200,
                    entrance: false,
                  ),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pump();
        late List<int> counts;
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = (await image.toByteData())!;
          var ink = 0, support = 0;
          final inkColor = dark ? 0xF4 : 0x14;
          for (var i = 0; i < data.lengthInBytes; i += 4) {
            final r = data.getUint8(i);
            if ((r - inkColor).abs() <= 2) ink++;
            if ((r - (bg.r * 255).round()).abs() <= 2) support++;
          }
          counts = [ink, support];
          image.dispose();
        });
        // Koach occupe une vraie surface, le reste est le support.
        expect(counts[0], greaterThan(2000));
        expect(counts[1], greaterThan(2000));
      });
    }
  });

  group('micro-animations (D6.3)', () {
    testWidgets('rebond d\'entrée puis repos ; aucune image au repos sous '
        'flutter test', (tester) async {
      await tester.pumpWidget(
        _page(const Center(child: KoachView(pose: KoachPose.wave))),
      );
      final state = tester.state<KoachViewState>(find.byType(KoachView));
      expect(state.animating, isTrue);
      await tester.pumpAndSettle();
      expect(state.animating, isFalse);
      expect(state.blinkScheduled, isFalse);
      expect(state.breathing, isFalse);
    });

    testWidgets('transition entre deux poses (≤ 200 ms)', (tester) async {
      Widget view(KoachPose p) =>
          _page(Center(child: KoachView(pose: p, entrance: false)));
      await tester.pumpWidget(view(KoachPose.wave));
      await tester.pump();
      await tester.pumpWidget(view(KoachPose.think));
      final state = tester.state<KoachViewState>(find.byType(KoachView));
      expect(state.previous, KoachPose.wave);
      expect(state.animating, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 120));
      expect(state.animating, isFalse);
      expect(state.previous, isNull);
    });

    testWidgets('« Réduire les animations » : pose fixe, changement '
        'immédiat', (tester) async {
      KoachMotion.idle = true;
      Widget view(KoachPose p) => _page(
        Center(child: KoachView(pose: p, height: 120)),
        reduce: true,
      );
      await tester.pumpWidget(view(KoachPose.wave));
      final state = tester.state<KoachViewState>(find.byType(KoachView));
      expect(state.animating, isFalse);
      expect(state.blinkScheduled, isFalse);
      expect(state.breathing, isFalse);
      await tester.pumpWidget(view(KoachPose.think));
      expect(state.animating, isFalse);
      expect(state.previous, isNull);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('au repos : clignement seedé et respiration (grande vue), '
        'tout s\'arrête au démontage', (tester) async {
      KoachMotion.idle = true;
      await tester.pumpWidget(
        _page(
          const Center(
            child: KoachView(pose: KoachPose.wave, height: 120, seed: 4),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final state = tester.state<KoachViewState>(find.byType(KoachView));
      expect(state.breathing, isTrue);
      expect(state.blinkScheduled, isTrue);
      // Premier clignement entre 2,2 et 6,4 s.
      await tester.pump(const Duration(milliseconds: 6500));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpWidget(_page(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('petite vue : clignement sans respiration ; yeux fermés : '
        'aucun clignement', (tester) async {
      KoachMotion.idle = true;
      await tester.pumpWidget(
        _page(
          const Row(
            children: [
              KoachView(pose: KoachPose.wave, height: 40),
              KoachView(pose: KoachPose.happy, height: 40),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final states = tester
          .stateList<KoachViewState>(find.byType(KoachView))
          .toList();
      expect(states[0].breathing, isFalse);
      expect(states[0].blinkScheduled, isTrue);
      expect(KoachPose.happy.art.eyesOpen, isFalse);
      expect(states[1].blinkScheduled, isFalse);
      await tester.pumpWidget(_page(const SizedBox()));
    });

    testWidgets('hors écran (TickerMode) : clignement et respiration '
        'suspendus', (tester) async {
      KoachMotion.idle = true;
      await tester.pumpWidget(
        _page(
          const TickerMode(
            enabled: false,
            child: KoachView(pose: KoachPose.wave, height: 120),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 7));
      final state = tester.state<KoachViewState>(find.byType(KoachView));
      expect(state.animating, isFalse);
      await tester.pumpWidget(_page(const SizedBox()));
    });
  });

  group('flammes (D5.3, D5.5)', () {
    test('libellés « Difficulté n sur 10, RIR … » (kalis_core)', () {
      expect(flameSemanticLabel(10), 'Difficulté 10 sur 10, échec, RIR 0');
      expect(flameSemanticLabel(9), 'Difficulté 9 sur 10, RIR 1');
      expect(flameSemanticLabel(8), 'Difficulté 8 sur 10, RIR 1,5');
      expect(flameSemanticLabel(7), 'Difficulté 7 sur 10, RIR 2');
      expect(flameSemanticLabel(1), 'Difficulté 1 sur 10, RIR 5 et plus');
      for (var i = 1; i <= 10; i++) {
        expect(Flames.toRir(i), isNotNull);
      }
    });

    test('dégradé de la couleur dominante, du clair au vif', () {
      for (final accent in KAccentSpec.all) {
        for (final dark in [true, false]) {
          final vivid = dark ? accent.bright : (accent.vividLight ?? accent.vivid);
          expect(flameColor(10, dark: dark, accent: accent), vivid);
          var last = 2.0;
          for (var i = 1; i <= 10; i++) {
            final l = flameColor(i, dark: dark, accent: accent)
                .computeLuminance();
            expect(l, lessThanOrEqualTo(last), reason: '${accent.id} $i');
            last = l;
          }
          expect(
            flameColor(1, dark: dark, accent: accent).computeLuminance(),
            greaterThan(vivid.computeLuminance()),
          );
        }
      }
    });

    test('tailles relatives : chaque flamme plus grande que la précédente',
        () {
      for (var i = 2; i <= 10; i++) {
        expect(
          koachFlame(i).bounds.height,
          greaterThan(koachFlame(i - 1).bounds.height),
        );
      }
    });

    testWidgets('sélecteur : 10 flammes, choix, libellés', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      int? value;
      await tester.pumpWidget(
        _page(
          StatefulBuilder(
            builder: (context, set) => FlamePicker(
              value: value,
              onChanged: (v) => set(() => value = v),
            ),
          ),
          dark: false,
        ),
      );
      for (var i = 1; i <= 10; i++) {
        expect(find.byKey(ValueKey('flame-pick-$i')), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('flame-pick-8')));
      await tester.pump();
      expect(value, 8);
      expect(
        find.text('Difficulté 8 sur 10 : encore 1,5 répétition en réserve.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Difficulté 8 sur 10, RIR 1,5'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('flame-pick-1')));
      await tester.pump();
      expect(
        find.text('Difficulté 1 sur 10 : 5 répétitions ou plus en réserve.'),
        findsOneWidget,
      );
    });
  });

  group('Koach parle (D6.4)', () {
    testWidgets('bulle d\'une réplique : texte, actions, « Pourquoi ? »', (
      tester,
    ) async {
      var accepted = 0;
      final line = koachDirector.lineFor(
        const KoachCue(
          KoachEvent.proposalNew,
          reason: 'load_increased',
          params: {'exercise': 'Tractions'},
        ),
      );
      await tester.pumpWidget(
        _page(
          ListView(
            children: [
              KoachBubble.line(
                line,
                onAction: {KoachActionKind.accept: () => accepted++},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(koachTexts.bubble(line)), findsOneWidget);
      expect(find.byKey(const ValueKey('koach-why-text')), findsNothing);
      final pose = tester
          .widget<KoachView>(find.byKey(const ValueKey('koach-bubble-view')))
          .pose;
      expect(pose, line.pose);
      await tester.tap(find.byKey(const ValueKey('koach-why')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('koach-why-text')), findsOneWidget);
      expect(
        tester
            .widget<KoachView>(find.byKey(const ValueKey('koach-bubble-view')))
            .pose,
        isNot(line.pose),
      );
      await tester.tap(find.byKey(const ValueKey('koach-action-accept')));
      expect(accepted, 1);
      // « Non merci » n'a pas d'effet ici : non montré.
      expect(find.byKey(const ValueKey('koach-action-decline')), findsNothing);
    });

    testWidgets('message court et feuille du bas', (tester) async {
      await tester.pumpWidget(
        _page(
          Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showKoachToast(context, 'C’est noté.'),
                  child: const Text('toast'),
                ),
                TextButton(
                  onPressed: () => showKoachSheet<void>(
                    context,
                    pose: KoachPose.explainBoard,
                    text: 'Explication.',
                    why: 'Parce que.',
                  ),
                  child: const Text('feuille'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('toast'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('koach-toast')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('koach-toast')),
          matching: find.byType(KoachView),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('feuille'));
      await tester.pumpAndSettle();
      expect(find.text('Explication.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('koach-sheet-ok')));
      await tester.pumpAndSettle();
      expect(find.text('Explication.'), findsNothing);
    });

    testWidgets('message de la session de test : Koach et le texte de G1', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              SessionToast(
                message: 'Session de test supprimée',
                detail: 'Retour à ta session personnelle.',
                pose: KoachPose.wave,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Session de test supprimée'), findsOneWidget);
      expect(find.text('Retour à ta session personnelle.'), findsOneWidget);
      final koach = tester.widget<KoachView>(
        find.byKey(const ValueKey('session-toast-koach')),
      );
      expect(koach.pose, KoachPose.wave);
      expect(koach.colors, KoachColors.onDark);
    });

    testWidgets('en-têtes « Koach · … » des cartes de séance', (tester) async {
      await tester.pumpWidget(
        _page(
          ListView(
            children: [
              KoachFatigueCard(
                level: .2,
                sets: 2,
                onAccept: () {},
                onRefuse: () {},
              ),
              const KoachCalibrationNote(),
              const KoachWeighInBanner(),
            ],
          ),
          dark: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(KoachView), findsNWidgets(3));
      expect(find.byIcon(Icons.battery_3_bar_rounded), findsNothing);
    });
  });

  group('écrans', () {
    for (final dark in [true, false]) {
      testWidgets('Galerie de Koach (${dark ? 'sombre' : 'clair'}) : 36 '
          'poses, 10 flammes, transition au toucher', (tester) async {
        // Écran haut : toute la galerie est construite (liste paresseuse).
        tester.view.physicalSize = const Size(1080, 7200);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _page(
            const KoachGalleryScreen(),
            dark: dark,
            accent: dark ? KAccentSpec.rouge : KAccentSpec.violet,
          ),
        );
        await tester.pumpAndSettle();
        for (final p in KoachPose.values) {
          expect(find.byKey(ValueKey('koach-pose-${p.id}')), findsOneWidget);
        }
        expect(kKoachPoseNames.keys.toSet(), KoachPose.values.toSet());
        expect(find.byType(FlameIcon), findsNWidgets(10 + 10));
        final state = tester.state<KoachGalleryScreenState>(
          find.byType(KoachGalleryScreen),
        );
        await tester.ensureVisible(find.byKey(const ValueKey('koach-pose-flag')));
        await tester.tap(find.byKey(const ValueKey('koach-pose-flag')));
        await tester.pump();
        expect(state.pose, KoachPose.flag);
        final stage = tester.state<KoachViewState>(
          find.byKey(const ValueKey('koach-gallery-stage')),
        );
        expect(stage.previous, KoachPose.wave);
        await tester.pumpAndSettle();
        expect(find.text('Plante le drapeau'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('grand texte (200 %) : galerie sans débordement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page(const KoachGalleryScreen(), scale: 2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Anatomie : « Galerie de Koach » remplace « Koach (aperçu) »', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_page(const AnatomyScreen()));
      for (var i = 0; i < 60; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('anatomy-koach-preview')), findsNothing);
      final tile = find.byKey(const ValueKey('anatomy-koach-gallery'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(find.byType(KoachGalleryScreen), findsOneWidget);
    });

    testWidgets('carte du jour de l\'accueil : séance, repos, faite', (
      tester,
    ) async {
      final week = store.program.week(1);
      final training = week.days.firstWhere((d) => d.exercises.isNotEmpty);
      final rest = week.days.where((d) => d.exercises.isEmpty).toList();
      var opened = 0;
      Future<void> show(DayPlan d, {bool done = false}) async {
        await tester.pumpWidget(
          _page(
            ListView(
              children: [
                KoachHomeCard(
                  day: d,
                  done: done,
                  inProgress: false,
                  today: DateTime(2026, 10, 1),
                  onOpen: () => opened++,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(training);
      final card = tester.widget<KoachHomeCard>(find.byType(KoachHomeCard));
      expect(card.state, KoachDayState.todo);
      expect(card.text(), startsWith('Aujourd’hui : ${training.title}.'));
      expect(find.byType(KoachView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('koach-home-open')));
      expect(opened, 1);
      await show(training, done: true);
      expect(find.byKey(const ValueKey('koach-home-open')), findsNothing);
      expect(
        tester.widget<KoachHomeCard>(find.byType(KoachHomeCard)).state,
        KoachDayState.done,
      );
      if (rest.isNotEmpty) {
        await show(rest.first);
        expect(
          tester.widget<KoachHomeCard>(find.byType(KoachHomeCard)).state,
          KoachDayState.rest,
        );
      }
    });
  });

  group('Koach 3D retiré (D1.5)', () {
    test('plus de clip « mascotte » ni d\'écran d\'aperçu', () {
      final index =
          jsonDecode(File('assets/anatomy/clips/index.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final c in index['clips'] as List) {
        expect((c as Map)['mascotte'], isNull, reason: '${c['id']}');
      }
      expect(Directory('assets/anatomy/clips/koach').existsSync(), isFalse);
      expect(File('lib/koach_preview_screen.dart').existsSync(), isFalse);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        isNot(contains('assets/anatomy/clips/koach/')),
      );
    });
  });
}
