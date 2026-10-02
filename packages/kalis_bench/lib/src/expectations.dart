/// Attentes de coach vérifiables : chaque profil du banc déclare ce qu'un
/// excellent programme doit contenir pour lui (`expectations.checks`) ; le
/// banc dit lesquelles sont tenues. Types : `docs/PROFILS.md`, § Attentes.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'analysis.dart';
import 'profile.dart';
import 'safety.dart' show SafetyLimits;

/// Résultat d'une attente.
final class CheckResult {
  /// Résultat de l'attente [check].
  const CheckResult(this.check, this.ok, this.observed);

  /// Attente.
  final BenchCheck check;

  /// Tenue ou non.
  final bool ok;

  /// Ce que le banc a mesuré, en français.
  final String observed;

  /// Objet JSON du résultat.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': check.id,
    'type': check.type,
    'label': check.label,
    'ok': ok,
    'observed': observed,
  };
}

/// Types d'attente connus.
const Set<String> checkTypes = <String>{
  'min_frequency',
  'max_frequency',
  'has_taper',
  'test_at_event',
  'relief_every',
  'min_group_sets',
  'max_group_sets',
  'min_weekly_minutes',
  'max_session_minutes',
  'pattern_present',
  'forbid_patterns',
  'forbid_exercises',
  'forbid_joint_stress',
  'format_present',
  'load_prescribed',
  'heavy_exposure',
  'min_rir_first_weeks',
  'max_exercise_level',
  'priority_share',
  'weekly_sets_between',
  'short_rest_share',
  'straight_arm_days_max',
  'distinct_week_types',
  'weeks_kind_present',
};

double _mean(Iterable<double> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

MuscleGroup _group(String code) {
  for (final g in MuscleGroup.values) {
    if (g.code == code) {
      return g;
    }
  }
  throw FormatException('groupe musculaire inconnu', code);
}

Set<MovementPattern> _patterns(Map<String, Object?> params) => <MovementPattern>{
  for (final code in benchStrings(params, 'patterns'))
    MovementPattern.fromCode(code),
};

String _f(double v) => v.toStringAsFixed(1);

/// Évalue l'attente [check] sur le programme lu [view].
///
/// [FormatException] si le type est inconnu ou un paramètre manque.
CheckResult evaluateCheck(
  ProgramView view,
  BenchProfile profile,
  BenchCheck check,
) {
  final p = check.params;
  final weeks = view.weeks;
  final build = view.buildWeeks;
  CheckResult result(bool ok, String observed) =>
      CheckResult(check, ok, observed);

  switch (check.type) {
    case 'min_frequency':
    case 'max_frequency':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final exact = p['exact'] == true;
      final freq = _mean(
        build.map(
          (w) => w.daysWith(ids, exact ? const <String>{} : roots).toDouble(),
        ),
      );
      final bound = benchDouble(p, 'perWeek');
      final ok = check.type == 'min_frequency'
          ? freq >= bound - 1e-9
          : freq <= bound + 1e-9;
      return result(ok, '${_f(freq)} séance(s) par semaine en montée');

    case 'has_taper':
      final event = profile.mainEvent;
      if (event == null || event.weeksOut - 1 >= weeks.length) {
        return result(false, "pas de semaine d'échéance dans le programme");
      }
      final at = event.weeksOut - 1;
      var peak = 0.0;
      for (var k = at - 6; k < at; k++) {
        if (k >= 0 && weeks[k].hardSets > peak) {
          peak = weeks[k].hardSets;
        }
      }
      final drop = peak <= 0 ? 0.0 : 1 - weeks[at].hardSets / peak;
      final low = benchDouble(p, 'minDrop');
      final high = benchDoubleOrNull(p, 'maxDrop') ?? 1;
      return result(
        drop >= low - 1e-9 && drop <= high + 1e-9,
        'volume ${(drop * 100).round()} % sous le pic la semaine de '
        "l'échéance",
      );

    case 'test_at_event':
      final event = profile.mainEvent;
      if (event == null || event.weeksOut - 1 >= weeks.length) {
        return result(false, "pas de semaine d'échéance dans le programme");
      }
      final week = weeks[event.weeksOut - 1];
      final (ids, roots) = view.chainOf(<String>[
        for (final t in event.targets) t.exerciseId,
      ]);
      var tested = 0;
      for (final i in week.items) {
        if (i.isTest &&
            (ids.contains(i.exercise.id) ||
                roots.contains(i.exercise.rootId))) {
          tested++;
        }
      }
      return result(
        tested > 0,
        '$tested épreuve(s) sur les mouvements visés la semaine de '
        "l'échéance (nature : ${week.kind.code})",
      );

    case 'relief_every':
      final limit = benchInt(p, 'weeks');
      var run = 0;
      var longest = 0;
      for (final w in weeks) {
        var reference = 0.0;
        for (var k = w.index - 3; k < w.index; k++) {
          if (k >= 0 && weeks[k].hardSets > reference) {
            reference = weeks[k].hardSets;
          }
        }
        final relieved =
            w.isLight ||
            (reference > 0 &&
                w.hardSets <= reference * SafetyLimits.reliefShare + 1e-9);
        run = relieved ? 0 : run + 1;
        if (run > longest) {
          longest = run;
        }
      }
      return result(
        longest <= limit,
        '$longest semaines de charge de suite au plus',
      );

    case 'min_group_sets':
    case 'max_group_sets':
      final group = _group(benchString(p, 'group'));
      final mean = _mean(build.map((w) => w.groupSets(group)));
      final bound = benchDouble(p, 'sets');
      final ok = check.type == 'min_group_sets'
          ? mean >= bound - 1e-9
          : mean <= bound + 1e-9;
      return result(ok, '${_f(mean)} séries dures par semaine en montée');

    case 'min_weekly_minutes':
      final kind = benchString(p, 'kind');
      final minutes = _mean(
        build.map((w) {
          var seconds = 0.0;
          for (final i in w.items) {
            final k = i.traits.kind;
            final match = switch (kind) {
              'cardio' => k.isCardio,
              'mobility' => k == SlotKind.mobility,
              'conditioning' => k == SlotKind.conditioning,
              _ => throw FormatException('kind inconnu', kind),
            };
            if (match) {
              seconds += i.estimatedSeconds;
            }
          }
          return seconds / 60;
        }),
      );
      return result(
        minutes >= benchDouble(p, 'minutes') - 1e-9,
        '${minutes.round()} min par semaine en montée',
      );

    case 'max_session_minutes':
      var longest = 0.0;
      for (final w in weeks) {
        for (final d in w.days) {
          if (d.estimatedMinutes > longest) {
            longest = d.estimatedMinutes;
          }
        }
      }
      return result(
        longest <= benchDouble(p, 'minutes') + 1e-9,
        'séance la plus longue : ${longest.round()} min estimées',
      );

    case 'pattern_present':
      final patterns = _patterns(p);
      final freq = _mean(
        build.map((w) {
          var days = 0;
          for (final d in w.days) {
            if (d.items.any((i) => patterns.contains(i.exercise.pattern))) {
              days++;
            }
          }
          return days.toDouble();
        }),
      );
      return result(
        freq >= benchDouble(p, 'perWeek') - 1e-9,
        '${_f(freq)} séance(s) par semaine en montée',
      );

    case 'forbid_patterns':
      final patterns = _patterns(p);
      final found = <String>{
        for (final w in weeks)
          for (final i in w.items)
            if (patterns.contains(i.exercise.pattern)) i.exercise.name,
      };
      return result(
        found.isEmpty,
        found.isEmpty ? 'aucun' : 'présents : ${found.join(', ')}',
      );

    case 'forbid_exercises':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final chain = p['chain'] == true;
      final found = <String>{
        for (final w in weeks)
          for (final i in w.items)
            if (ids.contains(i.exercise.id) ||
                (chain && roots.contains(i.exercise.rootId)))
              i.exercise.name,
      };
      return result(
        found.isEmpty,
        found.isEmpty ? 'aucun' : 'présents : ${found.join(', ')}',
      );

    case 'forbid_joint_stress':
      final joint = Joint.fromCode(benchString(p, 'joint'));
      final level = JointStress.fromCode(benchString(p, 'stress'));
      final found = <String>{
        for (final w in weeks)
          for (final i in w.items)
            if (i.exercise.stressOn(joint).index >= level.index)
              i.exercise.name,
      };
      return result(
        found.isEmpty,
        found.isEmpty ? 'aucun' : 'présents : ${found.join(', ')}',
      );

    case 'format_present':
      final formats = benchStrings(p, 'formats').toSet();
      final found = <String>{
        for (final w in weeks)
          for (final i in w.items)
            if (i.p.format != null && formats.contains(i.p.format))
              i.p.format!,
      };
      return result(
        found.isNotEmpty,
        found.isEmpty ? 'aucun de ces formats' : 'formats : ${found.join(', ')}',
      );

    case 'load_prescribed':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      var items = 0;
      var loaded = 0;
      for (final w in build) {
        for (final i in w.items) {
          if (ids.contains(i.exercise.id) ||
              roots.contains(i.exercise.rootId)) {
            items++;
            if (i.p.startLoadKg != null || i.p.percentOfOneRm != null) {
              loaded++;
            }
          }
        }
      }
      return result(
        items > 0 && loaded == items,
        '$loaded prescriptions chargées ou en % du 1RM sur $items',
      );

    case 'heavy_exposure':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final percent = benchDouble(p, 'minPercent');
      final maxReps = benchIntOrNull(p, 'maxReps') ?? 5;
      final freq = _mean(
        build.map((w) {
          var days = 0;
          for (final d in w.days) {
            if (d.items.any(
              (i) =>
                  (ids.contains(i.exercise.id) ||
                      roots.contains(i.exercise.rootId)) &&
                  ((i.p.percentOfOneRm ?? 0) >= percent - 1e-9 ||
                      (i.p.startLoadKg != null &&
                          i.isReps &&
                          i.repsHigh <= maxReps)),
            )) {
              days++;
            }
          }
          return days.toDouble();
        }),
      );
      return result(
        freq >= benchDouble(p, 'perWeek') - 1e-9,
        '${_f(freq)} exposition(s) lourde(s) par semaine en montée',
      );

    case 'min_rir_first_weeks':
      final count = benchInt(p, 'weeks');
      final bound = benchDouble(p, 'rir');
      var lowest = 10.0;
      for (final w in weeks.take(count)) {
        for (final i in w.items) {
          final r = i.rir;
          if (i.isResistance && !i.isTest && r != null && r < lowest) {
            lowest = r;
          }
        }
      }
      return result(
        lowest >= bound - 1e-9,
        'RIR le plus bas des $count premières semaines : ${_f(lowest)}',
      );

    case 'max_exercise_level':
      final max = ExerciseLevel.fromCode(benchString(p, 'level'));
      final found = <String>{
        for (final w in weeks)
          for (final i in w.items)
            if (i.isResistance && i.exercise.level.index > max.index)
              i.exercise.name,
      };
      return result(
        found.isEmpty,
        found.isEmpty ? 'aucun au-dessus' : 'au-dessus : ${found.join(', ')}',
      );

    case 'priority_share':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      var specific = 0.0;
      var all = 0.0;
      for (final w in build) {
        for (final i in w.items) {
          all += i.hardSets;
          if (ids.contains(i.exercise.id) ||
              roots.contains(i.exercise.rootId)) {
            specific += i.hardSets;
          }
        }
      }
      final share = all <= 0 ? 0.0 : specific / all;
      final low = benchDouble(p, 'minShare');
      final high = benchDoubleOrNull(p, 'maxShare') ?? 1;
      return result(
        share >= low - 1e-9 && share <= high + 1e-9,
        '${(share * 100).round()} % des séries dures en montée',
      );

    case 'weekly_sets_between':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final mean = _mean(
        build.map((w) {
          var sets = 0.0;
          for (final i in w.items) {
            if (ids.contains(i.exercise.id) ||
                roots.contains(i.exercise.rootId)) {
              sets += i.hardSets;
            }
          }
          return sets;
        }),
      );
      return result(
        mean >= benchDouble(p, 'min') - 1e-9 &&
            mean <= benchDouble(p, 'max') + 1e-9,
        '${_f(mean)} séries dures par semaine en montée',
      );

    case 'short_rest_share':
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final maxRest = benchInt(p, 'maxRestSeconds');
      var sets = 0.0;
      var dense = 0.0;
      for (final w in build) {
        for (final i in w.items) {
          if (ids.contains(i.exercise.id) ||
              roots.contains(i.exercise.rootId)) {
            sets += i.p.sets;
            final dense0 =
                (i.p.restSeconds ?? 9999) <= maxRest ||
                i.p.format == 'emom' ||
                i.p.format == 'amrap' ||
                i.p.format == 'rounds';
            if (dense0) {
              dense += i.p.sets;
            }
          }
        }
      }
      final share = sets <= 0 ? 0.0 : dense / sets;
      return result(
        share >= benchDouble(p, 'minShare') - 1e-9,
        '${(share * 100).round()} % des séries avec ${maxRest}s de repos '
        'ou moins (ou en format de densité)',
      );

    case 'straight_arm_days_max':
      var most = 0;
      for (final w in weeks) {
        for (final f in StraightArmFamily.values) {
          final d = w.straightArmDays(f);
          if (d > most) {
            most = d;
          }
        }
      }
      return result(
        most <= benchInt(p, 'days'),
        '$most jours par semaine au plus pour une même famille',
      );

    case 'distinct_week_types':
      // Ondulation : au moins `min` plages de répétitions distinctes par
      // semaine sur les mouvements cités.
      final (ids, roots) = view.chainOf(benchStrings(p, 'exerciseIds'));
      final mean = _mean(
        build.map((w) {
          final ranges = <String>{};
          for (final i in w.items) {
            if (i.isReps &&
                (ids.contains(i.exercise.id) ||
                    roots.contains(i.exercise.rootId))) {
              ranges.add('${i.repsLow}-${i.repsHigh}');
            }
          }
          return ranges.length.toDouble();
        }),
      );
      return result(
        mean >= benchDouble(p, 'min') - 1e-9,
        '${_f(mean)} plage(s) de répétitions distincte(s) par semaine',
      );

    case 'weeks_kind_present':
      final kind = WeekKind.fromCode(benchString(p, 'kind'));
      final count = weeks.where((w) => w.kind == kind).length;
      return result(
        count >= (benchIntOrNull(p, 'min') ?? 1),
        '$count semaine(s) de nature ${kind.code}',
      );
  }
  throw FormatException("type d'attente inconnu", check.type);
}

/// Résultats de toutes les attentes vérifiables du profil.
List<CheckResult> evaluateChecks(ProgramView view, BenchProfile profile) =>
    <CheckResult>[
      for (final c in profile.checks) evaluateCheck(view, profile, c),
    ];
