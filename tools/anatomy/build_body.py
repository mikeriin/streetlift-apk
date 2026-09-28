#!/usr/bin/env python3
"""M56 (mannequin 3D) : hypertrophie par muscle du modèle d'exécution.

Entrée : `tools/anatomy/mannequin_base.glb` (géométrie de M4b, sortie de
`build_model.py` sans peau : 227 maillages, 62 506 triangles), `rig.json`
(centres articulaires) et `muscles_map.json` (groupe et couche des régions).
Sortie : `assets/anatomy/mannequin.glb` (sans peau : `build_rig.py` la
recalcule ensuite), `tools/anatomy/body_report.json` (mesures avant / après /
cibles, facteurs par groupe, pénétrations).

Méthode (décision du propriétaire, 28/09/2026 : athlète de force, cibles en
fraction de la taille H, tolérance ± 5 %) :
- hypertrophie **par muscle** : chaque sommet est déplacé le long de sa
  normale de δ = k · p(s) · f · t/2, où k est le facteur du groupe du muscle,
  p(s) le profil de ventre musculaire le long de l'axe principal du
  muscle (plateau sur le ventre, nul aux deux extrémités sur 20 % de la
  longueur : les tendons d'origine et d'insertion restent attachés aux os), t l'épaisseur locale du muscle
  (rayon lancé vers l'intérieur : la section du muscle grandit d'un facteur
  1 + k p, comme une hypertrophie réelle), f un facteur de « liberté » :
  1 pour la face qui s'éloigne de l'os porteur, 0,15 pour la face plaquée
  contre lui (l'os est rigide, le muscle pousse vers l'extérieur) ;
- les facteurs des groupes mesurables (bras, avant-bras, épaules, poitrine,
  cuisse, mollet, cou) sont ajustés par sécante jusqu'aux cibles ; les
  autres (dos profond, gainage, fessiers profonds) sont fixés ici ;
- muscles profonds : facteur du groupe × 0,7 (contraints par les
  superficiels), visibles à 50 % d'opacité ;
- interpénétrations résolues par itérations : distance signée
  (pseudo-normale, libigl) de chaque sommet aux muscles voisins et aux os ;
  un sommet enfoncé de plus de 1 mm est ramené à la surface (moitié du
  chemin par chaque muscle, tout le chemin contre un os), jusqu'à ce qu'il
  ne reste aucune pénétration > PENETRATION_MAX, ou que le reste soit
  antérieur au lot (mesuré sur le modèle de base, consigné).
- os, tête, mains, pieds, contexte : inchangés.

Relançable : `pip install trimesh rtree libigl --break-system-packages` puis
`python3 tools/anatomy/build_body.py` (déterministe). `--mesures` mesure
seulement le modèle courant.
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import build_rig  # noqa: E402
import measure_body  # noqa: E402

BASE = HERE / 'mannequin_base.glb'
OUT_GLB = ROOT / 'assets/anatomy/mannequin.glb'
MAP = ROOT / 'assets/anatomy/muscles_map.json'
RIG = ROOT / 'assets/anatomy/rig.json'
REPORT = HERE / 'body_report.json'

TENDON_FRACTION = .2      # part de la longueur occupée par chaque tendon
INNER_FACTOR = .15        # face contre l'os
DEEP_FACTOR = .7
PENETRATION_MAX = .001    # m
PENETRATION_ITER = 40
DEEP_LIMIT = .02          # m : au-delà, recouvrement de la source, non corrigé
SMOOTH_SIGMA = .015       # m : lissage des déplacements dans chaque maillage

# Groupes d'hypertrophie (clé du muscle → groupe), et facteurs fixés pour les
# groupes non mesurés. Les muscles non listés suivent leur groupe de
# l'application (`muscles_map.json`).
GROUP_OF_KEY = {
    # bras (tour à mi-biceps)
    'biceps_brachii_long': 'bras', 'biceps_brachii_short': 'bras', 'brachialis': 'bras',
    'coracobrachialis': 'bras', 'triceps_long': 'bras', 'triceps_lateral': 'bras',
    'triceps_medial': 'bras', 'anconeus_muscle': 'avant_bras',
    # épaules (largeur bideltoïdienne)
    'deltoid_anterior': 'epaules', 'deltoid_lateral': 'epaules', 'deltoid_posterior': 'epaules',
    'supraspinatus': 'dos_profond', 'infraspinatus': 'dos_superficiel',
    'subscapularis': 'dos_profond', 'teres_minor': 'dos_superficiel',
    # poitrine (tour sous les aisselles) : pectoraux et grand dorsal
    'pectoralis_major_clavicular': 'poitrine', 'pectoralis_major_sternocostal': 'poitrine',
    'pectoralis_major_abdominal': 'poitrine', 'pectoralis_minor': 'poitrine',
    'serratus_anterior': 'poitrine', 'latissimus_dorsi': 'poitrine', 'teres_major': 'poitrine',
    # dos superficiel (trapèzes, rhomboïdes, élévateur) : épais, fixé
    'trapezius_upper': 'dos_superficiel', 'trapezius_middle': 'dos_superficiel',
    'trapezius_lower': 'dos_superficiel', 'rhomboid_major': 'dos_superficiel',
    'rhomboid_minor': 'dos_superficiel', 'levator_scapulae': 'dos_superficiel',
    # érecteurs et dos profond
    'iliocostalis_lumborum': 'dos_profond', 'iliocostalis_thoracis': 'dos_profond',
    'longissimus_thoracis': 'dos_profond', 'spinalis_thoracis': 'dos_profond',
    'multifidus_lumborum': 'dos_profond', 'serratus_posterior_inferior': 'dos_profond',
    'serratus_posterior_superior': 'dos_profond', 'quadratus_lumborum': 'dos_profond',
    # cou
    'sternocleidomastoid': 'cou', 'scalenus_anterior': 'cou', 'scalenus_medius': 'cou',
    'scalenus_posterior': 'cou', 'splenius_capitis': 'cou', 'splenius_colli': 'cou',
    'platysma': 'peau',
    # gainage (taille : ne pas épaissir)
    'rectus_abdominis': 'gainage', 'external_oblique': 'gainage',
    'internal_oblique': 'gainage', 'transversus_abdominis': 'gainage',
    # fessiers
    'gluteus_maximus': 'fessiers', 'gluteus_medius': 'fessiers',
    'gluteus_minimus': 'fessiers_profond', 'tensor_fasciae_latae': 'fessiers',
    'piriformis': 'fessiers_profond', 'quadratus_femoris': 'fessiers_profond',
    'obturator_internus': 'fessiers_profond', 'obturator_externus': 'fessiers_profond',
    'gemellus_inferior': 'fessiers_profond', 'gemellus_superior': 'fessiers_profond',
    'iliacus': 'fessiers_profond', 'psoas_major': 'fessiers_profond',
    # cuisse
    'rectus_femoris': 'cuisse', 'vastus_lateralis': 'cuisse', 'vastus_medialis': 'cuisse',
    'vastus_intermedius': 'cuisse', 'biceps_femoris_long': 'cuisse',
    'biceps_femoris_short': 'cuisse', 'semitendinosus': 'cuisse', 'semimembranosus': 'cuisse',
    'sartorius': 'cuisse', 'gracilis': 'cuisse', 'adductor_magnus': 'cuisse',
    'adductor_longus': 'cuisse', 'adductor_brevis': 'cuisse', 'pectineus': 'cuisse',
    'popliteus': 'mollet',
    # mollet
    'gastrocnemius_lateral': 'mollet', 'gastrocnemius_medial': 'mollet', 'soleus': 'mollet',
    'plantaris': 'mollet', 'tibialis_anterior': 'mollet', 'tibialis_posterior': 'mollet',
    'fibularis_longus': 'mollet', 'fibularis_brevis': 'mollet', 'fibularis_tertius': 'mollet',
    'extensor_digitorum_longus': 'mollet', 'extensor_hallucis_longus': 'mollet',
    'flexor_digitorum_longus': 'mollet', 'flexor_hallucis_longus': 'mollet',
}
APP_GROUP_TO_GROUP = {'avant-bras': 'avant_bras'}

# Facteurs fixés (groupes non mesurés) ; les groupes mesurés partent de ces
# valeurs puis sont ajustés.
FIXED = {'dos_superficiel': .30, 'dos_profond': .18, 'gainage': .10, 'fessiers': .30,
         'fessiers_profond': .12, 'peau': 0.0}
# Groupe ajusté → (mesure, cible en fraction de H).
FITTED = {'bras': 'bras', 'avant_bras': 'avant_bras', 'epaules': 'bideltoide',
          'poitrine': 'poitrine', 'cuisse': 'cuisse', 'mollet': 'mollet', 'cou': 'cou'}
FIT_START = {'bras': .35, 'avant_bras': .20, 'epaules': .10, 'poitrine': .30,
             'cuisse': .35, 'mollet': .15, 'cou': .35}
FIT_MAX = {'bras': .8, 'avant_bras': .8, 'epaules': .8, 'cuisse': .8, 'mollet': .8,
           'poitrine': 1.6, 'cou': 1.0}


# ------------------------------------------------------------------ outils --

def belly_profile(s):
    """Profil de ventre musculaire le long de l'axe : plateau à 1 sur le
    ventre, tombant à 0 sur les 20 % de chaque extrémité (tendons d'origine
    et d'insertion, qui restent attachés aux os)."""
    def step(u):
        u = np.clip(u, 0, 1)
        return u * u * (3 - 2 * u)
    return step(s / TENDON_FRACTION) * step((1 - s) / TENDON_FRACTION)


def vertex_normals(positions, indices):
    tri = indices.reshape(-1, 3)
    p = positions[tri]
    fn = np.cross(p[:, 1] - p[:, 0], p[:, 2] - p[:, 0])
    n = np.zeros_like(positions)
    for k in range(3):
        np.add.at(n, tri[:, k], fn)
    norm = np.linalg.norm(n, axis=1, keepdims=True)
    return n / np.maximum(norm, 1e-12)


def smooth_scalar(points, values, sigma):
    """Lissage gaussien d'un champ scalaire entre sommets proches."""
    from scipy.sparse import coo_matrix, identity
    from scipy.spatial import cKDTree
    tree = cKDTree(points)
    dist = tree.sparse_distance_matrix(tree, 2.5 * sigma, output_type='coo_matrix')
    k = coo_matrix((np.exp(-dist.data ** 2 / (2 * sigma * sigma)), (dist.row, dist.col)),
                   shape=dist.shape).tocsr() + identity(len(points), format='csr')
    w = np.asarray(k.sum(1)).ravel()
    return (k @ values) / w


def seg_closest(p, a, b):
    """Point le plus proche de p sur le segment [a, b] (tableaux N×3)."""
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(1e-12, ab @ ab), 0, 1)
    return a + np.outer(t, ab)


RADIAL_GROUPS = {'bras': 'upperarm', 'epaules': 'upperarm', 'avant_bras': 'forearm',
                 'cuisse': 'thigh', 'mollet': 'shin'}
BONE_RADIUS = .012        # m : rayon de l'os porteur (diaphyse), qui ne grandit pas


def local_thickness(pos, normals, radius=.06, cap=.05):
    """Épaisseur locale d'une nappe : distance au sommet le plus proche dont
    la normale est opposée (face d'en face), bornée."""
    from scipy.spatial import cKDTree
    tree = cKDTree(pos)
    t = np.full(len(pos), np.nan)
    for i, near in enumerate(tree.query_ball_point(pos, radius)):
        near = np.array(near)
        if not len(near):
            continue
        opp = near[(normals[near] @ normals[i]) < -.3]
        if len(opp):
            t[i] = np.linalg.norm(pos[opp] - pos[i], axis=1).min()
    med = np.nanmedian(t) if np.isfinite(t).any() else .01
    return np.minimum(np.where(np.isfinite(t), t, med), cap)


class Muscle:
    """Un muscle (un côté) et son mode d'hypertrophie :
    - membres (`RADIAL_GROUPS`) : dilatation radiale autour de l'axe de l'os
      porteur, r → r · (1 + k p(s) (1 − r_os / r)) : toute la section du
      membre grandit ensemble, les muscles voisins se poussent au lieu de se
      recouvrir, l'os reste en place ;
    - tronc, cou, fessiers : épaississement le long des normales,
      δ = k p(s) f t/2 (nappes sur une cage rigide)."""

    def __init__(self, mesh, key, region, side, group, deep, rig_heads, rig_tails):
        self.mesh = mesh
        self.name = mesh['nom']
        self.key, self.group, self.deep = key, group, deep
        self.rest = mesh['positions'].astype(float).copy()
        self.pos = self.rest.copy()
        self.tri = mesh['indices'].reshape(-1, 3)
        self.normals = vertex_normals(self.rest, mesh['indices'])
        n = len(self.rest)
        # Axe principal (ACP) et abscisse s ∈ [0, 1].
        c = self.rest.mean(0)
        _, _, vt = np.linalg.svd(self.rest - c, full_matrices=False)
        axis = vt[0]
        s = (self.rest - c) @ axis
        s = (s - s.min()) / max(1e-9, s.max() - s.min())
        self.profile = belly_profile(s)
        self.radial = group in RADIAL_GROUPS
        if self.radial:
            bone = f'{RADIAL_GROUPS[group]}_{side}'
            a, b = rig_heads[bone], rig_tails[bone]
            q = seg_closest(self.rest, a, b)
            r = self.rest - q
            self.r_len = np.linalg.norm(r, axis=1)
            self.r_dir = r / np.maximum(self.r_len[:, None], 1e-9)
            self.gain = self.profile * np.maximum(0, self.r_len - BONE_RADIUS)
            return
        self.thickness = smooth_scalar(self.rest, local_thickness(self.rest, self.normals),
                                       SMOOTH_SIGMA)
        # Liberté : face qui s'éloigne de l'os porteur (segments d'os autorisés).
        bones = build_rig.allowed_bones(key, region, side)
        best = np.full(n, np.inf)
        radial = np.zeros((n, 3))
        for b in bones:
            if b not in rig_heads:
                continue
            q = seg_closest(self.rest, rig_heads[b], rig_tails[b])
            d = np.linalg.norm(self.rest - q, axis=1)
            closer = d < best
            best[closer] = d[closer]
            radial[closer] = (self.rest - q)[closer]
        radial /= np.maximum(np.linalg.norm(radial, axis=1, keepdims=True), 1e-9)
        out = np.einsum('ij,ij->i', self.normals, radial)
        free = np.clip((out + .3) / .6, 0, 1)
        self.freedom = INNER_FACTOR + (1 - INNER_FACTOR) * smooth_scalar(self.rest, free, .01)
        self.gain = self.profile * self.freedom * self.thickness / 2 * (DEEP_FACTOR if deep else 1)

    def inflate(self, k):
        if self.radial:
            self.pos = self.rest + self.r_dir * (k * self.gain)[:, None]
        else:
            self.pos = self.rest + self.normals * (k * self.gain)[:, None]


# --------------------------------------------------------------- mesures --

def measure(meshes, rig):
    return measure_body.Body.from_meshes(meshes, rig).measure()


# ----------------------------------------------------------- pénétrations --

def boundary_edges(tri):
    e = np.sort(np.vstack([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]]), axis=1)
    u, counts = np.unique(e, axis=0, return_counts=True)
    return u[counts == 1]


class Collider:
    """Pénétration des sommets d'un maillage dans un autre : un point est
    dedans si son nombre d'enroulement généralisé (libigl, robuste aux
    maillages ouverts) dépasse 0,6 ; la profondeur est sa distance à la
    surface. Les pénétrations profondes (> DEEP_LIMIT) ne sont pas des
    contacts de voisins mais des recouvrements de la source : comptées à
    part, non corrigées."""

    def __init__(self, pos, tri):
        self.pos, self.tri = np.ascontiguousarray(pos, float), np.ascontiguousarray(tri, np.int64)
        self.lo, self.hi = pos.min(0), pos.max(0)

    def overlaps(self, other, margin):
        return np.all(self.lo - margin <= other.hi) and np.all(other.lo - margin <= self.hi)

    def penetration(self, points, tol):
        """(profondeur au-delà de tol, direction de sortie, profondeur brute)."""
        import igl
        inside_box = np.all((points >= self.lo - .002) & (points <= self.hi + .002), axis=1)
        depth = np.zeros(len(points))
        raw = np.zeros(len(points))
        normal = np.zeros((len(points), 3))
        idx = np.nonzero(inside_box)[0]
        if not len(idx):
            return depth, normal, raw
        q = np.ascontiguousarray(points[idx])
        w = igl.fast_winding_number(self.pos, self.tri, q)
        inside = w > .6
        if not inside.any():
            return depth, normal, raw
        d2, _, closest = igl.point_mesh_squared_distance(q[inside], self.pos, self.tri)
        d = np.sqrt(d2)
        out = q[inside] - closest
        n = np.linalg.norm(out, axis=1, keepdims=True)
        # Sortie : du sommet vers le point de surface le plus proche.
        direction = -out / np.maximum(n, 1e-12)
        sel = idx[inside]
        raw[sel] = d
        shallow = d <= DEEP_LIMIT
        depth[sel[shallow]] = np.maximum(0, d[shallow] - tol)
        normal[sel[shallow]] = direction[shallow]
        return depth, normal, raw


def resolve_penetrations(muscles, bone_mesh, log, iterations=PENETRATION_ITER,
                         tol=PENETRATION_MAX):
    """Pousse les sommets enfoncés hors des muscles voisins (moitié du chemin
    chacun) et hors des os (tout le chemin). Renvoie l'historique du maximum
    des pénétrations de contact (≤ DEEP_LIMIT) et les recouvrements profonds."""
    bone = Collider(bone_mesh['positions'].astype(float), bone_mesh['indices'].reshape(-1, 3))
    history = []
    for it in range(iterations + 1):
        colliders = {m.name: Collider(m.pos, m.tri) for m in muscles}
        moves = {m.name: np.zeros_like(m.pos) for m in muscles}
        deepest = {m.name: np.zeros(len(m.pos)) for m in muscles}
        worst, worst_pair = 0.0, None
        deep = {}
        pairs = 0
        for a in muscles:
            ca = colliders[a.name]
            for b in muscles:
                if a is b or not ca.overlaps(colliders[b.name], .002):
                    continue
                pairs += 1
                depth, nrm, raw = colliders[b.name].penetration(a.pos, tol)
                if raw.max() > DEEP_LIMIT:
                    deep[f'{a.name} dans {b.name}'] = round(float(raw.max()) * 1000, 1)
                if depth.max() > worst:
                    worst, worst_pair = float(depth.max()), (a.name, b.name)
                moves[a.name] += .6 * (depth + (depth > 0) * tol)[:, None] * nrm
                deepest[a.name] = np.maximum(deepest[a.name], depth)
            depth, nrm, raw = bone.penetration(a.pos, tol)
            if raw.max() > DEEP_LIMIT:
                deep[f'{a.name} dans os'] = round(float(raw.max()) * 1000, 1)
            if depth.max() > worst:
                worst, worst_pair = float(depth.max()), (a.name, 'os')
            moves[a.name] += 1.05 * (depth + (depth > 0) * tol)[:, None] * nrm
        history.append({'iteration': it, 'max_mm': round((worst + tol) * 1000, 2) if worst > 0 else 0.0,
                        'pire': worst_pair, 'paires': pairs, 'profonds': deep})
        log(f'  pénétrations, itération {it} : max {history[-1]["max_mm"]:.2f} mm '
            f'({worst_pair}), {pairs} paires, {len(deep)} recouvrements profonds')
        if worst <= 0 or it == iterations:
            break
        # Dix premières itérations : 60 % du chemin, lissé sur les voisins
        # (pas de pointe) ; ensuite tout le chemin, sommet par sommet.
        gentle = it < 10
        for m in muscles:
            mv = moves[m.name]
            if np.abs(mv).max() > 0:
                if gentle:
                    mv = np.stack([smooth_scalar(m.pos, mv[:, k], .004) for k in range(3)], 1)
                else:
                    mv = mv / .6
                    # Un sommet pris en sandwich entre deux voisins (poussé
                    # tour à tour de l'un dans l'autre) ne sort jamais : le
                    # muscle s'amincit là, le sommet rentre aussi vers son
                    # propre intérieur.
                    pen = deepest[m.name] > 0
                    if pen.any():
                        n = vertex_normals(m.pos, m.mesh['indices'])
                        mv[pen] -= n[pen] * (deepest[m.name][pen] + tol)[:, None]
                m.pos = m.pos + mv
    return history


# ------------------------------------------------------------------- main --

def build(log=print):
    meshes, materials = build_rig.read_meshes(BASE)
    rig = json.loads(RIG.read_text(encoding='utf-8'))
    heads = {b['nom']: np.array(b['tete']) for b in rig['os']}
    tails = {b['nom']: np.array(b['queue']) for b in rig['os']}
    regions = {r['id']: r for r in json.loads(MAP.read_text(encoding='utf-8'))['regions']}
    before = measure(meshes, rig)
    log(measure_body.report(before, 'avant : '))
    # Pénétrations du modèle de base (référence).
    muscles = []
    for m in meshes:
        r = regions.get(m['nom'])
        if r is None or r['couche'] == 'volume':
            continue
        key, region, side = build_rig.region_of_mesh(m['nom'])
        group = GROUP_OF_KEY.get(key) or APP_GROUP_TO_GROUP.get(r['groupe'], r['groupe'])
        muscles.append(Muscle(m, key, region, side, group, r['couche'] == 'profond', heads, tails))
    log(f'{len(muscles)} muscles ; groupes : '
        + ', '.join(sorted({m.group for m in muscles})))
    bone_mesh = next(m for m in meshes if m['nom'] == 'os')
    base_pen = resolve_penetrations(muscles, bone_mesh, log, iterations=0)[0]
    log(f"  recouvrements profonds de la source : {base_pen['profonds']}")
    for m in muscles:
        m.pos = m.rest.copy()

    factors = dict(FIXED)
    factors.update(FIT_START)
    unknown = {m.group for m in muscles} - set(factors)
    assert not unknown, f'groupes sans facteur : {unknown}'
    H = before['H']

    def apply(fac):
        for m in muscles:
            m.inflate(fac[m.group])
            m.mesh['positions'] = m.pos.astype(np.float32)
        return measure(meshes, rig)

    # Ajustement par sécante (chaque groupe agit surtout sur sa mesure).
    hist = {g: [(0.0, before[k] / H)] for g, k in FITTED.items()}
    for it in range(6):
        m = apply(factors)
        converged = True
        for g, k in FITTED.items():
            target = measure_body.envelope_target(k, H)
            val = m[k] / H
            hist[g].append((factors[g], val))
            err = val / target - 1
            if abs(err) > .01:
                converged = False
            (k0, v0), (k1, v1) = hist[g][-2], hist[g][-1]
            slope = (v1 - v0) / (k1 - k0) if abs(k1 - k0) > 1e-6 and v1 != v0 else None
            if slope and slope > 0:
                new = k1 + (target - v1) / slope
            else:
                new = k1 * (target / max(v1, 1e-9))
            factors[g] = float(np.clip(new, 0.0, FIT_MAX[g]))
        log(f'  ajustement {it + 1} : ' + ', '.join(
            f"{g} {hist[g][-1][0]:.3f} → {m[k] / H:.3f} H" for g, k in FITTED.items()))
        if converged:
            break
    m = apply(factors)
    log(measure_body.report(m, 'après hypertrophie : '))
    history = resolve_penetrations(muscles, bone_mesh, log)
    for mu in muscles:
        mu.mesh['positions'] = mu.pos.astype(np.float32)
        mu.mesh['normales'] = vertex_normals(mu.pos, mu.mesh['indices']).astype(np.float32)
    after = measure(meshes, rig)
    log(measure_body.report(after, 'après : '))
    build_rig.write_glb(OUT_GLB, meshes, materials)
    displacement = {mu.name: round(float(np.linalg.norm(mu.pos - mu.rest, axis=1).max()) * 1000, 1)
                    for mu in muscles}
    report = {
        'base': str(BASE.relative_to(ROOT)), 'H_m': H,
        'cibles': measure_body.TARGETS, 'tolerance': measure_body.TOLERANCE,
        'facteurs': {k: round(v, 4) for k, v in factors.items()},
        'avant': {k: v for k, v in before.items() if k != 'niveaux'},
        'apres': {k: v for k, v in after.items() if k != 'niveaux'},
        'penetrations_base': base_pen, 'penetrations': history,
        'deplacement_max_mm': displacement,
        'triangles': sum(len(mm['indices']) // 3 for mm in meshes),
        'sommets': sum(len(mm['positions']) for mm in meshes),
        'poids_glb': OUT_GLB.stat().st_size,
    }
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mesures', action='store_true', help='mesurer seulement')
    args = parser.parse_args()
    if args.mesures:
        meshes, _ = build_rig.read_meshes(OUT_GLB)
        rig = json.loads(RIG.read_text(encoding='utf-8'))
        print(measure_body.report(measure(meshes, rig)))
        return
    build()


if __name__ == '__main__':
    main()
