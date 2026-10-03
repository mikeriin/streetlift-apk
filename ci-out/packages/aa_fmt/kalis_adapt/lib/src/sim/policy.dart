/// Politiques de prescription comparées par le simulateur : `kalis_adapt`
/// et la double progression simple. (L'ancien moteur L7/L11 est branché
/// depuis `tool/l7/`.)
library;

import 'package:kalis_core/kalis_core.dart';

import '../book.dart';
import '../engine.dart';
import '../filter.dart';
import '../numeric.dart';
import 'truth.dart';

/// Ce qu'une politique sait de la séance du jour.
final class SessionContext {
  /// Contexte.
  SessionContext({
    required this.catalog,
    required this.profile,
    required this.book,
    required this.block,
    required this.weekIndex,
    required this.dayIndex,
    required this.weekKind,
    required this.date,
    required this.simDay,
    required this.health,
    required this.place,
    required this.log,
    required this.athlete,
  });

  /// Catalogue.
  final Catalog catalog;

  /// Profil.
  final AthleteProfile profile;

  /// Informations par exercice.
  final ExerciseBook book;

  /// Bloc en cours.
  final ProgramBlock block;

  /// Semaine dans le bloc.
  final int weekIndex;

  /// Jour d'entraînement.
  final int dayIndex;

  /// Nature de la semaine.
  final WeekKind weekKind;

  /// Jour civil.
  final CivilDate date;

  /// Jours depuis le début de la simulation.
  final int simDay;

  /// Bilan santé du jour, s'il a été rempli.
  final HealthCheck? health;

  /// Lieu du jour, s'il diffère du lieu prévu.
  final Place? place;

  /// Journal avant la séance.
  final TrainingLog log;

  /// Athlète (une politique n'y lit que le choix « au jugé » d'une
  /// première charge, jamais la vérité).
  final SimAthlete athlete;

  /// Le même contexte avec le journal [newLog] (après la séance).
  SessionContext withLog(TrainingLog newLog) => SessionContext(
    catalog: catalog,
    profile: profile,
    book: book,
    block: block,
    weekIndex: weekIndex,
    dayIndex: dayIndex,
    weekKind: weekKind,
    date: date,
    simDay: simDay,
    health: health,
    place: place,
    log: newLog,
    athlete: athlete,
  );

  /// Prescription du bloc pour la séance.
  DayPrescription get prescription {
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekIndex) {
        for (final d in w.days) {
          if (d.dayIndex == dayIndex) {
            return d;
          }
        }
      }
    }
    throw StateError('séance absente du bloc');
  }

  /// Rôle de l'emplacement [slotId] dans la semaine type.
  SlotRole? roleOf(String slotId) {
    for (final d in block.pass1.days) {
      for (final s in d.slots) {
        if (s.slotId == slotId) {
          return s.role;
        }
      }
    }
    return null;
  }
}

/// Estimation d'une politique pour un exercice.
final class SimEstimate {
  /// Estimation.
  const SimEstimate({
    required this.capacity,
    required this.relSd,
    required this.operational,
  });

  /// Capacité estimée : 1RM de charge totale, répétitions ou tenue max.
  final double capacity;

  /// Écart-type relatif annoncé.
  final double relSd;

  /// Charge totale estimée pour le nombre de répétitions demandé (ou la
  /// capacité elle-même hors exercices chargés).
  final double operational;
}

/// Politique de prescription.
abstract class SimPolicy {
  /// Nom affiché dans les rapports.
  String get name;

  /// Séance du jour.
  SessionPlan plan(SessionContext c);

  /// Cible de la série de rang [index] de [item], d'après les séries
  /// [done] de la séance ; `null` : l'exercice s'arrête là.
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  );

  /// La séance [record] est finie ([c].log ne la contient pas encore).
  void finish(SessionContext c, SessionRecord record);

  /// Estimation de l'exercice [exerciseId] ; [n] est le nombre de
  /// répétitions jusqu'à l'échec de la capacité opérationnelle demandée.
  SimEstimate? estimate(SessionContext c, String exerciseId, double n);
}

/// Cible de la série [index] telle que la prescription [item] la donne.
SetTarget targetOfItem(ExercisePrescription item, int index) {
  final targets = item.setTargets;
  if (targets != null && targets.isNotEmpty) {
    final t = targets[index < targets.length ? index : targets.length - 1];
    return SetTarget(
      repsLow: t.repsLow ?? item.repsLow,
      repsHigh: t.repsHigh ?? item.repsHigh,
      secondsLow: t.secondsLow ?? item.secondsLow,
      secondsHigh: t.secondsHigh ?? item.secondsHigh,
      loadKg: t.loadKg ?? item.startLoadKg,
      flames: t.flames ?? item.targetFlames,
    );
  }
  return SetTarget(
    repsLow: item.repsLow,
    repsHigh: item.repsHigh,
    secondsLow: item.secondsLow,
    secondsHigh: item.secondsHigh,
    loadKg: item.startLoadKg,
    flames: item.targetFlames,
  );
}

/// `kalis_adapt` par son interface publique : `prescribeSession` avant la
/// séance, `adviseNextSet` après chaque série.
final class KalisAdaptPolicy implements SimPolicy {
  /// Politique du moteur [engine].
  KalisAdaptPolicy(this.engine);

  /// Moteur.
  final KalisAdapt engine;

  SessionPlan? _session;

  /// Dernière séance prescrite.
  SessionPlan? get lastSession => _session;

  @override
  String get name => 'kalis_adapt';

  AdaptInput _input(SessionContext c) =>
      AdaptInput(profile: c.profile, block: c.block, log: c.log, today: c.date);

  @override
  SessionPlan plan(SessionContext c) {
    final session = engine.prescribeSession(
      c.catalog,
      SessionRequest(
        input: _input(c),
        weekIndex: c.weekIndex,
        dayIndex: c.dayIndex,
        healthCheck: c.health,
        place: c.place,
      ),
    );
    _session = session;
    return session;
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    final base = targetOfItem(item, index);
    if (index == 0) {
      return base;
    }
    final advice = engine.adviseNextSet(
      c.catalog,
      AdviceRequest(
        input: _input(c),
        session: _session!,
        done: done,
        slotId: item.slotId,
        healthCheck: c.health,
      ),
    );
    if (advice.action == IntraSessionAction.stopExercise) {
      return null;
    }
    final seconds = advice.nextSeconds;
    final low = advice.nextRepsLow;
    final high = advice.nextRepsHigh;
    if (seconds == null && low == null && high == null) {
      // Exercice sans suivi : la prescription vaut.
      return base;
    }
    return SetTarget(
      repsLow: low,
      repsHigh: high,
      secondsLow: seconds,
      secondsHigh: seconds,
      loadKg: advice.nextLoadKg,
      flames: base.flames,
    );
  }

  @override
  void finish(SessionContext c, SessionRecord record) {}

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) {
    final (_, _, replayed) = engine.prepare(c.catalog, _input(c));
    final track = replayed.state.tracks[exerciseId];
    if (track == null) {
      return null;
    }
    final f = track.filter;
    return SimEstimate(
      capacity: f.capacity,
      relSd: f.capacityRelSd,
      operational: f.mode == CapacityMode.loaded
          ? exp(f.logLoadFor(n))
          : f.capacity,
    );
  }
}

/// Double progression simple, « au ressenti » : même charge à toutes les
/// séries, répétitions jusqu'au RIR visé perçu sans dépasser le haut de la
/// plage ; toutes les séries en haut de plage → un incrément de plus à la
/// séance suivante ; première série sous le bas de la plage → un incrément
/// de moins (ACSM 2009 ; règle « 2 pour 2 » ramenée à une séance).
///
/// La première charge est celle du bloc (`kalis_plan` la tire du niveau
/// déclaré) ; sans elle, l'athlète la choisit au jugé. Les exercices sans
/// charge suivent la plage du bloc au ressenti.
final class DoubleProgressionPolicy implements SimPolicy {
  final Map<String, double> _load = <String, double>{};

  @override
  String get name => 'double_progression';

  @override
  SessionPlan plan(SessionContext c) {
    return SessionPlan(
      date: c.date,
      blockId: c.block.pass1.blockId,
      weekIndex: c.weekIndex,
      dayIndex: c.dayIndex,
      items: c.prescription.items,
      adjustments: const <SessionAdjustment>[],
      confidence: 0,
      reasons: const <Reason>[],
    );
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    final base = targetOfItem(item, index);
    final info = c.book.find(item.exerciseId);
    if (info == null || info.mode != CapacityMode.loaded) {
      return base;
    }
    var load = _load[item.exerciseId];
    if (load == null && index > 0) {
      // Charge choisie au jugé à la première série : elle est gardée.
      for (final s in done.reversed) {
        if (s.exerciseId == item.exerciseId && s.externalLoadKg != null) {
          load = s.externalLoadKg;
          break;
        }
      }
    }
    load ??= base.loadKg;
    final high = item.repsHigh ?? base.repsHigh ?? 10;
    return SetTarget(
      repsLow: 1,
      repsHigh: high,
      loadKg: load,
      flames: item.targetFlames ?? base.flames,
    );
  }

  @override
  void finish(SessionContext c, SessionRecord record) {
    final first = <String, int>{};
    final all = <String, bool>{};
    final loads = <String, double>{};
    final items = <String, ExercisePrescription>{
      for (final it in c.prescription.items) it.exerciseId: it,
    };
    for (final s in record.sets) {
      final item = items[s.exerciseId];
      final reps = s.reps;
      final load = s.externalLoadKg;
      final high = item?.repsHigh;
      if (item == null || reps == null || load == null || high == null) {
        continue;
      }
      first.putIfAbsent(s.exerciseId, () => reps);
      loads.putIfAbsent(s.exerciseId, () => load);
      all[s.exerciseId] = (all[s.exerciseId] ?? true) && reps >= high;
    }
    for (final id in first.keys) {
      final info = c.book.find(id);
      final item = items[id]!;
      if (info == null) {
        continue;
      }
      final load = loads[id]!;
      final low = item.repsLow ?? 1;
      if (all[id] ?? false) {
        _load[id] = info.grid.next(load, up: true);
      } else if (first[id]! < low) {
        _load[id] = info.grid.next(load, up: false);
      } else {
        _load[id] = load;
      }
    }
  }

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) => null;
}

/// Oracle : une politique qui connaît la vérité de l'athlète (capacité du
/// jour, fatigue des séries faites) et choisit, sur la grille du matériel
/// et dans la plage du bloc, la charge et les répétitions qui laissent le
/// RIR visé. Aucun moteur ne peut faire mieux : son écart au RIR visé est
/// le plancher qu'imposent la grille, l'arrondi des répétitions et la
/// plage, sans aucune erreur d'estimation.
final class OraclePolicy implements SimPolicy {
  final Map<String, double> _load = <String, double>{};

  @override
  String get name => 'oracle';

  @override
  SessionPlan plan(SessionContext c) {
    _load.clear();
    return SessionPlan(
      date: c.date,
      blockId: c.block.pass1.blockId,
      weekIndex: c.weekIndex,
      dayIndex: c.dayIndex,
      items: c.prescription.items,
      adjustments: const <SessionAdjustment>[],
      confidence: 1,
      reasons: const <Reason>[],
    );
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    final base = targetOfItem(item, index);
    final truth = c.athlete.truthOf(item.exerciseId);
    final flames = base.flames;
    if (truth == null || flames == null) {
      return base;
    }
    final rir = Flames.toRir(flames);
    final hold = truth.mode == CapacityMode.hold;
    final low = (hold ? item.secondsLow : item.repsLow) ?? 1;
    final high = (hold ? item.secondsHigh : item.repsHigh) ?? low;
    int clip(double value, int top) {
      final rounded = value.round();
      return rounded < 1 ? 1 : (rounded > top ? top : rounded);
    }

    switch (truth.mode) {
      case CapacityMode.hold:
        final capacity = c.athlete.capacityNow(truth, null);
        final seconds = clip(
          capacity * (1 - truth.holdShare * (rir > 6 ? 6 : rir)),
          high + high ~/ 2,
        );
        return SetTarget(
          secondsLow: seconds,
          secondsHigh: seconds,
          flames: flames,
        );
      case CapacityMode.reps:
        final reps = clip(
          c.athlete.capacityNow(truth, null) - rir,
          SimAthlete.extendedTop(high),
        );
        return SetTarget(repsLow: reps, repsHigh: reps, flames: flames);
      case CapacityMode.loaded:
        final grid = truth.info.grid;
        var kg = _load[item.slotId];
        if (kg == null) {
          // Charge de la grille dont les répétitions au RIR visé tombent
          // le plus près du milieu de la plage.
          final mid = (low + high) / 2;
          var best = grid.minimum;
          var bestGap = double.infinity;
          var candidate = grid.minimum;
          for (var i = 0; i < 2000; i++) {
            final reps = c.athlete.capacityNow(truth, candidate) - rir;
            final gap = (reps - mid).abs();
            if (gap < bestGap) {
              best = candidate;
              bestGap = gap;
            }
            if (reps < low - 2) {
              break;
            }
            final next = grid.next(candidate, up: true);
            if (next <= candidate) {
              break;
            }
            candidate = next;
          }
          kg = best;
          _load[item.slotId] = kg;
        }
        final reps = clip(
          c.athlete.capacityNow(truth, kg) - rir,
          SimAthlete.extendedTop(high),
        );
        return SetTarget(
          repsLow: reps,
          repsHigh: reps,
          loadKg: kg,
          flames: flames,
        );
    }
  }

  @override
  void finish(SessionContext c, SessionRecord record) {}

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) => null;
}
