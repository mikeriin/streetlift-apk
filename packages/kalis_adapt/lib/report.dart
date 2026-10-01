/// Mise en tableaux des mesures d'une campagne de simulation
/// (`bin/kalis_adapt_cli.dart`) : même entrée, même texte.
///
/// À n'importer que depuis des tests ou des outils.
library;

import 'package:kalis_core/kalis_core.dart';

import 'src/engine.dart';

String _pct(Object? v, [int digits = 1]) {
  if (v is! num) {
    return '—';
  }
  return '${(v * 100).toStringAsFixed(digits)} %';
}

String _num(Object? v, [int digits = 2]) {
  if (v is! num) {
    return '—';
  }
  return v.toStringAsFixed(digits);
}

Map<String, Object?> _map(Object? v) =>
    v is Map<String, Object?> ? v : const <String, Object?>{};

List<Object?> _list(Object? v) => v is List<Object?> ? v : const <Object?>[];

Object? _mean(Object? stat) => _map(stat)['mean'];

/// Moyenne ± demi-largeur de l'intervalle à 95 % (1,96 × erreur standard).
String _ci(Object? stat, {bool percent = false, int digits = 2}) {
  final m = _map(stat);
  final mean = m['mean'];
  final se = m['se'];
  if (mean is! num || se is! num || (m['n'] is num && m['n'] == 0)) {
    return '—';
  }
  final half = 1.96 * se;
  if (percent) {
    return '${(mean * 100).toStringAsFixed(digits)} ± '
        '${(half * 100).toStringAsFixed(digits)} %';
  }
  return '${mean.toStringAsFixed(digits)} ± ${half.toStringAsFixed(digits)}';
}

/// Noms des politiques, dans l'ordre des tableaux.
const List<String> reportPolicies = <String>[
  'kalis_adapt',
  'double_progression',
  'L7/L11',
  'oracle',
];

/// Tableaux Markdown des mesures [campaign] (l'objet écrit dans
/// `campagne.json`).
String campaignMarkdown(Map<String, Object?> campaign) {
  final out = <String>[];
  final athletes = _list(campaign['athletes']);
  final seeds = campaign['seeds'];
  final loopSeeds = campaign['loopSeeds'];
  final weeks = campaign['weeks'];
  out.addAll(<String>[
    '# kalis_adapt — mesures de la campagne de simulation',
    '',
    'Document généré par `dart run bin/kalis_adapt_cli.dart --rapport '
        '<dossier>` (moteur ${campaign['engineVersion']}) à partir de '
        '`docs/data/campagne.json` : ${athletes.length} athlètes simulés × '
        '$weeks semaines × $seeds graines × ${reportPolicies.length} '
        'politiques (dont l\'oracle) à programme égal, puis $loopSeeds graines par athlète en '
        'boucle complète. Lecture et limites : `VALIDATION.md`.',
    '',
    'Chaque valeur est la moyenne des graines ; « ± » donne la demi-largeur '
        'de l\'intervalle de confiance à 95 % (1,96 × erreur standard entre '
        'graines).',
    '',
    '## 1. Écart au RIR visé, échecs, progression',
    '',
    'Après calibrage (à partir de la 4ᵉ séance de chaque exercice), hors '
        'semaines de test. RIR MAE : écart absolu moyen '
        'entre le RIR réel et le RIR affiché, sur les séries dont la cible '
        'est atteignable — il existe une charge de la grille de l\'athlète '
        '(ou, sans charge, un nombre de répétitions) qui met le RIR visé '
        'dans la plage du bloc, étendue comme le moteur sait l\'étendre ; '
        '« Atteignable » en donne la part, « toutes séries » l\'écart sans '
        'ce tri. Biais > 0 : séries plus faciles que visé. Quasi-échec : série finie à moins de 0,5 '
        'répétition de l\'échec quand la cible en laissait au moins 2. '
        '« oracle » n\'est pas un moteur : c\'est la politique qui connaît '
        'la vérité de l\'athlète ; son écart est le plancher qu\'imposent la '
        'grille des charges, l\'arrondi des répétitions et la plage. '
        'Gain : progression moyenne de la capacité vraie par semaine, entre '
        'la première et la dernière séance de chaque exercice suivi au moins '
        'trois semaines.',
    '',
    '| Athlète | Politique | RIR MAE | Biais | Atteignable | RIR MAE '
        '(toutes séries) | Échecs non prévus | Quasi-échecs | Gain par '
        'semaine |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final policies = _map(athlete['policies']);
    for (final name in reportPolicies) {
      final m = _map(policies[name]);
      if (m.isEmpty) {
        continue;
      }
      out.add(
        '| ${athlete['key']} | $name | ${_ci(m['rirMae'])} | '
        '${_num(_mean(m['rirBias']))} | '
        '${_pct(_mean(m['reachableShare']), 0)} | '
        '${_num(_mean(m['rirMaeAll']))} | '
        '${_ci(m['failRate'], percent: true)} | '
        '${_ci(m['nearFailureRate'], percent: true)} | '
        '${_ci(m['gain'], percent: true, digits: 2)} |',
      );
    }
  }
  out.addAll(<String>[
    '',
    '### Différences appariées (mêmes graines, mêmes aléas)',
    '',
    'Moyenne de la différence `kalis_adapt − référence`, simulation par '
        'simulation. RIR MAE : négatif = `kalis_adapt` plus près de la '
        'cible. Gain : positif = `kalis_adapt` progresse plus.',
    '',
    '| Athlète | RIR MAE vs double progression | RIR MAE vs L7/L11 | '
        'Gain vs double progression | Gain vs L7/L11 |',
    '| --- | --- | --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final p = _map(athlete['paired']);
    out.add(
      '| ${athlete['key']} | ${_ci(p['rirMae_vs_double_progression'])} | '
      '${_ci(p['rirMae_vs_L7'])} | '
      '${_ci(p['gain_vs_double_progression'], percent: true, digits: 2)} | '
      '${_ci(p['gain_vs_L7'], percent: true, digits: 2)} |',
    );
  }
  out.addAll(<String>[
    '',
    '### Par nature d\'exercice (`kalis_adapt`)',
    '',
    '| Athlète | RIR MAE exercices chargés | RIR MAE poids du corps et '
        'tenues |',
    '| --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final m = _map(_map(athlete['policies'])['kalis_adapt']);
    out.add(
      '| ${athlete['key']} | ${_ci(m['rirMaeLoaded'])} | '
      '${_ci(m['rirMaeBodyweight'])} |',
    );
  }
  out.addAll(<String>[
    '',
    '## 2. Erreur de capacité',
    '',
    'Erreur relative absolue après 1, 3, 6 et 12 séances de l\'exercice. '
        'Capacité opérationnelle : charge du milieu de plage au RIR visé '
        '(ce qui sert à prescrire) ; 1RM : capacité extrapolée à une '
        'répétition. Couverture : part des estimations dont l\'intervalle '
        'annoncé à 95 % contient la vérité (cible : 95 %). La double '
        'progression n\'estime rien.',
    '',
    '| Athlète | Politique | Opér. S1 | Opér. S3 | Opér. S6 | Opér. S12 | '
        '1RM S1 | 1RM S3 | 1RM S6 | 1RM S12 | Couverture 95 % |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final policies = _map(athlete['policies']);
    for (final name in reportPolicies) {
      final m = _map(policies[name]);
      final op = _map(m['operationalError']);
      final cap = _map(m['capacityError']);
      if (op.isEmpty) {
        continue;
      }
      out.add(
        '| ${athlete['key']} | $name | ${_pct(_mean(op['1']))} | '
        '${_pct(_mean(op['3']))} | ${_pct(_mean(op['6']))} | '
        '${_pct(_mean(op['12']))} | ${_pct(_mean(cap['1']))} | '
        '${_pct(_mean(cap['3']))} | ${_pct(_mean(cap['6']))} | '
        '${_pct(_mean(cap['12']))} | ${_pct(m['coverage95'], 0)} |',
      );
    }
  }
  out.addAll(<String>[
    '',
    '## 3. Stabilité et sécurité',
    '',
    'Changements : changements de charge de première série par '
        'simulation, après calibrage. Inversions : part de ces changements '
        'qui défont le précédent. Hausse max : plus forte hausse de charge '
        'totale d\'une séance à l\'autre sur un mouvement principal, après '
        'calibrage (un seul cran de grille peut dépasser 10 % quand le plus '
        'petit cran du matériel est plus grand). Aggravations : hausses de '
        'charge sur une zone signalée douloureuse.',
    '',
    '| Athlète | Politique | Changements | Inversions | Hausse max '
        '(principal) | Hausses > 10 % | Séances ajustées | Aggravations |',
    '| --- | --- | --- | --- | --- | --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final policies = _map(athlete['policies']);
    for (final name in reportPolicies) {
      final m = _map(policies[name]);
      if (m.isEmpty) {
        continue;
      }
      out.add(
        '| ${athlete['key']} | $name | ${_num(_mean(m['loadMoves']), 1)} | '
        '${_pct(_mean(m['reversalRate']))} | ${_pct(m['maxMainRise'])} | '
        '${m['mainRisesOverTen']} | '
        '${_pct(_mean(m['sessionsAdjustedShare']))} | '
        '${_num(_mean(m['painAggravations']))} |',
      );
    }
  }
  out.addAll(<String>[
    '',
    '## 4. Boucle complète (`kalis_adapt`, mode assisté)',
    '',
    'Revue chaque fin de semaine, propositions appliquées, bloc suivant '
        'construit par `kalis_plan` à partir du résumé d\'adaptation. '
        'Propositions : nombre moyen par simulation de $weeks semaines. '
        'Déblocage : semaine moyenne où le niveau est atteint.',
    '',
    '| Athlète | RIR MAE | Gain | Volume | Décharge | Échange | Douleur | '
        'Séance | Bloc | Volume inversé |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  ]);
  for (final a in athletes) {
    final athlete = _map(a);
    final loop = _map(athlete['loop']);
    if (loop.isEmpty) {
      continue;
    }
    final base = _map(loop['base']);
    final p = _map(loop['proposals']);
    out.add(
      '| ${athlete['key']} | ${_ci(base['rirMae'])} | '
      '${_ci(base['gain'], percent: true, digits: 2)} | '
      '${_num(_mean(p['volume']), 1)} | ${_num(_mean(p['deload']), 1)} | '
      '${_num(_mean(p['exercise_swap']), 1)} | '
      '${_num(_mean(p['pain_sparing']), 1)} | '
      '${_num(_mean(p['session_restructure']), 1)} | '
      '${_num(_mean(p['block_restructure']), 1)} | '
      '${_pct(_mean(loop['volumeFlipRate']))} |',
    );
  }
  out.addAll(<String>[
    '',
    '| Athlète | Volume | Échange d\'exercice | Restructuration de séance | '
        'Restructuration de bloc |',
    '| --- | --- | --- | --- | --- |',
  ]);
  String unlock(Map<String, Object?> u, String code, Object? runs) {
    final s = _map(u[code]);
    final n = s['n'];
    if (n is! num || n == 0) {
      return 'jamais';
    }
    return 'semaine ${_num(s['mean'], 1)} ($n/$runs)';
  }

  for (final a in athletes) {
    final athlete = _map(a);
    final loop = _map(athlete['loop']);
    if (loop.isEmpty) {
      continue;
    }
    final u = _map(loop['unlockWeek']);
    final runs = loop['runs'];
    out.add(
      '| ${athlete['key']} | ${unlock(u, 'volume', runs)} | '
      '${unlock(u, 'exercise_swap', runs)} | '
      '${unlock(u, 'session_restructure', runs)} | '
      '${unlock(u, 'block_restructure', runs)} |',
    );
  }
  final timings = _map(campaign['timings']);
  if (timings.isNotEmpty) {
    out.addAll(<String>[
      '',
      '## 5. Temps de calcul',
      '',
      'Mesurés par le simulateur sur la machine de contrôle (le moteur n\'a '
          'pas d\'horloge), sur ${timings['sessions']} séances et '
          '${timings['advices']} conseils de l\'athlète '
          '`${timings['athlete']}`. « À froid » : premier appel, tout le '
          'journal rejoué (${timings['coldSessions']} séances).',
      '',
      '| Opération | Médiane | 95ᵉ centile | Maximum | Cible |',
      '| --- | --- | --- | --- | --- |',
    ]);
    void row(String label, String key, String target) {
      final t = _map(timings[key]);
      out.add(
        '| $label | ${_num(t['median'], 2)} ms | ${_num(t['p95'], 2)} ms | '
        '${_num(t['max'], 2)} ms | $target |',
      );
    }

    row('Décision de séance (`prescribeSession`)', 'prescribe', '≤ 50 ms');
    row('Mise à jour après une série (`adviseNextSet`)', 'advise', '≤ 5 ms');
    row('Revue (`review`)', 'review', '—');
    row('Décision de séance à froid', 'cold', '—');
  }
  out.add('');
  return out.join('\n');
}

/// Points (rang de séance, erreur) de la courbe de convergence d'une
/// politique pour un athlète de [campaign], ou une liste vide.
List<(int, double)> convergenceOf(
  Map<String, Object?> campaign,
  String athlete,
  String policy,
) {
  for (final a in _list(campaign['athletes'])) {
    final m = _map(a);
    if (m['key'] != athlete) {
      continue;
    }
    final values = _list(_map(_map(m['policies'])[policy])['convergence']);
    return <(int, double)>[
      for (var i = 0; i < values.length; i++)
        if (values[i] is num) (i + 1, (values[i] as num).toDouble()),
    ];
  }
  return const <(int, double)>[];
}

String _reasons(List<Reason> reasons) {
  if (reasons.isEmpty) {
    return '—';
  }
  return reasons
      .map((r) {
        if (r.params.isEmpty) {
          return '`${r.code}`';
        }
        final keys = r.params.keys.toList()..sort();
        return '`${r.code}`(${keys.map((k) => '$k=${r.params[k]}').join(', ')})';
      })
      .join(' ; ');
}

String _kg(double? v) {
  if (v == null) {
    return '—';
  }
  final rounded = (v * 100).roundToDouble() / 100;
  return rounded == rounded.roundToDouble()
      ? '${rounded.toStringAsFixed(0)} kg'
      : '$rounded kg';
}

String _unit(CapacityUnit unit) {
  switch (unit) {
    case CapacityUnit.oneRmKg:
      return 'kg (1RM, charge totale)';
    case CapacityUnit.maxReps:
      return 'répétitions max';
    case CapacityUnit.maxHoldSeconds:
      return 's (tenue max)';
    case CapacityUnit.metersPerSecond:
      return 'm/s';
  }
}

/// Ligne d'une prescription d'exercice (séries, cible, charge).
String prescriptionText(Catalog catalog, ExercisePrescription item) {
  final name = catalog.find(item.exerciseId)?.name ?? item.exerciseId;
  final targets = item.setTargets;
  final parts = <String>[];
  if (targets != null && targets.isNotEmpty) {
    for (final t in targets) {
      final amount = t.secondsHigh != null
          ? (t.secondsLow == t.secondsHigh
                ? '${t.secondsHigh} s'
                : '${t.secondsLow}–${t.secondsHigh} s')
          : (t.repsLow == t.repsHigh
                ? '${t.repsHigh}'
                : '${t.repsLow}–${t.repsHigh}');
      final load = t.loadKg == null ? '' : ' @ ${_kg(t.loadKg)}';
      final flames = t.flames == null ? '' : ' (${t.flames} fl.)';
      parts.add('$amount$load$flames');
    }
  } else {
    final amount = item.secondsHigh != null
        ? '${item.secondsLow}–${item.secondsHigh} s'
        : (item.repsHigh != null
              ? '${item.repsLow}–${item.repsHigh}'
              : (item.distanceMeters != null
                    ? '${item.distanceMeters} m'
                    : '—'));
    final load = item.startLoadKg == null ? '' : ' @ ${_kg(item.startLoadKg)}';
    final flames = item.targetFlames == null
        ? ''
        : ' (${item.targetFlames} fl.)';
    parts.add('${item.sets} × $amount$load$flames');
  }
  final share = item.percentOfOneRm;
  final tail = <String>[
    if (share != null) '${(share * 100).toStringAsFixed(0)} % du 1RM',
    if (item.toCalibrate) 'à calibrer',
    if (item.restSeconds != null) 'repos ${item.restSeconds} s',
  ];
  return '**$name** : ${parts.join(' · ')}'
      '${tail.isEmpty ? '' : ' — ${tail.join(', ')}'}';
}

/// Compte rendu Markdown du rejeu d'un journal par [engine] : résumé
/// d'adaptation, estimations (face à [truth] si elle est connue),
/// propositions, records, séance prescrite pour ([weekIndex], [dayIndex])
/// si elle est demandée, fin du journal du moteur.
String replayMarkdown(
  Catalog catalog,
  KalisAdapt engine, {
  required String title,
  required AthleteProfile profile,
  required ProgramBlock block,
  required TrainingLog log,
  required CivilDate today,
  int? weekIndex,
  int? dayIndex,
  HealthCheck? healthCheck,
  Map<String, double> truth = const <String, double>{},
  List<String> notes = const <String>[],
}) {
  final input = AdaptInput(
    profile: profile,
    block: block,
    log: log,
    today: today,
  );
  final review = engine.review(catalog, input);
  final summary = review.summary;
  var sets = 0;
  for (final s in log.sessions) {
    sets += s.sets.length;
  }
  final out = <String>[
    '# $title',
    '',
    ...notes,
    if (notes.isNotEmpty) '',
    'Moteur `kalis_adapt` ${engine.engineVersion}. Journal : '
        '${log.sessions.length} séances, $sets séries'
        '${log.sessions.isEmpty ? '' : ', du ${log.sessions.first.date.iso} au ${log.sessions.last.date.iso}'}'
        ' ; « aujourd\'hui » : ${today.iso}. Bloc `${block.pass1.blockId}` '
        '(${block.pass1.weeks} semaines).',
    '',
    '## Résumé d\'adaptation',
    '',
    '- Semaines de données : ${summary.weeksObserved} ; séances faites : '
        '${summary.sessionsCompleted} sur ${summary.sessionsPlanned} prévues.',
    '- Niveau de déblocage : `${summary.unlockLevel.code}` ; confiance '
        'globale : ${summary.confidence.toStringAsFixed(2)}.',
  ];
  final fatigue = summary.fatigue;
  if (fatigue != null) {
    out.add(
      '- Forme du jour (modèle) : ${fatigue.readiness.toStringAsFixed(2)} ; '
      'forme ${fatigue.fitness.toStringAsFixed(2)}, fatigue '
      '${fatigue.fatigue.toStringAsFixed(2)} (unités du modèle).',
    );
  }
  out.add('- Faits marquants : ${_reasons(summary.reasons)}.');
  for (final pain in summary.pains) {
    out.add(
      '- Douleur suivie : ${pain.zone.code} (${pain.side.code}), '
      '${pain.sessionsReported} séance(s), dernière intensité '
      '${pain.lastIntensity}, ${pain.consecutiveAboveThreshold} de suite '
      'au-dessus du seuil.',
    );
  }
  out.addAll(<String>[
    '',
    '## Capacités estimées',
    '',
    truth.isEmpty
        ? '| Exercice | Capacité | ± | Tendance / semaine | Séries | '
              'Dernière séance |'
        : '| Exercice | Capacité | ± | Tendance / semaine | Séries | '
              'Dernière séance | Vérité | Écart |',
    truth.isEmpty
        ? '| --- | --- | --- | --- | --- | --- |'
        : '| --- | --- | --- | --- | --- | --- | --- | --- |',
  ]);
  for (final e in summary.estimates) {
    final name = catalog.find(e.exerciseId)?.name ?? e.exerciseId;
    final t = truth[e.exerciseId];
    final cells = <String>[
      name,
      '${e.capacity.toStringAsFixed(1)} ${_unit(e.unit)}',
      e.standardError.toStringAsFixed(1),
      e.weeklyTrend.toStringAsFixed(2),
      '${e.observations}',
      e.lastObservedOn?.iso ?? '—',
      if (truth.isNotEmpty) t == null ? '—' : t.toStringAsFixed(1),
      if (truth.isNotEmpty)
        t == null || t <= 0
            ? '—'
            : '${((e.capacity / t - 1) * 100).toStringAsFixed(1)} %',
    ];
    out.add('| ${cells.join(' | ')} |');
  }
  out.addAll(<String>['', '## Propositions', '']);
  if (review.proposals.isEmpty) {
    out.add('Aucune proposition aujourd\'hui.');
  }
  for (final p in review.proposals) {
    out.add(
      '- `${p.id}` — ${p.kind.code} (portée ${p.scope.code}), confiance '
      '${p.confidence.toStringAsFixed(2)}, niveau requis '
      '`${p.unlockLevel.code}`, ${p.diff?.changes.length ?? 0} '
      'changement(s) : ${_reasons(p.reasons)}',
    );
  }
  final records = review.records ?? const <PersonalRecord>[];
  out.addAll(<String>['', '## Records', '']);
  if (records.isEmpty) {
    out.add('Aucun record.');
  } else {
    out.addAll(<String>[
      '| Exercice | Record | Valeur | Jour |',
      '| --- | --- | --- | --- |',
    ]);
    for (final r in records) {
      final name = catalog.find(r.exerciseId)?.name ?? r.exerciseId;
      out.add(
        '| $name | ${r.kind.code} | ${r.value.toStringAsFixed(1)} | '
        '${r.date.iso} |',
      );
    }
  }
  if (weekIndex != null && dayIndex != null) {
    final session = engine.prescribeSession(
      catalog,
      SessionRequest(
        input: input,
        weekIndex: weekIndex,
        dayIndex: dayIndex,
        healthCheck: healthCheck,
      ),
    );
    out.addAll(<String>[
      '',
      '## Séance prescrite — semaine ${weekIndex + 1}, jour ${dayIndex + 1}',
      '',
      'Confiance ${session.confidence.toStringAsFixed(2)} ; '
          '${_reasons(session.reasons)}.',
      '',
    ]);
    for (final item in session.items) {
      out.add('- ${prescriptionText(catalog, item)}');
      if (item.reasons.isNotEmpty) {
        out.add('  - ${_reasons(item.reasons)}');
      }
    }
    if (session.adjustments.isNotEmpty) {
      out.addAll(<String>['', 'Ajustements :', '']);
      for (final a in session.adjustments) {
        out.add(
          '- ${a.kind.code}'
          '${a.exerciseId == null ? '' : ' — ${catalog.find(a.exerciseId!)?.name ?? a.exerciseId}'}'
          '${a.replacementExerciseId == null ? '' : ' → ${catalog.find(a.replacementExerciseId!)?.name ?? a.replacementExerciseId}'}'
          '${a.setsDelta == null ? '' : ' (${a.setsDelta} série)'}'
          '${a.loadFactor == null ? '' : ' (× ${a.loadFactor})'}'
          ' : ${_reasons(a.reasons)}',
        );
      }
    }
  }
  out.addAll(<String>['', '## Journal du moteur (fin)', '']);
  final entries = review.log;
  final from = entries.length > 8 ? entries.length - 8 : 0;
  for (var i = from; i < entries.length; i++) {
    final e = entries[i];
    final data = e.data;
    final keys = <String>[
      for (final k in data.keys)
        if (data[k] is num || data[k] is String || data[k] is bool) k,
    ]..sort();
    out.add(
      '- n° ${e.sequence}, ${e.date.iso}, `${e.event}` : '
      '${keys.map((k) => '$k=${data[k]}').join(', ')}',
    );
  }
  out.add('');
  return out.join('\n');
}
