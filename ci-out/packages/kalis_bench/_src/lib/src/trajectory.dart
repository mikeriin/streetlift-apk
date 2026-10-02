/// Trajectoires : un athlète simulé à vérité connue (simulateur de
/// `kalis_adapt`, lu et appelé tel quel) suit le programme du profil sous
/// le moteur d'évolution, boucle complète (revue chaque semaine,
/// propositions appliquées, bloc suivant d'après le résumé d'adaptation).
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';
import 'program.dart';

/// Gain hebdomadaire de base de la vérité (`ln` de la capacité, à dose
/// pleine) par niveau : valeurs de la campagne de validation de
/// `kalis_adapt` (débutant, intermédiaire, avancé) ; l'élite est un choix
/// raisonné (la moitié de l'avancé).
const List<double> defaultWeeklyGain = <double>[0.012, 0.004, 0.0015, 0.0008];

/// Hausse de la charge totale au-delà de laquelle une séance compte comme
/// un pic de charge (R5-P22 : 10 %).
const double loadSpikeRise = 0.10;

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

  // Mesures.
  var work = 0;
  var failed = 0;
  var gapSum = 0.0;
  var spikes = 0;
  var maxRise = 0.0;
  for (final s in run.sets) {
    if (s.weekKind == WeekKind.test) {
      continue;
    }
    work++;
    if (s.failed && !s.plannedFailure) {
      failed++;
    }
    gapSum += (s.trueRir - s.wantRir).abs();
    final rise = s.rise;
    if (rise != null) {
      if (rise > maxRise) {
        maxRise = rise;
      }
      if (rise > loadSpikeRise) {
        spikes++;
      }
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
  // Performance le jour de l'échéance : capacité vraie de la dernière
  // semaine rapportée à la plus haute capacité vraie de la trajectoire.
  final eventRatio = <String, Object?>{};
  var ratioSum = 0.0;
  var ratioCount = 0;
  final event = bench.mainEvent;
  if (event != null) {
    for (final t in event.targets) {
      double? atEvent;
      var best = 0.0;
      for (final e in run.estimates) {
        if (e.exerciseId != t.exerciseId) {
          continue;
        }
        if (e.truth > best) {
          best = e.truth;
        }
        if (e.week <= event.weeksOut - 1) {
          atEvent = e.truth;
        }
      }
      if (atEvent != null && best > 0) {
        eventRatio[t.exerciseId] = _r(atEvent / best);
        ratioSum += atEvent / best;
        ratioCount++;
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
    'unwantedFailureRate': work == 0 ? 0 : _r(failed / work),
    'meanRirGap': work == 0 ? 0 : _r(gapSum / work),
    'loadSpikes': spikes,
    'maxLoadRise': _r(maxRise),
    'weeklyGainPercent': gains,
    'meanWeeklyGainPercent': gainCount == 0
        ? null
        : _r(gainSum / gainCount * 100),
    'eventCapacityRatio': eventRatio,
    'meanEventCapacityRatio': ratioCount == 0
        ? null
        : _r(ratioSum / ratioCount),
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
