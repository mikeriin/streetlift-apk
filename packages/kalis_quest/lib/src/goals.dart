/// Objectifs (D3.8) : avancement, jalons automatiques découpés selon la
/// courbe prévue, prédiction de la date d'atteinte (médiane et intervalle
/// à 80 %), objectifs en retard, objectifs suggérés.
library;

import 'package:kalis_core/kalis_core.dart';

import 'numeric.dart';
import 'world.dart';

/// Codes de méthode d'une prédiction.
abstract final class PredictionMethods {
  /// Capacité et tendance de `kalis_adapt`, tendance amortie.
  static const String adapt = 'adapt_damped_trend';

  /// Tendance robuste lue dans le journal (Theil–Sen), amortie.
  static const String journal = 'journal_damped_trend';

  /// Rythme récent d'un objectif d'habitude.
  static const String habit = 'habit_rate';
}

/// Estimation d'une grandeur : niveau, erreur, tendance par semaine, dans
/// l'unité de l'objectif, orientée pour que « plus grand = mieux ».
final class TrendEstimate {
  /// Estimation.
  const TrendEstimate(this.level, this.sd, this.weekly, this.method);

  /// Niveau actuel.
  final double level;

  /// Écart-type du niveau.
  final double sd;

  /// Tendance par semaine.
  final double weekly;

  /// Méthode.
  final String method;
}

/// Résultat de l'évaluation d'un objectif.
final class GoalResult {
  /// Résultat pour [goal].
  GoalResult(this.goal, this.progress, this.reachedDays, this.ambition);

  /// Objectif.
  final Goal goal;

  /// Avancement (contrat).
  final GoalProgress progress;

  /// Jour d'atteinte de chaque jalon (`null` : pas encore).
  final List<int?> reachedDays;

  /// Part de l'XP de jalon due à cet objectif (0 : jalons non payés).
  final double ambition;
}

/// Prévision par tendance amortie : gain cumulé après [weeks] semaines
/// d'une tendance d'une unité par semaine amortie de [damping] par semaine.
double dampedGain(double weeks, double damping) {
  if (weeks <= 0) {
    return 0;
  }
  if (damping >= 1) {
    return weeks;
  }
  return damping * (1 - power(damping, weeks)) / (1 - damping);
}

/// Évaluateur d'objectifs d'un appel.
final class GoalKeeper {
  /// Évaluateur du monde [w].
  GoalKeeper(this.w);

  /// Monde.
  final World w;

  double get _damping => w.adapt.trendDamping;

  double _k(String exerciseId) =>
      (w.book.find(exerciseId)?.lowerBody ?? false)
      ? w.adapt.kLowerBody
      : w.adapt.kGeneral;

  /// Vrai si une valeur plus petite est meilleure pour [metric].
  static bool lowerIsBetter(GoalMetric metric) =>
      metric == GoalMetric.timeSeconds;

  /// Observations (jour, valeur) de la grandeur d'un objectif de
  /// performance, par date croissante, dans l'unité de l'objectif.
  List<(int, double)> observationsOf(Goal goal) {
    final id = goal.exerciseId;
    final metric = goal.metric;
    if (id == null || metric == null) {
      return const <(int, double)>[];
    }
    final info = w.book.find(id);
    final fraction = info?.fraction ?? 0;
    List<Observation> of(RecordKind kind) =>
        w.series['$id|${kind.code}'] ?? const <Observation>[];
    final out = <(int, double)>[];
    switch (metric) {
      case GoalMetric.oneRmKg:
        for (final o in of(RecordKind.oneRmKg)) {
          out.add((o.day, roundTo(o.value - fraction * o.bodyWeightKg, 1)));
        }
      case GoalMetric.maxReps:
        final load = goal.loadKg;
        final loaded = of(RecordKind.oneRmKg);
        if (load == null && loaded.isEmpty) {
          for (final o in of(RecordKind.maxReps)) {
            out.add((o.day, o.value));
          }
        } else {
          final k = _k(id);
          for (final o in loaded) {
            final total = (load ?? 0) + fraction * o.bodyWeightKg;
            if (total <= 0) {
              continue;
            }
            final reps = (1 + k * (o.value / total - 1)).floorToDouble();
            out.add((o.day, reps < 0 ? 0 : reps));
          }
        }
      case GoalMetric.maxHoldSeconds:
        for (final o in of(RecordKind.maxHoldSeconds)) {
          out.add((o.day, o.value));
        }
      case GoalMetric.skillUnlocked:
        final days = <int>[
          for (final o in of(RecordKind.maxHoldSeconds))
            if (o.value >= w.params.skillHoldSeconds) o.day,
          for (final o in of(RecordKind.maxReps))
            if (o.value >= 1) o.day,
          for (final o in of(RecordKind.oneRmKg)) o.day,
        ]..sort();
        if (days.isNotEmpty) {
          out.add((days.first, 1));
        }
      case GoalMetric.timeSeconds:
        final meters = goal.distanceMeters;
        if (meters != null && meters > 0) {
          for (final o in of(RecordKind.timeSeconds)) {
            out.add((
              o.day,
              roundTo(
                o.value *
                    power(meters / 5000, w.params.riegelExponent),
                1,
              ),
            ));
          }
        }
      case GoalMetric.distanceMeters:
        final seconds = goal.durationSeconds;
        if (seconds != null) {
          for (final o in of(RecordKind.timeSeconds)) {
            out.add((
              o.day,
              roundTo(
                5000 * power(seconds / o.value, 1 / w.params.riegelExponent),
                0,
              ),
            ));
          }
        }
    }
    return out;
  }

  /// Parts de l'écart à atteindre aux quatre jalons : étapes d'égale durée
  /// le long de la courbe prévue (tendance amortie) entre la création et
  /// l'échéance.
  List<double> milestoneFractions(int days) {
    final weeks = days < 7 ? 1.0 : days / 7;
    final full = dampedGain(weeks, _damping);
    return <double>[
      for (var i = 1; i <= 3; i++)
        roundTo(dampedGain(weeks * i / 4, _damping) / full, 2),
      1,
    ];
  }

  /// Tendance robuste lue dans les observations [obs] (orientées « plus
  /// grand = mieux ») : meilleures valeurs par semaine sur la fenêtre,
  /// pente de Theil–Sen, erreur par l'écart absolu médian.
  TrendEstimate? journalTrend(List<(int, double)> obs) {
    final p = w.params;
    final weekly = <int, double>{};
    for (final (day, value) in obs) {
      final age = w.today - day;
      if (age < 0 || age >= 7 * p.seriesWindowWeeks) {
        continue;
      }
      final week = -(age ~/ 7);
      final old = weekly[week];
      if (old == null || value > old) {
        weekly[week] = value;
      }
    }
    if (weekly.length < p.seriesMinPoints) {
      return null;
    }
    final xs = weekly.keys.toList()..sort();
    final slopes = <double>[];
    for (var i = 0; i < xs.length; i++) {
      for (var j = i + 1; j < xs.length; j++) {
        slopes.add((weekly[xs[j]]! - weekly[xs[i]]!) / (xs[j] - xs[i]));
      }
    }
    final slope = medianOf(slopes);
    final level = medianOf(<double>[
      for (final x in xs) weekly[x]! - slope * x,
    ]);
    final mad = medianOf(<double>[
      for (final x in xs) (weekly[x]! - slope * x - level).abs(),
    ]);
    final floor = p.seriesSdFloor * level.abs();
    final sd = 1.4826 * mad;
    return TrendEstimate(
      level,
      sd > floor ? sd : floor,
      slope,
      PredictionMethods.journal,
    );
  }

  /// Estimation de la grandeur de [goal], orientée « plus grand = mieux » :
  /// celle de `kalis_adapt` quand le résumé d'adaptation suit l'exercice
  /// dans une unité convertible, sinon la tendance du journal.
  TrendEstimate? estimateOf(Goal goal, List<(int, double)> oriented) {
    final id = goal.exerciseId;
    final metric = goal.metric;
    if (id == null || metric == null) {
      return null;
    }
    final info = w.book.find(id);
    final bw = w.profileBodyWeightKg;
    final fraction = info?.fraction ?? 0;
    for (final e
        in w.input.adaptation?.estimates ?? const <ExerciseEstimate>[]) {
      if (e.exerciseId != id) {
        continue;
      }
      if (e.unit == CapacityUnit.oneRmKg && metric == GoalMetric.oneRmKg) {
        return TrendEstimate(
          e.capacity - fraction * bw,
          e.standardError,
          e.weeklyTrend,
          PredictionMethods.adapt,
        );
      }
      if (e.unit == CapacityUnit.oneRmKg && metric == GoalMetric.maxReps) {
        final total = (goal.loadKg ?? 0) + fraction * bw;
        if (total > 0) {
          final scale = _k(id) / total;
          return TrendEstimate(
            1 + _k(id) * (e.capacity / total - 1),
            e.standardError * scale,
            e.weeklyTrend * scale,
            PredictionMethods.adapt,
          );
        }
      }
      if ((e.unit == CapacityUnit.maxReps &&
              metric == GoalMetric.maxReps &&
              goal.loadKg == null) ||
          (e.unit == CapacityUnit.maxHoldSeconds &&
              metric == GoalMetric.maxHoldSeconds)) {
        return TrendEstimate(
          e.capacity,
          e.standardError,
          e.weeklyTrend,
          PredictionMethods.adapt,
        );
      }
    }
    return journalTrend(oriented);
  }

  /// Écart-type de la tendance d'une estimation.
  double trendSd(TrendEstimate e) {
    final p = w.params;
    final a = p.trendCv * e.weekly.abs();
    final b = e.sd / p.trendSdFloorWeeks;
    return a > b ? a : b;
  }

  /// Probabilité que la grandeur estimée par [e] atteigne [target] (même
  /// orientation) dans [days] jours.
  double probabilityBy(TrendEstimate e, double target, int days) {
    final g = dampedGain(days / 7, _damping);
    final mean = e.level + e.weekly * g;
    final sw = trendSd(e) * g;
    final sd = sqrt(e.sd * e.sd + sw * sw);
    if (sd <= 0) {
      return mean >= target ? 1 : 0;
    }
    return normCdf((mean - target) / sd);
  }

  /// Valeur atteinte avec la probabilité [probability] dans [days] jours.
  double valueBy(TrendEstimate e, int days, double probability) {
    final g = dampedGain(days / 7, _damping);
    final mean = e.level + e.weekly * g;
    final sw = trendSd(e) * g;
    final sd = sqrt(e.sd * e.sd + sw * sw);
    // Quantile par dichotomie sur la fonction de répartition.
    var low = -8.0;
    var high = 8.0;
    for (var i = 0; i < 50; i++) {
      final mid = (low + high) / 2;
      if (normCdf(mid) < 1 - probability) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return mean + (low + high) / 2 * sd;
  }

  /// Premier jour (compté depuis aujourd'hui) où la probabilité d'atteinte
  /// vaut au moins [probability], ou `null` dans l'horizon.
  int? firstDay(TrendEstimate e, double target, double probability) {
    final horizon = 7 * w.params.predictionHorizonWeeks;
    if (probabilityBy(e, target, 0) >= probability) {
      return 0;
    }
    // Pas d'une semaine, puis affinage au jour.
    for (var d = 7; d <= horizon; d += 7) {
      if (probabilityBy(e, target, d) >= probability) {
        for (var k = d - 6; k < d; k++) {
          if (probabilityBy(e, target, k) >= probability) {
            return k;
          }
        }
        return d;
      }
    }
    return null;
  }

  /// Évalue l'objectif de performance [goal].
  GoalResult performance(Goal goal) {
    final p = w.params;
    final metric = goal.metric!;
    final lower = lowerIsBetter(metric);
    final sign = lower ? -1.0 : 1.0;
    final created = goal.createdOn.dayNumber;
    final raw = observationsOf(goal);
    final target =
        goal.targetValue ?? (metric == GoalMetric.skillUnlocked ? 1.0 : 0.0);
    final deadline = goal.targetDate?.dayNumber ?? created;

    double? baseline;
    double? best;
    for (final (day, value) in raw) {
      if (day > created) {
        break;
      }
      if (baseline == null || sign * value > sign * baseline) {
        baseline = value;
      }
    }
    final hadBaseline = baseline != null;
    if (metric == GoalMetric.skillUnlocked ||
        metric == GoalMetric.maxReps ||
        metric == GoalMetric.maxHoldSeconds) {
      baseline ??= 0;
    }
    final reached = List<int?>.filled(4, null);
    final fractions = milestoneFractions(deadline - created);
    final alreadyThere =
        baseline != null && hadBaseline && sign * baseline >= sign * target;
    for (final (day, value) in raw) {
      if (best == null || sign * value > sign * best) {
        best = value;
      }
      if (day <= created) {
        continue;
      }
      // Sans mesure avant la création, la première mesure sert de départ.
      baseline ??= value;
      final gap = sign * (target - baseline);
      for (var i = 0; i < 4; i++) {
        if (reached[i] != null) {
          continue;
        }
        final need = gap <= 0 ? 0.0 : fractions[i] * gap;
        if (sign * (best - baseline) >= need - 1e-9 &&
            (gap > 0 || sign * best >= sign * target)) {
          reached[i] = day;
        }
      }
    }
    if (alreadyThere) {
      for (var i = 0; i < 4; i++) {
        reached[i] = created;
      }
    }
    final current = best ?? baseline ?? 0.0;
    var fraction = 0.0;
    if (baseline != null) {
      final gap = sign * (target - baseline);
      fraction = gap <= 0
          ? (sign * current >= sign * target ? 1 : 0)
          : clampDouble(sign * (current - baseline) / gap, 0, 1);
    }
    final achievedDay = reached[3];
    if (achievedDay != null) {
      fraction = 1;
    }

    Prediction? prediction;
    var overdue = false;
    var judged = false;
    CivilDate? suggestedDate;
    double? suggestedTarget;
    final reasons = <Reason>[];
    if (achievedDay == null && metric != GoalMetric.skillUnlocked) {
      judged = true;
      final oriented = <(int, double)>[
        for (final (day, value) in raw) (day, sign * value),
      ];
      final estimate = estimateOf(goal, oriented);
      final e = estimate == null || estimate.method != PredictionMethods.adapt
          ? estimate
          : TrendEstimate(
              sign * estimate.level,
              estimate.sd,
              sign * estimate.weekly,
              estimate.method,
            );
      final goalValue = sign * target;
      if (e != null) {
        final expected = firstDay(e, goalValue, 0.5);
        if (expected != null) {
          final earliest = firstDay(e, goalValue, 0.1) ?? expected;
          final horizon = 7 * p.predictionHorizonWeeks;
          var latest = firstDay(e, goalValue, 0.9) ?? horizon;
          if (latest < expected) {
            latest = expected;
          }
          final left = deadline - w.today;
          prediction = Prediction(
            expectedOn: CivilDate.fromDayNumber(w.today + expected),
            earliestOn: CivilDate.fromDayNumber(
              w.today + (earliest < expected ? earliest : expected),
            ),
            latestOn: CivilDate.fromDayNumber(w.today + latest),
            confidence: left < 0
                ? 0
                : roundTo(probabilityBy(e, goalValue, left), 3),
            method: e.method,
          );
          reasons.add(
            Reason(
              code: ReasonCodes.questPredictionUpdated,
              params: <String, Object?>{'goalId': goal.id},
            ),
          );
          overdue = w.today + expected > deadline;
        } else {
          overdue = true;
        }
        if (overdue) {
          final day = firstDay(e, goalValue, p.suggestProbability);
          if (day != null && w.today + day > deadline) {
            suggestedDate = CivilDate.fromDayNumber(w.today + day);
          }
          final left = deadline - w.today;
          if (left > 0) {
            final reachable =
                sign * valueBy(e, left, p.suggestProbability);
            final step = stepOf(metric, reachable.abs());
            final rounded = lower
                ? (reachable / step).ceilToDouble() * step
                : (reachable / step).floorToDouble() * step;
            if (sign * rounded > sign * current && rounded > 0) {
              suggestedTarget = roundTo(rounded, 1);
            }
          }
        }
      } else if (w.today > deadline) {
        overdue = true;
      }
      if (overdue) {
        reasons.add(
          Reason(
            code: ReasonCodes.questGoalLate,
            params: <String, Object?>{'goalId': goal.id},
          ),
        );
      }
    }

    var ambition = 0.0;
    if (!alreadyThere && deadline - created >= p.goalMinDays) {
      if (metric == GoalMetric.skillUnlocked) {
        ambition = 1;
      } else if (baseline != null) {
        final gap = (target - baseline).abs();
        final base = baseline.abs() < 1e-9 ? 1.0 : baseline.abs();
        if (sign * (target - baseline) > 0) {
          ambition = clampDouble(
            gap / base / p.goalFullGap,
            p.goalMinAmbition,
            1,
          );
        }
      } else {
        ambition = p.goalMinAmbition;
      }
    }

    return GoalResult(
      goal,
      GoalProgress(
        goalId: goal.id,
        current: current,
        target: target,
        fraction: roundTo(fraction, 3),
        achievedOn: achievedDay == null
            ? null
            : CivilDate.fromDayNumber(achievedDay),
        milestones: <Milestone>[
          for (var i = 0; i < 4; i++)
            Milestone(
              fraction: fractions[i],
              reachedOn: reached[i] == null
                  ? null
                  : CivilDate.fromDayNumber(reached[i]!),
            ),
        ],
        prediction: prediction,
        baseline: baseline,
        overdue: judged ? overdue : null,
        suggestedDate: suggestedDate,
        suggestedTarget: suggestedTarget,
        reasons: reasons.isEmpty ? null : reasons,
      ),
      reached,
      ambition,
    );
  }

  /// Pas d'arrondi d'une cible proposée.
  static double stepOf(GoalMetric metric, double value) {
    switch (metric) {
      case GoalMetric.oneRmKg:
        return value < 20 ? 1 : 2.5;
      case GoalMetric.maxReps:
      case GoalMetric.skillUnlocked:
        return 1;
      case GoalMetric.maxHoldSeconds:
        return value < 30 ? 1 : 5;
      case GoalMetric.timeSeconds:
        return 5;
      case GoalMetric.distanceMeters:
        return 50;
    }
  }

  /// Évalue l'objectif d'habitude [goal] : séances faites, au plus
  /// `sessionsPerWeek` par semaine civile, depuis la création.
  GoalResult habit(Goal goal) {
    final p = w.params;
    final perWeek = goal.sessionsPerWeek ?? 1;
    final weeks = goal.weeks ?? 1;
    final target = perWeek * weeks;
    final created = goal.createdOn.dayNumber;
    final reached = List<int?>.filled(4, null);
    const fractions = <double>[0.25, 0.5, 0.75, 1];
    var current = 0;
    var weekCount = 0;
    var monday = -1 << 40;
    final perWeekCounts = <int, int>{};
    for (final f in w.factsIn(created, w.today)) {
      if (f.completion < p.doneCompletion ||
          f.painZone != null ||
          (!f.hard && f.session.programRef == null)) {
        continue;
      }
      final m = mondayOf(f.day);
      if (m != monday) {
        monday = m;
        weekCount = 0;
      }
      if (weekCount >= perWeek || current >= target) {
        continue;
      }
      weekCount++;
      current++;
      perWeekCounts[m] = weekCount;
      for (var i = 0; i < 4; i++) {
        if (reached[i] == null && current >= fractions[i] * target - 1e-9) {
          reached[i] = f.day;
        }
      }
    }
    final achievedDay = reached[3];
    Prediction? prediction;
    var overdue = false;
    CivilDate? suggestedDate;
    final reasons = <Reason>[];
    if (achievedDay == null) {
      final thisMonday = mondayOf(w.today);
      var sum = 0.0;
      var n = 0;
      for (var m = thisMonday - 7; m >= mondayOf(created) && n < 4; m -= 7) {
        sum += perWeekCounts[m] ?? 0;
        n++;
      }
      final rate = n == 0 ? perWeek * 0.75 : sum / n;
      final remaining = target - current;
      final deadline = created + 7 * weeks - 1;
      if (rate > 0) {
        final horizon = 7 * p.predictionHorizonWeeks;
        int daysAt(double perWeekRate) {
          final d = (remaining / perWeekRate * 7).ceil();
          return d > horizon ? horizon : d;
        }

        final expected = daysAt(rate);
        final earliest = daysAt(perWeek.toDouble());
        final latest = daysAt(rate * 0.6);
        prediction = Prediction(
          expectedOn: CivilDate.fromDayNumber(w.today + expected),
          earliestOn: CivilDate.fromDayNumber(
            w.today + (earliest < expected ? earliest : expected),
          ),
          latestOn: CivilDate.fromDayNumber(
            w.today + (latest > expected ? latest : expected),
          ),
          confidence: roundTo(clampDouble(rate / perWeek, 0, 1), 3),
          method: PredictionMethods.habit,
        );
        reasons.add(
          Reason(
            code: ReasonCodes.questPredictionUpdated,
            params: <String, Object?>{'goalId': goal.id},
          ),
        );
        overdue = w.today + expected > deadline;
        if (overdue) {
          suggestedDate = CivilDate.fromDayNumber(w.today + expected);
        }
      } else {
        overdue = true;
      }
      if (overdue) {
        reasons.add(
          Reason(
            code: ReasonCodes.questGoalLate,
            params: <String, Object?>{'goalId': goal.id},
          ),
        );
      }
    }
    return GoalResult(
      goal,
      GoalProgress(
        goalId: goal.id,
        current: current.toDouble(),
        target: target.toDouble(),
        fraction: roundTo(clampDouble(current / target, 0, 1), 3),
        achievedOn: achievedDay == null
            ? null
            : CivilDate.fromDayNumber(achievedDay),
        milestones: <Milestone>[
          for (var i = 0; i < 4; i++)
            Milestone(
              fraction: fractions[i],
              reachedOn: reached[i] == null
                  ? null
                  : CivilDate.fromDayNumber(reached[i]!),
            ),
        ],
        prediction: prediction,
        baseline: 0,
        overdue: achievedDay == null ? overdue : null,
        suggestedDate: suggestedDate,
        reasons: reasons.isEmpty ? null : reasons,
      ),
      reached,
      clampDouble(weeks / p.habitFullWeeks, p.goalMinAmbition, 1),
    );
  }

  /// Évalue tous les objectifs du profil, dans leur ordre.
  List<GoalResult> evaluate() {
    return <GoalResult>[
      for (final goal in w.input.profile.goals)
        if (goal.kind == GoalKind.habit)
          habit(goal)
        else if (goal.exerciseId != null && goal.metric != null)
          performance(goal),
    ];
  }

  /// Gain relatif plausible sur l'échéance d'un objectif suggéré, selon le
  /// niveau d'expérience déclaré.
  static double plausibleGain(ExperienceLevel? level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 0.15;
      case null:
      case ExperienceLevel.intermediate:
        return 0.08;
      case ExperienceLevel.advanced:
        return 0.05;
      case ExperienceLevel.elite:
        return 0.02;
    }
  }

  /// Objectifs suggérés (D3.8) : pour les exercices les mieux suivis par
  /// `kalis_adapt`, la cible que la tendance atteint avec la probabilité
  /// visée à l'échéance, bornée par le gain plausible du niveau.
  List<Goal> suggest() {
    final p = w.params;
    final adaptation = w.input.adaptation;
    if (adaptation == null) {
      return const <Goal>[];
    }
    final taken = <String>{
      for (final g in w.input.profile.goals)
        if (g.exerciseId != null) g.exerciseId!,
    };
    final candidates =
        <ExerciseEstimate>[
          for (final e in adaptation.estimates)
            if (e.observations >= p.suggestMinObservations &&
                e.weeklyTrend > 0 &&
                e.unit != CapacityUnit.metersPerSecond &&
                !taken.contains(e.exerciseId) &&
                w.catalog.contains(e.exerciseId))
              e,
        ]..sort((a, b) {
          final c = b.observations.compareTo(a.observations);
          return c != 0 ? c : a.exerciseId.compareTo(b.exerciseId);
        });
    final out = <Goal>[];
    final monday = CivilDate.fromDayNumber(mondayOf(w.today)).iso;
    final bw = w.profileBodyWeightKg;
    for (final e in candidates) {
      if (out.length >= p.suggestMax) {
        break;
      }
      final fraction = w.book.find(e.exerciseId)?.fraction ?? 0;
      final GoalMetric metric;
      final RecordKind kind;
      var offset = 0.0;
      switch (e.unit) {
        case CapacityUnit.oneRmKg:
          metric = GoalMetric.oneRmKg;
          kind = RecordKind.oneRmKg;
          offset = fraction * bw;
        case CapacityUnit.maxReps:
          metric = GoalMetric.maxReps;
          kind = RecordKind.maxReps;
        case CapacityUnit.maxHoldSeconds:
          metric = GoalMetric.maxHoldSeconds;
          kind = RecordKind.maxHoldSeconds;
        case CapacityUnit.metersPerSecond:
          continue;
      }
      final estimate = TrendEstimate(
        e.capacity - offset,
        e.standardError,
        e.weeklyTrend,
        PredictionMethods.adapt,
      );
      var value = valueBy(estimate, p.suggestHorizonDays, p.suggestProbability);
      final best = w.bests['${e.exerciseId}|${kind.code}'];
      final known = best == null
          ? estimate.level
          : best.value - (kind == RecordKind.oneRmKg ? offset : 0);
      final reference = known > estimate.level ? known : estimate.level;
      final cap =
          reference * (1 + plausibleGain(w.input.profile.experience));
      if (value > cap) {
        value = cap;
      }
      final step = stepOf(metric, value.abs());
      final target = (value / step).floorToDouble() * step;
      if (target < reference + step || target <= 0) {
        continue;
      }
      out.add(
        Goal(
          id: 'koach:${e.exerciseId}:$monday',
          kind: GoalKind.performance,
          origin: GoalOrigin.suggested,
          createdOn: w.input.today,
          exerciseId: e.exerciseId,
          metric: metric,
          targetValue: roundTo(target, 1),
          targetDate: w.input.today.addDays(p.suggestHorizonDays),
        ),
      );
    }
    return out;
  }
}
