#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sécurité du couple `kalis_plan` × Koach (lot KR1) : agrège les parts de
campagne de `bin/km2.dart --partie i/n` (n >= 2, schéma `kalis_bench/km2_partie/1`)
en violations par type, par profil, par scénario et par modèle de vérité,
sans charger les critères (les parts de cent graines ne tiennent pas en
mémoire d'un seul `assembler`).

    python3 -I tool/kr1_securite.py --sortie securite.json [--md SECURITE.md] <parts…|dossiers…>
    python3 -I tool/kr1_securite.py --extraire <dossier> <parts…>   # une saison par fichier
        (`<cle>__<scenario>__<verite>__<graine>.json` : saison, calibration ; lu
        par `reference/banc/calibration_grappes.py`, critère 5)

Trois mesures, lues dans `securite` de chaque saison (`kmSecuriteSaison`) :

* **critère 7 du cahier** (`kmCritereSecurite`, inchangé) : constats du
  validateur du banc (`safetyFindings`) `introduit` ou `aggrave` par Koach
  dans le plan modulé (`plan_module`) et dans la saison servie
  (`servi_tests_faits` : séances faites remplacées par les items servis, tests
  comptés pour leurs tentatives faites, séances manquées à leur volume écrit),
  plus les aggravations et poussées de douleur de l'athlète simulé et les
  hausses de charge de plus de 10 % sur plusieurs crans ; les constats
  « retour à l'écrit » sont publiés à part et ne comptent pas (DECISIONS_CP.md
  C13.10.1) ;
* **réalisée appariée** (vue `realise_apparie`, lot KR1) : la saison
  réellement faite (séances manquées vidées) classée contre le plan écrit de
  `kalis_plan` aux MÊMES séances manquées vidées : `introduit` + `aggrave` =
  ce que Koach a servi de plus que le plan, en termes réalisés ;
* **réalisée contre le plan initial** (vue `realise`) : toutes catégories ;
  elle compte aussi la règle de rampe appliquée à une semaine où une séance a
  été manquée, que le plan écrit seul produit autant (relecture KR1, M2) :
  diagnostic, pas une mesure du couple.

Les parts antérieures sans ces vues sont signalées (`saisons_sans_vue_realisee`)
et ne contribuent qu'au critère 7 et au « retour à l'écrit ».
"""
import argparse
import collections
import gzip
import json
import os
import sys

CATS = ('deja_initial', 'aggrave', 'introduit', 'retour_ecrit')
VUES = ('plan_module', 'servi', 'servi_tests_faits', 'realise', 'realise_apparie')


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


def _somme(s, vue, cats):
    c = collections.Counter()
    for cat in cats:
        _ajouter(c, (s.get(vue) or {}).get(cat))
    return c


class _Mesure(object):
    def __init__(self):
        self.total = collections.Counter()
        self.touchees = 0
        self.graine0 = collections.Counter()
        self.par = {d: collections.defaultdict(collections.Counter) for d in ('profil', 'scenario', 'verite')}
        self.exemples = []

    def ajouter(self, r, c, exemples):
        cle, scen, v, g = r['saison']
        self.total.update(c)
        if sum(c.values()):
            self.touchees += 1
            self.par['profil'][cle].update(c)
            self.par['scenario'][scen].update(c)
            self.par['verite'][v].update(c)
            if g == 0:
                self.graine0.update(c)
            if len(self.exemples) < 40:
                self.exemples.append({'saison': r['saison'], 'constats': dict(c), 'exemples': exemples[:6]})

    def json(self):
        return {'total': sum(self.total.values()), 'par_code': dict(sorted(self.total.items())),
                'saisons_touchees': self.touchees, 'graine_0': sum(self.graine0.values()),
                'par_profil': {k: dict(sorted(v.items())) for k, v in sorted(self.par['profil'].items())},
                'par_scenario': {k: dict(sorted(v.items())) for k, v in sorted(self.par['scenario'].items())},
                'par_verite': {k: dict(sorted(v.items())) for k, v in sorted(self.par['verite'].items())},
                'exemples': self.exemples}


def agreger(chemins):
    parts = _parts(chemins)
    c7 = _Mesure()
    apparie = _Mesure()
    realise = _Mesure()
    retour = _Mesure()
    par_vue = {v: {c: collections.Counter() for c in CATS} for v in VUES}
    initial = collections.Counter()
    douleur = collections.Counter()
    rampe = collections.Counter()
    rampe_scen = collections.defaultdict(collections.Counter)
    rampe_ex = []
    saisons = 0
    sans_vue = 0
    plantages = []
    vus = set()
    graines = set()
    profils = set()
    for p in parts:
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        if not isinstance(d.get('saisons'), dict):
            raise SystemExit('%s : pas une part de campagne (lancer km2.dart avec --partie i/n, n >= 2)' % p)
        for nom, r in d['saisons'].items():
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
            ra = r.get('rampe') or {}
            for k in sorted(ra):
                rampe[k] += ra[k]
                rampe_scen[scen][k] += ra[k]
            if ra.get('principal_retire') and len(rampe_ex) < 40:
                rampe_ex.append({'saison': r['saison'], 'rampe': ra})
            _ajouter(initial, s.get('initial'))
            for vue in VUES:
                for cat in CATS:
                    _ajouter(par_vue[vue][cat], (s.get(vue) or {}).get(cat))
            dl = collections.Counter()
            agg = int(r.get('aggravations') or 0)
            fl = int(r.get('poussees') or 0)
            ha = int((r.get('effort') or {}).get('hausses_trop_fortes') or 0)
            if agg:
                dl['douleur_aggravee'] += agg
            if fl:
                dl['poussee_douleur'] += fl
            if ha:
                dl['hausse_charge_plusieurs_crans'] += ha
            douleur.update(dl)
            k7 = (_somme(s, 'plan_module', ('introduit', 'aggrave'))
                  + _somme(s, 'servi_tests_faits', ('introduit', 'aggrave')))
            c7.ajouter(r, k7 + dl,
                       (s.get('servi_tests_faits_exemples') or []) + (s.get('plan_module_exemples') or []))
            retour.ajouter(r, _somme(s, 'servi_tests_faits', ('retour_ecrit',)), [])
            if 'realise_apparie' in s:
                apparie.ajouter(r, _somme(s, 'realise_apparie', ('introduit', 'aggrave')) + dl,
                                s.get('realise_apparie_exemples') or [])
                realise.ajouter(r, _somme(s, 'realise', ('deja_initial', 'aggrave', 'introduit')) + dl,
                                s.get('realise_exemples') or [])
            else:
                sans_vue += 1
    return {
        'schema': 'kalis_bench/kr1_securite/2',
        'parts': len(parts),
        'saisons': saisons,
        'profils': len(profils),
        'graines': [min(graines), max(graines)] if graines else None,
        'plantages': len(plantages),
        'plantages_exemples': plantages[:10],
        'saisons_sans_vue_realisee': sans_vue,
        'critere_7_cahier': c7.json(),
        'retour_ecrit_publie_a_part': retour.json(),
        'realisee_appariee': apparie.json(),
        'realisee_contre_plan_initial': realise.json(),
        'douleur_et_hausses': dict(douleur),
        'initial_kalis_plan': dict(sorted(initial.items())),
        'vues': {v: {c: dict(sorted(par_vue[v][c].items())) for c in CATS} for v in VUES},
        'rampe_principaux': {'principal_retire': rampe.get('principal_retire', 0),
                             'total': _rampe_ind(rampe),
                             'par_scenario': {k: _rampe_ind(v) for k, v in sorted(rampe_scen.items())},
                             'exemples': rampe_ex},
    }


def _rampe_ind(c):
    """Indicateurs de la rampe sur les principaux (KM4, C17.37 ; mêmes que
    `reference/banc/securite_campagne.py`)."""
    d = dict(sorted((k, (round(v, 6) if isinstance(v, float) else v)) for k, v in c.items()))
    sp = c.get('seances_principal', 0)
    d['part_seances_principal_reduit'] = round(c.get('seances_principal_reduit', 0) / float(sp), 6) if sp else None
    n = c.get('principaux_reduits', 0)
    d['part_servie_moyenne'] = round(c.get('part_servie', 0.0) / float(n), 6) if n else None
    return d


def _table(titre, m):
    L = ['', '### ' + titre, '', '| | Total | Codes |', '| --- | --- | --- |']
    for k, d in m.items():
        L.append('| `%s` | %d | %s |' % (k, sum(d.values()), ', '.join('%s %d' % kv for kv in d.items())))
    return L


def markdown(r):
    L = ['# Sécurité du couple `kalis_plan` × Koach (lot KR1)', '',
         '%d saisons (%d profils, graines %s), %d parts, %d plantées, %d sans vue réalisée.' % (
             r['saisons'], r['profils'], r['graines'], r['parts'], r['plantages'], r['saisons_sans_vue_realisee']),
         '']
    for titre, cle in (('Critère 7 du cahier (introduits ou aggravés par Koach, douleurs, hausses)', 'critere_7_cahier'),
                       ('Saison réalisée appariée (Koach au-delà du plan écrit aux mêmes séances manquées)',
                        'realisee_appariee'),
                       ('« Retour à l\'écrit » (publié à part, C13.10.1)', 'retour_ecrit_publie_a_part'),
                       ('Saison réalisée contre le plan initial (diagnostic)', 'realisee_contre_plan_initial')):
        m = r[cle]
        L += ['## ' + titre, '', '**%d** (%d saisons touchées ; graine 0 : %d) : %s.' % (
            m['total'], m['saisons_touchees'], m['graine_0'],
            ', '.join('`%s` %d' % kv for kv in m['par_code'].items()) or 'aucun')]
        if m['total']:
            L += (_table('Par profil', m['par_profil']) + _table('Par scénario', m['par_scenario'])
                  + _table('Par modèle de vérité', m['par_verite']))
        L.append('')
    rp = r.get('rampe_principaux') or {}
    if rp:
        t = rp['total']
        L += ['## Rampe de volume et principaux (KM4, C17.37)', '',
              '**Principal retiré par la rampe sans douleur : %d** (séances : %d). Séances avec un principal : %d ; '
              'dont un principal réduit par le retour gradué : %d (part %s) ; part moyenne des séries écrites servie '
              'au principal réduit : %s.' % (rp['principal_retire'], t.get('seances_principal_retire', 0),
                                             t.get('seances_principal', 0), t.get('seances_principal_reduit', 0),
                                             t.get('part_seances_principal_reduit'), t.get('part_servie_moyenne')),
              '', '| Scénario | Séances avec principal | Réduit | Part | Part servie | Retirés |',
              '| --- | --- | --- | --- | --- | --- |']
        for k, v in rp['par_scenario'].items():
            L.append('| %s | %d | %d | %s | %s | %d |' % (k, v.get('seances_principal', 0),
                                                          v.get('seances_principal_reduit', 0),
                                                          v.get('part_seances_principal_reduit'),
                                                          v.get('part_servie_moyenne'), v.get('principal_retire', 0)))
        L.append('')
    L += ['## Par vue et catégorie', '', '| Vue | ' + ' | '.join(CATS) + ' |', '| --- |' + ' --- |' * len(CATS)]
    for v in VUES:
        L.append('| %s | %s |' % (v, ' | '.join(
            ', '.join('%s %d' % kv for kv in r['vues'][v][c].items()) or '0' for c in CATS)))
    L += ['', 'Plan initial de `kalis_plan` (constats comptés une fois par saison simulée) : %s.' % (
        r['initial_kalis_plan'] or '0')]
    return '\n'.join(L) + '\n'


def extraire(dossier, chemins):
    os.makedirs(dossier, exist_ok=True)
    n = 0
    for p in _parts(chemins):
        with gzip.open(p, 'rt', encoding='utf-8') as f:
            d = json.load(f)
        for nom, r in d.get('saisons', {}).items():
            x = {'saison': r['saison']}
            if 'plantage' in r or 'calibration' not in r:
                x['plantage'] = r.get('plantage') or 'mesure absente'
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
    print('saisons %d (plantées %d) ; critère 7 : %d ; réalisée appariée : %d ; retour à l\'écrit : %d ; '
          'réalisée contre le plan initial : %d ; principal retiré par la rampe : %d' % (
              r['saisons'], r['plantages'], r['critere_7_cahier']['total'], r['realisee_appariee']['total'],
              r['retour_ecrit_publie_a_part']['total'], r['realisee_contre_plan_initial']['total'],
              r['rampe_principaux']['principal_retire']))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
