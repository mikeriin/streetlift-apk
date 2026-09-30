// M2 (mannequin 3D) — carte des régions du mannequin, correspondance avec
// les groupes et les muscles du pack, rampe historique, repli 2D sans
// Flutter GPU (le moteur de test n'en a pas : c'est le cas d'un téléphone
// incompatible), écran Anatomie (Arsenal › Anatomie), Réglages › Affichage
// 3D, crédits du modèle dans « Sources et licences ». Le rendu réel est
// vérifié sur émulateur par integration_test/moteur_3d_test.dart.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/arsenal_screen.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/settings_screen.dart';
import 'package:streetlift_tracker/store.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'phone_test_support.dart';

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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    map = MannequinMap.fromJson(
      jsonDecode(await rootBundle.loadString(kMannequinMapAsset))
          as Map<String, dynamic>,
    );
    // Caches globaux (vérification du moteur, carte) remplis hors des
    // zones de temps simulé des tests d'écran : un futur créé dans la zone
    // d'un test ne se termine plus une fois ce test fini.
    await engine3DSupport();
    await MannequinMap.load();
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

  group('carte des régions', () {
    test('les 11 groupes de l’application, chacun représenté', () {
      expect(map.groups, atlasGroups);
      for (final g in atlasGroups) {
        expect(map.ofGroup(g), isNotEmpty, reason: g);
      }
      for (final r in map.regions) {
        expect(atlasGroups, contains(r.groupe), reason: r.id);
        expect(r.nom, isNotEmpty);
        expect(r.nomCote, contains(r.cote == 'left' ? 'gauche' : 'droit'));
      }
      expect(map.regions.map((r) => r.id).toSet().length, map.regions.length);
    });

    test('chaque muscle superficiel du pack a au moins une région', () {
      final covered = {for (final r in map.regions) ...r.pack};
      for (final p in covered) {
        expect(atlasMuscles.containsKey(p), isTrue, reason: 'inconnu : $p');
      }
      for (final e in atlasMuscles.entries) {
        if (e.value.profondeur != 'superficiel') continue;
        expect(covered, contains(e.key), reason: e.key);
      }
    });

    test('groupe d’une région = groupe de son muscle du pack', () {
      for (final r in map.regions) {
        if (r.pack.isEmpty) continue;
        expect(r.groupe, atlasMuscles[r.pack.first]!.groupe, reason: r.id);
      }
    });

    test('intensités depuis les groupes et depuis le pack', () {
      final dos = map.fromGroups({'dos': 1});
      expect(
        dos.keys,
        containsAll(['latissimus_dorsi_left', 'trapezius_upper_right']),
      );
      expect(dos.values.every((v) => v == 1), isTrue);
      final pack = map.fromPack({
        'grand_dorsal': kIntensityPrimary,
        'biceps_chef_long': kIntensitySecondary,
        'droit_abdomen': kIntensityStabilizer,
      });
      expect(pack['latissimus_dorsi_left'], 1);
      expect(pack['latissimus_dorsi_right'], 1);
      expect(pack['biceps_brachii_left'], .62);
      expect(pack['rectus_abdominis_right'], .35);
      expect(map.groupsOf(pack), {'dos': 1, 'biceps': .62, 'gainage': .35});
      expect(map.names(pack), [
        'Grand dorsal',
        'Biceps brachial',
        "Droit de l'abdomen",
      ]);
    });

    test('mains et pieds : volumes sélectionnables', () {
      final hand = map.byId['hand_left']!;
      expect(hand.couche, 'volume');
      expect(hand.pack, ['muscles_intrinseques_main']);
      expect(map.byId['foot_right']!.groupe, 'mollets');
      expect(map.byId.containsKey('head'), isFalse);
    });
  });

  test('rampe identique à la carte 2D, dans la couleur dominante choisie', () {
    for (final accent in [KAccentSpec.rouge, KAccentSpec.turquoise]) {
      SL.accentSpec = accent;
      for (final dark in [true, false]) {
        SL.dark = dark;
        for (final v in [.35, .62, 1.0]) {
          expect(mannequinHeat(v, dark), heat(v), reason: '$dark $v');
        }
        // 5.5.2 : le haut de la rampe est la teinte vive (claire en sombre)
        // de la dominante, le bas sa teinte principale.
        final top = dark ? accent.bright : (accent.vividLight ?? accent.vivid);
        expect(mannequinHeat(1, dark), top);
        expect(mannequinHeat(0, dark), Color.lerp(accent.principal, top, .15));
      }
    }
    SL.accentSpec = KAccentSpec.rouge;
    SL.dark = true;
  });

  testWidgets('sans Flutter GPU : carte 2D historique, sans exception', (
    tester,
  ) async {
    phone(tester);
    var ready = <bool>[];
    await tester.pumpWidget(
      page(
        Scaffold(
          body: SingleChildScrollView(
            child: Mannequin3D(
              intensities: map.fromGroups({'pectoraux': 1}),
              onReady: (ok) => ready = [...ready, ok],
            ),
          ),
        ),
      ),
    );
    await _settle(tester, find.byType(MuscleHeatmap));
    expect(find.byKey(const ValueKey('mannequin-fallback')), findsOneWidget);
    expect(find.byKey(const ValueKey('mannequin-views')), findsNothing);
    final heatmap = tester.widget<MuscleHeatmap>(find.byType(MuscleHeatmap));
    expect(heatmap.data, {'pectoraux': 1.0});
    expect(ready, [false]);
    expect(tester.takeException(), isNull);
  });

  for (final (size, scale, dark) in [
    (const Size(390, 844), 1.0, true),
    (const Size(320, 720), 2.0, false),
  ]) {
    testWidgets('écran Anatomie ${size.width.toInt()} px, '
        'texte ${(scale * 100).round()} %', (tester) async {
      phone(tester, size: size);
      AnatomyScreen.session = null;
      await tester.pumpWidget(
        page(const AnatomyScreen(), scale: scale, dark: dark),
      );
      await _settle(tester, find.byType(MuscleMap2D));
      expect(find.text('ANATOMIE'), findsWidgets);
      // M4b : le groupe se coche dans le menu « Filtres ».
      Future<void> toggleDos() async {
        await scrollToAction(
          tester,
          find.byKey(const ValueKey('anatomy-filters')),
          up: true,
        );
        await tester.tap(find.byKey(const ValueKey('anatomy-filters')));
        await tester.pumpAndSettle();
        // CheckboxMenuButton transmet sa clé à son MenuItemButton.
        final box = find.byKey(const ValueKey('anatomy-filter-dorsaux')).first;
        await tester.ensureVisible(box);
        await tester.pumpAndSettle();
        await tester.tap(box);
        await tester.pumpAndSettle();
        // Toucher en dehors : le menu se ferme.
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('anatomy-filter-dorsaux')),
          findsNothing,
        );
      }

      await toggleDos();
      final list = find.byKey(const ValueKey('anatomy-group-list'));
      await scrollToAction(tester, list);
      expect(
        find.descendant(
          of: list,
          matching: find.textContaining('Grand dorsal'),
        ),
        findsOneWidget,
      );
      expect(
        tester.state<AnatomyScreenState>(find.byType(AnatomyScreen)).groups,
        {'dorsaux'},
      );
      // M8 : carte 2D des groupes (plus de mannequin 3D).
      await scrollToAction(tester, find.byType(MuscleMap2D), up: true);
      final map2d = tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
      expect(map2d.intensities, {'dorsaux': 1.0});
      // Second appui : plus de groupe, plus de liste.
      await toggleDos();
      expect(list, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  test('toucher : intersection rayon-triangle, la plus proche', () {
    final m = PickMesh(
      't',
      Float32List.fromList([0, 0, 0, 1, 0, 0, 0, 1, 0]),
      const [0, 1, 2],
      vm.Vector3(0, 0, 0),
      vm.Vector3(1, 1, 0),
    );
    final dir = vm.Vector3(0, 0, 1);
    expect(m.intersect(vm.Vector3(.2, .2, -1), dir), closeTo(1, 1e-9));
    expect(m.intersect(vm.Vector3(.8, .8, -1), dir), isNull);
    expect(m.intersect(vm.Vector3(.2, .2, 1), dir), isNull);
    expect(m.intersect(vm.Vector3(.2, .2, -1), dir, .5), isNull);
  });

  testWidgets('Arsenal › Anatomie ouvre l’écran', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const ArsenalScreen()));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('arsenal-anatomy'));
    await scrollToAction(tester, tile);
    await tester.tap(tile);
    await _settle(tester, find.text('ANATOMIE'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Réglages › Affichage 3D : deux réglages activés, enregistrés '
      '(M6c : plus de « Os visibles »)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    Display3DSettings.instance.reset();
    phone(tester);
    await tester.pumpWidget(page(const SettingsScreen(section: 10)));
    await _settle(tester, find.text('Halo'));
    expect(find.text('AFFICHAGE 3D'), findsOneWidget);
    // M6c : personnage à la peau lisse, plus d'os à afficher.
    expect(find.text('Os visibles'), findsNothing);
    expect(find.byKey(const ValueKey('settings-3d-bones')), findsNothing);
    for (final key in ['names', 'halo']) {
      final tile = tester.widget<SwitchListTile>(
        find.descendant(
          of: find.byKey(ValueKey('settings-3d-$key')),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(tile.value, isTrue, reason: key);
    }
    await tester.tap(find.text('Halo'));
    await tester.pumpAndSettle();
    expect(Display3DSettings.instance.halo.value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('kt3d_halo'), isFalse);
    expect(prefs.getBool('kt3d_nom_toucher'), isTrue);
    expect(prefs.containsKey('kt3d_os_visibles'), isFalse);
    Display3DSettings.instance.reset();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sources et licences : crédits du modèle 3D', (tester) async {
    phone(tester);
    await tester.pumpWidget(page(const MentionsScreen()));
    final credit = find.textContaining('Mixamo');
    // Titre des crédits du modèle : le texte des mentions est chargé.
    await _settle(tester, find.textContaining('MANNEQUIN ANATOMIQUE 3D'));
    await scrollToAction(tester, credit);
    await scrollToAction(
      tester,
      find.textContaining('tools/anatomy/build_character.py'),
    );
    expect(tester.takeException(), isNull);
  });
}
