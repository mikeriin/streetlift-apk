// ignore_for_file: avoid_print
// Fichier temporaire de diagnostic (CP2, partie 1) : retiré avant la
// publication.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('diagnostic des autres disciplines', () {
    final catalog = loadCatalog();
    final engine = KalisPlan();
    for (final seed in const <int>[2282, 2170, 1221]) {
      final request = randomGeneralRequest(
        catalog,
        seed,
        planSeed: seed % 16 == 7 ? 1 : 0,
      );
      final p = request.profile;
      final p1 = engine.createPass1(catalog, request);
      final p2 = engine.createPass2(
        catalog,
        Pass2Request(request: request, pass1: p1),
      );
      print(
        'DIAG seed $seed : ${p.disciplines.primary.name} '
        '${p.disciplines.secondaries.map((s) => '${s.discipline.name} ${s.pct}').join(',')} '
        'exp ${p.experience?.name} gap ${p.trainingGap != null} '
        'minutes ${p.availability.map((d) => d.minutes).join('/')} '
        'emph ${p.emphasis?.name} intent ${p1.intent != null}',
      );
      for (final w in p2.weeks.where((w) => w.weekIndex < 2 || w.days.any((d) => d.items.any((i) => i.kind == SetKind.test)))) {
        for (final d in w.days) {
          final s = coachSessionSeconds(
            catalog,
            d,
            minutes: p.availability[d.dayIndex].minutes,
          );
          print('DIAG  s${w.weekIndex} j${d.dayIndex} ${(s / 60).round()} min');
          for (final i in d.items) {
            final notes = i.reasons
                .where((r) => r.params['note'] != null)
                .map((r) => r.params['note'])
                .join('+');
            print(
              'DIAG    ${i.exerciseId} ${i.kind?.name} ${i.sets}x'
              '${i.repsLow}-${i.repsHigh} s${i.secondsLow}-${i.secondsHigh} '
              'd${i.distanceMeters} r${i.restSeconds} ${i.format ?? ''} '
              '${i.groupId ?? ''} ${i.intensity?.toJson()} $notes',
            );
          }
        }
      }
    }
  });
}
