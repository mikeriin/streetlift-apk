/// Inspection d'un programme : note détaillée, contraintes dures
/// revérifiées, mesures de la semaine. Sert aux tests de propriétés, au
/// simulateur et à l'inspecteur du mode dev (D2.5).
library;

import 'dart:typed_data';

import 'package:kalis_core/kalis_core.dart';

import 'assemble.dart';
import 'context.dart';
import 'params.dart';
import 'pass2.dart';
import 'score.dart';
import 'sets.dart';
import 'state.dart';
import 'traits.dart';

/// Mesures d'une semaine de programme.
final class PlanMetrics {
  /// Mesures.
  const PlanMetrics({
    required this.dayMinutes,
    required this.dayBudget,
    required this.classShare,
    required this.classTarget,
    required this.dosageError,
    required this.groupSets,
    required this.bandLow,
    required this.bandHigh,
    required this.inBandShare,
    required this.pullSets,
    required this.pushSets,
    required this.hipSets,
    required this.kneeSets,
    required this.coveredPatterns,
    required this.coverablePatterns,
    required this.slots,
    required this.distinctExercises,
    required this.resistanceMinutes,
    required this.majorCredits,
    required this.score,
  });

  /// Durée estimée de chaque séance, échauffement compris, en minutes.
  final List<double> dayMinutes;

  /// Minutes disponibles chaque jour.
  final List<int> dayBudget;

  /// Part du temps par classe de discipline (code → part).
  final Map<String, double> classShare;

  /// Part visée par classe de discipline.
  final Map<String, double> classTarget;

  /// Erreur de dosage : demi-somme des écarts absolus, de 0 à 1.
  final double dosageError;

  /// Séries fractionnaires hebdomadaires par groupe musculaire.
  final Map<String, double> groupSets;

  /// Bas de la bande par groupe.
  final Map<String, double> bandLow;

  /// Haut de la bande par groupe.
  final Map<String, double> bandHigh;

  /// Part des groupes majeurs dans leur bande (pondérée), de 0 à 1.
  final double inBandShare;

  /// Séries de tirage.
  final double pullSets;

  /// Séries de poussée.
  final double pushSets;

  /// Séries de chaîne postérieure.
  final double hipSets;

  /// Séries à dominante genou.
  final double kneeSets;

  /// Schémas de base couverts (sur six).
  final int coveredPatterns;

  /// Schémas de base que le matériel et le niveau permettent.
  final int coverablePatterns;

  /// Nombre d'exercices de la semaine.
  final int slots;

  /// Nombre d'exercices distincts.
  final int distinctExercises;

  /// Minutes de renforcement (figures comprises).
  final double resistanceMinutes;

  /// Séries fractionnaires créditées aux groupes majeurs.
  final double majorCredits;

  /// Note.
  final PlanScore score;

  /// Nombre de séances qui dépassent leur temps.
  int get overBudgetDays {
    var n = 0;
    for (var d = 0; d < dayMinutes.length; d++) {
      if (dayMinutes[d] > dayBudget[d] + 1e-9) {
        n++;
      }
    }
    return n;
  }

  /// Part moyenne du temps disponible utilisée, de 0 à 1.
  double get timeUse {
    var sum = 0.0;
    for (var d = 0; d < dayMinutes.length; d++) {
      final u = dayMinutes[d] / dayBudget[d];
      sum += u > 1 ? 1 : u;
    }
    return dayMinutes.isEmpty ? 0 : sum / dayMinutes.length;
  }

  /// Objet JSON (rapports).
  Map<String, Object?> toJson() => <String, Object?>{
    'dayMinutes': <double>[for (final m in dayMinutes) _round(m)],
    'dayBudget': dayBudget,
    'overBudgetDays': overBudgetDays,
    'timeUse': _round(timeUse),
    'classShare': _rounded(classShare),
    'classTarget': _rounded(classTarget),
    'dosageError': _round(dosageError),
    'groupSets': _rounded(groupSets),
    'bandLow': _rounded(bandLow),
    'bandHigh': _rounded(bandHigh),
    'inBandShare': _round(inBandShare),
    'pullSets': pullSets,
    'pushSets': pushSets,
    'hipSets': hipSets,
    'kneeSets': kneeSets,
    'coveredPatterns': coveredPatterns,
    'coverablePatterns': coverablePatterns,
    'slots': slots,
    'distinctExercises': distinctExercises,
    'resistanceMinutes': _round(resistanceMinutes),
    'majorCredits': _round(majorCredits),
    'score': score.toJson(),
  };
}

double _round(double v) => (v * 1000).roundToDouble() / 1000;

Map<String, double> _rounded(Map<String, double> m) => <String, double>{
  for (final e in m.entries) e.key: _round(e.value),
};

int _bits(int v) {
  var n = 0;
  var x = v;
  while (x != 0) {
    n += x & 1;
    x >>= 1;
  }
  return n;
}

/// Inspecteur de programmes.
final class PlanInspector {
  /// Inspecteur du catalogue [catalog].
  PlanInspector(this.catalog, {this.params = PlanParams.standard});

  /// Catalogue.
  final Catalog catalog;

  /// Paramètres.
  final PlanParams params;

  /// Contexte de [request] pour le programme [plan] (ses exercices sont
  /// gardés dans le vivier même s'ils ne sont plus admissibles).
  PlanContext contextFor(PlanRequest request, Pass1Plan plan) {
    return PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: plan.startDate,
        seed: 0,
        locks: request.locks,
        adaptation: request.adaptation,
        forcedIds: <String>{
          for (final day in plan.days)
            for (final slot in day.slots) slot.exerciseId,
        },
        volumeScale: adaptationVolumeScale(request.adaptation),
        params: params,
      ),
    );
  }

  /// Ce que le moteur retient du profil de [request] : niveau par groupe
  /// de mouvements, niveau global, prudence, dosage visé, taille du vivier
  /// (inspecteur du mode dev).
  Map<String, Object?> explainProfile(PlanRequest request) {
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: request.startDate,
        seed: 0,
        locks: request.locks,
        adaptation: request.adaptation,
        volumeScale: adaptationVolumeScale(request.adaptation),
        params: params,
      ),
    );
    final byKind = <String, int>{};
    for (final e in ctx.pool) {
      byKind.update(e.kind.name, (n) => n + 1, ifAbsent: () => 1);
    }
    final rejected = <String, int>{};
    for (final code in ctx.rejections.values) {
      rejected.update(code, (n) => n + 1, ifAbsent: () => 1);
    }
    return <String, Object?>{
      'ability': <String, int>{
        for (final g in AbilityGroup.values) g.name: ctx.ability[g]!,
      },
      'globalLevel': ctx.globalLevel,
      'cautious': ctx.cautious,
      'targets': <String, double>{
        for (final c in DisciplineClass.values)
          if (ctx.targets[c.index] > 0) c.name: _round(ctx.targets[c.index]),
      },
      'pool': ctx.pool.length,
      'poolByKind': byKind,
      'rejected': rejected,
      'goals': <String>[for (final g in ctx.goals) g.exercise.id],
    };
  }

  /// Pourquoi l'exercice [exerciseId] n'est pas admissible pour [request]
  /// (code de `Rejections`), ou `null` s'il l'est.
  String? rejectionOf(PlanRequest request, String exerciseId) {
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: request.startDate,
        seed: 0,
        locks: request.locks,
        adaptation: request.adaptation,
        volumeScale: adaptationVolumeScale(request.adaptation),
        params: params,
      ),
    );
    return ctx.rejections[exerciseId];
  }

  /// Note de [plan] pour [request].
  PlanScore scoreOf(PlanRequest request, Pass1Plan plan) {
    final ctx = contextFor(request, plan);
    final scorer = Scorer(ctx);
    scorer.evaluate(stateFromPlan(ctx, plan));
    return planScoreOf(scorer);
  }

  /// Nombre d'emplacements de [plan] qui diffèrent de [reference]
  /// (remplacés, ajoutés, retirés).
  static int changesBetween(Pass1Plan reference, Pass1Plan plan) {
    final before = <String, String>{
      for (final day in reference.days)
        for (final s in day.slots) s.slotId: s.exerciseId,
    };
    var changed = 0;
    var present = 0;
    for (final day in plan.days) {
      for (final s in day.slots) {
        final old = before[s.slotId];
        if (old == null) {
          changed++;
        } else {
          present++;
          if (old != s.exerciseId) {
            changed++;
          }
        }
      }
    }
    return changed + before.length - present;
  }

  /// Objectif de la recherche pour [plan] : sécurité + note globale (de 0
  /// à 2), moins la pénalité de changement par rapport à [reference].
  double objective(
    PlanRequest request,
    Pass1Plan plan, {
    Pass1Plan? reference,
  }) {
    final ctx = contextFor(request, plan);
    final scorer = Scorer(ctx);
    var value = scorer.evaluate(stateFromPlan(ctx, plan));
    if (reference != null) {
      value -= params.changePenalty * changesBetween(reference, plan);
    }
    return value;
  }

  /// Contraintes dures violées par [plan] (liste vide = programme
  /// admissible). Ce que l'utilisateur a imposé (emplacement verrouillé)
  /// n'est pas contrôlé, et un jour qui porte un emplacement verrouillé
  /// peut dépasser son temps.
  List<String> hardViolations(PlanRequest request, Pass1Plan plan) =>
      _violations(
        contextFor(request, plan),
        request.profile,
        locks,
        plan,
        null,
      );

  /// Contraintes dures violées par la semaine type [plan] rendue par une
  /// restructuration de [request], relues dans le contexte de cette
  /// restructuration (douleurs signalées, exercices écartés, temps du
  /// jour). Seuls les jours que la portée laisse modifier sont relus ; une
  /// restructuration d'une seule semaine ne change pas la semaine type.
  List<String> restructureViolations(
    RestructureRequest request,
    Pass1Plan plan,
  ) {
    if (request.scope == RestructureScope.week) {
      return const <String>[];
    }
    final ctx = PlanContext.build(
      restructureInputs(
        catalog,
        request,
        params,
        alsoForced: <String>{
          for (final day in plan.days)
            for (final slot in day.slots) slot.exerciseId,
        },
      ),
    );
    final frozen = <int>{
      for (final l in locks)
        if (l.kind == LockKind.keepDay && l.dayIndex != null) l.dayIndex!,
    };
    final days = <int>{
      for (var d = 0; d < plan.days.length; d++)
        if (!frozen.contains(d) &&
            (request.scope != RestructureScope.session ||
                d == request.dayIndex))
          d,
    };
    return _violations(ctx, request.profile, locks, plan, days);
  }

  List<String> _violations(
    PlanContext ctx,
    AthleteProfile profile,
    List<PlanLock> locks,
    Pass1Plan plan,
    Set<int>? onlyDays,
  ) {
    final out = <String>[];
    final scorer = Scorer(ctx);
    final state = stateFromPlan(ctx, plan);
    if (plan.days.length != ctx.dayCount) {
      out.add('days: ${plan.days.length} jours pour ${ctx.dayCount}');
      return out;
    }
    final disliked = profile.dislikedExerciseIds.toSet();
    final present = <String>{};
    for (final day in plan.days) {
      final d = day.dayIndex;
      if (onlyDays != null && !onlyDays.contains(d)) {
        for (final slot in day.slots) {
          present.add(slot.exerciseId);
        }
        continue;
      }
      final info = ctx.days[d];
      if (day.weekday != info.weekday) {
        out.add('day $d: jour ISO ${day.weekday} ≠ ${info.weekday}');
      }
      if (day.slots.isEmpty) {
        out.add('day $d: séance vide');
      }
      final seen = <String>{};
      var work = 0;
      var lockedWork = 0;
      var lockedSeconds = 0;
      var lockedWarm = false;
      for (final slot in day.slots) {
        final id = slot.exerciseId;
        present.add(id);
        if (!seen.add(id)) {
          out.add('day $d: $id en double');
        }
        final e = catalog.find(id);
        if (e == null) {
          out.add('day $d: $id inconnu');
          continue;
        }
        final entry = ctx.entryOf(id);
        if (entry == null) {
          out.add('day $d: $id hors du vivier');
          continue;
        }
        if (entry.kind != SlotKind.mobility) {
          work++;
        }
        // Seul un emplacement que la requête verrouille vraiment échappe aux
        // règles : un simple drapeau `locked` ne suffit pas.
        final imposed =
            slot.locked &&
            locks.any(
              (l) =>
                  l.kind == LockKind.keepDay ||
                  (l.kind != LockKind.excludeExercise &&
                      (l.slotId == slot.slotId || l.exerciseId == id)),
            );
        if (imposed) {
          lockedSeconds += entry.scheme.secondsFor(ctx.defaultSets(entry, d));
          if (entry.needsWarmup) {
            lockedWarm = true;
          }
          if (entry.kind != SlotKind.mobility) {
            lockedWork++;
          }
          continue;
        }
        if (!e.feasibleWith(info.equipment)) {
          out.add('day $d: $id sans le matériel du jour');
        }
        final place = info.place;
        final placeOk = place == null
            ? e.places.any(profile.places.contains)
            : e.places.contains(place);
        if (!placeOk) {
          out.add('day $d: $id hors du lieu du jour');
        }
        if (disliked.contains(id) || ctx.excludedIds.contains(id)) {
          out.add('day $d: $id écarté par le profil ou un verrou');
        }
        for (final l in profile.limitations) {
          final joint = l.joint ?? l.zone.joint;
          if (joint == null) {
            continue;
          }
          final stress = e.stressOn(joint);
          if ((stress == JointStress.high &&
                  l.discomfort >= params.hardJointDiscomfort) ||
              (stress != JointStress.low &&
                  l.discomfort >= params.severeJointDiscomfort)) {
            out.add(
              'day $d: $id contraint ${joint.code} (gêne ${l.discomfort})',
            );
          }
        }
        if (!entry.selectable || !entry.feasibleOn(d)) {
          out.add('day $d: $id inadmissible (niveau, prérequis, prudence)');
        }
      }
      // Ce que l'utilisateur a verrouillé peut à lui seul dépasser le
      // temps ou le nombre d'exercices du jour : la règle ne vaut alors plus.
      final lockedTime = lockedSeconds + (lockedWarm ? info.warmupSeconds : 0);
      final seconds = scorer.timeOfDay(state, d);
      if (seconds > info.seconds && lockedTime <= info.seconds) {
        out.add('day $d: $seconds s pour ${info.seconds} s');
      }
      if (work > info.maxWorkSlots && lockedWork <= info.maxWorkSlots) {
        out.add('day $d: $work exercices pour ${info.maxWorkSlots}');
      }
      if (day.slots.length > state.capacity) {
        out.add('day $d: ${day.slots.length} emplacements');
      }
    }
    for (final lock in locks) {
      final id = lock.exerciseId;
      switch (lock.kind) {
        case LockKind.requireExercise:
          if (id != null && !present.contains(id)) {
            out.add('lock: $id exigé et absent');
          }
        case LockKind.excludeExercise:
          if (id != null && present.contains(id)) {
            out.add('lock: $id exclu et présent');
          }
        case LockKind.keepSlot:
          var kept = false;
          for (final day in plan.days) {
            for (final slot in day.slots) {
              if (slot.slotId == lock.slotId && slot.exerciseId == id) {
                kept = true;
              }
            }
          }
          final d = lock.slotId == null ? null : dayOfSlotId(lock.slotId!);
          final placeable =
              d != null &&
              d < ctx.dayCount &&
              id != null &&
              ctx.indexOf(id) >= 0;
          if (!kept && placeable) {
            out.add('lock: ${lock.slotId} non conservé');
          }
        case LockKind.keepDay:
          break;
      }
    }
    return out;
  }

  /// Pour chaque jour de [plan], les [top] ajouts qui changeraient le plus
  /// la note (en mieux d'abord), avec les composantes qui bougent : répond
  /// à « pourquoi pas un exercice de plus ? » (inspecteur du mode dev).
  List<String> whatIfAdd(PlanRequest request, Pass1Plan plan, {int top = 3}) {
    final ctx = PlanContext.build(
      ContextInputs(
        catalog: catalog,
        profile: request.profile,
        startDate: plan.startDate,
        seed: 0,
        locks: request.locks,
        adaptation: request.adaptation,
        volumeScale: adaptationVolumeScale(request.adaptation),
        params: params,
      ),
    );
    final scorer = Scorer(ctx);
    final state = stateFromPlan(ctx, plan);
    final base = scorer.evaluate(state);
    final before = List<double>.of(scorer.components);
    final out = <String>[];
    for (var d = 0; d < ctx.dayCount; d++) {
      final found = <(double, String)>[];
      var blockedByTime = 0;
      for (final e in ctx.pool) {
        if (!e.selectable ||
            !e.feasibleOn(d) ||
            state.dayHas(d, e.index) ||
            state.count[d] >= state.capacity) {
          continue;
        }
        final at = state.add(d, e.index, ctx.defaultSets(e, d), -1);
        if (normalizeDay(ctx, state, d)) {
          final value = scorer.evaluate(state);
          final moved = <String>[];
          for (var k = 0; k < before.length; k++) {
            final delta = scorer.components[k] - before[k];
            if (delta.abs() >= 0.002) {
              moved.add(
                '${ScoreWeights.codes[k]} '
                '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(3)}',
              );
            }
          }
          found.add((
            value - base,
            '${e.id} (${e.kind.name}) '
                '${(value - base).toStringAsFixed(4)} : ${moved.join(', ')}',
          ));
        } else {
          blockedByTime++;
        }
        state.removeAt(d, at);
        normalizeDay(ctx, state, d);
      }
      found.sort((a, b) {
        final by = b.$1.compareTo(a.$1);
        return by != 0 ? by : a.$2.compareTo(b.$2);
      });
      out.add(
        'jour $d : ${found.length} ajouts possibles, '
        '$blockedByTime hors temps',
      );
      for (final (_, line) in found.take(top)) {
        out.add('  $line');
      }
      // Échanges vers un schéma de base manquant.
      scorer.evaluate(state);
      final missing = ctx.coverableBits & ~scorer.coveredBits & basePatternBits;
      if (missing == 0) {
        continue;
      }
      final swaps = <(double, String)>[];
      final saved = Int32List.fromList(state.exercise[d]);
      final savedSets = Int32List.fromList(state.sets[d]);
      for (final e in ctx.pool) {
        if (!e.selectable ||
            !e.feasibleOn(d) ||
            e.coverBits & missing == 0 ||
            state.dayHas(d, e.index)) {
          continue;
        }
        for (var at = 0; at < state.count[d]; at++) {
          state.exercise[d][at] = e.index;
          state.sets[d][at] = ctx.defaultSets(e, d);
          if (normalizeDay(ctx, state, d)) {
            final value = scorer.evaluate(state);
            final moved = <String>[];
            for (var k = 0; k < before.length; k++) {
              final delta = scorer.components[k] - before[k];
              if (delta.abs() >= 0.002) {
                moved.add(
                  '${ScoreWeights.codes[k]} '
                  '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(3)}',
                );
              }
            }
            swaps.add((
              value - base,
              '${ctx.pool[saved[at]].id} → ${e.id} '
                  '${(value - base).toStringAsFixed(4)} : ${moved.join(', ')}',
            ));
          }
          state.exercise[d].setAll(0, saved);
          state.sets[d].setAll(0, savedSets);
        }
      }
      swaps.sort((a, b) {
        final by = b.$1.compareTo(a.$1);
        return by != 0 ? by : a.$2.compareTo(b.$2);
      });
      for (final (_, line) in swaps.take(top)) {
        out.add('  échange $line');
      }
    }
    return out;
  }

  /// Mesures de la semaine de référence de [plan] ; [tuned] règle d'abord
  /// les séries comme la passe 2.
  PlanMetrics metrics(
    PlanRequest request,
    Pass1Plan plan, {
    bool tuned = true,
  }) {
    final ctx = contextFor(request, plan);
    final scorer = Scorer(ctx);
    final state = stateFromPlan(ctx, plan);
    if (tuned) {
      tuneSets(ctx, scorer, state);
    }
    return metricsOfState(ctx, scorer, state);
  }
}

/// Mesures de [state].
PlanMetrics metricsOfState(PlanContext ctx, Scorer scorer, PlanState state) {
  scorer.evaluate(state);
  final slotSeconds = scorer.slotSeconds;
  final share = <String, double>{};
  final target = <String, double>{};
  var error = 0.0;
  for (final c in DisciplineClass.values) {
    final s = slotSeconds == 0 ? 0.0 : scorer.classSeconds(c) / slotSeconds;
    final t = ctx.targets[c.index];
    if (s > 0 || t > 0) {
      share[c.name] = s;
      target[c.name] = t;
    }
    error += (s - t).abs();
  }
  final sets = <String, double>{};
  final low = <String, double>{};
  final high = <String, double>{};
  var inBand = 0.0;
  var weights = 0.0;
  var majorCredits = 0.0;
  for (final g in MuscleGroup.values) {
    final v = scorer.weeklySets(g);
    sets[g.code] = v;
    low[g.code] = ctx.bandLow[g.index] / 2;
    high[g.code] = ctx.bandHigh[g.index] / 2;
    if (g.major) {
      majorCredits += v;
      weights += g.weight;
      if (v * 2 >= ctx.bandLow[g.index] && v * 2 <= ctx.bandHigh[g.index]) {
        inBand += g.weight;
      }
    }
  }
  var push = 0;
  var pull = 0;
  var knee = 0;
  var hip = 0;
  var resistanceSeconds = 0;
  var slots = 0;
  final distinct = <int>{};
  for (var d = 0; d < state.dayCount; d++) {
    for (var i = 0; i < state.count[d]; i++) {
      final e = ctx.pool[state.exercise[d][i]];
      final n = state.sets[d][i];
      slots++;
      distinct.add(e.index);
      push += n * e.pushUnits;
      pull += n * e.pullUnits;
      knee += n * e.kneeUnits;
      hip += n * e.hipUnits;
      if (e.kind.isResistance) {
        resistanceSeconds += e.scheme.secondsFor(n);
      }
    }
  }
  return PlanMetrics(
    dayMinutes: <double>[
      for (var d = 0; d < state.dayCount; d++) scorer.daySeconds(d) / 60,
    ],
    dayBudget: <int>[for (final d in ctx.days) d.minutes],
    classShare: share,
    classTarget: target,
    dosageError: error / 2,
    groupSets: sets,
    bandLow: low,
    bandHigh: high,
    inBandShare: weights == 0 ? 1 : inBand / weights,
    pullSets: pull / 2,
    pushSets: push / 2,
    hipSets: hip / 2,
    kneeSets: knee / 2,
    coveredPatterns: _bits(
      scorer.coveredBits & ctx.coverableBits & basePatternBits,
    ),
    coverablePatterns: _bits(ctx.coverableBits & basePatternBits),
    slots: slots,
    distinctExercises: distinct.length,
    resistanceMinutes: resistanceSeconds / 60,
    majorCredits: majorCredits,
    score: planScoreOf(scorer),
  );
}
