#!/usr/bin/env python3
"""weekvol.py <saison.json> [motif] : répétitions (ou séries de tenue) par semaine et par exercice."""
import json, re, sys, collections
d = json.load(open(sys.argv[1])); pat = sys.argv[2] if len(sys.argv) > 2 else ''
def reps(vol):
    tot = 0
    for part in re.split(r',| puis ', vol):
        m = re.search(r'(\d+) × (\d+)(?: à (\d+))?(?! ?s)', part)
        if m and not re.search(r'\d+ × \d+(?: à \d+)? ?s', part):
            tot += int(m.group(1)) * int(m.group(2))
    return tot
for w in d['weeks']:
    c = collections.Counter()
    for day in w['days']:
        for it in day['items']:
            if pat and not re.search(pat, it['name'], re.I): continue
            if 'échauffement' in (it.get('notes') or '')[:12]: continue
            c[it['name']] += reps(it['volume'])
    print(w['week'], w['kind'][:14], dict(c))
