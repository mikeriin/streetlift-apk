/// Vérité d'endurance, de conditionnement et de mobilité d'un athlète
/// simulé (lot CA2, partie 1). Le moteur ne la connaît pas : il ne voit que
/// les lignes du journal (durées, distances, tours, effort noté).
///
/// Deux modèles indépendants par discipline (CA2, prompt § 1) :
/// - modèle A : capacité de durée facile qui monte avec la dose de la
///   semaine (gain saturant), effort noté d'après le rapport durée /
///   capacité ; blessure de surcharge déclenchée par une sortie plus longue
///   de 10 % que la plus longue des 30 jours (risque relatif de Frandsen et
///   al. 2025 : 1,64 de +10 à +30 %, 1,52 de +30 à +100 %, 2,28 au-delà) ;
/// - modèles B et C : gain logarithmique de la dose, tolérance des tissus
///   qui suit la charge avec retard (rapport des charges de 7 et 28 jours)
///   et risque qui monte quand la semaine dépasse de 30 % la moyenne des
///   deux précédentes (Nielsen et al. 2014) ; notes d'effort arrondies et
///   biaisées.
/// Conditionnement : capacité relative au WOD écrit ; deux jours durs de
/// suite abaissent la forme du troisième (Tibana et al. 2016) ; risque
/// d'épaule ou de dos qui monte en série de jours durs (choix raisonné,
/// Feito et al. 2018 : épaule 39 %, dos 36 % des blessures).
library;

import 'dart:math' as math;

import 'package:kalis_core/kalis_core.dart';

import '../endurance.dart';
import '../numeric.dart';
import 'rng.dart';
import 'truth.dart' show TruthKind;

/// Ce que l'athlète a fait d'une ligne d'endurance.
final class EnduranceDone {
  /// Quantités faites par série et effort noté.
  const EnduranceDone({
    required this.sets,
    required this.seconds,
    required this.distanceMeters,
    required this.reps,
    required this.flames,
    required this.success,
    this.calories,
  });

  /// Calories par série (ou `null`).
  final double? calories;

  /// Séries faites.
  final int sets;

  /// Secondes par série (ou `null`).
  final int? seconds;

  /// Distance par série (ou `null`).
  final double? distanceMeters;

  /// Répétitions par série (ou `null`).
  final int? reps;

  /// Effort noté (flammes, 1 à 10), ou `null` si non noté.
  final int? flames;

  /// Ligne faite en entier.
  final bool success;
}

/// Vérité d'endurance d'un athlète simulé.
final class EnduranceTruth {
  /// Athlète de niveau [level] (0 débutant … 3 élite), modèle [kind].
  EnduranceTruth(this.kind, this.level, this.seed) {
    final r = SimRandom.of(seed, 'endurance');
    const base = <double>[25, 50, 75, 100];
    easyMinutes = base[level.clamp(0, 3)] * math.exp(0.2 * r.gauss());
    startEasyMinutes = easyMinutes;
    wod = math.exp(0.15 * r.gauss());
    startWod = wod;
    speed = (2.4 + 0.35 * level.clamp(0, 3)) * math.exp(0.06 * r.gauss());
    startSpeed = speed;
  }

  /// Modèle de vérité.
  final TruthKind kind;

  /// Niveau.
  final int level;

  /// Graine.
  final int seed;

  /// Durée de course facile tenue confortablement, en minutes.
  late double easyMinutes;

  /// Valeur de départ de [easyMinutes].
  late double startEasyMinutes;

  /// Vitesse de course facile, en m/s.
  late double speed;

  /// Valeur de départ de [speed].
  late double startSpeed;

  /// Capacité de conditionnement relative au WOD écrit pour le niveau.
  late double wod;

  /// Valeur de départ de [wod].
  late double startWod;

  /// Secondes de course par jour.
  final Map<int, double> runSeconds = <int, double>{};

  /// Jours de conditionnement dur.
  final Set<int> hardWodDays = <int>{};

  /// Blessures de surcharge déclenchées (course, conditionnement).
  int overuse = 0;

  /// Plus forte hausse d'une sortie sur la plus longue des 30 jours
  /// précédents (rapport), sur toute la simulation.
  double worstSpike = 0;

  double _weekDose = 0;
  int _weekStart = 0;

  /// Plus longue course (secondes, par jour) des 30 jours avant [day], et
  /// nombre de jours de course.
  (double, int) _longest(int day) {
    var longest = 0.0;
    var count = 0;
    for (final e in runSeconds.entries) {
      if (e.key < day && e.key >= day - 30) {
        count++;
        if (e.value > longest) {
          longest = e.value;
        }
      }
    }
    return (longest, count);
  }

  double _weekRun(int from, int to) {
    var s = 0.0;
    for (final e in runSeconds.entries) {
      if (e.key >= from && e.key < to) {
        s += e.value;
      }
    }
    return s;
  }

  /// Fin de journée : adaptation de la semaine (appelée une fois par jour
  /// d'entraînement, après les lignes).
  void endDay(int day) {
    if (day - _weekStart >= 7) {
      // Gain de la semaine écoulée : la capacité suit la dose (minutes de
      // course faciles), saturante (A) ou logarithmique (B, C).
      final dose = _weekDose / 60;
      final ratio = dose / (easyMinutes * 3);
      final gain = switch (kind) {
        TruthKind.a => 0.035 * (1 - math.exp(-ratio)),
        _ => 0.02 * math.log(1 + ratio),
      };
      final ceiling = startEasyMinutes * (2.5 - 0.3 * level);
      if (easyMinutes < ceiling) {
        easyMinutes *= 1 + gain;
      }
      speed *= 1 + gain * 0.25;
      if (dose < 1e-9) {
        easyMinutes *= 0.97;
      }
      _weekDose = 0;
      _weekStart = day;
    }
  }

  /// Fait la ligne de course [item] ([sets] séries) le jour [day], forme
  /// du jour [readiness] (ln capacité, 0 normal), malade [ill] ; renvoie
  /// ce qui est fait et, s'il y a lieu, la zone d'une blessure de
  /// surcharge déclenchée.
  (EnduranceDone, BodyZone?) run(
    ExercisePrescription item,
    int sets,
    int day,
    double readiness, {
    required bool ill,
    required bool rates,
  }) {
    final r = SimRandom.of(seed, 'run|$day|${item.exerciseId}');
    final writtenS = prescribedSeconds(item, sets, speed);
    final f0 = item.targetFlames;
    final quality =
        (f0 != null && rirOfFlames(f0) <= 3 + 1e-9) ||
        item.intensity != null ||
        qualityRunIds.any(item.exerciseId.contains);
    // Charge relative : durée sur la capacité, l'intensité d'une séance de
    // qualité comptant double (choix raisonné).
    final cap = easyMinutes * 60 * math.exp(readiness * 3 + (ill ? -0.4 : 0));
    final load =
        writtenS * (quality ? 2.0 : 1.0) / (cap * (quality ? 1.6 : 1.0));
    var doneShare = 1.0;
    if (load > 1.35) {
      doneShare = 1.35 / load;
    }
    final targetRir = item.targetFlames == null
        ? 5.0
        : rirOfFlames(item.targetFlames!);
    var rir = targetRir - 4 * (load - 0.8) + 0.6 * r.gauss();
    if (kind != TruthKind.a) {
      rir -= 0.5; // notes biaisées vers plus dur (B, C)
    }
    if (rir < 0) {
      rir = 0;
    }
    var flames = flamesOfRir(rir);
    if (kind != TruthKind.a) {
      flames = flames.clamp(2, 9);
    }
    final doneS = writtenS * doneShare;
    final (longest, count) = _longest(day);
    BodyZone? injured;
    if (count >= 3 && longest > 0 && writtenS > 0) {
      final spike = doneS / longest;
      if (spike > worstSpike) {
        worstSpike = spike;
      }
      var risk = 0.003;
      if (spike > 2.0) {
        risk *= 2.28;
      } else if (spike > 1.3) {
        risk *= 1.52;
      } else if (spike > 1.1) {
        risk *= 1.64;
      }
      if (kind != TruthKind.a) {
        final week = _weekRun(day - 6, day) + doneS;
        final before = (_weekRun(day - 20, day - 6)) / 2;
        if (before > 0 && week > 1.3 * before) {
          risk *= 1.5;
        }
      }
      if (r.next() < risk) {
        injured = r.next() < 0.5 ? BodyZone.knee : BodyZone.ankleFoot;
        overuse++;
      }
    }
    runSeconds[day] = (runSeconds[day] ?? 0) + doneS;
    _weekDose += quality ? doneS * 1.5 : doneS;
    final perSet = sets <= 0 ? 0.0 : doneS / sets;
    final distance = item.distanceMeters;
    return (
      EnduranceDone(
        sets: sets,
        seconds: perSet.round(),
        distanceMeters: distance == null
            ? null
            : (distance * doneShare / 10).round() * 10.0,
        reps: null,
        flames: rates ? flames : null,
        success: doneShare >= 0.999,
      ),
      injured,
    );
  }

  /// Fait la pièce de conditionnement [item] ([sets] tours) le jour [day].
  (EnduranceDone, BodyZone?) wodPiece(
    ExercisePrescription item,
    int sets,
    int day,
    double readiness, {
    required bool ill,
    required bool rates,
    required int hardDaysBefore,
    double writtenShare = 1,
  }) {
    final r = SimRandom.of(seed, 'wod|$day|${item.exerciseId}');
    var form = wod * math.exp(readiness * 2 + (ill ? -0.3 : 0));
    if (hardDaysBefore >= 2) {
      form *= kind == TruthKind.a ? 0.95 : 0.9;
    }
    // Demande relative de la pièce : 1 pour l'écrit de son niveau, moins
    // quand la pièce a été mise à l'échelle (répétitions ou durée servies
    // sous l'écrit du bloc, [writtenShare]).
    final ratio = writtenShare / form;
    final targetRir = item.targetFlames == null
        ? 2.0
        : rirOfFlames(item.targetFlames!);
    var rir = targetRir - 4 * (ratio - 1) + 0.6 * r.gauss();
    if (rir < 0) {
      rir = 0;
    }
    final share = ratio > 1.25 ? 1.25 / ratio : 1.0;
    final flames = flamesOfRir(rir);
    if (flames >= 8) {
      hardWodDays.add(day);
    }
    BodyZone? injured;
    var risk = 0.002;
    if (hardDaysBefore >= 2) {
      risk *= 2;
    }
    if (ratio > 1.15) {
      risk *= 1.5;
    }
    if (r.next() < risk) {
      injured = r.next() < 0.52 ? BodyZone.shoulder : BodyZone.lowerBack;
      overuse++;
    }
    // Gain lent de la capacité de conditionnement.
    wod *= 1 + (kind == TruthKind.a ? 0.004 : 0.003);
    final reps = item.repsHigh ?? item.repsLow;
    final seconds = item.secondsHigh ?? item.secondsLow;
    final distance = item.distanceMeters;
    final cal = item.calories;
    return (
      EnduranceDone(
        sets: sets,
        reps: reps == null ? null : (reps * share).floor(),
        seconds: reps == null && seconds != null
            ? (seconds * share).round()
            : null,
        distanceMeters: reps == null && seconds == null ? distance : null,
        calories:
            reps == null && seconds == null && distance == null && cal != null
            ? (cal * share).floorToDouble()
            : null,
        flames: rates ? flames : null,
        success: share >= 0.999,
      ),
      injured,
    );
  }

  /// Jours durs de conditionnement de suite juste avant [day] (un jour de
  /// repos entre deux ne rompt pas la suite).
  int hardStreakBefore(int day) {
    var n = 0;
    var rest = 0;
    for (var d = day - 1; d >= day - 7; d--) {
      if (hardWodDays.contains(d)) {
        n++;
        rest = 0;
      } else if (++rest > 1) {
        break;
      }
    }
    return n;
  }

  /// Secondes de course faites par semaine (jour de simulation / 7).
  Map<int, double> secondsByWeek() {
    final out = <int, double>{};
    for (final e in runSeconds.entries) {
      final w = e.key ~/ 7;
      out[w] = (out[w] ?? 0) + e.value;
    }
    return out;
  }
}
