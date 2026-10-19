# -*- coding: utf-8 -*-
"""Lot KM4 (Koach 1.0.6) : retour gradué au volume réparti sur la semaine et
priorisé par rôle (CHANGEMENTS_1_0_6.md, contrat § 8.5).

1. répartition : sans séance manquée récente, la réduction d'un groupe se
   répartit sur toutes les séances de la semaine qui le créditent ;
2. priorité de rôle : accessoires d'abord, secondaires ensuite, principaux
   en dernier ; sans rôle, la première ligne dure de la séance est le
   principal ;
3. plancher des principaux : jamais 0 série par la rampe sans douleur ;
   max(1, ⌈écrit × 0,5⌉) avant de couper un secondaire à 0 ; la conduite
   sous douleur garde la main ;
4. mode prudent (séance manquée dans les quatre dernières semaines) : la
   séance du jour paie d'abord jusqu'au plancher de ses principaux ;
5. scénario dédié (C17.37) : trois semaines d'un programme A, puis un
   programme B de six séances par semaine en PPL, +40 % de volume « chest »,
   séance de tirage en premier (muscle-up lesté E2MOM 6 × 2, traction
   lestée, accessoires) : muscle-up lesté et traction lestée servis, les
   accessoires réduits avant eux, limite de la semaine tenue.

Données synthétiques seulement (C17.33).
"""
import copy
import json
import math
import os

from koach.moteur import Koach

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']

S = PARAMS['securite']
CHEST = S['volume_groupes_majeurs'].index('chest')

MU = 'sl-muscle-up-leste'            # chest 1,0
TL = 'sl-traction-lestee'            # chest 0,5
PO = 'mu-pull-over-haltere'          # chest 1,0 (accessoire)
FP = 'mu-face-pull-corde'            # aucun crédit chest
DL = 'sl-dips-leste'                 # chest 1,0
PP = 'sw-pompe'                      # chest 1,0
PD = 'sw-pompe-declinee'             # chest 1,0
SQ = 'mu-back-squat-barre-basse'
RW = 'mu-rowing-pendlay'               # aucun crédit chest


def koach(niveau=2):
    return Koach(PARAMS, FICHES, {'niveau': niveau, 'sexe': 'male', 'poids_kg': 75.0, 'declares': {},
                                  'zones_fragiles': []})


def it(slot, ex, sets, flames=7, kind='work', role=None):
    d = {'slotId': slot, 'exerciseId': ex, 'kind': kind, 'sets': sets, 'repsLow': 3, 'repsHigh': 6,
         'targetFlames': flames}
    if role is not None:
        d['role'] = role
    return d


def roles_de(items):
    return {x['slotId']: x.get('role') for x in items}


def volume(items):
    return [{k: x.get(k) for k in ('slotId', 'exerciseId', 'kind', 'sets', 'targetFlames', 'secondsLow',
                                    'secondsHigh', 'role')} for x in items]


def seance(k, jour, items, reste=(), manquees=(), roles=True, faites=True):
    """Ouvre, sert et ferme la séance [items] du jour [jour] ; [reste] :
    séances restantes de la semaine (écrit) ; [manquees] : séances manquées
    versées au contexte ; renvoie (items servis, raisons)."""
    c = {'semaine': jour // 7, 'genre': 'accumulation', 'reste_semaine': [volume(r) for r in reste],
         'manquees': [{'semaine': jour // 7 if m is None else m, 'genre': 'accumulation', 'items': []}
                      for m in manquees]}
    k.garde.avancer(jour)
    k.seances.ouvrir(jour, None, c)
    out = k.seances.prescrire(copy.deepcopy(items), {}, {}, roles_de(items) if roles else {})
    raisons = list(k.seances.raisons)
    sets = []
    if faites:
        for x in out:
            for i in range(x['sets']):
                sets.append({'exerciseId': x['exerciseId'], 'slotId': x['slotId'], 'setIndex': i,
                             'kind': x.get('kind'), 'reps': x.get('repsHigh'), 'flames': 7, 'failed': False,
                             'target': {'flames': 7}})
    k.seances.fermer({'sets': sets})
    return out, raisons


def series(out, slot):
    for x in out:
        if x['slotId'] == slot:
            return x['sets']
    return 0


def chest(k, semaine):
    return (k.seances.vol_semaines.get(semaine) or [0.0] * 14)[CHEST]


# ----------------------------------------------------------------------
# Programmes synthétiques (scénario C17.37)
# ----------------------------------------------------------------------
def programme_a():
    """Programme A, quatre séances par semaine (haut poussée, tirage, jambes,
    haut) : 20 séries « chest », tirage et jambes au niveau de B."""
    return [
        [it('a0.1', DL, 5, role='main'), it('a0.2', PP, 4, role='secondary')],          # chest 9
        [it('a1.1', TL, 4, role='main'), it('a1.2', RW, 5, role='secondary'),
         it('a1.3', FP, 4, role='accessory')],                                           # 2
        [it('a2.1', SQ, 8, role='main')],                                                # 0
        [it('a3.1', DL, 4, role='main'), it('a3.2', PP, 3, role='secondary'),
         it('a3.3', TL, 4, role='secondary'), it('a3.4', RW, 3, role='accessory')],     # 9
    ]


def programme_b():
    """Programme B, six séances par semaine en PPL, séance de tirage en
    premier : 28 séries « chest » (+40 %)."""
    return [
        [it('b0.1', MU, 6, role='main'), it('b0.2', TL, 4, role='main'),
         it('b0.3', PO, 3, role='accessory'), it('b0.4', FP, 3, role='accessory')],     # 6 + 2 + 3 = 11
        [it('b1.1', DL, 5, role='main'), it('b1.2', PP, 3, role='secondary'),
         it('b1.3', PD, 2, role='accessory')],                                           # 10
        [it('b2.1', SQ, 5, role='main')],                                                # 0
        [it('b3.1', TL, 4, role='main'), it('b3.2', FP, 3, role='accessory')],          # 2
        [it('b4.1', DL, 3, role='main'), it('b4.2', PD, 2, role='accessory')],          # 5
        [it('b5.1', SQ, 4, role='main')],                                                # 0
    ]


def ecrit_chest(seances):
    t = 0.0
    for s in seances:
        for x in s:
            for (g, c) in k_credits(x['exerciseId']):
                if g == CHEST:
                    t += c * x['sets']
    return t


def k_credits(ex):
    return [(g, int(math.floor(w * 2 + 0.5)) / 2.0) for (g, w) in FICHES[ex]['groupes'] if g < 14]


def trois_semaines_a(k):
    jour = 0
    for w in range(3):
        a = programme_a()
        for i, s in enumerate(a):
            seance(k, 7 * w + [0, 1, 3, 5][i], s, reste=a[i + 1:])
        jour = 7 * (w + 1)
    return jour


def test_ecrit_du_scenario():
    assert ecrit_chest(programme_a()) == 20.0
    assert ecrit_chest(programme_b()) == 28.0


def test_scenario_c17_37_reparti():
    k = koach()
    j0 = trois_semaines_a(k)
    assert [chest(k, w) for w in range(3)] == [20.0, 20.0, 20.0]
    limite = k.seances._limite_volume(CHEST, 3)
    assert limite == 24.0          # max(20 × 1,2 ; 20 + 2) ; deux semaines : 26
    b = programme_b()
    jours = [j0 + d for d in range(6)]
    servis = []
    for i, s in enumerate(b):
        out, raisons = seance(k, jours[i], s, reste=b[i + 1:])
        servis.append(out)
        if i == 0:
            assert k.seances.retour_vol['repartie'] is True
    lundi = servis[0]
    # Muscle-up lesté et traction lestée servis à leur écrit : la réduction
    # (4 séries) est portée par les accessoires de la semaine.
    assert series(lundi, 'b0.1') == 6 and series(lundi, 'b0.2') == 4
    assert series(lundi, 'b0.3') < 3                     # pull-over (accessoire) réduit
    assert series(lundi, 'b0.4') == 3                     # face pull : aucun crédit chest
    assert chest(k, 3) <= limite + 1e-9
    # Répartition : le lundi ne paie pas tout (pull-over pas retiré seul).
    assert series(lundi, 'b0.3') >= 1
    accessoires = series(lundi, 'b0.3') + series(servis[1], 'b1.3') + series(servis[4], 'b4.2')
    assert accessoires <= 7 - 4
    for out in servis:
        for x in out:
            if x['slotId'].endswith('.1'):
                assert x['sets'] == [y for s in b for y in s if y['slotId'] == x['slotId']][0]['sets']


def test_scenario_c17_37_ancien_comportement_pour_memoire():
    """1.0.5 réservait tout l'écrit restant (17 séries) : budget du lundi =
    24 − 0 − 17 = 7 séries, coupées dans l'ordre de la séance (muscle-up 6,
    puis traction 0,5 × 2 = 1 → 2 séries, pull-over 0) ; avec plus de volume
    « chest » ailleurs dans la semaine, muscle-up et traction tombaient à 0.
    1.0.6, même lundi en mode prudent : accessoires d'abord, puis les
    principaux à leur plancher."""
    k = koach()
    j0 = trois_semaines_a(k)
    b = programme_b()
    # Plus de chest sur les séances de poussée : 36 séries écrites.
    b[1][0]['sets'] = 8
    b[4][0]['sets'] = 6
    b[4][1]['sets'] = 4
    assert ecrit_chest(b) == 36.0
    out, raisons = seance(k, j0, b[0], reste=b[1:], manquees=[2])     # séance manquée en semaine 2 : prudent
    assert k.seances.retour_vol['repartie'] is False
    # Écrit restant 25 ; budget 24 − 25 < 0 : le lundi paie jusqu'aux planchers.
    assert series(out, 'b0.3') == 0                     # accessoire coupé d'abord
    assert series(out, 'b0.1') == 3                     # muscle-up : ⌈6 × 0,5⌉
    assert series(out, 'b0.2') == 2                     # traction lestée : ⌈4 × 0,5⌉
    assert series(out, 'b0.4') == 3
    rg = [r for r in raisons if r['code'] == 'koach.retour_gradue']
    assert {r['params']['exercice'] for r in rg} == {MU, TL, PO}
    for r in rg:
        assert r['params']['groupe'] == 'chest' and r['params']['limite'] == 24.0
        assert r['params']['douleur'] is False
    assert [r['params']['ecrites'] for r in rg] == [6, 4, 3]


def test_jamais_zero_pour_un_principal_sans_douleur():
    """Budget très négatif (semaine de reprise basse puis écrit énorme) :
    principaux à 1 série au moins, secondaires et accessoires à 0."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 2, role='main')])
    jour = 21
    s = [it('m.1', DL, 10, role='main'), it('m.2', PP, 6, role='secondary'), it('m.3', PD, 6, role='accessory')]
    reste = [[it('r%d.1' % i, DL, 10, role='main'), it('r%d.2' % i, PP, 6, role='secondary')] for i in range(4)]
    out, _ = seance(k, jour, s, reste=reste)
    assert series(out, 'm.1') == 1
    assert series(out, 'm.2') == 0 and series(out, 'm.3') == 0
    # Limite 4 (max(2 × 1,2 ; 2 + 2)) : cinq principaux à 1 série dépassent
    # encore ; le dépassement est dit (`depasse`), aucun principal n'est
    # retiré (règle C17.37 ; le banc mesure qu'il n'arrive jamais).
    assert k.seances.retour_vol['depasse'] == [CHEST, S['volume_groupes_majeurs'].index('delt_anterior'),
                                               S['volume_groupes_majeurs'].index('triceps')]


def test_priorite_de_role_dans_la_seance():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    s = [it('m.1', DL, 6, role='main'), it('m.2', PP, 4, role='secondary'), it('m.3', PD, 4, role='accessory')]
    out, _ = seance(k, 21, s)
    # 14 écrites pour 12 admises : l'accessoire paie les deux séries.
    assert (series(out, 'm.1'), series(out, 'm.2'), series(out, 'm.3')) == (6, 4, 2)
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 5, role='main')])
    out, _ = seance(k, 21, s)
    # Limite 7 : accessoire 0, secondaire 1, principal ⌈6/2⌉ = 3 → 4 ; reste
    # 3 de trop… secondaire à 0, principal à 1 seulement en dernier.
    assert series(out, 'm.3') == 0
    assert series(out, 'm.1') >= series(out, 'm.2')


def test_sans_role_premiere_ligne_principale():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 2)], roles=False)
    s = [it('m.1', DL, 6), it('m.2', PP, 4), it('m.3', PD, 4)]
    out, _ = seance(k, 21, s, roles=False)
    assert series(out, 'm.1') >= 3                      # traitée comme principal (plancher)
    assert series(out, 'm.2') == 0 and series(out, 'm.3') == 0


def test_principal_sous_douleur_sans_plancher():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 2, role='main')])
    plan = {'cond': {'zone': 'shoulder'}, 'role': 'main'}
    assert k.seances._douleur_unite(DL, plan) is True
    assert k.seances._douleur_unite(DL, {'cond': {'zone': None}}) is False


def test_repartition_au_prorata_entre_seances():
    """Deux séances identiques, 8 séries d'accessoires de trop : 4 + 4, pas
    8 sur la première."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    s1 = [it('p.1', DL, 5, role='main'), it('p.2', PD, 6, role='accessory')]
    s2 = [it('q.1', DL, 5, role='main'), it('q.2', PD, 6, role='accessory')]
    out1, _ = seance(k, 21, s1, reste=[s2])
    assert k.seances.retour_vol['repartie'] is True
    out2, _ = seance(k, 23, s2)
    # 22 séries « chest » écrites pour 12 admises : 10 de trop, portées par
    # les deux accessoires à parts égales (5 + 5), principaux intacts.
    assert (series(out1, 'p.2'), series(out2, 'q.2')) == (1, 1)
    assert (series(out1, 'p.1'), series(out2, 'q.1')) == (5, 5)
    assert chest(k, 3) <= 12.0 + 1e-9


def test_mode_prudent_apres_une_seance_manquee():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    s1 = [it('p.1', DL, 5, role='main'), it('p.2', PD, 6, role='accessory')]
    s2 = [it('q.1', DL, 5, role='main'), it('q.2', PD, 6, role='accessory')]
    out1, _ = seance(k, 21, s1, reste=[s2], manquees=[0])
    assert k.seances.retour_vol['repartie'] is False
    # La séance du jour paie d'abord : son accessoire à 0 (6 séries), puis le
    # principal du jour vers son plancher (2 séries de plus).
    assert series(out1, 'p.2') == 0
    assert series(out1, 'p.1') == 3


def test_fenetre_d_assiduite():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    k.seances.semaines_manquees.add(3 - S['retour_repartition_semaines'])   # hors fenêtre
    s1 = [it('p.1', DL, 5, role='main'), it('p.2', PD, 6, role='accessory')]
    seance(k, 21, s1, reste=[s1])
    assert k.seances.retour_vol['repartie'] is True


def test_parametres_1_0_6():
    assert PARAMS['version'] == '1.0.6-ref.1'
    assert S['retour_plancher_principal'] == 0.5
    assert S['retour_repartition_semaines'] == 4
    assert 'elargissement_rien_de_special' not in PARAMS['rupture']
