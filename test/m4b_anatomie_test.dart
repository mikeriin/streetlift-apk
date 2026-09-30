// M4b (mannequin 3D) — tous les muscles remis (couche profonde, régions
// cachées au repos ; 5.5.2 : l'écorché acheté n'a plus de couche profonde,
// les muscles profonds sont en texte), opacité unique des muscles, règle du
// toucher à travers
// les muscles translucides (muscle sollicité le plus proche, sinon le plus
// proche, arrêt à la première surface opaque), bulle « (profond) », filtres à
// cocher de l'écran Anatomie (union des groupes, compteur, tout cocher /
// décocher, muscles profonds, os, session, libellés d'accessibilité). Le
// rendu réel est vérifié sur émulateur par
// integration_test/anatomie_m4b_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'phone_test_support.dart';

/// Carré d'un côté [size] dans le plan z = [z], centré sur l'axe z.
PickMesh _quad(String name, double z, {double size = 1}) {
  final h = size / 2;
  return PickMesh(
    name,
    Float32List.fromList([-h, -h, z, h, -h, z, h, h, z, -h, h, z]),
    const [0, 1, 2, 0, 2, 3],
    vm.Vector3(-h, -h, z),
    vm.Vector3(h, h, z),
  );
}

MuscleRegion _region(String id, String couche, {String groupe = 'dos'}) =>
    MuscleRegion(
      id: id,
      cle: id,
      cote: 'left',
      nom: id,
      nomCote: '$id (gauche)',
      groupe: groupe,
      couche: couche,
      pack: const [],
    );

Future<void> _settle(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
  expect(ready, findsWidgets);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MannequinMap map;
  late Map<String, dynamic> raw;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    raw =
        jsonDecode(await rootBundle.loadString(kMannequinMapAsset))
            as Map<String, dynamic>;
    map = MannequinMap.fromJson(raw);
    await engine3DSupport();
    await MannequinMap.load();
  });

  group('modèle complet', () {
    test('5.5.2 : aucune région retirée ni cachée, couche superficielle', () {
      expect(raw['retirees'] as List, isEmpty);
      expect(map.hiddenAtRest, isEmpty);
      expect(map.byId['neck_muscles_left']!.groupe, 'dos');
      expect(map.byId['sternocleidomastoid_right']!.groupe, 'dos');
    });

    test('muscles du pack : région ou justification (profonds absents)', () {
      final covered = {for (final r in map.regions) ...r.pack};
      final absent = atlasMuscles.keys.toSet().difference(covered);
      expect(absent, musclesSansRegion.keys.toSet());
      for (final m in absent) {
        expect(atlasMuscles[m]!.profondeur, 'profond', reason: m);
      }
      // M6c : 24 (coraco-brachial, élévateur de la scapula, extenseurs
      // cervicaux, rhomboïdes : sous d'autres muscles sur la peau).
      expect(absent, hasLength(24));
    });

    test('couche de chaque région : superficiel ou volume', () {
      for (final r in map.regions) {
        expect(['superficiel', 'volume'], contains(r.couche), reason: r.id);
      }
      expect(map.deepIds, isEmpty);
      expect(map.byId['hand_left']!.couche, 'volume');
      expect(map.byId['latissimus_dorsi_left']!.couche, 'superficiel');
      // Subdivisions du pack (zones de l'écorché projetées sur la peau).
      for (final id in [
        'deltoid_anterior_left',
        'deltoid_lateral_right',
        'deltoid_posterior_left',
        'trapezius_upper_left',
        'trapezius_middle_right',
        'trapezius_lower_left',
        'pectoralis_major_clavicular_right',
        'pectoralis_major_sternocostal_left',
        'pectoralis_major_abdominal_right',
        'gastrocnemius_medial_left',
        'gastrocnemius_lateral_right',
        'erector_spinae_right',
        'iliopsoas_left',
      ]) {
        expect(map.byId.containsKey(id), isTrue, reason: id);
      }
    });

    test('opacité unique des muscles : 100 % (5.5.3)', () {
      expect(kMuscleOpacity, 1.0); // 5.5.3 : opaque
    });

    test('bulle : « (profond) » pour un muscle profond (carte de test)', () {
      expect(
        _region('rhomboid_major_left', 'profond').label,
        'rhomboid_major_left (gauche) (profond) · Dos',
      );
      expect(
        map.byId['latissimus_dorsi_right']!.label,
        'Grand dorsal (droit) · Dos',
      );
      expect(
        map.byId['trapezius_middle_left']!.label,
        'Trapèze moyen (gauche) · Dos',
      );
    });
  });

  group('toucher à travers les muscles translucides', () {
    // Rayon le long de +z depuis z = -1 : « avant » (z 0), « milieu »
    // (z 0,5), « arriere » (z 1), peau nue (z 1,5, M6c : ex-os), « loin »
    // (z 2) derrière elle.
    final test2 = MannequinMap(
      [
        _region('avant', 'superficiel'),
        _region('milieu', 'profond'),
        _region('arriere', 'profond'),
        _region('loin', 'superficiel'),
        _region('main', 'volume', groupe: 'avant-bras'),
      ],
      const ['dos', 'avant-bras'],
    );
    final meshes = [
      _quad('arriere', 1),
      _quad('avant', 0),
      // M6c : peau sans zone (ex-os) : surface opaque hors carte.
      _quad('peau', 1.5),
      _quad('milieu', .5),
      _quad('loin', 2),
    ];
    final o = vm.Vector3(0, 0, -1), d = vm.Vector3(0, 0, 1);

    MuscleRegion? pick({
      Map<String, double> lit = const {},
      Set<String> stretched = const {},
      Set<String> hidden = const {},
      Iterable<PickMesh>? on,
      // Règle du toucher à travers des muscles translucides (5.5.3 : les
      // muscles de l'application sont opaques, la règle reste testée).
      double opacity = .5,
    }) => MannequinScene.pickAlong(
      o,
      d,
      on ?? meshes,
      test2,
      intensities: lit,
      stretched: stretched,
      hidden: hidden,
      opacity: opacity,
    );

    test('aucun muscle sollicité : le plus proche', () {
      expect(pick()!.id, 'avant');
    });

    test('muscle sollicité caché : le sollicité le plus proche', () {
      expect(pick(lit: {'arriere': 1})!.id, 'arriere');
      expect(pick(lit: {'arriere': 1, 'milieu': .35})!.id, 'milieu');
      expect(pick(stretched: {'arriere'})!.id, 'arriere');
    });

    test('la première surface opaque arrête le rayon', () {
      // « loin » est derrière la peau nue : jamais atteint, même sollicité.
      expect(pick(lit: {'loin': 1})!.id, 'avant');
      // Sans la peau nue : le rayon continue jusqu'à « loin ».
      expect(
        pick(lit: {'loin': 1}, on: meshes.where((m) => m.name != 'peau'))!.id,
        'loin',
      );
    });

    test('régions masquées ignorées', () {
      expect(pick(hidden: {'avant'})!.id, 'milieu');
      expect(pick(hidden: {'avant', 'milieu', 'arriere'})?.id, isNull);
    });

    test('main ou pied (opaque) : candidat qui arrête le rayon', () {
      final withHand = [_quad('main', .75), ...meshes];
      expect(pick(on: withHand, lit: {'arriere': 1})!.id, 'avant');
      expect(pick(on: withHand, hidden: {'avant', 'milieu'})!.id, 'main');
    });

    test('muscles opaques (opacité 1) : la surface la plus proche', () {
      expect(pick(lit: {'arriere': 1}, opacity: 1)!.id, 'avant');
    });
  });

  group('filtres', () {
    test('union des groupes, compteur, tout cocher / décocher', () {
      const f = AnatomyFilters();
      expect(f.count, 0); // M6c : plus de « Os » (M6b : « Muscles profonds »)
      final g = f.toggleGroup('dorsaux').toggleGroup('ischios');
      expect(g.groups, {'dorsaux', 'ischios'});
      expect(g.count, 2);
      expect(g.orderedGroups, ['dorsaux', 'ischios']);
      expect(g.toggleGroup('dorsaux').groups, {'ischios'});
      expect(AnatomyFilters.all.count, AnatomyFilters.total);
      expect(AnatomyFilters.all.groups, {for (final m in kMapGroups) m.id});
      expect(AnatomyFilters.none.count, 0);
      // M8 : les 15 groupes de la carte 2D.
      expect(AnatomyFilters.total, 16); // 5.10.0 : lombaires
      expect(AnatomyFilters.categories.map((c) => c.id), ['groupes']);
      expect(AnatomyFilters.fromSelection(g.selection), g);
      expect(g, g.toggleGroup('biceps').toggleGroup('biceps'));
    });
  });

  Widget page(Widget child, {double scale = 1, bool dark = true}) =>
      MaterialApp(
        theme: buildTheme(dark),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      );

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('anatomy-filters')));
    await tester.pumpAndSettle();
  }

  Future<void> tapItem(WidgetTester tester, String key) async {
    // CheckboxMenuButton transmet sa clé à son MenuItemButton : deux widgets.
    final item = find.byKey(ValueKey('anatomy-filter-$key')).first;
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  AnatomyScreenState state(WidgetTester tester) =>
      tester.state<AnatomyScreenState>(find.byType(AnatomyScreen));

  for (final (size, scale, dark) in [
    (const Size(390, 844), 1.0, true),
    (const Size(320, 720), 2.0, false),
  ]) {
    testWidgets('écran Anatomie ${size.width.toInt()} px, texte '
        '${(scale * 100).round()} % : filtres à cocher', (tester) async {
      phone(tester, size: size);
      AnatomyScreen.session = null;
      await tester.pumpWidget(
        page(const AnatomyScreen(), scale: scale, dark: dark),
      );
      await _settle(tester, find.byType(MuscleMap2D));
      expect(find.text('Filtres · 0'), findsOneWidget);
      // Résumé sous le mannequin (liste qui défile).
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('anatomy-summary-empty')),
      );
      expect(
        find.byKey(const ValueKey('anatomy-summary-empty')),
        findsOneWidget,
      );
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('anatomy-filters')),
        up: true,
      );

      // Plusieurs groupes cochés sans fermer le menu : union.
      await openMenu(tester);
      await tapItem(tester, 'dorsaux');
      await tapItem(tester, 'ischios');
      await tapItem(tester, 'pectoraux');
      expect(
        find.byKey(const ValueKey('anatomy-filter-dorsaux')),
        findsWidgets,
      );
      expect(state(tester).groups, {'dorsaux', 'ischios', 'pectoraux'});
      expect(find.text('Filtres · 3'), findsOneWidget);
      // Toucher en dehors : le menu se ferme.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('anatomy-filter-dorsaux')),
        findsNothing,
      );
      MuscleMap2D mapWidget() =>
          tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
      expect(
        mapWidget().intensities,
        mapIntensitiesFromGroups({'pectoraux', 'dorsaux', 'ischios'}),
      );
      // 5.10.0 : muscle par muscle
      expect(mapWidget().intensities['grand_dorsal'], 1.0);
      expect(mapWidget().intensities['semi_tendineux'], 1.0);
      expect(mapWidget().intensities.containsKey('trapeze_moyen'), isFalse);
      expect(mapWidget().views, MapView.values);
      final list = find.byKey(const ValueKey('anatomy-group-list'));
      await scrollToAction(tester, list);
      expect(
        find.byKey(const ValueKey('anatomy-group-muscles-dorsaux')),
        findsOneWidget,
      );
      final dos = tester.widget<Text>(
        find.byKey(const ValueKey('anatomy-group-muscles-dorsaux')),
      );
      expect(dos.data, contains('Grand dorsal'));
      expect(dos.data, contains('Grand rond'));
      expect(
        find.byKey(const ValueKey('anatomy-group-muscles-ischios')),
        findsOneWidget,
      );
      await scrollToAction(
        tester,
        find.byKey(const ValueKey('anatomy-filters')),
        up: true,
      );

      // M6b : plus de case « Muscles profonds » ; M6c : plus de case
      // « Os » ni de catégorie « Affichage » ; aucune région masquée.
      await openMenu(tester);
      expect(find.byKey(const ValueKey('anatomy-filter-deep')), findsNothing);
      expect(find.text('Muscles profonds'), findsNothing);
      expect(find.byKey(const ValueKey('anatomy-filter-bones')), findsNothing);
      expect(find.text('Affichage'), findsNothing);
      expect(find.byType(Mannequin3D), findsNothing);
      expect(find.text('Filtres · 3'), findsOneWidget);

      // Tout cocher, tout décocher (M4c : par catégorie).
      await tapItem(tester, 'all-groupes');
      expect(state(tester).filters, AnatomyFilters.all);
      expect(find.text('Filtres · 16'), findsOneWidget);
      expect(
        mapWidget().intensities.length,
        kMapRegions.where((r) => r.group != null).length,
      );
      await tapItem(tester, 'none-groupes');
      expect(state(tester).filters, AnatomyFilters.none);
      expect(find.text('Filtres · 0'), findsOneWidget);
      expect(mapWidget().intensities, isEmpty);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cases lues par l’accessibilité (libellé, état coché)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    phone(tester);
    AnatomyScreen.session = null;
    await tester.pumpWidget(page(const AnatomyScreen()));
    await _settle(tester, find.byType(MuscleMap2D));
    expect(
      tester.getSemantics(find.byKey(const ValueKey('anatomy-filters'))),
      isSemantics(
        label: 'Filtres, 0 actif sur 16',
        isButton: true,
        hasTapAction: true,
      ),
    );
    await openMenu(tester);
    await tapItem(tester, 'fessiers');
    // M4c : chaque case est lue avec sa catégorie.
    for (final (key, label, checked) in [
      ('fessiers', 'Fessiers, Groupes musculaires', true),
      ('dorsaux', 'Dorsaux, Groupes musculaires', false),
      ('mollets', 'Mollets, Groupes musculaires', false),
    ]) {
      expect(
        tester.getSemantics(find.byKey(ValueKey('anatomy-filter-$key')).first),
        isSemantics(
          label: label,
          hasCheckedState: true,
          isChecked: checked,
          hasTapAction: true,
        ),
        reason: key,
      );
    }
    handle.dispose();
  });

  testWidgets('filtres gardés pendant la session', (tester) async {
    phone(tester);
    AnatomyScreen.session = null;
    await tester.pumpWidget(page(const AnatomyScreen()));
    await _settle(tester, find.byType(MuscleMap2D));
    await openMenu(tester);
    await tapItem(tester, 'mollets');
    await tapItem(tester, 'fessiers');
    await tapItem(tester, 'fessiers');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    // Écran refermé puis rouvert : mêmes filtres.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(const AnatomyScreen()));
    await _settle(tester, find.byType(MuscleMap2D));
    expect(state(tester).groups, {'mollets'});
    expect(find.text('Filtres · 1'), findsOneWidget);
    // Groupe demandé à l'ouverture : il remplace les groupes de la session.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page(const AnatomyScreen(initialGroup: 'dorsaux')));
    await _settle(tester, find.byType(MuscleMap2D));
    expect(state(tester).groups, {'dorsaux'});
    expect(find.text('Filtres · 1'), findsOneWidget);
    AnatomyScreen.session = null;
  });
}
