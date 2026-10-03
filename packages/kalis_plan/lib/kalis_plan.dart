/// Moteur statique de Kalis Track : création du programme (D4).
///
/// - [KalisPlan] : réalisation de `PlanEngine` (kalis_core) — passe 1,
///   revue, variantes, passe 2, bloc suivant, restructuration ;
/// - [PlanParams] : paramètres chiffrés et poids de la note ;
/// - [PlanInspector] : note détaillée, contraintes dures, mesures d'un
///   programme (tests, simulateur, inspecteur du mode dev) ;
/// - [planSimilarity] : proximité entre deux exercices.
///
/// Dart pur : aucun import de Flutter ni de `dart:io`, aucune horloge,
/// aucun hasard hors de la graine. Voir `CONTRAT.md`.
library;

export 'src/assemble.dart' show FocusCodes, dayOfSlotId, slotIdFor;
export 'src/context.dart'
    show
        DisciplineClass,
        adaptationVolumeScale,
        competitionCategory,
        disciplineAffinity,
        levelOfAbility,
        volumeBandsByLevel;
export 'src/engine.dart'
    show KalisPlan, ReviewTrace, applyProfileDelta, blockIdFor;
export 'src/hash.dart' show SeededRandom, fnv1a32, fnvMix, stableExp, stableLn;
export 'src/inspect.dart' show PlanInspector, PlanMetrics;
export 'src/params.dart' show PlanParams, ScoreWeights;
export 'src/pass2.dart'
    show
        buildStartVolumeFactor,
        defaultBlockWeeks,
        defaultIncrement,
        deloadRirBonus,
        deloadVolumeFactor,
        introRirBonus,
        introVolumeFactor,
        weekKindsFor;
export 'src/scheme.dart' show SchemeKind;
export 'src/similarity.dart';
export 'src/traits.dart'
    show
        AbilityGroup,
        BalanceClass,
        CatalogTraits,
        ExerciseTraits,
        MobilityRegion,
        MuscleGroup,
        SlotKind,
        muscleGroupOf;
export 'src/version.dart';
