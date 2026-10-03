/// Relecture d'un programme du chemin street : les invariants de sécurité
/// revérifiés sur le programme rendu (passes 1 et 2), sans rien savoir de
/// la façon dont il a été construit. Sert aux tests de propriétés et à
/// l'inspecteur du mode dev (CONTRAT.md, § 12).
library;

import 'package:kalis_core/kalis_core.dart';

import '../traits.dart';
import 'athlete.dart';
import 'prescribe.dart';
import 'skeleton.dart' show coachStraightArmDays;

/// Plafond de séries dures par groupe et par semaine du référentiel
/// (R1-P1), par niveau.
const List<double> auditWeeklyCeiling = <double>[12, 20, 25, 30];

/// Niveau minimal d'une technique d'intensification (R2-P22).
const Map<SetTechniqueKind, int> auditTechniqueMinLevel =
    <SetTechniqueKind, int>{
      SetTechniqueKind.topSetBackoff: 1,
      SetTechniqueKind.dropSet: 1,
      SetTechniqueKind.amrap: 1,
      SetTechniqueKind.cluster: 2,
      SetTechniqueKind.restPause: 2,
      SetTechniqueKind.myoReps: 2,
      SetTechniqueKind.accentuatedEccentric: 2,
      SetTechniqueKind.contrast: 2,
      SetTechniqueKind.wave: 2,
    };

double? _rirOf(ExercisePrescription p) {
  final flames = p.targetFlames;
  return flames == null || !Flames.isValid(flames)
      ? null
      : Flames.toRir(flames);
}

bool _light(WeekKind kind) =>
    kind == WeekKind.intro || kind == WeekKind.deload || kind == WeekKind.test;

double _limit(
  List<double> series,
  List<bool> light,
  int index,
  double rise,
  double tolerance,
) {
  var loaded = 0.0;
  var easy = 0.0;
  var anyLoaded = false;
  for (var k = index - 3; k < index; k++) {
    if (k < 0) {
      continue;
    }
    if (light[k]) {
      if (series[k] > easy) {
        easy = series[k];
      }
    } else {
      anyLoaded = true;
      if (series[k] > loaded) {
        loaded = series[k];
      }
    }
  }
  double step(double reference) {
    final relative = reference * (1 + rise);
    final absolute = reference + tolerance;
    return relative > absolute ? relative : absolute;
  }

  if (anyLoaded) {
    return step(loaded > easy ? loaded : easy);
  }
  final stepped = step(easy);
  final resumed = easy / 0.5;
  return stepped > resumed ? stepped : resumed;
}

/// Durée estimée de la séance [day], en secondes (mêmes conventions que le
/// banc : 3 s par répétition, 45 s de transition, repos entre les séries,
/// l'échauffement général de `coachWarmupFor` dès qu'il y a du
/// renforcement).
double coachSessionSeconds(
  Catalog catalog,
  DayPrescription day, {
  int minutes = 60,
}) {
  final traits = CatalogTraits.of(catalog);
  var total = 0.0;
  var resistance = false;
  for (final p in day.items) {
    final t = traits.find(p.exerciseId);
    if (t == null) {
      continue;
    }
    final e = t.exercise;
    final sides = e.laterality == Laterality.bilateral ? 1 : 2;
    final isResistance = t.kind.isResistance;
    double effort;
    final reps = p.repsHigh ?? p.repsLow;
    final seconds = p.secondsHigh ?? p.secondsLow;
    final meters = p.distanceMeters;
    final calories = p.calories;
    if (reps != null) {
      effort = reps * coachSecondsPerRep * sides;
    } else if (seconds != null) {
      effort = seconds.toDouble() * (isResistance ? sides : 1);
    } else if (meters != null) {
      effort = meters / coachRunMetersPerSecond;
    } else if (calories != null) {
      effort = calories * 6;
    } else {
      effort = 30;
    }
    total +=
        coachTransitionSeconds +
        p.sets * effort +
        (p.sets - 1) * (p.restSeconds ?? 60);
    resistance = resistance || isResistance;
  }
  return total + (resistance ? coachWarmupFor(minutes) : 0);
}

/// Manquements du programme [blocks] (blocs enchaînés du profil [profile],
/// le premier commençant le [start]) aux invariants du chemin street ;
/// liste vide si tout est conforme.
///
/// Invariants relus : exercice admissible pour le profil (matériel, zone à
/// ménager, niveau, prérequis, exclusions) ; technique réservée à son
/// niveau ; au moins 2 répétitions en réserve sur un mouvement à risque et
/// chez le débutant ; reprise à 3 répétitions en réserve au moins ;
/// plafond et montée du volume par groupe ; montée des tenues bras tendus
/// et nombre de séances bras tendus ; hausse de charge à répétitions
/// égales ; durée des séances ; affûtage la semaine de l'échéance.
List<String> coachAudit(
  Catalog catalog,
  AthleteProfile profile,
  CivilDate start,
  List<ProgramBlock> blocks, {
  Set<String> imposedSlotIds = const <String>{},
}) {
  final out = <String>[];
  final traits = CatalogTraits.of(catalog);
  final a = Athlete.read(catalog, profile, start);
  final level = a.level;
  final bodyWeight = a.bodyWeight;

  final groups = <List<double>>[];
  final arms = <List<double>>[];
  final light = <bool>[];
  final hard = <double>[];
  final who = <List<(List<double>, String)>>[];
  final lastLoad = <String, (int, double, int)>{};
  var global = 0;
  int? eventWeek;
  for (final block in blocks) {
    final pass1 = block.pass1;
    final blockStart = pass1.startDate;
    final athlete = Athlete.read(catalog, profile, blockStart);
    final target = pass1.intent?.eventId;
    final weeksToEvent = pass1.intent?.weeksToEvent;
    if (target != null &&
        weeksToEvent != null &&
        weeksToEvent >= 1 &&
        weeksToEvent <= pass1.weeks) {
      eventWeek = global + weeksToEvent - 1;
    }
    for (final week in block.pass2.weeks) {
      final g = List<double>.filled(MuscleGroup.values.length, 0);
      final s = <double>[0, 0, 0];
      final armDays = <Set<int>>[<int>{}, <int>{}, <int>{}];
      final names = <(List<double>, String)>[];
      var hardSets = 0.0;
      for (final day in week.days) {
        final d = day.dayIndex;
        final where = 'bloc ${pass1.blockIndex} s${week.weekIndex} j$d';
        if (d >= athlete.dayCount) {
          out.add('$where : jour inconnu');
          continue;
        }
        if (day.items.isEmpty) {
          out.add('$where : séance vide');
        }
        final seconds = coachSessionSeconds(
          catalog,
          day,
          minutes: athlete.days[d].minutes,
        );
        final budget = athlete.days[d].minutes * 60.0;
        if (seconds > budget * 1.15 + 180 &&
            !day.items.any((p) => imposedSlotIds.contains(p.slotId))) {
          out.add(
            '$where : ${(seconds / 60).round()} min pour '
            '${athlete.days[d].minutes}',
          );
        }
        for (final p in day.items) {
          final t = traits.find(p.exerciseId);
          if (t == null) {
            out.add('$where : ${p.exerciseId} inconnu');
            continue;
          }
          final e = t.exercise;
          final imposed = imposedSlotIds.contains(p.slotId);
          if (!imposed) {
            final why = athlete.rejection(e.id, d);
            if (why != null) {
              out.add('$where : ${e.id} inadmissible ($why)');
            }
          }
          final technique = p.technique;
          if (technique != null) {
            final min = auditTechniqueMinLevel[technique.kind];
            if (min != null && level < min) {
              out.add('$where : ${technique.kind.code} au niveau $level');
            }
          }
          final rir = _rirOf(p);
          final resistance = t.kind.isResistance;
          final work = p.kind != SetKind.warmup && p.kind != SetKind.test;
          if (resistance && work && rir != null) {
            if (rir < 2 - 1e-9 && (coachHighRisk(e) || level == 0)) {
              out.add('$where : ${e.id} à $rir en réserve');
            }
            if (pass1.blockIndex == 0 &&
                week.weekIndex == 0 &&
                a.gapWeeks >= 2 &&
                rir < 3 - 1e-9) {
              out.add('$where : reprise à $rir en réserve sur ${e.id}');
            }
            for (final l in athlete.limits) {
              final joint = l.joint;
              if (joint != null &&
                  !imposed &&
                  e.stressOn(joint) == JointStress.high &&
                  (l.recent || l.discomfort >= 2) &&
                  rir < 1 - 1e-9) {
                out.add('$where : ${e.id} à $rir sur une zone à ménager');
              }
            }
          }
          final isHard =
              resistance &&
              p.kind != SetKind.warmup &&
              (rir == null || rir <= coachHardSetMaxRir);
          if (isHard) {
            hardSets += p.sets;
            names.add((
              <double>[
                for (final group in MuscleGroup.values) t.creditOf(group),
              ],
              '${e.id}×${p.sets}'
                  '${p.kind == SetKind.test ? ' (test)' : ''} j$d '
                  '${week.kind.code}',
            ));
            for (final group in MuscleGroup.values) {
              g[group.index] += p.sets * t.creditOf(group) / 2;
            }
          }
          final family = straightArmFamilyOf(e);
          final hold = p.secondsHigh ?? p.secondsLow;
          if (family >= 0 && hold != null && resistance) {
            s[family] += p.sets * hold.toDouble();
            armDays[family].add(d);
          }
          final load = p.startLoadKg;
          final reps = p.repsHigh ?? p.repsLow;
          if (load != null && reps != null && p.kind != SetKind.test) {
            final total =
                load + (e.bodyweightFraction?.value ?? 0) * bodyWeight;
            final key = '$d|${p.slotId}|${e.id}';
            final before = lastLoad[key];
            if (total > 0) {
              if (before != null &&
                  before.$1 == global - 1 &&
                  before.$3 == reps &&
                  total / before.$2 - 1 > coachLoadRise[level] + 1e-9) {
                out.add(
                  '$where : ${e.id} +'
                  '${((total / before.$2 - 1) * 100).toStringAsFixed(1)} %',
                );
              }
              lastLoad[key] = (global, total, reps);
            }
          }
          final pct = p.percentOfOneRm;
          if (pct != null && (pct <= 0 || pct > 1)) {
            out.add('$where : ${e.id} à $pct du 1RM');
          }
        }
      }
      for (var family = 0; family < 3; family++) {
        if (armDays[family].length > coachStraightArmDays[level]) {
          out.add(
            'bloc ${pass1.blockIndex} s${week.weekIndex} : '
            '${armDays[family].length} séances bras tendus (famille $family)',
          );
        }
      }
      groups.add(g);
      who.add(names);
      arms.add(s);
      light.add(_light(week.kind));
      hard.add(hardSets);
      global++;
    }
  }

  final ceiling = auditWeeklyCeiling[level];
  for (final group in MuscleGroup.values) {
    if (!group.major) {
      continue;
    }
    final series = <double>[for (final g in groups) g[group.index]];
    for (var w = 0; w < series.length; w++) {
      if (series[w] > ceiling + 1e-9) {
        out.add('s$w : ${group.code} ${series[w]} séries (plafond $ceiling)');
      }
      if (w == 0) {
        continue;
      }
      final limit = _limit(series, light, w, coachVolumeRise, 2);
      if (series[w] > limit + 1e-9) {
        out.add(
          's$w : ${group.code} ${series[w]} séries pour $limit — '
          '${<String>[for (final (c, n) in who[w])
            if (c[group.index] > 0) n].join(', ')}',
        );
      } else if (w > 1 &&
          !light[w] &&
          !light[w - 1] &&
          !light[w - 2] &&
          series[w - 2] > 0) {
        final before = series[w - 2];
        final two = before * 1.3 > before + 4 ? before * 1.3 : before + 4;
        if (series[w] > two + 1e-9) {
          out.add('s$w : ${group.code} ${series[w]} séries pour $two (2 sem.)');
        }
      }
    }
  }
  for (var family = 0; family < 3; family++) {
    final series = <double>[for (final s in arms) s[family]];
    for (var w = 1; w < series.length; w++) {
      final limit = _limit(series, light, w, coachStraightArmRise[level], 5);
      if (series[w] > limit + 1e-9) {
        out.add(
          's$w : bras tendus (famille $family) ${series[w]} s pour $limit',
        );
      }
    }
  }
  // Affûtage : la semaine de l'échéance est allégée d'au moins 30 % (40 %
  // à partir du niveau avancé) par rapport au pic des six semaines
  // précédentes (R3-P12, R3-P21).
  final at = eventWeek;
  if (at != null && at < hard.length && at > 0) {
    var peak = 0.0;
    for (var k = at - 6; k < at; k++) {
      if (k >= 0 && hard[k] > peak) {
        peak = hard[k];
      }
    }
    final drop = level >= 2 ? 0.40 : 0.30;
    if (peak >= 10 && hard[at] > peak * (1 - drop) + 1e-9) {
      out.add(
        's$at : échéance à ${hard[at]} séries dures pour un pic de $peak',
      );
    }
  }
  return out;
}
