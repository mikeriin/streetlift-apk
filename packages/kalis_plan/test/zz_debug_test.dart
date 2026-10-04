// TEMPORAIRE : à retirer avant livraison.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('debug', () {
    final catalog = loadCatalog();
    for (final seed in <int>[9485, 9717]) {
      final request = randomCoachRequest(
        catalog,
        seed,
        planSeed: seed % 16 == 7 ? 1 : 0,
      );
      final engine = KalisPlan();
      final p1 = engine.createPass1(catalog, request);
      final p2 = engine.createPass2(
        catalog,
        Pass2Request(request: request, pass1: p1),
      );
      final profile = jsonEncode(request.profile.toJson());
      // ignore: avoid_print
      print('DBG $seed profil ${profile.length > 3000 ? profile.substring(0, 3000) : profile}');
      // ignore: avoid_print
      print('DBG $seed start ${request.startDate}');
      for (final w in p2.weeks) {
        for (final d in w.days) {
          // ignore: avoid_print
          print(
            'DBG $seed s${w.weekIndex} ${w.kind.code} j${d.dayIndex} '
            '${d.items.map((i) => '${i.exerciseId}x${i.sets}'
                '(${i.kind?.code ?? 'w'},${i.secondsHigh ?? i.repsHigh})').join(' ; ')}',
          );
        }
      }
    }
  });
}
