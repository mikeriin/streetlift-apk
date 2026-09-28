#!/usr/bin/env python3
"""M5 (mannequin 3D) : squelette d'animation et peau du mannequin.

Entrées :
  - `assets/anatomy/mannequin.glb` (fabriqué par `build_model.py` ; s'il porte
    déjà une peau, elle est ignorée : le script est relançable sur sa sortie) ;
  - le squelette d'appui du modèle source (`tools/anatomy/source/`), qui donne
    les centres articulaires et les os rigides de chaque segment.
Sorties :
  - `assets/anatomy/mannequin.glb` : mêmes maillages (même organisation de
    mise en évidence qu'en M2 : un nœud par région), plus un squelette de
    30 articulations et une peau (JOINTS_0 / WEIGHTS_0, 4 influences) ;
  - `assets/anatomy/rig.json` : os, parents, têtes, queues, longueurs, axes et
    limites des degrés de liberté (sources), postures de référence ;
  - `assets/anatomy/mannequin_skin.bin` : influences par sommet dans l'ordre
    des sommets du GLB (toucher et cadrage sur le modèle déformé, en Dart) ;
  - `tools/anatomy/rig_report.json` : mesures (poids, contrôles).

Poids de peau : automatiques par distance géodésique dans le volume du corps
(voxels de 5 mm, chemin le plus court à l'intérieur du corps depuis les os
d'appui de chaque segment), puis corrigés : chaque partie du corps n'est
influencée que par les segments qu'elle peut suivre (un bras ne suit pas la
cuisse qu'il touche, une cuisse ne suit pas l'autre), les os du modèle sont
rigides (une pièce = un segment), les volumes de la tête, des mains et des
pieds sont pris dans leurs segments.

Relançable : `pip install bpy --break-system-packages` (Blender 4.x / 5.x ;
numpy, scipy) puis `python3 tools/anatomy/build_rig.py`.
"""
import json
import math
import struct
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import rig_def  # noqa: E402
from rig_def import BONE_NAMES, PARENT, SIDE  # noqa: E402

SOURCE = HERE / 'source'
GLB = ROOT / 'assets/anatomy/mannequin.glb'
MAP = ROOT / 'assets/anatomy/muscles_map.json'
OUT_RIG = ROOT / 'assets/anatomy/rig.json'
OUT_SKIN = ROOT / 'assets/anatomy/mannequin_skin.bin'
REPORT = HERE / 'rig_report.json'


# ------------------------------------------------------------------- GLB --

def read_glb(path):
    """(json, blob) d'un GLB."""
    data = path.read_bytes()
    magic, version, length = struct.unpack('<4sII', data[:12])
    assert magic == b'glTF' and version == 2 and length == len(data)
    jlen, jtype = struct.unpack('<I4s', data[12:20])
    assert jtype == b'JSON'
    gltf = json.loads(data[20:20 + jlen])
    blob = b''
    rest = 20 + jlen
    if rest < len(data):
        blen, btype = struct.unpack('<I4s', data[rest:rest + 8])
        assert btype == b'BIN\x00'
        blob = data[rest + 8:rest + 8 + blen]
    return gltf, blob


def accessor_array(gltf, blob, index):
    """Données d'un accesseur (numpy), sans décalage de vue entrelacée."""
    import numpy as np
    acc = gltf['accessors'][index]
    view = gltf['bufferViews'][acc['bufferView']]
    comp = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[
        acc['componentType']]
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[acc['type']]
    start = view.get('byteOffset', 0) + acc.get('byteOffset', 0)
    assert view.get('byteStride') in (None, width * np.dtype(comp).itemsize)
    arr = np.frombuffer(blob, dtype=comp, count=acc['count'] * width, offset=start)
    return arr.reshape(acc['count'], width) if width > 1 else arr


def read_meshes(path=GLB):
    """Maillages du mannequin : [{nom, positions, normales, indices, materiau}]
    dans l'ordre des nœuds du GLB. Une peau éventuelle est ignorée."""
    gltf, blob = read_glb(path)
    out = []
    for node in gltf['nodes']:
        if 'mesh' not in node:
            continue
        mesh = gltf['meshes'][node['mesh']]
        assert len(mesh['primitives']) == 1, node['name']
        prim = mesh['primitives'][0]
        out.append({
            'nom': node['name'],
            'maille': mesh.get('name', node['name']),
            'positions': accessor_array(gltf, blob, prim['attributes']['POSITION']).copy(),
            'normales': accessor_array(gltf, blob, prim['attributes']['NORMAL']).copy(),
            'indices': accessor_array(gltf, blob, prim['indices']).copy(),
            'materiau': prim['material'],
        })
    return out, gltf['materials']


# ------------------------------------------------------- squelette source --

def load_source_skeleton():
    """Pièces connexes du squelette d'appui source, en coordonnées glTF
    (liste de tableaux numpy N×3)."""
    import bpy
    import bmesh
    import numpy as np
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE / 'full-body-male-mobile.glb'))
    pieces = []
    for obj in bpy.data.objects:
        if obj.type != 'MESH' or 'boneId' not in obj.keys():
            continue
        obj.data.transform(obj.matrix_world)
        obj.matrix_world.identity()
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bm.verts.ensure_lookup_table()
        seen = set()
        for v in bm.verts:
            if v.index in seen:
                continue
            stack, comp = [v], []
            seen.add(v.index)
            while stack:
                x = stack.pop()
                comp.append(tuple(x.co))
                for e in x.link_edges:
                    y = e.other_vert(x)
                    if y.index not in seen:
                        seen.add(y.index)
                        stack.append(y)
            a = np.array(comp)
            # Blender (Z haut, −Y avant) → glTF (Y haut, +Z avant).
            pieces.append(np.stack([a[:, 0], a[:, 2], -a[:, 1]], axis=1))
        bm.free()
    # Ordre stable : par centre (hauteur, puis x, puis z).
    pieces.sort(key=lambda p: tuple(np.round(p.mean(0), 5)[[1, 0, 2]]))
    return pieces


def classify(pieces):
    """Rangement des pièces du squelette source. Renvoie (named, owner) :
    named = pièces anatomiques utiles aux centres articulaires ; owner =
    segment du squelette d'animation de chaque pièce (os rigides)."""
    import numpy as np
    info = []
    for i, p in enumerate(pieces):
        info.append({'i': i, 'c': p.mean(0), 'lo': p.min(0), 'hi': p.max(0),
                     'ext': p.max(0) - p.min(0), 'n': len(p)})
    left = {i['i'] for i in info}
    named, owner = {}, {}

    def take(idx, bone, name=None):
        left.discard(idx)
        owner[idx] = bone
        if name:
            named.setdefault(name, []).append(idx)

    # Rachis : 24 vertèbres (L5 → C1), sur la ligne médiane, en arrière.
    verts = [i for i in info if abs(i['c'][0]) < .012 and i['c'][2] < 0
             and i['ext'][0] > .04 and .95 < i['c'][1] < 1.56]
    verts.sort(key=lambda i: i['c'][1])
    assert len(verts) == 24, f'{len(verts)} vertèbres trouvées'
    levels = [f'L{5 - k}' for k in range(5)] + [f'T{12 - k}' for k in range(12)] + \
        [f'C{7 - k}' for k in range(7)]
    for lv, i in zip(levels, verts):
        seg = ('lumbar' if lv[0] == 'L' else
               'thoracic_low' if lv[0] == 'T' and int(lv[1:]) >= 8 else
               'thoracic_high' if lv[0] == 'T' else 'neck')
        take(i['i'], seg, lv)
    # Sacrum (la plus grande pièce) et coccyx.
    sacrum = max(info, key=lambda i: i['n'])
    assert abs(sacrum['c'][0]) < .01 and sacrum['c'][1] < .98
    take(sacrum['i'], 'pelvis', 'sacrum')
    for i in info:
        if i['i'] in left and abs(i['c'][0]) < .012 and i['c'][1] < sacrum['lo'][1] + .03 \
                and i['c'][1] > .8:
            take(i['i'], 'pelvis', 'coccyx')
    # Sternum : médian, en avant, à hauteur du thorax.
    for i in info:
        if i['i'] in left and abs(i['c'][0]) < .012 and i['c'][2] > .03 and 1.2 < i['c'][1] < 1.41:
            take(i['i'], 'thoracic_high', 'sternum')
    # Cou (cartilages et os hyoïde, en avant) puis tête.
    for i in info:
        if i['i'] in left and abs(i['c'][0]) < .03 and i['c'][2] > -.03 \
                and 1.40 < i['c'][1] < 1.505:
            take(i['i'], 'neck', 'larynx')
    for i in info:
        if i['i'] in left and i['c'][1] > 1.47:
            take(i['i'], 'head', 'skull')

    for side, sign in (('l', 1), ('r', -1)):
        def mine(i):
            return i['i'] in left and i['c'][0] * sign > .012

        def one(cands, what):
            assert len(cands) == 1, f'{what}_{side} : {len(cands)} pièces'
            return cands[0]

        hum = one([i for i in info if mine(i) and i['ext'][1] > .25 and 1.15 < i['c'][1] < 1.35
                   and abs(i['c'][0]) > .14], 'humerus')
        take(hum['i'], 'upperarm_' + side, 'humerus_' + side)
        fa = [i for i in info if mine(i) and i['ext'][1] > .2 and .9 < i['c'][1] < 1.05
              and abs(i['c'][0]) > .18]
        assert len(fa) == 2, f'avant-bras_{side}'
        ulna, radius = sorted(fa, key=lambda i: -i['hi'][1])
        take(ulna['i'], 'forearm_' + side, 'ulna_' + side)
        take(radius['i'], 'radius_' + side, 'radius_' + side)
        fem = one([i for i in info if mine(i) and i['ext'][1] > .35 and .5 < i['c'][1] < .8],
                  'femur')
        take(fem['i'], 'thigh_' + side, 'femur_' + side)
        leg = [i for i in info if mine(i) and i['ext'][1] > .3 and .15 < i['c'][1] < .35]
        assert len(leg) == 2, f'jambe_{side}'
        tibia, fibula = sorted(leg, key=lambda i: abs(i['c'][0]))
        take(tibia['i'], 'shin_' + side, 'tibia_' + side)
        take(fibula['i'], 'shin_' + side, 'fibula_' + side)
        hip = one([i for i in info if mine(i) and .8 < i['c'][1] < .95 and i['n'] >= 80
                   and i['ext'][0] > .1], 'os_coxal')
        take(hip['i'], 'pelvis', 'hip_' + side)
        # Rotule : rigide avec l'aide du genou aux 2/3 de la flexion (M56) :
        # tenue au tibia par le ligament patellaire, elle glisse dans la
        # trochlée en tournant moins que la jambe (flexion patellaire ≈ 0,6 à
        # 0,7 × flexion du genou, Kapandji t. 2).
        pat = one([i for i in info if mine(i) and .40 < i['c'][1] < .48 and i['n'] <= 30
                   and i['c'][2] > 0], 'rotule')
        take(pat['i'], 'knee_aux2_' + side, 'patella_' + side)
        scap = one([i for i in info if mine(i) and i['c'][2] < -.03 and 1.3 < i['c'][1] < 1.42
                    and abs(i['c'][0]) > .09 and i['ext'][1] > .12], 'scapula')
        take(scap['i'], 'scapula_' + side, 'scapula_' + side)
        clav = one([i for i in info if mine(i) and 1.38 < i['c'][1] < 1.45 and i['ext'][0] > .1
                    and i['ext'][1] < .06], 'clavicule')
        take(clav['i'], 'clavicle_' + side, 'clavicle_' + side)

        # Main : 8 os du carpe (les plus hauts), 5 métacarpiens, pouce (chaîne
        # partant du métacarpien le plus latéral), phalanges proximales des
        # doigts longs (les 4 plus hautes), puis moyennes et distales.
        hand = [i for i in info if mine(i) and abs(i['c'][0]) > .15 and i['c'][1] < .87]
        assert len(hand) == 27, f'main_{side} : {len(hand)} pièces'
        hand.sort(key=lambda i: -i['c'][1])
        carpus, rest = hand[:8], hand[8:]
        meta = sorted(rest, key=lambda i: -i['c'][1])[:5]
        rest = [i for i in rest if i not in meta]
        mc1 = max(meta, key=lambda i: abs(i['c'][0]))
        thumb, tip = [], mc1
        for _ in range(2):
            low = tip['c'] - np.array([0, tip['ext'][1] / 2, 0])
            nxt = min(rest, key=lambda i: np.linalg.norm(i['c'] - low))
            thumb.append(nxt)
            rest.remove(nxt)
            tip = nxt
        rest.sort(key=lambda i: -i['c'][1])
        prox, dist = rest[:4], rest[4:]
        for i in carpus:
            take(i['i'], 'hand_' + side, 'carpus_' + side)
        for i in meta:
            take(i['i'], 'hand_' + side, 'metacarpal_' + side)
        for i in thumb:
            take(i['i'], 'hand_' + side, 'thumb_' + side)
        for i in prox:
            take(i['i'], 'fingers1_' + side, 'phalanx1_' + side)
        for i in dist:
            take(i['i'], 'fingers2_' + side, 'phalanx23_' + side)

        # Pied : 5 métatarsiens (allongés vers l'avant), tarse (en arrière des
        # métatarsiens), phalanges et sésamoïdes (en avant).
        foot = [i for i in info if mine(i) and i['c'][1] < .09]
        assert len(foot) == 28, f'pied_{side} : {len(foot)} pièces'
        mts = sorted([i for i in foot if i['c'][2] > 0], key=lambda i: -i['ext'][2])[:5]
        zmt = sum(i['c'][2] for i in mts) / 5
        for i in foot:
            if i in mts:
                take(i['i'], 'foot_' + side, 'metatarsal_' + side)
            elif i['c'][2] < zmt:
                take(i['i'], 'foot_' + side, 'tarsus_' + side)
            else:
                take(i['i'], 'toes_' + side, 'phalanx_foot_' + side)
        tar = [i for i in foot if owner[i['i']] == 'foot_' + side and i not in mts]
        assert len(tar) == 7, f'tarse_{side} : {len(tar)}'

        # Côtes (12, les plus grandes pièces du thorax) et cartilages costaux
        # (10) : 1 à 7 avec le thorax haut (avec le sternum), 8 à 12 avec le
        # thorax bas.
        thorax = [i for i in info if mine(i) and 1.0 < i['c'][1] < 1.46 and abs(i['c'][0]) < .18]
        ribs = sorted([i for i in thorax if i['n'] >= 80], key=lambda i: -i['hi'][1])
        carts = sorted([i for i in thorax if i['n'] < 80], key=lambda i: -i['hi'][1])
        assert len(ribs) == 12 and len(carts) == 10, \
            f'thorax_{side} : {len(ribs)} côtes, {len(carts)} cartilages'
        for k, i in enumerate(ribs):
            take(i['i'], 'thoracic_high' if k < 7 else 'thoracic_low', f'rib{k + 1}_' + side)
        for k, i in enumerate(carts):
            take(i['i'], 'thoracic_high' if k < 7 else 'thoracic_low',
                 f'cartilage{k + 1}_' + side)
    assert not left, f'pièces non rangées : {sorted(left)}'
    return named, owner


def fit_sphere(p):
    """Centre de la sphère des moindres carrés passant au mieux par p."""
    import numpy as np
    a = np.hstack([2 * p, np.ones((len(p), 1))])
    b = (p * p).sum(1)
    sol = np.linalg.lstsq(a, b, rcond=None)[0]
    return sol[:3]


def joint_centres(pieces, named):
    """Têtes et queues des os (coordonnées glTF), depuis les repères
    anatomiques du squelette source."""
    import numpy as np

    def pts(name):
        return np.concatenate([pieces[i] for i in named[name]])

    def body_centre(level):
        # Corps vertébral : partie antérieure (3,5 cm) de la vertèbre.
        p = pts(level)
        front = p[p[:, 2] > p[:, 2].max() - .035]
        return front.mean(0)

    lv = {k: body_centre(k) for k in named if k[0] in 'LTC' and k[1:].isdigit()}

    def disc(a, b):
        return (lv[a] + lv[b]) / 2

    heads, tails, axes = {}, {}, {}
    l5s1 = lv['L5'] + (lv['L5'] - lv['L4']) / 2
    heads['lumbar'] = l5s1
    heads['thoracic_low'] = disc('L1', 'T12')
    heads['thoracic_high'] = disc('T8', 'T7')
    heads['neck'] = disc('T1', 'C7')
    c1 = pts('C1').mean(0)
    heads['head'] = c1 + np.array([0, .012, 0])
    skull = pts('skull')
    tails['head'] = np.array([0, skull[:, 1].max(), heads['head'][2]])

    for side, sign in (('l', 1), ('r', -1)):
        s = '_' + side
        fem = pts('femur' + s)
        top = fem[fem[:, 1] > fem[:, 1].max() - .07]
        medial = top[np.abs(top[:, 0]) < np.abs(top[:, 0]).min() + .045]
        hipc = fit_sphere(medial)
        heads['thigh' + s] = hipc
        tib = pts('tibia' + s)
        fib = pts('fibula' + s)
        cond = fem[fem[:, 1] < fem[:, 1].min() + .035]
        knee = cond.mean(0)
        knee[1] = (fem[:, 1].min() + tib[:, 1].max()) / 2 + .02
        heads['shin' + s] = knee
        # M56 : axe de flexion du genou = ligne des épicondyles fémoraux
        # (points les plus médial et latéral des condyles), du médial vers
        # le latéral (sens de l'axe X de la flexion, côté gauche).
        med = cond[np.argmin(cond[:, 0] * sign)]
        lat = cond[np.argmax(cond[:, 0] * sign)]
        a = (lat - med) / np.linalg.norm(lat - med)
        # Inclinaison frontale bornée à 3° : debout, l'interligne du genou
        # (parallèle à l'axe transépicondylien) est en varus de 3° ± 2°
        # (Cooke et al., J Bone Joint Surg Br 1997 ; Bellemans et al., Clin
        # Orthop 2012) ; les condyles du modèle simplifié donnent 8°, ce qui
        # ferait glisser le pied de 2 cm en bas de squat.
        tilt = max(-math.radians(3), min(math.radians(3), math.asin(float(a[1]))))
        horiz = a[[0, 2]] / np.linalg.norm(a[[0, 2]]) * math.cos(tilt)
        axes['genou' + s] = np.array([horiz[0], math.sin(tilt), horiz[1]])
        mm = tib[np.argmin(tib[:, 1])]
        lm = fib[np.argmin(fib[:, 1])]
        heads['foot' + s] = (mm + lm) / 2
        # Axe de la cheville : ligne bimalléolaire (malléole médiale plus
        # haute et plus avant que la latérale), du latéral vers le médial
        # (sens −X de la flexion dorsale). L'angle transversal est mesuré
        # (≈ 26°, dans la fourchette 20-30° d'Inman 1976) ; l'inclinaison
        # frontale des pointes des malléoles du modèle (≈ 19°) dépasse celle
        # de l'axe réel, qui passe sous les pointes (82° ± 4° sur l'axe du
        # tibia, Inman ; Lundberg 1989) : elle est bornée à 10°.
        a = (mm - lm) / np.linalg.norm(mm - lm)
        tilt = min(math.asin(float(a[1])), math.radians(10))
        horiz = a[[0, 2]] / np.linalg.norm(a[[0, 2]]) * math.cos(tilt)
        axes['cheville' + s] = np.array([horiz[0], math.sin(tilt), horiz[1]])
        mets = [pieces[i] for i in named['metatarsal' + s]]
        mtp = np.mean([m[m[:, 2] > m[:, 2].max() - .01].mean(0) for m in mets], axis=0)
        heads['toes' + s] = mtp
        toes = pts('phalanx_foot' + s)
        tails['toes' + s] = np.array([mtp[0], toes[:, 1].min(), toes[:, 2].max()])

        hum = pts('humerus' + s)
        top = hum[hum[:, 1] > hum[:, 1].max() - .05]
        medial = top[np.abs(top[:, 0]) < np.abs(top[:, 0]).min() + .035]
        heads['upperarm' + s] = fit_sphere(medial)
        dist = hum[hum[:, 1] < hum[:, 1].min() + .025]
        elbow = dist.mean(0)
        elbow[1] = hum[:, 1].min() + .012
        heads['forearm' + s] = elbow
        # Axe de flexion du coude : ligne transépicondylienne de l'humérus
        # (épicondyles médial et latéral = extrêmes médio-latéraux des 3 cm
        # distaux), du latéral vers le médial (sens −X de la flexion).
        dist3 = hum[hum[:, 1] < hum[:, 1].min() + .03]
        med = dist3[np.argmin(dist3[:, 0] * sign)]
        lat = dist3[np.argmax(dist3[:, 0] * sign)]
        axes['coude' + s] = (med - lat) / np.linalg.norm(med - lat)
        ulna = pts('ulna' + s)
        rad = pts('radius' + s)
        ulna_head = ulna[ulna[:, 1] < ulna[:, 1].min() + .015].mean(0)
        radial_head = rad[rad[:, 1] > rad[:, 1].max() - .015].mean(0)
        heads['radius' + s] = radial_head
        tails['forearm' + s] = ulna_head
        tails['radius' + s] = ulna_head
        carpus = pts('carpus' + s)
        heads['hand' + s] = carpus.mean(0)
        metas = [pieces[i] for i in named['metacarpal' + s]]
        # Métacarpiens des doigts longs (sans le premier, le plus latéral).
        metas.sort(key=lambda m: -abs(m.mean(0)[0]))
        mcp = np.mean([m[m[:, 1] < m[:, 1].min() + .008].mean(0) for m in metas[1:]], axis=0)
        heads['fingers1' + s] = mcp
        prox = [pieces[i] for i in named['phalanx1' + s]]
        pip = np.mean([p[p[:, 1] < p[:, 1].min() + .005].mean(0) for p in prox], axis=0)
        heads['fingers2' + s] = pip
        d = pts('phalanx23' + s)
        tails['fingers2' + s] = np.array([pip[0], d[:, 1].min(), pip[2]])

        clav = pts('clavicle' + s)
        ax = np.abs(clav[:, 0])
        heads['clavicle' + s] = clav[ax < ax.min() + .012].mean(0)
        heads['scapula' + s] = clav[ax > ax.max() - .012].mean(0)
        scap = pts('scapula' + s)
        tails['scapula' + s] = scap[np.argmin(scap[:, 1])]

    heads['pelvis'] = (heads['thigh_l'] + heads['thigh_r']) / 2
    # Symétrie exacte : moyenne des deux côtés (x opposés) ; axes mesurés :
    # moyenne des deux côtés dans la convention du côté gauche, puis miroir
    # (x, y, z) → (x, −y, −z) pour le droit (convention de rig_def).
    for name in list(heads):
        if name.endswith('_l'):
            r = name[:-2] + '_r'
            for d in (heads, tails):
                if name in d and r in d:
                    m = (d[name] * np.array([1, 1, 1]) + d[r] * np.array([-1, 1, 1])) / 2
                    d[name] = m
                    d[r] = m * np.array([-1, 1, 1])
    for name in list(axes):
        if name.endswith('_l'):
            r = name[:-2] + '_r'
            # L'axe droit mesuré (vecteur physique), ramené à gauche par le
            # miroir sagittal (−x, y, z), moyenné ; l'axe de rotation droit
            # est (x, −y, −z) de l'axe gauche (même signe d'angle des deux
            # côtés : convention de rig_def).
            m = (axes[name] + axes[r] * np.array([-1, 1, 1])) / 2
            m /= np.linalg.norm(m)
            axes[name] = m
            axes[r] = m * np.array([1, -1, -1])
    for name in ('pelvis', 'lumbar', 'thoracic_low', 'thoracic_high', 'neck', 'head'):
        heads[name][0] = 0.0
        if name in tails:
            tails[name][0] = 0.0
    # Queue par défaut : tête du premier enfant (le long de la chaîne).
    for name in BONE_NAMES:
        if name in tails or rig_def.helper_of(name):
            continue
        kids = [b for b in BONE_NAMES if PARENT[b] == name]
        chain = {'pelvis': 'lumbar', 'lumbar': 'thoracic_low',
                 'thoracic_low': 'thoracic_high', 'thoracic_high': 'neck', 'neck': 'head'}
        if name in chain:
            tails[name] = heads[chain[name]]
        else:
            tails[name] = heads[kids[0]]
    return heads, tails, axes


def bulge_placement(meshes):
    """Tête (ventre) et axe des os de gonflement (M56) : centre des sommets
    des muscles concernés pondérés par le profil de ventre, axe principal."""
    import numpy as np
    out = {}
    by_name = {m['nom']: m for m in meshes}
    for bone in BONE_NAMES:
        spec = rig_def.helper_spec(bone)
        if not spec or 'muscles' not in spec:
            continue
        side = 'left' if bone.endswith('_l') else 'right'
        pts = np.concatenate([by_name[f'{k}_{side}']['positions'] for k in spec['muscles']])
        c = pts.mean(0)
        _, _, vt = np.linalg.svd(pts - c, full_matrices=False)
        axis = vt[0]
        u = (pts - c) @ axis
        u = (u - u.min()) / (u.max() - u.min())
        w = np.sin(np.pi * u) ** 2
        head = (pts * w[:, None]).sum(0) / w.sum()
        out[bone] = (head, axis if axis[1] < 0 else -axis)
    return out


# ------------------------------------------------------------ poids de peau --

AXIAL = ['pelvis', 'lumbar', 'thoracic_low', 'thoracic_high', 'neck', 'head']


# Segments que chaque muscle peut suivre (correction des poids automatiques) :
# ceux de ses insertions et ceux qu'il croise (clé du muscle dans
# full-body-map.json). Un muscle ne suit jamais un segment auquel il n'est pas
# attaché, même s'il le touche (le dentelé antérieur, contre le bras au repos,
# ne suit que le thorax et la scapula).
TH = ('thoracic_low', 'thoracic_high')
MUSCLE_BONES = {
    # Épaule
    # Deltoïdes : la clavicule (parent de la scapula, qui bouge peu de plus)
    # n'est pas une influence à part : 4 influences par sommet, une de plus
    # créait des discontinuités entre voisins (M56).
    'deltoid_anterior': ('scapula', 'upperarm'),
    'deltoid_lateral': ('scapula', 'upperarm'),
    'deltoid_posterior': ('scapula', 'upperarm'),
    'supraspinatus': ('scapula', 'upperarm'), 'infraspinatus': ('scapula', 'upperarm'),
    'subscapularis': ('scapula', 'upperarm'), 'teres_minor': ('scapula', 'upperarm'),
    'teres_major': ('scapula', 'upperarm'),
    # Thorax
    'pectoralis_major_clavicular': TH + ('clavicle', 'upperarm'),
    'pectoralis_major_sternocostal': TH + ('upperarm',),
    'pectoralis_major_abdominal': TH + ('lumbar', 'upperarm'),
    'pectoralis_minor': TH + ('scapula',), 'serratus_anterior': TH + ('scapula',),
    # Dos
    # Trapèze : dans la source, « Descending part » (trapezius_upper) est la
    # nappe basse (T4-T12) et « Ascending part » (trapezius_lower) la nappe du
    # cou (vérifié sur la géométrie : y 1,12-1,41 m contre 1,42-1,57 m). Les
    # segments suivent la géométrie.
    'trapezius_upper': TH + ('lumbar', 'scapula'),
    'trapezius_middle': TH + ('neck', 'clavicle', 'scapula'),
    'trapezius_lower': ('head', 'neck', 'thoracic_high', 'clavicle', 'scapula'),
    'latissimus_dorsi': ('pelvis', 'lumbar') + TH + ('scapula', 'upperarm'),
    'rhomboid_major': TH + ('scapula',), 'rhomboid_minor': ('neck',) + TH + ('scapula',),
    'levator_scapulae': ('head', 'neck', 'thoracic_high', 'scapula'),
    'serratus_posterior_inferior': ('lumbar',) + TH,
    'serratus_posterior_superior': ('neck',) + TH,
    'iliocostalis_lumborum': ('pelvis', 'lumbar') + TH,
    'iliocostalis_thoracis': ('lumbar',) + TH + ('neck',),
    'longissimus_thoracis': ('pelvis', 'lumbar') + TH + ('neck',),
    'spinalis_thoracis': ('lumbar',) + TH + ('neck',),
    'multifidus_lumborum': ('pelvis', 'lumbar', 'thoracic_low'),
    # Tronc
    'rectus_abdominis': ('pelvis', 'lumbar') + TH,
    'transversus_abdominis': ('pelvis', 'lumbar') + TH,
    'external_oblique': ('pelvis', 'lumbar') + TH, 'internal_oblique': ('pelvis', 'lumbar') + TH,
    'quadratus_lumborum': ('pelvis', 'lumbar', 'thoracic_low'),
    # Cou
    'sternocleidomastoid': ('head', 'neck', 'thoracic_high', 'clavicle'),
    'scalenus_medius': ('neck', 'thoracic_high'), 'scalenus_anterior': ('neck', 'thoracic_high'),
    'scalenus_posterior': ('neck', 'thoracic_high'),
    'splenius_capitis': ('head', 'neck', 'thoracic_high'),
    'splenius_colli': ('head', 'neck', 'thoracic_high'),
    'platysma': ('head', 'neck', 'thoracic_high', 'clavicle'),
    # Bras
    'biceps_brachii_long': ('scapula', 'upperarm', 'forearm', 'radius'),
    'biceps_brachii_short': ('scapula', 'upperarm', 'forearm', 'radius'),
    'brachialis': ('upperarm', 'forearm'), 'coracobrachialis': ('scapula', 'upperarm'),
    'triceps_long': ('scapula', 'upperarm', 'forearm'),
    'triceps_lateral': ('upperarm', 'forearm'), 'triceps_medial': ('upperarm', 'forearm'),
    # Hanche
    'gluteus_maximus': ('pelvis', 'lumbar', 'thigh'), 'gluteus_medius': ('pelvis', 'thigh'),
    'gluteus_minimus': ('pelvis', 'thigh'), 'tensor_fasciae_latae': ('pelvis', 'thigh', 'shin'),
    'iliacus': ('pelvis', 'thigh'), 'psoas_major': ('thoracic_low', 'lumbar', 'pelvis', 'thigh'),
    'piriformis': ('pelvis', 'thigh'), 'quadratus_femoris': ('pelvis', 'thigh'),
    'obturator_internus': ('pelvis', 'thigh'), 'obturator_externus': ('pelvis', 'thigh'),
    'gemellus_inferior': ('pelvis', 'thigh'), 'gemellus_superior': ('pelvis', 'thigh'),
    # Cuisse
    'rectus_femoris': ('pelvis', 'thigh', 'shin'), 'vastus_lateralis': ('thigh', 'shin'),
    'vastus_medialis': ('thigh', 'shin'), 'vastus_intermedius': ('thigh', 'shin'),
    'biceps_femoris_long': ('pelvis', 'thigh', 'shin'), 'biceps_femoris_short': ('thigh', 'shin'),
    'semitendinosus': ('pelvis', 'thigh', 'shin'), 'semimembranosus': ('pelvis', 'thigh', 'shin'),
    'sartorius': ('pelvis', 'thigh', 'shin'), 'gracilis': ('pelvis', 'thigh', 'shin'),
    'adductor_magnus': ('pelvis', 'thigh'), 'adductor_longus': ('pelvis', 'thigh'),
    'adductor_brevis': ('pelvis', 'thigh'), 'pectineus': ('pelvis', 'thigh'),
    # Jambe
    'gastrocnemius_lateral': ('thigh', 'shin', 'foot'),
    'gastrocnemius_medial': ('thigh', 'shin', 'foot'), 'plantaris': ('thigh', 'shin', 'foot'),
    'popliteus': ('thigh', 'shin'),
    # Volumes
    'hand_intrinsic': ('forearm', 'radius', 'hand', 'fingers1', 'fingers2'),
    'foot_intrinsic': ('shin', 'foot', 'toes'),
}
# Par défaut, selon la région du modèle source.
REGION_BONES = {
    'forearms': ('upperarm', 'forearm', 'radius', 'hand'),
    'calves': ('shin', 'foot'),
}


def with_side(bones, s, key=None):
    """Noms complets (côté ajouté aux os des membres), os d'aide compris
    quand le muscle suit le parent et l'os suivi, os de gonflement du
    muscle `key` compris."""
    out = [b if b in AXIAL else f'{b}_{s}' for b in bones]
    for h in rig_def.BONE_NAMES:
        pair = rig_def.helper_of(h)
        if not pair or not h.endswith('_' + s):
            continue
        spec = rig_def.helper_spec(h)
        if 'muscles' in spec:
            if key in spec['muscles'] and pair[0] in out:
                out.append(h)
        elif pair[0] in out and pair[1] in out:
            out.append(h)
    return out


def allowed_bones(key, region, s):
    if key == 'head':
        return ['neck', 'head']
    if key in MUSCLE_BONES:
        return with_side(MUSCLE_BONES[key], s, key)
    if region in REGION_BONES:
        return with_side(REGION_BONES[region], s)
    raise KeyError(key)


def side_bones(s):
    """Contexte sombre (cou, tendons, fascias) : segments du côté du sommet
    (axiaux seuls près de la ligne médiane)."""
    if s == 'm':
        return list(AXIAL)
    return [b for b in rig_def.BONE_NAMES if b in AXIAL or b.endswith('_' + s)]


def region_of_mesh(name):
    """(clé du muscle, région source, côté) d'un maillage du mannequin."""
    source = json.loads((SOURCE / 'full-body-map.json').read_text())
    by_id = {m['id']: m for m in source['muscles']}
    if name in by_id:
        return by_id[name]['key'], by_id[name]['region'], by_id[name]['side'][0]
    if name.startswith('platysma_'):
        return 'platysma', 'neck', name.split('_')[1][0]
    if name.startswith('hand_'):
        return 'hand_intrinsic', 'hand', name.split('_')[1][0]
    if name.startswith('foot_'):
        return 'foot_intrinsic', 'foot', name.split('_')[1][0]
    if name == 'head':
        return 'head', 'head', None
    return None, None, None


# Paramètres des poids automatiques (géodésiques) ; réglables.
VOXEL = .005          # m
WEIGHT_POWER = 4.0    # w ∝ (d + D0)^-p
WEIGHT_D0 = .01       # m
MAX_INFLUENCES = 4


def voxel_domain(meshes, pieces, heads, tails):
    """Volume du corps en voxels : surfaces de tous les maillages (et os
    source) échantillonnées, dilatées d'un voxel, cavités comblées."""
    import numpy as np
    from scipy import ndimage
    pts = [np.concatenate([m['positions'] for m in meshes]), np.concatenate(pieces)]
    for m in meshes:
        tri = m['positions'][m['indices'].reshape(-1, 3)]
        edge = np.max(np.linalg.norm(tri - np.roll(tri, 1, axis=1), axis=2), axis=1)
        ks = np.clip(np.ceil(edge / (VOXEL * .5)).astype(int), 1, 40)
        for k in np.unique(ks):
            t = tri[ks == k]
            ij = np.array([(i, j) for i in range(k + 1) for j in range(k + 1 - i)]) / k
            bary = np.stack([ij[:, 0], ij[:, 1], 1 - ij.sum(1)], 1)
            pts.append(np.einsum('bk,tkd->tbd', bary, t).reshape(-1, 3))
    for b in heads:
        a, c = heads[b], tails[b]
        n = max(2, int(np.linalg.norm(c - a) / (VOXEL * .5)))
        pts.append(a + (c - a) * np.linspace(0, 1, n)[:, None])
    allp = np.concatenate(pts)
    origin = allp.min(0) - 3 * VOXEL
    dims = np.ceil((allp.max(0) - origin) / VOXEL).astype(int) + 4
    grid = np.zeros(dims, dtype=bool)
    ijk = np.floor((allp - origin) / VOXEL).astype(int)
    grid[ijk[:, 0], ijk[:, 1], ijk[:, 2]] = True
    grid = ndimage.binary_dilation(grid, iterations=1)
    grid = ndimage.binary_fill_holes(grid)
    return grid, origin


def geodesic_fields(grid, origin, seeds_by_bone):
    """Distance géodésique (m) de chaque voxel du volume aux voxels d'appui
    de chaque os (chemins à 26 voisins à l'intérieur du volume)."""
    import numpy as np
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import dijkstra
    index = -np.ones(grid.shape, dtype=np.int64)
    cells = np.argwhere(grid)
    index[grid] = np.arange(len(cells))
    rows, cols, vals = [], [], []
    offsets = [(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1)
               if (dx, dy, dz) > (0, 0, 0)]
    shape = np.array(grid.shape)
    for off in offsets:
        o = np.array(off)
        nb = cells + o
        ok = np.all((nb >= 0) & (nb < shape), axis=1)
        a = np.nonzero(ok)[0]
        b = index[nb[ok, 0], nb[ok, 1], nb[ok, 2]]
        keep = b >= 0
        rows.append(a[keep])
        cols.append(b[keep])
        vals.append(np.full(keep.sum(), VOXEL * float(np.linalg.norm(o))))
    n = len(cells)
    graph = coo_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))),
                       shape=(n, n)).tocsr()
    fields = {}
    for bone, seeds in seeds_by_bone.items():
        ijk = np.floor((seeds - origin) / VOXEL).astype(int)
        ids = np.unique(index[ijk[:, 0], ijk[:, 1], ijk[:, 2]])
        ids = ids[ids >= 0]
        assert len(ids), f'aucun voxel d\'appui pour {bone}'
        fields[bone] = dijkstra(graph, directed=False, indices=ids, min_only=True
                                ).astype(np.float32)
    return fields, index


def sample_fields(points, fields, index, origin, bones):
    """Distances interpolées (trilinéaire, voxels hors volume ou hors
    d'atteinte ignorés) aux os `bones` pour chaque point : (N, len(bones)),
    infini si aucun voxel voisin n'est relié à l'os."""
    import numpy as np
    f = (points - origin) / VOXEL - .5
    base = np.floor(f).astype(int)
    frac = f - base
    out = np.zeros((len(points), len(bones)))
    wsum = np.zeros((len(points), len(bones)))
    shape = np.array(index.shape)
    for corner in range(8):
        d = np.array([(corner >> k) & 1 for k in range(3)])
        c = np.clip(base + d, 0, shape - 1)
        idx = index[c[:, 0], c[:, 1], c[:, 2]]
        w = np.prod(np.where(d, frac, 1 - frac), axis=1)
        inside = idx >= 0
        for j, b in enumerate(bones):
            vals = fields[b][np.maximum(idx, 0)]
            ok = inside & np.isfinite(vals)
            out[:, j] += np.where(ok, w * np.where(ok, vals, 0), 0)
            wsum[:, j] += np.where(ok, w, 0)
    with np.errstate(invalid='ignore', divide='ignore'):
        res = out / wsum
    res[wsum < 1e-9] = np.inf
    return res


def quantize(weights):
    """Poids (N, 4) en octets de somme exactement 255 (plus forts restes)."""
    import numpy as np
    w = weights / weights.sum(1, keepdims=True) * 255
    q = np.floor(w).astype(int)
    rest = 255 - q.sum(1)
    order = np.argsort(-(w - q), axis=1)
    for k in range(4):
        add = rest > k
        q[np.arange(len(q))[add], order[add, k]] += 1
    assert (q.sum(1) == 255).all()
    return q.astype(np.uint8)


def rigid_bone_owner(os_mesh, pieces, owner):
    """Segment de chaque sommet de la maille des os : pièce source la plus
    proche, puis vote par pièce connexe (une pièce = un segment, rigide)."""
    import numpy as np
    from scipy.spatial import cKDTree
    src = np.concatenate(pieces)
    label = np.concatenate([np.full(len(p), i) for i, p in enumerate(pieces)])
    _, near = cKDTree(src).query(os_mesh['positions'])
    bone_of = np.array([BONE_NAMES.index(owner[label[k]]) for k in near])
    n = len(os_mesh['positions'])
    parent = np.arange(n)

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    tri = os_mesh['indices'].reshape(-1, 3)
    for a, b, c in tri:
        for x, y in ((a, b), (b, c)):
            rx, ry = find(x), find(y)
            if rx != ry:
                parent[rx] = ry
    # Sommets confondus (arêtes vives exportées en double) : même pièce.
    pos = np.round(os_mesh['positions'] / 1e-5).astype(np.int64)
    seen = {}
    for k, key in enumerate(map(tuple, pos)):
        if key in seen:
            rx, ry = find(k), find(seen[key])
            if rx != ry:
                parent[rx] = ry
        else:
            seen[key] = k
    roots = np.array([find(k) for k in range(n)])
    out = np.empty(n, dtype=int)
    comps = 0
    for r in np.unique(roots):
        members = roots == r
        out[members] = np.bincount(bone_of[members]).argmax()
        comps += 1
    return out, comps


def smooth_in_mesh(points, weights, sigma):
    """Lissage gaussien des poids entre sommets proches d'un même maillage
    (cohérence dans l'épaisseur des muscles minces, pas de pointes)."""
    import numpy as np
    from scipy.spatial import cKDTree
    tree = cKDTree(points)
    dist = tree.sparse_distance_matrix(tree, 2.5 * sigma, output_type='coo_matrix')
    from scipy.sparse import coo_matrix, identity
    k = coo_matrix((np.exp(-dist.data ** 2 / (2 * sigma * sigma)), (dist.row, dist.col)),
                   shape=dist.shape).tocsr() + identity(len(points), format='csr')
    out = k @ weights
    return out / out.sum(1, keepdims=True)


def finish_weights(w, bones, positions=None, chain=True):
    """Os d'aide (chaîne parent → 1/3 → 2/3 → os suivi, M56), os de
    gonflement (part du ventre), puis 4 influences les plus fortes.
    `chain` False : mélange linéaire direct parent / os suivi (nappes en
    éventail : leurs sommets sous l'aisselle, portés par un os d'aide,
    décriraient l'arc de l'articulation et sortiraient du corps en pointe ;
    la corde du mélange linéaire reste dans le corps)."""
    import numpy as np
    w = w.copy()
    col = {b: i for i, b in enumerate(bones)}
    # Chaînes d'aide : {(parent, suivi): [(part, os d'aide)…]}.
    chains = {}
    for h in bones:
        spec = rig_def.helper_spec(h)
        if spec and 'muscles' not in spec and chain:
            chains.setdefault(rig_def.helper_of(h), []).append((spec['part'], h))
    for (p, c), helpers in chains.items():
        nodes = [(0.0, p)] + sorted(helpers) + [(1.0, c)]
        wp, wc = w[:, col[p]].copy(), w[:, col[c]].copy()
        total = wp + wc
        both = (wp > 1e-9) & (wc > 1e-9)
        f = np.where(both, wc / np.maximum(total, 1e-12), 0.0)
        w[both, col[p]] = 0
        w[both, col[c]] = 0
        for (f0, b0), (f1, b1) in zip(nodes, nodes[1:]):
            seg = both & (f >= f0) & (f <= f1)
            t = (f[seg] - f0) / (f1 - f0)
            w[seg, col[b0]] += total[seg] * (1 - t)
            w[seg, col[b1]] += total[seg] * t
    # Gonflements : part du poids du segment, selon le profil de ventre.
    for h in bones:
        spec = rig_def.helper_spec(h)
        if not spec or 'muscles' not in spec or positions is None:
            continue
        p = rig_def.helper_of(h)[0]
        u = positions @ np.asarray(BULGE_AXES[h])
        u = (u - u.min()) / max(1e-9, u.max() - u.min())
        share = rig_def.BULGE_SHARE * np.sin(np.pi * u) ** 2
        moved = w[:, col[p]] * share
        w[:, col[p]] -= moved
        w[:, col[h]] += moved
    top = np.argsort(-w, axis=1)[:, :MAX_INFLUENCES]
    k = min(MAX_INFLUENCES, len(bones))
    tw = np.take_along_axis(w, top, 1)[:, :k]
    ids = np.array([BONE_NAMES.index(b) for b in bones])[top[:, :k]]
    return ids, tw


BULGE_AXES = {}


# Tendons d'insertion collés à l'os (M56) : les sommets de ces muscles à
# moins de GLUE_FAR de la surface de l'os d'insertion (fondu complet à
# GLUE_NEAR) suivent cet os seul ; sans cela, les poids géodésiques
# « doux » des grands muscles en éventail laissaient leur insertion à
# mi-chemin entre le tronc et le bras (déchirure de 9 cm bras levés).
INSERTIONS = {
    'latissimus_dorsi': 'humerus', 'teres_major': 'humerus',
    'pectoralis_major_clavicular': 'humerus', 'pectoralis_major_sternocostal': 'humerus',
    'pectoralis_major_abdominal': 'humerus', 'coracobrachialis': 'humerus',
    'deltoid_anterior': 'humerus', 'deltoid_lateral': 'humerus',
    'deltoid_posterior': 'humerus',
}
INSERTION_BONE = {'humerus': 'upperarm'}
GLUE_NEAR, GLUE_FAR = .012, .030
# Épaule (M56) : la tête humérale et l'acromion se chevauchent dans l'espace,
# les distances géodésiques y basculent d'un sommet au suivant (Δ de 0,5 sur
# 6 mm dans le deltoïde : plis en accordéon bras levé). Le partage scapula /
# bras des muscles qui croisent l'épaule suit donc la hauteur le long de
# l'axe du bras : tout à la scapula 2 cm au-dessus du centre de la tête
# humérale, tout au bras 10 cm au-dessous (tubérosité deltoïdienne), lissé.
SHOULDER_AXIAL = (-.02, .10)

SMOOTH_SIGMA = .018   # m
# Grands muscles en éventail tendus du tronc au bras : transition plus
# progressive (l'allongement se répartit sur toute leur longueur au lieu de
# se concentrer dans l'aisselle).
SOFT_POWER = 2.0
SOFT_SIGMA = .018     # lissage des nappes (comme les autres muscles)
SOFT_MUSCLES = {'latissimus_dorsi', 'pectoralis_major_clavicular',
                'pectoralis_major_sternocostal', 'pectoralis_major_abdominal', 'teres_major'}


def compute_weights(meshes, pieces, owner, heads, tails, log=print):
    """Influences (joints, poids en octets) par maillage."""
    import numpy as np
    # Os à distance calculée : os principaux et os d'aide qui portent une
    # pièce du squelette (la rotule, sur l'aide du genou).
    main_bones = [b for b in BONE_NAMES
                  if not rig_def.helper_of(b) or b in set(owner.values())]
    seeds = {}
    for b in main_bones:
        parts = [pieces[i] for i, o in owner.items() if o == b]
        if not rig_def.helper_of(b):
            a, c = heads[b], tails[b]
            n = max(2, int(np.linalg.norm(c - a) / (VOXEL * .5)))
            parts.append(a + (c - a) * np.linspace(0, 1, n)[:, None])
        seeds[b] = np.concatenate(parts)
    segs = [b for b in main_bones if not rig_def.helper_of(b)]
    grid, origin = voxel_domain(meshes, pieces, {b: heads[b] for b in segs},
                                {b: tails[b] for b in segs})
    log(f'volume : {grid.sum()} voxels de {VOXEL * 1000:.0f} mm, grille {grid.shape}')
    fields, index = geodesic_fields(grid, origin, seeds)
    log('distances géodésiques calculées')
    out, stats = {}, {'allowed': {}}
    deferred = []
    for mesh in meshes:
        name = mesh['nom']
        pos = mesh['positions']
        n = len(pos)
        joints = np.zeros((n, 4), dtype=np.uint8)
        weights = np.zeros((n, 4))
        if name == 'os':
            bone, comps = rigid_bone_owner(mesh, pieces, owner)
            joints[:, 0] = bone
            weights[:, 0] = 1
            stats['os_pieces'] = comps
        else:
            key, region, side = region_of_mesh(name)
            if key is None:
                # Contexte (fascias, tendons, muscles du cou) : poids des
                # muscles voisins, calculés après (collé à eux).
                deferred.append(mesh)
                continue
            groups = [(np.ones(n, dtype=bool), allowed_bones(key, region, side))]
            stats['allowed'][name] = groups[0][1]
            for mask, bones in groups:
                if not mask.any():
                    continue
                mains = [b for b in bones if b in fields]
                d = sample_fields(pos[mask], fields, index, origin, mains)
                power = SOFT_POWER if key in SOFT_MUSCLES else WEIGHT_POWER
                with np.errstate(divide='ignore'):
                    w = np.where(np.isfinite(d), (d + WEIGHT_D0) ** -power, 0)
                assert (w.sum(1) > 0).all(), f'{name} : sommet sans os atteignable'
                w = w / w.sum(1, keepdims=True)
                w = smooth_in_mesh(pos[mask], w,
                                   SOFT_SIGMA if key in SOFT_MUSCLES else SMOOTH_SIGMA)
                scap, arm = f'scapula_{side}', f'upperarm_{side}'
                if scap in mains and arm in mains:
                    a, b = heads[arm], heads['forearm_' + side]
                    axis = (b - a) / np.linalg.norm(b - a)
                    d = (pos[mask] - a) @ axis
                    f = np.clip((d - SHOULDER_AXIAL[0]) / (SHOULDER_AXIAL[1] - SHOULDER_AXIAL[0]),
                                0, 1)
                    f = f * f * (3 - 2 * f)
                    total = w[:, mains.index(scap)] + w[:, mains.index(arm)]
                    w[:, mains.index(scap)] = total * (1 - f)
                    w[:, mains.index(arm)] = total * f
                if key in INSERTIONS:
                    piece = INSERTIONS[key]
                    target = f'{INSERTION_BONE[piece]}_{side}'
                    src = np.concatenate([pieces[i] for i, o in owner.items() if o == target])
                    from scipy.spatial import cKDTree
                    d = cKDTree(src).query(pos[mask])[0]
                    near, far = (GLUE_NEAR, GLUE_FAR) if key not in SOFT_MUSCLES else (.008, .02)
                    g = np.clip((far - d) / (far - near), 0, 1)
                    g = g * g * (3 - 2 * g)
                    one = np.zeros(len(mains))
                    one[mains.index(target)] = 1
                    w = w * (1 - g)[:, None] + g[:, None] * one
                    stats.setdefault('colles', {})[name] = int((g > .5).sum())
                full = np.zeros((len(w), len(bones)))
                full[:, [bones.index(b) for b in mains]] = w
                ids, tw = finish_weights(full, bones, pos[mask],
                                         chain=key not in SOFT_MUSCLES)
                joints[mask, :ids.shape[1]] = ids
                weights[mask, :tw.shape[1]] = tw
        q = quantize(weights + 1e-12 * (weights.sum(1, keepdims=True) == 0))
        # Influence nulle après quantification : os 0 (sans effet).
        joints[q == 0] = 0
        out[name] = (joints, q)
    # Contexte : moyenne des 8 sommets de muscles les plus proches (pondérée
    # par l'inverse de la distance) ; les fascias et tendons suivent les
    # muscles qu'ils recouvrent.
    from scipy.spatial import cKDTree
    donors = [m for m in meshes if m['nom'] in out and m['nom'] != 'os']
    dpos = np.concatenate([m['positions'] for m in donors])
    dense = np.zeros((len(dpos), len(BONE_NAMES)))
    k0 = 0
    for m in donors:
        j, q = out[m['nom']]
        rows = np.arange(k0, k0 + len(j))
        for c in range(4):
            np.add.at(dense, (rows, j[:, c].astype(int)), q[:, c] / 255)
        k0 += len(j)
    tree = cKDTree(dpos)
    for mesh in deferred:
        dist, idx = tree.query(mesh['positions'], k=8)
        w = 1 / (dist + .002)
        blend = (dense[idx] * w[:, :, None]).sum(1) / w.sum(1, keepdims=True)
        top = np.argsort(-blend, axis=1)[:, :4]
        tw = np.take_along_axis(blend, top, 1)
        q = quantize(tw)
        joints = top.astype(np.uint8)
        joints[q == 0] = 0
        out[mesh['nom']] = (joints, q)
        stats['contexte_voisins'] = 8
    return out, stats


# ------------------------------------------------------------- postures --

def rig_bones(heads, tails, axes, bulges):
    """Os du rig.json : nom, parent, tête, queue, longueur, degrés de liberté
    (axes mesurés sur les os : coude, genou, cheville), os d'aide et de
    gonflement (M56)."""
    import numpy as np
    out = []
    heads, tails = dict(heads), dict(tails)
    for name in BONE_NAMES:
        pair = rig_def.helper_of(name)
        if name in bulges:
            head, axis = bulges[name]
            heads[name], tails[name] = head, head + axis * .05
        elif pair:
            heads[name], tails[name] = heads[pair[1]], tails[pair[1]]
    for name in BONE_NAMES:
        h, t = np.asarray(heads[name], float), np.asarray(tails[name], float)
        axis = (t - h) / np.linalg.norm(t - h)
        measured = {k[:-2]: v for k, v in axes.items() if k.endswith(name[-2:])}
        out.append({
            'nom': name, 'nom_fr': rig_def.FR_BONE[rig_def.base_name(name)] + (
                {'L': ' gauche', 'R': ' droit'}[SIDE[name]] if SIDE[name] else ''),
            'parent': PARENT[name], 'cote': SIDE[name],
            'tete': [round(float(v), 5) for v in h],
            'queue': [round(float(v), 5) for v in t],
            'longueur': round(float(np.linalg.norm(t - h)), 5),
            'ddl': rig_def.dofs_of(name, [round(float(v), 5) for v in axis],
                                   {k: [round(float(c), 5) for c in v]
                                    for k, v in measured.items()}),
        })
        spec = rig_def.helper_spec(name)
        if spec:
            aide = {'suit': spec['suit'], 'part': round(spec['part'], 6),
                    'gonflement': spec['gonflement']}
            if name in bulges:
                aide['axe'] = [round(float(v), 5) for v in bulges[name][1]]
                aide['muscles'] = spec['muscles']
            out[-1]['aide'] = aide
    return out


def resolve_postures(rig, meshes, skin):
    """Rotations locales (quaternions) et translation du bassin de chaque
    posture ; le placement (pieds à plat, appuis de la planche, sol) est
    résolu ici, une fois pour toutes."""
    import numpy as np
    import rig_pose
    model = {'meshes': meshes, 'rig': rig, 'skin': skin}
    by_name = {b['nom']: b for b in rig['os']}
    rest_low = min(float(m['positions'][:, 1].min()) for m in meshes)
    out = {}
    for key, spec in rig_def.POSTURES.items():
        angles = rig_def.posture_angles(key)

        def build(extra_pitch=0.0):
            a = {k: dict(v) for k, v in angles.items()}
            if extra_pitch:
                a.setdefault('pelvis', {})
                a['pelvis']['flexion'] = a['pelvis'].get('flexion', 0) + extra_pitch
            rots = rig_def.posture_rotations({b: by_name[b]['ddl'] for b in a}, a)
            return a, rots

        def posed(rots, trans=(0, 0, 0)):
            p = {'rotations': rots, 'translation': trans}
            return rig_pose.pose_model(model, p)

        def bisect(f, lo, hi):
            flo = f(lo)
            for _ in range(40):
                mid = (lo + hi) / 2
                fm = f(mid)
                if (fm > 0) == (flo > 0):
                    lo, flo = mid, fm
                else:
                    hi = mid
            return (lo + hi) / 2

        pitch = 0.0
        if spec['placement'] == 'pieds':
            # Pied à plat : l'axe avant du pied (+Z local) sans composante
            # verticale.
            def tilt(p):
                _, rots = build(p)
                g = rig_def.forward_kinematics(rig, rots)['foot_l']
                return g[1][2]
            pitch = bisect(tilt, -60, 30)
        elif spec['placement'] == 'appuis':
            def gap(p):
                _, rots = build(p)
                pos, _ = posed(rots)
                arm = min(pos[m['nom']][:, 1].min() for m in meshes
                          if m['nom'].startswith(('hand_', 'brachioradialis', 'extensor_carpi',
                                                  'flexor_carpi', 'anconeus')))
                toe = min(pos[f][:, 1].min() for f in ('foot_left', 'foot_right'))
                return arm - toe
            pitch = bisect(gap, 60, 110)
        a, rots = build(pitch)
        pos, _ = posed(rots)
        allp = np.concatenate(list(pos.values()))
        low = allp[:, 1].min()
        # Au sol : même hauteur que le modèle au repos (debout = repos exact).
        dy = rest_low - low + (.05 if spec['placement'] == 'suspendu' else 0)
        out[key] = {
            'nom': spec['nom'], 'app': spec['app'], 'placement': spec['placement'],
            'angles': {b: {k: round(v, 3) for k, v in d.items()} for b, d in a.items()},
            'rotations': {b: [round(float(c), 7) for c in q] for b, q in rots.items()
                          if abs(q[3]) < 1 - 1e-12},
            'translation': [0.0, round(float(dy), 5), 0.0],
        }
        # Têtes des os dans la posture (contrôle croisé de la cinématique de
        # l'application, test/m5_rig_test.dart).
        g = rig_def.forward_kinematics(rig, rots, (0.0, dy, 0.0))
        out[key]['tetes'] = {b: [round(float(g[b][i][3]), 5) for i in range(3)]
                             for b in BONE_NAMES}
    return out


# ------------------------------------------------------------------ export --

def write_glb(path, meshes, materials, rig=None, skin=None):
    """GLB riggé : nœuds des maillages (mêmes noms et ordre qu'avant), puis
    articulations `j_<os>` (translation seule au repos), une peau commune.
    Sans `rig` ni `skin` (M56, `build_body.py`) : maillages seuls."""
    import numpy as np
    chunks, views, accessors = [], [], []
    offset = 0

    def add(arr, target=None, **acc):
        nonlocal offset
        data = np.ascontiguousarray(arr).tobytes()
        pad = (-len(data)) % 4
        view = {'buffer': 0, 'byteOffset': offset, 'byteLength': len(data)}
        if target:
            view['target'] = target
        views.append(view)
        chunks.append(data + b'\0' * pad)
        offset += len(data) + pad
        accessors.append(dict(bufferView=len(views) - 1, **acc))
        return len(accessors) - 1

    nodes, gl_meshes = [], []
    njoint0 = len(meshes)
    for k, m in enumerate(meshes):
        pos = m['positions'].astype(np.float32)
        attrs = {
            'POSITION': add(pos, 34962, componentType=5126, count=len(pos), type='VEC3',
                            min=[float(v) for v in pos.min(0)],
                            max=[float(v) for v in pos.max(0)]),
            'NORMAL': add(m['normales'].astype(np.float32), 34962, componentType=5126,
                          count=len(pos), type='VEC3'),
        }
        if skin is not None:
            joints, weights = skin[m['nom']]
            attrs['JOINTS_0'] = add(joints.astype(np.uint8), 34962, componentType=5121,
                                    count=len(pos), type='VEC4')
            attrs['WEIGHTS_0'] = add(weights.astype(np.uint8), 34962, componentType=5121,
                                     normalized=True, count=len(pos), type='VEC4')
        idx = m['indices']
        itype = 5125 if idx.max() > 65535 else 5123
        ind = add(idx.astype(np.uint32 if itype == 5125 else np.uint16), 34963,
                  componentType=itype, count=len(idx), type='SCALAR')
        gl_meshes.append({'name': m['maille'], 'primitives': [
            {'attributes': attrs, 'indices': ind, 'material': m['materiau']}]})
        nodes.append({'name': m['nom'], 'mesh': k, **({'skin': 0} if skin is not None else {})})
    if rig is None:
        gltf = {
            'asset': {'version': '2.0',
                      'generator': 'Kalis Track tools/anatomy/build_body.py (M56)'},
            'scene': 0, 'scenes': [{'name': 'Mannequin', 'nodes': list(range(len(meshes)))}],
            'nodes': nodes, 'meshes': gl_meshes, 'materials': materials,
            'accessors': accessors, 'bufferViews': views, 'buffers': [{'byteLength': offset}],
        }
        _write_glb_file(path, gltf, chunks)
        return
    heads = {b['nom']: b['tete'] for b in rig['os']}
    for b in rig['os']:
        p = b['parent']
        t = heads[b['nom']] if p is None else [heads[b['nom']][i] - heads[p][i] for i in range(3)]
        node = {'name': 'j_' + b['nom'], 'translation': [float(v) for v in t]}
        kids = [njoint0 + i for i, c in enumerate(rig['os']) if c['parent'] == b['nom']]
        if kids:
            node['children'] = kids
        nodes.append(node)
    ibm = np.zeros((len(rig['os']), 16), dtype=np.float32)
    for i, b in enumerate(rig['os']):
        m = np.eye(4)
        m[:3, 3] = -np.asarray(b['tete'])
        ibm[i] = m.T.reshape(-1)   # colonnes
    ibm_acc = add(ibm, None, componentType=5126, count=len(ibm), type='MAT4')
    gltf = {
        'asset': {'version': '2.0', 'generator': 'Kalis Track tools/anatomy/build_rig.py (M5)'},
        'scene': 0,
        'scenes': [{'name': 'Mannequin', 'nodes': list(range(len(meshes))) + [njoint0]}],
        'nodes': nodes, 'meshes': gl_meshes, 'materials': materials,
        'skins': [{'name': 'squelette', 'skeleton': njoint0, 'inverseBindMatrices': ibm_acc,
                   'joints': [njoint0 + i for i in range(len(rig['os']))]}],
        'accessors': accessors, 'bufferViews': views,
        'buffers': [{'byteLength': offset}],
    }
    _write_glb_file(path, gltf, chunks)


def _write_glb_file(path, gltf, chunks):
    import struct
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    blob = b''.join(chunks)
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, total))
        f.write(struct.pack('<I4s', len(js), b'JSON'))
        f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0'))
        f.write(blob)


def write_skin(path, meshes, skin):
    """Influences par sommet : pour chaque maillage (ordre du GLB), 4 os
    (octets) puis 4 poids (octets, somme 255)."""
    import numpy as np
    parts = []
    for m in meshes:
        joints, weights = skin[m['nom']]
        parts.append(np.hstack([joints, weights]).astype(np.uint8).tobytes())
    path.write_bytes(b''.join(parts))


def main():
    import numpy as np
    log = print
    meshes, materials = read_meshes(GLB)
    log(f'{len(meshes)} maillages, {sum(len(m["positions"]) for m in meshes)} sommets')
    pieces = load_source_skeleton()
    named, owner = classify(pieces)
    heads, tails, axes = joint_centres(pieces, named)
    bulges = bulge_placement(meshes)
    BULGE_AXES.update({k: v[1] for k, v in bulges.items()})
    bones = rig_bones(heads, tails, axes, bulges)
    skin, stats = compute_weights(meshes, pieces, owner,
                                  {k: np.asarray(v) for k, v in heads.items()},
                                  {k: np.asarray(v) for k, v in tails.items()}, log)
    rig = {
        'schema': 1,
        'repere': 'glTF : mètres, Y vers le haut, +Z vers l\'avant, +X côté gauche',
        'os': bones,
        'sources': rig_def.SOURCES,
        'peau': {
            'fichier': 'assets/anatomy/mannequin_skin.bin', 'influences': MAX_INFLUENCES,
            'format': 'par sommet : 4 os (octet, index dans « os ») puis 4 poids '
                      '(octet, somme 255), maillages dans l\'ordre du GLB',
            'maillages': [{'nom': m['nom'], 'sommets': len(m['positions'])} for m in meshes],
        },
    }
    skin_f = {k: (j.astype(np.int64), q.astype(np.float64) / 255) for k, (j, q) in skin.items()}
    rig['postures'] = resolve_postures(rig, meshes, skin_f)
    write_glb(GLB, meshes, materials, rig, skin)
    write_skin(OUT_SKIN, meshes, skin)
    OUT_RIG.write_text(json.dumps(rig, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    report = {'os': len(bones), 'sommets': sum(len(m['positions']) for m in meshes),
              'axes_mesures': {k: [round(float(c), 4) for c in v] for k, v in axes.items()},
              'voxel_m': VOXEL, 'puissance': WEIGHT_POWER, 'd0_m': WEIGHT_D0, **stats,
              'pieces_squelette_source': len(pieces)}
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1) + '\n')
    log(f"{report['os']} os, {report['sommets']} sommets, "
        f"{len(rig['postures'])} postures ; rig.json, mannequin_skin.bin, mannequin.glb écrits")


if __name__ == '__main__':
    main()
