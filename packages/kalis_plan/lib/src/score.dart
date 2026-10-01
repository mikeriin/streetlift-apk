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

/// Écart moyen de fatigue entre séances toléré sans pénalité.
const double fatigueTolerance = 0.3;

/// Séries fictives ajoutées aux deux termes d'un rapport d'équilibre : un
/// premier exercice de poussée ou de jambes ne fait pas s'effondrer la note
/// avant que son pendant soit placé.
const int balancePriorHalfSets = 4;

/// Rapport au-delà duquel un côté domine trop l'autre (tirage sur poussée,
/// chaîne postérieure sur genou) : hypothèse d'ingénierie, `CONTRAT.md`.
const double balanceUpperRatio = 1.5;

/// Minutes de séance par exercice attendu (cinq exercices pour une heure).
const int minutesPerExpectedSlot = 12;

double _ratioScore(int a, int b, double low, double high) {
  final r = (a + balancePriorHalfSets) / (b + balancePriorHalfSets);
  if (r < low) {
    return r / low;
  }
  if (r > high) {
    return high / r;
  }
  return 1;
}

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
      _groupStamp = Int32List(MuscleGroup.values.length),
      _groupDays = Int32List(MuscleGroup.values.length),
      _dayWod = Float64List(context.dayCount),
      _weekSeen = Int32List(context.pool.length),
      _rootDay = Int32List(context.rootCount),
      _patternStamp = Int32List(64),
      _patternCount = Int32List(64),
      _skillWeek = Int32List(context.rootCount),
      _skillDay = Int32List(context.rootCount),
      _skillDays = Int32List(context.rootCount),
      _skillTouched = Int32List(context.rootCount),
      _dayAnchor = Float64List(context.dayCount),
      _anchorSaved = Float64List(context.dayCount),
      _anchorDays = _anchorDaysOf(context),
      _expectedSlots = _expectedSlotsOf(context),
      components = Float64List(ScoreWeights.codes.length);

  /// Séances de renforcement attendues : une fois et demie la part de
  /// renforcement, en jours, au moins une.
  static int _anchorDaysOf(PlanContext ctx) {
    final n = (1.5 * ctx.resistanceShare * ctx.dayCount - 0.25).ceil();
    return n < 1 ? 1 : (n > ctx.dayCount ? ctx.dayCount : n);
  }

  static int _expectedSlotsOf(PlanContext ctx) {
    var n = 0;
    for (final d in ctx.days) {
      final e = d.minutes ~/ minutesPerExpectedSlot;
      n += e < 2 ? 2 : e;
    }
    return n;
  }

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
  final Int32List _groupStamp;
  final Int32List _groupDays;
  final Float64List _dayWod;
  final Float64List _dayAnchor;
  final Float64List _anchorSaved;
  final int _anchorDays;
  final int _expectedSlots;
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
    _groupDays.fillRange(0, groups, 0);
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
    var fitSlots = 0;
    var relevantMobility = 0;
    var cardioStack = 0;
    var skillDays = 0;
    var duplicates = 0;
    var sameRoot = 0;
    var patternExcess = 0;
    var slots = 0;
    var hardCardio = 0;
    var easyCardio = 0;
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
      var coreSlots = 0;
      var coreHere = false;
      var strengthHere = false;
      var anchor = 0.0;
      var skillHere = false;
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
        // Un exercice réduit sous sa dose de référence vaut d'autant moins :
        // mieux vaut cinq exercices complets que huit exercices rognés.
        // Un effort continu (footing, routine) compte pour autant
        // d'exercices que sa durée en remplace.
        if (e.scheme.continuous) {
          final units = seconds ~/ (minutesPerExpectedSlot * 60);
          final n = units < 1 ? 1 : units;
          fitSum += e.fit * n;
          fitSlots += n;
        } else {
          final dose = e.scheme.sets;
          fitSum += count >= dose ? e.fit : e.fit * count / dose;
          fitSlots++;
        }
        if (e.needsWarmup) {
          warm = true;
        }
        final cg = e.creditGroups;
        final cv = e.creditValues;
        final credited = e.scheme.continuous
            ? 1
            : (e.practice ? (count + 1) >> 1 : count);
        for (var k = 0; k < cg.length; k++) {
          final v = cv[k];
          _volume[cg[k]] += credited * v;
          if (v == 2) {
            final g = cg[k];
            if (e.heavyWeight > 0) {
              _heavy[d * groups + g] += count * e.heavyWeight;
            }
            if (_groupStamp[g] != dayStamp) {
              _groupStamp[g] = dayStamp;
              _groupDays[g]++;
            }
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
            skillHere = true;
            if (ctx.hasPrioritySkill && !e.prioritySkill) {
              break;
            }
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
            break;
          case SlotKind.core:
            coreSlots++;
            if (coreSlots > 2) {
              patternExcess++;
            }
        }
        if (e.staple > anchor) {
          anchor = e.staple;
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
      final piece = conditioning >= 3 ? 1.0 : conditioning / 3;
      _dayWod[d] = 0.5 * piece + (strengthHere ? 0.5 : 0.0);
      _dayAnchor[d] = anchor;
      _anchorSaved[d] = anchor;
      if (cardioHere > 2) {
        cardioStack += cardioHere - 2;
      }
      if (skillHere) {
        skillDays++;
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
    // Un écart moyen de 30 % entre les séances est sans conséquence
    // (alternance de jours durs et légers) ; au-delà, la note baisse.
    var balance = 1.0;
    if (mean > 0) {
      final spread = deviation / mean - fatigueTolerance;
      if (spread > 0) {
        balance = 1 - spread / (1 - fatigueTolerance);
      }
    }
    if (balance < 0) {
      balance = 0;
    }
    c[1] = balance;

    // Sécurité : articulations limitées.
    c[2] = slotTime == 0 ? 1.0 : 1 - jointTime / slotTime;

    // Qualité : objectifs.
    final goals = ctx.goals;
    var goalWeightSum = 0.0;
    for (var j = 0; j < goals.length; j++) {
      goalWeightSum += ctx.goalWeights[j];
    }
    if (goalWeightSum <= 0) {
      c[3] = 1;
    } else {
      var sum = 0.0;
      for (var j = 0; j < goals.length; j++) {
        final weight = ctx.goalWeights[j];
        if (weight <= 0) {
          continue;
        }
        // Expositions visées, comptées en meilleur palier disponible.
        final need = ctx.goalExposureTarget * ctx.goalBestSupport[j];
        var covered = _goalSum[j] / need;
        if (covered > 1) {
          covered = 1;
        }
        if (ctx.goalExactSelectable[j]) {
          covered = 0.5 * covered + (_goalExact[j] > 0 ? 0.5 : 0.0);
        }
        sum += weight * covered;
      }
      c[3] = sum / goalWeightSum;
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
    var saturation = 0.0;
    if (ctx.resistanceShare <= 0) {
      c[5] = 1;
    } else {
      var sum = 0.0;
      var weights = 0.0;
      var twice = 0.0;
      var trained = 0.0;
      var filled = 0.0;
      for (var g = 0; g < groups; g++) {
        final v = _volume[g];
        final low = ctx.bandLow[g];
        final high = ctx.bandHigh[g];
        double s;
        if (v < low) {
          s = v / low;
        } else if (v > high) {
          s = 1 - 2 * (v - high) / high;
          if (s < 0) {
            s = 0;
          }
        } else {
          s = 1;
        }
        final weight = ctx.groupWeight[g];
        sum += weight * s;
        weights += weight;
        if (high > 0) {
          filled += weight * (v >= high ? 1.0 : v / high);
        }
        if (low > 0 && _groupDays[g] > 0) {
          trained += weight;
          if (_groupDays[g] >= 2 || dayCount < 2) {
            twice += weight;
          }
        }
      }
      // Bande de volume (70 %) et fréquence : un groupe travaillé l'est au
      // moins deux jours par semaine (30 %).
      final band = weights <= 0 ? 1.0 : sum / weights;
      final frequency = trained <= 0 ? 1.0 : twice / trained;
      c[5] = 0.7 * band + 0.3 * frequency;
      saturation = weights <= 0 ? 0.0 : filled / weights;
    }

    // Qualité : équilibre des schémas.
    if (ctx.resistanceShare <= 0) {
      c[6] = 1;
    } else {
      final coverable = ctx.coverableBits;
      // Les deux côtés d'un rapport ne se comparent que si le vivier les
      // permet tous les deux.
      var pullPush = 1.0;
      if (coverable & 3 != 0 && coverable & 12 != 0) {
        pullPush = _ratioScore(
          pull,
          push,
          params.pullToPushRatio,
          balanceUpperRatio,
        );
      }
      var hipKnee = 1.0;
      if (coverable & 16 != 0 && coverable & 32 != 0) {
        hipKnee = _ratioScore(
          hip,
          knee,
          params.hipToKneeRatio,
          balanceUpperRatio,
        );
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
          // Pratique fréquente et courte : une figure à chaque séance de
          // calisthénie, et chaque figure prioritaire (connue, ou palier
          // d'un objectif) travaillée trois jours par semaine.
          var wantedSkillDays = (target * dayCount).round();
          if (wantedSkillDays < 1) {
            wantedSkillDays = 1;
          }
          var presence = skillDays / wantedSkillDays;
          if (presence > 1) {
            presence = 1;
          }
          var frequency = 0.0;
          if (skillFamilies > 0) {
            final wantedDays = dayCount < params.skillPracticeDays
                ? dayCount
                : params.skillPracticeDays;
            var sum = 0.0;
            for (var f = 0; f < skillFamilies; f++) {
              final practiced = _skillDays[_skillTouched[f]] / wantedDays;
              sum += practiced > 1 ? 1 : practiced;
            }
            frequency = sum / skillFamilies;
            if (skillFamilies > 3) {
              frequency *= 3 / skillFamilies;
            }
          }
          sub = 0.5 * presence + 0.5 * frequency;
        case DisciplineClass.crossfit:
          // Une séance de CrossFit : une partie de force ou de technique,
          // puis une pièce de conditionnement d'environ trois mouvements.
          var wanted = (target * dayCount).round();
          if (wanted < 1) {
            wanted = 1;
          }
          var sum = 0.0;
          for (var rank = 0; rank < wanted; rank++) {
            var best = -1;
            for (var d = 0; d < dayCount; d++) {
              if (_dayWod[d] >= 0 && (best < 0 || _dayWod[d] > _dayWod[best])) {
                best = d;
              }
            }
            if (best < 0) {
              break;
            }
            sum += _dayWod[best];
            _dayWod[best] = -1;
          }
          sub = sum / wanted;
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
          // Les séances de renforcement attendues s'ancrent chacune sur
          // un mouvement de base (ou le mouvement d'un objectif) : on
          // compte les meilleures ancres de la semaine, si bien que retirer
          // du renforcement ne rapporte jamais.
          var sum = 0.0;
          for (var rank = 0; rank < _anchorDays; rank++) {
            var best = -1;
            for (var d = 0; d < dayCount; d++) {
              if (_dayAnchor[d] >= 0 &&
                  (best < 0 || _dayAnchor[d] > _dayAnchor[best])) {
                best = d;
              }
            }
            if (best < 0) {
              break;
            }
            sum += _dayAnchor[best];
            _dayAnchor[best] = -1;
          }
          sub = sum / _anchorDays;
          // Les autres classes de renforcement relisent les mêmes ancres.
          for (var d = 0; d < dayCount; d++) {
            _dayAnchor[d] = _anchorSaved[d];
          }
      }
      specific += target * sub;
    }
    final own = slotTime == 0 ? 0.0 : affinityTime / (100.0 * slotTime);
    c[7] = 0.5 * own + 0.5 * specific;

    // Qualité : temps utilisé.
    // Moitié moyenne, moitié séance la moins remplie : des séances
    // équilibrées plutôt qu'une séance pleine et une séance creuse.
    var used = 0.0;
    var least = 1.0;
    var most = 0.0;
    for (var d = 0; d < dayCount; d++) {
      var u = _dayTime[d] / (days[d].seconds * params.timeUseTarget);
      if (u > 1) {
        u = 1;
      }
      used += u;
      if (u < least) {
        least = u;
      }
      if (u > most) {
        most = u;
      }
    }
    // Quand tous les groupes ont atteint le haut de leur bande, il n'y a
    // plus de travail utile à ajouter : des séances plus courtes que le
    // temps disponible ne coûtent alors plus rien — pourvu qu'elles
    // restent équilibrées entre elles.
    final mean = used / dayCount;
    final full = saturation * saturation;
    final even = most <= 0 ? 0.0 : least / most;
    c[8] = 0.5 * (mean + (1 - mean) * full) + 0.5 * even;

    // Qualité : variété.
    var redundancy =
        (sameRoot + 0.5 * patternExcess + 0.5 * duplicates) / (2 * dayCount);
    if (redundancy > 1) {
      redundancy = 1;
    }
    c[9] = 1 - redundancy;

    // Qualité : exercices adaptés.
    // Moyenne sur le nombre d'exercices attendu tant qu'il n'est pas
    // atteint : un exercice de plus ne fait pas baisser la note d'une
    // semaine encore creuse.
    c[10] = slots == 0
        ? 1.0
        : fitSum / (fitSlots < _expectedSlots ? _expectedSlots : fitSlots);

    // Qualité : rapport stimulus / fatigue.
    c[11] = sfrTime == 0 ? 1.0 : sfrSum / sfrTime;

    // Qualité : préférences (exercices aimés, exercices sus).
    final likedShare = ctx.likedCount == 0
        ? 1.0
        : (likedSeen >= ctx.likedCount ? 1.0 : likedSeen / ctx.likedCount);
    final knownShare = ctx.knownCount == 0
        ? 1.0
        : (knownSeen >= ctx.knownCount ? 1.0 : knownSeen / ctx.knownCount);
    c[12] = 0.5 * likedShare + 0.5 * knownShare;

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
