/// Saison : échéance visée, découpage en blocs de 4 à 6 semaines calés pour
/// finir sur elle, nature et dosage de chaque semaine (R3-P2, P4, P9, P12 à
/// P14, P20, P21 du référentiel de `kalis_bench`).
library;

import 'package:kalis_core/kalis_core.dart';

import '../assemble.dart';
import '../version.dart';
import 'athlete.dart';

/// Échéance que prépare le programme : compétition, test daté ou objectif
/// daté.
final class CoachTarget {
  /// Échéance.
  const CoachTarget({
    required this.date,
    required this.event,
    required this.goals,
    required this.peak,
  });

  /// Jour de l'échéance.
  final CivilDate date;

  /// Échéance du profil (`AthleteProfile.events`), ou `null` pour un
  /// objectif daté.
  final SeasonEvent? event;

  /// Objectifs datés de ce jour-là (quand il n'y a pas d'échéance).
  final List<Goal> goals;

  /// Vrai si l'échéance appelle un pic de forme (échéance principale).
  final bool peak;

  /// Identifiant de l'échéance, ou `null`.
  String? get eventId => event?.id;
}

/// Échéance visée par [profile] à partir du [start] : la première
/// échéance principale à venir, sinon la première échéance, sinon le
/// premier objectif daté.
CoachTarget? targetOf(AthleteProfile profile, CivilDate start) {
  SeasonEvent? best;
  for (final e in profile.events ?? const <SeasonEvent>[]) {
    if (start.daysUntil(e.date) < 0) {
      continue;
    }
    final current = best;
    if (current == null) {
      best = e;
      continue;
    }
    final better =
        (e.priority == EventPriority.main &&
            current.priority != EventPriority.main) ||
        ((e.priority == EventPriority.main) ==
                (current.priority == EventPriority.main) &&
            e.date.compareTo(current.date) < 0);
    if (better) {
      best = e;
    }
  }
  if (best != null) {
    return CoachTarget(
      date: best.date,
      event: best,
      goals: const <Goal>[],
      peak: best.priority == EventPriority.main,
    );
  }
  CivilDate? first;
  for (final g in profile.goals) {
    final date = g.targetDate;
    if (g.kind != GoalKind.performance ||
        date == null ||
        start.daysUntil(date) < 0) {
      continue;
    }
    if (first == null || date.compareTo(first) < 0) {
      first = date;
    }
  }
  if (first == null) {
    return null;
  }
  return CoachTarget(
    date: first,
    event: null,
    goals: <Goal>[
      for (final g in profile.goals)
        if (g.kind == GoalKind.performance && g.targetDate == first) g,
    ],
    peak: false,
  );
}

/// Modèle de saison.
enum SeasonModel {
  /// Débutant : progression linéaire, test en fin de bloc (R3-P2).
  linear,

  /// Blocs avec ondulation, allègement et test en fin de bloc (R3-P3, P9).
  general,

  /// Pic de force : accumulation, intensification, réalisation, affûtage
  /// (R3-P4, P12 à P14).
  strengthPeak,

  /// Pic d'endurance de force : base, capacité, spécifique, affûtage
  /// (R3-P20, P21).
  repsPeak,
}

/// Semaine d'un bloc.
final class WeekSpec {
  /// Semaine.
  const WeekSpec({
    required this.kind,
    required this.intent,
    required this.phase,
    required this.volume,
    required this.stage,
    this.eventWeek = false,
    this.testWeek = false,
    this.weeksToEvent,
  });

  /// Nature (vocabulaire de 0.1).
  final WeekKind kind;

  /// Intention.
  final WeekIntent intent;

  /// Phase de saison.
  final SeasonPhaseKind phase;

  /// Volume visé, rapporté à la semaine la plus chargée (1 = pointe).
  final double volume;

  /// Rang de la semaine parmi les semaines de charge de sa phase dans le
  /// bloc (0 = première) : il règle la montée d'intensité.
  final int stage;

  /// Vrai pour la semaine de l'échéance.
  final bool eventWeek;

  /// Vrai pour une semaine qui porte des tests.
  final bool testWeek;

  /// Semaines jusqu'à l'échéance, celle-ci comprise (1 = semaine de
  /// l'échéance), ou `null`.
  final int? weeksToEvent;

  /// Vrai pour une semaine allégée par nature.
  bool get light =>
      kind == WeekKind.intro ||
      kind == WeekKind.deload ||
      kind == WeekKind.test;
}

/// Forme d'un bloc.
final class BlockShape {
  /// Forme.
  const BlockShape({
    required this.model,
    required this.weeks,
    required this.phase,
    required this.target,
    required this.weeksToEvent,
    required this.finalBlock,
  });

  /// Modèle de saison.
  final SeasonModel model;

  /// Semaines.
  final List<WeekSpec> weeks;

  /// Phase principale du bloc.
  final SeasonPhaseKind phase;

  /// Échéance visée, ou `null`.
  final CoachTarget? target;

  /// Semaines entre le début du bloc et l'échéance, celle-ci comprise, ou
  /// `null`.
  final int? weeksToEvent;

  /// Vrai si le bloc contient la semaine de l'échéance.
  final bool finalBlock;
}

/// Vrai si l'échéance [target] est une épreuve de force à charge maximale.
bool isStrengthTarget(Athlete a, CoachTarget target) {
  final event = target.event;
  if (event != null) {
    if (event.kind == EventKind.strengthCompetition) {
      return true;
    }
    if (event.kind == EventKind.repsCompetition ||
        event.kind == EventKind.race ||
        event.kind == EventKind.freestyleCompetition) {
      return false;
    }
    return (event.lifts ?? const <CompetitionLift>[]).isNotEmpty;
  }
  return target.goals.isNotEmpty &&
      target.goals.every((g) => g.metric == GoalMetric.oneRmKg);
}

/// Vrai si l'échéance [target] est une épreuve de répétitions.
bool isRepsTarget(CoachTarget target) {
  final event = target.event;
  if (event == null) {
    return false;
  }
  return event.kind == EventKind.repsCompetition ||
      (event.kind != EventKind.strengthCompetition &&
          event.kind != EventKind.race &&
          event.mode != null);
}

/// Modèle de saison de l'athlète [a] pour l'échéance [target].
SeasonModel seasonModelOf(Athlete a, CoachTarget? target) {
  if (a.level == 0) {
    return SeasonModel.linear;
  }
  if (target == null) {
    return SeasonModel.general;
  }
  if (isStrengthTarget(a, target) && (target.peak || a.level >= 2)) {
    return SeasonModel.strengthPeak;
  }
  if (isRepsTarget(target) && target.peak) {
    return SeasonModel.repsPeak;
  }
  return SeasonModel.general;
}

/// Durées de bloc préférées par niveau (R3-P9 : allègement réactif chez
/// le débutant, toutes les 5 à 6 semaines chez l'intermédiaire, toutes les
/// 4 à 5 ensuite).
List<int> blockPreferences(int level) => level <= 0
    ? const <int>[6, 5, 4]
    : (level == 1 ? const <int>[5, 6, 4] : const <int>[4, 5, 6]);

/// Durée du bloc qui commence à [weeksToEvent] semaines de l'échéance :
/// la première durée préférée qui laisse un reste découpable en blocs de 4
/// à 6 semaines.
int blockLengthFor(int? weeksToEvent, List<int> preferences) {
  final w = weeksToEvent;
  if (w == null) {
    return preferences.first;
  }
  if (w <= 6) {
    return w < 4 ? 4 : w;
  }
  for (final p in preferences) {
    final rest = w - p;
    if (rest == 0 || (rest >= 4 && rest != 7)) {
      return p;
    }
  }
  return preferences.first;
}

/// Semaines entre le [start] et le jour [date], celui-ci compris (1 : le
/// jour tombe dans la première semaine).
int weeksUntil(CivilDate start, CivilDate date) =>
    start.daysUntil(date) ~/ 7 + 1;

/// Forme du bloc de rang [blockIndex] qui commence le [start].
BlockShape shapeBlock(
  Athlete a,
  CivilDate start,
  int blockIndex, {
  int? blockWeeks,
}) {
  final target = targetOf(a.profile, start);
  final model = seasonModelOf(a, target);
  final toEvent = target == null ? null : weeksUntil(start, target.date);
  // Sans échéance, l'intermédiaire travaille par blocs de six semaines
  // (R3-P9 : allègement toutes les cinq à six semaines) : deux blocs font
  // un cycle de douze semaines qui finit sur un allègement et des tests.
  final length =
      blockWeeks ??
      (toEvent == null && a.level == 1
          ? 6
          : blockLengthFor(toEvent, blockPreferences(a.level)));
  final finalBlock = toEvent != null && toEvent <= length;
  final first = blockIndex == 0;
  final reintroduction = first && a.gapWeeks >= 3;
  final weeks = <WeekSpec>[];

  int? left(int i) => toEvent == null ? null : toEvent - i;
  bool isEvent(int i) => toEvent != null && toEvent - i == 1;

  void add(
    WeekKind kind,
    WeekIntent intent,
    SeasonPhaseKind phase,
    double volume,
    int stage, {
    bool test = false,
  }) {
    final i = weeks.length;
    weeks.add(
      WeekSpec(
        kind: kind,
        intent: intent,
        phase: phase,
        volume: volume,
        stage: stage,
        eventWeek: isEvent(i),
        testWeek: test || isEvent(i),
        weeksToEvent: left(i),
      ),
    );
  }

  SeasonPhaseKind phase;
  switch (model) {
    case SeasonModel.linear:
      phase = reintroduction
          ? SeasonPhaseKind.reintroduction
          : SeasonPhaseKind.accumulation;
      var stage = 0;
      // R3-P9, R3-P21 : avant un test daté, la dernière semaine de charge
      // devient une semaine allégée (volume −30 %, intensité gardée).
      final tapered = toEvent != null && toEvent >= 5 && toEvent <= length;
      for (var i = 0; i < length; i++) {
        if (i == 0 && first) {
          // R5-P22 : la marche vers la première semaine de charge reste sous
          // +20 %.
          add(WeekKind.intro, WeekIntent.intro, phase, 0.9, 0);
        } else if (tapered && left(i) == 2) {
          add(
            WeekKind.deload,
            WeekIntent.taper,
            SeasonPhaseKind.taper,
            0.7,
            stage,
          );
        } else if ((i == length - 1 && length >= 4) || isEvent(i)) {
          add(
            WeekKind.test,
            WeekIntent.test,
            SeasonPhaseKind.test,
            0.7,
            stage,
            test: true,
          );
        } else {
          add(
            WeekKind.build,
            WeekIntent.accumulation,
            phase,
            first ? 0.9 + 0.1 * (stage > 2 ? 1 : stage / 2) : 1.0,
            stage,
          );
          stage++;
        }
      }
    case SeasonModel.general:
      final after = toEvent == null ? null : toEvent - length;
      phase = reintroduction
          ? SeasonPhaseKind.reintroduction
          : (finalBlock
                ? SeasonPhaseKind.realization
                : (after != null && after <= 6
                      ? SeasonPhaseKind.intensification
                      : SeasonPhaseKind.accumulation));
      final intent = switch (phase) {
        SeasonPhaseKind.realization => WeekIntent.realization,
        SeasonPhaseKind.intensification => WeekIntent.intensification,
        _ => WeekIntent.accumulation,
      };
      // R3-P21, R4-G7 : avant un test daté, la dernière semaine de charge
      // devient une semaine d'affûtage (volume −35 %, intensité gardée).
      final tapered = toEvent != null && toEvent >= 5 && toEvent <= length;
      final loaded = length - 1 - (first ? 1 : 0) - (tapered ? 1 : 0);
      var stage = 0;
      for (var i = 0; i < length; i++) {
        if (i == 0 && first) {
          add(
            WeekKind.intro,
            WeekIntent.intro,
            phase,
            reintroduction ? 0.5 : 0.9,
            0,
          );
        } else if (tapered && left(i) == 2) {
          add(
            WeekKind.deload,
            WeekIntent.taper,
            SeasonPhaseKind.taper,
            0.65,
            stage,
          );
        } else if (isEvent(i)) {
          add(
            WeekKind.test,
            WeekIntent.test,
            SeasonPhaseKind.test,
            0.6,
            stage,
            test: true,
          );
        } else if (i == length - 1 && length >= 4) {
          add(
            WeekKind.deload,
            WeekIntent.deload,
            SeasonPhaseKind.deload,
            0.55,
            stage,
            test: true,
          );
        } else {
          final ramp = loaded <= 1 ? 1.0 : stage / (loaded - 1);
          // R5-P7, R5-P22 : en reprise, le volume repart de la moitié et
          // remonte de 15 % par semaine.
          var back = 0.5;
          for (var k = 0; k <= stage; k++) {
            back *= 1.15;
          }
          final volume = reintroduction
              ? (back > 0.95 ? 0.95 : back)
              : 0.9 + 0.1 * ramp;
          add(WeekKind.build, intent, phase, volume, stage);
          stage++;
        }
      }
    case SeasonModel.strengthPeak:
      if (finalBlock) {
        phase = SeasonPhaseKind.realization;
        final competition = target?.peak ?? false;
        final taperWeeks = competition && a.level >= 2 ? 2 : 1;
        // Semaines avant l'affûtage.
        final before = toEvent - taperWeeks;
        final plan = <SeasonPhaseKind>[];
        if (before >= 5) {
          for (var i = 0; i < before - 2; i++) {
            plan.add(SeasonPhaseKind.intensification);
          }
          plan
            ..add(SeasonPhaseKind.deload)
            ..add(SeasonPhaseKind.realization);
        } else if (before == 4) {
          plan
            ..add(SeasonPhaseKind.intensification)
            ..add(SeasonPhaseKind.intensification)
            ..add(SeasonPhaseKind.realization)
            ..add(SeasonPhaseKind.realization);
        } else if (before == 3) {
          plan
            ..add(SeasonPhaseKind.intensification)
            ..add(SeasonPhaseKind.realization)
            ..add(SeasonPhaseKind.realization);
        } else {
          for (var i = 0; i < before; i++) {
            plan.add(SeasonPhaseKind.realization);
          }
        }
        var intStage = 0;
        var realStage = 0;
        for (final p in plan) {
          switch (p) {
            case SeasonPhaseKind.intensification:
              add(
                WeekKind.build,
                WeekIntent.intensification,
                p,
                intStage == 0 && first ? 0.9 : 1.0,
                intStage,
              );
              intStage++;
            case SeasonPhaseKind.deload:
              add(WeekKind.deload, WeekIntent.deload, p, 0.55, intStage);
            default:
              add(
                WeekKind.build,
                WeekIntent.realization,
                SeasonPhaseKind.realization,
                realStage == 0 ? 0.85 : 0.8,
                realStage,
              );
              realStage++;
          }
        }
        if (taperWeeks == 2) {
          add(WeekKind.deload, WeekIntent.taper, SeasonPhaseKind.taper, 0.6, 0);
        }
        add(
          WeekKind.test,
          competition ? WeekIntent.competition : WeekIntent.test,
          competition ? SeasonPhaseKind.competition : SeasonPhaseKind.test,
          0.42,
          1,
          test: true,
        );
        // Semaines au-delà de l'échéance (bloc plus long qu'elle) :
        // transition (R3-P19).
        while (weeks.length < length) {
          add(
            WeekKind.deload,
            WeekIntent.transition,
            SeasonPhaseKind.transition,
            0.5,
            0,
          );
        }
      } else {
        final after = (toEvent ?? 99) - length;
        phase = after >= 5
            ? SeasonPhaseKind.accumulation
            : SeasonPhaseKind.intensification;
        final intent = phase == SeasonPhaseKind.accumulation
            ? WeekIntent.accumulation
            : WeekIntent.intensification;
        final loaded = length - 1;
        for (var i = 0; i < length; i++) {
          if (i == length - 1) {
            add(
              WeekKind.deload,
              WeekIntent.deload,
              SeasonPhaseKind.deload,
              0.55,
              loaded,
            );
          } else if (i == 0 && first) {
            add(WeekKind.intro, WeekIntent.intro, phase, 0.9, 0);
          } else {
            final ramp = loaded <= 1 ? 1.0 : i / (loaded - 1);
            add(
              WeekKind.build,
              intent,
              phase,
              phase == SeasonPhaseKind.accumulation ? 0.92 + 0.08 * ramp : 1.0,
              i,
            );
          }
        }
      }
    case SeasonModel.repsPeak:
      if (finalBlock) {
        phase = SeasonPhaseKind.realization;
        final taperWeeks = a.level >= 2 ? 2 : 1;
        final before = toEvent - taperWeeks;
        for (var i = 0; i < before; i++) {
          add(
            WeekKind.build,
            WeekIntent.realization,
            SeasonPhaseKind.realization,
            1.0,
            i,
          );
        }
        if (taperWeeks == 2) {
          add(
            WeekKind.deload,
            WeekIntent.taper,
            SeasonPhaseKind.taper,
            0.62,
            0,
          );
        }
        add(
          WeekKind.test,
          WeekIntent.competition,
          SeasonPhaseKind.competition,
          0.45,
          1,
          test: true,
        );
        while (weeks.length < length) {
          add(
            WeekKind.deload,
            WeekIntent.transition,
            SeasonPhaseKind.transition,
            0.5,
            0,
          );
        }
      } else {
        final after = (toEvent ?? 99) - length;
        phase = after >= 8
            ? SeasonPhaseKind.accumulation
            : SeasonPhaseKind.intensification;
        final intent = phase == SeasonPhaseKind.accumulation
            ? WeekIntent.accumulation
            : WeekIntent.intensification;
        final loaded = length - 1;
        for (var i = 0; i < length; i++) {
          if (i == length - 1) {
            add(
              WeekKind.deload,
              WeekIntent.deload,
              SeasonPhaseKind.deload,
              0.6,
              loaded,
              test: true,
            );
          } else if (i == 0 && first) {
            add(WeekKind.intro, WeekIntent.intro, phase, 0.9, 0);
          } else {
            final ramp = loaded <= 1 ? 1.0 : i / (loaded - 1);
            add(WeekKind.build, intent, phase, 0.92 + 0.08 * ramp, i);
          }
        }
      }
  }
  return BlockShape(
    model: model,
    weeks: weeks,
    phase: phase,
    target: target,
    weeksToEvent: toEvent,
    finalBlock: finalBlock,
  );
}

/// Plan de saison à partir du [start] : les phases des blocs enchaînés
/// jusqu'à l'échéance (deux blocs sans échéance).
SeasonPlan seasonPlanOf(Athlete a, CivilDate start, CivilDate createdOn) {
  final phases = <SeasonPhase>[];
  final target = targetOf(a.profile, start);
  var cursor = start;
  var blockIndex = 0;
  SeasonPhaseKind? runKind;
  CivilDate runStart = start;
  var runWeeks = 0;
  var runVolume = 0.0;
  String? runEvent;

  void flush() {
    final kind = runKind;
    if (kind == null || runWeeks == 0) {
      return;
    }
    phases.add(
      SeasonPhase(
        index: phases.length,
        kind: kind,
        startDate: runStart,
        weeks: runWeeks,
        eventId: runEvent,
        volumeFactor: (runVolume / runWeeks * 100).roundToDouble() / 100,
        reasons: <Reason>[
          if (runEvent != null && kind == SeasonPhaseKind.taper)
            reason(ReasonCodes.planPeakEvent, <String, Object?>{
              'eventId': runEvent,
            }),
        ],
      ),
    );
  }

  var guard = 0;
  while (guard < 30 && phases.length < 58) {
    guard++;
    // Le plan de saison ne dépend pas de la coupure en cours (elle ne
    // touche que le premier bloc) : le rang du bloc suffit.
    final shape = shapeBlock(
      Athlete.read(a.catalog, a.profile, cursor),
      cursor,
      blockIndex,
    );
    for (var i = 0; i < shape.weeks.length; i++) {
      final w = shape.weeks[i];
      final weekStart = cursor.addDays(7 * i);
      if (w.phase != runKind) {
        flush();
        runKind = w.phase;
        runStart = weekStart;
        runWeeks = 0;
        runVolume = 0;
        runEvent = shape.target?.eventId;
      }
      runWeeks++;
      runVolume += w.volume;
    }
    cursor = cursor.addDays(7 * shape.weeks.length);
    blockIndex++;
    if (shape.finalBlock || (shape.target == null && blockIndex >= 2)) {
      break;
    }
  }
  flush();
  return SeasonPlan(
    createdOn: createdOn,
    engineVersion: kalisPlanVersion,
    eventIds: <String>[if (target?.eventId != null) target!.eventId!],
    phases: phases,
    reasons: <Reason>[
      if (target?.eventId != null)
        reason(ReasonCodes.planPeakEvent, <String, Object?>{
          'eventId': target!.eventId,
        }),
    ],
  );
}
