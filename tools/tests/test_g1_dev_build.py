"""G1 : build de développement (D2.4), CI des paquets, isolation du mode dev.

- build-apk.yml : l'APK (installé par le propriétaire) est construit avec
  `--dart-define=KALIS_DEV=true`, l'AAB (Play Store) sans ; `packages/**`
  déclenche le build ; les tests du mode dev tournent avec le drapeau ; la
  vérification des artefacts sait que seul libapp.so diffère et exige le
  code du mode dev dans l'APK et son absence dans l'AAB.
- ci-3d.yml : tâche `packages` (formatage, analyse sans remarque, tests,
  rapport du simulateur), publiée dans ci-out/packages/.
- Code : le drapeau est une constante de compilation ; tout le stockage
  passe par la vue de session (aucun accès direct à SharedPreferences
  hors de lib/session_prefs.dart et du mode dev) ; plus de DateTime.now()
  pour l'heure de l'application hors de l'horloge unique.
"""
import importlib.util
import re
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BUILD = (ROOT / '.github/workflows/build-apk.yml').read_text(encoding='utf-8')
CI = (ROOT / '.github/workflows/ci-3d.yml').read_text(encoding='utf-8')
MARKER = 'KALIS-DEV-SESSION-7F3A'


def _load_verify():
    sys.path.insert(0, str(ROOT / 'tools'))
    spec = importlib.util.spec_from_file_location('verify_android_artifacts', ROOT / 'tools/verify_android_artifacts.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BuildWorkflowTest(unittest.TestCase):
    def build_lines(self):
        return [l.strip() for l in BUILD.splitlines() if l.strip().startswith('flutter build ')]

    def test_apk_has_dev_flag_and_aab_does_not(self):
        lines = self.build_lines()
        apk = [l for l in lines if l.startswith('flutter build apk')]
        aab = [l for l in lines if l.startswith('flutter build appbundle')]
        self.assertEqual(len(apk), 1)
        self.assertEqual(len(aab), 1)
        self.assertIn('--dart-define=KALIS_DEV=true', apk[0])
        self.assertNotIn('KALIS_DEV', aab[0])
        self.assertIn('--release', apk[0])
        self.assertIn('--release', aab[0])

    def test_packages_trigger_and_dev_tests(self):
        paths = BUILD.split('paths:', 1)[1].split('workflow_dispatch', 1)[0]
        self.assertIn('- packages/**', paths)
        self.assertIn('--dart-define=KALIS_DEV=true test/g1_mode_dev_test.dart', BUILD)
        self.assertIn('--dev-apk', BUILD)

    def test_ci_packages_job(self):
        self.assertIn('\n  packages:\n', CI)
        run = CI.split('\n  packages:\n', 1)[1].split('\n  before:\n', 1)[0]
        for command in ('dart format --output=none --set-exit-if-changed .', 'dart analyze --fatal-infos',
                        'dart test', 'aucun paquet', '_cli.dart'):
            self.assertIn(command, run)
        self.assertIn('needs: [checks, packages, before, emulator]', CI)
        self.assertIn('ci-out/packages', CI)
        self.assertIn('--dart-define=KALIS_DEV=true test/g1_mode_dev_test.dart', CI)


class DevCodeTest(unittest.TestCase):
    def test_flag_is_compile_time_constant(self):
        flags = (ROOT / 'lib/dev/dev_flags.dart').read_text(encoding='utf-8')
        self.assertIn("const bool kDevBuild = bool.fromEnvironment('KALIS_DEV');", flags)
        session = (ROOT / 'lib/dev/dev_session.dart').read_text(encoding='utf-8')
        self.assertIn(f"const kDevMarker = '{MARKER}';", session)
        self.assertIn('0xFFFF1493', session)

    def test_storage_goes_through_session_view(self):
        allowed = {'session_prefs.dart', 'dev/dev_session.dart'}
        for path in sorted((ROOT / 'lib').rglob('*.dart')):
            name = path.relative_to(ROOT / 'lib').as_posix()
            text = path.read_text(encoding='utf-8')
            if name in allowed:
                continue
            code = '\n'.join(l for l in text.splitlines() if not l.strip().startswith('//'))
            self.assertNotIn('SharedPreferences.getInstance', code, name)

    def test_app_time_goes_through_clock(self):
        # Seules les durées des chronos (timers.dart) et l'heure réelle des
        # rappels Android (notifications.dart) restent sur DateTime.now.
        allowed = {'kalis_clock.dart', 'timers.dart', 'notifications.dart'}
        for path in sorted((ROOT / 'lib').rglob('*.dart')):
            name = path.relative_to(ROOT / 'lib').as_posix()
            if name in allowed:
                continue
            code = '\n'.join(l for l in path.read_text(encoding='utf-8').splitlines()
                             if not l.strip().startswith('//'))
            self.assertIsNone(re.search(r'DateTime\.now\(\)', code), name)


class NativeComparisonTest(unittest.TestCase):
    def make(self, folder, name, bundle, marker):
        prefix = 'base/lib/' if bundle else 'lib/'
        path = Path(folder) / name
        with zipfile.ZipFile(path, 'w') as z:
            for abi in ('armeabi-v7a', 'arm64-v8a', 'x86_64'):
                z.writestr(f'{prefix}{abi}/libflutter.so', b'flutter')
                z.writestr(f'{prefix}{abi}/libapp.so', b'app' + (MARKER.encode() if marker else b''))
        return path

    def native(self, marker):
        import hashlib
        return {f'{abi}/{lib}': {'sha256': hashlib.sha256(
            b'flutter' if lib == 'libflutter.so' else b'app' + (MARKER.encode() if marker else b'')).hexdigest()}
            for abi in ('armeabi-v7a', 'arm64-v8a', 'x86_64') for lib in ('libflutter.so', 'libapp.so')}

    def test_dev_apk_rules(self):
        verify = _load_verify()
        with tempfile.TemporaryDirectory() as folder:
            apk = self.make(folder, 'a.apk', False, True)
            aab = self.make(folder, 'a.aab', True, False)
            report = verify.compare_native(apk, aab, self.native(True), self.native(False), True)
            self.assertTrue(report['dev_apk'])
            # Sans --dev-apk, une différence reste refusée.
            with self.assertRaises(ValueError):
                verify.compare_native(apk, aab, self.native(True), self.native(False), False)
            # AAB contenant le code du mode dev : refusé.
            bad = self.make(folder, 'b.aab', True, True)
            with self.assertRaises(ValueError):
                verify.compare_native(apk, bad, self.native(True), self.native(True) | {
                    'x86_64/libflutter.so': {'sha256': 'x'}}, True)
            same = self.native(True)
            with self.assertRaises(ValueError):
                verify.compare_native(apk, bad, same, same, True)
            # APK sans le code du mode dev : refusé.
            plain = self.make(folder, 'c.apk', False, False)
            with self.assertRaises(ValueError):
                verify.compare_native(plain, aab, self.native(False), self.native(False), True)
            self.assertTrue(verify.compare_native(plain, aab, self.native(False), self.native(False),
                                                  False)['same_native_payloads'])


if __name__ == '__main__':
    unittest.main()
