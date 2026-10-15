// Accès aux données de kalis_core depuis les tests (`dart test` s'exécute à
// la racine du paquet ; kalis_core est le dossier voisin).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';

/// Racine du paquet kalis_core.
const String corePath = '../kalis_core';

Catalog? _catalog;

/// Catalogue chargé (une fois par fichier de test).
Catalog loadCatalog() => _catalog ??= Catalog.fromJsonBytes(
  gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
);

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

/// Les 40 profils types de kalis_core.
List<ProfileFixture> loadProfiles() => readProfileFixtures(
  readJsonObject('$corePath/test/fixtures/profiles.json'),
);

/// Profil type de clé [key].
ProfileFixture profileOf(String key) =>
    loadProfiles().firstWhere((p) => p.key == key);

/// Requête de création du profil [profile].
PlanRequest requestFor(
  AthleteProfile profile, {
  int seed = 0,
  List<PlanLock> locks = const <PlanLock>[],
}) {
  return PlanRequest(
    profile: profile,
    seed: seed,
    startDate: CivilDate(2026, 10, 5),
    locks: locks,
  );
}

/// Texte JSON canonique d'un objet du contrat.
String jsonText(Map<String, Object?> json) => jsonEncode(json);
