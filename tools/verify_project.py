"""Vérifie l'intégrité des données livrées et l'identité de signature Android."""
import argparse
import gzip
import json
from pathlib import Path, PurePosixPath
import subprocess
import xml.etree.ElementTree as ET
from signing import SigningError, verify_restored

ROOT = Path(__file__).resolve().parents[1]


# M4c : motifs que le .gitignore racine doit couvrir (échantillons des
# fichiers refusés par tools/release_security.py).
IGNORED_SAMPLES = (
    'build/app/outputs/flutter-apk/app-release.apk', '.dart_tool/package_config.json',
    'flutter_scene_generated/mannequin.fsceneb', '.flutter-plugins', '.flutter-plugins-dependencies',
    'android/local.properties', 'android/key.properties', 'android/app/upload.jks',
    'release.keystore', 'signing/kalis_track.p12', 'signing/.restore-1', 'copie.pfx', 'cle.key',
    '.env', '.env.local', 'streetlift_tracker_v33.zip', 'kalis-track.aab', 'android/.gradle/cache',
    'tools/__pycache__/x.pyc',
)
REPO_FILES = ('.gitignore', '.gitattributes', '.github/workflows/build-apk.yml',
              '.github/workflows/ci-3d.yml')


def verify_repository(root=ROOT):
    """M4c : projet Flutter à la racine du dépôt, aucun ZIP, ignorés complets."""
    for name in ('pubspec.yaml', 'lib/main.dart', 'android/app/build.gradle.kts', 'README.md', *REPO_FILES):
        assert (root / name).is_file(), f'{name} absent de la racine du dépôt'
    attributes = (root / '.gitattributes').read_text(encoding='utf-8')
    assert '* text=auto eol=lf' in attributes, 'Fins de ligne LF non déclarées'
    for suffix in ('png', 'glb', 'gz', 'jar', 'wav'):
        assert f'*.{suffix} binary' in attributes, f'Binaire non déclaré : {suffix}'
    try:
        tracked = subprocess.run(['git', 'ls-files', '-z'], cwd=root, check=True,
                                 capture_output=True).stdout.decode().split('\0')
    except (OSError, subprocess.CalledProcessError):
        return None  # copie hors dépôt (artefact) : structure seule
    tracked = [PurePosixPath(t) for t in tracked if t]
    assert tracked, 'Aucun fichier suivi'
    assert not any(t.suffix.lower() == '.zip' for t in tracked), 'ZIP suivi dans le dépôt'
    assert not any(t.parts[0] == 'streetlift_tracker' for t in tracked), 'Dossier intermédiaire streetlift_tracker/'
    check = subprocess.run(['git', 'check-ignore', '--no-index', '--stdin', '-z'], cwd=root,
                           input='\0'.join(IGNORED_SAMPLES).encode(), capture_output=True)
    ignored = set(check.stdout.decode().split('\0'))
    missing = [s for s in IGNORED_SAMPLES if s not in ignored]
    assert not missing, 'Non couverts par .gitignore : ' + ', '.join(missing)
    return len(tracked)


def verify(root=ROOT, signing=False):
    program = json.loads(gzip.decompress((root / 'assets/programme_v33.json.gz').read_bytes()))
    weeks = program['weeks']
    assert [w['n'] for w in weeks] == list(range(1, 41)), 'Semaines invalides'
    ids = set()
    for week in weeks:
        assert [d['j'] for d in week['days']] == list(range(1, 8)), 'Jours invalides'
        for day in week['days']:
            for ex in day['exercises']:
                assert ex['id'] not in ids, f"Exercice dupliqué : {ex['id']}"
                ids.add(ex['id'])
    # LC1 (KT-037) : 1 954 − 202 lignes retirées + 66 nouvelles en S12-S19.
    assert len(ids) == 1812, 'Programme incomplet'  # LC1b : 1 818 − 7 + 1
    # BV11 (dev6.19.0) : base d'exercices v1.1 seule source de l'application ;
    # le pack 2.0.0 (L9b) est retiré, archivé dans tools/archives/pack_2.0.0/.
    catalog = json.loads(gzip.decompress((root / 'assets/catalog/catalog_v1.json.gz').read_bytes()))
    exercises = catalog['exercices']
    assert len({e['id'] for e in exercises}) == len(exercises) == 1039, 'Base v1.1 incomplète'
    v11_ids = {e['id'] for e in exercises}
    table = json.loads((root / 'assets/catalog/correspondance.json').read_text(encoding='utf-8'))
    assert all(v is None or v in v11_ids for v in table['ids'].values()), 'Correspondance des identifiants invalide'
    assert all(v in v11_ids for v in table['noms'].values()), 'Correspondance des noms invalide'
    groups = json.loads((root / 'assets/catalog/groupes_historiques.json').read_text(encoding='utf-8'))['groupes']
    assert len(groups) == 625, 'Groupes historiques incomplets'
    pubspec = (root / 'pubspec.yaml').read_text(encoding='utf-8')
    assert not (root / 'assets/content').exists() and 'assets/content/' not in pubspec, 'Pack 2.0.0 encore embarqué'
    assert (root / 'assets/legal/licences.md').is_file() and 'assets/legal/licences.md' in pubspec, 'Mentions absentes'
    # G7 : générateur L10 et ses modèles retirés (kalis_plan les remplace).
    assert not (root / 'assets/program_models.json').exists(), 'Modèles L10 encore présents'
    assert 'program_models.json' not in (root / 'pubspec.yaml').read_text(encoding='utf-8'), 'Modèles L10 encore déclarés'
    assert 'kalis_plan' in (root / 'pubspec.yaml').read_text(encoding='utf-8'), 'kalis_plan non déclaré'
    # G10 (D1.4) : Koach L7 et l'adaptation au quotidien L11 retirés (le
    # moteur dynamique kalis_adapt les remplace) ; leurs sections de
    # sauvegarde restent lues (koach_data.dart, legacy_adapt_data.dart).
    for old in ('koach_engine', 'koach_program', 'koach_store', 'koach_screens', 'koach_widgets',
                'koach_day_card', 'koach_adapt', 'adapt_store', 'adapt_screens'):
        assert not (root / f'lib/{old}.dart').exists(), f'{old}.dart encore présent (L7/L11)'
    assert (root / 'lib/legacy_adapt_data.dart').is_file(), 'Lecture de la section adapt absente'
    for path in (root / 'android/app/src/main/res').rglob('*.xml'):
        ET.parse(path)
    manifest = ET.parse(root / 'android/app/src/main/AndroidManifest.xml')
    ns = '{http://schemas.android.com/apk/res/android}'
    application = manifest.find('application')
    assert application.get(ns + 'label') == 'Kalis Track'
    # KT-016 option A : sauvegarde Android par défaut, déclarée explicitement.
    assert application.get(ns + 'allowBackup') == 'true', 'allowBackup doit rester "true" (KT-016, option A)'
    for attribute in ('dataExtractionRules', 'fullBackupContent', 'backupAgent'):
        assert application.get(ns + attribute) is None, f'{attribute} non prévu par la décision KT-016'
    # M1 (mannequin 3D) : Flutter GPU activé pour flutter_scene, Impeller par défaut.
    metas = {item.get(ns + 'name'): item.get(ns + 'value') for item in application.findall('meta-data')}
    assert metas.get('io.flutter.embedding.android.EnableFlutterGPU') == 'true', 'Flutter GPU non activé (M1)'
    assert 'io.flutter.embedding.android.EnableImpeller' not in metas, 'Impeller doit rester le moteur par défaut'
    permissions = {item.get(ns + 'name') for item in manifest.findall('uses-permission')}
    assert {
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.RECEIVE_BOOT_COMPLETED',
    } <= permissions, 'Permissions de notification manquantes'
    receivers = {item.get(ns + 'name'): item for item in manifest.findall('application/receiver')}
    for name in ('ScheduledNotificationReceiver', 'ScheduledNotificationBootReceiver'):
        full_name = 'com.dexterous.flutterlocalnotifications.' + name
        assert full_name in receivers, f'Receiver Android absent : {name}'
        assert receivers[full_name].get(ns + 'exported') == 'false'
    build = (root / 'android/app/build.gradle.kts').read_text()
    assert 'applicationId = "fr.tchoupi.streetlift_tracker"' in build
    verify_repository(root)
    if signing:
        verify_restored(root)
    return len(ids), len(exercises)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--signing', action='store_true')
    args = parser.parse_args()
    try:
        count, exercises = verify(signing=args.signing)
    except SigningError as error:
        parser.exit(1, str(error) + '\n')
    print(f'OK : 40 semaines, 280 jours, {count} exercices du programme, {exercises} exercices de la base.')
