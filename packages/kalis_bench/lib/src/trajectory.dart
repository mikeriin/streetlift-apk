/// Trajectoires : un athlète simulé à vérité connue (simulateur de
/// `kalis_adapt`, lu et appelé tel quel) suit le programme du profil sous
/// le moteur d'évolution, boucle complète (revue chaque semaine,
/// propositions appliquées, bloc suivant d'après le résumé d'adaptation).
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

import 'analysis.dart';
import 'profile.dart';
import 'program.dart';

/// Gain hebdomadaire de base de la vérité (`ln` de la capacité, à dose
/// pleine) par niveau : valeurs de la campagne de validation de
/// `kalis_adapt` (débutant, intermédiaire, avancé) ; l'élite est un choix
/// raisonné (la moitié de l'avancé).
const List<double> defaultWeeklyGain = <double>[0.012, 0.004, 0.0015, 0.0008];

/// Diviseur de la formule d'Epley (1RM estimé = charge × (1 + reps ÷ 30)),
/// utilisée seulement pour comparer deux séries d'un même exercice.
const double epleyDivisor = 30;

/// Athlète simulé du profil [p] : niveau et gain par défaut, puis les
/// réglages de `simulation` (champs de `AthleteSpec`).
AthleteSpec athleteSpecOf(BenchProfile p) {
  final json = <String, Object?>{
    'key': p.key,
    'profileKey': p.key,
    'level': p.level.index,
    'weeklyGain': defaultWeeklyGain[p.level.index],
    ...p.simulation,
  };
  return athleteFromJson(json);
}

/// Ligne hebdomadaire d'une trajectoire pour un exercice.
final class TrajectoryRow {
  /// Ligne.
  TrajectoryRow({
    required this.week,
    required this.weekKind,
    required this.exerciseId,
    required this.sets,
    required this.topLoadKg,
    required this.topAmount,
    required this.meanTrueRir,
    required this.meanWantRir,
    required this.failures,
    required this.truth,
    required this.estimate,
  });

  /// Semaine (0 = première).
  final int week;

  /// Nature de la semaine.
  final WeekKind weekKind;

  /// Exercice.
  final String exerciseId;

  /// Séries faites.
  final int sets;

  /// Plus forte charge externe de la semaine, ou `null`.
  final double? topLoadKg;

  /// Plus grand nombre de répétitions (ou de secondes) d'une série.
  final int topAmount;

  /// RIR réel moyen.
  final double meanTrueRir;

  /// RIR visé moyen.
  final double meanWantRir;

  /// Échecs non voulus.
  final int failures;

  /// Capacité vraie en fin de semaine, ou `null`.
  final double? truth;

  /// Capacité estimée par le moteur en fin de semaine, ou `null`.
  final double? estimate;
}

/// Trajectoire simulée d'un profil.
final class Trajectory {
  /// Trajectoire.
  Trajectory({
    required this.profile,
    required this.run,
    required this.weeks,
    required this.rows,
    required this.metrics,
    required this.mainExerciseIds,
  });

  /// Profil du banc.
  final BenchProfile profile;

  /// Simulation brute.
  final SimRun run;

  /// Semaines simulées.
  final int weeks;

  /// Lignes hebdomadaires des exercices suivis.
  final List<TrajectoryRow> rows;

  /// Mesures.
  final Map<String, Object?> metrics;

  /// Exercices suivis dans l'export (prioritaires, sinon principaux).
  final List<String> mainExerciseIds;
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

/// Simule [weeks] semaines (par défaut l'horizon du profil) du profil
/// [bench], dont le profil des moteurs est [profile], sous `kalis_adapt`
/// en boucle complète, graine [seed].
Trajectory simulateTrajectory(
  Catalog catalog,
  PlanEngine plan,
  BenchProfile bench,
  AthleteProfile profile, {
  int seed = 0,
  int? weeks,
}) {
  final horizon = weeks ?? horizonOf(bench);
  final engine = KalisAdapt();
  final run = simulate(
    catalog: catalog,
    spec: athleteSpecOf(bench),
    profile: profile,
    seed: seed,
    policy: KalisAdaptPolicy(engine),
    program: SimProgram(catalog, plan, profile, seed: seed),
    weeks: horizon,
    loop: engine,
  );

  // Exercices suivis : cibles du profil présentes dans la simulation, puis
  // mouvements principaux les plus travaillés.
  final counts = <String, int>{};
  final mains = <String>{};
  for (final s in run.sets) {
    counts[s.exerciseId] = (counts[s.exerciseId] ?? 0) + 1;
    if (s.main) {
      mains.add(s.exerciseId);
    }
  }
  final followed = <String>[
    for (final id in bench.priorityIds)
      if (counts.containsKey(id)) id,
  ];
  final byCount = mains.toList()
    ..sort((a, b) {
      final c = counts[b]!.compareTo(counts[a]!);
      return c != 0 ? c : a.compareTo(b);
    });
  for (final id in byCount) {
    if (followed.length >= 6) {
      break;
    }
    if (!followed.contains(id)) {
      followed.add(id);
    }
  }

  final rows = <TrajectoryRow>[];
  for (final id in followed) {
    for (var w = 0; w < horizon; w++) {
      var sets = 0;
      double? topLoad;
      var topAmount = 0;
      var trueSum = 0.0;
      var wantSum = 0.0;
      var failures = 0;
      var kind = WeekKind.build;
      for (final s in run.sets) {
        if (s.week != w || s.exerciseId != id) {
          continue;
        }
        sets++;
        kind = s.weekKind;
        final load = s.loadKg;
        if (load != null && (topLoad == null || load > topLoad)) {
          topLoad = load;
        }
        if (s.amount > topAmount) {
          topAmount = s.amount;
        }
        trueSum += s.trueRir;
        wantSum += s.wantRir;
        if (s.failed && !s.plannedFailure) {
          failures++;
        }
      }
      if (sets == 0) {
        continue;
      }
      double? truth;
      double? estimate;
      for (final e in run.estimates) {
        if (e.week == w && e.exerciseId == id) {
          truth = e.truth;
          estimate = e.capacity;
        }
      }
      rows.add(
        TrajectoryRow(
          week: w,
          weekKind: kind,
          exerciseId: id,
          sets: sets,
          topLoadKg: topLoad,
          topAmount: topAmount,
          meanTrueRir: trueSum / sets,
          meanWantRir: wantSum / sets,
          failures: failures,
          truth: truth,
          estimate: estimate,
        ),
      );
    }
  }

  // Mesures : celles de la campagne de validation de `kalis_adapt`
  // (classe `Metrics`), calculées sur cette seule simulation.
  final m = Metrics(<SimRun>[run]);
  var work = 0;
  for (final s in run.sets) {
    if (s.weekKind != WeekKind.test) {
      work++;
    }
  }
  final gains = <String, Object?>{};
  var gainSum = 0.0;
  var gainCount = 0;
  for (final id in followed) {
    final g = run.gain[id];
    if (g != null) {
      gains[id] = _r(g * 100);
      gainSum += g;
      gainCount++;
    }
  }
  // Performance à l'échéance : meilleure série de la semaine de
  // l'échéance sur chaque exercice visé, rapportée à la meilleure série
  // des semaines précédentes (1RM estimé de charge totale pour un exercice
  // chargé, répétitions ou secondes sinon). `null` quand l'exercice n'est
  // pas fait cette semaine-là.
  final bodyWeight = bench.bodyWeightKg ?? defaultBodyWeightKg;
  final eventPerformance = <String, Object?>{};
  var ratioSum = 0.0;
  var ratioCount = 0;
  var eventTargets = 0;
  final event = bench.mainEvent;
  if (event != null) {
    final at = event.weeksOut - 1;
    for (final t in event.targets) {
      eventTargets++;
      final fraction =
          catalog.find(t.exerciseId)?.bodyweightFraction?.value ?? 0;
      double scoreOf(SetRow s) {
        if (s.mode != CapacityMode.loaded) {
          return s.amount.toDouble();
        }
        final total = (s.loadKg ?? 0) + fraction * bodyWeight;
        return total * (1 + s.amount / epleyDivisor);
      }

      var atEvent = 0.0;
      var before = 0.0;
      for (final s in run.sets) {
        if (s.exerciseId != t.exerciseId || s.amount <= 0 || s.failed) {
          continue;
        }
        final score = scoreOf(s);
        if (s.week == at) {
          if (score > atEvent) {
            atEvent = score;
          }
        } else if (s.week < at && score > before) {
          before = score;
        }
      }
      if (atEvent > 0 && before > 0) {
        eventPerformance[t.exerciseId] = _r(atEvent / before);
        ratioSum += atEvent / before;
        ratioCount++;
      } else {
        eventPerformance[t.exerciseId] = null;
      }
    }
  }
  final proposals = <String, int>{};
  for (final p in run.proposals) {
    proposals[p.kind.code] = (proposals[p.kind.code] ?? 0) + 1;
  }
  final metrics = <String, Object?>{
    'weeks': horizon,
    'sessionsPlanned': run.sessionsPlanned,
    'sessionsDone': run.sessionsDone,
    'sessionsAdjusted': run.sessionsAdjusted,
    'workSets': work,
    'unwantedFailureRate': _r(m.failRate.mean),
    'nearFailureRate': _r(m.nearFailureRate.mean),
    'rirGapReachable': _r(m.rirMae.mean),
    'rirGapAll': _r(m.rirMaeAll.mean),
    'reachableShare': _r(m.reachableShare.mean),
    'maxMainLoadRise': _r(m.maxMainRise),
    'mainRisesOverTenPercent': m.mainRisesOverTen,
    'mainSingleStepsOverTenPercent': m.mainSingleStepsOverTen,
    'weeklyGainPercent': gains,
    'meanWeeklyGainPercent': gainCount == 0
        ? null
        : _r(gainSum / gainCount * 100),
    'eventPerformance': eventPerformance,
    'eventTargets': eventTargets,
    'eventTargetsTested': ratioCount,
    'meanEventPerformance': ratioCount == 0 ? null : _r(ratioSum / ratioCount),
    'unlockWeek': <String, Object?>{
      for (final e in run.unlockWeek.entries) e.key.code: e.value + 1,
    },
    'proposalsApplied': proposals,
    'proposalsWithheld': Map<String, Object?>.of(run.withheld),
    'painAggravations': run.painAggravations,
    'blocks': run.blocks.length,
  };
  return Trajectory(
    profile: bench,
    run: run,
    weeks: horizon,
    rows: rows,
    metrics: metrics,
    mainExerciseIds: followed,
  );
}
