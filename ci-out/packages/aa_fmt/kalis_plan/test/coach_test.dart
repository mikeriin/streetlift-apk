// Tests ciblés du chemin street (kalis_plan 0.2, CONTRAT.md § 12) : choix
// du chemin, saison calée sur l'échéance, méthodes par niveau, zones à
// ménager, revue, textes des notes de coach, budgets de calcul.
import 'dart:convert';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

final CivilDate _start = CivilDate(2026, 10, 5);

const List<String> _park = <String>[
  'barre fixe',
  'barres parallèles',
  'barre basse',
  'élastique',
];

const List<String> _gym = <String>[
  ..._park,
  'ceinture de lest',
  'disques',
  'barre olympique',
  'cage / rack',
  'banc plat',
  'haltères',
  'poulie',
  'anneaux',
  'tapis',
];

Benchmark _oneRm(String id, double kg) => Benchmark(
  exerciseId: id,
  kind: BenchmarkKind.loadReps,
  source: BenchmarkSource.declared,
  externalLoadKg: kg,
  reps: 1,
  rir: 0,
);

Benchmark _maxReps(String id, int reps) => Benchmark(
  exerciseId: id,
  kind: BenchmarkKind.maxReps,
  source: BenchmarkSource.declared,
  reps: reps,
);

AthleteProfile _profile({
  required ExperienceLevel experience,
  TrainingDiscipline primary = TrainingDiscipline.streetWorkout,
  List<int> weekdays = const <int>[1, 3, 5],
  int minutes = 60,
  List<String> equipment = _park,
  List<Benchmark> benchmarks = const <Benchmark>[],
  List<MovementLevel> levels = const <MovementLevel>[],
  List<SeasonEvent>? events,
  List<Limitation> limitations = const <Limitation>[],
  List<SkillState>? skills,
  TrainingGap? gap,
  TrainingAge? trainingAge = TrainingAge.years2To5,
  int schemaVersion = 3,
}) => AthleteProfile(
  schemaVersion: schemaVersion,
  sex: Sex.male,
  birthYear: 1996,
  heightCm: 178,
  bodyWeightKg: 78,
  disciplines: DisciplineMix(
    primary: primary,
    primaryPct: 100,
    secondaries: const <DisciplineShare>[],
  ),
  movementLevels: levels,
  goals: const <Goal>[],
  availability: <DaySlot>[
    for (final w in weekdays) DaySlot(weekday: w, minutes: minutes),
  ],
  places: const <Place>[Place.gym, Place.outdoor],
  equipment: equipment,
  loadIncrements: const <LoadIncrement>[],
  limitations: limitations,
  likedExerciseIds: const <String>[],
  dislikedExerciseIds: const <String>[],
  experience: experience,
  guidanceMode: GuidanceMode.assisted,
  healthScreening: HealthScreeningRef(
    questionnaireId: 'l13-v1',
    answeredOn: _start,
    outcome: HealthScreeningOutcome.standard,
  ),
  createdOn: _start,
  updatedOn: _start,
  trainingAge: schemaVersion >= 3 ? trainingAge : null,
  trainingGap: gap,
  benchmarks: benchmarks.isEmpty ? null : benchmarks,
  events: events,
  skills: skills,
);

PlanRequest _request(AthleteProfile profile, {CivilDate? start}) => PlanRequest(
  profile: profile,
  seed: 0,
  startDate: start ?? _start,
  locks: const <PlanLock>[],
);

/// Blocs enchaînés jusqu'à couvrir [weeks] semaines.
List<ProgramBlock> _program(
  Catalog catalog,
  AthleteProfile profile,
  int weeks,
) {
  final engine = KalisPlan();
  final request = _request(profile);
  final pass1 = engine.createPass1(catalog, request);
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  final blocks = <ProgramBlock>[ProgramBlock(pass1: pass1, pass2: pass2)];
  var done = pass1.weeks;
  while (done < weeks) {
    final previous = blocks.last;
    final next = engine.nextBlock(
      catalog,
      NextBlockRequest(
        profile: profile,
        seed: 0,
        startDate: _start.addDays(7 * done),
        previous: previous,
        adaptation: AdaptationSummary(
          asOf: _start.addDays(7 * done - 1),
          weeksObserved: previous.pass1.weeks,
          sessionsPlanned: previous.pass1.weeks * previous.pass1.days.length,
          sessionsCompleted: previous.pass1.weeks * previous.pass1.days.length,
          unlockLevel: UnlockLevel.loadsReps,
          confidence: 0,
          estimates: const <ExerciseEstimate>[],
          pains: const <PainTrend>[],
          avoidedExerciseIds: const <String>[],
          reasons: const <Reason>[],
        ),
        locks: const <PlanLock>[],
      ),
    );
    blocks.add(next.block);
    done += next.block.pass1.weeks;
  }
  return blocks;
}

/// Blocs enchaînés jusqu'à couvrir [weeks] semaines, le résumé d'adaptation
/// du bloc d'indice `n` portant les raisons `reasonsFor(n)` et les repères
/// du profil pouvant changer d'un bloc à l'autre (`profileFor(n)`).
List<ProgramBlock> _programWith(
  Catalog catalog,
  AthleteProfile profile,
  int weeks, {
  List<Reason> Function(int block)? reasonsFor,
  AthleteProfile Function(int block)? profileFor,
}) {
  final engine = KalisPlan();
  final request = _request(profile);
  final pass1 = engine.createPass1(catalog, request);
  final pass2 = engine.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  final blocks = <ProgramBlock>[ProgramBlock(pass1: pass1, pass2: pass2)];
  var done = pass1.weeks;
  while (done < weeks) {
    final previous = blocks.last;
    final n = blocks.length;
    final next = engine.nextBlock(
      catalog,
      NextBlockRequest(
        profile: profileFor == null ? profile : profileFor(n),
        seed: 0,
        startDate: _start.addDays(7 * done),
        previous: previous,
        adaptation: AdaptationSummary(
          asOf: _start.addDays(7 * done - 1),
          weeksObserved: previous.pass1.weeks,
          sessionsPlanned: previous.pass1.weeks * previous.pass1.days.length,
          sessionsCompleted: previous.pass1.weeks * previous.pass1.days.length,
          unlockLevel: UnlockLevel.loadsReps,
          confidence: 0,
          estimates: const <ExerciseEstimate>[],
          pains: const <PainTrend>[],
          avoidedExerciseIds: const <String>[],
          reasons: reasonsFor == null ? const <Reason>[] : reasonsFor(n),
        ),
        locks: const <PlanLock>[],
      ),
    );
    blocks.add(next.block);
    done += next.block.pass1.weeks;
  }
  return blocks;
}

AthleteProfile _lifter({int weeksOut = 12}) => _profile(
  experience: ExperienceLevel.advanced,
  primary: TrainingDiscipline.streetlifting,
  weekdays: const <int>[1, 2, 4, 6],
  minutes: 90,
  equipment: _gym,
  benchmarks: <Benchmark>[
    _oneRm('sl-traction-lestee', 60),
    _oneRm('sl-dips-leste', 90),
    _oneRm('sl-squat-competition', 160),
    _maxReps('sw-traction-pronation', 24),
    _maxReps('sw-dips-barres-paralleles', 40),
  ],
  events: <SeasonEvent>[
    SeasonEvent(
      id: 'e1',
      kind: EventKind.strengthCompetition,
      priority: EventPriority.main,
      date: _start.addDays(7 * weeksOut - 2),
      lifts: const <CompetitionLift>[
        CompetitionLift(exerciseId: 'sl-traction-lestee', attempts: 3),
        CompetitionLift(exerciseId: 'sl-dips-leste', attempts: 3),
        CompetitionLift(exerciseId: 'sl-squat-competition', attempts: 3),
      ],
    ),
  ],
);

AthleteProfile _beginner() => _profile(
  experience: ExperienceLevel.beginner,
  trainingAge: TrainingAge.under6Months,
  minutes: 45,
  benchmarks: <Benchmark>[_maxReps('sw-pompe', 6)],
  levels: const <MovementLevel>[
    MovementLevel(
      exerciseId: 'sw-traction-pronation',
      measure: LevelMeasure.maxReps,
      known: true,
      low: 0,
      high: 0,
    ),
  ],
);

void main() {
  final catalog = loadCatalog();

  group('choix du chemin', () {
    test('profil street au schéma 3 rempli : chemin street', () {
      final profile = _beginner();
      expect(coachEligible(profile), isTrue);
      final plan = KalisPlan().createPass1(catalog, _request(profile));
      expect(isCoachPlan(plan), isTrue);
      expect(plan.intent, isNotNull);
    });

    test('schéma 2, ancienneté absente ou discipline non street : 0.1', () {
      final v2 = _profile(
        experience: ExperienceLevel.intermediate,
        schemaVersion: 2,
      );
      expect(v2.validate(), isEmpty);
      expect(coachEligible(v2), isFalse);
      expect(
        isCoachPlan(KalisPlan().createPass1(catalog, _request(v2))),
        isFalse,
      );
      final noAge = _profile(
        experience: ExperienceLevel.intermediate,
        trainingAge: null,
      );
      expect(coachEligible(noAge), isFalse);
      final gym = _profile(
        experience: ExperienceLevel.intermediate,
        primary: TrainingDiscipline.musculation,
        equipment: _gym,
      );
      expect(coachEligible(gym), isFalse);
      expect(
        isCoachPlan(KalisPlan().createPass1(catalog, _request(gym))),
        isFalse,
      );
    });

    test('les profils aléatoires de 0.1 ne prennent pas le chemin street', () {
      for (var seed = 0; seed < 300; seed++) {
        expect(coachEligible(randomProfile(catalog, seed)), isFalse);
      }
    });
  });

  group('saison et échéance', () {
    final profile = _lifter();
    final blocks = _program(catalog, profile, 12);
    final weeks = <WeekPrescription>[for (final b in blocks) ...b.pass2.weeks];

    test('les blocs finissent sur l\'échéance', () {
      expect(weeks.length, 12);
      expect(weeks.last.intent, WeekIntent.competition);
      expect(weeks[10].intent, WeekIntent.taper);
      for (final b in blocks) {
        expect(b.validate(), isEmpty);
        expect(b.pass1.weeks, inInclusiveRange(4, 6));
      }
      // Un allègement toutes les cinq semaines de charge au plus.
      var run = 0;
      for (final w in weeks) {
        final relief =
            w.intent == WeekIntent.deload ||
            w.intent == WeekIntent.taper ||
            w.intent == WeekIntent.competition;
        run = relief ? 0 : run + 1;
        expect(run, lessThanOrEqualTo(5));
      }
    });

    test('épreuve la semaine de l\'échéance, volume en baisse', () {
      final tests = <String>{
        for (final d in weeks.last.days)
          for (final i in d.items)
            if (i.kind == SetKind.test) i.exerciseId,
      };
      expect(
        tests,
        containsAll(<String>[
          'sl-traction-lestee',
          'sl-dips-leste',
          'sl-squat-competition',
        ]),
      );
      final hard = hardSetsByWeek(catalog, weeks);
      var peak = 0.0;
      for (var k = 5; k < 11; k++) {
        if (hard[k] > peak) {
          peak = hard[k];
        }
      }
      expect(hard.last, lessThanOrEqualTo(peak * 0.6));
      expect(hard.last, greaterThanOrEqualTo(peak * 0.25));
    });

    test('la série de tête monte de l\'accumulation à la réalisation', () {
      final top = <double>[];
      for (final w in weeks) {
        var best = 0.0;
        for (final d in w.days) {
          for (final i in d.items) {
            final pct = i.percentOfOneRm;
            if (i.exerciseId == 'sl-traction-lestee' &&
                i.kind != SetKind.test &&
                pct != null &&
                pct > best) {
              best = pct;
            }
          }
        }
        top.add(best);
      }
      expect(top.first, lessThan(0.85));
      expect(top.reduce((a, b) => a > b ? a : b), inInclusiveRange(0.9, 0.95));
      // Une exposition lourde (85 % et plus) par semaine de réalisation.
      for (var k = 0; k < weeks.length; k++) {
        if (weeks[k].intent == WeekIntent.realization) {
          expect(top[k], greaterThanOrEqualTo(0.85));
        }
      }
    });

    test('le plan de saison couvre les mêmes semaines', () {
      final season = KalisPlan().planSeason(
        catalog,
        SeasonRequest(
          profile: profile,
          seed: 0,
          today: _start,
          startDate: _start,
        ),
      );
      expect(season.validate(), isEmpty);
      expect(season.eventIds, <String>['e1']);
      var total = 0;
      for (final p in season.phases) {
        total += p.weeks;
      }
      expect(total, 12);
      expect(season.phases.last.kind, SeasonPhaseKind.competition);
    });

    test('relecture : aucun manquement', () {
      expect(coachAudit(catalog, profile, _start, blocks), isEmpty);
    });
  });

  group('débutant', () {
    final profile = _beginner();
    final blocks = _program(catalog, profile, 12);

    test('ni technique, ni échec, ni exercice hors de portée', () {
      for (final b in blocks) {
        for (final w in b.pass2.weeks) {
          for (final d in w.days) {
            for (final i in d.items) {
              final technique = i.technique?.kind;
              expect(
                technique == null ||
                    technique == SetTechniqueKind.isometricHold ||
                    technique == SetTechniqueKind.skillPractice,
                isTrue,
                reason: '${i.exerciseId} ${technique?.code}',
              );
              final flames = i.targetFlames;
              if (flames != null && i.kind == SetKind.work) {
                expect(Flames.toRir(flames), greaterThanOrEqualTo(2));
              }
              expect(i.exerciseId, isNot('sw-traction-pronation'));
            }
          }
        }
      }
      expect(coachAudit(catalog, profile, _start, blocks), isEmpty);
    });

    test('un chemin vers la traction à chaque séance', () {
      const steps = <String>{
        'sw-traction-assistee-elastique',
        'sw-traction-assistee-pieds-au-sol',
        'sw-traction-negative',
      };
      for (final d in blocks.first.pass1.days) {
        expect(d.slots.any((s) => steps.contains(s.exerciseId)), isTrue);
      }
    });
  });

  group('zones à ménager et reprise', () {
    test('coude récent : pas de traction lestée, 2 en réserve au moins', () {
      final profile = _lifter().copyWith(
        events: null,
        limitations: const <Limitation>[
          Limitation(
            zone: BodyZone.elbow,
            side: BodySide.right,
            discomfort: 3,
            since: ConstraintSince.months3To12,
          ),
        ],
      );
      final blocks = _program(catalog, profile, 5);
      for (final w in blocks.first.pass2.weeks) {
        for (final d in w.days) {
          for (final i in d.items) {
            expect(i.exerciseId, isNot('sl-traction-lestee'));
            final flames = i.targetFlames;
            final e = catalog.exercise(i.exerciseId);
            if (flames != null &&
                i.kind == SetKind.work &&
                e.stressOn(Joint.elbow) != JointStress.low) {
              expect(Flames.toRir(flames), greaterThanOrEqualTo(2));
            }
          }
        }
      }
      expect(
        blocks.first.pass2.reasons.any(
          (r) => r.code == ReasonCodes.planPainRule,
        ),
        isTrue,
      );
    });

    test('reprise après une longue coupure : semaine 1 facile', () {
      final profile = _profile(
        experience: ExperienceLevel.intermediate,
        gap: TrainingGap.months6To24,
        benchmarks: <Benchmark>[
          _maxReps('sw-traction-pronation', 12),
          _maxReps('sw-dips-barres-paralleles', 20),
          _maxReps('sw-pompe', 35),
        ],
      );
      final blocks = _program(catalog, profile, 5);
      final weeks = blocks.first.pass2.weeks;
      for (var w = 0; w < 2; w++) {
        for (final d in weeks[w].days) {
          for (final i in d.items) {
            final flames = i.targetFlames;
            if (flames != null && i.kind == SetKind.work) {
              expect(Flames.toRir(flames), greaterThanOrEqualTo(3));
            }
          }
        }
      }
      final hard = hardSetsByWeek(catalog, weeks);
      expect(hard.first, lessThanOrEqualTo(hard[3]));
      expect(coachAudit(catalog, profile, _start, blocks), isEmpty);
    });
  });

  group('revue et passe 2', () {
    test('un remplacement est gardé par la passe 2', () {
      final profile = _lifter();
      final engine = KalisPlan();
      final request = _request(profile);
      final p1 = engine.createPass1(catalog, request);
      final slot = p1.days.first.slots.firstWhere(
        (s) => s.role == SlotRole.accessory,
      );
      final variants = engine.variants(
        catalog,
        VariantsRequest(request: request, current: p1, slotId: slot.slotId),
      );
      expect(variants.all, isNotEmpty);
      final other = variants.all.first.exerciseId;
      final result = engine.review(
        catalog,
        ReviewRequest(
          request: request,
          current: p1,
          action: ReviewAction(
            kind: ReviewKind.replace,
            slotId: slot.slotId,
            replacementExerciseId: other,
          ),
        ),
      );
      final next = request.copyWith(locks: result.locks);
      final p2 = engine.createPass2(
        catalog,
        Pass2Request(request: next, pass1: result.plan),
      );
      expect(
        p2.weeks[1].days.first.items.any(
          (i) => i.slotId == slot.slotId && i.exerciseId == other,
        ),
        isTrue,
      );
      // Une seule ligne du diff : le remplacement.
      expect(result.diff.changes.length, 1);
      expect(result.diff.changes.single.kind, ChangeKind.exerciseReplaced);
    });
  });

  group('textes et raisons', () {
    test('chaque note et chaque règle a son texte français', () {
      for (final note in CoachNotes.all) {
        final text = coachReasonText(
          Reason(
            code: ReasonCodes.planCoachNote,
            params: <String, Object?>{'note': note, 'value': 3.0},
          ),
          catalog,
        );
        expect(text, isNotNull, reason: note);
        expect(text, isNot(contains('null')), reason: note);
      }
      for (final rule in CoachRules.all) {
        final text = coachReasonText(
          Reason(
            code: ReasonCodes.planProgressionRule,
            params: <String, Object?>{
              'rule': rule,
              'step': 1.0,
              'unit': 'reps',
            },
          ),
          catalog,
        );
        expect(text, isNotNull, reason: rule);
      }
    });

    test('toutes les raisons rendues sont au registre', () {
      for (final profile in <AthleteProfile>[_lifter(), _beginner()]) {
        for (final b in _program(catalog, profile, 12)) {
          expect(b.pass1.validate(), isEmpty);
          expect(b.pass2.validate(), isEmpty);
          for (final r in <Reason>[
            ...b.pass1.reasons,
            ...b.pass2.reasons,
            for (final w in b.pass2.weeks)
              for (final d in w.days)
                for (final i in d.items) ...i.reasons,
          ]) {
            expect(r.validate(), isEmpty, reason: r.code);
          }
        }
      }
    });
  });

  group('déterminisme et budgets', () {
    test('même requête, même JSON', () {
      final profile = _lifter();
      final a = _program(catalog, profile, 12);
      final b = _program(catalog, profile, 12);
      expect(
        jsonEncode(<Object?>[for (final x in a) x.toJson()]),
        jsonEncode(<Object?>[for (final x in b) x.toJson()]),
      );
    });

    test('création en moins d\'une seconde, régénération en 300 ms', () {
      final engine = KalisPlan();
      // Mise en route (traits du catalogue, premier appel).
      engine.createPass1(catalog, randomCoachRequest(catalog, 0));
      for (var seed = 1; seed <= 40; seed++) {
        final request = randomCoachRequest(catalog, seed);
        final watch = Stopwatch()..start();
        final p1 = engine.createPass1(catalog, request);
        final p2 = engine.createPass2(
          catalog,
          Pass2Request(request: request, pass1: p1),
        );
        final create = watch.elapsedMilliseconds;
        watch
          ..reset()
          ..start();
        engine.createPass2(catalog, Pass2Request(request: request, pass1: p1));
        final again = watch.elapsedMilliseconds;
        expect(p2.weeks, isNotEmpty);
        expect(create, lessThan(1000), reason: 'profil $seed');
        expect(again, lessThan(300), reason: 'profil $seed');
      }
    });
  });

  group('CP1 — invariants de calibrage', () {
    // Semaines d'allègement ou d'échéance ; les autres sont des semaines
    // de charge.
    const relief = <WeekIntent>{
      WeekIntent.deload,
      WeekIntent.taper,
      WeekIntent.competition,
      WeekIntent.test,
      WeekIntent.transition,
    };
    bool loadWeek(WeekPrescription w) {
      final intent = w.intent;
      return intent != null && !relief.contains(intent);
    }

    List<WeekPrescription> weeksOf(List<ProgramBlock> blocks) {
      return <WeekPrescription>[for (final b in blocks) ...b.pass2.weeks];
    }

    final lifterBlocks = _program(catalog, _lifter(), 12);
    final beginnerBlocks = _program(catalog, _beginner(), 12);

    test('débutant : aucune série de travail sous 2 en réserve', () {
      for (final w in weeksOf(beginnerBlocks)) {
        for (final d in w.days) {
          for (final i in d.items) {
            if (i.kind != null && i.kind != SetKind.work) {
              continue;
            }
            final where = 's${w.weekIndex} j${d.dayIndex} ${i.exerciseId}';
            final flames = i.targetFlames;
            if (flames != null) {
              expect(
                Flames.toRir(flames),
                greaterThanOrEqualTo(2),
                reason: '$where : $flames flammes',
              );
            }
            final intensity = i.intensity;
            if (intensity != null && intensity.basis == IntensityBasis.rir) {
              expect(
                intensity.value,
                greaterThanOrEqualTo(2),
                reason: '$where : RIR visé ${intensity.value}',
              );
            }
          }
        }
      }
    });

    test('descentes freinées : 15 excentriques au plus, descente de 3 s', () {
      const negatives = <String>{'sw-traction-negative', 'sw-pompe-negative'};
      var seen = 0;
      for (final w in weeksOf(beginnerBlocks)) {
        for (final d in w.days) {
          final eccentrics = <String, int>{};
          for (final i in d.items) {
            // Le test de descente est chronométré (secondes, sans tempo).
            if (!negatives.contains(i.exerciseId) || i.kind == SetKind.test) {
              continue;
            }
            seen++;
            final where = 's${w.weekIndex} j${d.dayIndex} ${i.exerciseId}';
            final reps = i.repsHigh;
            expect(reps, isNotNull, reason: '$where : répétitions absentes');
            eccentrics[i.exerciseId] =
                (eccentrics[i.exerciseId] ?? 0) + i.sets * (reps ?? 0);
            final tempo = i.tempo;
            expect(tempo, isNotNull, reason: '$where : tempo absent');
            expect(
              tempo?.eccentricSeconds ?? 0,
              greaterThanOrEqualTo(3),
              reason: '$where : descente de ${tempo?.eccentricSeconds} s',
            );
          }
          for (final e in eccentrics.entries) {
            expect(
              e.value,
              lessThanOrEqualTo(15),
              reason:
                  's${w.weekIndex} j${d.dayIndex} ${e.key} : '
                  '${e.value} excentriques dans la séance',
            );
          }
        }
      }
      expect(seen, greaterThan(0), reason: 'aucune descente freinée prescrite');
    });

    test('affûtage et échéance : moins de séries dures qu\'au pic', () {
      final weeks = weeksOf(lifterBlocks);
      final hard = hardSetsByWeek(catalog, weeks);
      var overall = 0.0;
      for (var k = 0; k < weeks.length; k++) {
        if (loadWeek(weeks[k]) && hard[k] > overall) {
          overall = hard[k];
        }
      }
      var checked = 0;
      var offset = 0;
      for (final b in lifterBlocks) {
        final end = offset + b.pass2.weeks.length;
        var peak = 0.0;
        for (var k = offset; k < end; k++) {
          if (loadWeek(weeks[k]) && hard[k] > peak) {
            peak = hard[k];
          }
        }
        // Bloc sans semaine de charge : le pic de tout le programme.
        if (peak == 0) {
          peak = overall;
        }
        for (var k = offset; k < end; k++) {
          final intent = weeks[k].intent;
          if (intent == WeekIntent.taper || intent == WeekIntent.competition) {
            checked++;
            expect(
              hard[k],
              lessThan(peak),
              reason:
                  'semaine $k (${weeks[k].intent?.code}) : ${hard[k]} '
                  'séries dures, '
                  'pic de charge du bloc $peak',
            );
          }
        }
        offset = end;
      }
      expect(checked, greaterThan(0), reason: 'aucune semaine d\'affûtage');
    });

    test('reprise après plus de 10 semaines : montée de 50 % à 100 %', () {
      for (final gap in <TrainingGap>[
        TrainingGap.weeks10To26,
        TrainingGap.months6To24,
      ]) {
        final profile = _profile(
          experience: ExperienceLevel.intermediate,
          gap: gap,
          benchmarks: <Benchmark>[
            _maxReps('sw-traction-pronation', 12),
            _maxReps('sw-dips-barres-paralleles', 20),
            _maxReps('sw-pompe', 35),
          ],
        );
        final weeks = weeksOf(_program(catalog, profile, 5));
        expect(weeks.length, greaterThanOrEqualTo(5), reason: gap.code);
        final hard = hardSetsByWeek(catalog, weeks);
        expect(
          hard[0],
          lessThanOrEqualTo(hard[4] * 0.7),
          reason:
              '${gap.code} : semaine 1 ${hard[0]} séries dures, '
              'semaine 5 ${hard[4]}',
        );
        for (var k = 1; k < 5; k++) {
          if (!loadWeek(weeks[k - 1]) || !loadWeek(weeks[k])) {
            continue;
          }
          expect(
            hard[k],
            lessThanOrEqualTo(hard[k - 1] * 1.2 + 2),
            reason:
                '${gap.code} : semaine ${k + 1} ${hard[k]} séries dures '
                'après ${hard[k - 1]}',
          );
        }
      }
    });

    test('aucune charge au-delà du 1RM, sauf amplitude partielle', () {
      var seen = 0;
      for (final w in weeksOf(lifterBlocks)) {
        for (final d in w.days) {
          for (final i in d.items) {
            if (i.exerciseId.contains('partiel')) {
              continue;
            }
            final where = 's${w.weekIndex} j${d.dayIndex} ${i.exerciseId}';
            final pct = i.percentOfOneRm;
            if (pct != null) {
              seen++;
              expect(pct, lessThanOrEqualTo(1.0), reason: '$where : $pct');
            }
            final intensity = i.intensity;
            if (intensity != null &&
                intensity.basis == IntensityBasis.percentOneRm) {
              final high = intensity.valueHigh ?? intensity.value;
              expect(
                intensity.value > high ? intensity.value : high,
                lessThanOrEqualTo(1.0),
                reason: '$where : intensité ${intensity.value} à $high',
              );
            }
          }
        }
      }
      expect(seen, greaterThan(0), reason: 'aucune part du 1RM prescrite');
    });

    test('notes et règles de coach : codes connus, texte non vide', () {
      var seen = 0;
      for (final blocks in <List<ProgramBlock>>[lifterBlocks, beginnerBlocks]) {
        for (final b in blocks) {
          for (final r in <Reason>[
            ...b.pass1.reasons,
            for (final d in b.pass1.days)
              for (final s in d.slots) ...s.reasons,
            ...b.pass2.reasons,
            for (final w in b.pass2.weeks)
              for (final d in w.days)
                for (final i in d.items) ...i.reasons,
          ]) {
            final where = jsonEncode(r.toJson());
            if (r.code == ReasonCodes.planCoachNote) {
              expect(CoachNotes.all, contains(r.params['note']), reason: where);
            } else if (r.code == ReasonCodes.planProgressionRule) {
              expect(CoachRules.all, contains(r.params['rule']), reason: where);
            } else {
              continue;
            }
            seen++;
            final text = coachReasonText(r, catalog);
            expect(text, isNotNull, reason: where);
            expect((text ?? '').trim(), isNotEmpty, reason: where);
          }
        }
      }
      expect(seen, greaterThan(0), reason: 'aucune note de coach émise');
    });
  });
  group('CX — saison complète', () {
    // Tractions à la barre : un jour qui en contient en travail principal,
    // secondaire ou de figure ne suit pas un autre jour qui en contient
    // (48 h de récupération, ACSM 2011 ; LANCEMENTS.md CX, correction 6).
    bool barPull(String id) =>
        id == 'sl-traction-lestee' ||
        id == 'sw-traction-pronation' ||
        id == 'sw-traction-supination' ||
        id.contains('muscle-up');
    const hardRoles = <SlotRole>{
      SlotRole.main,
      SlotRole.secondary,
      SlotRole.skill,
    };

    void noBackToBackPulls(List<ProgramBlock> blocks) {
      for (final b in blocks) {
        final pulls = <int>[
          for (final d in b.pass1.days)
            if (d.slots.any(
              (s) => hardRoles.contains(s.role) && barPull(s.exerciseId),
            ))
              d.weekday,
        ];
        for (final x in pulls) {
          for (final y in pulls) {
            expect(
              (y - x) % 7 == 1,
              isFalse,
              reason: 'bloc ${b.pass1.blockIndex} : jours $x et $y',
            );
          }
        }
      }
    }

    test('streetlifting : pas de traction deux jours de suite', () {
      noBackToBackPulls(_program(catalog, _lifter(), 12));
    });

    test('répétitions avancé : pas de traction deux jours de suite', () {
      final profile = _profile(
        experience: ExperienceLevel.advanced,
        weekdays: const <int>[1, 2, 4, 6],
        minutes: 75,
        benchmarks: <Benchmark>[
          _maxReps('sw-traction-pronation', 22),
          _maxReps('sw-dips-barres-paralleles', 35),
          _maxReps('sw-pompe', 60),
        ],
        events: <SeasonEvent>[
          SeasonEvent(
            id: 'e1',
            kind: EventKind.repsCompetition,
            priority: EventPriority.main,
            date: _start.addDays(7 * 12 - 2),
            mode: RepsEventMode.maxReps,
          ),
        ],
      );
      noBackToBackPulls(_program(catalog, profile, 12));
    });

    test('épreuve de force : catégorie de poids, puis transition', () {
      final blocks = _program(catalog, _lifter(weeksOut: 8), 14);
      final reasons = <Reason>[
        for (final b in blocks) ...b.pass1.reasons,
        for (final b in blocks) ...b.pass2.reasons,
      ];
      expect(
        reasons.any(
          (r) =>
              r.code == ReasonCodes.planCoachNote &&
              r.params['note'] == CoachNotes.weightClass &&
              r.params['value'] == 80,
        ),
        isTrue,
        reason: '78 kg : catégorie des −80 kg',
      );
      final eventDay = _start.addDays(7 * 8 - 2);
      final after = blocks.where((b) {
        final days = eventDay.daysUntil(b.pass1.startDate);
        return days >= 1 && days <= 10;
      }).toList();
      expect(after, hasLength(1));
      expect(after.single.pass2.weeks.first.intent, WeekIntent.transition);
    });

    test('débutant sans pompe : échelle genoux, mains surélevées, sol', () {
      final profile = _beginner().copyWith(
        benchmarks: <Benchmark>[_maxReps('sw-pompe-genoux', 8)],
      );
      final pass1 = _program(catalog, profile, 4).first.pass1;
      final ladder = (pass1.skillLadders ?? const <SkillLadder>[]).where(
        (l) => l.targetExerciseId == 'sw-pompe',
      );
      expect(ladder, hasLength(1));
      final steps = ladder.single.steps.map((s) => s.exerciseId).toList();
      expect(steps.last, 'sw-pompe');
      expect(steps, contains('sw-pompe-inclinee'));
      expect(
        pass1.days.any((d) => d.slots.any((s) => s.exerciseId == 'sw-pompe')),
        isFalse,
        reason: 'pompe au sol avant le critère de passage',
      );
    });

    test('un test mesuré plus bas que le record déclaré fait foi', () {
      final declared = _profile(
        experience: ExperienceLevel.intermediate,
        benchmarks: <Benchmark>[
          _maxReps('sw-traction-pronation', 14),
          _maxReps('sw-dips-barres-paralleles', 20),
        ],
      );
      final tested = declared.copyWith(
        benchmarks: <Benchmark>[
          ...declared.benchmarks!,
          Benchmark(
            exerciseId: 'sw-traction-pronation',
            kind: BenchmarkKind.maxReps,
            source: BenchmarkSource.guidedTest,
            reps: 9,
            date: _start.addDays(-3),
          ),
        ],
      );
      int pullReps(AthleteProfile p) {
        var most = 0;
        final week = _program(catalog, p, 4).first.pass2.weeks.first;
        for (final d in week.days) {
          for (final i in d.items) {
            if (i.exerciseId == 'sw-traction-pronation' &&
                (i.kind == null || i.kind == SetKind.work)) {
              final reps = i.repsHigh;
              if (reps != null && reps > most) {
                most = reps;
              }
            }
          }
        }
        return most;
      }

      final before = pullReps(declared);
      final after = pullReps(tested);
      expect(before, greaterThan(0));
      expect(after, lessThan(before));
      expect(after, lessThan(9));
    });
  });
  group('CX correction 1', () {
    bool noted(ProgramBlock b, String note) =>
        <Reason>[...b.pass1.reasons, ...b.pass2.reasons].any(
          (r) =>
              r.code == ReasonCodes.planCoachNote && r.params['note'] == note,
        );

    AthleteProfile street() => _profile(
      experience: ExperienceLevel.intermediate,
      weekdays: const <int>[1, 3, 5],
      minutes: 75,
      benchmarks: <Benchmark>[
        _maxReps('sw-traction-pronation', 12),
        _maxReps('sw-dips-barres-paralleles', 18),
        _maxReps('sw-pompe', 35),
      ],
    );

    for (final zone in <BodyZone>[BodyZone.wristHand, BodyZone.elbow]) {
      test('douleur qui dure (${zone.code}) : arrêt, puis reprise graduée', () {
        final blocks = _programWith(
          catalog,
          street(),
          16,
          reasonsFor: (n) => n == 1
              ? <Reason>[
                  Reason(
                    code: ReasonCodes.adaptPainPersistent,
                    params: <String, Object?>{'zone': zone.code, 'sessions': 3},
                  ),
                ]
              : const <Reason>[],
        );
        expect(blocks.length, greaterThanOrEqualTo(3));
        final stopped = blocks[1];
        expect(noted(stopped, CoachNotes.painStop), isTrue);
        for (final w in stopped.pass2.weeks) {
          for (final d in w.days) {
            for (final i in d.items) {
              final e = catalog.exercise(i.exerciseId);
              expect(
                coachPainProvokes(e, zone),
                isFalse,
                reason: '${i.exerciseId} provoque ${zone.code}',
              );
              if (zone == BodyZone.elbow) {
                expect(coachPronationPull(e), isFalse, reason: i.exerciseId);
              }
            }
          }
        }
        final back = blocks[2];
        expect(noted(back, CoachNotes.painReturn), isTrue);
        var returning = 0;
        for (final w in back.pass2.weeks) {
          for (final d in w.days) {
            for (final i in d.items) {
              final item = i.reasons.any(
                (r) =>
                    r.code == ReasonCodes.planCoachNote &&
                    r.params['note'] == CoachNotes.painReturnItem,
              );
              if (!item) {
                continue;
              }
              returning++;
              final flames = i.targetFlames;
              if (flames != null && i.kind == SetKind.work) {
                expect(Flames.toRir(flames), greaterThanOrEqualTo(3));
              }
            }
          }
        }
        expect(returning, greaterThan(0));
      });
    }

    test('un repère mesuré ne baisse qu\'après deux mesures concordantes', () {
      Benchmark tested(int reps, int daysAgo) => Benchmark(
        exerciseId: 'sw-traction-pronation',
        kind: BenchmarkKind.maxReps,
        source: BenchmarkSource.guidedTest,
        reps: reps,
        date: _start.addDays(-daysAgo),
      );
      int pullReps(AthleteProfile p) {
        var most = 0;
        final week = _program(catalog, p, 4).first.pass2.weeks.first;
        for (final d in week.days) {
          for (final i in d.items) {
            if (i.exerciseId == 'sw-traction-pronation' &&
                (i.kind == null || i.kind == SetKind.work)) {
              final reps = i.repsHigh;
              if (reps != null && reps > most) {
                most = reps;
              }
            }
          }
        }
        return most;
      }

      final base = street();
      // Même plateau des deux côtés (14, puis 14 ou 9) : seul le repère
      // diffère.
      final once = base.copyWith(
        benchmarks: <Benchmark>[
          ...base.benchmarks!,
          tested(14, 40),
          tested(14, 3),
        ],
      );
      final lowOnce = base.copyWith(
        benchmarks: <Benchmark>[
          ...base.benchmarks!,
          tested(14, 40),
          tested(9, 3),
        ],
      );
      final lowTwice = base.copyWith(
        benchmarks: <Benchmark>[
          ...base.benchmarks!,
          tested(14, 60),
          tested(10, 30),
          tested(9, 3),
        ],
      );
      expect(pullReps(lowOnce), pullReps(once));
      expect(pullReps(lowTwice), lessThan(pullReps(once)));
    });

    test('tests placés après le premier jour de la semaine', () {
      for (final profile in <AthleteProfile>[street(), _beginner()]) {
        for (final b in _program(catalog, profile, 16)) {
          for (final w in b.pass2.weeks) {
            for (final d in w.days) {
              final weekday = b.pass1.days[d.dayIndex].weekday;
              for (final i in d.items) {
                if (i.test != null) {
                  expect(
                    weekday,
                    greaterThanOrEqualTo(3),
                    reason: 'bloc ${b.pass1.blockIndex}, ${i.exerciseId}',
                  );
                }
              }
            }
          }
        }
      }
    });

    test('répétitions au poids du corps : +15 % au plus par semaine', () {
      final reps = _profile(
        experience: ExperienceLevel.advanced,
        weekdays: const <int>[1, 2, 4, 6],
        minutes: 75,
        benchmarks: <Benchmark>[
          _maxReps('sw-traction-pronation', 22),
          _maxReps('sw-dips-barres-paralleles', 35),
          _maxReps('sw-pompe', 60),
        ],
        events: <SeasonEvent>[
          SeasonEvent(
            id: 'e1',
            kind: EventKind.repsCompetition,
            priority: EventPriority.main,
            date: _start.addDays(7 * 12 - 2),
            mode: RepsEventMode.maxReps,
          ),
        ],
      );
      // Semaines enchaînées sur toute la saison : la référence est le
      // maximum des trois semaines d'avant (un retour au niveau d'avant
      // l'allègement n'est pas une hausse).
      for (final profile in <AthleteProfile>[street(), reps]) {
        final totals = <Map<String, int>>[];
        final where = <String>[];
        for (final b in _program(catalog, profile, 12)) {
          for (final w in b.pass2.weeks) {
            final t = <String, int>{};
            for (final d in w.days) {
              for (final i in d.items) {
                final e = catalog.exercise(i.exerciseId);
                final high = i.repsHigh;
                if (high == null ||
                    i.kind != SetKind.work ||
                    i.test != null ||
                    e.unit != MeasureUnit.repetitions ||
                    (e.loadType != LoadType.bodyweight &&
                        e.loadType != LoadType.none)) {
                  continue;
                }
                t[e.rootId] = (t[e.rootId] ?? 0) + i.sets * high;
              }
            }
            totals.add(t);
            where.add('bloc ${b.pass1.blockIndex}, semaine ${w.weekIndex}');
          }
        }
        for (var w = 1; w < totals.length; w++) {
          for (final root in totals[w].keys) {
            var reference = 0;
            for (var k = w - 3; k < w; k++) {
              if (k >= 0 && (totals[k][root] ?? 0) > reference) {
                reference = totals[k][root]!;
              }
            }
            if (reference == 0) {
              continue;
            }
            expect(
              totals[w][root]!,
              lessThanOrEqualTo((reference * 1.15).ceil()),
              reason: '${where[w]}, $root',
            );
          }
        }
      }
    });
  });
}
