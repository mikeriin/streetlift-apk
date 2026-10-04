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
    // Copie de travail dans le paquet : même version de langage et mêmes
    // options que le contrôle de formatage.
    final work = Directory('fmtwork');
    if (work.existsSync()) {
      work.deleteSync(recursive: true);
    }
    work.createSync();
    final copied = <String>[];
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
          final to = File('${work.path}/${f.path}');
          to.parent.createSync(recursive: true);
          f.copySync(to.path);
          copied.add(f.path);
        }
      }
    }
    final result = Process.runSync('dart', <String>['format', work.path]);
    stdout.writeln(result.stdout);
    stdout.writeln(result.stderr);
    for (final path in copied) {
      final from = File('${work.path}/$path');
      if (from.readAsStringSync() != File(path).readAsStringSync()) {
        final to = File('${out.path}/$path');
        to.parent.createSync(recursive: true);
        from.copySync(to.path);
      }
    }
    work.deleteSync(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
