# -*- coding: utf-8 -*-
"""Campagne de mesure des critères du cahier KM (`banc/campagne.py`) :
structure du JSON, reprise sur le cache et déterminisme, sur une campagne
minuscule (`--rapide`, peu de trajectoires, saisons tronquées). Campagne
réelle : `python3 -m banc.campagne --profils tous --graines 1 ...`."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import campagne as ca  # noqa: E402

PROFIL = 'street_16_specialisation_traction_lestee'
CRITERES = ('1_erreur_e1rm_rang_6', '2_mauvais_jour_isole', '3_convergence_sous_3', '4_couverture_90',
            '5_calibration_p_reussite', '6_performance_jour_j', '7_securite', '8_temps_calcul', '9_rappels')


def _argv(sortie, travail):
    return ['--profils', PROFIL, '--scenarios', 'reference', '--verites', 'a', '--graines', '2',
            '--rapide', '--trajectoires', '40', '--semaines', '13', '--coeurs', '2',
            '--sortie', str(sortie), '--travail', str(travail)]


def test_classer_constats():
    c = lambda code, w, v: {'code': code, 'week': w, 'dayIndex': None, 'exerciseId': None, 'value': v}
    initial = [c('plafond_volume', 1, 30.0), c('volume_trop_vite', 3, 12.0)]
    servi = [c('plafond_volume', 1, 30.0), c('volume_trop_vite', 3, 13.0), c('volume_trop_vite', 5, 9.0)]
    cl, ex = ca.classer_constats(initial, servi)
    assert cl == {'deja_initial': {'plafond_volume': 1}, 'aggrave': {'volume_trop_vite': 1},
                  'introduit': {'volume_trop_vite': 1}}
    assert len(ex) == 2


def test_deciles():
    paires = [(0.05, False)] * 30 + [(0.95, True)] * 25 + [(0.55, True)] * 3
    dec, pire = ca._deciles(paires)
    assert len(dec) == 10
    assert dec[0]['n'] == 30 and abs(dec[0]['ecart'] - 0.05) < 1e-12
    assert dec[5]['signal'].startswith('n <')
    assert dec[3]['signal'] == 'vide'
    assert abs(pire - 0.05) < 1e-12


def test_campagne_rapide_structure_et_determinisme(tmp_path):
    s1 = tmp_path / 'c1.json'
    s2 = tmp_path / 'c2.json'
    s3 = tmp_path / 'c3.json'
    assert ca.main(_argv(s1, tmp_path / 'w1')) == 0
    assert ca.main(_argv(s2, tmp_path / 'w2')) == 0       # cache neuf
    assert ca.main(_argv(s3, tmp_path / 'w1')) == 0       # reprise sur le cache
    t1 = s1.read_text(encoding='utf-8')
    assert t1 == s2.read_text(encoding='utf-8')
    assert t1 == s3.read_text(encoding='utf-8')
    d = json.loads(t1)
    assert d['schema'] == ca.SCHEMA
    assert d['saisons']['prevues'] == 2 and d['saisons']['plantees'] == 0, d['saisons']['plantages']
    assert set(d['criteres']) == set(CRITERES)
    for k in CRITERES[:8]:
        c = d['criteres'][k]
        assert {'mesure', 'seuil', 'respecte', 'n', 'detail', 'methode'} <= set(c), k
        assert isinstance(c['respecte'], bool), k
    e = d['criteres']['1_erreur_e1rm_rang_6']['detail']
    assert e['koach']['n'] > 0 and e['temoin']['n'] > 0 and 'sd' not in e['temoin']
    cal = d['criteres']['5_calibration_p_reussite']['detail']
    assert set(cal['par_date']) == {'debut', 'mi_saison', 'moins_4_semaines'}
    assert len(cal['par_date']['debut']['deciles']) == 10
    sec = d['criteres']['7_securite']['detail']['b_validateur']['vues']
    assert set(sec) == set(ca.VUES_SECURITE)
    assert {'koach', 'temoin'} <= set(d['secondaires']['ecart_effort'])
    assert 'duree' not in t1 and 'horodatage' not in t1
    # Reprise : une saison = un fichier dans le dossier de travail.
    dossier = next((tmp_path / 'w1').rglob('config.json')).parent
    assert sum(1 for f in os.listdir(str(dossier)) if f.startswith(PROFIL)) == 2
