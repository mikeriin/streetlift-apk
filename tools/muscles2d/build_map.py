#!/usr/bin/env python3
"""M8 : carte 2D des groupes musculaires (image fournie par le propriétaire,
30/09/2026), réadaptée pour l'application.

Source : `tools/muscles2d/source_carte.png` (vues de face, de dos et de
profil ; 15 groupes colorés, légende). Sortie : pour chaque vue, un masque
alpha par calque (`assets/muscles2d/<vue>/<calque>.png`) que l'application
teinte à l'affichage (gris si le groupe n'est pas travaillé, couleur
dominante par rôle sinon) :
  - 15 groupes : trapezes, deltoides, pectoraux, dorsaux, biceps, triceps,
    avant_bras, abdominaux, obliques, fessiers, quadriceps, ischios,
    adducteurs, mollets, tibial ;
  - `peau` (articulations, tendons, bas du dos : gris clair) ;
  - `sombre` (tête, mains, pieds, creux : gris sombre).
Les traits blancs entre les muscles et le fond blanc deviennent
transparents : le support (page ou carte) apparaît entre les muscles, dans
les deux thèmes (règle des fonds du 30/09/2026). Légende et titres retirés
(la légende est dessinée par l'application).

Classement de chaque pixel par la couleur la plus proche de la légende de
la source, puis règles de position pour les couleurs voisines (trapèzes /
quadriceps / ischios, biceps / triceps, fessiers / adducteurs, mollets /
tibial) ; composantes minuscules rattachées à leur voisinage.

  python3 tools/muscles2d/build_map.py [--apercu apercu.png]
"""
import argparse
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
LAYERS = GROUPS + ['peau', 'sombre']

# couleurs de la légende de la source (pastilles), plus fond et gris
PALETTE = {
    'trapezes': (127, 56, 179), 'deltoides': (22, 136, 229), 'pectoraux': (225, 54, 58),
    'dorsaux': (21, 100, 184), 'biceps': (252, 145, 35), 'triceps': (249, 168, 29),
    'avant_bras': (248, 210, 32), 'abdominaux': (56, 154, 66), 'obliques': (158, 221, 78),
    'fessiers': (238, 70, 132), 'quadriceps': (148, 86, 201), 'adducteurs': (245, 108, 137),
    'mollets': (13, 191, 209), 'tibial': (60, 198, 212),
    'deltoides_clair': (70, 165, 245),
    'blanc': (255, 255, 255), 'peau': (205, 205, 203), 'sombre': (82, 82, 84),
    'sombre2': (60, 60, 62),
}

# vues : (nom, x0, x1) ; figures entre y0 et y1 (légende et titres exclus)
VIEWS = [('face', 20, 505), ('dos', 505, 935), ('profil', 935, 1175)]
Y0, Y1 = 15, 990


def classify(rgb):
    names = list(PALETTE)
    pal = np.array([PALETTE[n] for n in names], dtype=np.float32)
    d = ((rgb[:, :, None, :].astype(np.float32) - pal[None, None]) ** 2).sum(-1)
    idx = d.argmin(-1)
    lab = np.array(names, dtype=object)[idx]
    lab[lab == 'deltoides_clair'] = 'deltoides'
    lab[lab == 'sombre2'] = 'sombre'
    return lab


def refine(lab, view, x0):
    """Règles de position pour les couleurs voisines."""
    h, w = lab.shape
    ys, xs = np.mgrid[0:h, 0:w]
    purple = np.isin(lab, ['trapezes', 'quadriceps'])
    hip = 390 - Y0          # sous les trapèzes, au-dessus des cuisses (px de la vue)
    upper = ys < hip
    lab[purple & upper] = 'trapezes'
    thigh = purple & ~upper
    if view == 'face':
        lab[thigh] = 'quadriceps'
    elif view == 'dos':
        lab[thigh] = 'ischios'
    else:
        # profil (tourné vers la droite) : devant = quadriceps, derrière =
        # ischios, par rapport au milieu de la cuisse de chaque ligne
        for y in np.unique(ys[thigh]):
            row = np.where(thigh[y])[0]
            mid = (row.min() + row.max()) / 2
            lab[y, row[row >= mid]] = 'quadriceps'
            lab[y, row[row < mid]] = 'ischios'
    pink = np.isin(lab, ['fessiers', 'adducteurs'])
    if view == 'face':
        lab[pink] = 'adducteurs'
    else:
        lab[pink] = 'fessiers'
    orange = np.isin(lab, ['biceps', 'triceps'])
    if view == 'face':
        lab[orange] = 'biceps'
    elif view == 'dos':
        lab[orange] = 'triceps'
    else:
        for y in np.unique(ys[orange]):
            row = np.where(orange[y])[0]
            mid = (row.min() + row.max()) / 2
            lab[y, row[row >= mid]] = 'biceps'
            lab[y, row[row < mid]] = 'triceps'
    cyan = np.isin(lab, ['mollets', 'tibial'])
    if view == 'dos':
        lab[cyan] = 'mollets'
    elif view == 'profil':
        for y in np.unique(ys[cyan]):
            row = np.where(cyan[y])[0]
            mid = (row.min() + row.max()) / 2
            lab[y, row[row >= mid]] = 'tibial'
            lab[y, row[row < mid]] = 'mollets'
    if view == 'face':
        # de face, le tibial antérieur est sur le bord externe de la jambe,
        # les mollets sur le bord interne (chaque jambe de part et d'autre
        # de l'axe du corps)
        axis = w / 2
        for y in np.unique(ys[cyan]):
            for side in (0, 1):
                row = np.where(cyan[y] & ((xs[y] < axis) if side == 0 else (xs[y] >= axis)))[0]
                if not len(row):
                    continue
                mid = (row.min() + row.max()) / 2
                outer = row < mid if side == 0 else row >= mid
                lab[y, row[outer]] = 'tibial'
                lab[y, row[~outer]] = 'mollets'
    blue = lab == 'dorsaux'
    if view == 'face':
        lab[blue] = 'deltoides'
    if view == 'dos':
        # de dos, le vert des flancs est celui des obliques
        lab[np.isin(lab, ['abdominaux', 'obliques'])] = 'obliques'
    return lab


def clean(lab, min_px=40):
    """Petites composantes (liserés d'anticrénelage) rattachées au calque
    majoritaire de leur voisinage."""
    from scipy import ndimage
    out = lab.copy()
    for name in LAYERS:
        m = lab == name
        comp, n = ndimage.label(m)
        if n == 0:
            continue
        sizes = ndimage.sum(m, comp, range(1, n + 1))
        for k, s in enumerate(sizes, 1):
            if s >= min_px:
                continue
            region = comp == k
            ring = ndimage.binary_dilation(region, iterations=2) & ~region
            vals, counts = np.unique(lab[ring], return_counts=True)
            keep = [(c, v) for v, c in zip(vals, counts) if v != name]
            if keep:
                out[region] = max(keep)[1]
    return out


def build(apercu=None):
    src = np.array(Image.open(SRC).convert('RGB'))
    report = {'vues': {}}
    previews = []
    for view, x0, x1 in VIEWS:
        rgb = src[Y0:Y1, x0:x1]
        lab = classify(rgb)
        lab = refine(lab, view, x0)
        lab = clean(lab)
        # cadre serré autour de la figure (fond blanc exclu)
        fig = lab != 'blanc'
        ys, xs = np.where(fig)
        pad = 6
        top, bot = max(0, ys.min() - pad), min(lab.shape[0], ys.max() + pad)
        left, right = max(0, xs.min() - pad), min(lab.shape[1], xs.max() + pad)
        lab = lab[top:bot, left:right]
        H, W = lab.shape
        # masques à la résolution de la source (bords adoucis)
        size = (W, H)
        d = OUT / view
        d.mkdir(parents=True, exist_ok=True)
        present = []
        for name in LAYERS:
            m = (lab == name).astype(np.uint8) * 255
            if not m.any():
                continue
            img = Image.fromarray(m, 'L').filter(ImageFilter.GaussianBlur(.6))
            img = img.resize(size, Image.LANCZOS)
            # masque alpha (blanc opaque, teinté par l'application)
            rgba = Image.new('LA', size, 255)
            rgba.putalpha(img)
            rgba.save(d / f'{name}.png', optimize=True)
            present.append(name)
        # carte des étiquettes (toucher) : valeur = 1 + rang du calque dans
        # LAYERS, 0 = transparent ; même taille que les masques, au plus proche
        idx = np.zeros(lab.shape, dtype=np.uint8)
        for k, name in enumerate(LAYERS, 1):
            idx[lab == name] = k
        Image.fromarray(idx, 'L').resize(size, Image.NEAREST).save(d / 'etiquettes.png',
                                                                     optimize=True)
        report['vues'][view] = {'largeur': size[0], 'hauteur': size[1], 'calques': present}
        if apercu:
            pal = {**{k: PALETTE[k] for k in GROUPS if k in PALETTE}, 'ischios': (110, 60, 160),
                   'tibial': (120, 230, 240), 'peau': (205, 205, 203), 'sombre': (70, 70, 70),
                   'blanc': (255, 255, 255)}
            prev = np.zeros((H, W, 3), dtype=np.uint8)
            for name, c in pal.items():
                prev[lab == name] = c
            previews.append(Image.fromarray(prev))
    (OUT / 'carte.json').write_text(json.dumps(
        {**report, 'groupes': GROUPS, 'calques': LAYERS,
         'source': 'tools/muscles2d/source_carte.png (image du propriétaire, 30/09/2026)'},
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
