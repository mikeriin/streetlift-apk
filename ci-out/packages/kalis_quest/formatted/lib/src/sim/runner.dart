/// Déroulement d'une simulation de rythme : le journal d'un archétype est
/// donné au moteur semaine après semaine, comme le ferait l'application,
/// et ce que le moteur rend est mesuré.
library;

import 'package:kalis_core/kalis_core.dart';

import '../engine.dart';
import '../ledger.dart';
import '../level.dart';
import '../numeric.dart';
import 'archetypes.dart';
import 'generator.dart';

/// Niveaux dont on mesure la date d'atteinte.
const List<int> milestoneLevels = <int>[10, 25, 50, 100];

/// Mesures d'une simulation.
final class SimResult {
  /// Mesures de l'archétype [archetype] pour la graine [seed].
  SimResult(this.archetype, this.seed);

  /// Archétype.
  final String archetype;

  /// Graine.
  final int seed;

  /// Niveau global (`prestige × 100 + niveau`) à la fin de chaque semaine.
  final List<int> levels = <int>[];

  /// XP total à la fin de chaque semaine.
  final List<int> xp = <int>[];

  /// Semaine (1 = première) où chaque niveau de [milestoneLevels] est
  /// atteint, ou `null`.
  final Map<int, int?> weekOfLevel = <int, int?>{};

  /// XP par origine.
  final Map<String, int> xpBySource = <String, int>{};

  /// Krédits gagnés.
  int kredits = 0;

  /// Krédits par origine.
  final Map<String, int> kreditsBySource = <String, int>{};

  /// Quêtes créées par famille.
  final Map<String, int> questsCreated = <String, int>{};

  /// Quêtes terminées par famille.
  final Map<String, int> questsDone = <String, int>{};

  /// Semaines réussies, manquées, en pause.
  int weeksSuccess = 0;

  /// Voir [weeksSuccess].
  int weeksFailed = 0;

  /// Voir [weeksSuccess].
  int weeksPaused = 0;

  /// Meilleure série de semaines.
  int bestStreak = 0;

  /// Notes de séance.
  final Map<String, int> grades = <String, int>{'s': 0, 'a': 0, 'b': 0, 'c': 0};

  /// Coffres ouverts.
  int chests = 0;

  /// Plus longue suite de séances récompensées sans coffre.
  int maxChestGap = 0;

  /// Séances récompensées.
  int paidSessions = 0;

  /// Séances prévues.
  int plannedSessions = 0;

  /// Séances sans récompense pour douleur.
  int painSessions = 0;

  /// XP écrit pour ces séances (doit rester nul).
  int painXp = 0;

  /// Séances au-delà du programme (sans XP).
  int extraSessions = 0;

  /// XP d'effort le plus haut d'une semaine, rapporté à son plafond
  /// (séances prévues × XP maximal d'une séance) : jamais au-dessus de 1.
  double worstWeekShare = 0;

  /// Événements de record.
  int records = 0;

  /// Passages de rang.
  int rankUps = 0;

  /// Attributs à la fin.
  List<double> attributes = const <double>[];

  /// Meilleure valeur des attributs.
  List<double> attributeBests = const <double>[];

  /// Écritures d'XP à la fin.
  int ledgerEntries = 0;

  /// Vrai si le niveau global a baissé d'une semaine à l'autre.
  bool levelDropped = false;

  /// État final (pour les mesures de temps de calcul).
  QuestState? finalState;
}

/// Simule [weeks] semaines de l'archétype [a] avec la graine [seed] :
/// le moteur est appelé à la fin de chaque semaine, avec le bloc en cours
/// et le journal fait jusque-là.
SimResult simulateRun({
  required KalisQuest engine,
  required SimStage stage,
  required Archetype a,
  required int seed,
  required int weeks,
  bool keepState = false,
}) {
  final log = generateLog(a, stage, seed, weeks);
  final result = SimResult(a.key, seed)..plannedSessions = log.planned;
  final start = stage.startDay;
  var state = const QuestState(
    xp: <XpEntry>[],
    kredits: <KreditEntry>[],
    quests: <Quest>[],
    data: <String, Object?>{},
  );
  // Le registre démarre le premier jour, avant toute séance.
  state = engine
      .evaluate(
        stage.catalog,
        QuestInput(
          profile: stage.profile,
          log: const TrainingLog(sessions: <SessionRecord>[]),
          block: stage.blockOn(start),
          state: state,
          today: CivilDate.fromDayNumber(start),
          seed: seed,
        ),
      )
      .state;
  final seen = <String>{};
  var sessionCursor = 0;
  var claimCursor = 0;
  var gap = 0;
  final sessions = <SessionRecord>[];
  QuestOutcome? outcome;
  for (var week = 0; week < weeks; week++) {
    final today = start + 7 * week + 6;
    while (sessionCursor < log.sessions.length &&
        log.sessions[sessionCursor].date.dayNumber <= today) {
      sessions.add(log.sessions[sessionCursor]);
      sessionCursor++;
    }
    final claims = <QuestClaim>[];
    while (claimCursor < log.claims.length &&
        log.claims[claimCursor].date.dayNumber <= today) {
      claims.add(log.claims[claimCursor]);
      claimCursor++;
    }
    outcome = engine.evaluate(
      stage.catalog,
      QuestInput(
        profile: stage.profile,
        log: TrainingLog(
          sessions: List<SessionRecord>.of(sessions),
          breaks: log.breaks,
        ),
        block: stage.blockOn(today),
        state: state,
        today: CivilDate.fromDayNumber(today),
        seed: seed,
        claims: claims,
      ),
    );
    state = outcome.state;
    final ordinal = LevelCurve.ordinal(outcome.level);
    if (result.levels.isNotEmpty && ordinal < result.levels.last) {
      result.levelDropped = true;
    }
    result.levels.add(ordinal);
    result.xp.add(outcome.level.totalXp);
    for (final level in milestoneLevels) {
      if (result.weekOfLevel[level] == null && ordinal >= level) {
        result.weekOfLevel[level] = week + 1;
      }
    }
    for (final q in state.quests) {
      if (seen.add(q.id)) {
        result.questsCreated.update(
          q.kind.code,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
      }
    }
    for (final e in outcome.events) {
      switch (e.kind) {
        case DelightKind.sessionGrade:
          final g = e.grade;
          if (g != null) {
            result.grades.update(g.code, (n) => n + 1);
          }
          gap++;
          if (gap > result.maxChestGap) {
            result.maxChestGap = gap;
          }
        case DelightKind.chest:
          result.chests++;
          gap = 0;
        case DelightKind.record:
          result.records++;
        case DelightKind.rankUp:
          result.rankUps++;
        case DelightKind.weekStreak:
        case DelightKind.combo:
        case DelightKind.ghost:
        case DelightKind.firstTime:
        case DelightKind.levelUp:
        case DelightKind.goalMilestone:
        case DelightKind.questCompleted:
          break;
      }
    }
  }
  final last = outcome;
  if (last == null) {
    return result;
  }
  final cap = engine.params.sessionXp + engine.params.comboBonusCap;
  final effortByWeek = <String, int>{};
  final ledger = Ledger(state);
  for (final e in state.xp) {
    result.xpBySource.update(
      e.source.code,
      (n) => n + e.amount,
      ifAbsent: () => e.amount,
    );
    if (e.source == XpSource.effort) {
      final id = e.sessionId ?? '';
      switch (ledger.statusOf(id)) {
        case SessionStatus.paid:
          result.paidSessions++;
          effortByWeek.update(
            e.refId ?? '',
            (n) => n + e.amount,
            ifAbsent: () => e.amount,
          );
        case SessionStatus.pain:
          result.painSessions++;
          result.painXp += e.amount;
        case SessionStatus.extra:
          result.extraSessions++;
          result.painXp += e.amount;
        case SessionStatus.recovery:
        case SessionStatus.unsettled:
          break;
      }
    }
  }
  final perWeek = stage.profile.availability.length;
  for (final amount in effortByWeek.values) {
    final share = amount / (perWeek * cap);
    if (share > result.worstWeekShare) {
      result.worstWeekShare = share;
    }
  }
  for (final e in state.kredits) {
    result.kredits += e.amount;
    result.kreditsBySource.update(
      e.source.code,
      (n) => n + e.amount,
      ifAbsent: () => e.amount,
    );
  }
  final machine = MachineState.read(state, start + 7 * weeks);
  result.questsDone.addAll(machine.questsDone);
  result.bestStreak = machine.bestStreak;
  for (final w in machine.weeks) {
    if (w.status == WeekSummary.success) {
      result.weeksSuccess++;
    } else if (w.status == WeekSummary.paused) {
      result.weeksPaused++;
    } else {
      result.weeksFailed++;
    }
  }
  result.attributes = <double>[for (final s in last.attributes) s.value];
  result.attributeBests = <double>[
    for (final s in last.attributes) s.best ?? s.value,
  ];
  result.ledgerEntries = state.xp.length;
  if (keepState) {
    result.finalState = state;
  }
  return result;
}

/// Quantile [q] (0 à 1) de [values] ; 0 si la liste est vide.
double quantileOf(List<num> values, double q) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = <double>[for (final v in values) v.toDouble()]..sort();
  final position = q * (sorted.length - 1);
  final low = position.floor();
  final high = position.ceil();
  return sorted[low] + (sorted[high] - sorted[low]) * (position - low);
}

Map<String, Object?> _spread(List<num> values, {int decimals = 1}) =>
    <String, Object?>{
      'p10': roundTo(quantileOf(values, 0.1), decimals),
      'p50': roundTo(quantileOf(values, 0.5), decimals),
      'p90': roundTo(quantileOf(values, 0.9), decimals),
    };

double _mean(Iterable<num> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

/// Semaines dont le niveau est rapporté dans les tableaux.
const List<int> reportWeeks = <int>[1, 3, 13, 26, 52, 104, 156];

/// Résume les simulations [runs] d'un archétype (toutes les graines) en un
/// objet JSON stable.
Map<String, Object?> summarize(Archetype a, List<SimResult> runs, int weeks) {
  final n = runs.length;
  final xpTotal = <int>[for (final r in runs) r.xp.isEmpty ? 0 : r.xp.last];
  final sources = <String>[
    'effort',
    'consistency',
    'record',
    'milestone',
    'quest',
  ];
  final kinds = <String>['daily', 'weekly', 'campaign', 'koach'];
  final sumXp = _mean(xpTotal) * n;
  final curve = <Object?>[];
  for (var week = 4; week <= weeks; week += 4) {
    curve.add(<Object?>[
      week,
      roundTo(
        quantileOf(<int>[for (final r in runs) r.levels[week - 1]], 0.1),
        0,
      ),
      roundTo(
        quantileOf(<int>[for (final r in runs) r.levels[week - 1]], 0.5),
        0,
      ),
      roundTo(
        quantileOf(<int>[for (final r in runs) r.levels[week - 1]], 0.9),
        0,
      ),
    ]);
  }
  var maxGap = 0;
  var worst = 0.0;
  var dropped = false;
  for (final r in runs) {
    if (r.maxChestGap > maxGap) {
      maxGap = r.maxChestGap;
    }
    if (r.worstWeekShare > worst) {
      worst = r.worstWeekShare;
    }
    dropped = dropped || r.levelDropped;
  }
  final gradeTotal = _mean(<int>[
    for (final r in runs) r.grades.values.fold<int>(0, (s, v) => s + v),
  ]);
  return <String, Object?>{
    'key': a.key,
    'profileKey': a.profileKey,
    'note': a.note,
    'runs': n,
    'sessionsPerWeekPlanned': roundTo(
      _mean(<int>[for (final r in runs) r.plannedSessions]) / weeks,
      2,
    ),
    'sessionsPerWeekPaid': roundTo(
      _mean(<int>[for (final r in runs) r.paidSessions]) / weeks,
      2,
    ),
    'levelAt': <String, Object?>{
      for (final week in reportWeeks)
        if (week <= weeks)
          'w$week': _spread(<int>[
            for (final r in runs) r.levels[week - 1],
          ], decimals: 0),
    },
    'weeksTo': <String, Object?>{
      for (final level in milestoneLevels)
        'l$level': <String, Object?>{
          'reached': runs.where((r) => r.weekOfLevel[level] != null).length,
          ..._spread(<int>[
            for (final r in runs)
              if (r.weekOfLevel[level] != null) r.weekOfLevel[level]!,
          ]),
        },
    },
    'xpTotal': _spread(xpTotal, decimals: 0),
    'xpPerWeek': roundTo(_mean(xpTotal) / weeks, 1),
    'xpShare': <String, Object?>{
      for (final s in sources)
        s: roundTo(
          sumXp <= 0
              ? 0
              : _mean(<int>[for (final r in runs) r.xpBySource[s] ?? 0]) *
                    n /
                    sumXp,
          3,
        ),
    },
    'kredits': _spread(<int>[for (final r in runs) r.kredits], decimals: 0),
    'kreditsBySource': <String, Object?>{
      for (final s in <String>[
        'quest',
        'chest',
        'level_up',
        'milestone',
        'record',
      ])
        s: roundTo(
          _mean(<int>[for (final r in runs) r.kreditsBySource[s] ?? 0]),
          0,
        ),
    },
    'quests': <String, Object?>{
      for (final k in kinds)
        k: <String, Object?>{
          'created': roundTo(
            _mean(<int>[for (final r in runs) r.questsCreated[k] ?? 0]),
            1,
          ),
          'done': roundTo(
            _mean(<int>[for (final r in runs) r.questsDone[k] ?? 0]),
            1,
          ),
          'rate': roundTo(
            _mean(<int>[for (final r in runs) r.questsDone[k] ?? 0]) /
                (_mean(<int>[for (final r in runs) r.questsCreated[k] ?? 0]) +
                    1e-9),
            3,
          ),
        },
    },
    'weeks': <String, Object?>{
      'success': roundTo(_mean(<int>[for (final r in runs) r.weeksSuccess]), 1),
      'missed': roundTo(_mean(<int>[for (final r in runs) r.weeksFailed]), 1),
      'paused': roundTo(_mean(<int>[for (final r in runs) r.weeksPaused]), 1),
    },
    'bestStreak': _spread(<int>[
      for (final r in runs) r.bestStreak,
    ], decimals: 0),
    'grades': <String, Object?>{
      for (final g in <String>['s', 'a', 'b', 'c'])
        g: roundTo(
          gradeTotal <= 0
              ? 0
              : _mean(<int>[for (final r in runs) r.grades[g] ?? 0]) /
                    gradeTotal,
          3,
        ),
    },
    'chests': <String, Object?>{
      'perRun': _spread(<int>[for (final r in runs) r.chests], decimals: 0),
      'sessionsPerChest': roundTo(
        _mean(<int>[for (final r in runs) r.paidSessions]) /
            (_mean(<int>[for (final r in runs) r.chests]) + 1e-9),
        2,
      ),
      'longestGap': maxGap,
    },
    'records': roundTo(_mean(<int>[for (final r in runs) r.records]), 1),
    'rankUps': roundTo(_mean(<int>[for (final r in runs) r.rankUps]), 1),
    'attributes': <Object?>[
      for (var i = 0; i < 6; i++)
        roundTo(
          quantileOf(<double>[
            for (final r in runs)
              if (r.attributes.length > i) r.attributes[i],
          ], 0.5),
          1,
        ),
    ],
    'attributeBests': <Object?>[
      for (var i = 0; i < 6; i++)
        roundTo(
          quantileOf(<double>[
            for (final r in runs)
              if (r.attributeBests.length > i) r.attributeBests[i],
          ], 0.5),
          1,
        ),
    ],
    'guards': <String, Object?>{
      'painSessions': roundTo(
        _mean(<int>[for (final r in runs) r.painSessions]),
        1,
      ),
      'extraSessions': roundTo(
        _mean(<int>[for (final r in runs) r.extraSessions]),
        1,
      ),
      'xpForPainOrExtra': runs.fold<int>(0, (s, r) => s + r.painXp),
      'worstWeekShare': roundTo(worst, 3),
      'levelDropped': dropped,
    },
    'ledgerEntries': roundTo(
      _mean(<int>[for (final r in runs) r.ledgerEntries]),
      0,
    ),
    'curve': curve,
  };
}
