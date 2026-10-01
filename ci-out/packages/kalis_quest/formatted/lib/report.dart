/// Documents générés de `kalis_quest` : tables de standards
/// (`docs/STANDARDS.md`), rapport de la simulation de rythme
/// (`docs/RYTHME.md`), cas types (`docs/CAS_TYPES.md`).
///
/// À n'importer que depuis des tests ou des outils (`bin/`, `tool/`).
library;

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';

import 'kalis_quest.dart';
import 'simulation.dart' show reportWeeks;

String _clock(double seconds) {
  final s = seconds.round();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

String _kg(double v) {
  final r = (v * 2).round() / 2;
  final text = r == r.roundToDouble() ? r.round().toString() : r.toString();
  return r > 0 ? '+$text' : text;
}

String _plain(double v) {
  final r = (v * 2).round() / 2;
  return r == r.roundToDouble() ? r.round().toString() : r.toString();
}

const List<String> _tiers = <String>[
  'Bronze',
  'Argent',
  'Or',
  'Platine',
  'Diamant',
  'Élite',
];

const List<double> _maleWeights = <double>[60, 70, 80, 90, 100, 110];
const List<double> _femaleWeights = <double>[50, 60, 70, 80, 90];

/// `docs/STANDARDS.md` : tables de rang par sexe et poids de corps,
/// produites par les mêmes fonctions que le moteur.
String standardsMarkdown(Catalog catalog) {
  final out = StringBuffer();
  void line([String text = '']) => out.writeln(text);
  double fractionOf(String id) =>
      catalog.find(id)?.bodyweightFraction?.value ?? 0;
  String nameOf(String id) => catalog.find(id)?.name ?? id;

  line('# Standards de rang par mouvement — kalis_quest');
  line();
  line(
    'Document généré par `standardsMarkdown` (`lib/report.dart`) à partir '
    'des tables de `lib/src/standards.dart` : ce sont les seuils que le '
    'moteur applique. Méthode, sources et limites : `STANDARDS_SOURCES.md`.',
  );
  line();
  line('## 1. Seuils de référence');
  line();
  line(
    'Poids de corps de référence : ${Standards.maleRefKg.round()} kg '
    '(hommes), ${Standards.femaleRefKg.round()} kg (femmes). Charges : 1RM '
    'de charge externe ou de lest, en kg (négatif = assistance). Le rang '
    'Élite est extrapolé (voir les sources).',
  );
  line();
  line('| Mouvement | Mesure | Sexe | ${_tiers.join(' | ')} |');
  line('| --- | --- | --- | ${_tiers.map((_) => '---').join(' | ')} |');
  for (final m in Standards.movements) {
    if (m.measure == RankMeasure.hold) {
      continue;
    }
    final fraction = fractionOf(m.id);
    for (final (sex, label, ref) in <(Sex, String, double)>[
      (Sex.male, 'H', Standards.maleRefKg),
      (Sex.female, 'F', Standards.femaleRefKg),
    ]) {
      final t = Standards.thresholds(m, sex, ref, fraction);
      final cells = <String>[
        for (final v in t)
          switch (m.measure) {
            RankMeasure.load => _kg(v - fraction * ref),
            RankMeasure.reps => v.ceil().toString(),
            RankMeasure.run => _clock(Standards.runMeters / v),
            RankMeasure.hold => '',
          },
      ];
      final measure = switch (m.measure) {
        RankMeasure.load => fraction > 0 ? '1RM, lest (kg)' : '1RM (kg)',
        RankMeasure.reps => 'répétitions',
        RankMeasure.run => '5 km (min:s)',
        RankMeasure.hold => '',
      };
      line(
        '| ${nameOf(m.id)} (`${m.id}`) | $measure | $label | '
        '${cells.join(' | ')} |',
      );
    }
  }
  line();
  line('## 2. Figures tenues');
  line();
  line(
    'Mêmes échelons pour tous (aucun standard publié par sexe ou par poids '
    'de corps). Un échelon est acquis si l\'une de ses progressions est '
    'tenue le temps indiqué, ou si une progression d\'un échelon plus haut '
    'est tenue au moins ${QuestParams.standard.skillHoldSeconds} s.',
  );
  line();
  line('| Figure | ${_tiers.join(' | ')} |');
  line('| --- | ${_tiers.map((_) => '---').join(' | ')} |');
  for (final m in Standards.movements) {
    if (m.measure != RankMeasure.hold) {
      continue;
    }
    final cells = <String>[
      for (final r in m.rungs)
        '${r.exerciseIds.map(nameOf).join(' ou ')} : ${r.seconds} s',
    ];
    line('| ${nameOf(m.id)} (`${m.id}`) | ${cells.join(' | ')} |');
  }
  line();
  line('## 3. Tables par poids de corps');
  line();
  line(
    'Exposants du poids de corps par rang — charges : '
    '${Standards.loadExponents.join(' ; ')} ; répétitions : '
    '${Standards.repsExponents.join(' ; ')}. Le poids de corps est borné à '
    '[${Standards.minBodyWeightKg.round()} ; '
    '${Standards.maxBodyWeightKg.round()}] kg. Sexe non précisé : moyenne '
    'géométrique des deux tables.',
  );
  for (final m in Standards.movements) {
    if (m.measure == RankMeasure.hold || m.measure == RankMeasure.run) {
      continue;
    }
    final fraction = fractionOf(m.id);
    line();
    line('### ${nameOf(m.id)} (`${m.id}`)');
    line();
    line(
      m.measure == RankMeasure.load
          ? (fraction > 0
                ? '1RM en kg de lest (fraction du poids du corps portée : '
                      '$fraction).'
                : '1RM en kg de charge externe.')
          : 'Répétitions maximales au poids du corps.',
    );
    line();
    line('| Sexe | Poids (kg) | ${_tiers.join(' | ')} |');
    line('| --- | --- | ${_tiers.map((_) => '---').join(' | ')} |');
    for (final (sex, label, weights) in <(Sex, String, List<double>)>[
      (Sex.male, 'H', _maleWeights),
      (Sex.female, 'F', _femaleWeights),
    ]) {
      for (final bw in weights) {
        final t = Standards.thresholds(m, sex, bw, fraction);
        final cells = <String>[
          for (final v in t)
            m.measure == RankMeasure.load
                ? (fraction > 0 ? _kg(v - fraction * bw) : _plain(v))
                : v.ceil().toString(),
        ];
        line('| $label | ${bw.round()} | ${cells.join(' | ')} |');
      }
    }
  }
  line();
  line('## 4. Héritage');
  line();
  line(
    'Les performances comptent pour un rang quand elles sont faites sur le '
    'mouvement de référence ou sur l\'un des exercices listés ; les autres '
    'variantes de la même chaîne du catalogue (même racine) affichent le '
    'rang du mouvement de référence sans le faire avancer ; un exercice '
    'hors de ces chaînes n\'a pas de rang.',
  );
  line();
  line('| Mouvement de référence | Performances comptées |');
  line('| --- | --- |');
  for (final m in Standards.movements) {
    line('| `${m.id}` | ${m.sources.map((s) => '`$s`').join(', ')} |');
  }
  return out.toString();
}

String _num(Object? v) {
  if (v is double && v == v.roundToDouble()) {
    return v.round().toString();
  }
  return '$v';
}

String _pct(Object? v) => '${((v! as num) * 100).round()} %';

Map<String, Object?> _obj(Object? v) => v! as Map<String, Object?>;

String _spreadText(Object? v) {
  final m = _obj(v);
  return '${_num(m['p50'])} (${_num(m['p10'])}–${_num(m['p90'])})';
}

/// `docs/RYTHME.md` : mise en tableaux de `docs/data/campagne.json`.
String rhythmMarkdown(Map<String, Object?> campaign) {
  final out = StringBuffer();
  void line([String text = '']) => out.writeln(text);
  final list = <Map<String, Object?>>[
    for (final a in campaign['archetypes']! as List<Object?>) _obj(a),
  ];
  final weeks = campaign['weeks']! as int;
  line('# Simulation de rythme — kalis_quest ${campaign['engineVersion']}');
  line();
  line(
    'Document généré par `dart run bin/kalis_quest_cli.dart --rapport '
    '<dossier>` (mise en tableaux de `docs/data/campagne.json`). '
    '${list.length} archétypes × ${campaign['seeds']} graines × $weeks '
    'semaines ; le moteur est appelé à la fin de chaque semaine avec le '
    'bloc en cours de `kalis_plan`. Valeurs : médiane (10ᵉ–90ᵉ centile) '
    'sur les graines, ou moyenne quand un seul nombre est donné. Lecture '
    'et limites : `VALIDATION.md`.',
  );
  line();
  line('## 1. Archétypes');
  line();
  line(
    '| Archétype | Profil type | Séances prévues / sem. | Séances récompensées / sem. | Ce qu\'il représente |',
  );
  line('| --- | --- | --- | --- | --- |');
  for (final a in list) {
    line(
      '| `${a['key']}` | `${a['profileKey']}` | '
      '${_num(a['sessionsPerWeekPlanned'])} | '
      '${_num(a['sessionsPerWeekPaid'])} | ${a['note']} |',
    );
  }
  line();
  line('## 2. Niveau dans le temps');
  line();
  final columns = <String>[
    for (final w in reportWeeks)
      if (w <= weeks) 'w$w',
  ];
  line(
    '| Archétype | ${columns.map((c) => 'Sem. ${c.substring(1)}').join(' | ')} |',
  );
  line('| --- | ${columns.map((_) => '---').join(' | ')} |');
  for (final a in list) {
    final at = _obj(a['levelAt']);
    line(
      '| `${a['key']}` | '
      '${columns.map((c) => _spreadText(at[c])).join(' | ')} |',
    );
  }
  line();
  line(
    'Niveau global : `prestige × 100 + niveau` (au-delà de 100, un prestige '
    'est passé).',
  );
  line();
  line('### Semaines pour atteindre un niveau');
  line();
  line('| Archétype | Niveau 10 | Niveau 25 | Niveau 50 | Niveau 100 |');
  line('| --- | --- | --- | --- | --- |');
  for (final a in list) {
    final to = _obj(a['weeksTo']);
    String cell(String key) {
      final m = _obj(to[key]);
      final reached = m['reached']! as int;
      final runs = a['runs']! as int;
      if (reached == 0) {
        return 'jamais en $weeks sem.';
      }
      final text = _spreadText(m);
      return reached == runs ? text : '$text — $reached/$runs graines';
    }

    line(
      '| `${a['key']}` | ${cell('l10')} | ${cell('l25')} | ${cell('l50')} | '
      '${cell('l100')} |',
    );
  }
  final long = campaign['longRun'];
  if (long is Map<String, Object?>) {
    line();
    line(
      'Prolongement à ${long['weeks']} semaines des archétypes de repère '
      '(${long['seeds']} graines) :',
    );
    line();
    line('| Archétype | Niveau 50 | Niveau 100 | Niveau global à la fin |');
    line('| --- | --- | --- | --- |');
    for (final a in long['archetypes']! as List<Object?>) {
      final m = _obj(a);
      final to = _obj(m['weeksTo']);
      String cell(String key) {
        final t = _obj(to[key]);
        final reached = t['reached']! as int;
        return reached == 0
            ? 'jamais'
            : '${_spreadText(t)} sem. — $reached/${m['runs']} graines';
      }

      line(
        '| `${m['key']}` | ${cell('l50')} | ${cell('l100')} | '
        '${_spreadText(m['levelEnd'])} |',
      );
    }
  }
  line();
  line('### Courbe médiane (niveau global, toutes les 13 semaines)');
  line();
  final marks = <int>[for (var w = 12; w <= weeks; w += 12) w];
  line('| Archétype | ${marks.map((w) => 'S$w').join(' | ')} |');
  line('| --- | ${marks.map((_) => '---').join(' | ')} |');
  for (final a in list) {
    final curve = a['curve']! as List<Object?>;
    final byWeek = <int, Object?>{};
    for (final row in curve) {
      final cells = row! as List<Object?>;
      byWeek[cells[0]! as int] = cells[2];
    }
    line(
      '| `${a['key']}` | '
      '${marks.map((w) => _num(byWeek[w])).join(' | ')} |',
    );
  }
  line();
  line('## 3. XP');
  line();
  line(
    '| Archétype | XP total | XP / semaine | Effort | Régularité | Records | Jalons | Quêtes |',
  );
  line('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final a in list) {
    final share = _obj(a['xpShare']);
    line(
      '| `${a['key']}` | ${_spreadText(a['xpTotal'])} | '
      '${_num(a['xpPerWeek'])} | ${_pct(share['effort'])} | '
      '${_pct(share['consistency'])} | ${_pct(share['record'])} | '
      '${_pct(share['milestone'])} | ${_pct(share['quest'])} |',
    );
  }
  line();
  line('## 4. Quêtes');
  line();
  line('Créées et terminées par simulation (moyennes), part terminée.');
  line();
  line('| Archétype | Quotidiennes | Hebdomadaires | Campagne | Koach |');
  line('| --- | --- | --- | --- | --- |');
  for (final a in list) {
    final q = _obj(a['quests']);
    String cell(String kind) {
      final m = _obj(q[kind]);
      return '${_num(m['done'])} / ${_num(m['created'])} (${_pct(m['rate'])})';
    }

    line(
      '| `${a['key']}` | ${cell('daily')} | ${cell('weekly')} | '
      '${cell('campaign')} | ${cell('koach')} |',
    );
  }
  line();
  line('## 5. Série de semaines, notes, coffres, Krédits');
  line();
  line(
    '| Archétype | Semaines réussies / en pause / non réussies | Meilleure série | Notes S / A / B / C | Coffres | Séances par coffre | Plus longue attente | Krédits |',
  );
  line('| --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final a in list) {
    final w = _obj(a['weeks']);
    final g = _obj(a['grades']);
    final c = _obj(a['chests']);
    line(
      '| `${a['key']}` | ${_num(w['success'])} / ${_num(w['paused'])} / '
      '${_num(w['missed'])} | ${_spreadText(a['bestStreak'])} | '
      '${_pct(g['s'])} / ${_pct(g['a'])} / ${_pct(g['b'])} / ${_pct(g['c'])} | '
      '${_spreadText(c['perRun'])} | ${_num(c['sessionsPerChest'])} | '
      '${c['longestGap']} | ${_spreadText(a['kredits'])} |',
    );
  }
  line();
  line('Krédits par origine (moyennes) :');
  line();
  line('| Archétype | Quêtes | Coffres | Niveaux | Jalons | Records |');
  line('| --- | --- | --- | --- | --- | --- |');
  for (final a in list) {
    final k = _obj(a['kreditsBySource']);
    line(
      '| `${a['key']}` | ${_num(k['quest'])} | ${_num(k['chest'])} | '
      '${_num(k['level_up'])} | ${_num(k['milestone'])} | '
      '${_num(k['record'])} |',
    );
  }
  line();
  line('## 6. Avancements');
  line();
  line(
    'Attributs à la fin (médiane ; entre parenthèses, meilleure valeur atteinte), records et passages de rang (moyennes).',
  );
  line();
  line(
    '| Archétype | Force | Endurance | Puissance | Technique | Mobilité | Régularité | Records | Rangs gagnés |',
  );
  line('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');
  for (final a in list) {
    final now = a['attributes']! as List<Object?>;
    final best = a['attributeBests']! as List<Object?>;
    line(
      '| `${a['key']}` | '
      '${<String>[for (var i = 0; i < 6; i++) '${_num(now[i])} (${_num(best[i])})'].join(' | ')} | '
      '${_num(a['records'])} | ${_num(a['rankUps'])} |',
    );
  }
  line();
  line('## 7. Garde-fous mesurés');
  line();
  line(
    '| Archétype | Séances faites malgré une douleur (sans récompense) | Séances au-delà du programme (sans XP) | XP écrit pour ces séances | Pire semaine : XP d\'effort / plafond | Niveau en baisse | Écritures d\'XP |',
  );
  line('| --- | --- | --- | --- | --- | --- | --- |');
  for (final a in list) {
    final g = _obj(a['guards']);
    line(
      '| `${a['key']}` | ${_num(g['painSessions'])} | '
      '${_num(g['extraSessions'])} | ${g['xpForPainOrExtra']} | '
      '${_num(g['worstWeekShare'])} | '
      '${g['levelDropped'] == true ? 'oui' : 'jamais'} | '
      '${_num(a['ledgerEntries'])} |',
    );
  }
  final cheat = campaign['cheat'];
  if (cheat is List<Object?>) {
    line();
    line('### Triche par surentraînement');
    line();
    line(
      'Jumeau tricheur : mêmes aléas, moitié de séries en plus à chaque '
      'séance et une séance en plus quatre jours de repos sur cinq.',
    );
    line();
    line(
      '| Archétype | XP honnête | XP tricheur | Écart médian | XP d\'effort honnête | XP d\'effort tricheur | Séances en plus sans XP | Pire semaine / plafond |',
    );
    line('| --- | --- | --- | --- | --- | --- | --- | --- |');
    for (final c in cheat) {
      final m = _obj(c);
      line(
        '| `${m['key']}` | ${_spreadText(m['honestXp'])} | '
        '${_spreadText(m['cheaterXp'])} | ${_num(m['medianDelta'])} | '
        '${_num(m['honestEffort'])} | ${_num(m['cheaterEffort'])} | '
        '${_num(m['extraSessions'])} | ${_num(m['worstWeekShare'])} |',
      );
    }
    line();
    line(
      'Les séances en plus du tricheur prennent la place des séances '
      'prévues qu\'il manque : son XP d\'effort monte jusqu\'au plafond du '
      'programme, jamais au-delà. Face au même programme fait en entier '
      '(assiduité parfaite), le surentraînement ne rapporte rien :',
    );
    line();
    line(
      '| Archétype | Graines | XP, programme fait en entier | XP, programme fait en entier + surentraînement | Écart le plus favorable au tricheur |',
    );
    line('| --- | --- | --- | --- | --- |');
    for (final c in cheat) {
      final m = _obj(c);
      line(
        '| `${m['key']}` | ${m['perfectSeeds']} | ${_num(m['perfectXp'])} | '
        '${_num(m['perfectCheaterXp'])} | ${_num(m['perfectMaxDelta'])} |',
      );
    }
  }
  final timing = campaign['timing'];
  if (timing is Map<String, Object?>) {
    line();
    line('## 8. Temps de calcul');
    line();
    line(
      'VM Dart de la CI, journal de ${timing['sessions']} séances '
      '(${timing['weeks']} semaines, archétype `${timing['archetype']}`).',
    );
    line();
    line('| Appel | Médiane | Maximum | Budget |');
    line('| --- | --- | --- | --- |');
    line(
      '| Calcul complet depuis tout le journal (registre démarré le premier '
      'jour, un seul appel à la fin) | ${_num(timing['fullMedianMs'])} ms | '
      '${_num(timing['fullMaxMs'])} ms | ≤ 200 ms |',
    );
    line(
      '| Appel du lendemain (état à jour) | '
      '${_num(timing['dailyMedianMs'])} ms | ${_num(timing['dailyMaxMs'])} ms '
      '| ≤ 200 ms |',
    );
  }
  return out.toString();
}

/// État vide : le registre démarre au premier appel.
const QuestState emptyQuestState = QuestState(
  xp: <XpEntry>[],
  kredits: <KreditEntry>[],
  quests: <Quest>[],
  data: <String, Object?>{},
);

/// Évalue un journal type : le registre démarre la veille de la première
/// séance, puis le moteur est appelé chaque dimanche et le dernier jour.
QuestOutcome evaluateFixture(
  KalisQuest engine,
  Catalog catalog,
  AthleteProfile profile,
  TrainingLog log, {
  int seed = 0,
}) {
  if (log.sessions.isEmpty) {
    return engine.evaluate(
      catalog,
      QuestInput(
        profile: profile,
        log: log,
        state: emptyQuestState,
        today: profile.updatedOn,
        seed: seed,
      ),
    );
  }
  final first = log.sessions.first.date.dayNumber - 1;
  final last = log.sessions.last.date.dayNumber + 1;
  var outcome = engine.evaluate(
    catalog,
    QuestInput(
      profile: profile,
      log: log,
      state: emptyQuestState,
      today: CivilDate.fromDayNumber(first),
      seed: seed,
    ),
  );
  for (var day = first + 1; day <= last; day++) {
    if (weekdayOf(day) != 7 && day != last) {
      continue;
    }
    outcome = engine.evaluate(
      catalog,
      QuestInput(
        profile: profile,
        log: log,
        state: outcome.state,
        today: CivilDate.fromDayNumber(day),
        seed: seed,
      ),
    );
  }
  return outcome;
}

/// `docs/CAS_TYPES.md` : ce que le moteur rend pour les journaux types de
/// `kalis_core`.
String casesMarkdown(
  Catalog catalog,
  List<ProfileFixture> profiles,
  List<JournalFixture> journals,
) {
  final engine = KalisQuest();
  final out = StringBuffer();
  void line([String text = '']) => out.writeln(text);
  line('# Cas types — kalis_quest $kalisQuestVersion');
  line();
  line(
    'Document généré par `casesMarkdown` (`lib/report.dart`) : les '
    '${journals.length} journaux types de `kalis_core` '
    '(`test/fixtures/journals.json.gz`) passés au moteur, sans bloc ni '
    'résumé d\'adaptation. Le registre démarre la veille de la première '
    'séance ; le moteur est appelé chaque dimanche, puis le lendemain de la '
    'dernière séance.',
  );
  for (final j in journals) {
    final profile = profiles.firstWhere((p) => p.key == j.profileKey).profile;
    final o = evaluateFixture(engine, catalog, profile, j.log);
    final bySource = <String, int>{};
    for (final e in o.state.xp) {
      bySource.update(
        e.source.code,
        (n) => n + e.amount,
        ifAbsent: () => e.amount,
      );
    }
    var zero = 0;
    for (final e in o.state.xp) {
      if (e.source == XpSource.effort && e.amount == 0) {
        zero++;
      }
    }
    final extras = o.extras ?? const <String, Object?>{};
    final streak = _obj(extras['streak']);
    final totals = _obj(extras['totals']);
    line();
    line('## ${j.key}');
    line();
    line(
      '${j.description} Profil `${j.profileKey}`, ${j.weeks} semaines, '
      '${j.log.sessions.length} séances.',
    );
    line();
    line(
      '- Niveau ${o.level.level} (prestige ${o.level.prestige}), '
      '${o.level.totalXp} XP : '
      '${<String>[for (final s in XpSource.values) '${s.code} ${bySource[s.code] ?? 0}'].join(', ')}.',
    );
    line(
      '- Séances récompensées : ${totals['sessions']} ; écritures d\'effort '
      'à 0 XP (douleur, hors programme, récupération) : $zero.',
    );
    line(
      '- Série de semaines : ${streak['current']} (meilleure '
      '${streak['best']}, flamme ${streak['flameSize']}) ; Krédits : '
      '${o.kreditBalance} ; coffres : ${totals['chests']} ; quêtes '
      'terminées : ${totals['questsDone']}.',
    );
    line(
      '- Attributs (actuel / meilleur) : '
      '${<String>[for (final a in o.attributes) '${a.attribute.code} ${_num(a.value)} / ${_num(a.best)}'].join(', ')}.',
    );
    final ranked = <String>[
      for (final r in o.ranks)
        if (r.tier != MovementRankTier.unranked)
          '`${r.exerciseId}` ${r.tier.code} (${r.score})',
    ];
    line('- Rangs : ${ranked.isEmpty ? 'aucun' : ranked.join(', ')}.');
    final records = o.records ?? const <PersonalRecord>[];
    line('- Records connus : ${records.length}.');
    for (final g in o.goals) {
      final p = g.prediction;
      line(
        '- Objectif `${g.goalId}` : ${_num(g.current)} / ${_num(g.target)} '
        '(départ ${g.baseline == null ? '—' : _num(g.baseline)}, '
        '${(g.fraction * 100).round()} %), jalons '
        '${<String>[for (final m in g.milestones) '${m.fraction}${m.reachedOn == null ? '' : ' ✓'}'].join(' · ')}'
        '${g.achievedOn == null ? '' : ', atteint le ${g.achievedOn}'}'
        '${p == null ? '' : ', prédiction ${p.expectedOn} (${p.earliestOn} – ${p.latestOn}, ${p.method}, confiance ${p.confidence})'}'
        '${g.overdue == true ? ', en retard${g.suggestedDate == null ? '' : ' → date proposée ${g.suggestedDate}'}${g.suggestedTarget == null ? '' : ' ou cible proposée ${_num(g.suggestedTarget)}'}' : ''}.',
      );
    }
    final open = <String>[
      for (final q in o.state.quests)
        if (q.status == QuestStatus.active)
          '`${q.template}` ${_num(q.progress)}/${_num(q.target)}',
    ];
    line('- Quêtes en cours : ${open.isEmpty ? 'aucune' : open.join(', ')}.');
  }
  return out.toString();
}
