// Référence croisée : le filtre Dart rejoue les vecteurs produits par la
// référence Python (`tool/reference/`) et doit rendre le même état après
// chaque étape. Les deux écritures sont indépendantes (le Python a été
// écrit avant le Dart) ; les logarithmes et exponentielles n'y sont pas
// calculés de la même façon, d'où une tolérance de 1e-9 en valeur relative (plus 1e-13 en valeur
// absolue).
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:test/test.dart';

import 'support.dart';

const double _tolerance = 1e-9;

void _near(num actual, num expected, String where) {
  if ((actual - expected).abs() > _tolerance * expected.abs() + 1e-13) {
    fail('$where : Dart $actual, référence $expected');
  }
}

double _d(Object? v) => (v! as num).toDouble();

void main() {
  final vectors = readJsonObject('test/fixtures/filter_vectors.json.gz');
  const p = AdaptParams.standard;

  test('fonctions numériques : mêmes valeurs que la référence', () {
    final f = vectors['functions']! as Map<String, Object?>;
    List<List<Object?>> rows(String name) => <List<Object?>>[
      for (final r in f[name]! as List<Object?>) r! as List<Object?>,
    ];
    for (final r in rows('erfc')) {
      _near(erfc(_d(r[0])), _d(r[1]), 'erfc(${r[0]})');
    }
    for (final r in rows('normCdf')) {
      _near(normCdf(_d(r[0])), _d(r[1]), 'normCdf(${r[0]})');
    }
    for (final r in rows('normPdf')) {
      _near(normPdf(_d(r[0])), _d(r[1]), 'normPdf(${r[0]})');
    }
    for (final r in rows('rirOfFlames')) {
      expect(rirOfFlames(r[0]! as int), _d(r[1]), reason: 'flammes ${r[0]}');
    }
    for (final r in rows('flamesOfRir')) {
      expect(flamesOfRir(_d(r[0])), r[1], reason: 'RIR ${r[0]}');
    }
    for (final r in rows('logShare')) {
      _near(
        logShare(_d(r[0]), _d(r[1])),
        _d(r[2]),
        'logShare(${r[0]}, ${r[1]})',
      );
    }
    for (final r in rows('repsAt')) {
      _near(repsAt(_d(r[0]), _d(r[1])), _d(r[2]), 'repsAt(${r[0]}, ${r[1]})');
    }
    for (final r in rows('setFatigueOf')) {
      _near(
        setFatigueOf(_d(r[0]), r[1]! as int, p),
        _d(r[2]),
        'setFatigueOf(${r[0]}, ${r[1]})',
      );
    }
    for (final r in rows('plannedFatigue')) {
      _near(
        plannedFatigue(r[0]! as int, _d(r[1]), r[2]! as int, p),
        _d(r[3]),
        'plannedFatigue(${r[0]}, ${r[1]}, ${r[2]})',
      );
    }
  });

  test('filtre : même état que la référence après chaque étape', () {
    final cases = vectors['cases']! as List<Object?>;
    expect(cases.length, greaterThanOrEqualTo(50));
    var steps = 0;
    for (final c in cases) {
      final kase = c! as Map<String, Object?>;
      final name = kase['name']! as String;
      final init = kase['init']! as Map<String, Object?>;
      final modeName = init['mode']! as String;
      final mode = modeName == 'loaded'
          ? CapacityMode.loaded
          : (modeName == 'hold' ? CapacityMode.hold : CapacityMode.reps);
      final filter = init['fromOneRm'] == true
          ? CapacityFilter.fromOneRm(
              logOneRm: _d(init['c']),
              sd: _d(init['cSd']),
              v: _d(init['v']),
              vSd: _d(init['vSd']),
              k: _d(init['k']),
              kLogSd: _d(init['kLogSd']),
              nRef: _d(init['nRef']),
              day: init['day']! as int,
            )
          : CapacityFilter(
              mode: mode,
              c: _d(init['c']),
              cSd: _d(init['cSd']),
              v: _d(init['v']),
              vSd: _d(init['vSd']),
              k: _d(init['k']),
              kLogSd: _d(init['kLogSd']),
              nRef: _d(init['nRef']),
              day: init['day']! as int,
            );
      final list = kase['steps']! as List<Object?>;
      final expected = kase['expect']! as List<Object?>;
      for (var i = 0; i < list.length; i++) {
        final step = list[i]! as Map<String, Object?>;
        switch (step['op']) {
          case 'begin':
            filter.beginSession(
              step['day']! as int,
              _d(step['shift']),
              _d(step['daySd']),
              p,
            );
          case 'observe':
            filter.observeLoad(
              logLoad: _d(step['logLoad']),
              n: _d(step['n']),
              nSd: _d(step['nSd']),
              fatigue: _d(step['fatigue']),
              p: p,
              bound: step['bound']! as bool,
              upper: step['upper'] == true,
              learnK: step['learnK']! as bool,
            );
          case 'direct':
            filter.observeDirect(
              logCapacity: _d(step['logCapacity']),
              sd: _d(step['sd']),
              p: p,
              bound: step['bound']! as bool,
            );
          case 'fatigue':
            filter.noteSetFatigue(_d(step['rir']), step['rest']! as int, p);
          case 'end':
            filter.endSession();
          case 'predict':
            filter.predict(step['day']! as int, p);
          default:
            fail('$name : étape inconnue ${step['op']}');
        }
        final want = expected[i]! as Map<String, Object?>;
        final m = want['m']! as List<Object?>;
        final cov = want['cov']! as List<Object?>;
        final where = '$name, étape $i (${step['op']})';
        for (var j = 0; j < 4; j++) {
          _near(filter.m[j], _d(m[j]), '$where, m[$j]');
        }
        for (var j = 0; j < 16; j++) {
          _near(filter.cov[j], _d(cov[j]), '$where, cov[$j]');
        }
        _near(filter.fatigueNow(p), _d(want['fatigueNow']), '$where, fatigue');
        expect(filter.sets, want['sets'], reason: where);
        expect(filter.sessions, want['sessions'], reason: where);
        steps++;
      }
      final reads = kase['reads']! as Map<String, Object?>;
      _near(filter.k, _d(reads['k']), '$name, k');
      _near(filter.gRef, _d(reads['gRef']), '$name, gRef');
      _near(filter.capacity, _d(reads['capacity']), '$name, capacité');
      _near(
        filter.capacityRelSd,
        _d(reads['capacityRelSd']),
        '$name, écart-type relatif',
      );
      for (final r in reads['loadSd']! as List<Object?>) {
        final row = r! as List<Object?>;
        _near(filter.loadSd(_d(row[0])), _d(row[1]), '$name, loadSd');
        _near(
          filter.loadSd(_d(row[0]), withDay: false),
          _d(row[2]),
          '$name, loadSd hors jour',
        );
      }
      for (final r in reads['repsPossible']! as List<Object?>) {
        final row = r! as List<Object?>;
        _near(
          filter.repsPossible(filter.m[0] + _d(row[0]), shift: _d(row[1])),
          _d(row[2]),
          '$name, repsPossible',
        );
      }
      for (final r in reads['logLoadFor']! as List<Object?>) {
        final row = r! as List<Object?>;
        _near(
          filter.logLoadFor(_d(row[0]), shift: _d(row[1])),
          _d(row[2]),
          '$name, logLoadFor',
        );
      }
    }
    expect(steps, greaterThan(1000));
  });
}
