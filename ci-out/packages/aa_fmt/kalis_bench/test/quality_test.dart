// Critères de qualité, attentes de coach, non-ressemblance : cas écrits à
// la main.
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

const String traction = 'sw-traction-pronation';
const String tractionLestee = 'sl-traction-lestee';
const String dips = 'sw-dips-barres-paralleles';
const String pompe = 'sw-pompe';

QualityMeasure measure(List<QualityMeasure> all, String code) =>
    all.firstWhere((q) => q.code == code);

Map<String, Object?> event(int weeksOut) => <String, Object?>{
  'id': 'e1',
  'kind': 'competition',
  'label': 'compétition',
  'weeksOut': weeksOut,
  'targets': <Object?>[
    <String, Object?>{
      'exerciseId': tractionLestee,
      'metric': 'one_rm_kg',
      'targetValue': 60,
    },
  ],
};

void main() {
  test('chaque critère de qualité est rendu une fois, note entre 0 et 1', () {
    final p = testProfile();
    final view = handProgram(
      p,
      sameWeeks(4, <List<L>>[
        <L>[const L(traction, 4), const L(dips, 4)],
        <L>[const L(traction, 4), const L(pompe, 4)],
      ]),
    );
    final all = qualityMeasures(view, p);
    expect(<String>[
      for (final q in all) q.code,
    ], qualityCriteria.keys.toList());
    for (final q in all) {
      final s = q.score;
      if (s != null) {
        expect(s, inInclusiveRange(0, 1), reason: q.code);
      }
      expect(q.detail, isNotEmpty);
    }
  });

  test('equilibre_poussee_tirage : tirage seul, puis équilibré', () {
    final p = testProfile();
    final pullOnly = handProgram(
      p,
      sameWeeks(2, <List<L>>[
        <L>[const L(traction, 4)],
      ]),
    );
    expect(
      measure(qualityMeasures(pullOnly, p), 'equilibre_poussee_tirage').score,
      0,
    );
    final balanced = handProgram(
      p,
      sameWeeks(2, <List<L>>[
        <L>[const L(traction, 4), const L(dips, 4)],
      ]),
    );
    expect(
      measure(qualityMeasures(balanced, p), 'equilibre_poussee_tirage').score,
      1,
    );
  });

  test('frequence_prioritaires : une puis deux séances par semaine', () {
    final p = testProfile(events: <Map<String, Object?>>[event(8)]);
    List<L> day(bool specific) => <L>[
      if (specific) const L(tractionLestee, 3, reps: 4, load: 30),
      const L(dips, 3),
    ];
    final once = handProgram(p, sameWeeks(8, <List<L>>[day(true), day(false)]));
    final twice = handProgram(p, sameWeeks(8, <List<L>>[day(true), day(true)]));
    expect(
      measure(qualityMeasures(once, p), 'frequence_prioritaires').score,
      closeTo(0.5, 1e-9),
    );
    expect(
      measure(qualityMeasures(twice, p), 'frequence_prioritaires').score,
      closeTo(1, 1e-9),
    );
  });

  test('affutage_aligne : test et allègement la semaine de l\'échéance', () {
    final p = testProfile(events: <Map<String, Object?>>[event(6)]);
    List<List<L>> week(int sets, {SetKind? kind}) => <List<L>>[
      <L>[
        L(tractionLestee, sets, reps: 3, load: 40, kind: kind),
        L(dips, sets),
      ],
      <L>[L(tractionLestee, sets, reps: 3, load: 40), L(dips, sets)],
    ];
    final flat = handProgram(p, sameWeeks(6, week(4)));
    final tapered = handProgram(p, <(WeekKind, List<List<L>>)>[
      ...sameWeeks(5, week(4)),
      (WeekKind.test, week(2, kind: SetKind.test)),
    ]);
    final flatScore = measure(
      qualityMeasures(flat, p),
      'affutage_aligne',
    ).score!;
    final taperedScore = measure(
      qualityMeasures(tapered, p),
      'affutage_aligne',
    ).score!;
    expect(taperedScore, greaterThan(flatScore));
    expect(taperedScore, closeTo(1, 1e-9));
  });

  test('couples exercice × schéma et indice de Jaccard', () {
    final p = testProfile();
    final view = handProgram(
      p,
      sameWeeks(1, <List<L>>[
        <L>[const L(traction, 4, reps: 8), const L(dips, 3, reps: 10)],
      ]),
    );
    final pairs = programWeekPairs(view);
    expect(pairs.single, <String>{'$traction|4x8-8', '$dips|3x10-10'});
    expect(maxPairResemblance(pairs, pairs), 1);
    expect(
      maxPairResemblance(pairs, <Set<String>>[
        <String>{'$traction|4x8-8', 'autre|3x5-5', 'encore|2x2-2'},
      ]),
      closeTo(0.25, 1e-9),
    );
    expect(maxPairResemblance(pairs, const <Set<String>>[]), 0);
  });

  test('programme du propriétaire : couples lus, ressemblance mesurée', () {
    final inputs = loadInputs();
    final ownerPairs = inputs.ownerPairs!;
    expect(ownerPairs, isNotEmpty);
    expect(ownerPairs.first.first, contains('|'));
    final p = testProfile();
    final view = handProgram(
      p,
      sameWeeks(1, <List<L>>[
        <L>[const L(traction, 4)],
      ]),
    );
    final q = measure(
      qualityMeasures(view, p, owner: inputs.owner, ownerPairs: ownerPairs),
      'non_ressemblance_proprietaire',
    );
    expect(q.score, isNotNull);
    expect(q.values['limit'], resemblanceLimit);
  });

  test('attentes de coach : tenue et non tenue', () {
    Map<String, Object?> c(String id, String type, Map<String, Object?> more) =>
        <String, Object?>{
          'id': id,
          'type': type,
          'label': 'attente $id',
          ...more,
        };
    final p = testProfile(
      events: <Map<String, Object?>>[event(4)],
      checks: <Map<String, Object?>>[
        c('a', 'min_frequency', <String, Object?>{
          'exerciseIds': <Object?>[traction],
          'perWeek': 2,
        }),
        c('b', 'min_frequency', <String, Object?>{
          'exerciseIds': <Object?>[dips],
          'perWeek': 2,
        }),
        c('c', 'max_group_sets', <String, Object?>{'group': 'lats', 'sets': 6}),
        c('d', 'format_present', <String, Object?>{
          'formats': <Object?>['emom'],
        }),
        c('e', 'min_rir_first_weeks', <String, Object?>{'weeks': 2, 'rir': 3}),
        c('f', 'has_taper', <String, Object?>{'minDrop': 0.3}),
        c('g', 'forbid_patterns', <String, Object?>{
          'patterns': <Object?>['tirage_vertical'],
        }),
        c('h', 'max_session_minutes', <String, Object?>{'minutes': 60}),
        c('i', 'relief_every', <String, Object?>{'weeks': 3}),
        c('j', 'short_rest_share', <String, Object?>{
          'exerciseIds': <Object?>[traction],
          'maxRestSeconds': 90,
          'minShare': 0.5,
        }),
      ],
    );
    final view = handProgram(
      p,
      sameWeeks(4, <List<L>>[
        <L>[const L(traction, 4, rest: 60), const L(dips, 3)],
        <L>[const L(traction, 4, rest: 60)],
      ]),
    );
    final results = <String, bool>{
      for (final r in evaluateChecks(view, p)) r.check.id: r.ok,
    };
    expect(results, <String, bool>{
      'a': true,
      'b': false,
      'c': false,
      'd': false,
      'e': true,
      'f': false,
      'g': false,
      'h': true,
      'i': false,
      'j': true,
    });
  });

  test('type d\'attente inconnu : erreur de format', () {
    final p = testProfile(
      checks: <Map<String, Object?>>[
        <String, Object?>{'id': 'x', 'type': 'inconnu', 'label': 'x'},
      ],
    );
    final view = handProgram(
      p,
      sameWeeks(1, <List<L>>[
        <L>[const L(traction, 3)],
      ]),
    );
    expect(() => evaluateChecks(view, p), throwsFormatException);
  });
}
