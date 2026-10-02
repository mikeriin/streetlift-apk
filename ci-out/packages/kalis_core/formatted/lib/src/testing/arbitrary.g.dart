// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
// Valeurs aléatoires seedées de chaque type du contrat (tests de propriétés).
// Les bornes simples sont respectées ; les invariants croisés ne le sont pas
// forcément : ces valeurs servent aux allers-retours JSON, pas à la validation.
import 'dart:math';

import '../civil_date.dart';
import '../contracts.dart';
import 'arbitrary_base.dart';

/// Valeur aléatoire de [Reason].
Reason arbitraryReason(Random r) {
  return Reason(code: arbString(r, 1, 12), params: arbJson(r));
}

/// Valeur aléatoire de [DisciplineShare].
DisciplineShare arbitraryDisciplineShare(Random r) {
  return DisciplineShare(
    discipline: arbEnum(r, TrainingDiscipline.values),
    pct: arbInt(r, 1, 99),
  );
}

/// Valeur aléatoire de [DisciplineMix].
DisciplineMix arbitraryDisciplineMix(Random r) {
  return DisciplineMix(
    primary: arbEnum(r, TrainingDiscipline.values),
    primaryPct: arbInt(r, 1, 100),
    secondaries: arbList(r, 0, 2, () => arbitraryDisciplineShare(r)),
  );
}

/// Valeur aléatoire de [StreetMode].
StreetMode arbitraryStreetMode(Random r) {
  return StreetMode(
    primary: arbEnum(r, StreetStyle.values),
    streetliftingPct: arbInt(r, 0, 100),
    setsRepsPct: arbInt(r, 0, 100),
    calisthenicsPct: arbInt(r, 0, 100),
  );
}

/// Valeur aléatoire de [MovementLevel].
MovementLevel arbitraryMovementLevel(Random r) {
  return MovementLevel(
    exerciseId: arbId(r),
    measure: arbEnum(r, LevelMeasure.values),
    known: r.nextBool(),
    low: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    high: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
  );
}

/// Valeur aléatoire de [Goal].
Goal arbitraryGoal(Random r) {
  return Goal(
    id: arbString(r, 1, 12),
    kind: arbEnum(r, GoalKind.values),
    origin: arbEnum(r, GoalOrigin.values),
    createdOn: arbDate(r),
    exerciseId: r.nextBool() ? null : arbId(r),
    metric: r.nextBool() ? null : arbEnum(r, GoalMetric.values),
    targetValue: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    loadKg: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    durationSeconds: r.nextBool() ? null : arbInt(r, 1, 1001),
    targetDate: r.nextBool() ? null : arbDate(r),
    sessionsPerWeek: r.nextBool() ? null : arbInt(r, 1, 14),
    weeks: r.nextBool() ? null : arbInt(r, 1, 104),
  );
}

/// Valeur aléatoire de [DaySlot].
DaySlot arbitraryDaySlot(Random r) {
  return DaySlot(
    weekday: arbInt(r, 1, 7),
    minutes: arbInt(r, 10, 300),
    place: r.nextBool() ? null : arbEnum(r, Place.values),
  );
}

/// Valeur aléatoire de [PlaceEquipment].
PlaceEquipment arbitraryPlaceEquipment(Random r) {
  return PlaceEquipment(
    place: arbEnum(r, Place.values),
    equipment: arbList(r, 0, 3, () => arbString(r, 0, 12)),
  );
}

/// Valeur aléatoire de [LoadIncrement].
LoadIncrement arbitraryLoadIncrement(Random r) {
  return LoadIncrement(
    loadType: arbEnum(r, LoadType.values),
    stepKg: arbDouble(r, 0.05, 50.0),
    minKg: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
  );
}

/// Valeur aléatoire de [Limitation].
Limitation arbitraryLimitation(Random r) {
  return Limitation(
    zone: arbEnum(r, BodyZone.values),
    side: arbEnum(r, BodySide.values),
    joint: r.nextBool() ? null : arbEnum(r, Joint.values),
    discomfort: arbInt(r, 0, 10),
    since: r.nextBool() ? null : arbEnum(r, ConstraintSince.values),
    aggravatedBy: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbEnum(r, AggravatingMovement.values)),
    effortDiscomfort: r.nextBool() ? null : arbInt(r, 0, 10),
  );
}

/// Valeur aléatoire de [HealthScreeningRef].
HealthScreeningRef arbitraryHealthScreeningRef(Random r) {
  return HealthScreeningRef(
    questionnaireId: arbString(r, 1, 12),
    answeredOn: r.nextBool() ? null : arbDate(r),
    outcome: arbEnum(r, HealthScreeningOutcome.values),
  );
}

/// Valeur aléatoire de [AthleteProfile].
AthleteProfile arbitraryAthleteProfile(Random r) {
  return AthleteProfile(
    schemaVersion: AthleteProfile.currentSchemaVersion,
    displayName: r.nextBool() ? null : arbString(r, 0, 40),
    sex: arbEnum(r, Sex.values),
    birthYear: arbInt(r, 1900, 2100),
    heightCm: arbInt(r, 100, 250),
    bodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    disciplines: arbitraryDisciplineMix(r),
    streetMode: r.nextBool() ? null : arbitraryStreetMode(r),
    movementLevels: arbList(r, 0, 3, () => arbitraryMovementLevel(r)),
    goals: arbList(r, 0, 3, () => arbitraryGoal(r)),
    availability: arbList(r, 1, 7, () => arbitraryDaySlot(r)),
    places: arbList(r, 1, 3, () => arbEnum(r, Place.values)),
    equipment: arbList(r, 0, 3, () => arbString(r, 0, 12)),
    equipmentByPlace: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryPlaceEquipment(r)),
    loadIncrements: arbList(r, 0, 3, () => arbitraryLoadIncrement(r)),
    limitations: arbList(r, 0, 3, () => arbitraryLimitation(r)),
    likedExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    dislikedExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    knownExerciseIds: r.nextBool() ? null : arbList(r, 0, 3, () => arbId(r)),
    cannotDoExerciseIds: r.nextBool() ? null : arbList(r, 0, 3, () => arbId(r)),
    experience: r.nextBool() ? null : arbEnum(r, ExperienceLevel.values),
    guidanceMode: arbEnum(r, GuidanceMode.values),
    healthScreening: r.nextBool() ? null : arbitraryHealthScreeningRef(r),
    createdOn: arbDate(r),
    updatedOn: arbDate(r),
    trainingAge: r.nextBool() ? null : arbEnum(r, TrainingAge.values),
    trainingGap: r.nextBool() ? null : arbEnum(r, TrainingGap.values),
    sleep: r.nextBool() ? null : arbEnum(r, SleepBand.values),
    stress: r.nextBool() ? null : arbEnum(r, StressBand.values),
    occupationalLoad: r.nextBool() ? null : arbEnum(r, OccupationalLoad.values),
    otherSports: r.nextBool()
        ? null
        : arbList(r, 0, 6, () => arbitraryOtherSport(r)),
    bodyWeightGoal: r.nextBool() ? null : arbEnum(r, BodyWeightGoal.values),
    benchmarks: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryBenchmark(r)),
    events: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitrarySeasonEvent(r)),
    skills: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitrarySkillState(r)),
    weakPoints: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryWeakPoint(r)),
    specialization: r.nextBool() ? null : arbitrarySpecialization(r),
    recentTraining: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryRecentTraining(r)),
    currentPhase: r.nextBool() ? null : arbEnum(r, CurrentPhase.values),
    emphasis: r.nextBool() ? null : arbEnum(r, TrainingEmphasis.values),
    enduranceBase: r.nextBool() ? null : arbitraryEnduranceBase(r),
    targetBodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    lifestyleUpdatedOn: r.nextBool() ? null : arbDate(r),
  );
}

/// Valeur aléatoire de [PainReport].
PainReport arbitraryPainReport(Random r) {
  return PainReport(
    zone: arbEnum(r, BodyZone.values),
    side: arbEnum(r, BodySide.values),
    joint: r.nextBool() ? null : arbEnum(r, Joint.values),
    intensity: arbInt(r, 0, 10),
    phase: arbEnum(r, PainPhase.values),
    exerciseId: r.nextBool() ? null : arbId(r),
  );
}

/// Valeur aléatoire de [HealthCheck].
HealthCheck arbitraryHealthCheck(Random r) {
  return HealthCheck(
    overall: r.nextBool() ? null : arbInt(r, 1, 5),
    sleepQuality: r.nextBool() ? null : arbInt(r, 1, 5),
    sleepHours: r.nextBool() ? null : arbDouble(r, 0.0, 24.0),
    energy: r.nextBool() ? null : arbInt(r, 1, 5),
    mood: r.nextBool() ? null : arbInt(r, 1, 5),
    soreness: r.nextBool() ? null : arbInt(r, 1, 5),
    stress: r.nextBool() ? null : arbInt(r, 1, 5),
    motivation: r.nextBool() ? null : arbInt(r, 1, 5),
    nutrition: r.nextBool() ? null : arbInt(r, 1, 5),
    hydration: r.nextBool() ? null : arbInt(r, 1, 5),
    minutesAvailable: r.nextBool() ? null : arbInt(r, 0, 600),
    pains: r.nextBool() ? null : arbList(r, 0, 3, () => arbitraryPainReport(r)),
  );
}

/// Valeur aléatoire de [SetTarget].
SetTarget arbitrarySetTarget(Random r) {
  return SetTarget(
    repsLow: r.nextBool() ? null : arbInt(r, 0, 1000),
    repsHigh: r.nextBool() ? null : arbInt(r, 0, 1000),
    secondsLow: r.nextBool() ? null : arbInt(r, 0, 86400),
    secondsHigh: r.nextBool() ? null : arbInt(r, 0, 86400),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    calories: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    loadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    flames: r.nextBool() ? null : arbInt(r, 1, 10),
    role: r.nextBool() ? null : arbEnum(r, SetRole.values),
    percentOfOneRm: r.nextBool() ? null : arbDouble(r, 0.0, 1.5),
    restSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
  );
}

/// Valeur aléatoire de [SetRecord].
SetRecord arbitrarySetRecord(Random r) {
  return SetRecord(
    exerciseId: arbId(r),
    exerciseOrder: arbInt(r, 0, 1000),
    setIndex: arbInt(r, 0, 1000),
    kind: arbEnum(r, SetKind.values),
    externalLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    reps: r.nextBool() ? null : arbInt(r, 0, 1000),
    seconds: r.nextBool() ? null : arbInt(r, 0, 86400),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    calories: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    flames: r.nextBool() ? null : arbInt(r, 1, 10),
    success: r.nextBool(),
    excluded: r.nextBool(),
    slotId: r.nextBool() ? null : arbString(r, 0, 12),
    side: r.nextBool() ? null : arbEnum(r, BodySide.values),
    target: r.nextBool() ? null : arbitrarySetTarget(r),
    technique: r.nextBool() ? null : arbEnum(r, SetTechniqueKind.values),
    role: r.nextBool() ? null : arbEnum(r, SetRole.values),
    parts: r.nextBool() ? null : arbList(r, 1, 4, () => arbitrarySetPart(r)),
    restBeforeSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
    elapsedSeconds: r.nextBool() ? null : arbInt(r, 0, 86400),
    rounds: r.nextBool() ? null : arbInt(r, 0, 1000),
    quality: r.nextBool() ? null : arbInt(r, 1, 5),
    attemptIndex: r.nextBool() ? null : arbInt(r, 0, 3),
  );
}

/// Valeur aléatoire de [TrainingBreak].
TrainingBreak arbitraryTrainingBreak(Random r) {
  return TrainingBreak(
    startDate: arbDate(r),
    endDate: r.nextBool() ? null : arbDate(r),
    reason: arbEnum(r, BreakReason.values),
  );
}

/// Valeur aléatoire de [ProgramRef].
ProgramRef arbitraryProgramRef(Random r) {
  return ProgramRef(
    blockId: arbString(r, 1, 12),
    weekIndex: arbInt(r, 0, 1000),
    dayIndex: arbInt(r, 0, 1000),
  );
}

/// Valeur aléatoire de [SessionRecord].
SessionRecord arbitrarySessionRecord(Random r) {
  return SessionRecord(
    id: arbString(r, 1, 12),
    date: arbDate(r),
    origin: arbEnum(r, SessionOrigin.values),
    programRef: r.nextBool() ? null : arbitraryProgramRef(r),
    resume: r.nextBool(),
    completed: r.nextBool(),
    durationMinutes: r.nextBool() ? null : arbInt(r, 0, 600),
    bodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    place: r.nextBool() ? null : arbEnum(r, Place.values),
    healthCheck: r.nextBool() ? null : arbitraryHealthCheck(r),
    sets: arbList(r, 0, 3, () => arbitrarySetRecord(r)),
    pains: arbList(r, 0, 3, () => arbitraryPainReport(r)),
    plannedWorkSets: r.nextBool() ? null : arbInt(r, 0, 500),
    eventId: r.nextBool() ? null : arbString(r, 1, 12),
    groupResults: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryGroupResult(r)),
  );
}

/// Valeur aléatoire de [TrainingLog].
TrainingLog arbitraryTrainingLog(Random r) {
  return TrainingLog(
    schemaVersion: TrainingLog.currentSchemaVersion,
    sessions: arbList(r, 0, 3, () => arbitrarySessionRecord(r)),
    breaks: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryTrainingBreak(r)),
  );
}

/// Valeur aléatoire de [PlanLock].
PlanLock arbitraryPlanLock(Random r) {
  return PlanLock(
    kind: arbEnum(r, LockKind.values),
    dayIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    slotId: r.nextBool() ? null : arbString(r, 0, 12),
    exerciseId: r.nextBool() ? null : arbId(r),
  );
}

/// Valeur aléatoire de [PlanSlot].
PlanSlot arbitraryPlanSlot(Random r) {
  return PlanSlot(
    slotId: arbString(r, 1, 12),
    exerciseId: arbId(r),
    role: arbEnum(r, SlotRole.values),
    locked: r.nextBool(),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [PlanDay].
PlanDay arbitraryPlanDay(Random r) {
  return PlanDay(
    dayIndex: arbInt(r, 0, 1000),
    weekday: arbInt(r, 1, 7),
    minutesBudget: arbInt(r, 0, 300),
    focus: arbString(r, 0, 12),
    slots: arbList(r, 0, 3, () => arbitraryPlanSlot(r)),
  );
}

/// Valeur aléatoire de [ScoreComponent].
ScoreComponent arbitraryScoreComponent(Random r) {
  return ScoreComponent(
    code: arbString(r, 1, 12),
    value: arbDouble(r, 0.0, 1.0),
    weight: arbDouble(r, 0.0, 2000.0),
  );
}

/// Valeur aléatoire de [PlanScore].
PlanScore arbitraryPlanScore(Random r) {
  return PlanScore(
    total: arbDouble(r, 0.0, 1.0),
    components: arbList(r, 0, 3, () => arbitraryScoreComponent(r)),
  );
}

/// Valeur aléatoire de [Pass1Plan].
Pass1Plan arbitraryPass1Plan(Random r) {
  return Pass1Plan(
    schemaVersion: Pass1Plan.currentSchemaVersion,
    blockId: arbString(r, 1, 12),
    blockIndex: arbInt(r, 0, 1000),
    weeks: arbInt(r, 1, 52),
    startDate: arbDate(r),
    seed: arbInt(r, 0, 1000),
    engineVersion: arbString(r, 0, 12),
    days: arbList(r, 0, 3, () => arbitraryPlanDay(r)),
    score: arbitraryPlanScore(r),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    intent: r.nextBool() ? null : arbitraryBlockIntent(r),
    skillLadders: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitrarySkillLadder(r)),
  );
}

/// Valeur aléatoire de [ReviewAction].
ReviewAction arbitraryReviewAction(Random r) {
  return ReviewAction(
    kind: arbEnum(r, ReviewKind.values),
    slotId: r.nextBool() ? null : arbString(r, 0, 12),
    dayIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    exerciseId: r.nextBool() ? null : arbId(r),
    replacementExerciseId: r.nextBool() ? null : arbId(r),
  );
}

/// Valeur aléatoire de [ProfileDelta].
ProfileDelta arbitraryProfileDelta(Random r) {
  return ProfileDelta(
    knownExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    unknownExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    likedExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    dislikedExerciseIds: arbList(r, 0, 3, () => arbId(r)),
  );
}

/// Valeur aléatoire de [PlanChange].
PlanChange arbitraryPlanChange(Random r) {
  return PlanChange(
    kind: arbEnum(r, ChangeKind.values),
    dayIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    weekIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    slotId: r.nextBool() ? null : arbString(r, 0, 12),
    fromExerciseId: r.nextBool() ? null : arbId(r),
    toExerciseId: r.nextBool() ? null : arbId(r),
    fromDayIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    fromPrescription: r.nextBool() ? null : arbitraryExercisePrescription(r),
    toPrescription: r.nextBool() ? null : arbitraryExercisePrescription(r),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [PlanDiff].
PlanDiff arbitraryPlanDiff(Random r) {
  return PlanDiff(changes: arbList(r, 0, 3, () => arbitraryPlanChange(r)));
}

/// Valeur aléatoire de [ReviewResult].
ReviewResult arbitraryReviewResult(Random r) {
  return ReviewResult(
    plan: arbitraryPass1Plan(r),
    diff: arbitraryPlanDiff(r),
    locks: arbList(r, 0, 3, () => arbitraryPlanLock(r)),
    profileDelta: arbitraryProfileDelta(r),
  );
}

/// Valeur aléatoire de [Variant].
Variant arbitraryVariant(Random r) {
  return Variant(
    exerciseId: arbId(r),
    kind: arbEnum(r, VariantKind.values),
    similarity: arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [VariantSet].
VariantSet arbitraryVariantSet(Random r) {
  return VariantSet(
    slotId: arbString(r, 1, 12),
    targeted: arbList(r, 0, 3, () => arbitraryVariant(r)),
    all: arbList(r, 0, 3, () => arbitraryVariant(r)),
  );
}

/// Valeur aléatoire de [ExercisePrescription].
ExercisePrescription arbitraryExercisePrescription(Random r) {
  return ExercisePrescription(
    slotId: arbString(r, 1, 12),
    exerciseId: arbId(r),
    sets: arbInt(r, 1, 20),
    repsLow: r.nextBool() ? null : arbInt(r, 1, 1000),
    repsHigh: r.nextBool() ? null : arbInt(r, 1, 1000),
    secondsLow: r.nextBool() ? null : arbInt(r, 1, 86400),
    secondsHigh: r.nextBool() ? null : arbInt(r, 1, 86400),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    calories: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    targetFlames: r.nextBool() ? null : arbInt(r, 1, 10),
    restSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
    startLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    percentOfOneRm: r.nextBool() ? null : arbDouble(r, 0.0, 1.5),
    toCalibrate: r.nextBool(),
    loadBasis: arbEnum(r, LoadBasis.values),
    setTargets: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitrarySetTarget(r)),
    groupId: r.nextBool() ? null : arbString(r, 0, 12),
    format: r.nextBool() ? null : arbString(r, 0, 12),
    kind: r.nextBool() ? null : arbEnum(r, SetKind.values),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    technique: r.nextBool() ? null : arbitrarySetTechnique(r),
    tempo: r.nextBool() ? null : arbitraryTempo(r),
    intensity: r.nextBool() ? null : arbitraryIntensityTarget(r),
    autoregulation: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryAutoregulationRule(r)),
    test: r.nextBool() ? null : arbitraryTestSpec(r),
    dayStress: r.nextBool() ? null : arbEnum(r, DayStress.values),
    skillTargetId: r.nextBool() ? null : arbId(r),
    unbroken: r.nextBool() ? null : r.nextBool(),
    restMode: r.nextBool() ? null : arbEnum(r, RestMode.values),
  );
}

/// Valeur aléatoire de [DayPrescription].
DayPrescription arbitraryDayPrescription(Random r) {
  return DayPrescription(
    dayIndex: arbInt(r, 0, 1000),
    items: arbList(r, 0, 3, () => arbitraryExercisePrescription(r)),
    stress: r.nextBool() ? null : arbEnum(r, DayStress.values),
    groups: r.nextBool() ? null : arbList(r, 0, 4, () => arbitraryGroupSpec(r)),
  );
}

/// Valeur aléatoire de [WeekPrescription].
WeekPrescription arbitraryWeekPrescription(Random r) {
  return WeekPrescription(
    weekIndex: arbInt(r, 0, 1000),
    kind: arbEnum(r, WeekKind.values),
    days: arbList(r, 0, 3, () => arbitraryDayPrescription(r)),
    intent: r.nextBool() ? null : arbEnum(r, WeekIntent.values),
  );
}

/// Valeur aléatoire de [Pass2Plan].
Pass2Plan arbitraryPass2Plan(Random r) {
  return Pass2Plan(
    schemaVersion: Pass2Plan.currentSchemaVersion,
    blockId: arbString(r, 1, 12),
    engineVersion: arbString(r, 0, 12),
    weeks: arbList(r, 0, 3, () => arbitraryWeekPrescription(r)),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [ProgramBlock].
ProgramBlock arbitraryProgramBlock(Random r) {
  return ProgramBlock(
    schemaVersion: ProgramBlock.currentSchemaVersion,
    pass1: arbitraryPass1Plan(r),
    pass2: arbitraryPass2Plan(r),
  );
}

/// Valeur aléatoire de [ExerciseEstimate].
ExerciseEstimate arbitraryExerciseEstimate(Random r) {
  return ExerciseEstimate(
    exerciseId: arbId(r),
    unit: arbEnum(r, CapacityUnit.values),
    capacity: arbDouble(r, 0.0, 2000.0),
    standardError: arbDouble(r, 0.0, 2000.0),
    weeklyTrend: arbDouble(r, -1000.0, 1000.0),
    observations: arbInt(r, 0, 1000),
    lastObservedOn: r.nextBool() ? null : arbDate(r),
  );
}

/// Valeur aléatoire de [FatigueState].
FatigueState arbitraryFatigueState(Random r) {
  return FatigueState(
    fitness: arbDouble(r, 0.0, 2000.0),
    fatigue: arbDouble(r, 0.0, 2000.0),
    readiness: arbDouble(r, 0.0, 1.0),
  );
}

/// Valeur aléatoire de [PainTrend].
PainTrend arbitraryPainTrend(Random r) {
  return PainTrend(
    zone: arbEnum(r, BodyZone.values),
    side: arbEnum(r, BodySide.values),
    sessionsReported: arbInt(r, 0, 1000),
    lastIntensity: arbInt(r, 0, 10),
    consecutiveAboveThreshold: arbInt(r, 0, 1000),
  );
}

/// Valeur aléatoire de [AdaptationSummary].
AdaptationSummary arbitraryAdaptationSummary(Random r) {
  return AdaptationSummary(
    schemaVersion: AdaptationSummary.currentSchemaVersion,
    asOf: arbDate(r),
    weeksObserved: arbInt(r, 0, 1000),
    sessionsPlanned: arbInt(r, 0, 1000),
    sessionsCompleted: arbInt(r, 0, 1000),
    unlockLevel: arbEnum(r, UnlockLevel.values),
    confidence: arbDouble(r, 0.0, 1.0),
    estimates: arbList(r, 0, 3, () => arbitraryExerciseEstimate(r)),
    fatigue: r.nextBool() ? null : arbitraryFatigueState(r),
    pains: arbList(r, 0, 3, () => arbitraryPainTrend(r)),
    avoidedExerciseIds: arbList(r, 0, 3, () => arbId(r)),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    benchmarks: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryBenchmark(r)),
    skills: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitrarySkillProgress(r)),
    volumeTolerance: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryVolumeTolerance(r)),
  );
}

/// Valeur aléatoire de [AdaptInput].
AdaptInput arbitraryAdaptInput(Random r) {
  return AdaptInput(
    schemaVersion: AdaptInput.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    block: arbitraryProgramBlock(r),
    log: arbitraryTrainingLog(r),
    today: arbDate(r),
    state: r.nextBool() ? null : arbJson(r),
    decisions: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryProposalDecision(r)),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [SessionRequest].
SessionRequest arbitrarySessionRequest(Random r) {
  return SessionRequest(
    schemaVersion: SessionRequest.currentSchemaVersion,
    input: arbitraryAdaptInput(r),
    weekIndex: arbInt(r, 0, 1000),
    dayIndex: arbInt(r, 0, 1000),
    healthCheck: r.nextBool() ? null : arbitraryHealthCheck(r),
    place: r.nextBool() ? null : arbEnum(r, Place.values),
  );
}

/// Valeur aléatoire de [AdviceRequest].
AdviceRequest arbitraryAdviceRequest(Random r) {
  return AdviceRequest(
    schemaVersion: AdviceRequest.currentSchemaVersion,
    input: arbitraryAdaptInput(r),
    session: arbitrarySessionPlan(r),
    done: arbList(r, 0, 3, () => arbitrarySetRecord(r)),
    slotId: arbString(r, 1, 12),
    healthCheck: r.nextBool() ? null : arbitraryHealthCheck(r),
  );
}

/// Valeur aléatoire de [ProposalDecision].
ProposalDecision arbitraryProposalDecision(Random r) {
  return ProposalDecision(
    proposalId: arbString(r, 1, 12),
    date: arbDate(r),
    status: arbEnum(r, ProposalStatus.values),
  );
}

/// Valeur aléatoire de [PersonalRecord].
PersonalRecord arbitraryPersonalRecord(Random r) {
  return PersonalRecord(
    exerciseId: arbId(r),
    kind: arbEnum(r, RecordKind.values),
    value: arbDouble(r, 0.0, 2000.0),
    date: arbDate(r),
    sessionId: r.nextBool() ? null : arbString(r, 0, 12),
    previousValue: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
  );
}

/// Valeur aléatoire de [SessionAdjustment].
SessionAdjustment arbitrarySessionAdjustment(Random r) {
  return SessionAdjustment(
    kind: arbEnum(r, AdjustmentKind.values),
    exerciseId: r.nextBool() ? null : arbId(r),
    replacementExerciseId: r.nextBool() ? null : arbId(r),
    loadFactor: r.nextBool() ? null : arbDouble(r, 0.0, 2.0),
    setsDelta: r.nextBool() ? null : arbInt(r, -20, 20),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [SessionPlan].
SessionPlan arbitrarySessionPlan(Random r) {
  return SessionPlan(
    schemaVersion: SessionPlan.currentSchemaVersion,
    date: arbDate(r),
    blockId: arbString(r, 1, 12),
    weekIndex: arbInt(r, 0, 1000),
    dayIndex: arbInt(r, 0, 1000),
    items: arbList(r, 0, 3, () => arbitraryExercisePrescription(r)),
    adjustments: arbList(r, 0, 3, () => arbitrarySessionAdjustment(r)),
    confidence: arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    phase: r.nextBool() ? null : arbEnum(r, SeasonPhaseKind.values),
    weekIntent: r.nextBool() ? null : arbEnum(r, WeekIntent.values),
    eventId: r.nextBool() ? null : arbString(r, 1, 12),
    groups: r.nextBool() ? null : arbList(r, 0, 4, () => arbitraryGroupSpec(r)),
  );
}

/// Valeur aléatoire de [IntraSessionAdvice].
IntraSessionAdvice arbitraryIntraSessionAdvice(Random r) {
  return IntraSessionAdvice(
    exerciseId: arbId(r),
    action: arbEnum(r, IntraSessionAction.values),
    nextLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    nextRepsLow: r.nextBool() ? null : arbInt(r, 0, 1000),
    nextRepsHigh: r.nextBool() ? null : arbInt(r, 0, 1000),
    nextSeconds: r.nextBool() ? null : arbInt(r, 0, 86400),
    slotId: r.nextBool() ? null : arbString(r, 0, 12),
    restSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
    confidence: arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    miniSetsLeft: r.nextBool() ? null : arbInt(r, 0, 50),
    stepExerciseId: r.nextBool() ? null : arbId(r),
  );
}

/// Valeur aléatoire de [Proposal].
Proposal arbitraryProposal(Random r) {
  return Proposal(
    id: arbString(r, 1, 12),
    kind: arbEnum(r, ProposalKind.values),
    scope: arbEnum(r, ProposalScope.values),
    createdOn: arbDate(r),
    confidence: arbDouble(r, 0.0, 1.0),
    unlockLevel: arbEnum(r, UnlockLevel.values),
    autoApplicable: r.nextBool(),
    exerciseId: r.nextBool() ? null : arbId(r),
    diff: r.nextBool() ? null : arbitraryPlanDiff(r),
    block: r.nextBool() ? null : arbitraryProgramBlock(r),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    detail: r.nextBool() ? null : arbEnum(r, ProposalDetail.values),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [EngineLogEntry].
EngineLogEntry arbitraryEngineLogEntry(Random r) {
  return EngineLogEntry(
    sequence: arbInt(r, 0, 1000),
    date: arbDate(r),
    engine: arbString(r, 1, 12),
    event: arbString(r, 1, 12),
    confidence: r.nextBool() ? null : arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    data: arbJson(r),
  );
}

/// Valeur aléatoire de [AdaptReview].
AdaptReview arbitraryAdaptReview(Random r) {
  return AdaptReview(
    summary: arbitraryAdaptationSummary(r),
    proposals: arbList(r, 0, 3, () => arbitraryProposal(r)),
    state: arbJson(r),
    log: arbList(r, 0, 3, () => arbitraryEngineLogEntry(r)),
    records: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryPersonalRecord(r)),
    testResults: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryBenchmark(r)),
    skillStates: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitrarySkillState(r)),
  );
}

/// Valeur aléatoire de [XpEntry].
XpEntry arbitraryXpEntry(Random r) {
  return XpEntry(
    sequence: arbInt(r, 0, 1000),
    date: arbDate(r),
    source: arbEnum(r, XpSource.values),
    amount: arbInt(r, 0, 1000),
    sessionId: r.nextBool() ? null : arbString(r, 0, 12),
    refId: r.nextBool() ? null : arbString(r, 0, 12),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [KreditEntry].
KreditEntry arbitraryKreditEntry(Random r) {
  return KreditEntry(
    sequence: arbInt(r, 0, 1000),
    date: arbDate(r),
    source: arbEnum(r, KreditSource.values),
    amount: arbInt(r, 0, 1000),
    refId: r.nextBool() ? null : arbString(r, 0, 12),
  );
}

/// Valeur aléatoire de [LevelState].
LevelState arbitraryLevelState(Random r) {
  return LevelState(
    level: arbInt(r, 1, 100),
    prestige: arbInt(r, 0, 1000),
    totalXp: arbInt(r, 0, 1000),
    xpIntoLevel: arbInt(r, 0, 1000),
    xpForNextLevel: arbInt(r, 0, 1000),
  );
}

/// Valeur aléatoire de [AttributeScore].
AttributeScore arbitraryAttributeScore(Random r) {
  return AttributeScore(
    attribute: arbEnum(r, AthleteAttribute.values),
    value: arbDouble(r, 0.0, 100.0),
    best: r.nextBool() ? null : arbDouble(r, 0.0, 100.0),
  );
}

/// Valeur aléatoire de [MovementRank].
MovementRank arbitraryMovementRank(Random r) {
  return MovementRank(
    exerciseId: arbId(r),
    tier: arbEnum(r, MovementRankTier.values),
    score: arbDouble(r, 0.0, 2000.0),
    nextTierAt: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
  );
}

/// Valeur aléatoire de [Quest].
Quest arbitraryQuest(Random r) {
  return Quest(
    id: arbString(r, 1, 12),
    kind: arbEnum(r, QuestKind.values),
    template: arbString(r, 1, 12),
    params: arbJson(r),
    startsOn: arbDate(r),
    endsOn: r.nextBool() ? null : arbDate(r),
    progress: arbDouble(r, 0.0, 2000.0),
    target: arbDouble(r, 0.0, 2000.0),
    status: arbEnum(r, QuestStatus.values),
    rewardXp: arbInt(r, 0, 1000),
    rewardKredits: arbInt(r, 0, 1000),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [Milestone].
Milestone arbitraryMilestone(Random r) {
  return Milestone(
    fraction: arbDouble(r, 0.0, 1.0),
    reachedOn: r.nextBool() ? null : arbDate(r),
  );
}

/// Valeur aléatoire de [Prediction].
Prediction arbitraryPrediction(Random r) {
  return Prediction(
    expectedOn: arbDate(r),
    earliestOn: arbDate(r),
    latestOn: arbDate(r),
    confidence: arbDouble(r, 0.0, 1.0),
    method: arbString(r, 1, 12),
  );
}

/// Valeur aléatoire de [GoalProgress].
GoalProgress arbitraryGoalProgress(Random r) {
  return GoalProgress(
    goalId: arbString(r, 1, 12),
    current: arbDouble(r, -1000.0, 1000.0),
    target: arbDouble(r, -1000.0, 1000.0),
    fraction: arbDouble(r, 0.0, 1.0),
    achievedOn: r.nextBool() ? null : arbDate(r),
    milestones: arbList(r, 0, 3, () => arbitraryMilestone(r)),
    prediction: r.nextBool() ? null : arbitraryPrediction(r),
    baseline: r.nextBool() ? null : arbDouble(r, -1000.0, 1000.0),
    overdue: r.nextBool() ? null : r.nextBool(),
    suggestedDate: r.nextBool() ? null : arbDate(r),
    suggestedTarget: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    reasons: r.nextBool() ? null : arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [DelightEvent].
DelightEvent arbitraryDelightEvent(Random r) {
  return DelightEvent(
    kind: arbEnum(r, DelightKind.values),
    date: arbDate(r),
    sessionId: r.nextBool() ? null : arbString(r, 0, 12),
    exerciseId: r.nextBool() ? null : arbId(r),
    recordKind: r.nextBool() ? null : arbEnum(r, RecordKind.values),
    value: r.nextBool() ? null : arbDouble(r, -1000.0, 1000.0),
    previousValue: r.nextBool() ? null : arbDouble(r, -1000.0, 1000.0),
    grade: r.nextBool() ? null : arbEnum(r, SessionGrade.values),
    combo: r.nextBool() ? null : arbInt(r, 0, 1000),
    streakWeeks: r.nextBool() ? null : arbInt(r, 0, 1000),
    kredits: r.nextBool() ? null : arbInt(r, 0, 1000),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [QuestState].
QuestState arbitraryQuestState(Random r) {
  return QuestState(
    schemaVersion: QuestState.currentSchemaVersion,
    xp: arbList(r, 0, 3, () => arbitraryXpEntry(r)),
    kredits: arbList(r, 0, 3, () => arbitraryKreditEntry(r)),
    quests: arbList(r, 0, 3, () => arbitraryQuest(r)),
    lastEvaluatedOn: r.nextBool() ? null : arbDate(r),
    data: arbJson(r),
  );
}

/// Valeur aléatoire de [QuestClaim].
QuestClaim arbitraryQuestClaim(Random r) {
  return QuestClaim(questId: arbString(r, 1, 12), date: arbDate(r));
}

/// Valeur aléatoire de [QuestInput].
QuestInput arbitraryQuestInput(Random r) {
  return QuestInput(
    schemaVersion: QuestInput.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    log: arbitraryTrainingLog(r),
    block: r.nextBool() ? null : arbitraryProgramBlock(r),
    adaptation: r.nextBool() ? null : arbitraryAdaptationSummary(r),
    state: arbitraryQuestState(r),
    today: arbDate(r),
    seed: r.nextBool() ? null : arbInt(r, 0, 1000),
    claims: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryQuestClaim(r)),
  );
}

/// Valeur aléatoire de [QuestOutcome].
QuestOutcome arbitraryQuestOutcome(Random r) {
  return QuestOutcome(
    state: arbitraryQuestState(r),
    level: arbitraryLevelState(r),
    attributes: arbList(r, 0, 3, () => arbitraryAttributeScore(r)),
    ranks: arbList(r, 0, 3, () => arbitraryMovementRank(r)),
    goals: arbList(r, 0, 3, () => arbitraryGoalProgress(r)),
    events: arbList(r, 0, 3, () => arbitraryDelightEvent(r)),
    kreditBalance: arbInt(r, 0, 1000),
    weekStreak: r.nextBool() ? null : arbInt(r, 0, 1000),
    suggestedGoals: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryGoal(r)),
    records: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryPersonalRecord(r)),
    extras: r.nextBool() ? null : arbJson(r),
  );
}

/// Valeur aléatoire de [PlanRequest].
PlanRequest arbitraryPlanRequest(Random r) {
  return PlanRequest(
    schemaVersion: PlanRequest.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    seed: arbInt(r, 0, 1000),
    startDate: arbDate(r),
    blockWeeks: r.nextBool() ? null : arbInt(r, 4, 6),
    locks: arbList(r, 0, 3, () => arbitraryPlanLock(r)),
    previousBlock: r.nextBool() ? null : arbitraryProgramBlock(r),
    adaptation: r.nextBool() ? null : arbitraryAdaptationSummary(r),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [NextBlockRequest].
NextBlockRequest arbitraryNextBlockRequest(Random r) {
  return NextBlockRequest(
    schemaVersion: NextBlockRequest.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    seed: arbInt(r, 0, 1000),
    startDate: arbDate(r),
    previous: arbitraryProgramBlock(r),
    adaptation: arbitraryAdaptationSummary(r),
    locks: arbList(r, 0, 3, () => arbitraryPlanLock(r)),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [RestructureRequest].
RestructureRequest arbitraryRestructureRequest(Random r) {
  return RestructureRequest(
    schemaVersion: RestructureRequest.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    seed: arbInt(r, 0, 1000),
    today: arbDate(r),
    current: arbitraryProgramBlock(r),
    scope: arbEnum(r, RestructureScope.values),
    dayIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    fromWeekIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    locks: arbList(r, 0, 3, () => arbitraryPlanLock(r)),
    adaptation: r.nextBool() ? null : arbitraryAdaptationSummary(r),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [ReviewRequest].
ReviewRequest arbitraryReviewRequest(Random r) {
  return ReviewRequest(
    schemaVersion: ReviewRequest.currentSchemaVersion,
    request: arbitraryPlanRequest(r),
    current: arbitraryPass1Plan(r),
    action: arbitraryReviewAction(r),
  );
}

/// Valeur aléatoire de [VariantsRequest].
VariantsRequest arbitraryVariantsRequest(Random r) {
  return VariantsRequest(
    schemaVersion: VariantsRequest.currentSchemaVersion,
    request: arbitraryPlanRequest(r),
    current: arbitraryPass1Plan(r),
    slotId: arbString(r, 1, 12),
  );
}

/// Valeur aléatoire de [Pass2Request].
Pass2Request arbitraryPass2Request(Random r) {
  return Pass2Request(
    schemaVersion: Pass2Request.currentSchemaVersion,
    request: arbitraryPlanRequest(r),
    pass1: arbitraryPass1Plan(r),
  );
}

/// Valeur aléatoire de [BlockProposal].
BlockProposal arbitraryBlockProposal(Random r) {
  return BlockProposal(
    block: arbitraryProgramBlock(r),
    diff: arbitraryPlanDiff(r),
    season: r.nextBool() ? null : arbitrarySeasonPlan(r),
  );
}

/// Valeur aléatoire de [OtherSport].
OtherSport arbitraryOtherSport(Random r) {
  return OtherSport(
    kind: arbEnum(r, OtherSportKind.values),
    sessionsPerWeek: arbInt(r, 1, 14),
    minutesPerSession: arbInt(r, 10, 600),
    weekdays: r.nextBool() ? null : arbList(r, 0, 7, () => arbInt(r, 0, 1000)),
    regions: r.nextBool()
        ? null
        : arbList(r, 0, 5, () => arbEnum(r, BodyRegion.values)),
    hard: r.nextBool() ? null : r.nextBool(),
    mainSport: r.nextBool() ? null : r.nextBool(),
  );
}

/// Valeur aléatoire de [RecentTraining].
RecentTraining arbitraryRecentTraining(Random r) {
  return RecentTraining(
    exerciseId: arbId(r),
    sessionsPerWeek: arbInt(r, 0, 14),
    hardSets: r.nextBool() ? null : arbEnum(r, HardSetsBand.values),
  );
}

/// Valeur aléatoire de [EnduranceBase].
EnduranceBase arbitraryEnduranceBase(Random r) {
  return EnduranceBase(
    weeklyVolume: arbEnum(r, RunVolumeBand.values),
    sessionsPerWeek: arbInt(r, 0, 14),
    longRun: r.nextBool() ? null : arbEnum(r, LongRunBand.values),
  );
}

/// Valeur aléatoire de [Benchmark].
Benchmark arbitraryBenchmark(Random r) {
  return Benchmark(
    exerciseId: arbId(r),
    kind: arbEnum(r, BenchmarkKind.values),
    source: arbEnum(r, BenchmarkSource.values),
    date: r.nextBool() ? null : arbDate(r),
    externalLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    reps: r.nextBool() ? null : arbInt(r, 1, 1000),
    rir: r.nextBool() ? null : arbDouble(r, 0.0, 10.0),
    seconds: r.nextBool() ? null : arbInt(r, 1, 86400),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 1.0, 2001.0),
    bodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    protocolId: r.nextBool() ? null : arbString(r, 1, 40),
    competitionStandard: r.nextBool() ? null : r.nextBool(),
  );
}

/// Valeur aléatoire de [WeakPoint].
WeakPoint arbitraryWeakPoint(Random r) {
  return WeakPoint(
    exerciseId: arbId(r),
    kind: arbEnum(r, WeakPointKind.values),
  );
}

/// Valeur aléatoire de [CompetitionLift].
CompetitionLift arbitraryCompetitionLift(Random r) {
  return CompetitionLift(
    exerciseId: arbId(r),
    attempts: arbInt(r, 1, 4),
    minIncrementKg: r.nextBool() ? null : arbDouble(r, 0.25, 10.0),
    bestKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    targetKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
  );
}

/// Valeur aléatoire de [EventStation].
EventStation arbitraryEventStation(Random r) {
  return EventStation(
    exerciseId: arbId(r),
    reps: r.nextBool() ? null : arbInt(r, 1, 1000),
    seconds: r.nextBool() ? null : arbInt(r, 1, 3600),
    externalLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    unbroken: r.nextBool() ? null : r.nextBool(),
    timeLimitSeconds: r.nextBool() ? null : arbInt(r, 1, 14400),
    restAfterSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
  );
}

/// Valeur aléatoire de [SeasonEvent].
SeasonEvent arbitrarySeasonEvent(Random r) {
  return SeasonEvent(
    id: arbString(r, 1, 12),
    kind: arbEnum(r, EventKind.values),
    priority: arbEnum(r, EventPriority.values),
    date: arbDate(r),
    name: r.nextBool() ? null : arbString(r, 0, 60),
    ruleset: r.nextBool() ? null : arbString(r, 1, 40),
    weightClassKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    openWeightClass: r.nextBool() ? null : r.nextBool(),
    lifts: r.nextBool()
        ? null
        : arbList(r, 1, 6, () => arbitraryCompetitionLift(r)),
    mode: r.nextBool() ? null : arbEnum(r, RepsEventMode.values),
    stations: r.nextBool()
        ? null
        : arbList(r, 1, 4, () => arbitraryEventStation(r)),
    rounds: r.nextBool() ? null : arbInt(r, 1, 50),
    timeLimitSeconds: r.nextBool() ? null : arbInt(r, 10, 14400),
    distanceMeters: r.nextBool() ? null : arbDouble(r, 1.0, 2001.0),
    targetSeconds: r.nextBool() ? null : arbInt(r, 1, 86400),
    goalIds: r.nextBool() ? null : arbList(r, 0, 3, () => arbString(r, 0, 12)),
    dateApproximate: r.nextBool() ? null : r.nextBool(),
    plannedBodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    formatKnown: r.nextBool() ? null : r.nextBool(),
    heats: r.nextBool() ? null : arbInt(r, 1, 20),
    restBetweenHeatsSeconds: r.nextBool() ? null : arbInt(r, 0, 14400),
    elements: r.nextBool() ? null : arbList(r, 0, 4, () => arbId(r)),
    bestSeconds: r.nextBool() ? null : arbInt(r, 1, 86400),
    bestTotalReps: r.nextBool() ? null : arbInt(r, 0, 100000),
    bestDate: r.nextBool() ? null : arbDate(r),
  );
}

/// Valeur aléatoire de [Specialization].
Specialization arbitrarySpecialization(Random r) {
  return Specialization(
    kind: arbEnum(r, SpecializationKind.values),
    exerciseId: r.nextBool() ? null : arbId(r),
    muscle: r.nextBool() ? null : arbString(r, 1, 12),
    pattern: r.nextBool() ? null : arbEnum(r, MovementPattern.values),
    weeks: r.nextBool() ? null : arbInt(r, 2, 26),
    maintenance: r.nextBool() ? null : arbEnum(r, MaintenancePolicy.values),
    startedOn: r.nextBool() ? null : arbDate(r),
  );
}

/// Valeur aléatoire de [SkillState].
SkillState arbitrarySkillState(Random r) {
  return SkillState(
    targetExerciseId: arbId(r),
    currentExerciseId: arbId(r),
    bestHoldSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
    bestReps: r.nextBool() ? null : arbInt(r, 0, 1000),
    assessedOn: r.nextBool() ? null : arbDate(r),
    atStepSince: r.nextBool() ? null : arbEnum(r, StepTenure.values),
  );
}

/// Valeur aléatoire de [StepCriterion].
StepCriterion arbitraryStepCriterion(Random r) {
  return StepCriterion(
    holdSeconds: r.nextBool() ? null : arbInt(r, 1, 600),
    reps: r.nextBool() ? null : arbInt(r, 1, 200),
    sets: arbInt(r, 1, 10),
    minQuality: r.nextBool() ? null : arbInt(r, 1, 5),
    sessions: r.nextBool() ? null : arbInt(r, 1, 20),
    minWeeks: r.nextBool() ? null : arbInt(r, 0, 52),
  );
}

/// Valeur aléatoire de [SkillStep].
SkillStep arbitrarySkillStep(Random r) {
  return SkillStep(exerciseId: arbId(r), criterion: arbitraryStepCriterion(r));
}

/// Valeur aléatoire de [SkillLadder].
SkillLadder arbitrarySkillLadder(Random r) {
  return SkillLadder(
    targetExerciseId: arbId(r),
    steps: arbList(r, 1, 4, () => arbitrarySkillStep(r)),
  );
}

/// Valeur aléatoire de [SkillProgress].
SkillProgress arbitrarySkillProgress(Random r) {
  return SkillProgress(
    targetExerciseId: arbId(r),
    currentExerciseId: arbId(r),
    stepIndex: arbInt(r, 0, 1000),
    weeksAtStep: arbInt(r, 0, 1000),
    criterionMet: r.nextBool(),
    bestHoldSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
    bestReps: r.nextBool() ? null : arbInt(r, 0, 1000),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [PhaseOverride].
PhaseOverride arbitraryPhaseOverride(Random r) {
  return PhaseOverride(
    exerciseId: arbId(r),
    kind: arbEnum(r, SeasonPhaseKind.values),
    volumeFactor: r.nextBool() ? null : arbDouble(r, 0.0, 2.0),
    intensityFactor: r.nextBool() ? null : arbDouble(r, 0.0, 2.0),
  );
}

/// Valeur aléatoire de [SeasonPhase].
SeasonPhase arbitrarySeasonPhase(Random r) {
  return SeasonPhase(
    index: arbInt(r, 0, 1000),
    kind: arbEnum(r, SeasonPhaseKind.values),
    startDate: arbDate(r),
    weeks: arbInt(r, 1, 26),
    eventId: r.nextBool() ? null : arbString(r, 0, 12),
    volumeFactor: r.nextBool() ? null : arbDouble(r, 0.0, 2.0),
    intensityFactor: r.nextBool() ? null : arbDouble(r, 0.0, 2.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
    overrides: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryPhaseOverride(r)),
  );
}

/// Valeur aléatoire de [SeasonPlan].
SeasonPlan arbitrarySeasonPlan(Random r) {
  return SeasonPlan(
    schemaVersion: SeasonPlan.currentSchemaVersion,
    createdOn: arbDate(r),
    engineVersion: arbString(r, 0, 12),
    eventIds: arbList(r, 0, 3, () => arbString(r, 0, 12)),
    phases: arbList(r, 1, 4, () => arbitrarySeasonPhase(r)),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [BlockIntent].
BlockIntent arbitraryBlockIntent(Random r) {
  return BlockIntent(
    phase: arbEnum(r, SeasonPhaseKind.values),
    seasonPhaseIndex: r.nextBool() ? null : arbInt(r, 0, 1000),
    eventId: r.nextBool() ? null : arbString(r, 0, 12),
    weeksToEvent: r.nextBool() ? null : arbInt(r, 0, 104),
    undulation: r.nextBool() ? null : arbEnum(r, UndulationModel.values),
    specialization: r.nextBool() ? null : arbitrarySpecialization(r),
  );
}

/// Valeur aléatoire de [VolumeTolerance].
VolumeTolerance arbitraryVolumeTolerance(Random r) {
  return VolumeTolerance(
    muscle: arbString(r, 1, 12),
    weeklySetsLow: arbDouble(r, 0.0, 80.0),
    weeklySetsHigh: arbDouble(r, 0.0, 80.0),
    confidence: arbDouble(r, 0.0, 1.0),
  );
}

/// Valeur aléatoire de [AttemptResult].
AttemptResult arbitraryAttemptResult(Random r) {
  return AttemptResult(
    exerciseId: arbId(r),
    index: arbInt(r, 0, 3),
    loadKg: arbDouble(r, -300.0, 1000.0),
    success: r.nextBool(),
    failure: r.nextBool() ? null : arbEnum(r, AttemptFailure.values),
  );
}

/// Valeur aléatoire de [AttemptSuggestion].
AttemptSuggestion arbitraryAttemptSuggestion(Random r) {
  return AttemptSuggestion(
    index: arbInt(r, 0, 3),
    loadKg: arbDouble(r, -300.0, 1000.0),
    successProbability: r.nextBool() ? null : arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [WarmupStep].
WarmupStep arbitraryWarmupStep(Random r) {
  return WarmupStep(
    loadKg: arbDouble(r, -300.0, 1000.0),
    reps: arbInt(r, 1, 50),
    restSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
  );
}

/// Valeur aléatoire de [LiftAttempts].
LiftAttempts arbitraryLiftAttempts(Random r) {
  return LiftAttempts(
    exerciseId: arbId(r),
    estimateKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    standardErrorKg: r.nextBool() ? null : arbDouble(r, 0.0, 2000.0),
    attempts: arbList(r, 0, 4, () => arbitraryAttemptSuggestion(r)),
    warmup: r.nextBool()
        ? null
        : arbList(r, 0, 4, () => arbitraryWarmupStep(r)),
  );
}

/// Valeur aléatoire de [PacingSegment].
PacingSegment arbitraryPacingSegment(Random r) {
  return PacingSegment(
    exerciseId: arbId(r),
    setReps: arbList(r, 0, 4, () => arbInt(r, 0, 1000)),
    restSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
    targetSeconds: r.nextBool() ? null : arbInt(r, 1, 14400),
    stationIndex: r.nextBool() ? null : arbInt(r, 0, 39),
    round: r.nextBool() ? null : arbInt(r, 0, 49),
  );
}

/// Valeur aléatoire de [EventDayRequest].
EventDayRequest arbitraryEventDayRequest(Random r) {
  return EventDayRequest(
    schemaVersion: EventDayRequest.currentSchemaVersion,
    input: arbitraryAdaptInput(r),
    eventId: arbString(r, 1, 12),
    bodyWeightKg: r.nextBool() ? null : arbDouble(r, 25.0, 300.0),
    done: arbList(r, 0, 3, () => arbitraryAttemptResult(r)),
    healthCheck: r.nextBool() ? null : arbitraryHealthCheck(r),
    objective: r.nextBool() ? null : arbEnum(r, EventObjective.values),
    targetTotalKg: r.nextBool() ? null : arbDouble(r, 0.0, 5000.0),
  );
}

/// Valeur aléatoire de [EventDayPlan].
EventDayPlan arbitraryEventDayPlan(Random r) {
  return EventDayPlan(
    schemaVersion: EventDayPlan.currentSchemaVersion,
    eventId: arbString(r, 1, 12),
    lifts: arbList(r, 0, 3, () => arbitraryLiftAttempts(r)),
    pacing: r.nextBool()
        ? null
        : arbList(r, 0, 3, () => arbitraryPacingSegment(r)),
    targetTotalReps: r.nextBool() ? null : arbInt(r, 0, 100000),
    targetSeconds: r.nextBool() ? null : arbInt(r, 1, 86400),
    confidence: arbDouble(r, 0.0, 1.0),
    reasons: arbList(r, 0, 3, () => arbitraryReason(r)),
  );
}

/// Valeur aléatoire de [SeasonRequest].
SeasonRequest arbitrarySeasonRequest(Random r) {
  return SeasonRequest(
    schemaVersion: SeasonRequest.currentSchemaVersion,
    profile: arbitraryAthleteProfile(r),
    seed: arbInt(r, 0, 1000),
    today: arbDate(r),
    startDate: arbDate(r),
    previous: r.nextBool() ? null : arbitrarySeasonPlan(r),
    currentBlock: r.nextBool() ? null : arbitraryProgramBlock(r),
    adaptation: r.nextBool() ? null : arbitraryAdaptationSummary(r),
  );
}

/// Valeur aléatoire de [Tempo].
Tempo arbitraryTempo(Random r) {
  return Tempo(
    eccentricSeconds: arbInt(r, 0, 30),
    bottomPauseSeconds: arbInt(r, 0, 30),
    concentricSeconds: arbInt(r, 0, 30),
    topPauseSeconds: arbInt(r, 0, 30),
  );
}

/// Valeur aléatoire de [SetTechnique].
SetTechnique arbitrarySetTechnique(Random r) {
  return SetTechnique(
    kind: arbEnum(r, SetTechniqueKind.values),
    backoffSets: r.nextBool() ? null : arbInt(r, 1, 10),
    backoffDropPct: r.nextBool() ? null : arbDouble(r, 0.0, 0.6),
    backoffRepsLow: r.nextBool() ? null : arbInt(r, 1, 100),
    backoffRepsHigh: r.nextBool() ? null : arbInt(r, 1, 100),
    miniSets: r.nextBool() ? null : arbInt(r, 1, 20),
    miniSetReps: r.nextBool() ? null : arbInt(r, 1, 30),
    intraRestSeconds: r.nextBool() ? null : arbInt(r, 1, 120),
    totalRepsTarget: r.nextBool() ? null : arbInt(r, 1, 1000),
    drops: r.nextBool() ? null : arbInt(r, 1, 6),
    dropPct: r.nextBool() ? null : arbDouble(r, 0.05, 0.6),
    eccentricLoadPct: r.nextBool() ? null : arbDouble(r, 0.0, 1.5),
    eccentricOnly: r.nextBool() ? null : r.nextBool(),
    pairedSlotId: r.nextBool() ? null : arbString(r, 1, 12),
    pairedRestSeconds: r.nextBool() ? null : arbInt(r, 0, 900),
    waves: r.nextBool() ? null : arbInt(r, 1, 6),
    waveReps: r.nextBool() ? null : arbList(r, 1, 8, () => arbInt(r, 0, 1000)),
    waveStepPct: r.nextBool() ? null : arbDouble(r, 0.0, 0.2),
    durationSeconds: r.nextBool() ? null : arbInt(r, 10, 7200),
    intervalSeconds: r.nextBool() ? null : arbInt(r, 10, 900),
    intervals: r.nextBool() ? null : arbInt(r, 1, 120),
    ladderStart: r.nextBool() ? null : arbInt(r, 1, 100),
    ladderStep: r.nextBool() ? null : arbInt(r, 1, 20),
    ladderTop: r.nextBool() ? null : arbInt(r, 1, 100),
    ladderCount: r.nextBool() ? null : arbInt(r, 1, 20),
    pyramidReps: r.nextBool()
        ? null
        : arbList(r, 2, 4, () => arbInt(r, 0, 1000)),
    qualityFloor: r.nextBool() ? null : arbInt(r, 1, 5),
    maxAttempts: r.nextBool() ? null : arbInt(r, 1, 30),
    totalSecondsTarget: r.nextBool() ? null : arbInt(r, 1, 3600),
    lastSetOnly: r.nextBool() ? null : r.nextBool(),
  );
}

/// Valeur aléatoire de [IntensityTarget].
IntensityTarget arbitraryIntensityTarget(Random r) {
  return IntensityTarget(
    basis: arbEnum(r, IntensityBasis.values),
    value: arbDouble(r, 0.0, 15.0),
    valueHigh: r.nextBool() ? null : arbDouble(r, 0.0, 15.0),
    referenceExerciseId: r.nextBool() ? null : arbId(r),
    referenceKind: r.nextBool() ? null : arbEnum(r, BenchmarkKind.values),
    eventId: r.nextBool() ? null : arbString(r, 1, 12),
    rirCap: r.nextBool() ? null : arbDouble(r, 0.0, 10.0),
  );
}

/// Valeur aléatoire de [AutoregulationRule].
AutoregulationRule arbitraryAutoregulationRule(Random r) {
  return AutoregulationRule(
    kind: arbEnum(r, AutoregulationKind.values),
    pct: r.nextBool() ? null : arbDouble(r, 0.0, 1.0),
    rirFloor: r.nextBool() ? null : arbDouble(r, 0.0, 10.0),
    rirCeiling: r.nextBool() ? null : arbDouble(r, 0.0, 10.0),
    minSets: r.nextBool() ? null : arbInt(r, 0, 20),
    maxSets: r.nextBool() ? null : arbInt(r, 1, 30),
    repDrop: r.nextBool() ? null : arbInt(r, 1, 50),
    qualityFloor: r.nextBool() ? null : arbInt(r, 1, 5),
  );
}

/// Valeur aléatoire de [GroupSpec].
GroupSpec arbitraryGroupSpec(Random r) {
  return GroupSpec(
    groupId: arbString(r, 1, 12),
    format: arbEnum(r, GroupFormat.values),
    rounds: r.nextBool() ? null : arbInt(r, 1, 100),
    durationSeconds: r.nextBool() ? null : arbInt(r, 10, 14400),
    timeCapSeconds: r.nextBool() ? null : arbInt(r, 10, 14400),
    intervalSeconds: r.nextBool() ? null : arbInt(r, 5, 3600),
    restBetweenRoundsSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
    targetSeconds: r.nextBool() ? null : arbInt(r, 1, 14400),
    eventId: r.nextBool() ? null : arbString(r, 1, 12),
  );
}

/// Valeur aléatoire de [GroupResult].
GroupResult arbitraryGroupResult(Random r) {
  return GroupResult(
    groupId: arbString(r, 1, 12),
    completed: r.nextBool(),
    elapsedSeconds: r.nextBool() ? null : arbInt(r, 0, 86400),
    rounds: r.nextBool() ? null : arbInt(r, 0, 1000),
    extraReps: r.nextBool() ? null : arbInt(r, 0, 10000),
  );
}

/// Valeur aléatoire de [SetPart].
SetPart arbitrarySetPart(Random r) {
  return SetPart(
    reps: r.nextBool() ? null : arbInt(r, 0, 1000),
    seconds: r.nextBool() ? null : arbInt(r, 0, 86400),
    externalLoadKg: r.nextBool() ? null : arbDouble(r, -300.0, 1000.0),
    restBeforeSeconds: r.nextBool() ? null : arbInt(r, 0, 3600),
  );
}

/// Valeur aléatoire de [TestSpec].
TestSpec arbitraryTestSpec(Random r) {
  return TestSpec(
    kind: arbEnum(r, TestKind.values),
    protocolId: r.nextBool() ? null : arbString(r, 1, 40),
    targetRir: r.nextBool() ? null : arbDouble(r, 0.0, 5.0),
    attempts: r.nextBool() ? null : arbInt(r, 1, 6),
    benchmarkKind: r.nextBool() ? null : arbEnum(r, BenchmarkKind.values),
  );
}

/// Générateur, encodeur et décodeur de chaque type, pour les tests génériques.
final List<ContractCodec<Object>> contractCodecs = <ContractCodec<Object>>[
  ContractCodec<Reason>(
    'Reason',
    arbitraryReason,
    (v) => v.toJson(),
    Reason.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<DisciplineShare>(
    'DisciplineShare',
    arbitraryDisciplineShare,
    (v) => v.toJson(),
    DisciplineShare.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<DisciplineMix>(
    'DisciplineMix',
    arbitraryDisciplineMix,
    (v) => v.toJson(),
    DisciplineMix.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<StreetMode>(
    'StreetMode',
    arbitraryStreetMode,
    (v) => v.toJson(),
    StreetMode.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<MovementLevel>(
    'MovementLevel',
    arbitraryMovementLevel,
    (v) => v.toJson(),
    MovementLevel.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Goal>(
    'Goal',
    arbitraryGoal,
    (v) => v.toJson(),
    Goal.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<DaySlot>(
    'DaySlot',
    arbitraryDaySlot,
    (v) => v.toJson(),
    DaySlot.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlaceEquipment>(
    'PlaceEquipment',
    arbitraryPlaceEquipment,
    (v) => v.toJson(),
    PlaceEquipment.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<LoadIncrement>(
    'LoadIncrement',
    arbitraryLoadIncrement,
    (v) => v.toJson(),
    LoadIncrement.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Limitation>(
    'Limitation',
    arbitraryLimitation,
    (v) => v.toJson(),
    Limitation.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<HealthScreeningRef>(
    'HealthScreeningRef',
    arbitraryHealthScreeningRef,
    (v) => v.toJson(),
    HealthScreeningRef.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AthleteProfile>(
    'AthleteProfile',
    arbitraryAthleteProfile,
    (v) => v.toJson(),
    AthleteProfile.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PainReport>(
    'PainReport',
    arbitraryPainReport,
    (v) => v.toJson(),
    PainReport.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<HealthCheck>(
    'HealthCheck',
    arbitraryHealthCheck,
    (v) => v.toJson(),
    HealthCheck.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SetTarget>(
    'SetTarget',
    arbitrarySetTarget,
    (v) => v.toJson(),
    SetTarget.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SetRecord>(
    'SetRecord',
    arbitrarySetRecord,
    (v) => v.toJson(),
    SetRecord.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<TrainingBreak>(
    'TrainingBreak',
    arbitraryTrainingBreak,
    (v) => v.toJson(),
    TrainingBreak.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ProgramRef>(
    'ProgramRef',
    arbitraryProgramRef,
    (v) => v.toJson(),
    ProgramRef.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SessionRecord>(
    'SessionRecord',
    arbitrarySessionRecord,
    (v) => v.toJson(),
    SessionRecord.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<TrainingLog>(
    'TrainingLog',
    arbitraryTrainingLog,
    (v) => v.toJson(),
    TrainingLog.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanLock>(
    'PlanLock',
    arbitraryPlanLock,
    (v) => v.toJson(),
    PlanLock.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanSlot>(
    'PlanSlot',
    arbitraryPlanSlot,
    (v) => v.toJson(),
    PlanSlot.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanDay>(
    'PlanDay',
    arbitraryPlanDay,
    (v) => v.toJson(),
    PlanDay.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ScoreComponent>(
    'ScoreComponent',
    arbitraryScoreComponent,
    (v) => v.toJson(),
    ScoreComponent.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanScore>(
    'PlanScore',
    arbitraryPlanScore,
    (v) => v.toJson(),
    PlanScore.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Pass1Plan>(
    'Pass1Plan',
    arbitraryPass1Plan,
    (v) => v.toJson(),
    Pass1Plan.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ReviewAction>(
    'ReviewAction',
    arbitraryReviewAction,
    (v) => v.toJson(),
    ReviewAction.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ProfileDelta>(
    'ProfileDelta',
    arbitraryProfileDelta,
    (v) => v.toJson(),
    ProfileDelta.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanChange>(
    'PlanChange',
    arbitraryPlanChange,
    (v) => v.toJson(),
    PlanChange.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanDiff>(
    'PlanDiff',
    arbitraryPlanDiff,
    (v) => v.toJson(),
    PlanDiff.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ReviewResult>(
    'ReviewResult',
    arbitraryReviewResult,
    (v) => v.toJson(),
    ReviewResult.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Variant>(
    'Variant',
    arbitraryVariant,
    (v) => v.toJson(),
    Variant.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<VariantSet>(
    'VariantSet',
    arbitraryVariantSet,
    (v) => v.toJson(),
    VariantSet.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ExercisePrescription>(
    'ExercisePrescription',
    arbitraryExercisePrescription,
    (v) => v.toJson(),
    ExercisePrescription.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<DayPrescription>(
    'DayPrescription',
    arbitraryDayPrescription,
    (v) => v.toJson(),
    DayPrescription.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<WeekPrescription>(
    'WeekPrescription',
    arbitraryWeekPrescription,
    (v) => v.toJson(),
    WeekPrescription.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Pass2Plan>(
    'Pass2Plan',
    arbitraryPass2Plan,
    (v) => v.toJson(),
    Pass2Plan.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ProgramBlock>(
    'ProgramBlock',
    arbitraryProgramBlock,
    (v) => v.toJson(),
    ProgramBlock.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ExerciseEstimate>(
    'ExerciseEstimate',
    arbitraryExerciseEstimate,
    (v) => v.toJson(),
    ExerciseEstimate.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<FatigueState>(
    'FatigueState',
    arbitraryFatigueState,
    (v) => v.toJson(),
    FatigueState.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PainTrend>(
    'PainTrend',
    arbitraryPainTrend,
    (v) => v.toJson(),
    PainTrend.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AdaptationSummary>(
    'AdaptationSummary',
    arbitraryAdaptationSummary,
    (v) => v.toJson(),
    AdaptationSummary.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AdaptInput>(
    'AdaptInput',
    arbitraryAdaptInput,
    (v) => v.toJson(),
    AdaptInput.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SessionRequest>(
    'SessionRequest',
    arbitrarySessionRequest,
    (v) => v.toJson(),
    SessionRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AdviceRequest>(
    'AdviceRequest',
    arbitraryAdviceRequest,
    (v) => v.toJson(),
    AdviceRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ProposalDecision>(
    'ProposalDecision',
    arbitraryProposalDecision,
    (v) => v.toJson(),
    ProposalDecision.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PersonalRecord>(
    'PersonalRecord',
    arbitraryPersonalRecord,
    (v) => v.toJson(),
    PersonalRecord.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SessionAdjustment>(
    'SessionAdjustment',
    arbitrarySessionAdjustment,
    (v) => v.toJson(),
    SessionAdjustment.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SessionPlan>(
    'SessionPlan',
    arbitrarySessionPlan,
    (v) => v.toJson(),
    SessionPlan.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<IntraSessionAdvice>(
    'IntraSessionAdvice',
    arbitraryIntraSessionAdvice,
    (v) => v.toJson(),
    IntraSessionAdvice.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Proposal>(
    'Proposal',
    arbitraryProposal,
    (v) => v.toJson(),
    Proposal.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<EngineLogEntry>(
    'EngineLogEntry',
    arbitraryEngineLogEntry,
    (v) => v.toJson(),
    EngineLogEntry.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AdaptReview>(
    'AdaptReview',
    arbitraryAdaptReview,
    (v) => v.toJson(),
    AdaptReview.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<XpEntry>(
    'XpEntry',
    arbitraryXpEntry,
    (v) => v.toJson(),
    XpEntry.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<KreditEntry>(
    'KreditEntry',
    arbitraryKreditEntry,
    (v) => v.toJson(),
    KreditEntry.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<LevelState>(
    'LevelState',
    arbitraryLevelState,
    (v) => v.toJson(),
    LevelState.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AttributeScore>(
    'AttributeScore',
    arbitraryAttributeScore,
    (v) => v.toJson(),
    AttributeScore.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<MovementRank>(
    'MovementRank',
    arbitraryMovementRank,
    (v) => v.toJson(),
    MovementRank.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Quest>(
    'Quest',
    arbitraryQuest,
    (v) => v.toJson(),
    Quest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Milestone>(
    'Milestone',
    arbitraryMilestone,
    (v) => v.toJson(),
    Milestone.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Prediction>(
    'Prediction',
    arbitraryPrediction,
    (v) => v.toJson(),
    Prediction.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<GoalProgress>(
    'GoalProgress',
    arbitraryGoalProgress,
    (v) => v.toJson(),
    GoalProgress.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<DelightEvent>(
    'DelightEvent',
    arbitraryDelightEvent,
    (v) => v.toJson(),
    DelightEvent.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<QuestState>(
    'QuestState',
    arbitraryQuestState,
    (v) => v.toJson(),
    QuestState.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<QuestClaim>(
    'QuestClaim',
    arbitraryQuestClaim,
    (v) => v.toJson(),
    QuestClaim.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<QuestInput>(
    'QuestInput',
    arbitraryQuestInput,
    (v) => v.toJson(),
    QuestInput.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<QuestOutcome>(
    'QuestOutcome',
    arbitraryQuestOutcome,
    (v) => v.toJson(),
    QuestOutcome.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PlanRequest>(
    'PlanRequest',
    arbitraryPlanRequest,
    (v) => v.toJson(),
    PlanRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<NextBlockRequest>(
    'NextBlockRequest',
    arbitraryNextBlockRequest,
    (v) => v.toJson(),
    NextBlockRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<RestructureRequest>(
    'RestructureRequest',
    arbitraryRestructureRequest,
    (v) => v.toJson(),
    RestructureRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<ReviewRequest>(
    'ReviewRequest',
    arbitraryReviewRequest,
    (v) => v.toJson(),
    ReviewRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<VariantsRequest>(
    'VariantsRequest',
    arbitraryVariantsRequest,
    (v) => v.toJson(),
    VariantsRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Pass2Request>(
    'Pass2Request',
    arbitraryPass2Request,
    (v) => v.toJson(),
    Pass2Request.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<BlockProposal>(
    'BlockProposal',
    arbitraryBlockProposal,
    (v) => v.toJson(),
    BlockProposal.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<OtherSport>(
    'OtherSport',
    arbitraryOtherSport,
    (v) => v.toJson(),
    OtherSport.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<RecentTraining>(
    'RecentTraining',
    arbitraryRecentTraining,
    (v) => v.toJson(),
    RecentTraining.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<EnduranceBase>(
    'EnduranceBase',
    arbitraryEnduranceBase,
    (v) => v.toJson(),
    EnduranceBase.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Benchmark>(
    'Benchmark',
    arbitraryBenchmark,
    (v) => v.toJson(),
    Benchmark.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<WeakPoint>(
    'WeakPoint',
    arbitraryWeakPoint,
    (v) => v.toJson(),
    WeakPoint.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<CompetitionLift>(
    'CompetitionLift',
    arbitraryCompetitionLift,
    (v) => v.toJson(),
    CompetitionLift.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<EventStation>(
    'EventStation',
    arbitraryEventStation,
    (v) => v.toJson(),
    EventStation.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SeasonEvent>(
    'SeasonEvent',
    arbitrarySeasonEvent,
    (v) => v.toJson(),
    SeasonEvent.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Specialization>(
    'Specialization',
    arbitrarySpecialization,
    (v) => v.toJson(),
    Specialization.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SkillState>(
    'SkillState',
    arbitrarySkillState,
    (v) => v.toJson(),
    SkillState.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<StepCriterion>(
    'StepCriterion',
    arbitraryStepCriterion,
    (v) => v.toJson(),
    StepCriterion.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SkillStep>(
    'SkillStep',
    arbitrarySkillStep,
    (v) => v.toJson(),
    SkillStep.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SkillLadder>(
    'SkillLadder',
    arbitrarySkillLadder,
    (v) => v.toJson(),
    SkillLadder.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SkillProgress>(
    'SkillProgress',
    arbitrarySkillProgress,
    (v) => v.toJson(),
    SkillProgress.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PhaseOverride>(
    'PhaseOverride',
    arbitraryPhaseOverride,
    (v) => v.toJson(),
    PhaseOverride.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SeasonPhase>(
    'SeasonPhase',
    arbitrarySeasonPhase,
    (v) => v.toJson(),
    SeasonPhase.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SeasonPlan>(
    'SeasonPlan',
    arbitrarySeasonPlan,
    (v) => v.toJson(),
    SeasonPlan.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<BlockIntent>(
    'BlockIntent',
    arbitraryBlockIntent,
    (v) => v.toJson(),
    BlockIntent.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<VolumeTolerance>(
    'VolumeTolerance',
    arbitraryVolumeTolerance,
    (v) => v.toJson(),
    VolumeTolerance.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AttemptResult>(
    'AttemptResult',
    arbitraryAttemptResult,
    (v) => v.toJson(),
    AttemptResult.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AttemptSuggestion>(
    'AttemptSuggestion',
    arbitraryAttemptSuggestion,
    (v) => v.toJson(),
    AttemptSuggestion.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<WarmupStep>(
    'WarmupStep',
    arbitraryWarmupStep,
    (v) => v.toJson(),
    WarmupStep.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<LiftAttempts>(
    'LiftAttempts',
    arbitraryLiftAttempts,
    (v) => v.toJson(),
    LiftAttempts.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<PacingSegment>(
    'PacingSegment',
    arbitraryPacingSegment,
    (v) => v.toJson(),
    PacingSegment.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<EventDayRequest>(
    'EventDayRequest',
    arbitraryEventDayRequest,
    (v) => v.toJson(),
    EventDayRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<EventDayPlan>(
    'EventDayPlan',
    arbitraryEventDayPlan,
    (v) => v.toJson(),
    EventDayPlan.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SeasonRequest>(
    'SeasonRequest',
    arbitrarySeasonRequest,
    (v) => v.toJson(),
    SeasonRequest.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<Tempo>(
    'Tempo',
    arbitraryTempo,
    (v) => v.toJson(),
    Tempo.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SetTechnique>(
    'SetTechnique',
    arbitrarySetTechnique,
    (v) => v.toJson(),
    SetTechnique.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<IntensityTarget>(
    'IntensityTarget',
    arbitraryIntensityTarget,
    (v) => v.toJson(),
    IntensityTarget.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<AutoregulationRule>(
    'AutoregulationRule',
    arbitraryAutoregulationRule,
    (v) => v.toJson(),
    AutoregulationRule.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<GroupSpec>(
    'GroupSpec',
    arbitraryGroupSpec,
    (v) => v.toJson(),
    GroupSpec.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<GroupResult>(
    'GroupResult',
    arbitraryGroupResult,
    (v) => v.toJson(),
    GroupResult.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<SetPart>(
    'SetPart',
    arbitrarySetPart,
    (v) => v.toJson(),
    SetPart.fromJson,
    (v) => v.validate(),
  ),
  ContractCodec<TestSpec>(
    'TestSpec',
    arbitraryTestSpec,
    (v) => v.toJson(),
    TestSpec.fromJson,
    (v) => v.validate(),
  ),
];

/// Jour civil aléatoire (réexporté pour les tests).
CivilDate arbitraryCivilDate(Random r) => arbDate(r);
