// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Code de raison et ses paramètres (aucun texte : les phrases viennent de
/// kalis_koach et de l'application).
///
/// Invariant : `code` figure au registre ; `params` contient exactement les
/// paramètres déclarés, du bon type.
final class Reason {
  const Reason({required this.code, required this.params});

  /// Lit un objet JSON ; [FormatException] si un champ manque ou a un type inattendu.
  /// Les champs inconnus sont ignorés (évolution additive).
  factory Reason.fromJson(Map<String, Object?> json) {
    return Reason(
      code: jsonString(json, 'code'),
      params: jsonObject(json, 'params'),
    );
  }

  /// Identifiant stable du registre des codes de raison.
  final String code;

  /// Paramètres typés du code (nombres, chaînes, booléens), écrits par clés
  /// triées.
  final Map<String, Object?> params;

  /// Objet JSON canonique : clés dans l'ordre du contrat, champs absents omis.
  Map<String, Object?> toJson() {
    return <String, Object?>{'code': code, 'params': jsonCanonical(params)};
  }

  /// Copie modifiée ; un champ optionnel peut être remis à `null`.
  Reason copyWith({String? code, Map<String, Object?>? params}) {
    return Reason(code: code ?? this.code, params: params ?? this.params);
  }

  /// Violations des invariants du contrat (liste vide = valeur valide).
  List<Violation> validate() {
    final out = <Violation>[];
    collectViolations(r'$', out);
    return out;
  }

  /// Ajoute à [out] les violations de cette valeur, située à [path].
  void collectViolations(String path, List<Violation> out) {
    checkLength(out, '$path.code', code.length, 1, null);
    checkJson(out, '$path.params', params);
    _validateReason(this, path, out);
  }

  /// Ajoute à [out] les identifiants d'exercices cités par cette valeur.
  void collectExerciseIds(Set<String> out) {
    _collectReasonExerciseIds(this, out);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Reason &&
            code == other.code &&
            jsonDeepEquals(params, other.params);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[code, jsonDeepHash(params)]);

  @override
  String toString() => 'Reason(${toJson()})';
}
