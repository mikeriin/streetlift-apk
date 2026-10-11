"""Contrôle de livraison sans clés privées ni secrets locaux.

M4c (5.3.2) : le dépôt contient les sources (plus de ZIP). `--check` sans
argument contrôle l'arbre suivi par git, fichier par fichier ; un ZIP n'est
plus qu'un artefact facultatif (construit avec un chemin, contrôlé avec
`--check chemin.zip`)."""
from pathlib import Path
import argparse
import re
import zipfile
from release_security import (LIMIT, PackagingError, check_archive, check_content, check_tree,
                              clear_model, excluded, secure_asset)

ROOT = Path(__file__).resolve().parents[1]
CAPTURE_FORMATS = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.mp4'}


def package(root, output):
    root, output = root.resolve(), output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + '.tmp')
    version = re.search(r'^version:\s*([^+\s]+)',
                        (root / 'pubspec.yaml').read_text(), re.M).group(1)
    files = []
    for path in sorted(root.rglob('*')):
        relative = path.relative_to(root)
        if path.is_symlink():
            raise PackagingError(f'Lien symbolique interdit : {relative}.')
        if not path.is_file() or path in {output, temporary}:
            continue
        if excluded(relative) or clear_model(relative.as_posix()):
            continue
        if (len(relative.parts) >= 3 and relative.parts[0] == 'validation'
                and relative.parts[1] != version and path.suffix.lower() in CAPTURE_FORMATS):
            continue
        if not secure_asset(relative.as_posix()):
            check_content(relative, path.read_bytes())
        files.append(path)
    expanded = sum(path.stat().st_size for path in files
                   if not secure_asset(path.relative_to(root).as_posix()))
    if expanded > LIMIT:
        raise PackagingError('Le dossier extrait dépasserait 25 Mo. Aucune archive remplacée.')
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for path in files:
                archive.write(path, 'streetlift_tracker/' + path.relative_to(root).as_posix())
        check_archive(temporary)
        size = temporary.stat().st_size
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)
    return len(files), size, expanded


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path, nargs='?',
                        help='Chemin du ZIP (artefact facultatif) ; absent avec --check : arbre du dépôt')
    parser.add_argument('--check', action='store_true',
                        help='Contrôler sans rien écrire : l’arbre suivi par git, ou le ZIP donné')
    args = parser.parse_args()
    if args.archive is None and not args.check:
        parser.error('chemin du ZIP obligatoire pour construire une archive')
    try:
        if args.check and args.archive is None:
            count, size = check_tree(ROOT)
            print(f'OK : arbre du dépôt contrôlé fichier par fichier, {count} fichiers, {size} octets.')
        elif args.check:
            count, expanded = check_archive(args.archive)
            print(f'OK : ZIP contrôlé, {count} fichiers, {expanded} octets extraits.')
        else:
            count, size, expanded = package(ROOT, args.archive)
            print(f'{count} fichiers · ZIP {size:,} octets · dossier {expanded:,} octets')
    except (PackagingError, OSError, zipfile.BadZipFile) as error:
        message = str(error) if isinstance(error, PackagingError) else 'Échec de lecture/écriture du ZIP.'
        parser.exit(1, message + '\n')


if __name__ == '__main__':
    main()
