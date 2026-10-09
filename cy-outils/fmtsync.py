#!/usr/bin/env python3
"""Recopie les sources formatées par aa_fmt (ci-out) dans l'arbre de travail,
seulement pour les fichiers inchangés depuis le contrôle poussé (/tmp/cyci)."""
import os, sys, filecmp, shutil
ci = sys.argv[1]  # .../ci-out/packages/aa_fmt
wt = '/home/claude/mot/packages'
pushed = '/tmp/cyci/packages'
n = 0
for root, _, files in os.walk(ci):
    for f in files:
        if not f.endswith('.dart'):
            continue
        src = os.path.join(root, f)
        rel = os.path.relpath(src, ci)
        dst = os.path.join(wt, rel)
        old = os.path.join(pushed, rel)
        if not os.path.exists(dst) or not os.path.exists(old):
            continue
        if not filecmp.cmp(dst, old, shallow=False):
            print('modifié depuis, non recopié :', rel); continue
        if not filecmp.cmp(dst, src, shallow=False):
            shutil.copy(src, dst); n += 1; print('formaté :', rel)
print(n, 'fichier(s)')
