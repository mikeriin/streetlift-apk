# -*- coding: utf-8 -*-
"""Outils numériques de Koach 1.0. Chaque fonction est écrite avec des
boucles de longueur fixe et des opérations élémentaires, pour être portée
ligne pour ligne en Dart (parité à 1e-9, contrat § 9)."""
import math

SQRT2 = 1.4142135623730951
SQRT_PI = 1.7724538509055159
SQRT_2PI = 2.5066282746310002
M32 = 0xFFFFFFFF


def erfc(x):
    """Fonction d'erreur complémentaire, précision relative ~1e-15.

    |x| < 2 : série à termes positifs erf(x) = 2/sqrt(pi) e^{-x²} Σ 2^n
    x^{2n+1} / (1·3·…·(2n+1)) (80 termes) ; sinon fraction continue de
    Laplace évaluée à rebours (200 étages)."""
    z = -x if x < 0 else x
    if z < 2.0:
        term = z
        total = z
        for n in range(1, 80):
            term = term * 2.0 * z * z / (2 * n + 1)
            total += term
        erf = 2.0 / SQRT_PI * math.exp(-z * z) * total
        value = 1.0 - erf
    else:
        f = 0.0
        for k in range(200, 0, -1):
            f = (k / 2.0) / (z + f)
        value = math.exp(-z * z) / SQRT_PI / (z + f)
    return value if x >= 0 else 2.0 - value


def norm_pdf(a):
    return math.exp(-0.5 * a * a) / SQRT_2PI


def norm_cdf(a):
    return 0.5 * erfc(-a / SQRT2)


def norm_sf(a):
    """1 - Φ(a), précis dans la queue droite."""
    return 0.5 * erfc(a / SQRT2)


def norm_ppf(p):
    """Quantile de la loi normale (Acklam, puis un pas de Halley)."""
    if p <= 0.0:
        return -math.inf
    if p >= 1.0:
        return math.inf
    a = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
         1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
    b = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
         6.680131188771972e+01, -1.328068155288572e+01]
    c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
    d = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
         3.754408661907416e+00]
    plow = 0.02425
    if p < plow:
        q = math.sqrt(-2 * math.log(p))
        x = (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / \
            ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
    elif p <= 1 - plow:
        q = p - 0.5
        r = q * q
        x = (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q / \
            (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)
    else:
        q = math.sqrt(-2 * math.log(1 - p))
        x = -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) / \
            ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1)
    e = norm_cdf(x) - p
    u = e * SQRT_2PI * math.exp(x * x / 2)
    return x - u / (1 + x * u / 2)


def interval_moments(m, v, s2, a, b):
    """Mise à jour par appariement des moments (filtrage à densité supposée)
    d'une variable u ~ N(m, v) quand on observe que u + e tombe dans [a, b],
    e ~ N(0, s2). a peut valoir -inf, b +inf.

    Renvoie (logZ, m', v') : log-vraisemblance marginale, moyenne et variance
    a posteriori de u. C'est la vraisemblance d'une catégorie du modèle de
    réponse graduée de Samejima en forme ogive normale."""
    t2 = v + s2
    t = math.sqrt(t2)
    lo = -math.inf if a == -math.inf else (a - m) / t
    hi = math.inf if b == math.inf else (b - m) / t
    # Masse de l'intervalle, calculée du côté où elle est précise.
    if lo == -math.inf and hi == math.inf:
        return 0.0, m, v
    if lo > 0:
        plo = norm_sf(lo)
        phi = 0.0 if hi == math.inf else norm_sf(hi)
        z = plo - phi
    else:
        plo = 0.0 if lo == -math.inf else norm_cdf(lo)
        phi = 1.0 if hi == math.inf else norm_cdf(hi)
        z = phi - plo
    dlo = 0.0 if lo == -math.inf else norm_pdf(lo)
    dhi = 0.0 if hi == math.inf else norm_pdf(hi)
    if z < 1e-280:
        # Observation à plus de ~37 écarts-types : on la ramène à la borne
        # la plus proche (mise à jour ponctuelle), sans faire diverger l'état.
        target = a if (lo > 0 or hi == math.inf) else b
        if lo <= 0 and hi < 0:
            target = b
        gain = v / t2
        return -640.0, m + gain * (target - m), v - gain * v
    r1 = (dlo - dhi) / z
    alo = 0.0 if lo == -math.inf else lo * dlo
    ahi = 0.0 if hi == math.inf else hi * dhi
    r2 = (alo - ahi) / z
    m2 = m + v / t * r1
    v2 = v - v * v / t2 * (r1 * r1 - r2)
    if v2 < 1e-12 * v:
        v2 = 1e-12 * v
    return math.log(z), m2, v2


def _category_mass(a, b, u, t):
    """P(a <= u + e <= b), e ~ N(0, t²)."""
    if a == -math.inf:
        return 1.0 if b == math.inf else 0.5 * math.erfc(-(b - u) / t / SQRT2)
    if b == math.inf:
        return 0.5 * math.erfc((a - u) / t / SQRT2)
    lo = (a - u) / t
    hi = (b - u) / t
    if lo > 0:
        like = 0.5 * (math.erfc(lo / SQRT2) - math.erfc(hi / SQRT2))
    else:
        like = 0.5 * (math.erfc(-hi / SQRT2) - math.erfc(-lo / SQRT2))
    return like if like > 0.0 else 0.0


def category_moments(m, v, a, b, noise_var, steps=52, span=6.5, gross=0.0, gross_sd=0.0):
    """Appariement des moments d'une variable u ~ N(m, v) quand on observe
    que u + e tombe dans [a, b], avec un bruit dont la variance dépend de u :
    e ~ N(0, noise_var(u)). Quadrature sur une grille fixe de 2·[steps] + 1
    points entre m ± [span] écarts-types (trapèzes : convergence
    géométrique pour un intégrande lisse).

    [gross] > 0 ajoute une queue lourde : avec cette probabilité, l'erreur
    a un écart-type augmenté de [gross_sd] (erreur grossière de notation).

    Renvoie (logZ, m', v') comme `interval_moments`, dont c'est la
    généralisation (bruit constant : mêmes valeurs à la précision de la
    grille)."""
    sd = math.sqrt(v)
    if sd <= 0.0:
        return 0.0, m, v
    h = span / steps
    sw = 0.0
    s0 = 0.0
    s1 = 0.0
    s2 = 0.0
    for i in range(-steps, steps + 1):
        z = i * h
        u = m + sd * z
        w = math.exp(-0.5 * z * z)
        nv = noise_var(u)
        like = _category_mass(a, b, u, math.sqrt(nv))
        if gross > 0.0:
            like = (1.0 - gross) * like + gross * _category_mass(a, b, u, math.sqrt(nv + gross_sd * gross_sd))
        sw += w
        wl = w * like
        s0 += wl
        s1 += wl * z
        s2 += wl * z * z
    if s0 < 1e-280 * sw:
        return interval_moments(m, v, noise_var(m), a, b)
    mz = s1 / s0
    vz = s2 / s0 - mz * mz
    if vz < 1e-12:
        vz = 1e-12
    return math.log(s0 / sw), m + sd * mz, v * vz


def point_moments(m, v, s2, y):
    """Observation ponctuelle y = u + e, e ~ N(0, s2) (Kalman scalaire)."""
    t2 = v + s2
    gain = v / t2
    d = y - m
    logz = -0.5 * (math.log(2 * math.pi * t2) + d * d / t2)
    return logz, m + gain * d, v - gain * v


class Mulberry32(object):
    """Générateur seedé de Koach (mulberry32, comme L7 et le banc)."""

    __slots__ = ('state',)

    def __init__(self, seed):
        self.state = seed & M32

    def next(self):
        self.state = (self.state + 0x6D2B79F5) & M32
        t = self.state
        t = ((t ^ (t >> 15)) * (t | 1)) & M32
        t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & M32)) & M32
        return ((t ^ (t >> 14)) & M32) / 4294967296.0

    def gauss(self):
        """Normale centrée réduite par inversion (un seul tirage uniforme :
        les nombres aléatoires communs restent alignés entre plans)."""
        u = self.next()
        if u < 1e-12:
            u = 1e-12
        return norm_ppf(u)


def fnv1a32(text):
    h = 0x811C9DC5
    for byte in text.encode('utf-8'):
        h ^= byte
        h = (h * 0x01000193) & M32
    return h


def dart_round(x):
    return int(math.floor(x + 0.5)) if x >= 0 else -int(math.floor(-x + 0.5))


def clamp(x, low, high):
    return low if x < low else (high if x > high else x)
