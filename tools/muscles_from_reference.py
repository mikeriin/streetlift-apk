# -*- coding: utf-8 -*-
"""Segmentation de l'atlas de référence : muscles individuels → groupes → masques."""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np, json
from scipy import ndimage

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', type=Path, help='Illustration anatomique de référence')
parser.add_argument('--output', type=Path, default=Path('segmentation'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
im = Image.open(args.source).convert('RGB')
a = np.asarray(im).astype(np.float32); H, W, _ = a.shape
r, g, b = a[:,:,0], a[:,:,1], a[:,:,2]
mx = a.max(axis=2); mn = a.min(axis=2)
sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0); val = mx / 255
muscle = (sat > 0.35) & (val > 0.45) & (r > g)
body = (val > 0.10)
body = ndimage.binary_closing(body, structure=np.ones((5,5)))
body = ndimage.binary_fill_holes(body)

core = ndimage.binary_erosion(muscle, structure=np.ones((3,3)), iterations=2)
lab, n = ndimage.label(core, structure=np.ones((3,3)))
sizes = ndimage.sum(core, lab, range(1, n+1))
for i, s in enumerate(sizes):
    if s < 40: lab[lab == i+1] = 0
# propagation des étiquettes aux pixels muscle non étiquetés (plus proche noyau)
dist, (iy, ix) = ndimage.distance_transform_edt(lab == 0, return_indices=True)
full = np.where(muscle, lab[iy, ix], 0)
full[dist > 6] = 0  # ne pas déborder trop loin du noyau

MID = W // 2
GROUPS = ['pectoraux','épaules','biceps','triceps','avant-bras','gainage','dos','quadriceps','ischios','fessiers','mollets']

def classify(view, nx, ny, bw):
    """nx, ny normalisés dans la boîte du corps (0..1) ; bw = largeur relative."""
    dx = abs(nx - 0.5)
    arm = dx > 0.27
    if view == 'front':
        if arm:
            if ny < 0.245: return 'épaules'
            if ny < 0.335: return 'biceps'
            return 'avant-bras' if ny < 0.56 else None
        if ny < 0.145: return 'dos'                                       # trapèzes, cou
        if ny < 0.29: return 'pectoraux'
        if ny < 0.52: return 'gainage'                                    # abdos, obliques, dentelé
        if ny < 0.73: return 'quadriceps'
        if ny < 0.96: return 'mollets'
        return None
    else:
        if arm:
            if ny < 0.245: return 'épaules'
            if ny < 0.335: return 'triceps'
            return 'avant-bras' if ny < 0.56 else None
        if ny < 0.49: return 'dos'
        if ny < 0.58: return 'fessiers'
        if ny < 0.76: return 'ischios'
        if ny < 0.96: return 'mollets'
        return None

out = {}
debug = Image.new('RGB', (W, H), (14,18,22)); dd = ImageDraw.Draw(debug)
palette = {'pectoraux':(233,80,80),'épaules':(80,160,233),'biceps':(233,196,106),'triceps':(180,120,233),'avant-bras':(120,233,180),
           'gainage':(233,140,60),'dos':(90,200,90),'quadriceps':(233,60,160),'ischios':(60,200,233),'fessiers':(200,200,60),'mollets':(160,160,160)}
ids = np.unique(full); ids = ids[ids > 0]
assign = {}
for view, (x0, x1) in (('front', (0, MID)), ('back', (MID, W))):
    bview = body[:, x0:x1]
    ys, xs = np.nonzero(bview)
    by0, by1, bx0, bx1 = ys.min(), ys.max(), xs.min() + x0, xs.max() + x0
    bw = bx1 - bx0; bh = by1 - by0
    for i in ids:
        m = (full == i)
        cy, cx = ndimage.center_of_mass(m)
        if not (x0 <= cx < x1): continue
        nx = (cx - bx0) / bw; ny = (cy - by0) / bh
        gname = classify(view, nx, ny, bw)
        assign[int(i)] = (view, gname, float(nx), float(ny), int(m.sum()))
    out[view] = {'bbox': [int(bx0), int(by0), int(bx1), int(by1)]}
# image de contrôle
dbg = np.zeros((H, W, 3), np.uint8); dbg[body] = (38,46,54)
for i, (view, gname, nx, ny, sz) in assign.items():
    col = palette.get(gname, (255,255,255)) if gname else (255,0,255)
    dbg[full == i] = col
Image.fromarray(dbg).save(args.output / 'seg_debug.png')
json.dump({'assign': assign, 'views': out}, open(args.output / 'seg.json', 'w', encoding='utf-8'), ensure_ascii=False)
np.save(args.output / 'full.npy', full); np.save(args.output / 'body.npy', body)
from collections import Counter
print('pièces :', len(assign), '| non classées :', sum(1 for v in assign.values() if v[1] is None))
print(Counter((v[0], v[1]) for v in assign.values()))
