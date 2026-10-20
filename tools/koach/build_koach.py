"""Lot GK — vectorisation de Koach (36 poses) et des 10 flammes.

Usage :
    python3 tools/koach/build_koach.py            # génère le Dart + le rapport
    python3 tools/koach/build_koach.py --check    # vérifie que le Dart commité
                                                  # est à jour (aucune écriture)
    python3 tools/koach/build_koach.py --controle # + planches de contrôle PNG

Entrées : tools/koach/sources/ (copie des planches fournies par le
propriétaire, empreintes SHA-256 contrôlées) et tools/koach/poses.json.
Sorties :
  packages/kalis_koach/lib/src/art/koach_pose_art.g.dart
  packages/kalis_koach/lib/src/art/koach_flame_art.g.dart
  packages/kalis_koach/docs/controle/vectorisation.json (+ .md)
  packages/kalis_koach/docs/controle/*.png (avec --controle)

Chaîne : luminance -> encre (seuil 128) -> nettoyage des liserés fins ->
découpe par composantes connexes -> yeux, pointe de la flamme, pieds ->
normalisation (même hauteur de corps, pieds sur la même ligne) -> potrace ->
calques encre / papier / yeux -> commandes entières -> Dart.
Les planches de contrôle et l'IoU sont calculées en relisant le fichier Dart
généré, pas les masques.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import segment as seg  # noqa: E402
import vectorize as vec  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCES = HERE / 'sources'
PKG = ROOT / 'packages' / 'kalis_koach'
ART_DIR = PKG / 'lib' / 'src' / 'art'
POSE_DART = ART_DIR / 'koach_pose_art.g.dart'
FLAME_DART = ART_DIR / 'koach_flame_art.g.dart'
INFO_DART = ART_DIR / 'koach_pose_info.g.dart'
CONTROL_DIR = PKG / 'docs' / 'controle'

SOURCE_SHA256 = {
    'koach_planche_A_pedagogie.png': '56441518b5bd437b79fcd58b4b5d39be1d9e2f12c9606dcb5916502471271291',
    'koach_planche_B_emotions.png': 'd892652bc0fb9616ccad2995bfd41910bff0780de3297a0a26ad5133012f9e22',
    'koach_planche_C_energie.png': 'f719731a8d17c2f8bb58f13f24434081231106940dc6f4bd65158caf9bff52f0',
    'flammes_difficulte_1_a_10.png': '971eceb68d86821f7345b9643ff2a782040421d8f8da36c9f49e3802482f74e1',
}

# Hauteur de référence d'une pose en pied (pointe de la flamme -> pieds), en
# unités Koach. 1 000 unités ≈ 1 px de la planche source : les coordonnées
# entières perdent au plus 0,5 px, invisible à l'écran (Koach y mesure au
# plus 300 px).
BODY_HEIGHT = 1000
# Hauteur de la plus grande flamme, en unités.
FLAME_HEIGHT = 1000
# Poussières ignorées par potrace (px² de la planche).
TURDSIZE = 100
# Seuil de solidité (aire / aire de l'enveloppe convexe) d'un œil ouvert :
# un œil ouvert est une amande convexe (≥ 0,84 mesuré), un œil fermé un
# croissant (≤ 0,78 mesuré).
OPEN_EYE_SOLIDITY = 0.80
# Agrandissement des flammes avant le tracé (elles mesurent 70 à 180 px sur
# la planche source) : interpolation bicubique de la luminance.
FLAME_UPSCALE = 4
# Côté de la bulle : si la pose déborde de plus de BUBBLE_CLEARANCE unités
# du côté du regard (accessoire), la bulle passe de l'autre côté.
BUBBLE_CLEARANCE = 520
# Seuil d'asymétrie des yeux pour le regard (vue de trois quarts : l'œil le
# plus éloigné est plus petit).
GAZE_ASYMMETRY = 0.06


def sha256(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def check_sources():
    for name, digest in SOURCE_SHA256.items():
        got = sha256(SOURCES / name)
        if got != digest:
            raise SystemExit(f'Source modifiée : {name} ({got})')


def camel(s: str) -> str:
    parts = s.split('_')
    return parts[0] + ''.join(p[:1].upper() + p[1:] for p in parts[1:])


# ---------------------------------------------------------------- poses

def process_poses(catalog):
    sheets = {s['id']: s for s in catalog['sheets']}
    by_sheet = {}
    for p in catalog['poses']:
        by_sheet.setdefault(p['sheet'], []).append(p)
    results = []
    clean_reports = {}
    for sid, sheet in sheets.items():
        lum = seg.load_luminance(SOURCES / sheet['file'])
        raw = seg.raw_ink(lum)
        clean, lines, rep = seg.clean_ink(lum)
        clean_reports[sid] = rep.__dict__
        lab, cells = seg.split_sheet(clean, sheet['cols'], sheet['rows'], sid)
        cell_at = {(c.row, c.col): c for c in cells}
        if len(cells) != len(by_sheet[sid]):
            raise SystemExit(f'Planche {sid} : {len(cells)} cases, {len(by_sheet[sid])} poses déclarées')
        for pose in by_sheet[sid]:
            cell = cell_at[(pose['row'], pose['col'])]
            pm = seg.crop_pose(clean, lines, lab, cell)
            holes = seg.find_holes(pm)
            eyes = seg.find_eyes(pm, holes)
            if len(eyes) != 2:
                raise SystemExit(f'{pose["id"]} : yeux introuvables')
            m = seg.measure(pm, eyes)
            solid = [e.solidity for e in eyes]
            detected = 'open' if min(solid) >= OPEN_EYE_SOLIDITY else 'closed'
            if max(solid) >= OPEN_EYE_SOLIDITY > min(solid):
                raise SystemExit(f'{pose["id"]} : un œil ouvert, un œil fermé ({solid})')
            if detected != pose['eyes']:
                raise SystemExit(f'{pose["id"]} : yeux {detected} détectés, {pose["eyes"]} déclarés')
            x0, y0 = pm.origin
            raw_crop = raw[y0:y0 + pm.ink.shape[0], x0:x0 + pm.ink.shape[1]]
            # L'encre brute de la pose = encre brute dans l'enveloppe de la
            # pose nettoyée (les autres poses sont loin).
            env = cv2.dilate(pm.ink.astype(np.uint8), np.ones((15, 15), np.uint8)).astype(bool)
            results.append(dict(pose=pose, pm=pm, holes=holes, eyes=eyes, m=m,
                                raw=raw_crop & env, solidity=solid))
    # Échelle : poses en pied -> même hauteur (pointe -> pieds) ; bustes ->
    # même taille de tête (yeux -> pointe) que la médiane des poses en pied.
    head_units = []
    for r in results:
        m = r['m']
        if r['pose']['framing'] == 'full':
            r['scale'] = BODY_HEIGHT / (m.feet_y - m.tip_y)
            head_units.append(r['scale'] * (m.eye_y - m.tip_y))
    head_ref = float(np.median(head_units))
    for r in results:
        m = r['m']
        if r['pose']['framing'] == 'bust':
            r['scale'] = head_ref / (m.eye_y - m.tip_y)
        r['head_units'] = r['scale'] * (m.eye_y - m.tip_y)
    return results, clean_reports, head_ref


def vectorize_pose(r):
    pm, m, s = r['pm'], r['m'], r['scale']
    open_eyes = r['pose']['eyes'] == 'open'
    eye_mask = np.zeros_like(pm.ink)
    if open_eyes:
        for e in r['eyes']:
            eye_mask |= e.mask
    ink_filled = pm.ink | eye_mask
    curves = vec.trace(ink_filled, TURDSIZE)
    depths = vec.nesting_depths(curves)

    def fx(x):
        return (x - m.eye_x) * s

    def fy(y):
        return (y - m.feet_y) * s

    ink_cmd = vec.to_commands(curves, fx, fy)
    # Papier : tout le blanc à l'intérieur de la silhouette (yeux fermés, K,
    # parties blanches des accessoires, traits de séparation), yeux ouverts
    # exclus (calque séparé).
    closed = seg.ndi.binary_fill_holes(pm.ink | eye_mask | pm.lines)
    paper = closed & ~pm.ink & ~eye_mask
    paper_cmd = vec.to_commands(vec.trace(paper, TURDSIZE // 4), fx, fy)
    eye_cmd = []
    eye_boxes = []
    if open_eyes:
        for e in sorted(r['eyes'], key=lambda e: e.cx):
            ec = vec.trace(e.mask, 0)
            cmd = vec.to_commands(ec, fx, fy)
            eye_cmd += cmd
            xs, ys = [], []
            for sub in vec.parse_commands(cmd):
                for x, y in vec.subpath_polygon(sub, float, float):
                    xs.append(x)
                    ys.append(y)
            eye_boxes.append([int(np.floor(min(xs))), int(np.floor(min(ys))),
                              int(np.ceil(max(xs))), int(np.ceil(max(ys)))])
    r['ink_cmd'], r['paper_cmd'], r['eye_cmd'], r['eye_boxes'] = ink_cmd, paper_cmd, eye_cmd, eye_boxes
    r['depth_max'] = max(depths)
    xs, ys = [], []
    for sub in vec.parse_commands(ink_cmd):
        for x, y in vec.subpath_polygon(sub, float, float):
            xs.append(x)
            ys.append(y)
    r['bounds'] = [int(np.floor(min(xs))), int(np.floor(min(ys))), int(np.ceil(max(xs))), int(np.ceil(max(ys)))]
    # Regard : asymétrie des aires des yeux (vue de trois quarts, l'œil le
    # plus éloigné paraît plus petit) ; côté de la bulle : côté du regard sauf
    # si un accessoire l'occupe.
    el, er = sorted(r['eyes'], key=lambda e: e.cx)
    asym = (el.area - er.area) / (el.area + er.area)
    r['eye_asymmetry'] = round(float(asym), 3)
    computed = 'right' if asym > GAZE_ASYMMETRY else 'left' if asym < -GAZE_ASYMMETRY else 'front'
    r['gaze_computed'] = computed
    r['tip_dx_units'] = int(round((m.tip_x - m.eye_x) * s))


def pose_bubble_side(r, gaze):
    left, _, right, _ = r['bounds']
    if gaze == 'right':
        return 'right' if right < BUBBLE_CLEARANCE else 'left'
    if gaze == 'left':
        return 'left' if -left < BUBBLE_CLEARANCE else 'right'
    # De face : le côté le plus dégagé.
    return 'right' if right <= -left else 'left'


# --------------------------------------------------------------- flammes

def process_flames():
    lum = seg.load_luminance(SOURCES / 'flammes_difficulte_1_a_10.png')
    big = cv2.resize(lum, None, fx=FLAME_UPSCALE, fy=FLAME_UPSCALE, interpolation=cv2.INTER_CUBIC)
    ink = big < seg.INK_THRESHOLD
    n, lab, st, cen = cv2.connectedComponentsWithStats(ink.astype(np.uint8), connectivity=8)
    comps = [i for i in range(1, n) if st[i, cv2.CC_STAT_AREA] >= 50 * FLAME_UPSCALE ** 2]
    if len(comps) != 10:
        raise SystemExit(f'{len(comps)} flammes trouvées au lieu de 10')
    comps.sort(key=lambda i: cen[i][0])
    heights = [int(st[i, cv2.CC_STAT_HEIGHT]) for i in comps]
    if heights != sorted(heights):
        raise SystemExit(f'Flammes non croissantes : {heights}')
    s = FLAME_HEIGHT / max(heights)
    flames = []
    for level, i in enumerate(comps, start=1):
        x, y, w, h = (int(v) for v in st[i, :4])
        pad = 6
        crop = lab[y - pad:y + h + pad, x - pad:x + w + pad] == i
        # Creux : papier dans l'enveloppe convexe, composante la plus basse
        # (les deux encoches latérales sont plus haut).
        ys_, xs_ = np.nonzero(crop)
        hull = cv2.convexHull(np.stack([xs_, ys_], 1).astype(np.int32))
        hull_mask = np.zeros(crop.shape, np.uint8)
        cv2.fillPoly(hull_mask, [hull], 1)
        bays = hull_mask.astype(bool) & ~crop
        bl, bn = seg.ndi.label(bays)
        best, best_y = None, -1.0
        for j in range(1, bn + 1):
            yy = np.nonzero(bl == j)[0]
            if len(yy) > 20 * FLAME_UPSCALE ** 2 and yy.mean() > best_y:
                best, best_y = j, yy.mean()
        hollow = bl == best
        outer = crop | hollow
        bottom = float(ys_.max() + 1)
        cx = float(x - pad + (xs_.min() + xs_.max() + 1) / 2.0) - (x - pad)

        def fx(px, cx=cx):
            return (px - cx) * s

        def fy(py, bottom=bottom):
            return (py - bottom) * s

        ink_cmd = vec.to_commands(vec.trace(crop, 4 * FLAME_UPSCALE ** 2), fx, fy)
        outer_cmd = vec.to_commands(vec.trace(outer, 4 * FLAME_UPSCALE ** 2), fx, fy)
        hollow_cmd = vec.to_commands(vec.trace(hollow, 4 * FLAME_UPSCALE ** 2), fx, fy)
        xs, ys = [], []
        for sub in vec.parse_commands(outer_cmd):
            for px, py in vec.subpath_polygon(sub, float, float):
                xs.append(px)
                ys.append(py)
        bounds = [int(np.floor(min(xs))), int(np.floor(min(ys))), int(np.ceil(max(xs))), int(np.ceil(max(ys)))]
        flames.append(dict(level=level, ink=ink_cmd, outer=outer_cmd, hollow=hollow_cmd,
                           bounds=bounds, mask=crop, scale=s, cx=cx, bottom=bottom,
                           source_height_px=round(h / FLAME_UPSCALE, 1),
                           hollow_share=round(float(hollow.sum() / outer.sum()), 3)))
    return flames


# ------------------------------------------------------------- Dart

HEADER = """// GÉNÉRÉ PAR tools/koach/build_koach.py (lot GK) — NE PAS MODIFIER À LA MAIN.
// Sources : tools/koach/sources/ (empreintes SHA-256 dans build_koach.py).
// Format des commandes : voir CONTRAT.md (§ Format des commandes).
// dart format off
"""


def dart_ints(values, indent='    ', per_line=32) -> str:
    lines = []
    for i in range(0, len(values), per_line):
        lines.append(indent + ','.join(str(v) for v in values[i:i + per_line]) + ',')
    return '\n'.join(lines)


def emit_pose_dart(results) -> str:
    out = [HEADER, "import '../koach_art.dart';", '']
    out.append('/// Dessins des 36 poses, dans l’ordre de [KoachPose.values].')
    out.append('const List<KoachPoseArt> koachPoseArts = <KoachPoseArt>[')
    for r in results:
        p = r['pose']
        b = r['bounds']
        out.append('  KoachPoseArt(')
        out.append(f"    id: '{p['id']}',")
        out.append(f'    bounds: KoachBox({b[0]}, {b[1]}, {b[2]}, {b[3]}),')
        out.append('    eyeBoxes: <KoachBox>[' + ', '.join(f'KoachBox({e[0]}, {e[1]}, {e[2]}, {e[3]})' for e in r['eye_boxes']) + '],')
        for name, key in (('ink', 'ink_cmd'), ('paper', 'paper_cmd'), ('eyes', 'eye_cmd')):
            vals = r[key]
            if vals:
                out.append(f'    {name}: <int>[')
                out.append(dart_ints(vals, '      '))
                out.append('    ],')
            else:
                out.append(f'    {name}: <int>[],')
        out.append('  ),')
    out.append('];')
    out.append('// dart format on')
    return '\n'.join(out) + '\n'


def emit_info_dart(results) -> str:
    out = [HEADER, "import '../koach_pose.dart';", '']
    out.append('/// Fiches des 36 poses, dans l’ordre de [KoachPose.values].')
    out.append('const List<KoachPoseInfo> koachPoseInfos = <KoachPoseInfo>[')
    for r in results:
        p = r['pose']
        usages = ', '.join(f'KoachUsage.{u}' for u in p['usages'])
        out.append('  KoachPoseInfo(')
        out.append(f"    id: '{p['id']}',")
        out.append(f"    sheet: '{p['sheet']}',")
        out.append(f"    row: {p['row']},")
        out.append(f"    col: {p['col']},")
        out.append(f"    emotion: KoachEmotion.{p['emotion']},")
        out.append(f'    usages: <KoachUsage>[{usages}],')
        out.append(f"    eyesOpen: {'true' if p['eyes'] == 'open' else 'false'},")
        out.append(f"    framing: KoachFraming.{p['framing']},")
        out.append(f"    gaze: KoachGaze.{r['gaze']},")
        out.append(f"    bubbleSide: KoachSide.{r['bubble']},")
        out.append('  ),')
    out.append('];')
    out.append('// dart format on')
    return '\n'.join(out) + '\n'


def emit_flame_dart(flames) -> str:
    out = [HEADER, "import '../koach_art.dart';", '']
    out.append('/// Dessins des 10 flammes (niveau 1 à 10), tailles relatives conservées.')
    out.append('const List<KoachFlameArt> koachFlameArts = <KoachFlameArt>[')
    for f in flames:
        b = f['bounds']
        out.append('  KoachFlameArt(')
        out.append(f"    level: {f['level']},")
        out.append(f'    bounds: KoachBox({b[0]}, {b[1]}, {b[2]}, {b[3]}),')
        for name, key in (('ink', 'ink'), ('outline', 'outer'), ('hollow', 'hollow')):
            out.append(f'    {name}: <int>[')
            out.append(dart_ints(f[key], '      '))
            out.append('    ],')
        out.append('  ),')
    out.append('];')
    out.append('// dart format on')
    return '\n'.join(out) + '\n'


# ------------------------------------------------------- relecture Dart

def parse_dart_lists(text: str, kind: str):
    """Relit le fichier Dart généré : liste de dict {champ: valeurs}."""
    blocks = re.split(rf'\n  {kind}\(\n', text)[1:]
    items = []
    for blk in blocks:
        item = {}
        m = re.search(r"id: '([a-z0-9_]+)'", blk)
        if m:
            item['id'] = m.group(1)
        m = re.search(r'level: (\d+)', blk)
        if m:
            item['level'] = int(m.group(1))
        m = re.search(r'bounds: KoachBox\((-?\d+), (-?\d+), (-?\d+), (-?\d+)\)', blk)
        item['bounds'] = [int(v) for v in m.groups()]
        for field in ('ink', 'paper', 'eyes', 'outline', 'hollow'):
            m = re.search(rf'\n    {field}: <int>\[(.*?)\]', blk, re.S)
            if m:
                body = m.group(1).strip()
                item[field] = [int(v) for v in re.findall(r'-?\d+', body)]
        items.append(item)
    return items


# ------------------------------------------------------------ contrôle

def pose_iou(r, art):
    """IoU entre le rendu des commandes relues et le masque de la pose, en
    pixels de la planche source (couverture anticrénelée 4×4)."""
    m, s = r['m'], r['scale']
    h, w = r['pm'].ink.shape

    def tx(u):
        return u / s + m.eye_x

    def ty(u):
        return u / s + m.feet_y

    ink = vec.render_evenodd(art['ink'], (w, h), tx, ty)
    if art['eyes']:
        eyes = vec.render_evenodd(art['eyes'], (w, h), tx, ty)
        ink = np.clip(ink - eyes, 0, 1)
    return vec.iou(ink, r['pm'].ink), vec.iou(ink, r['raw'])


def render_pose_tile(art, size, ink_rgb, paper_rgb, bg_rgb, frame, pad=10):
    """Rendu d'une pose dans un cadre commun (unités) -> image RGB."""
    from PIL import Image
    fx0, fy0, fx1, fy1 = frame
    w, h = size
    k = min((w - 2 * pad) / (fx1 - fx0), (h - 2 * pad) / (fy1 - fy0))
    ox = pad + ((w - 2 * pad) - k * (fx1 - fx0)) / 2 - k * fx0
    oy = pad + ((h - 2 * pad) - k * (fy1 - fy0)) / 2 - k * fy0

    def tx(u):
        return u * k + ox

    def ty(u):
        return u * k + oy

    cov_ink = vec.render_evenodd(art['ink'], (w, h), tx, ty)
    cov_paper = vec.render_evenodd(art['paper'], (w, h), tx, ty) if art.get('paper') else np.zeros((h, w))
    cov_eyes = vec.render_evenodd(art['eyes'], (w, h), tx, ty) if art.get('eyes') else np.zeros((h, w))
    img = np.empty((h, w, 3))
    img[:] = bg_rgb
    for cov, col in ((cov_ink, ink_rgb), (cov_paper, paper_rgb), (cov_eyes, paper_rgb)):
        img = img * (1 - cov[..., None]) + np.array(col) * cov[..., None]
    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))


LIGHT = dict(ink=(0x14, 0x14, 0x14), paper=(255, 255, 255), bg=(255, 255, 255))
DARK = dict(ink=(0xF4, 0xF4, 0xF4), paper=(0x12, 0x12, 0x12), bg=(0x12, 0x12, 0x12))


def control_sheets(pose_arts, flame_arts, frame):
    from PIL import Image, ImageDraw
    CONTROL_DIR.mkdir(parents=True, exist_ok=True)
    tile = (300, 330)
    cols = 6
    for theme_name, th in (('clair', LIGHT), ('sombre', DARK)):
        rows = (len(pose_arts) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * tile[0], rows * (tile[1] + 22)), th['bg'])
        d = ImageDraw.Draw(sheet)
        for i, art in enumerate(pose_arts):
            t = render_pose_tile(art, tile, th['ink'], th['paper'], th['bg'], frame)
            x, y = (i % cols) * tile[0], (i // cols) * (tile[1] + 22)
            sheet.paste(t, (x, y))
            d.text((x + 8, y + tile[1] + 4), f"{i + 1:02d} {art['id']}", fill=th['ink'])
        sheet.save(CONTROL_DIR / f'poses_{theme_name}.png', optimize=True)
        # Flammes : cadre commun (tailles relatives conservées).
        fw = 160
        fs = Image.new('RGB', (fw * 10, 220), th['bg'])
        fd = ImageDraw.Draw(fs)
        fframe = (-560, -1040, 560, 40)
        for f in flame_arts:
            art = dict(ink=f['ink'], paper=[], eyes=[])
            t = render_pose_tile(art, (fw, 190), th['ink'], th['paper'], th['bg'], fframe, pad=6)
            fs.paste(t, ((f['level'] - 1) * fw, 0))
            fd.text(((f['level'] - 1) * fw + fw // 2 - 4, 198), str(f['level']), fill=th['ink'])
        fs.save(CONTROL_DIR / f'flammes_{theme_name}.png', optimize=True)
    # Calques des flammes : contour (gris), creux (rouge) sur fond blanc.
    lay = Image.new('RGB', (160 * 10, 200), (255, 255, 255))
    for f in flame_arts:
        art_o = dict(ink=f['outline'], paper=[], eyes=[])
        art_h = dict(ink=f['hollow'], paper=[], eyes=[])
        t1 = render_pose_tile(art_o, (160, 200), (150, 150, 150), (255, 255, 255), (255, 255, 255), (-560, -1040, 560, 40), 6)
        a1 = np.asarray(t1).astype(float)
        t2 = render_pose_tile(art_h, (160, 200), (200, 30, 30), (255, 255, 255), (255, 255, 255), (-560, -1040, 560, 40), 6)
        a2 = np.asarray(t2).astype(float)
        comb = np.minimum(a1, a2)
        lay.paste(Image.fromarray(comb.astype(np.uint8)), ((f['level'] - 1) * 160, 0))
    lay.save(CONTROL_DIR / 'flammes_calques.png', optimize=True)
    # Gros plans : mains, yeux, K de quelques poses, à grande échelle, dans
    # les deux thèmes, avec le calque des yeux en couleur pour le repérer.
    zooms = [
        ('wave', (-420, -620, -40, -220)), ('thumbs_up', (-420, -560, -20, -160)),
        ('clap', (-300, -520, 160, -60)), ('ponder', (-200, -540, 260, -80)),
        ('checklist', (-240, -440, 220, 20)), ('love', (-260, -480, 260, -40)),
        ('explain_board', (-260, -620, 140, -300)), ('you', (-300, -640, 240, -260)),
        ('please', (-260, -660, 240, -200)),
    ]
    by_id = {a['id']: a for a in pose_arts}
    zw = 360
    for theme_name, th in (('clair', LIGHT), ('sombre', DARK)):
        z = Image.new('RGB', (zw * 3, (zw + 22) * 3), th['bg'])
        zd = ImageDraw.Draw(z)
        for i, (pid, box) in enumerate(zooms):
            art = by_id[pid]
            eye_col = (220, 60, 40) if theme_name == 'clair' else (255, 120, 90)
            t = render_pose_tile(art, (zw, zw), th['ink'], th['paper'], th['bg'], box, pad=0)
            if art['eyes']:
                te = render_pose_tile(dict(ink=art['eyes'], paper=[], eyes=[]), (zw, zw), eye_col, th['bg'], th['bg'], box, pad=0)
                ta, tb = np.asarray(t).astype(float), np.asarray(te).astype(float)
                mask = (np.abs(tb - np.array(th['bg'])).sum(-1) > 30)[..., None]
                t = Image.fromarray(np.where(mask, tb * 0.5 + ta * 0.5, ta).astype(np.uint8))
            x, y = (i % 3) * zw, (i // 3) * (zw + 22)
            z.paste(t, (x, y))
            zd.text((x + 6, y + zw + 4), f'{pid} (gros plan)', fill=th['ink'])
        z.save(CONTROL_DIR / f'gros_plans_{theme_name}.png', optimize=True)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='vérifie que le Dart est à jour')
    ap.add_argument('--controle', action='store_true', help='rend aussi les planches de contrôle')
    args = ap.parse_args(argv)
    check_sources()
    catalog = json.loads((HERE / 'poses.json').read_text(encoding='utf-8'))
    results, clean_reports, head_ref = process_poses(catalog)
    for r in results:
        vectorize_pose(r)
        gaze = r['pose'].get('gaze', r['gaze_computed'])
        r['gaze'] = gaze
        r['bubble'] = r['pose'].get('bubble', pose_bubble_side(r, gaze))
    flames = process_flames()
    pose_text = emit_pose_dart(results)
    flame_text = emit_flame_dart(flames)
    info_text = emit_info_dart(results)
    if args.check:
        ok = (POSE_DART.read_text(encoding='utf-8') == pose_text
              and FLAME_DART.read_text(encoding='utf-8') == flame_text
              and INFO_DART.read_text(encoding='utf-8') == info_text)
        print('Dart à jour' if ok else 'Dart PÉRIMÉ : relancer build_koach.py')
        return 0 if ok else 1
    ART_DIR.mkdir(parents=True, exist_ok=True)
    POSE_DART.write_text(pose_text, encoding='utf-8')
    FLAME_DART.write_text(flame_text, encoding='utf-8')
    INFO_DART.write_text(info_text, encoding='utf-8')
    # Relecture du Dart écrit : tout ce qui suit part des commandes générées.
    pose_arts = parse_dart_lists(POSE_DART.read_text(encoding='utf-8'), 'KoachPoseArt')
    flame_arts = parse_dart_lists(FLAME_DART.read_text(encoding='utf-8'), 'KoachFlameArt')
    rows = []
    for r, art in zip(results, pose_arts):
        assert art['id'] == r['pose']['id']
        iou_clean, iou_raw = pose_iou(r, art)
        m = r['m']
        rows.append(dict(
            id=r['pose']['id'], sheet=r['pose']['sheet'], cell=[r['pose']['row'], r['pose']['col']],
            iou=round(iou_clean, 4), iou_raw=round(iou_raw, 4),
            eyes=r['pose']['eyes'], eye_solidity=[round(v, 2) for v in r['solidity']],
            gaze=r['gaze'], gaze_computed=r['gaze_computed'], eye_asymmetry=r['eye_asymmetry'],
            bubble=r['bubble'], framing=r['pose']['framing'],
            scale=round(r['scale'], 4), head_units=round(r['head_units'], 1),
            source_body_px=round(m.feet_y - m.tip_y, 1), tip_dx_units=r['tip_dx_units'],
            bounds=art['bounds'], ink_ints=len(art['ink']), paper_ints=len(art['paper']),
            eye_ints=len(art['eyes']), holes=len(r['holes']), depth_max=r['depth_max']))
    flame_rows = []
    for f, art in zip(flames, flame_arts):
        s = f['scale']
        h, w = f['mask'].shape
        cov = vec.render_evenodd(art['ink'], (w, h), lambda u, f=f: u / s + f['cx'], lambda u, f=f: u / s + f['bottom'])
        flame_rows.append(dict(level=f['level'], iou=round(vec.iou(cov, f['mask']), 4),
                               bounds=art['bounds'], source_height_px=f['source_height_px'],
                               hollow_share=f['hollow_share'],
                               ints=len(art['ink']) + len(art['outline']) + len(art['hollow'])))
    frame = [min(r['bounds'][0] for r in rows) - 40, min(r['bounds'][1] for r in rows) - 40,
             max(r['bounds'][2] for r in rows) + 40, max(r['bounds'][3] for r in rows) + 40]
    report = dict(
        schema=1, lot='GK', body_height_units=BODY_HEIGHT, head_ref_units=round(head_ref, 1),
        frame=frame, clean=clean_reports,
        sizes=dict(pose_dart_bytes=len(pose_text.encode()), flame_dart_bytes=len(flame_text.encode()),
                   info_dart_bytes=len(info_text.encode())),
        iou_min=min(r['iou'] for r in rows), iou_raw_min=min(r['iou_raw'] for r in rows),
        flame_iou_min=min(f['iou'] for f in flame_rows),
        poses=rows, flames=flame_rows)
    CONTROL_DIR.mkdir(parents=True, exist_ok=True)
    (CONTROL_DIR / 'vectorisation.json').write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    (CONTROL_DIR / 'vectorisation.md').write_text(report_md(report), encoding='utf-8')
    if args.controle:
        control_sheets(pose_arts, flame_arts, frame)
    print(f"IoU min {report['iou_min']} (brut {report['iou_raw_min']}), flammes {report['flame_iou_min']}, "
          f"Dart {sum(report['sizes'].values())} octets")
    return 0


def report_md(rep) -> str:
    L = ['# Vectorisation de Koach — contrôle (lot GK)', '',
         'Généré par `tools/koach/build_koach.py`. IoU = intersection / union entre le rendu des',
         'commandes **relues dans le fichier Dart généré** (couverture anticrénelée 4×4) et la silhouette',
         'source nettoyée (« IoU »), ou l’encre brute seuillée sans nettoyage (« IoU brut » : les traits',
         'de séparation, épaissis et régularisés, y comptent comme écart), en pixels de la planche d’origine.',
         'Exigence du lot : IoU ≥ 0,97 par pose.', '',
         f"- Hauteur d’une pose en pied : {rep['body_height_units']} unités (pointe de la flamme → pieds).",
         f"- Tête de référence des bustes : {rep['head_ref_units']} unités (médiane des poses en pied).",
         f"- Cadre commun (unités, marge 40) : {rep['frame']}.",
         f"- Poids du Dart généré : poses {rep['sizes']['pose_dart_bytes']} o, flammes {rep['sizes']['flame_dart_bytes']} o, "
         f"fiches {rep['sizes']['info_dart_bytes']} o (total {sum(rep['sizes'].values())} o ; plafond 400 000 o).",
         f"- Nettoyage : {json.dumps(rep['clean'], ensure_ascii=False)}.", '',
         '| # | Pose | Planche | IoU | IoU brut | Yeux (solidité) | Regard (calculé) | Bulle | Cadrage | Tête (u) | Entiers encre/papier/yeux |',
         '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |']
    for i, r in enumerate(rep['poses'], 1):
        L.append(f"| {i} | `{r['id']}` | {r['sheet']} {r['cell'][0] + 1}.{r['cell'][1] + 1} | {r['iou']:.4f} | {r['iou_raw']:.4f} | "
                 f"{r['eyes']} ({r['eye_solidity'][0]}/{r['eye_solidity'][1]}) | {r['gaze']} ({r['gaze_computed']}, {r['eye_asymmetry']}) | "
                 f"{r['bubble']} | {r['framing']} | {r['head_units']} | {r['ink_ints']}/{r['paper_ints']}/{r['eye_ints']} |")
    L += ['', '| Flamme | IoU | Hauteur source (px) | Part du creux | Boîte (unités) |', '| --- | --- | --- | --- | --- |']
    for f in rep['flames']:
        L.append(f"| {f['level']} | {f['iou']:.4f} | {f['source_height_px']} | {f['hollow_share']} | {f['bounds']} |")
    return '\n'.join(L) + '\n'


if __name__ == '__main__':
    sys.exit(main())
