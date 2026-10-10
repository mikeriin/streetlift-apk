# -*- coding: utf-8 -*-
"""Estimation de Koach 1.0 (CONTRAT_1_0.md § 4 à 6) : modèle de réponse à
l'item multidimensionnel sur dix qualités latentes, mesure du RIR (biais et
bruit appris), e1RM sur la masse totale, fatigue en trois compartiments,
a priori hiérarchique population → utilisateur → qualités → exercices.

État gaussien x ~ N(m, P). Chaque série devient une observation d'une
combinaison linéaire u = h·x + c : une catégorie ordonnée (intervalle [a, b],
modèle gradué de Samejima en ogive normale), un temps censuré ou observé
(survie), une valeur continue (log-normale) ou une réussite binaire (2PL en
ogive normale). La mise à jour est un appariement de moments de rang 1
(`numerique.interval_moments`), exact pour une vraisemblance qui ne dépend de
x que par u. Deux branches par séance (jour normal, mauvais jour) sont
fusionnées en fin de séance : un mauvais jour isolé ne déplace pas la
capacité.

Tout l'état se recalcule depuis le journal (déterminisme, cahier).
"""
import math

import numpy as np

from .numerique import interval_moments, point_moments, category_moments, clamp, norm_ppf

INF = math.inf
NQ = 10
NGR = 17        # groupes musculaires (fatigue locale)
# Indices des composantes globales de l'état.
TH = 0          # 0..9  : qualités (écart de l'utilisateur à l'a priori)
RHO = 10        # réponse à l'entraînement (ln capacité par semaine à dose de référence)
EPS = 11        # 11..15 : écart de réponse par classe (charge, reps, tenue, cardio, wod)
KN = 16         # sensibilité au compartiment nerveux (rapide), part systémique
KM = 17         # sensibilité au compartiment musculaire (lent), part locale
BA = 18         # biais personnel du RIR (répétitions, additif)
BP = 19         # biais du RIR proportionnel à la réserve (sous-estimation loin de l'échec)
LAM = 20        # forme de la courbe répétitions-charge (0 linéaire, 1 logarithmique)
KU = 21         # échelle de la courbe de l'utilisateur (ln)
FI = 22         # fatigue intra-séance (part des répétitions perdue)
HH = 23         # part du maintien maximal par répétition en réserve
DS = 24         # effet de jour de la séance
DE = 25         # effet de jour de l'exercice en cours
KL = 26         # sensibilité au compartiment rapide, part locale (qualités sollicitées)
KG = 27         # sensibilité au compartiment lent, part systémique
NG = 28
C_LIN = 0.0265  # pente de la courbe log-linéaire (forme 0) : -ln(part du 1RM) par répétition
C_LOG = 0.0892  # courbe logarithmique (forme 1), égale à la log-linéaire à 8 répétitions
G8 = C_LIN * 7.0            # -ln(part du 1RM) à 8 répétitions, échelle e^0, toutes formes
LN8 = math.log(8.0)
LAM_MIN = -0.8              # forme la plus convexe admise (au-delà de Brzycki, -0,30)
LAM_MAX = 1.3               # forme la plus concave admise (au-delà de Lombardi, 1)


def _phi(x):
    """(e^x - 1) / x, série près de 0 (portable : ni expm1 ni log1p)."""
    if -1e-2 < x < 1e-2:
        return 1.0 + x * (0.5 + x * (1.0 / 6.0 + x * (1.0 / 24.0 + x * (1.0 / 120.0 + x * (
            1.0 / 720.0 + x / 5040.0)))))
    return (math.exp(x) - 1.0) / x


def _phi1(x):
    """Dérivée de `_phi` : (e^x (x - 1) + 1) / x², série près de 0."""
    if -1e-2 < x < 1e-2:
        return 0.5 + x * (1.0 / 3.0 + x * (0.125 + x * (1.0 / 30.0 + x * (1.0 / 144.0 + x * (
            1.0 / 840.0 + x / 5760.0)))))
    return (math.exp(x) * (x - 1.0) + 1.0) / (x * x)
CLASSES = ['charge', 'reps', 'tenue', 'cardio', 'wod']
ZONES_TENDON = ['epaule', 'coude', 'poignet', 'lombaires', 'genou', 'hanche', 'cheville']


class Piste(object):
    """Suivi d'un exercice (item) : métadonnées hors de l'état gaussien."""

    __slots__ = ('id', 'type', 'classe', 'vecteur', 'base', 'idx', 'fraction', 'bas',
                 'tendon', 'zone_tendon', 'systemique', 'locale', 'seances', 'dernier_jour',
                 'premier_jour', 'stim_semaine', 'series_seance', 'jour_seance', 'declare',
                 'dernier_test_jour', 'residus', 'cran', 'meilleur', 'mesures', 'groupes', 'groupes_total',
                 'jour_prevu', 'jour_vu')

    def __init__(self, ex_id, typ, vecteur, base, idx, fraction=0.0, bas=False,
                 tendon=0.0, zone_tendon=None, systemique=1.0, locale=1.0, declare=False,
                 groupes=None):
        self.id = ex_id
        self.type = typ            # 'charge', 'reps', 'tenue', 'cardio', 'wod', 'mobilite'
        self.classe = CLASSES.index(typ) if typ in CLASSES else None
        self.vecteur = vecteur     # 10 charges sur les qualités (somme 1)
        self.base = base           # a priori de population de ln capacité
        self.idx = idx             # delta_e ; idx + 1 : échelle de courbe (ou part de tenue) ; idx + 2 : fatigue de séance
        self.fraction = fraction
        self.bas = bas
        self.tendon = tendon
        self.zone_tendon = zone_tendon
        self.systemique = systemique
        self.locale = locale
        self.seances = 0
        self.dernier_jour = None
        self.premier_jour = None
        self.stim_semaine = [0.0, 0.0, 0.0]   # volume, effort, intensité
        self.series_seance = []    # (effort, repos) des séries de la séance en cours
        self.jour_seance = None
        self.declare = declare
        self.dernier_test_jour = None
        self.residus = []
        self.cran = None
        self.meilleur = None
        self.mesures = 0
        self.groupes = [(int(g), float(w)) for g, w in (groupes or [])]
        self.groupes_total = sum(w for _, w in self.groupes)
        self.jour_prevu = None     # ln capacité du jour prévue avant la première série de la séance
        self.jour_vu = None        # ln capacité du jour après la dernière série de la séance


class Modele(object):
    """Filtre de Koach : état, journal des compartiments, pistes."""

    def __init__(self, params, vecteurs, profil):
        """[params] : fichier de paramètres ; [vecteurs] : id -> fiche de
        qualités (vecteur, type, charge tendineuse…) ; [profil] : dictionnaire
        {niveau 0..3, sexe, poids_kg, declares {id: (mesure, valeur)}}."""
        self.p = params
        self.vecteurs = vecteurs
        self.profil = profil
        self.niveau = int(clamp(profil.get('niveau', 1), 0, 3))
        ap = params['a_priori']
        n = NG + 3 * 48
        self.m = np.zeros(n)
        self.P = np.zeros((n, n))
        self.n = NG
        for q in range(NQ):
            self.P[TH + q, TH + q] = ap['theta_sd'] ** 2
        rho = ap['rho_moyenne_par_niveau'][self.niveau]
        self.m[RHO] = rho
        self.P[RHO, RHO] = (rho * ap['rho_sd_rel']) ** 2
        for c in range(5):
            self.m[EPS + c] = ap['eps_classe_moyenne'][c] * rho / ap['rho_moyenne_par_niveau'][1]
            self.P[EPS + c, EPS + c] = (ap['eps_classe_sd'] * rho / ap['rho_moyenne_par_niveau'][1]) ** 2
        for idx, cle in ((KN, 'k_nerveux'), (KM, 'k_musculaire'), (KL, 'k_nerveux_local'),
                         (KG, 'k_musculaire_systemique'), (BA, 'biais_rir_additif'),
                         (BP, 'biais_rir_proportionnel'), (LAM, 'courbe_forme'), (KU, 'courbe_echelle'),
                         (FI, 'fatigue_intra'), (HH, 'part_tenue')):
            self.m[idx] = ap[cle][0]
            self.P[idx, idx] = ap[cle][1] ** 2
        self.pistes = {}
        self.ordre = []
        self.jour = 0
        self.poids_kg = float(profil.get('poids_kg') or 72.0)
        # Compartiments de fatigue (valeurs au jour `self.jour`).
        f = params['fatigue']
        self.tau = [f['tau_nerveux_j'], f['tau_musculaire_j'], f['tau_tendineux_j']]
        # Chaque compartiment a une part systémique (toute la séance pèse)
        # et une part locale (par groupe musculaire sollicité) : indice 0 =
        # rapide (nerveux), 1 = lent (musculaire).
        self.f_g = [0.0, 0.0]
        self.f_l = [np.zeros(NGR), np.zeros(NGR)]
        self.f_tendon = {z: 0.0 for z in ZONES_TENDON}      # compartiment lent (28 j)
        self.f_tendon_aigu = {z: 0.0 for z in ZONES_TENDON}  # charge de la semaine en cours
        # Bruit du RIR appris (multiplicateur), notes paresseuses (Beta).
        self.bruit_rir = 1.0
        self.z2 = 1.0
        self.z2_n = 0.0
        self.paresse = list(params['mesure']['note_paresseuse_a_priori'])
        self.notes_demi = 0
        self.notes_entieres = 0
        # Séance en cours : branche « mauvais jour ».
        self.alt = None           # (m, P, logw) de la branche mauvais jour
        self.logw = 0.0
        self.en_seance = False
        self.bilan = None
        self.residus_seance = []  # innovations normalisées de la séance
        self.histoire_residus = []  # (jour, résidu moyen normalisé, résidu relatif)
        # Hypothèses de réponse (contrôle dual) : poids a posteriori.
        dyn = params['dynamique']
        self.hypotheses = [(s, k) for k in range(len(dyn['hypotheses_stimulus'])) for s in dyn['hypotheses_s0']]
        self.poids_hyp = [1.0 / len(self.hypotheses)] * len(self.hypotheses)
        self._dernier_ex = None
        self.semaines = 0
        self.journal_semaines = []  # doses et progrès par semaine (contrôle dual, synthétique)
        self.elargi = 0
        self.sonde = None         # diagnostic du banc : prévision avant chaque note
        self.oracle = None        # diagnostic du banc : effet de jour vrai

    # ------------------------------------------------------------------
    # Pistes et a priori
    # ------------------------------------------------------------------
    def _agrandir(self):
        if self.n + 3 <= self.m.shape[0]:
            return
        n = self.m.shape[0] * 2
        m = np.zeros(n)
        P = np.zeros((n, n))
        m[:self.n] = self.m[:self.n]
        P[:self.n, :self.n] = self.P[:self.n, :self.n]
        self.m, self.P = m, P
        if self.alt is not None:
            am, aP, lw = self.alt
            m2 = np.zeros(n)
            P2 = np.zeros((n, n))
            m2[:self.n] = am[:self.n]
            P2[:self.n, :self.n] = aP[:self.n, :self.n]
            self.alt = (m2, P2, lw)

    def base_de(self, fiche):
        """A priori de population de ln capacité d'un exercice (hors
        déclaration) : choix raisonné large, voir SOURCES.md § A priori."""
        ap = self.p['a_priori']
        typ = fiche['type']
        if typ == 'charge':
            total = fiche['ratio'] * self.poids_kg * ap['niveau_echelle_charge'][self.niveau]
            if self.profil.get('sexe') == 'female':
                total *= ap['facteur_femme']
            plancher = fiche.get('fraction', 0.0) * self.poids_kg * 1.1
            return math.log(max(total, plancher, 1.0))
        if typ in ('reps', 'tenue'):
            mn = ap['marge_niveau']
            marge = (mn[0] + mn[1] * self.niveau) - fiche.get('difficulte', 3)
            base = ap['reps_base'] if typ == 'reps' else ap['tenue_base_s']
            lo, hi = ap['reps_bornes'] if typ == 'reps' else ap['tenue_bornes_s']
            return math.log(clamp(base * math.exp(ap['pente_difficulte'] * marge), lo, hi))
        if typ == 'cardio':
            return math.log(ap['cardio_minutes_par_niveau'][self.niveau])
        return 0.0

    def piste(self, ex_id):
        """Piste de l'exercice (créée au besoin), ou None s'il n'est pas suivi."""
        t = self.pistes.get(ex_id)
        if t is not None or ex_id in self.pistes:
            return t
        fiche = self.vecteurs.get(ex_id)
        if fiche is None or fiche['type'] not in ('charge', 'reps', 'tenue', 'cardio', 'wod'):
            self.pistes[ex_id] = None
            return None
        self._agrandir()
        ap = self.p['a_priori']
        idx = self.n
        self.n += 3
        typ = fiche['type']
        base = self.base_de(fiche)
        sd = {'charge': ap['delta_sd'], 'reps': ap['reps_sd'], 'tenue': ap['reps_sd'],
              'cardio': ap['cardio_sd'], 'wod': ap['wod_sd']}[typ]
        vecteur = fiche['vecteur']
        declare = False
        t = Piste(ex_id, typ, vecteur, base, idx, fraction=fiche.get('fraction', 0.0),
                  bas=fiche.get('bas', False), tendon=fiche.get('tendon', 0.0),
                  zone_tendon=fiche.get('zone_tendon'), systemique=fiche.get('systemique', 1.0),
                  locale=fiche.get('locale', 1.0), declare=declare,
                  groupes=fiche.get('groupes'))
        for (m, P) in self._branches():
            m[idx] = 0.0
            # La part de la variance portée par les qualités est retirée de
            # l'écart propre à l'exercice (a priori total = sd²).
            vq = 0.0
            for q in range(NQ):
                vq += vecteur[q] * vecteur[q] * P[TH + q, TH + q]
            P[idx, idx] = max(sd * sd - vq, (0.5 * sd) ** 2)
            # Écart (ln) de la sensibilité de l'exercice à la fatigue laissée
            # par les séries précédentes de la séance.
            m[idx + 2] = 0.0
            P[idx + 2, idx + 2] = ap['fatigue_intra_exercice_sd'] ** 2
            if typ == 'tenue':
                # Écart (ln) de la part du temps maximal par répétition en
                # réserve, propre à l'exercice.
                m[idx + 1] = 0.0
                P[idx + 1, idx + 1] = ap['part_tenue_exercice_sd'] ** 2
            else:
                m[idx + 1] = ap['courbe_bas_du_corps'] if t.bas else 0.0
                P[idx + 1, idx + 1] = ap['courbe_echelle_exercice_sd'] ** 2
        self.pistes[ex_id] = t
        self.ordre.append(ex_id)
        d = (self.profil.get('declares') or {}).get(ex_id)
        if d is not None:
            # Capacité déclarée (record, test du profil) : une observation
            # de la capacité de l'exercice, qui renseigne aussi les qualités.
            mesure, valeur = d[0], d[1]
            sd_d = d[2] if len(d) > 2 and d[2] else ap['delta_sd_declare']
            voulu = {'charge': 'one_rm_kg', 'reps': 'max_reps', 'tenue': 'max_hold_seconds'}.get(typ)
            if mesure == voulu and valeur > 0:
                if typ == 'charge':
                    cible = math.log(valeur + t.fraction * self.poids_kg)
                else:
                    cible = math.log(valeur)
                hi, hc = self._h_capacite(t, jour=False)
                self._observer_hors(hi, hc, t.base - cible, None, None, sd_d ** 2, point=0.0)
                t.declare = True
        return t
    def _branches(self):
        out = [(self.m, self.P)]
        if self.alt is not None:
            out.append((self.alt[0], self.alt[1]))
        return out

    # ------------------------------------------------------------------
    # Courbe répétitions ↔ charge : famille de Box-Cox, g(R) = e^k G8 B(R, γ) / B(8, γ)
    # ------------------------------------------------------------------
    def _courbe_moyenne(self, reps, bas):
        ap = self.p['a_priori']
        k = ap['courbe_echelle'][0] + (ap['courbe_bas_du_corps'] if bas else 0.0)
        return self._g(ap['courbe_forme'][0], k, reps)

    @staticmethod
    def _g(lam, k, reps):
        """-ln(part du 1RM soulevable [reps] fois). Famille de Box-Cox en
        répétitions : g = e^k · G8 · B(R, γ) / B(8, γ), B(R, γ) = (R^γ - 1) / γ
        et γ = 1 - [lam]. Toutes les formes se croisent à 8 répétitions ;
        [lam] = 1 : logarithmique (Lombardi) ; 0 : log-linéaire ; négatif :
        convexe (part du 1RM linéaire en répétitions : Brzycki, Lander ≈ -0,3) ;
        e^[k] : échelle. La famille reproduit sept équations publiées à moins
        de 1,8 % de charge entre 2 et 20 répétitions (SOURCES.md § Courbe)."""
        r = 1.0 if reps < 1 else reps
        gam = 1.0 - lam
        a = math.log(r)
        return math.exp(k) * G8 * a * _phi(gam * a) / (LN8 * _phi(gam * LN8))

    @staticmethod
    def _dg(lam, k, reps):
        """Dérivée de g par rapport aux répétitions (plancher 0,004)."""
        r = 1.0 if reps < 1 else reps
        gam = 1.0 - lam
        d = math.exp(k) * G8 * math.exp((gam - 1.0) * math.log(r)) / (LN8 * _phi(gam * LN8))
        return d if d > 0.004 else 0.004

    @staticmethod
    def _dg_forme(lam, k, reps):
        """Dérivée de g par rapport à la forme [lam]."""
        r = 1.0 if reps < 1 else reps
        gam = 1.0 - lam
        a = math.log(r)
        den = LN8 * _phi(gam * LN8)
        num = a * _phi(gam * a)
        d_gam = math.exp(k) * G8 * (a * a * _phi1(gam * a) * den - num * LN8 * LN8 * _phi1(gam * LN8)) / (den * den)
        return -d_gam

    def courbe(self, t, m=None):
        """(forme, échelle) de la courbe de l'exercice : forme et échelle
        de l'utilisateur, échelle propre à l'exercice."""
        m = self.m if m is None else m
        return clamp(m[LAM], LAM_MIN, LAM_MAX), clamp(m[KU] + m[t.idx + 1], -1.0, 1.0)

    @staticmethod
    def _reps_de(lam, k, log_ratio):
        """Inverse de g (forme fermée) : répétitions R telles que
        g(lam, k, R) = [log_ratio] > 0, bornées à 200."""
        gam = 1.0 - lam
        y = log_ratio * LN8 * _phi(gam * LN8) / (math.exp(k) * G8)   # B(R, γ)
        u = gam * y
        if u <= -1.0 + 1e-12:
            return 200.0          # forme concave : charge sous l'asymptote
        if -1e-2 < u < 1e-2:
            ln_r = y * (1.0 + u * (-0.5 + u * (1.0 / 3.0 + u * (-0.25 + u * (0.2 + u * (
                -1.0 / 6.0 + u / 7.0))))))
        else:
            ln_r = math.log(1.0 + u) / gam
        if ln_r > 5.298317366548036:      # ln 200
            return 200.0
        r = math.exp(ln_r)
        return r if r > 1.0 else 1.0

    def reps_a(self, t, log_ratio, m=None):
        """Répétitions possibles quand ln(capacité / charge) = log_ratio
        (inverse de g)."""
        lam, k = self.courbe(t, m)
        if log_ratio <= 0:
            return 1.0 + log_ratio * 20.0 if log_ratio > -0.05 else 0.0
        return self._reps_de(lam, k, log_ratio)

    # ------------------------------------------------------------------
    # Compartiments de fatigue
    # ------------------------------------------------------------------
    def avancer(self, jour):
        """Avance le temps jusqu'à [jour] : décroissance des compartiments,
        bruit de processus, désentraînement."""
        dt = jour - self.jour
        if dt <= 0:
            return
        for c in (0, 1):
            e = math.exp(-dt / self.tau[c])
            self.f_g[c] *= e
            self.f_l[c] *= e
        e = math.exp(-dt / self.tau[2])
        for z in ZONES_TENDON:
            self.f_tendon[z] *= e
        dyn = self.p['dynamique']
        for ex_id in self.ordre:
            t = self.pistes[ex_id]
            self.P[t.idx, t.idx] += dyn['q_delta_jour_inactif'] * dt
        self.jour = jour

    def effort(self, rir, echec=False):
        f = self.p['fatigue']
        w = 1.0 / (1.0 + (rir if rir > 0 else 0.0) / f['effort_demi_rir'])
        return w + (f['echec_supplement'] if echec else 0.0)

    def effort_intra(self, rir):
        """Fatigue laissée dans la séance par une série : elle croît vite à
        l'approche de l'échec (SOURCES.md § Fatigue intra-séance)."""
        return math.exp(-(rir if rir > 0 else 0.0) / self.p['fatigue']['intra_rir'])

    def _charger_compartiments(self, t, effort, quantite=1.0):
        for c in (0, 1):
            self.f_g[c] += effort * t.systemique
            for g, w in t.groupes:
                self.f_l[c][g] += effort * t.locale * w
        if t.zone_tendon is not None and t.tendon > 0:
            self.f_tendon[t.zone_tendon] += effort * t.tendon * quantite
            self.f_tendon_aigu[t.zone_tendon] += effort * t.tendon * quantite

    def fatigue_de(self, t):
        """Régresseurs de fatigue de la piste au moment présent : (rapide
        systémique, rapide local, lent systémique, lent local)."""
        loc = [0.0, 0.0]
        if t.groupes_total > 0:
            for c in (0, 1):
                for g, w in t.groupes:
                    loc[c] += w * self.f_l[c][g]
                loc[c] /= t.groupes_total
        return self.f_g[0], loc[0], self.f_g[1], loc[1]

    @property
    def f_nerveux(self):
        return self.f_g[0]

    @property
    def f_musculaire(self):
        return self.f_l[1]

    def fatigue_intra_de(self, t, m=None):
        """Sensibilité de l'exercice à la fatigue de séance : valeur de
        population × écart propre à l'exercice (appris)."""
        m = self.m if m is None else m
        return clamp(m[FI], 0.0, 1.5) * math.exp(clamp(m[t.idx + 2], -1.5, 1.5))

    def garde_de(self, t, m=None):
        """Part des répétitions (ou du temps) gardée à la prochaine série."""
        g = 1.0 - self.fatigue_intra_de(t, m) * self._intra(t)
        return g if g > 0.3 else 0.3

    def _intra(self, t):
        """Régresseur de fatigue intra-séance de la prochaine série."""
        f = self.p['fatigue']
        s = 0.0
        n = len(t.series_seance)
        for i in range(n):
            eff, repos = t.series_seance[i]
            s += eff * math.exp(-repos / f['intra_repos_s']) * f['intra_report'] ** (n - 1 - i)
        return s

    # ------------------------------------------------------------------
    # Séance
    # ------------------------------------------------------------------
    def debut_seance(self, jour, bilan=None, poids_kg=None):
        """Ouvre une séance : effet de jour remis à son a priori (informé par
        le bilan de santé), branche « mauvais jour » ouverte."""
        self.avancer(jour)
        if poids_kg:
            self.poids_kg = float(poids_kg)
        j = self.p['jour']
        moyenne = 0.0
        sd = j['sigma_seance']
        p_mauvais = j['mauvais_jour_proba']
        general = None if bilan is None else bilan.get('overall')
        if general is not None:
            moyenne = j['bilan_par_point'] * (general - j['bilan_neutre'])
            sd = j['sigma_seance_avec_bilan']
            if general <= 2:
                p_mauvais = j['mauvais_jour_proba_bilan_bas']
        self._reset(self.m, self.P, DS, moyenne, sd * sd)
        self._reset(self.m, self.P, DE, 0.0, j['sigma_exercice'] ** 2)
        am = self.m.copy()
        aP = self.P.copy()
        self._reset(am, aP, DS, moyenne + j['mauvais_jour_moyenne'], j['mauvais_jour_sigma'] ** 2)
        self.alt = (am, aP, math.log(p_mauvais))
        self.logw = math.log(1.0 - p_mauvais)
        self.en_seance = True
        self.bilan = bilan
        self.residus_seance = []
        self._dernier_ex = None
        for ex_id in self.ordre:
            self.pistes[ex_id].series_seance = []

    def _reset(self, m, P, idx, moyenne, variance):
        P[idx, :] = 0.0
        P[:, idx] = 0.0
        P[idx, idx] = variance
        m[idx] = moyenne

    def debut_exercice(self, t):
        """Nouvel exercice dans la séance : effet de jour propre remis à zéro."""
        j = self.p['jour']
        for (m, P) in self._branches():
            self._reset(m, P, DE, 0.0, j['sigma_exercice'] ** 2)
        if self.oracle is not None:
            # Diagnostic du banc seulement : effet de jour vrai imposé.
            vrai = self.oracle(t.id)
            if vrai is not None:
                gn, ln_, gm, lm = self.fatigue_de(t)
                for (m, P) in self._branches():
                    self._reset(m, P, DS, 0.0, 1e-10)
                    self._reset(m, P, DE, vrai + gn * m[KN] + ln_ * m[KL] + gm * m[KG] + lm * m[KM], 1e-10)
        if t.jour_seance != self.jour:
            t.jour_prevu = self.capacite_du_jour(t.id)[0] if t.type == 'charge' and t.seances >= 3 else None
            t.jour_vu = None
            t.series_seance = []
            t.jour_seance = self.jour
            t.seances += 1
            if t.premier_jour is None:
                t.premier_jour = self.jour
        t.dernier_jour = self.jour

    def poids_mauvais_jour(self):
        if self.alt is None:
            return 0.0
        a = self.logw
        b = self.alt[2]
        mx = a if a > b else b
        return math.exp(b - mx) / (math.exp(a - mx) + math.exp(b - mx))

    def fin_seance(self):
        """Ferme la séance : fusion des deux branches par appariement des
        moments, innovations de la séance versées à la détection de rupture."""
        if not self.en_seance:
            return None
        # Résidu d'e1RM de la séance : moyenne, sur les mouvements chargés
        # suivis depuis 3 séances au moins, de l'écart (ln) entre la capacité
        # du jour vue après la séance et celle prévue avant.
        ecarts = []
        for ex_id in self.ordre:
            t = self.pistes[ex_id]
            if t.jour_seance == self.jour and t.jour_prevu is not None and t.jour_vu is not None:
                ecarts.append(t.jour_vu - t.jour_prevu)
        e1rm = sum(ecarts) / len(ecarts) if ecarts else None
        w = self.poids_mauvais_jour()
        if self.alt is not None and w > 1e-9:
            am, aP, _ = self.alt
            n = self.n
            m = (1 - w) * self.m[:n] + w * am[:n]
            d0 = self.m[:n] - m
            d1 = am[:n] - m
            P = (1 - w) * (self.P[:n, :n] + np.outer(d0, d0)) + w * (aP[:n, :n] + np.outer(d1, d1))
            self.m[:n] = m
            self.P[:n, :n] = P
        self.alt = None
        self.en_seance = False
        j = self.p['jour']
        self._reset(self.m, self.P, DS, 0.0, j['sigma_seance'] ** 2)
        self._reset(self.m, self.P, DE, 0.0, j['sigma_exercice'] ** 2)
        resume = None
        if self.residus_seance:
            zs = [r[0] for r in self.residus_seance]
            rel = [r[1] for r in self.residus_seance]
            resume = (self.jour, sum(zs) / len(zs), sum(rel) / len(rel), len(zs), w, e1rm)
            self.histoire_residus.append(resume)
        return resume

    # ------------------------------------------------------------------
    # Fonctionnelle linéaire d'un exercice
    # ------------------------------------------------------------------
    def _h_capacite(self, t, jour=True):
        """(indices, coefficients) de ln capacité du moment de la piste, hors
        constante `t.base` : qualités, écart de l'exercice, effets de jour,
        fatigue."""
        idx = []
        co = []
        for q in range(NQ):
            if t.vecteur[q] != 0.0:
                idx.append(TH + q)
                co.append(t.vecteur[q])
        idx.append(t.idx)
        co.append(1.0)
        if jour:
            gn, ln_, gm, lm = self.fatigue_de(t)
            idx += [DS, DE, KN, KL, KG, KM]
            co += [1.0, 1.0, -gn, -ln_, -gm, -lm]
        return idx, co

    @staticmethod
    def _stats(m, P, idx, co):
        """Moyenne et variance de h·x, et le vecteur P h."""
        n = P.shape[0]
        ph = np.zeros(n)
        mu = 0.0
        for i, c in zip(idx, co):
            mu += c * m[i]
            ph += c * P[:, i]
        v = 0.0
        for i, c in zip(idx, co):
            v += c * ph[i]
        return mu, v, ph

    @staticmethod
    def _appliquer(m, P, ph, mu, v, mu2, v2):
        """Report de la mise à jour scalaire (mu, v) -> (mu2, v2) sur l'état."""
        if v <= 0:
            return
        m += ph * ((mu2 - mu) / v)
        P -= np.outer(ph, ph) * ((v - v2) / (v * v))

    @staticmethod
    def _covariance_partielle(P, ph, pg, v, v2):
        """Mise à jour de covariance quand le gain [pg] est [ph] privé des
        composantes « considérées » (filtre de Schmidt) : le bloc des
        composantes écartées reste intact, les covariances croisées suivent."""
        w = (v - v2) / (v * v)
        P -= w * (np.outer(pg, ph) + np.outer(ph, pg) - np.outer(pg, pg))

    def _observer(self, idx, co, const, a, b, s2, point=None, melange=None, bruit=None, fonction=None,
                  fige=None):
        """Applique une observation aux deux branches. [a, b] : intervalle sur
        u = h·x + const ; [point] : valeur observée ; [melange] = (poids de
        la note sincère, poids d'une note sans information) ajoute une
        seconde composante qui laisse l'état inchangé. Renvoie (résidu
        normalisé, résidu relatif, informatif) de la branche principale."""
        resid = None
        for bi, (m, P) in enumerate(self._branches()):
            mu, v, ph = self._stats(m, P, idx, co)
            mu += const
            if point is not None:
                logz, mu2, v2 = point_moments(mu, v, s2, point)
                centre = point
            else:
                if bruit is not None:
                    # Bruit qui dépend de la valeur prédite (note en
                    # flammes : il croît avec la réserve vraie).
                    ge = self.p['mesure']['note_erreur_grossiere']
                    logz, mu2, v2 = category_moments(mu, v, a, b, bruit, gross=ge[0], gross_sd=ge[1])
                else:
                    logz, mu2, v2 = interval_moments(mu, v, s2, a, b)
                if melange is not None:
                    # (poids de la note sincère, poids d'une note qui ne dit
                    # rien : aberrante ou paresseuse).
                    w_main, w_nul = melange
                    mu_b, v_b = mu, v
                    la = math.log(w_main) + logz
                    lb = math.log(w_nul)
                    mx = la if la > lb else lb
                    wa = math.exp(la - mx)
                    wb = math.exp(lb - mx)
                    tot = wa + wb
                    wa /= tot
                    wb /= tot
                    mean = wa * mu2 + wb * mu_b
                    var = wa * (v2 + (mu2 - mean) ** 2) + wb * (v_b + (mu_b - mean) ** 2)
                    logz = mx + math.log(tot)
                    mu2, v2 = mean, var
                if a == -INF:
                    centre = b
                elif b == INF:
                    centre = a
                else:
                    centre = 0.5 * (a + b)
            if bi == 0:
                informatif = point is not None or (a != -INF and b != INF)
                dehors = (point is None) and ((a == -INF and mu > b) or (b == INF and mu < a))
                if informatif or dehors:
                    resid = ((centre - mu) / math.sqrt(v + s2), centre - mu, informatif and point is None)
            if v <= 0.0:
                continue
            pg = ph
            if fige:
                # Composantes « considérées » : elles pèsent dans la variance
                # prévue mais l'observation ne les déplace pas.
                pg = ph.copy()
                for i in fige:
                    pg[i] = 0.0
            if fonction is not None and abs(mu2 - mu) > 1.0:
                # Grande surprise : la carte état -> réserve n'est pas
                # linéaire. Le pas garde sa direction (linéarisation à la
                # moyenne a priori, symétrique) ; sa longueur est réduite
                # par dichotomie si, sur la carte exacte, il dépasse la
                # moyenne a posteriori visée.
                pas = pg * ((mu2 - mu) / v)
                alpha = 1.0
                if abs(fonction(m + pas) - mu) > abs(mu2 - mu):
                    lo_a, hi_a = 0.0, 1.0
                    for _ in range(12):
                        mid = 0.5 * (lo_a + hi_a)
                        if abs(fonction(m + mid * pas) - mu) > abs(mu2 - mu):
                            hi_a = mid
                        else:
                            lo_a = mid
                    alpha = lo_a
                m += alpha * pas
                # Pas raccourci : la covariance suit le gain réduit (forme
                # de Joseph avec le gain alpha·K : facteur 2·alpha − alpha²).
                v2a = v - (2.0 * alpha - alpha * alpha) * (v - v2)
                if fige:
                    self._covariance_partielle(P, ph, pg, v, v2a)
                else:
                    P -= np.outer(ph, ph) * ((v - v2a) / (v * v))
            elif fige:
                m += pg * ((mu2 - mu) / v)
                self._covariance_partielle(P, ph, pg, v, v2)
            else:
                self._appliquer(m, P, ph, mu - const, v, mu2 - const, v2)
            if bi == 0:
                self.logw += logz
            else:
                self.alt = (m, P, self.alt[2] + logz)
        return resid

    # ------------------------------------------------------------------
    # Bruit et biais de la note
    # ------------------------------------------------------------------
    def bruit_rir_de(self, rir, reps):
        me = self.p['mesure']
        base = me['bruit_rir_par_niveau'][self.niveau] * self.bruit_rir
        # Le bruit du cahier (2,0 / 1,5 / 1,0 selon le niveau) vaut loin de
        # l'échec (réserve de référence) ; il décroît près de l'échec.
        s = base * (me['bruit_rir_plancher'] + me['bruit_rir_pente'] * rir) / \
            (me['bruit_rir_plancher'] + me['bruit_rir_pente'] * me['bruit_rir_reference'])
        if reps > me['bruit_rir_longue_serie_de']:
            s *= 1 + me['bruit_rir_longue_serie_pente'] * (reps - me['bruit_rir_longue_serie_de'])
        return s

    def noter_resolution(self, flammes):
        """Apprend la résolution des notes de l'utilisateur : certains ne
        notent qu'en répétitions entières (flammes impaires). Compte les
        notes à la demi-répétition (flammes paires 2 à 8)."""
        if flammes is None or flammes >= 10:
            return
        if flammes in (2, 4, 6, 8):
            self.notes_demi += 1
        else:
            self.notes_entieres += 1

    def noteur_entier(self):
        me = self.p['mesure']
        n = self.notes_demi + self.notes_entieres
        return n >= me['noteur_entier_notes_min'] and self.notes_demi <= me['noteur_entier_part_max'] * n

    def bornes_flammes(self, flammes, ouvert=5.0):
        """Intervalle de RIR d'une note en flammes (kalis_core `Flames`) et
        son centre : 10 -> échec ; 9 -> [0,25 ; 1,25] ; f -> demi-répétition ;
        1 -> RIR 5 et plus (ouvert). Pour un utilisateur qui ne note qu'en
        répétitions entières, chaque note couvre une répétition entière."""
        if flammes >= 10:
            return 0.0, 0.25, 0.0
        entier = self.noteur_entier()
        if flammes == 9:
            return 0.25, (1.5 if entier else 1.25), 1.0
        r = (11 - flammes) / 2.0
        demi = 0.5 if entier else 0.25
        if r >= ouvert:
            # Loin de l'échec, la note ne distingue plus : « 4 répétitions
            # en réserve ou plus » (échelle de Zourdos et al. 2016).
            return r - demi, INF, r
        return r - demi, r + demi, r

    def rir_vrai(self, percu, m=None):
        """Réserve vraie attendue pour une réserve perçue (biais du modèle
        de mesure : perçu = (vrai - biais personnel) / (1 + biais de
        population))."""
        m = self.m if m is None else m
        if percu <= 0:
            return 0.0
        v = percu * (1.0 + clamp(m[BP], -0.2, 1.0)) + clamp(m[BA], -2.5, 2.5)
        return v if v > 0.0 else 0.0

    # ------------------------------------------------------------------
    # Observation d'une série
    # ------------------------------------------------------------------
    def observer_serie(self, s):
        """Verse une série du journal. Champs lus : exerciseId, kind,
        externalLoadKg, reps, seconds, flames, failed, target (repsLow,
        repsHigh, secondsLow, secondsHigh, flames), restSeconds, manual,
        parts, assistKg. Renvoie la piste ou None."""
        t = self.piste(s['exerciseId'])
        if t is None:
            return None
        if self._dernier_ex != t.id:
            self.debut_exercice(t)
        self._dernier_ex = t.id
        if not s.get('failed'):
            self.noter_resolution(s.get('flames'))
        typ = t.type
        if typ in ('charge', 'reps'):
            r = self._serie_force(t, s)
        elif typ == 'tenue':
            r = self._serie_tenue(t, s)
        else:
            r = self._serie_endurance(t, s)
        if t.jour_prevu is not None:
            t.jour_vu = self.capacite_du_jour(t.id)[0]
        if r is not None:
            self.residus_seance.append(r)
            t.residus.append((self.jour, r[0], r[1]))
            if typ in ('charge', 'reps') and r[2]:
                self._apprendre_bruit(r[0])
            self._projeter()
        return t

    def _apprendre_bruit(self, z):
        me = self.p['mesure']
        lam = me['apprentissage_bruit_oubli']
        self.z2 = lam * self.z2 + (1 - lam) * min(z * z, 9.0)
        self.z2_n = lam * self.z2_n + 1.0
        if self.z2_n > 12:
            lo, hi = me['apprentissage_bruit_bornes']
            cible = math.sqrt(self.z2)
            self.bruit_rir = clamp(self.bruit_rir * (1 + 0.02 * (cible - 1.0)), lo, hi)

    def masse(self, t, externe):
        if t.type == 'charge':
            return (externe or 0.0) + t.fraction * self.poids_kg
        return 1.0

    def _projeter(self):
        """Garde-fou numérique : les sensibilités restent positives."""
        for (m, _) in self._branches():
            for i in (KN, KM, KL, KG):
                if m[i] < 0.0:
                    m[i] = 0.0
            if m[LAM] < LAM_MIN:
                m[LAM] = LAM_MIN
            if m[LAM] > LAM_MAX:
                m[LAM] = LAM_MAX

    def _lin_force(self, t, m, lnL, reps, sj, sans_charge, percu):
        """Linéarise, autour de la moyenne [m], la réserve de la série :
        vraie (v = répétitions possibles - faites) ou perçue (p = (v - biais
        personnel) / (1 + biais de population)). Renvoie (indices,
        coefficients, valeur prédite, répétitions possibles à frais, v)."""
        idx, co = self._h_capacite(t)
        eta = t.base
        for i, c in zip(idx, co):
            eta += c * m[i]
        fi = self.fatigue_intra_de(t, m)
        garde = 1.0 - fi * sj
        if garde < 0.3:
            garde = 0.3
        if sans_charge:
            R = math.exp(eta)
            dR = R                      # dR/d eta
            dlam = dk = 0.0
        else:
            lam, k = self.courbe(t, m)
            x = eta - lnL
            R = self.reps_a(t, x, m)
            if x <= 0:
                dR = 20.0
                dlam = dk = 0.0
            else:
                d = self._dg(lam, k, R)
                r1 = R if R > 1 else 1.0
                dR = 1.0 / d
                dlam = -self._dg_forme(lam, k, r1) / d
                dk = -self._g(lam, k, R) / d
        v = R * garde - reps
        coefs = [c * dR * garde for c in co]
        indices = list(idx)
        if not sans_charge:
            indices += [LAM, KU, t.idx + 1]
            coefs += [dlam * garde, dk * garde, dk * garde]
        if sj > 0 and garde > 0.3:
            # d garde / d (écart de fatigue de l'exercice) = -fi × sj.
            indices.append(t.idx + 2)
            coefs.append(-R * sj * fi)
        if not percu:
            return indices, coefs, v, R, v
        ba = clamp(m[BA], -2.5, 2.5)
        bp = clamp(m[BP], -0.2, 1.0)
        pr = (v - ba) / (1.0 + bp)
        coefs = [c / (1.0 + bp) for c in coefs]
        indices += [BA, BP]
        coefs += [-1.0 / (1.0 + bp), -pr / (1.0 + bp)]
        return indices, coefs, pr, R, v

    def _serie_force(self, t, s):
        """Série de force (charge ou poids du corps). Sens génératif : la
        note en flammes est une catégorie ordonnée de la réserve PERÇUE,
        fonction de la réserve vraie (capacité, courbe, fatigue de la séance)
        et du biais de l'utilisateur, à un bruit près (modèle gradué)."""
        me = self.p['mesure']
        reps = s.get('reps') or 0
        externe = s.get('externalLoadKg')
        flammes = s.get('flames')
        cible = s.get('target') or {}
        echec = bool(s.get('failed'))
        repos = 90 if s.get('restSeconds') is None else s['restSeconds']
        charge = self.masse(t, externe)
        sans_charge = t.type == 'reps'
        if charge <= 0 and not sans_charge:
            return None
        lnL = 0.0 if sans_charge else math.log(charge)
        sj = self._intra(t)
        resid = None
        rir_c = 2.0
        if reps <= 0 and echec:
            # Barre manquée : la capacité du moment est sous la charge.
            if not sans_charge:
                idx, co = self._h_capacite(t)
                resid = self._observer(idx, co, t.base - lnL, -INF, 0.0, me['bruit_test'] ** 2)
            rir_c = 0.0
        else:
            percu = not (echec or flammes is None)
            if echec:
                a, b = 0.0, 1.0          # réserve vraie nulle : entre n et n + 1
            elif flammes is None:
                a, b = 0.0, INF          # série faite sans note : au moins n
            elif flammes >= 10:
                a, b = -INF, 0.25
            else:
                a, b, _ = self.bornes_flammes(flammes, me['rir_ouvert'])
            # Linéarisation à la moyenne a priori, en une passe : relinéariser
            # autour de la moyenne a posteriori rend les mises à jour
            # dissymétriques (une note haute et une note basse ne déplacent
            # pas l'état le long de la même direction) et, avec une charge
            # choisie par le modèle lui-même, fait dériver ensemble la
            # capacité et la courbe (mesuré sur le banc synthétique).
            lin = self.m
            idx, co, pred, R, v = self._lin_force(t, lin, lnL, reps, sj, sans_charge, percu)
            s2 = self._bruit_force(percu, v, reps, R, me, sj)
            const = pred
            for i, c in zip(idx, co):
                const -= c * lin[i]
            melange = None
            f_cible = cible.get('flames')
            if percu:
                # Note aberrante (erreur de saisie, distraction) : avec une
                # petite probabilité la note ne dit rien ; note paresseuse :
                # probabilité apprise quand la note est la note préremplie.
                eps = me['note_aberrante']
                par = 0.0
                if f_cible is not None and flammes == f_cible:
                    par = clamp(self.paresse[0] / (self.paresse[0] + self.paresse[1]), 0.01, 0.9)
                # Une note aberrante tombe au hasard sur l'une des dix
                # flammes ; une note paresseuse est toujours la préremplie.
                melange = ((1.0 - eps) * (1.0 - par), eps * 0.1 + (1.0 - eps) * par)
            if self.sonde is not None:
                _, var_p, _ = self._stats(self.m, self.P, idx, co)
                self.sonde.append((t.id, t.type, pred, var_p, s2, a, b, reps, R, sj, len(t.series_seance), t.seances))
            if flammes is None and not echec and pred >= a:
                # Série faite SANS note et déjà prévue faisable : elle ne dit
                # rien. La borne « au moins n répétitions » ne peut déplacer
                # l'état que vers le haut ; versée à chaque série, elle
                # fait monter la capacité sans fin (cliquet mesuré au rejeu
                # d'un journal réel où la plupart des séries ne sont pas
                # notées). Elle n'est donc versée que si la prévision la
                # contredit (réserve prévue négative).
                resid = None
            elif b == INF and percu and pred >= a + me['porte_note_ouverte'] * math.sqrt(s2):
                # Note ouverte (« 4 en réserve ou plus ») nettement attendue :
                # elle ne dit rien de plus. Sans cette porte, l'appariement de
                # moments rogne à chaque série facile la queue basse de la
                # prévision et aplatit peu à peu la courbe de l'exercice.
                resid = None
            else:
                bruit = None
                if percu:
                    ba_ = clamp(self.m[BA], -2.5, 2.5)
                    bp_ = clamp(self.m[BP], -0.2, 1.0)
                    extra = (me['dispersion_fatigue_intra'] * sj * R) ** 2

                    def bruit(u, ba_=ba_, bp_=bp_, extra=extra, R=R):
                        r = u * (1.0 + bp_) + ba_
                        if r < 0.0:
                            r = 0.0
                        if r > 8.0:
                            r = 8.0
                        sd = self.bruit_rir_de(r, R)
                        return sd * sd + extra

                def exacte(etat, t=t, lnL=lnL, reps=reps, sj=sj, sans_charge=sans_charge, percu=percu):
                    return self._lin_force(t, etat, lnL, reps, sj, sans_charge, percu)[2]
                # Série sans note qui contredit la prévision : elle dit que
                # la capacité est plus haute, pas quelle est la forme de la
                # courbe ; la forme (commune) et l'échelle de courbe de
                # l'exercice sont « considérées », non déplacées.
                fige = None
                if flammes is None and not echec:
                    fige = (LAM,) if sans_charge else (LAM, t.idx + 1)
                resid = self._observer(idx, co, const, a, b, s2, melange=melange, bruit=bruit,
                                       fonction=exacte, fige=fige)
            if percu and f_cible is not None and resid is not None and abs(resid[1]) > 1.0:
                # Notes paresseuses : part des notes égales à la note
                # préremplie quand l'attendu en est à plus d'une répétition.
                if flammes == f_cible:
                    self.paresse[0] += 1.0
                else:
                    self.paresse[1] += 1.0
            self._projeter()
            _, _, _, _, v_post = self._lin_force(t, self.m, lnL, reps, sj, sans_charge, False)
            rir_c = v_post if v_post > 0 else 0.0
            if echec:
                rir_c = 0.0
        # Compartiments et stimulus de la semaine.
        eff = self.effort(rir_c, echec)
        t.series_seance.append((self.effort_intra(rir_c), repos))
        self._charger_compartiments(t, eff)
        self._stimulus(t, rir_c, lnL, reps > 0)
        t.mesures += 1
        if echec or s.get('repere') or s.get('role') in ('test', 'attempt'):
            t.dernier_test_jour = self.jour
        if reps > 0 and not echec and not sans_charge:
            if t.meilleur is None or charge > t.meilleur[0]:
                t.meilleur = (charge, self.jour)
        return resid

    def _bruit_force(self, percu, v, reps, R, me, sj=0.0):
        # La fatigue laissée par les séries précédentes varie d'un exercice
        # à l'autre : une série qui suit une série dure renseigne moins.
        extra = (me['dispersion_fatigue_intra'] * sj * R) ** 2
        if not percu:
            return 0.35 ** 2 + extra
        r = v if v > 0 else 0.0
        if r > 8:
            r = 8.0
        return self.bruit_rir_de(r, R) ** 2 + extra

    def _apercu(self, idx, co, pred, a, b, s2):
        """Moyenne a posteriori approchée (branche principale) d'une
        observation, sans toucher à l'état : point de relinéarisation."""
        m = self.m.copy()
        mu, v, ph = self._stats(self.m, self.P, idx, co)
        const = pred - mu
        _, mu2, _ = interval_moments(pred, v, s2, a, b)
        if v > 0:
            m += ph * ((mu2 - pred) / v)
        return m

    def _stimulus(self, t, rir, lnL, fait):
        if not fait:
            return
        part = 1.0
        if t.type == 'charge':
            part = math.exp(lnL - (t.base + self._mu(t)))
        t.stim_semaine[0] += 1.0 if rir <= 4 else 0.5
        t.stim_semaine[1] += 1.0 / (1.0 + (rir - 1 if rir > 1 else 0.0) / 3.0)
        t.stim_semaine[2] += clamp((part - 0.4) / 0.4, 0.2, 1.5)

    def _mu(self, t, m=None):
        m = self.m if m is None else m
        v = m[t.idx]
        for q in range(NQ):
            v += t.vecteur[q] * m[TH + q]
        return v

    def _lin_tenue(self, t, m, ln_s, percu):
        """Réserve d'un maintien de durée s (ln_s = ln(s / garde)) : r =
        (1 - s / T) / h_e, avec h_e = h × exp(écart de l'exercice) la part du
        temps maximal par répétition en réserve ; perçue : p = (r - biais
        personnel) / (1 + biais de population). Linéarisée autour de [m].
        Renvoie (indices, coefficients, valeur prédite, r)."""
        idx, co = self._h_capacite(t)
        eta = t.base
        for i, c in zip(idx, co):
            eta += c * m[i]
        hh = clamp(m[HH], 0.03, 0.30) * math.exp(clamp(m[t.idx + 1], -1.0, 1.0))
        part = math.exp(ln_s - eta)
        if part > 3.0:
            part = 3.0
        r = (1.0 - part) / hh
        coefs = [c * part / hh for c in co]
        indices = list(idx)
        indices.append(t.idx + 1)
        coefs.append(-r)
        if not percu:
            return indices, coefs, r, r
        ba = clamp(m[BA], -2.5, 2.5)
        bp = clamp(m[BP], -0.2, 1.0)
        pr = (r - ba) / (1.0 + bp)
        coefs = [c / (1.0 + bp) for c in coefs]
        indices += [BA, BP]
        coefs += [-1.0 / (1.0 + bp), -pr / (1.0 + bp)]
        return indices, coefs, pr, r

    def _serie_tenue(self, t, s):
        """Maintien : modèle de survie. Tenue ratée = temps jusqu'à l'échec
        observé (ln T) ; tenue réussie sans note = temps censuré à droite ;
        avec une note, catégorie ordonnée de la réserve perçue, fonction de
        la part du temps maximal tenue et de la part par répétition en
        réserve propre à l'exercice (apprise avec le temps maximal)."""
        me = self.p['mesure']
        sec = s.get('seconds') or 0
        flammes = s.get('flames')
        echec = bool(s.get('failed'))
        repos = 90 if s.get('restSeconds') is None else s['restSeconds']
        if sec <= 0 and not echec:
            return None
        idx, co = self._h_capacite(t)
        sj = self._intra(t)
        garde = self.garde_de(t)
        ln_s = math.log((sec if sec > 0 else 0.5) / garde)
        bt = me['bruit_tenue']
        extra = (me['dispersion_fatigue_intra'] * sj) ** 2
        if echec:
            resid = self._observer(idx, co, t.base - ln_s, None, None, (bt / 2) ** 2 + extra, point=0.0)
            rir_c = 0.0
        elif flammes is None:
            # Tenue faite sans note : versée seulement si la prévision la
            # contredit (même règle que pour les répétitions).
            mu0, _, _ = self._stats(self.m, self.P, idx, co)
            resid = None
            if mu0 + t.base - ln_s < 0.0:
                resid = self._observer(idx, co, t.base - ln_s, 0.0, INF, bt ** 2 + extra)
            rir_c = 2.0
        else:
            if flammes >= 10:
                a, b = -INF, 0.25
            else:
                a, b, _ = self.bornes_flammes(flammes, me['rir_ouvert'])
            ix, cx, pred, r0 = self._lin_tenue(t, self.m, ln_s, True)
            const = pred
            for i, c in zip(ix, cx):
                const -= c * self.m[i]
            ba = clamp(self.m[BA], -2.5, 2.5)
            bp = clamp(self.m[BP], -0.2, 1.0)
            hh0 = clamp(self.m[HH], 0.03, 0.30)
            # Dispersion propre aux tenues (ln T) ramenée à l'échelle de la
            # réserve : bt / h.
            plus = (bt / hh0) ** 2 / (1.0 + bp) ** 2 + (me['dispersion_fatigue_intra'] * sj / hh0) ** 2

            def bruit(u, ba=ba, bp=bp, plus=plus):
                r = u * (1.0 + bp) + ba
                if r < 0.0:
                    r = 0.0
                if r > 8.0:
                    r = 8.0
                sd = self.bruit_rir_de(r, 6)
                return sd * sd + plus
            f_cible = (s.get('target') or {}).get('flames')
            eps = me['note_aberrante']
            par = 0.0
            if f_cible is not None and flammes == f_cible:
                par = clamp(self.paresse[0] / (self.paresse[0] + self.paresse[1]), 0.01, 0.9)
            melange = ((1.0 - eps) * (1.0 - par), eps * 0.1 + (1.0 - eps) * par)

            def exacte(etat, t=t, ln_s=ln_s):
                return self._lin_tenue(t, etat, ln_s, True)[2]
            resid = self._observer(ix, cx, const, a, b, bruit(pred), melange=melange, bruit=bruit,
                                   fonction=exacte)
            self._projeter()
            r = self._lin_tenue(t, self.m, ln_s, False)[3]
            rir_c = r if r > 0 else 0.0
        eff = self.effort(rir_c, echec)
        t.series_seance.append((self.effort_intra(rir_c), repos))
        self._charger_compartiments(t, eff, quantite=max(sec, 1) / 10.0)
        self._stimulus(t, rir_c, 0.0, sec > 0)
        t.mesures += 1
        if echec or s.get('repere') or s.get('role') in ('test', 'attempt'):
            t.dernier_test_jour = self.jour
        return resid

    def _serie_endurance(self, t, s):
        """Course, cardio, conditionnement : la demande relative (durée ×
        poids de l'intensité sur la capacité) se lit dans l'effort perçu
        (gradué) et dans la part faite."""
        me = self.p['mesure']
        demande = s.get('demand')
        if demande is None or demande <= 0:
            return None
        flammes = s.get('flames')
        fait = s.get('doneShare', 1.0)
        idx, co = self._h_capacite(t, jour=True)
        ln_d = math.log(demande)
        pente = me['cardio_pente_rir'] if t.type == 'cardio' else me['wod_pente_rir']
        neutre = me['cardio_charge_neutre'] if t.type == 'cardio' else 1.0
        bruit = me['bruit_cardio'] if t.type == 'cardio' else me['bruit_wod']
        cible = (s.get('target') or {}).get('flames')
        rir_cible = (5.0 if t.type == 'cardio' else 2.0) if cible is None else (0.0 if cible >= 10 else (11 - cible) / 2.0)
        resid = None
        if fait < 0.999:
            # Séance écourtée : la demande dépassait nettement la capacité.
            resid = self._observer(idx, co, t.base - ln_d, -INF, -math.log(1.3), bruit ** 2)
        elif flammes is not None:
            if flammes >= 10:
                a, b = -INF, 0.25
            else:
                a, b, _ = self.bornes_flammes(flammes, me['rir_ouvert'])
            # Réserve perçue = réserve visée - pente × (demande / capacité - neutre).
            eta = t.base
            for i, c in zip(idx, co):
                eta += c * self.m[i]
            rel = math.exp(ln_d - eta)
            pred = rir_cible - pente * (rel - neutre)
            cx = [c * pente * rel for c in co]
            const = pred
            for i, c in zip(idx, cx):
                const -= c * self.m[i]
            resid = self._observer(idx, cx, const, a, b, me['bruit_rir_endurance'] ** 2)
        eff = 0.6 if flammes is None else self.effort((11 - flammes) / 2.0 if flammes < 10 else 0.0)
        self._charger_compartiments(t, eff * (s.get('fatigueSets') or 1.0))
        t.stim_semaine[0] += s.get('dose', 1.0)
        t.stim_semaine[1] += s.get('dose', 1.0)
        t.stim_semaine[2] += s.get('dose', 1.0)
        t.mesures += 1
        return resid

    def observer_raison(self, ex_id, raison, charge_kg, reps, rir):
        """Refus motivé « trop lourd » / « trop léger » : mesure faible de la
        capacité (cahier § 8), à bruit élevé."""
        t = self.piste(ex_id)
        if t is None or t.type != 'charge' or raison not in ('too_heavy', 'too_light'):
            return
        lam, k = self.courbe(t)
        masse = self.masse(t, charge_kg)
        if masse <= 0 or reps is None:
            return
        rir = 0.0 if rir is None else rir
        lnL = math.log(masse)
        idx, co = self._h_capacite(t, jour=False)
        const = t.base - lnL - self._g(lam, k, reps + rir)
        s2 = self.p['mesure']['bruit_raison_refus'] ** 2
        if raison == 'too_heavy':
            self._observer_hors(idx, co, const, -INF, 0.0, s2)
        else:
            self._observer_hors(idx, co, const, 0.0, INF, s2)

    def observer_charge_manuelle(self, ex_id, charge_kg, reps, rir):
        """Charge modifiée à la main : mesure fiable de ce que l'utilisateur
        sait pouvoir faire (cahier § 3)."""
        t = self.piste(ex_id)
        if t is None or t.type != 'charge':
            return
        lam, k = self.courbe(t)
        masse = self.masse(t, charge_kg)
        if masse <= 0 or reps is None:
            return
        rir = 0.0 if rir is None else rir
        lnL = math.log(masse)
        idx, co = self._h_capacite(t, jour=False)
        const = t.base - lnL - self._g(lam, k, reps + rir)
        self._observer_hors(idx, co, const, None, None, self.p['mesure']['bruit_charge_manuelle'] ** 2, point=0.0)

    def _observer_hors(self, idx, co, const, a, b, s2, point=None):
        """Observation hors série (valeur déclarée, raison, charge manuelle) :
        appliquée aux deux branches du jour sans changer leur poids."""
        lw = self.logw
        la = self.alt[2] if self.alt is not None else None
        self._observer(idx, co, const, a, b, s2, point=point)
        self.logw = lw
        if self.alt is not None:
            self.alt = (self.alt[0], self.alt[1], la)

    def changer_cran(self, ex_id, facteur):
        """Changement de cran d'élastique : la capacité attendue est
        multipliée par [facteur], l'incertitude élargie."""
        t = self.piste(ex_id)
        if t is None:
            return
        sd = self.p['dynamique']['changement_cran_elastique_sd']
        for (m, P) in self._branches():
            m[t.idx] += math.log(facteur)
            P[t.idx, t.idx] += sd * sd

    # ------------------------------------------------------------------
    # Fin de semaine : réponse à l'entraînement
    # ------------------------------------------------------------------
    def dose(self, stim, hyp):
        s0, k = hyp
        ref = self.p['dynamique']['dose_reference']
        s = stim[k]
        if s <= 0:
            return 0.0
        return (1 - math.exp(-s / s0)) / (1 - math.exp(-ref / s0))

    def dose_moyenne(self, stim):
        d = 0.0
        for w, h in zip(self.poids_hyp, self.hypotheses):
            d += w * self.dose(stim, h)
        return d

    def recuperation(self, fatigue_lente):
        """Part de la réponse gardée quand la fatigue systémique lente est
        haute (surmenage) : 1 sous le seuil, puis décroissante jusqu'au
        plancher. Valeurs de population calées sur le banc (SOURCES.md)."""
        dyn = self.p['dynamique']
        f0 = dyn['recuperation_seuil']
        k = 1.0 - dyn['recuperation_pente'] * (fatigue_lente - f0 if fatigue_lente > f0 else 0.0) / f0
        return k if k > dyn['recuperation_plancher'] else dyn['recuperation_plancher']

    def accoutumance(self, semaines):
        """Rendements décroissants au fil des semaines de journal."""
        return 1.0 / (1.0 + semaines / self.p['dynamique']['accoutumance_semaines'])

    def fin_semaine(self):
        """Lundi : la capacité de chaque exercice travaillé progresse de
        (rho + eps_classe) × dose ; les autres se désentraînent après le délai
        de grâce ; bruit de processus."""
        dyn = self.p['dynamique']
        n = self.n
        m, P = self.m, self.P
        ligne = {'semaine': self.semaines, 'doses': {}, 'mu': {}, 'fatigue_lente': float(self.f_g[1]),
                 'fatigue_rapide': float(self.f_g[0])}
        facteur = self.recuperation(float(self.f_g[1])) * self.accoutumance(self.semaines)
        ligne['facteur'] = facteur
        for ex_id in self.ordre:
            t = self.pistes[ex_id]
            g = self.dose_moyenne(t.stim_semaine) * facteur
            ligne['doses'][ex_id] = list(t.stim_semaine)
            if g > 0:
                e = EPS + t.classe
                # x_d' = x_d + g (rho + eps) : P' = A P A^T.
                P[t.idx, :n] += g * (P[RHO, :n] + P[e, :n])
                P[:n, t.idx] += g * (P[:n, RHO] + P[:n, e])
                m[t.idx] += g * (m[RHO] + m[e])
            else:
                inactif = self.jour - (t.dernier_jour if t.dernier_jour is not None else self.jour)
                if inactif > dyn['desentrainement_grace_j']:
                    m[t.idx] -= dyn['desentrainement_par_semaine']
                    P[t.idx, t.idx] += (0.5 * dyn['desentrainement_par_semaine']) ** 2
            P[t.idx, t.idx] += dyn['q_delta_semaine']
            ligne['mu'][ex_id] = t.base + self._mu(t)
            t.stim_semaine = [0.0, 0.0, 0.0]
        for q in range(NQ):
            P[TH + q, TH + q] += dyn['q_theta_semaine']
        P[RHO, RHO] += dyn['q_reponse_semaine']
        for z in ZONES_TENDON:
            self.f_tendon_aigu[z] = 0.0
        self.semaines += 1
        self.journal_semaines.append(ligne)
        return ligne

    def elargir(self, facteur):
        """« Rien de spécial » au diagnostic : incertitude élargie sur les
        capacités, réapprentissage rapide (cahier § 9)."""
        for ex_id in self.ordre:
            t = self.pistes[ex_id]
            self.P[t.idx, t.idx] *= facteur
        for q in range(NQ):
            self.P[TH + q, TH + q] *= facteur
        self.elargi += 1

    # ------------------------------------------------------------------
    # Lecture de l'a posteriori
    # ------------------------------------------------------------------
    def capacite(self, ex_id):
        """(moyenne, écart-type) de ln capacité à frais de l'exercice (hors
        effet de jour et fatigue), ou None."""
        t = self.piste(ex_id)
        if t is None:
            return None
        idx, co = self._h_capacite(t, jour=False)
        mu, v, _ = self._stats(self.m, self.P, idx, co)
        # Défaut de modèle : part de l'erreur que le filtre gaussien ne
        # voit pas (forme de courbe, densité supposée), calée sur le banc
        # pour que l'intervalle à 90 % couvre 88 à 92 %.
        d = self.p['mesure'].get('defaut_modele_sd', 0.0)
        return t.base + mu, math.sqrt((v if v > 0 else 0.0) + d * d)

    def capacite_du_jour(self, ex_id, avec_bruit_jour=True):
        """(moyenne, écart-type) de ln capacité du moment (effets de jour et
        fatigue compris), mélange des deux branches."""
        t = self.piste(ex_id)
        if t is None:
            return None
        idx, co = self._h_capacite(t)
        mu, v, _ = self._stats(self.m, self.P, idx, co)
        if self.alt is not None:
            w = self.poids_mauvais_jour()
            mu1, v1, _ = self._stats(self.alt[0], self.alt[1], idx, co)
            mean = (1 - w) * mu + w * mu1
            v = (1 - w) * (v + (mu - mean) ** 2) + w * (v1 + (mu1 - mean) ** 2)
            mu = mean
        return t.base + mu, math.sqrt(v if v > 0 else 0.0)

    def intervalle(self, ex_id, niveau=0.90):
        c = self.capacite(ex_id)
        if c is None:
            return None
        z = 1.6448536269514722 if niveau == 0.90 else norm_ppf(0.5 + 0.5 * niveau)
        return math.exp(c[0] - z * c[1]), math.exp(c[0]), math.exp(c[0] + z * c[1])

    def valeur(self, ex_id):
        """Capacité dans l'unité naturelle de l'exercice : 1RM de charge
        totale (kg), répétitions maximales, secondes maximales, ou capacité
        d'endurance."""
        t = self.piste(ex_id)
        c = self.capacite(ex_id)
        if c is None:
            return None
        return math.exp(c[0])
