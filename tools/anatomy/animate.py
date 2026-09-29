#!/usr/bin/env python3
"""M6 (mannequin 3D) : chaîne de calcul des animations d'exercice.

  python3 tools/anatomy/animate.py <id> [<id>…] [--tous] [--planches dossier]
  python3 tools/anatomy/animate.py --check      (clips suivis à jour)

Entrée : la fiche biomécanique de l'exercice. Le pack (`assets/content`)
donne le plan du mouvement, le matériel et les muscles, pas les angles ni le
tempo : la fiche est complétée dans `tools/anatomy/fiches/<id>.json`
(positions clés en angles anatomiques, degrés de liberté laissés au calcul,
contacts, équilibre, phases et tempo, critères d'amplitude, sources).

Calcul (numpy / scipy, même cinématique et même peau que l'application,
`rig_def.py`, `rig_pose.py`) : pour chaque image clé, les angles imposés par
la fiche (interpolés entre les positions clés, progression lissée dans le
temps) sont complétés par une cinématique inverse (moindres carrés bornés
par les limites articulaires du rig) qui tient les contacts (mains sur la
prise, pieds fixes et à plat, barre sur les trapèzes), l'équilibre (centre
de masse du corps et de la charge au-dessus de l'appui ; sous la prise en
suspension), et écarte le corps du matériel. Aucune image clé n'est placée à
l'œil : une amplitude « automatique » est trouvée par dichotomie sur son
critère (menton au-dessus de la barre, hanche sous le genou…).

Sortie : `assets/anatomy/clips/<id>.json.gz` (≤ 5 Ko) : postures (rotations
locales en quaternions, translation du bassin, position du matériel mobile),
chronologie (temps → posture), phases (concentrique / excentrique /
isométrique), tempo, matériel et positions, vue par défaut, cadrage ;
registre `assets/anatomy/clips/index.json` (statut, date, contrôles).
L'application interpole comme ici (sphérique pour les rotations, linéaire
pour les translations) : les contrôles sont faits sur les images clés ET
entre elles, sur la posture que l'application affichera.

Blender (bpy) sert aux planches de contrôle (`render_clip.py`).

Masses segmentaires : Winter, « Biomechanics and Motor Control of Human
Movement », 4e éd. (Wiley, 2009), tableau 4.1 (d'après Dempster, 1955).
"""
import argparse
import datetime
import gzip
import io
import json
import math
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rig_def  # noqa: E402
import rig_pose  # noqa: E402

FICHES = HERE / 'fiches'
CLIPS = ROOT / 'assets/anatomy/clips'
INDEX = CLIPS / 'index.json'
EQUIPMENT = ROOT / 'assets/anatomy/equipment.json'
DETAILS = ROOT / 'assets/content/details.json.gz'
MAX_CLIP_BYTES = 5 * 1024

# Tolérances des contrôles.
CONTACT_TOL = .01          # contact tenu à 1 cm
PENETRATION_TOL = .0025    # corps / matériel (hors zones de contact)
CONTACT_PENETRATION = .006  # compression admise dans une zone de contact
SELF_TOL = .0              # capsules internes des segments : aucun recouvrement
FLOOR = 0.0                # dessus du sol
INVALID = -1000.0          # critère d'une posture invalide (voir `criterion`)

# Masse du corps (kg) pour l'équilibre avec une charge.
BODY_MASS = 75.0

# Prises : flexion des doigts selon le rayon de la barre, mesurée sur la main
# du modèle (couverture angulaire maximale autour de l'axe de la barre sans
# pénétration de plus de 3 mm : `--prises`).
GRIPS = {.014: (45.0, 90.0), .0225: (30.0, 50.0)}

# Segments : (os, point de repos du centre de masse, fraction de la masse).
# Winter 2009 : tête et cou 8,1 % ; thorax 21,6 % ; abdomen 13,9 % ; bassin
# 14,2 % ; bras 2,8 % (43,6 % depuis l'épaule) ; avant-bras 1,6 % (43 %) ;
# main 0,6 % (50,6 %) ; cuisse 10 % (43,3 %) ; jambe 4,65 % (43,3 %) ;
# pied 1,45 % (50 %).


def _lerp(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(3)]


def segments(heads):
    out = [('pelvis', [0, .93, heads['pelvis'][2]], .142),
           ('lumbar', [0, 1.04, heads['lumbar'][2]], .139),
           ('thoracic_low', [0, 1.20, heads['thoracic_low'][2] - .01], .08),
           ('thoracic_high', [0, 1.35, heads['thoracic_high'][2] + .01], .136),
           ('head', [0, 1.58, .008], .081)]
    for s in ('_l', '_r'):
        out += [
            ('upperarm' + s, _lerp(heads['upperarm' + s], heads['forearm' + s], .436), .028),
            ('radius' + s, _lerp(heads['forearm' + s], heads['hand' + s], .43), .016),
            ('hand' + s, _lerp(heads['hand' + s], heads['fingers1' + s], .506), .006),
            ('thigh' + s, _lerp(heads['thigh' + s], heads['shin' + s], .433), .10),
            ('shin' + s, _lerp(heads['shin' + s], heads['foot' + s], .433), .0465),
            ('foot' + s, [heads['foot' + s][0], .035, heads['foot' + s][2] + .06], .0145),
        ]
    return out


_PROFILES = {}


def smoothstep(u, a=3.0, b=3.0, ramp_in=.5, ramp_out=.5):
    """Profil de progression d'un segment de mouvement (M56) : vitesse en
    trapèze adouci, montée sur la fraction `ramp_in` du segment, palier à
    vitesse constante, descente sur `ramp_out` (une phase de 2 s se lit lente
    et régulière, revue de l'entraîneur). Forme des rampes selon le bout :
    - exposant 3 (arrêt tenu, tempo ≥ 1) : vitesse ∝ u² près du bout,
      accélération nulle à l'arrêt (secousse minimale, Flash & Hogan 1985) ;
    - exposant 2 (retournement sans pause, tempo 0) : vitesse ∝ u,
      accélération non nulle, la remontée repart aussitôt ;
    - exposant 1 (position de passage) : vitesse non nulle au bout.
    Avec ramp_in = ramp_out = 0,5 et a = b = 3 : ≈ 10u³ − 15u⁴ + 6u⁵."""
    key = (a, b, ramp_in, ramp_out)
    table = _PROFILES.get(key)
    if table is None:
        x = np.linspace(0, 1, 401)
        v = np.ones_like(x)
        if a > 1:
            r = np.clip(x / max(ramp_in, 1e-9), 0, 1)
            v *= r ** (a - 1)
        if b > 1:
            r = np.clip((1 - x) / max(ramp_out, 1e-9), 0, 1)
            v *= r ** (b - 1)
        pos = np.concatenate([[0.0], np.cumsum((v[1:] + v[:-1]) / 2)])
        table = _PROFILES[key] = (x, pos / pos[-1])
    x, pos = table
    return float(np.interp(u, x, pos))


# ------------------------------------------------------------------ modèle --

class Model:
    """Rig, peau, points d'appui et matériel (repère glTF)."""

    def __init__(self):
        self.m = rig_pose.load_model()
        self.rig = self.m['rig']
        self.bones = [b['nom'] for b in self.rig['os']]
        self.bidx = {b: i for i, b in enumerate(self.bones)}
        self.dofs = {b['nom']: b['ddl'] for b in self.rig['os']}
        self.heads = {b['nom']: np.array(b['tete']) for b in self.rig['os']}
        self.equipment = json.loads(EQUIPMENT.read_text(encoding='utf-8'))['elements']
        self.segments = [(b, np.array(p) - self.heads[b], w)
                         for b, p, w in segments({k: list(v) for k, v in self.heads.items()})]
        # Sommets du corps (toutes les mailles), influences et appartenance.
        pos, joints, weights, owner = [], [], [], []
        self.mesh_names = [mm['nom'] for mm in self.m['meshes']]
        for k, mm in enumerate(self.m['meshes']):
            j, w = self.m['skin'][mm['nom']]
            pos.append(mm['positions'])
            joints.append(j)
            weights.append(w)
            owner.append(np.full(len(mm['positions']), k))
        self.V = np.concatenate(pos).astype(float)
        self.J = np.concatenate(joints)
        self.W = np.concatenate(weights)
        self.owner = np.concatenate(owner)
        # Sous-échantillon pour la cinématique inverse (écart au matériel).
        rng = np.random.default_rng(6)
        # Tête et cou au complet (ils passent au ras de la barre de traction).
        neck = (self.V[:, 1] > 1.40) & (np.abs(self.V[:, 0]) < .12)
        self.is_head_neck = neck
        self.sample_base = np.sort(rng.choice(len(self.V), size=len(self.V) // 12, replace=False))
        self.sample_head = np.union1d(self.sample_base, np.nonzero(neck)[0])
        self.sample = self.sample_base
        names = np.array(self.mesh_names)
        self.is_hand = np.isin(names[self.owner], ['hand_left', 'hand_right'])
        self.is_foot = np.isin(names[self.owner], ['foot_left', 'foot_right'])
        # Bords de la main (plus de 2,6 cm de l'axe du poignet au repos : pouce
        # d'un côté, bord ulnaire de l'autre ; M56) : ils se referment autour
        # de la barre, de l'autre côté ou plus loin que la paume : il se referme autour de la barre, de l'autre côté ; le
        # volume lisse de la main ne l'articule pas, il est donc exclu du
        # contrôle de pénétration (la paume et les doigts ne le sont pas).
        lat = np.where(names[self.owner] == 'hand_left',
                       self.V[:, 0] - self.heads['hand_l'][0],
                       self.heads['hand_r'][0] - self.V[:, 0])
        self.is_thumb = self.is_hand & (np.abs(lat) > .026)
        self.is_bone = names[self.owner] == 'os'
        # Point du menton (tête, plan médian, face avant, le plus bas).
        head = self.m['meshes'][self.mesh_names.index('head')]['positions']
        sel = head[(np.abs(head[:, 0]) < .02) & (head[:, 2] > .06)]
        self.chin = sel[np.argmin(sel[:, 1])].astype(float)
        foot = self.m['meshes'][self.mesh_names.index('foot_left')]['positions']
        self.foot_len = (float(foot[:, 2].min()), float(foot[:, 2].max()))
        self._grips = {}

    # -- cinématique ------------------------------------------------------
    def expand(self, angles):
        """Angles par os avec côté depuis des clés sans côté (les deux
        côtés), `os_l` / `os_r`, ou `pelvis`."""
        out = {}
        for key, a in angles.items():
            if key in self.dofs:
                out.setdefault(key, {}).update(a)
            else:
                for b in self.bones:
                    if rig_def.base_name(b) == key:
                        out.setdefault(b, {}).update(a)
        return out

    def rotations(self, angles):
        return rig_def.posture_rotations(self.dofs, angles)

    def globals_(self, rots, trans):
        g = rig_def.forward_kinematics(self.rig, rots, tuple(trans))
        return {b: (np.array([r[:3] for r in m]), np.array([r[3] for r in m])) for b, m in g.items()}

    def point(self, g, bone, local):
        R, t = g[bone]
        return R @ local + t

    def skin(self, g, idx=None):
        """Positions déformées (mélange linéaire, comme le shader)."""
        mats = np.zeros((len(self.bones), 3, 4))
        for i, b in enumerate(self.bones):
            R, t = g[b]
            mats[i, :, :3] = R
            mats[i, :, 3] = t - R @ self.heads[b]
        V = self.V if idx is None else self.V[idx]
        J = self.J if idx is None else self.J[idx]
        W = self.W if idx is None else self.W[idx]
        p = np.hstack([V, np.ones((len(V), 1))])
        out = np.zeros((len(V), 3))
        for k in range(4):
            out += W[:, k:k + 1] * np.einsum('nij,nj->ni', mats[J[:, k]], p)
        return out

    def com(self, g):
        tot, acc = 0.0, np.zeros(3)
        for b, local, w in self.segments:
            acc += w * self.point(g, b, local)
            tot += w
        return acc / tot

    # -- prises -------------------------------------------------------------
    def grip(self, radius):
        """(angles des doigts, point de prise dans le repère de la main
        gauche) : axe de la barre le long de l'axe local X (en travers de la
        paume), placé au centre de l'enroulement des doigts."""
        radius = round(radius, 4)
        if radius in self._grips:
            return self._grips[radius]
        f1, f2 = GRIPS[radius]
        angles = self.expand({'fingers1': {'flexion': f1}, 'fingers2': {'flexion': f2}})
        g = self.globals_(self.rotations(angles), (0, 0, 0))
        k = self.mesh_names.index('hand_left')
        idx = np.nonzero(self.owner == k)[0]
        posed = self.skin(g, idx)
        R, t = g['hand_l']
        vl = (posed - t) @ R          # repère local de la main (R orthonormale)
        xlo, xhi = vl[:, 0].min() + .015, vl[:, 0].max() - .015
        sel = vl[(vl[:, 0] > xlo) & (vl[:, 0] < xhi)]
        best = None
        for y in np.arange(-.12, -.03, .0015):
            for z in np.arange(0, .12, .0015):
                d = np.hypot(sel[:, 1] - y, sel[:, 2] - z)
                dm = d.min()
                if dm < radius - .003:
                    continue
                near = d < radius + .008
                if not near.any():
                    continue
                a = np.degrees(np.arctan2(sel[near, 2] - z, sel[near, 1] - y))
                cov = len(np.unique((a // 20).astype(int)))
                score = (cov, -abs(dm - radius))
                if best is None or score > best[0]:
                    best = (score, y, z)
        point = np.array([(xlo + xhi) / 2, best[1], best[2]])
        self._grips[radius] = ({'fingers1': {'flexion': f1}, 'fingers2': {'flexion': f2}},
                               point, best[0][0])
        return self._grips[radius]


def mirror(v):
    return np.array([-v[0], v[1], v[2]])


# ------------------------------------------------------------------ matériel --

class Placed:
    """Élément de matériel placé (position, rotation autour de Y)."""

    def __init__(self, model, spec):
        self.id = spec['id']
        self.desc = model.equipment[self.id]
        self.position = np.array(spec.get('position', [0, 0, 0]), float)
        self.yaw = float(spec.get('rotation_y', 0.0))
        self.attach = spec.get('attache')     # {'os', 'hauteur'} : charge portée
        self.local = None                      # position dans le repère de l'os
        c, s = math.cos(math.radians(self.yaw)), math.sin(math.radians(self.yaw))
        self.R = np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])

    def world_position(self, model, g):
        if self.attach and self.local is not None:
            return model.point(g, self.attach['os'], self.local)
        return self.position

    def contact(self, name, model=None, g=None):
        for c in self.desc['contacts']:
            if c['nom'] == name:
                pos = self.world_position(model, g) if g is not None else self.position
                p = pos + self.R @ np.array(c['point'])
                axe = self.R @ np.array(c['axe']) if 'axe' in c else None
                return p, axe, c
        raise KeyError(f'{self.id} : contact {name} inconnu')

    def axes(self, model=None, g=None):
        """Cylindres (centre, axe, rayon, demi-longueur) pour les contrôles."""
        out = []
        for c in self.desc['contacts']:
            if c['type'] == 'axe' and 'longueur' in c and c['nom'] != 'appui_dos':
                p, axe, _ = self.contact(c['nom'], model, g)
                out.append((p, axe, c['rayon'], c['longueur'] / 2, c['nom']))
        return out


def dist_to_axis(pts, p, axe, half):
    d = pts - p
    along = d @ axe
    radial = d - np.outer(along, axe)
    r = np.linalg.norm(radial, axis=1)
    inside = np.abs(along) <= half
    return r, inside


# ------------------------------------------------------------------ fiche --

class Fiche:
    def __init__(self, model, data):
        self.model = model
        self.d = data
        self.id = data['id']
        self.bilateral = not data.get('unilateral', False)
        self.placed = {s['id']: Placed(model, s) for s in data['materiel']}
        ik = data['ik']
        self.free = ik['libres']
        self.contacts = ik.get('contacts', [])
        self.feet = ik.get('pieds')
        self.balance = ik.get('equilibre')
        self.load = ik.get('charge')
        self.driver = data['moteur']
        # Moteur « racine.y » : hauteur du bassin imposée (squat), le reste
        # (genou, cheville, hanche) calculé.
        self.root_driver = self.driver['ddl'].startswith('racine')
        self.feet_target = None
        self.start_free = ik.get('libres_depart')
        # Tête et cou échantillonnés au complet seulement s'ils passent au
        # ras du matériel (traction).
        model.sample = model.sample_head if data['ik'].get('derriere') else model.sample_base

    # Angles imposés d'une posture (progression u entre deux positions).
    def imposed(self, a, b, u):
        pa, pb = self.d['positions'][a]['angles'], self.d['positions'][b]['angles']
        out = {}
        for bone in set(pa) | set(pb):
            da, db = pa.get(bone, {}), pb.get(bone, {})
            out[bone] = {k: da.get(k, 0.0) + (db.get(k, 0.0) - da.get(k, 0.0)) * u
                         for k in set(da) | set(db)}
        # Bornes propres à une position (`bornes_positions`, correction 1 :
        # coudes des dips ouverts en bas seulement), interpolées entre a et b.
        bp = self.d['ik'].get('bornes_positions', {})
        ba, bb = bp.get(a, {}), bp.get(b, {})
        self.position_bounds = {}
        for k in set(ba) | set(bb):
            la, ha = ba.get(k) or bb[k]
            lb, hb = bb.get(k) or ba[k]
            self.position_bounds[k] = (la + (lb - la) * u, ha + (hb - ha) * u)
        return out

    def free_keys(self):
        keys = []
        free = self.free
        if self.start_free is not None and self.feet_target is None:
            # Première posture (pieds pas encore fixés) : seuls ces degrés
            # sont calculés, les autres suivent la fiche (debout).
            free = self.start_free
        for f in free:
            if f == 'racine':
                keys += ([] if self.root_driver else ['racine.y']) + ['racine.z'] + (
                    [] if self.bilateral else ['racine.x'])
            else:
                keys.append(f)
        return keys

    def bounds(self, keys):
        lo, hi = [], []
        extra = dict(self.d['ik'].get('bornes', {}))
        extra.update(getattr(self, 'position_bounds', {}))
        for k in keys:
            if k in extra:
                lo.append(float(extra[k][0]))
                hi.append(float(extra[k][1]))
                continue
            if k.startswith('racine'):
                lo.append(-3.0)
                hi.append(3.0)
                continue
            bone, dof = k.split('.')
            name = bone if bone in self.model.dofs else bone + '_l'
            d = next(x for x in self.model.dofs[name] if x['cle'] == dof)
            lo.append(float(d['min']))
            hi.append(float(d['max']))
        return np.array(lo), np.array(hi)

    def compose(self, base, keys, x):
        """Angles complets (avec côtés) et translation depuis les angles
        imposés `base` (sans côté) et les paramètres libres `x`."""
        angles = {k: dict(v) for k, v in base.items() if k != 'racine'}
        trans = np.zeros(3)
        if 'racine' in base:
            trans[1] = base['racine']['y']
        for k, v in zip(keys, x):
            if k.startswith('racine'):
                trans['xyz'.index(k[-1])] = v
            else:
                bone, dof = k.split('.')
                angles.setdefault(bone, {})[dof] = float(v)
        # Prises : doigts fermés sur la barre.
        for c in self.contacts:
            fingers, _, _ = self.model.grip(self.contact_radius(c))
            for k, v in fingers.items():
                angles.setdefault(k, {}).update(v)
        angles = self.model.expand(angles)
        if self.feet_target is not None and not self.root_driver:
            # Pieds fixes : le bassin est placé pour que les pieds restent
            # à leur place (moyenne des deux côtés, symétrique).
            g0 = self.model.globals_(self.model.rotations(angles), (0.0, 0.0, 0.0))
            trans = np.mean([self.feet_target[s][0] - g0['foot' + s][1] for s in ('_l', '_r')],
                            axis=0)
        return angles, trans

    def contact_radius(self, c):
        el, name = c['cible'].split(':')
        return next(x for x in self.placed[el].desc['contacts'] if x['nom'] == name)['rayon']

    # -- résidus ---------------------------------------------------------
    def residuals(self, g, keys, x, x0):
        M = self.model
        res = []
        for c in self.contacts:
            el, name = c['cible'].split(':')
            _, point, _ = M.grip(self.contact_radius(c))
            for side, s in (('_l', 1), ('_r', -1)):
                if c.get('cote') and c['cote'] != side:
                    continue
                target, axe, _ = self.placed[el].contact(
                    name if not c.get('par_cote') else c['par_cote'][side], M, g)
                off = c.get('decalage', 0.0)
                if off:
                    target = target + axe * off * s
                local = point if s > 0 else mirror(point)
                p = M.point(g, 'hand' + side, local)
                res += list((p - target) * 1000)
                R, _ = g['hand' + side]
                res += list(np.cross(R @ np.array([1.0, 0, 0]), axe) * 100)
        if self.feet:
            for side in ('_l', '_r'):
                R, t = g['foot' + side]
                if self.feet_target is None:
                    # À plat : dessus du pied vers le haut.
                    res += list((R @ np.array([0, 1.0, 0]) - [0, 1, 0]) * 200)
                else:
                    tt, RR = self.feet_target[side]
                    res += list((t - tt) * 1000)
                    res += list((R - RR).ravel() * 200)
        pts = M.skin(g, M.sample)
        for c in self.d['ik'].get('derriere', []):
            # Tête et cou passent derrière la barre (pas de traction nuque) :
            # tout sommet de la tête ou du cou qui n'a pas dépassé la barre
            # reste derrière son plan vertical, avec un cône d'approche
            # (pente `pente`, en m par m sous la barre) ; au-dessus de la
            # barre (menton passé), le visage est libre.
            el, name = c['cible'].split(':')
            bp, _, cc = self.placed[el].contact(name, M, g)
            hn = M.is_head_neck[M.sample]
            below = bp[1] + cc['rayon'] - pts[:, 1]
            limit = bp[2] - cc['rayon'] - c['marge'] + c['pente'] * np.maximum(0, below - .02)
            viol = np.where(hn & (below > 0) & (below < .35), np.maximum(0, pts[:, 2] - limit), 0)
            res += list(np.sort(viol)[-40:] * 1000)
        for c in self.d['ik'].get('coudes', []):
            # Orientation du bras (du coude) dans le repère du tronc : lève
            # l'ambiguïté du bras à deux segments (coudes vers le bas et
            # l'arrière sous une barre posée sur le dos).
            R, _ = g[c['repere']]
            for side, sx in (('_l', 1), ('_r', -1)):
                d = g['forearm' + side][1] - g['upperarm' + side][1]
                d = R.T @ d / np.linalg.norm(d)
                want = np.array(c['direction'], float) * [sx, 1, 1]
                res += list((d - want / np.linalg.norm(want)) * c['poids'])
        if self.d['ik'].get('genoux_dans_l_axe'):
            # Genoux dans l'axe des pieds : la cuisse, vue de dessus, suit la
            # direction du pied (pointe du pied).
            for side in ('_l', '_r'):
                th = g['shin' + side][1] - g['thigh' + side][1]
                sh = g['foot' + side][1] - g['shin' + side][1]
                ft = g['toes' + side][1] - g['foot' + side][1]
                a, b = th[[0, 2]], ft[[0, 2]]
                # Poids nul jambe tendue, plein dès 40° de flexion du genou.
                knee = math.degrees(math.acos(np.clip(
                    th @ sh / np.linalg.norm(th) / np.linalg.norm(sh), -1, 1)))
                w = float(np.clip((knee - 10) / 30, 0, 1))
                a, b = a / (np.linalg.norm(a) + 1e-9), b / np.linalg.norm(b)
                res.append(float(a[0] * b[1] - a[1] * b[0]) * 100 * w)
        if self.balance:
            com = self.system_com(g)
            if self.d['ik'].get('equilibre_charge'):
                # Charge lourde : la barre à l'aplomb du milieu du pied.
                com = self.placed[self.load['element']].world_position(M, g)
            support = self.support(g)
            res += [(com[0] - support[0]) * 300, (com[2] - support[2]) * 300]
        # Régularisation : paramètres libres près de la fiche.
        for k, v, v0 in zip(keys, x, x0):
            if k.startswith('racine'):
                # Translation sans effet (debout, pieds pas encore fixés) :
                # tenue près de l'origine.
                res.append(v * .5)
            else:
                # Poignet près de la fiche (pas de torsion pour tenir la prise) ;
                # rotation du tibia seulement quand rien d'autre ne suffit
                # (M56 : sinon le solveur alterne entre deux solutions, hanche
                # et tibia se compensant).
                res.append((v - v0) * (.2 if k.startswith('hand.') else
                                       .6 if k == 'shin.rotation' else .04))
        # Écart au matériel et au sol (charnière).
        res += list(self.clearance(pts, M.sample, g) * 1000)
        return np.array(res)

    def contact_error(self, g):
        """Plus grand écart (m) d'une prise à sa cible."""
        M, worst = self.model, 0.0
        for c in self.contacts:
            el, name = c['cible'].split(':')
            _, point, _ = M.grip(self.contact_radius(c))
            for side, s in (('_l', 1), ('_r', -1)):
                target, axe, _ = self.placed[el].contact(
                    name if not c.get('par_cote') else c['par_cote'][side], M, g)
                target = target + axe * c.get('decalage', 0.0) * s
                local = point if s > 0 else mirror(point)
                worst = max(worst, float(np.linalg.norm(M.point(g, 'hand' + side, local) - target)))
        return worst

    def system_com(self, g):
        com = self.model.com(g)
        if self.load:
            item = self.placed[self.load['element']]
            m = self.load['masse']
            com = (com * BODY_MASS + item.world_position(self.model, g) * m) / (BODY_MASS + m)
        return com

    def support(self, g):
        if self.balance == 'pieds':
            M = self.model
            pts = []
            for side in ('_l', '_r'):
                mid = (M.foot_len[0] + M.foot_len[1]) / 2
                local = np.array([M.heads['foot' + side][0], .0, mid]) - M.heads['foot' + side]
                pts.append(M.point(g, 'foot' + side, local))
            return (pts[0] + pts[1]) / 2
        el, name = self.balance.split(':')
        p, _, _ = self.placed[el].contact(name, self.model, g)
        if name.startswith('prise_'):
            # Barres parallèles : entre les deux prises.
            p2, _, _ = self.placed[el].contact(
                'prise_d' if name == 'prise_g' else 'prise_g', self.model, g)
            p = (p + p2) / 2
        return p

    def clearance(self, pts, idx, g, strict=False):
        """Pénétrations (m, ≥ 0) des sommets `pts` dans le matériel et le sol.
        Mains dans leur prise et dos sous la charge : compression admise."""
        M = self.model
        out = []
        hand = M.is_hand[idx]
        thumb = M.is_thumb[idx]
        for item in self.placed.values():
            if item.id == 'sol':
                continue
            load = self.load and self.load['element'] == item.id
            for p, axe, r, half, _ in item.axes(M, g):
                d, inside = dist_to_axis(pts, p, axe, half)
                allow = np.where(hand | bool(load), r - CONTACT_PENETRATION,
                                 r + (0 if strict else .01))
                pen = np.where(inside & ~thumb, np.maximum(0, allow - d), 0)
                out.append(pen)
            if load:
                p = item.world_position(M, g)
                d, inside = dist_to_axis(pts, p, np.array([1.0, 0, 0]), .65)
                pen = np.where(inside & ~hand, np.maximum(0, .014 - CONTACT_PENETRATION - d), 0)
                out.append(pen)
        if 'sol' in self.placed:
            out.append(np.maximum(0, FLOOR - pts[:, 1]))
        if not out:
            return np.zeros(0)
        return np.max(np.vstack(out), axis=0)

    # -- résolution -------------------------------------------------------
    def solve(self, base, x_init=None, fixed=None):
        from scipy.optimize import least_squares
        keys = self.free_keys()
        lo, hi = self.bounds(keys)
        if self.feet_target is not None and not self.root_driver:
            fixed = {**(fixed or {}), **{k: 0.0 for k in keys if k.startswith('racine')}}
        for k, v in (fixed or {}).items():
            if k not in keys:
                continue
            i = keys.index(k)
            lo[i], hi[i] = v - 1e-6, v + 1e-6
        x0 = []
        for k in keys:
            if k.startswith('racine'):
                x0.append(0.0)
            else:
                bone, dof = k.split('.')
                x0.append(base.get(bone, {}).get(dof, 0.0))
        x0 = np.clip(np.array(x0, float), lo + 1e-6, hi - 1e-6)
        start = x0 if x_init is None else np.clip(x_init, lo + 1e-6, hi - 1e-6)

        def f(x):
            angles, trans = self.compose(base, keys, x)
            g = self.model.globals_(self.model.rotations(angles), trans)
            return self.residuals(g, keys, x, x0)

        scale = np.array([.05 if k.startswith('racine') else 5.0 for k in keys])
        sol = least_squares(f, start, bounds=(lo, hi), x_scale=scale, diff_step=1e-4,
                            max_nfev=240, ftol=1e-9, xtol=1e-9)
        angles, trans = self.compose(base, keys, sol.x)
        return sol.x, angles, trans

    def pose(self, base, x_init=None, fixed=None):
        x, angles, trans = self.solve(base, x_init, fixed)
        rots = self.model.rotations(angles)
        g = self.model.globals_(rots, trans)
        return {'x': x, 'angles': angles, 'rots': rots, 'trans': trans, 'g': g}

    def fix_load(self, pose):
        """Charge sur le dos : la barre est « posée » sur le haut du dos à la
        hauteur de la fiche (centre de la barre, debout) : pour chaque
        profondeur z, hauteur la plus basse où la barre ne pénètre pas le
        corps (compression admise) ; la barre est placée à la profondeur où
        cette hauteur vaut celle de la fiche (sur la pente des trapèzes).
        Position gardée dans le repère de l'os porteur."""
        if not self.load:
            return
        item = self.placed[self.load['element']]
        M = self.model
        pts = M.skin(pose['g'])
        names = np.array(M.mesh_names)[M.owner]
        keep = (np.abs(pts[:, 0]) < .25) & ~M.is_hand & (names != 'head')
        P = pts[keep]
        r = .014 - CONTACT_PENETRATION / 2
        target = self.load['hauteur'] + pose['trans'][1]
        best = None
        z0 = pose['g'][self.load['os']][1][2]
        for z in np.arange(z0 + .03, z0 - .25, -.001):
            near = np.abs(P[:, 2] - z) < r
            if not near.any():
                continue
            y_low = float(np.max(P[near, 1] + np.sqrt(r * r - (P[near, 2] - z) ** 2)))
            if y_low <= target:
                best = (z, target)
                break
        world = np.array([0.0, best[1], best[0]])
        R, t = pose['g'][self.load['os']]
        item.local = R.T @ (world - t)

    def fix_feet(self, pose):
        if self.feet:
            self.feet_target = {s: (pose['g']['foot' + s][1].copy(), pose['g']['foot' + s][0].copy())
                                for s in ('_l', '_r')}


# ------------------------------------------------------------ chronologie --

def build(model, data, log=print):
    fiche = Fiche(model, data)
    drv = fiche.driver
    bone, dof = drv['ddl'].split('.')
    positions = data['positions']
    order = data['ordre']                       # positions clés dans l'ordre
    n_steps = data.get('images_par_phase', 6)

    # Bout de segment à chaque position clé : tenue (phase isométrique
    # adjacente : exposant 3), retournement sans pause (exposant 2) ou
    # passage (même sens de part et d'autre : exposant 1).
    phase_list = data['phases']

    def end_kind(key):
        held = any(ph['de'] == ph['vers'] == key for ph in phase_list)
        if held:
            return 3.0
        arrivals = [ph['de'] for ph in phase_list if ph['vers'] == key and ph['de'] != key]
        departures = [ph['vers'] for ph in phase_list if ph['de'] == key and ph['vers'] != key]
        # Passage : on arrive d'une position et on repart vers une autre.
        if arrivals and departures and any(x != y for x in arrivals for y in departures):
            return 1.0
        return 2.0

    # Rampes : 0,3 s au plus de chaque côté d'un segment (le reste à vitesse
    # constante), sur la durée de la phase qui joue ce segment.
    seg_duration = {}
    for ph in phase_list:
        if ph['de'] != ph['vers']:
            seg_duration[(ph['de'], ph['vers'])] = ph['duree']

    def with_driver(a, b, u, values):
        dur = seg_duration.get((a, b)) or seg_duration.get((b, a)) or 1.0
        ramp = min(.5, .3 / dur)
        s = smoothstep(u, end_kind(a), end_kind(b), ramp, ramp) if a != b else 0.0
        base = fiche.imposed(a, b, s)
        va, vb = values[a], values[b]
        base.setdefault(bone, {})[dof] = va + (vb - va) * s
        if bone == 'racine':
            base['racine'] = {'y': va + (vb - va) * s}
        return base

    # Valeurs du moteur ; une valeur « auto » ({critere, min, max}) est
    # cherchée par dichotomie sur son critère.
    auto = {n: p['moteur'] for n, p in positions.items() if isinstance(p['moteur'], dict)}
    values = {n: (p['moteur'] if n not in auto else auto[n]['min'])
              for n, p in positions.items()}
    first = order[0]
    # Posture de départ : fixe la charge (itération : la barre dépend des
    # bras, les bras de la barre), puis les pieds.
    base = with_driver(first, first, 0.0, values)
    # Debout (pieds au sol) : bassin à sa hauteur de repos pendant la pose
    # de la charge.
    fixed = {'racine.y': 0.0} if fiche.feet else None
    p0 = fiche.pose(base, fixed=fixed)
    for _ in range(3):
        fiche.fix_load(p0)
        p0 = fiche.pose(base, p0['x'], fixed=fixed)
    if fiche.feet:
        # Pieds posés sur le sol (point le plus bas des pieds à 8 mm : la
        # peau du talon descend un peu quand la cheville fléchit, et un peu
        # plus entre deux images clés interpolées ; M56).
        pts = model.skin(p0['g'])
        low = pts[model.is_foot, 1].min()
        x = p0['x'].copy()
        if fiche.root_driver:
            values[first] += FLOOR + .008 - low
            base = with_driver(first, first, 0.0, values)
            y = values[first]
        else:
            x[fiche.free_keys().index('racine.y')] += FLOOR + .008 - low
            y = x[fiche.free_keys().index('racine.y')]
        p0 = fiche.pose(base, x, fixed={'racine.y': y})
        start_keys = fiche.free_keys()
        # Degrés calculés au départ mais imposés ensuite (cheville) : la
        # position de départ de la fiche prend la valeur calculée.
        for k, v in zip(start_keys, p0['x']):
            if not k.startswith('racine') and k not in fiche.free:
                b_, d_ = k.split('.')
                positions[first]['angles'].setdefault(b_, {})[d_] = round(float(v), 2)
        base = with_driver(first, first, 0.0, values)
        fiche.fix_feet(p0)
        full = fiche.free_keys()
        x = [dict(zip(start_keys, p0['x'])).get(k) for k in full]
        x = np.array([v if v is not None else _guess(fiche, base, k) for k, v in zip(full, x)])
        p0 = fiche.pose(base, x)
    for name, crit in auto.items():
        lo, hi = crit['min'], crit['max']
        for _ in range(12):
            mid = (lo + hi) / 2
            trial = fiche.pose(with_driver(name, name, 0.0, {**values, name: mid}), p0['x'])
            v = criterion(model, fiche, trial, crit)
            if v >= 0 or v <= INVALID:
                hi = mid
            else:
                lo = mid
        values[name] = round(hi, 1)
        log(f'  {name} : {drv["ddl"]} = {values[name]}° ({crit["critere"]})')

    # Postures : chaque segment de mouvement entre deux positions clés
    # différentes est échantillonné (progression lissée dans le temps).
    poses, keys_of = [], {}
    prev = p0['x']
    for a, b in zip(order, order[1:]):
        if (a, b) in keys_of or (b, a) in keys_of:
            continue
        seg = []
        for k in range(n_steps + 1):
            u = k / n_steps
            p = fiche.pose(with_driver(a, b, u, values), prev)
            prev = p['x']
            seg.append(len(poses))
            poses.append(p)
        keys_of[(a, b)] = seg
    # Posture de chaque position clé.
    key_index = {}
    for (a, b), seg in keys_of.items():
        key_index.setdefault(a, seg[0])
        key_index.setdefault(b, seg[-1])
    # Chronologie (phases du tempo).
    timeline, phases, t = [], [], 0.0
    for ph in data['phases']:
        a, b, dur = ph['de'], ph['vers'], ph['duree']
        if a == b:
            steps = [(t, key_index[a]), (t + dur, key_index[a])]
        else:
            s = keys_of.get((a, b))
            if s is None:
                s = list(reversed(keys_of[(b, a)]))
            steps = [(t + dur * k / n_steps, i) for k, i in enumerate(s)]
        for tt, i in steps:
            if timeline and abs(timeline[-1][0] - tt) < 1e-9 and timeline[-1][1] == i:
                continue
            timeline.append((round(tt, 4), i))
        phases.append({'nom': ph['nom'], 'type': ph['type'], 'debut': round(t, 4),
                       'fin': round(t + dur, 4), 'de': a, 'vers': b})
        t += dur
    fiche.key_index = key_index
    return fiche, poses, timeline, phases, values


def key_positions(data, phases):
    """Positions montrées par l'application (correction 1 : positions de
    départ et de fin, sans animation) : nom, clé de la fiche, instant de la
    chronologie où la posture est atteinte (premier instant où elle est
    tenue, sinon fin du mouvement qui y mène)."""
    out = []
    for label, key in (('Départ', data.get('depart')), ('Fin', data.get('fin'))):
        if not key:
            continue
        held = [ph['debut'] for ph in phases if ph['de'] == key and ph['vers'] == key]
        reached = [ph['fin'] for ph in phases if ph['vers'] == key]
        starts = [ph['debut'] for ph in phases if ph['de'] == key]
        t = (held or reached or starts)[0]
        out.append({'nom': label, 'cle': key, 'temps': t})
    return out


def _guess(fiche, base, key):
    if key.startswith('racine'):
        return 0.0
    bone, dof = key.split('.')
    return base.get(bone, {}).get(dof, 0.0)


def criterion(model, fiche, pose, crit):
    """≥ 0 quand le critère d'amplitude est atteint."""
    g = pose['g']
    kind = crit['critere']
    if kind == 'menton_au_dessus':
        el, name = crit['cible'].split(':')
        p, _, c = fiche.placed[el].contact(name, model, g)
        chin = model.point(g, 'head', model.chin - model.heads['head'])
        v = chin[1] - (p[1] + c['rayon'] + crit['marge'])
        # Atteint seulement par une posture valide : tête derrière la barre,
        # sans la traverser, prises tenues.
        pts = model.skin(g, model.sample)
        pen = fiche.clearance(pts, model.sample, g, strict=True)
        bad = max(float(pen.max()) - PENETRATION_TOL, fiche.contact_error(g) - CONTACT_TOL)
        # Posture invalide (prise lâchée, barre traversée) : valeur très
        # négative, reconnue par la dichotomie comme « trop loin » (M56 : une
        # flexion excessive perd la prise ; l'ancien min(v, −bad) l'envoyait
        # vers plus de flexion encore).
        return v if bad <= 0 else INVALID - bad
    if kind == 'hanche_sous_genou':
        hip = g['thigh_l'][1]
        knee = g['shin_l'][1]
        return (knee[1] - crit['marge']) - hip[1]
    raise ValueError(kind)


# ---------------------------------------------------------------- contrôles --

def interpolate(model, pa, pb, u):
    """Posture affichée par l'application entre deux postures (rotations
    interpolées sphériquement os par os, aides recalculées, translation
    linéaire)."""
    rots = {}
    for b in model.bones:
        if rig_def.helper_of(b):
            continue
        qa = pa['rots'].get(b, (0.0, 0.0, 0.0, 1.0))
        qb = pb['rots'].get(b, (0.0, 0.0, 0.0, 1.0))
        rots[b] = slerp(qa, qb, u)
    rots = rig_def.with_helpers(rots)
    trans = pa['trans'] + (pb['trans'] - pa['trans']) * u
    return {'rots': rots, 'trans': trans, 'g': model.globals_(rots, trans)}


def slerp(a, b, t):
    a, b = np.array(a, float), np.array(b, float)
    d = float(a @ b)
    if d < 0:
        b, d = -b, -d
    if d > .9995:
        q = a + (b - a) * t
    else:
        th = math.acos(min(1.0, d))
        q = (math.sin((1 - t) * th) * a + math.sin(t * th) * b) / math.sin(th)
    return tuple(q / np.linalg.norm(q))


def capsules(model):
    """Capsules internes des segments (tête → tête de l'enfant, rayon = 55 %
    de la demi-épaisseur médiane de la chair qui les entoure) : deux capsules
    de segments non voisins qui se recouvrent = pénétration dans le corps."""
    H = model.heads
    segs = {
        'tronc': ('pelvis', H['pelvis'] + [0, .05, 0], H['neck'], None),
        'tete': ('head', H['head'] + [0, .03, .01], H['head'] + [0, .12, .01], None),
    }
    for s in ('_l', '_r'):
        segs['bras' + s] = ('upperarm' + s, H['upperarm' + s], H['forearm' + s], None)
        segs['avant_bras' + s] = ('radius' + s, H['forearm' + s], H['hand' + s], None)
        segs['cuisse' + s] = ('thigh' + s, H['thigh' + s], H['shin' + s], None)
        segs['jambe' + s] = ('shin' + s, H['shin' + s], H['foot' + s], None)
    out = {}
    for name, (bone, a, b, _) in segs.items():
        a, b = np.array(a, float), np.array(b, float)
        ab = b - a
        L = np.linalg.norm(ab)
        u = ab / L
        d = model.V - a
        s = d @ u
        near = (s > .15 * L) & (s < .85 * L)
        radial = np.linalg.norm(d - np.outer(s, u), axis=1)
        own = near & (radial < .2)
        # Épaisseur : distance médiane des sommets les plus proches de l'axe.
        r = float(np.percentile(radial[own], 20)) * .55 if own.any() else .02
        out[name] = (bone, a - H[bone], b - H[bone], r)
    return out


ADJACENT = {frozenset(p) for p in [
    ('tronc', 'tete'), ('tronc', 'bras_l'), ('tronc', 'bras_r'), ('tronc', 'cuisse_l'),
    ('tronc', 'cuisse_r'), ('bras_l', 'avant_bras_l'), ('bras_r', 'avant_bras_r'),
    ('cuisse_l', 'jambe_l'), ('cuisse_r', 'jambe_r'), ('cuisse_l', 'cuisse_r')]}


def seg_dist(p1, q1, p2, q2):
    """Distance minimale entre deux segments."""
    d1, d2, r = q1 - p1, q2 - p2, p1 - p2
    a, e, f = d1 @ d1, d2 @ d2, d2 @ r
    c, b = d1 @ r, d1 @ d2
    den = a * e - b * b
    s = np.clip((b * f - c * e) / den, 0, 1) if den > 1e-12 else 0.0
    t = (b * s + f) / e
    if t < 0:
        t, s = 0.0, np.clip(-c / a, 0, 1)
    elif t > 1:
        t, s = 1.0, np.clip((b - c) / a, 0, 1)
    return float(np.linalg.norm((p1 + d1 * s) - (p2 + d2 * t)))


def check(model, fiche, poses, timeline, values, log=print):
    """Contrôles automatiques ; renvoie {nom: (réussi, détail)}."""
    data = fiche.d
    results = {}
    caps = capsules(model)
    # Échantillons : chaque posture + 3 points entre deux postures voisines
    # de la chronologie (ce que l'application affiche).
    samples = [(f'p{i}', p) for i, p in enumerate(poses)]
    for (t0, a), (t1, b) in zip(timeline, timeline[1:]):
        if a != b:
            for u in (.25, .5, .75):
                samples.append((f'{a}-{b}@{u}', interpolate(model, poses[a], poses[b], u)))
    rest = {b: np.linalg.norm(model.heads[b] - model.heads[rig_def.PARENT[b]])
            for b in model.bones if rig_def.PARENT[b]}
    worst = {'longueur': 0.0, 'contact': 0.0, 'penetration': 0.0, 'corps': 0.0,
             'sol': 0.0, 'charge': 0.0}
    where = {}
    for name, p in samples:
        g = p['g']
        # Longueurs constantes (os).
        for b, L in rest.items():
            d = abs(np.linalg.norm(g[b][1] - g[rig_def.PARENT[b]][1]) - L)
            if d > worst['longueur']:
                worst['longueur'] = d
        # Contacts à 1 cm.
        for c in fiche.contacts:
            el, cname = c['cible'].split(':')
            _, point, _ = model.grip(fiche.contact_radius(c))
            for side, s in (('_l', 1), ('_r', -1)):
                target, axe, _ = fiche.placed[el].contact(
                    cname if not c.get('par_cote') else c['par_cote'][side], model, g)
                target = target + axe * c.get('decalage', 0.0) * s
                local = point if s > 0 else mirror(point)
                e = float(np.linalg.norm(model.point(g, 'hand' + side, local) - target))
                if e > worst['contact']:
                    worst['contact'], where['contact'] = e, name
        if fiche.feet_target:
            for side in ('_l', '_r'):
                e = float(np.linalg.norm(g['foot' + side][1] - fiche.feet_target[side][0]))
                if e > worst['contact']:
                    worst['contact'], where['contact'] = e, name + ' (pied)'
        pts = model.skin(g)
        allidx = np.arange(len(model.V))
        pen = fiche.clearance(pts, allidx, g, strict=True)
        if 'sol' in fiche.placed:
            floor = np.maximum(0, FLOOR - pts[:, 1])
            worst['sol'] = max(worst['sol'], float(floor.max()))
        pen_eq = float(pen.max()) if len(pen) else 0.0
        if pen_eq > worst['penetration']:
            worst['penetration'], where['penetration'] = pen_eq, name
        if fiche.load:
            # Charge posée : surface de la barre à ≤ 1 cm du dos.
            item = fiche.placed[fiche.load['element']]
            bp = item.world_position(model, g)
            d, inside = dist_to_axis(pts[~model.is_hand], bp, np.array([1.0, 0, 0]), .3)
            gap = float(d[inside].min() - .014)
            worst['charge'] = max(worst['charge'], gap)
        # Pénétration dans le corps (capsules de segments non voisins).
        segs = {n: (model.point(g, b, a), model.point(g, b, bb), r)
                for n, (b, a, bb, r) in caps.items()}
        names = list(segs)
        for i in range(len(names)):
            for j in range(i + 1, len(names)):
                if frozenset((names[i], names[j])) in ADJACENT:
                    continue
                p1, q1, r1 = segs[names[i]]
                p2, q2, r2 = segs[names[j]]
                over = r1 + r2 - seg_dist(p1, q1, p2, q2)
                if over > worst['corps']:
                    worst['corps'], where['corps'] = over, f'{name} {names[i]}/{names[j]}'
    results['longueurs'] = (worst['longueur'] < 1e-6, f"écart max {worst['longueur'] * 1000:.4f} mm")
    results['contacts'] = (worst['contact'] <= CONTACT_TOL,
                           f"écart max {worst['contact'] * 100:.2f} cm ({where.get('contact', '-')})")
    results['materiel'] = (worst['penetration'] <= PENETRATION_TOL,
                           f"pénétration max {worst['penetration'] * 1000:.1f} mm "
                           f"({where.get('penetration', '-')})")
    if 'sol' in fiche.placed:
        results['sol'] = (worst['sol'] <= PENETRATION_TOL, f"sous le sol {worst['sol'] * 1000:.1f} mm")
    if fiche.load:
        results['charge_posee'] = (worst['charge'] <= CONTACT_TOL,
                                   f"barre-dos max {worst['charge'] * 100:.2f} cm")
    results['corps'] = (worst['corps'] <= SELF_TOL,
                        f"recouvrement max {worst['corps'] * 1000:.1f} mm ({where.get('corps', '-')})")
    # Limites articulaires (postures, angles de la fiche et du calcul).
    bad = []
    for i, p in enumerate(poses):
        for bone, a in p['angles'].items():
            for d in model.dofs[bone]:
                v = a.get(d['cle'], 0.0)
                if v < d['min'] - 1e-6 or v > d['max'] + 1e-6:
                    bad.append(f"p{i} {bone}.{d['cle']}={v:.1f}")
        for side in ('_l', '_r'):
            gh = gh_elevation(model, p['g'], side)
            if gh > rig_def.GH_MAX + 1e-6:
                bad.append(f'p{i} glénohumérale {gh:.0f}°')
    results['limites'] = (not bad, ', '.join(bad[:4]) or 'toutes les postures dans les limites du rig')
    # Amplitude, trajectoire, sens (critères de la fiche).
    for spec in data['controles']:
        ok, detail = control(model, fiche, poses, timeline, values, spec, samples)
        results[spec['nom']] = (ok, detail)
    results = {k: (bool(ok), det) for k, (ok, det) in results.items()}
    for k, (ok, det) in results.items():
        log(f"  {'OK ' if ok else 'ÉCHEC'} {k} : {det}")
    return results


def gh_elevation(model, g, side):
    """Élévation glénohumérale (degrés) : angle de l'axe de l'humérus (tête →
    coude) dans le repère de la scapula avec sa direction de repos (la
    rotation axiale de l'humérus ne compte pas ; M56)."""
    Rs, ts = g['scapula' + side]
    axis = g['forearm' + side][1] - g['upperarm' + side][1]
    local = Rs.T @ axis
    rest = model.heads['forearm' + side] - model.heads['upperarm' + side]
    c = float(local @ rest) / (np.linalg.norm(local) * np.linalg.norm(rest))
    return math.degrees(math.acos(max(-1.0, min(1.0, c))))


def control(model, fiche, poses, timeline, values, spec, samples):
    kind = spec['type']
    if kind == 'critere':
        v = criterion(model, fiche, poses[fiche.key_index[spec['position']]], spec['critere'])
        # 4 mm de tolérance : la position clé est atteinte par la chaîne
        # séquentielle (image par image), à la convergence du solveur près.
        return v >= -4e-3, f"{spec['critere']['critere']} : {v * 100:+.1f} cm"
    if kind == 'angle':
        bone, dof = spec['ddl'].split('.')
        vals = [p['angles'].get(bone + '_l', p['angles'].get(bone, {})).get(dof, 0.0)
                for p in poses]
        lo, hi = min(vals), max(vals)
        ok = lo <= spec['max_depart'] and hi >= spec['min_arrivee']
        return ok, f"{spec['ddl']} de {lo:.0f}° à {hi:.0f}°"
    if kind == 'trajectoire_verticale':
        # Charge (ou centre de masse) : écart horizontal au-dessus de l'appui.
        dev = 0.0
        for _, p in samples:
            g = p['g']
            if spec['objet'] == 'charge':
                q = fiche.placed[fiche.load['element']].world_position(model, g)
            else:
                q = fiche.system_com(g)
            s = fiche.support(g)
            dev = max(dev, abs(q[2] - s[2]), abs(q[0] - s[0]))
        return dev <= spec['tolerance'], f"{spec['objet']} : écart horizontal max {dev * 100:.1f} cm"
    if kind == 'centre_sur_appui':
        # Centre de masse du système (corps + charge) au-dessus du pied.
        dev = 0.0
        for _, p in samples:
            q, sp = fiche.system_com(p['g']), fiche.support(p['g'])
            dev = max(dev, abs(q[2] - sp[2]), abs(q[0] - sp[0]))
        return dev <= spec['tolerance'], (f"centre de masse corps + charge : écart max "
                                          f"{dev * 100:.1f} cm au milieu du pied")
    if kind == 'sens':
        # En concentrique, l'objet monte ; en excentrique, il descend.
        ok, worst = True, ''
        phase_of = fiche.d['phases']
        t = 0.0
        for ph in phase_of:
            seg = [(tt, i) for tt, i in timeline if t - 1e-9 <= tt <= t + ph['duree'] + 1e-9]
            t += ph['duree']
            if ph['type'] == 'isometrique' or len(seg) < 2:
                continue
            ys = [height(model, fiche, poses[i], spec['objet']) for _, i in seg]
            dy = ys[-1] - ys[0]
            want = 1 if ph['type'] == 'concentrique' else -1
            if want * dy < ph.get('min_deplacement', spec.get('min', .05)):
                ok = False
                worst = f"{ph['nom']} : {dy * 100:+.1f} cm"
            back = min(want * (b - a) for a, b in zip(ys, ys[1:]))
            if back < -.005:   # 5 mm : en deçà, imperceptible (calcul)
                ok = False
                worst = f"{ph['nom']} : retour en arrière de {-back * 1000:.0f} mm"
        return ok, worst or f"{spec['objet']} monte en concentrique, descend en excentrique"
    if kind == 'garde_sol':
        low = min(float(model.skin(p['g'])[:, 1].min()) for _, p in samples)
        return low >= spec['min'], f"point le plus bas {low * 100:.1f} cm au-dessus du sol"
    if kind == 'ecart_pieds':
        # Largeur de la position des pieds (centres des chevilles), debout.
        g = poses[0]['g']
        w = abs(g['foot_l'][1][0] - g['foot_r'][1][0])
        return spec['min'] <= w <= spec['max'], f"pieds à {w * 100:.0f} cm d'axe à axe"
    if kind == 'epaule_sous_coude':
        # Bas de dip : centre de l'épaule sous le coude (profondeur complète).
        g = poses[fiche.key_index[spec['position']]]['g']
        d = g['forearm_l'][1][1] - g['upperarm_l'][1][1]
        return d >= spec.get('min', 0.0), f"épaule {d * 100:+.1f} cm sous le coude"
    if kind == 'inclinaison_tronc':
        # Angle du tronc (bassin → cou) sur la verticale, à une position.
        g = poses[fiche.key_index[spec['position']]]['g']
        v = g['neck'][1] - g['pelvis'][1]
        a = math.degrees(math.atan2(v[2], v[1]))
        return spec['min'] <= a <= spec['max'], f"tronc incliné de {a:.0f}° vers l'avant"
    if kind == 'angle_position':
        # Angle d'un degré de liberté (côté gauche) à une position clé, dans un
        # intervalle : coudes vers les côtes en haut de la traction, etc.
        p = poses[fiche.key_index[spec['position']]]
        bone, dof = spec['ddl'].split('.')
        v = p['angles'].get(bone + '_l', p['angles'].get(bone, {})).get(dof, 0.0)
        return spec['min'] <= v <= spec['max'], f"{spec['ddl']} = {v:.0f}° en {spec['position']}"
    if kind == 'ordre_scapulaire':
        # Suspension active avant la flexion des coudes : à la position
        # `position`, scapulas abaissées (élévation claviculaire ≤ max) avec
        # les coudes encore tendus (flexion ≤ coude_max).
        p = poses[fiche.key_index[spec['position']]]
        el = p['angles']['clavicle_l'].get('elevation', 0.0)
        fl = p['angles']['forearm_l'].get('flexion', 0.0)
        ok = el <= spec['elevation_max'] and fl <= spec['coude_max']
        return ok, f"clavicule {el:.0f}°, coude {fl:.0f}° en {spec['position']}"
    raise ValueError(kind)


def height(model, fiche, p, obj):
    if obj == 'charge':
        return fiche.placed[fiche.load['element']].world_position(model, p['g'])[1]
    return model.com(p['g'])[1]


# ------------------------------------------------------------------ sortie --

def framing(model, fiche, poses):
    """Cadrage fixe de la boucle : boîte du corps sur toutes les postures et
    du matériel (sauf le sol), repère glTF."""
    lo, hi = np.full(3, np.inf), np.full(3, -np.inf)
    for p in poses:
        pts = model.skin(p['g'])
        lo, hi = np.minimum(lo, pts.min(0)), np.maximum(hi, pts.max(0))
        for item in fiche.placed.values():
            if item.id == 'sol':
                continue
            b = np.array(item.desc['boite'])
            pos = item.world_position(model, p['g'])
            corners = np.array([[x, y, z] for x in b[:, 0] for y in b[:, 1] for z in b[:, 2]])
            w = corners @ item.R.T + pos
            lo, hi = np.minimum(lo, w.min(0)), np.maximum(hi, w.max(0))
    return lo, hi


def body_extent(model, poses):
    """Boîte du corps seul sur toutes les postures (repère glTF)."""
    lo, hi = np.full(3, np.inf), np.full(3, -np.inf)
    for p in poses:
        pts = model.skin(p['g'])
        lo, hi = np.minimum(lo, pts.min(0)), np.maximum(hi, pts.max(0))
    return lo, hi


def clip_json(model, fiche, poses, timeline, phases, results):
    data = fiche.d
    moving = [i.id for i in fiche.placed.values() if i.attach]
    bones = [b for b in model.bones if not rig_def.helper_of(b)
             and any(abs(p['rots'].get(b, (0, 0, 0, 1))[3]) < 1 - 1e-9 for p in poses)]

    def q4(q):
        q = np.array(q, float)
        if q[3] < 0:
            q = -q
        return [round(float(c), 4) for c in q]

    # Cadrage : hauteur du corps et du matériel (barre de traction, barres
    # parallèles), largeur du corps seul (+ 10 %) : une barre olympique de
    # 2,20 m ou les montants d'une barre de traction ne réduisent pas le
    # mannequin ; vus de face, leurs extrémités peuvent sortir du cadre.
    lo, hi = framing(model, fiche, poses)
    blo, bhi = body_extent(model, poses)
    size = hi - lo
    centre = np.array([(blo[0] + bhi[0]) / 2, (lo[1] + hi[1]) / 2, (blo[2] + bhi[2]) / 2])
    width = math.hypot(bhi[0] - blo[0], bhi[2] - blo[2]) * 1.1
    # Contacts vérifiables sans le modèle (tools/tests/test_m6_clips.py) :
    # point de prise dans le repère de la main, cible fixe ou portée par la
    # charge ; pieds fixes.
    contacts = []
    for c in fiche.contacts:
        el, cname = c['cible'].split(':')
        _, point, _ = model.grip(fiche.contact_radius(c))
        for side, sx in (('_l', 1), ('_r', -1)):
            item = fiche.placed[el]
            desc = next(x for x in item.desc['contacts'] if x['nom'] == (
                cname if not c.get('par_cote') else c['par_cote'][side]))
            off = np.array(desc['point'], float) + np.array(desc['axe'], float) * c.get(
                'decalage', 0.0) * sx
            local = point if sx > 0 else mirror(point)
            entry = {'os': 'hand' + side, 'point': [round(float(v), 4) for v in local]}
            if item.attach:
                entry['element'] = item.id
                entry['decalage'] = [round(float(v), 4) for v in item.R @ off]
            else:
                entry['cible'] = [round(float(v), 4) for v in item.position + item.R @ off]
            contacts.append(entry)
    if fiche.feet_target:
        for side in ('_l', '_r'):
            contacts.append({'os': 'foot' + side, 'point': [0.0, 0.0, 0.0],
                             'cible': [round(float(v), 4) for v in fiche.feet_target[side][0]]})
    return {
        'schema': 1,
        'id': fiche.id,
        'nom': data['nom'],
        'vue': data['vue'],
        'plan': data['plan'],
        'tempo': data['tempo'],
        'duree': phases[-1]['fin'],
        'os': bones,
        'postures': [{
            'r': [q4(p['rots'].get(b, (0, 0, 0, 1))) for b in bones],
            't': [round(float(c), 4) for c in p['trans']],
            **({'m': {i: [round(float(c), 4) for c in fiche.placed[i].world_position(model, p['g'])]
                      for i in moving}} if moving else {}),
        } for p in poses],
        'chronologie': [[t, i] for t, i in timeline],
        'phases': [{k: v for k, v in ph.items() if k not in ('de', 'vers')} for ph in phases],
        'positions': key_positions(data, phases),
        'materiel': [{'id': i.id, 'position': [round(float(c), 4) for c in i.position],
                      'rotation_y': i.yaw, 'mobile': bool(i.attach)}
                     for i in fiche.placed.values()],
        'cadrage': {'centre': [round(float(c), 4) for c in centre],
                    'hauteur': round(float(size[1]), 4),
                    'largeur': round(float(width), 4)},
        'contacts': contacts,
        'controles': {k: v[0] for k, v in results.items()},
    }


def gz_bytes(obj):
    raw = json.dumps(obj, ensure_ascii=False, separators=(',', ':')).encode()
    buf = io.BytesIO()
    with gzip.GzipFile(fileobj=buf, mode='wb', mtime=0, compresslevel=9) as f:
        f.write(raw)
    return buf.getvalue()


def load_fiche(ex_id):
    path = FICHES / f'{ex_id}.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    details = json.loads(gzip.decompress(DETAILS.read_bytes()))['exercices'][ex_id]
    # Le pack fait foi pour le plan et le matériel.
    assert data['plan'] == details['plan'], (data['plan'], details['plan'])
    data['vue'] = data.get('vue') or {'sagittal': 'profil', 'frontal': 'face'}.get(
        details['plan'], 'troisQuarts')
    # Chaque matériel du pack est placé (id d'un élément de la fiche) ou
    # justifié (texte).
    placed = {m['id'] for m in data['materiel']}
    for m in details['materiel']:
        assert m in data['materiel_pack'], f'{ex_id} : matériel du pack {m} non traité'
        v = data['materiel_pack'][m]
        assert v in placed or v.startswith('non représenté'), (ex_id, m, v)
    return data


def run(ex_id, model, log=print):
    data = load_fiche(ex_id)
    log(f'{ex_id} :')
    fiche, poses, timeline, phases, values = build(model, data, log)
    results = check(model, fiche, poses, timeline, values, log)
    clip = clip_json(model, fiche, poses, timeline, phases, results)
    blob = gz_bytes(clip)
    ok = all(v[0] for v in results.values())
    size_ok = len(blob) <= MAX_CLIP_BYTES
    log(f"  {'OK ' if size_ok else 'ÉCHEC'} taille : {len(blob)} octets (≤ {MAX_CLIP_BYTES})")
    results['taille'] = (size_ok, f'{len(blob)} octets')
    return {'clip': clip, 'blob': blob, 'results': results, 'ok': ok and size_ok,
            'fiche': fiche, 'poses': poses, 'timeline': timeline, 'values': values}


def write_index(entries):
    CLIPS.mkdir(parents=True, exist_ok=True)
    INDEX.write_text(json.dumps({'schema': 1, 'clips': entries}, ensure_ascii=False, indent=1)
                     + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('ids', nargs='*')
    parser.add_argument('--tous', action='store_true', help='toutes les fiches')
    parser.add_argument('--date', default=None, help='date du registre (AAAA-MM-JJ)')
    parser.add_argument('--prises', action='store_true', help='affiche les prises mesurées')
    parser.add_argument('--check', action='store_true',
                        help='recalcule les clips suivis et vérifie qu\'ils sont à jour')
    args = parser.parse_args()
    model = Model()
    if args.check:
        stale = []
        for e in json.loads(INDEX.read_text(encoding='utf-8'))['clips']:
            out = run(e['id'], model, log=lambda *a: None)
            path = CLIPS / f"{e['id']}.json.gz"
            if not path.exists() or path.read_bytes() != out['blob']:
                stale.append(e['id'])
        print('clips à jour' if not stale else 'clips à régénérer : ' + ', '.join(stale))
        sys.exit(1 if stale else 0)
    if args.prises:
        for r in GRIPS:
            fingers, point, cov = model.grip(r)
            print(f'rayon {r * 1000:.1f} mm : doigts {fingers}, point {point.round(4)}, '
                  f'couverture {cov}/18')
        return
    ids = args.ids or ([p.stem for p in sorted(FICHES.glob('*.json'))] if args.tous else [])
    if not ids:
        parser.error('aucun exercice')
    existing = json.loads(INDEX.read_text(encoding='utf-8'))['clips'] if INDEX.exists() else []
    by_id = {e['id']: e for e in existing}
    date = args.date or datetime.date.today().isoformat()
    failed = []
    for ex_id in ids:
        out = run(ex_id, model)
        CLIPS.mkdir(parents=True, exist_ok=True)
        path = CLIPS / f'{ex_id}.json.gz'
        if out['ok']:
            path.write_bytes(out['blob'])
        elif path.exists():
            path.unlink()
        by_id[ex_id] = {
            'id': ex_id, 'fichier': f'{ex_id}.json.gz' if out['ok'] else None,
            'statut': 'valide' if out['ok'] else 'refuse',
            'date': by_id.get(ex_id, {}).get('date') if by_id.get(ex_id, {}).get(
                'empreinte') == out['blob'].hex()[-16:] else date,
            'empreinte': out['blob'].hex()[-16:],
            'controles': {k: {'ok': v[0], 'detail': v[1]} for k, v in out['results'].items()},
        }
        if not out['ok']:
            failed.append(ex_id)
    write_index([by_id[k] for k in sorted(by_id)])
    if failed:
        print('Animations refusées (démonstration 2D gardée) :', ', '.join(failed))
        sys.exit(1)


if __name__ == '__main__':
    main()
