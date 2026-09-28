"""Compresse les JSON de manière reproductible ; conserve les sources.

La base d'exercices vient du pack de contenu depuis 3.2.0 : voir
tools/content_pack_import.py (assets/content/)."""
import argparse
import gzip
from pathlib import Path


def pack(root):
    for name in ('programme_v33.json',):
        source = root / name
        if source.exists():
            target = source.with_suffix('.json.gz')
            target.write_bytes(gzip.compress(source.read_bytes(), compresslevel=9, mtime=0))
            print(f'{source.name}: {source.stat().st_size} -> {target.stat().st_size} octets')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets', type=Path, default=Path(__file__).resolve().parents[1] / 'assets')
    args = parser.parse_args()
    pack(args.assets)
