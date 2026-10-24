# -*- coding: utf-8 -*-
"""Lot KM1c4 (Koach 1.0.5) : conduite sous douleur et rampe du réalisé,
cas construits à la main (CHANGEMENTS_1_0_5.md, contrat § 8.4 bis).

1. zone sensible douze semaines après un épisode, avec ou sans arrêt ;
   budget hebdomadaire d'exposition de la zone (séries des mouvements qui la
   provoquent, échauffement compris) ;
2. sortie progressive : la rampe continue après la fenêtre tant que le permis
   n'atteint pas l'écrit ; pas de retour d'un coup à l'écrit ;
3. rampe du réalisé : référence = dernière semaine de charge fermée exposée
   (séances manquées à 0, jamais comptées à l'écrit), +1 série ou +20 % ;
   départ à la moitié de l'habitude (charge chronique sur quatre semaines),
   quatre séries sans habitude ; pas de hausse si la zone a été signalée
   dans la semaine ; répartition au prorata des séances restantes ; pas de
   vrai test sur la zone ;
3 bis. rampe du réalisé après une coupure : une zone sans douleur connue qui
   n'a rien reçu depuis `coupure_j` jours alors qu'une séance manquée
   l'écrivait repart de la moitié de son habitude ; rien sans coupure ni
   séance manquée ; la zone sensible l'emporte ;
4. aucune hausse de charge sur un exercice qui sollicite (≥ 0,5) une zone
   signalée au-dessus du seuil dans les sept derniers jours ;
5. élargissement « rien de spécial » : `test_rupture.py`.
"""
import copy
import json
import os

from koach.moteur import Koach
from koach.securite import Gardefous

ICI = os.path.dirname(os.path.abspath(__file__))
with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']

S = PARAMS['securite']
SH = 'shoulder'
ZONES = {'sw-dips-barres-paralleles': ({SH: 1.0, 'elbow': 0.5}, {SH}),
         'sw-pompe': ({SH: 0.5, 'wrist_hand': 0.5}, {'wrist_hand'}),
         'sl-dips-leste': ({SH: 1.0, 'wrist_hand': 0.5}, {SH, 'elbow'})}


def koach():
    return Koach(PARAMS, FICHES, {'niveau': 1, 'sexe': 'male', 'poids_kg': 75.0, 'declares': {},
                                  'zones_fragiles': []})


def dips(slot, sets, kind='work', ex='sw-dips-barres-paralleles'):
    return {'slotId': slot, 'exerciseId': ex, 'kind': kind, 'sets': sets, 'repsLow': 6, 'repsHigh': 10,
            'targetFlames': 7}


def ouvrir(k, jour, bilan=None, genre='accumulation', **contexte):
    c = {'semaine': jour // 7, 'genre': genre}
    c.update(contexte)
    k.garde.avancer(jour)
    if bilan is not None and bilan.get('pains') is not None:
        k.garde.noter_seance(jour, bilan['pains'], posee=True)
    k.seances.ouvrir(jour, bilan, c)


def seance(k, jour, items, douleurs=None, faites=True, faites_max=None, **contexte):
    """Ouvre, sert et ferme une séance ; [douleurs] signalées au bilan ;
    [faites_max] : séries faites au plus (le reste non fait) ; renvoie les
    items servis."""
    bilan = {'overall': 4, 'pains': douleurs} if douleurs is not None else None
    ouvrir(k, jour, bilan, **contexte)
    out = k.seances.prescrire(copy.deepcopy(items), {}, ZONES, {})
    sets = []
    if faites:
        for it in out:
            for i in range(it['sets']):
                if faites_max is not None and len(sets) >= faites_max:
                    break
                sets.append({'exerciseId': it['exerciseId'], 'slotId': it['slotId'], 'setIndex': i,
                             'kind': it.get('kind'), 'reps': it.get('repsHigh'), 'flames': 7, 'failed': False,
                             'target': {'flames': 7}})
    k.seances.fermer({'sets': sets})
    return out


def expo(out, zone=SH):
    return sum(it['sets'] for it in out if zone in ZONES[it['exerciseId']][1])


# ----------------------------------------------------------------------
# Zone sensible
# ----------------------------------------------------------------------
def test_zone_sensible_douze_semaines_avec_ou_sans_arret():
    g = Gardefous(PARAMS, 1)
    g.noter_seance(10, [{'zone': SH, 'intensity': 2}])
    assert not g.sensible(SH)                       # gêne sous le seuil : pas d'épisode
    g.noter_seance(12, [{'zone': SH, 'intensity': 4}])
    g.avancer(12)
    assert g.sensible(SH) and g.episode(SH) == (12, 12)
    assert g.zones[SH].arret_depuis is None         # un seul signalement : pas d'arrêt
    g.avancer(12 + S['sensible_j'])
    assert g.sensible(SH)
    g.avancer(13 + S['sensible_j'])
    assert not g.sensible(SH)
    # Un nouveau signalement fort prolonge la fenêtre (même épisode à moins
    # de `arret_levee_j` jours, sinon nouvel épisode).
    g.noter_seance(13 + S['sensible_j'], [{'zone': SH, 'intensity': 3}])
    assert g.sensible(SH) and g.episode(SH)[0] == 13 + S['sensible_j']


def test_gene_recente():
    g = Gardefous(PARAMS, 1)
    g.noter_seance(10, [{'zone': SH, 'intensity': 4}])
    g.noter_seance(11, [])
    g.avancer(10 + S['douleur_hausse_j'] - 1)
    assert g.gene_recente(SH) == 4
    g.avancer(10 + S['douleur_hausse_j'])
    assert g.gene_recente(SH) == 0


# ----------------------------------------------------------------------
# Règle 4 : aucune hausse de charge dans la semaine qui suit une gêne
# ----------------------------------------------------------------------
def test_pas_de_hausse_de_charge_apres_une_gene_dans_la_semaine():
    g = Gardefous(PARAMS, 1)
    g.noter_seance(10, [{'zone': 'wrist_hand', 'intensity': 4}])
    g.noter_seance(12, [])                           # « plus rien » au bilan
    g.avancer(12)
    assert g.active('wrist_hand') == 0
    cond = g.conduite({'wrist_hand': 0.5}, set(), depuis_jour=None)   # exercice jamais fait
    assert cond['sans_hausse'] and not cond['retire'] and cond['raison'] == 'douleur'
    assert cond['rir'] >= S['douleur_rir_bonus']
    cond = g.conduite({'wrist_hand': 0.4}, set(), depuis_jour=None)   # sollicitation faible
    assert not cond['sans_hausse']
    g.avancer(10 + S['douleur_hausse_j'])
    cond = g.conduite({'wrist_hand': 0.5}, set(), depuis_jour=None)
    assert not cond['sans_hausse']


# ----------------------------------------------------------------------
# Règles 1 et 3 : budget de la zone sensible, rampe du réalisé
# ----------------------------------------------------------------------
def test_budget_sans_arret_depart_moitie_de_l_habitude():
    k = koach()
    # Quatre semaines de charge à 8 séries d'épaule : habitude 8.
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    # Douleur 4 au bilan : dips retirés (sollicitation 1 ≥ contrainte forte).
    assert expo(seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])) == 0
    # Un signalement, pas d'arrêt ; la semaine suivante (plus de douleur au
    # bilan) la zone est sensible, aucune semaine de charge exposée depuis
    # l'épisode (les semaines d'avant ne servent pas de référence) → départ :
    # floor(0,5 × 8) = 4 séries.
    assert k.garde.zones[SH].arret_depuis is None and k.garde.sensible(SH)
    out = seance(k, 36, [dips('d', 10)], douleurs=[])
    assert expo(out) == 4
    assert any(r['code'] == 'koach.reprise_dose' for r in k.seances.raisons)
    # Puis +1 ou +20 % par semaine de charge sur le réalisé : 5, 6, 7.
    for j, attendu in ((43, 5), (50, 6), (57, 7)):
        assert expo(seance(k, j, [dips('d', 10)], douleurs=[])) == attendu


def test_budget_depart_quand_la_zone_n_a_pas_ete_exposee_depuis_l_episode():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    # Épisode signalé avant toute série de la semaine 4 ; la semaine 4 fermée
    # sans exposition (dips retirés : douleur 4 ≥ `douleur_forte_contrainte`
    # sur sollicitation 1) ; semaine 5 : départ à la moitié de l'habitude.
    out = seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    assert expo(out) == 0
    # Semaine 5 : séance au bilan sans douleur mais exposition faite à 2
    # séries seulement (séance écourtée) ; semaine 6 : référence = réalisé 2
    # → 3, pas le départ (4) ni l'écrit.
    out = seance(k, 36, [dips('d', 2)], douleurs=[])
    assert expo(out) == 2
    out = seance(k, 43, [dips('d', 10)], douleurs=[])
    assert expo(out) == 3


def test_budget_sans_habitude_quatre_series():
    """Épisode dès la première semaine : aucune habitude mesurée → départ à
    `reprise_dose_sans_habitude` (4) ; le retour gradué au volume (groupes
    majeurs, +2 séries sur une semaine à 0) peut être plus strict encore :
    le plus bas des deux tient."""
    k = koach()
    out = seance(k, 1, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    assert expo(out) == 0
    assert k.seances._budget_zone_semaine(SH) == (S['reprise_dose_sans_habitude'], False)   # dès l'épisode (sans habitude)
    ouvrir(k, 8, {'overall': 4, 'pains': []})
    assert k.seances.budget_semaine[SH] == S['reprise_dose_sans_habitude']
    out = seance(k, 8, [dips('d', 10)], douleurs=[])
    assert 0 < expo(out) <= S['reprise_dose_sans_habitude']


def test_reference_realisee_pas_l_ecrit_apres_des_seances_manquees():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 4
    # Semaine 6 : séance servie mais rien de fait (écrit 10, réalisé 0).
    ouvrir(k, 43, {'overall': 4, 'pains': []})
    k.seances.prescrire([dips('d', 10)], {}, ZONES, {})
    k.seances.fermer({'sets': []})
    # Semaine 7 : la semaine 6 fermée sans exposition renvoie à la dernière
    # semaine exposée (5 : 4 séries) → 5, pas 12 (écrit + 20 %) ni 10.
    out = seance(k, 50, [dips('d', 10)], douleurs=[])
    assert expo(out) == 5
    # Quatre semaines de plus sans exposition : la fenêtre de recherche
    # (`rampe_zone_semaines_max` semaines avant la semaine vide) est
    # dépassée → départ (4).
    for j in (57, 64, 71, 78):
        ouvrir(k, j, {'overall': 4, 'pains': []})
        k.seances.prescrire([dips('d', 10)], {}, ZONES, {})
        k.seances.fermer({'sets': []})
    assert expo(seance(k, 85, [dips('d', 10)], douleurs=[])) == 4


def test_pas_de_hausse_si_la_zone_a_ete_signalee_dans_la_semaine():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    # Semaine 5 : départ 4 (semaine du signalement sans exposition).
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 4
    # Gêne 3 signalée au jour 40 (≤ `douleur_seuil` : pas de retrait, pas
    # d'arrêt à moins de 14 jours ; > `reprise_douleur_max`).
    seance(k, 40, [], douleurs=[{'zone': SH, 'intensity': 3}])
    # Semaine 6, trois jours après cette gêne : pas de hausse (4, pas 5).
    assert expo(seance(k, 43, [dips('d', 10)], douleurs=[])) == 4
    # Semaine 7, plus de gêne depuis plus de sept jours : la rampe reprend.
    assert expo(seance(k, 50, [dips('d', 10)], douleurs=[])) == 5


def test_semaine_du_signalement_tenue_sans_hausse():
    """La semaine du premier signalement ne sert de référence que si c'est
    la semaine précédente, et sans hausse (une partie de son exposition a
    été faite avant le signalement) : un signalement de 3 (sans retrait) en
    fin de semaine après huit séries donne huit séries la semaine suivante
    (tenue), pas neuf ; et jamais par la fenêtre de recherche : après une
    semaine vide qui suit le signalement, départ (4), pas huit."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    assert expo(seance(k, 29, [dips('d', 8)])) == 8
    seance(k, 33, [], douleurs=[{'zone': SH, 'intensity': 3}])
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 8
    assert expo(seance(k, 43, [dips('d', 10)], douleurs=[])) == 9
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    assert expo(seance(k, 29, [dips('d', 8)])) == 8
    seance(k, 33, [], douleurs=[{'zone': SH, 'intensity': 3}])
    # Semaine 5 fermée sans exposition de la zone (autre séance).
    seance(k, 36, [{'slotId': 'r', 'exerciseId': 'mu-rowing-barre-pronation', 'kind': 'work', 'sets': 3,
                    'repsLow': 8, 'repsHigh': 10, 'targetFlames': 7}], douleurs=[])
    assert expo(seance(k, 43, [dips('d', 10)], douleurs=[])) == 4


def test_budget_reparti_au_prorata_des_seances_restantes_echauffement_compris():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    # Semaine 5 : permis 4 ; deux séances écrites à 5 séries (dont une
    # d'échauffement) : 2 aujourd'hui (4 × 5/10), 2 à la suivante. Le
    # travail passe avant l'échauffement : l'échauffement ne prend que ce que
    # le travail laisse (ici rien : retiré, avec la zone épuisée).
    items = [dips('e', 1, kind='warmup'), dips('d', 4)]
    out = seance(k, 36, items, douleurs=[], reste_semaine=[items])
    assert expo(out) == 2 and len(out) == 1 and out[0]['kind'] == 'work' and out[0]['sets'] == 2
    assert any(r['code'] == 'koach.douleur_retrait' and r['params']['cause'] == 'reprise_dose'
               and r['params']['zone'] == SH and r['params']['exercice'] == 'sw-dips-barres-paralleles'
               for r in k.seances.raisons)
    out = seance(k, 38, items, douleurs=[])
    assert expo(out) == 2
    # Plus rien : retrait, avec la raison.
    out = seance(k, 40, items, douleurs=[])
    assert expo(out) == 0
    # Permis 5 sur deux séances à 1 + 2 : l'échauffement a sa place (1 + 2
    # aujourd'hui, 5 × 3/6 = 2,5 → 3 ; reste 2 à la suivante).
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    seance(k, 29, [dips('d', 10)], douleurs=[{'zone': SH, 'intensity': 4}])
    items = [dips('e', 1, kind='warmup'), dips('d', 2)]
    out = seance(k, 36, items, douleurs=[], reste_semaine=[items])
    assert [(it['kind'], it['sets']) for it in out] == [('warmup', 1), ('work', 2)]


def test_pas_de_vrai_test_sur_une_zone_sous_rampe():
    k = koach()
    ex = 'sl-dips-leste'
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 6, ex=ex)])
    seance(k, 29, [dips('d', 6, ex=ex)], douleurs=[{'zone': SH, 'intensity': 4}])
    s = k.seances
    appels = []
    vt0 = s._vrai_test

    def vt(servi, plan, piste):
        appels.append(servi['exerciseId'])
        return vt0(servi, plan, piste)
    s._vrai_test = vt
    seance(k, 36, [dips('d', 6, ex=ex)], douleurs=[])
    assert SH in s.budget_semaine and appels == []


# ----------------------------------------------------------------------
# Règle 2 : sortie progressive
# ----------------------------------------------------------------------
def test_sortie_progressive_apres_la_fenetre():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    # Pendant la fenêtre, l'athlète ne fait que 4 séries par semaine (le
    # permis monte, le réalisé reste à 4 : la référence est le réalisé) ;
    # l'écrit est à 12.
    j = 36
    while j <= 29 + S['sensible_j']:
        out = seance(k, j, [dips('d', 12)], douleurs=[], faites_max=4)
        assert 4 <= expo(out) <= 5, (j, expo(out))
        j += 7
    assert k.garde.sensible(SH) is False or j - 29 > S['sensible_j']
    # Fenêtre finie : la rampe continue depuis le réalisé (4 → 5 → 6 → …)
    # jusqu'à l'écrit, jamais un retour d'un coup à 12.
    attendu = 4
    while attendu < 12:
        attendu = max(attendu + 1, int(attendu * (1 + S['reprise_dose_hausse'])))
        out = seance(k, j, [dips('d', 12)], douleurs=[])
        assert not k.garde.sensible(SH)
        assert expo(out) == min(attendu, 12), (j, attendu, expo(out))
        j += 7
    assert SH not in k.seances.rampe_zone
    out = seance(k, j, [dips('d', 12)], douleurs=[])
    assert expo(out) == 12


# ----------------------------------------------------------------------
# Relecture KM1c4 (B1, B2, M1, m1, m10) : arrêt levé, semaines manquées,
# journal long, deux zones, plancher, rejeu, règle 4 de bout en bout
# ----------------------------------------------------------------------
def test_apres_un_arret_leve_rien_d_avant_l_arret_ne_sert_de_reference():
    """B1 : gêne 3 puis arrêt (épisode de 14 jours), levée ; les semaines
    exposées avant l'arrêt (dans l'épisode) ne servent pas de référence : la
    zone repart de la moitié de l'habitude."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    g = k.garde
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 3}])    # 8 servies (3 : rien retiré)
    seance(k, 36, [dips('d', 10)], douleurs=[{'zone': SH, 'intensity': 3}])   # tenue 8 (semaine du signalement)
    seance(k, 43, [dips('d', 10)], douleurs=[{'zone': SH, 'intensity': 3}])   # 43 − 29 ≥ 14 : arrêt
    assert g.zones[SH].arret_depuis == 43
    assert expo(seance(k, 50, [dips('d', 10)], douleurs=[])) == 0            # à l'arrêt : dips retirés
    # Levée au jour 57 (43 + 14), semaine de charge commencée le jour même :
    # reprise ; départ : floor(0,5 × 8) = 4 (1.0.4 : 4 aussi), pas 8 + 1 de
    # la semaine 6 (exposée pendant l'épisode, avant l'arrêt).
    out = seance(k, 57, [dips('d', 10)], douleurs=[])
    assert not k.garde.arret(SH) and k.seances.budget_semaine[SH] == 4 and 0 < expo(out) <= 4
    assert expo(seance(k, 64, [dips('d', 10)], douleurs=[])) == 5


def test_semaines_entierement_manquees_comptent_zero():
    """B2 : une semaine sans aucune séance fermée mais versée comme manquée
    (contexte) est une semaine de charge à exposition 0 ; après plus de
    `rampe_zone_semaines_max` semaines manquées, départ (4), pas la dernière
    semaine exposée + 1."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 4
    assert expo(seance(k, 43, [dips('d', 10)], douleurs=[])) == 5
    # Semaines 7 à 10 manquées (versées à la séance du jour 78).
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in range(7, 11)]
    out = seance(k, 78, [dips('d', 10)], douleurs=[], manquees=manquees)
    assert expo(out) == 4
    # Une seule semaine manquée : la dernière exposée (5) sert → 6.
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    seance(k, 36, [dips('d', 10)], douleurs=[])
    seance(k, 43, [dips('d', 10)], douleurs=[])
    out = seance(k, 57, [dips('d', 10)], douleurs=[],
                 manquees=[{'semaine': 7, 'genre': 'accumulation', 'items': [dips('d', 10)]}])
    assert expo(out) == 6


def test_journal_long_habitude_complete():
    """M1 : l'habitude et les semaines connues ne dépendent pas des 20
    derniers jours de séance : six séances par semaine pendant quatre
    semaines (24 séances), habitude 12 → départ 6."""
    k = koach()
    for w in range(4):
        for j in range(6):
            seance(k, 7 * w + 1 + j, [dips('d', 2)])
    seance(k, 29, [dips('d', 2)], douleurs=[{'zone': SH, 'intensity': 4}])
    seance(k, 36, [dips('d', 10)], douleurs=[])
    assert k.seances.budget_semaine[SH] == 6


def test_deux_zones_sensibles_et_plancher():
    """Deux zones sous permis : chaque mouvement est borné par la plus
    stricte ; `reprise_dose_min` : jamais sous 1."""
    k = koach()
    ex = 'sl-dips-leste'    # provoque épaule et coude
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 2, ex=ex)])
    seance(k, 29, [dips('d', 2, ex=ex)], douleurs=[{'zone': SH, 'intensity': 4}, {'zone': 'elbow', 'intensity': 4}])
    out = seance(k, 36, [dips('d', 10, ex=ex)], douleurs=[])
    # Habitude 2 → floor(1) = 1 pour chacune ; plancher 1.
    assert k.seances.budget_semaine == {SH: 1, 'elbow': 1}
    assert expo(out) == 1 and expo(out, 'elbow') == 1


def test_rejeu_redonne_l_etat_de_la_rampe():
    """Déterminisme : `rejouer` redonne `budget_semaine`, `rampe_zone`,
    `ecrit_zone`, `dose_zone`, le permis du jour et la réserve de
    l'échauffement (séances versées par l'API `observe` / `plan`)."""
    from koach.moteur import rejouer

    def jouer(k, jour, items, douleurs=None, reste=None):
        bilan = {'overall': 4, 'pains': douleurs} if douleurs is not None else None
        k.observe({'type': 'seance_debut', 'jour': jour, 'bilan': bilan, 'poids_kg': None,
                   'contexte': {'semaine': jour // 7, 'genre': 'accumulation', 'reste_semaine': reste or []}})
        r = k.plan({'horizon': 'seance', 'items': items, 'grilles': {}, 'zones': ZONES, 'roles': {}})
        sets = []
        for it in r['items']:
            for i in range(it['sets']):
                sets.append({'exerciseId': it['exerciseId'], 'slotId': it['slotId'], 'setIndex': i,
                             'kind': it.get('kind'), 'reps': it.get('repsHigh'), 'flames': 7, 'failed': False,
                             'target': {'flames': 7}})
        k.observe({'type': 'seance_fin', 'jour': jour, 'douleurs': [], 'seance': {'sets': sets}})
        return r['items']

    k = koach()
    for w in range(4):
        jouer(k, 7 * w + 1, [dips('d', 8)])
    jouer(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    items = [dips('e', 1, kind='warmup'), dips('d', 4)]
    jouer(k, 36, items, douleurs=[], reste=[items])
    out = jouer(k, 38, items, douleurs=[])
    assert expo(out) == 2
    journal = json.loads(json.dumps(k.journal))
    r = rejouer(PARAMS, FICHES, k.profil, journal)
    a, b = k.seances, r.seances
    assert a.budget_semaine == {SH: 4} and a.rampe_zone == {SH}
    assert (a.budget_semaine, a.budget_zone, sorted(a.rampe_zone), a.ecrit_zone, a.dose_zone) == \
        (b.budget_semaine, b.budget_zone, sorted(b.rampe_zone), b.ecrit_zone, b.dose_zone)
    assert a.reserve_echauffement == b.reserve_echauffement


def test_regle_4_charge_servie_jamais_au_dessus_du_dernier_passage():
    """Règle 4 de bout en bout : charge servie ≤ dernier passage sur un
    exercice chargé qui sollicite la zone, après une gêne 4 signalée puis 0."""
    k = koach()
    ex = 'sl-dips-leste'
    s = k.seances
    t = k.modele.piste(ex)
    item = {'slotId': 'd', 'exerciseId': ex, 'kind': 'work', 'sets': 3, 'repsLow': 5, 'repsHigh': 5,
            'targetFlames': 7, 'loadBasis': 'external'}
    grilles = {ex: __import__('koach.seance', fromlist=['Grille']).Grille(1.25, 0.0, False)}
    # Trois séances à 20 kg (passages), puis gêne 4 à l'épaule un jour sans
    # séance de l'exercice, puis 0.
    for j in (1, 4, 8):
        ouvrir(k, j, {'overall': 4, 'pains': []})
        servi = s.prescrire([item], grilles, ZONES, {'d': 'main'})
        sets = [{'exerciseId': ex, 'slotId': 'd', 'setIndex': i, 'kind': 'work', 'reps': 5,
                 'externalLoadKg': 20.0, 'flames': 7, 'failed': False, 'target': {'flames': 7}} for i in range(3)]
        s.fermer({'sets': sets})
    assert s.mem(ex).charge_derniere == 20.0
    ouvrir(k, 10, {'overall': 4, 'pains': [{'zone': SH, 'intensity': 4}]})
    s.fermer({'sets': []})
    ouvrir(k, 12, {'overall': 4, 'pains': []})
    servi = s.prescrire([item], grilles, ZONES, {'d': 'main'})
    assert servi and s.plans['d']['cond']['sans_hausse']
    for i in range(3):
        cible = s.cible(servi[0], i, [])
        assert cible.get('externalLoadKg') is None or cible['externalLoadKg'] <= 20.0 + 1e-9


# ----------------------------------------------------------------------
# Règle 3 bis : rampe du réalisé après une coupure (séances manquées)
# ----------------------------------------------------------------------
def test_retour_apres_une_coupure_sans_douleur_connue():
    """Quatre semaines à 10 séries d'épaule, deux semaines manquées (versées
    au retour, 21 jours après la dernière séance), aucune douleur signalée :
    la zone repart de la moitié de son habitude (5), puis +1 ou +20 % par
    semaine, jusqu'à l'écrit (10) où elle sort de la rampe."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in (4, 5)]
    out = seance(k, 43, [dips('d', 10)], manquees=manquees)
    assert expo(out) == 5 and k.seances.budget_semaine[SH] == 5
    assert k.seances.retour_zone[SH] == (6, 5)
    assert [expo(seance(k, j, [dips('d', 10)])) for j in (50, 57, 64, 71)] == [6, 7, 8, 9]
    out = seance(k, 78, [dips('d', 10)])
    assert expo(out) == 10 and SH not in k.seances.retour_zone and SH not in k.seances.budget_semaine


def test_pas_de_rampe_de_retour_sans_coupure_ni_seance_manquee():
    """Une séance manquée sans coupure de la zone (retour sept jours après la
    dernière séance) : aucun permis. Une coupure de 21 jours sans séance
    manquée versée (le plan ne prévoyait rien) : aucun permis non plus, le
    plan gouverne (seule la règle A6.1, 80 % des séries, s'applique)."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    out = seance(k, 29, [dips('d', 10)],
                 manquees=[{'semaine': 3, 'genre': 'accumulation', 'items': [dips('d', 10)]}])
    assert expo(out) == 10 and not k.seances.retour_zone
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    out = seance(k, 43, [dips('d', 10)])
    assert not k.seances.retour_zone and SH not in k.seances.budget_semaine
    assert expo(out) == 8  # A6.1


def test_retour_sans_habitude_et_zone_jamais_exposee():
    """Sans exposition connue dans la fenêtre (journal qui commence par les
    semaines manquées d'une zone déjà exposée une fois) : départ
    `reprise_dose_sans_habitude` (4) ; une zone jamais exposée dans le
    journal n'entre pas dans la rampe (le plan l'introduit)."""
    k = koach()
    seance(k, 1, [dips('d', 1)])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in (1, 2, 3, 4)]
    out = seance(k, 36, [dips('d', 10)], manquees=manquees)
    # Habitude sur les semaines 1 à 4 (fin = semaine 0 → semaines 0 seulement :
    # 1 série / 1 semaine) → moitié 0 → plancher ; départ = 1 ? Non : la
    # fenêtre finit à la semaine de la dernière exposition (0) : habitude
    # 1/1 = 1 → floor(0,5) = 0 → `reprise_dose_min` 1.
    assert expo(out) == 1 and k.seances.retour_zone[SH][1] == 1
    k = koach()
    seance(k, 1, [dips('p', 4, ex='sw-pompe')])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in (1, 2)]
    out = seance(k, 22, [dips('d', 10)], manquees=manquees)
    assert SH not in k.seances.retour_zone and expo(out) >= 8


def test_la_zone_sensible_l_emporte_sur_la_rampe_de_retour():
    """Une douleur signalée pendant la rampe de retour : la zone devient
    sensible, la rampe de la zone sensible la remplace (tenue au réalisé de
    la semaine de charge précédente dans la semaine du signalement)."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in (4, 5)]
    assert expo(seance(k, 43, [dips('d', 10)], manquees=manquees)) == 5
    out = seance(k, 50, [dips('d', 10)], douleurs=[{'zone': SH, 'intensity': 3}])
    assert SH not in k.seances.retour_zone and k.seances.budget_semaine[SH] == 5 and expo(out) == 5


def test_le_vrai_test_reste_possible_sous_la_rampe_de_retour():
    """La rampe de retour (sans douleur connue) n'interdit pas le vrai test :
    `_vrai_test` est consulté sur un mouvement dont la zone est en retour
    (A6.1 l'interdit déjà la semaine même du retour : séance hors de cette
    semaine ici)."""
    k = koach()
    ex = 'sl-dips-leste'
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 6, ex=ex)])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 6, ex=ex)]} for w in (4, 5)]
    seance(k, 43, [dips('d', 6, ex=ex)], manquees=manquees)
    s = k.seances
    assert SH in s.retour_zone
    appels = []
    vt0 = s._vrai_test

    def vt(servi, plan, piste):
        appels.append(servi['exerciseId'])
        return vt0(servi, plan, piste)
    s._vrai_test = vt
    seance(k, 51, [dips('d', 6, ex=ex)])
    assert SH in s.budget_semaine and SH in s.retour_zone and appels == [ex]


def test_la_rampe_de_retour_est_suspendue_en_semaine_verrouillee():
    """Une semaine verrouillée (affûtage, test, compétition…) n'ouvre ni
    n'applique la rampe de retour : au retour d'une coupure en semaine de
    compétition, l'écrit est servi (A6.1 seule) et, la coupure consommée,
    aucune rampe ne s'ouvre ensuite (limite dite au contrat) ; une semaine
    d'affûtage au milieu d'une rampe ouverte la suspend sans la fermer."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    manquees = [{'semaine': w, 'genre': 'accumulation', 'items': [dips('d', 10)]} for w in (4, 5)]
    out = seance(k, 43, [dips('d', 10)], manquees=manquees, genre='competition')
    assert not k.seances.retour_zone and SH not in k.seances.budget_semaine
    assert expo(out) == 8  # A6.1 seule (semaine du retour)
    assert expo(seance(k, 50, [dips('d', 10)])) == 8 and not k.seances.retour_zone   # A6.1 (fenêtre de 7 jours)
    assert expo(seance(k, 57, [dips('d', 10)])) == 10 and not k.seances.retour_zone
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 10)])
    assert expo(seance(k, 43, [dips('d', 10)], manquees=manquees)) == 5
    out = seance(k, 50, [dips('d', 10)], genre='taper')
    assert SH in k.seances.retour_zone and SH not in k.seances.budget_semaine and expo(out) == 8  # A6.1 seule
    # Reprise de la rampe : référence = dernière semaine de charge (5), pas
    # l'affûtage (allégé, 8) → 6.
    assert expo(seance(k, 57, [dips('d', 10)])) == 6 and SH in k.seances.retour_zone

