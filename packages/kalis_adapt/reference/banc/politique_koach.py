# -*- coding: utf-8 -*-
"""Politique du banc Python qui fait conduire la saison par Koach 1.0 :
adaptateur entre le meneur (blocs et séries au format du contrat de
kalis_core) et la façade du moteur (`observe`, `posterior`, `plan`)."""
import copy
import json
import math
import os

from koach.moteur import Koach
from koach.seance import Grille
from . import donnees
from .meneur import Politique, cible_de
from .verite_endurance import prescribed_seconds, QUALITY_RUN_IDS

ICI = os.path.dirname(os.path.abspath(__file__))
_params = None
_vecteurs = None


def params():
    global _params
    if _params is None:
        with open(os.path.join(ICI, '..', 'params', 'koach_params_v1.json'), encoding='utf-8') as f:
            _params = json.load(f)
    return _params


def vecteurs():
    global _vecteurs
    if _vecteurs is None:
        with open(os.path.join(ICI, '..', 'qualites', 'vecteurs_qualites_v1.json'), encoding='utf-8') as f:
            _vecteurs = json.load(f)['exercices']
    return _vecteurs


def profil_koach(saison, profil):
    declares = {}
    for lv in profil.get('movementLevels') or []:
        if lv.get('known') and lv.get('low') and lv.get('high'):
            declares[lv['exerciseId']] = (lv['measure'], math.sqrt(lv['low'] * lv['high']))
    fragiles = []
    for lim in profil.get('limitations') or []:
        z = lim.get('zone')
        if z:
            fragiles.append(z)
    return {'niveau': saison['level'], 'sexe': profil.get('sex'), 'poids_kg': profil.get('bodyWeightKg'),
            'declares': declares, 'zones_fragiles': fragiles}


class PolitiqueKoach(Politique):
    nom = 'koach_1_0'

    def __init__(self, parametres=None, extensions=None, options=None):
        self.parametres = parametres or params()
        self.fabriques = extensions or []
        self.options = options or {}

    def debut(self, saison, profil, livre):
        self.saison = saison
        self.livre = livre
        fiches = vecteurs()
        self.koach = Koach(self.parametres, fiches, profil_koach(saison, profil))
        for f in self.fabriques:
            self.koach.extensions.append(f(self))
        self.grilles = {}
        self.zones = {}
        for ex_id, info in livre.items():
            self.grilles[ex_id] = Grille(info.grid.step, info.grid.minimum, info.grid.dumbbell)
            self.zones[ex_id] = (info.zone_levels, info.pain_stop_hits)
        self.vus = 0
        self.ctx = None
        self.plan = None       # plan de Koach : blocs modifiés (copie paresseuse)
        self.cibles = {}
        for g in profil.get('goals') or []:
            if g.get('metric') == 'one_rm_kg' and g.get('targetValue'):
                self.cibles[g['exerciseId']] = g['targetValue']
        self.courses = []

    def changement_profil(self, semaine, profil):
        self.cibles = {}
        for g in profil.get('goals') or []:
            if g.get('metric') == 'one_rm_kg' and g.get('targetValue'):
                self.cibles[g['exerciseId']] = g['targetValue']
        for x in self.koach.extensions:
            if hasattr(x, 'changement_profil'):
                x.changement_profil(self.koach, semaine, profil)

    def seance_manquee(self, semaine, sim_day):
        self.koach.observe({'type': 'seance_manquee', 'jour': sim_day, 'semaine': semaine})

    def items_du_jour(self, ctx):
        """Items du plan de Koach pour le jour (les extensions de
        planification modifient l'écrit dans les plafonds)."""
        items = ctx.ecrit['items']
        for x in self.koach.extensions:
            if hasattr(x, 'items_du_jour'):
                items = x.items_du_jour(self.koach, ctx, items)
        return items

    def planifier(self, ctx):
        self.ctx = ctx
        self.vus = 0
        contexte = {'genre': ctx.genre_semaine, 'intention': ctx.intention,
                    'jour_evenement': ctx.jour_evenement, 'budget': ctx.budget, 'lieu': ctx.lieu,
                    'semaine': ctx.semaine}
        self.koach.observe({'type': 'seance_debut', 'jour': ctx.sim_day, 'bilan': ctx.bilan,
                            'poids_kg': None, 'contexte': contexte})
        items = []
        for it in self.items_du_jour(ctx):
            if it['exerciseId'] in self.cibles and it.get('kind') == 'test':
                it = dict(it)
                it['koachCible'] = self.cibles[it['exerciseId']]
            items.append(it)
        roles = {}
        for d in ctx.bloc['pass1']['days']:
            for s in d['slots']:
                roles[s['slotId']] = s.get('role')
        r = self.koach.plan({'horizon': 'seance', 'items': items, 'grilles': self.grilles,
                             'zones': self.zones, 'roles': roles})
        return {'items': r['items']}

    def _verser(self, done):
        while self.vus < len(done):
            rec = done[self.vus]
            self.vus += 1
            s = self._serie(rec)
            if s is not None:
                self.koach.observe({'type': 'serie', 'serie': s})

    def _serie(self, rec):
        if rec.get('nonModelise'):
            return None
        s = {k: rec.get(k) for k in ('exerciseId', 'slotId', 'setIndex', 'kind', 'reps', 'seconds',
                                     'flames', 'failed', 'target', 'restSeconds', 'technique', 'role', 'repere')}
        charge = rec.get('externalLoadKg')
        s['externalLoadKg'] = charge if (charge is not None and charge >= 0) else None
        ek = rec.get('enduranceKind')
        if ek is not None:
            item = rec['item']
            sets = max(1, item.get('sets', 1))
            if rec['setIndex'] != 0:
                return None
            if ek == 'run':
                vitesse = 2.6
                ecrit = prescribed_seconds(item, sets, vitesse)
                f0 = item.get('targetFlames')
                qualite = ((f0 is not None and (0.0 if f0 >= 10 else (11 - f0) / 2.0) <= 3 + 1e-9)
                           or item.get('intensity') is not None
                           or any(q in item['exerciseId'] for q in QUALITY_RUN_IDS))
                poids = self.parametres['mesure']['cardio_poids_qualite'] if qualite else 1.0
                fait = (rec.get('seconds') or 0) * sets
                s['demand'] = ecrit * poids / 60.0
                s['doneShare'] = 1.0 if rec.get('success') else (fait / ecrit if ecrit > 0 else 1.0)
                s['dose'] = fait * (1.5 if qualite else 1.0) / 3600.0
                s['fatigueSets'] = min(6.0, fait / 600.0)
                s['target'] = {'flames': f0}
            else:
                s['demand'] = rec.get('writtenShare', 1.0)
                s['doneShare'] = 1.0 if rec.get('success') else 0.9
                s['dose'] = 1.0
                s['fatigueSets'] = float(sets)
                s['target'] = {'flames': item.get('targetFlames')}
        return s

    def prochaine_serie(self, ctx, item, index, done):
        self._verser(done)
        return self.koach.plan({'horizon': 'serie', 'item': item, 'index': index})

    def cran_change(self, ex_id, change):
        self.koach.observe({'type': 'cran', 'exerciseId': ex_id, 'facteur': 0.75 if change < 0 else 1 / 0.75})

    def terminer(self, ctx, record):
        self._verser(record['sets'])
        self.koach.observe({'type': 'seance_fin', 'jour': ctx.sim_day, 'douleurs': record.get('pains'),
                            'seance': record})

    def estimer(self, ex_id, n):
        m = self.koach.modele
        t = m.piste(ex_id)
        if t is None or t.type not in ('charge', 'reps', 'tenue'):
            return None
        mu, sd = m.capacite(ex_id)
        if t.type == 'reps' and t.fraction > 0:
            masse = math.log(t.fraction * m.poids_kg)
            v = m.reps_a(t, mu - masse)
            lo = m.reps_a(t, mu - 1.6448536269514722 * sd - masse)
            hi = m.reps_a(t, mu + 1.6448536269514722 * sd - masse)
            rel = (hi - lo) / (2 * 1.6448536269514722 * v) if v > 0 else sd
            return (v, rel, v, lo, hi)
        cap = math.exp(mu)
        if t.type == 'charge':
            lam, k = m.courbe(t)
            op = math.exp(mu - m._g(lam, k, n))
        else:
            op = cap
        return (cap, sd, op, math.exp(mu - 1.6448536269514722 * sd), math.exp(mu + 1.6448536269514722 * sd))

    def fin_semaine(self, semaine, tour):
        self.koach.observe({'type': 'semaine_fin', 'jour': 7 * (semaine + 1), 'semaine': semaine})
        for x in self.koach.extensions:
            if hasattr(x, 'apres_semaine'):
                x.apres_semaine(self.koach, semaine, tour, self)
