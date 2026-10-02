// Propriétés des critères sur 10 000 programmes aléatoires seedés : les
// critères ne lèvent jamais, rendent des codes connus et des notes de 0 à
// 1, sont déterministes ; un programme répété à l'identique ne déclenche
// aucun critère de hausse.
import 'dart:convert';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

const List<String> levels = <String>[
  'beginner',
  'intermediate',
  'advanced',
  'elite',
];

const Set<String> riseCodes = <String>{
  'charge_trop_vite',
  'volume_trop_vite',
  'levier_trop_tot',
};

void main() {
  final catalog = loadCatalog();
  final traits = CatalogTraits.of(catalog);
  // Vivier : renforcement (figures comprises), plus quelques exercices de
  // cardio et de mobilité.
  final pool = <CatalogExercise>[
    for (final e in catalog.exercises)
      if (traits.of(e.id).kind.isResistance &&
          (e.unit == MeasureUnit.repetitions || e.unit == MeasureUnit.seconds))
        e,
  ];
  final others = <CatalogExercise>[
    for (final e in catalog.exercises)
      if (!traits.of(e.id).kind.isResistance && e.unit == MeasureUnit.seconds) e,
  ];

  L line(SeededRandom r) {
    final e = r.nextInt(10) == 0
        ? others[r.nextInt(others.length)]
        : pool[r.nextInt(pool.length)];
    final timed = e.unit == MeasureUnit.seconds;
    final loaded =
        e.loadType == LoadType.addedWeight || e.loadType == LoadType.barbell;
    return L(
      e.id,
      1 + r.nextInt(6),
      reps: 1 + r.nextInt(20),
      seconds: timed ? 5 + r.nextInt(56) : null,
      flames: r.nextInt(8) == 0 ? null : 1 + r.nextInt(10),
      load: loaded && r.nextInt(2) == 0 ? 2.5 * r.nextInt(40) : null,
      rest: 30 * r.nextInt(8),
      kind: r.nextInt(25) == 0 ? SetKind.test : null,
    );
  }

  List<List<L>> days(SeededRandom r) => <List<L>>[
    for (var d = 0, n = 1 + r.nextInt(4); d < n; d++)
      <L>[for (var i = 0, m = 1 + r.nextInt(6); i < m; i++) line(r)],
  ];

  BenchProfile profile(SeededRandom r) => testProfile(
    level: levels[r.nextInt(4)],
    birthYear: 1950 + r.nextInt(60),
    weight: 50.0 + r.nextInt(70),
    breakWeeks: r.nextInt(4) == 0 ? r.nextInt(40) : 0,
    injuries: r.nextInt(3) == 0
        ? <Map<String, Object?>>[
            <String, Object?>{
              'zone': const <String>[
                'shoulder',
                'elbow',
                'wrist_hand',
                'knee',
                'lower_back',
              ][r.nextInt(5)],
              'side': 'both',
              'discomfort': r.nextInt(9),
              'status': r.nextInt(2) == 0 ? 'current' : 'history',
              'monthsAgo': r.nextInt(30),
              'label': 'gêne de test',
            },
          ]
        : const <Map<String, Object?>>[],
    events: r.nextInt(3) == 0
        ? <Map<String, Object?>>[
            <String, Object?>{
              'id': 'e1',
              'kind': 'competition',
              'label': 'compétition',
              'weeksOut': 2 + r.nextInt(8),
              'targets': <Object?>[
                <String, Object?>{
                  'exerciseId': 'sl-traction-lestee',
                  'metric': 'one_rm_kg',
                  'targetValue': 60,
                },
              ],
            },
          ]
        : const <Map<String, Object?>>[],
  );

  void runSeeds(int from, int to) {
    for (var seed = from; seed < to; seed++) {
      final r = SeededRandom(700000 + seed);
      final p = profile(r);
      final count = 1 + r.nextInt(8);
      final first = days(r);
      final weeks = <(WeekKind, List<List<L>>)>[
        for (var w = 0; w < count; w++)
          (
            WeekKind.values[r.nextInt(WeekKind.values.length)],
            // Même nombre de jours toute la durée du bloc.
            w == 0
                ? first
                : <List<L>>[
                    for (final d in first)
                      r.nextInt(3) == 0
                          ? d
                          : <L>[
                              for (var i = 0, m = 1 + r.nextInt(6); i < m; i++)
                                line(r),
                            ],
                  ],
          ),
      ];
      final minutes = 20 + 10 * r.nextInt(10);
      final view = handProgram(p, weeks, minutes: minutes);
      final findings = safetyFindings(view, p);
      for (final f in findings) {
        expect(safetyCriteria, contains(f.code), reason: 'graine $seed');
        final week = f.week;
        if (week != null) {
          expect(week, inInclusiveRange(0, count - 1), reason: 'graine $seed');
        }
      }
      final quality = qualityMeasures(view, p);
      expect(quality.length, qualityCriteria.length, reason: 'graine $seed');
      for (final q in quality) {
        final s = q.score;
        if (s != null) {
          expect(
            s,
            inInclusiveRange(0, 1),
            reason: 'graine $seed, ${q.code}',
          );
        }
      }
      if (seed % 10 == 0) {
        // Déterminisme et export.
        final again = safetyFindings(
          handProgram(p, weeks, minutes: minutes),
          p,
        );
        expect(
          jsonEncode(<Object?>[for (final f in again) f.toJson()]),
          jsonEncode(<Object?>[for (final f in findings) f.toJson()]),
          reason: 'graine $seed',
        );
        final text = programMarkdown(view);
        for (var w = 1; w <= count; w++) {
          expect(text, contains('## Semaine $w '), reason: 'graine $seed');
        }
        final pairs = programWeekPairs(view);
        if (pairs.any((s) => s.isNotEmpty)) {
          expect(maxPairResemblance(pairs, pairs), 1, reason: 'graine $seed');
        }
      }
      // Programme répété à l'identique : aucun critère de hausse.
      final constant = handProgram(p, sameWeeks(count, first));
      final codes = codesOf(safetyFindings(constant, p));
      expect(
        codes.intersection(riseCodes),
        isEmpty,
        reason: 'graine $seed (programme constant)',
      );
      final frozen = safetyFindings(constant, p).where(
        (f) => f.code == 'tendon_figures' && f.message.contains(' s en '),
      );
      expect(frozen, isEmpty, reason: 'graine $seed (tenues constantes)');
    }
  }

  for (var chunk = 0; chunk < 4; chunk++) {
    test(
      'propriétés des critères, graines ${chunk * 2500} à '
      '${chunk * 2500 + 2499}',
      () => runSeeds(chunk * 2500, chunk * 2500 + 2500),
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }
}
