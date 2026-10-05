#!/usr/bin/env python3
"""table.py <toutes.json> [<base.json>] : tableau des notes d'ensemble (combinées sur la base)."""
import json, sys, collections
t = json.load(open(sys.argv[1]))
tab = collections.defaultdict(dict)
if len(sys.argv) > 2:
    for k, v in json.load(open(sys.argv[2])).items():
        tab[k].update(v)
for o in t:
    tab[o['source'][:-3]][o['ecole']] = o['ensemble']
E = ['force', 'calisthenie', 'hypertrophie', 'sante']
ok = 0; n = 0; s = 0; mn = 10
for k in sorted(tab):
    row = [tab[k].get(e) for e in E]
    print(f'{k:45}', *[f'{x:>4}' for x in row])
    for x in row:
        if x is None: continue
        n += 1; s += x; ok += x >= 9; mn = min(mn, x)
print(f'{ok}/{n} à 9, min {mn}, moyenne {s/n:.2f}')
json.dump(tab, open(sys.argv[1].replace('.json', '_comb.json'), 'w'), indent=1)
