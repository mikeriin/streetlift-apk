# -*- coding: utf-8 -*-
"""Sécurité du couple `kalis_plan` × Koach sur une campagne Python répartie
(lot KM1c4) : agrège, EN FLUX (une saison à la fois, les 90 600 résultats
d'une campagne de cent graines ne tenant pas en mémoire), les résultats
écrits par `banc.campagne --partie i/n` dans un ou plusieurs dossiers de
travail (`<dossier>/<empreinte>/<cle>__<scenario>__<verite>__<graine>.json`).

    python3 -m banc.securite_campagne --sortie securite.json [--md SECURITE.md] [--liste liste.json]
        [--graines a-b] <dossier de travail…>

Mêmes mesures que `kalis_bench/tool/kr1_securite.py` sur les parts Dart :

* **critère 7 du cahier** : constats du validateur du banc `introduit` ou
  `aggrave` par Koach dans le plan modulé (`plan_module`) et dans la saison
  servie (`servi_tests_faits`), plus les aggravations et poussées de douleur
  de l'athlète simulé et les hausses de charge de plus de 10 % sur plusieurs
  crans (`effort.hausses_trop_fortes`) ; « retour à l'écrit » publié à part
  (DECISIONS_CP.md C13.10.1) ;
* **réalisée appariée** (`realise_apparie`, `introduit` + `aggrave`, plus
  douleurs et hausses) : diagnostic ;
* **réalisée contre le plan initial** (`realise`, toutes catégories) :
  diagnostic ;
* plantages, plan initial de `kalis_plan` (`initial`).

`--liste` écrit la liste COMPLÈTE des saisons en violation du critère 7 (le
rapport n'en garde que 40 exemples). `--graines a-b` restreint aux graines
de a à b (sous-ensembles « saisons racontées » (0) et « critères du cahier »
(0 à 5)).
"""
import argparse
import collections
import json
import os
import sys

CATS = ('deja_initial', 'aggrave', 'introduit', 'retour_ecrit')
VUES = ('plan_module', 'servi', 'servi_tests_faits', 'realise', 'realise_apparie')
EXEMPLES_MAX = 40


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
        self.liste = []

    def ajouter(self, r, c, exemples, garder_liste=False):
        if sum(c.values()) <= 0:
            return
        cle, scen, v, g = r['saison']
        self.total.update(c)
        self.touchees += 1
        if g == 0:
            self.graine0.update(c)
        self.par['profil'][cle].update(c)
        self.par['scenario'][scen].update(c)
        self.par['verite'][v].update(c)
        if len(self.exemples) < EXEMPLES_MAX:
            self.exemples.append({'saison': r['saison'], 'constats': dict(c), 'exemples': exemples[:6]})
        if garder_liste:
            self.liste.append({'saison': r['saison'], 'constats': dict(c), 'exemples': exemples[:6]})

    def json(self):
        return {'total': sum(self.total.values()), 'codes': dict(sorted(self.total.items())),
                'saisons_touchees': self.touchees, 'graine_0': sum(self.graine0.values()),
                'par_profil': {k: dict(sorted(v.items())) for k, v in sorted(self.par['profil'].items())},
                'par_scenario': {k: dict(sorted(v.items())) for k, v in sorted(self.par['scenario'].items())},
                'par_verite': {k: dict(sorted(v.items())) for k, v in sorted(self.par['verite'].items())},
                'exemples': self.exemples}


def fichiers(dossiers, empreintes_multiples=False):
    """Fichiers de saison des dossiers de travail (triés, dédoublonnés par
    nom de saison : le premier trouvé l'emporte, parcours trié). Les
    résultats de parts d'une même campagne sont sous le même sous-dossier
    `<empreinte>` (paramètres, sources et configuration identiques) : plusieurs
    empreintes sont refusées, sauf [empreintes_multiples] (mélange de
    versions assumé)."""
    vus = set()
    out = []
    empreintes = set()
    for d in dossiers:
        for racine, dirs, noms in os.walk(d):
            dirs.sort()
            for f in sorted(noms):
                if not f.endswith('.json') or '__' not in f or f.startswith('mauvais_jour'):
                    continue
                empreintes.add(os.path.basename(racine))
                if f in vus:
                    continue
                vus.add(f)
                out.append(os.path.join(racine, f))
    if len(empreintes) > 1 and not empreintes_multiples:
        raise SystemExit('plusieurs empreintes de campagne (%s) : --empreintes-multiples pour les mélanger'
                         % ', '.join(sorted(empreintes)))
    return sorted(out)


def agreger(dossiers, graines=None, empreintes_multiples=False):
    c7 = _Mesure()
    apparie = _Mesure()
    realise = _Mesure()
    retour = _Mesure()
    ancienne = _Mesure()
    par_vue = {v: {c: collections.Counter() for c in CATS} for v in VUES}
    initial = collections.Counter()
    douleur = collections.Counter()
    rampe = collections.Counter()
    rampe_par_scenario = collections.defaultdict(collections.Counter)
    rampe_exemples = []
    saisons = 0
    plantages = []
    graines_vues = set()
    profils = set()
    duree = 0.0
    for chemin in fichiers(dossiers, empreintes_multiples):
        with open(chemin, encoding='utf-8') as f:
            r = json.load(f)
        if 'saison' not in r:
            continue
        cle, scen, v, g = r['saison']
        if graines is not None and not (graines[0] <= g <= graines[1]):
            continue
        graines_vues.add(g)
        profils.add(cle)
        saisons += 1
        duree += float(r.get('duree_s') or 0.0)
        if 'plantage' in r or 'securite' not in r:
            plantages.append({'saison': r['saison'], 'plantage': r.get('plantage'), 'trace': r.get('trace')})
            continue
        s = r['securite']
        ra = r.get('rampe') or {}
        for k in sorted(ra):
            rampe[k] += ra[k]
            rampe_par_scenario[scen][k] += ra[k]
        if ra.get('principal_retire') and len(rampe_exemples) < EXEMPLES_MAX:
            rampe_exemples.append({'saison': r['saison'], 'rampe': ra})
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
        c7.ajouter(r, k7 + dl, (s.get('servi_tests_faits_exemples') or []) + (s.get('plan_module_exemples') or []),
                   garder_liste=True)
        retour.ajouter(r, _somme(s, 'servi_tests_faits', ('retour_ecrit',)), [])
        # KM5 (C17.40.3) : critère 7 avec l'ancienne définition de
        # « volume_trop_vite » (dépassement de la limite seule), indicateur.
        an = s.get('ancienne_definition') or {}
        ancienne.ajouter(r, _somme(an, 'plan_module', ('introduit', 'aggrave'))
                         + _somme(an, 'servi_tests_faits', ('introduit', 'aggrave')) + dl, [])
        apparie.ajouter(r, _somme(s, 'realise_apparie', ('introduit', 'aggrave')) + dl,
                        s.get('realise_apparie_exemples') or [])
        realise.ajouter(r, _somme(s, 'realise', ('deja_initial', 'aggrave', 'introduit')) + dl,
                        s.get('realise_exemples') or [])
    liste = sorted(c7.liste, key=lambda l: (l['saison'][0], l['saison'][1], l['saison'][2], l['saison'][3]))
    return {
        'schema': 'kalis_adapt/securite_campagne/1',
        'dossiers': [os.path.basename(os.path.abspath(d)) for d in dossiers],
        'saisons': saisons,
        'profils': len(profils),
        'graines': [min(graines_vues), max(graines_vues)] if graines_vues else None,
        'duree_totale_s': round(duree, 1),
        'plantages': len(plantages),
        'plantages_exemples': plantages[:10],
        'critere_7_cahier': c7.json(),
        'retour_ecrit_publie_a_part': retour.json(),
        'critere_7_ancienne_definition': ancienne.json(),
        'realisee_appariee': apparie.json(),
        'realisee_contre_plan_initial': realise.json(),
        'douleur_et_hausses': dict(sorted(douleur.items())),
        'initial_kalis_plan': dict(sorted(initial.items())),
        'vues': {v: {c: dict(sorted(par_vue[v][c].items())) for c in CATS} for v in VUES},
        'rampe_principaux': rampe_json(rampe, rampe_par_scenario, rampe_exemples),
    }, liste


def _rampe_indicateurs(c):
    d = dict(sorted((k, (round(v, 6) if isinstance(v, float) else v)) for k, v in c.items()))
    sp = c.get('seances_principal', 0)
    d['part_seances_principal_reduit'] = round(c.get('seances_principal_reduit', 0) / float(sp), 6) if sp else None
    n = c.get('principaux_reduits', 0)
    d['part_servie_moyenne'] = round(c.get('part_servie', 0.0) / float(n), 6) if n else None
    return d


def rampe_json(c, par_scenario, exemples):
    """Critère KM4 (C17.37) : principaux retirés par la rampe de volume sans
    douleur (0 attendu) ; indicateurs : part des séances dont un principal
    est réduit, part moyenne des séries écrites servie au principal réduit."""
    return {'principal_retire': c.get('principal_retire', 0),
            # KM5 (C17.40) : « série ou item retiré sous l'écrit par la rampe
            # de volume » (0 attendu) ; ajouts de Koach bornés (indicateur).
            'sous_ecrit_items': c.get('sous_ecrit_items', 0), 'sous_ecrit_series': c.get('sous_ecrit_series', 0),
            'ajouts_bornes': c.get('ajouts_bornes', 0), 'ajouts_bornes_series': c.get('ajouts_bornes_series', 0),
            'sans_cause_items': c.get('sans_cause_items', 0), 'sans_cause_series': c.get('sans_cause_series', 0),
            'total': _rampe_indicateurs(c),
            'par_scenario': {k: _rampe_indicateurs(v) for k, v in sorted(par_scenario.items())},
            'exemples': exemples}


def _table(titre, m):
    L = ['', '### ' + titre, '', '| | Total | Codes |', '| --- | --- | --- |']
    for k, d in m.items():
        L.append('| `%s` | %d | %s |' % (k, sum(d.values()), ', '.join('%s %d' % kv for kv in d.items())))
    return L


def markdown(r, titre):
    L = ['# ' + titre, '',
         '%d saisons (%d profils, graines %s), %d plantée(s), %.0f s de calcul cumulé.' % (
             r['saisons'], r['profils'], r['graines'], r['plantages'], r['duree_totale_s']),
         '']
    for t, cle in (('Critère 7 du cahier (introduits ou aggravés par Koach, douleurs, hausses)', 'critere_7_cahier'),
                   ('Saison réalisée appariée (Koach au-delà du plan écrit aux mêmes séances manquées)',
                    'realisee_appariee'),
                   ('« Retour à l\'écrit » (publié à part, C13.10.1)', 'retour_ecrit_publie_a_part'),
                   ('Critère 7 avec l\'ancienne définition de « volume_trop_vite » (indicateur, KM5)',
                    'critere_7_ancienne_definition'),
                   ('Saison réalisée contre le plan initial (diagnostic)', 'realisee_contre_plan_initial')):
        m = r[cle]
        L += ['## ' + t, '', '**%d** (%d saisons touchées ; graine 0 : %d) : %s.' % (
            m['total'], m['saisons_touchees'], m['graine_0'],
            ', '.join('%s %d' % kv for kv in m['codes'].items()) or 'aucun')]
        if m['total']:
            L += _table('Par profil', m['par_profil']) + _table('Par scénario', m['par_scenario']) + \
                _table('Par modèle de vérité', m['par_verite'])
        L.append('')
    rp = r.get('rampe_principaux') or {}
    if rp:
        t = rp['total']
        L += ['## Rampe de volume sous l\'écrit (KM5, C17.40)', '',
              '**Série ou item retiré sous l\'écrit par la rampe de volume : %d item(s), %d série(s)**. Ajouts de '
              'Koach bornés : %d (%d séries). Mesure indépendante, ligne servie sous l\'écrit sans cause dite ni '
              'visible : %d item(s), %d série(s).' % (rp.get('sous_ecrit_items', 0), rp.get('sous_ecrit_series', 0),
                                                  rp.get('ajouts_bornes', 0), rp.get('ajouts_bornes_series', 0),
                                                  rp.get('sans_cause_items', 0), rp.get('sans_cause_series', 0)),
              '']
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
    L += ['## Plan initial de `kalis_plan`', '', '%s.' % (
        ', '.join('%s %d' % kv for kv in r['initial_kalis_plan'].items()) or '0 constat'), '']
    if r['plantages']:
        L += ['## Plantages', ''] + ['- `%s` : %s' % (p['saison'], p['plantage']) for p in r['plantages_exemples']]
    return '\n'.join(L) + '\n'


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('dossiers', nargs='+')
    ap.add_argument('--sortie', required=True)
    ap.add_argument('--md')
    ap.add_argument('--liste')
    ap.add_argument('--graines', help='a-b : graines gardées')
    ap.add_argument('--titre', default='Sécurité du couple `kalis_plan` × Koach (campagne Python)')
    ap.add_argument('--empreintes-multiples', action='store_true')
    a = ap.parse_args(argv)
    graines = None
    if a.graines:
        x, y = a.graines.split('-')
        graines = (int(x), int(y))
    r, liste = agreger(a.dossiers, graines, a.empreintes_multiples)
    with open(a.sortie, 'w', encoding='utf-8') as f:
        json.dump(r, f, ensure_ascii=False, indent=1, sort_keys=True)
    if a.md:
        with open(a.md, 'w', encoding='utf-8') as f:
            f.write(markdown(r, a.titre))
    if a.liste:
        with open(a.liste, 'w', encoding='utf-8') as f:
            json.dump({'saisons': r['saisons'], 'violations': r['critere_7_cahier']['total'],
                       'saisons_touchees': len(liste), 'liste': liste}, f, ensure_ascii=False, indent=1,
                      sort_keys=True)
    print('%d saisons, %d plantée(s) ; critère 7 : %d (%d saisons) ; réalisée appariée : %d ; retour à l\'écrit : %d'
          ' ; principal retiré par la rampe : %d ; sous l\'écrit par la rampe : %d ; ancienne définition : %d (%d saisons)'
          % (r['saisons'], r['plantages'], r['critere_7_cahier']['total'], r['critere_7_cahier']['saisons_touchees'],
             r['realisee_appariee']['total'], r['retour_ecrit_publie_a_part']['total'],
             r['rampe_principaux']['principal_retire'], r['rampe_principaux']['sous_ecrit_items'],
             r['critere_7_ancienne_definition']['total'], r['critere_7_ancienne_definition']['saisons_touchees']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
