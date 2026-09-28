"""L13 (KT-074, KT-075, KT-076) : allégations, politique, visuel Google Play."""
from pathlib import Path
import importlib.util  # noqa: F401
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import check_claims  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]


class ClaimsTests(unittest.TestCase):
    def test_application_texts_have_no_forbidden_claim(self):
        found = check_claims.scan()
        self.assertEqual(found, [], '\n'.join(f'{w} : {l} → {t}' for w, l, t in found))

    def test_each_forbidden_term_is_detected(self):
        samples = [
            'Ce programme guérit le mal de dos.',
            'Soigne ta tendinite avec ces exercices.',
            'Un traitement naturel.',
            'Séance de rééducation du genou.',
            'Diagnostic de ta posture.',
            'Pour prévenir les blessures.',
            'Routine anti-blessure.',
            'Résultats garantis en 4 semaines.',
            'Perdre du poids vite.',
            'Brûle les graisses.',
            'Méthode cliniquement prouvée.',
            'Renforce ton immunité.',
            'Soulage la douleur.',
            'Thérapie par le mouvement.',
        ]
        for s in samples:
            with self.subTest(s=s):
                self.assertTrue(check_claims.scan(items=[('x', s)]), s)

    def test_negations_and_referrals_are_allowed(self):
        ok = [
            'Elle ne pose aucun diagnostic.',
            'Kalis Track n’est pas un dispositif médical.',
            'Sans garantie de résultat.',
            'Aucun objectif de poids.',
            'Demande l’avis d’un professionnel de santé.',
        ]
        for s in ok:
            with self.subTest(s=s):
                self.assertEqual(check_claims.scan(items=[('x', s)]), [])

    def test_adjacent_dart_literals_are_judged_as_one_sentence(self):
        code = "Text(\n  'Estimation sans '\n  'garantie de résultat.',\n)\n// 'soigne' en commentaire\n"
        strings = check_claims.dart_strings(code)
        self.assertEqual(strings, [(2, 'Estimation sans garantie de résultat.')])
        self.assertEqual(check_claims.scan(items=[('x', s) for _, s in strings]), [])


class PolicyAndStoreTests(unittest.TestCase):
    def test_privacy_policy_is_bundled_and_dated(self):
        policy = ROOT / 'assets/legal/confidentialite.md'
        text = policy.read_text(encoding='utf-8')
        self.assertIn('assets/legal/confidentialite.md', (ROOT / 'pubspec.yaml').read_text(encoding='utf-8'))
        for needle in ('18 ans et plus', 'Données de santé', 'Sauvegarde Android',
                       'Durée de conservation', 'Retirer mon accord', 'n\'est pas un dispositif médical'):
            self.assertIn(needle, text)
        self.assertNotIn('http', text, 'Aucune URL inventée dans la politique')

    def test_feature_graphic_file_is_1024x500_rgb_without_alpha(self):
        # Lecture de l'en-tête PNG (bibliothèque standard) : largeur, hauteur,
        # profondeur 8, type de couleur 2 (RGB, sans canal alpha).
        import struct
        data = (ROOT / 'docs/play/feature_graphic_1024x500.png').read_bytes()
        self.assertEqual(data[:8], b'\x89PNG\r\n\x1a\n')
        width, height, depth, color = struct.unpack('>IIBB', data[16:26])
        self.assertEqual((width, height, depth, color), (1024, 500, 8, 2))

    @unittest.skipUnless(__import__('importlib').util.find_spec('PIL'), 'Pillow absent : régénération non rejouée')
    def test_feature_graphic_is_regenerated_identically_on_bordeaux(self):
        from PIL import Image
        import generate_brand
        with tempfile.TemporaryDirectory() as tmp:
            out = generate_brand.feature_graphic(Path(tmp) / 'fg.png')
            image = Image.open(out)
            self.assertEqual(image.size, (1024, 500))
            self.assertEqual(image.mode, 'RGB')
            self.assertEqual(image.getpixel((0, 0)), (0x6B, 0x0C, 0x0C))
            self.assertEqual(image.getpixel((1023, 499)), (0x6B, 0x0C, 0x0C))
            self.assertEqual(out.read_bytes(), (ROOT / 'docs/play/feature_graphic_1024x500.png').read_bytes())

if __name__ == '__main__':
    unittest.main()
