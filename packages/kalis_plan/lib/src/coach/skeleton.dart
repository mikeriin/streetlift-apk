/// Construction du squelette d'un bloc street : quels mouvements, quels
/// jours, avec quelle méthode. Chaque choix cite le principe du
/// référentiel de `kalis_bench` qui le fonde (CONTRAT.md, § 12).
library;

import 'package:kalis_core/kalis_core.dart';

import '../assemble.dart';
import '../traits.dart';
import 'athlete.dart';
import 'model.dart';
import 'prescribe.dart' show CoachNotes, coachGroupCap, straightArmFamilyOf;
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

/// Délai minimal par étape d'une figure bras tendus, en semaines (R4-F9 :
/// 12 chez le débutant, 8 à 12 chez l'intermédiaire, 8 chez l'avancé, 6 à
/// 8 en élite).
int coachStepWeeks(int level) => level <= 0 ? 12 : (level >= 3 ? 6 : 8);

/// Étape de travail prévue pour la figure [t] au début du bloc : l'étape
/// du profil, avancée d'un cran par délai minimal écoulé depuis le record
/// de cette étape (le plan suppose le critère de passage validé ; le test
/// de fin de bloc le confirme ou garde l'étape).
SkillTrack plannedTrack(Athlete a, SkillTrack t) {
  final anchor = a.recordDay[t.currentId];
  if (anchor == null) {
    return t;
  }
  final elapsed = anchor.daysUntil(a.start) ~/ 7;
  if (elapsed <= 0) {
    return t;
  }
  // Premier cran au premier bloc qui commence après le délai minimal ;
  // les suivants, un délai (plus la longueur d'un bloc) plus tard, pour
  // que chaque étape garde son délai entier.
  final weeks = coachStepWeeks(a.level);
  final first = weeks - t.weeksAtStep < 0 ? 0 : weeks - t.weeksAtStep;
  var steps = elapsed < first ? 0 : 1 + (elapsed - first) ~/ (weeks + 6);
  if (steps > 2) {
    steps = 2;
  }
  var at = t.stepIndex + steps;
  if (at > t.ladder.length - 1) {
    at = t.ladder.length - 1;
  }
  if (at == t.stepIndex) {
    return t;
  }
  return SkillTrack(
    targetId: t.targetId,
    ladder: t.ladder,
    stepIndex: at,
    weeksAtStep: 0,
  );
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

  /// Jour de renforcement qui finit par un footing court, ou −1.
  int extraRunDay = -1;
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
    bool support = false,
    bool keep = false,
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
        support: support,
        keep: keep,
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
  // Maximum de pompes prévu au début du bloc (trajectoire vers
  // l'objectif) : à partir de quatre, le geste complet devient le
  // mouvement principal.
  final pushPlanned = pushMax <= 0 || b.blockIndex == 0
      ? pushMax
      : (pushMax *
                    (1 +
                        a.plannedGain(
                          Ids.pushUp,
                          GoalMetric.maxReps,
                          pushMax,
                          a.start,
                        )) +
                1e-9)
            .floor();
  final heavy = a.heavyImpactBanned;
  final later = b.blockIndex > 0;
  // R5-P1 : 4 à 6 séries par groupe et par semaine au départ ; les séries
  // par exercice se règlent sur le nombre de séances.
  var shortest = 300;
  for (final d in a.days) {
    if (d.minutes < shortest) {
      shortest = d.minutes;
    }
  }
  final sets = a.dayCount >= 3 && shortest < 55 ? 2 : 3;
  // Surcharge progressive (R5-P1, R5-P2) : à partir du deuxième bloc, les
  // deux mouvements principaux prennent une série de plus quand ils n'en
  // ont que deux.
  final mainSets = later && sets < 3 ? sets + 1 : sets;
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
        // R5-P9 : en surpoids, l'appui des pieds dose mieux l'assistance
        // qu'un élastique.
        heavy
            ? <String>[...Picks.assistedPull.reversed, 'sw-traction-negative']
            : <String>[...Picks.assistedPull, 'sw-traction-negative'],
        SlotRole.main,
        Method.beginnerMain,
        sets: heavy ? mainSets : sets,
        referenceId: Ids.pull,
      );
      if (negativeDays.contains(d) && !heavy) {
        // R5-P8 : excentriques de 3 à 5 s, 2 à 3 × 2 à 3, juste après la
        // traction assistée.
        b.add(
          d,
          <String>['sw-traction-negative'],
          SlotRole.secondary,
          Method.beginnerNegative,
          sets: 2,
          referenceId: Ids.pull,
          fromWeek: later ? 0 : 2,
        );
      } else if (!heavy && a.aimsAt(Ids.pull)) {
        // Les autres jours : tenue menton au-dessus de la barre, courte et
        // propre (le haut du mouvement, sans excentrique).
        b.add(
          d,
          const <String>['cs-tenue-menton-barre-pronation'],
          SlotRole.secondary,
          Method.beginnerHold,
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
    } else if (pushPlanned >= 4 && !heavy && a.can(Ids.pushUp, d)) {
      // Quelques pompes acquises : des séries courtes du geste complet
      // d'abord (spécificité), puis la variante facile pour le volume.
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.main,
        Method.beginnerMain,
        sets: sets,
      );
      b.add(
        d,
        Picks.easyPushUp,
        SlotRole.secondary,
        Method.beginnerMain,
        sets: 2,
        referenceId: Ids.pushUp,
        support: true,
      );
    } else {
      b.add(
        d,
        Picks.easyPushUp,
        SlotRole.main,
        Method.beginnerMain,
        sets: mainSets,
        referenceId: Ids.pushUp,
      );
    }
    // Tirage horizontal (autant que de tirage vertical : R5-P8, R5-P27).
    if (rowDays.contains(d) || pullMax >= 5) {
      b.add(
        d,
        // Corps tendu dès six répétitions au record ; genoux fléchis en
        // dessous.
        rowMax != null && rowMax >= 6
            ? <String>[Ids.row, ...Picks.easyRow]
            : Picks.easyRow,
        SlotRole.secondary,
        Method.beginnerMain,
        // Chemin vers la première traction : le plafond du grand dorsal
        // (12 séries) va d'abord à la traction assistée et aux descentes
        // freinées ; le tirage horizontal garde deux séries (fixateurs
        // des omoplates et fléchisseurs du coude).
        sets: pullMax < 1 && a.aimsAt(Ids.pull) && !heavy ? 2 : sets,
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
          sets: 3,
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
    if (a.profile.bodyWeightGoal == BodyWeightGoal.lose && minutes >= 35) {
      // Perte de poids : la fin de séance se marche (dépense sans impact).
      b.add(
        d,
        const <String>['ca-marche-rapide'],
        SlotRole.accessory,
        Method.runEasy,
        sets: 1,
        note: 'walk',
      );
    }
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
      if (a.runGoal != null) {
        b.add(
          d,
          const <String>['ca-fractionne-long-1000m'],
          SlotRole.main,
          Method.runQuality,
          sets: 3,
          note: 'goal_pace',
        );
      }
    } else {
      b.add(d, <String>[Ids.easyRun], SlotRole.main, Method.runEasy, sets: 1);
    }
  }
  // Objectif chronométré : un footing court de plus, en fin d'une séance de
  // renforcement éloignée des deux courses (volume aérobie, R6-P14).
  if (a.runGoal != null && taken.length < 3) {
    var best = -1;
    var bestGap = -1;
    for (final d in runnable) {
      if (taken.contains(d) || a.days[d].minutes < 55) {
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
    if (best >= 0) {
      b.extraRunDay = best;
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
      <String>[...Picks.gymSingleLeg.take(2), ..._bodyweightLegsFor(a)],
      SlotRole.secondary,
      Method.accessoryLegs,
      sets: sets,
    );
    b.add(
      d,
      // À 50 ans et plus, ou quand le métier charge déjà les jambes : le
      // pont fessier sur une jambe avant l'excentrique des ischio-jambiers
      // (courbatures fortes, dosage difficile).
      a.age >= 50 || a.legsFactor < 1
          ? const <String>[
              'mu-pont-fessier-unilateral',
              'mu-pont-fessier-sol',
              'mu-nordic-hamstring-curl-assiste',
            ]
          : Picks.hamstring,
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

/// Méthodes d'un pilier en préparation d'une épreuve de répétitions :
/// série longue, densité, volume — la force passe par la séance lestée de
/// la semaine (R4-G1, R4-G2).
const List<String> _competitionMethods = <String>[
  Method.repsTop,
  Method.repsDensity,
  Method.repsVolume,
  Method.repsDensity,
  Method.repsVolume,
];

DayStress _stressOf(String method) => switch (method) {
  Method.repsTop || Method.repsStrength || Method.liftHeavy => DayStress.heavy,
  Method.repsDensity || Method.liftLight => DayStress.light,
  _ => DayStress.medium,
};

int _setsOf(String method, int level) => switch (method) {
  Method.repsTop => level >= 2 ? 4 : 3,
  Method.repsStrength => 4,
  Method.repsDensity => level >= 2 ? 8 : 6,
  _ => level >= 2 ? 5 : 4,
};

void _addRepsPillar(
  _Builder b,
  int d,
  String exerciseId,
  String method, {
  required int max,
  String? group,
  bool maintenance = false,
  bool short = false,
}) {
  final a = b.a;
  final stress = _stressOf(method);
  if (maintenance && group == null) {
    // Entretien : trois séries sous-maximales, sans densité ni série
    // longue (R4-H3 : un tiers du volume suffit à garder l'acquis).
    b.add(
      d,
      <String>[exerciseId],
      SlotRole.secondary,
      max < 8 ? Method.repsStrength : Method.repsVolume,
      sets: 3,
      stress: DayStress.medium,
    );
    return;
  }
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
      sets: group != null || short ? 3 : 4,
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
    sets: group != null || (short && method != Method.repsDensity)
        ? 3
        : _setsOf(method, a.level),
    stress: stress,
    group: group,
  );
}

/// Plus petit écart, en jours, entre deux séances voisines de [picked]
/// (semaine circulaire) ; 7 pour une seule séance.
int _minGap(Athlete a, List<int> picked) {
  if (picked.length < 2) {
    return 7;
  }
  var least = 7;
  for (var i = 0; i < picked.length; i++) {
    final here = a.days[picked[i]].weekday;
    final next = a.days[picked[(i + 1) % picked.length]].weekday;
    var g = next - here;
    if (g <= 0) {
      g += 7;
    }
    if (g < least) {
      least = g;
    }
  }
  return least;
}

/// Pratique du muscle-up d'un athlète qui en fait moins de six. Avec trois
/// répétitions ou plus : des simples propres, loin de l'échec (R4-F1,
/// R5-P27). En dessous, un simple serait déjà à une répétition de l'échec
/// sur un mouvement à risque : le travail passe par le muscle-up assisté
/// ou la descente freinée, et par le tirage explosif qui prépare la
/// transition.
void _addMuscleUpPractice(_Builder b, int d, int muMax) {
  final a = b.a;
  final weak = (a.profile.weakPoints ?? const <WeakPoint>[]).any(
    (w) => w.exerciseId == Ids.muscleUp,
  );
  if (muMax >= 3) {
    b.add(
      d,
      <String>[Ids.muscleUp],
      SlotRole.skill,
      Method.repsTechnique,
      sets: 4,
    );
    if (weak) {
      b.add(
        d,
        weakPointVariants[Ids.muscleUp]![WeakPointKind.transition]!,
        SlotRole.skill,
        Method.skillDynamic,
        sets: 2,
        referenceId: Ids.muscleUp,
        weak: WeakPointKind.transition,
        support: true,
      );
    }
    return;
  }
  b.add(
    d,
    const <String>[
      'cd-muscle-up-barre-assiste-elastique',
      'cd-muscle-up-barre-negatif',
      'cd-muscle-up-barre-basse-pieds-au-sol',
    ],
    SlotRole.skill,
    Method.skillDynamic,
    sets: 3,
    referenceId: Ids.muscleUp,
    skillTargetId: Ids.muscleUp,
    weak: weak ? WeakPointKind.transition : null,
  );
  b.add(
    d,
    const <String>[
      'cd-traction-explosive-poitrine-barre',
      'sw-traction-chest-to-bar',
    ],
    SlotRole.skill,
    Method.skillDynamic,
    sets: 3,
    referenceId: Ids.pull,
    support: true,
  );
}

/// Jambes au poids du corps au niveau de l'athlète : le pistol et le
/// shrimp squat demandent un record (ils ne se prescrivent pas à
/// l'aveugle) ; sans record, la chaîne part du pistol sur box.
List<String> _bodyweightLegsFor(Athlete a) {
  bool proven(String id) => (a.reps[id] ?? 0) >= 3;
  return <String>[
    for (final id in Picks.bodyweightLegs)
      if ((id != 'sw-pistol-squat' && id != 'sw-shrimp-squat') || proven(id))
        id,
  ];
}

/// Méthode de chaque jour de [pillarDays] pour un pilier de répétitions :
/// les jours lourds ([heavy], dans l'ordre) sont écartés d'au moins 48 h
/// l'un de l'autre et placés de préférence après un jour sans ce pilier ;
/// le lendemain d'un jour lourd reste léger (densité) ; les autres jours
/// alternent volume et densité (R4-F10, R5-P22 : 48 h entre deux charges
/// dures d'une même zone).
Map<int, String> _assignPillar(
  Athlete a,
  List<int> pillarDays,
  List<String> heavy, {
  Set<int> avoid = const <int>{},
}) {
  final out = <int, String>{};
  if (pillarDays.isEmpty) {
    return out;
  }
  int gap(int from, int to) {
    var g = a.days[to].weekday - a.days[from].weekday;
    if (g <= 0) {
      g += 7;
    }
    return g;
  }

  bool dayAfterPillar(int d) => pillarDays.any((o) => o != d && gap(o, d) == 1);
  final heavyDays = <int>[];
  for (final method in heavy) {
    if (heavyDays.length >= pillarDays.length) {
      break;
    }
    var best = -1;
    var bestScore = -1000;
    for (final d in pillarDays) {
      if (heavyDays.contains(d)) {
        continue;
      }
      // Écart au jour lourd le plus proche (dans les deux sens).
      var near = 7;
      for (final h in heavyDays) {
        final g1 = gap(h, d);
        final g2 = gap(d, h);
        final g = g1 < g2 ? g1 : g2;
        if (g < near) {
          near = g;
        }
      }
      var score = near * 10;
      if (!dayAfterPillar(d)) {
        score += 5;
      }
      if (avoid.contains(d)) {
        score -= 8;
      }
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    if (best < 0) {
      break;
    }
    // Deux jours lourds à moins de 48 h : le second devient du volume.
    var near = 7;
    for (final h in heavyDays) {
      final g1 = gap(h, best);
      final g2 = gap(best, h);
      final g = g1 < g2 ? g1 : g2;
      if (g < near) {
        near = g;
      }
    }
    if (heavyDays.isNotEmpty && near < 2) {
      continue;
    }
    heavyDays.add(best);
    out[best] = method;
  }
  // (La densité d'abord : un tiers au moins des séries d'un pilier se
  // fait au chrono, R4-G6.)
  var volume = false;
  for (final d in pillarDays) {
    if (out.containsKey(d)) {
      continue;
    }
    final afterHeavy = heavyDays.any((h) => gap(h, d) == 1);
    if (afterHeavy) {
      out[d] = Method.repsDensity;
    } else {
      out[d] = volume ? Method.repsVolume : Method.repsDensity;
      volume = !volume;
    }
  }
  return out;
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
  // Reprise après dix semaines d'arrêt ou plus : tout le premier cycle
  // (trois blocs) garde une fréquence réduite et le geste de base (R5-P6).
  final returning = a.gapWeeks >= 10 && b.blockIndex <= 2;
  final spared = a.pullFactor < 1 || a.volumeFactor < 1 || returning;

  // Fréquence par pilier (R4-G8 : 2 à 3 séances chez le débutant, 3 chez
  // l'intermédiaire, 3 à 4 chez l'avancé, 4 à 5 en élite), bornée par les
  // jours et par la tolérance du profil.
  // (L'intermédiaire qui s'entraîne quatre jours ou plus garde trois
  // séances sur le geste exact et en ajoute une sur une variante de
  // force : R4-G5, sous-maximal fréquent.)
  var frequency = a.level >= 3 ? 5 : (a.level == 2 || n >= 4 ? 4 : 3);
  // (R4-G8 vaut aussi en préparation d'une épreuve : 3 à 4 séances chez
  // l'avancé, 4 à 5 en élite ; la séance lestée de la semaine s'ajoute à
  // une séance au poids du corps, elle ne la remplace pas.)
  if (spared && frequency > 2) {
    frequency--;
  }
  if (frequency > n) {
    frequency = n;
  }
  var pullDays = spreadDays(a, days, frequency);
  // Jusqu'à l'intermédiaire, pas deux jours de tirage consécutifs (R4-F10,
  // R5-P22 : 48 h entre deux charges d'une même zone) : la fréquence cède.
  while (a.level <= 1 && frequency > 2 && _minGap(a, pullDays) < 2) {
    frequency--;
    pullDays = spreadDays(a, days, frequency);
  }
  final muPool = competition || pullDays.length < 2 ? days : pullDays;
  final muDays = muMax >= 1
      ? spreadDays(
          a,
          muPool,
          competition ? (n >= 4 ? 3 : n) : (muPool.length >= 2 ? 2 : 1),
        )
      : <int>[];
  final legCount = a.legsFactor < 1 ? 1 : (n >= 3 ? 2 : 1);
  // Les jambes ne précèdent pas un jour de course (R5-P19, R6-P30).
  final legCandidates = <int>[
    for (final d in days)
      if (!runDays.any((r) => b.dayBefore(d, r))) d,
  ];
  // Les jambes vont d'abord aux jours sans traction.
  final wanted = competition ? 1 : legCount;
  final free = <int>[
    for (final d in legCandidates)
      if (!pullDays.contains(d)) d,
  ];
  final short = days.every((d) => a.days[d].minutes <= 50);
  // (Les jours sans traction d'abord ; s'il en manque, on complète avec
  // les autres jours.)
  final others = <int>[
    for (final d in legCandidates.isEmpty ? days : legCandidates)
      if (!free.contains(d)) d,
  ];
  final legDays = short
      ? days
      : (free.length >= wanted
            ? spreadDays(a, free, wanted)
            : <int>[...free, ...spreadDays(a, others, wanted - free.length)]);

  // Poussée en entretien quand l'objectif ne porte que sur le tirage
  // (R4-H4 : on déplace du volume, on n'en ajoute pas).
  final pushGoal = a.aimsAt(Ids.dip) || a.aimsAt(Ids.pushUp);
  final pullGoal = a.aimsAt(Ids.pull) || a.aimsAt(Ids.muscleUp);
  final pushMaintenance = pullGoal && !pushGoal && !competition;
  final pullHeavy = <String>[
    for (final m in (competition ? _competitionMethods : _repsMethods(pullMax)))
      if (m == Method.repsTop || (m == Method.repsStrength && !returning)) m,
  ];
  final pullMethod = pullMax < 8 && !competition
      ? <int, String>{
          for (var i = 0; i < pullDays.length; i++)
            pullDays[i]: _repsMethods(pullMax)[i % 5],
        }
      : _assignPillar(a, pullDays, pullHeavy);
  final dipDays = pushMaintenance && pullDays.length > 2
      ? spreadDays(a, pullDays, 2)
      : pullDays;
  final dipMethod = pushMaintenance || dipMax < 8
      ? <int, String>{
          for (var i = 0; i < dipDays.length; i++)
            dipDays[i]: dipMax < 8 && !pushMaintenance
                ? _repsMethods(dipMax)[i % 5]
                : Method.repsVolume,
        }
      : _assignPillar(
          a,
          dipDays,
          competition || returning
              ? const <String>[Method.repsTop]
              : const <String>[Method.repsTop, Method.repsStrength],
          avoid: <int>{
            for (final e in pullMethod.entries)
              if (e.value == Method.repsTop) e.key,
          },
        );
  final rowDays = spreadDays(a, days, n >= 2 ? 2 : 1);
  // Épreuve de répétitions : les pompes ne gardent du volume que si elles
  // sont à l'épreuve (R4-G1 : spécificité).
  final event = shape.target?.event;
  final eventIds = <String>{
    for (final st in event?.stations ?? const <EventStation>[])
      st.exerciseId,
  };
  final pushUps = !competition || eventIds.contains(Ids.pushUp);
  // Séance lestée de la semaine d'une préparation d'épreuve : en tête
  // d'une séance sans série longue, loin de celle-ci.
  var weightedDay = -1;
  if (competition) {
    var top = -1;
    for (final d in pullDays) {
      if (pullMethod[d] == Method.repsTop) {
        top = d;
      }
    }
    for (final d in pullDays) {
      if (d != top &&
          a.can(Ids.weightedPull, d) &&
          (top < 0 || !b.dayBefore(top, d))) {
        weightedDay = d;
        break;
      }
    }
    if (weightedDay < 0 &&
        pullDays.isNotEmpty &&
        a.can(Ids.weightedPull, pullDays.first)) {
      weightedDay = pullDays.first;
    }
  }
  // Pratique des figures quand la calisthénie compte pour un quart ou plus
  // des disciplines déclarées (R4-F1 : courte, à l'état frais).
  var skillShare = 0;
  for (final sec in a.profile.disciplines.secondaries) {
    if (sec.discipline == TrainingDiscipline.calisthenics) {
      skillShare = sec.pct;
    }
  }
  final skillDays = skillShare >= 25 && !competition
      ? spreadDays(a, days, n >= 2 ? 2 : 1)
      : <int>[];
  var pushAt = 0;
  for (final d in days) {
    final minutes = a.days[d].minutes;
    b.days[d].focus = FocusCodes.upper;
    b.add(d, Picks.hangPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    if (skillDays.contains(d) && minutes >= 40) {
      b.add(d, Picks.wristPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
      b.add(
        d,
        const <String>[
          'cs-handstand-dos-au-mur',
          'cs-handstand-ventre-au-mur',
          'cs-l-sit-tuck',
        ],
        SlotRole.skill,
        Method.skillBalance,
        sets: 3,
      );
    }
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
        _addMuscleUpPractice(b, d, muMax);
      }
    }
    final pulls = pullDays.contains(d);
    final group = short && a.level >= 1 ? 'A' : null;
    // Séances courtes et objectif de tirage : la traction se fait seule,
    // repos complets ; la poussée s'enchaîne avec le tirage horizontal.
    final solo = group != null && pullGoal;
    if (d == weightedDay) {
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
    if (pulls && a.can(Ids.pull, d) && pullMax >= 1) {
      _addRepsPillar(
        b,
        d,
        Ids.pull,
        group != null && !solo
            ? (pullMax < 8 ? Method.repsStrength : Method.repsVolume)
            : pullMethod[d]!,
        max: pullMax,
        group: solo ? null : group,
        short: solo,
      );
      if (pullGoal && pullMax < 8 && !competition) {
        // Objectif de tirage sous huit répétitions : deux séries de
        // complément juste après (assistées, sinon descentes freinées) —
        // le volume spécifique que le geste complet ne permet pas encore.
        b.add(
              d,
              const <String>['sw-traction-assistee-elastique'],
              SlotRole.secondary,
              Method.accessoryCompound,
              sets: 2,
              referenceId: Ids.pull,
            ) ??
            b.add(
              d,
              const <String>['sw-traction-negative'],
              SlotRole.secondary,
              Method.beginnerNegative,
              sets: 2,
              referenceId: Ids.pull,
            );
      }
    } else if (!pulls &&
        pullGoal &&
        pullMax >= 5 &&
        !competition &&
        a.can(Ids.pull, d) &&
        !pullDays.any((o) => b.dayBefore(o, d) || b.dayBefore(d, o))) {
      // Jour sans traction, à 48 h des autres : une exposition légère au
      // chrono (R4-G6, R4-G8 : pratique fréquente et sous-maximale).
      b.add(
        d,
        <String>[Ids.pull],
        SlotRole.secondary,
        Method.repsDensity,
        sets: 5,
        stress: DayStress.light,
      );
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
    if (dipDays.contains(d) && a.can(Ids.dip, d) && dipMax >= 1) {
      _addRepsPillar(
        b,
        d,
        Ids.dip,
        group != null ? Method.repsVolume : dipMethod[d]!,
        max: dipMax,
        group: solo ? 'B' : group,
        maintenance: pushMaintenance,
      );
    } else if (!pushUps) {
      // Pompes hors épreuve : une seule séance d'entretien par semaine.
      if (pushAt < 1 && a.can(Ids.pushUp, d) && pushMax >= 1) {
        b.add(
          d,
          <String>[Ids.pushUp],
          SlotRole.secondary,
          Method.repsVolume,
          sets: 3,
          stress: DayStress.medium,
        );
        pushAt++;
      }
    } else if (a.can(Ids.pushUp, d) && pushMax >= 1) {
      final dense =
          group == null && !pushMaintenance && pushAt.isOdd && pushMax >= 10;
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.secondary,
        dense ? Method.repsDensity : Method.repsVolume,
        sets: group != null || pushMaintenance ? 3 : (dense ? 6 : 4),
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
    // Pompes en complément des dips : une fois par semaine, quand la
    // poussée fait partie de l'objectif.
    if (pulls &&
        pushUps &&
        !pushMaintenance &&
        pushMax >= 10 &&
        pushAt < 1 &&
        minutes >= 55 &&
        !b.days[d].hasExercise(Ids.pushUp) &&
        d != pullDays.first) {
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.accessory,
        Method.repsDensity,
        sets: 5,
        stress: DayStress.light,
      );
      pushAt++;
    }
    // Tirage horizontal et arrière d'épaule (R5-P27 : tirage au moins égal
    // à la poussée).
    if (group != null) {
      // Séances courtes : second enchaînement, tirage horizontal et
      // pompes, puis un mouvement de jambes et le tronc.
      b.add(
        d,
        Picks.bodyweightRow,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 3,
        group: 'B',
        rotate: true,
      );
      if (pushMax >= 1 &&
          !b.days[d].hasExercise(Ids.pushUp) &&
          !(solo && b.days[d].hasExercise(Ids.dip))) {
        b.add(
          d,
          <String>[Ids.pushUp],
          SlotRole.accessory,
          Method.repsVolume,
          sets: solo ? 2 : 3,
          stress: DayStress.medium,
          group: 'B',
        );
      }
      b.add(
        d,
        days.indexOf(d).isEven
            ? _bodyweightLegsFor(a)
            : Picks.bodyweightLegsSecond,
        SlotRole.secondary,
        Method.accessoryLegs,
        sets: 2,
      );
      _addCore(b, d);
      continue;
    }
    // Tirage horizontal : deux séances par semaine gardées quoi qu'il
    // arrive (équilibre des épaules), une de plus si le temps le permet.
    if (rowDays.contains(d) || (minutes >= 60 && !pulls)) {
      b.add(
        d,
        a.can(Ids.weightedPull, d) ? Picks.row : Picks.bodyweightRow,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: rowDays.contains(d) ? 3 : 2,
        keep: rowDays.contains(d),
      );
    }
    if (legDays.contains(d)) {
      _addLegs(b, d, main: d == legDays.first, sets: minutes >= 55 ? 3 : 2);
    }
    if (minutes >= 55 || !legDays.contains(d)) {
      _addCore(b, d, skill: skillDays.contains(d));
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
  // (R4-F10 : 48 h entre deux tirages lourds — traction lourde, puis
  // muscle-up lourd en fin de semaine quand il y a quatre séances
  // lourdes ; le tirage de volume tombe entre les deux.)
  final muDay = h >= 4 ? dayAt(3) : (h >= 2 ? dayAt(1) : dayAt(0));
  final dipHeavy = h >= 3 ? dayAt(2) : (h >= 2 ? dayAt(1) : dayAt(0));
  final pullVolume = h >= 3 ? dayAt(2) : (h >= 2 ? dayAt(1) : -1);
  // Objectif déclaré ailleurs et pas de compétition : le squat garde une
  // seule séance lourde (R4-H4 : le volume va à l'objectif).
  final squatAimed =
      a.profile.goals.isEmpty ||
      a.aimsAt(Ids.squat) ||
      (a.profile.events ?? const <SeasonEvent>[]).isNotEmpty;
  final squatVolume = !squatAimed
      ? -1
      : (h >= 4 ? dayAt(3) : (h >= 3 ? dayAt(0) : -1));
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
    if (!maintained(Ids.weightedMuscleUp) && n >= 3) {
      // Deuxième exposition de la semaine, technique et légère, en début
      // de séance, à 48 h au moins du muscle-up lourd (R4-F1 : pratique
      // distribuée du geste le plus technique).
      var second = -1;
      for (final d in <int>[if (light >= 0) light, ...heavyDays]) {
        if (d == muDay || b.dayBefore(d, muDay) || b.dayBefore(muDay, d)) {
          continue;
        }
        second = d;
        break;
      }
      if (second >= 0) {
        lift(
          second,
          Ids.weightedMuscleUp,
          Method.liftLight,
          DayStress.light,
        );
        final weak = _weakVariant(a, Ids.weightedMuscleUp);
        if (weak != null && weak.$2 == WeakPointKind.transition) {
          // Point faible « transition » : un éducatif dédié, léger.
          b.add(
            second,
            const <String>[
              'sl-dips-barre-fixe-leste',
              'cd-muscle-up-barre-basse-pieds-au-sol',
              'sw-dips-barre-droite',
            ],
            SlotRole.secondary,
            Method.liftVariant,
            sets: 2,
            referenceId: Ids.weightedMuscleUp,
            weak: WeakPointKind.transition,
            stress: DayStress.light,
          );
        }
      }
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
    if (target == Ids.weightedPull) {
      // Spécialisation : une troisième séance sur le geste exact, en
      // volume (R4-H2 : la cible monte en fréquence et en volume), à 48 h
      // des deux autres quand la semaine le permet.
      final taken = <int>{pullHeavy, if (pullVolume >= 0) pullVolume};
      var extra = -1;
      for (final d in <int>[if (light >= 0) light, ...heavyDays]) {
        if (taken.contains(d) ||
            taken.any((o) => b.dayBefore(d, o) || b.dayBefore(o, d))) {
          continue;
        }
        extra = d;
        break;
      }
      if (extra < 0 && extraDay >= 0 && !taken.contains(extraDay)) {
        extra = extraDay;
      }
      if (extra < 0 && light >= 0 && !taken.contains(light)) {
        extra = light;
      }
      if (extra >= 0) {
        lift(extra, Ids.weightedPull, Method.liftVolume, DayStress.medium);
      }
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
        note: 'pull_return',
      );
      // R5-P24 : charge graduée des fléchisseurs du poignet, légère et
      // loin de l'échec (aucun programme de soin : à coordonner avec le
      // professionnel qui suit le coude).
      for (final id in const <String>[
        'mu-wrist-curl-barre',
        'mu-reverse-wrist-curl-haltere',
      ]) {
        final e = a.catalog.find(id);
        if (e != null &&
            e.stressOn(Joint.elbow) != JointStress.high &&
            a.can(id, d)) {
          b.add(
            d,
            <String>[id],
            SlotRole.accessory,
            Method.accessoryPrehab,
            sets: 2,
            note: 'tendon',
          );
          break;
        }
      }
    }
  }
  if (squat && !squatAimed && !maintained(Ids.squat)) {
    // Objectif déclaré ailleurs, pas d'épreuve : le squat passe en
    // entretien (R4-H3, R4-H4 : charge gardée, volume réduit).
    b.add(
      squatHeavy,
      <String>[Ids.squat],
      SlotRole.secondary,
      Method.liftMaintain,
      sets: 3,
      stress: DayStress.heavy,
    );
  } else if (squat) {
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
  // Coude à ménager : tirage horizontal en prise neutre (R5-P24 : changer
  // la prise avant de supprimer).
  final rowPick = spareElbow
      ? const <String>['mu-rowing-haltere-unilateral-banc', ...Picks.row]
      : Picks.row;
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
          rowPick,
          SlotRole.accessory,
          Method.accessoryCompound,
          sets: 3,
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
        rowPick,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: lean ? 2 : (hasPull ? 3 : 4),
        // Coude à ménager : le tirage horizontal en prise neutre porte le
        // tirage de la semaine, il est gardé.
        keep: spareElbow,
      );
    } else if (!hasSquat) {
      b.add(d, rowPick, SlotRole.accessory, Method.accessoryCompound, sets: 3);
    }
    if (hasPull &&
        !spareElbow &&
        a.level >= 2 &&
        (!lean || target == Ids.weightedPull)) {
      // Fléchisseurs du coude : moteurs de la traction.
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
  // L'étape de travail est celle du profil : le plan ne suppose pas un
  // passage d'étape qui n'a pas été validé (R4-F7, R4-F9). L'étape
  // suivante s'ouvre sous condition, en entrées courtes (voir `ready`).
  final tracks = skillTargetsOf(a);
  final statics = <SkillTrack>[
    for (final t in tracks)
      if (t.targetId != 'cs-handstand' && t.targetId != 'cs-l-sit') t,
  ].take(2).toList();
  // R4-F10 : jours lourds par zone tendineuse (2 chez le débutant, 2 à 3
  // chez l'intermédiaire, 3 en avancé, 3 à 4 en élite), 48 h d'écart.
  // (Chez l'intermédiaire qui s'entraîne quatre jours : deux séances
  // lourdes et une légère, R4-F1 — pratique distribuée.)
  final heavyCount = a.level >= 2 ? 3 : (a.level == 1 && n >= 4 ? 3 : 2);
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
  final muPool = <int>[...rest, if (firstDays.length >= 3) firstDays[1]];
  final muDays = muMax >= 1 && (muWeak || muMax < 5)
      ? spreadDays(a, muPool.length >= 2 ? muPool : days, 2)
      : <int>[];
  final legDays = spreadDays(
    a,
    rest.isEmpty ? days : rest,
    n >= 5 || a.level < 2 ? 2 : 1,
  );
  // Budget du poignet (R4-F12) : quand une figure d'appui est au
  // programme, l'équilibre se travaille les mêmes jours qu'elle (à l'état
  // frais, en début de séance) ; les autres jours restent sans appui en
  // extension.
  bool supportTrack(SkillTrack? t) =>
      t != null &&
      a.catalog.find(t.currentId)?.pattern ==
          MovementPattern.figureStatiquePoussee;
  final supportDays = supportTrack(first)
      ? firstDays
      : (supportTrack(second) ? secondDays : <int>[]);
  final balanceDays = handstand >= 20
      ? (supportDays.isNotEmpty
            ? supportDays.take(n >= 5 ? 3 : 2).toList()
            : spreadDays(a, rest.isEmpty ? days : rest, n >= 5 ? 3 : 2))
      : <int>[];
  // Force de base : deux séances regroupées par semaine (à volume égal, la
  // dispersion n'apporte rien), hors des jours de maintien lourd quand
  // c'est possible.
  final strengthPool = <int>[...rest, if (firstDays.length >= 3) firstDays[1]];
  final strengthDays = spreadDays(
    a,
    strengthPool.length >= 2 ? strengthPool : days,
    2,
  );

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

  // Étape suivante sous condition : délai minimal de l'étape écoulé
  // (R4-F9), au moins un test passé (deuxième bloc ou plus) et maintien
  // de l'étape actuelle aux trois quarts du critère de passage.
  bool ready(SkillTrack t) {
    if (t.nextId == null || b.blockIndex == 0) {
      return false;
    }
    final anchor = a.recordDay[t.currentId] ?? a.profile.updatedOn;
    final elapsed = anchor.daysUntil(a.start) ~/ 7;
    final hold = a.holds[t.currentId] ?? 0;
    final criterion = a.level <= 1 ? 12 : (a.level == 2 ? 10 : 8);
    return t.weeksAtStep + elapsed >= coachStepWeeks(a.level) &&
        hold * 4 >= criterion * 3;
  }

  final attempts = <String, int>{};

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
        sets: heavy ? (a.level >= 2 ? 5 : 4) : 3,
        skillTargetId: t.targetId,
        stress: heavy ? DayStress.heavy : DayStress.light,
      );
      if (hold < 8 && easier != null && a.level >= 1) {
        // R4-F7 : deux à trois semaines de chevauchement avec l'étape
        // précédente quand l'étape est neuve ou courte.
        b.add(
          d,
          <String>[easier],
          SlotRole.skill,
          Method.skillEasyHold,
          sets: hold <= 0 ? 3 : 2,
          skillTargetId: t.targetId,
          stress: DayStress.medium,
        );
      }
      final next = t.nextId;
      if (heavy && next != null && ready(t) && (attempts[next] ?? 0) < 2) {
        // Deux séances par semaine au plus, deux entrées de 2 à 3 s.
        final slot = b.add(
          d,
          <String>[next],
          SlotRole.skill,
          Method.skillAttempt,
          sets: 2,
          skillTargetId: t.targetId,
          stress: DayStress.light,
        );
        if (slot != null) {
          attempts[next] = (attempts[next] ?? 0) + 1;
        }
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
      // Du travail dynamique au niveau de l'étape : la variante de même
      // rang, sinon la plus proche en dessous.
      final top = t.stepIndex >= dynamics.length
          ? dynamics.length - 1
          : t.stepIndex;
      b.add(
        d,
        <String>[
          for (var i = top; i >= 0; i--) dynamics[i],
          ...dynamics.skip(top + 1),
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
  // Figure complète hors de portée du programme : le dire (R4-F9).
  for (final t in <SkillTrack?>[first, second]) {
    if (t != null && t.ladder.length - 1 - t.stepIndex >= 1) {
      b.reasons.add(
        reason(ReasonCodes.planCoachNote, <String, Object?>{
          'note': CoachNotes.skillHorizon,
          'value': coachStepWeeks(a.level).toDouble(),
        }),
      );
      break;
    }
  }
  // Troisième exposition, légère, de la seconde figure : un jour à 48 h de
  // ses deux séances lourdes (R4-F1 : pratique distribuée ; tenues longues
  // sur l'étape plus facile, R4-F6).
  var secondLight = -1;
  if (second != null && n >= 4) {
    for (final d in <int>[...rest, ...days]) {
      if (secondDays.contains(d) ||
          secondDays.any((o) => b.dayBefore(d, o) || b.dayBefore(o, d))) {
        continue;
      }
      secondLight = d;
      break;
    }
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
      _addMuscleUpPractice(b, d, muMax);
    }
    // La seconde figure passe en premier sur sa dernière séance de la
    // semaine : chaque figure a au moins une séance à l'état frais.
    final secondFirst =
        second != null &&
        secondDays.length > 1 &&
        d == secondDays.last &&
        firstDays.contains(d);
    if (second != null && secondFirst) {
      skillDay(d, second, heavy: true);
    }
    if (first != null && firstDays.contains(d)) {
      skillDay(d, first, heavy: firstDays.length < 3 || d != firstDays[1]);
    }
    if (second != null && secondDays.contains(d) && !secondFirst) {
      skillDay(d, second, heavy: true);
    }
    if (second != null && d == secondLight) {
      skillDay(d, second, heavy: false);
    }
    // Force de base au service des figures (R1-P17, R4-F5) : lestée quand
    // le matériel et le niveau le permettent, sinon au poids du corps ;
    // plus de séries les jours sans maintien lourd.
    final weightedPull =
        a.oneRm[Ids.weightedPull] != null &&
        a.level >= 2 &&
        strengthDays.every((o) => a.can(Ids.weightedPull, o));
    if (weightedPull) {
      if (strengthDays.contains(d)) {
        b.add(
          d,
          <String>[Ids.weightedPull],
          SlotRole.secondary,
          Method.liftVolume,
          sets: 4,
          stress: DayStress.medium,
        );
      }
    } else if (pullMax >= 1 &&
        a.can(Ids.pull, d) &&
        strengthDays.isNotEmpty &&
        d == strengthDays.first) {
      b.add(
        d,
        <String>[Ids.pull],
        SlotRole.secondary,
        pullMax < 8 ? Method.repsStrength : Method.repsVolume,
        sets: 4,
        stress: DayStress.medium,
      );
    }
    if (balanceDays.contains(d) && a.level >= 2) {
      // Poussée verticale tête en bas : la force qui porte l'équilibre et
      // la planche (R4-F5).
      final dynamics = skillDynamics['cs-handstand']!;
      b.add(
        d,
        dynamics.reversed.toList(),
        SlotRole.skill,
        Method.skillDynamic,
        sets: 3,
        skillTargetId: 'cs-handstand',
        stress: DayStress.medium,
        support: true,
      );
    }
    final weightedDip =
        a.level >= 2 && strengthDays.every((o) => a.can(Ids.weightedDip, o));
    if (weightedDip && !strengthDays.contains(d)) {
      // Dips lestés regroupés sur les deux séances de force.
    } else if (dipMax >= 1 && a.can(Ids.dip, d) && strengthDays.contains(d)) {
      if (weightedDip) {
        b.add(
          d,
          <String>[Ids.weightedDip],
          SlotRole.secondary,
          a.oneRm[Ids.weightedDip] != null
              ? Method.liftVolume
              : Method.repsStrength,
          sets: 3,
          stress: DayStress.medium,
          referenceId: Ids.dip,
        );
      } else {
        b.add(
          d,
          <String>[Ids.dip],
          SlotRole.secondary,
          Method.repsVolume,
          sets: 3,
          stress: DayStress.medium,
        );
      }
    }
    if (strengthDays.contains(d)) {
      b.add(
        d,
        a.level >= 2
            ? const <String>[
                'sw-row-australien-pieds-sureleves',
                ...Picks.bodyweightRow,
              ]
            : Picks.bodyweightRow,
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 3,
        keep: true,
      );
    }
    if (legDays.contains(d)) {
      _addLegs(b, d, main: true, sets: a.level >= 2 ? 2 : 3);
    }
    _addCore(b, d, skill: true, sets: minutes >= 75 ? 3 : 2);
    if (minutes >= 60 && a.hasAny('élastique')) {
      _addPrehab(b, d);
    }
    // Mobilité des épaules et des poignets en fin de séance (R4-F12).
    if (minutes >= 60) {
      b.add(d, Picks.mobility, SlotRole.mobility, Method.mobility, sets: 1);
    }
  }
}

// ---------------------------------------------------------------- squelette

/// Durée approchée d'un emplacement, en secondes (séries × effort + repos
/// + transition) : sert à compléter une séance trop courte, la passe 2
/// fait le compte exact.
double _slotSeconds(Athlete a, SlotSpec s) {
  final e = a.catalog.find(s.exerciseId);
  final sides = e == null || e.laterality == Laterality.bilateral ? 1 : 2;
  final max = (a.reps[s.exerciseId] ?? 12).toDouble();
  final long = a.level >= 2 ? 240.0 : 180.0;
  double effort;
  double rest;
  var extra = 0.0;
  switch (s.method) {
    case Method.liftHeavy || Method.liftMaintain:
      effort = 15;
      rest = long;
      extra = 180;
    case Method.liftVolume:
      effort = 18;
      rest = 180;
      extra = 180;
    case Method.liftLight:
      effort = 9;
      rest = 120;
    case Method.liftVariant:
      effort = 12;
      rest = 150;
    case Method.repsTop || Method.repsEvent:
      effort = max * 0.8 * 3;
      rest = 180;
    case Method.repsVolume:
      effort = max * 0.6 * 3;
      rest = s.group != null
          ? 60
          : (a.level <= 0 ? 120 : (a.level == 1 ? 90 : 60));
    case Method.repsDensity:
      return 45 + s.sets * 90;
    case Method.repsStrength:
      effort = 15;
      rest = s.group != null ? 75 : 180;
    case Method.repsTechnique:
      effort = 6;
      rest = 150;
    case Method.beginnerMain:
      effort = 27.0 * sides;
      rest = 120;
    case Method.beginnerNegative:
      effort = 9;
      rest = 120;
    case Method.beginnerHold:
      effort = 15;
      rest = 60;
    case Method.skillHold || Method.skillEasyHold:
      effort = 10;
      rest = a.level >= 2 ? 180 : 150;
    case Method.skillDynamic || Method.skillAttempt:
      effort = 12;
      rest = 120;
    case Method.skillBalance:
      effort = 30;
      rest = 90;
    case Method.accessoryCompound:
      effort = 30.0 * sides;
      rest = 105;
    case Method.accessoryLegs:
      effort = 24.0 * sides;
      rest = 90;
    case Method.accessoryIsolation:
      effort = 39;
      rest = 75;
    case Method.accessoryPrehab:
      effort = 42;
      rest = 45;
    case Method.accessoryCore:
      effort = 30.0 * sides;
      rest = 60;
    case Method.warmupPrep:
      effort = 20;
      rest = 30;
    case Method.mobility:
      effort = 45;
      rest = 20;
    default:
      return 1800;
  }
  return 45 + s.sets * effort + (s.sets - 1) * rest + extra;
}

/// Compléments de fin de séance, dans l'ordre où ils sont ajoutés quand
/// la séance laisse plus d'un cinquième de son temps libre : gainage
/// latéral, bas du dos, chaîne postérieure, prévention de l'épaule, prise,
/// mobilité. Ils chargent les groupes que les mouvements de barre
/// laissent sous leur plancher (R1-P1) et ne prennent rien aux piliers
/// (emplacements d'appoint).
const List<(List<String>, SlotRole, String, int)>
_fillers = <(List<String>, SlotRole, String, int)>[
  (
    <String>['mu-gainage-lateral-coude', 'mu-gainage-lateral-releves-hanche'],
    SlotRole.core,
    Method.accessoryCore,
    2,
  ),
  (
    <String>['mu-bird-dog', 'mu-superman', 'mu-arch-hold'],
    SlotRole.core,
    Method.accessoryCore,
    2,
  ),
  (
    <String>[
      'mu-pont-fessier-sol',
      'mu-pont-fessier-unilateral',
      'mu-hip-thrust-unilateral',
      'mu-souleve-de-terre-roumain-halteres',
      'mu-hip-thrust-barre',
    ],
    SlotRole.accessory,
    Method.accessoryCompound,
    2,
  ),
  (
    <String>[
      'mu-face-pull-elastique',
      'mu-band-pull-apart',
      'mu-rotation-externe-elastique',
      'sw-row-scapulaire',
    ],
    SlotRole.accessory,
    Method.accessoryPrehab,
    2,
  ),
  (
    <String>[
      'mu-dead-bug',
      'mu-gainage-ventral-coudes',
      'mu-hollow-body-hold',
      'mu-hollow-rocks',
      'sw-dragon-flag-tuck',
    ],
    SlotRole.core,
    Method.accessoryCore,
    2,
  ),
  (
    <String>['mo-cars-epaule', 'mo-etirement-grand-dorsal-barre', 'mo-cat-cow'],
    SlotRole.mobility,
    Method.mobility,
    1,
  ),
  (
    <String>[
      'mo-squat-profond-tenu',
      'mo-cars-hanche',
      'mo-etirement-flechisseurs-poignet-bras-tendu',
    ],
    SlotRole.mobility,
    Method.mobility,
    1,
  ),
];

/// Complète les séances qui laissent plus d'un cinquième de leur temps
/// libre (hors jours de course).
void _fillTime(_Builder b, Set<int> runDays, CoachStyle style) {
  final a = b.a;
  // Chaque complément revient trois séances par semaine au plus (deux pour
  // la chaîne postérieure, une seule en préparation d'épreuve) : le temps
  // libre ne se remplit pas du même exercice tous les jours.
  final usage = List<int>.filled(_fillers.length, 0);
  bool posterior(SlotSpec s) {
    final pattern = a.catalog.find(s.exerciseId)?.pattern;
    return pattern == MovementPattern.charniereHanche ||
        pattern == MovementPattern.extensionHanche ||
        pattern == MovementPattern.flexionGenou;
  }

  var hinges = 0;
  for (final day in b.days) {
    hinges += day.slots.where(posterior).length;
  }
  final competition =
      b.shape.model == SeasonModel.repsPeak ||
      b.shape.model == SeasonModel.strengthPeak;
  for (var d = 0; d < a.dayCount; d++) {
    if (runDays.contains(d) || b.days[d].slots.isEmpty) {
      continue;
    }
    final minutes = a.days[d].minutes;
    if (minutes < 30) {
      continue;
    }
    final target = minutes * 60 * 0.8;
    double total() {
      var t = minutes * 9.0 > 480 ? 480.0 : minutes * 9.0;
      for (final s in b.days[d].slots) {
        t += _slotSeconds(a, s);
      }
      return t;
    }

    // Trois compléments au plus par séance ; en spécialisation, seuls la
    // prévention et la mobilité complètent (le volume dur reste à la
    // priorité, R4-H2).
    final lean = a.profile.specialization != null;
    var added = 0;
    // (Un seul complément dans une séance de 45 minutes ou moins, deux
    // sous 75 minutes, trois au-delà.)
    final most = minutes <= 45 ? 1 : (minutes < 75 ? 2 : 3);
    for (var k = 0; k < _fillers.length; k++) {
      final (base, role, method, sets) = _fillers[k];
      if (total() >= target || added >= most) {
        break;
      }
      // Du plus dur au plus facile à partir du niveau avancé ; l'ordre de
      // la liste (du plus simple) sinon.
      var candidates = a.level >= 2 ? base.reversed.toList() : base;
      if (lean &&
          method != Method.accessoryPrehab &&
          method != Method.mobility) {
        continue;
      }
      final free =
          method == Method.accessoryPrehab || method == Method.mobility;
      if (k == 1 && a.level >= 1) {
        // À partir de l'intermédiaire, le gainage d'appoint est la tenue
        // creuse, la position même de la barre et des figures.
        candidates = const <String>[
          'mu-hollow-body-hold',
          'mu-hollow-body-groupe',
        ];
      }
      if (k == 4 && a.level >= 1 && style != CoachStyle.beginner) {
        // (déjà couvert par la tenue creuse.)
        continue;
      }
      final limit = k == 2 ? (competition ? 1 : 2) : 3;
      if (!free && usage[k] >= limit) {
        continue;
      }
      if (k == 2 && hinges >= limit) {
        continue;
      }
      added++;
      if (b.days[d].slots.any((s) => candidates.contains(s.exerciseId))) {
        added--;
        continue;
      }
      final slot = b.add(
        d,
        candidates,
        role,
        method,
        sets: sets,
        support: true,
      );
      if (slot == null) {
        added--;
        continue;
      }
      // Un complément ne fait jamais dépasser un plafond de groupe : il
      // ne prend pas de séries aux mouvements visés.
      var over = false;
      for (final g in MuscleGroup.values) {
        if (!g.major || _slotCredit(a, slot, g) <= 0) {
          continue;
        }
        var sum = 0.0;
        for (final day in b.days) {
          for (final o in day.slots) {
            sum += _slotCredit(a, o, g);
          }
        }
        if (sum > coachGroupCap(a, g) + 1e-9) {
          over = true;
        }
      }
      if (over) {
        b.days[d].slots.remove(slot);
        added--;
        continue;
      }
      usage[k]++;
      if (k == 2) {
        hinges++;
      }
    }
    // La mobilité reste en fin de séance.
    final slots = b.days[d].slots;
    final mobility = <SlotSpec>[
      for (final s in slots)
        if (s.method == Method.mobility) s,
    ];
    slots
      ..removeWhere((s) => s.method == Method.mobility)
      ..addAll(mobility);
  }
}

/// Méthodes dont les séries ne comptent pas comme séries dures (loin de
/// l'échec par construction).
const Set<String> _easyMethods = <String>{
  Method.warmupPrep,
  Method.beginnerHold,
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
/// Séries dures que l'emplacement [s] crédite au groupe [g] (méthodes
/// loin de l'échec et maintiens sous-maximaux exclus).
double _slotCredit(Athlete a, SlotSpec s, MuscleGroup g) {
  if (_easyMethods.contains(s.method) ||
      s.method == Method.repsDensity ||
      s.method == Method.skillAttempt) {
    return 0;
  }
  final t = a.traits.find(s.exerciseId);
  if (t == null || !t.kind.isResistance) {
    return 0;
  }
  // Maintiens sous-maximaux des figures : comptés en secondes, pas en
  // séries dures (R4-F2).
  if (t.exercise.unit == MeasureUnit.seconds &&
      (s.method == Method.skillHold ||
          s.method == Method.skillEasyHold ||
          s.method == Method.skillBalance)) {
    return 0;
  }
  return s.sets * t.creditOf(g) / 2;
}

void _fitBudget(_Builder b) {
  final a = b.a;
  double credit(SlotSpec s, MuscleGroup g) => _slotCredit(a, s, g);

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
      final beginner = a.level == 0;
      for (final day in b.days) {
        for (final s in day.slots) {
          if (credit(s, g) <= 0) {
            continue;
          }
          // Le tirage horizontal gardé ne descend pas sous deux séries.
          if (s.keep && s.sets <= 2) {
            continue;
          }
          final pass = Method.trimPass(
            s.method,
            s.sets,
            beginner: beginner,
            support: s.support,
            keep: s.keep,
          );
          if ((pass == 4 || pass == 7) && day.slots.length <= 2) {
            continue;
          }
          final current = pick;
          if (current == null ||
              Method.trimBefore(
                s.method,
                s.sets,
                current.method,
                current.sets,
                beginner: beginner,
                support: s.support,
                otherSupport: current.support,
                keep: s.keep,
                otherKeep: current.keep,
              )) {
            pick = s;
            home = day;
          }
        }
      }
      if (pick == null || home == null) {
        break;
      }
      final pass = Method.trimPass(
        pick.method,
        pick.sets,
        beginner: beginner,
        support: pick.support,
        keep: pick.keep,
      );
      if (pass == 4 || pass == 7) {
        home.slots.remove(pick);
        continue;
      }
      final at = home.slots.indexOf(pick);
      home.slots[at] = pick.withSets(pick.sets - 1);
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
  if (b.extraRunDay >= 0) {
    b.add(
      b.extraRunDay,
      <String>[Ids.easyRun],
      SlotRole.accessory,
      Method.runEasy,
      sets: 1,
      note: 'run_extra',
    );
  }
  _limitStraightArmDays(b);
  _fitBudget(b);
  _fillTime(b, runDays, style);
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
    if (mobility >= 10 &&
        !runDays.contains(d) &&
        !b.days[d].slots.any((s) => s.method == Method.mobility)) {
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
