/// Déroulement d'une simulation : un athlète à vérité connue suit pendant
/// des semaines le programme de `kalis_plan`, piloté par une politique.
library;

import 'package:kalis_core/kalis_core.dart';

import '../apply.dart';
import '../book.dart';
import '../coach.dart' show blockCoached;
import '../endurance.dart';
import '../engine.dart';
import '../filter.dart';
import '../numeric.dart' show exp, ln;
import '../review.dart';
import 'endurance_truth.dart';
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
  SimProgram(
    this.catalog,
    this.plan,
    this.profile, {
    this.seed = 0,
    this.transform,
  });

  /// Programme réduit au bloc [block] déjà construit (programme importé) :
  /// la simulation ne doit pas dépasser sa durée.
  SimProgram.fixed(this.catalog, this.plan, this.profile, ProgramBlock block)
    : seed = block.pass1.seed,
      transform = null {
    _blocks.add(block);
  }

  /// Transformation appliquée à chaque bloc construit (programmes de
  /// test : techniques injectées), ou `null`.
  final ProgramBlock Function(ProgramBlock block)? transform;

  /// Le bloc [block] tel que la simulation le suit.
  ProgramBlock shaped(ProgramBlock block) => transform?.call(block) ?? block;

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
        _blocks.add(shaped(ProgramBlock(pass1: pass1, pass2: pass2)));
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
        shaped(
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
        ),
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
    required this.targetLow,
    required this.targetHigh,
    required this.reachable,
    required this.steps,
    this.simDay = 0,
    this.slotId,
    this.role,
    this.technique,
    this.schemeRise,
    this.schemeSteps = 0,
    this.attempt = false,
    this.eventDay = false,
    this.truePct,
    this.totalKg,
    this.dayMax,
    this.quality,
    this.test = false,
    this.openTarget = false,
  });

  /// Jour de la simulation (0 = premier).
  final int simDay;

  /// Emplacement de la semaine type.
  final String? slotId;

  /// Rôle de la ligne (programmes au contrat 0.4.0), ou `null`.
  final SetRole? role;

  /// Technique servie, ou `null`.
  final SetTechniqueKind? technique;

  /// Hausse relative de la charge totale par rapport à la séance
  /// précédente du même emplacement, à répétitions demandées égales
  /// (première ligne seulement, hors test), sinon `null`.
  final double? schemeRise;

  /// Crans de la grille de cette hausse.
  final int schemeSteps;

  /// Tentative (test de 1RM ou simulation de tentatives).
  final bool attempt;

  /// Séance du jour d'une échéance du profil.
  final bool eventDay;

  /// Part du 1RM vrai (charge totale) de la ligne, exercice chargé.
  final double? truePct;

  /// Charge totale (lest et part du poids de corps), exercice chargé.
  final double? totalKg;

  /// Maximum vrai du jour, frais (1RM de charge totale, répétitions ou
  /// secondes).
  final double? dayMax;

  /// Propreté notée (1 à 5), ou `null`.
  final int? quality;

  /// Ligne de test ou tentative.
  final bool test;

  /// Cible « 5 répétitions en réserve et plus » : seul un effort plus dur
  /// que prévu est un écart.
  final bool openTarget;

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

  /// Cible donnée par une plage (au ressenti) et non par un nombre.
  final bool open;

  /// Bas de la cible affichée (répétitions ou secondes).
  final int targetLow;

  /// Haut de la cible affichée.
  final int targetHigh;

  /// Vrai si la cible de RIR est atteignable dans la plage du bloc avec le
  /// matériel de l'athlète (voir `SimAthlete.reachable`).
  final bool reachable;

  /// Hausse relative de la charge totale par rapport à la plus forte
  /// charge de la séance précédente de l'exercice (première série
  /// seulement), sinon `null`.
  final double? rise;

  /// Crans de la grille entre cette plus forte charge et la charge de la
  /// série (première série seulement, 0 sans hausse).
  final int steps;
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
    required this.main,
  });

  /// Mouvement principal.
  final bool main;

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

/// Changement du profil en cours de saison (scénarios du croisement,
/// `kalis_bench`) : échéance avancée, échéance ajoutée… Il prend effet au
/// début de la semaine [week] de la simulation ; avec [replan], le bloc en
/// cours s'arrête à la fin de la semaine précédente et le bloc suivant est
/// construit tout de suite par `nextBlock`, à partir du profil changé et
/// du dernier résumé d'adaptation (comme l'application le fait quand
/// l'athlète change une échéance). Le bloc n'est pas reconstruit (le
/// changement vaut alors au bloc suivant) sans moteur d'évolution, avant le
/// premier résumé d'adaptation ou en première semaine d'un bloc ; le
/// changement est noté dans `SimRun.changes` dans tous les cas.
final class ProfileChange {
  /// Changement.
  const ProfileChange({
    required this.week,
    required this.apply,
    this.replan = true,
    this.label = '',
  });

  /// Semaine de la simulation (0 = première) où le changement prend effet.
  final int week;

  /// Profil changé, à partir du profil courant.
  final AthleteProfile Function(AthleteProfile profile) apply;

  /// Vrai pour reconstruire le bloc dès cette semaine.
  final bool replan;

  /// Libellé lisible du changement.
  final String label;
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

  /// Propositions candidates retenues par la revue (boucle complète), par
  /// « nature:cause ».
  final Map<String, int> withheld = <String, int>{};

  /// Semaine où chaque niveau de déblocage est atteint (boucle complète).
  final Map<UnlockLevel, int> unlockWeek = <UnlockLevel, int>{};

  /// Gain de capacité vraie par semaine (`ln`), par exercice suivi au
  /// moins trois semaines.
  final Map<String, double> gain = <String, double>{};

  /// Séances prévues.
  int sessionsPlanned = 0;

  /// Séances faites.
  int sessionsDone = 0;

  /// Séances ajustées par le bilan santé, la douleur, le lieu ou le temps.
  int sessionsAdjusted = 0;

  /// Hausses de charge sur la zone douloureuse après signalement.
  int painAggravations = 0;

  /// Poussées de douleur d'une zone réactive après une hausse trop rapide
  /// de sa charge (modèles B et C ; CA2, partie 0).
  int painFlares = 0;

  /// Blessures de surcharge de course ou de conditionnement (vérité
  /// d'endurance ; CA2, partie 1).
  int enduranceOveruse = 0;

  /// Plus forte course faite rapportée à la plus longue des 30 jours
  /// précédents (au moins trois courses dans la fenêtre), ou 0.
  double worstRunSpike = 0;

  /// Secondes de course faites par semaine de simulation.
  final Map<int, double> runSecondsByWeek = <int, double>{};

  /// Séances du journal.
  final List<SessionRecord> sessions = <SessionRecord>[];

  /// Blocs suivis.
  final List<ProgramBlock> blocks = <ProgramBlock>[];

  /// Séances servies, dans l'ordre (prescription du jour, bilan, journal).
  final List<SimSession> served = <SimSession>[];

  /// Revues de fin de semaine (boucle complète).
  final List<(int, AdaptReview)> reviews = <(int, AdaptReview)>[];

  /// Semaine de chaque bloc de [blocks] (0 = première).
  final List<int> blockWeeks = <int>[];

  /// Changements du profil appliqués : (semaine, libellé).
  final List<(int, String)> changes = <(int, String)>[];

  /// Profil en fin de simulation (repères et étapes de figure reportés).
  AthleteProfile? finalProfile;
}

/// Une séance servie pendant une simulation.
final class SimSession {
  /// Séance.
  const SimSession({
    required this.week,
    required this.weekInBlock,
    required this.simDay,
    required this.weekKind,
    required this.plan,
    required this.record,
    required this.advices,
  });

  /// Semaine de la simulation.
  final int week;

  /// Semaine dans le bloc.
  final int weekInBlock;

  /// Jour de la simulation.
  final int simDay;

  /// Nature de la semaine.
  final WeekKind weekKind;

  /// Séance prescrite le jour même.
  final SessionPlan plan;

  /// Séance faite.
  final SessionRecord record;

  /// Conseils d'entre-séries qui ont changé la suite (arrêt, allègement).
  final List<IntraSessionAdvice> advices;
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
  TruthKind truthKind = TruthKind.a,
  List<ProfileChange> changes = const <ProfileChange>[],
}) {
  final book = ExerciseBook(catalog, profile);
  final athlete = SimAthlete(spec, profile, book, seed, kind: truthKind);
  // Vérité d'endurance et de conditionnement (CA2, partie 1).
  final endurance = EnduranceTruth(truthKind, spec.level, seed);
  final aware = policy is CoachAwarePolicy ? policy : null;
  final rich = aware?.rich ?? false;
  final schemeLoad = <String, double>{};
  final eventDays = <int>{
    for (final e in profile.events ?? const <SeasonEvent>[]) e.date.dayNumber,
  };
  var current = profile;
  final run = SimRun(spec.key, policy.name, seed);
  final sessions = <SessionRecord>[];
  final exerciseSessions = <String, int>{};
  final bandNotch = <String, int>{};
  final lastMaxLoad = <String, double>{};
  final decisions = <ProposalDecision>[];
  Map<String, Object?>? reviewState;
  AdaptationSummary? summary;
  final startDay = simStartDate.dayNumber;

  var blockIndex = 0;
  var block = program.block(0);
  var weekInBlock = 0;
  var blockStart = simStartDate;
  run.blocks.add(block);
  run.blockWeeks.add(0);

  for (var g = 0; g < weeks; g++) {
    var replan = false;
    for (final c in changes) {
      if (c.week != g) {
        continue;
      }
      current = c.apply(current);
      eventDays
        ..clear()
        ..addAll(<int>[
          for (final e in current.events ?? const <SeasonEvent>[])
            e.date.dayNumber,
        ]);
      run.changes.add((g, c.label));
      if (c.replan &&
          loop != null &&
          summary != null &&
          weekInBlock > 0 &&
          weekInBlock < block.pass1.weeks) {
        replan = true;
      }
    }
    if (weekInBlock >= block.pass1.weeks || replan) {
      blockStart = blockStart.addDays(7 * weekInBlock);
      blockIndex++;
      weekInBlock = 0;
      final last = summary;
      if (loop == null || last == null) {
        block = program.block(blockIndex);
      } else {
        block = program.shaped(
          program.plan
              .nextBlock(
                catalog,
                NextBlockRequest(
                  profile: current,
                  seed: block.pass1.seed,
                  startDate: blockStart,
                  previous: block,
                  adaptation: last,
                  locks: const <PlanLock>[],
                ),
              )
              .block,
        );
      }
      run.blocks.add(block);
      run.blockWeeks.add(g);
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
        profile: current,
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
        final eInfo = truth == null ? book.find(item.exerciseId) : null;
        final eKind = eInfo == null ? null : enduranceKindOf(eInfo);
        if (truth == null &&
            (eKind == EnduranceKind.run ||
                eKind == EnduranceKind.conditioning) &&
            item.kind != SetKind.warmup &&
            item.sets > 0) {
          // Course et conditionnement (CA2, partie 1) : faits d'après la
          // vérité d'endurance de l'athlète, que le moteur ne connaît pas.
          final rates =
              SimRandom.of(seed, 'rate|$simDay|${item.exerciseId}').next() >=
              spec.lazy;
          final (EnduranceDone, BodyZone?) outcome;
          if (eKind == EnduranceKind.run) {
            outcome = endurance.run(
              item,
              item.sets,
              simDay,
              0,
              ill: athlete.ill,
              rates: rates,
            );
          } else {
            var written = item;
            for (final it in prescription.items) {
              if (it.slotId == item.slotId) {
                written = it;
              }
            }
            final wr = written.repsHigh ?? written.secondsHigh;
            final sr = item.repsHigh ?? item.secondsHigh;
            final ws = written.sets <= 0 ? 1 : written.sets;
            final share = wr == null || sr == null || wr <= 0
                ? 1.0
                : (sr / wr) * (item.sets / ws);
            outcome = endurance.wodPiece(
              item,
              item.sets,
              simDay,
              0,
              ill: athlete.ill,
              rates: rates,
              hardDaysBefore: endurance.hardStreakBefore(simDay),
              writtenShare: share > 1 ? 1.0 : share,
            );
          }
          final (made, injured) = outcome;
          if (injured != null) {
            athlete.overuse(injured, 4, 14);
          }
          for (var i = 0; i < made.sets; i++) {
            done.add(
              SetRecord(
                exerciseId: item.exerciseId,
                exerciseOrder: order,
                setIndex: i,
                kind: item.kind ?? SetKind.work,
                reps: made.reps,
                seconds: made.seconds,
                distanceMeters: made.distanceMeters,
                flames: made.flames,
                success: made.success,
                excluded: false,
                slotId: item.slotId,
              ),
            );
          }
          order++;
          continue;
        }
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
        // Exercice assisté à l'élastique (programmes au contrat 0.4.0) :
        // l'athlète note l'assistance (charge négative) et change de cran
        // quand le moteur le lui dit ; un cran de moins retire une part de
        // la capacité, que le moteur ne connaît pas.
        double? assistKg;
        if (rich &&
            blockCoached(block) &&
            truth.mode == CapacityMode.reps &&
            truth.info.exercise.assisted) {
          var notch = bandNotch[item.exerciseId] ?? 3;
          var change = 0;
          for (final r in item.reasons) {
            if (r.code == ReasonCodes.adaptFlamesBelowTarget) {
              change = -1;
            } else if (r.code == ReasonCodes.adaptFlamesAboveTarget) {
              change = 1;
            }
          }
          if ((change < 0 && notch > 0) || (change > 0 && notch < 6)) {
            final step =
                0.75 *
                exp(
                  0.12 *
                      SimRandom.of(
                        seed,
                        'band|${item.exerciseId}|${change < 0 ? notch : notch + 1}',
                      ).gauss(),
                );
            final factor = change < 0 ? step : 1 / step;
            truth.capacity *= factor;
            truth.startCapacity *= factor;
            truth.firstCapacity *= factor;
            notch += change;
          }
          bandNotch[item.exerciseId] = notch;
          assistKg = -10.0 * notch;
        }
        var basis = item;
        for (final it in prescription.items) {
          if (it.slotId == item.slotId && it.exerciseId == item.exerciseId) {
            basis = it;
          }
        }
        final basisLow = hold ? basis.secondsLow : basis.repsLow;
        final basisHigh = hold ? basis.secondsHigh : basis.repsHigh;
        final count = exerciseSessions[item.exerciseId] ?? 0;
        final role = context.roleOf(item.slotId);
        final rest = item.restSeconds ?? 90;
        final technique = rich ? item.technique : null;
        final isTest = item.kind == SetKind.test || basis.kind == SetKind.test;
        final testKind = isTest ? (item.test ?? basis.test)?.kind : null;
        final isAttempt =
            testKind == TestKind.oneRm ||
            testKind == TestKind.attemptSimulation;
        var performed = 0;
        double? sessionMax;
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
          final key = '$simDay|${item.slotId}|$i';
          final lineRole = rich ? target.role : null;
          final applies =
              technique != null &&
              (technique.lastSetOnly != true || i == item.sets - 1);
          final served = applies ? technique.kind : null;
          final dayMax = truth.capacity * exp(truth.day);
          var plannedFailure = flamesTarget >= Flames.failure;
          List<SetPart>? parts;
          int? elapsed;
          SetOutcome outcome;
          if (lineRole == SetRole.attempt) {
            // Tentative : une répétition, réussie ou manquée.
            outcome = athlete.perform(
              truth,
              loadKg: load,
              low: 1,
              high: 1,
              flamesTarget: flamesTarget,
              restSeconds: rest,
              noiseKey: key,
            );
            plannedFailure = true;
          } else if (lineRole == SetRole.test &&
              (!loaded || high > low) &&
              flamesTarget >= 8) {
            // Test au maximum : la série va jusqu'à la réserve du test.
            outcome = athlete.perform(
              truth,
              loadKg: load,
              low: low,
              high: high + (hold ? 600 : 200),
              flamesTarget: flamesTarget,
              restSeconds: rest,
              noiseKey: key,
            );
            plannedFailure = true;
          } else if (served == SetTechniqueKind.cluster && !hold) {
            final mini = technique!.miniSets ?? 1;
            final each = technique.miniSetReps ?? high;
            final intra = technique.intraRestSeconds ?? 30;
            parts = <SetPart>[];
            var total = 0;
            SetOutcome? last;
            for (var k = 0; k < mini; k++) {
              final o = athlete.perform(
                truth,
                loadKg: load,
                low: each,
                high: each,
                flamesTarget: flamesTarget,
                restSeconds: k < mini - 1 ? intra : rest,
                noiseKey: '$key|$k',
              );
              last = o;
              if (o.amount >= 1) {
                parts.add(
                  SetPart(
                    reps: o.amount,
                    restBeforeSeconds: k == 0 ? null : intra,
                  ),
                );
                total += o.amount;
              }
              if (o.failed || o.amount < each) {
                break;
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: last?.flames,
              trueRir: last?.trueRir ?? 0,
              failed: last?.failed ?? false,
            );
            low = mini * each;
            high = mini * each;
          } else if ((served == SetTechniqueKind.restPause ||
                  served == SetTechniqueKind.myoReps) &&
              !hold) {
            final myo = served == SetTechniqueKind.myoReps;
            final intra = technique!.intraRestSeconds ?? (myo ? 15 : 20);
            final cap = technique.miniSets ?? (myo ? 5 : 2);
            final each = technique.miniSetReps ?? 3;
            final goal = technique.totalRepsTarget;
            final first = athlete.perform(
              truth,
              loadKg: load,
              low: low,
              high: high,
              flamesTarget: flamesTarget,
              restSeconds: intra,
              noiseKey: key,
            );
            parts = <SetPart>[
              if (first.amount >= 1) SetPart(reps: first.amount),
            ];
            var total = first.amount;
            if (!first.failed) {
              for (var k = 1; k <= cap; k++) {
                if (goal != null && total >= goal) {
                  break;
                }
                final o = athlete.perform(
                  truth,
                  loadKg: load,
                  low: myo ? each : 1,
                  high: myo ? each : high,
                  flamesTarget: 9,
                  restSeconds: k < cap ? intra : rest,
                  noiseKey: '$key|$k',
                );
                if (o.amount < 1) {
                  break;
                }
                parts.add(SetPart(reps: o.amount, restBeforeSeconds: intra));
                total += o.amount;
                if (o.failed || (myo && o.amount < each)) {
                  break;
                }
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: first.flames,
              trueRir: first.trueRir,
              failed: first.failed,
            );
            if (parts.isEmpty) {
              parts = null;
            }
          } else if (served == SetTechniqueKind.dropSet &&
              loaded &&
              load != null) {
            final drops = technique!.drops ?? 1;
            final pct = technique.dropPct ?? 0.2;
            final first = athlete.perform(
              truth,
              loadKg: load,
              low: low,
              high: high,
              flamesTarget: flamesTarget,
              restSeconds: 10,
              noiseKey: key,
            );
            parts = <SetPart>[
              if (first.amount >= 1)
                SetPart(reps: first.amount, externalLoadKg: load),
            ];
            var total = first.amount;
            final bw = truth.info.fraction * athlete.bodyWeightKg;
            var kg = load;
            if (!first.failed) {
              for (var k = 1; k <= drops; k++) {
                var next = truth.info.grid.floor((kg + bw) * (1 - pct) - bw);
                if (next < truth.info.grid.minimum) {
                  next = truth.info.grid.minimum;
                }
                if (next >= kg) {
                  break;
                }
                kg = next;
                final o = athlete.perform(
                  truth,
                  loadKg: kg,
                  low: 1,
                  high: high + 10,
                  flamesTarget: 9,
                  restSeconds: k < drops ? 10 : rest,
                  noiseKey: '$key|$k',
                );
                if (o.amount < 1) {
                  break;
                }
                parts.add(
                  SetPart(
                    reps: o.amount,
                    externalLoadKg: kg,
                    restBeforeSeconds: 10,
                  ),
                );
                total += o.amount;
              }
            }
            outcome = SetOutcome(
              amount: total,
              flames: first.flames,
              trueRir: first.trueRir,
              failed: first.failed,
            );
            if (parts.isEmpty) {
              parts = null;
            }
          } else if (served == SetTechniqueKind.accentuatedEccentric) {
            outcome = athlete.performEccentric(
              truth,
              loadKg: load,
              low: low,
              high: high,
              flamesTarget: flamesTarget,
              restSeconds: rest,
              noiseKey: key,
            );
          } else if ((served == SetTechniqueKind.density ||
                  served == SetTechniqueKind.forTime) &&
              !hold) {
            // Bloc au temps : passages d'un tiers du maximum du moment,
            // vingt secondes de repos, jusqu'au total ou à la durée.
            final goal = technique!.totalRepsTarget ?? high;
            final limit = technique.durationSeconds;
            parts = <SetPart>[];
            var total = 0;
            var seconds = 0;
            SetOutcome? last;
            for (var k = 0; k < 120 && total < goal; k++) {
              var chunk = (athlete.capacityNow(truth, load) / 3).round();
              if (chunk < 1) {
                chunk = 1;
              }
              if (chunk > goal - total) {
                chunk = goal - total;
              }
              final o = athlete.perform(
                truth,
                loadKg: load,
                low: chunk,
                high: chunk,
                flamesTarget: 6,
                restSeconds: 20,
                noiseKey: '$key|$k',
              );
              last = o;
              if (o.amount < 1) {
                break;
              }
              parts.add(
                SetPart(reps: o.amount, restBeforeSeconds: k == 0 ? null : 20),
              );
              total += o.amount;
              seconds += o.amount * 3 + 20;
              if (limit != null && seconds >= limit) {
                break;
              }
            }
            elapsed = seconds > 20 ? seconds - 20 : seconds;
            outcome = SetOutcome(
              amount: total,
              flames: last?.flames,
              trueRir: last?.trueRir ?? 0,
              failed: false,
            );
            if (parts.isEmpty) {
              parts = null;
            }
            low = total < low ? total : low;
          } else {
            outcome = athlete.perform(
              truth,
              loadKg: load,
              low: low,
              high:
                  served == SetTechniqueKind.amrap &&
                      technique!.durationSeconds == null
                  ? high + 200
                  : high,
              flamesTarget: flamesTarget,
              restSeconds: rest,
              noiseKey: key,
            );
          }
          final quality =
              rich &&
                  (served == SetTechniqueKind.isometricHold ||
                      served == SetTechniqueKind.skillPractice)
              ? athlete.qualityOf(outcome)
              : null;
          done.add(
            SetRecord(
              exerciseId: item.exerciseId,
              exerciseOrder: order,
              setIndex: i,
              kind: item.kind ?? SetKind.work,
              externalLoadKg: load ?? assistKg,
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
                role: lineRole,
              ),
              technique: served == SetTechniqueKind.standard ? null : served,
              role: lineRole,
              parts: parts,
              elapsedSeconds: elapsed,
              quality: quality,
              attemptIndex: lineRole == SetRole.attempt ? i : null,
            ),
          );
          double? rise;
          var steps = 0;
          if (i == 0 && load != null) {
            final before = lastMaxLoad[item.exerciseId];
            if (before != null) {
              final bw = truth.info.fraction * athlete.bodyWeightKg;
              rise = (load + bw) / (before + bw) - 1;
              var kg = before;
              while (kg < load - 1e-9 && steps < 50) {
                kg = truth.info.grid.next(kg, up: true);
                steps++;
              }
            }
          }
          double? schemeRise;
          var schemeSteps = 0;
          if (i == 0 && load != null && !isTest) {
            final schemeKey = '${item.slotId}|${item.exerciseId}|$high';
            final before = schemeLoad[schemeKey];
            if (before != null) {
              final bw = truth.info.fraction * athlete.bodyWeightKg;
              schemeRise = (load + bw) / (before + bw) - 1;
              var kg = before;
              while (kg < load - 1e-9 && schemeSteps < 50) {
                kg = truth.info.grid.next(kg, up: true);
                schemeSteps++;
              }
            }
            schemeLoad[schemeKey] = load;
          }
          if (load != null && (sessionMax == null || load > sessionMax)) {
            sessionMax = load;
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
              plannedFailure: plannedFailure,
              main: role == SlotRole.main,
              open: high > low,
              rise: rise,
              targetLow: low,
              targetHigh: high,
              steps: steps,
              reachable: athlete.reachable(
                truth,
                basisLow ?? basisHigh ?? low,
                basisHigh ?? basisLow ?? high,
                Flames.toRir(flamesTarget),
              ),
              simDay: simDay,
              slotId: item.slotId,
              role: lineRole,
              technique: served,
              schemeRise: schemeRise,
              schemeSteps: schemeSteps,
              attempt: isAttempt,
              eventDay: eventDays.contains(dayNumber),
              truePct: loaded && load != null
                  ? truth.info.totalLoad(load, athlete.bodyWeightKg) /
                        truth.capacity
                  : null,
              totalKg: loaded && load != null
                  ? truth.info.totalLoad(load, athlete.bodyWeightKg)
                  : null,
              dayMax: dayMax,
              quality: quality,
              test: isTest,
              openTarget: Flames.isOpenEnded(flamesTarget),
            ),
          );
          performed++;
        }
        athlete.endExercise(truth);
        if (sessionMax != null) {
          lastMaxLoad[item.exerciseId] = sessionMax;
        }
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
        eventId: rich ? session.eventId : null,
      );
      endurance.endDay(simDay);
      policy.finish(context, record);
      sessions.add(record);
      run.served.add(
        SimSession(
          week: g,
          weekInBlock: weekInBlock,
          simDay: simDay,
          weekKind: week.kind,
          plan: session,
          record: record,
          advices: aware?.takeAdvices() ?? const <IntraSessionAdvice>[],
        ),
      );
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
            main: context.roleOf(item.slotId) == SlotRole.main,
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
          profile: current,
          block: block,
          log: TrainingLog(sessions: List<SessionRecord>.of(sessions)),
          today: today,
          state: reviewState,
          decisions: List<ProposalDecision>.of(decisions),
        ),
      );
      reviewState = review.state;
      summary = review.summary;
      run.reviews.add((g, review));
      // Résultats de test et étapes de figure reportés dans le profil,
      // comme l'application le fait (contrat de `kalis_core`, § 12).
      final tests = review.testResults;
      if (tests != null && tests.isNotEmpty) {
        current = current.copyWith(
          benchmarks: <Benchmark>[
            for (final b in current.benchmarks ?? const <Benchmark>[])
              if (!tests.any(
                (t) => t.exerciseId == b.exerciseId && t.kind == b.kind,
              ))
                b,
            ...tests,
          ],
        );
      }
      final skills = review.skillStates;
      if (skills != null && skills.isNotEmpty) {
        current = current.copyWith(skills: skills);
      }
      for (final level in UnlockLevel.values) {
        if (level.index <= review.summary.unlockLevel.index) {
          run.unlockWeek.putIfAbsent(level, () => g);
        }
      }
      for (final entry in review.log) {
        if (entry.event == 'proposal_withheld') {
          final key = '${entry.data['kind']}:${entry.data['withheld']}';
          run.withheld[key] = (run.withheld[key] ?? 0) + 1;
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
    final first = t.firstDay;
    final last = t.lastDay;
    if (first == null || last == null || last - first < 21) {
      continue;
    }
    // Gain par semaine entre la première et la dernière séance de
    // l'exercice (un exercice quitté en cours de route ne compte pas son
    // désentraînement).
    run.gain[t.info.id] =
        ln(t.lastCapacity / t.firstCapacity) / ((last - first) / 7);
  }
  run.painAggravations = athlete.painAggravations;
  run.painFlares = athlete.painFlares;
  run.enduranceOveruse = endurance.overuse;
  run.worstRunSpike = endurance.worstSpike;
  run.runSecondsByWeek.addAll(endurance.secondsByWeek());
  run.finalProfile = current;
  run.sessions.addAll(sessions);
  return run;
}
