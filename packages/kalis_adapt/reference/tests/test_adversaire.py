# -*- coding: utf-8 -*-
"""Banc adversarial de Koach (`banc/adversaire.py`, KM1 brique 4) : bornes,
déterminisme, export relisible et rejouable, la recherche améliore le tirage
initial, comparaison avec une sortie Dart factice. Budget réduit (une
cellule, ≤ 24 saisons) pour rester sous la minute."""
import gzip
import json
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from koach.numerique import Mulberry32  # noqa: E402

from banc import adversaire as A  # noqa: E402
from banc import mesures  # noqa: E402

CLE = 'street_07_avance_streetlifting_competition'
SANS_ECHEANCE = 'street_06_inter_sets_reps'


def _donnees_ou_skip():
    try:
        A.saison_de(CLE, 'reference')
    except (IOError, OSError, KeyError):
        pytest.skip('saisons de référence absentes : relancer `dart run bin/km1.dart`.')


@pytest.fixture(scope='module')
def recherche():
    _donnees_ou_skip()
    return A.chercher(budget=24, profils=(CLE,), modeles='b', graines=2, n_pires=4, n_temoins=1,
                      processus=2)


# ---------------------------------------------------------------------------
# Bornes
# ---------------------------------------------------------------------------

def test_bornes_tirages_aleatoires():
    """Tout point de [0, 1]^D (bords compris) donne un adversaire dans les
    bornes, pour une cellule avec et une sans échéance."""
    _donnees_ou_skip()
    rng = Mulberry32(12345)
    assert 'sl-muscle-up-leste' in A.Cadre(CLE, 'reference', 'a').poids_corps
    for cle in (CLE, SANS_ECHEANCE):
        cadre = A.Cadre(cle, 'reference', 'a')
        points = [[0.0] * A.D, [1.0] * A.D, [0.999999] * A.D]
        points += [[rng.next() for _ in range(A.D)] for _ in range(300)]
        for u in points:
            adv = A._adversaire(cadre, u, 'pire', 2)
            assert A.verifier_bornes(adv) == [], (u, adv['spec'], A.verifier_bornes(adv))
            assert len(adv['seeds']) == 2


def test_bornes_promises():
    """Les bornes écrites respectent les limites de réalisme du cahier."""
    p = A.PAR_NOM
    assert p['ratingNoise'].haut <= 2.5 * p['ratingNoise'].nominal
    assert p['rirBias'].bas >= -0.15 and p['rirBias'].haut <= 0.8
    assert p['capaciteTous'].bas >= 0.75 and p['capaciteTous'].haut <= 1.25
    assert p['capacitePrincipaux'].bas >= 0.75 and p['capacitePrincipaux'].haut <= 1.25
    assert p['missRate'].haut <= 0.35
    assert p['daySd'].haut <= 2.5 * p['daySd'].nominal
    for d in A.DIMENSIONS:
        assert d.raison, d.nom


def test_bornes_recherche(recherche):
    for adv in recherche['adversaires']:
        assert A.verifier_bornes(adv) == []
        assert len(adv['seeds']) >= 2


def test_graines_presentes_le_jour_j(recherche):
    for adv in recherche['adversaires']:
        cadre = A.Cadre(adv['key'], adv['scenario'], adv['kind'])
        complete = dict(cadre.spec_base)
        complete.update(adv['spec'])
        for g in adv['seeds']:
            assert any(A.present_le_jour(complete, g, j) for j in cadre.echeances)


# ---------------------------------------------------------------------------
# Recherche
# ---------------------------------------------------------------------------

def test_recherche_au_moins_le_tirage_initial(recherche):
    """Le pire adversaire retenu est au moins aussi difficile que le pire du
    tirage initial (hypercube latin)."""
    r = recherche['recherche']
    assert r['saisons_simulees'] <= 24
    c = recherche['cellules'][0]
    assert c['difficulte_max'] >= c['difficulte_initiale_max']
    pires = [a for a in recherche['adversaires'] if a['role'] == 'pire']
    assert pires[0]['difficulte'] == c['difficulte_max']
    assert any(a.get('generation', 0) > 0 for a in pires) or c['pire'] == c['pire_initial']
    # Difficulté (a) cohérente avec les performances mesurées.
    a0 = pires[0]
    assert a0['objectif_effectif'] == 'a'
    assert abs(a0['difficulte'] - (1 - a0['koach']['perf_a'])) < 2e-6


def test_determinisme_octet_pour_octet(tmp_path):
    _donnees_ou_skip()
    fichiers = []
    for k in range(2):
        # Budget 9 : 2 (témoin) + 6 (recherche) + 1 graine de confirmation.
        r = A.chercher(budget=9, profils=(CLE,), modeles='a', graines=2, n_pires=2, n_temoins=1,
                       processus=2)
        assert r['recherche']['saisons_simulees'] == 9
        assert any(len(a['seeds']) == 3 for a in r['adversaires'])
        p1 = tmp_path / ('lisible%d.json' % k)
        p2 = tmp_path / ('dart%d.json' % k)
        A.ecrire_lisible(str(p1), r)
        A.ecrire_adversaires(str(p2), r['adversaires'])
        fichiers.append((p1.read_bytes(), p2.read_bytes()))
    assert fichiers[0][0] == fichiers[1][0]
    assert fichiers[0][1] == fichiers[1][1]


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

def test_export_relisible_et_rejouable(recherche, tmp_path):
    chemin = tmp_path / 'adversaires.json'
    A.ecrire_adversaires(str(chemin), recherche['adversaires'])
    entrees = json.loads(chemin.read_text(encoding='utf-8'))
    assert isinstance(entrees, list)
    n = sum(len(a['seeds']) for a in recherche['adversaires'])
    assert len(entrees) == n
    ids = [e['id'] for e in entrees]
    assert len(set(ids)) == len(ids)
    for e in entrees:
        # Champs lus par `kmAdversaryRun` et `kmOverridesOf`.
        assert set(e) == {'id', 'key', 'scenario', 'kind', 'seed', 'spec', 'surcharges'}
        assert e['kind'] in ('a', 'b', 'c') and isinstance(e['seed'], int)
        for champ in ('breakFromDay', 'breakDays', 'illnessFromDay', 'illnessDays',
                      'painFromDay', 'painDays', 'painIntensity'):
            if champ in e['spec']:
                assert isinstance(e['spec'][champ], int)
        for m in e['surcharges'].values():
            assert set(m) <= {'capacity', 'curveB', 'slope', 'power', 'fatigueScale', 'holdShare'}
    # Rejeu : deux fois la même saison, mêmes mesures que la recherche.
    adv = [a for a in recherche['adversaires'] if a['role'] == 'pire'][0]
    e = [x for x in entrees if x['id'] == '%s-g%d' % (adv['id'], adv['seeds'][0])][0]
    relu = dict(adv, spec=e['spec'], surcharges=e['surcharges'])
    t1 = A.rejouer(relu, e['seed'])
    t2 = A.rejouer(relu, e['seed'])
    ev1, ev2 = mesures.evenements(t1), mesures.evenements(t2)
    assert ev1 == ev2
    assert [s['loadKg'] for s in t1.sets] == [s['loadKg'] for s in t2.sets]
    perf = A.perf_jour_j(ev1, True)
    assert abs(perf - adv['koach']['par_graine'][0]['perf_a']) < 2e-6


def test_lisible_relu(recherche, tmp_path):
    chemin = tmp_path / 'adversaires_v1.json'
    A.ecrire_lisible(str(chemin), recherche)
    advs = A.lire_adversaires(str(chemin))
    assert [a['id'] for a in advs] == [a['id'] for a in recherche['adversaires']]
    assert [a['role'] for a in advs].count('temoin') == 1


# ---------------------------------------------------------------------------
# Comparaison
# ---------------------------------------------------------------------------

def _sortie_dart_factice(adversaires, facteur):
    """Sortie au format de `kmAdversaryRun` : performances de Koach
    multipliées par [facteur], estimations à 5 % d'erreur au rang 6."""
    out = []
    for a in adversaires:
        for g, s in zip(a['seeds'], a['koach']['par_graine']):
            rows = [[0.0] * 6 for _ in range(25)]
            rows[6] = [2.0, 0.10, 0.02, 0.006, 0.0, 2.0]
            events = [[ex, mode, 82, best * facteur, 0.0, mx, None, None]
                      for (ex, mode, best, mx, _r) in s['evenements']]
            out.append({
                'id': '%s-g%d' % (a['id'], g), 'key': a['key'], 'scenario': a['scenario'],
                'kind': a['kind'], 'seed': g, 'findings': [],
                'run': {'seed': g, 'planned': 60, 'done': 55, 'painAggravations': 1,
                        'painFlares': 0, 'violations': 2, 'violationCodes': {'x': 2},
                        'gainMean': 0.001, 'gains': {}, 'events': events},
                'estimates': {'loadedMain': {'bySession': rows, 'firstUnder3': []}},
            })
    return out


def test_comparer_sortie_factice(recherche, tmp_path):
    advs = recherche['adversaires']
    chemin = tmp_path / 'adversaires_temoin.json.gz'
    with gzip.open(str(chemin), 'wt', encoding='utf-8') as f:
        json.dump(_sortie_dart_factice(advs, 0.9), f)
    c = A.comparer(advs, str(chemin), rejouer_koach=False)
    json.dumps(c)  # sérialisable
    assert c['critere']['saisons_temoin_manquantes'] == 0
    t = c['groupes']['tous']
    assert t['n'] == len(advs)
    assert abs(t['perf_a']['temoin']['pire'] - 0.9 * t['perf_a']['koach']['pire']) < 1e-5
    assert c['critere']['respecte'] is True
    assert abs(t['e1rm6']['temoin']['moyenne'] - 0.05) < 1e-9
    assert t['securite']['temoin']['aggravations'] == sum(len(a['seeds']) for a in advs)
    assert t['securite']['temoin']['violations'] == 2 * sum(len(a['seeds']) for a in advs)
    # Témoin meilleur : critère non respecté ; saison manquante comptée.
    sortie = _sortie_dart_factice(advs, 1.2)[1:]
    c2 = A.comparer(advs, sortie, rejouer_koach=False)
    assert c2['critere']['respecte'] is False
    assert c2['critere']['saisons_temoin_manquantes'] == 1


def test_comparer_rejoue_koach(recherche):
    """Avec rejeu, Koach retrouve exactement les mesures de la recherche."""
    adv = [a for a in recherche['adversaires'] if a['role'] == 'pire'][:1]
    sortie = _sortie_dart_factice(adv, 1.0)
    c = A.comparer(adv, sortie, rejouer_koach=True, processus=2)
    ligne = c['adversaires'][0]
    assert ligne['koach']['perf_a'] == adv[0]['koach']['perf_a']
    assert abs(ligne['temoin']['perf_a'] - ligne['koach']['perf_a']) < 1e-5
