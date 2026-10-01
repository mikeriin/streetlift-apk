/// Briques des générateurs de valeurs aléatoires seedées (tests de
/// propriétés des contrats).
library;

import 'dart:math';

import '../civil_date.dart';
import '../json_util.dart';

/// Entier uniforme de [min] à [max] inclus.
int arbInt(Random r, int min, int max) => min + r.nextInt(max - min + 1);

/// Nombre de [min] à [max], au dix-millième.
double arbDouble(Random r, double min, double max) {
  final steps = r.nextInt(10001);
  return ((min + (max - min) * steps / 10000) * 10000).roundToDouble() / 10000;
}

const String _alphabet =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_'
    'éèàçùâêîôûëïüœÉÀ\'"\\/{}[]:,.\n\t€日本';

/// Texte de [minLength] à [maxLength] caractères, avec accents, guillemets
/// et caractères d'échappement JSON.
String arbString(Random r, int minLength, int maxLength) {
  final runes = _alphabet.runes.toList();
  final n = arbInt(r, minLength, maxLength);
  return String.fromCharCodes(<int>[
    for (var i = 0; i < n; i++) runes[r.nextInt(runes.length)],
  ]);
}

/// Identifiant au format de ceux du catalogue.
String arbId(Random r) {
  const letters = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final n = arbInt(r, 3, 14);
  final body = String.fromCharCodes(<int>[
    for (var i = 0; i < n; i++) letters.codeUnitAt(r.nextInt(letters.length)),
  ]);
  return 'x${r.nextInt(10)}-$body';
}

/// Jour civil entre 1990 et 2059.
CivilDate arbDate(Random r) =>
    CivilDate.fromDayNumber(arbInt(r, 7305, 32872));

/// Valeur d'une énumération.
T arbEnum<T>(Random r, List<T> values) => values[r.nextInt(values.length)];

/// Liste de [min] à [max] éléments.
List<T> arbList<T>(Random r, int min, int max, T Function() element) {
  final n = arbInt(r, min, max);
  return List<T>.unmodifiable(<T>[for (var i = 0; i < n; i++) element()]);
}

Object? _arbJsonValue(Random r, int depth) {
  switch (r.nextInt(depth > 1 ? 5 : 7)) {
    case 0:
      return r.nextInt(2001) - 1000;
    case 1:
      return arbDouble(r, -1000, 1000);
    case 2:
      return arbString(r, 0, 8);
    case 3:
      return r.nextBool();
    case 4:
      return null;
    case 5:
      return <Object?>[
        for (var i = 0, n = r.nextInt(3); i < n; i++)
          _arbJsonValue(r, depth + 1),
      ];
    default:
      return <String, Object?>{
        for (var i = 0, n = r.nextInt(3); i < n; i++)
          'k$i${arbString(r, 0, 3)}': _arbJsonValue(r, depth + 1),
      };
  }
}

/// Objet JSON libre (scalaires, listes et objets imbriqués).
Map<String, Object?> arbJson(Random r) {
  return <String, Object?>{
    for (var i = 0, n = r.nextInt(4); i < n; i++)
      'p$i': _arbJsonValue(r, 0),
  };
}

/// Générateur, encodeur, décodeur et validateur d'un type du contrat.
final class ContractCodec<T extends Object> {
  /// Codec du type nommé [name].
  const ContractCodec(
    this.name,
    this.arbitrary,
    this._toJson,
    this.fromJson,
    this._validate,
  );

  /// Nom du type.
  final String name;

  /// Valeur aléatoire.
  final T Function(Random r) arbitrary;

  /// Décodeur.
  final T Function(Map<String, Object?> json) fromJson;

  final Map<String, Object?> Function(T value) _toJson;
  final List<Violation> Function(T value) _validate;

  /// Objet JSON de [value] (qui doit être du type [T]).
  Map<String, Object?> toJson(Object value) => _toJson(value as T);

  /// Violations de [value] (qui doit être du type [T]).
  List<Violation> validate(Object value) => _validate(value as T);
}
