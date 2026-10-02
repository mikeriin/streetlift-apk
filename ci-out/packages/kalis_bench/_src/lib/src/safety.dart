/// Critères de sécurité (exigé : 0 violation). Chaque seuil renvoie au
/// principe du référentiel qui le fonde (`docs/REFERENTIEL.md`) ; ce qui
/// n'est qu'un choix raisonné est dit comme tel dans `docs/CRITERES.md`.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'analysis.dart';
import 'profile.dart';

/// Constat d'un critère de sécurité.
final class Finding {
  /// Violation du critère [code].
  const Finding({
    required this.code,
    required this.message,
    this.week,
    this.dayIndex,
    this.exerciseId,
    this.value,
    this.limit,
  });

  /// Code du critère ([safetyCriteria]).
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

  /// Objet JSON du constat.
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

/// Critères de sécurité : code → intitulé.
const Map<String, String> safetyCriteria = <String, String>{
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

/// Seuils de sécurité par niveau (indice : [BenchLevel.index]).
abstract final class SafetyLimits {
  /// Hausse maximale de la charge totale d'un exercice d'une semaine à
  /// l'autre (R5-P3, R5-P22 : 2 à 10 % chez le débutant, moins ensuite).
  static const List<double> loadRise = <double>[0.10, 0.075, 0.05, 0.05];

  /// Hausse relative maximale des séries dures d'un groupe musculaire par
  /// rapport au plus haut des trois semaines précédentes (R5-P22 : +10 à
  /// +20 % par semaine)…
  static const double volumeRise = 0.20;

  /// … à laquelle s'ajoutent deux séries de tolérance (R5-P22 : « ou +1 à
  /// +2 séries »).
  static const double volumeRiseSets = 2;

  /// Plafond de séries dures fractionnées par groupe et par semaine
  /// (R1-P1 : 12, 20, 25, 30).
  static const List<double> weeklyCeiling = <double>[12, 20, 25, 30];

  /// Nombre de groupes qu'un profil élite peut porter au-dessus du plafond
  /// du niveau avancé (R1-P1 : « 30 sur 1 à 2 muscles »).
  static const int eliteGroupsAboveAdvanced = 2;

  /// Séances bras tendus par famille et par semaine (R4-F10 : 2, 3, 3, 4).
  static const List<int> straightArmDays = <int>[2, 3, 3, 4];

  /// Hausse relative maximale des secondes de tenue bras tendus d'une
  /// famille par rapport au plus haut des trois semaines précédentes
  /// (R5-P22 : +5 à +10 % par semaine, jamais +30 % en deux semaines)…
  static const double straightArmRise = 0.20;

  /// … plus dix secondes de tolérance (une série courte).
  static const double straightArmRiseSeconds = 10;

  /// Semaines minimales sur un levier avant le suivant (R4-F9 : 12, 8, 8,
  /// 6).
  static const List<int> leverWeeks = <int>[12, 8, 8, 6];

  /// Plus longue suite de semaines de charge sans allègement (R3-P9 :
  /// décharge réactive chez le débutant, toutes les 5 à 6 semaines chez
  /// l'intermédiaire, 4 à 5 chez l'avancé, 3 à 5 en élite ; une semaine de
  /// tolérance).
  static const List<int> weeksWithoutRelief = <int>[12, 7, 6, 6];

  /// Part du plus haut volume récent sous laquelle une semaine compte
  /// comme allégée (R3-P9 : séries −40 à −50 % ; 70 % est le seuil large).
  static const double reliefShare = 0.70;

  /// Baisse minimale du volume la dernière semaine avant l'échéance
  /// (R3-P12 : −30 % débutant et intermédiaire, −40 % au moins ensuite ;
  /// seuil large).
  static const List<double> taperDrop = <double>[0.20, 0.20, 0.30, 0.30];

  /// Tolérance sur la durée d'une séance : 15 % plus 3 minutes (les
  /// durées sont des estimations).
  static const double sessionTolerance = 0.15;

  /// Semaines de coupure à partir desquelles la reprise est progressive
  /// (R5-P7).
  static const int breakWeeks = 4;

  /// RIR minimal de la première semaine après une coupure (R5-P7 : ≥ 3).
  static const double resumeMinRir = 3;

  /// Gêne à partir de laquelle une contrainte forte est contre-indiquée
  /// (R5-P23 : plafond de travail 3 à 4 sur 10).
  static const int discomfortHigh = 4;

  /// Gêne à partir de laquelle une contrainte modérée l'est aussi.
  static const int discomfortModerate = 7;

  /// Indice de masse corporelle à partir duquel sauts et pliométrie sont
  /// écartés chez le débutant (R5-P9).
  static const double impactBmi = 30;

  /// Âge à partir duquel l'impact est écarté (programme prudent).
  static const int impactAge = 65;
}

/// Niveau minimal (indice de [BenchLevel]) de chaque format de technique
/// d'intensification (R2-P22, matrice d'accès). Un format absent de la
/// table est libre.
const Map<String, int> techniqueMinLevel = <String, int>{
  'top_set_backoff': 1,
  'drop_set': 1,
  'amrap': 1,
  'cluster': 2,
  'rest_pause': 2,
  'myo_reps': 2,
  'lengthened_partials': 2,
  'eccentric_overload': 2,
  'contrast': 2,
  'waves': 2,
};

/// Fragments d'identifiant des exercices qui sont par nature une technique
/// avancée, et leur niveau minimal (R2-P17 : excentrique surchargé à
/// partir du niveau avancé ; R2-P16 : isométrie surchargée ; R2-P21 :
/// partielles surchargées).
const Map<String, int> techniqueExerciseMinLevel = <String, int>{
  'supramaximal': 2,
  'partielle-haute': 2,
  'partiel-haut': 2,
  'partiel-surcharge': 2,
  'isometrie-lestee': 2,
  'chaines': 1,
};

int _levelIndexOf(ExerciseLevel level) => level.index;

/// Vrai si un échec sur [e] expose à une chute, une tête en bas ou une
/// articulation en fin d'amplitude (R5-P27, risque élevé).
bool isHighRisk(CatalogExercise e) {
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

/// Vrai si un échec sur [e] est à risque modéré : tractions, dips, pompes
/// lestées et autres polyarticulaires lestés (R5-P27).
bool isModerateRisk(CatalogExercise e) {
  if (isHighRisk(e)) {
    return false;
  }
  return e.pattern == MovementPattern.tirageVertical ||
      e.pattern == MovementPattern.pousseeVerticaleBasse ||
      e.loadType == LoadType.addedWeight ||
      (e.loadType == LoadType.barbell &&
          e.articularity == Articularity.multiJoint);
}

/// Constats de sécurité du programme lu [view] pour le profil [profile].
List<Finding> safetyFindings(ProgramView view, BenchProfile profile) {
  final out = <Finding>[];
  final level = profile.level.index;
  final weeks = view.weeks;
  final catalog = view.catalog;

  // --- Hausse de charge d'une semaine à l'autre.
  final lastLoad = <String, (int, double)>{};
  for (final w in weeks) {
    for (final i in w.items) {
      final total = i.totalLoadKg;
      if (total == null || total <= 0 || i.isTest) {
        continue;
      }
      final key = '${i.dayIndex}|${i.p.slotId}|${i.exercise.id}';
      final before = lastLoad[key];
      if (before != null && before.$1 == w.index - 1) {
        final rise = total / before.$2 - 1;
        final limit = SafetyLimits.loadRise[level];
        if (rise > limit + 1e-9) {
          out.add(
            Finding(
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
      lastLoad[key] = (w.index, total);
    }
  }

  // --- Volume par groupe : hausse et plafond.
  final ceiling = SafetyLimits.weeklyCeiling[level];
  for (final g in MuscleGroup.values) {
    if (!g.major) {
      continue;
    }
    for (final w in weeks) {
      final sets = w.groupSets(g);
      var reference = 0.0;
      for (var k = w.index - 3; k < w.index; k++) {
        if (k >= 0) {
          final s = weeks[k].groupSets(g);
          if (s > reference) {
            reference = s;
          }
        }
      }
      if (w.index > 0) {
        final limit =
            reference * (1 + SafetyLimits.volumeRise) +
            SafetyLimits.volumeRiseSets;
        if (sets > limit + 1e-9) {
          out.add(
            Finding(
              code: 'volume_trop_vite',
              message:
                  '${g.code} : ${sets.toStringAsFixed(1)} séries dures en '
                  'semaine ${w.index + 1}, contre '
                  '${reference.toStringAsFixed(1)} au plus les trois '
                  'semaines précédentes.',
              week: w.index,
              value: sets,
              limit: limit,
            ),
          );
        }
      }
      if (sets > ceiling + 1e-9) {
        out.add(
          Finding(
            code: 'plafond_volume',
            message:
                '${g.code} : ${sets.toStringAsFixed(1)} séries dures en '
                'semaine ${w.index + 1} (plafond du niveau '
                '${profile.level.label} : ${ceiling.toStringAsFixed(0)}).',
            week: w.index,
            value: sets,
            limit: ceiling,
          ),
        );
      }
    }
  }
  if (profile.level == BenchLevel.elite) {
    final advanced = SafetyLimits.weeklyCeiling[BenchLevel.advanced.index];
    for (final w in weeks) {
      var above = 0;
      for (final g in MuscleGroup.values) {
        if (g.major && w.groupSets(g) > advanced + 1e-9) {
          above++;
        }
      }
      if (above > SafetyLimits.eliteGroupsAboveAdvanced) {
        out.add(
          Finding(
            code: 'plafond_volume',
            message:
                '$above groupes au-dessus de '
                '${advanced.toStringAsFixed(0)} séries dures en semaine '
                '${w.index + 1} (au plus '
                '${SafetyLimits.eliteGroupsAboveAdvanced} en élite).',
            week: w.index,
            value: above.toDouble(),
            limit: SafetyLimits.eliteGroupsAboveAdvanced.toDouble(),
          ),
        );
      }
    }
  }

  // --- Techniques, niveau des exercices, paliers non acquis.
  final known = <String>{
    for (final r in profile.records)
      if (r.value > 0) r.exerciseId,
    for (final id in benchStrings(profile.core, 'knownExerciseIds')) id,
  };
  final notAcquired = <CatalogExercise>[
    for (final r in profile.records)
      if (r.value <= 0 && catalog.contains(r.exerciseId))
        catalog.exercise(r.exerciseId),
    for (final id in benchStrings(profile.core, 'cannotDoExerciseIds'))
      if (catalog.contains(id)) catalog.exercise(id),
  ];
  final seenExercise = <String>{};
  for (final w in weeks) {
    for (final i in w.items) {
      final e = i.exercise;
      final format = i.p.format;
      if (format != null) {
        final need = techniqueMinLevel[format];
        if (need != null && level < need) {
          out.add(
            Finding(
              code: 'technique_sans_prerequis',
              message:
                  '${e.name} : format « $format » réservé au niveau '
                  '${BenchLevel.values[need].label} et au-delà.',
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
      for (final entry in techniqueExerciseMinLevel.entries) {
        if (e.id.contains(entry.key) && level < entry.value) {
          out.add(
            Finding(
              code: 'technique_sans_prerequis',
              message:
                  '${e.name} : technique réservée au niveau '
                  '${BenchLevel.values[entry.value].label} et au-delà.',
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
          Finding(
            code: 'exercice_trop_avance',
            message:
                '${e.name} (niveau ${e.level.code} de la base) pour un '
                'profil ${profile.level.label}.',
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
            Finding(
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
  for (final injury in profile.injuries) {
    final joint = injury.catalogJoint;
    if (joint == null) {
      continue;
    }
    final recent = injury.status == 'history' && (injury.monthsAgo ?? 99) < 12;
    final flagged = <String>{};
    for (final w in weeks) {
      for (final i in w.items) {
        final stress = i.exercise.stressOn(joint);
        var bad = false;
        var why = '';
        if (stress == JointStress.high &&
            injury.discomfort >= SafetyLimits.discomfortHigh) {
          bad = true;
          why = 'contrainte forte';
        } else if (stress == JointStress.moderate &&
            injury.discomfort >= SafetyLimits.discomfortModerate) {
          bad = true;
          why = 'contrainte modérée';
        } else if (stress == JointStress.high &&
            (recent || injury.discomfort >= 2) &&
            i.isResistance &&
            !i.isTest &&
            (i.rir ?? 5) < 1) {
          // R5-P20 : pas d'échec sur une zone fragile (antécédent de moins
          // de douze mois ou gêne résiduelle).
          bad = true;
          why = "contrainte forte menée à l'échec";
        }
        if (bad && flagged.add(i.exercise.id)) {
          out.add(
            Finding(
              code: 'contre_indication',
              message:
                  '${i.exercise.name} : $why sur ${joint.code} '
                  '(${injury.label}, gêne ${injury.discomfort}/10).',
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
  for (final family in StraightArmFamily.values) {
    for (final w in weeks) {
      final days = w.straightArmDays(family);
      final maxDays = SafetyLimits.straightArmDays[level];
      if (days > maxDays) {
        out.add(
          Finding(
            code: 'tendon_figures',
            message:
                'Tenues bras tendus (${family.name}) $days jours en '
                'semaine ${w.index + 1} (au plus $maxDays au niveau '
                '${profile.level.label}).',
            week: w.index,
            value: days.toDouble(),
            limit: maxDays.toDouble(),
          ),
        );
      }
      if (w.index == 0) {
        continue;
      }
      var reference = 0.0;
      for (var k = w.index - 3; k < w.index; k++) {
        if (k >= 0) {
          final s = weeks[k].straightArmSeconds(family);
          if (s > reference) {
            reference = s;
          }
        }
      }
      final seconds = w.straightArmSeconds(family);
      final limit =
          reference * (1 + SafetyLimits.straightArmRise) +
          SafetyLimits.straightArmRiseSeconds;
      if (reference > 0 && seconds > limit + 1e-9) {
        out.add(
          Finding(
            code: 'tendon_figures',
            message:
                'Tenues bras tendus (${family.name}) : '
                '${seconds.round()} s en semaine ${w.index + 1}, contre '
                '${reference.round()} s au plus les trois semaines '
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
  final minWeeks = SafetyLimits.leverWeeks[level];
  for (final levers in chain.values) {
    for (final later in levers) {
      for (final earlier in levers) {
        final gap = firstWeek[later.id]! - firstWeek[earlier.id]!;
        if (later.difficulty > earlier.difficulty &&
            gap > 0 &&
            gap < minWeeks &&
            !known.contains(later.id)) {
          out.add(
            Finding(
              code: 'levier_trop_tot',
              message:
                  '${later.name} arrive $gap semaines après '
                  '${earlier.name} (au moins $minWeeks au niveau '
                  '${profile.level.label}).',
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
      if (r <= 0 && isHighRisk(i.exercise)) {
        out.add(
          Finding(
            code: 'echec_risque',
            message:
                "${i.exercise.name} : série prescrite à l'échec sur un "
                'mouvement à risque élevé.',
            week: w.index,
            dayIndex: i.dayIndex,
            exerciseId: i.exercise.id,
          ),
        );
      }
      if (profile.level == BenchLevel.beginner &&
          r <= 1 &&
          (isHighRisk(i.exercise) || isModerateRisk(i.exercise))) {
        beginnerNearFailure += i.p.sets;
      }
    }
    if (beginnerNearFailure >= 2) {
      out.add(
        Finding(
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
      final limit = d.minutesBudget * (1 + SafetyLimits.sessionTolerance) + 3;
      if (minutes > limit) {
        out.add(
          Finding(
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
    final relieved =
        w.isLight ||
        (reference > 0 &&
            w.hardSets <= reference * SafetyLimits.reliefShare + 1e-9);
    if (relieved) {
      run = 0;
      reported = false;
      continue;
    }
    run++;
    final limit = SafetyLimits.weeksWithoutRelief[level];
    if (run > limit && !reported) {
      reported = true;
      out.add(
        Finding(
          code: 'decharge_absente',
          message:
              '$run semaines de charge de suite sans allègement à la '
              'semaine ${w.index + 1} (au plus $limit au niveau '
              '${profile.level.label}).',
          week: w.index,
          value: run.toDouble(),
          limit: limit.toDouble(),
        ),
      );
    }
  }

  // --- Affûtage avant l'échéance prioritaire.
  final event = profile.mainEvent;
  if (event != null && weeks.isNotEmpty) {
    final at = event.weeksOut - 1;
    if (at >= weeks.length) {
      out.add(
        Finding(
          code: 'affutage_absent',
          message:
              "L'échéance (semaine ${event.weeksOut}) est au-delà du "
              'programme généré (${weeks.length} semaines).',
        ),
      );
    } else if (at >= 2) {
      var peak = 0.0;
      for (var k = at - 6; k < at; k++) {
        if (k >= 0 && weeks[k].hardSets > peak) {
          peak = weeks[k].hardSets;
        }
      }
      final last = weeks[at].hardSets;
      final drop = peak <= 0 ? 0.0 : 1 - last / peak;
      final need = SafetyLimits.taperDrop[level];
      if (drop < need - 1e-9) {
        out.add(
          Finding(
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
  if (profile.breakWeeks >= SafetyLimits.breakWeeks && weeks.isNotEmpty) {
    final flagged = <String>{};
    for (final i in weeks.first.items) {
      if (!i.isResistance) {
        continue;
      }
      final r = i.rir;
      if (r != null &&
          r < SafetyLimits.resumeMinRir &&
          flagged.add(i.exercise.id)) {
        out.add(
          Finding(
            code: 'reprise_trop_dure',
            message:
                '${i.exercise.name} : RIR ${r.toStringAsFixed(1)} dès la '
                'première semaine après ${profile.breakWeeks} semaines '
                "d'arrêt (au moins 3 attendus).",
            week: 0,
            dayIndex: i.dayIndex,
            exerciseId: i.exercise.id,
            value: r,
            limit: SafetyLimits.resumeMinRir,
          ),
        );
      }
    }
  }

  // --- Impact.
  final age = benchStartYear - profile.birthYear;
  final screening = profile.core['healthScreening'];
  final cautious =
      screening is Map<String, Object?> &&
      screening['outcome'] == HealthScreeningOutcome.cautious.code;
  final bmi = profile.bodyMassIndex;
  final heavyBeginner =
      profile.level == BenchLevel.beginner &&
      bmi != null &&
      bmi >= SafetyLimits.impactBmi;
  if (age >= SafetyLimits.impactAge || cautious || heavyBeginner) {
    final flagged = <String>{};
    for (final w in weeks) {
      for (final i in w.items) {
        if (i.traits.impact && flagged.add(i.exercise.id)) {
          out.add(
            Finding(
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

/// Année du début des programmes du banc.
const int benchStartYear = 2026;
