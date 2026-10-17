"""L10 (KT-052, KT-054) : modèles de périodisation et identifiants du pack
référencés par le générateur (lib/program_generator.dart)."""
import gzip
import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _gz(name):
    return json.loads(gzip.decompress((ROOT / 'assets/content' / name).read_bytes()))


class ProgramModelsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.models = json.loads((ROOT / 'assets/program_models.json').read_text(encoding='utf-8'))
        cls.details = _gz('details.json.gz')['exercices']
        cls.chains = {c['id'] for c in _gz('progressions.json.gz')['chaines']}
        cls.source = (ROOT / 'lib/program_generator.dart').read_text(encoding='utf-8')

    def test_models_complete(self):
        m = self.models
        self.assertEqual(m['schema'], 1)
        for key in ('linear', 'undulating', 'block', 'health', 'expert_streetlifting'):
            self.assertIn(key, m['models'])
            self.assertIn('simple', m['models'][key]['explain'])
            self.assertIn('technical', m['models'][key]['explain'])
        for key in ('linear', 'undulating', 'block', 'health'):
            loads = m['models'][key]['loadWeeks']
            self.assertTrue(3 <= loads <= 5, key)  # cycle de 4 à 6 semaines
        self.assertEqual(m['volume']['start'], [6, 8, 10, 12, 14])
        self.assertEqual(m['volume']['ceilingAbove'], 6)
        self.assertEqual(m['levels']['pushups'], [10, 25, 45, 70])
        self.assertEqual(m['levels']['pullups'], [1, 6, 13, 21])
        self.assertEqual(m['levels']['squatRatio'], [0.75, 1.25, 1.6, 2.0])
        self.assertEqual([s[0] for s in m['warmup']['ramp']['heavy']], [40, 60, 75, 85])
        self.assertTrue(0.4 <= 1 - m['taper']['volumeFactor'] <= 0.6)

    def test_referenced_exercises_exist_and_are_animated(self):
        ids = set(re.findall(r"'([a-z0-9]+(?:-[a-z0-9]+)+)'", self.source))
        ids -= {'avant-bras', 'mini-test'}  # groupe musculaire, suffixe
        self.assertGreater(len(ids), 30)
        for i in sorted(ids):
            self.assertIn(i, self.details, i)
            d = self.details[i]
            self.assertEqual(d['pose']['statut'], 'disponible', i)
            self.assertTrue(d['generateur'], i)
            self.assertIsNone(d['doublon_de'], i)

    def test_referenced_chains_exist(self):
        used = set()
        for block in re.findall(r"chains: \[([^\]]*)\]", self.source):
            used |= set(re.findall(r"'([a-z_]+)'", block))
        self.assertTrue(used)
        self.assertLessEqual(used, self.chains)


if __name__ == '__main__':
    unittest.main()
