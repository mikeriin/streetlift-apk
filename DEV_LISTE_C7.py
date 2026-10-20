# -*- coding: utf-8 -*-
"""Liste COMPLÈTE des saisons portant une violation du critère 7 du cahier
(poussées, aggravations, hausses, constats introduits ou aggravés) dans des
parts de campagne `km2.dart --partie` (mise au point KM1c4, KM2c3 ; `kr1_securite.py`
ne garde que 40 exemples)."""
import gzip
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'packages', 'kalis_bench', 'tool'))
import kr1_securite as ks  # noqa: E402


def main(dossier, sortie):
    lignes = []
    vus = set()
    for p in ks._parts([dossier]):
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        for nom, r in d['saisons'].items():
            if nom in vus or 'securite' not in r or 'plantage' in r:
                continue
            vus.add(nom)
            s = r['securite']
            c = (ks._somme(s, 'plan_module', ('introduit', 'aggrave'))
                 + ks._somme(s, 'servi_tests_faits', ('introduit', 'aggrave')))
            agg = int(r.get('aggravations') or 0)
            fl = int(r.get('poussees') or 0)
            ha = int((r.get('effort') or {}).get('hausses_trop_fortes') or 0)
            if agg:
                c['douleur_aggravee'] += agg
            if fl:
                c['poussee_douleur'] += fl
            if ha:
                c['hausse_charge_plusieurs_crans'] += ha
            if sum(c.values()) > 0:
                lignes.append({'saison': r['saison'], 'constats': dict(c),
                               'exemples': (s.get('servi_tests_faits_exemples') or []) + (s.get('plan_module_exemples') or [])})
    lignes.sort(key=lambda l: (l['saison'][0], l['saison'][1], l['saison'][2], l['saison'][3]))
    with open(sortie, 'w', encoding='utf-8') as f:
        json.dump({'saisons': len(vus), 'violations': sum(sum(l['constats'].values()) for l in lignes),
                   'saisons_touchees': len(lignes), 'liste': lignes}, f, ensure_ascii=False, indent=1, sort_keys=True)
    print('%d saisons, %d violations dans %d saisons' % (
        len(vus), sum(sum(l['constats'].values()) for l in lignes), len(lignes)))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
