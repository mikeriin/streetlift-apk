#!/usr/bin/env python3
"""G3 — base d'exercices v1.1 dans l'application : catalogue et correspondance.

1. Copie l'asset compilé du paquet étiqueté (`packages/kalis_core/data/
   catalog_v1.json.gz`) dans `assets/catalog/catalog_v1.json.gz`, octet pour
   octet (l'application le charge par `Catalog` de kalis_core).
2. Construit `assets/catalog/correspondance.json` : anciens identifiants du
   pack 2.0.0 (625) et anciens noms (pack, base v1, intitulés du programme
   embarqué v33 : les noms enregistrés dans le journal) → identifiants de la
   base v1.1.
   - Règle automatique : un nom de l'ancien exercice (nom, nom historique ou
     alias), normalisé (casse, accents, ponctuation), est le nom ou un alias
     d'un seul exercice de la base v1.1.
   - Sinon : table relue `tools/correspondance/relecture_g3.json` (exercice
     par exercice, avec confiance et note).
3. Écrit le rapport `docs/G3_CORRESPONDANCE.md`.

`--check` : vérifie que les trois fichiers sont à jour (tests Python de la
CI), sans rien écrire.
"""
from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PACKAGE_CATALOG = ROOT / 'packages/kalis_core/data/catalog_v1.json.gz'
APP_CATALOG = ROOT / 'assets/catalog/catalog_v1.json.gz'
OUT = ROOT / 'assets/catalog/correspondance.json'
REPORT = ROOT / 'docs/G3_CORRESPONDANCE.md'
REVIEW = ROOT / 'tools/correspondance/relecture_g3.json'
OLD_INDEX = ROOT / 'assets/content/index.json.gz'
PROGRAM = ROOT / 'assets/programme_v33.json.gz'

CONFIDENCES = ('auto', 'sur', 'proche', 'aucun')


def norm(text: str) -> str:
    """Même normalisation que `normalizeText` (lib/search.dart) : minuscules,
    sans accents, ligatures dépliées, ponctuation → espace."""
    t = unicodedata.normalize('NFD', text.lower())
    t = ''.join(c for c in t if unicodedata.category(c) != 'Mn')
    t = t.replace('œ', 'oe').replace('æ', 'ae').replace('’', "'")
    return re.sub(r'[^a-z0-9]+', ' ', t).strip()


def load_json_gz(path: Path):
    return json.loads(gzip.decompress(path.read_bytes()).decode('utf-8'))


def build() -> tuple[bytes, dict, str]:
    catalog_bytes = PACKAGE_CATALOG.read_bytes()
    catalog = json.loads(gzip.decompress(catalog_bytes).decode('utf-8'))
    exercises = {e['id']: e for e in catalog['exercices']}
    labels: dict[str, set[str]] = {}
    for e in catalog['exercices']:
        for name in [e['nom'], *e['alias']]:
            labels.setdefault(norm(name), set()).add(e['id'])

    old = load_json_gz(OLD_INDEX)
    review = {r['old_id']: r for r in json.loads(REVIEW.read_text('utf-8'))['entrees']}

    ids: dict[str, str | None] = {}
    detail: dict[str, dict] = {}
    for e in old['exercices']:
        found: set[str] = set()
        for name in [e['nom'], e['n'], *e.get('alias', [])]:
            found |= labels.get(norm(name), set())
        if len(found) == 1:
            if e['id'] in review:
                raise SystemExit(f"{e['id']} : correspondance automatique et relue à la fois")
            new = next(iter(found))
            ids[e['id']] = new
            detail[e['id']] = {'confiance': 'auto', 'note': 'nom ou alias identique'}
            continue
        r = review.get(e['id'])
        if r is None:
            raise SystemExit(f"{e['id']} ({e['nom']}) : ni correspondance automatique ni relue")
        if r['confiance'] not in CONFIDENCES[1:]:
            raise SystemExit(f"{e['id']} : confiance inconnue {r['confiance']}")
        if (r['new_id'] is None) != (r['confiance'] == 'aucun'):
            raise SystemExit(f"{e['id']} : « aucun » ⇔ identifiant nul")
        if r['new_id'] is not None and r['new_id'] not in exercises:
            raise SystemExit(f"{e['id']} : {r['new_id']} absent de la base v1.1")
        ids[e['id']] = r['new_id']
        detail[e['id']] = {'confiance': r['confiance'], 'note': r['note']}
    extra = set(review) - set(ids)
    if extra:
        raise SystemExit(f'relecture : anciens identifiants inconnus {sorted(extra)}')

    # Un doublon signalé de l'ancienne base suit son exercice canonique.
    by_old = {e['id']: e for e in old['exercices']}
    for e in old['exercices']:
        canon = e.get('doublon_de')
        if canon and ids.get(e['id']) is None and ids.get(canon) is not None:
            ids[e['id']] = ids[canon]
            detail[e['id']] = {'confiance': detail[canon]['confiance'], 'note': f'doublon de {canon}'}

    # Anciens noms → ancien identifiant (même ordre que l'ancien
    # ContentIndex.idFor : base v1 (canonique), programme, puis nom/alias).
    names: dict[str, str] = {}
    origin: dict[str, str] = {}

    def add(name: str, old_id: str, source: str) -> None:
        if name in names:
            return
        names[name] = old_id
        origin[name] = source

    for name, v in old['base_v1'].items():
        add(name, v.get('canonique') or v['id'], 'base_v1')
    for name, v in old['programme_v33'].items():
        add(name, v['id'], 'programme_v33')
    for e in old['exercices']:
        for name in [e['n'], e['nom'], *e.get('alias', [])]:
            add(name, e['id'], 'pack')

    noms = {n: ids[o] for n, o in sorted(names.items()) if ids.get(o) is not None}

    # Intitulés du programme embarqué (noms enregistrés dans le journal).
    program = load_json_gz(PROGRAM)
    labels_prog = sorted({x['name'] for w in program['weeks'] for d in w['days'] for x in d['exercises']})

    def resolve(name: str) -> str | None:
        if name in noms:
            return noms[name]
        base = name.split(' — ')[0].split(' [')[0].strip()
        return noms.get(base)

    prog_rows = []
    for label in labels_prog:
        old_id = names.get(label) or names.get(label.split(' — ')[0].split(' [')[0].strip())
        prog_rows.append((label, old_id, resolve(label)))

    sha = hashlib.sha256(catalog_bytes).hexdigest()
    data = {
        'schema': 1,
        'lot': 'G3',
        'catalogue': {
            'fichier': 'assets/catalog/catalog_v1.json.gz',
            'version': catalog['source']['version'],
            'sha256_gz': sha,
            'exercices': len(exercises),
        },
        'pack': {'version': '2.0.0', 'exercices': len(ids)},
        'regles': [
            'auto : un nom, nom historique ou alias de l\'ancien exercice, normalisé, est le nom ou un alias d\'un seul exercice de la base v1.1',
            'relu : tools/correspondance/relecture_g3.json (sur, proche, aucun)',
            'doublon signalé de l\'ancienne base : suit son exercice canonique',
            'nom enregistré : identifiant de l\'ancien exercice (base v1 canonique, intitulé du programme v33, nom ou alias du pack), puis ci-dessus',
        ],
        'ids': {k: ids[k] for k in sorted(ids)},
        'noms': noms,
        'confiance': {k: detail[k]['confiance'] for k in sorted(detail)},
    }
    text = json.dumps(data, ensure_ascii=False, indent=1) + '\n'

    # Rapport.
    c = Counter(detail[k]['confiance'] for k in ids)
    none = sorted(k for k in ids if ids[k] is None)
    lines = [
        '# G3 — Correspondance des anciens exercices vers la base v1.1',
        '',
        'Généré par `python3 tools/correspondance/build_correspondance.py` (ne pas modifier à la main).',
        f"Base v1.1 : {len(exercises)} exercices (`assets/catalog/catalog_v1.json.gz`, SHA-256 `{sha}`, "
        'copie octet pour octet de `packages/kalis_core/data/catalog_v1.json.gz`, étiquette `kalis_core-v0.1.0`).',
        f'Ancien pack 2.0.0 : {len(ids)} exercices. Table : `assets/catalog/correspondance.json`.',
        '',
        '## Bilan',
        '',
        '| Rattachement | Exercices |',
        '| --- | ---: |',
        f"| automatique (nom ou alias identique) | {c['auto']} |",
        f"| relu : même exercice | {c['sur']} |",
        f"| relu : même mouvement, petite différence | {c['proche']} |",
        f"| sans équivalent | {c['aucun']} |",
        f"| anciens noms reliés (pack, base v1, programme) | {len(noms)} |",
        '',
        '## Intitulés du programme embarqué (noms enregistrés dans le journal)',
        '',
        f"{sum(1 for r in prog_rows if r[2])} intitulés reliés sur {len(prog_rows)}.",
        '',
        '| Intitulé | Exercice de la base v1.1 | Rattachement |',
        '| --- | --- | --- |',
    ]
    for label, old_id, new in prog_rows:
        conf = detail.get(old_id or '', {}).get('confiance', '—')
        target = f"{exercises[new]['nom']} (`{new}`)" if new else '**aucun**'
        lines.append(f"| {label} | {target} | {conf} |")
    lines += ['', '## Sans équivalent', '', '| Ancien exercice | Raison |', '| --- | --- |']
    for k in none:
        lines.append(f"| {by_old[k]['nom']} (`{k}`) | {detail[k]['note']} |")
    lines += ['', '## Rattachements « proche » (à relire)', '', '| Ancien exercice | Base v1.1 | Différence |', '| --- | --- | --- |']
    for k in sorted(ids):
        if detail[k]['confiance'] == 'proche':
            lines.append(f"| {by_old[k]['nom']} | {exercises[ids[k]]['nom']} | {detail[k]['note']} |")
    lines.append('')
    return catalog_bytes, {'text': text, 'prog': prog_rows, 'none': none}, '\n'.join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='vérifie sans écrire')
    args = parser.parse_args()
    catalog_bytes, data, report = build()
    unmapped_prog = [r[0] for r in data['prog'] if r[2] is None]
    targets = [
        (APP_CATALOG, catalog_bytes),
        (OUT, data['text'].encode('utf-8')),
        (REPORT, report.encode('utf-8')),
    ]
    if args.check:
        stale = [str(p.relative_to(ROOT)) for p, b in targets if not p.exists() or p.read_bytes() != b]
        if stale:
            print('à régénérer : ' + ', '.join(stale))
            return 1
        print(f'correspondance à jour ; intitulés du programme sans équivalent : {unmapped_prog}')
        return 0
    for p, b in targets:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(b)
    print(f'écrit ; intitulés du programme sans équivalent : {unmapped_prog}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
