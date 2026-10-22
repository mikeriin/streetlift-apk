# -*- coding: utf-8 -*-
"""Lot KM5 (Koach 1.0.7, DECISIONS_CP.md C17.40) : la rampe de volume ne
coupe jamais sous l'écrit du programme de l'athlète
(CHANGEMENTS_1_0_7.md, contrat § 8.5).

1. aucune série ni aucun exercice retiré au nom du volume : un programme
   choisi plus volumineux que les semaines d'avant est servi tel qu'écrit,
   tous rôles, séance du jour comme séances restantes et manquées ;
2. la rampe borne seulement ce que Koach AJOUTE au-dessus de l'écrit
   (`koachVolume`) : par groupe et par semaine, servi ≤ max(limite de la
   rampe, écrit de la semaine) ; ajouts retirés accessoires d'abord, puis
   la ligne la plus tardive ; raison `koach.ajout_borne` ;
3. coupes sous l'écrit gardées pour leurs causes : douleur (conduite sous
   douleur), rampe tendineuse des tenues bras tendus ;
4. scénarios du prompt (C17.40.2) : (a) avancé, trois semaines d'un
   programme A puis un programme B de six séances par semaine en PPL
   (+43 % « chest », +57 % « delt_anterior », +60 % « triceps ») : lundi de
   tirage et mardi de poussée servis à leurs séries écrites, aucune raison
   de coupe ; (b) même athlète, douleur à l'épaule signalée le mardi : la
   conduite sous douleur coupe comme avant ; (c) un ajout de Koach qui
   dépasserait la limite est borné.

Données synthétiques seulement (C17.33).
"""
import copy
import json
import math
import os

from koach.moteur import Koach
from koach.rupture import Surveillance

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']

S = PARAMS['securite']
GROUPES = S['volume_groupes_majeurs']
CHEST = GROUPES.index('chest')
DANT = GROUPES.index('delt_anterior')
TRI = GROUPES.index('triceps')

MU = 'sl-muscle-up-leste'
TL = 'sl-traction-lestee'
FP = 'mu-face-pull-corde'
CU = 'mu-curl-barre-ez'
RW = 'mu-rowing-pendlay'
DL = 'sl-dips-leste'
TP = 'sw-traction-pronation'
PL = 'sl-pompe-lestee-gilet'
DM = 'mu-developpe-militaire-barre-debout'
RE = 'mu-rotation-externe-poulie'
ET = 'mu-extension-triceps-poulie-croisee'
EL = 'mu-elevation-laterale-halteres'
PP = 'sw-pompe'
PD = 'sw-pompe-declinee'
SQ = 'mu-back-squat-barre-basse'

#: Codes de raison de la rampe de volume (ajouts) et des coupes.
VOLUME = ('koach.ajout_borne', 'koach.retour_gradue')


def koach(niveau=2):
    return Koach(PARAMS, FICHES, {'niveau': niveau, 'sexe': 'male', 'poids_kg': 75.0, 'declares': {},
                                  'zones_fragiles': []})


def it(slot, ex, sets, flames=7, kind='work', role=None, ajout=None, reps=(3, 6)):
    d = {'slotId': slot, 'exerciseId': ex, 'kind': kind, 'sets': sets, 'repsLow': reps[0], 'repsHigh': reps[1],
         'targetFlames': flames}
    if role is not None:
        d['role'] = role
    if ajout is not None:
        # Séries ajoutées par Koach au-dessus de l'écrit du programme
        # (`Planification.appliquer`, bras A du contrôle dual).
        d['sets'] = sets + ajout
        d['koachVolume'] = ajout
    return d


def roles_de(items):
    return {x['slotId']: x.get('role') for x in items}


def volume(items):
    return [{k: x.get(k) for k in ('slotId', 'exerciseId', 'kind', 'sets', 'targetFlames', 'secondsLow',
                                    'secondsHigh', 'role')} for x in items]


def seance(k, jour, items, reste=(), manquees=(), zones=None, douleurs=None, genre='accumulation'):
    """Ouvre, sert et ferme la séance [items] du jour [jour] ; [reste] :
    séances restantes de la semaine (écrit) ; [manquees] : (semaine, items)
    des séances manquées versées au contexte ; [douleurs] : gênes du bilan.
    Renvoie (items servis, raisons)."""
    c = {'semaine': jour // 7, 'genre': genre, 'reste_semaine': [volume(r) for r in reste],
         'manquees': [{'semaine': w, 'genre': 'accumulation', 'items': volume(m)} for (w, m) in manquees]}
    k.garde.avancer(jour)
    bilan = None
    if douleurs is not None:
        bilan = {'overall': 4, 'pains': douleurs}
        k.garde.noter_seance(jour, douleurs, posee=True)
    k.seances.ouvrir(jour, bilan, c)
    out = k.seances.prescrire(copy.deepcopy(items), {}, zones or {}, roles_de(items))
    raisons = list(k.seances.raisons)
    sets = []
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


def credits(ex):
    return [(g, int(math.floor(w * 2 + 0.5)) / 2.0) for (g, w) in FICHES[ex]['groupes'] if g < len(GROUPES)]


def ecrit(seances, g):
    t = 0.0
    for s in seances:
        for x in s:
            n = x['sets'] - (x.get('koachVolume') or 0)
            for (gi, c) in credits(x['exerciseId']):
                if gi == g:
                    t += c * n
    return t


def codes(raisons, *cs):
    return [r for r in raisons if r['code'] in cs]


# ----------------------------------------------------------------------
# Programmes synthétiques du constat (C17.40.2)
# ----------------------------------------------------------------------
def programme_a():
    """Programme A, quatre séances par semaine (26,5 séries « chest »,
    17,5 « delt_anterior », 21 « triceps »)."""
    return [
        [it('a0.1', DL, 6, role='main'), it('a0.2', PL, 4, role='secondary'), it('a0.3', ET, 1, role='accessory')],
        [it('a1.1', TL, 8, role='main'), it('a1.2', MU, 5, role='main'), it('a1.3', RW, 4, role='secondary'),
         it('a1.4', FP, 3, role='accessory'), it('a1.5', CU, 3, role='accessory')],
        [it('a2.1', SQ, 8, role='main')],
        [it('a3.1', DL, 5, role='main'), it('a3.2', TL, 5, role='secondary'), it('a3.3', RW, 3, role='accessory')],
    ]


def programme_b():
    """Programme B, six séances par semaine en PPL : lundi de tirage
    (muscle-up lesté E2MOM 6 × 2, traction lestée E2MOM 8 × 3, accessoires),
    mardi de poussée (dip lesté E2MOM 8 × 3 avec tractions au poids du corps
    dans la pause, pompes lestées 4 × 6, développé militaire 3 × 8,
    rotations externes 2 × 15, extension triceps 3 × 12, élévations
    latérales 3 × 15), jambes, tirage, poussée, jambes."""
    return [
        [it('b0.1', MU, 6, role='main', reps=(2, 2)), it('b0.2', TL, 8, role='main', reps=(3, 3)),
         it('b0.3', RW, 3, role='secondary'), it('b0.4', FP, 3, role='accessory'), it('b0.5', CU, 3, role='accessory')],
        [it('b1.1', DL, 8, role='main', reps=(3, 3)), it('b1.2', TP, 8, role='secondary', reps=(5, 5)),
         it('b1.3', PL, 4, role='secondary', reps=(6, 6)), it('b1.4', DM, 3, role='secondary', reps=(8, 8)),
         it('b1.5', RE, 2, role='accessory', reps=(15, 15)), it('b1.6', ET, 3, role='accessory', reps=(12, 12)),
         it('b1.7', EL, 3, role='accessory', reps=(15, 15))],
        [it('b2.1', SQ, 5, role='main')],
        [it('b3.1', TL, 5, role='main'), it('b3.2', RW, 4, role='secondary'), it('b3.3', FP, 3, role='accessory')],
        [it('b4.1', DL, 5, role='main'), it('b4.2', PL, 3, role='secondary'), it('b4.3', ET, 3, role='accessory')],
        [it('b5.1', SQ, 5, role='main')],
    ]


def trois_semaines_a(k):
    for w in range(3):
        a = programme_a()
        for i, s in enumerate(a):
            seance(k, 7 * w + [0, 1, 3, 5][i], s, reste=a[i + 1:])
    return 21


def ecrit_de(slot, prog):
    return [y for s in prog for y in s if y['slotId'] == slot][0]['sets']


def test_volumes_du_scenario():
    a, b = programme_a(), programme_b()
    assert (ecrit(a, CHEST), ecrit(a, DANT), ecrit(a, TRI)) == (26.5, 17.5, 21.0)
    assert (ecrit(b, CHEST), ecrit(b, DANT), ecrit(b, TRI)) == (38.0, 27.5, 33.5)
    assert round(ecrit(b, CHEST) / ecrit(a, CHEST), 2) == 1.43
    assert round(ecrit(b, DANT) / ecrit(a, DANT), 2) == 1.57
    assert round(ecrit(b, TRI) / ecrit(a, TRI), 2) == 1.6


def test_scenario_a_programme_plus_volumineux_servi_tel_qu_ecrit():
    """(a) Toutes les lignes de la semaine du programme B servies à leurs
    séries écrites (le lundi de tirage et le mardi de poussée compris),
    aucune raison de la rampe de volume ; l'écrit au-dessus de la limite fait
    le plafond (max(limite, écrit)), rien n'est en excès."""
    k = koach()
    trois_semaines_a(k)
    lim_dant = k.seances._limite_volume(DANT, 3)
    lim_tri = k.seances._limite_volume(TRI, 3)
    assert lim_dant < ecrit(programme_b(), DANT) and lim_tri < ecrit(programme_b(), TRI)
    b = programme_b()
    for i, s in enumerate(b):
        out, raisons = seance(k, 21 + i, s, reste=b[i + 1:])
        assert [(x['slotId'], x['sets']) for x in out] == [(x['slotId'], x['sets']) for x in s]
        assert not codes(raisons, *VOLUME)
        if i == 1:
            rv = k.seances.retour_vol
            assert rv['depasse'] == []
            assert rv['limites'][DANT] < rv['ecrit'][DANT] and rv['limites'][TRI] < rv['ecrit'][TRI]
            assert rv['plafonds'][DANT] == ecrit(b, DANT) and rv['plafonds'][TRI] == ecrit(b, TRI)
            assert rv['plan'] == {x['slotId']: x['sets'] for x in s if credits(x['exerciseId'])}
    # Réalisé de la semaine = écrit du programme, au-dessus de la limite.
    assert k.seances.vol_semaines[3][DANT] == ecrit(b, DANT) > lim_dant


def test_scenario_c17_37_de_km4_servi_tel_qu_ecrit():
    """Le programme B de KM4 (C17.37 : lundi de tirage, +40 % « chest ») :
    en 1.0.6, muscle-up lesté 4 sur 6, traction lestée 3 sur 4, pull-over
    retiré ; en 1.0.7, tout est servi à son écrit."""
    k = koach()
    for w in range(3):
        a = [[it('a0.1', DL, 5, role='main'), it('a0.2', PP, 4, role='secondary')],
             [it('a1.1', TL, 4, role='main'), it('a1.2', RW, 5, role='secondary'), it('a1.3', FP, 4, role='accessory')],
             [it('a2.1', SQ, 8, role='main')],
             [it('a3.1', DL, 4, role='main'), it('a3.2', PP, 3, role='secondary'),
              it('a3.3', TL, 4, role='secondary'), it('a3.4', RW, 3, role='accessory')]]
        for i, s in enumerate(a):
            seance(k, 7 * w + [0, 1, 3, 5][i], s, reste=a[i + 1:])
    b = [[it('b0.1', MU, 6, role='main'), it('b0.2', TL, 4, role='main'),
          it('b0.3', 'mu-pull-over-haltere', 3, role='accessory'), it('b0.4', FP, 3, role='accessory')],
         [it('b1.1', DL, 5, role='main'), it('b1.2', PP, 3, role='secondary'), it('b1.3', PD, 2, role='accessory')],
         [it('b2.1', SQ, 5, role='main')]]
    out, raisons = seance(k, 21, b[0], reste=b[1:])
    assert [x['sets'] for x in out] == [6, 4, 3, 3]
    assert not codes(raisons, *VOLUME)


def test_scenario_b_douleur_a_l_epaule_le_mardi():
    """(b) Même athlète, gêne à l'épaule (4/10) signalée le mardi : la
    conduite sous douleur retire ou réduit les mouvements qui sollicitent
    l'épaule, comme avant ; aucune raison de la rampe de volume."""
    zones = {}
    for ex in (DL, PL, DM, EL, RE):
        zones[ex] = ({'shoulder': 1.0}, {'shoulder'})
    k = koach()
    trois_semaines_a(k)
    b = programme_b()
    seance(k, 21, b[0], reste=b[1:])
    out, raisons = seance(k, 22, b[1], reste=b[2:], zones=zones, douleurs=[{'zone': 'shoulder', 'intensity': 4}])
    # Les cinq mouvements qui sollicitent l'épaule sont retirés (gêne 4/10).
    assert [(x['slotId'], x['sets']) for x in out] == [('b1.2', 8), ('b1.6', 3)]
    assert [r['params']['exercice'] for r in codes(raisons, 'koach.douleur_retrait')] == [DL, PL, DM, RE, EL]
    assert not codes(raisons, *VOLUME)
    # Les lignes qui ne sollicitent pas l'épaule restent à leur écrit.
    for x in b[1]:
        if x['exerciseId'] not in zones:
            assert series(out, x['slotId']) == x['sets']


def test_scenario_c_ajout_de_koach_borne():
    """(c) Koach ajoute des séries (planification ou bras A) : au-delà de
    max(limite, écrit de la semaine), les ajouts sont retirés (accessoire
    d'abord), jamais l'écrit ; raison `koach.ajout_borne`."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    lim = k.seances._limite_volume(CHEST, 3)
    assert lim == 12.0
    s = [it('m.1', DL, 6, role='main', ajout=2), it('m.2', PP, 4, role='secondary', ajout=1),
         it('m.3', PD, 2, role='accessory', ajout=2)]
    out, raisons = seance(k, 21, s)
    # Écrit 12 = limite 12 : les 5 séries ajoutées sont retirées, accessoire
    # d'abord, puis le secondaire, puis le principal.
    assert (series(out, 'm.1'), series(out, 'm.2'), series(out, 'm.3')) == (6, 4, 2)
    rg = [r['params'] for r in codes(raisons, 'koach.ajout_borne')]
    assert [(p['exercice'], p['series'], p['ecrites'], p['prevues'], p['groupe'], p['limite'], p['ecrit'])
            for p in rg] == [(DL, 6, 6, 8, 'chest', 12.0, 12.0), (PP, 4, 4, 5, 'chest', 12.0, 12.0),
                             (PD, 2, 2, 4, 'chest', 12.0, 12.0)]
    assert not codes(raisons, 'koach.retour_gradue')
    # Écrit sous la limite : les ajouts tiennent jusqu'à la limite.
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    s = [it('m.1', DL, 6, role='main', ajout=2), it('m.2', PP, 2, role='secondary', ajout=1),
         it('m.3', PD, 1, role='accessory', ajout=2)]
    out, raisons = seance(k, 21, s)
    # Écrit 9, ajouts 5 → 14 pour 12 admises : 2 séries retirées, à
    # l'accessoire.
    assert (series(out, 'm.1'), series(out, 'm.2'), series(out, 'm.3')) == (8, 3, 1)
    assert [r['params']['prevues'] - r['params']['series'] for r in codes(raisons, 'koach.ajout_borne')] == [2]


def test_ajout_la_ligne_la_plus_tardive_d_abord():
    """Dans un même rang, l'ajout de la ligne la plus tardive est retiré
    d'abord (l'ajout le plus récent)."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    s = [it('m.1', DL, 5, role='main', ajout=1), it('m.2', PP, 3, role='accessory', ajout=2),
         it('m.3', PD, 3, role='accessory', ajout=2)]
    out, _ = seance(k, 21, s)
    # Écrit 11, ajouts 5 → 16 pour 12 : m.3 perd ses 2, m.2 ses 2, le
    # principal garde le sien (11 + 1 = 12).
    assert (series(out, 'm.1'), series(out, 'm.2'), series(out, 'm.3')) == (6, 3, 3)


def test_jamais_sous_l_ecrit_meme_au_dessus_de_la_limite():
    """Semaines basses puis un écrit énorme (ancien test de 1.0.6 : principal
    à 1 série, le reste à 0) : tout est servi à son écrit ; l'écrit fait le
    plafond, rien n'est en excès."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 2, role='main')])
    s = [it('m.1', DL, 10, role='main'), it('m.2', PP, 6, role='secondary'), it('m.3', PD, 6, role='accessory')]
    reste = [[it('r%d.1' % i, DL, 10, role='main'), it('r%d.2' % i, PP, 6, role='secondary')] for i in range(4)]
    out, raisons = seance(k, 21, s, reste=reste)
    assert [x['sets'] for x in out] == [10, 6, 6]
    assert not codes(raisons, *VOLUME)
    rv = k.seances.retour_vol
    assert rv['depasse'] == []
    assert rv['limites'][CHEST] == 4.0 and rv['plafonds'][CHEST] == rv['ecrit'][CHEST] == 22.0 + 4 * 16.0


def test_sans_role_et_sans_ajout_rien_n_est_coupe():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 2)])
    s = [it('m.1', DL, 6), it('m.2', PP, 4), it('m.3', PD, 4)]
    for x in s:
        x.pop('role', None)
    out, raisons = seance(k, 21, s)
    assert [x['sets'] for x in out] == [6, 4, 4]
    assert not codes(raisons, *VOLUME)


def test_sans_role_la_premiere_ligne_creditee_est_le_principal():
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10)])
    s = [it('m.1', DL, 6, ajout=2), it('m.2', PP, 6, ajout=2)]
    out, _ = seance(k, 21, s)
    # 12 écrites, 4 ajoutées : la seconde ligne (rang 0) perd ses ajouts la
    # première, puis la première (principal).
    assert (series(out, 'm.1'), series(out, 'm.2')) == (6, 6)


def test_seance_manquee_comptee_a_l_ecrit():
    """Une séance manquée de la semaine compte à son écrit au réalisé ET à
    l'écrit de la semaine : elle ne fait rien couper sous l'écrit."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 6, role='main')])
    manquee = [it('q.1', DL, 8, role='main')]
    out, raisons = seance(k, 23, [it('m.1', DL, 8, role='main'), it('m.2', PP, 4, role='accessory')],
                          manquees=[(3, manquee)])
    assert [x['sets'] for x in out] == [8, 4]
    assert not codes(raisons, *VOLUME)
    assert k.seances.retour_vol['ecrit'][CHEST] == 20.0
    assert k.seances.retour_vol['fait'][CHEST] == 8.0


def test_reduction_d_un_ajout_negatif_ne_change_pas_l_ecrit():
    """`koachVolume` négatif (la planification a retiré des séries) : la
    ligne est sous son écrit, la rampe n'y touche pas."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 4, role='main')])
    out, raisons = seance(k, 21, [it('m.1', DL, 10, role='main', ajout=-1)])
    assert series(out, 'm.1') == 9
    assert not codes(raisons, *VOLUME)
    assert k.seances._ecrites({'sets': 9, 'koachVolume': -1}) == 10
    assert k.seances._ecrites({'sets': 9}) == 9


def test_allegement_borne_les_ajouts_seulement():
    """Semaine d'allègement (genre `deload`) : le total des séries dures
    n'est borné qu'au-dessus de max(limite de l'allègement, écrit de la
    semaine)."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main'), it('y%d' % w, SQ, 10, role='main')])
    s = [it('m.1', DL, 4, role='main', ajout=4), it('m.2', SQ, 4, role='main', ajout=4)]
    out, raisons = seance(k, 21, s, genre='deload')
    rv = k.seances.retour_vol
    assert rv['limite_dures'] == S['decharge_part'] * 20.0
    assert rv['plafond_dures'] == max(rv['limite_dures'], 8.0) == 14.0
    # 16 prévues pour 14 : deux ajouts retirés, au plus tardif d'abord.
    assert (series(out, 'm.1'), series(out, 'm.2')) == (8, 6)
    assert {r['params']['groupe'] for r in codes(raisons, 'koach.ajout_borne')} == {'allegement'}


def test_allegement_d_un_diagnostic_garde_koach_volume():
    """Semaine allégée codée par la surveillance (action « fatigue ») :
    `koachVolume` reste « servies − écrites du programme »."""
    sv = Surveillance(PARAMS)
    sv.allegement = (0, 7, 0.6, 1.0)
    out = sv.appliquer_allegement([it('a', DL, 5), it('b', DL, 4, ajout=1)], 3)
    assert [(x['sets'], x['koachVolume']) for x in out] == [(3, -2), (3, -1)]
    k = koach()
    assert [k.seances._ecrites(x) for x in out] == [5, 4]


def test_tenues_bras_tendus_regle_tendineuse_gardee():
    """Rampe tendineuse (M1 de KM4) : seule coupe de `_retour_gradue` sous
    l'écrit, raison `koach.retour_gradue` d'une famille de tenue."""
    tenue = 'cs-90-hold'
    assert FICHES[tenue].get('bras_tendus') and FICHES[tenue].get('renforcement')
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [{'slotId': 'h%d' % w, 'exerciseId': tenue, 'kind': 'work', 'sets': 3, 'secondsLow': 10,
                           'secondsHigh': 10, 'targetFlames': 7}])
    out, raisons = seance(k, 21, [{'slotId': 'h', 'exerciseId': tenue, 'kind': 'work', 'sets': 8,
                                   'secondsLow': 20, 'secondsHigh': 20, 'targetFlames': 7}])
    # Limite 35 s (30 × 1,15 = 34,5 ou 30 + 5) : 7 séries de 5 s.
    assert [(x['sets'], x['secondsLow'], x['secondsHigh']) for x in out] == [(7, 5, 5)]
    rg = [r['params'] for r in codes(raisons, 'koach.retour_gradue')]
    assert rg == [{'exercice': tenue, 'groupe': 'bras_tendus_push', 'limite': 35.0, 'series': 7, 'secondes': 5,
                   'ecrites': 8, 'douleur': False}]
    assert not codes(raisons, 'koach.ajout_borne')


def test_douleur_sur_une_ligne_ajouts_sur_une_autre():
    """Relecture KM5 (M1) : l'écrit d'une ligne retirée par la douleur ne
    compte pas au plafond ; les ajouts de Koach sur une autre ligne du même
    groupe restent bornés à la limite de la rampe (écrit SERVI)."""
    zones = {DL: ({'shoulder': 1.0}, {'shoulder'})}
    k = koach()
    for w in range(4):
        seance(k, 7 * w, [it('x%d' % w, DL, 4, role='main')], zones=zones)
    out, raisons = seance(k, 28, [it('m.1', DL, 12, role='main'), it('m.2', PP, 4, role='secondary', ajout=8)],
                          zones=zones, douleurs=[{'zone': 'shoulder', 'intensity': 4}])
    assert [(x['slotId'], x['sets']) for x in out] == [('m.2', 6)]
    rv = k.seances.retour_vol
    assert (rv['limites'][CHEST], rv['ecrit'][CHEST], rv['plafonds'][CHEST]) == (6.0, 4.0, 6.0)
    assert [r['params']['series'] for r in codes(raisons, 'koach.ajout_borne')] == [6]
    assert codes(raisons, 'koach.douleur_retrait')


def test_allegement_decide_sur_l_ecrit_du_programme():
    """Relecture KM5 (M2) : une semaine écrite en allègement (6 ≤ 0,7 × 10)
    le reste malgré les ajouts de Koach (+3) : le total est borné à
    max(0,7 × 10 ; 6) = 7."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    out, raisons = seance(k, 21, [it('m.1', DL, 6, role='main', ajout=3)])
    rv = k.seances.retour_vol
    assert (rv['limite_dures'], rv['plafond_dures']) == (7.0, 7.0)
    assert series(out, 'm.1') == 7
    assert [r['params']['groupe'] for r in codes(raisons, 'koach.ajout_borne')] == ['allegement']


def test_deux_prescriptions_de_la_meme_seance():
    """Relecture KM5 (m1) : un second `prescrire` de la même séance ne
    compte pas son écrit deux fois (mêmes séries servies)."""
    k = koach()
    for w in range(3):
        seance(k, 7 * w, [it('x%d' % w, DL, 10, role='main')])
    c = {'semaine': 3, 'genre': 'accumulation', 'reste_semaine': [], 'manquees': []}
    k.garde.avancer(21)
    k.seances.ouvrir(21, None, c)
    s = [it('m.1', DL, 6, role='main', ajout=2), it('m.2', PP, 6, role='secondary', ajout=4)]
    a = k.seances.prescrire(copy.deepcopy(s), {}, {}, roles_de(s))
    b = k.seances.prescrire(copy.deepcopy(s), {}, {}, roles_de(s))
    assert [x['sets'] for x in a] == [x['sets'] for x in b] == [6, 6]
    assert k.seances.ecrit_vol[3][CHEST] == 12.0


def test_filtre_du_validateur_volume_ecrit():
    """Définition KM5 de `volume_trop_vite` (banc) : gardé seulement si le
    servi dépasse max(limite, écrit de la semaine) ; groupe trouvé par la
    valeur servie (à égalité, le premier qui dépasse) ; semaine inconnue ou
    groupe introuvable : gardé (prudent) ; autres codes inchangés."""
    from banc import securite_banc as sb
    v = lambda w, val, lim: {'code': 'volume_trop_vite', 'week': w, 'value': val, 'limit': lim}
    servi = [{0: 10.0, 4: 12.0}, {0: 14.0, 4: 12.0, 7: 9.0}]
    ecrit = [{0: 10.0, 4: 12.0}, {0: 12.0, 4: 13.0, 7: 9.0}]
    found = [v(1, 14.0, 10.0), v(1, 12.0, 10.0), v(1, 9.0, 8.0), v(5, 3.0, 2.0), v(1, 7.0, 6.0),
             {'code': 'charge_trop_vite', 'week': 1, 'value': 0.2, 'limit': 0.05}]
    out = sb.filtrer_volume_ecrit(found, servi, ecrit)
    assert [(c['code'], c.get('value'), c.get('ecrit', 'absent')) for c in out] == [
        ('volume_trop_vite', 14.0, 12.0),     # 14 > max(10, 12)
        ('volume_trop_vite', 3.0, None),      # semaine hors lecture : gardé
        ('volume_trop_vite', 7.0, None),      # aucun groupe à 7 : gardé
        ('charge_trop_vite', 0.2, 'absent')]
    # Deux groupes à la même valeur : gardé si l'un d'eux dépasse.
    out = sb.filtrer_volume_ecrit([v(0, 12.0, 10.0)], [{0: 12.0, 4: 12.0}], [{0: 6.0, 4: 12.0}])
    assert [c['ecrit'] for c in out] == [6.0]


def test_parametres_1_0_7():
    # (1.0.8, KM6 : version suivante, aucune clé ni valeur changée.)
    assert PARAMS['version'] == '1.0.8-ref.1'
    for cle in ('retour_plancher_principal', 'retour_repartition_semaines', 'retour_emprunt_plancher'):
        assert cle not in S
    assert 'elargissement_rien_de_special' not in PARAMS['rupture']
