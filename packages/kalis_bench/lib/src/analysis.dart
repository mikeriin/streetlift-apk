/// Lecture d'un programme : chaque semaine, chaque séance, chaque exercice,
/// avec les grandeurs que les critères mesurent (séries dures par groupe
/// musculaire, charge totale, durée estimée, tenues bras tendus…).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'profile.dart';
import 'program.dart';

/// Poids de corps pris quand le profil ne le donne pas, en kg.
const double defaultBodyWeightKg = 75;

/// Secondes comptées par répétition (celle de `kalis_plan`).
const double secondsPerRep = 3;

/// Secondes de transition entre deux exercices.
const double transitionSeconds = 45;

/// Allure de course prise sans record de course, en m/s (course lente).
const double defaultRunMetersPerSecond = 2.5;

/// Part de l'allure du record prise pour estimer la durée d'une distance
/// (une sortie d'entraînement est plus lente que le record).
const double trainingPaceShare = 0.9;

/// Allure de course du profil [profile] : celle de son meilleur record
/// chronométré sur une distance, ramenée à [trainingPaceShare], sinon
/// [defaultRunMetersPerSecond].
double runSpeedOf(BenchProfile profile) {
  var best = 0.0;
  for (final r in profile.records) {
    final meters = r.distanceMeters;
    if (r.measure == LevelMeasure.timeSeconds &&
        meters != null &&
        r.value > 0) {
      final speed = meters / r.value;
      if (speed > best) {
        best = speed;
      }
    }
  }
  return best > 0 ? best * trainingPaceShare : defaultRunMetersPerSecond;
}

/// Plus grand RIR d'une série « dure » (référentiel, R1 : 0 à 4 RIR).
const double hardSetMaxRir = 4;

/// Famille de tenue bras tendus (même maillon tendineux).
enum StraightArmFamily {
  /// Poussée bras tendus : planche et ses paliers.
  push,

  /// Tirage bras tendus : front lever, back lever et leurs paliers.
  pull,

  /// Figures mixtes : drapeau.
  mixed,
}

/// Exercice prescrit, lu avec le catalogue.
final class ItemView {
  /// Exercice [p] de la semaine [week] (rang global), jour [dayIndex].
  ItemView({
    required this.week,
    required this.kind,
    required this.dayIndex,
    required this.p,
    required this.exercise,
    required this.traits,
    required this.role,
    required this.bodyWeightKg,
  });

  /// Rang global de la semaine (0 = première du programme).
  final int week;

  /// Nature de la semaine.
  final WeekKind kind;

  /// Jour d'entraînement.
  final int dayIndex;

  /// Prescription.
  final ExercisePrescription p;

  /// Exercice du catalogue.
  final CatalogExercise exercise;

  /// Traits de l'exercice (lecture de `kalis_plan`).
  final ExerciseTraits traits;

  /// Rôle dans la séance (semaine type), ou `null` pour un emplacement
  /// propre à la semaine.
  final SlotRole? role;

  /// Poids de corps de l'athlète.
  final double bodyWeightKg;

  /// Vrai pour une tenue ou un effort mesuré en secondes.
  bool get isTimed => p.secondsLow != null || p.secondsHigh != null;

  /// Vrai pour des répétitions.
  bool get isReps => p.repsLow != null || p.repsHigh != null;

  /// Haut de la plage de répétitions (0 hors répétitions).
  int get repsHigh => p.repsHigh ?? p.repsLow ?? 0;

  /// Bas de la plage de répétitions (0 hors répétitions).
  int get repsLow => p.repsLow ?? p.repsHigh ?? 0;

  /// Haut de la plage de temps, en secondes (0 hors temps).
  int get secondsHigh => p.secondsHigh ?? p.secondsLow ?? 0;

  /// Bas de la plage de temps, en secondes (0 hors temps).
  int get secondsLow => p.secondsLow ?? p.secondsHigh ?? 0;

  /// RIR visé, ou `null` sans cible de difficulté.
  double? get rir {
    final flames = p.targetFlames;
    return flames == null ? null : Flames.toRir(flames);
  }

  /// Vrai pour du renforcement (figures comprises).
  bool get isResistance => traits.kind.isResistance;

  /// Vrai pour une épreuve.
  bool get isTest => p.kind == SetKind.test;

  /// Vrai pour un échauffement.
  bool get isWarmup => p.kind == SetKind.warmup;

  /// Séries dures : séries de renforcement menées à [hardSetMaxRir] RIR ou
  /// moins (une série sans cible de difficulté compte).
  double get hardSets {
    if (!isResistance || isWarmup) {
      return 0;
    }
    final r = rir;
    if (r != null && r > hardSetMaxRir) {
      return 0;
    }
    return p.sets.toDouble();
  }

  /// Séries dures créditées au groupe [group] : 1 par série pour un muscle
  /// principal, 0,5 pour un muscle secondaire (comptage fractionné).
  double creditedSets(MuscleGroup group) =>
      hardSets * traits.creditOf(group) / 2;

  /// Fraction du poids de corps portée (0 pour une charge externe pure).
  double get bodyFraction => exercise.bodyweightFraction?.value ?? 0;

  /// Charge totale de départ (charge externe + part du poids de corps),
  /// ou `null` sans charge prescrite.
  double? get totalLoadKg {
    final load = p.startLoadKg;
    if (load == null) {
      return null;
    }
    return load + bodyFraction * bodyWeightKg;
  }

  /// Famille bras tendus de l'exercice, ou `null`.
  StraightArmFamily? get straightArm {
    switch (exercise.pattern) {
      case MovementPattern.figureStatiquePoussee:
        return StraightArmFamily.push;
      case MovementPattern.figureStatiqueTirage:
        return StraightArmFamily.pull;
      case MovementPattern.figureStatiqueMixte:
        return StraightArmFamily.mixed;
      default:
        return null;
    }
  }

  /// Secondes de tenue cumulées (séries × haut de plage), 0 hors tenue.
  double get holdSeconds =>
      isTimed && isResistance ? p.sets * secondsHigh.toDouble() : 0;

  /// Durée estimée de l'exercice, en secondes : transition, puis séries ×
  /// (effort + repos), sans repos après la dernière série.
  double get estimatedSeconds {
    final sides = exercise.laterality == Laterality.bilateral ? 1 : 2;
    double effort;
    if (isReps) {
      effort = repsHigh * secondsPerRep * sides;
    } else if (isTimed) {
      effort = secondsHigh.toDouble() * (isResistance ? sides : 1);
    } else if (p.distanceMeters != null) {
      effort = p.distanceMeters! / runMetersPerSecond;
    } else if (p.calories != null) {
      effort = p.calories! * 6;
    } else {
      effort = 30;
    }
    final rest = (p.restSeconds ?? 60).toDouble();
    return transitionSeconds + p.sets * effort + (p.sets - 1) * rest;
  }

  /// Schéma de la prescription : `séries x bas-haut` (répétitions), avec
  /// `s` pour un temps, `m` pour une distance.
  String get scheme {
    if (isReps) {
      return '${p.sets}x$repsLow-$repsHigh';
    }
    if (isTimed) {
      return '${p.sets}x$secondsLow-${secondsHigh}s';
    }
    final meters = p.distanceMeters;
    if (meters != null) {
      return '${p.sets}x${meters.round()}m';
    }
    return '${p.sets}x';
  }
}

/// Séance d'une semaine.
final class DayView {
  /// Séance.
  DayView({
    required this.dayIndex,
    required this.weekday,
    required this.minutesBudget,
    required this.focus,
    required this.items,
  });

  /// Jour d'entraînement.
  final int dayIndex;

  /// Jour ISO (1 = lundi).
  final int weekday;

  /// Minutes disponibles.
  final int minutesBudget;

  /// Thème de la séance (code de `kalis_plan`).
  final String focus;

  /// Exercices, dans l'ordre.
  final List<ItemView> items;

  /// Durée estimée, en minutes : exercices + 5 min d'échauffement général
  /// dès qu'il y a du renforcement.
  double get estimatedMinutes {
    var seconds = 0.0;
    var resistance = false;
    for (final i in items) {
      seconds += i.estimatedSeconds;
      resistance = resistance || i.isResistance;
    }
    return (seconds + (resistance ? 300 : 0)) / 60;
  }
}

/// Semaine du programme.
final class WeekView {
  /// Semaine.
  WeekView({
    required this.index,
    required this.blockIndex,
    required this.weekInBlock,
    required this.kind,
    required this.days,
  });

  /// Rang global (0 = première).
  final int index;

  /// Rang du bloc.
  final int blockIndex;

  /// Rang dans le bloc.
  final int weekInBlock;

  /// Nature.
  final WeekKind kind;

  /// Séances.
  final List<DayView> days;

  /// Tous les exercices de la semaine.
  Iterable<ItemView> get items sync* {
    for (final d in days) {
      yield* d.items;
    }
  }

  /// Séries dures de la semaine.
  double get hardSets {
    var total = 0.0;
    for (final i in items) {
      total += i.hardSets;
    }
    return total;
  }

  /// Séries dures créditées au groupe [group].
  double groupSets(MuscleGroup group) {
    var total = 0.0;
    for (final i in items) {
      total += i.creditedSets(group);
    }
    return total;
  }

  /// Secondes de tenue bras tendus de la famille [family].
  double straightArmSeconds(StraightArmFamily family) {
    var total = 0.0;
    for (final i in items) {
      if (i.straightArm == family) {
        total += i.holdSeconds;
      }
    }
    return total;
  }

  /// Séances de la semaine qui contiennent une tenue bras tendus de la
  /// famille [family].
  int straightArmDays(StraightArmFamily family) {
    var count = 0;
    for (final d in days) {
      if (d.items.any((i) => i.straightArm == family)) {
        count++;
      }
    }
    return count;
  }

  /// Séances de la semaine où un exercice de la chaîne de [rootIds] (ou
  /// l'un des exercices [ids]) est prescrit.
  int daysWith(Set<String> ids, Set<String> rootIds) {
    var count = 0;
    for (final d in days) {
      if (d.items.any(
        (i) =>
            ids.contains(i.exercise.id) || rootIds.contains(i.exercise.rootId),
      )) {
        count++;
      }
    }
    return count;
  }

  /// Vrai pour une semaine allégée par nature (introduction, décharge,
  /// test).
  bool get isLight =>
      kind == WeekKind.intro ||
      kind == WeekKind.deload ||
      kind == WeekKind.test;
}

/// Programme lu : ses semaines jusqu'à l'horizon.
final class ProgramView {
  /// Lecture du programme [program].
  ProgramView(this.catalog, this.program) : weeks = _read(catalog, program);

  /// Catalogue.
  final Catalog catalog;

  /// Programme.
  final BenchProgram program;

  /// Semaines, jusqu'à l'horizon.
  final List<WeekView> weeks;

  /// Semaines de montée (ni introduction, ni décharge, ni test) ; toutes
  /// les semaines s'il n'y en a aucune.
  List<WeekView> get buildWeeks {
    final out = <WeekView>[
      for (final w in weeks)
        if (!w.isLight) w,
    ];
    return out.isEmpty ? weeks : out;
  }

  /// Identifiants et racines de chaîne des exercices [exerciseIds].
  (Set<String>, Set<String>) chainOf(Iterable<String> exerciseIds) {
    final ids = <String>{};
    final roots = <String>{};
    for (final id in exerciseIds) {
      ids.add(id);
      final e = catalog.find(id);
      if (e != null) {
        roots.add(e.rootId);
      }
    }
    return (ids, roots);
  }

  static List<WeekView> _read(Catalog catalog, BenchProgram program) {
    final traits = CatalogTraits.of(catalog);
    final bodyWeight = program.profile.bodyWeightKg ?? defaultBodyWeightKg;
    final runSpeed = runSpeedOf(program.bench);
    final out = <WeekView>[];
    var global = 0;
    for (var b = 0; b < program.blocks.length; b++) {
      final block = program.blocks[b];
      final roles = <String, SlotRole>{
        for (final d in block.pass1.days)
          for (final s in d.slots) s.slotId: s.role,
      };
      for (final week in block.pass2.weeks) {
        if (global >= program.horizonWeeks) {
          return out;
        }
        final days = <DayView>[];
        for (final day in week.days) {
          final base = block.pass1.days[day.dayIndex];
          days.add(
            DayView(
              dayIndex: day.dayIndex,
              weekday: base.weekday,
              minutesBudget: base.minutesBudget,
              focus: base.focus,
              items: <ItemView>[
                for (final item in day.items)
                  ItemView(
                    week: global,
                    kind: week.kind,
                    dayIndex: day.dayIndex,
                    p: item,
                    exercise: catalog.exercise(item.exerciseId),
                    traits: traits.of(item.exerciseId),
                    role: roles[item.slotId],
                    bodyWeightKg: bodyWeight,
                    runMetersPerSecond: runSpeed,
                  ),
              ],
            ),
          );
        }
        out.add(
          WeekView(
            index: global,
            blockIndex: b,
            weekInBlock: week.weekIndex,
            kind: week.kind,
            days: days,
          ),
        );
        global++;
      }
    }
    return out;
  }
}
