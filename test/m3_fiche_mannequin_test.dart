// M3 (mannequin 3D) — fiche exercice : muscles du pack posés sur les régions
// du mannequin pour TOUS les exercices (muscles sans région : liste
// justifiée, tous profonds), règle de la vue de départ, intensités par rôle
// (principal 1, secondaire 0,62, stabilisateur 0,35, étiré 0,25 en teinte
// distincte), fiche sans exception sur un échantillon de 50 exercices.
// M8 (5.9.0) : sans animation, rien en tête de fiche ; carte 2D des 15
// groupes dans la section « Muscles » (émulateur :
// integration_test/carte_2d_m8_test.dart).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/atlas.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/content_pack.dart';
import 'package:streetlift_tracker/engine3d.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/muscle_body.dart';
import 'package:streetlift_tracker/muscle_map_2d.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MannequinMap map;
  late ContentLibrary lib;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
    lib = await ContentLibrary.load();
    map = MannequinMap.fromJson(
      jsonDecode(await rootBundle.loadString(kMannequinMapAsset))
          as Map<String, dynamic>,
    );
    // Caches globaux remplis hors des zones de temps simulé (voir M2).
    await engine3DSupport();
    await MannequinMap.load();
  });

  List<String> ids() => [for (final e in store.content.entries) e.id];

  group('correspondance muscles du pack → régions', () {
    test('tous les exercices : chaque muscle a une région ou une raison', () {
      final covered = {for (final r in map.regions) ...r.pack};
      final uncovered = <String>{};
      var checked = 0;
      for (final id in ids()) {
        final d = lib.detail(id);
        expect(d, isNotNull, reason: id);
        for (final m in [
          ...d!.primaires,
          ...d.secondaires,
          ...d.stabilisateurs,
          ...d.etires,
        ]) {
          expect(atlasMuscles.containsKey(m), isTrue, reason: '$id : $m');
          checked++;
          if (!covered.contains(m)) {
            uncovered.add(m);
            expect(
              musclesSansRegion.containsKey(m),
              isTrue,
              reason: '$id : $m sans région ni justification',
            );
          }
        }
      }
      expect(checked, greaterThan(5000));
      // La liste justifiée ne contient que des muscles réellement sans
      // région, tous profonds.
      for (final m in musclesSansRegion.keys) {
        expect(covered.contains(m), isFalse, reason: m);
        expect(atlasMuscles[m]!.profondeur, 'profond', reason: m);
      }
      expect(uncovered, musclesSansRegion.keys.toSet());
    });

    test('chaque exercice montre au moins une région de ses principaux, '
        'secondaires ou étirés', () {
      var onlyAbsent = 0;
      for (final id in ids()) {
        final d = lib.detail(id)!;
        final m = ExerciseMuscleMap.of(
          map,
          primaires: d.primaires,
          secondaires: d.secondaires,
          etires: d.etires,
        );
        // 5.5.2 : respiration (diaphragme, plancher pelvien, transverse) :
        // rien à montrer sur l'écorché, liste en texte seulement.
        if ([
          ...d.primaires,
          ...d.secondaires,
          ...d.etires,
        ].every(musclesSansRegion.containsKey)) {
          onlyAbsent++;
          continue;
        }
        expect(
          m.intensities.isNotEmpty || m.stretched.isNotEmpty,
          isTrue,
          reason: id,
        );
      }
      expect(onlyAbsent, 3);
    });

    test('5.5.2 : écorché sans couche profonde, muscles profonds en '
        'texte', () async {
      final raw =
          jsonDecode(await rootBundle.loadString(kMannequinMapAsset))
              as Map<String, dynamic>;
      expect(raw['retirees'] as List, isEmpty);
      expect(raw['caches_au_repos'] as List, isEmpty);
      expect(map.deepIds, isEmpty);
      expect(
        (raw['muscles_sans_region'] as List).cast<String>().toSet(),
        musclesSansRegion.keys.toSet(),
      );
      for (final nom in [
        'Subscapulaire',
        'Petit pectoral',
        'Carré des lombes',
      ]) {
        expect(map.regions.where((r) => r.nom == nom), isEmpty, reason: nom);
      }
      // M6c : sur la peau du personnage, les rhomboïdes sont sous le
      // trapèze (en texte) ; le trapèze moyen a ses deux zones.
      expect(map.regions.where((r) => r.nom == 'Rhomboïdes'), isEmpty);
      expect(map.regions.where((r) => r.nom == 'Trapèze moyen'), hasLength(2));
    });
  });

  group('intensités par rôle', () {
    test('principal 1, secondaire 0,62, stabilisateur 0,35, étiré à part', () {
      final m = ExerciseMuscleMap.of(
        map,
        primaires: ['grand_dorsal'],
        secondaires: ['biceps_chef_court', 'grand_dorsal'],
        stabilisateurs: ['droit_abdomen'],
        etires: ['grand_pectoral_sterno_costal'],
      );
      double of(String pack) => [
        for (final r in map.regions)
          if (r.pack.contains(pack)) m.intensities[r.id] ?? 0,
      ].reduce((a, b) => a > b ? a : b);
      expect(of('grand_dorsal'), kIntensityPrimary);
      expect(of('biceps_chef_court'), kIntensitySecondary);
      expect(of('droit_abdomen'), kIntensityStabilizer);
      // Régions étirées : jamais aussi dans les intensités (rouge).
      final pecs = {
        for (final r in map.regions)
          if (r.pack.contains('grand_pectoral_sterno_costal')) r.id,
      };
      expect(pecs, isNotEmpty);
      expect(m.stretched.containsAll(pecs), isTrue);
      for (final id in m.stretched) {
        expect(m.intensities.containsKey(id), isFalse, reason: id);
      }
      expect(kIntensityStretched, .25);
      expect(m.hidden, isEmpty);
    });

    test('cible d’un étirement listée aussi en principal : montrée étirée', () {
      final m = ExerciseMuscleMap.of(
        map,
        primaires: ['droit_femoral', 'grand_psoas'],
        stabilisateurs: ['vaste_lateral'],
        etires: ['droit_femoral', 'grand_psoas'],
      );
      final rf = {
        for (final r in map.regions)
          if (r.pack.contains('droit_femoral')) r.id,
      };
      expect(rf, isNotEmpty);
      expect(m.stretched.containsAll(rf), isTrue);
      for (final id in rf) {
        expect(m.intensities.containsKey(id), isFalse, reason: id);
      }
      // Le stabilisateur non étiré reste en rouge.
      expect(
        m.intensities.values.every((v) => v == kIntensityStabilizer),
        isTrue,
      );
      expect(m.intensities, isNotEmpty);
    });

    test('tous les exercices avec des étirés en montrent au moins un', () {
      var count = 0;
      for (final id in ids()) {
        final d = lib.detail(id)!;
        if (d.etires.isEmpty) continue;
        count++;
        final m = ExerciseMuscleMap.of(
          map,
          primaires: d.primaires,
          secondaires: d.secondaires,
          stabilisateurs: d.stabilisateurs,
          etires: d.etires,
        );
        expect(m.stretched, isNotEmpty, reason: id);
      }
      expect(count, greaterThan(20));
    });

    test('muscles absents du modèle : listés à part (5.5.2 : profonds '
        'de l’écorché)', () {
      final m = ExerciseMuscleMap.of(
        map,
        primaires: ['rhomboides', 'trapeze_moyen'],
        stabilisateurs: ['sous_scapulaire', 'rhomboides', 'diaphragme'],
      );
      // M6c : rhomboïdes sous le trapèze sur la peau du personnage : en
      // texte, avec les profonds ; le trapèze moyen reste allumé.
      expect(m.hidden, ['rhomboides', 'sous_scapulaire', 'diaphragme']);
      expect(m.intensities, isNotEmpty);
      expect(m.intensities.containsKey('rhomboids_left'), isFalse);
      expect(m.intensities['trapezius_middle_left'], kIntensityPrimary);
      expect(m.intensities['trapezius_middle_right'], kIntensityPrimary);
      expect(m.intensities.containsKey('subscapularis_left'), isFalse);
    });

    test('teinte des étirés distincte de la rampe et du gris', () {
      for (final dark in [true, false]) {
        final s = mannequinStretch(dark);
        // Bleu : la composante bleue domine nettement (la rampe est rouge).
        expect(s.b, greaterThan(s.r + .15), reason: '$dark');
        for (final v in [0.0, .25, .35, .62, 1.0]) {
          final h = mannequinHeat(v, dark);
          expect(h.r, greaterThan(h.b), reason: '$dark $v');
        }
        expect(s, isNot(kMuscleGray));
      }
    });
  });

  group('vue de départ', () {
    test('postérieurs → Dos, antérieurs → Face, mixtes → 3/4', () {
      expect(
        exerciseStartView(['grand_fessier', 'biceps_femoral']),
        MannequinView.dos,
      );
      expect(
        exerciseStartView(['droit_abdomen', 'transverse_abdomen']),
        MannequinView.face,
      );
      expect(
        exerciseStartView(['droit_femoral', 'grand_fessier']),
        MannequinView.troisQuarts,
      );
      // Latéraux seuls : les secondaires décident.
      expect(
        exerciseStartView(['deltoide_moyen'], ['trapeze_superieur']),
        MannequinView.dos,
      );
      expect(
        exerciseStartView(['deltoide_moyen'], ['deltoide_anterieur']),
        MannequinView.face,
      );
      // Rien d'orienté : 3/4.
      expect(exerciseStartView(['deltoide_moyen']), MannequinView.troisQuarts);
      expect(exerciseStartView(const []), MannequinView.troisQuarts);
    });

    test('M6b : principaux mixtes départagés par l’aire des régions', () {
      MannequinView of(String id) {
        final d = lib.detail(id)!;
        return exerciseStartView(d.primaires, d.secondaires, map);
      }

      // Traction : grand dorsal vu de dos 1,76 × biceps vu de face (M6c,
      // peau du personnage ; M6b : 2 × 0,041 m² contre 2 × 0,020) : vue de dos (en 3/4 avant, le halo du dorsal au flanc se lisait comme
      // un pectoral).
      expect(of('traction-pronation'), MannequinView.dos);
      expect(of('traction-supination'), MannequinView.dos);
      // Surfaces comparables : 3/4, comme sans la carte.
      expect(of('dips'), MannequinView.troisQuarts);
      expect(of('back-squat'), MannequinView.troisQuarts);
      expect(of('muscle-up'), MannequinView.troisQuarts);
      // Principaux d'une seule face : inchangé.
      expect(of('souleve-de-terre'), MannequinView.dos);
      expect(of('ab-wheel'), MannequinView.face);
      // Toutes les régions ont une aire.
      expect(map.regions.every((r) => r.aire > 0), isTrue);
      // Sans aire (ancienne carte) : 3/4, comme avant.
      final bare = MannequinMap.fromJson({
        'regions': [
          for (final r in map.regions)
            {
              'id': r.id,
              'cle': r.cle,
              'cote': r.cote,
              'nom': r.nom,
              'nom_cote': r.nomCote,
              'groupe': r.groupe,
              'couche': r.couche,
              'pack': r.pack,
            },
        ],
        'groupes': map.groups,
      });
      final d = lib.detail('traction-pronation')!;
      expect(
        exerciseStartView(d.primaires, d.secondaires, bare),
        MannequinView.troisQuarts,
      );
    });

    test('chaque muscle du pack a une face', () {
      expect(muscleFaces.keys.toSet(), atlasMuscles.keys.toSet());
    });

    test('exemples du catalogue', () {
      MannequinView of(String id) {
        final d = lib.detail(id)!;
        return exerciseStartView(d.primaires, d.secondaires);
      }

      expect(of('souleve-de-terre'), MannequinView.dos);
      expect(of('hip-thrust'), MannequinView.dos);
      expect(of('ab-wheel'), MannequinView.face);
      expect(of('dips'), MannequinView.troisQuarts);
      expect(of('muscle-up'), MannequinView.troisQuarts);
      // Les trois vues sont utilisées par le catalogue.
      final used = {for (final id in ids()) of(id)};
      expect(
        used.containsAll([
          MannequinView.face,
          MannequinView.dos,
          MannequinView.troisQuarts,
        ]),
        isTrue,
      );
    });
  });

  testWidgets('légende : teinte des étirés sur le mannequin 3D', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        home: const Scaffold(
          body: Column(
            children: [
              AtlasRoleLegend(key: ValueKey('l2d')),
              AtlasRoleLegend(
                key: ValueKey('l3d'),
                stretchColor: Color(0xFF5B8DB0),
              ),
            ],
          ),
        ),
      ),
    );
    Color swatch(String key) {
      final box = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(Container),
            ),
          )
          .last;
      return (box.decoration! as BoxDecoration).color!;
    }

    expect(swatch('l2d'), heat(.25));
    expect(swatch('l3d'), const Color(0xFF5B8DB0));
  });

  group('fiche exercice', () {
    Widget host(Widget page, {required bool dark}) => MaterialApp(
      theme: buildTheme(dark),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: page,
    );

    // M8 (5.9.0) : la 3D ne sert qu'à la démonstration ; sans animation,
    // rien en tête de fiche ; muscles sur la carte 2D de la section
    // « Muscles », liste en texte dessous.
    testWidgets('M8 : pas d’animation, rien en tête ; carte 2D et liste', (
      tester,
    ) async {
      phone(tester, size: const Size(320, 720));
      await tester.pumpWidget(
        host(const ExerciseSheetScreen(id: 'souleve-de-terre'), dark: true),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseMannequin), findsNothing);
      expect(find.byKey(const ValueKey('mannequin-view')), findsNothing);
      expect(find.byType(ExerciseAtlas), findsNothing);
      await scrollToAction(tester, find.byType(MuscleMap2D));
      final map = tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
      final d = lib.detail('souleve-de-terre')!;
      expect(
        map.intensities,
        mapIntensitiesFromRoles(
          primaires: d.primaires,
          secondaires: d.secondaires,
          stabilisateurs: d.stabilisateurs,
        ),
      );
      // 5.10.0 : muscle par muscle — soulevé de terre : grand fessier,
      // ischio-jambiers et érecteurs (lombaires) au plus fort.
      expect(map.intensities['grand_fessier'], kMapPrimary);
      expect(map.intensities['biceps_femoral'], kMapPrimary);
      expect(map.intensities['lombaires'], kMapPrimary);
      expect(map.views, MapView.values);
      expect(find.byType(MapRoleLegend), findsOneWidget);
      await scrollToAction(tester, find.textContaining('Principaux : '));
      expect(tester.takeException(), isNull);
    });

    testWidgets('échantillon de 50 exercices, sombre et clair, sans '
        'exception', (tester) async {
      phone(tester);
      final all = ids();
      final step = all.length ~/ 50;
      final sample = [for (var i = 0; i < 50; i++) all[i * step]];
      expect(sample.toSet().length, 50);
      for (final (i, id) in sample.indexed) {
        await tester.pumpWidget(
          host(
            ExerciseSheetScreen(key: ValueKey(id), id: id),
            dark: i.isEven,
          ),
        );
        await tester.pumpAndSettle();
        await scrollToAction(tester, find.byType(MuscleMap2D));
        expect(tester.takeException(), isNull, reason: id);
        expect(find.byType(ExerciseMannequin), findsNothing, reason: id);
        final map = tester.widget<MuscleMap2D>(find.byType(MuscleMap2D));
        final d = lib.detail(id)!;
        // Au moins un groupe en couleur, sauf exercice dont tous les
        // muscles sont hors de la carte (respiration : profonds).
        final mapped = [
          ...d.primaires,
          ...d.secondaires,
          ...d.stabilisateurs,
        ].any(mapDrawsMuscle);
        expect(map.intensities.isNotEmpty, mapped, reason: id);
      }
      await tester.pumpWidget(const SizedBox());
    });
  });
}
