// Accès aux données du paquet depuis les tests (`dart test` s'exécute à la
// racine du paquet).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';

/// Chemin du catalogue compilé.
const String catalogPath = 'data/catalog_v1.json.gz';

/// Chemin de la copie de la base source.
const String sourcePath = 'data/source/base_exercices_v1.1.0.json';

/// Octets JSON (décompressés) du catalogue.
List<int> catalogJsonBytes() =>
    gzip.decode(File(catalogPath).readAsBytesSync());

/// Catalogue chargé.
Catalog loadCatalog() => Catalog.fromJsonBytes(catalogJsonBytes());

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

/// Aller-retour par le texte JSON.
Map<String, Object?> viaJsonText(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

/// Codes des violations.
List<String> codesOf(List<Violation> violations) =>
    <String>[for (final v in violations) v.code];
