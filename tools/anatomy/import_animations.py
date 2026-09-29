#!/usr/bin/env python3
"""M7 (mannequin 3D) : import des animations Mixamo du propriétaire.

Le propriétaire fournit **un FBX Mixamo « Without Skin » par animation**,
fait sur le personnage « Ch36 » (squelette `mixamorig1:` / `mixamorig:` de
65 os), nommé par l'identifiant d'exercice du pack (`back-squat.fbx`,
`traction-pronation.fbx`… ; mode d'emploi : docs/ANIMATIONS_PROPRIETAIRE.md).

Commandes (clé `KT_ASSETS_KEY` dans l'environnement ; Blender sans interface :
`pip install bpy numpy scipy --break-system-packages`) :

  deposer FBX…        vérifie chaque FBX (nom, squelette, animation) puis le
                      chiffre dans `assets_secure/animations/<id>.fbx.enc`
                      (rôle « animation » du manifeste) : jamais en clair
                      dans le dépôt ; `--id` impose l'identifiant
  importer [--id …]   déchiffre les FBX déposés et fabrique les clips :
                      squelette vérifié (noms, hiérarchie, longueurs),
                      déplacement racine parasite retiré si l'exercice est
                      sur place, rééchantillonnage (30 i/s), réduction des
                      images clés (écart ≤ `tolerance_deg`), quantification,
                      compression (≤ 5 Ko visé), phases (réglages ou
                      détection par la hauteur du centre de masse), registre
                      `assets/anatomy/clips/index.json`
  verifier            sans clé ni Blender : registre, clips (décodage,
                      taille, phases, os) et manifeste cohérents

Réglages par animation : `tools/anatomy/animations.json` (sur place,
phases imposées, tolérance, identifiants partageant la même animation,
muscles d'une animation de test). Toute erreur est un message clair
(`ImportErreur`), sans trace Python.

Format des clips (`.ktclip`, gzip d'un bloc petit-boutiste) :
  'KTC1', u8 version (1), u8 images/s, u16 nombre d'images, u8 nombre de
  pistes, u8 options (bit 0 : piste de translation du bassin) ;
  pour chaque piste d'os : u8 os (ordre de `assets/anatomy/rig_mixamo.json`),
  u16 nombre de clés, écarts d'images (u8), puis par clé u8 indice de la plus
  grande composante et 3 × i16 (quaternion « trois plus petites »,
  composantes / (1/√2) × 32767) ;
  translation du bassin : u16 clés, écarts (u8), 3 × i16 par clé (mm).
  Rotation = rotation locale de l'os dans le repère du corps (glTF : y en
  haut, avant = +z, gauche = +x) autour de sa tête, comme `MannequinRig` ;
  un os sans piste reste au repos (T). Interpolation : sphérique entre deux
  clés, linéaire pour la translation.
"""
import argparse
import gzip
import hashlib
import io
import json
import math
import struct
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(HERE))

SKELETON = ROOT / 'assets/anatomy/squelette_mixamo.json'
RIG = ROOT / 'assets/anatomy/rig_mixamo.json'
CLIPS_DIR = ROOT / 'assets/anatomy/clips'
INDEX = CLIPS_DIR / 'index.json'
CONFIG = HERE / 'animations.json'
SECURE_ANIM = 'assets_secure/animations'
CLEAR_ANIM = 'assets_secure/clair/animations'
CONTENT_INDEX = ROOT / 'assets/content/index.json.gz'

FPS = 30
CLIP_BUDGET = 5 * 1024          # octets, visé
TOLERANCE_DEG = .2              # écart angulaire maximal après réduction
TOLERANCE_MAX_DEG = 1.0         # au-delà du budget, relâchée jusqu'ici
TRANSLATION_TOL = .001          # m
LENGTH_TOLERANCE = .03          # écart relatif de longueur d'os toléré
MAX_DURATION = 60               # s
PHASE_TYPES = ('concentrique', 'excentrique', 'isometrique')
PHASE_NAMES = {'concentrique': 'Montée', 'excentrique': 'Descente', 'isometrique': 'Pause'}
INV_SQRT2 = 1 / math.sqrt(2)

# Masses relatives des segments (Winter, Biomechanics and Motor Control of
# Human Movement, 4e éd., tableau 4.1) : centre de masse pour la détection
# des phases et l'équilibre de l'animation de test. Segment = de l'os à son
# premier enfant nommé.
SEGMENT_MASS = {
    'Hips': .142, 'Spine': .07, 'Spine1': .07, 'Spine2': .139, 'Neck': .02, 'Head': .061,
    'LeftArm': .028, 'LeftForeArm': .016, 'LeftHand': .006,
    'RightArm': .028, 'RightForeArm': .016, 'RightHand': .006,
    'LeftUpLeg': .1, 'LeftLeg': .0465, 'LeftFoot': .0145,
    'RightUpLeg': .1, 'RightLeg': .0465, 'RightFoot': .0145,
}
SEGMENT_END = {
    'Hips': 'Spine', 'Spine': 'Spine1', 'Spine1': 'Spine2', 'Spine2': 'Neck', 'Neck': 'Head',
    'Head': 'HeadTop_End', 'LeftArm': 'LeftForeArm', 'LeftForeArm': 'LeftHand',
    'LeftHand': 'LeftHandMiddle1', 'RightArm': 'RightForeArm', 'RightForeArm': 'RightHand',
    'RightHand': 'RightHandMiddle1', 'LeftUpLeg': 'LeftLeg', 'LeftLeg': 'LeftFoot',
    'LeftFoot': 'LeftToeBase', 'RightUpLeg': 'RightLeg', 'RightLeg': 'RightFoot',
    'RightFoot': 'RightToeBase',
}


class ImportErreur(Exception):
    """Erreur d'import, avec un message clair pour le propriétaire."""


# ================================================================ données --

def canonical(name):
    """Nom d'os sans préfixe (`mixamorig:LeftArm` → `LeftArm`)."""
    return name.rsplit(':', 1)[-1]


def load_skeleton():
    return json.loads(SKELETON.read_text(encoding='utf-8'))


def load_config():
    if not CONFIG.exists():
        return {'animations': {}}
    return json.loads(CONFIG.read_text(encoding='utf-8'))


def pack_exercises():
    """{id: nom} des exercices du pack (index de contenu)."""
    data = json.loads(gzip.decompress(CONTENT_INDEX.read_bytes()))
    return {e['id']: e['nom'] for e in data['exercices']}


def owner_program():
    """Exercices du programme du propriétaire (identifiants du pack, ordre
    d'apparition), d'après la correspondance `programme_v33` de l'index."""
    data = json.loads(gzip.decompress(CONTENT_INDEX.read_bytes()))
    out = []
    for v in data['programme_v33'].values():
        if v['id'] not in out:
            out.append(v['id'])
    return out


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def sha256(path):
    return sha256_bytes(Path(path).read_bytes())


# ============================================================ rotations --

def quat_to_mat(q):
    import numpy as np
    x, y, z, w = q
    return np.array([
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]])


def mat_to_quat(m):
    import numpy as np
    m = np.asarray(m, dtype=np.float64)
    t = m.trace()
    if t > 0:
        s = math.sqrt(t + 1) * 2
        q = [(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, s / 4]
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        q = [s / 4, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        q = [(m[0, 1] + m[1, 0]) / s, s / 4, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    else:
        s = math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        q = [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, s / 4, (m[1, 0] - m[0, 1]) / s]
    q = np.array(q)
    return q / np.linalg.norm(q)


def axis_angle(axis, deg):
    """Matrice de rotation (degrés, règle de la main droite)."""
    import numpy as np
    a = np.asarray(axis, dtype=np.float64)
    a = a / np.linalg.norm(a)
    t = math.radians(deg)
    k = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + math.sin(t) * k + (1 - math.cos(t)) * (k @ k)


def slerp(a, b, t):
    """Interpolation sphérique (le plus court chemin), sans numpy."""
    a = [float(v) for v in a]
    b = [float(v) for v in b]
    d = sum(x * y for x, y in zip(a, b))
    if d < 0:
        b, d = [-v for v in b], -d
    if d > .9995:
        q = [x + t * (y - x) for x, y in zip(a, b)]
    else:
        th = math.acos(min(1.0, d))
        s0, s1 = math.sin((1 - t) * th), math.sin(t * th)
        q = [(s0 * x + s1 * y) / math.sin(th) for x, y in zip(a, b)]
    n = math.sqrt(sum(v * v for v in q))
    return [v / n for v in q]


def angle_deg(a, b):
    """Angle (degrés) entre deux rotations données en quaternions."""
    d = abs(sum(x * y for x, y in zip(a, b)))
    return math.degrees(2 * math.acos(min(1.0, d)))


# ================================================================ poses --

class Motion:
    """Mouvement échantillonné : rotations locales (quaternions x, y, z, w,
    repère du corps, autour de la tête de l'os) par image et par os (ordre
    du squelette), translation du bassin (m) par image."""

    def __init__(self, bones, parents, heads, fps, local, root):
        import numpy as np
        self.bones, self.parents, self.fps = bones, parents, fps
        self.heads = np.asarray(heads, dtype=np.float64)
        self.local = np.asarray(local, dtype=np.float64)   # (images, os, 4)
        self.root = np.asarray(root, dtype=np.float64)     # (images, 3)
        self.index = {b: i for i, b in enumerate(bones)}

    @property
    def frames(self):
        return len(self.local)

    @property
    def duration(self):
        return (self.frames - 1) / self.fps

    def globals(self, f):
        """Rotations globales (3×3) et positions des têtes pour l'image f."""
        import numpy as np
        R = np.zeros((len(self.bones), 3, 3))
        P = np.zeros((len(self.bones), 3))
        for i, b in enumerate(self.bones):
            p = self.parents[i]
            L = quat_to_mat(self.local[f, i])
            if p is None:
                R[i] = L
                P[i] = self.heads[i] + self.root[f]
            else:
                pi = self.index[p]
                R[i] = R[pi] @ L
                P[i] = P[pi] + R[pi] @ (self.heads[i] - self.heads[pi])
        return R, P

    def center_of_mass(self, f):
        import numpy as np
        _, P = self.globals(f)
        c = np.zeros(3)
        total = 0.0
        for seg, m in SEGMENT_MASS.items():
            a, b = self.index.get(seg), self.index.get(SEGMENT_END[seg])
            if a is None or b is None:
                continue
            c += m * (P[a] + P[b]) / 2
            total += m
        return c / total


def skeleton_motion_base():
    """Os, parents et têtes de repos du personnage (ordre du squelette)."""
    skel = load_skeleton()
    bones = [b['nom'] for b in skel['os']]
    parents = [b['parent'] for b in skel['os']]
    heads = [b['tete'] for b in skel['os']]
    return skel, bones, parents, heads


# ================================================================== FBX --

def to_gltf_mat(M):
    """Matrice du monde d'un os (colonnes : axes de l'os, puis tête) du
    repère de Blender (z en haut, avant = −y) vers glTF ; les axes propres
    de l'os ne changent pas (mêmes conventions que `squelette_mixamo.json`)."""
    import numpy as np
    C = np.array([[1, 0, 0, 0], [0, 0, 1, 0], [0, -1, 0, 0], [0, 0, 0, 1]], dtype=np.float64)
    return C @ np.asarray(M, dtype=np.float64)


def read_fbx(path):
    """Lit un FBX d'animation (Blender sans interface) : os (noms tels quels),
    parents, images/s, plage d'images, matrices du monde (glTF) des os pour
    chaque image et au repos."""
    import numpy as np
    try:
        import bpy
    except ImportError as e:  # pragma: no cover - dépend de l'environnement
        raise ImportErreur('Blender (module bpy) est nécessaire : '
                           'pip install bpy --break-system-packages') from e
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.fbx(filepath=str(path))
    except RuntimeError as e:
        raise ImportErreur(f'{Path(path).name} : fichier FBX illisible ({e}).') from e
    arms = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if len(arms) != 1:
        raise ImportErreur(f'{Path(path).name} : un seul squelette attendu, {len(arms)} trouvé(s).')
    arm = arms[0]
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    action = arm.animation_data.action if arm.animation_data else None
    if action is None:
        raise ImportErreur(f'{Path(path).name} : aucune animation dans le fichier '
                           '(exporter depuis Mixamo avec une animation choisie).')
    scene = bpy.context.scene
    fps = scene.render.fps / scene.render.fps_base
    f0, f1 = (int(round(v)) for v in action.frame_range)
    aw = arm.matrix_world
    names = [b.name for b in arm.data.bones]
    parents = [b.parent.name if b.parent else None for b in arm.data.bones]
    rest = np.array([to_gltf_mat(aw @ b.matrix_local) for b in arm.data.bones])
    world = []
    for f in range(f0, f1 + 1):
        scene.frame_set(f)
        world.append([to_gltf_mat(aw @ arm.pose.bones[n].matrix) for n in names])
    return {'names': names, 'parents': parents, 'fps': fps, 'frames': (f0, f1),
            'rest': rest, 'world': np.array(world), 'meshes': len(meshes)}


def check_skeleton(fbx, name='FBX'):
    """Squelette Mixamo du personnage : mêmes os (noms sans préfixe), même
    hiérarchie, longueurs d'os à ±3 %. Renvoie la liste des écarts."""
    import numpy as np
    skel = load_skeleton()
    want = [b['nom'] for b in skel['os']]
    want_parent = {b['nom']: b['parent'] for b in skel['os']}
    got = [canonical(n) for n in fbx['names']]
    missing = [b for b in want if b not in got]
    extra = [b for b in got if b not in want]
    if missing or extra:
        detail = []
        if missing:
            detail.append(f'os absents : {", ".join(missing[:6])}' + ('…' if len(missing) > 6 else ''))
        if extra:
            detail.append(f'os inconnus : {", ".join(extra[:6])}' + ('…' if len(extra) > 6 else ''))
        raise ImportErreur(f'{name} : squelette incompatible avec le personnage Ch36 '
                           f'(65 os Mixamo attendus ; {"; ".join(detail)}). Exporter depuis '
                           'Mixamo avec le personnage Ch36, « Without Skin ».')
    for n, p in zip(fbx['names'], fbx['parents']):
        c = canonical(n)
        if (canonical(p) if p else None) != want_parent[c]:
            raise ImportErreur(f'{name} : squelette incompatible (hiérarchie : {c} rattaché à '
                               f'{canonical(p) if p else "rien"} au lieu de {want_parent[c]}).')
    heads = {b['nom']: np.array(b['tete']) for b in skel['os']}
    pos = {canonical(n): fbx['rest'][i][:3, 3] for i, n in enumerate(fbx['names'])}
    gaps = []
    for b, p in want_parent.items():
        if p is None:
            continue
        ref = np.linalg.norm(heads[b] - heads[p])
        if ref < .02:
            continue
        got_len = np.linalg.norm(pos[b] - pos[p])
        rel = abs(got_len / ref - 1)
        if rel > LENGTH_TOLERANCE:
            gaps.append((b, round(rel * 100, 1)))
    if gaps:
        raise ImportErreur(f'{name} : squelette incompatible (proportions d\'un autre personnage : '
                           + ', '.join(f'{b} {g} %' for b, g in gaps[:5])
                           + '). Exporter depuis Mixamo avec le personnage Ch36.')
    return True


def fbx_motion(fbx):
    """Rotations locales (repère du corps) et translation du bassin, depuis
    les matrices du monde des os de l'animation et les repères de repos du
    personnage (`squelette_mixamo.json`, mêmes conventions d'axes Mixamo)."""
    import numpy as np
    skel, bones, parents, heads = skeleton_motion_base()
    rest_axes = {b['nom']: np.array(b['axes']).T for b in skel['os']}   # colonnes
    col = {canonical(n): i for i, n in enumerate(fbx['names'])}
    n_frames = len(fbx['world'])
    G = np.zeros((n_frames, len(bones), 3, 3))
    root = np.zeros((n_frames, 3))
    hips = bones.index('Hips')
    for f in range(n_frames):
        for i, b in enumerate(bones):
            M = fbx['world'][f][col[b]]
            A = M[:3, :3] / np.linalg.norm(M[:3, :3], axis=0, keepdims=True)
            U, _, Vt = np.linalg.svd(A @ rest_axes[b].T)
            G[f, i] = U @ Vt
        root[f] = fbx['world'][f][col['Hips']][:3, 3] - np.array(heads[hips])
    local = np.zeros((n_frames, len(bones), 4))
    for f in range(n_frames):
        for i, b in enumerate(bones):
            p = parents[i]
            L = G[f, i] if p is None else G[f, bones.index(p)].T @ G[f, i]
            q = mat_to_quat(L)
            local[f, i] = q if q[3] >= 0 else -q
    # continuité des signes (interpolation par le plus court chemin)
    for f in range(1, n_frames):
        flip = (local[f] * local[f - 1]).sum(axis=1) < 0
        local[f, flip] *= -1
    return Motion(bones, parents, heads, fbx['fps'], local, root)


# ======================================================== préparation --

def remove_root_drift(motion):
    """Déplacement racine parasite d'un exercice sur place : la dérive
    horizontale du bassin entre la première et la dernière image est retirée
    linéairement (le balancement naturel, lui, est gardé)."""
    import numpy as np
    n = motion.frames
    if n < 2:
        return 0.0
    drift = motion.root[-1] - motion.root[0]
    drift[1] = 0
    t = np.linspace(0, 1, n)[:, None]
    motion.root = motion.root - t * drift
    return float(np.linalg.norm(drift))


def resample(motion, fps=FPS):
    """Rééchantillonne à `fps` images/s (sphérique pour les rotations)."""
    import numpy as np
    if abs(motion.fps - fps) < 1e-6:
        return motion
    duration = motion.duration
    n = int(round(duration * fps)) + 1
    local = np.zeros((n, len(motion.bones), 4))
    root = np.zeros((n, 3))
    for k in range(n):
        x = min(k / fps * motion.fps, motion.frames - 1)
        a = int(math.floor(x))
        b = min(a + 1, motion.frames - 1)
        t = x - a
        for i in range(len(motion.bones)):
            local[k, i] = slerp(motion.local[a, i], motion.local[b, i], t)
        root[k] = motion.root[a] * (1 - t) + motion.root[b] * t
    return Motion(motion.bones, motion.parents, motion.heads, fps, local, root)


# ========================================================== compression --

def reduce_rotation(track, tol):
    """Images clés d'une piste de quaternions : on garde la première et la
    dernière, puis l'image la plus mal interpolée tant que l'écart dépasse
    `tol` degrés."""
    n = len(track)
    keep = {0, n - 1}
    stack = [(0, n - 1)]
    while stack:
        a, b = stack.pop()
        if b - a < 2:
            continue
        worst, at = 0.0, None
        for k in range(a + 1, b):
            e = angle_deg(slerp(track[a], track[b], (k - a) / (b - a)), track[k])
            if e > worst:
                worst, at = e, k
        if worst > tol:
            keep.add(at)
            stack += [(a, at), (at, b)]
    return sorted(keep)


def reduce_translation(track, tol):
    import numpy as np
    n = len(track)
    keep = {0, n - 1}
    stack = [(0, n - 1)]
    while stack:
        a, b = stack.pop()
        if b - a < 2:
            continue
        k = np.arange(a + 1, b)
        t = ((k - a) / (b - a))[:, None]
        e = np.linalg.norm(track[a] * (1 - t) + track[b] * t - track[k], axis=1)
        j = int(np.argmax(e))
        if e[j] > tol:
            keep.add(int(k[j]))
            stack += [(a, int(k[j])), (int(k[j]), b)]
    return sorted(keep)


def _with_gaps(keys):
    """Ajoute une clé tous les 255 images au plus (écarts sur un octet)."""
    out = [keys[0]]
    for k in keys[1:]:
        while k - out[-1] > 255:
            out.append(out[-1] + 255)
        out.append(k)
    return out


def encode_quat(q):
    q = list(q)
    i = max(range(4), key=lambda k: abs(q[k]))
    if q[i] < 0:
        q = [-v for v in q]
    rest = [q[k] for k in range(4) if k != i]
    return i, [max(-32767, min(32767, int(round(v / INV_SQRT2 * 32767)))) for v in rest]


def decode_quat(i, vals):
    rest = [v / 32767 * INV_SQRT2 for v in vals]
    big = math.sqrt(max(0.0, 1 - sum(v * v for v in rest)))
    q = []
    it = iter(rest)
    for k in range(4):
        q.append(big if k == i else next(it))
    n = math.sqrt(sum(v * v for v in q))
    return [v / n for v in q]


def encode_clip(motion, tol_deg=TOLERANCE_DEG, tol_m=TRANSLATION_TOL):
    """Clip compressé (octets) et statistiques."""
    import numpy as np
    if motion.frames > 65535:
        raise ImportErreur('Animation trop longue.')
    tracks = []
    for i in range(len(motion.bones)):
        tr = motion.local[:, i]
        if max(angle_deg(q, (0, 0, 0, 1)) for q in tr) <= tol_deg * .5:
            continue   # au repos toute l'animation : pas de piste
        tracks.append((i, _with_gaps(reduce_rotation(tr, tol_deg))))
    root_keys = None
    if np.abs(motion.root).max() > tol_m * .5:
        root_keys = _with_gaps(reduce_translation(motion.root, tol_m))
    out = io.BytesIO()
    out.write(b'KTC1')
    out.write(struct.pack('<BBHBB', 1, int(round(motion.fps)), motion.frames, len(tracks),
                          1 if root_keys else 0))
    for i, keys in tracks:
        out.write(struct.pack('<BH', i, len(keys)))
        prev = 0
        for k in keys:
            out.write(struct.pack('<B', k - prev))
            prev = k
        for k in keys:
            idx, vals = encode_quat(motion.local[k, i])
            out.write(struct.pack('<Bhhh', idx, *vals))
    if root_keys:
        out.write(struct.pack('<H', len(root_keys)))
        prev = 0
        for k in root_keys:
            out.write(struct.pack('<B', k - prev))
            prev = k
        for k in root_keys:
            mm = [max(-32767, min(32767, int(round(v * 1000)))) for v in motion.root[k]]
            out.write(struct.pack('<hhh', *mm))
    raw = out.getvalue()
    data = gzip.compress(raw, compresslevel=9, mtime=0)
    stats = {'pistes': len(tracks), 'cles': sum(len(k) for _, k in tracks),
             'cles_bassin': len(root_keys or []), 'octets_bruts': len(raw), 'octets': len(data),
             'tolerance_deg': tol_deg}
    return data, stats


def decode_clip(data, bones):
    """Décode un clip (vérification, tests ; sans numpy) : images/s, nombre
    d'images, rotations locales [image][os] (x, y, z, w) aux clés
    interpolées, translation du bassin [image] (m)."""
    import itertools
    raw = gzip.decompress(data)
    if raw[:4] != b'KTC1':
        raise ImportErreur('Clip illisible (en-tête).')
    version, fps, frames, n_tracks, flags = struct.unpack_from('<BBHBB', raw, 4)
    if version != 1:
        raise ImportErreur(f'Clip : version {version} inconnue.')
    o = 10
    local = [[[0.0, 0.0, 0.0, 1.0] for _ in bones] for _ in range(frames)]
    for _ in range(n_tracks):
        bone, n = struct.unpack_from('<BH', raw, o)
        o += 3
        if bone >= len(bones):
            raise ImportErreur('Clip : os hors du squelette.')
        keys = list(itertools.accumulate(raw[o:o + n]))
        o += n
        quats = []
        for _k in range(n):
            idx, a, b, c = struct.unpack_from('<Bhhh', raw, o)
            o += 7
            quats.append(decode_quat(idx, (a, b, c)))
        for f in range(frames):
            local[f][bone] = list(_sample_quat(keys, quats, f))
    root = [[0.0, 0.0, 0.0] for _ in range(frames)]
    if flags & 1:
        n = struct.unpack_from('<H', raw, o)[0]
        o += 2
        keys = list(itertools.accumulate(raw[o:o + n]))
        o += n
        vals = []
        for _k in range(n):
            vals.append([v / 1000 for v in struct.unpack_from('<hhh', raw, o)])
            o += 6
        import bisect
        for f in range(frames):
            j = max(0, min(bisect.bisect_right(keys, f) - 1, n - 1))
            if j == n - 1 or keys[j] == f:
                root[f] = list(vals[j])
            else:
                t = (f - keys[j]) / (keys[j + 1] - keys[j])
                root[f] = [a * (1 - t) + b * t for a, b in zip(vals[j], vals[j + 1])]
    if o != len(raw):
        raise ImportErreur('Clip : taille inattendue.')
    return fps, frames, local, root


def _sample_quat(keys, quats, f):
    import bisect
    j = bisect.bisect_right(keys, f) - 1
    j = max(0, min(j, len(keys) - 1))
    if j == len(keys) - 1 or keys[j] == f:
        return quats[j]
    t = (f - keys[j]) / (keys[j + 1] - keys[j])
    return slerp(quats[j], quats[j + 1], t)


def max_error(motion, decoded_local, decoded_root):
    """Écart maximal (degrés, m) entre le mouvement et le clip décodé,
    rotations locales et positions des têtes d'os (m)."""
    import numpy as np
    decoded_local = np.asarray(decoded_local, dtype=np.float64)
    decoded_root = np.asarray(decoded_root, dtype=np.float64)
    rot = 0.0
    for f in range(motion.frames):
        for i in range(len(motion.bones)):
            rot = max(rot, angle_deg(motion.local[f, i], decoded_local[f, i]))
    dec = Motion(motion.bones, motion.parents, motion.heads, motion.fps, decoded_local,
                 decoded_root)
    pos = 0.0
    for f in range(0, motion.frames, max(1, motion.frames // 60)):
        _, P0 = motion.globals(f)
        _, P1 = dec.globals(f)
        pos = max(pos, float(np.linalg.norm(P0 - P1, axis=1).max()))
    return rot, pos


# ================================================================ phases --

def detect_phases(motion, min_len=.25):
    """Phases par la hauteur du centre de masse : montée = concentrique,
    descente = excentrique, presque immobile = isométrique. Segments plus
    courts que `min_len` s rattachés au voisin."""
    import numpy as np
    y = np.array([motion.center_of_mass(f)[1] for f in range(motion.frames)])
    k = max(1, int(round(.1 * motion.fps)))
    ys = np.convolve(np.pad(y, k, mode='edge'), np.ones(2 * k + 1) / (2 * k + 1), 'valid')
    v = np.gradient(ys) * motion.fps
    span = max(float(y.max() - y.min()), 1e-6)
    still = max(.08 * span, .01)     # m/s
    kind = np.where(np.abs(v) < still, 2, np.where(v > 0, 0, 1))
    segs = []
    start = 0
    for f in range(1, motion.frames + 1):
        if f == motion.frames or kind[f] != kind[start]:
            segs.append([int(kind[start]), start, f - 1])
            start = f
    min_frames = int(round(min_len * motion.fps))
    changed = True
    while changed and len(segs) > 1:
        changed = False
        for j, (kd, a, b) in enumerate(segs):
            if b - a + 1 < min_frames:
                if j == 0:
                    segs[1][1] = a
                elif j == len(segs) - 1 or (segs[j - 1][2] - segs[j - 1][1]) >= (
                        segs[j + 1][2] - segs[j + 1][1]):
                    segs[j - 1][2] = b
                else:
                    segs[j + 1][1] = a
                del segs[j]
                changed = True
                break
        merged = [segs[0]]
        for s in segs[1:]:
            if s[0] == merged[-1][0]:
                merged[-1][2] = s[2]
            else:
                merged.append(s)
        segs = merged
    out = []
    for kd, a, b in segs:
        t0 = a / motion.fps
        t1 = (b + 1) / motion.fps if b + 1 < motion.frames else motion.duration
        out.append({'type': PHASE_TYPES[kd], 'debut_s': round(t0, 3), 'fin_s': round(t1, 3)})
    return name_phases(out)


def name_phases(phases):
    for p in phases:
        p.setdefault('nom', PHASE_NAMES[p['type']])
    return phases


def check_phases(phases, duration):
    if not phases:
        raise ImportErreur('Phases : au moins une.')
    t = 0.0
    for p in phases:
        if p['type'] not in PHASE_TYPES:
            raise ImportErreur(f'Phase de type inconnu : {p["type"]}.')
        if abs(p['debut_s'] - t) > 1e-6 or p['fin_s'] <= p['debut_s']:
            raise ImportErreur('Phases : elles doivent se suivre sans trou ni chevauchement.')
        t = p['fin_s']
    if abs(t - duration) > 1.5 / FPS:
        raise ImportErreur(f'Phases : elles couvrent {t:.2f} s, l\'animation dure {duration:.2f} s.')


# ============================================================ manifeste --

def _secure():
    import secure_assets
    return secure_assets


def animation_entries():
    return [e for e in _secure().load_manifest()['fichiers'] if e['role'] == 'animation']


def exercise_id_of(path):
    return Path(path).stem.strip().lower()


def deposit(paths, forced_id=None, log=print):
    """Vérifie puis chiffre chaque FBX dans assets_secure/animations/."""
    sa = _secure()
    known = pack_exercises()
    config = load_config()['animations']
    done = []
    for path in paths:
        path = Path(path)
        if path.suffix.lower() != '.fbx':
            raise ImportErreur(f'{path.name} : un fichier .fbx est attendu.')
        ex = forced_id or exercise_id_of(path)
        if ex not in known and not config.get(ex, {}).get('debogage'):
            close = [k for k in known if ex.replace('_', '-') in k][:3]
            raise ImportErreur(f'{path.name} : nom inconnu, « {ex} » n\'est pas un identifiant '
                               'd\'exercice du pack' + (f' (proches : {", ".join(close)})'
                                                        if close else '') +
                               '. Nommer le fichier comme dans docs/ANIMATIONS_PROPRIETAIRE.md.')
        fbx = read_fbx(path)
        check_skeleton(fbx, path.name)
        if fbx['meshes']:
            log(f'{path.name} : le fichier contient un maillage (export « With Skin ») ; '
                'seul le squelette est utilisé.')
        clear = ROOT / CLEAR_ANIM / f'{ex}.fbx'
        clear.parent.mkdir(parents=True, exist_ok=True)
        if path.resolve() != clear.resolve():
            clear.write_bytes(path.read_bytes())
        data = sa.load_manifest()
        rel_clear = f'{CLEAR_ANIM}/{ex}.fbx'
        entry = next((e for e in data['fichiers'] if e['clair'] == rel_clear), None)
        if entry is None:
            entry = {'chiffre': f'{SECURE_ANIM}/{ex}.fbx.enc', 'clair': rel_clear,
                     'role': 'animation',
                     'description': f'Animation Mixamo « Without Skin » de l\'exercice {ex}',
                     'sha256': '0' * 64, 'octets_clair': 0}
            data['fichiers'].append(entry)
            sa.save_manifest(data)
        (ROOT / SECURE_ANIM).mkdir(parents=True, exist_ok=True)
        sa.encrypt(clear, log=log)
        done.append(ex)
        log(f'OK : {path.name} déposé ({ex}, {fbx["frames"][1] - fbx["frames"][0] + 1} images '
            f'à {fbx["fps"]:g} i/s).')
    return done


def decrypt_animations(ids=None, log=print):
    sa = _secure()
    env = sa._key_env()
    out = {}
    for e in animation_entries():
        ex = Path(e['clair']).stem
        if ids and ex not in ids:
            continue
        dst = ROOT / e['clair']
        if not (dst.exists() and sa.sha256(dst) == e['sha256']):
            dst.parent.mkdir(parents=True, exist_ok=True)
            r = subprocess.run(sa.OPENSSL + ['-d', '-in', str(ROOT / e['chiffre']), '-out',
                                             str(dst)], env=env, capture_output=True)
            if r.returncode != 0 or sa.sha256(dst) != e['sha256']:
                raise ImportErreur(f'Déchiffrement refusé : {e["chiffre"]} (clé incorrecte ?).')
        out[ex] = (dst, e)
    return out


# =============================================================== import --

def build_clip(ex, fbx_path, entry, config, log=print):
    """Fabrique le clip d'une animation et son entrée de registre."""
    fbx = read_fbx(fbx_path)
    check_skeleton(fbx, Path(fbx_path).name)
    motion = fbx_motion(fbx)
    if motion.duration > MAX_DURATION:
        raise ImportErreur(f'{ex} : animation de {motion.duration:.0f} s (60 s au plus).')
    opts = config.get(ex, {})
    in_place = opts.get('sur_place', True)
    drift = remove_root_drift(motion) if in_place else 0.0
    motion = resample(motion, FPS)
    tol = float(opts.get('tolerance_deg', TOLERANCE_DEG))
    data, stats = encode_clip(motion, tol)
    while len(data) > CLIP_BUDGET and tol < TOLERANCE_MAX_DEG:
        tol = round(tol + .1, 2)
        data, stats = encode_clip(motion, tol)
    import numpy as np
    fps, frames, dl, dr = decode_clip(data, motion.bones)
    rot_err, pos_err = max_error(motion, np.array(dl), np.array(dr))
    phases = opts.get('phases')
    if phases:
        phases = name_phases([dict(p) for p in phases])
    else:
        phases = detect_phases(motion)
    check_phases(phases, motion.duration)
    CLIPS_DIR.mkdir(parents=True, exist_ok=True)
    out = CLIPS_DIR / f'{ex}.ktclip'
    out.write_bytes(data)
    item = {
        'id': ex,
        'fichier': f'assets/anatomy/clips/{ex}.ktclip',
        'exercices': [] if opts.get('debogage') else [ex] + list(opts.get('aussi', [])),
        'debogage': bool(opts.get('debogage', False)),
        'nom': opts.get('nom') or pack_exercises().get(ex, ex),
        'fps': FPS, 'images': motion.frames, 'duree_s': round(motion.duration, 3),
        'sur_place': in_place, 'derive_retiree_m': round(drift, 4),
        'phases': phases, 'phases_source': 'reglages' if opts.get('phases') else 'detection',
        'octets': len(data), 'budget_octets': CLIP_BUDGET,
        'compression': {**stats, 'ecart_max_deg': round(rot_err, 3),
                        'ecart_max_position_mm': round(pos_err * 1000, 2)},
        'source': {'chiffre': entry['chiffre'], 'sha256': entry['sha256'],
                   'images_s_source': fbx['fps'],
                   'images_source': fbx['frames'][1] - fbx['frames'][0] + 1},
    }
    if opts.get('muscles'):
        item['muscles'] = opts['muscles']
    if len(data) > CLIP_BUDGET:
        item['depassement'] = (f'{len(data)} octets > {CLIP_BUDGET} même à {tol}° : '
                               'mouvement long ou très riche, gardé (mesuré).')
    log(f'{ex} : {motion.frames} images, {stats["pistes"]} pistes, {stats["cles"]} clés, '
        f'{len(data)} octets (tolérance {tol}°, écart max {rot_err:.2f}°, '
        f'{pos_err * 1000:.1f} mm), phases {[(p["nom"], p["fin_s"] - p["debut_s"]) for p in phases]}')
    return item, motion


def import_all(ids=None, log=print):
    config = load_config()['animations']
    files = decrypt_animations(ids, log)
    if not files:
        raise ImportErreur('Aucune animation déposée (commande « deposer » d\'abord).')
    index = load_index()
    by_id = {c['id']: c for c in index['clips']}
    for ex, (path, entry) in sorted(files.items()):
        item, _ = build_clip(ex, path, entry, config, log)
        by_id[ex] = item
    index['clips'] = sorted(by_id.values(), key=lambda c: (not c['debogage'], c['id']))
    save_index(index)
    verify(log=log)
    return index


def load_index():
    if INDEX.exists():
        return json.loads(INDEX.read_text(encoding='utf-8'))
    return {'schema': 1, 'clips': []}


def save_index(index):
    index['schema'] = 1
    index['format'] = ('.ktclip : gzip, en-tête KTC1 ; rotations locales (repère du corps) '
                       'par os de assets/anatomy/rig_mixamo.json, translation du bassin (mm) ; '
                       'voir tools/anatomy/import_animations.py')
    index['squelette'] = 'assets/anatomy/rig_mixamo.json'
    INDEX.write_text(json.dumps(index, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


def verify(log=print):
    """Registre, clips et manifeste cohérents (sans clé ni Blender)."""
    index = load_index()
    rig = json.loads(RIG.read_text(encoding='utf-8'))
    bones = [b['nom'] for b in rig['os']]
    known = pack_exercises()
    enc = {e['chiffre']: e for e in animation_entries()}
    ids = set()
    for c in index['clips']:
        if c['id'] in ids:
            raise ImportErreur(f'Registre : {c["id"]} en double.')
        ids.add(c['id'])
        path = ROOT / c['fichier']
        data = path.read_bytes()
        if len(data) != c['octets']:
            raise ImportErreur(f'{c["id"]} : taille du clip différente du registre.')
        if len(data) > c['budget_octets'] and 'depassement' not in c:
            raise ImportErreur(f'{c["id"]} : clip de {len(data)} octets sans justification.')
        fps, frames, local, _ = decode_clip(data, bones)
        if fps != c['fps'] or frames != c['images']:
            raise ImportErreur(f'{c["id"]} : images/s ou nombre d\'images différents du registre.')
        check_phases(c['phases'], c['duree_s'])
        for ex in c['exercices']:
            if ex not in known:
                raise ImportErreur(f'{c["id"]} : exercice inconnu {ex}.')
        if c['debogage'] and c['exercices']:
            raise ImportErreur(f'{c["id"]} : une animation de test ne va sur aucune fiche.')
        src = c['source']['chiffre']
        if src not in enc or enc[src]['sha256'] != c['source']['sha256']:
            raise ImportErreur(f'{c["id"]} : source chiffrée absente ou différente du manifeste.')
    shared = {}
    for c in index['clips']:
        for ex in c['exercices']:
            if ex in shared:
                raise ImportErreur(f'{ex} : deux animations ({shared[ex]}, {c["id"]}).')
            shared[ex] = c['id']
    log(f'OK : {len(index["clips"])} clip(s) conforme(s).')
    return index


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('deposer')
    d.add_argument('fbx', nargs='+')
    d.add_argument('--id')
    i = sub.add_parser('importer')
    i.add_argument('--id', action='append')
    sub.add_parser('verifier')
    args = parser.parse_args()
    try:
        if args.cmd == 'deposer':
            deposit(args.fbx, args.id)
        elif args.cmd == 'importer':
            import_all(args.id)
        else:
            verify()
    except ImportErreur as e:
        print(f'ERREUR : {e}', file=sys.stderr)
        sys.exit(1)
    except Exception as e:  # noqa: BLE001 - message clair pour le propriétaire
        name = type(e).__name__
        if name == 'SecureAssetError':
            print(f'ERREUR : {e}', file=sys.stderr)
            sys.exit(1)
        raise


if __name__ == '__main__':
    main()
