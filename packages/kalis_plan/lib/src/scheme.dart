/// Modèles de prescription : pour un exercice et un athlète, le nombre de
/// séries, la plage (répétitions, secondes, distance), le repos et les
/// répétitions en réserve de la semaine la plus chargée du bloc. La passe 1
/// s'en sert pour estimer la durée d'une séance ; la passe 2 les module
/// semaine par semaine. Justifications : `CONTRAT.md`, § Prescription.
library;

import 'package:kalis_core/kalis_core.dart';

import 'params.dart';
import 'traits.dart';

/// Famille de prescription.
enum SchemeKind {
  /// Mouvement de force principal : charges lourdes, repos longs.
  strengthMain('strength_main'),

  /// Polyarticulaire de force en assistance.
  strengthAssist('strength_assist'),

  /// Polyarticulaire en charges modérées.
  hypertrophyCompound('hypertrophy_compound'),

  /// Isolation en répétitions hautes.
  hypertrophyIsolation('hypertrophy_isolation'),

  /// Exercice au poids du corps, en répétitions relatives au maximum.
  bodyweightReps('bodyweight_reps'),

  /// Tenue de figure sous-maximale.
  skillHold('skill_hold'),

  /// Figure dynamique en séries courtes de qualité.
  skillReps('skill_reps'),

  /// Haltérophilie : séries courtes, technique, jamais à l'échec.
  power('power'),

  /// Pliométrie.
  plyometric('plyometric'),

  /// Balistique (kettlebell).
  ballistic('ballistic'),

  /// Porté sur une distance.
  carry('carry'),

  /// Tronc en répétitions.
  coreReps('core_reps'),

  /// Gainage tenu.
  coreHold('core_hold'),

  /// Élément d'une pièce de conditionnement, en tours.
  conditioning('conditioning'),

  /// Cardio continu : une durée.
  cardioContinuous('cardio_continuous'),

  /// Fractionné : répétitions d'effort et récupération.
  cardioIntervals('cardio_intervals'),

  /// Sprints.
  cardioSprints('cardio_sprints'),

  /// Éducatifs de course.
  cardioDrill('cardio_drill'),

  /// Corde à sauter.
  jumpRope('jump_rope'),

  /// Étirement tenu.
  mobilityHold('mobility_hold'),

  /// Mobilité en répétitions.
  mobilityReps('mobility_reps'),

  /// Routine de mobilité, auto-massage ou respiration : une durée.
  mobilityBlock('mobility_block');

  const SchemeKind(this.code);

  /// Code stable.
  final String code;
}

/// Ce que le profil apporte au choix d'un modèle de prescription.
final class SchemeInputs {
  /// Entrées d'un exercice.
  const SchemeInputs({
    required this.level,
    required this.margin,
    required this.strengthFocus,
    required this.goalLift,
    required this.cautious,
    required this.senior,
    this.maxReps,
    this.maxHoldSeconds,
  });

  /// Niveau de l'athlète sur le groupe de l'exercice : 0 débutant,
  /// 1 intermédiaire, 2 avancé, 3 élite.
  final int level;

  /// Marge : niveau de l'athlète moins difficulté de l'exercice.
  final int margin;

  /// Discipline ou objectif de force maximale.
  final bool strengthFocus;

  /// L'exercice est un mouvement de compétition ou l'exercice d'un objectif.
  final bool goalLift;

  /// Programme prudent (questionnaire santé, âge).
  final bool cautious;

  /// 65 ans et plus.
  final bool senior;

  /// Répétitions maximales connues sur cet exercice.
  final int? maxReps;

  /// Tenue maximale connue sur cet exercice, en secondes.
  final int? maxHoldSeconds;
}

/// Prescription de référence d'un exercice (semaine la plus chargée).
final class Scheme {
  const Scheme._({
    required this.kind,
    required this.sets,
    required this.minSets,
    required this.maxSets,
    required this.unit,
    required this.low,
    required this.high,
    required this.distanceMeters,
    required this.calories,
    required this.restSeconds,
    required this.rir,
    required this.workSeconds,
    required this.fixedSeconds,
    required this.continuous,
    required this.format,
    required this.loaded,
  });

  /// Famille.
  final SchemeKind kind;

  /// Séries de la semaine la plus chargée (pour un cardio continu ou une
  /// routine : nombre de tranches de [continuousUnitSeconds]).
  final int sets;

  /// Plus petit nombre de séries.
  final int minSets;

  /// Plus grand nombre de séries.
  final int maxSets;

  /// Unité de la plage.
  final MeasureUnit unit;

  /// Bas de la plage (répétitions ou secondes ; 0 pour distance, calories).
  final int low;

  /// Haut de la plage.
  final int high;

  /// Distance par série, en mètres (unité distance).
  final double? distanceMeters;

  /// Calories par série (unité calories).
  final double? calories;

  /// Repos entre les séries, en secondes.
  final int restSeconds;

  /// Répétitions en réserve visées la semaine de référence, ou `null`
  /// (cardio, mobilité, conditionnement).
  final double? rir;

  /// Durée d'effort d'une série, en secondes.
  final int workSeconds;

  /// Temps fixe : mise en place, transition, séries de montée en charge.
  final int fixedSeconds;

  /// Vrai si l'exercice est une seule durée continue (les « séries » sont
  /// des tranches de [continuousUnitSeconds]).
  final bool continuous;

  /// Code du format de la prescription, ou `null`.
  final String? format;

  /// Vrai si une charge externe se règle (barre, haltères, lest, machine…).
  final bool loaded;

  /// Durée d'une tranche d'un exercice continu, en secondes.
  static const int continuousUnitSeconds = 300;

  /// Durée d'une série, repos compris, en secondes.
  int get perSetSeconds => continuous ? continuousUnitSeconds : workSeconds + restSeconds;

  /// Durée de l'exercice pour [setCount] séries, en secondes.
  int secondsFor(int setCount) => fixedSeconds + setCount * perSetSeconds;
}

int _byLevel(List<int> values, int level) =>
    values[level < 0 ? 0 : (level > 3 ? 3 : level)];

double _rirFor(List<double> values, SchemeInputs i) {
  final base = values[i.level < 0 ? 0 : (i.level > 3 ? 3 : i.level)];
  return i.cautious && base < 3 ? 3 : base;
}

int _sides(CatalogExercise e) => e.laterality == Laterality.unilateral ? 2 : 1;

/// Types de charge dont la valeur se règle.
bool isLoadAdjustable(LoadType type) {
  switch (type) {
    case LoadType.addedWeight:
    case LoadType.barbell:
    case LoadType.dumbbells:
    case LoadType.kettlebell:
    case LoadType.machine:
    case LoadType.cable:
      return true;
    case LoadType.none:
    case LoadType.bodyweight:
    case LoadType.band:
    case LoadType.other:
      return false;
  }
}

/// Modèle de prescription de l'exercice [t] pour l'athlète décrit par [i].
Scheme schemeFor(ExerciseTraits t, SchemeInputs i, PlanParams params) {
  final e = t.exercise;
  final sides = _sides(e);
  final rep = params.secondsPerRep;
  final transition = params.transitionSeconds;
  final loaded = isLoadAdjustable(e.loadType);
  final capSets = i.cautious || i.senior ? 3 : 20;

  Scheme reps(
    SchemeKind kind,
    List<int> sets,
    int low,
    int high,
    int rest,
    double? rir, {
    int ramp = 0,
    int minSets = 2,
    int maxSets = 6,
    String? format,
    double cadence = 1,
  }) {
    final n = _byLevel(sets, i.level);
    final s = n > capSets ? capSets : n;
    return Scheme._(
      kind: kind,
      sets: s,
      minSets: minSets > s ? s : minSets,
      maxSets: maxSets > capSets ? capSets : maxSets,
      unit: MeasureUnit.repetitions,
      low: low,
      high: high,
      distanceMeters: null,
      calories: null,
      restSeconds: rest,
      rir: rir,
      workSeconds: (high * rep * sides * cadence).round(),
      fixedSeconds: transition + ramp,
      continuous: false,
      format: format,
      loaded: loaded,
    );
  }

  Scheme hold(
    SchemeKind kind,
    List<int> sets,
    int low,
    int high,
    int rest,
    double? rir, {
    int minSets = 1,
    int maxSets = 6,
    String? format,
  }) {
    final n = _byLevel(sets, i.level);
    final s = n > capSets ? capSets : n;
    return Scheme._(
      kind: kind,
      sets: s,
      minSets: minSets > s ? s : minSets,
      maxSets: maxSets > capSets ? capSets : maxSets,
      unit: MeasureUnit.seconds,
      low: low,
      high: high,
      distanceMeters: null,
      calories: null,
      restSeconds: rest,
      rir: rir,
      workSeconds: high * sides,
      fixedSeconds: transition,
      continuous: false,
      format: format,
      loaded: loaded,
    );
  }

  Scheme distance(
    SchemeKind kind,
    List<int> sets,
    double meters,
    double metersPerSecond,
    int rest, {
    int minSets = 2,
    int maxSets = 12,
    String? format,
    double? rir,
  }) {
    final n = _byLevel(sets, i.level);
    return Scheme._(
      kind: kind,
      sets: n,
      minSets: minSets > n ? n : minSets,
      maxSets: maxSets,
      unit: MeasureUnit.distance,
      low: 0,
      high: 0,
      distanceMeters: meters,
      calories: null,
      restSeconds: rest,
      rir: rir,
      workSeconds: (meters / metersPerSecond).round(),
      fixedSeconds: transition,
      continuous: false,
      format: format,
      loaded: loaded,
    );
  }

  Scheme continuous(SchemeKind kind, List<int> minutes, int maxMinutes) {
    final m = _byLevel(minutes, i.level);
    final units = (m * 60) ~/ Scheme.continuousUnitSeconds;
    final maxUnits = (maxMinutes * 60) ~/ Scheme.continuousUnitSeconds;
    return Scheme._(
      kind: kind,
      sets: units < 1 ? 1 : units,
      minSets: units < 2 ? 1 : 2,
      maxSets: maxUnits < units ? units : maxUnits,
      unit: MeasureUnit.seconds,
      low: 0,
      high: 0,
      distanceMeters: null,
      calories: null,
      restSeconds: 0,
      rir: null,
      workSeconds: Scheme.continuousUnitSeconds,
      fixedSeconds: 0,
      continuous: true,
      format: kind == SchemeKind.cardioContinuous ? 'continuous' : null,
      loaded: false,
    );
  }

  // Plage d'un exercice au poids du corps : moitié à trois quarts du
  // maximum connu, sinon selon la marge entre le niveau et la difficulté.
  (int, int) bodyweightRange() {
    final max = i.maxReps;
    if (max != null && max >= 2) {
      final low = max ~/ 2 < 1 ? 1 : max ~/ 2;
      var high = (max * 3) ~/ 4;
      if (high < low) {
        high = low;
      }
      if (high > 30) {
        high = 30;
      }
      return (low > high ? high : low, high);
    }
    if (i.margin >= 3) {
      return (12, 20);
    }
    if (i.margin == 2) {
      return (10, 15);
    }
    if (i.margin == 1) {
      return (6, 12);
    }
    return (3, 8);
  }

  (int, int) holdRange(int easyLow, int easyHigh, int hardLow, int hardHigh) {
    final max = i.maxHoldSeconds;
    if (max != null && max >= 4) {
      var low = max ~/ 2;
      if (low < 3) {
        low = 3;
      }
      var high = (max * 3) ~/ 4;
      if (high < low) {
        high = low;
      }
      if (high > 60) {
        high = 60;
      }
      return (low > high ? high : low, high);
    }
    return i.margin >= 2 ? (easyLow, easyHigh) : (hardLow, hardHigh);
  }

  switch (t.kind) {
    case SlotKind.mobility:
      final p = e.pattern;
      if (p == MovementPattern.autoMassage) {
        return hold(SchemeKind.mobilityBlock, const <int>[1, 1, 1, 1], 60, 90, 15, null);
      }
      if (p == MovementPattern.respiration) {
        return hold(SchemeKind.mobilityBlock, const <int>[1, 1, 1, 1], 120, 180, 15, null);
      }
      if (e.id.contains('routine')) {
        return continuous(SchemeKind.mobilityBlock, const <int>[5, 5, 10, 10], 15);
      }
      if (e.unit == MeasureUnit.seconds) {
        final long = i.senior || p == MovementPattern.souplesse;
        return hold(
          SchemeKind.mobilityHold,
          const <int>[2, 2, 2, 3],
          long ? 30 : 20,
          long ? 45 : 30,
          10,
          null,
          maxSets: 4,
        );
      }
      return reps(
        SchemeKind.mobilityReps,
        const <int>[2, 2, 2, 2],
        8,
        12,
        10,
        null,
        minSets: 1,
        maxSets: 3,
      );
    case SlotKind.cardioEasy:
      final p = e.pattern;
      if (p == MovementPattern.cordeASauter) {
        if (e.unit == MeasureUnit.repetitions) {
          return reps(
            SchemeKind.jumpRope,
            const <int>[4, 5, 6, 6],
            20,
            40,
            45,
            null,
            maxSets: 10,
            format: 'intervals',
            cadence: 0.25,
          );
        }
        return hold(
          SchemeKind.jumpRope,
          const <int>[4, 5, 6, 6],
          45,
          60,
          30,
          null,
          minSets: 2,
          maxSets: 10,
          format: 'intervals',
        );
      }
      if (p == MovementPattern.sprint) {
        if (e.unit == MeasureUnit.distance) {
          return distance(
            SchemeKind.cardioDrill,
            const <int>[2, 3, 3, 3],
            30,
            2,
            30,
            maxSets: 4,
          );
        }
        return hold(SchemeKind.cardioDrill, const <int>[2, 3, 3, 3], 15, 20, 30, null);
      }
      if (p == MovementPattern.marche) {
        return continuous(
          SchemeKind.cardioContinuous,
          const <int>[20, 30, 30, 30],
          i.cautious ? 45 : 90,
        );
      }
      if (e.id.contains('longue')) {
        return continuous(
          SchemeKind.cardioContinuous,
          const <int>[40, 60, 75, 90],
          i.level <= 0 ? 60 : (i.level == 1 ? 105 : 150),
        );
      }
      return continuous(
        SchemeKind.cardioContinuous,
        const <int>[20, 30, 40, 45],
        i.level <= 0 || i.cautious ? 45 : (i.level == 1 ? 75 : 90),
      );
    case SlotKind.cardioHard:
      final p = e.pattern;
      if (p == MovementPattern.cardioContinu) {
        return continuous(
          SchemeKind.cardioContinuous,
          const <int>[15, 20, 25, 30],
          i.level <= 1 ? 30 : 40,
        );
      }
      if (p == MovementPattern.cordeASauter) {
        if (e.unit == MeasureUnit.repetitions) {
          return reps(
            SchemeKind.jumpRope,
            const <int>[4, 5, 6, 6],
            15,
            30,
            45,
            null,
            maxSets: 10,
            format: 'intervals',
            cadence: 0.3,
          );
        }
        return hold(
          SchemeKind.jumpRope,
          const <int>[4, 5, 6, 6],
          45,
          60,
          45,
          null,
          minSets: 2,
          maxSets: 10,
          format: 'intervals',
        );
      }
      if (p == MovementPattern.sprint) {
        if (e.unit == MeasureUnit.distance) {
          return distance(
            SchemeKind.cardioSprints,
            const <int>[4, 6, 8, 8],
            50,
            6,
            120,
            format: 'sprints',
          );
        }
        return hold(
          SchemeKind.cardioSprints,
          const <int>[4, 6, 8, 8],
          15,
          20,
          100,
          null,
          minSets: 2,
          maxSets: 10,
          format: 'sprints',
        );
      }
      if (e.unit == MeasureUnit.distance) {
        final meters = t.intervalMeters > 0 ? t.intervalMeters : 400;
        final total = _byLevel(const <int>[1600, 2000, 2400, 3000], i.level);
        var n = (total / meters).round();
        n = n < 3 ? 3 : (n > 12 ? 12 : n);
        final work = (meters / 3.5).round();
        return distance(
          SchemeKind.cardioIntervals,
          <int>[n, n, n, n],
          meters.toDouble(),
          3.5,
          work > 180 ? 180 : work,
          format: 'intervals',
        );
      }
      if (e.unit == MeasureUnit.calories) {
        final n = _byLevel(const <int>[4, 5, 6, 6], i.level);
        return Scheme._(
          kind: SchemeKind.cardioIntervals,
          sets: n,
          minSets: 2,
          maxSets: 10,
          unit: MeasureUnit.calories,
          low: 0,
          high: 0,
          distanceMeters: null,
          calories: 12,
          restSeconds: 90,
          rir: null,
          workSeconds: 48,
          fixedSeconds: transition,
          continuous: false,
          format: 'intervals',
          loaded: false,
        );
      }
      if (e.id.contains('30-30')) {
        return hold(
          SchemeKind.cardioIntervals,
          const <int>[8, 10, 12, 12],
          30,
          30,
          30,
          null,
          minSets: 4,
          maxSets: 20,
          format: 'intervals',
        );
      }
      return hold(
        SchemeKind.cardioIntervals,
        const <int>[4, 5, 6, 6],
        60,
        90,
        90,
        null,
        minSets: 2,
        maxSets: 10,
        format: 'intervals',
      );
    case SlotKind.conditioning:
      const rounds = <int>[3, 4, 5, 5];
      if (e.unit == MeasureUnit.seconds) {
        return hold(
          SchemeKind.conditioning,
          rounds,
          30,
          40,
          15,
          null,
          minSets: 2,
          maxSets: 8,
          format: 'rounds',
        );
      }
      if (e.unit == MeasureUnit.distance) {
        return distance(
          SchemeKind.conditioning,
          rounds,
          20,
          0.7,
          15,
          maxSets: 8,
          format: 'rounds',
        );
      }
      final hard = e.difficulty >= 7;
      return reps(
        SchemeKind.conditioning,
        rounds,
        hard ? 3 : 8,
        hard ? 6 : 12,
        15,
        null,
        maxSets: 8,
        format: 'rounds',
        cadence: 0.85,
      );
    case SlotKind.skillStatic:
      final (low, high) = holdRange(10, 20, 5, 10);
      return hold(
        SchemeKind.skillHold,
        const <int>[3, 4, 5, 5],
        low,
        high,
        120,
        _rirFor(const <double>[3, 2.5, 2.5, 2.5], i),
        minSets: 2,
      );
    case SlotKind.skillDynamic:
      if (e.unit == MeasureUnit.distance) {
        return distance(
          SchemeKind.skillReps,
          const <int>[3, 4, 5, 5],
          5,
          0.25,
          120,
          maxSets: 6,
          rir: _rirFor(const <double>[3, 2.5, 2.5, 2.5], i),
        );
      }
      return reps(
        SchemeKind.skillReps,
        const <int>[3, 4, 5, 5],
        2,
        5,
        150,
        _rirFor(const <double>[3, 2.5, 2.5, 2.5], i),
      );
    case SlotKind.power:
      final p = e.pattern;
      if (p == MovementPattern.halterophilie) {
        return reps(
          SchemeKind.power,
          const <int>[3, 4, 5, 5],
          2,
          3,
          150,
          _rirFor(const <double>[3, 3, 3, 2.5], i),
          ramp: 90,
        );
      }
      if (p == MovementPattern.pliometrie) {
        if (e.unit == MeasureUnit.seconds) {
          return hold(
            SchemeKind.plyometric,
            const <int>[2, 3, 3, 4],
            15,
            20,
            60,
            _rirFor(const <double>[3, 3, 3, 3], i),
            maxSets: 5,
          );
        }
        return reps(
          SchemeKind.plyometric,
          const <int>[2, 3, 3, 4],
          5,
          8,
          90,
          _rirFor(const <double>[3, 3, 3, 3], i),
          maxSets: 5,
          cadence: 0.7,
        );
      }
      return reps(
        SchemeKind.ballistic,
        const <int>[3, 3, 4, 4],
        10,
        15,
        75,
        _rirFor(const <double>[3, 2.5, 2.5, 2.5], i),
        cadence: 0.6,
      );
    case SlotKind.core:
      if (e.unit == MeasureUnit.seconds) {
        final (low, high) = holdRange(20, 40, 10, 20);
        return hold(
          SchemeKind.coreHold,
          const <int>[2, 3, 3, 3],
          low,
          high,
          60,
          _rirFor(const <double>[3, 2.5, 2, 2], i),
          maxSets: 4,
        );
      }
      if (e.unit == MeasureUnit.distance) {
        return distance(
          SchemeKind.carry,
          const <int>[2, 3, 3, 3],
          20,
          1,
          60,
          maxSets: 4,
          rir: _rirFor(const <double>[3, 2.5, 2, 2], i),
        );
      }
      final (low, high) = loaded ? (10, 15) : bodyweightRange();
      return reps(
        SchemeKind.coreReps,
        const <int>[2, 3, 3, 3],
        low,
        high,
        60,
        _rirFor(const <double>[3, 2.5, 2, 2], i),
        maxSets: 4,
      );
    case SlotKind.compound:
    case SlotKind.accessory:
      break;
  }

  final compound = t.kind == SlotKind.compound;
  if (e.unit == MeasureUnit.seconds) {
    final (low, high) = holdRange(20, 40, 5, 12);
    return hold(
      compound ? SchemeKind.skillHold : SchemeKind.coreHold,
      const <int>[2, 3, 3, 3],
      low,
      high,
      compound ? 120 : 60,
      _rirFor(const <double>[3, 2.5, 2, 2], i),
      maxSets: 4,
    );
  }
  if (e.unit == MeasureUnit.distance) {
    return distance(
      SchemeKind.carry,
      const <int>[2, 3, 3, 4],
      e.pattern == MovementPattern.fente ? 20 : 30,
      e.pattern == MovementPattern.fente ? 0.7 : 1,
      90,
      maxSets: 5,
      rir: _rirFor(const <double>[3, 2.5, 2, 2], i),
    );
  }
  if (e.unit == MeasureUnit.calories) {
    return reps(
      SchemeKind.hypertrophyIsolation,
      const <int>[2, 3, 3, 3],
      10,
      15,
      75,
      _rirFor(const <double>[3, 2, 1.5, 1.5], i),
    );
  }
  if (!loaded) {
    final (low, high) = bodyweightRange();
    return reps(
      SchemeKind.bodyweightReps,
      compound ? const <int>[3, 3, 4, 4] : const <int>[2, 3, 3, 3],
      low,
      high,
      compound ? 90 : 75,
      _rirFor(const <double>[3, 2, 2, 2], i),
    );
  }
  if (compound && i.goalLift) {
    final novice = i.level <= 0;
    return reps(
      SchemeKind.strengthMain,
      const <int>[3, 4, 5, 5],
      novice ? 5 : 3,
      novice ? 8 : 6,
      novice ? 150 : 180,
      _rirFor(const <double>[3, 2.5, 2, 2], i),
      ramp: 150,
    );
  }
  if (compound && i.strengthFocus) {
    final novice = i.level <= 0;
    return reps(
      SchemeKind.strengthAssist,
      const <int>[3, 3, 4, 4],
      novice ? 6 : 5,
      novice ? 10 : 8,
      150,
      _rirFor(const <double>[3, 2.5, 2, 2], i),
      ramp: 90,
    );
  }
  if (compound) {
    final novice = i.level <= 0;
    return reps(
      SchemeKind.hypertrophyCompound,
      const <int>[3, 3, 4, 4],
      novice ? 8 : 6,
      novice ? 12 : 10,
      120,
      _rirFor(const <double>[3, 2, 2, 1.5], i),
      ramp: 60,
    );
  }
  return reps(
    SchemeKind.hypertrophyIsolation,
    const <int>[2, 3, 3, 3],
    10,
    15,
    75,
    _rirFor(const <double>[3, 2, 1.5, 1], i),
    maxSets: 5,
  );
}
