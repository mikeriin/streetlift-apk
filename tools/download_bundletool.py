"""Télécharge l’outil de validation public épinglé ; aucun secret requis."""
import argparse
import hashlib
from pathlib import Path
import urllib.request

VERSION = '1.18.2'
SHA256 = '378b5434cd1378bef6b2bc527b8c7f0ff2584b273830335bce54d6d0813c8584'
URL = f'https://github.com/google/bundletool/releases/download/{VERSION}/bundletool-all-{VERSION}.jar'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    with urllib.request.urlopen(URL, timeout=120) as stream:
        data = stream.read()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise SystemExit('Empreinte bundletool différente : validation arrêtée.')
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    args.destination.write_bytes(data)
    print(f'OK : bundletool {VERSION}, SHA-256 vérifié.')
