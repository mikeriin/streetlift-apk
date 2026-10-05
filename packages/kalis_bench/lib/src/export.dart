/// Export lisible : ce que voient le panel de coachs et la page de
/// relecture. Français, sans code ni identifiant technique.
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart'
    show CoachNotes, coachPhaseLabel, coachReasonText;

import 'adapter.dart';
import 'analysis.dart';
import 'profile.dart';
import 'trajectory.dart';

/// Jours de la semaine (1 = lundi).
const List<String> weekdayNames = <String>[
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

/// Nom français de la nature d'une semaine.
String weekKindLabel(WeekKind kind) => switch (kind) {
  WeekKind.intro => 'introduction',
  WeekKind.build => 'montée',
  WeekKind.deload => 'décharge',
  WeekKind.test => 'test',
};

/// Nom français du thème d'une séance.
String focusLabel(String focus) => switch (focus) {
  'mobility' => 'mobilité',
  'cardio.endurance' => 'cardio, endurance',
  'cardio.intervals' => 'cardio, fractionné',
  'conditioning' => 'conditionnement',
  'skills' => 'figures et technique',
  'strength.lower' => 'force, bas du corps',
  'strength.push' => 'force, poussée',
  'strength.pull' => 'force, tirage',
  'strength.upper' => 'force, haut du corps',
  'strength.full_body' => 'force, corps entier',
  _ => focus.replaceAll('.', ', ').replaceAll('_', ' '),
};

/// Nom français du rôle d'un exercice.
String roleLabel(SlotRole? role) => switch (role) {
  SlotRole.main => 'principal',
  SlotRole.secondary => 'secondaire',
  SlotRole.accessory => 'accessoire',
  SlotRole.skill => 'figure / technique',
  SlotRole.core => 'tronc',
  SlotRole.conditioning => 'conditionnement',
  SlotRole.mobility => 'mobilité',
  SlotRole.warmup => 'échauffement',
  SlotRole.cooldown => 'retour au calme',
  null => '',
};

/// Nom français d'un format de séries.
String formatLabel(String format) => switch (format) {
  'superset' => 'superset',
  'rounds' => 'tours enchaînés',
  'amrap' => 'AMRAP (maximum en temps donné)',
  'emom' => 'EMOM (départ chaque minute)',
  'intervals' => 'fractionné',
  'sprints' => 'sprints',
  'continuous' => 'continu',
  'cluster' => 'cluster (pauses dans la série)',
  'rest_pause' => 'rest-pause',
  'drop_set' => 'série dégressive',
  'top_set_backoff' => 'série haute puis séries allégées',
  _ => format.replaceAll('_', ' '),
};

String _num(double v) {
  final rounded = (v * 100).roundToDouble() / 100;
  var text = rounded.toStringAsFixed(2);
  if (text.endsWith('00')) {
    text = text.substring(0, text.length - 3);
  } else if (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  return text.replaceAll('.', ',');
}

String _duration(int seconds) {
  if (seconds >= 120 && seconds % 60 == 0) {
    return '${seconds ~/ 60} min';
  }
  if (seconds >= 120) {
    return '${seconds ~/ 60} min ${seconds % 60} s';
  }
  return '$seconds s';
}

String _range(int low, int high) => low == high ? '$low' : '$low à $high';

/// Séries et répétitions (ou durée, distance) d'une prescription.
String volumeText(ItemView i) {
  final p = i.p;
  final technique = p.technique;
  if (technique != null && i.isReps) {
    switch (technique.kind) {
      case SetTechniqueKind.topSetBackoff:
        final back = technique.backoffSets ?? p.sets - 1;
        final low = technique.backoffRepsLow ?? i.repsLow;
        final high = technique.backoffRepsHigh ?? i.repsHigh;
        final drop = technique.backoffDropPct;
        return '1 × ${_range(i.repsLow, i.repsHigh)} (série de tête), puis '
            '$back × ${_range(low, high)}'
            '${drop == null || drop == 0 ? '' : ' à −${_num(drop * 100)} %'}';
      case SetTechniqueKind.emom:
        final count = technique.intervals ?? p.sets;
        final every = technique.intervalSeconds ?? 60;
        return every == 60
            ? '$count min : ${_range(i.repsLow, i.repsHigh)} rép. au début '
                  'de chaque minute'
            : '$count × ${_range(i.repsLow, i.repsHigh)}, un départ toutes '
                  'les ${_duration(every)}';
      default:
        break;
    }
  }
  final test = p.test;
  if (test != null && i.isReps) {
    return switch (test.kind) {
      TestKind.oneRm =>
        '${p.sets} tentatives × ${_range(i.repsLow, i.repsHigh)}',
      TestKind.maxReps =>
        '1 série maximale (repère : ${_range(i.repsLow, i.repsHigh)})',
      _ => '${p.sets} × ${_range(i.repsLow, i.repsHigh)}',
    };
  }
  if (i.isReps) {
    return '${p.sets} × ${_range(i.repsLow, i.repsHigh)}';
  }
  if (i.isTimed) {
    if (p.sets == 1 && i.secondsHigh >= 300) {
      return i.secondsLow == i.secondsHigh
          ? _duration(i.secondsHigh)
          : '${i.secondsLow ~/ 60} à ${i.secondsHigh ~/ 60} min';
    }
    return i.secondsLow == i.secondsHigh
        ? '${p.sets} × ${_duration(i.secondsHigh)}'
        : '${p.sets} × ${i.secondsLow} à ${i.secondsHigh} s';
  }
  final meters = p.distanceMeters;
  if (meters != null) {
    return p.sets == 1 && meters >= 1500
        ? '${_num(meters / 1000)} km'
        : '${p.sets} × ${meters.round()} m';
  }
  final calories = p.calories;
  if (calories != null) {
    return '${p.sets} × ${calories.round()} cal';
  }
  return '${p.sets} séries';
}

/// Charge d'une prescription.
String loadText(ItemView i) {
  final p = i.p;
  final parts = <String>[];
  final load = p.startLoadKg;
  if (load != null) {
    switch (p.loadBasis) {
      case LoadBasis.bodyweightPlusExternal:
        parts.add(
          load < 0
              ? 'assistance ${_num(-load)} kg'
              : (load == 0 ? 'poids du corps' : 'lest +${_num(load)} kg'),
        );
      case LoadBasis.external:
        parts.add('${_num(load)} kg');
      case LoadBasis.bodyweight:
      case LoadBasis.unloaded:
        parts.add('${_num(load)} kg');
    }
  } else if ((p.setTargets ?? const <SetTarget>[]).any(
    (t) => t.loadKg != null,
  )) {
    parts.add('voir les séries');
  } else {
    switch (p.loadBasis) {
      case LoadBasis.bodyweight:
        parts.add('poids du corps');
      case LoadBasis.bodyweightPlusExternal:
        parts.add('lest à déterminer');
      case LoadBasis.external:
        parts.add('charge à déterminer');
      case LoadBasis.unloaded:
        break;
    }
  }
  final percent = p.percentOfOneRm;
  if (percent != null) {
    // Le 1RM de référence est écrit en clair (CX, correction 1, panel : un
    // 1RM recalé sur le bloc précédent rendait le pourcentage illisible
    // face au record déclaré).
    final fraction = i.exercise.bodyweightFraction?.value ?? 0;
    final total = load == null || percent <= 0
        ? null
        : (load + fraction * i.bodyWeightKg) / percent;
    parts.add(
      '≈ ${(percent * 100).round()} % du 1RM (charge totale'
      '${total == null ? '' : ' ; 1RM de référence ${_num((total * 2).round() / 2)} kg'})',
    );
  }
  final intensity = p.intensity;
  if (intensity != null && percent == null) {
    final share = '${(intensity.value * 100).round()} %';
    if (intensity.basis == IntensityBasis.percentOneRm) {
      parts.add('≈ $share du 1RM du mouvement de compétition');
    } else if (intensity.basis == IntensityBasis.percentBenchmark) {
      // Le repère utilisé est écrit en clair (dernier maximum mesuré ou
      // repère de reprise) : l'athlète sait sur quoi porte le pourcentage.
      // (Plage de répétitions ouverte vers le haut : la part porte sur le
      // bas de la plage.)
      final top = p.secondsHigh ?? p.repsLow ?? p.repsHigh;
      final base = top == null || intensity.value <= 0
          ? null
          : (top / intensity.value).round();
      parts.add(
        intensity.referenceKind == BenchmarkKind.maxHold
            ? '≈ $share du maintien maximal'
                  '${base == null ? '' : ' (repère : $base s)'}'
            : '≈ $share du maximum de répétitions'
                  '${base == null ? '' : ' (repère : $base)'}',
      );
    }
  }
  if (p.toCalibrate) {
    parts.add('à calibrer');
  }
  return parts.isEmpty ? '—' : parts.join(', ');
}

/// Effort visé d'une prescription : les répétitions en réserve (la note en
/// flammes de l'application n'est pas affichée : elle se lisait comme une
/// difficulté sur 10).
String effortText(ItemView i) {
  final flames = i.p.targetFlames;
  if (flames == null) {
    return '—';
  }
  if (!i.traits.kind.isResistance) {
    // Course et cardio : l'effort se lit dans l'allure donnée en note, pas
    // en répétitions en réserve.
    return i.p.test != null
        ? 'chrono'
        : (Flames.isOpenEnded(flames) ? 'allure facile' : 'allure soutenue');
  }
  if (flames >= Flames.failure) {
    return 'effort maximal';
  }
  final hold =
      i.p.repsHigh == null &&
      i.p.repsLow == null &&
      (i.p.secondsHigh ?? i.p.secondsLow) != null;
  if (Flames.isOpenEnded(flames)) {
    // Descente freinée : l'effort se règle au contrôle, pas à la réserve.
    final tempo = i.p.tempo;
    if (tempo != null &&
        tempo.eccentricSeconds >= 3 &&
        tempo.concentricSeconds == 0) {
      return "au contrôle : arrêt dès qu'une descente accélère";
    }
    return hold
        ? 'sous-maximal : arrêt bien avant la perte de position'
        : '5 rép. en réserve ou plus';
  }
  final rir = Flames.toRir(flames);
  if (hold) {
    // Une tenue ne se compte pas en répétitions : la marge se lit sur la
    // qualité de la position.
    return rir >= 3
        ? 'position parfaite, quelques secondes de marge'
        : 'tenue dure, arrêt avant de perdre la position';
  }
  final text = rir == rir.roundToDouble() ? rir.toStringAsFixed(0) : _num(rir);
  // Séries à une part du maximum de répétitions : la réserve écrite est
  // celle de la dernière série (les séries se cumulent à repos court) ; la
  // première en laisse davantage — on le dit, pour que l'étiquette ne
  // contredise pas les chiffres.
  final intensity = i.p.intensity;
  final top = i.p.repsHigh;
  if (intensity != null &&
      intensity.basis == IntensityBasis.percentBenchmark &&
      intensity.referenceKind != BenchmarkKind.maxHold &&
      intensity.value > 0 &&
      top != null &&
      i.p.sets >= 2 &&
      i.p.technique?.kind != SetTechniqueKind.topSetBackoff) {
    final base = (top / intensity.value).round();
    if (base - top >= rir + 2) {
      return '$text rép. en réserve sur la dernière série (davantage sur '
          'les premières)';
    }
  }
  return '$text rép. en réserve';
}

/// Notes de coach d'une prescription : rôle, épreuve, format, détail des
/// séries quand elles diffèrent.
String notesText(ItemView i, Catalog catalog) {
  final p = i.p;
  final notes = <String>[];
  final role = roleLabel(i.role);
  // Une épreuve n'a pas de rang dans la séance : elle est l'épreuve.
  if (role.isNotEmpty && p.kind != SetKind.test) {
    notes.add(role);
  }
  if (p.kind == SetKind.test) {
    notes.add('ÉPREUVE');
  } else if (p.kind == SetKind.calibration) {
    notes.add('série de calibrage');
  } else if (p.kind == SetKind.warmup && !notes.contains('échauffement')) {
    notes.add('échauffement');
  }
  final format = p.format;
  if (format != null) {
    notes.add(formatLabel(format));
  }
  final targets = p.setTargets;
  if (targets != null && targets.isNotEmpty) {
    final detail = <String>[];
    for (final t in targets) {
      final b = StringBuffer();
      final high = t.repsHigh ?? t.repsLow;
      final seconds = t.secondsHigh ?? t.secondsLow;
      if (high != null) {
        b.write('${_range(t.repsLow ?? high, high)} rép.');
      } else if (seconds != null) {
        b.write('$seconds s');
      }
      final load = t.loadKg;
      if (load != null) {
        b.write(
          ' à ${load >= 0 && p.loadBasis == LoadBasis.bodyweightPlusExternal ? '+' : ''}${_num(load)} kg',
        );
      }
      final flames = t.flames;
      if (flames != null) {
        b.write(' ($flames/10)');
      }
      detail.add(b.toString().trim());
    }
    notes.add('séries : ${detail.join(' ; ')}');
  }
  final technique = p.technique;
  if (technique != null && p.format == null) {
    final label = switch (technique.kind) {
      SetTechniqueKind.isometricHold => 'tenue isométrique',
      SetTechniqueKind.skillPractice => 'pratique technique',
      SetTechniqueKind.standard ||
      SetTechniqueKind.topSetBackoff ||
      SetTechniqueKind.emom => '',
      _ => formatLabel(technique.kind.code),
    };
    if (label.isNotEmpty) {
      notes.add(label);
    }
  }
  final tempo = p.tempo;
  if (tempo != null && tempo.eccentricSeconds > 0) {
    notes.add(
      tempo.topPauseSeconds > 0
          ? '${tempo.topPauseSeconds} s tenues en haut, puis descente en '
                '${tempo.eccentricSeconds} s'
          : 'descente en ${tempo.eccentricSeconds} s',
    );
  }
  if (p.restMode == RestMode.jog) {
    notes.add('récupération en trottinant');
  }
  for (final r in p.reasons) {
    if (_ruleCodes.contains(r.code) || _isBlockNote(r)) {
      continue;
    }
    final text = coachReasonText(r, catalog);
    if (text != null) {
      notes.add(text);
    }
  }
  return notes.join(' ; ');
}

/// Raisons écrites une fois, dans les règles du programme, et non sous
/// chaque exercice.
const Set<String> _ruleCodes = <String>{
  ReasonCodes.planProgressionRule,
  ReasonCodes.planToCalibrate,
};

bool _isBlockNote(Reason r) {
  if (r.code != ReasonCodes.planCoachNote) {
    return false;
  }
  final note = r.params['note'];
  // (Les montées avant la série de tête restent sous chaque exercice : la
  // relecture documentée de CX ne voyait pas d'échauffement spécifique
  // dans les séances.)
  return note == CoachNotes.loadAdjust ||
      note == CoachNotes.repsAdjust ||
      note == CoachNotes.testUse ||
      note == CoachNotes.badDay ||
      note == CoachNotes.missed ||
      note == CoachNotes.testRest ||
      note == CoachNotes.topSetBackoff ||
      note == CoachNotes.submaximalHold ||
      note == CoachNotes.qualityFirst ||
      note == CoachNotes.everyMinute ||
      note == CoachNotes.generalWarmup;
}

/// Nom français de l'intention d'une semaine.
String weekIntentLabel(WeekIntent intent) => coachPhaseLabel(intent.code);

/// Nom français de la charge d'une séance.
String dayStressLabel(DayStress stress) => switch (stress) {
  DayStress.heavy => 'séance lourde',
  DayStress.medium => 'séance moyenne',
  DayStress.light => 'séance légère',
};

/// Règles du programme, écrites une fois : lecture du profil, phase,
/// règles de progression, de douleur et d'exécution (raisons du bloc et
/// règles communes aux exercices). Vide pour un moteur 0.1.
List<String> programRules(ProgramView view) {
  final catalog = view.catalog;
  final out = <String>[];
  void add(String? text) {
    if (text != null && !out.contains(text)) {
      out.add(text);
    }
  }

  final blocks = view.program.blocks;
  if (blocks.isEmpty || blocks.first.pass1.intent == null) {
    return out;
  }
  for (final r in blocks.first.pass2.reasons) {
    if (r.code != ReasonCodes.planSeasonPhase) {
      add(coachReasonText(r, catalog));
    }
  }
  for (final w in view.weeks) {
    for (final i in w.items) {
      for (final r in i.p.reasons) {
        if (_isBlockNote(r) && r.params['note'] == CoachNotes.everyMinute) {
          add(
            'Départs au chrono : chaque série part à heure fixe (le repos '
            'est ce qui reste) ; si les répétitions ne passent plus, arrête '
            'là.',
          );
        } else if (_ruleCodes.contains(r.code) || _isBlockNote(r)) {
          add(coachReasonText(r, catalog));
        }
      }
    }
  }
  add(
    'Effort visé : les « répétitions en réserve » sont celles que tu '
    "pourrais encore faire proprement à la fin de la série ; s'il t'en "
    'reste moins que prévu, allège ou arrête la série.',
  );
  return out;
}

/// Saison : une ligne par bloc (semaines, phases).
List<String> seasonLines(ProgramView view) {
  final out = <String>[];
  final blocks = view.program.blocks;
  if (blocks.isEmpty || blocks.first.pass1.intent == null) {
    return out;
  }
  var first = 0;
  for (var b = 0; b < blocks.length; b++) {
    final weeks = <WeekView>[
      for (final w in view.weeks)
        if (w.blockIndex == b) w,
    ];
    if (weeks.isEmpty) {
      continue;
    }
    final parts = <String>[];
    String? current;
    var from = 0;
    void flush(int to) {
      final label = current;
      if (label != null) {
        parts.add(
          from == to
              ? 'semaine ${from + 1} : $label'
              : 'semaines ${from + 1} à ${to + 1} : $label',
        );
      }
    }

    for (final w in weeks) {
      final intent = w.intent;
      final label = intent == null
          ? weekKindLabel(w.kind)
          : weekIntentLabel(intent);
      if (label != current) {
        flush(w.index - 1);
        current = label;
        from = w.index;
      }
    }
    flush(weeks.last.index);
    final intent = blocks[b].pass1.intent;
    out.add(
      '- **Bloc ${b + 1}** (semaines ${first + 1} à ${weeks.last.index + 1}'
      '${intent == null ? '' : ', ${coachPhaseLabel(intent.phase.code)}'}) — '
      '${parts.join(' ; ')}.',
    );
    // Règles propres au bloc (CX, correction 1) : arrêt d'une douleur qui
    // dure, reprise graduée — elles ne valent que pour ce bloc et sont
    // dites sous sa ligne.
    final own = <String>[];
    for (final r in <Reason>[
      ...blocks[b].pass1.reasons,
      ...blocks[b].pass2.reasons,
    ]) {
      final note = r.params['note'];
      if (r.code != ReasonCodes.planCoachNote ||
          (note != CoachNotes.painStop && note != CoachNotes.painReturn)) {
        continue;
      }
      final text = coachReasonText(r, view.catalog);
      if (text != null && !own.contains(text)) {
        own.add(text);
      }
    }
    for (final text in own) {
      out.add('  - $text');
    }
    first = weeks.last.index + 1;
  }
  return out;
}

/// Échelles des figures travaillées : étapes et critère de passage.
List<String> ladderLines(ProgramView view) {
  final out = <String>[];
  final blocks = view.program.blocks;
  if (blocks.isEmpty) {
    return out;
  }
  final catalog = view.catalog;
  final current = <String>{
    for (final r in blocks.first.pass1.reasons)
      if (r.code == ReasonCodes.planSkillStep &&
          r.params['exerciseId'] is String)
        r.params['exerciseId']! as String,
  };
  for (final ladder
      in blocks.first.pass1.skillLadders ?? const <SkillLadder>[]) {
    final target =
        catalog.find(ladder.targetExerciseId)?.name ?? ladder.targetExerciseId;
    final steps = <String>[
      for (final s in ladder.steps)
        '${catalog.find(s.exerciseId)?.name ?? s.exerciseId}'
            '${current.contains(s.exerciseId) ? ' (étape actuelle)' : ''}',
    ];
    out.add('- **Vers : $target** — ${steps.join(' → ')}.');
    if (ladder.steps.isNotEmpty) {
      final c = ladder.steps.first.criterion;
      final hold = c.holdSeconds;
      final reps = c.reps;
      out.add(
        "  - Passage à l'étape suivante : ${c.sets} séries de "
        '${hold != null ? '$hold s' : '${reps ?? 3} répétitions'} propres'
        '${c.minQuality == null ? '' : ' (qualité ${c.minQuality} sur 5 au moins)'}'
        '${c.sessions == null ? '' : ', sur ${c.sessions} séances de suite'}'
        '${c.minWeeks == null ? '' : ', et au moins ${c.minWeeks} semaines sur l\'étape'}'
        ' ; sinon on reste, sans forcer le levier.',
      );
    }
  }
  return out;
}

String _sexLabel(String? code) => switch (code) {
  'female' => 'femme',
  'male' => 'homme',
  _ => 'sexe non précisé',
};

String _oneRmText(String exerciseId, double? value, Catalog catalog) {
  if (value == null) {
    return '1RM';
  }
  final weighted = catalog.find(exerciseId)?.loadType == LoadType.addedWeight;
  return weighted
      ? '1RM avec +${_num(value)} kg de lest'
      : '1RM ${_num(value)} kg';
}

String _measureText(
  String exerciseId,
  LevelMeasure measure,
  double value,
  Catalog catalog,
) => switch (measure) {
  LevelMeasure.maxReps => '${_num(value)} répétitions au maximum',
  LevelMeasure.oneRmKg => _oneRmText(exerciseId, value, catalog),
  LevelMeasure.maxHoldSeconds => 'tenue maximale ${_num(value)} s',
  LevelMeasure.timeSeconds => 'temps ${_duration(value.round())}',
};

String _targetText(BenchTarget t, Catalog catalog) {
  final name = catalog.find(t.exerciseId)?.name ?? t.exerciseId;
  final value = t.targetValue;
  return switch (t.metric) {
    GoalMetric.oneRmKg => '$name : ${_oneRmText(t.exerciseId, value, catalog)}',
    GoalMetric.maxReps =>
      '$name : ${value == null ? '' : _num(value)} répétitions'
          '${t.loadKg == null ? '' : ' à ${_num(t.loadKg!)} kg'}',
    GoalMetric.maxHoldSeconds =>
      '$name : tenue de ${value == null ? '' : _num(value)} s',
    GoalMetric.skillUnlocked => '$name : figure à débloquer',
    // Une course chronométrée se nomme par sa distance, pas par l'exercice
    // d'entraînement qui la porte.
    GoalMetric.timeSeconds =>
      '${t.distanceMeters == null ? name : 'Course chronométrée'} : '
          '${t.distanceMeters == null ? '' : '${t.distanceMeters!.round()} m '}'
          'en ${value == null ? '' : _duration(value.round())}',
    GoalMetric.distanceMeters =>
      '$name : ${value == null ? '' : '${value.round()} m'}',
  };
}

String _disciplineLabel(String code) => switch (code) {
  'musculation' => 'musculation',
  'street_workout' => 'street workout (sets & reps)',
  'streetlifting' => 'streetlifting',
  'calisthenics' => 'calisthénie et figures',
  'crossfit' => 'CrossFit',
  'cardio' => 'cardio',
  'mobility' => 'mobilité',
  'general_fitness' => 'forme générale',
  _ => code,
};

String _placeLabel(String code) => switch (code) {
  'salle' => 'salle',
  'maison' => 'maison',
  'exterieur' => 'extérieur (parc)',
  _ => code,
};

/// Portrait du profil, tel qu'un coach le lirait.
List<String> profileLines(BenchProfile p, Catalog catalog) {
  final core = p.core;
  final out = <String>[];
  final age = benchStartDate.year - p.birthYear;
  final weight = p.bodyWeightKg;
  out.add(
    '- **Identité** : ${_sexLabel(benchStringOrNull(core, 'sex'))}, $age ans, '
    '${p.heightCm} cm${weight == null ? '' : ', ${_num(weight)} kg'}.',
  );
  final years = p.trainingAgeMonths >= 24
      ? '${p.trainingAgeMonths ~/ 12} ans'
      : '${p.trainingAgeMonths} mois';
  out.add(
    '- **Niveau** : ${p.level.label} ; ancienneté d\'entraînement '
    'structuré : $years.',
  );
  final mix = benchObject(core['disciplines'], 'disciplines');
  final parts = <String>[
    '${_disciplineLabel(benchString(mix, 'primary'))} '
        '${benchInt(mix, 'primaryPct')} %',
    for (final s in benchList(mix, 'secondaries'))
      '${_disciplineLabel(benchString(benchObject(s, 'secondaries'), 'discipline'))} '
          '${benchInt(benchObject(s, 'secondaries'), 'pct')} %',
  ];
  out.add('- **Disciplines** : ${parts.join(', ')}.');
  final days = <String>[
    for (final d in benchList(core, 'availability'))
      '${weekdayNames[benchInt(benchObject(d, 'availability'), 'weekday') - 1]} '
          '${benchInt(benchObject(d, 'availability'), 'minutes')} min',
  ];
  out.add('- **Disponibilités** : ${days.join(', ')}.');
  out.add(
    '- **Lieux et matériel** : '
    '${benchStrings(core, 'places').map(_placeLabel).join(', ')} ; '
    '${benchStrings(core, 'equipment').join(', ')}.',
  );
  if (p.records.isNotEmpty) {
    out.add('- **Tests et records** :');
    for (final r in p.records) {
      final name = catalog.find(r.exerciseId)?.name ?? r.exerciseId;
      out.add(
        '  - $name : ${_measureText(r.exerciseId, r.measure, r.value, catalog)}'
        '${r.testedWeeksAgo == null ? '' : ' (test il y a ${r.testedWeeksAgo} sem.)'}',
      );
    }
  }
  if (p.unknownLevels.isNotEmpty) {
    out.add(
      '- **Niveau inconnu** sur : '
      '${p.unknownLevels.map((id) => catalog.find(id)?.name ?? id).join(', ')}.',
    );
  }
  for (final e in p.events) {
    out.add(
      '- **Échéance** (${e.kind == 'competition' ? 'compétition' : 'test'}, '
      'priorité ${e.priority}) : ${e.label}, dans ${e.weeksOut} semaines'
      '${e.targets.isEmpty ? '' : ' — ${e.targets.map((t) => _targetText(t, catalog)).join(' ; ')}'}.',
    );
  }
  for (final g in p.goals) {
    out.add(
      '- **Objectif** : ${_targetText(g.target, catalog)}, d\'ici '
      '${g.weeksOut} semaines.',
    );
  }
  final habit = p.habitSessionsPerWeek;
  if (habit != null) {
    out.add(
      '- **Objectif d\'habitude** : $habit séances par semaine pendant '
      '${p.habitWeeks} semaines.',
    );
  }
  if (p.priorityExerciseIds.isNotEmpty) {
    out.add(
      '- **Spécialisation** : priorité à '
      '${p.priorityExerciseIds.map((id) => catalog.find(id)?.name ?? id).join(', ')}'
      '${p.maintainExerciseIds.isEmpty ? '' : ' ; à entretenir : ${p.maintainExerciseIds.map((id) => catalog.find(id)?.name ?? id).join(', ')}'}.',
    );
  }
  for (final w in p.weakPoints) {
    out.add('- **Point faible** : ${w.note}.');
  }
  for (final i in p.injuries) {
    out.add(
      '- **${i.status == 'current' ? 'Gêne actuelle' : 'Antécédent'}** : '
      '${i.label}${i.monthsAgo == null ? '' : ' (il y a ${i.monthsAgo} mois)'}, '
      'gêne actuelle ${i.discomfort}/10.',
    );
  }
  if (p.breakWeeks > 0) {
    out.add(
      '- **Coupure** : ${p.breakWeeks} semaines sans entraînement juste '
      'avant ce programme.',
    );
  }
  final r = p.recovery;
  final life = <String>[
    if (r.sleepHours != null) 'sommeil ${_num(r.sleepHours!)} h par nuit',
    if (r.sleepQuality != null) 'qualité du sommeil ${r.sleepQuality}/5',
    if (r.stress != null) 'stress de vie ${r.stress}/5',
    if (r.physicalJob == 'heavy') 'travail physique lourd',
    if (r.physicalJob == 'moderate') 'travail physique modéré',
    if (r.energyDeficit) 'en déficit énergétique (perte de poids voulue)',
    for (final s in r.otherSports)
      '${s.sport} ${s.sessionsPerWeek} × ${s.minutesPerSession} min par '
          'semaine',
  ];
  if (life.isNotEmpty) {
    out.add('- **Récupération et vie** : ${life.join(' ; ')}.');
  }
  final screening = core['healthScreening'];
  if (screening is Map<String, Object?>) {
    final outcome = screening['outcome'];
    out.add(
      '- **Questionnaire santé** : '
      '${outcome == 'cautious' ? 'mode prudent' : (outcome == 'standard' ? 'rien à signaler' : 'non répondu')}.',
    );
  }
  return out;
}

String _row(List<String> cells) => '| ${cells.join(' | ')} |';

/// Nature d'une semaine : son intention quand le moteur la donne, sinon
/// sa nature 0.1.
String weekLabel(WeekView w) {
  final intent = w.intent;
  return intent == null ? weekKindLabel(w.kind) : weekIntentLabel(intent);
}

/// Programme lu, en Markdown : profil, vue d'ensemble, puis semaine par
/// semaine, séance par séance.
String programMarkdown(ProgramView view) {
  final p = view.program.bench;
  final catalog = view.catalog;
  final b = StringBuffer()
    ..writeln('# Programme — ${p.title}')
    ..writeln()
    ..writeln(p.summary)
    ..writeln()
    ..writeln('## Profil')
    ..writeln();
  for (final line in profileLines(p, catalog)) {
    b.writeln(line);
  }
  b
    ..writeln()
    ..writeln('## Vue d\'ensemble')
    ..writeln()
    ..writeln(
      '${view.weeks.length} semaines, '
      '${view.weeks.isEmpty ? 0 : view.weeks.first.days.length} séances par '
      'semaine. « Séries dures » : séries de renforcement à 4 répétitions '
      'en réserve ou moins.',
    )
    ..writeln()
    ..writeln(
      _row(<String>['Semaine', 'Bloc', 'Nature', 'Séances', 'Séries dures']),
    )
    ..writeln(_row(<String>['---', '---', '---', '---', '---']));
  final event = p.mainEvent;
  for (final w in view.weeks) {
    final mark = event != null && event.weeksOut - 1 == w.index
        ? ' — ÉCHÉANCE'
        : '';
    b.writeln(
      _row(<String>[
        '${w.index + 1}',
        '${w.blockIndex + 1}',
        '${weekLabel(w)}$mark',
        '${w.days.length}',
        w.hardSets.toStringAsFixed(0),
      ]),
    );
  }
  final season = seasonLines(view);
  if (season.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Saison')
      ..writeln();
    season.forEach(b.writeln);
  }
  final ladders = ladderLines(view);
  if (ladders.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Échelles des figures')
      ..writeln();
    ladders.forEach(b.writeln);
  }
  final rules = programRules(view);
  if (rules.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Règles du programme')
      ..writeln();
    for (final r in rules) {
      b.writeln('- $r');
    }
  }
  for (final w in view.weeks) {
    b
      ..writeln()
      ..writeln(
        '## Semaine ${w.index + 1} — ${weekLabel(w)} '
        '(bloc ${w.blockIndex + 1})',
      );
    for (final d in w.days) {
      final stress = d.stress;
      b
        ..writeln()
        ..writeln(
          '### ${weekdayNames[d.weekday - 1]} — ${focusLabel(d.focus)}'
          '${stress == null ? '' : ', ${dayStressLabel(stress)}'} '
          '(${d.minutesBudget} min disponibles, '
          '${d.estimatedMinutes.round()} min estimées)',
        )
        ..writeln()
        ..writeln(
          _row(<String>[
            'Exercice',
            'Séries × répétitions',
            'Charge',
            'Effort visé',
            'Repos',
            'Notes',
          ]),
        )
        ..writeln(_row(<String>['---', '---', '---', '---', '---', '---']));
      for (final i in d.items) {
        final rest = i.p.technique?.kind == SetTechniqueKind.emom
            ? null
            : i.p.restSeconds;
        b.writeln(
          _row(<String>[
            i.exercise.name,
            volumeText(i),
            loadText(i),
            effortText(i),
            rest == null || rest == 0 ? '—' : _duration(rest),
            notesText(i, catalog),
          ]),
        );
      }
    }
  }
  return b.toString();
}

/// Programme lu, en objet JSON (page de relecture, comparaison aux
/// références hors dépôt).
Map<String, Object?> programJson(ProgramView view) {
  final p = view.program.bench;
  final catalog = view.catalog;
  return <String, Object?>{
    'key': p.key,
    'title': p.title,
    'summary': p.summary,
    'group': p.group,
    'level': p.level.code,
    'profile': profileLines(p, catalog),
    'eventWeek': p.mainEvent?.weeksOut,
    'season': seasonLines(view),
    'ladders': ladderLines(view),
    'rules': programRules(view),
    'weeks': <Object?>[
      for (final w in view.weeks)
        <String, Object?>{
          'week': w.index + 1,
          'block': w.blockIndex + 1,
          'kind': weekLabel(w),
          'hardSets': w.hardSets.round(),
          'days': <Object?>[
            for (final d in w.days)
              <String, Object?>{
                'day': weekdayNames[d.weekday - 1],
                'focus':
                    '${focusLabel(d.focus)}'
                    '${d.stress == null ? '' : ', ${dayStressLabel(d.stress!)}'}',
                'minutes': d.minutesBudget,
                'estimated': d.estimatedMinutes.round(),
                'items': <Object?>[
                  for (final i in d.items)
                    <String, Object?>{
                      'name': i.exercise.name,
                      'id': i.exercise.id,
                      'volume': volumeText(i),
                      'scheme': i.scheme,
                      'load': loadText(i),
                      'effort': effortText(i),
                      // Départs au chrono : le repos est ce qui reste de
                      // l'intervalle, pas une consigne à part.
                      'rest': i.p.technique?.kind == SetTechniqueKind.emom
                          ? null
                          : i.p.restSeconds,
                      'notes': notesText(i, catalog),
                    },
                ],
              },
          ],
        },
    ],
  };
}

/// Trajectoire simulée, en Markdown : semaine par semaine, pour chaque
/// exercice suivi, charges, performances, écarts, puis décisions du moteur.
String trajectoryMarkdown(Trajectory t, Catalog catalog) {
  final p = t.profile;
  final m = t.metrics;
  final b = StringBuffer()
    ..writeln('# Trajectoire simulée — ${p.title}')
    ..writeln()
    ..writeln(
      'Un athlète simulé (capacités réelles connues du simulateur, pas du '
      'moteur) suit le programme pendant ${t.weeks} semaines ; le moteur '
      'd\'évolution règle chaque séance, fait le point chaque semaine et '
      'applique ses propositions.',
    )
    ..writeln()
    ..writeln('## Profil')
    ..writeln();
  for (final line in profileLines(p, catalog)) {
    b.writeln(line);
  }
  b
    ..writeln()
    ..writeln('## Bilan')
    ..writeln()
    ..writeln(
      '- Séances faites : ${m['sessionsDone']} sur ${m['sessionsPlanned']} '
      '(${m['sessionsAdjusted']} ajustées le jour même).',
    )
    ..writeln(
      '- Séries de travail : ${m['workSets']} ; échecs non voulus (après '
      'les trois premières séances de chaque exercice) : '
      '${_percent(m['unwantedFailureRate'])} ; séries finies au bord de '
      'l\'échec alors que la cible laissait au moins 2 répétitions : '
      '${_percent(m['nearFailureRate'])}.',
    )
    ..writeln(
      '- Écart moyen entre l\'effort visé et l\'effort réel : '
      '${m['rirGapReachable']} répétition en réserve sur les séries dont '
      'la cible est atteignable (${_percent(m['reachableShare'])} des '
      'séries), ${m['rirGapAll']} sur toutes.',
    )
    ..writeln(
      '- Plus forte hausse de charge d\'une séance à l\'autre sur un '
      'mouvement principal : ${_percent(m['maxMainLoadRise'])} ; hausses '
      'de plus de 10 % faites de plusieurs crans : '
      '${m['mainRisesOverTenPercent']}.',
    );
  final gain = m['meanWeeklyGainPercent'];
  if (gain != null) {
    b.writeln(
      '- Progression réelle moyenne des mouvements suivis : $gain % par '
      'semaine.',
    );
  }
  if ((m['eventTargets'] as int? ?? 0) > 0) {
    final ratio = m['meanEventPerformance'];
    b.writeln(
      ratio == null
          ? '- Échéance : aucun des mouvements visés n\'est fait la '
                'semaine de l\'échéance.'
          : '- Échéance : ${m['eventTargetsTested']} mouvement(s) visé(s) '
                'sur ${m['eventTargets']} faits la semaine de l\'échéance ; '
                'meilleure série à ${_percent(ratio)} de la meilleure des '
                'semaines précédentes.',
    );
  }
  final proposals = m['proposalsApplied'];
  if (proposals is Map<String, int> && proposals.isNotEmpty) {
    b.writeln(
      '- Propositions appliquées : '
      '${proposals.entries.map((e) => '${_proposalLabel(e.key)} × ${e.value}').join(', ')}.',
    );
  } else {
    b.writeln('- Propositions appliquées : aucune.');
  }
  b
    ..writeln()
    ..writeln('## Semaine par semaine')
    ..writeln();
  for (final id in t.mainExerciseIds) {
    final name = catalog.find(id)?.name ?? id;
    b
      ..writeln('### $name')
      ..writeln()
      ..writeln(
        _row(<String>[
          'Semaine',
          'Nature',
          'Séries',
          'Meilleure série',
          'Effort visé → réel (rép. en réserve)',
          'Échecs',
          'Capacité réelle',
          'Capacité estimée',
        ]),
      )
      ..writeln(
        _row(<String>['---', '---', '---', '---', '---', '---', '---', '---']),
      );
    for (final r in t.rows) {
      if (r.exerciseId != id) {
        continue;
      }
      final load = r.topLoadKg;
      b.writeln(
        _row(<String>[
          '${r.week + 1}',
          weekKindLabel(r.weekKind),
          '${r.sets}',
          '${r.topAmount}${load == null ? '' : ' à ${_num(load)} kg'}',
          '${_num(r.meanWantRir)} → ${_num(r.meanTrueRir)}',
          '${r.failures}',
          r.truth == null ? '—' : _num(r.truth!),
          r.estimate == null ? '—' : _num(r.estimate!),
        ]),
      );
    }
    b.writeln();
  }
  b
    ..writeln('## Décisions du moteur')
    ..writeln();
  if (t.run.proposals.isEmpty) {
    b.writeln('Aucune proposition appliquée.');
  } else {
    for (final pr in t.run.proposals) {
      b.writeln(
        '- Semaine ${pr.week + 1} : ${_proposalLabel(pr.kind.code)} '
        '(${pr.changes} changement${pr.changes > 1 ? 's' : ''} au '
        'programme).',
      );
    }
  }
  final unlock = m['unlockWeek'];
  if (unlock is Map<String, Object?> && unlock.isNotEmpty) {
    b
      ..writeln()
      ..writeln(
        'Niveaux de proposition débloqués : '
        '${unlock.entries.map((e) => '${_unlockLabel(e.key)} dès la semaine ${e.value}').join(' ; ')}.',
      );
  }
  return b.toString();
}

String _percent(Object? value) =>
    value is num ? '${_num(value.toDouble() * 100)} %' : '—';

String _proposalLabel(String code) => switch (code) {
  'load' => 'charge',
  'reps' => 'répétitions',
  'volume' => 'volume',
  'exercise_swap' => 'échange d\'exercice',
  'session_restructure' => 'restructuration d\'une séance',
  'block_restructure' => 'restructuration du bloc',
  'deload' => 'décharge',
  'pain_sparing' => 'zone douloureuse épargnée',
  'schedule' => 'calendrier',
  _ => code,
};

String _unlockLabel(String code) => switch (code) {
  'loads_reps' => 'charges et répétitions',
  'volume' => 'volume',
  'exercise_swap' => 'échanges d\'exercices',
  'session_restructure' => 'restructuration de séance',
  'block_restructure' => 'restructuration de bloc',
  _ => code,
};
