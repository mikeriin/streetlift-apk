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
    assert set(cal['toutes_les_cibles']['par_date']) == {'debut', 'mi_saison', 'moins_4_semaines'}
    assert len(cal['toutes_les_cibles']['par_date']['debut']['deciles']) == 10
    assert len(cal['par_cible']['deciles']) == 10
    mj = d['criteres']['2_mauvais_jour_isole']
    assert 'apparie' in mj['methode'] and 'saisons_divergentes' in mj['detail']
    sec = d['criteres']['7_securite']['detail']['b_validateur']['vues']
    assert set(sec) == set(ca.VUES_SECURITE)
    assert {'koach', 'temoin'} <= set(d['secondaires']['ecart_effort'])
    assert 'duree' not in t1 and 'horodatage' not in t1
    # Reprise : une saison = un fichier dans le dossier de travail.
    dossier = next((tmp_path / 'w1').rglob('config.json')).parent
    assert sum(1 for f in os.listdir(str(dossier)) if f.startswith(PROFIL)) == 2


def test_vider_manquees_et_vues_realisees():
    """Lot KR1 : `vider_manquees` vide les seules séances non servies, sans
    toucher les blocs d'entrée ; `securite_saison` publie la saison réalisée
    classée contre le plan initial (`realise`) et contre le plan écrit aux
    mêmes séances manquées (`realise_apparie`)."""
    from banc import donnees, meneur
    from banc import criteres_moteur as cm
    saison = cm._saison(PROFIL, 'reference', 6)
    sessions = saison['sessions']
    faites = sessions[::2]
    items = [{'slotId': 'x', 'exerciseId': 'y', 'sets': 1}]

    class Tour(object):
        servi = [(g, bi, wb, di, items) for (g, bi, wb, di, _) in faites]

    blocs = saison['blocks']
    avant = json.dumps(blocs, sort_keys=True)
    vide = ca.vider_manquees(saison, Tour(), blocs)
    assert json.dumps(blocs, sort_keys=True) == avant
    faits = set((g, bi, wb, di) for (g, bi, wb, di, _) in faites)
    for (g, bi, wb, di, _) in sessions:
        for w in vide[bi]['pass2']['weeks']:
            if w['weekIndex'] == wb:
                for d in w['days']:
                    if d['dayIndex'] == di:
                        ecrit = [x for x in blocs[bi]['pass2']['weeks'] if x['weekIndex'] == wb][0]
                        ecrit = [x for x in ecrit['days'] if x['dayIndex'] == di][0]
                        attendu = ecrit['items'] if (g, bi, wb, di) in faits else []
                        assert d['items'] == attendu
    # Vues de la saison réalisée sur une vraie saison courte.
    opts = {'sans_planificateur': False, 'trajectoires': 40, 'defaut_modele': None}
    ca.appliquer_parametres(dict(ca.options_de([]), **opts))
    infos = donnees.catalogue_infos()
    pol = ca.politique(dict(ca.options_de([]), **opts), 0)
    tour = meneur.simuler(saison, infos, pol, 'a', 0)
    s = ca.securite_saison(saison, infos, tour, pol)
    for vue in ('realise', 'realise_apparie'):
        assert set(s[vue]) == {'deja_initial', 'aggrave', 'introduit'}
        assert isinstance(s[vue + '_exemples'], list)


def test_retour_a_l_ecrit_apres_un_bloc_interrompu():
    """Lot KR1 (cause des 9 constats « introduits » du critère 7 sur les
    90 600 saisons du couple) : après un bloc interrompu par une
    re-planification (changement de discipline), l'indice de semaine de la
    saison doit pointer sur la semaine SERVIE ; la hausse de volume des
    ischios de la semaine 11 (4 séries pour 3,5 admises, séance manquée de la
    même semaine comptée à son volume écrit) est un « retour à l'écrit »,
    pas un constat introduit par Koach. Avant : classée « introduit »."""
    from banc import donnees, meneur
    from banc import criteres_moteur as cm
    opts = ca.options_de([])
    ca.appliquer_parametres(opts)
    saison = cm._saison('autres_08_crossfit_intermediaire', 'changement_discipline', None)
    assert saison['blockWeeks'][:3] == [0, 5, 8]
    infos = donnees.catalogue_infos()
    pol = ca.politique(opts, 87)
    tour = meneur.simuler(saison, infos, pol, 'a', 87)
    s = ca.securite_saison(saison, infos, tour, pol)
    assert s['servi_tests_faits']['introduit'] == {} and s['servi_tests_faits']['aggrave'] == {}
    assert s['servi_tests_faits']['retour_ecrit'] == {'volume_trop_vite': 1}
    assert s['realise_apparie']['introduit'] == {} and s['realise_apparie']['aggrave'] == {}
