/// Lecture stricte du JSON, égalité profonde et contrôles de validation
/// partagés par le code généré des contrats.
library;

import 'civil_date.dart';

/// Marqueur « argument non fourni » des méthodes `copyWith`.
const Object unset = _Unset();

final class _Unset {
  const _Unset();
}

/// Violation d'un invariant du contrat.
final class Violation {
  /// Violation de l'invariant [code] à l'emplacement [path].
  const Violation(this.path, this.code, this.message);

  /// Chemin de la valeur fautive (`$.sessions[3].sets[0].flames`).
  final String path;

  /// Code stable de la violation (`below_min`, `sum_not_100`…).
  final String code;

  /// Détail technique, pour les journaux et les tests (jamais affiché).
  final String message;

  @override
  bool operator ==(Object other) {
    return other is Violation &&
        path == other.path &&
        code == other.code &&
        message == other.message;
  }

  @override
  int get hashCode => Object.hash(path, code, message);

  @override
  String toString() => '$path : $code ($message)';
}

Never _typeError(String key, String expected, Object? value) {
  final got = value == null ? 'rien' : value.runtimeType.toString();
  throw FormatException('Champ "$key" : $expected attendu, reçu $got');
}

/// [value] en entier, ou [FormatException].
int jsonAsInt(Object? value, String key) {
  if (value is int) {
    return value;
  }
  _typeError(key, 'entier', value);
}

/// [value] en nombre, ou [FormatException].
double jsonAsDouble(Object? value, String key) {
  if (value is num) {
    return value.toDouble();
  }
  _typeError(key, 'nombre', value);
}

/// [value] en booléen, ou [FormatException].
bool jsonAsBool(Object? value, String key) {
  if (value is bool) {
    return value;
  }
  _typeError(key, 'booléen', value);
}

/// [value] en texte, ou [FormatException].
String jsonAsString(Object? value, String key) {
  if (value is String) {
    return value;
  }
  _typeError(key, 'texte', value);
}

/// [value] en objet JSON, ou [FormatException].
Map<String, Object?> jsonAsObject(Object? value, String key) {
  if (value is Map<String, Object?>) {
    return value;
  }
  _typeError(key, 'objet', value);
}

/// Entier obligatoire.
int jsonInt(Map<String, Object?> json, String key) => jsonAsInt(json[key], key);

/// Entier optionnel (clé absente ou nulle : `null`).
int? jsonIntOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : jsonAsInt(v, key);
}

/// Nombre obligatoire.
double jsonDouble(Map<String, Object?> json, String key) =>
    jsonAsDouble(json[key], key);

/// Nombre optionnel.
double? jsonDoubleOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : jsonAsDouble(v, key);
}

/// Booléen obligatoire.
bool jsonBool(Map<String, Object?> json, String key) =>
    jsonAsBool(json[key], key);

/// Booléen optionnel.
bool? jsonBoolOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : jsonAsBool(v, key);
}

/// Texte obligatoire.
String jsonString(Map<String, Object?> json, String key) =>
    jsonAsString(json[key], key);

/// Texte optionnel.
String? jsonStringOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : jsonAsString(v, key);
}

/// Jour civil obligatoire.
CivilDate jsonDate(Map<String, Object?> json, String key) =>
    CivilDate.parse(jsonString(json, key));

/// Jour civil optionnel.
CivilDate? jsonDateOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : CivilDate.parse(jsonAsString(v, key));
}

/// Objet JSON libre obligatoire.
Map<String, Object?> jsonObject(Map<String, Object?> json, String key) =>
    jsonAsObject(json[key], key);

/// Objet JSON libre optionnel.
Map<String, Object?>? jsonObjectOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v == null ? null : jsonAsObject(v, key);
}

/// Valeur d'enum obligatoire, lue par son code.
T jsonEnum<T>(
  Map<String, Object?> json,
  String key,
  T Function(String code) fromCode,
) {
  return fromCode(jsonString(json, key));
}

/// Valeur d'enum optionnelle.
T? jsonEnumOrNull<T>(
  Map<String, Object?> json,
  String key,
  T Function(String code) fromCode,
) {
  final v = json[key];
  return v == null ? null : fromCode(jsonAsString(v, key));
}

/// Objet typé obligatoire.
T jsonObj<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) fromJson,
) {
  return fromJson(jsonObject(json, key));
}

/// Objet typé optionnel.
T? jsonObjOrNull<T>(
  Map<String, Object?> json,
  String key,
  T Function(Map<String, Object?> json) fromJson,
) {
  final v = json[key];
  return v == null ? null : fromJson(jsonAsObject(v, key));
}

/// Liste obligatoire (non modifiable), chaque élément converti par [convert].
List<T> jsonList<T>(
  Map<String, Object?> json,
  String key,
  T Function(Object? value) convert,
) {
  final v = json[key];
  if (v is List<Object?>) {
    return List<T>.unmodifiable(v.map(convert));
  }
  _typeError(key, 'liste', v);
}

/// Liste optionnelle (clé absente ou nulle : `null`).
List<T>? jsonListOrNull<T>(
  Map<String, Object?> json,
  String key,
  T Function(Object? value) convert,
) {
  return json[key] == null ? null : jsonList(json, key, convert);
}

/// Copie canonique d'un objet JSON libre : clés triées à tous les niveaux,
/// pour que deux objets égaux s'écrivent à l'identique.
Map<String, Object?> jsonCanonical(Map<String, Object?> json) {
  final keys = json.keys.toList()..sort();
  return <String, Object?>{
    for (final key in keys) key: _canonicalValue(json[key]),
  };
}

Object? _canonicalValue(Object? value) {
  if (value is Map<String, Object?>) {
    return jsonCanonical(value);
  }
  if (value is List<Object?>) {
    return <Object?>[for (final item in value) _canonicalValue(item)];
  }
  return value;
}

/// Égalité profonde de deux valeurs JSON (objets, listes, scalaires) ou de
/// deux valeurs du contrat. Un entier et un décimal ne sont jamais égaux
/// (`2` ≠ `2.0`) : ils ne s'écrivent pas de la même façon.
bool jsonDeepEquals(Object? a, Object? b) {
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !jsonDeepEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<Object?> && b is List<Object?>) {
    return jsonListEquals(a, b);
  }
  if (a is num && b is num) {
    return (a is int) == (b is int) && a == b;
  }
  return a == b;
}

/// Égalité profonde de deux listes.
bool jsonListEquals(List<Object?> a, List<Object?> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (!jsonDeepEquals(a[i], b[i])) {
      return false;
    }
  }
  return true;
}

/// Code de hachage cohérent avec [jsonDeepEquals].
int jsonDeepHash(Object? value) {
  if (value is Map<String, Object?>) {
    return Object.hashAllUnordered(
      value.entries.map((e) => Object.hash(e.key, jsonDeepHash(e.value))),
    );
  }
  if (value is List<Object?>) {
    return Object.hashAll(value.map(jsonDeepHash));
  }
  return value.hashCode;
}

/// Signale une valeur numérique non finie ou hors de [min]..[max].
void checkRange(
  List<Violation> out,
  String path,
  num value,
  num? min,
  num? max,
) {
  if (value is double && !value.isFinite) {
    out.add(Violation(path, 'not_finite', 'nombre fini attendu'));
    return;
  }
  if (min != null && value < min) {
    out.add(Violation(path, 'below_min', '$value < $min'));
  }
  if (max != null && value > max) {
    out.add(Violation(path, 'above_max', '$value > $max'));
  }
}

/// Signale une longueur (texte ou liste) hors de [min]..[max].
void checkLength(
  List<Violation> out,
  String path,
  int length,
  int? min,
  int? max,
) {
  if (min != null && length < min) {
    out.add(Violation(path, 'too_short', 'longueur $length < $min'));
  }
  if (max != null && length > max) {
    out.add(Violation(path, 'too_long', 'longueur $length > $max'));
  }
}

/// Signale ce qui, dans [value], n'est pas du JSON (objet à clés texte,
/// liste, nombre fini, texte, booléen, nul).
void checkJson(List<Violation> out, String path, Object? value) {
  if (value == null || value is String || value is bool || value is int) {
    return;
  }
  if (value is double) {
    if (!value.isFinite) {
      out.add(Violation(path, 'not_finite', 'nombre fini attendu'));
    }
    return;
  }
  if (value is Map<String, Object?>) {
    for (final entry in value.entries) {
      checkJson(out, '$path.${entry.key}', entry.value);
    }
    return;
  }
  if (value is List<Object?>) {
    for (var i = 0; i < value.length; i++) {
      checkJson(out, '$path[$i]', value[i]);
    }
    return;
  }
  out.add(Violation(path, 'not_json', 'type ${value.runtimeType}'));
}

/// Signale les doublons de [values].
void checkDistinct<T>(List<Violation> out, String path, Iterable<T> values) {
  final seen = <T>{};
  for (final v in values) {
    if (!seen.add(v)) {
      out.add(Violation(path, 'duplicate', 'doublon : $v'));
    }
  }
}
