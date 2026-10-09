# -*- coding: utf-8 -*-
"""Briques 6 et 7 de Koach 1.0 conduites par le banc Python (vrai `Koach`,
vraies saisons) : hors modèle (alerte, diagnostic, semaine allégée),
fausses alertes BOCPD sur la référence, déterminisme, état recalculé depuis
le journal, interruption d'un essai N-of-1 par une alerte, garde-fou
anti-complaisance de l'adhérence. Mesures complètes :
`python3 -m banc.validation_koach` (donnees/validation_briques_6_7.json)."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import donnees, meneur
from banc import extensions_koach as ek
from banc import validation_koach as vk
from banc.politique_koach import params, vecteurs
from koach.adherence import Adherence
from koach.dual import ControleDual, EssaiN1
from koach.moteur import Koach
from koach.numerique import Mulberry32
from koach.rupture import Surveillance

# Seuil d'alerte BOCPD retenu (voir donnees/validation_briques_6_7.json).
SEUIL_RETENU = 0.6


def _saison(cle, scenario):
    return vk.saison(cle, scenario)


def _conduire(cle, scenario, kind, graine, briques=('surveillance', 'dual', 'adherence')):
    s = _saison(cle, scenario)
    pol = ek.politique(graine, briques=briques, parametres=vk.params_seuil(SEUIL_RETENU))
    tour = meneur.simuler(s, vk.infos(), pol, kind, graine)
    return s, pol, tour


def _series_travail(items):
    return sum(int(it.get('sets') or 0) for it in items if it.get('kind', 'work') == 'work')


# ----------------------------------------------------------------------
# Hors modèle : maladie -> alerte -> « fatigue » -> semaine allégée
# ----------------------------------------------------------------------
def test_maladie_alerte_et_semaine_allegee():
    # Saison où la détection de rupture (BOCPD) se lève pendant la maladie
    # (le seuil de secours « résidu d'e1RM > 5 % deux semaines de suite » ne
    # se lève pas pour une maladie d'une semaine : mesuré, voir LIVRAISON).
    s, pol, tour = _conduire('autres_02_hypertrophie_intermediaire', 'maladie', 'a', 1,
                             briques=('surveillance',))
    j = ek.journaux(pol)['SurveillanceBanc']
    diag = [e for e in j if e['type'] == 'diagnostic']
    assert any(e['type'] == 'alerte' for e in j)
    fatigue = [e for e in diag if e['action'] == 'semaine_allegee']
    assert fatigue, diag
    for e in diag:
        assert 1 <= e['questions'] <= 3
    debut = fatigue[0]['jour']
    # La réponse vient de la vérité du scénario : maladie (+ 14 jours).
    v = ek.VeriteScenario(s)
    assert v.maladie[0] <= debut < v.maladie[1] + v.APRES_MALADIE_J
    # Séries servies pendant les 7 jours : bien sous les séries écrites.
    ecrites = 0
    servies = 0
    for (g, bi, wb, di, items) in tour.servi:
        jour = None
        for (g2, bi2, wb2, di2, d) in s['sessions']:
            if (g2, bi2, wb2, di2) == (g, bi, wb, di):
                jour = d
        if jour is None or not (debut <= jour < debut + 7):
            continue
        sem = [w for w in s['blocks'][bi]['pass2']['weeks'] if w['weekIndex'] == wb][0]
        ecrit = [d for d in sem['days'] if d['dayIndex'] == di][0]['items']
        ecrites += _series_travail(ecrit)
        servies += _series_travail(items)
    assert ecrites > 0
    assert servies <= 0.75 * ecrites, (servies, ecrites)
    allege = [e for e in j if e['type'] == 'allegement']
    assert allege and all(e['series_allegees'] < e['series_ecrites'] for e in allege)


# ----------------------------------------------------------------------
# Fausses alertes BOCPD sur la référence
# ----------------------------------------------------------------------
# Mesuré (`banc.validation_koach`, 2 graines x 27 profils x 3 modèles = 162
# saisons `reference`, 9 215 séances, BOCPD passive) : 1,67 % des séances
# au-dessus de 0,6 (0,77 passage au-dessus pour 100 séances) ; pire saison
# 25 % ; sur les 9 saisons de ce test : 5 séances sur ~600 (0,8 %). X = 3 %
# (marge pour les changements du modèle en cours).
X_POURCENT = 3.0


def test_reference_peu_de_seances_en_alerte_bocpd():
    n = 0
    hautes = 0
    for cle in ('street_06_inter_sets_reps', 'street_07_avance_streetlifting_competition',
                'autres_02_hypertrophie_intermediaire'):
        for kind in 'abc':
            c = vk.collecter(cle, 'reference', kind, 0)
            tr = vk._traces_p(c['seances'], vk.params_seuil(SEUIL_RETENU))
            n += len(tr)
            hautes += sum(1 for p in tr if p > SEUIL_RETENU)
    assert n > 300
    assert 100.0 * hautes / n <= X_POURCENT, (hautes, n)


# ----------------------------------------------------------------------
# Déterminisme et état recalculé depuis le journal
# ----------------------------------------------------------------------
def test_determinisme_journaux_d_extension():
    _, p1, t1 = _conduire('street_07_avance_streetlifting_competition', 'douleur_coude', 'a', 0)
    _, p2, t2 = _conduire('street_07_avance_streetlifting_competition', 'douleur_coude', 'a', 0)
    j1 = json.dumps(ek.journaux(p1), sort_keys=True)
    assert j1 == json.dumps(ek.journaux(p2), sort_keys=True)
    assert json.dumps(ek.etats(p1), sort_keys=True) == json.dumps(ek.etats(p2), sort_keys=True)
    assert json.dumps(t1.servi, sort_keys=True) == json.dumps(t2.servi, sort_keys=True)
    # Les trois briques ont agi.
    j = ek.journaux(p1)
    assert j['SurveillanceBanc'] and j['AdherenceBanc'] and j['ControleDualBanc']


def test_etat_recalcule_depuis_le_journal():
    s, pol, _ = _conduire('street_06_inter_sets_reps', 'maladie', 'b', 1)
    vivant = ek.etats(pol)
    rejoue = ek.rejouer_etats(pol, s)
    assert set(vivant) == {'Surveillance', 'ControleDual', 'Adherence'}
    for cle in vivant:
        assert json.dumps(vivant[cle], sort_keys=True) == json.dumps(rejoue[cle], sort_keys=True), cle
    # Aller-retour par l'état exporté (JSON).
    prm = pol.parametres
    e = json.loads(json.dumps(vivant['Surveillance']))
    assert json.dumps(Surveillance.depuis_etat(prm, e).etat_complet(), sort_keys=True) == \
        json.dumps(vivant['Surveillance'], sort_keys=True)
    e = json.loads(json.dumps(vivant['Adherence']))
    assert json.dumps(Adherence.depuis_etat(prm, e).etat(), sort_keys=True) == \
        json.dumps(vivant['Adherence'], sort_keys=True)
    e = json.loads(json.dumps(vivant['ControleDual']))
    assert json.dumps(ControleDual.depuis_etat(prm, e).etat(), sort_keys=True) == \
        json.dumps(vivant['ControleDual'], sort_keys=True)
    # Les poids des hypothèses du modèle sont ceux du contrôle dual.
    cd = [x for x in pol.koach.extensions if isinstance(x, ControleDual)][0]
    assert pol.koach.modele.poids_hyp == cd.reponse.poids


# ----------------------------------------------------------------------
# Branche Surveillance -> ControleDual sur un vrai moteur
# ----------------------------------------------------------------------
def test_alerte_interrompt_l_essai_en_cours():
    k = Koach(params(), vecteurs(), {'niveau': 1, 'sexe': 'male', 'poids_kg': 80})
    s = Surveillance(k.params)
    cd = ControleDual(k.params, [])
    k.extensions += [s, cd]
    es = EssaiN1(k.params, {'exerciseId': 'mu-developpe-couche-barre'})
    es.plan(Mulberry32(1), 4)
    es.demarrer(0)
    cd.essai = es
    assert cd.modulation(1).get('bras') in ('A', 'B')
    r = Mulberry32(11)
    for j in range(60):
        s.fin_seance(k, (j, r.gauss(), 0.0, 4, 0.0), {})
    assert cd.essai is not None
    for j in range(60, 70):
        s.fin_seance(k, (j, r.gauss() + 3.0, 0.0, 4, 0.0), {})
    assert s.etat()['hors_modele']
    assert cd.essai is None
    assert cd.essais_passes[-1]['essai']['statut'] == 'interrompu'
    assert cd.essais_passes[-1]['essai']['raison_fin'] == 'alerte_hors_modele'
    assert cd.modulation(1) == {'volume': 1.0, 'intensite': 1.0}


# ----------------------------------------------------------------------
# Adhérence : garde-fou anti-complaisance en conditions de banc
# ----------------------------------------------------------------------
def test_anti_complaisance_sur_le_banc():
    r = vk.anti_complaisance('street_07_avance_streetlifting_competition', 'reference', 'a', 0)
    assert r['decisions'] > 20 and r['refus'] > 0
    # Cibles et difficulté globale identiques avec et sans adhérence.
    assert r['servis_identiques'] and r['series_identiques'], r
    # Seule la forme change : le dernier palier vaut toujours la cible.
    _, pol, _ = _conduire('street_07_avance_streetlifting_competition', 'reference', 'a', 0,
                          briques=('adherence',))
    j = ek.journaux(pol)['AdherenceBanc']
    formes = set()
    for e in j:
        if e['cible'] is not None:
            assert e['paliers'][-1] == e['cible']
            formes.add((len(e['paliers']), e['moment']))
    assert len(formes) > 1
