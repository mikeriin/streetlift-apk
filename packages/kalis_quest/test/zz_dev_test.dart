// Branche de contrôle seulement : formate le paquet et exporte les sources
// formatées dans out-packages/<paquet>/formatted (récupérées ensuite).
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('export des sources formatées', () {
    final name = Directory.current.path.split('/').last;
    final r = Process.runSync('dart', <String>['format', '.']);
    final out = Directory('../../out-packages/$name/formatted');
    out.createSync(recursive: true);
    File('${out.path}/format.log').writeAsStringSync('${r.stdout}\n${r.stderr}');
    for (final dir in <String>['lib', 'test', 'bin', 'tool']) {
      final d = Directory(dir);
      if (!d.existsSync()) {
        continue;
      }
      for (final f in d.listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          final target = File('${out.path}/${f.path}');
          target.parent.createSync(recursive: true);
          f.copySync(target.path);
        }
      }
    }
  });
}
