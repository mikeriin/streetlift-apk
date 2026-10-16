#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Fixtures du banc Koach pour le portage Dart (lot KM2) : meneur de saison
(`banc/meneur.py`) et politique Koach complète de la campagne
(`banc/campagne.py`, `politique` : planification + surveillance + contrôle
dual + adhérence), rejouées par
`packages/kalis_bench/test/km2_banc_test.dart` (`kmSimuler` +
`PolitiqueKoach`).

    python3 fixtures/generer_banc_km2.py              # écrit les fichiers
    python3 fixtures/generer_banc_km2.py --verifier   # échoue s'ils ne sont pas à jour

(depuis `packages/kalis_adapt/reference/`). Déterministe : mêmes sources,
mêmes paramètres, mêmes fichiers. Sortie :
`packages/kalis_bench/test/fixtures/km2/<cle>__<scenario>__<verite>__<graine>.json`
(`.json.gz` au-delà de 300 Ko).

Contenu d'une fixture (JSON compact, clés triées, flottants en `repr`
Python, non-finis codés "inf", "-inf", "nan") :

* `config` : `cle`, `scenario`, `verite`, `graine`, `trajectoires`,
  `semaines` (troncature de la saison ou null), `briques` ;
* `saison` : `weeks` (après troncature) et `sessions` (nombre) ; le test
  Dart compare d'abord la saison entière de `kmReferenceSeason` au fichier
  `donnees/reference/<cle>.json.gz` lu par Python ;
* `tour` : `sets`, `estimates` (lignes du meneur, types JSON conservés),
  `servi` ([semaine, bloc, semaine du bloc, jour, items servis]),
  compteurs (`sessions_planned`, `sessions_done`, `pain_aggravations`,
  `pain_flares`, `endurance_overuse`, `worst_run_spike`), `gain`, `cap0`,
  `cap_fin`, `extra` ;
* `previsions` : prévisions de la planification (`PlanificationCampagne`) ;
* `journal_moteur` : `longueur` et `types` du journal de `Koach` (la façade
  Dart y ajoute les événements `reference` et `cibles`, que le test retire
  avant de comparer) ;
* `posterior` : `koach.posterior()` en fin de saison ;
* `journaux` : journaux des extensions du banc (`extensions_koach.journaux`,
  par nom de classe Python) ;
* `etats` : `extensions_koach.etats` (Surveillance : `etat_complet`,
  ControleDual, Adherence : `etat`) et `Planification` (`etat`).
"""
import argparse
import gzip
import json
import math
import os
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.dirname(ICI)
if RACINE not in sys.path:
    sys.path.insert(0, RACINE)

import numpy as np  # noqa: E402

from banc import campagne  # noqa: E402
from banc import criteres_moteur as cm  # noqa: E402
from banc import donnees, meneur  # noqa: E402
from banc import extensions_koach as ek  # noqa: E402
from banc import planification_banc as pb  # noqa: E402

SORTIE = os.path.normpath(os.path.join(RACINE, '..', '..', 'kalis_bench', 'test', 'fixtures', 'km2'))
VERSION_FORMAT = 1
TRAJECTOIRES = 40
SEMAINES = None              # saisons entières
SEUIL_GZIP = 300 * 1024

#: (profil, scénario, modèle de vérité, graine).
SAISONS = [
    ('street_07_avance_streetlifting_competition', 'reference', 'a', 0),
    ('street_01_debutant_complet', 'maladie', 'b', 1),
    ('autres_06_semi_marathon_intermediaire', 'reference', 'c', 0),
    ('street_16_specialisation_traction_lestee', 'reference', 'a', 1),
    ('street_07_avance_streetlifting_competition', 'changement_discipline', 'c', 1),
]


def _pur(x):
    """Valeur JSON pure : numpy -> Python, tuples -> listes, non-finis ->
    chaînes."""
    if isinstance(x, dict):
        return {str(k): _pur(v) for k, v in x.items()}
    if isinstance(x, (list, tuple)):
        return [_pur(v) for v in x]
    if isinstance(x, (set, frozenset)):
        return sorted(_pur(v) for v in x)
    if isinstance(x, np.bool_):
        return bool(x)
    if isinstance(x, np.integer):
        return int(x)
    if isinstance(x, np.floating):
        x = float(x)
    if isinstance(x, np.ndarray):
        return _pur(x.tolist())
    if isinstance(x, float):
        if math.isnan(x):
            return 'nan'
        if math.isinf(x):
            return 'inf' if x > 0 else '-inf'
        return x
    if x is None or isinstance(x, (bool, int, str)):
        return x
    raise TypeError('non codable : %r' % (type(x),))


def _texte(x):
    return json.dumps(x, sort_keys=True, separators=(',', ':'), ensure_ascii=False, allow_nan=False)


def nom_de(cle, scenario, verite, graine):
    return '%s__%s__%s__%d' % (cle, scenario, verite, graine)


def fixture(cle, scenario, verite, graine, trajectoires=TRAJECTOIRES, semaines=SEMAINES):
    opts = {'sans_planificateur': False, 'trajectoires': trajectoires, 'defaut_modele': None}
    infos = donnees.catalogue_infos()
    saison = cm._saison(cle, scenario, semaines)
    pol = campagne.politique(opts, graine)
    tour = meneur.simuler(saison, infos, pol, verite, graine)
    plan = None
    for x in pol.koach.extensions:
        if isinstance(x, pb.PlanificationBanc):
            plan = x
    etats = ek.etats(pol)
    if plan is not None:
        etats['Planification'] = plan.etat()
    journaux = ek.journaux(pol)
    return _pur({
        'format': 'km2_banc',
        'version_format': VERSION_FORMAT,
        'commande': 'python3 fixtures/generer_banc_km2.py (depuis packages/kalis_adapt/reference/)',
        'tolerance': 1e-9,
        'config': {'cle': cle, 'scenario': scenario, 'verite': verite, 'graine': graine,
                   'trajectoires': trajectoires, 'semaines': semaines,
                   'briques': ['planification', 'surveillance', 'dual', 'adherence']},
        'saison': {'weeks': saison['weeks'], 'sessions': len(saison['sessions'])},
        'tour': {
            'sets': tour.sets,
            'estimates': tour.estimates,
            'servi': [[g, bi, wb, di, items] for (g, bi, wb, di, items) in tour.servi],
            'sessions_planned': tour.sessions_planned,
            'sessions_done': tour.sessions_done,
            'pain_aggravations': tour.pain_aggravations,
            'pain_flares': tour.pain_flares,
            'endurance_overuse': tour.endurance_overuse,
            'worst_run_spike': tour.worst_run_spike,
            'gain': tour.gain,
            'cap0': tour.cap0,
            'cap_fin': tour.cap_fin,
            'extra': tour.extra,
        },
        'previsions': plan.previsions if plan is not None else [],
        'journal_moteur': {'longueur': len(pol.koach.journal),
                           'types': [e.get('type') for e in pol.koach.journal]},
        'posterior': pol.koach.posterior(),
        'journaux': journaux,
        'etats': etats,
    })


def ecrire(obj, nom, dossier):
    texte = _texte(obj).encode('utf-8')
    for ext in ('.json', '.json.gz'):
        ancien = os.path.join(dossier, nom + ext)
        if os.path.exists(ancien):
            os.remove(ancien)
    if len(texte) > SEUIL_GZIP:
        chemin = os.path.join(dossier, nom + '.json.gz')
        # mtime=0 : octets déterministes.
        with open(chemin, 'wb') as f:
            with gzip.GzipFile(filename='', mode='wb', fileobj=f, mtime=0) as g:
                g.write(texte)
    else:
        chemin = os.path.join(dossier, nom + '.json')
        with open(chemin, 'wb') as f:
            f.write(texte)
    return chemin


def lire(nom, dossier):
    for ext in ('.json', '.json.gz'):
        chemin = os.path.join(dossier, nom + ext)
        if os.path.exists(chemin):
            if ext == '.json.gz':
                with gzip.open(chemin, 'rb') as f:
                    return f.read()
            with open(chemin, 'rb') as f:
                return f.read()
    return None


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--verifier', action='store_true', help='échoue si une fixture n\'est pas à jour')
    ap.add_argument('--sortie', default=SORTIE)
    ap.add_argument('--seulement', default=None, help='nom de fixture (cle__scenario__verite__graine)')
    a = ap.parse_args(argv)
    os.makedirs(a.sortie, exist_ok=True)
    ecarts = 0
    for (cle, scenario, verite, graine) in SAISONS:
        nom = nom_de(cle, scenario, verite, graine)
        if a.seulement and a.seulement != nom:
            continue
        obj = fixture(cle, scenario, verite, graine)
        if a.verifier:
            ancien = lire(nom, a.sortie)
            if ancien is None or ancien != _texte(obj).encode('utf-8'):
                print('pas à jour : %s' % nom)
                ecarts += 1
            else:
                print('à jour : %s' % nom)
        else:
            chemin = ecrire(obj, nom, a.sortie)
            print('%s (%d séries, %d estimations)' % (os.path.relpath(chemin), len(obj['tour']['sets']),
                                                       len(obj['tour']['estimates'])))
    return 1 if ecarts else 0


if __name__ == '__main__':
    sys.exit(main())
