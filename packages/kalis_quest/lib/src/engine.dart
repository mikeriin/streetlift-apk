/// `KalisQuest` : réalisation de `QuestEngine` (kalis_core).
library;

import 'package:kalis_core/kalis_core.dart';

import 'extras.dart';
import 'goals.dart';
import 'grade.dart';
import 'ledger.dart';
import 'level.dart';
import 'numeric.dart';
import 'params.dart';
import 'progress.dart';
import 'quests.dart';
import 'standards.dart';
import 'version.dart';
import 'world.dart';

/// Moteur de progression de Kalis Track (D7, D8, D3.8).
///
/// `evaluate` est une fonction pure de son entrée : aucune horloge, aucun
/// hasard hors de la graine, aucun état gardé d'un appel à l'autre. Les
/// registres rendus prolongent ceux reçus sans jamais en retirer ni en
/// modifier une écriture.
final class KalisQuest implements QuestEngine {
  /// Moteur de paramètres [params].
  KalisQuest({this.params = QuestParams.standard}) : curve = LevelCurve(params);

  /// Paramètres.
  final QuestParams params;

  /// Courbe des niveaux.
  final LevelCurve curve;

  @override
  String get engineVersion => kalisQuestVersion;

  @override
  QuestOutcome evaluate(Catalog catalog, QuestInput input) =>
      _Run(this, catalog, input).run();
}

final class _Run {
  _Run(this.engine, Catalog catalog, this.input)
    : w = World(catalog, input, engine.params),
      ledger = Ledger(input.state),
      book = QuestBook(input.state.quests),
      seed = input.seed ?? 0 {
    st = MachineState.read(input.state, w.today);
    master = QuestMaster(
      w: w,
      book: book,
      ledger: ledger,
      st: st,
      seed: seed,
      attributesAt: (asOf) =>
          computeAttributes(w, computeRanks(w, asOf), st, asOf),
    );
  }

  final KalisQuest engine;
  final QuestInput input;
  final World w;
  final Ledger ledger;
  final QuestBook book;
  final int seed;
  late final MachineState st;
  late final QuestMaster master;
  final List<DelightEvent> events = <DelightEvent>[];
  int _ordinal = 1;

  QuestParams get p => engine.params;

  static Reason _reason(String code, Map<String, Object?> params) =>
      Reason(code: code, params: params);

  QuestOutcome run() {
    final today = w.today;
    _ordinal = LevelCurve.ordinal(engine.curve.stateOf(ledger.totalXp));
    final wasFresh = st.fresh;
    if (wasFresh) {
      _startBonus();
    }
    // Séances ajoutées après la clôture de leur jour.
    for (final f in w.factsIn(st.startedOn, st.settledThrough).toList()) {
      if (ledger.statusOf(f.session.id) == SessionStatus.unsettled) {
        _settle(f, f.day);
      }
    }
    _levelUps(today);
    final goals = GoalKeeper(w);
    final goalResults = goals.evaluate();
    final claims = input.claims ?? const <QuestClaim>[];
    for (var d = st.settledThrough + 1; d <= today; d++) {
      master.ensure(d);
      for (final claim in claims) {
        if (claim.date.dayNumber == d) {
          _claim(claim, d);
        }
      }
      for (final f in w.factsIn(d, d).toList()) {
        if (ledger.statusOf(f.session.id) == SessionStatus.unsettled &&
            (f.session.completed || d < today)) {
          _settle(f, d);
        }
      }
      _updateQuests(d);
      for (final g in goalResults) {
        _payMilestones(g, d);
      }
      _levelUps(d);
      if (d < today) {
        _closeDay(d);
        _levelUps(d);
      }
    }
    if (st.settledThrough < today - 1) {
      st.settledThrough = today - 1;
    }

    final ranks = computeRanks(w, today);
    for (final r in ranks) {
      final tier = Standards.tierOf(r.points).index;
      final kept = st.rankBest[r.movement.id] ?? 0;
      if (tier > kept) {
        st.rankBest[r.movement.id] = tier;
        if (!wasFresh) {
          events.add(
            DelightEvent(
              kind: DelightKind.rankUp,
              date: input.today,
              exerciseId: r.movement.id,
              value: tier.toDouble(),
              previousValue: kept.toDouble(),
              reasons: <Reason>[
                _reason(ReasonCodes.questRankUp, <String, Object?>{
                  'exerciseId': r.movement.id,
                  'tier': MovementRankTier.values[tier].code,
                }),
              ],
            ),
          );
        }
      }
    }
    final values = computeAttributes(w, ranks, st, today);
    final attributes = <AttributeScore>[];
    for (var i = 0; i < AthleteAttribute.values.length; i++) {
      final attribute = AthleteAttribute.values[i];
      final old = st.attrBest[attribute.code] ?? 0;
      final best = values[i] > old ? values[i] : old;
      st.attrBest[attribute.code] = best;
      attributes.add(
        AttributeScore(attribute: attribute, value: values[i], best: best),
      );
    }

    st.fresh = false;
    book.prune(today - p.questRetentionDays);
    final level = engine.curve.stateOf(ledger.totalXp);
    final suggested = goals.suggest();
    final state = QuestState(
      xp: List<XpEntry>.unmodifiable(ledger.xp),
      kredits: List<KreditEntry>.unmodifiable(ledger.kredits),
      quests: List<Quest>.unmodifiable(book.all),
      lastEvaluatedOn: input.today,
      data: st.toJson(),
    );
    return QuestOutcome(
      state: state,
      level: level,
      attributes: attributes,
      ranks: ranksToContract(ranks, st),
      goals: <GoalProgress>[for (final g in goalResults) g.progress],
      events: events,
      kreditBalance: ledger.balance,
      weekStreak: st.streak,
      suggestedGoals: suggested.isEmpty ? null : suggested,
      records: w.personalRecords(),
      extras: buildExtras(
        w: w,
        ledger: ledger,
        st: st,
        curve: engine.curve,
        ranks: ranks,
        goals: goalResults,
      ),
    );
  }

  /// Bonus de départ (désactivé par défaut : décision du lot G11).
  void _startBonus() {
    if (p.startBonusCap <= 0 || p.startBonusPerSession <= 0) {
      return;
    }
    var sessions = 0;
    for (final f in w.factsIn(w.today - p.startBonusDays, w.today - 1)) {
      if (f.completion >= p.doneCompletion && f.painZone == null) {
        sessions++;
      }
    }
    final amount = sessions * p.startBonusPerSession;
    if (amount <= 0) {
      return;
    }
    ledger.addXp(
      day: w.today,
      source: XpSource.consistency,
      amount: amount > p.startBonusCap ? p.startBonusCap : amount,
      refId: 'start',
      reasons: <Reason>[
        _reason(ReasonCodes.questStartBonus, <String, Object?>{
          'sessions': sessions,
        }),
      ],
    );
  }

  void _claim(QuestClaim claim, int day) {
    final q = book.find(claim.questId);
    if (q == null ||
        q.status != QuestStatus.active ||
        q.params['claimable'] != true ||
        q.startsOn.dayNumber > day ||
        (q.endsOn?.dayNumber ?? day) < day) {
      return;
    }
    book.put(q.copyWith(progress: q.target));
  }

  /// Règle la séance [f] : XP d'effort (plafonné), records, note, combo,
  /// coffre, fantôme. Une séance n'est réglée qu'une fois : son écriture
  /// d'effort au registre en fait foi.
  void _settle(SessionFacts f, int day) {
    final id = f.session.id;
    final monday = mondayOf(f.day);
    final weekRef = Ledger.weekRef(monday);
    final date = CivilDate.fromDayNumber(f.day);
    final zone = f.painZone;
    if (zone != null) {
      ledger.addXp(
        day: day,
        source: XpSource.effort,
        amount: 0,
        sessionId: id,
        refId: weekRef,
        reasons: <Reason>[
          _reason(ReasonCodes.questNoRewardPain, <String, Object?>{
            'intensity': f.painIntensity,
            'zone': zone.code,
          }),
        ],
      );
      return;
    }
    if (!f.hard && f.session.programRef == null) {
      ledger.addXp(
        day: day,
        source: XpSource.effort,
        amount: 0,
        sessionId: id,
        refId: weekRef,
        reasons: <Reason>[
          _reason(ReasonCodes.questXpCapped, <String, Object?>{
            'cap': 0,
            'scope': CapScope.recovery,
          }),
        ],
      );
      return;
    }
    final cap = w.scheduledIn(monday, monday + 6, skipBreaks: false);
    if (ledger.paidSessionsIn(weekRef) >= cap) {
      ledger.addXp(
        day: day,
        source: XpSource.effort,
        amount: 0,
        sessionId: id,
        refId: weekRef,
        reasons: <Reason>[
          _reason(ReasonCodes.questXpCapped, <String, Object?>{
            'cap': cap,
            'scope': CapScope.week,
          }),
        ],
      );
      return;
    }
    final base = (p.sessionXp * f.completion * f.quality).round();
    final bonus = f.combo >= p.comboMin
        ? (f.combo < p.comboBonusCap ? f.combo : p.comboBonusCap)
        : 0;
    ledger.addXp(
      day: day,
      source: XpSource.effort,
      amount: base + bonus,
      sessionId: id,
      refId: weekRef,
      reasons: <Reason>[
        _reason(ReasonCodes.questXpEffort, <String, Object?>{
          'capped': f.workSets > f.planned,
          'sets': f.workSets < f.limit ? f.workSets : f.limit,
        }),
        if (bonus > 0)
          _reason(ReasonCodes.questCombo, <String, Object?>{
            'bonus': bonus,
            'length': f.combo,
          }),
      ],
    );
    st.sessions++;

    var recordXp = 0;
    var paidRecord = false;
    for (final r in f.records) {
      final previous = r.previous;
      if (previous == null) {
        continue;
      }
      events.add(
        DelightEvent(
          kind: DelightKind.record,
          date: date,
          sessionId: id,
          exerciseId: r.exerciseId,
          recordKind: r.kind,
          value: r.value,
          previousValue: previous,
          reasons: <Reason>[
            _reason(ReasonCodes.questXpRecord, <String, Object?>{
              'exerciseId': r.exerciseId,
              'recordKind': r.kind.code,
            }),
          ],
        ),
      );
      if (r.ordinal >= f.limit || r.gain < p.recordMinGain) {
        continue;
      }
      final pct = (p.recordXpPerPct * r.gain * 100).round();
      var xp = p.recordXpBase + pct;
      if (xp > p.recordXpMax) {
        xp = p.recordXpMax;
      }
      final room = p.recordXpSessionCap - recordXp;
      final granted = xp < room ? xp : room;
      if (granted <= 0) {
        continue;
      }
      final written = ledger.addXp(
        day: day,
        source: XpSource.record,
        amount: granted,
        sessionId: id,
        refId: r.key,
        reasons: <Reason>[
          _reason(ReasonCodes.questXpRecord, <String, Object?>{
            'exerciseId': r.exerciseId,
            'recordKind': r.kind.code,
          }),
          if (granted < xp)
            _reason(ReasonCodes.questXpCapped, <String, Object?>{
              'cap': p.recordXpSessionCap,
              'scope': CapScope.records,
            }),
        ],
      );
      if (written) {
        recordXp += granted;
        if (!paidRecord) {
          paidRecord = true;
          ledger.addKredits(
            day: day,
            source: KreditSource.record,
            amount: p.recordKredits,
            refId: r.key,
          );
        }
      }
    }
    var firsts = 0;
    for (final exerciseId in f.firsts) {
      if (firsts >= p.firstTimeEventsPerSession ||
          !w.catalog.contains(exerciseId)) {
        continue;
      }
      firsts++;
      events.add(
        DelightEvent(
          kind: DelightKind.firstTime,
          date: date,
          sessionId: id,
          exerciseId: exerciseId,
          reasons: <Reason>[
            _reason(ReasonCodes.questFirstTime, <String, Object?>{
              'exerciseId': exerciseId,
            }),
          ],
        ),
      );
    }
    if (f.completion < p.doneCompletion) {
      return;
    }
    final mark = markOf(f, p);
    events.add(
      DelightEvent(
        kind: DelightKind.sessionGrade,
        date: date,
        sessionId: id,
        grade: mark.grade,
        value: mark.score.toDouble(),
        reasons: <Reason>[
          _reason(ReasonCodes.questSessionGrade, <String, Object?>{
            'accuracy': roundTo(mark.accuracy, 3),
            'completion': roundTo(f.completion, 3),
            'records': mark.records,
          }),
        ],
      ),
    );
    if (bonus > 0) {
      events.add(
        DelightEvent(
          kind: DelightKind.combo,
          date: date,
          sessionId: id,
          combo: f.combo,
          reasons: <Reason>[
            _reason(ReasonCodes.questCombo, <String, Object?>{
              'bonus': bonus,
              'length': f.combo,
            }),
          ],
        ),
      );
    }
    _chest(f, day, monday);
    _ghost(f);
  }

  void _chest(SessionFacts f, int day, int monday) {
    final id = f.session.id;
    st.chestGap++;
    if (ledger.chestsIn(monday) >= p.chestWeekCap) {
      return;
    }
    final guaranteed = st.chestGap >= p.chestPity;
    if (!guaranteed && unitOf(seed, 'chest|$id') >= p.chestProbability) {
      return;
    }
    final u = unitOf(seed, 'chest-size|$id');
    var index = p.chestKredits.length - 1;
    var cumulated = 0.0;
    for (var i = 0; i < p.chestShares.length; i++) {
      cumulated += p.chestShares[i];
      if (u < cumulated) {
        index = i;
        break;
      }
    }
    final amount = p.chestKredits[index];
    final written = ledger.addKredits(
      day: day,
      source: KreditSource.chest,
      amount: amount,
      refId: 'chest|${CivilDate.fromDayNumber(monday).iso}|$id',
    );
    if (!written) {
      return;
    }
    st.chestGap = 0;
    st.chests++;
    events.add(
      DelightEvent(
        kind: DelightKind.chest,
        date: CivilDate.fromDayNumber(f.day),
        sessionId: id,
        kredits: amount,
        reasons: <Reason>[
          _reason(ReasonCodes.questChest, <String, Object?>{
            'guaranteed': guaranteed,
          }),
        ],
      ),
    );
  }

  /// Fantôme battu : l'exercice de la séance dont le score dépasse le plus
  /// celui de la dernière fois.
  void _ghost(SessionFacts f) {
    String? winner;
    var gain = 0.0;
    final ids = f.scoreByExercise.keys.toList()..sort();
    for (final id in ids) {
      final last = f.lastScore[id];
      final score = f.scoreByExercise[id]!;
      if (last == null || last <= 0 || !w.catalog.contains(id)) {
        continue;
      }
      final g = score / last - 1;
      if (g > gain + 1e-12) {
        gain = g;
        winner = id;
      }
    }
    if (winner == null) {
      return;
    }
    final score = f.scoreByExercise[winner]!;
    final best = f.bestScore[winner] ?? 0;
    events.add(
      DelightEvent(
        kind: DelightKind.ghost,
        date: CivilDate.fromDayNumber(f.day),
        sessionId: f.session.id,
        exerciseId: winner,
        value: roundTo(score, 1),
        previousValue: roundTo(f.lastScore[winner]!, 1),
        reasons: <Reason>[
          _reason(ReasonCodes.questGhostBeaten, <String, Object?>{
            'exerciseId': winner,
            'reference': score > best ? 'best' : 'last',
          }),
        ],
      ),
    );
  }

  void _updateQuests(int day) {
    for (final q in List<Quest>.of(book.all)) {
      if (q.status != QuestStatus.active || q.startsOn.dayNumber > day) {
        continue;
      }
      final progress = roundTo(master.progressOf(q, day), 3);
      if (progress >= q.target) {
        book.put(q.copyWith(progress: progress, status: QuestStatus.completed));
        final reasons = <Reason>[
          _reason(ReasonCodes.questXpQuest, <String, Object?>{'questId': q.id}),
        ];
        ledger.addXp(
          day: day,
          source: XpSource.quest,
          amount: q.rewardXp,
          refId: q.id,
          reasons: reasons,
        );
        ledger.addKredits(
          day: day,
          source: KreditSource.quest,
          amount: q.rewardKredits,
          refId: q.id,
        );
        st.questsDone.update(q.kind.code, (n) => n + 1, ifAbsent: () => 1);
        events.add(
          DelightEvent(
            kind: DelightKind.questCompleted,
            date: CivilDate.fromDayNumber(day),
            reasons: reasons,
          ),
        );
      } else if (progress != q.progress) {
        book.put(q.copyWith(progress: progress));
      }
    }
  }

  void _closeDay(int day) {
    for (final q in List<Quest>.of(book.all)) {
      final end = q.endsOn;
      if (q.status == QuestStatus.active &&
          end != null &&
          end.dayNumber <= day) {
        book.put(q.copyWith(status: QuestStatus.expired));
      }
    }
    if (weekdayOf(day) == 7) {
      _closeWeek(day - 6);
      book.prune(day - p.questRetentionDays);
    }
    st.settledThrough = day;
  }

  /// Clôt la semaine du lundi [monday] : régularité, jours de repos, série
  /// de semaines. Une semaine sans séance prévue, ou touchée par une pause
  /// déclarée et non réussie, est en pause : la série ne bouge pas.
  void _closeWeek(int monday) {
    if (st.weeks.isNotEmpty && st.weeks.last.monday >= monday) {
      return;
    }
    final from = monday > st.startedOn ? monday : st.startedOn;
    final to = monday + 6;
    if (from > to) {
      return;
    }
    final windowDays = to - from + 1;
    final scheduled = w.scheduledIn(from, to, skipBreaks: true);
    var breakDays = 0;
    BreakReason? cause;
    for (var d = from; d <= to; d++) {
      final b = w.breakOn(d);
      if (b != null) {
        breakDays++;
        cause ??= b;
      }
    }
    var done = 0;
    var neutral = 0;
    final hardDays = <int>{};
    for (final f in w.factsIn(from, to)) {
      final status = ledger.statusOf(f.session.id);
      if (status == SessionStatus.pain) {
        neutral++;
      }
      if (status == SessionStatus.paid && f.completion >= p.doneCompletion) {
        done++;
      }
      if (f.hard) {
        hardDays.add(f.day);
      }
    }
    var planned = scheduled - neutral;
    if (planned < 0) {
      planned = 0;
    }
    if (done > planned) {
      done = planned;
    }
    final restPlanned = windowDays - scheduled;
    final restActual = windowDays - hardDays.length;
    final restKept = restActual < restPlanned ? restActual : restPlanned;
    final int status;
    if (planned == 0) {
      status = WeekSummary.paused;
    } else if (done * p.streakDenominator >= planned * p.streakNumerator) {
      status = WeekSummary.success;
    } else if (breakDays > 0) {
      status = WeekSummary.paused;
    } else {
      status = WeekSummary.failed;
    }
    if (status == WeekSummary.success) {
      st.streak++;
      if (st.streak > st.bestStreak) {
        st.bestStreak = st.streak;
      }
    } else if (status == WeekSummary.failed) {
      st.streak = 0;
    }
    final iso = CivilDate.fromDayNumber(monday).iso;
    if (planned > 0 && done > 0) {
      final adherence = done / planned;
      final rest = restPlanned == 0 ? 1.0 : restKept / restPlanned;
      ledger.addXp(
        day: to,
        source: XpSource.consistency,
        amount: (adherence * (p.weekXp + p.restXp * rest)).round(),
        refId: 'week|$iso',
        reasons: <Reason>[
          _reason(ReasonCodes.questXpConsistency, <String, Object?>{
            'weeks': st.streak,
          }),
          _reason(ReasonCodes.questXpRest, <String, Object?>{'days': restKept}),
          if (status == WeekSummary.paused && cause != null)
            _reason(ReasonCodes.questStreakPaused, <String, Object?>{
              'cause': cause.code,
            }),
        ],
      );
    }
    if (status == WeekSummary.success) {
      final reasons = <Reason>[
        _reason(ReasonCodes.questStreak, <String, Object?>{'weeks': st.streak}),
      ];
      events.add(
        DelightEvent(
          kind: DelightKind.weekStreak,
          date: CivilDate.fromDayNumber(to),
          streakWeeks: st.streak,
          reasons: reasons,
        ),
      );
      final at = p.streakMilestones.indexOf(st.streak);
      if (at >= 0) {
        final ref = 'streak|${st.streak}|$iso';
        ledger.addXp(
          day: to,
          source: XpSource.consistency,
          amount: p.streakMilestoneXp[at],
          refId: ref,
          reasons: reasons,
        );
        ledger.addKredits(
          day: to,
          source: KreditSource.milestone,
          amount: p.streakMilestoneKredits[at],
          refId: ref,
        );
      }
    }
    st.weeks.add(
      WeekSummary(
        monday: monday,
        planned: planned,
        done: done,
        restPlanned: restPlanned,
        restKept: restKept,
        status: status,
      ),
    );
  }

  /// Paie les jalons de [g] atteints au plus tard le jour [day].
  void _payMilestones(GoalResult g, int day) {
    if (g.ambition <= 0) {
      return;
    }
    for (var i = 0; i < 4; i++) {
      final reachedDay = g.reachedDays[i];
      if (reachedDay == null || reachedDay < st.startedOn || reachedDay > day) {
        continue;
      }
      final ref = 'goal|${g.goal.id}|${i + 1}';
      if (ledger.hasXp(Ledger.xpKey(XpSource.milestone, null, ref))) {
        continue;
      }
      final wanted = (g.ambition * p.milestoneXp[i]).round();
      final lastDay = ledger.xp.isEmpty
          ? reachedDay
          : ledger.xp.last.date.dayNumber;
      final entryDay = reachedDay > lastDay ? reachedDay : lastDay;
      final room =
          p.milestoneWeekCapXp - ledger.milestoneXpIn(mondayOf(entryDay));
      final granted = wanted < room ? wanted : (room < 0 ? 0 : room);
      final fraction = g.progress.milestones[i].fraction;
      final reason = _reason(ReasonCodes.questXpMilestone, <String, Object?>{
        'fraction': fraction,
        'goalId': g.goal.id,
      });
      ledger.addXp(
        day: reachedDay,
        source: XpSource.milestone,
        amount: granted,
        refId: ref,
        reasons: <Reason>[
          reason,
          if (granted < wanted)
            _reason(ReasonCodes.questXpCapped, <String, Object?>{
              'cap': p.milestoneWeekCapXp,
              'scope': CapScope.milestones,
            }),
        ],
      );
      ledger.addKredits(
        day: reachedDay,
        source: KreditSource.milestone,
        amount: (g.ambition * p.milestoneKredits[i]).round(),
        refId: ref,
      );
      events.add(
        DelightEvent(
          kind: DelightKind.goalMilestone,
          date: CivilDate.fromDayNumber(reachedDay),
          exerciseId:
              g.goal.exerciseId != null &&
                  w.catalog.contains(g.goal.exerciseId!)
              ? g.goal.exerciseId
              : null,
          value: fraction,
          reasons: <Reason>[reason],
        ),
      );
    }
  }

  /// Passages de niveau dus aux gains écrits jusqu'au jour [day].
  void _levelUps(int day) {
    final after = engine.curve.stateOf(ledger.totalXp);
    final from = _ordinal;
    final to = LevelCurve.ordinal(after);
    _ordinal = to;
    for (var ordinal = from + 1; ordinal <= to; ordinal++) {
      final prestige = (ordinal - 1) ~/ LevelCurve.maxLevel;
      final level = (ordinal - 1) % LevelCurve.maxLevel + 1;
      final rollover = level == 1 && prestige > 0;
      final amount = rollover
          ? p.prestigeKredits
          : p.levelKredits + (level % 10 == 0 ? p.levelDecadeKredits : 0);
      final written = ledger.addKredits(
        day: day,
        source: KreditSource.levelUp,
        amount: amount,
        refId: 'level|$prestige|$level',
      );
      if (!written) {
        continue;
      }
      events.add(
        DelightEvent(
          kind: DelightKind.levelUp,
          date: CivilDate.fromDayNumber(day),
          value: level.toDouble(),
          reasons: <Reason>[
            _reason(ReasonCodes.questLevelUp, <String, Object?>{
              'level': level,
            }),
            if (rollover)
              _reason(ReasonCodes.questPrestige, <String, Object?>{
                'prestige': prestige,
              }),
          ],
        ),
      );
    }
  }
}
