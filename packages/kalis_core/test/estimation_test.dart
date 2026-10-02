// Conversions des tests guidés (0.4.0) : estimation du 1RM (Brzycki),
// charge totale et lest, prédiction de temps de course (Riegel).
@Timeout(Duration(minutes: 30))
library;

import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

const int samples = 10000;

void main() {
  group('estimation du 1RM', () {
    test('valeurs de référence de l\'équation de Brzycki', () {
      // Coefficients 36 / (37 − r) : 3 → 1,059 ; 5 → 1,125 ; 6 → 1,161.
      expect(estimateOneRm(loadKg: 100, reps: 5)!.valueKg, closeTo(112.5, 1e-9));
      expect(
        estimateOneRm(loadKg: 100, reps: 3)!.valueKg,
        closeTo(105.882, 1e-3),
      );
      expect(
        estimateOneRm(loadKg: 100, reps: 6)!.valueKg,
        closeTo(116.129, 1e-3),
      );
      expect(
        estimateOneRm(loadKg: 100, reps: 10)!.valueKg,
        closeTo(133.333, 1e-3),
      );
      // Une répétition au maximum : la charge elle-même.
      expect(estimateOneRm(loadKg: 140, reps: 1)!.valueKg, 140);
    });

    test('réserve déclarée : comptée comme des répétitions', () {
      final withRir = estimateOneRm(loadKg: 100, reps: 4, rir: 1)!;
      final toFailure = estimateOneRm(loadKg: 100, reps: 5)!;
      expect(withRir.valueKg, closeTo(toFailure.valueKg, 1e-9));
      expect(withRir.relativeError, greaterThan(toFailure.relativeError));
      // Demi-répétitions en réserve (échelle des flammes).
      expect(
        estimateOneRm(loadKg: 100, reps: 4, rir: 1.5)!.valueKg,
        closeTo(100 * 36 / 31.5, 1e-9),
      );
    });

    test('incertitude selon la mesure', () {
      expect(estimateOneRm(loadKg: 100, reps: 1)!.relativeError, 0.04);
      expect(estimateOneRm(loadKg: 100, reps: 5)!.relativeError, 0.05);
      expect(estimateOneRm(loadKg: 100, reps: 8)!.relativeError, 0.075);
      expect(estimateOneRm(loadKg: 100, reps: 4, rir: 2)!.relativeError, 0.075);
      expect(
        estimateOneRm(loadKg: 100, reps: 5, novice: true)!.relativeError,
        0.10,
      );
      final e = estimateOneRm(loadKg: 100, reps: 5)!;
      expect(e.lowKg, closeTo(112.5 * 0.95, 1e-9));
      expect(e.highKg, closeTo(112.5 * 1.05, 1e-9));
    });

    test('refusée hors du domaine défendable', () {
      expect(estimateOneRm(loadKg: 100, reps: 11), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 9, rir: 2), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 0), isNull);
      expect(estimateOneRm(loadKg: 0, reps: 5), isNull);
      expect(estimateOneRm(loadKg: -10, reps: 5), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 5, rir: -1), isNull);
      expect(estimateOneRm(loadKg: double.nan, reps: 5), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 5, rir: double.nan), isNull);
    });

    test('exercice lesté : équation sur la charge totale, puis le lest', () {
      // 80 kg de poids de corps, 5 tractions à +20 kg, fraction 0,97.
      final total = totalFromExternal(
        externalKg: 20,
        bodyWeightKg: 80,
        bodyweightFraction: 0.97,
      );
      expect(total, closeTo(97.6, 1e-9));
      final max = estimateOneRm(loadKg: total, reps: 5)!;
      final lest = externalFromTotal(
        totalKg: max.valueKg,
        bodyWeightKg: 80,
        bodyweightFraction: 0.97,
      );
      expect(lest, closeTo(97.6 * 1.125 - 77.6, 1e-9));
      // L'incertitude porte sur la charge totale : elle est amplifiée sur
      // le lest.
      final spread =
          externalFromTotal(
            totalKg: max.highKg,
            bodyWeightKg: 80,
            bodyweightFraction: 0.97,
          ) -
          lest;
      expect(spread / lest, greaterThan(0.15));
    });

    test('$samples tirages : monotone, bornée, jamais sous la charge', () {
      final r = Random(6001);
      for (var i = 0; i < samples; i++) {
        final load = 1 + r.nextDouble() * 400;
        final reps = 1 + r.nextInt(10);
        final rir = r.nextInt(3) * 0.5;
        final e = estimateOneRm(loadKg: load, reps: reps, rir: rir);
        if (reps + rir > 10) {
          expect(e, isNull);
          continue;
        }
        expect(e, isNotNull);
        expect(e!.valueKg, greaterThanOrEqualTo(load));
        expect(e.valueKg, lessThanOrEqualTo(load * 36 / 27 + 1e-9));
        expect(e.relativeError, inInclusiveRange(0.04, 0.10));
        if (reps + rir + 1 <= 10) {
          final more = estimateOneRm(loadKg: load, reps: reps + 1, rir: rir)!;
          expect(more.valueKg, greaterThan(e.valueKg));
        }
        final heavier = estimateOneRm(loadKg: load + 1, reps: reps, rir: rir)!;
        expect(heavier.valueKg, greaterThan(e.valueKg));
        final a = totalFromExternal(
          externalKg: load,
          bodyWeightKg: 70,
          bodyweightFraction: 0.96,
        );
        expect(
          externalFromTotal(
            totalKg: a,
            bodyWeightKg: 70,
            bodyweightFraction: 0.96,
          ),
          closeTo(load, 1e-9),
        );
      }
    });
  });

  group('course', () {
    test('formule de Riegel : valeurs de référence', () {
      // 5 km en 26 min → 10 km : 1560 × 2^1,06.
      final t = riegelSeconds(seconds: 1560, meters: 5000, targetMeters: 10000)!;
      expect(t, closeTo(1560 * pow(2, 1.06), 1e-6));
      expect(t, closeTo(3252.5, 0.5));
      // Même distance : même temps.
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: 5000),
        closeTo(1560, 1e-9),
      );
    });

    test('refusée hors du domaine calibré', () {
      // Au-delà du semi-marathon.
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: 42195),
        isNull,
      );
      // Effort de moins de 3,5 minutes.
      expect(
        riegelSeconds(seconds: 180, meters: 1000, targetMeters: 5000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: 400),
        isNull,
      );
      expect(riegelSeconds(seconds: 0, meters: 5000, targetMeters: 10000), isNull);
      expect(
        riegelSeconds(seconds: 1560, meters: -1, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: double.nan, meters: 5000, targetMeters: 10000),
        isNull,
      );
    });

    test('$samples tirages : égale à la formule calculée par dart:math', () {
      final r = Random(6002);
      var compared = 0;
      for (var i = 0; i < samples; i++) {
        final meters = 1000 + r.nextDouble() * 20000;
        final target = 1000 + r.nextDouble() * 20000;
        final seconds = 240 + r.nextDouble() * 9000;
        final t = riegelSeconds(
          seconds: seconds,
          meters: meters,
          targetMeters: target,
        );
        final reference = seconds * pow(target / meters, 1.06);
        if (reference < 210 || reference > 13800) {
          expect(t, isNull);
          continue;
        }
        expect(t, isNotNull);
        expect(t! / reference, closeTo(1, 1e-12));
        compared++;
        // Plus loin, plus long.
        if (target > meters) {
          expect(t, greaterThan(seconds));
        }
      }
      expect(compared, greaterThan(samples ~/ 2));
    });

    test('vitesse d\'un test en durée fixe', () {
      expect(trialSpeed(meters: 1500, seconds: 360), closeTo(4.1667, 1e-4));
      expect(trialSpeed(meters: 0, seconds: 360), isNull);
      expect(trialSpeed(meters: 1500, seconds: 0), isNull);
    });
  });
}
