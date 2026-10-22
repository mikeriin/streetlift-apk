"""UI5 (refonte UI) : illustrations intouchables (cahier UI §1, §6.1) et
contrôles bloquants sur tout `lib/` (jetons, menus)."""
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _load(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / f'tools/{name}.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


ill = _load('check_ui_illustrations')
tokens = _load('check_ui_tokens')


class IllustrationsTest(unittest.TestCase):
    def test_illustrations_identiques_a_la_base(self):
        attendu = json.loads(ill.RELEVE.read_text(encoding='utf-8'))
        self.assertGreater(len(attendu), 50)
        self.assertEqual(ill.ecarts(attendu, ill.empreintes()), [])

    def test_ecart_detecte(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'lib').mkdir()
            (root / 'lib/brand.dart').write_text('a')
            avant = ill.empreintes(root)
            (root / 'lib/brand.dart').write_text('b')
            self.assertEqual(
                ill.ecarts(avant, ill.empreintes(root)),
                ['modifié : lib/brand.dart'],
            )

    def test_conteneurs_non_suivis(self):
        suivis = ill.suivis()
        for rel in ['lib/koach/koach_bubble.dart',
                    'lib/koach/koach_home_card.dart',
                    'lib/koach/koach_gallery_screen.dart']:
            self.assertNotIn(rel, suivis)


class ToutLibTest(unittest.TestCase):
    def test_jetons_et_menus_a_zero_sur_tout_lib(self):
        report = tokens.scan(menus=True)
        total = sum(r['total'] for r in report.values())
        self.assertEqual(total, 0, {k: v for k, v in report.items() if v['total']})


if __name__ == '__main__':
    unittest.main()
