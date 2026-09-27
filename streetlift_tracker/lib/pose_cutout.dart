// Démonstrations « découpées » (refonte muscles et animations) : les
// illustrations anatomiques historiques (face / dos) et la vue de profil sont
// découpées en segments (tools/anim_cutout.py → assets/muscles/anim/), puis
// animées par la cinématique du pack (pose_engine.dart). Chaque segment est
// posé par une transformation affine : l'os de l'illustration est amené sur
// l'os du modèle (longueur du modèle, largeur à l'échelle de l'illustration) ;
// tête, mains et pieds gardent leurs proportions. Les muscles travaillés sont
// surlignés par les calques de groupes, avec la rampe de la carte musculaire.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'atlas_data.dart';
import 'pose_engine.dart';

/// Intensités des rôles d'une démonstration (mêmes que la carte d'un exercice).
const cutoutPrimaryHeat = 1.0, cutoutSecondaryHeat = .62;

/// Assombrissement du membre éloigné (profil).
const cutoutFarShade = ui.Color(0xFF9C9C9C);

/// Muscles de la face postérieure du corps (vus de dos).
const cutoutPosteriorMuscles = {
  'extenseurs_cervicaux', 'elevateur_scapula', 'trapeze_superieur', //
  'trapeze_moyen', 'trapeze_inferieur', 'rhomboides', 'grand_dorsal',
  'grand_rond', 'petit_rond', 'infra_epineux', 'supra_epineux',
  'deltoide_posterieur', 'triceps_chef_long', 'triceps_chef_lateral',
  'triceps_chef_medial', 'ancone', 'erecteurs_lombaires',
  'erecteurs_thoraciques', 'multifides', 'carre_des_lombes', 'grand_fessier',
  'biceps_femoral', 'biceps_femoral_chef_court', 'semi_tendineux',
  'semi_membraneux', 'poplite', 'gastrocnemien_medial',
  'gastrocnemien_lateral', 'soleaire',
};

/// Muscles de la face antérieure du corps (vus de face). Les muscles
/// latéraux (obliques, deltoïde moyen, moyen fessier…) ne comptent pas.
const cutoutAnteriorMuscles = {
  'sterno_cleido_mastoidien', 'flechisseurs_cervicaux_profonds', //
  'deltoide_anterieur', 'dentele_anterieur', 'petit_pectoral',
  'grand_pectoral_claviculaire', 'grand_pectoral_sterno_costal',
  'grand_pectoral_abdominal', 'biceps_chef_long', 'biceps_chef_court',
  'brachial', 'coraco_brachial', 'droit_abdomen', 'transverse_abdomen',
  'grand_psoas', 'iliaque', 'sartorius', 'pectine', 'long_adducteur',
  'court_adducteur', 'gracile', 'droit_femoral', 'vaste_lateral',
  'vaste_medial', 'vaste_intermediaire', 'tibial_anterieur',
  'long_extenseur_des_orteils',
};

/// Vue de rendu d'une démonstration.
///
/// Règle : les gabarits de profil (plan sagittal) restent de profil ; les
/// gabarits de face (plan frontal) sont rendus de dos quand leurs muscles
/// principaux postérieurs sont plus nombreux que les antérieurs (les muscles
/// latéraux ne comptent pas), de face sinon.
String cutoutViewOf(PoseAnimation pose) {
  if (!pose.isFace) return 'profil';
  var back = 0, front = 0;
  for (final m in pose.primaires) {
    if (cutoutPosteriorMuscles.contains(m)) back++;
    if (cutoutAnteriorMuscles.contains(m)) front++;
  }
  return back > front ? 'dos' : 'face';
}

/// Revue visuelle de toutes les démonstrations (refonte muscles et
/// animations, 27/09/2026) : exercices dont l'animation serait fausse avec la
/// cinématique actuelle du pack. Jamais d'animation fausse : l'exercice passe
/// en image fixe (index de l'image clé juste) ou sans démonstration. Le pack
/// de contenu validé n'est pas modifié (correction proposée au propriétaire).
const cutoutReviewOverrides = <String, (String, int)>{
  // position basse du développé : barre derrière la tête (bras mal orientés)
  'developpe-couche': ('statique', 1),
  'developpe-couche-halteres': ('statique', 1),
  'developpe-couche-prise-serree': ('statique', 1),
  'developpe-couche-pause': ('statique', 1),
  'developpe-decline': ('statique', 1),
  'developpe-incline': ('statique', 1),
  'developpe-incline-halteres': ('statique', 1),
  'floor-press': ('statique', 1),
  'jm-press': ('statique', 1),
  'test-1rm-developpe-couche': ('statique', 1),
  'tate-press': ('statique', 1),
  // deux images clés identiques : aucun mouvement montré
  'leg-curl': ('statique', 0),
  'leg-extension': ('statique', 0),
  // contact essentiel absent (plateau, traîneau, appui, sol, caisse)
  'presse-a-cuisses': ('indisponible', 0),
  'sled-push': ('indisponible', 0),
  'rowing-haltere-appui-poitrine': ('indisponible', 0),
  'transition-muscle-up-assistee-pieds-au-sol': ('indisponible', 0),
  'sauts-en-contrebas-depth-jumps': ('indisponible', 0),
};

const _demoRank = {'disponible': 0, 'statique': 1, 'indisponible': 2};

/// Statut de démonstration affiché : le plus prudent entre le pack et la revue.
String reviewedDemoStatus(String id, String packStatus) {
  final review = cutoutReviewOverrides[id]?.$1;
  if (review == null) return packStatus;
  return (_demoRank[review] ?? 0) > (_demoRank[packStatus] ?? 0)
      ? review
      : packStatus;
}

/// Image clé montrée pour une démonstration en image fixe.
int reviewedStaticKeyframe(String id) => cutoutReviewOverrides[id]?.$2 ?? 0;

/// Intensité par groupe de l'application (0-1) pour une démonstration.
Map<String, double> cutoutGroupHeat(PoseAnimation pose) {
  final out = <String, double>{};
  void add(Iterable<String> ids, double v) {
    for (final id in ids) {
      final g = atlasMuscles[id]?.groupe;
      if (g != null && (out[g] ?? 0) < v) out[g] = v;
    }
  }

  add(pose.secondaires, cutoutSecondaryHeat);
  add(pose.primaires, cutoutPrimaryHeat);
  return out;
}

/// Calque d'un groupe musculaire découpé avec son segment.
@immutable
class CutoutLayer {
  final String group;
  final ui.Rect src;
  final ui.Offset offset;
  const CutoutLayer(this.group, this.src, this.offset);
}

/// Segment : rectangle de l'atlas et origine dans l'illustration (pixels).
@immutable
class CutoutSegment {
  final String name;
  final ui.Rect src;
  final ui.Offset origin;
  final List<CutoutLayer> layers;
  const CutoutSegment(this.name, this.src, this.origin, this.layers);
}

/// Gabarit d'une vue : articulations de l'illustration (pixels, y vers le
/// bas) et segments dans l'ordre de dessin (du fond vers l'avant).
@immutable
class CutoutRig {
  final String view;
  final String image, layersImage;
  final Map<String, ui.Offset> joints;
  final List<CutoutSegment> segments;
  const CutoutRig({
    required this.view,
    required this.image,
    required this.layersImage,
    required this.joints,
    required this.segments,
  });

  CutoutSegment segment(String name) =>
      segments.firstWhere((s) => s.name == name);

  static ui.Rect _rect(Object? v) {
    final l = [for (final x in v as List) (x as num).toDouble()];
    return ui.Rect.fromLTWH(l[0], l[1], l[2], l[3]);
  }

  static ui.Offset _off(Object? v) {
    final l = v as List;
    return ui.Offset((l[0] as num).toDouble(), (l[1] as num).toDouble());
  }

  factory CutoutRig.fromJson(String view, Map<String, dynamic> j) => CutoutRig(
    view: view,
    image: j['image'] as String,
    layersImage: j['calques'] as String,
    joints: {
      for (final e in (j['articulations'] as Map<String, dynamic>).entries)
        e.key: _off(e.value),
    },
    segments: [
      for (final s in j['segments'] as List)
        CutoutSegment(
          (s as Map)['nom'] as String,
          _rect(s['rect']),
          _off(s['origine']),
          [
            for (final c in s['calques'] as List)
              CutoutLayer(
                (c as Map)['groupe'] as String,
                _rect(c['rect']),
                _off(c['decalage']),
              ),
          ],
        ),
    ],
  );
}

/// Gabarits des trois vues (assets/muscles/anim/rig.json).
@immutable
class CutoutRigs {
  final double pixelsPerUnit;
  final Map<String, CutoutRig> views;
  const CutoutRigs(this.pixelsPerUnit, this.views);

  factory CutoutRigs.fromJson(Map<String, dynamic> j) =>
      CutoutRigs((j['echelle_px'] as num).toDouble(), {
        for (final e in (j['vues'] as Map<String, dynamic>).entries)
          e.key: CutoutRig.fromJson(e.key, e.value as Map<String, dynamic>),
      });
}

/// Atlas décodés d'une vue, prêts à peindre.
class CutoutSprites {
  final CutoutRig rig;
  final double pixelsPerUnit;
  final ui.Image image, layers;
  CutoutSprites(this.rig, this.pixelsPerUnit, this.image, this.layers);

  /// Mémoire des textures décodées (RGBA, octets).
  int get textureBytes =>
      4 * (image.width * image.height + layers.width * layers.height);

  static const rigAsset = 'assets/muscles/anim/rig.json';
  static Future<CutoutRigs>? _rigs;
  static final _loading = <String, Future<CutoutSprites>>{};
  static final _ready = <String, CutoutSprites>{};

  /// Atlas déjà décodés pour [view] (null tant que le chargement n'est pas fini).
  static CutoutSprites? cached(String view) => _ready[view];

  /// Charge (une seule fois) les atlas de [view] : 'face', 'dos' ou 'profil'.
  static Future<CutoutSprites> load(String view, {AssetBundle? bundle}) {
    final b = bundle ?? rootBundle;
    return _loading[view] ??= () async {
      final rigs =
          await (_rigs ??= b
              .loadString(rigAsset)
              .then(
                (s) =>
                    CutoutRigs.fromJson(jsonDecode(s) as Map<String, dynamic>),
              ));
      final rig = rigs.views[view]!;
      final images = await Future.wait([
        _decode(b, rig.image),
        _decode(b, rig.layersImage),
      ]);
      return _ready[view] = CutoutSprites(
        rig,
        rigs.pixelsPerUnit,
        images[0],
        images[1],
      );
    }();
  }

  static Future<ui.Image> _decode(AssetBundle b, String path) async {
    final data = await b.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  /// Libère les atlas (tests).
  @visibleForTesting
  static void reset() {
    for (final s in _ready.values) {
      s.image.dispose();
      s.layers.dispose();
    }
    _ready.clear();
    _loading.clear();
    _rigs = null;
  }
}

/// Transformation affine plane (x' = a·x + c·y + tx ; y' = b·x + d·y + ty).
@immutable
class Affine2 {
  final double a, b, c, d, tx, ty;
  const Affine2(this.a, this.b, this.c, this.d, this.tx, this.ty);

  ui.Offset apply(ui.Offset p) =>
      ui.Offset(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);

  /// this ∘ o (o appliquée d'abord).
  Affine2 times(Affine2 o) => Affine2(
    a * o.a + c * o.b,
    b * o.a + d * o.b,
    a * o.c + c * o.d,
    b * o.c + d * o.d,
    a * o.tx + c * o.ty + tx,
    b * o.tx + d * o.ty + ty,
  );

  Float64List get matrix4 => Float64List.fromList([
    a, b, 0, 0, //
    c, d, 0, 0,
    0, 0, 1, 0,
    tx, ty, 0, 1,
  ]);
}

/// Segment posé : transformation pixels de l'illustration → repère du modèle.
@immutable
class PlacedSegment {
  final String name;
  final Affine2 toModel;
  final bool far;
  const PlacedSegment(this.name, this.toModel, this.far);
}

ui.Offset _yUp(ui.Offset p) => ui.Offset(p.dx, -p.dy);
ui.Offset _unit(ui.Offset v) {
  final l = v.distance;
  return l == 0 ? const ui.Offset(0, 1) : v / l;
}

/// Os de l'illustration [a0]→[b0] (pixels) amené sur l'os du modèle [a]→[b] :
/// longueur du modèle le long de l'os, largeur × [k] (unités par pixel).
Affine2 cutoutBoneMap(
  ui.Offset a0,
  ui.Offset b0,
  ui.Offset a,
  ui.Offset b,
  double k,
) {
  final p0 = _yUp(a0), q0 = _yUp(b0);
  final len0 = (q0 - p0).distance, len = (b - a).distance;
  final u0 = _unit(q0 - p0), u = _unit(b - a);
  final s = len0 == 0 ? k : len / len0;
  // local = [u0; v0]·(F·p − p0), v0 = perp(u0) ; modèle = a + u·s·x + v·k·y
  final v0 = ui.Offset(-u0.dy, u0.dx), v = ui.Offset(-u.dy, u.dx);
  // M = [u·s, v·k] · [u0; v0] · F, F = diag(1, −1)
  final m00 = u.dx * s * u0.dx + v.dx * k * v0.dx;
  final m01 = u.dx * s * u0.dy + v.dx * k * v0.dy;
  final m10 = u.dy * s * u0.dx + v.dy * k * v0.dx;
  final m11 = u.dy * s * u0.dy + v.dy * k * v0.dy;
  final t = ui.Offset(
    a.dx - (m00 * p0.dx + m01 * p0.dy),
    a.dy - (m10 * p0.dx + m11 * p0.dy),
  );
  return Affine2(m00, m10, -m01, -m11, t.dx, t.dy);
}

/// Pièce rigide : pivot [p0] (pixels) → [a], direction de l'illustration
/// [dir0] (repère y vers le haut) tournée sur [dir], échelle uniforme [k].
Affine2 cutoutRigidMap(
  ui.Offset p0,
  ui.Offset dir0,
  ui.Offset a,
  ui.Offset dir,
  double k,
) {
  final th = math.atan2(dir.dy, dir.dx) - math.atan2(dir0.dy, dir0.dx);
  final cs = math.cos(th) * k, sn = math.sin(th) * k;
  final q = _yUp(p0);
  // modèle = R·k·(F·p − q) + a
  return Affine2(
    cs,
    sn,
    sn,
    -cs,
    a.dx - (cs * q.dx - sn * q.dy),
    a.dy - (sn * q.dx + cs * q.dy),
  );
}

/// Pose chaque segment d'une vue sur les articulations [j] du modèle, dans
/// l'ordre de dessin. Face et dos : 16 segments ; profil : membre éloigné
/// (côté 'g', assombri) d'abord, puis le corps et le membre proche ('d').
List<PlacedSegment> cutoutLayout(CutoutRig rig, double k, Joints j) {
  final ref = rig.joints;
  ui.Offset dirImg(String a, String b) => _yUp(ref[b]!) - _yUp(ref[a]!);
  const up = ui.Offset(0, 1), down = ui.Offset(0, -1);
  final out = <PlacedSegment>[];
  if (rig.view != 'profil') {
    final hg = j['hanche_g']!, hd = j['hanche_d']!;
    final pelvis = cutoutRigidMap(
      ref['bassin']!,
      dirImg('hanche_d', 'hanche_g'),
      j['bassin']!,
      hg - hd,
      k,
    );
    final trunk = cutoutBoneMap(
      ref['bassin']!,
      ref['cou']!,
      j['bassin']!,
      j['cou']!,
      k,
    );
    final head = cutoutRigidMap(
      ref['cou']!,
      up,
      j['cou']!,
      j['tete']! - j['cou']!,
      k,
    );
    final legs = <PlacedSegment>[], arms = <PlacedSegment>[];
    for (final s in const ['g', 'd']) {
      final hip = pelvis.apply(ref['hanche_$s']!);
      legs.addAll([
        PlacedSegment(
          'pied_$s',
          cutoutRigidMap(
            ref['cheville_$s']!,
            down,
            j['cheville_$s']!,
            j['cheville_$s']! - j['genou_$s']!,
            k,
          ),
          false,
        ),
        PlacedSegment(
          'jambe_$s',
          cutoutBoneMap(
            ref['genou_$s']!,
            ref['cheville_$s']!,
            j['genou_$s']!,
            j['cheville_$s']!,
            k,
          ),
          false,
        ),
        PlacedSegment(
          'cuisse_$s',
          cutoutBoneMap(
            ref['hanche_$s']!,
            ref['genou_$s']!,
            hip,
            j['genou_$s']!,
            k,
          ),
          false,
        ),
      ]);
      final shoulder = trunk.apply(ref['epaule_$s']!);
      arms.addAll([
        PlacedSegment(
          'main_$s',
          cutoutRigidMap(
            ref['poignet_$s']!,
            dirImg('poignet_$s', 'main_$s'),
            j['poignet_$s']!,
            j['main_$s']! - j['poignet_$s']!,
            k,
          ),
          false,
        ),
        PlacedSegment(
          'avant_bras_$s',
          cutoutBoneMap(
            ref['coude_$s']!,
            ref['poignet_$s']!,
            j['coude_$s']!,
            j['poignet_$s']!,
            k,
          ),
          false,
        ),
        PlacedSegment(
          'bras_$s',
          cutoutBoneMap(
            ref['epaule_$s']!,
            ref['coude_$s']!,
            shoulder,
            j['coude_$s']!,
            k,
          ),
          false,
        ),
      ]);
    }
    out
      ..addAll(legs)
      ..add(PlacedSegment('tronc', trunk, false))
      ..add(PlacedSegment('bassin', pelvis, false))
      ..add(PlacedSegment('cou', head, false))
      ..add(PlacedSegment('tete', head, false))
      ..addAll(arms);
    return out;
  }
  final trunk = cutoutBoneMap(
    ref['bassin']!,
    ref['cou']!,
    j['bassin']!,
    j['cou']!,
    k,
  );
  final pelvis = cutoutRigidMap(
    ref['bassin']!,
    dirImg('bassin', 'cou'),
    j['bassin']!,
    j['cou']! - j['bassin']!,
    k,
  );
  final head = cutoutRigidMap(
    ref['cou']!,
    up,
    j['cou']!,
    j['tete']! - j['cou']!,
    k,
  );
  final shoulder = trunk.apply(ref['epaule']!);
  final hip = pelvis.apply(ref['hanche']!);
  List<PlacedSegment> leg(String s, bool far) => [
    PlacedSegment(
      'pied',
      cutoutRigidMap(
        ref['cheville']!,
        dirImg('talon', 'pointe'),
        j['cheville_$s']!,
        j['pied_$s']! - j['talon_$s']!,
        k,
      ),
      far,
    ),
    PlacedSegment(
      'jambe',
      cutoutBoneMap(
        ref['genou']!,
        ref['cheville']!,
        j['genou_$s']!,
        j['cheville_$s']!,
        k,
      ),
      far,
    ),
    PlacedSegment(
      'cuisse',
      cutoutBoneMap(ref['hanche']!, ref['genou']!, hip, j['genou_$s']!, k),
      far,
    ),
  ];
  List<PlacedSegment> arm(String s, bool far) => [
    PlacedSegment(
      'main',
      cutoutRigidMap(
        ref['poignet']!,
        dirImg('poignet', 'main'),
        j['poignet_$s']!,
        j['main_$s']! - j['poignet_$s']!,
        k,
      ),
      far,
    ),
    PlacedSegment(
      'avant_bras',
      cutoutBoneMap(
        ref['coude']!,
        ref['poignet']!,
        j['coude_$s']!,
        j['poignet_$s']!,
        k,
      ),
      far,
    ),
    PlacedSegment(
      'bras',
      cutoutBoneMap(ref['epaule']!, ref['coude']!, shoulder, j['coude_$s']!, k),
      far,
    ),
  ];
  return [
    ...leg('g', true),
    ...arm('g', true),
    ...leg('d', false),
    PlacedSegment('tronc', trunk, false),
    PlacedSegment('bassin', pelvis, false),
    PlacedSegment('cou', head, false),
    PlacedSegment('tete', head, false),
    ...arm('d', false),
  ];
}

/// Peint le corps découpé. [toCanvas] : repère du modèle → pixels du canevas ;
/// [heat] : couleur d'un groupe pour une intensité (rampe de la carte).
void paintCutoutBody(
  ui.Canvas canvas,
  CutoutSprites sprites,
  Joints joints,
  Affine2 toCanvas,
  Map<String, double> groups,
  ui.Color Function(double) heat,
) {
  final k = 1 / sprites.pixelsPerUnit;
  final base = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  final far =
      ui.Paint()
        ..filterQuality = ui.FilterQuality.medium
        ..colorFilter = const ui.ColorFilter.mode(
          cutoutFarShade,
          ui.BlendMode.modulate,
        );
  final tints = <String, (ui.Paint, ui.Paint)>{
    for (final e in groups.entries)
      if (e.value > 0.02)
        e.key: (
          ui.Paint()
            ..filterQuality = ui.FilterQuality.medium
            ..colorFilter = ui.ColorFilter.mode(
              heat(e.value),
              ui.BlendMode.modulate,
            ),
          ui.Paint()
            ..filterQuality = ui.FilterQuality.medium
            ..colorFilter = ui.ColorFilter.mode(
              ui.Color.lerp(heat(e.value), const ui.Color(0xFF000000), .38)!,
              ui.BlendMode.modulate,
            ),
        ),
  };
  for (final placed in cutoutLayout(sprites.rig, k, joints)) {
    final seg = sprites.rig.segment(placed.name);
    canvas
      ..save()
      ..transform(toCanvas.times(placed.toModel).matrix4);
    canvas.drawImageRect(
      sprites.image,
      seg.src,
      ui.Rect.fromLTWH(
        seg.origin.dx,
        seg.origin.dy,
        seg.src.width,
        seg.src.height,
      ),
      placed.far ? far : base,
    );
    for (final l in seg.layers) {
      final t = tints[l.group];
      if (t == null) continue;
      canvas.drawImageRect(
        sprites.layers,
        l.src,
        ui.Rect.fromLTWH(
          seg.origin.dx + l.offset.dx,
          seg.origin.dy + l.offset.dy,
          l.src.width,
          l.src.height,
        ),
        placed.far ? t.$2 : t.$1,
      );
    }
    canvas.restore();
  }
}
