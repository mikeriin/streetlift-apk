# -*- coding: utf-8 -*-
"""M2 → M56 correction 2 (mannequin 3D) : sorties de
tools/anatomy/build_model.py vérifiées sans la source (bibliothèque
standard seulement) : budget de triangles lu dans le GLB, nœuds du GLB ↔
régions de la carte, groupes, correspondance avec les muscles du pack,
subdivisions, crédits de l'écorché acheté (jamais dans le dépôt)."""
import json
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))

import anatomy_data  # noqa: E402
import build_model  # noqa: E402  (n'importe numpy que pour fabriquer)

GLB = ROOT / 'assets' / 'anatomy' / 'mannequin.glb'
MAP = ROOT / 'assets' / 'anatomy' / 'muscles_map.json'
ATTRIBUTION = ROOT / 'assets' / 'anatomy' / 'ATTRIBUTION.md'
# Muscles du pack sans pièce dans l'écorché (lib/exercise_mannequin.dart,
# `musclesSansRegion`) : internes ou profonds, couverts par d'autres.
ABSENTS_DU_MODELE = {
    'flechisseurs_cervicaux_profonds', 'diaphragme', 'plancher_pelvien',
    'biceps_femoral_chef_court', 'carre_des_lombes', 'carre_pronateur',
    'court_adducteur', 'flechisseurs_profonds_des_doigts', 'multifides',
    'oblique_interne', 'petit_fessier', 'petit_pectoral', 'poplite',
    'rotateurs_lateraux_hanche', 'sous_scapulaire', 'supinateur', 'supra_epineux',
    'tibial_posterieur', 'transverse_abdomen', 'vaste_intermediaire',
}


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

    def test_source_hors_depot(self):
        # L'archive achetée n'est jamais dans le dépôt ; la carte cite son
        # empreinte pour retrouver la bonne release.
        for p in ROOT.rglob('*.zip'):
            self.assertNotIn(p.name, ('Archive.zip',), p)
        self.assertEqual(len(self.map['source']['sha256']), 64)
        self.assertEqual(self.map['schema'], 2)
        self.assertNotIn('CC-BY-SA', self.map['source']['licence'])
        self.assertFalse((ANATOMY / 'source').exists())
        for old in ('rig.json', 'mannequin_skin.bin'):
            self.assertFalse((ROOT / 'assets' / 'anatomy' / old).exists(), old)

    def test_budget_de_triangles(self):
        total = sum(self.tris.values())
        self.assertLessEqual(total, build_model.TRIANGLE_BUDGET)
        self.assertEqual(total, self.map['triangles'])
        for name, count in self.tris.items():
            self.assertGreater(count, 0, name)
        # Pas de squelette ni de peau dans le GLB.
        self.assertNotIn('skins', self.gltf)
        for node in self.gltf['nodes']:
            self.assertFalse(node['name'].startswith('j_'), node['name'])

    def test_noeuds_et_regions(self):
        regions = {r['id'] for r in self.map['regions']}
        nodes = set(self.tris)
        tendons = {n for n in nodes if n.startswith('tendon_')}
        self.assertGreaterEqual(len(tendons), 20)
        self.assertEqual(nodes - regions - tendons, {'os', 'head'})
        self.assertEqual(regions - nodes, set())
        self.assertEqual(len(regions), len(self.map['regions']), 'ids uniques')
        self.assertEqual(self.map['retirees'], [])
        self.assertEqual(self.map['caches_au_repos'], [])
        # Chaque clé a ses deux côtés.
        keys = {}
        for r in self.map['regions']:
            keys.setdefault(r['cle'], set()).add(r['cote'])
        for key, sides in keys.items():
            self.assertEqual(sides, {'left', 'right'}, key)
        for key in ('deltoid_anterior', 'deltoid_lateral', 'deltoid_posterior',
                    'trapezius_upper', 'trapezius_middle', 'trapezius_lower',
                    'pectoralis_major_clavicular', 'pectoralis_major_sternocostal',
                    'pectoralis_major_abdominal', 'gastrocnemius_medial',
                    'gastrocnemius_lateral', 'latissimus_dorsi', 'rectus_abdominis',
                    'gluteus_maximus', 'rhomboids', 'erector_spinae', 'iliopsoas',
                    'biceps_brachii', 'triceps_brachii', 'hand_intrinsic', 'foot_intrinsic'):
            self.assertIn(key, keys, key)
        self.assertEqual({'hand_left', 'hand_right', 'foot_left', 'foot_right'},
                         {r['id'] for r in self.map['regions'] if r['couche'] == 'volume'})

    def test_symetrie(self):
        # Même muscle des deux côtés : nombre de triangles comparable.
        by_key = {}
        for r in self.map['regions']:
            by_key.setdefault(r['cle'], {})[r['cote']] = self.tris[r['id']]
        for key, sides in by_key.items():
            lo, hi = sorted(sides.values())
            self.assertLessEqual(hi, 2 * lo + 40, f'{key} : {sides}')

    def test_aucune_region_sans_groupe(self):
        self.assertEqual(self.map['groupes'], anatomy_data.APP_GROUPS)
        for r in self.map['regions']:
            self.assertIn(r['groupe'], anatomy_data.APP_GROUPS, r['id'])
            self.assertTrue(r['nom'], r['id'])
            self.assertIn(r['cote'], ('left', 'right'))
            self.assertIn(r['couche'], ('superficiel', 'volume'), r['id'])
        for group in anatomy_data.APP_GROUPS:
            self.assertTrue(any(r['groupe'] == group for r in self.map['regions']), group)

    def test_muscles_du_pack(self):
        covered = {p for r in self.map['regions'] for p in r['pack']}
        self.assertTrue(covered <= set(self.pack), covered - set(self.pack))
        superficial = {k for k, (_, depth) in self.pack.items() if depth == 'superficiel'}
        self.assertEqual(superficial - covered, set(), 'muscle visible sans région')
        self.assertEqual(set(self.pack) - covered, ABSENTS_DU_MODELE)
        self.assertEqual(set(self.map['muscles_sans_region']), ABSENTS_DU_MODELE)
        for r in self.map['regions']:
            if r['pack']:
                self.assertEqual(r['groupe'], self.pack[r['pack'][0]][0], r['id'])

    def test_rapport(self):
        report = json.loads((ANATOMY / 'build_report.json').read_text(encoding='utf-8'))
        self.assertEqual(report['triangles']['total'], sum(self.tris.values()))
        self.assertEqual(report['triangles']['par_noeud'], self.tris)
        self.assertEqual(report['source']['sha256'], self.map['source']['sha256'])
        self.assertEqual(report['regions'], len(self.map['regions']))

    def test_noms_francais(self):
        for key in anatomy_data.PACK_OF_KEY:
            self.assertIn(key, anatomy_data.FR)
        for r in self.map['regions']:
            self.assertEqual(r['nom'], anatomy_data.FR[r['cle']])
            self.assertEqual(r['pack'], anatomy_data.PACK_OF_KEY[r['cle']])

    def test_etiquettes(self):
        # Chaque abréviation lue sur la texture est connue (légende du
        # vendeur) et donne une région, un os, un tendon, la tête, une main,
        # un pied ou le cou.
        known = (build_model.KEY_OF.keys() | build_model.HEAD | build_model.BONE_LABELS
                 | build_model.TENDON_LABELS | build_model.HAND_LABELS
                 | build_model.FOOT_LABELS | build_model.NECK_LABELS | {'ADM', 'SM', 'C'})
        for abbr, x, y in build_model.LABELS:
            self.assertIn(abbr, known, abbr)
            self.assertTrue(0 <= x < 4096 and 0 <= y < 4096, abbr)
        self.assertGreater(len(build_model.LABELS), 200)

    def test_credits(self):
        text = ATTRIBUTION.read_text(encoding='utf-8')
        for line in ('Ecorche Musclenames Male Anatomy', 'licence commerciale',
                     'tools/anatomy/build_model.py'):
            self.assertIn(line, text)
        self.assertNotIn('CC-BY-SA 4.0"', text)

    def test_pubspec(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for asset in ('assets/anatomy/muscles_map.json', 'assets/anatomy/ATTRIBUTION.md',
                      'flutter_scene_generated/'):
            self.assertIn(f'    - {asset}\n', pubspec)
        self.assertNotIn('- assets/anatomy/mannequin.glb', pubspec)
        self.assertNotIn('- assets/anatomy/rig.json', pubspec)
        self.assertNotIn('- assets/anatomy/\n', pubspec)
        hook = (ROOT / 'hook' / 'build.dart').read_text(encoding='utf-8')
        self.assertIn("'assets/anatomy/mannequin.glb'", hook)


if __name__ == '__main__':
    unittest.main()
