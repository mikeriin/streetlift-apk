# -*- coding: utf-8 -*-
"""Koach 1.0 — hors modèle (cahier KM § 9).

Trois pièces :

* `Bocpd` : détection bayésienne de rupture en ligne (Adams & MacKay 2007,
  arXiv:0710.3742) sur le flux des résidus normalisés moyens de séance ;
* `Surveillance` : extension du moteur qui tient la BOCPD, les seuils de
  secours (résidu d'e1RM, assiduité, douleur), le diagnostic en 3 questions
  au plus et ses actions codées, le dossier hors modèle exportable et
  l'import d'un fichier de paramètres ;
* `calibrer_alerte` : outil du banc (fausses alertes et délai de détection
  pour une liste de seuils).

Tout est écrit avec des boucles de longueur fixe et des opérations
élémentaires (portage ligne pour ligne en Dart, parité à 1e-9). Aucun aléa.
"""
import copy
import json
import math

from .moteur import Extension

LOG_2PI = 1.8378770664093453   # ln(2π)
LOG_PI = 1.1447298858494002    # ln(π)

# Valeurs par défaut des paramètres `rupture` (lus par .get(clé, défaut)).
DEFAUTS_RUPTURE = {
    'hasard': 0.02,
    'alerte': 0.6,
    'fenetre': 3,                   # lu pour mémoire, remplacé par fenetre_seances
    'a_priori_moyenne_sd': 2.0,
    # Clés nouvelles (absentes de koach_params_v1.json, défauts justifiés
    # dans LIVRAISON) :
    'a_priori_alpha': 2.0,          # a priori gamma de la précision : forme
    'a_priori_beta': 1.0,           # … et taux : variance attendue β/(α-1) = 1
    'a_priori_alpha_nouvelle': 5.0, # a priori empirique des nouvelles courses
    'course_max': 200,              # troncature de la longueur de course
    'min_observations': 6,          # pas d'alerte BOCPD avant 6 séances
    'fenetre_seances': 10,          # fenêtre de la P(rupture), en séances
    'silence_semaines': 2,          # pas de nouvelle alerte de même cause
    'residu_secours': 0.05,
    'residu_secours_semaines': 2,
    'assiduite_secours': 0.7,
    'assiduite_secours_semaines': 2,
    'douleur_secours': 2,
    'elargissement_rien_de_special': 4.0,
    'semaine_allegee_series': 0.6,
    'semaine_allegee_rir': 2.0,
    'journal_dossier': 60,          # événements du journal dans le dossier
    'douleur_recente_j': 7,         # une douleur compte si signalée depuis 7 jours au plus
    'residu_reps_reference': 8.0,   # répétitions de référence de la conversion réserve -> e1RM
}

CAUSES = ('rupture', 'residu', 'assiduite', 'douleur')
REPONSES = ('douleur', 'moins_de_temps', 'fatigue', 'rien')
VERSION_DOSSIER = 1


def _param(params, cle):
    return (params.get('rupture') or {}).get(cle, DEFAUTS_RUPTURE[cle])


# ----------------------------------------------------------------------
# Fonction gamma
# ----------------------------------------------------------------------
LANCZOS_G = 7.0
LANCZOS_C = (0.99999999999980993, 676.5203681218851, -1259.1392167224028,
             771.32342877765313, -176.61502916214059, 12.507343278686905,
             -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7)


def lgamma(x):
    """ln Γ(x) pour x > 0 (approximation de Lanczos, g = 7, 9 coefficients ;
    erreur absolue < 1e-13 sur (0, 1e6]). Pour x < 0,5, formule des
    compléments : Γ(x) Γ(1-x) = π / sin(πx)."""
    if x <= 0.0:
        raise ValueError('lgamma : argument positif attendu')
    if x < 0.5:
        return LOG_PI - math.log(math.sin(math.pi * x)) - lgamma(1.0 - x)
    z = x - 1.0
    a = LANCZOS_C[0]
    for i in range(1, 9):
        a += LANCZOS_C[i] / (z + i)
    t = z + LANCZOS_G + 0.5
    return 0.5 * LOG_2PI + (z + 0.5) * math.log(t) - t + math.log(a)


# ----------------------------------------------------------------------
# BOCPD
# ----------------------------------------------------------------------
class Bocpd(object):
    """Détection de rupture en ligne, modèle gaussien à moyenne et variance
    inconnues, a priori normal-gamma (μ0, κ0, α0, β0), prédictive de Student,
    hasard constant H.

    Convention : après l'observation x_t, la longueur de course r (r >= 1)
    compte les observations du régime courant, x_t comprise. r = 1 : une
    rupture vient d'avoir lieu juste avant x_t. Les longueurs sont tronquées
    à `course_max` : la case `course_max` absorbe les courses plus longues
    (elle garde les statistiques de la plus ancienne, approximation sans
    effet tant que les courses longues portent toute la masse).

    P(rupture) rendue par `ajouter` : masse a posteriori des courses de
    longueur r <= fenetre (rupture dans les `fenetre` dernières
    observations, soit r < fenetre dans l'indexation d'Adams & MacKay qui
    compte les observations avant x_t), EN EXCLUANT la course initiale
    (r = n, observations vues depuis la remise à zéro) : au démarrage, toutes
    les courses sont courtes et la course initiale n'est pas une rupture.
    En plus, rien n'est rendu (0) tant que n < min_observations : le régime
    de référence n'est pas encore appris, une « rupture » contre lui n'a pas
    de sens.

    A priori des nouvelles courses (empirique) : une fois `min_observations`
    vues, une course qui commence prend pour a priori de sa variance une
    gamma de forme `alpha_nouvelle` centrée sur la variance apprise par la
    course la plus probable (β = (α - 1) × E[σ²]). Les résidus normalisés
    moyens de séance n'ont pas une variance unité (moyennes de séries
    corrélées) : sans ce calage, un a priori de variance 1 rendrait la
    détection insensible quand la vraie dispersion est 0,4 et trop sensible
    quand elle vaut 2,5. La moyenne a priori (μ0, κ0) est en unités de σ,
    donc l'ensemble devient invariant d'échelle. La course initiale garde
    l'a priori faible (α0, β0)."""

    def __init__(self, hasard=0.02, fenetre=10, min_observations=6, course_max=200,
                 mu0=0.0, kappa0=0.25, alpha0=2.0, beta0=1.0, alpha_nouvelle=5.0):
        self.hasard = float(hasard)
        self.fenetre = int(fenetre)
        self.min_observations = int(min_observations)
        self.course_max = int(course_max)
        self.mu0 = float(mu0)
        self.kappa0 = float(kappa0)
        self.alpha0 = float(alpha0)
        self.beta0 = float(beta0)
        self.alpha_nouvelle = float(alpha_nouvelle)
        self.reinitialiser()

    @staticmethod
    def depuis_params(params):
        sd = _param(params, 'a_priori_moyenne_sd')
        # La fenêtre vient de `fenetre_seances` (10) et non de `fenetre` (3) :
        # avec 3 observations, la fenêtre se referme avant que l'évidence
        # d'un saut de 2 écarts-types ne s'accumule (détection en moins de 6
        # séances dans ~54 % des cas au lieu de ~88 %, voir LIVRAISON).
        return Bocpd(hasard=_param(params, 'hasard'), fenetre=_param(params, 'fenetre_seances'),
                     min_observations=_param(params, 'min_observations'),
                     course_max=_param(params, 'course_max'),
                     mu0=0.0, kappa0=1.0 / (sd * sd),
                     alpha0=_param(params, 'a_priori_alpha'), beta0=_param(params, 'a_priori_beta'),
                     alpha_nouvelle=_param(params, 'a_priori_alpha_nouvelle'))

    def reinitialiser(self):
        # Avant toute observation : une seule course, vide (r = 0), à l'a priori.
        self.n = 0
        self.longueurs = [0]
        self.log_p = [0.0]
        self.mu = [self.mu0]
        self.kappa = [self.kappa0]
        self.alpha = [self.alpha0]
        self.beta = [self.beta0]
        self.p_rupture = 0.0

    @staticmethod
    def log_student(x, mu, kappa, alpha, beta):
        """Log-densité prédictive : Student à 2α degrés de liberté, centre μ,
        échelle² β(κ+1)/(ακ)."""
        nu = 2.0 * alpha
        s2 = beta * (kappa + 1.0) / (alpha * kappa)
        d = x - mu
        return (lgamma(alpha + 0.5) - lgamma(alpha) - 0.5 * (math.log(nu * s2) + LOG_PI)
                - (alpha + 0.5) * math.log(1.0 + d * d / (nu * s2)))

    def ajouter(self, x):
        """Verse une observation, renvoie P(rupture dans les `fenetre`
        dernières observations) (0 avant `min_observations`)."""
        x = float(x)
        h = self.hasard
        log_h = math.log(h)
        log_1h = math.log(1.0 - h)
        k = len(self.longueurs)
        # Prédictive de chaque course.
        lpred = [0.0] * k
        for i in range(k):
            lpred[i] = self.log_student(x, self.mu[i], self.kappa[i], self.alpha[i], self.beta[i])
        # Rupture juste avant x : nouvelle course de longueur 1, prédictive a
        # priori ; masse H × Σ p(r) = H (les p(r) somment à 1).
        a0, b0 = self._a_priori_variance()
        lp0 = self.log_student(x, self.mu0, self.kappa0, a0, b0)
        n_long = []
        n_lp = []
        n_mu = []
        n_ka = []
        n_al = []
        n_be = []
        # Croissance : r -> r + 1, masse (1 - H) p(r) pred(r).
        for i in range(k):
            r = self.longueurs[i]
            lw = self.log_p[i] + lpred[i] + log_1h
            if r == 0:
                # Course vide de départ : elle devient la course initiale,
                # confondue avec la course « rupture avant x_1 ».
                lw = self.log_p[i] + lpred[i]
            mu, ka, al, be = self.mu[i], self.kappa[i], self.alpha[i], self.beta[i]
            d = x - mu
            mu2 = (ka * mu + x) / (ka + 1.0)
            be2 = be + ka * d * d / (2.0 * (ka + 1.0))
            r2 = r + 1
            if r2 > self.course_max:
                r2 = self.course_max
            if n_long and n_long[-1] == r2:
                # Case absorbante : on additionne les masses, on garde les
                # statistiques de la course la plus ancienne (celle-ci).
                a = n_lp[-1]
                mx = a if a > lw else lw
                n_lp[-1] = mx + math.log(math.exp(a - mx) + math.exp(lw - mx))
                n_mu[-1] = mu2
                n_ka[-1] = ka + 1.0
                n_al[-1] = al + 0.5
                n_be[-1] = be2
            else:
                n_long.append(r2)
                n_lp.append(lw)
                n_mu.append(mu2)
                n_ka.append(ka + 1.0)
                n_al.append(al + 0.5)
                n_be.append(be2)
        if self.n > 0:
            # Nouvelle course de longueur 1 (en tête : les longueurs restent
            # croissantes).
            d = x - self.mu0
            n_long.insert(0, 1)
            n_lp.insert(0, log_h + lp0)
            n_mu.insert(0, (self.kappa0 * self.mu0 + x) / (self.kappa0 + 1.0))
            n_ka.insert(0, self.kappa0 + 1.0)
            n_al.insert(0, a0 + 0.5)
            n_be.insert(0, b0 + self.kappa0 * d * d / (2.0 * (self.kappa0 + 1.0)))
        # Renormalisation (log-somme-exp).
        mx = n_lp[0]
        for i in range(1, len(n_lp)):
            if n_lp[i] > mx:
                mx = n_lp[i]
        tot = 0.0
        for i in range(len(n_lp)):
            tot += math.exp(n_lp[i] - mx)
        lz = mx + math.log(tot)
        for i in range(len(n_lp)):
            n_lp[i] -= lz
        self.longueurs = n_long
        self.log_p = n_lp
        self.mu = n_mu
        self.kappa = n_ka
        self.alpha = n_al
        self.beta = n_be
        self.n += 1
        self.p_rupture = self._p_fenetre()
        return self.p_rupture

    def _a_priori_variance(self):
        """(α, β) de l'a priori de variance d'une course qui commence."""
        if self.n < self.min_observations:
            return self.alpha0, self.beta0
        j = 0
        for i in range(1, len(self.log_p)):
            if self.log_p[i] > self.log_p[j]:
                j = i
        al = self.alpha[j]
        s2 = self.beta[j] / (al - 1.0) if al > 1.0 else self.beta[j] / al
        a = self.alpha_nouvelle
        b = (a - 1.0) * s2 if a > 1.0 else a * s2
        return a, b

    def _p_fenetre(self):
        if self.n < self.min_observations:
            return 0.0
        p = 0.0
        for i in range(len(self.longueurs)):
            r = self.longueurs[i]
            if r <= self.fenetre and r != self.n:
                p += math.exp(self.log_p[i])
        if p > 1.0:
            p = 1.0
        return p

    def distribution(self):
        """[(longueur, probabilité)] de la longueur de course."""
        return [(self.longueurs[i], math.exp(self.log_p[i])) for i in range(len(self.longueurs))]

    def etat(self):
        return {
            'config': [self.hasard, float(self.fenetre), float(self.min_observations),
                       float(self.course_max), self.mu0, self.kappa0, self.alpha0, self.beta0,
                       self.alpha_nouvelle],
            'n': float(self.n),
            'p_rupture': self.p_rupture,
            'longueurs': [float(r) for r in self.longueurs],
            'log_p': list(self.log_p),
            'mu': list(self.mu), 'kappa': list(self.kappa),
            'alpha': list(self.alpha), 'beta': list(self.beta),
        }

    @staticmethod
    def depuis_etat(etat):
        c = etat['config']
        b = Bocpd(hasard=c[0], fenetre=int(c[1]), min_observations=int(c[2]),
                  course_max=int(c[3]), mu0=c[4], kappa0=c[5], alpha0=c[6], beta0=c[7],
                  alpha_nouvelle=c[8])
        b.n = int(etat['n'])
        b.p_rupture = float(etat['p_rupture'])
        b.longueurs = [int(r) for r in etat['longueurs']]
        b.log_p = [float(v) for v in etat['log_p']]
        b.mu = [float(v) for v in etat['mu']]
        b.kappa = [float(v) for v in etat['kappa']]
        b.alpha = [float(v) for v in etat['alpha']]
        b.beta = [float(v) for v in etat['beta']]
        return b


# ----------------------------------------------------------------------
# Diagnostic : questions (3 au plus sur tout parcours)
# ----------------------------------------------------------------------
LIBELLES_ZONES = (('neck', 'Cou'), ('shoulder', 'Épaule'), ('elbow', 'Coude'),
                  ('wrist_hand', 'Poignet, main'), ('upper_back', 'Haut du dos'),
                  ('lower_back', 'Bas du dos'), ('chest', 'Poitrine'), ('abdomen', 'Abdomen'),
                  ('hip', 'Hanche'), ('thigh', 'Cuisse'), ('knee', 'Genou'),
                  ('lower_leg', 'Jambe'), ('ankle_foot', 'Cheville, pied'))

QUESTION_CAUSE = {
    'code': 'cause',
    'texte': "Qu'est-ce qui a changé ces derniers temps ?",
    'choix': [{'code': 'douleur', 'texte': 'Une douleur'},
              {'code': 'moins_de_temps', 'texte': 'Moins de temps'},
              {'code': 'fatigue', 'texte': 'Fatigue ou vie chargée'},
              {'code': 'rien', 'texte': 'Rien de spécial'}],
}
QUESTION_ZONE = {
    'code': 'zone', 'texte': 'Où as-tu mal ?',
    'choix': [{'code': c, 'texte': t} for (c, t) in LIBELLES_ZONES],
}
QUESTION_INTENSITE = {
    'code': 'intensite', 'texte': 'Quelle intensité, de 0 à 10 ?',
    'choix': [{'code': i, 'texte': str(i)} for i in range(11)],
}
QUESTION_SEANCES = {
    'code': 'seances_par_semaine', 'texte': 'Combien de séances par semaine peux-tu faire ?',
    'choix': [{'code': i, 'texte': str(i)} for i in range(1, 8)],
}
QUESTION_DUREE = {
    'code': 'duree_max_min', 'texte': 'Combien de temps par séance ?',
    'choix': [{'code': d, 'texte': '%d min' % d} for d in (20, 30, 45, 60, 75, 90)],
}


def _copie(q):
    return json.loads(json.dumps(q))


# ----------------------------------------------------------------------
# Surveillance : extension du moteur
# ----------------------------------------------------------------------
class Surveillance(Extension):
    """Hors modèle (cahier § 9) : BOCPD sur les résidus normalisés moyens de
    séance, seuils de secours, diagnostic et actions codées, dossier.

    Une cause déclenchée reste levée (« situation hors de mon modèle ») tant
    que l'utilisateur n'a pas répondu au diagnostic. Après une réponse,
    chaque cause levée est mise en silence `silence_semaines` semaines."""

    SEMAINES_GARDEES = 12
    REPONSES_GARDEES = 10

    def __init__(self, params):
        self.appliquer_parametres(params)
        self.bocpd = Bocpd.depuis_params(params)
        self.semaine = 0
        self.faites = 0
        self.manquees = 0
        self.somme_rel = 0.0
        self.n_rel = 0
        self.semaines = []     # [semaine, résidu relatif |moyen| ou None, faites, prévues]
        self.alertes = [False, False, False, False]   # par cause, ordre CAUSES
        self.silence = [-1, -1, -1, -1]               # semaine de fin de silence
        self.p = 0.0
        self.douleur_zones = []                       # zones > seuil (triées)
        self.reponses = []
        # Semaine allégée en cours : [jour de début, jour de fin (exclu),
        # facteur des séries, RIR ajouté] ou None.
        self.allegement = None

    def appliquer_parametres(self, params):
        self.params = params
        self.alerte = float(_param(params, 'alerte'))
        self.residu_secours = float(_param(params, 'residu_secours'))
        self.residu_semaines = int(_param(params, 'residu_secours_semaines'))
        self.assiduite_secours = float(_param(params, 'assiduite_secours'))
        self.assiduite_semaines = int(_param(params, 'assiduite_secours_semaines'))
        self.douleur_secours = float(_param(params, 'douleur_secours'))
        self.silence_semaines = int(_param(params, 'silence_semaines'))
        self.douleur_recente_j = int(_param(params, 'douleur_recente_j'))
        self.residu_reps = float(_param(params, 'residu_reps_reference'))

    # ------------------------------------------------------------------
    # Événements
    # ------------------------------------------------------------------
    def fin_seance(self, koach, resume, e):
        self.faites += 1
        if resume is not None:
            self.p = self.bocpd.ajouter(resume[1])
            if len(resume) > 5:
                # Résidu d'e1RM de la séance calculé par le modèle : écart
                # (ln) entre la capacité du jour après la séance et la
                # capacité du jour prévue avant, mouvements chargés suivis.
                r = resume[5] if resume[5] is not None else False
            else:
                r = self._residu_e1rm(koach, resume[0])
            if r is None:
                # Aucune série de la séance n'a laissé de résidu dans le
                # modèle (moteur de test, résumé fourni par l'appelant) : le
                # résidu relatif du résumé est pris tel quel.
                r = float(resume[2])
            if r is not False:
                self.somme_rel += r
                self.n_rel += 1
        self.verifier(koach)

    def _residu_e1rm(self, koach, jour):
        """Résidu relatif d'e1RM de la séance du jour [jour] (seuil de secours
        « résidu d'e1RM > 5 % ») : moyenne, sur les séries de force du jour
        (pistes de type charge ou répétitions), du résidu de réserve
        (observé − prédit, en répétitions) converti en ln capacité :
        charge : × g'(R) de la courbe de l'exercice à R = residu_reps_reference
        (pente −ln(part du 1RM) par répétition) ; répétitions au poids du
        corps : × 1 / Rmax estimé. Les tenues et l'endurance n'ont pas d'e1RM.
        Renvoie None si aucune piste n'a de résidu ce jour-là, False si la
        séance n'a que des tenues ou de l'endurance.

        (Le résidu relatif du résumé de séance, `resume[2]`, est en
        répétitions de réserve, pas en part d'e1RM : le comparer à 5 % levait
        l'alerte de secours presque chaque semaine sur le banc.)"""
        m = getattr(koach, 'modele', None)
        if m is None or not hasattr(m, 'ordre'):
            return None
        vu = False
        somme = 0.0
        n = 0
        for ex in m.ordre:
            t = m.pistes.get(ex)
            if t is None or not t.residus:
                continue
            k = len(t.residus) - 1
            while k >= 0 and t.residus[k][0] == jour:
                vu = True
                rel = float(t.residus[k][2])
                if t.type == 'charge':
                    lam, ku = m.courbe(t)
                    somme += rel * m._dg(lam, ku, self.residu_reps)
                    n += 1
                elif t.type == 'reps':
                    c = m.capacite(ex)
                    somme += rel / math.exp(c[0])
                    n += 1
                k -= 1
        if not vu:
            return None
        if n == 0:
            return False
        return somme / n

    def seance_manquee(self, koach, e):
        self.manquees += 1
        self.verifier(koach)

    def fin_semaine(self, koach, ligne, e):
        residu = None
        if self.n_rel > 0:
            residu = abs(self.somme_rel / self.n_rel)
        self.semaines.append([self.semaine, residu, self.faites, self.faites + self.manquees])
        if len(self.semaines) > self.SEMAINES_GARDEES:
            self.semaines = self.semaines[len(self.semaines) - self.SEMAINES_GARDEES:]
        self.semaine += 1
        self.faites = 0
        self.manquees = 0
        self.somme_rel = 0.0
        self.n_rel = 0
        self.verifier(koach)

    def decision(self, koach, e):
        """Les réponses au diagnostic passent par le journal (événement
        `decision` portant `diagnostic`), pour que l'état se recalcule depuis
        le journal. Une réponse reçue sans alerte levée est ignorée."""
        diag = e.get('diagnostic')
        if diag is not None and self.etat()['hors_modele']:
            self.repondre(koach, diag)
        self.verifier(koach)

    # ------------------------------------------------------------------
    # Causes
    # ------------------------------------------------------------------
    def _residu_actif(self):
        n = self.residu_semaines
        if n < 1 or len(self.semaines) < n:
            return False
        for i in range(len(self.semaines) - n, len(self.semaines)):
            r = self.semaines[i][1]
            if r is None or not (r > self.residu_secours):
                return False
        return True

    def _assiduite_active(self):
        n = self.assiduite_semaines
        if n < 1 or len(self.semaines) < n:
            return False
        faites = 0
        prevues = 0
        for i in range(len(self.semaines) - n, len(self.semaines)):
            faites += self.semaines[i][2]
            prevues += self.semaines[i][3]
        if prevues <= 0:
            return False
        return faites < self.assiduite_secours * prevues

    def _douleur(self, koach):
        """Zones dont le DERNIER signalement dépasse le seuil et date de
        `douleur_recente_j` jours au plus (triées). Sans la condition de
        date, un signalement ancien jamais remis à 0 (la séance ne pose pas
        la question quand rien n'est signalé) relevait l'alerte à chaque fin
        de silence."""
        zones = []
        jour = getattr(koach, 'jour', 0)
        for z in sorted(koach.garde.zones.keys()):
            dern = koach.garde.zones[z].derniere()
            if (dern is not None and dern[1] > self.douleur_secours
                    and jour - dern[0] <= self.douleur_recente_j):
                zones.append(z)
        return zones

    def verifier(self, koach):
        """Recalcule les causes et lève celles qui ne sont pas en silence.
        Quand une alerte se lève (aucune cause levée avant, au moins une
        après), les extensions qui exposent `sur_alerte_hors_modele` sont
        prévenues (contrôle dual : l'essai N-of-1 en cours est interrompu)."""
        avant = self.etat()['hors_modele']
        self.douleur_zones = self._douleur(koach)
        actives = [self.p > self.alerte, self._residu_actif(), self._assiduite_active(),
                   len(self.douleur_zones) > 0]
        for c in range(4):
            if actives[c] and self.semaine >= self.silence[c]:
                self.alertes[c] = True
        if not avant and self.etat()['hors_modele']:
            causes = self.causes()
            for x in getattr(koach, 'extensions', []):
                f = getattr(x, 'sur_alerte_hors_modele', None)
                if f is not None and x is not self:
                    f(koach, causes)

    def appliquer_allegement(self, items, jour):
        """Items écrits du jour transformés par la semaine allégée en cours
        (action codée « fatigue, vie chargée ») : séries de travail ×
        `semaine_allegee_series` (arrondi, au moins 1), réserve visée +
        `semaine_allegee_rir` (2 flammes par répétition de réserve, au moins
        1 flamme). Échauffements et tests inchangés. Renvoie une nouvelle
        liste ; les items reçus ne sont pas modifiés."""
        a = self.allegement
        if a is None or not (a[0] <= jour < a[1]):
            return items
        f_series, rir = a[2], a[3]
        cran = int(math.floor(2.0 * rir + 0.5))
        out = []
        for it in items:
            if it.get('kind', 'work') != 'work' or (it.get('sets') or 0) < 1:
                out.append(it)
                continue
            it = dict(it)
            n = int(math.floor(it['sets'] * f_series + 0.5))
            it['sets'] = n if n >= 1 else 1
            f = it.get('targetFlames')
            if f is not None and f < 10:
                g = f - cran
                it['targetFlames'] = g if g >= 1 else 1
            if it.get('setTargets'):
                cibles = []
                for c in it['setTargets']:
                    c = dict(c)
                    fc = c.get('flames')
                    if fc is not None and fc < 10:
                        g = fc - cran
                        c['flames'] = g if g >= 1 else 1
                    cibles.append(c)
                it['setTargets'] = cibles
            out.append(it)
        return out

    def causes(self):
        return [CAUSES[c] for c in range(4) if self.alertes[c]]

    def etat(self):
        causes = self.causes()
        return {'hors_modele': len(causes) > 0, 'p_rupture': self.p, 'causes': causes,
                'semaine': self.semaine}

    # ------------------------------------------------------------------
    # Diagnostic
    # ------------------------------------------------------------------
    def questions(self, reponses=None):
        """Questions du diagnostic pour le parcours en cours : la première
        distingue douleur / moins de temps / fatigue / rien ; selon la
        réponse, au plus deux questions de précision. Jamais plus de 3.
        Rien si aucune alerte n'est levée."""
        if not self.etat()['hors_modele']:
            return []
        qs = [_copie(QUESTION_CAUSE)]
        cause = (reponses or {}).get('cause')
        if cause == 'douleur':
            qs.append(_copie(QUESTION_ZONE))
            qs.append(_copie(QUESTION_INTENSITE))
        elif cause == 'moins_de_temps':
            qs.append(_copie(QUESTION_SEANCES))
            qs.append(_copie(QUESTION_DUREE))
        return qs[:3]

    def repondre(self, koach, reponses):
        """Applique la réponse au diagnostic et renvoie l'action codée."""
        cause = reponses.get('cause')
        if cause not in REPONSES:
            raise ValueError('réponse inconnue : %r' % (cause,))
        p = self.params
        if cause == 'douleur':
            zone = reponses.get('zone')
            intensite = reponses.get('intensite')
            if zone is not None and intensite is not None:
                # Le signalement suit le chemin habituel des douleurs : la
                # conduite sous douleur de securite.py s'applique.
                koach.garde.noter_seance(koach.jour, [{'zone': zone, 'intensity': int(intensite)}],
                                         posee=False)
            action = {'action': 'conduite_douleur', 'renvoi_professionnel': True,
                      'zone': zone, 'intensite': intensite}
        elif cause == 'moins_de_temps':
            action = {'action': 'replanifier',
                      'disponibilites': {'seances_par_semaine': reponses.get('seances_par_semaine'),
                                         'duree_max_min': reponses.get('duree_max_min')}}
        elif cause == 'fatigue':
            action = {'action': 'semaine_allegee',
                      'series': float(_param(p, 'semaine_allegee_series')),
                      'rir': float(_param(p, 'semaine_allegee_rir'))}
            j = int(getattr(koach, 'jour', 0))
            self.allegement = [j, j + 7, action['series'], action['rir']]
        else:
            facteur = float(_param(p, 'elargissement_rien_de_special'))
            koach.modele.elargir(facteur)
            self.bocpd.reinitialiser()
            self.p = 0.0
            action = {'action': 'elargir', 'facteur': facteur}
        # Acquittement : chaque cause levée se tait `silence_semaines` semaines.
        for c in range(4):
            if self.alertes[c]:
                self.silence[c] = self.semaine + self.silence_semaines
            self.alertes[c] = False
        self.reponses.append({'semaine': self.semaine, 'jour': koach.jour, 'cause': cause,
                              'action': action['action']})
        if len(self.reponses) > self.REPONSES_GARDEES:
            self.reponses = self.reponses[len(self.reponses) - self.REPONSES_GARDEES:]
        return action

    # ------------------------------------------------------------------
    # Sérialisation
    # ------------------------------------------------------------------
    def etat_complet(self):
        return {
            'bocpd': self.bocpd.etat(), 'semaine': self.semaine, 'faites': self.faites,
            'manquees': self.manquees, 'somme_rel': self.somme_rel, 'n_rel': self.n_rel,
            'semaines': [list(s) for s in self.semaines], 'alertes': list(self.alertes),
            'silence': list(self.silence), 'p': self.p, 'douleur_zones': list(self.douleur_zones),
            'reponses': _copie(self.reponses),
            'allegement': None if self.allegement is None else list(self.allegement),
        }

    @staticmethod
    def depuis_etat(params, etat):
        s = Surveillance(params)
        s.bocpd = Bocpd.depuis_etat(etat['bocpd'])
        s.semaine = int(etat['semaine'])
        s.faites = int(etat['faites'])
        s.manquees = int(etat['manquees'])
        s.somme_rel = float(etat['somme_rel'])
        s.n_rel = int(etat['n_rel'])
        s.semaines = [[int(x[0]), None if x[1] is None else float(x[1]), int(x[2]), int(x[3])]
                      for x in etat['semaines']]
        s.alertes = [bool(a) for a in etat['alertes']]
        s.silence = [int(v) for v in etat['silence']]
        s.p = float(etat['p'])
        s.douleur_zones = list(etat['douleur_zones'])
        s.reponses = _copie(etat['reponses'])
        a = etat.get('allegement')
        s.allegement = None if a is None else [int(a[0]), int(a[1]), float(a[2]), float(a[3])]
        return s

    # ------------------------------------------------------------------
    # Dossier hors modèle (mode dev) et import de paramètres
    # ------------------------------------------------------------------
    def dossier(self, koach):
        """Dossier exportable, JSON-sérialisable, sans donnée identifiante."""
        n = int(_param(self.params, 'journal_dossier'))
        journal = koach.journal[len(koach.journal) - n:] if len(koach.journal) > n else koach.journal
        evenements = []
        for e in journal:
            if e.get('type') in TYPES_EXCLUS:
                continue
            evenements.append(_anonymiser(e))
        return _json_propre({
            'type': 'dossier_hors_modele',
            'version_dossier': VERSION_DOSSIER,
            'version_parametres': koach.params.get('version'),
            'parametres': koach.params,
            'posterior': koach.posterior(),
            'histoire_residus': [list(r) for r in koach.modele.histoire_residus],
            'bocpd': self.bocpd.etat(),
            'surveillance': self.etat_complet(),
            'causes': self.causes(),
            'journal': evenements,
        })


def importer_parametres(koach, fichier_json):
    """Valide puis applique un fichier de paramètres renvoyé après analyse
    du dossier. [fichier_json] : texte JSON ou dictionnaire. Renvoie
    {'ok': bool, 'erreurs': [...], 'version': ...} ; rien n'est appliqué si
    une erreur est trouvée."""
    erreurs = []
    if isinstance(fichier_json, str):
        try:
            nouveau = json.loads(fichier_json)
        except ValueError as exc:
            return {'ok': False, 'erreurs': ['json_invalide: %s' % exc], 'version': None}
    else:
        nouveau = copy.deepcopy(fichier_json)
    if not isinstance(nouveau, dict):
        return {'ok': False, 'erreurs': ['racine_non_objet'], 'version': None}
    actuel = koach.params
    erreurs.extend(valider_parametres(actuel, nouveau))
    if erreurs:
        return {'ok': False, 'erreurs': erreurs, 'version': nouveau.get('version')}
    # L'import est un événement du journal : `rejouer` le réapplique au
    # même endroit (état recalculable depuis le journal).
    koach.observe({'type': 'parametres', 'fichier': nouveau})
    return {'ok': True, 'erreurs': [], 'version': koach.params.get('version')}


def appliquer_parametres(koach, nouveau):
    """Applique un fichier de paramètres déjà validé (événement
    `parametres` du journal)."""
    actuel = koach.params
    fusion = copy.deepcopy(actuel)
    for cle in sorted(nouveau.keys()):
        v = nouveau[cle]
        if isinstance(v, dict):
            for k in sorted(v.keys()):
                fusion[cle][k] = copy.deepcopy(v[k])
        else:
            fusion[cle] = copy.deepcopy(v)
    # Les modules lisent leurs paramètres dans ce dictionnaire.
    koach.params = fusion
    koach.modele.p = fusion
    koach.garde.s = fusion['securite']
    koach.seances.p = fusion
    koach.seances.s = fusion['securite']
    f_ = fusion['fatigue']
    koach.modele.tau = [f_['tau_nerveux_j'], f_['tau_musculaire_j'], f_['tau_tendineux_j']]
    for x in koach.extensions:
        f = getattr(x, 'appliquer_parametres', None)
        if f is not None:
            f(fusion)
        elif hasattr(x, 'p') and isinstance(getattr(x, 'cle_params', None), str):
            x.p = fusion[x.cle_params]


# Garde-fous qu'un import ne peut pas changer (cahier : la sécurité n'est
# jamais assouplie ; plafonds du § 6, amplitudes des essais, conditions des
# tests, seuil de douleur du secours), en plus de toute la section `securite`.
FIGEES = (
    ('planification', 'plafond_volume'), ('planification', 'plafond_intensite'),
    ('controle_dual', 'amplitude_volume'), ('controle_dual', 'amplitude_intensite'),
    ('controle_dual', 'plafond_volume'), ('controle_dual', 'plafond_intensite'),
    ('controle_dual', 'semaines_min'), ('controle_dual', 'intervalle_max'),
    ('controle_dual', 'synthetique_semaines_min'), ('controle_dual', 'bras_semaines'),
    ('test_adaptatif', 'intervalle_declenchement'), ('test_adaptatif', 'jours_min_entre_tests'),
    ('rupture', 'douleur_secours'),
)

# Bornes simples : (section, clé) -> (min, max) inclus.
BORNES = {
    ('jour', 'mauvais_jour_proba'): (1e-6, 0.999),
    ('jour', 'mauvais_jour_proba_bilan_bas'): (1e-6, 0.999),
    ('mesure', 'note_aberrante'): (1e-6, 0.5),
    ('mesure', 'porte_note_ouverte'): (0.0, 100.0),
    ('dynamique', 'recuperation_seuil'): (1e-6, 1e6),
    ('rupture', 'hasard'): (1e-6, 0.5),
    ('rupture', 'alerte'): (0.05, 0.999),
    ('rupture', 'residu_secours'): (0.0, 1.0),
    ('rupture', 'assiduite_secours'): (0.0, 1.0),
    ('rupture', 'douleur_secours'): (0.0, 10.0),
    ('rupture', 'elargissement_rien_de_special'): (1.0, 100.0),
    ('rupture', 'semaine_allegee_series'): (0.1, 1.0),
    ('rupture', 'semaine_allegee_rir'): (0.0, 5.0),
    ('rupture', 'course_max'): (10, 1000),
    ('rupture', 'fenetre_seances'): (1, 100),
    ('rupture', 'min_observations'): (1, 100),
    ('rupture', 'a_priori_alpha'): (0.5, 1000.0),
    ('rupture', 'a_priori_beta'): (1e-6, 1000.0),
    ('rupture', 'a_priori_alpha_nouvelle'): (0.5, 1000.0),
    ('rupture', 'douleur_recente_j'): (0, 60),
    ('rupture', 'residu_reps_reference'): (1.0, 30.0),
    ('adherence', 'proba_cible'): (0.05, 0.99),
    ('adherence', 'a_priori_poids_sd'): (1e-3, 100.0),
    ('adherence', 'biais_initial'): (-5.0, 5.0),
    ('adherence', 'pas_min'): (1e-6, 1e6),
    ('adherence', 'paliers_max'): (1, 20),
}


def _nombre(v):
    return (isinstance(v, (int, float)) and not isinstance(v, bool))


def _verifier_valeur(chemin, ancien, v, erreurs):
    if _nombre(ancien):
        if not _nombre(v):
            erreurs.append('type: %s' % chemin)
        elif v != v or v in (math.inf, -math.inf):
            erreurs.append('non_fini: %s' % chemin)
    elif isinstance(ancien, bool):
        if not isinstance(v, bool):
            erreurs.append('type: %s' % chemin)
    elif isinstance(ancien, str):
        if not isinstance(v, str):
            erreurs.append('type: %s' % chemin)
    elif isinstance(ancien, list):
        if not isinstance(v, list) or len(v) != len(ancien):
            erreurs.append('liste: %s' % chemin)
        else:
            for i in range(len(v)):
                _verifier_valeur('%s[%d]' % (chemin, i), ancien[i], v[i], erreurs)
    elif isinstance(ancien, dict):
        if not isinstance(v, dict):
            erreurs.append('type: %s' % chemin)
        else:
            for k in sorted(v.keys()):
                if k not in ancien:
                    erreurs.append('cle_inconnue: %s.%s' % (chemin, k))
                else:
                    _verifier_valeur('%s.%s' % (chemin, k), ancien[k], v[k], erreurs)


def valider_parametres(actuel, nouveau):
    """Schéma, version, types, bornes simples ; la section `securite` ne
    peut pas changer (la sécurité n'est jamais assouplie par un import)."""
    from .adherence import DEFAUTS_ADHERENCE
    erreurs = []
    if nouveau.get('schema') != actuel.get('schema'):
        erreurs.append('schema: attendu %r' % (actuel.get('schema'),))
    version = nouveau.get('version')
    va = str(actuel.get('version', ''))
    if not isinstance(version, str) or version.split('.')[0] != va.split('.')[0]:
        erreurs.append('version: majeure attendue %r' % (va.split('.')[0],))
    defauts = {'rupture': DEFAUTS_RUPTURE, 'adherence': DEFAUTS_ADHERENCE}
    for cle in sorted(nouveau.keys()):
        v = nouveau[cle]
        if cle in ('schema', 'version', 'date', 'note'):
            if cle in ('date', 'note') and not isinstance(v, str):
                erreurs.append('type: %s' % cle)
            continue
        if cle not in actuel:
            erreurs.append('section_inconnue: %s' % cle)
            continue
        if cle == 'securite':
            if v != actuel['securite']:
                erreurs.append('securite: modification interdite')
            continue
        ancien = actuel[cle]
        if isinstance(ancien, dict) and isinstance(v, dict) and cle in defauts:
            # Les clés nouvelles connues des modules sont admises.
            for k in sorted(v.keys()):
                ref = ancien[k] if k in ancien else defauts[cle].get(k)
                if ref is None and k not in ancien:
                    erreurs.append('cle_inconnue: %s.%s' % (cle, k))
                else:
                    _verifier_valeur('%s.%s' % (cle, k), ref, v[k], erreurs)
        else:
            _verifier_valeur(cle, ancien, v, erreurs)
    for (sec, k) in FIGEES:
        sv = nouveau.get(sec)
        if isinstance(sv, dict) and k in sv and isinstance(actuel.get(sec), dict) \
                and k in actuel[sec] and sv[k] != actuel[sec][k]:
            erreurs.append('fige: %s.%s (garde-fou, modification interdite)' % (sec, k))
    if not erreurs:
        for (sec, k) in sorted(BORNES.keys()):
            sv = nouveau.get(sec)
            if isinstance(sv, dict) and k in sv:
                lo, hi = BORNES[(sec, k)]
                if not (lo <= sv[k] <= hi):
                    erreurs.append('borne: %s.%s hors de [%s, %s]' % (sec, k, lo, hi))
        for sec in sorted(nouveau.keys()):
            sv = nouveau[sec]
            if not isinstance(sv, dict):
                continue
            for k in sorted(sv.keys()):
                x = sv[k]
                if _nombre(x) and (k.endswith('_sd') or k.startswith('sigma') or k.startswith('tau')
                                   or k.startswith('bruit')) and not (x > 0):
                    erreurs.append('borne: %s.%s doit être > 0' % (sec, k))
    return erreurs


# ----------------------------------------------------------------------
# Anonymisation et nettoyage JSON
# ----------------------------------------------------------------------
TYPES_EXCLUS = ('profil',)
CLES_INTERDITES = ('nom', 'name', 'prenom', 'firstName', 'lastName', 'email', 'mail',
                   'telephone', 'phone', 'adresse', 'address', 'note', 'notes', 'commentaire',
                   'comment', 'texte', 'text', 'userId', 'user_id', 'user', 'utilisateur', 'uid',
                   'deviceId', 'appareil', 'device', 'date', 'dateIso', 'timestamp', 'horodatage',
                   'naissance', 'birthDate', 'age', 'sexe', 'sex', 'profil', 'profile', 'photo',
                   'localisation', 'location', 'gps', 'id_utilisateur', 'createdAt', 'updatedAt')
CARACTERES_CODE = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-'


def _est_code(s):
    """Chaîne courte faite de caractères de code (pas de texte libre, pas
    de date ISO)."""
    if len(s) == 0 or len(s) > 64:
        return False
    for ch in s:
        if ch not in CARACTERES_CODE:
            return False
    if len(s) >= 10 and s[0:4].isdigit() and s[4] == '-' and s[5:7].isdigit() and s[7] == '-':
        return False
    return True


def _anonymiser(v):
    if isinstance(v, dict):
        out = {}
        for k in sorted(v.keys()):
            if not isinstance(k, str) or k in CLES_INTERDITES:
                continue
            x = _anonymiser(v[k])
            if x is not _RETIRE:
                out[k] = x
        return out
    if isinstance(v, (list, tuple)):
        out = []
        for x in v:
            y = _anonymiser(x)
            if y is not _RETIRE:
                out.append(y)
        return out
    if isinstance(v, str):
        return v if _est_code(v) else _RETIRE
    return v


class _Retire(object):
    pass


_RETIRE = _Retire()


def _json_propre(v):
    """Convertit en types JSON purs : flottants non finis -> None, tuples ->
    listes, clés -> chaînes, scalaires numpy -> float."""
    if v is None or isinstance(v, bool) or isinstance(v, str):
        return v
    if isinstance(v, int):
        return v
    if isinstance(v, float):
        return v if (v == v and v not in (math.inf, -math.inf)) else None
    if isinstance(v, dict):
        out = {}
        for k in v.keys():
            out[str(k)] = _json_propre(v[k])
        return out
    if isinstance(v, (list, tuple)):
        return [_json_propre(x) for x in v]
    try:
        return _json_propre(float(v))
    except (TypeError, ValueError):
        return str(v)


# ----------------------------------------------------------------------
# Calibrage du seuil d'alerte (banc)
# ----------------------------------------------------------------------
def _mediane(xs):
    ys = sorted(xs)
    n = len(ys)
    if n == 0:
        return None
    if n % 2 == 1:
        m = ys[n // 2]
    else:
        m = 0.5 * (ys[n // 2 - 1] + ys[n // 2])
    return None if m == math.inf else m


def calibrer_alerte(series_stables, series_avec_rupture, seuils, params=None, bocpd=None):
    """Pour chaque seuil : fausses alertes par 100 séances sur les séries
    stables (une alerte = un passage de P sous le seuil à P au-dessus) et
    délai médian de détection en séances sur les séries avec rupture
    (1 = détectée sur la première observation après la rupture ; une série
    non détectée compte comme un délai infini ; None si la médiane est
    infinie).

    [series_avec_rupture] : liste de (valeurs, indice de la première valeur
    du nouveau régime) ou de {'valeurs': ..., 'rupture': ...}.
    [bocpd] : fabrique sans argument (défaut : Bocpd.depuis_params(params)
    ou Bocpd())."""
    if bocpd is None:
        if params is not None:
            def bocpd():
                return Bocpd.depuis_params(params)
        else:
            bocpd = Bocpd
    traces_stables = []
    for s in series_stables:
        b = bocpd()
        traces_stables.append([b.ajouter(x) for x in s])
    traces_rupture = []
    for item in series_avec_rupture:
        if isinstance(item, dict):
            valeurs, k = item['valeurs'], int(item['rupture'])
        else:
            valeurs, k = item[0], int(item[1])
        b = bocpd()
        traces_rupture.append(([b.ajouter(x) for x in valeurs], k))
    total = 0
    for tr in traces_stables:
        total += len(tr)
    sortie = []
    for seuil in seuils:
        alertes = 0
        for tr in traces_stables:
            avant = False
            for p in tr:
                haut = p > seuil
                if haut and not avant:
                    alertes += 1
                avant = haut
        delais = []
        detectees = 0
        for tr, k in traces_rupture:
            d = math.inf
            for t in range(k, len(tr)):
                if tr[t] > seuil:
                    d = t - k + 1
                    break
            if d != math.inf:
                detectees += 1
            delais.append(d)
        sortie.append({
            'seuil': seuil,
            'fausses_alertes_100': 100.0 * alertes / total if total > 0 else None,
            'delai_median': _mediane(delais),
            'taux_detection': detectees / len(traces_rupture) if traces_rupture else None,
        })
    return sortie
