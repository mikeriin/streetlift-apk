/// Banc d'essai du calibrage des programmes de Kalis Track.
///
/// - [BenchProfile] : profil type (sur-ensemble du profil de `kalis_core`)
///   et [adaptProfile], l'adaptateur vers le profil des moteurs ;
/// - [generateProgram], [ProgramView] : programme créé par `kalis_plan`,
///   lu semaine par semaine ;
/// - [safetyFindings], [qualityMeasures], [evaluateChecks] : critères
///   calculables et attentes de coach ;
/// - [simulateTrajectory] : trajectoire sous `kalis_adapt` ;
/// - [programMarkdown], [trajectoryMarkdown] : exports lisibles ;
/// - [evaluateProfile], [renderReport] : rapport.
///
/// Dart pur : aucun import de Flutter ni de `dart:io`, aucune horloge,
/// aucun hasard hors des graines. Voir `CONTRAT.md`.
library;

export 'src/adapter.dart';
export 'src/analysis.dart';
export 'src/campaign.dart';
export 'src/expectations.dart';
export 'src/export.dart';
export 'src/profile.dart';
export 'src/program.dart';
export 'src/quality.dart';
export 'src/report.dart';
export 'src/safety.dart';
export 'src/trajectory.dart';
export 'src/trajectory_export.dart';
export 'src/version.dart';
