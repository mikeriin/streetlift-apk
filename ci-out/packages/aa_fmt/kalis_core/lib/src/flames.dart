/// Échelle des 10 flammes (D5.3) : note de difficulté d'une série, en
/// demi-répétitions en réserve (RIR).
///
/// | Flammes | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |
/// | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
/// | RIR | 0 (échec) | 1 | 1,5 | 2 | 2,5 | 3 | 3,5 | 4 | 4,5 | 5 et plus |
///
/// « Pas de note » est l'absence de valeur (`null`), jamais une flamme.
abstract final class Flames {
  /// Plus petite note : RIR 5 et plus.
  static const int min = 1;

  /// Plus grande note : échec (RIR 0 ou répétition manquée).
  static const int max = 10;

  /// Note de l'échec.
  static const int failure = 10;

  /// Vrai si [flames] est une note de l'échelle.
  static bool isValid(int flames) => flames >= min && flames <= max;

  /// RIR exact de [flames] : 10 → 0 ; 9 → 1 ; 8 → 1,5 ; … ; 1 → 5.
  ///
  /// Pour 1 flamme, 5 est une borne basse (« 5 et plus », voir
  /// [isOpenEnded]). [ArgumentError] hors de l'échelle.
  static double toRir(int flames) {
    if (!isValid(flames)) {
      throw ArgumentError.value(flames, 'flames', 'attendu de 1 à 10');
    }
    return flames == failure ? 0.0 : (11 - flames) / 2;
  }

  /// Vrai si la note ne borne pas le RIR par le haut (1 flamme : 5 et plus).
  static bool isOpenEnded(int flames) => flames == min;

  /// Note d'un RIR quelconque.
  ///
  /// Exacte sur les valeurs de l'échelle (`fromRir(toRir(f)) == f`). Le RIR
  /// est d'abord ramené au demi-point le plus proche (égalité : vers le RIR
  /// le plus bas, donc la série la plus dure) ; RIR 0,5, absent de
  /// l'échelle, donne 9 flammes : une série qui garde une demi-répétition
  /// n'est pas un échec. Sert à convertir l'ancien journal (difficulté
  /// notée en RIR de 0 à 5 par pas de 0,5). [ArgumentError] si [rir] est
  /// négatif ou n'est pas un nombre.
  static int fromRir(double rir) {
    if (rir.isNaN || rir < 0) {
      throw ArgumentError.value(rir, 'rir', 'attendu positif ou nul');
    }
    if (rir >= 5) {
      return min;
    }
    final halves = (rir * 2 - 0.5).ceil();
    if (halves <= 0) {
      return failure;
    }
    if (halves == 1) {
      return 9;
    }
    return 11 - halves;
  }

  /// Écart de difficulté entre la note réalisée et la note visée, en
  /// flammes (positif : plus dur que prévu) ; `null` sans note.
  static int? delta({required int? actual, required int target}) {
    return actual == null ? null : actual - target;
  }
}
