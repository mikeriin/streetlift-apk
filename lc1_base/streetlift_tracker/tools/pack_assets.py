"""Compresse les JSON de manière reproductible ; conserve les sources."""
import argparse
import gzip
from pathlib import Path


def pack(root, optimize_masks=False):
    for name in ('programme_v33.json', 'exercises_db.json'):
        source = root / name
        if source.exists():
            target = source.with_suffix('.json.gz')
            target.write_bytes(gzip.compress(source.read_bytes(), compresslevel=9, mtime=0))
            print(f'{source.name}: {source.stat().st_size} -> {target.stat().st_size} octets')
    if optimize_masks:
        from PIL import Image
        for path in sorted((root / 'muscles').glob('*.png')):
            with Image.open(path) as original:
                original.convert('LA').save(path, optimize=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--assets', type=Path, default=Path(__file__).resolve().parents[1] / 'assets')
    parser.add_argument('--optimize-masks', action='store_true', help='Optimise les masques PNG (nécessite Pillow).')
    args = parser.parse_args()
    pack(args.assets, args.optimize_masks)
