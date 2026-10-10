# -*- coding: utf-8 -*-
"""Koach (L7) — annotations structurées du programme, sans modifier l'asset.

Lit `assets/programme_v33.json.gz` (inchangé : l'empreinte LC1 reste
valable) et écrit `assets/koach_program.json.gz` :

- `exercises` : pour chaque exercice utile à Koach, sa catégorie
  (`strength`, `test1rm`, `endurance`, `enduranceTest`, `accessory`), sa
  référence Pilotage, le mouvement principal, et le **RIR visé structuré**
  lu dans le libellé (« RIR 2 · ~82 % système » → 2 ; « RIR 2-3 » → 2 et
  max 3 ; « RIR 5+ » → 5). Aucun libellé n'est modifié.
- `accessories` : matériel de chaque charge de référence (D23) et marque
  « prévention ».
- `weeks` : semaine normale, de décharge (cycle « DELOAD ») ou de tests.
- `curve` : k a priori de la courbe %1RM(n) = 1 / (1 + (n − 1) / k), par
  mouvement, ajusté par moindres carrés sur les couples (reps, RIR, %)
  prescrits par le programme (séries classiques, n ≥ 3 ; les singles et
  doubles à « RIR 0-1 ≈ 93-97 % » sont écartés : contrat L7 §4.2).

Déterministe (clés triées, gzip niveau 9 sans horodatage). Contrôle :
`tools/tests/test_koach_annotate.py` (égalité avec les libellés sur tous les
exercices).

    python3 tools/koach_annotate.py [--check]
"""
import argparse
import gzip
import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets' / 'programme_v33.json.gz'
TARGET = ROOT / 'assets' / 'koach_program.json.gz'

RIR_RE = re.compile(r'RIR\s*(\d)(?:\s*-\s*(\d))?(\+)?')
LABEL_RE = re.compile(r'^RIR (\d) · ~(\d+) % (système|barre)$')
SETS_RE = re.compile(r'^(\d+)\s*[×x]\s*(\d+)')

# Matériel des charges de référence (D23). « machine » : matériel guidé à
# pile, incrément réglable (non précisé par le propriétaire : contrat §4.7).
EQUIPMENT = {
    'B25': 'barbell',   # Rowing barre penché
    'B26': 'pulley',    # Tirage vertical prise neutre
    'B27': 'pulley',    # Tirage horizontal poulie
    'B28': 'dumbbell',  # Rowing haltère unilatéral
    'B29': 'barbell',   # Curl barre EZ
    'B30': 'dumbbell',  # Curl marteau
    'B31': 'barbell',   # Développé militaire debout
    'B32': 'barbell',   # Développé couché
    'B33': 'dumbbell',  # Élévations latérales
    'B34': 'pulley',    # Extension triceps poulie corde
    'B35': 'barbell',   # Barre au front EZ
    'B36': 'plate',     # Pompes lestées (lest ajouté)
    'B37': 'barbell',   # Soulevé de terre roumain
    'B38': 'dumbbell',  # Fentes marchées
    'B39': 'machine',   # Leg curl
    'B40': 'barbell',   # Hip thrust
    'B41': 'machine',   # Mollets debout
    'B42': 'dumbbell',  # Leg raises lestés (haltère entre les pieds)
    'B43': 'pulley',    # Face pulls
    'B44': 'dumbbell',  # Rotations externes
    'B45': 'dumbbell',  # Travail poignet excentrique
}

ENDURANCE_TESTS = {
    'TEST MAX MUSCLE-UPS PdC': 'B16',
    'TEST MAX TRACTIONS PdC': 'B17',
    'TEST MAX DIPS PdC': 'B18',
    'TEST MAX POMPES PdC': 'B19',
    'TEST MAX SQUAT @ 70 kg': 'B20',
}


def load_program(path=SOURCE):
    raw = gzip.decompress(path.read_bytes())
    return json.loads(raw), hashlib.sha256(raw).hexdigest()


def rir_target(label):
    """RIR visé lu dans un libellé : (min, max) ou (None, None)."""
    m = RIR_RE.search(label or '')
    if not m:
        return None, None
    lo = int(m.group(1))
    hi = int(m.group(2)) if m.group(2) else None
    return lo, hi


def pct(n, k):
    return 1.0 / (1.0 + (n - 1.0) / k)


def fit_k(points):
    """k minimisant Σ (pct(n, k) − p)² sur [15 ; 45] (pas de 0,01)."""
    best = None
    for i in range(1500, 4501):
        k = i / 100.0
        err = sum((pct(n, k) - p) ** 2 for n, p in points)
        if best is None or err < best[0] - 1e-15:
            best = (err, k)
    err, k = best
    return round(k, 1), (err / len(points)) ** 0.5


def annotate(program, digest):
    pil = program['pilotage']
    lifts = {l['ref']: l['key'] for l in pil['mainLifts']}
    repmax = {r['ref'] for r in pil['repMax']}
    exercises = {}
    prevention = {}
    curve_pts = {key: [] for key in lifts.values()}
    weeks = {}
    for week in program['weeks']:
        wtype = 'normal'
        if any(d.get('cycle') == 'DELOAD' for d in week['days']):
            wtype = 'deload'
        elif any('TEST' in e['name'].upper() for d in week['days'] for e in d['exercises']):
            wtype = 'test'
        weeks[str(week['n'])] = wtype
        for day in week['days']:
            for ex in day['exercises']:
                load, sets = ex['load'], ex['sets']
                lo, hi = rir_target(ex['intensity'])
                entry = {}
                name = ex['name']
                intensity = ex['intensity'].lower()
                if name.startswith('TEST 1RM') and load['type'] in ('system', 'barbell') and load.get('ref') in lifts:
                    entry = {'cat': 'test1rm', 'ref': load['ref'], 'movement': lifts[load['ref']]}
                elif name in ENDURANCE_TESTS:
                    entry = {'cat': 'enduranceTest', 'ref': ENDURANCE_TESTS[name]}
                elif (ex.get('main') and load['type'] in ('system', 'barbell') and load.get('ref') in lifts
                      and 'excentrique' not in intensity and 'élastique' not in intensity):
                    entry = {'cat': 'strength', 'ref': load['ref'], 'movement': lifts[load['ref']]}
                    m = LABEL_RE.match(ex['intensity'])
                    s = SETS_RE.match(sets.get('value') or '')
                    if m and s and 'cluster' not in (sets.get('value') or ''):
                        n = int(s.group(2)) + int(m.group(1))
                        if n >= 3:
                            curve_pts[lifts[load['ref']]].append((n, int(m.group(2)) / 100.0))
                elif sets['type'] == 'volume' and sets.get('ref') in repmax:
                    entry = {'cat': 'endurance', 'ref': sets['ref']}
                elif load['type'] == 'acc':
                    entry = {'cat': 'accessory', 'ref': load['ref']}
                    prevention[load['ref']] = prevention.get(load['ref'], False) or bool(ex.get('prevention'))
                if lo is not None:
                    entry['rirTarget'] = lo
                    if hi is not None:
                        entry['rirTargetMax'] = hi
                if entry:
                    exercises[ex['id']] = entry
    curve = {}
    for key, pts in curve_pts.items():
        k, rmse = fit_k(pts)
        curve[key] = {'k': k, 'points': len(pts), 'rmse': round(rmse, 4)}
    accessories = {}
    for a in pil['accessories']:
        accessories[a['ref']] = {'equipment': EQUIPMENT[a['ref']], 'prevention': prevention.get(a['ref'], False)}
    return {
        'version': 1,
        'source': {'asset': 'programme_v33.json.gz', 'sha256': digest},
        'curve': curve,
        'accessories': accessories,
        'weeks': weeks,
        'exercises': exercises,
    }


def encode(data):
    raw = json.dumps(data, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode()
    return gzip.compress(raw, compresslevel=9, mtime=0)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help="vérifie que l'annotation livrée est à jour")
    args = parser.parse_args(argv)
    program, digest = load_program()
    blob = encode(annotate(program, digest))
    if args.check:
        if not TARGET.exists() or TARGET.read_bytes() != blob:
            print('ÉCHEC : assets/koach_program.json.gz ne correspond pas au programme.', file=sys.stderr)
            return 1
        print('OK : annotations Koach à jour.')
        return 0
    TARGET.write_bytes(blob)
    data = annotate(program, digest)
    print('écrit %s : %d exercices annotés, k = %s' % (
        TARGET.name, len(data['exercises']), {k: v['k'] for k, v in data['curve'].items()}))
    return 0


if __name__ == '__main__':
    sys.exit(main())
