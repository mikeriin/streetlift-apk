// Mise au point (contrôle rapide seulement) : les sources formatées par
// `dart format` sont recopiées dans le dossier de sortie du contrôle.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('sources formatées', () {
    final name = Directory.current.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
    );
    final root = Directory('../../out-packages/$name');
    if (!root.existsSync()) {
      return;
    }
    final out = Directory('${root.path}/fmt')..createSync(recursive: true);
    for (final top in <String>['lib', 'test', 'bin', 'tool']) {
      final dir = Directory(top);
      if (!dir.existsSync()) {
        continue;
      }
      for (final f in dir.listSync(recursive: true)) {
        if (f is File &&
            f.path.endsWith('.dart') &&
            !f.path.contains('koach_engine') &&
            !f.path.contains('zz_fmt')) {
          final to = File('${out.path}/${f.path}');
          to.parent.createSync(recursive: true);
          f.copySync(to.path);
        }
      }
    }
    final result = Process.runSync('dart', <String>['format', out.path]);
    stdout.writeln(result.stderr);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
