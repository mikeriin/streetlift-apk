#!/usr/bin/env python3
"""M7 (mannequin 3D) : mannequin animable, pour le lecteur d'animations.

Le mannequin fixe de M6c (`assets/anatomy/mannequin.glb`) est le personnage
Mixamo « Ch36 » « fit », posé bras abaissés, sans squelette. Le lecteur a
besoin du même personnage **avec sa peau** : mêmes zones (un nœud par zone,
mêmes noms), mêmes triangles, mais au repos en T (pose de liaison du FBX)
avec les 65 os du squelette `mixamorig1:` et les poids de Mixamo.

Chaîne (aucune nouvelle segmentation : les zones sont reprises du GLB fixe) :
  1. lecture du FBX et mêmes étapes que `build_character.py` : coutures
     lissées, « fit » (maillage de repos), pose d'affichage ;
  2. zone de chaque triangle : celle du triangle du GLB fixe de même centre
     (écart vérifié < 0,05 mm : même maillage, même pose) ;
  3. GLB `assets/anatomy/mannequin_anime.glb` : un nœud par zone au repos en
     T, JOINTS_0 / WEIGHTS_0 (4 influences, octets), nœuds d'os `j_<os>`
     (translation depuis le parent, repère du corps : pose = rotation locale
     autour de la tête de l'os, comme `MannequinRig` de l'application et
     `skin_matrices` de build_character.py), matrices inverses de liaison
     = translation −tête ;
  4. `assets/anatomy/rig_mixamo.json` (os, têtes, pose d'affichage en
     quaternions, liste des maillages et nombre de sommets) et
     `assets/anatomy/peau_mixamo.bin` (4 os puis 4 poids par sommet, octets,
     somme 255) : la même peau sur le processeur (toucher, halo, cadrage).

Relançable :
  KT_ASSETS_KEY=… python3 tools/secure_assets.py decrypt --tout
  python3 tools/anatomy/build_animated.py
puis `KT_ASSETS_KEY=… python3 tools/secure_assets.py encrypt assets/anatomy/mannequin_anime.glb`.
`--check` vérifie les sorties suivies (sans la source ni la clé).
"""
import argparse
import json
import math
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))

OUT_GLB = ROOT / 'assets/anatomy/mannequin_anime.glb'
OUT_RIG = ROOT / 'assets/anatomy/rig_mixamo.json'
OUT_SKIN = ROOT / 'assets/anatomy/peau_mixamo.bin'
STATIC_GLB = ROOT / 'assets/anatomy/mannequin.glb'
MATCH_TOLERANCE = 5e-5   # m : écart maximal entre centres de triangles
INFLUENCES = 4


def quat_of(R):
    """Quaternion (x, y, z, w) d'une matrice de rotation 3×3."""
    import numpy as np
    m = np.asarray(R, dtype=np.float64)
    t = m.trace()
    if t > 0:
        s = math.sqrt(t + 1) * 2
        q = [(m[2, 1] - m[1, 2]) / s, (m[0, 2] - m[2, 0]) / s, (m[1, 0] - m[0, 1]) / s, s / 4]
    elif m[0, 0] > m[1, 1] and m[0, 0] > m[2, 2]:
        s = math.sqrt(1 + m[0, 0] - m[1, 1] - m[2, 2]) * 2
        q = [s / 4, (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    elif m[1, 1] > m[2, 2]:
        s = math.sqrt(1 + m[1, 1] - m[0, 0] - m[2, 2]) * 2
        q = [(m[0, 1] + m[1, 0]) / s, s / 4, (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    else:
        s = math.sqrt(1 + m[2, 2] - m[0, 0] - m[1, 1]) * 2
        q = [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, s / 4, (m[1, 0] - m[0, 1]) / s]
    q = np.array(q)
    q /= np.linalg.norm(q)
    if q[3] < 0:
        q = -q
    return q


def skin_influences(ch):
    """4 os (indices dans l'ordre des os du squelette) et 4 poids (octets,
    somme 255) par sommet, depuis les groupes de sommets du FBX."""
    import numpy as np
    col_bone = np.array([ch.index[g] for g in ch.groups])
    order = np.argsort(-ch.W, axis=1)[:, :INFLUENCES]
    w = np.take_along_axis(ch.W, order, axis=1)
    s = w.sum(1, keepdims=True)
    s[s == 0] = 1
    w = w / s
    q = np.floor(w * 255 + .5).astype(np.int64)
    # somme exacte 255 : l'écart va au plus fort
    q[:, 0] += 255 - q.sum(1)
    joints = col_bone[order]
    joints[q == 0] = 0
    return joints.astype(np.uint8), q.astype(np.uint8)


def zone_of_triangles(Pd, F, static_glb=STATIC_GLB):
    """Nom de nœud de chaque triangle, repris du GLB fixe (même maillage)."""
    import numpy as np
    from scipy.spatial import cKDTree
    import build_character as bc
    meshes = bc.read_glb(static_glb)
    names, centres = [], []
    for name, (p, f) in meshes.items():
        centres.append(p[f].mean(axis=1))
        names += [name] * len(f)
    centres = np.concatenate(centres)
    names = np.array(names, dtype=object)
    if len(centres) != len(F):
        raise SystemExit(f'GLB fixe : {len(centres)} triangles, personnage : {len(F)}')
    d, i = cKDTree(centres).query(Pd[F].mean(axis=1))
    if d.max() > MATCH_TOLERANCE or len(set(i)) != len(F):
        raise SystemExit(f'Zones non retrouvées : écart max {d.max() * 1000:.3f} mm, '
                         f'{len(set(i))} triangles distincts sur {len(F)}')
    return names[i], float(d.max())


def build(log=print):
    import numpy as np
    import build_character as bc
    import build_model
    if bc.sha256(bc.FBX) != bc.FBX_SHA256:
        raise SystemExit('FBX inattendu')
    ch = bc.load_character()
    ch.V, _ = bc.smooth_seams(ch, log=lambda *_: None)
    Vfit = ch.V + bc.fit_displacement(ch)
    Pd = bc.skin(ch, Vfit, bc.DISPLAY_POSE)
    names, gap = zone_of_triangles(Pd, ch.F)
    log(f'zones reprises du GLB fixe : {len(set(names))} nœuds, écart max {gap * 1000:.4f} mm')
    normals = bc.vertex_normals(Vfit, ch.F)
    joints, weights = skin_influences(ch)
    meshes = []
    for name in sorted(set(names)):
        faces = ch.F[names == name]
        used, inv = np.unique(faces, return_inverse=True)
        meshes.append({'nom': name, 'positions': Vfit[used], 'normales': normals[used],
                       'indices': inv.reshape(-1, 3).ravel(),
                       'joints': joints[used], 'poids': weights[used]})
    write_glb(OUT_GLB, meshes, ch.bones)
    OUT_SKIN.write_bytes(b''.join(
        np.hstack([m['joints'], m['poids']]).astype(np.uint8).tobytes() for m in meshes))
    write_rig(ch, meshes)
    report = {'noeuds': len(meshes), 'sommets': int(sum(len(m['positions']) for m in meshes)),
              'triangles': int(len(ch.F)), 'os': len(ch.bones),
              'glb_octets': OUT_GLB.stat().st_size, 'peau_octets': OUT_SKIN.stat().st_size,
              'ecart_zones_mm': round(gap * 1000, 5)}
    log(json.dumps(report, ensure_ascii=False))
    return report


def write_rig(ch, meshes):
    """Squelette au format de `MannequinRig.fromJson` (application)."""
    import numpy as np
    import build_character as bc
    display = {}
    for name, rots in bc.DISPLAY_POSE.items():
        R = np.eye(3)
        for axis, deg in rots:
            R = bc.rot(axis, deg) @ R
        display[name] = [round(float(v), 6) for v in quat_of(R)]
    data = {
        'schema': 1,
        'source': 'tools/anatomy/build_animated.py (M7) : squelette Mixamo « Ch36 » '
                  '(mixamorig1:, 65 os), pose de repos en T',
        'repere': 'glTF : y en haut, avant = +z, gauche anatomique = +x ; mètres ; '
                  'pose = rotation locale (repère du corps) autour de la tête de chaque os',
        'os': [{'nom': b['name'], 'nom_fr': b['name'], 'parent': b['parent'],
                'tete': [round(float(x), 6) for x in b['head']]} for b in ch.bones],
        'postures': {
            'affichage': {'nom': 'Pose d\'affichage (bras abaissés)', 'app': False,
                          'rotations': display, 'translation': [0, 0, 0]},
        },
        'peau': {'fichier': 'assets/anatomy/peau_mixamo.bin',
                 'format': '4 os puis 4 poids (octets, somme 255) par sommet, maillages dans '
                           'l\'ordre ci-dessous',
                 'maillages': [{'nom': m['nom'], 'sommets': int(len(m['positions']))}
                               for m in meshes]},
    }
    OUT_RIG.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


def write_glb(path, meshes, bones):
    """GLB avec peau : un nœud par zone (repos en T), nœuds d'os `j_<os>`
    (même écriture que le rig de M5, validée sur flutter_scene)."""
    import numpy as np
    import struct
    import build_character as bc
    chunks, views, accessors = [], [], []
    offset = 0

    def add(arr, target, **acc):
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
    for k, m in enumerate(meshes):
        pos = m['positions'].astype(np.float32)
        attrs = {
            'POSITION': add(pos, 34962, componentType=5126, count=len(pos), type='VEC3',
                            min=[float(v) for v in pos.min(0)],
                            max=[float(v) for v in pos.max(0)]),
            'NORMAL': add(m['normales'].astype(np.float32), 34962, componentType=5126,
                          count=len(pos), type='VEC3'),
            'JOINTS_0': add(m['joints'].astype(np.uint8), 34962, componentType=5121,
                            count=len(pos), type='VEC4'),
            'WEIGHTS_0': add(m['poids'].astype(np.uint8), 34962, componentType=5121,
                             normalized=True, count=len(pos), type='VEC4'),
        }
        idx = m['indices']
        itype = 5125 if idx.max() > 65535 else 5123
        ind = add(idx.astype(np.uint32 if itype == 5125 else np.uint16), 34963,
                  componentType=itype, count=len(idx), type='SCALAR')
        dark = m['nom'] == 'head' or m['nom'].startswith(('hand_', 'foot_'))
        gl_meshes.append({'name': m['nom'], 'primitives': [
            {'attributes': attrs, 'indices': ind, 'material': 1 if dark else 0}]})
        nodes.append({'name': m['nom'], 'mesh': k, 'skin': 0})
    j0 = len(meshes)
    heads = {b['name']: b['head'] for b in bones}
    for b in bones:
        p = b['parent']
        t = heads[b['name']] if p is None else heads[b['name']] - heads[p]
        node = {'name': 'j_' + b['name'], 'translation': [float(v) for v in t]}
        kids = [j0 + i for i, c in enumerate(bones) if c['parent'] == b['name']]
        if kids:
            node['children'] = kids
        nodes.append(node)
    roots = [j0 + i for i, b in enumerate(bones) if b['parent'] is None]
    ibm = np.zeros((len(bones), 16), dtype=np.float32)
    for i, b in enumerate(bones):
        m = np.eye(4)
        m[:3, 3] = -np.asarray(b['head'])
        ibm[i] = m.T.reshape(-1)   # colonnes
    ibm_acc = add(ibm, None, componentType=5126, count=len(ibm), type='MAT4')
    gltf = {
        'asset': {'version': '2.0',
                  'generator': 'Kalis Track tools/anatomy/build_animated.py (M7)'},
        'scene': 0,
        'scenes': [{'name': 'Mannequin animable', 'nodes': list(range(len(meshes))) + roots}],
        'nodes': nodes, 'meshes': gl_meshes, 'materials': bc.MATERIALS,
        'skins': [{'name': 'mixamo', 'skeleton': roots[0], 'inverseBindMatrices': ibm_acc,
                   'joints': [j0 + i for i in range(len(bones))]}],
        'accessors': accessors, 'bufferViews': views, 'buffers': [{'byteLength': offset}],
    }
    js = json.dumps(gltf, separators=(',', ':')).encode()
    js += b' ' * ((-len(js)) % 4)
    blob = b''.join(chunks)
    with open(path, 'wb') as f:
        f.write(struct.pack('<4sII', b'glTF', 2, 12 + 8 + len(js) + 8 + len(blob)))
        f.write(struct.pack('<I4s', len(js), b'JSON'))
        f.write(js)
        f.write(struct.pack('<I4s', len(blob), b'BIN\0'))
        f.write(blob)


def check():
    """Sorties suivies cohérentes (sans la source)."""
    rig = json.loads(OUT_RIG.read_text(encoding='utf-8'))
    assert len(rig['os']) == 65, 'squelette : 65 os attendus'
    names = [b['nom'] for b in rig['os']]
    seen = set()
    for b in rig['os']:
        assert b['parent'] is None or b['parent'] in seen, f'parent après l\'enfant : {b["nom"]}'
        seen.add(b['nom'])
    skel = json.loads((ROOT / 'assets/anatomy/squelette_mixamo.json').read_text(encoding='utf-8'))
    assert names == [b['nom'] for b in skel['os']], 'ordre des os différent du squelette M6c'
    mp = json.loads((ROOT / 'assets/anatomy/muscles_map.json').read_text(encoding='utf-8'))
    nodes = {m['nom'] for m in rig['peau']['maillages']}
    assert {r['id'] for r in mp['regions']} <= nodes, 'zones de la carte absentes du mannequin animable'
    n = sum(m['sommets'] for m in rig['peau']['maillages'])
    data = OUT_SKIN.read_bytes()
    assert len(data) == n * 8, 'peau : taille inattendue'
    for v in range(n):
        o = v * 8
        assert sum(data[o + 4:o + 8]) == 255, f'poids du sommet {v} : somme ≠ 255'
        assert max(data[o:o + 4]) < 65
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if args.check:
        print('OK' if check() else 'KO')
        return
    build()


if __name__ == '__main__':
    main()
