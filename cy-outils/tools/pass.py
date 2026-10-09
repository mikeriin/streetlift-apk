#!/usr/bin/env python3
"""Prépare une passe du panel : pass.py <id> <dossier exports> <couples.json|all-street|all-autres>
Écrit /tmp/cp2panel/<id>/<ecole>_<n>/ et la liste des appels dans calls.txt."""
import json, sys, os, glob, subprocess
pid, exports, which = sys.argv[1], sys.argv[2], sys.argv[3]
ecoles = ['force', 'calisthenie', 'hypertrophie', 'sante']
files = sorted(glob.glob(f'{exports}/*.md'))
keys = [os.path.basename(f)[:-3] for f in files]
if which.startswith('all-'):
    grp = which[4:]
    couples = [(e, k) for e in ecoles for k in keys if k.startswith(grp)]
else:
    couples = [tuple(c) for c in json.load(open(which))]
calls = []
for e in ecoles:
    ks = [k for (ee, k) in couples if ee == e]
    for i in range(0, len(ks), 4):
        chunk = ks[i:i+4]
        tag = str(i // 4 + 1)
        out = subprocess.run(['python3', '/home/claude/cp2/panel.py', 'prepare', pid, e, tag] + [f'{exports}/{k}.md' for k in chunk], capture_output=True, text=True, check=True).stdout.strip()
        calls.append(out)
open(f'/tmp/cp2panel/{pid}/calls.txt', 'w').write('\n'.join(calls) + '\n')
print(len(couples), 'couples,', len(calls), 'appels')
for c in calls: print(c)
