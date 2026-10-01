// Fichier de la branche de contrôle seulement : formate les sources,
// exporte le formatage officiel et un relevé de mise au point dans ci-out.
import 'dart:io';

import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('export du formatage', () {
    final result = Process.runSync('dart', <String>['format', '.']);
    final out = Directory('../../out-packages/kalis_plan/formatted')
      ..createSync(recursive: true);
    File(
      '${out.path}/_format.log',
    ).writeAsStringSync('${result.stdout}\n${result.stderr}');
    for (final dir in <String>['lib', 'test', 'bin']) {
      if (!Directory(dir).existsSync()) {
        continue;
      }
      for (final f in Directory(
        dir,
      ).listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) {
          continue;
        }
        final target = File('${out.path}/${f.path}');
        target.parent.createSync(recursive: true);
        target.writeAsStringSync(f.readAsStringSync());
      }
    }
  });

  test('relevé de mise au point', () {
    final catalog = loadCatalog();
    final engine = KalisPlan();
    final out = Directory('../../out-packages/kalis_plan/dev')
      ..createSync(recursive: true);
    final log = StringBuffer();
    for (final fixture in loadProfiles()) {
      final watch = Stopwatch()..start();
      try {
        final c = runProfileCase(catalog, engine, fixture);
        watch.stop();
        log.writeln('${fixture.key} : ${watch.elapsedMilliseconds} ms');
        log.writeln(profileCaseLines(catalog, c, 0).join('\n'));
      } on Object catch (e, s) {
        log.writeln('${fixture.key} : ERREUR $e\n$s');
      }
    }
    File('${out.path}/cas.md').writeAsStringSync(log.toString());
  }, timeout: const Timeout(Duration(minutes: 20)));
}
