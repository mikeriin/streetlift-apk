# -*- coding: utf-8 -*-
"""Vue de profil de la carte musculaire, à partir de l'illustration du propriétaire.

Refonte muscles et animations (27/09/2026). Entrée : l'image de profil validée
par le propriétaire (personnage tourné vers la gauche, fond transparent ou
blanc). Le personnage n'est PAS redessiné : l'outil

1. détoure proprement (alpha opaque dans le corps, bords sans liseré clair) ;
2. recadre et met à l'échelle à 760 px de haut, avec les mêmes marges que
   ``front_base.png`` / ``back_base.png`` (8 px) ;
3. harmonise les niveaux de gris sur la face (appariement des quantiles,
   séparément pour le noir des contours et le gris des muscles) ;
4. segmente les pièces musculaires (régions claires séparées par les traits
   sombres, même méthode que ``muscles_from_reference.py``) et les attribue aux
   11 groupes de l'application par des points-graines ; chaque pixel clair non
   attribué reprend le groupe du noyau le plus proche ;
5. écrit ``profile_base.png``, ``profile_<groupe>.png`` (niveaux de gris +
   alpha, même codage que les calques face / dos : gris = 0,877 × base + 89,5)
   et complète ``meta.json``.

Relançable :
    python3 tools/muscles_profile.py SOURCE.png [--assets assets/muscles]
        [--controle dossier]   # planches de contrôle (face / dos / profil,
                               # chaque calque surligné seul)
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

GROUPS = {
    'pectoraux': 'pectoraux', 'épaules': 'epaules', 'biceps': 'biceps',
    'triceps': 'triceps', 'avant-bras': 'avant_bras', 'gainage': 'gainage',
    'dos': 'dos', 'quadriceps': 'quadriceps', 'ischios': 'ischios',
    'fessiers': 'fessiers', 'mollets': 'mollets',
}

# Points-graines (pixels de l'image source 941 × 1672) : un point à l'intérieur
# de chaque pièce musculaire → groupe. Relevés sur la planche de segmentation
# (--controle), un par pièce ; le cou suit la convention de la face (« dos »).
SEEDS = [
    ((471, 209), 'dos'), ((441, 225), 'dos'), ((509, 216), 'dos'),
    ((499, 249), 'dos'), ((585, 405), 'dos'),
    ((528, 336), 'épaules'), ((460, 343), 'épaules'), ((581, 359), 'épaules'),
    ((435, 295), 'pectoraux'), ((397, 391), 'pectoraux'),
    ((472, 449), 'biceps'), ((516, 533), 'biceps'),
    ((548, 449), 'triceps'), ((560, 511), 'triceps'),
    ((428, 449), 'gainage'), ((433, 485), 'gainage'), ((435, 522), 'gainage'),
    ((395, 545), 'gainage'), ((361, 498), 'gainage'), ((415, 578), 'gainage'),
    ((364, 570), 'gainage'), ((432, 642), 'gainage'), ((368, 634), 'gainage'),
    ((370, 704), 'gainage'), ((388, 779), 'gainage'),
    ((500, 600), 'avant-bras'), ((538, 617), 'avant-bras'),
    ((545, 677), 'avant-bras'), ((434, 711), 'avant-bras'),
    ((502, 761), 'avant-bras'), ((454, 765), 'avant-bras'),
    ((476, 790), 'avant-bras'), ((517, 792), 'avant-bras'),
    ((560, 803), 'fessiers'),
    ((398, 859), 'quadriceps'), ((465, 978), 'quadriceps'),
    ((424, 1026), 'quadriceps'), ((441, 1171), 'quadriceps'),
    ((545, 909), 'ischios'), ((530, 963), 'ischios'), ((498, 1046), 'ischios'),
    ((484, 1118), 'ischios'),
    ((473, 1240), 'mollets'), ((529, 1241), 'mollets'), ((574, 1254), 'mollets'),
    ((512, 1350), 'mollets'), ((538, 1418), 'mollets'), ((503, 1439), 'mollets'),
]

HEIGHT, MARGIN = 760, 8
LIGHT = 95  # seuil entre le noir des contours et le gris des muscles


def load_source(path):
    im = Image.open(path).convert('RGBA')
    a = np.asarray(im).astype(np.float64)
    lum = a[..., :3].mean(axis=2)
    alpha = a[..., 3] / 255.0
    if alpha.min() > 0.99:  # fond blanc opaque : alpha tiré de la luminance
        bg = lum > 245
        lab, _ = nd.label(bg)
        border = set(np.unique(np.concatenate(
            [lab[0], lab[-1], lab[:, 0], lab[:, -1]])))
        outside = np.isin(lab, [b for b in border if b])
        alpha = np.where(outside, 0.0, 1.0)
        edge = nd.binary_dilation(outside, iterations=2) & ~outside
        alpha[edge] = np.clip((255 - lum[edge]) / (255 - 42), 0, 1)
    return lum, alpha


def clean(lum, alpha):
    """Alpha opaque dans le corps ; bords teintés du noir du contour."""
    body = nd.binary_fill_holes(alpha > 0.5)
    inner = nd.binary_erosion(body, iterations=2)
    a = np.clip(alpha / 0.985, 0, 1)
    a[inner] = 1.0
    dark = np.median(lum[inner & (lum < LIGHT)])
    edge = (a < 0.999) | ~nd.binary_erosion(body, iterations=1)
    lum = lum.copy()
    lum[edge] = np.minimum(lum[edge], dark)  # pas de liseré clair
    return lum, a, body


def harmonize(lum, body, refs):
    """Courbe affine par morceaux, monotone, passant par des points d'appui
    appariés entre histogrammes : noir des contours (médiane de la classe
    sombre) et quantiles 5 / 50 / 95 / 99,5 de la classe claire (muscles).
    Une courbe douce n'amplifie pas le grain des aplats sombres."""
    ref = np.concatenate(refs)
    src_dark, src_light = lum[body & (lum < LIGHT)], lum[body & (lum >= LIGHT)]
    ref_dark, ref_light = ref[ref < 70], ref[ref >= LIGHT]
    src_dark = src_dark[src_dark < 70]
    qs = [5, 50, 95, 99.5]
    xs = [0, np.median(src_dark)] + list(np.percentile(src_light, qs)) + [255]
    ys = [0, np.median(ref_dark)] + list(np.percentile(ref_light, qs)) + [255]
    return np.interp(lum, xs, ys), list(zip(xs, ys))


def resize_premul(lum, alpha, box, size):
    x0, y0, x1, y1 = box
    la = (lum * alpha)[y0:y1, x0:x1].astype(np.float32)
    aa = alpha[y0:y1, x0:x1].astype(np.float32)
    rl = np.asarray(Image.fromarray(la, 'F').resize(size, Image.LANCZOS))
    ra = np.asarray(Image.fromarray(aa, 'F').resize(size, Image.LANCZOS))
    ra = np.clip(ra, 0, 1)
    rl = np.where(ra > 1e-3, rl / np.maximum(ra, 1e-3), 0)
    return np.clip(rl, 0, 255), ra


def segment(lum, body):
    light = (lum >= LIGHT) & body
    core = nd.binary_erosion(light, iterations=2)
    lab, n = nd.label(core)
    groups = np.full(lab.shape, -1, np.int16)
    names = list(GROUPS)
    for (x, y), g in SEEDS:
        piece = lab[y, x]
        if piece == 0:
            raise SystemExit(f'Graine hors pièce : {(x, y)} ({g})')
        groups[lab == piece] = names.index(g)
    # pixels clairs non attribués (bords érodés, petites pièces) : noyau le
    # plus proche, sans déborder de plus de 8 px
    known = groups >= 0
    dist, (iy, ix) = nd.distance_transform_edt(~known, return_indices=True)
    full = np.where(light & (dist <= 8), groups[iy, ix], -1)
    orphan = np.unique(lab[(lab > 0) & ~known])
    return full, [int(o) for o in orphan]


def to_la(lum, alpha):
    l8 = np.clip(np.round(lum), 0, 255).astype(np.uint8)
    a8 = np.clip(np.round(alpha * 255), 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([l8, a8]), 'LA')


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument('source', type=Path)
    ap.add_argument('--assets', type=Path, default=Path('assets/muscles'))
    ap.add_argument('--controle', type=Path)
    args = ap.parse_args()
    lum, alpha = load_source(args.source)
    lum, alpha, body = clean(lum, alpha)
    refs = []
    for v in ('front', 'back'):
        r = np.asarray(Image.open(args.assets / f'{v}_base.png').convert('LA'))
        refs.append(r[..., 0][r[..., 1] > 250].astype(np.float64))
    src_lum = lum
    lum, curve = harmonize(lum, body, refs)
    print('courbe de gris (source → face/dos) :',
          ', '.join(f'{x:.0f}→{y:.0f}' for x, y in curve))

    ys, xs = np.nonzero(alpha > 0.02)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    f = (HEIGHT - 2 * MARGIN) / (box[3] - box[1])
    fw = round((box[2] - box[0]) * f)
    fh = HEIGHT - 2 * MARGIN
    W = fw + 2 * MARGIN
    bl, ba = resize_premul(lum, alpha, box, (fw, fh))
    base_l = np.zeros((HEIGHT, W)); base_a = np.zeros((HEIGHT, W))
    base_l[MARGIN:MARGIN + fh, MARGIN:MARGIN + fw] = bl
    base_a[MARGIN:MARGIN + fh, MARGIN:MARGIN + fw] = ba
    to_la(base_l, base_a).save(args.assets / 'profile_base.png', optimize=True)

    full, orphans = segment(src_lum, body)
    names = list(GROUPS)
    for gi, g in enumerate(names):
        m = (full == gi).astype(np.float64)
        _, ma = resize_premul(np.zeros_like(m), m, box, (fw, fh))
        la = np.zeros((HEIGHT, W))
        la[MARGIN:MARGIN + fh, MARGIN:MARGIN + fw] = ma
        la = np.minimum(la, base_a)
        la[la < 0.02] = 0
        ll = np.where(la > 0, 0.877 * base_l + 89.5, 0)
        to_la(ll, la).save(args.assets / f'profile_{GROUPS[g]}.png',
                           optimize=True)

    meta_path = args.assets / 'meta.json'
    meta = json.loads(meta_path.read_text()) if meta_path.exists() else {}
    meta['profile'] = {'w': W, 'h': HEIGHT}
    meta_path.write_text(json.dumps(meta, ensure_ascii=False))
    print(f'profil : {W} × {HEIGHT} ; pièces sans graine : {orphans or "aucune"}')

    if args.controle:
        control(args.assets, args.controle)


def _composite(la_img, bg=(18, 18, 18)):
    rgba = la_img.convert('RGBA')
    out = Image.new('RGBA', rgba.size, bg + (255,))
    out.alpha_composite(rgba)
    return out


def control(assets, out):
    """Planche face / dos / profil + chaque calque de profil surligné seul."""
    out.mkdir(parents=True, exist_ok=True)
    views = [Image.open(assets / f'{v}_base.png') for v in ('front', 'back', 'profile')]
    sheet = Image.new('RGBA', (sum(v.width for v in views) + 40, HEIGHT), (18, 18, 18, 255))
    x = 0
    for v in views:
        sheet.alpha_composite(_composite(v), (x, 0)); x += v.width + 20
    sheet.save(out / 'planche_face_dos_profil.png')
    base = Image.open(assets / 'profile_base.png')
    tiles = []
    for g, key in GROUPS.items():
        layer = np.asarray(Image.open(assets / f'profile_{key}.png').convert('LA')).astype(float)
        img = np.asarray(_composite(base).convert('RGB')).astype(float)
        a = layer[..., 1:2] / 255
        red = np.array([220, 40, 40]) * (layer[..., :1] / 255)
        img = img * (1 - a) + red * a
        t = Image.fromarray(img.astype(np.uint8))
        ImageDraw.Draw(t).text((4, 4), g, fill=(255, 255, 255))
        tiles.append(t)
    w = tiles[0].width
    grid = Image.new('RGB', (w * 6 + 50, HEIGHT * 2 + 10), (0, 0, 0))
    for i, t in enumerate(tiles):
        grid.paste(t, ((i % 6) * (w + 10), (i // 6) * (HEIGHT + 10)))
    grid.save(out / 'calques_profil.png')


if __name__ == '__main__':
    main()
