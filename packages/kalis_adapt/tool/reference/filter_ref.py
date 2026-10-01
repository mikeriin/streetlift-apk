# -*- coding: utf-8 -*-
"""kalis_adapt — implémentation de référence du noyau numérique (lot G8).

Écrite avant le Dart (prototype de mise au point du modèle), gardée comme
référence indépendante : `gen_vectors.py` produit avec elle les vecteurs de
`test/fixtures/filter_vectors.json.gz`, que `test/reference_test.dart` rejoue
avec `lib/src/filter.dart` et `lib/src/numeric.dart`. Une divergence entre
les deux écritures fait échouer le test. Aucune dépendance hors
bibliothèque standard.

Ce fichier ne couvre que le noyau numérique : filtre d'un exercice (état
[c, v, kappa, d]), fonctions de la loi normale, conversions flammes ↔ RIR,
courbe répétitions ↔ charge, fatigue intra-séance. Les règles de décision
sont validées par le simulateur et les tests de propriétés.
"""
import math

# Paramètres (mêmes valeurs que `AdaptParams.standard`, CONTRAT.md § 5).
P = {
    'q_level': 0.004,
    'q_trend': 0.0015,
    'trend_damping': 0.97,
    'obs_floor': 0.01,
    'k_min': 12.0,
    'k_max': 80.0,
    'set_fatigue_fail': 0.9,
    'set_fatigue_rest_tau': 150.0,
    'set_fatigue_rir_scale': 1.5,
    'set_fatigue_recovery': 0.5,
}


def sq(x):
    return x * x


def erfc(x):
    z = abs(x)
    t = 1.0 / (1.0 + 0.5 * z)
    poly = -z * z - 1.26551223 + t * (1.00002368 + t * (0.37409196 + t * (
        0.09678418 + t * (-0.18628806 + t * (0.27886807 + t * (-1.13520398 + t * (
            1.48851587 + t * (-0.82215223 + t * 0.17087277))))))))
    ans = t * math.exp(poly)
    return ans if x >= 0 else 2.0 - ans


def norm_pdf(a):
    return math.exp(-0.5 * a * a) / math.sqrt(2.0 * math.pi)


def norm_cdf(a):
    return 0.5 * erfc(-a / math.sqrt(2.0))


def flames_to_rir(f):
    return 0.0 if f == 10 else (11 - f) / 2.0


def rir_to_flames(rir):
    if rir >= 5:
        return 1
    halves = math.ceil(rir * 2 - 0.5)
    if halves <= 0:
        return 10
    return 9 if halves == 1 else 11 - halves


# ---------------------------------------------------------------------------
# Courbe répétitions ↔ charge
# ---------------------------------------------------------------------------
def log_share(n, k):
    """ln de la part du 1RM soulevable n fois (n ≥ 1) : −ln(1 + (n − 1)/k)."""
    return -math.log(1.0 + (max(n, 1.0) - 1.0) / k)


def reps_at(log_ratio, k):
    """Répétitions possibles à une charge dont ln(1RM / charge) = log_ratio."""
    return 1.0 + k * (math.exp(log_ratio) - 1.0)


# ---------------------------------------------------------------------------
# Filtre par exercice : état [x, v, kappa, d]
# ---------------------------------------------------------------------------
class Filter:
    """Filtre d'un exercice chargé. État [c, v, kappa, d] :

    - c : ln de la charge soulevable `n_ref` fois (capacité opérationnelle,
      à l'endroit de la courbe où l'exercice est travaillé) ;
    - v : pente de c par semaine ;
    - kappa : ln k (forme de la courbe répétitions ↔ charge) ;
    - d : effet de jour, remis à zéro à chaque séance.

    Le 1RM s'en déduit : ln 1RM = c + ln(1 + (n_ref − 1) / k).
    """

    def __init__(self, c, c_sd, v, v_sd, k, k_sd, n_ref, day):
        self.m = [c, v, math.log(k), 0.0]
        self.C = [[0.0] * 4 for _ in range(4)]
        self.C[0][0] = c_sd * c_sd
        self.C[1][1] = v_sd * v_sd
        self.C[2][2] = k_sd * k_sd
        self.n_ref = n_ref
        self.day = day
        self.sessions = 0
        self.sets = 0
        self.in_session = False
        self.set_fatigue = []
        self.history = []

    @staticmethod
    def from_one_rm(x, x_sd, v, v_sd, k, k_sd, n_ref, day):
        """A priori exprimé sur le 1RM (niveau déclaré) : c = x − g(n_ref, k)."""
        u = (n_ref - 1.0) / k
        a = u / (1.0 + u)
        f = Filter(x - math.log(1.0 + u), math.sqrt(x_sd * x_sd + a * a * k_sd * k_sd), v, v_sd, k, k_sd, n_ref, day)
        f.C[0][2] = a * k_sd * k_sd
        f.C[2][0] = f.C[0][2]
        return f

    # -- temps
    def predict(self, day, p=P):
        dt = (day - self.day) / 7.0
        if dt <= 0:
            return
        phi = p['trend_damping'] ** dt
        g = (1.0 - phi) / (-math.log(p['trend_damping']))
        F = [[1.0, g, 0.0, 0.0], [0.0, phi, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]]
        self.m = [self.m[0] + g * self.m[1], phi * self.m[1], self.m[2], self.m[3]]
        self.C = _fcft(F, self.C)
        ql, qt = sq(p['q_level']), sq(p['q_trend'])
        self.C[0][0] += ql * dt + qt * dt * dt * dt / 3.0
        self.C[0][1] += qt * dt * dt / 2.0
        self.C[1][0] += qt * dt * dt / 2.0
        self.C[1][1] += qt * dt
        self.day = day

    def begin_session(self, day, shift, day_sd, p=P):
        self.predict(day, p)
        for i in range(4):
            self.C[3][i] = 0.0
            self.C[i][3] = 0.0
        self.C[3][3] = day_sd * day_sd
        self.m[3] = shift
        self.in_session = True
        self.set_fatigue = []

    def end_session(self):
        if not self.in_session:
            return
        self.in_session = False
        self.sessions += 1
        for i in range(4):
            self.C[3][i] = 0.0
            self.C[i][3] = 0.0
        self.m[3] = 0.0
        self.history.append((self.day, self.m[0], math.sqrt(max(self.C[0][0], 0.0))))

    # -- fatigue intra-séance
    def fatigue_now(self, p=P):
        """Perte relative de capacité pour la série à venir."""
        total = 0.0
        n = len(self.set_fatigue)
        for i, f in enumerate(self.set_fatigue):
            age = n - 1 - i
            total += f * (p['set_fatigue_recovery'] ** (age / 2.0))
        return min(total, 0.8)

    def note_set_fatigue(self, rir, rest, p=P):
        self.set_fatigue.append(set_fatigue_of(rir, rest, p))

    # -- courbe
    def k(self):
        return math.exp(self.m[2])

    def g_ref(self):
        return math.log(1.0 + (self.n_ref - 1.0) / self.k())

    def _h(self, n_eff):
        """(prédiction du ln de la charge soulevable n_eff fois, jacobien)."""
        k = self.k()
        u = (max(n_eff, 1.0) - 1.0) / k
        ur = (self.n_ref - 1.0) / k
        h = self.m[0] + self.m[3] - math.log(1.0 + u) + math.log(1.0 + ur)
        H = [1.0, 0.0, u / (1.0 + u) - ur / (1.0 + ur), 1.0]
        return h, H, u

    def reps_possible(self, log_load, shift=0.0):
        """Répétitions possibles (frais) à la charge donnée, pour une
        capacité du jour décalée de `shift` (quantile)."""
        k = self.k()
        return 1.0 + k * (math.exp(self.m[0] + self.m[3] + shift + self.g_ref() - log_load) - 1.0)

    def log_load_for(self, n, shift=0.0):
        k = self.k()
        return self.m[0] + self.m[3] + shift + self.g_ref() - math.log(1.0 + (max(n, 1.0) - 1.0) / k)

    # -- observation
    def observe_load(self, log_load, n, n_sd, fatigue, p=P, bound=False, learn_k=False, upper=False):
        """Série à charge log_load, n répétitions jusqu'à l'échec estimées
        (écart-type n_sd). bound : borne inférieure seulement. learn_k :
        l'observation met à jour k (n connu précisément) ; sinon k est un
        état « considéré » (Schmidt-Kalman) : son incertitude compte, il ne
        bouge pas."""
        k = self.k()
        scale = 1.0 / max(1e-6, (1.0 - fatigue))
        h, H, u = self._h(max(n, 1.0) * scale)
        slope = scale / (k * (1.0 + u))
        R = sq(n_sd * slope) + sq(p['obs_floor'])
        if bound and upper:
            # « au plus n » : la même contrainte, de l'autre côté
            self._lower_bound([-x for x in H], log_load - h, R, learn_k)
        elif bound:
            self._lower_bound(H, h - log_load, R, learn_k)
        else:
            self._update(H, log_load - h, R, learn_k)
        self.m[2] = min(math.log(p['k_max']), max(math.log(p['k_min']), self.m[2]))
        self.sets += 1

    def _gain(self, H, R, learn_k):
        CH = [sum(self.C[i][j] * H[j] for j in range(4)) for i in range(4)]
        S = sum(H[i] * CH[i] for i in range(4)) + R
        K = [c / S for c in CH]
        if not learn_k:
            K[2] = 0.0
        return K, S

    def _joseph(self, K, H, R):
        """C ← (I − KH) C (I − KH)ᵀ + K R Kᵀ, valable pour tout gain."""
        A = [[(1.0 if i == j else 0.0) - K[i] * H[j] for j in range(4)] for i in range(4)]
        AC = [[sum(A[i][k] * self.C[k][j] for k in range(4)) for j in range(4)] for i in range(4)]
        self.C = [[sum(AC[i][k] * A[j][k] for k in range(4)) + K[i] * R * K[j] for j in range(4)]
                  for i in range(4)]
        _sym(self.C)

    def _update(self, H, innov, R, learn_k):
        K, S = self._gain(H, R, learn_k)
        for i in range(4):
            self.m[i] += K[i] * innov
        self._joseph(K, H, R)

    def _lower_bound(self, H, margin, R, learn_k):
        """Contrainte H·m + ε ≥ y, ε ~ N(0, R) ; margin = H·m − y. Moments
        de la loi tronquée (Tallis 1961) : la moyenne se déplace de
        K·√S·λ, la covariance fait la part λ(a + λ) d'une mise à jour
        complète."""
        K, S = self._gain(H, R, learn_k)
        s = math.sqrt(S)
        a = margin / s
        cdf = norm_cdf(a)
        lam = -a if cdf < 1e-300 else norm_pdf(a) / cdf
        for i in range(4):
            self.m[i] += K[i] * s * lam
        w = min(1.0, max(0.0, lam * (a + lam)))
        if w > 0.0:
            old = [row[:] for row in self.C]
            self._joseph(K, H, R)
            for i in range(4):
                for j in range(4):
                    self.C[i][j] = (1.0 - w) * old[i][j] + w * self.C[i][j]
            _sym(self.C)

    def observe_direct(self, log_capacity, sd, p=P, bound=False):
        """Capacité observée directement (répétitions ou secondes max)."""
        h = self.m[0] + self.m[3]
        H = [1.0, 0.0, 0.0, 1.0]
        R = sq(sd) + sq(p['obs_floor'])
        if bound:
            self._lower_bound(H, h - log_capacity, R, False)
        else:
            self._update(H, log_capacity - h, R, False)
        self.sets += 1

    # -- lecture
    def load_sd(self, n, with_day=True):
        """Écart-type du ln de la charge soulevable n fois (niveau, k et,
        si with_day, effet de jour)."""
        _, H, _ = self._h(n)
        if not with_day:
            H = [H[0], H[1], H[2], 0.0]
        var = 0.0
        for i in range(4):
            for j in range(4):
                var += H[i] * self.C[i][j] * H[j]
        return math.sqrt(max(var, 0.0))

    def one_rm(self):
        """(1RM, écart-type relatif) hors effet de jour."""
        return math.exp(self.m[0] + self.g_ref()), self.load_sd(1.0, False)


def set_fatigue_of(rir, rest, p=P):
    """Perte relative de répétitions possibles laissée par une série finie à
    `rir` répétitions de l'échec, après `rest` secondes de repos."""
    base = p['set_fatigue_fail'] * math.exp(-max(rest, 30.0) / p['set_fatigue_rest_tau'])
    return base * math.exp(-max(rir, 0.0) / p['set_fatigue_rir_scale'])


def _fcft(F, C):
    n = len(C)
    FC = [[sum(F[i][k] * C[k][j] for k in range(n)) for j in range(n)] for i in range(n)]
    return [[sum(FC[i][k] * F[j][k] for k in range(n)) for j in range(n)] for i in range(n)]


def _sym(C):
    n = len(C)
    for i in range(n):
        for j in range(i + 1, n):
            v = 0.5 * (C[i][j] + C[j][i])
            C[i][j] = v
            C[j][i] = v
        if C[i][i] < 1e-12:
            C[i][i] = 1e-12


def planned_fatigue(set_index, rir, rest, p=P):
    """Fatigue prévue avant la série `set_index` quand les précédentes
    finissent à `rir` répétitions de l'échec avec `rest` secondes de repos."""
    f = set_fatigue_of(rir, rest, p)
    total = 0.0
    for i in range(set_index):
        total += f * (p['set_fatigue_recovery'] ** ((set_index - 1 - i) / 2.0))
    return min(total, 0.8)
