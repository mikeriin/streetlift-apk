// M6c (mannequin 3D) : personnage Mixamo « Ch36 », zones musculaires sur
// la peau, squelette Mixamo exposé au code, réglages sans objet retirés.
// Le modèle d'exécution est chiffré dans assets_secure/ (déchiffré par la
// CI avant les tests) ; ici, la carte et le squelette (assets en clair).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/anatomy_screen.dart';
import 'package:streetlift_tracker/atlas_data.dart';
import 'package:streetlift_tracker/exercise_mannequin.dart';
import 'package:streetlift_tracker/mannequin_3d.dart';
import 'package:streetlift_tracker/mixamo_skeleton.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MannequinMap map;
  late MixamoSkeleton skeleton;

  setUpAll(() async {
    map = await MannequinMap.load();
    skeleton = await MixamoSkeleton.load();
  });

  group('squelette Mixamo (M7)', () {
    test('65 os, racine Hips, parents avant enfants', () {
      expect(skeleton.bones, hasLength(65));
      expect(skeleton.bones.first.name, 'Hips');
      expect(skeleton.bones.first.parent, isNull);
      final seen = <String>{};
      for (final b in skeleton.bones) {
        if (b.parent != null) expect(seen, contains(b.parent), reason: b.name);
        seen.add(b.name);
      }
      for (final name in [
        'Spine2',
        'Neck',
        'Head',
        'LeftShoulder',
        'LeftArm',
        'LeftForeArm',
        'LeftHand',
        'LeftHandIndex3',
        'RightUpLeg',
        'RightLeg',
        'RightFoot',
        'RightToeBase',
      ]) {
        expect(skeleton[name], isNotNull, reason: name);
      }
    });

    test('noms préfixés des animations Mixamo', () {
      expect(MixamoSkeleton.canonical('mixamorig:LeftArm'), 'LeftArm');
      expect(MixamoSkeleton.canonical('mixamorig1:Hips'), 'Hips');
      expect(MixamoSkeleton.canonical('Spine'), 'Spine');
      expect(skeleton['mixamorig1:LeftForeArm']!.parent, 'LeftArm');
      expect(MixamoSkeleton.fbxPrefix, 'mixamorig1:');
      expect(
        skeleton.childrenOf('LeftHand').map((b) => b.name),
        containsAll([
          'LeftHandThumb1',
          'LeftHandIndex1',
          'LeftHandMiddle1',
          'LeftHandRing1',
          'LeftHandPinky1',
        ]),
      );
    });

    test('pose de repos en T, symétrique, 1,77 m', () {
      final l = skeleton['LeftHand']!.head, r = skeleton['RightHand']!.head;
      final arm = skeleton['LeftArm']!.head;
      expect(
        (l.y - arm.y).abs(),
        lessThan(.03),
        reason: 'bras à l’horizontale',
      );
      expect(l.x, closeTo(-r.x, .005));
      expect(l.x, greaterThan(.5));
      expect(skeleton['HeadTop_End']!.head.y, closeTo(1.76, .03));
      expect(skeleton['LeftUpLeg']!.length, greaterThan(.35));
      // Pose d'affichage : bras abaissés, os connus.
      expect(skeleton.displayPose.keys, containsAll(['LeftArm', 'RightArm']));
      for (final bone in skeleton.displayPose.keys) {
        expect(skeleton[bone], isNotNull, reason: bone);
      }
    });
  });

  group('zones sur la peau', () {
    test('muscles superficiels du pack : chacun a une zone', () {
      final covered = {for (final r in map.regions) ...r.pack};
      for (final e in atlasMuscles.entries) {
        if (e.value.profondeur == 'superficiel') {
          expect(covered, contains(e.key), reason: e.key);
        }
      }
      expect(
        atlasMuscles.keys.toSet().difference(covered),
        musclesSansRegion.keys.toSet(),
      );
    });

    test('zones des 11 groupes, symétriques, aires vues de face et de dos', () {
      final groups = {for (final r in map.regions) r.groupe};
      expect(groups, AppStore.muscleGroups.toSet());
      for (final r in map.regions) {
        final other =
            map.byId[r.cote == 'left'
                ? r.id.replaceFirst(RegExp(r'_left$'), '_right')
                : r.id.replaceFirst(RegExp(r'_right$'), '_left')];
        expect(other, isNotNull, reason: r.id);
        expect(r.aire, greaterThan(0), reason: r.id);
        expect(r.aireFace + r.aireDos, greaterThan(0), reason: r.id);
        expect(r.aireFace, lessThanOrEqualTo(r.aire + 1e-5), reason: r.id);
      }
    });

    test('vue de départ des fiches sur la peau du personnage', () {
      // Traction : grand dorsal (vu de dos) contre biceps (vu de face).
      expect(
        exerciseStartView(
          ['grand_dorsal', 'biceps_chef_long', 'biceps_chef_court'],
          const [],
          map,
        ),
        MannequinView.dos,
      );
      expect(kStartViewDominance, 1.65);
    });
  });

  test('plus de réglage « Os visibles » ni de filtre « Os »', () {
    expect(AnatomyFilters.total, 17); // 5.10.0 : 17 groupes de la carte 2D
    expect(AnatomyFilters.categories.map((c) => c.id), ['groupes']);
    expect(AnatomyFilters.none.count, 0);
  });

  test('assets : carte, squelette et crédits (Mixamo)', () async {
    final credits = await rootBundle.loadString(kMannequinAttributionAsset);
    expect(credits, contains('Mixamo'));
    expect(credits, contains('Ecorche Musclenames Male Anatomy'));
    final raw = await rootBundle.loadString(kMannequinMapAsset);
    expect(raw, contains('"schema": 3'));
    expect(raw, contains('"zones_source": "ecorche"'));
  });
}
