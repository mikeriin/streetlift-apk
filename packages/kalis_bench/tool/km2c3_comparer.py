#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Campagne Dart contre campagne Python, SAISON PAR SAISON (lot KM2c3).

Le moteur Dart (`kalis_adapt` 1.0.4, Koach 1.0.5) doit refaire exactement la
campagne de la référence Python 1.0.5 du lot KM1c4 (run 39041787498, 20 parts
`banc.campagne --partie i/20`, une saison par fichier
`<dossier de travail>/<empreinte>/<cle>__<scenario>__<verite>__<graine>.json`).
Les parts Dart (`bin/km2.dart --partie i/n`, schéma `kalis_bench/km2_partie/1`)
portent, par saison, le même dictionnaire (`kmMesurerSaison`, portage de
`campagne.mesurer_saison`) : estimations, événements, effort, gain,
aggravations, poussées, séances, alertes, calibration, sécurité.

    python3 -I tool/km2c3_comparer.py --python <dossiers de travail Python…>
        --dart <parts ou dossiers Dart…> --sortie comparaison.json [--md COMPARAISON.md]

Chaque saison Dart est comparée à la saison Python de même nom, champ par
champ (récursif) : entiers et textes à l'identique, flottants à 1e-9 près
(relatif, absolu 1e-12 près de zéro), listes de même longueur, clés
identiques. Sortie : saisons comparées, identiques, différentes (par champ
de tête, avec les 60 premiers écarts : saison, chemin, Dart, Python),
saisons Dart sans saison Python et l'inverse.
"""
import argparse
import collections
import gzip
import json
import math
import os
import sys

TOL_REL = 1e-9
TOL_ABS = 1e-12
EXEMPLES_MAX = 60


def _parts(chemins):
    out = []
    for c in chemins:
        if os.path.isdir(c):
            for r, _, fs in os.walk(c):
                for f in fs:
                    if f.endswith('.json.gz') and 'partie' in f:
                        out.append(os.path.join(r, f))
        else:
            out.append(c)
    return sorted(out)


def _index_python(dossiers):
    """nom de saison -> chemin du fichier Python."""
    idx = {}
    for d in dossiers:
        for r, _, fs in os.walk(d):
            for f in fs:
                if f.endswith('.json') and f.count('__') == 3:
                    idx[f[:-5]] = os.path.join(r, f)
    return idx


def _num(x):
    if isinstance(x, str) and x in ('nan', 'inf', '-inf', 'NaN', 'Infinity', '-Infinity'):
        return float(x.replace('Infinity', 'inf'))
    return x


def _egaux_nombres(a, b):
    if isinstance(a, bool) or isinstance(b, bool):
        return a is b
    fa, fb = float(a), float(b)
    if math.isnan(fa) or math.isnan(fb):
        return math.isnan(fa) and math.isnan(fb)
    if math.isinf(fa) or math.isinf(fb):
        return fa == fb
    d = abs(fa - fb)
    return d <= TOL_ABS or d <= TOL_REL * max(abs(fa), abs(fb))


def comparer(a, b, chemin, ecarts):
    """Ajoute à [ecarts] les (chemin, a, b) qui diffèrent ; rend le nombre
    d'écarts trouvés."""
    a, b = _num(a), _num(b)
    n = 0
    if isinstance(a, (int, float)) and not isinstance(a, bool) and isinstance(b, (int, float)) \
            and not isinstance(b, bool):
        if not _egaux_nombres(a, b):
            ecarts.append((chemin, a, b))
            n += 1
        return n
    if isinstance(a, dict) and isinstance(b, dict):
        for k in sorted(set(a) | set(b)):
            if k not in a or k not in b:
                ecarts.append((chemin + '.' + str(k), a.get(k, '<absent>'), b.get(k, '<absent>')))
                n += 1
            else:
                n += comparer(a[k], b[k], chemin + '.' + str(k), ecarts)
        return n
    if isinstance(a, (list, tuple)) and isinstance(b, (list, tuple)):
        if len(a) != len(b):
            ecarts.append((chemin + '[longueur]', len(a), len(b)))
            return 1
        for i, (x, y) in enumerate(zip(a, b)):
            n += comparer(x, y, '%s[%d]' % (chemin, i), ecarts)
        return n
    if a != b:
        ecarts.append((chemin, a, b))
        n += 1
    return n


def _court(x):
    t = json.dumps(x, ensure_ascii=False, sort_keys=True)
    return t if len(t) <= 160 else t[:157] + '...'


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--python', nargs='+', required=True)
    ap.add_argument('--dart', nargs='+', required=True)
    ap.add_argument('--sortie', required=True)
    ap.add_argument('--md')
    a = ap.parse_args(argv)
    idx = _index_python(a.python)
    vus = set()
    comparees = identiques = 0
    par_champ = collections.Counter()
    saisons_par_champ = collections.Counter()
    differentes = []
    exemples = []
    sans_python = []
    plantees_dart = []
    for p in _parts(a.dart):
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        for nom, r in d.get('saisons', {}).items():
            if nom in vus:
                continue
            vus.add(nom)
            if 'plantage' in r:
                plantees_dart.append(nom)
            chemin = idx.get(nom)
            if chemin is None:
                sans_python.append(nom)
                continue
            with open(chemin, encoding='utf-8') as f:
                py = json.load(f)
            ecarts = []
            comparer(r, py, '', ecarts)
            comparees += 1
            if not ecarts:
                identiques += 1
                continue
            differentes.append(nom)
            champs = set()
            for (c, x, y) in ecarts:
                tete = c.split('.')[1] if c.count('.') >= 1 else c
                tete = tete.split('[')[0]
                par_champ[tete] += 1
                champs.add(tete)
            for t in champs:
                saisons_par_champ[t] += 1
            for (c, x, y) in ecarts[:5]:
                if len(exemples) < EXEMPLES_MAX:
                    exemples.append({'saison': nom, 'chemin': c, 'dart': _court(x), 'python': _court(y)})
    sans_dart = sorted(set(idx) - vus)
    out = {
        'tolerance': {'relative': TOL_REL, 'absolue': TOL_ABS},
        'saisons_dart': len(vus),
        'saisons_python': len(idx),
        'comparees': comparees,
        'identiques': identiques,
        'differentes': len(differentes),
        'ecarts_par_champ': dict(par_champ),
        'saisons_par_champ': dict(saisons_par_champ),
        'liste_differentes': sorted(differentes),
        'exemples': exemples,
        'dart_sans_python': sorted(sans_python),
        'python_sans_dart': sans_dart[:200],
        'python_sans_dart_nombre': len(sans_dart),
        'plantees_dart': sorted(plantees_dart),
    }
    with open(a.sortie, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write('\n')
    if a.md:
        with open(a.md, 'w', encoding='utf-8') as f:
            f.write('# Campagne Dart contre campagne Python, saison par saison (KM2c3)\n\n')
            f.write('| Mesure | Valeur |\n| --- | --- |\n')
            for k in ('saisons_dart', 'saisons_python', 'comparees', 'identiques', 'differentes',
                      'python_sans_dart_nombre'):
                f.write('| %s | %s |\n' % (k, out[k]))
            f.write('| dart_sans_python | %d |\n| plantees_dart | %d |\n\n' % (len(sans_python), len(plantees_dart)))
            if par_champ:
                f.write('Écarts par champ : %s\n\n' % json.dumps(dict(par_champ), ensure_ascii=False))
                for e in exemples:
                    f.write('- `%s` `%s` : Dart %s, Python %s\n' % (e['saison'], e['chemin'], e['dart'], e['python']))
    print('saisons Dart %d, Python %d ; comparées %d, identiques %d, différentes %d ; Dart sans Python %d, '
          'Python sans Dart %d' % (len(vus), len(idx), comparees, identiques, len(differentes), len(sans_python),
                                   len(sans_dart)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
