// M8 (5.9.0, changement de plan du propriétaire du 30/09/2026) : carte 2D
// des muscles (image du propriétaire réadaptée). 5.10.0 (correction 2) :
// carte muscle par muscle, anatomiquement vérifiée : un exercice n'allume
// que les régions de ses muscles, les muscles profonds restent en texte ;
// intensités par rôle (principal vif, secondaire atténué, stabilisateur
// pâle, autres en gris), couleurs dans la couleur dominante choisie, carte
// teintée sur la carte du jour, vues ajustées à la largeur, toucher d'une
// région (étiquettes), légende. Rendu réel sur émulateur :
// integration_test/carte_2d_m8_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentLibrary lib;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    lib = await ContentLibrary.load();
  });

  group('régions et groupes', () {
    test('16 filtres, régions uniques, muscles du pack', () {
      expect(kMapGroups, hasLength(16));
      expect(mapGroupLabel('ischios'), 'Ischio-jambiers');
      expect(mapGroupLabel('lombaires'), 'Lombaires');
      final ids = [for (final r in kMapRegions) r.id];
      expect(ids.toSet(), hasLength(ids.length));
      expect(kMapRegions.length, lessThan(kMapSombre));
      final groups = {for (final g in kMapGroups) g.id};
      for (final r in kMapRegions) {
        if (r.group != null) expect(groups, contains(r.group), reason: r.id);
        for (final m in r.muscles) {
          expect(atlasMuscles.containsKey(m), isTrue, reason: '${r.id} $m');
        }
      }
      // un muscle dans une seule région
      final seen = <String>{};
      for (final r in kMapRegions) {
        for (final m in r.muscles) {
          expect(seen.add(m), isTrue, reason: m);
        }
      }
      // chaque filtre allume au moins une région
      for (final g in kMapGroups) {
        expect(mapIntensitiesFromGroups({g.id}), isNotEmpty, reason: g.id);
      }
    });

    test('muscles profonds : jamais dessinés (listés en texte)', () {
      for (final m in const [
        'transverse_abdomen',
        'oblique_interne',
        'petit_pectoral',
        'supra_epineux',
        'sous_scapulaire',
        'coraco_brachial',
        'vaste_intermediaire',
        'petit_fessier',
        'rotateurs_lateraux_hanche',
        'court_adducteur',
        'poplite',
        'diaphragme',
        'plancher_pelvien',
        'flechisseurs_cervicaux_profonds',
        'supinateur',
        'carre_pronateur',
      ]) {
        expect(mapDrawsMuscle(m), isFalse, reason: m);
      }
      for (final m in const [
        'grand_dorsal',
        'erecteurs_lombaires',
        'vaste_medial',
        'soleaire',
        'tibial_anterieur',
        'dentele_anterieur',
        'infra_epineux',
      ]) {
        expect(mapDrawsMuscle(m), isTrue, reason: m);
      }
    });

    test('principal 1, secondaire 0,62, stabilisateur 0,35 ; le plus fort', () {
      final t = mapIntensitiesFromRoles(
        primaires: const ['grand_dorsal', 'biceps_chef_long'],
        secondaires: const ['brachial', 'trapeze_inferieur', 'biceps_chef_court'],
        stabilisateurs: const ['droit_abdomen', 'multifides', 'transverse_abdomen'],
      );
      expect(t, {
        'grand_dorsal': kMapPrimary,
        // chef court secondaire, même région que le chef long principal
        'biceps': kMapPrimary,
        'brachial': kMapSecondary,
        'trapeze_inferieur': kMapSecondary,
        'droit_abdomen': kMapStabilizer,
        'lombaires': kMapStabilizer,
      });
      expect(mapIntensitiesFromRoles(), isEmpty);
    });

    test('poids par muscle et par groupe, seuil de 2 %', () {
      final t = mapIntensitiesFromWeights(const {
        'vaste_lateral': 4,
        'droit_femoral': 1,
        'groupe:mollets': 2,
        'grand_fessier': .05,
        'transverse_abdomen': 9,
      });
      expect(t['vaste_lateral'], 1.0);
      expect(t['droit_femoral'], .25);
      expect(t['vaste_medial'], isNull); // pas sollicité : gris
      expect(t['soleaire'], .5);
      expect(t['gastrocnemien_medial'], .5);
      expect(t.containsKey('grand_fessier'), isFalse); // 1,25 % : gris
    });

    test('exercices de référence : les bons muscles, rien d’autre', () {
      Map<String, double> of(String id) {
        final d = lib.detail(id)!;
        return mapIntensitiesFromRoles(
          primaires: d.primaires,
          secondaires: d.secondaires,
          stabilisateurs: d.stabilisateurs,
        );
      }

      final squat = of('back-squat');
      expect(squat['vaste_lateral'], kMapPrimary);
      expect(squat['grand_fessier'], kMapPrimary);
      expect(squat.containsKey('grand_pectoral'), isFalse);
      expect(squat.containsKey('biceps'), isFalse);
      final deadlift = of('souleve-de-terre');
      expect(deadlift['lombaires'], kMapPrimary);
      expect(deadlift['grand_fessier'], kMapPrimary);
      expect(deadlift['droit_abdomen'], kMapStabilizer);
      expect(deadlift.containsKey('grand_pectoral'), isFalse);
      final pull = of('traction-pronation');
      expect(pull['grand_dorsal'], kMapPrimary);
      expect(pull.containsKey('grand_pectoral'), isFalse);
      expect(pull.containsKey('vaste_lateral'), isFalse);
      // toutes les fiches : chaque région allumée montre un muscle de la fiche
      for (final e in store.content.entries) {
        final d = lib.detail(e.id);
        if (d == null) continue;
        final muscles = {...d.primaires, ...d.secondaires, ...d.stabilisateurs};
        for (final r in of(e.id).keys) {
          expect(
            mapRegion(r)!.muscles.any(muscles.contains),
            isTrue,
            reason: '${e.id} $r',
          );
        }
      }
    });
  });

  group('couleurs', () {
    test('gris non travaillé, couleur dominante vive au plus fort', () {
      final pec = kMapRegions.indexWhere((r) => r.id == 'grand_pectoral') + 1;
      for (final dark in [true, false]) {
        final a = SL.accentSpec;
        final vivid = dark ? a.bright : (a.vividLight ?? a.vivid);
        expect(mapHeat(1, dark), vivid);
        expect(mapLabelColor(pec, const {}, dark), mapMuscleGray(dark));
        expect(
          mapLabelColor(pec, const {'grand_pectoral': 1}, dark),
          vivid,
        );
        expect(mapLabelColor(kMapPeau, const {}, dark), mapSkinGray(dark));
        expect(mapLabelColor(kMapSombre, const {}, dark), mapDarkGray(dark));
        expect(mapLabelColor(0, const {}, dark).a, 0);
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

    test('muscles du cou sans groupe ni muscle du pack : toujours gris', () {
      final cou = kMapRegions.indexWhere((r) => r.id == 'cou') + 1;
      expect(mapLabelColor(cou, const {'cou': 1}, true), mapMuscleGray(true));
    });

    test('carte du jour : teintée de la couleur du texte', () {
      const tint = Color(0xFFF4F4F4);
      final lat = kMapRegions.indexWhere((r) => r.id == 'grand_dorsal') + 1;
      expect(
        mapLabelColor(lat, const {'grand_dorsal': 1}, true, tint: tint),
        tint,
      );
      expect(
        mapLabelColor(lat, const {}, true, tint: tint).a,
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

    testWidgets('trois vues, traits et modelé, fond transparent', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MuscleMap2D(intensities: {'grand_pectoral': 1}, height: 200),
        ),
      );
      for (final v in MapView.values) {
        expect(find.byKey(ValueKey('map-${v.name}')), findsOneWidget);
        final contour = tester.widget<Image>(
          find.byKey(ValueKey('map-${v.name}-contour')),
        );
        expect(contour.colorBlendMode, BlendMode.srcIn);
        expect(contour.color, mapContour(true));
        final shade = tester.widget<Image>(
          find.byKey(ValueKey('map-${v.name}-ombre')),
        );
        expect(shade.color, kMapShade);
      }
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

    testWidgets('étiquettes : régions attendues aux bons endroits', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // cœur de quelques muscles, en fractions de chaque vue
        Future<Set<String?>> around(MapView v, String region) async {
          final out = <String?>{};
          for (var fy = 0.0; fy < 1; fy += .01) {
            for (var fx = 0.0; fx < 1; fx += .01) {
              if (await mapRegionAt(v, fx, fy) == region) out.add(region);
            }
          }
          return out;
        }

        for (final (v, r) in const [
          (MapView.dos, 'grand_dorsal'),
          (MapView.dos, 'lombaires'),
          (MapView.dos, 'trapeze_moyen'),
          (MapView.face, 'grand_pectoral'),
          (MapView.face, 'vaste_medial'),
          (MapView.face, 'tibial_anterieur'),
          (MapView.profil, 'deltoide_moyen'),
        ]) {
          expect(await around(v, r), {r}, reason: '${v.name} $r');
        }
        // haut du dos : trapèze supérieur au-dessus du moyen, lui-même
        // au-dessus de l'inférieur, sur l'axe
        final labels = await loadMapLabels(MapView.dos);
        int firstRow(String region) {
          final k = kMapRegions.indexWhere((r) => r.id == region) + 1;
          for (var y = 0; y < labels.height; y++) {
            for (var x = 0; x < labels.width; x++) {
              if (labels.values[y * labels.width + x] == k) return y;
            }
          }
          return -1;
        }

        expect(
          firstRow('trapeze_superieur'),
          lessThan(firstRow('trapeze_moyen')),
        );
        expect(
          firstRow('trapeze_moyen'),
          lessThan(firstRow('trapeze_inferieur')),
        );
      });
    });

    testWidgets('toucher : région sous le doigt', (tester) async {
      String? touched = 'aucun';
      await tester.pumpWidget(
        host(
          MuscleMap2D(
            views: const [MapView.dos],
            height: 400,
            onRegionTap: (g) => touched = g,
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const ValueKey('map-dos')));
      Offset? core;
      await tester.runAsync(() async {
        for (var fy = .25; fy < .5 && core == null; fy += .01) {
          for (var fx = .2; fx < .8; fx += .01) {
            if (await mapRegionAt(MapView.dos, fx, fy) == 'grand_dorsal' &&
                await mapRegionAt(MapView.dos, fx + .02, fy) ==
                    'grand_dorsal' &&
                await mapRegionAt(MapView.dos, fx - .02, fy) ==
                    'grand_dorsal') {
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
      expect(touched, 'grand_dorsal');
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

    test('résumé texte : groupes, puis régions sans groupe', () {
      expect(mapWorkedSummary(const {}), 'Aucun groupe travaillé');
      expect(
        mapWorkedSummary(const {
          'grand_fessier': 1,
          'trapeze_moyen': .4,
          'couturier': .5,
        }),
        'Trapèzes · Fessiers · Couturier',
      );
    });
  });
}
