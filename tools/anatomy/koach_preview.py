#!/usr/bin/env python3
"""M7b : aperçu hors application des animations de Koach (contrôle visuel).

Rendu logiciel (numpy + Pillow, sans GPU ni ressource chiffrée) d'un
mannequin de volumes simples posé par le squelette Mixamo : tronc, tête
sombre, membres, mains avec leurs doigts, paume marquée d'un point orange
(orientation lisible), pieds, sol quadrillé (un pied qui glisse se voit).
Sert aux planches de poses clés (2 vues) et aux GIF ; le rendu qui fait
foi reste la capture Flutter GPU de l'application (CI 3D).

  python3 tools/anatomy/koach_preview.py DOSSIER [--id koach_…] [--gif] [--planche]
"""
import argparse
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import koach_rig as kr  # noqa: E402

BODY = (150, 156, 164)
LEFT = (140, 150, 170)      # côté gauche du personnage, très légèrement bleuté
HEAD = (46, 50, 58)
PALM = (240, 140, 40)
BG = (250, 250, 247)
FLOOR = (215, 215, 208)

# (os de départ, os d'arrivée, rayon de départ, rayon d'arrivée, couleur)
# « +X » : point décalé le long de l'os (fraction de la longueur)
SHAPES = [
    ('LeftUpLeg', 'RightUpLeg', .095, .095, BODY),
    ('Hips', 'Spine1', .12, .125, BODY),
    ('Spine1', 'Spine2', .125, .135, BODY),
    ('Spine2', 'Neck', .14, .10, BODY),
    ('LeftArm', 'RightArm', .07, .07, BODY),
    ('Neck', 'Head', .055, .05, BODY),
    ('LeftArm', 'LeftForeArm', .058, .045, LEFT),
    ('LeftForeArm', 'LeftHand', .045, .03, LEFT),
    ('RightArm', 'RightForeArm', .058, .045, BODY),
    ('RightForeArm', 'RightHand', .045, .03, BODY),
    ('LeftUpLeg', 'LeftLeg', .085, .055, LEFT),
    ('LeftLeg', 'LeftFoot', .055, .038, LEFT),
    ('LeftFoot', 'LeftToeBase', .04, .035, LEFT),
    ('LeftToeBase', 'LeftToe_End', .032, .026, LEFT),
    ('RightUpLeg', 'RightLeg', .085, .055, BODY),
    ('RightLeg', 'RightFoot', .055, .038, BODY),
    ('RightFoot', 'RightToeBase', .04, .035, BODY),
    ('RightToeBase', 'RightToe_End', .032, .026, BODY),
]
for _s, _c in (('Left', LEFT), ('Right', BODY)):
    SHAPES.append((_s + 'Hand', _s + 'HandMiddle1', .026, .028, _c))
    SHAPES.append((_s + 'HandIndex1', _s + 'HandPinky1', .016, .016, _c))
    for _f in ('Index', 'Middle', 'Ring', 'Pinky'):
        for _j in (1, 2, 3):
            SHAPES.append((f'{_s}Hand{_f}{_j}', f'{_s}Hand{_f}{_j + 1}', .0095, .0085, _c))
    SHAPES.append((_s + 'Hand', _s + 'HandThumb2', .015, .012, _c))
    for _j in (2, 3):
        SHAPES.append((f'{_s}HandThumb{_j}', f'{_s}HandThumb{_j + 1}', .011, .0095, _c))

VIEWS = {'face': 0.0, 'profil': 90.0, '34': 35.0, 'dos': 180.0, '34d': -35.0}


def camera(yaw_deg):
    np = kr.np_()
    t = math.radians(yaw_deg)
    # caméra qui tourne autour du personnage : 0 = de face (depuis +z)
    to_cam = np.array([math.sin(t), 0.0, math.cos(t)])
    up = np.array([0.0, 1.0, 0.0])
    right = np.cross(-to_cam, up)
    return right, up, to_cam


def render(motion, f, view='face', size=(300, 420), scale=None, center=None):
    """Image (Pillow) de l'image f du mouvement, vue orthographique."""
    import numpy as np
    from PIL import Image
    W, H = size
    R, Pp = motion.globals(f)
    idx = motion.index
    right, up, to_cam = camera(VIEWS.get(view, view) if isinstance(view, str) else view)
    scale = scale or H / 2.3
    cx, cy = center if center is not None else (0.0, .98)
    depth = np.full((H, W), -1e9)
    img = np.zeros((H, W, 3))
    img[:] = BG
    light = np.array([-.45, .6, .66])
    light = light / np.linalg.norm(light)

    def to_px(p):
        return (W / 2 + (p @ right - cx) * scale, H / 2 - (p @ up - cy) * scale, p @ to_cam)

    def sphere(c, r, col):
        u, v, z = to_px(c)
        rp = r * scale
        x0, x1 = int(max(0, math.floor(u - rp))), int(min(W - 1, math.ceil(u + rp)))
        y0, y1 = int(max(0, math.floor(v - rp))), int(min(H - 1, math.ceil(v + rp)))
        if x1 < x0 or y1 < y0:
            return
        ys, xs = np.mgrid[y0:y1 + 1, x0:x1 + 1]
        dx, dy = (xs - u) / rp, (ys - v) / rp
        d2 = dx * dx + dy * dy
        m = d2 <= 1
        if not m.any():
            return
        dz = np.sqrt(np.clip(1 - d2, 0, 1))
        zz = z + dz * r
        sub = depth[y0:y1 + 1, x0:x1 + 1]
        win = m & (zz > sub)
        if not win.any():
            return
        # normale dans l'espace caméra (x à droite, y en haut, z vers la caméra)
        nx, ny, nz = dx, -dy, dz
        lam = np.clip(nx * light[0] + ny * light[1] + nz * light[2], 0, 1)
        shade = .42 + .58 * lam
        rim = .12 * (1 - dz) ** 3
        c3 = np.array(col, dtype=float)
        pix = c3[None, None, :] * shade[..., None] + 255 * rim[..., None]
        sub[win] = zz[win]
        img[y0:y1 + 1, x0:x1 + 1][win] = np.clip(pix[win], 0, 255)

    def capsule(a, b, ra, rb, col):
        L = float(np.linalg.norm(b - a))
        n = max(2, int(L / (min(ra, rb) * .45)) + 1)
        for k in range(n):
            t = k / (n - 1)
            sphere(a + (b - a) * t, ra + (rb - ra) * t, col)

    # sol quadrillé (y = 0) : lignes tous les 10 cm, vues de biais
    floor_pts = []
    for gx in np.arange(-.5, .51, .1):
        floor_pts.append((np.array([gx, 0, -.5]), np.array([gx, 0, .5])))
    for gz in np.arange(-.5, .51, .1):
        floor_pts.append((np.array([-.5, 0, gz]), np.array([.5, 0, gz])))
    for a, b in floor_pts:
        ua, va, _ = to_px(a)
        ub, vb, _ = to_px(b)
        for t in np.linspace(0, 1, 120):
            x, y = int(ua + (ub - ua) * t), int(va + (vb - va) * t)
            if 0 <= x < W and 0 <= y < H:
                img[y, x] = FLOOR
    for a, b, ra, rb, col in SHAPES:
        capsule(Pp[idx[a]], Pp[idx[b]], ra, rb, col)
    # tête : lisse et sombre (ovoïde), légèrement en avant de l'os
    hd = idx['Head']
    Rh = R[hd]
    c = Pp[hd] + Rh @ np.array([0, .1, .025])
    sphere(c, .105, HEAD)
    sphere(Pp[hd] + Rh @ np.array([0, .045, .05]), .07, HEAD)
    # nez discret (orientation de la tête)
    sphere(Pp[hd] + Rh @ np.array([0, .085, .115]), .016, (80, 86, 96))
    # deltoïdes et fessiers
    for s in ('Left', 'Right'):
        sphere(Pp[idx[s + 'Arm']] + R[idx[s + 'Arm']] @ np.array([0, .01, 0]), .066,
               LEFT if s == 'Left' else BODY)
        sphere(Pp[idx[s + 'UpLeg']] + R[idx['Hips']] @ np.array([0, .02, -.06]), .085,
               LEFT if s == 'Left' else BODY)
        # paume : point orange du côté paume (axe z de l'os de la main)
        h = idx[s + 'Hand']
        m1 = Pp[idx[s + 'HandMiddle1']]
        palm_c = (Pp[h] + m1) / 2
        A = kr.skeleton().axes[s + 'Hand']
        nrm = R[h] @ A[:, 2]
        sphere(palm_c + nrm * .024, .011, PALM)
        # poing fermé : volume des doigts repliés (lecture du poing, comme le
        # maillage réel), dès que les phalanges moyennes reviennent sous la paume
        mids = [Pp[idx[f'{s}Hand{f}2']] for f in ('Middle', 'Ring', 'Pinky')]
        tips = [Pp[idx[f'{s}Hand{f}4']] for f in ('Middle', 'Ring', 'Pinky')]
        curl = float(np.mean([np.linalg.norm(t - m1) for t in tips]))
        if curl < .05:
            c = (sum(mids) / 3 + sum(tips) / 3) / 2
            sphere(c, .026, LEFT if s == 'Left' else BODY)
    return Image.fromarray(img.astype('uint8'))


def closeup(motion, f, side='r_', views=(0, 90, -90, 180), cell=(220, 220), zoom=1300):
    """Gros plan de la main (plusieurs vues) : lecture des doigts."""
    from PIL import Image
    import numpy as np
    _, Pp = motion.globals(f)
    s = 'Left' if side == 'l_' else 'Right'
    c = (Pp[motion.index[s + 'Hand']] + Pp[motion.index[s + 'HandMiddle2']]) / 2
    row = Image.new('RGB', (cell[0] * len(views), cell[1]), BG)
    for i, v in enumerate(views):
        right, up, _ = camera(v)
        im = render(motion, f, v, size=cell, scale=zoom, center=(c @ right, c @ up))
        label(im, f'{v}°')
        row.paste(im, (i * cell[0], 0))
    return row


def label(im, text):
    from PIL import ImageDraw
    d = ImageDraw.Draw(im)
    d.text((6, 4), text, fill=(40, 40, 40))
    return im


def key_times(anim):
    ts = sorted({round(t, 3) for t, _, _ in anim.poses()})
    return [t for t in ts if t <= anim.duree + 1e-6]


def sheet(anim, motion, out, views=('face', 'profil'), cell=(230, 320), times=None, max_cols=8):
    """Planche des poses clés sous plusieurs vues (une colonne par clé)."""
    from PIL import Image
    times = times or key_times(anim)
    if len(times) > max_cols:
        # poses les plus éloignées de l'attente et bien réparties
        import numpy as np
        step = (len(times) - 1) / (max_cols - 1)
        times = [times[int(round(i * step))] for i in range(max_cols)]
    W, H = cell
    board = Image.new('RGB', (W * len(times), H * len(views) + 18), BG)
    for j, t in enumerate(times):
        f = min(motion.frames - 1, int(round(t * kr.FPS)))
        for i, v in enumerate(views):
            im = render(motion, f, v, size=cell)
            label(im, f'{t:.2f} s · {v}')
            board.paste(im, (j * W, i * H + 18))
    from PIL import ImageDraw
    ImageDraw.Draw(board).text((6, 3), f'{anim.id} — {anim.nom}', fill=(0, 0, 0))
    board.save(out)
    return out


def strip(anim, motion, out, view='face', dt=.1, cols=12, cell=(120, 170)):
    """Bande chronologique (une image tous les `dt` s) : rythme, poses
    tenues, anticipation et dépassement se lisent d'un coup d'œil."""
    from PIL import Image
    n = int(round(anim.duree / dt)) + 1
    rows = (n + cols - 1) // cols
    board = Image.new('RGB', (cell[0] * cols, cell[1] * rows + 16), BG)
    from PIL import ImageDraw
    ImageDraw.Draw(board).text((4, 2), f'{anim.id} — {view}, une image tous les {dt:g} s',
                               fill=(0, 0, 0))
    for k in range(n):
        f = min(motion.frames - 1, int(round(k * dt * kr.FPS)))
        im = render(motion, f, view, size=cell)
        label(im, f'{k * dt:.1f}')
        board.paste(im, ((k % cols) * cell[0], (k // cols) * cell[1] + 16))
    board.save(out)
    return out


def gif(anim, motion, out, views=('face', '34'), cell=(240, 330), fps=15):
    from PIL import Image
    frames = []
    step = max(1, int(round(kr.FPS / fps)))
    for f in range(0, motion.frames, step):
        row = Image.new('RGB', (cell[0] * len(views), cell[1]), BG)
        for i, v in enumerate(views):
            row.paste(render(motion, f, v, size=cell), (i * cell[0], 0))
        label(row, f'{anim.id} {f / kr.FPS:.2f} s')
        frames.append(row.convert('P', palette=Image.ADAPTIVE, colors=64))
    frames[0].save(out, save_all=True, append_images=frames[1:], duration=int(1000 / fps),
                   loop=0, optimize=True)
    return out


def main():
    import koach_animations as ka
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('dossier')
    parser.add_argument('--id', action='append')
    parser.add_argument('--gif', action='store_true')
    parser.add_argument('--planche', action='store_true')
    parser.add_argument('--bande', action='store_true')
    parser.add_argument('--vues', default='face,profil')
    args = parser.parse_args()
    out = Path(args.dossier)
    out.mkdir(parents=True, exist_ok=True)
    for anim in ka.all_anims():
        if args.id and anim.id not in args.id:
            continue
        m = anim.motion()
        if args.planche or not args.gif:
            sheet(anim, m, out / f'{anim.id}_planche.png', views=tuple(args.vues.split(',')))
        if args.gif:
            gif(anim, m, out / f'{anim.id}.gif')
        if args.bande:
            for v in args.vues.split(','):
                strip(anim, m, out / f'{anim.id}_bande_{v}.png', view=v)
        print(anim.id, 'ok')


if __name__ == '__main__':
    main()
