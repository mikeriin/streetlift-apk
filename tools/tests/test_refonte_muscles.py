# -*- coding: utf-8 -*-
"""Refonte muscles et animations : cohérence des illustrations découpées
(assets/muscles/anim) avec leurs atlas, sans dépendance hors bibliothèque
standard (les outils de production, eux, utilisent numpy / scipy / Pillow)."""
import json
import struct
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MUSCLES = ROOT / 'assets' / 'muscles'


def png_size(path):
    data = path.read_bytes()[:24]
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    return struct.unpack('>II', data[16:24])


class RefonteMusclesTest(unittest.TestCase):
    def test_illustrations_et_calques(self):
        meta = json.loads((MUSCLES / 'meta.json').read_text())
        for view in ('front', 'back', 'profile'):
            w, h = png_size(MUSCLES / f'{view}_base.png')
            self.assertEqual((w, h), (meta[view]['w'], meta[view]['h']))
            for layer in MUSCLES.glob(f'{view}_*.png'):
                self.assertEqual(png_size(layer), (w, h), layer.name)
        # 11 calques de profil, un par groupe de l'application
        self.assertEqual(len(list(MUSCLES.glob('profile_*.png'))), 12)

    def test_gabarits_decoupes(self):
        rig = json.loads((MUSCLES / 'anim' / 'rig.json').read_text())
        self.assertEqual(set(rig['vues']), {'face', 'dos', 'profil'})
        expected = {
            'face': 16, 'dos': 16, 'profil': 10,
        }
        for view, spec in rig['vues'].items():
            segs = spec['segments']
            self.assertEqual(len(segs), expected[view], view)
            aw, ah = png_size(ROOT / spec['image'])
            lw, lh = png_size(ROOT / spec['calques'])
            names = [s['nom'] for s in segs]
            self.assertEqual(len(names), len(set(names)))
            for s in segs:
                x, y, w, h = s['rect']
                self.assertTrue(0 <= x and 0 <= y and x + w <= aw and y + h <= ah, (view, s['nom']))
                for c in s['calques']:
                    cx, cy, cw, ch = c['rect']
                    self.assertTrue(cx + cw <= lw and cy + ch <= lh, (view, s['nom'], c['groupe']))
                    dx, dy = c['decalage']
                    # le calque tient dans le sprite de son segment
                    self.assertTrue(dx + cw <= w and dy + ch <= h, (view, s['nom'], c['groupe']))
            for joint in ('tete', 'cou', 'bassin', 'nuque', 'taille'):
                self.assertIn(joint, spec['articulations'])

    def test_outils_relancables_presents(self):
        for tool in ('muscles_profile.py', 'anim_cutout.py'):
            self.assertTrue((ROOT / 'tools' / tool).is_file(), tool)
        self.assertTrue((ROOT / 'tools' / 'sources' / 'profil_source_chatgpt.png').is_file())


if __name__ == '__main__':
    unittest.main()
