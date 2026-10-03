/// Construction du squelette d'un bloc street : quels mouvements, quels
/// jours, avec quelle méthode. Chaque choix cite le principe du
/// référentiel de `kalis_bench` qui le fonde (CONTRAT.md, § 12).
library;

import 'package:kalis_core/kalis_core.dart';

import '../assemble.dart';
import '../traits.dart';
import 'athlete.dart';
import 'model.dart';
import 'prescribe.dart' show coachGroupCap, straightArmFamilyOf;
import 'season.dart';
import 'tables.dart';

/// Style de programme de l'athlète [a].
CoachStyle styleOf(Athlete a) {
  if (a.level == 0) {
    return CoachStyle.beginner;
  }
  final primary = a.profile.disciplines.primary;
  if (primary == TrainingDiscipline.calisthenics &&
      skillTargetsOf(a).isNotEmpty) {
    return CoachStyle.figures;
  }
  if (primary == TrainingDiscipline.streetlifting && hasBelt(a)) {
    return CoachStyle.lifting;
  }
  return CoachStyle.reps;
}

/// Vrai si l'athlète peut lester une traction ou un dips au moins un jour.
bool hasBelt(Athlete a) {
  for (var d = 0; d < a.dayCount; d++) {
    if (a.can(Ids.weightedPull, d) || a.can(Ids.weightedDip, d)) {
      return true;
    }
  }
  return false;
}

/// Figure visée et étape actuelle.
final class SkillTrack {
  /// Figure.
  SkillTrack({
    required this.targetId,
    required this.ladder,
    required this.stepIndex,
    required this.weeksAtStep,
  });

  /// Figure visée.
  final String targetId;

  /// Étapes, de la plus facile à la figure.
  final List<String> ladder;

  /// Rang de l'étape actuelle.
  final int stepIndex;

  /// Semaines déjà passées à l'étape actuelle (déclaration du profil).
  final int weeksAtStep;

  /// Étape actuelle.
  String get currentId => ladder[stepIndex];

  /// Étape suivante, ou `null` à la dernière étape.
  String? get nextId =>
      stepIndex + 1 < ladder.length ? ladder[stepIndex + 1] : null;

  /// Étape précédente, ou `null` à la première.
  String? get easierId => stepIndex > 0 ? ladder[stepIndex - 1] : null;
}

/// Figures visées par l'athlète [a], par ordre de priorité : celles du
/// profil (`skills`), puis les objectifs qui portent sur une figure.
List<SkillTrack> skillTargetsOf(Athlete a) {
  final out = <SkillTrack>[];
  final seen = <String>{};

  void consider(String targetId, String? currentId, StepTenure? tenure) {
    if (!seen.add(targetId) || !a.catalog.contains(targetId)) {
      return;
    }
    final table = skillLadders[targetId];
    final ladder = <String>[
      for (final id in table ?? <String>[targetId])
        if (a.catalog.contains(id)) id,
    ];
    if (ladder.isEmpty || ladder.last != targetId) {
      ladder
        ..remove(targetId)
        ..add(targetId);
    }
    var at = -1;
    if (currentId != null) {
      at = ladder.indexOf(currentId);
      if (at < 0 && a.catalog.contains(currentId)) {
        // Étape hors de l'échelle type : elle y est insérée avant la figure.
        ladder.insert(ladder.length - 1, currentId);
        at = ladder.length - 2;
      }
    }
    if (at < 0) {
      for (var i = ladder.length - 1; i >= 0; i--) {
        final id = ladder[i];
        if ((a.holds[id] ?? 0) >= 3 ||
            (a.reps[id] ?? 0) >= 1 ||
            (a.profile.knownExerciseIds ?? const <String>[]).contains(id)) {
          at = i;
          break;
        }
      }
    }
    if (at < 0) {
      at = 0;
    }
    final weeks = tenure == null
        ? 0
        : switch (tenure) {
            StepTenure.months1To3 => 8,
            StepTenure.months3To6 => 16,
            StepTenure.over6Months => 26,
            _ => 2,
          };
    out.add(
      SkillTrack(
        targetId: targetId,
        ladder: ladder,
        stepIndex: at,
        weeksAtStep: weeks,
      ),
    );
  }

  for (final s in a.profile.skills ?? const <SkillState>[]) {
    consider(s.targetExerciseId, s.currentExerciseId, s.atStepSince);
  }
  for (final g in a.profile.goals) {
    final id = g.exerciseId;
    if (g.kind != GoalKind.performance || id == null) {
      continue;
    }
    final e = a.catalog.find(id);
    if (e == null) {
      continue;
    }
    final kind = slotKindOf(e);
    final figure =
        skillLadders.containsKey(id) ||
        (kind == SlotKind.skillStatic &&
            (g.metric == GoalMetric.skillUnlocked ||
                g.metric == GoalMetric.maxHoldSeconds));
    if (figure && id != Ids.muscleUp) {
      consider(id, null, null);
    }
  }
  return out;
}

/// Jours choisis pour [count] séances parmi les jours [candidates] : les
/// plus espacés dans la semaine (le plus petit écart circulaire le plus
/// grand), à égalité les premiers.
List<int> spreadDays(Athlete a, List<int> candidates, int count) {
  if (count >= candidates.length) {
    return List<int>.of(candidates);
  }
  if (count <= 0) {
    return <int>[];
  }
  List<int> best = candidates.sublist(0, count);
  var bestGap = -1;
  var bestSum = -1;
  final n = candidates.length;
  final pick = List<int>.generate(count, (i) => i);
  while (true) {
    var gap = 99;
    var sum = 0;
    for (var i = 0; i < count; i++) {
      final here = a.days[candidates[pick[i]]].weekday;
      final next = a.days[candidates[pick[(i + 1) % count]]].weekday;
      var g = next - here;
      if (g <= 0) {
        g += 7;
      }
      if (g < gap) {
        gap = g;
      }
      sum += g * g;
    }
    // Le plus grand écart minimal, puis les écarts les plus réguliers.
    if (gap > bestGap || (gap == bestGap && sum < bestSum)) {
      bestGap = gap;
      bestSum = sum;
      best = <int>[for (final p in pick) candidates[p]];
    }
    var i = count - 1;
    while (i >= 0 && pick[i] == n - count + i) {
      i--;
    }
    if (i < 0) {
      break;
    }
    pick[i]++;
    for (var j = i + 1; j < count; j++) {
      pick[j] = pick[j - 1] + 1;
    }
  }
  return best;
}

final class _Builder {
  _Builder(this.a, this.shape, this.blockIndex, this.rotation)
    : days = <DaySpec>[for (var d = 0; d < a.dayCount; d++) DaySpec(d)];

  final Athlete a;
  final BlockShape shape;
  final int blockIndex;

  /// Décalage des choix d'assistance (« Autre proposition », rotation
  /// d'un bloc à l'autre).
  final int rotation;
  final List<DaySpec> days;
  final List<SkillLadder> ladders = <SkillLadder>[];
  final List<Reason> reasons = <Reason>[];

  /// Ajoute au jour [day] le premier exercice admissible de [candidates]
  /// qui n'y est pas déjà. Rend l'emplacement, ou `null`.
  SlotSpec? add(
    int day,
    List<String> candidates,
    SlotRole role,
    String method, {
    int sets = 3,
    DayStress? stress,
    String? referenceId,
    String? skillTargetId,
    String? group,
    WeakPointKind? weak,
    int fromWeek = 0,
    int untilWeek = 99,
    String? note,
    bool rotate = false,
  }) {
    final n = candidates.length;
    for (var k = 0; k < n; k++) {
      final id = candidates[rotate ? (k + rotation) % n : k];
      if (!a.can(id, day) || days[day].hasExercise(id)) {
        continue;
      }
      final slot = SlotSpec(
        exerciseId: id,
        role: role,
        method: method,
        sets: sets,
        stress: stress,
        referenceId: referenceId,
        skillTargetId: skillTargetId,
        group: group,
        weak: weak,
        fromWeek: fromWeek,
        untilWeek: untilWeek,
        note: note,
      );
      days[day].slots.add(slot);
      return slot;
    }
    return null;
  }

  List<int> get allDays => <int>[for (var d = 0; d < a.dayCount; d++) d];

  /// Jours triés du plus court au plus long (à égalité, le plus tard).
  int get shortestDay {
    var best = 0;
    for (var d = 1; d < a.dayCount; d++) {
      if (a.days[d].minutes <= a.days[best].minutes) {
        best = d;
      }
    }
    return best;
  }

  /// Vrai si le jour [d] précède, à moins de 36 h, le jour [other].
  bool dayBefore(int d, int other) {
    var gap = a.days[other].weekday - a.days[d].weekday;
    if (gap < 0) {
      gap += 7;
    }
    return gap == 1;
  }
}

// ------------------------------------------------------------- débutant

void _buildBeginner(_Builder b) {
  final a = b.a;
  final pullMax = a.reps[Ids.pull] ?? 0;
  final pushMax = a.reps[Ids.pushUp] ?? 0;
  final dipMax = a.reps[Ids.dip] ?? 0;
  final rowMax = a.reps[Ids.row];
  final heavy = a.heavyImpactBanned;
  final later = b.blockIndex > 0;
  // R5-P1 : 4 à 6 séries par groupe et par semaine au départ ; les séries
  // par exercice se règlent sur le nombre de séances.
  final sets = a.dayCount >= 3 ? 2 : 3;
  // Tirage horizontal : deux séances par semaine suffisent quand le tirage
  // vertical est travaillé à chaque séance (plafond du débutant, R1-P1).
  final rowDays = a.dayCount <= 2
      ? b.allDays
      : spreadDays(a, b.allDays, a.dayCount >= 4 ? 3 : 2);
  // R4-F10 : au plus deux jours d'appui bras tendus par semaine chez le
  // débutant, non consécutifs.
  final supportDays = b.a.dayCount <= 2
      ? b.allDays
      : spreadDays(a, b.allDays, 2).toSet().toList();
  final negativeDays = spreadDays(a, b.allDays, a.dayCount >= 3 ? 2 : 1);
  for (var d = 0; d < a.dayCount; d++) {
    final minutes = a.days[d].minutes;
    final day = b.days[d]..focus = FocusCodes.fullBody;
    // Préparation de la suspension (R5-P8).
    b.add(d, Picks.hangPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    // Tirage vertical : chemin vers la traction.
    if (pullMax >= 5) {
      b.add(
        d,
        <String>[Ids.pull],
        SlotRole.main,
        Method.beginnerMain,
        sets: sets,
      );
    } else {
      b.add(
        d,
        <String>[...Picks.assistedPull, 'sw-traction-negative'],
        SlotRole.main,
        Method.beginnerMain,
        sets: sets,
        referenceId: Ids.pull,
      );
      if (negativeDays.contains(d) && !heavy) {
        b.add(
          d,
          <String>['sw-traction-negative'],
          SlotRole.secondary,
          Method.beginnerNegative,
          sets: 2,
          referenceId: Ids.pull,
          fromWeek: later ? 0 : 2,
        );
      }
    }
    // Poussée : pompes adaptées (R5-P9 : une variante qui permet 6 à 8
    // répétitions avec 3 en réserve).
    if (pushMax >= 6) {
      b.add(
        d,
        <String>[Ids.pushUp, ...Picks.easyPushUp],
        SlotRole.main,
        Method.beginnerMain,
        sets: sets,
      );
    } else {
      b.add(
        d,
        Picks.easyPushUp,
        SlotRole.main,
        Method.beginnerMain,
        sets: sets,
        referenceId: Ids.pushUp,
      );
      if (pushMax >= 1 && !heavy) {
        b.add(
          d,
          <String>['sw-pompe-negative'],
          SlotRole.secondary,
          Method.beginnerNegative,
          sets: 2,
          referenceId: Ids.pushUp,
          fromWeek: later ? 0 : 2,
        );
      }
    }
    // Tirage horizontal (autant que de tirage vertical : R5-P8, R5-P27).
    if (rowDays.contains(d) || pullMax >= 5) {
    b.add(
      d,
      rowMax != null && rowMax >= 10
          ? <String>[Ids.row, ...Picks.easyRow]
          : Picks.easyRow,
      SlotRole.secondary,
      Method.beginnerMain,
      sets: sets,
      referenceId: Ids.row,
    );
    }
    // Jambes : squat et fente en alternance, hanche si le temps le permet.
    final squatFirst = d.isEven;
    b.add(
      d,
      squatFirst ? Picks.beginnerSquat : Picks.beginnerLunge,
      SlotRole.secondary,
      Method.beginnerMain,
      sets: sets,
    );
    if (minutes >= 40) {
      b.add(
        d,
        squatFirst ? Picks.beginnerLunge : Picks.beginnerHip,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 2,
      );
    }
    // Dips : appui, puis dips assistés quand les pompes sont installées.
    if (!heavy && dipMax < 5 && supportDays.contains(d)) {
      if (later && pushMax >= 3) {
        b.add(
          d,
          Picks.assistedDip,
          SlotRole.secondary,
          Method.beginnerMain,
          sets: 2,
          referenceId: Ids.dip,
        );
      } else {
        b.add(
          d,
          <String>['cs-support-barres-paralleles'],
          SlotRole.accessory,
          Method.beginnerHold,
          sets: 2,
          referenceId: Ids.dip,
        );
      }
    } else if (dipMax >= 5) {
      b.add(
        d,
        <String>[Ids.dip],
        SlotRole.secondary,
        Method.beginnerMain,
        sets: sets,
      );
    }
    // Tronc.
    b.add(
      d,
      Picks.beginnerCore,
      SlotRole.core,
      Method.accessoryCore,
      sets: 2,
      rotate: true,
    );
    if (minutes >= 55 && !day.hasExercise('mu-gainage-lateral-genoux')) {
      b.add(
        d,
        <String>['mu-gainage-lateral-genoux', 'mu-gainage-lateral-coude'],
        SlotRole.core,
        Method.accessoryCore,
        sets: 2,
      );
    }
  }
}

// ----------------------------------------------------------------- course

/// Jours de course (hybride street et course) : rend les jours pris.
Set<int> _buildRuns(_Builder b) {
  final a = b.a;
  var share = 0;
  for (final s in a.profile.disciplines.secondaries) {
    if (s.discipline == TrainingDiscipline.cardio) {
      share = s.pct;
    }
  }
  if (share < 20 || a.dayCount < 3) {
    return <int>{};
  }
  var count = (a.dayCount * share / 100).round();
  if (count < 2) {
    count = 2;
  }
  if (count > a.dayCount - 2) {
    count = a.dayCount - 2;
  }
  if (count <= 0) {
    return <int>{};
  }
  final runnable = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (a.can(Ids.easyRun, d)) d,
  ];
  if (runnable.length < count) {
    return <int>{};
  }
  // Sortie longue : le jour le plus long (à égalité, le plus tard).
  var long = runnable.first;
  for (final d in runnable) {
    if (a.days[d].minutes >= a.days[long].minutes) {
      long = d;
    }
  }
  int distance(int x, int y) {
    var g = (a.days[x].weekday - a.days[y].weekday).abs();
    if (g > 3) {
      g = 7 - g;
    }
    return g;
  }

  final taken = <int>{long};
  while (taken.length < count) {
    var best = -1;
    var bestGap = -1;
    for (final d in runnable) {
      if (taken.contains(d)) {
        continue;
      }
      var gap = 99;
      for (final t in taken) {
        final g = distance(d, t);
        if (g < gap) {
          gap = g;
        }
      }
      if (gap > bestGap) {
        bestGap = gap;
        best = d;
      }
    }
    if (best < 0) {
      break;
    }
    taken.add(best);
  }
  // R6-P15 : une séance de qualité par semaine au plus, le reste facile.
  var quality = -1;
  for (final d in taken) {
    if (d != long &&
        (quality < 0 || distance(d, long) > distance(quality, long))) {
      quality = d;
    }
  }
  for (final d in taken) {
    b.days[d].focus = d == quality && a.level >= 1
        ? FocusCodes.cardioIntervals
        : FocusCodes.cardioEndurance;
    if (d == long) {
      b.add(
        d,
        <String>[Ids.longRun, Ids.easyRun],
        SlotRole.main,
        Method.runLong,
        sets: 1,
      );
    } else if (d == quality && a.level >= 1) {
      b.add(
        d,
        <String>[Ids.easyRun],
        SlotRole.warmup,
        Method.runEasy,
        sets: 1,
        note: 'run_warmup',
      );
      b.add(d, Picks.runQuality, SlotRole.main, Method.runQuality, sets: 5);
    } else {
      b.add(d, <String>[Ids.easyRun], SlotRole.main, Method.runEasy, sets: 1);
    }
  }
  return taken;
}

// ------------------------------------------------------------ assistance

/// Jambes d'une séance street au poids du corps ou en salle.
void _addLegs(_Builder b, int d, {required bool main, int sets = 3}) {
  final a = b.a;
  if (a.can(Ids.squat, d) && a.oneRm[Ids.squat] != null) {
    b.add(
      d,
      <String>[Ids.squat],
      SlotRole.secondary,
      main ? Method.liftVolume : Method.liftLight,
      sets: sets,
      stress: main ? DayStress.medium : DayStress.light,
    );
    return;
  }
  if (main) {
    b.add(
      d,
      <String>[...Picks.gymSingleLeg.take(2), ...Picks.bodyweightLegs],
      SlotRole.secondary,
      Method.accessoryLegs,
      sets: sets,
    );
    b.add(
      d,
      Picks.hamstring,
      SlotRole.accessory,
      Method.accessoryCompound,
      sets: 2,
    );
  } else {
    b.add(
      d,
      Picks.bodyweightLegsSecond,
      SlotRole.accessory,
      Method.accessoryLegs,
      sets: 2,
    );
  }
}

void _addCore(_Builder b, int d, {bool skill = false, int sets = 2}) {
  b.add(
    d,
    skill ? Picks.skillCore : Picks.core,
    SlotRole.core,
    Method.accessoryCore,
    sets: sets,
    rotate: !skill,
  );
}

void _addPrehab(_Builder b, int d) {
  b.add(
    d,
    d.isEven ? Picks.rearDelt : Picks.cuff,
    SlotRole.accessory,
    Method.accessoryPrehab,
    sets: 2,
  );
}

// ------------------------------------------------------------ sets & reps

/// Méthodes d'un pilier de répétitions selon son maximum (R4-G2) : force
/// d'abord sous 8, mixte de 8 à 15, endurance au-delà.
List<String> _repsMethods(int max) {
  if (max < 8) {
    return const <String>[
      Method.repsStrength,
      Method.repsVolume,
      Method.repsVolume,
      Method.repsVolume,
      Method.repsVolume,
    ];
  }
  return const <String>[
    Method.repsTop,
    Method.repsDensity,
    Method.repsStrength,
    Method.repsVolume,
    Method.repsDensity,
  ];
}

DayStress _stressOf(String method) => switch (method) {
  Method.repsTop || Method.repsStrength || Method.liftHeavy => DayStress.heavy,
  Method.repsDensity || Method.liftLight => DayStress.light,
  _ => DayStress.medium,
};

int _setsOf(String method, int level) => switch (method) {
  Method.repsTop => level >= 2 ? 4 : 3,
  Method.repsStrength => 4,
  Method.repsDensity => 8,
  _ => level >= 2 ? 5 : 4,
};

void _addRepsPillar(
  _Builder b,
  int d,
  String exerciseId,
  String method, {
  required int max,
  String? group,
}) {
  final a = b.a;
  final stress = _stressOf(method);
  if (method == Method.repsStrength && group != null) {
    b.add(
      d,
      <String>[exerciseId],
      SlotRole.main,
      Method.repsStrength,
      sets: 3,
      stress: DayStress.heavy,
      group: group,
    );
    return;
  }
  if (method == Method.repsStrength && group == null) {
    // R4-G2, R1-P17 : la force au poids du corps passe par le lest ou par
    // une variante plus dure, en séries courtes.
    final weighted = exerciseId == Ids.pull
        ? Ids.weightedPull
        : (exerciseId == Ids.dip ? Ids.weightedDip : null);
    final elbow = a.limitOn(Joint.elbow);
    final spare = elbow != null && elbow.discomfort >= 2 && elbow.recent;
    if (weighted != null && a.can(weighted, d) && !spare && max >= 8) {
      b.add(
        d,
        <String>[weighted],
        SlotRole.main,
        a.oneRm[weighted] != null ? Method.liftVolume : Method.repsStrength,
        sets: 4,
        stress: DayStress.heavy,
        referenceId: exerciseId,
      );
      return;
    }
    if (max >= 10 && !spare) {
      final hard = exerciseId == Ids.pull
          ? Picks.hardPull
          : (exerciseId == Ids.dip ? Picks.hardDip : Picks.hardPushUp);
      final slot = b.add(
        d,
        hard,
        SlotRole.main,
        Method.repsStrength,
        sets: 4,
        stress: DayStress.heavy,
        referenceId: exerciseId,
      );
      if (slot != null) {
        return;
      }
    }
    b.add(
      d,
      <String>[exerciseId],
      SlotRole.main,
      max < 8 ? Method.repsStrength : Method.repsVolume,
      sets: group != null ? 3 : 4,
      stress: max < 8 ? DayStress.heavy : DayStress.medium,
      group: group,
    );
    return;
  }
  b.add(
    d,
    <String>[exerciseId],
    method == Method.repsTop ? SlotRole.main : SlotRole.secondary,
    method,
    sets: group != null ? 3 : _setsOf(method, a.level),
    stress: stress,
    group: group,
  );
}

void _buildReps(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  if (days.isEmpty) {
    return;
  }
  final n = days.length;
  final shape = b.shape;
  final competition = shape.model == SeasonModel.repsPeak;
  final pullMax = a.reps[Ids.pull] ?? 0;
  final dipMax = a.reps[Ids.dip] ?? 0;
  final pushMax = a.reps[Ids.pushUp] ?? 0;
  final muMax = a.reps[Ids.muscleUp] ?? 0;
  final spared = a.pullFactor < 1 || a.volumeFactor < 1;

  // Fréquence par pilier (R4-G8 : 2 à 3 séances chez le débutant, 3 chez
  // l'intermédiaire, 3 à 4 chez l'avancé, 4 à 5 en élite), bornée par les
  // jours et par la tolérance du profil.
  var frequency = a.level >= 3 ? 5 : (a.level == 2 ? 4 : 3);
  if (competition && a.level >= 2) {
    frequency = a.level >= 3 ? 5 : 4;
  }
  if (spared && frequency > 2) {
    frequency--;
  }
  if (frequency > n) {
    frequency = n;
  }
  final pullDays = spreadDays(a, days, frequency);
  final muDays = muMax >= 1
      ? spreadDays(a, days, competition ? (n >= 4 ? 3 : n) : (n >= 2 ? 2 : 1))
      : <int>[];
  final legCount = a.legsFactor < 1 ? 1 : (n >= 3 ? 2 : 1);
  // Les jambes ne précèdent pas un jour de course (R5-P19, R6-P30).
  final legCandidates = <int>[
    for (final d in days)
      if (!runDays.any((r) => b.dayBefore(d, r))) d,
  ];
  final legDays = spreadDays(
    a,
    legCandidates.isEmpty ? days : legCandidates,
    competition ? 1 : legCount,
  );

  final pullMethods = _repsMethods(pullMax);
  final dipMethods = _repsMethods(dipMax);
  final short = days.every((d) => a.days[d].minutes <= 50);
  var pullAt = 0;
  var dipAt = 1;
  var pushAt = 0;
  for (final d in days) {
    final minutes = a.days[d].minutes;
    b.days[d].focus = FocusCodes.upper;
    b.add(d, Picks.hangPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    // Muscle-up : à l'état frais, en début de séance (R4-F1, R5-P27).
    if (muDays.contains(d)) {
      if (muMax >= 6) {
        b.add(
          d,
          <String>[Ids.muscleUp],
          SlotRole.skill,
          competition && d == muDays.first
              ? Method.repsTop
              : Method.repsDensity,
          sets: competition && d == muDays.first ? 4 : 6,
          stress: d == muDays.first ? DayStress.heavy : DayStress.light,
        );
      } else {
        b.add(
          d,
          <String>[Ids.muscleUp],
          SlotRole.skill,
          Method.repsTechnique,
          sets: 4,
        );
        final weak = (a.profile.weakPoints ?? const <WeakPoint>[]).any(
          (w) => w.exerciseId == Ids.muscleUp,
        );
        if (weak || muMax <= 3) {
          b.add(
            d,
            weakPointVariants[Ids.muscleUp]![WeakPointKind.transition]!,
            SlotRole.skill,
            Method.skillDynamic,
            sets: 3,
            referenceId: Ids.muscleUp,
            weak: WeakPointKind.transition,
          );
        }
      }
    }
    final pulls = pullDays.contains(d);
    final group = short && a.level >= 1 ? 'A' : null;
    if (pulls && a.can(Ids.pull, d) && pullMax >= 1) {
      _addRepsPillar(
        b,
        d,
        Ids.pull,
        group != null
            ? (pullMax < 8 ? Method.repsStrength : Method.repsVolume)
            : pullMethods[pullAt % pullMethods.length],
        max: pullMax,
        group: group,
      );
      pullAt++;
    } else if (pulls) {
      b.add(
        d,
        <String>[...Picks.assistedPull, ...Picks.bodyweightRow],
        SlotRole.main,
        Method.beginnerMain,
        sets: 3,
        referenceId: Ids.pull,
      );
    }
    // Poussée : dips les jours de traction (méthodes décalées), pompes en
    // complément.
    if (pulls && a.can(Ids.dip, d) && dipMax >= 1) {
      _addRepsPillar(
        b,
        d,
        Ids.dip,
        group != null
            ? Method.repsVolume
            : dipMethods[dipAt % dipMethods.length],
        max: dipMax,
        group: group,
      );
      dipAt++;
    } else if (a.can(Ids.pushUp, d) && pushMax >= 1) {
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.secondary,
        group != null || pushAt.isEven ? Method.repsVolume : Method.repsDensity,
        sets: group != null ? 3 : (pushAt.isEven ? 4 : 8),
        stress: DayStress.medium,
        group: group,
      );
      pushAt++;
    } else {
      b.add(
        d,
        Picks.easyPushUp,
        SlotRole.secondary,
        Method.beginnerMain,
        sets: 3,
        referenceId: Ids.pushUp,
      );
    }
    // Sets & reps de compétition : une séance lourde lestée par semaine
    // entretient la force (R4-G2, R3-P18).
    if (competition && d == pullDays.first && a.can(Ids.weightedPull, d)) {
      b.add(
        d,
        <String>[Ids.weightedPull],
        SlotRole.secondary,
        a.oneRm[Ids.weightedPull] != null
            ? Method.liftVolume
            : Method.repsStrength,
        sets: 3,
        stress: DayStress.heavy,
        referenceId: Ids.pull,
      );
    }
    // Pompes en complément des dips, deux fois par semaine au plus.
    if (pulls &&
        pushMax >= 10 &&
        pushAt < 2 &&
        minutes >= 55 &&
        !b.days[d].hasExercise(Ids.pushUp) &&
        d != pullDays.first) {
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.accessory,
        Method.repsDensity,
        sets: 6,
        stress: DayStress.light,
      );
      pushAt++;
    }
    // Tirage horizontal et arrière d'épaule (R5-P27 : tirage au moins égal
    // à la poussée).
    if (minutes >= 40) {
      b.add(
        d,
        a.can(Ids.weightedPull, d) ? Picks.row : Picks.bodyweightRow,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: pulls ? 2 : 3,
        rotate: true,
      );
    }
    if (legDays.contains(d)) {
      _addLegs(b, d, main: d == legDays.first, sets: minutes >= 55 ? 3 : 2);
    }
    if (minutes >= 55 || !legDays.contains(d)) {
      _addCore(b, d);
    }
    if (minutes >= 60 && a.hasAny('élastique')) {
      _addPrehab(b, d);
    }
  }
}

// ---------------------------------------------------------- streetlifting

/// Variante du mouvement [liftId] pour le point faible déclaré, ou `null`.
(List<String>, WeakPointKind)? _weakVariant(Athlete a, String liftId) {
  for (final w in a.profile.weakPoints ?? const <WeakPoint>[]) {
    if (w.exerciseId != liftId) {
      continue;
    }
    final candidates = weakPointVariants[liftId]?[w.kind];
    if (candidates != null) {
      return (candidates, w.kind);
    }
  }
  return null;
}

void _buildLifting(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  final n = days.length;
  if (n == 0) {
    return;
  }
  bool liftable(String id) => days.any((d) => a.can(id, d));
  final elbow = a.limitOn(Joint.elbow);
  final spareElbow = elbow != null && elbow.discomfort >= 2 && elbow.recent;
  final pull = liftable(Ids.weightedPull) && !spareElbow;
  final dip = liftable(Ids.weightedDip);
  final squat = liftable(Ids.squat);
  final mu =
      liftable(Ids.weightedMuscleUp) &&
      !spareElbow &&
      (a.oneRm[Ids.weightedMuscleUp] != null ||
          (a.reps[Ids.muscleUp] ?? 0) >= 5) &&
      a.level >= 2;

  // Spécialisation (R4-H1 à H4) : la cible monte en fréquence, le reste
  // passe en entretien.
  final special = a.profile.specialization;
  final target = special != null && special.kind == SpecializationKind.exercise
      ? special.exerciseId
      : null;
  bool maintained(String id) => target != null && target != id;

  // Jour léger : le plus court.
  final light = n >= 4 ? b.shortestDay : -1;
  final heavyDays = <int>[
    for (final d in days)
      if (d != light) d,
  ];
  final h = heavyDays.length;
  // Répartition des séances lourdes et de volume (R2-P7, R3-P3) : séance
  // lourde d'un mouvement et séance de volume séparées d'au moins un jour
  // d'entraînement.
  int dayAt(int k) => heavyDays[k % h];
  final pullHeavy = dayAt(0);
  final dipVolume = dayAt(0);
  final squatHeavy = h >= 2 ? dayAt(1) : dayAt(0);
  final muDay = h >= 2 ? dayAt(1) : dayAt(0);
  final dipHeavy = h >= 3 ? dayAt(2) : (h >= 2 ? dayAt(1) : dayAt(0));
  final pullVolume = h >= 3 ? dayAt(2) : (h >= 2 ? dayAt(1) : -1);
  final squatVolume = h >= 4 ? dayAt(3) : (h >= 3 ? dayAt(0) : -1);
  final extraDay = h >= 4 ? dayAt(3) : -1;

  for (final d in days) {
    b.days[d].focus = FocusCodes.upper;
    b.add(d, Picks.hangPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
  }

  void lift(int d, String id, String method, DayStress stress, {int sets = 4}) {
    if (d < 0) {
      return;
    }
    b.add(
      d,
      <String>[id],
      method == Method.liftHeavy ? SlotRole.main : SlotRole.secondary,
      maintained(id) ? Method.liftMaintain : method,
      sets: maintained(id)
          ? (method == Method.liftHeavy ? 3 : 2)
          : (sets == 4 && (a.level >= 3 || target == id) ? 5 : sets),
      stress: stress,
    );
  }

  void variant(int d, String id) {
    final v = _weakVariant(a, id);
    if (v == null || d < 0 || maintained(id)) {
      return;
    }
    b.add(
      d,
      v.$1,
      SlotRole.secondary,
      Method.liftVariant,
      sets: 3,
      referenceId: id,
      weak: v.$2,
      stress: DayStress.medium,
    );
  }

  // Muscle-up lesté d'abord, à l'état frais (R4-F1, R5-P27).
  if (mu) {
    lift(
      muDay,
      Ids.weightedMuscleUp,
      Method.liftHeavy,
      DayStress.heavy,
      sets: 5,
    );
    variant(muDay, Ids.weightedMuscleUp);
    if (light >= 0 && !maintained(Ids.weightedMuscleUp)) {
      lift(
        light,
        Ids.weightedMuscleUp,
        Method.liftLight,
        DayStress.light,
        sets: 3,
      );
    }
  }
  if (pull) {
    lift(pullHeavy, Ids.weightedPull, Method.liftHeavy, DayStress.heavy);
    if (pullVolume >= 0 && !maintained(Ids.weightedPull)) {
      lift(pullVolume, Ids.weightedPull, Method.liftVolume, DayStress.medium);
      variant(pullVolume, Ids.weightedPull);
    } else {
      variant(pullHeavy, Ids.weightedPull);
    }
    if (light >= 0 &&
        !maintained(Ids.weightedPull) &&
        a.level >= 2 &&
        target != Ids.weightedPull) {
      lift(light, Ids.weightedPull, Method.liftLight, DayStress.light, sets: 3);
    }
    if (target == Ids.weightedPull && (light >= 0 || extraDay >= 0)) {
      // Spécialisation : une exposition de plus, technique (R2-P7).
      b.add(
        light >= 0 ? light : extraDay,
        <String>[
          'sl-traction-lestee-pause-haut',
          'sl-traction-lestee-prise-neutre',
        ],
        SlotRole.secondary,
        Method.liftVariant,
        sets: 3,
        referenceId: Ids.weightedPull,
        stress: DayStress.medium,
      );
    }
  } else {
    // Coude à ménager : tirage au poids du corps en prise neutre, charge
    // graduée (R5-P20, R5-P24).
    final pullDays = spreadDays(a, days, n >= 3 ? 2 : 1);
    for (final d in pullDays) {
      b.add(
        d,
        <String>['sw-traction-neutre', 'sw-traction-anneaux', Ids.pull],
        SlotRole.secondary,
        Method.repsVolume,
        sets: 3,
        stress: DayStress.medium,
        referenceId: Ids.pull,
      );
    }
  }
  if (squat) {
    lift(squatHeavy, Ids.squat, Method.liftHeavy, DayStress.heavy);
    variant(squatHeavy, Ids.squat);
    lift(squatVolume, Ids.squat, Method.liftVolume, DayStress.medium);
  }
  if (dip) {
    lift(dipHeavy, Ids.weightedDip, Method.liftHeavy, DayStress.heavy);
    if (!maintained(Ids.weightedDip)) {
      if (dipVolume != dipHeavy) {
        lift(dipVolume, Ids.weightedDip, Method.liftVolume, DayStress.medium);
        variant(dipVolume, Ids.weightedDip);
      } else {
        variant(dipHeavy, Ids.weightedDip);
      }
      if (light >= 0 && a.level >= 2) {
        lift(
          light,
          Ids.weightedDip,
          Method.liftLight,
          DayStress.light,
          sets: 3,
        );
      }
    } else if (dipVolume != dipHeavy && h >= 3) {
      lift(dipVolume, Ids.weightedDip, Method.liftVolume, DayStress.medium);
    }
  }

  // Assistance (R2-P9, R5-P27) : tirage horizontal, chaîne postérieure,
  // prévention, tronc ; jour léger : jambes en unilatéral et mobilité.
  for (final d in days) {
    final slots = b.days[d].slots;
    final hasSquat = slots.any((s) => s.exerciseId == Ids.squat);
    final hasPull = slots.any(
      (s) =>
          a.catalog.find(s.exerciseId)?.pattern ==
          MovementPattern.tirageVertical,
    );
    final lower = slots.where((s) => s.exerciseId == Ids.squat).length;
    b.days[d].focus = lower > 0 && slots.length <= 3
        ? FocusCodes.lower
        : FocusCodes.fullBody;
    if (d == light) {
      if (a.level < 2) {
        // Intermédiaire : jour léger au poids du corps (volume facile).
        if (!slots.any((s) => s.method == Method.repsVolume)) {
          b.add(
            d,
            <String>[Ids.dip, Ids.pushUp],
            SlotRole.secondary,
            Method.repsVolume,
            sets: 3,
            stress: DayStress.light,
          );
        }
        b.add(
          d,
          Picks.row,
          SlotRole.accessory,
          Method.accessoryCompound,
          sets: 3,
          rotate: true,
        );
        _addCore(b, d);
      }
      if (!squat) {
        _addLegs(b, d, main: true);
      } else {
        b.add(
          d,
          Picks.gymSingleLeg,
          SlotRole.accessory,
          Method.accessoryLegs,
          sets: 2,
        );
      }
      _addPrehab(b, d);
      continue;
    }
    final lean = target != null;
    if (hasSquat && (!lean || d == squatHeavy)) {
      b.add(
        d,
        Picks.hinge,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: lean ? 2 : 3,
      );
      _addCore(b, d, sets: lean ? 2 : 3);
    } else if (!squat && d == squatHeavy) {
      _addLegs(b, d, main: true);
      _addCore(b, d);
    }
    if (hasPull || !pull) {
      b.add(
        d,
        Picks.row,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: lean ? 2 : (hasPull ? 3 : 4),
        rotate: true,
      );
    } else if (!hasSquat) {
      b.add(
        d,
        Picks.row,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 3,
        rotate: true,
      );
    }
    if (hasPull && !spareElbow && a.level >= 2 && !lean) {
      b.add(
        d,
        Picks.curl,
        SlotRole.accessory,
        Method.accessoryIsolation,
        sets: 2,
      );
    }
    _addPrehab(b, d);
  }
}

// ---------------------------------------------------------------- figures

void _buildFigures(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  final n = days.length;
  if (n == 0) {
    return;
  }
  final tracks = skillTargetsOf(a);
  final statics = <SkillTrack>[
    for (final t in tracks)
      if (t.targetId != 'cs-handstand' && t.targetId != 'cs-l-sit') t,
  ].take(2).toList();
  // R4-F10 : jours lourds par zone tendineuse (2 chez le débutant, 2 à 3
  // chez l'intermédiaire, 3 en avancé, 3 à 4 en élite), 48 h d'écart.
  final heavyCount = a.level >= 3 ? 3 : (a.level == 2 ? 3 : 2);
  final first = statics.isEmpty ? null : statics.first;
  final second = statics.length > 1 ? statics[1] : null;
  final firstDays = first == null
      ? <int>[]
      : spreadDays(a, days, heavyCount > n ? n : heavyCount);
  // La seconde figure partage les jours de la première quand elle charge
  // une autre zone (planche et front lever), pour garder des jours sans
  // bras tendus ; sinon elle prend les jours restants.
  final rest = <int>[
    for (final d in days)
      if (!firstDays.contains(d)) d,
  ];
  const secondCount = 2;
  final secondDays = second == null
      ? <int>[]
      : (n >= 5
            ? <int>[
                firstDays.first,
                if (firstDays.length > 1) firstDays.last,
              ].take(secondCount).toList()
            : spreadDays(a, rest.isEmpty ? days : rest, secondCount));
  final handstand = a.holds['cs-handstand'] ?? 0;
  final muMax = a.reps[Ids.muscleUp] ?? 0;
  final muWeak = (a.profile.weakPoints ?? const <WeakPoint>[]).any(
    (w) => w.exerciseId == Ids.muscleUp,
  );
  final muDays = muMax >= 1 && (muWeak || muMax < 5)
      ? spreadDays(a, rest.isEmpty ? days : rest, 2)
      : <int>[];
  final legDays = spreadDays(
    a,
    rest.isEmpty ? days : rest,
    a.level >= 2 ? 1 : 2,
  );
  final balanceDays = handstand >= 20
      ? spreadDays(a, rest.isEmpty ? days : rest, 2)
      : <int>[];

  void ladderOf(SkillTrack t) {
    final holdTarget = a.level <= 1 ? 12 : (a.level == 2 ? 10 : 8);
    final minWeeks = a.level == 0 ? 12 : (a.level >= 3 ? 6 : 8);
    b.ladders.add(
      SkillLadder(
        targetExerciseId: t.targetId,
        steps: <SkillStep>[
          for (final id in t.ladder)
            SkillStep(
              exerciseId: id,
              criterion: StepCriterion(
                holdSeconds: a.catalog.find(id)?.unit == MeasureUnit.seconds
                    ? holdTarget
                    : null,
                reps: a.catalog.find(id)?.unit == MeasureUnit.seconds
                    ? null
                    : 3,
                sets: 3,
                minQuality: 4,
                sessions: 3,
                minWeeks: minWeeks,
              ),
            ),
        ],
      ),
    );
    b.reasons.add(
      reason(ReasonCodes.planSkillStep, <String, Object?>{
        'exerciseId': t.currentId,
        'stepIndex': t.stepIndex,
      }),
    );
  }

  void skillDay(int d, SkillTrack t, {required bool heavy}) {
    final support =
        a.catalog.find(t.currentId)?.pattern ==
        MovementPattern.figureStatiquePoussee;
    if (support) {
      b.add(d, Picks.wristPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    }
    final hold = a.holds[t.currentId] ?? 0;
    final easier = t.easierId;
    if (heavy || easier == null || a.level < 2 || hold <= 0) {
      // R4-F6 : levier utile quand le maintien maximal vaut 8 à 25 s ; en
      // dessous, des maintiens courts sur l'étape et du temps sur l'étape
      // plus facile.
      b.add(
        d,
        <String>[t.currentId, if (easier != null) easier],
        SlotRole.skill,
        Method.skillHold,
        sets: a.level >= 2 ? 5 : 4,
        skillTargetId: t.targetId,
        stress: DayStress.heavy,
      );
      if (hold > 0 && hold < 8 && easier != null) {
        b.add(
          d,
          <String>[easier],
          SlotRole.skill,
          Method.skillEasyHold,
          sets: 2,
          skillTargetId: t.targetId,
          stress: DayStress.medium,
        );
      }
    } else {
      b.add(
        d,
        <String>[easier, t.currentId],
        SlotRole.skill,
        Method.skillEasyHold,
        sets: 3,
        skillTargetId: t.targetId,
        stress: DayStress.light,
      );
    }
    final dynamics = skillDynamics[t.targetId];
    if (dynamics != null) {
      // R4-F5 : compléter le statique par du dynamique dans le même schéma.
      final from = t.stepIndex >= 2 ? 2 : 0;
      b.add(
        d,
        <String>[
          ...dynamics.skip(from),
          ...dynamics.take(from).toList().reversed,
        ],
        SlotRole.skill,
        Method.skillDynamic,
        sets: 3,
        skillTargetId: t.targetId,
        stress: heavy ? DayStress.medium : DayStress.light,
      );
    }
  }

  if (first != null) {
    ladderOf(first);
  }
  if (second != null) {
    ladderOf(second);
  }
  final pullMax = a.reps[Ids.pull] ?? 0;
  final dipMax = a.reps[Ids.dip] ?? 0;
  for (final d in days) {
    final minutes = a.days[d].minutes;
    b.days[d].focus = FocusCodes.skills;
    b.add(d, Picks.shoulderPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    // Équilibre : pratique courte, à l'état frais (R4-F1), hors des jours
    // d'appui lourd.
    if (balanceDays.contains(d)) {
      b.add(d, Picks.wristPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
      b.add(
        d,
        <String>['cs-handstand', 'cs-handstand-dos-au-mur'],
        SlotRole.skill,
        Method.skillBalance,
        sets: 4,
      );
    }
    if (muDays.contains(d)) {
      b.add(
        d,
        <String>[Ids.muscleUp],
        SlotRole.skill,
        Method.repsTechnique,
        sets: 4,
      );
      b.add(
        d,
        weakPointVariants[Ids.muscleUp]![WeakPointKind.transition]!,
        SlotRole.skill,
        Method.skillDynamic,
        sets: 3,
        referenceId: Ids.muscleUp,
        weak: WeakPointKind.transition,
      );
    }
    if (first != null && firstDays.contains(d)) {
      skillDay(d, first, heavy: firstDays.length < 3 || d != firstDays[1]);
    }
    if (second != null && secondDays.contains(d)) {
      skillDay(d, second, heavy: true);
    }
    // Force de base au service des figures (R1-P17, R4-F5).
    final skillLoad = b.days[d].slots
        .where((s) => s.method == Method.skillHold)
        .length;
    if (a.can(Ids.weightedPull, d) &&
        a.oneRm[Ids.weightedPull] != null &&
        skillLoad == 0 &&
        a.level >= 2) {
      b.add(
        d,
        <String>[Ids.weightedPull],
        SlotRole.secondary,
        Method.liftVolume,
        sets: 3,
        stress: DayStress.medium,
      );
    } else if (pullMax >= 1 && a.can(Ids.pull, d) && skillLoad < 2) {
      b.add(
        d,
        <String>[Ids.pull],
        SlotRole.secondary,
        pullMax < 8 ? Method.repsStrength : Method.repsVolume,
        sets: skillLoad == 0 ? 4 : 3,
        stress: DayStress.medium,
      );
    }
    if (dipMax >= 1 && a.can(Ids.dip, d) && skillLoad < 2) {
      b.add(
        d,
        <String>[Ids.dip],
        SlotRole.secondary,
        Method.repsVolume,
        sets: 3,
        stress: DayStress.medium,
      );
    }
    if (skillLoad == 0 || minutes >= 75) {
      b.add(
        d,
        Picks.bodyweightRow,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 3,
        rotate: true,
      );
    }
    if (legDays.contains(d)) {
      _addLegs(b, d, main: true, sets: a.level >= 2 ? 2 : 3);
    }
    _addCore(b, d, skill: true);
    if (minutes >= 75 && a.hasAny('élastique')) {
      _addPrehab(b, d);
    }
  }
}

// ---------------------------------------------------------------- squelette

/// Méthodes dont les séries ne comptent pas comme séries dures (loin de
/// l'échec par construction).
const Set<String> _easyMethods = <String>{
  Method.warmupPrep,
  Method.accessoryPrehab,
  Method.liftLight,
  Method.mobility,
  Method.runEasy,
  Method.runLong,
  Method.runQuality,
};

/// Ramène le volume hebdomadaire de chaque groupe musculaire sous son
/// plafond (R1-P1, R5-P21) : une série en moins là où il en reste le plus,
/// au plus bas de l'ordre de retrait à égalité ; le travail principal
/// garde deux séries, la densité quatre minutes.
void _fitBudget(_Builder b) {
  final a = b.a;
  double credit(SlotSpec s, MuscleGroup g) {
    if (_easyMethods.contains(s.method)) {
      return 0;
    }
    final t = a.traits.find(s.exerciseId);
    if (t == null || !t.kind.isResistance) {
      return 0;
    }
    return s.sets * t.creditOf(g) / 2;
  }

  for (final g in MuscleGroup.values) {
    if (!g.major) {
      continue;
    }
    final cap = coachGroupCap(a, g);
    var guard = 0;
    while (guard < 200) {
      guard++;
      var total = 0.0;
      for (final day in b.days) {
        for (final s in day.slots) {
          total += credit(s, g);
        }
      }
      if (total <= cap + 1e-9) {
        break;
      }
      SlotSpec? pick;
      DaySpec? home;
      for (final day in b.days) {
        for (final s in day.slots) {
          if (credit(s, g) <= 0) {
            continue;
          }
          final floor = s.method == Method.repsDensity
              ? 4
              : (Method.cutRank(s.method) >
                        Method.cutRank(Method.liftVariant)
                    ? 2
                    : 1);
          if (s.sets <= floor) {
            continue;
          }
          final current = pick;
          if (current == null ||
              s.sets > current.sets ||
              (s.sets == current.sets &&
                  Method.cutRank(s.method) <
                      Method.cutRank(current.method))) {
            pick = s;
            home = day;
          }
        }
      }
      if (pick == null || home == null) {
        // Plus rien à réduire : un emplacement d'assistance en moins.
        SlotSpec? drop;
        DaySpec? from;
        for (final day in b.days) {
          for (final s in day.slots) {
            if (credit(s, g) > 0 &&
                Method.cutRank(s.method) <=
                    Method.cutRank(Method.liftVariant) &&
                day.slots.length > 2 &&
                (drop == null ||
                    Method.cutRank(s.method) < Method.cutRank(drop.method))) {
              drop = s;
              from = day;
            }
          }
        }
        if (drop == null || from == null) {
          break;
        }
        from.slots.remove(drop);
        continue;
      }
      final at = home.slots.indexOf(pick);
      home.slots[at] = SlotSpec(
        exerciseId: pick.exerciseId,
        role: pick.role,
        method: pick.method,
        sets: pick.sets - 1,
        stress: pick.stress,
        referenceId: pick.referenceId,
        skillTargetId: pick.skillTargetId,
        group: pick.group,
        weak: pick.weak,
        fromWeek: pick.fromWeek,
        untilWeek: pick.untilWeek,
        note: pick.note,
      );
    }
  }
}

/// Séances bras tendus par famille et par semaine (R4-F10 : 2 chez le
/// débutant, 3 chez l'intermédiaire et l'avancé, 4 en élite).
const List<int> coachStraightArmDays = <int>[2, 3, 3, 4];

/// Ramène chaque famille bras tendus à son nombre de séances : sur les
/// jours en trop (ceux dont le travail bras tendus compte le moins), le
/// gainage en appui est remplacé par un gainage sans appui tendu, le reste
/// est retiré.
void _limitStraightArmDays(_Builder b) {
  final a = b.a;
  final limit = coachStraightArmDays[a.level];
  int familyOf(SlotSpec s) {
    final e = a.catalog.find(s.exerciseId);
    return e == null || e.unit != MeasureUnit.seconds
        ? -1
        : straightArmFamilyOf(e);
  }

  for (var family = 0; family < 3; family++) {
    final ranked = <(int, int)>[];
    for (final day in b.days) {
      var rank = -1;
      for (final s in day.slots) {
        if (familyOf(s) == family && Method.cutRank(s.method) > rank) {
          rank = Method.cutRank(s.method);
        }
      }
      if (rank >= 0) {
        ranked.add((rank, day.dayIndex));
      }
    }
    var excess = ranked.length - limit;
    if (excess <= 0) {
      continue;
    }
    ranked.sort((x, y) {
      final by = x.$1.compareTo(y.$1);
      return by != 0 ? by : y.$2.compareTo(x.$2);
    });
    for (final (_, d) in ranked) {
      if (excess <= 0) {
        break;
      }
      excess--;
      final slots = b.days[d].slots;
      for (var i = 0; i < slots.length; i++) {
        final s = slots[i];
        if (familyOf(s) != family) {
          continue;
        }
        String? other;
        if (s.method == Method.accessoryCore) {
          for (final id in const <String>[
            'mu-hollow-body-hold',
            'sw-releve-genoux-suspendu',
            'mu-hollow-body-groupe',
            'mu-gainage-ventral-coudes',
            'mu-dead-bug',
          ]) {
            final e = a.catalog.find(id);
            if (e != null &&
                straightArmFamilyOf(e) < 0 &&
                a.can(id, d) &&
                !b.days[d].hasExercise(id)) {
              other = id;
              break;
            }
          }
        }
        if (other == null) {
          slots.removeAt(i);
          i--;
        } else {
          slots[i] = SlotSpec(
            exerciseId: other,
            role: s.role,
            method: s.method,
            sets: s.sets,
          );
        }
      }
    }
  }
}

/// Squelette du bloc de rang [blockIndex] qui commence le jour lu par
/// [a] ; [rotation] décale les choix d'assistance (« Autre proposition »).
Skeleton buildSkeleton(
  Athlete a,
  BlockShape shape,
  int blockIndex, {
  int rotation = 0,
}) {
  final style = styleOf(a);
  final b = _Builder(a, shape, blockIndex, rotation);
  final runDays = style == CoachStyle.beginner ? <int>{} : _buildRuns(b);
  switch (style) {
    case CoachStyle.beginner:
      _buildBeginner(b);
    case CoachStyle.reps:
      _buildReps(b, runDays);
    case CoachStyle.lifting:
      _buildLifting(b, runDays);
    case CoachStyle.figures:
      _buildFigures(b, runDays);
  }
  _limitStraightArmDays(b);
  _fitBudget(b);
  // Mobilité en fin de séance quand le profil la demande.
  var mobility = 0;
  for (final s in a.profile.disciplines.secondaries) {
    if (s.discipline == TrainingDiscipline.mobility) {
      mobility = s.pct;
    }
  }
  // Aucune séance vide : repli sur ce que le matériel du jour permet.
  for (var d = 0; d < a.dayCount; d++) {
    if (mobility >= 10 && !runDays.contains(d)) {
      b.add(
        d,
        Picks.mobility,
        SlotRole.mobility,
        Method.mobility,
        sets: 1,
        rotate: true,
      );
    }
    if (b.days[d].slots.every((s) => s.method == Method.warmupPrep)) {
      b.add(
        d,
        <String>[Ids.pushUp, ...Picks.easyPushUp],
        SlotRole.main,
        Method.beginnerMain,
      );
      b.add(d, Picks.beginnerSquat, SlotRole.secondary, Method.beginnerMain);
      b.add(
        d,
        Picks.beginnerCore,
        SlotRole.core,
        Method.accessoryCore,
        sets: 2,
      );
      b.add(
        d,
        <String>['ca-marche-rapide'],
        SlotRole.conditioning,
        Method.runEasy,
        sets: 1,
      );
      if (b.days[d].focus.isEmpty) {
        b.days[d].focus = FocusCodes.fullBody;
      }
    }
    if (b.days[d].focus.isEmpty) {
      b.days[d].focus = FocusCodes.fullBody;
    }
    // Identifiants stables : rang dans la séance.
    final slots = b.days[d].slots;
    for (var i = 0; i < slots.length; i++) {
      slots[i].slotId = slotIdFor(d, i + 1);
    }
  }

  final target = shape.target;
  final toEvent = shape.weeksToEvent;
  final special = a.profile.specialization;
  final intent = BlockIntent(
    phase: shape.phase,
    eventId: target?.eventId,
    weeksToEvent: toEvent == null
        ? null
        : (toEvent > 104 ? 104 : (toEvent < 0 ? 0 : toEvent)),
    undulation: style == CoachStyle.beginner
        ? UndulationModel.none
        : UndulationModel.daily,
    specialization: special,
  );
  return Skeleton(
    style: style,
    shape: shape,
    days: b.days,
    ladders: b.ladders,
    reasons: b.reasons,
    intent: intent,
  );
}
