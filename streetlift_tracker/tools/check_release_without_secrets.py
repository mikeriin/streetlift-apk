"""Vraies tentatives release ; seul le refus de signature attendu valide le test."""
import argparse
import json
import os
from pathlib import Path
import subprocess
from signing import BASE64_NAME, PASSWORD_NAME

ROOT = Path(__file__).resolve().parents[1]


def check(output):
    output.mkdir(parents=True, exist_ok=True)
    env = {k: v for k, v in os.environ.items() if k not in (BASE64_NAME, PASSWORD_NAME)}
    cases = [
        ('apk-absents', 'apk', {}, 'sont obligatoires'),
        ('aab-absents', 'appbundle', {}, 'sont obligatoires'),
        ('apk-sans-mot-de-passe', 'apk', {BASE64_NAME: '%%%'}, 'sont obligatoires'),
        ('aab-sans-conteneur', 'appbundle', {PASSWORD_NAME: 'invalid-fixture'}, 'sont obligatoires'),
        ('apk-base64-invalide', 'apk', {BASE64_NAME: '%%%', PASSWORD_NAME: 'invalid-fixture'}, 'BASE64 invalide'),
    ]
    rows = []
    for name, target, values, expected in cases:
        result = subprocess.run(
            ['flutter', 'build', target, '--release', '--no-pub', '--build-number=1'],
            cwd=ROOT, env={**env, **values}, capture_output=True, text=True, timeout=600)
        log = result.stdout + result.stderr
        (output / (name + '.log')).write_text(log)
        passed = result.returncode != 0 and 'Release refusée' in log and expected in log
        rows.append({'case': name, 'exit_code': result.returncode, 'expected_refusal_observed': passed})
        (output / 'release-sans-secrets.json').write_text(json.dumps(rows, indent=2))
        if not passed:
            raise RuntimeError(f'{name} : refus de signature attendu non démontré. Voir le journal de ce cas.')
        print(f'OK : {name}, refus Gradle attendu observé.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    check(parser.parse_args().output.resolve())
