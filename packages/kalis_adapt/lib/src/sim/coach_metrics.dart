/// Mesures des simulations sur des programmes au contrat 0.4.0 (parts du
/// 1RM, techniques, tests, tentatives) : écart à l'effort visé, échecs non
/// voulus, stabilité des charges à schéma égal, tentatives, performance le
/// jour de l'échéance rapportée au maximum vrai du jour.
library;

import 'package:kalis_core/kalis_core.dart';

import '../filter.dart';
import '../numeric.dart';
import 'metrics.dart';
import 'runner.dart';

/// Hausse à schéma égal au-delà de laquelle une montée de plusieurs crans
/// compte comme un pic (invariant de 0.1 : +10 % hors calibrage).
const double coachRiseLimit = 0.10;

/// Mesures d'un athlète sous une politique (programmes au contrat 0.4.0).
final class CoachMetrics {
  /// Mesures des simulations [runs] (une graine par simulation).
  CoachMetrics(List<SimRun> runs)
    : athlete = runs.isEmpty ? '' : runs.first.athlete,
      policy = runs.isEmpty ? '' : runs.first.policy,
      runs = runs.length {
    final gaps = <double>[];
    final biases = <double>[];
    final harder = <double>[];
    final easier = <double>[];
    final fails = <double>[];
    final gains = <double>[];
    final events = <double>[];
    final made = <double>[];
    final openers = <double>[];
    for (final run in runs) {
      var gapSum = 0.0;
      var biasSum = 0.0;
      var gapCount = 0;
      var hard = 0;
      var easy = 0;
      var work = 0;
      var failed = 0;
      var tries = 0;
      var good = 0;
      var first = 0;
      var firstGood = 0;
      // Meilleure barre réussie et maximum du jour, par exercice, le jour
      // de l'échéance.
      final best = <String, double>{};
      final dayMax = <String, double>{};
      for (final s in run.sets) {
        if (s.attempt) {
          tries++;
          attempts++;
          if (!s.failed && s.amount >= 1) {
            good++;
            attemptsMade++;
          }
          if (s.setIndex == 0) {
            first++;
            if (!s.failed && s.amount >= 1) {
              firstGood++;
            }
          }
        }
        if (s.eventDay && s.test) {
          final max = s.dayMax;
          if (max != null && max > 0) {
            dayMax[s.exerciseId] = max;
            final value = s.mode == CapacityMode.loaded
                ? (s.failed || s.amount < 1 ? 0.0 : s.totalKg ?? 0.0)
                : s.amount.toDouble();
            if (value > (best[s.exerciseId] ?? 0)) {
              best[s.exerciseId] = value;
            }
          }
        }
        if (s.test || s.role == SetRole.warmup) {
          continue;
        }
        final rise = s.schemeRise;
        if (rise != null && s.main) {
          if (rise > maxSchemeRise) {
            maxSchemeRise = rise;
          }
          if (rise > coachRiseLimit + 1e-9 && s.schemeSteps > 1) {
            schemeRisesOverLimit++;
          }
        }
        if (s.exerciseSession < metricCalibrationSessions) {
          continue;
        }
        work++;
        if (s.failed && !s.plannedFailure) {
          failed++;
        }
        if (s.plannedFailure) {
          continue;
        }
        final diff = s.trueRir - s.wantRir;
        final gap = s.openTarget ? (diff < 0 ? -diff : 0.0) : diff.abs();
        gapSum += gap;
        biasSum += s.openTarget && diff > 0 ? 0 : diff;
        gapCount++;
        if (diff <= -2) {
          hard++;
        }
        if (!s.openTarget && diff >= 3) {
          easy++;
        }
      }
      if (gapCount > 0) {
        gaps.add(gapSum / gapCount);
        biases.add(biasSum / gapCount);
        harder.add(hard / gapCount);
        easier.add(easy / gapCount);
      }
      if (work > 0) {
        fails.add(failed / work);
      }
      if (tries > 0) {
        made.add(good / tries);
      }
      if (first > 0) {
        openers.add(firstGood / first);
      }
      for (final e in best.entries) {
        final max = dayMax[e.key];
        if (max != null && max > 0) {
          events.add(e.value / max);
        }
      }
      if (run.gain.isNotEmpty) {
        var sum = 0.0;
        for (final g in run.gain.values) {
          sum += g;
        }
        gains.add(sum / run.gain.length);
      }
    }
    effortGap = Stat.of(gaps);
    effortBias = Stat.of(biases);
    harderRate = Stat.of(harder);
    easierRate = Stat.of(easier);
    failRate = Stat.of(fails);
    weeklyGain = Stat.of(gains);
    eventPerformance = Stat.of(events);
    attemptRate = Stat.of(made);
    openerRate = Stat.of(openers);
  }

  /// Athlète.
  final String athlete;

  /// Politique.
  final String policy;

  /// Nombre de simulations.
  final int runs;

  /// Écart absolu moyen à l'effort visé, en répétitions en réserve (cible
  /// « 5 et plus » : seul un effort plus dur compte), hors tests, après les
  /// trois premières séances de chaque exercice.
  late final Stat effortGap;

  /// Écart moyen signé (positif : plus facile que visé).
  late final Stat effortBias;

  /// Part des séries au moins 2 répétitions plus dures que visé.
  late final Stat harderRate;

  /// Part des séries au moins 3 répétitions plus faciles que visé.
  late final Stat easierRate;

  /// Part d'échecs non voulus parmi les séries de travail.
  late final Stat failRate;

  /// Gain de capacité vraie par semaine (`ln`).
  late final Stat weeklyGain;

  /// Meilleure performance du jour de l'échéance rapportée au maximum vrai
  /// du jour (une valeur par mouvement et par graine).
  late final Stat eventPerformance;

  /// Part de tentatives réussies.
  late final Stat attemptRate;

  /// Part d'ouvertures réussies.
  late final Stat openerRate;

  /// Tentatives faites.
  int attempts = 0;

  /// Tentatives réussies.
  int attemptsMade = 0;

  /// Plus forte hausse de charge totale d'un mouvement principal d'une
  /// séance à la suivante du même emplacement, à répétitions égales.
  double maxSchemeRise = 0;

  /// Hausses à schéma égal de plus de 10 % faites de plusieurs crans.
  int schemeRisesOverLimit = 0;

  /// Objet JSON.
  Map<String, Object?> toJson() => <String, Object?>{
    'athlete': athlete,
    'policy': policy,
    'runs': runs,
    'effortGap': effortGap.toJson(),
    'effortBias': effortBias.toJson(),
    'harderRate': harderRate.toJson(),
    'easierRate': easierRate.toJson(),
    'failRate': failRate.toJson(),
    'weeklyGain': weeklyGain.toJson(),
    'eventPerformance': eventPerformance.toJson(),
    'attemptRate': attemptRate.toJson(),
    'openerRate': openerRate.toJson(),
    'attempts': attempts,
    'attemptsMade': attemptsMade,
    'maxSchemeRise': roundTo(maxSchemeRise, 4),
    'schemeRisesOverLimit': schemeRisesOverLimit,
  };
}
