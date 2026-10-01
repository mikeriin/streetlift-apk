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
