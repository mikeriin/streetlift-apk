# -*- coding: utf-8 -*-
"""Koach 1.0 — façade du moteur (CONTRAT_1_0.md § 3) :

    observe(evenement)   verse un événement du journal ;
    posterior()          l'a posteriori lisible (capacités, intervalles, biais) ;
    plan(contraintes)    la séance, la série suivante ou la semaine ;
    explain()            les raisons des dernières décisions.

L'état est entièrement recalculable depuis le journal (`rejouer`).
"""
import copy
import math

from .modele import Modele, NQ, TH, RHO, EPS, KN, KM, KL, KG, BA, BP, LAM, KU, FI, HH
from .securite import Gardefous
from .seance import Seances, Grille


class Koach(object):
    def __init__(self, params, fiches, profil):
        """[fiches] : id -> fiche (vecteur de qualités, type, tendon, zones) ;
        [profil] : {niveau, sexe, poids_kg, declares, zones_fragiles}."""
        self.params = params
        self.fiches = fiches
        self.profil = profil
        self.modele = Modele(params, fiches, profil)
        self.garde = Gardefous(params, self.modele.niveau, profil.get('zones_fragiles'))
        self.seances = Seances(params, self.modele, self.garde, fiches)
        self.journal = []
        self.raisons = []
        self.jour = 0
        self.extensions = []   # modules branchés (planification, adhérence, rupture, dual)

    # ------------------------------------------------------------------
    def observe(self, e):
        """Verse un événement : dictionnaire avec `type` parmi seance_debut,
        serie, seance_fin, seance_manquee, semaine_fin, decision, cran,
        poids, profil."""
        self.journal.append(e)
        typ = e['type']
        m = self.modele
        if typ == 'seance_debut':
            self.jour = e['jour']
            self.garde.avancer(self.jour)
            bilan = e.get('bilan')
            if bilan is not None and bilan.get('pains') is not None:
                self.garde.noter_seance(self.jour, bilan.get('pains'), posee=True)
            m.debut_seance(self.jour, bilan, e.get('poids_kg'))
            self.seances.ouvrir(self.jour, bilan, e.get('contexte') or {})
        elif typ == 'serie':
            m.observer_serie(e['serie'])
            self.seances.serie_faite(e['serie'])
        elif typ == 'seance_fin':
            douleurs = e.get('douleurs')
            if douleurs:
                self.garde.noter_seance(self.jour, douleurs, posee=False)
            self.seances.fermer(e.get('seance') or {})
            resume = m.fin_seance()
            for x in self.extensions:
                x.fin_seance(self, resume, e)
        elif typ == 'seance_manquee':
            for x in self.extensions:
                x.seance_manquee(self, e)
        elif typ == 'semaine_fin':
            m.avancer(e['jour'])
            ligne = m.fin_semaine()
            for x in self.extensions:
                x.fin_semaine(self, ligne, e)
        elif typ == 'cran':
            m.changer_cran(e['exerciseId'], e['facteur'])
        elif typ == 'poids':
            m.poids_kg = float(e['poids_kg'])
        elif typ == 'decision':
            for x in self.extensions:
                x.decision(self, e)
        elif typ == 'charge_manuelle':
            m.observer_charge_manuelle(e['exerciseId'], e['loadKg'], e['reps'], e['rir'])
        elif typ == 'plan':
            # Appel de plan() rejoué : il a des effets sur la mémoire des
            # séances (rampes, paliers, raisons) ; le rejouer rend l'état
            # exactement recalculable depuis le journal.
            self._plan(e['contraintes'])
        return None

    # ------------------------------------------------------------------
    def posterior(self):
        m = self.modele
        exercices = {}
        for ex_id in m.ordre:
            t = m.pistes[ex_id]
            mu, sd = m.capacite(ex_id)
            exercices[ex_id] = {
                'type': t.type, 'ln_capacite': mu, 'ecart_type': sd,
                'valeur': m.valeur(ex_id), 'intervalle_90': list(m.intervalle(ex_id)),
                'seances': t.seances, 'mesures': t.mesures,
            }
        return {
            'jour': m.jour,
            'qualites': [m.m[TH + q] for q in range(NQ)],
            'qualites_sd': [math.sqrt(max(m.P[TH + q, TH + q], 0.0)) for q in range(NQ)],
            'reponse': m.m[RHO], 'reponse_sd': math.sqrt(max(m.P[RHO, RHO], 0.0)),
            'reponse_classes': [m.m[EPS + c] for c in range(5)],
            'fatigue_sensibilite': {'nerveux_systemique': float(m.m[KN]), 'nerveux_local': float(m.m[KL]),
                                    'musculaire_systemique': float(m.m[KG]), 'musculaire_local': float(m.m[KM])},
            'fatigue': {'nerveux': {'systemique': float(m.f_g[0]), 'local': [float(x) for x in m.f_l[0]]},
                        'musculaire': {'systemique': float(m.f_g[1]), 'local': [float(x) for x in m.f_l[1]]},
                        'tendineux': dict(m.f_tendon), 'tau': list(m.tau)},
            'biais_rir': [m.m[BA], m.m[BP]], 'bruit_rir': m.bruit_rir,
            'courbe': [m.m[LAM], m.m[KU]], 'fatigue_intra': m.m[FI], 'part_tenue': m.m[HH],
            'note_paresseuse': m.paresse[0] / (m.paresse[0] + m.paresse[1]),
            'hypotheses_reponse': list(m.poids_hyp),
            'exercices': exercices,
        }

    # ------------------------------------------------------------------
    def plan(self, c):
        """[c] : contraintes. `horizon` = 'seance' (items écrits du jour ->
        items servis), 'serie' (item, index -> cible) ou 'semaine'
        (replanification, par l'extension de planification). L'appel est
        versé au journal (événement `plan`) : `rejouer` le refait."""
        c = self._canonique(c)
        self.journal.append({'type': 'plan', 'contraintes': c})
        return self._plan(c)

    @staticmethod
    def _canonique(c):
        """Forme journalisable (JSON) des contraintes : pour une séance,
        seules les grilles et les zones des exercices des items sont
        gardées (ce sont les seules lues), grilles en dictionnaires
        {pas, minimum, halteres}, zones en [niveaux, zones provoquées triées]."""
        c = dict(c)
        if c.get('horizon') == 'seance':
            ids = []
            for it in c.get('items') or []:
                if it['exerciseId'] not in ids:
                    ids.append(it['exerciseId'])
            grilles = {}
            zones = {}
            for ex in ids:
                g = (c.get('grilles') or {}).get(ex)
                if g is not None:
                    if isinstance(g, Grille):
                        g = {'pas': g.pas, 'minimum': g.minimum, 'halteres': bool(g.halteres)}
                    grilles[ex] = dict(g)
                z = (c.get('zones') or {}).get(ex)
                if z is not None:
                    zones[ex] = [dict(z[0]), sorted(z[1])]
            slots = [it.get('slotId') for it in c.get('items') or []]
            roles = {k: v for k, v in (c.get('roles') or {}).items() if k in slots}
            c['grilles'] = grilles
            c['zones'] = zones
            c['roles'] = roles
        return copy.deepcopy(c)

    def _plan(self, c):
        h = c.get('horizon')
        if h == 'seance':
            grilles = {k: Grille(g['pas'], g['minimum'], g['halteres']) for k, g in (c.get('grilles') or {}).items()}
            zones = {k: (dict(z[0]), set(z[1])) for k, z in (c.get('zones') or {}).items()}
            items = self.seances.prescrire(c['items'], grilles, zones, c.get('roles') or {})
            self.raisons = list(self.seances.raisons)
            return {'items': items, 'raisons': self.raisons}
        if h == 'serie':
            cible = self.seances.cible(c['item'], c['index'], c.get('faites') or [])
            self.raisons = list(self.seances.raisons)
            return cible
        if h == 'semaine':
            out = None
            for x in self.extensions:
                r = x.plan_semaine(self, c)
                if r is not None:
                    out = r
            return out
        raise ValueError('horizon inconnu : %r' % (h,))

    def explain(self):
        return list(self.raisons)


class Extension(object):
    """Module branché sur le moteur (planification, adhérence, rupture…)."""

    def fin_seance(self, koach, resume, e):
        pass

    def seance_manquee(self, koach, e):
        pass

    def fin_semaine(self, koach, ligne, e):
        pass

    def decision(self, koach, e):
        pass

    def plan_semaine(self, koach, c):
        return None


def rejouer(params, fiches, profil, journal, extensions=None):
    """Recalcule l'état depuis le journal (déterminisme : même journal et
    mêmes décisions = même état)."""
    k = Koach(params, fiches, profil)
    for f in extensions or []:
        k.extensions.append(f())
    for e in journal:
        k.observe(e)
    return k
