import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

void main() {
  group('profil', () {
    test('le profil de référence est valide', () {
      expect(baseProfile().validate(), isEmpty);
    });

    test('bornes simples', () {
      final p = baseProfile();
      expect(
        codesOf(p.copyWith(birthYear: 1800).validate()),
        contains('below_min'),
      );
      expect(
        codesOf(p.copyWith(heightCm: 300).validate()),
        contains('above_max'),
      );
      expect(
        codesOf(p.copyWith(bodyWeightKg: 10.0).validate()),
        contains('below_min'),
      );
      expect(
        codesOf(p.copyWith(bodyWeightKg: double.nan).validate()),
        contains('not_finite'),
      );
      expect(
        codesOf(p.copyWith(displayName: 'x' * 41).validate()),
        contains('too_long'),
      );
      expect(
        codesOf(p.copyWith(availability: const <DaySlot>[]).validate()),
        contains('too_short'),
      );
      expect(
        codesOf(p.copyWith(places: const <Place>[]).validate()),
        contains('too_short'),
      );
      expect(p.copyWith(bodyWeightKg: null).validate(), isEmpty);
      expect(
        p.copyWith(bodyWeightKg: null).toJson().containsKey('bodyWeightKg'),
        isFalse,
      );
    });

    test('version de schéma : seule la version 2 est admise', () {
      final p = baseProfile();
      expect(p.schemaVersion, 2);
      expect(
        codesOf(p.copyWith(schemaVersion: 1).validate()),
        contains('below_min'),
      );
      expect(
        codesOf(p.copyWith(schemaVersion: 3).validate()),
        contains('above_max'),
      );
    });

    test(
      'dosage des disciplines : somme 100, distinctes, principale en tête',
      () {
        const sum = DisciplineMix(
          primary: TrainingDiscipline.musculation,
          primaryPct: 70,
          secondaries: <DisciplineShare>[
            DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 20),
          ],
        );
        expect(codesOf(sum.validate()), <String>['sum_not_100']);
        const duplicate = DisciplineMix(
          primary: TrainingDiscipline.musculation,
          primaryPct: 60,
          secondaries: <DisciplineShare>[
            DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 20),
            DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 20),
          ],
        );
        expect(codesOf(duplicate.validate()), <String>['duplicate']);
        const inverted = DisciplineMix(
          primary: TrainingDiscipline.musculation,
          primaryPct: 40,
          secondaries: <DisciplineShare>[
            DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 60),
          ],
        );
        expect(codesOf(inverted.validate()), <String>[
          'secondary_above_primary',
        ]);
        const three = DisciplineMix(
          primary: TrainingDiscipline.musculation,
          primaryPct: 40,
          secondaries: <DisciplineShare>[
            DisciplineShare(discipline: TrainingDiscipline.cardio, pct: 20),
            DisciplineShare(discipline: TrainingDiscipline.mobility, pct: 20),
            DisciplineShare(discipline: TrainingDiscipline.crossfit, pct: 20),
          ],
        );
        expect(codesOf(three.validate()), <String>['too_long']);
        const alone = DisciplineMix(
          primary: TrainingDiscipline.generalFitness,
          primaryPct: 100,
          secondaries: <DisciplineShare>[],
        );
        expect(alone.validate(), isEmpty);
        const equal = DisciplineMix(
          primary: TrainingDiscipline.cardio,
          primaryPct: 50,
          secondaries: <DisciplineShare>[
            DisciplineShare(
              discipline: TrainingDiscipline.musculation,
              pct: 50,
            ),
          ],
        );
        expect(equal.validate(), isEmpty);
      },
    );

    test(
      'mode street : somme 100, principale dominante, image des disciplines',
      () {
        const mode = StreetMode(
          primary: StreetStyle.streetlifting,
          streetliftingPct: 60,
          setsRepsPct: 25,
          calisthenicsPct: 15,
        );
        expect(mode.validate(), isEmpty);
        final mix = mode.toDisciplineMix();
        expect(mix.primary, TrainingDiscipline.streetlifting);
        expect(mix.primaryPct, 60);
        expect(mix.secondaries, const <DisciplineShare>[
          DisciplineShare(
            discipline: TrainingDiscipline.streetWorkout,
            pct: 25,
          ),
          DisciplineShare(discipline: TrainingDiscipline.calisthenics, pct: 15),
        ]);
        expect(mix.validate(), isEmpty);
        expect(codesOf(mode.copyWith(setsRepsPct: 30).validate()), <String>[
          'sum_not_100',
        ]);
        expect(
          codesOf(
            mode.copyWith(streetliftingPct: 20, setsRepsPct: 65).validate(),
          ),
          <String>['secondary_above_primary'],
        );
        const zero = StreetMode(
          primary: StreetStyle.calisthenics,
          streetliftingPct: 0,
          setsRepsPct: 40,
          calisthenicsPct: 60,
        );
        expect(zero.validate(), isEmpty);
        expect(zero.toDisciplineMix().secondaries, hasLength(1));
        final p = baseProfile();
        expect(codesOf(p.copyWith(streetMode: mode).validate()), <String>[
          'street_mode_mismatch',
        ]);
        expect(
          p.copyWith(streetMode: mode, disciplines: mix).validate(),
          isEmpty,
        );
      },
    );

    test('niveau déclaré : fourchette ou « je ne sais pas »', () {
      const level = MovementLevel(
        exerciseId: 'sw-pompe',
        measure: LevelMeasure.maxReps,
        known: true,
        low: 8,
        high: 12,
      );
      expect(level.validate(), isEmpty);
      expect(codesOf(level.copyWith(low: 15.0).validate()), <String>[
        'range_inverted',
      ]);
      expect(codesOf(level.copyWith(high: null).validate()), <String>[
        'range_missing',
      ]);
      expect(codesOf(level.copyWith(known: false).validate()), <String>[
        'value_on_unknown',
      ]);
      expect(
        level.copyWith(known: false, low: null, high: null).validate(),
        isEmpty,
      );
      expect(
        codesOf(level.copyWith(distanceMeters: 5000.0).validate()),
        <String>['distance_mismatch'],
      );
      expect(
        level
            .copyWith(measure: LevelMeasure.timeSeconds, distanceMeters: 5000.0)
            .validate(),
        isEmpty,
      );
    });

    test('objectif : champs selon la nature', () {
      final goals = baseProfile().goals;
      final performance = goals[0];
      final habit = goals[1];
      expect(performance.validate(), isEmpty);
      expect(habit.validate(), isEmpty);
      expect(
        codesOf(performance.copyWith(targetDate: null).validate()),
        <String>['missing_field'],
      );
      expect(codesOf(performance.copyWith(weeks: 4).validate()), <String>[
        'unexpected_field',
      ]);
      expect(
        codesOf(performance.copyWith(targetValue: null).validate()),
        <String>['missing_field'],
      );
      expect(
        performance
            .copyWith(metric: GoalMetric.skillUnlocked, targetValue: null)
            .validate(),
        isEmpty,
      );
      expect(
        codesOf(
          performance.copyWith(metric: GoalMetric.timeSeconds).validate(),
        ),
        <String>['missing_field'],
      );
      expect(
        codesOf(
          performance.copyWith(targetDate: CivilDate(2026, 9, 1)).validate(),
        ),
        <String>['date_before_creation'],
      );
      expect(
        codesOf(habit.copyWith(sessionsPerWeek: null).validate()),
        <String>['missing_field'],
      );
      expect(
        codesOf(habit.copyWith(exerciseId: 'sw-pompe').validate()),
        <String>['unexpected_field'],
      );
      expect(codesOf(habit.copyWith(sessionsPerWeek: 15).validate()), <String>[
        'above_max',
      ]);
    });

    test('invariants croisés du profil', () {
      final p = baseProfile();
      expect(
        codesOf(
          p
              .copyWith(
                availability: const <DaySlot>[
                  DaySlot(weekday: 1, minutes: 60),
                  DaySlot(weekday: 1, minutes: 30),
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
      expect(
        codesOf(
          p.copyWith(likedExerciseIds: const <String>['cf-burpee']).validate(),
        ),
        <String>['liked_and_disliked'],
      );
      expect(
        codesOf(p.copyWith(updatedOn: CivilDate(2026, 9, 30)).validate()),
        <String>['date_before_creation'],
      );
      expect(
        codesOf(
          p
              .copyWith(
                loadIncrements: const <LoadIncrement>[
                  LoadIncrement(loadType: LoadType.barbell, stepKg: 2.5),
                  LoadIncrement(loadType: LoadType.barbell, stepKg: 5),
                ],
              )
              .validate(),
        ),
        <String>['duplicate'],
      );
      expect(
        codesOf(
          p
              .copyWith(
                limitations: const <Limitation>[
                  Limitation(
                    zone: BodyZone.knee,
                    side: BodySide.left,
                    joint: Joint.shoulder,
                    discomfort: 3,
                  ),
                ],
              )
              .validate(),
        ),
        <String>['joint_zone_mismatch'],
      );
      expect(
        codesOf(
          p
              .copyWith(
                limitations: const <Limitation>[
                  Limitation(
                    zone: BodyZone.neck,
                    side: BodySide.both,
                    discomfort: 11,
                  ),
                ],
              )
              .validate(),
        ),
        <String>['above_max'],
      );
      expect(
        codesOf(p.copyWith(equipment: const <String>['']).validate()),
        <String>['too_short'],
      );
    });

    test('exercices cités par le profil', () {
      final ids = <String>{};
      baseProfile().collectExerciseIds(ids);
      expect(ids, <String>{
        'sw-pompe',
        'mu-back-squat-barre-haute',
        'mu-hip-thrust-barre',
        'cf-burpee',
      });
    });
  });

  group('journal', () {
    test('série : au moins une mesure', () {
      expect(baseSet.validate(), isEmpty);
      expect(codesOf(baseSet.copyWith(reps: null).validate()), <String>[
        'no_measure',
      ]);
      expect(baseSet.copyWith(reps: null, seconds: 30).validate(), isEmpty);
      expect(codesOf(baseSet.copyWith(reps: -1).validate()), <String>[
        'below_min',
      ]);
      expect(
        codesOf(
          baseSet
              .copyWith(target: const SetTarget(repsLow: 12, repsHigh: 8))
              .validate(),
        ),
        <String>['range_inverted'],
      );
    });

    test('journal : identifiants uniques, dates croissantes', () {
      final log = TrainingLog(
        sessions: <SessionRecord>[
          session('a', '2026-01-05'),
          session('b', '2026-01-05'),
          session('c', '2026-01-07'),
        ],
      );
      expect(log.validate(), isEmpty);
      expect(log.schemaVersion, 1);
      final duplicate = TrainingLog(
        sessions: <SessionRecord>[
          session('a', '2026-01-05'),
          session('a', '2026-01-06'),
        ],
      );
      expect(codesOf(duplicate.validate()), <String>['duplicate']);
      final unordered = TrainingLog(
        sessions: <SessionRecord>[
          session('a', '2026-01-06'),
          session('b', '2026-01-05'),
        ],
      );
      expect(codesOf(unordered.validate()), <String>['not_chronological']);
    });

    test('séances « reprise » : gardées au journal, ignorées des moteurs', () {
      final log = TrainingLog(
        sessions: <SessionRecord>[
          session('a', '2026-01-05', resume: true),
          session('b', '2026-01-06', resume: true),
          session('c', '2026-01-07'),
        ],
      );
      expect(log.validate(), isEmpty);
      expect(log.sessions, hasLength(3));
      expect(log.countedSessions.map((s) => s.id), <String>['c']);
      expect(TrainingLog.fromJson(viaJsonText(log.toJson())), log);
    });

    test('bilan santé : une réponse absente reste absente', () {
      const empty = HealthCheck();
      expect(empty.validate(), isEmpty);
      expect(empty.toJson(), isEmpty);
      // Douleurs : « question non posée » (absent) ≠ « aucune douleur » (vide).
      const noPain = HealthCheck(pains: <PainReport>[]);
      expect(noPain.toJson(), <String, Object?>{'pains': <Object?>[]});
      expect(noPain == empty, isFalse);
      expect(HealthCheck.fromJson(viaJsonText(noPain.toJson())).pains, isEmpty);
      expect(empty.pains, isNull);
      final back = HealthCheck.fromJson(viaJsonText(empty.toJson()));
      expect(back, empty);
      for (final value in <int?>[
        back.overall,
        back.sleepQuality,
        back.energy,
        back.mood,
        back.soreness,
        back.stress,
        back.motivation,
        back.nutrition,
        back.hydration,
        back.minutesAvailable,
      ]) {
        expect(value, isNull);
      }
      expect(back.sleepHours, isNull);
      expect(back.pains, isNull);
      const partial = HealthCheck(overall: 2, sleepHours: 5.5);
      expect(partial.toJson().keys, <String>['overall', 'sleepHours']);
      expect(codesOf(partial.copyWith(overall: 6).validate()), <String>[
        'above_max',
      ]);
      expect(codesOf(partial.copyWith(overall: 0).validate()), <String>[
        'below_min',
      ]);
    });
  });

  group('plan', () {
    test('verrous et actions de revue : champs selon la nature', () {
      const keep = PlanLock(
        kind: LockKind.keepSlot,
        slotId: 'd0s0',
        exerciseId: 'sw-pompe',
      );
      expect(keep.validate(), isEmpty);
      expect(codesOf(keep.copyWith(slotId: null).validate()), <String>[
        'missing_field',
      ]);
      expect(
        codesOf(const PlanLock(kind: LockKind.excludeExercise).validate()),
        <String>['missing_field'],
      );
      expect(
        const PlanLock(kind: LockKind.keepDay, dayIndex: 2).validate(),
        isEmpty,
      );
      expect(
        const ReviewAction(kind: ReviewKind.dislike, slotId: 'd0s0').validate(),
        isEmpty,
      );
      expect(
        codesOf(
          const ReviewAction(kind: ReviewKind.add, dayIndex: 0).validate(),
        ),
        <String>['missing_field'],
      );
      expect(
        codesOf(
          const ReviewAction(
            kind: ReviewKind.replace,
            slotId: 'd0s0',
          ).validate(),
        ),
        <String>['missing_field'],
      );
    });

    test('prescription : une seule famille de mesure, plages ordonnées', () {
      expect(basePrescription.validate(), isEmpty);
      expect(
        codesOf(basePrescription.copyWith(repsHigh: 6).validate()),
        <String>['range_inverted'],
      );
      expect(
        codesOf(basePrescription.copyWith(repsHigh: null).validate()),
        <String>['range_incomplete'],
      );
      expect(
        codesOf(
          basePrescription.copyWith(secondsLow: 20, secondsHigh: 30).validate(),
        ),
        <String>['measure_count'],
      );
      expect(
        codesOf(
          basePrescription.copyWith(repsLow: null, repsHigh: null).validate(),
        ),
        <String>['measure_count'],
      );
      expect(
        basePrescription
            .copyWith(
              repsLow: null,
              repsHigh: null,
              secondsLow: 20,
              secondsHigh: 30,
            )
            .validate(),
        isEmpty,
      );
      expect(
        codesOf(basePrescription.copyWith(targetFlames: 11).validate()),
        <String>['above_max'],
      );
      expect(
        codesOf(
          basePrescription
              .copyWith(loadBasis: LoadBasis.unloaded, startLoadKg: 10.0)
              .validate(),
        ),
        <String>['unexpected_field'],
      );
    });

    test('passe 1 : rangs des jours et emplacements uniques', () {
      final plan = basePass1();
      expect(plan.validate(), isEmpty);
      final shifted = plan.copyWith(
        days: <PlanDay>[plan.days[0].copyWith(dayIndex: 1)],
      );
      expect(codesOf(shifted.validate()), <String>['index_mismatch']);
      final twice = plan.copyWith(
        days: <PlanDay>[
          plan.days[0],
          plan.days[0].copyWith(dayIndex: 1, weekday: 3),
        ],
      );
      expect(codesOf(twice.validate()), <String>['duplicate']);
      // 4 à 6 semaines est la règle de kalis_plan ; le contrat admet de 1 à
      // 52 semaines pour un programme importé (celui du propriétaire).
      expect(plan.copyWith(weeks: 40).validate(), isEmpty);
      expect(codesOf(plan.copyWith(weeks: 53).validate()), <String>[
        'above_max',
      ]);
      expect(codesOf(plan.copyWith(weeks: 0).validate()), <String>[
        'below_min',
      ]);
    });

    test('bloc : passes 1 et 2 cohérentes', () {
      final block = ProgramBlock(pass1: basePass1(), pass2: basePass2());
      expect(block.validate(), isEmpty);
      expect(ProgramBlock.fromJson(viaJsonText(block.toJson())), block);
      expect(
        codesOf(
          block.copyWith(pass2: basePass2().copyWith(blockId: 'b1')).validate(),
        ),
        <String>['block_mismatch'],
      );
      final short = basePass2();
      expect(
        codesOf(
          block
              .copyWith(pass2: short.copyWith(weeks: short.weeks.sublist(0, 3)))
              .validate(),
        ),
        <String>['week_count'],
      );
      // La passe 2 fait foi : une semaine peut porter un autre exercice
      // pour un emplacement (échange en cours de bloc, semaine de test) ou un
      // emplacement propre à cette semaine.
      final weeks = basePass2().weeks;
      final swapped = basePass2().copyWith(
        weeks: <WeekPrescription>[
          weeks[0],
          weeks[1],
          weeks[2].copyWith(
            days: <DayPrescription>[
              DayPrescription(
                dayIndex: 0,
                items: <ExercisePrescription>[
                  basePrescription.copyWith(exerciseId: 'sw-pompe-diamant'),
                  basePrescription.copyWith(slotId: 'w2-test', kind: SetKind.test),
                ],
              ),
            ],
          ),
          weeks[3],
        ],
      );
      expect(block.copyWith(pass2: swapped).validate(), isEmpty);
      final twice = basePass2().copyWith(
        weeks: <WeekPrescription>[
          weeks[0].copyWith(
            days: const <DayPrescription>[
              DayPrescription(
                dayIndex: 0,
                items: <ExercisePrescription>[basePrescription, basePrescription],
              ),
            ],
          ),
          weeks[1],
          weeks[2],
          weeks[3],
        ],
      );
      expect(codesOf(block.copyWith(pass2: twice).validate()),
          <String>['duplicate']);
      final elsewhere = basePass2().copyWith(
        weeks: <WeekPrescription>[
          weeks[0].copyWith(
            days: const <DayPrescription>[
              DayPrescription(
                dayIndex: 3,
                items: <ExercisePrescription>[basePrescription],
              ),
            ],
          ),
          weeks[1],
          weeks[2],
          weeks[3],
        ],
      );
      expect(codesOf(block.copyWith(pass2: elsewhere).validate()),
          <String>['unknown_day']);
      final misnumbered = basePass2();
      expect(
        codesOf(
          misnumbered
              .copyWith(weeks: misnumbered.weeks.reversed.toList())
              .validate(),
        ).toSet(),
        <String>{'index_mismatch'},
      );
    });

    test('restructuration : la portée séance demande un jour', () {
      final request = RestructureRequest(
        profile: baseProfile(),
        seed: 1,
        today: CivilDate(2026, 10, 20),
        current: ProgramBlock(pass1: basePass1(), pass2: basePass2()),
        scope: RestructureScope.session,
        reasons: const <Reason>[],
        locks: const <PlanLock>[],
      );
      expect(codesOf(request.validate()), <String>['missing_field']);
      expect(request.copyWith(dayIndex: 0).validate(), isEmpty);
      expect(
        request.copyWith(scope: RestructureScope.block).validate(),
        isEmpty,
      );
    });
  });

  group('quest', () {
    test('registres en ajout seul : rangs et dates', () {
      final state = QuestState(
        xp: <XpEntry>[
          XpEntry(
            sequence: 0,
            date: CivilDate(2026, 1, 5),
            source: XpSource.effort,
            amount: 120,
            reasons: const <Reason>[],
          ),
          XpEntry(
            sequence: 1,
            date: CivilDate(2026, 1, 7),
            source: XpSource.record,
            amount: 50,
            reasons: const <Reason>[],
          ),
        ],
        kredits: const <KreditEntry>[],
        quests: const <Quest>[],
        data: const <String, Object?>{},
      );
      expect(state.validate(), isEmpty);
      final gap = state.copyWith(
        xp: <XpEntry>[state.xp[0], state.xp[1].copyWith(sequence: 5)],
      );
      expect(codesOf(gap.validate()), <String>['index_mismatch']);
      final backwards = state.copyWith(
        xp: <XpEntry>[
          state.xp[0],
          state.xp[1].copyWith(date: CivilDate(2026, 1, 1)),
        ],
      );
      expect(codesOf(backwards.validate()), <String>['not_chronological']);
      expect(codesOf(state.xp[0].copyWith(amount: -1).validate()), <String>[
        'below_min',
      ]);
    });

    test('prédiction : dates ordonnées ; niveau borné à 100', () {
      final prediction = Prediction(
        expectedOn: CivilDate(2027, 3, 1),
        earliestOn: CivilDate(2027, 2, 1),
        latestOn: CivilDate(2027, 5, 1),
        confidence: 0.6,
        method: 'linear_trend',
      );
      expect(prediction.validate(), isEmpty);
      expect(
        codesOf(
          prediction.copyWith(earliestOn: CivilDate(2027, 4, 1)).validate(),
        ),
        <String>['dates_not_ordered'],
      );
      const level = LevelState(
        level: 100,
        prestige: 2,
        totalXp: 1000000,
        xpIntoLevel: 0,
        xpForNextLevel: 0,
      );
      expect(level.validate(), isEmpty);
      expect(codesOf(level.copyWith(level: 101).validate()), <String>[
        'above_max',
      ]);
      expect(codesOf(level.copyWith(level: 0).validate()), <String>[
        'below_min',
      ]);
    });
  });

  group('ajouts de la relecture', () {
    test('cibles série par série : autant que de séries', () {
      const targets = <SetTarget>[
        SetTarget(repsLow: 5, repsHigh: 5, loadKg: 60, flames: 5),
        SetTarget(repsLow: 5, repsHigh: 5, loadKg: 70, flames: 7),
        SetTarget(repsLow: 3, repsHigh: 5, loadKg: 75, flames: 8),
      ];
      expect(basePrescription.copyWith(setTargets: targets).validate(), isEmpty);
      expect(
        codesOf(basePrescription
            .copyWith(setTargets: targets.sublist(0, 2))
            .validate()),
        <String>['set_count'],
      );
      expect(
        codesOf(const SetTarget(secondsLow: 40, secondsHigh: 20).validate()),
        <String>['range_inverted'],
      );
      expect(
        basePrescription
            .copyWith(targetFlames: null, restSeconds: null)
            .validate(),
        isEmpty,
      );
    });

    test('pauses déclarées, lieu par jour, matériel par lieu', () {
      final pause = TrainingBreak(
        startDate: CivilDate(2026, 2, 2),
        endDate: CivilDate(2026, 2, 13),
        reason: BreakReason.illness,
      );
      expect(pause.validate(), isEmpty);
      expect(pause.copyWith(endDate: null).validate(), isEmpty);
      expect(
        codesOf(pause.copyWith(endDate: CivilDate(2026, 2, 1)).validate()),
        <String>['dates_not_ordered'],
      );
      final p = baseProfile();
      final placed = p.copyWith(
        availability: const <DaySlot>[
          DaySlot(weekday: 1, minutes: 60, place: Place.gym),
        ],
        equipmentByPlace: const <PlaceEquipment>[
          PlaceEquipment(place: Place.gym, equipment: <String>['disques']),
        ],
      );
      expect(placed.validate(), isEmpty);
      expect(
        codesOf(placed.copyWith(
          availability: const <DaySlot>[
            DaySlot(weekday: 1, minutes: 60, place: Place.home),
          ],
        ).validate()),
        <String>['unknown_place'],
      );
      expect(
        codesOf(placed.copyWith(
          equipmentByPlace: const <PlaceEquipment>[
            PlaceEquipment(place: Place.gym, equipment: <String>['kettlebell']),
          ],
        ).validate()),
        <String>['not_in_equipment'],
      );
      expect(
        codesOf(p.copyWith(
          knownExerciseIds: const <String>['sw-pompe'],
          cannotDoExerciseIds: const <String>['sw-pompe'],
        ).validate()),
        <String>['known_and_cannot'],
      );
      expect(
        p
            .copyWith(
              knownExerciseIds: const <String>['sw-pompe'],
              cannotDoExerciseIds: const <String>['cs-planche'],
              experience: ExperienceLevel.intermediate,
            )
            .validate(),
        isEmpty,
      );
    });

    test('objectif : répétitions à une charge, distance en une durée', () {
      final goal = baseProfile().goals[0];
      expect(
        goal
            .copyWith(metric: GoalMetric.maxReps, targetValue: 38.0, loadKg: 70.0)
            .validate(),
        isEmpty,
      );
      expect(codesOf(goal.copyWith(loadKg: 70.0).validate()),
          <String>['unexpected_field']);
      expect(
        codesOf(goal.copyWith(metric: GoalMetric.distanceMeters).validate()),
        <String>['missing_field'],
      );
      expect(
        goal
            .copyWith(metric: GoalMetric.distanceMeters, durationSeconds: 720)
            .validate(),
        isEmpty,
      );
    });

    test('objets JSON libres : égalité sans ordre, écriture canonique', () {
      const a = Reason(
        code: ReasonCodes.adaptEstimateUpdated,
        params: <String, Object?>{
          'exerciseId': 'sw-pompe',
          'capacity': 31.5,
          'standardError': 2.0,
        },
      );
      const b = Reason(
        code: ReasonCodes.adaptEstimateUpdated,
        params: <String, Object?>{
          'standardError': 2.0,
          'capacity': 31.5,
          'exerciseId': 'sw-pompe',
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toJson().toString(), b.toJson().toString());
      expect((a.toJson()['params']! as Map<String, Object?>).keys,
          <String>['capacity', 'exerciseId', 'standardError']);
      // Un entier et un décimal ne s'écrivent pas pareil : ils ne sont pas égaux.
      final c = a.copyWith(
        params: <String, Object?>{...a.params, 'standardError': 2},
      );
      expect(a == c, isFalse);
      expect(jsonDeepEquals(2, 2.0), isFalse);
      expect(jsonDeepEquals(2.0, 2.0), isTrue);
      // Les exercices cités par une raison sont contrôlables.
      final ids = <String>{};
      a.collectExerciseIds(ids);
      expect(ids, <String>{'sw-pompe'});
    });
  });

  group('correspondances', () {
    test('discipline du profil → disciplines de la base', () {
      expect(
        TrainingDiscipline.calisthenics.catalogDisciplines,
        <CatalogDiscipline>[
          CatalogDiscipline.calisthenicsStatic,
          CatalogDiscipline.calisthenicsDynamic,
        ],
      );
      final covered = <CatalogDiscipline>{
        for (final d in TrainingDiscipline.values) ...d.catalogDisciplines,
      };
      expect(covered, CatalogDiscipline.values.toSet());
      for (final d in TrainingDiscipline.values) {
        expect(d.catalogDisciplines, isNotEmpty, reason: d.code);
      }
      expect(TrainingDiscipline.values, hasLength(8));
    });

    test('zone du corps → articulation suivie', () {
      final joints = <Joint>{
        for (final zone in BodyZone.values)
          if (zone.joint != null) zone.joint!,
      };
      expect(joints, Joint.values.toSet());
      expect(BodyZone.lowerBack.joint, Joint.lumbar);
      expect(BodyZone.neck.joint, isNull);
    });

    test('codes des enums : uniques, lecture par code', () {
      expect(Sex.fromCode('female'), Sex.female);
      expect(LoadType.fromCode('poids_du_corps'), LoadType.bodyweight);
      expect(Place.fromCode('exterieur'), Place.outdoor);
      expect(() => Sex.fromCode('autre'), throwsFormatException);
      expect(UnlockLevel.values.map((v) => v.code), <String>[
        'loads_reps',
        'volume',
        'exercise_swap',
        'session_restructure',
        'block_restructure',
      ]);
    });
  });
}
