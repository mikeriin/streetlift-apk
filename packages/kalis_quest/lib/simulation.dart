/// Simulation de rythme de `kalis_quest` : archétypes, journaux simulés,
/// déroulement semaine par semaine, mesures.
///
/// À n'importer que depuis des tests ou des outils (`bin/`, `tool/`). Dart
/// pur : aucun hasard hors des graines, aucune horloge.
library;

export 'src/sim/archetypes.dart';
export 'src/sim/generator.dart'
    show SimLog, SimRng, SimStage, generateLog, truthGain, truthTau;
export 'src/sim/runner.dart';
