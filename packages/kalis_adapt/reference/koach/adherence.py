# -*- coding: utf-8 -*-
"""Koach 1.0 — adhérence et refus (cahier KM § 8, décision D7).

* Modèle probit bayésien de P(acceptation) d'une proposition :
  P = Φ(w·x), w ~ N(m, P) mis à jour à chaque décision par appariement des
  moments de rang 1 (filtrage à densité supposée, même mécanique que
  `interval_moments`) : accepter ⇔ w·x + ε > 0, ε ~ N(0, 1).
* Deux canaux pour un refus : il nourrit SEULEMENT ce modèle ; s'il porte la
  raison « trop lourd » / « trop léger », il devient EN PLUS une mesure
  faible de capacité (`modele.observer_raison`) ; « matériel » et « temps »
  sont rangés comme contraintes de planification ; « autre » ou aucune
  raison : rien d'autre.
* Garde-fou anti-complaisance : l'adhérence agit sur la FORME des
  propositions (taille des paliers, moment), jamais sur les cibles ni la
  difficulté globale. `forme` découpe un trajet départ -> cible dont la
  destination ne dépend jamais du modèle : le dernier palier vaut toujours
  exactement la cible. Aucune fonction de ce module ne renvoie ni ne modifie
  une cible, une charge de travail, un nombre de séries ou une réserve.

Boucles de longueur fixe, opérations élémentaires (portage Dart, parité à
1e-9). Aucun aléa.
"""
import math

from .moteur import Extension
from .numerique import interval_moments, norm_cdf

DEFAUTS_ADHERENCE = {
    'a_priori_poids_sd': 1.5,
    'biais_initial': 1.0,
    'pas_min': 0.5,
    'proba_cible': 0.7,
    'refus_silence_j': 0,
    # Clés nouvelles (absentes de koach_params_v1.json) :
    'paliers_max': 4,               # au plus 4 paliers vers une cible
    'ampleur_echelle': 4.0,         # ampleur (en pas de grille) divisée par 4
    'ampleur_borne': 3.0,           # … et bornée à 3 (12 pas)
    'refus_recents_j': 14,          # fenêtre des refus récents (jours)
    'refus_recents_echelle': 5.0,   # 5 refus récents = caractéristique 1
}

TYPES = ('charge_plus', 'charge_moins', 'volume_plus', 'volume_moins', 'reps_plus',
         'reps_moins', 'echange', 'test', 'allegement')
MOMENTS = ('debut_de_seance', 'entre_series', 'prochaine_seance')
RAISONS_CAPACITE = ('too_heavy', 'too_light')
RAISONS_CONTRAINTE = ('equipment', 'time')

# Caractéristiques : 0 biais ; 1..9 type ; 10 ampleur ; 11 jour de bilan bas ;
# 12 semaine d'allègement ; 13 moment entre deux séries ; 14 moment à la
# prochaine séance (référence : début de séance) ; 15 refus récents.
I_TYPE = 1
I_AMPLEUR = 10
I_BILAN = 11
I_ALLEGEMENT = 12
I_ENTRE = 13
I_PROCHAINE = 14
I_REFUS = 15
DIM = 16
NOMS = ('biais',) + TYPES + ('ampleur', 'bilan_bas', 'semaine_allegement', 'entre_series',
                             'prochaine_seance', 'refus_recents')


def _param(params, cle):
    return ((params or {}).get('adherence') or {}).get(cle, DEFAUTS_ADHERENCE[cle])


class Adherence(Extension):
    def __init__(self, params=None):
        self.appliquer_parametres(params)
        sd = self.poids_sd
        self.m = [0.0] * DIM
        self.m[0] = self.biais_initial
        self.P = [[0.0] * DIM for _ in range(DIM)]
        for i in range(DIM):
            self.P[i][i] = sd * sd
        self.refus_jours = []
        self.contraintes_liste = []
        self.n = 0
        # Calibration en ligne : par tranche de 20 %, [n, Σ p prédite, Σ acceptées].
        self.tranches = [[0, 0.0, 0] for _ in range(5)]

    def appliquer_parametres(self, params):
        self.params = params
        self.poids_sd = float(_param(params, 'a_priori_poids_sd'))
        self.biais_initial = float(_param(params, 'biais_initial'))
        self.pas_min = float(_param(params, 'pas_min'))
        self.proba_cible = float(_param(params, 'proba_cible'))
        self.paliers_max = int(_param(params, 'paliers_max'))
        self.ampleur_echelle = float(_param(params, 'ampleur_echelle'))
        self.ampleur_borne = float(_param(params, 'ampleur_borne'))
        self.refus_recents_j = int(_param(params, 'refus_recents_j'))
        self.refus_recents_echelle = float(_param(params, 'refus_recents_echelle'))

    # ------------------------------------------------------------------
    # Caractéristiques et prédiction
    # ------------------------------------------------------------------
    def refus_recents(self, jour):
        n = 0
        for j in self.refus_jours:
            if jour - j < self.refus_recents_j:
                n += 1
        return n

    def caracteristiques(self, type_, ampleur, contexte=None):
        """Vecteur x (16 flottants). [ampleur] : |changement| en pas de grille
        (ou en fraction, selon le type) ; [contexte] : {bilan_bas,
        semaine_allegement, moment, refus_recents}."""
        if type_ not in TYPES:
            raise ValueError('type de changement inconnu : %r' % (type_,))
        c = contexte or {}
        x = [0.0] * DIM
        x[0] = 1.0
        x[I_TYPE + TYPES.index(type_)] = 1.0
        a = abs(float(ampleur or 0.0)) / self.ampleur_echelle
        x[I_AMPLEUR] = a if a < self.ampleur_borne else self.ampleur_borne
        x[I_BILAN] = 1.0 if c.get('bilan_bas') else 0.0
        x[I_ALLEGEMENT] = 1.0 if c.get('semaine_allegement') else 0.0
        moment = c.get('moment', 'debut_de_seance')
        x[I_ENTRE] = 1.0 if moment == 'entre_series' else 0.0
        x[I_PROCHAINE] = 1.0 if moment == 'prochaine_seance' else 0.0
        r = float(c.get('refus_recents') or 0) / self.refus_recents_echelle
        x[I_REFUS] = r if r < 1.0 else 1.0
        return x

    def _px(self, x):
        px = [0.0] * DIM
        for i in range(DIM):
            s = 0.0
            for j in range(DIM):
                s += self.P[i][j] * x[j]
            px[i] = s
        return px

    def _moments(self, x):
        s = 0.0
        for i in range(DIM):
            s += self.m[i] * x[i]
        px = self._px(x)
        v = 0.0
        for i in range(DIM):
            v += x[i] * px[i]
        if v < 1e-12:
            v = 1e-12
        return s, v, px

    def proba(self, x):
        """Probabilité prédictive Φ(m·x / sqrt(1 + xᵀPx))."""
        s, v, _ = self._moments(x)
        return norm_cdf(s / math.sqrt(1.0 + v))

    # ------------------------------------------------------------------
    # Apprentissage
    # ------------------------------------------------------------------
    def apprendre(self, x, accepte):
        """Mise à jour par appariement des moments de rang 1 ; renvoie la
        probabilité prédite AVANT la mise à jour."""
        s, v, px = self._moments(x)
        p = norm_cdf(s / math.sqrt(1.0 + v))
        if accepte:
            _, s2, v2 = interval_moments(s, v, 1.0, 0.0, math.inf)
        else:
            _, s2, v2 = interval_moments(s, v, 1.0, -math.inf, 0.0)
        a = (s2 - s) / v
        b = (v - v2) / (v * v)
        for i in range(DIM):
            self.m[i] += px[i] * a
        for i in range(DIM):
            for j in range(DIM):
                self.P[i][j] -= px[i] * px[j] * b
        k = int(p * 5.0)
        if k > 4:
            k = 4
        t = self.tranches[k]
        t[0] += 1
        t[1] += p
        t[2] += 1 if accepte else 0
        self.n += 1
        return p

    def decision(self, koach, e):
        """Événement {type: 'decision', jour, proposition: {id, type,
        exerciseId, ampleur, charge_kg, reps, rir, contexte}, accepte,
        raison}. Ne modifie jamais l'événement. Les autres événements
        `decision` du journal (réponse au diagnostic hors modèle, essai du
        contrôle dual) ne portent pas de proposition : ils sont ignorés (sans
        ce filtre, chacun comptait comme un refus)."""
        if e.get('proposition') is None:
            return
        prop = e.get('proposition') or {}
        jour = e.get('jour', 0)
        accepte = bool(e.get('accepte'))
        typ = prop.get('type')
        if typ in TYPES:
            ctx = prop.get('contexte') or {}
            c = {'bilan_bas': ctx.get('bilan_bas'), 'semaine_allegement': ctx.get('semaine_allegement'),
                 'moment': ctx.get('moment', 'debut_de_seance'),
                 'refus_recents': ctx.get('refus_recents', self.refus_recents(jour))}
            self.apprendre(self.caracteristiques(typ, prop.get('ampleur'), c), accepte)
        if accepte:
            return
        self.refus_jours.append(jour)
        # Seuls les refus récents servent : on oublie les plus anciens.
        garde = []
        for j in self.refus_jours:
            if jour - j < self.refus_recents_j:
                garde.append(j)
        self.refus_jours = garde
        raison = e.get('raison')
        if raison in RAISONS_CAPACITE:
            ex = prop.get('exerciseId')
            charge = prop.get('charge_kg')
            reps = prop.get('reps')
            rir = prop.get('rir')
            if ex is not None and charge is not None and reps is not None and rir is not None:
                # Second canal (D7) : mesure faible de capacité, raison explicite.
                koach.modele.observer_raison(ex, raison, float(charge), float(reps), float(rir))
        elif raison in RAISONS_CONTRAINTE:
            self.contraintes_liste.append({'jour': jour, 'raison': raison,
                                           'exerciseId': prop.get('exerciseId'),
                                           'proposition': prop.get('id')})

    def contraintes(self):
        """Contraintes de planification datées (matériel, temps)."""
        return [dict(c) for c in self.contraintes_liste]

    # ------------------------------------------------------------------
    # Forme des propositions (garde-fou anti-complaisance)
    # ------------------------------------------------------------------
    @staticmethod
    def _paliers(depart, cible, n, pas):
        """n paliers de départ vers cible, intermédiaires calés sur la grille
        de pas depuis le départ, dernier = cible exactement."""
        d = cible - depart
        sg = 1.0 if d > 0 else -1.0
        q = abs(d) / (n * pas)
        out = []
        for k in range(1, n):
            out.append(depart + sg * pas * math.floor(k * q + 0.5))
        out.append(cible)
        return out

    def forme(self, cible, depart, pas_min=None, type_='charge_plus', contexte=None):
        """{'paliers': [...], 'moment': ..., 'proba_min': ...} : le plus petit
        nombre de paliers dont chacun a P(acceptation) >= proba_cible, chaque
        pas >= pas_min, au plus paliers_max ; si aucun n'y parvient, le
        découpage de plus forte probabilité minimale. Le dernier palier vaut
        toujours exactement [cible]."""
        pas = float(pas_min) if pas_min is not None else self.pas_min
        c = contexte or {}
        moments = c.get('moments_possibles') or MOMENTS
        d = abs(cible - depart)
        n_max = int(math.floor(d / pas + 1e-9)) if pas > 0 else 1
        if n_max > self.paliers_max:
            n_max = self.paliers_max
        if n_max < 1:
            n_max = 1
        meilleur = None   # (proba_min, n, paliers, moment)
        for n in range(1, n_max + 1):
            if d == 0.0:
                paliers = [cible]
            else:
                paliers = self._paliers(depart, cible, n, pas)
            # Chaque pas doit valoir au moins pas_min (sauf trajet en un pas).
            prec = depart
            valide = True
            pas_l = []
            for v in paliers:
                ecart = abs(v - prec)
                if n > 1 and ecart < pas * (1.0 - 1e-9):
                    valide = False
                pas_l.append(ecart)
                prec = v
            if not valide:
                continue
            choix = None
            for mo in moments:
                cm = {'bilan_bas': c.get('bilan_bas'), 'semaine_allegement': c.get('semaine_allegement'),
                      'moment': mo, 'refus_recents': c.get('refus_recents', 0)}
                pmin = 1.0
                for e in pas_l:
                    p = self.proba(self.caracteristiques(type_, e / pas if pas > 0 else 0.0, cm))
                    if p < pmin:
                        pmin = p
                if choix is None or pmin > choix[0]:
                    choix = (pmin, mo)
            if meilleur is None or choix[0] > meilleur[0]:
                meilleur = (choix[0], n, paliers, choix[1])
            if choix[0] >= self.proba_cible:
                meilleur = (choix[0], n, paliers, choix[1])
                break
            if d == 0.0:
                break
        paliers = list(meilleur[2])
        paliers[-1] = cible
        return {'paliers': paliers, 'moment': meilleur[3], 'proba_min': meilleur[0]}

    # ------------------------------------------------------------------
    # Calibration (banc)
    # ------------------------------------------------------------------
    def calibration(self, decisions=None):
        """Table prédit / observé par tranche de 20 %. [decisions] : liste de
        (p prédite, acceptée) ou de {'p', 'accepte'} ; sans argument, les
        décisions vues par ce modèle (probabilité prédite avant chaque mise
        à jour)."""
        if decisions is None:
            t = [list(x) for x in self.tranches]
        else:
            t = [[0, 0.0, 0] for _ in range(5)]
            for dcs in decisions:
                if isinstance(dcs, dict):
                    p, a = float(dcs['p']), bool(dcs['accepte'])
                else:
                    p, a = float(dcs[0]), bool(dcs[1])
                k = int(p * 5.0)
                if k > 4:
                    k = 4
                if k < 0:
                    k = 0
                t[k][0] += 1
                t[k][1] += p
                t[k][2] += 1 if a else 0
        out = []
        for k in range(5):
            n = t[k][0]
            out.append({'tranche': [0.2 * k, 0.2 * (k + 1)], 'n': n,
                        'predit': t[k][1] / n if n > 0 else None,
                        'observe': t[k][2] / n if n > 0 else None})
        return out

    # ------------------------------------------------------------------
    # Sérialisation
    # ------------------------------------------------------------------
    def etat(self):
        return {
            'version': 1, 'noms': list(NOMS), 'm': list(self.m),
            'P': [list(r) for r in self.P], 'refus_jours': list(self.refus_jours),
            'contraintes': self.contraintes(), 'n': self.n,
            'tranches': [list(x) for x in self.tranches],
        }

    @staticmethod
    def depuis_etat(params, etat):
        a = Adherence(params)
        if int(etat.get('version', 0)) != 1 or len(etat['m']) != DIM:
            raise ValueError("état d'adhérence incompatible")
        a.m = [float(v) for v in etat['m']]
        a.P = [[float(v) for v in r] for r in etat['P']]
        a.refus_jours = list(etat['refus_jours'])
        a.contraintes_liste = [dict(c) for c in etat['contraintes']]
        a.n = int(etat['n'])
        a.tranches = [[int(x[0]), float(x[1]), int(x[2])] for x in etat['tranches']]
        return a
