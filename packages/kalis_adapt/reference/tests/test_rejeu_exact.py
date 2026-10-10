# -*- coding: utf-8 -*-
"""Rejeu exact : l'état du moteur se recalcule depuis son journal (séries,
bilans, décisions ET appels de plan journalisés), cahier § Déterminisme."""
import json

import numpy as np

from banc import donnees, meneur
from banc.politique_koach import PolitiqueKoach
from koach.moteur import rejouer


def _saison(cle, scenario):
    return [x for x in donnees.saisons_reference(cle) if x['scenario'] == scenario][0]


def _compare(cle, scenario, verite, graine):
    infos = donnees.catalogue_infos()
    pol = PolitiqueKoach()
    meneur.simuler(_saison(cle, scenario), infos, pol, verite, graine)
    k = pol.koach
    # Le journal est du JSON pur : il survit à un aller-retour.
    journal = json.loads(json.dumps(k.journal))
    assert any(e['type'] == 'plan' for e in journal)
    r = rejouer(k.params, k.fiches, k.profil, journal)
    assert r.modele.ordre == k.modele.ordre
    assert np.array_equal(r.modele.m[:r.modele.n], k.modele.m[:k.modele.n])
    assert np.array_equal(r.modele.P[:r.modele.n, :r.modele.n], k.modele.P[:k.modele.n, :k.modele.n])
    assert json.dumps(r.posterior(), sort_keys=True) == json.dumps(k.posterior(), sort_keys=True)
    assert r.explain() == k.explain()
    assert len(r.journal) == len(journal)


def test_rejeu_exact_reference():
    _compare('street_07_avance_streetlifting_competition', 'reference', 'a', 3)


def test_rejeu_exact_douleur():
    _compare('street_07_avance_streetlifting_competition', 'douleur_coude', 'b', 1)
