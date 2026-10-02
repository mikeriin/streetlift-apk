// Prescriptions avancées, saison, compétition, figures (0.4.0) : types à
// variantes, invariants croisés, journal, interfaces nouvelles.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

void main() {
  group('types à variantes', () {
    final fixture = readJsonObject('test/fixtures/variants.json');
    final types = (fixture['types']! as List<Object?>)
        .cast<Map<String, Object?>>();
    final codecs = <String, ContractCodec<Object>>{
      for (final c in contractCodecs) c.name: c,
    };

    test('six types à variantes', () {
      expect(types.map((t) => t['type']), <String>[
        'Benchmark',
        'SeasonEvent',
        'Specialization',
        'SetTechnique',
        'IntensityTarget',
        'AutoregulationRule',
      ]);
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
          // Un paramètre obligatoire absent est signalé.
          for (final n in required) {
            final missing = <String, Object?>{...minimal}..remove(n);
            expect(
              codes(missing),
              contains('missing_field'),
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
      expect(SetTechniqueKind.values, hasLength(16));
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
      const myo = SetTechnique(
        kind: SetTechniqueKind.myoReps,
        miniSetReps: 4,
        intraRestSeconds: 15,
        miniSets: 5,
        activationRepsLow: 12,
        activationRepsHigh: 15,
      );
      expect(myo.validate(), isEmpty);
      expect(codesOf(myo.copyWith(activationRepsLow: 20).validate()), <String>[
        'range_inverted',
      ]);
      expect(
        codesOf(myo.copyWith(activationRepsHigh: null).validate()),
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
      const pyramid = SetTechnique(
        kind: SetTechniqueKind.pyramid,
        pyramidReps: <int>[10, 8, 6, 4, 2],
      );
      expect(pyramid.validate(), isEmpty);
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

    test('intensité et autorégulation : plages', () {
      const hold = IntensityTarget(
        basis: IntensityBasis.holdFraction,
        value: 0.6,
        valueHigh: 0.7,
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
      const step = IntensityTarget(
        basis: IntensityBasis.progressionStep,
        stepExerciseId: 'cs-front-lever-tuck-avance',
      );
      expect(step.validate(), isEmpty);
      final ids = <String>{};
      step.collectExerciseIds(ids);
      expect(ids, <String>{'cs-front-lever-tuck-avance'});
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

    test('journal : mini-séries, tentatives, qualité', () {
      final mini = baseSet.copyWith(
        technique: SetTechniqueKind.cluster,
        role: SetRole.mini,
        miniSetIndex: 2,
        restBeforeSeconds: 20,
        quality: 4,
      );
      expect(mini.validate(), isEmpty);
      expect(SetRecord.fromJson(viaJsonText(mini.toJson())), mini);
      expect(codesOf(mini.copyWith(quality: 6).validate()), <String>[
        'above_max',
      ]);
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
  });

  group('saison, compétition, figures', () {
    SeasonPhase phase(int index, PhaseKind kind, String start, int weeks) =>
        SeasonPhase(
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
        phase(0, PhaseKind.accumulation, '2026-10-05', 6),
        phase(1, PhaseKind.intensification, '2026-11-16', 5),
        phase(2, PhaseKind.realization, '2026-12-21', 3),
        phase(3, PhaseKind.taper, '2027-01-11', 2),
        phase(4, PhaseKind.competition, '2027-01-25', 1),
        phase(5, PhaseKind.transition, '2027-02-01', 1),
      ]);
      expect(ok.validate(), isEmpty);
      expect(SeasonPlan.fromJson(viaJsonText(ok.toJson())), ok);
      final gap = plan(<SeasonPhase>[
        phase(0, PhaseKind.accumulation, '2026-10-05', 6),
        phase(1, PhaseKind.taper, '2026-11-23', 2),
      ]);
      expect(codesOf(gap.validate()), <String>['phases_not_contiguous']);
      final overlap = plan(<SeasonPhase>[
        phase(0, PhaseKind.accumulation, '2026-10-05', 6),
        phase(1, PhaseKind.taper, '2026-11-09', 2),
      ]);
      expect(codesOf(overlap.validate()), <String>['phases_not_contiguous']);
      final rank = plan(<SeasonPhase>[
        phase(1, PhaseKind.accumulation, '2026-10-05', 6),
      ]);
      expect(codesOf(rank.validate()), <String>['index_mismatch']);
      expect(codesOf(plan(const <SeasonPhase>[]).validate()), <String>[
        'too_short',
      ]);
    });

    test('le plan de saison voyage dans les requêtes sans les casser', () {
      final season = plan(<SeasonPhase>[
        phase(0, PhaseKind.accumulation, '2026-10-05', 6),
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
          phase: PhaseKind.intensification,
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
      final day = advisor.planEventDay(catalog, request);
      expect(day.validate(), isEmpty);
      expect(
        day.lifts.single.attempts.first.loadKg,
        greaterThanOrEqualTo(72.5),
      );
      expect(EventDayPlan.fromJson(viaJsonText(day.toJson())), day);
    });
  });

  group('codes de raison 0.4.0', () {
    test('128 codes, les 92 premiers inchangés en tête', () {
      expect(reasonRegistry, hasLength(128));
      expect(reasonRegistry[91].code, 'quest.start_bonus');
      expect(reasonRegistry[92].code, 'plan.season_phase');
      expect(reasonRegistry.last.code, 'adapt.mini_set_stop');
      expect(reasonRegistry.first.code, 'plan.discipline_share');
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
          kind: PhaseKind.accumulation,
          startDate: request.startDate,
          weeks: 8,
          eventId: events.isEmpty ? null : events.first.id,
          volumeFactor: 1,
          reasons: const <Reason>[],
        ),
        SeasonPhase(
          index: 1,
          kind: PhaseKind.taper,
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
