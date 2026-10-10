"""Vraies tentatives release ; seul le refus de signature attendu valide le test.

M4c (5.3.2) : `--tree` contrôle d'abord, fichier par fichier, l'arbre suivi
par git (aucune clé, aucun mot de passe, aucun fichier local ni artefact),
sans lancer de build : à passer avant chaque push."""
import argparse
import json
import os
from pathlib import Path
import subprocess
from release_security import PackagingError, check_tree
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


def check_repository_tree(root=ROOT):
    """Arbre suivi par git sans secret (M4c) ; lève PackagingError sinon."""
    count, size = check_tree(root)
    print(f'OK : arbre suivi sans secret, {count} fichiers contrôlés un par un ({size} octets).')
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='journaux des tentatives de build release')
    parser.add_argument('--tree', action='store_true', help='contrôler l’arbre suivi par git (sans build)')
    args = parser.parse_args()
    if not args.tree and args.output is None:
        parser.error('--output ou --tree obligatoire')
    if args.tree:
        try:
            check_repository_tree()
        except PackagingError as error:
            parser.exit(1, str(error) + '\n')
    if args.output is not None:
        check(args.output.resolve())
