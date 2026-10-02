// Profil d'athlète v3 (0.4.0) : migration du schéma 2 sans perte ni
// invention, relecture à l'identique du JSON du schéma 2, invariants des
// champs du schéma 3, profils types v3.
@Timeout(Duration(minutes: 30))
library;

import 'dart:convert';
import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

/// Tirages seedés (PIPELINE_GP.md §4 : au moins 10 000).
const int samples = 10000;

/// Clés JSON des champs du schéma 3 du profil.
const List<String> schema3Keys = <String>[
  'trainingAge',
  'trainingGap',
  'sleep',
  'stress',
  'occupationalLoad',
  'otherSports',
  'bodyWeightGoal',
  'benchmarks',
  'events',
  'skills',
  'weakPoints',
  'specialization',
  'lifestyleUpdatedOn',
];

/// JSON du profil ramené au schéma 2 : sans aucune clé du schéma 3.
Map<String, Object?> asSchema2Json(Map<String, Object?> json) {
  return <String, Object?>{
    for (final entry in json.entries)
      if (!schema3Keys.contains(entry.key))
        entry.key: entry.key == 'schemaVersion'
            ? 2
            : entry.key == 'limitations'
            ? <Object?>[
                for (final l in entry.value! as List<Object?>)
                  <String, Object?>{
                    for (final e in (l! as Map<String, Object?>).entries)
                      if (e.key != 'since' && e.key != 'aggravatedBy')
                        e.key: e.value,
                  },
              ]
            : entry.value,
  };
}

void main() {
  final catalog = loadCatalog();
  final profilesJson = readJsonObject('test/fixtures/profiles.json');
  final v2Profiles = readProfileFixtures(profilesJson);
  final v3Json = readJsonObject('test/fixtures/profiles_v3.json');
  final v3Profiles = readProfileFixtures(v3Json);

  group('schéma 2 relu à l\'identique', () {
    test('les 40 profils types du schéma 2 se réécrivent à l\'octet près', () {
      final items = profilesJson['profiles']! as List<Object?>;
      expect(items, hasLength(40));
      for (final item in items) {
        final json = (item! as Map<String, Object?>)['profile']!;
        final profile = AthleteProfile.fromJson(json as Map<String, Object?>);
        expect(profile.schemaVersion, 2);
        expect(profile.schema3FieldsPresent, isEmpty);
        expect(profile.validate(), isEmpty);
        expect(jsonEncode(profile.toJson()), jsonEncode(json));
      }
    });

    test('$samples profils du schéma 2 aléatoires : lecture puis écriture '
        'identiques, aucune clé du schéma 3 inventée', () {
      final r = Random(4001);
      for (var i = 0; i < samples; i++) {
        final v2 = asSchema2Json(arbitraryAthleteProfile(r).toJson());
        final text = jsonEncode(v2);
        final back = AthleteProfile.fromJson(
          jsonDecode(text) as Map<String, Object?>,
        );
        expect(back.schemaVersion, 2);
        expect(back.schema3FieldsPresent, isEmpty);
        expect(jsonEncode(back.toJson()), text);
        expect(codesOf(back.validate()), isNot(contains('schema3_field')));
      }
    });

    test('$samples journaux aléatoires sans les champs 0.4.0 : lecture puis '
        'écriture identiques', () {
      const added = <String>[
        'technique',
        'role',
        'miniSetIndex',
        'restBeforeSeconds',
        'elapsedSeconds',
        'rounds',
        'quality',
        'attemptIndex',
        'eventId',
        'percentOfOneRm',
        'restSeconds',
      ];
      Object? strip(Object? value) {
        if (value is Map<String, Object?>) {
          return <String, Object?>{
            for (final e in value.entries)
              if (!added.contains(e.key)) e.key: strip(e.value),
          };
        }
        if (value is List<Object?>) {
          return <Object?>[for (final v in value) strip(v)];
        }
        return value;
      }

      final r = Random(4002);
      for (var i = 0; i < samples; i++) {
        final old = strip(arbitrarySessionRecord(r).toJson());
        final text = jsonEncode(old);
        final back = SessionRecord.fromJson(
          jsonDecode(text) as Map<String, Object?>,
        );
        expect(jsonEncode(back.toJson()), text);
        for (final set in back.sets) {
          expect(set.technique, isNull);
          expect(set.quality, isNull);
        }
      }
    });
  });

  group('migration du schéma 2 vers le schéma 3', () {
    test('profils types : seul le numéro de schéma change', () {
      for (final p in v2Profiles) {
        final migrated = p.profile.toSchema3();
        expect(migrated.schemaVersion, 3, reason: p.key);
        expect(migrated.schema3FieldsPresent, isEmpty, reason: p.key);
        expect(migrated.validate(), isEmpty, reason: p.key);
        expect(catalog.checkProfile(migrated), isEmpty, reason: p.key);
        expect(migrated.copyWith(schemaVersion: 2), p.profile, reason: p.key);
        final before = p.profile.toJson();
        final after = migrated.toJson();
        expect(after.keys.toList(), before.keys.toList(), reason: p.key);
        for (final key in before.keys) {
          if (key != 'schemaVersion') {
            expect(
              jsonEncode(after[key]),
              jsonEncode(before[key]),
              reason: '${p.key}.$key',
            );
          }
        }
        // Idempotente.
        expect(identical(migrated.toSchema3(), migrated), isTrue);
      }
    });

    test('$samples profils aléatoires : ni perte ni invention, mêmes '
        'violations, migration du JSON équivalente', () {
      final r = Random(4003);
      for (var i = 0; i < samples; i++) {
        final v2Json = asSchema2Json(arbitraryAthleteProfile(r).toJson());
        final v2 = AthleteProfile.fromJson(v2Json);
        final v3 = v2.toSchema3();
        expect(v3.schemaVersion, 3);
        expect(v3.copyWith(schemaVersion: 2), v2);
        expect(v3.schema3FieldsPresent, isEmpty);
        final migratedJson = migrateAthleteProfileJsonToSchema3(v2Json);
        expect(jsonEncode(migratedJson), jsonEncode(v3.toJson()));
        expect(migratedJson.keys.toList(), v2Json.keys.toList());
        expect(codesOf(v3.validate()), codesOf(v2.validate()));
        expect(
          jsonEncode(migrateAthleteProfileJsonToSchema3(migratedJson)),
          jsonEncode(migratedJson),
        );
      }
    });

    test('la migration du JSON garde les clés inconnues et refuse un schéma '
        'inattendu', () {
      final json = baseProfile().copyWith(schemaVersion: 2).toJson();
      final withUnknown = <String, Object?>{...json, 'champFutur': 7};
      final migrated = migrateAthleteProfileJsonToSchema3(withUnknown);
      expect(migrated['champFutur'], 7);
      expect(migrated['schemaVersion'], 3);
      expect(withUnknown['schemaVersion'], 2, reason: 'entrée non modifiée');
      expect(
        () => migrateAthleteProfileJsonToSchema3(<String, Object?>{
          ...json,
          'schemaVersion': 1,
        }),
        throwsFormatException,
      );
      expect(
        () => migrateAthleteProfileJsonToSchema3(<String, Object?>{
          ...json,
          'schemaVersion': 4,
        }),
        throwsFormatException,
      );
      expect(
        () => migrateAthleteProfileJsonToSchema3(
          <String, Object?>{...json}..remove('schemaVersion'),
        ),
        throwsFormatException,
      );
    });

    test('un champ du schéma 3 exige le schéma 3', () {
      final v3 = baseProfile().copyWith(sleep: SleepBand.under6Hours);
      expect(v3.validate(), isEmpty);
      expect(v3.schema3FieldsPresent, <String>['sleep']);
      final wrong = v3.copyWith(schemaVersion: 2);
      expect(codesOf(wrong.validate()), <String>['schema3_field']);
      final limited = baseProfile().copyWith(
        schemaVersion: 2,
        limitations: const <Limitation>[
          Limitation(
            zone: BodyZone.elbow,
            side: BodySide.both,
            joint: Joint.elbow,
            discomfort: 2,
            since: ConstraintSince.months3To12,
          ),
        ],
      );
      expect(codesOf(limited.validate()), <String>['schema3_field']);
      expect(limited.toSchema3().validate(), isEmpty);
    });

    test('une réponse absente reste absente (aucune valeur par défaut)', () {
      final p = baseProfile();
      final json = p.toJson();
      for (final key in schema3Keys) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
      expect(p.sleep, isNull);
      expect(p.stress, isNull);
      expect(p.otherSports, isNull);
      expect(p.events, isNull);
      // Liste vide ≠ champ absent.
      final none = p.copyWith(otherSports: const <OtherSport>[]);
      expect(none.toJson()['otherSports'], isEmpty);
      expect(
        AthleteProfile.fromJson(viaJsonText(none.toJson())).otherSports,
        isEmpty,
      );
      expect(none.copyWith(otherSports: null).otherSports, isNull);
    });
  });

  group('profils types du schéma 3', () {
    test('valides, connus du catalogue, allers-retours exacts', () {
      expect(v3Profiles.length, greaterThanOrEqualTo(5));
      for (final p in v3Profiles) {
        expect(p.profile.schemaVersion, 3, reason: p.key);
        expect(p.profile.validate(), isEmpty, reason: p.key);
        expect(catalog.checkProfile(p.profile), isEmpty, reason: p.key);
        expect(
          AthleteProfile.fromJson(viaJsonText(p.profile.toJson())),
          p.profile,
          reason: p.key,
        );
        expect(
          p.profile.createdOn.year - p.profile.birthYear,
          greaterThanOrEqualTo(18),
          reason: p.key,
        );
      }
      final items = v3Json['profiles']! as List<Object?>;
      for (final item in items) {
        final json = (item! as Map<String, Object?>)['profile']!;
        expect(
          jsonEncode(
            AthleteProfile.fromJson(json as Map<String, Object?>).toJson(),
          ),
          jsonEncode(json),
        );
      }
    });

    test('les situations du lot sont couvertes', () {
      AthleteProfile of(String key) =>
          v3Profiles.firstWhere((p) => p.key == key).profile;
      final beginner = of('v3_debutant_forme_generale');
      expect(beginner.experience, ExperienceLevel.beginner);
      expect(beginner.trainingAge, TrainingAge.under6Months);
      expect(beginner.otherSports, isEmpty);
      expect(beginner.events, isNull);
      expect(beginner.benchmarks, isNull);

      final elite = of('v3_competiteur_elite_streetlifting');
      expect(elite.experience, ExperienceLevel.elite);
      expect(elite.events, hasLength(2));
      final main = elite.events!.first;
      expect(main.kind, EventKind.strengthCompetition);
      expect(main.priority, EventPriority.main);
      expect(main.lifts!.map((l) => l.exerciseId), <String>[
        'sl-muscle-up-leste',
        'sl-traction-lestee',
        'sl-dips-leste',
        'sl-squat-competition',
      ]);
      expect(main.lifts!.every((l) => l.attempts == 3), isTrue);
      expect(elite.skills!.single.currentExerciseId, 'cs-front-lever-straddle');
      expect(elite.weakPoints, hasLength(2));
      expect(elite.specialization!.kind, SpecializationKind.exercise);
      expect(elite.limitations.single.aggravatedBy, <AggravatingMovement>[
        AggravatingMovement.straightArmSupport,
        AggravatingMovement.pullBentArm,
      ]);

      final runner = of('v3_coureuse_10km');
      expect(runner.events!.single.kind, EventKind.race);
      expect(runner.trainingGap, TrainingGap.under3Weeks);
      expect(runner.benchmarks!.single.kind, BenchmarkKind.timeTrial);

      final reps = of('v3_sets_reps_avance');
      final event = reps.events!.single;
      expect(event.kind, EventKind.repsCompetition);
      expect(event.mode, RepsEventMode.forTime);
      expect(event.stations, hasLength(5));
      expect(reps.sleep, SleepBand.under6Hours);
      expect(reps.otherSports!.single.kind, OtherSportKind.combatSport);
    });

    test('contrôles du catalogue propres au schéma 3', () {
      final base = baseProfile();
      final outside = base.copyWith(
        skills: const <SkillState>[
          SkillState(
            targetExerciseId: 'cs-front-lever',
            currentExerciseId: 'cs-planche-tuck',
          ),
        ],
      );
      expect(outside.validate(), isEmpty);
      expect(codesOf(catalog.checkProfile(outside)), <String>[
        'skill_step_outside_progression',
      ]);
      final unknownMuscle = base.copyWith(
        specialization: const Specialization(
          kind: SpecializationKind.muscle,
          muscle: 'muscle imaginaire',
        ),
      );
      expect(codesOf(catalog.checkProfile(unknownMuscle)), <String>[
        'unknown_muscle',
      ]);
      final known = base.copyWith(
        specialization: const Specialization(
          kind: SpecializationKind.muscle,
          muscle: 'grand dorsal',
        ),
      );
      expect(catalog.checkProfile(known), isEmpty);
      expect(
        catalog.isProgressionStep('cs-front-lever-tuck', 'cs-front-lever'),
        isTrue,
      );
      expect(
        catalog.isProgressionStep('cs-front-lever', 'cs-front-lever'),
        isTrue,
      );
      expect(
        catalog.isProgressionStep('cs-front-lever', 'cs-front-lever-tuck'),
        isFalse,
      );
      expect(catalog.isProgressionStep('inconnu', 'cs-front-lever'), isFalse);
      final candidates = catalog.progressionCandidates('cs-front-lever');
      expect(candidates.last.id, 'cs-front-lever');
      expect(
        candidates.map((e) => e.id),
        containsAll(<String>[
          'cs-front-lever-tuck',
          'cs-front-lever-tuck-avance',
          'cs-front-lever-straddle',
        ]),
      );
      expect(candidates.map((e) => e.id).toSet(), hasLength(candidates.length));
      expect(
        () => catalog.progressionCandidates('inconnu'),
        throwsArgumentError,
      );
    });
  });

  group('invariants des champs du schéma 3', () {
    test('identifiants et cibles sans doublon', () {
      final base = baseProfile();
      SeasonEvent event(String id) => SeasonEvent(
        id: id,
        kind: EventKind.personalTest,
        priority: EventPriority.secondary,
        date: CivilDate(2027, 1, 10),
      );
      expect(
        base.copyWith(events: <SeasonEvent>[event('a'), event('b')]).validate(),
        isEmpty,
      );
      expect(
        codesOf(
          base
              .copyWith(events: <SeasonEvent>[event('a'), event('a')])
              .validate(),
        ),
        <String>['duplicate'],
      );
      const skill = SkillState(
        targetExerciseId: 'cs-front-lever',
        currentExerciseId: 'cs-front-lever-tuck',
      );
      expect(
        codesOf(
          base.copyWith(skills: const <SkillState>[skill, skill]).validate(),
        ),
        <String>['duplicate'],
      );
      const weak = WeakPoint(
        exerciseId: 'sl-dips-leste',
        kind: WeakPointKind.bottom,
      );
      expect(
        codesOf(
          base.copyWith(weakPoints: const <WeakPoint>[weak, weak]).validate(),
        ),
        <String>['duplicate'],
      );
      expect(
        codesOf(
          base.copyWith(lifestyleUpdatedOn: CivilDate(2026, 9, 30)).validate(),
        ),
        <String>['date_before_creation'],
      );
    });

    test('autre sport : jours de 1 à 7, distincts', () {
      const ok = OtherSport(
        kind: OtherSportKind.running,
        sessionsPerWeek: 2,
        minutesPerSession: 45,
        weekdays: <int>[2, 6],
      );
      expect(ok.validate(), isEmpty);
      expect(
        codesOf(ok.copyWith(weekdays: const <int>[2, 2]).validate()),
        <String>['duplicate'],
      );
      expect(
        codesOf(ok.copyWith(weekdays: const <int>[0]).validate()),
        <String>['below_min'],
      );
      expect(
        codesOf(ok.copyWith(weekdays: const <int>[8]).validate()),
        <String>['above_max'],
      );
      expect(codesOf(ok.copyWith(sessionsPerWeek: 0).validate()), <String>[
        'below_min',
      ]);
      expect(
        codesOf(
          ok
              .copyWith(
                regions: const <BodyRegion>[
                  BodyRegion.lowerBody,
                  BodyRegion.lowerBody,
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
    });

    test('gêne : mouvements qui la réveillent sans doublon', () {
      const l = Limitation(
        zone: BodyZone.shoulder,
        side: BodySide.right,
        joint: Joint.shoulder,
        discomfort: 3,
        since: ConstraintSince.over12Months,
        aggravatedBy: <AggravatingMovement>[
          AggravatingMovement.overhead,
          AggravatingMovement.rings,
        ],
      );
      expect(l.validate(), isEmpty);
      expect(
        codesOf(
          l
              .copyWith(
                aggravatedBy: const <AggravatingMovement>[
                  AggravatingMovement.rings,
                  AggravatingMovement.rings,
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
      // Sans les champs 0.4.0, le JSON est celui de 0.3.0.
      expect(
        l.copyWith(since: null, aggravatedBy: null).toJson().keys.toList(),
        <String>['zone', 'side', 'joint', 'discomfort'],
      );
    });

    test('test ou record : champs selon la nature', () {
      const oneRm = Benchmark(
        exerciseId: 'sl-traction-lestee',
        kind: BenchmarkKind.loadReps,
        source: BenchmarkSource.competition,
        externalLoadKg: 75,
        reps: 1,
        rir: 0,
        bodyWeightKg: 72.8,
      );
      expect(oneRm.validate(), isEmpty);
      expect(codesOf(oneRm.copyWith(reps: null).validate()), <String>[
        'missing_field',
      ]);
      expect(codesOf(oneRm.copyWith(seconds: 10).validate()), <String>[
        'unexpected_field',
      ]);
      const hold = Benchmark(
        exerciseId: 'cs-front-lever-straddle',
        kind: BenchmarkKind.maxHold,
        source: BenchmarkSource.guidedTest,
        seconds: 8,
        protocolId: 't5_maintien_max',
      );
      expect(hold.validate(), isEmpty);
      expect(codesOf(hold.copyWith(reps: 3).validate()), <String>[
        'unexpected_field',
      ]);
      const run = Benchmark(
        exerciseId: 'ca-footing-endurance-fondamentale',
        kind: BenchmarkKind.timeTrial,
        source: BenchmarkSource.declared,
        distanceMeters: 5000,
        seconds: 1560,
      );
      expect(run.validate(), isEmpty);
      expect(codesOf(run.copyWith(distanceMeters: null).validate()), <String>[
        'missing_field',
      ]);
    });
  });
}
