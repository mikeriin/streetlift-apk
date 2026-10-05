/// Mode coach : lecture des prescriptions de `kalis_core` 0.4.0 (technique,
/// intensité, autorégulation, test, intention de la semaine) et cibles des
/// séries qui en découlent. Un bloc sans ces champs (kalis_plan 0.1,
/// programme importé) ne passe jamais ici : il garde la règle générale de
/// 0.1. Règles et sources : `CONTRAT.md`, § 11.
library;

import 'package:kalis_core/kalis_core.dart';

import 'book.dart';
import 'filter.dart';
import 'grid.dart';
import 'model.dart';
import 'numeric.dart';
import 'params.dart';

Reason _r(String code, [Map<String, Object?> params = const {}]) =>
    Reason(code: code, params: params);

/// Vrai si le bloc [block] porte des champs de `kalis_core` 0.4.0 que le
/// moteur doit exécuter : intention du bloc ou d'une semaine, technique,
/// intensité, règle d'autorégulation, test décrit, étape de figure.
bool blockCoached(ProgramBlock block) {
  if (block.pass1.intent != null || block.pass1.skillLadders != null) {
    return true;
  }
  for (final week in block.pass2.weeks) {
    if (week.intent != null) {
      return true;
    }
    for (final day in week.days) {
      if (day.groups != null || day.stress != null) {
        return true;
      }
      for (final item in day.items) {
        if (item.technique != null ||
            item.intensity != null ||
            item.autoregulation != null ||
            item.test != null ||
            item.skillTargetId != null ||
            item.dayStress != null) {
          return true;
        }
      }
    }
  }
  return false;
}

/// Ce que l'intention d'une semaine permet au moteur.
final class WeekPolicy {
  /// Semaine d'intention [intent] et de nature [kind].
  const WeekPolicy(this.intent, this.kind);

  /// Intention (0.4.0), ou `null`.
  final WeekIntent? intent;

  /// Nature de la semaine, ou `null`.
  final WeekKind? kind;

  /// Semaine de charge : le RIR pilote la charge, une plage peut s'étendre.
  bool get build {
    final i = intent;
    if (i == null) {
      return kind == null || kind == WeekKind.build;
    }
    return i == WeekIntent.accumulation ||
        i == WeekIntent.intensification ||
        i == WeekIntent.realization;
  }

  /// Semaine d'affûtage ou de compétition : aucun volume ajouté, intensité
  /// gardée, aucune technique qui mène près de l'échec.
  bool get peak =>
      intent == WeekIntent.taper || intent == WeekIntent.competition;

  /// Semaine où la charge du bloc est servie telle quelle (allègement,
  /// affûtage, test, compétition, transition, introduction).
  bool get locked => !build && intent != WeekIntent.maintenance;

  /// Code de la phase (paramètre `phase` de `adapt.phase_respected`).
  String get code => intent?.code ?? kind?.code ?? WeekKind.build.code;

  /// Phase de saison que la semaine réalise, ou `null`.
  SeasonPhaseKind? get phase {
    final i = intent;
    if (i == null) {
      return null;
    }
    if (i == WeekIntent.accumulation || i == WeekIntent.intro) {
      return SeasonPhaseKind.accumulation;
    }
    if (i == WeekIntent.intensification) {
      return SeasonPhaseKind.intensification;
    }
    if (i == WeekIntent.realization) {
      return SeasonPhaseKind.realization;
    }
    if (i == WeekIntent.deload) {
      return SeasonPhaseKind.deload;
    }
    if (i == WeekIntent.taper) {
      return SeasonPhaseKind.taper;
    }
    if (i == WeekIntent.test) {
      return SeasonPhaseKind.test;
    }
    if (i == WeekIntent.competition) {
      return SeasonPhaseKind.competition;
    }
    if (i == WeekIntent.transition) {
      return SeasonPhaseKind.transition;
    }
    if (i == WeekIntent.maintenance) {
      return SeasonPhaseKind.maintenance;
    }
    return null;
  }
}

/// Niveau d'accès minimal d'une technique (0 débutant … 3 élite) : matrice
/// du référentiel (R2-P22), telle que le banc la contrôle.
int techniqueAccessLevel(SetTechniqueKind kind) {
  if (kind == SetTechniqueKind.topSetBackoff ||
      kind == SetTechniqueKind.dropSet ||
      kind == SetTechniqueKind.amrap ||
      kind == SetTechniqueKind.pyramid ||
      kind == SetTechniqueKind.ladder ||
      kind == SetTechniqueKind.density ||
      kind == SetTechniqueKind.forTime) {
    return 1;
  }
  if (kind == SetTechniqueKind.cluster ||
      kind == SetTechniqueKind.restPause ||
      kind == SetTechniqueKind.myoReps ||
      kind == SetTechniqueKind.accentuatedEccentric ||
      kind == SetTechniqueKind.contrast ||
      kind == SetTechniqueKind.wave) {
    return 2;
  }
  return 0;
}

/// Vrai si la technique mène près de l'échec ou surcharge : elle n'est
/// servie ni sur une zone douloureuse, ni un jour de bilan nettement bas,
/// ni en affûtage.
bool techniqueIntensifies(SetTechniqueKind kind) =>
    kind == SetTechniqueKind.restPause ||
    kind == SetTechniqueKind.myoReps ||
    kind == SetTechniqueKind.dropSet ||
    kind == SetTechniqueKind.accentuatedEccentric ||
    kind == SetTechniqueKind.amrap ||
    kind == SetTechniqueKind.cluster ||
    kind == SetTechniqueKind.wave ||
    kind == SetTechniqueKind.contrast;

/// Lecture « coach » d'une prescription du bloc.
final class CoachSpec {
  /// Lecture de [item] à l'emplacement [slotId].
  const CoachSpec({
    required this.slotId,
    required this.item,
    required this.policy,
    required this.level,
    required this.eventDays,
    required this.eventNear,
    required this.fragile,
  });

  /// Emplacement.
  final String slotId;

  /// Prescription du bloc.
  final ExercisePrescription item;

  /// Semaine.
  final WeekPolicy policy;

  /// Niveau d'expérience (0 débutant … 3 élite).
  final int level;

  /// Jours avant la prochaine échéance principale, ou `null`.
  final int? eventDays;

  /// Échéance principale proche : décisions prudentes.
  final bool eventNear;

  /// L'exercice sollicite une zone à antécédent récent ou à gêne déclarée.
  final bool fragile;

  /// Technique du bloc.
  SetTechniqueKind get technique =>
      item.technique?.kind ?? SetTechniqueKind.standard;

  /// Part du 1RM de charge totale écrite par le bloc, ou `null`.
  double? get pct {
    final intensity = item.intensity;
    if (intensity != null && intensity.basis == IntensityBasis.percentOneRm) {
      return intensity.value;
    }
    return item.percentOfOneRm;
  }

  /// Exercice dont le 1RM sert de référence à [pct], s'il diffère.
  String? get referenceId {
    final intensity = item.intensity;
    if (intensity != null && intensity.basis == IntensityBasis.percentOneRm) {
      return intensity.referenceExerciseId;
    }
    return null;
  }

  /// Part d'un test de référence (répétitions max, maintien max), ou
  /// `null`.
  double? get benchmarkShare {
    final intensity = item.intensity;
    if (intensity != null &&
        intensity.basis == IntensityBasis.percentBenchmark &&
        (intensity.referenceExerciseId == null ||
            intensity.referenceExerciseId == item.exerciseId)) {
      return intensity.value;
    }
    return null;
  }

  /// Séance ou série légère : très loin de l'échec, la charge du bloc est
  /// servie telle quelle.
  bool get light {
    final flames = item.targetFlames;
    return item.dayStress == DayStress.light || (flames != null && flames <= 2);
  }

  /// Règle d'autorégulation de nature [kind], ou `null`.
  AutoregulationRule? rule(AutoregulationKind kind) {
    for (final r in item.autoregulation ?? const <AutoregulationRule>[]) {
      if (r.kind == kind) {
        return r;
      }
    }
    return null;
  }

  /// Plancher de répétitions en réserve (plafond d'effort) : `rirCap` de
  /// l'intensité, sinon celui de la règle `stop_at_rir`, sinon `null`.
  double? get rirFloor {
    final cap = item.intensity?.rirCap;
    if (cap != null) {
      return cap;
    }
    return rule(AutoregulationKind.stopAtRir)?.rirFloor;
  }

  /// Répétitions (ou secondes) du schéma : haut de la plage de la première
  /// ligne.
  int get schemeAmount => item.repsHigh ?? item.secondsHigh ?? 0;

  /// Plage et rôle de la ligne de rang [index] parmi [sets], pour la
  /// technique servie [served] ; [hold] : exercice tenu (secondes).
  (int, int, SetRole?) line(
    int index,
    int sets,
    SetTechniqueKind served, {
    required bool hold,
  }) {
    final low = (hold ? item.secondsLow : item.repsLow) ?? 1;
    final high = (hold ? item.secondsHigh : item.repsHigh) ?? low;
    final t = item.technique;
    if (item.kind == SetKind.test) {
      final test = item.test?.kind;
      final attempt =
          test == TestKind.oneRm || test == TestKind.attemptSimulation;
      return (low, high, attempt ? SetRole.attempt : SetRole.test);
    }
    if (t == null || served == SetTechniqueKind.standard) {
      return (low, high, null);
    }
    if (t.lastSetOnly == true && index < sets - 1) {
      return (low, high, null);
    }
    if (served == SetTechniqueKind.topSetBackoff) {
      if (index == 0) {
        return (low, high, SetRole.top);
      }
      return (
        t.backoffRepsLow ?? low,
        t.backoffRepsHigh ?? high,
        SetRole.backOff,
      );
    }
    if (served == SetTechniqueKind.wave) {
      final reps = t.waveReps;
      if (reps != null && reps.isNotEmpty) {
        final n = reps[index % reps.length];
        return (n, n, SetRole.wave);
      }
    }
    if (served == SetTechniqueKind.pyramid) {
      final reps = t.pyramidReps;
      if (reps != null && reps.isNotEmpty) {
        final n = reps[index < reps.length ? index : reps.length - 1];
        return (n, n, SetRole.rung);
      }
    }
    if (served == SetTechniqueKind.ladder) {
      final start = t.ladderStart;
      final step = t.ladderStep;
      final top = t.ladderTop;
      if (start != null && step != null && top != null && step > 0) {
        final rungs = (top - start) ~/ step + 1;
        final n = start + step * (index % (rungs < 1 ? 1 : rungs));
        return (n, n, SetRole.rung);
      }
    }
    if (served == SetTechniqueKind.emom) {
      return (low, high, SetRole.interval);
    }
    return (low, high, null);
  }
}

/// Dernière séance d'un emplacement (mode coach) : ce à quoi la séance
/// suivante du même emplacement se compare, à schéma égal.
final class SlotMark {
  /// Marque.
  const SlotMark({
    required this.day,
    required this.loadKg,
    required this.amount,
    required this.top,
    required this.failed,
    this.easy = 0,
    this.total = 0,
    this.sets = 0,
    this.reached = 0,
  });

  /// Séances de suite où toutes les séries ont atteint le haut de leur
  /// plage sans être dites plus dures que visé, ou où la première série a
  /// été dite au moins deux répétitions plus facile que visé (exercice
  /// assisté : règle d'assistance du programme, CX, correction 1).
  final int reached;

  /// Somme des répétitions (ou secondes) menées à bien ce jour-là.
  final int total;

  /// Lignes faites ce jour-là.
  final int sets;

  /// Séances où la charge, servie au haut du couloir, est restée
  /// nettement plus facile que visé (élargit le couloir, R2-P3).
  final int easy;

  /// Jour de la séance.
  final int day;

  /// Plus forte charge externe menée à bien (après un échec non prévu : la
  /// plus légère des charges échouées), ou `null` sans charge.
  final double? loadKg;

  /// Répétitions (ou secondes) du schéma ce jour-là.
  final int amount;

  /// Plus grande série faite (répétitions ou secondes).
  final int top;

  /// Un échec non prévu a eu lieu.
  final bool failed;
}

/// Plus lourde barre réussie du suivi [track] dans les
/// `attemptRecentDays` jours avant [day], ou `null`.
double? recentHeavy(ExerciseTrack track, int day, AdaptParams p) {
  for (final h in track.heavy) {
    if (day - h.$1 <= p.attemptRecentDays) {
      return h.$2;
    }
  }
  return null;
}

/// Note dans le suivi [track] les barres réussies de la séance de [run] :
/// les six plus lourdes des dernières semaines sont gardées (une ouverture
/// est une barre déjà faite). Sans effet sur les décisions de 0.1.
void noteHeavy(ExerciseTrack track, ExerciseRun run, int day, AdaptParams p) {
  // (Une barre où les répétitions demandées n'ont pas été faites n'est
  // pas une barre réussie.)
  bool made(ObservedSet o) =>
      o.loadKg != null &&
      !o.failed &&
      o.amount >= 1 &&
      o.amount >= (o.target?.low ?? 1);
  var any = false;
  for (final o in run.observed) {
    if (made(o)) {
      any = true;
    }
  }
  if (!any) {
    return;
  }
  final heavy = <(int, double)>[
    for (final h in track.heavy)
      if (day - h.$1 <= p.attemptRecentDays) h,
  ];
  for (final o in run.observed) {
    final kg = o.loadKg;
    if (kg != null && made(o)) {
      heavy.add((day, kg));
    }
  }
  heavy.sort((a, b) {
    final byLoad = b.$2.compareTo(a.$2);
    return byLoad != 0 ? byLoad : b.$1.compareTo(a.$1);
  });
  track.heavy = heavy.length > 6 ? heavy.sublist(0, 6) : heavy;
}

/// Note la séance de l'exercice [run] dans son suivi [track] : marque de
/// l'emplacement.
void noteCoachSession(
  ExerciseTrack track,
  ExerciseRun run,
  CoachSpec coach,
  int day,
  AdaptParams p,
  double bodyWeightKg,
) {
  if (run.observed.isEmpty) {
    return;
  }
  double? held;
  double? lowestFailed;
  var top = 0;
  var failed = false;
  var total = 0;
  for (final o in run.observed) {
    if (o.amount > top && !o.failed) {
      top = o.amount;
    }
    if (!o.failed) {
      total += o.amount;
    }
    final kg = o.loadKg;
    if (o.unplannedFail) {
      failed = true;
      if (kg != null && (lowestFailed == null || kg < lowestFailed)) {
        lowestFailed = kg;
      }
    }
    if (kg != null && !o.failed && o.amount >= 1) {
      if (held == null || kg > held) {
        held = kg;
      }
    }
  }
  final marks = Map<String, SlotMark>.of(track.slotMarks);
  // Couloir : une séance servie au haut du couloir et restée nettement
  // plus facile que visé l'élargit d'un cran ; une séance plus dure que
  // visé le resserre d'un cran.
  var easy = marks[coach.slotId]?.easy ?? 0;
  var rirSum = 0.0;
  var rirCount = 0;
  for (final o in run.observed) {
    final flames = o.flames;
    if (flames != null && o.role != SetRole.backOff && !o.failed) {
      rirSum += Flames.toRir(flames);
      rirCount++;
    }
  }
  // Servie au haut nominal du couloir (à 2 % près) : la part du bloc et
  // le 1RM estimé de l'exercice lui-même.
  final pct = coach.pct;
  final f = track.filter;
  final ownRef = coach.referenceId == null || coach.referenceId == run.info.id;
  var atCeiling = false;
  if (pct != null && ownRef && held != null && f.mode == CapacityMode.loaded) {
    final ref = exp(f.m[0] + f.m[3] + f.gRef);
    final bw = run.info.fraction * bodyWeightKg;
    atCeiling = held + bw >= (pct + p.coachCorridorUp) * ref * 0.98;
  }
  if (failed) {
    easy = easy > 0 ? easy - 1 : 0;
  } else if (rirCount > 0) {
    final gap = rirSum / rirCount - run.rirEff;
    if (atCeiling && gap >= p.coachEasyGapRir - 1e-9) {
      easy++;
    } else if (gap <= -p.coachBreachRir + 1e-9 && easy > 0) {
      easy--;
    }
  }
  // Règle d'assistance : toutes les séries au haut de leur plage, aucune
  // dite plus dure que visé ; ou première série dite au moins deux
  // répétitions plus facile que visé.
  var allTop = true;
  for (final o in run.observed) {
    final t = o.target;
    final said = o.flames;
    if (o.failed ||
        t == null ||
        o.amount < t.high ||
        (said != null && rirOfFlames(said) < rirOfFlames(t.flames) - 0.5)) {
      allTop = false;
    }
  }
  final first = run.observed.first;
  final firstSaid = first.flames;
  final firstTarget = first.target;
  final firstEasy =
      !first.failed &&
      firstSaid != null &&
      firstTarget != null &&
      first.amount >= firstTarget.low &&
      rirOfFlames(firstSaid) - rirOfFlames(firstTarget.flames) >= 2 - 1e-9;
  final reached = allTop || firstEasy
      ? (marks[coach.slotId]?.reached ?? 0) + 1
      : 0;
  marks[coach.slotId] = SlotMark(
    day: day,
    reached: reached,
    loadKg: lowestFailed ?? held,
    amount: coach.schemeAmount,
    top: top,
    failed: failed,
    easy: easy,
    // (Un jour écourté — bilan bas, temps court — ne ramène pas le repère
    // de volume loin sous la séance d'avant.)
    total: _keptTotal(marks[coach.slotId]?.total ?? 0, total),
    sets: run.observed.length,
  );
  track.slotMarks = marks;
}

int _keptTotal(int before, int now) {
  final kept = (before * 0.85).floor();
  return now > kept ? now : kept;
}

/// Ce qu'une ligne du journal dit de la capacité quand elle porte des
/// champs de 0.4.0 (technique, parties, rôle, propreté).
final class LineReading {
  /// Lecture.
  const LineReading({
    required this.skip,
    this.amount,
    this.loadKg,
    this.boundOnly = false,
    this.unclean = false,
  });

  /// La ligne ne dit rien de la capacité.
  final bool skip;

  /// Répétitions ou secondes à retenir (première partie, plus grande
  /// partie), ou `null` : celles de la ligne.
  final int? amount;

  /// Charge externe à retenir, ou `null` : celle de la ligne.
  final double? loadKg;

  /// La ligne ne donne qu'une borne basse (« au moins tant »).
  final bool boundOnly;

  /// Propreté sous le plancher : la capacité propre est dépassée.
  final bool unclean;
}

/// Lecture de la ligne [set] ; `null` : ligne sans champ de 0.4.0, lue
/// comme en 0.1. [item] est la prescription du bloc, si elle est connue.
LineReading? readLine(
  SetRecord set, {
  required bool hold,
  ExercisePrescription? item,
}) {
  final parts = set.parts;
  final quality = set.quality;
  // La technique est celle que la ligne déclare ; une ligne découpée en
  // parties sans technique déclarée prend celle de la prescription. Une
  // ligne sans technique ni parties est une série classique (technique
  // non servie ce jour-là).
  final kind = set.technique ?? (parts != null ? item?.technique?.kind : null);
  if (set.technique == null &&
      parts == null &&
      set.role == null &&
      quality == null) {
    return null;
  }
  if (set.role == SetRole.warmup) {
    return const LineReading(skip: true);
  }
  if (set.role == SetRole.attempt && !hold) {
    // Tentative : une barre réussie dit « au moins une fois » ; la note
    // d'une répétition unique ne se lit pas comme une réserve mesurée.
    return const LineReading(skip: false, boundOnly: true);
  }
  if (kind == SetTechniqueKind.accentuatedEccentric) {
    // Une descente surchargée ou seule ne mesure pas la capacité du
    // mouvement complet.
    return const LineReading(skip: true);
  }
  var unclean = false;
  if (quality != null) {
    var floor = item?.technique?.qualityFloor;
    for (final r in item?.autoregulation ?? const <AutoregulationRule>[]) {
      if (r.kind == AutoregulationKind.stopOnQualityDrop) {
        floor ??= r.qualityFloor;
      }
    }
    unclean = quality < (floor ?? 3);
  }
  if (kind == SetTechniqueKind.restPause ||
      kind == SetTechniqueKind.myoReps ||
      kind == SetTechniqueKind.dropSet) {
    // Seule la première partie se lit comme une série : le total d'une
    // série relancée dépasse ce qu'une série d'une traite permet.
    if (parts == null || parts.isEmpty) {
      return const LineReading(skip: true);
    }
    final first = parts.first;
    final amount = hold ? first.seconds : first.reps;
    if (amount == null) {
      return const LineReading(skip: true);
    }
    return LineReading(
      skip: false,
      amount: amount,
      loadKg: first.externalLoadKg,
      unclean: unclean,
    );
  }
  if (kind == SetTechniqueKind.cluster ||
      kind == SetTechniqueKind.density ||
      kind == SetTechniqueKind.forTime ||
      (kind == SetTechniqueKind.amrap &&
          (parts != null || set.elapsedSeconds != null))) {
    // Répétitions fractionnées : chaque partie est une borne basse.
    if (parts == null || parts.isEmpty) {
      return const LineReading(skip: true);
    }
    var most = 0;
    for (final part in parts) {
      final amount = hold ? part.seconds : part.reps;
      if (amount != null && amount > most) {
        most = amount;
      }
    }
    if (most < 1) {
      return const LineReading(skip: true);
    }
    return LineReading(skip: false, amount: most, boundOnly: true);
  }
  return LineReading(skip: false, unclean: unclean);
}

/// Technique servie aujourd'hui pour l'exercice [ex] : celle du bloc, ou
/// `standard` quand un prérequis manque (niveau, douleur, bilan, phase,
/// échéance proche, antécédent) ; la cause est notée dans [ex].
SetTechniqueKind servedTechnique(SessionRun run, ExerciseRun ex, CoachSpec c) {
  final kind = c.technique;
  if (kind == SetTechniqueKind.standard) {
    return kind;
  }
  final p = run.ctx.params;
  String? cause;
  if (c.level < techniqueAccessLevel(kind)) {
    cause = 'level';
  } else if (techniqueIntensifies(kind)) {
    final days = c.eventDays;
    if (ex.painZones.isNotEmpty) {
      cause = 'pain';
    } else if (run.health.level >= 2) {
      cause = 'health';
    } else if (c.policy.locked) {
      cause = 'phase';
    } else if (kind == SetTechniqueKind.accentuatedEccentric &&
        days != null &&
        days <= p.coachEccentricEventDays) {
      cause = 'event';
    } else if (kind == SetTechniqueKind.accentuatedEccentric && c.fragile) {
      cause = 'history';
    }
  }
  if (cause == null) {
    return kind;
  }
  ex.techniqueWithheld = true;
  ex.notes.add(
    _r(ReasonCodes.planTechniqueWithheld, <String, Object?>{
      'technique': kind.code,
      'cause': cause,
    }),
  );
  return SetTechniqueKind.standard;
}

/// 1RM de charge totale auquel se rapporte la part écrite par le bloc :
/// celui de l'exercice (effet du jour compris), ou celui du mouvement de
/// référence ; `null` s'il est inconnu.
double? referenceTotal(SessionRun run, ExerciseRun ex, CoachSpec c) {
  final own = ex.track?.filter;
  final ref = c.referenceId;
  if (ref == null || ref == ex.info.id) {
    if (own == null || own.mode != CapacityMode.loaded) {
      return null;
    }
    return exp(own.m[0] + own.m[3] + own.gRef);
  }
  final other = run.state.tracks[ref];
  if (other != null && other.info.mode == CapacityMode.loaded) {
    final shift = own == null ? ex.baseShift : own.m[3];
    return other.filter.capacity * exp(shift);
  }
  final info = run.ctx.book.find(ref);
  if (info == null) {
    return null;
  }
  for (final declared in run.ctx.profile.movementLevels) {
    final low = declared.low;
    final high = declared.high;
    if (declared.exerciseId == ref &&
        declared.known &&
        declared.measure == LevelMeasure.oneRmKg &&
        low != null &&
        high != null &&
        low > 0) {
      return info.totalLoad((low + high) / 2, run.bodyWeightKg);
    }
  }
  return null;
}

/// Hausse maximale d'une séance à la suivante du même emplacement, à
/// schéma égal, pour l'exercice de [c].
double coachRiseOf(CoachSpec c, AdaptParams p) {
  final base = p.coachRise[c.level < 0 ? 0 : (c.level > 3 ? 3 : c.level)];
  return c.fragile ? base * p.coachHistoryRiseFactor : base;
}

/// Répétitions possibles, frais, à la charge externe [kg], après la perte
/// relative [fatigue] (valeur centrale, sans marge de prudence).
double _possible(SessionRun run, ExerciseRun ex, double kg, double fatigue) {
  final total = ex.info.totalLoad(kg, run.bodyWeightKg);
  if (total <= 0) {
    return 1000;
  }
  return ex.track!.filter.repsPossible(ln(total)) * (1 - fatigue);
}

/// Vrai si la charge [kg] laisse en moyenne [rir] répétitions en réserve
/// sur les lignes [reps] (répétitions, fatigue prévue) et, avec la marge
/// de prudence, au moins [worst] sur la plus dure.
bool _holdsRir(
  SessionRun run,
  ExerciseRun ex,
  double kg,
  List<(int, double)> reps,
  double rir,
  double worst,
) {
  if (reps.isEmpty) {
    return true;
  }
  var sum = 0.0;
  for (final (n, fatigue) in reps) {
    sum += _possible(run, ex, kg, fatigue) - n;
    if (run.predictedReps(ex, kg, 0, fatigue) - n < worst - 1e-9) {
      return false;
    }
  }
  return sum / reps.length >= rir - 1e-9;
}

/// Plus forte charge de la grille, de [from] vers le bas (au plus [steps]
/// crans), qui tient [test] ; la plus basse essayée sinon.
double _stepDownTo(
  LoadGrid grid,
  double from,
  int steps,
  bool Function(double kg) test,
) {
  var kg = from;
  for (var i = 0; i < steps; i++) {
    if (test(kg)) {
      return kg;
    }
    final next = grid.next(kg, up: false);
    if (next >= kg - 1e-9) {
      break;
    }
    kg = next;
  }
  return kg;
}

double _onGrid(LoadGrid grid, double kg, {bool nearest = false}) {
  final floor = kg < grid.minimum ? grid.minimum : kg;
  return nearest ? grid.nearest(floor) : grid.floor(floor);
}

/// Cibles des séries de l'exercice [ex] en mode coach, ou `null` quand la
/// règle générale de 0.1 s'applique (charge « à calibrer », plage sans
/// part du 1RM). [sets] est le nombre de lignes du jour.
List<SetPlan>? coachPlans(
  SessionRun run,
  ExerciseRun ex,
  ExercisePrescription item,
  int sets,
) {
  final c = ex.spec.coach;
  final track = ex.track;
  final mode = ex.info.mode;
  if (c == null || track == null || mode == null || sets < 1) {
    return null;
  }
  final served = servedTechnique(run, ex, c);
  if (item.kind == SetKind.test && item.test != null) {
    return _testPlans(run, ex, c, item, sets);
  }
  // Zone douloureuse (au-dessus de 3 sur 10) : pas de progression, donc
  // pas plus de lignes que la dernière séance de l'emplacement (R5-P23).
  var lines = sets;
  final before = track.slotMarks[c.slotId]?.sets ?? 0;
  final frozen = ex.painZones.isNotEmpty && before > 0 && lines > before;
  if (frozen) {
    lines = before;
  }
  // Alerte de surmenage (mouvements principaux) : deux séances mesurées de
  // suite nettement sous la précédente — une semaine à volume réduit (environ 40 % des lignes), intensité gardée
  // (hors semaines déjà allégées et tests).
  final p = run.ctx.params;
  final ease = track.easeDay;
  var eased = 0;
  if (ease != null &&
      run.day > ease &&
      run.day - ease <= p.coachOverreachDays &&
      c.policy.build &&
      ex.spec.main &&
      lines >= 2) {
    eased = (lines * p.coachOverreachCut).round();
    if (eased < 1) {
      eased = 1;
    }
    lines -= eased;
  }
  final out = mode == CapacityMode.loaded
      ? _loadedPlans(run, ex, c, item, lines, served)
      : _directPlans(run, ex, c, item, lines, served);
  // Lignes retenues : elles valent aussi quand la règle générale de 0.1
  // sert l'exercice (aucune cible du mode coach).
  ex.lines = lines;
  if (lines < sets) {
    ex.notes.add(
      _r(ReasonCodes.adaptVolumeDown, <String, Object?>{'sets': sets - lines}),
    );
  }
  if (eased > 0) {
    ex.notes.add(
      _r(ReasonCodes.adaptFatigueHigh, <String, Object?>{
        'readiness': roundTo(track.easeRatio, 3),
      }),
    );
  }
  return out;
}

int _restOf(ExerciseRun ex, CoachSpec c, SetTechniqueKind served, int reps) {
  final t = c.item.technique;
  if (served == SetTechniqueKind.emom && t != null) {
    final interval = t.intervalSeconds;
    if (interval != null) {
      final rest = interval - reps * 3;
      return rest < 10 ? 10 : rest;
    }
  }
  return ex.spec.restSeconds;
}

List<SetPlan>? _loadedPlans(
  SessionRun run,
  ExerciseRun ex,
  CoachSpec c,
  ExercisePrescription item,
  int sets,
  SetTechniqueKind served,
) {
  final p = run.ctx.params;
  final info = ex.info;
  final track = ex.track!;
  final grid = info.grid;
  final bw = info.fraction * run.bodyWeightKg;
  final pct = c.pct;
  final ref = referenceTotal(run, ex, c);
  if (pct == null || ref == null || ref <= 0) {
    return null;
  }
  final ownRef = c.referenceId == null || c.referenceId == info.id;
  final rir = ex.rirEff;
  final flames = flamesOfRir(rir);
  final t = item.technique;
  final lines = <(int, int, SetRole?)>[
    for (var i = 0; i < sets; i++) c.line(i, sets, served, hold: false),
  ];

  // Lignes qui partagent la charge de tête, avec leur fatigue prévue.
  final topSet = served == SetTechniqueKind.topSetBackoff;
  final head = <(int, double)>[];
  final tail = <(int, double)>[];
  if (served == SetTechniqueKind.cluster && t != null) {
    final mini = t.miniSets ?? 1;
    final each = t.miniSetReps ?? lines.first.$2;
    final intra = t.intraRestSeconds ?? 30;
    for (var i = 0; i < mini; i++) {
      head.add((each, plannedFatigue(i, rir, intra, p)));
    }
  } else {
    for (var i = 0; i < sets; i++) {
      final rest = _restOf(ex, c, served, lines[i].$2);
      final entry = (lines[i].$2, plannedFatigue(i, rir, rest, p));
      if (topSet && i > 0) {
        tail.add(entry);
      } else {
        head.add(entry);
      }
    }
  }
  final worst = rir - p.coachWorstSetSlack < 0.5
      ? 0.5
      : rir - p.coachWorstSetSlack;
  // Sans suivi propre fiable (variante calée sur un autre mouvement), le
  // plafond d'effort ne se juge pas encore : la part du bloc vaut.
  final judged = ownRef || !ex.uncertain || track.lastLoad != null;
  bool pilotOk(double kg) =>
      !judged || _holdsRir(run, ex, kg, head, rir, worst);
  bool guardOk(double kg) =>
      !judged || _holdsRir(run, ex, kg, head, rir - p.coachBreachRir, worst);

  // Exercice surchargé (au-dessus du 1RM de référence) sur une zone à
  // antécédent : jamais plus que le 1RM de référence.
  final overload = !ownRef && pct > p.coachOverloadFragileMax && c.fragile;
  final pctWritten = overload ? p.coachOverloadFragileMax : pct;
  // Exercice jamais fait, écrit en part du 1RM d'un autre mouvement :
  // entrée graduée (R5-P22), la hausse suit ensuite le plafond de hausse
  // à schéma égal.
  final entry = !ownRef && track.lastLoad == null && item.kind != SetKind.test;
  final written = _onGrid(
    grid,
    pctWritten * ref * (entry ? p.coachNewExerciseShare : 1) - bw,
    nearest: true,
  );
  final pilot =
      !entry &&
      !overload &&
      c.policy.build &&
      !c.light &&
      !c.eventNear &&
      c.level >= 1 &&
      served != SetTechniqueKind.accentuatedEccentric &&
      ex.painZones.isEmpty &&
      !run.noIncrease;
  double kg;
  var capped = false;
  if (served == SetTechniqueKind.accentuatedEccentric && t != null) {
    // Charge de la descente : part du 1RM écrite par la technique, jamais
    // au-dessus de 110 % (R2-P17).
    final share = t.eccentricLoadPct ?? pct;
    kg = _onGrid(grid, (share > 1.1 ? 1.1 : share) * ref - bw);
  } else if (pilot) {
    final streak = track.slotMarks[c.slotId]?.easy ?? 0;
    var up = ex.uncertain
        ? 0.0
        : p.coachCorridorUp + p.coachCorridorWiden * streak;
    if (up > p.coachCorridorUpMax) {
      up = p.coachCorridorUpMax;
    }
    final low = _onGrid(grid, (pct - p.coachCorridorDown) * ref - bw);
    final high = _onGrid(grid, (pct + up) * ref - bw);
    kg = high;
    while (kg > low + 1e-9 && !pilotOk(kg)) {
      final next = grid.next(kg, up: false);
      if (next >= kg - 1e-9) {
        break;
      }
      kg = next;
    }
    if (!guardOk(kg)) {
      kg = _stepDownTo(grid, kg, 8, guardOk);
      capped = true;
    }
  } else {
    kg = written;
    if (!guardOk(kg)) {
      // (Exercice calé sur un autre mouvement : la charge écrite peut être
      // loin de ce que son propre suivi permet.)
      kg = _stepDownTo(grid, kg, ownRef ? 8 : 400, guardOk);
      capped = true;
    }
  }

  // Garde-fous : hausse bornée à schéma égal, aucune hausse après un échec
  // non prévu, sur une zone douloureuse ou un jour de bilan bas.
  ex.heldCause = null;
  ex.coarse = false;
  final mark = track.slotMarks[c.slotId];
  final markLoad = mark != null && mark.amount == lines.first.$2
      ? mark.loadKg
      : null;
  // (Répétitions écrites non atteintes à la dernière séance de
  // l'emplacement : pas de hausse non plus.)
  final missed = mark != null && mark.top > 0 && mark.top < mark.amount;
  final lockCause = track.noUp || (mark != null && mark.failed)
      ? 'failure'
      : (ex.painZones.isNotEmpty
            ? 'pain'
            : (run.noIncrease ? 'health' : (missed ? 'reps' : null)));
  if (markLoad != null) {
    if (kg > markLoad + 1e-9) {
      final floored = grid.floor(markLoad);
      final last = floored > markLoad ? markLoad : floored;
      if (lockCause != null) {
        kg = last;
        ex.heldCause = lockCause;
      } else {
        // (Exercice calé sur le 1RM d'un autre mouvement, encore sous la
        // charge écrite : il la rejoint par paliers de 10 % au plus, 5 %
        // sur une zone à antécédent — R5-P22.)
        final rise = ownRef
            ? coachRiseOf(c, p)
            : (c.fragile ? p.maxUpMain / 2 : p.maxUpMain);
        final cap = grid.floor((markLoad + bw) * (1 + rise) - bw);
        final step = grid.next(last, up: true);
        final ceiling = cap > step ? cap : step;
        if (kg > ceiling + 1e-9) {
          kg = ceiling;
          ex.heldCause = 'cap';
        }
      }
    }
  } else if (lockCause != null && kg > written + 1e-9) {
    // Première fois à ce schéma un jour sans hausse : la part du bloc, pas
    // davantage.
    kg = written;
    ex.heldCause = lockCause;
  }
  final lastAny = track.lastLoad;
  if (markLoad == null && lastAny != null && !ex.calibrating) {
    // Premier passage à ce schéma : au plus la charge écrite par le bloc,
    // sauf à rester à +10 % (ou un cran) de la plus lourde barre récente.
    // (La plus lourde barre réussie des dernières semaines, quel que soit
    // le schéma ; sans elle, la dernière charge.)
    final heaviest = recentHeavy(track, run.day, p) ?? lastAny;
    final base = heaviest > lastAny ? heaviest : lastAny;
    final cap = grid.floor((base + bw) * (1 + p.maxUpMain) - bw);
    final step = grid.next(base, up: true);
    var bound = cap > step ? cap : step;
    final start = item.startLoadKg;
    if (ownRef && start != null && start > bound) {
      bound = start;
    }
    if (kg > bound + 1e-9) {
      kg = bound;
      ex.heldCause = 'cap';
    }
  }
  if (lastAny != null && kg > lastAny + 1e-9) {
    // Invariants de 0.1 : aucune hausse par rapport à la dernière séance
    // de l'exercice après un échec non prévu ni sur une zone douloureuse.
    final cause = track.noUp
        ? 'failure'
        : (ex.painZones.isNotEmpty ? 'pain' : null);
    if (cause != null) {
      final floored = grid.floor(lastAny);
      kg = floored > lastAny ? lastAny : floored;
      ex.heldCause = cause;
    }
  }
  // Simple d'entraînement : 92 % au plus du maximum estimé du jour, 85 %
  // un jour de bilan bas (CX, correction 1 : un simple servi à 96 % un
  // jour de bilans bas finit en échec ; Helms et al. 2018).
  if (item.kind != SetKind.test &&
      lines.isNotEmpty &&
      lines.first.$2 == 1 &&
      served != SetTechniqueKind.accentuatedEccentric &&
      ownRef) {
    final share = run.health.level >= 1 ? 0.85 : 0.92;
    final most = grid.floor(share * ref - bw);
    if (kg > most + 1e-9) {
      kg = most < grid.minimum ? grid.minimum : most;
      ex.heldCause ??= run.health.level >= 1 ? 'health' : 'cap';
    }
  }
  if (capped) {
    ex.notes.add(
      _r(ReasonCodes.adaptRirCap, <String, Object?>{
        'rir': roundTo(c.rirFloor ?? rir, 1),
      }),
    );
  }

  // Effort affiché : celui du bloc ; quand la charge servie est retenue
  // sous ce que la réserve visée demanderait (plafond de hausse, couloir,
  // semaine servie telle quelle), l'effort attendu est affiché à sa place
  // (jamais plus dur que la cible du bloc).
  int shownFor(double load, List<(int, double)> entries) {
    if (entries.isEmpty || !judged) {
      return flames;
    }
    var sum = 0.0;
    for (final (n, fatigue) in entries) {
      sum += _possible(run, ex, load, fatigue) - n;
    }
    final expected = sum / entries.length;
    if (expected < rir + 1) {
      return flames;
    }
    return flamesOfRir(expected > 5 ? 5.0 : (expected * 2).floorToDouble() / 2);
  }

  final out = <SetPlan>[];
  if (topSet && t != null) {
    final drop =
        t.backoffDropPct ??
        c.rule(AutoregulationKind.backoffFromTopSet)?.pct ??
        0.1;
    var back = _onGrid(grid, (kg + bw) * (1 - drop) - bw);
    if (back > kg) {
      back = kg;
    }
    if (pilot && judged && tail.isNotEmpty && lockCause == null) {
      // Semaine de charge : des séries allégées qui laisseraient nettement
      // plus de réserve que visé (un point de plus que la série de tête)
      // sont rapprochées de la série de tête, jusqu'à la moitié de la
      // baisse écrite (au moins `coachBackoffMinDrop`), tant que la réserve
      // visée tient.
      final least = drop / 2 > p.coachBackoffMinDrop
          ? drop / 2
          : p.coachBackoffMinDrop;
      var x = _onGrid(grid, (kg + bw) * (1 - least) - bw);
      if (x > kg) {
        x = kg;
      }
      for (var i = 0; i < 12 && x > back + 1e-9; i++) {
        if (_holdsRir(run, ex, x, tail, rir + 1, worst)) {
          back = x;
          break;
        }
        final next = grid.next(x, up: false);
        if (next >= x - 1e-9) {
          break;
        }
        x = next;
      }
    }
    if (judged && tail.isNotEmpty) {
      back = _stepDownTo(
        grid,
        back,
        6,
        (x) => _holdsRir(run, ex, x, tail, rir - p.coachBreachRir, worst),
      );
    }
    final shownTop = shownFor(kg, head);
    final shownBack = shownFor(back, tail);
    for (var i = 0; i < sets; i++) {
      final (low, high, role) = lines[i];
      out.add(
        SetPlan(
          loadKg: i == 0 ? kg : back,
          low: low,
          high: high,
          flames: i == 0 ? shownTop : shownBack,
          open: high > low,
          role: role,
        ),
      );
    }
    // Série de tête repère : quand aucune série n'a mesuré la capacité
    // depuis `coachProbeDays`, la série de tête d'une semaine de charge
    // (hors réalisation) devient ouverte — les répétitions écrites, et
    // jusqu'à `coachTopProbeReps` de plus si la réserve visée le permet.
    final exact = track.exactDay;
    final probed = track.benchmarkDay;
    if (pilot &&
        lockCause == null &&
        ex.heldCause != 'failure' &&
        c.policy.intent != WeekIntent.realization &&
        item.kind != SetKind.test &&
        lines.first.$2 >= 2 &&
        lines.first.$1 == lines.first.$2 &&
        track.lastDay != null &&
        (exact == null || run.day - exact >= p.coachProbeDays) &&
        (probed == null || run.day - probed >= p.coachProbeDays)) {
      final top = out.first;
      final reserve = rir > p.benchmarkRir ? rir : p.benchmarkRir;
      out[0] = SetPlan(
        loadKg: top.loadKg,
        low: top.low,
        high: top.high + p.coachTopProbeReps,
        flames: flamesOfRir(reserve),
        open: true,
        benchmark: true,
        role: top.role,
      );
    }
    return out;
  }
  final shown = shownFor(kg, head);
  // Vagues : la charge ne monte d'une vague à l'autre qu'un jour sans
  // verrou (ni échec récent, ni douleur, ni bilan bas, ni charge retenue).
  final waveStep =
      served == SetTechniqueKind.wave &&
          ex.heldCause == null &&
          lockCause == null
      ? t?.waveStepPct
      : null;
  final waveLength = t?.waveReps?.length ?? 1;
  for (var i = 0; i < sets; i++) {
    final (low, high, role) = lines[i];
    var load = kg;
    if (waveStep != null && waveLength > 0) {
      // La vague la plus lourde est à la charge retenue par les
      // garde-fous ; les vagues d'avant sont plus légères d'autant.
      final wave = i ~/ waveLength;
      final lastWave = (sets - 1) ~/ waveLength;
      load = _onGrid(grid, (kg + bw) / (1 + waveStep * (lastWave - wave)) - bw);
    }
    out.add(
      SetPlan(
        loadKg: load,
        low: low,
        high: high,
        flames: shown,
        open: high > low,
        role: role,
      ),
    );
  }
  _probe(run, ex, c, item, served, out);
  return out;
}

/// Vrai si l'exercice [info] est une tenue en bras tendus ou en appui dont
/// la progression est bornée pour les tendons (R4-F9, R5-P22).
bool tendonLoaded(ExerciseInfo info) =>
    info.mode == CapacityMode.hold &&
    info.exercise.family == MovementFamily.figureStatique;

/// Zone du corps la plus contrainte par l'exercice [info] parmi le poignet,
/// le coude et l'épaule (paramètre `zone` de `adapt.tendon_load`).
BodyZone tendonZone(ExerciseInfo info) {
  var best = BodyZone.shoulder;
  var level = -1.0;
  for (final zone in const <BodyZone>[
    BodyZone.elbow,
    BodyZone.shoulder,
    BodyZone.wristHand,
  ]) {
    final l = info.zoneLevel(zone);
    if (l > level) {
      level = l;
      best = zone;
    }
  }
  return best;
}

/// Durée sûre d'un maintien aujourd'hui : une part du maximum du jour
/// (`coachHoldMaxShare`), jamais plus que la dernière séance après un échec
/// non prévu, une douleur ou un bilan bas, jamais plus que le dernier
/// maintien après un échec dans la séance. La propreté arrête les séries
/// (règle `stop_on_quality_drop`).
int _holdSafe(SessionRun run, ExerciseRun ex, double fatigue, String slotId) {
  final p = run.ctx.params;
  final track = ex.track!;
  final cap = track.filter.capacityToday() * (1 - fatigue);
  var target = (p.coachHoldMaxShare * cap + 0.5).floor();
  if (!ex.spec.test &&
      track.lastDay != null &&
      (track.noUp || ex.painZones.isNotEmpty || run.noIncrease)) {
    // Après un échec non prévu ou sur une zone douloureuse : pas de hausse
    // par rapport à la dernière séance de l'exercice (I2, I3). Un jour de
    // bilan bas : par rapport à la dernière séance du même emplacement
    // (séance lourde et séance au chrono d'un même exercice ne se
    // comparent pas).
    final last = track.noUp || ex.painZones.isNotEmpty
        ? track.lastTop
        : track.slotMarks[slotId]?.top;
    if (last != null) {
      final top = last < 1 ? 1 : last;
      if (target > top) {
        target = top;
      }
    }
  }
  if (ex.fails > 0 && ex.observed.isNotEmpty) {
    final done = ex.observed.last.amount;
    final top = done < 1 ? 1 : done;
    if (target > top) {
      target = top;
    }
  }
  return target < 1 ? 1 : target;
}

/// Série repère : quand aucune série n'a mesuré la capacité depuis
/// `coachProbeDays` (toutes les notes au plafond « loin de l'échec »), la
/// dernière série classique d'un exercice devient ouverte, près de la
/// réserve du repère (APRE, Mann et al. 2010) — jamais en semaine servie
/// telle quelle, près d'une échéance, un jour léger, sur une zone
/// douloureuse, un jour de bilan bas ni après un échec.
void _probe(
  SessionRun run,
  ExerciseRun ex,
  CoachSpec c,
  ExercisePrescription item,
  SetTechniqueKind served,
  List<SetPlan> out,
) {
  final p = run.ctx.params;
  final track = ex.track!;
  final exact = track.exactDay;
  final probed = track.benchmarkDay;
  if (served != SetTechniqueKind.standard ||
      item.kind == SetKind.test ||
      out.length < 2 ||
      !c.policy.build ||
      c.light ||
      c.eventNear ||
      track.lastDay == null ||
      track.noUp ||
      ex.painZones.isNotEmpty ||
      run.noIncrease ||
      out.last.benchmark ||
      (exact != null && run.day - exact < p.coachProbeDays) ||
      (probed != null && run.day - probed < p.coachProbeDays)) {
    return;
  }
  final last = out.removeLast();
  final reserve = c.level == 0 && p.benchmarkRir < 2 ? 2.0 : p.benchmarkRir;
  out.add(
    SetPlan(
      loadKg: last.loadKg,
      low: last.low,
      // (Sans charge : jusqu'au double du haut de la plage, pour que la
      // série mesure même une plage devenue très facile.)
      high:
          last.high +
          (last.loadKg == null && last.high > p.benchmarkExtraReps
              ? last.high
              : p.benchmarkExtraReps),
      flames: flamesOfRir(reserve),
      open: true,
      benchmark: true,
      role: last.role,
    ),
  );
}

/// Répétitions sûres aujourd'hui pour un exercice sans charge : ce que le
/// bloc écrit est servi tant qu'il reste, avec la marge de prudence, la
/// réserve visée moins un point (au plus `coachDirectGuardRir`) ; mêmes
/// garde-fous que la règle générale après un échec, une douleur ou un
/// bilan bas.
int _repsSafe(SessionRun run, ExerciseRun ex, double fatigue, String slotId) {
  final p = run.ctx.params;
  final track = ex.track!;
  var guard = ex.rirEff - p.coachBreachRir;
  if (guard > p.coachDirectGuardRir) {
    guard = p.coachDirectGuardRir;
  }
  if (guard < 0.5) {
    guard = 0.5;
  }
  var target = (run.predictedAmount(ex, guard, fatigue) + 0.5).floor();
  if (!ex.spec.test &&
      track.lastDay != null &&
      (track.noUp || ex.painZones.isNotEmpty || run.noIncrease)) {
    // Après un échec non prévu ou sur une zone douloureuse : pas de hausse
    // par rapport à la dernière séance de l'exercice (I2, I3). Un jour de
    // bilan bas : par rapport à la dernière séance du même emplacement
    // (séance lourde et séance au chrono d'un même exercice ne se
    // comparent pas).
    final last = track.noUp || ex.painZones.isNotEmpty
        ? track.lastTop
        : track.slotMarks[slotId]?.top;
    if (last != null) {
      final top = last < 1 ? 1 : last;
      if (target > top) {
        target = top;
      }
    }
  }
  if (ex.fails > 0 && ex.observed.isNotEmpty) {
    final done = ex.observed.last.amount;
    final top = done < 1 ? 1 : done;
    if (target > top) {
      target = top;
    }
  }
  return target < 1 ? 1 : target;
}

List<SetPlan>? _directPlans(
  SessionRun run,
  ExerciseRun ex,
  CoachSpec c,
  ExercisePrescription item,
  int sets,
  SetTechniqueKind served,
) {
  final p = run.ctx.params;
  final info = ex.info;
  final track = ex.track!;
  final hold = info.mode == CapacityMode.hold;
  final rir = ex.rirEff;
  final flames = flamesOfRir(rir);
  final share = c.benchmarkShare;
  final follows = share != null && c.policy.build && !c.light && !c.eventNear;
  final mark = track.slotMarks[c.slotId];
  final tendon = tendonLoaded(info);
  final locked =
      track.noUp || ex.painZones.isNotEmpty || run.noIncrease || ex.fails > 0;
  // Exercice assisté (élastique, appui des pieds, machine) : la
  // progression passe par l'assistance ;
  // la plage du bloc est gardée et le moteur dit quand changer de cran.
  final assisted = info.exercise.assisted;
  var tendonCapped = false;
  // La marge de sûreté a réduit la première série.
  var guarded = false;

  // Effort affiché d'une ligne de [target] (répétitions ou secondes) après
  // la perte [fatigue] : celui du bloc ; quand la quantité servie laisse
  // nettement plus, ou nettement moins, de réserve que la cible du bloc,
  // l'effort attendu est affiché à sa place (un maintien : toujours).
  int shownFor(int target, double fatigue) {
    final cap = track.filter.capacityToday() * (1 - fatigue);
    final expected = hold
        ? (cap <= 0 ? 0.0 : (1 - target / cap) / p.holdReserveShare)
        : cap - target;
    if (expected >= rir + 1 || expected <= rir - 1 || (hold && expected >= 0)) {
      final e = expected > 5 ? 5.0 : (expected < 0.5 ? 0.5 : expected);
      return flamesOfRir((e * 2).floorToDouble() / 2);
    }
    return flames;
  }

  final (firstLow, firstHigh, firstRole) = c.line(0, sets, served, hold: hold);
  if (!hold &&
      !assisted &&
      !(follows && firstLow == firstHigh) &&
      served == SetTechniqueKind.standard &&
      item.kind != SetKind.test &&
      firstLow > 1) {
    final rest = _restOf(ex, c, served, firstHigh);
    final reach = _repsSafe(run, ex, plannedFatigue(0, rir, rest, p), c.slotId);
    // Chaque série garde la réserve du bloc.
    final kept = (track.filter.capacityToday() - rir + 0.3).floor();
    if (reach < firstLow || (c.policy.build && kept < firstLow)) {
      // Plage hors de portée aujourd'hui (le bas de la plage ne laisse pas
      // la réserve visée) : séries fractionnées — moins de répétitions par
      // série, plus de séries, pour approcher le travail écrit (au plus le
      // double des séries, trois au moins permises ; le total vise le
      // bas de la plage écrite, à moins d'une série près).
      final each = kept < 1 ? 1 : (kept < reach ? kept : reach);
      var count = (sets * firstLow / each).ceil();
      // Après un échec, sur une zone douloureuse ou un jour de bilan bas :
      // aucune série ajoutée ; de même tant qu'aucune série n'a mesuré le
      // maximum (exercice encore estimé d'après le profil), ou quand le
      // bloc écrit une technique (servie ou non).
      final exact = track.exactDay;
      final known =
          !ex.calibrating &&
          item.technique == null &&
          c.item.technique == null &&
          !ex.techniqueWithheld &&
          exact != null &&
          run.day - exact <= 2 * p.coachProbeDays;
      final most = locked || !known || c.policy.locked
          ? sets
          : (2 * sets < 3 ? 3 : 2 * sets);
      if (count > most) {
        count = most;
      }
      ex.notes.add(
        _r(ReasonCodes.adaptRepsDown, <String, Object?>{
          'delta': firstLow - each,
        }),
      );
      ex.split = count > sets;
      return <SetPlan>[
        for (var i = 0; i < count; i++)
          SetPlan(
            loadKg: null,
            low: each,
            high: each,
            flames: shownFor(each, plannedFatigue(i, rir, rest, p)),
            role: firstRole,
          ),
      ];
    }
  }

  final out = <SetPlan>[];
  for (var i = 0; i < sets; i++) {
    final (low, high, role) = c.line(i, sets, served, hold: hold);
    final rest = _restOf(ex, c, served, high);
    final fatigue = plannedFatigue(i, rir, rest, p);
    // Ce que le modèle prévoit de sûr aujourd'hui (réserve gardée, marge de
    // prudence, garde-fous après échec, douleur ou bilan bas).
    final safe = hold
        ? _holdSafe(run, ex, fatigue, c.slotId)
        : _repsSafe(run, ex, fatigue, c.slotId);
    int? easyTop;
    var wanted = high;
    if (follows && low == high) {
      // Part d'un test : elle suit le maximum mesuré, dans les deux sens —
      // et la série garde la réserve écrite (« série de tête = maximum
      // mesuré moins la réserve », jamais sur un progrès supposé).
      final cap = track.filter.capacityToday();
      final fromTest = (share * cap + 0.5).floor();
      wanted = fromTest < 1 ? 1 : fromTest;
      if (!hold && wanted > high) {
        // Au-dessus de ce que le bloc écrit : une répétition de plus que
        // la dernière séance de l'emplacement au plus (la règle du
        // programme : « +1 répétition quand la réserve est dépassée »),
        // jamais d'un coup.
        final lift = mark == null ? 0 : mark.top + 1 - firstHigh;
        final most = high + (lift > 0 ? lift : 0);
        if (wanted > most) {
          wanted = most;
        }
      }
      if (!hold) {
        final kept = (cap * (1 - fatigue) - rir + 0.3).floor();
        if (kept < wanted) {
          wanted = kept < 1 ? 1 : kept;
        }
      }
    } else if (!hold &&
        share == null &&
        !assisted &&
        served == SetTechniqueKind.standard &&
        item.kind != SetKind.test &&
        c.policy.build &&
        !c.light &&
        !c.eventNear) {
      // Sans charge, les répétitions sont le seul réglage : quand la plage
      // du bloc est devenue trop facile, elle s'étend comme en 0.1 (au
      // plus le double), jusqu'à ce que la revue propose une variante plus
      // dure.
      final extended = run.targetAmount(ex, fatigue);
      if (extended > wanted) {
        wanted = extended;
      }
      if (ex.easyMode) {
        // Dernière séance notée « plus facile que visé » : séries au
        // ressenti jusqu'au haut de plage étendu (elles diront ce que la
        // plage vaut, que les notes ne bornent que par le bas).
        easyTop = ex.spec.wideTop;
      }
    }
    if (hold &&
        share == null &&
        c.policy.build &&
        !c.eventNear &&
        !locked &&
        item.kind != SetKind.test) {
      // Maintien devenu très facile : quand une tenue a mesuré le maximum
      // et que la durée écrite en vaut moins de 40 %, la durée monte vers
      // la moitié du maximum (R4-F2 : maintiens à 50–70 % du maximum) —
      // par les paliers de hausse des tendons, jamais d'un coup.
      final exact = track.exactDay;
      final cap = track.filter.capacityToday();
      if (exact != null &&
          run.day - exact <= 2 * p.coachProbeDays &&
          high < p.coachHoldEasyShare * cap) {
        final floorHalf = (p.coachHoldUsefulShare * cap).floor();
        if (floorHalf > wanted) {
          wanted = floorHalf;
        }
      }
    }
    var target = wanted < safe ? wanted : safe;
    if (i == 0 && safe < wanted) {
      guarded = true;
    }
    if (!hold &&
        !(follows && low == high) &&
        !assisted &&
        item.kind != SetKind.test) {
      // Plage : le haut servi garde la réserve du bloc (« jamais plus que
      // le maximum moins la réserve »), sans descendre sous le bas de la
      // plage tant qu'il reste sûr.
      final kept = (track.filter.capacityToday() * (1 - fatigue) - rir + 0.3)
          .floor();
      if (kept < target) {
        target = kept >= low ? kept : (low < target ? low : target);
      }
    }
    if (easyTop != null && easyTop > target) {
      final floor = target < low ? target : low;
      out.add(
        SetPlan(
          loadKg: null,
          low: floor < 1 ? 1 : floor,
          high: easyTop,
          flames: flames,
          open: true,
          role: role,
        ),
      );
      continue;
    }
    if (tendon &&
        mark != null &&
        mark.top > 0 &&
        item.kind != SetKind.test &&
        target > mark.top) {
      // Bras tendus : hausse bornée d'une séance à la suivante.
      final rise =
          p.coachHoldRise[c.level < 0 ? 0 : (c.level > 3 ? 3 : c.level)];
      final byShare = (mark.top * (1 + rise)).floor();
      final bySlack = mark.top + p.coachHoldRiseSlackSeconds;
      final cap = byShare > bySlack ? byShare : bySlack;
      if (target > cap) {
        target = cap;
        tendonCapped = true;
      }
    }
    if (target < 1) {
      target = 1;
    }
    final shown = shownFor(target, fatigue);
    if (high > low && target >= low && !follows) {
      // Plage du bloc : série au ressenti, sans dépasser ce qui est sûr.
      out.add(
        SetPlan(
          loadKg: null,
          low: low,
          high: target,
          flames: shown,
          open: target > low,
          role: role,
        ),
      );
    } else {
      out.add(
        SetPlan(
          loadKg: null,
          low: target,
          high: target,
          flames: shown,
          role: role,
        ),
      );
    }
  }
  if (hold && tendon && mark != null && mark.total > 0 && out.length > 1) {
    // Bras tendus : le temps total sous tension de l'emplacement ne monte
    // pas plus vite que la durée d'une tenue (séries ajoutées comprises) :
    // un seul changement à la fois (R4-F9, R5-P22).
    final rise = p.coachHoldRise[c.level < 0 ? 0 : (c.level > 3 ? 3 : c.level)];
    final byShare = (mark.total * (1 + rise)).floor();
    final bySlack = mark.total + p.coachHoldRiseSlackSeconds;
    final most = byShare > bySlack ? byShare : bySlack;
    var total = 0;
    for (final s in out) {
      total += s.high;
    }
    if (item.kind != SetKind.test && total > most) {
      final each = most ~/ out.length < 1 ? 1 : most ~/ out.length;
      for (var i = 0; i < out.length; i++) {
        final s = out[i];
        if (s.high > each) {
          out[i] = SetPlan(
            loadKg: null,
            low: s.low > each ? each : s.low,
            high: each,
            flames: shownFor(each, 0),
            open: s.open && each > (s.low > each ? each : s.low),
            role: s.role,
          );
        }
      }
      tendonCapped = true;
    }
  }
  if (!hold && share == null) {
    _probe(run, ex, c, item, served, out);
  }
  if (hold && item.kind != SetKind.test && out.isNotEmpty) {
    // Tenue repère : quand le moteur sert moins que la durée écrite parce
    // que son estimation du maintien maximal est basse et qu'aucune tenue
    // ne l'a mesuré depuis `coachProbeDays`, la dernière tenue est
    // ouverte jusqu'à la durée écrite par le bloc (jamais au-delà), arrêt
    // avant la perte de position.
    final (_, writtenHigh, _) = c.line(
      out.length - 1,
      sets,
      served,
      hold: true,
    );
    final exact = track.exactDay;
    final probed = track.benchmarkDay;
    final last = out.last;
    // Bras tendus et appuis : la tenue repère garde la borne de hausse
    // d'une séance à la suivante.
    var probeHigh = writtenHigh;
    if (tendon && mark != null && mark.top > 0) {
      final rise =
          p.coachHoldRise[c.level < 0 ? 0 : (c.level > 3 ? 3 : c.level)];
      final byShare = (mark.top * (1 + rise)).floor();
      final bySlack = mark.top + p.coachHoldRiseSlackSeconds;
      final cap = byShare > bySlack ? byShare : bySlack;
      if (probeHigh > cap) {
        probeHigh = cap;
      }
    }
    if (!locked &&
        !tendonCapped &&
        !c.light &&
        c.policy.build &&
        !c.eventNear &&
        share == null &&
        track.lastDay != null &&
        last.high < probeHigh &&
        (exact == null || run.day - exact >= p.coachProbeDays) &&
        (probed == null || run.day - probed >= p.coachProbeDays)) {
      out[out.length - 1] = SetPlan(
        loadKg: null,
        low: last.high,
        high: probeHigh,
        flames: flamesOfRir(2),
        open: true,
        benchmark: true,
        role: last.role,
      );
    }
  }
  if (assisted && !hold && item.kind != SetKind.test && out.isNotEmpty) {
    // Assistance : quand une série a mesuré la capacité récemment et que
    // le haut de la plage laisse nettement plus de réserve que visé, un
    // cran d'assistance de moins (élastique plus fin) ; quand le bas de la
    // plage ne laisse plus la réserve visée moins un point, un cran de
    // plus.
    final exact = track.exactDay;
    final probed = track.benchmarkDay;
    final measured =
        (exact != null && run.day - exact <= 2 * p.coachProbeDays) ||
        (probed != null && run.day - probed <= 2 * p.coachProbeDays);
    // (Une série repère notée « loin de l'échec » borne la capacité par le
    // bas : cela suffit pour retirer un cran d'assistance.)
    final shown = track.probeCapacity;
    final estimate = track.filter.capacityToday();
    final cap = shown != null && shown > estimate ? shown : estimate;
    final spare = cap - c.schemeAmount - rir;
    final (low, _, _) = c.line(0, sets, served, hold: false);
    // (Règle d'assistance du programme : deux séances de suite au haut de
    // la plage avec la réserve prévue, ou première série dite au moins
    // deux répétitions plus facile que visé — un cran de moins.)
    final streak = (mark?.reached ?? 0) >= 2;
    if (!locked &&
        c.policy.build &&
        !c.eventNear &&
        (streak || (measured && spare >= p.coachAssistGapRir - 1e-9))) {
      ex.notes.add(
        _r(ReasonCodes.adaptFlamesBelowTarget, <String, Object?>{
          'delta': roundTo(spare > 2 ? spare : 2.0, 1),
          'sets': sets,
        }),
      );
    } else if (track.lastDay != null &&
        (track.noUp || (track.lastTop > 0 && track.lastTop < low))) {
      // (Un cran de plus seulement sur ce que l'athlète a fait : échec, ou
      // bas de la plage manqué à la dernière séance.)
      ex.notes.add(
        _r(ReasonCodes.adaptFlamesAboveTarget, <String, Object?>{
          'delta': roundTo(low - track.lastTop.toDouble(), 1),
          'sets': sets,
        }),
      );
    }
  }
  if (tendonCapped) {
    final first = track.firstDay;
    ex.notes.add(
      _r(ReasonCodes.adaptTendonLoad, <String, Object?>{
        'zone': tendonZone(info).code,
        'weeks': first == null ? 0 : (run.day - first) ~/ 7,
      }),
    );
  }
  if (out.isNotEmpty && !hold) {
    final floor = c.rirFloor;
    if (guarded && out.first.high < c.schemeAmount && floor != null) {
      ex.notes.add(
        _r(ReasonCodes.adaptRirCap, <String, Object?>{
          'rir': roundTo(floor, 1),
        }),
      );
    } else if (follows && out.first.high != c.schemeAmount) {
      // Recalé sur le maximum mesuré : dit en clair.
      final delta = out.first.high - c.schemeAmount;
      ex.notes.add(
        _r(
          delta > 0 ? ReasonCodes.adaptRepsUp : ReasonCodes.adaptRepsDown,
          <String, Object?>{'delta': delta.abs()},
        ),
      );
    }
  }
  return out;
}

/// Écart-type relatif du maximum du jour de l'exercice [ex] : estimation
/// et effet de jour.
double dayRelSd(ExerciseRun ex) {
  final f = ex.track!.filter;
  return f.loadSd(1);
}

List<SetPlan>? _testPlans(
  SessionRun run,
  ExerciseRun ex,
  CoachSpec c,
  ExercisePrescription item,
  int sets,
) {
  final p = run.ctx.params;
  final info = ex.info;
  final track = ex.track!;
  final f = track.filter;
  final test = item.test!;
  final kind = test.kind;
  final hold = info.mode == CapacityMode.hold;
  final loaded = info.mode == CapacityMode.loaded;
  final low = (hold ? item.secondsLow : item.repsLow) ?? 1;
  final high = (hold ? item.secondsHigh : item.repsHigh) ?? low;
  final locked = track.noUp || ex.painZones.isNotEmpty || run.noIncrease;
  if (loaded &&
      (kind == TestKind.oneRm || kind == TestKind.attemptSimulation)) {
    final bw = info.fraction * run.bodyWeightKg;
    final recent = recentHeavy(track, run.day, p);
    final lift = competitionLiftOf(run.ctx.profile, info.id, run.day);
    final ladder = attemptLadder(
      estimateTotal: exp(f.m[0] + f.m[3] + f.gRef),
      relSd: dayRelSd(ex),
      bodyPart: bw,
      grid: info.grid,
      attempts: sets,
      done: const <(double, bool)>[],
      recentBest: recent,
      targetKg: lift?.targetKg,
      objective: kind == TestKind.attemptSimulation
          ? EventObjective.secureTotal
          : null,
      healthLevel: run.health.level,
      prudentCause: track.noUp
          ? 'previous_failure'
          : (ex.painZones.isNotEmpty ? 'pain' : null),
      p: p,
      minIncrementKg: lift?.minIncrementKg,
    );
    final out = <SetPlan>[];
    for (var i = 0; i < sets; i++) {
      final a = ladder[i < ladder.length ? i : ladder.length - 1];
      out.add(
        SetPlan(
          loadKg: a.loadKg,
          low: 1,
          high: 1,
          flames: i == 0 ? 7 : (i == 1 ? 9 : Flames.failure),
          role: SetRole.attempt,
        ),
      );
    }
    if (ladder.isNotEmpty) {
      ex.notes.add(
        _r(ReasonCodes.adaptAttemptOpener, <String, Object?>{
          'pct': roundTo(ladder.first.share, 3),
        }),
      );
    }
    return out;
  }
  final targetRir = test.targetRir ?? 1;
  final flames = flamesOfRir(targetRir);
  if (loaded) {
    // xRM ou série d'estimation : la charge que le modèle prévoit pour les
    // répétitions dites en gardant la réserve du test.
    final bw = info.fraction * run.bodyWeightKg;
    final n = high + targetRir;
    final shift = -run.quantileZ(targetRir) * f.loadSd(n);
    var kg = _onGrid(info.grid, exp(f.logLoadFor(n, shift: shift)) - bw);
    // Semaine allégée ou de test : jamais plus lourd que la charge écrite
    // par le programme (CX, correction 1 ; un test servi au-dessus du
    // plan finit en échec).
    final written = item.startLoadKg;
    if (c.policy.locked && written != null && kg > written + 1e-9) {
      kg = info.grid.floor(written) > written
          ? written
          : info.grid.floor(written);
    }
    final last = track.lastLoad;
    if (locked && last != null && kg > last) {
      final floored = info.grid.floor(last);
      kg = floored > last ? last : floored;
      ex.heldCause = track.noUp
          ? 'failure'
          : (ex.painZones.isNotEmpty ? 'pain' : 'health');
    }
    return <SetPlan>[
      for (var i = 0; i < sets; i++)
        SetPlan(
          loadKg: kg,
          low: low,
          high: kind == TestKind.amrapEstimate && high == low ? low + 6 : high,
          flames: flames,
          open: kind == TestKind.amrapEstimate || high > low,
          role: SetRole.test,
        ),
    ];
  }
  // Répétitions ou maintien maximal : série ouverte, la prévision prudente
  // sert de repère bas.
  final out = <SetPlan>[];
  for (var i = 0; i < sets; i++) {
    final fatigue = plannedFatigue(i, targetRir, ex.spec.restSeconds, p);
    var floor = (run.predictedAmount(ex, targetRir, fatigue)).floor();
    if (locked && track.lastTop > 0 && floor > track.lastTop) {
      floor = track.lastTop;
    }
    if (floor > low) {
      floor = low;
    }
    if (floor < 1) {
      floor = 1;
    }
    var top = high > floor ? high : floor + (hold ? 5 : 2);
    if (locked && track.lastTop > 0 && top > track.lastTop) {
      top = track.lastTop < floor ? floor : track.lastTop;
    }
    out.add(
      SetPlan(
        loadKg: null,
        low: floor,
        high: top,
        flames: flames,
        open: top > floor,
        role: SetRole.test,
      ),
    );
  }
  return out;
}

/// Tentative proposée.
final class AttemptPick {
  /// Tentative de rang [index] à la charge externe [loadKg].
  const AttemptPick({
    required this.index,
    required this.loadKg,
    required this.probability,
    required this.share,
    required this.cause,
  });

  /// Rang (0 = ouverture).
  final int index;

  /// Charge externe, en kg.
  final double loadKg;

  /// Probabilité de réussite estimée.
  final double probability;

  /// Part du maximum estimé du jour (charge totale).
  final double share;

  /// Cause d'une tentative prudente (`uncertainty`, `previous_failure`,
  /// `health`, `untested`, `weigh_in`), ou `null`.
  final String? cause;
}

/// Probabilité de réussir la charge totale [total] quand le maximum du
/// jour est estimé à [estimateTotal] avec l'écart-type relatif [relSd].
double attemptProbability(double total, double estimateTotal, double relSd) {
  if (total <= 0) {
    return 1;
  }
  final sd = relSd < 0.01 ? 0.01 : relSd;
  return normCdf((ln(estimateTotal) - ln(total)) / sd);
}

/// Tentatives restantes d'un mouvement (ouverture, deuxième, troisième…),
/// de la plus légère à la plus lourde.
///
/// [estimateTotal] : maximum du jour estimé (charge totale) ; [relSd] : son
/// écart-type relatif ; [bodyPart] : part du poids du corps dans la charge
/// totale ; [done] : tentatives déjà faites (charge externe, réussite) ;
/// [recentBest] : plus lourde barre réussie récemment à l'entraînement ;
/// [targetKg] : barre visée ; [prudentCause] : cause d'une prudence de plus
/// (`pain`, `previous_failure`, `weigh_in`), ou `null`.
List<AttemptPick> attemptLadder({
  required double estimateTotal,
  required double relSd,
  required double bodyPart,
  required LoadGrid grid,
  required int attempts,
  required List<(double, bool)> done,
  required double? recentBest,
  required double? targetKg,
  required EventObjective? objective,
  required int healthLevel,
  required String? prudentCause,
  required AdaptParams p,
  double? minIncrementKg,
}) {
  var estimate = estimateTotal;
  String? globalCause;
  if (healthLevel > 0) {
    estimate *= 1 - p.attemptLowHealthShare * healthLevel;
    globalCause = 'health';
  }
  if (prudentCause != null) {
    estimate *= 1 - p.attemptLowHealthShare;
    globalCause ??= prudentCause;
  }
  if (relSd > p.calibrationSd) {
    globalCause ??= 'uncertainty';
  }
  double chance(double kg) =>
      attemptProbability(kg + bodyPart, estimate, relSd);
  final step = minIncrementKg != null && minIncrementKg > grid.step
      ? minIncrementKg
      : grid.step;

  // Plus forte charge de la grille dont la probabilité de réussite atteint
  // `probability`, sans dépasser la part `share` du maximum estimé.
  double heaviest(double probability, double share) {
    var kg = _onGrid(grid, share * estimate - bodyPart);
    for (var i = 0; i < 400 && chance(kg) < probability; i++) {
      final next = grid.next(kg, up: false);
      if (next >= kg - 1e-9) {
        break;
      }
      kg = next;
    }
    return kg;
  }

  double third() {
    if (objective == EventObjective.secureTotal) {
      return p.attemptSecureProbability;
    }
    if (objective == EventObjective.record) {
      return p.attemptRecordProbability;
    }
    return p.attemptThirdProbability;
  }

  final out = <AttemptPick>[];
  double? previous;
  var previousOk = true;
  if (done.isNotEmpty) {
    previous = done.last.$1;
    previousOk = done.last.$2;
  }
  for (var index = done.length; index < attempts; index++) {
    double kg;
    String? cause = globalCause;
    if (previous != null && !previousOk) {
      // Tentative manquée : la même barre, jamais une plus légère.
      kg = previous;
      cause = 'previous_failure';
    } else if (index == 0) {
      kg = heaviest(p.attemptOpenerProbability, p.attemptOpenerShare);
      final best = recentBest;
      if (best != null) {
        if (kg > best && best + bodyPart >= 0.85 * estimate) {
          // Une ouverture est une barre déjà réussie à l'entraînement.
          final floored = grid.floor(best);
          kg = floored > best ? best : floored;
        }
      } else {
        cause ??= 'untested';
      }
    } else {
      final probability = index == 1 ? p.attemptSecondProbability : third();
      kg = heaviest(probability, 1.5);
      final goal = targetKg;
      if (index >= 2 &&
          goal != null &&
          goal > kg &&
          chance(goal) >= p.attemptRecordProbability &&
          objective == EventObjective.record) {
        final floored = grid.floor(goal);
        kg = floored > goal ? goal : floored;
      }
    }
    if (previous != null && previousOk && index >= 1) {
      // Sauts des tentatives (CX, correction 1 ; pratique des élites :
      // deuxième vers +4 à 5 %, troisième vers +2 à 3 %, Travis et al.) :
      // jamais au-delà du plan écrit (+5 kg de charge externe au plus).
      final rise = index == 1 ? 0.05 : 0.03;
      var cap = grid.floor((previous + bodyPart) * (1 + rise) - bodyPart);
      if (cap > previous + 5.0 + 1e-9) {
        cap = grid.floor(previous + 5.0);
      }
      if (kg > cap) {
        kg = cap;
      }
    }
    if (previous != null) {
      final least = previousOk ? previous + step : previous;
      if (kg < least) {
        kg = least;
      }
    }
    out.add(
      AttemptPick(
        index: index,
        loadKg: kg,
        probability: chance(kg),
        share: (kg + bodyPart) / estimateTotal,
        cause: cause,
      ),
    );
    previous = kg;
    previousOk = true;
  }
  return out;
}

/// Mouvement de compétition [exerciseId] de l'échéance du profil la plus
/// proche à partir du jour [day] (barre visée, plus petit saut de charge),
/// ou `null`.
CompetitionLift? competitionLiftOf(
  AthleteProfile profile,
  String exerciseId,
  int day,
) {
  CompetitionLift? best;
  int? bestDay;
  for (final event in profile.events ?? const <SeasonEvent>[]) {
    final when = event.date.dayNumber;
    if (when < day) {
      continue;
    }
    for (final lift in event.lifts ?? const <CompetitionLift>[]) {
      if (lift.exerciseId == exerciseId &&
          (bestDay == null || when < bestDay)) {
        best = lift;
        bestDay = when;
      }
    }
  }
  return best;
}
