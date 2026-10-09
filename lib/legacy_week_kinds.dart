// G10 (D1.4) : nature des semaines d'un programme existant (programme
// embarqué du propriétaire, ancien programme L10, semaines d'avant un
// programme créé), lue dans les annotations du programme
// (`assets/koach_program.json.gz`, section `weeks`). Avant G10, Koach L7
// lisait tout ce fichier ; seules les natures de semaine servent encore :
// elles disent au moteur dynamique (`kalis_adapt`) quelles semaines du bloc
// importé sont des décharges ou des tests (G9, D5.10).

class LegacyWeekKinds {
  /// Semaine (S) → `normal`, `deload` ou `test`.
  final Map<int, String> weekTypes;

  const LegacyWeekKinds(this.weekTypes);
  const LegacyWeekKinds.empty() : weekTypes = const {};

  /// Annotations au format de `assets/koach_program.json.gz` (seule la
  /// section `weeks` est lue ; absente : aucune nature connue).
  factory LegacyWeekKinds.fromJson(Map<String, dynamic> j) {
    final weeks = j['weeks'];
    if (weeks is! Map) return const LegacyWeekKinds.empty();
    return LegacyWeekKinds({
      for (final e in weeks.entries)
        if (int.tryParse('${e.key}') != null && e.value is String)
          int.parse('${e.key}'): e.value as String,
    });
  }

  bool isDeload(int week) => weekTypes[week] == 'deload';
  bool isTest(int week) => weekTypes[week] == 'test';
}
