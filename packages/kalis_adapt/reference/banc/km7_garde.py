# -*- coding: utf-8 -*-
"""Lot KM7 (Koach 1.0.9, DECISIONS_CP.md C17.54) : mesure de la variante
« l'athlète garde l'écrit une fois sur deux en mode Libre » (campagne
Python `--bilan-garde verse` / `--bilan-garde non_verse`, graines 0-5) et de
la campagne ordinaire sur les mêmes graines.

    python3 -m banc.km7_garde --nom verse <dossier de travail>... --sortie x.json

Lit les saisons des dossiers (fichiers `<profil>__<scénario>__<vérité>__<graine>.json`
de `campagne.executer`), garde celles des graines demandées, et calcule :

- la variante : séances gardées, plans du bilan versé identiques au plan
  des seuls faits (témoin dans la même séance, `PolitiqueKoach.planifier`),
  erreur de prédiction des séances (résidu relatif moyen de la séance,
  |·| ; e1RM de la séance, |·|) : séances qui suivent une séance gardée,
  séances gardées, toutes ;
- les critères du cahier qui lisent l'estimation et la séance (1 e1RM,
  3 convergence, 4 couverture, 6 jour J, 7 sécurité) par les fonctions de
  `campagne` (mêmes définitions que la campagne ordinaire).
"""
import argparse
import json
import os
import sys

from . import campagne as cp


def _saisons(dossiers, graines):
    out = {}
    for d in dossiers:
        for r, _, fs in os.walk(d):
            for f in fs:
                if not f.endswith('.json') or f.count('__') != 3:
                    continue
                with open(os.path.join(r, f), encoding='utf-8') as h:
                    x = json.load(h)
                s = x.get('saison')
                if not s or s[3] not in graines:
                    continue
                out[tuple(s)] = x
    return out


def _moy(p):
    return p[0] / p[1] if p[1] else None


def mesurer(dossiers, graines=range(6)):
    graines = set(graines)
    res = _saisons(dossiers, graines)
    jobs = sorted(res)
    ok = [res[j] for j in jobs if 'plantage' not in res[j]]
    plantees = len(jobs) - len(ok)
    temoin = cp.charger_temoin(jobs)
    K, KV, KN, T, TV, TN = cp.agreger_estimations(ok, temoin)
    opts = cp.options_de([])
    criteres = {
        '1_erreur_e1rm_rang_6': cp.critere_e1rm(K, KV, KN, T, TV, TN),
        '3_convergence_sous_3': cp.critere_convergence(K, KV, T, TV),
        '4_couverture_90': cp.critere_couverture(K, KV, opts),
        '6_performance_jour_j': cp.critere_jour_j(ok, temoin),
        '7_securite': cp.critere_securite(ok, temoin, False),
    }
    g = {}
    for x in ok:
        for k, v in (x.get('garde') or {}).items():
            if k == 'premier_ecart':
                if v is not None:
                    g['saisons_avec_ecart'] = g.get('saisons_avec_ecart', 0) + 1
                continue
            if isinstance(v, list):
                a = g.setdefault(k, [0.0, 0])
                a[0] += v[0]
                a[1] += v[1]
            elif isinstance(v, (int, float)) and not isinstance(v, bool):
                g[k] = g.get(k, 0) + v
    erreurs = {k: _moy(v) for k, v in g.items() if isinstance(v, list)}
    return cp._arrondir({'saisons': len(jobs), 'plantees': plantees, 'graines': sorted(graines),
                         'garde': {k: v for k, v in g.items() if not isinstance(v, list)},
                         'erreurs': erreurs, 'comptes': {k: v[1] for k, v in g.items() if isinstance(v, list)},
                         'criteres': criteres})


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument('dossiers', nargs='+')
    ap.add_argument('--nom', required=True)
    ap.add_argument('--graines', default='0-5')
    ap.add_argument('--sortie', required=True)
    a = ap.parse_args(argv)
    lo, hi = (int(x) for x in a.graines.split('-'))
    r = mesurer(a.dossiers, range(lo, hi + 1))
    r['nom'] = a.nom
    with open(a.sortie, 'w', encoding='utf-8') as f:
        json.dump(r, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write('\n')
    print(a.nom, json.dumps({k: r[k] for k in ('saisons', 'plantees', 'garde', 'erreurs')}, ensure_ascii=False))
    for k, c in r['criteres'].items():
        print(' ', k, json.dumps({x: c.get(x) for x in ('valeur', 'respecte') if x in c}, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
