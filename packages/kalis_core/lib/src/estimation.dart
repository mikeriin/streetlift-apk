/// Conversions des tests guidés en valeurs du profil (0.4.0) : estimation
/// d'un maximum à partir d'une série sous-maximale, prédiction d'un temps de
/// course d'une distance à une autre. Formules et incertitudes :
/// `docs/PARCOURS_V3.md`, § tests guidés. Fonctions pures.
library;

/// Estimation d'un maximum et son incertitude.
final class OneRmEstimate {
  /// Maximum [valueKg] estimé à plus ou moins [relativeError] près.
  const OneRmEstimate(this.valueKg, this.relativeError);

  /// 1RM estimé, dans la même convention de charge que la charge fournie.
  final double valueKg;

  /// Incertitude relative (un écart-type), en part de [valueKg].
  final double relativeError;

  /// Borne basse à un écart-type.
  double get lowKg => valueKg * (1 - relativeError);

  /// Borne haute à un écart-type.
  double get highKg => valueKg * (1 + relativeError);
}

/// Estimation du 1RM à partir d'une série de [reps] répétitions à la charge
/// [loadKg], finie avec [rir] répétitions en réserve.
///
/// Équation de Brzycki (1993) : `1RM = charge × 36 / (37 − r)`, avec
/// `r = reps + rir`. Pour un exercice au poids du corps ou lesté, [loadKg]
/// est la charge TOTALE (charge externe + fraction × poids de corps) : le
/// lest maximal s'obtient ensuite par [externalFromTotal].
///
/// Rend `null` quand l'estimation n'est pas défendable : charge non
/// positive, moins d'une répétition, ou plus de 10 répétitions réserve
/// comprise (Reynolds et al. 2006 ; Mayhew et al. 2008).
///
/// Incertitude (choix raisonné adossé à Nuzzo et al. 2024, Halperin et al.
/// 2022 et Grgic et al. 2020) : 4 % pour un maximum mesuré (1 répétition,
/// réserve nulle) ; 5 % pour une série au maximum de 2 à 6 répétitions ;
/// 7,5 % avec une réserve déclarée ou de 7 à 10 répétitions ; 10 % pour
/// une série de plusieurs répétitions ou avec réserve d'un [novice] (moins
/// de six mois de pratique : la réserve et l'échec sont mal estimés).
OneRmEstimate? estimateOneRm({
  required double loadKg,
  required int reps,
  double rir = 0,
  bool novice = false,
}) {
  if (!loadKg.isFinite || loadKg <= 0 || reps < 1) {
    return null;
  }
  if (!rir.isFinite || rir < 0) {
    return null;
  }
  final effective = reps + rir;
  if (effective > 10) {
    return null;
  }
  final value = effective <= 1 ? loadKg : loadKg * 36 / (37 - effective);
  final double error;
  if (reps == 1 && rir == 0) {
    error = 0.04;
  } else if (novice) {
    error = 0.10;
  } else if (rir > 0 || effective > 6) {
    error = 0.075;
  } else {
    error = 0.05;
  }
  return OneRmEstimate(value, error);
}

/// Charge totale d'un exercice au poids du corps ou lesté : charge externe
/// [externalKg] + [bodyweightFraction] × [bodyWeightKg] (la fraction est
/// `CatalogExercise.bodyweightFraction`).
double totalFromExternal({
  required double externalKg,
  required double bodyWeightKg,
  required double bodyweightFraction,
}) {
  return externalKg + bodyweightFraction * bodyWeightKg;
}

/// Charge externe (lest) correspondant à une charge totale [totalKg].
double externalFromTotal({
  required double totalKg,
  required double bodyWeightKg,
  required double bodyweightFraction,
}) {
  return totalKg - bodyweightFraction * bodyWeightKg;
}

/// Temps prédit sur [targetMeters] à partir d'un temps [seconds] réalisé
/// sur [meters] : formule de Riegel (1981), `T2 = T1 × (D2 / D1)^1,06`.
///
/// Rend `null` hors du domaine où la formule est calibrée : effort de
/// départ ou effort prédit de moins de 3,5 minutes ou de plus de
/// 230 minutes (Riegel 1981), ou distance prédite au-delà du
/// semi-marathon (21 097,5 m), où la formule est trop optimiste pour les
/// coureurs amateurs (Vickers et Vertosick 2016).
double? riegelSeconds({
  required double seconds,
  required double meters,
  required double targetMeters,
}) {
  if (!seconds.isFinite || !meters.isFinite || !targetMeters.isFinite) {
    return null;
  }
  if (seconds <= 0 || meters <= 0 || targetMeters <= 0) {
    return null;
  }
  if (targetMeters > 21097.5) {
    return null;
  }
  const low = 3.5 * 60;
  const high = 230.0 * 60;
  if (seconds < low || seconds > high) {
    return null;
  }
  final ratio = targetMeters / meters;
  // Hors de ces bornes, l'effort prédit sort de toute façon du domaine.
  if (!ratio.isFinite || ratio < 1e-3 || ratio > 1e3) {
    return null;
  }
  final predicted = seconds * _pow(ratio, 1.06);
  if (predicted < low || predicted > high) {
    return null;
  }
  return predicted;
}

/// Vitesse moyenne, en mètres par seconde, d'un test de course en durée
/// fixe (test de 6 minutes : [meters] parcourus en [seconds]). `null` si
/// une valeur n'est pas strictement positive.
double? trialSpeed({required double meters, required double seconds}) {
  if (!meters.isFinite || !seconds.isFinite || meters <= 0 || seconds <= 0) {
    return null;
  }
  return meters / seconds;
}

// x^y pour x > 0, par exponentielle et logarithme calculés ici (opérations
// élémentaires seulement) : le résultat ne dépend pas de la bibliothèque
// mathématique de la machine (même règle que kalis_plan).
double _pow(double x, double y) => _exp(y * _ln(x));

double _ln(double x) {
  // Réduction à m dans [1/√2 ; √2] : x = m × 2^k, puis série de atanh.
  var m = x;
  var k = 0;
  while (m > 1.4142135623730951) {
    m /= 2;
    k++;
  }
  while (m < 0.7071067811865476) {
    m *= 2;
    k--;
  }
  final t = (m - 1) / (m + 1);
  final t2 = t * t;
  var term = t;
  var sum = 0.0;
  for (var n = 1; n <= 41; n += 2) {
    sum += term / n;
    term *= t2;
  }
  return 2 * sum + k * 0.6931471805599453;
}

double _exp(double x) {
  // Réduction : x = k × ln 2 + r, |r| ≤ ln 2 / 2, puis série de Taylor.
  final k = (x / 0.6931471805599453).round();
  final r = x - k * 0.6931471805599453;
  var term = 1.0;
  var sum = 1.0;
  for (var n = 1; n <= 24; n++) {
    term *= r / n;
    sum += term;
  }
  var result = sum;
  if (k >= 0) {
    for (var i = 0; i < k; i++) {
      result *= 2;
    }
  } else {
    for (var i = 0; i < -k; i++) {
      result /= 2;
    }
  }
  return result;
}
