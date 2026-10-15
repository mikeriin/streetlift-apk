"""Critère 5 : ce que la mesure par déciles peut conclure (KM1 correction 2).

Les cas jugés par le critère 5 (une prévision par cible, 4 semaines avant
l'échéance) ne sont pas indépendants : un même athlète (profil, graine) et une
même cible reviennent dans chaque scénario et chaque vérité, avec presque
toujours la même issue. Ce module regroupe les cas par grappe (graine, profil,
exercice) et mesure :
  - le nombre de grappes et la part des grappes à issue unique ;
  - le biais global prévu − observé des cas à P >= 10 %, avec un intervalle
    par rééchantillonnage des grappes ;
  - la distribution de l'écart maximal par décile (n >= 30) qu'obtiendrait un
    modèle parfaitement calibré dont les issues sont liées dans la grappe
    (même tirage uniforme pour tous les cas de la grappe).

Usage : python3 -m banc.calibration_grappes <dossier de travail de la campagne> [sortie.json]
"""
import collections
import glob
import json
import math
import os
import random
import sys


def cas(dossier):
    lignes = []
    for f in sorted(glob.glob(os.path.join(dossier, '*__*__*__*.json'))):
        if os.path.basename(f).startswith('mauvais_jour'):
            continue
        r = json.load(open(f))
        if 'plantage' in r:
            continue
        cle, _scen, _verite, graine = r['saison']
        for u in r['calibration']['unites']:
            p4 = u['previsions'].get('moins_4_semaines')
            if p4 is None or not p4.get('p'):
                continue
            for ex, p in p4['p'].items():
                if ex in u['reussite_par_cible']:
                    lignes.append((graine, cle, ex, p, bool(u['reussite_par_cible'][ex])))
    return lignes


def ecart_max(paires, nmin=30):
    pire = None
    for d in range(10):
        sel = [(p, o) for p, o in paires if min(9, int(math.floor(p * 10))) == d]
        if len(sel) < nmin:
            continue
        e = abs(sum(p for p, _ in sel) / len(sel) - sum(1 for _, o in sel if o) / len(sel))
        if pire is None or e > pire:
            pire = e
    return pire


def mesurer(dossier, tirages=2000, graine=1):
    lignes = cas(dossier)
    grappes = collections.defaultdict(list)
    for g, cle, ex, p, ok in lignes:
        grappes[(g, cle, ex)].append((p, ok))
    alea = random.Random(graine)
    observe = ecart_max([(p, ok) for _, _, _, p, ok in lignes])
    simules = []
    for _ in range(tirages):
        paires = []
        for v in grappes.values():
            u = alea.random()
            paires += [(p, u < p) for p, _ in v]
        simules.append(ecart_max(paires))
    simules.sort()
    cles = sorted(grappes)

    def biais(ks):
        s = [x for k in ks for x in grappes[k] if x[0] >= 0.1]
        return sum(p for p, _ in s) / len(s) - sum(1 for _, o in s if o) / len(s)

    b = sorted(biais([alea.choice(cles) for _ in cles]) for _ in range(tirages))
    q = lambda xs, a: xs[min(len(xs) - 1, int(a * len(xs)))]
    return {
        'cas': len(lignes),
        'grappes': len(grappes),
        'grappes_a_issue_mixte': sum(1 for v in grappes.values() if 0 < sum(1 for _, o in v if o) < len(v)),
        'grappes_avec_p_10_pct_ou_plus': sum(1 for v in grappes.values() if any(p >= 0.1 for p, _ in v)),
        'cas_p_10_pct_ou_plus': sum(1 for _, _, _, p, _ in lignes if p >= 0.1),
        'ecart_max_observe': round(observe, 6),
        'modele_parfait_issues_liees': {
            'tirages': tirages,
            'mediane': round(q(simules, 0.5), 6), 'q10': round(q(simules, 0.1), 6), 'q90': round(q(simules, 0.9), 6),
            'part_sous_5_points': round(sum(1 for s in simules if s <= 0.05) / tirages, 4),
            'part_au_moins_l_observe': round(sum(1 for s in simules if s >= observe) / tirages, 4),
        },
        'biais_prevu_moins_observe_p_10_pct_ou_plus': {
            'valeur': round(biais(cles), 6), 'ic90_par_grappes': [round(q(b, 0.05), 6), round(q(b, 0.95), 6)],
        },
    }


if __name__ == '__main__':
    res = mesurer(sys.argv[1])
    texte = json.dumps(res, ensure_ascii=False, indent=1, sort_keys=True)
    if len(sys.argv) > 2:
        open(sys.argv[2], 'w').write(texte + '\n')
    print(texte)
