#!/usr/bin/env python3
"""M6 (mannequin 3D) : bibliothèque de matériel 3D, à l'échelle réelle.

  python3 tools/anatomy/build_equipment.py [--check]

Sorties (relançable, déterministe) :
- `assets/anatomy/equipment.glb` : un nœud racine `eq_<id>` par élément
  (parties de teinte différente en nœuds enfants `eq_<id>__<partie>`),
  chacun dans son propre repère (origine décrite dans `equipment.json`) ;
- `assets/anatomy/equipment.json` : dimensions, origine, points de contact
  nommés (prise, appui, assise…) dans le repère de l'élément, triangles.

Repère : celui du mannequin (glTF : mètres, Y en haut, +Z vers l'avant du
corps, +X côté gauche). Style : gris neutres mats, sans texture (les teintes
définitives sont posées par l'application, `lib/mannequin_clip.dart`).

Dimensions (sources) :
- barre de traction Ø 28 mm à 2,30 m du sol ; barres parallèles Ø 45 mm,
  écart 55 cm entre axes, 1,40 m (demande du propriétaire, lot M6) ;
- barre olympique homme : 2,20 m, Ø 28 mm, manchons Ø 50 mm, disques Ø 450 mm
  (IWF Technical and Competition Rules, 2020, art. 2.2) ;
- anneaux : Ø intérieur 180 mm, section Ø 28 mm (FIG Apparatus Norms, 2022) ;
- banc : plateau 1,20 × 0,28 m à 0,43 m (hauteur usuelle de développé
  couché, IPF Technical Rules 2023 : 42-45 cm) ;
- haltère 20 kg (poignée Ø 28 mm), kettlebell 16 kg (Ø 210 mm, poignée
  Ø 35 mm : dimensions de compétition IKFF/IUKL), élastique en boucle de
  104 cm (longueur courante des bandes de résistance), box 76 × 61 × 51 cm ;
- ceinture et gilet de lest : ajustés au tronc du mannequin (coupes
  mesurées sur le modèle, plus 1,5 cm).
"""
import argparse
import json
import math
import struct
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT_GLB = ROOT / 'assets/anatomy/equipment.glb'
OUT_JSON = ROOT / 'assets/anatomy/equipment.json'

# Teintes (sRGB) : gris neutres, cohérents avec le mannequin (muscles
# #8F8B8A, os #4A4646, volumes sombres #2E2A2A).
TEINTES = {
    'metal': '#9A9794',      # barres, poignées
    'structure': '#5E5A58',  # montants, cadres
    'charge': '#3B3837',     # disques, kettlebell, haltères, lest
    'mousse': '#4A4644',     # sellerie, box
    'sangle': '#6E6A67',     # sangles, élastique, ceinture
    'sol': '#2A2726',        # sol (teinte ajustée au thème par l'application)
}
SEG = 20   # segments d'un cylindre


# ------------------------------------------------------------ primitives --

class Mesh:
    def __init__(self):
        self.p, self.n, self.i = [], [], []

    """Parties (positions, normales, indices locaux à la partie)."""

    def add(self, pos, nor, idx):
        self.p.append(np.asarray(pos, float))
        self.n.append(np.asarray(nor, float))
        self.i.append(np.asarray(idx, np.int64))
        return self

    def merge(self, other):
        self.p += other.p
        self.n += other.n
        self.i += other.i
        return self

    def arrays(self):
        bases = np.cumsum([0] + [len(p) for p in self.p[:-1]])
        return (np.concatenate(self.p).astype(np.float32),
                np.concatenate(self.n).astype(np.float32),
                np.concatenate([i + b for i, b in zip(self.i, bases)]).astype(np.uint32))

    @property
    def triangles(self):
        return sum(len(i) for i in self.i) // 3


def _frame(axis):
    a = np.asarray(axis, float)
    a = a / np.linalg.norm(a)
    t = np.array([0, 1, 0]) if abs(a[1]) < .9 else np.array([1, 0, 0])
    u = np.cross(a, t)
    u /= np.linalg.norm(u)
    v = np.cross(a, u)
    return a, u, v


def cylinder(p0, p1, r, seg=SEG, caps=True):
    """Cylindre plein de p0 à p1 (normales lisses sur le côté)."""
    p0, p1 = np.asarray(p0, float), np.asarray(p1, float)
    a, u, v = _frame(p1 - p0)
    ang = np.linspace(0, 2 * math.pi, seg, endpoint=False)
    ring = np.outer(np.cos(ang), u) + np.outer(np.sin(ang), v)
    pos = np.vstack([p0 + r * ring, p1 + r * ring])
    idx = []
    for k in range(seg):
        k2 = (k + 1) % seg
        idx += [k, seg + k, seg + k2, k, seg + k2, k2]
    m = Mesh().add(pos, np.vstack([ring, ring]), idx)
    if caps:
        for c, s in ((p0, -1), (p1, 1)):
            cp = np.vstack([c, c + r * ring])
            ci = []
            for k in range(seg):
                k2 = (k + 1) % seg
                ci += ([0, 1 + k2, 1 + k] if s < 0 else [0, 1 + k, 1 + k2])
            m.merge(Mesh().add(cp, np.tile(a * s, (seg + 1, 1)), ci))
    return m


def box(center, size):
    """Parallélépipède (normales plates)."""
    c, h = np.asarray(center, float), np.asarray(size, float) / 2
    m = Mesh()
    for axis in range(3):
        for s in (-1, 1):
            n = np.zeros(3)
            n[axis] = s
            u = np.zeros(3)
            u[(axis + 1) % 3] = h[(axis + 1) % 3]
            v = np.zeros(3)
            v[(axis + 2) % 3] = h[(axis + 2) % 3]
            f = c + n * h[axis]
            pts = [f - u - v, f + u - v, f + u + v, f - u + v]
            idx = [0, 1, 2, 0, 2, 3] if s > 0 else [0, 2, 1, 0, 3, 2]
            m.add(pts, np.tile(n, (4, 1)), idx)
    return m


def torus(center, axis, big, small, seg=32, seg2=12, arc=2 * math.pi, start=0.0):
    """Tore (ou arc de tore) autour de `axis`."""
    c = np.asarray(center, float)
    a, u, v = _frame(axis)
    pos, nor, idx = [], [], []
    closed = arc >= 2 * math.pi - 1e-9
    n1 = seg if closed else seg + 1
    for i in range(n1):
        t = start + arc * i / seg
        d = math.cos(t) * u + math.sin(t) * v
        for j in range(seg2):
            s = 2 * math.pi * j / seg2
            nn = math.cos(s) * d + math.sin(s) * a
            pos.append(c + big * d + small * nn)
            nor.append(nn)
    for i in range(seg if closed else seg):
        i2 = (i + 1) % n1
        for j in range(seg2):
            j2 = (j + 1) % seg2
            a0, a1 = i * seg2 + j, i * seg2 + j2
            b0, b1 = i2 * seg2 + j, i2 * seg2 + j2
            idx += [a0, b0, b1, a0, b1, a1]
    return Mesh().add(pos, nor, idx)


def sphere(center, r, seg=20, rings=12, squash=1.0):
    c = np.asarray(center, float)
    pos, nor, idx = [], [], []
    for i in range(rings + 1):
        th = math.pi * i / rings
        for j in range(seg):
            ph = 2 * math.pi * j / seg
            n = np.array([math.sin(th) * math.cos(ph), math.cos(th), math.sin(th) * math.sin(ph)])
            pos.append(c + r * n * np.array([1, squash, 1]))
            nor.append(n)
    for i in range(rings):
        for j in range(seg):
            j2 = (j + 1) % seg
            a0, a1 = i * seg + j, i * seg + j2
            b0, b1 = (i + 1) * seg + j, (i + 1) * seg + j2
            idx += [a0, a1, b1, a0, b1, b0]
    return Mesh().add(pos, nor, idx)


def elliptic_band(center_y, rx, rz, height, thickness, seg=40, z0=0.0):
    """Bande elliptique (ceinture, gilet) autour de l'axe vertical."""
    pos, nor, idx = [], [], []
    for side, r_off in ((1, thickness / 2), (-1, -thickness / 2)):
        for k in range(seg):
            t = 2 * math.pi * k / seg
            ex, ez = (rx + r_off) * math.cos(t), (rz + r_off) * math.sin(t) + z0
            n = np.array([math.cos(t) / rx, 0, math.sin(t) / rz])
            n = side * n / np.linalg.norm(n)
            for y in (center_y - height / 2, center_y + height / 2):
                pos.append([ex, y, ez])
                nor.append(n)
    half = seg * 2
    for s in range(2):
        o = s * half
        for k in range(seg):
            k2 = (k + 1) % seg
            a0, a1, b0, b1 = o + 2 * k, o + 2 * k + 1, o + 2 * k2, o + 2 * k2 + 1
            idx += ([a0, b0, b1, a0, b1, a1] if s == 0 else [a0, b1, b0, a0, a1, b1])
    return Mesh().add(pos, nor, idx)


# --------------------------------------------------------------- éléments --

def contact(nom, point, axe=None, rayon=None, type_='point', longueur=None):
    """Point de contact nommé ; type 'axe' : cylindre de rayon `rayon` et de
    longueur `longueur` centré sur `point` (prise, appui de la charge)."""
    out = {'nom': nom, 'type': type_, 'point': [round(float(c), 4) for c in point]}
    if axe is not None:
        out['axe'] = [round(float(c), 4) for c in axe]
    if rayon is not None:
        out['rayon'] = rayon
    if longueur is not None:
        out['longueur'] = longueur
    return out


def build_items():
    """{id: {'nom', 'origine', 'parties': {partie: (Mesh, teinte)}, 'contacts'}}."""
    items = {}

    # Barre de traction : barre Ø 28 mm, 1,20 m, à 2,30 m (axe), deux
    # montants Ø 48 mm. Origine : au sol, sous le milieu de la barre.
    # Montants 35 cm en arrière de la barre (potence) : dans la vue de profil,
    # ils ne passent pas devant le corps suspendu.
    h, r, back = 2.30, .014, -.35
    frame = Mesh()
    for x in (-.63, .63):
        frame.merge(cylinder((x, 0, back), (x, h + .03, back), .024))
        frame.merge(cylinder((x, h, back), (x, h, .02), .018))
    items['barre_traction'] = {
        'nom': 'Barre de traction', 'origine': 'au sol, sous le milieu de la barre',
        'dimensions': {'diametre': .028, 'hauteur_axe': h, 'longueur': 1.2},
        'parties': {
            '': (cylinder((-.65, h, 0), (.65, h, 0), r), 'metal'),
            'montants': (frame, 'structure'),
        },
        'contacts': [contact('prise', (0, h, 0), (1, 0, 0), r, 'axe', 1.2)],
    }

    # Barres parallèles : Ø 45 mm, écart 55 cm entre axes, 1,40 m (axe),
    # longueur 1,00 m, montants Ø 50 mm. Barres orientées d'avant en arrière.
    h, r, e = 1.40, .0225, .275
    rails = Mesh()
    posts = Mesh()
    for x in (-e, e):
        rails.merge(cylinder((x, h, -.5), (x, h, .5), r))
        for z in (-.42, .42):
            posts.merge(cylinder((x, 0, z), (x, h - r, z), .025))
    items['barres_paralleles'] = {
        'nom': 'Barres parallèles', 'origine': 'au sol, entre les deux barres',
        'dimensions': {'diametre': .045, 'hauteur_axe': h, 'ecart_axes': .55, 'longueur': 1.0},
        'parties': {'': (rails, 'metal'), 'montants': (posts, 'structure')},
        'contacts': [contact('prise_g', (e, h, 0), (0, 0, 1), r, 'axe', 1.0),
                     contact('prise_d', (-e, h, 0), (0, 0, 1), r, 'axe', 1.0)],
    }

    # Anneaux : Ø intérieur 180 mm, section Ø 28 mm, sangles de 60 cm,
    # anneaux écartés de 50 cm. Origine : entre les centres des anneaux.
    big, small = .09 + .014, .014
    rings, straps = Mesh(), Mesh()
    for x in (-.25, .25):
        rings.merge(torus((x, 0, 0), (0, 0, 1), big, small))
        straps.merge(box((x, big + .31, 0), (.004, .6, .035)))
    items['anneaux'] = {
        'nom': 'Anneaux', 'origine': 'entre les centres des deux anneaux',
        'dimensions': {'diametre_interieur': .18, 'section': .028, 'ecart': .5},
        'parties': {'': (rings, 'structure'), 'sangles': (straps, 'sangle')},
        'contacts': [contact('prise_g', (.25, -big, 0), (0, 0, 1), small, 'axe'),
                     contact('prise_d', (-.25, -big, 0), (0, 0, 1), small, 'axe')],
    }

    # Banc plat : plateau 1,20 × 0,28 × 0,06 à 0,43 m (dessus), pieds.
    top = .43
    frame = Mesh()
    for z in (-.5, .5):
        frame.merge(box((0, (top - .06) / 2, z), (.05, top - .06, .05)))
        frame.merge(box((0, .02, z), (.42, .04, .06)))
    items['banc_plat'] = {
        'nom': 'Banc plat', 'origine': 'au sol, sous le centre du plateau',
        'dimensions': {'longueur': 1.2, 'largeur': .28, 'hauteur': top},
        'parties': {'': (box((0, top - .03, 0), (.28, .06, 1.2)), 'mousse'),
                    'cadre': (frame, 'structure')},
        'contacts': [contact('assise', (0, top, 0), None, None, 'plan'),
                     contact('appui_dos', (0, top, -.3), None, None, 'plan')],
    }

    # Banc inclinable : assise 0,40 m à 0,45 m, dossier 0,85 m incliné à 45°.
    top, back_angle = .45, math.radians(45)
    seat = box((0, top - .03, .2), (.28, .06, .4))
    L = .85
    back_c = np.array([0, top - .03 + math.sin(back_angle) * L / 2, -math.cos(back_angle) * L / 2])
    back = box((0, 0, 0), (.28, .06, L))
    # Rotation autour de X : le dossier monte vers l'arrière (−Z).
    rot = np.array([[1, 0, 0], [0, math.cos(-back_angle), -math.sin(-back_angle)],
                    [0, math.sin(-back_angle), math.cos(-back_angle)]])
    back.p = [(rot @ p.T).T + back_c for p in back.p]
    back.n = [(rot @ n.T).T for n in back.n]
    frame = Mesh()
    for z in (-.45, .35):
        frame.merge(box((0, .02, z), (.42, .04, .06)))
    frame.merge(box((0, (top - .06) / 2, 0), (.05, top - .06, .05)))
    frame.merge(box((0, .05, -.05), (.05, .05, .8)))
    items['banc_inclinable'] = {
        'nom': 'Banc inclinable (45°)', 'origine': 'au sol, sous la charnière assise-dossier',
        'dimensions': {'hauteur_assise': top, 'longueur_dossier': L, 'inclinaison': 45},
        'parties': {'': (seat.merge(back), 'mousse'), 'cadre': (frame, 'structure')},
        'contacts': [contact('assise', (0, top, .2), None, None, 'plan'),
                     contact('appui_dos', [float(c) for c in back_c + rot @ np.array([0, .03, 0])],
                             None, None, 'plan')],
    }

    # Barre olympique : 2,20 m, Ø 28 mm, manchons Ø 50 mm (0,415 m) ; un
    # disque de 20 kg (Ø 450 mm, 55 mm) de chaque côté (partie « disques »).
    bar = cylinder((-.655, 0, 0), (.655, 0, 0), .014)
    for s in (-1, 1):
        bar.merge(cylinder((s * .655, 0, 0), (s * .685, 0, 0), .025))   # collerette
        bar.merge(cylinder((s * .685, 0, 0), (s * 1.10, 0, 0), .025))
    plates = Mesh()
    for s in (-1, 1):
        plates.merge(cylinder((s * .69, 0, 0), (s * .745, 0, 0), .225, seg=32))
    items['barre_olympique'] = {
        'nom': 'Barre olympique chargée', 'origine': 'centre de la barre',
        'dimensions': {'longueur': 2.2, 'diametre': .028, 'diametre_disques': .45},
        'parties': {'': (bar, 'metal'), 'disques': (plates, 'charge')},
        'contacts': [contact('prise', (0, 0, 0), (1, 0, 0), .014, 'axe', 1.31),
                     contact('appui_dos', (0, 0, 0), (1, 0, 0), .014, 'axe', 1.31)],
    }

    # Haltère 20 kg : poignée Ø 28 mm (0,14 m), têtes Ø 0,12 m.
    items['haltere'] = {
        'nom': 'Haltère', 'origine': 'centre de la poignée',
        'dimensions': {'longueur': .35, 'diametre_poignee': .028, 'diametre_tetes': .12},
        'parties': {'': (cylinder((-.07, 0, 0), (.07, 0, 0), .014), 'metal'),
                    'tetes': (cylinder((-.175, 0, 0), (-.07, 0, 0), .06, seg=6)
                              .merge(cylinder((.07, 0, 0), (.175, 0, 0), .06, seg=6)), 'charge')},
        'contacts': [contact('prise', (0, 0, 0), (1, 0, 0), .014, 'axe')],
    }

    # Kettlebell 16 kg : corps Ø 0,21 m, poignée Ø 35 mm, hauteur 0,28 m.
    body = sphere((0, .105, 0), .105, squash=.95)
    handle = torus((0, .205, 0), (0, 0, 1), .075, .0175, seg=16, arc=math.pi, start=math.pi)
    items['kettlebell'] = {
        'nom': 'Kettlebell 16 kg', 'origine': 'au sol, sous le centre',
        'dimensions': {'diametre': .21, 'hauteur': .2975, 'diametre_poignee': .035},
        'parties': {'': (body.merge(handle), 'charge')},
        'contacts': [contact('prise', (0, .28, 0), (1, 0, 0), .0175, 'axe')],
    }

    # Élastique en boucle : 104 cm de long, 2 cm de large (bande plate).
    items['elastique'] = {
        'nom': 'Élastique en boucle', 'origine': 'point d’ancrage haut',
        'dimensions': {'longueur': 1.04, 'largeur': .02},
        'parties': {'': (_band_loop(1.04, .02, .005), 'sangle')},
        'contacts': [contact('ancrage', (0, 0, 0)), contact('appui', (0, -1.04, 0))],
    }

    # Box de pliométrie : 76 × 61 × 51 cm.
    items['box'] = {
        'nom': 'Box', 'origine': 'au sol, sous le centre',
        'dimensions': {'longueur': .76, 'largeur': .61, 'hauteur': .51},
        'parties': {'': (box((0, .255, 0), (.61, .51, .76)), 'mousse')},
        'contacts': [contact('appui', (0, .51, 0), None, None, 'plan')],
    }

    # Sol : disque de 0,9 m de rayon, 1 cm d'épaisseur, dessus à y = 0.
    items['sol'] = {
        'nom': 'Sol', 'origine': 'dessus du sol, au centre',
        'dimensions': {'rayon': .9, 'epaisseur': .01},
        'parties': {'': (cylinder((0, -.01, 0), (0, 0, 0), .9, seg=48), 'sol')},
        'contacts': [contact('appui', (0, 0, 0), None, None, 'plan')],
    }

    # Ceinture de lest : bande ajustée à la taille (coupe du modèle à 0,97 m :
    # 0,28 × 0,19 m) + 1,5 cm, chaîne pendante et disque de 10 kg (Ø 0,33 m).
    rx, rz = .139 + .015, .093 + .015
    belt = elliptic_band(0, rx, rz, .07, .012, z0=.004)
    chain = Mesh()
    for k in range(9):
        y = -.02 - k * .03
        chain.merge(torus((0, y, rz + .01), (1, 0, 0) if k % 2 else (0, 0, 1), .012, .004,
                          seg=10, seg2=6))
    plate = cylinder((0, -.45, rz - .01), (0, -.45, rz + .035), .165, seg=32)
    items['ceinture_lest'] = {
        'nom': 'Ceinture de lest', 'origine': 'centre de la taille (hauteur de la ceinture)',
        'dimensions': {'tour_x': 2 * rx, 'tour_z': 2 * rz, 'diametre_disque': .33},
        'parties': {'': (belt.merge(chain), 'sangle'), 'disque': (plate, 'charge')},
        'contacts': [contact('taille', (0, 0, 0), None, None, 'appui')],
    }

    # Gilet de lest : buste (coupe du modèle à 1,25 m : 0,34 × 0,25 m) +
    # 1,5 cm, hauteur 0,40 m, épaisseur 3 cm.
    rx, rz = .17 + .015, .123 + .015
    items['gilet_lest'] = {
        'nom': 'Gilet de lest', 'origine': 'centre du buste (milieu du gilet)',
        'dimensions': {'tour_x': 2 * rx, 'tour_z': 2 * rz, 'hauteur': .4},
        'parties': {'': (elliptic_band(0, rx, rz, .4, .03, z0=-.004), 'charge')},
        'contacts': [contact('buste', (0, 0, 0), None, None, 'appui')],
    }
    return items


def _band_loop(length, width, thick):
    """Boucle plate verticale : deux brins parallèles reliés en haut et en bas."""
    half = length / 2
    m = Mesh()
    for x in (-.02, .02):
        m.merge(box((x, -half, 0), (thick, length - .04, width)))
    m.merge(torus((0, -.02, 0), (0, 0, 1), .02, thick / 2, seg=8, seg2=6, arc=math.pi))
    m.merge(torus((0, -length + .02, 0), (0, 0, 1), .02, thick / 2, seg=8, seg2=6,
                  arc=math.pi, start=math.pi))
    return m


# ------------------------------------------------------------------ export --

def srgb_lin(hex_color):
    c = int(hex_color.lstrip('#'), 16)
    out = []
    for s in ((c >> 16) & 255, (c >> 8) & 255, c & 255):
        v = s / 255
        out.append(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4)
    return out


def write_glb(path, items):
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

    teintes = list(TEINTES)
    materials = [{'name': t, 'pbrMetallicRoughness': {
        'baseColorFactor': srgb_lin(TEINTES[t]) + [1.0], 'metallicFactor': 0.0,
        'roughnessFactor': .8}} for t in teintes]
    nodes, meshes, roots = [], [], []
    for item_id, item in items.items():
        root_index = None
        children = []
        for part, (mesh, teinte) in item['parties'].items():
            pos, nor, idx = mesh.arrays()
            a_pos = add(pos, 34962, componentType=5126, count=len(pos), type='VEC3',
                        min=[float(v) for v in pos.min(0)], max=[float(v) for v in pos.max(0)])
            a_nor = add(nor / np.linalg.norm(nor, axis=1, keepdims=True), 34962,
                        componentType=5126, count=len(nor), type='VEC3')
            small = idx.max() < 65536
            a_idx = add(idx.astype(np.uint16 if small else np.uint32), 34963,
                        componentType=5123 if small else 5125, count=len(idx), type='SCALAR')
            name = f'eq_{item_id}' + (f'__{part}' if part else '')
            meshes.append({'name': name, 'primitives': [{
                'attributes': {'POSITION': a_pos, 'NORMAL': a_nor}, 'indices': a_idx,
                'material': teintes.index(teinte)}]})
            nodes.append({'name': name, 'mesh': len(meshes) - 1})
            if part:
                children.append(len(nodes) - 1)
            else:
                root_index = len(nodes) - 1
        nodes[root_index]['children'] = children
        roots.append(root_index)
    gltf = {
        'asset': {'version': '2.0', 'generator': 'Kalis Track tools/anatomy/build_equipment.py (M6)'},
        'scene': 0, 'scenes': [{'name': 'Materiel', 'nodes': roots}],
        'nodes': nodes, 'meshes': meshes, 'materials': materials,
        'accessors': accessors, 'bufferViews': views, 'buffers': [{'byteLength': offset}],
    }
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    blob = b''.join(chunks)
    total = 12 + 8 + len(js) + 8 + len(blob)
    data = struct.pack('<4sII', b'glTF', 2, total) + struct.pack('<I4s', len(js), b'JSON') + js
    data += struct.pack('<I4s', len(blob), b'BIN\0') + blob
    return data


def describe(items, glb_size):
    out = {'schema': 1, 'repere': "glTF : mètres, Y vers le haut, +Z vers l'avant, +X côté gauche",
           'teintes': TEINTES, 'elements': {}}
    total = 0
    for item_id, item in items.items():
        tris = sum(m.triangles for m, _ in item['parties'].values())
        total += tris
        pts = np.concatenate([m.arrays()[0] for m, _ in item['parties'].values()])
        out['elements'][item_id] = {
            'nom': item['nom'], 'noeud': f'eq_{item_id}', 'origine': item['origine'],
            'parties': {p or 'principale': t for p, (_, t) in item['parties'].items()},
            'dimensions': item['dimensions'], 'contacts': item['contacts'],
            'boite': [[round(float(v), 4) for v in pts.min(0)],
                      [round(float(v), 4) for v in pts.max(0)]],
            'triangles': tris,
        }
    out['triangles'] = total
    out['octets_glb'] = glb_size
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true',
                        help='vérifie que les fichiers suivis sont à jour')
    args = parser.parse_args()
    items = build_items()
    glb = write_glb(OUT_GLB, items)
    desc = json.dumps(describe(items, len(glb)), ensure_ascii=False, indent=1) + '\n'
    if args.check:
        ok = OUT_GLB.read_bytes() == glb and OUT_JSON.read_text(encoding='utf-8') == desc
        print('matériel à jour' if ok else 'matériel à régénérer')
        sys.exit(0 if ok else 1)
    OUT_GLB.write_bytes(glb)
    OUT_JSON.write_text(desc, encoding='utf-8')
    d = json.loads(desc)
    print(f"{len(d['elements'])} éléments, {d['triangles']} triangles, {len(glb)} octets")


if __name__ == '__main__':
    main()
