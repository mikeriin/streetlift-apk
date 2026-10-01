/// Hachage stable et suite pseudo-aléatoire seedée : aucun hasard implicite.
library;

import 'dart:convert';

/// Hachage FNV-1a 32 bits de [text] (octets UTF-8).
///
/// Sert au départage déterministe : sa valeur ne dépend que du texte, donc
/// pas de l'ordre des appels.
int fnv1a32(String text) {
  var h = 0x811C9DC5;
  for (final byte in utf8.encode(text)) {
    h ^= byte;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

/// Mélange l'entier [value] (4 octets, poids faible d'abord) dans [hash].
int fnvMix(int hash, int value) {
  var h = hash & 0xFFFFFFFF;
  var v = value & 0xFFFFFFFF;
  for (var i = 0; i < 4; i++) {
    h ^= v & 0xFF;
    h = (h * 0x01000193) & 0xFFFFFFFF;
    v >>= 8;
  }
  return h;
}

/// Logarithme népérien de 2.
const double _ln2 = 0.6931471805599453;

/// Exponentielle de [x] pour [x] ≤ 0, calculée avec les seules opérations
/// élémentaires IEEE 754 (réduction par moitiés, série de Taylor, carrés
/// successifs) : contrairement à `dart:math`, qui s'en remet à la
/// bibliothèque mathématique de la plateforme, le résultat est le même bit
/// pour bit sur toute machine. Erreur relative inférieure à 1e-12 sur
/// [-40 ; 0] ; 0 en dessous de −700.
double stableExp(double x) {
  if (x >= 0) {
    return 1;
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

/// Logarithme népérien de [x] > 0 avec les seules opérations élémentaires
/// IEEE 754 (réduction par puissances de 2, série de l'arc tangente
/// hyperbolique) : même résultat bit pour bit sur toute machine.
double stableLn(double x) {
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

/// Suite pseudo-aléatoire xorshift32 (Marsaglia 2003), entièrement
/// déterminée par sa graine.
final class SeededRandom {
  /// Suite de graine [seed] (ramenée à 32 bits ; 0 est remplacé).
  SeededRandom(int seed) : _state = _normalize(seed);

  static int _normalize(int seed) =>
      (seed & 0xFFFFFFFF) == 0 ? 0x9E3779B9 : seed & 0xFFFFFFFF;

  int _state;

  /// Repart de la graine [seed].
  void reset(int seed) {
    _state = _normalize(seed);
  }

  /// Entier suivant, de 1 à 2^32 − 1.
  int nextU32() {
    var x = _state;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    _state = x;
    return x;
  }

  /// Entier uniforme de 0 à [bound] − 1 ([bound] ≥ 1).
  int nextInt(int bound) => nextU32() % bound;

  /// Nombre de [0 ; 1[.
  double nextDouble() => (nextU32() - 1) / 4294967295.0;
}
