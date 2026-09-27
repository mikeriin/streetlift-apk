"""L9b (KT-079/080) : contrôles des données du pack intégrées à l'application."""
import gzip
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def gz(rel):
    return json.loads(gzip.decompress((ROOT / rel).read_bytes()))


class ContentPackTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.index = gz('assets/content/index.json.gz')
        cls.v1 = gz('test/fixtures/l9b/exercises_db_v1.json.gz')
        cls.meta = json.loads((ROOT / 'assets/content/pack.json').read_text())

    def test_pack_version_and_fingerprint(self):
        self.assertEqual(self.meta['pack'], '2.0.0')
        self.assertEqual(self.meta['schema_exercice'], '2.1.0')
        self.assertEqual(self.meta['sha256'], '5a13a91e3171c303391e00123c24f5cb8e2577e775e4f4be60622351108f9086')
        self.assertEqual(self.meta['exercices'], 625)

    def test_v1_entries_unchanged(self):
        now = {e['n']: e for e in self.index['exercices']}
        self.assertEqual(len(self.v1), 505)
        for e in self.v1:
            self.assertIn(e['n'], now)
            self.assertEqual((now[e['n']]['g'], now[e['n']]['eq']), (e['g'], e['eq']), e['n'])
            self.assertIn(e['n'], self.index['base_v1'])

    def test_program_titles_mapped(self):
        program = gz('assets/programme_v33.json.gz')
        ids = {e['id'] for e in self.index['exercices']}
        titles = {ex['name'] for w in program['weeks'] for d in w['days'] for ex in d['exercises']}
        self.assertEqual(len(titles), 79)
        for t in titles:
            self.assertIn(self.index['programme_v33'][t]['id'], ids, t)

    def test_atlas_generated_from_pack(self):
        text = (ROOT / 'lib/atlas_data.dart').read_text()
        muscles = re.findall(r"AtlasRegion\('(face|dos)', 'muscle', '([a-z_]+)'", text)
        self.assertGreaterEqual(len(muscles), 100)
        self.assertEqual(len({m for _, m in muscles}), 51)
        self.assertEqual(text.count('AtlasMuscle(\''), 81)

    def test_parity_fixture(self):
        data = json.loads((ROOT / 'test/fixtures/l9b/pose_parity.json').read_text())
        self.assertEqual(len(data['exercices']), 20)
        self.assertTrue(all(len(x['samples']) == 5 for x in data['exercices']))
        views = {x['view'] for x in data['exercices']}
        self.assertEqual(views, {'profil', 'face'})

    def test_demo_status_consistent(self):
        poses = gz('assets/content/poses.json.gz')
        for e in self.index['exercices']:
            p = poses['exercices'][e['id']]
            self.assertEqual(p['statut'], e['demo'], e['id'])
            if p['statut'] != 'indisponible':
                self.assertIn(p['gabarit'], poses['gabarits'])
            else:
                self.assertTrue(p['motif'])


if __name__ == '__main__':
    unittest.main()
