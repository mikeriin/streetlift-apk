// M56 (mannequin 3D, brouillon M6) : animations d'exercice calculées hors de l'application.
//
// `assets/anatomy/clips/<id>.json.gz` (fabriqué par
// tools/anatomy/animate.py depuis la fiche biomécanique de l'exercice) :
// postures (rotations locales des os en quaternions, translation du bassin,
// position du matériel mobile), chronologie (temps → posture), phases
// (concentrique, excentrique, isométrique), tempo, matériel, vue par défaut,
// cadrage fixe de la boucle. Entre deux postures, la rotation de chaque os
// est interpolée sphériquement et la translation linéairement, exactement
// comme les contrôles de la chaîne de calcul (contacts à 1 cm, aucune
// pénétration, entre les images clés comprises).
//
// `assets/anatomy/clips/index.json` : registre des exercices convertis
// (statut, date, contrôles passés). L'application montre la démonstration 3D
// d'un exercice seulement s'il y figure avec le statut « valide » ; sinon la
// démonstration 2D reste en place.
//
// Correction 1 de M56 (décision du propriétaire, 29/09/2026) : l'application
// ne joue plus la boucle ; elle montre les **positions de départ et de fin**
// (`positions` du clip : nom, clé de la fiche, instant de la chronologie)
// avec un fondu doux de l'une à l'autre, comme les postures de l'écran
// Anatomie. La chronologie complète reste dans le clip (contrôles de la
// chaîne de calcul, captures).
import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mannequin_rig.dart';

const kClipIndexAsset = 'assets/anatomy/clips/index.json';
String clipAsset(String id) => 'assets/anatomy/clips/$id.json.gz';

/// Bibliothèque de matériel (tools/anatomy/build_equipment.py), convertie
/// par le build hook comme le mannequin.
const kEquipmentAsset = 'assets/anatomy/equipment.glb';

/// Type de contraction d'une phase.
enum ClipPhaseType { concentrique, excentrique, isometrique }

class ClipPhase {
  final String name;
  final ClipPhaseType type;
  final double start, end;
  const ClipPhase(this.name, this.type, this.start, this.end);

  String get typeLabel => switch (type) {
    ClipPhaseType.concentrique => 'concentrique',
    ClipPhaseType.excentrique => 'excentrique',
    ClipPhaseType.isometrique => 'isométrique',
  };
}

/// Élément de matériel placé (repère glTF, rotation autour de la verticale).
class ClipEquipment {
  final String id;
  final vm.Vector3 position;
  final double yawDegrees;

  /// Mobile : suit le corps (barre sur le dos) ; position par posture.
  final bool moving;
  const ClipEquipment(this.id, this.position, this.yawDegrees, this.moving);
}

/// Position montrée par l'application (départ, fin) : instant de la
/// chronologie où la posture est atteinte.
class ClipPosition {
  final String name, key;
  final double time;
  const ClipPosition(this.name, this.key, this.time);
}

/// Posture d'une image clé et positions du matériel mobile.
class ClipKey {
  final RigPose pose;
  final Map<String, vm.Vector3> equipment;
  const ClipKey(this.pose, this.equipment);
}

class MannequinClip {
  final String id, name, view, plane, tempo;
  final double duration;
  final List<ClipKey> keys;

  /// (temps en secondes, index de posture), croissant ; la boucle revient à
  /// la première posture à [duration].
  final List<(double, int)> timeline;
  final List<ClipPhase> phases;
  final List<ClipEquipment> equipment;

  /// Positions montrées (départ, fin) ; à défaut, positions clés des phases.
  final List<ClipPosition> positions;

  /// Cadrage fixe de la boucle (repère glTF) : corps sur toutes les
  /// postures et matériel, sol exclu.
  final vm.Vector3 center;
  final double height, width;

  const MannequinClip({
    required this.id,
    required this.name,
    required this.view,
    required this.plane,
    required this.tempo,
    required this.duration,
    required this.keys,
    required this.timeline,
    required this.phases,
    required this.equipment,
    required this.center,
    required this.height,
    required this.width,
    this.positions = const [],
  });

  factory MannequinClip.fromJson(Map<String, dynamic> j) {
    double d(Object? v) => (v as num).toDouble();
    vm.Vector3 v3(List l) => vm.Vector3(d(l[0]), d(l[1]), d(l[2]));
    final bones = [for (final b in j['os'] as List) b as String];
    final keys = <ClipKey>[];
    for (final p in j['postures'] as List) {
      final r = p['r'] as List;
      final rots = <String, vm.Quaternion>{
        for (var i = 0; i < bones.length; i++)
          bones[i]: vm.Quaternion(
            d(r[i][0]),
            d(r[i][1]),
            d(r[i][2]),
            d(r[i][3]),
          )..normalize(),
      };
      final moving = <String, vm.Vector3>{
        for (final e in ((p['m'] as Map?) ?? const {}).entries)
          e.key as String: v3(e.value as List),
      };
      keys.add(ClipKey(RigPose(rots, v3(p['t'] as List)), moving));
    }
    final framing = j['cadrage'] as Map<String, dynamic>;
    return MannequinClip(
      id: j['id'] as String,
      name: j['nom'] as String,
      view: j['vue'] as String,
      plane: j['plan'] as String,
      tempo: j['tempo'] as String,
      duration: d(j['duree']),
      keys: keys,
      timeline: [
        for (final e in j['chronologie'] as List)
          (d(e[0]), (e[1] as num).toInt()),
      ],
      phases: [
        for (final p in j['phases'] as List)
          ClipPhase(
            p['nom'] as String,
            ClipPhaseType.values.byName(p['type'] as String),
            d(p['debut']),
            d(p['fin']),
          ),
      ],
      equipment: [
        for (final e in j['materiel'] as List)
          ClipEquipment(
            e['id'] as String,
            v3(e['position'] as List),
            d(e['rotation_y']),
            e['mobile'] as bool? ?? false,
          ),
      ],
      center: v3(framing['centre'] as List),
      height: d(framing['hauteur']),
      width: d(framing['largeur']),
      positions: [
        for (final p in (j['positions'] as List?) ?? const [])
          ClipPosition(p['nom'] as String, p['cle'] as String, d(p['temps'])),
      ],
    );
  }

  /// Positions montrées par l'application : départ et fin du clip, sinon
  /// les positions clés des phases.
  List<ClipPosition> get shownPositions => positions.isNotEmpty
      ? positions
      : [for (final (name, t) in keyPositions) ClipPosition(name, name, t)];

  factory MannequinClip.fromGzip(Uint8List bytes) => MannequinClip.fromJson(
    jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>,
  );

  /// Temps ramené dans la boucle.
  double wrap(double t) {
    if (duration <= 0) return 0;
    final w = t % duration;
    return w < 0 ? w + duration : w;
  }

  /// Segment de la chronologie qui contient [t] : (posture a, posture b,
  /// fraction). Après la dernière entrée, retour à la première posture.
  (int, int, double) segmentAt(double t) {
    final w = wrap(t);
    for (var i = 0; i + 1 < timeline.length; i++) {
      final (t0, a) = timeline[i];
      final (t1, b) = timeline[i + 1];
      if (w >= t0 && w <= t1) {
        return (a, b, t1 > t0 ? (w - t0) / (t1 - t0) : 0.0);
      }
    }
    final (tl, last) = timeline.last;
    final first = timeline.first.$2;
    final span = duration - tl;
    return (
      last,
      first,
      span > 0 ? ((w - tl) / span).clamp(0.0, 1.0).toDouble() : 0.0,
    );
  }

  /// Posture à l'instant [t] (os d'aide compris).
  RigPose poseAt(double t, MannequinRig rig) {
    final (a, b, u) = segmentAt(t);
    if (a == b || u <= 0) return rig.withHelpers(keys[a].pose);
    if (u >= 1) return rig.withHelpers(keys[b].pose);
    return rig.blend(keys[a].pose, keys[b].pose, u);
  }

  /// Position du matériel mobile à l'instant [t] (repère glTF).
  Map<String, vm.Vector3> equipmentAt(double t) {
    final (a, b, u) = segmentAt(t);
    final ka = keys[a].equipment, kb = keys[b].equipment;
    return {
      for (final e in ka.entries)
        e.key: e.value + ((kb[e.key] ?? e.value) - e.value) * u,
    };
  }

  /// Phase à l'instant [t].
  ClipPhase phaseAt(double t) {
    final w = wrap(t);
    for (final p in phases) {
      if (w >= p.start && w < p.end) return p;
    }
    return phases.last;
  }

  /// Positions clés (début de chaque phase isométrique, sinon de chaque
  /// phase) : images fixes quand les animations sont réduites.
  List<(String, double)> get keyPositions {
    final out = <(String, double)>[];
    for (final p in phases) {
      if (p.type == ClipPhaseType.isometrique) out.add((p.name, p.start));
    }
    if (out.isEmpty) {
      for (final p in phases) {
        out.add((p.name, p.start));
      }
    }
    return out;
  }
}

/// Registre des animations validées (chargé une fois) et clips (cache).
class ClipRegistry {
  static Set<String>? _valid;
  static Future<Set<String>>? _pending;
  static final Map<String, Future<MannequinClip?>> _clips = {};

  /// Exercices convertis (statut « valide »), null tant que non chargé.
  static Set<String>? get loaded => _valid;

  static Set<String> parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final c in j['clips'] as List)
        if (c['statut'] == 'valide' && c['fichier'] != null) c['id'] as String,
    };
  }

  static Future<Set<String>> load([AssetBundle? bundle]) {
    return _pending ??= () async {
      try {
        final s = await (bundle ?? rootBundle).loadString(kClipIndexAsset);
        return _valid = parse(s);
      } catch (_) {
        // Registre illisible : aucune animation 3D, démonstrations 2D.
        return _valid = <String>{};
      }
    }();
  }

  /// Clip d'un exercice validé (null : absent ou illisible).
  static Future<MannequinClip?> clip(String id, [AssetBundle? bundle]) {
    return _clips[id] ??= () async {
      final valid = await load(bundle);
      if (!valid.contains(id)) return null;
      try {
        final data = await (bundle ?? rootBundle).load(clipAsset(id));
        return MannequinClip.fromGzip(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } catch (_) {
        return null;
      }
    }();
  }

  /// Tests : registre imposé.
  static void debugSet(Set<String>? valid) {
    _valid = valid;
    _pending = valid == null ? null : Future.value(valid);
    _clips.clear();
  }
}
