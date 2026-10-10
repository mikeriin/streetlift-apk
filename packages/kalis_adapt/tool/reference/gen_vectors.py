# -*- coding: utf-8 -*-
"""Vecteurs partagés entre la référence Python et le Dart.

    python3 tool/reference/gen_vectors.py

écrit `test/fixtures/filter_vectors.json.gz` (déterministe : graines fixes).
`test/reference_test.dart` rejoue chaque cas avec le filtre Dart et exige
le même état après chaque étape.
"""
import gzip
import json
import math
import random
from pathlib import Path

import filter_ref as fr

ROOT = Path(__file__).resolve().parents[2]


def state(f):
    return {
        'm': list(f.m),
        'cov': [f.C[i][j] for i in range(4) for j in range(4)],
        'fatigueNow': f.fatigue_now(),
        'sets': f.sets,
        'sessions': f.sessions,
    }


def loaded_case(seed):
    r = random.Random(seed)
    k = r.choice([30.0, 38.0])
    n_ref = r.choice([5.0, 6.5, 9.5, 12.0, 14.5])
    log_one_rm = math.log(r.uniform(20.0, 220.0))
    day = r.randint(0, 5)
    init = {
        'mode': 'loaded', 'fromOneRm': r.random() < 0.5, 'c': log_one_rm,
        'cSd': r.choice([0.05, 0.10, 0.25, 0.5]), 'v': r.choice([0.010, 0.004, 0.0015]),
        'vSd': r.choice([0.010, 0.005, 0.003]), 'k': k, 'kLogSd': 0.30, 'nRef': n_ref, 'day': day,
    }
    if init['fromOneRm']:
        f = fr.Filter.from_one_rm(init['c'], init['cSd'], init['v'], init['vSd'], k, 0.30, n_ref, day)
    else:
        f = fr.Filter(init['c'], init['cSd'], init['v'], init['vSd'], k, 0.30, n_ref, day)
    steps, expect = [], []

    def push(step):
        steps.append(step)
        expect.append(state(f))

    truth = log_one_rm + r.gauss(0.0, 0.1)
    for _ in range(r.randint(2, 9)):
        day += r.choice([1, 2, 2, 3, 3, 4, 7, 12, 30])
        if r.random() < 0.3:
            pivot = r.choice([3.0, 5.0, 8.5, 12.0, 16.0])
            f.repivot(pivot)
            push({'op': 'repivot', 'n': pivot})
        shift = r.choice([0.0, 0.0, -0.01, -0.03, 0.006])
        day_sd = r.choice([0.035, 0.0303, 0.0248])
        f.begin_session(day, shift, day_sd)
        push({'op': 'begin', 'day': day, 'shift': shift, 'daySd': day_sd})
        for _ in range(r.randint(1, 6)):
            n_true = r.uniform(2.0, 22.0)
            log_load = truth + fr.log_share(n_true, k) + r.gauss(0.0, 0.03)
            fatigue = f.fatigue_now()
            kind = r.random()
            n = max(0.0, n_true + r.gauss(0.0, 1.5))
            if kind < 0.05:
                # Zéro répétition ; une fois sur trois à une charge légère (saisie douteuse).
                off = 0.2 if r.random() < 0.67 else -1.2
                step = {'op': 'observe', 'logLoad': log_load + off, 'n': 1.0, 'nSd': 0.5, 'fatigue': fatigue,
                        'bound': True, 'upper': True, 'learnK': False, 'clip': 3.0}
            elif kind < 0.15:
                # Échec ; une fois sur quatre très loin de ce qui était prévu.
                off = 0.0 if r.random() < 0.75 else r.choice([-0.5, 0.4])
                step = {'op': 'observe', 'logLoad': log_load + off, 'n': n + 0.5, 'nSd': 0.5, 'fatigue': fatigue,
                        'bound': False, 'learnK': fatigue < 0.02, 'clip': 3.0}
            elif kind < 0.35:
                step = {'op': 'observe', 'logLoad': log_load, 'n': math.floor(n), 'nSd': 0.5, 'fatigue': fatigue,
                        'bound': True, 'learnK': False}
            else:
                step = {'op': 'observe', 'logLoad': log_load, 'n': n, 'nSd': r.uniform(0.6, 3.5),
                        'fatigue': fatigue, 'bound': False, 'learnK': r.random() < 0.2}
            f.observe_load(step['logLoad'], step['n'], step['nSd'], step['fatigue'],
                           bound=step['bound'], learn_k=step['learnK'], upper=step.get('upper', False),
                           clip=step.get('clip'))
            push(step)
            rir = r.uniform(0.0, 5.0)
            rest = r.choice([20, 60, 90, 150, 240])
            f.note_set_fatigue(rir, rest)
            push({'op': 'fatigue', 'rir': rir, 'rest': rest})
        f.end_session()
        push({'op': 'end'})
        truth += 0.003
    day += r.randint(1, 40)
    f.predict(day)
    push({'op': 'predict', 'day': day})
    reads = {
        'k': f.k(),
        'gRef': f.g_ref(),
        'capacity': f.one_rm()[0],
        'capacityRelSd': f.one_rm()[1],
        'loadSd': [[n, f.load_sd(n, True), f.load_sd(n, False)] for n in (1.0, 5.0, 12.5)],
        'repsPossible': [[x, s, f.reps_possible(f.m[0] + x, s)] for x, s in ((-0.1, 0.0), (0.0, -0.02), (0.15, 0.01))],
        'logLoadFor': [[n, s, f.log_load_for(n, s)] for n, s in ((1.0, 0.0), (6.0, -0.03), (15.0, 0.02))],
    }
    return {'name': 'loaded-%d' % seed, 'init': init, 'steps': steps, 'expect': expect, 'reads': reads}


def direct_case(seed):
    r = random.Random(1000 + seed)
    day = 0
    capacity = math.log(r.uniform(4.0, 60.0))
    init = {'mode': r.choice(['reps', 'hold']), 'fromOneRm': False, 'c': capacity, 'cSd': r.choice([0.1, 0.5]),
            'v': 0.004, 'vSd': 0.005, 'k': 30.0, 'kLogSd': 0.0, 'nRef': 1.0, 'day': day}
    f = fr.Filter(init['c'], init['cSd'], init['v'], init['vSd'], 30.0, 0.0, 1.0, day)
    steps, expect = [], []

    def push(step):
        steps.append(step)
        expect.append(state(f))

    for _ in range(r.randint(2, 7)):
        day += r.choice([2, 3, 4, 7, 21])
        f.begin_session(day, r.choice([0.0, -0.02]), 0.035)
        push({'op': 'begin', 'day': day, 'shift': f.m[3], 'daySd': 0.035})
        for _ in range(r.randint(1, 4)):
            step = {'op': 'direct', 'logCapacity': capacity + r.gauss(0.0, 0.15), 'sd': r.uniform(0.05, 0.3),
                    'bound': r.random() < 0.3}
            if r.random() < 0.25:
                step['clip'] = 3.0
                step['bound'] = False
                step['logCapacity'] += r.choice([-0.6, 0.0, 0.5])
            f.observe_direct(step['logCapacity'], step['sd'], bound=step['bound'], clip=step.get('clip'))
            push(step)
            rir = r.uniform(0.0, 4.0)
            rest = r.choice([45, 90, 120])
            f.note_set_fatigue(rir, rest)
            push({'op': 'fatigue', 'rir': rir, 'rest': rest})
        f.end_session()
        push({'op': 'end'})
    reads = {'k': f.k(), 'gRef': 0.0, 'capacity': math.exp(f.m[0]), 'capacityRelSd': f.load_sd(1.0, False),
             'loadSd': [], 'repsPossible': [], 'logLoadFor': []}
    return {'name': 'direct-%d' % seed, 'init': init, 'steps': steps, 'expect': expect, 'reads': reads}


def functions():
    xs = [-6.0, -3.2, -1.96, -1.0, -0.3, 0.0, 0.2, 0.7, 1.0, 1.64, 2.5, 4.0, 7.5]
    return {
        'erfc': [[x, fr.erfc(x)] for x in xs],
        'normCdf': [[x, fr.norm_cdf(x)] for x in xs],
        'normPdf': [[x, fr.norm_pdf(x)] for x in xs],
        'rirOfFlames': [[f, fr.flames_to_rir(f)] for f in range(1, 11)],
        'flamesOfRir': [[x / 8.0, fr.rir_to_flames(x / 8.0)] for x in range(0, 60)],
        'logShare': [[n, k, fr.log_share(n, k)] for n in (0.5, 1.0, 3.0, 8.5, 20.0, 40.0) for k in (12.0, 30.0, 38.0)],
        'repsAt': [[x, k, fr.reps_at(x, k)] for x in (-0.05, 0.0, 0.1, 0.4) for k in (22.4, 30.0, 38.0)],
        'setFatigueOf': [[rir, rest, fr.set_fatigue_of(rir, rest)]
                         for rir in (-1.0, 0.0, 1.5, 3.0, 6.0) for rest in (10, 30, 90, 180, 300)],
        'plannedFatigue': [[i, rir, rest, fr.planned_fatigue(i, rir, rest)]
                           for i in (0, 1, 2, 4, 9) for rir in (0.0, 2.0, 4.0) for rest in (30, 120, 240)],
    }


def main():
    out = {
        'note': 'Généré par tool/reference/gen_vectors.py — ne pas modifier à la main.',
        'cases': [loaded_case(s) for s in range(40)] + [direct_case(s) for s in range(12)],
        'functions': functions(),
    }
    path = ROOT / 'test' / 'fixtures' / 'filter_vectors.json.gz'
    text = json.dumps(out, sort_keys=True, separators=(',', ':')) + '\n'
    with open(path, 'wb') as raw:
        with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as gz:
            gz.write(text.encode('utf-8'))
    print('%s : %d cas' % (path, len(out['cases'])))


if __name__ == '__main__':
    main()
