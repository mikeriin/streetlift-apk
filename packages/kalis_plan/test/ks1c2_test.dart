// Lot KS1c2 (kalis_plan 0.4.2) : aucun jour typé sans son principal, sur
// tous les états du profil (constat de KS1A, LIVRAISON_KS1A.md § 1.5 : le
// jour « Poussée — endurance de force » d'un profil street 50 / 50 sans
// repère de poussée, questionnaire de santé non rempli, ne contenait aucun
// exercice de poussée).
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

final CivilDate _start = CivilDate(2026, 10, 16);

/// Matériel du profil d'exemple de l'application (`sampleAthleteProfile`).
const List<String> _appEquipment = <String>[
  'aucun (sol)',
  'barre fixe',
  'barres parallèles',
  'barre olympique',
  'disques',
  'cage / rack',
  'ceinture de lest',
];

const List<String> _fullGym = <String>[
  ..._appEquipment,
  'barre basse',
  'élastique',
  'banc plat',
  'haltères',
  'poulie',
  'anneaux',
  'tapis',
];

MovementLevel _level(String id, LevelMeasure m, double low, double high) =>
    MovementLevel(
      exerciseId: id,
      measure: m,
      known: true,
      low: low,
      high: high,
    );

/// Repères complets d'un avancé (choix raisonné, proches du profil de test
/// du banc `ks_test_ppl6`).
const Map<String, (LevelMeasure, double)> _allMarks =
    <String, (LevelMeasure, double)>{
      'sl-traction-lestee': (LevelMeasure.oneRmKg, 40),
      'sw-traction-pronation': (LevelMeasure.maxReps, 15),
      'sl-dips-leste': (LevelMeasure.oneRmKg, 50),
      'sw-dips-barres-paralleles': (LevelMeasure.maxReps, 25),
      'sw-pompe': (LevelMeasure.maxReps, 40),
      'sl-squat-competition': (LevelMeasure.oneRmKg, 110),
    };

/// Profil street 50 / 50 à [sessions] séances de 120 min : par défaut,
/// réplique du profil d'exemple de l'application qui a montré le constat
/// de KS1A (`sampleStreet5050Profile`, dev7.1.0 : seuls repères traction
/// lestée 35 à 50 kg et 13 à 20 tractions ; questionnaire non rempli ;
/// compétition principale dans 12 semaines ; objectif traction lestée 60 kg
/// à 180 jours).
AthleteProfile _street5050({
  int sessions = 6,
  List<MovementLevel>? levels,
  HealthScreeningOutcome health = HealthScreeningOutcome.notAnswered,
  ExperienceLevel experience = ExperienceLevel.advanced,
  TrainingAge age = TrainingAge.years2To5,
  List<String> equipment = _appEquipment,
  List<Limitation> limitations = const <Limitation>[],
}) {
  const mode = StreetMode(
    primary: StreetStyle.streetlifting,
    streetliftingPct: 50,
    setsRepsPct: 50,
    calisthenicsPct: 0,
  );
  return AthleteProfile(
    schemaVersion: 3,
    sex: Sex.male,
    birthYear: 1990,
    heightCm: 178,
    bodyWeightKg: 75,
    disciplines: mode.toDisciplineMix(),
    streetMode: mode,
    movementLevels:
        levels ??
        <MovementLevel>[
          _level('sl-traction-lestee', LevelMeasure.oneRmKg, 35, 50),
          _level('sw-traction-pronation', LevelMeasure.maxReps, 13, 20),
        ],
    goals: <Goal>[
      Goal(
        id: 'goal-1',
        kind: GoalKind.performance,
        origin: GoalOrigin.user,
        createdOn: _start,
        exerciseId: 'sl-traction-lestee',
        metric: GoalMetric.oneRmKg,
        targetValue: 60,
        targetDate: _start.addDays(180),
      ),
    ],
    availability: <DaySlot>[
      for (var w = 1; w <= sessions; w++) DaySlot(weekday: w, minutes: 120),
    ],
    places: const <Place>[Place.gym],
    equipment: equipment,
    loadIncrements: const <LoadIncrement>[],
    limitations: limitations,
    likedExerciseIds: const <String>[],
    dislikedExerciseIds: const <String>[],
    experience: experience,
    guidanceMode: GuidanceMode.assisted,
    healthScreening: HealthScreeningRef(
      questionnaireId: 'kalis-sante-l13-v1',
      answeredOn: health == HealthScreeningOutcome.notAnswered ? null : _start,
      outcome: health,
    ),
    createdOn: _start,
    updatedOn: _start,
    trainingAge: age,
    trainingGap: TrainingGap.none,
    events: <SeasonEvent>[
      SeasonEvent(
        id: 'ci1-competition',
        kind: EventKind.strengthCompetition,
        priority: EventPriority.main,
        date: _start.addDays(84),
        lifts: const <CompetitionLift>[
          CompetitionLift(
            exerciseId: 'sl-traction-lestee',
            attempts: 3,
            minIncrementKg: 1.25,
          ),
        ],
      ),
    ],
  );
}

String? _schema(Catalog catalog, String id) {
  final e = catalog.find(id);
  if (e == null) {
    return null;
  }
  return coachSchemaOf(e)?.code;
}

/// Écarts du jour [d] à la règle (même définition que `kalis_bench`,
/// `principalGapsOfDay`, réécrite ici pour un contrôle indépendant).
List<String> _gaps(Catalog catalog, PlanDay d) {
  final type = d.type;
  if (type == null ||
      type.quality == DayQuality.run ||
      type.quality == DayQuality.recovery ||
      type.quality == DayQuality.conditioning) {
    return const <String>[];
  }
  final schemas = <String>{
    for (final p in type.patterns)
      ...switch (p) {
        DayPattern.pull => const <String>['pull'],
        DayPattern.push => const <String>['push'],
        DayPattern.legs => const <String>['legs'],
        DayPattern.full => const <String>['pull', 'push', 'legs'],
        _ => const <String>[],
      },
  };
  if (schemas.isEmpty) {
    return const <String>[];
  }
  final carried = <String>{};
  var main = false;
  for (final s in d.slots) {
    final schema = _schema(catalog, s.exerciseId);
    if (schema == null || !schemas.contains(schema)) {
      continue;
    }
    if (s.role == SlotRole.main) {
      main = true;
    }
    if (s.role == SlotRole.main || s.role == SlotRole.secondary) {
      carried.add(schema);
    }
  }
  return <String>[
    if (!main) 'principal',
    if (type.patterns.contains(DayPattern.full) && carried.length < 2)
      'corps entier',
    for (final p in type.patterns)
      if ((p == DayPattern.pull || p == DayPattern.push || p == DayPattern.legs) &&
          !carried.contains(p.code))
        'schéma ${p.code}',
  ];
}

/// Gabarits d'avant 0.4.0, figés par le critère d'identité (leurs jours de
/// volume portent leurs schémas en secondaires : lot KS1).
const Set<String> _legacy = <String>{
  SplitTemplates.liftDup,
  SplitTemplates.repsPillars,
  SplitTemplates.figures,
  SplitTemplates.beginner,
  SplitTemplates.hypertrophy,
  SplitTemplates.strength,
  SplitTemplates.endurance,
  SplitTemplates.conditioning,
  SplitTemplates.health,
};

/// Écarts de la passe 1 : écarts de schéma partout ; absence de principal
/// sur les gabarits typés seulement.
List<String> _planGaps(Catalog catalog, Pass1Plan plan) {
  final legacy = _legacy.contains(plan.split?.templateId);
  return <String>[
    for (final d in plan.days)
      for (final g in _gaps(catalog, d))
        if (g != 'principal' || !legacy) 'j${d.dayIndex} $g',
  ];
}

void main() {
  final catalog = loadCatalog();
  final engine = KalisPlan();

  Pass1Plan pass1Of(AthleteProfile p) =>
      engine.createPass1(catalog, requestFor(p));

  group('KS1c2 — constat de KS1A', () {
    final profile = _street5050();
    final pass1 = pass1Of(profile);
    final pass2 = engine.createPass2(
      catalog,
      Pass2Request(request: requestFor(profile), pass1: pass1),
    );

    test('gabarit ppl6_q, chaque jour typé porte un principal de son schéma',
        () {
      expect(pass1.split?.templateId, SplitTemplates.pushPullLegs6);
      expect(_planGaps(catalog, pass1), isEmpty);
    });

    test('le jour poussée — endurance de force porte un exercice de poussée '
        'principal, en tête après la préparation', () {
      final day = pass1.days.firstWhere(
        (d) =>
            d.type!.patterns.contains(DayPattern.push) &&
            d.type!.quality == DayQuality.endurance,
      );
      final work = day.slots
          .where((s) => s.role != SlotRole.warmup)
          .toList();
      expect(work.first.role, SlotRole.main);
      expect(_schema(catalog, work.first.exerciseId), 'push');
    });

    test('sans repère : dosage prudent écrit et première série de mesure '
        'proposée', () {
      final week = pass2.weeks.first;
      final day = pass1.days.firstWhere(
        (d) =>
            d.type!.patterns.contains(DayPattern.push) &&
            d.type!.quality == DayQuality.endurance,
      );
      final main = day.slots.firstWhere((s) => s.role == SlotRole.main);
      final items = week.days
          .firstWhere((d) => d.dayIndex == day.dayIndex)
          .items
          .where((i) => i.slotId == main.slotId && i.kind == SetKind.work)
          .toList();
      expect(items, isNotEmpty);
      for (final i in items) {
        expect(i.repsLow, isNotNull);
        expect(i.repsHigh, lessThanOrEqualTo(12));
        expect(i.startLoadKg ?? 0, 0);
      }
      final reasons = <Reason>[for (final i in items) ...i.reasons];
      final note = reasons.where(
        (r) =>
            r.code == ReasonCodes.planCoachNote &&
            r.params['note'] == CoachNotes.repsCalibrate,
      );
      expect(note, isNotEmpty);
      final text = coachReasonText(note.first, catalog);
      expect(text, isNotNull);
      expect(text, contains('repère'));
    });
  });

  group('KS1c2 — grille des profils incomplets', () {
    final marks = <String, List<String>>{
      'tous': _allMarks.keys.toList(),
      'sans tirage': <String>[
        for (final k in _allMarks.keys)
          if (!k.contains('traction')) k,
      ],
      'sans poussée': <String>[
        for (final k in _allMarks.keys)
          if (!k.contains('dips') && k != 'sw-pompe') k,
      ],
      'sans jambes': <String>[
        for (final k in _allMarks.keys)
          if (!k.contains('squat')) k,
      ],
      'aucun': const <String>[],
    };
    const levels = <(ExperienceLevel, TrainingAge)>[
      (ExperienceLevel.beginner, TrainingAge.under6Months),
      (ExperienceLevel.intermediate, TrainingAge.months6To24),
      (ExperienceLevel.advanced, TrainingAge.years2To5),
      (ExperienceLevel.elite, TrainingAge.over5Years),
    ];
    for (final sessions in const <int>[4, 5, 6]) {
      for (final m in marks.entries) {
        for (final health in const <HealthScreeningOutcome>[
          HealthScreeningOutcome.standard,
          HealthScreeningOutcome.notAnswered,
        ]) {
          for (final (experience, age) in levels) {
            final name =
                '$sessions séances, repères ${m.key}, santé ${health.code}, '
                '${experience.code}';
            test(name, () {
              final p = _street5050(
                sessions: sessions,
                health: health,
                experience: experience,
                age: age,
                equipment: _fullGym,
                levels: <MovementLevel>[
                  for (final id in m.value)
                    _level(
                      id,
                      _allMarks[id]!.$1,
                      _allMarks[id]!.$2,
                      _allMarks[id]!.$2,
                    ),
                ],
              );
              final pass1 = pass1Of(p);
              expect(_planGaps(catalog, pass1), isEmpty, reason: name);
              expect(pass1.validate(), isEmpty);
            });
          }
        }
      }
    }
  });

  group('KS1c2 — aucun exercice du schéma possible', () {
    /// Jours qui changent de type : (jour, raison qui suit son type).
    List<(int, Reason)> changed(Pass1Plan pass1) {
      final out = <(int, Reason)>[];
      final reasons = pass1.split!.reasons;
      var day = -1;
      for (final r in reasons) {
        if (r.code == ReasonCodes.planDayType) {
          day++;
        } else if (r.code == ReasonCodes.planJointLimitation ||
            r.code == ReasonCodes.planEquipmentMissing) {
          out.add((day, r));
        }
      }
      return out;
    }

    String show(Pass1Plan pass1) => <String>[
      for (final d in pass1.days)
        'j${d.dayIndex} ${d.type?.toJson()} : '
            '${d.slots.map((s) => '${s.role.code}/${s.exerciseId}').join(', ')}',
    ].join('\n');

    test('poignet très gêné : les jours de poussée deviennent des jours de '
        'récupération, raison écrite après leur type', () {
      final p = _street5050(
        equipment: _fullGym,
        limitations: const <Limitation>[
          Limitation(
            zone: BodyZone.wristHand,
            side: BodySide.both,
            joint: Joint.wrist,
            discomfort: 6,
            since: ConstraintSince.under6Weeks,
          ),
        ],
      );
      final pass1 = pass1Of(p);
      expect(pass1.split?.templateId, SplitTemplates.pushPullLegs6);
      expect(_planGaps(catalog, pass1), isEmpty, reason: show(pass1));
      final c = changed(pass1);
      expect(c, isNotEmpty, reason: show(pass1));
      for (final (d, r) in c) {
        expect(r.code, ReasonCodes.planJointLimitation);
        expect(r.params['joint'], Joint.wrist.code);
        expect(r.params['discomfort'], 6);
        expect(pass1.days[d].type!.patterns, isNot(contains(DayPattern.push)));
      }
      expect(pass1.validate(), isEmpty);
    });

    test('genou très gêné : les jours de jambes changent de type', () {
      final p = _street5050(
        equipment: _fullGym,
        limitations: const <Limitation>[
          Limitation(
            zone: BodyZone.knee,
            side: BodySide.both,
            joint: Joint.knee,
            discomfort: 8,
            since: ConstraintSince.under6Weeks,
          ),
        ],
      );
      final pass1 = pass1Of(p);
      expect(_planGaps(catalog, pass1), isEmpty, reason: show(pass1));
      final c = changed(pass1);
      expect(c, isNotEmpty, reason: show(pass1));
      for (final (d, r) in c) {
        expect(r.params['joint'], Joint.knee.code);
        expect(pass1.days[d].type!.patterns, isNot(contains(DayPattern.legs)));
      }
    });

    test('sans barre fixe : un jour de tirage impossible le dit par le '
        'matériel', () {
      final p = _street5050(
        equipment: const <String>[
          'aucun (sol)',
          'barres parallèles',
          'barre olympique',
          'disques',
          'cage / rack',
          'ceinture de lest',
        ],
      );
      final pass1 = pass1Of(p);
      expect(_planGaps(catalog, pass1), isEmpty, reason: show(pass1));
      for (final (_, r) in changed(pass1)) {
        expect(r.code, ReasonCodes.planEquipmentMissing);
        expect(r.params['equipment'], isA<String>());
      }
      expect(pass1.validate(), isEmpty);
    });
  });
}
