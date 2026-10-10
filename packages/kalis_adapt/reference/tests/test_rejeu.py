# -*- coding: utf-8 -*-
"""Tests du rejeu walk-forward (brique 8) sur un export SYNTHÉTIQUE fabriqué
ici : programme inventé de trois semaines, deux exercices (traction lestée,
pompes) et une ligne sans correspondance, valeurs rondes inventées, dates
fictives en 2030. Aucune donnée réelle."""
import gzip
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from rejeu import walk_forward as wf  # noqa: E402
from rejeu.journal_app import (Programme, convertir, evenements, flammes_de_rir,  # noqa: E402
                               nombre, rir_ancien)

FICHES = wf.charger_fiches()
PARAMS = wf.charger_params()
TRACTION, POMPES = 'sl-traction-lestee', 'sw-pompe'


# ----------------------------------------------------------------------
# Fabrique de l'export synthétique
# ----------------------------------------------------------------------
def fabriquer_programme():
    weeks, ann = [], {}
    for w in (1, 2, 3):
        days = []
        for j in (1, 3):
            ex = []
            if w == 2 and j == 1:
                ex.append({'id': 'T2-9', 'name': 'Traction lestée (essai)', 'sets': {'type': 'text', 'value': '1 × maximum'},
                           'load': {'type': 'system', 'ref': 'R1', 'pct': 1.0}, 'restSec': 300})
                ann['T2-9'] = {'cat': 'test1rm', 'ref': 'R1'}
            ex.append({'id': 'T%d%d-1' % (w, j), 'name': 'Traction lestée (essai)', 'sets': {'type': 'text', 'value': '3×5'},
                       'load': {'type': 'system', 'ref': 'R1', 'pct': 0.8}, 'restSec': 180})
            ann['T%d%d-1' % (w, j)] = {'cat': 'strength', 'ref': 'R1', 'rirTarget': 2}
            ex.append({'id': 'T%d%d-2' % (w, j), 'name': 'Pompes (essai)', 'sets': {'type': 'text', 'value': '3×10'},
                       'load': {'type': 'fixed', 'kg': 0.0}, 'restSec': 90})
            ann['T%d%d-2' % (w, j)] = {'cat': 'endurance', 'ref': 'R2', 'rirTarget': 2}
            ex.append({'id': 'T%d%d-3' % (w, j), 'name': 'Exercice inventé', 'sets': {'type': 'text', 'value': '2×10'},
                       'load': {'type': 'fixed', 'kg': 0.0}, 'restSec': 60})
            days.append({'j': j, 'exercises': ex})
        weeks.append({'n': w, 'days': days})
    prog = {'meta': {'anchorMonday': '2030-01-07'}, 'weeks': weeks,
            'pilotage': {'mainLifts': [{'ref': 'R1', 'unit': 'kg de lest', 'oneRm': 20.0}],
                         'repMax': [{'ref': 'R2', 'max': 40.0}], 'accessories': []}}
    kprog = {'exercises': ann, 'weeks': {'1': 'normal', '2': 'test', '3': 'normal'}}
    corr = {'noms': {'Traction lestée (essai)': TRACTION, 'Pompes (essai)': POMPES}}
    return prog, kprog, corr


def _serie(kg, reps, **kw):
    s = {'kg': kg, 'reps': reps, 'rir': '', 'v': '', 'done': True, 'completedAt': None}
    s.update(kw)
    return s


def fabriquer_export():
    logs = {}

    def seance(cle, fini, traction, pompes, autre=True, done=True):
        w, j = re.match(r'S(\d+)-J(\d+)', cle).groups()
        ex = {'T%s%s-1' % (w, j): {'sets': traction, 'note': ''},
              'T%s%s-2' % (w, j): {'sets': pompes, 'note': ''}}
        if autre:
            ex['T%s%s-3' % (w, j)] = {'sets': [_serie('', '10')], 'note': ''}
        logs[cle] = {'done': done, 'finishedAt': fini, 'title': cle, 'exerciseNames': {}, 'ex': ex}

    # Ordre d'insertion volontairement non chronologique.
    seance('S2-J3', '2030-01-16T18:00:00.000',
           [_serie('10', '5', effort=2.0), _serie('10', '5', flames=6), _serie('10', '5')],
           [_serie('', '10'), _serie('', '10')])
    seance('S1-J1', '2030-01-07T18:00:00.000',
           [_serie('10', '5', effort=2.0), _serie('10', '5', flames=8), _serie('10', '5', done=False)],
           [_serie('', '10', effort=3.0), _serie('', '10')])
    seance('S1-J3', '2030-01-09T18:00:00.000',
           [_serie('12,5', '5', effort=0.5), _serie('12.5', '4', flames=9), _serie('12,5', '4', excluded=True)],
           [_serie('', '12'), _serie('0', '11')])
    logs['S2-J1'] = {'done': True, 'finishedAt': '2030-01-14T18:00:00.000', 'title': 'S2-J1', 'exerciseNames': {},
                     'ex': {'T2-9': {'sets': [_serie('20', '1', flames=9), _serie('25', '1', flames=10),
                                              _serie('27,5', '0', effort=0.0)], 'note': ''},
                            'T21-1': {'sets': [_serie('10', '5', flames=7)], 'note': ''},
                            'T21-2': {'sets': [_serie('', '10', effort=4.0)], 'note': ''}}}
    seance('S3-J1', '2030-01-21T18:00:00.000',
           [_serie('15', '5', flames=8), _serie('15', '5', flames=9), _serie('abc', '5')],
           [_serie('', '15', flames=5), _serie('', '')])
    seance('S3-J3', None, [_serie('15', '5', done=False)], [_serie('', '10', done=False)], done=False)
    return {
        'kalisTrack': 1, 'format': 3,
        'programStart': {'status': 'set', 'date': '2030-01-07'},
        'logs': logs,
        'koach': {'legacyScale': 'rir',
                  'history': [{'at': '2030-01-01T00:00:00', 'ref': 'R1', 'value': 20.0, 'source': 'initial'},
                              {'at': '2030-01-01T00:00:00', 'ref': 'R2', 'value': 40.0, 'source': 'initial'},
                              {'at': '2030-01-15T00:00:00', 'ref': 'R1', 'value': 35.0, 'source': 'koach'}],
                  'answers': {'S1-J1': {'sleep': 8.0, 'form': 7, 'pain': {'pull': 2}}},
                  'weighIns': [{'date': '2030-01-10', 'kg': 71.0}]},
        'athleteProfile': {'v': 1, 'profile': {'experience': 'intermediate', 'sex': 'male', 'bodyWeightKg': 70.0}},
    }


def conversion(export=None):
    prog, kprog, corr = fabriquer_programme()
    return convertir(export or fabriquer_export(), Programme(prog, kprog, corr), FICHES)


def ecrire_entrees(tmp, export=None):
    prog, kprog, corr = fabriquer_programme()
    chemins = {}
    for nom, obj in (('export.json', export or fabriquer_export()), ('prog.json.gz', prog),
                     ('kprog.json.gz', kprog), ('corr.json', corr)):
        p = os.path.join(str(tmp), nom)
        if nom.endswith('.gz'):
            with gzip.open(p, 'wt', encoding='utf-8') as f:
                json.dump(obj, f)
        else:
            with open(p, 'w', encoding='utf-8') as f:
                json.dump(obj, f)
        chemins[nom] = p
    return chemins


def lancer(tmp, sortie, export=None, depuis=2):
    c = ecrire_entrees(tmp, export)
    wf.main([c['export.json'], '--programme', c['prog.json.gz'], '--koach-programme', c['kprog.json.gz'],
             '--correspondance', c['corr.json'], '--depuis', str(depuis), '--sortie', sortie])
    with open(sortie, 'rb') as f:
        return f.read()


# ----------------------------------------------------------------------
# Conversion
# ----------------------------------------------------------------------
def test_lectures_elementaires():
    assert nombre('12,5') == (12.5, 'ok')
    assert nombre(' ') == (None, 'vide')
    assert nombre('abc') == (None, 'illisible')
    assert [flammes_de_rir(r) for r in (0, 0.5, 1, 1.5, 2, 3, 4, 5, 6)] == [10, 9, 9, 8, 7, 5, 3, 1, 1]
    assert rir_ancien('8', 'rpe') == 2.0
    assert rir_ancien('2', 'rir') == 2.0


def test_conversion_ordre_jours_et_semaines():
    conv = conversion()
    cles = [s['cle'] for s in conv['seances']]
    assert cles == ['S1-J1', 'S1-J3', 'S2-J1', 'S2-J3', 'S3-J1']
    assert [s['jour'] for s in conv['seances']] == [0, 2, 7, 9, 14]
    assert conv['seances'][0]['avant'] == []
    assert [e['jour'] for e in conv['seances'][2]['avant']] == [7]
    assert [e['jour'] for e in conv['seances'][4]['avant']] == [14]
    ev = evenements(conv)
    assert ev[0]['type'] == 'seance_debut'
    jours = [e['jour'] for e in ev if 'jour' in e]
    assert jours == sorted(jours)
    r = conv['rapport']
    assert r['seances_non_terminees_ignorees'] == 1
    assert r['seances_converties'] == 5


def test_conversion_series_charges_et_notes():
    conv = conversion()
    r = conv['rapport']
    s1 = [e['serie'] for e in conv['seances'][0]['series']]
    trac = [s for s in s1 if s['exerciseId'] == TRACTION]
    assert len(trac) == 2                                   # la série non faite est ignorée
    assert trac[0]['flames'] == 7                           # effort 2,0 -> 7 flammes
    assert trac[1]['flames'] == 8                           # flames prioritaire
    assert trac[0]['externalLoadKg'] == 10.0
    assert trac[0]['target'] == {'flames': 7, 'repsLow': 5, 'repsHigh': 5}
    pomp = [s for s in s1 if s['exerciseId'] == POMPES]
    assert pomp[0]['externalLoadKg'] is None and pomp[0]['reps'] == 10
    assert pomp[1]['flames'] is None                        # série faite sans note
    s2 = [e['serie'] for e in conv['seances'][1]['series']]
    assert [s['externalLoadKg'] for s in s2 if s['exerciseId'] == TRACTION] == [12.5, 12.5]
    assert [s['flames'] for s in s2 if s['exerciseId'] == TRACTION] == [9, 9]   # effort 0,5 -> 9
    assert [s['externalLoadKg'] for s in s2 if s['exerciseId'] == POMPES] == [None, None]
    test = [e['serie'] for e in conv['seances'][2]['series'] if e['serie']['slotId'] == 'T2-9']
    assert [s['role'] for s in test] == ['test'] * 3
    assert test[2]['failed'] is True and test[2]['flames'] == 10
    assert r['series_non_faites'] == 1                      # S1-J1 (S3-J3 : séance non terminée)
    assert r['series_exclues_par_l_utilisateur'] == 1
    assert r['series_sans_correspondance'] == 4
    assert r['series_charge_illisible'] == 1
    assert r['series_mesure_vide'] == 1
    assert r['notes_depuis_effort'] >= 4
    for s in conv['seances']:
        for e in s['series']:
            assert e['serie']['exerciseId'] in (TRACTION, POMPES)


def test_profil_valeurs_initiales_bilan_et_poids():
    conv = conversion()
    p = conv['profil']
    assert p['niveau'] == 1 and p['sexe'] == 'male' and p['poids_kg'] == 70.0
    # Valeur déclarée = valeur INITIALE (la mise à jour postérieure à 35 est ignorée).
    assert p['declares'] == {TRACTION: ('one_rm_kg', 20.0), POMPES: ('max_reps', 40.0)}
    d0 = conv['seances'][0]['debut']
    assert d0['bilan'] == {'overall': 4, 'sleepHours': 8.0}  # forme 7/10 -> 4
    assert 'pains' not in d0['bilan']
    assert conv['rapport']['douleurs_par_mouvement_non_converties'] == 1
    assert d0['poids_kg'] is None                            # pesée postérieure
    assert conv['seances'][2]['debut']['poids_kg'] == 71.0
    assert d0['contexte']['semaine'] == 1 and conv['seances'][2]['debut']['contexte']['genre'] == 'test'
    assert conv['principaux'] == {TRACTION}


def test_serie_informative():
    s = [{'kind': 'work', 'externalLoadKg': 20.0, 'reps': 3, 'flames': 4},
         {'kind': 'work', 'externalLoadKg': 15.0, 'reps': 5, 'flames': 8}]
    assert wf.serie_informative(s) == (None, 'serie_plus_lourde_avant')
    s[0]['externalLoadKg'] = 10.0
    assert wf.serie_informative(s)[0] == 1
    assert wf.serie_informative([{'kind': 'work', 'externalLoadKg': 5.0, 'reps': 0, 'flames': 10}])[0] is None


# ----------------------------------------------------------------------
# Rejeu
# ----------------------------------------------------------------------
def _prevision(res, cle):
    return ([(r['exercice'], r['e1rm_prevu'], r['sd_jour'], r['e1rm_a_frais']) for r in res['A'] if r['cle'] == cle]
            + [(r['exercice'], r['prevu'], r['bas'], r['haut']) for r in res['B'] if r['cle'] == cle])


def test_pas_de_fuite_du_futur():
    base = wf.rejouer(conversion(), PARAMS, FICHES, depuis=1)
    exp = fabriquer_export()
    for s in exp['logs']['S3-J1']['ex']['T31-1']['sets']:
        s['kg'] = '40'
        s['flames'] = 10
    modif = wf.rejouer(conversion(exp), PARAMS, FICHES, depuis=1)
    for cle in ('S1-J1', 'S1-J3', 'S2-J1', 'S2-J3'):
        assert _prevision(base, cle) == _prevision(modif, cle)
    assert any(r['cle'] == 'S1-J3' for r in base['A'])
    assert _prevision(base, 'S3-J1') == _prevision(modif, 'S3-J1')   # la séance elle-même n'entre pas dans sa prévision
    # ... mais l'état final, lui, change.
    assert base['modele'].capacite(TRACTION) != modif['modele'].capacite(TRACTION)


def test_prevision_ne_perturbe_pas_le_rejeu():
    a = wf.rejouer(conversion(), PARAMS, FICHES, depuis=1)['modele']
    b = wf.rejouer(conversion(), PARAMS, FICHES, depuis=99)['modele']
    assert a.capacite(TRACTION) == b.capacite(TRACTION)
    assert a.capacite(POMPES) == b.capacite(POMPES)


def test_agregats_sans_valeur_individuelle(tmp_path):
    brut = lancer(tmp_path, os.path.join(str(tmp_path), 'ag.json'), depuis=1).decode('utf-8')
    assert not re.search(r'\d{4}-\d{2}-\d{2}', brut)
    assert not re.search(r'S\d+-J\d+', brut)
    assert '2030' not in brut and 'T2-9' not in brut

    def cles(o):
        if isinstance(o, dict):
            for k, v in o.items():
                yield k
                yield from cles(v)
        elif isinstance(o, list):
            for v in o:
                yield from cles(v)
    ag = json.loads(brut)
    interdites = {'cle', 'date', 'jour', 'finishedAt', 'e1rm_prevu', 'e1rm_reel', 'charge_totale', 'observe', 'prevu'}
    assert not interdites & set(cles(ag))
    assert ag['A_une_seance_d_avance']['total']['n'] >= 1
    # Aucune statistique publiée sur moins de N_MIN_CELLULE observations.
    def cellules(o):
        if isinstance(o, dict):
            if 'n' in o and isinstance(o['n'], int) and not isinstance(o.get('total'), dict):
                yield o
            for v in o.values():
                yield from cellules(v)
    for c in cellules(ag):
        if c['n'] < wf.N_MIN_CELLULE:
            assert set(c) <= {'n', 'meilleure_serie_sous_10_flammes', 'par_famille'}, c
    # Exercices nommés seulement avec au moins 5 observations.
    for nom, v in ag['A_une_seance_d_avance']['par_exercice'].items():
        assert nom.startswith('autres') or v['n'] >= wf.N_MIN_EXERCICE


def test_determinisme(tmp_path):
    a = lancer(tmp_path, os.path.join(str(tmp_path), 'a.json'), depuis=1)
    b = lancer(tmp_path, os.path.join(str(tmp_path), 'b.json'), depuis=1)
    assert a == b


def test_details_refuses_dans_le_depot(tmp_path):
    conv = conversion()
    res = wf.rejouer(conv, PARAMS, FICHES, depuis=1)
    try:
        wf.ecrire_details(os.path.join(wf.RACINE, 'donnees', 'interdit'), conv, res)
    except SystemExit:
        pass
    else:
        raise AssertionError('les détails ont été écrits dans le dépôt')
    assert not os.path.exists(os.path.join(wf.RACINE, 'donnees', 'interdit'))
    wf.ecrire_details(str(tmp_path / 'prive'), conv, res)
    assert os.path.exists(str(tmp_path / 'prive' / 'details_A.jsonl'))
