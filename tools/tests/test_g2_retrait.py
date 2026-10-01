"""G2 (dev6.1.0) : nommage « devX.Y.Z » et retrait des WOD, des séances
manuelles et de L12.

- build-apk.yml : l'APK de développement reçoit `--build-name=dev<version du
  pubspec>`, l'AAB garde la version du pubspec ; même numéro de build.
- verify_android_artifacts.py : versionName attendu « devX.Y.Z » pour l'APK
  de développement, « X.Y.Z » pour l'AAB.
- Application : `kAppVersion` vaut « dev » + `kVersion` seulement avec
  KALIS_DEV ; `kVersion` suit le pubspec.
- Aucune référence morte aux fichiers retirés (imports, assets, partage
  d'image L12).
"""
import importlib.util
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILD = (ROOT / '.github/workflows/build-apk.yml').read_text(encoding='utf-8')
PUBSPEC = (ROOT / 'pubspec.yaml').read_text(encoding='utf-8')
SETTINGS = (ROOT / 'lib/settings_screen.dart').read_text(encoding='utf-8')

RETIRED_FILES = [
    'lib/wod_catalog.dart', 'lib/wod_formats.dart', 'lib/wod_generator.dart',
    'lib/wod_models.dart', 'lib/wod_preview.dart', 'lib/wod_screen.dart',
    'lib/wod_store.dart', 'lib/builder_screen.dart', 'lib/motivation.dart',
    'lib/motivation_screens.dart', 'lib/motiv_store.dart',
    'tools/wod_catalog_snapshot.dart',
]


def _load_verify():
    sys.path.insert(0, str(ROOT / 'tools'))
    spec = importlib.util.spec_from_file_location(
        'verify_android_artifacts', ROOT / 'tools/verify_android_artifacts.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _pubspec_version():
    return re.search(r'^version:\s*([^+\s]+)\+(\d+)', PUBSPEC, re.M).groups()


class DevNamingTest(unittest.TestCase):
    def build_lines(self):
        return [l.strip() for l in BUILD.splitlines()
                if l.strip().startswith('flutter build ')]

    def test_apk_is_named_dev_and_aab_is_not(self):
        lines = self.build_lines()
        apk = [l for l in lines if l.startswith('flutter build apk')]
        aab = [l for l in lines if l.startswith('flutter build appbundle')]
        self.assertEqual((len(apk), len(aab)), (1, 1))
        self.assertIn('--build-name="dev$VERSION"', apk[0])
        self.assertNotIn('--build-name', aab[0])
        # Même versionCode pour les deux formats (installation par-dessus).
        for line in (apk[0], aab[0]):
            self.assertIn('--build-number="$BUILD_NUMBER"', line)

    def test_version_variable_comes_from_pubspec(self):
        step = BUILD.split('flutter build apk', 1)[0].rsplit('run: |', 1)[1]
        self.assertIn('VERSION=$(sed -n', step)
        self.assertIn('pubspec.yaml', step)
        self.assertIn('test -n "$VERSION"', step)
        # La commande sed extrait bien « 6.1.0 » de « version: 6.1.0+96 ».
        pattern = re.search(r"sed -n '(s/.*?/p)' pubspec.yaml", step).group(1)
        self.assertTrue(pattern.startswith('s/^version:'))
        version, _ = _pubspec_version()
        self.assertRegex(version, r'^\d+\.\d+\.\d+$')

    def test_artifact_check_expects_dev_name_for_apk_only(self):
        verify = _load_verify()
        self.assertEqual(verify.apk_version_name('6.1.0', True), 'dev6.1.0')
        self.assertEqual(verify.apk_version_name('6.1.0', False), '6.1.0')
        source = (ROOT / 'tools/verify_android_artifacts.py').read_text(encoding='utf-8')
        self.assertIn('manifest_info(xml_apk, args.build_number, apk_version)', source)
        self.assertIn('manifest_info(xml_aab, args.build_number, version)', source)

    def test_app_label_follows_pubspec_and_dev_flag(self):
        version, build = _pubspec_version()
        # G6 correction 1 : 6.4.1 (dev6.4.1).
        self.assertEqual(version, '6.4.1')
        self.assertGreaterEqual(int(build), 98)
        self.assertIn(f"const kVersion = '{version}';", SETTINGS)
        self.assertIn("const kAppVersion = kDevBuild ? 'dev$kVersion' : kVersion;", SETTINGS)


class RetiredFeaturesTest(unittest.TestCase):
    def test_retired_files_are_gone(self):
        for name in RETIRED_FILES:
            self.assertFalse((ROOT / name).exists(), name)

    def test_no_dead_reference_left(self):
        stems = [Path(n).name for n in RETIRED_FILES]
        roots = ['lib', 'test', 'integration_test', 'tools/perf_device', 'android/app/src']
        for root in roots:
            for path in (ROOT / root).rglob('*'):
                if path.suffix not in ('.dart', '.kt', '.xml'):
                    continue
                text = path.read_text(encoding='utf-8')
                for stem in stems:
                    dead = f"'{stem}'" in text or f"/{stem}'" in text
                    self.assertFalse(dead, f'{path} : référence à {stem}')

    def test_l12_share_image_removed(self):
        kotlin = '\n'.join(p.read_text(encoding='utf-8')
                           for p in (ROOT / 'android/app/src/main/kotlin').rglob('*.kt'))
        self.assertNotIn('shareImage', kotlin)
        self.assertNotIn('kalis_progression.png', kotlin)
        # La copie d'avant G2 est partagée par le même fournisseur, en JSON.
        self.assertIn('kalis_copie_avant_suppression.json', kotlin)

    def test_pubspec_no_longer_describes_wod(self):
        self.assertNotIn('WOD', PUBSPEC)


if __name__ == '__main__':
    unittest.main()
