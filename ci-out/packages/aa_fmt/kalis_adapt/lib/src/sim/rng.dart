/// Hasard seedé du simulateur : aucune source implicite.
library;

import 'package:kalis_plan/kalis_plan.dart' show fnv1a32, fnvMix;

import '../numeric.dart';

/// Suite pseudo-aléatoire mulberry32, entièrement déterminée par sa
/// graine ; lois uniforme et normale (méthode polaire de Marsaglia, qui
/// n'utilise que le logarithme et la racine carrée).
final class SimRandom {
  /// Suite de graine [seed].
  SimRandom(int seed) : _state = seed & 0xFFFFFFFF;

  /// Suite propre à l'événement [key] pour la graine [seed] : deux
  /// politiques comparées sur la même graine tirent les mêmes aléas pour
  /// le même événement (nombres aléatoires communs).
  factory SimRandom.of(int seed, String key) =>
      SimRandom(fnvMix(fnv1a32(key), seed));

  int _state;

  /// Nombre uniforme de [0 ; 1[.
  double next() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  /// Nombre de loi normale centrée réduite.
  double gauss() {
    for (var i = 0; i < 64; i++) {
      final u = 2 * next() - 1;
      final v = 2 * next() - 1;
      final s = u * u + v * v;
      if (s > 1e-12 && s < 1) {
        return u * sqrt(-2 * ln(s) / s);
      }
    }
    return 0;
  }
}
