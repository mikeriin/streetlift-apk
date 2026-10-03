# -*- coding: utf-8 -*-
"""Découpe des illustrations anatomiques en segments animables (« cutout »).

Refonte muscles et animations (27/09/2026). Entrées : ``front_base.png``,
``back_base.png``, ``profile_base.png`` et leurs calques de groupes
(``assets/muscles``). Sorties (``assets/muscles/anim``) :

- ``<vue>.png`` : atlas des segments (niveaux de gris + alpha) ;
- ``<vue>_calques.png`` : atlas des calques de groupes découpés par segment ;
- ``rig.json`` : pour chaque vue, chaque segment (rectangle dans l'atlas,
  articulations de référence en pixels du sprite, mode de mise à l'échelle)
  et ses calques (groupe, rectangle, décalage dans le sprite).

Vues : ``face`` (front_base), ``dos`` (back_base retourné : le moteur rend la
vue de dos comme la face vue en miroir) et ``profil`` (profile_base retourné :
le personnage regarde vers +x comme le moteur). En profil, un seul bras et une
seule jambe sont découpés (côté proche) ; le moteur les réutilise, assombris,
pour le côté éloigné. Les zones cachées par le bras (flanc du tronc) et par la
main (haut de cuisse) sont redessinées dans le style de l'illustration (aplat
sombre + fuseaux musculaires gris), visibles seulement quand le membre bouge.

Chaque segment = son cœur (partition du corps) + une marge aux articulations :
pleine sur ``SOLID`` px puis dégradée sur ``FEATHER`` px, limitée à un disque
autour de l'articulation, pour que les recouvrements ne laissent ni trou ni
cassure quand l'articulation plie.

Relançable : ``python3 tools/anim_cutout.py [--assets assets/muscles]
[--controle dossier]``.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage as nd

GROUP_FILES = {
    'pectoraux': 'pectoraux', 'épaules': 'epaules', 'biceps': 'biceps',
    'triceps': 'triceps', 'avant-bras': 'avant_bras', 'gainage': 'gainage',
    'dos': 'dos', 'quadriceps': 'quadriceps', 'ischios': 'ischios',
    'fessiers': 'fessiers', 'mollets': 'mollets',
}
SOLID, FEATHER = 5, 9
DARK = 44  # noir des contours des illustrations

# --------------------------------------------------------------------------
# Gabarits des vues, en pixels des images ORIGINALES (avant retournement).
# Articulations : 'tete' (centre de la tête), 'cou' (haut du tronc, niveau des
# épaules du modèle), 'bassin' (centre des hanches), 'epaule', 'coude',
# 'poignet', 'main' (bout du poing), 'hanche', 'genou', 'cheville', 'talon',
# 'pointe' ; suffixes _g / _d = côtés du PERSONNAGE.
# Coupes : polygones (points) qui délimitent le cœur de chaque segment.
# --------------------------------------------------------------------------
FRONT = {
    'source': 'front_base.png',
    'mirror': False,
    'joints': {
        'tete': (142, 46), 'cou': (141, 142), 'bassin': (140, 358),
        'nuque': (141, 100), 'taille': (140, 300),
        # face : le côté gauche du personnage est à droite de l'image
        'epaule_g': (227, 140), 'coude_g': (238, 252), 'poignet_g': (254, 358),
        'main_g': (256, 414),
        'epaule_d': (55, 140), 'coude_d': (42, 252), 'poignet_d': (27, 358),
        'main_d': (26, 414),
        'hanche_g': (181, 358), 'genou_g': (181, 526), 'cheville_g': (184, 710),
        'hanche_d': (100, 358), 'genou_d': (100, 526), 'cheville_d': (97, 710),
    },
}
BACK = {
    'source': 'back_base.png',
    'mirror': True,  # retourné : côté gauche du personnage à droite, comme la face
    'joints': {
        'tete': (143, 46), 'cou': (142, 142), 'bassin': (141, 358),
        'nuque': (142, 100), 'taille': (141, 300),
        # coordonnées dans l'image ORIGINALE (gauche du personnage = gauche)
        'epaule_g': (57, 140), 'coude_g': (44, 252), 'poignet_g': (26, 358),
        'main_g': (25, 414),
        'epaule_d': (227, 140), 'coude_d': (240, 252), 'poignet_d': (257, 358),
        'main_d': (258, 414),
        'hanche_g': (98, 358), 'genou_g': (98, 526), 'cheville_g': (98, 710),
        'hanche_d': (184, 358), 'genou_d': (184, 526), 'cheville_d': (184, 710),
    },
}
PROFILE = {
    'source': 'profile_base.png',
    'mirror': True,  # l'original regarde à gauche ; le moteur regarde vers +x
    'joints': {
        'tete': (55, 46), 'cou': (80, 150), 'bassin': (74, 366),
        'nuque': (76, 104), 'taille': (72, 309),
        'epaule': (88, 158), 'coude': (93, 268), 'poignet': (76, 380),
        'main': (72, 436),
        'hanche': (74, 366), 'genou': (76, 526), 'cheville': (92, 710),
        'talon': (116, 736), 'pointe': (14, 738),
    },
}


def load_la(path):
    a = np.asarray(Image.open(path).convert('LA')).astype(np.float64)
    return a[..., 0], a[..., 1] / 255.0


def poly_mask(shape, pts):
    im = Image.new('L', (shape[1], shape[0]), 0)
    ImageDraw.Draw(im).polygon([tuple(p) for p in pts], fill=255)
    return np.asarray(im) > 127


def side_of(shape, a, b):
    """Masque des pixels à gauche du vecteur a→b (repère image)."""
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    return ((b[0] - a[0]) * (yy - a[1]) - (b[1] - a[1]) * (xx - a[0])) < 0


# ------------------------------ partitions -------------------------------


def partition_frontal(lum, alpha, J, back=False):
    """Cœurs des segments pour la face (et le dos, même silhouette)."""
    H, W = alpha.shape
    body = alpha > 0.02
    yy, xx = np.mgrid[0:H, 0:W]
    cx = J['bassin'][0]
    # côté image : 'L' = x < cx
    left_side = 'd' if not back else 'g'
    right_side = 'g' if not back else 'd'
    parts = {}
    head = (yy < 96) & body
    neck = (yy >= 96) & (yy < 124) & (np.abs(xx - cx) < 26) & body
    parts['tete'] = head
    parts['cou'] = neck
    # bras : à l'extérieur d'une ligne épaule-aisselle (deltoïde compris)
    def arm_of(sign, s):
        line = [(cx + sign * 55, 112), (cx + sign * 61, 170),
                (cx + sign * 67, 232), (cx + sign * 71, 440)]
        far = cx + sign * cx
        m = poly_mask(alpha.shape, [(far, 110)] + line + [(far, 440)])
        m &= body & (yy >= 110)
        lab, _ = nd.label(m)
        keep = {lab[J[f'epaule_{s}'][1], J[f'epaule_{s}'][0]],
                lab[J[f'poignet_{s}'][1], J[f'poignet_{s}'][0]]} - {0}
        return np.isin(lab, list(keep))

    armL = arm_of(-1, left_side)
    armR = arm_of(1, right_side)
    # sous le bassin, les bras sont séparés des cuisses : composantes
    for arm, s in ((armL, left_side), (armR, right_side)):
        e, w, h = J[f'coude_{s}'], J[f'poignet_{s}'], J[f'main_{s}']
        sh = J[f'epaule_{s}']
        # coupe du coude : perpendiculaire à l'axe bras / avant-bras
        up = arm & _beyond(alpha.shape, e, sh, w, proximal=True)
        fore = arm & ~up & _beyond(alpha.shape, w, e, h, proximal=True)
        hand = arm & ~up & ~fore
        parts[f'bras_{s}'] = up
        parts[f'avant_bras_{s}'] = fore
        parts[f'main_{s}'] = hand
    arms = armL | armR
    trunk_zone = body & ~head & ~neck & ~arms
    # taille (tronc / bassin) : ligne horizontale au nombril
    waist_y = 300
    # cuisses : sous une ligne hanche externe → entrejambe
    cr_y = 386
    thighL = poly_mask(alpha.shape, [(0, 342), (cx - 30, 360), (cx, cr_y),
                                     (cx, H), (0, H)])
    thighR = poly_mask(alpha.shape, [(W, 342), (cx + 30, 360), (cx, cr_y),
                                     (cx, H), (W, H)])
    for thigh, s in ((thighL, left_side), (thighR, right_side)):
        leg = trunk_zone & thigh
        k, a = J[f'genou_{s}'], J[f'cheville_{s}']
        hp = J[f'hanche_{s}']
        th = leg & (yy < k[1])
        sh_ = leg & (yy >= k[1]) & (yy < a[1])
        ft = leg & (yy >= a[1])
        parts[f'cuisse_{s}'] = th
        parts[f'jambe_{s}'] = sh_
        parts[f'pied_{s}'] = ft
    legs = thighL | thighR
    parts['tronc'] = trunk_zone & ~legs & (yy < waist_y)
    parts['bassin'] = trunk_zone & ~legs & (yy >= waist_y)
    return parts


def _beyond(shape, joint, prev, nxt, proximal):
    """Pixels du côté de [prev] par rapport à la droite passant par [joint],
    perpendiculaire à la bissectrice prev-joint-nxt."""
    j = np.array(joint, float)
    d1 = np.array(prev, float) - j
    d2 = j - np.array(nxt, float)
    d = d1 / np.linalg.norm(d1) + d2 / np.linalg.norm(d2)
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    return ((xx - j[0]) * d[0] + (yy - j[1]) * d[1]) > 0


def profile_body_parts(alpha, J, head, neck, arm, inside):
    """Cœurs du tronc, du bassin et de la jambe (zones redessinées comprises)."""
    H, W = alpha.shape
    body = alpha > 0.02
    yy = np.mgrid[0:H, 0:W][0]
    thigh_zone = poly_mask(alpha.shape, [(0, 350), (40, 360), (74, 378),
                                         (100, 424), (W, 416), (W, H), (0, H)])
    rest = body & ~head & ~neck & ~(arm & ~inside)
    leg = rest & thigh_zone
    k, a = J['genou'], J['cheville']
    parts = {'cuisse': leg & (yy < k[1]),
             'jambe': leg & (yy >= k[1]) & (yy < a[1] - 4),
             'pied': leg & (yy >= a[1] - 4)}
    waist = poly_mask(alpha.shape, [(0, 0), (W, 0), (W, 318), (0, 300)])
    parts['tronc'] = rest & ~leg & waist
    parts['bassin'] = rest & ~leg & ~waist
    return parts


def partition_profile(lum, alpha, J, layers):
    H, W = alpha.shape
    body = alpha > 0.02
    yy, xx = np.mgrid[0:H, 0:W]
    parts = {}
    head = poly_mask(alpha.shape, [(0, 0), (W, 0), (W, 60), (100, 70),
                                   (86, 94), (48, 100), (0, 100)]) & body
    neck = (~head) & body & (yy < 132) & (xx < 118)
    # bras (côté proche) : pièces musculaires du bras + poing + traits sombres
    arm_groups = ('épaules', 'biceps', 'triceps', 'avant-bras')
    arm = np.zeros_like(body)
    for g in arm_groups:
        arm |= layers[g] > 0.3
    fist = poly_mask(alpha.shape, [(54, 376), (98, 372), (100, 398), (96, 432),
                                   (84, 440), (60, 438), (54, 410)]) & body & (lum < 90)
    arm |= fist
    arm = nd.binary_closing(arm, iterations=3)
    arm = nd.binary_fill_holes(arm)
    arm = nd.binary_dilation(arm, iterations=2) & body & (yy > 128)
    up = arm & _beyond(alpha.shape, J['coude'], J['epaule'], J['poignet'], True)
    fore = arm & ~up & _beyond(alpha.shape, J['poignet'], J['coude'], J['main'], True)
    hand = arm & ~up & ~fore
    parts['tete'] = head
    parts['cou'] = neck & ~arm
    parts['bras'] = up
    parts['avant_bras'] = fore
    parts['main'] = hand
    # cuisse : sous le pli de l'aine et le pli fessier
    thigh_zone = poly_mask(alpha.shape, [(0, 350), (40, 360), (74, 378),
                                         (100, 424), (W, 416), (W, H), (0, H)])
    rest = body & ~head & ~parts['cou'] & ~arm
    leg = rest & thigh_zone
    k, a = J['genou'], J['cheville']
    parts['cuisse'] = leg & (yy < k[1])
    parts['jambe'] = leg & (yy >= k[1]) & (yy < a[1] - 4)
    parts['pied'] = leg & (yy >= a[1] - 4)
    waist = poly_mask(alpha.shape, [(0, 0), (W, 0), (W, 318), (0, 300)])
    parts['tronc'] = rest & ~leg & waist
    parts['bassin'] = rest & ~leg & ~waist
    return parts, arm


# --------------------------- zones redessinées ---------------------------

# Muscles redessinés sous le bras (profil, image originale tournée à gauche) :
# ligne directrice (polyligne) → groupe. Chaque pixel caché est rattaché à la
# ligne la plus proche (cellules de Voronoï), puis les cellules sont séparées
# par un trait sombre et modelées comme les pièces de l'illustration.
HIDDEN_MUSCLES = [
    ([(60, 168), (80, 178), (94, 190)], 'pectoraux'),     # grand pectoral
    ([(96, 140), (118, 156)], 'dos'),                     # trapèze
    ([(98, 166), (121, 186)], 'dos'),                     # infra-épineux
    ([(104, 198), (112, 240), (111, 292)], 'dos'),        # grand dorsal
    ([(125, 204), (125, 306)], 'dos'),                    # érecteurs
    ([(64, 204), (86, 212)], 'gainage'),                  # dentelé
    ([(64, 226), (90, 235)], 'gainage'),
    ([(66, 248), (94, 258)], 'gainage'),
    ([(70, 276), (88, 300), (96, 332)], 'gainage'),       # oblique externe
    ([(102, 314), (114, 334)], 'gainage'),                # crête iliaque
    ([(58, 378), (64, 446)], 'quadriceps'),               # vaste latéral
    ([(84, 378), (92, 446)], 'quadriceps'),               # tenseur du fascia lata
]


def _polyline_dist(shape, pts):
    H, W = shape
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    best = np.full(shape, np.inf)
    for (x0, y0), (x1, y1) in zip(pts[:-1], pts[1:]):
        dx, dy = x1 - x0, y1 - y0
        t = np.clip(((xx - x0) * dx + (yy - y0) * dy) / (dx * dx + dy * dy), 0, 1)
        d = np.hypot(xx - (x0 + t * dx), yy - (y0 + t * dy))
        best = np.minimum(best, d)
    return best


def repaint_profile(lum, alpha, arm, J):
    """Flanc du tronc sous le bras et haut de cuisse sous la main, redessinés
    dans le style de l'illustration (fuseaux gris séparés par un trait sombre,
    bord de silhouette sombre), sans toucher au reste de l'image."""
    H, W = alpha.shape
    lum = lum.copy(); alpha = alpha.copy()
    hole = nd.binary_dilation(arm, iterations=1)
    # silhouette du tronc derrière le bras (dos prolongé)
    trunk_sil = poly_mask(alpha.shape, [
        (58, 126), (104, 130), (122, 148), (129, 196), (129, 262), (126, 300),
        (121, 330), (116, 372), (40, 372)])
    thigh_sil = poly_mask(alpha.shape, [(22, 360), (104, 368), (112, 452),
                                         (24, 452)])
    zone = hole & (trunk_sil | thigh_sil)
    dists = np.stack([_polyline_dist(alpha.shape, pts) for pts, _ in HIDDEN_MUSCLES])
    owner = dists.argmin(axis=0)
    inside = zone
    painted = np.full(alpha.shape, float(DARK))
    groups = {}
    outside_body = ~(inside | ((alpha > 0.5) & ~hole))
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float64)
    smooth_inside = nd.gaussian_filter(inside.astype(np.float64), 1.6) > 0.5
    for i, (pts, grp) in enumerate(HIDDEN_MUSCLES):
        cell = inside & (owner == i)
        if not cell.any():
            continue
        # contours arrondis comme les pièces de l'illustration, puis trait
        # sombre anticrénelé (~3 px) entre cellules et contre le reste
        shape = nd.gaussian_filter(cell.astype(np.float64), 2.4) > 0.5
        shape &= smooth_inside
        din = nd.distance_transform_edt(shape)
        cov = np.clip(din - 1.8, 0, 1)
        # modelé : plus clair au centre, léger dégradé le long de la fibre
        (x0, y0), (x1, y1) = pts[0], pts[-1]
        L2 = (x1 - x0) ** 2 + (y1 - y0) ** 2
        t = np.clip(((xx - x0) * (x1 - x0) + (yy - y0) * (y1 - y0)) / L2, 0, 1)
        shade = (104 + 8 * (i % 3)) + 40 * np.clip(din / 9.0, 0, 1) + 10 * (1 - t)
        val = DARK * (1 - cov) + shade * cov
        painted[cell] = val[cell]
        groups[grp] = np.maximum(groups.get(grp, np.zeros(alpha.shape)),
                                 np.where(cell, cov, 0.0))
    # bord de silhouette : 2 px sombres le long du vide
    rim = inside & nd.binary_dilation(outside_body, iterations=2)
    painted[rim] = DARK
    for g in groups.values():
        g[rim] = 0
    # marge sombre le long du bord du trou : les bords anticrénelés du bras
    # (et de la main) retombent sur du noir, comme dans l'illustration
    dh = nd.distance_transform_edt(inside)
    k = np.clip((dh - 1.5) / 2.0, 0, 1)
    painted = DARK * (1 - k) + painted * k
    for g in groups.values():
        g *= k
    lum[inside] = painted[inside]
    alpha[inside] = 1.0
    zone_groups = {g: np.where(inside, m, 0.0) for g, m in groups.items()}
    return lum, alpha, inside, zone_groups


# ------------------------------- sprites --------------------------------


def joint_weight(core, body, joints):
    """Poids du sprite : 1 dans le cœur, puis selon chaque articulation :

    - ``solid`` : disque plein de rayon r (le segment passe DESSOUS : il comble
      le coin ouvert quand l'articulation plie) ;
    - ``cap`` : chapeau circulaire centré sur l'articulation, bord dégradé
      (le segment passe DESSUS ; en tournant autour de son centre, le chapeau
      garde la même empreinte) ;
    - ``edge`` : bord de coupe dégradé sur FEATHER px (coupes hors
      articulation : taille, cou).
    """
    H, W = body.shape
    yy, xx = np.mgrid[0:H, 0:W]
    dcore = nd.distance_transform_edt(~core)
    w = core.astype(np.float64)
    for (x, y), mode, r in joints:
        d = np.hypot(xx - x, yy - y)
        if mode == 'solid':
            e = np.clip(r + 1 - d, 0, 1)
        elif mode == 'cap':
            e = np.clip((r + FEATHER / 2 - d) / FEATHER, 0, 1)
        else:
            e = np.clip(1 - dcore / FEATHER, 0, 1) * (d <= r)
        w = np.maximum(w, np.where(body, e, 0.0))
    return w


def _limbs(s):
    return [
        (f'pied{s}', [(f'cheville{s}', 'solid', 24)]),
        (f'jambe{s}', [(f'genou{s}', 'solid', 30), (f'cheville{s}', 'cap', 15)]),
        (f'cuisse{s}', [(f'hanche{s}', 'solid', 44), (f'genou{s}', 'cap', 21)]),
    ], [
        (f'main{s}', [(f'poignet{s}', 'solid', 20)]),
        (f'avant_bras{s}', [(f'coude{s}', 'solid', 26), (f'poignet{s}', 'cap', 13)]),
        (f'bras{s}', [(f'epaule{s}', 'edge', 44), (f'coude{s}', 'cap', 17)]),
    ]


_LG, _AG = _limbs('_g')
_LD, _AD = _limbs('_d')
# Ordre de dessin (du fond vers l'avant) : à chaque articulation, le segment
# proximal passe dessus (chapeau) et le distal dessous (disque plein).
SEGMENTS_FRONTAL = _LG + _LD + [
    ('tronc', [('cou', 'solid', 34), ('taille', 'solid', 70),
               ('epaule_g', 'solid', 40), ('epaule_d', 'solid', 40)]),
    ('bassin', [('taille', 'edge', 90), ('hanche_g', 'edge', 50),
                ('hanche_d', 'edge', 50)]),
    ('cou', [('nuque', 'solid', 22), ('cou', 'edge', 40)]),
    ('tete', [('nuque', 'edge', 30)]),
] + _AG + _AD
_L1, _A1 = _limbs('')
# profil : membre éloigné (réutilise les sprites du membre proche) dessiné
# d'abord par le moteur ; ici, une seule jambe et un seul bras.
SEGMENTS_PROFILE = _L1 + [
    ('tronc', [('cou', 'solid', 34), ('taille', 'solid', 60),
               ('epaule', 'solid', 44)]),
    ('bassin', [('taille', 'edge', 80), ('hanche', 'cap', 44)]),
    ('cou', [('nuque', 'solid', 22), ('cou', 'edge', 40)]),
    ('tete', [('nuque', 'edge', 30)]),
] + _A1


def build_view(assets, spec, view):
    lum, alpha = load_la(assets / spec['source'])
    layers = {}
    prefix = spec['source'].split('_')[0]
    for g, f in GROUP_FILES.items():
        p = assets / f'{prefix}_{f}.png'
        if p.exists():
            layers[g] = load_la(p)[1]
    J = spec['joints']
    if view == 'profil':
        parts, arm = partition_profile(lum, alpha, J, layers)
        lum_arm, alpha_arm = lum, alpha
        lum, alpha, zone, zone_groups = repaint_profile(lum, alpha, arm, J)
        parts.update(profile_body_parts(alpha, J, parts['tete'], parts['cou'],
                                        arm, zone))
        arm_mask = nd.binary_dilation(arm, iterations=2) & (alpha_arm > 0.02)
        body_mask = (alpha > 0.02) & ~(arm & ~zone)
        # calques du tronc et de la cuisse : rien de peint sous le bras
        body_layers = {g: np.where(zone, zone_groups.get(g, 0.0), la)
                       for g, la in layers.items()}
        seglist = SEGMENTS_PROFILE
    else:
        parts = partition_frontal(lum, alpha, J, back=(view == 'dos'))
        seglist = SEGMENTS_FRONTAL
        lum_arm, alpha_arm = lum, alpha
        body_layers = layers
        arm_mask = body_mask = alpha > 0.02
    W = alpha.shape[1]
    mirror = spec['mirror']

    def mx(p):
        return (W - 1 - p[0], p[1]) if mirror else tuple(p)

    if mirror:
        lum, alpha = lum[:, ::-1], alpha[:, ::-1]
        lum_arm, alpha_arm = lum_arm[:, ::-1], alpha_arm[:, ::-1]
        parts = {k: v[:, ::-1] for k, v in parts.items()}
        layers = {k: v[:, ::-1] for k, v in layers.items()}
        body_layers = {k: v[:, ::-1] for k, v in body_layers.items()}
        arm_mask, body_mask = arm_mask[:, ::-1], body_mask[:, ::-1]
    Jm = {k: mx(v) for k, v in J.items()}
    sprites = []
    arm_parts = ('bras', 'avant_bras', 'main')
    for name, jn in seglist:
        core = parts[name]
        is_arm = view == 'profil' and name in arm_parts
        src_l, src_a = (lum_arm, alpha_arm) if is_arm else (lum, alpha)
        body = arm_mask if is_arm else body_mask
        w = joint_weight(core, body, [(Jm[j], m, r) for j, m, r in jn])
        a = src_a * w
        ys, xs = np.nonzero(a > 0.004)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        spr = {'name': name, 'box': [int(x0), int(y0), int(x1), int(y1)],
               'lum': src_l[y0:y1, x0:x1], 'alpha': a[y0:y1, x0:x1], 'layers': {}}
        src_layers = layers if (view == 'profil' and name in arm_parts) else body_layers
        for g, la in src_layers.items():
            m = (la * w)[y0:y1, x0:x1]
            if (m > 0.05).sum() < 12:
                continue
            ly, lx = np.nonzero(m > 0.004)
            bx0, by0, bx1, by1 = lx.min(), ly.min(), lx.max() + 1, ly.max() + 1
            ll = 0.877 * src_l[y0:y1, x0:x1] + 89.5
            spr['layers'][g] = {'off': [int(bx0), int(by0)],
                                'lum': ll[by0:by1, bx0:bx1],
                                'alpha': m[by0:by1, bx0:bx1]}
        sprites.append(spr)
    return sprites, Jm, (lum, alpha, parts)


def pack(rects, width=512):
    """Rangement en étagères : renvoie les positions et la hauteur."""
    order = sorted(range(len(rects)), key=lambda i: -rects[i][1])
    pos = [None] * len(rects)
    x = y = shelf = 0
    for i in order:
        w, h = rects[i]
        if x + w + 2 > width:
            x, y, shelf = 0, y + shelf + 2, 0
        pos[i] = (x, y)
        x += w + 2
        shelf = max(shelf, h)
    return pos, y + shelf


def to_la(lum, alpha):
    l8 = np.clip(np.round(lum), 0, 255).astype(np.uint8)
    a8 = np.clip(np.round(alpha * 255), 0, 255).astype(np.uint8)
    l8[a8 == 0] = 0
    return Image.fromarray(np.dstack([l8, a8]), 'LA')


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument('--assets', type=Path, default=Path('assets/muscles'))
    ap.add_argument('--controle', type=Path)
    args = ap.parse_args()
    out = args.assets / 'anim'
    out.mkdir(parents=True, exist_ok=True)
    rig = {'version': 1, 'unite': 'px', 'echelle_px': 748.0, 'vues': {}}
    debug = {}
    for view, spec in (('face', FRONT), ('dos', BACK), ('profil', PROFILE)):
        sprites, J, dbg = build_view(args.assets, spec, view)
        debug[view] = (sprites, J, dbg)
        # atlas des segments
        pos, h = pack([(s['lum'].shape[1], s['lum'].shape[0]) for s in sprites])
        W = 512
        L = np.zeros((h, W)); A = np.zeros((h, W))
        lrects, lkeys = [], []
        for s in sprites:
            for g, l in s['layers'].items():
                lrects.append((l['lum'].shape[1], l['lum'].shape[0]))
                lkeys.append((s['name'], g))
        lpos, lh = pack(lrects)
        LL = np.zeros((lh, W)); LA = np.zeros((lh, W))
        segs = []
        li = 0
        for s, (x, y) in zip(sprites, pos):
            hh, ww = s['lum'].shape
            L[y:y + hh, x:x + ww] = s['lum']; A[y:y + hh, x:x + ww] = s['alpha']
            bx, by = s['box'][0], s['box'][1]
            seg = {'nom': s['name'], 'rect': [x, y, ww, hh],
                   'origine': [bx, by], 'calques': []}
            for g, l in s['layers'].items():
                lx, ly = lpos[lkeys.index((s['name'], g))]
                lhh, lww = l['lum'].shape
                LL[ly:ly + lhh, lx:lx + lww] = l['lum']
                LA[ly:ly + lhh, lx:lx + lww] = l['alpha']
                seg['calques'].append({'groupe': g, 'rect': [lx, ly, lww, lhh],
                                       'decalage': l['off']})
            segs.append(seg)
        to_la(L, A).save(out / f'{view}.png', optimize=True)
        to_la(LL, LA).save(out / f'{view}_calques.png', optimize=True)
        rig['vues'][view] = {
            'image': f'assets/muscles/anim/{view}.png',
            'calques': f'assets/muscles/anim/{view}_calques.png',
            'articulations': {k: [float(v[0]), float(v[1])] for k, v in J.items()},
            'segments': segs,
        }
        print(f'{view} : {len(segs)} segments, atlas {W}×{h}, calques {W}×{lh}')
    (out / 'rig.json').write_text(json.dumps(rig, ensure_ascii=False, indent=1))
    if args.controle:
        control(debug, args.controle)


PALETTE = [(230, 80, 80), (80, 160, 230), (230, 196, 106), (170, 110, 230),
           (110, 230, 170), (230, 140, 60), (90, 200, 90), (230, 60, 160),
           (60, 200, 230), (200, 200, 60), (160, 160, 160), (255, 120, 200),
           (120, 255, 120), (120, 120, 255), (255, 200, 120), (200, 255, 255),
           (255, 255, 120), (180, 80, 40), (40, 120, 180), (240, 240, 240)]


def control(debug, out):
    out.mkdir(parents=True, exist_ok=True)
    tiles = []
    for view, (sprites, J, (lum, alpha, parts)) in debug.items():
        H, W = alpha.shape
        img = np.zeros((H, W, 3)); img[:] = 18
        base = np.dstack([lum] * 3) * alpha[..., None] + img * (1 - alpha[..., None])
        col = np.zeros((H, W, 3)); cnt = np.zeros((H, W))
        for i, s in enumerate(sprites):
            m = parts[s['name']]
            col[m] = PALETTE[i % len(PALETTE)]; cnt[m] += 1
        over = (cnt > 1)
        mix = base * 0.45 + col * 0.55
        mix[cnt == 0] = base[cnt == 0]
        mix[over] = (255, 0, 255)
        t = Image.fromarray(mix.clip(0, 255).astype(np.uint8)).resize((W * 2, H * 2), Image.NEAREST)
        d = ImageDraw.Draw(t)
        for k, (x, y) in J.items():
            d.ellipse([x * 2 - 4, y * 2 - 4, x * 2 + 4, y * 2 + 4], outline=(255, 255, 0), width=2)
        tiles.append(t)
        # sprites seuls (alpha → blanc) pour vérifier les marges
        wtile = Image.new('RGB', (W * 2, H * 2), (18, 18, 18))
        for s in sprites:
            x0, y0, x1, y1 = s['box']
            spr = to_la(s['lum'], s['alpha']).convert('RGBA').resize(((x1 - x0) * 2, (y1 - y0) * 2))
            tmp = Image.new('RGBA', wtile.size, (0, 0, 0, 0))
            tmp.paste(spr, (x0 * 2, y0 * 2))
            wtile = Image.alpha_composite(wtile.convert('RGBA'), tmp).convert('RGB')
        tiles.append(wtile)
    Wt = sum(t.width for t in tiles) + 10 * len(tiles)
    sheet = Image.new('RGB', (Wt, max(t.height for t in tiles)), (0, 0, 0))
    x = 0
    for t in tiles:
        sheet.paste(t, (x, 0)); x += t.width + 10
    sheet.save(out / 'decoupe.png')


if __name__ == '__main__':
    main()
