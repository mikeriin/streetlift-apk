// M2 (mannequin 3D) : mannequin anatomique statique réutilisable.
//
// Modèle d'exécution `assets/anatomy/mannequin.glb` (fabriqué par
// tools/anatomy/build_model.py ; 5.5.2 : depuis l'écorché acheté par le
// propriétaire, un muscle = une région de sa texture ; jusqu'à 5.5.1 :
// Z-Anatomy / BodyParts3D, CC BY-SA 4.0), converti au build par le hook de
// flutter_scene et chargé une seule fois.
// Une maille par muscle et par côté (nœud nommé par l'id de la région de
// `assets/anatomy/muscles_map.json`) : la mise en évidence (jusqu'à 5.5.3 :
// matériau coloré des nœuds ; 5.5.4 : halo dessiné par-dessus la vue,
// `MannequinHaloPainter`, le maillage reste gris), le toucher lance un rayon
// sur la scène et nomme le muscle touché.
//
// Rendu à la demande : la vue ne se redessine que lorsqu'un paramètre change
// (caméra, intensités, thème, réglages) ; aucune boucle continue, sauf dans
// l'écran « Moteur 3D » qui mesure la fluidité (`spin`). Sans Flutter GPU, la
// carte 2D historique (`MuscleHeatmap`) prend le relais.
//
// M4b : tous les muscles, profonds compris, sont rendus translucides
// ([kMuscleOpacity]) pour qu'un muscle sollicité caché derrière d'autres se
// voie à travers eux. Os, tête, contexte, mains et pieds restent opaques.
// flutter_scene 0.23 dessine d'abord les surfaces opaques (écriture de
// profondeur), puis les translucides triées de l'arrière vers l'avant à
// chaque image (distance du centre de chaque maille à la caméra, le long de
// son axe), sans écriture de profondeur, faces arrière éliminées : chaque
// muscle ne compte qu'une couche par pixel, même en rotation.
//
// M5 : le modèle portait un squelette d'animation et une peau
// (`mannequin_rig.dart`). [MannequinScene.applyPose] tourne les articulations
// (le GPU déforme les maillages) ; le toucher et le cadrage utilisent les
// positions déformées, calculées sur le processeur avec la même peau.
//
// 5.5.2 (M56 correction 2, décision du propriétaire du 29/09/2026) : l'écorché
// acheté n'a ni squelette ni posture (rig.json et mannequin_skin.bin
// retirés) ; aucun rig n'est chargé, le modèle reste au repos partout. Le
// code de posture reste en place, inactif, pour les positions d'exercice
// que le propriétaire fera à la main plus tard.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

// `Material` désigne ici le matériau 3D de flutter_scene.
import 'package:flutter/material.dart' hide Material;
import 'package:flutter/services.dart';
import 'package:flutter_scene/scene.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math.dart' as vm;

import 'app_theme.dart';
import 'engine3d.dart';
import 'mannequin_gestures.dart';
import 'mannequin_preload.dart';
import 'mannequin_rig.dart';
import 'muscle_body.dart';
import 'ui.dart';

/// Source du modèle d'exécution (chemin de source lu par `loadScene`).
const kMannequinAsset = 'assets/anatomy/mannequin.glb';

/// Carte des régions (id, côté, nom français, groupe, muscles du pack).
const kMannequinMapAsset = 'assets/anatomy/muscles_map.json';

/// Crédits du modèle (écorché acheté), repris dans « Sources et licences ».
const kMannequinAttributionAsset = 'assets/anatomy/ATTRIBUTION.md';

/// M4b : opacité de tous les muscles (décision du propriétaire, 28/09/2026 :
/// 50 %). Constante unique, à ajuster ici ; 1 rend les muscles opaques.
/// 5.5.3 (M56 correction 3, décision du propriétaire du 29/09/2026) : 100 % :
/// l'écorché n'a plus de couche profonde à voir par transparence.
const kMuscleOpacity = 1.0;

/// Intensités de la mise en évidence (décision du propriétaire).
const kIntensityPrimary = 1.0;
const kIntensitySecondary = .62;
const kIntensityStabilizer = .35;

/// M3 : muscles étirés (rôle « Étiré » du pack), intensité 0,25 dans une
/// teinte distincte de la rampe rouge : bleu acier, froid et sourd, qui ne
/// peut pas se lire comme un muscle sollicité (voir DECISIONS_3D.md, M3).
const kIntensityStretched = .25;

/// Teinte des muscles étirés (sombre : plus claire, pour rester lisible sur
/// le fond de scène sombre ; clair : plus dense).
Color mannequinStretch(bool dark) =>
    dark ? const Color(0xFF5B8DB0) : const Color(0xFF346C92);

/// Os et contexte sombre (tête lisse, tissus, mains et pieds au repos).
const kBoneGray = Color(0xFF4A4646);
const kDarkVolume = Color(0xFF2E2A2A);

// ----------------------------------------------------------------- carte --

/// Région sélectionnable du mannequin : un muscle d'un côté, ou le volume
/// d'une main ou d'un pied (muscles intrinsèques).
class MuscleRegion {
  final String id, cle, cote, nom, nomCote, groupe, couche;
  final List<String> pack;

  const MuscleRegion({
    required this.id,
    required this.cle,
    required this.cote,
    required this.nom,
    required this.nomCote,
    required this.groupe,
    required this.couche,
    required this.pack,
  });

  factory MuscleRegion.fromJson(Map<String, dynamic> j) => MuscleRegion(
    id: j['id'] as String,
    cle: j['cle'] as String,
    cote: j['cote'] as String,
    nom: j['nom'] as String,
    nomCote: j['nom_cote'] as String,
    groupe: j['groupe'] as String,
    couche: j['couche'] as String,
    pack: [for (final p in j['pack'] as List) p as String],
  );

  /// M4b : muscle profond (source anatomique ou caché au repos).
  bool get profond => couche == 'profond';

  /// Libellé de la bulle au toucher : « Grand dorsal (gauche) · Dos »,
  /// « Grand rhomboïde (droit) (profond) · Dos ».
  String get label =>
      '$nomCote${profond ? ' (profond)' : ''} · '
      '${groupe[0].toUpperCase()}${groupe.substring(1)}';
}

/// Carte des régions du mannequin (`assets/anatomy/muscles_map.json`).
class MannequinMap {
  final List<MuscleRegion> regions;
  final List<String> groups;
  final Map<String, MuscleRegion> byId;

  /// M4b : régions cachées au repos (retirées du modèle jusqu'à 5.3.0,
  /// mesure de visibilité de M2), toutes profondes.
  final Set<String> hiddenAtRest;

  MannequinMap(this.regions, this.groups, {this.hiddenAtRest = const {}})
    : byId = {for (final r in regions) r.id: r};

  factory MannequinMap.fromJson(Map<String, dynamic> j) => MannequinMap(
    [
      for (final r in j['regions'] as List)
        MuscleRegion.fromJson(r as Map<String, dynamic>),
    ],
    [for (final g in j['groupes'] as List) g as String],
    hiddenAtRest: {
      for (final id in (j['caches_au_repos'] as List?) ?? const [])
        id as String,
    },
  );

  /// M4b : ids des régions profondes (filtre « Muscles profonds »).
  Set<String> get deepIds => {
    for (final r in regions)
      if (r.profond) r.id,
  };

  static Future<MannequinMap>? _cache;

  /// Carte déjà chargée, s'il y en a une.
  static MannequinMap? loaded;

  /// Chargée une seule fois par lancement.
  static Future<MannequinMap> load([AssetBundle? bundle]) =>
      _cache ??= (bundle ?? rootBundle)
          .loadString(kMannequinMapAsset)
          .then((s) => loaded = MannequinMap.fromJson(jsonDecode(s)));

  Iterable<MuscleRegion> ofGroup(String group) =>
      regions.where((r) => r.groupe == group);

  /// Intensités par région pour des groupes de l'application (0-1).
  Map<String, double> fromGroups(Map<String, double> groups) => {
    for (final r in regions)
      if ((groups[r.groupe] ?? 0) > 0) r.id: groups[r.groupe]!,
  };

  /// Intensités par région pour des muscles du pack (0-1) : une région prend
  /// l'intensité la plus forte de ses muscles du pack.
  Map<String, double> fromPack(Map<String, double> pack) {
    final out = <String, double>{};
    for (final r in regions) {
      for (final p in r.pack) {
        final v = pack[p] ?? 0;
        if (v > (out[r.id] ?? 0)) out[r.id] = v;
      }
    }
    return out;
  }

  /// Intensités par groupe (repli 2D) : le maximum des régions du groupe.
  Map<String, double> groupsOf(Map<String, double> intensities) {
    final out = <String, double>{};
    intensities.forEach((id, v) {
      final g = byId[id]?.groupe;
      if (g != null && v > (out[g] ?? 0)) out[g] = v;
    });
    return out;
  }

  /// Noms distincts (sans le côté) des régions allumées, par intensité
  /// décroissante : la liste en texte qui accompagne toujours la couleur.
  List<String> names(Map<String, double> intensities) {
    final best = <String, double>{};
    intensities.forEach((id, v) {
      final r = byId[id];
      if (r == null || v <= 0) return;
      if (v > (best[r.nom] ?? 0)) best[r.nom] = v;
    });
    final list = best.keys.toList()
      ..sort((a, b) {
        final c = best[b]!.compareTo(best[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return list;
  }
}

// ------------------------------------------------------------------ halo --

/// 5.5.4 (M56 correction 4, décision du propriétaire du 29/09/2026) : le
/// maillage n'est plus coloré ; chaque muscle sollicité reçoit un **halo**
/// dessiné par-dessus la vue : ses triangles tournés vers la caméra sont
/// projetés à l'écran, l'union est remplie dans la couleur de la rampe
/// (couleur dominante, intensité → opacité) avec un flou doux ([soft],
/// réglage « Halo »), le gris du muscle reste visible au travers. Sans
/// scène ni GPU : projection calculée ici, étalonnée sur
/// `camera.screenPointToRay` (mêmes repères que le toucher). Approximation
/// assumée : un triangle tourné vers la caméra mais caché par une autre
/// partie du corps (bras devant le tronc) est quand même compté.
class MannequinHaloPainter extends CustomPainter {
  final MannequinScene scene;
  final PerspectiveCamera camera;
  final Size size;
  final bool dark, soft;

  const MannequinHaloPainter({
    required this.scene,
    required this.camera,
    required this.size,
    required this.dark,
    required this.soft,
  });

  /// Flou du halo (px) et opacités (intensité 0 → 1).
  static const blurSigma = 9.0;
  static double alphaFor(double v) => .16 + .30 * v;

  @override
  void paint(Canvas canvas, Size s) {
    final lit = scene.haloIntensities;
    final stretched = scene.haloStretched;
    if (lit.isEmpty && stretched.isEmpty) return;
    final proj = HaloProjection.of(camera, size);
    if (proj == null) return;
    void draw(String id, Color color, double alpha) {
      final mesh = scene.restMesh(id);
      if (mesh == null) return;
      final path = proj.silhouette(
        mesh.positions,
        mesh.indices ?? List<int>.generate(mesh.vertexCount, (i) => i),
        outward: scene.windingOutward,
      );
      if (path == null) return;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      if (soft) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, blurSigma);
      }
      canvas.drawPath(path, paint);
    }

    // Faibles d'abord : les principaux ressortent.
    final ordered = lit.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final id in stretched) {
      draw(id, mannequinStretch(dark), alphaFor(kIntensityStretched));
    }
    for (final e in ordered) {
      draw(e.key, mannequinHeat(e.value, dark), alphaFor(e.value));
    }
  }

  @override
  bool shouldRepaint(MannequinHaloPainter old) =>
      old.scene != scene ||
      old.camera != camera ||
      old.size != size ||
      old.dark != dark ||
      old.soft != soft;
}

/// Projection écran d'un point du monde pour une caméra donnée, étalonnée
/// sur les rayons des coins de la vue (aucune hypothèse sur les
/// conventions du moteur).
class HaloProjection {
  final vm.Vector3 eye, forward, right, up;
  final double kx, ky;
  final Size size;

  const HaloProjection(
    this.eye,
    this.forward,
    this.right,
    this.up,
    this.kx,
    this.ky,
    this.size,
  );

  static HaloProjection? of(PerspectiveCamera camera, Size size) {
    if (size.isEmpty) return null;
    final eye = camera.position;
    final centre = camera.screenPointToRay(size.center(Offset.zero), size);
    final forward = centre.direction.normalized();
    var right = forward.cross(vm.Vector3(0, 1, 0));
    if (right.length2 < 1e-9) right = vm.Vector3(1, 0, 0);
    right.normalize();
    final up = right.cross(forward)..normalize();
    // Coin bas droit : composantes tangentielles du rayon → échelle et signe
    // de l'axe écran correspondant.
    final corner = camera
        .screenPointToRay(Offset(size.width, size.height), size)
        .direction
        .normalized();
    final cz = corner.dot(forward);
    if (cz.abs() < 1e-6) return null;
    final kx = corner.dot(right) / cz;
    final ky = corner.dot(up) / cz;
    if (kx.abs() < 1e-9 || ky.abs() < 1e-9) return null;
    return HaloProjection(eye, forward, right, up, kx, ky, size);
  }

  /// Point du monde → écran (null derrière la caméra).
  Offset? project(double x, double y, double z) {
    final dx = x - eye.x, dy = y - eye.y, dz = z - eye.z;
    final pz = dx * forward.x + dy * forward.y + dz * forward.z;
    if (pz <= 1e-4) return null;
    final px = (dx * right.x + dy * right.y + dz * right.z) / pz;
    final py = (dx * up.x + dy * up.y + dz * up.z) / pz;
    return Offset(
      size.width / 2 + px / kx * size.width / 2,
      size.height / 2 + py / ky * size.height / 2,
    );
  }

  /// Silhouette écran des triangles tournés vers la caméra (null : aucun).
  Path? silhouette(Float32List p, List<int> idx, {bool outward = true}) {
    final n = p.length ~/ 3;
    final screen = List<Offset?>.filled(n, null);
    for (var i = 0; i < n; i++) {
      screen[i] = project(p[i * 3], p[i * 3 + 1], p[i * 3 + 2]);
    }
    final path = Path();
    var any = false;
    for (var t = 0; t + 2 < idx.length; t += 3) {
      final a = idx[t], b = idx[t + 1], c = idx[t + 2];
      final sa = screen[a], sb = screen[b], sc = screen[c];
      if (sa == null || sb == null || sc == null) continue;
      // Face tournée vers la caméra : normale (sens direct glTF) du côté
      // de l'œil.
      final ax = p[a * 3], ay = p[a * 3 + 1], az = p[a * 3 + 2];
      final ux = p[b * 3] - ax, uy = p[b * 3 + 1] - ay, uz = p[b * 3 + 2] - az;
      final wx = p[c * 3] - ax, wy = p[c * 3 + 1] - ay, wz = p[c * 3 + 2] - az;
      final nx = uy * wz - uz * wy, ny = uz * wx - ux * wz;
      final nz = ux * wy - uy * wx;
      final facing = nx * (eye.x - ax) + ny * (eye.y - ay) + nz * (eye.z - az);
      if (outward ? facing <= 0 : facing >= 0) continue;
      path
        ..moveTo(sa.dx, sa.dy)
        ..lineTo(sb.dx, sb.dy)
        ..lineTo(sc.dx, sc.dy)
        ..close();
      any = true;
    }
    return any ? path : null;
  }
}

// --------------------------------------------------------------- réglages --

/// Réglages › Affichage 3D. Préférences de l'appareil (SharedPreferences),
/// hors sauvegarde : le format des sauvegardes reste inchangé.
class Display3DSettings {
  Display3DSettings._();
  static final instance = Display3DSettings._();

  static const _kNames = 'kt3d_nom_toucher';
  static const _kBones = 'kt3d_os_visibles';
  static const _kHalo = 'kt3d_halo';

  /// Nom du muscle au toucher (activé par défaut).
  final touchNames = ValueNotifier<bool>(true);

  /// Os visibles (activé par défaut).
  final bones = ValueNotifier<bool>(true);

  /// Halo autour des muscles sollicités (activé par défaut).
  final halo = ValueNotifier<bool>(true);

  bool _loaded = false;

  Listenable get listenable => Listenable.merge([touchNames, bones, halo]);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      touchNames.value = p.getBool(_kNames) ?? true;
      bones.value = p.getBool(_kBones) ?? true;
      halo.value = p.getBool(_kHalo) ?? true;
    } catch (_) {
      // Préférences illisibles : valeurs par défaut.
    }
  }

  Future<void> set({bool? touchNames, bool? bones, bool? halo}) async {
    if (touchNames != null) this.touchNames.value = touchNames;
    if (bones != null) this.bones.value = bones;
    if (halo != null) this.halo.value = halo;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kNames, this.touchNames.value);
      await p.setBool(_kBones, this.bones.value);
      await p.setBool(_kHalo, this.halo.value);
    } catch (_) {}
  }

  /// Tests : revient aux valeurs par défaut et relit les préférences.
  void reset() {
    _loaded = false;
    touchNames.value = true;
    bones.value = true;
    halo.value = true;
  }
}

// ------------------------------------------------------------------- vues --

/// Vues de départ : Face, Dos, Profil (côté gauche du mannequin, tourné vers
/// la gauche de l'écran comme l'illustration historique) et 3/4 avant.
enum MannequinView {
  face('Face', 0),
  dos('Dos', math.pi),
  profil('Profil', math.pi / 2),
  troisQuarts('3/4', math.pi / 4);

  final String label;

  /// Angle de la caméra autour de l'axe vertical, depuis la face, vers le
  /// côté gauche du mannequin.
  final double yaw;
  const MannequinView(this.label, this.yaw);
}

double _linear(double c) =>
    c <= .04045 ? c / 12.92 : math.pow((c + .055) / 1.055, 2.4).toDouble();

vm.Vector4 _lin(Color c, [double scale = 1, double alpha = 1]) => vm.Vector4(
  _linear(c.r) * scale,
  _linear(c.g) * scale,
  _linear(c.b) * scale,
  alpha,
);

/// Rampe des muscles sollicités (même loi que `heat()` de muscle_body.dart)
/// pour un thème donné. 5.5.2 (décision du propriétaire, 29/09/2026) : la
/// rampe suit la **couleur dominante** choisie dans les réglages (principale
/// → vive / claire), plus le rouge historique fixe.
Color mannequinHeat(double v, bool dark, [KAccentSpec? accent]) {
  final a = accent ?? SL.accentSpec;
  return Color.lerp(
    a.principal,
    dark ? a.bright : (a.vividLight ?? a.vivid),
    .15 + .85 * v.clamp(0.0, 1.0),
  )!;
}

// ------------------------------------------------------------------ modèle --

/// Repère du modèle importé, mesuré une fois sur ses nœuds : avant du corps,
/// côté gauche anatomique, centre et hauteur.
class MannequinFrame {
  final vm.Vector3 front, left, center;
  final double height;
  const MannequinFrame(this.front, this.left, this.center, this.height);
}

MannequinFrame? _frame;

/// Positions de repos (repère de la scène) des maillages nommés du modèle.
/// Maillages avec peau : `extractMeshData` rend la pose de liaison.
Map<String, MeshData> _restMeshes(Node root) {
  final out = <String, MeshData>{};
  void visit(Node n) {
    if (n.name.isNotEmpty && n.mesh != null) {
      out[n.name] = n.extractMeshData(transform: vm.Matrix4.identity());
    }
    for (final c in n.children) {
      visit(c);
    }
  }

  visit(root);
  return out;
}

(vm.Vector3, vm.Vector3)? _boundsOf(Float32List p) {
  if (p.length < 3) return null;
  final lo = vm.Vector3.all(double.infinity);
  final hi = vm.Vector3.all(-double.infinity);
  for (var i = 0; i + 2 < p.length; i += 3) {
    lo.x = math.min(lo.x, p[i]);
    lo.y = math.min(lo.y, p[i + 1]);
    lo.z = math.min(lo.z, p[i + 2]);
    hi.x = math.max(hi.x, p[i]);
    hi.y = math.max(hi.y, p[i + 1]);
    hi.z = math.max(hi.z, p[i + 2]);
  }
  return (lo, hi);
}

/// M5 : mesuré sur les positions de repos (les bornes d'un maillage avec
/// peau ne sont pas celles du repos) ; mêmes valeurs qu'en 5.3.2.
MannequinFrame _measure(Map<String, MeshData> meshes) {
  vm.Vector3? centerOf(String name) {
    final m = meshes[name];
    final b = m == null ? null : _boundsOf(m.positions);
    return b == null ? null : (b.$1 + b.$2) * .5;
  }

  final lo = vm.Vector3.all(double.infinity);
  final hi = vm.Vector3.all(-double.infinity);
  for (final m in meshes.values) {
    final b = _boundsOf(m.positions);
    if (b == null) continue;
    lo.setValues(
      math.min(lo.x, b.$1.x),
      math.min(lo.y, b.$1.y),
      math.min(lo.z, b.$1.z),
    );
    hi.setValues(
      math.max(hi.x, b.$2.x),
      math.max(hi.y, b.$2.y),
      math.max(hi.z, b.$2.z),
    );
  }
  final empty = lo.x > hi.x;
  final center = empty ? vm.Vector3(0, .9, 0) : (lo + hi) * .5;
  final height = empty ? 1.7 : hi.y - lo.y;
  // Avant : du grand fessier vers le droit de l'abdomen ; gauche : côté des
  // régions « _left ».
  final abdo = centerOf('rectus_abdominis_left');
  final glute = centerOf('gluteus_maximus_left');
  var front = vm.Vector3(0, 0, -1);
  if (abdo != null && glute != null) {
    final d = abdo - glute;
    front = d.z.abs() >= d.x.abs()
        ? vm.Vector3(0, 0, d.z.sign)
        : vm.Vector3(d.x.sign, 0, 0);
  }
  final l = centerOf('deltoid_lateral_left');
  final r = centerOf('deltoid_lateral_right');
  var left = vm.Vector3(1, 0, 0);
  if (l != null && r != null) {
    final d = l - r;
    left = d.x.abs() >= d.z.abs()
        ? vm.Vector3(d.x.sign, 0, 0)
        : vm.Vector3(0, 0, d.z.sign);
  }
  return MannequinFrame(front, left, center, height);
}

/// M5 : cadrage d'une posture (centre, hauteur, largeur horizontale).
class MannequinFraming {
  final vm.Vector3 center;
  final double height, width;
  const MannequinFraming(this.center, this.height, this.width);

  static MannequinFraming lerp(
    MannequinFraming a,
    MannequinFraming b,
    double t,
  ) => MannequinFraming(
    a.center + (b.center - a.center) * t,
    a.height + (b.height - a.height) * t,
    a.width + (b.width - a.width) * t,
  );
}

/// Scène du mannequin : modèle, un matériau par région, lumière qui suit la
/// caméra, fond de la charte, halo en thème sombre.
///
/// Chaque nœud de région reçoit son propre matériau avant l'ajout du modèle
/// à la scène ; la mise en évidence modifie ensuite les couleurs de ces
/// matériaux (flutter_scene 0.23 prend en compte un changement de propriété
/// d'un matériau, pas le remplacement du matériau d'un nœud déjà monté).
class MannequinScene {
  final Scene scene = Scene();
  final Node model;
  final MannequinMap map;
  final MannequinFrame frame;

  final PhysicallyBasedMaterial _bone = _mat(kBoneGray, roughness: .85);
  final PhysicallyBasedMaterial _dark = _mat(kDarkVolume, roughness: .85);
  late final PhysicallyBasedMaterial _tendon = _tendonMaterial();

  /// 5.5.2 : tendons de l'écorché, gris des muscles à leur opacité.
  PhysicallyBasedMaterial _tendonMaterial() {
    final m = _mat(kMuscleGray);
    m.baseColorFactor = _lin(kMuscleGray, 1, opacity);
    if (opacity < 1) m.alphaMode = AlphaMode.blend;
    return m;
  }

  final Map<String, PhysicallyBasedMaterial> _regions = {};
  final Map<String, Node> _nodes = {};

  bool? _dark3d;
  Color? _background;
  KAccentSpec? _accent3d;
  Map<String, double> _intensities = const {};
  Set<String> _stretched = const {};
  Set<String> _hidden = const {};
  bool _bones = true, _halo = true;

  /// Mesure avant / après de M4b (tests d'intégration) : opacité imposée
  /// aux muscles et régions masquées d'office, lues à la création de la
  /// scène. Null : [kMuscleOpacity], aucune région masquée d'office.
  @visibleForTesting
  static double? debugOpacity;
  @visibleForTesting
  static Set<String> Function(MannequinMap map)? debugHidden;

  /// Opacité des muscles de cette scène.
  final double opacity = debugOpacity ?? kMuscleOpacity;
  late final Set<String> _forcedHidden = debugHidden?.call(map) ?? const {};

  static PhysicallyBasedMaterial _mat(Color c, {double roughness = .78}) =>
      PhysicallyBasedMaterial()
        ..baseColorFactor = _lin(c)
        ..metallicFactor = 0
        ..roughnessFactor = roughness;

  /// M5 : squelette, postures et peau (null : modèle sans rig, toujours au
  /// repos).
  final MannequinRig? rig;

  /// Positions de repos des maillages (repère de la scène), partagées.
  final Map<String, MeshData> _rest;

  final Map<String, Node> _joints = {};
  final Map<String, vm.Vector3> _jointRest = {};

  /// Le repère de la scène est-il le miroir (z → −z) de celui du glTF ?
  /// (Import de flutter_scene : `bakeNative`.) Mesuré sur les articulations.
  bool _flip = false;

  MannequinScene._(this.model, this.map, this.frame, this.rig, this._rest) {
    void collect(Node n) {
      if (n.name.isNotEmpty) _nodes[n.name] = n;
      for (final c in n.children) {
        collect(c);
      }
    }

    collect(model);
    final rig = this.rig;
    if (rig != null) {
      for (final b in rig.bones) {
        final node = _nodes['j_${b.name}'];
        if (node == null) continue;
        _joints[b.name] = node;
        _jointRest[b.name] = node.localTransform.getTranslation();
      }
      // Sens de l'axe avant : translation des orteils depuis le pied.
      final toes = rig.index['toes_l'], foot = rig.index['foot_l'];
      final t = _jointRest['toes_l'];
      if (toes != null && foot != null && t != null) {
        final gz = rig.bones[toes].head.z - rig.bones[foot].head.z;
        _flip = gz * t.z < 0;
      }
    }
    _nodes.forEach((name, node) {
      // Maillages avec peau : jamais écartés par le cadre de la caméra (leurs
      // bornes sont celles du repos, pas de la posture).
      if (node.skin != null) node.frustumCulled = false;
    });
    _nodes.forEach((name, node) {
      final region = map.byId[name];
      if (region != null) {
        final m = _mat(
          region.couche == 'volume' ? kDarkVolume : kMuscleGray,
          roughness: region.couche == 'volume' ? .85 : .78,
        );
        // Muscles translucides (M4b) ; mains et pieds opaques.
        if (region.couche != 'volume' && opacity < 1) {
          m.alphaMode = AlphaMode.blend;
        }
        _regions[name] = m;
        _assign(node, m);
      } else if (name == 'os') {
        _assign(node, _bone);
      } else if (name == 'contexte' || name == 'head') {
        _assign(node, _dark);
      } else if (name.startsWith('tendon_')) {
        // 5.5.2 : tendons et aponévroses de l'écorché, gris translucide
        // comme les muscles (un nœud par pièce pour le tri de
        // transparence), jamais allumés ni touchés.
        _assign(node, _tendon);
      }
    });
    scene
      ..add(model)
      ..environmentIntensity = .75
      ..toneMapping = ToneMappingMode.linear;
    scene.postProcess.bloom
      ..threshold = .6
      ..intensity = .55
      ..scatter = .7;
  }

  /// Modèle chargé une seule fois par lancement (M3) : chaque mannequin en
  /// reçoit une copie (arbre de nœuds et enveloppes de maillage ; géométrie
  /// partagée), sans relire ni convertir le fichier. Le modèle gardé ici
  /// n'est jamais ajouté à une scène.
  static Future<Node>? _template;

  static Future<Node> _loadTemplate() {
    final pending = _template ??= loadScene(kMannequinAsset);
    return pending.catchError((Object e) {
      // Échec non mis en cache : le mannequin suivant réessaie.
      if (identical(_template, pending)) _template = null;
      throw e;
    });
  }

  static Map<String, MeshData>? _restCache;

  /// 5.5.2 : plus de rig (écorché acheté, sans squelette) ; le mannequin
  /// reste au repos. Le code de posture ci-dessous attend un rig non nul.
  static Future<MannequinRig?> _loadRig() async => null;

  static Future<MannequinScene> create() async {
    final results = await Future.wait<Object?>([
      _loadTemplate(),
      MannequinMap.load(),
      _loadRig(),
    ]);
    final template = results[0] as Node;
    final rest = _restCache ??= _restMeshes(template);
    final scene = MannequinScene._(
      template.clone(),
      results[1] as MannequinMap,
      _frame ??= _measure(rest),
      results[2] as MannequinRig?,
      rest,
    );
    scene._applyMaterials();
    return scene;
  }

  /// Nœuds présents dans le modèle (contrôles).
  Iterable<String> get nodeNames => _nodes.keys;

  /// Articulations du squelette présentes dans le modèle (contrôles).
  Iterable<String> get jointNames => _joints.keys;

  /// Posture courante (repos par défaut).
  RigPose get pose => _pose;
  RigPose _pose = RigPose.rest;
  bool _posed = false;

  /// Cadrage courant (M5 : celui de la posture ; au repos, celui de 5.3.2).
  MannequinFraming get framing => _framing ??= restFraming;
  MannequinFraming? _framing;
  set framing(MannequinFraming f) => _framing = f;

  /// Cadrage du modèle au repos : le corps entier, largeur utile ≈ moitié de
  /// la hauteur (bras le long du corps).
  MannequinFraming get restFraming =>
      MannequinFraming(frame.center, frame.height, frame.height * 1.08 * .5);

  vm.Vector3 get target {
    final c = framing.center;
    return vm.Vector3(c.x, c.y, c.z);
  }

  vm.Vector3 _vecToScene(vm.Vector3 v) =>
      _flip ? vm.Vector3(v.x, v.y, -v.z) : v.clone();

  /// Place le mannequin dans [pose] : rotations des articulations (le GPU
  /// déforme les maillages), toucher recalculé à la demande, ordre des
  /// maillages translucides mis à jour.
  void applyPose(RigPose pose) {
    final rig = this.rig;
    if (rig == null || _joints.isEmpty) return;
    // M56 : os d'aide et échelles de gonflement recalculés ici, comme à la
    // fabrication (les postures de rig.json ne portent que les
    // rotations des segments).
    pose = rig.withHelpers(pose);
    _pose = pose;
    _posed = pose.rotations.isNotEmpty || pose.translation.length2 > 0;
    for (final b in rig.bones) {
      final node = _joints[b.name];
      final rest = _jointRest[b.name];
      if (node == null || rest == null) continue;
      final t = b.parent == null ? rest + _vecToScene(pose.translation) : rest;
      node.localTransform = _matToScene(
        MannequinRig.localMatrix(
          _flip ? vm.Vector3(t.x, t.y, -t.z) : t,
          pose.rotationOf(b.name),
          pose.scales[b.name],
        ),
      );
    }
    _posedPickables = null;
    _updateSortHints();
  }

  /// Matrice locale d'un os (repère glTF) dans le repère de la scène : le
  /// miroir z (M5, `bakeNative` de flutter_scene) s'applique des deux côtés.
  vm.Matrix4 _matToScene(vm.Matrix4 m) {
    if (!_flip) return m;
    final f = vm.Matrix4.diagonal3Values(1, 1, -1);
    return f * m * f;
  }

  /// Positions déformées d'un maillage (repère de la scène) pour [mats]
  /// (matrices de peau du rig, repère glTF).
  Float32List _skinned(String name, Float64List mats) {
    final rig = this.rig!;
    final rest = _rest[name]!.positions;
    if (!_flip) return rig.skinPositions(name, rest, mats);
    final g = Float32List.fromList(rest);
    for (var i = 2; i < g.length; i += 3) {
      g[i] = -g[i];
    }
    final out = rig.skinPositions(name, g, mats);
    for (var i = 2; i < out.length; i += 3) {
      out[i] = -out[i];
    }
    return out;
  }

  /// Cadrage d'une posture : boîte du corps déformé (repère de la scène).
  MannequinFraming framingFor(RigPose pose) {
    final rig = this.rig;
    if (rig == null ||
        (pose.rotations.isEmpty && pose.translation.length2 == 0)) {
      return restFraming;
    }
    final mats = rig.skinMatrices(pose);
    final lo = vm.Vector3.all(double.infinity);
    final hi = vm.Vector3.all(-double.infinity);
    for (final name in _rest.keys) {
      final b = _boundsOf(_skinned(name, mats));
      if (b == null) continue;
      lo.setValues(
        math.min(lo.x, b.$1.x),
        math.min(lo.y, b.$1.y),
        math.min(lo.z, b.$1.z),
      );
      hi.setValues(
        math.max(hi.x, b.$2.x),
        math.max(hi.y, b.$2.y),
        math.max(hi.z, b.$2.z),
      );
    }
    final size = hi - lo;
    return MannequinFraming(
      (lo + hi) * .5,
      size.y,
      math.sqrt(size.x * size.x + size.z * size.z) * 1.02,
    );
  }

  /// Ordre des maillages translucides : flutter_scene les trie par le centre
  /// de leurs bornes (celles du repos pour un maillage avec peau). Chaque
  /// maille reçoit une translation (ignorée par le dessin avec peau) qui
  /// amène ce centre sur le centre déformé : peau appliquée au centre de
  /// repos avec les influences moyennes de la maille.
  void _updateSortHints() {
    final rig = this.rig;
    if (rig == null) return;
    final centers = _restCenters ??= _computeRestCenters();
    final mats = rig.skinMatrices(_pose);
    centers.forEach((name, c) {
      final node = _nodes[name];
      if (node == null) return;
      if (!_posed) {
        node.localTransform = vm.Matrix4.identity();
        return;
      }
      final (point, joints, weights) = c;
      var ox = 0.0, oy = 0.0, oz = 0.0;
      final x = point.x, y = point.y, z = _flip ? -point.z : point.z;
      for (var k = 0; k < joints.length; k++) {
        final m = joints[k] * 12;
        final w = weights[k];
        ox +=
            w * (mats[m] * x + mats[m + 1] * y + mats[m + 2] * z + mats[m + 3]);
        oy +=
            w *
            (mats[m + 4] * x + mats[m + 5] * y + mats[m + 6] * z + mats[m + 7]);
        oz +=
            w *
            (mats[m + 8] * x +
                mats[m + 9] * y +
                mats[m + 10] * z +
                mats[m + 11]);
      }
      final posed = vm.Vector3(ox, oy, _flip ? -oz : oz);
      node.localTransform = vm.Matrix4.translation(posed - point);
    });
  }

  Map<String, (vm.Vector3, List<int>, List<double>)>? _restCenters;

  /// Centre de repos et influences moyennes de chaque maillage translucide.
  Map<String, (vm.Vector3, List<int>, List<double>)> _computeRestCenters() {
    final rig = this.rig!;
    final out = <String, (vm.Vector3, List<int>, List<double>)>{};
    _regions.forEach((name, _) {
      final region = map.byId[name];
      final data = _rest[name];
      final inf = rig.skin[name];
      if (region == null || region.couche == 'volume') return;
      if (data == null || inf == null) return;
      final b = _boundsOf(data.positions);
      if (b == null) return;
      final acc = <int, double>{};
      for (var i = 0; i < inf.joints.length; i++) {
        final w = inf.weights[i];
        if (w > 0) acc[inf.joints[i]] = (acc[inf.joints[i]] ?? 0) + w;
      }
      final total = acc.values.fold<double>(0, (a, b) => a + b);
      out[name] = (
        (b.$1 + b.$2) * .5,
        acc.keys.toList(),
        [for (final v in acc.values) v / total],
      );
    });
    return out;
  }

  /// Matériau du nœud et de ses descendants sans nom propre. Le maillage est
  /// d'abord cloné : les instances de `loadScene` partagent leurs primitives,
  /// chaque mannequin garde ainsi ses propres matériaux.
  void _assign(Node node, Material material) {
    final shared = node.mesh;
    if (shared != null) {
      final mesh = shared.clone();
      for (final p in mesh.primitives) {
        p.material = material;
      }
      node.mesh = mesh;
    }
    for (final c in node.children) {
      if (!_nodes.containsKey(c.name)) _assign(c, material);
    }
  }

  void _applyMaterials() {
    // 5.5.4 (M56 correction 4, décision du propriétaire du 29/09/2026) : le
    // maillage n'est plus coloré ; les muscles sollicités reçoivent un halo
    // dessiné par-dessus la vue (`MannequinHaloPainter`). Les matériaux
    // restent gris ; seule la visibilité des régions change.
    _regions.forEach((name, m) {
      final volume = map.byId[name]!.couche == 'volume';
      final a = volume ? 1.0 : opacity;
      m
        ..baseColorFactor = _lin(volume ? kDarkVolume : kMuscleGray, 1, a)
        ..emissiveFactor = vm.Vector4(0, 0, 0, 1)
        ..emissiveStrength = 0
        ..roughnessFactor = volume ? .85 : .78;
      _nodes[name]?.visible =
          !_hidden.contains(name) && !_forcedHidden.contains(name);
    });
    _nodes['os']?.visible = _bones;
    scene.postProcess.bloom.enabled = false;
  }

  /// 5.5.4 : régions à entourer d'un halo (intensité 0-1) et régions
  /// étirées, visibles, pour le dessin par-dessus la vue.
  Map<String, double> get haloIntensities => {
    for (final e in _intensities.entries)
      if (e.value > 0 &&
          _regions.containsKey(e.key) &&
          map.byId[e.key]!.couche != 'volume' &&
          !_hidden.contains(e.key) &&
          !_forcedHidden.contains(e.key))
        e.key: e.value.clamp(0.0, 1.0),
  };
  Set<String> get haloStretched => {
    for (final id in _stretched)
      if ((_intensities[id] ?? 0) <= 0 &&
          _regions.containsKey(id) &&
          !_hidden.contains(id) &&
          !_forcedHidden.contains(id))
        id,
  };

  /// Maillage au repos d'une région (halo).
  MeshData? restMesh(String name) => _rest[name];

  /// Sens direct des triangles = normale vers l'extérieur ? Mesuré sur le
  /// droit de l'abdomen (tourné vers l'avant du repère), une fois : le
  /// repère importé peut être le miroir de celui du glTF.
  late final bool windingOutward = _measureWinding();

  bool _measureWinding() {
    final m = _rest['rectus_abdominis_left'] ?? _rest.values.firstOrNull;
    if (m == null) return true;
    final p = m.positions;
    final idx = m.indices ?? List<int>.generate(m.vertexCount, (i) => i);
    final f = frame.front;
    var sum = 0.0;
    for (var t = 0; t + 2 < idx.length; t += 3) {
      final a = idx[t], b = idx[t + 1], c = idx[t + 2];
      final ax = p[a * 3], ay = p[a * 3 + 1], az = p[a * 3 + 2];
      final ux = p[b * 3] - ax, uy = p[b * 3 + 1] - ay, uz = p[b * 3 + 2] - az;
      final wx = p[c * 3] - ax, wy = p[c * 3 + 1] - ay, wz = p[c * 3 + 2] - az;
      sum +=
          (uy * wz - uz * wy) * f.x +
          (uz * wx - ux * wz) * f.y +
          (ux * wy - uy * wx) * f.z;
    }
    return sum >= 0;
  }

  /// Thème, intensités par région (0-1), régions étirées (M3), régions
  /// masquées (M4b, filtre « Muscles profonds »), os visibles, halo.
  void configure({
    required bool dark,
    required Map<String, double> intensities,
    Set<String> stretched = const {},
    Set<String> hidden = const {},
    required bool bones,
    required bool halo,
    Color? background,
  }) {
    // 5.5.4 : fond de la scène = couleur du support (carte, page), sans
    // démarcation.
    final bgColor = background ?? sceneBackground(dark);
    final themeChanged = _dark3d != dark || _background != bgColor;
    final accentChanged = _accent3d != SL.accentSpec;
    if (!themeChanged &&
        !accentChanged &&
        identical(intensities, _intensities) &&
        identical(stretched, _stretched) &&
        identical(hidden, _hidden) &&
        bones == _bones &&
        halo == _halo) {
      return;
    }
    _dark3d = dark;
    _background = bgColor;
    _accent3d = SL.accentSpec;
    _intensities = intensities;
    _stretched = stretched;
    _hidden = hidden;
    _bones = bones;
    _halo = halo;
    if (themeChanged) {
      final bg = _lin(bgColor).xyz;
      scene.skybox = Skybox(
        GradientSkySource(
          zenithColor: bg,
          horizonColor: bg.clone(),
          groundColor: bg.clone(),
          sunColor: vm.Vector3.zero(),
        ),
      );
    }
    _applyMaterials();
  }

  /// Direction du centre vers la caméra.
  vm.Vector3 _eyeDirection(double yaw, double pitch) {
    final f = frame.front, l = frame.left;
    return (f * math.cos(yaw) + l * math.sin(yaw)) * math.cos(pitch) +
        vm.Vector3(0, math.sin(pitch), 0);
  }

  /// Caméra en orbite autour du mannequin ; la lumière principale suit la
  /// caméra (en haut à gauche) pour que chaque vue soit lisible.
  ///
  /// M4c : [zoom] réduit l'angle de champ (la caméra ne s'approche pas du
  /// modèle : jamais de traversée) et décale le point visé ; la rotation
  /// tourne autour du point visé.
  PerspectiveCamera camera(
    double yaw,
    double pitch,
    double distance, {
    MannequinZoom? zoom,
  }) {
    final center = zoom == null ? target : target + zoom.offset;
    final eye = center + _eyeDirection(yaw, pitch) * distance;
    final forward = (center - eye)..normalize();
    final right = forward.cross(vm.Vector3(0, 1, 0))..normalize();
    final light = (forward + vm.Vector3(0, -.9, 0) + right * .45)..normalize();
    scene.directionalLight = DirectionalLight(direction: light, intensity: 2.3);
    return PerspectiveCamera(
      fovRadiansY: zoom?.fovY ?? kMannequinFovY,
      position: eye,
      target: center,
    );
  }

  /// Distance qui cadre le corps entier dans une vue de rapport [aspect].
  /// M5 : cadrage de la posture courante (au repos : celui de 5.3.2).
  double fitDistance(double aspect) {
    const fov = kMannequinFovY;
    final f = framing;
    final h = f.height * 1.08;
    final byHeight = h / 2 / math.tan(fov / 2);
    // Largeur utile : au repos ≈ 0,5 × hauteur (bras le long du corps, vue
    // 3/4) ; en posture, diagonale horizontale du corps déformé.
    final hFov = 2 * math.atan(math.tan(fov / 2) * aspect);
    final byWidth = f.width / 2 / math.tan(hFov / 2);
    return math.max(byHeight, byWidth) + .3;
  }

  List<PickMesh>? _pickables, _posedPickables;

  bool _pickable(String name) =>
      map.byId.containsKey(name) ||
      const {'os', 'contexte', 'head'}.contains(name);

  /// Maillages du toucher (régions et occultants : os, tête, contexte), en
  /// coordonnées du monde. M5 : sur le modèle déformé par la posture
  /// courante (peau calculée sur le processeur à la demande).
  List<PickMesh> get pickables {
    final rest = _pickables ??= [
      for (final e in _rest.entries)
        if (_nodes.containsKey(e.key) && _pickable(e.key))
          PickMesh.fromData(e.key, e.value),
    ];
    final rig = this.rig;
    if (!_posed || rig == null) return rest;
    return _posedPickables ??= () {
      final mats = rig.skinMatrices(_pose);
      return [
        for (final m in rest)
          PickMesh.fromPositions(m.name, _skinned(m.name, mats), m.indices),
      ];
    }();
  }

  /// Région touchée au point [position] d'une vue de taille [size].
  ///
  /// M4b (muscles translucides) : le rayon traverse les muscles jusqu'à la
  /// première surface opaque (os visibles, tête, contexte, main, pied). Parmi
  /// les régions traversées (et la main ou le pied qui l'arrête), il renvoie
  /// la plus proche des régions mises en évidence (sollicitées ou étirées)
  /// s'il y en a une, sinon la plus proche. Régions masquées ignorées.
  MuscleRegion? pick(Camera camera, Offset position, Size size) {
    final ray = camera.screenPointToRay(position, size);
    return pickRay(ray.origin, ray.direction.normalized());
  }

  /// [pick] pour un rayon d'origine [origin] et de direction unitaire [dir].
  MuscleRegion? pickRay(vm.Vector3 origin, vm.Vector3 dir) => pickAlong(
    origin,
    dir,
    pickables,
    map,
    intensities: _intensities,
    stretched: _stretched,
    hidden: {..._hidden, ..._forcedHidden},
    bones: _bones,
    opacity: opacity,
  );

  /// Règle du toucher, sans scène (tests).
  static MuscleRegion? pickAlong(
    vm.Vector3 origin,
    vm.Vector3 dir,
    Iterable<PickMesh> meshes,
    MannequinMap map, {
    Map<String, double> intensities = const {},
    Set<String> stretched = const {},
    Set<String> hidden = const {},
    bool bones = true,
    double opacity = kMuscleOpacity,
  }) {
    // Surface opaque la plus proche : elle arrête le rayon.
    var stop = double.infinity;
    String? stopName;
    final crossed = <String, double>{};
    for (final m in meshes) {
      if (m.name == 'os' && !bones) continue;
      if (hidden.contains(m.name)) continue;
      final region = map.byId[m.name];
      final opaque =
          region == null || region.couche == 'volume' || opacity >= 1;
      final t = m.intersect(origin, dir, opaque ? stop : double.infinity);
      if (t == null) continue;
      if (opaque) {
        if (t < stop) {
          stop = t;
          stopName = m.name;
        }
      } else {
        crossed[m.name] = t;
      }
    }
    final candidates = <String, double>{
      for (final e in crossed.entries)
        if (e.value < stop) e.key: e.value,
      if (stopName != null && map.byId.containsKey(stopName)) stopName: stop,
    };
    String? nearestOf(Iterable<String> ids) {
      String? best;
      var d = double.infinity;
      for (final id in ids) {
        final t = candidates[id]!;
        if (t < d) {
          d = t;
          best = id;
        }
      }
      return best;
    }

    final lit = nearestOf(
      candidates.keys.where(
        (id) => (intensities[id] ?? 0) > 0 || stretched.contains(id),
      ),
    );
    final best = lit ?? nearestOf(candidates.keys);
    return best == null ? null : map.byId[best];
  }
}

/// Maillage d'un nœud en coordonnées du monde, pour le toucher : test des
/// triangles (Möller-Trumbore) après une boîte englobante.
class PickMesh {
  final String name;
  final Float32List positions;
  final List<int> indices;
  final vm.Vector3 min, max;

  PickMesh(this.name, this.positions, this.indices, this.min, this.max);

  factory PickMesh.of(String name, Node node) => PickMesh.fromData(
    name,
    node.extractMeshData(transform: node.globalTransform),
  );

  factory PickMesh.fromData(String name, MeshData data) =>
      PickMesh.fromPositions(
        name,
        data.positions,
        data.indices ?? List<int>.generate(data.vertexCount, (i) => i),
      );

  factory PickMesh.fromPositions(String name, Float32List p, List<int> idx) {
    final lo = vm.Vector3.all(double.infinity);
    final hi = vm.Vector3.all(-double.infinity);
    for (var i = 0; i + 2 < p.length; i += 3) {
      lo.x = math.min(lo.x, p[i]);
      lo.y = math.min(lo.y, p[i + 1]);
      lo.z = math.min(lo.z, p[i + 2]);
      hi.x = math.max(hi.x, p[i]);
      hi.y = math.max(hi.y, p[i + 1]);
      hi.z = math.max(hi.z, p[i + 2]);
    }
    return PickMesh(name, p, idx, lo, hi);
  }

  bool _hitsBox(vm.Vector3 o, vm.Vector3 d, double limit) {
    var t0 = 0.0, t1 = limit;
    for (var k = 0; k < 3; k++) {
      final inv = 1 / d[k];
      var a = (min[k] - o[k]) * inv, b = (max[k] - o[k]) * inv;
      if (a > b) {
        final s = a;
        a = b;
        b = s;
      }
      t0 = math.max(t0, a);
      t1 = math.min(t1, b);
      if (t0 > t1) return false;
    }
    return true;
  }

  /// Distance du premier triangle touché le long de [d] (unitaire), ou null.
  double? intersect(vm.Vector3 o, vm.Vector3 d, [double limit = 1e9]) {
    if (!_hitsBox(o, d, limit)) return null;
    double? best;
    final p = positions;
    for (var i = 0; i + 2 < indices.length; i += 3) {
      final a = indices[i] * 3, b = indices[i + 1] * 3, c = indices[i + 2] * 3;
      final e1x = p[b] - p[a], e1y = p[b + 1] - p[a + 1];
      final e1z = p[b + 2] - p[a + 2];
      final e2x = p[c] - p[a], e2y = p[c + 1] - p[a + 1];
      final e2z = p[c + 2] - p[a + 2];
      final px = d.y * e2z - d.z * e2y;
      final py = d.z * e2x - d.x * e2z;
      final pz = d.x * e2y - d.y * e2x;
      final det = e1x * px + e1y * py + e1z * pz;
      if (det.abs() < 1e-12) continue;
      final inv = 1 / det;
      final tx = o.x - p[a], ty = o.y - p[a + 1], tz = o.z - p[a + 2];
      final u = (tx * px + ty * py + tz * pz) * inv;
      if (u < 0 || u > 1) continue;
      final qx = ty * e1z - tz * e1y;
      final qy = tz * e1x - tx * e1z;
      final qz = tx * e1y - ty * e1x;
      final v = (d.x * qx + d.y * qy + d.z * qz) * inv;
      if (v < 0 || u + v > 1) continue;
      final t = (e2x * qx + e2y * qy + e2z * qz) * inv;
      if (t > 1e-6 && t < limit && (best == null || t < best)) best = t;
    }
    return best;
  }
}

// ------------------------------------------------------------------ widget --

/// Mannequin anatomique 3D : vues Face / Dos / Profil / 3/4 avec transition,
/// rotation au doigt, intensités par région, nom du muscle au toucher.
/// Sans Flutter GPU : carte 2D historique ([MuscleHeatmap]).
class Mannequin3D extends StatefulWidget {
  /// Intensité (0-1) par id de région (`muscles_map.json`).
  final Map<String, double> intensities;

  /// Régions étirées (M3, fiche exercice) : teinte [mannequinStretch], si la
  /// région n'est pas déjà sollicitée.
  final Set<String> stretched;

  /// Régions masquées (M4b, écran Anatomie : filtre « Muscles profonds »).
  final Set<String> hidden;

  /// Os visibles imposés par l'écran (M4b, filtre « Os » de l'écran
  /// Anatomie) ; null : réglage « Os visibles ».
  final bool? bones;

  /// Repli sans Flutter GPU à la place de la carte 2D par groupes (M3 : la
  /// fiche exercice garde sa carte historique, `ExerciseAtlas`).
  final Widget? fallback;

  /// Rotation au doigt seulement horizontale (M3 : dans une page qui défile,
  /// le glissement vertical fait défiler la page au lieu d'incliner la vue).
  final bool horizontalDragOnly;

  /// Vue de départ (et vue imposée quand elle change).
  final MannequinView view;

  /// Boutons Face / Dos / Profil / 3/4 sous la vue.
  final bool viewButtons;

  /// 5.5.3 : gestes (toucher, zoom) ; false pour un mannequin de carte.
  final bool interactive;

  /// 5.5.4 : couleur du support (carte, page) : fond de la scène et du repli
  /// 2D, sans démarcation. Null : couleur des cartes du thème.
  final Color? background;

  /// Vues proposées par les boutons (M4, STATS : bascule Face / Dos).
  final List<MannequinView> views;

  /// Rotation continue lente (écran « Moteur 3D », mesure de fluidité).
  final bool spin;

  /// Hauteur de la vue.
  final double height;

  /// Appelé à chaque région touchée (null : aucune).
  final ValueChanged<MuscleRegion?>? onRegionTap;

  /// Libellé d'accessibilité de la vue.
  final String semanticLabel;

  /// Appelé une fois : true quand le mannequin 3D est prêt, false en repli
  /// 2D (téléphone incompatible ou modèle illisible).
  final ValueChanged<bool>? onReady;

  /// M5 : posture du mannequin (clé de `rig.json`, par exemple `squat_bas`) ;
  /// null : repos. Un changement passe par une transition douce (instantanée
  /// si les animations sont réduites).
  final String? posture;

  const Mannequin3D({
    super.key,
    this.intensities = const {},
    this.stretched = const {},
    this.hidden = const {},
    this.bones,
    this.fallback,
    this.horizontalDragOnly = false,
    this.view = MannequinView.face,
    this.viewButtons = true,
    this.interactive = true,
    this.background,
    this.views = MannequinView.values,
    this.spin = false,
    this.height = 420,
    this.onRegionTap,
    this.semanticLabel = 'Mannequin anatomique en 3D',
    this.onReady,
    this.posture,
  });

  @override
  State<Mannequin3D> createState() => Mannequin3DState();
}

class Mannequin3DState extends State<Mannequin3D>
    with TickerProviderStateMixin {
  MannequinScene? _scene;
  bool? _available;
  final _settings = Display3DSettings.instance;

  late MannequinView _view = widget.view;

  double _yaw = 0, _pitch = .06;
  double _fromYaw = 0, _fromPitch = 0, _toYaw = 0, _toPitch = 0;
  late final AnimationController _tween = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..addListener(_onTween);
  MuscleRegion? _touched;
  PerspectiveCamera? _camera;

  // M5 : transition entre deux postures.
  late final AnimationController _poseTween = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  )..addListener(_onPoseTween);
  RigPose _fromPose = RigPose.rest, _toPose = RigPose.rest;
  MannequinFraming? _fromFraming, _toFraming;
  String? _posture;

  /// Posture affichée (clé de `rig.json`, null : repos) et transition en
  /// cours (tests).
  String? get posture => _posture;
  bool get posing => _poseTween.isAnimating;
  Size _size = Size.zero;

  // M4c : zoom au pincement (1× corps entier à 4×) et déplacement.
  MannequinZoom _zoom = MannequinZoom();
  MannequinZoom _fromZoom = MannequinZoom();
  MannequinZoom _pinchStart = MannequinZoom();
  Offset _pinchFocal = Offset.zero;

  /// Zoom courant (tests).
  MannequinZoom get zoom => _zoom;

  /// Scène chargée (tests d'intégration et captures).
  MannequinScene? get scene => _scene;
  bool? get available => _available;
  MannequinView get view => _view;
  MuscleRegion? get touched => _touched;

  /// Caméra et taille de la vue au dernier rendu (tests d'intégration :
  /// point de l'écran où se trouve un muscle).
  PerspectiveCamera? get camera => _camera;
  Size get viewSize => _size;

  // M56 : mesure de l'ouverture (temps jusqu'à la première image, images
  // perdues), lue dans Réglages › À propos › Moteur 3D.
  OpenTimer? _openTimer;
  bool _firstImage = false;

  @override
  void initState() {
    super.initState();
    _yaw = _toYaw = widget.view.yaw;
    _settings.listenable.addListener(_onSettings);
    unawaited(_settings.load());
    _openTimer = OpenTimer();
    // Téléphone déjà reconnu incompatible et carte chargée : repli 2D
    // immédiat, sans attente.
    final known = engine3DSupportKnown;
    if (known != null &&
        !known.compatible &&
        (widget.fallback != null || MannequinMap.loaded != null)) {
      _map = MannequinMap.loaded;
      _available = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onReady?.call(false);
      });
      return;
    }
    unawaited(_init());
  }

  MannequinMap? _map;

  Future<void> _init() async {
    final support = await engine3DSupport();
    if (!support.compatible) {
      // Repli 2D : la carte des régions donne les groupes à colorer (inutile
      // quand l'écran fournit son propre repli).
      MannequinMap? map;
      if (widget.fallback == null) {
        try {
          map = await MannequinMap.load();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _map = map;
          _available = false;
        });
      }
      widget.onReady?.call(false);
      return;
    }
    MannequinScene? scene;
    try {
      scene = await MannequinScene.create();
    } catch (_) {
      scene = null;
    }
    if (!mounted) return;
    if (scene != null && widget.posture != null) {
      _posture = widget.posture;
      final pose = _poseOf(scene, widget.posture);
      scene.applyPose(pose);
      scene.framing = scene.framingFor(pose);
    }
    setState(() {
      _scene = scene;
      _available = scene != null;
    });
    widget.onReady?.call(scene != null);
  }

  RigPose _poseOf(MannequinScene scene, String? key) => key == null
      ? RigPose.rest
      : scene.rig?.posture(key)?.pose ?? RigPose.rest;

  /// Passe à la posture [key] (null : repos) avec une transition.
  void setPosture(String? key) {
    final scene = _scene;
    _posture = key;
    if (scene == null || scene.rig == null) return;
    _poseTween.stop();
    _fromPose = scene.pose;
    _toPose = _poseOf(scene, key);
    _fromFraming = scene.framing;
    _toFraming = scene.framingFor(_toPose);
    // Nouveau cadrage : vue d'ensemble (zoom 1×).
    _zoom = MannequinZoom();
    _touched = null;
    if (!mounted) return;
    if (_reduceMotion) {
      scene.applyPose(_toPose);
      scene.framing = _toFraming!;
      setState(() {});
    } else {
      _poseTween.forward(from: 0);
    }
  }

  void _onPoseTween() {
    final scene = _scene;
    final rig = scene?.rig;
    if (scene == null || rig == null) return;
    final t = Curves.easeInOutCubic.transform(_poseTween.value);
    setState(() {
      scene.applyPose(t >= 1 ? _toPose : rig.blend(_fromPose, _toPose, t));
      scene.framing = MannequinFraming.lerp(_fromFraming!, _toFraming!, t);
    });
  }

  @override
  void didUpdateWidget(Mannequin3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view != widget.view) setView(widget.view);
    if (oldWidget.posture != widget.posture) setPosture(widget.posture);
  }

  @override
  void dispose() {
    _openTimer?.cancel();
    _settings.listenable.removeListener(_onSettings);
    _tween.dispose();
    _poseTween.dispose();
    super.dispose();
  }

  void _onSettings() {
    if (!mounted) return;
    setState(() {
      if (!_settings.touchNames.value) _touched = null;
    });
  }

  bool get _reduceMotion => MediaQuery.of(context).disableAnimations;

  /// Change de vue avec une transition (instantanée si les animations sont
  /// réduites), par le plus court chemin autour du mannequin.
  void setView(MannequinView view) {
    _view = view;
    var delta = (view.yaw - _yaw) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    _fromYaw = _yaw;
    _fromPitch = _pitch;
    _toYaw = _yaw + delta;
    _toPitch = .06;
    // M4c : les boutons de vue remettent aussi le zoom par défaut.
    _fromZoom = _zoom.copy();
    if (!mounted) return;
    if (_reduceMotion) {
      setState(() {
        _yaw = _toYaw;
        _pitch = _toPitch;
        _zoom = MannequinZoom();
      });
    } else {
      _tween.forward(from: 0);
      setState(() {});
    }
  }

  void _onTween() {
    final t = Curves.easeOutCubic.transform(_tween.value);
    setState(() {
      _yaw = _fromYaw + (_toYaw - _fromYaw) * t;
      _pitch = _fromPitch + (_toPitch - _fromPitch) * t;
      _zoom = t >= 1
          ? MannequinZoom()
          : MannequinZoom.lerp(_fromZoom, MannequinZoom(), t);
    });
  }

  void _onTick(Duration elapsed, double dt) {
    if (!widget.spin || _reduceMotion || dt <= 0 || _dragging) return;
    _yaw += math.min(dt, .1) * .45;
  }

  bool _dragging = false;

  void _startDrag() {
    _tween.stop();
    _dragging = true;
  }

  Camera _cameraFor(Duration _) {
    final scene = _scene!;
    return _camera = scene.camera(
      _yaw,
      _pitch,
      scene.fitDistance(_aspect),
      zoom: _zoom,
    );
  }

  /// Double toucher : retour à la vue par défaut (même vue, zoom 1×).
  void resetZoom() {
    if (_zoom.isDefault) return;
    _tween.stop();
    _fromYaw = _toYaw = _yaw;
    _fromPitch = _toPitch = _pitch;
    _fromZoom = _zoom.copy();
    if (_reduceMotion) {
      setState(() => _zoom = MannequinZoom());
    } else {
      _tween.forward(from: 0);
    }
  }

  /// Pincement : zoom centré sur [focal] à l'échelle [scale] (bornée), puis
  /// déplacement de la vue de [pan] pixels (tests et gestes).
  void pinchTo(double scale, Offset focal, {Offset pan = Offset.zero}) {
    final scene = _scene;
    if (scene == null || _size.isEmpty) return;
    final (right, up) = _screenAxes(scene);
    final distance = scene.fitDistance(_aspect);
    setState(() {
      if (pan != Offset.zero) _zoom.pan(pan, _size, right, up, distance);
      _zoom.zoomAt(scale, focal, _size, right, up, distance);
    });
  }

  /// Directions du monde qui vont vers la droite et vers le haut de l'écran,
  /// mesurées avec la caméra elle-même (mêmes rayons que le toucher) : le
  /// repère de flutter_scene est miroir de `forward × haut` (essai 1 de M4c :
  /// le zoom partait vers l'autre avant-bras).
  (vm.Vector3, vm.Vector3) _screenAxes(MannequinScene scene) {
    final camera = scene.camera(_yaw, _pitch, scene.fitDistance(_aspect));
    final c = _size.center(Offset.zero);
    vm.Vector3 dir(Offset p) =>
        camera.screenPointToRay(p, _size).direction.normalized();
    final o = dir(c);
    final right = (dir(c + const Offset(8, 0)) - o)..normalize();
    final up = (dir(c - const Offset(0, 8)) - o)..normalize();
    return (right, up);
  }

  void _onPinchStart(ScaleStartDetails d) {
    _startDrag();
    _pinchStart = _zoom.copy();
    _pinchFocal = d.localFocalPoint;
    final scene = _scene;
    if (scene == null || _size.isEmpty) return;
    // Point du monde sous les doigts au premier contact, dans le plan
    // perpendiculaire à l'axe de la caméra qui passe par le point visé.
    final camera = scene.camera(
      _yaw,
      _pitch,
      scene.fitDistance(_aspect),
      zoom: _pinchStart,
    );
    _pinchNormal = camera
        .screenPointToRay(_size.center(Offset.zero), _size)
        .direction
        .normalized();
    _pinchPlane = scene.target + _pinchStart.offset;
    _pinchWorld = _onPlane(camera, _pinchFocal);
  }

  vm.Vector3 _pinchNormal = vm.Vector3(0, 0, 1);
  vm.Vector3 _pinchPlane = vm.Vector3.zero();
  vm.Vector3 _pinchWorld = vm.Vector3.zero();

  /// Point du plan du pincement sous le point [p] de la vue, pour [camera].
  vm.Vector3 _onPlane(Camera camera, Offset p) {
    final ray = camera.screenPointToRay(p, _size);
    final dir = ray.direction.normalized();
    final t =
        (_pinchPlane - ray.origin).dot(_pinchNormal) / dir.dot(_pinchNormal);
    return ray.origin + dir * t;
  }

  /// Chaque image du pincement est calculée depuis son début : le point
  /// visé au premier contact reste sous les doigts (essai 5 de M4c : en
  /// cumulant pas à pas, les bornes du début du geste le décalaient). Le
  /// modèle (`MannequinZoom.pinched`) est ensuite vérifié et ajusté avec les
  /// rayons de la caméra elle-même (mêmes rayons que le toucher).
  void _onPinchUpdate(ScaleUpdateDetails d) {
    final scene = _scene;
    if (d.pointerCount < 2 || scene == null || _size.isEmpty) return;
    final (right, up) = _screenAxes(scene);
    final distance = scene.fitDistance(_aspect);
    final z = MannequinZoom.pinched(
      _pinchStart,
      _pinchFocal,
      d.localFocalPoint,
      _pinchStart.scale * d.scale,
      _size,
      right,
      up,
      distance,
    );
    for (var i = 0; i < 2; i++) {
      final camera = scene.camera(_yaw, _pitch, distance, zoom: z);
      z.offset += _pinchWorld - _onPlane(camera, d.localFocalPoint);
    }
    z.clampTo(_size, right, up, distance);
    setState(() => _zoom = z);
  }

  double get _aspect =>
      _size.height == 0 ? .75 : _size.width / math.max(1, _size.height);

  void _onTap(TapUpDetails d) {
    final scene = _scene, camera = _camera;
    if (scene == null || camera == null || _size.isEmpty) return;
    final region = scene.pick(camera, d.localPosition, _size);
    widget.onRegionTap?.call(region);
    if (!_settings.touchNames.value) return;
    setState(() => _touched = region);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final available = _available;
    Widget view;
    if (available == false) {
      _openTimer?.cancel();
      view = widget.fallback ?? _fallback(context);
    } else if (_scene == null) {
      view = SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    } else {
      view = _view3d(context, dark);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        view,
        if (widget.viewButtons && available != false) ...[
          const SizedBox(height: 8),
          _viewButtons(context),
        ],
      ],
    );
  }

  Widget _fallback(BuildContext context) {
    final groups = _map?.groupsOf(widget.intensities) ?? const {};
    return Semantics(
      label: '${widget.semanticLabel} (illustration 2D)',
      child: ClipRRect(
        key: const ValueKey('mannequin-fallback'),
        borderRadius: BorderRadius.circular(KSpace.radius),
        child: ColoredBox(
          color: _background(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: MuscleHeatmap(
              data: groups,
              height: widget.height - 24,
              normalize: false,
              glow: _settings.halo.value,
            ),
          ),
        ),
      ),
    );
  }

  /// 5.5.4 : fond = couleur du support.
  Color _background(BuildContext context) =>
      widget.background ?? Theme.of(context).colorScheme.surfaceContainerLow;

  /// Fond de la vue (tests d'intégration : pixels du fond).
  Color get backgroundColor => _background(context);

  Widget _view3d(BuildContext context, bool dark) {
    final scene = _scene!;
    if (!_firstImage) {
      _firstImage = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTimer?.firstImage();
      });
    }
    scene.configure(
      dark: dark,
      intensities: widget.intensities,
      stretched: widget.stretched,
      hidden: widget.hidden,
      bones: widget.bones ?? _settings.bones.value,
      halo: _settings.halo.value,
      background: _background(context),
    );
    final touched = _touched;
    return ClipRRect(
      borderRadius: BorderRadius.circular(KSpace.radius),
      child: ColoredBox(
        color: _background(context),
        child: SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _size = constraints.biggest;
              _camera = scene.camera(
                _yaw,
                _pitch,
                scene.fitDistance(_aspect),
                zoom: _zoom,
              );
              return Stack(
                children: [
                  Positioned.fill(
                    // 5.5.3 : mannequin d'une carte (accueil) : aucun geste,
                    // le toucher va à la carte.
                    child: MannequinGestures(
                      key: const ValueKey('mannequin-view'),
                      enabled: widget.interactive,
                      horizontalOnly: widget.horizontalDragOnly,
                      onTapUp: _onTap,
                      // Reconnu seulement une fois zoomé : le toucher bref
                      // (nom du muscle) n'attend pas un second toucher.
                      onDoubleTap: _zoom.isDefault ? null : resetZoom,
                      // 5.5.3 (décision du propriétaire, 29/09/2026) : plus
                      // de rotation au doigt, les boutons de vue suffisent
                      // (le zoom au pincement reste).
                      onPinchStart: _onPinchStart,
                      onPinchUpdate: _onPinchUpdate,
                      onPinchEnd: (_) => _dragging = false,
                      child: Semantics(
                        label:
                            '${widget.semanticLabel}. Pince pour zoomer'
                            '${_zoom.isDefault ? '' : ', touche deux fois pour revenir à la vue d’ensemble'}.',
                        child: SceneView(
                          scene.scene,
                          // Rendu à la demande : la vue se redessine quand ce
                          // widget se reconstruit (caméra, intensités,
                          // réglages). flutter_scene 0.23 ne permet pas de
                          // basculer autoTick sur une vue montée : la clé
                          // remonte la vue si `spin` change.
                          key: ValueKey('scene-${widget.spin}'),
                          autoTick: widget.spin,
                          onTick: widget.spin ? _onTick : null,
                          // En rotation continue, la caméra est recalculée à
                          // chaque image ; sinon, à chaque reconstruction.
                          camera: widget.spin ? null : _camera,
                          cameraBuilder: widget.spin ? _cameraFor : null,
                        ),
                      ),
                    ),
                  ),
                  // 5.5.4 : halo des muscles sollicités, par-dessus la vue.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        key: const ValueKey('mannequin-halo'),
                        // Rotation continue (Moteur 3D) : caméra par image,
                        // pas de halo.
                        painter: widget.spin
                            ? null
                            : MannequinHaloPainter(
                                scene: scene,
                                camera: _camera!,
                                size: _size,
                                dark: dark,
                                soft: _settings.halo.value,
                              ),
                      ),
                    ),
                  ),
                  if (touched != null)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: _Bubble(
                          key: const ValueKey('mannequin-bubble'),
                          text: touched.label,
                          dark: dark,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _viewButtons(BuildContext context) => SegmentedButton<MannequinView>(
    key: const ValueKey('mannequin-views'),
    expandedInsets: EdgeInsets.zero,
    showSelectedIcon: false,
    segments: [
      for (final v in widget.views)
        ButtonSegment(
          value: v,
          label: Text(v.label, key: ValueKey('mannequin-view-${v.name}')),
        ),
    ],
    // Vue hors des boutons proposés : aucun bouton sélectionné.
    selected: {if (widget.views.contains(_view)) _view},
    emptySelectionAllowed: !widget.views.contains(_view),
    onSelectionChanged: (s) {
      if (s.isNotEmpty) setView(s.single);
    },
  );
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool dark;
  const _Bubble({super.key, required this.text, required this.dark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: (dark ? KPalette.charcoal : Colors.white).withValues(alpha: .9),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: SL.line),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: dark ? KPalette.light : null),
    ),
  );
}
