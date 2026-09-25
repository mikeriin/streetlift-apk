import gzip
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from program_math import rest_seconds, round_step
from pack_assets import pack
from verify_project import verify


class ToolsTests(unittest.TestCase):
    def test_rounding_matches_excel_half_away_from_zero(self):
        self.assertEqual(round_step(11.25, 2.5), 12.5)
        self.assertEqual(round_step(-11.25, 2.5), -12.5)
        self.assertEqual(round_step(26.25, 2.5), 27.5)

    def test_rest_ranges_and_mixed_units(self):
        self.assertEqual(rest_seconds('1 min 30 s'), 90)
        self.assertEqual(rest_seconds('2–3 min'), 180)
        self.assertEqual(rest_seconds('30-45 s'), 45)
        self.assertIsNone(rest_seconds('≥ 20 min après les dips'))
        self.assertIsNone(rest_seconds('12 min au total'))

    def test_pack_is_reproducible_and_preserves_sources(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / 'programme_v33.json'
            source.write_bytes(b'{"test":true}')
            pack(root)
            first = (root / 'programme_v33.json.gz').read_bytes()
            pack(root)
            self.assertEqual(first, (root / 'programme_v33.json.gz').read_bytes())
            self.assertEqual(gzip.decompress(first), source.read_bytes())

    def test_shipped_assets_and_android_identity(self):
        # LC1 (KT-037) : 1 954 − 202 + 66 exercices.
        self.assertEqual(verify(), (1818, 505))


if __name__ == '__main__':
    unittest.main()
