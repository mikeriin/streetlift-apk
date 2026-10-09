# -*- coding: utf-8 -*-
"""Koach 1.0 — façade du moteur (CONTRAT_1_0.md § 3) :

    observe(evenement)   verse un événement du journal ;
    posterior()          l'a posteriori lisible (capacités, intervalles, biais) ;
    plan(contraintes)    la séance, la série suivante ou la semaine ;
    explain()            les raisons des dernières décisions.

L'état est entièrement recalculable depuis le journal (`rejouer`).
"""
import math

from .modele import Modele, NQ, TH, RHO, EPS, KN, KM, BA, LAM, KU, FI, HH
from .securite import Gardefous
from .seance import Seances


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
            'fatigue_sensibilite': [m.m[KN], m.m[KM]],
            'fatigue': {'nerveux': m.f_nerveux, 'musculaire': list(m.f_musculaire),
                        'tendineux': dict(m.f_tendon), 'tau': list(m.tau)},
            'biais_rir': m.m[BA], 'bruit_rir': m.bruit_rir,
            'courbe': [m.m[LAM], m.m[KU]], 'fatigue_intra': m.m[FI], 'part_tenue': m.m[HH],
            'note_paresseuse': m.paresse[0] / (m.paresse[0] + m.paresse[1]),
            'hypotheses_reponse': list(m.poids_hyp),
            'exercices': exercices,
        }

    # ------------------------------------------------------------------
    def plan(self, c):
        """[c] : contraintes. `horizon` = 'seance' (items écrits du jour ->
        items servis), 'serie' (item, index -> cible) ou 'semaine'
        (replanification, par l'extension de planification)."""
        h = c.get('horizon')
        if h == 'seance':
            items = self.seances.prescrire(c['items'], c.get('grilles') or {}, c.get('zones') or {},
                                           c.get('roles') or {})
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
