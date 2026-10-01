/// Grille des charges réellement disponibles (incréments du matériel).
library;

import 'package:kalis_core/kalis_core.dart';

/// Livre en kilogrammes.
const double poundKg = 0.45359237;

/// Grille de charge d'un type de matériel.
///
/// Les incréments viennent du profil (`loadIncrements`) ; sinon : haltères
/// par 1 kg jusqu'à 10 kg puis par 2 kg, barre par paire de disques de
/// 1,25 kg (2,5 kg), poulie par 2,5 lb, machine par 5 kg, kettlebell par
/// 4 kg, lest par 1,25 kg.
final class LoadGrid {
  const LoadGrid._(this.step, this.minimum, this.dumbbellRule);

  /// Grille du type [type] pour le profil [profile].
  factory LoadGrid.of(LoadType type, AthleteProfile? profile) {
    if (profile != null) {
      for (final inc in profile.loadIncrements) {
        if (inc.loadType == type) {
          final least = inc.minKg;
          return LoadGrid._(inc.stepKg, least ?? _defaultMinimum(type), false);
        }
      }
    }
    switch (type) {
      case LoadType.dumbbells:
        return const LoadGrid._(1, 1, true);
      case LoadType.barbell:
        return const LoadGrid._(2.5, 20, false);
      case LoadType.cable:
        return const LoadGrid._(2.5 * poundKg, 2.5 * poundKg, false);
      case LoadType.machine:
        return const LoadGrid._(5, 5, false);
      case LoadType.kettlebell:
        return const LoadGrid._(4, 4, false);
      case LoadType.addedWeight:
        return const LoadGrid._(1.25, 0, false);
      case LoadType.none:
      case LoadType.bodyweight:
      case LoadType.band:
      case LoadType.other:
        return const LoadGrid._(1, 0, false);
    }
  }

  static double _defaultMinimum(LoadType type) {
    switch (type) {
      case LoadType.barbell:
        return 20;
      case LoadType.dumbbells:
        return 1;
      case LoadType.machine:
        return 5;
      case LoadType.kettlebell:
        return 4;
      case LoadType.cable:
        return 2.5 * poundKg;
      case LoadType.addedWeight:
      case LoadType.none:
      case LoadType.bodyweight:
      case LoadType.band:
      case LoadType.other:
        return 0;
    }
  }

  /// Pas de la grille, en kg (pour les haltères par défaut : pas sous 10 kg).
  final double step;

  /// Plus petite charge, en kg.
  final double minimum;

  /// Haltères par défaut : 1 kg jusqu'à 10 kg, puis 2 kg.
  final bool dumbbellRule;

  static const double _eps = 1e-9;
  static const double _dumbbellKnee = 10;
  static const double _dumbbellLargeStep = 2;

  /// Pas de la grille au-dessus de [kg].
  double stepAbove(double kg) {
    if (dumbbellRule) {
      return kg < _dumbbellKnee - _eps ? step : _dumbbellLargeStep;
    }
    return step;
  }

  /// Plus grande charge de la grille inférieure ou égale à [kg] (jamais
  /// sous [minimum]).
  double floor(double kg) {
    double value;
    if (dumbbellRule && kg > _dumbbellKnee + _eps) {
      value =
          _dumbbellKnee +
          ((kg - _dumbbellKnee) / _dumbbellLargeStep + _eps).floorToDouble() *
              _dumbbellLargeStep;
    } else {
      value = (kg / step + _eps).floorToDouble() * step;
    }
    return value < minimum ? minimum : value;
  }

  /// Charge de la grille la plus proche de [kg] (jamais sous [minimum]).
  double nearest(double kg) {
    final low = floor(kg);
    final high = next(low, up: true);
    return (kg - low) <= (high - kg) ? low : high;
  }

  /// Charge suivante ([up]) ou précédente de la grille à partir de [kg],
  /// supposé sur la grille ; ne descend pas sous [minimum].
  double next(double kg, {required bool up}) {
    if (up) {
      return kg + stepAbove(kg);
    }
    final down = dumbbellRule
        ? (kg <= _dumbbellKnee + _eps ? step : _dumbbellLargeStep)
        : step;
    final value = kg - down;
    return value < minimum ? minimum : value;
  }
}
