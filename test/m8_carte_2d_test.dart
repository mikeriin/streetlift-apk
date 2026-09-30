// M8 (5.9.0, changement de plan du propriétaire du 30/09/2026) : carte 2D
// des 15 groupes musculaires (image du propriétaire réadaptée). Intensités
// par rôle (principal vif, secondaire atténué, stabilisateur pâle, autres
// en gris), couleurs dans la couleur dominante choisie, carte teintée sur
// la carte du jour, vues ajustées à la largeur, toucher d'un groupe
// (étiquettes), légende, 3D absente des écrans des muscles. Rendu réel sur
// émulateur : integration_test/carte_2d_m8_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  group('groupes et rôles', () {
    test('15 groupes, libellés, calques', () {
      expect(kMapGroups, hasLength(15));
      expect(mapGroupLabel('ischios'), 'Ischio-jambiers');
      expect(mapGroupLabel('tibial'), 'Tibial antérieur');
      expect(kMapLayers.take(15), [for (final g in kMapGroups) g.id]);
      expect(kMapLayers.skip(15), [
        'neutre',
        'peau',
        'sombre',
        'contour',
        'ombre',
      ]);
      for (final v in MapView.values) {
        expect(
          kMapViewLayers[v],
          containsAll(['peau', 'sombre', 'contour', 'ombre']),
        );
      }
    });

    test('chaque muscle rattaché existe dans le pack', () {
      for (final e in kMuscleToMapGroup.entries) {
        expect(atlasMuscles.containsKey(e.key), isTrue, reason: e.key);
        expect(kMapGroups.any((g) => g.id == e.value), isTrue, reason: e.key);
      }
    });

    test('principal 1, secondaire 0,62, stabilisateur 0,35 ; le plus fort', () {
      final t = mapIntensitiesFromRoles(
        primaires: const ['grand_dorsal', 'biceps_chef_long'],
        secondaires: const ['brachial', 'trapeze_inferieur'],
        stabilisateurs: const ['droit_abdomen', 'multifides'],
      );
      expect(t, {
        'dorsaux': kMapPrimary,
        // brachial (secondaire) dans le même groupe que le biceps principal
        'biceps': kMapPrimary,
        'trapezes': kMapSecondary,
        'abdominaux': kMapStabilizer,
      });
      expect(mapIntensitiesFromRoles(), isEmpty);
    });

    test('poids par muscle et par groupe, seuil de 2 %', () {
      final t = mapIntensitiesFromWeights(const {
        'vaste_lateral': 3,
        'droit_femoral': 1,
        'groupe:mollets': 2,
        'grand_fessier': .05,
        'multifides': 9,
      });
      expect(t['quadriceps'], 1.0);
      expect(t['mollets'], .5);
      expect(t.containsKey('fessiers'), isFalse); // 1,25 % : gris
      expect(t.length, 2);
    });
  });

  group('couleurs', () {
    test('gris non travaillé, couleur dominante vive au plus fort', () {
      for (final dark in [true, false]) {
        final a = SL.accentSpec;
        final vivid = dark ? a.bright : (a.vividLight ?? a.vivid);
        expect(mapHeat(1, dark), vivid);
        expect(
          MuscleMap2D.layerColor('dorsaux', const {}, dark),
          mapMuscleGray(dark),
        );
        expect(
          MuscleMap2D.layerColor('dorsaux', const {'dorsaux': 1}, dark),
          vivid,
        );
        // du principal au stabilisateur : de plus en plus près du gris
        double d(Color c) =>
            (c.r - mapMuscleGray(dark).r).abs() +
            (c.g - mapMuscleGray(dark).g).abs() +
            (c.b - mapMuscleGray(dark).b).abs();
        expect(
          d(mapHeat(kMapPrimary, dark)),
          greaterThan(d(mapHeat(kMapSecondary, dark))),
        );
        expect(
          d(mapHeat(kMapSecondary, dark)),
          greaterThan(d(mapHeat(kMapStabilizer, dark))),
        );
        expect(d(mapHeat(kMapStabilizer, dark)), greaterThan(0));
      }
    });

    test('suit la couleur dominante choisie', () {
      final saved = SL.accentSpec;
      addTearDown(() => SL.accentSpec = saved);
      for (final a in KAccentSpec.all) {
        SL.accentSpec = a;
        expect(mapHeat(1, true), a.bright, reason: a.id);
      }
    });

    test('5.9.1 : traits, modelé et bas du dos (sans groupe)', () {
      for (final dark in [true, false]) {
        expect(
          MuscleMap2D.layerColor('contour', const {}, dark),
          mapContour(dark),
        );
        expect(MuscleMap2D.layerColor('ombre', const {}, dark), kMapShade);
        // jamais en couleur, même « travaillé »
        expect(
          MuscleMap2D.layerColor('neutre', const {'neutre': 1}, dark),
          mapMuscleGray(dark),
        );
      }
      expect(kMapShade.a, inInclusiveRange(.3, .6));
    });

    test('carte du jour : teintée de la couleur du texte', () {
      const tint = Color(0xFFF4F4F4);
      expect(
        MuscleMap2D.layerColor('dorsaux', const {'dorsaux': 1}, true, tint),
        tint,
      );
      expect(
        MuscleMap2D.layerColor('dorsaux', const {}, true, tint).a,
        closeTo(.22, .01),
      );
    });
  });

  group('affichage', () {
    Widget host(Widget child, {double width = 390, bool dark = true}) =>
        MaterialApp(
          theme: buildTheme(dark),
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        );

    testWidgets('trois vues, calques de chaque vue, fond transparent', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const MuscleMap2D(intensities: {'pectoraux': 1}, height: 200)),
      );
      for (final v in MapView.values) {
        expect(find.byKey(ValueKey('map-${v.name}')), findsOneWidget);
        for (final l in kMapViewLayers[v]!) {
          final img = tester.widget<Image>(
            find.byKey(ValueKey('map-${v.name}-$l')),
          );
          expect(img.colorBlendMode, BlendMode.srcIn);
        }
      }
      final pec = tester.widget<Image>(
        find.byKey(const ValueKey('map-face-pectoraux')),
      );
      expect(pec.color, mapHeat(1, true));
      final dor = tester.widget<Image>(
        find.byKey(const ValueKey('map-dos-dorsaux')),
      );
      expect(dor.color, mapMuscleGray(true));
      expect(find.text('Face'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      // aucun fond peint derrière la carte (couleur du support)
      expect(
        find.descendant(
          of: find.byType(MuscleMap2D),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
    });

    testWidgets('hauteur réduite si la largeur manque', (tester) async {
      await tester.pumpWidget(
        host(const MuscleMap2D(height: 400, viewLabels: false), width: 200),
      );
      final face = tester.getSize(find.byKey(const ValueKey('map-face')));
      expect(face.height, lessThan(400));
      expect(
        MuscleMap2D.widthFor(MapView.values, face.height),
        closeTo(199, .5), // un pixel de marge (arrondis)
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('toucher : groupe sous le doigt', (tester) async {
      String? touched = 'aucun';
      await tester.pumpWidget(
        host(
          MuscleMap2D(
            views: const [MapView.dos],
            height: 400,
            onGroupTap: (g) => touched = g,
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const ValueKey('map-dos')));
      // Cœur du grand dorsal (vue de dos) d'après les étiquettes.
      Offset? core;
      await tester.runAsync(() async {
        for (var fy = .25; fy < .5 && core == null; fy += .01) {
          for (var fx = .2; fx < .8; fx += .01) {
            if (await mapGroupAt(MapView.dos, fx, fy) == 'dorsaux' &&
                await mapGroupAt(MapView.dos, fx + .02, fy) == 'dorsaux' &&
                await mapGroupAt(MapView.dos, fx - .02, fy) == 'dorsaux') {
              core = Offset(fx, fy);
              break;
            }
          }
        }
      });
      expect(core, isNotNull);
      await tester.tapAt(
        rect.topLeft + Offset(core!.dx * rect.width, core!.dy * rect.height),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(touched, 'dorsaux');
      // coin : hors de la figure
      await tester.tapAt(rect.topLeft + const Offset(2, 2));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(touched, isNull);
    });

    testWidgets('légende des rôles', (tester) async {
      await tester.pumpWidget(host(const MapRoleLegend()));
      for (final t in [
        'Principal',
        'Secondaire',
        'Stabilisateur',
        'Non travaillé',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.pumpWidget(host(const MapRoleLegend(stabilizers: false)));
      expect(find.text('Stabilisateur'), findsNothing);
    });

    test('résumé texte', () {
      expect(mapWorkedSummary(const {}), 'Aucun groupe travaillé');
      expect(
        mapWorkedSummary(const {'fessiers': 1, 'trapezes': .4}),
        'Trapèzes · Fessiers',
      );
    });
  });
}
