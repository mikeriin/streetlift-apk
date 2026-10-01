// TEMPORAIRE (branche de contrôle uniquement) : écrit la version formatée
// des fichiers qui diffèrent, pour corriger le formatage sans SDK local.
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  test('dump format', () {
    final f = DartFormatter(languageVersion: Version(3, 10, 0));
    final out = Directory('../../out-packages/kalis_koach/formatted');
    final changed = <String>[];
    for (final d in ['lib', 'bin', 'test']) {
      for (final e in Directory(d).listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final src = e.readAsStringSync();
        String res;
        try {
          res = f.format(src, uri: e.path);
        } catch (err) {
          changed.add('ERREUR ${e.path}: $err');
          continue;
        }
        if (res != src) {
          changed.add(e.path);
          final o = File('${out.path}/${e.path}')..createSync(recursive: true);
          o.writeAsStringSync(res);
        }
      }
    }
    out.createSync(recursive: true);
    File('${out.path}/LISTE.txt').writeAsStringSync(changed.join('\n'));
  });
}
