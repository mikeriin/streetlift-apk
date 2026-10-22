"""M8 correction 2 (5.10.0) : corrections des rôles musculaires du pack de
contenu, relues par un regard biomécanique indépendant (erreurs nettes
seulement : gabarit de famille recopié à tort, stabilisateur compté comme
moteur, antagoniste compté comme moteur ; références dans chaque « why »).

Source : `tools/sources/corrections_muscles.json` (une entrée par
exercice et par rôle : `add`, `remove`, `move_to` {muscle: rôle}).
Appliquées à `assets/content/details.json.gz`, sérialisé exactement comme
`tools/content_pack_import.py` (JSON compact trié, gzip niveau 9 sans
horodatage) ; idempotent : relancer ne change rien.

  python3 tools/content_corrections.py           # applique
  python3 tools/content_corrections.py --check   # vérifie (CI, tests)
"""
import argparse
import gzip
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DETAILS = ROOT / 'assets/content/details.json.gz'
CORRECTIONS = ROOT / 'tools/sources/corrections_muscles.json'
ROLES = ('primaires', 'secondaires', 'stabilisateurs')


def atlas_ids():
    src = (ROOT / 'lib/atlas_data.dart').read_text(encoding='utf-8')
    start = src.index('const atlasMuscles')
    return set(re.findall(r"^  '([a-z_]+)': AtlasMuscle\(", src[start:], re.M))


def apply(details, corrections, known=None):
    """Applique les corrections (sur place) ; renvoie le nombre de changements."""
    ex = details['exercices']
    changes = 0
    for c in corrections:
        fiche = ex[c['id']]
        role = c['role']
        assert role in ROLES, c
        for m in [*c.get('add', []), *c.get('remove', []), *c.get('move_to', {})]:
            assert known is None or m in known, (c['id'], m)
        lists = {r: fiche['muscles_' + r] for r in ROLES}
        for m in c.get('remove', []):
            for r in ROLES:
                if m in lists[r]:
                    lists[r].remove(m)
                    changes += 1
        for m, target in c.get('move_to', {}).items():
            assert target in ROLES, c
            if m in lists[target] and not any(m in lists[r] for r in ROLES if r != target):
                continue
            for r in ROLES:
                if m in lists[r]:
                    lists[r].remove(m)
            lists[target].append(m)
            changes += 1
        for m in c.get('add', []):
            if not any(m in lists[r] for r in ROLES):
                lists[role].append(m)
                changes += 1
        # un muscle dans un seul rôle, un moteur au moins
        seen = [m for r in ROLES for m in lists[r]]
        assert len(seen) == len(set(seen)), c['id']
        assert lists['primaires'], c['id']
    return changes


def dump(details):
    raw = json.dumps(details, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode()
    return gzip.compress(raw, compresslevel=9, mtime=0)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    corrections = json.loads(CORRECTIONS.read_text(encoding='utf-8'))['corrections']
    details = json.loads(gzip.decompress(DETAILS.read_bytes()))
    changes = apply(details, corrections, atlas_ids())
    if args.check:
        if changes:
            raise SystemExit(f'{changes} corrections non appliquées : relancer sans --check')
        print(f'OK : {len(corrections)} corrections de rôles musculaires appliquées.')
        return
    DETAILS.write_bytes(dump(details))
    print(f'{changes} changements ({len(corrections)} corrections).')


if __name__ == '__main__':
    main()
