# -*- coding: utf-8 -*-
"""M2 → M6c (mannequin 3D) : sorties de tools/anatomy/build_character.py
(personnage Mixamo « Ch36 », zones musculaires projetées depuis l'écorché
acheté) vérifiées sans la source (bibliothèque standard seulement) : budget
de triangles lu dans le GLB d'exécution (déchiffré par
`tools/secure_assets.py decrypt` avant les tests, comme en CI), nœuds ↔
zones de la carte, symétrie, groupes, correspondance avec les muscles du
pack, « fit » mesuré, squelette Mixamo exposé au code, crédits.
L'écorché (tools/anatomy/build_model.py) reste la source des zones."""
import json
import math
import struct
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ANATOMY = ROOT / 'tools' / 'anatomy'
sys.path.insert(0, str(ANATOMY))
sys.path.insert(0, str(ROOT / 'tools'))

import anatomy_data  # noqa: E402
import build_character  # noqa: E402  (n'importe numpy / bpy que pour fabriquer)
import build_model  # noqa: E402
import release_security  # noqa: E402
import secure_assets  # noqa: E402

GLB = ROOT / 'assets' / 'anatomy' / 'mannequin.glb'
MAP = ROOT / 'assets' / 'anatomy' / 'muscles_map.json'
SKELETON = ROOT / 'assets' / 'anatomy' / 'squelette_mixamo.json'
ATTRIBUTION = ROOT / 'assets' / 'anatomy' / 'ATTRIBUTION.md'
# Muscles du pack sans zone sur la peau (lib/exercise_mannequin.dart,
# `musclesSansRegion`) : profonds ou internes, sous d'autres muscles.
ABSENTS_DU_MODELE = {
    'flechisseurs_cervicaux_profonds', 'diaphragme', 'plancher_pelvien',
    'biceps_femoral_chef_court', 'carre_des_lombes', 'carre_pronateur',
    'court_adducteur', 'flechisseurs_profonds_des_doigts', 'multifides',
    'oblique_interne', 'petit_fessier', 'petit_pectoral', 'poplite',
    'rotateurs_lateraux_hanche', 'sous_scapulaire', 'supinateur', 'supra_epineux',
    'tibial_posterieur', 'transverse_abdomen', 'vaste_intermediaire',
    # M6c : sous le trapèze, le deltoïde ou le grand pectoral sur une peau.
    'coraco_brachial', 'elevateur_scapula', 'extenseurs_cervicaux', 'rhomboides',
}
# Squelette Mixamo standard (préfixe `mixamorig1:` retiré) : 65 os.
MIXAMO_BONES = (
    ['Hips', 'Spine', 'Spine1', 'Spine2', 'Neck', 'Head', 'HeadTop_End']
    + [f'{s}{b}' for s in ('Left', 'Right') for b in (
        ['Shoulder', 'Arm', 'ForeArm', 'Hand']
        + [f'Hand{f}{i}' for f in ('Thumb', 'Index', 'Middle', 'Ring', 'Pinky')
           for i in range(1, 5)])]
    + [f'{s}{b}' for s in ('Left', 'Right')
       for b in ('UpLeg', 'Leg', 'Foot', 'ToeBase', 'Toe_End')])


def read_glb(path):
    if not path.exists():
        raise AssertionError(
            f'{path.relative_to(ROOT)} absent : déchiffrer d\'abord les ressources sous '
            'licence (KT_ASSETS_KEY=… python3 tools/secure_assets.py decrypt).')
    data = path.read_bytes()
    magic, version, length = struct.unpack('<4sII', data[:12])
    assert magic == b'glTF' and version == 2 and length == len(data)
    chunk_len, chunk_type = struct.unpack('<I4s', data[12:20])
    assert chunk_type == b'JSON'
    return json.loads(data[20:20 + chunk_len]), data[20 + chunk_len + 8:]


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


class M6cCharacterTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gltf, cls.blob = read_glb(GLB)
        cls.map = json.loads(MAP.read_text(encoding='utf-8'))
        cls.tris = triangles(cls.gltf)
        cls.pack = anatomy_data.pack_muscles()
        cls.report = json.loads((ANATOMY / 'character_report.json').read_text(encoding='utf-8'))

    def test_ressources_chiffrees(self):
        # Aucun modèle sous licence en clair dans l'arbre suivi ; le GLB
        # d'exécution déchiffré est celui du manifeste.
        tracked = release_security.tracked_files(ROOT)
        for p in tracked:
            self.assertFalse(release_security.clear_model(p.as_posix()), p)
            self.assertNotEqual(p.name, 'Archive.zip', p)
        secure_assets.check([p.as_posix() for p in tracked], log=lambda *_: None)
        manifest = secure_assets.load_manifest()
        by_clear = {e['clair']: e for e in manifest['fichiers']}
        entry = by_clear['assets/anatomy/mannequin.glb']
        self.assertEqual(entry['role'], 'execution')
        self.assertEqual(secure_assets.sha256(GLB), entry['sha256'])
        self.assertEqual(by_clear['assets_secure/clair/character_mixamo_ch36.fbx']['sha256'],
                         build_character.FBX_SHA256)
        self.assertEqual(self.map['schema'], 3)
        self.assertEqual(self.map['source']['sha256'], build_character.FBX_SHA256)
        self.assertEqual(self.map['source']['zones_source'], 'ecorche')
        self.assertFalse((ANATOMY / 'source').exists())
        for old in ('rig.json', 'mannequin_skin.bin'):
            self.assertFalse((ROOT / 'assets' / 'anatomy' / old).exists(), old)

    def test_budget_de_triangles(self):
        total = sum(self.tris.values())
        self.assertLessEqual(total, build_character.TRIANGLE_BUDGET)
        self.assertEqual(total, self.map['triangles'])
        self.assertEqual(total, 28880)  # maillage du personnage, sans décimation
        for name, count in self.tris.items():
            self.assertGreater(count, 0, name)
        # Mannequin fixe : ni squelette ni peau dans le GLB (M7).
        self.assertNotIn('skins', self.gltf)
        self.assertNotIn('animations', self.gltf)
        self.assertEqual(len(self.gltf['materials']), 2)
        self.assertNotIn('images', self.gltf)  # textures d'origine retirées

    def test_noeuds_et_zones(self):
        regions = {r['id'] for r in self.map['regions']}
        nodes = set(self.tris)
        self.assertEqual(nodes - regions, {'peau', 'head'})
        self.assertEqual(regions - nodes, set())
        self.assertEqual(len(regions), len(self.map['regions']), 'ids uniques')
        self.assertEqual(self.map['retirees'], [])
        self.assertEqual(self.map['caches_au_repos'], [])
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
                    'external_oblique', 'gluteus_maximus', 'erector_spinae',
                    'biceps_brachii', 'triceps_brachii', 'rectus_femoris',
                    'vastus_lateralis', 'vastus_medialis', 'biceps_femoris_long',
                    'semitendinosus', 'soleus', 'tibialis_anterior',
                    'hand_intrinsic', 'foot_intrinsic'):
            self.assertIn(key, keys, key)
        self.assertEqual({'hand_left', 'hand_right', 'foot_left', 'foot_right'},
                         {r['id'] for r in self.map['regions'] if r['couche'] == 'volume'})
        # Peau nue (genoux, coudes, tibias, bas du ventre…) : minoritaire.
        self.assertLess(self.tris['peau'], .15 * sum(self.tris.values()))

    def test_symetrie(self):
        # Maillage symétrique, zones recopiées du côté gauche : mêmes
        # nombres de triangles à gauche et à droite.
        by_key = {}
        for r in self.map['regions']:
            by_key.setdefault(r['cle'], {})[r['cote']] = self.tris[r['id']]
        for key, sides in by_key.items():
            self.assertLessEqual(abs(sides['left'] - sides['right']), 4, f'{key} : {sides}')

    def test_aires_des_zones(self):
        g = self.gltf

        def read(i, fmt, size):
            acc = g['accessors'][i]
            view = g['bufferViews'][acc['bufferView']]
            n = {'VEC3': 3, 'SCALAR': 1}[acc['type']] * acc['count']
            start = view['byteOffset'] + acc.get('byteOffset', 0)
            return struct.unpack(f'<{n}{fmt}', self.blob[start:start + n * size])

        areas = {}
        for node in g['nodes']:
            prim = g['meshes'][node['mesh']]['primitives'][0]
            p = read(prim['attributes']['POSITION'], 'f', 4)
            big = g['accessors'][prim['indices']]['componentType'] == 5125
            idx = read(prim['indices'], 'I' if big else 'H', 4 if big else 2)
            total = 0.0
            for t in range(0, len(idx), 3):
                a, b, c = (3 * idx[t + k] for k in range(3))
                ux, uy, uz = p[b] - p[a], p[b + 1] - p[a + 1], p[b + 2] - p[a + 2]
                vx, vy, vz = p[c] - p[a], p[c + 1] - p[a + 1], p[c + 2] - p[a + 2]
                total += 0.5 * math.sqrt((uy * vz - uz * vy) ** 2
                                         + (uz * vx - ux * vz) ** 2
                                         + (ux * vy - uy * vx) ** 2)
            areas[node['name']] = total
        for r in self.map['regions']:
            self.assertGreater(r['aire'], 0, r['id'])
            self.assertAlmostEqual(r['aire'], areas[r['id']], delta=2e-5, msg=r['id'])
        by_id = {r['id']: r for r in self.map['regions']}
        self.assertLess(by_id['latissimus_dorsi_left']['aire'], 0.1)
        # M6c : aires vues de face et de dos (vue de départ des fiches,
        # lib/exercise_mannequin.dart) : chacune ≤ l'aire, somme ≥ 0,9 aire
        # environ pour une zone plane de face ou de dos.
        for r in self.map['regions']:
            self.assertLessEqual(r['aire_face'], r['aire'] + 1e-5, r['id'])
            self.assertLessEqual(r['aire_dos'], r['aire'] + 1e-5, r['id'])
        # Traction : grand dorsal vu de dos ≥ 1,65 × biceps vu de face
        # (kStartViewDominance) ; droit de l'abdomen vu de face seulement.
        self.assertGreater(by_id['latissimus_dorsi_left']['aire_dos'],
                           1.65 * by_id['biceps_brachii_left']['aire_face'])
        self.assertEqual(by_id['rectus_abdominis_left']['aire_dos'], 0)

    def test_repere_et_hauteur(self):
        # Pieds au sol, 1,77 m, avant = +z (droit de l'abdomen devant le
        # grand fessier), gauche anatomique = +x.
        acc = self.gltf['accessors']

        def bounds(node):
            a = acc[self.gltf['meshes'][node['mesh']]['primitives'][0]['attributes']['POSITION']]
            return a['min'], a['max']

        lo = [min(bounds(n)[0][i] for n in self.gltf['nodes']) for i in range(3)]
        hi = [max(bounds(n)[1][i] for n in self.gltf['nodes']) for i in range(3)]
        self.assertLess(abs(lo[1]), .01)
        self.assertAlmostEqual(hi[1], 1.77, delta=.02)
        # Bras abaissés (pose d'affichage) : largeur ≈ la moitié de la hauteur.
        self.assertLess(hi[0] - lo[0], .6 * hi[1])

        def center(name):
            b = bounds(next(n for n in self.gltf['nodes'] if n['name'] == name))
            return [(b[0][i] + b[1][i]) / 2 for i in range(3)]

        self.assertGreater(center('rectus_abdominis_left')[2], center('gluteus_maximus_left')[2])
        self.assertGreater(center('deltoid_lateral_left')[0], 0)
        self.assertLess(center('deltoid_lateral_right')[0], 0)

    def test_aucune_zone_sans_groupe(self):
        self.assertEqual(self.map['groupes'], anatomy_data.APP_GROUPS)
        for r in self.map['regions']:
            self.assertIn(r['groupe'], anatomy_data.APP_GROUPS, r['id'])
            self.assertTrue(r['nom'], r['id'])
            self.assertIn(r['couche'], ('superficiel', 'volume'), r['id'])
        for group in anatomy_data.APP_GROUPS:
            self.assertTrue(any(r['groupe'] == group for r in self.map['regions']), group)

    def test_muscles_du_pack(self):
        covered = {p for r in self.map['regions'] for p in r['pack']}
        self.assertTrue(covered <= set(self.pack), covered - set(self.pack))
        superficial = {k for k, (_, depth) in self.pack.items() if depth == 'superficiel'}
        self.assertEqual(superficial - covered, set(), 'muscle visible sans zone')
        self.assertEqual(set(self.pack) - covered, ABSENTS_DU_MODELE)
        self.assertEqual(set(self.map['muscles_sans_region']), ABSENTS_DU_MODELE)
        for r in self.map['regions']:
            if r['pack']:
                self.assertEqual(r['groupe'], self.pack[r['pack'][0]][0], r['id'])

    def test_fit_mesure(self):
        # « Un peu plus fit, sans abus ni déformation » : +6 à +10 % de tour
        # sur les membres travaillés (jamais plus de 12 %), taille inchangée.
        fit = self.report['fit']
        gains = fit['gains_pct']
        for zone in ('bras', 'avant_bras', 'cuisse', 'mollet'):
            self.assertGreaterEqual(gains[zone], 6.0, zone)
            self.assertLessEqual(gains[zone], 10.0, zone)
        self.assertGreater(gains['poitrine'], 4.0)
        self.assertGreater(gains['largeur_epaules'], 1.5)
        for zone, g in gains.items():
            self.assertLessEqual(g, 12.0, zone)
        self.assertLess(abs(gains['taille']), .5)
        self.assertLess(fit['deplacement_max_mm'], 25)

    def test_rapport(self):
        self.assertEqual(self.report['triangles']['total'], sum(self.tris.values()))
        self.assertEqual(self.report['triangles']['par_noeud'], self.tris)
        self.assertEqual(self.report['source']['sha256'], self.map['source']['sha256'])
        self.assertEqual(self.report['regions'], len(self.map['regions']))
        self.assertEqual(self.report['personnage'],
                         {'sommets': 14442, 'triangles': 28880, 'os': 65, 'groupes': 52})
        self.assertEqual(self.report['glb_octets'], GLB.stat().st_size)

    def test_squelette_mixamo(self):
        # Exposé au code pour M7 (lib/mixamo_skeleton.dart) : 65 os, noms,
        # hiérarchie et pose de repos du FBX, pose d'affichage.
        skel = json.loads(SKELETON.read_text(encoding='utf-8'))
        names = [b['nom'] for b in skel['os']]
        self.assertEqual(len(names), 65)
        self.assertEqual(set(names), set(MIXAMO_BONES))
        self.assertEqual(skel['prefixe_fbx'], 'mixamorig1:')
        parents = {b['nom']: b['parent'] for b in skel['os']}
        self.assertIsNone(parents['Hips'])
        for name, parent in parents.items():
            if name != 'Hips':
                self.assertIn(parent, parents, name)
                self.assertLess(names.index(parent), names.index(name), 'parents d\'abord')
        heads = {b['nom']: b['tete'] for b in skel['os']}
        # Pose en T : poignets à hauteur d'épaule, symétrie gauche / droite.
        self.assertAlmostEqual(heads['LeftHand'][1], heads['LeftArm'][1], delta=.03)
        self.assertAlmostEqual(heads['LeftHand'][0], -heads['RightHand'][0], delta=.005)
        self.assertGreater(heads['LeftArm'][0], 0)
        for bone in skel['pose_affichage']['rotations']:
            self.assertIn(bone, parents)

    def test_noms_francais(self):
        for key in anatomy_data.PACK_OF_KEY:
            self.assertIn(key, anatomy_data.FR)
        for r in self.map['regions']:
            self.assertEqual(r['nom'], anatomy_data.FR[r['cle']])
            self.assertEqual(r['pack'], anatomy_data.PACK_OF_KEY[r['cle']])

    def test_credits(self):
        text = ATTRIBUTION.read_text(encoding='utf-8')
        for line in ('Mixamo', 'Adobe', 'Ecorche Musclenames Male Anatomy',
                     'tools/anatomy/build_character.py', 'chiffré'):
            self.assertIn(line, text)

    def test_pubspec(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for asset in ('assets/anatomy/muscles_map.json', 'assets/anatomy/ATTRIBUTION.md',
                      'assets/anatomy/squelette_mixamo.json', 'flutter_scene_generated/'):
            self.assertIn(f'    - {asset}\n', pubspec)
        self.assertNotIn('- assets/anatomy/mannequin.glb', pubspec)
        self.assertNotIn('- assets/anatomy/\n', pubspec)
        self.assertNotIn('assets_secure', pubspec)
        hook = (ROOT / 'hook' / 'build.dart').read_text(encoding='utf-8')
        self.assertIn("'assets/anatomy/mannequin.glb'", hook)
        ignore = (ROOT / '.gitignore').read_text(encoding='utf-8')
        self.assertIn('/assets/anatomy/mannequin.glb', ignore)
        self.assertIn('/assets_secure/clair/', ignore)


class EcorcheSourceTest(unittest.TestCase):
    """L'écorché acheté (tools/anatomy/build_model.py) : source des zones."""

    def test_carte_de_l_ecorche(self):
        mapping = json.loads(build_model.OUT_MAP.read_text(encoding='utf-8'))
        self.assertEqual(mapping['schema'], 2)
        self.assertEqual(len(mapping['source']['sha256']), 64)
        self.assertEqual(len(mapping['regions']), 136)
        report = json.loads((ANATOMY / 'build_report.json').read_text(encoding='utf-8'))
        self.assertEqual(report['regions'], len(mapping['regions']))
        self.assertEqual(build_model.OUT_GLB.relative_to(ROOT).as_posix(),
                         'assets_secure/clair/ecorche_mannequin.glb')

    def test_etiquettes(self):
        known = (build_model.KEY_OF.keys() | build_model.HEAD | build_model.BONE_LABELS
                 | build_model.TENDON_LABELS | build_model.HAND_LABELS
                 | build_model.FOOT_LABELS | build_model.NECK_LABELS | {'ADM', 'SM', 'C'})
        for abbr, x, y in build_model.LABELS:
            self.assertIn(abbr, known, abbr)
            self.assertTrue(0 <= x < 4096 and 0 <= y < 4096, abbr)
        self.assertGreater(len(build_model.LABELS), 200)


if __name__ == '__main__':
    unittest.main()
