#!/usr/bin/env python3
"""M6c (mannequin 3D) : fabrique le mannequin d'exécution à partir du
personnage Mixamo « Ch36 » fourni par le propriétaire (29/09/2026).

Source : `assets_secure/character_mixamo_ch36.fbx.enc` (chiffré ; déchiffré
par `tools/secure_assets.py decrypt` avec la clé `KT_ASSETS_KEY`) : un seul
maillage fermé de 28 880 triangles, 14 442 sommets, squelette `mixamorig1:`
de 65 os, 52 groupes de sommets, en T, 1,77 m, sans animation.

Chaîne (Blender sans interface pour lire le FBX, numpy / scipy ensuite) :
  1. lecture du FBX : sommets de repos, triangles, poids de peau, os
     (noms, parents, têtes et repères de repos) ; repère glTF (y en haut,
     avant = +z, gauche anatomique = +x) ;
  2. « un peu plus fit, sans abus ni déformation » (`FIT`) : gonflements
     lisses du maillage de repos, par zones (épaules / deltoïdes,
     pectoraux, grand dorsal, bras, avant-bras, cuisses, mollets), taille
     inchangée ; os et poids de peau intacts ; mesures avant / après ;
  3. pose d'affichage (`DISPLAY_POSE`, bras abaissés comme l'écorché de
     5.5.2 à 5.5.5) par une peau linéaire calculée ici avec les poids de
     Mixamo (le squelette et la pose de repos restent ceux du FBX :
     `assets/anatomy/squelette_mixamo.json` les donne au code pour M7) ;
  4. zones musculaires : les régions d'un modèle anatomique (écorché
     acheté ou Z-Anatomy, `--source`) sont recalées sur le personnage posé
     (échelle par segments de hauteur, repères : épaules, coudes,
     poignets, hanches, genoux, chevilles), puis projetées sur sa peau le
     long des normales (surface la plus proche) ; frontières lissées,
     îlots rattachés au voisin, côté gauche / droit donné par la position ;
     tête, mains et pieds par les poids de peau ;
  5. GLB : un nœud par zone (`<clé>_<left|right>`), `peau` (peau sans
     muscle), `head` ; normales du maillage entier (aucune couture) ; carte
     `assets/anatomy/muscles_map.json`.

Relançable :
  KT_ASSETS_KEY=… python3 tools/secure_assets.py decrypt --tout
  pip install bpy numpy scipy pillow --break-system-packages
  python3 tools/anatomy/build_character.py [--source ecorche|zanatomy]
      [--render dossier] [--poses dossier]
puis `KT_ASSETS_KEY=… python3 tools/secure_assets.py encrypt assets/anatomy/mannequin.glb`.
`--check` vérifie seulement les sorties (sans la source).
Sources des zones comparées en M6c (DECISIONS_3D.md) : l'écorché acheté
(retenu : couverture complète de la peau, frontières nettes) et Z-Anatomy
(`--source zanatomy`, repris de l'historique git : plus de peau nue, zones
morcelées).
"""
import argparse
import hashlib
import json
import math
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
from anatomy_data import APP_GROUPS, FR, GROUP_OF_KEY, PACK_OF_KEY, SIDE_FR, pack_muscles  # noqa: E402,F401

FBX = ROOT / 'assets_secure/clair/character_mixamo_ch36.fbx'
ECORCHE_GLB = ROOT / 'assets_secure/clair/ecorche_mannequin.glb'
ECORCHE_MAP = HERE / 'ecorche_map.json'
# Z-Anatomy (comparaison, non retenu en M6c) : modèle d'exécution de 5.5.1,
# repris de l'historique git (commit 786e867) dans un dossier ignoré.
ZANATOMY_COMMIT = '786e867'
ZANATOMY_GLB = ROOT / 'assets_secure/clair/zanatomy_mannequin.glb'
ZANATOMY_MAP = ROOT / 'assets_secure/clair/zanatomy_map.json'

OUT_GLB = ROOT / 'assets/anatomy/mannequin.glb'
OUT_MAP = ROOT / 'assets/anatomy/muscles_map.json'
OUT_SKELETON = ROOT / 'assets/anatomy/squelette_mixamo.json'
REPORT = HERE / 'character_report.json'

FBX_SHA256 = 'd1ed4fa2a987dcdc8824e130ac1ad0f4500d78868f2890c5c544fac73ce9f521'
SOURCE_NAME = 'Personnage Mixamo « Ch36 » (Adobe Mixamo, fourni par le propriétaire, 29/09/2026)'
PREFIX = 'mixamorig1:'
TRIANGLE_BUDGET = 30000

# ------------------------------------------------------------------ fit --
# Gonflements (repère glTF, mètres). `limb` : écartement radial autour de
# l'axe de l'os (tête → tête de l'enfant), `s` = gain de tour au sommet du
# profil, profil cos² centré sur `c` (fraction de la longueur), demi-largeur
# `h` ; `back` : part du gain réservée à l'arrière (mollet : jumeaux).
# `bump` : déplacement le long de la normale, `a` = amplitude (m) au
# centre, ellipsoïde de demi-axes `r`, seulement où la normale suit `facing`.
FIT = [
    {'kind': 'limb', 'bone': 'Arm', 's': .09, 'c': .52, 'h': .55},
    {'kind': 'limb', 'bone': 'ForeArm', 's': .07, 'c': .30, 'h': .42},
    {'kind': 'limb', 'bone': 'UpLeg', 's': .07, 'c': .50, 'h': .52},
    {'kind': 'limb', 'bone': 'Leg', 's': .08, 'c': .30, 'h': .34, 'back': .7},
    # Deltoïdes : dôme de l'épaule (centre sous l'acromion, vers le bras).
    {'kind': 'bump', 'name': 'deltoides', 'at': ('Arm', .15), 'r': (.09, .10, .09),
     'a': .016, 'facing': None, 'bones': ('Arm', 'Shoulder')},
    # Pectoraux : devant du thorax, au-dessus du sillon sous-mammaire.
    {'kind': 'bump', 'name': 'pectoraux', 'center': (.095, 1.345, .09), 'r': (.12, .075, .10),
     'a': .017, 'facing': (0, 0, 1)},
    # Grand dorsal : flanc et arrière du thorax sous l'aisselle (V discret),
    # nul à la taille.
    {'kind': 'bump', 'name': 'grand_dorsal', 'center': (.12, 1.27, -.05), 'r': (.09, .13, .10),
     'a': .016, 'facing': (1, 0, -.6)},
    # Haut du dos (trapèze moyen, rhomboïdes, haut du grand dorsal) :
    # épaisseur discrète, nulle à la taille.
    {'kind': 'bump', 'name': 'haut_du_dos', 'center': (.075, 1.33, -.09), 'r': (.12, .11, .09),
     'a': .012, 'facing': (0, 0, -1)},
]
WAIST_Y = (1.02, 1.13)  # tranche de la taille : aucun déplacement toléré

# Pose d'affichage : rotations (degrés) autour d'axes du repère de repos
# (glTF), appliquées à la tête de l'os. Bras abaissés à ~20° de la
# verticale, léger valgus du coude, comme l'écorché de 5.5.2 à 5.5.5.
DISPLAY_POSE = {
    'LeftArm': [((0, 0, 1), -70)], 'RightArm': [((0, 0, 1), 70)],
    'LeftForeArm': [((0, 0, 1), 8)], 'RightForeArm': [((0, 0, 1), -8)],
}

# Six poses extrêmes (contrôle de la déformation, point 2 du lot).
EXTREME_POSES = {
    # Repère de repos (en T) : bras gauche le long de +x ; R_z(−θ) abaisse le
    # bras, R_x(+θ) le porte en arrière (extension), R_y(−θ) fléchit le
    # coude gauche vers l'avant (R_y(+θ) à droite) ; hanche : R_x(−θ) =
    # flexion, genou : R_x(+θ) = flexion.
    'bras_au_dessus_de_la_tete': {
        'LeftArm': [((0, 0, 1), 80)], 'RightArm': [((0, 0, 1), -80)],
    },
    'bas_de_dip': {
        'LeftArm': [((0, 0, 1), -80), ((1, 0, 0), 70)],
        'RightArm': [((0, 0, 1), 80), ((1, 0, 0), 70)],
        'LeftForeArm': [((0, 1, 0), -95)], 'RightForeArm': [((0, 1, 0), 95)],
    },
    'bas_de_squat': {
        'Hips': [((1, 0, 0), 25)],
        'LeftUpLeg': [((1, 0, 0), -120), ((0, 0, 1), -12)],
        'RightUpLeg': [((1, 0, 0), -120), ((0, 0, 1), 12)],
        'LeftLeg': [((1, 0, 0), 125)], 'RightLeg': [((1, 0, 0), 125)],
        'LeftFoot': [((1, 0, 0), -35)], 'RightFoot': [((1, 0, 0), -35)],
        'LeftArm': [((0, 0, 1), -10), ((0, 1, 0), -80)],
        'RightArm': [((0, 0, 1), 10), ((0, 1, 0), 80)],
    },
    'traction_menton_au_dessus': {
        'LeftArm': [((0, 0, 1), -65), ((1, 0, 0), 25)],
        'RightArm': [((0, 0, 1), 65), ((1, 0, 0), 25)],
        'LeftForeArm': [((0, 1, 0), -140)], 'RightForeArm': [((0, 1, 0), 140)],
    },
    'pompe_basse': {
        'LeftArm': [((0, 0, 1), -45), ((1, 0, 0), 55)],
        'RightArm': [((0, 0, 1), 45), ((1, 0, 0), 55)],
        'LeftForeArm': [((0, 1, 0), -95)], 'RightForeArm': [((0, 1, 0), 95)],
    },
    'extension_de_hanche': {
        'LeftUpLeg': [((1, 0, 0), 35)], 'RightUpLeg': [((1, 0, 0), -60)],
        'RightLeg': [((1, 0, 0), 60)], 'LeftLeg': [((1, 0, 0), 10)],
    },
}

# Zones projetées depuis la source : clés retenues (les autres parties de la
# source — os, tendons, tête, muscles profonds — laissent la peau nue).
HAND_BONES = ('Hand', 'HandThumb', 'HandIndex', 'HandMiddle', 'HandRing', 'HandPinky')
FOOT_BONES = ('Foot', 'ToeBase')
HEAD_BONES = ('Head',)
DIFFUSE_PASSES = 4       # passes de diffusion des zones (≈ 1 anneau chacune)
BARE_WEIGHT = .6         # poids de la peau nue dans la diffusion
MIN_ISLAND = 12          # triangles : îlot plus petit rattaché au voisin
MIN_ZONE = 30            # triangles : zone plus petite retirée (peau)
SMOOTH_PASSES = 3        # passes de vote majoritaire sur les frontières
RAY_MARGIN = .025        # m : départ du rayon au-dessus de la peau
RAY_REACH = .07          # m : portée du rayon vers l'intérieur
NEAREST_REACH = .045     # m : repli par surface la plus proche


# ============================================================ utilitaires --

def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def to_gltf(v):
    """Repère de Blender (z en haut, avant = −y) → glTF (y en haut, avant = +z)."""
    import numpy as np
    v = np.asarray(v, dtype=np.float64)
    return np.stack([v[..., 0], v[..., 2], -v[..., 1]], axis=-1)


def rot(axis, deg):
    import numpy as np
    a = np.asarray(axis, dtype=np.float64)
    a = a / np.linalg.norm(a)
    t = math.radians(deg)
    k = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + math.sin(t) * k + (1 - math.cos(t)) * (k @ k)


def vertex_normals(P, F):
    import numpy as np
    n = np.zeros_like(P)
    fn = np.cross(P[F[:, 1]] - P[F[:, 0]], P[F[:, 2]] - P[F[:, 0]])
    for i in range(3):
        np.add.at(n, F[:, i], fn)
    l = np.linalg.norm(n, axis=1, keepdims=True)
    l[l == 0] = 1
    return n / l


def face_pairs(F):
    """Paires de triangles voisins (arête commune)."""
    import numpy as np
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    e.sort(axis=1)
    fid = np.tile(np.arange(len(F)), 3)
    order = np.lexsort((e[:, 1], e[:, 0]))
    e, fid = e[order], fid[order]
    same = (e[1:] == e[:-1]).all(axis=1)
    return np.stack([fid[:-1][same], fid[1:][same]], axis=1)


# ============================================================== personnage --

class Character:
    """Maillage de repos (glTF), poids de peau et os du personnage."""

    def __init__(self, V, F, W, groups, bones):
        self.V, self.F, self.W, self.groups, self.bones = V, F, W, groups, bones
        self.index = {b['name']: i for i, b in enumerate(bones)}

    def weight(self, *suffixes):
        """Somme des poids des groupes dont le nom (sans préfixe) commence
        par l'un des suffixes, côtés compris (`Arm` → LeftArm + RightArm)."""
        import numpy as np
        w = np.zeros(len(self.V))
        for j, g in enumerate(self.groups):
            for s in suffixes:
                if g == s or g in (f'Left{s}', f'Right{s}') or \
                        any(g.startswith(p + s) and g[len(p + s):].isdigit()
                            for p in ('Left', 'Right')):
                    w += self.W[:, j]
                    break
        return w

    def head(self, name):
        return self.bones[self.index[name]]['head']


def load_character(fbx=FBX):
    """Lit le FBX (Blender sans interface)."""
    import bpy
    import numpy as np
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=str(fbx))
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
    m = mesh.data
    m.calc_loop_triangles()
    mw = mesh.matrix_world
    V = to_gltf(np.array([tuple(mw @ v.co) for v in m.vertices]))
    F = np.array([t.vertices[:] for t in m.loop_triangles], dtype=np.int64)
    groups = [g.name.replace(PREFIX, '') for g in mesh.vertex_groups]
    W = np.zeros((len(V), len(groups)))
    for v in m.vertices:
        for g in v.groups:
            W[v.index, g.group] = g.weight
    s = W.sum(1, keepdims=True)
    s[s == 0] = 1
    W /= s
    bones = []
    aw = arm.matrix_world
    for b in arm.data.bones:
        mat = aw @ b.matrix_local
        rot3 = np.array([[mat[i][j] for j in range(3)] for i in range(3)])
        rot3 /= np.linalg.norm(rot3, axis=0, keepdims=True)
        # colonnes du repère de l'os (Blender) → glTF
        axes = to_gltf(rot3.T)
        bones.append({
            'name': b.name.replace(PREFIX, ''),
            'parent': b.parent.name.replace(PREFIX, '') if b.parent else None,
            'head': to_gltf(np.array(tuple(aw @ b.head_local))),
            'tail': to_gltf(np.array(tuple(aw @ b.tail_local))),
            'axes': axes,  # lignes : x, y (le long de l'os), z de l'os
        })
    return Character(V, F, W, groups, bones)


# ============================================================ coutures --

SEAM_ANGLE = 40          # degrés : arête vive = lèvre d'une couture
SEAM_RINGS = 3           # anneaux de voisins lissés autour des coutures
SEAM_PASSES = 30         # passes de lissage (Laplacien, zone des coutures)


def smooth_seams(ch, log=print):
    """Coutures du mannequin Mixamo (sillons et marches à la taille, aux
    épaules, au cou, aux poignets, aux chevilles) : arêtes vives détectées
    par l'angle entre triangles voisins (doigts et visage exclus), lissage
    laplacien limité à une bande autour d'elles, poids décroissant avec la
    distance (en anneaux). Renvoie les positions lissées et le nombre de
    sommets touchés."""
    import numpy as np
    from scipy.sparse import coo_matrix
    V, F = ch.V, ch.F
    fn = np.cross(V[F[:, 1]] - V[F[:, 0]], V[F[:, 2]] - V[F[:, 0]])
    fn /= np.maximum(np.linalg.norm(fn, axis=1, keepdims=True), 1e-12)
    pairs = face_pairs(F)
    ang = np.degrees(np.arccos(np.clip((fn[pairs[:, 0]] * fn[pairs[:, 1]]).sum(1), -1, 1)))
    face = ch.W[:, ch.groups.index('Head')]
    V0 = np.unique(F[np.unique(pairs[ang > SEAM_ANGLE].ravel())].ravel())
    # mains et pieds : seules les coutures du poignet et de la cheville
    # comptent (jamais les plis des doigts ni des orteils) ; visage : seul
    # le bas du cou.
    far = np.zeros(len(V), bool)
    hands = ch.weight(*HAND_BONES)
    feet = ch.weight(*FOOT_BONES)
    for side in ('Left', 'Right'):
        h = ch.head(side + 'Hand')
        ax = h - ch.head(side + 'ForeArm')
        ax /= np.linalg.norm(ax)
        far |= (hands > .3) & ((V - h) @ ax > .02)   # au-delà du poignet
        far |= (feet > .3) & (V[:, 1] < ch.head(side + 'Foot')[1] - .045)
    neck_y = ch.head('Head')[1]
    V0 = V0[~far[V0] & ~((face[V0] > .5) & (V[V0, 1] > neck_y))]
    n = len(V)
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    A = coo_matrix((np.ones(len(e) * 2), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])),
                   shape=(n, n)).tocsr()
    A.data[:] = 1
    deg = np.asarray(A.sum(1)).ravel()
    ring = np.full(n, 99)
    ring[V0] = 0
    front = np.zeros(n, bool)
    front[V0] = True
    for r in range(1, SEAM_RINGS + 1):
        nxt = (A @ front.astype(float)) > 0
        nxt &= ring == 99
        ring[nxt] = r
        front = nxt
    w = np.where(ring <= SEAM_RINGS, 1 - ring / (SEAM_RINGS + 1), 0)
    P = V.copy()
    for _ in range(SEAM_PASSES):
        avg = (A @ P) / deg[:, None]
        P = P + (.5 * w)[:, None] * (avg - P)
    log(f'coutures : {len(V0)} sommets sur les lèvres, {int((w > 0).sum())} lissés, '
        f'déplacement max {np.linalg.norm(P - V, axis=1).max() * 1000:.1f} mm')
    return P, int((w > 0).sum())


# ===================================================================== fit --

def _profile(t, c, h):
    import numpy as np
    u = np.clip((t - c) / h, -1, 1)
    return np.cos(u * math.pi / 2) ** 2


def fit_displacement(ch):
    """Déplacement de chaque sommet de repos (m) et détail par zone."""
    import numpy as np
    V = ch.V
    N = vertex_normals(V, ch.F)
    D = np.zeros_like(V)
    for z in FIT:
        if z['kind'] == 'limb':
            for side in ('Left', 'Right'):
                name = side + z['bone']
                b = ch.bones[ch.index[name]]
                child = next(x for x in ch.bones if x['parent'] == name)
                h0, h1 = b['head'], child['head']
                ax = h1 - h0
                L = np.linalg.norm(ax)
                ax = ax / L
                rel = V - h0
                t = rel @ ax / L
                radial = rel - np.outer(rel @ ax, ax)
                w = ch.W[:, ch.groups.index(name)]
                gain = z['s'] * _profile(t, z['c'], z['h'])
                if 'back' in z:
                    rn = radial / np.maximum(np.linalg.norm(radial, axis=1, keepdims=True), 1e-9)
                    back = np.clip(-rn[:, 2], 0, 1)
                    gain = gain * ((1 - z['back']) + 2 * z['back'] * back) / (1 + z['back'] * 0)
                D += (w * gain)[:, None] * radial
        else:
            for sx in (1, -1):
                if 'at' in z:
                    bone, frac = z['at']
                    name = ('Left' if sx > 0 else 'Right') + bone
                    b = ch.bones[ch.index[name]]
                    child = next(x for x in ch.bones if x['parent'] == name)
                    c = b['head'] + frac * (child['head'] - b['head'])
                else:
                    c = np.array(z['center']) * np.array([sx, 1, 1])
                r = np.array(z['r'])
                q = ((V - c) / r)
                d2 = (q ** 2).sum(1)
                g = np.where(d2 < 1, np.cos(np.sqrt(np.minimum(d2, 1)) * math.pi / 2) ** 2, 0)
                if z.get('facing') is not None:
                    f = np.array(z['facing'], dtype=float) * np.array([sx, 1, 1])
                    f /= np.linalg.norm(f)
                    g = g * np.clip((N @ f - .1) / .5, 0, 1)
                if z.get('bones'):
                    w = sum(ch.W[:, ch.groups.index(('Left' if sx > 0 else 'Right') + b)]
                            for b in z['bones'])
                    g = g * np.clip(w * 2, 0, 1)
                else:
                    # côté du corps : jamais au-delà de la ligne médiane
                    g = g * np.clip(V[:, 0] * sx / .02, 0, 1)
                D += (z['a'] * g)[:, None] * N
    # taille inchangée : aucun déplacement dans la tranche de la taille
    # hors des bras
    arms = ch.weight('Arm', 'ForeArm', 'Hand', *HAND_BONES[1:])
    waist = (V[:, 1] > WAIST_Y[0]) & (V[:, 1] < WAIST_Y[1]) & (arms < .5)
    D[waist] = 0
    return D


# ================================================================= peau --

def skin_matrices(ch, pose):
    """Matrices 3×4 de chaque os pour `pose` (rotations autour d'axes du
    repère de repos, à la tête de l'os ; composées le long de la chaîne)."""
    import numpy as np
    mats = {}
    for b in ch.bones:  # parents avant enfants (ordre du FBX)
        R = np.eye(3)
        for axis, deg in pose.get(b['name'], []):
            R = rot(axis, deg) @ R
        h = b['head']
        local = np.eye(4)
        local[:3, :3] = R
        local[:3, 3] = h - R @ h
        parent = mats.get(b['parent'], np.eye(4))
        mats[b['name']] = parent @ local
    return mats


def skin(ch, P, pose):
    """Peau linéaire des positions P (repos, modifiées ou non) pour `pose`."""
    import numpy as np
    mats = skin_matrices(ch, pose)
    out = np.zeros_like(P)
    Ph = np.concatenate([P, np.ones((len(P), 1))], axis=1)
    for j, g in enumerate(ch.groups):
        w = ch.W[:, j]
        m = w > 0
        if not m.any():
            continue
        M = mats[g]
        out[m] += w[m, None] * (Ph[m] @ M[:3].T)
    return out


# ============================================================ mesures --

def section_perimeter(P, F, origin, normal, keep):
    """Tour (m) : enveloppe convexe de la section du maillage par le plan
    (origine, normale), limitée aux points retenus par `keep(points)`
    (comme un mètre ruban)."""
    import numpy as np
    from scipy.spatial import ConvexHull
    n = np.asarray(normal, dtype=float)
    n /= np.linalg.norm(n)
    d = (P - origin) @ n
    pts = []
    for i, j in ((0, 1), (1, 2), (2, 0)):
        a, b = F[:, i], F[:, j]
        m = (d[a] * d[b]) < 0
        t = d[a[m]] / (d[a[m]] - d[b[m]])
        pts.append(P[a[m]] + (P[b[m]] - P[a[m]]) * t[:, None])
    pts = np.concatenate(pts)
    pts = pts[keep(pts)]
    if len(pts) < 3:
        return 0.0
    u = np.cross(n, [0, 1, 0] if abs(n[1]) < .9 else [1, 0, 0])
    u /= np.linalg.norm(u)
    v = np.cross(n, u)
    q = np.stack([(pts - origin) @ u, (pts - origin) @ v], axis=1)
    hull = ConvexHull(q)
    return float(hull.area)  # en 2D, « area » = périmètre


def measures(ch, P_rest, P_display):
    """Tours (cm) sur le repos (bras, avant-bras, cuisse, mollet : plans
    perpendiculaires aux os, côté gauche) et sur la pose d'affichage
    (poitrine, taille : plans horizontaux ; largeur d'épaules)."""
    import numpy as np
    F = ch.F
    out = {}

    def limb(name, frac):
        b = ch.bones[ch.index[name]]
        child = next(x for x in ch.bones if x['parent'] == name)
        o = b['head'] + frac * (child['head'] - b['head'])
        ax = child['head'] - b['head']
        return section_perimeter(P_rest, F, o, ax,
                                 lambda p: (np.linalg.norm(p - o, axis=1) < .13)
                                 & (p[:, 0] * o[0] > 0))

    out['bras'] = limb('LeftArm', .55)
    out['avant_bras'] = limb('LeftForeArm', .30)
    out['cuisse'] = limb('LeftUpLeg', .40)
    out['mollet'] = limb('LeftLeg', .30)
    arms = ch.weight('Arm', 'ForeArm', 'Hand', *HAND_BONES[1:]) > .5

    def torso(y):
        o = np.array([0, y, 0.0])
        return section_perimeter(P_display[~arms], _faces_of(F, ~arms), o, (0, 1, 0),
                                 lambda p: np.abs(p[:, 0]) < .22)

    out['poitrine'] = torso(1.32)
    out['taille'] = torso(1.08)
    band = (P_display[:, 1] > 1.33) & (P_display[:, 1] < 1.46)
    out['largeur_epaules'] = float(P_display[band, 0].max() - P_display[band, 0].min())
    return {k: round(v * 100, 1) for k, v in out.items()}


def _faces_of(F, keep_vertices):
    """Triangles dont les trois sommets sont gardés, réindexés."""
    import numpy as np
    idx = np.cumsum(keep_vertices) - 1
    m = keep_vertices[F].all(axis=1)
    return idx[F[m]]


# ============================================================ sources --

def read_glb(path):
    """Positions et indices de chaque nœud à maillage d'un GLB (repère du
    fichier, transformations de nœuds ignorées : sources écrites à plat)."""
    import numpy as np
    import struct
    data = Path(path).read_bytes()
    json_len = struct.unpack('<I', data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    blob = data[20 + json_len + 8:]
    kinds = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}

    def read(i):
        acc = gltf['accessors'][i]
        view = gltf['bufferViews'][acc['bufferView']]
        n = {'VEC3': 3, 'SCALAR': 1, 'VEC4': 4, 'VEC2': 2}[acc['type']]
        return np.frombuffer(blob, dtype=kinds[acc['componentType']], count=acc['count'] * n,
                             offset=view['byteOffset'] + acc.get('byteOffset', 0))

    out = {}
    for node in gltf['nodes']:
        if 'mesh' not in node:
            continue
        ps, ids, base = [], [], 0
        for prim in gltf['meshes'][node['mesh']]['primitives']:
            p = read(prim['attributes']['POSITION']).reshape(-1, 3).astype(np.float64)
            i = read(prim['indices']).astype(np.int64)
            ps.append(p)
            ids.append(i + base)
            base += len(p)
        out[node['name']] = (np.concatenate(ps), np.concatenate(ids).reshape(-1, 3))
    return out


def load_source(kind):
    """Régions de la source : {nom de nœud: (positions, triangles)}, carte
    des régions {id: entrée}, et nom de la source."""
    glb, mp = (ECORCHE_GLB, ECORCHE_MAP) if kind == 'ecorche' else (ZANATOMY_GLB, ZANATOMY_MAP)
    if kind == 'zanatomy' and not glb.exists():
        import subprocess
        glb.parent.mkdir(parents=True, exist_ok=True)
        for src, dst in (('assets/anatomy/mannequin.glb', glb),
                         ('assets/anatomy/muscles_map.json', mp)):
            dst.write_bytes(subprocess.run(['git', 'show', f'{ZANATOMY_COMMIT}:{src}'], cwd=ROOT,
                                           check=True, capture_output=True).stdout)
    meshes = read_glb(glb)
    mapping = json.loads(mp.read_text(encoding='utf-8'))
    regions = {r['id']: r for r in mapping['regions']}
    return meshes, regions, mapping


def source_landmarks(meshes, regions):
    """Repères de la source (repère glTF) mesurés sur ses régions : hauteur
    des épaules, coudes, poignets, hanches, genoux, chevilles, sommet."""
    import numpy as np

    def pts(*keys):
        arr = [meshes[k][0] for k in keys if k in meshes]
        return np.concatenate(arr) if arr else None

    allp = np.concatenate([p for p, _ in meshes.values()])
    top = allp[:, 1].max()
    return {'top': top, 'all': allp, 'pts': pts}


# ======================================================== recalage --

def body_levels(P, ch=None):
    """Niveaux (y) d'un corps debout : sol, chevilles, genoux, hanches,
    épaules, sommet — sur le personnage, depuis ses os."""
    b = ch.head
    return {
        'sol': 0.0,
        'cheville': (b('LeftFoot')[1] + b('RightFoot')[1]) / 2,
        'genou': (b('LeftLeg')[1] + b('RightLeg')[1]) / 2,
        'hanche': (b('LeftUpLeg')[1] + b('RightUpLeg')[1]) / 2,
        'epaule': (b('LeftArm')[1] + b('RightArm')[1]) / 2,
        'sommet': float(P[:, 1].max()),
    }


def source_levels(meshes, kind):
    """Mêmes niveaux sur la source, mesurés sur ses régions."""
    import numpy as np

    def get(names):
        arr = [meshes[n][0] for n in names if n in meshes]
        return np.concatenate(arr) if arr else None

    allp = np.concatenate([p for p, _ in meshes.values()])
    foot = get(['foot_left', 'foot_right'])
    gast = get(['gastrocnemius_medial_left', 'gastrocnemius_lateral_left',
                'gastrocnemius_medial_right', 'gastrocnemius_lateral_right'])
    vm = get(['vastus_medialis_left', 'vastus_medialis_right'])
    glut = get(['gluteus_medius_left', 'gluteus_medius_right'])
    tfl = get(['tensor_fasciae_latae_left', 'tensor_fasciae_latae_right'])
    delt = get(['deltoid_lateral_left', 'deltoid_lateral_right'])
    lv = {
        'sol': float(allp[:, 1].min()),
        'cheville': float(foot[:, 1].max()) - .01,
        # genou : bas du vaste médial (juste au-dessus de l'interligne) et
        # haut des jumeaux (juste au-dessous)
        'genou': float((vm[:, 1].min() + gast[:, 1].max()) / 2),
        # hanche (centre de la tête fémorale) : bas du tenseur du fascia lata
        # et du moyen fessier
        'hanche': float((tfl[:, 1].min() * .5 + glut[:, 1].min() * .5)),
        'epaule': float(delt[:, 1].max()) - .045,
        'sommet': float(allp[:, 1].max()),
    }
    return lv


def register_source(meshes, lv_src, lv_ch, width_ratio):
    """Recale la source sur le personnage : hauteur par morceaux entre les
    niveaux, largeur et profondeur par un facteur global."""
    import numpy as np
    keys = ['sol', 'cheville', 'genou', 'hanche', 'epaule', 'sommet']
    xs = np.array([lv_src[k] for k in keys])
    ys = np.array([lv_ch[k] for k in keys])
    out = {}
    for name, (p, f) in meshes.items():
        q = p.copy()
        q[:, 1] = np.interp(p[:, 1], xs, ys, left=None, right=None)
        q[:, 0] *= width_ratio[0]
        q[:, 2] *= width_ratio[1]
        out[name] = (q, f)
    return out


# =========================================================== projection --

# Segments comparés pour ajuster la pose du personnage à celle de la source
# (axe principal des sommets du segment / des régions de la source).
SEGMENTS = [
    # (os du personnage, clés des régions de la source)
    ('Arm', ('biceps_brachii', 'biceps_brachii_long', 'biceps_brachii_short', 'brachialis',
             'triceps_brachii', 'triceps_long', 'triceps_lateral')),
    ('ForeArm', ('brachioradialis_muscle', 'flexor_carpi_radialis', 'flexor_carpi_ulnaris',
                 'extensor_digitorum', 'extensor_carpi_ulnaris', 'extensor_carpi_radialis_longus',
                 'extensor_carpi_radialis_brevis', 'flexor_digitorum_superficialis',
                 'palmaris_longus_muscle', 'humeral_head_of_flexor_carpi_ulnaris',
                 'ulnar_head_of_flexor_carpi_ulnaris', 'ulnar_head_of_extensor_carpi_ulnaris',
                 'humeral_head_of_extensor_carpi_ulnaris')),
    ('UpLeg', ('rectus_femoris', 'vastus_lateralis', 'vastus_medialis', 'biceps_femoris_long',
               'semitendinosus', 'sartorius', 'adductor_longus', 'gracilis')),
    ('Leg', ('gastrocnemius_medial', 'gastrocnemius_lateral', 'soleus', 'tibialis_anterior',
             'fibularis_longus', 'extensor_digitorum_longus')),
]


def _axis(points, ref):
    """Axe principal d'un nuage, orienté comme `ref`."""
    import numpy as np
    c = points.mean(0)
    _, _, vt = np.linalg.svd(points - c, full_matrices=False)
    a = vt[0]
    return a if a @ ref >= 0 else -a


def _align(u, v):
    """Rotation minimale qui amène le vecteur unitaire u sur v."""
    import numpy as np
    c = np.cross(u, v)
    s = np.linalg.norm(c)
    d = float(np.clip(u @ v, -1, 1))
    if s < 1e-9:
        return np.eye(3)
    return rot(c / s, math.degrees(math.atan2(s, d)))


def match_pose(ch, Vfit, meshes, regions, base_pose):
    """Pose du personnage dont les bras et les jambes suivent ceux de la
    source (axe principal de chaque segment), à partir de `base_pose`."""
    import numpy as np
    pose = {k: list(v) for k, v in base_pose.items()}
    detail = {}
    for bone, keys in SEGMENTS[:2]:  # bras seulement (jambes déjà droites)
        for side, sname in (('Left', 'left'), ('Right', 'right')):
            name = side + bone
            pts = [meshes[f'{k}_{sname}'][0] for k in keys if f'{k}_{sname}' in meshes]
            if not pts:
                continue
            target_pts = np.concatenate(pts)
            mats = skin_matrices(ch, pose)
            P = skin(ch, Vfit, pose)
            w = ch.W[:, ch.groups.index(name)]
            seg = P[w > .7]
            b = ch.bones[ch.index[name]]
            child = next(x for x in ch.bones if x['parent'] == name)
            M = mats[name]
            ref = M[:3, :3] @ (child['head'] - b['head'])
            cur = _axis(seg, ref)
            tgt = _axis(target_pts, ref)
            Rw = _align(cur, tgt)
            # rotation locale (axes du repère de repos) : R_parent⁻¹ Rw R_parent
            Rp = mats[b['parent']][:3, :3] if b['parent'] in mats else np.eye(3)
            Rl = Rp.T @ Rw @ Rp
            ang = math.degrees(math.acos(np.clip((np.trace(Rl) - 1) / 2, -1, 1)))
            if ang > .5:
                w_, v_ = np.linalg.eig(Rl)
                ax = np.real(v_[:, np.argmin(np.abs(w_ - 1))])
                if (rot(ax, ang) - Rl).__abs__().max() > 1e-6:
                    ax = -ax
                # la rotation s'ajoute après celles déjà présentes
                pose[name] = pose.get(name, []) + [(tuple(float(x) for x in ax), ang)]
            detail[name] = round(ang, 1)
    return pose, detail


def morph_to_source(P, F, src_all, log, schedule=((60, .10), (25, .08), (10, .06), (4, .05),
                                                   (2, .04))):
    """Recalage non rigide : le personnage (copie) est attiré vers la
    surface la plus proche de la source, champ de déplacement lissé sur le
    maillage (raideur décroissante). Sert seulement à lire les zones."""
    import numpy as np
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    from scipy.sparse import coo_matrix, diags
    from scipy.sparse.linalg import spsolve
    Vs, Fs = src_all
    Ns = np.cross(Vs[Fs[:, 1]] - Vs[Fs[:, 0]], Vs[Fs[:, 2]] - Vs[Fs[:, 0]])
    Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-12)
    bvh = BVHTree.FromPolygons([tuple(v) for v in Vs], [tuple(int(i) for i in t) for t in Fs],
                               all_triangles=True)
    n = len(P)
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    A = coo_matrix((np.ones(len(e) * 2), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])),
                   shape=(n, n)).tocsr()
    A.data[:] = 1
    L = diags(np.asarray(A.sum(1)).ravel()) - A
    Q = P.copy()
    for mu, reach in schedule:
        N = vertex_normals(Q, F)
        T = np.zeros_like(Q)
        w = np.zeros(n)
        for i in range(n):
            loc, _, idx, dist = bvh.find_nearest(Vector(Q[i]), reach)
            if idx is None or Ns[idx] @ N[i] < .3:
                continue
            T[i] = np.array(loc) - Q[i]
            w[i] = 1
        M = diags(w) + mu * L
        D = np.stack([spsolve(M.tocsc(), w * T[:, k]) for k in range(3)], axis=1)
        Q = Q + D
        log(f'  recalage non rigide μ={mu} : {int(w.sum())} sommets appariés, '
            f'écart moyen {np.linalg.norm(T[w > 0], axis=1).mean() * 1000:.0f} mm')
    return Q


def project_labels(Q, F, src, keep_region, key_of):
    """Zone de chaque sommet recalé : triangle de la source le plus proche
    (normales compatibles ; sinon rayon vers l'intérieur), à portée. Renvoie
    la clé (sans côté) de chaque sommet ('' : peau nue)."""
    import numpy as np
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree
    names = sorted(src)
    verts, tris, lab = [], [], []
    base = 0
    for n in names:
        p, f = src[n]
        verts.append(p)
        tris.append(f + base)
        base += len(p)
        lab += [key_of(n) if keep_region(n) else ''] * len(f)
    Vs = np.concatenate(verts)
    Fs = np.concatenate(tris)
    lab = np.array(lab, dtype=object)
    Ns = np.cross(Vs[Fs[:, 1]] - Vs[Fs[:, 0]], Vs[Fs[:, 2]] - Vs[Fs[:, 0]])
    Ns /= np.maximum(np.linalg.norm(Ns, axis=1, keepdims=True), 1e-12)
    bvh = BVHTree.FromPolygons([tuple(v) for v in Vs], [tuple(int(i) for i in t) for t in Fs],
                               all_triangles=True)
    N = vertex_normals(Q, F)
    out = np.full(len(Q), '', dtype=object)
    how = Counter()
    for i in range(len(Q)):
        loc, _, idx, dist = bvh.find_nearest(Vector(Q[i]), NEAREST_REACH)
        if idx is None:
            how['aucune'] += 1
            continue
        if Ns[idx] @ N[i] < 0:
            # face opposée (creux entre deux muscles) : rayon vers l'intérieur
            hit = bvh.ray_cast(Vector(Q[i] + N[i] * RAY_MARGIN), Vector(-N[i]),
                               RAY_MARGIN + RAY_REACH)
            if hit[0] is None or Ns[hit[2]] @ N[i] < 0:
                how['aucune'] += 1
                continue
            idx = hit[2]
            how['rayon'] += 1
        else:
            how['proche'] += 1
        out[i] = lab[idx]
    return out, dict(how)


def diffuse_labels(F, vkeys, passes=DIFFUSE_PASSES, bare_weight=BARE_WEIGHT, boost=None):
    """Frontières régulières : chaque clé devient un champ (1 sur ses
    sommets), diffusé sur le maillage (moyenne des voisins, `passes` fois) ;
    la peau nue pèse moins (les fentes étroites entre deux muscles de la
    source se referment). Clé de chaque triangle = champ le plus fort au
    centre (moyenne de ses trois sommets)."""
    import numpy as np
    from scipy.sparse import coo_matrix, diags
    n = len(vkeys)
    keys = sorted(set(vkeys))
    idx = {k: i for i, k in enumerate(keys)}
    X = np.zeros((n, len(keys)))
    X[np.arange(n), [idx[k] for k in vkeys]] = 1
    if '' in idx:
        X[:, idx['']] *= bare_weight
    for k, b in (boost or {}).items():
        if k in idx:
            X[:, idx[k]] *= b
    e = np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]])
    A = coo_matrix((np.ones(len(e) * 2), (np.r_[e[:, 0], e[:, 1]], np.r_[e[:, 1], e[:, 0]])),
                   shape=(n, n)).tocsr()
    A.data[:] = 1
    A = A + diags(np.ones(n))
    A = diags(1 / np.asarray(A.sum(1)).ravel()) @ A
    for _ in range(passes):
        X = A @ X
    T = X[F].mean(axis=1)
    return np.array([keys[i] for i in T.argmax(1)], dtype=object)


def region_key(node_name, regions):
    r = regions.get(node_name)
    return r['cle'] if r else None


def clean_labels(P, F, keys, log, protected=frozenset()):
    """Frontières lissées (vote majoritaire des voisins), îlots rattachés
    au voisin qui partage le plus d'arêtes, zones minuscules retirées."""
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    pairs = face_pairs(F)
    nb = [[] for _ in range(len(F))]
    for a, b in pairs:
        nb[a].append(b)
        nb[b].append(a)
    keys = keys.copy()
    for _ in range(SMOOTH_PASSES):
        new = keys.copy()
        for t in range(len(F)):
            votes = Counter(keys[j] for j in nb[t])
            votes[keys[t]] += 1
            top, cnt = votes.most_common(1)[0]
            if top != keys[t] and cnt >= 3:
                new[t] = top
        keys = new
    # îlots
    for _ in range(4):
        same = keys[pairs[:, 0]] == keys[pairs[:, 1]]
        g = coo_matrix((np.ones(same.sum()), (pairs[same, 0], pairs[same, 1])),
                       shape=(len(F), len(F)))
        n, comp = connected_components(g, directed=False)
        size = np.bincount(comp)
        # plus grande composante de chaque clé
        biggest = {}
        for c in range(n):
            k = keys[np.argmax(comp == c)]
            biggest[k] = max(biggest.get(k, 0), size[c])
        changed = 0
        for c in np.nonzero(size < MIN_ISLAND * 4)[0]:
            faces = np.nonzero(comp == c)[0]
            k = keys[faces[0]]
            if size[c] >= MIN_ISLAND and size[c] >= .35 * biggest[k]:
                continue
            if k in protected and size[c] == biggest[k]:
                continue
            m = np.isin(pairs, faces)
            neigh = np.concatenate([pairs[m[:, 0], 1], pairs[m[:, 1], 0]])
            names = [keys[f] for f in neigh if keys[f] != k]
            if names:
                keys[faces] = Counter(names).most_common(1)[0][0]
                changed += 1
        if not changed:
            break
    cnt = Counter(keys)
    for k, c in cnt.items():
        if k and c < MIN_ZONE and k not in protected:
            keys[keys == k] = ''
    log(f'zones : {len(set(keys)) - (1 if "" in set(keys) else 0)} clés après nettoyage')
    return keys


# ================================================================ build --

def assign(ch, Vfit, source_kind, log):
    """Clé de zone de chaque triangle du personnage."""
    import numpy as np
    meshes, regions, mapping = load_source(source_kind)
    pose, detail = match_pose(ch, Vfit, meshes, regions, DISPLAY_POSE)
    log(f'pose ajustée à la source {source_kind} (degrés ajoutés) : {detail}')
    P = skin(ch, Vfit, pose)
    lv_ch = body_levels(P, ch)
    lv_src = source_levels(meshes, source_kind)
    log(f'niveaux source {dict((k, round(v, 3)) for k, v in lv_src.items())} → personnage '
        f'{dict((k, round(v, 3)) for k, v in lv_ch.items())}')
    src = register_source(meshes, lv_src, lv_ch, (1.0, 1.0))
    verts, tris, base = [], [], 0
    for p, f in src.values():
        verts.append(p)
        tris.append(f + base)
        base += len(p)
    Q = morph_to_source(P, ch.F, (np.concatenate(verts), np.concatenate(tris)), log)

    def keep(name):
        r = regions.get(name)
        return r is not None and r['couche'] == 'superficiel'

    vkeys, how = project_labels(Q, ch.F, src, keep, lambda n: regions[n]['cle'])
    log(f'projection (sommets) : {how}')
    keys = diffuse_labels(ch.F, vkeys)
    # muscles superficiels du pack (petits : anconé, rond pronateur, petit
    # rond, chef abdominal du grand pectoral) : jamais effacés par la
    # diffusion ; leurs triangles de la projection brute sont rétablis.
    pack = pack_muscles()
    protected = {k for k, packs in PACK_OF_KEY.items()
                 if any(pack.get(p, ('', ''))[1] == 'superficiel' for p in packs)}
    boost = {}
    for _ in range(4):
        cnt = Counter(keys)
        small = [k for k in sorted(protected & set(vkeys)) if cnt.get(k, 0) < 40]
        if not small:
            break
        for k in small:
            boost[k] = boost.get(k, 1.0) * 1.8
        keys = diffuse_labels(ch.F, vkeys, boost=boost)
    restored = {k: int((keys == k).sum()) for k in boost}
    log(f'petits muscles rétablis : {restored}')
    # tête, mains, pieds par les poids de peau (moyenne des sommets)
    Wf = lambda *s: ch.weight(*s)[ch.F].mean(axis=1)  # noqa: E731
    keys[Wf(*HEAD_BONES) > .5] = 'HEAD'
    keys[Wf(*HAND_BONES) > .5] = 'hand_intrinsic'
    keys[Wf(*FOOT_BONES) > .5] = 'foot_intrinsic'
    keys = clean_labels(P, ch.F, keys, log, protected)
    keys = mirror_labels(ch, keys, log)
    return keys, {'pose_source': detail, 'niveaux_source': lv_src, 'niveaux_personnage': lv_ch,
                  'projection': how, 'source_map': mapping, 'morph': Q}


def mirror_labels(ch, keys, log):
    """Zones symétriques : le maillage de Ch36 est symétrique (chaque sommet
    a son miroir x → −x à moins de 0,5 mm) ; chaque triangle du côté droit
    reçoit la zone de son miroir du côté gauche."""
    import numpy as np
    from scipy.spatial import cKDTree
    V, F = ch.V, ch.F
    d, mv = cKDTree(V).query(V * np.array([-1, 1, 1]))
    tri = {tuple(sorted(f)): t for t, f in enumerate(F.tolist())}
    C = V[F].mean(axis=1)
    out = keys.copy()
    moved = 0
    for t, f in enumerate(F.tolist()):
        if C[t, 0] < -1e-4:
            m = tri.get(tuple(sorted(mv[f])))
            if m is not None and d[f].max() < .002:
                if out[t] != keys[m]:
                    moved += 1
                out[t] = keys[m]
    log(f'symétrie : {moved} triangles du côté droit alignés sur le gauche')
    return out


def node_names(P, F, keys):
    """Nom de nœud de chaque triangle : `<clé>_<côté>` (côté par la position
    du centre du triangle : x > 0 = gauche anatomique), `head`, `peau`."""
    import numpy as np
    C = P[F].mean(axis=1)
    out = np.empty(len(F), dtype=object)
    for t, k in enumerate(keys):
        if k == 'HEAD':
            out[t] = 'head'
        elif not k:
            out[t] = 'peau'
        else:
            # mains et pieds : nœuds `hand_<côté>` / `foot_<côté>` (ids de
            # la carte depuis M2)
            k = {'hand_intrinsic': 'hand', 'foot_intrinsic': 'foot'}.get(k, k)
            out[t] = f"{k}_{'left' if C[t, 0] >= 0 else 'right'}"
    return out


def build(source_kind='ecorche', render_dir=None, poses_dir=None, log=print):
    import numpy as np
    sys.path.insert(0, str(HERE))
    import build_model
    fbx_sha = sha256(FBX)
    if fbx_sha != FBX_SHA256:
        raise SystemExit(f'FBX inattendu : {fbx_sha}')
    ch = load_character()
    log(f'personnage : {len(ch.V)} sommets, {len(ch.F)} triangles, {len(ch.bones)} os, '
        f'{len(ch.groups)} groupes')
    ch.V, seam_count = smooth_seams(ch, log)
    D = fit_displacement(ch)
    Vfit = ch.V + D
    Pd0 = skin(ch, ch.V, DISPLAY_POSE)
    Pd = skin(ch, Vfit, DISPLAY_POSE)
    before = measures(ch, ch.V, Pd0)
    after = measures(ch, Vfit, Pd)
    gains = {k: round(100 * (after[k] / before[k] - 1), 1) for k in before}
    log(f'mesures avant {before}')
    log(f'mesures après {after}')
    log(f'gains (%) {gains}')
    keys, info = assign(ch, Vfit, source_kind, log)
    names = node_names(Pd, ch.F, keys)
    normals = vertex_normals(Pd, ch.F)
    meshes = build_model.split_meshes(Pd, ch.F, names, normals)
    # régions
    regions = region_entries(sorted(set(names)))
    build_model.add_areas(regions, {m['nom']: (m['positions'], m['indices']) for m in meshes})
    add_projected_areas(regions, meshes)
    write_glb(OUT_GLB, meshes)
    pack = pack_muscles()
    covered = {p for r in regions for p in r['pack']}
    mapping = {
        'schema': 3,
        'source': {
            'nom': SOURCE_NAME, 'fichier': 'assets_secure/character_mixamo_ch36.fbx.enc',
            'sha256': FBX_SHA256,
            'licence': 'Adobe Mixamo (conditions d\'utilisation d\'Adobe), chiffré dans le dépôt',
            'zones': {
                'ecorche': 'Ecorche Musclenames Male Anatomy (écorché acheté, 136 régions)',
                'zanatomy': 'Z-Anatomy / BodyParts3D (CC BY-SA 4.0, 218 régions)',
            }[source_kind],
            'zones_source': source_kind,
        },
        'groupes': APP_GROUPS,
        'triangles': int(len(ch.F)),
        'regions': regions,
        'retirees': [],
        'caches_au_repos': [],
        'muscles_sans_region': sorted(set(pack) - covered),
    }
    OUT_MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    write_skeleton(ch)
    tris = Counter(names)
    report = {
        'source': {'fichier': 'assets_secure/character_mixamo_ch36.fbx.enc', 'sha256': FBX_SHA256},
        'zones_source': source_kind,
        'coutures_lissees_sommets': seam_count,
        'personnage': {'sommets': int(len(ch.V)), 'triangles': int(len(ch.F)),
                       'os': len(ch.bones), 'groupes': len(ch.groups)},
        'fit': {'mesures_avant_cm': before, 'mesures_apres_cm': after, 'gains_pct': gains,
                'deplacement_max_mm': round(float(np.linalg.norm(D, axis=1).max()) * 1000, 1)},
        'recalage': {'pose_source_deg': info['pose_source'], 'niveaux_source': info['niveaux_source'],
                     'niveaux_personnage': info['niveaux_personnage']},
        'projection': info['projection'],
        'triangles': {'total': int(len(ch.F)), 'par_noeud': {k: int(v) for k, v in sorted(tris.items())}},
        'regions': len(regions),
        'glb_octets': OUT_GLB.stat().st_size,
    }
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1, default=float) + '\n',
                      encoding='utf-8')
    log(f'GLB {OUT_GLB.stat().st_size} octets, {len(regions)} régions, '
        f'{tris.get("peau", 0)} triangles de peau nue')
    if render_dir:
        render_views(Pd, ch.F, names, Path(render_dir), f'zones_{source_kind}', log)
    if poses_dir:
        render_poses(ch, Vfit, Path(poses_dir), log)
    return report


def region_entries(names):
    pack = pack_muscles()
    out = []
    for name in names:
        if name in ('head', 'peau'):
            continue
        key, side = name.rsplit('_', 1)
        key = {'hand': 'hand_intrinsic', 'foot': 'foot_intrinsic'}.get(key, key)
        packs = PACK_OF_KEY[key]
        group = pack[packs[0]][0] if packs else GROUP_OF_KEY[key]
        couche = 'volume' if key in ('hand_intrinsic', 'foot_intrinsic') else 'superficiel'
        out.append({'id': name, 'cle': key, 'cote': side, 'nom': FR[key],
                    'nom_cote': f'{FR[key]} ({SIDE_FR[side]})', 'groupe': group,
                    'pack': packs, 'couche': couche})
    return out


def add_projected_areas(entries, meshes):
    """M6c : aire de chaque zone vue de face (projetée sur le plan frontal,
    triangles tournés vers +z) et vue de dos (tournés vers −z), m² : ce que
    montrent les vues Face et Dos (vue de départ des fiches)."""
    import numpy as np
    by = {m['nom']: m for m in meshes}
    for e in entries:
        m = by[e['id']]
        p, f = m['positions'], m['indices'].reshape(-1, 3)
        c = np.cross(p[f[:, 1]] - p[f[:, 0]], p[f[:, 2]] - p[f[:, 0]]) / 2
        e['aire_face'] = round(float(np.clip(c[:, 2], 0, None).sum()), 5)
        e['aire_dos'] = round(float(np.clip(-c[:, 2], 0, None).sum()), 5)
    return entries


MATERIALS = [
    {'name': 'peau', 'pbrMetallicRoughness': {'baseColorFactor': [.62, .59, .59, 1],
                                              'metallicFactor': 0, 'roughnessFactor': .78}},
    {'name': 'sombre', 'pbrMetallicRoughness': {'baseColorFactor': [.18, .16, .16, 1],
                                                'metallicFactor': 0, 'roughnessFactor': .85}},
]


def write_glb(path, meshes):
    """GLB : un nœud par zone, matériau gris mat (tête, mains, pieds :
    gris sombre)."""
    import numpy as np
    import struct
    chunks, views, accessors = [], [], []
    offset = 0

    def add(arr, target, **acc):
        nonlocal offset
        data = np.ascontiguousarray(arr).tobytes()
        pad = (-len(data)) % 4
        views.append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(data),
                      'target': target})
        chunks.append(data + b'\0' * pad)
        offset += len(data) + pad
        accessors.append(dict(bufferView=len(views) - 1, **acc))
        return len(accessors) - 1

    nodes, gl_meshes = [], []
    for k, m in enumerate(meshes):
        pos = m['positions'].astype(np.float32)
        attrs = {
            'POSITION': add(pos, 34962, componentType=5126, count=len(pos), type='VEC3',
                            min=[float(v) for v in pos.min(0)],
                            max=[float(v) for v in pos.max(0)]),
            'NORMAL': add(m['normales'].astype(np.float32), 34962, componentType=5126,
                          count=len(pos), type='VEC3'),
        }
        idx = m['indices']
        itype = 5125 if idx.max() > 65535 else 5123
        ind = add(idx.astype(np.uint32 if itype == 5125 else np.uint16), 34963,
                  componentType=itype, count=len(idx), type='SCALAR')
        dark = m['nom'] == 'head' or m['nom'].startswith(('hand_', 'foot_'))
        gl_meshes.append({'name': m['nom'], 'primitives': [
            {'attributes': attrs, 'indices': ind, 'material': 1 if dark else 0}]})
        nodes.append({'name': m['nom'], 'mesh': k})
    gltf = {
        'asset': {'version': '2.0', 'generator': 'Kalis Track tools/anatomy/build_character.py (M6c)'},
        'scene': 0, 'scenes': [{'name': 'Mannequin', 'nodes': list(range(len(meshes)))}],
        'nodes': nodes, 'meshes': gl_meshes, 'materials': MATERIALS,
        'accessors': accessors, 'bufferViews': views, 'buffers': [{'byteLength': offset}],
    }
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    blob = b''.join(chunks)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<I4s', len(js), b'JSON'))
        f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0'))
        f.write(blob)


def write_skeleton(ch):
    """Squelette Mixamo pour le code (M7) : noms (sans préfixe), parents,
    têtes et queues de repos (pose en T, repère glTF, mètres), repères des
    os, et pose d'affichage du mannequin fixe."""
    bones = []
    for b in ch.bones:
        bones.append({
            'nom': b['name'], 'parent': b['parent'],
            'tete': [round(float(x), 5) for x in b['head']],
            'queue': [round(float(x), 5) for x in b['tail']],
            'axes': [[round(float(x), 5) for x in row] for row in b['axes']],
        })
    data = {
        'schema': 1,
        'prefixe_fbx': PREFIX,
        'repere': 'glTF : y en haut, avant = +z, gauche anatomique = +x ; mètres',
        'pose_de_repos': 'T (bras à l\'horizontale), pose de liaison de la peau',
        'os': bones,
        'pose_affichage': {
            'description': 'rotations (degrés) autour d\'axes du repère de repos, à la tête de '
                           'l\'os, composées le long de la chaîne ; le GLB d\'exécution est '
                           'le maillage « fit » posé ainsi',
            'rotations': {k: [[list(a), d] for a, d in v] for k, v in DISPLAY_POSE.items()},
        },
    }
    OUT_SKELETON.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


# ============================================================== rendus --

PALETTE = [(230, 25, 75), (60, 180, 75), (255, 225, 25), (0, 130, 200), (245, 130, 48),
           (145, 30, 180), (70, 240, 240), (240, 50, 230), (210, 245, 60), (250, 190, 212),
           (0, 128, 128), (220, 190, 255), (170, 110, 40), (255, 250, 200), (128, 0, 0),
           (170, 255, 195), (128, 128, 0), (255, 215, 180), (0, 0, 128), (128, 128, 255)]


def _blender_scene(size=(520, 720)):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    cam = bpy.data.objects.new('cam', bpy.data.cameras.new('cam'))
    sc.collection.objects.link(cam)
    sc.camera = cam
    cam.data.type = 'ORTHO'
    for rot_z, energy in ((35, 3.0), (-140, 1.2)):
        sun = bpy.data.objects.new('sun', bpy.data.lights.new('sun', 'SUN'))
        sc.collection.objects.link(sun)
        sun.data.energy = energy
        sun.rotation_euler = (math.radians(55), 0, math.radians(rot_z))
    sc.world = bpy.data.worlds.new('w')
    sc.world.color = (.22, .22, .22)
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 12
    sc.cycles.device = 'CPU'
    sc.render.resolution_x, sc.render.resolution_y = size
    return sc, cam


def _add_mesh(P, F, colors=None, name='m'):
    """Maillage Blender depuis le repère glTF, couleur par triangle."""
    import bpy
    import numpy as np
    Vb = np.stack([P[:, 0], -P[:, 2], P[:, 1]], axis=1)
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in Vb], [], [tuple(int(i) for i in f) for f in F])
    me.polygons.foreach_set('use_smooth', [True] * len(me.polygons))
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mat = bpy.data.materials.new(name + '_mat')
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Roughness'].default_value = .8
    if colors is not None:
        attr = me.color_attributes.new('col', 'FLOAT_COLOR', 'CORNER')
        cols = np.repeat(np.asarray(colors, dtype=float), 3, axis=0)
        attr.data.foreach_set('color', np.concatenate([cols, np.ones((len(cols), 1))], 1).ravel())
        node = mat.node_tree.nodes.new('ShaderNodeVertexColor')
        node.layer_name = 'col'
        mat.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
    else:
        bsdf.inputs['Base Color'].default_value = (.36, .34, .34, 1)
    ob.data.materials.append(mat)
    return ob


def _shoot(sc, cam, center, height, views, out, prefix, log):
    import bpy
    paths = []
    for name, yaw in views:
        a = math.radians(yaw)
        # yaw 0 : face (caméra devant, sur +z glTF = −y Blender)
        cam.location = (center[0] + 4 * math.sin(a), -(center[2] + 4 * math.cos(a)), center[1])
        cam.rotation_euler = (math.radians(90), 0, a)
        cam.data.ortho_scale = height * 1.08
        p = out / f'{prefix}_{name}.png'
        sc.render.filepath = str(p)
        bpy.ops.render.render(write_still=True)
        paths.append(p)
    return paths


def render_views(P, F, names, out, prefix, log):
    """Planche face / dos / profil / 3/4 : une couleur par zone, peau nue en
    gris, tête / mains / pieds en sombre."""
    import numpy as np
    out.mkdir(parents=True, exist_ok=True)
    keys = sorted({n.rsplit('_', 1)[0] for n in names if n not in ('peau', 'head')})
    # couleurs fixes des muscles principaux (contrôle anatomique), autres en
    # teintes pastel
    fixed = {
        'pectoralis_major_clavicular': (255, 120, 120), 'pectoralis_major_sternocostal': (220, 30, 30),
        'pectoralis_major_abdominal': (150, 0, 0), 'deltoid_anterior': (255, 200, 0),
        'deltoid_lateral': (255, 150, 0), 'deltoid_posterior': (200, 100, 0),
        'biceps_brachii': (0, 90, 255), 'brachialis': (120, 170, 255), 'triceps_brachii': (0, 200, 255),
        'latissimus_dorsi': (0, 170, 60), 'trapezius_upper': (160, 255, 120),
        'trapezius_middle': (90, 210, 90), 'trapezius_lower': (40, 120, 40),
        'erector_spinae': (140, 70, 20), 'rectus_abdominis': (170, 0, 220),
        'external_oblique': (230, 120, 255), 'serratus_anterior': (255, 0, 160),
        'gluteus_maximus': (255, 60, 200), 'gluteus_medius': (255, 170, 230),
        'rectus_femoris': (0, 60, 160), 'vastus_lateralis': (80, 140, 255),
        'vastus_medialis': (0, 30, 90), 'biceps_femoris_long': (0, 150, 150),
        'semitendinosus': (0, 230, 200), 'gastrocnemius_medial': (255, 230, 90),
        'gastrocnemius_lateral': (210, 170, 0), 'soleus': (130, 90, 0),
        'tibialis_anterior': (255, 110, 40), 'infraspinatus': (120, 60, 160),
        'teres_major': (60, 30, 110), 'sartorius': (250, 250, 250),
        'adductor_longus': (100, 100, 180), 'gracilis': (180, 180, 250),
        'brachioradialis_muscle': (40, 90, 60), 'hand_intrinsic': (40, 40, 40),
        'foot_intrinsic': (40, 40, 40), 'sternocleidomastoid': (255, 255, 0),
    }
    col = {}
    for i, k in enumerate(keys):
        c = fixed.get(k, PALETTE[(i * 7) % len(PALETTE)])
        col[k] = np.array(c) / 255
    C = np.array([(.45, .45, .45) if n == 'peau' else (.08, .08, .08) if n == 'head'
                  else col[n.rsplit('_', 1)[0]] for n in names])
    sc, cam = _blender_scene()
    _add_mesh(P, F, C)
    center = (P.min(0) + P.max(0)) / 2
    paths = _shoot(sc, cam, center, P[:, 1].max(), [('face', 0), ('dos', 180), ('profil', 90),
                                                   ('trois_quarts', 35)], out, prefix, log)
    _sheet(paths, out / f'{prefix}.png')
    log(f'planche : {out / (prefix + ".png")}')


def render_poses(ch, Vfit, out, log):
    """Six poses extrêmes, avant / après le « fit » (gris)."""
    import numpy as np
    out.mkdir(parents=True, exist_ok=True)
    for pose_name, pose in EXTREME_POSES.items():
        paths = []
        for tag, base in (('avant', ch.V), ('apres', Vfit)):
            P = skin(ch, base, pose)
            sc, cam = _blender_scene((440, 560))
            _add_mesh(P, ch.F)
            center = (P.min(0) + P.max(0)) / 2
            h = max(P[:, 1].max() - P[:, 1].min(), P[:, 0].max() - P[:, 0].min()) + .1
            paths += _shoot(sc, cam, center, h, [('34', 35), ('profil', 90)], out,
                            f'{pose_name}_{tag}', log)
        _sheet(paths, out / f'pose_{pose_name}.png')
    log(f'poses : {out}')


def _sheet(paths, dest):
    from PIL import Image
    ims = [Image.open(p).convert('RGB') for p in paths]
    w, h = ims[0].size
    sheet = Image.new('RGB', (w * len(ims), h))
    for i, im in enumerate(ims):
        sheet.paste(im, (i * w, 0))
    sheet.save(dest)


# =============================================================== check --

def check():
    """Sorties cohérentes (sans la source)."""
    mapping = json.loads(OUT_MAP.read_text(encoding='utf-8'))
    ids = {r['id'] for r in mapping['regions']}
    assert len(ids) == len(mapping['regions'])
    assert mapping['triangles'] <= TRIANGLE_BUDGET
    skel = json.loads(OUT_SKELETON.read_text(encoding='utf-8'))
    assert len(skel['os']) == 65
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--source', choices=('ecorche', 'zanatomy'), default='ecorche')
    parser.add_argument('--render', help='dossier des planches de zones')
    parser.add_argument('--poses', help='dossier des planches des poses extrêmes')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        print('OK' if check() else 'KO')
        return
    build(args.source, args.render, args.poses)


if __name__ == '__main__':
    main()
