/// Export lisible : ce que voient le panel de coachs et la page de
/// relecture. Français, sans code ni identifiant technique.
library;

import 'package:kalis_core/kalis_core.dart';

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
    return '${p.sets} × ${meters.round()} m';
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
    parts.add('≈ ${(percent * 100).round()} % du 1RM (charge totale)');
  }
  if (p.toCalibrate) {
    parts.add('à calibrer');
  }
  return parts.isEmpty ? '—' : parts.join(', ');
}

/// Effort visé d'une prescription.
String effortText(ItemView i) {
  final flames = i.p.targetFlames;
  if (flames == null) {
    return '—';
  }
  final rir = Flames.toRir(flames);
  if (flames >= Flames.failure) {
    return 'effort maximal (10/10)';
  }
  final text = rir == rir.roundToDouble() ? rir.toStringAsFixed(0) : _num(rir);
  return '$text rép. en réserve ($flames/10)';
}

/// Notes de coach d'une prescription : rôle, épreuve, format, détail des
/// séries quand elles diffèrent.
String notesText(ItemView i, Catalog catalog) {
  final p = i.p;
  final notes = <String>[];
  final role = roleLabel(i.role);
  if (role.isNotEmpty) {
    notes.add(role);
  }
  if (p.kind == SetKind.test) {
    notes.add('ÉPREUVE');
  } else if (p.kind == SetKind.calibration) {
    notes.add('série de calibrage');
  } else if (p.kind == SetKind.warmup) {
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
  return notes.join(' ; ');
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
    GoalMetric.timeSeconds =>
      '$name : ${t.distanceMeters == null ? '' : '${t.distanceMeters!.round()} m '}'
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
        '${weekKindLabel(w.kind)}$mark',
        '${w.days.length}',
        w.hardSets.toStringAsFixed(0),
      ]),
    );
  }
  for (final w in view.weeks) {
    b
      ..writeln()
      ..writeln(
        '## Semaine ${w.index + 1} — ${weekKindLabel(w.kind)} '
        '(bloc ${w.blockIndex + 1})',
      );
    for (final d in w.days) {
      b
        ..writeln()
        ..writeln(
          '### ${weekdayNames[d.weekday - 1]} — ${focusLabel(d.focus)} '
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
        final rest = i.p.restSeconds;
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
    'weeks': <Object?>[
      for (final w in view.weeks)
        <String, Object?>{
          'week': w.index + 1,
          'block': w.blockIndex + 1,
          'kind': weekKindLabel(w.kind),
          'hardSets': w.hardSets.round(),
          'days': <Object?>[
            for (final d in w.days)
              <String, Object?>{
                'day': weekdayNames[d.weekday - 1],
                'focus': focusLabel(d.focus),
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
                      'rest': i.p.restSeconds,
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
          '${r.topAmount}${load == null ? '' : ' à ${load >= 0 ? '+' : ''}${_num(load)} kg'}',
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
