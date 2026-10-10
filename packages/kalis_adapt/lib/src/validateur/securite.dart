// Critères de sécurité du banc, copiés pour l'application (lot KM2).
//
// Copie fidèle, le 2026-10-10, de `kalis_bench` 0.3.1 :
// - `lib/src/safety.dart` (`safetyFindings`, `Finding`, `SafetyLimits`,
//   `techniqueMinLevel`, `techniqueExerciseMinLevel`, `isHighRisk`,
//   `isModerateRisk`, `heavyImpactPatterns`, `rampLimit`, `benchStartYear`) ;
// - `lib/src/analysis.dart` (lecture `ProgramView` : `ItemView`, `DayView`,
//   `WeekView`, `StraightArmFamily`, `runSpeedOf`, `muscleLabel`,
//   `jointLabel` et leurs constantes), réduite à ce que lisent les critères.
//
// Même code, mêmes constantes, mêmes arrondis, même ordre des constats ;
// seuls changent les noms publics (en français) et le profil lu
// (`ProfilValidation` à la place de `BenchProfile` et du profil des
// moteurs). `kalis_bench` n'est pas modifié : son test
// `km2_validateur_test.dart` vérifie que les deux donnent les mêmes
// constats. Toute évolution de `safety.dart` ou de `analysis.dart` doit
// être reportée ici.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart'
    show CatalogTraits, ExerciseTraits, MuscleGroup;

import 'profil.dart';

/// Constat d'un critère de sécurité (`Finding` du banc).
final class ConstatSecurite {
  /// Violation du critère [code].
  const ConstatSecurite({
    required this.code,
    required this.message,
    this.week,
    this.dayIndex,
    this.exerciseId,
    this.value,
    this.limit,
  });

  /// Code du critère ([criteresSecurite]).
  final String code;

  /// Constat, en français.
  final String message;

  /// Semaine concernée (rang global), ou `null`.
  final int? week;

  /// Jour concerné, ou `null`.
  final int? dayIndex;

  /// Exercice concerné, ou `null`.
  final String? exerciseId;

  /// Valeur mesurée.
  final double? value;

  /// Seuil.
  final double? limit;

  /// Objet JSON du constat (`Finding.toJson` du banc).
  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'message': message,
    if (week != null) 'week': week,
    if (dayIndex != null) 'dayIndex': dayIndex,
    if (exerciseId != null) 'exerciseId': exerciseId,
    if (value != null) 'value': _round(value!),
    if (limit != null) 'limit': _round(limit!),
  };
}

double _round(double v) => (v * 1000).roundToDouble() / 1000;

/// Critères de sécurité : code → intitulé (`safetyCriteria`).
const Map<String, String> criteresSecurite = <String, String>{
  'charge_trop_vite': 'Hausse de charge trop rapide',
  'volume_trop_vite': 'Hausse de volume trop rapide',
  'plafond_volume': 'Volume hebdomadaire au-dessus du plafond du niveau',
  'technique_sans_prerequis': 'Technique avancée sans ses prérequis',
  'exercice_trop_avance': 'Exercice au-dessus du niveau du profil',
  'exercice_non_acquis': "Exercice dont un palier n'est pas acquis",
  'contre_indication': 'Exercice contre-indiqué par une gêne déclarée',
  'tendon_figures': 'Montée trop rapide de la charge bras tendus',
  'levier_trop_tot': 'Passage au levier suivant trop tôt',
  'echec_risque': "Échec ou quasi-échec sur un mouvement à risque",
  'seance_trop_longue': 'Séance plus longue que le temps donné',
  'decharge_absente': 'Trop de semaines de charge sans allègement',
  'affutage_absent': "Pas d'allègement avant l'échéance",
  'reprise_trop_dure': 'Reprise après coupure sans progressivité',
  'impact_deconseille': 'Impact ou explosif déconseillé pour ce profil',
};

/// Nom français des niveaux (`BenchLevel.label`), par indice de
/// `ExperienceLevel`.
const List<String> _levelLabels = <String>[
  'débutant',
  'intermédiaire',
  'avancé',
  'élite',
];

/// Seuils de sécurité par niveau (indice : `ExperienceLevel.index`),
/// ceux de `SafetyLimits` du banc (références au référentiel dans
/// `kalis_bench/lib/src/safety.dart`).
abstract final class LimitesSecurite {
  /// Hausse maximale de la charge totale d'un exercice d'une semaine à
  /// l'autre, à schéma de répétitions égal (R5-P3, R5-P22).
  static const List<double> loadRise = <double>[0.10, 0.05, 0.05, 0.05];

  /// Hausse relative maximale des séries dures d'un groupe musculaire par
  /// rapport au plus haut des trois semaines précédentes (R5-P22)…
  static const double volumeRise = 0.20;

  /// … ou deux séries, si c'est plus.
  static const double volumeRiseSets = 2;

  /// Hausse relative maximale sur deux semaines de charge consécutives
  /// (R5-P22)…
  static const double volumeRiseTwoWeeks = 0.30;

  /// … ou quatre séries, si c'est plus.
  static const double volumeRiseTwoWeeksSets = 4;

  /// Part de la pleine charge à laquelle démarre une semaine allégée ou
  /// de reprise (R5-P7, R5-P22).
  static const double rampShare = 0.5;

  /// Plafond de séries dures fractionnées par groupe et par semaine
  /// (R1-P1).
  static const List<double> weeklyCeiling = <double>[12, 20, 25, 30];

  /// Nombre de groupes qu'un profil élite peut porter au-dessus du plafond
  /// du niveau avancé (R1-P1).
  static const int eliteGroupsAboveAdvanced = 2;

  /// Séances bras tendus par famille et par semaine (R4-F10).
  static const List<int> straightArmDays = <int>[2, 3, 3, 4];

  /// Hausse relative maximale des secondes de tenue bras tendus d'une
  /// famille par rapport au plus haut des trois semaines précédentes
  /// (R5-P22)…
  static const List<double> straightArmRise = <double>[0.20, 0.15, 0.10, 0.10];

  /// … ou cinq secondes, si c'est plus.
  static const double straightArmRiseSeconds = 5;

  /// Semaines minimales sur un levier avant le suivant (R4-F9).
  static const List<int> leverWeeks = <int>[12, 8, 8, 6];

  /// Plus longue suite de semaines de charge sans allègement (R3-P9).
  static const List<int> weeksWithoutRelief = <int>[12, 7, 6, 6];

  /// Part du plus haut volume récent sous laquelle une semaine compte
  /// comme allégée (R3-P9).
  static const double reliefShare = 0.70;

  /// Baisse minimale du volume la semaine de l'échéance, par rapport au
  /// pic des six semaines précédentes (R3-P12, R3-P21).
  static const List<double> taperDrop = <double>[0.30, 0.30, 0.40, 0.40];

  /// Tolérance sur la durée d'une séance : 15 % plus 3 minutes.
  static const double sessionTolerance = 0.15;

  /// Semaines de coupure à partir desquelles la reprise est progressive
  /// (R5-P7).
  static const int breakWeeks = 2;

  /// RIR minimal de la première semaine après une coupure (R5-P7).
  static const double resumeMinRir = 3;

  /// Gêne à partir de laquelle une contrainte forte est contre-indiquée
  /// (R5-P23).
  static const int discomfortHigh = 4;

  /// Gêne à partir de laquelle une contrainte modérée l'est aussi
  /// (R5-P23, R4-F11).
  static const int discomfortModerate = 6;

  /// RIR minimal sur un mouvement à risque élevé, à tout niveau (R5-P27).
  static const double highRiskMinRir = 2;

  /// Indice de masse corporelle à partir duquel sauts et pliométrie sont
  /// écartés chez le débutant (R5-P9).
  static const double impactBmi = 30;

  /// Âge à partir duquel l'impact est écarté (programme prudent).
  static const int impactAge = 65;
}

/// Niveau minimal (indice de `ExperienceLevel`) de chaque technique
/// d'intensification (`techniqueMinLevel` du banc).
const Map<String, int> niveauMinimalTechnique = <String, int>{
  'top_set_backoff': 1,
  'drop_set': 1,
  'amrap': 1,
  'cluster': 2,
  'rest_pause': 2,
  'myo_reps': 2,
  'accentuated_eccentric': 2,
  'contrast': 2,
  'wave': 2,
};

/// Fragments d'identifiant des exercices qui sont par nature une technique
/// avancée, et leur niveau minimal (`techniqueExerciseMinLevel` du banc).
const Map<String, int> niveauMinimalExerciceTechnique = <String, int>{
  'supramaximal': 2,
  'partielle-haute': 2,
  'partiel-haut': 2,
  'partiel-surcharge': 2,
  'isometrie-lestee': 2,
  'chaines': 1,
};

int _levelIndexOf(ExerciseLevel level) => level.index;

/// Vrai si un échec sur [e] expose à une chute, une tête en bas ou une
/// articulation en fin d'amplitude (R5-P27, risque élevé ; `isHighRisk`).
bool risqueEleve(CatalogExercise e) {
  switch (e.pattern) {
    case MovementPattern.equilibreMains:
    case MovementPattern.transitionMuscleUp:
    case MovementPattern.figureStatiquePoussee:
    case MovementPattern.figureStatiqueTirage:
    case MovementPattern.figureStatiqueMixte:
    case MovementPattern.figureDynamiquePoussee:
    case MovementPattern.figureDynamiqueTirage:
    case MovementPattern.freestyle:
    case MovementPattern.halterophilie:
      return true;
    default:
      break;
  }
  if (e.equipment.contains('anneaux') && e.family == MovementFamily.poussee) {
    return true;
  }
  return e.loadType == LoadType.barbell &&
      (e.pattern == MovementPattern.squat ||
          e.pattern == MovementPattern.pousseeHorizontale ||
          e.pattern == MovementPattern.pousseeInclinee);
}

/// Vrai si un échec sur [e] est à risque modéré (R5-P27 ;
/// `isModerateRisk`).
bool risqueModere(CatalogExercise e) {
  if (risqueEleve(e)) {
    return false;
  }
  return e.pattern == MovementPattern.tirageVertical ||
      e.pattern == MovementPattern.pousseeVerticaleBasse ||
      e.loadType == LoadType.addedWeight ||
      (e.loadType == LoadType.barbell &&
          e.articularity == Articularity.multiJoint);
}

/// Schémas écartés chez le débutant dont l'indice de masse corporelle
/// atteint [LimitesSecurite.impactBmi] (R5-P9 ; `heavyImpactPatterns`).
const Set<MovementPattern> schemasImpactLourd = <MovementPattern>{
  MovementPattern.pliometrie,
  MovementPattern.cordeASauter,
  MovementPattern.balistique,
  MovementPattern.halterophilie,
};

// ---------------------------------------------------------------------------
// Lecture du programme (`analysis.dart` du banc)
// ---------------------------------------------------------------------------

/// Poids de corps pris quand le profil ne le donne pas, en kg
/// (`defaultBodyWeightKg`).
const double poidsCorpsParDefautKg = 75;

const double _secondsPerRep = 3;
const double _transitionSeconds = 45;
const double _defaultRunMetersPerSecond = 2.5;
const double _trainingPaceShare = 0.9;
const double _hardSetMaxRir = 4;

/// Allure de course du profil (`runSpeedOf`).
double _runSpeedOf(ProfilValidation profile) {
  var best = 0.0;
  for (final r in profile.records) {
    final meters = r.distanceMetres;
    if (r.mesure == LevelMeasure.timeSeconds &&
        meters != null &&
        r.valeur > 0) {
      final speed = meters / r.valeur;
      if (speed > best) {
        best = speed;
      }
    }
  }
  return best > 0 ? best * _trainingPaceShare : _defaultRunMetersPerSecond;
}

String _muscleLabel(MuscleGroup g) => switch (g) {
  MuscleGroup.chest => 'pectoraux',
  MuscleGroup.deltAnterior => 'deltoïde antérieur',
  MuscleGroup.deltMiddle => 'deltoïde moyen',
  MuscleGroup.deltPosterior => 'deltoïde postérieur',
  MuscleGroup.lats => 'grand dorsal',
  MuscleGroup.upperBack => 'haut du dos',
  MuscleGroup.biceps => 'biceps',
  MuscleGroup.triceps => 'triceps',
  MuscleGroup.abs => 'abdominaux',
  MuscleGroup.lowerBack => 'lombaires',
  MuscleGroup.glutes => 'fessiers',
  MuscleGroup.quads => 'quadriceps',
  MuscleGroup.hamstrings => 'ischio-jambiers',
  MuscleGroup.calves => 'mollets',
  MuscleGroup.forearms => 'avant-bras',
  MuscleGroup.adductors => 'adducteurs',
  MuscleGroup.upperTraps => 'trapèzes supérieurs',
};

String _jointLabel(Joint j) => switch (j) {
  Joint.shoulder => 'épaule',
  Joint.elbow => 'coude',
  Joint.wrist => 'poignet',
  Joint.lumbar => 'lombaires',
  Joint.knee => 'genou',
  Joint.hip => 'hanche',
  Joint.ankle => 'cheville',
};

enum _StraightArmFamily {
  push,
  pull,
  mixed;

  String get label => switch (this) {
    _StraightArmFamily.push => 'poussée, type planche et back lever',
    _StraightArmFamily.pull => 'tirage, type front lever',
    _StraightArmFamily.mixed => 'mixtes, type drapeau',
  };
}

final class _ItemView {
  _ItemView({
    required this.dayIndex,
    required this.p,
    required this.exercise,
    required this.traits,
    required this.bodyWeightKg,
    required this.runMetersPerSecond,
  });

  final double runMetersPerSecond;
  final int dayIndex;
  final ExercisePrescription p;
  final CatalogExercise exercise;
  final ExerciseTraits traits;
  final double bodyWeightKg;

  bool get isTimed => p.secondsLow != null || p.secondsHigh != null;

  bool get isReps => p.repsLow != null || p.repsHigh != null;

  int get repsHigh => p.repsHigh ?? p.repsLow ?? 0;

  int get secondsHigh => p.secondsHigh ?? p.secondsLow ?? 0;

  double? get rir {
    final flames = p.targetFlames;
    return flames == null ? null : Flames.toRir(flames);
  }

  bool get isResistance => traits.kind.isResistance;

  Set<String> get techniqueCodes {
    final format = p.format;
    final technique = p.technique;
    return <String>{
      if (format != null) format,
      if (technique != null && technique.kind != SetTechniqueKind.standard)
        technique.kind.code,
    };
  }

  bool get isTest => p.kind == SetKind.test;

  bool get isWarmup => p.kind == SetKind.warmup;

  double get hardSets {
    if (!isResistance || isWarmup) {
      return 0;
    }
    final r = rir;
    if (r != null && r > _hardSetMaxRir) {
      return 0;
    }
    return p.sets.toDouble();
  }

  double creditedSets(MuscleGroup group) =>
      hardSets * traits.creditOf(group) / 2;

  double get bodyFraction => exercise.bodyweightFraction?.value ?? 0;

  double? get totalLoadKg {
    final load = p.startLoadKg;
    if (load == null) {
      return null;
    }
    return load + bodyFraction * bodyWeightKg;
  }

  _StraightArmFamily? get straightArm {
    if (exercise.rootId.startsWith('cs-back-lever') ||
        exercise.id.startsWith('cs-back-lever')) {
      return _StraightArmFamily.push;
    }
    if (exercise.rootId.startsWith('cs-tenue-menton') ||
        exercise.id.startsWith('cs-tenue-menton')) {
      return null;
    }
    switch (exercise.pattern) {
      case MovementPattern.figureStatiquePoussee:
        return _StraightArmFamily.push;
      case MovementPattern.figureStatiqueTirage:
        return _StraightArmFamily.pull;
      case MovementPattern.figureStatiqueMixte:
        return _StraightArmFamily.mixed;
      default:
        return null;
    }
  }

  double get holdSeconds =>
      isTimed && isResistance ? p.sets * secondsHigh.toDouble() : 0;

  double get estimatedSeconds {
    final sides = exercise.laterality == Laterality.bilateral ? 1 : 2;
    double effort;
    if (isReps) {
      effort = repsHigh * _secondsPerRep * sides;
    } else if (isTimed) {
      effort = secondsHigh.toDouble() * (isResistance ? sides : 1);
    } else if (p.distanceMeters != null) {
      effort = p.distanceMeters! / runMetersPerSecond;
    } else if (p.calories != null) {
      effort = p.calories! * 6;
    } else {
      effort = 30;
    }
    final rest = (p.restSeconds ?? 60).toDouble();
    return _transitionSeconds + p.sets * effort + (p.sets - 1) * rest;
  }
}

final class _DayView {
  _DayView({
    required this.dayIndex,
    required this.minutesBudget,
    required this.items,
  });

  final int dayIndex;
  final int minutesBudget;
  final List<_ItemView> items;

  double get estimatedMinutes {
    var seconds = 0.0;
    var resistance = false;
    for (final i in items) {
      seconds += i.estimatedSeconds;
      resistance = resistance || i.isResistance;
    }
    return (seconds + (resistance ? 300 : 0)) / 60;
  }
}

final class _WeekView {
  _WeekView({required this.index, required this.kind, required this.days});

  final int index;
  final WeekKind kind;
  final List<_DayView> days;

  Iterable<_ItemView> get items sync* {
    for (final d in days) {
      yield* d.items;
    }
  }

  double get hardSets {
    var total = 0.0;
    for (final i in items) {
      total += i.hardSets;
    }
    return total;
  }

  double groupSets(MuscleGroup group) {
    var total = 0.0;
    for (final i in items) {
      total += i.creditedSets(group);
    }
    return total;
  }

  double get conditioningMinutes {
    var seconds = 0.0;
    for (final i in items) {
      if (!i.isResistance) {
        seconds += i.estimatedSeconds;
      }
    }
    return seconds / 60;
  }

  double straightArmSeconds(_StraightArmFamily family) {
    var total = 0.0;
    for (final i in items) {
      if (i.straightArm == family) {
        total += i.holdSeconds;
      }
    }
    return total;
  }

  int straightArmDays(_StraightArmFamily family) {
    var count = 0;
    for (final d in days) {
      if (d.items.any((i) => i.straightArm == family)) {
        count++;
      }
    }
    return count;
  }

  bool get isLight =>
      kind == WeekKind.intro ||
      kind == WeekKind.deload ||
      kind == WeekKind.test;
}

/// Semaines des blocs [blocks] jusqu'à [horizonWeeks] (`ProgramView._read`).
List<_WeekView> _read(
  Catalog catalog,
  List<ProgramBlock> blocks,
  int horizonWeeks,
  ProfilValidation profile,
) {
  final traits = CatalogTraits.of(catalog);
  final bodyWeight = profile.poidsCorpsKg ?? poidsCorpsParDefautKg;
  final runSpeed = _runSpeedOf(profile);
  final out = <_WeekView>[];
  var global = 0;
  for (var b = 0; b < blocks.length; b++) {
    final block = blocks[b];
    for (final week in block.pass2.weeks) {
      if (global >= horizonWeeks) {
        return out;
      }
      final days = <_DayView>[];
      for (final day in week.days) {
        final base = block.pass1.days[day.dayIndex];
        days.add(
          _DayView(
            dayIndex: day.dayIndex,
            minutesBudget: base.minutesBudget,
            items: <_ItemView>[
              for (final item in day.items)
                _ItemView(
                  dayIndex: day.dayIndex,
                  p: item,
                  exercise: catalog.exercise(item.exerciseId),
                  traits: traits.of(item.exerciseId),
                  bodyWeightKg: bodyWeight,
                  runMetersPerSecond: runSpeed,
                ),
            ],
          ),
        );
      }
      out.add(_WeekView(index: global, kind: week.kind, days: days));
      global++;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Critères (`safety.dart` du banc)
// ---------------------------------------------------------------------------

double _rampLimit(
  List<_WeekView> weeks,
  List<double> series,
  int index, {
  required double rise,
  required double tolerance,
}) {
  var loaded = 0.0;
  var light = 0.0;
  var anyLoaded = false;
  for (var k = index - 3; k < index; k++) {
    if (k < 0) {
      continue;
    }
    if (weeks[k].isLight) {
      if (series[k] > light) {
        light = series[k];
      }
    } else {
      anyLoaded = true;
      if (series[k] > loaded) {
        loaded = series[k];
      }
    }
  }
  if (anyLoaded) {
    final reference = loaded > light ? loaded : light;
    return _stepLimit(reference, rise, tolerance);
  }
  final stepped = _stepLimit(light, rise, tolerance);
  final resumed = light / LimitesSecurite.rampShare;
  return stepped > resumed ? stepped : resumed;
}

double _stepLimit(double reference, double rise, double tolerance) {
  final relative = reference * (1 + rise);
  final absolute = reference + tolerance;
  return relative > absolute ? relative : absolute;
}

/// Constats de sécurité des blocs [blocs] (déjà réduits à leurs semaines
/// servies, voir `blocsServis`), lus jusqu'à [horizonSemaines] semaines,
/// pour le profil [profil] : ceux de `safetyFindings` du banc sur la même
/// vue, dans le même ordre.
List<ConstatSecurite> constatsSecurite({
  required Catalog catalog,
  required ProfilValidation profil,
  required List<ProgramBlock> blocs,
  required int horizonSemaines,
}) {
  final profile = profil;
  final out = <ConstatSecurite>[];
  final level = profile.niveau.index;
  final levelLabel = _levelLabels[level];
  final weeks = _read(catalog, blocs, horizonSemaines, profile);

  // --- Hausse de charge d'une semaine à l'autre.
  final lastLoad = <String, (int, double, int)>{};
  for (final w in weeks) {
    for (final i in w.items) {
      final total = i.totalLoadKg;
      if (total == null || total <= 0 || i.isTest) {
        continue;
      }
      final key = '${i.dayIndex}|${i.p.slotId}|${i.exercise.id}';
      final before = lastLoad[key];
      if (before != null &&
          before.$1 == w.index - 1 &&
          before.$3 == i.repsHigh) {
        final rise = total / before.$2 - 1;
        final limit = LimitesSecurite.loadRise[level];
        if (rise > limit + 1e-9) {
          out.add(
            ConstatSecurite(
              code: 'charge_trop_vite',
              message:
                  '${i.exercise.name} : charge totale '
                  '+${(rise * 100).toStringAsFixed(1)} % en une semaine '
                  '(seuil ${(limit * 100).toStringAsFixed(1)} %).',
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: i.exercise.id,
              value: rise,
              limit: limit,
            ),
          );
        }
      }
      lastLoad[key] = (w.index, total, i.repsHigh);
    }
  }

  // --- Volume par groupe : hausse et plafond.
  final ceiling = LimitesSecurite.weeklyCeiling[level];
  for (final g in MuscleGroup.values) {
    if (!g.major) {
      continue;
    }
    final series = <double>[for (final w in weeks) w.groupSets(g)];
    var above = 0;
    var highest = 0.0;
    int? firstAbove;
    for (final w in weeks) {
      final sets = series[w.index];
      if (w.index > 0) {
        final limit = _rampLimit(
          weeks,
          series,
          w.index,
          rise: LimitesSecurite.volumeRise,
          tolerance: LimitesSecurite.volumeRiseSets,
        );
        if (sets > limit + 1e-9) {
          out.add(
            ConstatSecurite(
              code: 'volume_trop_vite',
              message:
                  '${_muscleLabel(g)} : ${sets.toStringAsFixed(1)} séries '
                  'dures en semaine ${w.index + 1}, pour '
                  '${limit.toStringAsFixed(1)} admises au vu des trois '
                  'semaines précédentes.',
              week: w.index,
              value: sets,
              limit: limit,
            ),
          );
        } else if (w.index > 1 &&
            !w.isLight &&
            !weeks[w.index - 1].isLight &&
            !weeks[w.index - 2].isLight) {
          final twoWeeks = _stepLimit(
            series[w.index - 2],
            LimitesSecurite.volumeRiseTwoWeeks,
            LimitesSecurite.volumeRiseTwoWeeksSets,
          );
          if (series[w.index - 2] > 0 && sets > twoWeeks + 1e-9) {
            out.add(
              ConstatSecurite(
                code: 'volume_trop_vite',
                message:
                    '${_muscleLabel(g)} : ${sets.toStringAsFixed(1)} séries '
                    'dures en semaine ${w.index + 1}, pour '
                    '${twoWeeks.toStringAsFixed(1)} admises au vu de la '
                    'semaine ${w.index - 1} (hausse sur deux semaines).',
                week: w.index,
                value: sets,
                limit: twoWeeks,
              ),
            );
          }
        }
      }
      if (sets > ceiling + 1e-9) {
        above++;
        firstAbove ??= w.index;
        if (sets > highest) {
          highest = sets;
        }
      }
    }
    if (above > 0) {
      out.add(
        ConstatSecurite(
          code: 'plafond_volume',
          message:
              '${_muscleLabel(g)} : $above semaine(s) au-dessus du plafond '
              'du niveau $levelLabel (${ceiling.toStringAsFixed(0)} séries '
              'dures), jusqu\'à ${highest.toStringAsFixed(1)}.',
          week: firstAbove,
          value: highest,
          limit: ceiling,
        ),
      );
    }
  }
  if (profile.niveau == ExperienceLevel.elite) {
    final advanced =
        LimitesSecurite.weeklyCeiling[ExperienceLevel.advanced.index];
    for (final w in weeks) {
      var above = 0;
      for (final g in MuscleGroup.values) {
        if (g.major && w.groupSets(g) > advanced + 1e-9) {
          above++;
        }
      }
      if (above > LimitesSecurite.eliteGroupsAboveAdvanced) {
        out.add(
          ConstatSecurite(
            code: 'plafond_volume',
            message:
                '$above groupes au-dessus de '
                '${advanced.toStringAsFixed(0)} séries dures en semaine '
                '${w.index + 1} (au plus '
                '${LimitesSecurite.eliteGroupsAboveAdvanced} en élite).',
            week: w.index,
            value: above.toDouble(),
            limit: LimitesSecurite.eliteGroupsAboveAdvanced.toDouble(),
          ),
        );
      }
    }
  }

  // --- Techniques, niveau des exercices, paliers non acquis.
  final known = <String>{
    for (final r in profile.records)
      if (r.valeur > 0) r.exerciseId,
    for (final id in profile.exercicesConnus) id,
  };
  final notAcquired = <CatalogExercise>[
    for (final r in profile.records)
      if (r.valeur <= 0 && catalog.contains(r.exerciseId))
        catalog.exercise(r.exerciseId),
    for (final id in profile.exercicesNonAcquis)
      if (catalog.contains(id)) catalog.exercise(id),
  ];
  final seenExercise = <String>{};
  for (final w in weeks) {
    for (final i in w.items) {
      final e = i.exercise;
      for (final code in i.techniqueCodes) {
        final need = niveauMinimalTechnique[code];
        if (need != null && level < need) {
          out.add(
            ConstatSecurite(
              code: 'technique_sans_prerequis',
              message:
                  '${e.name} : technique « $code » réservée au niveau '
                  '${_levelLabels[need]} et au-delà.',
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: e.id,
            ),
          );
        }
      }
      if (!seenExercise.add(e.id)) {
        continue;
      }
      for (final entry in niveauMinimalExerciceTechnique.entries) {
        if (e.id.contains(entry.key) && level < entry.value) {
          out.add(
            ConstatSecurite(
              code: 'technique_sans_prerequis',
              message:
                  '${e.name} : technique réservée au niveau '
                  '${_levelLabels[entry.value]} et au-delà.',
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: e.id,
            ),
          );
        }
      }
      if (i.isResistance &&
          !known.contains(e.id) &&
          _levelIndexOf(e.level) > level + 1) {
        out.add(
          ConstatSecurite(
            code: 'exercice_trop_avance',
            message:
                '${e.name} (niveau ${e.level.code} de la base) pour un '
                'profil $levelLabel.',
            week: w.index,
            dayIndex: i.dayIndex,
            exerciseId: e.id,
          ),
        );
      }
      for (final missing in notAcquired) {
        final harderInChain =
            e.rootId == missing.rootId &&
            !e.assisted &&
            e.difficulty >= missing.difficulty;
        if (e.id == missing.id ||
            harderInChain ||
            e.prerequisites.contains(missing.id)) {
          out.add(
            ConstatSecurite(
              code: 'exercice_non_acquis',
              message:
                  "${e.name} : demande ${missing.name}, que le profil "
                  "n'a pas acquis.",
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: e.id,
            ),
          );
          break;
        }
      }
    }
  }

  // --- Contre-indications par articulation.
  for (final injury in profile.genes) {
    final joint = injury.articulationCatalogue;
    if (joint == null) {
      continue;
    }
    final recent = injury.recente;
    final flagged = <String>{};
    for (final w in weeks) {
      for (final i in w.items) {
        final stress = i.exercise.stressOn(joint);
        var bad = false;
        var why = '';
        if (stress == JointStress.high &&
            injury.gene >= LimitesSecurite.discomfortHigh) {
          bad = true;
          why = 'contrainte forte';
        } else if (stress == JointStress.moderate &&
            injury.gene >= LimitesSecurite.discomfortModerate) {
          bad = true;
          why = 'contrainte modérée';
        } else if (stress == JointStress.high &&
            (recent || injury.gene >= 2) &&
            i.isResistance &&
            !i.isTest &&
            (i.rir ?? 5) < 1) {
          bad = true;
          why = "contrainte forte menée à l'échec";
        }
        if (bad && flagged.add(i.exercise.id)) {
          out.add(
            ConstatSecurite(
              code: 'contre_indication',
              message:
                  '${i.exercise.name} : $why sur ${_jointLabel(joint)} '
                  '(${injury.libelle}, gêne ${injury.gene}/10).',
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: i.exercise.id,
            ),
          );
        }
      }
    }
  }

  // --- Tenues bras tendus : fréquence, hausse, passage de levier.
  for (final family in _StraightArmFamily.values) {
    for (final w in weeks) {
      final days = w.straightArmDays(family);
      final maxDays = LimitesSecurite.straightArmDays[level];
      if (days > maxDays) {
        out.add(
          ConstatSecurite(
            code: 'tendon_figures',
            message:
                'Tenues bras tendus (${family.label}) $days jours en '
                'semaine ${w.index + 1} (au plus $maxDays au niveau '
                '$levelLabel).',
            week: w.index,
            value: days.toDouble(),
            limit: maxDays.toDouble(),
          ),
        );
      }
      if (w.index == 0) {
        continue;
      }
      final held = <double>[
        for (final x in weeks) x.straightArmSeconds(family),
      ];
      var reference = 0.0;
      for (var k = w.index - 3; k < w.index; k++) {
        if (k >= 0 && held[k] > reference) {
          reference = held[k];
        }
      }
      final seconds = held[w.index];
      final limit = _rampLimit(
        weeks,
        held,
        w.index,
        rise: LimitesSecurite.straightArmRise[level],
        tolerance: LimitesSecurite.straightArmRiseSeconds,
      );
      if (reference > 0 && seconds > limit + 1e-9) {
        out.add(
          ConstatSecurite(
            code: 'tendon_figures',
            message:
                'Tenues bras tendus (${family.label}) : '
                '${seconds.round()} s en semaine ${w.index + 1}, pour '
                '${limit.round()} s admises au vu des trois semaines '
                'précédentes.',
            week: w.index,
            value: seconds,
            limit: limit,
          ),
        );
      }
    }
  }
  final firstWeek = <String, int>{};
  final chain = <String, List<CatalogExercise>>{};
  for (final w in weeks) {
    for (final i in w.items) {
      if (i.straightArm == null) {
        continue;
      }
      if (!firstWeek.containsKey(i.exercise.id)) {
        firstWeek[i.exercise.id] = w.index;
        chain
            .putIfAbsent(i.exercise.rootId, () => <CatalogExercise>[])
            .add(i.exercise);
      }
    }
  }
  final minWeeks = LimitesSecurite.leverWeeks[level];
  for (final levers in chain.values) {
    for (final later in levers) {
      for (final earlier in levers) {
        final gap = firstWeek[later.id]! - firstWeek[earlier.id]!;
        if (later.difficulty > earlier.difficulty &&
            gap > 0 &&
            gap < minWeeks &&
            !known.contains(later.id)) {
          out.add(
            ConstatSecurite(
              code: 'levier_trop_tot',
              message:
                  '${later.name} arrive $gap semaines après '
                  '${earlier.name} (au moins $minWeeks au niveau '
                  '$levelLabel).',
              week: firstWeek[later.id],
              exerciseId: later.id,
              value: gap.toDouble(),
              limit: minWeeks.toDouble(),
            ),
          );
        }
      }
    }
  }

  // --- Échec et quasi-échec sur mouvements à risque.
  for (final w in weeks) {
    var beginnerNearFailure = 0;
    for (final i in w.items) {
      if (!i.isResistance || i.isTest || i.isWarmup) {
        continue;
      }
      final r = i.rir;
      if (r == null) {
        continue;
      }
      if (r < LimitesSecurite.highRiskMinRir - 1e-9 &&
          risqueEleve(i.exercise)) {
        out.add(
          ConstatSecurite(
            code: 'echec_risque',
            message:
                '${i.exercise.name} : ${r.toStringAsFixed(1)} répétition(s) '
                'en réserve sur un mouvement à risque élevé (au moins 2 '
                'attendues).',
            week: w.index,
            dayIndex: i.dayIndex,
            exerciseId: i.exercise.id,
            value: r,
            limit: LimitesSecurite.highRiskMinRir,
          ),
        );
      } else if (profile.niveau == ExperienceLevel.beginner && r <= 0) {
        out.add(
          ConstatSecurite(
            code: 'echec_risque',
            message:
                "${i.exercise.name} : série prescrite à l'échec pour un "
                'débutant.',
            week: w.index,
            dayIndex: i.dayIndex,
            exerciseId: i.exercise.id,
            value: r,
            limit: 1,
          ),
        );
      }
      if (profile.niveau == ExperienceLevel.beginner &&
          r <= 1 &&
          (risqueEleve(i.exercise) || risqueModere(i.exercise))) {
        beginnerNearFailure += i.p.sets;
      }
    }
    if (beginnerNearFailure >= 2) {
      out.add(
        ConstatSecurite(
          code: 'echec_risque',
          message:
              '$beginnerNearFailure séries à 1 RIR ou moins sur des '
              'mouvements à risque en semaine ${w.index + 1}, pour un '
              'débutant.',
          week: w.index,
          value: beginnerNearFailure.toDouble(),
          limit: 1,
        ),
      );
    }
  }

  // --- Durée des séances.
  for (final w in weeks) {
    for (final d in w.days) {
      final minutes = d.estimatedMinutes;
      final limit =
          d.minutesBudget * (1 + LimitesSecurite.sessionTolerance) + 3;
      // Jour d'une course d'épreuve : sa durée est celle de la course
      // choisie, pas un choix du programme (CP2, partie 1).
      final eventDay = d.items.any(
        (i) =>
            i.p.kind == SetKind.test &&
            i.p.test?.kind == TestKind.timeTrial &&
            i.p.reasons.any((r) => r.params['note'] == 'event_day'),
      );
      if (minutes > limit && !eventDay) {
        out.add(
          ConstatSecurite(
            code: 'seance_trop_longue',
            message:
                'Semaine ${w.index + 1}, jour ${d.dayIndex + 1} : '
                '${minutes.round()} min estimées pour '
                '${d.minutesBudget} min disponibles.',
            week: w.index,
            dayIndex: d.dayIndex,
            value: minutes,
            limit: limit,
          ),
        );
      }
    }
  }

  // --- Allègements.
  var run = 0;
  var reported = false;
  for (final w in weeks) {
    var reference = 0.0;
    for (var k = w.index - 3; k < w.index; k++) {
      if (k >= 0 && weeks[k].hardSets > reference) {
        reference = weeks[k].hardSets;
      }
    }
    final relieved = reference > 0
        ? w.hardSets <= reference * LimitesSecurite.reliefShare + 1e-9
        : w.isLight;
    if (relieved) {
      run = 0;
      reported = false;
      continue;
    }
    run++;
    final limit = LimitesSecurite.weeksWithoutRelief[level];
    if (run > limit && !reported) {
      reported = true;
      out.add(
        ConstatSecurite(
          code: 'decharge_absente',
          message:
              '$run semaines de charge de suite sans allègement à la '
              'semaine ${w.index + 1} (au plus $limit au niveau '
              '$levelLabel).',
          week: w.index,
          value: run.toDouble(),
          limit: limit.toDouble(),
        ),
      );
    }
  }

  // --- Affûtage avant l'échéance prioritaire.
  final eventWeeksOut = profile.semainesEcheance;
  if (eventWeeksOut != null && weeks.isNotEmpty) {
    final at = eventWeeksOut - 1;
    if (at >= weeks.length) {
      out.add(
        ConstatSecurite(
          code: 'affutage_absent',
          message:
              "L'échéance (semaine $eventWeeksOut) est au-delà du "
              'programme généré (${weeks.length} semaines).',
        ),
      );
    } else if (at >= 2) {
      double volumeOf(_WeekView w, {required bool cardio}) =>
          cardio ? w.conditioningMinutes : w.hardSets;
      var cardio = true;
      for (var k = at - 6; k < at; k++) {
        if (k >= 0 && weeks[k].hardSets > 0) {
          cardio = false;
        }
      }
      var peak = 0.0;
      for (var k = at - 6; k < at; k++) {
        if (k >= 0 && volumeOf(weeks[k], cardio: cardio) > peak) {
          peak = volumeOf(weeks[k], cardio: cardio);
        }
      }
      final last = volumeOf(weeks[at], cardio: cardio);
      final drop = peak <= 0 ? 0.0 : 1 - last / peak;
      final need = LimitesSecurite.taperDrop[level];
      if (drop < need - 1e-9) {
        out.add(
          ConstatSecurite(
            code: 'affutage_absent',
            message:
                "Semaine de l'échéance : volume "
                '${(drop * 100).round()} % sous le pic des six semaines '
                'précédentes (au moins ${(need * 100).round()} % '
                'attendus).',
            week: at,
            value: drop,
            limit: need,
          ),
        );
      }
    }
  }

  // --- Reprise après coupure.
  if (profile.semainesPause >= LimitesSecurite.breakWeeks &&
      weeks.isNotEmpty) {
    final flagged = <String>{};
    for (final i in weeks.first.items) {
      if (!i.isResistance || i.isWarmup || i.isTest) {
        continue;
      }
      final r = i.rir;
      if (r != null &&
          r < LimitesSecurite.resumeMinRir &&
          flagged.add(i.exercise.id)) {
        out.add(
          ConstatSecurite(
            code: 'reprise_trop_dure',
            message:
                '${i.exercise.name} : RIR ${r.toStringAsFixed(1)} dès la '
                'première semaine après ${profile.semainesPause} semaines '
                "d'arrêt (au moins 3 attendus).",
            week: 0,
            dayIndex: i.dayIndex,
            exerciseId: i.exercise.id,
            value: r,
            limit: LimitesSecurite.resumeMinRir,
          ),
        );
      }
    }
  }

  // --- Impact.
  final age = profile.age;
  final cautious = profile.prudent;
  final bmi = profile.indiceMasseCorporelle;
  final heavyBeginner =
      profile.niveau == ExperienceLevel.beginner &&
      bmi != null &&
      bmi >= LimitesSecurite.impactBmi;
  if (age >= LimitesSecurite.impactAge || cautious || heavyBeginner) {
    final flagged = <String>{};
    for (final w in weeks) {
      for (final i in w.items) {
        final risky = (age >= LimitesSecurite.impactAge || cautious)
            ? i.traits.impact
            : schemasImpactLourd.contains(i.exercise.pattern);
        if (risky && flagged.add(i.exercise.id)) {
          out.add(
            ConstatSecurite(
              code: 'impact_deconseille',
              message:
                  '${i.exercise.name} : impact ou explosif, déconseillé '
                  'pour ce profil.',
              week: w.index,
              dayIndex: i.dayIndex,
              exerciseId: i.exercise.id,
            ),
          );
        }
      }
    }
  }
  return out;
}
