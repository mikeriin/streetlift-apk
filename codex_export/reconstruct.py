#!/usr/bin/env python3
"""Reconstruit l'arbre 4.0.1 depuis le ZIP texte/binaire de 5d38177."""

import argparse
import base64
import hashlib
import re
import shutil
import subprocess
import zipfile
from pathlib import Path, PurePosixPath

HEADER = re.compile(r"^=== (.+) ; sha256=([0-9a-f]{64}) ===$")
MANIFEST = re.compile(r"^\| `([^`]+)` \| `([0-9a-f]{64})` \| (?:texte|binaire/base64) \|$")


def safe_relative(value: str) -> Path:
    posix = PurePosixPath(value)
    if posix.is_absolute() or ".." in posix.parts or not posix.parts:
        raise SystemExit(f"Chemin refusé: {value!r}")
    return Path(*posix.parts)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    export = Path(__file__).resolve().parent
    if args.destination.exists():
        raise SystemExit(f"Destination déjà présente: {args.destination}")
    args.destination.mkdir(parents=True)
    with zipfile.ZipFile(args.archive) as archive:
        for member in archive.infolist():
            safe_relative(member.filename)
        archive.extractall(args.destination)
    root = args.destination / "streetlift_tracker"
    if not root.is_dir():
        raise SystemExit("Racine streetlift_tracker/ absente")
    subprocess.run(
        ["git", "apply", "--check", str(export / "refonte.patch")],
        cwd=root,
        check=True,
    )
    subprocess.run(
        ["git", "apply", str(export / "refonte.patch")], cwd=root, check=True
    )

    current_path = None
    expected = None
    chunks = []

    def flush() -> None:
        nonlocal current_path, expected, chunks
        if current_path is None:
            return
        target = root / safe_relative(current_path)
        target.parent.mkdir(parents=True, exist_ok=True)
        try:
            payload = base64.b64decode("".join(chunks), validate=True)
        except ValueError as error:
            raise SystemExit(f"Base64 invalide pour {current_path}: {error}") from error
        actual = hashlib.sha256(payload).hexdigest()
        if actual != expected:
            raise SystemExit(f"SHA-256 Base64 incorrect pour {current_path}: {actual}")
        target.write_bytes(payload)
        current_path = expected = None
        chunks = []

    for line in (export / "assets_base64.txt").read_text(encoding="ascii").splitlines():
        header = HEADER.fullmatch(line)
        if header:
            flush()
            current_path, expected = header.groups()
        elif current_path is not None:
            chunks.append(line)
        elif line.strip():
            raise SystemExit("Texte inattendu avant le premier bloc Base64")
    flush()

    expected_files = {
        match.group(1): match.group(2)
        for line in (export / "LISEZMOI.md").read_text().splitlines()
        if (match := MANIFEST.fullmatch(line))
    }
    if not expected_files:
        raise SystemExit("Manifeste vide")
    errors = []
    for relative, wanted in expected_files.items():
        path = root / safe_relative(relative)
        if not path.is_file():
            errors.append(f"absent: {relative}")
        elif (actual := digest(path)) != wanted:
            errors.append(f"empreinte: {relative}: {actual} != {wanted}")
    if errors:
        raise SystemExit("Échec de reconstruction:\n" + "\n".join(errors))
    print(f"OK: {len(expected_files)} fichiers reconstruits et vérifiés dans {root}")


if __name__ == "__main__":
    main()
