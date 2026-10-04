/// Proximité entre deux exercices pour le choix des variantes et la
/// recherche locale (CONTRAT.md, § Variantes).
library;

import 'package:kalis_core/kalis_core.dart';

/// Poids du cosinus des vecteurs musculaires pondérés (principal 1,
/// secondaire 0,5, stabilisateur 0,2).
const double similarityMuscleWeight = 0.45;

/// Poids du schéma de mouvement (1 : même schéma ; 0,5 : même famille).
const double similarityPatternWeight = 0.20;

/// Poids du plan du mouvement (1 : même plan ; 0,5 : l'un est multiple).
const double similarityPlaneWeight = 0.10;

/// Poids de l'écart de difficulté (1 − |écart| / 9).
const double similarityDifficultyWeight = 0.10;

/// Poids de la chaîne `variante_de` (même racine).
const double similarityChainWeight = 0.10;

/// Poids de l'unité de mesure (répétitions, secondes, distance).
const double similarityUnitWeight = 0.05;

/// Proximité de [a] et [b], de 0 à 1 : symétrique, 1 pour un exercice et
/// lui-même.
///
/// Raffine `Catalog.similarity` (kalis_core) : le plan du mouvement et
/// l'unité de mesure entrent dans la note, pour qu'une tenue ne remplace
/// pas un mouvement dynamique à la légère.
double planSimilarity(CatalogExercise a, CatalogExercise b) {
  if (identical(a, b) || a.id == b.id) {
    return 1;
  }
  final pattern = a.pattern == b.pattern
      ? 1.0
      : (a.family == b.family ? 0.5 : 0.0);
  final plane = a.plane == b.plane
      ? 1.0
      : (a.plane == MovementPlane.multiple || b.plane == MovementPlane.multiple
            ? 0.5
            : 0.0);
  final difficulty = 1 - (a.difficulty - b.difficulty).abs() / 9;
  final chain = a.rootId == b.rootId ? 1.0 : 0.0;
  final unit = a.unit == b.unit ? 1.0 : 0.0;
  final value =
      similarityMuscleWeight * a.muscleCosine(b) +
      similarityPatternWeight * pattern +
      similarityPlaneWeight * plane +
      similarityDifficultyWeight * difficulty +
      similarityChainWeight * chain +
      similarityUnitWeight * unit;
  return value < 0 ? 0 : (value > 1 ? 1 : value);
}
