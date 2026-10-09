# -*- coding: utf-8 -*-
"""Règles de sécurité de kalis_adapt 0.3.1 reprises par Koach 1.0 (poignet,
zones fragiles du profil, endurance, techniques, coupure, surmenage, renvoi,
tendons, test en semaine verrouillée) : un cas construit à la main par règle,
déclenchement et non-déclenchement (SECURITE_KOACH_COUVERTURE.md)."""
import copy
import json
import os

import pytest

from koach.moteur import Koach
from koach.securite import Gardefous
from koach.seance import Grille, equivalent_standard, reduire

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']

POUSSEE_SOL = {'type': 'reps', 'contraintes': {'poignet': 'moyenne'}, 'materiel': ['aucun (sol)']}
POUSSEE_PARALLETTES = {'type': 'reps', 'contraintes': {'poignet': 'moyenne'}, 'materiel': ['parallettes']}
DIPS_LESTE = {'type': 'charge', 'contraintes': {'poignet': 'moyenne'}, 'materiel': ['barres parallèles']}
W = 'wrist_hand'


def garde(niveau=1, fragiles=None):
    return Gardefous(PARAMS, niveau, fragiles)


def koach(niveau=1, fragiles=None):
    return Koach(PARAMS, FICHES, {'niveau': niveau, 'sexe': 'male', 'poids_kg': 75.0, 'declares': {},
                                  'zones_fragiles': fragiles or []})


def ouvrir(k, jour, bilan=None, genre='accumulation', **contexte):
    c = {'semaine': jour // 7, 'genre': genre}
    c.update(contexte)
    k.garde.avancer(jour)
    k.seances.ouvrir(jour, bilan, c)


def arret_poignet(g):
    """Poignet à l'arrêt au jour 7 (deux signalements à 5/10 sur 7 jours)."""
    g.noter_seance(0, [{'zone': W, 'intensity': 5}])
    g.noter_seance(7, [{'zone': W, 'intensity': 5}])
    assert g.zones[W].arret_depuis == 7


# ----------------------------------------------------------------------
# A7.2 : zones fragiles du profil
# ----------------------------------------------------------------------
def test_zones_fragiles_regle_0_3_1():
    g = garde(fragiles=[{'zone': 'elbow', 'since': 'over_12_months', 'discomfort': 1},
                        {'zone': 'lower_back', 'since': 'months_3_to_12', 'discomfort': 0},
                        {'zone': 'knee', 'since': None, 'discomfort': 2},
                        {'zone': 'shoulder', 'since': 'past_resolved', 'discomfort': 0},
                        'hip'])
    assert g.fragiles == ('hip', 'knee', 'lower_back')
    assert g.fragile({'knee': 0.5}) == 'knee'
    assert g.fragile({'knee': 0.4, 'elbow': 1.0}) is None


def _bornes(fragiles, part_ref=None):
    k = koach(fragiles=fragiles)
    s = k.seances
    ouvrir(k, 10)
    ex = 'mu-developpe-couche-barre'
    t = k.modele.piste(ex)
    s.mem(ex).schemas[('s1', 5)] = (100.0, False)
    cond = k.garde.conduite({'shoulder': 0.5}, set())
    plan = {'cond': cond, 'fragile': cond['fragile'], 'role': 'main', 'sans_hausse': False}
    item = {'slotId': 's1', 'exerciseId': ex}
    return s._bornes_hausse(ex, item, 110.0, plan, t, Grille(2.5, 20.0), 5, 0), s.raisons


def test_hausse_reduite_zone_fragile_du_profil():
    charge, raisons = _bornes([{'zone': 'shoulder', 'since': 'under_6_weeks', 'discomfort': 0}])
    assert charge == 102.5          # 5 % × 0,5 : un cran
    assert any(r['code'] == 'koach.zone_fragile' for r in raisons)
    charge, raisons = _bornes([])
    assert charge == 105.0          # 5 % sans antécédent
    assert not any(r['code'] == 'koach.zone_fragile' for r in raisons)


def test_schema_nouveau_zone_fragile_sans_part_de_repetitions():
    k = koach(fragiles=['shoulder'])
    s = k.seances
    ouvrir(k, 10)
    ex = 'mu-developpe-couche-barre'
    t = k.modele.piste(ex)
    s.mem(ex).charges_reussies.append((5, 100.0, 8))
    item = {'slotId': 's1', 'exerciseId': ex}
    for fragile, attendu in ((True, 105.0), (False, 120.0)):
        cond = k.garde.conduite({'shoulder': 0.5 if fragile else 0.0}, set())
        plan = {'cond': cond, 'fragile': cond['fragile'], 'role': 'main', 'sans_hausse': False}
        # 8 rép. faites -> 4 rép. : +10 % × (1 + 4 × 2,5 %) sans antécédent ;
        # +5 % et aucune part de répétitions sur zone fragile.
        assert s._bornes_hausse(ex, item, 130.0, plan, t, Grille(2.5, 20.0), 4, 0) == attendu


def test_surcharge_plafonnee_sur_zone_fragile():
    def raisons(fragiles):
        k = koach(fragiles=fragiles)
        s = k.seances
        ouvrir(k, 10)
        ex = 'mu-developpe-couche-barre'
        t = k.modele.piste(ex)
        t.mesures = 1
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'repsLow': 3, 'repsHigh': 3,
                'percentOfOneRm': 1.1, 'targetFlames': 7}
        servi = s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({'shoulder': 1.0}, set())}, {'s1': 'main'})
        s.cible(servi[0], 0, [])
        return [r for r in s.raisons if r['code'] == 'koach.zone_fragile' and r['params']['cause'] == 'surcharge']
    assert raisons(['shoulder'])
    assert not raisons([])


# ----------------------------------------------------------------------
# A4 : poignet
# ----------------------------------------------------------------------
def test_poignet_premiere_gene_appui_neutre_conseille():
    g = garde()
    g.noter_seance(10, [{'zone': W, 'intensity': 3}])
    c = g.conduite({W: 0.5}, {W}, fiche=POUSSEE_SOL)
    assert c['appui_neutre'] == 3 and c['sans_hausse'] and c['dose_plafonnee'] and not c['retire']
    # Déjà sur appui neutre : rien à conseiller.
    assert g.conduite({W: 0.5}, {W}, fiche=POUSSEE_PARALLETTES)['appui_neutre'] is None
    # Gêne à 2/10 : pas de « première gêne » (mais poignet sensible).
    g2 = garde()
    g2.noter_seance(10, [{'zone': W, 'intensity': 2}])
    c2 = g2.conduite({W: 0.5}, {W}, fiche=POUSSEE_SOL)
    assert c2['appui_neutre'] is None and not c2['sans_hausse'] and c2['dose_plafonnee']


def test_poignet_arret_charge_externe_retiree():
    g = garde()
    arret_poignet(g)
    g.avancer(15)   # arrêt toujours en cours, rien signalé depuis 8 jours : pas « chaud »
    assert g.arret(W) and not g.poignet_chaud()
    c = g.conduite({W: 0.5}, set(), fiche=DIPS_LESTE)
    assert c['retire'] and c['raison'] == 'poignet_charge'
    # L'échauffement reste ; un appui au poids du corps reste au premier palier.
    assert not g.conduite({W: 0.5}, set(), fiche=DIPS_LESTE, echauffement=True)['retire']
    c = g.conduite({W: 0.5}, set(), fiche=POUSSEE_PARALLETTES)
    assert not c['retire'] and c['series'] == PARAMS['securite']['reprise_depart']


def test_poignet_chaud_tout_retire_sauf_appui_neutre_modere():
    g = garde()
    arret_poignet(g)
    g.avancer(8)
    assert g.poignet_chaud()
    c = g.conduite({W: 0.5}, set(), fiche=POUSSEE_SOL, echauffement=True)
    assert c['retire'] and c['raison'] == 'poignet_chaud'
    assert g.conduite({W: 1.0}, set(), fiche=POUSSEE_PARALLETTES)['retire']
    assert not g.conduite({W: 0.5}, set(), fiche=POUSSEE_PARALLETTES)['retire']
    # Sans arrêt du poignet : rien.
    assert not garde().conduite({W: 1.0}, set(), fiche=POUSSEE_SOL)['retire']


def test_poignet_sensible_dose_plafonnee():
    g = garde(fragiles=[{'zone': W, 'since': None, 'discomfort': 2}])
    c = g.conduite({W: 0.5}, {W}, fiche=POUSSEE_SOL)
    assert c['dose_plafonnee'] and c['poignet_sensible']
    assert not g.conduite({W: 0.5}, set(), fiche=POUSSEE_SOL)['dose_plafonnee']
    assert not garde().conduite({W: 0.5}, {W}, fiche=POUSSEE_SOL)['dose_plafonnee']


def test_dose_plafonnee_dans_la_seance():
    k = koach(fragiles=[W])
    s = k.seances
    ouvrir(k, 10)
    ex = 'cd-pompe-un-bras'
    t = k.modele.piste(ex)
    t.mesures = 1
    item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 60,
            'targetFlames': 5}
    servi = s.prescrire([item], {}, {ex: ({W: 0.5}, {W})}, {'s1': 'main'})
    assert any(r['code'] == 'koach.poignet_dose' for r in s.raisons)
    plan = s.plans['s1']
    assert plan['dose_plafonnee'] and not s._mesure_utile(servi[0], plan, t)
    s.mem(ex).reps_seance = 4
    assert s.cible(servi[0], 1, [])['repsHigh'] <= 4
    plan['dose_plafonnee'] = False
    assert s.cible(servi[0], 1, [])['repsHigh'] > 4


# ----------------------------------------------------------------------
# A2.2 : renvoi vers un professionnel
# ----------------------------------------------------------------------
def test_renvoi_premiere_seance_puis_chaque_semaine():
    g = garde()
    arret_poignet(g)
    assert g.renvois() == [W]       # séance du jour 7
    g.avancer(9)
    assert g.renvois() == []        # même semaine d'arrêt
    g.avancer(14)
    assert g.renvois() == [W]       # semaine suivante
    assert garde().renvois() == []


# ----------------------------------------------------------------------
# A6.1 : reprise après coupure, toute la semaine du retour
# ----------------------------------------------------------------------
def test_coupure_vaut_la_semaine_du_retour():
    k = koach()
    s = k.seances
    s.jours_seances = [0, 20]
    assert s._coupure(24) == 20
    assert s._coupure(28) == 0
    s.jours_seances = [0, 3]
    assert s._coupure(20) == 17
    assert s._coupure(10) == 0


# ----------------------------------------------------------------------
# A6.2 : alerte de surmenage
# ----------------------------------------------------------------------
def test_surmenage_alerte_et_lignes_retirees():
    k = koach()
    s = k.seances
    ex = 'mu-back-squat-barre-basse'
    k.modele.piste(ex)
    valeurs = iter([5.0, 4.9, 4.9])     # deux séances à −9,5 % de la référence
    s._forme = lambda ex_id: next(valeurs)
    for jour in (1, 5, 9):
        ouvrir(k, jour)
        s.plans = {'s1': {'role': 'main', 'type': 'charge'}}
        s._formes({(ex, 's1'): [{'kind': 'work', 'reps': 5}]})
    mem = s.mem(ex)
    assert mem.alerte_jour == 9 and len(mem.forme) == 1
    ouvrir(k, 11)
    assert s._surmenage(ex, mem, 'main', 5) == 3
    assert any(r['code'] == 'koach.surmenage' for r in s.raisons)
    assert s._surmenage(ex, mem, 'secondary', 5) == 5
    ouvrir(k, 11, genre='deload')
    assert s._surmenage(ex, mem, 'main', 5) == 5
    ouvrir(k, 17)
    assert s._surmenage(ex, mem, 'main', 5) == 5
    # Baisse de 3 % seulement : pas d'alerte.
    k2 = koach()
    s2 = k2.seances
    k2.modele.piste(ex)
    valeurs2 = iter([5.0, 4.97, 4.97])
    s2._forme = lambda ex_id: next(valeurs2)
    for jour in (1, 5, 9):
        ouvrir(k2, jour)
        s2.plans = {'s1': {'role': 'main', 'type': 'charge'}}
        s2._formes({(ex, 's1'): [{'kind': 'work', 'reps': 5}]})
    assert s2.mem(ex).alerte_jour is None


# ----------------------------------------------------------------------
# A6.5 : test xRM en semaine verrouillée
# ----------------------------------------------------------------------
def test_test_xrm_semaine_verrouillee_au_plus_la_charge_ecrite():
    def charge(genre):
        k = koach(niveau=2)
        s = k.seances
        ouvrir(k, 10, genre=genre)
        ex = 'mu-back-squat-barre-basse'
        t = k.modele.piste(ex)
        t.mesures = 1
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'test', 'sets': 1, 'repsLow': 3, 'repsHigh': 3,
                'startLoadKg': 20.0, 'test': {'kind': 'rep_max', 'targetRir': 1}}
        servi = s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({}, set())}, {'s1': 'main'})
        return s.cible(servi[0], 0, [])['loadKg']
    assert charge('test') == 20.0
    assert charge('accumulation') > 20.0


# ----------------------------------------------------------------------
# A9.1 : temps total des tenues en bras tendus
# ----------------------------------------------------------------------
def test_tendons_temps_total_de_l_emplacement():
    def haut(series, total):
        k = koach()
        s = k.seances
        ouvrir(k, 10)
        ex = 'cs-back-lever'
        t = k.modele.piste(ex)
        t.mesures = 1
        mem = s.mem(ex)
        mem.sec_max = 8
        if total is not None:
            mem.sec_slot['s1'] = total
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': series, 'secondsLow': 5,
                'secondsHigh': 9, 'targetFlames': 6}
        servi = s.prescrire([item], {}, {ex: ({}, set())}, {'s1': 'main'})
        return s.cible(servi[0], 0, [])['secondsHigh'], s.raisons
    sans, _ = haut(4, None)
    avec, raisons = haut(4, 24)
    # Dernière séance : 24 s au total ; 4 × 9 = 36 > max(⌊24 × 1,15⌋, 25) = 27
    # -> chaque tenue à ⌊27 / 4⌋ = 6 s.
    assert (sans, avec) == (9, 6)
    assert any(r['code'] == 'koach.tendon' and r['params'].get('cause') == 'total' for r in raisons)
    trois, _ = haut(3, 24)
    assert trois == 9               # 3 × 9 = 27 ≤ 27 : rien


# ----------------------------------------------------------------------
# A9.2 : techniques
# ----------------------------------------------------------------------
def test_technique_au_dessus_du_niveau():
    def servi(niveau, technique, bilan=None, fragiles=None):
        k = koach(niveau=niveau, fragiles=fragiles)
        s = k.seances
        ouvrir(k, 10, bilan=bilan)
        ex = 'mu-back-squat-barre-basse'
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 4, 'repsLow': 5, 'repsHigh': 5,
                'targetFlames': 6, 'technique': technique,
                'autoregulation': [{'kind': 'backoff_from_top_set'}, {'kind': 'stop_at_rir'}]}
        out = s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({'knee': 0.5}, set())}, {'s1': 'main'})
        return out[0], s.raisons
    tsb = {'kind': 'top_set_backoff', 'backoffRepsLow': 8, 'backoffRepsHigh': 8}
    it, r = servi(0, tsb)
    assert it['technique'] is None and it['autoregulation'] == [{'kind': 'stop_at_rir'}]
    assert any(x['code'] == 'koach.technique_retenue' and x['params']['cause'] == 'niveau' for x in r)
    it, r = servi(1, tsb)
    assert it['technique'] == tsb and not any(x['code'] == 'koach.technique_retenue' for x in r)
    # Technique qui intensifie, jour de bilan au palier 2.
    it, r = servi(2, {'kind': 'drop_set'}, bilan={'overall': 1})
    assert it['technique'] is None
    it, r = servi(2, {'kind': 'drop_set'})
    assert it['technique'] == {'kind': 'drop_set'}
    # Excentrique accentué sur zone fragile du profil.
    it, r = servi(2, {'kind': 'accentuated_eccentric'}, fragiles=['knee'])
    assert it['technique'] is None and r[-1]['params']['cause'] == 'antecedent'
    it, r = servi(2, {'kind': 'accentuated_eccentric'})
    assert it['technique'] == {'kind': 'accentuated_eccentric'}


def test_equivalent_standard():
    it = equivalent_standard({'sets': 5, 'repsLow': 3, 'repsHigh': 3,
                              'technique': {'kind': 'cluster', 'miniSets': 3, 'miniSetReps': 2}})
    assert (it['sets'], it['repsLow'], it['repsHigh'], it['technique']) == (5, 4, 4, None)
    it = equivalent_standard({'sets': 1, 'repsLow': 50, 'repsHigh': 50,
                              'technique': {'kind': 'density', 'totalRepsTarget': 50}})
    assert (it['sets'], it['repsLow'], it['repsHigh']) == (3, 12, 12)
    it = equivalent_standard({'sets': 3, 'repsLow': 6, 'repsHigh': 10, 'technique': {'kind': 'drop_set'}})
    assert (it['sets'], it['repsLow'], it['repsHigh']) == (3, 6, 10)


# ----------------------------------------------------------------------
# A2.3 et A10 : endurance
# ----------------------------------------------------------------------
def course(slot, ex, **kw):
    it = {'slotId': slot, 'exerciseId': ex, 'kind': 'work', 'sets': 1}
    it.update(kw)
    return it


def servir(k, items):
    return k.seances.prescrire(copy.deepcopy(items), {}, {}, {})


def test_reduire_comme_scaled():
    it = {'sets': 1, 'secondsLow': 1800, 'secondsHigh': 1800}
    assert reduire(it, 0.7) and it['secondsHigh'] == 1260
    it = {'sets': 6, 'distanceMeters': 400}
    assert reduire(it, 0.5) and it['sets'] == 3
    it = {'sets': 3, 'repsLow': 10, 'repsHigh': 15}
    assert reduire(it, 0.75) and (it['repsLow'], it['repsHigh']) == (7, 11)
    assert not reduire({'sets': 1, 'secondsHigh': 600}, 1.0)


def test_course_retiree_pendant_un_arret_du_bas_du_corps():
    k = koach()
    k.garde.noter_seance(0, [{'zone': 'knee', 'intensity': 5}])
    k.garde.noter_seance(7, [{'zone': 'knee', 'intensity': 5}])
    ouvrir(k, 8)
    out = servir(k, [course('r', 'ca-footing-endurance-fondamentale', secondsHigh=1800),
                     course('v', 'ca-rameur-endurance', secondsHigh=1200)])
    assert [i['exerciseId'] for i in out] == ['ca-rameur-endurance']
    assert any(r['code'] == 'koach.douleur_retrait' and r['params']['zone'] == 'knee' for r in k.seances.raisons)
    k2 = koach()
    ouvrir(k2, 8)
    assert len(servir(k2, [course('r', 'ca-footing-endurance-fondamentale', secondsHigh=1800)])) == 1


def test_endurance_reprise_apres_coupure():
    for ecart, attendu in ((3, 1800), (8, 1260), (15, 900)):
        k = koach()
        k.seances.jours_actifs = [20 - ecart]
        ouvrir(k, 20)
        out = servir(k, [course('r', 'ca-footing-endurance-fondamentale', secondsLow=1800, secondsHigh=1800),
                         course('m', 'mo-90-90-passif', secondsHigh=300)])
        assert out[0]['secondsHigh'] == attendu
        assert out[1]['secondsHigh'] == 300   # mobilité non réduite


def test_jour_sans_qualite_devient_facile_ou_retiree():
    k = koach()
    ouvrir(k, 20, bilan={'overall': 2})
    out = servir(k, [course('r', 'ca-fractionne-400m', sets=8, distanceMeters=400, targetFlames=8)])
    assert out[0]['exerciseId'] == 'ca-footing-endurance-fondamentale'
    assert out[0]['sets'] == 1 and out[0]['secondsHigh'] == 60 * int(8 * 400 / 2.6 // 60)
    assert out[0]['targetFlames'] == 1
    # Côtes : la course facile demande un matériel absent de l'écrit -> retirée.
    k = koach()
    ouvrir(k, 20, bilan={'overall': 2})
    assert servir(k, [course('r', 'ca-sprint-cote', sets=6, distanceMeters=60)]) == []
    # Bon jour : servie telle quelle.
    k = koach()
    ouvrir(k, 20)
    out = servir(k, [course('r', 'ca-fractionne-400m', sets=8, distanceMeters=400, targetFlames=8)])
    assert out[0]['exerciseId'] == 'ca-fractionne-400m' and out[0]['sets'] == 8


def test_jour_sans_bilan_tres_bas_cardio_raccourci():
    k = koach()
    ouvrir(k, 20, bilan={'overall': 1})
    out = servir(k, [course('v', 'ca-rameur-endurance', secondsLow=1200, secondsHigh=1200)])
    assert out[0]['secondsHigh'] == 840
    k = koach()
    ouvrir(k, 20, bilan={'overall': 2})
    out = servir(k, [course('v', 'ca-rameur-endurance', secondsLow=1200, secondsHigh=1200)])
    assert out[0]['secondsHigh'] == 1200


def test_jour_sans_course_trop_dure():
    k = koach()
    k.seances.courses = [(18, 1800.0, 9, 5)]   # notée 4 flammes au-dessus de la cible
    k.seances.jours_actifs = [18]
    ouvrir(k, 20)
    out = servir(k, [course('r', 'ca-course-seuil-tempo', secondsHigh=1500, targetFlames=7)])
    assert out[0]['exerciseId'] == 'ca-footing-endurance-fondamentale'
    k = koach()
    k.seances.courses = [(18, 1800.0, 6, 5)]
    k.seances.jours_actifs = [18]
    ouvrir(k, 20)
    out = servir(k, [course('r', 'ca-course-seuil-tempo', secondsHigh=1500, targetFlames=7)])
    assert out[0]['exerciseId'] == 'ca-course-seuil-tempo'


def test_sortie_bornee_a_la_plus_longue_course_du_mois():
    k = koach()
    k.seances.courses = [(5, 1000.0, 4, 4), (10, 900.0, 4, 4), (15, 800.0, 4, 4)]
    k.seances.jours_actifs = [5, 10, 15, 19]
    ouvrir(k, 20)
    out = servir(k, [course('r', 'ca-sortie-longue', secondsLow=1800, secondsHigh=1800, targetFlames=4)])
    assert out[0]['secondsHigh'] <= 1100
    assert any(r['code'] == 'koach.course_bornee' for r in k.seances.raisons)
    # Deux courses seulement dans la fenêtre : pas de borne.
    k = koach()
    k.seances.courses = [(10, 900.0, 4, 4), (15, 800.0, 4, 4)]
    k.seances.jours_actifs = [10, 15, 19]
    ouvrir(k, 20)
    out = servir(k, [course('r', 'ca-sortie-longue', secondsLow=1800, secondsHigh=1800, targetFlames=4)])
    assert out[0]['secondsHigh'] == 1800


def test_conditionnement_mis_a_l_echelle_apres_jours_durs():
    k = koach()
    k.seances.jours_durs = [18, 19]
    k.seances.jours_actifs = [18, 19]
    ouvrir(k, 20)
    out = servir(k, [course('w', 'cf-burpee', sets=3, repsLow=20, repsHigh=20, targetFlames=8)])
    assert (out[0]['repsHigh'], out[0]['targetFlames']) == (15, 7)
    k = koach()
    k.seances.jours_durs = [19]
    k.seances.jours_actifs = [18, 19]
    ouvrir(k, 20)
    out = servir(k, [course('w', 'cf-burpee', sets=3, repsLow=20, repsHigh=20, targetFlames=8)])
    assert (out[0]['repsHigh'], out[0]['targetFlames']) == (20, 8)


def test_fatigue_croisee_apres_course_dure():
    items = [course('a', 'mu-back-squat-barre-basse', repsLow=5, repsHigh=5, targetFlames=7),
             course('b', 'mu-developpe-couche-barre', repsLow=5, repsHigh=5, targetFlames=7)]
    k = koach()
    k.seances.jours_course_dure = [19]
    k.seances.jours_actifs = [19]
    ouvrir(k, 20)
    out = servir(k, items)
    assert [i['targetFlames'] for i in out] == [6, 7]
    k = koach()
    k.seances.jours_course_dure = [17]
    k.seances.jours_actifs = [17]
    ouvrir(k, 20)
    assert [i['targetFlames'] for i in servir(k, items)] == [7, 7]


def test_historique_endurance_lu_a_la_fermeture():
    k = koach()
    ouvrir(k, 20)
    item = course('r', 'ca-fractionne-400m', sets=2, distanceMeters=400, targetFlames=6)
    servir(k, [item])
    k.seances.fermer({'sets': [
        {'exerciseId': 'ca-fractionne-400m', 'slotId': 'r', 'kind': 'work', 'seconds': 100,
         'distanceMeters': 400.0, 'flames': 9},
        {'exerciseId': 'ca-fractionne-400m', 'slotId': 'r', 'kind': 'work', 'seconds': 100,
         'distanceMeters': 400.0, 'flames': 8},
        {'exerciseId': 'cf-burpee', 'slotId': 'w', 'kind': 'work', 'reps': 20, 'flames': 8}]})
    s = k.seances
    assert s.courses == [(20, 200.0, 9, 6)]
    assert s.jours_course_dure == [20] and s.jours_durs == [20] and s.jours_actifs == [20]
    assert s._vitesse() == pytest.approx(4.0)


def test_test_xrm_apres_un_echec_pas_plus_lourd_que_le_dernier_passage():
    def charge(echec):
        k = koach(niveau=2)
        s = k.seances
        ouvrir(k, 10)
        ex = 'mu-back-squat-barre-basse'
        t = k.modele.piste(ex)
        t.mesures = 1
        mem = s.mem(ex)
        mem.charge_derniere = 20.0
        mem.echec = echec
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'test', 'sets': 1, 'repsLow': 3, 'repsHigh': 3,
                'test': {'kind': 'rep_max', 'targetRir': 1}}
        servi = s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({}, set())}, {'s1': 'main'})
        return s.cible(servi[0], 0, [])['loadKg']
    assert charge(True) == 20.0
    assert charge(False) > 20.0


def test_coupure_reduit_aussi_l_echauffement():
    for ecart, attendu in ((20, 4), (3, 5)):
        k = koach()
        k.seances.jours_seances = [30 - ecart]
        ouvrir(k, 30)
        ex = 'mu-back-squat-barre-basse'
        item = {'slotId': 'e', 'exerciseId': ex, 'kind': 'warmup', 'sets': 5, 'repsLow': 5, 'repsHigh': 5}
        out = k.seances.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({}, set())}, {})
        assert out[0]['sets'] == attendu


# ----------------------------------------------------------------------
# A7.2 : accessoires sans doublement, schéma changé (règle 4)
# ----------------------------------------------------------------------
def _borne(role='main', marque=None, hi=5, avant=None, charge=130.0):
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    ex = 'mu-developpe-couche-barre'
    t = k.modele.piste(ex)
    mem = s.mem(ex)
    if avant is not None:
        mem.schemas[('s1', hi)] = (avant, False)
    if marque is not None:
        mem.marques['s1'] = marque
    cond = k.garde.conduite({}, set())
    plan = {'cond': cond, 'fragile': None, 'role': role, 'sans_hausse': False}
    return s._bornes_hausse(ex, {'slotId': 's1', 'exerciseId': ex}, charge, plan, t, Grille(2.5, 20.0), hi, 0)


def test_hausse_des_accessoires_non_doublee():
    assert _borne(role='accessory', avant=100.0, charge=110.0) == 105.0
    assert _borne(role='main', avant=100.0, charge=110.0) == 105.0


def test_schema_change_au_meme_emplacement():
    # Dernière séance de l'emplacement à 8 rép. et 100 kg ; 5 rép. aujourd'hui :
    # 100 × 1,05 × (1 + 3 × 2,5 %) = 112,9 -> 112,5 sur la grille.
    assert _borne(marque=(100.0, 100.0, 8), hi=5) == 112.5
    # Même schéma que la dernière séance : la règle ne s'applique pas.
    assert _borne(marque=(100.0, 100.0, 5), hi=5) == 130.0
    # Base d'une semaine de charge retenue de préférence à la dernière charge.
    assert _borne(marque=(90.0, 100.0, 5), hi=8) == 92.5


# ----------------------------------------------------------------------
# Retour de coupure : ni test ni hausse
# ----------------------------------------------------------------------
def test_retour_de_coupure_ni_test_ni_hausse():
    k = koach(niveau=2)
    s = k.seances
    ex = 'mu-back-squat-barre-basse'
    t = k.modele.piste(ex)
    t.seances = 12
    t.mesures = 12
    t.dernier_test_jour = None
    jours = [3 * i for i in range(12)]          # 12 séances, puis 42 jours de coupure
    s.jours_seances = list(jours)
    mem = s.mem(ex)
    mem.jours = list(jours)
    mem.charge_max = 100.0
    mem.charge_derniere = 100.0
    mem.charges_reussies = [(j, 100.0, 5) for j in jours]
    mem.schemas[('s1', 5)] = (100.0, False)
    retour = jours[-1] + 42
    ouvrir(k, retour)
    item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 4, 'repsLow': 5, 'repsHigh': 5,
            'targetFlames': 7}
    out = s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({}, set())}, {'s1': 'main'})
    assert all(i.get('kind') != 'test' for i in out)
    plan = s.plans['s1']
    assert not s._mesure_utile(out[-1], plan, t)
    for i in range(out[-1]['sets']):
        c = s.cible(out[-1], i, [])
        assert c['loadKg'] <= 100.0 and not c.get('repere')
    # Deuxième semaine après le retour, exercice refait une seule fois :
    # toujours pas de mesure.
    s.jours_seances.append(retour)
    mem.jours.append(retour)
    ouvrir(k, retour + 10)
    s.prescrire([item], {ex: Grille(2.5, 20.0)}, {ex: ({}, set())}, {'s1': 'main'})
    assert s.coupure == 0 and not s._mesure_utile(item, s.plans['s1'], t)


def test_rampe_sans_barre_recente():
    k = koach(niveau=2)
    s = k.seances
    ouvrir(k, 100)
    ex = 'mu-back-squat-barre-basse'
    t = k.modele.piste(ex)
    t.seances = 5
    plan = {'grille': Grille(2.5, 20.0), 'rampe': (3, 1.0)}
    item = {'slotId': 's1.t', 'exerciseId': ex}
    s.mem(ex).charges_reussies = [(10, 100.0, 5)]
    assert s._rampe(item, 0, plan, t) is None
    s.mem(ex).charges_reussies = [(90, 100.0, 5)]
    assert s._rampe(item, 0, plan, t)['loadKg'] <= 110.0


# ----------------------------------------------------------------------
# Plafond des tenues sur la valeur centrale
# ----------------------------------------------------------------------
def test_plafond_des_tenues_sur_exp_mu():
    import math
    k = koach()
    s = k.seances
    ouvrir(k, 10)
    ex = 'cs-back-lever'
    t = k.modele.piste(ex)
    t.mesures = 1
    mu, sd = k.modele.capacite_du_jour(ex)
    item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'secondsLow': 5,
            'secondsHigh': 600, 'targetFlames': 6}
    out = s.prescrire([item], {}, {ex: ({}, set())}, {'s1': 'main'})
    haut = s.cible(out[0], 0, [])['secondsHigh']
    assert haut <= math.floor(PARAMS['securite']['tenue_part_max'] * math.exp(mu))
    assert math.floor(PARAMS['securite']['tenue_part_max'] * math.exp(mu + sd)) > haut


# ----------------------------------------------------------------------
# Semaine verrouillée : jamais au-dessus du dernier passage
# ----------------------------------------------------------------------
# ----------------------------------------------------------------------
# Essai N-of-1 du banc : bras sous les garde-fous
# ----------------------------------------------------------------------
class _Ctx(object):
    def __init__(self, semaine, ecrit=None):
        self.semaine = semaine
        self.sim_day = 7 * semaine
        self.genre_semaine = 'accumulation'
        self.ecrit = ecrit


def _bras(mod, grilles=None):
    from banc.extensions_koach import ControleDualBanc
    d = ControleDualBanc.__new__(ControleDualBanc)
    d.params = PARAMS
    d.journal = []
    d.semaine_vol = None
    d.genre = None
    d.modulation = lambda semaine: mod

    class _Pol(object):
        pass
    d.politique = _Pol()
    d.politique.grilles = grilles or {}
    return d


def test_bras_intensite_sous_les_garde_fous():
    ex = 'mu-back-squat-barre-basse'
    grille = Grille(2.5, 20.0)
    d = _bras({'bras': 'B', 'exerciseId': ex, 'intensite': 1.05, 'volume': 1.0}, {ex: grille})

    def servie(bilan=None, genre='accumulation'):
        k = koach(niveau=2)
        s = k.seances
        ouvrir(k, 14, bilan=bilan, genre=genre)
        t = k.modele.piste(ex)
        t.mesures = 3
        t.seances = 5
        mem = s.mem(ex)
        mem.charge_derniere = 40.0
        mem.schemas[('s1', 5)] = (40.0, False)
        item = {'slotId': 's1', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 5,
                'targetFlames': 6}
        out = s.prescrire([item], {ex: grille}, {ex: ({}, set())}, {'s1': 'main'})
        c = s.cible(out[0], 0, [])
        base = c['loadKg']
        return d.cible_serie(k, _Ctx(2), out[0], 0, c)['loadKg'], base
    assert servie(bilan={'overall': 2})[0] <= 40.0
    # Semaine verrouillée : le bras n'ajoute rien à ce que Koach sert.
    kg, base = servie(genre='deload')
    assert kg <= base
    # Jour normal : le bras monte au plus jusqu'à la borne de hausse (+5 % ou un cran).
    assert servie()[0] <= 42.5


def test_bras_volume_borne_par_la_reference():
    ex = 'mu-back-squat-barre-basse'
    d = _bras({'bras': 'A', 'exerciseId': ex, 'intensite': 1.0, 'volume': 1.1})
    ecrit = {'items': [{'slotId': 's%d' % i, 'exerciseId': ex, 'kind': 'work', 'sets': 4} for i in range(5)]}
    # Planification déjà à +15 % (5 × 4 = 20 séries de référence -> 23).
    planifie = [dict(it) for it in ecrit['items']]
    for it in planifie[:3]:
        it['sets'] = 5
    out = d.items_du_jour(None, _Ctx(3, ecrit), planifie)
    assert sum(it['sets'] for it in out) <= 1.15 * 20 + 1e-9
    # Sans planification : le bras ajoute jusqu'à +10 %.
    d2 = _bras({'bras': 'A', 'exerciseId': ex, 'intensite': 1.0, 'volume': 1.1})
    out = d2.items_du_jour(None, _Ctx(3, ecrit), [dict(it) for it in ecrit['items']])
    assert 20 < sum(it['sets'] for it in out) <= 22
