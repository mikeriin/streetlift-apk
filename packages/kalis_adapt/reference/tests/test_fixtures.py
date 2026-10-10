# -*- coding: utf-8 -*-
"""Fixtures de parité de Koach 1.0 (`fixtures/`, lot KM1 → portage Dart
KM2) : à jour, rejouées À L'IDENTIQUE par un `Koach` neuf depuis leurs seules
entrées (params, fiches, profil, journal : exactement ce que fera le test de
parité Dart, à 1e-9 près), état recalculé par `rejouer`, génération
déterministe, couverture des règles de sécurité."""
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

MOTEURS = ['moteur_%d.json' % sc['n'] for sc in generer.SCENARIOS]
PLANIFS = ['planification_%d.json' % pc['n'] for pc in generer.PLANIFICATIONS]
TOUS = ['numerique.json'] + MOTEURS + PLANIFS
_cache = {}


def _lire(nom):
    if nom not in _cache:
        with open(os.path.join(FIX, nom), encoding='utf-8') as f:
            _cache[nom] = json.load(f)
    return _cache[nom]


def _json(x):
    """Valeur du moteur -> JSON, comme les fixtures (non-finis en chaînes)."""
    return json.loads(json.dumps(generer.propre(x), allow_nan=False))


def _premier_ecart(a, b, chemin=''):
    """Premier écart (chemin, a, b) entre deux valeurs JSON, à l'identique
    (entier et flottant distingués), ou None."""
    if type(a) is not type(b):
        return (chemin + ' (type)', a, b)
    if isinstance(a, dict):
        if set(a) != set(b):
            return (chemin + ' (clés)', sorted(set(a) ^ set(b)), None)
        for k in sorted(a):
            e = _premier_ecart(a[k], b[k], chemin + '.' + k)
            if e:
                return e
        return None
    if isinstance(a, list):
        if len(a) != len(b):
            return (chemin + ' (longueur)', len(a), len(b))
        for i, (x, y) in enumerate(zip(a, b)):
            e = _premier_ecart(x, y, '%s[%d]' % (chemin, i))
            if e:
                return e
        return None
    return None if a == b else (chemin, a, b)


def _identique(x, attendu, quoi=''):
    """Égalité stricte (texte JSON canonique identique : même double, même
    type) d'une sortie du moteur et de la valeur attendue."""
    obtenu = _json(x)
    if generer.texte(obtenu) != generer.texte(attendu):
        raise AssertionError('%s : %r' % (quoi, _premier_ecart(obtenu, attendu)))


def _rejeu_pas_a_pas(d):
    """Rejoue le journal d'une fixture sur un `Koach` neuf, `plan` appelé
    pour chaque événement `plan` (comme l'application), et vérifie chaque
    sortie et chaque instantané. Renvoie le moteur."""
    e_ = d['entrees']
    att = d['attendu']
    plans = {p['indice']: p for p in att['plans']}
    instantanes = {x['indice']: x for x in att['instantanes']}
    k = Koach(copy.deepcopy(e_['params']), e_['fiches'], copy.deepcopy(e_['profil']))
    for i, e in enumerate(e_['journal']):
        if e['type'] == 'plan':
            out = k.plan(copy.deepcopy(e['contraintes']))
            p = plans.pop(i)
            _identique(out, p['sortie'], 'plan %d : sortie' % i)
            _identique(k.explain(), p['raisons'], 'plan %d : raisons' % i)
        else:
            k.observe(copy.deepcopy(e))
        if i in instantanes:
            x = instantanes.pop(i)
            _identique(k.posterior(), x['posterior'], 'instantané %d' % i)
            if 'diagnostic' in x:
                _identique(generer.diagnostic(k), x['diagnostic'], 'diagnostic %d' % i)
    assert not plans and not instantanes, (sorted(plans)[:3], sorted(instantanes)[:3])
    return k


# ----------------------------------------------------------------------
# (a) À jour, codage, en-tête
# ----------------------------------------------------------------------
def test_fixtures_a_jour():
    r = subprocess.run([sys.executable, os.path.join(FIX, 'generer.py'), '--verifier'],
                       cwd=REF, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr + r.stdout


def test_taille_codage_entete():
    total = 0
    for nom in TOUS:
        chemin = os.path.join(FIX, nom)
        total += os.path.getsize(chemin)
        with open(chemin, encoding='utf-8') as f:
            t = f.read()
        assert 'Infinity' not in t and 'NaN' not in t, nom
        d = json.loads(t)
        assert t == generer.texte(d), nom      # compact, trié, repr complet
        assert d['version_format'] == generer.VERSION_FORMAT
        assert d['version_moteur'] == generer.VERSION
        assert d['commande'] == generer.COMMANDE
        assert d['nature'] in ('numerique', 'moteur', 'planification')
        if d['nature'] != 'numerique':
            p = d['entrees']['params']
            assert d['sha256_parametres'] == generer.empreinte(p), nom
            assert d['version_parametres'] == p['version']
            assert d['sha256_fichier_parametres'] == generer.empreinte_fichier(generer.FICHIER_PARAMS)
            # Entrées du moteur : JSON pur (aucun non-fini codé).
            assert '"inf"' not in generer.texte(d['entrees']) and '"nan"' not in generer.texte(d['entrees'])
    assert total < 6 * 1000 * 1000, total


# ----------------------------------------------------------------------
# (b) Rejeu à l'identique
# ----------------------------------------------------------------------
@pytest.mark.parametrize('nom', MOTEURS)
def test_rejeu_moteur(nom):
    """Un `Koach` neuf, le journal rejoué pas à pas (`observe` / `plan`),
    redonne à l'identique chaque sortie de `plan`, chaque `explain()`, chaque
    instantané, l'état final, et le même journal."""
    d = _lire(nom)
    k = _rejeu_pas_a_pas(d)
    fin = d['attendu']['final']
    _identique(k.posterior(), fin['posterior'], 'posterior final')
    _identique(k.explain(), fin['raisons'], 'raisons finales')
    _identique(generer.diagnostic(k), fin['diagnostic'], 'diagnostic final')
    assert len(k.journal) == fin['longueur_journal'] == len(d['entrees']['journal'])
    assert _json(k.journal) == d['entrees']['journal']
    assert generer.empreinte(k.params) == fin['sha256_parametres_finaux']
    assert len(d['attendu']['plans']) >= 4 and len(d['attendu']['instantanes']) >= 4


@pytest.mark.parametrize('nom', MOTEURS)
def test_rejouer_le_journal(nom):
    """`rejouer` (journal seul, événements `plan` compris, versés à
    `observe`) redonne exactement l'état du rejeu pas à pas : mêmes vecteur
    et covariance, même `posterior()`, mêmes raisons."""
    d = _lire(nom)
    e_ = d['entrees']
    r = rejouer(copy.deepcopy(e_['params']), e_['fiches'], copy.deepcopy(e_['profil']),
                copy.deepcopy(e_['journal']))
    k = _rejeu_pas_a_pas(d)
    assert r.modele.ordre == k.modele.ordre
    assert np.array_equal(r.modele.m[:r.modele.n], k.modele.m[:k.modele.n])
    assert np.array_equal(r.modele.P[:r.modele.n, :r.modele.n], k.modele.P[:k.modele.n, :k.modele.n])
    fin = d['attendu']['final']
    _identique(r.posterior(), fin['posterior'], 'rejouer : posterior')
    _identique(r.explain(), fin['raisons'], 'rejouer : raisons')
    assert _json(r.journal) == e_['journal']


@pytest.mark.parametrize('nom', MOTEURS)
def test_couverture_entete(nom):
    """Le compteur de l'en-tête est celui des raisons attendues."""
    d = _lire(nom)
    raisons = {}
    for p in d['attendu']['plans']:
        for r in p['raisons']:
            raisons[r['code']] = raisons.get(r['code'], 0) + 1
    assert d['couverture']['raisons'] == raisons
    ev = {}
    for e in d['entrees']['journal']:
        ev[e['type']] = ev.get(e['type'], 0) + 1
    assert d['couverture']['evenements'] == ev


def test_scenarios_couvrent_les_cas():
    """Ensemble des scénarios : les raisons de sécurité exigées, tous les
    types d'événements et de pistes, douleur, zone fragile du profil,
    coupure d'au moins `coupure_j` jours, test, semaine de décharge, import
    de paramètres ; le premier scénario a un instantané après chaque série."""
    types = set()
    evenements = set()
    raisons = set()
    genres = set()
    douleur = fragile = coupure = False
    for nom in MOTEURS:
        d = _lire(nom)
        e_ = d['entrees']
        if e_['profil'].get('zones_fragiles'):
            fragile = True
        jours = []
        for e in e_['journal']:
            evenements.add(e['type'])
            if e['type'] == 'seance_fin' and e.get('douleurs'):
                douleur = True
            if e['type'] == 'seance_debut':
                jours.append(e['jour'])
                genres.add((e.get('contexte') or {}).get('genre'))
        seuil = e_['params']['securite']['coupure_j']
        if any(b - a >= seuil for a, b in zip(jours, jours[1:])):
            coupure = True
        for p in d['attendu']['plans']:
            for r in p['raisons']:
                raisons.add(r['code'])
        for x in d['attendu']['instantanes']:
            for v in x['posterior']['exercices'].values():
                types.add(v['type'])
    assert {'charge', 'reps', 'tenue', 'cardio'} <= types
    assert {'seance_debut', 'serie', 'seance_fin', 'semaine_fin', 'seance_manquee', 'plan',
            'parametres'} <= evenements
    manquantes = set(generer.RAISONS_EXIGEES) - raisons
    assert not manquantes, sorted(manquantes)
    assert douleur and fragile and coupure
    assert 'deload' in genres
    d = _lire(MOTEURS[0])
    inst = set(x['indice'] for x in d['attendu']['instantanes'])
    for i, e in enumerate(d['entrees']['journal']):
        if e['type'] == 'serie':
            assert i in inst


# ----------------------------------------------------------------------
# (c) Outils numériques
# ----------------------------------------------------------------------
def test_numerique():
    d = _lire('numerique.json')['cas']
    f = generer.decoder_flottant
    simples = {'erfc': nu.erfc, 'norm_cdf': nu.norm_cdf, 'norm_sf': nu.norm_sf, 'norm_pdf': nu.norm_pdf,
               'norm_ppf': nu.norm_ppf, 'fnv1a32': nu.fnv1a32, 'dart_round': nu.dart_round}
    for nom, fn in simples.items():
        assert len(d[nom]) >= 10, nom
        for x, y in d[nom]:
            _identique(fn(f(x)), y, '%s(%r)' % (nom, x))
    for (x, lo, hi), y in d['clamp']:
        _identique(nu.clamp(x, lo, hi), y, 'clamp')
    for entree, sortie in d['interval_moments']:
        _identique(nu.interval_moments(*[f(v) for v in entree]), sortie, 'interval_moments %r' % (entree,))
    for entree, sortie in d['category_moments']:
        m, v, a, b, ib, steps, span, gross, gsd = [f(x) for x in entree]
        r = nu.category_moments(m, v, a, b, generer.bruit_de(d['category_moments_bruits'][ib]), steps=steps,
                                span=span, gross=gross, gross_sd=gsd)
        _identique(r, sortie, 'category_moments %r' % (entree,))
    for entree, sortie in d['category_mass']:
        _identique(nu._category_mass(*[f(v) for v in entree]), sortie, 'category_mass %r' % (entree,))
    for entree, sortie in d['point_moments']:
        _identique(nu.point_moments(*entree), sortie, 'point_moments %r' % (entree,))
    for c in d['mulberry32']:
        r = nu.Mulberry32(c['graine'])
        assert [r.next() for _ in c['next']] == c['next']
        assert r.state == c['etat_apres_next']
        r = nu.Mulberry32(c['graine'])
        assert [r.gauss() for _ in c['gauss']] == c['gauss']
        assert r.state == c['etat_apres_gauss']
    for (S, tol), L in d['cholesky_semi']:
        _identique(nu.cholesky_semi(S) if tol is None else nu.cholesky_semi(S, tol), L, 'cholesky_semi')
        A = np.array(L)
        assert np.allclose(A @ A.T, np.array(S), atol=1e-9 * max(1.0, np.max(np.abs(S))))
        assert np.all(np.triu(A, 1) == 0.0)
    for (x, n), y in d['arrondi']:
        _identique(nu.arrondi(x, n), y, 'arrondi(%r, %r)' % (x, n))
    # Branches couvertes : queues, bornes infinies, masse minuscule.
    assert any(s[0] == -640.0 for _, s in d['interval_moments'])
    assert any(x == 0.0 for _, x in d['norm_sf'])
    assert any(y == '-inf' for _, y in d['norm_ppf']) and any(y == 'inf' for _, y in d['norm_ppf'])
    # cholesky_semi : rang déficient (colonne annulée) ; arrondi ≠ round.
    assert any(any(L[j][j] == 0.0 for j in range(len(L))) and any(L[j][j] > 0 for j in range(len(L)))
               for _, L in d['cholesky_semi'])
    assert any(y != round(x, n) for (x, n), y in d['arrondi'])
    # category_moments : a priori très large devant le bruit, intervalle
    # fermé et ouvert, avec et sans queue lourde.
    bruits = d['category_moments_bruits']

    def large(e):
        return e[1] >= 25.0 and math.sqrt(generer.bruit_de(bruits[e[4]])(e[0])) < 0.1 * math.sqrt(e[1])

    cas = [e for e, _ in d['category_moments']]
    for gross in (False, True):
        assert any(large(e) and (e[7] > 0) == gross and e[2] != '-inf' and e[3] != 'inf' and e[2] != e[3]
                   for e in cas)
        assert any(large(e) and (e[7] > 0) == gross and (e[2] == '-inf' or e[3] == 'inf') for e in cas)


# ----------------------------------------------------------------------
# (d) Planification
# ----------------------------------------------------------------------
@pytest.mark.parametrize('nom', PLANIFS)
def test_rejeu_planification(nom):
    d = _lire(nom)
    e_ = d['entrees']
    att = d['attendu']
    k = rejouer(copy.deepcopy(e_['params']), e_['fiches'], copy.deepcopy(e_['profil']),
                copy.deepcopy(e_['journal']))
    _identique(k.posterior(), att['posterior_avant'], 'posterior_avant')
    pl_d = d['planification']
    ref = pl_d['reference']
    assert pl_d['options'].get('sans_validateur') is True
    with pytest.raises(ValueError):
        Planification(e_['params'], e_['fiches'], None, {'trajectoires': 2})
    pl = Planification(e_['params'], e_['fiches'], None, pl_d['options'])
    pl.charger_reference(ref['blocs'], ref['block_weeks'], ref['horizon'], cibles=ref['cibles'],
                         echeance_jour=ref['echeance_jour'], principaux=ref['principaux'],
                         poids_corps=ref['poids_corps'])
    _identique(list(pl.suivis), att['suivis'], 'suivis')
    w = pl_d['semaine']
    tirage = pl.tirer(k, w, int(pl.p['trajectoires']))
    assert pl.hypothese_thompson == att['hypothese_thompson']
    for c, v in att['tirage'].items():
        _identique(tirage[c], v, 'tirage.' + c)
    # Tirages intermédiaires : recalcul (cholesky_semi) identique et
    # cohérent : x = moyennes + z Lᵀ redonne mu et rho.
    inter = generer.tirage_intermediaire(pl, k, w, int(pl.p['trajectoires']))
    for c, v in att['tirage_intermediaire'].items():
        _identique(inter[c], v, 'tirage_intermediaire.' + c)
    E = len(att['suivis'])
    assert np.array_equal(inter['x'][:, :E], tirage['mu']) and np.array_equal(inter['x'][:, E], tirage['rho'])
    ligne = pl.replanifier(k, w)
    _identique(ligne, att['ligne'], 'ligne')
    _identique({str(s): p for s, p in sorted(pl.plan.items())}, att['plan'], 'plan')
    for s, lignes in att['items_modules'].items():
        mods = [[j, slot, n, e] for (j, slot), (n, e) in sorted(pl.items_modules(int(s)).items())]
        _identique(mods, lignes, 'items_modules ' + s)
    _identique(k.posterior(), att['posterior_apres'], 'posterior_apres')


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
# (e) Déterminisme : deux générations, mêmes octets (numerique + un moteur ;
# la génération complète est comparée aux fichiers par --verifier)
# ----------------------------------------------------------------------
def test_generation_deterministe():
    noms = ['numerique.json', MOTEURS[1]]
    g1 = generer.fixtures(noms)
    g2 = generer.fixtures(noms)
    assert list(g1) == list(g2) == noms
    for nom in noms:
        assert g1[nom].encode('utf-8') == g2[nom].encode('utf-8'), nom
        with open(os.path.join(FIX, nom), 'rb') as f:
            assert f.read() == g1[nom].encode('utf-8'), nom


def test_non_finis_codes():
    assert generer.propre(math.inf) == 'inf' and generer.propre(-math.inf) == '-inf'
    assert generer.propre(float('nan')) == 'nan'
    with pytest.raises(ValueError):
        generer.copie_json({'x': math.inf})
    assert generer.decoder_flottant('-inf') == -math.inf
