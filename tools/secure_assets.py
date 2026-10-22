#!/usr/bin/env python3
"""M6c : ressources sous licence chiffrées dans le dépôt (`assets_secure/`).

Le personnage Mixamo « Ch36 » (source FBX), le mannequin d'exécution qui en
est dérivé et l'écorché acheté qui a donné les zones musculaires ne sont
jamais suivis en clair : seuls leurs fichiers `.enc` le sont, chiffrés par
`openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt -pass env:KT_ASSETS_KEY`.
La clé est le secret GitHub `KT_ASSETS_KEY` (CI) ou la variable
d'environnement du même nom (sessions) ; elle n'est jamais écrite dans un
fichier, un commit, un journal ou une capture.

`assets_secure/manifest.json` liste chaque fichier chiffré, son chemin en
clair (ignoré par git) et l'empreinte SHA-256 du clair.

Commandes :
  decrypt [--tout]   déchiffre les ressources d'exécution (ou toutes) et
                     vérifie leurs empreintes ; échoue clairement sans clé
  encrypt CHEMIN     (re)chiffre un fichier du manifeste depuis son clair et
                     met à jour son empreinte
  verify             vérifie les empreintes des clairs présents
  check              sans clé : manifeste cohérent, fichiers chiffrés présents
                     (en-tête OpenSSL « Salted__ »), aucun clair suivi
"""
import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECURE = ROOT / 'assets_secure'
MANIFEST = SECURE / 'manifest.json'
KEY_ENV = 'KT_ASSETS_KEY'
OPENSSL = ['openssl', 'enc', '-aes-256-cbc', '-pbkdf2', '-iter', '200000', '-salt',
           '-pass', f'env:{KEY_ENV}']


class SecureAssetError(RuntimeError):
    pass


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def load_manifest():
    return json.loads(MANIFEST.read_text(encoding='utf-8'))


def save_manifest(data):
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')


def _key_env():
    if not os.environ.get(KEY_ENV):
        raise SecureAssetError(
            f'Clé absente : la variable {KEY_ENV} (secret GitHub {KEY_ENV}) est '
            'nécessaire pour déchiffrer les ressources sous licence '
            '(assets_secure/). Crée le secret dans Settings › Secrets and '
            'variables › Actions du dépôt.')
    return dict(os.environ)


def decrypt(everything=False, log=print):
    env = _key_env()
    done = []
    for entry in load_manifest()['fichiers']:
        if not everything and entry['role'] != 'execution':
            continue
        src = ROOT / entry['chiffre']
        dst = ROOT / entry['clair']
        dst.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run(OPENSSL + ['-d', '-in', str(src), '-out', str(dst)], env=env,
                                capture_output=True)
        if result.returncode != 0:
            if dst.exists():
                dst.unlink()
            raise SecureAssetError(f'Déchiffrement refusé : {entry["chiffre"]} (clé incorrecte ?).')
        got = sha256(dst)
        if got != entry['sha256']:
            dst.unlink()
            raise SecureAssetError(f'Empreinte inattendue après déchiffrement : {entry["clair"]}.')
        done.append(entry['clair'])
        log(f'OK : {entry["clair"]} déchiffré ({dst.stat().st_size} octets, empreinte vérifiée).')
    return done


def encrypt(clear_path, log=print):
    env = _key_env()
    data = load_manifest()
    rel = Path(clear_path).resolve().relative_to(ROOT).as_posix()
    entry = next((e for e in data['fichiers'] if e['clair'] == rel), None)
    if entry is None:
        raise SecureAssetError(f'{rel} absent du manifeste.')
    src = ROOT / rel
    dst = ROOT / entry['chiffre']
    result = subprocess.run(OPENSSL + ['-in', str(src), '-out', str(dst)], env=env,
                            capture_output=True)
    if result.returncode != 0:
        raise SecureAssetError(f'Chiffrement refusé : {rel}.')
    entry['sha256'] = sha256(src)
    entry['octets_clair'] = src.stat().st_size
    save_manifest(data)
    log(f'OK : {entry["chiffre"]} ({dst.stat().st_size} octets).')


def verify(log=print):
    bad = []
    for entry in load_manifest()['fichiers']:
        p = ROOT / entry['clair']
        if p.exists() and sha256(p) != entry['sha256']:
            bad.append(entry['clair'])
    if bad:
        raise SecureAssetError('Clairs différents du manifeste : ' + ', '.join(bad))
    log('OK : clairs présents conformes au manifeste.')


def check(tracked=None, log=print):
    """Sans clé. `tracked` : chemins suivis par git (défaut : git ls-files)."""
    data = load_manifest()
    if tracked is None:
        out = subprocess.run(['git', 'ls-files', '-z'], cwd=ROOT, capture_output=True,
                             check=True).stdout.decode()
        tracked = [p for p in out.split('\0') if p]
    tracked = set(tracked)
    clears = set()
    for entry in data['fichiers']:
        enc = ROOT / entry['chiffre']
        if not enc.exists():
            raise SecureAssetError(f'Fichier chiffré absent : {entry["chiffre"]}.')
        with open(enc, 'rb') as f:
            if f.read(8) != b'Salted__':
                raise SecureAssetError(f'En-tête OpenSSL absent : {entry["chiffre"]}.')
        if len(entry['sha256']) != 64:
            raise SecureAssetError(f'Empreinte invalide : {entry["chiffre"]}.')
        if entry['role'] not in ('source', 'execution', 'source_zones', 'animation'):
            raise SecureAssetError(f'Rôle inconnu : {entry["chiffre"]}.')
        clears.add(entry['clair'])
    for p in tracked:
        if p in clears:
            raise SecureAssetError(f'Ressource sous licence suivie en clair : {p}.')
        if p.startswith('assets_secure/') and not (p.endswith('.enc') or p in (
                'assets_secure/manifest.json', 'assets_secure/README.md')):
            raise SecureAssetError(f'Fichier non chiffré dans assets_secure/ : {p}.')
    log(f'OK : {len(data["fichiers"])} ressources chiffrées, aucun clair suivi.')
    return len(data['fichiers'])


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='cmd', required=True)
    d = sub.add_parser('decrypt')
    d.add_argument('--tout', action='store_true', help='aussi les sources (FBX, écorché)')
    e = sub.add_parser('encrypt')
    e.add_argument('chemin')
    sub.add_parser('verify')
    sub.add_parser('check')
    args = parser.parse_args()
    try:
        if args.cmd == 'decrypt':
            decrypt(args.tout)
        elif args.cmd == 'encrypt':
            encrypt(args.chemin)
        elif args.cmd == 'verify':
            verify()
        else:
            check()
    except SecureAssetError as error:
        print(f'ERREUR : {error}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
