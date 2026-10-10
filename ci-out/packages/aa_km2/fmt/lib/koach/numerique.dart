part of 'koach.dart';

// Outils numériques de Koach (référence `koach/numerique.py`, contrat § 9.3),
// portés ligne pour ligne : boucles de longueur fixe, sommes dans l'ordre
// des indices.

const double sqrt2 = 1.4142135623730951;
const double sqrtPi = 1.7724538509055159;
const double sqrt2Pi = 2.5066282746310002;
const int m32 = 0xFFFFFFFF;

/// Fonction d'erreur complémentaire (série de 80 termes sous 2, fraction
/// continue de Laplace à 200 étages au-delà).
double erfcK(double x) {
  final z = x < 0 ? -x : x;
  double value;
  if (z < 2.0) {
    var term = z;
    var total = z;
    for (var n = 1; n < 80; n++) {
      term = term * 2.0 * z * z / (2 * n + 1);
      total += term;
    }
    final erf = 2.0 / sqrtPi * math.exp(-z * z) * total;
    value = 1.0 - erf;
  } else {
    var f = 0.0;
    for (var k = 200; k > 0; k--) {
      f = (k / 2.0) / (z + f);
    }
    value = math.exp(-z * z) / sqrtPi / (z + f);
  }
  return x >= 0 ? value : 2.0 - value;
}

double normPdfK(double a) => math.exp(-0.5 * a * a) / sqrt2Pi;

double normCdfK(double a) => 0.5 * erfcK(-a / sqrt2);

/// 1 − Φ(a), précis dans la queue droite.
double normSfK(double a) => 0.5 * erfcK(a / sqrt2);

const List<double> _ppfA = [
  -3.969683028665376e+01,
  2.209460984245205e+02,
  -2.759285104469687e+02,
  1.383577518672690e+02,
  -3.066479806614716e+01,
  2.506628277459239e+00,
];
const List<double> _ppfB = [
  -5.447609879822406e+01,
  1.615858368580409e+02,
  -1.556989798598866e+02,
  6.680131188771972e+01,
  -1.328068155288572e+01,
];
const List<double> _ppfC = [
  -7.784894002430293e-03,
  -3.223964580411365e-01,
  -2.400758277161838e+00,
  -2.549732539343734e+00,
  4.374664141464968e+00,
  2.938163982698783e+00,
];
const List<double> _ppfD = [
  7.784695709041462e-03,
  3.224671290700398e-01,
  2.445134137142996e+00,
  3.754408661907416e+00,
];

/// Quantile de la loi normale (Acklam, puis un pas de Halley).
double normPpfK(double p) {
  if (p <= 0.0) return -inf;
  if (p >= 1.0) return inf;
  const a = _ppfA;
  const b = _ppfB;
  const c = _ppfC;
  const d = _ppfD;
  const plow = 0.02425;
  double x;
  if (p < plow) {
    final q = math.sqrt(-2 * math.log(p));
    x =
        (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
        ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  } else if (p <= 1 - plow) {
    final q = p - 0.5;
    final r = q * q;
    x =
        (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  } else {
    final q = math.sqrt(-2 * math.log(1 - p));
    x =
        -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5]) /
        ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
  }
  final e = normCdfK(x) - p;
  final u = e * sqrt2Pi * math.exp(x * x / 2);
  return x - u / (1 + x * u / 2);
}

/// Moments (logZ, m', v') de u ~ N(m, v) quand u + e tombe dans [a, b],
/// e ~ N(0, s2).
(double, double, double) intervalMoments(
  double m,
  double v,
  double s2,
  double a,
  double b,
) {
  final t2 = v + s2;
  final t = math.sqrt(t2);
  final lo = a == -inf ? -inf : (a - m) / t;
  final hi = b == inf ? inf : (b - m) / t;
  if (lo == -inf && hi == inf) {
    return (0.0, m, v);
  }
  double z;
  if (lo > 0) {
    final plo = normSfK(lo);
    final phi = hi == inf ? 0.0 : normSfK(hi);
    z = plo - phi;
  } else {
    final plo = lo == -inf ? 0.0 : normCdfK(lo);
    final phi = hi == inf ? 1.0 : normCdfK(hi);
    z = phi - plo;
  }
  final dlo = lo == -inf ? 0.0 : normPdfK(lo);
  final dhi = hi == inf ? 0.0 : normPdfK(hi);
  if (z < 1e-280) {
    var target = (lo > 0 || hi == inf) ? a : b;
    if (lo <= 0 && hi < 0) {
      target = b;
    }
    final gain = v / t2;
    return (-640.0, m + gain * (target - m), v - gain * v);
  }
  final r1 = (dlo - dhi) / z;
  final alo = lo == -inf ? 0.0 : lo * dlo;
  final ahi = hi == inf ? 0.0 : hi * dhi;
  final r2 = (alo - ahi) / z;
  final m2 = m + v / t * r1;
  var v2 = v - v * v / t2 * (r1 * r1 - r2);
  if (v2 < 1e-12 * v) {
    v2 = 1e-12 * v;
  }
  return (math.log(z), m2, v2);
}

double _categoryMass(double a, double b, double u, double t) {
  if (a == -inf) {
    return b == inf ? 1.0 : 0.5 * erfcK(-(b - u) / t / sqrt2);
  }
  if (b == inf) {
    return 0.5 * erfcK((a - u) / t / sqrt2);
  }
  final lo = (a - u) / t;
  final hi = (b - u) / t;
  double like;
  if (lo > 0) {
    like = 0.5 * (erfcK(lo / sqrt2) - erfcK(hi / sqrt2));
  } else {
    like = 0.5 * (erfcK(-hi / sqrt2) - erfcK(-lo / sqrt2));
  }
  return like > 0.0 ? like : 0.0;
}

/// Appariement des moments à bruit dépendant de u (quadrature, § 5.6).
(double, double, double) categoryMoments(
  double m,
  double v,
  double a,
  double b,
  double Function(double) noiseVar, {
  int steps = 52,
  double span = 6.5,
  double gross = 0.0,
  double grossSd = 0.0,
}) {
  final sd = math.sqrt(v);
  if (sd <= 0.0) {
    return (0.0, m, v);
  }
  var nvMin = noiseVar(m);
  for (final x in [a, b]) {
    if (x != inf && x != -inf) {
      final nx = noiseVar(x);
      if (nx < nvMin) {
        nvMin = nx;
      }
    }
  }
  var large = nvMin > 0.0 ? math.sqrt(nvMin) : 0.0;
  final fini = a != -inf && b != inf;
  if (fini && 0.5 * (b - a) > large) {
    large = 0.5 * (b - a);
  }
  var zlo = -span;
  var zhi = span;
  if (fini) {
    var nvMax = noiseVar(m);
    for (final x in [a, b]) {
      final nx = noiseVar(x);
      if (nx > nvMax) {
        nvMax = nx;
      }
    }
    final tt = math.sqrt(nvMax + (gross > 0.0 ? grossSd * grossSd : 0.0));
    final z1 = (a - 8.0 * tt - m) / sd;
    final z2 = (b + 8.0 * tt - m) / sd;
    if (z1 > zlo) {
      zlo = z1;
    }
    if (z2 < zhi) {
      zhi = z2;
    }
    if (zhi <= zlo) {
      return intervalMoments(m, v, noiseVar(m), a, b);
    }
  }
  var n = 2 * steps;
  if (large > 0.0) {
    final besoin = ((zhi - zlo) * sd / (0.5 * large)).ceil();
    if (besoin > n) {
      n = besoin < 1200 ? besoin : 1200;
    }
  }
  final h = (zhi - zlo) / n;
  var s0 = 0.0;
  var s1 = 0.0;
  var s2 = 0.0;
  for (var i = 0; i < n + 1; i++) {
    final z = zlo + i * h;
    final u = m + sd * z;
    final w = math.exp(-0.5 * z * z);
    final nv = noiseVar(u);
    var like = _categoryMass(a, b, u, math.sqrt(nv));
    if (gross > 0.0) {
      like =
          (1.0 - gross) * like +
          gross * _categoryMass(a, b, u, math.sqrt(nv + grossSd * grossSd));
    }
    final wl = w * like;
    s0 += wl;
    s1 += wl * z;
    s2 += wl * z * z;
  }
  final sw = math.sqrt(2.0 * math.pi) / h;
  if (s0 < 1e-280 * sw) {
    return intervalMoments(m, v, noiseVar(m), a, b);
  }
  final mz = s1 / s0;
  var vz = s2 / s0 - mz * mz;
  if (vz < 1e-12) {
    vz = 1e-12;
  }
  return (math.log(s0 / sw), m + sd * mz, v * vz);
}

/// Observation ponctuelle y = u + e (Kalman scalaire).
(double, double, double) pointMoments(double m, double v, double s2, double y) {
  final t2 = v + s2;
  final gain = v / t2;
  final d = y - m;
  final logz = -0.5 * (math.log(2 * math.pi * t2) + d * d / t2);
  return (logz, m + gain * d, v - gain * v);
}

/// Générateur seedé de Koach (mulberry32).
class Mulberry32 {
  Mulberry32(int seed) : state = seed & m32;

  int state;

  double next() {
    state = (state + 0x6D2B79F5) & m32;
    var t = state;
    t = ((t ^ (t >> 15)) * (t | 1)) & m32;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & m32)) & m32;
    return ((t ^ (t >> 14)) & m32) / 4294967296.0;
  }

  /// Normale centrée réduite par inversion (un seul tirage uniforme).
  double gauss() {
    var u = next();
    if (u < 1e-12) {
      u = 1e-12;
    }
    return normPpfK(u);
  }
}

/// FNV-1a 32 bits sur les octets UTF-8.
int fnv1a32(String text) {
  var h = 0x811C9DC5;
  for (final byte in utf8.encode(text)) {
    h ^= byte;
    h = (h * 0x01000193) & m32;
  }
  return h;
}

int dartRound(double x) => x >= 0 ? (x + 0.5).floor() : -((-x + 0.5).floor());

double clampD(double x, double low, double high) =>
    x < low ? low : (x > high ? high : x);

/// Racine triangulaire inférieure semi-définie (Cholesky en boucles
/// explicites, § 9.3).
List<List<double>> choleskySemi(List<List<double>> s, {double tol = 1e-12}) {
  final k = s.length;
  final l = [for (var i = 0; i < k; i++) List<double>.filled(k, 0.0)];
  var grand = 0.0;
  for (var j = 0; j < k; j++) {
    final v = s[j][j];
    if (v > grand) {
      grand = v;
    }
  }
  final seuil = tol * grand;
  for (var j = 0; j < k; j++) {
    var d = s[j][j];
    for (var q = 0; q < j; q++) {
      d -= l[j][q] * l[j][q];
    }
    if (d <= seuil) {
      continue;
    }
    final r = math.sqrt(d);
    l[j][j] = r;
    for (var i = j + 1; i < k; i++) {
      var x = s[i][j];
      for (var q = 0; q < j; q++) {
        x -= l[i][q] * l[j][q];
      }
      l[i][j] = x / r;
    }
  }
  return l;
}

/// Arrondi portable : floor(x·10ⁿ + 0,5)/10ⁿ en flottants.
double arrondi(double x, [int decimales = 0]) {
  final f = math.pow(10.0, decimales).toDouble();
  return (x * f + 0.5).floorToDouble() / f;
}

/// P(a ≤ u + e ≤ b), e ~ N(0, t²) (lecture publique pour les tests de
/// parité).
double categoryMassK(double a, double b, double u, double t) =>
    _categoryMass(a, b, u, t);
