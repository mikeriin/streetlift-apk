"""M5 (mannequin 3D) : définition du squelette d'animation (sans Blender ni numpy).

Utilisé par `build_rig.py` (fabrication), `render_poses.py` (planches de
contrôle) et `tools/tests/test_m5_rig.py` (contrôles, bibliothèque standard).

Repère : celui du glTF exporté (mètres, Y vers le haut, +Z vers l'avant du
corps, +X côté gauche anatomique). Au repos, chaque os a l'orientation du
corps (aucune rotation) : ses axes sont ceux du corps, et une posture est une
rotation locale par os, composée de rotations anatomiques autour d'axes fixes
du repère local (ordre de la liste `DOF`).

Les axes sont écrits pour le côté gauche ; le côté droit en est le miroir
(symétrie du plan sagittal : axe (x, y, z) → (x, -y, -z), même angle), ce qui
garde le sens anatomique (une flexion reste une flexion des deux côtés).

Amplitudes (degrés, depuis la position de repos du modèle, position
anatomique : paumes vers l'avant, bras écartés d'environ 15°) ; références :
- [AAOS] American Academy of Orthopaedic Surgeons, « Joint Motion: Method of
  Measuring and Recording » (1965) ; Greene & Heckman, « The Clinical
  Measurement of Joint Motion » (AAOS, 1994).
- [NW] Norkin & White, « Measurement of Joint Motion: A Guide to Goniometry »,
  5e éd. (F. A. Davis, 2016).
- [WP] White & Panjabi, « Clinical Biomechanics of the Spine », 2e éd.
  (Lippincott, 1990) : amplitudes segmentaires du rachis.
- [INMAN] Inman, Saunders & Abbott, « Observations on the function of the
  shoulder joint », J Bone Joint Surg 26 (1944) : rythme scapulo-huméral,
  élévation de la clavicule.
- [LUD] Ludewig et al., « Motion of the shoulder complex during multiplanar
  humeral elevation », J Bone Joint Surg Am 91 (2009) : sonnette, bascule.
- [HEM] Hemmerich et al., « Hip, knee, and ankle kinematics of high range of
  motion activities of daily living », J Orthop Res 24 (2006) : squat complet
  (genou 157°, cheville 38°).
- [KAP] Kapandji, « Physiologie articulaire » (Maloine), tomes 1 à 3.
"""
import math

# Os : (nom, parent, côté) ; côté 'L' / 'R' / None. Ordre = ordre des
# articulations du glTF (parent avant enfant).
_AXIAL = [
    ('pelvis', None), ('lumbar', 'pelvis'), ('thoracic_low', 'lumbar'),
    ('thoracic_high', 'thoracic_low'), ('neck', 'thoracic_high'), ('head', 'neck'),
]
_ARM = [
    ('clavicle', 'thoracic_high'), ('scapula', 'clavicle'), ('upperarm', 'scapula'),
    ('forearm', 'upperarm'), ('radius', 'forearm'), ('hand', 'radius'),
    ('fingers1', 'hand'), ('fingers2', 'fingers1'),
]
_LEG = [('thigh', 'pelvis'), ('shin', 'thigh'), ('foot', 'shin'), ('toes', 'foot')]


def _side_name(name, side):
    return f'{name}_{side.lower()}'


BONES = [(n, p, None) for n, p in _AXIAL]
for _side in ('L', 'R'):
    for _n, _p in _ARM + _LEG:
        parent = _p if _p in dict(_AXIAL) else _side_name(_p, _side)
        BONES.append((_side_name(_n, _side), parent, _side))

# Os d'aide (correctifs du mélange linéaire, M56) : à la tête de l'os suivi,
# fils du même parent, ils prennent une fraction (1/3, 2/3) de sa rotation
# locale. Les sommets partagés entre le parent et l'os suivi sont répartis
# sur la chaîne parent → 1/3 → 2/3 → os suivi selon leur fraction de
# rotation : une articulation pliée à 150° se déforme en trois tiers au lieu
# de s'effondrer (épaule, coude, hanche, genou ; pronation à 1/2). Un
# gonflement (par radian de flexion, perpendiculaire à l'axe de rotation)
# compense la perte de volume du mélange linéaire au pli.
# nom de base : (parent, os suivi, part, gonflement par radian)
HELPERS = {
    'shoulder_aux': ('scapula', 'upperarm', 1 / 3, 0.0),
    'shoulder_aux2': ('scapula', 'upperarm', 2 / 3, 0.0),
    'elbow_aux': ('upperarm', 'forearm', 1 / 3, .06),
    'elbow_aux2': ('upperarm', 'forearm', 2 / 3, .06),
    'pronation_aux': ('forearm', 'radius', .5, 0.0),
    'hip_aux': ('pelvis', 'thigh', 1 / 3, .04),
    'hip_aux2': ('pelvis', 'thigh', 2 / 3, .04),
    'knee_aux': ('thigh', 'shin', 1 / 3, .06),
    'knee_aux2': ('thigh', 'shin', 2 / 3, .06),
}
# Gonflements de contraction (M56) : os sans rotation, fils du segment, à la
# tête placée au ventre du muscle (calculée à la fabrication), dont l'échelle
# perpendiculaire à l'axe du muscle croît avec la flexion de l'articulation
# motrice (par radian) ; les sommets du ventre des muscles cités lui sont
# confiés pour une part (BULGE_SHARE) de leur poids sur le segment.
# nom de base : (parent = segment, os moteur, gain par radian, muscles)
BULGES = {
    'biceps_bulge': ('upperarm', 'forearm', .10,
                     ('biceps_brachii_long', 'biceps_brachii_short', 'brachialis')),
    'quads_bulge': ('thigh', 'shin', .045,
                    ('rectus_femoris', 'vastus_lateralis', 'vastus_medialis',
                     'vastus_intermedius')),
    'glute_bulge': ('pelvis', 'thigh', .05, ('gluteus_maximus',)),
}
BULGE_SHARE = .7
# Os d'insertion (M56, correction 1) : fils du bras, placé à l'insertion des
# grands muscles du tronc sur l'humérus (gouttière bicipitale : grand
# dorsal, grand rond, grand pectoral), il **suit la position** de cette
# insertion mais **garde l'orientation du tronc** (rotation locale = inverse
# de la rotation cumulée clavicule → scapula → bras). Une nappe pesée entre
# le tronc et cet os s'étire donc en ligne droite vers l'insertion déplacée
# (un V bras levés) au lieu d'être emportée par la rotation de 160° du bras
# (les « boucles » sous l'aisselle en suspension, retour du propriétaire).
# nom de base : (parent, os dont il garde l'orientation, distance de la tête
# de l'humérus le long du bras, muscles confiés)
INSERTIONS = {
    'arm_ins': ('upperarm', 'thoracic_high', .06,
                ('latissimus_dorsi', 'teres_major', 'pectoralis_major_clavicular',
                 'pectoralis_major_sternocostal', 'pectoralis_major_abdominal')),
}
for _side in ('L', 'R'):
    for _n, (_p, _f, _part, _g) in HELPERS.items():
        parent = _p if _p in dict(_AXIAL) else _side_name(_p, _side)
        BONES.append((_side_name(_n, _side), parent, _side))
    for _n, (_p, _f, _g, _m) in BULGES.items():
        parent = _p if _p in dict(_AXIAL) else _side_name(_p, _side)
        BONES.append((_side_name(_n, _side), parent, _side))
    for _n, (_p, _f, _d, _m) in INSERTIONS.items():
        BONES.append((_side_name(_n, _side), _side_name(_p, _side), _side))

BONE_NAMES = [b[0] for b in BONES]
PARENT = {b[0]: b[1] for b in BONES}
SIDE = {b[0]: b[2] for b in BONES}
MAX_BONES = 60

# Noms français (rig.json, écran Anatomie).
FR_BONE = {
    'pelvis': 'Bassin', 'lumbar': 'Rachis lombaire',
    'thoracic_low': 'Rachis thoracique bas', 'thoracic_high': 'Rachis thoracique haut',
    'neck': 'Cou', 'head': 'Tête', 'clavicle': 'Clavicule', 'scapula': 'Scapula',
    'upperarm': 'Bras', 'forearm': 'Avant-bras (ulna)', 'radius': 'Avant-bras (radius)',
    'hand': 'Main', 'fingers1': 'Doigts (phalanges proximales)',
    'fingers2': 'Doigts (phalanges moyennes et distales)', 'thigh': 'Cuisse',
    'shin': 'Jambe', 'foot': 'Pied', 'toes': 'Orteils',
    'shoulder_aux': "Aide de l'épaule (1/3)", 'shoulder_aux2': "Aide de l'épaule (2/3)",
    'elbow_aux': 'Aide du coude (1/3)', 'elbow_aux2': 'Aide du coude (2/3)',
    'pronation_aux': 'Aide de la pronation', 'hip_aux': 'Aide de la hanche (1/3)',
    'hip_aux2': 'Aide de la hanche (2/3)', 'knee_aux': 'Aide du genou (1/3)',
    'knee_aux2': 'Aide du genou (2/3)',
    'biceps_bulge': 'Gonflement du biceps', 'quads_bulge': 'Gonflement du quadriceps',
    'glute_bulge': 'Gonflement du grand fessier',
    'arm_ins': 'Insertion des muscles du tronc sur le bras',
}


def helper_of(bone):
    """(parent, os suivi) d'un os d'aide ou de gonflement, sinon None."""
    base = base_name(bone)
    side = bone[-2:]
    if base in HELPERS:
        p, f = HELPERS[base][:2]
    elif base in BULGES:
        p, f = BULGES[base][:2]
    elif base in INSERTIONS:
        p, f = INSERTIONS[base][:2]
        return (p + side, f)
    else:
        return None
    return (p if p in dict(_AXIAL) else p + side, f + side)


def helper_spec(bone):
    """{'suit', 'part', 'gonflement'} d'un os d'aide, {'suit', 'moteur',
    'gonflement', 'muscles'} d'un os de gonflement, sinon None."""
    base = base_name(bone)
    side = bone[-2:]
    if base in HELPERS:
        p, f, part, g = HELPERS[base]
        return {'suit': f + side, 'part': part, 'gonflement': g}
    if base in BULGES:
        p, f, g, muscles = BULGES[base]
        return {'suit': f + side, 'part': 0.0, 'gonflement': g, 'muscles': list(muscles)}
    if base in INSERTIONS:
        p, f, d, muscles = INSERTIONS[base]
        return {'suit': f, 'part': 0.0, 'gonflement': 0.0, 'insertion': True,
                'distance': d, 'muscles': list(muscles)}
    return None


def is_insertion(bone):
    return base_name(bone) in INSERTIONS


def is_bulge(bone):
    return base_name(bone) in BULGES


def base_name(bone):
    return bone[:-2] if bone.endswith(('_l', '_r')) else bone


# Degrés de liberté par os (côté gauche) : (clé, nom, axe, min, max, source).
# Axe 'bone' : axe propre de l'os (de la tête vers la queue), calculé à la
# fabrication (pronation / supination autour de l'axe radius-ulna).
X, Y, Z = (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)
# Plan de la scapula (côté gauche) : 35° en avant du plan frontal.
_SP = math.radians(35)
SCAPULAR_NORMAL = (-math.sin(_SP), 0.0, math.cos(_SP))          # sonnette
SCAPULAR_MEDIOLATERAL = (-math.cos(_SP), 0.0, -math.sin(_SP))   # bascule (comme NX)
NX, NY, NZ = (-1.0, 0.0, 0.0), (0.0, -1.0, 0.0), (0.0, 0.0, -1.0)

DOF = {
    'lumbar': [
        ('flexion', 'Flexion (+) / extension (−)', X, -25, 50, 'WP (L1-S1), AAOS'),
        ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -20, 20, 'WP'),
        ('rotation', 'Rotation vers la gauche (+)', Y, -8, 8, 'WP'),
    ],
    'thoracic_low': [
        ('flexion', 'Flexion (+) / extension (−)', X, -12, 20, 'WP (T8-T12)'),
        ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -15, 15, 'WP'),
        ('rotation', 'Rotation vers la gauche (+)', Y, -18, 18, 'WP'),
    ],
    'thoracic_high': [
        ('flexion', 'Flexion (+) / extension (−)', X, -10, 15, 'WP (T1-T7)'),
        ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -12, 12, 'WP'),
        ('rotation', 'Rotation vers la gauche (+)', Y, -18, 18, 'WP'),
    ],
    'neck': [
        ('flexion', 'Flexion (+) / extension (−)', X, -50, 40, 'AAOS, NW (C2-C7)'),
        ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -35, 35, 'AAOS'),
        ('rotation', 'Rotation vers la gauche (+)', Y, -45, 45, 'AAOS'),
    ],
    'head': [
        ('flexion', 'Flexion (+) / extension (−)', X, -20, 10, 'WP (C0-C1)'),
        ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -8, 8, 'WP'),
        ('rotation', 'Rotation vers la gauche (+)', Y, -35, 35, 'WP (C1-C2)'),
    ],
    # Élévation / abaissement et protraction / rétraction de la scapula : la
    # clavicule qui la porte tourne autour de l'articulation sterno-claviculaire.
    'clavicle': [
        ('elevation', 'Élévation (+) / abaissement (−) de la scapula', Z, -10, 45,
         'INMAN, KAP'),
        ('protraction', 'Protraction (+) / rétraction (−) de la scapula', NY, -25, 20,
         'LUD, KAP'),
    ],
    # Sonnette et bascule dans le plan de la scapula (35° en avant du plan
    # frontal, LUD, KAP) : l'angle inférieur s'écarte vers le côté ET vers
    # l'avant, il contourne la cage thoracique (correction 1 : autour de Z,
    # il sortait du dos de 5 cm en suspension, « omoplates arrachées »).
    'scapula': [
        ('sonnette', 'Sonnette latérale (+, rotation vers le haut) / médiale (−)',
         SCAPULAR_NORMAL, -15, 60, 'INMAN, LUD'),
        ('bascule', 'Bascule postérieure (+) / antérieure (−)', SCAPULAR_MEDIOLATERAL,
         -20, 30, 'LUD'),
        ('rotation', 'Rotation interne (+) / externe (−)', Y, -15, 15, 'LUD'),
    ],
    # Bras par rapport au thorax (angles humérothoraciques, ceux des
    # goniomètres) : la rotation glénohumérale en est déduite, une fois la
    # scapula et la clavicle placées (voir `posture_rotations`). La part
    # glénohumérale reste contrôlée (GH_MAX, rythme scapulo-huméral 2:1).
    'upperarm': [
        ('flexion', 'Flexion (+) / extension (−) du bras / thorax', NX, -60, 180, 'AAOS'),
        ('abduction', 'Abduction (+) / adduction (−) du bras / thorax', Z, -25, 170,
         'AAOS'),
        ('rotation', 'Rotation interne (+) / externe (−)', NY, -90, 70, 'AAOS'),
    ],
    'forearm': [
        ('flexion', 'Flexion du coude (+)', 'mesure:coude', -5, 150, 'AAOS'),
    ],
    'radius': [
        ('pronation', 'Pronation (+) depuis la supination du repos', 'bone', -10, 165,
         'AAOS (pronation 80, supination 80)'),
    ],
    'hand': [
        ('flexion', 'Flexion palmaire (+) / extension (−)', NX, -70, 80, 'AAOS'),
        ('deviation', 'Inclinaison radiale (+) / ulnaire (−)', Z, -30, 20, 'AAOS'),
    ],
    'fingers1': [
        ('flexion', 'Flexion des métacarpo-phalangiennes (+)', NX, -20, 90, 'AAOS'),
    ],
    'fingers2': [
        ('flexion', 'Flexion des interphalangiennes (+)', NX, 0, 100, 'AAOS'),
    ],
    'thigh': [
        ('flexion', 'Flexion (+) / extension (−)', NX, -20, 125, 'AAOS, NW'),
        ('abduction', 'Abduction (+) / adduction (−)', Z, -30, 45, 'AAOS'),
        ('rotation', 'Rotation interne (+) / externe (−)', NY, -45, 45, 'AAOS'),
    ],
    'shin': [
        ('flexion', 'Flexion du genou (+)', 'mesure:genou', -5, 157, 'AAOS, HEM'),
        # Rotation du tibia sous le fémur, genou fléchi (M56 : squat profond,
        # pieds à plat et genoux dans l'axe des pieds).
        ('rotation', 'Rotation interne (+) / externe (−) du tibia, genou fléchi', 'bone',
         -30, 20, 'AAOS (genou fléchi : interne 10-20°, externe 20-30°), KAP t. 2'),
    ],
    'foot': [
        ('flexion', 'Flexion dorsale (+) / plantaire (−)', 'mesure:cheville', -50, 40,
         'AAOS, HEM'),
        ('inversion', 'Inversion (+) / éversion (−)', NZ, -15, 35, 'AAOS'),
    ],
    'toes': [
        ('flexion', 'Flexion (+) / extension (−) des orteils', X, -70, 40, 'AAOS'),
    ],
}

# Axes par défaut des articulations mesurées (sans mesure : anatomiques).
MEASURED_DEFAULT = {'coude': NX, 'genou': X, 'cheville': NX}

SOURCES = {
    'AAOS': 'American Academy of Orthopaedic Surgeons, Joint Motion: Method of '
            'Measuring and Recording (1965) ; Greene & Heckman, The Clinical '
            'Measurement of Joint Motion (1994)',
    'NW': 'Norkin & White, Measurement of Joint Motion: A Guide to Goniometry, 5e éd. (2016)',
    'WP': 'White & Panjabi, Clinical Biomechanics of the Spine, 2e éd. (1990)',
    'INMAN': 'Inman, Saunders & Abbott, J Bone Joint Surg 26 (1944)',
    'LUD': 'Ludewig et al., J Bone Joint Surg Am 91 (2009)',
    'HEM': 'Hemmerich et al., J Orthop Res 24 (2006)',
    'KAP': 'Kapandji, Physiologie articulaire, tomes 1 à 3',
}


def mirror_axis(axis):
    return (axis[0], -axis[1], -axis[2])


def dofs_of(bone, bone_axis=None, measured=None):
    """Degrés de liberté d'un os (axes du côté de l'os). `measured` : axes
    mesurés sur les os du modèle (M56 : 'coude', 'genou', 'cheville'), en
    convention du côté de l'os ; sans mesure, l'axe anatomique par défaut."""
    out = []
    for key, name, axis, lo, hi, src in DOF.get(base_name(bone), []):
        if isinstance(axis, str) and axis.startswith('mesure:'):
            m = (measured or {}).get(axis[7:])
            axis = tuple(m) if m else MEASURED_DEFAULT[axis[7:]]
            if m:
                out.append({'cle': key, 'nom': name, 'axe': list(axis), 'min': lo, 'max': hi,
                            'source': src + ' ; axe mesuré sur les os du modèle'})
                continue
            if SIDE[bone] == 'R':
                axis = mirror_axis(axis)
        elif axis == 'bone':
            axis = tuple(bone_axis)
            # Le miroir d'un axe propre est l'opposé de l'axe propre de l'os
            # droit (voir la docstring) : l'axe du radius droit est donc
            # retourné pour garder le sens de la pronation.
            if SIDE[bone] == 'R':
                axis = tuple(-a for a in axis)
        elif SIDE[bone] == 'R':
            axis = mirror_axis(axis)
        out.append({'cle': key, 'nom': name, 'axe': list(axis), 'min': lo, 'max': hi,
                    'source': src})
    return out


# ------------------------------------------------------------ quaternions --
# (x, y, z, w), convention du glTF.

def q_axis_angle(axis, degrees):
    a = math.radians(degrees) / 2
    n = math.sqrt(sum(c * c for c in axis))
    s = math.sin(a) / n
    return (axis[0] * s, axis[1] * s, axis[2] * s, math.cos(a))


def q_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return (aw * bx + ax * bw + ay * bz - az * by,
            aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw,
            aw * bw - ax * bx - ay * by - az * bz)


def q_normalize(q):
    n = math.sqrt(sum(c * c for c in q))
    return tuple(c / n for c in q)


def q_rotate(q, v):
    x, y, z, w = q
    # v' = q v q*
    ix = w * v[0] + y * v[2] - z * v[1]
    iy = w * v[1] + z * v[0] - x * v[2]
    iz = w * v[2] + x * v[1] - y * v[0]
    iw = -x * v[0] - y * v[1] - z * v[2]
    return (ix * w + iw * -x + iy * -z - iz * -y,
            iy * w + iw * -y + iz * -x - ix * -z,
            iz * w + iw * -z + ix * -y - iy * -x)


def local_rotation(bone, angles, dofs):
    """Rotation locale d'un os : produit des rotations anatomiques, dans
    l'ordre de ses degrés de liberté."""
    q = (0.0, 0.0, 0.0, 1.0)
    for d in dofs:
        a = angles.get(d['cle'], 0.0)
        if a:
            q = q_mul(q, q_axis_angle(d['axe'], a))
    return q_normalize(q)


def q_conj(q):
    return (-q[0], -q[1], -q[2], q[3])


def q_angle(q):
    """Angle (degrés) d'une rotation."""
    return math.degrees(2 * math.acos(min(1.0, abs(q[3]))))


# Part glénohumérale maximale de l'élévation du bras (INMAN : ≈ 120° sur
# 180°, le reste par la scapula et la clavicule ; M56 : 130°, haut de la
# variabilité inter-individuelle (Inman 120 ± 10°), atteint en suspension
# active : scapulas abaissées, bras vertical).
GH_MAX = 130


def posture_rotations(dofs_by_bone, angles_by_bone):
    """Rotations locales {os: quaternion} d'une posture (angles par os),
    os d'aide compris. Bras : angles humérothoraciques convertis en rotation
    glénohumérale (inverse de la ceinture scapulaire)."""
    rots = {}
    for bone, angles in angles_by_bone.items():
        rots[bone] = local_rotation(bone, angles, dofs_by_bone[bone])
    for side in ('_l', '_r'):
        arm = 'upperarm' + side
        if arm in rots:
            girdle = q_mul(rots.get('clavicle' + side, (0.0, 0.0, 0.0, 1.0)),
                           rots.get('scapula' + side, (0.0, 0.0, 0.0, 1.0)))
            rots[arm] = q_normalize(q_mul(q_conj(girdle), rots[arm]))
        elif 'clavicle' + side in rots or 'scapula' + side in rots:
            # Bras immobile par rapport au thorax quand la ceinture bouge.
            girdle = q_mul(rots.get('clavicle' + side, (0.0, 0.0, 0.0, 1.0)),
                           rots.get('scapula' + side, (0.0, 0.0, 0.0, 1.0)))
            rots[arm] = q_conj(girdle)
    return with_helpers(rots)


def q_slerp_identity(q, t):
    """Interpolation sphérique de l'identité vers q (fraction t)."""
    x, y, z, w = q
    if w < 0:
        x, y, z, w = -x, -y, -z, -w
    angle = math.acos(max(-1.0, min(1.0, w)))
    if angle < 1e-9:
        return (0.0, 0.0, 0.0, 1.0)
    s = math.sin(angle)
    a = math.sin((1 - t) * angle) / s
    b = math.sin(t * angle) / s
    return q_normalize((b * x, b * y, b * z, a + b * w))


def with_helpers(rotations):
    """Rotations complétées par celles des os d'aide (fraction de la rotation
    locale de l'os suivi) ; les os de gonflement ne tournent pas."""
    out = dict(rotations)
    for bone in BONE_NAMES:
        spec = helper_spec(bone)
        if spec and spec['part']:
            q = rotations.get(spec['suit'], (0.0, 0.0, 0.0, 1.0))
            out[bone] = q_slerp_identity(q, spec['part'])
        elif spec and spec.get('insertion'):
            # Orientation du tronc : inverse de la rotation cumulée des os
            # entre l'os suivi (exclu) et le parent (inclus).
            chain = (0.0, 0.0, 0.0, 1.0)
            b = PARENT[bone]
            while b is not None and b != spec['suit']:
                chain = q_mul(rotations.get(b, (0.0, 0.0, 0.0, 1.0)), chain)
                b = PARENT[b]
            out[bone] = q_conj(q_normalize(chain))
    return out


def q_axis(q):
    """Axe unitaire d'une rotation (X si nulle)."""
    x, y, z, w = q
    n = math.sqrt(x * x + y * y + z * z)
    return (x / n, y / n, z / n) if n > 1e-9 else (1.0, 0.0, 0.0)


def helper_scales(rotations, rig=None):
    """Échelles locales (matrices 3×3) des os d'aide et de gonflement (M56) :
    1 + gain × angle (radians) de l'os moteur, perpendiculairement à l'axe de
    sa rotation (aide) ou à l'axe du muscle (gonflement, `axe` de rig.json).
    Vide sans gonflement."""
    axes = {}
    if rig is not None:
        axes = {b['nom']: b['aide'].get('axe') for b in rig['os'] if 'aide' in b}
    out = {}
    for bone in BONE_NAMES:
        spec = helper_spec(bone)
        if not spec or not spec['gonflement']:
            continue
        q = rotations.get(spec['suit'], (0.0, 0.0, 0.0, 1.0))
        angle = math.radians(q_angle(q))
        if angle < 1e-6:
            continue
        s = 1 + spec['gonflement'] * angle
        a = axes.get(bone) or (None if spec['part'] else (0.0, 1.0, 0.0))
        a = tuple(a) if a else q_axis(q)
        out[bone] = [[(1 if i == j else 0) + (s - 1) * ((1 if i == j else 0) - a[i] * a[j])
                      for j in range(3)] for i in range(3)]
    return out


def mat_from(q, t, scale=None):
    """Matrice 3×4 (lignes) d'une échelle (3×3, facultative) suivie d'une
    rotation q et d'une translation t."""
    x, y, z, w = q
    r = [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ]
    if scale is not None:
        r = [[sum(r[i][k] * scale[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return [r[0] + [t[0]], r[1] + [t[1]], r[2] + [t[2]]]


def mat_mul(a, b):
    out = []
    for i in range(3):
        row = []
        for j in range(4):
            s = sum(a[i][k] * b[k][j] for k in range(3))
            if j == 3:
                s += a[i][3]
            row.append(s)
        out.append(row)
    return out


def mat_apply(m, p):
    return (m[0][0] * p[0] + m[0][1] * p[1] + m[0][2] * p[2] + m[0][3],
            m[1][0] * p[0] + m[1][1] * p[1] + m[1][2] * p[2] + m[1][3],
            m[2][0] * p[0] + m[2][1] * p[1] + m[2][2] * p[2] + m[2][3])


def forward_kinematics(rig, rotations, root_translation=(0.0, 0.0, 0.0), scales=None):
    """Transformations globales des os (matrices 3×4) pour des rotations
    locales {os: quaternion} et des échelles locales {os: 3×3} (os d'aide et
    de gonflement, M56 ; None : calculées ici). Os au repos : translation
    seule (tête de l'os). La racine (bassin) est placée en
    `head + root_translation`."""
    if scales is None:
        scales = helper_scales(rotations, rig)
    heads = {b['nom']: b['tete'] for b in rig['os']}
    out = {}
    for b in rig['os']:
        name = b['nom']
        q = tuple(rotations.get(name, (0.0, 0.0, 0.0, 1.0)))
        parent = b['parent']
        if parent is None:
            t = [heads[name][i] + root_translation[i] for i in range(3)]
            out[name] = mat_from(q, t, scales.get(name))
        else:
            rel = [heads[name][i] - heads[parent][i] for i in range(3)]
            out[name] = mat_mul(out[parent], mat_from(q, rel, scales.get(name)))
    return out


def skinning_matrices(rig, globals_):
    """Matrices de peau : globale × inverse de la liaison (translation −tête)."""
    out = {}
    for b in rig['os']:
        g = globals_[b['nom']]
        h = b['tete']
        out[b['nom']] = [[g[i][0], g[i][1], g[i][2],
                          g[i][3] - (g[i][0] * h[0] + g[i][1] * h[1] + g[i][2] * h[2])]
                         for i in range(3)]
    return out


# ---------------------------------------------------------------- postures --
# Angles anatomiques (degrés) par os ; une clé sans côté vaut pour les deux
# côtés, `os_l` / `os_r` pour un seul. Placement :
#   'sol'      : point le plus bas posé au sol ;
#   'pieds'    : bassin incliné pour que les pieds soient à plat, puis au sol ;
#   'appuis'   : bassin incliné pour que les avant-bras et les orteils
#                touchent le sol ensemble (planche) ;
#   'suspendu' : orteils à 5 cm du sol (suspension, sans barre en M5).
# `app` : proposée dans l'écran Anatomie (sélecteur « Posture »).
POSTURES = {
    'debout': {'nom': 'Debout', 'app': True, 'placement': 'sol', 'angles': {}},
    'suspendu': {
        'nom': 'Suspendu à la barre', 'app': True, 'placement': 'suspendu',
        'angles': {
            # Suspension passive, prise en pronation : scapulas élevées et en
            # sonnette latérale (élévation totale du bras ≈ 165°).
            'clavicle': {'elevation': 15},
            'scapula': {'sonnette': 35, 'bascule': 15},
            'upperarm': {'abduction': 155},
            'hand': {'flexion': 5},
            'fingers1': {'flexion': 75}, 'fingers2': {'flexion': 90},
            'thigh': {'flexion': 5}, 'shin': {'flexion': 10},
            'foot': {'flexion': -25},
        },
    },
    'squat_bas': {
        'nom': 'Squat bas', 'app': True, 'placement': 'pieds',
        'angles': {
            # Squat complet talons au sol (HEM : genou 157°, cheville 38°),
            # genoux ouverts, bras tendus devant pour l'équilibre.
            'lumbar': {'flexion': 15}, 'thoracic_low': {'flexion': 5},
            'neck': {'flexion': -20}, 'head': {'flexion': -10},
            'thigh': {'flexion': 118, 'abduction': 18, 'rotation': -15},
            'shin': {'flexion': 145}, 'foot': {'flexion': 35},
            'clavicle': {'protraction': 10},
            'scapula': {'sonnette': 15},
            'upperarm': {'flexion': 65, 'abduction': -8},
            'forearm': {'flexion': 10}, 'radius': {'pronation': 90},
            'fingers1': {'flexion': 20}, 'fingers2': {'flexion': 20},
        },
    },
    'planche': {
        'nom': 'Planche de gainage', 'app': True, 'placement': 'appuis',
        'angles': {
            # Planche sur les avant-bras : coudes sous les épaules, poings
            # (pouces en haut), corps gainé, appui sur les orteils.
            'clavicle': {'protraction': 8},
            'scapula': {'sonnette': 8},
            'upperarm': {'flexion': 80, 'abduction': -8},
            'forearm': {'flexion': 90}, 'radius': {'pronation': 85},
            'fingers1': {'flexion': 80}, 'fingers2': {'flexion': 95},
            'neck': {'flexion': -5},
            'foot': {'flexion': 5}, 'toes': {'flexion': -60},
        },
    },
    # Postures extrêmes de contrôle (planches Blender et tests).
    'bras_leves': {
        'nom': 'Bras levés verticalement', 'app': False, 'placement': 'sol',
        # Sonnette 50° et clavicule 20° en élévation complète (Inman : 50-60°
        # de rotation scapulaire, 30° d'élévation claviculaire) : part
        # glénohumérale 122° (correction 1, axes scapulaires inclinés).
        'angles': {'clavicle': {'elevation': 20}, 'scapula': {'sonnette': 50, 'bascule': 20},
                   'upperarm': {'abduction': 168}},
    },
    'bras_extension': {
        'nom': 'Bras en extension arrière maximale', 'app': False, 'placement': 'sol',
        'angles': {'clavicle': {'protraction': 10}, 'scapula': {'bascule': -15},
                   'upperarm': {'flexion': -60, 'abduction': -8}},
    },
    'coude_150': {
        'nom': 'Coude fléchi à 150°', 'app': False, 'placement': 'sol',
        'angles': {'forearm': {'flexion': 150}, 'radius': {'pronation': 80},
                   'upperarm': {'abduction': -5}},
    },
    'hanche_120': {
        'nom': 'Hanche fléchie à 120°, jambe tendue', 'app': False, 'placement': 'sol',
        'angles': {'thigh_l': {'flexion': 120}, 'lumbar': {'flexion': 10}},
    },
    'rachis_flexion': {
        'nom': 'Rachis en flexion', 'app': False, 'placement': 'sol',
        'angles': {'lumbar': {'flexion': 45}, 'thoracic_low': {'flexion': 18},
                   'thoracic_high': {'flexion': 12}, 'neck': {'flexion': 35},
                   'head': {'flexion': 8}},
    },
    'rachis_extension': {
        'nom': 'Rachis en extension', 'app': False, 'placement': 'sol',
        'angles': {'lumbar': {'flexion': -20}, 'thoracic_low': {'flexion': -8},
                   'thoracic_high': {'flexion': -5}, 'neck': {'flexion': -30},
                   'head': {'flexion': -10}},
    },
    'rachis_rotation': {
        'nom': 'Rachis en rotation', 'app': False, 'placement': 'sol',
        'angles': {'lumbar': {'rotation': 8, 'inclinaison': 10},
                   'thoracic_low': {'rotation': 18, 'inclinaison': 8},
                   'thoracic_high': {'rotation': 18, 'inclinaison': 6},
                   'neck': {'rotation': 40}, 'head': {'rotation': 25}},
    },
    'dips_bas': {
        'nom': 'Appui bas de dip', 'app': False, 'placement': 'suspendu',
        'angles': {
            'pelvis': {'flexion': 20},
            'clavicle': {'elevation': 12}, 'scapula': {'sonnette': -12, 'bascule': -15},
            'upperarm': {'flexion': -60, 'abduction': -8},
            'forearm': {'flexion': 100}, 'radius': {'pronation': 85},
            'fingers1': {'flexion': 70}, 'fingers2': {'flexion': 80},
            'thigh': {'flexion': 20}, 'shin': {'flexion': 95}, 'foot': {'flexion': -20},
        },
    },
}

# Degrés de liberté du bassin (racine, placement global de la posture).
DOF['pelvis'] = [
    ('flexion', 'Inclinaison du corps vers l\'avant (+)', X, -180, 180, '—'),
    ('inclinaison', 'Inclinaison latérale gauche (+)', NZ, -180, 180, '—'),
    ('rotation', 'Rotation vers la gauche (+)', Y, -180, 180, '—'),
]


def posture_angles(name):
    """Angles par os (noms avec côté) d'une posture."""
    out = {}
    for key, angles in POSTURES[name]['angles'].items():
        if key in BONE_NAMES:
            out.setdefault(key, {}).update(angles)
        else:
            for b in BONE_NAMES:
                if base_name(b) == key:
                    out.setdefault(b, {}).update(angles)
    return out
