"""M4c : compare l'arbre suivi par git avec le contenu du ZIP 5.3.1.

L'arbre d'un commit (par défaut HEAD) est lu dans git (contenu des blobs,
jamais la copie de travail) ; le ZIP est lu dans git à l'étiquette
`archive-zip-5.3.1` (dernier commit qui le contient) ou depuis un fichier.
Chaque fichier est comparé par son SHA-256.

Exceptions admises (seules différences autorisées par le lot M4c) :
- fichiers de version : pubspec.yaml, lib/settings_screen.dart (version
  affichée dans Réglages › À propos), README.md, SUIVI_PROJET.md ;
- fichiers de dépôt ajoutés : .gitignore, .gitattributes.
`--allow` ajoute des fichiers admis (lots suivants : fichiers qu'ils
modifient). Code de sortie 1 si une différence n'est pas admise.

    python3 tools/compare_tree_with_zip.py --ref HEAD
    python3 tools/compare_tree_with_zip.py --zip streetlift_tracker_v33.zip
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_TAG = 'archive-zip-5.3.1'
# Dernier commit de main qui contient le ZIP (si l'étiquette n'est pas présente).
ARCHIVE_COMMIT = '4531346f183aae545980ae0ecfc80b1942a8134a'
ARCHIVE_PATH = 'streetlift_tracker_v33.zip'
PREFIX = 'streetlift_tracker/'
VERSION_FILES = frozenset({'pubspec.yaml', 'lib/settings_screen.dart', 'README.md', 'SUIVI_PROJET.md'})
REPO_FILES = frozenset({'.gitignore', '.gitattributes'})


def _git(*args: str, root: Path = ROOT) -> bytes:
    return subprocess.run(['git', *args], cwd=root, check=True, capture_output=True).stdout


def zip_files(data: bytes) -> dict[str, str]:
    """Fichiers du ZIP (chemins sans le dossier `streetlift_tracker/`)."""
    out = {}
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            name = entry.filename
            if not name.startswith(PREFIX):
                raise ValueError(f'Entrée hors de {PREFIX} : {name}')
            out[name[len(PREFIX):]] = hashlib.sha256(archive.read(entry)).hexdigest()
    return out


def tree_files(ref: str, root: Path = ROOT) -> dict[str, str]:
    """Fichiers suivis au commit [ref], contenu des blobs git."""
    listing = _git('ls-tree', '-r', '-z', '--full-tree', ref, root=root).split(b'\0')
    entries = []
    for line in listing:
        if not line:
            continue
        meta, path = line.split(b'\t', 1)
        mode, kind, sha = meta.split()
        if kind != b'blob':
            continue
        if mode == b'120000':
            raise ValueError(f'Lien symbolique suivi : {path.decode()}')
        entries.append((path.decode(), sha.decode()))
    # Lecture groupée des blobs (un seul processus git).
    batch = subprocess.run(['git', 'cat-file', '--batch'], cwd=root, check=True, capture_output=True,
                           input=''.join(f'{sha}\n' for _, sha in entries).encode()).stdout
    out, pos = {}, 0
    for path, _ in entries:
        header_end = batch.index(b'\n', pos)
        size = int(batch[pos:header_end].split()[2])
        content = batch[header_end + 1:header_end + 1 + size]
        pos = header_end + 1 + size + 1
        out[path] = hashlib.sha256(content).hexdigest()
    return out


def compare(tree: dict[str, str], archive: dict[str, str], allow=frozenset()) -> dict:
    allowed = VERSION_FILES | REPO_FILES | frozenset(allow)
    same = sorted(p for p in tree.keys() & archive.keys() if tree[p] == archive[p])
    changed = sorted(p for p in tree.keys() & archive.keys() if tree[p] != archive[p])
    added = sorted(tree.keys() - archive.keys())
    missing = sorted(archive.keys() - tree.keys())
    refused = sorted(p for p in changed + added if p not in allowed) + missing
    return {
        'fichiers_zip': len(archive),
        'fichiers_arbre': len(tree),
        'identiques': len(same),
        'modifies': changed,
        'ajoutes': added,
        'absents': missing,
        'differences_non_admises': refused,
        'identique_hors_exceptions': not refused,
    }


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--ref', default='HEAD', help='commit dont l’arbre est comparé (défaut HEAD)')
    parser.add_argument('--zip', type=Path, help='ZIP local (défaut : ZIP lu dans git à ' + ARCHIVE_TAG + ')')
    parser.add_argument('--zip-ref', help='commit qui contient le ZIP (défaut : étiquette ' + ARCHIVE_TAG
                        + ', sinon ' + ARCHIVE_COMMIT[:7] + ')')
    parser.add_argument('--allow', action='append', default=[], help='fichier admis en plus des exceptions')
    parser.add_argument('--json', type=Path, help='écrit aussi le résultat en JSON')
    args = parser.parse_args(argv)
    zip_ref = args.zip_ref
    if zip_ref is None:
        known = subprocess.run(['git', 'rev-parse', '-q', '--verify', f'refs/tags/{ARCHIVE_TAG}'], cwd=ROOT,
                               capture_output=True).returncode == 0
        zip_ref = ARCHIVE_TAG if known else ARCHIVE_COMMIT
    data = args.zip.read_bytes() if args.zip else _git('show', f'{zip_ref}:{ARCHIVE_PATH}')
    result = compare(tree_files(args.ref), zip_files(data), args.allow)
    result['commit'] = _git('rev-parse', '--short', args.ref).decode().strip()
    result['zip_sha256'] = hashlib.sha256(data).hexdigest()
    lines = [
        f"Arbre {result['commit']} / ZIP {result['zip_sha256'][:12]}… : "
        f"{result['fichiers_arbre']} fichiers suivis, {result['fichiers_zip']} dans le ZIP, "
        f"{result['identiques']} identiques (SHA-256).",
    ]
    for label, key in (('Modifiés', 'modifies'), ('Ajoutés', 'ajoutes'), ('Absents', 'absents')):
        lines.append(f'{label} ({len(result[key])}) : ' + (', '.join(result[key]) or 'aucun'))
    if result['identique_hors_exceptions']:
        lines.append('OK : arbre identique au ZIP 5.3.1 hors exceptions admises.')
    else:
        lines.append('ÉCHEC : différences non admises : ' + ', '.join(result['differences_non_admises']))
    print('\n'.join(lines))
    if args.json:
        args.json.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return 0 if result['identique_hors_exceptions'] else 1


if __name__ == '__main__':
    sys.exit(main())
