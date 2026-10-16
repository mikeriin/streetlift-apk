#!/usr/bin/env python3
"""M7b (mannequin 3D) : outils d'animation « personnage » de Koach.

Système de pose du squelette Mixamo du personnage Ch36 (65 os,
`assets/anatomy/squelette_mixamo.json`, en clair : aucune ressource
chiffrée n'est nécessaire), sur le modèle de `debug_animation.py` :

- une **pose** est un dictionnaire de canaux (degrés ou mètres), toujours
  définis pour le côté gauche et reportés en miroir sur le côté droit
  (préfixes `l_` / `r_`) : bassin (translation et rotations), rachis
  réparti sur Spine / Spine1 / Spine2, cou, tête, clavicules, bras (dans le
  repère du thorax), coudes, avant-bras, poignets, doigts (fermeture du
  poing, index, pouce) ;
- **jambes par cinématique inverse** : chevilles et pieds fixes (aucun
  glissement), genoux dans le plan qui regarde vers l'avant ;
- **clés** : poses clés, courbes d'accélération par segment (lente aux
  deux bouts, départ vif, arrivée amortie…), dépassements écrits comme des
  clés, décalage de quelques images de la tête, du cou, des clavicules et
  des mains (mouvements secondaires), respiration périodique ;
- **contrôles** : durée, boucle, retour à la pose d'attente, limites
  articulaires, pieds fixes, interpénétration (capsules du corps) ;
- **FBX « Without Skin »** : armature reconstruite depuis
  `squelette_mixamo.json` (os `mixamorig:`), une clé par image à 30 i/s,
  relu ensuite par la chaîne d'import de M7 (`import_animations.py`).

Repère : glTF, y en haut, avant = +z, gauche du personnage = +x ; mètres.
"""
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import import_animations as ia  # noqa: E402

FPS = 30
S = None  # miroir gauche ↔ droite (diag(-1, 1, 1)), créé à la demande


def np_():
    import numpy as np
    return np


def Rx(d):
    return ia.axis_angle((1, 0, 0), d)


def Ry(d):
    return ia.axis_angle((0, 1, 0), d)


def Rz(d):
    return ia.axis_angle((0, 0, 1), d)


def mirror(R):
    """Rotation du côté droit correspondant à la rotation R du côté gauche."""
    np = np_()
    s = np.diag([-1.0, 1.0, 1.0])
    return s @ R @ s


def normalize(v):
    np = np_()
    v = np.asarray(v, dtype=np.float64)
    return v / np.linalg.norm(v)


# ============================================================ squelette --

class Skeleton:
    """Squelette du personnage : os, parents, têtes et repères de repos."""

    def __init__(self):
        np = np_()
        skel, bones, parents, heads = ia.skeleton_motion_base()
        self.skel = skel
        self.bones, self.parents = bones, parents
        self.heads = np.array(heads, dtype=np.float64)
        self.index = {b: i for i, b in enumerate(bones)}
        self.H = {b: self.heads[i] for i, b in enumerate(bones)}
        self.tails = {b['nom']: np.array(b['queue']) for b in skel['os']}
        # colonnes : axes x, y (le long de l'os), z de l'os au repos
        self.axes = {b['nom']: np.array(b['axes'], dtype=np.float64).T for b in skel['os']}
        for side in ('Left', 'Right'):
            up, kn, an = (self.H[side + n] for n in ('UpLeg', 'Leg', 'Foot'))
            setattr(self, side + '_l1', float(np.linalg.norm(kn - up)))
            setattr(self, side + '_l2', float(np.linalg.norm(an - kn)))
        self.base = (skel, bones, parents, list(map(list, heads)))

    def children(self, name):
        return [b for b, p in zip(self.bones, self.parents) if p == name]


_SKEL = None


def skeleton():
    global _SKEL
    if _SKEL is None:
        _SKEL = Skeleton()
    return _SKEL


# ================================================================ poses --

SIDES = (('l_', 'Left'), ('r_', 'Right'))
FINGERS = ('Index', 'Middle', 'Ring', 'Pinky')

# Pose d'attente (départ et arrivée de toutes les animations : transitions
# possibles entre elles). Bras relâchés le long du corps, paumes vers les
# cuisses, coudes à peine fléchis, doigts mi-détendus, genoux déverrouillés.
NEUTRAL = {
    'px': 0.0, 'py': -0.012, 'pz': 0.0,
    'hip_p': 0.0, 'hip_r': 0.0, 'hip_y': 0.0,
    'sp_p': 0.0, 'sp_r': 0.0, 'sp_y': 0.0,
    'nk_p': 0.0, 'nk_y': 0.0, 'nk_r': 0.0,
    'hd_p': 0.0, 'hd_y': 0.0, 'hd_r': 0.0,
}
for _p, _ in SIDES:
    NEUTRAL.update({
        _p + 'cl_up': 0.0, _p + 'cl_fw': 0.0,
        _p + 'ar_dn': 76.0, _p + 'ar_fw': 6.0, _p + 'ar_tw': 0.0,
        _p + 'el': 14.0, _p + 'fa_tw': 0.0,
        _p + 'wr_fl': 6.0, _p + 'wr_dv': 0.0, _p + 'wr_tw': 0.0,
        _p + 'fist': .22, _p + 'idx': -1.0, _p + 'th_c': .15, _p + 'th_o': 0.0,
    })


def P(**kw):
    """Pose partielle : `l_` / `r_` explicites, ou `b_` pour les deux côtés."""
    out = {}
    for k, v in kw.items():
        if k.startswith('b_'):
            out['l_' + k[2:]] = v
            out['r_' + k[2:]] = v
        else:
            out[k] = v
    return out


def arm_chest(p, side):
    """Rotation du bras dans le repère du thorax (côté gauche, puis miroir) :
    abaissé de `ar_dn` depuis l'horizontale (T), porté vers l'avant de
    `ar_fw`, tourné de `ar_tw` autour de son axe."""
    R = Ry(-p[side + 'ar_fw']) @ Rz(-p[side + 'ar_dn']) @ Rx(p[side + 'ar_tw'])
    return R if side == 'l_' else mirror(R)


def local_axis_rot(sk, bone, axis, deg):
    """Rotation locale (repère du corps) d'un os autour d'un de ses axes de
    repos (0 = x, 1 = y, 2 = z)."""
    A = sk.axes[bone]
    return A @ ia.axis_angle([1 if i == axis else 0 for i in range(3)], deg) @ A.T


def leg_ik(sk, side, hip, ankle, pole, G_hips):
    """Deux segments : cuisse et jambe, cheville imposée, genou dans le plan
    orienté par `pole`. Renvoie les rotations globales et l'extension
    (1 = jambe tendue au maximum autorisé)."""
    np = np_()
    l1, l2 = getattr(sk, side + '_l1'), getattr(sk, side + '_l2')
    d = ankle - hip
    D = float(np.linalg.norm(d))
    reach = (l1 + l2) * .9995
    ext = D / reach
    D = min(D, reach)
    u = d / np.linalg.norm(d)
    v = pole - (pole @ u) * u
    v = v / np.linalg.norm(v)
    ca = (l1 * l1 + D * D - l2 * l2) / (2 * l1 * D)
    a = math.acos(max(-1.0, min(1.0, ca)))
    knee = hip + l1 * (math.cos(a) * u + math.sin(a) * v)
    ankle_reached = hip + D * u

    def frame(t, pl):
        t = t / np.linalg.norm(t)
        w = pl - (pl @ t) * t
        w = w / np.linalg.norm(w)
        return np.stack([t, w, np.cross(t, w)], axis=1)

    up0, kn0, an0 = sk.H[side + 'UpLeg'], sk.H[side + 'Leg'], sk.H[side + 'Foot']
    pole0 = np.array([0.0, 0.0, 1.0])
    R1 = frame(knee - hip, pole) @ frame(kn0 - up0, pole0).T
    R2 = frame(ankle_reached - knee, pole) @ frame(an0 - kn0, pole0).T
    return R1, R2, ext


def pose_globals(pose, sk=None):
    """Rotations globales (repère du corps, autour de la tête de chaque os)
    et translation du bassin pour une pose complète. Renvoie aussi
    l'extension des jambes (contrôle)."""
    np = np_()
    sk = sk or skeleton()
    p = dict(NEUTRAL)
    p.update(pose)
    G = {}
    G['Hips'] = Ry(p['hip_y']) @ Rx(p['hip_p']) @ Rz(p['hip_r'])
    share = {'Spine': .3, 'Spine1': .35, 'Spine2': .35}
    parent = G['Hips']
    for b in ('Spine', 'Spine1', 'Spine2'):
        s = share[b]
        G[b] = parent @ Ry(p['sp_y'] * s) @ Rx(p['sp_p'] * s) @ Rz(p['sp_r'] * s)
        parent = G[b]
    G['Neck'] = G['Spine2'] @ Ry(p['nk_y']) @ Rx(p['nk_p']) @ Rz(p['nk_r'])
    G['Head'] = G['Neck'] @ Ry(p['hd_y']) @ Rx(p['hd_p']) @ Rz(p['hd_r'])
    G['HeadTop_End'] = G['Head']
    for pre, side in SIDES:
        cl = Ry(-p[pre + 'cl_fw']) @ Rz(p[pre + 'cl_up'])
        G[side + 'Shoulder'] = G['Spine2'] @ (cl if pre == 'l_' else mirror(cl))
        G[side + 'Arm'] = G['Spine2'] @ arm_chest(p, pre)
        fa = Ry(-p[pre + 'el']) @ Rx(p[pre + 'fa_tw'])
        G[side + 'ForeArm'] = G[side + 'Arm'] @ (fa if pre == 'l_' else mirror(fa))
        hd = Rx(p[pre + 'wr_tw']) @ Rz(-p[pre + 'wr_fl']) @ Ry(-p[pre + 'wr_dv'])
        G[side + 'Hand'] = G[side + 'ForeArm'] @ (hd if pre == 'l_' else mirror(hd))
        # doigts : fermeture autour de l'axe x propre de chaque phalange
        fist = p[pre + 'fist']
        for f in FINGERS:
            c = fist
            if f == 'Index' and p[pre + 'idx'] >= 0:
                c = p[pre + 'idx']
            par = G[side + 'Hand']
            for j, amp in zip((1, 2, 3, 4), (82, 100, 72, 0)):
                b = f'{side}Hand{f}{j}'
                G[b] = par @ local_axis_rot(sk, b, 0, c * amp)
                par = G[b]
        # pouce : flexion (x) et opposition (z) de la première phalange,
        # flexion des suivantes
        par = G[side + 'Hand']
        tc, to = p[pre + 'th_c'], p[pre + 'th_o']
        for j, amp in zip((1, 2, 3, 4), (30, 38, 45, 0)):
            b = f'{side}HandThumb{j}'
            R = local_axis_rot(sk, b, 0, tc * amp)
            if j == 1:
                # axes z des pouces non symétriques dans le squelette Mixamo :
                # signe inversé à droite (vérifié : miroir exact à 4 mm près)
                R = local_axis_rot(sk, b, 2, to if pre == 'l_' else -to) @ R
            G[b] = par @ R
            par = G[b]
    # bassin et jambes (pieds fixes)
    root = np.array([p['px'], p['py'], p['pz']])
    P_hips = sk.H['Hips'] + root
    fwd = G['Hips'] @ np.array([0.0, 0.0, 1.0])
    ext = {}
    for pre, side in SIDES:
        hip = P_hips + G['Hips'] @ (sk.H[side + 'UpLeg'] - sk.H['Hips'])
        ankle = sk.H[side + 'Foot'].copy()
        out = np.array([1.0 if side == 'Left' else -1.0, 0, 0])
        pole = normalize(fwd + .12 * out)
        R1, R2, e = leg_ik(sk, side, hip, ankle, pole, G['Hips'])
        G[side + 'UpLeg'], G[side + 'Leg'] = R1, R2
        G[side + 'Foot'] = np.eye(3)
        G[side + 'ToeBase'] = np.eye(3)
        G[side + 'Toe_End'] = np.eye(3)
        ext[side] = e
    return G, root, ext


def to_local(G, sk=None):
    """Quaternions locaux (ordre du squelette) depuis les rotations globales."""
    np = np_()
    sk = sk or skeleton()
    q = np.zeros((len(sk.bones), 4))
    for i, b in enumerate(sk.bones):
        par = sk.parents[i]
        L = G[b] if par is None else G[par].T @ G[b]
        q[i] = ia.mat_to_quat(L)
        if q[i, 3] < 0:
            q[i] *= -1
    return q


# ================================================================= clés --

def ease(kind, u):
    u = min(1.0, max(0.0, u))
    if kind == 'l':
        return u
    if kind == 'io':          # lent aux deux bouts
        return u * u * (3 - 2 * u)
    if kind == 'io5':         # plus franc au milieu
        return u * u * u * (u * (6 * u - 15) + 10)
    if kind == 'o':           # départ vif, arrivée amortie
        return 1 - (1 - u) ** 3
    if kind == 'o2':
        return 1 - (1 - u) ** 2
    if kind == 'i':           # départ lent, arrivée vive (coup, impact)
        return u ** 3
    if kind == 'i2':
        return u * u
    raise ValueError(kind)


# décalage (s) des mouvements secondaires : la tête, le cou, les clavicules
# et les mains arrivent quelques images après le corps
DELAY = {'hd_': .1, 'nk_': .066, 'cl_': .05, 'wr_': .066, 'fist': .05, 'idx': .05,
         'th_': .05, 'fa_': .033}


def channel_delay(name, offsets=None):
    base = name[2:] if name[:2] in ('l_', 'r_') else name
    d = 0.0
    for k, v in DELAY.items():
        if base.startswith(k):
            d = v
            break
    for k, v in (offsets or {}).items():
        if name.startswith(k) or base.startswith(k):
            d += v
    return d


class Anim:
    """Animation : poses clés (temps, changements, courbe du segment qui
    arrive sur la clé), boucle ou geste qui revient à l'attente."""

    def __init__(self, ident, nom, famille, duree, boucle, phases, respirations=2,
                 respiration_amp=1.0):
        self.id, self.nom, self.famille = ident, nom, famille
        self.duree, self.boucle = duree, boucle
        self.phases = phases            # [(nom, fin_s)]
        self.keys = [(0.0, {}, 'io')]
        self.breaths = respirations
        self.breath_amp = respiration_amp
        self.extra = []                 # couches ajoutées : f(t) -> dict
        self.offsets = {}               # décalages propres (s) : préfixe -> s
        # respiration (degrés au plus fort de l'inspiration, × respiration_amp)
        self.breath_weights = {'sp_p': -2.6, 'nk_p': 1.6, 'cl_up': 3.0, 'ar_dn': -1.2}

    def key(self, t, ease_kind='io', **kw):
        self.keys.append((float(t), P(**kw), ease_kind))
        return self

    def hold(self, t, ease_kind='io', **drift):
        """Pose tenue jusqu'à t ; `drift` : léger mouvement pendant la tenue
        (« moving hold », jamais d'image morte)."""
        self.keys.append((float(t), P(**drift), ease_kind if drift else 'l'))
        return self

    def back(self, t, ease_kind='io'):
        """Retour à la pose d'attente."""
        self.keys.append((float(t), {k: v for k, v in NEUTRAL.items()}, ease_kind))
        return self

    def poses(self):
        cur = dict(NEUTRAL)
        out = []
        for t, ch, e in sorted(self.keys, key=lambda k: k[0]):
            cur = dict(cur)
            cur.update(ch)
            out.append((t, cur, e))
        return out

    def channel(self, keys, name, t):
        if t <= keys[0][0]:
            return keys[0][1][name]
        for (t0, p0, _), (t1, p1, e) in zip(keys, keys[1:]):
            if t <= t1:
                u = (t - t0) / (t1 - t0) if t1 > t0 else 1.0
                return p0[name] + (p1[name] - p0[name]) * ease(e, u)
        return keys[-1][1][name]

    def sample(self, t):
        keys = self.poses()
        out = {}
        for name in NEUTRAL:
            # décalage borné aux extrémités : départ et arrivée exactement sur
            # la pose d'attente (transitions entre animations), boucles comprises
            tt = min(self.duree, max(0.0, t - channel_delay(name, self.offsets)))
            out[name] = self.channel(keys, name, tt)
        # respiration : poitrine qui se soulève, clavicules, tête compensée
        # (la tête suit de 2 à 3 images)
        def breath(tt):
            return ((1 - math.cos(2 * math.pi * self.breaths * tt / self.duree)) / 2
                    * self.breath_amp)
        b, bh = breath(t), breath(t - .08)
        w = self.breath_weights
        out['sp_p'] += w['sp_p'] * b
        out['nk_p'] += w['nk_p'] * bh
        out['hd_p'] += w.get('hd_p', 0) * bh
        out['l_cl_up'] += w['cl_up'] * b
        out['r_cl_up'] += w['cl_up'] * b
        out['l_ar_dn'] += w['ar_dn'] * b
        out['r_ar_dn'] += w['ar_dn'] * b
        for f in self.extra:
            for k, v in f(t).items():
                out[k] += v
        return out

    def frames(self):
        return int(round(self.duree * FPS)) + 1

    def motion(self):
        """Mouvement échantillonné (ia.Motion) et relevés par image."""
        np = np_()
        sk = skeleton()
        n = self.frames()
        local = np.zeros((n, len(sk.bones), 4))
        roots = np.zeros((n, 3))
        exts = []
        poses = []
        for f in range(n):
            pose = self.sample(f / FPS)
            G, root, ext = pose_globals(pose, sk)
            local[f] = to_local(G, sk)
            roots[f] = root
            exts.append(ext)
            poses.append(pose)
        for f in range(1, n):
            flip = (local[f] * local[f - 1]).sum(axis=1) < 0
            local[f, flip] *= -1
        m = ia.Motion(sk.bones, sk.parents, sk.heads, FPS, local, roots)
        m.poses, m.exts = poses, exts
        return m

    def phase_list(self):
        out, t = [], 0.0
        for nom, fin in self.phases:
            out.append({'nom': nom, 'type': 'isometrique', 'debut_s': round(t, 3),
                        'fin_s': round(fin, 3)})
            t = fin
        return out


# ============================================================ contrôles --

# limites articulaires (degrés) des canaux, amplitude humaine courante
LIMITS = {
    'hip_p': (-15, 25), 'hip_r': (-12, 12), 'hip_y': (-25, 25),
    'sp_p': (-25, 40), 'sp_r': (-30, 30), 'sp_y': (-35, 35),
    'nk_p': (-30, 35), 'nk_y': (-45, 45), 'nk_r': (-25, 25),
    'hd_p': (-30, 30), 'hd_y': (-56, 56), 'hd_r': (-28, 28),
    'cl_up': (-8, 25), 'cl_fw': (-15, 20),
    'ar_dn': (-95, 90), 'ar_fw': (-45, 170), 'ar_tw': (-90, 90),
    'el': (0, 145), 'fa_tw': (-35, 35),
    'wr_fl': (-60, 70), 'wr_dv': (-20, 30), 'wr_tw': (-80, 80),
    'fist': (0, 1.05), 'idx': (-1, 1.05), 'th_c': (-.5, 1.2), 'th_o': (-50, 60),
    'py': (-.12, .01), 'px': (-.08, .08), 'pz': (-.08, .08),
}

# capsules du corps (os de départ, os d'arrivée ou None = queue, rayon m) :
# rayons d'un athlète de force « fit », avec marge
CAPSULES = {
    'bassin': ('Hips', 'Spine', .135),
    'abdomen': ('Spine', 'Spine2', .13),
    'thorax': ('Spine2', 'Neck', .145),
    'tete': ('Head', 'HeadTop_End', .1),
    'l_bras': ('LeftArm', 'LeftForeArm', .052),
    'l_avantbras': ('LeftForeArm', 'LeftHand', .04),
    'l_main': ('LeftHand', 'LeftHandMiddle2', .03),
    'r_bras': ('RightArm', 'RightForeArm', .052),
    'r_avantbras': ('RightForeArm', 'RightHand', .04),
    'r_main': ('RightHand', 'RightHandMiddle2', .03),
    'l_cuisse': ('LeftUpLeg', 'LeftLeg', .08),
    'l_jambe': ('LeftLeg', 'LeftFoot', .055),
    'r_cuisse': ('RightUpLeg', 'RightLeg', .08),
    'r_jambe': ('RightLeg', 'RightFoot', .055),
}
# paires contrôlées (membres entre eux et contre le tronc) ; les paires
# voisines (épaule-thorax, hanche-bassin) sont naturellement en contact
PAIRS = [
    ('l_main', 'thorax'), ('l_main', 'abdomen'), ('l_main', 'tete'), ('l_main', 'l_cuisse'),
    ('r_main', 'thorax'), ('r_main', 'abdomen'), ('r_main', 'tete'), ('r_main', 'r_cuisse'),
    ('l_avantbras', 'thorax'), ('l_avantbras', 'abdomen'), ('l_avantbras', 'tete'),
    ('r_avantbras', 'thorax'), ('r_avantbras', 'abdomen'), ('r_avantbras', 'tete'),
    ('l_main', 'r_main'), ('l_avantbras', 'r_avantbras'), ('l_main', 'r_avantbras'),
    ('r_main', 'l_avantbras'), ('l_cuisse', 'r_cuisse'), ('l_jambe', 'r_jambe'),
    ('l_main', 'bassin'), ('r_main', 'bassin'),
]


HAND_THICKNESS = .028   # m : épaisseur de la main à la paume (athlète)


def palm_centre(motion, f, side):
    _, Pp = motion.globals(f)
    s = 'Left' if side == 'l_' else 'Right'
    return (Pp[motion.index[s + 'Hand']] + Pp[motion.index[s + 'HandMiddle1']]) / 2


def seg_dist(a0, a1, b0, b1):
    """Distance minimale entre deux segments."""
    np = np_()
    d1, d2, r = a1 - a0, b1 - b0, a0 - b0
    a, e, f = d1 @ d1, d2 @ d2, d2 @ r
    c, b = d1 @ r, d1 @ d2
    den = a * e - b * b
    s = np.clip((b * f - c * e) / den, 0, 1) if den > 1e-12 else 0.0
    t = (b * s + f) / e if e > 1e-12 else 0.0
    if t < 0:
        t, s = 0.0, np.clip(-c / a, 0, 1) if a > 1e-12 else 0.0
    elif t > 1:
        t, s = 1.0, np.clip((b - c) / a, 0, 1) if a > 1e-12 else 0.0
    return float(np.linalg.norm((a0 + d1 * s) - (b0 + d2 * t)))


def capsule_points(motion, f):
    _, Pp = motion.globals(f)
    idx = motion.index
    return {k: (Pp[idx[a]], Pp[idx[b]], r) for k, (a, b, r) in CAPSULES.items()}


def check(anim, motion, contact_ok=()):
    """Contrôles automatiques d'une animation. Renvoie un rapport (dict) ;
    `rapport['ok']` faux si un contrôle échoue."""
    np = np_()
    sk = skeleton()
    rep = {'id': anim.id, 'duree_s': anim.duree, 'images': motion.frames, 'defauts': []}
    if not 3 <= anim.duree <= 6:
        rep['defauts'].append(f'durée {anim.duree} s hors de 3 à 6 s')
    # départ et arrivée : pose d'attente (transitions), boucle sans à-coup
    q0, q1 = motion.local[0], motion.local[-1]
    ends = max(ia.angle_deg(a, b) for a, b in zip(q0, q1))
    Gn, rn, _ = pose_globals({}, sk)
    qn = to_local(Gn, sk)
    start = max(ia.angle_deg(a, b) for a, b in zip(q0, qn))
    rep['ecart_debut_fin_deg'] = round(ends, 3)
    rep['ecart_attente_deg'] = round(start, 3)
    tol = .5
    if ends > tol or start > tol:
        rep['defauts'].append(f'départ / arrivée différents de la pose d\'attente '
                              f'({ends:.2f}°, {start:.2f}°)')
    if anim.boucle:
        # vitesse à la jonction : dernière image → première ≈ images voisines
        jump = max(ia.angle_deg(a, b) for a, b in zip(motion.local[-2], motion.local[1]))
        step = max(max(ia.angle_deg(a, b) for a, b in zip(motion.local[f], motion.local[f + 1]))
                   for f in range(motion.frames - 1))
        rep['jonction_deg'] = round(jump, 3)
        if jump > max(2.5 * step / 2, 1.0) * 2:
            rep['defauts'].append(f'boucle : à-coup à la jonction ({jump:.2f}°)')
    # limites
    worst = {}
    for pose in motion.poses:
        for k, v in pose.items():
            base = k[2:] if k[:2] in ('l_', 'r_') else k
            lo, hi = LIMITS.get(base, (-1e9, 1e9))
            if v < lo - 1e-6 or v > hi + 1e-6:
                worst[k] = v
    if worst:
        rep['defauts'].append('limites dépassées : ' + ', '.join(
            f'{k}={v:.1f}' for k, v in list(worst.items())[:6]))
    ext = max(max(e.values()) for e in motion.exts)
    rep['extension_jambes_max'] = round(ext, 4)
    if ext > 1.0:
        rep['defauts'].append(f'jambe tendue au-delà de sa longueur ({ext:.4f})')
    # pieds fixes
    feet = ['LeftFoot', 'LeftToeBase', 'LeftToe_End', 'RightFoot', 'RightToeBase', 'RightToe_End']
    ref = {}
    slide = 0.0
    for f in range(motion.frames):
        _, Pp = motion.globals(f)
        for b in feet:
            p = Pp[motion.index[b]]
            if b not in ref:
                ref[b] = p
            slide = max(slide, float(np.linalg.norm(p - ref[b])))
    rep['glissement_pieds_mm'] = round(slide * 1000, 3)
    if slide > .001:
        rep['defauts'].append(f'pieds qui glissent ({slide * 1000:.1f} mm)')
    # interpénétration (capsules)
    worst_pen = (0.0, None, None)
    contacts = {}
    for f in range(motion.frames):
        caps = capsule_points(motion, f)
        for a, b in PAIRS:
            a0, a1, ra = caps[a]
            b0, b1, rb = caps[b]
            d = seg_dist(a0, a1, b0, b1) - ra - rb
            if (a, b) in contact_ok or (b, a) in contact_ok:
                # contact voulu des paumes : distance des centres des paumes
                # (au milieu de l'épaisseur de la main) ≥ épaisseur d'une main
                pa = palm_centre(motion, f, a[:2])
                pb = palm_centre(motion, f, b[:2])
                d = float(np.linalg.norm(pa - pb)) - HAND_THICKNESS
                contacts[(a, b)] = min(contacts.get((a, b), 9), d)
                if d < -.004 and -d > worst_pen[0]:
                    worst_pen = (-d, f'{a}/{b}', f)
                continue
            if d < -.004 and -d > worst_pen[0]:
                worst_pen = (-d, f'{a}/{b}', f)
    rep['interpenetration_mm'] = round(worst_pen[0] * 1000, 1)
    if worst_pen[1]:
        rep['interpenetration_ou'] = f'{worst_pen[1]} (image {worst_pen[2]})'
        rep['defauts'].append(f'interpénétration {worst_pen[1]} de {worst_pen[0] * 1000:.0f} mm '
                              f'(image {worst_pen[2]})')
    rep['contacts_mm'] = {f'{a}/{b}': round(d * 1000, 1) for (a, b), d in contacts.items()}
    rep['ok'] = not rep['defauts']
    return rep


# ================================================================== FBX --

def build_armature():
    """Armature Blender du personnage depuis `squelette_mixamo.json` (os
    `mixamorig:`), sans maillage : ni personnage ni clé nécessaires."""
    import bpy
    from mathutils import Matrix
    np = np_()
    sk = skeleton()
    C = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]], dtype=np.float64)   # Blender → glTF
    bpy.ops.wm.read_factory_settings(use_empty=True)
    data = bpy.data.armatures.new('Armature')
    arm = bpy.data.objects.new('Armature', data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for b in sk.bones:
        e = data.edit_bones.new('mixamorig:' + b)
        length = float(np.linalg.norm(sk.tails[b] - sk.H[b])) or .01
        M = np.eye(4)
        M[:3, :3] = C.T @ sk.axes[b]            # axes de l'os (Blender)
        M[:3, 3] = C.T @ sk.H[b]
        e.head = (0, 0, 0)
        e.tail = (0, length, 0)
        e.matrix = Matrix(M.tolist())
        eb[b] = e
    for b, par in zip(sk.bones, sk.parents):
        if par:
            eb[b].parent = eb[par]
            eb[b].use_connect = False
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm


def write_fbx(motion, out, log=print):
    """FBX « Without Skin » : armature du personnage, une clé par image."""
    import bpy
    from mathutils import Matrix
    np = np_()
    arm = build_armature()
    scene = bpy.context.scene
    scene.render.fps, scene.render.fps_base = FPS, 1
    scene.frame_start, scene.frame_end = 1, motion.frames
    aw = np.array(arm.matrix_world)
    aw_inv = np.linalg.inv(aw)
    C = np.array([[1, 0, 0], [0, 0, 1], [0, -1, 0]], dtype=np.float64)
    names = {ia.canonical(b.name): b.name for b in arm.data.bones}
    L = {c: np.array(arm.data.bones[n].matrix_local) for c, n in names.items()}
    order = list(motion.bones)
    for pb in arm.pose.bones:
        pb.rotation_mode = 'QUATERNION'
    for f in range(motion.frames):
        R, Pp = motion.globals(f)
        posed = {}
        for i, b in enumerate(order):
            Gbl = C.T @ R[i] @ C
            D = np.eye(4)
            D[:3, :3] = Gbl
            D[:3, 3] = C.T @ Pp[i] - Gbl @ (C.T @ motion.heads[i])
            posed[b] = aw_inv @ D @ aw @ L[b]
        for i, b in enumerate(order):
            par = motion.parents[i]
            if par is None:
                basis = np.linalg.inv(L[b]) @ posed[b]
            else:
                basis = np.linalg.inv(L[b]) @ L[par] @ np.linalg.inv(posed[par]) @ posed[b]
            loc, rot, _ = Matrix(basis.tolist()).decompose()
            pb = arm.pose.bones[names[b]]
            pb.location = loc
            pb.rotation_quaternion = rot
            pb.scale = (1, 1, 1)
            pb.keyframe_insert('location', frame=f + 1)
            pb.keyframe_insert('rotation_quaternion', frame=f + 1)
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.fbx(filepath=str(out), use_selection=True, object_types={'ARMATURE'},
                             add_leaf_bones=False, bake_anim=True,
                             bake_anim_use_all_actions=False, bake_anim_use_nla_strips=False,
                             bake_anim_simplify_factor=0.0, bake_anim_step=1.0)
    log(f'FBX {Path(out).name} ({Path(out).stat().st_size} octets, {motion.frames} images)')


# ============================================================ résolution --

def hand_frame(pose, side='l_', sk=None):
    """Main : centre de la paume, normale de la paume (côté paume), direction
    des doigts et du pouce, dans le repère du corps."""
    np = np_()
    sk = sk or skeleton()
    G, root, _ = pose_globals(pose, sk)
    s = 'Left' if side == 'l_' else 'Right'
    # positions : têtes posées (chaîne depuis le bassin)
    pos = {}
    for i, b in enumerate(sk.bones):
        par = sk.parents[i]
        if par is None:
            pos[b] = sk.H[b] + root
        else:
            pos[b] = pos[par] + G[par] @ (sk.H[b] - sk.H[par])
    A = sk.axes[s + 'Hand']
    Gh = G[s + 'Hand']
    palm = (pos[s + 'Hand'] + pos[s + 'HandMiddle1']) / 2
    normal = Gh @ A[:, 2]
    fingers = normalize(pos[s + 'HandMiddle1'] - pos[s + 'Hand'])
    thumb = normalize(pos[s + 'HandThumb4'] - pos[s + 'HandThumb2'])
    return {'paume': palm, 'normale': normal, 'doigts': fingers, 'pouce': thumb, 'pos': pos}


def solve_hand(pose, side, palm=None, normal=None, fingers=None, thumb=None,
               vars=('ar_dn', 'ar_fw', 'ar_tw', 'el', 'wr_tw'), weights=(1, .15, .15, .15)):
    """Canaux du bras (côté `side`) qui placent la paume et l'orientent
    (moindres carrés, bornés par les limites articulaires). Renvoie les
    changements à écrire dans une clé."""
    np = np_()
    from scipy.optimize import least_squares
    names = [side + v for v in vars]
    base = dict(NEUTRAL)
    base.update(pose)
    x0 = np.array([base[n] for n in names])
    lo = np.array([LIMITS[v][0] for v in vars])
    hi = np.array([LIMITS[v][1] for v in vars])

    def res(x):
        p = dict(base)
        p.update(dict(zip(names, x)))
        h = hand_frame(p, side)
        r = []
        if palm is not None:
            r += list((h['paume'] - np.asarray(palm)) * weights[0] * 10)
        if normal is not None:
            r += list((h['normale'] - normalize(normal)) * weights[1] * 10)
        if fingers is not None:
            r += list((h['doigts'] - normalize(fingers)) * weights[2] * 10)
        if thumb is not None:
            r += list((h['pouce'] - normalize(thumb)) * weights[3] * 10)
        # préférence douce pour la pose de départ (pas de torsion inutile)
        r += list((x - x0) * .002)
        return np.array(r)

    sol = least_squares(res, np.clip(x0, lo + 1e-6, hi - 1e-6), bounds=(lo, hi))
    return {n: round(float(v), 2) for n, v in zip(names, sol.x)}
