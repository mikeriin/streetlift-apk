# -*- coding: utf-8 -*-
"""M2 (mannequin 3D) : sorties de tools/anatomy/build_model.py vérifiées sans
Blender (bibliothèque standard seulement) : SHA-256 de la source, budget de
triangles lu dans le GLB, nœuds du GLB ↔ régions de la carte, groupes,
correspondance avec les muscles du pack, crédits CC BY-SA."""
import hashlib
import json
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))

import anatomy_data  # noqa: E402
import build_model  # noqa: E402  (n'importe bpy que pour fabriquer)

GLB = ROOT / 'assets' / 'anatomy' / 'mannequin.glb'
# Muscles du pack sans pièce dans le modèle source (lib/exercise_mannequin.dart,
# `musclesSansRegion`).
ABSENTS_DU_MODELE = {'flechisseurs_cervicaux_profonds', 'diaphragme', 'plancher_pelvien'}
MAP = ROOT / 'assets' / 'anatomy' / 'muscles_map.json'
ATTRIBUTION = ROOT / 'assets' / 'anatomy' / 'ATTRIBUTION.md'


def read_glb(path):
    data = path.read_bytes()
    magic, version, length = struct.unpack('<4sII', data[:12])
    assert magic == b'glTF' and version == 2 and length == len(data)
    chunk_len, chunk_type = struct.unpack('<I4s', data[12:20])
    assert chunk_type == b'JSON'
    return json.loads(data[20:20 + chunk_len])


def triangles(gltf):
    total = {}
    for node in gltf['nodes']:
        if 'mesh' not in node:
            continue
        count = 0
        for prim in gltf['meshes'][node['mesh']]['primitives']:
            assert prim.get('mode', 4) == 4, 'triangles seulement'
            count += gltf['accessors'][prim['indices']]['count'] // 3
        total[node['name']] = count
    return total


class M2AnatomyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gltf = read_glb(GLB)
        cls.map = json.loads(MAP.read_text(encoding='utf-8'))
        cls.tris = triangles(cls.gltf)
        cls.pack = anatomy_data.pack_muscles()

    def test_source_sha256(self):
        self.assertTrue(build_model.check_source())
        for name, expected in build_model.SOURCE_SHA256.items():
            digest = hashlib.sha256((ANATOMY / 'source' / name).read_bytes()).hexdigest()
            self.assertEqual(digest, expected, name)
        self.assertEqual(self.map['source']['sha256'],
                         build_model.SOURCE_SHA256['full-body-male-mobile.glb'])
        self.assertEqual(self.map['source']['commit'], build_model.SOURCE_COMMIT)

    def test_budget_de_triangles(self):
        total = sum(self.tris.values())
        self.assertLessEqual(total, build_model.TRIANGLE_BUDGET)
        self.assertEqual(total, self.map['triangles'])
        # Tous les nœuds ont une géométrie non vide.
        for name, count in self.tris.items():
            self.assertGreater(count, 0, name)

    def test_noeuds_et_regions(self):
        regions = {r['id'] for r in self.map['regions']}
        nodes = set(self.tris)
        self.assertEqual(nodes - regions, {'os', 'contexte', 'head'})
        self.assertEqual(regions - nodes, set())
        self.assertEqual(len(regions), len(self.map['regions']), 'ids uniques')
        removed = {r['id'] for r in self.map['retirees']}
        self.assertFalse(removed & nodes)
        for r in self.map['retirees']:
            self.assertEqual(r['raison'], 'profond, invisible au repos')
        # M4b : plus aucune région retirée ; toutes les régions de la source
        # sont dans le modèle, plus le platysma (gauche et droit).
        self.assertEqual(self.map['retirees'], [])
        source = json.loads((ANATOMY / 'source' / 'full-body-map.json').read_text())
        for m in source['muscles']:
            self.assertIn(m['id'], nodes, m['id'])
        self.assertLessEqual({'platysma_left', 'platysma_right'}, nodes)

    def test_aucune_region_sans_groupe(self):
        self.assertEqual(self.map['groupes'], anatomy_data.APP_GROUPS)
        for r in self.map['regions']:
            self.assertIn(r['groupe'], anatomy_data.APP_GROUPS, r['id'])
            self.assertTrue(r['nom'], r['id'])
            self.assertIn(r['cote'], ('left', 'right'))
        for group in anatomy_data.APP_GROUPS:
            self.assertTrue(any(r['groupe'] == group for r in self.map['regions']), group)

    def test_muscles_du_pack(self):
        covered = {p for r in self.map['regions'] for p in r['pack']}
        self.assertTrue(covered <= set(self.pack), covered - set(self.pack))
        superficial = {k for k, (_, depth) in self.pack.items() if depth == 'superficiel'}
        self.assertEqual(superficial - covered, set(), 'muscle visible sans région')
        # M4b : chaque muscle du pack a au moins une région, profonds compris,
        # sauf ceux qu'aucune pièce du modèle source ne représente.
        self.assertEqual(set(self.pack) - covered, ABSENTS_DU_MODELE)
        # Groupe d'une région = groupe de son (premier) muscle du pack.
        for r in self.map['regions']:
            if r['pack']:
                self.assertEqual(r['groupe'], self.pack[r['pack'][0]][0], r['id'])

    def test_couches(self):
        # M4b : chaque région porte sa couche.
        by_id = {r['id']: r for r in self.map['regions']}
        for r in self.map['regions']:
            expected = 'volume' if r['id'] in ('hand_left', 'hand_right',
                                               'foot_left', 'foot_right') else None
            if expected:
                self.assertEqual(r['couche'], expected, r['id'])
            else:
                self.assertIn(r['couche'], ('superficiel', 'profond'), r['id'])
        hidden = self.map['caches_au_repos']
        # Les 21 paires cachées au repos (retirées de M2 à M4) : profondes.
        self.assertEqual(len(hidden), 42)
        for rid in hidden:
            self.assertEqual(by_id[rid]['couche'], 'profond', rid)
        for rid in ('rhomboid_major_left', 'rhomboid_minor_right', 'subscapularis_left',
                    'vastus_intermedius_right', 'pectoralis_minor_left'):
            self.assertEqual(by_id[rid]['couche'], 'profond', rid)
        for rid in ('latissimus_dorsi_left', 'trapezius_middle_right',
                    'rectus_femoris_left', 'platysma_left'):
            self.assertEqual(by_id[rid]['couche'], 'superficiel', rid)
        platysma = by_id['platysma_right']
        self.assertEqual((platysma['nom'], platysma['groupe'], platysma['pack']),
                         ('Platysma', 'dos', []))

    def test_budget_profonds(self):
        # M4b : ≤ 75 000 triangles ; muscles cachés au repos plus décimés.
        self.assertLessEqual(sum(self.tris.values()), 75000)
        report = json.loads((ANATOMY / 'build_report.json').read_text(encoding='utf-8'))
        self.assertEqual(report['triangles']['total'], sum(self.tris.values()))
        hidden = set(self.map['caches_au_repos'])
        self.assertEqual(report['triangles']['muscles_caches'],
                         sum(self.tris[n] for n in hidden))
        for n in hidden:
            self.assertGreaterEqual(self.tris[n], 40, n)

    def test_noms_francais(self):
        for key in anatomy_data.model_groups():
            self.assertIn(key, anatomy_data.FR)
            self.assertIn(key, anatomy_data.PACK_OF_KEY)

    def test_credits(self):
        text = ATTRIBUTION.read_text(encoding='utf-8')
        for line in ('"Z-Anatomy - The libre 3D atlas of anatomy - CC-BY-SA 4.0"',
                     '"BodyParts3D - The Database Center for Life Science - CC-BY-SA 2.1 Japan"',
                     'https://creativecommons.org/licenses/by-sa/4.0/',
                     build_model.SOURCE_COMMIT):
            self.assertIn(line, text)
        source = (ANATOMY / 'source' / 'ATTRIBUTION.txt').read_text(encoding='utf-8')
        self.assertIn('Z-Anatomy - The libre 3D atlas of anatomy - CC-BY-SA 4.0', source)
        self.assertTrue((ANATOMY / 'source' / 'LICENSE.txt').is_file())

    def test_pubspec(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for asset in ('assets/anatomy/muscles_map.json', 'assets/anatomy/ATTRIBUTION.md',
                      'flutter_scene_generated/'):
            self.assertIn(f'    - {asset}\n', pubspec)
        # Le GLB passe par le build hook, pas par la liste des ressources.
        self.assertNotIn('- assets/anatomy/mannequin.glb', pubspec)
        self.assertNotIn('- assets/anatomy/\n', pubspec)
        hook = (ROOT / 'hook' / 'build.dart').read_text(encoding='utf-8')
        self.assertIn("'assets/anatomy/mannequin.glb'", hook)


if __name__ == '__main__':
    unittest.main()
