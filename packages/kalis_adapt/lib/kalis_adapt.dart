/// Moteur dynamique de Kalis Track : suivi et adaptation (D5).
///
/// - [KalisAdapt] : réalisation de `AdaptEngine` (kalis_core) —
///   prescription de la séance du jour, conseil pour la série suivante,
///   revue complète (résumé d'adaptation, propositions, records, journal
///   du moteur) ;
/// - [KalisAdapt.planEventDay] : tentatives d'une compétition de force,
///   rythme d'une épreuve de répétitions (`EventDayAdvisor`) ;
/// - [AdaptParams] : tous les paramètres chiffrés ;
/// - [CapacityFilter] : filtre de Kalman d'un exercice.
///
/// Dart pur : aucun import de Flutter ni de `dart:io`, aucune horloge,
/// aucun hasard. Voir `CONTRAT.md`.
library;

export 'src/apply.dart' show applyProposal;
export 'src/book.dart' show ExerciseBook, ExerciseInfo, zoneGroups;
export 'src/coach.dart'
    show
        AttemptPick,
        CoachSpec,
        LineReading,
        SlotMark,
        WeekPolicy,
        attemptLadder,
        attemptProbability,
        blockCoached,
        competitionLiftOf,
        readLine,
        techniqueAccessLevel,
        techniqueIntensifies,
        tendonLoaded;
export 'src/endurance.dart'
    show EnduranceKind, enduranceKindOf, isQualityRun, prescribedSeconds;
export 'src/engine.dart' show KalisAdapt;
export 'src/event_day.dart' show warmupSteps;
export 'src/fatigue.dart'
    show FatigueModel, HealthReading, effortWeight, readHealth, readinessOf;
export 'src/filter.dart'
    show CapacityFilter, CapacityMode, TrackPoint, plannedFatigue, setFatigueOf;
export 'src/grid.dart' show LoadGrid, poundKg;
export 'src/model.dart'
    show
        EngineContext,
        ExerciseRun,
        ExerciseTrack,
        ModelState,
        ObservedSet,
        PainState,
        SessionRun,
        SetPlan,
        SlotSpec;
export 'src/numeric.dart'
    show erfc, flamesOfRir, logShare, normCdf, normPdf, repsAt, rirOfFlames;
export 'src/params.dart' show AdaptParams;
export 'src/rater.dart' show RatingModel;
export 'src/replay.dart'
    show
        BlockView,
        DigestEntry,
        Replayed,
        SessionDigest,
        bodyWeightOf,
        planOfTarget,
        replayLog,
        sessionsOf;
export 'src/review.dart'
    show
        confidenceThreshold,
        estimatesOf,
        recordsOf,
        scheduledDay,
        unlockLevelFor,
        weekOfDay;
export 'src/results.dart'
    show
        testBenchmarks,
        testResultReasons,
        trainingBenchmarks,
        volumeToleranceOf;
export 'src/session.dart'
    show
        equipmentFor,
        findSubstitute,
        itemSeconds,
        recoveryLimited,
        recoveryReasons;
export 'src/skills.dart' show SkillBoard, SkillLine;
export 'src/version.dart';
