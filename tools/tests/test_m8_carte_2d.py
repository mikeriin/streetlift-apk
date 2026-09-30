"""M8 (5.9.0) : carte 2D des 15 groupes musculaires.

Masques fabriqués par tools/muscles2d/build_map.py d'après l'image du
propriétaire (tools/muscles2d/source_carte.png) : chaque vue a ses calques,
tous à la même taille que sa carte des étiquettes ; fond transparent ;
groupes et tailles identiques côté Dart (lib/muscle_map_2d.dart) ; assets
déclarés dans pubspec.yaml ; fabrication reproductible.
"""
import hashlib
import importlib.util
import json
import re
import struct
import tempfile
import unittest
from pathlib import Path

try:
    import numpy as np
    from PIL import Image
except ImportError:  # CI sans numpy ni Pillow : en-têtes PNG seulement
    np = Image = None

needs_pil = unittest.skipIf(Image is None, 'numpy et Pillow requis (pixels)')

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/muscles2d'
DART = (ROOT / 'lib/muscle_map_2d.dart').read_text(encoding='utf-8')

GROUPS = ['trapezes', 'deltoides', 'pectoraux', 'dorsaux', 'biceps', 'triceps', 'avant_bras',
          'abdominaux', 'obliques', 'fessiers', 'quadriceps', 'ischios', 'adducteurs',
          'mollets', 'tibial']


def png_header(path):
    """(largeur, hauteur, type de couleur) lus dans l'en-tête IHDR."""
    raw = Path(path).read_bytes()[:26]
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', path
    w, h, _depth, color = struct.unpack('>IIBB', raw[16:26])
    return w, h, color


def carte():
    return json.loads((OUT / 'carte.json').read_text(encoding='utf-8'))


class CarteTest(unittest.TestCase):
    def test_15_groupes_et_calques(self):
        c = carte()
        self.assertEqual(c['groupes'], GROUPS)
        self.assertEqual(c['calques'], GROUPS + ['peau', 'sombre'])
        self.assertEqual(sorted(c['vues']), ['dos', 'face', 'profil'])
        present = set()
        for view, v in c['vues'].items():
            present |= set(v['calques'])
            self.assertIn('peau', v['calques'], view)
            self.assertIn('sombre', v['calques'], view)
        # chaque groupe est visible dans au moins une vue
        self.assertTrue(set(GROUPS) <= present, set(GROUPS) - present)

    def test_en_tetes(self):
        # sans Pillow : tailles et types (0 = gris : étiquettes ; 4 = gris +
        # alpha : masques) lus dans les en-têtes PNG
        c = carte()
        for view, v in c['vues'].items():
            size = (v['largeur'], v['hauteur'])
            self.assertEqual(png_header(OUT / view / 'etiquettes.png'), (*size, 0), view)
            for name in v['calques']:
                self.assertEqual(png_header(OUT / view / f'{name}.png'), (*size, 4),
                                 f'{view}/{name}')
            files = {p.stem for p in (OUT / view).glob('*.png')}
            self.assertEqual(files, set(v['calques']) | {'etiquettes'}, view)

    @needs_pil
    def test_masques_et_etiquettes(self):
        c = carte()
        for view, v in c['vues'].items():
            size = (v['largeur'], v['hauteur'])
            labels = Image.open(OUT / view / 'etiquettes.png')
            self.assertEqual(labels.mode, 'L', view)
            self.assertEqual(labels.size, size, view)
            values = set(np.unique(np.asarray(labels)).tolist())
            self.assertIn(0, values, view)  # fond transparent
            self.assertTrue(values <= set(range(len(c['calques']) + 1)), view)
            for name in v['calques']:
                m = Image.open(OUT / view / f'{name}.png')
                self.assertEqual(m.size, size, f'{view}/{name}')
                self.assertEqual(m.mode, 'LA', f'{view}/{name}')
                # coin en haut à gauche : transparent (le support se voit)
                self.assertEqual(m.getpixel((0, 0))[1], 0, f'{view}/{name}')
                # calque non vide, étiquette présente
                self.assertIsNotNone(m.getchannel('A').getbbox(), f'{view}/{name}')
                k = c['calques'].index(name) + 1
                self.assertIn(k, values, f'{view}/{name}')
            # pas de fichier en trop
            files = {p.stem for p in (OUT / view).glob('*.png')}
            self.assertEqual(files, set(v['calques']) | {'etiquettes'}, view)

    def test_vues_et_groupes_cote_dart(self):
        c = carte()
        for view, v in c['vues'].items():
            m = re.search(rf"{view}\('[^']+', (\d+), (\d+)\)", DART)
            self.assertIsNotNone(m, view)
            self.assertEqual((int(m.group(1)), int(m.group(2))),
                             (v['largeur'], v['hauteur']), view)
            block = re.search(rf'MapView\.{view}: \{{(.*?)\}}', DART, re.S).group(1)
            self.assertEqual(set(re.findall(r"'([a-z_]+)'", block)), set(v['calques']), view)
        ids = re.findall(r"MapGroup\('([a-z_]+)'", DART)
        self.assertEqual(ids, GROUPS)
        layers = re.search(r'const kMapLayers = \[(.*?)\];', DART, re.S).group(1)
        self.assertEqual(re.findall(r"'([a-z_]+)'", layers), c['calques'])

    def test_assets_declares(self):
        pubspec = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        for view in ('face', 'dos', 'profil'):
            self.assertIn(f'    - assets/muscles2d/{view}/\n', pubspec)

    def test_muscles_du_pack_rattaches(self):
        atlas = (ROOT / 'lib/atlas_data.dart').read_text(encoding='utf-8')
        start = atlas.index('const atlasMuscles')
        ids = re.findall(r"^  '([a-z_]+)': AtlasMuscle\(", atlas[start:], re.M)
        mapping = dict(re.findall(r"^  '([a-z_]+)': '([a-z_]+)',", DART, re.M))
        self.assertTrue(set(mapping) <= set(ids), set(mapping) - set(ids))
        self.assertTrue(set(mapping.values()) <= set(GROUPS))
        # sans groupe : muscles profonds du tronc et du cou seulement
        self.assertEqual(set(ids) - set(mapping), {
            'flechisseurs_cervicaux_profonds', 'carre_des_lombes', 'erecteurs_lombaires',
            'erecteurs_thoraciques', 'multifides', 'diaphragme', 'plancher_pelvien',
        })

    @needs_pil
    @unittest.skipUnless(importlib.util.find_spec('scipy'), 'scipy absent')
    def test_fabrication_reproductible(self):
        spec = importlib.util.spec_from_file_location(
            'build_map', ROOT / 'tools/muscles2d/build_map.py')
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        with tempfile.TemporaryDirectory() as tmp:
            mod.OUT = Path(tmp)
            mod.build()
            for view in ('face', 'dos', 'profil'):
                a = Image.open(Path(tmp) / view / 'etiquettes.png').tobytes()
                b = Image.open(OUT / view / 'etiquettes.png').tobytes()
                self.assertEqual(hashlib.sha256(a).hexdigest(),
                                 hashlib.sha256(b).hexdigest(), view)


if __name__ == '__main__':
    unittest.main()
