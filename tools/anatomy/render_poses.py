#!/usr/bin/env python3
"""M5 (mannequin 3D) : planches de contrôle de la déformation (Blender, Cycles CPU).

Pose le mannequin riggé (`assets/anatomy/mannequin.glb`, `rig.json`) dans
chaque posture de contrôle avec la même peau que l'application (mélange
linéaire de 4 influences, calculé ici en numpy comme le fait le shader
`SkinnedVertex` de flutter_scene), puis rend les vues Face / Dos / Profil /
3/4 avec les couleurs de l'application (muscles gris, os et volumes sombres).

  python3 tools/anatomy/render_poses.py dossier_sortie [--postures a,b]
      [--opacite 0.5] [--taille 300] [--articulations] [--regions id1,id2]

Une planche PNG par posture (`<dossier>/<posture>.png`). Le rendu qui fait foi
reste la capture Flutter GPU sur émulateur (CI 3D).
"""
import argparse
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rig_pose  # noqa: E402

MAP = ROOT / 'assets/anatomy/muscles_map.json'


def srgb(hex_color):
    c = int(hex_color.lstrip('#'), 16)
    out = []
    for s in ((c >> 16) & 255, (c >> 8) & 255, c & 255):
        v = s / 255
        out.append(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4)
    return tuple(out)


def setup_scene(size, dark=True, ratio=1.6):
    import bpy
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 12
    sc.cycles.device = 'CPU'
    sc.cycles.transparent_max_bounces = 64
    sc.cycles.max_bounces = 64
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new('w')
    sc.world = w
    w.use_nodes = True
    bg = srgb('#161414' if dark else '#EDEBEA')
    w.node_tree.nodes['Background'].inputs[0].default_value = (*bg, 1)
    # Lumière principale qui suit la caméra (en haut à gauche), comme dans
    # l'application (`MannequinScene.camera`), plus un faible contre-jour.
    ld = bpy.data.lights.new('cle', 'SUN')
    ld.energy = 3.4
    lo = bpy.data.objects.new('cle', ld)
    sc.collection.objects.link(lo)
    ld = bpy.data.lights.new('contre', 'SUN')
    ld.energy = .8
    lc = bpy.data.objects.new('contre', ld)
    sc.collection.objects.link(lc)
    lc.rotation_euler = tuple(math.radians(a) for a in (60, 0, 160))
    sc.render.resolution_x = size
    sc.render.resolution_y = int(size * ratio)
    return sc


def material(name, rgb, alpha=1.0, emit=0.0):
    import bpy
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*rgb, 1)
    b.inputs['Roughness'].default_value = .78
    b.inputs['Alpha'].default_value = alpha
    if emit:
        b.inputs['Emission Color'].default_value = (*rgb, 1)
        b.inputs['Emission Strength'].default_value = emit
    return m


def add_mesh(name, positions, indices, mat):
    """Maillage Blender depuis des positions glTF (Y haut, +Z avant)."""
    import bpy
    me = bpy.data.meshes.new(name)
    verts = [(float(p[0]), float(-p[2]), float(p[1])) for p in positions]
    tris = [tuple(int(i) for i in indices[k:k + 3]) for k in range(0, len(indices), 3)]
    me.from_pydata(verts, [], tris)
    me.update()
    for poly in me.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def render_views(sc, out, centre, scale, views=(0, 180, 90, 45)):
    """Vues orthographiques autour de `centre` (glTF), assemblées en planche."""
    import bpy
    from mathutils import Vector
    from PIL import Image
    cam = bpy.data.cameras.new('c')
    cam.type = 'ORTHO'
    cam.ortho_scale = scale
    co = bpy.data.objects.new('c', cam)
    sc.collection.objects.link(co)
    sc.camera = co
    c = Vector((centre[0], -centre[2], centre[1]))
    shots = []
    for i, az in enumerate(views):
        a = math.radians(az)
        d = Vector((math.sin(a), -math.cos(a), 0))
        co.location = c + d * 5
        co.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
        fwd = -d
        right = fwd.cross(Vector((0, 0, 1))).normalized()
        light = (fwd + Vector((0, 0, -.9)) + right * .45).normalized()
        sc.objects['cle'].rotation_euler = (light).to_track_quat('-Z', 'Y').to_euler()
        path = out.with_name(f'{out.stem}_{i}.png')
        sc.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        shots.append(Image.open(path).convert('RGB'))
        path.unlink()
    sheet = Image.new('RGB', (sum(s.width for s in shots), shots[0].height))
    x = 0
    for s in shots:
        sheet.paste(s, (x, 0))
        x += s.width
    sheet.save(out)
    bpy.data.objects.remove(co)


def render_posture(model, posture, out, opacity=.5, size=300, joints=False,
                   regions=(), views=(0, 180, 90, 45), centre=None, scale=None):
    import numpy as np
    regions_map = {r['id']: r for r in json.loads(MAP.read_text())['regions']}
    posed, globals_ = rig_pose.pose_model(model, posture)
    allp = np.concatenate([p for p in posed.values()])
    lo, hi = allp.min(0), allp.max(0)
    tall = centre is None and (hi[1] - lo[1]) > 1.3 * max(hi[0] - lo[0], hi[2] - lo[2])
    sc = setup_scene(size, ratio=1.6 if tall else 1.0)
    m_muscle = material('muscle', srgb('#8F8B8A'), opacity)
    m_bone = material('os', srgb('#4A4646'))
    m_dark = material('sombre', srgb('#2B2828'))
    m_hot = material('chaud', srgb('#E85959'), opacity, .25)
    for mesh in model['meshes']:
        name = mesh['nom']
        r = regions_map.get(name)
        if name in regions:
            mat = m_hot
        elif name == 'os':
            mat = m_bone
        elif r and r['couche'] != 'volume':
            mat = m_muscle
        else:
            mat = m_dark
        add_mesh(name, posed[name], mesh['indices'], mat)
    if joints:
        import bpy
        mj = material('art', srgb('#3FA7FF'), 1, 2.0)
        for b in model['rig']['os']:
            g = globals_[b['nom']]
            p = (g[0][3], g[1][3], g[2][3])
            bpy.ops.mesh.primitive_uv_sphere_add(radius=.012, location=(p[0], -p[2], p[1]))
            bpy.context.active_object.data.materials.append(mj)
    if centre is None:
        centre = (lo + hi) / 2
        scale = max(hi[1] - lo[1], hi[0] - lo[0], hi[2] - lo[2]) * 1.06
    render_views(sc, Path(out), centre, scale, views)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sortie')
    parser.add_argument('--postures', default='')
    parser.add_argument('--opacite', type=float, default=.5)
    parser.add_argument('--taille', type=int, default=300)
    parser.add_argument('--articulations', action='store_true')
    parser.add_argument('--regions', default='')
    parser.add_argument('--centre', help='x,y,z (glTF, posture déformée) : vue rapprochée')
    parser.add_argument('--echelle', type=float, default=.5)
    parser.add_argument('--vues', default='0,180,90,45')
    args = parser.parse_args()
    model = rig_pose.load_model()
    names = [p for p in args.postures.split(',') if p] or list(model['rig']['postures'])
    out = Path(args.sortie)
    out.mkdir(parents=True, exist_ok=True)
    for name in names:
        centre = [float(v) for v in args.centre.split(',')] if args.centre else None
        suffix = '_zoom' if centre else ''
        render_posture(model, name, out / f'{name}{suffix}.png', args.opacite, args.taille,
                       args.articulations, {r for r in args.regions.split(',') if r},
                       tuple(int(v) for v in args.vues.split(',')), centre,
                       args.echelle if centre else None)
        print('planche', out / f'{name}.png')


if __name__ == '__main__':
    main()
