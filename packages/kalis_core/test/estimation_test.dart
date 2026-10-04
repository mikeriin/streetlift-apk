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
      expect(
        estimateOneRm(loadKg: 100, reps: 5)!.valueKg,
        closeTo(112.5, 1e-9),
      );
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

    test('paliers d\'incertitude : 4 %, 5 %, 7,5 %, 10 %', () {
      double error(int reps, {double rir = 0, bool novice = false}) {
        return estimateOneRm(
          loadKg: 100,
          reps: reps,
          rir: rir,
          novice: novice,
        )!.relativeError;
      }

      // 4 % : maximum mesuré (1 répétition, réserve nulle), même chez un
      // novice.
      expect(error(1), 0.04);
      expect(error(1, novice: true), 0.04);
      final measured = estimateOneRm(loadKg: 100, reps: 1, novice: true)!;
      expect(measured.valueKg, 100);
      expect(measured.lowKg, closeTo(96, 1e-9));
      expect(measured.highKg, closeTo(104, 1e-9));
      // 5 % : série au maximum de 2 à 6 répétitions.
      for (var reps = 2; reps <= 6; reps++) {
        expect(error(reps), 0.05, reason: '$reps répétitions');
      }
      // 7,5 % : de 7 à 10 répétitions, ou une réserve déclarée.
      for (var reps = 7; reps <= 10; reps++) {
        expect(error(reps), 0.075, reason: '$reps répétitions');
      }
      expect(error(1, rir: 0.5), 0.075);
      expect(error(1, rir: 1), 0.075);
      expect(error(3, rir: 0.5), 0.075);
      expect(error(5, rir: 1), 0.075);
      expect(error(8, rir: 2), 0.075);
      // 10 % : novice, dès que la série a plusieurs répétitions ou une
      // réserve.
      for (var reps = 2; reps <= 10; reps++) {
        expect(error(reps, novice: true), 0.10, reason: '$reps répétitions');
      }
      expect(error(1, rir: 0.5, novice: true), 0.10);
      expect(error(1, rir: 2, novice: true), 0.10);
      expect(error(4, rir: 2, novice: true), 0.10);
      // Par défaut : pas novice, réserve nulle.
      expect(
        estimateOneRm(loadKg: 100, reps: 5)!.relativeError,
        error(5, rir: 0, novice: false),
      );
      // Le statut de novice ne change que l'incertitude, pas la valeur.
      expect(
        estimateOneRm(loadKg: 100, reps: 5, novice: true)!.valueKg,
        estimateOneRm(loadKg: 100, reps: 5)!.valueKg,
      );
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
      // Valeurs infinies.
      expect(estimateOneRm(loadKg: double.infinity, reps: 5), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 5, rir: double.infinity), isNull);
      // La borne : 10 répétitions réserve comprise, pas davantage.
      expect(estimateOneRm(loadKg: 100, reps: 10), isNotNull);
      expect(estimateOneRm(loadKg: 100, reps: 8, rir: 2), isNotNull);
      expect(estimateOneRm(loadKg: 100, reps: 10, rir: 0.5), isNull);
      // Le statut de novice n'élargit ni ne réduit le domaine.
      expect(estimateOneRm(loadKg: 100, reps: 11, novice: true), isNull);
      expect(estimateOneRm(loadKg: 100, reps: 10, novice: true), isNotNull);
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

    test('$samples tirages : un seul palier d\'incertitude par mesure', () {
      final r = Random(6003);
      const rirs = <double>[0, 0.5, 1, 1.5, 2, 3];
      var measured = 0;
      for (var i = 0; i < samples; i++) {
        final load = 1 + r.nextDouble() * 400;
        final reps = 1 + r.nextInt(10);
        final rir = rirs[r.nextInt(rirs.length)];
        final plain = estimateOneRm(loadKg: load, reps: reps, rir: rir);
        final novice = estimateOneRm(
          loadKg: load,
          reps: reps,
          rir: rir,
          novice: true,
        );
        if (reps + rir > 10) {
          expect(plain, isNull);
          expect(novice, isNull);
          continue;
        }
        expect(plain, isNotNull);
        expect(novice, isNotNull);
        // Même valeur ; un novice n'est jamais estimé plus précisément.
        expect(novice!.valueKg, plain!.valueKg);
        expect(novice.relativeError, greaterThanOrEqualTo(plain.relativeError));
        if (reps == 1 && rir == 0) {
          // Maximum mesuré : 4 %, novice ou non.
          expect(plain.relativeError, 0.04);
          expect(novice.relativeError, 0.04);
          expect(plain.valueKg, load);
          measured++;
        } else {
          expect(novice.relativeError, 0.10);
          expect(plain.relativeError, rir > 0 || reps + rir > 6 ? 0.075 : 0.05);
        }
        for (final e in <OneRmEstimate>[plain, novice]) {
          expect(e.lowKg, closeTo(e.valueKg * (1 - e.relativeError), 1e-9));
          expect(e.highKg, closeTo(e.valueKg * (1 + e.relativeError), 1e-9));
          expect(e.lowKg, lessThan(e.valueKg));
          expect(e.highKg, greaterThan(e.valueKg));
        }
      }
      expect(measured, greaterThan(0));
    });
  });

  group('course', () {
    test('formule de Riegel : valeurs de référence', () {
      // 5 km en 26 min → 10 km : 1560 × 2^1,06.
      final t = riegelSeconds(
        seconds: 1560,
        meters: 5000,
        targetMeters: 10000,
      )!;
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
      expect(
        riegelSeconds(seconds: 0, meters: 5000, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: -1, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: double.nan, meters: 5000, targetMeters: 10000),
        isNull,
      );
    });

    test('durée de départ hors domaine : refusée avant le calcul', () {
      // Effort de départ trop court ou trop long, alors que l'effort prédit
      // serait dans le domaine (100 s sur 1 km → environ 2 394 s sur 20 km ;
      // 14 000 s sur 10 km → environ 6 715 s sur 5 km).
      expect(100 * pow(20, 1.06), inInclusiveRange(210, 13800));
      expect(
        riegelSeconds(seconds: 100, meters: 1000, targetMeters: 20000),
        isNull,
      );
      expect(14000 * pow(0.5, 1.06), inInclusiveRange(210, 13800));
      expect(
        riegelSeconds(seconds: 14000, meters: 10000, targetMeters: 5000),
        isNull,
      );
      // Bornes de l'effort de départ : 3,5 minutes et 230 minutes, incluses.
      expect(
        riegelSeconds(seconds: 210, meters: 1000, targetMeters: 1000),
        closeTo(210, 1e-9),
      );
      expect(
        riegelSeconds(seconds: 209.9, meters: 1000, targetMeters: 1000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 13800, meters: 21000, targetMeters: 21000),
        closeTo(13800, 1e-6),
      );
      expect(
        riegelSeconds(seconds: 13800.1, meters: 21000, targetMeters: 21000),
        isNull,
      );
      // Durées négatives ou infinies.
      expect(
        riegelSeconds(seconds: -1560, meters: 5000, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(
          seconds: double.infinity,
          meters: 5000,
          targetMeters: 10000,
        ),
        isNull,
      );
    });

    test('effort prédit hors domaine : refusé', () {
      // Effort de départ dans le domaine, effort prédit trop court
      // (300 s sur 1 km → environ 114 s sur 400 m).
      expect(
        riegelSeconds(seconds: 300, meters: 1000, targetMeters: 400),
        isNull,
      );
      // … ou trop long (13 000 s sur 10 km → plus de 28 000 s sur 21 km).
      expect(
        riegelSeconds(seconds: 13000, meters: 10000, targetMeters: 21000),
        isNull,
      );
    });

    test('distances hors domaine : refusées avant le calcul', () {
      // Distance prédite : jusqu'au semi-marathon, borne incluse.
      final half = riegelSeconds(
        seconds: 3000,
        meters: 10000,
        targetMeters: 21097.5,
      );
      expect(half, isNotNull);
      expect(half, closeTo(3000 * pow(2.10975, 1.06), 1e-6));
      expect(
        riegelSeconds(seconds: 3000, meters: 10000, targetMeters: 21097.6),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 3000, meters: 10000, targetMeters: 42195),
        isNull,
      );
      // Distances nulles, négatives, infinies ou non numériques.
      expect(
        riegelSeconds(seconds: 1560, meters: 0, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: 0),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: -10000),
        isNull,
      );
      expect(
        riegelSeconds(
          seconds: 1560,
          meters: double.infinity,
          targetMeters: 10000,
        ),
        isNull,
      );
      expect(
        riegelSeconds(
          seconds: 1560,
          meters: 5000,
          targetMeters: double.infinity,
        ),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: double.nan, targetMeters: 10000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: 5000, targetMeters: double.nan),
        isNull,
      );
    });

    test('rapport de distances hors garde : refusé avant le calcul', () {
      // Rapport de plus de 1 000 ou de moins d'un millième.
      expect(
        riegelSeconds(seconds: 300, meters: 1, targetMeters: 1500),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 300, meters: 0.5, targetMeters: 21000),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 13000, meters: 21000000, targetMeters: 1000),
        isNull,
      );
      // Rapport qui déborde (infini) ou s'annule : aucune boucle sans fin
      // dans le calcul de la puissance, la fonction rend `null`.
      expect(
        riegelSeconds(
          seconds: 1560,
          meters: double.minPositive,
          targetMeters: 21000,
        ),
        isNull,
      );
      expect(
        riegelSeconds(seconds: 1560, meters: 1e300, targetMeters: 1e-300),
        isNull,
      );
      expect(
        riegelSeconds(
          seconds: 1560,
          meters: double.maxFinite,
          targetMeters: double.minPositive,
        ),
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

    test('$samples tirages dans et hors du domaine : refusée exactement '
        'hors du domaine', () {
      final r = Random(6004);
      var accepted = 0;
      var refused = 0;
      for (var i = 0; i < samples; i++) {
        final meters = 200 + r.nextDouble() * 29800;
        final target = 200 + r.nextDouble() * 29800;
        final seconds = 60 + r.nextDouble() * 17940;
        final t = riegelSeconds(
          seconds: seconds,
          meters: meters,
          targetMeters: target,
        );
        final reference = seconds * pow(target / meters, 1.06);
        final inDomain =
            target <= 21097.5 &&
            seconds >= 210 &&
            seconds <= 13800 &&
            reference >= 210 &&
            reference <= 13800;
        if (!inDomain) {
          expect(t, isNull);
          refused++;
          continue;
        }
        expect(t, isNotNull);
        expect(t! / reference, closeTo(1, 1e-12));
        expect(t, inInclusiveRange(210, 13800));
        accepted++;
        // Plus loin, plus long ; plus près, plus court.
        if (target > meters) {
          expect(t, greaterThan(seconds));
        }
        if (target < meters) {
          expect(t, lessThan(seconds));
        }
      }
      expect(accepted, greaterThan(samples ~/ 10));
      expect(refused, greaterThan(samples ~/ 10));
    });

    test('vitesse d\'un test en durée fixe', () {
      expect(trialSpeed(meters: 1500, seconds: 360), closeTo(4.1667, 1e-4));
      expect(trialSpeed(meters: 0, seconds: 360), isNull);
      expect(trialSpeed(meters: 1500, seconds: 0), isNull);
      // Valeurs négatives, infinies ou non numériques.
      expect(trialSpeed(meters: -1500, seconds: 360), isNull);
      expect(trialSpeed(meters: 1500, seconds: -360), isNull);
      expect(trialSpeed(meters: double.infinity, seconds: 360), isNull);
      expect(trialSpeed(meters: 1500, seconds: double.infinity), isNull);
      expect(trialSpeed(meters: double.nan, seconds: 360), isNull);
      expect(trialSpeed(meters: 1500, seconds: double.nan), isNull);
    });
  });
}
