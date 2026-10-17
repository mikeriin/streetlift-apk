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
    assert k.seances._budget_zone_semaine(SH) == S['reprise_dose_sans_habitude']   # dès l'épisode (sans habitude)
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
    # Gêne 3 quatre jours plus tard (≤ `douleur_seuil` : pas de retrait, pas
    # d'arrêt à moins de 14 jours ; > `reprise_douleur_max`) : départ 4.
    assert expo(seance(k, 33, [dips('d', 10)], douleurs=[{'zone': SH, 'intensity': 3}])) == 4
    # Semaine 5, trois jours après cette gêne : pas de hausse (4, pas 5).
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 4
    # Semaine 6, plus de gêne depuis plus de sept jours : la rampe reprend.
    assert expo(seance(k, 43, [dips('d', 10)], douleurs=[])) == 5


def test_semaine_du_signalement_jamais_reference():
    """Ce qui a été fait avant le signalement, dans sa semaine, ne sert pas
    de référence : un signalement en fin de semaine après huit séries ne
    permet pas neuf séries la semaine suivante, mais le départ (4)."""
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    assert expo(seance(k, 29, [dips('d', 8)])) == 8
    seance(k, 33, [], douleurs=[{'zone': SH, 'intensity': 4}])
    assert expo(seance(k, 36, [dips('d', 10)], douleurs=[])) == 4


def test_budget_reparti_au_prorata_des_seances_restantes_echauffement_compris():
    k = koach()
    for w in range(4):
        seance(k, 7 * w + 1, [dips('d', 8)])
    seance(k, 29, [dips('d', 8)], douleurs=[{'zone': SH, 'intensity': 4}])
    # Semaine 5 : permis 4 ; deux séances écrites à 5 séries (dont une
    # d'échauffement) : 2 aujourd'hui (4 × 5/10), 2 à la suivante.
    items = [dips('e', 1, kind='warmup'), dips('d', 4)]
    out = seance(k, 36, items, douleurs=[], reste_semaine=[items])
    assert expo(out) == 2 and out[0]['kind'] == 'warmup' and out[0]['sets'] == 1 and out[1]['sets'] == 1
    out = seance(k, 38, items, douleurs=[])
    assert expo(out) == 2
    # Plus rien : retrait, avec la raison.
    out = seance(k, 40, items, douleurs=[])
    assert expo(out) == 0
    assert any(r['code'] == 'koach.douleur_retrait' and r['params']['cause'] == 'reprise_dose'
               for r in k.seances.raisons)


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
