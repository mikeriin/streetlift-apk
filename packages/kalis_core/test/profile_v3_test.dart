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

/// Clés JSON des champs du schéma 3 du profil, dans l'ordre du contrat
/// (celui de `AthleteProfileSchema.schema3FieldsPresent`).
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
  'recentTraining',
  'currentPhase',
  'emphasis',
  'enduranceBase',
  'targetBodyWeightKg',
  'lifestyleUpdatedOn',
];

/// Clés JSON des champs du schéma 3 d'une gêne (`Limitation`).
const List<String> limitation3Keys = <String>[
  'since',
  'aggravatedBy',
  'effortDiscomfort',
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
                      if (!limitation3Keys.contains(e.key)) e.key: e.value,
                  },
              ]
            : entry.value,
  };
}

/// Violations sous la forme « chemin code ».
List<String> located(Iterable<Violation> violations) {
  return <String>[for (final v in violations) '${v.path} ${v.code}'];
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
        final entry = item! as Map<String, Object?>;
        final json = entry['profile']! as Map<String, Object?>;
        final profile = AthleteProfile.fromJson(json);
        expect(profile.schemaVersion, 2);
        expect(profile.isSchema3, isFalse);
        expect(profile.schema3FieldsPresent, isEmpty);
        expect(profile.validate(), isEmpty);
        expect(jsonEncode(profile.toJson()), jsonEncode(json));
        for (final key in schema3Keys) {
          expect(json.containsKey(key), isFalse, reason: key);
        }
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
        expect(
          codesOf(back.validate()),
          isNot(contains('schema3_field')),
        );
      }
    });

    test('$samples journaux aléatoires sans les champs 0.4.0 : lecture puis '
        'écriture identiques', () {
      // Champs ajoutés par 0.4.0 à `SetRecord`, `SetTarget` et
      // `SessionRecord` (`parts` : les mini-séries d'une ligne de journal).
      const added = <String>[
        'technique',
        'role',
        'parts',
        'restBeforeSeconds',
        'elapsedSeconds',
        'rounds',
        'quality',
        'attemptIndex',
        'eventId',
        'groupResults',
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
        expect(back.eventId, isNull);
        expect(back.groupResults, isNull);
        for (final set in back.sets) {
          expect(set.technique, isNull);
          expect(set.role, isNull);
          expect(set.parts, isNull);
          expect(set.quality, isNull);
        }
      }
    });
  });

  group('migration du schéma 2 vers le schéma 3', () {
    test('profils types : seul le numéro de schéma change', () {
      expect(v2Profiles, hasLength(40));
      for (final p in v2Profiles) {
        final migrated = p.profile.toSchema3();
        expect(migrated.schemaVersion, 3, reason: p.key);
        expect(migrated.isSchema3, isTrue, reason: p.key);
        expect(migrated.schema3FieldsPresent, isEmpty, reason: p.key);
        expect(migrated.validate(), isEmpty, reason: p.key);
        expect(catalog.checkProfile(migrated), isEmpty, reason: p.key);
        expect(
          migrated.copyWith(schemaVersion: 2),
          p.profile,
          reason: p.key,
        );
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
        // Le profil migré se relit, et se réécrit à l'identique.
        final reread = AthleteProfile.fromJson(viaJsonText(after));
        expect(reread, migrated, reason: p.key);
        expect(jsonEncode(reread.toJson()), jsonEncode(after), reason: p.key);
        // Idempotente.
        expect(identical(migrated.toSchema3(), migrated), isTrue);
      }
    });

    test('profils types : la migration du JSON donne le même profil', () {
      final items = profilesJson['profiles']! as List<Object?>;
      for (final item in items) {
        final entry = item! as Map<String, Object?>;
        final key = entry['key']! as String;
        final json = entry['profile']! as Map<String, Object?>;
        final text = jsonEncode(json);
        final migratedJson = migrateAthleteProfileJsonToSchema3(json);
        // L'entrée n'est pas modifiée.
        expect(jsonEncode(json), text, reason: key);
        expect(migratedJson['schemaVersion'], 3, reason: key);
        expect(migratedJson.keys.toList(), json.keys.toList(), reason: key);
        for (final name in json.keys) {
          if (name != 'schemaVersion') {
            expect(
              jsonEncode(migratedJson[name]),
              jsonEncode(json[name]),
              reason: '$key.$name',
            );
          }
        }
        final typed = AthleteProfile.fromJson(json).toSchema3();
        expect(jsonEncode(migratedJson), jsonEncode(typed.toJson()));
        expect(AthleteProfile.fromJson(migratedJson), typed, reason: key);
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
      // Un numéro de schéma qui n'est pas un entier.
      expect(
        () => migrateAthleteProfileJsonToSchema3(<String, Object?>{
          ...json,
          'schemaVersion': '2',
        }),
        throwsFormatException,
      );
      expect(
        () => migrateAthleteProfileJsonToSchema3(<String, Object?>{
          ...json,
          'schemaVersion': null,
        }),
        throwsFormatException,
      );
    });

    test('un champ du schéma 3 exige le schéma 3', () {
      final v3 = baseProfile().copyWith(sleep: SleepBand.under6Hours);
      expect(v3.validate(), isEmpty);
      expect(v3.schema3FieldsPresent, <String>['sleep']);
      final wrong = v3.copyWith(schemaVersion: 2);
      expect(codesOf(wrong.validate()), <String>['schema3_field']);
      expect(located(wrong.validate()), <String>[r'$.sleep schema3_field']);
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
      expect(located(limited.validate()), <String>[
        r'$.limitations schema3_field',
      ]);
      expect(limited.toSchema3().validate(), isEmpty);
    });

    test('chaque champ du schéma 3 : nommé par `schema3FieldsPresent`, '
        'refusé au schéma 2 à son chemin', () {
      final base = baseProfile();
      expect(base.schemaVersion, AthleteProfile.currentSchemaVersion);
      expect(AthleteProfile.currentSchemaVersion, 3);
      expect(base.isSchema3, isTrue);
      expect(base.schema3FieldsPresent, isEmpty);
      expect(base.copyWith(schemaVersion: 2).validate(), isEmpty);
      // Un champ à la fois ; une liste vide est une réponse (« aucun »).
      final single = <String, AthleteProfile>{
        'trainingAge': base.copyWith(trainingAge: TrainingAge.years2To5),
        'trainingGap': base.copyWith(trainingGap: TrainingGap.reduced),
        'sleep': base.copyWith(sleep: SleepBand.hours7Plus),
        'stress': base.copyWith(stress: StressBand.high),
        'occupationalLoad': base.copyWith(
          occupationalLoad: OccupationalLoad.heavy,
        ),
        'otherSports': base.copyWith(otherSports: const <OtherSport>[]),
        'bodyWeightGoal': base.copyWith(
          bodyWeightGoal: BodyWeightGoal.maintain,
        ),
        'benchmarks': base.copyWith(benchmarks: const <Benchmark>[]),
        'events': base.copyWith(events: const <SeasonEvent>[]),
        'skills': base.copyWith(skills: const <SkillState>[]),
        'weakPoints': base.copyWith(weakPoints: const <WeakPoint>[]),
        'specialization': base.copyWith(
          specialization: const Specialization(
            kind: SpecializationKind.muscle,
            muscle: 'grand dorsal',
          ),
        ),
        'recentTraining': base.copyWith(
          recentTraining: const <RecentTraining>[],
        ),
        'currentPhase': base.copyWith(currentPhase: CurrentPhase.heavy),
        'emphasis': base.copyWith(emphasis: TrainingEmphasis.both),
        'enduranceBase': base.copyWith(
          enduranceBase: const EnduranceBase(
            weeklyVolume: RunVolumeBand.km10To20,
            sessionsPerWeek: 2,
          ),
        ),
        'lifestyleUpdatedOn': base.copyWith(
          lifestyleUpdatedOn: CivilDate(2026, 10, 1),
        ),
      };
      // Tous les champs du schéma 3, sauf le poids visé (qui exige un but).
      expect(single.keys.toList(), <String>[
        for (final key in schema3Keys)
          if (key != 'targetBodyWeightKg') key,
      ]);
      for (final entry in single.entries) {
        final key = entry.key;
        final profile = entry.value;
        expect(profile.schema3FieldsPresent, <String>[key], reason: key);
        expect(profile.validate(), isEmpty, reason: key);
        expect(<String>[
          for (final name in profile.toJson().keys)
            if (schema3Keys.contains(name)) name,
        ], <String>[key], reason: key);
        final old = profile.copyWith(schemaVersion: 2);
        expect(old.isSchema3, isFalse, reason: key);
        expect(old.schema3FieldsPresent, <String>[key], reason: key);
        expect(located(old.validate()), <String>[
          '\$.$key schema3_field',
        ], reason: key);
        expect(old.toSchema3(), profile, reason: key);
        expect(old.toSchema3().validate(), isEmpty, reason: key);
        // Relu depuis le JSON : même champ, même refus.
        final reread = AthleteProfile.fromJson(viaJsonText(old.toJson()));
        expect(reread, old, reason: key);
        expect(codesOf(reread.validate()), <String>['schema3_field']);
      }
      // Poids visé : avec son but.
      final target = base.copyWith(
        bodyWeightGoal: BodyWeightGoal.lose,
        targetBodyWeightKg: 58.0,
      );
      expect(target.validate(), isEmpty);
      expect(target.schema3FieldsPresent, <String>[
        'bodyWeightGoal',
        'targetBodyWeightKg',
      ]);
      expect(located(target.copyWith(schemaVersion: 2).validate()), <String>[
        r'$.bodyWeightGoal schema3_field',
        r'$.targetBodyWeightKg schema3_field',
      ]);
      // Gêne : chacun des trois champs du schéma 3 suffit.
      const knee = Limitation(
        zone: BodyZone.knee,
        side: BodySide.left,
        joint: Joint.knee,
        discomfort: 3,
      );
      for (final limitation in <Limitation>[
        knee.copyWith(since: ConstraintSince.pastResolved),
        knee.copyWith(aggravatedBy: const <AggravatingMovement>[]),
        knee.copyWith(
          aggravatedBy: const <AggravatingMovement>[
            AggravatingMovement.kneeFlexion,
          ],
        ),
        knee.copyWith(effortDiscomfort: 0),
        knee.copyWith(effortDiscomfort: 6),
      ]) {
        final reason = limitation.toString();
        final profile = base.copyWith(
          limitations: <Limitation>[knee, limitation],
        );
        expect(profile.validate(), isEmpty, reason: reason);
        expect(
          profile.schema3FieldsPresent,
          <String>['limitations'],
          reason: reason,
        );
        expect(
          located(profile.copyWith(schemaVersion: 2).validate()),
          <String>[r'$.limitations schema3_field'],
          reason: reason,
        );
      }
      // Tous les champs à la fois : la liste entière, dans l'ordre.
      final full = base.copyWith(
        trainingAge: TrainingAge.years2To5,
        trainingGap: TrainingGap.none,
        sleep: SleepBand.hours7Plus,
        stress: StressBand.low,
        occupationalLoad: OccupationalLoad.seated,
        otherSports: const <OtherSport>[],
        bodyWeightGoal: BodyWeightGoal.gain,
        benchmarks: const <Benchmark>[],
        events: const <SeasonEvent>[],
        skills: const <SkillState>[],
        weakPoints: const <WeakPoint>[],
        specialization: const Specialization(
          kind: SpecializationKind.muscle,
          muscle: 'grand dorsal',
        ),
        recentTraining: const <RecentTraining>[],
        currentPhase: CurrentPhase.volume,
        emphasis: TrainingEmphasis.muscle,
        enduranceBase: const EnduranceBase(
          weeklyVolume: RunVolumeBand.none,
          sessionsPerWeek: 0,
        ),
        targetBodyWeightKg: 66.0,
        lifestyleUpdatedOn: CivilDate(2026, 10, 2),
        limitations: <Limitation>[knee.copyWith(effortDiscomfort: 5)],
      );
      expect(full.validate(), isEmpty);
      expect(full.schema3FieldsPresent, <String>[
        ...schema3Keys,
        'limitations',
      ]);
      expect(located(full.copyWith(schemaVersion: 2).validate()), <String>[
        for (final key in schema3Keys) '\$.$key schema3_field',
        r'$.limitations schema3_field',
      ]);
      expect(<String>[
        for (final name in full.toJson().keys)
          if (schema3Keys.contains(name)) name,
      ], schema3Keys);
    });

    test('$samples profils aléatoires : `schema3FieldsPresent` nomme les clés '
        'du schéma 3 écrites, le schéma 2 les refuse une à une', () {
      final r = Random(4004);
      for (var i = 0; i < samples; i++) {
        final profile = arbitraryAthleteProfile(r);
        final json = profile.toJson();
        final limitations = json['limitations']! as List<Object?>;
        final expected = <String>[
          for (final key in schema3Keys)
            if (json.containsKey(key)) key,
          if (limitations.any(
            (l) => (l! as Map<String, Object?>).keys.any(
              limitation3Keys.contains,
            ),
          ))
            'limitations',
        ];
        expect(profile.schemaVersion, 3);
        expect(profile.schema3FieldsPresent, expected);
        final violations = profile.validate();
        expect(codesOf(violations), isNot(contains('schema3_field')));
        final old = profile.copyWith(schemaVersion: 2);
        final oldViolations = old.validate();
        expect(<String>[
          for (final v in oldViolations)
            if (v.code == 'schema3_field') v.path,
        ], <String>[for (final name in expected) '\$.$name']);
        // Les autres violations ne dépendent pas du numéro de schéma.
        expect(
          located(oldViolations.where((v) => v.code != 'schema3_field')),
          located(violations),
        );
        expect(old.toSchema3(), profile);
        // Le JSON complet se relit et se réécrit à l'identique.
        final text = jsonEncode(json);
        final back = AthleteProfile.fromJson(
          jsonDecode(text) as Map<String, Object?>,
        );
        expect(back, profile);
        expect(jsonEncode(back.toJson()), text);
      }
    });

    test('une réponse absente reste absente (aucune valeur par défaut)', () {
      final p = baseProfile();
      final json = p.toJson();
      for (final key in schema3Keys) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
      for (final l in json['limitations']! as List<Object?>) {
        for (final key in limitation3Keys) {
          expect(
            (l! as Map<String, Object?>).containsKey(key),
            isFalse,
            reason: key,
          );
        }
      }
      expect(p.sleep, isNull);
      expect(p.stress, isNull);
      expect(p.otherSports, isNull);
      expect(p.events, isNull);
      expect(p.recentTraining, isNull);
      expect(p.currentPhase, isNull);
      expect(p.emphasis, isNull);
      expect(p.enduranceBase, isNull);
      expect(p.targetBodyWeightKg, isNull);
      expect(p.limitations.single.effortDiscomfort, isNull);
      // Liste vide ≠ champ absent.
      final none = p.copyWith(otherSports: const <OtherSport>[]);
      expect(none.toJson()['otherSports'], isEmpty);
      expect(
        AthleteProfile.fromJson(viaJsonText(none.toJson())).otherSports,
        isEmpty,
      );
      expect(none.copyWith(otherSports: null).otherSports, isNull);
      final noLoad = p.copyWith(recentTraining: const <RecentTraining>[]);
      expect(noLoad.toJson()['recentTraining'], isEmpty);
      expect(
        AthleteProfile.fromJson(viaJsonText(noLoad.toJson())).recentTraining,
        isEmpty,
      );
      expect(noLoad.copyWith(recentTraining: null).recentTraining, isNull);
    });
  });

  group('profils types du schéma 3', () {
    test('valides, connus du catalogue, allers-retours exacts', () {
      expect(v3Profiles, hasLength(5));
      for (final p in v3Profiles) {
        expect(p.profile.schemaVersion, 3, reason: p.key);
        expect(p.profile.isSchema3, isTrue, reason: p.key);
        expect(p.profile.validate(), isEmpty, reason: p.key);
        expect(catalog.checkProfile(p.profile), isEmpty, reason: p.key);
        expect(p.profile.schema3FieldsPresent, isNotEmpty, reason: p.key);
        expect(
          AthleteProfile.fromJson(viaJsonText(p.profile.toJson())),
          p.profile,
          reason: p.key,
        );
        expect(
          identical(p.profile.toSchema3(), p.profile),
          isTrue,
          reason: p.key,
        );
        expect(
          p.profile.createdOn.year - p.profile.birthYear,
          greaterThanOrEqualTo(18),
          reason: p.key,
        );
      }
      final items = v3Json['profiles']! as List<Object?>;
      expect(items, hasLength(5));
      for (final item in items) {
        final entry = item! as Map<String, Object?>;
        final json = entry['profile']! as Map<String, Object?>;
        final profile = AthleteProfile.fromJson(json);
        expect(jsonEncode(profile.toJson()), jsonEncode(json));
        // Déjà au schéma 3 : la migration du JSON ne change rien.
        expect(
          jsonEncode(migrateAthleteProfileJsonToSchema3(json)),
          jsonEncode(json),
        );
      }
    });

    test('les situations du lot sont couvertes', () {
      AthleteProfile of(String key) =>
          v3Profiles.firstWhere((p) => p.key == key).profile;
      final beginner = of('v3_debutant_forme_generale');
      expect(beginner.experience, ExperienceLevel.beginner);
      // L'ancienneté n'est plus demandée à un débutant.
      expect(beginner.trainingAge, isNull);
      expect(beginner.otherSports, isEmpty);
      expect(beginner.events, isNull);
      expect(beginner.benchmarks, isNull);
      expect(beginner.schema3FieldsPresent, <String>[
        'sleep',
        'stress',
        'occupationalLoad',
        'otherSports',
        'lifestyleUpdatedOn',
      ]);

      final intermediate = of('v3_intermediaire_musculation');
      expect(intermediate.experience, ExperienceLevel.intermediate);
      expect(intermediate.trainingAge, TrainingAge.years2To5);
      expect(intermediate.bodyWeightGoal, BodyWeightGoal.lose);
      expect(intermediate.targetBodyWeightKg, 61.0);
      expect(intermediate.emphasis, TrainingEmphasis.muscle);
      expect(intermediate.specialization!.kind, SpecializationKind.muscle);
      expect(intermediate.specialization!.muscle, 'grand fessier');
      expect(intermediate.events, isEmpty);
      expect(intermediate.benchmarks, hasLength(2));
      final knee = intermediate.limitations.single;
      expect(knee.effortDiscomfort, 4);
      expect(knee.aggravatedBy, <AggravatingMovement>[
        AggravatingMovement.kneeFlexion,
        AggravatingMovement.runningJumping,
      ]);

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
      expect(main.plannedBodyWeightKg, 72.8);
      expect(main.goalIds, <String>['g1', 'g2', 'g3', 'g4']);
      expect(elite.skills!.single.currentExerciseId, 'cs-front-lever-straddle');
      expect(elite.skills!.single.atStepSince, StepTenure.months3To6);
      expect(elite.weakPoints, hasLength(2));
      expect(elite.specialization!.kind, SpecializationKind.exercise);
      expect(elite.limitations.single.aggravatedBy, <AggravatingMovement>[
        AggravatingMovement.straightArmSupport,
        AggravatingMovement.elbowLockout,
      ]);
      expect(elite.limitations.single.effortDiscomfort, 3);
      expect(elite.limitations.single.since, ConstraintSince.months3To12);
      expect(elite.recentTraining, hasLength(5));
      expect(elite.recentTraining!.first.hardSets, HardSetsBand.sets10To14);
      expect(elite.recentTraining!.last.hardSets, isNull);
      expect(elite.currentPhase, CurrentPhase.volume);
      expect(
        elite.benchmarks!.map((b) => b.competitionStandard),
        <bool?>[true, true, true, true, null],
      );

      final runner = of('v3_coureuse_10km');
      expect(runner.events!.single.kind, EventKind.race);
      expect(runner.events!.single.bestSeconds, 3210);
      expect(runner.trainingGap, TrainingGap.under3Weeks);
      expect(runner.benchmarks!.single.kind, BenchmarkKind.timeTrial);
      expect(runner.emphasis, TrainingEmphasis.strength);
      expect(
        runner.enduranceBase,
        const EnduranceBase(
          weeklyVolume: RunVolumeBand.km20To35,
          sessionsPerWeek: 3,
          longRun: LongRunBand.min60To90,
        ),
      );

      final reps = of('v3_sets_reps_avance');
      final event = reps.events!.single;
      expect(event.kind, EventKind.repsCompetition);
      expect(event.mode, RepsEventMode.forTime);
      expect(event.stations, hasLength(5));
      expect(event.stations!.first.unbroken, isTrue);
      expect(event.heats, 4);
      expect(event.restBetweenHeatsSeconds, 900);
      expect(event.bestSeconds, 512);
      expect(event.bestDate, CivilDate(2026, 5, 23));
      expect(reps.sleep, SleepBand.under6Hours);
      expect(reps.otherSports!.single.kind, OtherSportKind.combatSport);
      expect(reps.skills!.single.atStepSince, StepTenure.over6Months);
      expect(reps.recentTraining, hasLength(3));
      expect(reps.currentPhase, CurrentPhase.unstructured);
    });

    test('contrôles du catalogue propres au schéma 3', () {
      final base = baseProfile();
      // L'étape actuelle d'une figure n'est plus contrôlée au catalogue :
      // une échelle peut passer par un exercice d'une autre famille.
      final outside = base.copyWith(
        skills: const <SkillState>[
          SkillState(
            targetExerciseId: 'cs-front-lever',
            currentExerciseId: 'cs-planche-tuck',
          ),
        ],
      );
      expect(outside.validate(), isEmpty);
      expect(
        catalog.isProgressionStep('cs-planche-tuck', 'cs-front-lever'),
        isFalse,
      );
      expect(catalog.checkProfile(outside), isEmpty);
      // Un exercice inconnu reste signalé.
      final unknownStep = base.copyWith(
        skills: const <SkillState>[
          SkillState(
            targetExerciseId: 'cs-front-lever',
            currentExerciseId: 'exercice-imaginaire',
          ),
        ],
      );
      expect(unknownStep.validate(), isEmpty);
      expect(codesOf(catalog.checkProfile(unknownStep)), <String>[
        'unknown_exercise',
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
      expect(located(catalog.checkProfile(unknownMuscle)), <String>[
        r'$.specialization.muscle unknown_muscle',
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
    SeasonEvent event(String id, {List<String>? goalIds}) {
      return SeasonEvent(
        id: id,
        kind: EventKind.personalTest,
        priority: EventPriority.secondary,
        date: CivilDate(2027, 1, 10),
        goalIds: goalIds,
      );
    }

    test('identifiants et cibles sans doublon', () {
      final base = baseProfile();
      expect(
        base.copyWith(events: <SeasonEvent>[event('a'), event('b')]).validate(),
        isEmpty,
      );
      final sameEvents = base.copyWith(
        events: <SeasonEvent>[event('a'), event('a')],
      );
      expect(codesOf(sameEvents.validate()), <String>['duplicate']);
      expect(located(sameEvents.validate()), <String>[r'$.events duplicate']);
      const skill = SkillState(
        targetExerciseId: 'cs-front-lever',
        currentExerciseId: 'cs-front-lever-tuck',
      );
      final sameSkills = base.copyWith(
        skills: const <SkillState>[skill, skill],
      );
      expect(codesOf(sameSkills.validate()), <String>['duplicate']);
      expect(located(sameSkills.validate()), <String>[r'$.skills duplicate']);
      // Deux figures visées distinctes peuvent en être à la même étape ;
      // une figure visée ne se déclare qu'une fois.
      expect(
        base
            .copyWith(
              skills: <SkillState>[
                skill,
                skill.copyWith(targetExerciseId: 'cs-planche'),
              ],
            )
            .validate(),
        isEmpty,
      );
      expect(
        located(
          base
              .copyWith(
                skills: <SkillState>[
                  skill,
                  skill.copyWith(currentExerciseId: 'cs-front-lever-straddle'),
                ],
              )
              .validate(),
        ),
        <String>[r'$.skills duplicate'],
      );
      const weak = WeakPoint(
        exerciseId: 'sl-dips-leste',
        kind: WeakPointKind.bottom,
      );
      final sameWeakPoints = base.copyWith(
        weakPoints: const <WeakPoint>[weak, weak],
      );
      expect(codesOf(sameWeakPoints.validate()), <String>['duplicate']);
      expect(located(sameWeakPoints.validate()), <String>[
        r'$.weakPoints duplicate',
      ]);
      // Deux points faibles différents sur le même mouvement : acceptés.
      expect(
        base
            .copyWith(
              weakPoints: <WeakPoint>[
                weak,
                weak.copyWith(kind: WeakPointKind.lockout),
                weak.copyWith(exerciseId: 'sl-traction-lestee'),
              ],
            )
            .validate(),
        isEmpty,
      );
      expect(
        codesOf(
          base
              .copyWith(lifestyleUpdatedOn: CivilDate(2026, 9, 30))
              .validate(),
        ),
        <String>['date_before_creation'],
      );
    });

    test('récupération : jamais datée d\'avant la création du profil', () {
      final base = baseProfile();
      expect(base.createdOn, CivilDate(2026, 10, 1));
      final before = base.copyWith(lifestyleUpdatedOn: CivilDate(2026, 9, 30));
      expect(located(before.validate()), <String>[
        r'$.lifestyleUpdatedOn date_before_creation',
      ]);
      // Le jour de la création, ou plus tard : accepté.
      expect(
        base.copyWith(lifestyleUpdatedOn: CivilDate(2026, 10, 1)).validate(),
        isEmpty,
      );
      expect(
        base.copyWith(lifestyleUpdatedOn: CivilDate(2027, 3, 1)).validate(),
        isEmpty,
      );
    });

    test('échéance : ses objectifs sont des objectifs du profil', () {
      final base = baseProfile();
      expect(base.goals.map((g) => g.id), <String>['g1', 'g2']);
      expect(
        base
            .copyWith(
              events: <SeasonEvent>[
                event('a', goalIds: const <String>['g1', 'g2']),
                event('b', goalIds: const <String>[]),
                event('c'),
              ],
            )
            .validate(),
        isEmpty,
      );
      final unknown = base.copyWith(
        events: <SeasonEvent>[
          event('a', goalIds: const <String>['g1']),
          event('b', goalIds: const <String>['g2', 'g9']),
        ],
      );
      expect(codesOf(unknown.validate()), <String>['unknown_goal']);
      expect(located(unknown.validate()), <String>[
        r'$.events[1].goalIds unknown_goal',
      ]);
      expect(unknown.validate().single.message, 'g9');
      // Un profil sans objectif : toute référence est inconnue.
      final noGoals = base.copyWith(
        goals: const <Goal>[],
        events: <SeasonEvent>[
          event('a', goalIds: const <String>['g1', 'g2']),
        ],
      );
      expect(located(noGoals.validate()), <String>[
        r'$.events[0].goalIds unknown_goal',
        r'$.events[0].goalIds unknown_goal',
      ]);
      // Un objectif cité deux fois par la même échéance : doublon.
      final twice = base.copyWith(
        events: <SeasonEvent>[
          event('a', goalIds: const <String>['g1', 'g1']),
        ],
      );
      expect(located(twice.validate()), <String>[
        r'$.events[0].goalIds duplicate',
      ]);
      expect(
        located(event('a', goalIds: const <String>['g1', 'g1']).validate()),
        <String>[r'$.goalIds duplicate'],
      );
    });

    test('charge actuelle : un mouvement au plus une fois', () {
      final base = baseProfile();
      const pull = RecentTraining(
        exerciseId: 'sl-traction-lestee',
        sessionsPerWeek: 2,
        hardSets: HardSetsBand.sets10To14,
      );
      const dips = RecentTraining(
        exerciseId: 'sl-dips-leste',
        sessionsPerWeek: 0,
      );
      expect(pull.validate(), isEmpty);
      expect(dips.validate(), isEmpty);
      expect(dips.toJson().keys.toList(), <String>[
        'exerciseId',
        'sessionsPerWeek',
      ]);
      expect(
        base
            .copyWith(recentTraining: const <RecentTraining>[pull, dips])
            .validate(),
        isEmpty,
      );
      final twice = base.copyWith(
        recentTraining: <RecentTraining>[
          pull,
          dips,
          pull.copyWith(sessionsPerWeek: 3, hardSets: null),
        ],
      );
      expect(codesOf(twice.validate()), <String>['duplicate']);
      expect(located(twice.validate()), <String>[
        r'$.recentTraining duplicate',
      ]);
      // Bornes : de 0 à 14 séances par semaine, 12 mouvements au plus.
      expect(located(pull.copyWith(sessionsPerWeek: -1).validate()), <String>[
        r'$.sessionsPerWeek below_min',
      ]);
      expect(located(pull.copyWith(sessionsPerWeek: 15).validate()), <String>[
        r'$.sessionsPerWeek above_max',
      ]);
      expect(pull.copyWith(sessionsPerWeek: 14).validate(), isEmpty);
      final tooHigh = base.copyWith(
        recentTraining: <RecentTraining>[
          pull,
          dips.copyWith(sessionsPerWeek: 15),
        ],
      );
      expect(located(tooHigh.validate()), <String>[
        r'$.recentTraining[1].sessionsPerWeek above_max',
      ]);
      RecentTraining numbered(int i) {
        return RecentTraining(exerciseId: 'mouvement-$i', sessionsPerWeek: 1);
      }

      expect(
        base
            .copyWith(
              recentTraining: <RecentTraining>[
                for (var i = 0; i < 12; i++) numbered(i),
              ],
            )
            .validate(),
        isEmpty,
      );
      expect(
        located(
          base
              .copyWith(
                recentTraining: <RecentTraining>[
                  for (var i = 0; i < 13; i++) numbered(i),
                ],
              )
              .validate(),
        ),
        <String>[r'$.recentTraining too_long'],
      );
    });

    test('poids visé : seulement pour perdre ou prendre du poids', () {
      final base = baseProfile();
      for (final goal in <BodyWeightGoal>[
        BodyWeightGoal.lose,
        BodyWeightGoal.gain,
      ]) {
        final ok = base.copyWith(
          bodyWeightGoal: goal,
          targetBodyWeightKg: 60.0,
        );
        expect(ok.validate(), isEmpty, reason: goal.code);
        expect(
          AthleteProfile.fromJson(viaJsonText(ok.toJson())),
          ok,
          reason: goal.code,
        );
      }
      for (final goal in <BodyWeightGoal?>[
        BodyWeightGoal.maintain,
        BodyWeightGoal.noGoal,
        null,
      ]) {
        final reason = goal?.code ?? 'absent';
        final wrong = base.copyWith(
          bodyWeightGoal: goal,
          targetBodyWeightKg: 60.0,
        );
        expect(
          codesOf(wrong.validate()),
          <String>['unexpected_field'],
          reason: reason,
        );
        expect(
          located(wrong.validate()),
          <String>[r'$.targetBodyWeightKg unexpected_field'],
          reason: reason,
        );
        // Sans poids visé : tout but est accepté.
        expect(
          wrong.copyWith(targetBodyWeightKg: null).validate(),
          isEmpty,
          reason: reason,
        );
      }
      // Bornes du poids visé : celles du poids de corps (25 à 300 kg).
      final lose = base.copyWith(bodyWeightGoal: BodyWeightGoal.lose);
      expect(lose.copyWith(targetBodyWeightKg: 25.0).validate(), isEmpty);
      expect(lose.copyWith(targetBodyWeightKg: 300.0).validate(), isEmpty);
      expect(
        located(lose.copyWith(targetBodyWeightKg: 24.5).validate()),
        <String>[r'$.targetBodyWeightKg below_min'],
      );
      expect(
        located(lose.copyWith(targetBodyWeightKg: 300.5).validate()),
        <String>[r'$.targetBodyWeightKg above_max'],
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
      expect(codesOf(ok.copyWith(weekdays: const <int>[2, 2]).validate()), <
        String
      >['duplicate']);
      expect(codesOf(ok.copyWith(weekdays: const <int>[0]).validate()), <
        String
      >['below_min']);
      expect(codesOf(ok.copyWith(weekdays: const <int>[8]).validate()), <
        String
      >['above_max']);
      expect(codesOf(ok.copyWith(sessionsPerWeek: 0).validate()), <String>[
        'below_min',
      ]);
      expect(
        codesOf(
          ok.copyWith(
            regions: const <BodyRegion>[
              BodyRegion.lowerBody,
              BodyRegion.lowerBody,
            ],
          ).validate(),
        ),
        <String>['duplicate'],
      );
      // Chemins des violations.
      expect(
        located(ok.copyWith(weekdays: const <int>[2, 2]).validate()),
        <String>[r'$.weekdays duplicate'],
      );
      expect(
        located(ok.copyWith(weekdays: const <int>[3, 0, 8]).validate()),
        <String>[r'$.weekdays[1] below_min', r'$.weekdays[2] above_max'],
      );
      expect(
        located(
          ok.copyWith(
            regions: const <BodyRegion>[
              BodyRegion.lowerBody,
              BodyRegion.lowerBody,
            ],
          ).validate(),
        ),
        <String>[r'$.regions duplicate'],
      );
      // Cas acceptés : les sept jours, des régions distinctes, sport
      // principal (0.4.0).
      final full = ok.copyWith(
        weekdays: const <int>[1, 2, 3, 4, 5, 6, 7],
        regions: const <BodyRegion>[BodyRegion.lowerBody, BodyRegion.trunk],
        hard: true,
        mainSport: true,
      );
      expect(full.validate(), isEmpty);
      expect(OtherSport.fromJson(viaJsonText(full.toJson())), full);
      expect(full.toJson().keys.toList(), <String>[
        'kind',
        'sessionsPerWeek',
        'minutesPerSession',
        'weekdays',
        'regions',
        'hard',
        'mainSport',
      ]);
      // Dans un profil, le chemin désigne le sport fautif.
      final profile = baseProfile().copyWith(
        otherSports: <OtherSport>[
          ok,
          ok.copyWith(weekdays: const <int>[5, 5]),
        ],
      );
      expect(located(profile.validate()), <String>[
        r'$.otherSports[1].weekdays duplicate',
      ]);
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
          l.copyWith(
            aggravatedBy: const <AggravatingMovement>[
              AggravatingMovement.rings,
              AggravatingMovement.rings,
            ],
          ).validate(),
        ),
        <String>['duplicate'],
      );
      expect(
        located(
          l.copyWith(
            aggravatedBy: const <AggravatingMovement>[
              AggravatingMovement.rings,
              AggravatingMovement.rings,
            ],
          ).validate(),
        ),
        <String>[r'$.aggravatedBy duplicate'],
      );
      // Sans les champs 0.4.0, le JSON est celui de 0.3.0.
      expect(
        l.copyWith(since: null, aggravatedBy: null).toJson().keys.toList(),
        <String>['zone', 'side', 'joint', 'discomfort'],
      );
      // Les 14 familles de mouvements à la fois : accepté (14 au plus).
      expect(AggravatingMovement.values, hasLength(14));
      final all = l.copyWith(aggravatedBy: AggravatingMovement.values);
      expect(all.validate(), isEmpty);
      expect(Limitation.fromJson(viaJsonText(all.toJson())), all);
      final tooMany = l.copyWith(
        aggravatedBy: <AggravatingMovement>[
          ...AggravatingMovement.values,
          AggravatingMovement.rings,
        ],
      );
      expect(located(tooMany.validate()), <String>[
        r'$.aggravatedBy too_long',
        r'$.aggravatedBy duplicate',
      ]);
      // Les quatre familles ajoutées par la seconde passe.
      expect(
        l
            .copyWith(
              aggravatedBy: const <AggravatingMovement>[
                AggravatingMovement.deepShoulderExtension,
                AggravatingMovement.axialLoading,
                AggravatingMovement.elbowLockout,
                AggravatingMovement.explosivePull,
              ],
            )
            .toJson()['aggravatedBy'],
        <String>[
          'deep_shoulder_extension',
          'axial_loading',
          'elbow_lockout',
          'explosive_pull',
        ],
      );
    });

    test('gêne : gêne à l\'effort de 0 à 10', () {
      const l = Limitation(
        zone: BodyZone.elbow,
        side: BodySide.both,
        joint: Joint.elbow,
        discomfort: 0,
        effortDiscomfort: 6,
      );
      expect(l.validate(), isEmpty);
      expect(l.copyWith(effortDiscomfort: 0).validate(), isEmpty);
      expect(l.copyWith(effortDiscomfort: 10).validate(), isEmpty);
      expect(located(l.copyWith(effortDiscomfort: 11).validate()), <String>[
        r'$.effortDiscomfort above_max',
      ]);
      expect(located(l.copyWith(effortDiscomfort: -1).validate()), <String>[
        r'$.effortDiscomfort below_min',
      ]);
      expect(l.toJson().keys.toList(), <String>[
        'zone',
        'side',
        'joint',
        'discomfort',
        'effortDiscomfort',
      ]);
      expect(l.toJson()['effortDiscomfort'], 6);
      expect(Limitation.fromJson(viaJsonText(l.toJson())), l);
      final plain = l.copyWith(effortDiscomfort: null);
      expect(plain.toJson().keys.toList(), <String>[
        'zone',
        'side',
        'joint',
        'discomfort',
      ]);
      // Dans un profil : champ du schéma 3, chemin de la gêne fautive.
      final profile = baseProfile().copyWith(
        limitations: const <Limitation>[l],
      );
      expect(profile.validate(), isEmpty);
      expect(profile.schema3FieldsPresent, <String>['limitations']);
      expect(
        located(
          profile
              .copyWith(
                limitations: <Limitation>[l.copyWith(effortDiscomfort: 12)],
              )
              .validate(),
        ),
        <String>[r'$.limitations[0].effortDiscomfort above_max'],
      );
    });

    test('poste d\'épreuve : répétitions ou durée, pas les deux', () {
      const station = EventStation(exerciseId: 'sw-pompe', reps: 30);
      expect(station.validate(), isEmpty);
      // Maximum (ni répétitions ni durée imposées) : accepté.
      expect(station.copyWith(reps: null).validate(), isEmpty);
      // Maintien imposé seul : accepté.
      expect(station.copyWith(reps: null, seconds: 20).validate(), isEmpty);
      final both = station.copyWith(seconds: 20);
      expect(codesOf(both.validate()), <String>['measure_count']);
      expect(located(both.validate()), <String>[r'$ measure_count']);
      // Champs 0.4.0 : limite de temps et repos imposé du poste.
      final timed = station.copyWith(
        unbroken: true,
        timeLimitSeconds: 120,
        restAfterSeconds: 0,
      );
      expect(timed.validate(), isEmpty);
      expect(EventStation.fromJson(viaJsonText(timed.toJson())), timed);
      expect(
        located(station.copyWith(timeLimitSeconds: 0).validate()),
        <String>[r'$.timeLimitSeconds below_min'],
      );
      expect(
        located(station.copyWith(restAfterSeconds: 3601).validate()),
        <String>[r'$.restAfterSeconds above_max'],
      );
      // Dans une échéance, puis dans un profil : chemin du poste fautif.
      final competition = SeasonEvent(
        id: 'e1',
        kind: EventKind.repsCompetition,
        priority: EventPriority.main,
        date: CivilDate(2027, 5, 22),
        mode: RepsEventMode.forTime,
        stations: <EventStation>[station, both],
      );
      expect(located(competition.validate()), <String>[
        r'$.stations[1] measure_count',
      ]);
      final profile = baseProfile().copyWith(
        events: <SeasonEvent>[competition],
      );
      expect(located(profile.validate()), <String>[
        r'$.events[0].stations[1] measure_count',
      ]);
    });

    test('échéance : mouvements distincts, postes avec leur format', () {
      const pull = CompetitionLift(
        exerciseId: 'sl-traction-lestee',
        attempts: 3,
      );
      const dips = CompetitionLift(exerciseId: 'sl-dips-leste', attempts: 3);
      final strength = SeasonEvent(
        id: 'e1',
        kind: EventKind.strengthCompetition,
        priority: EventPriority.main,
        date: CivilDate(2027, 4, 17),
        lifts: const <CompetitionLift>[pull, dips],
      );
      expect(strength.validate(), isEmpty);
      final sameLifts = strength.copyWith(
        lifts: const <CompetitionLift>[pull, dips, pull],
      );
      expect(codesOf(sameLifts.validate()), <String>['duplicate']);
      expect(located(sameLifts.validate()), <String>[r'$.lifts duplicate']);
      expect(located(strength.copyWith(lifts: null).validate()), <String>[
        r'$.lifts missing_field',
      ]);
      // Champs de la seconde passe sur une compétition de force.
      final planned = strength.copyWith(
        dateApproximate: true,
        plannedBodyWeightKg: 72.8,
        heats: 2,
        restBetweenHeatsSeconds: 1800,
      );
      expect(planned.validate(), isEmpty);
      expect(SeasonEvent.fromJson(viaJsonText(planned.toJson())), planned);
      expect(
        located(strength.copyWith(plannedBodyWeightKg: 24.0).validate()),
        <String>[r'$.plannedBodyWeightKg below_min'],
      );
      expect(located(strength.copyWith(heats: 0).validate()), <String>[
        r'$.heats below_min',
      ]);

      // Compétition de répétitions : seul le format est exigé.
      const stations = <EventStation>[
        EventStation(exerciseId: 'sw-traction-pronation', reps: 30),
        EventStation(exerciseId: 'sw-pompe', reps: 30),
      ];
      final reps = SeasonEvent(
        id: 'e2',
        kind: EventKind.repsCompetition,
        priority: EventPriority.main,
        date: CivilDate(2027, 5, 22),
        mode: RepsEventMode.forTime,
      );
      expect(reps.validate(), isEmpty);
      // Format annoncé le jour même : pas de postes.
      expect(reps.copyWith(formatKnown: false).validate(), isEmpty);
      final withStations = reps.copyWith(
        stations: stations,
        rounds: 2,
        timeLimitSeconds: 600,
        bestSeconds: 512,
        bestDate: CivilDate(2026, 5, 23),
      );
      expect(withStations.validate(), isEmpty);
      expect(
        SeasonEvent.fromJson(viaJsonText(withStations.toJson())),
        withStations,
      );
      // Postes sans format : refusé.
      final noMode = withStations.copyWith(mode: null);
      expect(codesOf(noMode.validate()).toSet(), <String>{'missing_field'});
      expect(located(noMode.validate()).toSet(), <String>{
        r'$.mode missing_field',
      });
      expect(located(reps.copyWith(mode: null).validate()), <String>[
        r'$.mode missing_field',
      ]);
      // Un test personnel peut porter des postes, avec leur format.
      final personal = SeasonEvent(
        id: 'e3',
        kind: EventKind.personalTest,
        priority: EventPriority.secondary,
        date: CivilDate(2027, 2, 1),
        stations: stations,
      );
      expect(located(personal.validate()), <String>[r'$.mode missing_field']);
      expect(
        personal.copyWith(mode: RepsEventMode.maxRepsInTime).validate(),
        isEmpty,
      );
      // Des postes n'ont pas leur place dans une compétition de force.
      expect(
        located(
          strength
              .copyWith(stations: stations, mode: RepsEventMode.forTime)
              .validate(),
        ),
        <String>[r'$.mode unexpected_field', r'$.stations unexpected_field'],
      );

      // Objectifs servis : sans doublon.
      final sameGoals = strength.copyWith(
        goalIds: const <String>['g1', 'g2', 'g1'],
      );
      expect(located(sameGoals.validate()), <String>[r'$.goalIds duplicate']);
      expect(
        strength.copyWith(goalIds: const <String>['g1', 'g2']).validate(),
        isEmpty,
      );

      // Course : distance d'au moins 1 m.
      final race = SeasonEvent(
        id: 'e4',
        kind: EventKind.race,
        priority: EventPriority.main,
        date: CivilDate(2027, 3, 14),
        distanceMeters: 10000,
        targetSeconds: 2880,
        bestSeconds: 3210,
      );
      expect(race.validate(), isEmpty);
      expect(located(race.copyWith(distanceMeters: null).validate()), <String>[
        r'$.distanceMeters missing_field',
      ]);
      expect(located(race.copyWith(distanceMeters: 0.5).validate()), <String>[
        r'$.distanceMeters below_min',
      ]);
      expect(race.copyWith(distanceMeters: 1.0).validate(), isEmpty);
      expect(located(race.copyWith(heats: 2).validate()), <String>[
        r'$.heats unexpected_field',
      ]);

      // Freestyle : figures prévues.
      final freestyle = SeasonEvent(
        id: 'e5',
        kind: EventKind.freestyleCompetition,
        priority: EventPriority.preparation,
        date: CivilDate(2027, 6, 5),
        elements: const <String>['cs-front-lever', 'cs-planche'],
        formatKnown: true,
      );
      expect(freestyle.validate(), isEmpty);
      expect(
        located(
          strength.copyWith(elements: const <String>['cs-planche']).validate(),
        ),
        <String>[r'$.elements unexpected_field'],
      );
    });

    test('critère d\'étape : un maintien ou des répétitions', () {
      const hold = StepCriterion(holdSeconds: 10, sets: 3);
      expect(hold.validate(), isEmpty);
      const reps = StepCriterion(reps: 5, sets: 3, minQuality: 4, sessions: 2);
      expect(reps.validate(), isEmpty);
      expect(hold.copyWith(reps: 3).validate(), isEmpty);
      const none = StepCriterion(sets: 3, minWeeks: 4);
      expect(codesOf(none.validate()), <String>['no_measure']);
      expect(located(none.validate()), <String>[r'$ no_measure']);
      expect(located(hold.copyWith(holdSeconds: null).validate()), <String>[
        r'$ no_measure',
      ]);
      expect(located(hold.copyWith(sets: 0).validate()), <String>[
        r'$.sets below_min',
      ]);
    });

    test('échelle de figure : étapes distinctes, la figure en dernier', () {
      const criterion = StepCriterion(holdSeconds: 10, sets: 3);
      const tuck = SkillStep(
        exerciseId: 'cs-front-lever-tuck',
        criterion: criterion,
      );
      const straddle = SkillStep(
        exerciseId: 'cs-front-lever-straddle',
        criterion: criterion,
      );
      const target = SkillStep(
        exerciseId: 'cs-front-lever',
        criterion: criterion,
      );
      const ladder = SkillLadder(
        targetExerciseId: 'cs-front-lever',
        steps: <SkillStep>[tuck, straddle, target],
      );
      expect(ladder.validate(), isEmpty);
      expect(SkillLadder.fromJson(viaJsonText(ladder.toJson())), ladder);
      // La figure seule : accepté.
      expect(
        ladder.copyWith(steps: const <SkillStep>[target]).validate(),
        isEmpty,
      );
      // Une étape d'une autre famille : acceptée (aucun contrôle de
      // progression au catalogue).
      const other = SkillStep(
        exerciseId: 'cs-planche-tuck',
        criterion: criterion,
      );
      final mixed = ladder.copyWith(
        steps: const <SkillStep>[tuck, other, target],
      );
      expect(mixed.validate(), isEmpty);
      final twice = ladder.copyWith(
        steps: const <SkillStep>[tuck, tuck, target],
      );
      expect(codesOf(twice.validate()), <String>['duplicate']);
      expect(located(twice.validate()), <String>[r'$.steps duplicate']);
      final wrongEnd = ladder.copyWith(
        steps: const <SkillStep>[tuck, target, straddle],
      );
      expect(codesOf(wrongEnd.validate()), <String>['last_step_not_target']);
      expect(located(wrongEnd.validate()), <String>[
        r'$.steps last_step_not_target',
      ]);
      expect(wrongEnd.validate().single.message, 'cs-front-lever');
      final both = ladder.copyWith(steps: const <SkillStep>[tuck, tuck]);
      expect(located(both.validate()), <String>[
        r'$.steps duplicate',
        r'$.steps last_step_not_target',
      ]);
      // Aucune étape : seule la longueur est signalée.
      expect(
        located(ladder.copyWith(steps: const <SkillStep>[]).validate()),
        <String>[r'$.steps too_short'],
      );
      // Le critère d'une étape est contrôlé à son chemin.
      const empty = SkillStep(
        exerciseId: 'cs-front-lever-tuck',
        criterion: StepCriterion(sets: 2),
      );
      final unmeasured = ladder.copyWith(
        steps: const <SkillStep>[empty, target],
      );
      expect(located(unmeasured.validate()), <String>[
        r'$.steps[0].criterion no_measure',
      ]);
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
      expect(located(oneRm.copyWith(reps: null).validate()), <String>[
        r'$.reps missing_field',
      ]);
      expect(located(oneRm.copyWith(seconds: 10).validate()), <String>[
        r'$.seconds unexpected_field',
      ]);
      // La réserve est facultative ; au standard de compétition ou non.
      expect(oneRm.copyWith(rir: null).validate(), isEmpty);
      expect(oneRm.copyWith(rir: 1.5).validate(), isEmpty);
      expect(located(oneRm.copyWith(rir: 10.5).validate()), <String>[
        r'$.rir above_max',
      ]);
      final standard = oneRm.copyWith(competitionStandard: true);
      expect(standard.validate(), isEmpty);
      expect(standard.toJson()['competitionStandard'], isTrue);
      expect(Benchmark.fromJson(viaJsonText(standard.toJson())), standard);
      expect(oneRm.toJson().containsKey('competitionStandard'), isFalse);
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
      // Distance d'au moins 1 m.
      expect(located(run.copyWith(distanceMeters: 0.5).validate()), <String>[
        r'$.distanceMeters below_min',
      ]);
      expect(run.copyWith(distanceMeters: 1.0).validate(), isEmpty);
      expect(
        run.copyWith(kind: BenchmarkKind.distanceTrial).validate(),
        isEmpty,
      );
      // Répétitions max : lestées, ou en temps limité.
      const maxReps = Benchmark(
        exerciseId: 'sw-traction-pronation',
        kind: BenchmarkKind.maxReps,
        source: BenchmarkSource.declared,
        reps: 28,
      );
      expect(maxReps.validate(), isEmpty);
      expect(
        maxReps.copyWith(externalLoadKg: 10.0, seconds: 120).validate(),
        isEmpty,
      );
      expect(located(maxReps.copyWith(rir: 1.0).validate()), <String>[
        r'$.rir unexpected_field',
      ]);
      expect(located(maxReps.copyWith(reps: null).validate()), <String>[
        r'$.reps missing_field',
      ]);
      // Volume imposé au meilleur temps (0.4.0) : répétitions et temps.
      const forTime = Benchmark(
        exerciseId: 'sw-pompe',
        kind: BenchmarkKind.repsForTime,
        source: BenchmarkSource.declared,
        reps: 100,
        seconds: 300,
      );
      expect(forTime.validate(), isEmpty);
      expect(forTime.toJson()['kind'], 'reps_for_time');
      expect(forTime.copyWith(externalLoadKg: 10.0).validate(), isEmpty);
      expect(located(forTime.copyWith(seconds: null).validate()), <String>[
        r'$.seconds missing_field',
      ]);
      expect(located(forTime.copyWith(reps: null).validate()), <String>[
        r'$.reps missing_field',
      ]);
      expect(
        located(forTime.copyWith(distanceMeters: 400.0).validate()),
        <String>[r'$.distanceMeters unexpected_field'],
      );
      // Plusieurs records sur le même exercice et de même nature : acceptés
      // (l'unicité des records n'est plus un invariant du profil).
      final profile = baseProfile().copyWith(
        benchmarks: <Benchmark>[oneRm, oneRm, oneRm.copyWith(reps: 3)],
      );
      expect(profile.validate(), isEmpty);
    });

    test('volume de course : bornes', () {
      const running = EnduranceBase(
        weeklyVolume: RunVolumeBand.km20To35,
        sessionsPerWeek: 3,
        longRun: LongRunBand.min60To90,
      );
      expect(running.validate(), isEmpty);
      expect(EnduranceBase.fromJson(viaJsonText(running.toJson())), running);
      expect(running.toJson(), <String, Object?>{
        'weeklyVolume': 'km_20_to_35',
        'sessionsPerWeek': 3,
        'longRun': 'min_60_to_90',
      });
      final none = running.copyWith(sessionsPerWeek: 0, longRun: null);
      expect(none.validate(), isEmpty);
      expect(none.toJson().containsKey('longRun'), isFalse);
      final negative = running.copyWith(sessionsPerWeek: -1);
      expect(located(negative.validate()), <String>[
        r'$.sessionsPerWeek below_min',
      ]);
      final tooMany = running.copyWith(sessionsPerWeek: 15);
      expect(located(tooMany.validate()), <String>[
        r'$.sessionsPerWeek above_max',
      ]);
      final profile = baseProfile().copyWith(
        enduranceBase: running.copyWith(sessionsPerWeek: 15),
      );
      expect(located(profile.validate()), <String>[
        r'$.enduranceBase.sessionsPerWeek above_max',
      ]);
    });
  });
}
