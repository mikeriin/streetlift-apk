// M6b (CI 3D) : audit des écrans du mannequin fixe, sur émulateur Android
// (Flutter GPU), lancé par tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/audit_m6b_test.dart -d emulator-5554
// Même test avant (main 5.5.4) et après les corrections : captures
// `m6b_*.png` de chaque écran 3D en sombre et en clair (Anatomie : vues,
// groupe, menu Filtres, toucher, zoom, grande taille de texte, animations
// réduites, grand écran ; fiches ; STATS ; accueil ; aperçu de WOD ;
// Moteur 3D), relevé `m6b_releve.json` : part de la figure, part du halo
// (couleur dominante), démarcation entre la vue et son support (écart des
// pixels juste à l'intérieur et juste à l'extérieur des bords de la vue),
// vue de départ, nom touché, libellés d'accessibilité.
//
// Émulateur sans GPU (PIPELINE_3D.md §4) : aucun `pumpAndSettle` sur un
// écran qui contient une vue 3D, nombre fixe de `pump`, 5 min par test.
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
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/home_screen.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/stats_mannequin.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_performance.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:streetlift_tracker/wod_preview.dart';

final _root = GlobalKey();
const _ratio = 1.5;

/// Partie jouée (`--dart-define=M6B_PART=a|b`) : deux lancements, pour que
/// les captures renvoyées par le pilote restent de taille raisonnable
/// (essai A : 30 captures d'un coup, service du pilote perdu au retour).
const _part = String.fromEnvironment('M6B_PART', defaultValue: 'a');
bool _skip(String part) => _part != part;
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

  void record() => data['m6b_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  // Grand écran : capture réduite (surface de 1200 × 1920 px).
  var ratio = _ratio;

  Future<ui.Image> grab() async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: ratio);
  }

  Future<void> shot(String name) async {
    final image = await grab();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    data['m6b_$name.png'] = base64Encode(png.buffer.asUint8List());
    image.dispose();
  }

  Mannequin3DState? mannequin(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    return f.evaluate().isEmpty
        ? null
        : tester.state<Mannequin3DState>(f.first);
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

  /// Contrôles sans référence dans la vue `mannequin-view` : figure (pixels
  /// hors fond), halo (pixels saturés dans la couleur dominante), gris ;
  /// démarcation : écart moyen (0-255) entre les pixels juste à l'intérieur
  /// et juste à l'extérieur des bords gauche et droit de la vue, sur la
  /// moitié haute (hors boutons).
  Future<Map<String, Object?>> check(WidgetTester tester) async {
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

    final bg = mannequin(tester)?.backgroundColor;
    final br = ((bg?.r ?? 0) * 255).round(), bgG = ((bg?.g ?? 0) * 255).round();
    final bb = ((bg?.b ?? 0) * 255).round();
    final accent = SL.accentSpec.principal;
    final ar = (accent.r * 255).round(), ag = (accent.g * 255).round();
    final ab = (accent.b * 255).round();
    var total = 0, figure = 0, halo = 0, gray = 0;
    for (var y = rect.top; y < rect.bottom; y += 2) {
      for (var x = rect.left; x < rect.right; x += 2) {
        final (r, g, b) = at(x, y);
        total++;
        if ((r - br).abs() <= 12 &&
            (g - bgG).abs() <= 12 &&
            (b - bb).abs() <= 12) {
          continue;
        }
        figure++;
        final sat =
            [r, g, b].reduce((a, c) => a > c ? a : c) -
            [r, g, b].reduce((a, c) => a < c ? a : c);
        // Teinte proche de la couleur dominante, saturée.
        final dot =
            (r - br) * (ar - br) +
            (g - bgG) * (ag - bgG) +
            (b - bb) * (ab - bb);
        if (sat > 40 && dot > 0) halo++;
        if (sat < 24 && r > 30) gray++;
      }
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
    return {
      'cadre': [rect.left, rect.top, rect.width, rect.height],
      'figure': total == 0 ? 0 : figure / total,
      'halo': total == 0 ? 0 : halo / total,
      'gris': total == 0 ? 0 : gray / total,
      'demarcation': n == 0 ? 0 : edge / n,
    };
  }

  Future<void> pumpHome(
    WidgetTester tester,
    Widget home,
    bool dark, {
    bool reduce = false,
    double text = 1,
  }) async {
    SL.dark = dark;
    await tester.pumpWidget(
      RepaintBoundary(
        key: _root,
        child: MaterialApp(
          key: ValueKey('m6b-$dark-$reduce-$text-${home.key}'),
          debugShowCheckedModeBanner: false,
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduce,
              textScaler: TextScaler.linear(text),
            ),
            child: child!,
          ),
          home: home,
        ),
      ),
    );
  }

  Future<Mannequin3DState> ready(WidgetTester tester) async {
    await waitFor(tester, () => mannequin(tester)?.available != null);
    final state = mannequin(tester)!;
    expect(state.available, isTrue, reason: 'pas de 3D');
    await tester.pump(const Duration(seconds: 2));
    return state;
  }

  String? semantics(WidgetTester tester) {
    final f = find.byType(Mannequin3D);
    if (f.evaluate().isEmpty) return null;
    return tester.widget<Mannequin3D>(f.first).semanticLabel;
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    await ContentLibrary.load();
    await Display3DSettings.instance.load();
    await engine3DSupport();
    await MannequinMap.load();
  });

  // ------------------------------------------------------- Anatomie --

  testWidgets(
    'M6b : Anatomie sombre (repos, groupe, menu, toucher, zoom)',
    (tester) async {
      AnatomyScreen.session = null;
      await pumpHome(tester, const AnatomyScreen(key: ValueKey('a1')), true);
      final state = await ready(tester);
      final out = <String, Object?>{};
      await shot('anatomie_sombre_repos');
      out['repos'] = await check(tester);
      out['filtres_bouton'] = find
          .descendant(
            of: find.byKey(const ValueKey('anatomy-filters')),
            matching: find.byType(Text),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .join(' ');
      // Menu Filtres ouvert.
      await tester.tap(find.byKey(const ValueKey('anatomy-filters')));
      await tester.pump(const Duration(seconds: 1));
      await shot('anatomie_sombre_menu');
      out['menu_options'] = [
        for (final e
            in find
                .descendant(
                  of: find.byType(CheckboxListTile),
                  matching: find.byType(Text),
                )
                .evaluate())
          (e.widget as Text).data,
      ];
      await tester.tapAt(const Offset(4, 4));
      await tester.pump(const Duration(seconds: 1));
      // Groupe Dos, vue de dos.
      tester
          .state<AnatomyScreenState>(find.byType(AnatomyScreen))
          .toggleGroup('dos');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      await shot('anatomie_sombre_dos');
      out['dos'] = await check(tester);
      out['dos_vue'] = state.view.name;
      out['dos_semantique'] = semantics(tester);
      // Toucher : grand dorsal, à côté de la colonne (essai B : au milieu,
      // le fascia de la colonne n'est pas un muscle, rien sous le doigt).
      final rect = tester.getRect(
        find.byKey(const ValueKey('mannequin-view')).first,
      );
      await tester.tapAt(
        rect.topCenter + Offset(rect.width * .08, rect.height * .36),
      );
      await tester.pump(const Duration(seconds: 2));
      out['toucher'] = state.touched?.label;
      // Diagnostic (essai C : aucune bulle) : même point, rayon calculé
      // directement, et points voisins.
      final local = Offset(rect.width * .58, rect.height * .36);
      final scene = state.scene!;
      out['toucher_direct'] = {
        for (final (dx, dy) in const [
          (.58, .36),
          (.45, .30),
          (.5, .5),
          (.55, .75),
        ])
          '$dx,$dy': scene
              .pick(
                state.camera!,
                Offset(rect.width * dx, rect.height * dy),
                state.viewSize,
              )
              ?.label,
      };
      out['toucher_vue'] = [state.viewSize.width, state.viewSize.height];
      out['toucher_local'] = [local.dx, local.dy];
      final ray = state.camera!.screenPointToRay(local, state.viewSize);
      out['toucher_rayon'] = [
        ray.origin.x,
        ray.origin.y,
        ray.origin.z,
        ray.direction.x,
        ray.direction.y,
        ray.direction.z,
      ];
      out['toucher_maillages'] = scene.pickables.length;
      out['toucher_touches'] = [
        for (final m in scene.pickables)
          if (m.intersect(ray.origin, ray.direction.normalized()) != null)
            m.name,
      ];
      await shot('anatomie_sombre_toucher');
      // Zoom ×2,5 sur le haut du dos.
      state.pinchTo(2.5, rect.size.center(Offset(0, -rect.height * .2)));
      await tester.pump(const Duration(seconds: 3));
      await shot('anatomie_sombre_zoom');
      out['zoom'] = await check(tester);
      // Retour à la face.
      await tester.tap(find.byKey(const ValueKey('mannequin-view-face')));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      out['face_apres_zoom'] = state.zoom.isDefault;
      await shot('anatomie_sombre_face_dos_allume');
      releve['anatomie_sombre'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  testWidgets(
    'M6b : Anatomie clair, grand texte, animations réduites',
    (tester) async {
      AnatomyScreen.session = null;
      await pumpHome(
        tester,
        const AnatomyScreen(key: ValueKey('a2'), initialGroup: 'pectoraux'),
        false,
      );
      await ready(tester);
      final out = <String, Object?>{};
      await shot('anatomie_clair_pectoraux');
      out['clair'] = await check(tester);
      AnatomyScreen.session = null;
      await pumpHome(
        tester,
        const AnatomyScreen(key: ValueKey('a3'), initialGroup: 'quadriceps'),
        true,
        text: 1.3,
        reduce: true,
      );
      final state = await ready(tester);
      await shot('anatomie_grand_texte');
      out['grand_texte'] = await check(tester);
      // Animations réduites : la vue change sans transition.
      await tester.tap(find.byKey(const ValueKey('mannequin-view-profil')));
      await tester.pump(const Duration(milliseconds: 100));
      out['reduit_vue_immediate'] = state.view == MannequinView.profil;
      await tester.pump(const Duration(seconds: 2));
      await shot('anatomie_reduit_profil');
      releve['anatomie_clair'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  // --------------------------------------------------------- fiches --

  Future<Map<String, Object?>> fiche(
    WidgetTester tester,
    String id, {
    bool dark = true,
    bool legend = false,
  }) async {
    await pumpHome(
      tester,
      ExerciseSheetScreen(key: ValueKey('m6b-$id-$dark'), id: id),
      dark,
    );
    await waitFor(
      tester,
      () => find.byType(ExerciseMannequin).evaluate().isNotEmpty,
      seconds: 30,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await Scrollable.ensureVisible(
      tester.element(find.byType(ExerciseMannequin)),
      alignment: .04,
    );
    final state = await ready(tester);
    await shot('fiche_${id}_${dark ? 'sombre' : 'clair'}');
    final s = await check(tester);
    // Légende et « Absents du mannequin ».
    await Scrollable.ensureVisible(
      tester.element(find.byType(ExerciseMannequin)),
      alignment: .6,
    );
    await tester.pump(const Duration(seconds: 2));
    if (legend) await shot('fiche_${id}_${dark ? 'sombre' : 'clair'}_legende');
    return {'vue': state.view.name, ...s, 'semantique': semantics(tester)};
  }

  testWidgets(
    'M6b : fiches (traction, dips, squat, étirement)',
    (tester) async {
      final out = <String, Object?>{};
      for (final id in const ['traction-pronation', 'dips', 'back-squat']) {
        out[id] = await fiche(tester, id, legend: id == 'traction-pronation');
        releve['fiches'] = out;
        record();
      }
      out['etirements-flechisseurs-de-hanche'] = await fiche(
        tester,
        'etirements-flechisseurs-de-hanche',
        dark: false,
      );
      releve['fiches'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  // ---------------------------------------------------------- STATS --

  testWidgets(
    'M6b : STATS, muscles de la semaine, sombre et clair',
    (tester) async {
      _fillWeek();
      final out = <String, Object?>{};
      for (final dark in const [true, false]) {
        SL.dark = dark;
        await pumpHome(
          tester,
          StatsScreen(
            key: ValueKey('m6b-stats-$dark'),
            initialSection: StatsSection.performance,
            standalone: true,
          ),
          dark,
        );
        await waitFor(
          tester,
          () => find.byType(StatsPerformance).evaluate().isNotEmpty,
          seconds: 30,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.scrollUntilVisible(
          find.byType(WeeklyMannequin),
          250,
          scrollable: find
              .descendant(
                of: find.byType(StatsPerformance),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await Scrollable.ensureVisible(
          tester.element(find.byType(WeeklyMannequin)),
          alignment: .05,
        );
        await ready(tester);
        await tester.pump(const Duration(seconds: 1));
        final theme = dark ? 'sombre' : 'clair';
        await shot('stats_$theme');
        out[theme] = {...await check(tester), 'semantique': semantics(tester)};
      }
      releve['stats'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );

  // ------------------------------------------------- accueil et WOD --

  testWidgets(
    'M6b : accueil (carte du jour) et aperçu de WOD',
    (tester) async {
      store.storeClock = () => DateTime(2026, 7, 27, 9);
      store.program.start = DateTime(2026, 7, 13);
      store.startOrigin = 'user';
      final out = <String, Object?>{};
      for (final dark in const [true, false]) {
        await pumpHome(
          tester,
          HomeScreen(
            key: ValueKey('m6b-home-$dark'),
            referenceDate: DateTime(2026, 7, 27, 9),
          ),
          dark,
        );
        await waitFor(
          tester,
          () => find.byType(TargetedMannequin).evaluate().isNotEmpty,
          seconds: 30,
        );
        await ready(tester);
        await tester.pump(const Duration(seconds: 2));
        final theme = dark ? 'sombre' : 'clair';
        await shot('accueil_$theme');
        out['accueil_$theme'] = {
          ...await check(tester),
          'mannequins': find.byType(Mannequin3D).evaluate().length,
          'semantique': semantics(tester),
        };
      }
      final wod = store.wods.firstWhere((w) => store.isCatalog(w));
      await pumpHome(
        tester,
        WodPreviewScreen(key: const ValueKey('m6b-wod'), wodId: wod.id),
        true,
      );
      await tester.pump(const Duration(seconds: 2));
      await waitFor(
        tester,
        () => find.byType(TargetedMannequin).evaluate().isNotEmpty,
        seconds: 10,
      );
      if (find.byType(TargetedMannequin).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.byType(TargetedMannequin),
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await Scrollable.ensureVisible(
        tester.element(find.byType(TargetedMannequin)),
        alignment: .1,
      );
      await ready(tester);
      await tester.pump(const Duration(seconds: 1));
      await shot('wod_apercu_sombre');
      out['wod'] = {
        'id': wod.id,
        ...await check(tester),
        'semantique': semantics(tester),
      };
      store.storeClock = DateTime.now;
      releve['accueil_wod'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );

  // ------------------------------------------------------ Moteur 3D --

  testWidgets(
    'M6b : Moteur 3D (rotation, halo, fond)',
    (tester) async {
      await pumpHome(
        tester,
        const Engine3DScreen(key: ValueKey('m6b-moteur'), autoMeasure: false),
        true,
      );
      await ready(tester);
      await tester.pump(const Duration(seconds: 3));
      await shot('moteur3d');
      releve['moteur3d'] = await check(tester);
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );

  // --------------------------------------------------- grand écran --

  testWidgets(
    'M6b : grand écran (tablette, 800 × 1280 dp)',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.5;
      ratio = .75;
      addTearDown(() {
        tester.view.reset();
        ratio = _ratio;
      });
      AnatomyScreen.session = null;
      await pumpHome(
        tester,
        const AnatomyScreen(key: ValueKey('a4'), initialGroup: 'épaules'),
        true,
      );
      await ready(tester);
      await shot('grand_ecran_anatomie');
      final out = <String, Object?>{'anatomie': await check(tester)};
      await pumpHome(
        tester,
        const ExerciseSheetScreen(key: ValueKey('m6b-ge'), id: 'dips'),
        true,
      );
      await waitFor(
        tester,
        () => find.byType(ExerciseMannequin).evaluate().isNotEmpty,
        seconds: 30,
      );
      await ready(tester);
      await shot('grand_ecran_fiche');
      out['fiche'] = await check(tester);
      releve['grand_ecran'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );
}
