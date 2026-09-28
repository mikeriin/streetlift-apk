# -*- coding: utf-8 -*-
"""M5 (mannequin 3D) : squelette d'animation et peau, vérifiés sans Blender ni
numpy (bibliothèque standard seulement) : os, parents, longueurs constantes
dans toutes les postures, limites articulaires respectées, poids normalisés,
aucun sommet sans poids, os du modèle rigides, GLB riggé cohérent avec
rig.json et le fichier de peau, pas de déchirure entre maillages voisins."""
import json
import math
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))

import rig_def  # noqa: E402

GLB = ROOT / 'assets' / 'anatomy' / 'mannequin.glb'
RIG = ROOT / 'assets' / 'anatomy' / 'rig.json'
SKIN = ROOT / 'assets' / 'anatomy' / 'mannequin_skin.bin'
APP_POSTURES = ['debout', 'suspendu', 'squat_bas', 'planche']
CONTROL_POSTURES = ['bras_leves', 'bras_extension', 'coude_150', 'hanche_120',
                    'rachis_flexion', 'rachis_extension', 'rachis_rotation', 'dips_bas']


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack('<4sII', data[:12])
    assert magic == b'glTF' and version == 2 and length == len(data)
    jlen, _ = struct.unpack('<I4s', data[12:20])
    gltf = json.loads(data[20:20 + jlen])
    rest = 20 + jlen
    blen, _ = struct.unpack('<I4s', data[rest:rest + 8])
    return gltf, data[rest + 8:rest + 8 + blen]


def accessor(gltf, blob, index):
    acc = gltf['accessors'][index]
    view = gltf['bufferViews'][acc['bufferView']]
    fmt = {5126: 'f', 5125: 'I', 5123: 'H', 5121: 'B'}[acc['componentType']]
    width = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[acc['type']]
    start = view.get('byteOffset', 0) + acc.get('byteOffset', 0)
    n = acc['count'] * width
    vals = struct.unpack_from('<%d%s' % (n, fmt), blob, start)
    return [vals[i:i + width] for i in range(0, n, width)] if width > 1 else list(vals)


def dist(a, b):
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))


class M5RigTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.rig = json.loads(RIG.read_text(encoding='utf-8'))
        cls.gltf, cls.blob = read_glb(GLB)
        cls.bones = {b['nom']: b for b in cls.rig['os']}
        cls.order = [b['nom'] for b in cls.rig['os']]
        cls.meshes = []
        for node in cls.gltf['nodes']:
            if 'mesh' in node:
                prim = cls.gltf['meshes'][node['mesh']]['primitives'][0]
                cls.meshes.append((node, prim))
        # Influences du fichier de peau, par maillage.
        data = SKIN.read_bytes()
        cls.skin, offset = {}, 0
        for m in cls.rig['peau']['maillages']:
            n = m['sommets']
            block = data[offset:offset + 8 * n]
            cls.skin[m['nom']] = [(block[8 * i:8 * i + 4], block[8 * i + 4:8 * i + 8])
                                  for i in range(n)]
            offset += 8 * n
        cls.skin_size = offset
        cls.skin_bytes = len(data)

    def test_os_et_parents(self):
        self.assertLessEqual(len(self.order), rig_def.MAX_BONES)
        self.assertEqual(len(self.order), len(set(self.order)))
        seen = set()
        for b in self.rig['os']:
            if b['parent'] is not None:
                self.assertIn(b['parent'], seen, f"{b['nom']} avant son parent")
            seen.add(b['nom'])
            self.assertAlmostEqual(b['longueur'], dist(b['tete'], b['queue']), places=4)
            self.assertGreater(b['longueur'], .01, b['nom'])
        self.assertEqual([b['nom'] for b in self.rig['os'] if b['parent'] is None], ['pelvis'])
        # Segments demandés par le lot : bassin, 3 segments de rachis, cou,
        # tête, clavicules, scapulas, bras, avant-bras (ulna + radius), mains,
        # 2 os de doigts, cuisses, jambes, pieds, orteils.
        for name in ('pelvis', 'lumbar', 'thoracic_low', 'thoracic_high', 'neck', 'head'):
            self.assertIn(name, self.bones)
        for side in 'lr':
            for name in ('clavicle', 'scapula', 'upperarm', 'forearm', 'radius', 'hand',
                         'fingers1', 'fingers2', 'thigh', 'shin', 'foot', 'toes'):
                self.assertIn(f'{name}_{side}', self.bones)
        # Symétrie gauche / droite des têtes.
        for name, b in self.bones.items():
            if name.endswith('_l'):
                r = self.bones[name[:-2] + '_r']['tete']
                self.assertAlmostEqual(b['tete'][0], -r[0], places=4)
                self.assertAlmostEqual(b['tete'][1], r[1], places=4)

    def test_axes_limites_et_sources(self):
        for b in self.rig['os']:
            for d in b['ddl']:
                self.assertLess(d['min'], d['max'], (b['nom'], d['cle']))
                self.assertAlmostEqual(math.sqrt(sum(a * a for a in d['axe'])), 1, places=3)
                self.assertTrue(d['source'], (b['nom'], d['cle']))
            if 'aide' in b:
                self.assertEqual(b['ddl'], [])
                self.assertIn(b['aide']['suit'], self.bones)

    def test_postures(self):
        postures = self.rig['postures']
        self.assertEqual([k for k, p in postures.items() if p['app']], APP_POSTURES)
        for k in CONTROL_POSTURES:
            self.assertIn(k, postures)
        self.assertEqual(postures['debout']['rotations'], {})
        self.assertEqual(postures['debout']['translation'], [0.0, 0.0, 0.0])

    def test_limites_respectees(self):
        for key, p in self.rig['postures'].items():
            for bone, angles in p['angles'].items():
                dofs = {d['cle']: d for d in self.bones[bone]['ddl']}
                for k, a in angles.items():
                    self.assertIn(k, dofs, (key, bone))
                    self.assertGreaterEqual(a, dofs[k]['min'] - 1e-6, (key, bone, k))
                    self.assertLessEqual(a, dofs[k]['max'] + 1e-6, (key, bone, k))
            # Part glénohumérale bornée (rythme scapulo-huméral).
            for side in 'lr':
                q = p['rotations'].get('upperarm_' + side)
                if q:
                    self.assertLessEqual(rig_def.q_angle(q), rig_def.GH_MAX + 1e-6, key)

    def test_rotations_recalculees(self):
        # Les quaternions du fichier sont ceux des angles anatomiques.
        dofs = {b['nom']: b['ddl'] for b in self.rig['os']}
        for key, p in self.rig['postures'].items():
            rots = rig_def.posture_rotations(dofs, p['angles'])
            for bone, q in p['rotations'].items():
                r = rots[bone]
                dot = abs(sum(q[i] * r[i] for i in range(4)))
                self.assertAlmostEqual(dot, 1, places=5, msg=(key, bone))

    def test_longueurs_constantes(self):
        heads = {b['nom']: b['tete'] for b in self.rig['os']}
        for key, p in self.rig['postures'].items():
            rots = {k: tuple(v) for k, v in p['rotations'].items()}
            g = rig_def.forward_kinematics(self.rig, rots, p['translation'])
            posed = {b: (g[b][0][3], g[b][1][3], g[b][2][3]) for b in g}
            for b in self.rig['os']:
                par = b['parent']
                if par:
                    self.assertAlmostEqual(dist(posed[b['nom']], posed[par]),
                                           dist(heads[b['nom']], heads[par]), places=6)
                self.assertLess(dist(posed[b['nom']], p['tetes'][b['nom']]), 1e-4)
            # Rotations pures (matrices orthonormées), sauf les os d'aide et
            # de gonflement à échelle (M56), qui gonflent avec la flexion.
            scaled = {b['nom'] for b in self.rig['os'] if b.get('aide', {}).get('gonflement')}
            for name, m in g.items():
                if name in scaled:
                    continue
                for i in range(3):
                    self.assertAlmostEqual(sum(m[i][k] ** 2 for k in range(3)), 1, places=6)

    def test_glb_rigge(self):
        gltf = self.gltf
        self.assertEqual(len(gltf['skins']), 1)
        skin = gltf['skins'][0]
        names = [gltf['nodes'][j]['name'] for j in skin['joints']]
        self.assertEqual(names, ['j_' + n for n in self.order])
        ibm = accessor(gltf, self.blob, skin['inverseBindMatrices'])
        for m, b in zip(ibm, self.rig['os']):
            for i in range(3):
                self.assertAlmostEqual(m[12 + i], -b['tete'][i], places=5)
            self.assertEqual([round(m[k], 6) for k in (0, 5, 10, 15)], [1, 1, 1, 1])
        for node, _ in self.meshes:
            self.assertEqual(node.get('skin'), 0, node['name'])
            self.assertNotIn('translation', node)
        # Articulations au repos : translation seule.
        for j in skin['joints']:
            self.assertNotIn('rotation', gltf['nodes'][j])

    def test_poids_normalises_sans_sommet_orphelin(self):
        self.assertEqual(self.skin_size, self.skin_bytes)
        order = [m['nom'] for m in self.rig['peau']['maillages']]
        self.assertEqual(order, [n['name'] for n, _ in self.meshes])
        for node, prim in self.meshes:
            name = node['name']
            joints = accessor(self.gltf, self.blob, prim['attributes']['JOINTS_0'])
            weights = accessor(self.gltf, self.blob, prim['attributes']['WEIGHTS_0'])
            self.assertTrue(self.gltf['accessors'][prim['attributes']['WEIGHTS_0']]['normalized'])
            infl = self.skin[name]
            self.assertEqual(len(infl), len(joints), name)
            for (fj, fw), j, w in zip(infl, joints, weights):
                self.assertEqual(tuple(fj), tuple(j), name)
                self.assertEqual(tuple(fw), tuple(w), name)
                self.assertEqual(sum(w), 255, name)
                self.assertTrue(all(x < len(self.order) for x in j), name)

    def test_os_rigides(self):
        for fj, fw in self.skin['os']:
            self.assertEqual(fw[0], 255)
        # Mains, pieds et tête dans leurs segments.
        for name, allowed in (('head', {'head', 'neck'}),
                              ('hand_left', {'forearm_l', 'radius_l', 'hand_l', 'fingers1_l',
                                             'fingers2_l', 'elbow_aux_l', 'pronation_aux_l'}),
                              ('foot_right', {'shin_r', 'foot_r', 'toes_r'})):
            used = {self.order[j] for fj, fw in self.skin[name] for j, w in zip(fj, fw) if w}
            self.assertLessEqual(used, allowed, name)

    def _posed(self, key):
        p = self.rig['postures'][key]
        rots = {k: tuple(v) for k, v in p['rotations'].items()}
        g = rig_def.forward_kinematics(self.rig, rots, p['translation'])
        mats = rig_def.skinning_matrices(self.rig, g)
        mlist = [mats[b] for b in self.order]
        out = {}
        for node, prim in self.meshes:
            pos = accessor(self.gltf, self.blob, prim['attributes']['POSITION'])
            res = []
            for p0, (fj, fw) in zip(pos, self.skin[node['name']]):
                x = y = z = 0.0
                for j, w in zip(fj, fw):
                    if not w:
                        continue
                    m = mlist[j]
                    f = w / 255
                    x += f * (m[0][0] * p0[0] + m[0][1] * p0[1] + m[0][2] * p0[2] + m[0][3])
                    y += f * (m[1][0] * p0[0] + m[1][1] * p0[1] + m[1][2] * p0[2] + m[1][3])
                    z += f * (m[2][0] * p0[0] + m[2][1] * p0[1] + m[2][2] * p0[2] + m[2][3])
                res.append((x, y, z))
            out[node['name']] = (pos, res)
        return out

    def test_repos_identique(self):
        posed = self._posed('debout')
        for name, (rest, res) in posed.items():
            for a, b in zip(rest, res):
                self.assertLess(dist(a, b), 1e-5, name)

    def test_pas_de_dechirure(self):
        """Sommets de maillages musculaires différents qui se touchent au
        repos (≤ 2 mm) : écart après déformation borné (glissement d'un
        muscle sur l'autre, jamais d'ouverture)."""
        rest = self._posed('debout')
        cell = .004
        grid = {}
        for name, (pos, _) in rest.items():
            if name == 'os':
                continue
            for i, p in enumerate(pos):
                grid.setdefault(tuple(int(math.floor(c / cell)) for c in p), []).append((name, i))
        pairs = []
        for key, items in grid.items():
            near = []
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    for dz in (-1, 0, 1):
                        near += grid.get((key[0] + dx, key[1] + dy, key[2] + dz), [])
            for a in items:
                pa = rest[a[0]][0][a[1]]
                for b in near:
                    # M56 : les deux côtés d'un même muscle (adducteurs,
                    # grands dorsaux…) se touchent au repos sur la ligne
                    # médiane et s'écartent quand les membres s'ouvrent :
                    # pas une déchirure.
                    if b[0] > a[0] and dist(pa, rest[b[0]][0][b[1]]) <= .002 \
                            and a[0].rsplit('_', 1)[0] != b[0].rsplit('_', 1)[0]:
                        pairs.append((a, b))
        self.assertGreater(len(pairs), 500)
        limits = {'suspendu': .03, 'squat_bas': .025, 'planche': .02}
        for key, p99 in limits.items():
            posed = self._posed(key)
            gaps = sorted(dist(posed[a[0]][1][a[1]], posed[b[0]][1][b[1]]) for a, b in pairs)
            self.assertLess(gaps[int(len(gaps) * .99)], p99, key)
            # M56 : muscles plus volumineux ; bras levés, le coraco-brachial
            # (bras) quitte le bord latéral du grand dorsal (tronc) : 8,4 cm.
            self.assertLess(gaps[-1], .10, key)


if __name__ == '__main__':
    unittest.main()
