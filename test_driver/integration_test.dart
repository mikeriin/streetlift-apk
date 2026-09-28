// M1 (CI 3D) : pilote hôte de `flutter drive`. Le test d'intégration encode
// chaque capture PNG en Base64 dans reportData ; ce pilote les écrit dans
// build/ci3d/ (hors du bac à sable de l'application), même si le test
// échoue, pour que la CI les publie et qu'on puisse les regarder.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    if (data == null) return;
    final dir = Directory('build/ci3d')..createSync(recursive: true);
    data.forEach((name, value) {
      if (value is! String) return;
      final file = File('${dir.path}/$name');
      if (name.endsWith('.png')) {
        file.writeAsBytesSync(base64Decode(value));
      } else {
        file.writeAsStringSync(value);
      }
    });
  },
);
