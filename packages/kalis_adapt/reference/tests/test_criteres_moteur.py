# -*- coding: utf-8 -*-
"""Critères du cahier KM mesurés sur le banc Python (`banc/criteres_moteur.py`) :
versions rapides du mauvais jour isolé et du déterminisme, et forme de la
sortie JSON. Mesures complètes :
`python3 -m banc.criteres_moteur --sortie donnees/criteres_moteur.json`."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import criteres_moteur as cm  # noqa: E402

PROFIL = 'street_16_specialisation_traction_lestee'


def test_stats():
    s = cm.stats([3.0, 1.0, 2.0, 10.0])
    assert s == {'n': 4, 'moyenne': 4.0, 'mediane': 2.5, 'p95': 10.0, 'max': 10.0}
    assert cm.stats([])['moyenne'] is None
    assert cm.stats(list(range(1, 101)))['p95'] == 95


def test_mauvais_jour_sans_baisse_ne_change_rien():
    """Témoin : un « mauvais jour » de 0 % redonne exactement la même saison
    (mêmes tirages) ; les écarts mesurés sont donc dus au seul mauvais jour."""
    ligne = cm.mauvais_jour_saison(PROFIL, 'b', 1, baisse=0.0)
    assert ligne['jour'] is not None and ligne['semaine'] >= 8
    assert ligne['ecarts']
    for vals in ligne['ecarts'].values():
        assert vals[0] == 0.0
        assert all(v in (None, 0.0) for v in vals)


def test_mauvais_jour_rapide():
    r = cm.mesurer_mauvais_jour(jobs=[(PROFIL, 'a', 0), ('autres_03_powerlifter_competition', 'c', 1)],
                                coeurs=2)
    assert not r['plantages']
    assert r['saisons_mesurees'] == 2
    for ligne in r['mesures']:
        assert ligne['exercice_declencheur'] in ligne['ecarts']
        for vals in ligne['ecarts'].values():
            assert len(vals) == len(cm.HORIZONS) and vals[0] is not None
            # L'estimation bouge, mais bien moins que la baisse de capacité.
            assert all(v is None or abs(v) < cm.MAUVAIS_JOUR for v in vals)
    assert r['ecart_abs']['apres']['n'] >= 2


def test_determinisme_rapide():
    r = cm.mesurer_determinisme(semaines=5, trajectoires=100)
    assert r['respecte'], r['identiques']
    assert r['empreintes'][0]['seances'] > 0


def test_sortie_json(tmp_path):
    sortie = tmp_path / 'criteres.json'
    assert cm.main(['--rapide', '--coeurs', '1', '--sortie', str(sortie)]) == 0
    d = json.loads(sortie.read_text(encoding='utf-8'))
    assert {'version', 'commande', 'machine', 'temps', 'mauvais_jour', 'determinisme', 'duree_s'} <= set(d)
    t = d['temps']
    for cle in ('observe_serie_ms', 'plan_serie_ms', 'plan_seance_ms', 'replanification_s'):
        assert set(t[cle]) == {'n', 'moyenne', 'mediane', 'p95', 'max'}, cle
        assert t[cle]['n'] > 0
    assert t['critere_serie_ms'] == 50.0 and t['critere_replanification_s'] == 10.0
    m = d['mauvais_jour']
    assert set(m['ecart_abs']) == set(cm.HORIZONS)
    assert m['critere'] == 0.01 and isinstance(m['respecte'], bool)
    assert d['determinisme']['respecte'] is True
    assert set(d['determinisme']['identiques']) >= {'servi', 'estimations', 'posterior'}
