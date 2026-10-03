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
      expect(hard.first, lessThan(hard[2]));
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
}
