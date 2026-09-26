"""LC1 (KT-037) : script de révision S12-S19 et asset livré."""
import copy
import gzip
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import lc1_revision_s12_s19 as lc1  # noqa: E402

ASSET = TOOLS.parent / 'assets' / 'programme_v33.json.gz'
# Méta, Pilotage et semaines 1-11 / 20-40 de l'asset 2.5.6 (JSON canonique,
# clés triées) : ils ne doivent pas bouger.
UNTOUCHED_SHA256 = '04ffcab8f56dc05788624426a7e921e6cd64b15fb502951b942c39ab3735e89b'


def load():
    return json.loads(gzip.decompress(ASSET.read_bytes()))


def untouched(data):
    part = {
        'meta': data['meta'],
        'pilotage': data['pilotage'],
        'weeks': [w for w in data['weeks'] if not 12 <= w['n'] <= 19],
    }
    raw = json.dumps(part, ensure_ascii=False, separators=(',', ':'), sort_keys=True)
    return hashlib.sha256(raw.encode()).hexdigest()


class Lc1RevisionTests(unittest.TestCase):
    def test_shipped_asset_is_the_expected_revision(self):
        digest, _ = lc1.sha256_json(load())
        self.assertEqual(digest, lc1.OUTPUT_SHA256_VALUE)

    def test_weeks_outside_block_2_and_pilotage_unchanged(self):
        self.assertEqual(untouched(load()), UNTOUCHED_SHA256)

    def test_second_run_is_refused_clearly(self):
        with self.assertRaisesRegex(lc1.RevisionError, 'déjà appliquée'):
            lc1.revise(load())

    def test_unexpected_input_is_refused(self):
        data = copy.deepcopy(load())
        data['weeks'][0]['days'][0]['title'] += ' (modifié)'
        with self.assertRaisesRegex(lc1.RevisionError, 'Asset inattendu'):
            lc1.revise(data)

    def test_cli_second_run_fails_without_writing(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / 'programme_v33.json.gz'
            shutil.copy(ASSET, target)
            before = target.read_bytes()
            result = subprocess.run(
                [sys.executable, str(TOOLS / 'lc1_revision_s12_s19.py'), '--assets', tmp],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertIn('ÉCHEC LC1', result.stderr)
            self.assertIn('déjà appliquée', result.stderr)
            self.assertEqual(target.read_bytes(), before)

    def test_new_ids_are_unique_sequential_and_never_reused(self):
        ids = [e['id'] for w in load()['weeks'] for d in w['days'] for e in d['exercises']]
        self.assertEqual(len(ids), len(set(ids)))
        new = [i for i in ids if i.startswith('B2-L1-')]
        self.assertEqual(new, [f'B2-L1-{n:03d}' for n in range(1, 67)])
        self.assertEqual(len(ids), 1818)


if __name__ == '__main__':
    unittest.main()
