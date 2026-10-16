"""Validation L1b sur fixtures synthétiques ; aucune clé générée."""
from pathlib import Path
import os
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_android_artifacts import elf_info, manifest_info, PACKAGE, run
from check_release_without_secrets import check
from signing import BASE64_NAME, PASSWORD_NAME


def elf(align=16384, relro=(0x4000, 0x4000), load_size=0x8000):
    data = bytearray(512)
    data[:6] = b'\x7fELF\x02\x01'
    struct.pack_into('<H', data, 18, 183)
    struct.pack_into('<Q', data, 32, 64)
    struct.pack_into('<HH', data, 54, 56, 2)
    struct.pack_into('<IIQQQQQQ', data, 64, 1, 6, 0, 0, 0, 512, load_size, align)
    struct.pack_into('<IIQQQQQQ', data, 120, 0x6474e552, 4, 0, relro[0], 0, 0, relro[1], 1)
    return bytes(data)


def manifest(**changes):
    fields = dict(package=PACKAGE, code='123', version='2.5.0', minimum='24', target='36', debug='false',
                  backup='android:allowBackup="true"')
    fields.update(changes)
    return '''<manifest xmlns:android="http://schemas.android.com/apk/res/android"
      package="{package}" android:versionCode="{code}" android:versionName="{version}">
      <uses-sdk android:minSdkVersion="{minimum}" android:targetSdkVersion="{target}"/>
      <uses-permission android:name="android.permission.VIBRATE"/>
      <application android:debuggable="{debug}" {backup}><activity android:name=".MainActivity" android:exported="true"/></application>
      </manifest>'''.format(**fields)


class ArtifactTests(unittest.TestCase):
    def test_final_manifest_identity_version_sdk_and_debug_are_enforced(self):
        result = manifest_info(manifest(), 123, '2.5.0')
        self.assertEqual(result['permissions'], ['android.permission.VIBRATE'])
        self.assertEqual(result['components'][0]['exported'], 'true')
        for changes in [dict(package='other'), dict(code='124'), dict(version='2.5.1'), dict(minimum='21'), dict(target='35'), dict(debug='true'),
                        dict(backup=''), dict(backup='android:allowBackup="false"'),
                        dict(backup='android:allowBackup="true" android:dataExtractionRules="@xml/rules"'),
                        dict(backup='android:allowBackup="true" android:fullBackupContent="@xml/rules"')]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                manifest_info(manifest(**changes), 123, '2.5.0')
        with self.assertRaises(ValueError):
            manifest_info('<manifest/>', 123, '2.5.0')

    def test_elf_accepts_aligned_and_whole_load_relro(self):
        self.assertEqual(elf_info(elf(), 'arm64-v8a')['load_alignments'], [16384])
        self.assertTrue(elf_info(elf(relro=(0, 0x5000), load_size=0x5000), 'arm64-v8a')['relro_checks'][0]['suffix_or_aligned'])

    def test_elf_rejects_4k_truncated_wrong_abi_and_relro_internal_4k_boundary(self):
        for raw, abi in [(elf(4096), 'arm64-v8a'), (elf()[:80], 'arm64-v8a'), (elf(), 'x86_64'), (elf(relro=(0, 0x5000)), 'arm64-v8a'), (elf(relro=(0x1000, 0x3000)), 'arm64-v8a')]:
            with self.subTest(abi=abi, length=len(raw)), self.assertRaises(ValueError):
                elf_info(raw, abi)

    def test_external_failure_does_not_leak_output_and_commands_receive_no_secrets(self):
        with patch.dict(os.environ, {BASE64_NAME: 'fixture', PASSWORD_NAME: 'fixture'}):
            with patch('verify_android_artifacts.subprocess.run', return_value=subprocess.CompletedProcess([], 1, 'private output', 'private error')) as call:
                with self.assertRaisesRegex(ValueError, '^Échec du contrôle : tool.$'):
                    run(['tool'])
                self.assertNotIn(BASE64_NAME, call.call_args.kwargs['env'])
                self.assertNotIn(PASSWORD_NAME, call.call_args.kwargs['env'])

    def test_unsigned_aab_rejected_by_real_java_verifier(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'unsigned.aab'
            with zipfile.ZipFile(path, 'w') as z:
                z.writestr('base/manifest/AndroidManifest.xml', 'fixture')
            java = Path(__file__).resolve().parents[1] / 'VerifyBundleSignature.java'
            result = subprocess.run(['java', str(java), str(path), '0' * 64], capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode, 1)
            self.assertIn('Signature AAB absente', result.stderr)
            self.assertEqual(result.stdout, '')


class ReleaseRefusalTests(unittest.TestCase):
    def test_unrelated_error_and_success_do_not_count_as_expected_refusal(self):
        for code, output in [(1, 'No Android SDK found'), (0, 'Release refusée : sont obligatoires')]:
            with tempfile.TemporaryDirectory() as folder:
                with patch('check_release_without_secrets.subprocess.run', return_value=subprocess.CompletedProcess([], code, output, '')):
                    with self.assertRaises(RuntimeError):
                        check(Path(folder))

    def test_each_case_uses_only_missing_or_synthetic_values_and_correct_target(self):
        results = [subprocess.CompletedProcess([], 1, 'Release refusée : sont obligatoires', '') for _ in range(4)]
        results.append(subprocess.CompletedProcess([], 1, 'Release refusée : BASE64 invalide', ''))
        with tempfile.TemporaryDirectory() as folder:
            with patch.dict(os.environ, {BASE64_NAME: 'private-input', PASSWORD_NAME: 'private-input'}):
                with patch('check_release_without_secrets.subprocess.run', side_effect=results) as call:
                    check(Path(folder))
                    self.assertEqual(call.call_count, 5)
                    self.assertEqual([c.args[0][2] for c in call.call_args_list], ['apk', 'appbundle', 'apk', 'appbundle', 'apk'])
                    for c in call.call_args_list:
                        self.assertNotEqual(c.kwargs['env'].get(BASE64_NAME), 'private-input')
                        self.assertNotEqual(c.kwargs['env'].get(PASSWORD_NAME), 'private-input')
