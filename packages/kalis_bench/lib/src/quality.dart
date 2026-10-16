/// Critères de qualité (mesurés, non bloquants) : volume dans la bande du
/// référentiel, fréquence des mouvements prioritaires, spécificité,
/// progression planifiée, équilibre poussée / tirage, points faibles,
/// alignement de l'affûtage, variété, non-ressemblance.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart' show OwnerProgram, jaccard;

import 'analysis.dart';
import 'profile.dart';

/// Mesure d'un critère de qualité.
final class QualityMeasure {
  /// Mesure du critère [code].
  const QualityMeasure(this.code, this.score, this.detail, this.values);

  /// Code du critère ([qualityCriteria]).
  final String code;

  /// Note de 0 à 1, ou `null` quand le critère ne s'applique pas au profil.
  final double? score;

  /// Constat, en français.
  final String detail;

  /// Valeurs mesurées.
  final Map<String, Object?> values;

  /// Objet JSON de la mesure.
  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    if (score != null) 'score': _r(score!),
    'detail': detail,
    'values': values,
  };
}

double _r(double v) => (v * 1000).roundToDouble() / 1000;

/// Critères de qualité : code → intitulé.
const Map<String, String> qualityCriteria = <String, String>{
  'volume_bande': 'Volume par muscle dans la bande du référentiel',
  'frequence_prioritaires': 'Fréquence des mouvements prioritaires',
  'specificite': "Spécificité à l'approche de l'échéance",
  'progression_planifiee': 'Progression planifiée',
  'equilibre_poussee_tirage': 'Équilibre poussée / tirage',
  'points_faibles': 'Couverture des points faibles',
  'affutage_aligne': "Affûtage aligné sur la date de l'échéance",
  'variete_utile': 'Variété utile',
  'non_ressemblance_proprietaire':
      'Non-ressemblance au programme du propriétaire',
};

/// Bandes de séries dures fractionnées par groupe et par semaine
/// (plancher, plafond) par niveau (R1-P1 et synthèse R1 § 2).
const List<(double, double)> volumeBands = <(double, double)>[
  (4, 12),
  (8, 20),
  (10, 25),
  (12, 30),
];

/// Expositions hebdomadaires attendues d'un mouvement prioritaire (R1-P9,
/// R2-P7 : au moins deux).
const double priorityFrequency = 2;

/// Part des séries dures attendue sur les mouvements prioritaires dans les
/// quatre dernières semaines avant l'échéance (choix raisonné, voir
/// `docs/CRITERES.md`).
const double lateSpecificShare = 0.40;

/// Seuil de ressemblance au programme du propriétaire (indice de Jaccard).
const double resemblanceLimit = 0.30;

final RegExp _ownerScheme = RegExp(
  r'(\d+)\s*[×x]\s*(\d+)(?:\s*[-–à]\s*(\d+))?',
);

/// Couples « exercice | schéma » de chaque semaine du programme du
/// propriétaire (objet JSON de `owner_program_v33.json.gz`).
List<Set<String>> ownerWeekPairs(Map<String, Object?> json) {
  final out = <Set<String>>[];
  for (final w in benchList(json, 'weeks')) {
    final pairs = <String>{};
    for (final d in benchList(benchObject(w, 'weeks'), 'days')) {
      for (final x in benchList(benchObject(d, 'days'), 'exercises')) {
        final exercise = benchObject(x, 'exercises');
        final id = exercise['catalogId'];
        final sets = exercise['sets'];
        if (id is! String || sets is! String) {
          continue;
        }
        final m = _ownerScheme.firstMatch(sets);
        if (m == null) {
          continue;
        }
        final low = m.group(2)!;
        pairs.add('$id|${m.group(1)}x$low-${m.group(3) ?? low}');
      }
    }
    if (pairs.isNotEmpty) {
      out.add(pairs);
    }
  }
  return out;
}

/// Couples « exercice | schéma » de chaque semaine du programme lu.
List<Set<String>> programWeekPairs(ProgramView view) => <Set<String>>[
  for (final w in view.weeks)
    <String>{
      for (final i in w.items)
        if (i.isResistance) '${i.exercise.id}|${i.scheme}',
    },
];

/// Plus forte ressemblance (Jaccard) entre une semaine de [program] et une
/// semaine de [reference].
double maxPairResemblance(
  List<Set<String>> program,
  List<Set<String>> reference,
) {
  var best = 0.0;
  for (final a in program) {
    for (final b in reference) {
      final j = jaccard(a, b);
      if (j > best) {
        best = j;
      }
    }
  }
  return best;
}

double _mean(Iterable<double> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Part du temps de renforcement dans le programme (séries dures par
/// rapport aux exercices) : un profil de cardio ou de mobilité pure n'a
/// pas de critère de volume musculaire.
bool _isResistanceProgram(ProgramView view) {
  var resistance = 0;
  var all = 0;
  for (final w in view.weeks) {
    for (final i in w.items) {
      all++;
      if (i.isResistance) {
        resistance++;
      }
    }
  }
  return all > 0 && resistance / all >= 0.3;
}

/// Mesures de qualité du programme lu [view] pour le profil [profile].
/// [owner] et [ownerPairs] : programme du propriétaire (non-ressemblance).
List<QualityMeasure> qualityMeasures(
  ProgramView view,
  BenchProfile profile, {
  OwnerProgram? owner,
  List<Set<String>>? ownerPairs,
}) {
  final out = <QualityMeasure>[];
  final level = profile.level.index;
  final weeks = view.weeks;
  final build = view.buildWeeks;
  final resistance = _isResistanceProgram(view);
  final (priorityIds, priorityRoots) = view.chainOf(profile.priorityIds);

  // --- Volume dans la bande.
  if (!resistance) {
    out.add(
      const QualityMeasure(
        'volume_bande',
        null,
        'Sans objet : programme sans renforcement dominant.',
        <String, Object?>{},
      ),
    );
  } else {
    final (floor, ceiling) = volumeBands[level];
    final under = <String>[];
    final over = <String>[];
    final means = <String, Object?>{};
    var inBand = 0;
    var counted = 0;
    for (final g in MuscleGroup.values) {
      if (!g.major) {
        continue;
      }
      final mean = _mean(build.map((w) => w.groupSets(g)));
      means[g.code] = _r(mean);
      counted++;
      if (mean < floor - 1e-9) {
        under.add(muscleLabel(g));
      } else if (mean > ceiling + 1e-9) {
        over.add(muscleLabel(g));
      } else {
        inBand++;
      }
    }
    out.add(
      QualityMeasure(
        'volume_bande',
        counted == 0 ? null : inBand / counted,
        '$inBand groupes majeurs sur $counted entre '
            '${floor.toStringAsFixed(0)} et ${ceiling.toStringAsFixed(0)} '
            'séries dures par semaine (semaines de montée)'
            '${under.isEmpty ? '' : ' ; sous le plancher : ${under.join(', ')}'}'
            '${over.isEmpty ? '' : ' ; au-dessus du plafond : ${over.join(', ')}'}.',
        <String, Object?>{
          'floor': floor,
          'ceiling': ceiling,
          'meanSetsByGroup': means,
          'under': under,
          'over': over,
        },
      ),
    );
  }

  // --- Fréquence des mouvements prioritaires.
  if (priorityIds.isEmpty) {
    out.add(
      const QualityMeasure(
        'frequence_prioritaires',
        null,
        'Sans objet : aucun mouvement prioritaire déclaré.',
        <String, Object?>{},
      ),
    );
  } else {
    final byExercise = <String, Object?>{};
    final scores = <double>[];
    for (final id in profile.priorityIds) {
      final (ids, roots) = view.chainOf(<String>[id]);
      final freq = _mean(build.map((w) => w.daysWith(ids, roots).toDouble()));
      byExercise[id] = _r(freq);
      scores.add(_clamp01(freq / priorityFrequency));
    }
    out.add(
      QualityMeasure(
        'frequence_prioritaires',
        _mean(scores),
        'Séances par semaine où chaque mouvement prioritaire (ou un palier '
            'de sa chaîne) est travaillé ; attendu : au moins '
            '${priorityFrequency.toStringAsFixed(0)}.',
        <String, Object?>{'daysPerWeek': byExercise},
      ),
    );
  }

  // --- Spécificité à l'approche de l'échéance.
  final event = profile.mainEvent;
  if (event == null || priorityIds.isEmpty || weeks.length < 6) {
    out.add(
      const QualityMeasure(
        'specificite',
        null,
        'Sans objet : pas d\'échéance prioritaire à six semaines ou plus.',
        <String, Object?>{},
      ),
    );
  } else {
    double share(Iterable<WeekView> ws) {
      var specific = 0.0;
      var all = 0.0;
      for (final w in ws) {
        for (final i in w.items) {
          all += i.hardSets;
          if (priorityIds.contains(i.exercise.id) ||
              priorityRoots.contains(i.exercise.rootId)) {
            specific += i.hardSets;
          }
        }
      }
      return all <= 0 ? 0 : specific / all;
    }

    final cut = weeks.length - 4;
    final early = share(weeks.take(cut));
    final late = share(weeks.skip(cut));
    final score =
        _clamp01(late / lateSpecificShare) * (late + 1e-9 >= early ? 1 : 0.8);
    out.add(
      QualityMeasure(
        'specificite',
        score,
        'Part des séries dures sur les mouvements de l\'échéance : '
            '${(early * 100).round()} % avant les quatre dernières '
            'semaines, ${(late * 100).round()} % pendant.',
        <String, Object?>{'earlyShare': _r(early), 'lateShare': _r(late)},
      ),
    );
  }

  // --- Progression planifiée.
  if (!resistance) {
    out.add(
      const QualityMeasure(
        'progression_planifiee',
        null,
        'Sans objet : programme sans renforcement dominant.',
        <String, Object?>{},
      ),
    );
  } else {
    var slots = 0;
    var loadOrReps = 0;
    var setsOrEffort = 0;
    final first = <String, ItemView>{};
    final last = <String, ItemView>{};
    for (final w in weeks) {
      if (w.blockIndex != 0 || w.isLight) {
        continue;
      }
      for (final i in w.items) {
        if (!i.isResistance ||
            (i.role != SlotRole.main &&
                i.role != SlotRole.secondary &&
                i.role != SlotRole.skill)) {
          continue;
        }
        final key = '${i.dayIndex}|${i.p.slotId}|${i.exercise.id}';
        first.putIfAbsent(key, () => i);
        last[key] = i;
      }
    }
    for (final key in first.keys) {
      final a = first[key]!;
      final b = last[key]!;
      if (identical(a, b)) {
        continue;
      }
      slots++;
      final loadUp = (b.totalLoadKg ?? 0) > (a.totalLoadKg ?? 0) + 1e-9;
      final percentUp =
          (b.p.percentOfOneRm ?? 0) > (a.p.percentOfOneRm ?? 0) + 1e-9;
      final repsUp = b.repsHigh > a.repsHigh || b.secondsHigh > a.secondsHigh;
      if (loadUp || percentUp || repsUp) {
        loadOrReps++;
      } else if (b.p.sets > a.p.sets ||
          (b.p.targetFlames ?? 0) > (a.p.targetFlames ?? 0)) {
        setsOrEffort++;
      }
    }
    final score = slots == 0 ? null : (loadOrReps + 0.5 * setsOrEffort) / slots;
    out.add(
      QualityMeasure(
        'progression_planifiee',
        score,
        'Sur $slots mouvements principaux, secondaires ou figures du '
            'premier bloc — en charge, en répétitions ou en durée entre la '
            'première et la dernière semaine de montée : $loadOrReps ; '
            'seulement en séries ou en effort : $setsOrEffort.',
        <String, Object?>{
          'slots': slots,
          'loadOrReps': loadOrReps,
          'setsOrEffortOnly': setsOrEffort,
        },
      ),
    );
  }

  // --- Équilibre poussée / tirage.
  if (!resistance) {
    out.add(
      const QualityMeasure(
        'equilibre_poussee_tirage',
        null,
        'Sans objet : programme sans renforcement dominant.',
        <String, Object?>{},
      ),
    );
  } else {
    var push = 0.0;
    var pull = 0.0;
    for (final w in build) {
      for (final i in w.items) {
        switch (i.traits.balance) {
          case BalanceClass.pushHorizontal:
          case BalanceClass.pushVertical:
            push += i.hardSets;
          case BalanceClass.pullHorizontal:
          case BalanceClass.pullVertical:
            pull += i.hardSets;
          case BalanceClass.pullThenPush:
            push += i.hardSets / 2;
            pull += i.hardSets / 2;
          default:
            break;
        }
      }
    }
    double? score;
    var ratio = 0.0;
    if (push > 0 && pull > 0) {
      ratio = pull / push;
      // R5-P27 : tirage / poussée d'au moins 1 ; bande 1 à 2.
      if (ratio >= 1.0 - 1e-9 && ratio <= 2.0) {
        score = 1;
      } else if (ratio < 1.0) {
        score = _clamp01(ratio);
      } else {
        score = _clamp01(2.0 / ratio);
      }
    } else if (push > 0 || pull > 0) {
      score = 0;
    }
    out.add(
      QualityMeasure(
        'equilibre_poussee_tirage',
        score,
        'Séries dures de tirage / de poussée sur les semaines de montée : '
            '${pull.toStringAsFixed(0)} / ${push.toStringAsFixed(0)}'
            '${push > 0 ? ' (rapport ${ratio.toStringAsFixed(2)})' : ''}.',
        <String, Object?>{'pull': _r(pull), 'push': _r(push)},
      ),
    );
  }

  // --- Points faibles.
  if (profile.weakPoints.isEmpty) {
    out.add(
      const QualityMeasure(
        'points_faibles',
        null,
        'Sans objet : aucun point faible déclaré.',
        <String, Object?>{},
      ),
    );
  } else {
    var covered = 0;
    var checkable = 0;
    final notes = <String>[];
    for (final wp in profile.weakPoints) {
      final exerciseId = wp.exerciseId;
      final groupCode = wp.muscleGroup;
      if (exerciseId != null) {
        checkable++;
        final (ids, roots) = view.chainOf(<String>[exerciseId]);
        final freq = _mean(build.map((w) => w.daysWith(ids, roots).toDouble()));
        if (freq >= priorityFrequency - 1e-9) {
          covered++;
        } else {
          notes.add('$exerciseId : ${freq.toStringAsFixed(1)} séance/sem');
        }
      } else if (groupCode != null) {
        checkable++;
        MuscleGroup? group;
        for (final g in MuscleGroup.values) {
          if (g.code == groupCode) {
            group = g;
          }
        }
        if (group == null) {
          notes.add('$groupCode : groupe inconnu');
          continue;
        }
        final target = group;
        final mean = _mean(build.map((w) => w.groupSets(target)));
        // Attendu : au moins le milieu de la bande du niveau.
        final (floor, ceiling) = volumeBands[level];
        final middle = (floor + ceiling) / 2;
        if (mean >= middle - 1e-9) {
          covered++;
        } else {
          notes.add(
            '$groupCode : ${mean.toStringAsFixed(1)} séries/sem '
            '(attendu ≥ ${middle.toStringAsFixed(0)})',
          );
        }
      }
    }
    out.add(
      QualityMeasure(
        'points_faibles',
        checkable == 0 ? null : covered / checkable,
        '$covered points faibles couverts sur $checkable vérifiables'
            '${notes.isEmpty ? '' : ' ; non couverts : ${notes.join(' ; ')}'}.',
        <String, Object?>{'covered': covered, 'checkable': checkable},
      ),
    );
  }

  // --- Affûtage aligné.
  if (event == null || event.weeksOut - 1 >= weeks.length || weeks.length < 3) {
    out.add(
      const QualityMeasure(
        'affutage_aligne',
        null,
        'Sans objet : pas d\'échéance prioritaire dans le programme.',
        <String, Object?>{},
      ),
    );
  } else {
    final at = event.weeksOut - 1;
    var peak = 0.0;
    for (var k = at - 6; k < at; k++) {
      if (k >= 0 && weeks[k].hardSets > peak) {
        peak = weeks[k].hardSets;
      }
    }
    final drop = peak <= 0 ? 0.0 : 1 - weeks[at].hardSets / peak;
    // R3-P12 : −30 à −60 % (jusqu'à −70 % en force athlétique).
    final dropScore = drop >= 0.3 && drop <= 0.7
        ? 1.0
        : (drop < 0.3 ? _clamp01(drop / 0.3) : _clamp01((1 - drop) / 0.3));
    // Test au plus près de l'échéance.
    var nearestTest = -1;
    for (final w in weeks) {
      final hasTest = w.kind == WeekKind.test || w.items.any((i) => i.isTest);
      if (hasTest &&
          (nearestTest < 0 ||
              (w.index - at).abs() < (nearestTest - at).abs())) {
        nearestTest = w.index;
      }
    }
    final testScore = nearestTest < 0
        ? 0.0
        : (nearestTest == at ? 1.0 : ((nearestTest - at).abs() == 1 ? 0.5 : 0));
    // Fréquence maintenue (R3-P13 : au plus une séance retirée).
    final before = at > 0 ? weeks[at - 1].days.length : weeks[at].days.length;
    final frequencyScore = weeks[at].days.length >= before - 1 ? 1.0 : 0.0;
    out.add(
      QualityMeasure(
        'affutage_aligne',
        (dropScore + testScore + frequencyScore) / 3,
        'Semaine de l\'échéance (semaine ${at + 1}) : nature '
            '${weekKindName(weeks[at].kind)}, volume ${(drop * 100).round()} % sous '
            'le pic des six semaines précédentes ; épreuve la plus proche : '
            '${nearestTest < 0 ? 'aucune' : 'semaine ${nearestTest + 1}'}.',
        <String, Object?>{
          'eventWeek': at + 1,
          'volumeDrop': _r(drop),
          'nearestTestWeek': nearestTest < 0 ? null : nearestTest + 1,
          'weekKind': weeks[at].kind.code,
        },
      ),
    );
  }

  // --- Variété utile.
  if (weeks.isEmpty) {
    out.add(
      const QualityMeasure(
        'variete_utile',
        null,
        'Sans objet : programme vide.',
        <String, Object?>{},
      ),
    );
  } else {
    var slots = 0;
    var duplicates = 0;
    final distinct = <String>{};
    for (final d in weeks.first.days) {
      final roots = <String>{};
      for (final i in d.items) {
        if (!i.isResistance) {
          continue;
        }
        slots++;
        distinct.add(i.exercise.id);
        if (!roots.add(i.exercise.rootId)) {
          duplicates++;
        }
      }
    }
    final rotation = <String>{};
    for (final w in weeks) {
      for (final i in w.items) {
        if (i.isResistance) {
          rotation.add(i.exercise.id);
        }
      }
    }
    out.add(
      QualityMeasure(
        'variete_utile',
        slots == 0 ? null : 1 - duplicates / slots,
        '${distinct.length} exercices de renforcement distincts en '
            'première semaine pour $slots emplacements ; $duplicates '
            'doublons de chaîne dans une même séance ; '
            '${rotation.length} exercices distincts sur tout le programme.',
        <String, Object?>{
          'slots': slots,
          'distinctFirstWeek': distinct.length,
          'sameChainInSession': duplicates,
          'distinctProgram': rotation.length,
        },
      ),
    );
  }

  // --- Non-ressemblance au programme du propriétaire.
  if (owner == null) {
    out.add(
      const QualityMeasure(
        'non_ressemblance_proprietaire',
        null,
        'Non mesuré : programme du propriétaire non fourni.',
        <String, Object?>{},
      ),
    );
  } else {
    var exercises = 0.0;
    for (final w in weeks) {
      final ids = <String>{for (final i in w.items) i.exercise.id};
      final j = owner.weekResemblance(ids);
      if (j > exercises) {
        exercises = j;
      }
    }
    final pairs = ownerPairs == null
        ? 0.0
        : maxPairResemblance(programWeekPairs(view), ownerPairs);
    out.add(
      QualityMeasure(
        'non_ressemblance_proprietaire',
        exercises < resemblanceLimit && pairs < resemblanceLimit ? 1 : 0,
        'Indice de Jaccard le plus haut entre une semaine générée et une '
            'semaine du propriétaire : exercices '
            '${exercises.toStringAsFixed(3)}, exercices × schémas '
            '${pairs.toStringAsFixed(3)} (seuil $resemblanceLimit).',
        <String, Object?>{
          'exercises': _r(exercises),
          'exerciseSchemes': _r(pairs),
          'limit': resemblanceLimit,
        },
      ),
    );
  }
  return out;
}
