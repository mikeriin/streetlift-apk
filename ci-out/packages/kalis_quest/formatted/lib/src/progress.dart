/// Avancements (D7.5) : rangs par mouvement et attributs, calculés depuis
/// les performances du journal.
library;

import 'package:kalis_core/kalis_core.dart';

import 'ledger.dart';
import 'numeric.dart';
import 'standards.dart';
import 'world.dart';

/// Rang calculé d'un mouvement de référence.
final class RankResult {
  /// Rang du mouvement [movement].
  RankResult(this.movement);

  /// Mouvement de référence.
  final RankMovement movement;

  /// Points de rang de la meilleure performance connue (0 à 7).
  double points = 0;

  /// Points de rang du niveau actuel : les performances anciennes sont
  /// diminuées par la rétention.
  double current = 0;

  /// Meilleure performance, dans son unité lisible : charge externe (ou
  /// lest) du 1RM en kg, répétitions, secondes de tenue, secondes sur 5 km.
  double? value;

  /// Exercice de cette performance.
  String? valueExerciseId;

  /// Valeur du rang suivant, même unité, pour le poids de corps du profil
  /// (`null` au rang Élite ou pour une figure qui change de progression).
  double? nextValue;

  /// Progression à tenir pour le rang suivant (figures).
  String? nextExerciseId;
}

/// Rétention d'une performance vieille de [ageDays] jours : entière
/// pendant `detrainFromDays` jours (kalis_adapt), puis `detrainPerWeek`
/// de moins par semaine, jusqu'au plancher.
double retentionOf(World w, int ageDays) {
  final from = w.adapt.detrainFromDays;
  if (ageDays <= from) {
    return 1;
  }
  final r = 1 - w.adapt.detrainPerWeek * (ageDays - from) / 7;
  return r < w.params.retentionFloor ? w.params.retentionFloor : r;
}

/// Rangs des mouvements de référence d'après les séances jusqu'au jour
/// [asOf] inclus.
List<RankResult> computeRanks(World w, int asOf) {
  final sex = w.input.profile.sex;
  final profileBw = w.profileBodyWeightKg;
  final out = <RankResult>[];
  for (final m in Standards.movements) {
    final r = RankResult(m);
    out.add(r);
    if (m.measure == RankMeasure.hold) {
      final best = <String, double>{};
      final decayed = <String, double>{};
      for (final id in m.sources) {
        for (final o
            in w.series['$id|${RecordKind.maxHoldSeconds.code}'] ??
                const <Observation>[]) {
          if (o.day > asOf) {
            break;
          }
          if (o.value > (best[id] ?? 0)) {
            best[id] = o.value;
          }
          final d = o.value * retentionOf(w, asOf - o.day);
          if (d > (decayed[id] ?? 0)) {
            decayed[id] = d;
          }
        }
      }
      final minHold = w.params.skillHoldSeconds;
      r.points = Standards.holdPoints(m, (id) => best[id] ?? 0, minHold);
      r.current = Standards.holdPoints(m, (id) => decayed[id] ?? 0, minHold);
      final tier = r.points.floor();
      if (tier < m.rungs.length) {
        final next = m.rungs[tier];
        r.nextValue = next.seconds.toDouble();
        r.nextExerciseId = next.exerciseIds.first;
        var held = 0.0;
        for (final id in next.exerciseIds) {
          if ((best[id] ?? 0) > held) {
            held = best[id]!;
            r.valueExerciseId = id;
          }
        }
        r.value = held;
        r.valueExerciseId ??= next.exerciseIds.first;
      } else {
        final last = m.rungs.last;
        r.valueExerciseId = last.exerciseIds.first;
        r.value = best[last.exerciseIds.first] ?? last.seconds.toDouble();
      }
      continue;
    }
    final kind = switch (m.measure) {
      RankMeasure.load => RecordKind.oneRmKg,
      RankMeasure.reps => RecordKind.maxReps,
      RankMeasure.run => RecordKind.timeSeconds,
      RankMeasure.hold => RecordKind.maxHoldSeconds,
    };
    for (final id in m.sources) {
      final fraction = w.book.find(id)?.fraction ?? Standards.defaultFraction;
      for (final o in w.series['$id|${kind.code}'] ?? const <Observation>[]) {
        if (o.day > asOf) {
          break;
        }
        final t = Standards.thresholds(m, sex, o.bodyWeightKg, fraction);
        final perf = m.measure == RankMeasure.run
            ? Standards.runMeters / o.value
            : o.value;
        final p = Standards.pointsOf(t, perf);
        if (p > r.points) {
          r.points = p;
          r.valueExerciseId = id;
          r.value = m.measure == RankMeasure.load
              ? roundTo(o.value - fraction * o.bodyWeightKg, 1)
              : o.value;
        }
        final c = Standards.pointsOf(t, perf * retentionOf(w, asOf - o.day));
        if (c > r.current) {
          r.current = c;
        }
      }
    }
    final tier = r.points.floor();
    if (tier < 6) {
      final fraction = w.book.find(m.id)?.fraction ?? Standards.defaultFraction;
      final t = Standards.thresholds(m, sex, profileBw, fraction);
      final next = t[tier < 0 ? 0 : tier];
      r.nextValue = switch (m.measure) {
        RankMeasure.load => roundTo(next - fraction * profileBw, 1),
        RankMeasure.reps => next.ceilToDouble(),
        RankMeasure.run => roundTo(Standards.runMeters / next, 0),
        RankMeasure.hold => null,
      };
    }
  }
  return out;
}

/// Sorties `MovementRank` : le rang ne redescend jamais sous le meilleur
/// rang déjà atteint ([MachineState.rankBest]).
List<MovementRank> ranksToContract(List<RankResult> ranks, MachineState st) {
  final out = <MovementRank>[];
  for (final r in ranks) {
    final kept = st.rankBest[r.movement.id] ?? 0;
    var points = r.points;
    if (points < kept) {
      points = kept.toDouble();
    }
    final tier = Standards.tierOf(points);
    out.add(
      MovementRank(
        exerciseId: r.movement.id,
        tier: tier,
        score: roundTo(points, 3),
        nextTierAt: tier.index < 6 ? (tier.index + 1).toDouble() : null,
      ),
    );
  }
  return out;
}

double _topTwo(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  values.sort((a, b) => b.compareTo(a));
  if (values.length == 1) {
    return values.first * 0.85;
  }
  return (values[0] + values[1]) / 2;
}

double _scale(double points) => clampDouble(points, 0, 6) / 6 * 100;

/// Mouvements de référence des figures (attribut Technique).
const List<String> figureMovements = <String>[
  'cs-front-lever',
  'cs-planche',
  'cs-handstand',
  'cd-muscle-up-barre-strict',
];

/// Mouvements de référence explosifs (attribut Puissance).
const List<String> explosiveMovements = <String>[
  'cd-muscle-up-barre-strict',
  'sl-muscle-up-leste',
];

/// Attributs (D7.5) au jour [asOf], dans l'ordre de `AthleteAttribute` :
/// Force, Endurance, Puissance, Technique, Mobilité, Régularité. Valeurs de
/// 1 à 100, arrondies au dixième. Définitions et plafonds : `CONTRAT.md`.
List<double> computeAttributes(
  World w,
  List<RankResult> ranks,
  MachineState st,
  int asOf,
) {
  final p = w.params;
  final loaded = <double>[];
  final bodyweight = <double>[];
  final enduring = <double>[];
  final figures = <double>[];
  var explosive = 0.0;
  for (final r in ranks) {
    final n = _scale(r.current);
    final id = r.movement.id;
    if (n <= 0) {
      continue;
    }
    switch (r.movement.measure) {
      case RankMeasure.load:
        loaded.add(n);
      case RankMeasure.reps:
        if (id != 'cd-muscle-up-barre-strict') {
          bodyweight.add(n);
          enduring.add(n);
        }
      case RankMeasure.run:
        enduring.add(n);
      case RankMeasure.hold:
        break;
    }
    if (figureMovements.contains(id)) {
      figures.add(n);
    }
    if (explosiveMovements.contains(id) && n > explosive) {
      explosive = n;
    }
  }
  final strengthLoaded = _topTwo(loaded);
  final strengthBody = 0.6 * _topTwo(List<double>.of(bodyweight));
  final strength = strengthLoaded > strengthBody
      ? strengthLoaded
      : strengthBody;

  var cardioSeconds = 0;
  var explosiveSets = 0;
  var mobilitySeconds = 0;
  var mobilityDays = 0;
  var onTarget = 0;
  var withTarget = 0;
  final widest = <int>[
    p.cardioWindowDays,
    p.explosiveWindowDays,
    p.mobilityWindowDays,
    p.accuracyWindowDays,
  ].reduce((a, b) => a > b ? a : b);
  var lastMobilityDay = -1 << 40;
  var dayMobility = 0;
  for (final f in w.factsIn(asOf - widest + 1, asOf)) {
    final age = asOf - f.day;
    if (age < p.cardioWindowDays) {
      cardioSeconds += f.cardioSeconds;
    }
    if (age < p.explosiveWindowDays) {
      explosiveSets += f.explosiveSets;
    }
    if (age < p.mobilityWindowDays) {
      mobilitySeconds += f.mobilitySeconds;
      if (f.day != lastMobilityDay) {
        lastMobilityDay = f.day;
        dayMobility = 0;
      }
      final before = dayMobility;
      dayMobility += f.mobilitySeconds;
      if (before < p.mobilityDaySeconds &&
          dayMobility >= p.mobilityDaySeconds) {
        mobilityDays++;
      }
    }
    if (age < p.accuracyWindowDays) {
      onTarget += f.ratedOnTarget;
      withTarget += f.ratedWithTarget;
    }
  }
  double perWeek(int total, int windowDays) => total * 7 / windowDays;
  double share(double value, num full) => clampDouble(value / full, 0, 1) * 100;

  final endurance =
      0.7 * _topTwo(enduring) +
      0.3 *
          share(
            perWeek(cardioSeconds, p.cardioWindowDays),
            p.cardioSecondsPerWeek,
          );
  final power =
      0.5 * explosive +
      0.2 * strength +
      0.3 *
          share(
            perWeek(explosiveSets, p.explosiveWindowDays),
            p.explosiveSetsPerWeek,
          );

  var hardest = 0;
  for (final entry in w.bests.entries) {
    final o = entry.value;
    if (o.day > asOf) {
      continue;
    }
    final cut = entry.key.indexOf('|');
    final e = w.catalog.find(entry.key.substring(0, cut));
    if (e == null) {
      continue;
    }
    final mastered =
        (e.family == MovementFamily.figureStatique &&
            entry.key.endsWith(RecordKind.maxHoldSeconds.code) &&
            o.value >= p.skillHoldSeconds) ||
        (e.family == MovementFamily.figureDynamique &&
            entry.key.endsWith(RecordKind.maxReps.code) &&
            o.value >= p.skillMinReps);
    if (mastered && e.difficulty > hardest) {
      hardest = e.difficulty;
    }
  }
  final figureScore = _topTwo(figures);
  final difficultyScore = 8.0 * hardest;
  final skill = figureScore > difficultyScore ? figureScore : difficultyScore;
  final accuracy = withTarget == 0
      ? 0.0
      : onTarget /
            withTarget *
            100 *
            clampDouble(withTarget / p.accuracyMinSets, 0, 1);
  final technique = 0.6 * skill + 0.4 * accuracy;

  final mobility =
      0.5 *
          share(
            perWeek(mobilityDays, p.mobilityWindowDays),
            p.mobilityDaysPerWeek,
          ) +
      0.5 *
          share(
            perWeek(mobilitySeconds, p.mobilityWindowDays),
            p.mobilitySecondsPerWeek,
          );

  var adherence = 0.0;
  var counted = 0;
  var streak = 0;
  for (var i = st.weeks.length - 1; i >= 0; i--) {
    final week = st.weeks[i];
    if (week.monday + 6 > asOf) {
      continue;
    }
    if (week.status == WeekSummary.paused) {
      continue;
    }
    if (counted == streak && week.status == WeekSummary.success) {
      streak++;
    }
    if (counted < p.consistencyWeeks && week.planned > 0) {
      adherence += week.done / week.planned;
    }
    counted++;
    if (counted >= p.consistencyWeeks && counted > streak) {
      break;
    }
  }
  final weeksRead = counted < p.consistencyWeeks ? counted : p.consistencyWeeks;
  final consistency = weeksRead == 0
      ? 0.0
      : adherence / weeksRead * 80 +
            clampDouble(streak / p.consistencyWeeks, 0, 1) * 20;

  return <double>[
    for (final v in <double>[
      strength,
      endurance,
      power,
      technique,
      mobility,
      consistency,
    ])
      roundTo(clampDouble(v, 1, 100), 1),
  ];
}
