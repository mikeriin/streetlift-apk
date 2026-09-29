// M6c (mannequin 3D) : squelette Mixamo du personnage « Ch36 », exposé au
// code pour le lecteur d'animations (M7).
//
// `assets/anatomy/squelette_mixamo.json` (tools/anatomy/build_character.py) :
// 65 os (préfixe `mixamorig1:` du FBX retiré), parents, têtes et queues de
// la pose de repos en T (pose de liaison de la peau, repère glTF : y en
// haut, avant = +z, gauche anatomique = +x, mètres), repères des os, et la
// pose d'affichage du mannequin fixe (bras abaissés). Les animations Mixamo
// « Without Skin » nomment leurs os avec un préfixe (`mixamorig:`,
// `mixamorig1:`…) : [MixamoSkeleton.canonical] les ramène à ces noms.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Un os du squelette Mixamo.
class MixamoBone {
  /// Nom sans préfixe (`LeftArm`, `Hips`…).
  final String name;

  /// Parent (null pour `Hips`, la racine).
  final String? parent;

  /// Tête et queue dans la pose de repos (en T), repère glTF, mètres.
  final vm.Vector3 head, tail;

  const MixamoBone(this.name, this.parent, this.head, this.tail);

  /// Longueur de l'os (m).
  double get length => (tail - head).length;
}

/// Rotation de la pose d'affichage : axe du repère de repos, angle (degrés).
typedef MixamoRotation = ({vm.Vector3 axis, double degrees});

class MixamoSkeleton {
  static const asset = 'assets/anatomy/squelette_mixamo.json';

  /// Préfixe des os dans le FBX du personnage.
  static const fbxPrefix = 'mixamorig1:';

  /// Os, parents avant enfants (ordre du FBX).
  final List<MixamoBone> bones;

  /// Pose d'affichage du mannequin fixe : rotations par os, appliquées à la
  /// tête de l'os, composées le long de la chaîne.
  final Map<String, List<MixamoRotation>> displayPose;

  final Map<String, MixamoBone> _byName;

  MixamoSkeleton(this.bones, this.displayPose)
    : _byName = {for (final b in bones) b.name: b};

  factory MixamoSkeleton.fromJson(Map<String, dynamic> j) {
    vm.Vector3 v(Object? o) {
      final l = [for (final x in o! as List) (x as num).toDouble()];
      return vm.Vector3(l[0], l[1], l[2]);
    }

    final rotations =
        ((j['pose_affichage'] as Map?)?['rotations'] as Map?) ?? const {};
    return MixamoSkeleton(
      [
        for (final b in j['os'] as List)
          MixamoBone(
            (b as Map)['nom'] as String,
            b['parent'] as String?,
            v(b['tete']),
            v(b['queue']),
          ),
      ],
      {
        for (final e in rotations.entries)
          e.key as String: [
            for (final r in e.value as List)
              (
                axis: v((r as List)[0]),
                degrees: (r[1] as num).toDouble(),
              ),
          ],
      },
    );
  }

  /// Nom d'os sans préfixe (`mixamorig:LeftArm` → `LeftArm`).
  static String canonical(String name) {
    final i = name.lastIndexOf(':');
    return i < 0 ? name : name.substring(i + 1);
  }

  /// Os de ce nom (préfixé ou non), ou null.
  MixamoBone? operator [](String name) => _byName[canonical(name)];

  /// Enfants directs d'un os.
  List<MixamoBone> childrenOf(String name) => [
    for (final b in bones)
      if (b.parent == canonical(name)) b,
  ];

  static Future<MixamoSkeleton>? _cache;

  /// Squelette déjà chargé, s'il y en a un.
  static MixamoSkeleton? loaded;

  /// Chargé une seule fois par lancement.
  static Future<MixamoSkeleton> load([AssetBundle? bundle]) =>
      _cache ??= (bundle ?? rootBundle)
          .loadString(asset)
          .then(
            (s) => loaded = MixamoSkeleton.fromJson(
              jsonDecode(s) as Map<String, dynamic>,
            ),
          );
}
