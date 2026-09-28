#!/usr/bin/env python3
"""M2 / M4b : aperçu hors application du mannequin d'exécution (Blender, Cycles CPU).

Rend `assets/anatomy/mannequin.glb` sous les vues Face / Dos / Profil / 3/4
avec les couleurs de l'application (gris mat, os et contexte sombres,
groupe allumé dans la rampe historique) et les assemble en une planche PNG.
Sert au contrôle visuel de la fabrication ; le rendu qui fait foi reste la
capture Flutter GPU sur émulateur (CI 3D).

  python3 tools/anatomy/render_preview.py sortie.png [--groupe dos,ischios]
      [--regions id1,id2] [--opacite 0.5] [--clair]
      [--zoom tete|mains|pieds|tronc] [--taille 360]

M4b : `--opacite` rend les muscles translucides (os, tête, mains et pieds
opaques), comme l'application (kMuscleOpacity) ; `--groupe` accepte
plusieurs groupes séparés par des virgules ; `--regions` allume des régions.
"""
import argparse
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GLB = ROOT / 'assets/anatomy/mannequin.glb'
MAP = ROOT / 'assets/anatomy/muscles_map.json'


def srgb(hex_color):
    c = int(hex_color.lstrip('#'), 16)
    out = []
    for s in ((c >> 16) & 255, (c >> 8) & 255, c & 255):
        v = s / 255
        out.append(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4)
    return tuple(out)


def lerp(a, b, t):
    return '#%02X%02X%02X' % tuple(
        round(int(a[i:i + 2], 16) + (int(b[i:i + 2], 16) - int(a[i:i + 2], 16)) * t)
        for i in (1, 3, 5))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sortie')
    parser.add_argument('--groupe', default='')
    parser.add_argument('--regions', default='')
    parser.add_argument('--opacite', type=float, default=1.0)
    parser.add_argument('--clair', action='store_true')
    parser.add_argument('--zoom')
    parser.add_argument('--taille', type=int, default=360)
    parser.add_argument('--glb', help='M56 : autre modèle (avant / après)')
    args = parser.parse_args()

    import bpy
    from mathutils import Vector
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(args.glb or GLB))
    regions = {r['id']: r for r in json.loads(MAP.read_text())['regions']}
    dark = not args.clair
    top = '#E85959' if dark else '#A61717'
    hot = srgb(lerp('#6B0C0C', top, 1.0))
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 16
    sc.cycles.device = 'CPU'
    sc.view_settings.view_transform = 'Standard'
    w = bpy.data.worlds.new('w')
    sc.world = w
    w.use_nodes = True
    bg = srgb('#161414' if dark else '#EDEBEA')
    w.node_tree.nodes['Background'].inputs[0].default_value = (*bg, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
    for name, energy, rot in (('cle', 3.2, (50, 15, -30)), ('contre', 1.6, (60, 0, 160))):
        ld = bpy.data.lights.new(name, 'SUN')
        ld.energy = energy
        lo = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(lo)
        lo.rotation_euler = tuple(math.radians(a) for a in rot)

    sc.cycles.transparent_max_bounces = 64
    sc.cycles.max_bounces = 64

    def mat(name, rgb, emit=0.0, alpha=1.0):
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

    alpha = args.opacite
    m_muscle = mat('muscle', srgb('#8F8B8A'), alpha=alpha)
    m_bone = mat('os', srgb('#4A4646'))
    m_dark = mat('sombre', srgb('#2B2828'))
    m_hot = mat('chaud', hot, .25, alpha=alpha)
    groups = {g for g in args.groupe.split(',') if g}
    lit = {r for r in args.regions.split(',') if r}
    for o in bpy.data.objects:
        if o.type != 'MESH':
            continue
        r = regions.get(o.name)
        if r and r['couche'] != 'volume' and (r['groupe'] in groups or o.name in lit):
            m = m_hot
        elif o.name == 'os':
            m = m_bone
        elif r and r['couche'] != 'volume':
            m = m_muscle
        else:
            m = m_dark
        o.data.materials.clear()
        o.data.materials.append(m)

    zooms = {'tete': ((0, 0, 1.58), .45), 'mains': ((.28, 0, .80), .35),
             'pieds': ((.1, 0, .06), .35), 'tronc': ((0, 0, 1.15), .8), 'abdo': ((0, 0, 1.02), .4),
             'bassin': ((0, 0, .9), .5),
             None: ((0, 0, .86), 1.9)}
    centre, scale = zooms[args.zoom]
    cam = bpy.data.cameras.new('c')
    cam.type = 'ORTHO'
    cam.ortho_scale = scale
    co = bpy.data.objects.new('c', cam)
    sc.collection.objects.link(co)
    sc.camera = co
    tall = args.zoom is None
    sc.render.resolution_x = args.taille if tall else args.taille * 2
    sc.render.resolution_y = int(args.taille * 2.3) if tall else args.taille * 2
    from PIL import Image
    shots = []
    out = Path(args.sortie)
    for i, az in enumerate((0, 180, 90, 45)):
        a = math.radians(az)
        d = Vector((math.sin(a), -math.cos(a), 0))
        co.location = Vector(centre) + d * 4
        co.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
        path = out.with_name(f'{out.stem}_{i}.png')
        sc.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        shots.append(Image.open(path).convert('RGB'))
    sheet = Image.new('RGB', (sum(s.width for s in shots), shots[0].height))
    x = 0
    for s in shots:
        sheet.paste(s, (x, 0))
        x += s.width
    sheet.save(out)
    for i in range(len(shots)):
        out.with_name(f'{out.stem}_{i}.png').unlink()


if __name__ == '__main__':
    main()
