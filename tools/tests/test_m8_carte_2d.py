"""M8 : carte 2D des muscles (5.9.0 ; 5.10.0 : muscle par muscle).

Carte fabriquée par tools/muscles2d/build_map.py d'après l'image du
propriétaire (tools/muscles2d/source_carte.png) : par vue, une carte des
étiquettes (rang de la région), les traits et le modelé, tous à la même
taille ; tailles identiques côté Dart ; table des régions générée
(lib/muscle_map_regions.dart) identique au script ; muscles du pack dessinés
une seule fois, les profonds jamais ; assets déclarés ; fabrication
reproductible.
"""
import hashlib
import importlib.util
import json
import re
import struct
import sys
import tempfile
import unittest
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError:  # CI sans numpy ni Pillow : en-têtes PNG seulement
    np = Image = None

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/muscles2d'
DART = (ROOT / 'lib/muscle_map_2d.dart').read_text(encoding='utf-8')
REGIONS_DART = (ROOT / 'lib/muscle_map_regions.dart').read_text(encoding='utf-8')
needs_pil = unittest.skipIf(Image is None, 'numpy et Pillow requis (pixels)')

# Muscles du pack que l'image ne dessine pas (sous un autre muscle ou
# internes) : listés en texte seulement.
PROFONDS = {
    'flechisseurs_cervicaux_profonds', 'supra_epineux', 'sous_scapulaire', 'petit_pectoral',
    'coraco_brachial', 'supinateur', 'carre_pronateur', 'muscles_intrinseques_main',
    'transverse_abdomen', 'oblique_interne', 'diaphragme', 'plancher_pelvien',
    'petit_fessier', 'rotateurs_lateraux_hanche', 'court_adducteur', 'vaste_intermediaire',
    'poplite', 'muscles_intrinseques_pied', 'flechisseurs_profonds_des_orteils',
    'tibial_posterieur',
}


def png_header(path):
    """(largeur, hauteur, type de couleur) lus dans l'en-tête IHDR."""
    raw = Path(path).read_bytes()[:26]
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', path
    w, h, _depth, color = struct.unpack('>IIBB', raw[16:26])
    return w, h, color


def carte():
    return json.loads((OUT / 'carte.json').read_text(encoding='utf-8'))


def builder():
    sys.path.insert(0, str(ROOT / 'tools/muscles2d'))
    try:
        spec = importlib.util.spec_from_file_location(
            'build_map_test', ROOT / 'tools/muscles2d/build_map.py')
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    finally:
        sys.path.pop(0)


def atlas_ids():
    atlas = (ROOT / 'lib/atlas_data.dart').read_text(encoding='utf-8')
    start = atlas.index('const atlasMuscles')
    return set(re.findall(r"^  '([a-z_]+)': AtlasMuscle\(", atlas[start:], re.M))


class CarteTest(unittest.TestCase):
    def test_regions_et_groupes(self):
        c = carte()
        self.assertEqual(len(c['groupes']), 16)
        self.assertIn('lombaires', c['groupes'])
        ids = [r['id'] for r in c['regions']]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertLess(len(ids), 253)
        present = set()
        for v in c['vues'].values():
            present |= set(v['regions'])
        self.assertEqual(present, set(ids), 'région jamais dessinée')
        for r in c['regions']:
            self.assertTrue(r['groupe'] is None or r['groupe'] in c['groupes'], r['id'])

    def test_muscles_du_pack(self):
        c = carte()
        pack = atlas_ids()
        seen = []
        for r in c['regions']:
            seen += r['muscles']
        self.assertEqual(len(seen), len(set(seen)), 'muscle dans deux régions')
        self.assertTrue(set(seen) <= pack, set(seen) - pack)
        self.assertEqual(pack - set(seen), PROFONDS)

    def test_en_tetes(self):
        # sans Pillow : tailles et types (0 = gris : étiquettes ; 4 = gris +
        # alpha : traits et modelé) lus dans les en-têtes PNG
        c = carte()
        for view, v in c['vues'].items():
            size = (v['largeur'], v['hauteur'])
            self.assertEqual(png_header(OUT / view / 'etiquettes.png'), (*size, 0), view)
            for name in ('contour', 'ombre'):
                self.assertEqual(png_header(OUT / view / f'{name}.png'), (*size, 4), view)
            files = {p.name for p in (OUT / view).glob('*.png')}
            self.assertEqual(files, {'etiquettes.png', 'contour.png', 'ombre.png'}, view)

    @needs_pil
    def test_etiquettes(self):
        c = carte()
        n = len(c['regions'])
        for view, v in c['vues'].items():
            lab = np.asarray(Image.open(OUT / view / 'etiquettes.png'))
            values = set(np.unique(lab).tolist())
            self.assertIn(0, values, view)  # fond transparent
            self.assertEqual(lab[0, 0], 0, view)
            self.assertTrue(values <= set(range(n + 1)) | {253, 254}, view)
            self.assertEqual({c['regions'][k - 1]['id'] for k in values if 1 <= k <= n},
                             set(v['regions']), view)

    def test_vues_cote_dart(self):
        c = carte()
        for view, v in c['vues'].items():
            m = re.search(rf"{view}\('[^']+', (\d+), (\d+)\)", DART)
            self.assertIsNotNone(m, view)
            self.assertEqual((int(m.group(1)), int(m.group(2))),
                             (v['largeur'], v['hauteur']), view)
        self.assertIn('kMapSombre = 253, kMapPeau = 254', DART)

    def test_table_generee(self):
        c = carte()
        found = re.findall(r"MapRegion\(\s*'([a-z_]+)',", REGIONS_DART)
        self.assertEqual(found, [r['id'] for r in c['regions']])
        groups = re.findall(r"MapGroup\('([a-z_]+)'", REGIONS_DART)
        self.assertEqual(groups, c['groupes'])

    @needs_pil
    def test_table_generee_identique_au_script(self):
        mod = builder()
        with tempfile.TemporaryDirectory() as tmp:
            mod.DART = Path(tmp) / 'r.dart'
            mod.write_dart()
            self.assertEqual(mod.DART.read_text(encoding='utf-8'), REGIONS_DART)

    def test_assets_declares(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for view in ('face', 'dos', 'profil'):
            self.assertIn(f'    - assets/muscles2d/{view}/\n', pubspec)

    @needs_pil
    @unittest.skipUnless(importlib.util.find_spec('scipy'), 'scipy absent')
    def test_fabrication_reproductible(self):
        mod = builder()
        with tempfile.TemporaryDirectory() as tmp:
            mod.OUT = Path(tmp)
            mod.DART = Path(tmp) / 'r.dart'
            mod.build()
            for view in ('face', 'dos', 'profil'):
                a = Image.open(Path(tmp) / view / 'etiquettes.png').tobytes()
                b = Image.open(OUT / view / 'etiquettes.png').tobytes()
                self.assertEqual(hashlib.sha256(a).hexdigest(),
                                 hashlib.sha256(b).hexdigest(), view)


if __name__ == '__main__':
    unittest.main()
