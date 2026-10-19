/// Modèle forme / fatigue (impulsion-réponse) par groupe musculaire et
/// global, et forme du jour tirée du bilan santé.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show MuscleGroup;

import 'book.dart';
import 'numeric.dart';
import 'params.dart';

/// Poids d'une série dans l'impulsion d'entraînement : plus elle finit
/// près de l'échec, plus elle coûte.
double effortWeight(double rir, {required bool failed}) {
  final r = clampDouble(rir, 0, 6);
  var w = 1 - r / 8;
  if (w < 0.3) {
    w = 0.3;
  }
  return failed ? w + 0.25 : w;
}

/// État du modèle impulsion-réponse.
final class FatigueModel {
  /// Modèle au repos.
  FatigueModel(AdaptParams p) : gainVar = p.fatigueGainSd * p.fatigueGainSd;

  FatigueModel._copy(FatigueModel o) : gainVar = o.gainVar {
    chronic = o.chronic;
    fitness = o.fitness;
    day = o.day;
    gain = o.gain;
    for (var i = 0; i < acute.length; i++) {
      acute[i] = o.acute[i];
    }
  }

  /// Copie indépendante.
  FatigueModel fork() => FatigueModel._copy(this);

  /// Fatigue aiguë par groupe musculaire (`MuscleGroup.index`).
  final List<double> acute = List<double>.filled(MuscleGroup.values.length, 0);

  /// Fatigue accumulée, globale.
  double chronic = 0;

  /// Forme (charge d'entraînement lissée sur le long terme).
  double fitness = 0;

  /// Jour de la dernière mise à jour.
  int? day;

  /// Sensibilité individuelle (multiplie l'effet de la fatigue), apprise
  /// par les résidus de performance.
  double gain = 1;

  /// Variance de [gain].
  double gainVar;

  /// Laisse décroître les trois composantes jusqu'au jour [toDay].
  void advance(int toDay, AdaptParams p) {
    final from = day;
    if (from == null) {
      day = toDay;
      return;
    }
    final dt = toDay - from;
    if (dt <= 0) {
      return;
    }
    final ea = exp(-dt / p.tauAcute);
    for (var i = 0; i < acute.length; i++) {
      acute[i] *= ea;
    }
    chronic *= exp(-dt / p.tauChronic);
    fitness *= exp(-dt / p.tauFitness);
    day = toDay;
  }

  /// Ajoute l'impulsion d'une série de l'exercice [info], de poids [weight].
  void add(ExerciseInfo info, double weight) {
    final local = weight * info.exercise.localFatigue / 3;
    for (var i = 0; i < info.groups.length; i++) {
      acute[info.groups[i].index] += local * info.groupWeights[i];
    }
    final systemic = weight * info.exercise.systemicFatigue / 3;
    chronic += systemic;
    fitness += systemic;
  }

  /// Effet brut de la fatigue sur `ln` capacité pour l'exercice [info]
  /// (négatif), avant le gain individuel.
  double rawShift(ExerciseInfo info, AdaptParams p) {
    var a = 0.0;
    var total = 0.0;
    for (var i = 0; i < info.groups.length; i++) {
      a += acute[info.groups[i].index] * info.groupWeights[i];
      total += info.groupWeights[i];
    }
    if (total > 0) {
      a /= total;
    }
    return -(p.kappaAcute * a + p.kappaChronic * chronic);
  }

  /// Affine le gain individuel : [residual] est l'effet de jour observé,
  /// [rawDeviation] l'écart de la fatigue brute à son niveau habituel ;
  /// modèle `résidu = gain × écart + bruit` de variance [variance].
  void learn(double rawDeviation, double residual, double variance) {
    if (rawDeviation.abs() < 1e-5) {
      return;
    }
    final s = rawDeviation * rawDeviation * gainVar + variance;
    final k = gainVar * rawDeviation / s;
    gain += k * (residual - rawDeviation * gain);
    gainVar *= 1 - k * rawDeviation;
    gain = clampDouble(gain, 0, 4);
  }

  /// Fatigue globale (aiguë moyenne + accumulée), unités du modèle.
  double get fatigueLevel {
    var a = 0.0;
    for (final x in acute) {
      a += x;
    }
    return a / acute.length + chronic;
  }

  /// Effet global de la fatigue sur `ln` capacité (négatif).
  double globalShift(AdaptParams p) {
    var a = 0.0;
    for (final x in acute) {
      a += x;
    }
    return -gain * (p.kappaAcute * a / acute.length + p.kappaChronic * chronic);
  }
}

/// Forme du jour tirée du bilan santé : effet sur `ln` capacité (négatif
/// ou nul) et palier d'ajustement.
final class HealthReading {
  /// Lecture d'effet [shift] et de palier [level].
  const HealthReading(this.shift, this.level, this.answered);

  /// Aucun bilan.
  static const HealthReading none = HealthReading(0, 0, 0);

  /// Effet sur `ln` capacité, de [AdaptParams.healthFloor] à 0.
  final double shift;

  /// Palier : 0 rien, 1 séance allégée, 2 séance nettement allégée.
  final int level;

  /// Nombre de réponses prises en compte.
  final int answered;
}

/// Lit le bilan [check]. **Seules les réponses données comptent** : une
/// réponse absente n'ajoute aucun terme (D5.8).
HealthReading readHealth(HealthCheck? check, AdaptParams p) {
  if (check == null) {
    return HealthReading.none;
  }
  var answered = 0;
  var general = 0.0;
  final overall = check.overall;
  if (overall != null) {
    answered++;
    if (overall < p.healthNeutral) {
      general = -p.healthPerPoint * (p.healthNeutral - overall);
    }
  }
  var detail = 0.0;
  final hours = check.sleepHours;
  if (hours != null) {
    answered++;
    if (hours < p.sleepHoursNeutral) {
      var missing = p.sleepHoursNeutral - hours;
      if (missing > 3) {
        missing = 3;
      }
      detail -= p.sleepPerHour * missing;
    }
  }
  for (final item in <int?>[
    check.sleepQuality,
    check.energy,
    check.mood,
    check.soreness,
    check.stress,
    check.motivation,
    check.nutrition,
    check.hydration,
  ]) {
    if (item != null) {
      answered++;
      if (item <= 2) {
        detail -= p.detailPerItem;
      }
    }
  }
  var shift = general + p.detailShare * detail;
  if (overall == null) {
    shift = detail;
  }
  if (shift < p.healthFloor) {
    shift = p.healthFloor;
  }
  var level = 0;
  if (shift <= p.healthLevel2 || (overall != null && overall <= 1)) {
    level = 2;
  } else if (shift <= p.healthLevel1 || (overall != null && overall <= 2)) {
    level = 1;
  }
  return HealthReading(shift, level, answered);
}

/// Forme du jour de 0 à 1 pour un effet [shift] sur `ln` capacité.
double readinessOf(double shift, AdaptParams p) =>
    clampDouble(1 + shift / p.readinessSpan, 0, 1);
