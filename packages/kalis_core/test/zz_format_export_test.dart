// Fichier de la branche de contrôle seulement : formate les sources et les
// exporte dans ci-out pour que le lot récupère le formatage officiel.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('export du formatage', () {
    final result = Process.runSync('dart', <String>['format', '.']);
    final out = Directory('../../out-packages/kalis_core/formatted')
      ..createSync(recursive: true);
    File('${out.path}/_format.log')
        .writeAsStringSync('${result.stdout}\n${result.stderr}');
    for (final dir in <String>['lib', 'test', 'bin']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) {
          continue;
        }
        final target = File('${out.path}/${f.path}');
        target.parent.createSync(recursive: true);
        target.writeAsStringSync(f.readAsStringSync());
      }
    }
  });
}
