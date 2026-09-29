// M7 (mannequin 3D) : clips d'animation du mannequin, registre et loi
// d'intensité par phase.
//
// Les animations du propriétaire (un FBX Mixamo « Without Skin » par
// exercice) et l'animation de test sont converties par
// tools/anatomy/import_animations.py en clips compressés `.ktclip`
// (`assets/anatomy/clips/`), listés dans `assets/anatomy/clips/index.json`
// avec leurs phases (concentrique, excentrique, isométrique) et, pour une
// animation de test, ses muscles. Format : gzip d'un bloc « KTC1 » —
// rotations locales par os (repère du corps, autour de la tête de l'os, os
// dans l'ordre de `rig_mixamo.json`) aux images clés, en quaternions « trois
// plus petites composantes » sur 16 bits, et translation du bassin (mm) ;
// interpolation sphérique entre deux clés. Un os sans piste reste au repos.
//
// Loi d'intensité par phase ([phaseHaloGain], docs/ANIMATION_3D.md) : le
// halo de la zone travaillée est plus vif en concentrique, plus doux en
// excentrique, pulse lentement en isométrie ; transitions douces, jamais de
// clignotement.
import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'mannequin_rig.dart';

/// Registre des clips.
const kClipIndexAsset = 'assets/anatomy/clips/index.json';

/// Type de contraction d'une phase.
enum PhaseKind {
  concentrique('Concentrique'),
  excentrique('Excentrique'),
  isometrique('Isométrique');

  final String label;
  const PhaseKind(this.label);

  static PhaseKind parse(String s) => switch (s) {
    'concentrique' => concentrique,
    'excentrique' => excentrique,
    'isometrique' => isometrique,
    _ => throw FormatException('Phase de type inconnu : $s'),
  };
}

/// Une phase du mouvement : nom affiché, type, début et fin (s).
class ClipPhase {
  final String name;
  final PhaseKind kind;
  final double start, end;
  const ClipPhase(this.name, this.kind, this.start, this.end);

  double get duration => end - start;

  /// Tempo affiché : durée arrondie à la demi-seconde (« 3 s », « 1,5 s »).
  String get tempo {
    final v = (duration * 2).round() / 2;
    final text = v == v.roundToDouble()
        ? v.round().toString()
        : v.toString().replaceAll('.', ',');
    return '$text s';
  }

  /// Libellé du lecteur : « Descente · 3 s ».
  String get label => '$name · $tempo';

  factory ClipPhase.fromJson(Map<String, dynamic> j) => ClipPhase(
    j['nom'] as String,
    PhaseKind.parse(j['type'] as String),
    (j['debut_s'] as num).toDouble(),
    (j['fin_s'] as num).toDouble(),
  );
}

/// Muscles d'une animation de test (les animations d'exercice prennent
/// ceux de la fiche du pack).
class ClipMuscles {
  final List<String> primaires, secondaires, stabilisateurs;
  const ClipMuscles(this.primaires, this.secondaires, this.stabilisateurs);

  static List<String> _list(Object? o) => [
    for (final v in (o as List?) ?? const []) v as String,
  ];

  factory ClipMuscles.fromJson(Map<String, dynamic> j) => ClipMuscles(
    _list(j['primaires']),
    _list(j['secondaires']),
    _list(j['stabilisateurs']),
  );
}

/// Entrée du registre.
class ClipEntry {
  final String id, asset, name;

  /// Exercices du pack qui montrent ce clip (vide pour un test).
  final List<String> exercises;

  /// Animation de test : Réglages › À propos › Moteur 3D seulement.
  final bool debug;
  final int fps, frames, bytes;
  final double duration;
  final List<ClipPhase> phases;
  final ClipMuscles? muscles;

  const ClipEntry({
    required this.id,
    required this.asset,
    required this.name,
    required this.exercises,
    required this.debug,
    required this.fps,
    required this.frames,
    required this.bytes,
    required this.duration,
    required this.phases,
    this.muscles,
  });

  factory ClipEntry.fromJson(Map<String, dynamic> j) => ClipEntry(
    id: j['id'] as String,
    asset: j['fichier'] as String,
    name: j['nom'] as String,
    exercises: [for (final e in j['exercices'] as List) e as String],
    debug: j['debogage'] as bool? ?? false,
    fps: (j['fps'] as num).toInt(),
    frames: (j['images'] as num).toInt(),
    bytes: (j['octets'] as num).toInt(),
    duration: (j['duree_s'] as num).toDouble(),
    phases: [
      for (final p in j['phases'] as List)
        ClipPhase.fromJson(p as Map<String, dynamic>),
    ],
    muscles: j['muscles'] == null
        ? null
        : ClipMuscles.fromJson(j['muscles'] as Map<String, dynamic>),
  );

  /// Phase au temps [t] (s), bornée à la durée.
  ClipPhase phaseAt(double t) {
    for (final p in phases) {
      if (t < p.end) return p;
    }
    return phases.last;
  }

  /// Indice de la phase au temps [t].
  int phaseIndexAt(double t) => phases.indexOf(phaseAt(t));

  /// Images clés parcourables quand les animations sont réduites : début et
  /// fin de chaque phase (sans doublon), dans l'ordre.
  List<double> get keyTimes {
    final out = <double>[];
    for (final p in phases) {
      for (final t in [p.start, p.end]) {
        if (out.isEmpty || (t - out.last).abs() > 1e-6) out.add(t);
      }
    }
    return out;
  }
}

/// Registre des clips (`assets/anatomy/clips/index.json`).
class ClipRegistry {
  final List<ClipEntry> clips;
  ClipRegistry(this.clips);

  factory ClipRegistry.fromJson(Map<String, dynamic> j) => ClipRegistry([
    for (final c in j['clips'] as List)
      ClipEntry.fromJson(c as Map<String, dynamic>),
  ]);

  /// Animation d'un exercice du pack (jamais une animation de test), ou
  /// null : la fiche garde alors son mannequin fixe.
  ClipEntry? forExercise(String? exerciseId) {
    if (exerciseId == null) return null;
    for (final c in clips) {
      if (!c.debug && c.exercises.contains(exerciseId)) return c;
    }
    return null;
  }

  /// Animation de test (Réglages › À propos › Moteur 3D).
  ClipEntry? get debugClip {
    for (final c in clips) {
      if (c.debug) return c;
    }
    return null;
  }

  static Future<ClipRegistry>? _cache;

  /// Registre déjà chargé, s'il y en a un (fiches : décision synchrone).
  static ClipRegistry? loaded;

  /// Chargé une seule fois par lancement (préchargement du mannequin).
  static Future<ClipRegistry> load([AssetBundle? bundle]) {
    final pending = _cache ??= (bundle ?? rootBundle)
        .loadString(kClipIndexAsset)
        .then(
          (s) => loaded = ClipRegistry.fromJson(
            jsonDecode(s) as Map<String, dynamic>,
          ),
        );
    return pending.catchError((Object e) {
      if (identical(_cache, pending)) _cache = null;
      throw e;
    });
  }
}

/// Piste d'un os : images clés et quaternions.
class _Track {
  final int bone;
  final Int32List keys;
  final List<vm.Quaternion> values;
  const _Track(this.bone, this.keys, this.values);
}

/// Clip décodé : échantillonnage à n'importe quel temps.
class MannequinClip {
  final int fps, frames;
  final List<String> bones;
  final List<_Track> _tracks;
  final Int32List? _rootKeys;
  final List<vm.Vector3> _rootValues;

  MannequinClip._(
    this.fps,
    this.frames,
    this.bones,
    this._tracks,
    this._rootKeys,
    this._rootValues,
  );

  /// Durée (s).
  double get duration => (frames - 1) / fps;

  /// Nombre de pistes d'os (contrôles).
  int get trackCount => _tracks.length;

  /// Os animés (contrôles).
  Iterable<String> get animatedBones => _tracks.map((t) => bones[t.bone]);

  static const _invSqrt2 = 0.7071067811865476;

  /// Décode un clip compressé ([bones] : os du squelette, ordre du rig).
  factory MannequinClip.decode(Uint8List data, List<String> bones) {
    final raw = Uint8List.fromList(gzip.decode(data));
    final b = ByteData.sublistView(raw);
    if (raw.length < 10 ||
        raw[0] != 0x4B ||
        raw[1] != 0x54 ||
        raw[2] != 0x43 ||
        raw[3] != 0x31) {
      throw const FormatException('Clip illisible (en-tête)');
    }
    final version = b.getUint8(4);
    if (version != 1) throw FormatException('Clip : version $version');
    final fps = b.getUint8(5);
    final frames = b.getUint16(6, Endian.little);
    final nTracks = b.getUint8(8);
    final flags = b.getUint8(9);
    var o = 10;
    Int32List readKeys(int n) {
      final keys = Int32List(n);
      var acc = 0;
      for (var k = 0; k < n; k++) {
        acc += raw[o + k];
        keys[k] = acc;
      }
      o += n;
      return keys;
    }

    final tracks = <_Track>[];
    for (var t = 0; t < nTracks; t++) {
      final bone = b.getUint8(o);
      final n = b.getUint16(o + 1, Endian.little);
      o += 3;
      if (bone >= bones.length) {
        throw const FormatException('Clip : os hors du squelette');
      }
      final keys = readKeys(n);
      final values = <vm.Quaternion>[];
      for (var k = 0; k < n; k++) {
        final idx = b.getUint8(o);
        final c = [
          b.getInt16(o + 1, Endian.little) / 32767 * _invSqrt2,
          b.getInt16(o + 3, Endian.little) / 32767 * _invSqrt2,
          b.getInt16(o + 5, Endian.little) / 32767 * _invSqrt2,
        ];
        o += 7;
        final big = math.sqrt(
          math.max(0, 1 - c[0] * c[0] - c[1] * c[1] - c[2] * c[2]),
        );
        final q = List<double>.filled(4, 0);
        var j = 0;
        for (var i = 0; i < 4; i++) {
          q[i] = i == idx ? big : c[j++];
        }
        values.add(vm.Quaternion(q[0], q[1], q[2], q[3])..normalize());
      }
      tracks.add(_Track(bone, keys, values));
    }
    Int32List? rootKeys;
    final rootValues = <vm.Vector3>[];
    if (flags & 1 != 0) {
      final n = b.getUint16(o, Endian.little);
      o += 2;
      rootKeys = readKeys(n);
      for (var k = 0; k < n; k++) {
        rootValues.add(
          vm.Vector3(
            b.getInt16(o, Endian.little) / 1000,
            b.getInt16(o + 2, Endian.little) / 1000,
            b.getInt16(o + 4, Endian.little) / 1000,
          ),
        );
        o += 6;
      }
    }
    if (o != raw.length) throw const FormatException('Clip : taille');
    return MannequinClip._(fps, frames, bones, tracks, rootKeys, rootValues);
  }

  /// Charge et décode un clip du registre.
  static Future<MannequinClip> load(
    ClipEntry entry,
    MannequinRig rig, [
    AssetBundle? bundle,
  ]) async {
    final data = await (bundle ?? rootBundle).load(entry.asset);
    return MannequinClip.decode(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      [for (final b in rig.bones) b.name],
    );
  }

  /// Clé précédente et fraction jusqu'à la suivante pour l'image [f].
  static (int, double) _segment(Int32List keys, double f) {
    if (f <= keys.first) return (0, 0);
    if (f >= keys.last) return (keys.length - 1, 0);
    var lo = 0, hi = keys.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (keys[mid] <= f) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return (lo, (f - keys[lo]) / (keys[hi] - keys[lo]));
  }

  /// Posture au temps [t] (s, borné à la durée).
  RigPose sample(double t) {
    final f = (t.clamp(0.0, duration)) * fps;
    final rots = <String, vm.Quaternion>{};
    for (final tr in _tracks) {
      final (k, u) = _segment(tr.keys, f);
      rots[bones[tr.bone]] = u == 0 || k + 1 >= tr.values.length
          ? tr.values[k]
          : quatSlerp(tr.values[k], tr.values[k + 1], u);
    }
    var root = vm.Vector3.zero();
    final rk = _rootKeys;
    if (rk != null && rk.isNotEmpty) {
      final (k, u) = _segment(rk, f);
      root = u == 0 || k + 1 >= _rootValues.length
          ? _rootValues[k].clone()
          : _rootValues[k] + (_rootValues[k + 1] - _rootValues[k]) * u;
    }
    return RigPose(rots, root);
  }
}

// ------------------------------------------------------ intensité / phase --

/// Gains du halo par type de phase (docs/ANIMATION_3D.md).
const kGainConcentric = 1.0;
const kGainEccentric = .62;
const kGainIsometric = .8;

/// Pulsation de l'isométrie : amplitude et période (s). 0,5 Hz, loin des
/// 3 Hz des recommandations d'accessibilité (WCAG 2.3.1).
const kIsometricPulse = .14;
const kIsometricPeriod = 2.0;

/// Durée des transitions entre deux phases (s), centrées sur la frontière.
const kPhaseBlend = .4;

double _baseGain(PhaseKind kind) => switch (kind) {
  PhaseKind.concentrique => kGainConcentric,
  PhaseKind.excentrique => kGainEccentric,
  PhaseKind.isometrique => kGainIsometric,
};

/// Gain de la phase [kind] à l'instant [t] : constant, ou pulsation lente
/// (cosinus : 0 à l'entrée de la phase, donc sans saut) en isométrie, sauf
/// si les animations sont réduites.
double _phaseGain(ClipPhase p, double t, bool reduceMotion) {
  final base = _baseGain(p.kind);
  if (p.kind != PhaseKind.isometrique || reduceMotion) return base;
  final u = (t - p.start) / kIsometricPeriod;
  return base + kIsometricPulse * (1 - math.cos(2 * math.pi * u)) / 2 -
      kIsometricPulse / 2;
}

/// Gain du halo au temps [t] d'un clip : vif en concentrique (1), plus
/// doux en excentrique (0,62), pulsation lente autour de 0,8 en isométrie
/// (± 0,07, période 2 s ; fixe si les animations sont réduites) ; fondu de
/// [kPhaseBlend] s (lissage en S) autour de chaque frontière. Le temps
/// boucle : la fin du clip se fond dans son début.
double phaseHaloGain(
  List<ClipPhase> phases,
  double t, {
  bool reduceMotion = false,
}) {
  if (phases.isEmpty) return 1;
  final duration = phases.last.end;
  var i = phases.length - 1;
  for (var k = 0; k < phases.length; k++) {
    if (t < phases[k].end) {
      i = k;
      break;
    }
  }
  final p = phases[i];
  final g = _phaseGain(p, t, reduceMotion);
  final prev = i > 0 ? phases[i - 1] : phases.last;
  final next = i + 1 < phases.length ? phases[i + 1] : phases.first;
  // Demi-largeur du fondu d'une frontière : la même des deux côtés, jamais
  // plus de la moitié d'une des deux phases.
  double half(ClipPhase a, ClipPhase b) =>
      math.min(kPhaseBlend / 2, math.min(a.duration, b.duration) / 2);
  // Fondu avec la phase précédente (au début de p) ou suivante (à la fin).
  final hs = half(prev, p);
  if (phases.length > 1 && t - p.start < hs) {
    final tp = i > 0 ? t : t + duration;
    final x = (t - p.start + hs) / (2 * hs);
    return _mix(_phaseGain(prev, tp, reduceMotion), g, x);
  }
  final he = half(p, next);
  if (phases.length > 1 && p.end - t < he) {
    final tn = i + 1 < phases.length ? t : t - duration;
    final x = (t - p.end + he) / (2 * he);
    return _mix(g, _phaseGain(next, tn, reduceMotion), x);
  }
  return g;
}

double _mix(double a, double b, double x) {
  final s = x.clamp(0.0, 1.0);
  final e = s * s * (3 - 2 * s);
  return a + (b - a) * e;
}
