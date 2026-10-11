# -*- coding: utf-8 -*-
"""Branchement de la planification de Koach (`koach/planification.py`) sur le
banc Python : plan de référence = blocs de `kalis_plan` de la saison,
validateur = critères de sécurité du banc (`securite_banc`), cibles = buts du
profil, échéance = jour d'épreuve de la saison."""
from koach.planification import Planification
from . import donnees, securite_banc


def cibles_du_profil(profil, fiches):
    """Buts de performance du profil -> {exercice: valeur visée} ; pour un
    exercice chargé, la charge TOTALE (charge visée + part du poids de corps)."""
    out = {}
    bw = profil.get('bodyWeightKg') or 72.0
    for g in profil.get('goals') or []:
        ex = g.get('exerciseId')
        v = g.get('targetValue')
        fiche = fiches.get(ex)
        if ex is None or v is None or fiche is None:
            continue
        metrique = g.get('metric')
        if metrique == 'one_rm_kg' and fiche['type'] == 'charge':
            out[ex] = v + fiche.get('fraction', 0.0) * bw
        elif metrique == 'max_reps' and fiche['type'] == 'reps':
            out[ex] = float(v)
        elif metrique == 'max_hold_seconds' and fiche['type'] == 'tenue':
            out[ex] = float(v)
    return out


def principaux_de(saison):
    out = []
    for b in saison['blocks']:
        for d in b['pass1']['days']:
            for s in d['slots']:
                if s.get('role') == 'main' and s['exerciseId'] not in out:
                    out.append(s['exerciseId'])
    return out


def echeance_de(saison, semaine, jour=0):
    """Prochain jour d'épreuve connu à la semaine [semaine] (None sinon)."""
    if semaine >= len(saison['eventDaysByWeek']):
        return None
    futurs = [d for d in saison['eventDaysByWeek'][semaine] if d >= jour]
    return min(futurs) if futurs else None


class PlanificationBanc(Planification):
    """Planification conduite par le banc : l'échéance connue et les buts du
    profil sont relus avant chaque replanification."""

    def __init__(self, politique, options=None, avec_validateur=True):
        saison = politique.saison
        infos = donnees.catalogue_infos()
        validateur = None
        if avec_validateur:
            validateur = lambda blocs: securite_banc.constats_saison(saison, infos, blocs=blocs)
        Planification.__init__(self, politique.parametres, politique.koach.fiches, validateur, options)
        self.saison = saison
        self.profil = saison['profiles'][0]['profile']
        self.previsions = []
        self.charger_reference(saison['blocks'], saison.get('blockWeeks'), saison['weeks'],
                               cibles=cibles_du_profil(self.profil, self.fiches),
                               echeance_jour=echeance_de(saison, 0),
                               principaux=principaux_de(saison),
                               poids_corps=self.profil.get('bodyWeightKg'))
        self.replanifier(politique.koach, 0)
        self._noter(0)

    def _noter(self, semaine):
        ligne = self.historique[-1] if self.historique else None
        if ligne and ligne.get('p_cibles'):
            self.previsions.append({'semaine': semaine, 'echeance': self.echeance_jour,
                                    'p': dict(ligne['p_cibles']), 'p_tout': ligne.get('objectif')})

    def changement_profil(self, koach, semaine, profil):
        self.profil = profil
        self.cibles = cibles_du_profil(profil, self.fiches)
        for e in self.cibles:
            if e not in self.suivis and e in self.fiches:
                self.suivis.append(e)
                self._tables = {}

    def fin_semaine(self, koach, ligne, e):
        w = int(e.get('semaine', 0)) + 1
        self.echeance_jour = echeance_de(self.saison, w, 7 * w)
        Planification.fin_semaine(self, koach, ligne, e)
        self._noter(w)

    def items_du_jour(self, koach, ctx, items):
        return self.appliquer(ctx.semaine, ctx.jour_index, items)


def fabrique(options=None, avec_validateur=True):
    return lambda politique: PlanificationBanc(politique, options, avec_validateur)
