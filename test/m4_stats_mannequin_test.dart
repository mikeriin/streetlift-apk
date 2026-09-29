// M4 (mannequin 3D) — STATS : résumé hebdomadaire sur le mannequin.
// Les intensités du mannequin sont celles de la carte 2D de 5.2.0 (même
// calcul, même normalisation, même seuil), comparées chiffre à chiffre sur
// des données de test ; chaque groupe a des muscles sur le mannequin ; la
// légende écrit la valeur de chaque groupe ; l'onglet Performances se
// construit sans exception (semaine type, semaine vide, sombre et clair). Le
// moteur de test n'a pas Flutter GPU : la carte 2D historique prend le
// relais, avec les mêmes données qu'avant. Rendu 3D réel vérifié sur
// émulateur (integration_test/stats_semaine_test.dart).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/stats_mannequin.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

/// Normalisation de la carte 2D de 5.2.0, recopiée telle quelle
/// (`MuscleHeatmap.build` puis le filtre de `_View`) : la référence.
Map<String, double> _reference520(Map<String, double> data) {
  final max = data.values.fold<double>(0, (a, b) => b > a ? b : a);
  final t = {
    for (final e in data.entries) e.key: max == 0 ? 0.0 : e.value / max,
  };
  return {
    for (final e in t.entries)
      if (e.value > 0.02) e.key: e.value,
  };
}

/// Semaine type : toutes les séries des trois premières journées du
/// programme validées aujourd'hui.
void fillWeek(AppStore app) {
  final now = DateTime.now().toIso8601String();
  for (var day = 1; day <= 3; day++) {
    final plan = app.program.week(1).day(day);
    if (plan == null) continue;
    for (final ex in plan.exercises) {
      for (final set in app.exLog(1, day, ex).sets) {
        set
          ..done = true
          ..completedAt = now;
      }
    }
  }
  app.notifyListeners();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MannequinMap map;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    map = MannequinMap.fromJson(
      jsonDecode(await rootBundle.loadString(kMannequinMapAsset))
          as Map<String, dynamic>,
    );
    // Caches globaux remplis hors des zones de temps simulé (voir M2).
    await engine3DSupport();
  });

  setUp(() {
    store.logs.clear();
    store.notifyListeners();
  });

  /// Contrôle chiffré : chaque région prend exactement l'intensité de son
  /// groupe sur la carte 2D de 5.2.0 ; aucune autre région n'est allumée.
  void expectSameAsBefore(Map<String, double> data) {
    final ref = _reference520(data);
    final got = weeklyRegionIntensities(map, data);
    var lit = 0;
    for (final r in map.regions) {
      final want = r.couche == 'volume' ? null : ref[r.groupe];
      expect(got[r.id], want, reason: '${r.id} (${r.groupe}) $data');
      if (want != null) lit++;
    }
    expect(got.length, lit);
    // La carte 2D elle-même garde ses chiffres.
    final t = heatmapIntensities(data);
    for (final e in data.entries) {
      final max = data.values.fold<double>(0, (a, b) => b > a ? b : a);
      expect(t[e.key], max == 0 ? 0.0 : e.value / max);
    }
  }

  group('mêmes intensités que la carte 2D', () {
    test('données de test chiffrées', () {
      const cases = <Map<String, double>>[
        {'dos': 12, 'biceps': 7.2, 'avant-bras': 3.6, 'gainage': .2},
        {'pectoraux': 9, 'triceps': 5.4, 'épaules': 5.4, 'quadriceps': .1},
        {'quadriceps': 16, 'fessiers': 9.6, 'ischios': 9.6, 'mollets': 4},
        {'gainage': 1},
        {'dos': 0, 'biceps': 0},
        {},
      ];
      for (final data in cases) {
        expectSameAsBefore(data);
      }
      // Valeurs attendues écrites en clair (premier cas).
      final got = weeklyRegionIntensities(map, cases.first);
      final lat = map.regions.firstWhere((r) => r.cle == 'latissimus_dorsi');
      final bic = map.regions.firstWhere((r) => r.groupe == 'biceps');
      final fa = map.regions.firstWhere(
        (r) => r.groupe == 'avant-bras' && r.couche != 'volume',
      );
      expect(got[lat.id], 1.0);
      expect(got[bic.id], closeTo(.6, 1e-12));
      expect(got[fa.id], closeTo(.3, 1e-12));
      // Gainage à 0,2 / 12 ≈ 1,7 % : sous le seuil, non coloré (comme 2D).
      expect(
        map.regions.where((r) => r.groupe == 'gainage').map((r) => got[r.id]),
        everyElement(isNull),
      );
    });

    test('semaine type du store : mêmes chiffres, 2D et 3D', () {
      fillWeek(store);
      final weekly = store.weeklyMuscles();
      expect(weekly.values.where((v) => v > 0).length, greaterThan(2));
      expectSameAsBefore(weekly);
    });

    test('semaine vide : aucun muscle allumé', () {
      final weekly = store.weeklyMuscles();
      expect(weekly.values.every((v) => v == 0), isTrue);
      expect(weeklyRegionIntensities(map, weekly), isEmpty);
    });

    test('chaque groupe a des muscles sur le mannequin', () {
      for (final g in AppStore.muscleGroups) {
        expect(
          map.regions.where((r) => r.groupe == g && r.couche != 'volume'),
          isNotEmpty,
          reason: g,
        );
      }
    });

    test('mains et pieds restent sombres', () {
      final got = weeklyRegionIntensities(map, const {
        'avant-bras': 5,
        'mollets': 5,
      });
      for (final r in map.regions.where((r) => r.couche == 'volume')) {
        expect(got.containsKey(r.id), isFalse, reason: r.id);
      }
    });
  });

  test('légende : valeur lisible à la française', () {
    expect(MuscleLegend.format(12), '12');
    expect(MuscleLegend.format(12.6), '12,6');
    expect(MuscleLegend.format(3.6000000000000005), '3,6');
    expect(MuscleLegend.format(.04), '0');
    expect(MuscleLegend.format(7.25), '7,3');
  });

  group('onglet Performances', () {
    Future<void> open(WidgetTester tester, {required bool dark}) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      store.settings.theme = dark ? 'dark' : 'light';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(dark),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const StatsScreen(
            initialSection: StatsSection.performance,
            standalone: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(WeeklyMannequin),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
    }

    for (final dark in [true, false]) {
      final theme = dark ? 'sombre' : 'clair';
      testWidgets('semaine type ($theme)', (tester) async {
        fillWeek(store);
        final weekly = store.weeklyMuscles();
        await open(tester, dark: dark);
        final w = tester.widget<WeeklyMannequin>(find.byType(WeeklyMannequin));
        expect(w.groups, weekly);
        // Sans Flutter GPU : carte 2D historique, mêmes données qu'avant.
        final heatmap = tester.widget<MuscleHeatmap>(
          find.byType(MuscleHeatmap),
        );
        expect(heatmap.data, weekly);
        expect(heatmap.height, 220);
        expect(heatmap.normalize, isTrue);
        // Légende chiffrée : chaque groupe travaillé avec sa valeur.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('stats-muscles-unite')),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        for (final e in weekly.entries.where((e) => e.value > 0)) {
          final label =
              '${e.key[0].toUpperCase()}${e.key.substring(1)}'
              ' · ${MuscleLegend.format(e.value)}';
          expect(find.text(label), findsOneWidget, reason: label);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('semaine vide ($theme)', (tester) async {
        await open(tester, dark: dark);
        expect(find.byType(WeeklyMannequin), findsOneWidget);
        expect(
          find.text('Valide tes séries pour voir ta répartition musculaire.'),
          findsOneWidget,
        );
        expect(find.byType(MuscleLegend), findsNothing);
        expect(find.byKey(const ValueKey('stats-muscles-unite')), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });
}
