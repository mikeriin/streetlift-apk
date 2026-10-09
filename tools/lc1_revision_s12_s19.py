"""LC1 (KT-037) — Révision du contenu du Bloc 2, semaines 12 à 19.

Transforme l'asset embarqué `assets/programme_v33.json.gz` (et lui seul :
le classeur Excel n'est plus la référence). Déterministe et vérifié :

- l'entrée doit être exactement l'asset 2.5.6 attendu (SHA-256 du JSON
  décompressé) ; sinon arrêt sans rien écrire ;
- une seconde exécution sur l'asset déjà révisé est refusée avec un message
  clair (la révision ne s'applique qu'une fois) ;
- la sortie est comparée à son empreinte attendue avant d'être écrite ;
- les semaines 1 à 11 et 20 à 40, la feuille Pilotage et les métadonnées ne
  sont pas touchées (vérifié).

Identifiants : lignes conservées ou modifiées → identifiant inchangé ; lignes
supprimées → identifiant retiré ; lignes nouvelles → `B2-L1-001`, `B2-L1-002`…
attribués dans l'ordre semaine → jour → position, jamais réutilisés.

Décisions du propriétaire du 26/09/2026 appliquées telles quelles (voir
SUIVI_PROJET.md, LC1.1).

    python3 tools/lc1_revision_s12_s19.py [--assets DOSSIER] [--dry-run]
"""
import argparse
import copy
import gzip
import hashlib
import json
import sys
from pathlib import Path

from program_math import rest_seconds

ROOT = Path(__file__).resolve().parents[1]

# SHA-256 du JSON décompressé : asset 2.5.6 (entrée) et asset révisé (sortie).
INPUT_SHA256 = '0330e9a628fa505fa918fcdf92b0424b675b1aae70d987a3d9662f661cdeb7d4'
OUTPUT_SHA256_VALUE = '399450dcb37da34e8a186a78ec084e77b046b65b6860dff524dc18caca3c5328'

WEEKS = range(12, 20)
DELOAD = {15, 19}
CLASSIC = {12, 13, 15, 19}  # R2 : séries classiques ; S14, S16-S18 : clusters

VBT = 'VBT : coupe la série à −20 % de perte de vitesse.'
NO_SENSOR = (
    "Sans capteur : arrête la série dès qu'une rep ralentit nettement "
    'ou que ta marge passe sous le RIR visé.'
)
CLUSTER_SETS = ' en clusters (30 s intra)'
CLUSTER_CUE = ' Clusters : 30 s pleines entre reps.'
CALIBRATION = (
    'Série 1 = calibrage, note ton RIR. RIR visé + 2 ou plus → +5 kg sur les '
    'séries suivantes et +5 kg sur le 1RM de la feuille Pilotage (muscle-up : '
    '+3,75 kg). RIR visé + 1 → +2,5 kg et +2,5 kg (muscle-up : +1,25 kg). RIR '
    'visé → rien. Une seule série sous le RIR visé → rien. Deux séries de suite '
    'à RIR 1 ou moins alors que le RIR visé est 2 ou plus → −2,5 kg sur les '
    'suivantes. Série ratée → −2,5 kg (−5 kg s\'il manque 2 reps ou plus).'
)
DELOAD_NOTE = 'Décharge : aucune hausse de charge.'
GTG_CONDUITE_OLD = ' GtG dans la journée.'
GTG_CONDUITE_NEW = ' GtG : 3 × 4 muscle-ups PdC répartis dans la journée.'
RECALAGE = 'SEMAINE DE RECALAGE — sortie de décharge. '
TEST_HEAD = (
    'Test en tête de séance ; reporte le résultat dans la feuille Pilotage '
    "avant l'exercice suivant. "
)
REF_CUE = (
    "Même série tout le bloc, d'une traite. Note ton RIR : c'est ton repère "
    'de progression en endurance.'
)

MAIN_NAMES = {
    'MUSCLE-UP LESTÉ — lift n°1, avant tout tirage',
    'TRACTION LESTÉE — lift principal',
    'DIP LESTÉ — lift principal',
    'BACK SQUAT — lift principal',
}

# Lignes d'origine attendues, jour par jour (S15/S19 : pas de dips à
# résistance accommodante en J2).
ORIGINAL = {
    1: [
        'MUSCLE-UP LESTÉ — lift n°1, avant tout tirage',
        'TRACTION LESTÉE — lift principal',
        'Rowing barre penché',
        'Tirage vertical prise neutre',
        'Curl barre EZ',
        'Face pulls',
        'Rotations externes (par haltère)',
        'Scapular pull-ups',
        'Travail poignet excentrique (haltère)',
    ],
    2: [
        'DIP LESTÉ — lift principal',
        'Dips à résistance accommodante (élastique depuis le sol)',
        'Pompes lestées (lest ajouté)',
        'Développé militaire debout',
        'Développé couché',
        'Élévations latérales (par haltère)',
        'Extension triceps poulie corde',
        'Rotations externes (par haltère)',
        'YTW à plat ventre (banc incliné)',
        'Travail poignet excentrique (haltère)',
    ],
    3: [
        'BACK SQUAT — lift principal',
        'Soulevé de terre roumain',
        'Fentes marchées (par haltère)',
        'Leg curl',
        'Hip thrust',
        'Mollets debout',
        'Hollow body hold',
        'Ab wheel',
        'Pallof press',
        'Travail poignet excentrique (haltère)',
    ],
    4: [
        'Tractions PdC — clusters',
        'Rowing haltère unilatéral (par haltère)',
        'Tirage horizontal poulie',
        'Curl marteau (par haltère)',
        'Dead-hang lesté ou PdC',
        'Face pulls',
        'Scapular pull-ups',
    ],
    5: [
        'Dips PdC — clusters',
        'Pompes PdC — clusters — enchaîné après les dips',
        'Élévations latérales (par haltère)',
        'Extension triceps poulie corde',
        'Rotations externes (par haltère)',
        'Travail poignet excentrique (haltère)',
    ],
    6: [
        'Isométrie maximale — transition MU, 3 angles',
        'Excentriques de transition LESTÉS',
        'Tractions explosives poitrine-barre',
        'Négatifs de muscle-up complets',
        'Transitions de muscle-up à l\'élastique',
        'Isométrie maximale — bas de dip',
        'Squat endurance @ 70 kg',
        'False grip hold (anneaux ou barre)',
        'Leg raises lestés (suspendu)',
        'HIIT court',
        'Mobilité épaules + poignets',
    ],
}

# Coefficients de volume d'origine → nouveaux (origine − 0,6), par semaine.
CLUSTER_COEF = {
    'B17': {13: (2.0, 1.4), 14: (2.2, 1.6), 15: (1.4, 0.8), 16: (2.0, 1.4),
            17: (2.2, 1.6), 18: (2.4, 1.8), 19: (1.4, 0.8)},
    'B18': {13: (2.0, 1.4), 14: (2.2, 1.6), 15: (1.4, 0.8), 16: (2.0, 1.4),
            17: (2.2, 1.6), 18: (2.4, 1.8), 19: (1.4, 0.8)},
    'B19': {13: (1.4, 0.8), 14: (1.54, 0.94), 15: (0.98, 0.38), 16: (1.4, 0.8),
            17: (1.54, 0.94), 18: (1.68, 1.08), 19: (0.98, 0.38)},
}


class RevisionError(Exception):
    pass


def sha256_json(data):
    raw = json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode()
    return hashlib.sha256(raw).hexdigest(), raw


def check(condition, message):
    if not condition:
        raise RevisionError(message)


def exercise(ex_id, name, sets, intensity, load, rest, tempo, cue, main=False,
             prevention=False):
    """Ligne au format de l'asset (même ordre de clés)."""
    return {
        'id': ex_id,
        'name': name,
        'sets': sets,
        'intensity': intensity,
        'load': load,
        'rest': rest,
        'restSec': rest_seconds(rest),
        'tempo': tempo,
        'cue': cue,
        'main': main,
        'prevention': prevention,
    }


def text(value):
    return {'type': 'text', 'value': value}


def volume(prefix, coef, ref, div):
    return {'type': 'volume', 'prefix': prefix, 'coef': coef, 'ref': ref,
            'div': div, 'suffix': ' reps'}


FIXED0 = {'type': 'fixed', 'kg': 0.0}


class Ids:
    def __init__(self, taken):
        self.taken = taken
        self.n = 0

    def next(self):
        self.n += 1
        new = f'B2-L1-{self.n:03d}'
        check(new not in self.taken, f'Identifiant déjà utilisé : {new}')
        self.taken.add(new)
        return new


def set_rest(ex, rest):
    ex['rest'] = rest
    ex['restSec'] = rest_seconds(rest)


def main_lift(ex, week):
    """R1, R2, R3 sur un des 4 mouvements principaux."""
    check(ex['tempo'] == 'Coupure VBT', f"{ex['id']} : tempo VBT attendu")
    check(VBT in ex['cue'], f"{ex['id']} : phrase VBT attendue")
    ex['tempo'] = 'Intention maximale'
    ex['cue'] = ex['cue'].replace(VBT, NO_SENSOR)
    if week in CLASSIC:
        ex['sets']['value'] = ex['sets']['value'].replace(CLUSTER_SETS, '')
        ex['cue'] = ex['cue'].replace(CLUSTER_CUE, '')
    ex['cue'] = f"{ex['cue']} {DELOAD_NOTE if week in DELOAD else CALIBRATION}"


def gtg(ids, week):
    return exercise(
        ids.next(),
        'GtG muscle-up — dans la journée',
        text('2×3' if week in DELOAD else '3×4'),
        "PdC — jamais à l'échec",
        dict(FIXED0),
        '≥ 2 h',
        'Propre',
        'Réparties dans la journée, au moins 2 h d\'écart. Aucun kipping. Stop '
        'à la première rep moins propre. Douleur au coude > 3/10 → GtG suspendu.',
    )


def by_name(day):
    out = {}
    for ex in day['exercises']:
        check(ex['name'] not in out, f"Nom en double S? J{day['j']} : {ex['name']}")
        out[ex['name']] = ex
    return out


def revise_week(week, ids, s2):
    n = week['n']
    deload = n in DELOAD
    days = {d['j']: d for d in week['days']}
    for j, names in ORIGINAL.items():
        expected = [x for x in names if not (
            deload and x == 'Dips à résistance accommodante (élastique depuis le sol)')]
        actual = [e['name'] for e in days[j]['exercises']]
        check(actual == expected, f'S{n} J{j} : lignes inattendues {actual}')
    for j in range(1, 7):
        for ex in days[j]['exercises']:
            if ex['name'] in MAIN_NAMES:
                main_lift(ex, n)

    # ---------- J1 ----------
    d = days[1]
    e = by_name(d)
    rowing = e['Rowing barre penché']
    rowing['sets'] = text('2×8' if deload else '3×8')
    curl = e['Curl barre EZ']
    curl['sets'] = text('1×10' if deload else '2×10')
    curl['intensity'] = 'RIR 2'
    set_rest(curl, '90 s')
    curl['cue'] = ('Contrôlé, jamais à l\'échec : protection des fléchisseurs du '
                   'coude après le muscle-up.')
    check(curl['load']['type'] == 'acc' and curl['load']['ref'] == 'B29', 'Curl EZ : charge acc B29')
    curl['load']['dayReps'] = 10
    face = e['Face pulls']
    face['sets'] = text('2×18' if deload else '3×18')
    wrist = e['Travail poignet excentrique (haltère)']
    if deload:
        wrist['sets'] = text('2×15 (flex. + ext.)')
    check(GTG_CONDUITE_OLD in d['conduite'], f'S{n} J1 : GtG attendu dans la conduite')
    d['conduite'] = d['conduite'].replace(GTG_CONDUITE_OLD, '', 1)
    d['exercises'] = [e['MUSCLE-UP LESTÉ — lift n°1, avant tout tirage'],
                      e['TRACTION LESTÉE — lift principal'], rowing, curl, face, wrist]
    j1_wrist = wrist

    # ---------- J2 ----------
    d = days[2]
    e = by_name(d)
    push = e['Pompes lestées (lest ajouté)']
    push['sets'] = text('2×8' if deload else '3×8')
    press = e['Développé militaire debout']
    press['sets'] = text('2×8' if deload else '3×8')
    triceps = e['Extension triceps poulie corde']
    triceps['sets'] = text('1×12-15 puis 2×(4)' if deload else '1×12-15 puis 4×(4)')
    triceps['intensity'] = 'Myo-reps — activation RIR 1'
    set_rest(triceps, '10 s intra')
    triceps['cue'] = ('Activation à RIR 1, puis mini-séries de 4 reps avec 10 s de '
                      'repos, jusqu\'à ne plus tenir les 4. Coudes fixes.')
    # Myo-reps : même référence de reps que les autres lignes myo-reps.
    triceps['load']['dayReps'] = 13
    rotations = e['Rotations externes (par haltère)']
    rotations['sets'] = text('2×15/bras')
    d['exercises'] = [e['DIP LESTÉ — lift principal'], push, press,
                      e['Élévations latérales (par haltère)'], triceps, rotations]

    # ---------- J3 ----------
    d = days[3]
    e = by_name(d)
    pause = exercise(
        ids.next(), 'Squat pause 2 s', text('1×4' if deload else '2×4'),
        'RIR 3 · ~67 % barre', {'type': 'barbell', 'ref': 'B11', 'pct': 0.67},
        '3 min', 'Pause 2 s en bas',
        'Pause immobile 2 s en bas, gainage maintenu, remontée explosive. '
        'Renforce la sortie du bas sans fatigue lourde.')
    rdl, curl_leg = e['Soulevé de terre roumain'], e['Leg curl']
    if deload:
        # Séries réduites d'un tiers (base 3 séries), entier inférieur, min 2.
        for line, reps in ((rdl, 10), (curl_leg, 12)):
            sets = max(2, (3 * 2) // 3)
            check(line['sets']['value'] == f'{sets}×{reps}', f'S{n} J3 : décharge {line["name"]}')
    check(GTG_CONDUITE_OLD in d['conduite'], f'S{n} J3 : GtG attendu dans la conduite')
    d['conduite'] = d['conduite'].replace(GTG_CONDUITE_OLD, GTG_CONDUITE_NEW, 1)
    d['exercises'] = [e['BACK SQUAT — lift principal'], pause, rdl, curl_leg,
                      e['Ab wheel'], gtg(ids, n)]

    # ---------- J4 ----------
    d = days[4]
    e = by_name(d)
    clusters = e['Tractions PdC — clusters']
    head = []
    if n == 12:
        test = s2[4]['TEST MAX TRACTIONS PdC']
        head = [
            exercise(ids.next(), 'TEST MAX TRACTIONS PdC', text('1 × maximum'),
                     'Maximum strict', dict(FIXED0), test['rest'], 'Régulier',
                     'Première série de la séance, après échauffement complet. '
                     'Cadence régulière, pas de kipping, descente complète bras '
                     'tendus. Résultat → maximum Tractions de la feuille Pilotage, '
                     'AVANT l\'exercice suivant : tout le volume de tirage du bloc '
                     'en dépend.'),
            exercise(ids.next(), 'Tractions PdC — séries continues',
                     volume('2 × ', 1.2, 'B17', 2), 'RIR 3 ou plus', dict(FIXED0),
                     '4 min', 'Régulier',
                     '60 % de ton nouveau maximum, d\'une traite, sans pause en '
                     'suspension.', main=True),
        ]
    else:
        old, new = CLUSTER_COEF['B17'][n]
        check(clusters['sets']['coef'] == old and clusters['sets']['div'] == 5,
              f'S{n} J4 : coefficient tractions {old} attendu')
        clusters['sets']['coef'] = new
        clusters['cue'] = ('Reste du volume du jour : 5 clusters de 3 mini-séries, '
                           '20 s de pause en suspension.')
        head = [
            exercise(ids.next(), 'Tractions PdC — série de référence',
                     volume('1 × ', 0.6, 'B17', 1), 'Note ton RIR', dict(FIXED0),
                     '3 min', 'Régulier', REF_CUE, main=True),
            clusters,
        ]
    row = e['Rowing haltère unilatéral (par haltère)']
    row['sets'] = text('2×10' if deload else '3×10')
    hammer = e['Curl marteau (par haltère)']
    hammer['sets'] = text('1×12' if deload else '2×12')
    hammer['intensity'] = 'RIR 2'
    set_rest(hammer, '90 s')
    check(hammer['load']['type'] == 'acc' and hammer['load']['ref'] == 'B30', 'Curl marteau : charge acc B30')
    hammer['load']['dayReps'] = 12
    hang = e['Dead-hang lesté ou PdC']
    hang['sets'] = text('1× max effort' if deload else '2× max effort')
    face = e['Face pulls']
    face['sets'] = text('2×18' if deload else '3×18')
    wrist = copy.deepcopy(j1_wrist)
    wrist['id'] = ids.next()
    d['exercises'] = head + [row, hammer, hang, face, wrist]

    # ---------- J5 ----------
    d = days[5]
    e = by_name(d)
    dips = e['Dips PdC — clusters']
    pushups = e['Pompes PdC — clusters — enchaîné après les dips']
    if n == 12:
        t_dips = s2[2]['TEST MAX DIPS PdC']
        t_push = s2[2]['TEST MAX POMPES PdC']
        head = [
            exercise(ids.next(), 'TEST MAX DIPS PdC', text('1 × maximum'),
                     'Maximum strict', dict(FIXED0), t_dips['rest'], 'Régulier',
                     t_dips['cue'] + ' Résultat → maximum Dips de la feuille '
                     'Pilotage avant la suite.'),
            exercise(ids.next(), 'TEST MAX POMPES PdC', text('1 × maximum'),
                     'Maximum strict', dict(FIXED0), '5 min', 'Régulier',
                     t_push['cue'] + ' Enchaîné après le test de dips, comme en '
                     'S2 : même protocole, résultats comparables. Résultat → '
                     'maximum Pompes.'),
        ]
    else:
        for line, ref in ((dips, 'B18'), (pushups, 'B19')):
            old, new = CLUSTER_COEF[ref][n]
            check(line['sets']['coef'] == old and line['sets']['div'] == 5,
                  f'S{n} J5 : coefficient {ref} {old} attendu')
            line['sets']['coef'] = new
            line['cue'] = ('Reste du volume du jour : 5 clusters de 3 mini-séries, '
                           '20 s de pause en appui.')
        # Nom de la section 3 (« Pompes PdC — clusters »). Le suffixe
        # « — enchaîné après les dips » ferait enchaîner l'application cette
        # ligne avec celle qui la précède, désormais la série de référence
        # des pompes (regroupement par nom, `AppStore.groups`).
        pushups['name'] = 'Pompes PdC — clusters'
        head = [
            exercise(ids.next(), 'Dips PdC — série de référence',
                     volume('1 × ', 0.6, 'B18', 1), 'Note ton RIR', dict(FIXED0),
                     '3 min', 'Régulier', REF_CUE, main=True),
            dips,
            exercise(ids.next(), 'Pompes PdC — série de référence',
                     volume('1 × ', 0.6, 'B19', 1), 'Note ton RIR', dict(FIXED0),
                     '3 min', 'Régulier', REF_CUE, main=True),
            pushups,
        ]
    check(GTG_CONDUITE_OLD in d['conduite'], f'S{n} J5 : GtG attendu dans la conduite')
    d['conduite'] = d['conduite'].replace(GTG_CONDUITE_OLD, GTG_CONDUITE_NEW, 1)
    d['exercises'] = head + [e['Élévations latérales (par haltère)'], gtg(ids, n)]

    # ---------- J6 ----------
    d = days[6]
    e = by_name(d)
    d['title'] = 'PUISSANCE MU + SQUAT ENDURANCE'
    check(' | ' in d['conduite'], f'S{n} J6 : conduite inattendue')
    d['conduite'] = ('CONDUITE J6 — Muscle-up au poids de corps et tirage explosif, '
                     'squat endurance. AUCUNE charge maximale. | '
                     + d['conduite'].split(' | ', 1)[1])
    mu = exercise(ids.next(), 'Muscle-ups PdC explosifs', text('3×2' if deload else '4×3'),
                  'PdC — vitesse maximale', dict(FIXED0), '2 min', 'Explosif',
                  'Tire le plus haut possible, transition rapide. Stop à la '
                  'première rep plus lente ou plus basse.')
    explosive = e['Tractions explosives poitrine-barre']
    explosive['sets'] = text('3×3' if deload else '4×3')
    explosive['cue'] += ' +5 kg si le sternum touche la barre facilement sur toutes les reps.'
    squat = e['Squat endurance @ 70 kg']
    if n == 12:
        t_squat = s2[6]['TEST MAX SQUAT @ 70 kg']
        squat = exercise(ids.next(), 'TEST MAX SQUAT @ 70 kg', text('1 × maximum'),
                         t_squat['intensity'], dict(t_squat['load']), t_squat['rest'],
                         t_squat['tempo'],
                         t_squat['cue'] + ' Résultat → maximum Squat 70 kg')
    d['exercises'] = [mu, explosive, squat, e['Leg raises lestés (suspendu)'],
                      e['Mobilité épaules + poignets']]

    # ---------- Conduites S12 ----------
    if n == 12:
        for j in range(1, 7):
            lead = RECALAGE + (TEST_HEAD if j in (4, 5, 6) else '')
            days[j]['conduite'] = lead + days[j]['conduite']


def revise(data):
    digest, _ = sha256_json(data)
    if digest == OUTPUT_SHA256_VALUE:
        raise RevisionError(
            'Révision LC1 déjà appliquée à cet asset : rien à faire. '
            'Repars de l\'asset 2.5.6 d\'origine pour la rejouer.')
    check(digest == INPUT_SHA256,
          f'Asset inattendu (SHA-256 {digest}) : la révision LC1 ne s\'applique '
          f'qu\'à l\'asset 2.5.6 ({INPUT_SHA256}).')
    out = copy.deepcopy(data)
    taken = {ex['id'] for w in out['weeks'] for d in w['days'] for ex in d['exercises']}
    ids = Ids(taken)
    s2 = {d['j']: {e['name']: e for e in d['exercises']} for d in out['weeks'][1]['days']}
    for week in out['weeks']:
        if week['n'] in WEEKS:
            revise_week(week, ids, s2)
    # Invariants : reste du programme, Pilotage et métadonnées intacts.
    check(out['meta'] == data['meta'] and out['pilotage'] == data['pilotage'],
          'Pilotage ou métadonnées modifiés')
    for before, after in zip(data['weeks'], out['weeks']):
        if before['n'] not in WEEKS:
            check(before == after, f"Semaine {before['n']} modifiée")
    seen = set()
    for w in out['weeks']:
        for d in w['days']:
            for ex in d['exercises']:
                check(ex['id'] not in seen, f"Identifiant dupliqué : {ex['id']}")
                seen.add(ex['id'])
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
        print(f'ÉCHEC LC1 : {error}', file=sys.stderr)
        sys.exit(1)
    print(f'LC1 appliquée : {before} → {after} exercices ; SHA-256 du JSON révisé {digest}')
