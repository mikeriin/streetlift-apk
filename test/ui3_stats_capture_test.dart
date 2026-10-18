// UI3 (refonte UI) — captures de la zone Stats (PIPELINE_UI.md §3) : les
// quatre onglets, la page Records et chaque feuille de jeu, en sombre et en
// clair, palettes `bordeaux` et `neon`, sur un journal d'exemple ; puis les
// mêmes pages à 320 dp et 200 % de texte (aucun débordement). Lancé par la CI
// avec --dart-define=KALIS_CAPTURE=true ; fichiers validation/UI/ui3_*.png,
// recopiés dans ci-out/captures-ui/.
//
// Le même fichier a tourné sur `refonte-ui` 0e5342df avant le lot (préfixe
// « ui3_avant_ ») : les fonctions d'ouverture des feuilles gardent leur nom.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/game_widgets.dart';
import 'package:streetlift_tracker/records_screen.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_progression.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

import 'support/ui_capture.dart';

const _prefix = 'ui3';

/// Journal d'exemple : départ il y a 60 jours, trois séances par semaine
/// pendant huit semaines, charges en progression (records), références.
Future<void> seedStats() async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day - 60);
  await store.configureStart(start);
  store.logs.clear();
  var kg = 10.0;
  for (var w = 1; w <= 8; w++) {
    final week = store.program.week(w);
    final days = week.days.where((d) => d.exercises.isNotEmpty).take(3);
    for (final day in days) {
      final at = start.add(Duration(days: (w - 1) * 7 + day.j - 1, hours: 18));
      store.sessionLog(w, day.j)
        ..done = true
        ..title = 'S$w · ${day.title}'
        ..finishedAt = at.toIso8601String();
      var i = 0;
      for (final exercise in day.exercises.take(4)) {
        final log = store.exLog(w, day.j, exercise);
        if (w == 3 && i == 0) log.note = 'Amplitude complète, tempo contrôlé';
        for (final set in log.sets) {
          set
            ..done = true
            ..kg = i.isEven ? kg.toStringAsFixed(1) : ''
            ..reps = '${6 + (w % 3)}'
            ..completedAt = at.toIso8601String();
        }
        i++;
      }
    }
    kg += 2.5;
  }
  store.setValue('B4', 72);
  store.setValue('B8', 30);
  store.notifyListeners();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = GlobalKey();

  setUpAll(() async {
    await loadUiFonts();
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false
      ..celebrations = false;
    await seedStats();
  });

  Future<BuildContext> open(
    WidgetTester tester,
    Widget screen, {
    required bool dark,
    required String palette,
    double width = 390,
    double height = 3400,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    store.settings.theme = dark ? 'dark' : 'light';
    store.settings.accent = palette;
    await tester.pumpWidget(
      RepaintBoundary(
        key: root,
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(dark, KAccentSpec.byId(palette)),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    return tester.element(find.byType(Scaffold).first);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: name);
    await saveUiPng(tester, root, '${_prefix}_$name', pixelRatio: 1.5);
  }

  final pages = <String, Widget Function()>{
    'apercu': () => const StatsScreen(),
    'parcours': () => const StatsScreen(initialSection: StatsSection.journey),
    'performances': () =>
        const StatsScreen(initialSection: StatsSection.performance),
    'historique': () => const StatsScreen(initialSection: StatsSection.history),
    'records': () => const RecordsScreen(),
  };

  final sheets = <String, void Function(BuildContext)>{
    'personnage': showCharacterSheet,
    'serie': showStreak,
    'defis': showStatsMissions,
    'campagne': showCampaign,
    'saisons': showSeasons,
    'titres': showTitles,
    'xp': showStatsRules,
    'boss': (c) {
      final boss = store.game.nextBoss ?? store.game.bosses.first;
      showBoss(c, boss);
    },
  };

  testWidgets('Stats : onglets et Records × sombre, clair × bordeaux, neon', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final palette in ['bordeaux', 'neon']) {
      for (final dark in [true, false]) {
        final mode = dark ? 'sombre' : 'clair';
        for (final p in pages.entries) {
          await open(tester, p.value(), dark: dark, palette: palette);
          await shot(tester, '${p.key}_${palette}_$mode');
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !uiCaptureEnabled);

  testWidgets('Stats : feuilles de jeu × sombre, clair × bordeaux, neon', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final palette in ['bordeaux', 'neon']) {
      for (final dark in [true, false]) {
        final mode = dark ? 'sombre' : 'clair';
        for (final s in sheets.entries) {
          final context = await open(
            tester,
            const StatsScreen(initialSection: StatsSection.journey),
            dark: dark,
            palette: palette,
            height: 844,
          );
          s.value(context);
          await tester.pump(const Duration(milliseconds: 600));
          await shot(tester, 'feuille_${s.key}_${palette}_$mode');
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !uiCaptureEnabled);

  testWidgets('Stats : 320 dp et 200 % de texte, sans débordement', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    for (final p in pages.entries) {
      await open(
        tester,
        p.value(),
        dark: true,
        palette: 'bordeaux',
        width: 320,
        height: 3600,
        scale: 2,
      );
      await shot(tester, '320_${p.key}');
    }
    for (final s in ['personnage', 'boss', 'titres']) {
      final context = await open(
        tester,
        const StatsScreen(initialSection: StatsSection.journey),
        dark: true,
        palette: 'bordeaux',
        width: 320,
        height: 720,
        scale: 2,
      );
      sheets[s]!(context);
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, '320_feuille_$s');
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: !uiCaptureEnabled);
}
