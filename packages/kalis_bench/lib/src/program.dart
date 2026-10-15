/// Programme généré pour un profil du banc : le premier bloc de
/// `kalis_plan`, puis ses blocs suivants jusqu'à l'horizon du profil
/// (l'échéance, sinon douze semaines).
library;

import 'package:kalis_core/kalis_core.dart';

import 'adapter.dart';
import 'profile.dart';

/// Horizon par défaut d'un programme sans échéance, en semaines.
const int defaultHorizonWeeks = 12;

/// Plus long horizon généré, en semaines.
const int maxHorizonWeeks = 16;

/// Horizon du profil [p] : semaines jusqu'à son échéance prioritaire (ou
/// son objectif daté le plus lointain), bornées de 4 à [maxHorizonWeeks] ;
/// [defaultHorizonWeeks] sans échéance.
int horizonOf(BenchProfile p) {
  var weeks = 0;
  final main = p.mainEvent;
  if (main != null) {
    weeks = main.weeksOut;
  } else {
    for (final e in p.events) {
      if (e.weeksOut > weeks) {
        weeks = e.weeksOut;
      }
    }
    for (final g in p.goals) {
      if (g.weeksOut > weeks) {
        weeks = g.weeksOut;
      }
    }
  }
  if (weeks == 0) {
    return defaultHorizonWeeks;
  }
  if (weeks < 4) {
    return 4;
  }
  return weeks > maxHorizonWeeks ? maxHorizonWeeks : weeks;
}

/// Programme d'un profil du banc.
final class BenchProgram {
  /// Programme.
  BenchProgram({
    required this.bench,
    required this.adapted,
    required this.request,
    required this.blocks,
    required this.horizonWeeks,
  });

  /// Profil du banc.
  final BenchProfile bench;

  /// Profil des moteurs et informations perdues.
  final AdaptedProfile adapted;

  /// Requête de création du premier bloc.
  final PlanRequest request;

  /// Blocs, dans l'ordre.
  final List<ProgramBlock> blocks;

  /// Semaines analysées et exportées (les semaines d'un dernier bloc qui
  /// dépassent l'horizon sont ignorées).
  final int horizonWeeks;

  /// Profil des moteurs.
  AthleteProfile get profile => adapted.profile;

  /// Semaines générées au total.
  int get generatedWeeks {
    var total = 0;
    for (final b in blocks) {
      total += b.pass1.weeks;
    }
    return total;
  }
}

/// Résumé d'adaptation neutre (aucune donnée de séance), celui des
/// simulations de `kalis_adapt` à programme égal.
AdaptationSummary neutralAdaptation(CivilDate asOf, int weeks, int sessions) =>
    AdaptationSummary(
      asOf: asOf,
      weeksObserved: weeks,
      sessionsPlanned: sessions,
      sessionsCompleted: sessions,
      unlockLevel: UnlockLevel.loadsReps,
      confidence: 0,
      estimates: const <ExerciseEstimate>[],
      pains: const <PainTrend>[],
      avoidedExerciseIds: const <String>[],
      reasons: const <Reason>[],
    );

/// Programme du profil [bench] créé par le moteur [engine] (graine
/// [seed]) : premier bloc, puis blocs suivants sans donnée de séance,
/// jusqu'à couvrir l'horizon.
BenchProgram generateProgram(
  Catalog catalog,
  PlanEngine engine,
  BenchProfile bench, {
  int seed = 0,
}) {
  final adapted = adaptProfile(bench, catalog: catalog);
  final problems = catalog.checkProfile(adapted.profile);
  if (problems.isNotEmpty) {
    throw ArgumentError.value(
      bench.key,
      'profil',
      'inconnu du catalogue : ${problems.join(' ; ')}',
    );
  }
  final horizon = horizonOf(bench);
  final request = PlanRequest(
    profile: adapted.profile,
    seed: seed,
    startDate: benchStartDate,
    locks: const <PlanLock>[],
  );
  final pass1 = engine.createPass1(catalog, request);
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  final blocks = <ProgramBlock>[ProgramBlock(pass1: pass1, pass2: pass2)];
  var weeks = pass1.weeks;
  while (weeks < horizon) {
    final previous = blocks.last;
    final start = benchStartDate.addDays(7 * weeks);
    final next = engine
        .nextBlock(
          catalog,
          NextBlockRequest(
            profile: adapted.profile,
            seed: seed,
            startDate: start,
            previous: previous,
            adaptation: neutralAdaptation(
              start.addDays(-1),
              weeks,
              weeks * previous.pass1.days.length,
            ),
            locks: const <PlanLock>[],
          ),
        )
        .block;
    blocks.add(next);
    weeks += next.pass1.weeks;
  }
  return BenchProgram(
    bench: bench,
    adapted: adapted,
    request: request,
    blocks: blocks,
    horizonWeeks: horizon,
  );
}
