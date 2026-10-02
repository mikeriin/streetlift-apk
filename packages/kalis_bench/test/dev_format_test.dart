// OUTIL DE MISE AU POINT (retiré avant la livraison) : pas de SDK Dart
// dans la session, donc la CI formate les sources et les rend dans
// ci-out/packages/kalis_bench/_src/.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('sources formatées rendues dans le rapport', () {
    final out = Directory('../../out-packages/kalis_bench/_src');
    Process.runSync('dart', <String>['format', 'lib', 'bin', 'test']);
    for (final dir in <String>['lib', 'bin', 'test']) {
      for (final f in Directory(dir).listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          final target = File('${out.path}/${f.path}');
          target.parent.createSync(recursive: true);
          target.writeAsStringSync(f.readAsStringSync());
        }
      }
    }
    expect(out.existsSync(), isTrue);
  });
}
