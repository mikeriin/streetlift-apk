# -*- coding: utf-8 -*-
"""1.0.3 (KM1 correction 3, DECISIONS_CP.md C17.9) : fiabilité des notes —
indicateur bayésien (φ, part non notée, oubli), élargissement de l'incertitude
des capacités sans déplacement de leur moyenne, prudence ciblée à l'ouverture
des tentatives."""
import copy
import json
import math
import os

import numpy as np

from koach.modele import Fiabilite, Modele, INF
from koach.moteur import Koach
from koach.seance import Grille

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']
EX = 'mu-back-squat-barre-basse'


def koach(params=None, niveau=2):
    return Koach(params or PARAMS, FICHES, {'niveau': niveau, 'sexe': 'male', 'poids_kg': 80.0,
                                             'declares': {EX: ('one_rm_kg', 150.0)}, 'zones_fragiles': []})


def serie(charge, reps, flammes, cible_flammes=7, failed=False, hi=None):
    return {'exerciseId': EX, 'slotId': 's1', 'externalLoadKg': charge, 'reps': reps, 'flames': flammes,
            'failed': failed, 'restSeconds': 120,
            'target': {'repsLow': reps, 'repsHigh': hi or reps, 'flames': cible_flammes, 'role': None}}


# ----------------------------------------------------------------------
# L'indicateur seul
# ----------------------------------------------------------------------
def test_a_priori_centre_sur_1_et_grille():
    f = Fiabilite(PARAMS)
    assert len(f.phi) == PARAMS['mesure']['fiabilite_phi_points']
    assert abs(f.phi[0] - PARAMS['mesure']['fiabilite_phi_min']) < 1e-12
    assert abs(f.phi[-1] - PARAMS["mesure"]["fiabilite_phi_max"]) < 1e-9
    assert abs(sum(math.exp(x) for x in f.lp) - 1.0) < 1e-12
    assert abs(f.ln_phi_moyen()) < 1e-9                 # a priori symétrique en ln φ
    assert f.phi_moyen() > 1.0                          # E[φ] > e^{E[ln φ]} (Jensen)
    assert f.elargissement() == 1.0                     # sans note : aucun élargissement
    assert abs(f.part_non_notee() - 0.2) < 1e-12        # a priori Beta(1, 4)


def test_notes_justes_abaissent_phi_notes_fausses_l_elevent():
    """Des notes dont l'intervalle contient la prévision (bruit de population
    s0 = 1 rep) font baisser E[φ] ; des notes à 3 écarts-types le font monter
    au-delà de 2 ; une note ouverte contredite (« 4 ou plus » quand la
    prévision est 0,3) pèse autant."""
    juste = Fiabilite(PARAMS)
    faux = Fiabilite(PARAMS)
    ouverte = Fiabilite(PARAMS)
    for _ in range(40):
        juste.noter(2.0, 0.2, 1.75, 2.25, 1.0, 0.0, 0.95, 0.005, False)
        faux.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, False)
        ouverte.noter(0.3, 0.2, 3.75, INF, 1.0, 0.0, 0.95, 0.005, True)
    assert juste.phi_moyen() < 1.0
    assert faux.phi_moyen() > 2.0
    assert ouverte.phi_moyen() > 2.0
    assert ouverte.notes_s[0] == 40 and ouverte.notes_s[1] == 0      # par schéma : lourd


def test_oubli_rehabilite_un_athlete_qui_apprend_a_noter():
    f = Fiabilite(PARAMS)
    for _ in range(40):
        f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, False)
    haut = f.phi_moyen()
    for _ in range(120):
        f.noter(2.0, 0.2, 1.75, 2.25, 1.0, 0.0, 0.95, 0.005, False)
    assert haut > 2.0 and f.phi_moyen() < 1.2


def test_note_paresseuse_ne_dit_rien():
    """Une note égale à la préremplie, quand le mélange lui donne tout le
    poids « sans information », ne déplace pas la grille."""
    f = Fiabilite(PARAMS)
    avant = list(f.lp)
    f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.0, 1.0, False)
    assert max(abs(a - b) for a, b in zip(avant, f.lp)) < 1e-12


def test_part_non_notee_beta_avec_oubli():
    f = Fiabilite(PARAMS)
    for _ in range(50):
        f.serie(False, False)
    assert f.part_non_notee() > 0.85
    for _ in range(200):
        f.serie(True, False)
    assert f.part_non_notee() < 0.1


def test_elargissement_formule():
    p = copy.deepcopy(PARAMS)
    p['mesure']['fiabilite_elargissement_phi'] = 0.5
    p['mesure']['fiabilite_elargissement_non_notee'] = 2.0
    f = Fiabilite(p)
    for _ in range(60):
        f.noter(2.0, 0.2, 4.75, 5.25, 1.0, 0.0, 0.95, 0.005, False)
        f.serie(False, False)
        f.serie(True, False)
    phi = f.phi_moyen()
    nn = f.part_non_notee()
    attendu = math.sqrt(1.0 + 0.5 * (phi - f.phi0) + 2.0 * (nn - 0.2) ** 2)
    assert abs(f.elargissement() - attendu) < 1e-12
    assert f.elargissement() > 1.1
    r = f.resume()
    assert set(r) == {'phi', 'ln_phi', 'p_phi_sup_2', 'notes', 'part_non_notee', 'elargissement', 'par_schema'}


# ----------------------------------------------------------------------
# Dans le moteur : moyenne intacte, incertitude élargie, prudence ciblée
# ----------------------------------------------------------------------
def _journal(k, notes, jours=(7, 10, 14, 17, 21, 24, 28, 31)):
    """Huit séances de 4 × 5 à 110 kg ; [notes] : flammes par série (None :
    non notée). Renvoie le modèle."""
    for j in jours:
        k.observe({'type': 'seance_debut', 'jour': j, 'contexte': {'semaine': j // 7, 'genre': 'accumulation'}})
        for i in range(4):
            k.observe({'type': 'serie', 'serie': serie(110.0, 5, notes[i % len(notes)])})
        k.observe({'type': 'seance_fin', 'seance': {'sets': []}})
    return k.modele


def test_moyenne_intacte_incertitude_elargie():
    """Même journal, paramètres d'élargissement à 0 (1.0.2) ou non nuls
    (1.0.3) : la moyenne de la capacité est identique, l'écart-type ne l'est
    que pour l'athlète aux notes non fiables."""
    p0 = copy.deepcopy(PARAMS)
    p0['mesure']['fiabilite_elargissement_phi'] = 0.0
    p0['mesure']['fiabilite_elargissement_non_notee'] = 0.0
    p1 = copy.deepcopy(PARAMS)
    p1['mesure']['fiabilite_elargissement_phi'] = 1.0
    p1['mesure']['fiabilite_elargissement_non_notee'] = 3.0
    # Notes cohérentes avec 110 kg × 5 pour un 1RM déclaré de 150 kg
    # (réserve vraie ≈ 4 à 6) : flammes 3 et 5.
    fiable = [3, 5, 5, 3]
    # Notes incohérentes : 10 (échec) et 3 (4 ou plus) en alternance, et une
    # série sur deux sans note.
    douteux = [10, None, 3, None]
    for notes in (fiable, douteux):
        m0 = _journal(koach(p0), notes)
        m1 = _journal(koach(p1), notes)
        c0 = m0.capacite(EX)
        c1 = m1.capacite(EX)
        j0 = m0.capacite_du_jour(EX)
        j1 = m1.capacite_du_jour(EX)
        assert abs(c0[0] - c1[0]) < 1e-12 and abs(j0[0] - j1[0]) < 1e-12     # moyenne intacte
        assert np.allclose(m0.m[:m0.n], m1.m[:m1.n]) and np.allclose(m0.P[:m0.n, :m0.n], m1.P[:m1.n, :m1.n])
        k0 = m0.elargissement()
        k1 = m1.elargissement()
        assert k0 == 1.0
        if notes is fiable:
            assert k1 == 1.0 and abs(c0[1] - c1[1]) < 1e-12 and abs(j0[1] - j1[1]) < 1e-12
        else:
            assert k1 > 1.1
            assert c1[1] > c0[1] and abs(j1[1] / j0[1] - k1) < 1e-9
            # brut : variance du filtre telle quelle (contrôle dual)
            assert abs(m1.capacite(EX, brut=True)[1] - m0.capacite(EX, brut=True)[1]) < 1e-12


def test_posterior_expose_la_fiabilite():
    k = koach()
    _journal(k, [10, None, 3, None])
    r = k.posterior()['fiabilite']
    assert r['notes'] == 16 and r['part_non_notee'] > 0.3 and r['phi'] > 1.0
    assert r['elargissement'] >= 1.0 and 'lourd' in r['par_schema']


def _ouverture(kappa, e_ouv=0.0, estimation=200.0, sd=0.03):
    k = koach()
    s = k.seances
    s.s = dict(s.s, tentative_prudence_elargie=e_ouv)
    k.garde.avancer(40)
    s.ouvrir(40, None, {'semaine': 5, 'genre': 'accumulation', 'jour_evenement': True})
    t = k.modele.piste(EX)
    t.mesures = 5
    t.seances = 8
    mem = s.mem(EX)
    mem.charge_derniere = 60.0
    k.modele.capacite_du_jour = lambda ex_id: (math.log(estimation), sd * kappa)
    k.modele.elargissement = lambda: kappa
    item = {'slotId': 's1', 'exerciseId': EX, 'kind': 'test', 'sets': 3, 'repsLow': 1, 'repsHigh': 1,
            'targetFlames': 10, 'test': {'kind': 'one_rm'}}
    out = s.prescrire([item], {EX: Grille(2.5, 20.0)}, {EX: ({}, set())}, {'s1': 'main'})
    return s.cible(out[0], 0, [])['loadKg']


def test_prudence_ciblee_a_l_ouverture():
    """κ = 1 : ouverture de 1.0.2 (91 % de 200 kg → 180). κ > 1 : l'écart-type
    élargi abaisse le quantile, et la probabilité visée monte avec κ quand
    `tentative_prudence_elargie` > 0 ; jamais au-dessus de 1.0.2."""
    assert _ouverture(1.0) == 180.0
    assert _ouverture(1.0, e_ouv=2.0) == 180.0
    # σ = 0,03 : P ≥ 0,95 donne e^{−1,645·σ} ; avec κ = 2, σ_eff = 0,06 → 0,906 → 180 ; κ = 2,5 → 0,884 → 175
    assert _ouverture(2.5) == 175.0
    assert _ouverture(2.5, e_ouv=2.0) < 175.0
    assert _ouverture(2.0, e_ouv=2.0) < _ouverture(2.0)
    for kappa in (1.2, 1.5, 2.0, 3.0):
        assert _ouverture(kappa, e_ouv=2.0) <= _ouverture(kappa) <= 180.0


def test_jumeau_tire_avec_l_elargissement():
    """Les tirages du jumeau (planification) ont un écart-type des capacités
    multiplié par κ, pas celui de la réponse."""
    from koach.planification import Planification
    p = copy.deepcopy(PARAMS)
    p['mesure']['fiabilite_elargissement_phi'] = 1.0
    p['mesure']['fiabilite_elargissement_non_notee'] = 3.0
    k = koach(p)
    _journal(k, [10, None, 3, None])
    kappa = k.modele.elargissement()
    assert kappa > 1.1
    pl = Planification(k.params, FICHES, options={'trajectoires': 400, 'graine': 1, 'sans_validateur': True})
    pl.suivis = [EX]
    x1 = pl.tirer(k, 5, 400)
    k.modele.elargissement = lambda: 1.0
    x0 = pl.tirer(k, 5, 400)
    moy = k.modele.capacite(EX)[0]
    # Mêmes nombres aléatoires : écarts à la moyenne multipliés par κ
    # exactement pour la capacité, inchangés pour la réponse.
    assert np.allclose(x1['mu'][:, 0] - moy, kappa * (x0['mu'][:, 0] - moy), atol=1e-9)
    assert np.allclose(x1['rho'], x0['rho'], atol=1e-12)
