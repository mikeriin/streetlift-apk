# -*- coding: utf-8 -*-
"""Le portage Python du modèle de vérité rejoue les traces exportées par le
banc Dart et retrouve les mêmes réponses (PIPELINE KM1 § 0 : la référence
lit les MÊMES modèles de vérité que le témoin)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from banc import donnees
from banc.alea import SimRandom, flames_to_rir
from banc.verite import SimAthlete, Spec, make_book
from banc.verite_endurance import EnduranceTruth

TOL = 1e-9


def proche(a, b, tol=TOL):
    if a is None or b is None:
        return a is None and b is None
    return abs(a - b) <= tol * max(1.0, abs(a), abs(b))


def rejouer_trace(cas, infos):
    trace = cas['trace']
    profile = cas['profile']
    book = make_book(infos, profile)
    a = SimAthlete(Spec(cas['specJson']), profile, book, trace['seed'], kind=trace['kind'])
    ecarts = []
    n = 0
    for ev in trace['events']:
        typ = ev[0]
        if typ == 'skip':
            continue
        if typ == 'day':
            _, day, ill, in_pain, pi, pu, pz, hc = ev
            a.advance(day)
            got = a.health_check(60)
            if (a.ill, a.in_pain, a.pain_intensity, a.pain_until, a.pain_zone) != (ill, in_pain, pi, pu, pz):
                ecarts.append(('day', day, (a.ill, a.in_pain, a.pain_intensity, a.pain_until, a.pain_zone), ev[2:7]))
            if (got is None) != (hc is None):
                ecarts.append(('bilan', day, got, hc))
            elif got is not None:
                for k in ('overall', 'sleepQuality', 'energy', 'minutesAvailable'):
                    if got.get(k) != hc.get(k):
                        ecarts.append(('bilan', day, k, got, hc))
                if len(got.get('pains') or []) != len(hc.get('pains') or []):
                    ecarts.append(('bilan-douleur', day, got, hc))
        elif typ == 'ex':
            _, day, ex_id, slot, t_day, cap, rows = ev
            t = a.truth_of(ex_id)
            a.begin_exercise(t, slot)
            for row in rows:
                (i, load, low, high, ft, rest, ecc, before, reach, amount, flames, true_rir,
                 failed, quality, set_fat) = row
                key = '%d|%s|%d' % (day, slot, i)
                b = a.capacity_now(t, load)
                r = a.reachable(t, low, high, flames_to_rir(ft))
                f = a.perform_eccentric if ecc else a.perform
                o = f(t, load, low, high, ft, rest, key)
                n += 1
                ok = (proche(b, before) and r == reach and o.amount == amount and o.flames == flames
                      and proche(o.true_rir, true_rir) and o.failed == failed
                      and a.quality_of(o) == quality and proche(t.set_fatigue[-1], set_fat))
                if not ok:
                    ecarts.append(('serie', day, ex_id, i, (b, r, o.amount, o.flames, o.true_rir, o.failed), row))
            a.end_exercise(t)
            if not (proche(t.day, t_day) and proche(t.capacity, cap)):
                ecarts.append(('ex', day, ex_id, t.day, t_day, t.capacity, cap))
        elif typ == 'end':
            _, day, pains, agg, flares = ev
            got = a.session_pains()
            if len(got) != len(pains) or a.pain_aggravations != agg or a.pain_flares != flares:
                ecarts.append(('end', day, got, pains, a.pain_aggravations, agg, a.pain_flares, flares))
        elif typ == 'week':
            _, w, caps, pi, pu, pz, flares = ev
            a.end_week()
            for t in a.truths:
                if not proche(t.capacity, caps[t.info.id]):
                    ecarts.append(('week', w, t.info.id, t.capacity, caps[t.info.id]))
            if (a.pain_intensity, a.pain_until, a.pain_zone, a.pain_flares) != (pi, pu, pz, flares):
                ecarts.append(('week-douleur', w, (a.pain_intensity, a.pain_until, a.pain_zone, a.pain_flares), ev[3:]))
    return n, ecarts


def test_traces_force():
    infos = donnees.catalogue_infos()
    total = 0
    for cas in donnees.lire('traces_verite.json.gz'):
        n, ecarts = rejouer_trace(cas, infos)
        assert not ecarts, (cas['key'], cas['scenario'], cas['trace']['kind'], cas['trace']['seed'], ecarts[:3])
        total += n
    assert total > 20000


def rejouer_endurance(cas):
    tr = cas['trace']
    truth = EnduranceTruth(tr['kind'], tr['level'], tr['seed'])
    ecarts = []
    n = 0
    for ev in tr['events']:
        if ev[0] == 'run':
            _, day, item, ill, rates, want = ev
            done, injured = truth.run(item, item['sets'], day, 0, ill, rates)
        elif ev[0] == 'wod':
            _, day, item, ill, rates, share, hard, want = ev
            got_hard = truth.hard_streak_before(day)
            if got_hard != hard:
                ecarts.append(('hard', day, got_hard, hard))
            done, injured = truth.wod_piece(item, item['sets'], day, 0, ill, rates, hard, share)
        else:
            _, day, easy, speed, wod, overuse, spike = ev
            truth.end_day(day)
            if not (proche(truth.easy_minutes, easy) and proche(truth.speed, speed) and proche(truth.wod, wod)
                    and truth.overuse == overuse and proche(truth.worst_spike, spike)):
                ecarts.append(('endDay', day, truth.easy_minutes, easy, truth.speed, speed, truth.wod, wod))
            continue
        n += 1
        for k in ('sets', 'seconds', 'reps', 'flames', 'success'):
            if done[k] != want[k]:
                ecarts.append((ev[0], day, k, done, want))
        for k in ('distanceMeters', 'calories'):
            if not proche(done[k], want[k]):
                ecarts.append((ev[0], day, k, done, want))
        if injured != want['injured']:
            ecarts.append((ev[0], day, 'injured', injured, want['injured']))
    return n, ecarts


def test_traces_endurance():
    total = 0
    for cas in donnees.lire('traces_endurance.json.gz'):
        n, ecarts = rejouer_endurance(cas)
        assert not ecarts, (cas['key'], cas['trace']['kind'], cas['trace']['seed'], ecarts[:3])
        total += n
    assert total > 500


def test_tirages_de_depart():
    """Les tirages de départ exportés avec chaque saison de référence
    (capacités, courbes, biais) sont retrouvés par le portage."""
    infos = donnees.catalogue_infos()
    n = 0
    for cle in donnees.profils():
        for saison in donnees.saisons_reference(cle):
            profile = saison['profiles'][0]['profile']
            book = make_book(infos, profile)
            spec = Spec(saison['specJson'])
            for init in saison['truthInits']:
                a = SimAthlete(spec, profile, book, init['seed'], kind=init['kind'])
                for k, v in (('bodyWeightKg', a.body_weight), ('sensAcute', a.sens_acute),
                             ('sensChronic', a.sens_chronic), ('beta', a.beta), ('noise', a.noise)):
                    assert proche(init[k], v), (cle, saison['scenario'], k)
                e = EnduranceTruth(init['kind'], spec.level, init['seed'])
                assert proche(e.easy_minutes, init['endurance']['easyMinutes'])
                assert proche(e.speed, init['endurance']['speed'])
                assert proche(e.wod, init['endurance']['wod'])
                for ex_id, row in init['truths'].items():
                    t = a.truth_of(ex_id)
                    got = [t.capacity, t.curve_a, t.curve_b, t.fatigue_scale, t.hold_share, t.slope, t.power, t.carry]
                    for x, y in zip(got, row):
                        assert proche(x, y), (cle, saison['scenario'], init['kind'], init['seed'], ex_id, got, row)
                        n += 1
    assert n > 10000
