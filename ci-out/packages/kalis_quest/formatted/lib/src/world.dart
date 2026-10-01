/// Lecture du journal par `kalis_quest` : faits par séance (réalisation,
/// justesse, combo, douleur, travail de mobilité…), calendrier (jours
/// prévus, pauses), chronologie des records et séries de performances.
///
/// Tout est une fonction pure du catalogue, du profil, du bloc, du journal
/// et d'« aujourd'hui ».
library;

import 'package:kalis_adapt/kalis_adapt.dart'
    show AdaptParams, CapacityMode, ExerciseBook, ExerciseInfo, bodyWeightOf;
import 'package:kalis_core/kalis_core.dart';

import 'numeric.dart';
import 'params.dart';
import 'standards.dart';

/// Meilleure performance d'une séance sur un exercice, pour une nature de
/// record.
final class Observation {
  /// Observation.
  const Observation(this.day, this.value, this.bodyWeightKg, this.sessionId);

  /// Numéro de jour de la séance.
  final int day;

  /// Valeur, dans l'unité de la nature de record.
  final double value;

  /// Poids de corps de la séance, en kg.
  final double bodyWeightKg;

  /// Séance.
  final String sessionId;
}

/// Record établi par une séance : la meilleure valeur de la séance dépasse
/// tout ce qui précède.
final class RecordEvent {
  /// Record.
  const RecordEvent({
    required this.exerciseId,
    required this.kind,
    required this.value,
    required this.previous,
    required this.ordinal,
  });

  /// Exercice.
  final String exerciseId;

  /// Nature.
  final RecordKind kind;

  /// Valeur atteinte.
  final double value;

  /// Meilleure valeur avant la séance (`null` : première fois).
  final double? previous;

  /// Rang, parmi les séries de travail de la séance, de la série qui
  /// l'établit.
  final int ordinal;

  /// Gain relatif sur le record précédent (0 pour une première fois).
  double get gain {
    final p = previous;
    if (p == null || p <= 0 || value <= 0) {
      return 0;
    }
    return kind == RecordKind.timeSeconds ? p / value - 1 : value / p - 1;
  }

  /// Clé stable du record (registre d'XP).
  String get key => 'rec|$exerciseId|${kind.code}|$value';
}

/// Faits d'une séance comptée.
final class SessionFacts {
  /// Faits de [session].
  SessionFacts(this.session, this.day);

  /// Séance.
  final SessionRecord session;

  /// Numéro de jour.
  final int day;

  /// Séries de travail faites (mesure non nulle, non écartées, hors
  /// échauffement).
  int workSets = 0;

  /// Séries de travail prévues (référence de la réalisation).
  int planned = 1;

  /// Séries qui comptent pour la qualité et les records (au plus le volume
  /// prévu).
  int limit = 0;

  /// Réalisation, de 0 à 1.
  double completion = 0;

  /// Qualité moyenne des séries comptées, de 0 à 1.
  double quality = 0;

  /// Séries dans la cible.
  int inTarget = 0;

  /// Plus longue suite de séries consécutives dans la cible.
  int combo = 0;

  /// Séries notées ayant une cible de flammes.
  int ratedWithTarget = 0;

  /// Parmi elles, séries à la tolérance près.
  int ratedOnTarget = 0;

  /// Toutes les séries de travail ont une note.
  bool fullyRated = false;

  /// Le bilan santé a une réponse à la question principale.
  bool healthAnswered = false;

  /// Zone de la douleur déclarée avant la séance qu'un exercice fait
  /// sollicite au-delà du seuil (`null` : aucune).
  BodyZone? painZone;

  /// Intensité de cette douleur.
  int painIntensity = 0;

  /// Séance d'entraînement proprement dite (autre chose que mobilité,
  /// récupération, marche).
  bool hard = false;

  /// Secondes de mobilité et de récupération.
  int mobilitySeconds = 0;

  /// Secondes de cardio.
  int cardioSeconds = 0;

  /// Séries explosives (pliométrie, haltérophilie, balistique, sprint).
  int explosiveSets = 0;

  /// Volume des exercices chargés : charge totale × répétitions, en kg.
  double volumeKg = 0;

  /// Séries de travail par exercice.
  final Map<String, int> setsByExercise = <String, int>{};

  /// Score de séance par exercice (fantôme) : charge totale × répétitions,
  /// répétitions, secondes ou mètres.
  final Map<String, double> scoreByExercise = <String, double>{};

  /// Score de la dernière séance précédente contenant l'exercice.
  final Map<String, double> lastScore = <String, double>{};

  /// Meilleur score des séances précédentes contenant l'exercice.
  final Map<String, double> bestScore = <String, double>{};

  /// Records établis par la séance.
  final List<RecordEvent> records = <RecordEvent>[];

  /// Exercices faits pour la première fois.
  final List<String> firsts = <String>[];

  /// Justesse des flammes : part des séries notées à la tolérance près, ou
  /// `null` sans série notée ayant une cible.
  double? get accuracy =>
      ratedWithTarget == 0 ? null : ratedOnTarget / ratedWithTarget;

  /// Séance du programme.
  bool get program => session.origin == SessionOrigin.program;
}

/// Pause déclarée, en numéros de jour.
final class BreakSpan {
  /// Pause du jour [start] au jour [end] inclus.
  const BreakSpan(this.start, this.end, this.reason);

  /// Premier jour.
  final int start;

  /// Dernier jour (très grand si la pause est en cours).
  final int end;

  /// Motif.
  final BreakReason reason;
}

/// Le monde vu par le moteur pour un appel.
final class World {
  /// Lit [input] ; seules les séances comptées (hors « reprise ») de date
  /// inférieure ou égale à « aujourd'hui » sont prises en compte.
  World(this.catalog, this.input, this.params)
    : book = ExerciseBook(catalog, input.profile),
      today = input.today.dayNumber {
    final block = input.block;
    scheduleWeekdays = <int>{
      if (block != null)
        for (final d in block.pass1.days) d.weekday
      else
        for (final d in input.profile.availability) d.weekday,
    };
    breaks = <BreakSpan>[
      for (final b in input.log.breaks ?? const <TrainingBreak>[])
        BreakSpan(
          b.startDate.dayNumber,
          b.endDate?.dayNumber ?? 1 << 40,
          b.reason,
        ),
    ];
    _scan();
  }

  /// Catalogue.
  final Catalog catalog;

  /// Entrée.
  final QuestInput input;

  /// Paramètres.
  final QuestParams params;

  /// Informations par exercice (`kalis_adapt`).
  final ExerciseBook book;

  /// Numéro de jour d'« aujourd'hui ».
  final int today;

  /// Jours ISO d'entraînement prévus (bloc en cours, sinon disponibilités).
  late final Set<int> scheduleWeekdays;

  /// Pauses déclarées.
  late final List<BreakSpan> breaks;

  /// Faits des séances comptées, par date croissante.
  final List<SessionFacts> facts = <SessionFacts>[];

  /// Faits par identifiant de séance.
  final Map<String, SessionFacts> factsById = <String, SessionFacts>{};

  /// Meilleures performances par séance, par `exercice|nature`.
  final Map<String, List<Observation>> series = <String, List<Observation>>{};

  /// Meilleure valeur connue par `exercice|nature`.
  final Map<String, Observation> bests = <String, Observation>{};

  static const AdaptParams _adapt = AdaptParams.standard;

  /// Paramètres de `kalis_adapt` partagés (courbe répétitions ↔ charge,
  /// seuils de douleur, poids de corps de référence).
  AdaptParams get adapt => _adapt;

  /// Poids de corps du profil, sinon la référence du modèle.
  double get profileBodyWeightKg =>
      input.profile.bodyWeightKg ?? _adapt.referenceBodyWeightKg;

  /// Motif de la pause qui couvre le jour [day], ou `null`.
  BreakReason? breakOn(int day) {
    for (final b in breaks) {
      if (day >= b.start && day <= b.end) {
        return b.reason;
      }
    }
    return null;
  }

  /// Vrai si le jour [day] est un jour d'entraînement prévu (hors pause).
  bool isTrainingDay(int day) =>
      scheduleWeekdays.contains(weekdayOf(day)) && breakOn(day) == null;

  /// Jours prévus au calendrier dans [from ; to], pauses comprises ou non.
  int scheduledIn(int from, int to, {required bool skipBreaks}) {
    var n = 0;
    for (var d = from; d <= to; d++) {
      if (scheduleWeekdays.contains(weekdayOf(d)) &&
          (!skipBreaks || breakOn(d) == null)) {
        n++;
      }
    }
    return n;
  }

  /// Faits des séances du jour [from] au jour [to] inclus.
  Iterable<SessionFacts> factsIn(int from, int to) sync* {
    var low = 0;
    var high = facts.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (facts[mid].day < from) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    for (var i = low; i < facts.length && facts[i].day <= to; i++) {
      yield facts[i];
    }
  }

  /// Semaine du bloc en cours qui contient le jour [day], ou `null`.
  int? blockWeekOf(int day) {
    final block = input.block;
    if (block == null) {
      return null;
    }
    final start = block.pass1.startDate.dayNumber;
    if (day < start) {
      return null;
    }
    final week = (day - start) ~/ 7;
    return week < block.pass1.weeks ? week : null;
  }

  /// Prescription du bloc en cours pour la semaine [weekIndex] et le jour
  /// d'entraînement [dayIndex], ou `null`.
  DayPrescription? prescriptionOf(int weekIndex, int dayIndex) {
    final block = input.block;
    if (block == null) {
      return null;
    }
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekIndex) {
        for (final d in w.days) {
          if (d.dayIndex == dayIndex) {
            return d;
          }
        }
      }
    }
    return null;
  }

  /// Prescription du bloc en cours prévue le jour civil [day], ou `null`.
  DayPrescription? prescriptionOn(int day) {
    final block = input.block;
    final week = blockWeekOf(day);
    if (block == null || week == null) {
      return null;
    }
    final weekday = weekdayOf(day);
    for (final d in block.pass1.days) {
      if (d.weekday == weekday) {
        return prescriptionOf(week, d.dayIndex);
      }
    }
    return null;
  }

  /// Nature de la semaine [weekIndex] du bloc en cours, ou `null`.
  WeekKind? weekKindOf(int weekIndex) {
    final block = input.block;
    if (block == null) {
      return null;
    }
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekIndex) {
        return w.kind;
      }
    }
    return null;
  }

  /// Séries de travail d'une prescription (hors échauffement).
  static int workSetsOf(DayPrescription day) {
    var n = 0;
    for (final item in day.items) {
      if ((item.kind ?? SetKind.work) != SetKind.warmup) {
        n += item.sets;
      }
    }
    return n;
  }

  int? _blockPlanned(ProgramRef? ref) {
    final block = input.block;
    if (ref == null || block == null || ref.blockId != block.pass1.blockId) {
      return null;
    }
    final day = prescriptionOf(ref.weekIndex, ref.dayIndex);
    return day == null ? null : workSetsOf(day);
  }

  static bool _measured(SetRecord s) =>
      (s.reps ?? 0) > 0 ||
      (s.seconds ?? 0) > 0 ||
      (s.distanceMeters ?? 0) > 0 ||
      (s.calories ?? 0) > 0;

  static bool _gentle(CatalogExercise e) =>
      e.family == MovementFamily.mobilite ||
      e.family == MovementFamily.recuperation ||
      e.pattern == MovementPattern.marche;

  /// Temps équivalent sur 5 km d'une course de [meters] mètres en
  /// [seconds] secondes (Riegel 1981).
  double riegel5k(double meters, double seconds) =>
      seconds * power(Standards.runMeters / meters, params.riegelExponent);

  void _scan() {
    final p = params;
    final seen = <String>{};
    final lastScores = <String, double>{};
    final bestScores = <String, double>{};
    final sessionBest = <String, (double, int)>{};
    for (final session in input.log.countedSessions) {
      final day = session.date.dayNumber;
      if (day > today) {
        continue;
      }
      final f = SessionFacts(session, day);
      final bw = bodyWeightOf(session, input.profile, _adapt);
      sessionBest.clear();
      final work = <SetRecord>[];
      for (final set in session.sets) {
        if (set.isUsable && set.kind != SetKind.warmup && _measured(set)) {
          work.add(set);
        }
      }
      f.workSets = work.length;
      final field = session.plannedWorkSets;
      final fromBlock = _blockPlanned(session.programRef);
      if (field != null && field > 0) {
        f.planned = field;
        f.limit = field;
      } else if (session.completed) {
        if (fromBlock != null && fromBlock > 0) {
          final light = (p.lightFloor * fromBlock).ceil();
          f.planned = light < 1 ? 1 : light;
          f.limit = fromBlock;
        } else {
          f.planned = work.isEmpty ? 1 : work.length;
          f.limit = work.length;
        }
      } else {
        final reference = fromBlock != null && fromBlock > 0
            ? fromBlock
            : p.defaultTypicalSets;
        f.planned = reference > work.length ? reference : work.length;
        f.limit = f.planned;
      }
      f.completion = f.workSets >= f.planned ? 1 : f.workSets / f.planned;
      f.healthAnswered = session.healthCheck?.overall != null;

      var qualitySum = 0.0;
      var qualityCount = 0;
      var run = 0;
      var rated = 0;
      for (var i = 0; i < work.length; i++) {
        final set = work[i];
        final info = book.find(set.exerciseId);
        final e = info?.exercise;
        final flames = set.flames;
        final targetFlames = set.target?.flames;
        if (flames != null) {
          rated++;
        }
        bool hit;
        double q;
        if (targetFlames == null) {
          hit = set.success;
          q = 1;
        } else if (flames == null) {
          hit = false;
          q = p.unratedQuality;
        } else {
          final delta = flames - targetFlames;
          f.ratedWithTarget++;
          final near = delta.abs() <= p.targetTolerance;
          if (near) {
            f.ratedOnTarget++;
          }
          hit = near && set.success;
          q = delta >= -p.targetTolerance
              ? 1
              : clampDouble(
                  1 + (delta + p.targetTolerance) * p.qualityStep,
                  p.qualityFloor,
                  1,
                );
        }
        if (i < f.limit) {
          qualitySum += q;
          qualityCount++;
        }
        // Les séries au-delà du volume prévu ne comptent ni pour la cible
        // ni pour le combo.
        if (i < f.limit) {
          if (hit) {
            f.inTarget++;
            run++;
            if (run > f.combo) {
              f.combo = run;
            }
          } else {
            run = 0;
          }
        }
        f.setsByExercise.update(
          set.exerciseId,
          (n) => n + 1,
          ifAbsent: () => 1,
        );
        if (seen.add(set.exerciseId)) {
          f.firsts.add(set.exerciseId);
        }
        if (e == null || !_gentle(e)) {
          f.hard = true;
        }
        final reps = set.reps ?? 0;
        final seconds = set.seconds ?? 0;
        var score = reps > 0
            ? reps.toDouble()
            : (seconds > 0
                  ? seconds.toDouble()
                  : (set.distanceMeters ?? set.calories ?? 0.0));
        if (e != null) {
          if (_gentle(e)) {
            f.mobilitySeconds += seconds > 0
                ? seconds
                : reps * p.mobilityRepSeconds;
          }
          if (e.family == MovementFamily.cardio &&
              e.pattern != MovementPattern.marche) {
            f.cardioSeconds += seconds;
          }
          if (e.family == MovementFamily.explosif ||
              e.pattern == MovementPattern.sprint) {
            f.explosiveSets++;
          }
        }
        if (info != null) {
          _observe(info, set, bw, i, sessionBest);
          if (info.mode == CapacityMode.loaded && reps > 0) {
            final total = info.totalLoad(set.externalLoadKg ?? 0, bw);
            if (total > 0) {
              f.volumeKg += total * reps;
              score = total * reps;
            }
          }
        }
        f.scoreByExercise.update(
          set.exerciseId,
          (v) => v + score,
          ifAbsent: () => score,
        );
      }
      for (final entry in f.scoreByExercise.entries) {
        final last = lastScores[entry.key];
        final best = bestScores[entry.key];
        if (last != null) {
          f.lastScore[entry.key] = last;
        }
        if (best != null) {
          f.bestScore[entry.key] = best;
        }
        lastScores[entry.key] = entry.value;
        if (best == null || entry.value > best) {
          bestScores[entry.key] = entry.value;
        }
      }
      f.quality = qualityCount == 0 ? 0 : qualitySum / qualityCount;
      f.fullyRated = work.isNotEmpty && rated == work.length;
      _painGuard(f, work);

      final keys = sessionBest.keys.toList()..sort();
      for (final key in keys) {
        final (value, ordinal) = sessionBest[key]!;
        final obs = Observation(day, value, bw, session.id);
        series.putIfAbsent(key, () => <Observation>[]).add(obs);
        final cut = key.indexOf('|');
        final kind = RecordKind.fromCode(key.substring(cut + 1));
        final old = bests[key];
        final better =
            old == null ||
            (kind == RecordKind.timeSeconds
                ? value < old.value - 1e-9
                : value > old.value + 1e-9);
        if (better) {
          bests[key] = obs;
          f.records.add(
            RecordEvent(
              exerciseId: key.substring(0, cut),
              kind: kind,
              value: value,
              previous: old?.value,
              ordinal: ordinal,
            ),
          );
        }
      }
      facts.add(f);
      factsById[session.id] = f;
    }
  }

  /// Même règle que `recordsOf` de `kalis_adapt` pour les tenues, les
  /// répétitions et le 1RM impliqué ; en plus, le temps équivalent sur
  /// 5 km et la plus longue distance des séries de course.
  void _observe(
    ExerciseInfo info,
    SetRecord set,
    double bw,
    int ordinal,
    Map<String, (double, int)> best,
  ) {
    void offer(RecordKind kind, double value, {bool lower = false}) {
      final key = '${info.id}|${kind.code}';
      final old = best[key];
      if (old == null || (lower ? value < old.$1 : value > old.$1)) {
        best[key] = (value, ordinal);
      }
    }

    final mode = info.mode;
    if (mode == null) {
      final meters = set.distanceMeters;
      final seconds = set.seconds;
      if (Standards.sourceOf(info.id)?.measure == RankMeasure.run &&
          meters != null &&
          seconds != null &&
          seconds > 0 &&
          meters >= params.runMinMeters &&
          meters <= params.runMaxMeters) {
        offer(
          RecordKind.timeSeconds,
          roundTo(riegel5k(meters, seconds.toDouble()), 1),
          lower: true,
        );
        offer(RecordKind.distanceMeters, meters);
      }
      return;
    }
    switch (mode) {
      case CapacityMode.hold:
        final seconds = set.seconds;
        if (seconds != null && seconds > 0) {
          offer(RecordKind.maxHoldSeconds, seconds.toDouble());
        }
      case CapacityMode.reps:
        final reps = set.reps;
        if (reps != null && reps > 0) {
          offer(RecordKind.maxReps, reps.toDouble());
        }
      case CapacityMode.loaded:
        final reps = set.reps;
        final flames = set.flames;
        if (reps == null ||
            reps < 1 ||
            reps > 10 ||
            flames == null ||
            flames < 8) {
          return;
        }
        final total = info.totalLoad(set.externalLoadKg ?? 0, bw);
        if (total <= 0) {
          return;
        }
        final n = reps + Flames.toRir(flames);
        final k = info.lowerBody ? _adapt.kLowerBody : _adapt.kGeneral;
        offer(RecordKind.oneRmKg, roundTo(total * (1 + (n - 1) / k), 1));
    }
  }

  /// Séance faite malgré une douleur : une douleur déclarée au bilan de
  /// début de séance écarte un exercice (règle et seuils de `kalis_adapt`)
  /// et cet exercice a pourtant été fait.
  void _painGuard(SessionFacts f, List<SetRecord> work) {
    final pains = f.session.healthCheck?.pains;
    if (pains == null || pains.isEmpty) {
      return;
    }
    for (final pain in pains) {
      if (pain.intensity < _adapt.painHard) {
        continue;
      }
      final done = <String>{};
      for (final set in work) {
        if (!done.add(set.exerciseId)) {
          continue;
        }
        final info = book.find(set.exerciseId);
        if (info != null &&
            info.excludedByPain(
              pain.zone,
              pain.intensity,
              hard: _adapt.painHard,
              severe: _adapt.painSevere,
            )) {
          if (pain.intensity > f.painIntensity) {
            f.painZone = pain.zone;
            f.painIntensity = pain.intensity;
          }
        }
      }
    }
  }

  /// Records personnels connus : la meilleure valeur par exercice et par
  /// nature (même liste que `recordsOf` de `kalis_adapt`, plus la course).
  List<PersonalRecord> personalRecords() {
    final keys = bests.keys.toList()..sort();
    final out = <PersonalRecord>[];
    for (final key in keys) {
      final cut = key.indexOf('|');
      final obs = bests[key]!;
      final list = series[key]!;
      double? previous;
      final kind = RecordKind.fromCode(key.substring(cut + 1));
      for (final o in list) {
        if (o.sessionId == obs.sessionId) {
          break;
        }
        if (previous == null ||
            (kind == RecordKind.timeSeconds
                ? o.value < previous
                : o.value > previous)) {
          previous = o.value;
        }
      }
      out.add(
        PersonalRecord(
          exerciseId: key.substring(0, cut),
          kind: kind,
          value: obs.value,
          date: CivilDate.fromDayNumber(obs.day),
          sessionId: obs.sessionId,
          previousValue: previous,
        ),
      );
    }
    return out;
  }
}
