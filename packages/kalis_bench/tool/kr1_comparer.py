#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parité saison par saison de la campagne du couple (lot KR1) : mesures de
chaque saison de la campagne Dart (`bin/km2.dart --partie`, parts
`kalis_bench/km2_partie/1`) contre celles de la référence Python
(`reference/banc/campagne.py --partie`, dossier de travail : un fichier
`<cle>__<scenario>__<verite>__<graine>.json` par saison).

    python3 -I tool/kr1_comparer.py --sortie parite.json <dossier de travail Python> <parts Dart…>

Clés comparées : celles des deux côtés sauf `duree_s` (temps) ; flottants à
1e-9 relatif (`|a − b| <= 1e-9 · max(1, |a|, |b|)`), entiers et textes à
l'identique. Sortie : nombre de saisons comparées, égales, écarts (premiers
chemins).
"""
import argparse
import glob
import gzip
import json
import math
import os
import sys

TOL = 1e-9
IGNORER = {'duree_s'}


def _egal(a, b, chemin, ecarts):
    if isinstance(a, bool) or isinstance(b, bool):
        if a != b:
            ecarts.append((chemin, a, b))
        return
    if isinstance(a, (int, float)) and isinstance(b, (int, float)):
        if isinstance(a, float) or isinstance(b, float):
            fa, fb = float(a), float(b)
            if math.isnan(fa) or math.isnan(fb) or math.isinf(fa) or math.isinf(fb):
                if not (fa == fb or (math.isnan(fa) and math.isnan(fb))):
                    ecarts.append((chemin, a, b))
                return
            if abs(fa - fb) > TOL * max(1.0, abs(fa), abs(fb)):
                ecarts.append((chemin, a, b))
        elif a != b:
            ecarts.append((chemin, a, b))
        return
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k in IGNORER:
                continue
            if k not in a or k not in b:
                ecarts.append((chemin + '/' + k, 'absent' if k not in a else 'présent',
                               'absent' if k not in b else 'présent'))
                continue
            _egal(a[k], b[k], chemin + '/' + k, ecarts)
        return
    if isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            ecarts.append((chemin + '#len', len(a), len(b)))
            return
        for i, (x, y) in enumerate(zip(a, b)):
            _egal(x, y, '%s[%d]' % (chemin, i), ecarts)
        return
    if a != b:
        ecarts.append((chemin, a, b))


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--sortie', required=True)
    ap.add_argument('python')
    ap.add_argument('parts', nargs='+')
    a = ap.parse_args(argv)
    py = {}
    doublons = []
    for f in sorted(glob.glob(os.path.join(a.python, '**', '*__*__*__*.json'), recursive=True)):
        n = os.path.basename(f)[:-5]
        if n.startswith('mauvais_jour'):
            continue
        if n in py:
            doublons.append(n)
        py[n] = f
    if doublons:
        raise SystemExit('saisons Python en double (plusieurs dossiers de travail) : %s' % doublons[:5])
    vues_dart = set()
    comparees = egales = 0
    absentes = []
    ecarts_saisons = []
    for p in a.parts:
        with gzip.open(p, 'rt', encoding='utf-8') as fh:
            d = json.load(fh)
        for nom, r in d['saisons'].items():
            vues_dart.add(nom)
            if nom not in py:
                absentes.append(nom)
                continue
            with open(py[nom], encoding='utf-8') as fh:
                q = json.load(fh)
            e = []
            _egal(q, r, '', e)
            comparees += 1
            if e:
                ecarts_saisons.append({'saison': nom, 'n': len(e), 'premiers': [list(map(str, x)) for x in e[:8]]})
            else:
                egales += 1
    out = {'schema': 'kalis_bench/kr1_parite_saisons/1', 'tolerance': TOL, 'python': len(py),
           'comparees': comparees, 'egales': egales, 'absentes_python': len(absentes),
           'absentes_exemples': absentes[:10], 'ecarts': len(ecarts_saisons),
           'ecarts_exemples': ecarts_saisons[:20],
           'python_absentes_dart': sorted(set(py) - vues_dart)[:20]}
    with open(a.sortie, 'w', encoding='utf-8') as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
        fh.write('\n')
    print('parité saison par saison : %d comparées, %d égales, %d avec écarts, %d absentes côté Python'
          % (comparees, egales, len(ecarts_saisons), len(absentes)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
