/// Mesures d'une campagne de simulation : erreur de capacité, écart au RIR
/// visé, échecs, progression, stabilité, sécurité.
library;

import 'package:kalis_core/kalis_core.dart';

import '../filter.dart';
import '../numeric.dart';
import 'runner.dart';

/// Moyenne et erreur standard d'une mesure calculée graine par graine.
final class Stat {
  /// Moyenne [mean], erreur standard [se], sur [n] graines.
  const Stat(this.mean, this.se, this.n);

  /// Statistique des valeurs [values] (une par graine).
  factory Stat.of(List<double> values) {
    final n = values.length;
    if (n == 0) {
      return const Stat(0, 0, 0);
    }
    var sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    final mean = sum / n;
    if (n < 2) {
      return Stat(mean, 0, n);
    }
    var ss = 0.0;
    for (final v in values) {
      ss += sq(v - mean);
    }
    return Stat(mean, sqrt(ss / (n - 1) / n), n);
  }

  /// Moyenne.
  final double mean;

  /// Erreur standard de la moyenne.
  final double se;

  /// Nombre de graines.
  final int n;

  /// Objet JSON (moyenne et erreur standard arrondies).
  Map<String, Object?> toJson() => <String, Object?>{
    'mean': roundTo(mean, 5),
    'se': roundTo(se, 5),
    'n': n,
  };
}

/// Séances d'un exercice comptées comme calibrage par les mesures (les
/// mêmes pour toutes les politiques).
const int metricCalibrationSessions = 3;

/// Rangs de séance auxquels l'erreur de capacité est rapportée.
const List<int> metricSessionRanks = <int>[1, 3, 6, 12];

/// Mesures d'un athlète sous une politique.
final class Metrics {
  /// Mesures des simulations [runs] (un athlète, une politique, une
  /// graine par simulation).
  Metrics(List<SimRun> runs)
    : athlete = runs.isEmpty ? '' : runs.first.athlete,
      policy = runs.isEmpty ? '' : runs.first.policy,
      runs = runs.length {
    final maes = <double>[];
    final maesAll = <double>[];
    final shares = <double>[];
    final biases = <double>[];
    final maesLoaded = <double>[];
    final maesBody = <double>[];
    final fails = <double>[];
    final nears = <double>[];
    final gains = <double>[];
    final reversals = <double>[];
    final moves = <double>[];
    final adherence = <double>[];
    final adjusted = <double>[];
    final aggravations = <double>[];
    final capacity = <int, List<double>>{};
    final operational = <int, List<double>>{};
    final byRank = <int, List<double>>{};
    final byWeek = <int, List<double>>{};
    var covered = 0;
    var coverable = 0;
    for (final run in runs) {
      var errorSum = 0.0;
      var biasSum = 0.0;
      var errorCount = 0;
      var allSum = 0.0;
      var allCount = 0;
      var loadedSum = 0.0;
      var loadedCount = 0;
      var bodySum = 0.0;
      var bodyCount = 0;
      var work = 0;
      var failed = 0;
      var near = 0;
      final weekSum = <int, double>{};
      final weekCount = <int, int>{};
      final firsts = <String, List<double>>{};
      for (final s in run.sets) {
        if (s.weekKind == WeekKind.test) {
          continue;
        }
        if (s.setIndex == 0 &&
            s.loadKg != null &&
            s.exerciseSession >= metricCalibrationSessions) {
          firsts.putIfAbsent(s.exerciseId, () => <double>[]).add(s.loadKg!);
        }
        if (s.exerciseSession < metricCalibrationSessions) {
          continue;
        }
        work++;
        if (s.failed && !s.plannedFailure) {
          failed++;
        }
        if (s.trueRir < 0.5 && s.wantRir >= 2) {
          near++;
        }
        final rise = s.rise;
        if (rise != null && s.main && rise > maxMainRise) {
          maxMainRise = rise;
        }
        if (rise != null && s.main && rise > 0.10 + 1e-9) {
          mainRisesOverTen++;
        }
        if (s.plannedFailure) {
          continue;
        }
        final e = (s.trueRir - s.wantRir).abs();
        allSum += e;
        allCount++;
        if (!s.reachable) {
          continue;
        }
        errorSum += e;
        biasSum += s.trueRir - s.wantRir;
        errorCount++;
        if (s.mode == CapacityMode.loaded) {
          loadedSum += e;
          loadedCount++;
        } else {
          bodySum += e;
          bodyCount++;
        }
        weekSum[s.week] = (weekSum[s.week] ?? 0) + e;
        weekCount[s.week] = (weekCount[s.week] ?? 0) + 1;
      }
      if (errorCount > 0) {
        maes.add(errorSum / errorCount);
        biases.add(biasSum / errorCount);
      }
      if (allCount > 0) {
        maesAll.add(allSum / allCount);
        shares.add(errorCount / allCount);
      }
      if (loadedCount > 0) {
        maesLoaded.add(loadedSum / loadedCount);
      }
      if (bodyCount > 0) {
        maesBody.add(bodySum / bodyCount);
      }
      if (work > 0) {
        fails.add(failed / work);
        nears.add(near / work);
      }
      for (final e in weekSum.entries) {
        byWeek
            .putIfAbsent(e.key, () => <double>[])
            .add(e.value / weekCount[e.key]!);
      }
      // Stabilité : changements de sens de la charge de première série.
      var moved = 0;
      var reversed = 0;
      for (final loads in firsts.values) {
        var direction = 0;
        for (var i = 1; i < loads.length; i++) {
          final d = loads[i] > loads[i - 1] + 1e-9
              ? 1
              : (loads[i] < loads[i - 1] - 1e-9 ? -1 : 0);
          if (d == 0) {
            continue;
          }
          moved++;
          if (direction != 0 && d != direction) {
            reversed++;
          }
          direction = d;
        }
      }
      moves.add(moved.toDouble());
      if (moved > 0) {
        reversals.add(reversed / moved);
      }
      // Estimation.
      final capacityRun = <int, List<double>>{};
      final operationalRun = <int, List<double>>{};
      final rankRun = <int, List<double>>{};
      for (final e in run.estimates) {
        if (e.truth <= 0 || e.truthOperational <= 0) {
          continue;
        }
        final capacityError = (e.capacity / e.truth - 1).abs();
        final operationalError = (e.operational / e.truthOperational - 1).abs();
        if (metricSessionRanks.contains(e.exerciseSession)) {
          capacityRun
              .putIfAbsent(e.exerciseSession, () => <double>[])
              .add(capacityError);
          operationalRun
              .putIfAbsent(e.exerciseSession, () => <double>[])
              .add(operationalError);
        }
        if (e.exerciseSession <= convergenceRanks) {
          rankRun
              .putIfAbsent(e.exerciseSession, () => <double>[])
              .add(operationalError);
        }
        if (e.exerciseSession >= metricCalibrationSessions && e.relSd > 0) {
          coverable++;
          if (ln(e.capacity / e.truth).abs() <= 1.96 * e.relSd) {
            covered++;
          }
        }
      }
      void fold(Map<int, List<double>> from, Map<int, List<double>> into) {
        for (final e in from.entries) {
          into.putIfAbsent(e.key, () => <double>[]).add(_mean(e.value));
        }
      }

      fold(capacityRun, capacity);
      fold(operationalRun, operational);
      fold(rankRun, byRank);
      if (run.gain.isNotEmpty) {
        gains.add(_mean(run.gain.values.toList()));
      }
      if (run.sessionsPlanned > 0) {
        adherence.add(run.sessionsDone / run.sessionsPlanned);
      }
      if (run.sessionsDone > 0) {
        adjusted.add(run.sessionsAdjusted / run.sessionsDone);
      }
      aggravations.add(run.painAggravations.toDouble());
    }
    rirMae = Stat.of(maes);
    rirMaeAll = Stat.of(maesAll);
    reachableShare = Stat.of(shares);
    rirBias = Stat.of(biases);
    rirMaeLoaded = Stat.of(maesLoaded);
    rirMaeBodyweight = Stat.of(maesBody);
    failRate = Stat.of(fails);
    nearFailureRate = Stat.of(nears);
    gain = Stat.of(gains);
    reversalRate = Stat.of(reversals);
    loadMoves = Stat.of(moves);
    sessionsDoneShare = Stat.of(adherence);
    sessionsAdjustedShare = Stat.of(adjusted);
    painAggravations = Stat.of(aggravations);
    for (final rank in metricSessionRanks) {
      final c = capacity[rank];
      final o = operational[rank];
      if (c != null && o != null) {
        capacityError[rank] = Stat.of(c);
        operationalError[rank] = Stat.of(o);
      }
    }
    for (var rank = 1; rank <= convergenceRanks; rank++) {
      final v = byRank[rank];
      convergence.add(v == null ? null : _mean(v));
    }
    final lastWeek = byWeek.keys.fold<int>(-1, (a, b) => a > b ? a : b);
    for (var w = 0; w <= lastWeek; w++) {
      final v = byWeek[w];
      rirMaeByWeek.add(v == null ? null : _mean(v));
    }
    coverage95 = coverable == 0 ? null : covered / coverable;
  }

  /// Nombre de rangs de séance de la courbe de convergence.
  static const int convergenceRanks = 20;

  /// Athlète.
  final String athlete;

  /// Politique.
  final String policy;

  /// Nombre de graines.
  final int runs;

  /// Écart absolu moyen entre RIR réel et RIR affiché, après calibrage,
  /// hors séries ouvertes et semaines de test, sur les séries dont la cible
  /// est atteignable (plage du bloc et matériel de l'athlète).
  late final Stat rirMae;

  /// Le même écart sur toutes les séries, cible atteignable ou non.
  late final Stat rirMaeAll;

  /// Part des séries dont la cible est atteignable.
  late final Stat reachableShare;

  /// Écart moyen signé (positif : séries plus faciles que visé).
  late final Stat rirBias;

  /// Écart absolu moyen, exercices chargés.
  late final Stat rirMaeLoaded;

  /// Écart absolu moyen, exercices au poids du corps et tenues.
  late final Stat rirMaeBodyweight;

  /// Part des séries à l'échec non prévu, après calibrage.
  late final Stat failRate;

  /// Part des séries finies à moins de 0,5 répétition de l'échec quand la
  /// cible en laissait au moins 2.
  late final Stat nearFailureRate;

  /// Gain moyen de capacité vraie par semaine (`ln`), entre la première
  /// et la dernière séance de chaque exercice suivi au moins trois
  /// semaines.
  late final Stat gain;

  /// Part des changements de charge qui inversent le précédent.
  late final Stat reversalRate;

  /// Changements de charge de première série par simulation.
  late final Stat loadMoves;

  /// Part des séances prévues qui ont été faites.
  late final Stat sessionsDoneShare;

  /// Part des séances ajustées (bilan santé, douleur, lieu, temps).
  late final Stat sessionsAdjustedShare;

  /// Hausses de charge sur la zone douloureuse après signalement.
  late final Stat painAggravations;

  /// Erreur relative absolue de la capacité estimée après 1, 3, 6 et 12
  /// séances de l'exercice.
  final Map<int, Stat> capacityError = <int, Stat>{};

  /// Erreur relative absolue de la capacité opérationnelle (charge du
  /// milieu de plage au RIR visé) aux mêmes rangs.
  final Map<int, Stat> operationalError = <int, Stat>{};

  /// Erreur opérationnelle moyenne par rang de séance (1 à 20).
  final List<double?> convergence = <double?>[];

  /// Écart absolu moyen au RIR visé, par semaine de simulation.
  final List<double?> rirMaeByWeek = <double?>[];

  /// Part des estimations dont l'intervalle annoncé à 95 % contient la
  /// vérité (après calibrage), ou `null` sans estimation.
  late final double? coverage95;

  /// Plus forte hausse de charge totale d'une séance à l'autre sur un
  /// mouvement principal, après calibrage.
  double maxMainRise = 0;

  /// Nombre de ces hausses au-dessus de 10 %.
  int mainRisesOverTen = 0;

  /// Objet JSON des mesures.
  Map<String, Object?> toJson() => <String, Object?>{
    'athlete': athlete,
    'policy': policy,
    'runs': runs,
    'rirMae': rirMae.toJson(),
    'rirMaeAll': rirMaeAll.toJson(),
    'reachableShare': reachableShare.toJson(),
    'rirBias': rirBias.toJson(),
    'rirMaeLoaded': rirMaeLoaded.toJson(),
    'rirMaeBodyweight': rirMaeBodyweight.toJson(),
    'failRate': failRate.toJson(),
    'nearFailureRate': nearFailureRate.toJson(),
    'gain': gain.toJson(),
    'reversalRate': reversalRate.toJson(),
    'loadMoves': loadMoves.toJson(),
    'sessionsDoneShare': sessionsDoneShare.toJson(),
    'sessionsAdjustedShare': sessionsAdjustedShare.toJson(),
    'painAggravations': painAggravations.toJson(),
    'capacityError': <String, Object?>{
      for (final e in capacityError.entries) '${e.key}': e.value.toJson(),
    },
    'operationalError': <String, Object?>{
      for (final e in operationalError.entries) '${e.key}': e.value.toJson(),
    },
    'convergence': <Object?>[
      for (final v in convergence) v == null ? null : roundTo(v, 5),
    ],
    'rirMaeByWeek': <Object?>[
      for (final v in rirMaeByWeek) v == null ? null : roundTo(v, 4),
    ],
    'coverage95': coverage95 == null ? null : roundTo(coverage95!, 4),
    'maxMainRise': roundTo(maxMainRise, 4),
    'mainRisesOverTen': mainRisesOverTen,
  };
}

double _mean(List<double> values) {
  if (values.isEmpty) {
    return 0;
  }
  var sum = 0.0;
  for (final v in values) {
    sum += v;
  }
  return sum / values.length;
}

/// Différence appariée (mêmes graines) d'une mesure par simulation entre
/// deux politiques : moyenne de `a − b` et son erreur standard.
Stat pairedDifference(
  List<SimRun> a,
  List<SimRun> b,
  double? Function(SimRun run) measure,
) {
  final bySeed = <int, double>{};
  for (final run in b) {
    final v = measure(run);
    if (v != null) {
      bySeed[run.seed] = v;
    }
  }
  final diffs = <double>[];
  for (final run in a) {
    final v = measure(run);
    final w = bySeed[run.seed];
    if (v != null && w != null) {
      diffs.add(v - w);
    }
  }
  return Stat.of(diffs);
}

/// Écart absolu moyen au RIR visé d'une simulation (après calibrage, hors
/// semaines de test, cibles atteignables), ou `null` sans série.
double? runRirMae(SimRun run) {
  var sum = 0.0;
  var count = 0;
  for (final s in run.sets) {
    if (s.weekKind == WeekKind.test ||
        s.plannedFailure ||
        !s.reachable ||
        s.exerciseSession < metricCalibrationSessions) {
      continue;
    }
    sum += (s.trueRir - s.wantRir).abs();
    count++;
  }
  return count == 0 ? null : sum / count;
}

/// Gain moyen de capacité vraie d'une simulation, ou `null`.
double? runGain(SimRun run) =>
    run.gain.isEmpty ? null : _mean(run.gain.values.toList());

/// Mesures de la boucle complète (revues, propositions, déblocage).
final class LoopMetrics {
  /// Mesures des simulations en boucle complète [runs].
  LoopMetrics(List<SimRun> runs)
    : athlete = runs.isEmpty ? '' : runs.first.athlete,
      runs = runs.length {
    final counts = <ProposalKind, List<double>>{
      for (final k in ProposalKind.values) k: <double>[],
    };
    final flips = <double>[];
    final unlock = <UnlockLevel, List<double>>{
      for (final l in UnlockLevel.values) l: <double>[],
    };
    for (final run in runs) {
      final perKind = <ProposalKind, int>{};
      final lastVolume = <String, (int, bool)>{};
      var flipped = 0;
      var volumes = 0;
      for (final p in run.proposals) {
        perKind[p.kind] = (perKind[p.kind] ?? 0) + 1;
        if (p.kind == ProposalKind.volume) {
          // volume:<groupe>:<up|down>:<bloc>@<semaine>
          final parts = p.id.split(':');
          if (parts.length >= 3) {
            volumes++;
            final up = parts[2] == 'up';
            final before = lastVolume[parts[1]];
            if (before != null && before.$2 != up && p.week - before.$1 <= 6) {
              flipped++;
            }
            lastVolume[parts[1]] = (p.week, up);
          }
        }
      }
      for (final k in ProposalKind.values) {
        counts[k]!.add((perKind[k] ?? 0).toDouble());
      }
      if (volumes > 0) {
        flips.add(flipped / volumes);
      }
      for (final l in UnlockLevel.values) {
        final w = run.unlockWeek[l];
        if (w != null) {
          unlock[l]!.add(w + 1.0);
        }
      }
    }
    for (final k in ProposalKind.values) {
      proposals[k] = Stat.of(counts[k]!);
    }
    volumeFlipRate = Stat.of(flips);
    for (final l in UnlockLevel.values) {
      unlockWeek[l] = Stat.of(unlock[l]!);
    }
    base = Metrics(runs);
  }

  /// Athlète.
  final String athlete;

  /// Nombre de graines.
  final int runs;

  /// Propositions appliquées par simulation, par nature.
  final Map<ProposalKind, Stat> proposals = <ProposalKind, Stat>{};

  /// Part des propositions de volume qui inversent la précédente du même
  /// groupe à moins de six semaines.
  late final Stat volumeFlipRate;

  /// Semaine (1 = première) où chaque niveau de déblocage est atteint ;
  /// `n` = nombre de simulations qui l'atteignent.
  final Map<UnlockLevel, Stat> unlockWeek = <UnlockLevel, Stat>{};

  /// Mesures générales des mêmes simulations.
  late final Metrics base;

  /// Objet JSON des mesures.
  Map<String, Object?> toJson() => <String, Object?>{
    'athlete': athlete,
    'runs': runs,
    'proposals': <String, Object?>{
      for (final e in proposals.entries) e.key.code: e.value.toJson(),
    },
    'volumeFlipRate': volumeFlipRate.toJson(),
    'unlockWeek': <String, Object?>{
      for (final e in unlockWeek.entries) e.key.code: e.value.toJson(),
    },
    'base': base.toJson(),
  };
}
