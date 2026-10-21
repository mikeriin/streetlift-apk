#!/usr/bin/env python3
"""Illustrations intouchables de la refonte UI (cahier UI §1, §6.1 ; lot UI5).

Koach (dessins, vue, flamme, paquet `kalis_koach`), logo (`brand.dart`,
`assets/icon/`) et anatomie musculaire (`muscle_body.dart`,
`muscle_map_2d.dart`, `muscle_map_regions.dart`, `assets/muscles*/`) ne
changent pas pendant la refonte : seuls leurs conteneurs bougent
(`koach_bubble.dart`, `koach_home_card.dart`, `koach_gallery_screen.dart`,
qui ne dessinent rien et ne sont pas suivis ici).

Le relevé `tools/ui_illustrations_empreintes.json` donne l'empreinte SHA-256
de chaque fichier suivi sur `main` b7996b3f (dev6.11.1, base de la refonte).

Usage :
  python3 tools/check_ui_illustrations.py            # échoue si un fichier diffère
  python3 tools/check_ui_illustrations.py --write    # réécrit le relevé (base seulement)
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RELEVE = ROOT / 'tools' / 'ui_illustrations_empreintes.json'

SUIVIS = [
    'lib/brand.dart',
    'lib/koach/koach_view.dart',
    'lib/koach/flame_icon.dart',
    'lib/muscle_body.dart',
    'lib/muscle_map_2d.dart',
    'lib/muscle_map_regions.dart',
]
DOSSIERS = [
    'assets/icon',
    'assets/muscles',
    'assets/muscles2d',
    'packages/kalis_koach',
]
IGNORES = ('.dart_tool', 'build', 'pubspec.lock', '.packages')


def suivis(root: Path = ROOT) -> list[str]:
    out = [p for p in SUIVIS if (root / p).is_file()]
    for d in DOSSIERS:
        base = root / d
        if not base.is_dir():
            continue
        for f in sorted(base.rglob('*')):
            rel = f.relative_to(root).as_posix()
            if f.is_file() and not any(part in IGNORES for part in f.parts):
                out.append(rel)
    return sorted(out)


def empreintes(root: Path = ROOT) -> dict[str, str]:
    return {
        rel: hashlib.sha256((root / rel).read_bytes()).hexdigest()
        for rel in suivis(root)
    }


def ecarts(attendu: dict[str, str], actuel: dict[str, str]) -> list[str]:
    msgs = []
    for rel in sorted(set(attendu) | set(actuel)):
        if rel not in actuel:
            msgs.append(f'supprimé : {rel}')
        elif rel not in attendu:
            msgs.append(f'ajouté : {rel}')
        elif attendu[rel] != actuel[rel]:
            msgs.append(f'modifié : {rel}')
    return msgs


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--write', action='store_true')
    args = ap.parse_args(argv)
    actuel = empreintes()
    if args.write:
        RELEVE.write_text(
            json.dumps(actuel, indent=1, sort_keys=True, ensure_ascii=False) + '\n',
            encoding='utf-8',
        )
        print(f'{len(actuel)} fichiers relevés')
        return 0
    attendu = json.loads(RELEVE.read_text(encoding='utf-8'))
    msgs = ecarts(attendu, actuel)
    if msgs:
        print('Illustrations modifiées (cahier UI §1) :')
        for m in msgs:
            print('  ' + m)
        return 1
    print(f'Illustrations intactes : {len(actuel)} fichiers identiques à dev6.11.1')
    return 0


if __name__ == '__main__':
    sys.exit(main())
