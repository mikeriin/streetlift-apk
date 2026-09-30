#!/usr/bin/env python3
"""M8 : carte 2D des groupes musculaires, d'après l'image du propriétaire,
réadaptée pour l'application.

5.9.1 (M8 correction 1, 30/09/2026) : nouvelle image, plus détaillée
(`tools/muscles2d/source_carte.png` : vues de face, de dos et de profil,
sans légende ; chaque muscle est une zone colorée cernée d'un trait noir).
Sortie : pour chaque vue, un masque alpha par calque
(`assets/muscles2d/<vue>/<calque>.png`) que l'application teinte à
l'affichage (gris si le groupe n'est pas travaillé, couleur dominante par
rôle sinon) :
  - 15 groupes : trapezes, deltoides, pectoraux, dorsaux, biceps, triceps,
    avant_bras, abdominaux, obliques, fessiers, quadriceps, ischios,
    adducteurs, mollets, tibial ;
  - `neutre` (muscles sans groupe de la carte : bas du dos) : gris des
    muscles, jamais en couleur ;
  - `peau` (tendons, rotules, bandes blanches : gris clair) ;
  - `sombre` (tête, mains, pieds : gris sombre) ;
  - `contour` (traits noirs de l'image : cernes et séparations) ;
  - `ombre` (modelé de l'image : fibres, volumes), posé en noir
    translucide par-dessus les muscles.
Le fond blanc devient transparent : le support (page ou carte) apparaît
autour de la figure (règle des fonds du 30/09/2026).

Méthode : les pixels colorés sont regroupés par couleur (k-moyennes), puis
en zones connexes (un muscle = une zone : les traits noirs les séparent) ;
chaque zone reçoit un groupe par des règles de position et de couleur
propres à chaque vue (l'image n'a pas de légende : une même couleur sert à
plusieurs groupes). Rendu de contrôle : `--apercu`.

  python3 tools/muscles2d/build_map.py [--apercu apercu.png]
"""
import argparse
import colorsys
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SRC = HERE / 'source_carte.png'
OUT = ROOT / 'assets/muscles2d'

GROUPS = ['trapezes', 'deltoides', 'pectoraux', 'dorsaux', 'biceps', 'triceps', 'avant_bras',
          'abdominaux', 'obliques', 'fessiers', 'quadriceps', 'ischios', 'adducteurs',
          'mollets', 'tibial']
LAYERS = GROUPS + ['neutre', 'peau', 'sombre', 'contour', 'ombre']

# vues : (nom, x0, x1, axe du corps en x) ; image 1536 × 1024
VIEWS = [('face', 0, 540, 288), ('dos', 540, 1040, 790), ('profil', 1040, 1536, None)]

# couleurs d'aperçu (contrôle seulement)
PREVIEW = {
    'trapezes': (60, 110, 230), 'deltoides': (250, 140, 30), 'pectoraux': (220, 50, 50),
    'dorsaux': (150, 20, 60), 'biceps': (250, 220, 40), 'triceps': (150, 90, 220),
    'avant_bras': (40, 190, 230), 'abdominaux': (60, 180, 70), 'obliques': (250, 170, 150),
    'fessiers': (240, 100, 20), 'quadriceps': (30, 120, 250), 'ischios': (110, 90, 200),
    'adducteurs': (230, 60, 200), 'mollets': (130, 200, 40), 'tibial': (20, 150, 110),
    'neutre': (150, 150, 150), 'peau': (225, 225, 225), 'sombre': (70, 70, 70),
    'contour': (15, 15, 15),
}


def kind(rgb):
    """Famille de couleur d'une zone (l'image réutilise les mêmes teintes)."""
    h, light, _ = colorsys.rgb_to_hls(*[v / 255 for v in rgb])
    h *= 360
    if h < 12 or h >= 340:
        return 'rouge'
    if h < 40:
        return 'orange' if light < .72 else 'peche'
    if h < 62:
        return 'jaune' if light < .72 else 'jaune_clair'
    if h < 90:
        return 'vert_clair' if light > .62 else 'vert_jaune'
    if h < 160:
        return 'vert'
    if h < 200:
        return 'cyan'
    if h < 235:
        return 'bleu'
    if h < 255:
        return 'lavande' if light > .62 else 'bleu_violet'
    if h < 300:
        return 'lavande' if light > .72 else 'violet'
    return 'rose'


VIOLETS = ('violet', 'lavande', 'bleu_violet')
VERTS = ('vert', 'vert_jaune', 'vert_clair')
ORANGES = ('orange', 'peche')


# --------------------------------------------------------------- règles --

def face(x, y, k, axis):
    dx = abs(x - axis)
    if y < 275 and dx >= 80 and k in ORANGES:
        return 'deltoides'
    if y < 190 and k != 'rouge':
        return 'trapezes'
    if k == 'rouge' and y < 300:
        return 'pectoraux'
    if dx > 118 and y < 480:  # bras
        if y < 335:
            if k in VIOLETS or k == 'rose':
                return 'triceps'
            if k in ('bleu', 'cyan'):
                return 'avant_bras'
            return 'biceps'
        return 'avant_bras'
    if y < 480:  # tronc
        if k in VERTS and dx < 55:
            return 'abdominaux'
        if k in VERTS and y > 395:
            return 'fessiers'  # tenseur du fascia lata
        if k in VIOLETS and y < 330:
            return 'dorsaux'
        if y < 362:
            return 'pectoraux'  # dentelé antérieur
        if y < 445 and k not in VIOLETS + ('bleu', 'rose'):
            return 'obliques'
    if y < 700:  # cuisse
        if k in ('violet', 'bleu_violet', 'rose'):
            return 'adducteurs'
        return 'quadriceps'  # vastes, droit fémoral, couturier (lavande)
    # jambe : tibial antérieur (juste en dehors du tibia, quelle que soit
    # sa couleur : l'image ne colore pas les deux jambes pareil) et
    # extenseurs (bleus) ; fibulaires plus en dehors, mollets en dedans
    if k in ('bleu', 'cyan') or 72 <= dx <= 100:
        return 'tibial'
    return 'mollets'


def dos(x, y, k, axis):
    dx = abs(x - axis)
    if y < 140:
        return 'trapezes'
    if y < 275 and dx >= 85 and k in ORANGES + ('jaune',):
        return 'deltoides'
    if dx > 135 and y < 490:  # bras
        return 'triceps' if y < 350 else 'avant_bras'
    if k != 'rouge' and 245 < y < 360 and dx > 95:
        return 'triceps'  # chefs latéral et médial, côté tronc
    if k in VIOLETS and y < 270:
        return 'deltoides'  # sous-épineux, petit rond
    if k in ('bleu', 'cyan', 'bleu_violet') and y < 340:
        return 'trapezes' if dx < 62 or y < 215 else 'dorsaux'
    if k == 'rouge' and y < 440:
        return 'dorsaux'
    if k == 'rose' and y < 440:
        return 'neutre'  # fascia thoraco-lombaire, érecteurs : sans groupe
    if k in ORANGES and y < 415:
        return 'obliques'
    if y < 535:
        return 'fessiers'
    if y < 700:
        if k in ('bleu', 'cyan') and dx > 60:
            return 'quadriceps'  # vaste latéral
        return 'ischios'
    return 'mollets'


def profil(x, y, k, axis):
    if y < 200 and (x < 1255 or y < 170) and k not in ORANGES + ('jaune',):
        return 'trapezes'
    if 160 < y < 290 and 1195 < x < 1300 and k in ORANGES + ('jaune',):
        return 'deltoides'
    if k == 'rouge' and y < 300 and x > 1285:
        return 'pectoraux'
    if k in VERTS and x > 1318 and y < 500:
        return 'abdominaux'
    if 250 < y < 440 and 1288 < x < 1335 and k not in ('jaune', 'bleu', 'cyan', 'violet'):
        return 'pectoraux' if y < 345 and k not in ORANGES else 'obliques'
    if y < 370 and k in VIOLETS + ('bleu',) and x < 1265:
        return 'dorsaux' if x < 1212 and y < 300 else 'triceps'
    if y < 355 and k in ('jaune',) + VERTS:
        return 'biceps'
    if 340 <= y < 490 and x > 1232:
        return 'avant_bras'
    if y < 540 and k in ORANGES:
        return 'fessiers'
    if y < 705:
        return 'ischios' if k in VIOLETS else 'quadriceps'
    if x > 1262 and k not in ('rouge',) + ORANGES:
        return 'tibial'  # tibial antérieur, extenseurs (devant)
    return 'mollets'


RULES = {'face': face, 'dos': dos, 'profil': profil}


# -------------------------------------------------------- segmentation --

def segment(rgb):
    """Classes des pixels : fond, contour, sombre, peau, zones colorées."""
    from scipy import ndimage
    from scipy.cluster.vq import kmeans2
    f = rgb.astype(float)
    mx, mn = f.max(-1), f.min(-1)
    sat = mx - mn
    lum = f.mean(-1)
    # fond : clair et relié au bord de l'image (halo gris clair compris)
    light = (lum > 212) & (sat < 30)
    lab, _ = ndimage.label(light)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    background = np.isin(lab, list(border))
    colored = (sat > 42) & (mx > 95) & ~background
    contour = (mx < 62) & ~background & ~colored
    sombre = (sat < 36) & (mx >= 62) & (mx < 150) & ~background & ~colored
    peau = ~background & ~colored & ~contour & ~sombre
    # zones colorées : k-moyennes puis composantes connexes par classe
    _, lbl = kmeans2(f[colored], 24, minit='++', seed=1)
    cls = np.full(colored.shape, -1)
    cls[colored] = lbl
    zones = np.zeros(colored.shape, int)
    n = 0
    for c in range(24):
        cl, k = ndimage.label(cls == c)
        zones[cl > 0] = cl[cl > 0] + n
        n += k
    # petites zones (liserés) rattachées à leur voisine la plus présente
    sizes = ndimage.sum(zones > 0, zones, range(1, n + 1))
    objs = ndimage.find_objects(zones)
    for i, s in enumerate(sizes, 1):
        if s >= 150 or objs[i - 1] is None:
            continue
        sl = tuple(slice(max(0, a.start - 3), a.stop + 3) for a in objs[i - 1])
        sub = zones[sl]
        r = sub == i
        ring = ndimage.binary_dilation(r, iterations=2) & ~r & (sub > 0)
        if ring.any():
            v, cnt = np.unique(sub[ring], return_counts=True)
            sub[r] = v[cnt.argmax()]
    return background, colored, contour, sombre, peau, zones


def classify():
    """Calque de chaque pixel de l'image source et modelé (0-1)."""
    from scipy import ndimage
    src = np.array(Image.open(SRC).convert('RGB'))
    background, colored, contour, sombre, peau, zones = segment(src)
    lum = src.astype(float).mean(-1)
    ids = [i for i in np.unique(zones) if i]
    centers = ndimage.center_of_mass(zones > 0, zones, ids)
    means = [ndimage.mean(src[..., j].astype(float), zones, ids) for j in range(3)]
    lut = np.full(zones.max() + 1, '', dtype=object)
    for n, i in enumerate(ids):
        cy, cx = centers[n]
        rgb = tuple(int(means[j][n]) for j in range(3))
        for view, x0, x1, axis in VIEWS:
            if x0 <= cx < x1:
                lut[i] = RULES[view](cx, cy, kind(rgb), axis)
    labels = np.full(src.shape[:2], '', dtype=object)
    labels[colored] = lut[zones[colored]]
    labels[contour] = 'contour'
    labels[sombre] = 'sombre'
    labels[peau] = 'peau'
    # pixels restés sans calque (traits anticrénelés, liserés) : calque du
    # pixel voisin le plus proche (pas de trou vers le support)
    todo = (labels == '') & ~background
    if todo.any():
        _, (iy, ix) = ndimage.distance_transform_edt(
            (labels == '') | background, return_indices=True)
        labels[todo] = labels[iy[todo], ix[todo]]
    # ombre : écart de luminance à la moyenne de la zone (fibres, volumes)
    zone_lum = np.zeros(zones.max() + 1)
    zone_lum[ids] = ndimage.mean(lum, zones, ids)
    shade = np.zeros(lum.shape)
    shade[colored] = np.clip((zone_lum[zones[colored]] - lum[colored]) / 70, 0, 1)
    return labels, shade


def build(apercu=None):
    labels, shade = classify()
    report = {'vues': {}}
    previews = []
    for view, x0, x1, _ in VIEWS:
        lab = labels[:, x0:x1]
        ys, xs = np.where(lab != '')
        pad = 4
        top, bot = max(0, ys.min() - pad), min(lab.shape[0], ys.max() + pad + 1)
        left, right = max(0, xs.min() - pad), min(lab.shape[1], xs.max() + pad + 1)
        lab = lab[top:bot, left:right]
        sh = shade[top:bot, x0 + left:x0 + right]
        H, W = lab.shape
        d = OUT / view
        d.mkdir(parents=True, exist_ok=True)
        for old in d.glob('*.png'):
            old.unlink()
        present = []
        for name in LAYERS:
            if name == 'ombre':
                img = Image.fromarray((sh * 255).astype(np.uint8), 'L')
            else:
                m = (lab == name).astype(np.uint8) * 255
                if not m.any():
                    continue
                # léger débord (0,6 px) : pas de liseré de fond entre calques
                img = Image.fromarray(m, 'L').filter(ImageFilter.GaussianBlur(.6))
            rgba = Image.new('LA', (W, H), 255)
            rgba.putalpha(img)
            rgba.save(d / f'{name}.png', optimize=True)
            present.append(name)
        # étiquettes (toucher) : 1 + rang du calque, groupes et neutre
        idx = np.zeros(lab.shape, dtype=np.uint8)
        for k, name in enumerate(LAYERS, 1):
            if name in GROUPS or name == 'neutre':
                idx[lab == name] = k
        Image.fromarray(idx, 'L').save(d / 'etiquettes.png', optimize=True)
        report['vues'][view] = {'largeur': W, 'hauteur': H, 'calques': present}
        if apercu:
            prev = np.full((H, W, 3), 255, dtype=np.uint8)
            for name, c in PREVIEW.items():
                prev[lab == name] = c
            prev = (prev * (1 - .55 * sh[..., None])).astype(np.uint8)
            previews.append(Image.fromarray(prev))
    (OUT / 'carte.json').write_text(json.dumps(
        {**report, 'groupes': GROUPS, 'calques': LAYERS,
         'source': 'tools/muscles2d/source_carte.png (image détaillée du propriétaire, '
                   '30/09/2026)'},
        ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    if apercu:
        w = sum(p.width for p in previews) + 20 * len(previews)
        h = max(p.height for p in previews)
        board = Image.new('RGB', (w, h), (255, 255, 255))
        x = 0
        for p in previews:
            board.paste(p, (x, 0))
            x += p.width + 20
        board.save(apercu)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--apercu')
    args = parser.parse_args()
    print(json.dumps(build(args.apercu), ensure_ascii=False))


if __name__ == '__main__':
    main()
