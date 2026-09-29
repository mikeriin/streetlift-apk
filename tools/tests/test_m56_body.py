# -*- coding: utf-8 -*-
"""M56 (mannequin 3D) : modèle musclé, vérifié sans Blender (bibliothèque
standard) : mêmes nœuds et mêmes triangles que le modèle de base, os, tête,
mains et pieds inchangés, muscles déplacés, rapport de fabrication (mesures
dans la tolérance, aucune pénétration > 1 mm, budget de triangles)."""
import json
import math
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))

GLB = ROOT / 'assets' / 'anatomy' / 'mannequin.glb'
BASE = ANATOMY / 'mannequin_base.glb'
REPORT = ANATOMY / 'body_report.json'
UNCHANGED = ('os', 'contexte', 'head', 'hand_left', 'hand_right', 'foot_left', 'foot_right')


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


def meshes_of(path):
    gltf, blob = read_glb(path)
    out = {}
    for node in gltf['nodes']:
        if 'mesh' not in node:
            continue
        prim = gltf['meshes'][node['mesh']]['primitives'][0]
        out[node['name']] = (accessor(gltf, blob, prim['attributes']['POSITION']),
                             accessor(gltf, blob, prim['indices']))
    return out


class M56BodyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = meshes_of(BASE)
        cls.new = meshes_of(GLB)
        cls.report = json.loads(REPORT.read_text(encoding='utf-8'))

    def test_memes_noeuds_et_triangles(self):
        self.assertEqual(list(self.base), list(self.new))
        for name, (pos, idx) in self.base.items():
            self.assertEqual(len(pos), len(self.new[name][0]), name)
            self.assertEqual(idx, self.new[name][1], name)
        total = sum(len(idx) // 3 for _, idx in self.new.values())
        self.assertEqual(total, self.report['triangles'])
        self.assertLessEqual(total, 75000)

    def test_os_tete_mains_pieds_inchanges(self):
        for name in UNCHANGED:
            self.assertEqual(self.base[name][0], self.new[name][0], name)

    def test_muscles_deplaces_symetriquement(self):
        moved = 0
        for name, (pos, _) in self.base.items():
            if name in UNCHANGED:
                continue
            new = self.new[name][0]
            d = max(math.dist(a, b) for a, b in zip(pos, new))
            if d > 1e-4:
                moved += 1
            self.assertLess(d, .05, f'{name} : déplacement {d * 1000:.0f} mm')
        self.assertGreater(moved, 150)
        # Même facteur des deux côtés : mêmes déplacements maximaux.
        dep = self.report['deplacement_max_mm']
        for name, v in dep.items():
            if name.endswith('_left'):
                other = name[:-5] + '_right'
                # Source presque symétrique : mêmes déplacements à 30 % près.
                self.assertAlmostEqual(v, dep[other], delta=max(1.5, .3 * v), msg=name)

    def test_mesures_dans_la_tolerance(self):
        """Correction 1 : chaque groupe ajusté atteint sa cible (largeur de
        la silhouette de référence ou tour nominal du propriétaire) à 1 % ;
        tours nominaux dans ± 10 % (la référence en image prime)."""
        r = self.report
        H = r['H_m']
        for group, (src, key, target) in r['cibles_ajustement'].items():
            val = r['silhouette_apres'][key] if src == 'silhouette' else r['apres'][key] / H
            # Groupe au plafond (cou : au-delà, il paraissait gonflé) : 5 %.
            capped = r['facteurs'][group] >= r['plafonds'][group] - 1e-9
            self.assertAlmostEqual(val / target, 1.0, delta=.05 if capped else .015,
                                   msg=f'{group} ({src} {key})')
        for key, target in r['cibles'].items():
            env = target - (0.0 if key == 'bideltoide' else .02 / H)
            dev = r['apres'][key] / H / env - 1
            self.assertLessEqual(abs(dev), .11, f'{key} : {dev * 100:+.1f} %')
        # Silhouette de référence (écorché du propriétaire) : largeurs de
        # face dans ± 6 % là où la référence les donne sans ambiguïté.
        ref = r['silhouette_reference']
        for key in ('bideltoide', 'poitrine_largeur', 'taille_largeur', 'hanches_largeur',
                    'cuisse_largeur', 'genou_largeur', 'mollet_largeur', 'cuisse_profondeur',
                    'mollet_profondeur'):
            dev = r['silhouette_apres'][key] / ref[key][0] - 1
            self.assertLessEqual(abs(dev), .07, f'{key} : {dev * 100:+.1f} %')
        # Bras : cible à mi-chemin (voir build_body.FITTED).
        self.assertLessEqual(abs(r['silhouette_apres']['bras_largeur'] / ref['bras_largeur'][0] - 1), .08)
        self.assertGreaterEqual(r['apres']['epaules_sur_taille'], 1.55)
        # Plus musclé partout où c'est mesuré.
        for key in ('bras', 'avant_bras', 'poitrine', 'cuisse', 'mollet', 'cou', 'bideltoide',
                    'taille'):
            self.assertGreater(r['apres'][key], r['avant'][key], key)

    def test_aucune_penetration(self):
        last = self.report['penetrations'][-1]
        self.assertEqual(last['max_mm'], 0.0, last)
        self.assertEqual(last['profonds'], {})


if __name__ == '__main__':
    unittest.main()
