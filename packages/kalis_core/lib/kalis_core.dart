/// Contrats et modèles partagés des moteurs de Kalis Track.
///
/// - [Catalog] : catalogue d'exercices compilé depuis la base v1.1 ;
/// - [AthleteProfile] : profil d'athlète (schémas 2 et 3) ;
/// - [ProfileQuestionnaire] : parcours de questions du profil et tests
///   guidés ; [estimateOneRm], [riegelSeconds] : conversions des tests ;
/// - [TrainingLog] : journal de séances ;
/// - [Flames] : échelle des 10 flammes ;
/// - [PlanEngine], [AdaptEngine], [QuestEngine], [SeasonPlanner],
///   [EventDayAdvisor] : interfaces des moteurs et leurs types d'échange
///   (prescriptions avancées, saison, compétition, figures) ;
/// - [reasonRegistry] : codes de raison.
///
/// Dart pur : aucun import de Flutter ni de `dart:io`, aucune horloge,
/// aucun hasard. Voir `CONTRAT.md`.
library;

export 'src/catalog.dart';
export 'src/civil_date.dart';
export 'src/contracts.dart';
export 'src/engines.dart';
export 'src/estimation.dart';
export 'src/flames.dart';
export 'src/json_util.dart'
    show
        Violation,
        checkJson,
        jsonDeepEquals,
        jsonDeepHash,
        jsonListEquals,
        unset;
export 'src/questionnaire.dart';
export 'src/version.dart';
