"""LC1b (suite de KT-037) : S11·J6 au format du J6 du Bloc 2, asset livré."""
import copy
import gzip
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import lc1_revision_s12_s19 as lc1  # noqa: E402
import lc1b_s11_j6 as lc1b  # noqa: E402
from test_lc1_revision import load as load_lc1, shipped  # noqa: E402


def day(data, n, j):
    return lc1b.day_of(data, n, j)


class Lc1bTests(unittest.TestCase):
    def test_input_is_lc1_output_and_shipped_is_expected_output(self):
        self.assertEqual(lc1b.INPUT_SHA256, lc1.OUTPUT_SHA256_VALUE)
        self.assertEqual(lc1.sha256_json(load_lc1())[0], lc1b.INPUT_SHA256)
        self.assertEqual(lc1.sha256_json(shipped())[0], lc1b.OUTPUT_SHA256_VALUE)

    def test_revision_reproduces_shipped_asset(self):
        self.assertEqual(lc1b.revise(load_lc1()), shipped())

    def test_only_s11_j6_changes(self):
        before, after = load_lc1(), shipped()
        self.assertEqual(before['meta'], after['meta'])
        self.assertEqual(before['pilotage'], after['pilotage'])
        changed = [(w['n'], db['j'])
                   for w, wa in zip(before['weeks'], after['weeks'])
                   for db, da in zip(w['days'], wa['days']) if db != da]
        self.assertEqual(changed, [(11, 6)])
        self.assertEqual(day(before, 12, 6), day(after, 12, 6))

    def test_s11_j6_content(self):
        data = shipped()
        d = day(data, 11, 6)
        s12 = {e['id']: e for e in day(data, 12, 6)['exercises']}
        old = {e['id']: e for e in day(load_lc1(), 11, 6)['exercises']}
        self.assertEqual(d['title'], 'PUISSANCE MU + SQUAT ENDURANCE')
        self.assertEqual(d['cycle'], 'DELOAD')
        self.assertTrue(d['conduite'].startswith(
            'CONDUITE J6 — Muscle-up au poids de corps et tirage explosif, '
            'squat endurance. AUCUNE charge maximale. | Échauffement 12 min'))
        self.assertNotIn('Test', d['conduite'])
        self.assertNotIn('GtG', d['conduite'])
        ids = [e['id'] for e in d['exercises']]
        self.assertEqual(ids, ['B1-L1b-001', 'B1-521', 'B1-525', 'B1-527', 'B1-529'])
        by_id = {e['id']: e for e in d['exercises']}
        # Format S12·J6, identifiant S11 conservé pour les lignes modifiées.
        for s11_id, s12_id in [('B1-L1b-001', 'B2-L1-009'), ('B1-521', 'B2-60'),
                               ('B1-527', 'B2-66'), ('B1-529', 'B2-68')]:
            self.assertEqual({**by_id[s11_id], 'id': s12_id}, s12[s12_id], s11_id)
        self.assertEqual(by_id['B1-521']['sets']['value'], '4×3')
        self.assertEqual(old['B1-521']['sets']['value'], '5×3')
        self.assertEqual(by_id['B1-527']['sets']['value'], '3×10')
        self.assertEqual(old['B1-527']['sets']['value'], '2×10')
        # Squat endurance de S11 inchangé ; aucun test max en S11.
        self.assertEqual(by_id['B1-525'], old['B1-525'])
        self.assertEqual(by_id['B1-525']['sets']['coef'], 0.9)
        self.assertEqual(by_id['B1-525']['intensity'], 'Sous-maximal, RIR 3')
        self.assertFalse(any('TEST' in e['name'] for e in d['exercises']))

    def test_ids_removed_new_and_total(self):
        ids = [e['id'] for w in shipped()['weeks'] for d in w['days'] for e in d['exercises']]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(ids), 1812)
        self.assertEqual(1818 - len(lc1b.REMOVED) + 1, 1812)
        self.assertFalse(set(ids) & set(lc1b.REMOVED))
        self.assertEqual([i for i in ids if 'L1b' in i], ['B1-L1b-001'])

    def test_second_run_is_refused_clearly(self):
        with self.assertRaisesRegex(lc1.RevisionError, 'déjà appliquée'):
            lc1b.revise(shipped())

    def test_unexpected_input_is_refused(self):
        data = copy.deepcopy(load_lc1())
        data['weeks'][0]['days'][0]['title'] += ' (modifié)'
        with self.assertRaisesRegex(lc1.RevisionError, 'Asset inattendu'):
            lc1b.revise(data)

    def test_cli_applies_once_then_refuses_without_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / 'programme_v33.json.gz'
            _, raw = lc1.sha256_json(load_lc1())
            target.write_bytes(gzip.compress(raw, compresslevel=9, mtime=0))
            cmd = [sys.executable, str(TOOLS / 'lc1b_s11_j6.py'), '--assets', tmp]
            first = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(first.returncode, 0, first.stderr)
            self.assertIn('1818 → 1812', first.stdout)
            self.assertEqual(target.read_bytes(), (TOOLS.parent / 'assets' / 'programme_v33.json.gz').read_bytes())
            before = target.read_bytes()
            second = subprocess.run(cmd, capture_output=True, text=True)
            self.assertEqual(second.returncode, 1)
            self.assertIn('ÉCHEC LC1b', second.stderr)
            self.assertIn('déjà appliquée', second.stderr)
            self.assertEqual(target.read_bytes(), before)
            self.assertEqual(json.loads(gzip.decompress(before)), shipped())


if __name__ == '__main__':
    unittest.main()
