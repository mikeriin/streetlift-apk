#!/usr/bin/env python3
"""M2 / M4b (mannequin 3D) : fabrique le modèle anatomique d'exécution.

Entrée : `tools/anatomy/source/` (copie vérifiée du dépôt
slfresh/fitmitwith-anatomy-atlas, CC BY-SA 4.0).
Sorties :
  - `assets/anatomy/mannequin.glb` (converti en .fsceneb par le build hook de
    flutter_scene) : une maille par muscle et par côté (nœud nommé par l'id de
    la région), les os d'appui (`os`), le contexte sombre (`contexte` : tête
    lisse, tissus de liaison, muscles de contexte), les mains et les pieds
    (volumes sombres simplifiés, sélectionnables comme muscles intrinsèques) ;
  - `assets/anatomy/muscles_map.json` : régions (id, côté, nom français,
    groupe parmi les 11 de l'application, muscles du pack, couche
    superficielle / profonde) ;
  - `tools/anatomy/build_report.json` : mesures (triangles, visibilité,
    régions retirées).

Relançable : `pip install bpy --break-system-packages` puis
`python3 tools/anatomy/build_model.py`. `--check` vérifie seulement la source.
Déterministe à la décimation près (Blender 4.x / 5.x).

M4b : tous les muscles sont gardés (le mannequin est rendu à 50 % d'opacité,
les muscles profonds se voient à travers les autres). La mesure de
visibilité de M2 sert désormais à classer les régions : une région cachée au
repos est « profonde » et plus décimée. Le platysma est remis.
"""
import argparse
import hashlib
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
from anatomy_data import (  # noqa: E402
    APP_GROUPS, FR, GROUP_OF_MODEL, PACK_OF_KEY, SIDE_FR, VOLUME_REGIONS,
)

SOURCE = HERE / 'source'
SOURCE_REPO = 'https://github.com/slfresh/fitmitwith-anatomy-atlas'
SOURCE_COMMIT = '4120ee68b6604b8f2f69105d6de6166fad4734c4'
SOURCE_SHA256 = {
    'full-body-male-mobile.glb':
        'd80bebc4045069b660ca8e7afe599d76d15ccc7d96410b3727c600ef01d24e54',
    'full-body-map.json':
        'd1221ef499558c60b93641456c6594a8e02409a85554677e4ed939da185038c6',
}
OUT_GLB = ROOT / 'assets/anatomy/mannequin.glb'
OUT_MAP = ROOT / 'assets/anatomy/muscles_map.json'
REPORT = HERE / 'build_report.json'

# Budget du mannequin d'exécution (M4b : ≤ 75 000 avec les muscles profonds).
TRIANGLE_BUDGET = 75000
# Cibles de décimation (triangles) : muscles visibles au repos (même rapport
# qu'en M2), os, contexte, volumes.
TARGET_MUSCLES = 40000
# Muscles cachés au repos (vus seulement à travers les autres) : rapport de
# décimation des muscles visibles multiplié par ce facteur, au moins
# DEEP_MIN_TRIANGLES triangles par région.
DEEP_RATIO_FACTOR = 0.85
DEEP_MIN_TRIANGLES = 80
TARGET_BONES = 7000
TARGET_HEAD = 2600
TARGET_HAND = 700
TARGET_FOOT = 700
TARGET_CONTEXT = 3500

# Repères anatomiques du modèle (Blender, mètres, Z vers le haut, -Y avant).
WRIST_Z = 0.855     # extrémité distale du radius et de l'ulna
ARM_X = 0.15        # |x| au-delà duquel on est dans le membre supérieur
ANKLE_Z = 0.085     # dessus du talus : sous ce plan, le pied
HEAD_Z = 1.47       # sous le menton : au-dessus, la tête (centre des pièces)
# Visibilité : rayons orthographiques (pas en mètres) depuis N directions.
RAY_STEP = 0.005
VISIBLE_MIN_RAYS = 40   # une région vue par moins de rayons est cachée


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def check_source():
    for name, expected in SOURCE_SHA256.items():
        actual = sha256(SOURCE / name)
        if actual != expected:
            raise SystemExit(f'Source modifiée : {name} ({actual}).')
    for name in ('ATTRIBUTION.txt', 'LICENSE.txt'):
        if not (SOURCE / name).exists():
            raise SystemExit(f'Fichier de licence manquant : {name}.')
    return True


# ---------------------------------------------------------------- Blender --

def blender_build():  # noqa: C901 (pipeline linéaire, étapes commentées)
    import bpy  # noqa: F401 (charge bmesh et mathutils)
    import bmesh
    from mathutils import Vector
    from mathutils.bvhtree import BVHTree

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / 'full-body-male-mobile.glb'))
    source_map = json.loads((SOURCE / 'full-body-map.json').read_text())
    meta = {m['id']: m for m in source_map['muscles']}
    report = {'source': {'repo': SOURCE_REPO, 'commit': SOURCE_COMMIT,
                         'sha256': SOURCE_SHA256}}

    def tri_count(obj):
        obj.data.calc_loop_triangles()
        return len(obj.data.loop_triangles)

    def apply_world(obj):
        obj.data.transform(obj.matrix_world)
        obj.matrix_world.identity()

    muscles, support = {}, {}
    for obj in list(bpy.data.objects):
        if obj.type != 'MESH':
            bpy.data.objects.remove(obj)
            continue
        apply_world(obj)
        if 'muscleId' in obj.keys():
            obj.name = obj['muscleId']
            muscles[obj['muscleId']] = obj
        elif 'boneId' in obj.keys():
            obj.name = 'src_skeleton'
            support['skeleton'] = obj
        else:
            obj.name = 'src_' + obj['supportId']
            support[obj['supportId']] = obj
    report['source_triangles'] = sum(tri_count(o) for o in bpy.data.objects)

    def new_obj(name, bm):
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        return obj

    def split_parts(obj):
        """Pièces connexes d'un maillage fusionné : [(bmesh, centre, zmin, zmax, nfaces)]."""
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.verts.ensure_lookup_table()
        seen, parts = set(), []
        for v in bm.verts:
            if v.index in seen:
                continue
            stack, comp = [v], []
            seen.add(v.index)
            while stack:
                x = stack.pop()
                comp.append(x)
                for e in x.link_edges:
                    y = e.other_vert(x)
                    if y.index not in seen:
                        seen.add(y.index)
                        stack.append(y)
            faces = {f for x in comp for f in x.link_faces}
            part = bmesh.new()
            vmap = {}
            for x in comp:
                vmap[x] = part.verts.new(x.co)
            for f in faces:
                try:
                    part.faces.new([vmap[x] for x in f.verts])
                except ValueError:
                    pass
            zs = [x.co.z for x in comp]
            centre = sum((x.co for x in comp), Vector()) / len(comp)
            parts.append({'bm': part, 'centre': centre, 'zmin': min(zs),
                          'zmax': max(zs), 'faces': len(faces)})
        bm.free()
        return parts

    def region_of(centre):
        """Tête, main ou pied pour une pièce, sinon None."""
        side = 'left' if centre.x > 0 else 'right'
        if centre.z > HEAD_Z:
            return 'head'
        if abs(centre.x) > ARM_X and centre.z < WRIST_Z:
            return 'hand_' + side
        if centre.z < ANKLE_Z:
            return 'foot_' + side
        return None

    # 1. Aponévrose des obliques écartée de devant le droit de l'abdomen
    #    (comme la page de référence, qui en supprimait les triangles) : les
    #    sommets des obliques situés devant le droit, à la même hauteur (pas de
    #    1 cm), passent derrière sa face profonde, avec un fondu de 15 mm au
    #    bord. La nappe reste continue : ni trou ni bord en dents de scie.
    rows = {}
    for oid in ('rectus_abdominis_left', 'rectus_abdominis_right'):
        for v in muscles[oid].data.vertices:
            k = round(v.co.z * 100)
            w, back = rows.get(k, (0, -1))
            rows[k] = (max(w, abs(v.co.x)), max(back, v.co.y))
    moved = 0
    for oid in ('external_oblique_left', 'external_oblique_right',
                'internal_oblique_left', 'internal_oblique_right'):
        for v in muscles[oid].data.vertices:
            k = round(v.co.z * 100)
            near = [rows[j] for j in (k - 1, k, k + 1) if j in rows]
            if k not in rows or not near:
                continue
            lim = max(r[0] for r in near)
            back = max(r[1] for r in near)
            target = back + .004
            if v.co.y >= target:
                continue
            d = abs(v.co.x) - lim
            if d >= .015:
                continue
            t = 0.0 if d <= 0 else (d / .015) ** 2 * (3 - 2 * d / .015)
            v.co.y += (target - v.co.y) * (1 - t)
            moved += 1
    report['aponeurosis_vertices_moved'] = moved

    # 2. Pièces des supports : squelette, contexte (tête/mains/pieds/cou),
    #    tissus de liaison. Chaque pièce est rangée dans un volume (tête, main,
    #    pied) ou gardée telle quelle (os, contexte sombre).
    volume_pieces = {r: [] for r in VOLUME_REGIONS}
    bone_parts, context_parts = [], []
    for part in split_parts(support['skeleton']):
        region = region_of(part['centre'])
        (volume_pieces[region] if region else bone_parts).append(part)
    platysma = []
    for part in split_parts(support['head_hands_feet']):
        c = part['centre']
        # Platysma : grande nappe cutanée du cou, du menton aux clavicules.
        # Retiré en M2 (il masquait le sterno-cléido-mastoïdien), remis en
        # M4b : translucide, il laisse voir le sterno-cléido-mastoïdien. Une
        # région par côté ; hors de la mesure de visibilité (étape 6), comme
        # en M2, pour ne rien changer au tri des os et du contexte.
        if part['faces'] > 400 and part['zmin'] < 1.42 and part['zmax'] > 1.52:
            side = 'left' if c.x > 0 else 'right'
            platysma.append(new_obj('platysma_' + side, part['bm']))
            continue
        region = region_of(c)
        (volume_pieces[region] if region else context_parts).append(part)
    report['platysma_parts'] = sorted(o.name for o in platysma)
    if len(platysma) != 2 or {o.name for o in platysma} != {'platysma_left', 'platysma_right'}:
        raise SystemExit(f'Platysma : deux nappes attendues, {len(platysma)} trouvées.')
    itb = 0
    for part in split_parts(support['connective_tissue']):
        c = part['centre']
        # Bandelette ilio-tibiale : masquée par défaut sur la page de
        # référence (« Tendons et fascias » désactivé), elle couvre le vaste
        # latéral.
        if part['zmax'] - part['zmin'] > .5 and abs(c.x) > .1:
            itb += 1
            part['bm'].free()
            continue
        region = region_of(c)
        (volume_pieces[region] if region else context_parts).append(part)
    report['iliotibial_parts_removed'] = itb
    for obj in support.values():
        bpy.data.objects.remove(obj)

    # 3. Muscles coupés au poignet et à la cheville : les tendons qui entrent
    #    dans la main ou le pied rejoignent leur volume sombre (comme les
    #    images historiques, où mains et pieds sont des volumes simples).
    cut = {}
    for oid, obj in muscles.items():
        side = 'left' if oid.endswith('_left') else 'right'
        planes = []
        zs = [v.co.z for v in obj.data.vertices]
        group = meta[oid]['group']
        if group == 'Forearms' and min(zs) < WRIST_Z:
            planes.append(('hand_' + side, WRIST_Z))
        if group in ('Lower legs', 'Calves') and min(zs) < ANKLE_Z:
            planes.append(('foot_' + side, ANKLE_Z))
        for region, z in planes:
            # Le morceau versé au volume dépasse de 2 cm la coupe du muscle :
            # le volume recouvre la coupe (pas de jour au poignet).
            below = bmesh.new()
            below.from_mesh(obj.data)
            bmesh.ops.bisect_plane(below, geom=below.verts[:] + below.edges[:] + below.faces[:],
                                   plane_co=(0, 0, z + .02), plane_no=(0, 0, 1),
                                   clear_outer=True)
            volume_pieces[region].append({'bm': below})
            above = bmesh.new()
            above.from_mesh(obj.data)
            bmesh.ops.bisect_plane(above, geom=above.verts[:] + above.edges[:] + above.faces[:],
                                   plane_co=(0, 0, z), plane_no=(0, 0, 1),
                                   clear_inner=True)
            above.to_mesh(obj.data)
            above.free()
            cut[oid] = cut.get(oid, []) + [region]
    report['muscles_cut'] = cut

    # 4. Volumes sombres lisses (tête, mains, pieds) : union des pièces,
    #    remaillage voxel, fermeture morphologique (dilatation puis érosion le
    #    long des normales : orbites, doigts et orteils comblés), lissage,
    #    décimation. Même encombrement que la tête et les extrémités d'origine.
    def smooth_volume(name, pieces, voxel, close, smooth_iter, target, inflate=0.0):
        bm = bmesh.new()
        for p in pieces:
            tmp = bpy.data.meshes.new('tmp')
            p['bm'].to_mesh(tmp)
            p['bm'].free()
            bm.from_mesh(tmp)
            bpy.data.meshes.remove(tmp)
        obj = new_obj(name, bm)
        bpy.context.view_layer.objects.active = obj

        def mod(kind, **kw):
            m = obj.modifiers.new(kind.lower(), kind)
            for k, v in kw.items():
                setattr(m, k, v)
            with bpy.context.temp_override(object=obj, active_object=obj):
                bpy.ops.object.modifier_apply(modifier=m.name)

        mod('REMESH', mode='VOXEL', voxel_size=voxel, use_smooth_shade=True)
        mod('DISPLACE', strength=close, mid_level=0, direction='NORMAL')
        mod('REMESH', mode='VOXEL', voxel_size=voxel, use_smooth_shade=True)
        mod('DISPLACE', strength=inflate - close, mid_level=0, direction='NORMAL')
        mod('CORRECTIVE_SMOOTH', iterations=smooth_iter, factor=.5,
            use_only_smooth=True, use_pin_boundary=False,
            smooth_type='SIMPLE')
        mod('LAPLACIANSMOOTH', iterations=4, lambda_factor=.4,
            use_volume_preserve=True)
        ratio = min(1.0, target / max(1, tri_count(obj)))
        mod('DECIMATE', ratio=ratio, use_collapse_triangulate=True)
        return obj

    volumes = {}
    volumes['head'] = smooth_volume('head', volume_pieces['head'], .006, .010, 12, TARGET_HEAD)
    for side in ('left', 'right'):
        volumes['hand_' + side] = smooth_volume(
            'hand_' + side, volume_pieces['hand_' + side], .005, .013, 10, TARGET_HAND, .004)
        volumes['foot_' + side] = smooth_volume(
            'foot_' + side, volume_pieces['foot_' + side], .005, .010, 10, TARGET_FOOT, .003)

    # 5. Pièces d'os et de contexte en objets séparés (pour la visibilité).
    bone_objs = [new_obj(f'bone_{i:03d}', p['bm']) for i, p in enumerate(bone_parts)]
    context_objs = [new_obj(f'ctx_{i:03d}', p['bm']) for i, p in enumerate(context_parts)]

    # 6. Visibilité : rayons orthographiques depuis 58 directions (sphère de
    #    Fibonacci, sans les directions trop verticales). Une pièce d'os ou de
    #    contexte touchée par moins de VISIBLE_MIN_RAYS rayons est invisible au
    #    repos et retirée. M4b : les muscles sont tous gardés ; un muscle
    #    touché par moins de VISIBLE_MIN_RAYS rayons est « caché au repos »
    #    (couche profonde, décimation plus forte).
    candidates = list(muscles.values()) + list(volumes.values()) + bone_objs + context_objs
    verts, polys, owner = [], [], []
    for idx, obj in enumerate(candidates):
        base = len(verts)
        verts.extend(v.co.copy() for v in obj.data.vertices)
        obj.data.calc_loop_triangles()
        for t in obj.data.loop_triangles:
            polys.append(tuple(base + i for i in t.vertices))
            owner.append(idx)
    tree = BVHTree.FromPolygons(verts, polys)
    lo = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
    hi = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
    centre = (lo + hi) / 2
    radius = (hi - lo).length / 2 + .02
    hits = [0] * len(candidates)
    dirs, n = [], 72
    golden = math.pi * (3 - math.sqrt(5))
    for i in range(n):
        z = 1 - 2 * (i + .5) / n
        r = math.sqrt(1 - z * z)
        if abs(z) > .8:
            continue
        dirs.append(Vector((math.cos(golden * i) * r, math.sin(golden * i) * r, z)))
    for d in dirs:
        u = d.cross(Vector((0, 0, 1)))
        u.normalize()
        w = u.cross(d)
        steps = int(2 * radius / RAY_STEP)
        # Étendue projetée du corps : on ne tire que dans son rectangle.
        pu = [(p - centre).dot(u) for p in (lo, hi, Vector((lo.x, hi.y, lo.z)), Vector((hi.x, lo.y, hi.z)))]
        umax = max(abs(x) for x in pu) + .02
        for j in range(steps):
            b = -radius + j * RAY_STEP
            for i in range(int(2 * umax / RAY_STEP)):
                a = -umax + i * RAY_STEP
                origin = centre + u * a + w * b - d * radius
                loc, _, face, _ = tree.ray_cast(origin, d, 2 * radius)
                if face is not None:
                    hits[owner[face]] += 1
    report['visibility'] = {'directions': len(dirs), 'step_m': RAY_STEP,
                            'min_rays': VISIBLE_MIN_RAYS}
    hidden_muscles, removed_bones, removed_context = [], 0, 0
    region_hits, drop = {}, []
    bone_names = {o.name for o in bone_objs}
    context_names = {o.name for o in context_objs}
    for idx, obj in enumerate(candidates):
        name = obj.name
        visible = hits[idx] >= VISIBLE_MIN_RAYS
        if name in muscles:
            region_hits[name] = hits[idx]
        elif name in bone_names and not visible:
            removed_bones += 1
            drop.append(name)
        elif name in context_names and not visible:
            removed_context += 1
            drop.append(name)
    report['region_hits'] = region_hits
    # Décision symétrique : un muscle est caché des deux côtés seulement si
    # aucun des deux n'est visible (sinon les deux sont visibles).
    for name in muscles:
        side = '_left' if name.endswith('_left') else '_right'
        other = name[:-len(side)] + ('_right' if side == '_left' else '_left')
        best = max(region_hits.get(name, 0), region_hits.get(other, 0))
        if best < VISIBLE_MIN_RAYS:
            hidden_muscles.append(name)
    report['total_rays_hit'] = sum(hits)
    for name in drop:
        bpy.data.objects.remove(bpy.data.objects[name])
    bone_objs = [bpy.data.objects[n] for n in sorted(bone_names) if n in bpy.data.objects]
    context_objs = [bpy.data.objects[n] for n in sorted(context_names) if n in bpy.data.objects]
    report['hidden_muscles'] = sorted(hidden_muscles)
    report['removed_muscles'] = []
    for obj in platysma:
        muscles[obj.name] = obj
        meta[obj.name] = {'id': obj.name, 'key': 'platysma',
                          'side': obj.name.rsplit('_', 1)[1],
                          'group': 'Neck', 'layer': 'superficial'}
    report['removed_bone_parts'] = removed_bones
    report['removed_context_parts'] = removed_context

    # 7. Regroupement : os (une maille), contexte sombre (une maille).
    def join(objs, name):
        if not objs:
            return None
        with bpy.context.temp_override(active_object=objs[0], selected_editable_objects=objs):
            bpy.ops.object.join()
        objs[0].name = name
        objs[0].data.name = name
        return objs[0]

    bones = join(bone_objs, 'os')
    context = join(context_objs, 'contexte')

    # 8. Décimation vers le budget, normales lisses (pas de facette visible).
    def decimate(obj, ratio):
        if ratio >= .999:
            return
        m = obj.modifiers.new('dec', 'DECIMATE')
        m.ratio = ratio
        m.use_collapse_triangulate = True
        with bpy.context.temp_override(object=obj, active_object=obj):
            bpy.ops.object.modifier_apply(modifier=m.name)

    hidden = set(hidden_muscles)
    # Rapport des muscles visibles calculé comme en M2 (sans le platysma ni
    # les muscles cachés) : leur géométrie ne change pas.
    visible_total = sum(tri_count(o) for n, o in muscles.items()
                        if n not in hidden and not n.startswith('platysma_'))
    ratio = min(1.0, TARGET_MUSCLES / visible_total)
    for name, obj in muscles.items():
        # Petites régions épargnées (silhouette), grandes décimées ; muscles
        # cachés au repos plus décimés (vus à travers les autres).
        t = tri_count(obj)
        if name in hidden:
            decimate(obj, min(1.0, max(ratio * DEEP_RATIO_FACTOR, DEEP_MIN_TRIANGLES / t)))
        else:
            decimate(obj, 1.0 if t < 120 else ratio)
    decimate(bones, min(1.0, TARGET_BONES / tri_count(bones)))
    if context is not None:
        decimate(context, min(1.0, TARGET_CONTEXT / tri_count(context)))
    for obj in bpy.data.objects:
        for poly in obj.data.polygons:
            poly.use_smooth = True
        obj.data.validate()

    # 9. Matériaux (surchargés à l'exécution) et export glTF (Y vers le haut,
    #    +Z vers l'avant, comme la source).
    def material(name, rgb):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes['Principled BSDF']
        bsdf.inputs['Base Color'].default_value = (*rgb, 1)
        bsdf.inputs['Roughness'].default_value = .8
        return mat

    m_muscle = material('muscle', (.27, .25, .25))
    m_bone = material('os', (.068, .061, .061))
    m_dark = material('sombre', (.046, .041, .041))
    for obj in bpy.data.objects:
        obj.data.materials.clear()
        if obj.name in muscles:
            obj.data.materials.append(m_muscle)
        elif obj.name == 'os':
            obj.data.materials.append(m_bone)
        else:
            obj.data.materials.append(m_dark)
    counts = {o.name: tri_count(o) for o in bpy.data.objects}
    total = sum(counts.values())
    report['triangles'] = {'total': total, 'muscles': sum(counts[k] for k in muscles),
                           'muscles_caches': sum(counts[k] for k in hidden),
                           'os': counts.get('os', 0), 'contexte': counts.get('contexte', 0),
                           'volumes': {k: counts[k] for k in volumes}}
    report['nodes'] = sorted(counts)
    if total > TRIANGLE_BUDGET:
        raise SystemExit(f'Budget dépassé : {total} triangles.')
    OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(OUT_GLB), export_format='GLB', use_selection=False,
        export_texcoords=False, export_normals=True, export_materials='EXPORT',
        export_yup=True, export_extras=False, export_animations=False,
        export_apply=True)
    return report, meta


def build_map(report, meta):
    """Carte des régions : id, côté, nom, groupe, muscles du pack, couche.

    Couche (M4b) : « profond » pour un muscle profond selon la source
    (Z-Anatomy) ou caché au repos selon la mesure de visibilité ; sinon
    « superficiel » ; « volume » pour les mains et les pieds."""
    regions = []
    hidden = set(report['hidden_muscles'])
    for rid in sorted(list(report['region_hits']) + report['platysma_parts']):
        m = meta[rid]
        regions.append({
            'id': rid,
            'cle': m['key'],
            'cote': m['side'],
            'nom': FR[m['key']],
            'nom_cote': f"{FR[m['key']]} ({SIDE_FR[m['side']]})",
            'groupe': GROUP_OF_MODEL[m['key']],
            'pack': PACK_OF_KEY[m['key']],
            'couche': 'profond' if m['layer'] != 'superficial' or rid in hidden
                      else 'superficiel',
        })
    for rid, (key, side) in VOLUME_REGIONS.items():
        if key is None:
            continue
        regions.append({
            'id': rid, 'cle': key, 'cote': side, 'nom': FR[key],
            'nom_cote': f'{FR[key]} ({SIDE_FR[side]})',
            'groupe': GROUP_OF_MODEL[key], 'pack': PACK_OF_KEY[key],
            'couche': 'volume',
        })
    return {
        'schema': 1,
        'source': {'depot': SOURCE_REPO, 'commit': SOURCE_COMMIT,
                   'sha256': SOURCE_SHA256['full-body-male-mobile.glb'],
                   'licence': 'CC-BY-SA-4.0'},
        'groupes': APP_GROUPS,
        'triangles': report['triangles']['total'],
        'regions': regions,
        # M4b : plus aucune région retirée ; régions cachées au repos (mesure
        # de visibilité de M2), toutes de couche « profond ».
        'retirees': [],
        'caches_au_repos': sorted(hidden),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Vérifier la source seulement')
    args = parser.parse_args()
    check_source()
    if args.check:
        print('Source vérifiée (SHA-256).')
        return
    report, meta = blender_build()
    mapping = build_map(report, meta)
    OUT_MAP.write_text(json.dumps(mapping, ensure_ascii=False, indent=1) + '\n')
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1, default=str) + '\n')
    print(json.dumps(report['triangles'], indent=1))
    print('Cachés au repos :', ', '.join(report['hidden_muscles']))


if __name__ == '__main__':
    main()
