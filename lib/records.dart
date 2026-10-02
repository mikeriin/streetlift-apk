// Records personnels par nom d'exercice (bannière « record » en direct de la
// séance, records battus d'une séance). Repris tels quels de l'ancienne
// couche « jeu » (game.dart, retirée en G12) : les records et l'historique
// ne changent pas. Les records du moteur de progression (kalis_quest)
// s'affichent dans Progression.
import 'search.dart' show normalizeText;
import 'store.dart' show SessionLog;

/// Epley : 1RM estimé = charge × (1 + reps / 30). Poids de corps : la charge
/// vaut 0 et l'on compare les répétitions.
double e1rmOf(double kg, int reps) => kg <= 0 ? 0 : kg * (1 + reps / 30);

class ExerciseBests {
  double bestE1rm = 0;
  double bestKg = 0;
  int bestKgReps = 0;
  int bestReps = 0;
  int weightedSets = 0, bodyweightSets = 0;
}

double? _kg(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
int? _reps(String s) => int.tryParse(s.trim());

/// Meilleures performances par exercice, toutes séances confondues (clé de
/// séance `excludeKey` ignorée : la séance en cours).
Map<String, ExerciseBests> exerciseBests(
  Map<String, SessionLog> logs, {
  String? excludeKey,
}) {
  final out = <String, ExerciseBests>{};
  for (final entry in logs.entries) {
    if (entry.key == excludeKey) continue;
    final log = entry.value;
    for (final ex in log.ex.entries) {
      final name = log.exerciseNames[ex.key];
      if (name == null || name.isEmpty) continue;
      final best = out.putIfAbsent(normalizeText(name), ExerciseBests.new);
      for (final set in ex.value.sets) {
        if (!set.done) continue;
        _fold(best, set.kg, set.reps);
      }
    }
  }
  return out;
}

void _fold(ExerciseBests best, String kgText, String repsText) {
  final reps = _reps(repsText) ?? 0;
  final kg = _kg(kgText) ?? 0;
  if (reps <= 0) return;
  if (kg > 0) {
    best.weightedSets++;
    final e = e1rmOf(kg, reps);
    if (e > best.bestE1rm) {
      best.bestE1rm = e;
      best.bestKg = kg;
      best.bestKgReps = reps;
    }
  } else {
    best.bodyweightSets++;
    if (reps > best.bestReps) best.bestReps = reps;
  }
}

/// Record battu par une série (charge / reps) face à l'historique d'un
/// exercice ; null si ce n'est pas un record ou s'il n'y a pas de référence.
class RecordHit {
  final String exercise;
  final bool weighted;
  final double kg;
  final int reps;
  final double previous; // 1RM estimé précédent, ou reps précédentes
  final double current;
  const RecordHit({
    required this.exercise,
    required this.weighted,
    required this.kg,
    required this.reps,
    required this.previous,
    required this.current,
  });

  String get label {
    String fmt(double v) => v == v.roundToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return weighted
        ? '${fmt(kg)} kg × $reps (1RM estimé ${fmt(current)} kg, avant ${fmt(previous)})'
        : '$reps reps (avant ${previous.toInt()})';
  }
}

RecordHit? recordFor(
  Map<String, ExerciseBests> bests,
  String exercise,
  String kgText,
  String repsText,
) {
  final best = bests[normalizeText(exercise)];
  final reps = _reps(repsText) ?? 0;
  final kg = _kg(kgText) ?? 0;
  if (reps <= 0 || best == null) return null;
  if (kg > 0) {
    if (best.weightedSets == 0) return null;
    final e = e1rmOf(kg, reps);
    if (e <= best.bestE1rm) return null;
    return RecordHit(
      exercise: exercise,
      weighted: true,
      kg: kg,
      reps: reps,
      previous: best.bestE1rm,
      current: e,
    );
  }
  if (best.bodyweightSets == 0 || reps <= best.bestReps) return null;
  return RecordHit(
    exercise: exercise,
    weighted: false,
    kg: 0,
    reps: reps,
    previous: best.bestReps.toDouble(),
    current: reps.toDouble(),
  );
}

// ---------------------------------------------------------------------------
// Attributs de personnage
// ---------------------------------------------------------------------------
