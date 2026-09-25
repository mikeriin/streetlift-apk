"""Vérifie l'intégrité des données livrées et l'identité de signature Android."""
import argparse
import gzip
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from signing import SigningError, verify_restored

ROOT = Path(__file__).resolve().parents[1]


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
    assert len(ids) == 1954, 'Programme incomplet'
    exercises = json.loads(gzip.decompress((root / 'assets/exercises_db.json.gz').read_bytes()))
    assert all(isinstance(e[k], str) for e in exercises for k in ('n', 'g', 'eq'))
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
