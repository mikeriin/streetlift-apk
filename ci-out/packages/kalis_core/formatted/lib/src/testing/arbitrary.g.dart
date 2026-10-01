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
  );
}

/// Valeur aléatoire de [DayPrescription].
DayPrescription arbitraryDayPrescription(Random r) {
  return DayPrescription(
    dayIndex: arbInt(r, 0, 1000),
    items: arbList(r, 0, 3, () => arbitraryExercisePrescription(r)),
  );
}

/// Valeur aléatoire de [WeekPrescription].
WeekPrescription arbitraryWeekPrescription(Random r) {
  return WeekPrescription(
    weekIndex: arbInt(r, 0, 1000),
    kind: arbEnum(r, WeekKind.values),
    days: arbList(r, 0, 3, () => arbitraryDayPrescription(r)),
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
];

/// Jour civil aléatoire (réexporté pour les tests).
CivilDate arbitraryCivilDate(Random r) => arbDate(r);
