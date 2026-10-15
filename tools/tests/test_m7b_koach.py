# -*- coding: utf-8 -*-
"""M7b : animations de Koach en mascotte (tools/anatomy/koach_animations.py,
koach_rig.py, import_animations.import_koach). Sans Blender : registre et
clips toujours ; avec numpy : contrôles automatiques des 9 animations
(durée, attente au départ et à l'arrivée, limites, pieds fixes,
interpénétration) et clips fidèles au script (le FBX n'est qu'un passage)."""
import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
sys.path.insert(0, str(ROOT / 'tools/anatomy'))

try:
    import numpy as np
except ImportError:  # CI sans numpy : registre et documentation
    np = None

import import_animations as ia  # noqa: E402

needs_numpy = unittest.skipIf(np is None, 'numpy requis (contrôles des animations)')

IDS = ['koach_attente_respiration', 'koach_attente_regard', 'koach_attente_etirement',
       'koach_parle_une_main', 'koach_parle_deux_mains', 'koach_parle_montre',
       'koach_felicite_applaudit', 'koach_felicite_poing', 'koach_felicite_pouce']


def koach_entries():
    index = json.loads(ia.INDEX.read_text(encoding='utf-8'))
    return [c for c in index['clips'] if c.get('mascotte')]


class RegistreKoach(unittest.TestCase):
    def test_neuf_animations_trois_familles(self):
        clips = koach_entries()
        self.assertEqual(sorted(c['id'] for c in clips), sorted(IDS))
        fam = {}
        for c in clips:
            fam.setdefault(c['famille'], []).append(c['id'])
            self.assertEqual(c['exercices'], [])
            self.assertFalse(c['debogage'])
            self.assertNotIn('muscles', c)
            self.assertTrue(3 <= c['duree_s'] <= 6, c['id'])
            self.assertEqual(c['boucle'], c['famille'] != 'felicite', c['id'])
            self.assertTrue(c['fichier'].startswith('assets/anatomy/clips/koach/'))
            self.assertEqual(c['source']['script'], 'tools/anatomy/koach_animations.py')
            self.assertLessEqual(c['compression']['ecart_max_deg'], 1.0)
            if c['octets'] > c['budget_octets']:
                self.assertIn('depassement', c)
        self.assertEqual({k: len(v) for k, v in fam.items()},
                         {'attente': 3, 'parle': 3, 'felicite': 3})

    def test_registre_verifie(self):
        index = ia.verify(log=lambda *_: None)
        self.assertTrue(any(c['id'] == 'debug_squat' for c in index['clips']))

    def test_clips_decodes(self):
        rig = json.loads(ia.RIG.read_text(encoding='utf-8'))
        bones = [b['nom'] for b in rig['os']]
        for c in koach_entries():
            data = (ROOT / c['fichier']).read_bytes()
            fps, frames, local, root = ia.decode_clip(data, bones)
            self.assertEqual((fps, frames), (30, c['images']), c['id'])

    def test_actifs_declares(self):
        pub = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
        self.assertIn('- assets/anatomy/clips/koach/', pub)

    def test_mascotte_refusee_sur_une_fiche(self):
        c = dict(koach_entries()[0], exercices=['back-squat'])
        index = {'schema': 1, 'clips': [c]}
        saved = ia.load_index
        ia.load_index = lambda: index
        try:
            with self.assertRaises(ia.ImportErreur):
                ia.verify(log=lambda *_: None)
        finally:
            ia.load_index = saved

    def test_documentation(self):
        doc = (ROOT / 'docs/CI_3D.md').read_text(encoding='utf-8')
        self.assertIn('koach_m7b_test.dart', doc)
        self.assertIn('koach_animations.py --importer', doc)


@needs_numpy
class AnimationsKoach(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        import koach_animations as ka
        import koach_rig as kr
        cls.ka, cls.kr = ka, kr
        cls.anims = {a.id: a for a in ka.all_anims()}
        cls.motions = {i: a.motion() for i, a in cls.anims.items()}

    def test_controles_automatiques(self):
        for i, a in self.anims.items():
            rep = self.kr.check(a, self.motions[i], self.ka.CONTACTS.get(i, ()))
            self.assertTrue(rep['ok'], (i, rep['defauts']))
            self.assertEqual(rep['glissement_pieds_mm'], 0.0, i)

    def test_style_anime_tenues_courtes(self):
        """Aucune pose figée plus de 0,45 s (revue d'animation) : la tête, les
        mains, les coudes, le bassin ou le thorax bougent d'au moins 6 cm/s."""
        joints = ['Head', 'HeadTop_End', 'LeftHand', 'RightHand', 'LeftForeArm',
                  'RightForeArm', 'Hips', 'Spine2']
        for i, m in self.motions.items():
            idx = m.index
            prev = m.globals(0)[1]
            still = worst = 0
            for f in range(1, m.frames):
                cur = m.globals(f)[1]
                speed = max(np.linalg.norm(cur[idx[j]] - prev[idx[j]]) for j in joints) * m.fps
                still = still + 1 if speed < .06 else 0
                worst = max(worst, still)
                prev = cur
            self.assertLessEqual(worst / m.fps, .45, i)

    def test_clips_fideles_au_script(self):
        rig = json.loads(ia.RIG.read_text(encoding='utf-8'))
        bones = [b['nom'] for b in rig['os']]
        by_id = {c['id']: c for c in koach_entries()}
        for i, m in self.motions.items():
            data = (ROOT / by_id[i]['fichier']).read_bytes()
            _, frames, local, root = ia.decode_clip(data, bones)
            self.assertEqual(frames, m.frames, i)
            rot, pos = ia.max_error(m, np.array(local), np.array(root))
            self.assertLess(rot, 1.2, i)
            self.assertLess(pos, .012, i)

    def test_transitions(self):
        ref = self.motions[IDS[0]].local[0]
        for i, m in self.motions.items():
            gap = max(ia.angle_deg(a, b) for a, b in zip(m.local[0], ref))
            self.assertLess(gap, 2.5, i)

    def test_miroir_des_mains(self):
        """Les canaux des mains sont symétriques (pouces compris)."""
        kr = self.kr
        M = np.array([-1, 1, 1])
        for ch in ({'b_fist': 1, 'b_th_c': .3, 'b_th_o': -30}, {'b_th_o': 30},
                   {'b_wr_tw': 40, 'b_ar_tw': -30, 'b_idx': 0, 'b_fist': 1}):
            pose = kr.P(**ch)
            hl = kr.hand_frame(pose, 'l_')['pos']
            hr = kr.hand_frame(pose, 'r_')['pos']
            for n in ('HandThumb4', 'HandIndex4', 'HandPinky4'):
                self.assertLess(np.linalg.norm(hl['Left' + n] - M * hr['Right' + n]), .008,
                                (ch, n))


if __name__ == '__main__':
    unittest.main()
