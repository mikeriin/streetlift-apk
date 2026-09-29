// M6c (CI 3D) : nouveau mannequin (personnage Mixamo « Ch36 », zones
// musculaires sur la peau) sur émulateur Android (Flutter GPU), lancé par
// tools/ci3d_drive.sh :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/personnage_m6c_test.dart \
//     --dart-define=M6B_PART=a -d emulator-5554
// Captures `m6c_*.png` : a = Anatomie, 4 vues avec plusieurs groupes, en
// sombre et en clair, toucher ; b = fiches (traction, dips, squat), STATS,
// accueil, aperçu de WOD, Moteur 3D ; c = gros plans du halo aux frontières
// (pectoraux, deltoïdes, dorsaux, quadriceps, ischios). Relevé
// `m6c_releve_<partie>.json` (part de la figure, du halo, du gris,
// démarcation, vue de départ, nom touché, nœuds du modèle). Méthode et
// mesures reprises de l'audit M6b (integration_test/audit_m6b_test.dart).
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

  void record() => data['m6c_releve_$_part.json'] =
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
    data['m6c_$name.png'] = base64Encode(png.buffer.asUint8List());
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
          key: ValueKey('m6c-$dark-$reduce-$text-${home.key}'),
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

  const groups = ['pectoraux', 'épaules', 'dos', 'quadriceps', 'ischios'];
  const views = [
    MannequinView.face,
    MannequinView.dos,
    MannequinView.profil,
    MannequinView.troisQuarts,
  ];

  Future<Map<String, Object?>> anatomyViews(
    WidgetTester tester,
    bool dark,
  ) async {
    AnatomyScreen.session = null;
    await pumpHome(
      tester,
      AnatomyScreen(key: ValueKey('m6c-anatomie-$dark')),
      dark,
    );
    final state = await ready(tester);
    final screen = tester.state<AnatomyScreenState>(find.byType(AnatomyScreen));
    for (final g in groups) {
      screen.toggleGroup(g);
    }
    await tester.pump(const Duration(milliseconds: 900));
    final theme = dark ? 'sombre' : 'clair';
    final out = <String, Object?>{
      'groupes': screen.filters.orderedGroups,
      'filtres_bouton': find
          .descendant(
            of: find.byKey(const ValueKey('anatomy-filters')),
            matching: find.byType(Text),
          )
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .join(' '),
      'semantique': semantics(tester),
    };
    // Essai A : avec 5 puces, les boutons de vue sortaient de l'écran
    // (toucher sans effet) : mannequin amené en haut de la page, vue
    // choisie par l'état du mannequin (comme ses boutons).
    await Scrollable.ensureVisible(
      tester.element(find.byType(Mannequin3D)),
      alignment: .02,
    );
    await tester.pump(const Duration(seconds: 1));
    for (final v in views) {
      state.setView(v);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      await shot('anatomie_${theme}_${v.name}');
      out[v.name] = {...await check(tester), 'vue': state.view.name};
    }
    return out;
  }

  testWidgets(
    'M6c : Anatomie sombre, 4 vues, 5 groupes, toucher, nœuds',
    (tester) async {
      final out = await anatomyViews(tester, true);
      final state = mannequin(tester)!;
      final scene = state.scene!;
      final names = scene.nodeNames.toSet();
      out['noeuds'] = names.length;
      out['noeuds_hors_zones'] = names
          .where((n) => !scene.map.byId.containsKey(n))
          .toList();
      expect(names, containsAll(['peau', 'head', 'latissimus_dorsi_left']));
      expect(names.contains('os'), isFalse);
      // Toucher de face : grand pectoral.
      state.setView(MannequinView.face);
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(seconds: 2));
      final rect = tester.getRect(
        find.byKey(const ValueKey('mannequin-view')).first,
      );
      out['toucher_direct'] = {
        for (final (dx, dy) in const [
          (.44, .24),
          (.5, .38),
          (.44, .6),
          (.34, .3),
        ])
          '$dx,$dy': scene
              .pick(
                state.camera!,
                Offset(rect.width * dx, rect.height * dy),
                state.viewSize,
              )
              ?.label,
      };
      await tester.tapAt(
        rect.topLeft + Offset(rect.width * .44, rect.height * .24),
      );
      await tester.pump(const Duration(seconds: 2));
      out['toucher'] = state.touched?.label;
      await shot('anatomie_sombre_toucher');
      releve['anatomie_sombre'] = out;
      record();
      expect(state.touched, isNotNull, reason: 'nom au toucher');
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  testWidgets(
    'M6c : Anatomie clair, 4 vues, 5 groupes',
    (tester) async {
      releve['anatomie_clair'] = await anatomyViews(tester, false);
      record();
    },
    timeout: _limit,
    skip: _skip('a'),
  );

  // --------------------------------------------- gros plans du halo --

  testWidgets(
    'M6c : halo aux frontières (gros plans)',
    (tester) async {
      final out = <String, Object?>{};
      for (final (group, view, fx, fy, name) in const [
        ('pectoraux', MannequinView.face, .5, .27, 'pectoraux'),
        ('épaules', MannequinView.face, .33, .22, 'deltoides'),
        ('dos', MannequinView.dos, .5, .33, 'dorsaux'),
        ('quadriceps', MannequinView.face, .43, .6, 'quadriceps'),
        ('ischios', MannequinView.dos, .43, .62, 'ischios'),
      ]) {
        AnatomyScreen.session = null;
        await pumpHome(
          tester,
          AnatomyScreen(key: ValueKey('m6c-gp-$name'), initialGroup: group),
          true,
        );
        final state = await ready(tester);
        state.setView(view);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.pump(const Duration(seconds: 1));
        final rect = tester.getRect(
          find.byKey(const ValueKey('mannequin-view')).first,
        );
        state.pinchTo(2.6, Offset(rect.width * fx, rect.height * fy));
        await tester.pump(const Duration(seconds: 3));
        await shot('gros_plan_$name');
        out[name] = await check(tester);
        releve['gros_plans'] = out;
        record();
      }
    },
    timeout: _limit,
    skip: _skip('c'),
  );

  // --------------------------------------------------------- fiches --

  Future<Map<String, Object?>> fiche(
    WidgetTester tester,
    String id, {
    bool dark = true,
  }) async {
    await pumpHome(
      tester,
      ExerciseSheetScreen(key: ValueKey('m6c-$id-$dark'), id: id),
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
    return {'vue': state.view.name, ...s, 'semantique': semantics(tester)};
  }

  testWidgets(
    'M6c : fiches (traction, dips, squat)',
    (tester) async {
      final out = <String, Object?>{};
      for (final id in const ['traction-pronation', 'dips', 'back-squat']) {
        out[id] = await fiche(tester, id);
        releve['fiches'] = out;
        record();
      }
      out['traction-pronation_clair'] = await fiche(
        tester,
        'traction-pronation',
        dark: false,
      );
      releve['fiches'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );

  // ---------------------------------------------------------- STATS --

  testWidgets(
    'M6c : STATS, muscles de la semaine, sombre et clair',
    (tester) async {
      _fillWeek();
      final out = <String, Object?>{};
      for (final dark in const [true, false]) {
        SL.dark = dark;
        await pumpHome(
          tester,
          StatsScreen(
            key: ValueKey('m6c-stats-$dark'),
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

  // ------------------------------------------ accueil, WOD, Moteur 3D --

  testWidgets(
    'M6c : accueil (carte du jour), aperçu de WOD, Moteur 3D',
    (tester) async {
      store.storeClock = () => DateTime(2026, 7, 27, 9);
      store.program.start = DateTime(2026, 7, 13);
      store.startOrigin = 'user';
      final out = <String, Object?>{};
      await pumpHome(
        tester,
        HomeScreen(
          key: const ValueKey('m6c-home'),
          referenceDate: DateTime(2026, 7, 27, 9),
        ),
        true,
      );
      await waitFor(
        tester,
        () => find.byType(TargetedMannequin).evaluate().isNotEmpty,
        seconds: 30,
      );
      await ready(tester);
      await tester.pump(const Duration(seconds: 2));
      await shot('accueil_sombre');
      out['accueil'] = {
        ...await check(tester),
        'semantique': semantics(tester),
      };
      final wod = store.wods.firstWhere((w) => store.isCatalog(w));
      await pumpHome(
        tester,
        WodPreviewScreen(key: const ValueKey('m6c-wod'), wodId: wod.id),
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
      out['wod'] = {'id': wod.id, ...await check(tester)};
      store.storeClock = DateTime.now;
      await pumpHome(
        tester,
        const Engine3DScreen(key: ValueKey('m6c-moteur'), autoMeasure: false),
        true,
      );
      await ready(tester);
      await tester.pump(const Duration(seconds: 3));
      await shot('moteur3d');
      out['moteur3d'] = await check(tester);
      releve['accueil_wod_moteur'] = out;
      record();
    },
    timeout: _limit,
    skip: _skip('b'),
  );
}
