// L10 (KT-050 à KT-057) puis G7 — programme en place côté magasin.
//
// G7 retire le générateur L10 (D1.4) : `kalis_plan` crée désormais le
// programme (plan_store.dart). Reste ici la lecture des instances L10
// existantes (« generated »), affichées telles quelles (G10 retire le
// catalogue de l'ancien pack qui servait à L11). Sans instance, le
// programme embarqué reste exactement celui de 3.2.0 : modèle « Expert
// streetlifting » implicite.
part of 'store.dart';

extension ProgramStore on AppStore {
  /// Un programme L10 (« generated ») est en place.
  bool get programGenerated => programInstance?.generated ?? false;

  /// Identifiant du modèle de périodisation L10 en place.
  String get programModel =>
      programInstance?.summary['model'] as String? ?? 'expert_streetlifting';

  /// Résumé de la génération L10 (vide pour le modèle implicite).
  Map<String, dynamic> get programSummary =>
      programInstance?.summary ?? const {'model': 'expert_streetlifting'};
}
