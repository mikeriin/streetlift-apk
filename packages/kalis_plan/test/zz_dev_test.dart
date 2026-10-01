// Fichier de la branche de contrôle seulement : formate les sources,
// exporte le formatage officiel et un relevé de mise au point dans ci-out.
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:kalis_plan/testing.dart';
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

  test('diagnostic des graines en échec', () {
    final catalog = loadCatalog();
    final inspector = PlanInspector(catalog);
    final out = Directory('../../out-packages/kalis_plan/dev')
      ..createSync(recursive: true);
    final b = StringBuffer();
    String days(Pass1Plan p) => p.days
        .map(
          (d) =>
              'j${d.dayIndex}(${d.minutesBudget}min ${d.weekday}): '
              '${d.slots.map((s) => '${s.slotId}=${s.exerciseId}${s.locked ? '*' : ''}').join(', ')}',
        )
        .join('\n    ');
    for (final seed in <int>[7402, 7546, 681, 3859, 1458, 1496]) {
      try {
        final request = randomRequest(catalog, seed);
        final engine = KalisPlan();
        b.writeln('== graine $seed : ${profileLine(request.profile)}');
        b.writeln('  matériel ${request.profile.equipment}');
        b.writeln('  ${inspector.explainProfile(request)}');
        final p1 = engine.createPass1(catalog, request);
        b.writeln('  passe 1 :\n    ${days(p1)}');
        b.writeln('  violations ${inspector.hardViolations(request, p1)}');
        final slots = <(int, PlanSlot)>[
          for (final d in p1.days)
            for (final s in d.slots) (d.dayIndex, s),
        ];
        if (slots.isEmpty) {
          continue;
        }
        final (_, slot) = slots[fnv1a32('$seed:revue') % slots.length];
        final kind = ReviewKind.values[seed % ReviewKind.values.length];
        b.writeln('  action ${kind.code} sur ${slot.slotId}');
        if (kind == ReviewKind.remove) {
          final trace = engine.reviewTraced(
            catalog,
            ReviewRequest(
              request: request,
              current: p1,
              action: ReviewAction(kind: kind, slotId: slot.slotId),
            ),
          );
          final next = request.copyWith(
            profile: trace.profile,
            locks: trace.result.locks,
          );
          b.writeln('  référence :\n    ${days(trace.reference)}');
          b.writeln('  résultat :\n    ${days(trace.result.plan)}');
          for (final (name, plan) in <(String, Pass1Plan)>[
            ('référence', trace.reference),
            ('résultat', trace.result.plan),
          ]) {
            final score = inspector.scoreOf(next, plan);
            b.writeln(
              '  $name : objectif '
              '${inspector.objective(next, plan, reference: trace.reference)} '
              'sans pénalité ${inspector.objective(next, plan)} '
              'changements ${PlanInspector.changesBetween(trace.reference, plan)} '
              'note ${score.total} '
              '${score.components.map((c) => '${c.code.substring(0, 4)} ${c.value.toStringAsFixed(3)}').join(' ')}',
            );
          }
          b.writeln(
            '  violations de la référence '
            '${inspector.hardViolations(next, trace.reference)}',
          );
        }
      } on Object catch (e, st) {
        b.writeln(
          '  ERREUR $e\n${st.toString().split('\n').take(8).join('\n')}',
        );
      }
    }
    for (final seed in <int>[1429]) {
      final request = randomRequest(catalog, seed);
      final engine = KalisPlan();
      b.writeln('== restructuration, graine $seed : '
          '${profileLine(request.profile)}');
      b.writeln('  ${inspector.explainProfile(request)}');
      final p1 = engine.createPass1(catalog, request);
      b.writeln('  passe 1 :\n    ${days(p1)}');
      final p2 = engine.createPass2(
        catalog,
        Pass2Request(request: request, pass1: p1),
      );
      final block = ProgramBlock(pass1: p1, pass2: p2);
      for (final r in <Reason>[
        const Reason(
          code: ReasonCodes.adaptPainReported,
          params: <String, Object?>{'zone': 'knee', 'intensity': 5},
        ),
        const Reason(
          code: ReasonCodes.adaptFatigueHigh,
          params: <String, Object?>{'readiness': 0.3},
        ),
      ]) {
        final rr = RestructureRequest(
          profile: request.profile,
          seed: 0,
          today: p1.startDate.addDays(7),
          current: block,
          scope: RestructureScope.block,
          fromWeekIndex: 1,
          reasons: <Reason>[r],
          locks: request.locks,
        );
        final after = engine.restructure(catalog, rr).block.pass1;
        b.writeln('  ${r.code} :\n    ${days(after)}');
        b.writeln('  relu : ${inspector.restructureViolations(rr, after)}');
        b.writeln('  relu sans le contexte : '
            '${inspector.hardViolations(request, after)}');
      }
    }
    File('${out.path}/graines.txt').writeAsStringSync(b.toString());
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
