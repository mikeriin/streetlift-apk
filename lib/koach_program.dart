// Koach (L7) — annotations structurées du programme, lues dans
// `assets/koach_program.json.gz` (généré par `tools/koach_annotate.py` ;
// l'asset du programme n'est pas modifié). Contrat L7 §3.5.

/// Rôle d'un exercice pour Koach.
class KoachAnnotation {
  /// `strength` · `test1rm` · `endurance` · `enduranceTest` · `accessory`.
  final String? cat;

  /// Référence Pilotage (B8… 1RM, B16… maxima, B25… accessoires).
  final String? ref;

  /// Mouvement principal (`mu`, `pull`, `dip`, `squat`).
  final String? movement;

  /// RIR visé structuré, lu dans le libellé (« RIR 2 · ~82 % » → 2).
  final double? rirTarget;
  final double? rirTargetMax;

  const KoachAnnotation({
    this.cat,
    this.ref,
    this.movement,
    this.rirTarget,
    this.rirTargetMax,
  });
}

class KoachAccessory {
  final String equipment; // dumbbell | plate | barbell | pulley | machine
  final bool prevention;
  const KoachAccessory(this.equipment, this.prevention);
}

class KoachProgram {
  final Map<String, KoachAnnotation> exercises;
  final Map<String, KoachAccessory> accessories;

  /// Semaine → `normal`, `deload` ou `test`.
  final Map<int, String> weekTypes;

  /// k a priori de la courbe %1RM(n), par mouvement.
  final Map<String, double> kPrior;

  const KoachProgram({
    required this.exercises,
    required this.accessories,
    required this.weekTypes,
    required this.kPrior,
  });

  const KoachProgram.empty()
    : exercises = const {},
      accessories = const {},
      weekTypes = const {},
      kPrior = const {};

  bool get available => exercises.isNotEmpty;

  factory KoachProgram.fromJson(Map<String, dynamic> j) {
    double? n(Object? v) => v == null ? null : (v as num).toDouble();
    return KoachProgram(
      exercises: {
        for (final e in (j['exercises'] as Map).entries)
          e.key as String: KoachAnnotation(
            cat: (e.value as Map)['cat'] as String?,
            ref: (e.value as Map)['ref'] as String?,
            movement: (e.value as Map)['movement'] as String?,
            rirTarget: n((e.value as Map)['rirTarget']),
            rirTargetMax: n((e.value as Map)['rirTargetMax']),
          ),
      },
      accessories: {
        for (final e in (j['accessories'] as Map).entries)
          e.key as String: KoachAccessory(
            (e.value as Map)['equipment'] as String,
            (e.value as Map)['prevention'] == true,
          ),
      },
      weekTypes: {
        for (final e in (j['weeks'] as Map).entries)
          int.parse(e.key as String): e.value as String,
      },
      kPrior: {
        for (final e in (j['curve'] as Map).entries)
          e.key as String: ((e.value as Map)['k'] as num).toDouble(),
      },
    );
  }

  KoachAnnotation? of(String exerciseId) => exercises[exerciseId];

  bool isDeload(int week) => weekTypes[week] == 'deload';
  bool isTest(int week) => weekTypes[week] == 'test';
}
