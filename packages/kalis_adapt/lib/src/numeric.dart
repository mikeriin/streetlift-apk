/// Outils numériques : logarithme et exponentielle portables, loi normale,
/// courbe répétitions ↔ charge, conversions de notes.
library;

import 'dart:math' as math;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show stableExp, stableLn;

/// Logarithme népérien de [x] > 0 (opérations élémentaires seulement : même
/// résultat sur toute machine, voir `kalis_plan`).
double ln(double x) => stableLn(x);

/// Exponentielle de [x] (opérations élémentaires seulement).
double exp(double x) => x <= 0 ? stableExp(x) : 1 / stableExp(-x);

/// Racine carrée (IEEE 754 : exacte sur toute machine).
double sqrt(double x) => math.sqrt(x);

/// Carré de [x].
double sq(double x) => x * x;

/// [x] ramené dans [low ; high].
double clampDouble(double x, double low, double high) =>
    x < low ? low : (x > high ? high : x);

/// Fonction d'erreur complémentaire (Numerical Recipes, `erfcc` : erreur
/// relative inférieure à 1,2e-7).
double erfc(double x) {
  final z = x.abs();
  final t = 1 / (1 + 0.5 * z);
  final poly =
      -z * z -
      1.26551223 +
      t *
          (1.00002368 +
              t *
                  (0.37409196 +
                      t *
                          (0.09678418 +
                              t *
                                  (-0.18628806 +
                                      t *
                                          (0.27886807 +
                                              t *
                                                  (-1.13520398 +
                                                      t *
                                                          (1.48851587 +
                                                              t *
                                                                  (-0.82215223 +
                                                                      t *
                                                                          0.17087277))))))));
  final ans = t * exp(poly);
  return x >= 0 ? ans : 2 - ans;
}

const double _sqrt2 = 1.4142135623730951;
const double _sqrt2Pi = 2.5066282746310002;

/// Densité de la loi normale centrée réduite.
double normPdf(double a) => exp(-0.5 * a * a) / _sqrt2Pi;

/// Fonction de répartition de la loi normale centrée réduite.
double normCdf(double a) => 0.5 * erfc(-a / _sqrt2);

/// `ln` de la part du 1RM soulevable [n] fois (n ≥ 1) pour une courbe de
/// paramètre [k] : `−ln(1 + (n − 1) / k)`.
double logShare(double n, double k) {
  final m = n < 1 ? 1.0 : n;
  return -ln(1 + (m - 1) / k);
}

/// Répétitions possibles à une charge telle que `ln(1RM / charge)` vaut
/// [logRatio], pour une courbe de paramètre [k].
double repsAt(double logRatio, double k) => 1 + k * (exp(logRatio) - 1);

/// RIR d'une note en flammes (table de `kalis_core`).
double rirOfFlames(int flames) => Flames.toRir(flames);

/// Note en flammes d'un RIR, borné à l'échelle.
int flamesOfRir(double rir) => Flames.fromRir(rir < 0 ? 0.0 : rir);

/// [value] arrondi à [decimals] décimales (sorties JSON stables).
double roundTo(double value, int decimals) {
  var scale = 1.0;
  for (var i = 0; i < decimals; i++) {
    scale *= 10;
  }
  return (value * scale).roundToDouble() / scale;
}
