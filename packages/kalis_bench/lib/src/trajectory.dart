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

/// Niveau de déblocage qu'exige chaque nature de proposition appliquée
/// d'office (décision D5.7 du pipeline GP). Les natures absentes de la
/// table (décharge, épargne d'une zone douloureuse, calendrier) ne
/// dépendent pas du déblocage.
const Map<ProposalKind, UnlockLevel> requiredUnlock =
    <ProposalKind, UnlockLevel>{
      ProposalKind.load: UnlockLevel.loadsReps,
      ProposalKind.reps: UnlockLevel.loadsReps,
      ProposalKind.volume: UnlockLevel.volume,
      ProposalKind.exerciseSwap: UnlockLevel.exerciseSwap,
      ProposalKind.sessionRestructure: UnlockLevel.sessionRestructure,
      ProposalKind.blockRestructure: UnlockLevel.blockRestructure,
    };

/// Repères de verdict d'une trajectoire (choix raisonnés, voir
/// `docs/CRITERES.md`).
abstract final class TrajectoryLimits {
  /// Part maximale d'échecs non voulus parmi les séries de travail.
  static const double unwantedFailureRate = 0.05;

  /// Écart absolu moyen maximal au RIR visé, cibles atteignables (cible de
  /// la validation de `kalis_adapt` : 1 répétition).
  static const double rirGap = 1;

  /// Hausses de plus de 10 % d'un mouvement principal admises.
  static const int mainRisesOverTenPercent = 0;

  /// Performance minimale à l'échéance, rapportée à la meilleure série des
  /// semaines précédentes.
  static const double eventPerformance = 1;
}

/// Verdicts d'une trajectoire d'après ses mesures [metrics] : code →
/// `true` (tenu), `false` (non tenu) ou `null` (sans objet).
Map<String, bool?> trajectoryVerdicts(Map<String, Object?> metrics) {
  double? number(String key) {
    final v = metrics[key];
    return v is num ? v.toDouble() : null;
  }

  final failures = number('unwantedFailureRate');
  final gap = number('rirGapReachable');
  final rises = number('mainRisesOverTenPercent');
  final event = number('meanEventPerformance');
  final unlock = number('unlockViolations');
  final pain = number('painAggravations');
  return <String, bool?>{
    'echecs_non_voulus': failures == null
        ? null
        : failures <= TrajectoryLimits.unwantedFailureRate + 1e-9,
    'ecart_rir': gap == null ? null : gap <= TrajectoryLimits.rirGap + 1e-9,
    'pics_de_charge': rises == null
        ? null
        : rises <= TrajectoryLimits.mainRisesOverTenPercent,
    'performance_echeance': event == null
        ? null
        : event >= TrajectoryLimits.eventPerformance - 1e-9,
    'deblocages': unlock == null ? null : unlock <= 0,
    'douleur': pain == null ? null : pain <= 0,
    if (metrics['coached'] == true) ...<String, bool?>{
      'ecart_effort': number('effortGap') == null
          ? null
          : number('effortGap')! <= TrajectoryLimits.rirGap + 1e-9,
      'pics_a_schema_egal': number('schemeRisesOverLimit') == null
          ? null
          : number('schemeRisesOverLimit')! <= 0,
      'ouvertures': number('openerRate') == null
          ? null
          : number('openerRate')! >= 1 - 1e-9,
    },
  };
}

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
    this.truth = TruthKind.a,
    this.coached = false,
  });

  /// Modèle de vérité de l'athlète simulé.
  final TruthKind truth;

  /// Programme au contrat 0.4.0 (parts du 1RM, techniques, tests).
  final bool coached;

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
  TruthKind truth = TruthKind.a,
  bool legacy = false,
}) {
  final horizon = weeks ?? horizonOf(bench);
  final engine = KalisAdapt(legacy: legacy);
  final run = simulate(
    catalog: catalog,
    spec: athleteSpecOf(bench),
    profile: profile,
    seed: seed,
    policy: KalisAdaptPolicy(engine),
    program: SimProgram(catalog, plan, profile, seed: seed),
    weeks: horizon,
    loop: engine,
    truthKind: truth,
  );
  final coached = run.blocks.isNotEmpty && blockCoached(run.blocks.first);
  final cm = CoachMetrics(<SimRun>[run]);

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
  var unlockViolations = 0;
  for (final p in run.proposals) {
    proposals[p.kind.code] = (proposals[p.kind.code] ?? 0) + 1;
    // Respect des déblocages : une proposition appliquée d'office avant
    // que son niveau soit débloqué est une violation.
    final need = requiredUnlock[p.kind];
    if (need != null) {
      final unlockedAt = run.unlockWeek[need];
      if (unlockedAt == null || p.week < unlockedAt) {
        unlockViolations++;
      }
    }
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
    'unlockViolations': unlockViolations,
    'proposalsWithheld': Map<String, Object?>.of(run.withheld),
    'painAggravations': run.painAggravations,
    'blocks': run.blocks.length,
    'truth': truth.name,
    'coached': coached,
    'effortGap': _r(cm.effortGap.mean),
    'effortBias': _r(cm.effortBias.mean),
    'harderRate': _r(cm.harderRate.mean),
    'easierRate': _r(cm.easierRate.mean),
    'coachFailureRate': _r(cm.failRate.mean),
    'maxSchemeRise': _r(cm.maxSchemeRise),
    'schemeRisesOverLimit': cm.schemeRisesOverLimit,
    'attempts': cm.attempts,
    'attemptsMade': cm.attemptsMade,
    'openerRate': cm.openerRate.n == 0 ? null : _r(cm.openerRate.mean),
    'eventOverDayMax': cm.eventPerformance.n == 0
        ? null
        : _r(cm.eventPerformance.mean),
  };
  // Écart d'effort par exercice (mise au point) : séries, effort visé
  // moyen, effort réel moyen.
  final byExercise = <String, List<double>>{};
  for (final s in run.sets) {
    if (s.test || s.plannedFailure) {
      continue;
    }
    final e = byExercise.putIfAbsent(s.exerciseId, () => <double>[0, 0, 0]);
    e[0] += 1;
    e[1] += s.wantRir;
    e[2] += s.trueRir;
  }
  metrics['effortByExercise'] = <String, Object?>{
    for (final e in byExercise.entries)
      e.key: <Object?>[
        e.value[0].round(),
        _r(e.value[1] / e.value[0]),
        _r(e.value[2] / e.value[0]),
      ],
  };
  metrics['verdicts'] = trajectoryVerdicts(metrics);
  return Trajectory(
    profile: bench,
    run: run,
    weeks: horizon,
    rows: rows,
    metrics: metrics,
    mainExerciseIds: followed,
    truth: truth,
    coached: coached,
  );
}
