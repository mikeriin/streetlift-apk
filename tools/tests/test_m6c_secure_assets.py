# -*- coding: utf-8 -*-
"""M6c : ressources sous licence chiffrées (`assets_secure/`,
tools/secure_assets.py) et refus des modèles 3D en clair par les contrôles
de l'arbre (tools/release_security.py)."""
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))

import release_security  # noqa: E402
import secure_assets  # noqa: E402


class SecureAssetsTest(unittest.TestCase):
    def test_manifeste(self):
        data = secure_assets.load_manifest()
        roles = {e['role'] for e in data['fichiers']}
        self.assertEqual(roles, {'source', 'execution', 'source_zones'})
        for entry in data['fichiers']:
            self.assertTrue(entry['chiffre'].startswith('assets_secure/'), entry)
            self.assertTrue(entry['chiffre'].endswith('.enc'), entry)
            self.assertEqual(len(entry['sha256']), 64)
            self.assertNotIn('KT_ASSETS_KEY=', entry.get('description', ''))
        self.assertIn('KT_ASSETS_KEY', data['cle'])

    def test_arbre_sans_clair(self):
        tracked = [p.as_posix() for p in release_security.tracked_files(ROOT)]
        self.assertEqual(secure_assets.check(tracked, log=lambda *_: None), 3)
        with self.assertRaises(secure_assets.SecureAssetError):
            secure_assets.check(tracked + ['assets/anatomy/mannequin.glb'], log=lambda *_: None)
        with self.assertRaises(secure_assets.SecureAssetError):
            secure_assets.check(tracked + ['assets_secure/modele.glb'], log=lambda *_: None)

    def test_cle_absente(self):
        env = dict(os.environ)
        env.pop(secure_assets.KEY_ENV, None)
        result = subprocess.run([sys.executable, str(ROOT / 'tools/secure_assets.py'), 'decrypt'],
                                env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('KT_ASSETS_KEY', result.stderr)

    @unittest.skipUnless(shutil.which('openssl'), 'openssl requis')
    def test_aller_retour(self):
        # Même commande qu'en production, clé de test jetable.
        with tempfile.TemporaryDirectory() as d:
            d = Path(d)
            (d / 'a.bin').write_bytes(bytes(range(256)) * 40)
            env = {**os.environ, secure_assets.KEY_ENV: 'cle-de-test-jetable'}
            subprocess.run(secure_assets.OPENSSL + ['-in', str(d / 'a.bin'), '-out',
                                                    str(d / 'a.enc')], env=env, check=True)
            self.assertEqual((d / 'a.enc').read_bytes()[:8], b'Salted__')
            subprocess.run(secure_assets.OPENSSL + ['-d', '-in', str(d / 'a.enc'), '-out',
                                                    str(d / 'b.bin')], env=env, check=True)
            self.assertEqual((d / 'a.bin').read_bytes(), (d / 'b.bin').read_bytes())
            # Mauvaise clé : refus d'OpenSSL (remplissage invalide) ou, une
            # fois sur 256 environ, un clair illisible ; dans les deux cas
            # jamais le fichier d'origine (secure_assets vérifie l'empreinte).
            bad = {**os.environ, secure_assets.KEY_ENV: 'mauvaise-cle'}
            result = subprocess.run(secure_assets.OPENSSL + ['-d', '-in', str(d / 'a.enc'), '-out',
                                                             str(d / 'c.bin')], env=bad,
                                    capture_output=True)
            self.assertTrue(result.returncode != 0 or (d / 'c.bin').read_bytes()
                            != (d / 'a.bin').read_bytes())


class TreeRefusesClearModelsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / 'lib').mkdir()
        (self.root / 'lib/a.dart').write_text('void main() {}\n')

    def tearDown(self):
        self.tmp.cleanup()

    def test_modele_en_clair_refuse(self):
        for name in ('assets/anatomy/mannequin.glb', 'x/perso.fbx', 'y/m.fsceneb',
                     'z/modele.OBJ'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'glTF')
            with self.assertRaises(release_security.PackagingError, msg=name):
                release_security.check_tree(self.root, ['lib/a.dart', name])

    def test_ressource_chiffree_budget_a_part(self):
        (self.root / 'assets_secure').mkdir()
        big = self.root / 'assets_secure/perso.fbx.enc'
        big.write_bytes(b'Salted__' + b'\0' * (release_security.LIMIT + 1000))
        count, size = release_security.check_tree(self.root, ['lib/a.dart',
                                                              'assets_secure/perso.fbx.enc'])
        self.assertEqual(count, 2)
        self.assertGreater(size, release_security.LIMIT)
        # Un fichier de assets_secure/ sans en-tête OpenSSL est refusé.
        big.write_bytes(b'glTF' + b'\0' * 100)
        with self.assertRaises(release_security.PackagingError):
            release_security.check_tree(self.root, ['assets_secure/perso.fbx.enc'])


if __name__ == '__main__':
    unittest.main()
