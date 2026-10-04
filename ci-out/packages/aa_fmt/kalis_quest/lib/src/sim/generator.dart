/// Journaux simulés de la simulation de rythme : un athlète à vérité
/// simple (capacité qui croît en ralentissant, forme du jour, erreur de
/// note) exécute le programme que `kalis_plan` crée pour son profil.
///
/// Ce modèle ne sert qu'à produire des journaux plausibles sur trois ans
/// pour mesurer le rythme de la progression ; il ne valide pas
/// `kalis_adapt` (voir sa propre simulation).
library;

import 'package:kalis_adapt/kalis_adapt.dart'
    show AdaptParams, CapacityMode, ExerciseBook, ExerciseInfo;
import 'package:kalis_adapt/simulation.dart' show SimProgram, simStartDate;
import 'package:kalis_core/kalis_core.dart';

import '../numeric.dart';
import 'archetypes.dart';

/// Suite pseudo-aléatoire mulberry32 propre à un événement : la même
/// graine et la même clé donnent les mêmes tirages, quel que soit l'ordre
/// des appels.
final class SimRng {
  /// Suite de l'événement [key] pour la graine [seed].
  SimRng(int seed, String key) : _state = fnv1a32('$seed|$key');

  int _state;

  /// Nombre uniforme de [0 ; 1[.
  double next() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xFFFFFFFF;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xFFFFFFFF)) & 0xFFFFFFFF;
    return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  /// Nombre de loi normale centrée réduite (méthode polaire).
  double gauss() {
    for (var i = 0; i < 64; i++) {
      final u = 2 * next() - 1;
      final v = 2 * next() - 1;
      final s = u * u + v * v;
      if (s > 1e-12 && s < 1) {
        return u * sqrt(-2 * ln(s) / s);
      }
    }
    return 0;
  }
}

/// Programme d'un archétype : les blocs de `kalis_plan` pour son profil,
/// communs à toutes les graines.
final class SimStage {
  /// Programme du profil [profile] sur [weeks] semaines.
  SimStage(this.catalog, PlanEngine plan, this.profile, int weeks)
    : book = ExerciseBook(catalog, profile) {
    final program = SimProgram(catalog, plan, profile);
    var covered = 0;
    for (var i = 0; covered < weeks; i++) {
      final block = program.block(i);
      blocks.add(block);
      covered += block.pass1.weeks;
    }
  }

  /// Catalogue.
  final Catalog catalog;

  /// Profil.
  final AthleteProfile profile;

  /// Informations par exercice.
  final ExerciseBook book;

  /// Blocs successifs.
  final List<ProgramBlock> blocks = <ProgramBlock>[];

  /// Premier jour de la simulation.
  int get startDay => simStartDate.dayNumber;

  /// Bloc en cours le jour [day], ou `null` après le dernier.
  ProgramBlock? blockOn(int day) {
    for (final b in blocks) {
      final start = b.pass1.startDate.dayNumber;
      if (day >= start && day < start + 7 * b.pass1.weeks) {
        return b;
      }
    }
    return null;
  }

  /// Exercice de mobilité utilisé pour les courtes séances des jours de
  /// repos.
  late final String mobilityExerciseId = () {
    for (final e in catalog.exercises) {
      if (e.family == MovementFamily.mobilite &&
          e.unit == MeasureUnit.seconds) {
        return e.id;
      }
    }
    return catalog.exercises.first.id;
  }();
}

/// Journal simulé.
final class SimLog {
  /// Séances, par date croissante.
  final List<SessionRecord> sessions = <SessionRecord>[];

  /// Pauses déclarées.
  final List<TrainingBreak> breaks = <TrainingBreak>[];

  /// Déclarations de quêtes de récupération.
  final List<QuestClaim> claims = <QuestClaim>[];

  /// Séances prévues au calendrier (hors pauses déclarées).
  int planned = 0;

  /// Séances faites malgré une douleur déclarée.
  int through = 0;

  /// Séances en plus du tricheur.
  int extra = 0;
}

final class _Truth {
  _Truth(this.mode, this.start);

  final CapacityMode mode;
  final double start;
}

/// Gain relatif total de capacité, à long terme, par niveau de la vérité
/// (ordres de grandeur de la prise de force selon l'entraînement passé :
/// position ACSM 2002 citée par Kraemer et coll. 2002).
const List<double> truthGain = <double>[0.60, 0.25, 0.12, 0.05];

/// Constante de temps de la croissance, en semaines entraînées.
const double truthTau = 78;

bool _in(List<YearlySpan> spans, int offset) {
  final dayOfYear = offset % 364;
  for (final s in spans) {
    final from = s.week * 7;
    if (dayOfYear >= from && dayOfYear < from + s.days) {
      return true;
    }
  }
  return false;
}

/// Simule [weeks] semaines de l'archétype [a] sur le programme [stage]
/// avec la graine [seed].
SimLog generateLog(Archetype a, SimStage stage, int seed, int weeks) {
  const adapt = AdaptParams.standard;
  final log = SimLog();
  final truths = <String, _Truth>{};
  final bw = stage.profile.bodyWeightKg ?? adapt.referenceBodyWeightKg;
  final start = stage.startDay;
  var trainedWeeks = 0.0;
  var trainedThisWeek = false;
  SessionRecord? previous;

  // Pauses déclarées (vacances, maladie), année après année.
  for (var offset = 0; offset < 7 * weeks; offset++) {
    for (final (spans, reason) in <(List<YearlySpan>, BreakReason)>[
      (a.vacations, BreakReason.vacation),
      (a.illnesses, BreakReason.illness),
    ]) {
      for (final s in spans) {
        if (offset % 364 == s.week * 7) {
          final last = offset + s.days - 1;
          log.breaks.add(
            TrainingBreak(
              startDate: CivilDate.fromDayNumber(start + offset),
              endDate: CivilDate.fromDayNumber(
                start + (last < 7 * weeks ? last : 7 * weeks - 1),
              ),
              reason: reason,
            ),
          );
        }
      }
    }
  }

  double capacity(_Truth t, double day) {
    final growth = 1 + truthGain[a.level] * (1 - exp(-trainedWeeks / truthTau));
    return t.start * growth * day;
  }

  for (var offset = 0; offset < 7 * weeks; offset++) {
    final day = start + offset;
    final date = CivilDate.fromDayNumber(day);
    if (offset % 7 == 0) {
      if (trainedThisWeek) {
        trainedWeeks += 1;
      }
      trainedThisWeek = false;
    }
    final block = stage.blockOn(day);
    if (block == null) {
      continue;
    }
    final pass1 = block.pass1;
    final weekIndex = (day - pass1.startDate.dayNumber) ~/ 7;
    PlanDay? planDay;
    for (final d in pass1.days) {
      if (d.weekday == date.weekday) {
        planDay = d;
      }
    }
    final declared = _in(a.vacations, offset) || _in(a.illnesses, offset);
    final stopped = _in(a.stops, offset);
    final rng = SimRng(seed, 'day|$offset');
    if (planDay == null || declared || stopped) {
      if (planDay != null && !declared) {
        log.planned++;
      }
      if (declared || stopped) {
        if (declared && rng.next() < a.claimRate) {
          log.claims.add(QuestClaim(questId: 'd:${date.iso}:0', date: date));
        }
        continue;
      }
      // Jour de repos.
      for (var slot = 0; slot < 2; slot++) {
        if (rng.next() < a.claimRate) {
          log.claims.add(
            QuestClaim(questId: 'd:${date.iso}:$slot', date: date),
          );
        }
      }
      final last = previous;
      if (a.cheat && last != null && rng.next() < 0.8) {
        log.extra++;
        log.sessions.add(
          last.copyWith(id: 'x$offset', date: date, healthCheck: null),
        );
      } else if (rng.next() < a.mobilityRate) {
        log.sessions.add(
          SessionRecord(
            id: 'm$offset',
            date: date,
            origin: SessionOrigin.program,
            resume: false,
            completed: true,
            durationMinutes: 8,
            sets: <SetRecord>[
              SetRecord(
                exerciseId: stage.mobilityExerciseId,
                exerciseOrder: 0,
                setIndex: 0,
                kind: SetKind.work,
                seconds: 300 + (rng.next() * 300).round(),
                success: true,
                excluded: false,
              ),
            ],
            pains: const <PainReport>[],
          ),
        );
      }
      continue;
    }
    log.planned++;
    if (rng.next() >= a.adherence) {
      continue;
    }
    DayPrescription? prescription;
    WeekKind? weekKind;
    for (final wk in block.pass2.weeks) {
      if (wk.weekIndex == weekIndex) {
        weekKind = wk.kind;
        for (final d in wk.days) {
          if (d.dayIndex == planDay.dayIndex) {
            prescription = d;
          }
        }
      }
    }
    if (prescription == null || weekKind == null) {
      continue;
    }
    trainedThisWeek = true;
    final dayForm = exp(0.03 * rng.gauss());
    final pain = rng.next() < a.painRate;
    final through = pain && rng.next() < a.throughRate;
    final mood = (rng.next() * 3).floor();
    final health = rng.next() < a.healthRate || pain
        ? HealthCheck(
            overall: pain ? 2 : 3 + (mood > 2 ? 2 : mood),
            pains: pain
                ? const <PainReport>[
                    PainReport(
                      zone: BodyZone.shoulder,
                      side: BodySide.both,
                      intensity: 5,
                      phase: PainPhase.before,
                    ),
                  ]
                : null,
          )
        : null;
    var items = prescription.items;
    if (pain && !through) {
      items = <ExercisePrescription>[
        for (final item in items)
          if (!(stage.book
                  .find(item.exerciseId)
                  ?.excludedByPain(
                    BodyZone.shoulder,
                    5,
                    hard: adapt.painHard,
                    severe: adapt.painSevere,
                  ) ??
              false))
            item,
      ];
    }
    var plannedSets = 0;
    for (final item in items) {
      if ((item.kind ?? SetKind.work) != SetKind.warmup) {
        plannedSets += item.sets;
      }
    }
    final full = rng.next() < a.fullRate;
    final keep = full ? items.length : (items.length * 0.6).ceil();
    final sets = <SetRecord>[];
    var hasExcluded = false;
    for (var order = 0; order < keep; order++) {
      final item = items[order];
      final info = stage.book.find(item.exerciseId);
      if (info != null &&
          pain &&
          info.excludedByPain(
            BodyZone.shoulder,
            5,
            hard: adapt.painHard,
            severe: adapt.painSevere,
          )) {
        hasExcluded = true;
      }
      for (var i = 0; i < item.sets; i++) {
        final set = _performSet(
          a,
          info,
          item,
          order,
          i,
          truths,
          capacity,
          dayForm,
          bw,
          rng,
        );
        if (set != null) {
          sets.add(set);
        }
      }
    }
    if (a.cheat) {
      // Le tricheur ajoute, après le programme, la moitié des séries en
      // plus (tirages à part : les séries prévues sont celles du jumeau
      // honnête).
      final more = SimRng(seed, 'triche|$offset');
      for (var order = 0; order < keep; order++) {
        final item = items[order];
        final info = stage.book.find(item.exerciseId);
        for (var i = 0; i < (item.sets + 1) ~/ 2; i++) {
          final set = _performSet(
            a,
            info,
            item,
            order,
            item.sets + i,
            truths,
            capacity,
            dayForm,
            bw,
            more,
          );
          if (set != null) {
            sets.add(set);
          }
        }
      }
    }
    if (sets.isEmpty) {
      continue;
    }
    if (through && hasExcluded) {
      log.through++;
    }
    final session = SessionRecord(
      id: 's$offset',
      date: date,
      origin: SessionOrigin.program,
      programRef: ProgramRef(
        blockId: pass1.blockId,
        weekIndex: weekIndex,
        dayIndex: planDay.dayIndex,
      ),
      resume: false,
      completed: true,
      durationMinutes: planDay.minutesBudget,
      healthCheck: health,
      sets: sets,
      pains: const <PainReport>[],
      plannedWorkSets: plannedSets,
    );
    log.sessions.add(session);
    previous = session;
  }
  return log;
}

SetRecord? _performSet(
  Archetype a,
  ExerciseInfo? info,
  ExercisePrescription item,
  int order,
  int index,
  Map<String, _Truth> truths,
  double Function(_Truth truth, double day) capacity,
  double dayForm,
  double bw,
  SimRng rng,
) {
  const adapt = AdaptParams.standard;
  final kind = item.kind ?? SetKind.work;
  final targetFlames = item.targetFlames;
  final rir = Flames.toRir(targetFlames ?? 7);
  final mode = info?.mode;
  final repsLow = item.repsLow ?? item.repsHigh;
  final repsHigh = item.repsHigh ?? item.repsLow;
  final secondsLow = item.secondsLow ?? item.secondsHigh;
  final secondsHigh = item.secondsHigh ?? item.secondsLow;
  int? flamesOf(double trueRir) {
    if (rng.next() < a.ratingSkip) {
      return null;
    }
    final noisy = trueRir + a.ratingNoise * rng.gauss();
    return Flames.fromRir(clampDouble(noisy, 0, 9));
  }

  if (info == null ||
      mode == null ||
      (mode == CapacityMode.hold && secondsHigh == null) ||
      (mode != CapacityMode.hold && repsHigh == null)) {
    // Exercice non modélisé : fait comme prescrit.
    if (repsHigh == null &&
        secondsHigh == null &&
        item.distanceMeters == null &&
        item.calories == null) {
      return null;
    }
    return SetRecord(
      exerciseId: item.exerciseId,
      exerciseOrder: order,
      setIndex: index,
      kind: kind,
      reps: repsHigh,
      seconds: repsHigh == null ? secondsHigh : null,
      distanceMeters: repsHigh == null && secondsHigh == null
          ? item.distanceMeters
          : null,
      calories:
          repsHigh == null && secondsHigh == null && item.distanceMeters == null
          ? item.calories
          : null,
      flames: targetFlames == null ? null : flamesOf(rir),
      success: true,
      excluded: false,
      slotId: item.slotId,
      target: SetTarget(
        repsLow: repsLow,
        repsHigh: repsHigh,
        secondsLow: repsHigh == null ? secondsLow : null,
        secondsHigh: repsHigh == null ? secondsHigh : null,
        flames: targetFlames,
      ),
    );
  }
  final k = info.lowerBody ? adapt.kLowerBody : adapt.kGeneral;
  var truth = truths[item.exerciseId];
  if (truth == null) {
    double first;
    switch (mode) {
      case CapacityMode.loaded:
        final startLoad = item.startLoadKg;
        final total = startLoad == null ? 0.0 : info.totalLoad(startLoad, bw);
        if (total > 0) {
          first = total * (1 + (repsHigh! + rir - 1) / k) * 1.05;
        } else {
          first = bw * (info.lowerBody ? 1.0 : 0.6) * (1 + 0.35 * a.level);
        }
        final floor = info.fraction * bw * 1.15;
        if (first < floor) {
          first = floor;
        }
      case CapacityMode.reps:
        first = repsHigh! + rir + 1;
      case CapacityMode.hold:
        first = secondsHigh! + 3 * rir + 3;
    }
    truth = _Truth(mode, first);
    truths[item.exerciseId] = truth;
  }
  final c = capacity(truth, dayForm);
  switch (mode) {
    case CapacityMode.loaded:
      final high = repsHigh!;
      final low = repsLow ?? high;
      final ideal = c / (1 + (high + rir - 1) / k);
      var external = ((ideal - info.fraction * bw) / 2.5).floorToDouble() * 2.5;
      if (external < 0) {
        external = 0;
      }
      final total = info.totalLoad(external, bw);
      if (total <= 0) {
        return null;
      }
      final possible = 1 + k * (c / total - 1);
      var reps = (possible - rir).round();
      if (reps > high) {
        reps = high;
      }
      if (reps < 1) {
        reps = possible >= 1 ? possible.floor() : 0;
      }
      if (reps < 1) {
        return null;
      }
      return SetRecord(
        exerciseId: item.exerciseId,
        exerciseOrder: order,
        setIndex: index,
        kind: kind,
        externalLoadKg: external,
        reps: reps,
        flames: flamesOf(possible - reps),
        success: reps >= low,
        excluded: false,
        slotId: item.slotId,
        target: SetTarget(
          repsLow: low,
          repsHigh: high,
          loadKg: external,
          flames: targetFlames,
        ),
      );
    case CapacityMode.reps:
      final high = repsHigh!;
      final low = repsLow ?? high;
      var reps = (c - rir).round();
      if (reps > high) {
        reps = high;
      }
      if (reps < 1) {
        reps = 1;
      }
      return SetRecord(
        exerciseId: item.exerciseId,
        exerciseOrder: order,
        setIndex: index,
        kind: kind,
        reps: reps,
        flames: flamesOf(c - reps < 0 ? 0 : c - reps),
        success: reps >= low,
        excluded: false,
        slotId: item.slotId,
        target: SetTarget(repsLow: low, repsHigh: high, flames: targetFlames),
      );
    case CapacityMode.hold:
      final high = secondsHigh!;
      final low = secondsLow ?? high;
      var seconds = (c - 3 * rir).round();
      if (seconds > high) {
        seconds = high;
      }
      if (seconds < 1) {
        seconds = 1;
      }
      return SetRecord(
        exerciseId: item.exerciseId,
        exerciseOrder: order,
        setIndex: index,
        kind: kind,
        seconds: seconds,
        flames: flamesOf((c - seconds) / 3 < 0 ? 0 : (c - seconds) / 3),
        success: seconds >= low,
        excluded: false,
        slotId: item.slotId,
        target: SetTarget(
          secondsLow: low,
          secondsHigh: high,
          flames: targetFlames,
        ),
      );
  }
}
