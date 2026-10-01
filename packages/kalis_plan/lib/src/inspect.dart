/// Inspection d'un programme : note détaillée, contraintes dures
/// revérifiées, mesures de la semaine. Sert aux tests de propriétés, au
/// simulateur et à l'inspecteur du mode dev (D2.5).
library;

import 'package:kalis_core/kalis_core.dart';

import 'assemble.dart';
import 'context.dart';
import 'params.dart';
import 'pass2.dart';
import 'score.dart';
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

  /// Objectif de la recherche pour [plan] : palier de sécurité × 2 + note
  /// globale, moins la pénalité de changement par rapport à [reference].
  double objective(PlanRequest request, Pass1Plan plan, {Pass1Plan? reference}) {
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
  List<String> hardViolations(PlanRequest request, Pass1Plan plan) {
    final out = <String>[];
    final ctx = contextFor(request, plan);
    final profile = request.profile;
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
        if (slot.locked) {
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
            out.add('day $d: $id contraint ${joint.code} (gêne ${l.discomfort})');
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
    for (final lock in request.locks) {
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
              d != null && d < ctx.dayCount && id != null && ctx.indexOf(id) >= 0;
          if (!kept && placeable) {
            out.add('lock: ${lock.slotId} non conservé');
          }
        case LockKind.keepDay:
          break;
      }
    }
    return out;
  }

  /// Mesures de la semaine de référence de [plan] ; [tuned] règle d'abord
  /// les séries comme la passe 2.
  PlanMetrics metrics(PlanRequest request, Pass1Plan plan, {bool tuned = true}) {
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
