import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final profiles = readProfileFixtures(
    readJsonObject('test/fixtures/profiles.json'),
  );
  final journalsJson = readJsonObject('test/fixtures/journals.json.gz');
  final journals = readJournalFixtures(journalsJson);
  AthleteProfile profile(String key) =>
      profiles.firstWhere((p) => p.key == key).profile;

  group('profils types', () {
    test('40 profils, clés uniques, descriptions', () {
      expect(profiles, hasLength(40));
      expect(profiles.map((p) => p.key).toSet(), hasLength(40));
      for (final p in profiles) {
        expect(p.description, isNotEmpty, reason: p.key);
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(p.key), isTrue, reason: p.key);
      }
    });

    test('chaque profil est valide et ne cite que le catalogue', () {
      for (final p in profiles) {
        expect(p.profile.validate(), isEmpty, reason: p.key);
        expect(catalog.checkProfile(p.profile), isEmpty, reason: p.key);
        expect(p.profile.schemaVersion, 2, reason: p.key);
        expect(
          AthleteProfile.fromJson(viaJsonText(p.profile.toJson())),
          p.profile,
          reason: p.key,
        );
        // Aucun mineur dans les jeux de données (règle L13).
        expect(
          p.profile.createdOn.year - p.profile.birthYear,
          greaterThanOrEqualTo(18),
          reason: p.key,
        );
      }
    });

    test('les situations demandées par le lot sont couvertes', () {
      final all = <AthleteProfile>[for (final p in profiles) p.profile];
      final beginner = profile('debutant_forme_generale_maison_2x30');
      expect(beginner.disciplines.primary, TrainingDiscipline.generalFitness);
      expect(beginner.availability.map((d) => d.minutes), <int>[30, 30]);
      expect(beginner.places, <Place>[Place.home]);
      expect(beginner.equipment, <String>['tapis']);

      final woman = profile('femme_45_musculation_salle_4x60');
      expect(woman.sex, Sex.female);
      expect(woman.createdOn.year - woman.birthYear, 45);
      expect(woman.disciplines.primary, TrainingDiscipline.musculation);
      expect(woman.availability.map((d) => d.minutes), <int>[60, 60, 60, 60]);

      expect(
        profile('coureur_cardio_3x45').disciplines.primary,
        TrainingDiscipline.cardio,
      );
      final crossfit = profile('crossfit_5x60');
      expect(crossfit.disciplines.primary, TrainingDiscipline.crossfit);
      expect(crossfit.availability, hasLength(5));
      expect(
        profile('calisthenie_figures_4x75').disciplines.primary,
        TrainingDiscipline.calisthenics,
      );

      // Mode street : les trois principales.
      final street = <StreetStyle>{
        for (final p in all)
          if (p.streetMode != null) p.streetMode!.primary,
      };
      expect(street, StreetStyle.values.toSet());

      final shoulder = profile('blessure_epaule_musculation_3x60');
      expect(shoulder.limitations.single.zone, BodyZone.shoulder);
      expect(shoulder.limitations.single.joint, Joint.shoulder);

      final minimal = profile('minimal_1x20');
      expect(minimal.availability.single.minutes, 20);
      expect(minimal.bodyWeightKg, isNull);
      expect(
        profile('six_jours_musculation_avance_6x75').availability,
        hasLength(6),
      );
      final senior = profile('senior_65_forme_generale_3x40');
      expect(senior.createdOn.year - senior.birthYear, 65);
      expect(senior.healthScreening!.outcome, HealthScreeningOutcome.cautious);

      final owner = profile('proprietaire_streetlifting_avance');
      expect(owner.bodyWeightKg, 71.5);
      expect(owner.streetMode!.primary, StreetStyle.streetlifting);
      expect(owner.goals, hasLength(4));

      // Les 8 disciplines du profil apparaissent comme principale.
      expect(<TrainingDiscipline>{
        for (final p in all) p.disciplines.primary,
      }, TrainingDiscipline.values.toSet());
      expect(<Sex>{for (final p in all) p.sex}, Sex.values.toSet());
      expect(<GuidanceMode>{
        for (final p in all) p.guidanceMode,
      }, GuidanceMode.values.toSet());
      expect(<int>{
        for (final p in all) p.availability.length,
      }, containsAll(<int>[1, 2, 3, 4, 5, 6, 7]));
      expect(
        <int>{for (final p in all) p.disciplines.secondaries.length},
        <int>{0, 1, 2},
      );
      expect(<GoalKind>{
        for (final p in all)
          for (final g in p.goals) g.kind,
      }, GoalKind.values.toSet());
      expect(
        <GoalMetric>{
          for (final p in all)
            for (final g in p.goals)
              if (g.metric != null) g.metric!,
        },
        containsAll(<GoalMetric>[
          GoalMetric.oneRmKg,
          GoalMetric.maxReps,
          GoalMetric.maxHoldSeconds,
          GoalMetric.skillUnlocked,
          GoalMetric.timeSeconds,
        ]),
      );
      expect(all.where((p) => p.goals.isEmpty), isNotEmpty);
      expect(
        all.where((p) => p.movementLevels.any((m) => !m.known)),
        isNotEmpty,
      );
      expect(<HealthScreeningOutcome>{
        for (final p in all) p.healthScreening!.outcome,
      }, HealthScreeningOutcome.values.toSet());
    });
  });

  group('journaux synthétiques', () {
    test('12 journaux de 4 à 24 semaines, valides', () {
      expect(journals, hasLength(12));
      expect(journals.map((j) => j.key).toSet(), hasLength(12));
      expect(journals.map((j) => j.weeks).reduce((a, b) => a < b ? a : b), 4);
      expect(journals.map((j) => j.weeks).reduce((a, b) => a > b ? a : b), 24);
      final start = CivilDate.parse(journalsJson['startDate']! as String);
      for (final j in journals) {
        expect(
          profiles.any((p) => p.key == j.profileKey),
          isTrue,
          reason: j.key,
        );
        expect(j.log.validate(), isEmpty, reason: j.key);
        final ids = <String>{};
        j.log.collectExerciseIds(ids);
        expect(catalog.checkExerciseIds(ids), isEmpty, reason: j.key);
        expect(j.log.sessions, isNotEmpty, reason: j.key);
        expect(j.log.sessions.first.date >= start, isTrue, reason: j.key);
        expect(
          j.log.sessions.last.date < start.addDays(7 * j.weeks),
          isTrue,
          reason: j.key,
        );
        expect(
          TrainingLog.fromJson(viaJsonText(j.log.toJson())),
          j.log,
          reason: j.key,
        );
      }
    });

    test('les unités des séries suivent le catalogue', () {
      for (final j in journals) {
        for (final s in j.log.sessions) {
          for (final set in s.sets) {
            final e = catalog.exercise(set.exerciseId);
            if (e.unit == MeasureUnit.seconds) {
              expect(set.seconds, isNotNull, reason: '${j.key} ${e.id}');
            } else if (e.unit == MeasureUnit.repetitions) {
              expect(set.reps, isNotNull, reason: '${j.key} ${e.id}');
            }
            if (set.externalLoadKg != null) {
              expect(e.loadType, isNot(LoadType.none), reason: e.id);
            }
          }
        }
      }
    });

    test('vérité de la simulation fournie pour chaque journal', () {
      final list = (journalsJson['journals']! as List<Object?>)
          .cast<Map<String, Object?>>();
      for (final item in list) {
        final truth = item['truth']! as Map<String, Object?>;
        expect(truth, isNotEmpty, reason: '${item['key']}');
        for (final entry in truth.entries) {
          expect(catalog.contains(entry.key), isTrue, reason: entry.key);
          final value = entry.value! as Map<String, Object?>;
          expect(value['capacityStart']! as num, greaterThan(0));
          expect(value['weeklyGain']! as num, greaterThanOrEqualTo(0));
        }
      }
    });

    test('séances « reprise », séries sans note, bilans partiels', () {
      TrainingLog log(String key) =>
          journals.firstWhere((j) => j.key == key).log;
      final resume = log('j05_reprise');
      expect(resume.sessions.where((s) => s.resume), isNotEmpty);
      expect(
        resume.countedSessions.length,
        resume.sessions.where((s) => !s.resume).length,
      );
      expect(resume.countedSessions.length, lessThan(resume.sessions.length));
      expect(resume.countedSessions.every((s) => !s.resume), isTrue);

      final unrated = log('j10_sans_notes');
      final sets = <SetRecord>[for (final s in unrated.sessions) ...s.sets];
      expect(
        sets.where((s) => !s.isRated).length / sets.length,
        greaterThan(0.5),
      );

      final all = <SessionRecord>[for (final j in journals) ...j.log.sessions];
      expect(all.where((s) => s.healthCheck == null), isNotEmpty);
      final checks = <HealthCheck>[
        for (final s in all)
          if (s.healthCheck != null) s.healthCheck!,
      ];
      // Questions sans réponse : absentes, jamais remplacées.
      expect(checks.where((c) => c.overall == null), isNotEmpty);
      expect(checks.where((c) => c.sleepHours == null), isNotEmpty);
      expect(checks.where((c) => c.stress != null), isNotEmpty);
      expect(all.where((s) => s.pains.isNotEmpty), isNotEmpty);
      expect(
        <SetRecord>[for (final s in all) ...s.sets].where((s) => s.excluded),
        isNotEmpty,
      );
      expect(
        <SetRecord>[for (final s in all) ...s.sets].where((s) => !s.success),
        isNotEmpty,
      );
    });
  });

  group('champs optionnels utilisés par les jeux de données', () {
    test('lieu par jour, matériel par lieu, expérience, su / pas su', () {
      final runner = profile('coureur_cardio_3x45');
      expect(runner.equipmentByPlace, hasLength(2));
      expect(runner.availability.where((d) => d.place != null), hasLength(2));
      expect(runner.experience, ExperienceLevel.intermediate);
      final owner = profile('proprietaire_streetlifting_avance');
      expect(owner.knownExerciseIds, contains('cd-muscle-up-barre-strict'));
      expect(owner.cannotDoExerciseIds, <String>['cs-front-lever']);
      expect(profile('minimal_1x20').experience, isNull);
      expect(profile('minimal_1x20').knownExerciseIds, isNull);
    });

    test('pause déclarée dans le journal irrégulier', () {
      final log = journals.firstWhere((j) => j.key == 'j08_irregulier').log;
      final pause = log.breaks!.single;
      expect(pause.reason, BreakReason.illness);
      expect(pause.startDate.daysUntil(pause.endDate!), 11);
      expect(
        log.sessions.where(
          (s) => s.date >= pause.startDate && s.date <= pause.endDate!,
        ),
        isEmpty,
      );
      expect(journals.first.log.breaks, isNull);
    });

    test('douleurs du bilan : absentes quand la question n\'est pas posée', () {
      final checks = <HealthCheck>[
        for (final j in journals)
          for (final s in j.log.sessions)
            if (s.healthCheck != null) s.healthCheck!,
      ];
      expect(checks.where((c) => c.pains == null), isNotEmpty);
      expect(
        checks.where((c) => c.pains != null && c.pains!.isEmpty),
        isNotEmpty,
      );
      expect(
        checks.where((c) => c.pains != null && c.pains!.isNotEmpty),
        isNotEmpty,
      );
    });
  });

  group('programme du propriétaire (lecture seule)', () {
    final program = readJsonObject('test/fixtures/owner_program_v33.json.gz');

    test('40 semaines, marqué en lecture seule, source tracée', () {
      expect(program['readOnly'], isTrue);
      final weeks = program['weeks']! as List<Object?>;
      expect(weeks, hasLength(40));
      final source = program['source']! as Map<String, Object?>;
      expect(source['file'], 'assets/programme_v33.json.gz');
      expect(
        RegExp(r'^[0-9a-f]{64}$').hasMatch(source['sha256']! as String),
        isTrue,
      );
      expect(program['bodyWeightKg'], 71.5);
    });

    test('la correspondance indicative ne cite que le catalogue', () {
      final names = (program['exerciseNames']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(names.length, greaterThan(70));
      var mapped = 0;
      for (final n in names) {
        final id = n['catalogId'] as String?;
        if (id != null) {
          mapped++;
          expect(catalog.contains(id), isTrue, reason: id);
        }
      }
      expect(mapped / names.length, greaterThan(0.85));
    });
  });

  group('ancien journal et conversion', () {
    final legacy = readJsonObject('test/fixtures/legacy_journal.json');
    final before = legacy['before']! as Map<String, Object?>;
    final report = legacy['report']! as Map<String, Object?>;
    final after = TrainingLog.fromJson(
      legacy['after']! as Map<String, Object?>,
    );

    test('le journal converti est valide et ne cite que le catalogue', () {
      expect(after.validate(), isEmpty);
      final ids = <String>{};
      after.collectExerciseIds(ids);
      expect(catalog.checkExerciseIds(ids), isEmpty);
      expect(
        after.sessions.every((s) => s.origin == SessionOrigin.imported),
        isTrue,
      );
      expect(after.sessions.every((s) => !s.resume), isTrue);
    });

    test('le rapport de conversion compte tout ce qui est lu', () {
      final logs = before['logs']! as Map<String, Object?>;
      expect(report['sessionsRead'], logs.length);
      expect(report['sessionsConverted'], after.sessions.length);
      expect(
        report['sessionsRead'],
        (report['sessionsConverted']! as int) +
            (report['manualSessionsDropped']! as int) +
            (report['emptySessionsDropped']! as int),
      );
      var done = 0;
      var notDone = 0;
      for (final entry in logs.entries) {
        if (entry.key.startsWith('S0-')) {
          continue;
        }
        final session = entry.value! as Map<String, Object?>;
        for (final ex in (session['ex']! as Map<String, Object?>).values) {
          final sets = ((ex! as Map<String, Object?>)['sets']! as List<Object?>)
              .cast<Map<String, Object?>>();
          done += sets.where((s) => s['done'] == true).length;
          notDone += sets.where((s) => s['done'] != true).length;
        }
      }
      final converted = after.sessions.fold<int>(
        0,
        (n, s) => n + s.sets.length,
      );
      expect(report['setsConverted'], converted);
      expect(report['setsNotDone'], notDone);
      expect(
        done,
        converted +
            (report['setsUnmappedExercise']! as int) +
            (report['setsWithoutMeasure']! as int),
      );
      // Séance manuelle (D1.1) : supprimée, jamais convertie.
      expect(report['manualSessionsDropped'], 1);
      expect(after.sessions.any((s) => s.id.contains('S0-')), isFalse);
    });

    test(
      'difficulté : RIR de l\'ancien journal → flammes, absence conservée',
      () {
        final logs = before['logs']! as Map<String, Object?>;
        final expected = <int>[];
        var unrated = 0;
        for (final entry in logs.entries) {
          if (entry.key.startsWith('S0-')) {
            continue;
          }
          final session = entry.value! as Map<String, Object?>;
          final names = session['exerciseNames']! as Map<String, Object?>;
          final ex = session['ex']! as Map<String, Object?>;
          for (final key in ex.keys) {
            final unmapped = (report['unmappedExerciseNames']! as List<Object?>)
                .contains(names[key]);
            if (unmapped) {
              continue;
            }
            final sets =
                ((ex[key]! as Map<String, Object?>)['sets']! as List<Object?>)
                    .cast<Map<String, Object?>>();
            for (final s in sets.where((s) => s['done'] == true)) {
              if (double.tryParse(
                    (s['reps']! as String).replaceAll(',', '.'),
                  ) ==
                  null) {
                continue; // série sans mesure : écartée (règle C8)
              }
              final effort = s['effort'] as num?;
              final rir =
                  effort?.toDouble() ??
                  double.tryParse((s['rir']! as String).replaceAll(',', '.'));
              if (rir == null) {
                unrated++;
              } else {
                expected.add(Flames.fromRir(rir));
              }
            }
          }
        }
        final sets = <SetRecord>[for (final s in after.sessions) ...s.sets];
        final actual = <int>[
          for (final s in sets)
            if (s.flames != null) s.flames!,
        ];
        expect(actual..sort(), expected..sort());
        expect(sets.where((s) => !s.isRated).length, unrated);
        expect(unrated, greaterThan(0));
      },
    );

    test('bilan : forme /10 → 1 à 5, sommeil en heures, douleur par mouvement non convertie', () {
      final answers =
          (before['koach']! as Map<String, Object?>)['answers']!
              as Map<String, Object?>;
      expect(answers, isNotEmpty);
      final session = after.sessions.firstWhere((s) => s.id == 'legacy-S1-J2');
      expect(session.healthCheck!.overall, 4); // forme 7/10
      expect(session.healthCheck!.sleepHours, 6.5);
      expect(session.healthCheck!.pains, isNull);
      expect(report['painAnswersDropped'], greaterThanOrEqualTo(1));
      for (final s in after.sessions) {
        final legacyKey = s.id.substring('legacy-'.length);
        if (!answers.containsKey(legacyKey)) {
          expect(s.healthCheck, isNull, reason: s.id);
        }
      }
    });
  });
}
