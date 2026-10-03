import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

void main() {
  // Table de la décision D5.3, recopiée telle quelle.
  const table = <int, double>{
    10: 0,
    9: 1,
    8: 1.5,
    7: 2,
    6: 2.5,
    5: 3,
    4: 3.5,
    3: 4,
    2: 4.5,
    1: 5,
  };

  test('flammes → RIR : table exacte de D5.3', () {
    for (final entry in table.entries) {
      expect(Flames.toRir(entry.key), entry.value, reason: '${entry.key}');
    }
    expect(Flames.min, 1);
    expect(Flames.max, 10);
    expect(Flames.failure, 10);
  });

  test('RIR → flammes : inverse exact sur l\'échelle', () {
    for (final entry in table.entries) {
      expect(Flames.fromRir(entry.value), entry.key, reason: '${entry.value}');
      expect(Flames.fromRir(Flames.toRir(entry.key)), entry.key);
    }
  });

  test('1 flamme = RIR 5 et plus ; seule note ouverte', () {
    expect(Flames.fromRir(5), 1);
    expect(Flames.fromRir(5.5), 1);
    expect(Flames.fromRir(12), 1);
    expect(Flames.fromRir(double.infinity), 1);
    for (var f = 1; f <= 10; f++) {
      expect(Flames.isOpenEnded(f), f == 1);
    }
  });

  test('RIR 0,5 (ancien journal) donne 9 flammes, jamais l\'échec', () {
    expect(Flames.fromRir(0.5), 9);
    expect(Flames.fromRir(0), 10);
  });

  test(
    'hors échelle : demi-point le plus proche, égalité vers le plus dur',
    () {
      expect(Flames.fromRir(0.2), 10);
      expect(Flames.fromRir(0.25), 10);
      expect(Flames.fromRir(0.3), 9);
      expect(Flames.fromRir(0.75), 9);
      expect(Flames.fromRir(1.2), 9);
      expect(Flames.fromRir(1.25), 9);
      expect(Flames.fromRir(1.3), 8);
      expect(Flames.fromRir(1.75), 8);
      expect(Flames.fromRir(4.75), 2);
      expect(Flames.fromRir(4.8), 1);
    },
  );

  test(
    'monotone : plus de réserve, jamais plus de flammes (10 000 tirages)',
    () {
      final r = Random(53);
      for (var i = 0; i < 10000; i++) {
        final a = r.nextDouble() * 7;
        final b = a + r.nextDouble() * 3;
        final fa = Flames.fromRir(a);
        final fb = Flames.fromRir(b);
        expect(Flames.isValid(fa), isTrue);
        expect(fb, lessThanOrEqualTo(fa), reason: '$a → $fa, $b → $fb');
        // L'aller-retour ne s'éloigne jamais de plus d'un quart de point
        // (hors RIR 0,5, absent de l'échelle, et au-delà de 5).
        if (a < 5 && (a < 0.25 || a >= 0.75)) {
          expect(
            (Flames.toRir(fa) - a).abs(),
            lessThanOrEqualTo(0.25 + 1e-9),
            reason: '$a',
          );
        }
      }
    },
  );

  test('valeurs refusées', () {
    expect(() => Flames.toRir(0), throwsArgumentError);
    expect(() => Flames.toRir(11), throwsArgumentError);
    expect(() => Flames.fromRir(-0.5), throwsArgumentError);
    expect(() => Flames.fromRir(double.nan), throwsArgumentError);
    expect(Flames.isValid(0), isFalse);
    expect(Flames.isValid(11), isFalse);
  });

  test('« pas de note » reste une absence, jamais une flamme', () {
    const unrated = SetRecord(
      exerciseId: 'sw-pompe',
      exerciseOrder: 0,
      setIndex: 0,
      kind: SetKind.work,
      reps: 12,
      success: true,
      excluded: false,
    );
    expect(unrated.flames, isNull);
    expect(unrated.isRated, isFalse);
    expect(unrated.toJson().containsKey('flames'), isFalse);
    expect(SetRecord.fromJson(unrated.toJson()).flames, isNull);
    expect(Flames.delta(actual: unrated.flames, target: 7), isNull);
    final rated = unrated.copyWith(flames: 9);
    expect(rated.isRated, isTrue);
    expect(rated.toJson()['flames'], 9);
    expect(Flames.delta(actual: rated.flames, target: 7), 2);
    expect(rated.copyWith(flames: null).flames, isNull);
    expect(rated.copyWith().flames, 9);
    expect(codesOf(unrated.copyWith(flames: 11).validate()), <String>[
      'above_max',
    ]);
    expect(codesOf(unrated.copyWith(flames: 0).validate()), <String>[
      'below_min',
    ]);
  });
}

List<String> codesOf(List<Violation> violations) => <String>[
  for (final v in violations) v.code,
];
