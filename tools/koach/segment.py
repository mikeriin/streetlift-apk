"""Découpe et nettoyage des planches de Koach et des flammes (lot GK).

Fonctions pures sur des tableaux numpy : aucune écriture de fichier ici.
Les planches sont découpées par **composantes connexes** : chaque composante
d'encre est rattachée à la case de la grille déclarée qui contient son
centre, puis des contrôles vérifient que la découpe est sans ambiguïté
(une seule grande silhouette par case, aucune composante à cheval sur deux
cases). Aucune coordonnée de découpe n'est codée en dur.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import cv2
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

# Seuil encre / papier sur la luminance (0-255) : milieu de l'échelle, ce qui
# place la frontière au milieu de l'anticrénelage.
INK_THRESHOLD = 128
# Liserés de séparation (bras devant le corps, doigts, mains jointes) : sur
# les planches ce sont des traits clairs de 2 à 6 px, gris, irréguliers et
# parfois interrompus. Ils portent le dessin (sans eux, « main au menton »
# devient une silhouette pleine) : ils sont conservés et nettoyés, c'est-à-
# dire transformés en traits de papier nets d'épaisseur régulière.
# Détection : pixels clairs (luminance ≥ LINE_LUMA) appartenant à une
# structure fine (supprimée par une ouverture de rayon THIN_RADIUS, soit
# moins de 9 px de large) et assez longue (≥ LINE_MIN_AREA px²).
LINE_LUMA = 70
THIN_RADIUS = 4
LINE_MIN_AREA = 60
# Épaississement : rayon de dilatation du trait détecté (3 px -> trait de
# 8 à 12 px sur la planche, soit ~1 % de la hauteur du corps, ~1,5 px à
# l'écran pour un Koach de 150 px) ; comble aussi les interruptions < 6 px.
LINE_RADIUS = 3
# Poussières : composantes d'encre ou trous de papier plus petits que cela
# (en px², à la résolution de la planche) sont supprimés.
SPECK_AREA = 150


def load_luminance(path) -> np.ndarray:
    """Luminance 0-255 (float32), transparence composée sur fond blanc."""
    im = Image.open(path).convert('RGBA')
    a = np.asarray(im).astype(np.float32)
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    alpha = a[..., 3] / 255.0
    return lum * alpha + 255.0 * (1.0 - alpha)


def raw_ink(lum: np.ndarray) -> np.ndarray:
    return lum < INK_THRESHOLD


@dataclass
class CleanReport:
    line_parts: int = 0
    line_seed_px: int = 0
    line_px: int = 0
    ink_specks: int = 0
    paper_specks: int = 0


def disk(r: int) -> np.ndarray:
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))


def separation_lines(lum: np.ndarray, rep: CleanReport | None = None) -> np.ndarray:
    """Traits de séparation nets (masque booléen) extraits des liserés."""
    light = (lum >= LINE_LUMA).astype(np.uint8)
    opened = cv2.morphologyEx(light, cv2.MORPH_OPEN, disk(THIN_RADIUS))
    thin = (light == 1) & (opened == 0)
    n, lab, st, _ = cv2.connectedComponentsWithStats(thin.astype(np.uint8), connectivity=8)
    keep = np.zeros(n, bool)
    keep[1:] = st[1:, cv2.CC_STAT_AREA] >= LINE_MIN_AREA
    seed = keep[lab]
    lines = cv2.dilate(seed.astype(np.uint8), disk(LINE_RADIUS)).astype(bool)
    if rep is not None:
        rep.line_parts = int(keep.sum())
        rep.line_seed_px = int(seed.sum())
        rep.line_px = int(lines.sum())
    return lines


def clean_ink(lum: np.ndarray) -> tuple[np.ndarray, np.ndarray, CleanReport]:
    """Encre nettoyée : seuil 128, traits de séparation nets, sans poussières.

    Renvoie (encre, traits, rapport) ; les traits sont du papier."""
    rep = CleanReport()
    lines = separation_lines(lum, rep)
    out = (lum < INK_THRESHOLD) & ~lines
    n, lab, st, _ = cv2.connectedComponentsWithStats(out.astype(np.uint8), connectivity=8)
    small = np.zeros(n, bool)
    small[1:] = st[1:, cv2.CC_STAT_AREA] < SPECK_AREA
    rep.ink_specks = int(small.sum())
    out[small[lab]] = False
    n, lab, st, _ = cv2.connectedComponentsWithStats((~out).astype(np.uint8), connectivity=4)
    small = np.zeros(n, bool)
    small[1:] = st[1:, cv2.CC_STAT_AREA] < SPECK_AREA
    rep.paper_specks = int(small.sum())
    out[small[lab]] = True
    return out, lines, rep


@dataclass
class Cell:
    sheet: str
    row: int
    col: int
    body_label: int
    labels: list[int]
    bbox: tuple[int, int, int, int]  # x0, y0, x1, y1 (exclusif) de toute la pose
    body_bbox: tuple[int, int, int, int]
    body_area: int
    second_area: int


class SegmentationError(RuntimeError):
    pass


def split_sheet(ink: np.ndarray, cols: int, rows: int, sheet: str = '?'):
    """Rattache chaque composante d'encre à une case ; contrôle la découpe.

    Renvoie (labels, cells) où labels est l'image des composantes.
    """
    h, w = ink.shape
    n, lab, st, cen = cv2.connectedComponentsWithStats(ink.astype(np.uint8), connectivity=8)
    cw, ch = w / cols, h / rows
    groups: dict[tuple[int, int], list[int]] = {}
    for i in range(1, n):
        c = min(cols - 1, int(cen[i][0] // cw))
        r = min(rows - 1, int(cen[i][1] // ch))
        groups.setdefault((r, c), []).append(i)
    cells = []
    for r in range(rows):
        for c in range(cols):
            ids = groups.get((r, c), [])
            if not ids:
                raise SegmentationError(f'{sheet} case ({r},{c}) vide')
            ids.sort(key=lambda i: -st[i, cv2.CC_STAT_AREA])
            body = ids[0]
            area = int(st[body, cv2.CC_STAT_AREA])
            second = int(st[ids[1], cv2.CC_STAT_AREA]) if len(ids) > 1 else 0
            if area < 1.5 * second:
                raise SegmentationError(f'{sheet} ({r},{c}) : silhouette ambiguë ({area} vs {second})')
            bx, by, bw, bh = (int(v) for v in st[body, :4])
            if bh < 0.5 * ch:
                raise SegmentationError(f'{sheet} ({r},{c}) : silhouette trop petite')
            # Aucune composante ne déborde de sa case de plus de 12 % (les pieds
            # d'un chevalet frôlent la ligne suivante) ; le chevauchement avec
            # une autre silhouette est contrôlé ensuite.
            tol_x, tol_y = 0.12 * cw, 0.12 * ch
            x0 = y0 = 10 ** 9
            x1 = y1 = -1
            for i in ids:
                x, y, ww, hh = (int(v) for v in st[i, :4])
                if (x < c * cw - tol_x or x + ww > (c + 1) * cw + tol_x
                        or y < r * ch - tol_y or y + hh > (r + 1) * ch + tol_y):
                    raise SegmentationError(f'{sheet} ({r},{c}) : composante {i} à cheval sur deux cases ({x},{y},{ww},{hh})')
                x0, y0 = min(x0, x), min(y0, y)
                x1, y1 = max(x1, x + ww), max(y1, y + hh)
            cells.append(Cell(sheet, r, c, body, ids, (x0, y0, x1, y1),
                              (bx, by, bx + bw, by + bh), area, second))
    # Aucune composante ne touche la silhouette d'une autre case.
    for cell in cells:
        for other in cells:
            if other is cell:
                continue
            ox0, oy0, ox1, oy1 = other.body_bbox
            for i in cell.labels:
                x, y, ww, hh = (int(v) for v in st[i, :4])
                if x < ox1 and x + ww > ox0 and y < oy1 and y + hh > oy0:
                    sub = lab[max(y, oy0):min(y + hh, oy1), max(x, ox0):min(x + ww, ox1)]
                    if np.any(sub == i) and np.any(sub == other.body_label):
                        raise SegmentationError(
                            f'{sheet} : composante {i} de ({cell.row},{cell.col}) dans la silhouette ({other.row},{other.col})')
    return lab, cells


@dataclass
class Hole:
    mask: np.ndarray  # booléen, coordonnées de la découpe
    area: int
    cy: float
    cx: float
    bbox: tuple[int, int, int, int]
    solidity: float
    kind: str = 'paper'  # 'eye_open', 'eye_closed', 'paper'


@dataclass
class PoseMasks:
    ink: np.ndarray       # encre nettoyée de la pose (découpe)
    body: np.ndarray      # composante principale (silhouette du personnage)
    lines: np.ndarray     # traits de séparation (papier) touchant la pose
    origin: tuple[int, int]  # (x0, y0) de la découpe dans la planche


def crop_pose(clean: np.ndarray, lines: np.ndarray, lab: np.ndarray, cell: Cell, pad: int = 12) -> PoseMasks:
    x0, y0, x1, y1 = cell.bbox
    x0, y0 = max(0, x0 - pad), max(0, y0 - pad)
    x1, y1 = min(clean.shape[1], x1 + pad), min(clean.shape[0], y1 + pad)
    sub_lab = lab[y0:y1, x0:x1]
    ink = np.isin(sub_lab, cell.labels)
    near = cv2.dilate(ink.astype(np.uint8), disk(2)).astype(bool)
    ln, ll = cv2.connectedComponents(lines[y0:y1, x0:x1].astype(np.uint8), connectivity=8)
    ids = np.unique(ll[near & (ll > 0)])
    pose_lines = np.isin(ll, ids[ids > 0])
    # Silhouette du personnage : les traits de séparation coupent parfois le
    # corps en morceaux (bras devant le torse) ; on la recompose avec les
    # traits, puis on garde la composante de la plus grande pièce d'encre.
    joined = (ink | pose_lines).astype(np.uint8)
    _, jl = cv2.connectedComponents(joined, connectivity=8)
    seed = sub_lab == cell.body_label
    body_id = np.bincount(jl[seed]).argmax()
    body = jl == body_id
    return PoseMasks(ink=ink, body=body, lines=pose_lines, origin=(x0, y0))


def find_holes(pm: PoseMasks, min_area: int = SPECK_AREA) -> list[Hole]:
    """Régions de papier entièrement entourées d'encre (yeux, K, accessoires)."""
    # Les traits de séparation comptent comme des cloisons : un œil à demi
    # caché par une main reste un trou fermé.
    wall = pm.ink | pm.lines
    holes = ndi.binary_fill_holes(wall) & ~wall
    lab, n = ndi.label(holes)
    out = []
    for j in range(1, n + 1):
        m = lab == j
        area = int(m.sum())
        if area < min_area:
            continue
        ys, xs = np.nonzero(m)
        pts = np.stack([xs, ys], axis=1).astype(np.int32)
        hull = cv2.convexHull(pts)
        hull_area = max(1.0, cv2.contourArea(hull))
        out.append(Hole(m, area, float(ys.mean()), float(xs.mean()),
                        (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1),
                        float(area / hull_area)))
    return out


def _touches_only(mask_hole: np.ndarray, region: np.ndarray) -> bool:
    ring = cv2.dilate(mask_hole.astype(np.uint8), np.ones((3, 3), np.uint8)).astype(bool) & ~mask_hole
    return bool(ring.any()) and float(region[ring].mean()) > 0.95


def find_eyes(pm: PoseMasks, holes: list[Hole]) -> list[Hole]:
    """Les deux yeux : paire de trous de la silhouette, dans la tête.

    Candidats : trous entourés d'encre (ou de traits de séparation), d'aire
    comparable à un œil, dans la moitié haute du corps ; un accessoire
    (pastille, engrenage) est écarté par le critère de paire.
    Paire retenue : même hauteur, aires voisines, écart horizontal plausible.
    """
    ys, xs = np.nonzero(pm.body)
    top, bottom = ys.min(), ys.max()
    bh = bottom - top + 1
    s2 = (bh / 950.0) ** 2
    cands = [h for h in holes
             if 1500 * s2 <= h.area <= 20000 * s2
             and 0.30 <= (h.cy - top) / bh <= 0.66
             and _touches_only(h.mask, pm.ink | pm.lines)]
    best = None
    for i, a in enumerate(cands):
        for b in cands[i + 1:]:
            dy = abs(a.cy - b.cy) / bh
            dx = abs(a.cx - b.cx) / bh
            if dy > 0.08 or not (0.08 <= dx <= 0.40):
                continue
            score = dy + 0.25 * abs(np.log(a.area / b.area)) + 0.1 * ((a.cy + b.cy) / 2 - top) / bh
            if best is None or score < best[0]:
                best = (score, a, b)
    if best is None:
        return []
    return sorted([best[1], best[2]], key=lambda h: h.cx)


@dataclass
class Measures:
    eye_y: float
    eye_x: float
    interocular: float
    tip_y: float
    tip_x: float
    feet_y: float
    body_top: float


def measure(pm: PoseMasks, eyes: list[Hole]) -> Measures:
    ys, xs = np.nonzero(pm.body)
    bottom = float(ys.max() + 1)
    ex = float(np.mean([e.cx for e in eyes]))
    ey = float(np.mean([e.cy for e in eyes]))
    io = float(abs(eyes[1].cx - eyes[0].cx))
    # Pointe de la flamme. Une hampe de drapeau ou un bras levé peuvent
    # dépasser la tête : on ouvre la silhouette (structures de moins de 0,6
    # écart des yeux retirées, ce qui détache hampes et bras fins), on garde
    # la composante qui contient la tête (point entre les yeux), on y prend
    # le point le plus haut, puis on l'affine sur la silhouette d'origine à
    # ±0,3 écart de cette position.
    r = max(2, int(round(0.3 * io)))
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * r + 1, 2 * r + 1))
    opened = cv2.morphologyEx(pm.body.astype(np.uint8), cv2.MORPH_OPEN, k)
    _, olab = cv2.connectedComponents(opened, connectivity=8)
    oys, oxs = np.nonzero(olab)
    d2 = (oxs - ex) ** 2 + (oys - ey) ** 2
    head = olab[oys[d2.argmin()], oxs[d2.argmin()]]
    hys, hxs = np.nonzero(olab == head)
    ax = float(hxs[hys == hys.min()].mean())
    fine = (xs >= ax - 0.3 * io) & (xs <= ax + 0.3 * io) & (ys < ey)
    ty = float(ys[fine].min())
    tx = float(xs[fine][ys[fine] == ys[fine].min()].mean())
    return Measures(ey, ex, io, ty, tx, bottom, float(ys.min()))
