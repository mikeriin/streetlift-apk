"""LC1b (suite de KT-037) — S11·J6 au format du J6 du Bloc 2.

Décision du propriétaire du 26/09/2026 : tester dès la séance du jour
(S11·J6, semaine de décharge) le nouveau format du J6 de S12 (muscle-ups au
poids de corps explosifs, tractions explosives, leg raises, mobilité), en
gardant le squat endurance de S11 (3 × 0,9 × max à 70 kg, RIR 3) : le test
max squat reste en S12·J6, qui ne change pas.

Transforme l'asset embarqué `assets/programme_v33.json.gz`. Déterministe et
vérifié, sur le modèle de `lc1_revision_s12_s19.py` :

- l'entrée doit être exactement l'asset révisé par LC1 (SHA-256 du JSON
  décompressé) ; sinon arrêt sans rien écrire ;
- une seconde exécution sur l'asset déjà transformé est refusée avec un
  message clair ;
- la sortie est comparée à son empreinte attendue avant d'être écrite ;
- tout le reste (autres jours de S11, autres semaines dont S12·J6, feuille
  Pilotage, métadonnées) est vérifié identique.

Identifiants (même règle que LC1) : lignes conservées ou modifiées →
identifiant inchangé (`B1-521` tractions explosives 5×3 → 4×3, `B1-525`
squat endurance inchangé, `B1-527` leg raises 2×10 → 3×10, `B1-529`
mobilité inchangée) ; lignes supprimées → identifiant retiré (`B1-519`,
`B1-520`, `B1-522`, `B1-523`, `B1-524`, `B1-526`, `B1-528`) ; ligne nouvelle
→ `B1-L1b-001` (muscle-ups PdC explosifs), jamais réutilisé.

    python3 tools/lc1b_s11_j6.py [--assets DOSSIER] [--dry-run]
"""
import argparse
import copy
import gzip
import json
import sys
from pathlib import Path

import lc1_revision_s12_s19 as lc1
from lc1_revision_s12_s19 import RevisionError, check, sha256_json

ROOT = Path(__file__).resolve().parents[1]

# SHA-256 du JSON décompressé : asset LC1 (entrée) et asset transformé (sortie).
INPUT_SHA256 = lc1.OUTPUT_SHA256_VALUE
OUTPUT_SHA256_VALUE = '144869b3d42eb4293f3670f99a23806bc745debbe3ebe54c96b3ad31e5c5c4b2'

WEEK, DAY = 11, 6
REMOVED = ['B1-519', 'B1-520', 'B1-522', 'B1-523', 'B1-524', 'B1-526', 'B1-528']
NEW_ID = 'B1-L1b-001'
# Ligne de S11·J6 → ligne de S12·J6 dont elle prend le format (identifiant
# S11 conservé). Le squat endurance B1-525 reste tel quel.
FROM_S12 = {'B1-521': 'B2-60', 'B1-527': 'B2-66', 'B1-529': 'B2-68'}
SQUAT = 'B1-525'
S12_MU = 'B2-L1-009'
TITLE = 'PUISSANCE MU + SQUAT ENDURANCE'
CONDUITE_HEAD = ('CONDUITE J6 — Muscle-up au poids de corps et tirage explosif, '
                 'squat endurance. AUCUNE charge maximale.')


def day_of(data, n, j):
    week = next(w for w in data['weeks'] if w['n'] == n)
    return next(d for d in week['days'] if d['j'] == j)


def revise(data):
    digest, _ = sha256_json(data)
    if digest == OUTPUT_SHA256_VALUE:
        raise RevisionError(
            'Transformation LC1b déjà appliquée à cet asset : rien à faire. '
            'Repars de l\'asset LC1 pour la rejouer.')
    check(digest == INPUT_SHA256,
          f'Asset inattendu (SHA-256 {digest}) : LC1b ne s\'applique qu\'à '
          f'l\'asset LC1 ({INPUT_SHA256}).')
    out = copy.deepcopy(data)
    taken = {ex['id'] for w in out['weeks'] for d in w['days'] for ex in d['exercises']}
    check(NEW_ID not in taken, f'Identifiant {NEW_ID} déjà pris')

    s12 = {e['id']: e for e in day_of(out, 12, DAY)['exercises']}
    d = day_of(out, WEEK, DAY)
    by_id = {e['id']: e for e in d['exercises']}
    check([e['id'] for e in d['exercises']] ==
          ['B1-519', 'B1-520', 'B1-521', 'B1-522', 'B1-523', 'B1-524',
           SQUAT, 'B1-526', 'B1-527', 'B1-528', 'B1-529'],
          f'S{WEEK} J{DAY} : lignes inattendues')
    check(d['cycle'] == 'DELOAD', f'S{WEEK} J{DAY} : semaine de décharge attendue')
    check(' | ' in d['conduite'], f'S{WEEK} J{DAY} : conduite inattendue')
    for s11_id, s12_id in FROM_S12.items():
        check(by_id[s11_id]['name'] == s12[s12_id]['name'],
              f'{s11_id} ne correspond pas à {s12_id}')

    mu = dict(s12[S12_MU], id=NEW_ID)
    kept = {s11_id: dict(s12[s12_id], id=s11_id) for s11_id, s12_id in FROM_S12.items()}
    d['title'] = TITLE
    d['conduite'] = CONDUITE_HEAD + ' | ' + d['conduite'].split(' | ', 1)[1]
    d['exercises'] = [mu, kept['B1-521'], by_id[SQUAT], kept['B1-527'], kept['B1-529']]

    # Invariants : seul S11·J6 change ; S12·J6 et le reste sont intacts.
    check(out['meta'] == data['meta'] and out['pilotage'] == data['pilotage'],
          'Pilotage ou métadonnées modifiés')
    for before, after in zip(data['weeks'], out['weeks']):
        for db, da in zip(before['days'], after['days']):
            if (before['n'], db['j']) != (WEEK, DAY):
                check(db == da, f"S{before['n']} J{db['j']} modifié")
        check({k: v for k, v in before.items() if k != 'days'} ==
              {k: v for k, v in after.items() if k != 'days'},
              f"En-tête de S{before['n']} modifié")
    seen = set()
    for w in out['weeks']:
        for dd in w['days']:
            for ex in dd['exercises']:
                check(ex['id'] not in seen, f"Identifiant dupliqué : {ex['id']}")
                seen.add(ex['id'])
    check(not seen & set(REMOVED), 'Identifiant supprimé encore présent')
    return out


def run(assets, dry_run=False):
    path = assets / 'programme_v33.json.gz'
    data = json.loads(gzip.decompress(path.read_bytes()))
    out = revise(data)
    digest, raw = sha256_json(out)
    check(digest == OUTPUT_SHA256_VALUE, f'Sortie inattendue (SHA-256 {digest})')
    before = sum(len(d['exercises']) for w in data['weeks'] for d in w['days'])
    after = sum(len(d['exercises']) for w in out['weeks'] for d in w['days'])
    if not dry_run:
        path.write_bytes(gzip.compress(raw, compresslevel=9, mtime=0))
    return before, after, digest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('--assets', type=Path, default=ROOT / 'assets')
    parser.add_argument('--dry-run', action='store_true', help="Vérifie sans écrire l'asset.")
    args = parser.parse_args()
    try:
        before, after, digest = run(args.assets, args.dry_run)
    except RevisionError as error:
        print(f'ÉCHEC LC1b : {error}', file=sys.stderr)
        sys.exit(1)
    print(f'LC1b appliquée : {before} → {after} exercices ; SHA-256 du JSON {digest}')
