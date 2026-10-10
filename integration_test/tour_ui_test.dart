// UI0 (refonte UI, cahier §6.2, §6.3, PIPELINE_UI.md §3) : tour de captures
// des écrans principaux et relevé des parcours, sur émulateur Android, lancé
// par tools/ci_ui_drive.sh (tâche « tour » de ci-ui.yml) :
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/tour_ui_test.dart \
//     --dart-define=UI_TOUR_PART=a --dart-define=KALIS_DEV=true -d emulator-5554
// Parties : a = sombre, bordeaux, session personnelle ; b = clair, neon,
// personnelle ; c = sombre, neon, session de test ; d = clair, bordeaux,
// session de test.
// Le même fichier tourne sur le lot (« après ») et sur main b7996b3f
// (« avant », palettes sous leurs anciens noms rouge et jaune) : il n'utilise
// que l'API commune aux deux (magasin, racine `kalisApp`, écrans existants,
// textes et clés), jamais le kit.
// Relevé `tour_releve_<partie>.json` : écrans ouverts, parcours (nombre
// d'appuis, chemin suivi, null si impossible), textes sous le dock en bas
// des onglets. Captures `tour_<partie>_<nn>_<écran>.png`.
//
// Ajouter un écran au tour (lots UI1 à UI4) : une ligne `await screen(...)`
// dans la section de la zone (même nom de fichier dans les deux colonnes) ;
// ajouter un parcours : une entrée de `routes` (chemins candidats, du plus
// court au plus long ; le premier qui aboutit est relevé).
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/athlete_profile_screen.dart';
import 'package:streetlift_tracker/dev/dev_session.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/pilotage_screen.dart';
import 'package:streetlift_tracker/plan/evolution_widgets.dart';
import 'package:streetlift_tracker/plan/event_day_screen.dart';
import 'package:streetlift_tracker/plan/season_view.dart';
import 'package:streetlift_tracker/program_screens.dart';
import 'package:streetlift_tracker/session_screen.dart';
import 'package:streetlift_tracker/store.dart';

final _root = GlobalKey();
const _part = String.fromEnvironment('UI_TOUR_PART', defaultValue: 'a');

/// Palette demandée sous son nom actuel ou, sur la base, sous son ancien nom.
String _palette(String id) {
  if (kAccentIds.contains(id)) return id;
  return const {'bordeaux': 'rouge', 'neon': 'jaune'}[id] ?? kAccentIds.first;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  final data = <String, Object?>{};
  final dark = _part == 'a' || _part == 'c';
  final dev = _part == 'c' || _part == 'd';
  final palette = (_part == 'a' || _part == 'd') ? 'bordeaux' : 'neon';
  final releve = <String, Object?>{
    'partie': _part,
    'theme': dark ? 'sombre' : 'clair',
    'palette': palette,
    'palette_enregistree': _palette(palette),
    'session': dev ? 'test' : 'personnelle',
    'ecrans': <String, Object?>{},
    'parcours': <String, Object?>{},
    'sous_le_dock': <String, Object?>{},
  };
  binding.reportData = data;
  var shots = 0;

  void record() => data['tour_releve_$_part.json'] =
      const JsonEncoder.withIndent('  ').convert(releve);

  Future<void> shot(String name) async {
    final boundary =
        _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    shots++;
    final n = shots.toString().padLeft(2, '0');
    data['tour_${_part}_${n}_$name.png'] = base64Encode(
      png.buffer.asUint8List(),
    );
    image.dispose();
    record();
  }

  Future<void> wait(WidgetTester tester, [int ms = 1200]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<bool> until(WidgetTester tester, Finder f, {int max = 150}) async {
    for (var i = 0; i < max && f.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return f.evaluate().isNotEmpty;
  }

  Finder vertical() => find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .hitTestable();

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    for (final dy in const [-260.0, 260.0]) {
      for (var i = 0; i < 40 && target.hitTestable().evaluate().isEmpty; i++) {
        final lists = vertical();
        if (lists.evaluate().isEmpty) break;
        final s = tester.state<ScrollableState>(lists.last).position;
        if ((dy < 0 && s.pixels >= s.maxScrollExtent) ||
            (dy > 0 && s.pixels <= s.minScrollExtent)) {
          break;
        }
        await tester.drag(lists.last, Offset(0, dy));
        await wait(tester, 300);
      }
    }
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.last);
      await wait(tester, 400);
    }
  }

  Future<void> toEnd(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      final lists = vertical();
      if (lists.evaluate().isEmpty) return;
      final s = tester.state<ScrollableState>(lists.last).position;
      if (s.pixels >= s.maxScrollExtent - 1) break;
      await tester.drag(lists.last, const Offset(0, -500));
      await wait(tester, 300);
    }
    await wait(tester, 600);
  }

  Future<void> home(WidgetTester tester) async {
    appNavigator.currentState!.popUntil((r) => r.isFirst);
    await wait(tester, 800);
    final tab = find.byKey(const ValueKey('nav-2'));
    if (tab.evaluate().isNotEmpty) {
      await tester.tap(tab.first);
      await wait(tester, 800);
    }
  }

  Future<void> push(WidgetTester tester, Widget screen, [int ms = 1800]) async {
    unawaited(
      appNavigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
    await wait(tester, ms);
  }

  Future<void> tab(WidgetTester tester, int i) async {
    final f = find.byKey(ValueKey('nav-$i'));
    if (f.evaluate().isEmpty) return;
    await tester.tap(f.first);
    await wait(tester, 1500);
  }

  /// Textes des onglets passés sous le dock en bas de page (C8 : aucun).
  Future<void> underDock(WidgetTester tester, String name) async {
    final dock = find.byType(HeroNavBar);
    if (dock.evaluate().isEmpty) return;
    final rect = tester.getRect(dock.first);
    // Pilule du dock : la bande occupée, sans la marge transparente.
    final band = Rect.fromLTRB(
      rect.left,
      rect.bottom - 80,
      rect.right,
      rect.bottom,
    );
    final hidden = <String>[];
    for (final e in find.byType(Text).evaluate()) {
      final w = e.widget as Text;
      final inDock = find
          .ancestor(of: find.byWidget(w), matching: find.byType(HeroNavBar))
          .evaluate()
          .isNotEmpty;
      if (inDock) continue;
      final box = e.renderObject;
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final r = box.localToGlobal(Offset.zero) & box.size;
      if (r.height <= 0 || r.width <= 0) continue;
      if (r.overlaps(band) && r.top < band.bottom && r.bottom > band.top) {
        hidden.add(w.data ?? w.textSpan?.toPlainText() ?? '?');
      }
    }
    (releve['sous_le_dock'] as Map<String, Object?>)[name] = hidden;
    record();
  }

  Future<void> screen(
    WidgetTester tester,
    String name, {
    Widget? open,
    Finder? check,
  }) async {
    if (open != null) await push(tester, open);
    final ok = check == null ? true : await until(tester, check, max: 60);
    (releve['ecrans'] as Map<String, Object?>)[name] = ok;
    await shot(name);
  }

  /// Parcours : chemins candidats (suites de cibles à toucher), du plus
  /// court au plus long ; relevé du premier qui aboutit à [reached].
  Future<void> route(
    WidgetTester tester,
    String name,
    List<List<Finder Function()>> paths,
    Finder Function() reached,
  ) async {
    Object? result;
    for (var p = 0; p < paths.length && result == null; p++) {
      await home(tester);
      var taps = 0;
      var ok = true;
      for (final step in paths[p]) {
        final f = step();
        await scrollTo(tester, f);
        final hit = f.hitTestable();
        if (hit.evaluate().isEmpty) {
          ok = false;
          break;
        }
        await tester.tap(hit.first);
        taps++;
        await wait(tester, 1500);
      }
      if (ok) await scrollTo(tester, reached());
      if (ok && await until(tester, reached(), max: 30)) {
        result = {'appuis': taps, 'chemin': p};
      }
    }
    (releve['parcours'] as Map<String, Object?>)[name] = result;
    record();
    await home(tester);
  }

  Finder text(String t) => find.text(t);
  Finder textCi(String t) => find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? w.textSpan?.toPlainText() ?? '').toLowerCase() ==
            t.toLowerCase(),
  );

  testWidgets('Tour UI $_part : écrans principaux et parcours', (tester) async {
    final raw = await SharedPreferences.getInstance();
    await raw.clear();
    if (dev) await DevSession.create();
    final seed = AppStore();
    await seed.init();
    seed.settings.theme = dark ? 'dark' : 'light';
    seed.settings.accent = _palette(palette);
    seed.saveSettings();
    final real = DateTime.now();
    await seed.configureStart(DateTime(real.year, real.month, real.day - 86));
    seed.saveAthleteProfile(
      ProfileDraft.of(
        sampleAthleteProfile(
          on: civilOf(real.subtract(const Duration(days: 90))),
          guidance: kc.GuidanceMode.assisted,
        ),
      )..consent = 'refused',
    );
    await seed.flush();
    seed.dispose();

    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    await tester.pumpWidget(RepaintBoundary(key: _root, child: kalisApp()));
    for (var i = 0; i < 200; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const ValueKey('opening-logo')).evaluate().isEmpty &&
          i > 25) {
        break;
      }
    }
    await wait(tester, 1500);
    releve['accueil'] = await until(
      tester,
      find.byKey(const ValueKey('nav-2')),
    );
    releve['session_de_test_active'] = DevSession.active.value;
    releve['palette_lue'] = store.settings.accent;
    record();

    // Programme (UI1).
    await screen(tester, 'accueil');
    await toEnd(tester);
    await underDock(tester, 'accueil');
    await screen(tester, 'accueil_bas');
    await home(tester);
    await screen(
      tester,
      'mon_programme',
      open: const ProgramScreen(),
      check: find.byType(ProgramScreen),
    );
    await home(tester);
    await screen(
      tester,
      'ma_saison',
      open: const SeasonScreen(),
      check: find.byType(SeasonScreen),
    );
    await home(tester);
    await screen(
      tester,
      'evolution',
      open: const EvolutionScreen(),
      check: find.byType(EvolutionScreen),
    );
    await home(tester);

    // Séance (UI2) : séance du jour, ou la prochaine.
    final now = store.storeClock();
    var sw = store.program.weekFor(now);
    var sj = (store.program.offsetOf(now) ?? 0) % 7 + 1;
    for (var k = 0; k < 7; k++) {
      final d = DateTime(now.year, now.month, now.day + k);
      final ww = store.program.weekFor(d);
      final jj = (store.program.offsetOf(d) ?? 0) % 7 + 1;
      final day = store.program.week(ww).day(jj);
      if (day != null && day.exercises.isNotEmpty) {
        sw = ww;
        sj = jj;
        break;
      }
    }
    final week = store.program.week(sw);
    final day = week.day(sj);
    releve['seance'] = 'S$sw-J$sj';
    if (day != null) {
      await screen(
        tester,
        'seance',
        open: SessionScreen(week: week, day: day),
        check: find.byType(SessionScreen),
      );
      await home(tester);
    }

    // Stats (UI3).
    await tab(tester, 1);
    await screen(tester, 'stats');
    await toEnd(tester);
    await underDock(tester, 'stats');
    await screen(tester, 'stats_bas');
    await home(tester);

    // Arsenal et Réglages (UI4). Les clés du lot (racine d'Arsenal,
    // rubriques des Réglages) n'existent pas sur la base : l'appui est alors
    // sauté et la capture montre l'écran d'avant au même endroit.
    Future<void> tapIf(WidgetTester tester, Finder f) async {
      await scrollTo(tester, f);
      final hit = f.hitTestable();
      if (hit.evaluate().isEmpty) return;
      await tester.tap(hit.first);
      await wait(tester, 1500);
    }

    Future<void> typeIn(WidgetTester tester, Finder field, String q) async {
      // L'onglet garde sa position de défilement : le champ est remonté.
      await scrollTo(tester, field);
      final f = field.hitTestable();
      if (f.evaluate().isEmpty) return;
      await tester.tap(f.first);
      await wait(tester, 400);
      await tester.enterText(f.first, q);
      await wait(tester, 1200);
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(tester, 800);
    }

    await tab(tester, 0);
    await screen(tester, 'arsenal');
    await toEnd(tester);
    await underDock(tester, 'arsenal');
    await home(tester);
    await tab(tester, 0);
    await typeIn(
      tester,
      find.byKey(const ValueKey('arsenal-search')),
      'pector',
    );
    await screen(tester, 'arsenal_recherche');
    final clearArsenal = find.byTooltip('Effacer la recherche').hitTestable();
    if (clearArsenal.evaluate().isNotEmpty) {
      await tester.tap(clearArsenal.first);
      await wait(tester, 600);
    }
    await home(tester);
    await screen(
      tester,
      'anatomie_pectoraux',
      open: const AnatomyScreen(initialGroup: 'pectoraux'),
      check: find.byType(AnatomyScreen),
    );
    await home(tester);
    await tab(tester, 3);
    await screen(tester, 'reglages');
    await toEnd(tester);
    await underDock(tester, 'reglages');
    await screen(tester, 'reglages_bas');
    await home(tester);
    await tab(tester, 3);
    await tapIf(tester, find.byKey(const ValueKey('settings-page-appearance')));
    final picker = find.byKey(const ValueKey('accent-picker'));
    await scrollTo(tester, picker);
    await screen(tester, 'reglages_apparence', check: picker);
    // UI0 : interrupteur « Contraste renforcé » sous le sélecteur.
    final contrast = find.text('Contraste renforcé');
    await scrollTo(tester, contrast);
    await screen(tester, 'reglages_contraste', check: contrast);
    await home(tester);
    await tab(tester, 3);
    await tapIf(tester, find.byKey(const ValueKey('settings-page-session')));
    await screen(tester, 'reglages_seance');
    await home(tester);
    await tab(tester, 3);
    await typeIn(
      tester,
      find.byKey(const ValueKey('settings-search')),
      'repos',
    );
    await screen(tester, 'reglages_recherche');
    // La recherche est effacée : l'onglet garde son état pour les parcours.
    final clearSearch = find.byTooltip('Effacer la recherche').hitTestable();
    if (clearSearch.evaluate().isNotEmpty) {
      await tester.tap(clearSearch.first);
      await wait(tester, 600);
    }
    await home(tester);
    await tab(tester, 3);
    await tapIf(tester, find.byKey(const ValueKey('settings-page-data')));
    await screen(tester, 'reglages_donnees');
    await home(tester);
    await tab(tester, 3);
    await tapIf(tester, find.byKey(const ValueKey('settings-page-about')));
    await screen(tester, 'reglages_aide');
    await home(tester);
    await screen(
      tester,
      'profil',
      open: const ProfileScreen(),
      check: find.byType(ProfileScreen),
    );
    await home(tester);
    await screen(
      tester,
      'references',
      open: const PilotageScreen(),
      check: find.byType(PilotageScreen),
    );
    await home(tester);

    // Parcours (cahier §6.3) : chemins de la base d'abord présents dans les
    // deux colonnes ; les lots ajoutent leurs chemins courts en tête.
    Finder settingsTab() => find.byKey(const ValueKey('nav-3'));
    await route(tester, 'mon_programme', [
      [() => text('Mon programme')],
      [settingsTab, () => text('Mon programme')],
    ], () => find.byType(ProgramScreen));
    await route(tester, 'ma_saison', [
      [
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-season')),
      ],
      [
        settingsTab,
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-season')),
      ],
    ], () => find.byType(SeasonScreen));
    await route(tester, 'evolution', [
      [
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-evolution-open')),
      ],
      [
        settingsTab,
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-evolution-open')),
      ],
    ], () => find.byType(EvolutionScreen));
    await route(tester, 'jour_j', [
      [
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-season')),
        () => find.textContaining('Jour J'),
      ],
      [
        settingsTab,
        () => text('Mon programme'),
        () => find.byKey(const ValueKey('program-season')),
        () => find.textContaining('Jour J'),
      ],
    ], () => find.byType(EventDayScreen));
    await route(tester, 'mes_references', [
      [
        settingsTab,
        () => find.byKey(const ValueKey('settings-profile')),
        () => find.byKey(const ValueKey('profile-references')),
      ],
      [settingsTab, () => text('Mes références')],
      [settingsTab, () => textCi('Profil'), () => text('Mes références')],
      [settingsTab, () => text('Programme'), () => text('Références')],
    ], () => find.byType(PilotageScreen));
    // Un réglage précis : la ligne « Repos par défaut » visible à l'écran.
    await route(tester, 'reglage_repos', [
      [settingsTab, () => text('Séance')],
      [settingsTab, () => text('Chronomètres')],
    ], () => find.text('Repos par défaut'));
    // UI4 : parcours avec saisie (recherche) ; appuis comptés onglet compris,
    // la saisie n'est pas un appui. Null si le chemin n'existe pas (base).
    Future<void> typedRoute(
      String name,
      int tabIndex,
      Finder field,
      String query,
      List<Finder Function()> steps,
      Finder Function() reached,
    ) async {
      await home(tester);
      Object? result;
      final f = find.byKey(ValueKey('nav-$tabIndex'));
      if (f.evaluate().isNotEmpty) {
        await tester.tap(f.first);
        await wait(tester, 1500);
        var taps = 1;
        await scrollTo(tester, field);
        var ok = field.hitTestable().evaluate().isNotEmpty;
        if (ok) {
          await tester.tap(field.hitTestable().first);
          taps++;
          await wait(tester, 400);
          await tester.enterText(field.hitTestable().first, query);
          await wait(tester, 1200);
          FocusManager.instance.primaryFocus?.unfocus();
          await wait(tester, 800);
        }
        for (final step in steps) {
          if (!ok) break;
          final s = step();
          await scrollTo(tester, s);
          final hit = s.hitTestable();
          if (hit.evaluate().isEmpty) {
            ok = false;
            break;
          }
          await tester.tap(hit.first);
          taps++;
          await wait(tester, 1500);
        }
        if (ok) await scrollTo(tester, reached());
        if (ok && await until(tester, reached(), max: 30)) {
          result = {'appuis': taps, 'chemin': 0, 'saisie': query};
        }
      }
      (releve['parcours'] as Map<String, Object?>)[name] = result;
      record();
      await home(tester);
    }

    await typedRoute(
      'reglage_repos_recherche',
      3,
      find.byKey(const ValueKey('settings-search')),
      'repos',
      [() => find.byKey(const ValueKey('settings-result-rest'))],
      () => find.text('Repos par défaut'),
    );
    await typedRoute(
      'exercices_muscle_recherche',
      0,
      find.byKey(const ValueKey('arsenal-search')),
      'pectoraux',
      [
        () => find.byKey(const ValueKey('arsenal-group-pectoraux')),
        () => find.byKey(const ValueKey('anatomy-exercises-pectoraux')),
      ],
      () => find.byType(ExerciseLibraryScreen),
    );
    releve['captures'] = shots;
    record();
  });
}
