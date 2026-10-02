// Ancien pack 2.0.0 lu depuis le disque (fonction pure, sans Flutter) pour
// les tests de L11 (échanges d'exercice) jusqu'à son retrait en G10. Le
// générateur L10 et ses données de test sont retirés par G7.
import 'dart:convert';
import 'dart:io';

import 'package:streetlift_tracker/legacy_pack.dart';

Map<String, dynamic> readGz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

class L10Data {
  final GenCatalog catalog;
  L10Data(this.catalog);

  static L10Data? _cached;
  static L10Data load() => _cached ??= L10Data(
    GenCatalog.fromContent(
      index: readGz('assets/content/index.json.gz'),
      details: readGz('assets/content/details.json.gz'),
      progressions: readGz('assets/content/progressions.json.gz'),
    ),
  );
}
