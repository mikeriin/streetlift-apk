part of 'contracts.dart';

/// Type d'un paramètre de code de raison.
enum ReasonParamType {
  /// Entier.
  integer,

  /// Nombre fini.
  number,

  /// Texte court (code d'enum, identifiant) — jamais une phrase.
  text,

  /// Booléen.
  flag,

  /// Identifiant d'exercice du catalogue.
  exerciseId,
}

/// Entrée du registre des codes de raison.
final class ReasonSpec {
  /// Code [code] et ses paramètres typés.
  const ReasonSpec(this.code, this.params);

  /// Identifiant stable (`plan.muscle_volume`).
  final String code;

  /// Nom et type de chaque paramètre attendu.
  final Map<String, ReasonParamType> params;
}

/// Entrée du registre pour [code], ou `null` si le code est inconnu.
ReasonSpec? reasonSpecOf(String code) {
  for (final spec in reasonRegistry) {
    if (spec.code == code) {
      return spec;
    }
  }
  return null;
}

bool _reasonParamMatches(ReasonParamType type, Object? value) {
  switch (type) {
    case ReasonParamType.integer:
      return value is int;
    case ReasonParamType.number:
      return value is num && value.isFinite;
    case ReasonParamType.text:
    case ReasonParamType.exerciseId:
      return value is String && value.isNotEmpty;
    case ReasonParamType.flag:
      return value is bool;
  }
}

void _validateReason(Reason v, String path, List<Violation> out) {
  final spec = reasonSpecOf(v.code);
  if (spec == null) {
    out.add(Violation('$path.code', 'unknown_reason_code', v.code));
    return;
  }
  for (final entry in spec.params.entries) {
    if (!v.params.containsKey(entry.key)) {
      out.add(Violation('$path.params', 'missing_param', entry.key));
    } else if (!_reasonParamMatches(entry.value, v.params[entry.key])) {
      out.add(
        Violation('$path.params.${entry.key}', 'param_type', entry.value.name),
      );
    }
  }
  for (final key in v.params.keys) {
    if (!spec.params.containsKey(key)) {
      out.add(Violation('$path.params.$key', 'unknown_param', v.code));
    }
  }
}
