# -*- coding: utf-8 -*-
"""Tests du contrôle dual (cahier KM § 7) : a posteriori des hypothèses de
réponse et Thompson sampling, contrôle synthétique, essai N-of-1,
orchestration et déterminisme. Données synthétiques, graines fixes."""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

from koach import dual
from koach.dual import (ControleDual, EssaiN1, Reponse, calibre, controle_synthetique,
                        effet_essai, facteur_borne, projection_simplexe)
from koach.numerique import Mulberry32

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with open(os.path.join(RACINE, 'params', 'koach_params_v1.json')) as f:
    PARAMS = json.load(f)


# ----------------------------------------------------------------------
# Doublures : un moteur réduit à ce que lit le contrôle dual
# ----------------------------------------------------------------------
class FauxPiste(object):
    def __init__(self, classe):
        self.classe = classe


class FauxModele(object):
    def __init__(self, ids, sd=0.02, rho=0.01):
        self.journal_semaines = []
        self.sd = dict((ex, sd) for ex in ids)
        self.m = [0.0] * 16
        self.m[dual.RHO] = rho
        self.pistes = dict((ex, FauxPiste(0)) for ex in ids)

    def capacite(self, ex):
        if ex not in self.sd:
            return None
        mu = self.journal_semaines[-1]['mu'][ex] if self.journal_semaines else 0.0
        return mu, self.sd[ex]


class FauxKoach(object):
    def __init__(self, ids, sd=0.02, params=PARAMS):
        self.params = params
        self.modele = FauxModele(ids, sd)
        self.extensions = []

    def semaine(self, doses, mu, e=None):
        ligne = {'semaine': len(self.modele.journal_semaines), 'doses': doses, 'mu': mu}
        self.modele.journal_semaines.append(ligne)
        for x in self.extensions:
            x.fin_semaine(self, ligne, e or {'type': 'semaine_fin'})
        return ligne


def test_indices_alignes_sur_modele():
    try:
        from koach import modele
    except ImportError:  # numpy absent : rien à comparer
        return
    assert dual.RHO == modele.RHO and dual.EPS == modele.EPS


# ----------------------------------------------------------------------
# (a) Reponse
# ----------------------------------------------------------------------
def _simuler_reponse(graine, variable, semaines=12, sigma=0.003, rho=0.01, n_ex=4):
    """Progrès simulés sous l'hypothèse vraie (graine % 9), bruit sigma."""
    r = Reponse.depuis_params(PARAMS)
    rng = Mulberry32(graine)
    vraie = graine % len(r.hypotheses)
    mu = dict(('e%d' % i, 0.0) for i in range(n_ex))
    ref = r.ref
    lignes = [{'semaine': 0, 'doses': dict((k, [ref, ref, ref]) for k in mu), 'mu': dict(mu)}]
    for w in range(1, semaines):
        doses = {}
        for k in sorted(mu):
            if variable:
                st = [1.0 + 13.0 * rng.next() for _ in range(3)]
            else:
                st = [ref, ref, ref]
            doses[k] = st
            mu[k] += rho * r.dose(st, vraie) + sigma * rng.gauss()
        lignes.append({'semaine': w, 'doses': doses, 'mu': dict(mu)})
        r.mettre_a_jour(lignes[-2:], rho, sigma)
    return r, vraie, lignes


def test_reponse_identifie_hypothese_vraie_doses_variables():
    """Hypothèses s0 = 1,5 / 2,5 / 5 (params v1 actuels ; avant : 2,5 / 5 /
    10). Plus proches, elles se distinguent moins. `Reponse` calcule ici
    l'a posteriori EXACT (vraisemblance gaussienne vraie, a priori uniforme) :
    choisir l'hypothèse de plus grand poids est la règle d'identification
    optimale, on ne peut pas faire mieux avec ces données. Taux mesuré avec
    11 progrès (12 semaines) : 239 / 300 graines = 79,7 % (écart-type
    binomial 2,3 points ; l'ancien critère « 24 / 30 » était exactement à la
    moyenne et échouait une fois sur deux selon les graines : 22 / 30 sur
    les graines 1 à 30). Par hypothèse (900 graines) : de 68 % (s0 = 1,5,
    effort) à 100 % (s0 = 5, volume). On exige 75 % sur 300 graines (2
    écarts-types sous la mesure), et, avec 16 semaines (88 % mesuré),
    80 % sur 300 graines."""
    succes = 0
    for g in range(1, 301):
        r, vraie, _ = _simuler_reponse(g, True)
        if r.meilleure() == vraie:
            succes += 1
    assert succes >= 225, succes
    succes16 = 0
    for g in range(1, 301):
        r, vraie, _ = _simuler_reponse(g, True, semaines=16)
        if r.meilleure() == vraie:
            succes16 += 1
    assert succes16 >= 240, succes16


# ----------------------------------------------------------------------
# Non-circularité : Reponse nourrie par l'innovation de capacité
# ----------------------------------------------------------------------
class _PisteK(object):
    classe = 0


class _ModeleKalman(object):
    """Filtre scalaire par exercice qui fait comme le moteur : il apprend la
    capacité par des observations bruitées et, chaque lundi, la fait
    progresser de rho × dose MOYENNE sur les hypothèses (poids `poids_hyp`,
    écrits par le contrôle dual)."""

    def __init__(self, ids, rho):
        dyn = PARAMS['dynamique']
        self.hypotheses = [(x, k) for k in range(len(dyn['hypotheses_stimulus']))
                           for x in dyn['hypotheses_s0']]
        self.poids_hyp = [1.0 / len(self.hypotheses)] * len(self.hypotheses)
        self.m = [0.0] * 16
        self.m[dual.RHO] = rho
        self.pistes = dict((e, _PisteK()) for e in ids)
        self.mu = dict((e, 0.0) for e in ids)
        self.P = dict((e, 0.02 ** 2) for e in ids)
        self.journal_semaines = []

    def capacite(self, e):
        return self.mu[e], math.sqrt(self.P[e])


def _filtre_simule(graine, sy=0.005, semaines=16, nobs=3, rho=0.01, n_ex=4, sp=0.001):
    ids = ['e%d' % i for i in range(n_ex)]
    k = FauxKoach(ids)
    m = _ModeleKalman(ids, rho)
    k.modele = m
    cd = ControleDual(PARAMS, [])
    circ = Reponse.depuis_params(PARAMS)
    rng = Mulberry32(graine)
    vraie = graine % 9
    vrai = dict((e, 0.0) for e in ids)
    dyn = PARAMS['dynamique']
    q7 = 7 * dyn['q_delta_jour_inactif']
    for w in range(semaines):
        for e in ids:
            m.P[e] += q7
        for _ in range(nobs):
            for e in ids:
                y = vrai[e] + sy * rng.gauss()
                gain = m.P[e] / (m.P[e] + sy * sy)
                m.mu[e] += gain * (y - m.mu[e])
                m.P[e] *= 1 - gain
            cd.fin_seance(k, None, {})
        doses = {}
        for e in ids:
            st = [1.0 + 13.0 * rng.next() for _ in range(3)]
            doses[e] = st
            m.mu[e] += rho * sum(m.poids_hyp[i] * cd.reponse.dose(st, i) for i in range(9))
            m.P[e] += dyn['q_delta_semaine']
            vrai[e] += rho * cd.reponse.dose(st, vraie) + sp * rng.gauss()
        ligne = {'semaine': w, 'doses': doses, 'mu': dict(m.mu), 'facteur': 1.0}
        m.journal_semaines.append(ligne)
        cd.fin_semaine(k, ligne, {})
        assert m.poids_hyp == cd.reponse.poids          # une seule source de vérité
        if len(m.journal_semaines) >= 2:
            circ.mettre_a_jour(m.journal_semaines[-2:], rho, 0.01)
    return cd.reponse.meilleure() == vraie, circ.meilleure() == vraie


def test_reponse_innovation_non_circulaire():
    """Nourrie avec les `mu` du journal (qui progressent déjà de la dose
    moyenne), `Reponse` reste au hasard : 15 / 100 et 12 / 100 graines
    mesurées (hasard : 1 / 9 = 11 %). Nourrie par `ControleDual` avec
    l'innovation hebdomadaire de capacité : 67 / 100 et 69 / 100, autant
    qu'un oracle qui verrait les observations brutes (66 / 100 avec bruit
    0,005, 28 / 100 avec bruit 0,02 contre 31 / 100 pour l'innovation)."""
    res = [_filtre_simule(g) for g in range(1, 101)]
    innov = sum(1 for r in res if r[0])
    circ = sum(1 for r in res if r[1])
    assert innov >= 55, innov
    assert circ <= 25, circ


def test_reponse_reste_diffuse_dose_constante():
    hmax = math.log(9)
    for g in range(1, 31):
        r, _, _ = _simuler_reponse(g, False)
        assert max(r.poids) < 0.2
        assert r.entropie() > 0.99 * hmax


def test_reponse_plancher_et_normalisation():
    r = Reponse.depuis_params(PARAMS)
    lignes = [{'semaine': 0, 'doses': {'x': [1, 1, 1]}, 'mu': {'x': 0.0}},
              {'semaine': 1, 'doses': {'x': [14.0, 0.5, 0.5]}, 'mu': {'x': 1.0}}]
    r.mettre_a_jour(lignes, 0.01, 0.001)   # observation aberrante : log-vraisemblances ~ -5e5
    assert abs(sum(r.poids) - 1.0) < 1e-12
    assert min(r.poids) > 0.5e-6
    # Idempotence : la même semaine n'est pas consommée deux fois.
    avant = list(r.poids)
    assert r.mettre_a_jour(lignes, 0.01, 0.001) == 0
    assert r.poids == avant


def test_reponse_dose_identique_au_modele():
    r = Reponse.depuis_params(PARAMS)
    ref = PARAMS['dynamique']['dose_reference']
    for i, (s0, k) in enumerate(r.hypotheses):
        stim = [3.0, 7.0, 11.0]
        attendu = (1 - math.exp(-stim[k] / s0)) / (1 - math.exp(-ref / s0))
        assert abs(r.dose(stim, i) - attendu) < 1e-15
        assert abs(r.dose([ref, ref, ref], i) - 1.0) < 1e-15


def test_thompson_reproductible_et_frequences():
    r, _, _ = _simuler_reponse(7, True, semaines=5)
    r.poids = [0.30, 0.05, 0.10, 0.02, 0.18, 0.15, 0.08, 0.07, 0.05]
    t1 = [r.tirer(Mulberry32(4242 + i)) for i in range(200)]
    t2 = [r.tirer(Mulberry32(4242 + i)) for i in range(200)]
    assert t1 == t2
    rng = Mulberry32(20261009)
    comptes = [0] * 9
    n = 10000
    for _ in range(n):
        comptes[r.tirer(rng)] += 1
    for i in range(9):
        assert abs(comptes[i] / n - r.poids[i]) < 0.02


def test_reponse_etat_aller_retour():
    r, _, _ = _simuler_reponse(3, True)
    r2 = Reponse.depuis_etat(json.loads(json.dumps(r.etat())))
    assert json.dumps(r2.etat()) == json.dumps(r.etat())


# ----------------------------------------------------------------------
# calibre
# ----------------------------------------------------------------------
def test_calibre():
    k = FauxKoach(['squat', 'dc', 'autre'], sd=0.02)
    for w in range(7):
        k.semaine({}, {'squat': 0.0, 'dc': 0.0, 'autre': 0.0})
    ok, raisons = calibre(k, ['squat', 'dc'])
    assert not ok and raisons[0].startswith('semaines_insuffisantes')
    k.semaine({}, {'squat': 0.0, 'dc': 0.0, 'autre': 0.0})
    ok, raisons = calibre(k, ['squat', 'dc'])
    assert ok, raisons                     # 1,645 × 0,02 = 0,033 < 0,06
    k.modele.sd['dc'] = 0.04               # 1,645 × 0,04 = 0,066 ≥ 0,06
    ok, raisons = calibre(k, ['squat', 'dc'])
    assert not ok and raisons[0].startswith('intervalle_large:dc')
    ok, raisons = calibre(k, ['inconnu'])
    assert not ok and raisons == ['lift_inconnu:inconnu']


# ----------------------------------------------------------------------
# (b) Contrôle synthétique
# ----------------------------------------------------------------------
def _temoins(graine, T, J=4):
    rng = Mulberry32(graine)
    series = []
    for j in range(J):
        v = 0.0
        pente = 0.002 + 0.004 * rng.next()
        s = []
        for t in range(T):
            v += pente + 0.012 * rng.gauss()
            s.append(4.0 + 0.3 * j + v)
        series.append(s)
    return series, rng


def test_projection_simplexe():
    assert projection_simplexe([0.2, 0.3, 0.5]) == [0.2, 0.3, 0.5]
    w = projection_simplexe([2.0, 0.0, -1.0])
    assert w == [1.0, 0.0, 0.0]
    w = projection_simplexe([0.5, 0.5, 0.5])   # égalités : résultat symétrique
    assert all(abs(x - 1.0 / 3) < 1e-15 for x in w)
    w = projection_simplexe([0.9, 0.4, -0.3, 0.1])
    assert abs(sum(w) - 1.0) < 1e-12 and min(w) >= 0.0
    # Optimalité : ⟨v − w, u − w⟩ ≤ 0 pour tout sommet u du simplexe.
    v = [0.9, 0.4, -0.3, 0.1]
    for i in range(4):
        u = [1.0 if j == i else 0.0 for j in range(4)]
        assert sum((v[j] - w[j]) * (u[j] - w[j]) for j in range(4)) <= 1e-12


def test_synthetique_retrouve_poids_connus():
    for g in (11, 12, 13, 14, 15):
        T, T0 = 20, 12
        tem, rng = _temoins(g, T)
        tr = [0.6 * tem[0][t] + 0.4 * tem[1][t] + 0.0005 * rng.gauss() for t in range(T)]
        r = controle_synthetique(tr, tem, T0, 200)
        assert abs(r['poids'][0] - 0.6) < 0.05, r['poids']
        assert abs(r['poids'][1] - 0.4) < 0.05, r['poids']
        assert abs(sum(r['poids']) - 1.0) < 1e-12 and min(r['poids']) >= 0.0
        assert r['erreur_pre'] < 0.002
        assert len(r['contrefactuel']) == T and len(r['ecart']) == T - T0


def test_synthetique_convergence():
    """200 itérations suffisent : écart de dualité de Frank-Wolfe (borne de
    f(w) − f*) négligeable, et la solution ne bouge plus avec 2 000."""
    for g in (21, 22, 23):
        tem, rng = _temoins(g, 18, J=5)
        tr = [0.5 * tem[2][t] + 0.3 * tem[3][t] + 0.2 * tem[4][t] + 0.003 * rng.gauss()
              for t in range(18)]
        r = controle_synthetique(tr, tem, 10, 200)
        r2 = controle_synthetique(tr, tem, 10, 2000)
        sse = r['erreur_pre'] ** 2 * 10
        # f(w) − f* ≤ écart de dualité : sous-optimalité < 1 % de l'erreur résiduelle.
        assert r['ecart_dualite'] <= 1e-2 * sse + 1e-12, (r['ecart_dualite'], sse)
        assert r2['ecart_dualite'] <= r['ecart_dualite'] + 1e-15
        for j in range(5):
            assert abs(r['poids'][j] - r2['poids'][j]) < 0.01


def test_synthetique_effet_injecte():
    for g in (31, 32, 33, 34, 35):
        T, T0 = 20, 12
        tem, rng = _temoins(g, T)
        tr = [0.6 * tem[0][t] + 0.4 * tem[1][t] + 0.0005 * rng.gauss() + (0.02 if t >= T0 else 0.0)
              for t in range(T)]
        r = controle_synthetique(tr, tem, T0, 200)
        assert abs(r['effet_moyen'] - 0.02) < 0.005, r['effet_moyen']


def test_synthetique_minimum_six_semaines():
    tem, _ = _temoins(41, 12)
    tr = list(tem[0])
    with pytest.raises(ValueError):
        controle_synthetique(tr, tem, 5, 200)
    controle_synthetique(tr, tem, 6, 200)   # exactement 6 : accepté


def test_effet_essai_progres():
    T, T0 = 16, 8
    tem, rng = _temoins(51, T)
    tr = [0.5 * tem[0][t] + 0.5 * tem[2][t] + (0.003 * (t - T0 + 1) if t >= T0 else 0.0)
          for t in range(T)]
    r = effet_essai(tr, tem, T0)
    assert len(r['progres_traite']) == T - T0
    for k in range(T - T0):
        assert abs(r['progres_traite'][k] - r['progres_temoin_synthetique'][k] - 0.003) < 1e-3


# ----------------------------------------------------------------------
# (c) Essai N-of-1
# ----------------------------------------------------------------------
def _essai_simule(graine, effet, bruit=0.003, n_bras=4):
    es = EssaiN1(PARAMS, {'qualite': 'force'}, ['squat'], ['dc', 'traction'])
    rng = Mulberry32(graine)
    es.plan(rng, n_bras)
    es.demarrer(10)
    for s in range(10, 10 + es.duree()):
        c = es.condition(s)
        base = 0.006 + 0.002 * rng.gauss()          # progrès commun (vu aussi par le témoin)
        traite = base + (effet if c == 'B' else 0.0) + bruit * rng.gauss()
        assert es.enregistrer(s, traite, base)
    assert es.statut == 'termine'
    assert es.condition(10 + es.duree()) is None
    return es


def test_essai_sequence_equilibree():
    vues = set()
    for g in range(1, 41):
        es = EssaiN1(PARAMS, {'exerciseId': 'squat'})
        seq = es.plan(Mulberry32(g), 4)
        assert seq in (['A', 'B', 'B', 'A'], ['B', 'A', 'A', 'B'])
        vues.add(''.join(seq))
        seq8 = es.plan(Mulberry32(g), 8)
        assert seq8.count('A') == 4
        for j in range(4):
            assert sorted(seq8[2 * j:2 * j + 2]) == ['A', 'B']
    assert vues == {'ABBA', 'BAAB'}
    with pytest.raises(ValueError):
        EssaiN1(PARAMS, {'exerciseId': 'squat'}).plan(Mulberry32(1), 3)


def test_essai_conditions_par_bras():
    es = EssaiN1(PARAMS, {'exerciseId': 'squat'})
    assert es.condition(0) is None             # pas commencé
    es.plan(Mulberry32(5), 4)
    es.demarrer(20)
    assert es.condition(19) is None
    for s in range(20, 32):
        assert es.condition(s) == es.sequence[(s - 20) // 3]
    assert es.condition(32) is None
    es.interrompre('douleur')
    assert es.condition(21) is None and es.statut == 'interrompu'


def test_essai_decide_b_avec_effet():
    n = sum(1 for g in range(1, 51) if _essai_simule(g, 0.004).analyse()['decision'] == 'B')
    assert n >= 40, n   # ≥ 80 % de 50 graines, 4 bras


def test_essai_effet_nul():
    """Effet nul. Avec la règle du cahier (P(B > A) entre 0,2 et 0,8) et
    l'a priori N(0, 0,005²), une probabilité a posteriori calibrée est
    quasi uniforme sous l'hypothèse nulle : 'indetermine' ≈ 60 %, et non
    80 % (voir le rapport de livraison). On vérifie l'atteignable :
    majorité d'indéterminés, erreurs rares et symétriques, effet estimé
    centré."""
    res = [_essai_simule(1000 + g, 0.0).analyse() for g in range(50)]
    ind = sum(1 for a in res if a['decision'] == 'indetermine')
    na = sum(1 for a in res if a['decision'] == 'A')
    nb = sum(1 for a in res if a['decision'] == 'B')
    assert ind >= 25, (ind, na, nb)
    assert na <= 15 and nb <= 15
    moy = sum(a['effet'] for a in res) / 50
    assert abs(moy) < 0.0008


def test_essai_analyse_formules():
    es = EssaiN1(PARAMS, {'exerciseId': 'squat'})
    es.sequence = ['A', 'B', 'B', 'A']
    es.demarrer(0)
    vals = [0.001, 0.002, 0.003, 0.006, 0.005, 0.007, 0.004, 0.006, 0.005, 0.002, 0.001, 0.000]
    for s in range(12):
        es.enregistrer(s, vals[s], 0.0)
    a = es.analyse()
    mA1, mB1, mB2, mA2 = 0.002, 0.006, 0.005, 0.001
    assert abs(a['effet'] - ((mB1 - mA1) + (mB2 - mA2)) / 2) < 1e-15
    ssw = sum((vals[s] - [mA1, mB1, mB2, mA2][s // 3]) ** 2 for s in range(12))
    se = math.sqrt(ssw / 8 * (2.0 / 3 + 2.0 / 3) / 4)
    assert abs(a['erreur_type'] - se) < 1e-15
    t2 = 0.005 ** 2
    v = 1 / (1 / t2 + 1 / se ** 2)
    assert abs(a['moyenne_post'] - v * a['effet'] / se ** 2) < 1e-15
    assert a['decision'] == 'B' and a['ddl'] == 8


def test_amplitudes_dans_plafonds():
    es = EssaiN1(PARAMS, {'qualite': 'force'})
    pl = PARAMS['planification']
    for lettre in ('A', 'B'):
        f = es.facteurs(lettre)
        assert 1 - pl['plafond_volume'] <= f['volume'] <= 1 + pl['plafond_volume']
        assert 1 - pl['plafond_intensite'] <= f['intensite'] <= 1 + pl['plafond_intensite']
    trop = json.loads(json.dumps(PARAMS))
    trop['controle_dual']['amplitude_volume'] = 0.2
    with pytest.raises(AssertionError):
        EssaiN1(trop, {'qualite': 'force'})
    trop = json.loads(json.dumps(PARAMS))
    trop['controle_dual']['amplitude_intensite'] = 0.06
    with pytest.raises(AssertionError):
        EssaiN1(trop, {'qualite': 'force'})
    # Le produit avec le déplacement du plan reste borné.
    assert facteur_borne(1.12, 1.10, 0.15) == 1.15
    assert abs(facteur_borne(0.98, 1.03, 0.05) - 1.0094) < 1e-12


def test_peut_demarrer():
    es = EssaiN1(PARAMS, {'qualite': 'force'})
    es.plan(Mulberry32(1), 4)
    ok_ctx = {'calibre': True, 'affutage': False, 'semaines_avant_echeance': 30,
              'alerte': False, 'douleur': False}
    assert es.peut_demarrer(ok_ctx) == (True, [])
    for cle, val, raison in (('calibre', False, 'non_calibre'),
                             ('affutage', True, 'affutage'),
                             ('alerte', True, 'alerte_hors_modele'),
                             ('douleur', True, 'douleur'),
                             ('semaines_avant_echeance', 5, 'echeance_proche'),
                             ('semaines_avant_echeance', 17, 'echeance_proche')):
        ctx = dict(ok_ctx)
        ctx[cle] = val
        ok, raisons = es.peut_demarrer(ctx)
        assert not ok and raison in raisons, (cle, raisons)
    ctx = dict(ok_ctx)
    ctx['semaines_avant_echeance'] = 18      # 12 semaines d'essai + 6 de marge
    assert es.peut_demarrer(ctx)[0]


# ----------------------------------------------------------------------
# ControleDual et (d) déterminisme
# ----------------------------------------------------------------------
IDS = ['dc', 'row', 'squat', 'traction', 'dips']


def _scenario(graine, douleur_semaine=None):
    """20 semaines : 9 de rodage, essai sur le squat à partir de la 10e,
    témoins synthétiques = autres exercices."""
    k = FauxKoach(IDS, sd=0.02)
    cd = ControleDual(PARAMS, ['squat', 'dc'])
    k.extensions.append(cd)
    rng = Mulberry32(graine)
    mu = dict((ex, 4.0 + 0.1 * i) for i, ex in enumerate(IDS))
    commun = 0.0
    tirages = []
    mods = []
    for w in range(22):
        if w == 10:
            ok, raisons = cd.proposer_essai(k, w, {'exerciseId': 'squat'}, ['squat'],
                                           ['dc', 'row', 'traction', 'dips'],
                                           {'semaines_avant_echeance': 30}, graine)
            assert ok, raisons
        mod = cd.modulation(w)
        mods.append(mod)
        commun = 0.004 + 0.002 * rng.gauss()
        doses = {}
        for i, ex in enumerate(IDS):
            st = [2.0 + 10.0 * rng.next(), 2.0 + 8.0 * rng.next(), 1.0 + 10.0 * rng.next()]
            doses[ex] = st
            gain = commun * (0.8 + 0.1 * i) + 0.002 * rng.gauss()
            if ex == 'squat' and mod.get('bras') == 'B':
                gain += 0.004
            mu[ex] += gain
        e = {'type': 'semaine_fin'}
        if douleur_semaine is not None and w == douleur_semaine:
            e['douleur'] = True
        k.semaine(doses, dict(mu), e)
        tirages.append(cd.hypothese_pour_la_semaine(k, w + 1, graine))
    return cd, tirages, mods


def test_controle_dual_essai_complet():
    cd, tirages, mods = _scenario(77)
    assert cd.essai is None and len(cd.essais_passes) == 1
    passe = cd.essais_passes[0]
    assert passe['essai']['statut'] == 'termine'
    assert len(passe['essai']['mesures']) == 12
    assert passe['analyse']['paires'] == 2
    # Modulation : 1,0 hors essai, facteurs des bras pendant l'essai.
    assert mods[9] == {'volume': 1.0, 'intensite': 1.0}
    assert cd.modulation(22) == {'volume': 1.0, 'intensite': 1.0}
    for w in range(10, 22):
        assert mods[w]['exerciseId'] == 'squat'
        assert mods[w]['volume'] in (1.1, 1.0) and mods[w]['intensite'] in (1.0, 1.03)
    # Thompson : rien avant 8 semaines de journal, puis tirage reproductible.
    assert tirages[:7] == [None] * 7
    assert all(t is not None for t in tirages[7:])


def test_controle_dual_interrompu_par_douleur():
    cd, _, mods = _scenario(78, douleur_semaine=14)
    assert cd.essai is None
    passe = cd.essais_passes[0]
    assert passe['essai']['statut'] == 'interrompu'
    assert passe['essai']['raison_fin'] == 'douleur'
    assert mods[16] == {'volume': 1.0, 'intensite': 1.0}   # retour au plan de référence


def test_essai_refuse_si_non_calibre():
    k = FauxKoach(IDS, sd=0.02)
    cd = ControleDual(PARAMS, ['squat'])
    for w in range(3):
        k.semaine({}, dict((ex, 4.0) for ex in IDS))
    ok, raisons = cd.proposer_essai(k, 3, {'exerciseId': 'squat'}, ['squat'], ['dc'], {}, 1)
    assert not ok and 'non_calibre' in raisons
    assert cd.modulation(4) == {'volume': 1.0, 'intensite': 1.0}


def test_thompson_semaine_graine():
    k = FauxKoach(IDS, sd=0.02)
    cd = ControleDual(PARAMS, ['squat'])
    for w in range(9):
        k.semaine({}, dict((ex, 4.0) for ex in IDS))
    cd.reponse.poids = [0.3, 0.05, 0.1, 0.02, 0.18, 0.15, 0.08, 0.07, 0.05]
    a = [cd.hypothese_pour_la_semaine(k, s, 123) for s in range(50)]
    b = [cd.hypothese_pour_la_semaine(k, s, 123) for s in range(50)]
    c = [cd.hypothese_pour_la_semaine(k, s, 124) for s in range(50)]
    assert a == b and a != c
    assert len(set(a)) > 3


def test_determinisme_et_etat():
    cd1, t1, m1 = _scenario(99)
    cd2, t2, m2 = _scenario(99)
    j1 = json.dumps(cd1.etat(), sort_keys=True)
    assert j1 == json.dumps(cd2.etat(), sort_keys=True)
    assert t1 == t2 and m1 == m2
    cd3 = ControleDual.depuis_etat(PARAMS, json.loads(j1))
    assert json.dumps(cd3.etat(), sort_keys=True) == j1
    # Essai en cours : l'état se recharge et l'essai continue à l'identique.
    es = _essai_simule(5, 0.004)
    es2 = EssaiN1.depuis_etat(PARAMS, json.loads(json.dumps(es.etat())))
    assert json.dumps(es2.analyse(), sort_keys=True) == json.dumps(es.analyse(), sort_keys=True)
