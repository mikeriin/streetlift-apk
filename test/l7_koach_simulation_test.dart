// L7 — KT-035 : simulations Koach en Dart (mêmes athlètes fictifs que
// `tools/koach_simulation.py` : générateur mulberry32 + Box-Muller, graines
// fixées). Critères de la demande L7 §5, définis au contrat L7 §8
// (95e centile ; C5-C7 sur le maximum). Résultats informatifs exclus :
// ils dépendent du modèle et ne prouvent aucune efficacité réelle.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/koach_engine.dart';

class Mulberry32 {
  int s;
  Mulberry32(int seed) : s = seed & 0xFFFFFFFF;

  double next() {
    s = (s + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = s;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  double gauss() {
    final u1 = math.max(next(), 1e-12);
    final u2 = next();
    return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
  }
}

const double bw = 71.5, kPrior = 22.4, x0 = 110.0;
const wave = [(5, 5, 3), (5, 4, 2), (4, 3, 2)];

double trajectory(String kind, int week) => switch (kind) {
  'prog' => x0 * (1.0 + 0.005 * week),
  'plateau' => x0,
  'drop' => week < 6 ? x0 : x0 * 0.95,
  _ => throw ArgumentError(kind),
};

String ts(int day, int minute) =>
    isoOf(day * 86400.0 + 18 * 3600.0 + minute * 60.0);

class SimPoint {
  final int week;
  final double x, sd, truth, bias, before;
  final double? applied;
  final int weeks;
  final List<(double, double, double)> inSession;
  const SimPoint(
    this.week,
    this.x,
    this.sd,
    this.truth,
    this.bias,
    this.before,
    this.applied,
    this.weeks,
    this.inSession,
  );
}

(List<SimPoint>, Map<String, dynamic>) simulate(
  int seed, {
  String traj = 'plateau',
  double priorErr = 0.0,
  int beta = 0,
  int sessions = 12,
  int? badDay,
  double incidents = 0.05,
  bool koach = false,
  Set<int> tests = const {},
  double kTrue = kPrior,
  bool cached = false,
}) {
  final rng = Mulberry32(seed);
  var pil = nearGrid((x0 - bw) * (1.0 + priorErr) + priorErr * bw, 1.25);
  final inp = <String, dynamic>{
    'now': ts(0, 0),
    'lifts': [
      {
        'key': 'pull',
        'ref': 'B8',
        'bodyweight': true,
        'k': kPrior,
        'grid': 1.25,
      },
    ],
    'repmax': <dynamic>[],
    'accessories': <dynamic>[],
    'references': <String, dynamic>{'B4': bw, 'B8': pil},
    'history': <dynamic>[
      {'at': ts(0, -60), 'ref': 'B8', 'value': pil, 'source': 'initial'},
    ],
    'weighIns': [
      {'date': ts(0, 0).substring(0, 10), 'kg': bw},
    ],
    'sessions': <dynamic>[],
  };
  final hist = <SimPoint>[];
  KoachState? cache;
  for (var w = 0; w < sessions; w++) {
    final day = 7 * w + 1;
    final xt = trajectory(traj, w);
    final f = badDay == w ? 0.92 : 1.0;
    final sess = <String, dynamic>{
      'key': 'S${w + 1}-J1',
      'week': w + 1,
      'day': 1,
      'done': true,
      'finishedAt': ts(day, 60),
      'exercises': <dynamic>[],
    };
    final caps = <(double, double, double)>[];
    if (tests.contains(w)) {
      final best = floorGrid(xt * f - bw, 1.25);
      (sess['exercises'] as List).add({
        'id': 'T',
        'cat': 'test1rm',
        'ref': 'B8',
        'restSec': 300,
        'rirTarget': null,
        'plannedReps': 1,
        'cluster': false,
        'sets': [
          {
            'kg': r2(best * 0.8),
            'reps': 1,
            'rir': null,
            'excluded': false,
            'done': true,
            'at': ts(day, 0),
          },
          {
            'kg': r2(best),
            'reps': 1,
            'rir': null,
            'excluded': false,
            'done': true,
            'at': ts(day, 5),
          },
        ],
      });
    } else {
      final (nSets, reps, target) = wave[w % wave.length];
      var lest = pctOf((reps + target).toDouble(), kPrior) * (pil + bw) - bw;
      lest = math.max(0.0, nearGrid(lest, koach ? 1.25 : 2.5));
      final sets = <Map<String, dynamic>>[];
      for (var j = 0; j < nSets; j++) {
        final m = lest + bw;
        final cap = 1.0 + kTrue * (xt * f / m - 1.0);
        final st = <String, dynamic>{
          'kg': r2(lest),
          'excluded': false,
          'done': true,
          'at': ts(day, 3 * j),
        };
        final incident = rng.next() < incidents;
        final noise = rng.gauss();
        if (cap < reps) {
          st['reps'] = math.max(1, cap.floor());
          st['rir'] = 0.0;
        } else {
          st['reps'] = reps;
          final trueRir = cap - reps;
          st['rir'] = math.min(
            5.0,
            math.max(0.0, kRound(trueRir + noise + beta)),
          );
        }
        if (incident) {
          st['reps'] = math.max(1, (st['reps'] as int) - 2);
          st['rir'] = 0.0;
          st['excluded'] = true;
        }
        sets.add(st);
        if (koach) {
          final done = [
            for (final s in sets)
              if (s['excluded'] != true)
                {'kg': s['kg'], 'reps': s['reps'], 'rir': s['rir']},
          ];
          final sug = inSession(
            koachParams,
            {'bodyweight': true},
            done,
            target.toDouble(),
            reps,
            bw,
            1.25,
            const {},
          );
          if (sug != null) {
            caps.add((sug.from, sug.kg, sug.delta));
            lest = sug.kg;
          }
        }
      }
      (sess['exercises'] as List).add({
        'id': 'W',
        'cat': 'strength',
        'ref': 'B8',
        'restSec': 180,
        'rirTarget': target,
        'plannedReps': reps,
        'cluster': false,
        'sets': sets,
      });
    }
    (inp['sessions'] as List).add(sess);
    inp['now'] = ts(day, 90);
    final KoachState state;
    if (cached) {
      state = replayIncremental(inp, cache);
      cache = state;
    } else {
      state = replay(inp);
    }
    final tr = state.tracks['pull']!;
    double? applied;
    final before = pil;
    final weeks = weeksSinceChange(
      inp,
      'B8',
      parseDt(inp['now'] as String)!,
      koachParams,
    );
    if (koach) {
      for (final pr in proposals(inp, state, sess['key'] as String)) {
        if (pr['ref'] == 'B8') {
          applied = (pr['to'] as num).toDouble();
          (inp['history'] as List).add({
            'at': ts(day, 95),
            'ref': 'B8',
            'value': applied,
            'source': 'koach',
          });
          (inp['references'] as Map)['B8'] = applied;
          pil = applied;
        }
      }
    }
    hist.add(
      SimPoint(w, tr.x, tr.sd, xt, state.bias.b, before, applied, weeks, caps),
    );
  }
  return (hist, inp);
}

double p95(List<double> values) {
  final v = [...values]..sort();
  return v[(0.95 * (v.length - 1)).floor()];
}

void main() {
  const n = 30;

  test('le simulateur Dart reproduit les athlètes de la référence Python', () {
    for (final (name, seed, traj, pe, beta, tests) in [
      ('sim_4001.json', 4001, 'plateau', 0.0, 1, {3, 7}),
      ('sim_2003.json', 2003, 'prog', -0.15, 0, <int>{}),
      ('sim_6002.json', 6002, 'drop', 0.05, -1, {4, 9}),
    ]) {
      final fixture =
          jsonDecode(File('test/fixtures/koach/$name').readAsStringSync())
              as Map<String, dynamic>;
      final (_, inp) = simulate(
        seed,
        traj: traj,
        priorErr: pe,
        beta: beta,
        tests: tests,
        koach: pe != 0.0,
      );
      final want = (fixture['input'] as Map)['sessions'] as List;
      final got = inp['sessions'] as List;
      expect(got.length, want.length, reason: name);
      for (var i = 0; i < want.length; i++) {
        final a = ((want[i] as Map)['exercises'] as List).first as Map;
        final b = ((got[i] as Map)['exercises'] as List).first as Map;
        final sa = a['sets'] as List, sb = b['sets'] as List;
        expect(sb.length, sa.length, reason: '$name S${i + 1}');
        for (var j = 0; j < sa.length; j++) {
          for (final k in ['kg', 'reps', 'rir', 'excluded', 'at']) {
            expect(
              '${(sb[j] as Map)[k]}'.replaceAll('.0', ''),
              '${(sa[j] as Map)[k]}'.replaceAll('.0', ''),
              reason: '$name S${i + 1} série ${j + 1} $k',
            );
          }
        }
      }
    }
  });

  test('C1 — erreur < 3 % après 6 séances depuis un a priori juste', () {
    final e = <double>[];
    for (var s = 0; s < n; s++) {
      for (final traj in ['prog', 'plateau', 'drop']) {
        final (h, _) = simulate(1000 + s, traj: traj, sessions: 6);
        e.add((h[5].x - h[5].truth).abs() / h[5].truth);
      }
    }
    expect(p95(e), lessThan(0.03), reason: 'p95 ${p95(e)}');
  });

  test('C2 — convergence en ≤ 6 séances depuis un a priori faux de ±15 %', () {
    final e = <double>[];
    for (var s = 0; s < n; s++) {
      for (final pe in [0.15, -0.15]) {
        for (final traj in ['prog', 'plateau']) {
          final (h, _) = simulate(
            2000 + s,
            traj: traj,
            priorErr: pe,
            sessions: 6,
            koach: true,
          );
          e.add((h[5].x - h[5].truth).abs() / h[5].truth);
        }
      }
    }
    expect(p95(e), lessThan(0.03), reason: 'p95 ${p95(e)}');
  });

  test('C3 — un mauvais jour isolé (−8 %) déplace l’estimation de < 1 %', () {
    final e = <double>[];
    for (var s = 0; s < n; s++) {
      final (a, _) = simulate(3000 + s, sessions: 10, incidents: 0);
      final (b, _) = simulate(3000 + s, sessions: 10, badDay: 8, incidents: 0);
      e.add((b[8].x - a[8].x).abs() / a[8].x);
    }
    expect(p95(e), lessThan(0.01), reason: 'p95 ${p95(e)}');
  });

  test('C4 — biais de RIR appris à ±0,5 près après 2 tests', () {
    final e = <double>[];
    for (var s = 0; s < n; s++) {
      for (final beta in [-1, 0, 1]) {
        final (h, _) = simulate(
          4000 + s,
          beta: beta,
          sessions: 9,
          tests: {3, 7},
        );
        e.add((h.last.bias + beta).abs());
      }
    }
    expect(p95(e), lessThanOrEqualTo(0.5), reason: 'p95 ${p95(e)}');
  });

  test('C5, C6 — pas d’oscillation, plafonds D20 / D24 jamais dépassés', () {
    var worst = 0, violations = 0;
    for (var s = 0; s < n; s++) {
      final (h, _) = simulate(5000 + s, sessions: 24, koach: true);
      final dirs = <(int, int)>[];
      for (final e in h) {
        final applied = e.applied;
        if (applied != null) {
          dirs.add((e.week, applied > e.before ? 1 : -1));
          final lo =
              (e.before + bw) * (1 - koachParams['cap_down']! * e.weeks) - bw;
          final hi =
              (e.before + bw) * (1 + koachParams['cap_up']! * e.weeks) - bw;
          if (applied > hi + 1e-9 || applied < lo - 1e-9) violations++;
        }
        for (final (from, to, delta) in e.inSession) {
          final cap = delta > 0.04
              ? koachParams['up_big_cap']!
              : koachParams['up_small_cap']!;
          if (to - from > cap + 1e-9) violations++;
        }
      }
      for (var i = 6; i < 21; i++) {
        final window = [
          for (final (wk, d) in dirs)
            if (wk >= i && wk < i + 4) d,
        ];
        var changes = 0;
        for (var j = 1; j < window.length; j++) {
          if (window[j] != window[j - 1]) changes++;
        }
        worst = math.max(worst, changes);
      }
    }
    expect(worst, lessThanOrEqualTo(1));
    expect(violations, 0);
  });

  test('C7 — rejeu complet = cache incrémental, au centième de kg', () {
    var diff = 0.0;
    for (var s = 0; s < 6; s++) {
      final (a, _) = simulate(
        6000 + s,
        traj: 'prog',
        priorErr: 0.05,
        beta: 1,
        tests: {4, 9},
        koach: true,
      );
      final (b, _) = simulate(
        6000 + s,
        traj: 'prog',
        priorErr: 0.05,
        beta: 1,
        tests: {4, 9},
        koach: true,
        cached: true,
      );
      for (var i = 0; i < a.length; i++) {
        diff = math.max(diff, (a[i].x - b[i].x).abs());
        diff = math.max(diff, (a[i].sd - b[i].sd).abs());
        diff = math.max(diff, (a[i].bias - b[i].bias).abs());
      }
    }
    expect(diff, lessThan(0.01));
  });
}
