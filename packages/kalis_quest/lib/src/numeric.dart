/// Outils numériques de `kalis_quest` : logarithme et exponentielle
/// portables, loi normale, hachage stable et tirages seedés.
///
/// Les montants d'XP et de Krédits n'utilisent que les opérations
/// élémentaires et la racine carrée (exactes en IEEE 754) : ils sont les
/// mêmes sur toute machine.
library;

import 'dart:convert';
import 'dart:math' as math;

const double _ln2 = 0.6931471805599453;

/// Exponentielle (réduction par moitiés, série de Taylor, carrés
/// successifs — même écriture que `kalis_plan`, opérations élémentaires
/// seulement).
double exp(double x) {
  if (x.isNaN) {
    return double.nan;
  }
  if (x > 0) {
    return x > 700 ? double.infinity : 1 / exp(-x);
  }
  if (x < -700) {
    return 0;
  }
  var r = x;
  var halvings = 0;
  while (r < -0.125) {
    r *= 0.5;
    halvings++;
  }
  var term = 1.0;
  var sum = 1.0;
  for (var n = 1; n <= 14; n++) {
    term = term * r / n;
    sum += term;
  }
  for (var i = 0; i < halvings; i++) {
    sum *= sum;
  }
  return sum;
}

/// Logarithme népérien (réduction par puissances de 2, série de l'arc
/// tangente hyperbolique). Zéro et les négatifs rendent moins l'infini.
double ln(double x) {
  if (x.isNaN) {
    return double.nan;
  }
  if (x <= 0) {
    return double.negativeInfinity;
  }
  if (x == double.infinity) {
    return double.infinity;
  }
  var r = x;
  var twos = 0;
  while (r < 0.75) {
    r *= 2;
    twos--;
  }
  while (r >= 1.5) {
    r *= 0.5;
    twos++;
  }
  final z = (r - 1) / (r + 1);
  final z2 = z * z;
  var term = z;
  var sum = z;
  for (var n = 3; n <= 41; n += 2) {
    term *= z2;
    sum += term / n;
  }
  return 2 * sum + twos * _ln2;
}

/// [x] à la puissance [y] ([x] > 0).
double power(double x, double y) => x <= 0 ? 0 : exp(y * ln(x));

/// Racine carrée (IEEE 754 : exacte sur toute machine).
double sqrt(double x) => math.sqrt(x);

/// [x] ramené dans [low ; high].
double clampDouble(double x, double low, double high) =>
    x < low ? low : (x > high ? high : x);

/// [x] ramené dans [low ; high].
int clampInt(int x, int low, int high) => x < low ? low : (x > high ? high : x);

/// [value] arrondi à [decimals] décimales (sorties JSON stables).
double roundTo(double value, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  return (value * scale).roundToDouble() / scale;
}

/// Fonction d'erreur complémentaire (Numerical Recipes, `erfcc` : erreur
/// relative inférieure à 1,2e-7).
double erfc(double x) {
  final z = x.abs();
  final t = 1 / (1 + 0.5 * z);
  const c = <double>[
    -1.26551223,
    1.00002368,
    0.37409196,
    0.09678418,
    -0.18628806,
    0.27886807,
    -1.13520398,
    1.48851587,
    -0.82215223,
    0.17087277,
  ];
  var poly = c[9];
  for (var i = 8; i >= 0; i--) {
    poly = c[i] + t * poly;
  }
  final ans = t * exp(-z * z + poly);
  return x >= 0 ? ans : 2 - ans;
}

/// Fonction de répartition de la loi normale centrée réduite.
double normCdf(double a) => 0.5 * erfc(-a / 1.4142135623730951);

/// Quantile 60 % de la loi normale centrée réduite.
const double z60 = 0.2533471031357997;

/// Quantile 90 % de la loi normale centrée réduite.
const double z90 = 1.2815515655446004;

/// Médiane de [values] (0 si la liste est vide). La liste est triée sur
/// place.
double medianOf(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  values.sort();
  final n = values.length;
  return n.isOdd ? values[n ~/ 2] : (values[n ~/ 2 - 1] + values[n ~/ 2]) / 2;
}

/// Hachage FNV-1a 32 bits de [text] (octets UTF-8).
int fnv1a32(String text) {
  var h = 0x811C9DC5;
  for (final byte in utf8.encode(text)) {
    h ^= byte;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Nombre uniforme de [0 ; 1[ entièrement déterminé par la graine [seed]
/// et la clé [key] (mélange de type mulberry32 sur le hachage) : aucun
/// état, donc aucun effet de l'ordre des appels.
double unitOf(int seed, String key) {
  var state = fnv1a32('$seed|$key');
  state = (state + 0x6D2B79F5) & 0xFFFFFFFF;
  var t = state;
  t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
  t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
  return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
}

/// Entier uniforme de 0 à [bound] − 1 déterminé par [seed] et [key].
int pickOf(int seed, String key, int bound) {
  final i = (unitOf(seed, key) * bound).floor();
  return i >= bound ? bound - 1 : i;
}

/// Jour ISO de la semaine (1 = lundi … 7 = dimanche) du numéro de jour
/// [dayNumber] (jours depuis le 1970-01-01, un jeudi).
int weekdayOf(int dayNumber) => ((dayNumber + 3) % 7 + 7) % 7 + 1;

/// Numéro de jour du lundi de la semaine ISO de [dayNumber].
int mondayOf(int dayNumber) => dayNumber - (weekdayOf(dayNumber) - 1);
