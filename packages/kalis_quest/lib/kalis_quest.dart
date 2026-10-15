/// Moteur de progression de Kalis Track : niveaux, attributs, rangs,
/// quêtes, objectifs, mécaniques de plaisir (D7, D8, D3.8).
///
/// - [KalisQuest] : réalisation de `QuestEngine` (kalis_core) ;
/// - [QuestParams] : tous les paramètres chiffrés ;
/// - [LevelCurve] : courbe des niveaux 1 à 100 puis prestige ;
/// - [Standards] : standards de rang par sexe et poids de corps.
///
/// Dart pur : aucun import de Flutter ni de `dart:io`, aucune horloge,
/// aucun hasard hors de la graine. Voir `CONTRAT.md`.
library;

export 'src/engine.dart' show KalisQuest;
export 'src/extras.dart' show extrasSchema, flameSizeOf;
export 'src/grade.dart' show SessionMark, markOf;
export 'src/goals.dart'
    show GoalKeeper, GoalResult, PredictionMethods, TrendEstimate, dampedGain;
export 'src/ledger.dart'
    show CapScope, Ledger, MachineState, SessionStatus, WeekSummary;
export 'src/level.dart' show LevelCurve;
export 'src/numeric.dart' show mondayOf, unitOf, weekdayOf;
export 'src/params.dart' show QuestParams;
export 'src/progress.dart'
    show
        RankResult,
        computeAttributes,
        computeRanks,
        explosiveMovements,
        figureMovements,
        retentionOf;
export 'src/quests.dart'
    show QuestBook, QuestMaster, QuestMetrics, QuestTemplates;
export 'src/standards.dart' show HoldRung, RankMeasure, RankMovement, Standards;
export 'src/version.dart';
export 'src/world.dart'
    show BreakSpan, Observation, RecordEvent, SessionFacts, World;
