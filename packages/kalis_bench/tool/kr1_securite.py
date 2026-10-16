#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sécurité du couple `kalis_plan` × Koach (lot KR1) : agrège les parts de
campagne de `bin/km2.dart --partie i/n` (schéma `kalis_bench/km2_partie/1`)
en violations réalisées par type, par profil, par scénario et par modèle de
vérité, sans charger les critères (les parts de cent graines ne tiennent pas
en mémoire d'un seul `assembler`).

    python3 -I tool/kr1_securite.py --sortie securite.json [--md SECURITE.md] <parts…|dossiers…>
    python3 -I tool/kr1_securite.py --extraire <dossier> <parts…>   # une saison par fichier
        (`<cle>__<scenario>__<verite>__<graine>.json` : saison, calibration ; lu
        par `reference/banc/calibration_grappes.py`, critère 5)

Définitions (lues dans `securite` de chaque saison, `kmSecuriteSaison`) :

* **réalisées** : constats du validateur de sécurité du banc (`safetyFindings`)
  sur la saison servie (`servi_tests_faits` : chaque séance faite remplacée par
  les items servis par Koach, tests ajoutés comptés pour leurs tentatives
  faites), toutes catégories : `deja_initial` (constat déjà dans le plan
  initial de `kalis_plan`), `aggrave`, `introduit` (par Koach) et
  `retour_ecrit` (semaine servie telle qu'écrite après des semaines servies
  plus légères) ; plus les aggravations et poussées de douleur de l'athlète
  simulé et les hausses de charge de plus de 10 % sur plusieurs crans ;
* **critère 7 du cahier** (inchangé, `kmCritereSecurite`) : `introduit` +
  `aggrave` de `plan_module` et de `servi_tests_faits`, plus les douleurs et
  les hausses ;
* rapporté à part : `initial` (le plan de `kalis_plan` seul), `plan_module`
  (blocs modulés par la planification, non servis tels quels) et `servi`
  (rampes de test comptées comme séries dures).
"""
import argparse
import collections
import gzip
import json
import os
import sys

CATS = ('deja_initial', 'aggrave', 'introduit', 'retour_ecrit')
VUES = ('plan_module', 'servi', 'servi_tests_faits')


def _parts(chemins):
    out = []
    for c in chemins:
        if os.path.isdir(c):
            for racine, _, fichiers in os.walk(c):
                for f in fichiers:
                    if f.endswith('.json.gz') and '_partie_' in f:
                        out.append(os.path.join(racine, f))
        else:
            out.append(c)
    return sorted(set(out))


def _ajouter(cpt, d):
    for k, v in (d or {}).items():
        cpt[k] += int(v)


def agreger(chemins):
    total = collections.Counter()
    par_vue = {v: {c: collections.Counter() for c in CATS} for v in VUES}
    initial = collections.Counter()
    par_profil = collections.defaultdict(collections.Counter)
    par_scenario = collections.defaultdict(collections.Counter)
    par_verite = collections.defaultdict(collections.Counter)
    par_graine0 = collections.Counter()
    critere7 = collections.Counter()
    douleur = collections.Counter()
    touchees = 0
    saisons = 0
    plantages = []
    exemples = []
    vus = set()
    graines = set()
    profils = set()
    for p in _parts(chemins):
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        for nom, r in d.get('saisons', {}).items():
            if nom in vus:
                continue
            vus.add(nom)
            cle, scen, v, g = r['saison']
            graines.add(g)
            profils.add(cle)
            saisons += 1
            if 'plantage' in r or 'securite' not in r:
                plantages.append({'saison': r['saison'], 'plantage': r.get('plantage')})
                continue
            s = r['securite']
            _ajouter(initial, s.get('initial'))
            for vue in VUES:
                for c in CATS:
                    _ajouter(par_vue[vue][c], (s.get(vue) or {}).get(c))
            real = collections.Counter()
            for c in CATS:
                _ajouter(real, (s.get('servi_tests_faits') or {}).get(c))
            agg = int(r.get('aggravations') or 0)
            fl = int(r.get('poussees') or 0)
            ha = int((r.get('effort') or {}).get('hausses_trop_fortes') or 0)
            if agg:
                real['douleur_aggravee'] += agg
            if fl:
                real['poussee_douleur'] += fl
            if ha:
                real['hausse_charge_plusieurs_crans'] += ha
            douleur['aggravations'] += agg
            douleur['poussees'] += fl
            douleur['hausses_trop_fortes'] += ha
            c7 = collections.Counter()
            for vue in ('plan_module', 'servi_tests_faits'):
                for c in ('introduit', 'aggrave'):
                    _ajouter(c7, (s.get(vue) or {}).get(c))
            n7 = sum(c7.values()) + agg + fl + ha
            critere7['total'] += n7
            n = sum(real.values())
            total.update(real)
            if n:
                touchees += 1
                par_profil[cle].update(real)
                par_scenario[scen].update(real)
                par_verite[v].update(real)
                if g == 0:
                    par_graine0.update(real)
                if len(exemples) < 40:
                    exemples.append({'saison': r['saison'], 'constats': dict(real),
                                     'exemples': (s.get('servi_tests_faits_exemples') or [])[:6]})
    return {
        'schema': 'kalis_bench/kr1_securite/1',
        'parts': len(_parts(chemins)),
        'saisons': saisons,
        'profils': len(profils),
        'graines': [min(graines), max(graines)] if graines else None,
        'plantages': len(plantages),
        'plantages_exemples': plantages[:10],
        'realisees': {'total': sum(total.values()), 'par_code': dict(sorted(total.items())),
                      'saisons_touchees': touchees},
        'realisees_graine_0': {'total': sum(par_graine0.values()), 'par_code': dict(sorted(par_graine0.items()))},
        'critere_7_cahier': critere7['total'],
        'douleur_et_hausses': dict(douleur),
        'initial_kalis_plan': dict(sorted(initial.items())),
        'vues': {v: {c: dict(sorted(par_vue[v][c].items())) for c in CATS} for v in VUES},
        'par_profil': {k: dict(sorted(par_profil[k].items())) for k in sorted(par_profil)},
        'par_scenario': {k: dict(sorted(par_scenario[k].items())) for k in sorted(par_scenario)},
        'par_verite': {k: dict(sorted(par_verite[k].items())) for k in sorted(par_verite)},
        'exemples': exemples,
    }


def markdown(r):
    L = ['# Sécurité du couple `kalis_plan` × Koach (lot KR1)', '',
         '%d saisons (%d profils, graines %s), %d parts, %d plantées.' % (
             r['saisons'], r['profils'], r['graines'], r['parts'], r['plantages']), '',
         '- Violations réalisées (saison servie, toutes catégories, douleurs et hausses) : **%d** '
         '(%d saisons touchées) ; graine 0 : %d.' % (r['realisees']['total'], r['realisees']['saisons_touchees'],
                                                     r['realisees_graine_0']['total']),
         '- Critère 7 du cahier (introduits ou aggravés par Koach, douleurs, hausses) : **%d**.' % r['critere_7_cahier'],
         '- Plan initial de `kalis_plan` (constats comptés une fois par saison) : %s.' % (r['initial_kalis_plan'] or '0'),
         '', '## Par code', '', '| Code | Réalisées |', '| --- | --- |']
    for k, v in r['realisees']['par_code'].items():
        L.append('| `%s` | %d |' % (k, v))
    L += ['', '## Par vue et catégorie', '', '| Vue | ' + ' | '.join(CATS) + ' |',
          '| --- |' + ' --- |' * len(CATS)]
    for v in VUES:
        L.append('| %s | %s |' % (v, ' | '.join(
            ', '.join('%s %d' % kv for kv in r['vues'][v][c].items()) or '0' for c in CATS)))
    for titre, cle in (('Par profil', 'par_profil'), ('Par scénario', 'par_scenario'),
                       ('Par modèle de vérité', 'par_verite')):
        L += ['', '## ' + titre, '', '| | Total | Codes |', '| --- | --- | --- |']
        for k, d in r[cle].items():
            L.append('| `%s` | %d | %s |' % (k, sum(d.values()), ', '.join('%s %d' % kv for kv in d.items())))
    return '\n'.join(L) + '\n'


def extraire(dossier, chemins):
    os.makedirs(dossier, exist_ok=True)
    n = 0
    for p in _parts(chemins):
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        for nom, r in d.get('saisons', {}).items():
            x = {'saison': r['saison']}
            if 'plantage' in r:
                x['plantage'] = r['plantage']
            else:
                x['calibration'] = r['calibration']
            with open(os.path.join(dossier, nom + '.json'), 'w', encoding='utf-8') as f:
                json.dump(x, f)
            n += 1
    return n


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--sortie')
    ap.add_argument('--md')
    ap.add_argument('--extraire')
    ap.add_argument('entrees', nargs='+')
    a = ap.parse_args(argv)
    if a.extraire:
        print('%d saisons extraites dans %s' % (extraire(a.extraire, a.entrees), a.extraire))
        return 0
    if not a.sortie:
        ap.error('--sortie attendu')
    r = agreger(a.entrees)
    with open(a.sortie, 'w', encoding='utf-8') as f:
        json.dump(r, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write('\n')
    if a.md:
        with open(a.md, 'w', encoding='utf-8') as f:
            f.write(markdown(r))
    print('saisons %d, réalisées %d, critère 7 %d, plantées %d' % (
        r['saisons'], r['realisees']['total'], r['critere_7_cahier'], r['plantages']))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
