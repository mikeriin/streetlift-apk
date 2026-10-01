// Fichier de la branche de contrôle seulement : fait tourner l'ancien
// générateur L10 (qui dépend de Flutter) sur les 40 profils types et
// dépose ses sorties dans out-packages/kalis_plan/l10/.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('export des programmes L10', () {
    final out = Directory('../../out-packages/kalis_plan/l10')
      ..createSync(recursive: true);
    final result = Process.runSync('flutter', <String>[
      'test',
      'test/zz_l10_export_test.dart',
    ], workingDirectory: '../..');
    File('${out.path}/flutter.log').writeAsStringSync(
      'code ${result.exitCode}\n${result.stdout}\n${result.stderr}',
    );
    final json = File('${out.path}/l10_outputs.json');
    if (json.existsSync()) {
      File(
        '${out.path}/l10_outputs.json.gz',
      ).writeAsBytesSync(gzip.encode(json.readAsBytesSync()));
      json.deleteSync();
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
