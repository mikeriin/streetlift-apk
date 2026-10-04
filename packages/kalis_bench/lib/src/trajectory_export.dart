/// Export lisible d'une trajectoire sur un programme au contrat 0.4.0 :
/// semaine par semaine, ce que le bloc écrit, ce que le moteur d'évolution
/// sert, ce que l'athlète fait, et les décisions du moteur avec leurs
/// raisons. Français, sans code ni identifiant technique.
library;

import 'package:kalis_adapt/kalis_adapt.dart' show CapacityMode;
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show coachPhaseLabel;

import 'analysis.dart';
import 'export.dart';
import 'trajectory.dart';

String _n(double v, [int digits = 2]) {
  var text = v.toStringAsFixed(digits);
  if (text.contains('.')) {
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
  }
  return text.replaceAll('.', ',');
}

String _pct(Object? value, [int digits = 1]) =>
    value is num ? '${_n(value.toDouble() * 100, digits)} %' : '—';

String _kg(double kg) => '${_n(kg)} kg';

String _row(List<String> cells) => '| ${cells.join(' | ')} |';

double? _num(Reason r, String key) {
  final v = r.params[key];
  return v is num ? v.toDouble() : null;
}

String _text(Reason r, String key) => '${r.params[key] ?? ''}';

String _zoneLabel(String code) => switch (code) {
  'shoulder' => 'épaule',
  'elbow' => 'coude',
  'wrist_hand' => 'poignet',
  'lower_back' => 'bas du dos',
  'knee' => 'genou',
  'hip' => 'hanche',
  'neck' => 'cou',
  'ankle_foot' => 'cheville',
  'upper_back' => 'haut du dos',
  _ => code,
};

String _techniqueLabel(String code) => switch (code) {
  'top_set_backoff' => 'série de tête puis séries allégées',
  'cluster' => 'séries fractionnées',
  'rest_pause' => 'rest-pause',
  'myo_reps' => 'myo-reps',
  'drop_set' => 'série dégressive',
  'isometric_hold' => 'maintien',
  'accentuated_eccentric' => 'descente accentuée',
  'contrast' => 'contraste',
  'wave' => 'vagues',
  'amrap' => 'série au maximum',
  'emom' => 'départs au chrono',
  'density' => 'bloc de densité',
  'ladder' => 'échelle',
  'pyramid' => 'pyramide',
  'skill_practice' => 'pratique technique',
  'for_time' => 'contre la montre',
  _ => code,
};

String _causeLabel(String code) => switch (code) {
  'failure' || 'previous_failure' => 'après un échec non prévu',
  'pain' => 'zone douloureuse',
  'health' || 'health_strong' || 'health_low' => 'bilan du jour bas',
  'cap' => 'hausse plafonnée d\'une séance à la suivante',
  'phase' => 'semaine où le programme se sert tel quel',
  'level' => 'niveau d\'expérience insuffisant pour cette technique',
  'event' => 'échéance trop proche',
  'history' => 'antécédent sur la zone',
  'low_health' => 'bilan du jour bas',
  'uncertain' => 'maximum encore mal connu',
  'rir' => 'effort plus dur que prévu',
  'quality' => 'propreté en baisse',
  'reps' => 'répétitions en baisse',
  _ => code,
};

/// Raison du moteur d'évolution [r] en clair, ou `null` quand elle ne dit
/// rien de plus que les chiffres de la ligne.
String? adaptReasonText(Reason r, Catalog catalog) {
  String name(String key) => catalog.find(_text(r, key))?.name ?? _text(r, key);
  switch (r.code) {
    case ReasonCodes.adaptLoadHeld:
      return 'charge non augmentée (${_causeLabel(_text(r, 'cause'))})';
    case ReasonCodes.adaptRirCap:
      return 'allégé pour garder la marge prévue (au moins '
          '${_n(_num(r, 'rir') ?? 0, 1)} en réserve)';
    case ReasonCodes.adaptBackoffFromTopSet:
      return 'séries allégées calculées sur la série de tête réalisée '
          '(${_kg(_num(r, 'topLoadKg') ?? 0)}, '
          '−${_n((_num(r, 'pct') ?? 0) * 100, 1)} %)';
    case ReasonCodes.planTechniqueWithheld:
      return 'technique « ${_techniqueLabel(_text(r, 'technique'))} » non '
          'servie : ${_causeLabel(_text(r, 'cause'))} — séries classiques à '
          'la place';
    case ReasonCodes.adaptPhaseRespected:
      return 'phase « ${coachPhaseLabel(_text(r, 'phase'))} » : séances '
          'servies telles que le programme les écrit';
    case ReasonCodes.adaptTaperNoVolume:
      return 'affûtage : aucun volume ajouté, intensité gardée';
    case ReasonCodes.adaptEventNear:
      return 'échéance proche : décisions prudentes, pas de hausse au-delà '
          'du programme';
    case ReasonCodes.adaptAttemptOpener:
      return 'ouverture à ${_pct(_num(r, 'pct'))} du maximum estimé';
    case ReasonCodes.adaptAttemptNext:
      return 'barre suivante choisie pour '
          '${_pct(_num(r, 'successProbability'), 0)} de chances de réussite';
    case ReasonCodes.adaptAttemptConservative:
      return 'tentatives prudentes (${_causeLabel(_text(r, 'cause'))})';
    case ReasonCodes.adaptPacing:
      return 'rythme : ${(_num(r, 'targetReps') ?? 0).round()} répétitions '
          'visées';
    case ReasonCodes.adaptRecoveryProfile:
      final factor = switch (_text(r, 'factor')) {
        'sleep' => 'sommeil habituel court',
        'stress' => 'stress élevé',
        'occupational_load' => 'métier physique',
        'body_weight_goal' => 'perte de poids en cours',
        _ => _text(r, 'factor'),
      };
      return 'récupération réduite ($factor) : pas de volume ajouté';
    case ReasonCodes.adaptTendonLoad:
      return 'hausse du maintien bornée pour les tendons '
          '(${_zoneLabel(_text(r, 'zone'))})';
    case ReasonCodes.adaptMiniSetStop:
      return 'arrêt des séries : ${_causeLabel(_text(r, 'cause'))}';
    case ReasonCodes.adaptSkillStepUp:
      return 'étape suivante de la figure : ${name('exerciseId')}';
    case ReasonCodes.adaptSkillStepDown:
      return 'étape plus facile aujourd\'hui : ${name('exerciseId')}';
    case ReasonCodes.adaptSkillHold:
      return 'étape en cours gardée tant que le critère de passage n\'est '
          'pas rempli (${name('exerciseId')})';
    case ReasonCodes.adaptTestResult:
      return 'résultat de test retenu : ${name('exerciseId')} '
          '${_n(_num(r, 'value') ?? 0, 1)} '
          '(± ${_n(_num(r, 'standardError') ?? 0, 1)})';
    case ReasonCodes.adaptBenchmarkSet:
      return 'série repère : dernière série ouverte (au ressenti, '
          '${_n(_num(r, 'rir') ?? 0, 1)} en réserve) pour mesurer où en est '
          'l\'athlète';
    case ReasonCodes.adaptHealthLow:
      final overall = (_num(r, 'overall') ?? 0).round();
      return 'bilan du jour ${overall >= 3 ? 'moyen' : 'bas'} ($overall/5)';
    case ReasonCodes.adaptSleepLow:
      return 'nuit courte';
    case ReasonCodes.adaptTimeShort:
      return 'temps réduit '
          '(${(_num(r, 'minutesAvailable') ?? 0).round()} min au lieu de '
          '${(_num(r, 'minutesPlanned') ?? 0).round()})';
    case ReasonCodes.adaptPainReported:
      return 'douleur signalée (${_zoneLabel(_text(r, 'zone'))}, '
          '${(_num(r, 'intensity') ?? 0).round()}/10)';
    case ReasonCodes.adaptPainPersistent:
      return 'douleur qui dure (${_zoneLabel(_text(r, 'zone'))}, '
          '${(_num(r, 'sessions') ?? 0).round()} séances)';
    case ReasonCodes.adaptFatigueHigh:
      return 'fatigue accumulée élevée';
    case ReasonCodes.adaptDeload:
      return 'semaine allégée';
    case ReasonCodes.adaptPlateau:
      return 'stagnation depuis ${(_num(r, 'weeks') ?? 0).round()} semaines '
          '(${name('exerciseId')})';
    case ReasonCodes.adaptMissedSessions:
      return '${(_num(r, 'missed') ?? 0).round()} séance(s) manquée(s) sur '
          '${(_num(r, 'planned') ?? 0).round()}';
    case ReasonCodes.adaptResumeAfterBreak:
      return 'reprise après ${(_num(r, 'days') ?? 0).round()} jours '
          'd\'arrêt : charges réduites puis remontée graduelle';
    case ReasonCodes.adaptSetFailed:
      return 'série manquée la dernière fois';
    case ReasonCodes.adaptFlamesAboveTarget:
      return 'dernières séries plus dures que prévu';
    case ReasonCodes.adaptFlamesBelowTarget:
      return 'dernières séries plus faciles que prévu';
    case ReasonCodes.adaptCalibration:
      return 'calibrage (séance ${(_num(r, 'session') ?? 0).round()} sur ce '
          'mouvement)';
    case ReasonCodes.adaptIncrementCoarse:
      return 'plus petit cran de charge trop grand : progression par les '
          'répétitions';
    case ReasonCodes.adaptVolumeUp:
      return '+${(_num(r, 'sets') ?? 0).round()} série(s)';
    case ReasonCodes.adaptVolumeDown:
      return '−${(_num(r, 'sets') ?? 0).round()} série(s)';
    case ReasonCodes.adaptVolumeResponse:
      return 'volume ajusté d\'après la réponse observée';
    case ReasonCodes.adaptPlaceChanged:
      return 'lieu différent : exercices adaptés au matériel';
    case ReasonCodes.adaptExerciseSkipped:
      return 'exercice souvent sauté (${name('exerciseId')})';
  }
  return null;
}

String _adjustmentLabel(String code) => switch (code) {
  'load_reduced' => 'charges réduites',
  'sets_reduced' => 'séries retirées',
  'exercise_swapped' => 'exercice remplacé',
  'exercise_removed' => 'exercice retiré',
  'rest_increased' => 'repos allongés',
  'load_increased' => 'charge augmentée',
  _ => code.replaceAll('_', ' '),
};

String _proposalText(String code) => switch (code) {
  'load' => 'charge de départ ajustée',
  'reps' => 'répétitions ajustées',
  'volume' => 'volume ajusté',
  'exercise_swap' => 'exercice échangé',
  'session_restructure' => 'séance restructurée',
  'block_restructure' => 'bloc restructuré',
  'deload' => 'semaine de décharge avancée',
  'pain_sparing' => 'zone douloureuse épargnée',
  'schedule' => 'calendrier ajusté',
  _ => code,
};

String _truthLabel(TruthKind kind) => switch (kind) {
  TruthKind.a =>
    'modèle 1 (courbe charge-répétitions à plateau, notes d\'effort '
        'continues)',
  TruthKind.b =>
    'modèle 2 (courbe linéaire, notes d\'effort entières et plafonnées, '
        'récupération lente entre séries, tendons à adaptation lente)',
  TruthKind.c =>
    'modèle 3 (courbe en puissance, forme masquée par la fatigue, mauvais '
        'jours marqués, désentraînement rapide)',
};

ExercisePrescription? _blockItem(SimRun run, SimSession s, String slotId) {
  ProgramBlock? block;
  for (var i = 0; i < run.blocks.length; i++) {
    if (i < run.blockWeeks.length && run.blockWeeks[i] <= s.week) {
      block = run.blocks[i];
    }
  }
  if (block == null) {
    return null;
  }
  for (final w in block.pass2.weeks) {
    if (w.weekIndex != s.weekInBlock) {
      continue;
    }
    for (final d in w.days) {
      if (d.dayIndex != s.plan.dayIndex) {
        continue;
      }
      for (final it in d.items) {
        if (it.slotId == slotId) {
          return it;
        }
      }
    }
  }
  return null;
}

String _written(ExercisePrescription it) {
  final hold = it.secondsHigh != null || it.secondsLow != null;
  final low = hold ? it.secondsLow : it.repsLow;
  final high = hold ? it.secondsHigh : it.repsHigh;
  final amount = low == null && high == null
      ? ''
      : (low == null || high == null || low == high
            ? '${high ?? low}'
            : '$low à $high');
  final b = StringBuffer('${it.sets} × $amount${hold ? ' s' : ''}');
  final pct = it.intensity?.basis == IntensityBasis.percentOneRm
      ? it.intensity!.value
      : it.percentOfOneRm;
  if (pct != null) {
    b.write(' à ${_n(pct * 100, 0)} %');
  } else if (it.intensity?.basis == IntensityBasis.percentBenchmark) {
    b.write(' (${_n(it.intensity!.value * 100, 0)} % du maximum testé)');
  }
  final kind = it.technique?.kind;
  if (kind != null && kind != SetTechniqueKind.standard) {
    b.write(', ${_techniqueLabel(kind.code)}');
  }
  if (it.kind == SetKind.test) {
    b.write(', test');
  }
  return b.toString();
}

String _done(List<SetRow> sets, bool hold) {
  if (sets.isEmpty) {
    return 'non fait';
  }
  final parts = <String>[];
  var i = 0;
  while (i < sets.length) {
    final load = sets[i].loadKg;
    var j = i;
    final amounts = <String>[];
    while (j < sets.length && sets[j].loadKg == load) {
      final s = sets[j];
      final mark = s.failed
          ? (s.attempt ? ' (manquée)' : ' (échec)')
          : (s.amount < s.targetLow && !s.test
                ? ' (arrêt avant la cible)'
                : '');
      amounts.add('${s.amount}$mark');
      j++;
    }
    parts.add(
      '${amounts.join('-')}${hold ? ' s' : ''}'
      '${load == null || load == 0 ? '' : ' à ${_kg(load)}'}',
    );
    i = j;
  }
  return parts.join(' puis ');
}

/// Trajectoire simulée d'un programme au contrat 0.4.0, en Markdown.
/// [others] : la même trajectoire sous les autres modèles de vérité.
String coachTrajectoryMarkdown(
  Trajectory t,
  Catalog catalog, {
  List<Trajectory> others = const <Trajectory>[],
}) {
  final p = t.profile;
  final m = t.metrics;
  final run = t.run;
  final bodyWeight = p.bodyWeightKg ?? defaultBodyWeightKg;
  String name(String id) => catalog.find(id)?.name ?? id;
  final b = StringBuffer()
    ..writeln('# Trajectoire simulée — ${p.title}')
    ..writeln()
    ..writeln(
      'Un athlète simulé (capacités réelles connues du simulateur, jamais '
      'du moteur) suit le programme pendant ${t.weeks} semaines. Avant '
      'chaque séance, le moteur d\'évolution règle les charges, les '
      'répétitions et les techniques d\'après le journal, le bilan du jour '
      'et la phase ; après chaque série il conseille la suivante ; chaque '
      'fin de semaine il fait le point, reporte les résultats de test et '
      'transmet ses estimations au bloc suivant. Athlète simulé : '
      '${_truthLabel(t.truth)}.',
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
      '- Échecs non voulus (hors tests et tentatives) : '
      '${_pct(m['coachFailureRate'])} des séries de travail.',
    )
    ..writeln(
      '- Écart moyen entre l\'effort affiché par le moteur et l\'effort '
      'réel : ${_n((m['effortGap'] as num? ?? 0).toDouble())} répétition en '
      'réserve (sur les ${_pct(m['effortReachableShare'], 0)} de séries dont '
      'la cible est atteignable avec le matériel ; séries « 5 en réserve et '
      'plus » : seul un effort plus dur compte) ; '
      'séries au moins 2 répétitions plus dures que visé : '
      '${_pct(m['harderRate'])} ; au moins 3 plus faciles : '
      '${_pct(m['easierRate'])}.',
    )
    ..writeln(
      '- Plus forte hausse de charge totale d\'un mouvement principal d\'une '
      'séance à la suivante, à schéma égal : ${_pct(m['maxSchemeRise'])} ; '
      'hausses de plus de 10 % faites de plusieurs crans : '
      '${m['schemeRisesOverLimit']}.',
    );
  final gain = m['meanWeeklyGainPercent'];
  if (gain is num) {
    b.writeln(
      '- Progression réelle moyenne des mouvements suivis : '
      '${_n(gain.toDouble(), 3)} % par semaine.',
    );
  }
  final attempts = m['attempts'];
  if (attempts is int && attempts > 0) {
    b.writeln(
      '- Tentatives de maximum : ${m['attemptsMade']} réussies sur '
      '$attempts ; ouvertures réussies : ${_pct(m['openerRate'], 0)}.',
    );
  }
  final event = m['eventOverDayMax'];
  if (event is num) {
    b.writeln(
      '- Jour de l\'échéance : meilleure performance à ${_pct(event)} du '
      'maximum réel du jour (moyenne des mouvements).',
    );
  }
  b.writeln(
    '- Douleur : ${run.painAggravations} hausse(s) de charge sur une zone '
    'douloureuse signalée.',
  );

  // Séances par semaine.
  final byWeek = <int, List<SimSession>>{};
  for (final s in run.served) {
    byWeek.putIfAbsent(s.week, () => <SimSession>[]).add(s);
  }
  final rowsOf = <String, List<SetRow>>{};
  for (final r in run.sets) {
    rowsOf.putIfAbsent('${r.simDay}|${r.exerciseId}', () => <SetRow>[]).add(r);
  }

  b
    ..writeln()
    ..writeln('## Mouvements suivis, semaine par semaine')
    ..writeln()
    ..writeln(
      'Pour chaque mouvement, la séance la plus lourde de la semaine : ce '
      'que le programme écrit, ce que le moteur sert et ce que l\'athlète '
      'fait, l\'effort affiché par le moteur et l\'effort réel (répétitions '
      'en réserve ; première série, puis moyenne des suivantes), le '
      'maximum réel et le maximum estimé par le moteur (1RM de charge '
      'totale, répétitions ou secondes), puis les décisions du moteur.',
    )
    ..writeln();
  // Étapes de figure : les exercices travaillés pour une figure visée
  // sont suivis dans le tableau de la figure.
  final stepsOf = <String, Set<String>>{};
  for (final block in run.blocks) {
    for (final w in block.pass2.weeks) {
      for (final d in w.days) {
        for (final it in d.items) {
          final target = it.skillTargetId;
          if (target != null) {
            stepsOf.putIfAbsent(target, () => <String>{}).add(it.exerciseId);
          }
        }
      }
    }
  }
  // Une figure visée par le profil et travaillée seulement par ses étapes
  // a aussi son tableau.
  final shown = <String>[
    ...t.mainExerciseIds,
    for (final id in t.profile.priorityIds)
      if (!t.mainExerciseIds.contains(id) && stepsOf.containsKey(id)) id,
  ];
  for (final id in shown) {
    final ids = <String>{id, ...?stepsOf[id]};
    var covered = false;
    for (final e in stepsOf.entries) {
      if (e.key != id && e.value.contains(id) && shown.contains(e.key)) {
        // Étape d'une figure suivie par ailleurs : dans son tableau.
        covered = true;
      }
    }
    if (covered) {
      continue;
    }
    final fraction = catalog.find(id)?.bodyweightFraction?.value ?? 0;
    b
      ..writeln(
        '### ${name(id)}${ids.length > 1 ? ' (étapes de la figure)' : ''}',
      )
      ..writeln()
      ..writeln(
        _row(<String>[
          'Sem.',
          'Phase',
          'Écrit par le programme',
          'Fait (séance la plus lourde)',
          'Effort visé → réel',
          'Maximum réel / estimé',
          'Décisions du moteur',
        ]),
      )
      ..writeln(
        _row(<String>['---', '---', '---', '---', '---', '---', '---']),
      );
    for (var w = 0; w < t.weeks; w++) {
      SimSession? best;
      var bestLoad = -1.0;
      ExercisePrescription? bestItem;
      for (final s in byWeek[w] ?? const <SimSession>[]) {
        for (final it in s.plan.items) {
          if (!ids.contains(it.exerciseId)) {
            continue;
          }
          var top = 0.0;
          for (final r in s.record.sets) {
            if (r.exerciseId == it.exerciseId &&
                (r.externalLoadKg ?? 0) > top) {
              top = r.externalLoadKg ?? 0;
            }
          }
          if (best == null || top > bestLoad) {
            best = s;
            bestLoad = top;
            bestItem = it;
          }
        }
      }
      if (best == null || bestItem == null) {
        continue;
      }
      // Décisions de la séance montrée (et conseils d'entre-séries).
      final notes = <String>[];
      void note(Reason r) {
        final text = adaptReasonText(r, catalog);
        if (text != null && !notes.contains(text)) {
          notes.add(text);
        }
      }

      final served = bestItem.exerciseId;
      bestItem.reasons.forEach(note);
      for (final a in best.advices) {
        if (a.exerciseId == served) {
          a.reasons.forEach(note);
        }
      }
      final rows = rowsOf['${best.simDay}|$served'] ?? const <SetRow>[];
      final hold = rows.isNotEmpty && rows.first.mode == CapacityMode.hold;
      // Effort de la première ligne, puis des suivantes.
      String effort(List<SetRow> part) {
        var want = 0.0;
        var real = 0.0;
        var open = false;
        for (final r in part) {
          want += r.wantRir;
          real += r.trueRir;
          open = open || r.openTarget;
        }
        return '${_n(want / part.length, 1)}${open ? '+' : ''} → '
            '${_n(real / part.length, 1)}';
      }

      final work = <SetRow>[
        for (final r in rows)
          if (!r.test) r,
      ];
      double? dayMax;
      for (final r in rows) {
        dayMax = r.dayMax;
      }
      final effortText = work.isEmpty
          ? (rows.isEmpty ? '—' : 'test')
          : (work.length == 1
                ? effort(work)
                : '${effort(work.sublist(0, 1))} ; suivantes '
                      '${effort(work.sublist(1))}');
      double? estimate;
      for (final e in run.estimates) {
        if (e.week == w && e.exerciseId == served) {
          estimate = e.capacity;
        }
      }
      final written = _blockItem(run, best, bestItem.slotId);
      final loaded = rows.isNotEmpty && rows.first.mode == CapacityMode.loaded;
      String max(double? v) {
        if (v == null) {
          return '—';
        }
        if (!loaded) {
          return _n(v, 0);
        }
        final ext = v - fraction * bodyWeight;
        return '${_n(v, 0)}${fraction > 0 ? ' (lest ${_n(ext, 0)})' : ''}';
      }

      final intent = best.plan.weekIntent;
      b.writeln(
        _row(<String>[
          '${w + 1}',
          intent == null
              ? weekKindLabel(best.weekKind)
              : coachPhaseLabel(intent.code),
          written == null ? '—' : _written(written),
          '${served == id ? '' : '${name(served)} : '}${_done(rows, hold)}',
          effortText,
          '${max(dayMax)} / ${max(estimate)}',
          notes.isEmpty ? '—' : notes.take(4).join(' ; '),
        ]),
      );
    }
    b.writeln();
  }

  // Journal des décisions, semaine par semaine.
  b
    ..writeln('## Journal des décisions')
    ..writeln();
  final reviewOf = <int, AdaptReview>{
    for (final (w, review) in run.reviews) w: review,
  };
  final proposalsOf = <int, List<ProposalRow>>{};
  for (final pr in run.proposals) {
    proposalsOf.putIfAbsent(pr.week, () => <ProposalRow>[]).add(pr);
  }
  final seenTests = <String>{};
  final onceSaid = <String>{};
  final steps = <String, String>{};
  for (var w = 0; w < t.weeks; w++) {
    final lines = <String>[];
    final sessions = byWeek[w] ?? const <SimSession>[];
    var planned = 0;
    for (final s in run.blocks) {
      planned = s.pass1.days.length;
    }
    if (sessions.length < planned) {
      lines.add(
        '${planned - sessions.length} séance(s) manquée(s) sur $planned',
      );
    }
    final sessionNotes = <String, int>{};
    final adjusted = <String, Set<String>>{};
    for (final s in sessions) {
      for (final r in s.plan.reasons) {
        // Un bilan moyen (3 sur 5) ne change rien ; « charge non
        // augmentée » redit le bilan bas déjà noté.
        if (r.code == ReasonCodes.adaptLoadHeld ||
            (r.code == ReasonCodes.adaptHealthLow &&
                (_num(r, 'overall') ?? 0) >= 3)) {
          continue;
        }
        final text = adaptReasonText(r, catalog);
        if (text != null) {
          sessionNotes[text] = (sessionNotes[text] ?? 0) + 1;
        }
      }
      for (final a in s.plan.adjustments) {
        final causes = <String>[
          for (final r in a.reasons)
            if (adaptReasonText(r, catalog) != null)
              adaptReasonText(r, catalog)!,
        ];
        final key =
            '${_adjustmentLabel(a.kind.code)}'
            '${causes.isEmpty ? '' : ' (${causes.join(', ')})'}';
        final id = a.exerciseId;
        adjusted.putIfAbsent(key, () => <String>{}).add(id ?? '');
      }
      for (final it in s.plan.items) {
        for (final r in it.reasons) {
          if (r.code == ReasonCodes.planTechniqueWithheld ||
              r.code == ReasonCodes.adaptSkillStepDown ||
              r.code == ReasonCodes.adaptSkillHold ||
              r.code == ReasonCodes.adaptTendonLoad) {
            final text =
                '${name(it.exerciseId)} : '
                '${adaptReasonText(r, catalog)}';
            // Dit une fois : la borne des tendons et l'étape gardée valent
            // pour les semaines qui suivent.
            final standing =
                r.code == ReasonCodes.adaptTendonLoad ||
                r.code == ReasonCodes.adaptSkillHold;
            if (standing && !onceSaid.add('${it.exerciseId}|${r.code}')) {
              continue;
            }
            sessionNotes[text] = standing ? 1 : (sessionNotes[text] ?? 0) + 1;
          }
        }
      }
      for (final a in s.advices) {
        if (a.action == IntraSessionAction.stopExercise) {
          final causes = <String>[
            for (final r in a.reasons)
              if (adaptReasonText(r, catalog) != null)
                adaptReasonText(r, catalog)!,
          ];
          final text =
              '${name(a.exerciseId)} : séries arrêtées en cours de séance'
              '${causes.isEmpty ? '' : ' (${causes.join(', ')})'}';
          sessionNotes[text] = (sessionNotes[text] ?? 0) + 1;
        }
      }
    }
    for (final e in sessionNotes.entries) {
      lines.add(e.value > 1 ? '${e.key} (× ${e.value})' : e.key);
    }
    for (final e in adjusted.entries) {
      final ids = e.value.where((id) => id.isNotEmpty).toList();
      final at = e.key.indexOf(' (');
      final label = at < 0 ? e.key : e.key.substring(0, at);
      final causes = at < 0 ? '' : e.key.substring(at);
      lines.add(
        ids.isEmpty
            ? e.key
            : (ids.length <= 2
                  ? '$label — ${ids.map(name).join(', ')}$causes'
                  : '$label sur ${ids.length} exercices$causes'),
      );
    }
    for (final pr in proposalsOf[w] ?? const <ProposalRow>[]) {
      lines.add('proposition appliquée : ${_proposalText(pr.kind.code)}');
    }
    final review = reviewOf[w];
    if (review != null) {
      for (final test in review.testResults ?? const <Benchmark>[]) {
        final key =
            '${test.exerciseId}|${test.kind.code}|${test.date}|'
            '${test.externalLoadKg}|${test.reps}|${test.seconds}';
        if (!seenTests.add(key)) {
          continue;
        }
        final value = test.seconds != null
            ? '${test.seconds} s'
            : (test.externalLoadKg != null
                  ? '${test.reps ?? 1} × ${_kg(test.externalLoadKg!)}'
                  : '${test.reps} répétitions');
        lines.add(
          'résultat de test reporté au profil : ${name(test.exerciseId)} '
          '$value',
        );
      }
      for (final sp in review.summary.skills ?? const <SkillProgress>[]) {
        final before = steps[sp.targetExerciseId];
        if (before != null && before != sp.currentExerciseId) {
          lines.add(
            'figure ${name(sp.targetExerciseId)} : passage à l\'étape '
            '« ${name(sp.currentExerciseId)} »',
          );
        }
        steps[sp.targetExerciseId] = sp.currentExerciseId;
      }
    }
    final block = run.blockWeeks.indexOf(w);
    if (block > 0) {
      lines.insert(
        0,
        'nouveau bloc construit à partir du point de fin de bloc (maxima '
        'estimés, résultats de test, tolérance)',
      );
    }
    if (lines.isEmpty) {
      continue;
    }
    final intent = sessions.isEmpty ? null : sessions.first.plan.weekIntent;
    b.writeln(
      '- **Semaine ${w + 1}'
      '${intent == null ? '' : ' (${coachPhaseLabel(intent.code)})'}** : '
      '${lines.take(12).join(' ; ')}.',
    );
  }

  // Figures : état final.
  SummarySkills? last;
  for (final (_, review) in run.reviews) {
    final skills = review.summary.skills;
    if (skills != null && skills.isNotEmpty) {
      last = SummarySkills(skills);
    }
  }
  if (last != null) {
    b
      ..writeln()
      ..writeln('## Figures')
      ..writeln();
    for (final sp in last.skills) {
      final best = sp.bestHoldSeconds != null
          ? ', meilleur maintien ${sp.bestHoldSeconds} s'
          : (sp.bestReps != null ? ', meilleure série ${sp.bestReps}' : '');
      b.writeln(
        '- ${name(sp.targetExerciseId)} : étape « '
        '${name(sp.currentExerciseId)} » depuis ${sp.weeksAtStep} '
        'semaine(s)$best ; critère de passage '
        '${sp.criterionMet ? 'rempli' : 'pas encore rempli'}.',
      );
    }
  }

  // Tentatives.
  final attemptRows = <SetRow>[
    for (final r in run.sets)
      if (r.attempt) r,
  ];
  if (attemptRows.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Tentatives de maximum')
      ..writeln()
      ..writeln(
        _row(<String>[
          'Sem.',
          'Mouvement',
          'Barres (lest)',
          'Maximum réel du jour (lest)',
          'Meilleure barre / maximum du jour',
        ]),
      )
      ..writeln(_row(<String>['---', '---', '---', '---', '---']));
    final groups = <String, List<SetRow>>{};
    for (final r in attemptRows) {
      groups
          .putIfAbsent('${r.simDay}|${r.exerciseId}', () => <SetRow>[])
          .add(r);
    }
    for (final g in groups.values) {
      final first = g.first;
      final fraction =
          catalog.find(first.exerciseId)?.bodyweightFraction?.value ?? 0;
      var bestTotal = 0.0;
      for (final r in g) {
        if (!r.failed && r.amount >= 1 && (r.totalKg ?? 0) > bestTotal) {
          bestTotal = r.totalKg ?? 0;
        }
      }
      final dayMax = first.dayMax ?? 0;
      b.writeln(
        _row(<String>[
          '${first.week + 1}${first.eventDay ? ' (échéance)' : ''}',
          name(first.exerciseId),
          g
              .map(
                (r) =>
                    '${_n(r.loadKg ?? 0)} '
                    '${!r.failed && r.amount >= 1 ? 'réussie' : 'manquée'}',
              )
              .join(', '),
          _n(dayMax - fraction * bodyWeight, 1),
          dayMax <= 0 ? '—' : _pct(bestTotal / dayMax),
        ]),
      );
    }
  }

  if (others.isNotEmpty) {
    b
      ..writeln()
      ..writeln('## Même programme, autres athlètes simulés')
      ..writeln()
      ..writeln(
        'Le même profil et le même moteur, avec d\'autres hypothèses sur '
        'l\'athlète réel (ce que le moteur ne connaît pas).',
      )
      ..writeln()
      ..writeln(
        _row(<String>[
          'Athlète simulé',
          'Échecs non voulus',
          'Écart d\'effort',
          'Séries ≥ 2 rép. plus dures',
          'Plus forte hausse à schéma égal',
          'Progression par semaine',
          'Tentatives réussies',
          'Échéance / maximum du jour',
          'Hausses sur zone douloureuse',
        ]),
      )
      ..writeln(
        _row(<String>[
          '---',
          '---',
          '---',
          '---',
          '---',
          '---',
          '---',
          '---',
          '---',
        ]),
      );
    for (final o in <Trajectory>[t, ...others]) {
      final om = o.metrics;
      final g = om['meanWeeklyGainPercent'];
      b.writeln(
        _row(<String>[
          _truthLabel(o.truth),
          _pct(om['coachFailureRate']),
          _n((om['effortGap'] as num? ?? 0).toDouble()),
          _pct(om['harderRate']),
          _pct(om['maxSchemeRise']),
          g is num ? '${_n(g.toDouble(), 3)} %' : '—',
          (om['attempts'] as int? ?? 0) == 0
              ? '—'
              : '${om['attemptsMade']}/${om['attempts']}',
          _pct(om['eventOverDayMax']),
          '${om['painAggravations']}',
        ]),
      );
    }
  }
  return b.toString();
}

/// Étapes de figure d'un résumé d'adaptation.
final class SummarySkills {
  /// Étapes [skills].
  const SummarySkills(this.skills);

  /// Étapes.
  final List<SkillProgress> skills;
}
