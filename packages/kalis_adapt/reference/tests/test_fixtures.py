# -*- coding: utf-8 -*-
"""Fixtures de parité de Koach 1.0 (`fixtures/`, lot KM1 → portage Dart
KM2) : à jour, rejouables par un `Koach` neuf (exactement ce que fera le test
de parité Dart), déterministes, et état du modèle recalculé depuis le seul
journal des événements."""
import copy
import json
import math
import os
import subprocess
import sys

import numpy as np
import pytest

REF = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIX = os.path.join(REF, 'fixtures')
sys.path.insert(0, REF)
sys.path.insert(0, FIX)

import generer  # noqa: E402
from koach import numerique as nu  # noqa: E402
from koach.moteur import Koach, rejouer  # noqa: E402
from koach.planification import Planification  # noqa: E402

TOL = 1e-9
MOTEURS = ['moteur_%d.json' % sc['n'] for sc in generer.SCENARIOS]
PLANIFS = ['planification_%d.json' % pc['n'] for pc in generer.PLANIFICATIONS]


def _lire(nom):
    with open(os.path.join(FIX, nom), encoding='utf-8') as f:
        return json.load(f)


def _ecarts(a, b, chemin='', out=None):
    """Écarts entre deux valeurs JSON : nombres à TOL près (relatif au-delà
    de 1), le reste à l'identique (entiers et flottants confondus)."""
    if out is None:
        out = []
    num_a = isinstance(a, (int, float)) and not isinstance(a, bool)
    num_b = isinstance(b, (int, float)) and not isinstance(b, bool)
    if num_a and num_b:
        if abs(a - b) > TOL * max(1.0, abs(a), abs(b)):
            out.append((chemin, a, b))
    elif isinstance(a, dict) and isinstance(b, dict):
        if set(a) != set(b):
            out.append((chemin + ' (clés)', sorted(set(a) ^ set(b)), None))
        for k in a:
            if k in b:
                _ecarts(a[k], b[k], chemin + '.' + k, out)
    elif isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            out.append((chemin + ' (longueur)', len(a), len(b)))
        for i, (x, y) in enumerate(zip(a, b)):
            _ecarts(x, y, '%s[%d]' % (chemin, i), out)
    elif a != b:
        out.append((chemin, a, b))
    return out


def _json(x):
    """Valeur du moteur -> JSON, comme les fixtures (non-finis en chaînes)."""
    return json.loads(json.dumps(generer.propre(x), allow_nan=False))


def _rejouer_operations(d, k=None):
    """Rejoue les opérations d'une fixture sur un `Koach` neuf ; renvoie le
    moteur et la liste des écarts aux sorties attendues."""
    if k is None:
        k = Koach(d['params'], d['fiches'], d['profil'])
    ecarts = []
    for i, op in enumerate(d['operations']):
        if op['op'] == 'observe':
            k.observe(copy.deepcopy(op['evenement']))
            if 'posterior' in op:
                ecarts += _ecarts(_json(k.posterior()), op['posterior'], 'op%d.posterior' % i)
        else:
            c = generer.contraintes_vers_moteur(copy.deepcopy(op['contraintes']))
            ecarts += _ecarts(_json(k.plan(c)), op['sortie'], 'op%d.sortie' % i)
            ecarts += _ecarts(_json(k.explain()), op['raisons'], 'op%d.raisons' % i)
    return k, ecarts


# ----------------------------------------------------------------------
# (a) À jour
# ----------------------------------------------------------------------
def test_fixtures_a_jour():
    r = subprocess.run([sys.executable, os.path.join(FIX, 'generer.py'), '--verifier'],
                       cwd=REF, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr + r.stdout


def test_taille_et_codage():
    total = 0
    for nom in ['numerique.json'] + MOTEURS + PLANIFS:
        chemin = os.path.join(FIX, nom)
        total += os.path.getsize(chemin)
        with open(chemin, encoding='utf-8') as f:
            t = f.read()
        assert 'Infinity' not in t and 'NaN' not in t, nom
        d = json.loads(t)
        assert d['version_format'] == generer.VERSION_FORMAT
        assert t == generer.texte(d), nom      # compact, trié, repr complet
    assert total < 3 * 1000 * 1000, total


# ----------------------------------------------------------------------
# (b) Rejeu : un Koach neuf redonne les instantanés à 1e-9 près
# ----------------------------------------------------------------------
@pytest.mark.parametrize('nom', MOTEURS)
def test_rejeu_moteur(nom):
    d = _lire(nom)
    _, ecarts = _rejouer_operations(d)
    assert not ecarts, ecarts[:5]
    instantanes = sum(1 for op in d['operations'] if 'posterior' in op)
    plans = sum(1 for op in d['operations'] if op['op'] == 'plan')
    assert instantanes >= 4 and plans >= 4


def test_scenarios_couvrent_les_cas():
    """Le premier scénario a un instantané après chaque série ; les autres
    couvrent répétitions, tenues, cardio, séance manquée, douleur et test."""
    types = set()
    evenements = set()
    raisons = set()
    for nom in MOTEURS:
        d = _lire(nom)
        for op in d['operations']:
            if op['op'] == 'observe':
                evenements.add(op['evenement']['type'])
                if op['evenement']['type'] == 'seance_fin' and op['evenement'].get('douleurs'):
                    evenements.add('douleur')
            else:
                for r in op['raisons']:
                    raisons.add(r['code'])
            if 'posterior' in op:
                for x in op['posterior']['exercices'].values():
                    types.add(x['type'])
    assert {'charge', 'reps', 'tenue', 'cardio'} <= types
    assert {'seance_debut', 'serie', 'seance_fin', 'semaine_fin', 'seance_manquee', 'douleur'} <= evenements
    assert {'koach.douleur_retrait', 'koach.vrai_test'} <= raisons
    d = _lire(MOTEURS[0])
    for op in d['operations']:
        if op['op'] == 'observe' and op['evenement']['type'] == 'serie':
            assert 'posterior' in op


def test_numerique():
    d = _lire('numerique.json')['cas']
    f = generer.decoder_flottant
    simples = {'erfc': nu.erfc, 'norm_cdf': nu.norm_cdf, 'norm_sf': nu.norm_sf, 'norm_pdf': nu.norm_pdf,
               'norm_ppf': nu.norm_ppf, 'fnv1a32': nu.fnv1a32, 'dart_round': nu.dart_round}
    for nom, fn in simples.items():
        assert len(d[nom]) >= 10, nom
        for x, y in d[nom]:
            assert not _ecarts(_json(fn(f(x))), y), (nom, x)
    for entree, sortie in d['interval_moments']:
        assert not _ecarts(_json(nu.interval_moments(*[f(v) for v in entree])), sortie), entree
    for entree, sortie in d['category_moments']:
        m, v, a, b, ib, steps, span, gross, gsd = [f(x) for x in entree]
        r = nu.category_moments(m, v, a, b, generer.bruit_de(d['category_moments_bruits'][ib]), steps=steps,
                                span=span, gross=gross, gross_sd=gsd)
        assert not _ecarts(_json(r), sortie), entree
    assert any(e[7] > 0 for e, _ in d['category_moments'])          # queue lourde
    for entree, sortie in d['point_moments']:
        assert not _ecarts(_json(nu.point_moments(*entree)), sortie)
    for c in d['mulberry32']:
        r = nu.Mulberry32(c['graine'])
        assert [r.next() for _ in c['next']] == c['next']
        assert r.state == c['etat_apres_next']
        r = nu.Mulberry32(c['graine'])
        assert [r.gauss() for _ in c['gauss']] == c['gauss']
    # Branches couvertes : queues, bornes infinies, masse minuscule.
    assert any(s[0] == -640.0 for _, s in d['interval_moments'])
    assert any(x == 0.0 for _, x in d['norm_sf'])
    assert any(y == '-inf' for _, y in d['norm_ppf']) and any(y == 'inf' for _, y in d['norm_ppf'])


@pytest.mark.parametrize('nom', PLANIFS)
def test_rejeu_planification(nom):
    d = _lire(nom)
    k, ecarts = _rejouer_operations(d)
    assert not ecarts, ecarts[:5]
    att = d['attendu']
    assert not _ecarts(_json(k.posterior()), att['posterior_avant'])
    pl_d = d['planification']
    ref = pl_d['reference']
    pl = Planification(d['params'], d['fiches'], None, pl_d['options'])
    pl.charger_reference(ref['blocs'], ref['block_weeks'], ref['horizon'], cibles=ref['cibles'],
                         echeance_jour=ref['echeance_jour'], principaux=ref['principaux'],
                         poids_corps=ref['poids_corps'])
    w = pl_d['semaine']
    tirage = pl.tirer(k, w, int(pl.p['trajectoires']))
    for c, v in att['tirage'].items():
        assert not _ecarts(_json(tirage[c]), v, 'tirage.' + c), c
    ligne = pl.replanifier(k, w)
    assert not _ecarts(_json(ligne), att['ligne'])
    assert not _ecarts(_json({str(s): p for s, p in sorted(pl.plan.items())}), att['plan'])
    for s, lignes in att['items_modules'].items():
        mods = [[j, slot, n, e] for (j, slot), (n, e) in sorted(pl.items_modules(int(s)).items())]
        assert not _ecarts(_json(mods), lignes), s
    assert not _ecarts(_json(k.posterior()), att['posterior_apres'])
    # Tirages intermédiaires cohérents : x = moyennes + z Lᵀ (L par valeurs propres).
    ti = att['tirage_intermediaire']
    vec = np.array(ti['vecteurs_propres'])
    L = vec * np.sqrt(np.array(ti['valeurs_propres']))
    x = np.array(ti['moyennes'])[None, :] + np.array(ti['z']) @ L.T
    E = len(att['suivis'])
    assert np.max(np.abs(x[:, :E] - np.array(att['tirage']['mu']))) < 1e-12


def test_planification_cas_delicats():
    """Cas 1 : échéance et cible, plan retenu différent de la référence,
    probabilité intermédiaire ; cas 2 : sans échéance."""
    a = _lire(PLANIFS[0])['attendu']['ligne']
    assert a['valeur'] > a['valeur_reference']
    assert any(0.05 < p < 0.95 for p in a['p_cibles'].values())
    b = _lire(PLANIFS[1])
    assert b['planification']['reference']['echeance_jour'] is None
    assert b['attendu']['ligne']['valeur'] > b['attendu']['ligne']['valeur_reference']


# ----------------------------------------------------------------------
# (c) Déterminisme : deux générations, mêmes octets
# ----------------------------------------------------------------------
def test_generation_deterministe():
    g1 = generer.fixtures()
    g2 = generer.fixtures()
    assert list(g1) == list(g2)
    for nom in g1:
        assert g1[nom].encode('utf-8') == g2[nom].encode('utf-8'), nom


# ----------------------------------------------------------------------
# (d) État recalculé depuis le journal (`koach.moteur.rejouer`)
# ----------------------------------------------------------------------
@pytest.mark.parametrize('nom', MOTEURS)
def test_rejouer_le_journal(nom):
    """`rejouer` sur les seuls événements (sans les appels `plan`) redonne
    le même `posterior()`, à chaque instantané et à la fin (l'a posteriori
    ne dépend pas des appels `plan` : ils créent au plus des pistes à la
    prescription, au même a priori). Les appels `plan` portent en revanche
    un état de prescription que `rejouer` ne reconstruit pas (voir
    LIVRAISON : zones provoquées -> dose de reprise après douleur)."""
    d = _lire(nom)
    evenements = [op['evenement'] for op in d['operations'] if op['op'] == 'observe']
    instantanes = [op['posterior'] for op in d['operations'] if 'posterior' in op]
    k = rejouer(d['params'], d['fiches'], d['profil'], copy.deepcopy(evenements))
    assert k.journal == evenements
    assert not _ecarts(_json(k.posterior()), instantanes[-1])
    # Aussi à chaque instantané, et à l'identique (pas seulement à 1e-9).
    k = Koach(d['params'], d['fiches'], d['profil'])
    for op in d['operations']:
        if op['op'] == 'observe':
            k.observe(copy.deepcopy(op['evenement']))
            if 'posterior' in op:
                assert generer.texte(_json(k.posterior())) == generer.texte(op['posterior'])


def test_non_finis_codes():
    assert generer.propre(math.inf) == 'inf' and generer.propre(-math.inf) == '-inf'
    assert generer.propre(float('nan')) == 'nan'
    with pytest.raises(ValueError):
        generer.copie_json({'x': math.inf})
