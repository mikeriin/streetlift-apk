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


def test_echauffements_echecs_et_bruit_appris_sans_effet_sur_l_indicateur():
    """Les échauffements et les séries ratées ne comptent ni comme notées ni
    comme non notées ; φ est mesuré contre le bruit de population : forcer
    `bruit_rir` ne change pas la mise à jour d'une note."""
    k = koach()
    k.observe({'type': 'seance_debut', 'jour': 7, 'contexte': {'semaine': 1, 'genre': 'accumulation'}})
    chauffe = serie(60.0, 5, None)
    chauffe['kind'] = 'warmup'
    k.observe({'type': 'serie', 'serie': chauffe})
    k.observe({'type': 'serie', 'serie': serie(110.0, 0, 10, failed=True)})
    k.observe({'type': 'serie', 'serie': serie(110.0, 3, 10, failed=True)})
    f = k.modele.fiabilite
    assert f.notes == 0 and f.nn == f.nn0 and f.notes_s == [0, 0]
    k.observe({'type': 'serie', 'serie': serie(110.0, 5, None)})
    assert f.notes == 0 and f.nn[0] > f.nn0[0]
    # bruit_rir forcé : même grille après la même note
    k1 = koach()
    k2 = koach()
    for kk in (k1, k2):
        kk.observe({'type': 'seance_debut', 'jour': 7, 'contexte': {'semaine': 1, 'genre': 'accumulation'}})
    k2.modele.bruit_rir = 2.0
    for kk in (k1, k2):
        kk.observe({'type': 'serie', 'serie': serie(110.0, 5, 7)})
    assert max(abs(a - b) for a, b in zip(k1.modele.fiabilite.lp, k2.modele.fiabilite.lp)) < 1e-12
    # série lourde selon repsHigh
    k3 = koach()
    k3.observe({'type': 'seance_debut', 'jour': 7, 'contexte': {'semaine': 1, 'genre': 'accumulation'}})
    k3.observe({'type': 'serie', 'serie': serie(110.0, 5, 7, hi=8)})
    assert k3.modele.fiabilite.notes_s == [0, 1]


def test_proba_phi_sup_inclut_le_point_de_grille():
    f = Fiabilite(PARAMS)
    assert abs(f.proba_phi_sup(2.0) - sum(math.exp(x) for x, ph in zip(f.lp, f.phi) if ph >= 2.0 - 1e-9)) < 1e-12
    assert f.proba_phi_sup(2.0) > f.proba_phi_sup(2.83)


def test_elargissement_plafonne():
    p = copy.deepcopy(PARAMS)
    p['mesure']['fiabilite_elargissement_non_notee'] = 1000.0
    f = Fiabilite(p)
    for _ in range(100):
        f.serie(False, False)
    assert f.elargissement() == p['mesure']['fiabilite_elargissement_max'] == 2.0


def test_echec_non_prevu_sans_hausse_tout_schema():
    """Après un échec non prévu à la dernière séance de l'exercice : mode 1,
    aucune hausse par rapport au dernier passage quel que soit le schéma ;
    mode 0, seule la règle du même schéma ; mode 2, seulement si κ > 1."""
    def premiere_serie(mode, kappa):
        prm = copy.deepcopy(PARAMS)
        prm['securite']['echec_sans_hausse_tout_schema'] = mode
        k = koach(prm)
        _journal(k, [3, 5, 5, 3])
        k.modele.elargissement = lambda: kappa
        s = k.seances
        mem = s.mem(EX)
        mem.echec = True
        mem.charge_derniere = 100.0
        k.garde.avancer(40)
        s.ouvrir(40, None, {'semaine': 5, 'genre': 'accumulation'})
        item = {'slotId': 's9', 'exerciseId': EX, 'kind': 'work', 'sets': 3, 'repsLow': 3, 'repsHigh': 3,
                'targetFlames': 7}
        out = s.prescrire([item], {EX: Grille(2.5, 20.0)}, {EX: ({}, set())}, {'s9': 'main'})
        return s.cible(out[0], 0, [])['loadKg']
    assert premiere_serie(0, 1.0) > 100.0
    assert premiere_serie(1, 1.0) <= 100.0
    assert premiere_serie(2, 1.0) > 100.0
    assert premiere_serie(2, 1.3) <= 100.0


def test_posterior_expose_la_fiabilite():
    k = koach()
    _journal(k, [10, None, 3, None])
    r = k.posterior()['fiabilite']
    assert r['notes'] == 16 and r['part_non_notee'] > 0.3 and r['phi'] > 1.0
    assert r['elargissement'] >= 1.0 and 'lourd' in r['par_schema']


def _ouverture(kappa, barres=(), ratees=(), estimation=200.0, sd=0.03, apres_echec=False, genre='test'):
    k = koach()
    s = k.seances
    k.garde.avancer(40)
    s.ouvrir(40, None, {'semaine': 5, 'genre': genre, 'jour_evenement': True})
    t = k.modele.piste(EX)
    t.mesures = 5
    t.seances = 8
    mem = s.mem(EX)
    mem.charge_derniere = 60.0
    mem.charges_reussies = [(j, c, r) for (j, c, r, f) in barres]
    mem.barres = list(barres)
    mem.barres_ratees = list(ratees)
    est = [estimation]
    k.modele.capacite_du_jour = lambda ex_id, avec_bruit_jour=True, brut=False: (math.log(est[0]), sd * (1.0 if brut else kappa))
    k.modele.elargissement = lambda: kappa
    item = {'slotId': 's1', 'exerciseId': EX, 'kind': 'test', 'sets': 3, 'repsLow': 1, 'repsHigh': 1,
            'targetFlames': 10, 'test': {'kind': 'one_rm'}}
    out = s.prescrire([item], {EX: Grille(2.5, 20.0)}, {EX: ({}, set())}, {'s1': 'main'})
    c0 = s.cible(out[0], 0, [])['loadKg']
    if not apres_echec:
        return c0
    s.serie_faite({'exerciseId': EX, 'slotId': 's1', 'externalLoadKg': c0, 'reps': 0, 'flames': 10, 'failed': True,
                   'target': {'repsLow': 1, 'repsHigh': 1, 'flames': 7, 'role': 'attempt'}})
    est[0] = c0 * 0.97          # la barre manquée a abaissé l'estimation (filtre)
    return c0, s.cible(out[0], 1, [])['loadKg']


def test_ouverture_quantile_brut_et_palier_selon_la_fiabilite():
    """L'ouverture suit le quantile sur l'écart-type BRUT (κ ne l'abaisse
    pas : mesuré en KM1c3, coût sans gain) ; chez un athlète aux notes peu
    fiables, le palier accordé par la note des barres est réduit (nul dès
    κ ≥ 1,33 avec c = 3) et chaque barre réussie ne vaut que (1 − marge) de
    sa charge, marge = min(5 % ; 10 %·(κ − 1))."""
    assert _ouverture(1.0) == 180.0
    assert _ouverture(2.0) == 180.0                                    # σ brut : identique
    assert _ouverture(1.0, [(30, 150.0, 1, 3)]) == 165.0               # 4 en réserve : +10 % (1.0.2)
    assert _ouverture(1.2, [(30, 150.0, 1, 3)]) == 152.5               # 150 × 0,98 × (1 + 0,10 × 0,4) = 152,9 → 152,5
    assert _ouverture(1.4, [(30, 150.0, 1, 3)]) == 142.5               # palier nul, marge 4 % : 144 → 142,5
    assert _ouverture(1.0, [(30, 150.0, 1, 10)]) == 150.0              # à la limite, notes fiables : la barre
    assert _ouverture(1.5, [(30, 150.0, 1, 10)]) == 142.5              # marge 5 % : 142,5
    assert _ouverture(2.0, [(30, 150.0, 1, None)]) == 142.5            # marge plafonnée à 5 %
    assert _ouverture(1.0, [(30, 150.0, 1, 7)]) == 157.5               # 2 en réserve, fiable : +5 % (1.0.2)


def test_barre_suivante_apres_un_echec_hors_competition():
    """Test 1RM à l'entraînement : après un échec, la barre suivante suit
    l'estimation mise à jour, au plus 5 % sous la barre ratée, jamais
    au-dessus ; en semaine de compétition, la même barre (A8.2)."""
    c0, c1 = _ouverture(1.0, [(30, 150.0, 1, 3)], apres_echec=True)
    assert c0 == 165.0 and c1 == 157.5      # 160 × e^{−0,84·0,03} = 156 → plancher 155 ; ≥ 165 × 0,95 = 156,75 → 157,5
    c0, c1 = _ouverture(1.0, [(30, 150.0, 1, 3)], apres_echec=True, genre='competition')
    assert c0 == 165.0 and c1 == 165.0


def test_prudence_des_series_lourdes():
    """Séries ≤ 5 répétitions, κ > 1 : charge au quantile plus prudent de
    `prudence_charge_fiabilite`·(κ − 1) écarts-types ; κ = 1 ou série
    longue : inchangée."""
    p = copy.deepcopy(PARAMS)
    p['planification']['prudence_charge_fiabilite'] = 1.0

    def charge(kappa, reps, prm):
        k = koach(prm)
        _journal(k, [3, 5, 5, 3])
        k.modele.elargissement = lambda: kappa
        s = k.seances
        k.garde.avancer(40)
        s.ouvrir(40, None, {'semaine': 5, 'genre': 'accumulation'})
        item = {'slotId': 's1', 'exerciseId': EX, 'kind': 'work', 'sets': 3, 'repsLow': reps, 'repsHigh': reps,
                'targetFlames': 7}
        out = s.prescrire([item], {EX: Grille(2.5, 20.0)}, {EX: ({}, set())}, {'s1': 'main'})
        return s.cible(out[0], 0, [])['loadKg']
    p0 = copy.deepcopy(PARAMS)
    p0['planification']['prudence_charge'] = [0.0, 0.0]          # isole la prudence de fiabilité de prudence_charge·σ·κ
    p1 = copy.deepcopy(p0)
    p1['planification']['prudence_charge_fiabilite'] = 1.0
    assert charge(1.0, 3, p1) == charge(1.0, 3, p0)
    assert charge(1.5, 3, p1) < charge(1.0, 3, p1)
    assert charge(1.5, 3, p0) == charge(1.0, 3, p0)              # coefficient 0 : rien
    assert charge(1.5, 8, p1) == charge(1.0, 8, p1)              # série longue : rien
    assert charge(1.5, 3, p) <= charge(1.0, 3, p)


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
