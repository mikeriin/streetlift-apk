// L7 — Koach : moteur (KT-026, KT-027, KT-028, KT-030, KT-031, KT-032).
//
// 1. Recoupement avec la référence Python : chaque fixture de
//    `test/fixtures/koach/` contient des entrées et les sorties calculées par
//    `tools/koach_reference.py` ; le moteur Dart doit donner les mêmes
//    valeurs à 0,01 près et les mêmes décisions.
// 2. Règles chiffrées de la demande (D24, D25, D23, échelle héritée).
// 3. Rejeu complet = cache incrémental.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/koach_engine.dart';

Map<String, dynamic> _load(String name) =>
    jsonDecode(File('test/fixtures/koach/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Égalité profonde : nombres à 0,01 près, le reste exact.
void _same(Object? expected, Object? actual, String path) {
  if (expected is num || actual is num) {
    expect(actual, isA<num>(), reason: '$path : nombre attendu ($expected)');
    expect(expected, isA<num>(), reason: '$path : $actual inattendu');
    expect(
      ((actual as num) - (expected as num)).abs(),
      lessThanOrEqualTo(0.01 + 1e-9),
      reason: '$path : Dart $actual, Python $expected',
    );
    return;
  }
  if (expected is Map) {
    expect(actual, isA<Map>(), reason: '$path : objet attendu');
    final a = actual as Map;
    expect(
      a.keys.map((k) => '$k').toSet(),
      expected.keys.map((k) => '$k').toSet(),
      reason: '$path : clés',
    );
    for (final k in expected.keys) {
      _same(expected[k], a[k], '$path.$k');
    }
    return;
  }
  if (expected is List) {
    expect(actual, isA<List>(), reason: '$path : liste attendue');
    final a = actual as List;
    expect(a.length, expected.length, reason: '$path : longueur');
    for (var i = 0; i < expected.length; i++) {
      _same(expected[i], a[i], '$path[$i]');
    }
    return;
  }
  expect(actual, expected, reason: path);
}

void main() {
  group('Recoupement Dart / Python (fixtures partagées)', () {
    final files =
        Directory('test/fixtures/koach')
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .map((f) => f.uri.pathSegments.last)
            .toList()
          ..sort();

    test('les fixtures sont présentes', () {
      expect(files.length, greaterThanOrEqualTo(20));
    });

    for (final name in files) {
      test(name, () {
        final kase = _load(name);
        final expected = kase['expected'] as Map<String, dynamic>;
        final actual = runCase(kase);
        _same(expected, jsonDecode(jsonEncode(actual)), name);
      });
    }
  });

  group('D24 — exemples chiffrés de la demande (poids du corps 71,5 kg)', () {
    const p = koachParams;
    KSuggestion? after(double kg, int rir, bool body, double grid) => inSession(
      p,
      {'bodyweight': body},
      [
        {'kg': kg, 'reps': 4, 'rir': rir},
      ],
      2,
      4,
      body ? 71.5 : null,
      grid,
      const {},
    );

    test('traction +32,5 → +35 (cible + 1) ou +37,5 (cible + 2)', () {
      expect(after(32.5, 3, true, 1.25)!.kg, 35.0);
      expect(after(32.5, 4, true, 1.25)!.kg, 37.5);
      expect(after(32.5, 5, true, 1.25)!.kg, 37.5); // plafond +5 kg
      expect(after(32.5, 2, true, 1.25), isNull); // RIR visé : rien
    });

    test('muscle-up +5 → +6,25 ou +8,75', () {
      expect(after(5.0, 3, true, 1.25)!.kg, 6.25);
      expect(after(5.0, 4, true, 1.25)!.kg, 8.75);
    });

    test('squat 97,5 → 100 ou 102,5', () {
      expect(after(97.5, 3, false, 2.5)!.kg, 100.0);
      expect(after(97.5, 4, false, 2.5)!.kg, 102.5);
    });

    test('baisses : deux séries dures, série ratée (−3 % / −6 %)', () {
      final two = inSession(
        p,
        {'bodyweight': true},
        [
          {'kg': 32.5, 'reps': 4, 'rir': 1},
          {'kg': 32.5, 'reps': 4, 'rir': 1},
        ],
        2,
        4,
        71.5,
        1.25,
        const {},
      );
      expect(two!.kg, 30.0);
      expect(two.reason, 'twoHard');
      final one = inSession(
        p,
        {'bodyweight': true},
        [
          {'kg': 32.5, 'reps': 4, 'rir': 0},
        ],
        2,
        4,
        71.5,
        1.25,
        const {},
      );
      expect(
        one,
        isNull,
        reason: 'une seule série dure : peut être un incident',
      );
      final missed = inSession(
        p,
        {'bodyweight': true},
        [
          {'kg': 32.5, 'reps': 3, 'rir': 0},
        ],
        2,
        4,
        71.5,
        1.25,
        const {},
      );
      expect(missed!.kg, 30.0);
      final missed2 = inSession(
        p,
        {'bodyweight': true},
        [
          {'kg': 32.5, 'reps': 2, 'rir': 0},
        ],
        2,
        4,
        71.5,
        1.25,
        const {},
      );
      expect(missed2!.kg, 27.5);
      expect(missed2.reason, 'missed2');
    });

    test('décharge, douleur, verrou, refus : aucune hausse', () {
      for (final flags in <Map<String, dynamic>>[
        {'deload': true},
        {'pain': true},
        {'fatigue': true},
        {'locked': true},
        {
          'refused': ['up'],
        },
      ]) {
        expect(
          inSession(
            p,
            {'bodyweight': true},
            [
              {'kg': 32.5, 'reps': 4, 'rir': 4},
            ],
            2,
            4,
            71.5,
            1.25,
            flags,
          ),
          isNull,
          reason: '$flags',
        );
      }
    });
  });

  group('D25 — jour de fatigue', () {
    const p = koachParams;
    double level(
      double mass,
      int reps,
      double rir, {
      double? sleep,
      double? form,
    }) => fatigueLevel(
      p,
      110,
      mass,
      reps,
      rir,
      0,
      22.4,
      sleep: sleep,
      form: form,
    );

    test('bandes −5 / −7,5 / −10 % et questionnaire', () {
      // 1RM de la série 1 = masse × (1 + (n − 1) / 22,4).
      double massFor(double gap) => 110 * (1 + gap) / (1 + 5 / 22.4);
      expect(level(massFor(-0.04), 4, 2), 0);
      expect(level(massFor(-0.06), 4, 2), 0.15);
      expect(level(massFor(-0.08), 4, 2), 0.25);
      expect(level(massFor(-0.11), 4, 2), 0.30);
      expect(level(massFor(0), 4, 2, sleep: 4.5), 0.30);
      expect(level(massFor(0), 4, 2, form: 4), 0.30);
      expect(level(massFor(0), 4, 2, form: 5, sleep: 5), 0);
    });
  });

  group('D23 — grilles du matériel', () {
    test('haltères par 1 kg jusqu’à 10 kg puis par 2 kg', () {
      expect(gridNext(8, 'dumbbell', null, true), 9);
      expect(gridNext(10, 'dumbbell', null, true), 12);
      expect(gridNext(12, 'dumbbell', null, false), 10);
      expect(gridNext(10, 'dumbbell', null, false), 9);
    });

    test('poulies par 2,5 lb (unité native), lest 1,25 kg, barre 2,5 kg', () {
      expect(r2(gridNext(20, 'pulley', null, true)), 20.41); // 45 lb
      expect(gridNext(70, 'barbell', null, true), 72.5);
      expect(gridNext(10, 'plate', null, true), 11.25);
    });

    test('valeur en livres enregistrée au centième de kg : la progression '
        'avance d’un cran', () {
      // 45 lb = 20,4117 kg enregistrés 20,41 ; 70 lb = 31,7515 → 31,75.
      expect(r2(gridNext(20.41, 'pulley', null, true)), 21.55); // 47,5 lb
      expect(r2(gridNext(20.41, 'pulley', null, false)), 19.28); // 42,5 lb
      expect(r2(gridNext(31.75, 'pulley', null, true)), 32.89); // 72,5 lb
    });
  });

  group('D9 — échelle et valeurs héritées', () {
    test('six niveaux, du plus dur au plus facile, stockés en RIR', () {
      expect(
        [for (final e in effortScale) e.label],
        ['Échec', 'Très dur', 'Dur', 'Soutenu', 'Modéré', 'Facile'],
      );
      expect([for (final e in effortScale) e.rir], [0, 1, 2, 3, 4, 5]);
      expect(effortScale[2].more, 'encore 2');
    });

    test('RIR / RPE hérités ; valeurs non interprétables', () {
      expect(parseLegacyEffort('2', 'rir'), 2);
      expect(parseLegacyEffort('2,5', 'rir'), 2.5);
      expect(parseLegacyEffort('8', 'rir'), 5);
      expect(parseLegacyEffort('8', 'rpe'), 2);
      expect(parseLegacyEffort('10', 'rpe'), 0);
      expect(parseLegacyEffort('2-3', 'rir'), isNull);
      expect(parseLegacyEffort('@8', 'rpe'), isNull);
      expect(parseLegacyEffort('RIR 2', 'rir'), isNull);
    });
  });

  group('Rejeu complet = cache incrémental (au centième)', () {
    for (final name in [
      'replay_basic.json',
      'sim_4001.json',
      'sim_6002.json',
    ]) {
      test(name, () {
        final inp = _load(name)['input'] as Map<String, dynamic>;
        final sessions = inp['sessions'] as List;
        KoachState? cache;
        for (var n = 1; n <= sessions.length; n++) {
          final part = Map<String, dynamic>.of(inp)
            ..['sessions'] = sessions.sublist(0, n);
          final inc = replayIncremental(part, cache);
          final full = replay(part);
          cache = inc;
          _same(summarize(full), summarize(inc), '$name[$n]');
        }
      });
    }

    test('une correction passée impose le rejeu complet', () {
      final inp = _load('replay_basic.json')['input'] as Map<String, dynamic>;
      final cache = replay(inp);
      final changed = jsonDecode(jsonEncode(inp)) as Map<String, dynamic>;
      ((((changed['sessions'] as List)[0] as Map)['exercises'] as List)[0]
              as Map)['sets'][0]['reps'] =
          5;
      _same(
        summarize(replay(changed)),
        summarize(replayIncremental(changed, cache)),
        'correction',
      );
    });

    test('pesée rétroactive ou repère modifié : rejeu complet', () {
      final inp = _load('replay_basic.json')['input'] as Map<String, dynamic>;
      final cache = replay(inp);
      final heavier = jsonDecode(jsonEncode(inp)) as Map<String, dynamic>;
      ((heavier['weighIns'] as List)[0] as Map)['kg'] = 80.0;
      final inc = replayIncremental(heavier, cache);
      _same(summarize(replay(heavier)), summarize(inc), 'pesée');
      expect(
        (summarize(inc)['lifts'] as Map)['mu'],
        isNot(equals((summarize(cache)['lifts'] as Map)['mu'])),
      );
      final moved = jsonDecode(jsonEncode(inp)) as Map<String, dynamic>;
      for (final h in moved['history'] as List) {
        if ((h as Map)['source'] == 'initial') {
          h['value'] = (h['value'] as num) + 5;
        }
      }
      (moved['references'] as Map)['B9'] =
          ((moved['references'] as Map)['B9'] as num) + 5;
      _same(
        summarize(replay(moved)),
        summarize(replayIncremental(moved, cache)),
        'repère',
      );
    });
  });
}
