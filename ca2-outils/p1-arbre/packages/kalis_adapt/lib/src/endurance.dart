/// Conduite des exercices d'endurance, de conditionnement et de mobilité
/// (lot CA2, partie 1). Le moteur ne les modélise pas en capacité (ni
/// 1RM, ni maximum de répétitions) : il lit ce que l'athlète a fait (durées,
/// distances, effort noté) et sert la prescription du bloc, raccourcie ou
/// rendue plus facile quand le journal ou le bilan du jour le demandent —
/// jamais plus longue, plus rapide ni plus dure que l'écrit.
///
/// Règles et sources : `CONTRAT.md`, § 12.
library;

import 'package:kalis_core/kalis_core.dart';

import 'book.dart';
import 'numeric.dart';
import 'params.dart';
import 'replay.dart';

/// Nature d'un exercice non modélisé.
enum EnduranceKind {
  /// Course à pied (impact) : footing, sortie longue, fractionné, côtes.
  run,

  /// Autre cardio (vélo, rameur, natation, marche, corde).
  cardio,

  /// Conditionnement (pièces d'un WOD, circuits).
  conditioning,

  /// Mobilité, étirements, récupération.
  mobility,
}

/// Matériel qui fait d'un cardio une course à pied.
const Set<String> runningEquipment = <String>{
  'piste ou terrain extérieur',
  'tapis de course',
  'côte ou escaliers',
};

/// Fragments d'identifiant d'une séance de course de qualité (allure,
/// fractionné, sprint), quand l'effort visé n'est pas écrit.
const List<String> qualityRunIds = <String>[
  'fractionne',
  'seuil',
  'tempo',
  '30-30',
  'sprint',
  'cotes',
  'fartlek',
  'intervalles',
  'navettes',
  'accelerations',
];

/// Nature de l'exercice [info], ou `null` s'il est modélisé.
EnduranceKind? enduranceKindOf(ExerciseInfo info) {
  if (info.mode != null) {
    return null;
  }
  final e = info.exercise;
  switch (e.family) {
    case MovementFamily.cardio:
      final walk = e.id.startsWith('ca-marche');
      final drill = e.id.startsWith('ca-educatif');
      if (!walk && !drill && e.equipment.any(runningEquipment.contains)) {
        return EnduranceKind.run;
      }
      return EnduranceKind.cardio;
    case MovementFamily.conditionnement:
      return EnduranceKind.conditioning;
    case MovementFamily.mobilite:
    case MovementFamily.recuperation:
      return EnduranceKind.mobility;
    default:
      return null;
  }
}

/// Une course faite (les lignes de course d'une séance).
final class RunBout {
  /// Course du jour [day], de [seconds] secondes, effort noté le plus haut
  /// [flames] pour une cible [targetFlames].
  const RunBout(this.day, this.seconds, this.flames, this.targetFlames);

  /// Jour civil.
  final int day;

  /// Durée, en secondes.
  final double seconds;

  /// Effort noté le plus haut, ou `null`.
  final int? flames;

  /// Effort visé sur cette ligne, ou `null`.
  final int? targetFlames;
}

/// Ce que le journal dit de l'endurance de l'athlète.
final class EnduranceHistory {
  EnduranceHistory._(
    this.runs,
    this.speed,
    this.conditioningDays,
    this.hardRunDays,
    this.lastActivityDay,
  );

  /// Historique vide.
  static final EnduranceHistory empty = EnduranceHistory._(
    const <RunBout>[],
    0,
    const <int>{},
    const <int>{},
    null,
  );

  /// Lit les séances [digests] (dans l'ordre).
  factory EnduranceHistory.of(
    List<SessionDigest> digests,
    ExerciseBook book,
    AdaptParams p,
  ) {
    // Vitesse de course : celle des lignes qui disent à la fois distance
    // et durée ; sinon la vitesse par défaut.
    var meters = 0.0;
    var timed = 0.0;
    for (final d in digests) {
      for (final s in d.session.sets) {
        final info = book.find(s.exerciseId);
        if (info == null || enduranceKindOf(info) != EnduranceKind.run) {
          continue;
        }
        final m = s.distanceMeters;
        final t = s.seconds;
        if (m != null && t != null && m > 0 && t > 0) {
          meters += m;
          timed += t;
        }
      }
    }
    final speed = timed > 0 ? meters / timed : p.enduranceRunSpeed;
    final runs = <RunBout>[];
    final conditioning = <int>{};
    final hard = <int>{};
    int? last;
    for (final d in digests) {
      var seconds = 0.0;
      int? worst;
      int? target;
      var any = false;
      for (final s in d.session.sets) {
        if (s.kind == SetKind.warmup) {
          continue;
        }
        any = true;
        final info = book.find(s.exerciseId);
        final kind = info == null ? null : enduranceKindOf(info);
        final f = s.flames;
        if (kind == EnduranceKind.conditioning &&
            f != null &&
            f >= p.enduranceHardFlames) {
          conditioning.add(d.day);
        }
        if (kind != EnduranceKind.run) {
          continue;
        }
        final m = s.distanceMeters;
        seconds += s.seconds?.toDouble() ?? (m == null ? 0.0 : m / speed);
        if (f != null && (worst == null || f > worst)) {
          worst = f;
          target = s.target?.flames;
        }
        if (f != null && f >= p.enduranceHardFlames) {
          hard.add(d.day);
        }
      }
      if (any) {
        last = d.day;
      }
      if (seconds > 0) {
        runs.add(RunBout(d.day, seconds, worst, target));
      }
    }
    return EnduranceHistory._(runs, speed, conditioning, hard, last);
  }

  /// Courses faites, une par séance, dans l'ordre.
  final List<RunBout> runs;

  /// Vitesse de course retenue, en m/s.
  final double speed;

  /// Jours de conditionnement dur.
  final Set<int> conditioningDays;

  /// Jours de course dure (effort noté au moins
  /// [AdaptParams.enduranceHardFlames]).
  final Set<int> hardRunDays;

  /// Dernier jour d'entraînement, ou `null`.
  final int? lastActivityDay;

  /// Plus longue course (en secondes, sur une séance) des [window] jours
  /// avant [day], et nombre de courses dans cette fenêtre.
  (double, int) longestBefore(int day, int window) {
    var longest = 0.0;
    var count = 0;
    for (final r in runs) {
      if (r.day < day && r.day >= day - window) {
        count++;
        if (r.seconds > longest) {
          longest = r.seconds;
        }
      }
    }
    return (longest, count);
  }

  /// Vrai si une course des [window] jours avant [day] a été notée au
  /// moins [margin] flammes plus dure que visé, ou dure sans cible.
  bool recentRunTooHard(int day, int window, int margin, int hardFlames) {
    for (final r in runs) {
      if (r.day >= day || r.day < day - window) {
        continue;
      }
      final f = r.flames;
      final t = r.targetFlames;
      if (f == null) {
        continue;
      }
      if (t != null ? f - t >= margin : f >= hardFlames + 1) {
        return true;
      }
    }
    return false;
  }

  /// Nombre de jours durs de conditionnement de suite juste avant [day]
  /// (un jour sans séance entre deux ne rompt pas la suite ; deux, si).
  int conditioningStreak(int day) {
    var n = 0;
    var d = day - 1;
    var gap = 0;
    while (d >= day - 7) {
      if (conditioningDays.contains(d)) {
        n++;
        gap = 0;
      } else if (lastActivityDay != null && d > lastActivityDay!) {
        // Jour après la dernière séance : rien de fait.
        gap++;
      } else {
        break;
      }
      if (gap > 1) {
        break;
      }
      d--;
    }
    return n;
  }
}

/// Durée prescrite d'une ligne d'endurance, en secondes (toutes séries),
/// pour une vitesse de course [speed] (m/s) ; `0` si la ligne ne dit ni
/// durée ni distance.
double prescribedSeconds(ExercisePrescription item, int sets, double speed) {
  final s = item.secondsHigh ?? item.secondsLow;
  if (s != null) {
    return (s * sets).toDouble();
  }
  final m = item.distanceMeters;
  if (m != null && speed > 0) {
    return m * sets / speed;
  }
  return 0;
}

/// Vrai si [item] (course [info]) est une séance de qualité : effort visé à
/// [AdaptParams.enduranceQualityRir] répétitions en réserve ou plus près,
/// allure visée, test, ou exercice de fractionné.
bool isQualityRun(ExercisePrescription item, ExerciseInfo info, AdaptParams p) {
  final f = item.targetFlames;
  if (f != null && rirOfFlames(f) <= p.enduranceQualityRir + 1e-9) {
    return true;
  }
  if (item.intensity != null || item.kind == SetKind.test) {
    return true;
  }
  final id = info.exercise.id;
  return qualityRunIds.any(id.contains);
}

/// Ligne [item] ramenée à la part [factor] (de 0 à 1) : nombre de séries
/// d'un fractionné, durée ou distance de chaque série d'une course
/// continue, répétitions d'une pièce de conditionnement. Jamais au-dessus
/// de l'écrit ; arrondi vers le bas (minute, 100 m, répétition).
(ExercisePrescription, int) scaled(
  ExercisePrescription item,
  int sets,
  double factor,
) {
  if (factor >= 1) {
    return (item, sets);
  }
  if (sets > 1 && item.repsHigh == null && item.repsLow == null) {
    var n = (sets * factor).floor();
    if (n < 1) {
      n = 1;
    }
    return (item, n);
  }
  final hi = item.secondsHigh;
  final lo = item.secondsLow;
  final m = item.distanceMeters;
  final rh = item.repsHigh;
  final rl = item.repsLow;
  int? down(int? v, int unit, int floor) {
    if (v == null) {
      return null;
    }
    var x = ((v * factor) / unit).floor() * unit;
    if (x < floor) {
      x = floor < v ? floor : v;
    }
    return x;
  }

  final newHi = hi == null ? null : down(hi, hi >= 300 ? 60 : 5, 5);
  var newLo = lo == null ? null : down(lo, lo >= 300 ? 60 : 5, 5);
  if (newLo != null && newHi != null && newLo > newHi) {
    newLo = newHi;
  }
  final newRh = rh == null ? null : down(rh, 1, 1);
  var newRl = rl == null ? null : down(rl, 1, 1);
  if (newRl != null && newRh != null && newRl > newRh) {
    newRl = newRh;
  }
  double? newM;
  if (m != null) {
    final x = (m * factor / 100).floor() * 100.0;
    newM = x < 100 ? (m < 100 ? m : 100.0) : x;
  }
  return (
    item.copyWith(
      secondsHigh: hi == null ? unset : newHi,
      secondsLow: lo == null ? unset : newLo,
      distanceMeters: m == null ? unset : newM,
      repsHigh: rh == null ? unset : newRh,
      repsLow: rl == null ? unset : newRl,
    ),
    sets,
  );
}

/// Exercice de course facile qui remplace une séance de qualité de
/// l'exercice [original] (tapis pour un tapis, sinon footing).
String easyRunFor(ExerciseInfo original) {
  final e = original.exercise;
  if (e.equipment.contains('tapis de course')) {
    return 'ca-course-tapis-endurance';
  }
  return 'ca-footing-endurance-fondamentale';
}
