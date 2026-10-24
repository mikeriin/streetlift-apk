# -*- coding: utf-8 -*-
"""Lot KM7 (Koach 1.0.9, DECISIONS_CP.md C17.54 ; CHANGEMENTS_1_0_9.md) :

1. forme du jour versée sans être appliquée (`bilan.applique: false`, mode
   Libre « Garder l'écrit », Assisté « Annuler ») : plan identique au plan
   des seuls faits du bilan, douleur toujours appliquée, état appris
   identique à celui d'un bilan appliqué, journal sans drapeau inchangé ;
2. remplaçants en séance (`Koach.remplacants`) classés et étiquetés selon la
   raison et le matériel, et remplaçant versé servi à l'emplacement avec ses
   propres cibles (`remplace`).

Le portage Dart reprend les mêmes cas et les mêmes valeurs
(`test/koach_km7_test.dart`). Données synthétiques seulement (C17.33).
"""
import copy
import gzip
import json
import os

import numpy as np

from koach.moteur import Koach, faits_du_bilan, bilan_applique, rejouer
from koach import remplacants as rp

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']
with gzip.open(os.path.join(ICI, '..', 'donnees', 'catalogue_infos.json.gz'), 'rt', encoding='utf-8') as f:
    INFOS = json.load(f)['exercises']

DL = 'sl-dips-leste'
SQ = 'mu-back-squat-barre-basse'
DIPS = 'sw-dips-barres-paralleles'
GRILLES = {DL: {'pas': 1.25, 'minimum': 0.0, 'halteres': False},
           SQ: {'pas': 2.5, 'minimum': 20.0, 'halteres': False},
           'sl-dips-barre-fixe-leste': {'pas': 1.25, 'minimum': 0.0, 'halteres': False}}
BAS = {'overall': 1, 'sleepHours': 5, 'energy': 2, 'pains': []}


def koach():
    return Koach(PARAMS, FICHES, {'niveau': 2, 'sexe': 'male', 'poids_kg': 75.0,
                                  'declares': {DL: ('one_rm_kg', 40.0), SQ: ('one_rm_kg', 140.0)},
                                  'zones_fragiles': []})


def items_j5():
    return [{'slotId': 'j5.1', 'exerciseId': DL, 'kind': 'work', 'sets': 6, 'repsLow': 3, 'repsHigh': 3,
             'targetFlames': 7, 'restSeconds': 0, 'groupId': 'g1', 'format': 'e2mom',
             'technique': {'kind': 'emom', 'intervalSeconds': 120, 'intervals': 6}},
            {'slotId': 'j5.2', 'exerciseId': SQ, 'kind': 'work', 'sets': 4, 'repsLow': 5, 'repsHigh': 5,
             'targetFlames': 7, 'restSeconds': 180}]


def seance(k, jour, bilan, items=None, series=True, faites=None):
    """Une séance : début, plan, séries faites (synthétiques, 3 flammes de
    réserve), fin. Renvoie le plan servi."""
    k.observe({'type': 'seance_debut', 'jour': jour, 'bilan': copy.deepcopy(bilan),
               'contexte': {'semaine': jour // 7, 'genre': 'accumulation'}})
    r = k.plan({'horizon': 'seance', 'items': copy.deepcopy(items or items_j5()), 'grilles': GRILLES,
                'zones': {}, 'roles': {'j5.1': 'main', 'j5.2': 'main'}})
    if series:
        for it in r['items']:
            for i in range(int(it['sets'])):
                c = k.plan({'horizon': 'serie', 'item': it, 'index': i, 'faites': []})
                if c is None:
                    break
                charge = c.get('loadKg')
                reps = c.get('repsHigh') or 5
                if faites is not None:
                    reps = faites(it, i, reps)
                k.observe({'type': 'serie', 'serie': {
                    'exerciseId': it['exerciseId'], 'slotId': it['slotId'], 'setIndex': i, 'kind': 'work',
                    'reps': reps, 'externalLoadKg': charge, 'flames': 7, 'failed': False,
                    'target': {'repsLow': c.get('repsLow'), 'repsHigh': c.get('repsHigh'), 'flames': 7},
                    'restSeconds': 120}})
    k.observe({'type': 'seance_fin', 'jour': jour, 'douleurs': None, 'seance': {'sets': []}})
    return r


def histoire(k):
    for j in (0, 2, 4, 7, 9):
        seance(k, j, {'overall': 4})


def sans_trace(items):
    return [{k: v for k, v in it.items() if k != 'trace'} for it in items]


def cibles(k, r):
    out = []
    for it in r['items']:
        out.append([k.plan({'horizon': 'serie', 'item': it, 'index': i, 'faites': []}) for i in range(it['sets'])])
    return out


# ----------------------------------------------------------------------
# 1. Forme du jour versée sans être appliquée
# ----------------------------------------------------------------------
def test_drapeau_et_faits():
    assert bilan_applique(None) and bilan_applique({'overall': 2}) and bilan_applique({'applique': True})
    assert not bilan_applique({'overall': 2, 'applique': False})
    assert faits_du_bilan(dict(BAS, applique=False, minutesAvailable=45)) == {'pains': [], 'minutesAvailable': 45}
    assert faits_du_bilan(None) is None


def _debut(k, jour, bilan):
    k.observe({'type': 'seance_debut', 'jour': jour, 'bilan': copy.deepcopy(bilan),
               'contexte': {'semaine': jour // 7, 'genre': 'accumulation'}})
    return k.plan({'horizon': 'seance', 'items': items_j5(), 'grilles': GRILLES, 'zones': {},
                   'roles': {'j5.1': 'main', 'j5.2': 'main'}})


def test_plan_non_applique_identique_au_plan_des_faits():
    """Bilan bas gardé à l'écrit : séance, séries, charges et plages
    identiques au plan des seuls faits ; le bilan appliqué sert moins."""
    base = koach()
    histoire(base)
    k_faits, k_non, k_app = copy.deepcopy(base), copy.deepcopy(base), copy.deepcopy(base)
    r_faits = _debut(k_faits, 11, faits_du_bilan(BAS))
    r_non = _debut(k_non, 11, dict(BAS, applique=False))
    r_app = _debut(k_app, 11, BAS)
    assert sans_trace(r_non['items']) == sans_trace(r_faits['items'])
    assert r_non['raisons'] == r_faits['raisons']
    assert [[{k: v for k, v in c.items() if k != 'trace'} for c in l] for l in cibles(k_non, r_non)] == \
        [[{k: v for k, v in c.items() if k != 'trace'} for c in l] for l in cibles(k_faits, r_faits)]
    # Le bilan appliqué change bien le service (sinon le test ne prouve rien).
    assert sans_trace(r_app['items']) != sans_trace(r_faits['items'])
    assert [it['sets'] for it in r_app['items']] == [5, 3]
    assert [it['sets'] for it in r_non['items']] == [6, 4]
    assert k_non.seances.palier == 0 and k_app.seances.palier == 2


def test_forme_versee_a_la_premiere_serie_etat_identique_au_bilan_applique():
    """Mêmes séries versées : l'état du modèle après la séance est celui du
    bilan appliqué (forme apprise) et diffère de celui des seuls faits."""
    base = koach()
    histoire(base)
    etats = {}
    for nom, b in (('app', BAS), ('non', dict(BAS, applique=False)), ('faits', faits_du_bilan(BAS))):
        k = copy.deepcopy(base)
        _debut(k, 11, b)
        # Avant la première série : l'effet du jour est celui des faits.
        if nom == 'non':
            assert k.modele.bilan_differe is not None
        for i in range(3):
            k.observe({'type': 'serie', 'serie': {
                'exerciseId': DL, 'slotId': 'j5.1', 'setIndex': i, 'kind': 'work', 'reps': 3,
                'externalLoadKg': 25.0, 'flames': 8, 'failed': False,
                'target': {'repsLow': 3, 'repsHigh': 3, 'flames': 7}, 'restSeconds': 120}})
        if nom == 'non':
            assert k.modele.bilan_differe is None
        etats[nom + '_seance'] = (k.modele.m.copy(), k.modele.P.copy(), k.modele.logw)
        k.observe({'type': 'seance_fin', 'jour': 11, 'douleurs': None, 'seance': {'sets': []}})
        etats[nom] = k.posterior()
    m_a, P_a, w_a = etats['app_seance']
    m_n, P_n, w_n = etats['non_seance']
    assert np.array_equal(m_a, m_n) and np.array_equal(P_a, P_n) and w_a == w_n
    assert json.dumps(etats['app'], sort_keys=True) == json.dumps(etats['non'], sort_keys=True)
    assert json.dumps(etats['faits'], sort_keys=True) != json.dumps(etats['non'], sort_keys=True)


def test_avant_la_premiere_serie_effet_du_jour_des_faits():
    base = koach()
    histoire(base)
    k_non, k_faits = copy.deepcopy(base), copy.deepcopy(base)
    _debut(k_non, 11, dict(BAS, applique=False))
    _debut(k_faits, 11, faits_du_bilan(BAS))
    assert np.array_equal(k_non.modele.m, k_faits.modele.m)
    assert np.array_equal(k_non.modele.P, k_faits.modele.P)
    assert k_non.modele.logw == k_faits.modele.logw
    assert k_non.posterior() == k_faits.posterior()


def test_douleur_pendant_garder_l_ecrit_toujours_appliquee():
    """Douleur signalée au bilan, écrit gardé : la conduite sous douleur
    s'applique (même plan que le bilan des faits, douleur comprise), jamais
    celui d'un bilan sans douleur."""
    base = koach()
    histoire(base)
    douleur = dict(BAS, pains=[{'zone': 'elbow', 'intensity': 4}])
    zones = {DL: [{'elbow': 1.0, 'shoulder': 0.5}, ['elbow']], SQ: [{'knee': 1.0}, []]}
    sorties = {}
    for nom, b in (('non', dict(douleur, applique=False)), ('faits', faits_du_bilan(douleur)),
                   ('sans', faits_du_bilan(BAS))):
        k = copy.deepcopy(base)
        k.observe({'type': 'seance_debut', 'jour': 11, 'bilan': copy.deepcopy(b),
                   'contexte': {'semaine': 1, 'genre': 'accumulation'}})
        sorties[nom] = k.plan({'horizon': 'seance', 'items': items_j5(), 'grilles': GRILLES, 'zones': zones,
                               'roles': {'j5.1': 'main', 'j5.2': 'main'}})
    assert sans_trace(sorties['non']['items']) == sans_trace(sorties['faits']['items'])
    assert sorties['non']['raisons'] == sorties['faits']['raisons']
    assert sans_trace(sorties['non']['items']) != sans_trace(sorties['sans']['items'])
    assert any(r['code'].startswith('koach.douleur') for r in sorties['non']['raisons'])


def test_journal_sans_drapeau_inchange_et_rejeu():
    """Un journal sans drapeau = bilan appliqué (comme 1.0.8) ; `applique:
    true` explicite donne la même chose ; le rejeu du journal d'une séance
    non appliquée redonne l'état exact."""
    base = koach()
    histoire(base)
    k1, k2 = copy.deepcopy(base), copy.deepcopy(base)
    r1 = _debut(k1, 11, BAS)
    r2 = _debut(k2, 11, dict(BAS, applique=True))
    assert sans_trace(r1['items']) == sans_trace(r2['items'])
    k = koach()
    histoire(k)
    seance(k, 11, dict(BAS, applique=False))
    seance(k, 14, {'overall': 4})
    k2 = rejouer(PARAMS, FICHES, k.profil, k.journal)
    assert json.dumps(k.posterior(), sort_keys=True) == json.dumps(k2.posterior(), sort_keys=True)


def test_bilan_bas_garde_puis_seance_suivante():
    """Bilan bas gardé à l'écrit, séance faite plus faible que prévu, puis
    séance suivante : la version qui a versé la forme attribue la baisse au
    jour (capacité moins baissée) ; celle des seuls faits la croit durable."""
    def faites(it, i, reps):
        return max(1, reps - 1) if it['exerciseId'] == DL else reps
    sortie = {}
    for nom, b in (('non', dict(BAS, applique=False)), ('faits', faits_du_bilan(BAS))):
        k = koach()
        histoire(k)
        seance(k, 11, b, faites=faites)
        sortie[nom] = (k.posterior()['exercices'][DL]['ln_capacite'], seance(k, 14, {'overall': 4}, series=False))
    assert sortie['non'][0] > sortie['faits'][0]
    assert sortie['non'][1]['items'][0]['sets'] == sortie['faits'][1]['items'][0]['sets']


# ----------------------------------------------------------------------
# 2. Remplaçants en séance
# ----------------------------------------------------------------------
def _demande(**kw):
    d = {'exerciseId': DL, 'item': items_j5()[0], 'role': 'main',
         'raison': {'code': 'pas_de_materiel', 'materiel': ['ceinture de lest']}, 'niveau': 2}
    d.update(kw)
    return d


def ids(r, etiquette=None):
    return [x['exerciseId'] for x in r['remplacants'] if etiquette is None or x['etiquette'] == etiquette]


def test_dip_leste_sans_ceinture():
    k = koach()
    histoire(k)
    r = k.remplacants(INFOS, _demande())
    assert r['raison'] == 'pas_de_materiel' and r['regles'] == {'autre_permis': False, 'zone': None}
    assert set(x['etiquette'] for x in r['remplacants']) == {'sans_materiel'}
    assert ids(r) == ['cd-dips-russes', DIPS, 'cd-dips-explosifs', 'sw-dips-prise-inversee', 'sw-dips-negatifs']
    # Aucun exercice ne demande la ceinture, aucun n'est une poussée haute.
    par = {i['id']: i for i in INFOS}
    for x in r['remplacants']:
        assert 'ceinture de lest' not in par[x['exerciseId']]['equipment']
        assert par[x['exerciseId']]['pattern'] != 'pousseeVerticaleHaute'
        assert x['unite'] == 'reps' and x['depart']['source'] == 'a_priori'
    d = r['remplacants'][1]
    assert d['texte'] == ('Au poids du corps, sans ceinture de lest : tempo lent ou pause en bas pour garder '
                          'l’effort.')
    assert (d['depart']['repsLow'], d['depart']['repsHigh']) == (16, 20)
    assert r['remplacants'][2]['texte'] == 'Version explosive du mouvement, sans ceinture de lest.'


def test_dip_leste_avec_anneaux_et_role_accessoire():
    k = koach()
    histoire(k)
    r = k.remplacants(INFOS, _demande(materiel=['barres parallèles', 'disques', 'anneaux']))
    assert 'cd-dips-bulgares-anneaux' in ids(r)
    r0 = k.remplacants(INFOS, _demande())
    assert not any('anneaux' in x for x in ids(r0))
    # Rôle accessoire : un autre schéma de poussée est permis, en « autre » ;
    # le HSPU au mur n'est jamais « équivalent ».
    ra = k.remplacants(INFOS, _demande(role='accessory', par_etiquette=40, limite=200))
    assert ra['regles']['autre_permis'] is True
    lab = {x['exerciseId']: x['etiquette'] for x in ra['remplacants']}
    assert lab.get('cd-hspu-mur-dos') == 'autre'
    rm = k.remplacants(INFOS, _demande(par_etiquette=40, limite=200))
    assert 'cd-hspu-mur-dos' not in ids(rm)
    assert set(x['etiquette'] for x in rm['remplacants']) <= {'equivalent', 'plus_facile', 'sans_materiel'}


def test_douleur_jamais_la_zone_signalee():
    k = koach()
    histoire(k)
    for zone in ('shoulder', 'elbow', 'wrist_hand', 'knee'):
        r = k.remplacants(INFOS, _demande(raison={'code': 'douleur', 'zone': zone}, role='accessory',
                                          par_etiquette=40, limite=200))
        par = {i['id']: i for i in INFOS}
        for x in r['remplacants']:
            i = par[x['exerciseId']]
            assert i['zoneLevels'].get(zone, 0.0) == 0.0 and zone not in i['painStopHits']
    # Squat, douleur au genou : rien qui charge le genou.
    r = k.remplacants(INFOS, {'exerciseId': SQ, 'item': items_j5()[1], 'role': 'accessory',
                              'raison': {'code': 'douleur', 'zone': 'knee'}, 'niveau': 2, 'limite': 200,
                              'par_etiquette': 40})
    for x in r['remplacants']:
        assert {i['id']: i for i in INFOS}[x['exerciseId']]['zoneLevels'].get('knee', 0.0) == 0.0


def test_trop_dur_jamais_plus_difficile():
    k = koach()
    histoire(k)
    r = k.remplacants(INFOS, _demande(raison={'code': 'trop_dur'}, par_etiquette=40, limite=200))
    par = {i['id']: i for i in INFOS}
    assert r['remplacants'] and r['remplacants'][0]['etiquette'] == 'plus_facile'
    for x in r['remplacants']:
        assert par[x['exerciseId']]['difficulty'] <= par[DL]['difficulty']


def test_cibles_de_depart_historique_transfert_a_priori():
    k = koach()
    histoire(k)
    item = items_j5()[0]
    # Historique : l'exercice lui-même a des mesures.
    d = rp.depart(k, SQ, 'charge', DL, 'charge_ajoutee', item, rp.Grille(1.25, 0.0))
    assert d['source'] == 'historique' and d['loadKg'] is not None and (d['repsLow'], d['repsHigh']) == (3, 3)
    # Transfert : dips à la barre fixe lesté depuis le dip lesté (× 0,9 du total).
    d = rp.depart(k, DL, 'charge_ajoutee', 'sl-dips-barre-fixe-leste', 'charge_ajoutee', item,
                  rp.Grille(1.25, 0.0))
    assert d['source'] == 'transfert'
    total = (k.seances.charge_pour(DL, 3, 2.0, PARAMS['planification']['prudence_charge'][0]) + 0.96 * 75.0) * 0.9
    assert d['loadKg'] == rp.Grille(1.25, 0.0).plancher(total - 0.96 * 75.0)
    assert rp.transfert(DL, 'sl-dips-barre-fixe-leste') == 0.9
    assert rp.transfert('sl-dips-barre-fixe-leste', DL) == 1.0
    assert rp.transfert(DL, SQ) is None
    # Sans Koach : la plage écrite de même unité, aucune source.
    d = rp.depart(None, DL, 'charge_ajoutee', 'sl-dips-leste-anneaux', 'charge_ajoutee', item)
    assert d['source'] is None and (d['repsLow'], d['repsHigh']) == (3, 3)


def test_remplacant_verse_servi_a_l_emplacement_avec_ses_cibles():
    """J5 sans ceinture : dips aux barres à la place du dip lesté, servi dans
    le groupe E2MOM (format, technique, séries gardés), plage au poids du
    corps de Koach ; séries versées sous l'exercice réel."""
    k = koach()
    histoire(k)
    k.observe({'type': 'seance_debut', 'jour': 11, 'bilan': None, 'contexte': {'semaine': 1, 'genre': 'accumulation'}})
    items = items_j5()
    items[0] = dict(items[0], exerciseId=DIPS, remplace={'exerciseId': DL, 'raison': 'pas_de_materiel'})
    r = k.plan({'horizon': 'seance', 'items': items, 'grilles': GRILLES, 'zones': {},
                'roles': {'j5.1': 'main', 'j5.2': 'main'},
                'groups': [{'groupId': 'g1', 'format': 'e2mom', 'rounds': 6, 'intervalSeconds': 120}]})
    it = r['items'][0]
    assert it['exerciseId'] == DIPS and it['remplace'] == {'exerciseId': DL, 'raison': 'pas_de_materiel'}
    assert (it['groupId'], it['format'], it['sets']) == ('g1', 'e2mom', 6)
    assert it['technique'] == {'kind': 'emom', 'intervalSeconds': 120, 'intervals': 6}
    assert (it['repsLow'], it['repsHigh']) == (16, 20)
    assert r['groups'] == [{'groupId': 'g1', 'format': 'e2mom', 'rounds': 6, 'intervalSeconds': 120}]
    assert {'code': 'koach.remplacement', 'params': {'exercice': DIPS, 'de': DL, 'cause': 'pas_de_materiel'}} \
        in r['raisons']
    c = k.plan({'horizon': 'serie', 'item': it, 'index': 0, 'faites': []})
    assert (c['repsLow'], c['repsHigh'], c['loadKg']) == (16, 20, None)
    avant = k.posterior()['exercices'][DL]
    k.observe({'type': 'serie', 'serie': {'exerciseId': DIPS, 'slotId': 'j5.1', 'setIndex': 0, 'kind': 'work',
                                          'reps': 18, 'externalLoadKg': None, 'flames': 7, 'failed': False,
                                          'target': {'repsLow': 16, 'repsHigh': 20, 'flames': 7},
                                          'restSeconds': 120}})
    post = k.posterior()['exercices']
    # Série versée au nom de l'exercice réel : mesure des dips, aucune au dip lesté.
    assert post[DIPS]['mesures'] == 1
    assert (post[DL]['mesures'], post[DL]['seances']) == (avant['mesures'], avant['seances'])
    assert k.seances.mem(DIPS).reps_seance == 18 and k.seances.mem(DL).reps_seance is None


def test_remplacant_par_transfert_charge_de_depart():
    """Dip lesté remplacé par le dip à la barre fixe lesté (jamais fait) :
    charge de départ transférée (× 0,9 du total, arrondi vers le bas)."""
    k = koach()
    histoire(k)
    k.observe({'type': 'seance_debut', 'jour': 11, 'bilan': None, 'contexte': {'semaine': 1, 'genre': 'accumulation'}})
    items = items_j5()
    items[0] = dict(items[0], exerciseId='sl-dips-barre-fixe-leste', remplace={'exerciseId': DL, 'raison': 'autre'})
    r = k.plan({'horizon': 'seance', 'items': items, 'grilles': GRILLES, 'zones': {},
                'roles': {'j5.1': 'main', 'j5.2': 'main'}})
    it = r['items'][0]
    attendu = rp.depart(k, DL, 'charge_ajoutee', 'sl-dips-barre-fixe-leste', 'charge_ajoutee', items_j5()[0],
                        rp.Grille(1.25, 0.0))
    c = k.plan({'horizon': 'serie', 'item': it, 'index': 0, 'faites': []})
    assert attendu['source'] == 'transfert'
    assert c['loadKg'] == attendu['loadKg'] and (c['repsLow'], c['repsHigh']) == (3, 3)


def test_sans_remplacement_rien_ne_change():
    """Une séance sans `remplace` est servie comme en 1.0.8 (aucune clé ni
    raison nouvelle)."""
    k = koach()
    histoire(k)
    r = _debut(k, 11, None)
    assert all('remplace' not in it and 'koachDepartKg' not in it for it in r['items'])
    assert not any(x['code'] == 'koach.remplacement' for x in r['raisons'])


def test_remplacants_lecture_seule():
    """L'aperçu ouvre des pistes pour les cibles de départ, puis les referme :
    état, posterior et journal inchangés (l'état reste recalculable)."""
    k = koach()
    histoire(k)
    avant = (k.modele.m.copy(), k.modele.P.copy(), k.modele.n, list(k.modele.ordre), len(k.journal),
             json.dumps(k.posterior(), sort_keys=True))
    r = k.remplacants(INFOS, _demande(role='accessory'))
    assert r['remplacants']
    assert np.array_equal(avant[0], k.modele.m) and np.array_equal(avant[1], k.modele.P)
    assert (avant[2], avant[3], avant[4]) == (k.modele.n, list(k.modele.ordre), len(k.journal))
    assert avant[5] == json.dumps(k.posterior(), sort_keys=True)
