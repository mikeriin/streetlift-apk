// Structure de la semaine (lot KS1, `pipeline/cp/CAHIER_KS.md`) : qualités
// et répartition des séances, gabarit choisi, placement, type de chaque
// jour, couverture des objectifs, jalons, récupération recalée, corrections
// de charge du § 8.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

final CivilDate _start = CivilDate(2026, 10, 5);

const List<String> _gym = <String>[
  'barre fixe',
  'barres parallèles',
  'barre basse',
  'élastique',
  'ceinture de lest',
  'disques',
  'barre olympique',
  'cage / rack',
  'magnésie',
  'banc plat',
  'haltères',
  'poulie',
  'anneaux',
  'tapis',
  'box / plinth',
];

Benchmark _oneRm(String id, double kg) => Benchmark(
  exerciseId: id,
  kind: BenchmarkKind.loadReps,
  source: BenchmarkSource.declared,
  externalLoadKg: kg,
  reps: 1,
  rir: 0,
  bodyWeightKg: 80,
);

Benchmark _maxReps(String id, int reps) => Benchmark(
  exerciseId: id,
  kind: BenchmarkKind.maxReps,
  source: BenchmarkSource.declared,
  reps: reps,
);

Goal _goal(
  String id,
  String exerciseId,
  GoalMetric metric,
  double value,
  CivilDate date, {
  double? loadKg,
}) => Goal(
  id: id,
  kind: GoalKind.performance,
  origin: GoalOrigin.user,
  createdOn: _start,
  exerciseId: exerciseId,
  metric: metric,
  targetValue: value,
  loadKg: loadKg,
  targetDate: date,
);

/// Profil proche du profil de test du cahier (§ 7.1) : streetlifting 50 /
/// sets & reps 50, six séances de 120 minutes, neuf objectifs datés, une
/// échéance secondaire plus lointaine.
AthleteProfile _testProfile({
  List<int> weekdays = const <int>[1, 2, 3, 4, 5, 6],
  int force = 50,
  int endurance = 50,
  List<WeakPoint>? weakPoints,
  List<SeasonEvent>? events,
}) {
  final goals = CivilDate(2027, 4, 30);
  return AthleteProfile(
    schemaVersion: 3,
    sex: Sex.male,
    birthYear: 1996,
    heightCm: 178,
    bodyWeightKg: 80,
    disciplines: DisciplineMix(
      primary: force >= endurance
          ? TrainingDiscipline.streetlifting
          : TrainingDiscipline.streetWorkout,
      primaryPct: force >= endurance ? force : endurance,
      secondaries: <DisciplineShare>[
        DisciplineShare(
          discipline: force >= endurance
              ? TrainingDiscipline.streetWorkout
              : TrainingDiscipline.streetlifting,
          pct: force >= endurance ? endurance : force,
        ),
      ],
    ),
    movementLevels: const <MovementLevel>[],
    goals: <Goal>[
      _goal('g1', Ids.weightedMuscleUp, GoalMetric.oneRmKg, 13, goals),
      _goal('g2', Ids.weightedPull, GoalMetric.oneRmKg, 55, goals),
      _goal('g3', Ids.weightedDip, GoalMetric.oneRmKg, 77.5, goals),
      _goal('g4', Ids.squat, GoalMetric.oneRmKg, 135, goals),
      _goal('g5', Ids.pull, GoalMetric.maxReps, 26, goals),
      _goal('g6', Ids.pushUp, GoalMetric.maxReps, 70, goals),
      _goal('g7', Ids.dip, GoalMetric.maxReps, 42, goals),
      _goal('g8', Ids.muscleUp, GoalMetric.maxReps, 13, goals),
      _goal('g9', Ids.squat, GoalMetric.maxReps, 35, goals, loadKg: 70),
    ],
    availability: <DaySlot>[
      for (final w in weekdays) DaySlot(weekday: w, minutes: 120),
    ],
    places: const <Place>[Place.gym],
    equipment: _gym,
    loadIncrements: const <LoadIncrement>[
      LoadIncrement(loadType: LoadType.addedWeight, stepKg: 1.25),
      LoadIncrement(loadType: LoadType.barbell, stepKg: 2.5, minKg: 20),
    ],
    limitations: const <Limitation>[],
    likedExerciseIds: const <String>[Ids.weightedPull, Ids.dip],
    dislikedExerciseIds: const <String>[],
    experience: ExperienceLevel.advanced,
    guidanceMode: GuidanceMode.free,
    healthScreening: HealthScreeningRef(
      questionnaireId: 'l13-v1',
      answeredOn: _start,
      outcome: HealthScreeningOutcome.standard,
    ),
    createdOn: _start,
    updatedOn: _start,
    trainingAge: TrainingAge.years2To5,
    trainingGap: TrainingGap.none,
    benchmarks: <Benchmark>[
      _oneRm(Ids.weightedPull, 48),
      _oneRm(Ids.weightedMuscleUp, 8),
      _oneRm(Ids.squat, 127),
      _oneRm(Ids.weightedDip, 70),
      _maxReps(Ids.pull, 22),
      _maxReps(Ids.dip, 35),
      _maxReps(Ids.pushUp, 60),
      _maxReps(Ids.muscleUp, 10),
    ],
    events:
        events ??
        <SeasonEvent>[
          SeasonEvent(
            id: 'e1',
            kind: EventKind.strengthCompetition,
            priority: EventPriority.secondary,
            date: CivilDate(2027, 12, 15),
            lifts: const <CompetitionLift>[
              CompetitionLift(exerciseId: Ids.weightedPull, attempts: 3),
            ],
          ),
        ],
    weakPoints: weakPoints,
  );
}

PlanRequest _request(AthleteProfile profile) => PlanRequest(
  profile: profile,
  seed: 0,
  startDate: _start,
  locks: const <PlanLock>[],
);

ProgramBlock _block(Catalog catalog, AthleteProfile profile) {
  final engine = KalisPlan();
  final request = _request(profile);
  final pass1 = engine.createPass1(catalog, request);
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  return ProgramBlock(pass1: pass1, pass2: pass2);
}

void main() {
  final catalog = loadCatalog();

  group('qualités et séances (§ 3.3)', () {
    test('plus fort reste, une séance au moins par qualité', () {
      expect(coachQualitySessions(6, 50, 50, forceFirst: true), (3, 3));
      expect(coachQualitySessions(5, 50, 50, forceFirst: true), (3, 2));
      expect(coachQualitySessions(5, 50, 50, forceFirst: false), (2, 3));
      expect(coachQualitySessions(4, 60, 30, forceFirst: true), (3, 1));
      expect(coachQualitySessions(3, 30, 50, forceFirst: false), (1, 2));
      expect(coachQualitySessions(4, 25, 75, forceFirst: false), (1, 3));
      expect(coachQualitySessions(2, 90, 25, forceFirst: true), (1, 1));
    });

    test('deux qualités à 25 % au moins : profil mixte ; sinon gabarit '
        'de son chemin', () {
      final mixed = Athlete.read(catalog, _testProfile(), _start);
      expect(mixedStreetShares(mixed, styleOf(mixed)), (50, 50));
      final mono = Athlete.read(
        catalog,
        _testProfile(force: 80, endurance: 20),
        _start,
      );
      expect(mixedStreetShares(mono, styleOf(mono)), isNull);
      final plan = KalisPlan().createPass1(
        catalog,
        _request(_testProfile(force: 80, endurance: 20)),
      );
      expect(plan.split!.templateId, SplitTemplates.liftDup);
      for (final d in plan.days) {
        expect(d.type, isNotNull, reason: 'jour ${d.dayIndex}');
      }
    });
  });

  group('profil de test : ppl6_q (§ 7)', () {
    late ProgramBlock block;
    setUpAll(() {
      block = _block(catalog, _testProfile());
    });

    test('gabarit, types et placement', () {
      final plan = block.pass1;
      expect(plan.split!.templateId, SplitTemplates.pushPullLegs6);
      expect(
        plan.split!.reasons.first.code,
        ReasonCodes.planSplitChosen,
      );
      final types = <String>[
        for (final d in plan.days)
          '${d.type!.patterns.map((p) => p.code).join('+')}/'
              '${d.type!.quality.code}',
      ];
      expect(types, <String>[
        'pull/force',
        'push/force',
        'legs/force',
        'pull/endurance',
        'push/endurance',
        'legs/endurance',
      ]);
      // Le muscle-up lesté ouvre le lundi, qui ouvre la rotation (§ 11.2).
      final monday = plan.days.first.slots
          .where((s) => s.role != SlotRole.warmup)
          .first;
      expect(monday.exerciseId, Ids.weightedMuscleUp);
      for (final d in plan.days) {
        expect(
          d.slots.any((s) => s.role == SlotRole.main),
          isTrue,
          reason: 'jour ${d.dayIndex} sans principal',
        );
      }
    });

    test('neuf objectifs portés, jalon avant l\'échéance secondaire', () {
      final plan = block.pass1;
      expect(
        plan.reasons.where((r) => r.code == ReasonCodes.planGoalUncovered),
        isEmpty,
      );
      final milestone = plan.reasons.firstWhere(
        (r) => r.code == ReasonCodes.planMilestone,
      );
      expect(milestone.params['date'], '2027-04-30');
      expect(milestone.params['goals'], 9);
      final target = targetOf(_testProfile(), _start)!;
      expect(target.event, isNull);
      expect(target.date, CivilDate(2027, 4, 30));
      // Une échéance principale prime toujours.
      final main = targetOf(
        _testProfile(
          events: <SeasonEvent>[
            SeasonEvent(
              id: 'e1',
              kind: EventKind.strengthCompetition,
              priority: EventPriority.main,
              date: CivilDate(2027, 12, 15),
              lifts: const <CompetitionLift>[
                CompetitionLift(exerciseId: Ids.weightedPull, attempts: 3),
              ],
            ),
          ],
        ),
        _start,
      )!;
      expect(main.eventId, 'e1');
    });

    test('récupération recalée ≥ 0,9, aucun schéma lourd deux jours de '
        'suite', () {
      final recovery = block.pass1.score.components.firstWhere(
        (c) => c.code == 'recovery',
      );
      expect(recovery.value, greaterThanOrEqualTo(coachRecoveryFloor));
    });

    test('charge fixe du squat 35 × 70 kg et lest minimal du muscle-up', () {
      var fixed = 0;
      var mu = 0;
      for (final w in block.pass2.weeks) {
        for (final d in w.days) {
          for (final i in d.items) {
            final note = i.reasons
                .where((r) => r.code == ReasonCodes.planCoachNote)
                .map((r) => r.params['note'])
                .toSet();
            if (note.contains(CoachNotes.fixedLoad)) {
              fixed++;
              expect(i.exerciseId, Ids.squat);
              expect(i.startLoadKg, 70);
              expect(i.repsLow, i.repsHigh);
              expect(i.repsHigh!, inInclusiveRange(3, 35));
            }
            if (i.exerciseId == Ids.weightedMuscleUp &&
                w.kind == WeekKind.build &&
                i.kind != SetKind.test &&
                i.kind != SetKind.warmup) {
              mu++;
              // (Plus jamais +0 kg sur le mouvement visé en semaine de
              // charge : § 8.1 ; une semaine légère reste au poids du
              // corps.)
              expect(i.startLoadKg ?? 0, greaterThan(0), reason: '$i');
            }
          }
        }
      }
      expect(fixed, greaterThan(0));
      expect(mu, greaterThan(0));
    });

    test('déterministe', () {
      final again = _block(catalog, _testProfile());
      expect(
        jsonEncode(again.pass1.toJson()),
        jsonEncode(block.pass1.toJson()),
      );
      expect(
        jsonEncode(again.pass2.toJson()),
        jsonEncode(block.pass2.toJson()),
      );
    });
  });

  group('corrections de charge (§ 8)', () {
    test('squat pause bas et traction haute : charges de leur référence', () {
      final block = _block(
        catalog,
        _testProfile(
          weakPoints: const <WeakPoint>[
            WeakPoint(exerciseId: Ids.squat, kind: WeakPointKind.bottom),
            WeakPoint(
              exerciseId: Ids.weightedMuscleUp,
              kind: WeakPointKind.transition,
            ),
          ],
        ),
      );
      var pause = 0;
      var high = 0;
      for (final w in block.pass2.weeks) {
        for (final d in w.days) {
          for (final i in d.items) {
            if (i.exerciseId == 'sl-squat-pause-bas') {
              pause++;
              expect(i.toCalibrate, isFalse);
              expect(i.startLoadKg, isNotNull);
            }
            if (i.exerciseId == 'sl-traction-haute-lestee' &&
                i.intensity != null) {
              high++;
              expect(
                i.intensity!.referenceExerciseId,
                Ids.weightedPull,
                reason: '$i',
              );
            }
          }
        }
      }
      expect(pause + high, greaterThan(0));
    });

    test('remplacement à la revue : raison du remplaçant', () {
      final engine = KalisPlan();
      final request = _request(_testProfile(force: 80, endurance: 20));
      final plan = engine.createPass1(catalog, request);
      final slot = plan.days.first.slots.firstWhere(
        (s) => s.role == SlotRole.accessory,
      );
      final result = engine.review(
        catalog,
        ReviewRequest(
          request: request,
          current: plan,
          action: ReviewAction(kind: ReviewKind.dislike, slotId: slot.slotId),
        ),
      );
      var seen = 0;
      for (final d in result.plan.days) {
        for (final s in d.slots) {
          for (final r in s.reasons) {
            expect(r.code, isNot(ReasonCodes.planUserDislikes));
            if (r.code == ReasonCodes.planReplacedDisliked) {
              seen++;
              expect(r.params['exerciseId'], slot.exerciseId);
            }
          }
        }
      }
      expect(seen, greaterThan(0));
    });
  });
}
