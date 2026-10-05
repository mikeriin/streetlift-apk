#!/usr/bin/env python3
"""Sauts de charge lestée d'une semaine à l'autre dans les saisons (export JSON)."""
import json, re, sys, glob, os
def parse(load):
    m = re.search(r'lest \+([\d,]+) kg', load or '')
    p = re.search(r'≈ (\d+) % du 1RM', load or '')
    return (float(m.group(1).replace(',', '.')) if m else None, int(p.group(1)) if p else None)
def reps_of(vol):
    m = re.findall(r'(\d+) × (\d+)', vol or '')
    return m
out = []
for f in sorted(glob.glob(os.path.join(sys.argv[1], 'street_*.json'))):
    d = json.load(open(f)); key = d['key']
    best = {}  # exo -> list per week of (max pct, kg, reps)
    for w in d['weeks']:
        for day in w['days']:
            for it in day['items']:
                kg, pct = parse(it.get('load'))
                if pct is None: continue
                r = reps_of(it.get('volume'))
                reps = min(int(x[1]) for x in r) if r else None
                cur = best.setdefault(it['id'], {}).get(w['week'])
                if cur is None or pct > cur[0]:
                    best[it['id']][w['week']] = (pct, kg, reps, w['kind'])
    for ex, wk in best.items():
        ws = sorted(wk)
        for a, b in zip(ws, ws[1:]):
            if b != a + 1: continue
            pa, pb = wk[a], wk[b]
            if pb[0] - pa[0] >= float(sys.argv[2]) if len(sys.argv) > 2 else 6:
                out.append((key[:9], ex, a, pa, b, pb))
for o in out: print(*o)
print(len(out), 'sauts')
