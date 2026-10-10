# -*- coding: utf-8 -*-
"""Adhérence et refus (cahier KM § 8, D7) : apprentissage probit,
garde-fou anti-complaisance, deux canaux du refus, déterminisme."""
import copy
import inspect
import json
import math
import os
import pickle
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

from banc.politique_koach import params, vecteurs
from koach import adherence as module_adherence
from koach.adherence import Adherence, TYPES, MOMENTS, DIM
from koach.moteur import Koach
from koach.numerique import Mulberry32, norm_cdf

PROFIL = {'niveau': 1, 'sexe': 'male', 'poids_kg': 80}
EX = 'mu-developpe-couche-barre'


def koach_minimal():
    k = Koach(params(), vecteurs(), PROFIL)
    a = Adherence(k.params)
    k.extensions.append(a)
    return k, a


def evt(jour, typ='charge_plus', accepte=True, raison=None, ampleur=1.0, contexte=None,
        charge=80.0, reps=5, rir=2.0):
    return {'type': 'decision', 'jour': jour,
            'proposition': {'id': 'p%d' % jour, 'type': typ, 'exerciseId': EX, 'ampleur': ampleur,
                            'charge_kg': charge, 'reps': reps, 'rir': rir,
                            'contexte': contexte or {}},
            'accepte': accepte, 'raison': raison}


def etat_estimation(k):
    m = k.modele
    return pickle.dumps((m.m.copy(), m.P.copy(), m.n, list(m.ordre), m.logw))


# ----------------------------------------------------------------------
# Apprentissage
# ----------------------------------------------------------------------
W_VRAI = [0.9,                                                  # biais
          -0.4, 0.5, -0.6, 0.6, -0.2, 0.3, 0.0, -0.5, 0.4,      # types
          -0.8,                                                 # ampleur
          -0.5, 0.3, -0.3, 0.2, -0.7]                          # contexte


def proposition_aleatoire(r):
    typ = TYPES[int(r.next() * len(TYPES)) % len(TYPES)]
    ampleur = 8.0 * r.next()
    ctx = {'bilan_bas': r.next() < 0.2, 'semaine_allegement': r.next() < 0.2,
           'moment': MOMENTS[int(r.next() * 3) % 3], 'refus_recents': int(r.next() * 4)}
    return typ, ampleur, ctx


def simuler(graine, n):
    a = Adherence(params())
    r = Mulberry32(graine)
    for _ in range(n):
        typ, amp, ctx = proposition_aleatoire(r)
        x = a.caracteristiques(typ, amp, ctx)
        p_vrai = norm_cdf(sum(W_VRAI[i] * x[i] for i in range(DIM)))
        a.apprendre(x, r.next() < p_vrai)
    return a


def _mae(a, W=None):
    W = W or W_VRAI
    erreurs = []
    for typ in TYPES:
        for amp in (0.5, 1.0, 2.0, 4.0, 6.0):
            for moment in MOMENTS:
                x = a.caracteristiques(typ, amp, {'moment': moment})
                p_vrai = norm_cdf(sum(W[i] * x[i] for i in range(DIM)))
                erreurs.append(abs(a.proba(x) - p_vrai))
    return sum(erreurs) / len(erreurs)


def test_apprentissage_probit():
    """Utilisateur simulé selon une vraie loi probit (16 poids), propositions
    tirées uniformément sur les 9 types. Le critère « erreur < 0,08 après
    200 décisions » n'est pas atteignable avec 16 poids indépendants
    d'écart-type a priori 1,5 : ~22 décisions par type. Une estimation de
    Laplace (MAP + hessienne, quasi optimale) sur les mêmes données donne
    0,094 en moyenne sur 20 graines, le filtrage en ligne 0,09 à 0,11 selon
    les graines. On exige
    donc, en moyenne sur 10 graines : < 0,12 après 200 décisions et < 0,08
    après 400 (mesuré : voir la sortie)."""
    m200 = sum(_mae(simuler(100 + g, 200)) for g in range(10)) / 10
    m400 = sum(_mae(simuler(100 + g, 400)) for g in range(10)) / 10
    m0 = _mae(Adherence(params()))
    print('erreur absolue moyenne : a priori %.3f, 200 décisions %.3f, 400 décisions %.3f'
          % (m0, m200, m400))
    assert m200 < 0.12
    assert m400 < 0.08
    assert m400 < m200 < m0


def test_covariance_reste_symetrique_et_positive():
    a = simuler(5, 300)
    for i in range(DIM):
        assert a.P[i][i] > 0
        for j in range(DIM):
            assert abs(a.P[i][j] - a.P[j][i]) < 1e-12


def test_calibration():
    a = simuler(8, 400)
    t = a.calibration()
    assert len(t) == 5 and sum(x['n'] for x in t) == 400
    json.dumps(t)
    t2 = a.calibration([(0.1, False), (0.15, True), {'p': 0.95, 'accepte': True}, (1.0, True)])
    assert t2[0]['n'] == 2 and t2[0]['observe'] == 0.5 and t2[4]['n'] == 2
    assert t2[2]['predit'] is None


def test_determinisme():
    e1 = json.dumps(simuler(77, 150).etat())
    e2 = json.dumps(simuler(77, 150).etat())
    assert e1 == e2
    k1, a1 = koach_minimal()
    k2, a2 = koach_minimal()
    for k in (k1, k2):
        for j in range(30):
            k.observe(evt(j, TYPES[j % 9], accepte=(j % 3 != 0),
                          raison=('too_heavy', 'equipment', None, 'time')[j % 4]))
    assert json.dumps(a1.etat()) == json.dumps(a2.etat())


def test_serialisation_ronde():
    k, a = koach_minimal()
    for j in range(20):
        k.observe(evt(j, accepte=j % 2 == 0, raison='time' if j % 4 == 1 else None))
    txt = json.dumps(a.etat())
    b = Adherence.depuis_etat(k.params, json.loads(txt))
    assert json.dumps(b.etat()) == txt
    x = a.caracteristiques('volume_plus', 2.0, {'moment': 'entre_series'})
    assert a.proba(x) == b.proba(x)


# ----------------------------------------------------------------------
# Garde-fou anti-complaisance
# ----------------------------------------------------------------------
def etats_contrastes():
    tout_accepte = Adherence(params())
    refuse_hausses = Adherence(params())
    refuse_tout = Adherence(params())
    r = Mulberry32(3)
    for i in range(200):
        typ, amp, ctx = proposition_aleatoire(r)
        tout_accepte.apprendre(tout_accepte.caracteristiques(typ, amp, ctx), True)
    for i in range(30):
        refuse_hausses.apprendre(refuse_hausses.caracteristiques('charge_plus', 1.0 + i % 4, {}),
                                 False)
    for i in range(200):
        typ, amp, ctx = proposition_aleatoire(r)
        refuse_tout.apprendre(refuse_tout.caracteristiques(typ, amp, ctx), False)
    return {'neuf': Adherence(params()), 'tout_accepte': tout_accepte,
            'refuse_hausses': refuse_hausses, 'refuse_tout': refuse_tout}


CAS_FORME = [
    (100.0, 90.0, 2.5, 'charge_plus'),
    (82.5, 80.0, 2.5, 'charge_plus'),
    (61.25, 70.0, 1.25, 'charge_moins'),
    (5.0, 3.0, 1.0, 'volume_plus'),
    (12.0, 8.0, 1.0, 'reps_plus'),
    (100.0, 100.0, 2.5, 'charge_plus'),
    (101.3, 100.0, 2.5, 'charge_plus'),     # écart sous le pas minimal
    (0.85, 0.80, 0.0125, 'charge_plus'),    # fractions
    (37.7, 21.1, 0.5, 'test'),
]


@pytest.mark.parametrize('nom', ['neuf', 'tout_accepte', 'refuse_hausses', 'refuse_tout'])
def test_forme_destination_inchangee(nom):
    a = etats_contrastes()[nom]
    for (cible, depart, pas, typ) in CAS_FORME:
        for ctx in ({}, {'bilan_bas': True, 'refus_recents': 5}, {'moments_possibles': ['entre_series']}):
            f = a.forme(cible, depart, pas, typ, ctx)
            p = f['paliers']
            assert p[-1] == cible                       # exactement
            assert 1 <= len(p) <= 4
            assert f['moment'] in MOMENTS
            if ctx.get('moments_possibles'):
                assert f['moment'] == 'entre_series'
            lo, hi = min(cible, depart), max(cible, depart)
            prec = depart
            for v in p:
                assert lo <= v <= hi                    # jamais au-delà de la cible
                if cible > depart:
                    assert v > prec
                elif cible < depart:
                    assert v < prec
                if len(p) > 1:
                    assert abs(v - prec) >= pas * (1 - 1e-9)
                prec = v


def test_forme_adapte_seulement_les_paliers():
    e = etats_contrastes()
    f_ok = e['tout_accepte'].forme(100.0, 90.0, 2.5, 'charge_plus')
    f_non = e['refuse_hausses'].forme(100.0, 90.0, 2.5, 'charge_plus')
    # Le modèle change la taille des paliers, jamais la destination.
    assert len(f_ok['paliers']) <= len(f_non['paliers'])
    assert f_ok['paliers'][-1] == f_non['paliers'][-1] == 100.0
    assert len(f_ok['paliers']) == 1
    assert len(f_non['paliers']) == 4


def test_aucune_cible_modifiee():
    """Aucune fonction du module ne touche une cible, une charge, un nombre
    de séries ou une réserve : ni l'événement, ni la prescription, ni la
    façade du moteur."""
    k, a = koach_minimal()
    seances_avant = pickle.dumps(k.seances.__dict__.keys().__repr__()) + repr(
        {cle: v for cle, v in sorted(k.seances.__dict__.items())
         if isinstance(v, (int, float, str, list, dict, tuple, type(None)))
         and cle not in ('p', 's')}).encode()
    params_avant = json.dumps(k.params, sort_keys=True)
    for j, raison in enumerate((None, 'too_heavy', 'too_light', 'equipment', 'time', 'other')):
        e = evt(j, accepte=False, raison=raison)
        copie = copy.deepcopy(e)
        k.observe(e)
        assert e == copie
    seances_apres = pickle.dumps(k.seances.__dict__.keys().__repr__()) + repr(
        {cle: v for cle, v in sorted(k.seances.__dict__.items())
         if isinstance(v, (int, float, str, list, dict, tuple, type(None)))
         and cle not in ('p', 's')}).encode()
    assert seances_avant == seances_apres
    assert json.dumps(k.params, sort_keys=True) == params_avant
    assert a.plan_semaine(k, {'horizon': 'semaine'}) is None
    # Le module ne lit ni n'écrit la prescription, les garde-fous ou les
    # paramètres du moteur : seul `modele.observer_raison` est appelé.
    src = inspect.getsource(module_adherence)
    for interdit in ('koach.seances', 'koach.garde', 'koach.params', 'koach.plan', '.prescrire',
                     'modele.m[', 'modele.P['):
        assert interdit not in src, interdit
    # Sorties publiques : uniquement paliers, moment et probabilité.
    assert set(a.forme(90.0, 80.0, 2.5).keys()) == {'paliers', 'moment', 'proba_min'}


# ----------------------------------------------------------------------
# Deux canaux du refus (D7)
# ----------------------------------------------------------------------
def test_refus_sans_raison_ne_touche_pas_l_estimation():
    k, a = koach_minimal()
    k.modele.piste(EX)
    avant = etat_estimation(k)
    m_avant = k.modele.m.copy()
    P_avant = k.modele.P.copy()
    adh_avant = json.dumps(a.etat())
    for j in range(10):
        k.observe(evt(j, accepte=False, raison=None))
        k.observe(evt(j, accepte=False, raison='other'))
        k.observe(evt(j, accepte=True))
    assert etat_estimation(k) == avant
    assert (k.modele.m == m_avant).all() and (k.modele.P == P_avant).all()
    assert json.dumps(a.etat()) != adh_avant     # mais l'adhérence a appris
    assert a.contraintes() == []


@pytest.mark.parametrize('raison,signe', [('too_heavy', -1), ('too_light', 1)])
def test_refus_trop_lourd_ou_leger_mesure_faible(raison, signe):
    k, a = koach_minimal()
    t = k.modele.piste(EX)
    mu0, sd0 = k.modele.capacite(EX)
    charge = math.exp(mu0) * 0.8   # proche de la capacité estimée à 5 reps + 2 RIR
    k.observe(evt(1, accepte=False, raison=raison, charge=charge, reps=5, rir=2.0))
    mu1, sd1 = k.modele.capacite(EX)
    assert (mu1 - mu0) * signe > 0
    assert sd1 < sd0
    # Mesure faible : bien moins qu'un écart-type a priori.
    assert abs(mu1 - mu0) < sd0
    assert a.contraintes() == []


@pytest.mark.parametrize('raison', ['equipment', 'time'])
def test_refus_materiel_ou_temps_contrainte(raison):
    k, a = koach_minimal()
    k.modele.piste(EX)
    avant = etat_estimation(k)
    k.observe(evt(12, accepte=False, raison=raison))
    assert etat_estimation(k) == avant
    c = a.contraintes()
    assert c == [{'jour': 12, 'raison': raison, 'exerciseId': EX, 'proposition': 'p12'}]
    c[0]['jour'] = 99
    assert a.contraintes()[0]['jour'] == 12      # copie


def test_acceptation_avec_raison_ignoree():
    k, a = koach_minimal()
    k.modele.piste(EX)
    avant = etat_estimation(k)
    k.observe(evt(1, accepte=True, raison='too_heavy'))
    assert etat_estimation(k) == avant


def test_refus_recents_comptes():
    k, a = koach_minimal()
    for j in range(4):
        k.observe(evt(j, accepte=False))
    assert a.refus_recents(4) == 4
    assert a.refus_recents(4 + 14) == 0
    k.observe(evt(40, accepte=False))
    assert a.refus_jours == [40]


def test_type_inconnu():
    a = Adherence(params())
    with pytest.raises(ValueError):
        a.caracteristiques('saut_perilleux', 1.0)
