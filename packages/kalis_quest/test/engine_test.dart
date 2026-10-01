// Scénarios du moteur : XP d'effort rapporté au programme, plafonds,
// douleur, repos, registre en ajout seul, série de semaines, records,
// coffres, prestige, reprises.
import 'dart:convert';

import 'package:kalis_adapt/kalis_adapt.dart'
    show AdaptParams, EngineContext, ExerciseBook, recordsOf;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/report.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final profile = profileOf(scenarioProfile);
  final engine = KalisQuest();
  final tuesday = monday.addDays(1);
  final wednesday = monday.addDays(2);

  // Le registre démarre le lundi, avant toute séance ; puis le moteur est
  // appelé le jour [today] avec le journal [sessions].
  QuestOutcome first(List<SessionRecord> sessions, {CivilDate? today}) => run(
    engine,
    profile,
    sessions,
    run(engine, profile, const <SessionRecord>[], emptyState, monday).state,
    today ?? monday,
  );

  group('XP d\'effort', () {
    test('séance prévue faite en entier à la cible : 100 XP + combo', () {
      final o = first(<SessionRecord>[
        sessionOf('a', monday, benchSets(4), planned: 4),
      ]);
      final effort = effortOf(o.state, 'a');
      expect(effort.amount, 104);
      expect(effort.reasons.first.code, ReasonCodes.questXpEffort);
      expect(effort.reasons.first.params['sets'], 4);
      expect(effort.reasons.first.params['capped'], isFalse);
      expect(effort.reasons.last.code, ReasonCodes.questCombo);
      expect(o.level.level, greaterThan(1));
      expect(o.validate(), isEmpty);
      final grade = o.events.firstWhere(
        (e) => e.kind == DelightKind.sessionGrade,
      );
      expect(grade.grade, SessionGrade.s);
    });

    test('moitié du volume prévu : moitié de l\'XP', () {
      final o = first(<SessionRecord>[
        sessionOf('a', monday, benchSets(4), planned: 8),
      ]);
      expect(effortOf(o.state, 'a').amount, 50 + 4);
    });

    test('séance allégée par le bilan santé, faite en entier : complète', () {
      final light = first(<SessionRecord>[
        sessionOf(
          'a',
          monday,
          benchSets(3, flames: 5, target: 5),
          planned: 3,
          health: const HealthCheck(overall: 2),
        ),
      ]);
      expect(effortOf(light.state, 'a').amount, 100 + 3);
      final grade = light.events.firstWhere(
        (e) => e.kind == DelightKind.sessionGrade,
      );
      expect(grade.grade, SessionGrade.s);
    });

    test('des séries en plus du programme ne rapportent rien', () {
      final honest = first(<SessionRecord>[
        sessionOf('a', monday, benchSets(4), planned: 4),
      ]);
      final greedy = first(<SessionRecord>[
        sessionOf('a', monday, benchSets(12), planned: 4),
      ]);
      expect(
        effortOf(greedy.state, 'a').amount,
        effortOf(honest.state, 'a').amount,
      );
      expect(
        effortOf(greedy.state, 'a').reasons.first.params['capped'],
        isTrue,
      );
      expect(greedy.level.totalXp, honest.level.totalXp);
    });

    test('aller plus dur que la cible ne rapporte pas plus ; plus facile, '
        'un peu moins ; sans note, moins', () {
      int amount(int? flames) => effortOf(
        first(<SessionRecord>[
          sessionOf('a', monday, <SetRecord>[
            for (var i = 0; i < 4; i++)
              setOf(bench, i, load: 60, reps: 8, flames: flames, target: 7),
          ], planned: 4),
        ]).state,
        'a',
      ).amount;
      // Échec visé 7 : hors tolérance, donc pas de combo, mais pas plus d'XP
      // de base.
      expect(amount(10), 100);
      expect(amount(8), 104);
      expect(amount(6), 104);
      expect(amount(3), lessThan(100));
      expect(amount(3), greaterThanOrEqualTo(50));
      expect(amount(null), 70);
    });

    test('au-delà des séances prévues de la semaine : 0 XP, plafond tenu', () {
      final sessions = <SessionRecord>[
        for (var i = 0; i < 6; i++)
          sessionOf('s$i', monday.addDays(i), benchSets(4), planned: 4),
      ];
      final o = first(sessions, today: monday.addDays(6));
      var paid = 0;
      var sum = 0;
      for (final e in o.state.xp) {
        if (e.source == XpSource.effort) {
          sum += e.amount;
          if (e.amount > 0) {
            paid++;
          }
        }
      }
      expect(paid, 3);
      expect(sum, lessThanOrEqualTo(3 * 110));
      final extra = effortOf(o.state, 's3');
      expect(extra.amount, 0);
      expect(extra.reasons.single.code, ReasonCodes.questXpCapped);
      expect(extra.reasons.single.params['scope'], CapScope.week);
    });

    test(
      'une séance écourtée est payée pour ce qui est fait et ne prend la '
      'place d\'aucune séance prévue ; le plafond d\'XP de la semaine tient',
      () {
        final sessions = <SessionRecord>[
          sessionOf('short', monday, benchSets(2), planned: 10),
          sessionOf('c1', wednesday, benchSets(4), planned: 4),
          sessionOf('c2', monday.addDays(4), benchSets(4), planned: 4),
          sessionOf('c3', monday.addDays(5), benchSets(4), planned: 4),
        ];
        final o = first(sessions, today: monday.addDays(7));
        final short = effortOf(o.state, 'short');
        expect(short.amount, 20);
        expect(short.reasons.last.code, ReasonCodes.questXpCapped);
        expect(short.reasons.last.params['scope'], CapScope.partial);
        expect(effortOf(o.state, 'c1').amount, 104);
        expect(effortOf(o.state, 'c2').amount, 104);
        // 3 séances prévues × 110 XP : il reste 102 XP pour la troisième.
        final last = effortOf(o.state, 'c3');
        expect(last.amount, 102);
        expect(
          last.reasons.map((r) => r.params['scope']),
          contains(CapScope.weekXp),
        );
        final week =
            (o.state.data['weeks']! as List<Object?>).single! as List<Object?>;
        expect(week.sublist(1, 3), <int>[3, 3]);
        expect(week[5], WeekSummary.success);
      },
    );

    test('une séance déplacée dans une autre semaine après son règlement n\'y '
        'compte pas une seconde fois', () {
      final a = sessionOf('a', monday, benchSets(4), planned: 4);
      final settled = first(<SessionRecord>[a], today: tuesday);
      final moved = <SessionRecord>[
        sessionOf('a', monday.addDays(7), benchSets(4), planned: 4),
        sessionOf('b', monday.addDays(9), benchSets(4), planned: 4),
        sessionOf('c', monday.addDays(11), benchSets(4), planned: 4),
      ];
      final o = run(engine, profile, moved, settled.state, monday.addDays(14));
      expect(
        o.state.xp.where((e) => e.source == XpSource.effort),
        hasLength(3),
      );
      final weeks = o.state.data['weeks']! as List<Object?>;
      expect(
        <Object?>[for (final w in weeks) (w! as List<Object?>)[2]],
        <int>[1, 2],
      );
      final quest = o.state.quests.firstWhere(
        (q) => q.id == 'w:${monday.addDays(7).iso}:0',
      );
      expect(quest.progress, 2);
    });

    test(
      'une séance en cours aujourd\'hui n\'est réglée qu\'une fois finie',
      () {
        final open = first(<SessionRecord>[
          sessionOf('a', monday, benchSets(2), planned: 4, completed: false),
        ]);
        expect(
          open.state.xp.where((e) => e.source == XpSource.effort),
          isEmpty,
        );
        final done = run(
          engine,
          profile,
          <SessionRecord>[sessionOf('a', monday, benchSets(4), planned: 4)],
          open.state,
          monday,
        );
        expect(effortOf(done.state, 'a').amount, 104);
        // Laissée inachevée, elle est réglée le lendemain pour ce qui est fait.
        final later = run(
          engine,
          profile,
          <SessionRecord>[
            sessionOf('a', monday, benchSets(2), planned: 4, completed: false),
          ],
          open.state,
          tuesday,
        );
        expect(effortOf(later.state, 'a').amount, 50);
      },
    );
  });

  group('douleur', () {
    final book = ExerciseBook(catalog, profile);
    const p = AdaptParams.standard;
    // Un exercice que la règle de kalis_adapt écarte pour une douleur de
    // 5/10 à l'épaule, et un autre qu'elle garde.
    final excluded = catalog.exercises.firstWhere((e) {
      final info = book.find(e.id)!;
      return info.mode != null &&
          e.unit == MeasureUnit.repetitions &&
          info.excludedByPain(
            BodyZone.shoulder,
            5,
            hard: p.painHard,
            severe: p.painSevere,
          );
    }).id;
    const pain = HealthCheck(
      overall: 2,
      pains: <PainReport>[
        PainReport(
          zone: BodyZone.shoulder,
          side: BodySide.left,
          intensity: 5,
          phase: PainPhase.before,
        ),
      ],
    );

    test('le squat épargne l\'épaule douloureuse', () {
      expect(
        book
            .find(squat)!
            .excludedByPain(
              BodyZone.shoulder,
              5,
              hard: p.painHard,
              severe: p.painSevere,
            ),
        isFalse,
      );
    });

    test('séance faite malgré la douleur : aucune récompense', () {
      final o = first(<SessionRecord>[
        sessionOf(
          'a',
          monday,
          <SetRecord>[
            for (var i = 0; i < 4; i++)
              setOf(excluded, i, reps: 8, flames: 7, target: 7),
          ],
          planned: 4,
          health: pain,
        ),
      ]);
      final effort = effortOf(o.state, 'a');
      expect(effort.amount, 0);
      expect(effort.reasons.single.code, ReasonCodes.questNoRewardPain);
      expect(effort.reasons.single.params['zone'], 'shoulder');
      expect(effort.reasons.single.params['intensity'], 5);
      expect(o.level.totalXp, 0);
      expect(o.kreditBalance, 0);
      expect(o.events, isEmpty);
      for (final q in o.state.quests) {
        expect(q.status, isNot(QuestStatus.completed));
      }
    });

    test('la séance douloureuse ne nourrit ni objectif, ni rang, ni record '
        'payé ; le fait reste connu', () {
      final goal = Goal(
        id: 'g',
        kind: GoalKind.performance,
        origin: GoalOrigin.user,
        createdOn: monday,
        exerciseId: excluded,
        metric: GoalMetric.maxReps,
        loadKg: 40,
        targetValue: 30,
        targetDate: monday.addDays(84),
      );
      final withGoal = profile.copyWith(goals: <Goal>[goal]);
      final clean = sessionOf('a', monday, <SetRecord>[
        for (var i = 0; i < 4; i++)
          setOf(excluded, i, load: 40, reps: 5, flames: 9, target: 9),
      ], planned: 4);
      final painful = sessionOf(
        'b',
        wednesday,
        <SetRecord>[
          for (var i = 0; i < 4; i++)
            setOf(excluded, i, load: 40, reps: 8, flames: 9, target: 9),
        ],
        planned: 4,
        health: pain,
      );
      final start = run(
        engine,
        withGoal,
        const <SessionRecord>[],
        emptyState,
        monday,
      ).state;
      final a = run(engine, withGoal, <SessionRecord>[clean], start, monday);
      final without = run(
        engine,
        withGoal,
        <SessionRecord>[clean],
        a.state,
        wednesday,
      );
      final o = run(
        engine,
        withGoal,
        <SessionRecord>[clean, painful],
        a.state,
        wednesday,
      );
      expect(effortOf(o.state, 'b').amount, 0);
      expect(o.level.totalXp, without.level.totalXp);
      expect(o.kreditBalance, without.kreditBalance);
      expect(o.goals.single.current, without.goals.single.current);
      expect(o.goals.single.fraction, without.goals.single.fraction);
      expect(
        jsonEncode(<Object?>[for (final r in o.ranks) r.toJson()]),
        jsonEncode(<Object?>[for (final r in without.ranks) r.toJson()]),
      );
      expect(
        jsonEncode(<Object?>[for (final x in o.attributes) x.toJson()]),
        jsonEncode(<Object?>[for (final x in without.attributes) x.toJson()]),
      );
      // Le fait brut reste un record connu de l'athlète.
      expect(o.records!.any((r) => r.sessionId == 'b'), isTrue);
    });

    test('une semaine avec une séance douloureuse garde ses séances prévues : '
        'elle est en pause, pas réussie', () {
      final sessions = <SessionRecord>[
        sessionOf('a', monday, benchSets(4), planned: 4),
        sessionOf(
          'b',
          wednesday,
          <SetRecord>[
            for (var i = 0; i < 4; i++)
              setOf(excluded, i, reps: 8, flames: 7, target: 7),
          ],
          planned: 4,
          health: pain,
        ),
        sessionOf('c', monday.addDays(4), benchSets(4), planned: 4),
      ];
      final o = first(sessions, today: monday.addDays(7));
      final week =
          (o.state.data['weeks']! as List<Object?>).single! as List<Object?>;
      // 3 prévues, 2 comptées : ni réussie (il en faut 3 sur 3) ni manquée.
      expect(week.sublist(1, 3), <int>[3, 2]);
      expect(week[5], WeekSummary.paused);
      expect(o.weekStreak, 0);
      final entry = o.state.xp.singleWhere(
        (e) => e.source == XpSource.consistency,
      );
      expect(entry.amount, 67);
      expect(
        entry.reasons.map((r) => r.code),
        contains(ReasonCodes.questStreakPaused),
      );
    });

    test('la même douleur, zone épargnée : récompense entière', () {
      final o = first(<SessionRecord>[
        sessionOf(
          'a',
          monday,
          <SetRecord>[
            for (var i = 0; i < 4; i++)
              setOf(squat, i, load: 80, reps: 8, flames: 7, target: 7),
          ],
          planned: 4,
          health: pain,
        ),
      ]);
      expect(effortOf(o.state, 'a').amount, 104);
    });

    test('une douleur signalée pendant ou après la séance ne retire rien', () {
      final session =
          sessionOf('a', monday, <SetRecord>[
            for (var i = 0; i < 4; i++)
              setOf(excluded, i, reps: 8, flames: 7, target: 7),
          ], planned: 4).copyWith(
            pains: const <PainReport>[
              PainReport(
                zone: BodyZone.shoulder,
                side: BodySide.left,
                intensity: 6,
                phase: PainPhase.during,
              ),
            ],
          );
      expect(effortOf(first(<SessionRecord>[session]).state, 'a').amount, 104);
    });
  });

  group('repos et récupération', () {
    test('un jour de repos ne propose que de la récupération', () {
      final o = first(const <SessionRecord>[], today: tuesday);
      final daily = o.state.quests.where(
        (q) => q.kind == QuestKind.daily && q.startsOn == tuesday,
      );
      expect(daily, isNotEmpty);
      expect(daily.length, lessThanOrEqualTo(3));
      for (final q in daily) {
        expect(QuestTemplates.recovery, contains(q.template));
        expect(q.params['claimable'], isTrue);
      }
    });

    test('une quête de récupération se déclare ; une quête d\'entraînement '
        'ne se déclare pas', () {
      final rest = first(const <SessionRecord>[], today: tuesday);
      final id = 'd:${tuesday.iso}:0';
      final claimed = run(
        engine,
        profile,
        const <SessionRecord>[],
        rest.state,
        tuesday,
        claims: <QuestClaim>[QuestClaim(questId: id, date: tuesday)],
      );
      final quest = claimed.state.quests.firstWhere((q) => q.id == id);
      expect(quest.status, QuestStatus.completed);
      expect(xpOf(claimed.state, XpSource.quest), 5);
      expect(claimed.kreditBalance, greaterThanOrEqualTo(1));
      // Redonner la déclaration ne paie pas deux fois.
      final again = run(
        engine,
        profile,
        const <SessionRecord>[],
        claimed.state,
        tuesday,
        claims: <QuestClaim>[QuestClaim(questId: id, date: tuesday)],
      );
      expect(again.level.totalXp, claimed.level.totalXp);

      final training = first(const <SessionRecord>[]);
      final cheat = run(
        engine,
        profile,
        const <SessionRecord>[],
        training.state,
        monday,
        claims: <QuestClaim>[
          QuestClaim(questId: 'd:${monday.iso}:0', date: monday),
        ],
      );
      expect(cheat.level.totalXp, 0);
    });

    test('une courte séance de mobilité un jour de repos ne prend pas la '
        'place d\'une séance prévue', () {
      final mobility = catalog.exercises
          .firstWhere(
            (e) =>
                e.family == MovementFamily.mobilite &&
                e.unit == MeasureUnit.seconds,
          )
          .id;
      final sessions = <SessionRecord>[
        sessionOf('a', monday, benchSets(4), planned: 4),
        sessionOf('m', tuesday, <SetRecord>[setOf(mobility, 0, seconds: 400)]),
        sessionOf('b', wednesday, benchSets(4), planned: 4),
        sessionOf('c', monday.addDays(4), benchSets(4), planned: 4),
      ];
      final o = first(sessions, today: monday.addDays(7));
      expect(effortOf(o.state, 'm').amount, 0);
      expect(effortOf(o.state, 'c').amount, 104);
      final data = o.state.data;
      expect(data['streak'], 1);
      final week = (data['weeks']! as List<Object?>).single! as List<Object?>;
      // 3 prévues, 3 faites, 4 jours de repos prévus et gardés, réussie.
      expect(week.sublist(1), <int>[3, 3, 4, 4, 1]);
      expect(xpOf(o.state, XpSource.consistency), 100);
    });
  });

  group('registre en ajout seul', () {
    final sessions = <SessionRecord>[
      sessionOf('a', monday, benchSets(4), planned: 4),
      sessionOf('b', wednesday, benchSets(4, load: 62.5), planned: 4),
    ];

    test('une séance supprimée ne retire aucun XP', () {
      final before = first(sessions, today: wednesday);
      final after = run(
        engine,
        profile,
        <SessionRecord>[sessions.first],
        before.state,
        wednesday.addDays(1),
      );
      expect(after.level.totalXp, greaterThanOrEqualTo(before.level.totalXp));
      for (var i = 0; i < before.state.xp.length; i++) {
        expect(after.state.xp[i], before.state.xp[i]);
      }
      for (var i = 0; i < before.state.kredits.length; i++) {
        expect(after.state.kredits[i], before.state.kredits[i]);
      }
      expect(after.state.validate(), isEmpty);
    });

    test('même entrée, même sortie ; rappel sans effet', () {
      final a = first(sessions, today: wednesday);
      final b = first(sessions, today: wednesday);
      expect(outcomeText(a), outcomeText(b));
      final again = run(engine, profile, sessions, a.state, wednesday);
      expect(stateText(again.state), stateText(a.state));
      expect(again.events, isEmpty);
      expect(again.level, a.level);
    });

    test('export puis import de l\'état : suite identique', () {
      final a = first(sessions, today: wednesday);
      final next = <SessionRecord>[
        ...sessions,
        sessionOf('c', monday.addDays(4), benchSets(4, load: 65), planned: 4),
      ];
      final direct = run(engine, profile, next, a.state, monday.addDays(8));
      final imported = run(
        engine,
        profile,
        next,
        reimport(a.state),
        monday.addDays(8),
      );
      expect(outcomeText(imported), outcomeText(direct));
    });

    test('remise à zéro : l\'historique ne donne pas d\'XP, mais il compte '
        'pour les records et les rangs', () {
      final history = <SessionRecord>[
        for (var i = 0; i < 6; i++)
          sessionOf(
            'h$i',
            monday.addDays(-28 + 2 * i),
            benchSets(3, load: 100, reps: 5, flames: 9, target: 9),
            planned: 3,
          ),
      ];
      final o = run(engine, profile, history, emptyState, monday);
      expect(o.level.totalXp, 0);
      expect(o.state.xp, isEmpty);
      expect(o.events, isEmpty);
      expect(o.records, isNotEmpty);
      final rank = o.ranks.firstWhere((r) => r.exerciseId == bench);
      expect(
        rank.tier.index,
        greaterThanOrEqualTo(MovementRankTier.gold.index),
      );
      // Refaire la même performance ensuite n'est pas un record.
      final next = run(
        engine,
        profile,
        <SessionRecord>[
          ...history,
          sessionOf(
            'n',
            monday,
            benchSets(3, load: 100, reps: 5, flames: 9, target: 9),
            planned: 3,
          ),
        ],
        o.state,
        monday,
      );
      expect(xpOf(next.state, XpSource.record), 0);
      expect(next.events.where((e) => e.kind == DelightKind.record), isEmpty);
      expect(next.events.where((e) => e.kind == DelightKind.rankUp), isEmpty);
    });

    test(
      'bonus de départ : désactivé par défaut, plafonné s\'il est activé',
      () {
        final history = <SessionRecord>[
          for (var i = 0; i < 10; i++)
            sessionOf(
              'h$i',
              monday.addDays(-25 + 2 * i),
              benchSets(3),
              planned: 3,
            ),
        ];
        expect(first(history).level.totalXp, 0);
        final bonus = KalisQuest(
          params: const QuestParams(
            startBonusPerSession: 20,
            startBonusCap: 150,
          ),
        );
        final o = run(bonus, profile, history, emptyState, monday);
        expect(o.level.totalXp, 150);
        expect(
          o.state.xp.single.reasons.single.code,
          ReasonCodes.questStartBonus,
        );
        expect(o.validate(), isEmpty);
      },
    );

    test('les séances « reprise » ne changent rien', () {
      final plain = first(sessions, today: wednesday);
      final withResume = first(<SessionRecord>[
        sessionOf(
          'r0',
          monday.addDays(-3),
          benchSets(4, load: 200, reps: 3, flames: 10),
          resume: true,
        ),
        sessions[0],
        sessionOf('r1', tuesday, benchSets(9, load: 150), resume: true),
        sessions[1],
      ], today: wednesday);
      expect(outcomeText(withResume), outcomeText(plain));
    });
  });

  group('série de semaines', () {
    List<SessionRecord> week(int index, int count) => <SessionRecord>[
      for (var i = 0; i < count; i++)
        sessionOf(
          'w$index-$i',
          monday.addDays(7 * index + 2 * i),
          benchSets(4),
          planned: 4,
        ),
    ];

    test('3 sur 3 : réussie ; 2 sur 3 : non réussie, la série repart, la '
        'meilleure est gardée', () {
      final sessions = <SessionRecord>[
        ...week(0, 3),
        ...week(1, 3),
        ...week(2, 2),
      ];
      var o = first(const <SessionRecord>[]);
      final streaks = <int>[];
      for (var w = 1; w <= 3; w++) {
        o = run(engine, profile, sessions, o.state, monday.addDays(7 * w));
        streaks.add(o.weekStreak!);
      }
      expect(streaks, <int>[1, 2, 0]);
      expect(o.state.data['bestStreak'], 2);
      final extras = o.extras!;
      final streak = extras['streak']! as Map<String, Object?>;
      expect(streak['best'], 2);
      expect(streak['lastWeek'], 'incomplete');
      // Aucune écriture, aucun événement ne dit la semaine manquée.
      expect(o.events.where((e) => e.kind == DelightKind.weekStreak), isEmpty);
    });

    test('vacances déclarées : pause, la série ne bouge pas', () {
      final sessions = <SessionRecord>[...week(0, 3), ...week(2, 3)];
      final breaks = <TrainingBreak>[
        TrainingBreak(
          startDate: monday.addDays(7),
          endDate: monday.addDays(13),
          reason: BreakReason.vacation,
        ),
      ];
      final o = run(
        engine,
        profile,
        sessions,
        first(const <SessionRecord>[]).state,
        monday.addDays(21),
        breaks: breaks,
      );
      expect(o.weekStreak, 2);
      final weeks = o.state.data['weeks']! as List<Object?>;
      expect(
        <Object?>[for (final w in weeks) (w! as List<Object?>)[5]],
        <int>[WeekSummary.success, WeekSummary.paused, WeekSummary.success],
      );
      // Pendant la pause : une quête par jour, de récupération.
      final paused = run(
        engine,
        profile,
        week(0, 3),
        first(const <SessionRecord>[]).state,
        monday.addDays(9),
        breaks: breaks,
      );
      for (final q in paused.state.quests) {
        if (q.kind == QuestKind.daily && q.startsOn >= monday.addDays(7)) {
          expect(QuestTemplates.recovery, contains(q.template));
        }
      }
    });

    test('maladie : récupération passive seulement', () {
      final o = run(
        engine,
        profile,
        const <SessionRecord>[],
        emptyState,
        monday,
        breaks: <TrainingBreak>[
          TrainingBreak(startDate: monday, reason: BreakReason.illness),
        ],
      );
      final daily = o.state.quests.where((q) => q.kind == QuestKind.daily);
      expect(daily, hasLength(1));
      expect(QuestTemplates.passive, contains(daily.single.template));
      expect(o.state.quests.where((q) => q.kind != QuestKind.daily), isEmpty);
    });
  });

  group('records', () {
    test('un record paie, plafonné ; une première fois ne paie pas', () {
      final sessions = <SessionRecord>[
        sessionOf(
          'a',
          monday,
          benchSets(3, load: 60, reps: 5, flames: 9, target: 9),
          planned: 3,
        ),
        sessionOf(
          'b',
          wednesday,
          benchSets(3, load: 65, reps: 5, flames: 9, target: 9),
          planned: 3,
        ),
      ];
      final a = first(sessions.sublist(0, 1));
      expect(xpOf(a.state, XpSource.record), 0);
      expect(
        a.events.where((e) => e.kind == DelightKind.firstTime),
        hasLength(1),
      );
      expect(a.events.where((e) => e.kind == DelightKind.record), isEmpty);
      final b = run(engine, profile, sessions, a.state, wednesday);
      final event = b.events.singleWhere((e) => e.kind == DelightKind.record);
      expect(event.exerciseId, bench);
      expect(event.recordKind, RecordKind.oneRmKg);
      expect(event.value, greaterThan(event.previousValue!));
      expect(xpOf(b.state, XpSource.record), 30);
      expect(
        b.state.kredits.where((k) => k.source == KreditSource.record),
        hasLength(1),
      );
    });

    test('une série au-delà du volume prévu n\'établit pas de record payé', () {
      final a = first(<SessionRecord>[
        sessionOf(
          'a',
          monday,
          benchSets(3, load: 60, reps: 5, flames: 9, target: 9),
          planned: 3,
        ),
      ]);
      final b = run(
        engine,
        profile,
        <SessionRecord>[
          sessionOf(
            'a',
            monday,
            benchSets(3, load: 60, reps: 5, flames: 9, target: 9),
            planned: 3,
          ),
          sessionOf('b', wednesday, <SetRecord>[
            ...benchSets(3, load: 60, reps: 5, flames: 9, target: 9),
            setOf(bench, 3, load: 70, reps: 5, flames: 9, target: 9),
          ], planned: 3),
        ],
        a.state,
        wednesday,
      );
      expect(xpOf(b.state, XpSource.record), 0);
    });

    test('mêmes records que kalis_adapt sur les journaux types', () {
      for (final j in loadJournals()) {
        final p = profileOf(j.profileKey);
        final o = evaluateFixture(engine, catalog, p, j.log);
        final expected = recordsOf(
          EngineContext(
            catalog: catalog,
            profile: p,
            params: AdaptParams.standard,
          ),
          j.log,
        );
        final mine = <String, PersonalRecord>{
          for (final r in o.records!) '${r.exerciseId}|${r.kind.code}': r,
        };
        for (final r in expected) {
          final m = mine['${r.exerciseId}|${r.kind.code}'];
          expect(m, isNotNull, reason: '${j.key} ${r.exerciseId}');
          expect(m!.value, r.value, reason: '${j.key} ${r.exerciseId}');
          expect(m.date, r.date);
          expect(m.sessionId, r.sessionId);
        }
      }
    });
  });

  group('coffres', () {
    test('déterministes ; garantie après une série sans coffre ; plafond '
        'par semaine', () {
      final sessions = <SessionRecord>[
        for (var w = 0; w < 12; w++)
          for (final d in <int>[0, 2, 4])
            sessionOf(
              'c$w-$d',
              monday.addDays(7 * w + d),
              benchSets(4),
              planned: 4,
            ),
      ];
      final end = monday.addDays(7 * 12);
      QuestOutcome play(int seed) => run(
        engine,
        profile,
        sessions,
        first(const <SessionRecord>[]).state,
        end,
        seed: seed,
      );
      final a = play(11);
      final b = play(11);
      expect(stateText(a.state), stateText(b.state));
      final chests = a.state.kredits
          .where((k) => k.source == KreditSource.chest)
          .toList();
      expect(chests, isNotEmpty);
      for (final c in chests) {
        expect(QuestParams.standard.chestKredits, contains(c.amount));
      }
      // Au moins un coffre toutes les 8 séances + 1 semaine de plafond.
      expect(chests.length, greaterThanOrEqualTo(36 ~/ 11));
      final perWeek = <String, int>{};
      for (final c in chests) {
        final week = c.refId!.split('|')[1];
        perWeek.update(week, (n) => n + 1, ifAbsent: () => 1);
      }
      for (final n in perWeek.values) {
        expect(n, lessThanOrEqualTo(QuestParams.standard.chestWeekCap));
      }
      // Une autre graine tire d'autres coffres.
      expect(stateText(play(12).state), isNot(stateText(a.state)));
    });
  });

  group('niveaux et prestige', () {
    test(
      'Krédits à chaque niveau ; prestige quand le niveau 100 est franchi',
      () {
        final small = KalisQuest(params: const QuestParams(levelScale: 0.01));
        expect(small.curve.prestigeSpan, 500);
        final sessions = <SessionRecord>[
          for (var w = 0; w < 3; w++)
            for (final d in <int>[0, 2, 4])
              sessionOf(
                'p$w-$d',
                monday.addDays(7 * w + d),
                benchSets(4),
                planned: 4,
              ),
        ];
        var o = run(
          small,
          profile,
          const <SessionRecord>[],
          emptyState,
          monday,
        );
        var previous = LevelCurve.ordinal(o.level);
        for (var day = 0; day <= 21; day++) {
          o = run(small, profile, sessions, o.state, monday.addDays(day));
          final ordinal = LevelCurve.ordinal(o.level);
          expect(ordinal, greaterThanOrEqualTo(previous));
          expect(o.level.level, inInclusiveRange(1, 100));
          expect(o.validate(), isEmpty);
          previous = ordinal;
        }
        expect(o.level.prestige, greaterThanOrEqualTo(1));
        expect(o.level.totalXp, greaterThan(500));
        final levelUps = o.state.kredits.where(
          (k) => k.source == KreditSource.levelUp,
        );
        expect(levelUps.length, previous - 1);
        expect(
          levelUps.where((k) => k.refId == 'level|1|1').single.amount,
          QuestParams.standard.prestigeKredits,
        );
      },
    );
  });

  group('sorties', () {
    test('journaux types : sorties valides, exercices du catalogue, extras '
        'sérialisables', () {
      for (final j in loadJournals()) {
        final o = evaluateFixture(
          engine,
          catalog,
          profileOf(j.profileKey),
          j.log,
        );
        expect(o.validate(), isEmpty, reason: j.key);
        final ids = <String>{};
        o.collectExerciseIds(ids);
        expect(catalog.checkExerciseIds(ids), isEmpty, reason: j.key);
        expect(o.attributes, hasLength(6));
        expect(o.ranks, hasLength(Standards.movements.length));
        for (final a in o.attributes) {
          expect(a.value, inInclusiveRange(1, 100));
          expect(a.best, greaterThanOrEqualTo(a.value));
        }
        final extras = o.extras!;
        expect(extras['schema'], extrasSchema);
        for (final key in <String>[
          'startedOn',
          'streak',
          'recap',
          'comparisons',
          'ghost',
          'ranks',
          'rankOf',
          'grades',
          'goals',
          'level',
          'totals',
        ]) {
          expect(extras.containsKey(key), isTrue, reason: '${j.key} $key');
        }
        final text = jsonEncode(extras);
        expect(jsonEncode(jsonDecode(text)), text);
        expect(o.state.lastEvaluatedOn, isNotNull);
      }
    });

    test('aucun code culpabilisant ; tous les codes sont au registre', () {
      const forbidden = <String>[
        'fail',
        'miss',
        'lost',
        'broken',
        'lazy',
        'shame',
      ];
      for (final spec in reasonRegistry) {
        if (!spec.code.startsWith('quest.')) {
          continue;
        }
        for (final word in forbidden) {
          expect(spec.code.contains(word), isFalse, reason: spec.code);
        }
      }
      for (final j in loadJournals()) {
        final o = evaluateFixture(
          engine,
          catalog,
          profileOf(j.profileKey),
          j.log,
        );
        for (final code in reasonCodesOf(o)) {
          expect(code.startsWith('quest.'), isTrue, reason: code);
          expect(reasonSpecOf(code), isNotNull, reason: code);
        }
      }
    });
  });
}
