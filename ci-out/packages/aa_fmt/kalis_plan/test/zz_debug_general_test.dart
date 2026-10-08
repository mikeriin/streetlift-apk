// ignore_for_file: avoid_print
// Fichier temporaire de diagnostic (CP2, partie 1) : retiré avant la
// publication.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('diagnostic des courses', () {
    final catalog = loadCatalog();
    final engine = KalisPlan();
    for (final seed in const <int>[7770, 9846]) {
      final request = randomGeneralRequest(
        catalog,
        seed,
        planSeed: seed % 16 == 7 ? 1 : 0,
      );
      final p = request.profile;
      final p2 = engine.createPass2(
        catalog,
        Pass2Request(
          request: request,
          pass1: engine.createPass1(catalog, request),
        ),
      );
      print(
        'DIAG seed $seed ${p.disciplines.primary.name} '
        '${p.disciplines.secondaries.map((s) => s.discipline.name).join(',')} '
        '${p.experience?.name} ${p.availability.map((d) => d.minutes).join('/')} '
        '${p.benchmarks?.map((b) => '${b.exerciseId}:${b.seconds}').join(',')}',
      );
      for (final w in p2.weeks) {
        for (final d in w.days) {
          for (final i in d.items) {
            if (i.exerciseId.startsWith('ca-')) {
              print(
                'DIAG  s${w.weekIndex} ${w.kind.name} j${d.dayIndex} '
                '${i.exerciseId} ${i.kind?.name} ${i.sets}x'
                '${i.secondsHigh} d${i.distanceMeters} ${i.slotId} '
                '${i.reasons.map((r) => r.params['note']).whereType<Object>().join('+')}',
              );
            }
          }
        }
      }
    }
  });
}
