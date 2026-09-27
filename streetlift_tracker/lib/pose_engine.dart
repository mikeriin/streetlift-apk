// Moteur des démonstrations animées (L9b, KT-080) : portage exact du moteur de
// référence du pack de contenu (renderer_reference/kt_pose.js 2.0.0).
//
// Repère : unité = taille du personnage, y vers le haut, sol en y = 0 ; profil :
// le personnage regarde vers +x ; face : +x = côté gauche du personnage.
// Angles ABSOLUS de segment en degrés (voir kt_pose.js). Aucune dépendance à
// l'interface : fonctions pures, testées contre les positions du pack.
import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Longueurs segmentaires (Drillis & Contini), fractions de la taille.
class PoseLengths {
  static const tronc = 0.288,
      cou = 0.110,
      bras = 0.186,
      avantBras = 0.146,
      main = 0.108,
      prise = 0.050,
      cuisse = 0.245,
      jambe = 0.246,
      piedTalon = 0.045,
      piedPointe = 0.107,
      piedHauteur = 0.039,
      demiEpaulesFace = 0.130,
      demiBassinFace = 0.095;
}

const poseHeadRadius = 0.065;

/// Épaisseurs des capsules (début, fin).
const poseWidths = <String, (double, double)>{
  'bras': (0.052, 0.040),
  'avant_bras': (0.040, 0.028),
  'main': (0.026, 0.020),
  'cuisse': (0.082, 0.052),
  'jambe': (0.054, 0.030),
  'cou': (0.045, 0.045),
};

const poseAngleKeys = [
  't',
  'n',
  'p',
  'ua_g',
  'fa_g',
  'ha_g',
  'th_g',
  'sh_g',
  'ft_g',
  'ua_d',
  'fa_d',
  'ha_d',
  'th_d',
  'sh_d',
  'ft_d',
];

const _rad = math.pi / 180;

Offset _down(double th, double l) =>
    Offset(math.sin(th * _rad) * l, -math.cos(th * _rad) * l);
Offset _up(double th, double l) =>
    Offset(math.sin(th * _rad) * l, math.cos(th * _rad) * l);
Offset _norm(Offset a) {
  var l = math.sqrt(a.dx * a.dx + a.dy * a.dy);
  if (l == 0) l = 1;
  return Offset(a.dx / l, a.dy / l);
}

/// Rotation de +90° (sens trigonométrique, y vers le haut).
Offset _perp(Offset a) => Offset(-a.dy, a.dx);

typedef Joints = Map<String, Offset>;

/// Ancrage d'une image clé : articulation maintenue à une position.
class PoseAnchor {
  final String joint;
  final Offset pos;
  const PoseAnchor(this.joint, this.pos);
}

class PoseKeyframe {
  final String label;
  final Map<String, double> angles;
  final Offset pelvis;
  final PoseAnchor anchor;
  final double? hold, dur;
  const PoseKeyframe({
    required this.label,
    required this.angles,
    required this.pelvis,
    required this.anchor,
    this.hold,
    this.dur,
  });

  factory PoseKeyframe.fromJson(Map<String, dynamic> j) {
    final a = j['anchor'] as Map<String, dynamic>;
    return PoseKeyframe(
      label: j['label'] as String? ?? '',
      angles: {
        for (final e in (j['angles'] as Map<String, dynamic>).entries)
          e.key: (e.value as num).toDouble(),
      },
      pelvis: _offset(j['bassin']),
      anchor: PoseAnchor(a['joint'] as String, _offset(a['pos'])),
      hold: (j['hold'] as num?)?.toDouble(),
      dur: (j['dur'] as num?)?.toDouble(),
    );
  }
}

Offset _offset(Object? v) {
  final l = v as List;
  return Offset((l[0] as num).toDouble(), (l[1] as num).toDouble());
}

/// Accessoire (données brutes du pack : type, static, attach, between…).
class PoseProp {
  final Map<String, dynamic> raw;
  const PoseProp(this.raw);
  String get type => raw['type'] as String? ?? '';
  bool get isStatic => raw['static'] == true;
  bool get behind => raw['layer'] == 'arriere';
  double num(String k, [double fallback = 0]) =>
      (raw[k] as num?)?.toDouble() ?? fallback;
  double? opt(String k) => (raw[k] as num?)?.toDouble();
  List<String> get to => [for (final j in (raw['to'] as List? ?? [])) '$j'];
  List<String>? get between =>
      raw['between'] == null
          ? null
          : [for (final j in raw['between'] as List) '$j'];
  String? get attach => raw['attach'] as String?;
  Offset get offset =>
      raw['offset'] == null ? Offset.zero : _offset(raw['offset']);
}

/// Pose prête à jouer (équivalent de `fromPack` du moteur de référence).
class PoseAnimation {
  final String view;
  final String loop;
  final List<PoseKeyframe> keyframes;
  final List<PoseProp> props;
  final List<String> primaires, secondaires;
  final String statut;
  const PoseAnimation({
    required this.view,
    required this.loop,
    required this.keyframes,
    required this.props,
    this.primaires = const [],
    this.secondaires = const [],
    this.statut = 'disponible',
  });

  /// [gabarit] = poses.gabarits[nom] ; [entree] = poses.exercices[id].
  factory PoseAnimation.fromPack(
    Map<String, dynamic> gabarit, [
    Map<String, dynamic>? entree,
  ]) {
    final retirer = [for (final t in (entree?['retirer'] as List? ?? [])) '$t'];
    final base = [
      for (final p in (gabarit['accessoires'] as List? ?? []))
        if (!retirer.contains((p as Map)['type']))
          PoseProp(Map<String, dynamic>.from(p)),
    ];
    final muscles = (entree?['muscles'] as Map?) ?? const {};
    return PoseAnimation(
      view: gabarit['vue'] as String? ?? 'profil',
      loop: gabarit['boucle'] as String? ?? 'aller-retour',
      keyframes: [
        for (final k in gabarit['images_cles'] as List)
          PoseKeyframe.fromJson(Map<String, dynamic>.from(k as Map)),
      ],
      props: [
        ...base,
        for (final p in (entree?['accessoires'] as List? ?? []))
          PoseProp(Map<String, dynamic>.from(p as Map)),
      ],
      primaires: [for (final m in (muscles['primaires'] as List? ?? [])) '$m'],
      secondaires: [
        for (final m in (muscles['secondaires'] as List? ?? [])) '$m',
      ],
      statut: entree?['statut'] as String? ?? 'disponible',
    );
  }

  bool get isFace => view == 'face';
}

/// Cinématique directe depuis le bassin.
Joints poseFk(Map<String, double> ang, String view, [Offset? pelvis]) {
  final a = <String, double>{
    for (final k in poseAngleKeys) k: ang[k] ?? 0,
  };
  if (!ang.containsKey('n')) a['n'] = a['t']!;
  if (!ang.containsKey('p')) a['p'] = a['t']!;
  final p0 = pelvis ?? Offset.zero;
  final j = <String, Offset>{'bassin': p0};
  j['cou'] = p0 + _up(a['t']!, PoseLengths.tronc);
  j['tete'] = j['cou']! + _up(a['n']!, PoseLengths.cou);
  if (view == 'face') {
    final px = math.cos(a['t']! * _rad), py = -math.sin(a['t']! * _rad);
    final c = j['cou']!;
    j['epaule_g'] = Offset(
      c.dx + px * PoseLengths.demiEpaulesFace,
      c.dy + py * PoseLengths.demiEpaulesFace,
    );
    j['epaule_d'] = Offset(
      c.dx - px * PoseLengths.demiEpaulesFace,
      c.dy - py * PoseLengths.demiEpaulesFace,
    );
    final qx = math.cos(a['p']! * _rad), qy = -math.sin(a['p']! * _rad);
    j['hanche_g'] = Offset(
      p0.dx + qx * PoseLengths.demiBassinFace,
      p0.dy + qy * PoseLengths.demiBassinFace,
    );
    j['hanche_d'] = Offset(
      p0.dx - qx * PoseLengths.demiBassinFace,
      p0.dy - qy * PoseLengths.demiBassinFace,
    );
  } else {
    j['epaule_g'] = j['epaule_d'] = j['cou']!;
    j['hanche_g'] = j['hanche_d'] = p0;
  }
  for (final s in const ['g', 'd']) {
    j['coude_$s'] = j['epaule_$s']! + _down(a['ua_$s']!, PoseLengths.bras);
    j['poignet_$s'] =
        j['coude_$s']! + _down(a['fa_$s']!, PoseLengths.avantBras);
    j['main_$s'] = j['poignet_$s']! + _down(a['ha_$s']!, PoseLengths.main);
    j['prise_$s'] = j['poignet_$s']! + _down(a['ha_$s']!, PoseLengths.prise);
    j['genou_$s'] = j['hanche_$s']! + _down(a['th_$s']!, PoseLengths.cuisse);
    j['cheville_$s'] = j['genou_$s']! + _down(a['sh_$s']!, PoseLengths.jambe);
    if (view == 'face') {
      j['pied_$s'] =
          j['cheville_$s']! + _down(a['sh_$s']!, PoseLengths.piedHauteur);
      j['talon_$s'] = j['cheville_$s']!;
    } else {
      final sole = _down(a['ft_$s']!, 1);
      final pp = Offset(sole.dy, -sole.dx); // normale de la plante, vers le bas
      final base = j['cheville_$s']! + pp * PoseLengths.piedHauteur;
      j['talon_$s'] = base - sole * PoseLengths.piedTalon;
      j['pied_$s'] = base + sole * PoseLengths.piedPointe;
    }
  }
  return j;
}

Joints _translate(Joints j, double dx, double dy) => {
  for (final e in j.entries) e.key: Offset(e.value.dx + dx, e.value.dy + dy),
};

/// Courbe d'accélération : v = (1 − cos πu) / 2.
double poseEase(double u) => (1 - math.cos(math.pi * u)) / 2;

bool _sameAnchor(PoseKeyframe a, PoseKeyframe b) =>
    a.anchor.joint == b.anchor.joint &&
    (a.anchor.pos.dx - b.anchor.pos.dx).abs() < 1e-6 &&
    (a.anchor.pos.dy - b.anchor.pos.dy).abs() < 1e-6;

/// Position d'une image clé (ancrage respecté).
Joints poseOf(PoseKeyframe kf, String view) {
  final j = poseFk(kf.angles, view);
  final an = j[kf.anchor.joint]!;
  return _translate(j, kf.anchor.pos.dx - an.dx, kf.anchor.pos.dy - an.dy);
}

double _angleOr(PoseKeyframe k, String key) =>
    k.angles[key] ?? (key == 'n' || key == 'p' ? (k.angles['t'] ?? 0) : 0);

/// Interpolation A → B, u ∈ [0, 1] (angles linéaires sans repli modulo 360).
Joints poseInterp(PoseKeyframe a, PoseKeyframe b, double u, String view) {
  final v = poseEase(u);
  final ang = <String, double>{
    for (final k in poseAngleKeys)
      k: _angleOr(a, k) + (_angleOr(b, k) - _angleOr(a, k)) * v,
  };
  if (_sameAnchor(a, b)) {
    final j = poseFk(ang, view);
    final an = j[a.anchor.joint]!;
    return _translate(j, a.anchor.pos.dx - an.dx, a.anchor.pos.dy - an.dy);
  }
  final p = Offset(
    a.pelvis.dx + (b.pelvis.dx - a.pelvis.dx) * v,
    a.pelvis.dy + (b.pelvis.dy - a.pelvis.dy) * v,
  );
  return poseFk(ang, view, p);
}

class PoseStep {
  final int a, b;
  final double hold, dur;
  const PoseStep(this.a, this.b, this.hold, this.dur);
}

/// Chronologie : image i tenue `hold` puis transition `dur` ; boucle
/// « aller-retour » (0→…→n→…→0) ou « cycle » (0→…→n→0).
List<PoseStep> poseTimeline(PoseAnimation pose) {
  final k = pose.keyframes, n = k.length;
  if (n == 1) {
    final h = k[0].hold;
    return [PoseStep(0, 0, (h == null || h == 0) ? 1 : h, 0)];
  }
  final steps = <PoseStep>[
    for (var i = 0; i < n - 1; i++)
      PoseStep(i, i + 1, k[i].hold ?? 0, k[i].dur ?? 0),
  ];
  if (pose.loop == 'cycle') {
    steps.add(PoseStep(n - 1, 0, k[n - 1].hold ?? 0, k[n - 1].dur ?? 0));
  } else {
    for (var i = n - 1; i > 0; i--) {
      steps.add(PoseStep(i, i - 1, k[i].hold ?? 0, k[i - 1].dur ?? 0));
    }
  }
  return steps;
}

double poseDuration(PoseAnimation pose) =>
    poseTimeline(pose).fold(0.0, (s, x) => s + x.hold + x.dur);

/// Positions des articulations à l'instant [t] (secondes, bouclé).
Joints poseJointsAt(PoseAnimation pose, double t) {
  final steps = poseTimeline(pose), total = poseDuration(pose);
  final k = pose.keyframes;
  if (total <= 0) return poseOf(k[0], pose.view);
  t = ((t % total) + total) % total;
  for (final s in steps) {
    if (t < s.hold) return poseOf(k[s.a], pose.view);
    t -= s.hold;
    if (t < s.dur) return poseInterp(k[s.a], k[s.b], t / s.dur, pose.view);
    t -= s.dur;
  }
  return poseOf(k[0], pose.view);
}

/// Cadre commun à toutes les images (x, y haut en repère SVG, largeur, hauteur).
List<double> poseBBox(PoseAnimation pose) {
  final xs = <double>[], ys = <double>[];
  for (final k in pose.keyframes) {
    for (final p in poseOf(k, pose.view).values) {
      xs.add(p.dx);
      ys.add(p.dy);
    }
  }
  for (final p in pose.props) {
    if (p.isStatic && p.raw['x'] != null) {
      xs.add(p.num('x'));
      if (p.raw['y'] != null) ys.add(p.num('y'));
    }
  }
  ys.add(0);
  final x0 = xs.reduce(math.min) - 0.22, x1 = xs.reduce(math.max) + 0.22;
  const y0 = -0.06;
  final y1 = ys.reduce(math.max) + 0.16;
  final w = math.max(x1 - x0, 1.1), h = math.max(y1 - y0, 1.1);
  final cx = (x0 + x1) / 2;
  return [cx - w / 2, -(y0 + h), w, h];
}

// ----------------------------- zones musculaires ----------------------------

const poseMuscleZone = <String, List<String>>{
  // tronc avant
  'grand_pectoral_claviculaire': ['poitrine'],
  'grand_pectoral_sterno_costal': ['poitrine'],
  'grand_pectoral_abdominal': ['poitrine'],
  'petit_pectoral': ['poitrine'],
  'dentele_anterieur': ['poitrine'],
  'coraco_brachial': ['bras_avant'],
  'droit_abdomen': ['abdomen'],
  'oblique_externe': ['abdomen'],
  'oblique_interne': ['abdomen'],
  'transverse_abdomen': ['abdomen'],
  'diaphragme': ['abdomen'],
  'plancher_pelvien': ['abdomen'],
  'grand_psoas': ['abdomen', 'cuisse_avant'],
  'iliaque': ['abdomen', 'cuisse_avant'],
  // tronc arrière
  'trapeze_superieur': ['cou_arriere', 'haut_dos'],
  'trapeze_moyen': ['haut_dos'],
  'trapeze_inferieur': ['haut_dos'],
  'rhomboides': ['haut_dos'],
  'elevateur_scapula': ['cou_arriere'],
  'grand_dorsal': ['haut_dos', 'bas_dos'],
  'grand_rond': ['haut_dos'],
  'erecteurs_thoraciques': ['haut_dos'],
  'erecteurs_lombaires': ['bas_dos'],
  'multifides': ['bas_dos'],
  'carre_des_lombes': ['bas_dos'],
  'extenseurs_cervicaux': ['cou_arriere'],
  'sterno_cleido_mastoidien': ['cou_avant'],
  'flechisseurs_cervicaux_profonds': ['cou_avant'],
  // épaule et bras
  'deltoide_anterieur': ['epaule'],
  'deltoide_moyen': ['epaule'],
  'deltoide_posterieur': ['epaule'],
  'supra_epineux': ['epaule'],
  'infra_epineux': ['epaule'],
  'petit_rond': ['epaule'],
  'sous_scapulaire': ['epaule'],
  'biceps_chef_long': ['bras_avant'],
  'biceps_chef_court': ['bras_avant'],
  'brachial': ['bras_avant'],
  'triceps_chef_long': ['bras_arriere'],
  'triceps_chef_lateral': ['bras_arriere'],
  'triceps_chef_medial': ['bras_arriere'],
  'ancone': ['bras_arriere'],
  'brachio_radial': ['avant_bras_avant'],
  'flechisseurs_du_poignet': ['avant_bras_avant'],
  'flechisseurs_superficiels_des_doigts': ['avant_bras_avant', 'main'],
  'flechisseurs_profonds_des_doigts': ['avant_bras_avant', 'main'],
  'rond_pronateur': ['avant_bras_avant'],
  'carre_pronateur': ['avant_bras_avant'],
  'muscles_intrinseques_main': ['main'],
  'extenseurs_du_poignet': ['avant_bras_arriere'],
  'extenseurs_des_doigts': ['avant_bras_arriere'],
  'supinateur': ['avant_bras_arriere'],
  // hanche et cuisse
  'grand_fessier': ['fesses'],
  'moyen_fessier': ['fesses'],
  'petit_fessier': ['fesses'],
  'rotateurs_lateraux_hanche': ['fesses'],
  'tenseur_fascia_lata': ['cuisse_avant'],
  'sartorius': ['cuisse_avant'],
  'pectine': ['cuisse_avant'],
  'long_adducteur': ['cuisse_avant'],
  'court_adducteur': ['cuisse_avant'],
  'grand_adducteur': ['cuisse_arriere'],
  'gracile': ['cuisse_avant'],
  'droit_femoral': ['cuisse_avant'],
  'vaste_lateral': ['cuisse_avant'],
  'vaste_medial': ['cuisse_avant'],
  'vaste_intermediaire': ['cuisse_avant'],
  'biceps_femoral': ['cuisse_arriere'],
  'biceps_femoral_chef_court': ['cuisse_arriere'],
  'semi_tendineux': ['cuisse_arriere'],
  'semi_membraneux': ['cuisse_arriere'],
  'poplite': ['cuisse_arriere'],
  // jambe
  'gastrocnemien_medial': ['jambe_arriere'],
  'gastrocnemien_lateral': ['jambe_arriere'],
  'soleaire': ['jambe_arriere'],
  'tibial_posterieur': ['jambe_arriere'],
  'flechisseurs_profonds_des_orteils': ['jambe_arriere'],
  'fibulaires': ['jambe_avant'],
  'tibial_anterieur': ['jambe_avant'],
  'long_extenseur_des_orteils': ['jambe_avant'],
  'muscles_intrinseques_pied': ['pied'],
};

/// Zones visibles de face ; les autres sont dessinées en contour dans cette vue.
const poseFaceFront = {
  'poitrine',
  'abdomen',
  'epaule',
  'bras_avant',
  'avant_bras_avant',
  'main',
  'cuisse_avant',
  'jambe_avant',
  'cou_avant',
};

// ----------------------------- géométrie ------------------------------------

List<Offset> _arc(Offset c, double r, double a0, double a1, int n) => [
  for (var i = 0; i <= n; i++)
    Offset(
      c.dx + math.cos(a0 + (a1 - a0) * i / n) * r,
      c.dy + math.sin(a0 + (a1 - a0) * i / n) * r,
    ),
];

class _Capsule {
  final List<Offset> all, front, back;
  const _Capsule(this.all, this.front, this.back);
}

/// Capsule effilée A → B ; « front » = côté de la normale perp(dir).
_Capsule _capsule(Offset a, Offset b, double wa, double wb) {
  final d = _norm(b - a), n = _perp(d);
  final ra = wa / 2, rb = wb / 2;
  final th = math.atan2(n.dy, n.dx);
  final capB = _arc(b, rb, th, th - math.pi, 8);
  final capA = _arc(a, ra, th + math.pi, th + 2 * math.pi, 8);
  return _Capsule(
    [a + n * ra, ...capB, ...capA],
    [a, a + n * ra, ..._arc(b, rb, th, th - math.pi / 2, 4), b],
    [a, b, ..._arc(b, rb, th - math.pi / 2, th - math.pi, 4), a - n * ra],
  );
}

Map<String, List<Offset>> _torsoProfile(Joints j) {
  final p0 = j['bassin']!, upv = _norm(j['cou']! - j['bassin']!);
  final fr0 = _perp(upv), fr = Offset(-fr0.dx, -fr0.dy);
  Offset pt(double u, double v) => p0 + upv * (u * PoseLengths.tronc) + fr * v;
  final front = [
    pt(-0.02, 0.055),
    pt(0.12, 0.08),
    pt(0.35, 0.09),
    pt(0.60, 0.115),
    pt(0.80, 0.125),
    pt(0.95, 0.10),
    pt(1.0, 0.06),
  ];
  final back = [
    pt(1.0, -0.05),
    pt(0.86, -0.08),
    pt(0.62, -0.085),
    pt(0.38, -0.075),
    pt(0.14, -0.085),
    pt(-0.02, -0.09),
    pt(-0.09, -0.045),
    pt(-0.09, 0.02),
  ];
  return {
    'all': [...front, ...back],
    'poitrine': [
      pt(0.55, 0),
      pt(0.55, 0.11),
      pt(0.60, 0.115),
      pt(0.80, 0.125),
      pt(0.95, 0.10),
      pt(1.0, 0.06),
      pt(1.0, 0),
    ],
    'abdomen': [
      pt(-0.02, 0),
      pt(-0.02, 0.055),
      pt(0.12, 0.08),
      pt(0.35, 0.09),
      pt(0.55, 0.11),
      pt(0.55, 0),
    ],
    'haut_dos': [
      pt(1.0, 0),
      pt(1.0, -0.05),
      pt(0.86, -0.08),
      pt(0.62, -0.085),
      pt(0.5, -0.08),
      pt(0.5, 0),
    ],
    'bas_dos': [
      pt(0.5, 0),
      pt(0.5, -0.08),
      pt(0.38, -0.075),
      pt(0.14, -0.085),
      pt(0.12, 0),
    ],
    'fesses': [
      pt(0.12, 0),
      pt(0.14, -0.085),
      pt(-0.02, -0.09),
      pt(-0.09, -0.045),
      pt(-0.09, 0.02),
      pt(-0.02, 0.03),
    ],
  };
}

Map<String, List<Offset>> _torsoFace(Joints j) {
  final sg = j['epaule_g']!, sd = j['epaule_d']!;
  final hg = j['hanche_g']!, hd = j['hanche_d']!;
  final c = j['cou']!, b = j['bassin']!;
  final upv = _norm(c - b), side = _perp(upv);
  Offset mix(Offset a, Offset bb, double t) =>
      Offset(a.dx + (bb.dx - a.dx) * t, a.dy + (bb.dy - a.dy) * t);
  final wg = mix(hg, sg, 0.45), wd = mix(hd, sd, 0.45);
  final waistG = wg - side * 0.02, waistD = wd + side * 0.02;
  final all = [
    sg + upv * 0.02,
    sg + side * 0.02,
    waistG,
    hg + side * 0.01,
    hg + upv * -0.05,
    hd + upv * -0.05,
    hd - side * 0.01,
    waistD,
    sd - side * 0.02,
    sd + upv * 0.02,
  ];
  final mg = mix(waistG, sg, 0.35), md = mix(waistD, sd, 0.35);
  return {
    'all': all,
    'poitrine': [
      mg,
      sg + side * 0.02,
      sg + upv * 0.02,
      sd + upv * 0.02,
      sd - side * 0.02,
      md,
    ],
    'abdomen': [
      hg + upv * -0.05,
      hg + side * 0.01,
      waistG,
      mg,
      md,
      waistD,
      hd - side * 0.01,
      hd + upv * -0.05,
    ],
    'haut_dos': [mg, sg + side * 0.02, sd + upv * 0.02, sd - side * 0.02, md],
    'bas_dos': [waistG, mg, md, waistD],
    'fesses': [
      hg + upv * -0.05,
      hg + side * 0.01,
      hd - side * 0.01,
      hd + upv * -0.05,
    ],
  };
}

List<Offset> _footProfile(Joints j, String s) {
  final talon = j['talon_$s']!, pointe = j['pied_$s']!, ch = j['cheville_$s']!;
  final sole = _norm(pointe - talon), upn = _perp(sole);
  return [
    talon,
    pointe,
    pointe + upn * 0.018,
    ch + sole * 0.03 + upn * 0.012,
    ch - sole * 0.02 + upn * 0.01,
    talon + upn * 0.03,
  ];
}

/// Forme du corps : polygone [all] ou disque [circle] ; [zones] : zone →
/// polygone (null = toute la forme).
class PoseShape {
  final String part;
  final String? side;
  final bool far;
  final List<Offset>? all;
  final (Offset, double)? circle;
  final Map<String, List<Offset>?> zones;
  const PoseShape({
    required this.part,
    this.side,
    required this.far,
    this.all,
    this.circle,
    required this.zones,
  });
}

/// Formes dans l'ordre de dessin (identique au moteur de référence).
List<PoseShape> poseBodyShapes(String view, Joints j) {
  List<PoseShape> limb(String s, bool far) {
    (double, double) w(String k) => poseWidths[k]!;
    final a = _capsule(
      j['epaule_$s']!,
      j['coude_$s']!,
      w('bras').$1,
      w('bras').$2,
    );
    final fa = _capsule(
      j['coude_$s']!,
      j['poignet_$s']!,
      w('avant_bras').$1,
      w('avant_bras').$2,
    );
    final ma = _capsule(
      j['poignet_$s']!,
      j['main_$s']!,
      w('main').$1,
      w('main').$2,
    );
    final th = _capsule(
      j['hanche_$s']!,
      j['genou_$s']!,
      w('cuisse').$1,
      w('cuisse').$2,
    );
    final sh = _capsule(
      j['genou_$s']!,
      j['cheville_$s']!,
      w('jambe').$1,
      w('jambe').$2,
    );
    return [
      PoseShape(
        part: 'cuisse',
        side: s,
        far: far,
        all: th.all,
        zones: {'cuisse_avant': th.front, 'cuisse_arriere': th.back},
      ),
      PoseShape(
        part: 'jambe',
        side: s,
        far: far,
        all: sh.all,
        zones: {'jambe_avant': sh.front, 'jambe_arriere': sh.back},
      ),
      PoseShape(
        part: 'pied',
        side: s,
        far: far,
        all:
            view == 'face'
                ? _capsule(j['cheville_$s']!, j['pied_$s']!, 0.05, 0.05).all
                : _footProfile(j, s),
        zones: const {'pied': null},
      ),
      PoseShape(
        part: 'bras',
        side: s,
        far: far,
        all: a.all,
        zones: {'bras_avant': a.front, 'bras_arriere': a.back},
      ),
      PoseShape(
        part: 'avant_bras',
        side: s,
        far: far,
        all: fa.all,
        zones: {'avant_bras_avant': fa.front, 'avant_bras_arriere': fa.back},
      ),
      PoseShape(
        part: 'main',
        side: s,
        far: far,
        all: ma.all,
        zones: const {'main': null},
      ),
      PoseShape(
        part: 'epaule',
        side: s,
        far: far,
        circle: (j['epaule_$s']!, 0.048),
        zones: const {'epaule': null},
      ),
    ];
  }

  final torso = view == 'face' ? _torsoFace(j) : _torsoProfile(j);
  final neck = _capsule(
    j['cou']!,
    j['tete']!,
    poseWidths['cou']!.$1,
    poseWidths['cou']!.$2,
  );
  final tronc = PoseShape(
    part: 'tronc',
    far: false,
    all: torso['all'],
    zones: {for (final e in torso.entries) e.key: e.value},
  );
  final tete = PoseShape(
    part: 'tete',
    far: false,
    circle: (j['tete']!, poseHeadRadius),
    zones: const {},
  );
  if (view == 'face') {
    final g = limb('g', false), d = limb('d', false);
    return [
      ...g.sublist(0, 3),
      ...d.sublist(0, 3),
      tronc,
      PoseShape(
        part: 'cou',
        far: false,
        all: neck.all,
        zones: {'cou_avant': neck.all, 'cou_arriere': null},
      ),
      tete,
      ...g.sublist(3),
      ...d.sublist(3),
    ];
  }
  return [
    ...limb('g', true),
    tronc,
    PoseShape(
      part: 'cou',
      far: false,
      all: neck.all,
      zones: {'cou_avant': neck.front, 'cou_arriere': neck.back},
    ),
    tete,
    ...limb('d', false),
  ];
}

/// Rôle d'une zone : 'prim', 'sec' ou null.
Map<String, String> poseZoneRoles(
  List<String> primaires,
  List<String> secondaires,
) {
  final out = <String, String>{};
  for (final m in primaires) {
    for (final z in poseMuscleZone[m] ?? const <String>[]) {
      out[z] = 'prim';
    }
  }
  for (final m in secondaires) {
    for (final z in poseMuscleZone[m] ?? const <String>[]) {
      out.putIfAbsent(z, () => 'sec');
    }
  }
  return out;
}
