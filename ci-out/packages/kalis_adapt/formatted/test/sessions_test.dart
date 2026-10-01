// Scénarios de journal, de bout en bout par le moteur : séries enchaînées
// (supersets), charge de référence, verrous après un échec, une douleur ou
// un bilan bas, exercices sans charge, journal prolongé, saisies douteuses.
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const p = AdaptParams.standard;
  final catalog = loadCatalog();

  /// Ce qu'il faut pour écrire des journaux sur le premier jour du premier
  /// bloc du profil type [key].
  ({
    AthleteProfile profile,
    ProgramBlock block,
    DayPrescription day,
    ExerciseBook book,
  })
  world(String key) {
    final profile = profileOf(key);
    final block = programOf(key).block(0);
    return (
      profile: profile,
      block: block,
      day: block.pass2.weeks.first.days.first,
      book: ExerciseBook(catalog, profile),
    );
  }

  /// Exercices du jour dont le mode de capacité est [mode] et qui portent
  /// une cible de difficulté.
  List<ExercisePrescription> itemsOf(
    ({
      AthleteProfile profile,
      ProgramBlock block,
      DayPrescription day,
      ExerciseBook book,
    })
    w,
    CapacityMode mode,
  ) {
    final seen = <String>{};
    return <ExercisePrescription>[
      for (final week in w.block.pass2.weeks)
        for (final day in week.days)
          if (day.dayIndex == w.day.dayIndex && week.weekIndex == 0)
            for (final item in day.items)
              if (item.targetFlames != null &&
                  w.book.find(item.exerciseId)?.mode == mode &&
                  seen.add(item.exerciseId))
                item,
    ];
  }

  SetRecord setOf(
    ExercisePrescription item,
    int order,
    int index, {
    double? kg,
    int? reps,
    int? flames,
    bool success = true,
    int aimed = 8,
    int aimedFlames = 7,
  }) => SetRecord(
    exerciseId: item.exerciseId,
    exerciseOrder: order,
    setIndex: index,
    kind: SetKind.work,
    externalLoadKg: kg,
    reps: reps,
    flames: flames,
    success: success,
    excluded: false,
    slotId: item.slotId,
    target: SetTarget(
      repsLow: aimed,
      repsHigh: aimed,
      loadKg: kg,
      flames: aimedFlames,
    ),
  );

  SessionRecord sessionOf(
    ProgramBlock block,
    DayPrescription day,
    String id,
    CivilDate date,
    List<SetRecord> sets,
  ) => SessionRecord(
    id: id,
    date: date,
    origin: SessionOrigin.program,
    programRef: ProgramRef(
      blockId: block.pass1.blockId,
      weekIndex: 0,
      dayIndex: day.dayIndex,
    ),
    resume: false,
    completed: true,
    sets: sets,
    pains: const <PainReport>[],
  );

  const gym = 'homme_25_musculation_debutant_3x60';

  group('séries enchaînées (supersets, tours)', () {
    final w = world(gym);
    final loaded = itemsOf(w, CapacityMode.loaded);
    final a = loaded[0];
    final b = loaded[1];
    final start = w.block.pass1.startDate;
    List<SetRecord> setsA() => <SetRecord>[
      for (var i = 0; i < 3; i++) setOf(a, 0, i, kg: 40, reps: 8, flames: 7),
    ];
    List<SetRecord> setsB() => <SetRecord>[
      for (var i = 0; i < 3; i++) setOf(b, 1, i, kg: 20, reps: 8, flames: 7),
    ];
    AdaptInput input(List<SetRecord> sets) => AdaptInput(
      profile: w.profile,
      block: w.block,
      log: TrainingLog(
        sessions: <SessionRecord>[sessionOf(w.block, w.day, 's1', start, sets)],
      ),
      today: start.addDays(2),
    );

    test('une séance enchaînée reste une séance par exercice', () {
      final sa = setsA();
      final sb = setsB();
      final mixed = <SetRecord>[
        for (var i = 0; i < 3; i++) ...<SetRecord>[sa[i], sb[i]],
      ];
      final (_, _, chained) = KalisAdapt().prepare(catalog, input(mixed));
      final (_, _, plain) = KalisAdapt().prepare(
        catalog,
        input(<SetRecord>[...sa, ...sb]),
      );
      for (final item in <ExercisePrescription>[a, b]) {
        final track = chained.state.tracks[item.exerciseId]!;
        final reference = plain.state.tracks[item.exerciseId]!;
        expect(track.filter.sessions, 1);
        expect(track.filter.sets, reference.filter.sets);
        expect(track.lastSets, 3);
        expect(track.lastLoad, reference.lastLoad);
        expect(
          track.filter.capacity / reference.filter.capacity,
          closeTo(1, 0.03),
        );
      }
      expect(chained.digests.single.entries.length, 2);
      expect(chained.digests.single.workSets, 6);
    });

    test('le conseil se souvient d\'un échec après un autre exercice', () {
      final engine = KalisAdapt();
      final none = <SessionRecord>[];
      final empty = AdaptInput(
        profile: w.profile,
        block: w.block,
        log: TrainingLog(sessions: none),
        today: start,
      );
      final session = engine.prescribeSession(
        catalog,
        SessionRequest(input: empty, weekIndex: 0, dayIndex: w.day.dayIndex),
      );
      final advice = engine.adviseNextSet(
        catalog,
        AdviceRequest(
          input: empty,
          session: session,
          done: <SetRecord>[
            setOf(a, 0, 0, kg: 40, reps: 3, flames: 10, success: false),
            setOf(b, 1, 0, kg: 20, reps: 8, flames: 7),
          ],
          slotId: a.slotId,
        ),
      );
      expect(advice.validate(), isEmpty);
      expect(advice.nextLoadKg, isNotNull);
      expect(advice.nextLoadKg, lessThanOrEqualTo(40));
      expect(advice.action, isNot(IntraSessionAction.loadUp));
      expect(
        advice.reasons.map((r) => r.code),
        contains(ReasonCodes.adaptSetFailed),
      );
    });
  });

  group('charge de référence', () {
    final w = world(gym);
    final a = itemsOf(w, CapacityMode.loaded).first;
    final start = w.block.pass1.startDate;
    ExerciseTrack trackAfter(List<SetRecord> sets) {
      final (_, _, replayed) = KalisAdapt().prepare(
        catalog,
        AdaptInput(
          profile: w.profile,
          block: w.block,
          log: TrainingLog(
            sessions: <SessionRecord>[
              sessionOf(w.block, w.day, 's1', start, sets),
            ],
          ),
          today: start.addDays(3),
        ),
      );
      return replayed.state.tracks[a.exerciseId]!;
    }

    test('pyramide : la plus lourde des séries tenues', () {
      final track = trackAfter(<SetRecord>[
        setOf(a, 0, 0, kg: 30, reps: 8, flames: 4),
        setOf(a, 0, 1, kg: 40, reps: 8, flames: 6),
        setOf(a, 0, 2, kg: 50, reps: 8, flames: 7),
      ]);
      expect(track.lastLoad, 50);
      expect(track.noUp, isFalse);
    });

    test('après un échec non prévu : jamais plus que la charge échouée', () {
      final sets = <SetRecord>[
        setOf(a, 0, 0, kg: 50, reps: 3, flames: 10, success: false),
        setOf(a, 0, 1, kg: 45, reps: 8, flames: 7),
        setOf(a, 0, 2, kg: 45, reps: 8, flames: 7),
      ];
      final track = trackAfter(sets);
      expect(track.lastLoad, 45);
      expect(track.noUp, isTrue);
      final input = AdaptInput(
        profile: w.profile,
        block: w.block,
        log: TrainingLog(
          sessions: <SessionRecord>[
            sessionOf(w.block, w.day, 's1', start, sets),
          ],
        ),
        today: start.addDays(3),
      );
      final session = KalisAdapt().prescribeSession(
        catalog,
        SessionRequest(input: input, weekIndex: 0, dayIndex: w.day.dayIndex),
      );
      for (final item in session.items) {
        if (item.exerciseId != a.exerciseId) {
          continue;
        }
        expect(item.startLoadKg, lessThanOrEqualTo(45));
        for (final t in item.setTargets ?? const <SetTarget>[]) {
          expect(t.loadKg, lessThanOrEqualTo(45));
        }
      }
      expect(
        checkSession(catalog, w.profile, w.block, input.log, session, p),
        isEmpty,
      );
    });

    test('zéro répétition à une charge légère : saisie douteuse', () {
      final regular = <SessionRecord>[
        for (var s = 0; s < 3; s++)
          sessionOf(w.block, w.day, 's$s', start.addDays(3 * s), <SetRecord>[
            for (var i = 0; i < 3; i++)
              setOf(a, 0, i, kg: 50, reps: 8, flames: 7),
          ]),
      ];
      double capacityOf(List<SessionRecord> sessions) {
        final (_, _, replayed) = KalisAdapt().prepare(
          catalog,
          AdaptInput(
            profile: w.profile,
            block: w.block,
            log: TrainingLog(sessions: sessions),
            today: start.addDays(12),
          ),
        );
        return replayed.state.tracks[a.exerciseId]!.filter.capacity;
      }

      final before = capacityOf(regular);
      final after = capacityOf(<SessionRecord>[
        ...regular,
        sessionOf(w.block, w.day, 'faute', start.addDays(9), <SetRecord>[
          setOf(a, 0, 0, kg: 10, reps: 0, success: false),
        ]),
      ]);
      expect(after, lessThanOrEqualTo(before * 1.02));
      expect(after, greaterThan(before * 0.85));
    });
  });

  group('exercices sans charge', () {
    const park = 'femme_30_street_workout_parc_3x45';
    final w = world(park);
    final start = w.block.pass1.startDate;

    test('après un échec non prévu : jamais plus que la dernière séance', () {
      final items = itemsOf(w, CapacityMode.reps);
      expect(items, isNotEmpty);
      final r = items.first;
      final sets = <SetRecord>[
        setOf(r, 0, 0, reps: 6, flames: 2, aimed: 6),
        setOf(r, 0, 1, reps: 6, flames: 2, aimed: 6),
        setOf(r, 0, 2, reps: 4, flames: 10, success: false, aimed: 6),
      ];
      final input = AdaptInput(
        profile: w.profile,
        block: w.block,
        log: TrainingLog(
          sessions: <SessionRecord>[
            sessionOf(w.block, w.day, 's1', start, sets),
          ],
        ),
        today: start.addDays(3),
      );
      final session = KalisAdapt().prescribeSession(
        catalog,
        SessionRequest(input: input, weekIndex: 0, dayIndex: w.day.dayIndex),
      );
      var checked = 0;
      for (final item in session.items) {
        if (item.exerciseId != r.exerciseId || item.kind == SetKind.test) {
          continue;
        }
        for (final t in item.setTargets ?? const <SetTarget>[]) {
          expect(t.repsHigh, lessThanOrEqualTo(6));
          checked++;
        }
      }
      expect(checked, greaterThan(0));
      expect(
        checkSession(catalog, w.profile, w.block, input.log, session, p),
        isEmpty,
      );
    });
  });

  group('bilan du jour non redonné au conseil', () {
    final w = world(gym);
    final a = itemsOf(w, CapacityMode.loaded).first;
    final start = w.block.pass1.startDate;
    final input = AdaptInput(
      profile: w.profile,
      block: w.block,
      log: TrainingLog(
        sessions: <SessionRecord>[
          for (var s = 0; s < 4; s++)
            sessionOf(w.block, w.day, 's$s', start.addDays(3 * s), <SetRecord>[
              for (var i = 0; i < 3; i++)
                setOf(a, 0, i, kg: 40, reps: 8, flames: 7),
            ]),
        ],
      ),
      today: start.addDays(12),
    );

    test('le verrou « bilan bas » est relu dans la séance', () {
      final engine = KalisAdapt();
      const check = HealthCheck(overall: 1);
      final session = engine.prescribeSession(
        catalog,
        SessionRequest(
          input: input,
          weekIndex: 0,
          dayIndex: w.day.dayIndex,
          healthCheck: check,
        ),
      );
      expect(
        session.reasons.where(
          (r) =>
              r.code == ReasonCodes.adaptLoadHeld &&
              r.params['cause'] == 'health_strong',
        ),
        hasLength(1),
      );
      final item = session.items.firstWhere(
        (i) => i.exerciseId == a.exerciseId,
      );
      final kg = item.startLoadKg!;
      expect(kg, lessThanOrEqualTo(40));
      final shown = item.setTargets!.first;
      final done = <SetRecord>[
        SetRecord(
          exerciseId: item.exerciseId,
          exerciseOrder: 0,
          setIndex: 0,
          kind: SetKind.work,
          externalLoadKg: kg,
          reps: shown.repsHigh,
          flames: 1,
          success: true,
          excluded: false,
          slotId: item.slotId,
          target: shown,
        ),
      ];
      for (final given in <HealthCheck?>[check, null]) {
        final advice = engine.adviseNextSet(
          catalog,
          AdviceRequest(
            input: input,
            session: session,
            done: done,
            slotId: item.slotId,
            healthCheck: given,
          ),
        );
        expect(advice.validate(), isEmpty);
        expect(advice.nextLoadKg, lessThanOrEqualTo(kg));
        expect(advice.action, isNot(IntraSessionAction.loadUp));
      }
    });

    test('sans bilan bas, la même série très facile fait monter', () {
      final engine = KalisAdapt();
      final session = engine.prescribeSession(
        catalog,
        SessionRequest(input: input, weekIndex: 0, dayIndex: w.day.dayIndex),
      );
      expect(
        session.reasons.where((r) => r.code == ReasonCodes.adaptLoadHeld),
        isEmpty,
      );
      final item = session.items.firstWhere(
        (i) => i.exerciseId == a.exerciseId,
      );
      final kg = item.startLoadKg!;
      final shown = item.setTargets!.first;
      final advice = engine.adviseNextSet(
        catalog,
        AdviceRequest(
          input: input,
          session: session,
          done: <SetRecord>[
            SetRecord(
              exerciseId: item.exerciseId,
              exerciseOrder: 0,
              setIndex: 0,
              kind: SetKind.work,
              externalLoadKg: kg,
              reps: shown.repsHigh,
              flames: 1,
              success: true,
              excluded: false,
              slotId: item.slotId,
              target: shown,
            ),
          ],
          slotId: item.slotId,
        ),
      );
      expect(advice.nextLoadKg, greaterThan(kg));
    });
  });

  group('journal prolongé', () {
    final w = world(gym);
    final a = itemsOf(w, CapacityMode.loaded).first;
    final start = w.block.pass1.startDate;
    SessionRecord at(String id, int offset) => sessionOf(
      w.block,
      w.day,
      id,
      start.addDays(offset),
      <SetRecord>[setOf(a, 0, 0, kg: 40, reps: 8, flames: 7)],
    );

    test('une séance ajoutée avant la dernière est refusée, avec ou sans '
        'cache', () {
      final first = at('s1', 0);
      final second = at('s2', 4);
      final late = at('s3', 2);
      AdaptInput input(List<SessionRecord> sessions) => AdaptInput(
        profile: w.profile,
        block: w.block,
        log: TrainingLog(sessions: sessions),
        today: start.addDays(6),
      );
      final engine = KalisAdapt();
      engine.estimates(catalog, input(<SessionRecord>[first, second]));
      expect(
        () => engine.estimates(
          catalog,
          input(<SessionRecord>[first, second, late]),
        ),
        throwsArgumentError,
      );
      expect(
        () => KalisAdapt().estimates(
          catalog,
          input(<SessionRecord>[first, second, late]),
        ),
        throwsArgumentError,
      );
    });
  });

  group('pivot de la courbe', () {
    CapacityFilter filter() => CapacityFilter.fromOneRm(
      logOneRm: 4.6,
      sd: 0.08,
      v: 0.002,
      vSd: 0.004,
      k: 30,
      kLogSd: p.kLogSd,
      nRef: 12,
      day: 0,
    );

    test('déplacer le pivot conserve le 1RM et toute incertitude', () {
      final f = filter();
      final capacity = f.capacity;
      final sds = <double>[
        for (final n in <double>[1, 4, 8, 12, 20]) f.loadSd(n, withDay: false),
      ];
      final loads = <double>[
        for (final n in <double>[1, 4, 8, 12, 20]) f.logLoadFor(n),
      ];
      f.repivot(4);
      expect(f.nRef, 4);
      expect(f.capacity, closeTo(capacity, 1e-9));
      var i = 0;
      for (final n in <double>[1, 4, 8, 12, 20]) {
        expect(f.loadSd(n, withDay: false), closeTo(sds[i], 1e-9));
        expect(f.logLoadFor(n), closeTo(loads[i], 1e-9));
        i++;
      }
      // Au nouveau pivot, l'incertitude du niveau est celle de la charge
      // prévue à ce nombre de répétitions.
      expect(f.loadSd(4, withDay: false), closeTo(math.sqrt(f.cov[0]), 1e-9));
      // Aller-retour : l'état d'origine.
      final g = filter();
      f.repivot(12);
      for (var j = 0; j < 4; j++) {
        expect(f.m[j], closeTo(g.m[j], 1e-9));
      }
      for (var j = 0; j < 16; j++) {
        expect(f.cov[j], closeTo(g.cov[j], 1e-9));
      }
    });

    test('après un changement de plage, le niveau s\'apprend au nouveau '
        'pivot', () {
      final f = filter();
      for (var s = 0; s < 30; s++) {
        f.beginSession(3 * s, 0, p.daySd, p);
        for (var i = 0; i < 3; i++) {
          f.observeLoad(
            logLoad: f.logLoadFor(12),
            n: 12,
            nSd: 0.8,
            fatigue: 0,
            p: p,
          );
        }
        f.endSession();
      }
      expect(f.loadSd(12, withDay: false), lessThan(p.calibrationSd));
      f.repivot(4);
      final wide = f.loadSd(4, withDay: false);
      for (var s = 30; s < 34; s++) {
        f.beginSession(3 * s, 0, p.daySd, p);
        for (var i = 0; i < 3; i++) {
          f.observeLoad(
            logLoad: f.logLoadFor(4),
            n: 4,
            nSd: 0.8,
            fatigue: 0,
            p: p,
          );
        }
        f.endSession();
      }
      expect(f.loadSd(4, withDay: false), lessThan(wide));
      expect(f.loadSd(4, withDay: false), lessThan(p.calibrationSd));
    });
  });
}
