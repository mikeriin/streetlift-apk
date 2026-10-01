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
    final inspector = PlanInspector(catalog);
    final out = Directory('../../out-packages/kalis_plan/dev')
      ..createSync(recursive: true);
    final log = StringBuffer();
    final times = StringBuffer();
    for (final fixture in loadProfiles()) {
      final watch = Stopwatch()..start();
      try {
        final request = requestFor(fixture.profile);
        final fresh = KalisPlan();
        final p1 = fresh.createPass1(catalog, request);
        final t1 = watch.elapsedMicroseconds;
        final c = runProfileCase(catalog, engine, fixture);
        watch.stop();
        times.writeln('  ${inspector.explainProfile(request)}');
        for (final id in <String>[
          'cs-planche-tuck',
          'sl-muscle-up-leste',
          'sl-squat-competition',
          'mu-air-squat',
          'ca-sortie-longue',
          'mu-developpe-couche-barre',
        ]) {
          times.writeln('  $id : ${inspector.rejectionOf(request, id)}');
        }
        times.writeln(
          '${fixture.key} : passe 1 ${(t1 / 1000).toStringAsFixed(1)} ms ; '
          'cas complet ${watch.elapsedMilliseconds} ms ; '
          '${p1.days.fold<int>(0, (n, d) => n + d.slots.length)} exercices ; '
          'violations ${inspector.hardViolations(request, p1)}',
        );
        log.writeln(profileCaseLines(catalog, c, 0).join('\n'));
        times.writeln(inspector.whatIfAdd(request, p1).join('\n'));
      } on Object catch (e, s) {
        final trace = s.toString().split('\n').take(8).join('\n');
        times.writeln('${fixture.key} : ERREUR $e\n$trace');
      }
    }
    File('${out.path}/cas.md').writeAsStringSync(log.toString());
    File('${out.path}/temps.txt').writeAsStringSync(times.toString());
  }, timeout: const Timeout(Duration(minutes: 20)));
}
