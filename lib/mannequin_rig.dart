// M5 / M56 (mannequin 3D) : squelette d'animation et peau du mannequin.
//
// `assets/anatomy/rig.json` (fabriqué par tools/anatomy/build_rig.py) : 54
// os (30 segments anatomiques, 18 os d'aide qui prennent une fraction (1/3,
// 2/3, 1/2) de la rotation d'une articulation et gonflent avec sa flexion,
// 6 os de gonflement de contraction : biceps, quadriceps, grand fessier,
// dont l'échelle croît avec la flexion de l'articulation motrice), têtes au
// repos, degrés de liberté et limites, postures de référence (rotations
// locales par os, translation du bassin). Les échelles des os d'aide et de
// gonflement sont recalculées ici à chaque posture ([MannequinRig.withHelpers]),
// comme à la fabrication (`rig_def.helper_scales`).
// `assets/anatomy/mannequin_skin.bin` : 4 influences par sommet, dans l'ordre
// des sommets du modèle ; le GPU déforme le modèle avec les mêmes données
// (JOINTS_0 / WEIGHTS_0 du GLB), ce fichier sert au toucher et au cadrage
// sur le modèle déformé, calculés ici sur le processeur.
//
// Repère du rig : celui du glTF (Y en haut, +Z vers l'avant, +X à gauche).
// Au repos, chaque os a l'orientation du corps : une posture est une rotation
// locale par os autour de sa tête, et la peau un mélange linéaire de 4
// matrices (globale × inverse de la liaison), comme le shader de
// flutter_scene.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;

const kRigAsset = 'assets/anatomy/rig.json';
const kSkinAsset = 'assets/anatomy/mannequin_skin.bin';

/// M7 : squelette Mixamo du personnage « Ch36 » (65 os, pose de repos en T,
/// pose d'affichage en posture `affichage`) et sa peau (4 influences par
/// sommet), fabriqués par tools/anatomy/build_animated.py pour le mannequin
/// animable (`assets/anatomy/mannequin_anime.glb`). Même convention que M5 :
/// une posture est une rotation locale (repère du corps) par os autour de
/// sa tête, plus la translation du bassin.
const kMixamoRigAsset = 'assets/anatomy/rig_mixamo.json';
const kMixamoSkinAsset = 'assets/anatomy/peau_mixamo.bin';

/// Os du squelette d'animation.
class RigBone {
  final String name, label;
  final String? parent;

  /// Os d'aide : os suivi (il en prend [helperPart] de la rotation locale ;
  /// 0 pour un os de gonflement, qui ne tourne pas).
  final String? follows;
  final double helperPart;

  /// M56 : gonflement par radian de rotation de l'os suivi (échelle
  /// perpendiculaire à l'axe de rotation, ou à [bulgeAxis] pour un os de
  /// gonflement) ; 0 : aucune échelle.
  final double bulge;
  final vm.Vector3? bulgeAxis;

  /// M56 correction 1 : os d'insertion — suit la position de l'insertion
  /// sur son parent (bras) mais garde l'orientation de l'os [follows]
  /// (tronc) : rotation locale = inverse de la rotation cumulée des os
  /// entre [follows] (exclu) et le parent (inclus).
  final bool insertion;

  /// Tête au repos (repère glTF).
  final vm.Vector3 head;
  const RigBone(
    this.name,
    this.label,
    this.parent,
    this.head, {
    this.follows,
    this.helperPart = .5,
    this.insertion = false,
    this.bulge = 0,
    this.bulgeAxis,
  });
}

/// Posture : rotations locales (repère glTF), translation du bassin et, M56,
/// échelles locales des os d'aide et de gonflement (matrices 3×3, calculées
/// par [MannequinRig.withHelpers]).
class RigPose {
  final Map<String, vm.Quaternion> rotations;
  final vm.Vector3 translation;
  final Map<String, vm.Matrix3> scales;
  RigPose(this.rotations, this.translation, [this.scales = const {}]);

  static final rest = RigPose(const {}, vm.Vector3.zero());

  vm.Quaternion rotationOf(String bone) =>
      rotations[bone] ?? vm.Quaternion.identity();
}

/// Posture de référence du rig (`rig.json`, clé `postures`).
class RigPosture {
  final String key, name;

  /// Proposée dans l'écran Anatomie.
  final bool app;
  final RigPose pose;
  const RigPosture(this.key, this.name, this.app, this.pose);
}

/// Interpolation sphérique (le plus court chemin).
vm.Quaternion quatSlerp(vm.Quaternion a, vm.Quaternion b, double t) {
  var bx = b.x, by = b.y, bz = b.z, bw = b.w;
  var dot = a.x * bx + a.y * by + a.z * bz + a.w * bw;
  if (dot < 0) {
    dot = -dot;
    bx = -bx;
    by = -by;
    bz = -bz;
    bw = -bw;
  }
  double ka, kb;
  if (dot > .9995) {
    ka = 1 - t;
    kb = t;
  } else {
    final angle = math.acos(dot.clamp(-1.0, 1.0));
    final s = math.sin(angle);
    ka = math.sin((1 - t) * angle) / s;
    kb = math.sin(t * angle) / s;
  }
  return vm.Quaternion(
    ka * a.x + kb * bx,
    ka * a.y + kb * by,
    ka * a.z + kb * bz,
    ka * a.w + kb * bw,
  )..normalize();
}

/// Influences d'un maillage : 4 os et 4 poids (octets, somme 255) par sommet.
class SkinInfluences {
  final Uint8List joints, weights;
  const SkinInfluences(this.joints, this.weights);
  int get vertexCount => joints.length ~/ 4;
}

/// Squelette, postures et peau du mannequin.
class MannequinRig {
  final List<RigBone> bones;
  final Map<String, int> index;
  final List<RigPosture> postures;

  /// Influences par maillage (nom du nœud) ; vide si le fichier de peau
  /// n'est pas chargé (tests).
  final Map<String, SkinInfluences> skin;

  MannequinRig(this.bones, this.postures, {this.skin = const {}})
    : index = {for (var i = 0; i < bones.length; i++) bones[i].name: i};

  /// Postures proposées dans l'écran Anatomie, dans l'ordre du fichier.
  List<RigPosture> get appPostures => [
    for (final p in postures)
      if (p.app) p,
  ];

  RigPosture? posture(String key) {
    for (final p in postures) {
      if (p.key == key) return p;
    }
    return null;
  }

  factory MannequinRig.fromJson(Map<String, dynamic> j, [ByteData? skinData]) {
    vm.Vector3 v3(List l) => vm.Vector3(
      (l[0] as num).toDouble(),
      (l[1] as num).toDouble(),
      (l[2] as num).toDouble(),
    );
    final bones = <RigBone>[
      for (final b in j['os'] as List)
        RigBone(
          b['nom'] as String,
          b['nom_fr'] as String,
          b['parent'] as String?,
          v3(b['tete'] as List),
          follows: (b['aide'] as Map?)?['suit'] as String?,
          helperPart: ((b['aide'] as Map?)?['part'] as num?)?.toDouble() ?? .5,
          bulge: ((b['aide'] as Map?)?['gonflement'] as num?)?.toDouble() ?? 0,
          bulgeAxis: (b['aide'] as Map?)?['axe'] == null
              ? null
              : v3((b['aide'] as Map)['axe'] as List),
          insertion: (b['aide'] as Map?)?['insertion'] == true,
        ),
    ];
    final postures = <RigPosture>[];
    (j['postures'] as Map<String, dynamic>).forEach((key, p) {
      final rots = <String, vm.Quaternion>{
        for (final e in (p['rotations'] as Map<String, dynamic>).entries)
          e.key: vm.Quaternion(
            (e.value[0] as num).toDouble(),
            (e.value[1] as num).toDouble(),
            (e.value[2] as num).toDouble(),
            (e.value[3] as num).toDouble(),
          ),
      };
      postures.add(
        RigPosture(
          key,
          p['nom'] as String,
          p['app'] as bool? ?? false,
          RigPose(rots, v3(p['translation'] as List)),
        ),
      );
    });
    final skin = <String, SkinInfluences>{};
    if (skinData != null) {
      final bytes = skinData.buffer.asUint8List(
        skinData.offsetInBytes,
        skinData.lengthInBytes,
      );
      var offset = 0;
      for (final m in (j['peau'] as Map)['maillages'] as List) {
        final n = (m['sommets'] as num).toInt();
        final joints = Uint8List(n * 4), weights = Uint8List(n * 4);
        for (var i = 0; i < n; i++) {
          final o = offset + i * 8;
          for (var k = 0; k < 4; k++) {
            joints[i * 4 + k] = bytes[o + k];
            weights[i * 4 + k] = bytes[o + 4 + k];
          }
        }
        skin[m['nom'] as String] = SkinInfluences(joints, weights);
        offset += n * 8;
      }
      if (offset != bytes.length) {
        throw const FormatException('Peau du mannequin : taille inattendue');
      }
    }
    return MannequinRig(bones, postures, skin: skin);
  }

  static Future<MannequinRig>? _cache, _mixamoCache;

  /// M7 : squelette Mixamo et peau du mannequin animable, chargés une seule
  /// fois par lancement.
  static Future<MannequinRig> loadMixamo([AssetBundle? bundle]) {
    final pending = _mixamoCache ??= _load(
      bundle,
      kMixamoRigAsset,
      kMixamoSkinAsset,
    );
    return pending.catchError((Object e) {
      if (identical(_mixamoCache, pending)) _mixamoCache = null;
      throw e;
    });
  }

  static Future<MannequinRig> _load(
    AssetBundle? bundle,
    String rigAsset,
    String skinAsset,
  ) async {
    final b = bundle ?? rootBundle;
    final results = await Future.wait<Object>([
      b.loadString(rigAsset),
      b.load(skinAsset),
    ]);
    return MannequinRig.fromJson(
      jsonDecode(results[0] as String) as Map<String, dynamic>,
      results[1] as ByteData,
    );
  }

  /// Chargé une seule fois par lancement (squelette, postures, peau).
  static Future<MannequinRig> load([AssetBundle? bundle]) {
    final pending = _cache ??= () async {
      final b = bundle ?? rootBundle;
      final results = await Future.wait<Object>([
        b.loadString(kRigAsset),
        b.load(kSkinAsset),
      ]);
      return MannequinRig.fromJson(
        jsonDecode(results[0] as String) as Map<String, dynamic>,
        results[1] as ByteData,
      );
    }();
    return pending.catchError((Object e) {
      if (identical(_cache, pending)) _cache = null;
      throw e;
    });
  }

  /// Rotations complétées par celles des os d'aide (fraction de la rotation
  /// locale de l'os suivi) et échelles de gonflement (M56 : 1 + gain × angle
  /// de l'os suivi, perpendiculairement à l'axe de sa rotation ou à l'axe du
  /// muscle), comme à la fabrication (`rig_def.with_helpers`,
  /// `rig_def.helper_scales`).
  RigPose withHelpers(RigPose pose) {
    final rots = Map<String, vm.Quaternion>.of(pose.rotations);
    final scales = <String, vm.Matrix3>{};
    for (final b in bones) {
      final f = b.follows;
      if (f == null) continue;
      if (b.insertion) {
        // Orientation du tronc : inverse de la chaîne parent → … → suivi.
        var chain = vm.Quaternion.identity();
        var name = b.parent;
        while (name != null && name != f) {
          chain = pose.rotationOf(name) * chain;
          name = bones[index[name]!].parent;
        }
        chain.normalize();
        rots[b.name] = chain.conjugated();
        continue;
      }
      final q = pose.rotationOf(f);
      if (b.helperPart > 0) {
        rots[b.name] = quatSlerp(vm.Quaternion.identity(), q, b.helperPart);
      }
      if (b.bulge > 0) {
        final s = bulgeScale(q, b.bulge, b.bulgeAxis);
        if (s != null) scales[b.name] = s;
      }
    }
    return RigPose(rots, pose.translation, scales);
  }

  /// Échelle d'un os d'aide ou de gonflement pour la rotation [q] de l'os
  /// suivi : `1 + gain × angle`, perpendiculaire à [axis] (axe du muscle) ou,
  /// sans axe, à l'axe de [q] ; null si la rotation est nulle.
  static vm.Matrix3? bulgeScale(
    vm.Quaternion q,
    double gain,
    vm.Vector3? axis,
  ) {
    var w = q.w.abs().clamp(0.0, 1.0);
    final angle = 2 * math.acos(w);
    if (angle < 1e-6) return null;
    final s = 1 + gain * angle;
    vm.Vector3 a;
    if (axis != null) {
      a = axis;
    } else {
      a = vm.Vector3(q.x, q.y, q.z);
      final n = a.length;
      a = n > 1e-9 ? a / n : vm.Vector3(1, 0, 0);
    }
    final m = vm.Matrix3.identity();
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        final d = i == j ? 1.0 : 0.0;
        m.setEntry(i, j, d + (s - 1) * (d - a[i] * a[j]));
      }
    }
    return m;
  }

  /// Posture intermédiaire entre [a] et [b] (fraction [t]) : rotations
  /// interpolées os par os, os d'aide recalculés, translation linéaire.
  RigPose blend(RigPose a, RigPose b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final rots = <String, vm.Quaternion>{};
    for (final bone in bones) {
      if (bone.follows != null) continue;
      final qa = a.rotations[bone.name], qb = b.rotations[bone.name];
      if (qa == null && qb == null) continue;
      rots[bone.name] = quatSlerp(
        qa ?? vm.Quaternion.identity(),
        qb ?? vm.Quaternion.identity(),
        t,
      );
    }
    return withHelpers(
      RigPose(rots, a.translation + (b.translation - a.translation) * t),
    );
  }

  /// Transformation locale d'un os : translation, rotation, puis échelle
  /// (M56, os d'aide et de gonflement).
  static vm.Matrix4 localMatrix(
    vm.Vector3 t,
    vm.Quaternion q,
    vm.Matrix3? scale,
  ) {
    final m = vm.Matrix4.compose(t, q, vm.Vector3.all(1));
    if (scale == null) return m;
    final s = vm.Matrix4.identity()..setRotation(scale);
    return m * s;
  }

  /// Transformations globales des os (repère glTF).
  List<vm.Matrix4> globals(RigPose pose) {
    final out = List<vm.Matrix4>.filled(bones.length, vm.Matrix4.identity());
    for (var i = 0; i < bones.length; i++) {
      final b = bones[i];
      final q = pose.rotationOf(b.name);
      final s = pose.scales[b.name];
      final p = b.parent;
      if (p == null) {
        out[i] = localMatrix(b.head + pose.translation, q, s);
      } else {
        final pi = index[p]!;
        out[i] = out[pi] * localMatrix(b.head - bones[pi].head, q, s);
      }
    }
    return out;
  }

  /// Matrices de peau (globale × inverse de la liaison), 12 coefficients par
  /// os (3 lignes de 4), repère glTF.
  Float64List skinMatrices(RigPose pose) {
    final g = globals(pose);
    final out = Float64List(bones.length * 12);
    for (var i = 0; i < bones.length; i++) {
      final m = g[i] * vm.Matrix4.translation(-bones[i].head);
      final s = m.storage;
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 4; c++) {
          out[i * 12 + r * 4 + c] = s[c * 4 + r];
        }
      }
    }
    return out;
  }

  /// Positions déformées (mélange linéaire) d'un maillage [mesh] dont les
  /// positions de repos sont [rest] (repère glTF, 3 flottants par sommet).
  Float32List skinPositions(String mesh, Float32List rest, Float64List mats) {
    final inf = skin[mesh];
    final n = rest.length ~/ 3;
    final out = Float32List(rest.length);
    if (inf == null || inf.vertexCount != n) {
      out.setAll(0, rest);
      return out;
    }
    final j = inf.joints, w = inf.weights;
    for (var v = 0; v < n; v++) {
      final x = rest[v * 3], y = rest[v * 3 + 1], z = rest[v * 3 + 2];
      var ox = 0.0, oy = 0.0, oz = 0.0;
      for (var k = 0; k < 4; k++) {
        final wk = w[v * 4 + k];
        if (wk == 0) continue;
        final f = wk / 255;
        final m = j[v * 4 + k] * 12;
        ox +=
            f * (mats[m] * x + mats[m + 1] * y + mats[m + 2] * z + mats[m + 3]);
        oy +=
            f *
            (mats[m + 4] * x + mats[m + 5] * y + mats[m + 6] * z + mats[m + 7]);
        oz +=
            f *
            (mats[m + 8] * x +
                mats[m + 9] * y +
                mats[m + 10] * z +
                mats[m + 11]);
      }
      out[v * 3] = ox;
      out[v * 3 + 1] = oy;
      out[v * 3 + 2] = oz;
    }
    return out;
  }
}
