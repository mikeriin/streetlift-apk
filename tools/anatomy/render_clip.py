#!/usr/bin/env python3
"""M6 (mannequin 3D) : planches de contrôle des animations (Blender, Cycles CPU).

  python3 tools/anatomy/render_clip.py <id> dossier_sortie [--images 0,3,6]
      [--vues 90,45] [--taille 260] [--opacite 0.5]

Recalcule l'animation (`animate.py`, mêmes postures que le clip), puis rend
les images clés demandées (par défaut : les positions clés et le milieu de
chaque mouvement) sous la vue par défaut de l'exercice et en 3/4, avec le
matériel à sa place. Une planche PNG : une ligne par vue, une colonne par
image clé (`<dossier>/<id>.png`). Le rendu qui fait foi reste la capture
Flutter GPU sur émulateur (CI 3D).
"""
import argparse
import json
import math
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import animate  # noqa: E402
import build_rig  # noqa: E402
import render_poses as rp  # noqa: E402

VIEW_YAW = {'face': 0, 'dos': 180, 'profil': 90, 'troisQuarts': 45}
EQUIP_GLB = ROOT / 'assets/anatomy/equipment.glb'
MAP = ROOT / 'assets/anatomy/muscles_map.json'


def equipment_meshes():
    gltf, blob = build_rig.read_glb(EQUIP_GLB)
    out = {}
    for n in gltf['nodes']:
        prim = gltf['meshes'][n['mesh']]['primitives'][0]
        item = n['name'][3:].split('__')[0]
        out.setdefault(item, []).append((
            n['name'], build_rig.accessor_array(gltf, blob, prim['attributes']['POSITION']),
            build_rig.accessor_array(gltf, blob, prim['indices']),
            gltf['materials'][prim['material']]['name']))
    return out


def render_frame(model, out, pose, fiche, lo, hi, views, size, opacity, hot):
    import bpy
    regions = {r['id']: r for r in json.loads(MAP.read_text())['regions']}
    sc = rp.setup_scene(size, ratio=1.25)
    m_muscle = rp.material('muscle', rp.srgb('#8F8B8A'), opacity)
    m_bone = rp.material('os', rp.srgb('#4A4646'))
    m_dark = rp.material('sombre', rp.srgb('#2B2828'))
    m_hot = rp.material('chaud', rp.srgb('#E85959'), opacity, .25)
    pts = model.skin(pose['g'])
    start = 0
    for k, mesh in enumerate(model.m['meshes']):
        n = len(mesh['positions'])
        name = mesh['nom']
        r = regions.get(name)
        mat = (m_hot if name in hot else m_bone if name == 'os'
               else m_muscle if r and r['couche'] != 'volume' else m_dark)
        rp.add_mesh(name, pts[start:start + n], mesh['indices'], mat)
        start += n
    eq = equipment_meshes()
    tints = {t: rp.material('eq_' + t, rp.srgb(c)) for t, c in
             json.loads((ROOT / 'assets/anatomy/equipment.json').read_text())['teintes'].items()}
    tints['sol'] = rp.material('eq_sol2', rp.srgb('#242020'))
    for item in fiche.placed.values():
        pos = item.world_position(model, pose['g'])
        for name, p, idx, tint in eq[item.id]:
            rp.add_mesh(name, p @ item.R.T + pos, idx, tints[tint])
    centre = (lo + hi) / 2
    scale = max(hi[1] - lo[1], math.hypot(hi[0] - lo[0], hi[2] - lo[2])) * 1.08
    rp.render_views(sc, Path(out), centre, scale, views)
    bpy.ops.wm.read_factory_settings(use_empty=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('id')
    parser.add_argument('sortie')
    parser.add_argument('--images', default='')
    parser.add_argument('--vues', default='')
    parser.add_argument('--taille', type=int, default=240)
    parser.add_argument('--opacite', type=float, default=.5)
    parser.add_argument('--gif', type=float, default=0.0,
                        help='M56 : GIF d\'une boucle, N images par seconde du tempo réel')
    args = parser.parse_args()
    from PIL import Image
    model = animate.Model()
    res = animate.run(args.id, model)
    fiche, poses = res['fiche'], res['poses']
    if args.images:
        frames = [int(v) for v in args.images.split(',')]
    else:
        n = len(poses)
        frames = sorted({0, n // 2, n - 1})
    views = ([int(v) for v in args.vues.split(',')] if args.vues
             else [VIEW_YAW[res['clip']['vue']], 45])
    lo, hi = animate.framing(model, fiche, poses)
    regions = json.loads(MAP.read_text())['regions']
    details = animate.load_fiche(args.id)
    import gzip
    pack = json.loads(gzip.decompress(animate.DETAILS.read_bytes()))['exercices'][args.id]
    hot = {r['id'] for r in regions if set(r['pack']) & set(pack['muscles_primaires'])}
    del details
    out = Path(args.sortie)
    out.mkdir(parents=True, exist_ok=True)
    if args.gif:
        # Boucle au tempo réel : une image toutes les 1/N s, posture affichée
        # par l'application (interpolation sphérique entre deux images de la
        # chronologie), première vue seulement.
        timeline, duration = res['timeline'], res['clip']['duree']
        gif_frames = []
        t = 0.0
        k = 0
        while t < duration - 1e-9:
            i = max(j for j in range(len(timeline)) if timeline[j][0] <= t + 1e-9)
            if i + 1 < len(timeline) and timeline[i + 1][0] > timeline[i][0]:
                (t0, a), (t1, b) = timeline[i], timeline[i + 1]
                u = (t - t0) / (t1 - t0)
                pose = animate.interpolate(model, poses[a], poses[b], u) if a != b else poses[a]
            else:
                pose = poses[timeline[i][1]]
            path = out / f'{args.id}_gif{k}.png'
            render_frame(model, path, pose, fiche, lo, hi, views[:1], args.taille, args.opacite, hot)
            gif_frames.append(Image.open(path).convert('P', palette=Image.ADAPTIVE))
            t += 1 / args.gif
            k += 1
        # Durée par image (liste : Pillow fusionne les images identiques des
        # phases isométriques en additionnant leurs durées) ; planche de la
        # boucle (toutes les images, 8 par ligne) pour la revue.
        gif_frames[0].save(out / f'{args.id}.gif', save_all=True, append_images=gif_frames[1:],
                           duration=[int(1000 / args.gif)] * k, loop=0)
        rgb = [Image.open(out / f'{args.id}_gif{j}.png').convert('RGB') for j in range(k)]
        w, h = rgb[0].size
        cols = 8
        sheet = Image.new('RGB', (w * cols, h * ((k + cols - 1) // cols)))
        for j, img in enumerate(rgb):
            sheet.paste(img, ((j % cols) * w, (j // cols) * h))
        sheet.save(out / f'{args.id}_boucle.png')
        for j in range(k):
            (out / f'{args.id}_gif{j}.png').unlink()
        print('gif', out / f'{args.id}.gif', k, 'images', f'({k / args.gif:.1f} s)')
    cols = []
    for f in frames:
        path = out / f'{args.id}_{f}.png'
        render_frame(model, path, poses[f], fiche, lo, hi, views, args.taille, args.opacite, hot)
        cols.append(Image.open(path))
    w, h = cols[0].width // len(views), cols[0].height
    sheet = Image.new('RGB', (w * len(cols), h * len(views)))
    for c, img in enumerate(cols):
        for r in range(len(views)):
            sheet.paste(img.crop((r * w, 0, (r + 1) * w, h)), (c * w, r * h))
    sheet.save(out / f'{args.id}.png')
    for f in frames:
        (out / f'{args.id}_{f}.png').unlink()
    print('planche', out / f'{args.id}.png', 'images', frames, 'vues', views)


if __name__ == '__main__':
    main()
