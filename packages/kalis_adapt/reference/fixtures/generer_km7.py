# -*- coding: utf-8 -*-
"""Fixture de parité du lot KM7 (Koach 1.0.9) pour le portage Dart
(`test/koach_km7_test.dart`, parité à 1e-9) : scénarios synthétiques de
`tests/test_km7.py` (bilan versé sans être appliqué, douleur gardée,
séance suivante, remplaçants, remplacement versé, transfert) déroulés pas à
pas, avec les sorties attendues de chaque pas.

    python3 fixtures/generer_km7.py              # écrit ../test/fixtures/km7/km7.json
    python3 fixtures/generer_km7.py --verifier   # échoue s'il n'est pas à jour

(depuis `packages/kalis_adapt/reference/`). Même codage que `generer.py`
(JSON compact, clés triées, flottants en `repr`). Données synthétiques
seulement (C17.33).
"""
import argparse
import copy
import gzip
import json
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(ICI))

from fixtures.generer import propre  # noqa: E402
from koach.moteur import Koach, faits_du_bilan  # noqa: E402

with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
    PARAMS = json.load(f)
with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
    FICHES = json.load(f)['exercices']
with gzip.open(os.path.join(ICI, '..', 'donnees', 'catalogue_infos.json.gz'), 'rt', encoding='utf-8') as f:
    INFOS = json.load(f)['exercises']

DL = 'sl-dips-leste'
SQ = 'mu-back-squat-barre-basse'
DIPS = 'sw-dips-barres-paralleles'
GRILLES = {DL: {'pas': 1.25, 'minimum': 0.0, 'halteres': False},
           SQ: {'pas': 2.5, 'minimum': 20.0, 'halteres': False},
           'sl-dips-barre-fixe-leste': {'pas': 1.25, 'minimum': 0.0, 'halteres': False}}
BAS = {'overall': 1, 'sleepHours': 5, 'energy': 2, 'pains': []}
PROFIL = {'niveau': 2, 'sexe': 'male', 'poids_kg': 75.0,
          'declares': {DL: ['one_rm_kg', 40.0], SQ: ['one_rm_kg', 140.0]}, 'zones_fragiles': []}
ROLES = {'j5.1': 'main', 'j5.2': 'main'}
ZONES = {DL: [{'elbow': 1.0, 'shoulder': 0.5}, ['elbow']], SQ: [{'knee': 1.0}, []]}


def items_j5():
    return [{'slotId': 'j5.1', 'exerciseId': DL, 'kind': 'work', 'sets': 6, 'repsLow': 3, 'repsHigh': 3,
             'targetFlames': 7, 'restSeconds': 0, 'groupId': 'g1', 'format': 'e2mom',
             'technique': {'kind': 'emom', 'intervalSeconds': 120, 'intervals': 6}},
            {'slotId': 'j5.2', 'exerciseId': SQ, 'kind': 'work', 'sets': 4, 'repsLow': 5, 'repsHigh': 5,
             'targetFlames': 7, 'restSeconds': 180}]


class Scenario(object):
    """Koach dont chaque pas (événement, plan, remplaçants, posterior) est
    noté avec sa sortie."""

    def __init__(self, nom):
        self.nom = nom
        self.k = Koach(PARAMS, FICHES, copy.deepcopy(PROFIL))
        self.etapes = []

    def observe(self, e):
        e = copy.deepcopy(e)
        self.k.observe(copy.deepcopy(e))
        self.etapes.append({'op': 'observe', 'e': e})

    def plan(self, c):
        c = copy.deepcopy(c)
        r = self.k.plan(copy.deepcopy(c))
        self.etapes.append({'op': 'plan', 'c': c, 'sortie': propre(r), 'raisons': propre(self.k.explain())})
        return r

    def remplacants(self, demande):
        r = self.k.remplacants(INFOS, copy.deepcopy(demande))
        self.etapes.append({'op': 'remplacants', 'demande': copy.deepcopy(demande), 'sortie': propre(r)})
        return r

    def posterior(self):
        self.etapes.append({'op': 'posterior', 'sortie': propre(self.k.posterior())})

    def json(self):
        return {'nom': self.nom, 'profil': PROFIL, 'etapes': self.etapes}


def seance(s, jour, bilan, items=None, series=True, faites=None, zones=None, groupes=None):
    s.observe({'type': 'seance_debut', 'jour': jour, 'bilan': bilan,
               'contexte': {'semaine': jour // 7, 'genre': 'accumulation'}})
    c = {'horizon': 'seance', 'items': items or items_j5(), 'grilles': GRILLES, 'zones': zones or {},
         'roles': ROLES}
    if groupes is not None:
        c['groups'] = groupes
    r = s.plan(c)
    if series:
        for it in r['items']:
            for i in range(int(it['sets'])):
                cb = s.plan({'horizon': 'serie', 'item': it, 'index': i, 'faites': []})
                if cb is None:
                    break
                reps = cb.get('repsHigh') or 5
                if faites is not None:
                    reps = faites(it, i, reps)
                s.observe({'type': 'serie', 'serie': {
                    'exerciseId': it['exerciseId'], 'slotId': it['slotId'], 'setIndex': i, 'kind': 'work',
                    'reps': reps, 'externalLoadKg': cb.get('loadKg'), 'flames': 7, 'failed': False,
                    'target': {'repsLow': cb.get('repsLow'), 'repsHigh': cb.get('repsHigh'), 'flames': 7},
                    'restSeconds': 120}})
    s.observe({'type': 'seance_fin', 'jour': jour, 'douleurs': None, 'seance': {'sets': []}})
    return r


def histoire(s):
    for j in (0, 2, 4, 7, 9):
        seance(s, j, {'overall': 4})


def faites_moins(it, i, reps):
    return max(1, reps - 1) if it['exerciseId'] == DL else reps


def scenarios():
    out = []
    # 1-3 : bilan bas appliqué, versé sans être appliqué, seuls faits.
    for nom, b in (('applique', BAS), ('non_applique', dict(BAS, applique=False)),
                   ('faits', faits_du_bilan(BAS))):
        s = Scenario('bilan_' + nom)
        histoire(s)
        seance(s, 11, b, faites=faites_moins)
        s.posterior()
        seance(s, 14, {'overall': 4}, series=False)
        s.posterior()
        out.append(s)
    # 4 : douleur pendant « Garder l'écrit ».
    s = Scenario('douleur_non_applique')
    histoire(s)
    seance(s, 11, dict(BAS, pains=[{'zone': 'elbow', 'intensity': 4}], applique=False), zones=ZONES)
    s.posterior()
    out.append(s)
    # 5 : remplaçants (aperçus) puis remplacement versé et transfert.
    s = Scenario('remplacants')
    histoire(s)
    base = {'exerciseId': DL, 'item': items_j5()[0], 'role': 'main',
            'raison': {'code': 'pas_de_materiel', 'materiel': ['ceinture de lest']}, 'niveau': 2}
    s.remplacants(base)
    s.remplacants(dict(base, materiel=['barres parallèles', 'disques', 'anneaux']))
    s.remplacants(dict(base, role='accessory', par_etiquette=40, limite=200))
    s.remplacants(dict(base, raison={'code': 'douleur', 'zone': 'wrist_hand'}, role='accessory',
                       par_etiquette=40, limite=200))
    s.remplacants(dict(base, raison={'code': 'trop_dur'}, par_etiquette=40, limite=200))
    s.remplacants({'exerciseId': SQ, 'item': items_j5()[1], 'role': 'accessory',
                   'raison': {'code': 'douleur', 'zone': 'knee'}, 'niveau': 2, 'limite': 200, 'par_etiquette': 40})
    s.remplacants(dict(base, lieu='exterieur', exclus=['cd-dips-russes'], materiel=None))
    s.posterior()
    items = items_j5()
    items[0] = dict(items[0], exerciseId=DIPS, remplace={'exerciseId': DL, 'raison': 'pas_de_materiel'})
    seance(s, 11, None, items=items,
           groupes=[{'groupId': 'g1', 'format': 'e2mom', 'rounds': 6, 'intervalSeconds': 120}])
    s.posterior()
    items = items_j5()
    items[0] = dict(items[0], exerciseId='sl-dips-barre-fixe-leste',
                    remplace={'exerciseId': DL, 'raison': 'autre'})
    seance(s, 14, None, items=items)
    s.posterior()
    out.append(s)
    # 6 : séance close sans série, bilan non appliqué (forme versée à la fin).
    s = Scenario('sans_serie_non_applique')
    histoire(s)
    seance(s, 11, dict(BAS, applique=False), series=False)
    s.posterior()
    out.append(s)
    # 7 : transfert pendant la conduite sous douleur puis hors conduite.
    s = Scenario('transfert_douleur')
    histoire(s)
    seance(s, 11, {'overall': 4, 'pains': [{'zone': 'elbow', 'intensity': 6}]})
    zones = {'sl-dips-barre-fixe-leste': [{'elbow': 1.0}, []], DL: [{'elbow': 1.0}, []]}
    for j in (14, 18):
        items = items_j5()
        items[0] = dict(items[0], exerciseId='sl-dips-barre-fixe-leste',
                        remplace={'exerciseId': DL, 'raison': 'autre'})
        seance(s, j, {'overall': 4, 'pains': []}, items=items, zones=zones)
    s.posterior()
    out.append(s)
    return [x.json() for x in out]


def ecrire():
    from fixtures.generer import texte
    return texte(propre({'version': PARAMS.get('version'), 'scenarios': scenarios()}))


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('--verifier', action='store_true')
    a = ap.parse_args(argv)
    # Hors de `fixtures/` : `generer.py --verifier` n'y admet que ses propres
    # fichiers (comme `test/fixtures/km2c2/`).
    chemin = os.path.join(ICI, '..', '..', 'test', 'fixtures', 'km7', 'km7.json')
    texte = ecrire()
    if a.verifier:
        with open(chemin, encoding='utf-8') as f:
            if f.read() != texte:
                print('test/fixtures/km7/km7.json pas à jour')
                return 1
        print('test/fixtures/km7/km7.json à jour')
        return 0
    with open(chemin, 'w', encoding='utf-8') as f:
        f.write(texte)
    print('écrit', chemin)
    return 0


if __name__ == '__main__':
    sys.exit(main())
