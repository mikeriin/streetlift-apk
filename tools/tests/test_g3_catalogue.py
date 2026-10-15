"""G3 (dev6.2.0) : base d'exercices v1.1 dans l'application.

- l'asset `assets/catalog/catalog_v1.json.gz` est la copie octet pour octet
  de celui du paquet étiqueté `kalis_core` ;
- la correspondance et son rapport sont à jour (régénération à l'identique) ;
- chaque ancien exercice est relié par règle ou relu (une seule fois) ;
- chaque intitulé du programme embarqué a un exercice, sauf le bilan.
"""
import gzip
import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools/correspondance'))
import build_correspondance as bc  # noqa: E402


class CatalogueG3Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.table = json.loads((ROOT / 'assets/catalog/correspondance.json').read_text('utf-8'))
        cls.catalog = json.loads(gzip.decompress((ROOT / 'assets/catalog/catalog_v1.json.gz').read_bytes()))
        cls.ids = {e['id'] for e in cls.catalog['exercices']}

    def test_asset_is_byte_copy_of_package(self):
        app = (ROOT / 'assets/catalog/catalog_v1.json.gz').read_bytes()
        pkg = (ROOT / 'packages/kalis_core/data/catalog_v1.json.gz').read_bytes()
        self.assertEqual(app, pkg)
        self.assertEqual(self.table['catalogue']['sha256_gz'], hashlib.sha256(app).hexdigest())
        self.assertEqual(self.catalog['source']['version'], '1.1.0')
        self.assertEqual(len(self.ids), 1039)

    def test_generated_files_are_up_to_date(self):
        out = subprocess.run([sys.executable, str(ROOT / 'tools/correspondance/build_correspondance.py'), '--check'],
                             capture_output=True, text=True)
        self.assertEqual(out.returncode, 0, out.stdout + out.stderr)

    def test_every_old_exercise_is_reviewed_once(self):
        old = json.loads(gzip.decompress((ROOT / 'assets/content/index.json.gz').read_bytes()))
        review = json.loads((ROOT / 'tools/correspondance/relecture_g3.json').read_text('utf-8'))['entrees']
        reviewed = [r['old_id'] for r in review]
        self.assertEqual(len(reviewed), len(set(reviewed)))
        self.assertEqual(set(self.table['ids']), {e['id'] for e in old['exercices']})
        auto = {k for k, v in self.table['confiance'].items() if v == 'auto'}
        self.assertFalse(auto & set(reviewed))
        for r in review:
            self.assertIn(r['confiance'], ('sur', 'proche', 'aucun'), r)
            self.assertTrue(r['note'].strip(), r)
            if r['new_id'] is not None:
                self.assertIn(r['new_id'], self.ids, r)

    def test_targets_exist(self):
        for k, v in self.table['ids'].items():
            if v is not None:
                self.assertIn(v, self.ids, k)
        for k, v in self.table['noms'].items():
            self.assertIn(v, self.ids, k)

    def test_owner_program_labels_mapped(self):
        program = json.loads(gzip.decompress((ROOT / 'assets/programme_v33.json.gz').read_bytes()))
        labels = {x['name'] for w in program['weeks'] for d in w['days'] for x in d['exercises']}
        noms = self.table['noms']
        missing = sorted(l for l in labels
                         if l not in noms and l.split(' — ')[0].split(' [')[0].strip() not in noms)
        self.assertEqual(missing, ['BILAN — report des résultats'])
        # Les lifts du programme de streetlifting vont aux lifts de compétition.
        self.assertEqual(noms['BACK SQUAT — lift principal'], 'sl-squat-competition')
        self.assertEqual(noms['DIP LESTÉ — lift principal'], 'sl-dips-leste')
        self.assertEqual(noms['TRACTION LESTÉE — lift principal'], 'sl-traction-lestee')
        self.assertEqual(noms['MUSCLE-UP LESTÉ — lift n°1, avant tout tirage'], 'sl-muscle-up-leste')

    def test_normalisation(self):
        self.assertEqual(bc.norm('Développé  COUCHÉ (barre)'), 'developpe couche barre')
        self.assertEqual(bc.norm('Œuf’s'), "oeuf s")


if __name__ == '__main__':
    unittest.main()
