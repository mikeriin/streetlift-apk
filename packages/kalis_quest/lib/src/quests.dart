/// Quêtes (D7.6) : génération déterministe (graine de l'utilisateur +
/// date), adaptée au jour et à l'utilisateur, et mesure de l'avancement
/// depuis le journal.
///
/// Règles tenues par construction (testées) : un jour de repos ou de pause
/// ne propose que de la récupération ; aucune quête ne demande plus que le
/// programme ; aucune cible n'est impossible.
library;

import 'package:kalis_core/kalis_core.dart';

import 'ledger.dart';
import 'numeric.dart';
import 'params.dart';
import 'world.dart';

/// Codes des modèles de quête.
abstract final class QuestTemplates {
  /// Faire la séance du jour.
  static const String dailySession = 'daily.session';

  /// Tenir un nombre de séries dans la cible de flammes.
  static const String dailyInTarget = 'daily.in_target';

  /// Noter toutes les séries de la séance.
  static const String dailyRated = 'daily.rated';

  /// Répondre au bilan santé avant la séance.
  static const String dailyHealthCheck = 'daily.health_check';

  /// Enchaîner des séries dans la cible.
  static const String dailyCombo = 'daily.combo';

  /// Bien dormir (déclaratif).
  static const String restSleep = 'rest.sleep';

  /// Bien s'hydrater (déclaratif).
  static const String restHydration = 'rest.hydration';

  /// Marche légère (déclaratif).
  static const String restWalk = 'rest.walk';

  /// Mobilité légère (journal ou déclaratif).
  static const String restMobility = 'rest.mobility';

  /// Respiration, relâchement (déclaratif).
  static const String restBreathing = 'rest.breathing';

  /// Faire les séances prévues de la semaine.
  static const String weeklySessions = 'weekly.sessions';

  /// Noter toutes les séries de chaque séance de la semaine.
  static const String weeklyRated = 'weekly.rated';

  /// Répondre au bilan santé à chaque séance de la semaine.
  static const String weeklyHealthChecks = 'weekly.health_checks';

  /// Faire de la mobilité plusieurs jours de la semaine.
  static const String weeklyMobility = 'weekly.mobility';

  /// Chapitre de campagne : les séances du bloc.
  static const String campaignChapter = 'campaign.chapter';

  /// Boss de campagne : séance de test ou dernière séance du bloc.
  static const String campaignBoss = 'campaign.boss';

  /// Koach : mobilité (attribut le plus faible).
  static const String koachMobility = 'koach.mobility';

  /// Koach : justesse des flammes (attribut le plus faible).
  static const String koachAccuracy = 'koach.accuracy';

  /// Koach : chaque séance prévue faite en entier (attribut le plus
  /// faible).
  static const String koachFullSessions = 'koach.full_sessions';

  /// Koach : toutes les séries prévues d'un exercice souvent écourté.
  static const String koachLaggingExercise = 'koach.lagging_exercise';

  /// Koach : la séance d'un jour de la semaine souvent manqué.
  static const String koachWeekday = 'koach.weekday';

  /// Modèles d'un jour de repos ou de pause : récupération seulement.
  static const List<String> recovery = <String>[
    restSleep,
    restHydration,
    restWalk,
    restMobility,
    restBreathing,
  ];

  /// Modèles d'une pause pour maladie ou blessure : récupération passive.
  static const List<String> passive = <String>[restSleep, restHydration];
}

/// Mesures d'avancement d'une quête (`params.metric`).
abstract final class QuestMetrics {
  /// Séances récompensées faites.
  static const String sessions = 'sessions';

  /// Séances récompensées faites en entier.
  static const String fullSessions = 'full_sessions';

  /// Séries dans la cible.
  static const String setsInTarget = 'sets_in_target';

  /// Séances dont toutes les séries sont notées.
  static const String ratedSessions = 'rated_sessions';

  /// Séances précédées d'un bilan santé.
  static const String healthChecks = 'health_checks';

  /// Plus long combo.
  static const String combo = 'combo';

  /// Secondes de mobilité et de récupération.
  static const String mobilitySeconds = 'mobility_seconds';

  /// Jours avec de la mobilité.
  static const String mobilityDays = 'mobility_days';

  /// Séries de travail d'un exercice.
  static const String exerciseSets = 'exercise_sets';

  /// Séance faite un jour de la semaine donné.
  static const String weekdaySession = 'weekday_session';

  /// Séance de boss faite.
  static const String boss = 'boss';

  /// Séances du bloc faites.
  static const String chapter = 'chapter';

  /// Déclaration de l'utilisateur.
  static const String claim = 'claim';
}

/// Quêtes de l'état, dans leur ordre de création.
final class QuestBook {
  /// Quêtes de [quests].
  QuestBook(List<Quest> quests) {
    for (final q in quests) {
      put(q);
    }
  }

  final List<Quest> _list = <Quest>[];
  final Map<String, int> _index = <String, int>{};

  /// Toutes les quêtes.
  List<Quest> get all => _list;

  /// Quête d'identifiant [id], ou `null`.
  Quest? find(String id) {
    final i = _index[id];
    return i == null ? null : _list[i];
  }

  /// Ajoute [quest], ou remplace celle du même identifiant.
  void put(Quest quest) {
    final i = _index[quest.id];
    if (i == null) {
      _index[quest.id] = _list.length;
      _list.add(quest);
    } else {
      _list[i] = quest;
    }
  }

  /// Retire les quêtes finies dont la fin précède le jour [before].
  void prune(int before) {
    final kept = <Quest>[
      for (final q in _list)
        if (q.status == QuestStatus.active ||
            (q.endsOn ?? q.startsOn).dayNumber >= before)
          q,
    ];
    _list
      ..clear()
      ..addAll(kept);
    _index.clear();
    for (var i = 0; i < _list.length; i++) {
      _index[_list[i].id] = i;
    }
  }
}

/// Générateur et mesureur de quêtes d'un appel.
final class QuestMaster {
  /// Quêtes de [book] pour le monde [w].
  QuestMaster({
    required this.w,
    required this.book,
    required this.ledger,
    required this.st,
    required this.seed,
    required this.attributesAt,
  });

  /// Monde.
  final World w;

  /// Quêtes.
  final QuestBook book;

  /// Registres.
  final Ledger ledger;

  /// État.
  final MachineState st;

  /// Graine de l'utilisateur.
  final int seed;

  /// Attributs au jour donné (pour la quête Koach).
  final List<double> Function(int asOf) attributesAt;

  QuestParams get _p => w.params;

  static String _iso(int day) => CivilDate.fromDayNumber(day).iso;

  bool get _persistentPain {
    for (final pain in w.input.adaptation?.pains ?? const <PainTrend>[]) {
      if (pain.consecutiveAboveThreshold >= _p.persistentPainSessions) {
        return true;
      }
    }
    return false;
  }

  /// Séries de travail et combo habituels avant le jour [day] (médianes
  /// des huit dernières séances d'entraînement).
  (int, int) _typical(int day) {
    final sets = <double>[];
    final combos = <double>[];
    for (var i = w.facts.length - 1; i >= 0 && sets.length < 8; i--) {
      final f = w.facts[i];
      if (f.day >= day || !f.hard || f.workSets == 0) {
        continue;
      }
      sets.add(f.workSets.toDouble());
      combos.add(f.combo.toDouble());
    }
    if (sets.isEmpty) {
      return (_p.defaultTypicalSets, _p.comboMin);
    }
    return (medianOf(sets).round(), medianOf(combos).round());
  }

  Quest _quest({
    required String id,
    required QuestKind kind,
    required String template,
    required String metric,
    required int from,
    required int to,
    required num target,
    required int xp,
    required int kredits,
    required List<Reason> reasons,
    Map<String, Object?> extra = const <String, Object?>{},
    bool claimable = false,
  }) {
    return Quest(
      id: id,
      kind: kind,
      template: template,
      params: <String, Object?>{
        ...extra,
        if (claimable) 'claimable': true,
        'metric': metric,
      },
      startsOn: CivilDate.fromDayNumber(from),
      endsOn: CivilDate.fromDayNumber(to),
      progress: 0,
      target: target.toDouble(),
      status: QuestStatus.active,
      rewardXp: xp,
      rewardKredits: kredits,
      reasons: reasons,
    );
  }

  /// Crée les quêtes qui commencent le jour [day] si elles n'existent pas.
  void ensure(int day) {
    _ensureDaily(day);
    _ensureWeekly(day);
    _ensureCampaign(day);
  }

  void _ensureDaily(int day) {
    final iso = _iso(day);
    if (book.find('d:$iso:0') != null) {
      return;
    }
    final pause = w.breakOn(day);
    final training = pause == null && w.isTrainingDay(day);
    final dayKind = pause != null ? 'break' : (training ? 'training' : 'rest');
    final reasons = <Reason>[
      Reason(
        code: ReasonCodes.questDaily,
        params: <String, Object?>{'dayKind': dayKind},
      ),
    ];
    var slot = 0;
    void add(
      String template,
      String metric,
      num target, {
      bool claimable = false,
    }) {
      final recovery = template.startsWith('rest.');
      book.put(
        _quest(
          id: 'd:$iso:$slot',
          kind: QuestKind.daily,
          template: template,
          metric: metric,
          from: day,
          to: day,
          target: target,
          xp: recovery ? _p.restQuestXp : _p.dailyXp,
          kredits: recovery ? _p.restQuestKredits : _p.dailyKredits,
          reasons: reasons,
          claimable: claimable,
        ),
      );
      slot++;
    }

    if (!training) {
      final passive =
          pause == BreakReason.illness || pause == BreakReason.injury;
      final pool = passive ? QuestTemplates.passive : QuestTemplates.recovery;
      final count = pause != null ? 1 : 1 + pickOf(seed, 'rest-count|$iso', 2);
      final first = pickOf(seed, 'rest-first|$iso', pool.length);
      for (var i = 0; i < count && i < pool.length; i++) {
        final template = pool[(first + i) % pool.length];
        if (template == QuestTemplates.restMobility) {
          add(
            template,
            QuestMetrics.mobilitySeconds,
            _p.restMobilitySeconds,
            claimable: true,
          );
        } else {
          add(template, QuestMetrics.claim, 1, claimable: true);
        }
      }
      return;
    }

    add(QuestTemplates.dailySession, QuestMetrics.sessions, 1);
    final (typicalSets, typicalCombo) = _typical(day);
    final prescription = w.prescriptionOn(day);
    var upper = typicalSets;
    if (prescription != null) {
      var targeted = 0;
      for (final item in prescription.items) {
        if (item.targetFlames != null &&
            (item.kind ?? SetKind.work) != SetKind.warmup) {
          targeted += item.sets;
        }
      }
      upper = targeted;
    }
    final pool = <String>[
      QuestTemplates.dailyRated,
      QuestTemplates.dailyHealthCheck,
      if (!_persistentPain && upper >= 1) QuestTemplates.dailyInTarget,
      if (!_persistentPain && upper >= _p.comboMin) QuestTemplates.dailyCombo,
    ];
    final extras = 1 + pickOf(seed, 'day-count|$iso', 2);
    final first = pickOf(seed, 'day-first|$iso', pool.length);
    final step = 1 + pickOf(seed, 'day-step|$iso', pool.length - 1);
    for (var i = 0; i < extras; i++) {
      final template = pool[(first + i * step) % pool.length];
      switch (template) {
        case QuestTemplates.dailyRated:
          add(template, QuestMetrics.ratedSessions, 1);
        case QuestTemplates.dailyHealthCheck:
          add(template, QuestMetrics.healthChecks, 1);
        case QuestTemplates.dailyInTarget:
          final wanted = (_p.inTargetShare * typicalSets).round();
          final floor = _p.inTargetMin < upper ? _p.inTargetMin : upper;
          add(
            template,
            QuestMetrics.setsInTarget,
            clampInt(wanted, floor, upper),
          );
        case QuestTemplates.dailyCombo:
          add(
            template,
            QuestMetrics.combo,
            clampInt(typicalCombo, _p.comboMin, upper),
          );
      }
    }
  }

  /// Cible adaptée à l'utilisateur : une de plus que d'habitude, sans
  /// jamais dépasser le programme [planned].
  int _stretch(num usual, int planned) =>
      clampInt(usual.floor() + 1, 1, planned);

  void _ensureWeekly(int day) {
    final monday = mondayOf(day);
    final iso = _iso(monday);
    if (book.find('w:$iso:0') != null) {
      return;
    }
    final end = monday + 6;
    final planned = w.scheduledIn(day, end, skipBreaks: true);
    if (planned < 1) {
      return;
    }
    final reasons = <Reason>[
      Reason(
        code: ReasonCodes.questWeekly,
        params: <String, Object?>{'planned': planned},
      ),
    ];
    // Séances faites d'habitude : médiane des quatre dernières semaines
    // closes hors pause. Sans historique, la cible est le programme.
    final recent = <double>[];
    for (var i = st.weeks.length - 1; i >= 0 && recent.length < 4; i--) {
      final week = st.weeks[i];
      if (week.monday < monday && week.status != WeekSummary.paused) {
        recent.add(week.done.toDouble());
      }
    }
    final sessionsTarget = recent.isEmpty
        ? planned
        : _stretch(medianOf(recent), planned);
    book.put(
      _quest(
        id: 'w:$iso:0',
        kind: QuestKind.weekly,
        template: QuestTemplates.weeklySessions,
        metric: QuestMetrics.sessions,
        from: day,
        to: end,
        target: sessionsTarget,
        xp: _p.weeklyQuestXp,
        kredits: _p.weeklyQuestKredits,
        reasons: reasons,
      ),
    );
    // Habitudes des 28 jours précédents, par semaine.
    var rated = 0;
    var checked = 0;
    for (final f in w.factsIn(day - 28, day - 1)) {
      if (f.completion >= _p.doneCompletion && f.painZone == null) {
        if (f.fullyRated) {
          rated++;
        }
        if (f.healthAnswered) {
          checked++;
        }
      }
    }
    final daysLeft = end - day + 1;
    final String template;
    final String metric;
    final int target;
    switch (pickOf(seed, 'week|$iso', 3)) {
      case 0:
        template = QuestTemplates.weeklyRated;
        metric = QuestMetrics.ratedSessions;
        target = _stretch(rated / 4, planned);
      case 1:
        template = QuestTemplates.weeklyHealthChecks;
        metric = QuestMetrics.healthChecks;
        target = _stretch(checked / 4, planned);
      default:
        template = QuestTemplates.weeklyMobility;
        metric = QuestMetrics.mobilityDays;
        target = _p.weeklyMobilityDays < daysLeft
            ? _p.weeklyMobilityDays
            : daysLeft;
    }
    book.put(
      _quest(
        id: 'w:$iso:1',
        kind: QuestKind.weekly,
        template: template,
        metric: metric,
        from: day,
        to: end,
        target: target,
        xp: _p.weeklyQuestXp,
        kredits: _p.weeklyQuestKredits,
        reasons: reasons,
      ),
    );
    final koach = _koach(day, monday, end, planned);
    if (koach != null) {
      book.put(koach);
    }
  }

  Quest? _koach(int day, int monday, int end, int planned) {
    final id = 'k:${_iso(monday)}';
    final rotation = (monday ~/ 7) % 3;
    for (var i = 0; i < 3; i++) {
      final Quest? q;
      switch ((rotation + i) % 3) {
        case 0:
          q = _koachWeakPoint(id, day, end, planned);
        case 1:
          q = _koachLagging(id, day, end);
        default:
          q = _koachWeekday(id, day, end);
      }
      if (q != null) {
        return q;
      }
    }
    return null;
  }

  /// Quête sur un point faible : l'un des trois attributs les plus bas
  /// pour lesquels une action existe, à tour de rôle d'une semaine à
  /// l'autre (une même quête ne revient pas chaque semaine).
  Quest? _koachWeakPoint(String id, int day, int end, int planned) {
    final values = attributesAt(day - 1);
    final order = <int>[for (var i = 0; i < values.length; i++) i]
      ..sort((a, b) {
        final c = values[a].compareTo(values[b]);
        return c != 0 ? c : a.compareTo(b);
      });
    final candidates = <Quest>[];
    for (final index in order) {
      final q = _weakPointQuest(
        AthleteAttribute.values[index],
        id,
        day,
        end,
        planned,
      );
      if (q != null) {
        candidates.add(q);
      }
      if (candidates.length == 3) {
        break;
      }
    }
    if (candidates.isEmpty) {
      return null;
    }
    return candidates[(mondayOf(day) ~/ 7) % candidates.length];
  }

  Quest? _weakPointQuest(
    AthleteAttribute attribute,
    String id,
    int day,
    int end,
    int planned,
  ) {
    final reasons = <Reason>[
      Reason(
        code: ReasonCodes.questWeakPoint,
        params: <String, Object?>{'attribute': attribute.code},
      ),
    ];
    final extra = <String, Object?>{'attribute': attribute.code};
    switch (attribute) {
      case AthleteAttribute.mobility:
        return _quest(
          id: id,
          kind: QuestKind.koach,
          template: QuestTemplates.koachMobility,
          metric: QuestMetrics.mobilitySeconds,
          from: day,
          to: end,
          target: _p.koachMobilitySeconds,
          xp: _p.koachQuestXp,
          kredits: _p.koachQuestKredits,
          reasons: reasons,
          extra: extra,
        );
      case AthleteAttribute.technique:
        if (_persistentPain) {
          return null;
        }
        final (typicalSets, _) = _typical(day);
        final wanted = (_p.inTargetShare * typicalSets * planned).round();
        return _quest(
          id: id,
          kind: QuestKind.koach,
          template: QuestTemplates.koachAccuracy,
          metric: QuestMetrics.setsInTarget,
          from: day,
          to: end,
          target: wanted < 1 ? 1 : wanted,
          xp: _p.koachQuestXp,
          kredits: _p.koachQuestKredits,
          reasons: reasons,
          extra: extra,
        );
      case AthleteAttribute.consistency:
        return null;
      case AthleteAttribute.strength:
      case AthleteAttribute.endurance:
      case AthleteAttribute.power:
        return _quest(
          id: id,
          kind: QuestKind.koach,
          template: QuestTemplates.koachFullSessions,
          metric: QuestMetrics.fullSessions,
          from: day,
          to: end,
          target: planned,
          xp: _p.koachQuestXp,
          kredits: _p.koachQuestKredits,
          reasons: reasons,
          extra: extra,
        );
    }
  }

  Quest? _koachLagging(String id, int day, int end) {
    final avoided = w.input.adaptation?.avoidedExerciseIds;
    if (avoided == null || avoided.isEmpty) {
      return null;
    }
    for (final exerciseId in avoided) {
      var sets = 0;
      for (var d = day; d <= end; d++) {
        if (!w.isTrainingDay(d)) {
          continue;
        }
        final prescription = w.prescriptionOn(d);
        if (prescription == null) {
          continue;
        }
        for (final item in prescription.items) {
          if (item.exerciseId == exerciseId &&
              (item.kind ?? SetKind.work) != SetKind.warmup) {
            sets += item.sets;
          }
        }
      }
      if (sets > 0) {
        return _quest(
          id: id,
          kind: QuestKind.koach,
          template: QuestTemplates.koachLaggingExercise,
          metric: QuestMetrics.exerciseSets,
          from: day,
          to: end,
          target: sets,
          xp: _p.koachQuestXp,
          kredits: _p.koachQuestKredits,
          reasons: <Reason>[
            Reason(
              code: ReasonCodes.questLaggingExercise,
              params: <String, Object?>{'exerciseId': exerciseId},
            ),
          ],
          extra: <String, Object?>{'exerciseId': exerciseId},
        );
      }
    }
    return null;
  }

  Quest? _koachWeekday(String id, int day, int end) {
    final monday = mondayOf(day);
    final first = st.startedOn > monday - 56 ? st.startedOn : monday - 56;
    final weeks = (monday - mondayOf(first)) ~/ 7;
    if (weeks < 3) {
      return null;
    }
    final trained = <int, Set<int>>{};
    for (final f in w.factsIn(first, monday - 1)) {
      if (f.workSets > 0) {
        trained
            .putIfAbsent(weekdayOf(f.day), () => <int>{})
            .add(mondayOf(f.day));
      }
    }
    int? weakest;
    var lowest = _p.weekdayFocusShare;
    final weekdays = w.scheduleWeekdays.toList()..sort();
    for (final weekday in weekdays) {
      final target = monday + weekday - 1;
      if (target < day || target > end || w.breakOn(target) != null) {
        continue;
      }
      final share = (trained[weekday]?.length ?? 0) / weeks;
      if (share < lowest) {
        lowest = share;
        weakest = weekday;
      }
    }
    if (weakest == null) {
      return null;
    }
    return _quest(
      id: id,
      kind: QuestKind.koach,
      template: QuestTemplates.koachWeekday,
      metric: QuestMetrics.weekdaySession,
      from: day,
      to: end,
      target: 1,
      xp: _p.koachQuestXp,
      kredits: _p.koachQuestKredits,
      reasons: <Reason>[
        Reason(
          code: ReasonCodes.questWeekdayFocus,
          params: <String, Object?>{'weekday': weakest},
        ),
      ],
      extra: <String, Object?>{'weekday': weakest},
    );
  }

  void _ensureCampaign(int day) {
    final block = w.input.block;
    final week = w.blockWeekOf(day);
    if (block == null || week == null) {
      return;
    }
    final pass1 = block.pass1;
    final blockId = pass1.blockId;
    final blockEnd = pass1.startDate.dayNumber + 7 * pass1.weeks - 1;
    final end = blockEnd + _p.campaignGraceDays;
    if (book.find('c:$blockId:chapter') == null) {
      final remaining = w.scheduledIn(day, blockEnd, skipBreaks: false);
      if (remaining >= 1) {
        final target = (_p.chapterShare * remaining).ceil();
        book.put(
          _quest(
            id: 'c:$blockId:chapter',
            kind: QuestKind.campaign,
            template: QuestTemplates.campaignChapter,
            metric: QuestMetrics.chapter,
            from: day,
            to: end,
            target: target < 1 ? 1 : target,
            xp: _p.chapterXp,
            kredits: _p.chapterKredits,
            reasons: <Reason>[
              Reason(
                code: ReasonCodes.questCampaignChapter,
                params: <String, Object?>{'blockIndex': pass1.blockIndex},
              ),
            ],
            extra: <String, Object?>{'blockId': blockId},
          ),
        );
      }
    }
    if (book.find('c:$blockId:boss') == null) {
      int? bossWeek;
      var bossDay = -1;
      for (final wk in block.pass2.weeks) {
        if (wk.kind == WeekKind.test && wk.weekIndex >= week) {
          if (bossWeek == null || wk.weekIndex < bossWeek) {
            bossWeek = wk.weekIndex;
          }
        }
      }
      if (bossWeek == null) {
        // Pas de semaine de test : le boss est la dernière séance prévue
        // du bloc, si elle est encore à venir.
        final lastWeek = pass1.weeks - 1;
        final start = pass1.startDate.dayNumber + 7 * lastWeek;
        var latest = -1;
        for (final d in pass1.days) {
          final offset = (d.weekday - weekdayOf(start)) % 7;
          final when = start + offset;
          if (when >= day && when > latest) {
            latest = when;
            bossDay = d.dayIndex;
          }
        }
        if (latest >= 0) {
          bossWeek = lastWeek;
        }
      }
      if (bossWeek != null) {
        book.put(
          _quest(
            id: 'c:$blockId:boss',
            kind: QuestKind.campaign,
            template: QuestTemplates.campaignBoss,
            metric: QuestMetrics.boss,
            from: day,
            to: end,
            target: 1,
            xp: _p.bossXp,
            kredits: _p.bossKredits,
            reasons: <Reason>[
              Reason(
                code: ReasonCodes.questCampaignBoss,
                params: <String, Object?>{'blockIndex': pass1.blockIndex},
              ),
            ],
            extra: <String, Object?>{
              'blockId': blockId,
              'dayIndex': bossDay,
              'weekIndex': bossWeek,
            },
          ),
        );
      }
    }
  }

  /// Avancement de [q] d'après les séances réglées jusqu'au jour [upTo]
  /// inclus. Une séance faite malgré une douleur ou au-delà du programme
  /// ne fait avancer aucune quête.
  double progressOf(Quest q, int upTo) {
    final from = q.startsOn.dayNumber;
    final end = q.endsOn?.dayNumber ?? upTo;
    final to = end < upTo ? end : upTo;
    final metric = q.params['metric'];
    final claimed = q.params['claimable'] == true && q.progress >= q.target;
    if (metric == QuestMetrics.claim) {
      return q.progress;
    }
    var value = 0.0;
    final days = <int, int>{};
    for (final f in w.factsIn(from, to)) {
      final status = ledger.statusOf(f.session.id);
      final paid = status == SessionStatus.paid;
      final done = paid && f.completion >= _p.doneCompletion;
      switch (metric) {
        case QuestMetrics.sessions:
          if (done) {
            value += 1;
          }
        case QuestMetrics.fullSessions:
          if (paid && f.completion >= 1) {
            value += 1;
          }
        case QuestMetrics.setsInTarget:
          if (paid) {
            value += f.inTarget;
          }
        case QuestMetrics.ratedSessions:
          if (done && f.fullyRated) {
            value += 1;
          }
        case QuestMetrics.healthChecks:
          if (done && f.healthAnswered) {
            value += 1;
          }
        case QuestMetrics.combo:
          if (paid && f.combo > value) {
            value = f.combo.toDouble();
          }
        case QuestMetrics.mobilitySeconds:
          if (paid || status == SessionStatus.recovery) {
            value += f.mobilitySeconds;
          }
        case QuestMetrics.mobilityDays:
          if (paid || status == SessionStatus.recovery) {
            days.update(
              f.day,
              (s) => s + f.mobilitySeconds,
              ifAbsent: () => f.mobilitySeconds,
            );
          }
        case QuestMetrics.exerciseSets:
          if (paid) {
            value += f.setsByExercise[q.params['exerciseId']] ?? 0;
          }
        case QuestMetrics.weekdaySession:
          if (done && weekdayOf(f.day) == q.params['weekday']) {
            value = 1;
          }
        case QuestMetrics.boss:
          final ref = f.session.programRef;
          final dayIndex = q.params['dayIndex'];
          if (paid &&
              ref != null &&
              ref.blockId == q.params['blockId'] &&
              ref.weekIndex == q.params['weekIndex'] &&
              (dayIndex is! int || dayIndex < 0 || ref.dayIndex == dayIndex) &&
              f.completion >= _p.bossCompletion) {
            value = 1;
          }
        case QuestMetrics.chapter:
          final ref = f.session.programRef;
          if (done && ref != null && ref.blockId == q.params['blockId']) {
            value += 1;
          }
      }
    }
    if (metric == QuestMetrics.mobilityDays) {
      for (final seconds in days.values) {
        if (seconds >= _p.mobilityDaySeconds) {
          value += 1;
        }
      }
    }
    if (claimed && value < q.target) {
      return q.target;
    }
    return value;
  }
}
