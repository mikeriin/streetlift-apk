"""Vectorisation (potrace) et rendu des commandes numériques (lot GK).

Format des commandes (identique côté Dart, voir packages/kalis_koach/CONTRAT.md) :
une liste plate d'entiers, opcode suivi de ses coordonnées.
  0 x y              déplacer (début d'un sous-chemin)
  1 x y              ligne
  2 x1 y1 x2 y2 x y  courbe cubique
  3                  fermer le sous-chemin
Remplissage pair-impair (even-odd) pour chaque calque.
"""
from __future__ import annotations

import numpy as np
import potrace
from PIL import Image, ImageDraw

MOVE, LINE, CUBIC, CLOSE = 0, 1, 2, 3

# Paramètres de potrace (valeurs par défaut de potrace 1.16, Selinger 2003) :
# alphamax 1.0 = lissage des angles par défaut ; opttolerance 0.2 = fusion des
# courbes sans s'écarter de plus de 0,2 px du tracé.
ALPHAMAX = 1.0
OPTTOLERANCE = 0.2


def trace(mask: np.ndarray, turdsize: int):
    """Trace un masque booléen (True = forme). Renvoie une liste de courbes,
    chacune = liste de segments en coordonnées pixel (coins des pixels)."""
    pad = 2
    m = np.pad(mask, pad, constant_values=False)
    # potracer inverse son entrée : il trace les pixels False.
    bm = potrace.Bitmap(~m)
    path = bm.trace(turdsize=turdsize, alphamax=ALPHAMAX, opticurve=True,
                    opttolerance=OPTTOLERANCE)
    curves = []
    for c in path:
        sp = (c.start_point.x - pad, c.start_point.y - pad)
        segs = []
        for s in c.segments:
            if s.is_corner:
                segs.append(('corner', (s.c.x - pad, s.c.y - pad), (s.end_point.x - pad, s.end_point.y - pad)))
            else:
                segs.append(('bezier', (s.c1.x - pad, s.c1.y - pad), (s.c2.x - pad, s.c2.y - pad),
                             (s.end_point.x - pad, s.end_point.y - pad)))
        curves.append((sp, segs))
    return curves


def flatten_curve(curve, steps: int = 12) -> np.ndarray:
    sp, segs = curve
    pts = [sp]
    cur = sp
    for s in segs:
        if s[0] == 'corner':
            pts.append(s[1])
            pts.append(s[2])
            cur = s[2]
        else:
            p0, p1, p2, p3 = np.array(cur), np.array(s[1]), np.array(s[2]), np.array(s[3])
            for i in range(1, steps + 1):
                t = i / steps
                pts.append(tuple((1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3))
            cur = s[3]
    return np.array(pts, dtype=np.float64)


def _point_in_poly(x: float, y: float, poly: np.ndarray) -> bool:
    xs, ys = poly[:, 0], poly[:, 1]
    xj, yj = np.roll(xs, 1), np.roll(ys, 1)
    cond = ((ys > y) != (yj > y))
    with np.errstate(divide='ignore', invalid='ignore'):
        xint = (xj - xs) * (y - ys) / (yj - ys) + xs
    return bool(np.count_nonzero(cond & (x < xint)) % 2)


def nesting_depths(curves) -> list[int]:
    """Profondeur d'imbrication de chaque courbe (0 = contour extérieur)."""
    polys = [flatten_curve(c, 4) for c in curves]
    depths = []
    for i, p in enumerate(polys):
        x, y = p[0]
        d = 0
        for j, q in enumerate(polys):
            if i != j and _point_in_poly(x, y, q):
                d += 1
        depths.append(d)
    return depths


def curve_area(curve) -> float:
    p = flatten_curve(curve, 6)
    x, y = p[:, 0], p[:, 1]
    return float(abs(np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1))) / 2)


def to_commands(curves, fx, fy) -> list[int]:
    """Convertit des courbes en commandes entières ; fx, fy : px -> unités."""
    out: list[int] = []

    def p(pt):
        return [int(round(fx(pt[0]))), int(round(fy(pt[1])))]

    for sp, segs in curves:
        out += [MOVE] + p(sp)
        for s in segs:
            if s[0] == 'corner':
                out += [LINE] + p(s[1])
                out += [LINE] + p(s[2])
            else:
                out += [CUBIC] + p(s[1]) + p(s[2]) + p(s[3])
        out.append(CLOSE)
    return out


def parse_commands(cmds: list[int]):
    """Commandes -> liste de sous-chemins (listes de segments en unités)."""
    subs = []
    i = 0
    cur = None
    while i < len(cmds):
        op = cmds[i]
        if op == MOVE:
            cur = [('M', (cmds[i + 1], cmds[i + 2]))]
            subs.append(cur)
            i += 3
        elif op == LINE:
            cur.append(('L', (cmds[i + 1], cmds[i + 2])))
            i += 3
        elif op == CUBIC:
            cur.append(('C', (cmds[i + 1], cmds[i + 2]), (cmds[i + 3], cmds[i + 4]), (cmds[i + 5], cmds[i + 6])))
            i += 7
        elif op == CLOSE:
            i += 1
        else:
            raise ValueError(f'opcode inconnu {op} à {i}')
    return subs


def subpath_polygon(sub, tx, ty, steps: int = 16) -> list[tuple[float, float]]:
    pts = []
    cur = None
    for s in sub:
        if s[0] in ('M', 'L'):
            cur = (tx(s[1][0]), ty(s[1][1]))
            pts.append(cur)
        else:
            p0 = np.array(cur)
            p1 = np.array((tx(s[1][0]), ty(s[1][1])))
            p2 = np.array((tx(s[2][0]), ty(s[2][1])))
            p3 = np.array((tx(s[3][0]), ty(s[3][1])))
            for k in range(1, steps + 1):
                t = k / steps
                q = (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t ** 2 * p2 + t ** 3 * p3
                pts.append((float(q[0]), float(q[1])))
            cur = (float(p3[0]), float(p3[1]))
    return pts


def render_evenodd(cmds: list[int], size: tuple[int, int], tx, ty, ss: int = 4) -> np.ndarray:
    """Rendu anticrénelé (couverture 0-1) d'un calque, remplissage pair-impair.

    tx, ty : unités -> pixels de sortie. Sur-échantillonnage ss×ss.
    Chaque sous-chemin est rempli dans son propre masque puis combiné par OU
    exclusif : c'est exactement la règle pair-impair.
    """
    w, h = size
    acc = np.zeros((h * ss, w * ss), dtype=bool)
    for sub in parse_commands(cmds):
        poly = subpath_polygon(sub, lambda x: tx(x) * ss, lambda y: ty(y) * ss)
        if len(poly) < 3:
            continue
        im = Image.new('1', (w * ss, h * ss), 0)
        # Centres de pixels : décalage d'un demi-pixel (convention potrace :
        # coordonnées aux coins des pixels).
        ImageDraw.Draw(im).polygon([(x - 0.5, y - 0.5) for x, y in poly], fill=1)
        acc ^= np.asarray(im, dtype=bool)
    return acc.reshape(h, ss, w, ss).mean(axis=(1, 3))


def iou(coverage: np.ndarray, mask: np.ndarray) -> float:
    m = mask.astype(np.float64)
    inter = np.minimum(coverage, m).sum()
    union = np.maximum(coverage, m).sum()
    return float(inter / union) if union else 1.0
