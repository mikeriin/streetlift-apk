// Prescriptions avancées, saison, compétition, figures (0.4.0) : types à
// variantes, invariants croisés, journal, interfaces nouvelles.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

/// Chemin et code de chaque violation (`$.sets:set_count`).
List<String> _tagged(List<Violation> violations) => <String>[
  for (final v in violations) '${v.path}:${v.code}',
];

void main() {
  group('types à variantes', () {
    final fixture = readJsonObject('test/fixtures/variants.json');
    final types = (fixture['types']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final codecs = <String, ContractCodec<Object>>{
      for (final c in contractCodecs) c.name: c,
    };

    test('sept types à variantes', () {
      expect(types.map((t) => t['type']), <String>[
        'Benchmark',
        'SeasonEvent',
        'Specialization',
        'SetTechnique',
        'IntensityTarget',
        'AutoregulationRule',
        'GroupSpec',
      ]);
    });

    test('chaque valeur du discriminant a sa règle, dans l\'ordre', () {
      final expected = <String, List<String>>{
        'Benchmark': <String>[for (final v in BenchmarkKind.values) v.code],
        'SeasonEvent': <String>[for (final v in EventKind.values) v.code],
        'Specialization': <String>[
          for (final v in SpecializationKind.values) v.code,
        ],
        'SetTechnique': <String>[
          for (final v in SetTechniqueKind.values) v.code,
        ],
        'IntensityTarget': <String>[
          for (final v in IntensityBasis.values) v.code,
        ],
        'AutoregulationRule': <String>[
          for (final v in AutoregulationKind.values) v.code,
        ],
        'GroupSpec': <String>[for (final v in GroupFormat.values) v.code],
      };
      for (final type in types) {
        final name = type['type']! as String;
        final rules = (type['rules']! as Map<String, Object?>).keys.toList();
        expect(rules, expected[name], reason: name);
      }
    });

    for (final type in types) {
      final name = type['type']! as String;
      final discriminator = type['discriminator']! as String;
      final base = type['base']! as Map<String, Object?>;
      final samples = type['samples']! as Map<String, Object?>;
      final rules = (type['rules']! as Map<String, Object?>)
          .cast<String, Map<String, Object?>>();

      test('$name : chaque variante porte exactement ses paramètres', () {
        final codec = codecs[name]!;
        List<String> codes(Map<String, Object?> json) =>
            codesOf(codec.validate(codec.fromJson(json)));
        List<String> found(Map<String, Object?> json) =>
            _tagged(codec.validate(codec.fromJson(json)));
        for (final rule in rules.entries) {
          final required = (rule.value['required']! as List<Object?>)
              .cast<String>();
          final allowed = (rule.value['allowed']! as List<Object?>)
              .cast<String>();
          final minimal = <String, Object?>{
            ...base,
            discriminator: rule.key,
            for (final n in required) n: samples[n],
          };
          final where = '$name ${rule.key}';
          // Objet minimal : valide.
          expect(codes(minimal), isEmpty, reason: where);
          // Aller-retour exact.
          final value = codec.fromJson(minimal);
          expect(
            codec.fromJson(viaJsonText(codec.toJson(value))),
            value,
            reason: where,
          );
          // Relu puis réécrit, l'objet est le même JSON.
          expect(viaJsonText(codec.toJson(value)), minimal, reason: where);
          // Un paramètre obligatoire absent est signalé, à son chemin.
          for (final n in required) {
            final missing = <String, Object?>{...minimal}..remove(n);
            expect(
              codes(missing),
              contains('missing_field'),
              reason: '$where −$n',
            );
            expect(
              found(missing),
              contains('\$.$n:missing_field'),
              reason: '$where −$n',
            );
          }
          // Un paramètre d'une autre variante est signalé ; un paramètre
          // permis ne l'est pas.
          for (final n in samples.keys) {
            if (required.contains(n)) {
              continue;
            }
            final extra = <String, Object?>{...minimal, n: samples[n]};
            if (allowed.contains(n)) {
              expect(
                codes(extra),
                isNot(contains('unexpected_field')),
                reason: '$where +$n',
              );
            } else {
              expect(
                codes(extra),
                contains('unexpected_field'),
                reason: '$where +$n',
              );
              expect(
                found(extra),
                contains('\$.$n:unexpected_field'),
                reason: '$where +$n',
              );
            }
          }
        }
        // Toutes les valeurs du discriminant ont une règle.
        final probe = codec.toJson(
          codec.fromJson(<String, Object?>{
            ...base,
            discriminator: rules.keys.first,
            for (final n
                in (rules.values.first['required']! as List<Object?>)
                    .cast<String>())
              n: samples[n],
          }),
        );
        expect(probe[discriminator], rules.keys.first);
      });
    }

    test('toutes les techniques de série ont une règle', () {
      final rules =
          (types.firstWhere((t) => t['type'] == 'SetTechnique')['rules']!
                  as Map<String, Object?>)
              .keys
              .toList();
      expect(rules, <String>[for (final k in SetTechniqueKind.values) k.code]);
      expect(SetTechniqueKind.values, hasLength(17));
      expect(SetTechniqueKind.values.last, SetTechniqueKind.forTime);
      expect(SetTechniqueKind.forTime.code, 'for_time');
    });

    test('un groupe par format : paramètres exacts', () {
      const valid = <GroupSpec>[
        GroupSpec(groupId: 'g1', format: GroupFormat.superset),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.superset,
          rounds: 3,
          restBetweenRoundsSeconds: 90,
          eventId: 'e1',
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.circuit,
          rounds: 3,
          restBetweenRoundsSeconds: 60,
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.roundsForTime,
          rounds: 5,
          timeCapSeconds: 1200,
          targetSeconds: 900,
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.amrap,
          durationSeconds: 720,
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.emom,
          intervalSeconds: 60,
          durationSeconds: 600,
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.chipper,
          timeCapSeconds: 1800,
          targetSeconds: 1500,
        ),
        GroupSpec(
          groupId: 'g1',
          format: GroupFormat.intervals,
          rounds: 8,
          intervalSeconds: 30,
          restBetweenRoundsSeconds: 30,
        ),
      ];
      for (final g in valid) {
        expect(g.validate(), isEmpty, reason: g.format.code);
        expect(
          GroupSpec.fromJson(viaJsonText(g.toJson())),
          g,
          reason: g.format.code,
        );
      }
      expect(GroupFormat.values, hasLength(7));
      const superset = GroupSpec(groupId: 'g1', format: GroupFormat.superset);
      expect(superset.toJson().keys.toList(), <String>['groupId', 'format']);
      expect(
        _tagged(superset.copyWith(durationSeconds: 600).validate()),
        <String>[r'$.durationSeconds:unexpected_field'],
      );
      expect(
        _tagged(superset.copyWith(format: GroupFormat.circuit).validate()),
        <String>[r'$.rounds:missing_field'],
      );
      expect(
        _tagged(
          superset
              .copyWith(
                format: GroupFormat.roundsForTime,
                rounds: 5,
                intervalSeconds: 30,
              )
              .validate(),
        ),
        <String>[r'$.intervalSeconds:unexpected_field'],
      );
      expect(
        _tagged(
          superset
              .copyWith(
                format: GroupFormat.amrap,
                durationSeconds: 720,
                rounds: 3,
              )
              .validate(),
        ),
        <String>[r'$.rounds:unexpected_field'],
      );
      expect(
        _tagged(
          superset
              .copyWith(format: GroupFormat.emom, intervalSeconds: 60)
              .validate(),
        ),
        <String>[r'$.durationSeconds:missing_field'],
      );
      expect(
        _tagged(
          superset.copyWith(format: GroupFormat.chipper, rounds: 3).validate(),
        ),
        <String>[r'$.rounds:unexpected_field'],
      );
      expect(
        _tagged(
          superset
              .copyWith(format: GroupFormat.intervals, rounds: 8)
              .validate(),
        ),
        <String>[r'$.intervalSeconds:missing_field'],
      );
      // Bornes ; `eventId` est libre mais jamais vide.
      expect(_tagged(superset.copyWith(rounds: 0).validate()), <String>[
        r'$.rounds:below_min',
      ]);
      expect(_tagged(superset.copyWith(groupId: '').validate()), <String>[
        r'$.groupId:too_short',
      ]);
      expect(_tagged(superset.copyWith(eventId: '').validate()), <String>[
        r'$.eventId:too_short',
      ]);
      expect(
        _tagged(
          superset
              .copyWith(
                format: GroupFormat.intervals,
                rounds: 8,
                intervalSeconds: 4,
              )
              .validate(),
        ),
        <String>[r'$.intervalSeconds:below_min'],
      );
    });
  });

  group('prescriptions avancées', () {
    test('série de tête puis séries allégées, autorégulées', () {
      final p = basePrescription.copyWith(
        exerciseId: 'sl-traction-lestee',
        sets: 4,
        repsLow: 3,
        repsHigh: 3,
        loadBasis: LoadBasis.bodyweightPlusExternal,
        percentOfOneRm: 0.9,
        technique: const SetTechnique(
          kind: SetTechniqueKind.topSetBackoff,
          backoffSets: 3,
          backoffDropPct: 0.1,
          backoffRepsLow: 4,
          backoffRepsHigh: 5,
        ),
        intensity: const IntensityTarget(
          basis: IntensityBasis.percentOneRm,
          value: 0.9,
          rirCap: 1,
        ),
        autoregulation: const <AutoregulationRule>[
          AutoregulationRule(
            kind: AutoregulationKind.backoffFromTopSet,
            pct: 0.1,
          ),
        ],
        dayStress: DayStress.heavy,
        setTargets: const <SetTarget>[
          SetTarget(repsLow: 3, repsHigh: 3, role: SetRole.top),
          SetTarget(repsLow: 4, repsHigh: 5, role: SetRole.backOff),
          SetTarget(repsLow: 4, repsHigh: 5, role: SetRole.backOff),
          SetTarget(repsLow: 4, repsHigh: 5, role: SetRole.backOff),
        ],
      );
      expect(p.validate(), isEmpty);
      expect(ExercisePrescription.fromJson(viaJsonText(p.toJson())), p);
      // Les séries allégées sont comptées dans `sets`, avec la série de tête.
      expect(
        codesOf(p.copyWith(sets: 3, setTargets: null).validate()),
        <String>['set_count'],
      );
    });

    test('un test se déclare sur une prescription de rôle test', () {
      const spec = TestSpec(
        kind: TestKind.amrapEstimate,
        protocolId: 't1_serie_lourde',
        targetRir: 1,
        benchmarkKind: BenchmarkKind.loadReps,
      );
      final ok = basePrescription.copyWith(kind: SetKind.test, test: spec);
      expect(ok.validate(), isEmpty);
      expect(
        codesOf(basePrescription.copyWith(test: spec).validate()),
        <String>['unexpected_field'],
      );
    });

    test('sans les champs 0.4.0, une prescription s\'écrit comme en 0.3.0', () {
      expect(basePrescription.toJson().keys.toList(), <String>[
        'slotId',
        'exerciseId',
        'sets',
        'repsLow',
        'repsHigh',
        'targetFlames',
        'restSeconds',
        'toCalibrate',
        'loadBasis',
        'reasons',
      ]);
      expect(baseSet.toJson().keys.toList(), <String>[
        'exerciseId',
        'exerciseOrder',
        'setIndex',
        'kind',
        'reps',
        'flames',
        'success',
        'excluded',
      ]);
    });

    test('plages et listes des techniques', () {
      // `activationRepsLow/High` et `repsPerInterval` n'existent plus : la
      // série d'activation des myo-reps suit la plage de la prescription. La
      // seule plage d'une technique est celle des séries allégées.
      const myo = SetTechnique(
        kind: SetTechniqueKind.myoReps,
        miniSetReps: 4,
        intraRestSeconds: 15,
        miniSets: 5,
      );
      expect(myo.validate(), isEmpty);
      expect(
        SetTechnique.fromJson(<String, Object?>{
          ...viaJsonText(myo.toJson()),
          'activationRepsLow': 12,
          'activationRepsHigh': 15,
          'repsPerInterval': 5,
        }),
        myo,
        reason: 'champs retirés : ignorés à la lecture',
      );
      expect(myo.toJson().keys.toList(), <String>[
        'kind',
        'miniSets',
        'miniSetReps',
        'intraRestSeconds',
      ]);
      const backoff = SetTechnique(
        kind: SetTechniqueKind.topSetBackoff,
        backoffSets: 3,
        backoffDropPct: 0.1,
        backoffRepsLow: 4,
        backoffRepsHigh: 5,
      );
      expect(backoff.validate(), isEmpty);
      expect(codesOf(backoff.copyWith(backoffRepsLow: 6).validate()), <String>[
        'range_inverted',
      ]);
      expect(
        codesOf(backoff.copyWith(backoffRepsHigh: null).validate()),
        <String>['range_incomplete'],
      );
      const wave = SetTechnique(
        kind: SetTechniqueKind.wave,
        waves: 2,
        waveReps: <int>[3, 2, 1],
        waveStepPct: 0.025,
      );
      expect(wave.validate(), isEmpty);
      expect(
        codesOf(wave.copyWith(waveReps: const <int>[3, 0]).validate()),
        <String>['below_min'],
      );
      const ladder = SetTechnique(
        kind: SetTechniqueKind.ladder,
        ladderStart: 1,
        ladderStep: 1,
        ladderTop: 5,
        ladderCount: 3,
      );
      expect(ladder.validate(), isEmpty);
      expect(codesOf(ladder.copyWith(ladderStart: 6).validate()), <String>[
        'range_inverted',
      ]);
      // L'écart entre la première et la dernière marche est un multiple du pas.
      expect(ladder.copyWith(ladderStep: 2).validate(), isEmpty);
      expect(
        ladder.copyWith(ladderStep: 4, ladderCount: null).validate(),
        isEmpty,
      );
      expect(
        _tagged(ladder.copyWith(ladderStep: 2, ladderTop: 6).validate()),
        <String>[r'$.ladderStep:ladder_step'],
      );
      expect(_tagged(ladder.copyWith(ladderStep: 3).validate()), <String>[
        r'$.ladderStep:ladder_step',
      ]);
      const pyramid = SetTechnique(
        kind: SetTechniqueKind.pyramid,
        pyramidReps: <int>[10, 8, 6, 4, 2],
      );
      expect(pyramid.validate(), isEmpty);
      expect(
        _tagged(pyramid.copyWith(pyramidReps: const <int>[10, 101]).validate()),
        <String>[r'$.pyramidReps[1]:above_max'],
      );
      expect(
        _tagged(pyramid.copyWith(pyramidReps: const <int>[5]).validate()),
        <String>[r'$.pyramidReps:too_short'],
      );
      const cluster = SetTechnique(
        kind: SetTechniqueKind.cluster,
        miniSets: 3,
        miniSetReps: 2,
        intraRestSeconds: 20,
      );
      expect(cluster.validate(), isEmpty);
      expect(
        codesOf(cluster.copyWith(intraRestSeconds: 0).validate()),
        <String>['below_min'],
      );
    });

    test('technique au temps, temps total visé, dernière série seulement', () {
      const forTime = SetTechnique(
        kind: SetTechniqueKind.forTime,
        totalRepsTarget: 100,
      );
      expect(forTime.validate(), isEmpty);
      expect(forTime.copyWith(durationSeconds: 600).validate(), isEmpty);
      expect(SetTechnique.fromJson(viaJsonText(forTime.toJson())), forTime);
      expect(
        _tagged(forTime.copyWith(totalRepsTarget: null).validate()),
        <String>[r'$.totalRepsTarget:missing_field'],
      );
      expect(_tagged(forTime.copyWith(intervals: 10).validate()), <String>[
        r'$.intervals:unexpected_field',
      ]);
      const hold = SetTechnique(
        kind: SetTechniqueKind.isometricHold,
        totalSecondsTarget: 60,
        qualityFloor: 3,
      );
      expect(hold.validate(), isEmpty);
      expect(SetTechnique.fromJson(viaJsonText(hold.toJson())), hold);
      expect(codesOf(hold.copyWith(totalSecondsTarget: 0).validate()), <String>[
        'below_min',
      ]);
      expect(
        codesOf(hold.copyWith(totalSecondsTarget: 3601).validate()),
        <String>['above_max'],
      );
      const practice = SetTechnique(
        kind: SetTechniqueKind.skillPractice,
        qualityFloor: 4,
        maxAttempts: 8,
        totalSecondsTarget: 45,
      );
      expect(practice.validate(), isEmpty);
      const cluster = SetTechnique(
        kind: SetTechniqueKind.cluster,
        miniSets: 3,
        miniSetReps: 2,
        intraRestSeconds: 20,
      );
      expect(
        _tagged(cluster.copyWith(totalSecondsTarget: 60).validate()),
        <String>[r'$.totalSecondsTarget:unexpected_field'],
      );
      // `lastSetOnly` n'est pas un paramètre de variante : il est admis
      // partout et s'écrit en dernier.
      const last = SetTechnique(
        kind: SetTechniqueKind.restPause,
        intraRestSeconds: 15,
        lastSetOnly: true,
      );
      expect(last.validate(), isEmpty);
      expect(last.toJson().keys.toList(), <String>[
        'kind',
        'intraRestSeconds',
        'lastSetOnly',
      ]);
      expect(SetTechnique.fromJson(viaJsonText(last.toJson())), last);
      expect(cluster.copyWith(lastSetOnly: false).validate(), isEmpty);
      // … sauf sur des séries normales, où il ne veut rien dire.
      expect(
        _tagged(
          const SetTechnique(
            kind: SetTechniqueKind.standard,
            lastSetOnly: true,
          ).validate(),
        ),
        <String>[r'$.lastSetOnly:unexpected_field'],
      );
      // Un pas d'échelle nul est signalé, sans faire lever la validation.
      expect(
        _tagged(
          const SetTechnique(
            kind: SetTechniqueKind.ladder,
            ladderStart: 1,
            ladderStep: 0,
            ladderTop: 5,
          ).validate(),
        ),
        <String>[r'$.ladderStep:below_min'],
      );
    });

    test('nombre de séries : une ligne de journal par série', () {
      // Série de tête et séries allégées : moins de séries allégées que de
      // séries.
      const backoff = SetTechnique(
        kind: SetTechniqueKind.topSetBackoff,
        backoffSets: 3,
        backoffDropPct: 0.1,
      );
      final top = basePrescription.copyWith(sets: 4, technique: backoff);
      expect(top.validate(), isEmpty);
      expect(_tagged(top.copyWith(sets: 3).validate()), <String>[
        r'$.technique.backoffSets:set_count',
      ]);
      // Vagues : `waves` × paliers.
      const wave = SetTechnique(
        kind: SetTechniqueKind.wave,
        waves: 2,
        waveReps: <int>[3, 2, 1],
      );
      final waves = basePrescription.copyWith(
        sets: 6,
        repsLow: 1,
        repsHigh: 3,
        technique: wave,
      );
      expect(waves.validate(), isEmpty);
      expect(_tagged(waves.copyWith(sets: 3).validate()), <String>[
        r'$.sets:set_count',
      ]);
      // Pyramide : un palier par série.
      const pyramid = SetTechnique(
        kind: SetTechniqueKind.pyramid,
        pyramidReps: <int>[10, 8, 6, 4, 2],
      );
      final pyramids = basePrescription.copyWith(
        sets: 5,
        repsLow: 2,
        repsHigh: 10,
        technique: pyramid,
      );
      expect(pyramids.validate(), isEmpty);
      expect(_tagged(pyramids.copyWith(sets: 4).validate()), <String>[
        r'$.sets:set_count',
      ]);
      // Échelle : marches × nombre d'échelles.
      const ladder = SetTechnique(
        kind: SetTechniqueKind.ladder,
        ladderStart: 1,
        ladderStep: 1,
        ladderTop: 5,
        ladderCount: 3,
      );
      final ladders = basePrescription.copyWith(
        sets: 15,
        repsLow: 1,
        repsHigh: 5,
        technique: ladder,
      );
      expect(ladders.validate(), isEmpty);
      expect(_tagged(ladders.copyWith(sets: 5).validate()), <String>[
        r'$.sets:set_count',
      ]);
      expect(
        ladders
            .copyWith(sets: 5, technique: ladder.copyWith(ladderCount: null))
            .validate(),
        isEmpty,
        reason: 'une seule échelle par défaut',
      );
      // Une échelle mal formée est signalée une fois, sur la technique.
      expect(
        _tagged(
          ladders
              .copyWith(technique: ladder.copyWith(ladderStep: 2, ladderTop: 6))
              .validate(),
        ),
        <String>[r'$.technique.ladderStep:ladder_step'],
      );
      // EMOM : une ligne par intervalle.
      const emom = SetTechnique(
        kind: SetTechniqueKind.emom,
        intervalSeconds: 60,
        intervals: 10,
      );
      final emoms = basePrescription.copyWith(sets: 10, technique: emom);
      expect(emoms.validate(), isEmpty);
      expect(_tagged(emoms.copyWith(sets: 3).validate()), <String>[
        r'$.sets:set_count',
      ]);
      // Densité, volume au temps : un seul bloc.
      const density = SetTechnique(
        kind: SetTechniqueKind.density,
        durationSeconds: 600,
      );
      final dense = basePrescription.copyWith(sets: 1, technique: density);
      expect(dense.validate(), isEmpty);
      expect(_tagged(dense.copyWith(sets: 3).validate()), <String>[
        r'$.sets:set_count',
      ]);
      const forTime = SetTechnique(
        kind: SetTechniqueKind.forTime,
        totalRepsTarget: 100,
      );
      final timed = basePrescription.copyWith(sets: 1, technique: forTime);
      expect(timed.validate(), isEmpty);
      expect(_tagged(timed.copyWith(sets: 2).validate()), <String>[
        r'$.sets:set_count',
      ]);
      // Les autres techniques laissent `sets` libre.
      const restPause = SetTechnique(
        kind: SetTechniqueKind.restPause,
        intraRestSeconds: 15,
      );
      expect(
        basePrescription.copyWith(technique: restPause).validate(),
        isEmpty,
      );
      expect(
        basePrescription.copyWith(sets: 1, technique: restPause).validate(),
        isEmpty,
      );
      // Une technique réservée à la dernière série ne change pas le compte.
      expect(
        basePrescription
            .copyWith(technique: density.copyWith(lastSetOnly: true))
            .validate(),
        isEmpty,
      );
      // Cibles série par série : autant que de séries.
      const target = SetTarget(repsLow: 8, repsHigh: 12);
      expect(
        basePrescription
            .copyWith(setTargets: const <SetTarget>[target, target, target])
            .validate(),
        isEmpty,
      );
      expect(
        _tagged(
          basePrescription
              .copyWith(setTargets: const <SetTarget>[target, target])
              .validate(),
        ),
        <String>[r'$.setTargets:set_count'],
      );
    });

    test('plage de répétitions : celle d\'une ligne de journal', () {
      // Cluster : mini-séries × répétitions dans la plage.
      const cluster = SetTechnique(
        kind: SetTechniqueKind.cluster,
        miniSets: 3,
        miniSetReps: 2,
        intraRestSeconds: 20,
      );
      final clusters = basePrescription.copyWith(
        repsLow: 6,
        repsHigh: 6,
        technique: cluster,
      );
      expect(clusters.validate(), isEmpty);
      expect(clusters.copyWith(repsLow: 5, repsHigh: 8).validate(), isEmpty);
      expect(
        _tagged(clusters.copyWith(repsLow: 8, repsHigh: 12).validate()),
        <String>[r'$:reps_mismatch'],
      );
      expect(
        _tagged(clusters.copyWith(repsLow: 3, repsHigh: 5).validate()),
        <String>[r'$:reps_mismatch'],
      );
      expect(
        clusters
            .copyWith(
              repsLow: 8,
              repsHigh: 12,
              technique: cluster.copyWith(lastSetOnly: true),
            )
            .validate(),
        isEmpty,
        reason: 'les autres séries sont normales',
      );
      // Vagues, pyramide, échelle : les bornes de leurs paliers.
      const wave = SetTechnique(
        kind: SetTechniqueKind.wave,
        waves: 2,
        waveReps: <int>[3, 2, 1],
      );
      final waves = basePrescription.copyWith(
        sets: 6,
        repsLow: 1,
        repsHigh: 3,
        technique: wave,
      );
      expect(waves.validate(), isEmpty);
      expect(_tagged(waves.copyWith(repsLow: 3).validate()), <String>[
        r'$:reps_mismatch',
      ]);
      const pyramid = SetTechnique(
        kind: SetTechniqueKind.pyramid,
        pyramidReps: <int>[10, 8, 6, 4, 2],
      );
      final pyramids = basePrescription.copyWith(
        sets: 5,
        repsLow: 2,
        repsHigh: 10,
        technique: pyramid,
      );
      expect(pyramids.validate(), isEmpty);
      expect(
        _tagged(pyramids.copyWith(repsLow: 8, repsHigh: 12).validate()),
        <String>[r'$:reps_mismatch'],
      );
      const ladder = SetTechnique(
        kind: SetTechniqueKind.ladder,
        ladderStart: 1,
        ladderStep: 1,
        ladderTop: 5,
      );
      final ladders = basePrescription.copyWith(
        sets: 5,
        repsLow: 1,
        repsHigh: 5,
        technique: ladder,
      );
      expect(ladders.validate(), isEmpty);
      expect(_tagged(ladders.copyWith(repsHigh: 6).validate()), <String>[
        r'$:reps_mismatch',
      ]);
    });

    test('deux écritures de la même intensité s\'accordent', () {
      // Part du 1RM : `percentOfOneRm` dans la plage de `intensity`.
      const range = IntensityTarget(
        basis: IntensityBasis.percentOneRm,
        value: 0.75,
        valueHigh: 0.85,
      );
      final percent = basePrescription.copyWith(
        loadBasis: LoadBasis.external,
        percentOfOneRm: 0.8,
        intensity: range,
      );
      expect(percent.validate(), isEmpty);
      expect(percent.copyWith(percentOfOneRm: 0.75).validate(), isEmpty);
      expect(percent.copyWith(percentOfOneRm: 0.85).validate(), isEmpty);
      expect(percent.copyWith(percentOfOneRm: null).validate(), isEmpty);
      expect(
        _tagged(percent.copyWith(percentOfOneRm: 0.9).validate()),
        <String>[r'$.intensity:intensity_mismatch'],
      );
      expect(
        _tagged(percent.copyWith(percentOfOneRm: 0.7).validate()),
        <String>[r'$.intensity:intensity_mismatch'],
      );
      // Sans haut de plage, la valeur exacte.
      final exact = percent.copyWith(
        intensity: range.copyWith(value: 0.8, valueHigh: null),
      );
      expect(exact.validate(), isEmpty);
      expect(codesOf(exact.copyWith(percentOfOneRm: 0.85).validate()), <String>[
        'intensity_mismatch',
      ]);
      // Une intensité relative au 1RM d'un AUTRE exercice ne se compare pas.
      expect(
        percent
            .copyWith(
              percentOfOneRm: 0.9,
              intensity: range.copyWith(
                referenceExerciseId: 'sl-traction-lestee',
              ),
            )
            .validate(),
        isEmpty,
      );
      // Répétitions en réserve : celles de `targetFlames` dans la plage.
      const rir = IntensityTarget(
        basis: IntensityBasis.rir,
        value: 2,
        valueHigh: 3,
      );
      final flames = basePrescription.copyWith(intensity: rir);
      expect(basePrescription.targetFlames, 7);
      expect(Flames.toRir(7), 2.0);
      expect(flames.validate(), isEmpty);
      expect(
        flames.copyWith(targetFlames: 5).validate(),
        isEmpty,
        reason: 'RIR 3',
      );
      expect(flames.copyWith(targetFlames: null).validate(), isEmpty);
      expect(_tagged(flames.copyWith(targetFlames: 9).validate()), <String>[
        r'$.intensity:intensity_mismatch',
      ]);
      expect(_tagged(flames.copyWith(targetFlames: 4).validate()), <String>[
        r'$.intensity:intensity_mismatch',
      ]);
      expect(
        flames
            .copyWith(
              targetFlames: 10,
              intensity: rir.copyWith(value: 0.0, valueHigh: null),
            )
            .validate(),
        isEmpty,
      );
      // 1 flamme : « 5 et plus », compatible avec toute plage qui atteint 5.
      expect(
        flames
            .copyWith(
              targetFlames: 1,
              intensity: rir.copyWith(value: 6.0, valueHigh: 8.0),
            )
            .validate(),
        isEmpty,
      );
      expect(codesOf(flames.copyWith(targetFlames: 1).validate()), <String>[
        'intensity_mismatch',
      ]);
      // Des flammes hors de 1..10 sont signalées, sans faire lever la
      // validation.
      expect(_tagged(flames.copyWith(targetFlames: 0).validate()), <String>[
        r'$.targetFlames:below_min',
      ]);
      // Allègement : le `pct` de la règle est celui de la technique.
      const backoff = SetTechnique(
        kind: SetTechniqueKind.topSetBackoff,
        backoffSets: 3,
        backoffDropPct: 0.1,
      );
      const rule = AutoregulationRule(
        kind: AutoregulationKind.backoffFromTopSet,
        pct: 0.1,
      );
      final top = basePrescription.copyWith(
        sets: 4,
        technique: backoff,
        autoregulation: const <AutoregulationRule>[rule],
      );
      expect(top.validate(), isEmpty);
      expect(
        top
            .copyWith(
              autoregulation: <AutoregulationRule>[rule.copyWith(pct: null)],
            )
            .validate(),
        isEmpty,
        reason: 'pct absent : celui de la technique',
      );
      expect(
        _tagged(
          top
              .copyWith(
                autoregulation: <AutoregulationRule>[rule.copyWith(pct: 0.15)],
              )
              .validate(),
        ),
        <String>[r'$.autoregulation:intensity_mismatch'],
      );
      // Sans technique de série de tête, rien à comparer.
      expect(
        basePrescription
            .copyWith(
              autoregulation: <AutoregulationRule>[rule.copyWith(pct: 0.15)],
            )
            .validate(),
        isEmpty,
      );
    });

    test('série indivisible, nature de la récupération', () {
      final run = basePrescription.copyWith(
        exerciseId: 'ca-fractionne-400m',
        sets: 6,
        repsLow: null,
        repsHigh: null,
        distanceMeters: 400.0,
        restSeconds: 90,
        restMode: RestMode.jog,
      );
      expect(run.validate(), isEmpty);
      expect(run.toJson()['restMode'], 'jog');
      expect(ExercisePrescription.fromJson(viaJsonText(run.toJson())), run);
      expect(RestMode.values, <RestMode>[
        RestMode.passive,
        RestMode.walk,
        RestMode.jog,
      ]);
      expect(() => RestMode.fromCode('sprint'), throwsFormatException);
      final unbroken = basePrescription.copyWith(unbroken: true);
      expect(unbroken.validate(), isEmpty);
      expect(unbroken.toJson()['unbroken'], isTrue);
      expect(unbroken.toJson().keys.last, 'unbroken');
      expect(
        ExercisePrescription.fromJson(viaJsonText(unbroken.toJson())),
        unbroken,
      );
      expect(
        () => ExercisePrescription.fromJson(<String, Object?>{
          ...viaJsonText(unbroken.toJson()),
          'unbroken': 'oui',
        }),
        throwsFormatException,
      );
    });

    test(
      'groupes d\'exercices enchaînés : séance prescrite, séance du jour',
      () {
        final first = basePrescription.copyWith(groupId: 'g1');
        final second = basePrescription.copyWith(
          slotId: 'd0s1',
          exerciseId: 'sl-traction-lestee',
          groupId: 'g1',
        );
        const circuit = GroupSpec(
          groupId: 'g1',
          format: GroupFormat.circuit,
          rounds: 3,
          restBetweenRoundsSeconds: 60,
        );
        final day = DayPrescription(
          dayIndex: 0,
          items: <ExercisePrescription>[first, second],
          groups: const <GroupSpec>[circuit],
        );
        expect(day.validate(), isEmpty);
        expect(DayPrescription.fromJson(viaJsonText(day.toJson())), day);
        expect(day.copyWith(groups: null).toJson().keys.toList(), <String>[
          'dayIndex',
          'items',
        ]);
        expect(
          _tagged(
            day
                .copyWith(groups: <GroupSpec>[circuit.copyWith(rounds: null)])
                .validate(),
          ),
          <String>[r'$.groups[0].rounds:missing_field'],
        );
        expect(
          _tagged(
            day
                .copyWith(
                  groups: <GroupSpec>[
                    for (var i = 0; i < 21; i++)
                      GroupSpec(groupId: 'g$i', format: GroupFormat.superset),
                  ],
                )
                .validate(),
          ),
          contains(r'$.groups:too_long'),
        );
        // Groupes distincts, et chacun a au moins un membre dans la séance.
        expect(
          _tagged(
            day
                .copyWith(groups: const <GroupSpec>[circuit, circuit])
                .validate(),
          ),
          <String>[r'$.groups:duplicate'],
        );
        const orphan = GroupSpec(groupId: 'g2', format: GroupFormat.superset);
        expect(
          _tagged(
            day.copyWith(groups: const <GroupSpec>[circuit, orphan]).validate(),
          ),
          <String>[r'$.groups[1].groupId:unknown_group'],
        );
        final plan = SessionPlan(
          date: CivilDate(2026, 10, 5),
          blockId: 'b0',
          weekIndex: 0,
          dayIndex: 0,
          items: <ExercisePrescription>[first, second],
          adjustments: const <SessionAdjustment>[],
          confidence: 0.8,
          reasons: const <Reason>[],
          phase: SeasonPhaseKind.maintenance,
          groups: const <GroupSpec>[circuit],
        );
        expect(plan.validate(), isEmpty);
        expect(SessionPlan.fromJson(viaJsonText(plan.toJson())), plan);
        expect(
          plan.copyWith(groups: null).toJson().containsKey('groups'),
          isFalse,
        );
        expect(
          _tagged(
            plan
                .copyWith(
                  groups: <GroupSpec>[circuit.copyWith(durationSeconds: 600)],
                )
                .validate(),
          ),
          <String>[r'$.groups[0].durationSeconds:unexpected_field'],
        );
        expect(
          _tagged(plan.copyWith(groups: const <GroupSpec>[orphan]).validate()),
          <String>[r'$.groups[0].groupId:unknown_group'],
        );
      },
    );

    test('intensité et autorégulation : plages', () {
      // `hold_fraction` n'existe plus : une part du maintien max s'écrit
      // `percent_benchmark` avec le test de référence `max_hold`.
      const hold = IntensityTarget(
        basis: IntensityBasis.percentBenchmark,
        value: 0.6,
        valueHigh: 0.7,
        referenceKind: BenchmarkKind.maxHold,
      );
      expect(hold.validate(), isEmpty);
      expect(codesOf(hold.copyWith(value: 0.8).validate()), <String>[
        'range_inverted',
      ]);
      expect(codesOf(hold.copyWith(valueHigh: 1.6).validate()), <String>[
        'above_max',
      ]);
      const rir = IntensityTarget(
        basis: IntensityBasis.rir,
        value: 2,
        valueHigh: 3,
      );
      expect(rir.validate(), isEmpty);
      // `progression_step` et `stepExerciseId` n'existent plus : le seul
      // exercice cité par une intensité est celui du test de référence.
      const step = IntensityTarget(
        basis: IntensityBasis.percentOneRm,
        value: 0.8,
        referenceExerciseId: 'cs-front-lever-tuck-avance',
      );
      expect(step.validate(), isEmpty);
      final ids = <String>{};
      step.collectExerciseIds(ids);
      expect(ids, <String>{'cs-front-lever-tuck-avance'});
      expect(
        IntensityTarget.fromJson(<String, Object?>{
          ...viaJsonText(step.toJson()),
          'stepExerciseId': 'cs-front-lever',
        }),
        step,
        reason: 'champ retiré : ignoré à la lecture',
      );
      const rule = AutoregulationRule(
        kind: AutoregulationKind.loadFromRir,
        rirFloor: 1,
        rirCeiling: 3,
      );
      expect(rule.validate(), isEmpty);
      expect(codesOf(rule.copyWith(rirFloor: 4.0).validate()), <String>[
        'range_inverted',
      ]);
      const stop = AutoregulationRule(
        kind: AutoregulationKind.stopAtRir,
        rirFloor: 1,
        minSets: 2,
        maxSets: 6,
      );
      expect(stop.validate(), isEmpty);
      expect(codesOf(stop.copyWith(minSets: 7).validate()), <String>[
        'range_inverted',
      ]);
    });

    test('intensité : valeur obligatoire, bases, bornes par base', () {
      expect(IntensityBasis.values, <IntensityBasis>[
        IntensityBasis.percentOneRm,
        IntensityBasis.percentBenchmark,
        IntensityBasis.rir,
        IntensityBasis.speedFraction,
        IntensityBasis.bodyweightFraction,
        IntensityBasis.absoluteSpeed,
      ]);
      for (final removed in <String>[
        'hold_fraction',
        'progression_step',
        'heart_rate_fraction',
      ]) {
        expect(
          () => IntensityBasis.fromCode(removed),
          throwsFormatException,
          reason: removed,
        );
      }
      // `value` est obligatoire.
      expect(
        () => IntensityTarget.fromJson(const <String, Object?>{'basis': 'rir'}),
        throwsFormatException,
      );
      expect(
        IntensityTarget.fromJson(const <String, Object?>{
          'basis': 'rir',
          'value': 2,
        }),
        const IntensityTarget(basis: IntensityBasis.rir, value: 2),
      );
      // Bases en part : de 0 à 1,5.
      for (final basis in <IntensityBasis>[
        IntensityBasis.percentOneRm,
        IntensityBasis.speedFraction,
        IntensityBasis.bodyweightFraction,
      ]) {
        final t = IntensityTarget(basis: basis, value: 1.5);
        expect(t.validate(), isEmpty, reason: basis.code);
        expect(_tagged(t.copyWith(value: 1.6).validate()), <String>[
          r'$.value:above_max',
        ], reason: basis.code);
        expect(
          _tagged(t.copyWith(value: 1.0, valueHigh: 2.0).validate()),
          <String>[r'$.valueHigh:above_max'],
          reason: basis.code,
        );
      }
      const benchmark = IntensityTarget(
        basis: IntensityBasis.percentBenchmark,
        value: 0.7,
        referenceKind: BenchmarkKind.maxReps,
      );
      expect(benchmark.validate(), isEmpty);
      expect(_tagged(benchmark.copyWith(value: 1.6).validate()), <String>[
        r'$.value:above_max',
      ]);
      expect(
        _tagged(benchmark.copyWith(referenceKind: null).validate()),
        <String>[r'$.referenceKind:missing_field'],
      );
      // Répétitions en réserve : de 0 à 10.
      const rir = IntensityTarget(basis: IntensityBasis.rir, value: 10);
      expect(rir.validate(), isEmpty);
      expect(_tagged(rir.copyWith(value: 10.5).validate()), <String>[
        r'$.value:above_max',
      ]);
      expect(
        _tagged(rir.copyWith(value: 2.0, valueHigh: 11.0).validate()),
        <String>[r'$.valueHigh:above_max'],
      );
      // Vitesse, en mètres par seconde : de 0 à 15.
      const speed = IntensityTarget(
        basis: IntensityBasis.absoluteSpeed,
        value: 4.2,
        valueHigh: 4.5,
      );
      expect(speed.validate(), isEmpty);
      expect(speed.copyWith(value: 12.0, valueHigh: 15.0).validate(), isEmpty);
      final tooFast = _tagged(
        speed.copyWith(value: 15.5, valueHigh: null).validate(),
      );
      expect(tooFast, isNotEmpty);
      expect(tooFast.toSet(), <String>{r'$.value:above_max'});
      final negative = _tagged(
        speed.copyWith(value: -0.1, valueHigh: null).validate(),
      );
      expect(negative, isNotEmpty);
      expect(negative.toSet(), <String>{r'$.value:below_min'});
      expect(codesOf(speed.copyWith(value: 5.0).validate()), <String>[
        'range_inverted',
      ]);
      expect(
        codesOf(speed.copyWith(value: double.nan).validate()),
        contains('not_finite'),
      );
      // `eventId` : seulement pour une part de l'allure cible d'une course.
      const pace = IntensityTarget(
        basis: IntensityBasis.speedFraction,
        value: 0.95,
        valueHigh: 1.05,
        eventId: 'e1',
      );
      expect(pace.validate(), isEmpty);
      expect(pace.toJson()['eventId'], 'e1');
      expect(IntensityTarget.fromJson(viaJsonText(pace.toJson())), pace);
      expect(
        pace
            .copyWith(
              eventId: null,
              referenceKind: BenchmarkKind.timeTrial,
              referenceExerciseId: 'ca-fractionne-400m',
            )
            .validate(),
        isEmpty,
      );
      expect(_tagged(pace.copyWith(eventId: '').validate()), <String>[
        r'$.eventId:too_short',
      ]);
      expect(
        _tagged(pace.copyWith(basis: IntensityBasis.percentOneRm).validate()),
        <String>[r'$.eventId:unexpected_field'],
      );
      expect(
        _tagged(pace.copyWith(basis: IntensityBasis.absoluteSpeed).validate()),
        <String>[r'$.eventId:unexpected_field'],
      );
      // Plafond d'effort.
      expect(pace.copyWith(rirCap: 2.0).validate(), isEmpty);
      expect(_tagged(pace.copyWith(rirCap: 10.5).validate()), <String>[
        r'$.rirCap:above_max',
      ]);
    });

    test('autorégulation : arrêt sur baisse de propreté, allègement', () {
      expect(AutoregulationKind.values, hasLength(7));
      expect(AutoregulationKind.stopOnQualityDrop.code, 'stop_on_quality_drop');
      const quality = AutoregulationRule(
        kind: AutoregulationKind.stopOnQualityDrop,
        qualityFloor: 3,
        minSets: 2,
        maxSets: 6,
      );
      expect(quality.validate(), isEmpty);
      expect(
        AutoregulationRule.fromJson(viaJsonText(quality.toJson())),
        quality,
      );
      expect(
        quality.copyWith(minSets: null, maxSets: null).validate(),
        isEmpty,
      );
      expect(_tagged(quality.copyWith(qualityFloor: null).validate()), <String>[
        r'$.qualityFloor:missing_field',
      ]);
      expect(_tagged(quality.copyWith(qualityFloor: 6).validate()), <String>[
        r'$.qualityFloor:above_max',
      ]);
      expect(_tagged(quality.copyWith(qualityFloor: 0).validate()), <String>[
        r'$.qualityFloor:below_min',
      ]);
      expect(codesOf(quality.copyWith(minSets: 7).validate()), <String>[
        'range_inverted',
      ]);
      expect(_tagged(quality.copyWith(repDrop: 2).validate()), <String>[
        r'$.repDrop:unexpected_field',
      ]);
      // La propreté minimale n'appartient qu'à cette règle.
      const stop = AutoregulationRule(
        kind: AutoregulationKind.stopAtRir,
        rirFloor: 1,
      );
      expect(_tagged(stop.copyWith(qualityFloor: 3).validate()), <String>[
        r'$.qualityFloor:unexpected_field',
      ]);
      // Allègement : le pourcentage est facultatif.
      const backoff = AutoregulationRule(
        kind: AutoregulationKind.backoffFromTopSet,
      );
      expect(backoff.validate(), isEmpty);
      expect(backoff.toJson().keys.toList(), <String>['kind']);
      expect(backoff.copyWith(pct: 0.1, rirCeiling: 2.0).validate(), isEmpty);
      expect(_tagged(backoff.copyWith(pct: 1.1).validate()), <String>[
        r'$.pct:above_max',
      ]);
      // Dans une prescription : trois règles au plus.
      final practice = basePrescription.copyWith(
        autoregulation: const <AutoregulationRule>[quality],
      );
      expect(practice.validate(), isEmpty);
      expect(
        ExercisePrescription.fromJson(viaJsonText(practice.toJson())),
        practice,
      );
      expect(
        _tagged(
          practice
              .copyWith(
                autoregulation: const <AutoregulationRule>[
                  quality,
                  quality,
                  quality,
                  quality,
                ],
              )
              .validate(),
        ),
        <String>[r'$.autoregulation:too_long'],
      );
    });

    test('journal : mini-séries, tentatives, qualité', () {
      // Une ligne de journal par série : les mini-séries d'un cluster sont
      // des `parts` de cette ligne (`miniSetIndex` et le rôle `mini`
      // n'existent plus).
      final mini = baseSet.copyWith(
        technique: SetTechniqueKind.cluster,
        role: SetRole.straight,
        reps: 6,
        parts: const <SetPart>[
          SetPart(reps: 2),
          SetPart(reps: 2, restBeforeSeconds: 20),
          SetPart(reps: 2, restBeforeSeconds: 20),
        ],
        restBeforeSeconds: 20,
        quality: 4,
      );
      expect(mini.validate(), isEmpty);
      expect(SetRecord.fromJson(viaJsonText(mini.toJson())), mini);
      expect(codesOf(mini.copyWith(quality: 6).validate()), <String>[
        'above_max',
      ]);
      expect(mini.setIndex, 0);
      expect(mini.toJson().containsKey('miniSetIndex'), isFalse);
      expect(
        SetRecord.fromJson(<String, Object?>{
          ...viaJsonText(mini.toJson()),
          'miniSetIndex': 2,
        }),
        mini,
        reason: 'champ retiré : ignoré à la lecture',
      );
      expect(SetRole.values, <SetRole>[
        SetRole.straight,
        SetRole.top,
        SetRole.backOff,
        SetRole.wave,
        SetRole.test,
        SetRole.attempt,
        SetRole.warmup,
        SetRole.rung,
        SetRole.interval,
      ]);
      expect(() => SetRole.fromCode('mini'), throwsFormatException);
      final attempt = baseSet.copyWith(
        kind: SetKind.test,
        role: SetRole.attempt,
        attemptIndex: 0,
        reps: 1,
      );
      expect(attempt.validate(), isEmpty);
      expect(codesOf(attempt.copyWith(attemptIndex: 4).validate()), <String>[
        'above_max',
      ]);
      final day = session('s1', '2027-04-17').copyWith(eventId: 'e1');
      expect(day.validate(), isEmpty);
      expect(SessionRecord.fromJson(viaJsonText(day.toJson())), day);
    });

    test('journal : parties d\'une série', () {
      expect(const SetPart(reps: 2).validate(), isEmpty);
      expect(const SetPart(seconds: 10).validate(), isEmpty);
      const drop = SetPart(reps: 8, externalLoadKg: 40, restBeforeSeconds: 0);
      expect(drop.validate(), isEmpty);
      expect(SetPart.fromJson(viaJsonText(drop.toJson())), drop);
      // Au moins des répétitions ou une durée.
      expect(_tagged(const SetPart().validate()), <String>[r'$:no_measure']);
      expect(
        _tagged(
          const SetPart(externalLoadKg: 40, restBeforeSeconds: 15).validate(),
        ),
        <String>[r'$:no_measure'],
      );
      expect(_tagged(const SetPart(reps: 1001).validate()), <String>[
        r'$.reps:above_max',
      ]);
      expect(
        _tagged(drop.copyWith(restBeforeSeconds: 3601).validate()),
        <String>[r'$.restBeforeSeconds:above_max'],
      );
      // Dans une série : de 1 à 120 parties, chacune contrôlée à son rang.
      final dropSet = baseSet.copyWith(
        technique: SetTechniqueKind.dropSet,
        externalLoadKg: 50.0,
        reps: 24,
        parts: const <SetPart>[
          SetPart(reps: 10),
          SetPart(reps: 8, externalLoadKg: 40),
          SetPart(reps: 6, externalLoadKg: 30),
        ],
      );
      expect(dropSet.validate(), isEmpty);
      expect(SetRecord.fromJson(viaJsonText(dropSet.toJson())), dropSet);
      expect(
        _tagged(
          dropSet
              .copyWith(parts: const <SetPart>[SetPart(reps: 10), SetPart()])
              .validate(),
        ),
        <String>[r'$.parts[1]:no_measure'],
      );
      expect(
        _tagged(dropSet.copyWith(parts: const <SetPart>[]).validate()),
        <String>[r'$.parts:too_short'],
      );
      expect(
        _tagged(
          dropSet
              .copyWith(
                parts: <SetPart>[
                  for (var i = 0; i < 121; i++) const SetPart(reps: 1),
                ],
              )
              .validate(),
        ),
        contains(r'$.parts:too_long'),
      );
      // Quand toutes les parties ont des répétitions, leur somme est le
      // total de la série.
      expect(_tagged(dropSet.copyWith(reps: 25).validate()), <String>[
        r'$.parts:parts_mismatch',
      ]);
      expect(
        dropSet
            .copyWith(
              parts: const <SetPart>[SetPart(reps: 10), SetPart(seconds: 20)],
            )
            .validate(),
        isEmpty,
        reason: 'une partie sans répétitions : pas de total à recouper',
      );
      // Sans parties, la série s'écrit comme en 0.3.0.
      expect(
        dropSet.copyWith(parts: null).toJson().containsKey('parts'),
        isFalse,
      );
    });

    test('journal : résultats des groupes d\'exercices enchaînés', () {
      const result = GroupResult(
        groupId: 'g1',
        completed: true,
        elapsedSeconds: 754,
        rounds: 5,
        extraReps: 0,
      );
      expect(result.validate(), isEmpty);
      expect(GroupResult.fromJson(viaJsonText(result.toJson())), result);
      expect(
        const GroupResult(
          groupId: 'g1',
          completed: false,
        ).toJson().keys.toList(),
        <String>['groupId', 'completed'],
      );
      expect(_tagged(result.copyWith(groupId: '').validate()), <String>[
        r'$.groupId:too_short',
      ]);
      expect(_tagged(result.copyWith(extraReps: 10001).validate()), <String>[
        r'$.extraReps:above_max',
      ]);
      expect(_tagged(result.copyWith(rounds: -1).validate()), <String>[
        r'$.rounds:below_min',
      ]);
      final done = session(
        's1',
        '2026-10-05',
      ).copyWith(groupResults: const <GroupResult>[result]);
      expect(done.validate(), isEmpty);
      expect(SessionRecord.fromJson(viaJsonText(done.toJson())), done);
      expect(done.toJson().keys.last, 'groupResults');
      expect(
        session('s1', '2026-10-05').toJson().containsKey('groupResults'),
        isFalse,
      );
      expect(
        _tagged(
          done
              .copyWith(
                groupResults: <GroupResult>[
                  result.copyWith(elapsedSeconds: 86401),
                ],
              )
              .validate(),
        ),
        <String>[r'$.groupResults[0].elapsedSeconds:above_max'],
      );
      expect(
        _tagged(
          done
              .copyWith(
                groupResults: <GroupResult>[
                  for (var i = 0; i < 21; i++)
                    GroupResult(groupId: 'g$i', completed: true),
                ],
              )
              .validate(),
        ),
        <String>[r'$.groupResults:too_long'],
      );
      // Un résultat au plus par groupe.
      expect(
        _tagged(
          done
              .copyWith(groupResults: const <GroupResult>[result, result])
              .validate(),
        ),
        <String>[r'$.groupResults:duplicate'],
      );
    });
  });

  group('saison, compétition, figures', () {
    SeasonPhase phase(
      int index,
      SeasonPhaseKind kind,
      String start,
      int weeks,
    ) => SeasonPhase(
      index: index,
      kind: kind,
      startDate: CivilDate.parse(start),
      weeks: weeks,
      reasons: const <Reason>[],
    );
    SeasonPlan plan(List<SeasonPhase> phases) => SeasonPlan(
      createdOn: CivilDate(2026, 10, 5),
      engineVersion: '0.0.0-test',
      eventIds: const <String>['e1'],
      phases: phases,
      reasons: const <Reason>[],
    );

    test('plan de saison : phases contiguës, rangs exacts', () {
      final ok = plan(<SeasonPhase>[
        phase(0, SeasonPhaseKind.accumulation, '2026-10-05', 6),
        phase(1, SeasonPhaseKind.intensification, '2026-11-16', 5),
        phase(2, SeasonPhaseKind.realization, '2026-12-21', 3),
        phase(3, SeasonPhaseKind.taper, '2027-01-11', 2),
        phase(4, SeasonPhaseKind.competition, '2027-01-25', 1),
        phase(5, SeasonPhaseKind.transition, '2027-02-01', 1),
        phase(6, SeasonPhaseKind.reintroduction, '2027-02-08', 2),
        phase(7, SeasonPhaseKind.maintenance, '2027-02-22', 4),
      ]);
      expect(ok.validate(), isEmpty);
      expect(SeasonPlan.fromJson(viaJsonText(ok.toJson())), ok);
      final gap = plan(<SeasonPhase>[
        phase(0, SeasonPhaseKind.accumulation, '2026-10-05', 6),
        phase(1, SeasonPhaseKind.taper, '2026-11-23', 2),
      ]);
      expect(codesOf(gap.validate()), <String>['phases_not_contiguous']);
      final overlap = plan(<SeasonPhase>[
        phase(0, SeasonPhaseKind.accumulation, '2026-10-05', 6),
        phase(1, SeasonPhaseKind.taper, '2026-11-09', 2),
      ]);
      expect(codesOf(overlap.validate()), <String>['phases_not_contiguous']);
      final rank = plan(<SeasonPhase>[
        phase(1, SeasonPhaseKind.accumulation, '2026-10-05', 6),
      ]);
      expect(codesOf(rank.validate()), <String>['index_mismatch']);
      expect(codesOf(plan(const <SeasonPhase>[]).validate()), <String>[
        'too_short',
      ]);
      // Le chemin désigne la phase fautive.
      expect(_tagged(gap.validate()), <String>[
        r'$.phases[1].startDate:phases_not_contiguous',
      ]);
      expect(_tagged(rank.validate()), <String>[
        r'$.phases[0].index:index_mismatch',
      ]);
    });

    test('phases de saison : dix natures, dont entretien et reprise', () {
      expect(SeasonPhaseKind.values, <SeasonPhaseKind>[
        SeasonPhaseKind.accumulation,
        SeasonPhaseKind.intensification,
        SeasonPhaseKind.realization,
        SeasonPhaseKind.taper,
        SeasonPhaseKind.competition,
        SeasonPhaseKind.transition,
        SeasonPhaseKind.test,
        SeasonPhaseKind.deload,
        SeasonPhaseKind.maintenance,
        SeasonPhaseKind.reintroduction,
      ]);
      expect(
        SeasonPhaseKind.fromCode('maintenance'),
        SeasonPhaseKind.maintenance,
      );
      expect(
        SeasonPhaseKind.fromCode('reintroduction'),
        SeasonPhaseKind.reintroduction,
      );
      expect(() => SeasonPhaseKind.fromCode('peak'), throwsFormatException);
      final back = phase(0, SeasonPhaseKind.reintroduction, '2026-10-05', 3);
      expect(back.validate(), isEmpty);
      expect(back.toJson()['kind'], 'reintroduction');
      expect(SeasonPhase.fromJson(viaJsonText(back.toJson())), back);
    });

    test('plan de saison : échéances connues, sans doublon', () {
      final known = plan(<SeasonPhase>[
        phase(
          0,
          SeasonPhaseKind.accumulation,
          '2026-10-05',
          6,
        ).copyWith(eventId: 'e1'),
        phase(1, SeasonPhaseKind.taper, '2026-11-16', 2),
      ]);
      expect(known.validate(), isEmpty);
      expect(SeasonPlan.fromJson(viaJsonText(known.toJson())), known);
      final unknown = plan(<SeasonPhase>[
        phase(0, SeasonPhaseKind.accumulation, '2026-10-05', 6),
        phase(
          1,
          SeasonPhaseKind.taper,
          '2026-11-16',
          2,
        ).copyWith(eventId: 'e2'),
      ]);
      expect(_tagged(unknown.validate()), <String>[
        r'$.phases[1].eventId:unknown_event',
      ]);
      expect(
        unknown.copyWith(eventIds: const <String>['e1', 'e2']).validate(),
        isEmpty,
      );
      expect(
        _tagged(known.copyWith(eventIds: const <String>[]).validate()),
        <String>[r'$.phases[0].eventId:unknown_event'],
      );
      expect(
        _tagged(
          known.copyWith(eventIds: const <String>['e1', 'e1']).validate(),
        ),
        <String>[r'$.eventIds:duplicate'],
      );
    });

    test('phase propre à un mouvement : mouvements distincts', () {
      const overrides = <PhaseOverride>[
        PhaseOverride(
          exerciseId: 'sl-muscle-up-leste',
          kind: SeasonPhaseKind.accumulation,
          volumeFactor: 1,
          intensityFactor: 0.8,
        ),
        PhaseOverride(
          exerciseId: 'sl-squat-competition',
          kind: SeasonPhaseKind.maintenance,
        ),
      ];
      final base = phase(0, SeasonPhaseKind.intensification, '2026-10-05', 5);
      final ok = base.copyWith(overrides: overrides);
      expect(ok.validate(), isEmpty);
      expect(SeasonPhase.fromJson(viaJsonText(ok.toJson())), ok);
      expect(ok.toJson().keys.last, 'overrides');
      expect(base.toJson().containsKey('overrides'), isFalse);
      final ids = <String>{};
      ok.collectExerciseIds(ids);
      expect(ids, <String>{'sl-muscle-up-leste', 'sl-squat-competition'});
      final twice = base.copyWith(
        overrides: <PhaseOverride>[overrides.first, overrides.first],
      );
      expect(_tagged(twice.validate()), <String>[r'$.overrides:duplicate']);
      expect(_tagged(plan(<SeasonPhase>[twice]).validate()), <String>[
        r'$.phases[0].overrides:duplicate',
      ]);
      expect(plan(<SeasonPhase>[ok]).validate(), isEmpty);
      expect(
        _tagged(
          base
              .copyWith(
                overrides: <PhaseOverride>[
                  overrides.first.copyWith(volumeFactor: 2.5),
                ],
              )
              .validate(),
        ),
        <String>[r'$.overrides[0].volumeFactor:above_max'],
      );
      expect(
        _tagged(
          base
              .copyWith(
                overrides: <PhaseOverride>[
                  overrides.first.copyWith(exerciseId: ''),
                ],
              )
              .validate(),
        ),
        <String>[r'$.overrides[0].exerciseId:too_short'],
      );
      expect(
        _tagged(
          base
              .copyWith(
                overrides: <PhaseOverride>[
                  for (var i = 0; i < 21; i++)
                    PhaseOverride(
                      exerciseId: 'x$i',
                      kind: SeasonPhaseKind.deload,
                    ),
                ],
              )
              .validate(),
        ),
        <String>[r'$.overrides:too_long'],
      );
    });

    test('le plan de saison voyage dans les requêtes sans les casser', () {
      final season = plan(<SeasonPhase>[
        phase(0, SeasonPhaseKind.accumulation, '2026-10-05', 6),
      ]);
      final request = PlanRequest(
        profile: baseProfile(),
        seed: 1,
        startDate: CivilDate(2026, 10, 5),
        locks: const <PlanLock>[],
        season: season,
      );
      expect(request.validate(), isEmpty);
      expect(PlanRequest.fromJson(viaJsonText(request.toJson())), request);
      // Sans plan de saison, la requête est celle de 0.3.0.
      expect(
        request.copyWith(season: null).toJson().containsKey('season'),
        isFalse,
      );
      final block = ProgramBlock(pass1: basePass1(), pass2: basePass2());
      final input = AdaptInput(
        profile: baseProfile(),
        block: block,
        log: const TrainingLog(sessions: <SessionRecord>[]),
        today: CivilDate(2026, 10, 6),
        season: season,
      );
      expect(input.validate(), isEmpty);
      expect(AdaptInput.fromJson(viaJsonText(input.toJson())), input);
    });

    test('intention du bloc, de la semaine, ondulation', () {
      final pass1 = basePass1().copyWith(
        intent: const BlockIntent(
          phase: SeasonPhaseKind.intensification,
          seasonPhaseIndex: 1,
          eventId: 'e1',
          weeksToEvent: 10,
          undulation: UndulationModel.daily,
          specialization: Specialization(
            kind: SpecializationKind.exercise,
            exerciseId: 'sl-muscle-up-leste',
            weeks: 8,
            maintenance: MaintenancePolicy.maintain,
          ),
        ),
        skillLadders: const <SkillLadder>[
          SkillLadder(
            targetExerciseId: 'cs-front-lever',
            steps: <SkillStep>[
              SkillStep(
                exerciseId: 'cs-front-lever-tuck-avance',
                criterion: StepCriterion(
                  holdSeconds: 15,
                  sets: 3,
                  minQuality: 4,
                  sessions: 2,
                  minWeeks: 8,
                ),
              ),
              SkillStep(
                exerciseId: 'cs-front-lever',
                criterion: StepCriterion(holdSeconds: 5, sets: 1),
              ),
            ],
          ),
        ],
      );
      expect(pass1.validate(), isEmpty);
      expect(Pass1Plan.fromJson(viaJsonText(pass1.toJson())), pass1);
      final ids = <String>{};
      pass1.collectExerciseIds(ids);
      expect(
        ids,
        containsAll(<String>[
          'sl-muscle-up-leste',
          'cs-front-lever',
          'cs-front-lever-tuck-avance',
        ]),
      );
      final week = basePass2().weeks.last.copyWith(
        intent: WeekIntent.taper,
        days: const <DayPrescription>[
          DayPrescription(
            dayIndex: 0,
            items: <ExercisePrescription>[basePrescription],
            stress: DayStress.light,
          ),
        ],
      );
      expect(week.validate(), isEmpty);
      expect(week.kind, WeekKind.deload, reason: '`kind` reste renseigné');
      expect(WeekPrescription.fromJson(viaJsonText(week.toJson())), week);
    });

    test('échelle de figure : étapes distinctes, la dernière est la cible', () {
      const criterion = StepCriterion(holdSeconds: 10, sets: 3);
      const ladder = SkillLadder(
        targetExerciseId: 'cs-planche',
        steps: <SkillStep>[
          SkillStep(exerciseId: 'cs-planche-lean', criterion: criterion),
          SkillStep(exerciseId: 'cs-planche-tuck', criterion: criterion),
          SkillStep(exerciseId: 'cs-planche', criterion: criterion),
        ],
      );
      expect(ladder.validate(), isEmpty);
      expect(
        codesOf(
          ladder
              .copyWith(
                steps: const <SkillStep>[
                  SkillStep(
                    exerciseId: 'cs-planche-lean',
                    criterion: criterion,
                  ),
                ],
              )
              .validate(),
        ),
        <String>['last_step_not_target'],
      );
      expect(
        codesOf(
          ladder
              .copyWith(
                steps: const <SkillStep>[
                  SkillStep(exerciseId: 'cs-planche', criterion: criterion),
                  SkillStep(exerciseId: 'cs-planche', criterion: criterion),
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
      expect(codesOf(const StepCriterion(sets: 3).validate()), <String>[
        'no_measure',
      ]);
    });

    test('compétition de force : mouvements distincts, tentatives', () {
      final event = SeasonEvent(
        id: 'e1',
        kind: EventKind.strengthCompetition,
        priority: EventPriority.main,
        date: CivilDate(2027, 4, 17),
        ruleset: 'final_rep_all4',
        weightClassKg: 73,
        lifts: const <CompetitionLift>[
          CompetitionLift(
            exerciseId: 'sl-muscle-up-leste',
            attempts: 3,
            minIncrementKg: 1.25,
            bestKg: 25,
          ),
          CompetitionLift(
            exerciseId: 'sl-squat-competition',
            attempts: 3,
            minIncrementKg: 2.5,
          ),
        ],
      );
      expect(event.validate(), isEmpty);
      expect(SeasonEvent.fromJson(viaJsonText(event.toJson())), event);
      expect(
        codesOf(
          event
              .copyWith(
                lifts: const <CompetitionLift>[
                  CompetitionLift(exerciseId: 'sl-dips-leste', attempts: 3),
                  CompetitionLift(exerciseId: 'sl-dips-leste', attempts: 3),
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
      expect(
        codesOf(
          event
              .copyWith(
                lifts: const <CompetitionLift>[
                  CompetitionLift(exerciseId: 'sl-dips-leste', attempts: 5),
                ],
              )
              .validate(),
        ),
        <String>['above_max'],
      );
      const station = EventStation(exerciseId: 'sw-pompe', reps: 30);
      expect(station.validate(), isEmpty);
      expect(codesOf(station.copyWith(seconds: 30).validate()), <String>[
        'measure_count',
      ]);
      // Limite de temps et repos propres à un poste.
      final timed = station.copyWith(
        unbroken: true,
        timeLimitSeconds: 120,
        restAfterSeconds: 60,
      );
      expect(timed.validate(), isEmpty);
      expect(EventStation.fromJson(viaJsonText(timed.toJson())), timed);
      expect(_tagged(timed.copyWith(timeLimitSeconds: 0).validate()), <String>[
        r'$.timeLimitSeconds:below_min',
      ]);
      expect(
        _tagged(timed.copyWith(restAfterSeconds: 3601).validate()),
        <String>[r'$.restAfterSeconds:above_max'],
      );
      expect(
        const EventStation(exerciseId: 'sw-pompe', seconds: 30).validate(),
        isEmpty,
      );
    });

    test('échéances : répétitions, freestyle, course, objectifs liés', () {
      // Une compétition de répétitions n'exige que son format.
      final reps = SeasonEvent(
        id: 'e2',
        kind: EventKind.repsCompetition,
        priority: EventPriority.secondary,
        date: CivilDate(2027, 6, 12),
        mode: RepsEventMode.forTime,
      );
      expect(reps.validate(), isEmpty);
      expect(_tagged(reps.copyWith(mode: null).validate()), <String>[
        r'$.mode:missing_field',
      ]);
      final full = reps.copyWith(
        stations: const <EventStation>[
          EventStation(exerciseId: 'sw-pompe', reps: 30, restAfterSeconds: 60),
          EventStation(exerciseId: 'sl-traction-lestee', reps: 10),
        ],
        rounds: 2,
        timeLimitSeconds: 900,
        targetSeconds: 480,
        dateApproximate: true,
        plannedBodyWeightKg: 72.5,
        formatKnown: true,
        heats: 2,
        restBetweenHeatsSeconds: 600,
        bestSeconds: 515,
        bestTotalReps: 80,
        bestDate: CivilDate(2026, 6, 14),
      );
      expect(full.validate(), isEmpty);
      expect(SeasonEvent.fromJson(viaJsonText(full.toJson())), full);
      expect(_tagged(full.copyWith(heats: 21).validate()), <String>[
        r'$.heats:above_max',
      ]);
      expect(
        _tagged(full.copyWith(plannedBodyWeightKg: 20.0).validate()),
        <String>[r'$.plannedBodyWeightKg:below_min'],
      );
      expect(
        _tagged(full.copyWith(elements: const <String>['x']).validate()),
        <String>[r'$.elements:unexpected_field'],
      );
      // Des postes sans format : le format manque.
      final other = SeasonEvent(
        id: 'e3',
        kind: EventKind.otherCompetition,
        priority: EventPriority.preparation,
        date: CivilDate(2027, 3, 6),
        stations: const <EventStation>[EventStation(exerciseId: 'sw-pompe')],
      );
      expect(_tagged(other.validate()), <String>[r'$.mode:missing_field']);
      expect(other.copyWith(mode: RepsEventMode.maxReps).validate(), isEmpty);
      // Freestyle : éléments, passages.
      final freestyle = SeasonEvent(
        id: 'e4',
        kind: EventKind.freestyleCompetition,
        priority: EventPriority.main,
        date: CivilDate(2027, 5, 1),
        timeLimitSeconds: 90,
        heats: 3,
        elements: const <String>['cs-front-lever', 'cs-planche'],
        formatKnown: false,
      );
      expect(freestyle.validate(), isEmpty);
      expect(SeasonEvent.fromJson(viaJsonText(freestyle.toJson())), freestyle);
      expect(
        _tagged(freestyle.copyWith(bestTotalReps: 10).validate()),
        <String>[r'$.bestTotalReps:unexpected_field'],
      );
      expect(
        _tagged(freestyle.copyWith(elements: const <String>['']).validate()),
        <String>[r'$.elements[0]:too_short'],
      );
      // Course : distance d'au moins 1 m.
      final race = SeasonEvent(
        id: 'e5',
        kind: EventKind.race,
        priority: EventPriority.main,
        date: CivilDate(2027, 4, 4),
        distanceMeters: 10000,
        targetSeconds: 3000,
        bestSeconds: 3120,
      );
      expect(race.validate(), isEmpty);
      expect(SeasonEvent.fromJson(viaJsonText(race.toJson())), race);
      expect(_tagged(race.copyWith(distanceMeters: 0.5).validate()), <String>[
        r'$.distanceMeters:below_min',
      ]);
      expect(_tagged(race.copyWith(distanceMeters: null).validate()), <String>[
        r'$.distanceMeters:missing_field',
      ]);
      // Objectifs liés : sans doublon, et connus du profil.
      final linked = race.copyWith(goalIds: const <String>['g1', 'g2']);
      expect(linked.validate(), isEmpty);
      expect(
        _tagged(race.copyWith(goalIds: const <String>['g1', 'g1']).validate()),
        <String>[r'$.goalIds:duplicate'],
      );
      final profile = baseProfile().copyWith(events: <SeasonEvent>[linked]);
      expect(profile.validate(), isEmpty);
      expect(
        _tagged(
          baseProfile()
              .copyWith(
                events: <SeasonEvent>[
                  race.copyWith(goalIds: const <String>['g1', 'g9']),
                ],
              )
              .validate(),
        ),
        <String>[r'$.events[0].goalIds:unknown_goal'],
      );
    });

    test('tentatives proposées : jamais décroissantes', () {
      AttemptSuggestion attempt(int index, double loadKg) => AttemptSuggestion(
        index: index,
        loadKg: loadKg,
        successProbability: 0.9,
        reasons: const <Reason>[
          Reason(
            code: ReasonCodes.adaptAttemptOpener,
            params: <String, Object?>{'pct': 0.91},
          ),
        ],
      );
      final ok = LiftAttempts(
        exerciseId: 'sl-traction-lestee',
        estimateKg: 80,
        standardErrorKg: 2,
        attempts: <AttemptSuggestion>[
          attempt(0, 72.5),
          attempt(1, 77.5),
          attempt(2, 80),
        ],
      );
      expect(ok.validate(), isEmpty);
      final same = ok.copyWith(
        attempts: <AttemptSuggestion>[attempt(1, 77.5), attempt(2, 77.5)],
      );
      expect(same.validate(), isEmpty, reason: 'même charge après un échec');
      final lower = ok.copyWith(
        attempts: <AttemptSuggestion>[attempt(0, 77.5), attempt(1, 75)],
      );
      expect(codesOf(lower.validate()), <String>['attempt_decreasing']);
      final order = ok.copyWith(
        attempts: <AttemptSuggestion>[attempt(1, 75), attempt(1, 77.5)],
      );
      expect(codesOf(order.validate()), <String>['index_mismatch']);
      expect(_tagged(lower.validate()), <String>[
        r'$.attempts[1].loadKg:attempt_decreasing',
      ]);
      expect(_tagged(order.validate()), <String>[
        r'$.attempts[1].index:index_mismatch',
      ]);
      // Montée d'échauffement avant l'ouverture.
      final warm = ok.copyWith(
        warmup: const <WarmupStep>[
          WarmupStep(loadKg: 0, reps: 8, restSeconds: 60),
          WarmupStep(loadKg: 30, reps: 5, restSeconds: 120),
          WarmupStep(loadKg: 55, reps: 2, restSeconds: 180),
          WarmupStep(loadKg: 67.5, reps: 1),
        ],
      );
      expect(warm.validate(), isEmpty);
      expect(LiftAttempts.fromJson(viaJsonText(warm.toJson())), warm);
      expect(warm.toJson().keys.last, 'warmup');
      expect(ok.toJson().containsKey('warmup'), isFalse);
      expect(
        _tagged(
          ok
              .copyWith(
                warmup: const <WarmupStep>[WarmupStep(loadKg: 30, reps: 0)],
              )
              .validate(),
        ),
        <String>[r'$.warmup[0].reps:below_min'],
      );
      expect(
        _tagged(
          ok
              .copyWith(
                warmup: const <WarmupStep>[
                  WarmupStep(loadKg: 30, reps: 5, restSeconds: 901),
                ],
              )
              .validate(),
        ),
        <String>[r'$.warmup[0].restSeconds:above_max'],
      );
      expect(
        _tagged(
          ok
              .copyWith(
                warmup: <WarmupStep>[
                  for (var i = 0; i < 13; i++)
                    const WarmupStep(loadKg: 20, reps: 3),
                ],
              )
              .validate(),
        ),
        <String>[r'$.warmup:too_long'],
      );
    });

    test('tentative faite : cause de l\'échec', () {
      const failed = AttemptResult(
        exerciseId: 'sl-traction-lestee',
        index: 1,
        loadKg: 77.5,
        success: false,
        failure: AttemptFailure.technique,
      );
      expect(failed.validate(), isEmpty);
      // La cause d'un échec ne se dit pas pour une tentative réussie.
      expect(_tagged(failed.copyWith(success: true).validate()), <String>[
        r'$.failure:unexpected_field',
      ]);
      expect(failed.toJson()['failure'], 'technique');
      expect(AttemptResult.fromJson(viaJsonText(failed.toJson())), failed);
      expect(AttemptFailure.values, <AttemptFailure>[
        AttemptFailure.strength,
        AttemptFailure.technique,
        AttemptFailure.judging,
      ]);
      expect(failed.copyWith(failure: null).toJson().keys.toList(), <String>[
        'exerciseId',
        'index',
        'loadKg',
        'success',
      ]);
      expect(
        () => AttemptResult.fromJson(<String, Object?>{
          ...viaJsonText(failed.toJson()),
          'failure': 'fatigue',
        }),
        throwsFormatException,
      );
      expect(_tagged(failed.copyWith(index: 4).validate()), <String>[
        r'$.index:above_max',
      ]);
    });

    test('rythme d\'une épreuve : poste, tour, répétitions par série', () {
      const segment = PacingSegment(
        exerciseId: 'sw-pompe',
        setReps: <int>[15, 10, 5],
        restSeconds: 10,
        targetSeconds: 75,
        stationIndex: 2,
        round: 0,
      );
      expect(segment.validate(), isEmpty);
      expect(PacingSegment.fromJson(viaJsonText(segment.toJson())), segment);
      expect(segment.toJson().keys.toList(), <String>[
        'exerciseId',
        'setReps',
        'restSeconds',
        'targetSeconds',
        'stationIndex',
        'round',
      ]);
      expect(
        segment.copyWith(stationIndex: null, round: null).validate(),
        isEmpty,
      );
      expect(segment.copyWith(stationIndex: 39, round: 49).validate(), isEmpty);
      expect(_tagged(segment.copyWith(stationIndex: 40).validate()), <String>[
        r'$.stationIndex:above_max',
      ]);
      expect(_tagged(segment.copyWith(round: 50).validate()), <String>[
        r'$.round:above_max',
      ]);
      expect(_tagged(segment.copyWith(round: -1).validate()), <String>[
        r'$.round:below_min',
      ]);
      expect(
        _tagged(segment.copyWith(setReps: const <int>[10, 0]).validate()),
        <String>[r'$.setReps[1]:below_min'],
      );
      expect(
        _tagged(segment.copyWith(setReps: const <int>[1001]).validate()),
        <String>[r'$.setReps[0]:above_max'],
      );
      const day = EventDayPlan(
        eventId: 'e2',
        lifts: <LiftAttempts>[],
        pacing: <PacingSegment>[segment],
        targetTotalReps: 30,
        targetSeconds: 480,
        confidence: 0.6,
        reasons: <Reason>[],
      );
      expect(day.validate(), isEmpty);
      expect(EventDayPlan.fromJson(viaJsonText(day.toJson())), day);
      expect(
        _tagged(
          day
              .copyWith(
                pacing: <PacingSegment>[
                  segment.copyWith(setReps: const <int>[0]),
                ],
              )
              .validate(),
        ),
        <String>[r'$.pacing[0].setReps[0]:below_min'],
      );
    });

    test('volume toléré : plage ordonnée', () {
      const t = VolumeTolerance(
        muscle: 'dorsaux',
        weeklySetsLow: 10,
        weeklySetsHigh: 16,
        confidence: 0.6,
      );
      expect(t.validate(), isEmpty);
      expect(codesOf(t.copyWith(weeklySetsLow: 18.0).validate()), <String>[
        'range_inverted',
      ]);
    });
  });

  group('interfaces nouvelles', () {
    test('un planificateur de saison et un conseiller du jour J se réalisent '
        'sans toucher aux interfaces de 0.3.0', () {
      final catalog = loadCatalog();
      const SeasonPlanner planner = _FakeSeason();
      const EventDayAdvisor advisor = _FakeEventDay();
      final profile = baseProfile().copyWith(
        events: <SeasonEvent>[
          SeasonEvent(
            id: 'e1',
            kind: EventKind.personalTest,
            priority: EventPriority.main,
            date: CivilDate(2026, 12, 14),
          ),
        ],
      );
      expect(profile.validate(), isEmpty);
      final season = planner.planSeason(
        catalog,
        SeasonRequest(
          profile: profile,
          seed: 0,
          today: CivilDate(2026, 10, 5),
          startDate: CivilDate(2026, 10, 5),
        ),
      );
      expect(season.validate(), isEmpty);
      expect(season.eventIds, <String>['e1']);
      final input = AdaptInput(
        profile: profile,
        block: ProgramBlock(pass1: basePass1(), pass2: basePass2()),
        log: const TrainingLog(sessions: <SessionRecord>[]),
        today: CivilDate(2026, 12, 14),
        season: season,
      );
      final request = EventDayRequest(
        input: input,
        eventId: 'e1',
        bodyWeightKg: 72.4,
        done: const <AttemptResult>[
          AttemptResult(
            exerciseId: 'sl-traction-lestee',
            index: 0,
            loadKg: 72.5,
            success: true,
          ),
        ],
      );
      expect(request.validate(), isEmpty);
      expect(EventDayRequest.fromJson(viaJsonText(request.toJson())), request);
      // Objectif du jour, total visé, cause d'un échec.
      final aimed = request.copyWith(
        objective: EventObjective.secureTotal,
        targetTotalKg: 250.0,
        done: <AttemptResult>[
          ...request.done,
          const AttemptResult(
            exerciseId: 'sl-traction-lestee',
            index: 1,
            loadKg: 77.5,
            success: false,
            failure: AttemptFailure.strength,
          ),
        ],
      );
      expect(aimed.validate(), isEmpty);
      expect(aimed.toJson()['objective'], 'secure_total');
      expect(EventDayRequest.fromJson(viaJsonText(aimed.toJson())), aimed);
      expect(EventObjective.values, <EventObjective>[
        EventObjective.secureTotal,
        EventObjective.maxTotal,
        EventObjective.record,
      ]);
      expect(request.toJson().containsKey('objective'), isFalse);
      expect(request.toJson().containsKey('targetTotalKg'), isFalse);
      expect(
        _tagged(aimed.copyWith(targetTotalKg: 5001.0).validate()),
        <String>[r'$.targetTotalKg:above_max'],
      );
      expect(_tagged(aimed.copyWith(targetTotalKg: -1.0).validate()), <String>[
        r'$.targetTotalKg:below_min',
      ]);
      final day = advisor.planEventDay(catalog, request);
      expect(day.validate(), isEmpty);
      expect(
        day.lifts.single.attempts.first.loadKg,
        greaterThanOrEqualTo(72.5),
      );
      expect(EventDayPlan.fromJson(viaJsonText(day.toJson())), day);
      expect(day.lifts.single.warmup, hasLength(2));
      final next = advisor.planEventDay(catalog, aimed);
      expect(next.validate(), isEmpty);
      expect(next.lifts.single.attempts.single.index, 2);
    });
  });

  group('codes de raison 0.4.0', () {
    test('130 codes, les 92 premiers inchangés en tête', () {
      expect(reasonRegistry, hasLength(130));
      expect(reasonRegistry[91].code, 'quest.start_bonus');
      expect(reasonRegistry[92].code, 'plan.season_phase');
      expect(reasonRegistry.last.code, 'adapt.mini_set_stop');
      expect(reasonRegistry.first.code, 'plan.discipline_share');
      // 38 codes nouveaux, tous après les 92 de 0.3.0, sans doublon.
      final added = <String>[for (final s in reasonRegistry.skip(92)) s.code];
      expect(added, hasLength(38));
      expect(added.toSet(), hasLength(38));
      expect(
        added.where((c) => c.startsWith('quest.')),
        isEmpty,
        reason: 'aucun code de progression ajouté',
      );
      final before = <String>{for (final s in reasonRegistry.take(92)) s.code};
      expect(before, hasLength(92));
      expect(before.intersection(added.toSet()), isEmpty);
      // Plateau de figure et charge récente : juste après l'étape de figure.
      expect(reasonRegistry[100].code, ReasonCodes.planSkillStep);
      expect(reasonRegistry[101].code, ReasonCodes.planSkillPlateau);
      expect(reasonRegistry[102].code, ReasonCodes.planRecentLoad);
      expect(ReasonCodes.planSkillPlateau, 'plan.skill_plateau');
      expect(ReasonCodes.planRecentLoad, 'plan.recent_load');
    });

    test('plateau de figure, charge récente : paramètres', () {
      expect(
        reasonSpecOf(ReasonCodes.planSkillPlateau)!.params,
        <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId},
      );
      expect(
        reasonSpecOf(ReasonCodes.planRecentLoad)!.params,
        <String, ReasonParamType>{
          'exerciseId': ReasonParamType.exerciseId,
          'sessions': ReasonParamType.integer,
        },
      );
      const plateau = Reason(
        code: ReasonCodes.planSkillPlateau,
        params: <String, Object?>{'exerciseId': 'cs-front-lever-tuck-avance'},
      );
      expect(plateau.validate(), isEmpty);
      expect(Reason.fromJson(viaJsonText(plateau.toJson())), plateau);
      const load = Reason(
        code: ReasonCodes.planRecentLoad,
        params: <String, Object?>{
          'exerciseId': 'sl-traction-lestee',
          'sessions': 2,
        },
      );
      expect(load.validate(), isEmpty);
      expect(Reason.fromJson(viaJsonText(load.toJson())), load);
      final ids = <String>{};
      plateau.collectExerciseIds(ids);
      load.collectExerciseIds(ids);
      expect(ids, <String>{'cs-front-lever-tuck-avance', 'sl-traction-lestee'});
      expect(
        codesOf(
          const Reason(
            code: ReasonCodes.planSkillPlateau,
            params: <String, Object?>{},
          ).validate(),
        ),
        <String>['missing_param'],
      );
      expect(
        codesOf(
          const Reason(
            code: ReasonCodes.planRecentLoad,
            params: <String, Object?>{'exerciseId': 'sl-traction-lestee'},
          ).validate(),
        ),
        <String>['missing_param'],
      );
      expect(
        codesOf(
          const Reason(
            code: ReasonCodes.planRecentLoad,
            params: <String, Object?>{
              'exerciseId': 'sl-traction-lestee',
              'sessions': 2.5,
            },
          ).validate(),
        ),
        <String>['param_type'],
      );
      expect(
        codesOf(
          const Reason(
            code: ReasonCodes.planSkillPlateau,
            params: <String, Object?>{
              'exerciseId': 'cs-front-lever',
              'stepIndex': 1,
            },
          ).validate(),
        ),
        <String>['unknown_param'],
      );
    });

    test('les nouvelles raisons se valident', () {
      const taper = Reason(
        code: ReasonCodes.planTaper,
        params: <String, Object?>{'volumeFactor': 0.5, 'daysToEvent': 10},
      );
      expect(taper.validate(), isEmpty);
      const withheld = Reason(
        code: ReasonCodes.planTechniqueWithheld,
        params: <String, Object?>{
          'technique': 'rest_pause',
          'cause': 'training_age',
        },
      );
      expect(withheld.validate(), isEmpty);
      const none = Reason(
        code: ReasonCodes.adaptTaperNoVolume,
        params: <String, Object?>{},
      );
      expect(none.validate(), isEmpty);
      const result = Reason(
        code: ReasonCodes.adaptTestResult,
        params: <String, Object?>{
          'exerciseId': 'sl-dips-leste',
          'value': 105.0,
          'standardError': 4.2,
        },
      );
      expect(result.validate(), isEmpty);
      final ids = <String>{};
      result.collectExerciseIds(ids);
      expect(ids, <String>{'sl-dips-leste'});
    });
  });
}

final class _FakeSeason implements SeasonPlanner {
  const _FakeSeason();

  @override
  String get engineVersion => '0.0.0-test';

  @override
  SeasonPlan planSeason(Catalog catalog, SeasonRequest request) {
    final events = request.profile.events ?? const <SeasonEvent>[];
    return SeasonPlan(
      createdOn: request.today,
      engineVersion: engineVersion,
      eventIds: <String>[for (final e in events) e.id],
      phases: <SeasonPhase>[
        SeasonPhase(
          index: 0,
          kind: SeasonPhaseKind.accumulation,
          startDate: request.startDate,
          weeks: 8,
          eventId: events.isEmpty ? null : events.first.id,
          volumeFactor: 1,
          reasons: const <Reason>[],
        ),
        SeasonPhase(
          index: 1,
          kind: SeasonPhaseKind.taper,
          startDate: request.startDate.addDays(56),
          weeks: 2,
          volumeFactor: 0.5,
          intensityFactor: 1,
          reasons: const <Reason>[],
        ),
      ],
      reasons: const <Reason>[],
    );
  }
}

final class _FakeEventDay implements EventDayAdvisor {
  const _FakeEventDay();

  @override
  String get engineVersion => '0.0.0-test';

  @override
  EventDayPlan planEventDay(Catalog catalog, EventDayRequest request) {
    final last = request.done.isEmpty ? null : request.done.last;
    return EventDayPlan(
      eventId: request.eventId,
      lifts: <LiftAttempts>[
        if (last != null)
          LiftAttempts(
            exerciseId: last.exerciseId,
            warmup: const <WarmupStep>[
              WarmupStep(loadKg: 40, reps: 3, restSeconds: 120),
              WarmupStep(loadKg: 60, reps: 1),
            ],
            attempts: <AttemptSuggestion>[
              AttemptSuggestion(
                index: last.index + 1,
                loadKg: last.loadKg + 2.5,
                reasons: const <Reason>[],
              ),
            ],
          ),
      ],
      confidence: 0.5,
      reasons: const <Reason>[],
    );
  }
}
