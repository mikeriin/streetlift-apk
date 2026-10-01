/// Note d'un programme candidat (D4.2). Formulation et justification de
/// chaque composante : `CONTRAT.md`, § Formulation.
library;

import 'dart:typed_data';

import 'context.dart';
import 'params.dart';
import 'sets.dart';
import 'state.dart';
import 'traits.dart';

/// Bits des six schémas de base (hors tronc) dans `PoolEntry.coverBits`.
const int basePatternBits = 63;

/// Bit du tronc dans `PoolEntry.coverBits`.
const int coreBit = 64;

int _popCount(int v) {
  var n = 0;
  var x = v;
  while (x != 0) {
    n += x & 1;
    x >>= 1;
  }
  return n;
}

/// Calcule la note d'un [PlanState] pour un [PlanContext].
///
/// Une instance garde ses tableaux de travail : elle n'est pas réentrante,
/// mais deux appels sur le même état rendent exactement la même note (tous
/// les cumuls sont entiers ou recalculés de zéro).
final class Scorer {
  /// Notateur du contexte [context].
  Scorer(this.context)
    : _groups = MuscleGroup.values.length,
      _volume = Int32List(MuscleGroup.values.length),
      _heavy = Int32List(context.dayCount * MuscleGroup.values.length),
      _dayTime = Int32List(context.dayCount),
      _dayFatigue = Float64List(context.dayCount),
      _classTime = Int32List(DisciplineClass.values.length),
      _goalSum = Int32List(context.goals.length),
      _goalExact = Int32List(context.goals.length),
      _dayMobility = Int32List(64),
      _weekSeen = Int32List(context.pool.length),
      _rootDay = Int32List(context.rootCount),
      _patternStamp = Int32List(64),
      _patternCount = Int32List(64),
      _skillWeek = Int32List(context.rootCount),
      _skillDay = Int32List(context.rootCount),
      _skillDays = Int32List(context.rootCount),
      _skillTouched = Int32List(context.rootCount),
      components = Float64List(ScoreWeights.codes.length);

  /// Contexte.
  final PlanContext context;

  final int _groups;
  final Int32List _volume;
  final Int32List _heavy;
  final Int32List _dayTime;
  final Float64List _dayFatigue;
  final Int32List _classTime;
  final Int32List _goalSum;
  final Int32List _goalExact;
  final Int32List _dayMobility;
  final Int32List _weekSeen;
  final Int32List _rootDay;
  final Int32List _patternStamp;
  final Int32List _patternCount;
  final Int32List _skillWeek;
  final Int32List _skillDay;
  final Int32List _skillDays;
  final Int32List _skillTouched;
  int _stamp = 0;

  /// Valeur de chaque composante (ordre de `ScoreWeights.codes`), de 0 à 1,
  /// après le dernier [evaluate].
  final Float64List components;

  /// Note de sécurité du dernier [evaluate], de 0 à 1.
  double safety = 0;

  /// Note de qualité du dernier [evaluate], de 0 à 1.
  double quality = 0;

  /// Note globale du dernier [evaluate], de 0 à 1.
  double total = 0;

  /// Palier de sécurité du dernier [evaluate].
  int safetyBucket = 0;

  /// Schémas de base couverts au dernier [evaluate] (bits).
  int coveredBits = 0;

  /// Temps des exercices au dernier [evaluate], hors échauffement, en
  /// secondes.
  int slotSeconds = 0;

  /// Volume du groupe de rang [group] au dernier [evaluate], en
  /// demi-séries.
  int volumeHalfSets(int group) => _volume[group];

  /// Soutien cumulé de l'objectif de rang [goal] au dernier [evaluate].
  int goalSupportSum(int goal) => _goalSum[goal];

  /// Temps de la classe de rang [index] au dernier [evaluate].
  int classSecondsAt(int index) => _classTime[index];

  /// Volume hebdomadaire du groupe [group] au dernier [evaluate], en
  /// séries fractionnaires.
  double weeklySets(MuscleGroup group) => _volume[group.index] / 2;

  /// Durée estimée du jour [day] au dernier [evaluate], échauffement
  /// compris, en secondes.
  int daySeconds(int day) => _dayTime[day];

  /// Temps par classe de discipline au dernier [evaluate], en secondes.
  int classSeconds(DisciplineClass c) => _classTime[c.index];

  /// Durée estimée du jour [day] de [state], échauffement compris.
  int timeOfDay(PlanState state, int day) => dayTime(context, state, day);

  /// Vrai si une copie supplémentaire de [entry] dans la semaine n'est pas
  /// une redondance : pratique d'une figure, cardio, mobilité, travail d'un
  /// objectif, et polyarticulaire répété quand la semaine compte au plus
  /// trois séances (séances « corps entier » qui reprennent les mêmes bases).
  bool repeatAllowed(PoolEntry entry) {
    final kind = entry.kind;
    if (kind.isSkill ||
        kind.isCardio ||
        kind == SlotKind.mobility ||
        entry.goalLift ||
        (kind == SlotKind.compound && context.dayCount <= 3)) {
      return true;
    }
    for (final s in entry.goalSupport) {
      if (s >= 80) {
        return true;
      }
    }
    return false;
  }

  /// Note de [state]. Rend l'objectif de la recherche : la note globale plus
  /// `safetyPriority` fois la note de sécurité (la sécurité d'abord, sans
  /// marche d'escalier qui bloquerait la recherche).
  double evaluate(PlanState state) {
    final ctx = context;
    final params = ctx.params;
    final pool = ctx.pool;
    final days = ctx.days;
    final groups = _groups;
    final dayCount = ctx.dayCount;
    _volume.fillRange(0, groups, 0);
    _heavy.fillRange(0, dayCount * groups, 0);
    _classTime.fillRange(0, _classTime.length, 0);
    _goalSum.fillRange(0, _goalSum.length, 0);
    _goalExact.fillRange(0, _goalExact.length, 0);
    _stamp++;
    final stamp = _stamp;

    var slotTime = 0;
    var affinityTime = 0;
    var jointTime = 0.0;
    var push = 0;
    var pull = 0;
    var knee = 0;
    var hip = 0;
    var cover = 0;
    var coreDays = 0;
    var likedSeen = 0;
    var knownSeen = 0;
    var novelSeen = 0;
    var fitSum = 0.0;
    var relevantMobility = 0;
    var cardioStack = 0;
    var duplicates = 0;
    var sameRoot = 0;
    var patternExcess = 0;
    var slots = 0;
    var hardCardio = 0;
    var easyCardio = 0;
    var wodDays = 0;
    var mobilitySlots = 0;
    var regionMask = 0;
    var sfrSum = 0.0;
    var sfrTime = 0;
    var skillFamilies = 0;

    for (var d = 0; d < dayCount; d++) {
      final ex = state.exercise[d];
      final sets = state.sets[d];
      final n = state.count[d];
      final dayStamp = stamp * 8 + d;
      var t = 0;
      var fatigue = 0;
      var warm = false;
      var conditioning = 0;
      var coreHere = false;
      var strengthHere = false;
      var cardioHere = 0;
      var regions = 0;
      var mobilityHere = 0;
      for (var i = 0; i < n; i++) {
        final e = pool[ex[i]];
        final count = sets[i];
        final seconds = e.scheme.secondsFor(count);
        final exercise = e.traits.exercise;
        slots++;
        t += seconds;
        _classTime[e.cls.index] += seconds;
        affinityTime += seconds * e.affinity;
        fatigue += seconds * exercise.systemicFatigue;
        jointTime += seconds * e.jointPenalty;
        fitSum += e.fit;
        if (e.needsWarmup) {
          warm = true;
        }
        final cg = e.creditGroups;
        final cv = e.creditValues;
        final credited = e.scheme.continuous ? 1 : count;
        for (var k = 0; k < cg.length; k++) {
          final v = cv[k];
          _volume[cg[k]] += credited * v;
          if (v == 2 && e.heavyWeight > 0) {
            _heavy[d * groups + cg[k]] += credited * e.heavyWeight;
          }
        }
        push += count * e.pushUnits;
        pull += count * e.pullUnits;
        knee += count * e.kneeUnits;
        hip += count * e.hipUnits;
        cover |= e.coverBits;
        if (e.coverBits & coreBit != 0) {
          coreHere = true;
        }
        final support = e.goalSupport;
        for (var j = 0; j < support.length; j++) {
          final v = support[j];
          _goalSum[j] += v;
          if (v == 100) {
            _goalExact[j]++;
          }
        }
        if (_weekSeen[e.index] == stamp) {
          if (!repeatAllowed(e)) {
            duplicates++;
          }
        } else {
          _weekSeen[e.index] = stamp;
          if (e.liked) {
            likedSeen++;
          }
          if (e.known) {
            knownSeen++;
          }
          if (e.novel) {
            novelSeen++;
          }
        }
        final root = e.rootIndex;
        if (_rootDay[root] == dayStamp) {
          sameRoot++;
        } else {
          _rootDay[root] = dayStamp;
        }
        final kind = e.kind;
        if (kind == SlotKind.mobility) {
          if (mobilityHere < _dayMobility.length) {
            _dayMobility[mobilityHere] = e.traits.regionMask;
          }
          mobilityHere++;
        } else {
          regions |= e.traits.regionMask;
        }
        if (kind != SlotKind.mobility) {
          final p = exercise.pattern.index;
          if (_patternStamp[p] != dayStamp) {
            _patternStamp[p] = dayStamp;
            _patternCount[p] = 1;
          } else {
            _patternCount[p]++;
            if (_patternCount[p] > (kind.isCardio ? 1 : 2)) {
              patternExcess++;
            }
          }
        }
        switch (kind) {
          case SlotKind.cardioHard:
            hardCardio++;
            cardioHere++;
          case SlotKind.cardioEasy:
            easyCardio++;
            cardioHere++;
          case SlotKind.conditioning:
            conditioning++;
          case SlotKind.mobility:
            mobilitySlots++;
            regionMask |= e.traits.regionMask;
          case SlotKind.skillStatic:
          case SlotKind.skillDynamic:
            if (_skillWeek[root] != stamp) {
              _skillWeek[root] = stamp;
              _skillDays[root] = 0;
              _skillDay[root] = -1;
              _skillTouched[skillFamilies] = root;
              skillFamilies++;
            }
            if (_skillDay[root] != d) {
              _skillDay[root] = d;
              _skillDays[root]++;
            }
          case SlotKind.power:
          case SlotKind.compound:
            strengthHere = true;
          case SlotKind.accessory:
          case SlotKind.core:
            break;
        }
        final sfr = e.traits.stimulusFatigue;
        if (sfr >= 0) {
          sfrSum += sfr * seconds;
          sfrTime += seconds;
        }
      }
      slotTime += t;
      _dayTime[d] = warm ? t + days[d].warmupSeconds : t;
      _dayFatigue[d] = fatigue / days[d].seconds;
      if (conditioning >= 2 && strengthHere) {
        wodDays++;
      }
      if (cardioHere > 2) {
        cardioStack += cardioHere - 2;
      }
      // Mobilité en rapport avec le travail du jour (échauffement des
      // articulations sollicitées, étirement des muscles travaillés).
      final listed = mobilityHere < _dayMobility.length
          ? mobilityHere
          : _dayMobility.length;
      for (var m = 0; m < listed; m++) {
        if (regions == 0 || _dayMobility[m] & regions != 0) {
          relevantMobility++;
        }
      }
      if (coreHere) {
        coreDays++;
      }
    }

    coveredBits = cover;
    slotSeconds = slotTime;
    final w = params.weights;
    final c = components;

    // Sécurité : récupération (48 h).
    var heavyTotal = 0;
    for (var i = 0; i < dayCount * groups; i++) {
      heavyTotal += _heavy[i];
    }
    var overlap = 0;
    final threshold = params.heavyPrimarySets * 2;
    for (final (a, b) in ctx.adjacentPairs) {
      for (var g = 0; g < groups; g++) {
        final x = _heavy[a * groups + g];
        final y = _heavy[b * groups + g];
        if (x >= threshold && y >= threshold) {
          overlap += x < y ? x : y;
        }
      }
    }
    var recovery = heavyTotal == 0 ? 1.0 : 1 - 2 * overlap / heavyTotal;
    if (recovery < 0) {
      recovery = 0;
    }
    c[0] = recovery;

    // Sécurité : fatigue répartie.
    var mean = 0.0;
    for (var d = 0; d < dayCount; d++) {
      mean += _dayFatigue[d];
    }
    mean /= dayCount;
    var deviation = 0.0;
    for (var d = 0; d < dayCount; d++) {
      final x = _dayFatigue[d] - mean;
      deviation += x < 0 ? -x : x;
    }
    deviation /= dayCount;
    var balance = mean <= 0 ? 1.0 : 1 - deviation / mean;
    if (balance < 0) {
      balance = 0;
    }
    c[1] = balance;

    // Sécurité : articulations limitées.
    c[2] = slotTime == 0 ? 1.0 : 1 - jointTime / slotTime;

    // Qualité : objectifs.
    final goals = ctx.goals;
    if (goals.isEmpty) {
      c[3] = 1;
    } else {
      var sum = 0.0;
      var weights = 0.0;
      final need = ctx.goalExposureTarget * 100;
      for (var j = 0; j < goals.length; j++) {
        var covered = _goalSum[j] / need;
        if (covered > 1) {
          covered = 1;
        }
        if (ctx.goalExactSelectable[j]) {
          covered = 0.5 * covered + (_goalExact[j] > 0 ? 0.5 : 0.0);
        }
        sum += goals[j].weight * covered;
        weights += goals[j].weight;
      }
      c[3] = sum / weights;
    }

    // Qualité : dosage des disciplines.
    final targets = ctx.targets;
    if (slotTime == 0) {
      c[4] = 0;
    } else {
      var distance = 0.0;
      for (var k = 0; k < targets.length; k++) {
        final gap = _classTime[k] / slotTime - targets[k];
        distance += gap < 0 ? -gap : gap;
      }
      c[4] = 1 - distance / 2;
    }

    // Qualité : volume par muscle.
    if (ctx.resistanceShare <= 0) {
      c[5] = 1;
    } else {
      var sum = 0.0;
      var weights = 0.0;
      for (var g = 0; g < groups; g++) {
        final v = _volume[g];
        final low = ctx.bandLow[g];
        final high = ctx.bandHigh[g];
        double s;
        if (v < low) {
          s = v / low;
        } else if (v > high) {
          s = 1 - (v - high) / high;
          if (s < 0) {
            s = 0;
          }
        } else {
          s = 1;
        }
        sum += ctx.groupWeight[g] * s;
        weights += ctx.groupWeight[g];
      }
      c[5] = weights <= 0 ? 1 : sum / weights;
    }

    // Qualité : équilibre des schémas.
    if (ctx.resistanceShare <= 0) {
      c[6] = 1;
    } else {
      final coverable = ctx.coverableBits;
      var pullPush = 1.0;
      if (push > 0 && coverable & 12 != 0) {
        pullPush = pull / (params.pullToPushRatio * push);
        if (pullPush > 1) {
          pullPush = 1;
        }
      }
      var hipKnee = 1.0;
      if (knee > 0 && coverable & 32 != 0) {
        hipKnee = hip / (params.hipToKneeRatio * knee);
        if (hipKnee > 1) {
          hipKnee = 1;
        }
      }
      var core = 1.0;
      if (coverable & coreBit != 0) {
        final wanted = dayCount >= 2 ? 2 : 1;
        core = coreDays / wanted;
        if (core > 1) {
          core = 1;
        }
      }
      final possible = _popCount(coverable & basePatternBits);
      final coverage = possible == 0
          ? 1.0
          : _popCount(cover & coverable & basePatternBits) / possible;
      c[6] = 0.3 * pullPush + 0.2 * hipKnee + 0.15 * core + 0.35 * coverage;
    }

    // Qualité : structure propre à la discipline.
    var specific = 0.0;
    for (final k in DisciplineClass.values) {
      final target = targets[k.index];
      if (target <= 0) {
        continue;
      }
      var sub = 1.0;
      switch (k) {
        case DisciplineClass.cardio:
          final n = hardCardio + easyCardio;
          if (n == 0) {
            sub = 0.5;
          } else {
            var wanted = 0;
            if (ctx.globalLevel > 0 && !ctx.cautious) {
              wanted = (params.cardioHardShare * n).round();
              if (wanted < 1 && n >= 3) {
                wanted = 1;
              }
            }
            final gap = hardCardio - wanted;
            sub = 1 - (gap < 0 ? -gap : gap) / n - cardioStack / n;
            if (sub < 0) {
              sub = 0;
            }
          }
        case DisciplineClass.calisthenics:
          if (skillFamilies == 0) {
            sub = 0.3;
          } else {
            final wantedDays = dayCount < params.skillPracticeDays
                ? dayCount
                : params.skillPracticeDays;
            var sum = 0.0;
            for (var f = 0; f < skillFamilies; f++) {
              final practiced = _skillDays[_skillTouched[f]] / wantedDays;
              sum += practiced > 1 ? 1 : practiced;
            }
            sub = sum / skillFamilies;
            if (skillFamilies > 3) {
              sub *= 3 / skillFamilies;
            }
          }
        case DisciplineClass.crossfit:
          var wanted = (target * dayCount).round();
          if (wanted < 1) {
            wanted = 1;
          }
          sub = wodDays / wanted;
          if (sub > 1) {
            sub = 1;
          }
        case DisciplineClass.mobility:
          if (mobilitySlots == 0) {
            sub = 0.5;
          } else {
            var wanted = mobilitySlots < 3 ? 3 : mobilitySlots;
            if (wanted > 9) {
              wanted = 9;
            }
            var coverage = _popCount(regionMask) / wanted;
            if (coverage > 1) {
              coverage = 1;
            }
            sub = 0.6 * coverage + 0.4 * relevantMobility / mobilitySlots;
            if (sub > 1) {
              sub = 1;
            }
          }
        case DisciplineClass.musculation:
        case DisciplineClass.streetWorkout:
        case DisciplineClass.streetlifting:
        case DisciplineClass.generalFitness:
          break;
      }
      specific += target * sub;
    }
    final own = slotTime == 0 ? 0.0 : affinityTime / (100.0 * slotTime);
    c[7] = 0.5 * own + 0.5 * specific;

    // Qualité : temps utilisé.
    var used = 0.0;
    for (var d = 0; d < dayCount; d++) {
      final u = _dayTime[d] / (days[d].seconds * params.timeUseTarget);
      used += u > 1 ? 1 : u;
    }
    c[8] = used / dayCount;

    // Qualité : variété.
    var redundancy =
        (sameRoot + 0.5 * patternExcess + 0.5 * duplicates) / (2 * dayCount);
    if (redundancy > 1) {
      redundancy = 1;
    }
    c[9] = 1 - redundancy;

    // Qualité : exercices adaptés.
    c[10] = slots == 0 ? 1.0 : fitSum / slots;

    // Qualité : rapport stimulus / fatigue.
    c[11] = sfrTime == 0 ? 1.0 : sfrSum / sfrTime;

    // Qualité : préférences (exercices aimés, exercices sus).
    final likedShare = ctx.likedCount == 0
        ? 1.0
        : (likedSeen >= ctx.likedCount ? 1.0 : likedSeen / ctx.likedCount);
    final knownShare = ctx.knownCount == 0
        ? 1.0
        : (knownSeen >= ctx.knownCount ? 1.0 : knownSeen / ctx.knownCount);
    c[12] = 0.6 * likedShare + 0.4 * knownShare;

    // Qualité : nouveautés techniques.
    final extra = novelSeen - ctx.noveltyAllowance;
    c[13] = extra <= 0 ? 1.0 : 1 - extra / novelSeen;

    final s =
        (w.recovery * c[0] + w.fatigueBalance * c[1] + w.jointLoad * c[2]) /
        w.safetySum;
    final q =
        (w.goalSpecificity * c[3] +
            w.disciplineDosage * c[4] +
            w.muscleVolume * c[5] +
            w.patternBalance * c[6] +
            w.disciplineStructure * c[7] +
            w.timeUse * c[8] +
            w.variety * c[9] +
            w.exerciseFit * c[10] +
            w.stimulusFatigue * c[11] +
            w.preferences * c[12] +
            w.novelty * c[13]) /
        w.qualitySum;
    safety = s;
    quality = q;
    total = params.safetyShare * s + (1 - params.safetyShare) * q;
    safetyBucket = (s / params.safetyStep + 1e-9).floor();
    return params.safetyPriority * s + total;
  }
}
