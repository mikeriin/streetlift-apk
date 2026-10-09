// Valeurs de référence valides, partagées par les tests.
import 'package:kalis_core/kalis_core.dart';

AthleteProfile baseProfile() {
  return AthleteProfile(
    sex: Sex.female,
    birthYear: 1990,
    heightCm: 168,
    bodyWeightKg: 62,
    disciplines: const DisciplineMix(
      primary: TrainingDiscipline.musculation,
      primaryPct: 70,
      secondaries: <DisciplineShare>[
        DisciplineShare(discipline: TrainingDiscipline.mobility, pct: 20),
        DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 10),
      ],
    ),
    movementLevels: const <MovementLevel>[
      MovementLevel(
        exerciseId: 'sw-pompe',
        measure: LevelMeasure.maxReps,
        known: true,
        low: 8,
        high: 12,
      ),
      MovementLevel(
        exerciseId: 'mu-back-squat-barre-haute',
        measure: LevelMeasure.oneRmKg,
        known: false,
      ),
    ],
    goals: <Goal>[
      Goal(
        id: 'g1',
        kind: GoalKind.performance,
        origin: GoalOrigin.user,
        createdOn: CivilDate(2026, 10, 1),
        exerciseId: 'mu-back-squat-barre-haute',
        metric: GoalMetric.oneRmKg,
        targetValue: 80,
        targetDate: CivilDate(2027, 4, 1),
      ),
      Goal(
        id: 'g2',
        kind: GoalKind.habit,
        origin: GoalOrigin.suggested,
        createdOn: CivilDate(2026, 10, 1),
        sessionsPerWeek: 3,
        weeks: 8,
      ),
    ],
    availability: const <DaySlot>[
      DaySlot(weekday: 1, minutes: 60),
      DaySlot(weekday: 3, minutes: 45),
      DaySlot(weekday: 6, minutes: 90),
    ],
    places: const <Place>[Place.gym],
    equipment: const <String>['barre olympique', 'disques', 'cage / rack'],
    loadIncrements: const <LoadIncrement>[
      LoadIncrement(loadType: LoadType.barbell, stepKg: 2.5, minKg: 20),
    ],
    limitations: const <Limitation>[
      Limitation(
        zone: BodyZone.knee,
        side: BodySide.left,
        joint: Joint.knee,
        discomfort: 3,
      ),
    ],
    likedExerciseIds: const <String>['mu-hip-thrust-barre'],
    dislikedExerciseIds: const <String>['cf-burpee'],
    guidanceMode: GuidanceMode.assisted,
    createdOn: CivilDate(2026, 10, 1),
    updatedOn: CivilDate(2026, 10, 1),
  );
}

const SetRecord baseSet = SetRecord(
  exerciseId: 'sw-pompe',
  exerciseOrder: 0,
  setIndex: 0,
  kind: SetKind.work,
  reps: 10,
  flames: 7,
  success: true,
  excluded: false,
);

SessionRecord session(String id, String date, {bool resume = false}) {
  return SessionRecord(
    id: id,
    date: CivilDate.parse(date),
    origin: SessionOrigin.program,
    resume: resume,
    completed: true,
    sets: const <SetRecord>[baseSet],
    pains: const <PainReport>[],
  );
}

const ExercisePrescription basePrescription = ExercisePrescription(
  slotId: 'd0s0',
  exerciseId: 'sw-pompe',
  sets: 3,
  repsLow: 8,
  repsHigh: 12,
  targetFlames: 7,
  restSeconds: 90,
  toCalibrate: false,
  loadBasis: LoadBasis.bodyweight,
  reasons: <Reason>[],
);

Pass1Plan basePass1() {
  return Pass1Plan(
    blockId: 'b0',
    blockIndex: 0,
    weeks: 4,
    startDate: CivilDate(2026, 10, 5),
    seed: 1,
    engineVersion: '0.0.0-test',
    days: const <PlanDay>[
      PlanDay(
        dayIndex: 0,
        weekday: 1,
        minutesBudget: 60,
        focus: 'full_body',
        slots: <PlanSlot>[
          PlanSlot(
            slotId: 'd0s0',
            exerciseId: 'sw-pompe',
            role: SlotRole.main,
            locked: false,
            reasons: <Reason>[],
          ),
        ],
      ),
    ],
    score: const PlanScore(total: 0.8, components: <ScoreComponent>[]),
    reasons: const <Reason>[],
  );
}

Pass2Plan basePass2() {
  return Pass2Plan(
    blockId: 'b0',
    engineVersion: '0.0.0-test',
    weeks: <WeekPrescription>[
      for (var w = 0; w < 4; w++)
        WeekPrescription(
          weekIndex: w,
          kind: w == 3 ? WeekKind.deload : WeekKind.build,
          days: const <DayPrescription>[
            DayPrescription(
              dayIndex: 0,
              items: <ExercisePrescription>[basePrescription],
            ),
          ],
        ),
    ],
    reasons: const <Reason>[],
  );
}
