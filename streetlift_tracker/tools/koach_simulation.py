# -*- coding: utf-8 -*-
"""Koach — simulations (KT-035) : athlètes fictifs à trajectoire connue.

Générateur pseudo-aléatoire mulberry32 + Box-Muller, identique à
`test/l7_koach_simulation_test.dart` (graines fixées). Les critères de la
demande L7 §5 sont évalués ici et dans les tests Dart ; la définition des
critères (95e centile, maximum rapporté) est au contrat L7 §8.

    python3 tools/koach_simulation.py            # rapport des critères
    python3 tools/koach_simulation.py --json     # rapport JSON
"""
import json
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import koach_reference as kr  # noqa: E402


class Rng:
    """mulberry32 (32 bits) + Box-Muller."""

    def __init__(self, seed):
        self.s = seed & 0xFFFFFFFF

    def next(self):
        self.s = (self.s + 0x6D2B79F5) & 0xFFFFFFFF
        t = self.s
        t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF
        t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF
        return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0

    def gauss(self):
        u1 = max(self.next(), 1e-12)
        u2 = self.next()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2)


BW = 71.5
K_PRIOR = 22.4
X0 = 110.0
# Vague de 3 semaines (séries, reps, RIR visé) ; % déduit de la courbe a priori.
WAVE = [(5, 5, 3), (5, 4, 2), (4, 3, 2)]


def trajectory(kind, week):
    if kind == 'prog':
        return X0 * (1.0 + 0.005 * week)
    if kind == 'plateau':
        return X0
    if kind == 'drop':
        return X0 if week < 6 else X0 * 0.95
    raise ValueError(kind)


def ts(day, minute):
    return kr.iso(day * kr.DAY + 18 * 3600.0 + minute * 60.0)


def simulate(seed, traj='plateau', prior_err=0.0, beta=0, sessions=12, bad_day=None, incidents=0.05,
             koach=False, tests=(), k_true=K_PRIOR, mark=True, dose=False, cached=False):
    """Une séance de traction lestée par semaine (athlète de 71,5 kg, 1RM
    système 110 kg). `koach` : suggestions D24 et propositions acceptées."""
    rng = Rng(seed)
    pil = kr.near_grid((X0 - BW) * (1.0 + prior_err) + prior_err * BW, 1.25)
    inp = {
        'now': ts(0, 0),
        'lifts': [{'key': 'pull', 'ref': 'B8', 'bodyweight': True, 'k': K_PRIOR, 'grid': 1.25}],
        'repmax': [], 'accessories': [],
        'references': {'B4': BW, 'B8': pil},
        'history': [{'at': ts(0, -60), 'ref': 'B8', 'value': pil, 'source': 'initial'}],
        'weighIns': [{'date': ts(0, 0)[:10], 'kg': BW}],
        'sessions': [],
    }
    hist = []
    gain = 1.0
    cache = None
    for w in range(sessions):
        day = 7 * w + 1
        xt = trajectory(traj, w) * gain
        f = 0.92 if bad_day == w else 1.0
        sess = {'key': 'S%d-J1' % (w + 1), 'week': w + 1, 'day': 1, 'done': True,
                'finishedAt': ts(day, 60), 'exercises': []}
        caps = []
        if w in tests:
            best = kr.floor_grid(xt * f - BW, 1.25)
            sets = [{'kg': kr.r2(best * 0.8), 'reps': 1, 'rir': None, 'excluded': False, 'done': True, 'at': ts(day, 0)},
                    {'kg': kr.r2(best), 'reps': 1, 'rir': None, 'excluded': False, 'done': True, 'at': ts(day, 5)}]
            sess['exercises'].append({'id': 'T', 'cat': 'test1rm', 'ref': 'B8', 'restSec': 300, 'rirTarget': None,
                                      'plannedReps': 1, 'cluster': False, 'sets': sets})
        else:
            n_sets, reps, target = WAVE[w % len(WAVE)]
            lest = kr.pct(reps + target, K_PRIOR) * (pil + BW) - BW
            lest = max(0.0, kr.near_grid(lest, 1.25 if koach else 2.5))
            sets = []
            effective = 0
            for j in range(n_sets):
                m = lest + BW
                cap = 1.0 + k_true * (xt * f / m - 1.0)
                st = {'kg': kr.r2(lest), 'excluded': False, 'done': True, 'at': ts(day, 3 * j)}
                incident = rng.next() < incidents
                noise = rng.gauss()
                if cap < reps:
                    st['reps'] = max(1, int(math.floor(cap)))
                    st['rir'] = 0.0
                    effective += 1
                else:
                    st['reps'] = reps
                    true_rir = cap - reps
                    st['rir'] = float(min(5.0, max(0.0, kr.rnd(true_rir + noise + beta))))
                    if true_rir <= 3.0:
                        effective += 1
                if incident:
                    st['reps'] = max(1, st['reps'] - 2)
                    st['rir'] = 0.0
                    st['excluded'] = mark or rng.next() < 0.5
                sets.append(st)
                if koach:
                    done = [{'kg': s['kg'], 'reps': s['reps'], 'rir': s['rir']} for s in sets if not s['excluded']]
                    sug = kr.in_session(kr.PARAMS, {'bodyweight': True}, done, target, reps, BW, 1.25, {})
                    if sug is not None:
                        caps.append((sug['from'], sug['kg'], sug['delta']))
                        lest = sug['kg']
            sess['exercises'].append({'id': 'W', 'cat': 'strength', 'ref': 'B8', 'restSec': 180, 'rirTarget': target,
                                      'plannedReps': reps, 'cluster': False, 'sets': sets})
            if dose:
                # Modèle informatif : le gain dépend de la part de séries
                # réellement proches de l'échec (RIR réel ≤ 3).
                gain *= 1.0 + 0.006 * (effective / float(n_sets)) - 0.002
        inp['sessions'].append(sess)
        inp['now'] = ts(day, 90)
        if cached:
            state = kr.replay_incremental(inp, cache)
            cache = state
        else:
            state = kr.replay(inp)
        tr = state['tracks']['pull']
        applied = None
        before = pil
        weeks = kr.weeks_since_change(inp, 'B8', kr.parse_dt(inp['now']), kr.PARAMS)
        if koach:
            for pr in kr.proposals(inp, state, sess['key']):
                if pr['ref'] == 'B8':
                    applied = pr['to']
                    inp['history'].append({'at': ts(day, 95), 'ref': 'B8', 'value': pr['to'], 'source': 'koach'})
                    inp['references']['B8'] = pr['to']
                    pil = pr['to']
        hist.append({'week': w, 'x': tr.x, 'sd': math.sqrt(tr.P), 'true': xt, 'bias': state['bias']['b'],
                     'biasUpdates': state['bias']['updates'], 'pil': pil, 'before': before, 'applied': applied,
                     'k': tr.k, 'weeks': weeks, 'inSession': caps})
    return hist, inp


def p95(values):
    v = sorted(values)
    return v[int(0.95 * (len(v) - 1))]


def criteria(n=60):
    rep = {}
    e6 = []
    for seed in range(n):
        for traj in ('prog', 'plateau', 'drop'):
            h, _ = simulate(1000 + seed, traj, 0.0, 0, sessions=6)
            e6.append(abs(h[5]['x'] - h[5]['true']) / h[5]['true'])
    rep['C1'] = ('erreur après 6 séances, a priori juste', p95(e6), max(e6), 0.03)
    c6 = []
    for seed in range(n):
        for pe in (0.15, -0.15):
            for traj in ('prog', 'plateau'):
                h, _ = simulate(2000 + seed, traj, pe, 0, sessions=6, koach=True)
                c6.append(abs(h[5]['x'] - h[5]['true']) / h[5]['true'])
    rep['C2'] = ('erreur après 6 séances, a priori faux de ±15 %', p95(c6), max(c6), 0.03)
    bd = []
    for seed in range(n):
        a, _ = simulate(3000 + seed, 'plateau', 0.0, 0, sessions=10, incidents=0.0)
        b, _ = simulate(3000 + seed, 'plateau', 0.0, 0, sessions=10, bad_day=8, incidents=0.0)
        bd.append(abs(b[8]['x'] - a[8]['x']) / a[8]['x'])
    rep['C3'] = ('déplacement par un mauvais jour isolé (−8 %)', p95(bd), max(bd), 0.01)
    bi = []
    for seed in range(n):
        for beta in (-1, 0, 1):
            h, _ = simulate(4000 + seed, 'plateau', 0.0, beta, sessions=9, tests=(3, 7))
            bi.append(abs(h[-1]['bias'] + beta))
    rep['C4'] = ('erreur sur le biais de RIR après 2 tests (RIR)', p95(bi), max(bi), 0.5)
    worst = 0
    cap_violations = 0
    for seed in range(n):
        h, _ = simulate(5000 + seed, 'plateau', 0.0, 0, sessions=24, koach=True)
        dirs = []
        for e in h:
            if e['applied'] is not None:
                dirs.append((e['week'], 1 if e['applied'] > e['before'] else -1))
                lo = (e['before'] + BW) * (1 - kr.PARAMS['cap_down'] * e['weeks']) - BW
                hi = (e['before'] + BW) * (1 + kr.PARAMS['cap_up'] * e['weeks']) - BW
                if e['applied'] > hi + 1e-9 or e['applied'] < lo - 1e-9:
                    cap_violations += 1
            for frm, to, delta in e['inSession']:
                if to - frm > (kr.PARAMS['up_big_cap'] if delta > 0.04 else kr.PARAMS['up_small_cap']) + 1e-9:
                    cap_violations += 1
        for i in range(6, 21):
            window = [d for wk, d in dirs if i <= wk < i + 4]
            changes = sum(1 for a, b in zip(window, window[1:]) if a != b)
            worst = max(worst, changes)
    rep['C5'] = ('changements de sens des propositions sur 4 séances (régime stable)', worst, worst, 1)
    rep['C6'] = ('dépassements des plafonds D20 / D24', cap_violations, cap_violations, 0)
    diff = 0.0
    for seed in range(10):
        a, _ = simulate(6000 + seed, 'prog', 0.05, 1, sessions=12, tests=(4, 9), koach=True)
        b, _ = simulate(6000 + seed, 'prog', 0.05, 1, sessions=12, tests=(4, 9), koach=True, cached=True)
        for x, y in zip(a, b):
            diff = max(diff, abs(x['x'] - y['x']), abs(x['sd'] - y['sd']), abs(x['bias'] - y['bias']))
    rep['C7'] = ('écart rejeu complet / cache incrémental (kg)', diff, diff, 0.01)
    return rep


def informative(n=40):
    """Résultats informatifs, dépendants du modèle (jamais une preuve)."""
    out = {}
    e = []
    for seed in range(n):
        for traj in ('prog', 'plateau'):
            h, _ = simulate(7000 + seed, traj, 0.0, 0, sessions=6, mark=False, incidents=0.1)
            e.append(abs(h[5]['x'] - h[5]['true']) / h[5]['true'])
    out['incidents non signalés (10 %) : erreur après 6 séances, p95'] = p95(e)
    ks = []
    for seed in range(n):
        h, _ = simulate(8000 + seed, 'plateau', 0.0, 0, sessions=20, tests=(3, 7, 11, 15, 19), k_true=28.0)
        ks.append(h[-1]['k'])
    out['k personnel (vrai k = 28, a priori 22,4) après 5 tests : moyenne'] = sum(ks) / len(ks)
    reach_fixed = reach_koach = 0
    final_fixed = final_koach = 0.0
    for seed in range(n):
        a, _ = simulate(9000 + seed, 'plateau', 0.0, 0, sessions=24, dose=True)
        b, _ = simulate(9000 + seed, 'plateau', 0.0, 0, sessions=24, dose=True, koach=True)
        final_fixed += a[-1]['true'] / X0 - 1.0
        final_koach += b[-1]['true'] / X0 - 1.0
        reach_fixed += 1 if a[-1]['true'] >= X0 * 1.05 else 0
        reach_koach += 1 if b[-1]['true'] >= X0 * 1.05 else 0
    out['programme fixe : gain moyen sur 24 séances'] = final_fixed / n
    out['Koach : gain moyen sur 24 séances'] = final_koach / n
    out['programme fixe : part atteignant +5 %'] = reach_fixed / float(n)
    out['Koach : part atteignant +5 %'] = reach_koach / float(n)
    return out


def main(argv):
    rep = criteria()
    ok = True
    lines = []
    for key, (name, v95, vmax, limit) in rep.items():
        good = (vmax <= limit + 1e-12) if key in ('C5', 'C6', 'C7') else (v95 <= limit + 1e-12)
        ok = ok and good
        lines.append({'id': key, 'critère': name, 'p95': v95, 'max': vmax, 'seuil': limit, 'ok': good})
    info = informative()
    if '--json' in argv:
        print(json.dumps({'criteres': lines, 'informatif': info}, ensure_ascii=False, indent=1))
    else:
        for l in lines:
            print('%s %-62s p95 %.4f  max %.4f  seuil %s  %s' % (l['id'], l['critère'], l['p95'], l['max'], l['seuil'],
                                                                  'OK' if l['ok'] else 'ÉCHEC'))
        for k, v in info.items():
            print('   (informatif) %-66s %.4f' % (k, v))
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
