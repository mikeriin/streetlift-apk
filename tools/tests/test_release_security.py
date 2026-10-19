"""Régressions KT-001 ; aucune vraie clé ni mot de passe dans les fixtures."""
import base64
import hashlib
import contextlib
import io
import os
from pathlib import Path, PurePosixPath
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from package_release import package
from release_security import PackagingError, check_archive, check_content
from signing import (BASE64_NAME, PASSWORD_NAME, SigningError, restore, secret_bytes,
                     verify_apk, verify_key, verify_restored)


class SigningTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.raw = b'invalid-container-for-isolated-tests'
        self.env = dict(os.environ)
        self.env[BASE64_NAME] = base64.b64encode(self.raw).decode()
        self.env[PASSWORD_NAME] = 'fixture-' + 'only'

    def test_each_secret_required_and_invalid_base64_rejected(self):
        for name in (BASE64_NAME, PASSWORD_NAME):
            env = dict(self.env)
            del env[name]
            with self.assertRaisesRegex(SigningError, name):
                restore(self.root, env)
            self.assertFalse((self.root / 'signing').exists())
        self.env[BASE64_NAME] = '%%%'
        with self.assertRaisesRegex(SigningError, 'Base64 strict'):
            secret_bytes(self.env)

    def test_restoration_creates_directories_and_private_file(self):
        with patch('signing.verify_key') as verify:
            restore(self.root, self.env)
        target = self.root / 'signing/kalis_track.p12'
        self.assertEqual(target.read_bytes(), self.raw)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        verify.assert_called_once()
        self.assertEqual(list(target.parent.glob('.restore-*')), [])

    def test_invalid_secret_keeps_existing_copy_and_removes_temporary(self):
        target = self.root / 'signing/kalis_track.p12'
        target.parent.mkdir()
        target.write_bytes(b'existing-copy')
        with patch('signing.verify_key', side_effect=SigningError('refus')):
            with self.assertRaises(SigningError):
                restore(self.root, self.env)
        self.assertEqual(target.read_bytes(), b'existing-copy')
        self.assertEqual(list(target.parent.glob('.restore-*')), [])
        with patch('signing.verify_key'):
            with self.assertRaisesRegex(SigningError, 'autre copie locale'):
                restore(self.root, self.env)
        self.assertEqual(target.read_bytes(), b'existing-copy')

    def test_stale_file_and_symlink_are_rejected(self):
        target = self.root / 'signing/kalis_track.p12'
        target.parent.mkdir()
        target.write_bytes(b'stale')
        with self.assertRaisesRegex(SigningError, 'différente'):
            verify_restored(self.root, self.env)
        target.unlink()
        source = self.root / 'preserve'
        source.write_bytes(b'source')
        target.symlink_to(source)
        with self.assertRaisesRegex(SigningError, 'lien symbolique'):
            restore(self.root, self.env)
        self.assertEqual(source.read_bytes(), b'source')

    def test_keytool_errors_never_echo_external_output(self):
        failure = subprocess.CompletedProcess([], 1, b'private stdout', b'private stderr')
        with patch('signing.subprocess.run', return_value=failure) as run:
            with self.assertRaises(SigningError) as error:
                verify_key(self.root, self.root / 'key', self.env)
        self.assertNotIn('private stdout', str(error.exception))
        self.assertNotIn('private stderr', str(error.exception))
        self.assertNotIn(self.env[PASSWORD_NAME], run.call_args.args[0])
        self.assertIn('-storepass:env', run.call_args.args[0])

    def test_other_certificate_and_certificate_without_private_key_rejected(self):
        signing = self.root / 'signing'
        signing.mkdir()
        cert = b'public-certificate-fixture'
        (signing / 'certificate.sha256').write_text('0' * 64)
        with patch('signing.keytool', return_value=cert):
            with self.assertRaisesRegex(SigningError, 'Certificat différent'):
                verify_key(self.root, signing / 'key', self.env)
        (signing / 'certificate.sha256').write_text(hashlib.sha256(cert).hexdigest())
        with patch('signing.keytool', side_effect=[cert, SigningError('clé privée inaccessible')]):
            with self.assertRaisesRegex(SigningError, 'privée'):
                verify_key(self.root, signing / 'key', self.env)

class ApkCertificateTests(unittest.TestCase):
    """Protocole de l'adaptateur Java simulé ; aucune signature d'APK ici."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'signing').mkdir()
        self.expected = 'a1' * 32
        (self.root / 'signing/certificate.sha256').write_text(self.expected)
        self.apk = self.root / 'fixture.apk'
        self.apk.write_bytes(b'placeholder-not-a-real-apk')
        self.apksigner = self.root / 'sdk/apksigner'
        self.apksigner.parent.mkdir()
        self.apksigner.write_text('placeholder-not-an-executable')
        self.jar = self.apksigner.parent / 'lib/apksigner.jar'
        self.jar.parent.mkdir()
        self.jar.write_bytes(b'placeholder-not-a-real-jar')
        self.helper = self.root / 'tools/VerifyApkCertificate.java'
        self.helper.parent.mkdir()
        self.helper.write_text('// placeholder for subprocess-isolated tests')

    def verify_output(self, output, rc=0):
        result = subprocess.CompletedProcess([], rc, output, 'UNTRUSTED STDERR')
        captured = io.StringIO()
        with patch('signing.subprocess.run', return_value=result), contextlib.redirect_stdout(captured):
            verify_apk(self.apk, self.apksigner, self.root)
        return captured.getvalue()

    def test_exact_verified_identity_accepted_without_echoing_stderr(self):
        diagnostic = self.verify_output(f'KT_APK_CERT_V1 OK {self.expected}\n')
        self.assertIn(self.expected, diagnostic)
        self.assertNotIn('UNTRUSTED STDERR', diagnostic)

    def test_subprocess_uses_selected_jar_absolute_paths_and_no_signing_secrets(self):
        result = subprocess.CompletedProcess([], 0, f'KT_APK_CERT_V1 OK {self.expected}\n', '')
        private_environment = {
            BASE64_NAME: 'sensitive-fixture-base64',
            PASSWORD_NAME: 'sensitive-fixture-access',
            'KT_ADAPTER_TEST': 'preserved',
        }
        with patch.dict(os.environ, private_environment), patch('signing.subprocess.run', return_value=result) as run:
            with contextlib.redirect_stdout(io.StringIO()):
                verify_apk(self.apk, self.apksigner, self.root)
        run.assert_called_once()
        self.assertEqual(run.call_args.args[0], [
            'java', '--class-path', str(self.jar.resolve()), str(self.helper.resolve()),
            str(self.apk.resolve()), self.expected,
        ])
        arguments = run.call_args.kwargs
        self.assertTrue(arguments['capture_output'])
        self.assertTrue(arguments['text'])
        self.assertEqual(arguments['timeout'], 60)
        self.assertNotIn(BASE64_NAME, arguments['env'])
        self.assertNotIn(PASSWORD_NAME, arguments['env'])
        self.assertEqual(arguments['env']['KT_ADAPTER_TEST'], 'preserved')

    def test_claimed_success_requires_exact_reference_certificate(self):
        with self.assertRaises(SigningError):
            self.verify_output('KT_APK_CERT_V1 OK ' + 'b2' * 32 + '\n')

    def test_failure_statuses_remain_failures_and_never_echo_tool_output(self):
        for status in ('CRYPTO', 'SIGNERS', 'ROTATION', 'TOOL'):
            with self.subTest(status=status):
                with self.assertRaises(SigningError) as error:
                    self.verify_output(f'KT_APK_CERT_V1 {status}\n', rc=1)
                self.assertNotIn('UNTRUSTED STDERR', str(error.exception))

    def test_mismatch_diagnostic_contains_only_validated_public_digests(self):
        observed = ['b2' * 32, 'c3' * 32]
        with self.assertRaises(SigningError) as error:
            self.verify_output('KT_APK_CERT_V1 MISMATCH ' + ','.join(observed) + '\n', rc=1)
        message = str(error.exception)
        self.assertIn(self.expected, message)
        for digest in observed:
            self.assertIn(digest, message)
        self.assertNotIn('UNTRUSTED STDERR', message)

    def test_protocol_status_and_exit_code_must_agree(self):
        for rc, output in [
            (1, f'KT_APK_CERT_V1 OK {self.expected}\n'),
            (2, f'KT_APK_CERT_V1 OK {self.expected}\n'),
            (-9, f'KT_APK_CERT_V1 OK {self.expected}\n'),
            (0, 'KT_APK_CERT_V1 CRYPTO\n'),
            (0, 'KT_APK_CERT_V1 SIGNERS\n'),
            (0, 'KT_APK_CERT_V1 ROTATION\n'),
            (0, 'KT_APK_CERT_V1 TOOL\n'),
            (0, 'KT_APK_CERT_V1 MISMATCH ' + 'b2' * 32 + '\n'),
        ]:
            with self.subTest(rc=rc, output=output), self.assertRaises(SigningError):
                self.verify_output(output, rc)

    def test_missing_duplicate_truncated_and_untrusted_protocol_rejected(self):
        valid = f'KT_APK_CERT_V1 OK {self.expected}\n'
        rejected = [
            '', valid.rstrip('\n'), valid + valid, valid + '\n',
            ' ' + valid, valid.replace('OK ', 'OK  '),
            valid.replace(self.expected, self.expected.upper()),
            valid.replace(self.expected, self.expected[:-1]),
            valid.replace(self.expected, self.expected + 'a'),
            valid.replace(self.expected, 'z' * 64),
            valid.replace('CERT_V1', 'CERT_V2'),
            valid + 'PRIVATE OR UNRELATED OUTPUT\n',
            'PRIVATE OR UNRELATED OUTPUT\n' + valid,
            'Number of signers: 1\nSigner #1 certificate SHA-256 digest: ' + self.expected + '\n',
        ]
        for output in rejected:
            with self.subTest(output=output):
                with self.assertRaises(SigningError) as error:
                    self.verify_output(output)
                self.assertNotIn('PRIVATE OR UNRELATED OUTPUT', str(error.exception))
                self.assertNotIn('UNTRUSTED STDERR', str(error.exception))

    def test_malformed_failure_protocol_never_echoes_untrusted_values(self):
        for output in [
            'KT_APK_CERT_V1 MISMATCH sensitive-fixture-value\n',
            'KT_APK_CERT_V1 MISMATCH ' + 'b2' * 32 + ',sensitive-fixture-value\n',
            'KT_APK_CERT_V1 MISMATCH ' + 'b2' * 32 + ',\n',
            'KT_APK_CERT_V1 CRYPTO sensitive-fixture-value\n',
            'KT_APK_CERT_V1 UNKNOWN\n',
        ]:
            with self.subTest(output=output):
                with self.assertRaises(SigningError) as error:
                    self.verify_output(output, rc=1)
                self.assertNotIn('sensitive-fixture-value', str(error.exception))
                self.assertNotIn('UNTRUSTED STDERR', str(error.exception))

    def test_missing_apk_helper_or_selected_jar_prevents_subprocess(self):
        for path in (self.apk, self.helper, self.jar):
            with self.subTest(path=path):
                original = path.read_bytes()
                path.unlink()
                try:
                    with patch('signing.subprocess.run') as run, self.assertRaises(SigningError):
                        verify_apk(self.apk, self.apksigner, self.root)
                    run.assert_not_called()
                finally:
                    path.write_bytes(original)

    def test_java_missing_and_timeout_are_sanitized_explicit_failures(self):
        failures = [
            FileNotFoundError('sensitive-tool-error'),
            subprocess.TimeoutExpired('sensitive-tool-error', 60,
                                      output='sensitive-tool-output', stderr='sensitive-tool-stderr'),
        ]
        for failure in failures:
            with self.subTest(failure=type(failure).__name__):
                with patch('signing.subprocess.run', side_effect=failure), self.assertRaises(SigningError) as error:
                    verify_apk(self.apk, self.apksigner, self.root)
                for marker in ('sensitive-tool-error', 'sensitive-tool-output', 'sensitive-tool-stderr'):
                    self.assertNotIn(marker, str(error.exception))

    def test_invalid_reference_rejected_before_starting_java(self):
        (self.root / 'signing/certificate.sha256').write_text('malformed-reference')
        with patch('signing.subprocess.run') as run, self.assertRaises(SigningError):
            verify_apk(self.apk, self.apksigner, self.root)
        run.assert_not_called()


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'project'
        self.root.mkdir()
        (self.root / 'pubspec.yaml').write_text('version: 2.5.0+51\n')
        self.output = self.root.parent / 'delivery.zip'

    def put(self, name, data):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)

    def test_secrets_artifacts_caches_excluded_public_reference_and_wrapper_preserved(self):
        forbidden = ['signing/kalis_track.p12', 'backup/copy.pfx', 'copy.jks', 'local.key',
                     'key.properties', '.env', '.env.local', 'build/app.apk', 'other.aab',
                     'backup.zip', '.dart_tool/cache', 'nested/__pycache__/cache.pyc']
        for path in forbidden:
            self.put(path, b'fixture')
        allowed = ['signing/certificate.sha256', 'android/gradle/wrapper/gradle-wrapper.jar',
                   'android/gradlew', 'public.pem']
        for path in allowed:
            self.put(path, b'public-fixture')
        package(self.root, self.output)
        check_archive(self.output)
        with zipfile.ZipFile(self.output) as z:
            names = {name.removeprefix('streetlift_tracker/') for name in z.namelist()}
        self.assertFalse(names & set(forbidden))
        self.assertTrue(set(allowed) <= names)
        self.assertTrue((self.root / forbidden[0]).exists())

    def test_private_content_and_plaintext_passwords_rejected_without_echo(self):
        # Entête synthétique, pas une clé ; teste la reconnaissance d'un conteneur renommé.
        container = bytes.fromhex('30820100020103300b06092a864886f70d010701') + b'x' * 90
        pem = ('-----BEGIN ' + 'PRIVATE KEY-----').encode()
        value = b'"fixture-sensitive-value"'
        assignments = [b''.join([b'store', b'Password', b' = ', value]),
                       b''.join([b'KALIS_KEYSTORE_', b'PASSWORD', b': ', value]),
                       b''.join([b'key', b'Password', b' = env ', b'?', b': ', value]),
                       b''.join([b'env.setdefault(', b'"KEYSTORE_', b'PASSWORD", ', value, b')']),
                       b''.join([b'env.get(', b'"KEYSTORE_', b'PASSWORD", ', value, b')'])]
        for data in [container, base64.b64encode(container), pem, *assignments]:
            with self.assertRaises(PackagingError) as error:
                check_content(PurePosixPath('docs/copy.txt'), data)
            self.assertNotIn('fixture-sensitive-value', str(error.exception))

    def test_rejected_delivery_preserves_previous_archive(self):
        self.output.write_bytes(b'previous-delivery')
        self.put('docs/copy.txt', ("-----BEGIN " + "RSA PRIVATE KEY-----").encode())
        with self.assertRaises(PackagingError):
            package(self.root, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous-delivery')
        self.assertFalse(self.output.with_name(self.output.name + '.tmp').exists())

    def test_external_archive_rejects_traversal_secret_and_wrong_root(self):
        for name in ['streetlift_tracker/../escape', 'other/file',
                     'streetlift_tracker/signing/copy.p12']:
            with zipfile.ZipFile(self.output, 'w') as z:
                z.writestr(name, b'fixture')
            with self.assertRaises(PackagingError):
                check_archive(self.output)

    def test_symlink_refused(self):
        (self.root / 'link').symlink_to(self.root / 'pubspec.yaml')
        with self.assertRaises(PackagingError):
            package(self.root, self.output)


if __name__ == '__main__':
    unittest.main()
