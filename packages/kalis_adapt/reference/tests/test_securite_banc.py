# -*- coding: utf-8 -*-
"""Le portage Python des critères de sécurité du banc (`safetyFindings`,
`kalis_bench/lib/src/safety.dart`) : 0 constat sur les saisons de référence
de `kalis_plan`, chaque critère se déclenche sur des blocs modifiés à la
main, et mêmes constats que le Dart sur les blocs passés à
`kmSafetyOfBlocks` (`donnees/securite_dart.json.gz`)."""
import copy
import gzip
import json
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import donnees
from banc import securite_banc as sb

RACINE = donnees.RACINE
FICHIER_DART = os.path.join(RACINE, 'securite_dart.json.gz')
ENTREES_DART = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(
    os.path.abspath(__file__))))), 'kalis_bench', 'km1_entree', 'securite')


# ---------------------------------------------------------------------------
# Données exportées
# ---------------------------------------------------------------------------

def _catalogue():
    try:
        return donnees.lire('catalogue_infos.json.gz')
    except (IOError, OSError):
        return None


def _catalogue_complet_ou_skip():
    cat = _catalogue()
    if cat is None:
        pytest.skip('donnees/catalogue_infos.json.gz absent : relancer `dart run bin/km1.dart`.')
    if not sb.fiches_completes(cat['exercises']) or not cat.get('groups'):
        pytest.skip("catalogue_infos.json.gz sans les champs de sécurité du lot KM1 (name, "
                    "resistance, groupCredits, rootId, level, laterality, jointStress…) ni la "
                    "clé `groups` : relancer l'export Dart complété (`dart run bin/km1.dart`).")
    return cat


#: Constats connus des saisons de référence (à confirmer par le Dart :
#: `python3 -m banc.securite_banc --entrees-dart ../../kalis_bench/km1_entree/securite`
#: puis `dart run bin/km1.dart --sortie <dossier> --outils-seuls`, et
#: `test_memes_codes_que_le_dart`). Relevé au lot KM1 sur des fiches
#: reconstruites depuis le catalogue : au changement de discipline, le bloc
#: 1 est interrompu après deux semaines et le bloc suivant de `kalis_plan`
#: (planifié contre le bloc 1 entier) monte les pectoraux de 12 à 14,5
#: séries dures (limite 14,4).
EXCEPTIONS_CONNUES = {
    ('street_06_inter_sets_reps', 'changement_discipline'): {'volume_trop_vite': 1},
}


def test_saisons_de_reference_sans_constat():
    cat = _catalogue_complet_ou_skip()
    infos = sb.indexer_infos(cat['exercises'])
    groupes = sb.groupes_de(cat)
    erreurs = []
    n = 0
    for cle in donnees.profils():
        for s in donnees.saisons_reference(cle):
            found = sb.constats_saison(s, infos, groupes=groupes)
            n += 1
            attendu = EXCEPTIONS_CONNUES.get((cle, s['scenario']), {})
            if sb.comptes(found) != attendu:
                erreurs.append((cle, s['scenario'], sb.comptes(found), found[:3]))
    assert n > 0
    assert not erreurs, 'constats sur des saisons de référence : %r' % (erreurs[:10],)


def test_champs_recalcules_egaux_aux_champs_exportes():
    """Les classes recalculées en Python (risque élevé et modéré, impact,
    famille bras tendus) sont celles que le Dart exporte."""
    cat = _catalogue_complet_ou_skip()
    ecarts = []
    for f in cat['exercises']:
        if sb.risque_eleve_calcule(f) != f['highRisk']:
            ecarts.append(('highRisk', f['id']))
        if sb.risque_modere_calcule(f) != f['moderateRisk']:
            ecarts.append(('moderateRisk', f['id']))
        if sb.impact_calcule(f) != f['impact']:
            ecarts.append(('impact', f['id']))
        if 'straightArm' in f and sb.famille_bras_tendus_calculee(f) != f['straightArm']:
            ecarts.append(('straightArm', f['id']))
        if 'slotKind' in f and (f['slotKind'] in sb.NATURES_RENFORCEMENT) != f['resistance']:
            ecarts.append(('resistance', f['id']))
        if 'heavyImpact' in f and (f['pattern'] in sb.SCHEMAS_IMPACT_LOURD) != f['heavyImpact']:
            ecarts.append(('heavyImpact', f['id']))
    assert [(g['index'], g['code'], g['major']) for g in cat['groups']] == sb.GROUPES
    assert not ecarts, ecarts[:20]


# ---------------------------------------------------------------------------
# Programmes construits à la main
# ---------------------------------------------------------------------------

ARTICULATIONS = ['epaule', 'coude', 'poignet', 'lombaires', 'genou', 'hanche', 'cheville']


def fiche(eid, pattern='tirageVertical', family='tirage', load_type='bodyweight', resistance=True,
          credits=None, level=0, root=None, difficulty=3, laterality='bilateral', stress=None,
          fraction=0.0, impact=False, equipment=None, prerequisites=None, articularity='multiJoint',
          assisted=False, name=None):
    c = [0] * 17
    for g, v in (credits if credits is not None else {4: 2, 6: 1}).items():
        c[g] = v
    js = {j: 'low' for j in ARTICULATIONS}
    js.update(stress or {})
    f = {
        'id': eid, 'name': name or eid, 'pattern': pattern, 'family': family,
        'loadType': load_type, 'resistance': resistance, 'groupCredits': c, 'level': level,
        'rootId': root or eid, 'difficulty': difficulty, 'laterality': laterality,
        'jointStress': js, 'bodyweightFraction': fraction, 'fraction': fraction,
        'impact': impact, 'equipment': equipment or [], 'prerequisites': prerequisites or [],
        'articularity': articularity, 'assisted': assisted, 'contractionMode': 'dynamicEffort',
    }
    f['highRisk'] = sb.risque_eleve_calcule(f)
    f['moderateRisk'] = sb.risque_modere_calcule(f)
    f['straightArm'] = sb.famille_bras_tendus_calculee(f)
    return f


INFOS = {f['id']: f for f in [
    fiche('traction', credits={4: 2, 6: 1}),
    fiche('rowing', pattern='tirageHorizontal', credits={5: 2, 6: 1}),
    fiche('pompe', pattern='pousseeHorizontale', family='poussee', credits={0: 2, 7: 1}),
    fiche('squat-barre', pattern='squat', family='jambesGenou', load_type='barbell',
          credits={11: 2, 10: 1}, stress={'genou': 'high'}),
    fiche('planche-tuck', pattern='figureStatiquePoussee', family='figureStatique',
          credits={1: 2}, root='planche', difficulty=4, stress={'poignet': 'high'}),
    fiche('planche-straddle', pattern='figureStatiquePoussee', family='figureStatique',
          credits={1: 2}, root='planche', difficulty=6, level=2),
    fiche('saut-boite', pattern='pliometrie', family='explosif', credits={11: 2}, impact=True),
    fiche('course', pattern='cardioContinu', family='cardio', resistance=False, credits={}),
    fiche('muscle-up', pattern='transitionMuscleUp', family='tirage', credits={4: 2}, level=3,
          difficulty=7, prerequisites=['traction']),
    fiche('dips-chaines', pattern='pousseeVerticaleBasse', family='poussee', credits={7: 2}),
]}


def it(eid, slot, sets=3, reps=(8, 10), flames=5, load=None, seconds=None, rest=90, kind='work',
       **extra):
    p = {'slotId': slot, 'exerciseId': eid, 'sets': sets, 'restSeconds': rest, 'kind': kind,
         'toCalibrate': False, 'loadBasis': 'bodyweight', 'reasons': []}
    if seconds is not None:
        p['secondsLow'], p['secondsHigh'] = seconds
    elif reps is not None:
        p['repsLow'], p['repsHigh'] = reps
    if flames is not None:
        p['targetFlames'] = flames
    if load is not None:
        p['startLoadKg'] = load
    p.update(extra)
    return p


def bloc(semaines, budgets=(60, 60, 60), index=0):
    """`semaines` : liste de (nature, [items du jour 0, items du jour 1, …])."""
    days1 = [{'dayIndex': d, 'weekday': 1 + 2 * d, 'minutesBudget': b, 'focus': 'x', 'slots': []}
             for d, b in enumerate(budgets)]
    weeks = []
    for wi, (kind, jours) in enumerate(semaines):
        weeks.append({'weekIndex': wi, 'kind': kind,
                      'days': [{'dayIndex': d, 'items': items} for d, items in enumerate(jours)]})
    return {'schemaVersion': 1,
            'pass1': {'blockIndex': index, 'weeks': len(semaines), 'days': days1},
            'pass2': {'weeks': weeks}}


def bench(level='beginner', **extra):
    j = {'schemaVersion': 1, 'key': 'test', 'level': level,
         'core': {'birthYear': 1995, 'heightCm': 180, 'bodyWeightKg': 75.0},
         'records': [], 'events': [], 'injuries': []}
    j.update(extra)
    return j


PROFIL = {'bodyWeightKg': 75.0}


def semaine_base():
    return [
        [it('traction', 'd0.1'), it('pompe', 'd0.2')],
        [it('rowing', 'd1.1'), it('squat-barre', 'd1.2', load=60.0, flames=5)],
        [it('traction', 'd2.1'), it('pompe', 'd2.2')],
    ]


def programme(n=8, kinds=None):
    """`n` semaines identiques, une décharge toutes les quatre semaines."""
    sems = []
    for w in range(n):
        kind = kinds[w] if kinds else ('deload' if w % 4 == 3 else 'build')
        jours = semaine_base()
        if kind == 'deload':
            for j in jours:
                for p in j:
                    p['sets'] = 1
        sems.append((kind, jours))
    return sems


def codes(blocs, b=None, horizon=None, infos=INFOS, block_weeks=None):
    found = sb.constats(blocs, b or bench(), PROFIL, infos,
                        horizon if horizon is not None else 99, block_weeks=block_weeks)
    return sb.comptes(found), found


def test_programme_sain_sans_constat():
    c, found = codes([bloc(programme(8))])
    assert c == {}, found


def test_charge_trop_vite():
    sems = programme(3)
    sems[1][1][1][1]['startLoadKg'] = 70.0    # +16,7 % (seuil débutant 10 %)
    c, found = codes([bloc(sems)])
    assert c.get('charge_trop_vite') == 1, found
    f = [x for x in found if x['code'] == 'charge_trop_vite'][0]
    assert f['week'] == 1 and f['dayIndex'] == 1 and f['exerciseId'] == 'squat-barre'
    assert f['value'] == pytest.approx(70 / 60 - 1, abs=1e-3) and f['limit'] == 0.1
    assert '+16.7 %' in f['message'] and 'seuil 10.0 %' in f['message']
    # Schéma de répétitions changé : pas de comparaison.
    sems[1][1][1][1]['repsHigh'] = 6
    c, _ = codes([bloc(sems)])
    assert 'charge_trop_vite' not in c


def test_volume_trop_vite():
    sems = programme(3)
    sems[1][1][0][0]['sets'] = 8        # grand dorsal : 3+3 → 8+3 séries (limite 7,2)
    c, found = codes([bloc(sems)])
    assert c.get('volume_trop_vite', 0) >= 1, found
    # Règle de deux semaines : 30 → 36 → 40 séries (chaque pas tenu : +20 %,
    # mais +33 % sur deux semaines, limite 39).
    sems = programme(4, kinds=['build'] * 4)
    for w, n in ((0, 27), (1, 33), (2, 37), (3, 37)):
        sems[w][1][0][0]['sets'] = n
    c, found = codes([bloc(sems)], b=bench('elite'))
    f = [x for x in found if x['code'] == 'volume_trop_vite' and 'grand dorsal' in x['message']]
    assert len(f) == 1 and 'deux semaines' in f[0]['message'], found
    assert f[0]['week'] == 2 and f[0]['value'] == 40 and f[0]['limit'] == 39


def test_plafond_volume():
    sems = programme(4, kinds=['build'] * 4)
    for w in sems:
        w[1][0][0]['sets'] = 4
        w[1][0].append(it('traction', 'd1.3', sets=6))     # grand dorsal 4+6+1+3 = 14 > 12
        w[1][0].append(it('traction', 'd1.4', sets=1))
    c, found = codes([bloc(sems)])
    assert c.get('plafond_volume') == 1, found
    # Élite : plus de deux groupes au-dessus de 25.
    sems = programme(1, kinds=['build'])
    sems[0][1][0][0] = it('traction', 'd0.1', sets=26)
    sems[0][1][0][1] = it('pompe', 'd0.2', sets=26)
    sems[0][1][1][0] = it('rowing', 'd1.1', sets=26)
    c, found = codes([bloc(sems)], b=bench('elite'))
    assert c.get('plafond_volume') == 1, found


def test_tendon_figures():
    sems = programme(3)
    for d in range(3):
        sems[0][1][d].append(it('planche-tuck', 'p%d' % d, sets=3, seconds=(10, 10), flames=5))
    c, found = codes([bloc(sems)])
    assert c.get('tendon_figures') == 1, found           # 3 jours > 2 (débutant)
    # Hausse des secondes : 30 s → 60 s.
    sems = programme(3)
    sems[0][1][0].append(it('planche-tuck', 'p0', sets=3, seconds=(10, 10)))
    sems[1][1][0].append(it('planche-tuck', 'p0', sets=6, seconds=(10, 10)))
    c, found = codes([bloc(sems)])
    f = [x for x in found if x['code'] == 'tendon_figures']
    assert len(f) == 1 and f[0]['value'] == 60 and f[0]['limit'] == 36, found


def test_levier_trop_tot():
    sems = programme(3)
    sems[0][1][0].append(it('planche-tuck', 'p0', sets=2, seconds=(10, 10)))
    sems[2][1][0].append(it('planche-straddle', 'p1', sets=1, seconds=(5, 5)))
    c, found = codes([bloc(sems)], b=bench('intermediate'))
    assert c.get('levier_trop_tot') == 1, found


def test_echec_risque():
    sems = programme(3)
    sems[0][1][1][1]['targetFlames'] = 8      # squat à la barre (risque élevé), RIR 1,5
    c, found = codes([bloc(sems)], b=bench('advanced'))
    assert c.get('echec_risque') == 1, found
    # Débutant : échec sur n'importe quel exercice, et quasi-échec répété.
    sems = programme(3)
    sems[0][1][0][0]['targetFlames'] = 10
    c, found = codes([bloc(sems)])
    assert c.get('echec_risque') == 2, found   # échec + 3 séries à RIR ≤ 1 (traction, risque modéré)


def test_seance_trop_longue():
    sems = programme(3)
    sems[0][1][0].append(it('rowing', 'd0.3', sets=20, reps=(15, 20), rest=240))
    c, found = codes([bloc(sems)])
    assert c.get('seance_trop_longue') == 1, found
    # Jour d'une course d'épreuve : non compté.
    sems[0][1][0].append(it('course', 'd0.4', sets=1, reps=None, flames=None, kind='test',
                         distanceMeters=10000.0, test={'kind': 'time_trial'},
                         reasons=[{'code': 'x', 'params': {'note': 'event_day'}}]))
    c, _ = codes([bloc(sems)])
    assert 'seance_trop_longue' not in c


def test_decharge_absente():
    c, found = codes([bloc(programme(14, kinds=['build'] * 14))])
    assert c.get('decharge_absente') == 1, found
    f = [x for x in found if x['code'] == 'decharge_absente'][0]
    assert f['week'] == 12 and f['value'] == 13 and f['limit'] == 12
    # Intermédiaire : 7 au plus.
    c, _ = codes([bloc(programme(8, kinds=['build'] * 8))], b=bench('intermediate'))
    assert c.get('decharge_absente') == 1


def test_affutage_absent():
    ev = [{'id': 'e', 'kind': 'competition', 'label': 'x', 'weeksOut': 8, 'priority': 'A'}]
    c, found = codes([bloc(programme(8, kinds=['build'] * 8))], b=bench(events=ev))
    assert c.get('affutage_absent') == 1, found
    # Échéance au-delà du programme.
    ev[0]['weeksOut'] = 20
    c, found = codes([bloc(programme(8))], b=bench(events=ev))
    assert c.get('affutage_absent') == 1, found
    # Semaine d'échéance allégée : rien.
    ev[0]['weeksOut'] = 8
    sems = programme(8, kinds=['build'] * 7 + ['test'])
    for j in sems[7][1]:
        for p in j:
            p['sets'] = 1
    c, found = codes([bloc(sems)], b=bench(events=ev))
    assert 'affutage_absent' not in c, found


def test_reprise_trop_dure():
    sems = programme(3)
    sems[0][1][0][0]['targetFlames'] = 6          # RIR 2,5 < 3
    c, found = codes([bloc(sems)], b=bench('intermediate', **{'break': {'weeksOff': 3}}))
    assert c.get('reprise_trop_dure') == 1, found
    c, _ = codes([bloc(sems)], b=bench('intermediate', **{'break': {'weeksOff': 1}}))
    assert 'reprise_trop_dure' not in c


def test_contre_indication_impact_technique_niveau_non_acquis():
    sems = programme(3)
    sems[0][1][2].append(it('saut-boite', 'd2.3'))
    sems[0][1][2].append(it('muscle-up', 'd2.4', flames=5))
    sems[1][1][2].append(it('dips-chaines', 'd2.5', format='cluster'))
    inj = [{'zone': 'knee', 'side': 'left', 'discomfort': 5, 'status': 'current', 'label': 'genou'}]
    b = bench(injuries=inj, core={'birthYear': 1950, 'heightCm': 180, 'bodyWeightKg': 75.0,
                                  'cannotDoExerciseIds': ['traction']})
    c, found = codes([bloc(sems)], b=b)
    assert c.get('contre_indication') == 1, found          # squat, contrainte forte, gêne 5
    assert c.get('impact_deconseille') == 1, found         # 76 ans : saut
    assert c.get('technique_sans_prerequis') == 2, found   # cluster + exercice « chaines »
    assert c.get('exercice_trop_avance') == 1, found       # muscle-up niveau élite
    assert c.get('exercice_non_acquis') == 2, found        # traction, muscle-up (prérequis)


def test_blocs_servis_tronques():
    b1 = bloc(programme(4))
    b2 = bloc(programme(4), index=1)
    sems = sb.lire_programme([b1, b2], INFOS, 99, block_weeks=[0, 2])
    assert len(sems) == 6 and [w.block_index for w in sems] == [0, 0, 1, 1, 1, 1]
    sems = sb.lire_programme([b1, b2], INFOS, 5)
    assert len(sems) == 5


def test_grandeurs_et_limites():
    blocs = [bloc(programme(4))]
    sems = sb.lire_programme(blocs, INFOS, 99)
    v = sb.series_par_groupe(sems)
    assert v['lats'] == [6.0, 6.0, 6.0, 2.0]
    assert sb.limites_volume([w.allegee for w in sems], v['lats'], 2) == (8.0, 10.0)
    assert sb.plafond_hebdomadaire(1) == 20
    assert sb.limite_duree_seance(60) == pytest.approx(72.0)
    assert sb.duree_seance_minutes(blocs[0]['pass2']['weeks'][0]['days'][0]['items'], INFOS) \
        == pytest.approx(sems[0].days[0].minutes_estimees)
    assert sb.secondes_par_famille(sems)['push'] == [0.0] * 4
    assert sb.fixe(2.25, 1) == '2.3' and sb.arrondi_dart(2.5) == 3 and sb.arrondi_dart(-2.5) == -3


# ---------------------------------------------------------------------------
# Comparaison au Dart (`kmSafetyOfBlocks`)
# ---------------------------------------------------------------------------

def _resultats_dart():
    if not os.path.exists(FICHIER_DART):
        pytest.skip('donnees/securite_dart.json.gz absent (sortie de `dart run bin/km1.dart '
                    '--outils-seuls` sur km1_entree/securite/).')
    with gzip.open(FICHIER_DART, 'rt', encoding='utf-8') as f:
        return json.load(f)


def _entree_de(r):
    if r.get('blocks') is not None:
        return r['blocks'], r.get('blockWeeks'), r.get('weeks')
    chemin = os.path.join(ENTREES_DART, r['file'])
    if not os.path.exists(chemin):
        pytest.skip('entrée %s introuvable' % r['file'])
    with gzip.open(chemin, 'rt', encoding='utf-8') as f:
        e = json.load(f)
    return e['blocks'], e.get('blockWeeks'), r.get('weeks')


def _saison(cle, scenario):
    for s in donnees.saisons_reference(cle):
        if s['scenario'] == scenario:
            return s
    pytest.skip('saison %s / %s absente des exports' % (cle, scenario))


def _python_de(r, infos, groupes):
    s = _saison(r['key'], r['scenario'])
    blocs, bw, weeks = _entree_de(r)
    return sb.constats(blocs, s['benchJson'], s['profiles'][0]['profile'], infos,
                       weeks if weeks is not None else s['weeks'], block_weeks=bw, groupes=groupes)


def test_memes_codes_que_le_dart():
    resultats = _resultats_dart()
    cat = _catalogue_complet_ou_skip()
    infos = sb.indexer_infos(cat['exercises'])
    groupes = sb.groupes_de(cat)
    ecarts = []
    for r in resultats:
        py = sb.comptes(_python_de(r, infos, groupes))
        dart = sb.comptes(r['findings'])
        if py != dart:
            ecarts.append((r['file'], dart, py))
    assert not ecarts, ecarts


def test_memes_constats_que_le_dart():
    """Comparaison complète (messages, semaines, jours, exercices, valeurs) :
    plus stricte que les comptes par code."""
    resultats = _resultats_dart()
    cat = _catalogue_complet_ou_skip()
    infos = sb.indexer_infos(cat['exercises'])
    groupes = sb.groupes_de(cat)
    ecarts = []
    for r in resultats:
        py = _python_de(r, infos, groupes)
        dart = r['findings']
        if len(py) != len(dart):
            ecarts.append((r['file'], 'nombre', len(dart), len(py)))
            continue
        for a, b in zip(dart, py):
            for k in ('code', 'message', 'week', 'dayIndex', 'exerciseId'):
                if a.get(k) != b.get(k):
                    ecarts.append((r['file'], k, a.get(k), b.get(k)))
            for k in ('value', 'limit'):
                va, vb = a.get(k), b.get(k)
                if (va is None) != (vb is None) or (va is not None and abs(va - vb) > 1.5e-3):
                    ecarts.append((r['file'], k, va, vb))
    assert not ecarts, ecarts[:20]


def test_entree_dart_ecrite_par_python(tmp_path):
    """L'aide `ecrire_entree_securite` écrit le format lu par `runKm1`."""
    chemin = os.path.join(str(tmp_path), 'x.json.gz')
    blocs = [copy.deepcopy(bloc(programme(2)))]
    sb.ecrire_entree_securite(chemin, 'street_01', 'reference', 'essai', blocs, [0])
    with gzip.open(chemin, 'rt', encoding='utf-8') as f:
        e = json.load(f)
    assert e == {'key': 'street_01', 'scenario': 'reference', 'label': 'essai',
                 'blockWeeks': [0], 'blocks': blocs}
