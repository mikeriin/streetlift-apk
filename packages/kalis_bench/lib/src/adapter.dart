/// Adaptateur du profil du banc vers le profil d'athlète de `kalis_core`.
///
/// C'est le **seul** endroit qui connaît le schéma du profil des moteurs.
/// Depuis `kalis_bench` 0.1.1 : `AthleteProfile` au schéma 3 (kalis_core
/// 0.4) — expérience, ancienneté, coupure, récupération, tests datés,
/// échéances, figures, points faibles, spécialisation, antécédents (voir
/// `docs/PROFILS.md`, § Adaptateur).
library;

import 'package:kalis_core/kalis_core.dart';

import 'profile.dart';

/// Premier jour des programmes du banc (un lundi, celui des simulations de
/// `kalis_adapt` et des rapports de `kalis_plan`).
final CivilDate benchStartDate = CivilDate(2026, 10, 5);

/// Profil adapté et ce que l'adaptation a perdu.
final class AdaptedProfile {
  /// Résultat de l'adaptation.
  const AdaptedProfile(this.profile, this.lost);

  /// Profil lisible par les moteurs.
  final AthleteProfile profile;

  /// Informations du profil du banc que le profil des moteurs ne sait pas
  /// porter (codes stables, voir [lostFieldLabels]).
  final List<String> lost;
}

/// Nom français de chaque information perdue par l'adaptation.
const Map<String, String> lostFieldLabels = <String, String>{
  'weak_points_muscle':
      'points faibles musculaires (le profil ne porte que les points '
      "faibles d'un mouvement)",
  'injury_label': 'description de la blessure',
  'sleep_quality': 'qualité du sommeil (seule la durée est transmise)',
  'event_label': "libellé de l'échéance",
  'maintain_list':
      'liste des mouvements à entretenir (la spécialisation porte la '
      "cible ; le reste passe en entretien d'office)",
};

/// Jour de l'échéance située à [weeksOut] semaines du début [start] : le
/// samedi de la dernière semaine.
CivilDate eventDate(CivilDate start, int weeksOut) =>
    start.addDays(7 * weeksOut - 2);

Map<String, Object?> _goalJson(
  String id,
  BenchTarget t,
  CivilDate start,
  int weeksOut,
) => <String, Object?>{
  'id': id,
  'kind': GoalKind.performance.code,
  'origin': GoalOrigin.user.code,
  'createdOn': start.iso,
  'exerciseId': t.exerciseId,
  'metric': t.metric.code,
  if (t.targetValue != null) 'targetValue': t.targetValue,
  if (t.distanceMeters != null) 'distanceMeters': t.distanceMeters,
  if (t.loadKg != null) 'loadKg': t.loadKg,
  if (t.durationSeconds != null) 'durationSeconds': t.durationSeconds,
  'targetDate': eventDate(start, weeksOut).iso,
};

/// Profil des moteurs du profil du banc [p], pour un programme qui
/// commence le [start]. Avec [catalog], les figures visées reçoivent leur
/// étape actuelle (`skills`).
///
/// [FormatException] si le profil obtenu n'est pas lisible ;
/// [ArgumentError] s'il viole un invariant du contrat de `kalis_core`.
AdaptedProfile adaptProfile(
  BenchProfile p, {
  CivilDate? start,
  Catalog? catalog,
}) {
  final day = start ?? benchStartDate;
  final lost = <String>[];
  void lose(String code) {
    if (!lost.contains(code)) {
      lost.add(code);
    }
  }

  final json = Map<String, Object?>.of(p.core);
  json['schemaVersion'] = 3;
  json['createdOn'] = day.iso;
  json['updatedOn'] = day.iso;
  json.putIfAbsent('likedExerciseIds', () => <Object?>[]);
  json.putIfAbsent('dislikedExerciseIds', () => <Object?>[]);
  json.putIfAbsent('loadIncrements', () => <Object?>[]);
  json.putIfAbsent('guidanceMode', () => GuidanceMode.assisted.code);
  json['experience'] = p.level.code;
  final months = p.trainingAgeMonths;
  json['trainingAge'] =
      (months < 6
              ? TrainingAge.under6Months
              : (months < 24
                    ? TrainingAge.months6To24
                    : (months < 60
                          ? TrainingAge.years2To5
                          : TrainingAge.over5Years)))
          .code;
  final off = p.breakWeeks;
  json['trainingGap'] =
      (off <= 0
              ? TrainingGap.none
              : (off < 3
                    ? TrainingGap.under3Weeks
                    : (off <= 10
                          ? TrainingGap.weeks3To10
                          : (off <= 26
                                ? TrainingGap.weeks10To26
                                : (off <= 104
                                      ? TrainingGap.months6To24
                                      : TrainingGap.over2Years)))))
          .code;
  final sleepHours = p.recovery.sleepHours;
  if (sleepHours != null) {
    json['sleep'] =
        (sleepHours < 6
                ? SleepBand.under6Hours
                : (sleepHours < 7 ? SleepBand.hours6To7 : SleepBand.hours7Plus))
            .code;
  }
  if (p.recovery.sleepQuality != null) {
    lose('sleep_quality');
  }
  final stress = p.recovery.stress;
  if (stress != null) {
    json['stress'] =
        (stress <= 2
                ? StressBand.low
                : (stress == 3 ? StressBand.moderate : StressBand.high))
            .code;
  }
  if (p.recovery.physicalJob == 'heavy') {
    json['occupationalLoad'] = OccupationalLoad.heavy.code;
  }
  if (p.recovery.energyDeficit) {
    json['bodyWeightGoal'] = BodyWeightGoal.lose.code;
  }
  if (p.recovery.otherSports.isNotEmpty) {
    json['otherSports'] = <Object?>[
      for (final s in p.recovery.otherSports)
        OtherSport(
          kind: switch (s.sport) {
            'running' || 'course' => OtherSportKind.running,
            'cycling' || 'velo' => OtherSportKind.cycling,
            'swimming' || 'natation' => OtherSportKind.swimming,
            'climbing' || 'escalade' => OtherSportKind.climbing,
            _ => OtherSportKind.other,
          },
          sessionsPerWeek: s.sessionsPerWeek,
          minutesPerSession: s.minutesPerSession,
          hard: s.intensity == 'hard',
        ).toJson(),
    ];
  }

  // Records : fourchette (lue par le chemin 0.1) et test daté (schéma 3).
  final bodyWeight = json['bodyWeightKg'];
  final levels = <Object?>[];
  final benchmarks = <Object?>[];
  for (final r in p.records) {
    levels.add(<String, Object?>{
      'exerciseId': r.exerciseId,
      'measure': r.measure.code,
      'known': true,
      'low': r.value,
      'high': r.value,
      if (r.distanceMeters != null) 'distanceMeters': r.distanceMeters,
    });
    final weeksAgo = r.testedWeeksAgo;
    final date = weeksAgo == null ? null : day.addDays(-7 * weeksAgo);
    Benchmark? b;
    switch (r.measure) {
      case LevelMeasure.oneRmKg:
        b = Benchmark(
          exerciseId: r.exerciseId,
          kind: BenchmarkKind.loadReps,
          source: BenchmarkSource.declared,
          date: date,
          externalLoadKg: r.value,
          reps: 1,
          rir: 0,
          bodyWeightKg: bodyWeight is num ? bodyWeight.toDouble() : null,
        );
      case LevelMeasure.maxReps:
        if (r.value > 0) {
          b = Benchmark(
            exerciseId: r.exerciseId,
            kind: BenchmarkKind.maxReps,
            source: BenchmarkSource.declared,
            date: date,
            reps: r.value.round(),
          );
        }
      case LevelMeasure.maxHoldSeconds:
        if (r.value > 0) {
          b = Benchmark(
            exerciseId: r.exerciseId,
            kind: BenchmarkKind.maxHold,
            source: BenchmarkSource.declared,
            date: date,
            seconds: r.value.round(),
          );
        }
      case LevelMeasure.timeSeconds:
        final meters = r.distanceMeters;
        if (meters != null && r.value > 0) {
          b = Benchmark(
            exerciseId: r.exerciseId,
            kind: BenchmarkKind.timeTrial,
            source: BenchmarkSource.declared,
            date: date,
            seconds: r.value.round(),
            distanceMeters: meters,
          );
        }
    }
    if (b != null) {
      benchmarks.add(b.toJson());
    }
  }
  for (final id in p.unknownLevels) {
    levels.add(<String, Object?>{
      'exerciseId': id,
      'measure': LevelMeasure.maxReps.code,
      'known': false,
    });
  }
  json['movementLevels'] = levels;
  if (benchmarks.isNotEmpty) {
    json['benchmarks'] = benchmarks;
  }

  // Échéances : l'objectif daté par mouvement (chemin 0.1) et l'échéance
  // du schéma 3 (nature, priorité, format).
  final goals = <Object?>[];
  final events = <Object?>[];
  final targets = <BenchTarget>[];
  double? recordOf(String id) {
    for (final r in p.records) {
      if (r.exerciseId == id && r.measure == LevelMeasure.oneRmKg) {
        return r.value;
      }
    }
    return null;
  }

  for (final e in p.events) {
    final goalIds = <String>[];
    for (var i = 0; i < e.targets.length; i++) {
      goalIds.add('${e.id}-${i + 1}');
      goals.add(_goalJson('${e.id}-${i + 1}', e.targets[i], day, e.weeksOut));
      targets.add(e.targets[i]);
    }
    final test = e.kind == 'test';
    final kind = test
        ? EventKind.personalTest
        : switch (e.format) {
            'streetlifting' || 'powerlifting' => EventKind.strengthCompetition,
            'sets_reps' => EventKind.repsCompetition,
            'course' => EventKind.race,
            _ => EventKind.otherCompetition,
          };
    final lifts = <CompetitionLift>[
      for (final t in e.targets)
        if (t.metric == GoalMetric.oneRmKg)
          CompetitionLift(
            exerciseId: t.exerciseId,
            attempts: 3,
            bestKg: recordOf(t.exerciseId),
            targetKg: t.targetValue,
          ),
    ];
    final stations = <EventStation>[
      for (final t in e.targets)
        if (t.metric == GoalMetric.maxReps)
          EventStation(exerciseId: t.exerciseId),
    ];
    BenchTarget? timed;
    for (final t in e.targets) {
      if (t.metric == GoalMetric.timeSeconds) {
        timed = t;
      }
    }
    events.add(
      SeasonEvent(
        id: e.id,
        kind: kind,
        priority: e.priority == 'A'
            ? EventPriority.main
            : (e.priority == 'B'
                  ? EventPriority.secondary
                  : EventPriority.preparation),
        date: eventDate(day, e.weeksOut),
        lifts: lifts.isEmpty || kind == EventKind.race ? null : lifts,
        mode: kind == EventKind.repsCompetition ? RepsEventMode.maxReps : null,
        stations: kind == EventKind.repsCompetition && stations.isNotEmpty
            ? stations
            : null,
        distanceMeters: kind == EventKind.race ? timed?.distanceMeters : null,
        targetSeconds: kind == EventKind.race
            ? timed?.targetValue?.round()
            : null,
        goalIds: goalIds,
      ).toJson(),
    );
    lose('event_label');
  }
  for (final g in p.goals) {
    goals.add(_goalJson(g.id, g.target, day, g.weeksOut));
    targets.add(g.target);
  }
  final habitSessions = p.habitSessionsPerWeek;
  final habitWeeks = p.habitWeeks;
  if (habitSessions != null && habitWeeks != null) {
    goals.add(<String, Object?>{
      'id': 'habitude',
      'kind': GoalKind.habit.code,
      'origin': GoalOrigin.user.code,
      'createdOn': day.iso,
      'sessionsPerWeek': habitSessions,
      'weeks': habitWeeks,
    });
  }
  json['goals'] = goals;
  if (events.isNotEmpty) {
    json['events'] = events;
  }

  // Figures : l'étape actuelle est le record le plus avancé de la chaîne
  // de la figure visée.
  if (catalog != null) {
    final skills = <Object?>[];
    final seen = <String>{};
    for (final t in targets) {
      final target = catalog.find(t.exerciseId);
      if (target == null ||
          !seen.add(t.exerciseId) ||
          (t.metric != GoalMetric.skillUnlocked &&
              t.metric != GoalMetric.maxHoldSeconds)) {
        continue;
      }
      BenchRecord? best;
      var bestDifficulty = -1;
      for (final r in p.records) {
        final step = catalog.find(r.exerciseId);
        if (step == null || r.value <= 0) {
          continue;
        }
        final onPath =
            r.exerciseId == t.exerciseId ||
            catalog.isProgressionStep(r.exerciseId, t.exerciseId);
        if (onPath && step.difficulty > bestDifficulty) {
          best = r;
          bestDifficulty = step.difficulty;
        }
      }
      if (best == null) {
        continue;
      }
      skills.add(
        SkillState(
          targetExerciseId: t.exerciseId,
          currentExerciseId: best.exerciseId,
          bestHoldSeconds: best.measure == LevelMeasure.maxHoldSeconds
              ? best.value.round()
              : null,
          bestReps: best.measure == LevelMeasure.maxReps
              ? best.value.round()
              : null,
        ).toJson(),
      );
    }
    if (skills.isNotEmpty) {
      json['skills'] = skills;
    }
  }

  // Points faibles d'un mouvement : la nature est lue dans la note.
  final weak = <Object?>[];
  // Point faible d'un groupe musculaire (CP2, partie 1) : le premier devient
  // la spécialisation « muscle » du profil quand aucun mouvement n'est
  // prioritaire (le contrat n'en porte qu'une) ; les suivants sont perdus.
  String? weakMuscle;
  for (final w in p.weakPoints) {
    final id = w.exerciseId;
    if (id == null) {
      final muscle = w.muscleGroup;
      if (muscle != null &&
          weakMuscle == null &&
          p.priorityExerciseIds.isEmpty) {
        weakMuscle = muscle;
      } else {
        lose('weak_points_muscle');
      }
      continue;
    }
    final note = w.note.toLowerCase();
    final kind = note.contains('départ') || note.contains('bras tendus')
        ? WeakPointKind.deadStart
        : (note.contains('verrouillage')
              ? WeakPointKind.lockout
              : (note.contains('transition')
                    ? WeakPointKind.transition
                    : (note.contains('bas')
                          ? WeakPointKind.bottom
                          : WeakPointKind.midRange)));
    weak.add(WeakPoint(exerciseId: id, kind: kind).toJson());
  }
  if (weak.isNotEmpty) {
    json['weakPoints'] = weak;
  }

  if (weakMuscle != null) {
    json['specialization'] = Specialization(
      kind: SpecializationKind.muscle,
      muscle: weakMuscle,
      maintenance: MaintenancePolicy.maintain,
    ).toJson();
  }

  if (p.priorityExerciseIds.isNotEmpty) {
    final main = p.mainEvent;
    json['specialization'] = Specialization(
      kind: SpecializationKind.exercise,
      exerciseId: p.priorityExerciseIds.first,
      weeks: main?.weeksOut,
      maintenance: MaintenancePolicy.maintain,
    ).toJson();
    if (p.maintainExerciseIds.isNotEmpty) {
      lose('maintain_list');
    }
  }

  final limitations = <Object?>[];
  for (final i in p.injuries) {
    final ago = i.monthsAgo;
    final history = i.status == 'history';
    ConstraintSince? since;
    if (ago != null) {
      since = ago >= 12
          ? (history && i.discomfort == 0
                ? ConstraintSince.pastResolved
                : ConstraintSince.over12Months)
          : (ago >= 3
                ? ConstraintSince.months3To12
                : (ago >= 2
                      ? ConstraintSince.weeks6To12
                      : ConstraintSince.under6Weeks));
    }
    limitations.add(<String, Object?>{
      'zone': i.zone.code,
      'side': i.side.code,
      if (i.joint != null) 'joint': i.joint!.code,
      'discomfort': i.discomfort,
      if (since != null) 'since': since.code,
    });
    lose('injury_label');
  }
  json['limitations'] = limitations;

  final profile = AthleteProfile.fromJson(json);
  final violations = profile.validate();
  if (violations.isNotEmpty) {
    throw ArgumentError.value(
      p.key,
      'profil',
      'profil adapté invalide : ${violations.join(' ; ')}',
    );
  }
  return AdaptedProfile(profile, List<String>.unmodifiable(lost));
}
