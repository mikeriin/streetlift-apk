# -*- coding: utf-8 -*-
"""Lot KM6 (Koach 1.0.8, DECISIONS_CP.md C17.47 ; CHANGEMENTS_1_0_8.md) :
bugs du moteur trouvés par la revue RV1 (X1 à X6, LIVRAISON_RV1.md § 5),
groupe perdu à l'échange (X7, RV1c1 § 4), baisse hebdomadaire sous l'écrit
dite (X8, C17.43.4) et crédits « chest » des tirages (ex-lot KS, KM4 § 5).
Chaque bug a sa reproduction (avant : comportement de 1.0.7, dit dans le
commentaire) et son test de non-régression ; le portage Dart reprend les
mêmes cas et les mêmes valeurs (`test/koach_km6_test.dart`).

Données synthétiques seulement (C17.33).
"""
import copy
import gzip
import json
import os

from banc import politique_koach as pk
from banc.verite import grid_of, make_book
from koach.moteur import Koach
from koach.planification import Planification
from koach.seance import Grille, groupes_servis, technique_coherente

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']

ET = 'mu-extension-triceps-poulie-croisee'
SQ = 'mu-back-squat-barre-basse'
EP = 'mu-epaule-haltere-unilateral'
DL = 'sl-dips-leste'


def koach(niveau=2, declares=None):
    return Koach(PARAMS, FICHES, {'niveau': niveau, 'sexe': 'male', 'poids_kg': 75.0, 'declares': declares or {},
                                  'zones_fragiles': []})


def ouvrir(k, jour, bilan=None, genre='accumulation', **contexte):
    c = {'semaine': jour // 7, 'genre': genre}
    c.update(contexte)
    k.garde.avancer(jour)
    k.seances.ouvrir(jour, bilan, c)


def grille(g):
    return {'pas': g.step, 'minimum': g.minimum, 'halteres': bool(g.dumbbell)}


# ----------------------------------------------------------------------
# X1 : grille de la poulie par 2,5 kg (défaut de kalis_plan), plus 2,5 lb
# ----------------------------------------------------------------------
def test_x1_grille_poulie_par_defaut_en_kg():
    g = grid_of('cable', None)
    # Avant : 2,5 lb (1,134 kg), minimum 2,5 lb.
    assert (g.step, g.minimum, g.dumbbell) == (2.5, 2.5, False)
    # Un pas déclaré par l'athlète reste prioritaire.
    g2 = grid_of('cable', {'loadIncrements': [{'loadType': 'poulie', 'stepKg': 1.25, 'minKg': 1.25}]})
    assert (g2.step, g2.minimum) == (1.25, 1.25)


def test_x1_extension_triceps_poulie_servie_a_2_5_kg_pres_sans_profil_de_pas():
    """Extension triceps poulie servie par Koach sur la grille par défaut du
    banc (aucun pas dans le profil) : charges multiples de 2,5 kg (avant :
    19,28 / 20,41 / 21,55 kg, grille en livres)."""
    k = koach(declares={ET: ('one_rm_kg', 33.0)})
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': None, 'contexte': {}})
    item = {'slotId': 's1', 'exerciseId': ET, 'kind': 'work', 'sets': 3, 'repsLow': 12, 'repsHigh': 12,
            'targetFlames': 7}
    r = k.plan({'horizon': 'seance', 'items': [item], 'grilles': {ET: grille(grid_of('cable', None))},
                'zones': {}, 'roles': {'s1': 'accessory'}})
    charges = [k.plan({'horizon': 'serie', 'item': r['items'][0], 'index': i, 'faites': []})['loadKg']
               for i in range(3)]
    assert charges == [22.5, 22.5, 22.5]
    for c in charges:
        assert abs(c / 2.5 - round(c / 2.5)) < 1e-9


def test_x1_carnet_du_banc():
    infos = json.load(gzip.open(os.path.join(ICI, '..', 'donnees', 'catalogue_infos.json.gz')))
    livre = make_book(infos['exercises'] if isinstance(infos, dict) else infos, None)
    assert (livre[ET].grid.step, livre[ET].grid.minimum) == (2.5, 2.5)


# ----------------------------------------------------------------------
# X2 : groupe d'intervalles recalé sur les lignes servies
# ----------------------------------------------------------------------
def _intervalles(bilan):
    k = koach()
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': bilan, 'contexte': {}})
    items = [{'slotId': 's1', 'exerciseId': 'cf-burpee', 'kind': 'work', 'sets': 8, 'secondsLow': 30,
              'secondsHigh': 30, 'restSeconds': 30, 'groupId': 'g1', 'format': 'intervals'}]
    groupes = [{'groupId': 'g1', 'format': 'intervals', 'rounds': 8, 'intervalSeconds': 30,
                'restBetweenRoundsSeconds': 30}]
    return k.plan({'horizon': 'seance', 'items': items, 'grilles': {}, 'zones': {}, 'roles': {'s1': 'accessory'},
                   'groups': groupes}), groupes


def test_x2_intervalles_reduits_tours_du_groupe_recales():
    """« 8× (30 s / 30 s) » mis à l'échelle (bilan très bas, `wod_echelle`
    75 %) : 6 lignes servies et le groupe à 6 tours (avant : 8 tours pour 6
    lignes, le chrono et les lignes divergeaient)."""
    r, groupes = _intervalles({'overall': 1})
    assert [x['code'] for x in r['raisons']] == ['koach.wod_echelle']
    assert r['items'][0]['sets'] == 6
    assert r['groups'] == [{'groupId': 'g1', 'format': 'intervals', 'rounds': 6, 'intervalSeconds': 30,
                            'restBetweenRoundsSeconds': 30}]
    assert groupes[0]['rounds'] == 8           # les groupes reçus ne sont pas modifiés


def test_x2_sans_groupes_recus_rien_de_change_dans_la_sortie():
    k = koach()
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': None, 'contexte': {}})
    r = k.plan({'horizon': 'seance', 'items': [{'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 3,
                                                'repsLow': 5, 'repsHigh': 5, 'targetFlames': 7}],
                'grilles': {}, 'zones': {}, 'roles': {}})
    assert set(r) == {'items', 'raisons'}
    r2, _ = _intervalles(None)
    assert r2['groups'][0]['rounds'] == 8 and r2['items'][0]['sets'] == 8


def test_x2_groupes_servis_regles():
    ecrits = [{'slotId': 'a', 'groupId': 'c', 'sets': 4}, {'slotId': 'b', 'groupId': 'c', 'sets': 4},
              {'slotId': 'e', 'groupId': 'e', 'sets': 1}, {'slotId': 'm1', 'groupId': 'm', 'sets': 5},
              {'slotId': 'm2', 'groupId': 'm', 'sets': 5}, {'slotId': 'x', 'groupId': 'x', 'sets': 3},
              {'slotId': 'k', 'groupId': 'k', 'sets': 6, 'koachVolume': 2}]
    servis = [{'slotId': 'a', 'groupId': 'c', 'sets': 3}, {'slotId': 'b', 'groupId': 'c', 'sets': 2},
              {'slotId': 'e', 'groupId': 'e', 'sets': 1}, {'slotId': 'm1', 'groupId': 'm', 'sets': 4},
              {'slotId': 'm2', 'groupId': 'm', 'sets': 5}, {'slotId': 'k', 'groupId': 'k', 'sets': 5}]
    groupes = [{'groupId': 'c', 'format': 'circuit', 'rounds': 4},
               {'groupId': 'e', 'format': 'amrap', 'durationSeconds': 600},
               {'groupId': 'm', 'format': 'emom', 'intervalSeconds': 60, 'durationSeconds': 600},
               {'groupId': 'x', 'format': 'superset', 'rounds': 3},
               {'groupId': 'k', 'format': 'intervals', 'rounds': 4, 'intervalSeconds': 60},
               {'groupId': 'r', 'format': 'rounds_for_time', 'rounds': 5}]
    out = groupes_servis(groupes, ecrits, servis)
    assert out == [{'groupId': 'c', 'format': 'circuit', 'rounds': 3},        # max des séries servies
                   {'groupId': 'e', 'format': 'amrap', 'durationSeconds': 600},  # au temps : inchangé
                   {'groupId': 'm', 'format': 'emom', 'intervalSeconds': 60, 'durationSeconds': 540},
                   # x : aucun membre servi, retiré ; r : aucun membre, retiré
                   {'groupId': 'k', 'format': 'intervals', 'rounds': 5, 'intervalSeconds': 60}]
    # Des tours qui ne comptent pas les lignes (rounds ≠ séries écrites) sont gardés.
    assert groupes_servis([{'groupId': 'c', 'format': 'circuit', 'rounds': 2}], ecrits, servis)[0]['rounds'] == 2


# ----------------------------------------------------------------------
# X3 : technique recalée quand Koach change les séries
# ----------------------------------------------------------------------
def test_x3_emom_dont_koach_baisse_les_series():
    """Dips lestés en EMOM 10 × 3, bilan très bas : Koach sert 9 séries ;
    `technique.intervals` vaut 9 (avant : 10, plan refusé par l'application)."""
    k = koach()
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': {'overall': 1}, 'contexte': {}})
    items = [{'slotId': 's1', 'exerciseId': DL, 'kind': 'work', 'sets': 10, 'repsLow': 3, 'repsHigh': 3,
              'targetFlames': 6, 'restSeconds': 0, 'technique': {'kind': 'emom', 'intervalSeconds': 60,
                                                                 'intervals': 10}}]
    r = k.plan({'horizon': 'seance', 'items': items, 'grilles': {}, 'zones': {}, 'roles': {'s1': 'main'}})
    it = r['items'][0]
    assert it['sets'] == 9
    assert it['technique'] == {'kind': 'emom', 'intervalSeconds': 60, 'intervals': 9}
    assert items[0]['technique']['intervals'] == 10        # l'écrit reçu n'est pas modifié


def test_x3_technique_coherente_regles():
    def t(sets, tech, **extra):
        it = {'sets': sets, 'technique': tech}
        it.update(extra)
        technique_coherente(it)
        return it

    assert t(3, {'kind': 'top_set_backoff', 'backoffSets': 3, 'backoffDropPct': 0.1})['technique'] == \
        {'kind': 'top_set_backoff', 'backoffSets': 2, 'backoffDropPct': 0.1}
    regles = [{'kind': 'backoff_from_top_set', 'pct': 0.1}, {'kind': 'rir_floor', 'rirFloor': 1}]
    seul = t(1, {'kind': 'top_set_backoff', 'backoffSets': 2}, autoregulation=regles)
    assert seul['technique'] is None and seul['autoregulation'] == [{'kind': 'rir_floor', 'rirFloor': 1}]
    assert t(6, {'kind': 'emom', 'intervals': 8})['technique']['intervals'] == 6
    assert t(5, {'kind': 'wave', 'waves': 2, 'waveReps': [3, 2, 1]})['technique'] is None
    assert t(6, {'kind': 'wave', 'waves': 2, 'waveReps': [3, 2, 1]})['technique'] is not None
    assert t(4, {'kind': 'pyramid', 'pyramidReps': [8, 6, 4]})['technique'] is None
    assert t(5, {'kind': 'ladder', 'ladderStart': 1, 'ladderStep': 1, 'ladderTop': 5})['technique'] is not None
    assert t(4, {'kind': 'ladder', 'ladderStart': 1, 'ladderStep': 1, 'ladderTop': 5})['technique'] is None
    assert t(2, {'kind': 'density', 'durationSeconds': 600})['technique'] is None
    assert t(1, {'kind': 'density', 'durationSeconds': 600})['technique'] is not None
    assert t(2, {'kind': 'cluster', 'miniSets': 3})['technique'] == {'kind': 'cluster', 'miniSets': 3}
    assert t(2, {'kind': 'emom', 'intervals': 8, 'lastSetOnly': True})['technique']['intervals'] == 8
    assert t(2, None, setTargets=[{'loadKg': 1}, {'loadKg': 2}, {'loadKg': 3}])['setTargets'] == \
        [{'loadKg': 1}, {'loadKg': 2}]
    assert t(3, None, setTargets=[{'loadKg': 1}])['setTargets'] is None


# ----------------------------------------------------------------------
# X4 : test xRM verrouillé, charge écrite hors grille gardée
# ----------------------------------------------------------------------
def test_x4_test_xrm_verrouille_garde_l_ecrit_hors_grille():
    def charge(genre, ecrite):
        k = koach()
        s = k.seances
        ouvrir(k, 10, genre=genre)
        t = k.modele.piste(SQ)
        t.mesures = 1
        item = {'slotId': 's1', 'exerciseId': SQ, 'kind': 'test', 'sets': 1, 'repsLow': 3, 'repsHigh': 3,
                'startLoadKg': ecrite, 'test': {'kind': 'rep_max', 'targetRir': 1}}
        servi = s.prescrire([item], {SQ: Grille(2.5, 20.0)}, {SQ: ({}, set())}, {'s1': 'main'})
        return s.cible(servi[0], 0, [])['loadKg']
    assert charge('test', 61.0) == 61.0        # avant : 60,0, sous l'écrit
    assert charge('test', 60.0) == 60.0
    assert charge('accumulation', 61.0) > 61.0


# ----------------------------------------------------------------------
# X5, X6 : jamais au-dessus d'un plafond (arrondi, test adaptatif)
# ----------------------------------------------------------------------
def _premiere(ex, part, genre, grille_):
    k = koach()
    s = k.seances
    ouvrir(k, 10, genre=genre)
    t = k.modele.piste(ex)
    t.mesures = 1
    t.seances = 2
    reps, flammes = (5, 10) if ex == SQ else (3, 7)
    item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'repsLow': reps, 'repsHigh': reps,
            'targetFlames': flammes}
    if part is not None:
        item['percentOfOneRm'] = part
    servi = s.prescrire([item], {ex: grille_}, {ex: ({}, set())}, {'s1': 'main'})
    c = s.cible(servi[0], 0, [])
    # Plafond appliqué (part écrite, couloir de +15 % hors semaine
    # verrouillée), lu dans la trace de la cible.
    caps = [float(x.split('-> ')[1]) for x in c.get('trace') or [] if x.startswith('part ecrite')]
    return c['loadKg'], (caps[0] if caps else None)


def test_x5_charge_plafonnee_arrondie_vers_le_bas():
    """Semaine verrouillée, 70 % écrits du 1RM (91,875 kg) : 90 kg (avant :
    92,5 kg, l'arrondi au plus proche passait au-dessus du plafond)."""
    charge, plafond = _premiere(SQ, 0.70, 'test', Grille(2.5, 20.0))
    assert abs(plafond - 91.9) < 1e-9          # trace au dixième (91,875)
    assert charge == 90.0


def test_x6_test_adaptatif_sous_le_plafond():
    """Haltère par 5 kg, 62 % écrits (plafond 20,1 kg) : le test adaptatif ne
    prend plus le cran du dessus (avant : 25 kg)."""
    for part in (0.62, 0.63, 0.64):
        charge, plafond = _premiere(EP, part, 'accumulation', Grille(5.0, 5.0))
        assert charge == 20.0
        assert charge <= plafond + 0.05           # plafond lu au dixième


def test_x5_x6_sans_plafond_inchange():
    charge, _ = _premiere(SQ, None, 'accumulation', Grille(2.5, 20.0))
    assert charge == 100.0


# ----------------------------------------------------------------------
# X7 : l'item servi garde le groupe de l'emplacement
# ----------------------------------------------------------------------
def test_x7_course_facile_garde_le_groupe():
    """Fractionné 6 × 400 m dans un bloc d'intervalles, bilan très bas :
    course facile à la place, dans le groupe (avant : `groupId` nul, le
    format du bloc était perdu) ; le groupe passe à un tour."""
    k = koach(niveau=1)
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': {'overall': 1}, 'contexte': {}})
    items = [{'slotId': 's1', 'exerciseId': 'ca-fractionne-400m', 'kind': 'work', 'sets': 6, 'distanceMeters': 400,
              'targetFlames': 8, 'restSeconds': 90, 'groupId': 'g1', 'format': 'intervals'}]
    r = k.plan({'horizon': 'seance', 'items': items, 'grilles': {}, 'zones': {}, 'roles': {},
                'groups': [{'groupId': 'g1', 'format': 'intervals', 'rounds': 6, 'intervalSeconds': 90}]})
    it = r['items'][0]
    assert it['exerciseId'] == 'ca-footing-endurance-fondamentale'
    assert (it['groupId'], it['format'], it['sets']) == ('g1', 'intervals', 1)
    assert 'koach.course_facile' in [x['code'] for x in r['raisons']]
    assert r['groups'] == [{'groupId': 'g1', 'format': 'intervals', 'rounds': 1, 'intervalSeconds': 90}]


def test_x7_vrai_test_hors_du_groupe():
    """La montée d'un vrai test (emplacement `<slot>.t`) n'entre pas dans le
    groupe de la ligne (elle se fait avant)."""
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    servi = s.prescrire([{'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 4, 'repsLow': 5,
                          'repsHigh': 5, 'targetFlames': 7, 'groupId': 'g1'}],
                        {SQ: Grille(2.5, 20.0)}, {SQ: ({}, set())}, {'s1': 'main'})
    for it in servi:
        if it.get('koach') == 'vrai_test':
            assert it.get('groupId') is None
        else:
            assert it['groupId'] == 'g1'


# ----------------------------------------------------------------------
# X8 : baisse hebdomadaire de la planification sous l'écrit, dite
# ----------------------------------------------------------------------
def test_x8_baisse_de_la_modulation_dite():
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    items = [{'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 5,
              'targetFlames': 7, 'koachVolume': -1, 'koachModule': -1},
             {'slotId': 's2', 'exerciseId': DL, 'kind': 'work', 'sets': 5, 'repsLow': 5, 'repsHigh': 5,
              'targetFlames': 7, 'koachVolume': 1, 'koachModule': 1},
             {'slotId': 's3', 'exerciseId': SQ, 'kind': 'warmup', 'sets': 1, 'repsLow': 5, 'repsHigh': 5,
              'targetFlames': 3, 'koachVolume': -1, 'koachModule': -1}]
    s.prescrire(items, {SQ: Grille(2.5, 20.0), DL: Grille(1.25, 0.0)}, {}, {'s1': 'main', 's2': 'main'})
    dites = [r for r in s.raisons if r['code'] == 'koach.volume_semaine']
    assert dites == [{'code': 'koach.volume_semaine',
                      'params': {'exercice': SQ, 'ecrites': 4, 'series': 3, 'cause': 'planification'}}]


def test_x8_planification_pose_koach_module():
    p = Planification.__new__(Planification)
    p.items_modules = lambda semaine: {(1, 'a'): (2, 0.0), (1, 'b'): (4, 0.02), (1, 'c'): (3, 0.0)}
    items = [{'slotId': 'a', 'sets': 3}, {'slotId': 'b', 'sets': 3}, {'slotId': 'c', 'sets': 3},
             {'slotId': 'd', 'sets': 3}]
    out = Planification.appliquer(p, 0, 1, items)
    assert [(x['sets'], x.get('koachVolume'), x.get('koachModule')) for x in out] == \
        [(2, -1, -1), (4, 1, 1), (3, None, None), (3, None, None)]
    assert out[1]['koachIntensite'] == 0.02
    assert 'koachModule' not in items[0]


def test_x8_mesure_du_banc():
    """`mesure_module` : lignes baissées, séries retirées, séances, baisses
    sans raison (0 attendu)."""
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    items = [{'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 5,
              'targetFlames': 7, 'koachVolume': -1, 'koachModule': -1}]
    servis = s.prescrire(copy.deepcopy(items), {SQ: Grille(2.5, 20.0)}, {}, {'s1': 'main'})
    acc = pk.rampe_vide()
    pk.mesure_rampe(acc, items, {'s1': 'main'}, servis, s.raisons, s, {})
    assert (acc['module_items'], acc['module_series'], acc['module_seances'], acc['module_sans_raison']) == \
        (1, 1, 1, 0)
    acc2 = pk.rampe_vide()
    pk.mesure_rampe(acc2, items, {'s1': 'main'}, servis, [], s, {})
    assert acc2['module_sans_raison'] == 1


# ----------------------------------------------------------------------
# Crédits « chest » des tirages (ex-lot KS)
# ----------------------------------------------------------------------
def _chest(ex):
    for g, w in FICHES[ex]['groupes']:
        if g == 0:
            return w
    return 0.0


def test_credits_table_avant_apres():
    attendu = {
        'sl-traction-lestee': 0.0, 'sl-traction-lestee-prise-serree': 0.0, 'sl-chin-up-leste': 0.0,
        'sw-traction-pronation': 0.0, 'sw-traction-supination': 0.0, 'sw-traction-neutre': 0.0,
        'cd-traction-un-bras': 0.0, 'cf-traction-kipping': 0.0, 'cd-traction-explosive-hanches': 0.0,
        'sl-muscle-up-leste': 0.5, 'cd-muscle-up-barre-strict': 0.5, 'cd-muscle-up-anneaux-strict': 0.5,
        'mu-pull-over-haltere': 0.5,
        'sl-dips-leste': 1.0, 'sw-pompe': 1.0, 'mu-developpe-couche-barre': 1.0, 'mu-pull-over-machine': 0.5,
        'mu-rowing-pendlay': 0.0, 'cs-back-lever': 1.0, 'cs-front-lever': 0.5, 'cd-hefesto': 0.5,
    }
    for ex, v in attendu.items():
        assert _chest(ex) == v, ex
    for ex, f in FICHES.items():
        if f['schema'] == 'tirage_vertical':
            assert _chest(ex) == 0.0, ex
        if f['schema'] == 'transition_muscle_up':
            assert _chest(ex) <= 0.5, ex


def test_credits_fiches_egales_aux_credits_de_kalis_plan_exportes():
    """Fiches de Koach = crédits de `kalis_plan` exportés pour le validateur
    du banc (`donnees/catalogue_infos.json.gz`, `groupCredits`), exercice
    par exercice et groupe par groupe ; asset = référence, à l'octet."""
    infos = json.load(gzip.open(os.path.join(ICI, '..', 'donnees', 'catalogue_infos.json.gz')))['exercises']
    vus = 0
    for e in infos:
        f = FICHES[e['id']]
        credits = [0] * len(e['groupCredits'])
        for g, w in f['groupes']:
            credits[g] = int(round(w * 2))
        assert credits == e['groupCredits'], e['id']
        vus += 1
    assert vus == len(FICHES)
    with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), 'rb') as a, \
            open(os.path.join(ICI, '..', '..', 'assets', 'koach', 'vecteurs_qualites_v1.json'), 'rb') as b:
        assert a.read() == b.read()


def test_credits_regles_a_jour():
    import subprocess
    import sys
    r = subprocess.run([sys.executable, os.path.join(ICI, '..', 'qualites', 'regles.py'), '--verifier'])
    assert r.returncode == 0


# ----------------------------------------------------------------------
# Relecture indépendante (KM6) : constats traités
# ----------------------------------------------------------------------
def test_relecture_groupes_contre_la_montre_emom_aux_tours_membres_a_zero():
    ecrits = [{'slotId': 'a', 'groupId': 'r', 'sets': 5}, {'slotId': 'b', 'groupId': 'r', 'sets': 5},
              {'slotId': 'c', 'groupId': 'e', 'sets': 8}, {'slotId': 'd', 'groupId': 'e', 'sets': 8},
              {'slotId': 'z', 'groupId': 'z', 'sets': 3}]
    servis = [{'slotId': 'a', 'groupId': 'r', 'sets': 5}, {'slotId': 'b', 'groupId': 'r', 'sets': 3},
              {'slotId': 'c', 'groupId': 'e', 'sets': 6}, {'slotId': 'd', 'groupId': 'e', 'sets': 6},
              {'slotId': 'z', 'groupId': 'z', 'sets': 0}]
    groupes = [{'groupId': 'r', 'format': 'rounds_for_time', 'rounds': 5, 'timeCapSeconds': 900},
               {'groupId': 'e', 'format': 'emom', 'rounds': 8, 'intervalSeconds': 120, 'durationSeconds': 960},
               {'groupId': 'z', 'format': 'circuit', 'rounds': 3}]
    assert groupes_servis(groupes, ecrits, servis) == [
        {'groupId': 'r', 'format': 'rounds_for_time', 'rounds': 3, 'timeCapSeconds': 900},   # le moins
        {'groupId': 'e', 'format': 'emom', 'rounds': 6, 'intervalSeconds': 120, 'durationSeconds': 720}]


def test_relecture_volume_semaine_sur_l_exercice_ecrit_seulement():
    """Fractionné écrit à 6 séries, modulé à 5, remplacé par une course
    facile (bilan très bas) : pas de `koach.volume_semaine` sur la course
    (sa raison est `koach.course_facile`) ; la mesure ne compte pas de baisse
    sans raison."""
    k = koach(niveau=1)
    k.observe({'type': 'seance_debut', 'jour': 0, 'bilan': {'overall': 1}, 'contexte': {}})
    items = [{'slotId': 's1', 'exerciseId': 'ca-fractionne-400m', 'kind': 'work', 'sets': 5, 'distanceMeters': 400,
              'targetFlames': 8, 'restSeconds': 90, 'koachVolume': -1, 'koachModule': -1}]
    r = k.plan({'horizon': 'seance', 'items': items, 'grilles': {}, 'zones': {}, 'roles': {}})
    codes = [x['code'] for x in r['raisons']]
    assert 'koach.course_facile' in codes and 'koach.volume_semaine' not in codes
    acc = pk.rampe_vide()
    pk.mesure_rampe(acc, items, {}, r['items'], r['raisons'], k.seances, {})
    assert (acc['module_items'], acc['module_sans_raison']) == (1, 0)


def test_relecture_modulation_garde_les_techniques_a_lignes_fixes():
    p = Planification.__new__(Planification)
    p.semaines = [{'jours': [(1, [{'slotId': 'a', 'exerciseId': SQ, 'kind': 'work', 'sets': 5,
                                   'technique': {'kind': 'pyramid', 'pyramidReps': [8, 6, 4, 6, 8]}},
                                  {'slotId': 'b', 'exerciseId': SQ, 'kind': 'work', 'sets': 4}])]}]
    p.plan = {0: {'volume': [0.15] * 10, 'intensite': 0.02}}
    p.p = {'plafond_volume': 0.15}
    p.facteur_exercice = lambda ex, mod: 1.15
    p.fiches = FICHES
    mods = Planification.items_modules(p, 0)
    assert mods[(1, 'a')] == (5, 0.02)             # pyramide : séries gardées, intensité modulée
    assert mods[(1, 'b')][0] == 5


def test_relecture_koach_volume_cumule():
    p = Planification.__new__(Planification)
    p.items_modules = lambda semaine: {(1, 'a'): (5, 0.0)}
    out = Planification.appliquer(p, 0, 1, [{'slotId': 'a', 'sets': 4, 'koachVolume': 1}])
    assert (out[0]['sets'], out[0]['koachVolume'], out[0]['koachModule']) == (5, 2, 1)   # écrit 3


def test_relecture_mesure_rampe_deguisee_sur_l_ecrit_du_programme():
    """La ligne baissée par la modulation reste « sur limite » quand l'écrit
    du PROGRAMME de la semaine dépasse la limite de la rampe."""
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    item = {'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 5,
            'targetFlames': 7, 'koachVolume': -3, 'koachModule': -3}
    servis = s.prescrire([dict(item)], {SQ: Grille(2.5, 20.0)}, {}, {'s1': 'main'})
    groupes = [g for (g, c) in s._credits(SQ)]
    s.retour_vol = {'limites': [5.0] * 14, 'plafonds': [5.0] * 14}
    ecrit = [{'slotId': 's1', 'exerciseId': SQ, 'kind': 'work', 'sets': 6, 'targetFlames': 7}]
    acc = pk.rampe_vide()
    pk.mesure_module(acc, servis, s.raisons, s, ecrit)
    assert groupes and (acc['module_lignes'], acc['module_lignes_sur_limite'], acc['module_baisses_sur_limite']) \
        == (1, 1, 1)
