"""Annotations du programme (`assets/koach_program.json.gz`).

G10 : le moteur Koach L7 et sa référence Python sont retirés ; les
annotations restent (natures de semaine du bloc importé lu par le moteur
dynamique, G9) et restent égales à ce que produit `tools/koach_annotate.py`.
Repris de test_koach_reference.py (L7).
"""
import gzip
import json
from pathlib import Path
import re
import sys
import unittest

TOOLS = Path(__file__).resolve().parents[1]
ROOT = TOOLS.parent
sys.path.insert(0, str(TOOLS))
import koach_annotate as ka  # noqa: E402


class KoachAnnotationTests(unittest.TestCase):
    def setUp(self):
        self.program, self.digest = ka.load_program()
        self.data = json.loads(gzip.decompress(ka.TARGET.read_bytes()))

    def test_shipped_annotations_are_current(self):
        self.assertEqual(ka.encode(ka.annotate(self.program, self.digest)), ka.TARGET.read_bytes())
        self.assertEqual(self.data['source']['sha256'], self.digest)

    def test_rir_target_equals_label_on_every_exercise(self):
        count = 0
        for week in self.program['weeks']:
            for day in week['days']:
                for ex in day['exercises']:
                    count += 1
                    m = re.search(r'RIR\s*(\d)(?:\s*-\s*(\d))?', ex['intensity'])
                    entry = self.data['exercises'].get(ex['id'], {})
                    if m:
                        self.assertEqual(entry.get('rirTarget'), int(m.group(1)), ex['id'])
                        self.assertEqual(entry.get('rirTargetMax'), int(m.group(2)) if m.group(2) else None, ex['id'])
                    else:
                        self.assertNotIn('rirTarget', entry, ex['id'])
        self.assertEqual(count, 1812)  # LC1b : 1 818 − 7 + 1

    def test_curve_prior_and_incoherent_singles_excluded(self):
        self.assertEqual(self.data['curve']['mu']['k'], 28.0)
        for key in ('pull', 'dip', 'squat'):
            self.assertEqual(self.data['curve'][key]['k'], 22.4)

    def test_categories_weeks_and_equipment(self):
        cats = {}
        for e in self.data['exercises'].values():
            if 'cat' in e:
                cats[e['cat']] = cats.get(e['cat'], 0) + 1
        self.assertEqual(cats, {'accessory': 918, 'endurance': 151, 'strength': 136, 'enduranceTest': 19, 'test1rm': 12})
        weeks = self.data['weeks']
        self.assertEqual(sorted(int(n) for n, t in weeks.items() if t == 'deload'), [7, 11, 15, 19, 23, 30, 35])
        self.assertEqual(sorted(int(n) for n, t in weeks.items() if t == 'test'), [1, 2, 12, 25, 31, 39, 40])
        self.assertTrue(self.data['accessories']['B43']['prevention'])
        self.assertEqual(self.data['accessories']['B30']['equipment'], 'dumbbell')
        self.assertEqual(self.data['accessories']['B34']['equipment'], 'pulley')

    def test_programme_asset_untouched(self):
        # Asset LC1 puis LC1b (empreintes vérifiées par test_lc1_revision et test_lc1b_s11_j6).
        raw = gzip.decompress((ROOT / 'assets' / 'programme_v33.json.gz').read_bytes())
        self.assertNotIn(b'rirTarget', raw)


if __name__ == '__main__':
    unittest.main()
