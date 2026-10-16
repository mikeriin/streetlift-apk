// M4 → M8 — STATS : résumé hebdomadaire des muscles sollicités.
// M8 (5.9.0, changement de plan du propriétaire du 30/09/2026) : carte 2D
// des 15 groupes (plus de mannequin 3D hors démonstration et Koach).
// Contrôles chiffrés : poids par groupe de l'application (`groupe:<g>`) ou
// par muscle du pack ramenés au plus fort, seuil de 2 % (comme avant) ;
// chaque groupe de l'application a sa place sur la carte ; la légende écrit
// la valeur de chaque groupe ; l'onglet Performances se construit sans
// exception (semaine type, semaine vide, sombre et clair). Rendu réel sur
// émulateur (integration_test/carte_2d_m8_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/main.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/stats_mannequin.dart';
import 'package:streetlift_tracker/stats_navigation.dart';
import 'package:streetlift_tracker/stats_screen.dart';
import 'package:streetlift_tracker/store.dart';

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

  late ContentLibrary lib;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    store.settings
      ..sound = false
      ..vibration = false
      ..wakelock = false
      ..autoTimer = false;
    lib = await ContentLibrary.load();
  });

  setUp(() {
    store.logs.clear();
    store.notifyListeners();
  });

  Map<String, double> byGroup(Map<String, double> data) => {
    for (final e in data.entries) 'groupe:${e.key}': e.value,
  };

  group('intensités de la carte', () {
    test('groupes de l’application : chiffres écrits en clair', () {
      final got = mapIntensitiesFromWeights(
        byGroup(const {
          'dos': 12,
          'biceps': 7.2,
          'avant-bras': 3.6,
          'gainage': .2,
        }),
      );
      // 5.10.0 : régions de chaque groupe. dos → dorsaux (1) et trapèzes
      // (0,6) ; gainage 0,2 / 12 ≈ 1,7 % : sous le seuil, gris (comme la
      // carte historique).
      expect(got['grand_dorsal'], 1.0);
      expect(got['grand_rond'], 1.0);
      expect(got['trapeze_moyen'], closeTo(.6, 1e-12));
      expect(got['rhomboides'], closeTo(.6, 1e-12));
      expect(got['biceps'], closeTo(.6, 1e-12));
      expect(got['brachial'], closeTo(.6, 1e-12));
      expect(got['brachio_radial'], closeTo(.3, 1e-12));
      expect(got.containsKey('droit_abdomen'), isFalse);
      expect(got.containsKey('lombaires'), isFalse);
      // régions sans groupe (cou, psoas, couturier) : jamais par groupe
      expect(got.containsKey('couturier'), isFalse);
      expect(got.containsKey('sterno_cleido_mastoidien'), isFalse);
    });

    test('semaine vide : aucun groupe en couleur', () {
      expect(mapIntensitiesFromWeights(byGroup(store.weeklyMuscles())), {});
      expect(mapIntensitiesFromWeights(const {'dos': 0}), {});
      expect(targetedMapIntensities(lib, const {}, const {}), {});
    });

    test('chaque groupe de l’application a sa place sur la carte', () {
      final ids = {for (final g in kMapGroups) g.id};
      for (final g in AppStore.muscleGroups) {
        final m = kAppGroupToMap[g];
        expect(m, isNotNull, reason: g);
        expect(ids.containsAll(m!), isTrue, reason: g);
      }
    });

    test('semaine type : muscles des fiches, bornés à 1', () {
      fillWeek(store);
      final names = store.weeklyNames();
      expect(names, isNotEmpty);
      final got = targetedMapIntensities(lib, names, store.weeklyMuscles());
      expect(got, isNotEmpty);
      expect(got.values.reduce((a, b) => a > b ? a : b), 1.0);
      for (final v in got.values) {
        expect(v, inInclusiveRange(kMapMinIntensity, 1.0));
      }
      expect(got, mapIntensitiesFromWeights(targetedMuscles(lib, names)));
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
        find.byType(TargetedMuscleMap),
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
        final w = tester.widget<TargetedMuscleMap>(
          find.byType(TargetedMuscleMap),
        );
        expect(w.groups, weekly);
        expect(w.names, store.weeklyNames());
        final map = tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
        expect(map.views, MapView.values);
        expect(
          map.intensities,
          targetedMapIntensities(lib, store.weeklyNames(), weekly),
        );
        expect(map.intensities, isNotEmpty);
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
        final map = tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
        expect(map.intensities, isEmpty);
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
