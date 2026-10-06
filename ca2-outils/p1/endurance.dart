/// Conduite des exercices d'endurance, de conditionnement et de mobilité
/// (lot CA2, partie 1) : le moteur ne les modélise pas en capacité (ni
/// 1RM, ni maximum de répétitions) ; il lit ce que l'athlète a fait (durées,
/// distances, effort noté) et sert la prescription du bloc, raccourcie ou
/// allégée quand le journal ou le bilan du jour le demandent — jamais plus
/// longue, plus rapide ni plus lourde que l'écrit.
///
/// Règles (sources au contrat, § 12) :
/// - pic de sortie : la course du jour ne dépasse pas de plus de 10 % la
///   plus longue des 30 derniers jours (Frandsen et al. 2025) ;
/// - jour sans (bilan bas, séance de course précédente bien plus dure que
///   prévu, gêne du bas du corps) : l'intensité baisse d'abord, une séance
///   de qualité devient une séance facile (Kiviniemi et al. 2007 ;
///   Vesterinen et al. 2016) ; bilan très bas : la durée baisse aussi ;
/// - reprise après une coupure : 70 % puis 50 % de l'écrit (avis d'expert,
///   règle du cou : reprise vers 50 %) ;
/// - conditionnement : mise à l'échelle (charges, puis répétitions) un
///   jour sans ou après deux jours durs de suite (Tibana et al. 2016) ;
/// - fatigue croisée : course dure la veille → une répétition de réserve
///   de plus sur le bas du corps (Robineau et al. 2016 : 24 h entre course
///   et force du bas du corps).
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

/// Une course faite (une ligne du journal).
final class RunBout {
  /// Course du jour [day], de [seconds] secondes, effort noté [flames]
  /// pour une cible [targetFlames].
  const RunBout(this.day, this.seconds, this.flames, this.targetFlames);

  /// Jour civil.
  final int day;

  /// Durée, en secondes.
  final double seconds;

  /// Effort noté.
  final int? flames;

  /// Effort visé.
  final int? targetFlames;
}

/// Ce que le journal dit de l'endurance de l'athlète.
final class EnduranceHistory {
  EnduranceHistory._(this.runs, this.speed, this.conditioningDays,
      this.hardRunDays, this.lastActivityDay);

  /// Lit les séances [digests] (dans l'ordre).
  factory EnduranceHistory.of(
    List<SessionDigest> digests,
    ExerciseBook book,
    AdaptParams p,
  ) {
    // Vitesse de course : celle des lignes qui disent à la fois distance
    // et durée ; sinon la vitesse de référence du moteur.
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
      var day = 0.0;
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
        if (kind == EnduranceKind.conditioning) {
          final f = s.flames;
          if (f != null && f >= p.enduranceHardFlames) {
            conditioning.add(d.day);
          }
        }
        if (kind != EnduranceKind.run) {
          continue;
        }
        final seconds =
            s.seconds?.toDouble() ??
            (s.distanceMeters == null ? 0.0 : s.distanceMeters! / speed);
        day += seconds;
        final f = s.flames;
        final t = s.target?.flames;
        if (f != null && (worst == null || f > worst)) {
          worst = f;
          target = t;
        }
        if (f != null && f >= p.enduranceHardFlames) {
          hard.add(d.day);
        }
      }
      if (any) {
        last = d.day;
      }
      if (day > 0) {
        runs.add(RunBout(d.day, day, worst, target));
      }
    }
    return EnduranceHistory._(runs, speed, conditioning, hard, last);
  }

  /// Courses faites, une par séance, dans l'ordre.
  final List<RunBout> runs;

  /// Vitesse de course retenue, en m/s.
  final double speed;

  /// Jours de conditionnement dur (effort noté au moins
  /// [AdaptParams.enduranceHardFlames]).
  final Set<int> conditioningDays;

  /// Jours de course dure (qualité ou sortie notée dure).
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

  /// Vrai si la dernière course, dans les [window] jours avant [day], a été
  /// notée au moins [margin] flammes plus dure que visé.
  bool lastRunTooHard(int day, int window, int margin) {
    for (var i = runs.length - 1; i >= 0; i--) {
      final r = runs[i];
      if (r.day >= day) {
        continue;
      }
      if (r.day < day - window) {
        return false;
      }
      final f = r.flames;
      final t = r.targetFlames;
      return f != null && t != null && f - t >= margin;
    }
    return false;
  }

  /// Nombre de jours durs de conditionnement consécutifs juste avant [day].
  int conditioningStreak(int day) {
    var n = 0;
    var d = day - 1;
    while (conditioningDays.contains(d)) {
      n++;
      d--;
    }
    return n;
  }
}

/// Durée prescrite d'une ligne d'endurance, en secondes, pour une vitesse
/// de course [speed] (m/s) ; `0` si la ligne ne dit ni durée ni distance.
double prescribedSeconds(ExercisePrescription item, int sets, double speed) {
  final s = item.secondsHigh;
  if (s != null) {
    return (s * sets).toDouble();
  }
  final m = item.distanceMeters;
  if (m != null && speed > 0) {
    return m * sets / speed;
  }
  return 0;
}

/// Vrai si [item] est une séance de qualité (effort visé à trois
/// répétitions en réserve ou plus près de l'échec).
bool isQuality(ExercisePrescription item, AdaptParams p) {
  final f = item.targetFlames;
  return f != null && rirOfFlames(f) <= p.enduranceQualityRir + 1e-9;
}

/// Ligne [item] raccourcie au facteur [factor] (de 0 à 1) : durée ou
/// distance de chaque série d'une course continue, nombre de séries d'un
/// fractionné.
ExercisePrescription shortened(
  ExercisePrescription item,
  int sets,
  double factor, {
  required int Function(int) setsOut,
}) {
  if (sets > 1) {
    var n = (sets * factor).floor();
    if (n < 1) {
      n = 1;
    }
    setsOut(n);
    return item;
  }
  setsOut(sets);
  final hi = item.secondsHigh;
  final lo = item.secondsLow;
  final m = item.distanceMeters;
  return item.copyWith(
    secondsHigh: hi == null ? unset : _atLeast(hi * factor, 60),
    secondsLow: lo == null
        ? unset
        : (_atLeast(lo * factor, 60) > _atLeast((hi ?? lo) * factor, 60)
              ? _atLeast((hi ?? lo) * factor, 60)
              : _atLeast(lo * factor, 60)),
    distanceMeters: m == null
        ? unset
        : ((m * factor / 100).floor() * 100.0 < 100
              ? 100.0
              : (m * factor / 100).floor() * 100.0),
  );
}

int _atLeast(double seconds, int floor) {
  // Arrondi à la minute vers le bas (durées de course écrites en minutes).
  final s = (seconds / 60).floor() * 60;
  return s < floor ? floor : s;
}
