/// Déroulement d'une simulation : un athlète à vérité connue suit pendant
/// des semaines le programme de `kalis_plan`, piloté par une politique.
library;

import 'package:kalis_core/kalis_core.dart';

import '../apply.dart';
import '../book.dart';
import '../engine.dart';
import '../filter.dart';
import '../numeric.dart' show ln;
import '../review.dart';
import 'policy.dart';
import 'rng.dart';
import 'truth.dart';

/// Premier jour des simulations (un lundi).
final CivilDate simStartDate = CivilDate(2026, 10, 5);

/// Programme commun à toutes les politiques et à toutes les graines d'un
/// profil : le premier bloc de `kalis_plan`, puis ses blocs suivants
/// construits sans résumé d'adaptation (résumé neutre), pour que les
/// politiques soient comparées à programme égal.
final class SimProgram {
  /// Programme du profil [profile] par le moteur statique [plan].
  SimProgram(this.catalog, this.plan, this.profile, {this.seed = 0});

  /// Catalogue.
  final Catalog catalog;

  /// Moteur statique.
  final PlanEngine plan;

  /// Profil.
  final AthleteProfile profile;

  /// Graine du programme.
  final int seed;

  final List<ProgramBlock> _blocks = <ProgramBlock>[];

  /// Bloc de rang [index] (créé à la demande).
  ProgramBlock block(int index) {
    while (_blocks.length <= index) {
      if (_blocks.isEmpty) {
        final request = PlanRequest(
          profile: profile,
          seed: seed,
          startDate: simStartDate,
          locks: const <PlanLock>[],
        );
        final pass1 = plan.createPass1(catalog, request);
        final pass2 = plan.createPass2(
          catalog,
          Pass2Request(request: request, pass1: pass1),
        );
        _blocks.add(ProgramBlock(pass1: pass1, pass2: pass2));
        continue;
      }
      final previous = _blocks.last;
      var weeks = 0;
      for (final b in _blocks) {
        weeks += b.pass1.weeks;
      }
      final start = simStartDate.addDays(7 * weeks);
      final sessions = weeks * previous.pass1.days.length;
      _blocks.add(
        plan
            .nextBlock(
              catalog,
              NextBlockRequest(
                profile: profile,
                seed: seed,
                startDate: start,
                previous: previous,
                adaptation: AdaptationSummary(
                  asOf: start.addDays(-1),
                  weeksObserved: weeks,
                  sessionsPlanned: sessions,
                  sessionsCompleted: sessions,
                  unlockLevel: UnlockLevel.loadsReps,
                  confidence: 0,
                  estimates: const <ExerciseEstimate>[],
                  pains: const <PainTrend>[],
                  avoidedExerciseIds: const <String>[],
                  reasons: const <Reason>[],
                ),
                locks: const <PlanLock>[],
              ),
            )
            .block,
      );
    }
    return _blocks[index];
  }
}

/// Une série simulée.
final class SetRow {
  /// Série.
  const SetRow({
    required this.week,
    required this.weekKind,
    required this.exerciseId,
    required this.mode,
    required this.exerciseSession,
    required this.setIndex,
    required this.loadKg,
    required this.amount,
    required this.flames,
    required this.trueRir,
    required this.wantRir,
    required this.failed,
    required this.plannedFailure,
    required this.main,
    required this.open,
    required this.rise,
  });

  /// Semaine de la simulation (0 = première).
  final int week;

  /// Nature de la semaine.
  final WeekKind weekKind;

  /// Exercice.
  final String exerciseId;

  /// Mode de capacité.
  final CapacityMode mode;

  /// Rang de la séance pour cet exercice (0 = première).
  final int exerciseSession;

  /// Rang de la série.
  final int setIndex;

  /// Charge externe, en kg.
  final double? loadKg;

  /// Répétitions ou secondes faites.
  final int amount;

  /// Note donnée.
  final int? flames;

  /// Répétitions réellement en réserve.
  final double trueRir;

  /// RIR affiché comme cible.
  final double wantRir;

  /// Échec.
  final bool failed;

  /// La cible demandait l'échec (10 flammes).
  final bool plannedFailure;

  /// Mouvement principal.
  final bool main;

  /// Série ouverte (série repère, plage au ressenti).
  final bool open;

  /// Hausse relative de la charge totale par rapport à la première série
  /// de la séance précédente de l'exercice (première série seulement),
  /// sinon `null`.
  final double? rise;
}

/// Estimation d'un exercice après une séance, face à la vérité.
final class EstimateRow {
  /// Estimation.
  const EstimateRow({
    required this.week,
    required this.exerciseId,
    required this.mode,
    required this.exerciseSession,
    required this.capacity,
    required this.truth,
    required this.relSd,
    required this.operational,
    required this.truthOperational,
  });

  /// Semaine de la simulation.
  final int week;

  /// Exercice.
  final String exerciseId;

  /// Mode de capacité.
  final CapacityMode mode;

  /// Séances faites sur l'exercice (1 = après la première).
  final int exerciseSession;

  /// Capacité estimée.
  final double capacity;

  /// Capacité vraie.
  final double truth;

  /// Écart-type relatif annoncé.
  final double relSd;

  /// Capacité opérationnelle estimée (charge pour le milieu de plage au
  /// RIR visé).
  final double operational;

  /// Capacité opérationnelle vraie.
  final double truthOperational;
}

/// Proposition émise pendant une simulation en boucle complète.
final class ProposalRow {
  /// Proposition [id] de nature [kind] à la semaine [week].
  const ProposalRow(this.week, this.id, this.kind, this.changes);

  /// Semaine de la simulation.
  final int week;

  /// Identifiant.
  final String id;

  /// Nature.
  final ProposalKind kind;

  /// Nombre de changements appliqués au bloc.
  final int changes;
}

/// Résultat d'une simulation.
final class SimRun {
  /// Résultat.
  SimRun(this.athlete, this.policy, this.seed);

  /// Clé de l'athlète.
  final String athlete;

  /// Nom de la politique.
  final String policy;

  /// Graine.
  final int seed;

  /// Séries.
  final List<SetRow> sets = <SetRow>[];

  /// Estimations.
  final List<EstimateRow> estimates = <EstimateRow>[];

  /// Propositions (boucle complète).
  final List<ProposalRow> proposals = <ProposalRow>[];

  /// Semaine où chaque niveau de déblocage est atteint (boucle complète).
  final Map<UnlockLevel, int> unlockWeek = <UnlockLevel, int>{};

  /// Gain de capacité vraie (`ln` fin / début) par exercice entraîné.
  final Map<String, double> gain = <String, double>{};

  /// Séances prévues.
  int sessionsPlanned = 0;

  /// Séances faites.
  int sessionsDone = 0;

  /// Séances ajustées par le bilan santé, la douleur, le lieu ou le temps.
  int sessionsAdjusted = 0;

  /// Hausses de charge sur la zone douloureuse après signalement.
  int painAggravations = 0;

  /// Séances du journal.
  final List<SessionRecord> sessions = <SessionRecord>[];

  /// Blocs suivis.
  final List<ProgramBlock> blocks = <ProgramBlock>[];
}

int _measureOf(ExercisePrescription item) {
  if (item.secondsHigh != null || item.secondsLow != null) {
    return 1;
  }
  if (item.repsHigh != null || item.repsLow != null) {
    return 0;
  }
  return 2;
}

/// Simule [weeks] semaines de l'athlète [spec] (profil [profile], graine
/// [seed]) sous la politique [policy] et le programme [program].
///
/// Sans [loop], le programme est celui de [program], identique pour toutes
/// les politiques. Avec [loop] (le moteur de la politique `kalis_adapt`),
/// la boucle est complète : revue chaque fin de semaine, propositions
/// appliquées (mode assisté), bloc suivant construit par [SimProgram.plan]
/// à partir du résumé d'adaptation.
SimRun simulate({
  required Catalog catalog,
  required AthleteSpec spec,
  required AthleteProfile profile,
  required int seed,
  required SimPolicy policy,
  required SimProgram program,
  int weeks = 24,
  KalisAdapt? loop,
}) {
  final book = ExerciseBook(catalog, profile);
  final athlete = SimAthlete(spec, profile, book, seed);
  final run = SimRun(spec.key, policy.name, seed);
  final sessions = <SessionRecord>[];
  final exerciseSessions = <String, int>{};
  final lastFirstLoad = <String, double>{};
  final decisions = <ProposalDecision>[];
  Map<String, Object?>? reviewState;
  AdaptationSummary? summary;
  final startDay = simStartDate.dayNumber;

  var blockIndex = 0;
  var block = program.block(0);
  var weekInBlock = 0;
  var blockStart = simStartDate;
  run.blocks.add(block);

  for (var g = 0; g < weeks; g++) {
    if (weekInBlock >= block.pass1.weeks) {
      blockStart = blockStart.addDays(7 * block.pass1.weeks);
      blockIndex++;
      weekInBlock = 0;
      final last = summary;
      if (loop == null || last == null) {
        block = program.block(blockIndex);
      } else {
        block = program.plan
            .nextBlock(
              catalog,
              NextBlockRequest(
                profile: profile,
                seed: block.pass1.seed,
                startDate: blockStart,
                previous: block,
                adaptation: last,
                locks: const <PlanLock>[],
              ),
            )
            .block;
      }
      run.blocks.add(block);
    }
    WeekPrescription? week;
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekInBlock) {
        week = w;
      }
    }
    if (week == null) {
      throw StateError('semaine $weekInBlock absente du bloc');
    }
    final days = <(int, DayPrescription)>[
      for (final d in week.days)
        (scheduledDay(block.pass1, weekInBlock, d.dayIndex), d),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (dayNumber, prescription) in days) {
      final simDay = dayNumber - startDay;
      run.sessionsPlanned++;
      final calendar = SimRandom.of(seed, 'calendar|$simDay');
      final breakFrom = spec.breakFromDay;
      if (breakFrom != null &&
          simDay >= breakFrom &&
          simDay < breakFrom + spec.breakDays) {
        continue;
      }
      if (calendar.next() < spec.missRate) {
        continue;
      }
      athlete.advance(simDay);
      final budget = block.pass1.days[prescription.dayIndex].minutesBudget;
      final health = athlete.healthCheck(budget);
      final otherFrom = spec.otherPlaceFromDay;
      final place =
          otherFrom != null &&
              simDay >= otherFrom &&
              simDay < otherFrom + spec.otherPlaceDays
          ? spec.otherPlace
          : null;
      final context = SessionContext(
        catalog: catalog,
        profile: profile,
        book: book,
        block: block,
        weekIndex: weekInBlock,
        dayIndex: prescription.dayIndex,
        weekKind: week.kind,
        date: CivilDate.fromDayNumber(dayNumber),
        simDay: simDay,
        health: health,
        place: place,
        log: TrainingLog(sessions: List<SessionRecord>.of(sessions)),
        athlete: athlete,
      );
      final session = policy.plan(context);
      if (session.adjustments.isNotEmpty) {
        run.sessionsAdjusted++;
      }
      final done = <SetRecord>[];
      final trained = <(TruthExercise, ExercisePrescription)>[];
      var order = 0;
      for (final item in session.items) {
        final truth = athlete.truthOf(item.exerciseId);
        final measure = _measureOf(item);
        if (truth == null || measure == 2) {
          // Exercice que le moteur ne modélise pas : fait comme prescrit.
          final reps = item.repsHigh ?? item.repsLow;
          final seconds = item.secondsHigh ?? item.secondsLow;
          if (reps != null ||
              seconds != null ||
              item.distanceMeters != null ||
              item.calories != null) {
            for (var i = 0; i < item.sets; i++) {
              done.add(
                SetRecord(
                  exerciseId: item.exerciseId,
                  exerciseOrder: order,
                  setIndex: i,
                  kind: item.kind ?? SetKind.work,
                  reps: reps,
                  seconds: reps == null ? seconds : null,
                  distanceMeters: reps == null && seconds == null
                      ? item.distanceMeters
                      : null,
                  calories:
                      reps == null &&
                          seconds == null &&
                          item.distanceMeters == null
                      ? item.calories
                      : null,
                  flames: item.targetFlames,
                  success: true,
                  excluded: false,
                  slotId: item.slotId,
                ),
              );
            }
          }
          order++;
          continue;
        }
        final hold = truth.mode == CapacityMode.hold;
        final loaded = truth.mode == CapacityMode.loaded;
        if (hold != (measure == 1)) {
          // Prescription dans une autre unité que la capacité : ignorée.
          order++;
          continue;
        }
        athlete.beginExercise(truth, item.slotId);
        final count = exerciseSessions[item.exerciseId] ?? 0;
        final role = context.roleOf(item.slotId);
        final rest = item.restSeconds ?? 90;
        var performed = 0;
        for (var i = 0; i < item.sets; i++) {
          final target = policy.nextSet(context, item, i, done);
          if (target == null) {
            break;
          }
          final flamesTarget = target.flames ?? item.targetFlames ?? 6;
          var low = hold ? target.secondsLow : target.repsLow;
          var high = hold ? target.secondsHigh : target.repsHigh;
          low ??= high;
          high ??= low;
          if (low == null || high == null) {
            break;
          }
          double? load;
          var selfSelected = false;
          if (loaded) {
            load = target.loadKg;
            if (load == null) {
              load = athlete.selfSelect(
                truth,
                high,
                Flames.toRir(flamesTarget),
              );
              selfSelected = true;
            }
          }
          final outcome = athlete.perform(
            truth,
            loadKg: load,
            low: low,
            high: high,
            flamesTarget: flamesTarget,
            restSeconds: rest,
            noiseKey: '$simDay|${item.slotId}|$i',
          );
          done.add(
            SetRecord(
              exerciseId: item.exerciseId,
              exerciseOrder: order,
              setIndex: i,
              kind: item.kind ?? SetKind.work,
              externalLoadKg: load,
              reps: hold ? null : outcome.amount,
              seconds: hold ? outcome.amount : null,
              flames: outcome.flames,
              success: !outcome.failed && outcome.amount >= low,
              excluded: false,
              slotId: item.slotId,
              target: SetTarget(
                repsLow: hold ? null : low,
                repsHigh: hold ? null : high,
                secondsLow: hold ? low : null,
                secondsHigh: hold ? high : null,
                loadKg: selfSelected ? null : load,
                flames: flamesTarget,
              ),
            ),
          );
          double? rise;
          if (i == 0 && load != null) {
            final before = lastFirstLoad[item.exerciseId];
            if (before != null) {
              final bw = truth.info.fraction * athlete.bodyWeightKg;
              rise = (load + bw) / (before + bw) - 1;
            }
            lastFirstLoad[item.exerciseId] = load;
          }
          run.sets.add(
            SetRow(
              week: g,
              weekKind: week.kind,
              exerciseId: item.exerciseId,
              mode: truth.mode,
              exerciseSession: count,
              setIndex: i,
              loadKg: load,
              amount: outcome.amount,
              flames: outcome.flames,
              trueRir: outcome.trueRir,
              wantRir: Flames.toRir(flamesTarget),
              failed: outcome.failed,
              plannedFailure: flamesTarget >= Flames.failure,
              main: role == SlotRole.main,
              open: high > low,
              rise: rise,
            ),
          );
          performed++;
        }
        athlete.endExercise(truth);
        if (performed > 0) {
          exerciseSessions[item.exerciseId] = count + 1;
          trained.add((truth, item));
        }
        order++;
      }
      final record = SessionRecord(
        id: 'sim-$simDay',
        date: context.date,
        origin: SessionOrigin.program,
        programRef: ProgramRef(
          blockId: block.pass1.blockId,
          weekIndex: weekInBlock,
          dayIndex: prescription.dayIndex,
        ),
        resume: false,
        completed: true,
        place: place,
        healthCheck: health,
        sets: done,
        pains: athlete.sessionPains(),
      );
      policy.finish(context, record);
      sessions.add(record);
      run.sessionsDone++;
      final after = context.withLog(
        TrainingLog(sessions: List<SessionRecord>.of(sessions)),
      );
      for (final (truth, item) in trained) {
        var basis = item;
        for (final it in prescription.items) {
          if (it.slotId == item.slotId && it.exerciseId == item.exerciseId) {
            basis = it;
          }
        }
        final flames = basis.targetFlames;
        final hold = truth.mode == CapacityMode.hold;
        final low = hold ? basis.secondsLow : basis.repsLow;
        final high = hold ? basis.secondsHigh : basis.repsHigh;
        final n =
            ((low ?? high ?? 8) + (high ?? low ?? 8)) / 2 +
            (flames == null ? 3.0 : Flames.toRir(flames));
        final estimate = policy.estimate(after, item.exerciseId, n);
        if (estimate == null) {
          continue;
        }
        final loaded = truth.mode == CapacityMode.loaded;
        run.estimates.add(
          EstimateRow(
            week: g,
            exerciseId: item.exerciseId,
            mode: truth.mode,
            exerciseSession: exerciseSessions[item.exerciseId] ?? 0,
            capacity: estimate.capacity,
            truth: truth.capacity,
            relSd: estimate.relSd,
            operational: estimate.operational,
            truthOperational: loaded
                ? truth.capacity * truth.share(n)
                : truth.capacity,
          ),
        );
      }
    }
    athlete.endWeek();

    if (loop != null) {
      // Revue de fin de semaine (dimanche) : propositions appliquées.
      final today = blockStart.addDays(7 * weekInBlock + 6);
      final review = loop.review(
        catalog,
        AdaptInput(
          profile: profile,
          block: block,
          log: TrainingLog(sessions: List<SessionRecord>.of(sessions)),
          today: today,
          state: reviewState,
          decisions: List<ProposalDecision>.of(decisions),
        ),
      );
      reviewState = review.state;
      summary = review.summary;
      for (final level in UnlockLevel.values) {
        if (level.index <= review.summary.unlockLevel.index) {
          run.unlockWeek.putIfAbsent(level, () => g);
        }
      }
      for (final proposal in review.proposals) {
        if (!proposal.autoApplicable) {
          continue;
        }
        final next = applyProposal(block, proposal);
        run.proposals.add(
          ProposalRow(
            g,
            proposal.id,
            proposal.kind,
            proposal.diff?.changes.length ?? 0,
          ),
        );
        decisions.add(
          ProposalDecision(
            proposalId: proposal.id,
            date: today,
            status: ProposalStatus.autoApplied,
          ),
        );
        if (!identical(next, block)) {
          block = next;
          run.blocks[run.blocks.length - 1] = block;
        }
      }
    }
    weekInBlock++;
  }
  for (final t in athlete.truths) {
    if (t.sessions > 0 && t.startCapacity > 0) {
      run.gain[t.info.id] = ln(t.capacity / t.startCapacity);
    }
  }
  run.painAggravations = athlete.painAggravations;
  run.sessions.addAll(sessions);
  return run;
}
