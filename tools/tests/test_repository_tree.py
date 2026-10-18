"""M4c : dépôt en sources. Contrôles de l'arbre suivi par git (plus de ZIP)."""
import hashlib
import io
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compare_tree_with_zip import compare, tree_files, zip_files
from release_security import PackagingError, check_tree, tracked_files
import verify_project

ROOT = Path(__file__).resolve().parents[2]


def git(root, *args):
    env = {**os.environ, 'GIT_AUTHOR_NAME': 'test', 'GIT_AUTHOR_EMAIL': 'test@local',
           'GIT_COMMITTER_NAME': 'test', 'GIT_COMMITTER_EMAIL': 'test@local'}
    return subprocess.run(['git', *args], cwd=root, check=True, capture_output=True, env=env).stdout


@unittest.skipUnless(shutil.which('git'), 'git absent')
class TreeCheckTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        git(self.root, 'init', '-q')
        self.put('pubspec.yaml', b'version: 5.3.2+77\n')
        self.put('lib/main.dart', b'void main() {}\n')
        self.put('signing/certificate.sha256', b'0' * 64)

    def put(self, name, data):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        git(self.root, 'add', '-f', name)

    def test_clean_tree_accepted_file_by_file(self):
        count, size = check_tree(self.root)
        self.assertEqual(count, 3)
        self.assertEqual(size, len(b'version: 5.3.2+77\n') + len(b'void main() {}\n') + 64)

    def test_untracked_local_files_are_not_part_of_the_tree(self):
        (self.root / 'android').mkdir()
        (self.root / 'android/key.properties').write_text('fixture')
        (self.root / 'build').mkdir()
        (self.root / 'build/app.apk').write_bytes(b'fixture')
        self.assertEqual({p.as_posix() for p in tracked_files(self.root)},
                         {'pubspec.yaml', 'lib/main.dart', 'signing/certificate.sha256'})
        check_tree(self.root)

    def test_tracked_secret_artifact_cache_or_zip_rejected(self):
        for name in ['signing/kalis_track.p12', 'android/key.properties', 'copy.jks', 'release.keystore',
                     'local.key', '.env', '.env.prod', 'build/app.apk', 'app.aab', 'streetlift_tracker_v33.zip',
                     '.dart_tool/cache', 'tools/__pycache__/x.pyc', 'android/local.properties']:
            with self.subTest(name=name):
                self.put(name, b'fixture')
                with self.assertRaises(PackagingError):
                    check_tree(self.root)
                git(self.root, 'rm', '-q', '--cached', name)

    def test_renamed_private_container_and_plaintext_password_rejected_without_echo(self):
        container = bytes.fromhex('30820100020103300b06092a864886f70d010701') + b'x' * 90
        self.put('assets/image.png', container)
        with self.assertRaises(PackagingError) as error:
            check_tree(self.root)
        self.assertIn('assets/image.png', str(error.exception))
        git(self.root, 'rm', '-q', '--cached', 'assets/image.png')
        self.put('android/gradle.properties', b''.join([b'store', b'Pass', b'word', b'=', b'fixture-sensitive-value']))
        with self.assertRaises(PackagingError) as error:
            check_tree(self.root)
        self.assertNotIn('fixture-sensitive-value', str(error.exception))

    def test_symlink_rejected(self):
        (self.root / 'link').symlink_to(self.root / 'pubspec.yaml')
        git(self.root, 'add', 'link')
        with self.assertRaises(PackagingError):
            check_tree(self.root)


@unittest.skipUnless(shutil.which('git'), 'git absent')
class CompareWithZipTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        git(self.root, 'init', '-q')
        self.files = {'pubspec.yaml': b'version: 5.3.1+76\n', 'lib/a.dart': b'// a\n',
                      'assets/m.glb': bytes(range(256)), 'android/gradlew.bat': b'@echo off\r\n'}
        for name, data in self.files.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        (self.root / '.gitattributes').write_text('* text=auto eol=lf\n*.bat -text\n*.glb binary\n')
        git(self.root, 'add', '-A')
        git(self.root, 'commit', '-qm', 'arbre')
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as archive:
            for name, data in self.files.items():
                archive.writestr('streetlift_tracker/' + name, data)
        self.zip = zip_files(buffer.getvalue())

    def test_identical_except_admitted_repository_files(self):
        tree = tree_files('HEAD', self.root)
        self.assertEqual(tree['android/gradlew.bat'], hashlib.sha256(b'@echo off\r\n').hexdigest())
        result = compare(tree, self.zip)
        self.assertEqual(result['ajoutes'], ['.gitattributes'])
        self.assertEqual(result['modifies'], [])
        self.assertTrue(result['identique_hors_exceptions'])

    def test_any_other_difference_refused(self):
        (self.root / 'lib/a.dart').write_bytes(b'// b\n')
        (self.root / 'pubspec.yaml').write_bytes(b'version: 5.3.2+77\n')
        (self.root / 'lib/new.dart').write_bytes(b'// n\n')
        (self.root / 'assets/m.glb').unlink()
        git(self.root, 'add', '-A')
        git(self.root, 'commit', '-qm', 'changements')
        result = compare(tree_files('HEAD', self.root), self.zip)
        self.assertEqual(result['modifies'], ['lib/a.dart', 'pubspec.yaml'])
        self.assertEqual(result['absents'], ['assets/m.glb'])
        self.assertEqual(result['differences_non_admises'], ['lib/a.dart', 'lib/new.dart', 'assets/m.glb'])
        self.assertFalse(result['identique_hors_exceptions'])
        allowed = compare(tree_files('HEAD', self.root), self.zip, {'lib/a.dart', 'lib/new.dart'})
        self.assertEqual(allowed['differences_non_admises'], ['assets/m.glb'])

    def test_zip_entry_outside_project_folder_refused(self):
        buffer = io.BytesIO()
        with zipfile.ZipFile(buffer, 'w') as archive:
            archive.writestr('autre/pubspec.yaml', b'x')
        with self.assertRaises(ValueError):
            zip_files(buffer.getvalue())


@unittest.skipUnless((ROOT / '.git').exists() and shutil.which('git'), 'dépôt git absent')
class RepositoryTests(unittest.TestCase):
    """Le vrai dépôt : projet à la racine, aucun ZIP, .gitignore complet."""

    def test_repository_structure(self):
        self.assertGreater(verify_project.verify_repository(ROOT), 500)

    def test_gitignore_covers_every_refused_local_file(self):
        ignored = subprocess.run(['git', 'check-ignore', '--no-index', '--stdin'], cwd=ROOT, capture_output=True,
                                 input='\n'.join(verify_project.IGNORED_SAMPLES).encode()).stdout.decode()
        self.assertEqual(set(ignored.split()), set(verify_project.IGNORED_SAMPLES))

    def test_public_signing_reference_and_wrapper_stay_tracked(self):
        tracked = {p.as_posix() for p in tracked_files(ROOT)}
        for name in ('signing/certificate.sha256', 'android/gradlew', 'android/gradlew.bat',
                     'android/gradle/wrapper/gradle-wrapper.jar', 'flutter_scene_generated/.gitignore'):
            self.assertIn(name, tracked)
        self.assertFalse(any(name.endswith('.zip') for name in tracked))
        self.assertFalse(any(name.startswith('streetlift_tracker/') for name in tracked))

    def test_tracked_tree_has_no_secret(self):
        count, _ = check_tree(ROOT)
        self.assertGreater(count, 500)


if __name__ == '__main__':
    unittest.main()
