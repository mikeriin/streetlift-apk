# -*- coding: utf-8 -*-
"""Koach 1.0 — apprentissage actif (cahier KM § 7).

« Contrôle dual par Thompson sampling sur les paramètres de réponse.
Déclenché seulement si le modèle est calibré : 8 semaines de journal au
moins et intervalle à 90 % de l'e1RM sous 6 % sur les lifts principaux.
Essais N-of-1 par bras de 3 semaines. Contrôle synthétique construit sur au
moins 6 semaines avant l'intervention. Toujours à l'intérieur des plafonds
de l'optimisation bornée. »

Pièces :

* `Reponse` : a posteriori discret sur les hypothèses de réponse h = (s0,
  type de stimulus) de `Modele.hypotheses`, mis à jour par vraisemblance
  gaussienne des progrès hebdomadaires ; `tirer` fait le tirage de Thompson
  (Thompson 1933 ; Russo et al. 2018) : la planification optimise ensuite
  le plan sous l'hypothèse tirée, ce qui mêle exploitation et exploration
  (contrôle dual, Feldbaum 1960) ;
* `calibre` : condition de déclenchement ;
* `EssaiN1` : essai N-of-1 A/B par bras de 3 semaines, séquence
  contre-balancée ABBA/BAAB (Lillie et al. 2011 ; Duan et al. 2013),
  analyse appariée par paire de bras, a posteriori normal ;
* `controle_synthetique` : contrôle synthétique (Abadie et al. 2010), poids
  sur le simplexe par gradient projeté accéléré (FISTA, nombre d'itérations
  fixe) ; `effet_essai` en tire les progrès témoins des bras ;
* `ControleDual` : extension du moteur qui orchestre le tout.

Tout est écrit avec des boucles de longueur fixe, des opérations
élémentaires et des clés de dictionnaire triées (portage ligne pour ligne
en Dart, parité à 1e-9). Le seul aléa est `numerique.Mulberry32`, seedé par
une graine passée en paramètre.
"""
import math

from .moteur import Extension
from .modele import RHO, EPS   # indices de l'état : toujours importés par nom
from .numerique import Mulberry32, fnv1a32, norm_cdf

Z90 = 1.6448536269514722   # quantile 95 % de la loi normale (intervalle à 90 %)

# Valeurs par défaut des paramètres `controle_dual` (lus par .get(clé, défaut)).
DEFAUTS_DUAL = {
    'semaines_min': 8,
    'intervalle_max': 0.06,
    'bras_semaines': 3,
    'synthetique_semaines_min': 6,
    'synthetique_iterations': 200,
    'amplitude_volume': 0.10,
    'amplitude_intensite': 0.03,
    # Clés nouvelles (absentes de koach_params_v1.json) :
    'sigma_progres': 0.01,          # bruit (écart-type) du progrès hebdomadaire observé de ln capacité
    'plancher_poids': 1e-6,         # aucune hypothèse de réponse n'est jamais éteinte
    'a_priori_effet_sd': 0.005,     # a priori N(0, 0,005²) sur l'effet B − A par semaine
    'marge_echeance_semaines': 6,   # pas d'essai qui finirait à moins de 6 semaines d'une échéance
    'seuil_decision': 0.8,          # décision si P(B > A) ≥ 0,8 ou ≤ 0,2
    'n_bras': 4,                    # ABBA ou BAAB : deux paires de bras (12 semaines)
    'sigma_innovation': 0.003,      # plancher (écart-type) de l'innovation hebdomadaire de ln capacité
    'semaines_gardees': 26,         # semaines de capacité a posteriori gardées pour le synthétique
}
DEFAUTS_PLAFONDS = {'plafond_volume': 0.15, 'plafond_intensite': 0.05}
LETTRES = ('A', 'B')


def _param(params, cle):
    return (params.get('controle_dual') or {}).get(cle, DEFAUTS_DUAL[cle])


def _plafond(params, cle):
    return (params.get('planification') or {}).get(cle, DEFAUTS_PLAFONDS[cle])


def facteur_borne(facteur_plan, facteur_essai, plafond):
    """Facteur final par rapport à la référence quand la planification a déjà
    déplacé le plan de `facteur_plan` : le produit reste dans [1 − plafond,
    1 + plafond] (plafonds durs de l'optimisation bornée, cahier § 6)."""
    f = facteur_plan * facteur_essai
    bas = 1.0 - plafond
    haut = 1.0 + plafond
    return bas if f < bas else (haut if f > haut else f)


# ----------------------------------------------------------------------
# 1. A posteriori sur les hypothèses de réponse
# ----------------------------------------------------------------------
class Reponse(object):
    """Poids a posteriori des hypothèses h = (s0, k) : le progrès hebdomadaire
    attendu d'un exercice vaut rho × dose_h(stimulus de la semaine), avec
    dose_h(s) = (1 − exp(−s_k/s0)) / (1 − exp(−ref/s0)) (formule de
    `Modele.dose`). Toutes les hypothèses valent rho à la dose de référence :
    seules les semaines dont le stimulus s'en écarte apportent de
    l'information."""

    def __init__(self, hypotheses, ref, plancher=1e-6, poids=None):
        self.hypotheses = [(float(h[0]), int(h[1])) for h in hypotheses]
        self.ref = float(ref)
        self.plancher = float(plancher)
        n = len(self.hypotheses)
        self.poids = [1.0 / n] * n if poids is None else [float(w) for w in poids]
        self.derniere = None      # dernière semaine (de journal) déjà consommée
        self.n_obs = 0            # progrès observés intégrés

    @staticmethod
    def depuis_params(params):
        dyn = params['dynamique']
        hyps = [(s, k) for k in range(len(dyn['hypotheses_stimulus'])) for s in dyn['hypotheses_s0']]
        return Reponse(hyps, dyn['dose_reference'], _param(params, 'plancher_poids'))

    def dose(self, stim, i):
        s0, k = self.hypotheses[i]
        s = stim[k]
        if s <= 0:
            return 0.0
        return (1.0 - math.exp(-s / s0)) / (1.0 - math.exp(-self.ref / s0))

    def mettre_a_jour(self, lignes, rho, sigma):
        """Vraisemblance directe des progrès (données synthétiques, tests) :
        [lignes] : lignes {semaine, doses, mu} dans l'ordre ; pour chaque
        paire consécutive (a, b), le progrès observé d'un exercice est
        b.mu − a.mu, causé par le stimulus de la semaine b (b.doses), attendu
        rho × dose_h(stimulus) sous l'hypothèse h. [rho] : nombre ou
        dictionnaire exercice -> nombre. [sigma] : écart-type du bruit du
        progrès. Une semaine déjà consommée est ignorée (appel idempotent).
        Renvoie le nombre de progrès intégrés.

        ATTENTION : ne pas nourrir cette méthode avec les `mu` de
        `journal_semaines` du moteur : ils progressent déjà, chaque lundi, de
        la dose MOYENNE sur les hypothèses (calcul circulaire : les poids
        resteraient près de leur valeur courante quoi qu'il arrive). Le
        moteur passe par `ControleDual`, qui nourrit `integrer` avec
        l'innovation hebdomadaire de capacité."""
        n = len(self.hypotheses)
        obs = []
        derniere = None
        for j in range(len(lignes) - 1):
            a = lignes[j]
            b = lignes[j + 1]
            if self.derniere is not None and b['semaine'] <= self.derniere:
                continue
            ids = sorted(b['mu'].keys())
            for ex in ids:
                if ex not in a['mu'] or ex not in b['doses']:
                    continue
                stim = b['doses'][ex]
                r = rho[ex] if isinstance(rho, dict) else rho
                attendus = [r * self.dose(stim, i) for i in range(n)]
                obs.append((attendus, b['mu'][ex] - a['mu'][ex], sigma * sigma))
            derniere = b['semaine']
        if derniere is None:
            return 0
        return self.integrer(obs, derniere)

    def integrer(self, observations, semaine):
        """Intègre des observations scalaires indépendantes : liste de
        (attendus [valeur attendue sous chaque hypothèse], observé, variance).
        Log-vraisemblance gaussienne, normalisation stable, plancher.
        [semaine] : semaine consommée (une semaine ≤ la dernière consommée
        est ignorée : appel idempotent). Renvoie le nombre d'observations
        intégrées."""
        if self.derniere is not None and semaine <= self.derniere:
            return 0
        self.derniere = int(semaine)
        n = len(self.hypotheses)
        ll = [0.0] * n
        compte = 0
        for (attendus, obs, var) in observations:
            v = float(var)
            if not v > 0.0:
                continue
            for i in range(n):
                d = obs - attendus[i]
                ll[i] += -0.5 * d * d / v
            compte += 1
        if compte == 0:
            return 0
        # Log-espace, normalisation stable (soustraction du maximum).
        lw = [0.0] * n
        mx = -math.inf
        for i in range(n):
            w = self.poids[i]
            lw[i] = (math.log(w) if w > 0 else -745.0) + ll[i]
            if lw[i] > mx:
                mx = lw[i]
        tot = 0.0
        for i in range(n):
            lw[i] = math.exp(lw[i] - mx)
            tot += lw[i]
        # Plancher puis renormalisation (le plancher effectif vaut au moins
        # plancher / (1 + n × plancher)).
        tot2 = 0.0
        for i in range(n):
            w = lw[i] / tot
            if w < self.plancher:
                w = self.plancher
            lw[i] = w
            tot2 += w
        for i in range(n):
            self.poids[i] = lw[i] / tot2
        self.n_obs += compte
        return compte

    def tirer(self, rng):
        """Tirage de Thompson : indice d'hypothèse tiré selon les poids (un
        seul uniforme, inversion de la fonction de répartition dans l'ordre
        des hypothèses)."""
        u = rng.next()
        c = 0.0
        n = len(self.poids)
        for i in range(n):
            c += self.poids[i]
            if u < c:
                return i
        return n - 1

    def meilleure(self):
        """Indice de plus grand poids (égalité : le plus petit indice)."""
        b = 0
        for i in range(1, len(self.poids)):
            if self.poids[i] > self.poids[b]:
                b = i
        return b

    def entropie(self):
        h = 0.0
        for w in self.poids:
            if w > 0:
                h -= w * math.log(w)
        return h

    def etat(self):
        return {'hypotheses': [[h[0], h[1]] for h in self.hypotheses], 'ref': self.ref,
                'plancher': self.plancher, 'poids': list(self.poids),
                'derniere': self.derniere, 'n_obs': self.n_obs}

    @staticmethod
    def depuis_etat(etat):
        r = Reponse(etat['hypotheses'], etat['ref'], etat['plancher'], etat['poids'])
        r.derniere = None if etat['derniere'] is None else int(etat['derniere'])
        r.n_obs = int(etat['n_obs'])
        return r


# ----------------------------------------------------------------------
# 2. Condition de déclenchement
# ----------------------------------------------------------------------
def calibre(koach, lifts_principaux, semaines=None):
    """(bool, raisons) : au moins `semaines_min` semaines de journal ET, pour
    chaque lift principal, demi-largeur relative de l'intervalle à 90 % de
    l'e1RM (1,645 × écart-type de ln capacité) sous `intervalle_max`.
    [semaines] : nombre de semaines de journal (défaut : longueur de
    `koach.modele.journal_semaines`)."""
    p = koach.params
    raisons = []
    n = len(koach.modele.journal_semaines) if semaines is None else int(semaines)
    nmin = _param(p, 'semaines_min')
    if n < nmin:
        raisons.append('semaines_insuffisantes:%d<%d' % (n, nmin))
    imax = _param(p, 'intervalle_max')
    if len(lifts_principaux) == 0:
        raisons.append('aucun_lift_principal')
    for ex in lifts_principaux:
        c = koach.modele.capacite(ex)
        if c is None:
            raisons.append('lift_inconnu:%s' % ex)
            continue
        demi = Z90 * c[1]
        if not demi < imax:
            raisons.append('intervalle_large:%s:%.4f' % (ex, demi))
    return len(raisons) == 0, raisons


# ----------------------------------------------------------------------
# 3. Essai N-of-1
# ----------------------------------------------------------------------
class EssaiN1(object):
    """Compare A (+amplitude_volume de volume) et B (+amplitude_intensite
    d'intensité) sur une qualité ou un exercice, par bras de `bras_semaines`
    semaines. Le résultat mesuré chaque semaine est le progrès de ln
    capacité de la cible moins celui de son témoin synthétique."""

    def __init__(self, params, cible, exercices_traites=None, exercices_temoins=None):
        """[cible] : {'qualite': q} ou {'exerciseId': id}."""
        if 'qualite' in cible:
            self.cle = 'qualite'
        elif 'exerciseId' in cible:
            self.cle = 'exerciseId'
        else:
            raise ValueError('cible sans qualite ni exerciseId')
        self.valeur = cible[self.cle]
        self.traites = sorted(exercices_traites or ([] if self.cle == 'qualite' else [self.valeur]))
        self.temoins = sorted(exercices_temoins or [])
        self.bras_semaines = int(_param(params, 'bras_semaines'))
        self.amp_v = float(_param(params, 'amplitude_volume'))
        self.amp_i = float(_param(params, 'amplitude_intensite'))
        self.plafond_v = float(_plafond(params, 'plafond_volume'))
        self.plafond_i = float(_plafond(params, 'plafond_intensite'))
        # Toujours à l'intérieur des plafonds de l'optimisation bornée.
        if not (0.0 <= self.amp_v <= self.plafond_v):
            raise AssertionError('amplitude de volume hors plafond : %r' % self.amp_v)
        if not (0.0 <= self.amp_i <= self.plafond_i):
            raise AssertionError('amplitude d\'intensité hors plafond : %r' % self.amp_i)
        self.tau = float(_param(params, 'a_priori_effet_sd'))
        self.sigma_secours = float(_param(params, 'sigma_progres'))
        self.seuil = float(_param(params, 'seuil_decision'))
        self.marge = int(_param(params, 'marge_echeance_semaines'))
        self.sequence = []
        self.debut = None
        self.statut = 'prevu'     # prevu, en_cours, termine, interrompu
        self.raison_fin = None
        self.mesures = []         # [semaine, bras, lettre, progrès traité − témoin]

    # --- conditions -------------------------------------------------------
    def facteurs(self, lettre):
        if lettre == 'A':
            return {'volume': 1.0 + self.amp_v, 'intensite': 1.0}
        return {'volume': 1.0, 'intensite': 1.0 + self.amp_i}

    def duree(self):
        return len(self.sequence) * self.bras_semaines

    def plan(self, rng, n_bras):
        """Séquence équilibrée et contre-balancée : paires de bras AB ou BA ;
        la paire paire est tirée (un uniforme), la paire impaire est son
        miroir (ABBA ou BAAB). n_bras pair ≥ 2."""
        if n_bras < 2 or n_bras % 2 != 0:
            raise ValueError('n_bras doit être pair et ≥ 2')
        seq = []
        prem = 'A'
        for j in range(n_bras // 2):
            if j % 2 == 0:
                prem = 'A' if rng.next() < 0.5 else 'B'
            else:
                prem = 'B' if prem == 'A' else 'A'
            seq.append(prem)
            seq.append('B' if prem == 'A' else 'A')
        self.sequence = seq
        return list(seq)

    def peut_demarrer(self, contexte):
        """(bool, raisons). [contexte] : {'calibre': bool, 'affutage': bool,
        'semaines_avant_echeance': int ou None, 'alerte': bool, 'douleur':
        bool}. L'essai doit finir au moins `marge_echeance_semaines` avant
        l'échéance (donc ne démarre jamais à moins de cette marge)."""
        raisons = []
        if not contexte.get('calibre', False):
            raisons.append('non_calibre')
        if contexte.get('affutage', False):
            raisons.append('affutage')
        if contexte.get('alerte', False):
            raisons.append('alerte_hors_modele')
        if contexte.get('douleur', False):
            raisons.append('douleur')
        ech = contexte.get('semaines_avant_echeance')
        if ech is not None:
            duree = self.duree() if self.sequence else self.bras_semaines * int(DEFAUTS_DUAL['n_bras'])
            if ech < self.marge or ech - duree < self.marge:
                raisons.append('echeance_proche')
        if self.statut != 'prevu':
            raisons.append('deja_%s' % self.statut)
        # Contrôle synthétique : il faut assez de semaines AVANT
        # l'intervention, sinon l'essai modulerait l'athlète sans pouvoir
        # rien mesurer.
        pre = contexte.get('semaines_temoin')
        if pre is not None and pre < int(contexte.get('semaines_temoin_min', DEFAUTS_DUAL['synthetique_semaines_min'])):
            raisons.append('temoin_trop_court:%d' % pre)
        return len(raisons) == 0, raisons

    def demarrer(self, semaine):
        if not self.sequence:
            raise ValueError('plan() avant demarrer()')
        self.debut = int(semaine)
        self.statut = 'en_cours'

    def interrompre(self, raison):
        """Retour au plan de référence (alerte hors modèle, douleur…)."""
        if self.statut in ('prevu', 'en_cours'):
            self.statut = 'interrompu'
            self.raison_fin = raison

    def bras_de(self, semaine):
        if self.debut is None or self.statut == 'interrompu':
            return None
        i = (int(semaine) - self.debut) // self.bras_semaines
        if semaine < self.debut or i >= len(self.sequence):
            return None
        return i

    def condition(self, semaine):
        """'A', 'B' ou None (essai fini, interrompu ou pas commencé)."""
        i = self.bras_de(semaine)
        return None if i is None else self.sequence[i]

    def fini(self, semaine):
        return self.debut is not None and semaine >= self.debut + self.duree() - 1

    def enregistrer(self, semaine, progres_traite, progres_temoin_synthetique):
        i = self.bras_de(semaine)
        if i is None:
            return False
        for m in self.mesures:
            if m[0] == semaine:
                return False
        self.mesures.append([int(semaine), i, self.sequence[i], progres_traite - progres_temoin_synthetique])
        if self.fini(semaine) and self.statut == 'en_cours':
            self.statut = 'termine'
        return True

    # --- analyse ------------------------------------------------------------
    def analyse(self):
        """Effet moyen B − A sur le progrès hebdomadaire : moyenne des
        différences appariées par paire de bras (bras 2j et 2j+1). Erreur-type
        par la variance intra-bras groupée (σ² supposée commune, semaines
        indépendantes ; `sigma_progres` si aucun degré de liberté).
        A posteriori normal sous a priori N(0, τ²) : P(B > A), décision 'B'
        si P ≥ seuil, 'A' si P ≤ 1 − seuil, 'indetermine' sinon."""
        nb = len(self.sequence)
        somme = [0.0] * nb
        compte = [0] * nb
        for m in self.mesures:
            somme[m[1]] += m[3]
            compte[m[1]] += 1
        moy = [0.0] * nb
        for i in range(nb):
            if compte[i] > 0:
                moy[i] = somme[i] / compte[i]
        diffs = []
        var_somme_inv = 0.0   # Σ (1/nA + 1/nB) sur les paires complètes
        ddl = 0
        for j in range(nb // 2):
            i0 = 2 * j
            i1 = 2 * j + 1
            if compte[i0] == 0 or compte[i1] == 0:
                continue
            ia, ib = (i0, i1) if self.sequence[i0] == 'A' else (i1, i0)
            diffs.append(moy[ib] - moy[ia])
            var_somme_inv += 1.0 / compte[ia] + 1.0 / compte[ib]
            ddl += compte[ia] - 1 + compte[ib] - 1
        n = len(diffs)
        if n == 0:
            return {'paires': 0, 'effet': None, 'erreur_type': None, 'ddl': 0,
                    'probabilite_b': 0.5, 'moyenne_post': 0.0, 'ecart_type_post': self.tau,
                    'decision': 'indetermine', 'moyennes_bras': moy}
        effet = 0.0
        for d in diffs:
            effet += d
        effet /= n
        # Somme des carrés intra-bras, sur les seules paires complètes.
        ssw_p = 0.0
        for m in self.mesures:
            j = m[1] // 2
            if compte[2 * j] > 0 and compte[2 * j + 1] > 0:
                d = m[3] - moy[m[1]]
                ssw_p += d * d
        s2 = ssw_p / ddl if ddl > 0 else self.sigma_secours * self.sigma_secours
        se2 = s2 * var_somme_inv / (n * n)
        t2 = self.tau * self.tau
        if se2 <= 0:
            se2 = 1e-18
        v_post = 1.0 / (1.0 / t2 + 1.0 / se2)
        m_post = v_post * effet / se2
        sd_post = math.sqrt(v_post)
        p = norm_cdf(m_post / sd_post)
        if p >= self.seuil:
            dec = 'B'
        elif p <= 1.0 - self.seuil:
            dec = 'A'
        else:
            dec = 'indetermine'
        return {'paires': n, 'effet': effet, 'erreur_type': math.sqrt(se2), 'ddl': ddl,
                'probabilite_b': p, 'moyenne_post': m_post, 'ecart_type_post': sd_post,
                'decision': dec, 'moyennes_bras': moy}

    # --- état -----------------------------------------------------------------
    def etat(self):
        return {'cle': self.cle, 'valeur': self.valeur, 'traites': list(self.traites),
                'temoins': list(self.temoins), 'sequence': list(self.sequence),
                'debut': self.debut, 'statut': self.statut, 'raison_fin': self.raison_fin,
                'mesures': [list(m) for m in self.mesures]}

    @staticmethod
    def depuis_etat(params, etat):
        e = EssaiN1(params, {etat['cle']: etat['valeur']}, etat['traites'], etat['temoins'])
        e.sequence = list(etat['sequence'])
        e.debut = None if etat['debut'] is None else int(etat['debut'])
        e.statut = etat['statut']
        e.raison_fin = etat['raison_fin']
        e.mesures = [[int(m[0]), int(m[1]), m[2], float(m[3])] for m in etat['mesures']]
        return e


# ----------------------------------------------------------------------
# 4. Contrôle synthétique
# ----------------------------------------------------------------------
def projection_simplexe(v):
    """Projection euclidienne exacte de v sur {w ≥ 0, Σ w = 1} (Held, Wolfe
    et Crowder 1974 ; Duchi et al. 2008) : tri décroissant (tri par
    insertion, égalités départagées par l'indice croissant : stable et
    portable), seuil θ, w = max(v − θ, 0)."""
    n = len(v)
    ordre = list(range(n))
    for i in range(1, n):
        j = i
        while j > 0:
            a = ordre[j - 1]
            b = ordre[j]
            if v[b] > v[a] or (v[b] == v[a] and b < a):
                ordre[j - 1] = b
                ordre[j] = a
                j -= 1
            else:
                break
    cumul = 0.0
    theta = 0.0
    for r in range(n):
        cumul += v[ordre[r]]
        t = (cumul - 1.0) / (r + 1)
        if v[ordre[r]] - t > 0:
            theta = t
    w = [0.0] * n
    for i in range(n):
        d = v[i] - theta
        w[i] = d if d > 0 else 0.0
    return w


def borne_lambda_max(A, tr, carres=4):
    """Majorant garanti de la plus grande valeur propre d'une matrice
    symétrique semi-définie positive : λmax ≤ trace(A^(2^p))^(1/2^p), au
    plus J^(1/2^p) fois λmax (1,11 pour J = 5, p = 4). A est d'abord
    divisée par sa trace (valeurs propres ≤ 1, pas de débordement), puis
    élevée au carré p fois (nombre d'opérations fixe)."""
    J = len(A)
    B = [[A[j][l] / tr for l in range(J)] for j in range(J)]
    for _ in range(carres):
        C = [[0.0] * J for _ in range(J)]
        for j in range(J):
            for l in range(J):
                acc = 0.0
                for m in range(J):
                    acc += B[j][m] * B[m][l]
                C[j][l] = acc
        B = C
    t = 0.0
    for j in range(J):
        t += B[j][j]
    if t <= 0.0:
        return tr
    return tr * math.pow(t, 1.0 / (2 ** carres))


def _simplexe_moindres_carres(A, b, iterations):
    """min_w wᵀAw − 2bᵀw sur le simplexe (A = XᵀX, b = Xᵀy). Gradient projeté
    accéléré (FISTA, Beck et Teboulle 2009) à pas 1/L, L = 2 × majorant de
    λmax(A) (`borne_lambda_max`, sûr sans calcul de valeurs propres), nombre
    d'itérations fixe. Renvoie (w, écart de dualité de Frank-Wolfe)."""
    J = len(b)
    w = [1.0 / J] * J
    tr = 0.0
    for j in range(J):
        tr += A[j][j]
    if tr <= 0.0:
        return w, 0.0
    L = 2.0 * borne_lambda_max(A, tr)
    y = list(w)
    t = 1.0
    for _ in range(iterations):
        z = [0.0] * J
        for j in range(J):
            g = 0.0
            for l in range(J):
                g += A[j][l] * y[l]
            g = 2.0 * (g - b[j])
            z[j] = y[j] - g / L
        wn = projection_simplexe(z)
        tn = (1.0 + math.sqrt(1.0 + 4.0 * t * t)) / 2.0
        c = (t - 1.0) / tn
        for j in range(J):
            y[j] = wn[j] + c * (wn[j] - w[j])
        w = wn
        t = tn
    # Écart de dualité de Frank-Wolfe : gᵀw − min_j g_j ≥ f(w) − f*.
    g = [0.0] * J
    gmin = math.inf
    gw = 0.0
    for j in range(J):
        s = 0.0
        for l in range(J):
            s += A[j][l] * w[l]
        g[j] = 2.0 * (s - b[j])
        gw += g[j] * w[j]
        if g[j] < gmin:
            gmin = g[j]
    return w, gw - gmin


def controle_synthetique(serie_traitee, series_temoins, debut_intervention, iterations=200,
                         semaines_min=6):
    """Contrôle synthétique (Abadie, Diamond et Hainmueller 2010).

    [serie_traitee] : trajectoire de ln capacité de la cible (une valeur par
    semaine) ; [series_temoins] : trajectoires d'exercices non touchés par
    l'essai, même longueur ; [debut_intervention] : indice de la première
    semaine traitée. Chaque série est centrée sur sa moyenne
    pré-intervention (contrôle synthétique « démoyenné ») ; les poids w ≥ 0,
    Σ w = 1 minimisent l'erreur quadratique pré-intervention.

    Renvoie {poids, erreur_pre (RMSE pré), contrefactuel (toute la période),
    ecart (traitée − contrefactuel à partir de l'intervention), effet_moyen,
    ecart_dualite}."""
    T = len(serie_traitee)
    T0 = int(debut_intervention)
    if T0 < semaines_min:
        raise ValueError('contrôle synthétique : %d semaines avant l\'intervention (minimum %d)'
                         % (T0, semaines_min))
    if T0 > T:
        raise ValueError('début d\'intervention après la fin de la série')
    J = len(series_temoins)
    if J == 0:
        raise ValueError('contrôle synthétique sans série témoin')
    for s in series_temoins:
        if len(s) != T:
            raise ValueError('séries témoins de longueurs différentes')
    my = 0.0
    for t in range(T0):
        my += serie_traitee[t]
    my /= T0
    mx = [0.0] * J
    for j in range(J):
        acc = 0.0
        for t in range(T0):
            acc += series_temoins[j][t]
        mx[j] = acc / T0
    A = [[0.0] * J for _ in range(J)]
    b = [0.0] * J
    for j in range(J):
        for l in range(J):
            acc = 0.0
            for t in range(T0):
                acc += (series_temoins[j][t] - mx[j]) * (series_temoins[l][t] - mx[l])
            A[j][l] = acc
        acc = 0.0
        for t in range(T0):
            acc += (series_temoins[j][t] - mx[j]) * (serie_traitee[t] - my)
        b[j] = acc
    w, gap = _simplexe_moindres_carres(A, b, iterations)
    contre = [0.0] * T
    for t in range(T):
        v = my
        for j in range(J):
            v += w[j] * (series_temoins[j][t] - mx[j])
        contre[t] = v
    sse = 0.0
    for t in range(T0):
        d = serie_traitee[t] - contre[t]
        sse += d * d
    ecart = []
    for t in range(T0, T):
        ecart.append(serie_traitee[t] - contre[t])
    effet = 0.0
    for d in ecart:
        effet += d
    effet = effet / len(ecart) if len(ecart) > 0 else 0.0
    return {'poids': w, 'erreur_pre': math.sqrt(sse / T0), 'contrefactuel': contre,
            'ecart': ecart, 'effet_moyen': effet, 'ecart_dualite': gap}


def effet_essai(serie_traitee, series_temoins, debut_intervention, iterations=200, semaines_min=6):
    """Progrès hebdomadaires de la cible et de son témoin synthétique à partir
    de l'intervention : progrès(t) = valeur(t) − valeur(t − 1), t ≥ début.
    Renvoie {'progres_traite', 'progres_temoin_synthetique', 'synthetique'}."""
    sc = controle_synthetique(serie_traitee, series_temoins, debut_intervention, iterations,
                              semaines_min)
    c = sc['contrefactuel']
    pt = []
    pc = []
    for t in range(int(debut_intervention), len(serie_traitee)):
        pt.append(serie_traitee[t] - serie_traitee[t - 1])
        pc.append(c[t] - c[t - 1])
    return {'progres_traite': pt, 'progres_temoin_synthetique': pc, 'synthetique': sc}


# ----------------------------------------------------------------------
# 5. Orchestration
# ----------------------------------------------------------------------
class ControleDual(Extension):
    """Extension du moteur : met à jour `Reponse` chaque lundi, conduit
    l'essai N-of-1 en cours et expose le tirage de Thompson de la semaine et
    la modulation du plan pendant un bras.

    Source unique des poids des hypothèses : `self.reponse.poids`. Après
    chaque mise à jour, ils sont recopiés dans `koach.modele.poids_hyp`
    (que le modèle lit pour sa dose moyenne) ; rien d'autre n'écrit
    `poids_hyp`. Sans contrôle dual branché, le modèle garde ses poids
    uniformes.

    Mesure non circulaire (innovation hebdomadaire de capacité). Les `mu` de
    `journal_semaines` sont pris APRÈS la croissance du lundi, calculée avec
    la dose moyenne sur les hypothèses : leurs écarts contiennent la
    prédiction du modèle lui-même. On mesure à la place, pour chaque
    exercice, l'innovation de la semaine b :
        ν_b = μ_pré(b) − μ_post(b − 1),
    μ_pré(b) = capacité a posteriori à la fin de la dernière séance de la
    semaine b (avant la croissance du lundi), μ_post(b − 1) = capacité
    prédite au lundi précédent (croissance g_util appliquée). Sous
    l'hypothèse h, l'écart attendu entre la capacité vraie et la prédiction
    vaut δ_h, qui évolue ainsi (approximation scalaire du filtre, gain
    K_b = 1 − V_pré(b) / V_prior(b)) :
        lundi : δ_h += g_h − g_util (g_h = (ρ + ε) × facteur × dose_h) ;
        semaine : E[ν_b | h] = K_b δ_h, Var[ν_b] = V_prior − V_pré (+ plancher) ;
                  puis δ_h ← (1 − K_b) δ_h.
    ν_b ne dépend pas de l'hypothèse ; seule sa valeur attendue en dépend.
    Approximations documentées : exercices traités comme indépendants
    (les qualités partagées les corrèlent), gain scalaire par exercice."""

    def __init__(self, params, lifts_principaux):
        self.params = params
        self.lifts = sorted(lifts_principaux)
        self.reponse = Reponse.depuis_params(params)
        self.essai = None
        self.essais_passes = []   # [{'essai': etat, 'analyse': dict}]
        self.raisons = []
        self.cap_seance = {}      # ex -> [μ, V] à la fin de la dernière séance
        self.suivi = {}           # ex -> [μ_post, V_post, [δ_h]]
        self.pre = []             # [{'semaine', 'mu': {ex: μ_pré}}] (synthétique)

    RAISONS_GARDEES = 50

    def _raison(self, r):
        self.raisons.append(r)
        if len(self.raisons) > self.RAISONS_GARDEES:
            self.raisons = self.raisons[len(self.raisons) - self.RAISONS_GARDEES:]

    # --- lecture du modèle ----------------------------------------------------
    @staticmethod
    def _rho(koach, ids):
        """rho + eps de la classe de chaque exercice (dictionnaire)."""
        m = koach.modele
        rho = float(m.m[RHO])
        out = {}
        for ex in ids:
            t = m.pistes.get(ex) if hasattr(m, 'pistes') else None
            c = getattr(t, 'classe', None) if t is not None else None
            out[ex] = rho + (float(m.m[EPS + c]) if c is not None else 0.0)
        return out

    @staticmethod
    def _suivables(koach):
        """Exercices suivis par le modèle avec une classe de réponse (triés)."""
        m = koach.modele
        out = []
        for ex in sorted(m.pistes.keys()):
            t = m.pistes[ex]
            if t is not None and getattr(t, 'classe', None) is not None:
                out.append(ex)
        return out

    @staticmethod
    def series(lignes, traites, temoins):
        """(semaines, série traitée = moyenne des mu des exercices traités,
        séries témoins) sur les lignes où tous les exercices sont présents."""
        sem = []
        tr = []
        te = [[] for _ in temoins]
        for ligne in lignes:
            mu = ligne['mu']
            ok = len(traites) > 0
            for ex in traites:
                if ex not in mu:
                    ok = False
            for ex in temoins:
                if ex not in mu:
                    ok = False
            if not ok:
                continue
            v = 0.0
            for ex in traites:
                v += mu[ex]
            sem.append(ligne['semaine'])
            tr.append(v / len(traites))
            for j in range(len(temoins)):
                te[j].append(mu[temoins[j]])
        return sem, tr, te

    # --- innovations et poids ---------------------------------------------------
    def _innovations(self, koach, ligne):
        m = koach.modele
        hyps = getattr(m, 'hypotheses', None)
        if hyps is not None and [(float(h[0]), int(h[1])) for h in hyps] != self.reponse.hypotheses:
            raise ValueError('hypothèses de réponse différentes entre le modèle et le contrôle dual')
        n = len(self.reponse.hypotheses)
        ids = []
        for ex in sorted(ligne['mu'].keys()):
            t = m.pistes.get(ex) if hasattr(m, 'pistes') else None
            if t is not None and getattr(t, 'classe', None) is not None:
                ids.append(ex)
        rho = self._rho(koach, ids)
        fac = float(ligne.get('facteur', 1.0))
        dyn = self.params.get('dynamique') or {}
        q7 = 7.0 * float(dyn.get('q_delta_jour_inactif', 0.0))
        smin = float(_param(self.params, 'sigma_innovation'))
        w = list(self.reponse.poids)
        obs = []
        suivi = {}
        pre = {}
        for ex in ids:
            c = m.capacite(ex)
            if c is None:
                continue
            mu_post = float(ligne['mu'][ex])
            v_post = float(c[1]) * float(c[1])
            stim = (ligne.get('doses') or {}).get(ex)
            g = [0.0] * n
            gu = 0.0
            if stim is not None:
                for i in range(n):
                    g[i] = rho[ex] * fac * self.reponse.dose(stim, i)
                    gu += w[i] * g[i]
            cs = self.cap_seance.get(ex)
            mu_pre = cs[0] if cs is not None else mu_post - gu
            s = self.suivi.get(ex)
            if s is not None:
                v_prior = s[1] + q7
                v_pre = cs[1] if cs is not None else v_prior
                k = 1.0 - v_pre / v_prior if v_prior > 0.0 else 0.0
                k = 0.0 if k < 0.0 else (1.0 if k > 1.0 else k)
                var = v_prior - v_pre
                var = (var if var > 0.0 else 0.0) + smin * smin
                obs.append(([k * d for d in s[2]], mu_pre - s[0], var))
                deltas = [(1.0 - k) * d for d in s[2]]
            else:
                deltas = [0.0] * n
            suivi[ex] = [mu_post, v_post, [deltas[i] + g[i] - gu for i in range(n)]]
            pre[ex] = mu_pre
        self.suivi = suivi
        self.cap_seance = {}
        self.pre.append({'semaine': int(ligne['semaine']), 'mu': pre})
        garde = int(_param(self.params, 'semaines_gardees'))
        if len(self.pre) > garde:
            self.pre = self.pre[len(self.pre) - garde:]
        return obs

    # --- crochets du moteur -----------------------------------------------------
    def fin_seance(self, koach, resume, e):
        m = koach.modele
        for ex in self._suivables(koach):
            c = m.capacite(ex)
            if c is not None:
                self.cap_seance[ex] = [float(c[0]), float(c[1]) * float(c[1])]
        if self.essai is not None and e.get('douleurs'):
            self.interrompre('douleur')

    def fin_semaine(self, koach, ligne, e):
        obs = self._innovations(koach, ligne)
        self.reponse.integrer(obs, ligne['semaine'])
        if hasattr(koach.modele, 'poids_hyp'):
            koach.modele.poids_hyp = list(self.reponse.poids)
        es = self.essai
        if es is None:
            return
        if e.get('alerte_hors_modele') or e.get('alerte'):
            self.interrompre('alerte_hors_modele')
            return
        if e.get('douleur') or e.get('douleurs'):
            self.interrompre('douleur')
            return
        s = ligne['semaine']
        if es.condition(s) is not None:
            # Séries de capacité a posteriori AVANT la croissance du lundi
            # (μ_pré) : la croissance prédite par la dose de la semaine (donc
            # par le bras) n'y entre pas.
            sem, tr, te = self.series(self.pre, es.traites, es.temoins)
            debut = 0
            while debut < len(sem) and sem[debut] < es.debut:
                debut += 1
            pos = len(sem) - 1
            if pos >= 0 and sem[pos] == s and debut <= pos and len(te) > 0:
                try:
                    r = effet_essai(tr, te, debut, int(_param(self.params, 'synthetique_iterations')),
                                    int(_param(self.params, 'synthetique_semaines_min')))
                    k = pos - debut
                    es.enregistrer(s, r['progres_traite'][k], r['progres_temoin_synthetique'][k])
                except ValueError as err:
                    self._raison('synthetique_impossible:%s' % err)
        if es.statut == 'en_cours' and es.fini(s):
            es.statut = 'termine'
        if es.statut in ('termine', 'interrompu'):
            self._clore()

    def decision(self, koach, e):
        """Propositions d'essai journalisées (événement `decision` portant
        `essai` : {semaine, cible, traites, temoins, contexte, graine,
        n_bras}) : l'état se recalcule depuis le journal."""
        d = e.get('essai')
        if d is not None:
            ok, raisons = self.proposer_essai(koach, int(d['semaine']), d['cible'], d['traites'],
                                              d['temoins'], d.get('contexte') or {}, int(d['graine']),
                                              d.get('n_bras'))
            self._raison('essai_%s:%d:%s' % ('demarre' if ok else 'refuse', int(d['semaine']),
                                             ','.join(raisons)))
        if self.essai is not None and e.get('alerte_hors_modele'):
            self.interrompre('alerte_hors_modele')

    def sur_alerte_hors_modele(self, koach, causes):
        """Branche `Surveillance` -> contrôle dual : une alerte hors modèle
        interrompt l'essai en cours (retour au plan de référence)."""
        if self.essai is not None:
            self.interrompre('alerte_hors_modele')

    # --- essais -----------------------------------------------------------------
    def proposer_essai(self, koach, semaine, cible, traites, temoins, contexte, graine, n_bras=None):
        """Crée, planifie et démarre un essai à la semaine [semaine] si
        `peut_demarrer` l'accepte (le calibrage est recalculé ici). Renvoie
        (bool, raisons)."""
        if self.essai is not None:
            return False, ['essai_en_cours']
        es = EssaiN1(self.params, cible, traites, temoins)
        nb = int(_param(self.params, 'n_bras') if n_bras is None else n_bras)
        rng = Mulberry32(fnv1a32('koach-dual-essai:%d:%d' % (graine, semaine)))
        es.plan(rng, nb)
        ok_cal, r_cal = calibre(koach, self.lifts)
        ctx = dict(contexte)
        ctx['calibre'] = ok_cal
        # Semaines de journal des capacités disponibles avant l'intervention
        # pour les témoins (contrôle synthétique, cahier § 7 : 6 au moins).
        ctx['semaines_temoin'] = sum(1 for x in self.pre if all(t in x['mu'] for t in es.temoins)) \
            if es.temoins else 0
        ctx['semaines_temoin_min'] = int(_param(self.params, 'synthetique_semaines_min'))
        ok, raisons = es.peut_demarrer(ctx)
        if not ok:
            return False, raisons + r_cal
        es.demarrer(semaine)
        self.essai = es
        return True, []

    def interrompre(self, raison):
        if self.essai is not None:
            self.essai.interrompre(raison)
            self._raison('essai_interrompu:%s' % raison)
            self._clore()

    def _clore(self):
        es = self.essai
        self.essais_passes.append({'essai': es.etat(), 'analyse': es.analyse()})
        self.essai = None

    # --- sorties pour la planification ------------------------------------------
    def hypothese_pour_la_semaine(self, koach, semaine, graine):
        """Indice d'hypothèse tiré (Thompson) pour la replanification de
        [semaine], ou None si le modèle n'est pas calibré (la planification
        garde alors la dose moyenne). Même semaine + même graine = même
        tirage."""
        ok, raisons = calibre(koach, self.lifts)
        if not ok:
            return None
        rng = Mulberry32(fnv1a32('koach-dual:%d:%d' % (graine, semaine)))
        return self.reponse.tirer(rng)

    def modulation(self, semaine):
        """Facteurs à appliquer par la planification à la cible pendant un
        bras ; 1,0 hors essai. La planification borne le produit par les
        plafonds (`facteur_borne`)."""
        es = self.essai
        lettre = None if es is None else es.condition(semaine)
        if lettre is None:
            return {'volume': 1.0, 'intensite': 1.0}
        f = es.facteurs(lettre)
        return {es.cle: es.valeur, 'volume': f['volume'], 'intensite': f['intensite'], 'bras': lettre}

    # --- état -------------------------------------------------------------------
    def etat(self):
        return {'lifts': list(self.lifts), 'reponse': self.reponse.etat(),
                'essai': None if self.essai is None else self.essai.etat(),
                'essais_passes': [{'essai': x['essai'], 'analyse': x['analyse']} for x in self.essais_passes],
                'raisons': list(self.raisons),
                'cap_seance': [[ex, self.cap_seance[ex][0], self.cap_seance[ex][1]]
                               for ex in sorted(self.cap_seance.keys())],
                'suivi': [[ex, self.suivi[ex][0], self.suivi[ex][1], list(self.suivi[ex][2])]
                          for ex in sorted(self.suivi.keys())],
                'pre': [{'semaine': x['semaine'], 'mu': [[ex, x['mu'][ex]] for ex in sorted(x['mu'].keys())]}
                        for x in self.pre]}

    @staticmethod
    def depuis_etat(params, etat):
        c = ControleDual(params, etat['lifts'])
        c.reponse = Reponse.depuis_etat(etat['reponse'])
        c.essai = None if etat['essai'] is None else EssaiN1.depuis_etat(params, etat['essai'])
        c.essais_passes = [{'essai': x['essai'], 'analyse': x['analyse']} for x in etat['essais_passes']]
        c.raisons = list(etat['raisons'])
        c.cap_seance = dict((x[0], [float(x[1]), float(x[2])]) for x in etat.get('cap_seance', []))
        c.suivi = dict((x[0], [float(x[1]), float(x[2]), [float(v) for v in x[3]]])
                       for x in etat.get('suivi', []))
        c.pre = [{'semaine': int(x['semaine']), 'mu': dict((p[0], float(p[1])) for p in x['mu'])}
                 for x in etat.get('pre', [])]
        return c
