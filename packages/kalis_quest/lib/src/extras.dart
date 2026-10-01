/// Données de présentation de `QuestOutcome.extras` (D8.1) : série de
/// semaines et taille de la flamme, récapitulatif hebdomadaire façon
/// story, comparaisons dans le temps, fantôme, détail des rangs, notes des
/// dernières séances, prédictions. Format décrit dans `docs/EXTRAS.md`.
library;

import 'package:kalis_core/kalis_core.dart';

import 'goals.dart';
import 'grade.dart';
import 'ledger.dart';
import 'level.dart';
import 'numeric.dart';
import 'progress.dart';
import 'standards.dart';
import 'world.dart';

/// Version du format de `extras`.
const int extrasSchema = 1;

String _iso(int day) => CivilDate.fromDayNumber(day).iso;

/// Taille de la flamme (0 à 10) pour une série de [weeks] semaines.
int flameSizeOf(int weeks, List<int> thresholds) {
  var size = 0;
  for (final t in thresholds) {
    if (weeks >= t) {
      size++;
    }
  }
  return size;
}

Map<String, Object?> _setJson(SetRecord s) => <String, Object?>{
  if (s.externalLoadKg != null) 'loadKg': s.externalLoadKg,
  if (s.reps != null) 'reps': s.reps,
  if (s.seconds != null) 'seconds': s.seconds,
  if (s.distanceMeters != null) 'distanceMeters': s.distanceMeters,
  if (s.flames != null) 'flames': s.flames,
};

Map<String, Object?> _ghostSession(SessionFacts f, String exerciseId) =>
    <String, Object?>{
      'date': f.session.date.iso,
      'sessionId': f.session.id,
      'score': roundTo(f.scoreByExercise[exerciseId] ?? 0, 1),
      'sets': <Object?>[
        for (final s in f.session.sets)
          if (s.exerciseId == exerciseId &&
              s.isUsable &&
              s.kind != SetKind.warmup)
            _setJson(s),
      ],
    };

Map<String, Object?> _ghost(World w) {
  final p = w.params;
  final wanted = <String>[];
  final prescription = w.prescriptionOn(w.today);
  if (prescription != null) {
    for (final item in prescription.items) {
      if (!wanted.contains(item.exerciseId)) {
        wanted.add(item.exerciseId);
      }
    }
  }
  for (var i = w.facts.length - 1; i >= 0; i--) {
    final f = w.facts[i];
    if (w.today - f.day > p.ghostWindowDays ||
        wanted.length >= p.ghostMaxExercises) {
      break;
    }
    final ids = f.scoreByExercise.keys.toList()..sort();
    for (final id in ids) {
      if (!wanted.contains(id) && wanted.length < p.ghostMaxExercises) {
        wanted.add(id);
      }
    }
  }
  final last = <String, SessionFacts>{};
  final best = <String, SessionFacts>{};
  for (final f in w.facts) {
    if (f.painZone != null) {
      continue;
    }
    for (final entry in f.scoreByExercise.entries) {
      last[entry.key] = f;
      final b = best[entry.key];
      if (b == null || entry.value > (b.scoreByExercise[entry.key] ?? 0)) {
        best[entry.key] = f;
      }
    }
  }
  wanted.sort();
  final out = <String, Object?>{};
  for (final id in wanted) {
    final l = last[id];
    final b = best[id];
    if (l == null || b == null) {
      continue;
    }
    out[id] = <String, Object?>{
      'last': _ghostSession(l, id),
      'best': _ghostSession(b, id),
    };
  }
  return out;
}

Map<String, Object?> _window(World w, int from, int to) {
  var sessions = 0;
  var sets = 0;
  var volume = 0.0;
  for (final f in w.factsIn(from, to)) {
    if (f.workSets == 0) {
      continue;
    }
    sessions++;
    sets += f.workSets;
    volume += f.volumeKg;
  }
  final weeks = (to - from + 1) / 7;
  return <String, Object?>{
    'sessionsPerWeek': roundTo(sessions / weeks, 2),
    'workSetsPerWeek': roundTo(sets / weeks, 1),
    'volumeKgPerWeek': roundTo(volume / weeks, 0),
  };
}

List<Object?> _comparisons(World w) {
  final p = w.params;
  final span = p.comparisonWindowDays;
  final nowFrom = w.today - span + 1;
  final out = <Object?>[];
  final first = w.facts.isEmpty ? w.today : w.facts.first.day;
  for (final back in p.comparisonDays) {
    final thenTo = w.today - back;
    final thenFrom = thenTo - span + 1;
    final available = first <= thenTo;
    final exercises = <Object?>[];
    if (available) {
      final keys = w.series.keys.toList()..sort();
      final rows = <(double, Map<String, Object?>)>[];
      for (final key in keys) {
        final cut = key.indexOf('|');
        final kind = key.substring(cut + 1);
        final lower = kind == RecordKind.timeSeconds.code;
        double? now;
        double? then;
        for (final o in w.series[key]!) {
          bool better(double? old) =>
              old == null || (lower ? o.value < old : o.value > old);
          if (o.day >= nowFrom && o.day <= w.today && better(now)) {
            now = o.value;
          }
          if (o.day >= thenFrom && o.day <= thenTo && better(then)) {
            then = o.value;
          }
        }
        if (now == null || then == null || then <= 0 || now <= 0) {
          continue;
        }
        final change = lower ? then / now - 1 : now / then - 1;
        rows.add((
          change,
          <String, Object?>{
            'exerciseId': key.substring(0, cut),
            'kind': kind,
            'now': now,
            'then': then,
            'change': roundTo(change, 4),
          },
        ));
      }
      rows.sort((a, b) {
        final c = b.$1.compareTo(a.$1);
        return c != 0
            ? c
            : (a.$2['exerciseId']! as String).compareTo(
                b.$2['exerciseId']! as String,
              );
      });
      for (final row in rows.take(5)) {
        exercises.add(row.$2);
      }
    }
    out.add(<String, Object?>{
      'daysAgo': back,
      'available': available,
      'now': _window(w, nowFrom, w.today),
      if (available) 'then': _window(w, thenFrom, thenTo),
      'exercises': exercises,
    });
  }
  return out;
}

Map<String, Object?> _recap(
  World w,
  Ledger ledger,
  LevelCurve curve,
  int monday,
  WeekSummary? summary,
) {
  final to = monday + 6;
  var xpBefore = 0;
  var xpIn = 0;
  var quests = 0;
  for (final e in ledger.xp) {
    final d = e.date.dayNumber;
    if (d < monday) {
      xpBefore += e.amount;
    } else if (d <= to) {
      xpIn += e.amount;
      if (e.source == XpSource.quest) {
        quests++;
      }
    }
  }
  var kredits = 0;
  var chests = 0;
  for (final e in ledger.kredits) {
    final d = e.date.dayNumber;
    if (d >= monday && d <= to) {
      kredits += e.amount;
      if (e.source == KreditSource.chest) {
        chests++;
      }
    }
  }
  var sessions = 0;
  var sets = 0;
  var volume = 0.0;
  final grades = <String, int>{'s': 0, 'a': 0, 'b': 0, 'c': 0};
  final records = <(double, Map<String, Object?>)>[];
  for (final f in w.factsIn(monday, to)) {
    final status = ledger.statusOf(f.session.id);
    if (f.workSets == 0) {
      continue;
    }
    sessions++;
    sets += f.workSets;
    volume += f.volumeKg;
    if (status != SessionStatus.paid) {
      continue;
    }
    if (f.completion >= w.params.doneCompletion) {
      final mark = markOf(f, w.params);
      grades.update(mark.grade.code, (n) => n + 1);
    }
    for (final r in f.records) {
      if (r.previous == null || !w.catalog.contains(r.exerciseId)) {
        continue;
      }
      records.add((
        r.gain,
        <String, Object?>{
          'exerciseId': r.exerciseId,
          'kind': r.kind.code,
          'value': r.value,
          'previous': r.previous,
          'gain': roundTo(r.gain, 4),
        },
      ));
    }
  }
  records.sort((a, b) {
    final c = b.$1.compareTo(a.$1);
    return c != 0
        ? c
        : (a.$2['exerciseId']! as String).compareTo(
            b.$2['exerciseId']! as String,
          );
  });
  String? bestGrade;
  for (final g in <String>['s', 'a', 'b', 'c']) {
    if (grades[g]! > 0) {
      bestGrade = g;
      break;
    }
  }
  return <String, Object?>{
    'monday': _iso(monday),
    'closed': summary != null,
    if (summary != null)
      'status': switch (summary.status) {
        WeekSummary.success => 'success',
        WeekSummary.paused => 'paused',
        _ => 'incomplete',
      },
    if (summary != null) 'sessionsPlanned': summary.planned,
    if (summary != null) 'sessionsDone': summary.done,
    'sessions': sessions,
    'workSets': sets,
    'volumeKg': roundTo(volume, 0),
    'xp': xpIn,
    'kredits': kredits,
    'chests': chests,
    'questsCompleted': quests,
    'levelFrom': LevelCurve.ordinal(curve.stateOf(xpBefore)),
    'levelTo': LevelCurve.ordinal(curve.stateOf(xpBefore + xpIn)),
    'grades': grades,
    if (bestGrade != null) 'bestGrade': bestGrade,
    'records': <Object?>[
      for (final r in records.take(w.params.recapTopRecords)) r.$2,
    ],
  };
}

Map<String, Object?> _rankDetails(List<RankResult> ranks) {
  final out = <String, Object?>{};
  for (final r in ranks) {
    out[r.movement.id] = <String, Object?>{
      'measure': r.movement.measure.name,
      'points': roundTo(r.points, 3),
      'current': roundTo(r.current, 3),
      if (r.value != null) 'value': r.value,
      if (r.valueExerciseId != null) 'valueExerciseId': r.valueExerciseId,
      if (r.nextValue != null) 'nextValue': r.nextValue,
      if (r.nextExerciseId != null) 'nextExerciseId': r.nextExerciseId,
    };
  }
  return out;
}

Map<String, Object?> _rankOf(World w) {
  final ids = <String>{};
  final block = w.input.block;
  if (block != null) {
    for (final d in block.pass1.days) {
      for (final s in d.slots) {
        ids.add(s.exerciseId);
      }
    }
  }
  for (final f in w.factsIn(w.today - 27, w.today)) {
    ids.addAll(f.scoreByExercise.keys);
  }
  final sorted = ids.toList()..sort();
  final out = <String, Object?>{};
  for (final id in sorted) {
    final carrier = Standards.carrierOf(w.catalog, id);
    if (carrier != null) {
      out[id] = carrier.id;
    }
  }
  return out;
}

/// Construit `QuestOutcome.extras`.
Map<String, Object?> buildExtras({
  required World w,
  required Ledger ledger,
  required MachineState st,
  required LevelCurve curve,
  required List<RankResult> ranks,
  required List<GoalResult> goals,
}) {
  final p = w.params;
  final today = w.today;
  final monday = mondayOf(today);
  final from = monday > st.startedOn ? monday : st.startedOn;
  final planned = w.scheduledIn(from, monday + 6, skipBreaks: true);
  var done = 0;
  for (final f in w.factsIn(from, today)) {
    if (ledger.statusOf(f.session.id) == SessionStatus.paid &&
        f.completion >= p.doneCompletion) {
      done++;
    }
  }
  final needed =
      (planned * p.streakNumerator + p.streakDenominator - 1) ~/
      p.streakDenominator;
  final lastWeek = st.weeks.isEmpty ? null : st.weeks.last;

  // Rythme d'XP des 28 derniers jours et date du prochain niveau.
  var recentXp = 0;
  for (var i = ledger.xp.length - 1; i >= 0; i--) {
    final e = ledger.xp[i];
    if (today - e.date.dayNumber >= 28) {
      break;
    }
    recentXp += e.amount;
  }
  final level = curve.stateOf(ledger.totalXp);
  final perDay = recentXp / 28;
  final toNext = level.xpForNextLevel - level.xpIntoLevel;
  final nextLevelDays = perDay <= 0 ? null : (toNext / perDay).ceil();

  final grades = <Object?>[];
  for (var i = w.facts.length - 1; i >= 0 && grades.length < 10; i--) {
    final f = w.facts[i];
    if (ledger.statusOf(f.session.id) != SessionStatus.paid ||
        f.completion < p.doneCompletion) {
      continue;
    }
    final mark = markOf(f, p);
    grades.add(<String, Object?>{
      'sessionId': f.session.id,
      'date': f.session.date.iso,
      'grade': mark.grade.code,
      'score': mark.score,
      'combo': f.combo,
    });
  }

  final goalExtras = <String, Object?>{};
  for (final g in goals) {
    if (g.goal.kind != GoalKind.performance) {
      continue;
    }
    final created = g.goal.createdOn.dayNumber;
    final deadline = g.goal.targetDate?.dayNumber ?? created;
    final span = deadline - created;
    goalExtras[g.goal.id] = <String, Object?>{
      'expectedMilestoneDates': <Object?>[
        for (var i = 1; i <= 4; i++) _iso(created + (span * i / 4).round()),
      ],
      'ambition': roundTo(g.ambition, 3),
    };
  }

  return <String, Object?>{
    'schema': extrasSchema,
    'startedOn': _iso(st.startedOn),
    'streak': <String, Object?>{
      'current': st.streak,
      'best': st.bestStreak,
      'flameSize': flameSizeOf(st.streak, p.flameSizeWeeks),
      'lastWeek': lastWeek == null
          ? 'none'
          : switch (lastWeek.status) {
              WeekSummary.success => 'success',
              WeekSummary.paused => 'paused',
              _ => 'incomplete',
            },
      'week': <String, Object?>{
        'monday': _iso(monday),
        'planned': planned,
        'done': done > planned ? planned : done,
        'needed': needed,
      },
    },
    'recap': <String, Object?>{
      if (lastWeek != null)
        'lastWeek': _recap(w, ledger, curve, lastWeek.monday, lastWeek),
      'thisWeek': _recap(w, ledger, curve, monday, null),
    },
    'comparisons': _comparisons(w),
    'ghost': _ghost(w),
    'ranks': _rankDetails(ranks),
    'rankOf': _rankOf(w),
    'grades': grades,
    'goals': goalExtras,
    'level': <String, Object?>{
      'xpPerWeek': roundTo(perDay * 7, 1),
      if (nextLevelDays != null) 'nextLevelOn': _iso(today + nextLevelDays),
    },
    'totals': <String, Object?>{
      'sessions': st.sessions,
      'chests': st.chests,
      'questsDone': <String, Object?>{
        for (final k in st.questsDone.keys.toList()..sort())
          k: st.questsDone[k],
      },
    },
  };
}
