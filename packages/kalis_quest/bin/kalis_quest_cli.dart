// Simulateur de kalis_quest : simulation de rythme sur trois ans, triche
// par surentraînement, temps de calcul, documents générés.
//
//   dart run bin/kalis_quest_cli.dart --rapport <dossier>
//       [--graines <n>] [--semaines <n>]
//
// Écrit dans <dossier> :
//   campagne.json   toutes les mesures (copie de référence : docs/data/) ;
//   RYTHME.md       les mêmes, en tableaux (copie de référence : docs/) ;
//   STANDARDS.md    tables de rang (copie de référence : docs/) ;
//   CAS_TYPES.md    journaux types de kalis_core (copie de référence :
//                   docs/).
//
// Par défaut : 200 graines par archétype, 156 semaines. Le fichier
// `campaign_seeds.txt` à la racine du paquet, s'il existe, remplace le
// nombre de graines (essais rapides).
//
// Seul ce fichier lit l'horloge (temps de calcul) : le moteur n'en a pas.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kalis_adapt/kalis_adapt.dart' show KalisAdapt;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/report.dart';
import 'package:kalis_quest/simulation.dart';

const String _corePath = '../kalis_core';

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at < 0 || at + 1 >= args.length ? null : args[at + 1];
}

Map<String, Object?> _readJson(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

Catalog _loadCatalog() => Catalog.fromJsonBytes(
  gzip.decode(File('$_corePath/data/catalog_v1.json.gz').readAsBytesSync()),
);

List<ProfileFixture> _profiles() =>
    readProfileFixtures(_readJson('$_corePath/test/fixtures/profiles.json'));

/// Campagne d'un archétype (dans son propre isolat) : toutes les graines,
/// puis, pour les archétypes de repère, le jumeau tricheur et le
/// prolongement à quatre ans.
Map<String, Object?> _campaign(String key, int seeds, int weeks) {
  final catalog = _loadCatalog();
  final a = archetypeOf(key);
  final profile = _profiles().firstWhere((p) => p.key == a.profileKey).profile;
  final reference = key == 'debutant_3x' || key == 'intermediaire_4x';
  final longWeeks = weeks > 208 ? weeks : 208;
  final stage = SimStage(
    catalog,
    KalisAdapt().plan,
    profile,
    reference ? longWeeks : weeks,
  );
  final engine = KalisQuest();
  final runs = <SimResult>[
    for (var seed = 0; seed < seeds; seed++)
      simulateRun(engine: engine, stage: stage, a: a, seed: seed, weeks: weeks),
  ];
  final out = <String, Object?>{'summary': summarize(a, runs, weeks)};
  if (reference) {
    final cheater = cheaterOf(a);
    final cheats = <SimResult>[
      for (var seed = 0; seed < seeds; seed++)
        simulateRun(
          engine: engine,
          stage: stage,
          a: cheater,
          seed: seed,
          weeks: weeks,
        ),
    ];
    // À assiduité parfaite : le programme fait en entier, avec et sans
    // surentraînement.
    final perfectSeeds = seeds < 50 ? seeds : 50;
    final perfect = perfectOf(a);
    var perfectXp = 0;
    var perfectCheaterXp = 0;
    var perfectMaxDelta = -1 << 40;
    for (var seed = 0; seed < perfectSeeds; seed++) {
      final h = simulateRun(
        engine: engine,
        stage: stage,
        a: perfect,
        seed: seed,
        weeks: weeks,
      );
      final c = simulateRun(
        engine: engine,
        stage: stage,
        a: cheaterOf(perfect),
        seed: seed,
        weeks: weeks,
      );
      perfectXp += h.xp.last;
      perfectCheaterXp += c.xp.last;
      if (c.xp.last - h.xp.last > perfectMaxDelta) {
        perfectMaxDelta = c.xp.last - h.xp.last;
      }
    }
    final deltas = <int>[
      for (var i = 0; i < seeds; i++) cheats[i].xp.last - runs[i].xp.last,
    ];
    var worst = 0.0;
    var extra = 0;
    var honestEffort = 0;
    var cheaterEffort = 0;
    for (var i = 0; i < seeds; i++) {
      if (cheats[i].worstWeekShare > worst) {
        worst = cheats[i].worstWeekShare;
      }
      extra += cheats[i].extraSessions;
      honestEffort += runs[i].xpBySource['effort'] ?? 0;
      cheaterEffort += cheats[i].xpBySource['effort'] ?? 0;
    }
    double r1(double v) => (v * 10).roundToDouble() / 10;
    out['cheat'] = <String, Object?>{
      'key': a.key,
      'perfectSeeds': perfectSeeds,
      'perfectXp': (perfectXp / perfectSeeds).round(),
      'perfectCheaterXp': (perfectCheaterXp / perfectSeeds).round(),
      'perfectMaxDelta': perfectMaxDelta,
      'honestXp': <String, Object?>{
        'p10': quantileOf(<int>[for (final r in runs) r.xp.last], 0.1).round(),
        'p50': quantileOf(<int>[for (final r in runs) r.xp.last], 0.5).round(),
        'p90': quantileOf(<int>[for (final r in runs) r.xp.last], 0.9).round(),
      },
      'cheaterXp': <String, Object?>{
        'p10': quantileOf(<int>[
          for (final r in cheats) r.xp.last,
        ], 0.1).round(),
        'p50': quantileOf(<int>[
          for (final r in cheats) r.xp.last,
        ], 0.5).round(),
        'p90': quantileOf(<int>[
          for (final r in cheats) r.xp.last,
        ], 0.9).round(),
      },
      'medianDelta': quantileOf(deltas, 0.5).round(),
      'maxDelta': quantileOf(deltas, 1).round(),
      'honestEffort': (honestEffort / seeds).round(),
      'cheaterEffort': (cheaterEffort / seeds).round(),
      'extraSessions': r1(extra / seeds),
      'worstWeekShare': (worst * 1000).roundToDouble() / 1000,
    };
    final longSeeds = seeds < 50 ? seeds : 50;
    final longs = <SimResult>[
      for (var seed = 0; seed < longSeeds; seed++)
        simulateRun(
          engine: engine,
          stage: stage,
          a: a,
          seed: seed,
          weeks: longWeeks,
        ),
    ];
    Map<String, Object?> weeksTo(int level) {
      final reached = <int>[
        for (final r in longs)
          if (r.weekOfLevel[level] != null) r.weekOfLevel[level]!,
      ];
      return <String, Object?>{
        'reached': reached.length,
        'p10': r1(quantileOf(reached, 0.1)),
        'p50': r1(quantileOf(reached, 0.5)),
        'p90': r1(quantileOf(reached, 0.9)),
      };
    }

    out['long'] = <String, Object?>{
      'key': a.key,
      'runs': longSeeds,
      'weeksTo': <String, Object?>{'l50': weeksTo(50), 'l100': weeksTo(100)},
      'levelEnd': <String, Object?>{
        'p10': quantileOf(<int>[
          for (final r in longs) r.levels.last,
        ], 0.1).round(),
        'p50': quantileOf(<int>[
          for (final r in longs) r.levels.last,
        ], 0.5).round(),
        'p90': quantileOf(<int>[
          for (final r in longs) r.levels.last,
        ], 0.9).round(),
      },
    };
  }
  return out;
}

double _median(List<double> values) {
  final sorted = List<double>.of(values)..sort();
  return sorted[sorted.length ~/ 2];
}

/// Temps de calcul : calcul complet depuis tout le journal, et appel du
/// lendemain.
Map<String, Object?> _timing(int weeks) {
  final catalog = _loadCatalog();
  final a = archetypeOf('expert_6x');
  final profile = _profiles().firstWhere((p) => p.key == a.profileKey).profile;
  final stage = SimStage(catalog, KalisAdapt().plan, profile, weeks);
  final log = generateLog(a, stage, 1, weeks);
  final training = TrainingLog(sessions: log.sessions, breaks: log.breaks);
  final engine = KalisQuest();
  final start = stage.startDay;
  final end = start + 7 * weeks - 1;
  final first = engine.evaluate(
    catalog,
    QuestInput(
      profile: profile,
      log: const TrainingLog(sessions: <SessionRecord>[]),
      block: stage.blockOn(start),
      state: emptyQuestState,
      today: CivilDate.fromDayNumber(start),
      seed: 1,
    ),
  );
  final full = <double>[];
  final daily = <double>[];
  QuestOutcome? last;
  for (var i = 0; i < 9; i++) {
    final watch = Stopwatch()..start();
    last = engine.evaluate(
      catalog,
      QuestInput(
        profile: profile,
        log: training,
        block: stage.blockOn(end),
        state: first.state,
        today: CivilDate.fromDayNumber(end),
        seed: 1,
      ),
    );
    watch.stop();
    full.add(watch.elapsedMicroseconds / 1000);
  }
  for (var i = 0; i < 9; i++) {
    final watch = Stopwatch()..start();
    engine.evaluate(
      catalog,
      QuestInput(
        profile: profile,
        log: training,
        block: stage.blockOn(end),
        state: last!.state,
        today: CivilDate.fromDayNumber(end + 1),
        seed: 1,
      ),
    );
    watch.stop();
    daily.add(watch.elapsedMicroseconds / 1000);
  }
  double r1(double v) => (v * 10).roundToDouble() / 10;
  return <String, Object?>{
    'archetype': a.key,
    'weeks': weeks,
    'sessions': log.sessions.length,
    'fullMedianMs': r1(_median(full)),
    'fullMaxMs': r1(full.reduce((x, y) => x > y ? x : y)),
    'dailyMedianMs': r1(_median(daily)),
    'dailyMaxMs': r1(daily.reduce((x, y) => x > y ? x : y)),
  };
}

Future<void> main(List<String> args) async {
  final dir = _option(args, '--rapport');
  if (dir == null) {
    stderr.writeln(
      'usage : dart run bin/kalis_quest_cli.dart --rapport <dossier> '
      '[--graines <n>] [--semaines <n>]',
    );
    exitCode = 64;
    return;
  }
  var seeds = int.parse(_option(args, '--graines') ?? '200');
  final weeks = int.parse(_option(args, '--semaines') ?? '156');
  final override = File('campaign_seeds.txt');
  if (override.existsSync()) {
    seeds = int.parse(override.readAsStringSync().trim());
  }
  final watch = Stopwatch()..start();
  final pending = <Future<Map<String, Object?>>>[
    for (final a in archetypes)
      Isolate.run(() => _campaign(a.key, seeds, weeks)),
  ];
  final results = <Map<String, Object?>>[];
  for (var i = 0; i < pending.length; i++) {
    results.add(await pending[i]);
    stdout.writeln(
      '  ${archetypes[i].key} : fait (${watch.elapsed.inSeconds} s)',
    );
  }
  final timing = _timing(weeks);
  const p = QuestParams.standard;
  final campaign = <String, Object?>{
    'schema': 1,
    'engineVersion': kalisQuestVersion,
    'weeks': weeks,
    'seeds': seeds,
    'levelScale': p.levelScale,
    'archetypes': <Object?>[for (final r in results) r['summary']],
    'cheat': <Object?>[
      for (final r in results)
        if (r['cheat'] != null) r['cheat'],
    ],
    'longRun': <String, Object?>{
      'weeks': weeks > 208 ? weeks : 208,
      'seeds': seeds < 50 ? seeds : 50,
      'archetypes': <Object?>[
        for (final r in results)
          if (r['long'] != null) r['long'],
      ],
    },
    'timing': timing,
  };
  final catalog = _loadCatalog();
  final out = Directory(dir)..createSync(recursive: true);
  final text = const JsonEncoder.withIndent(' ').convert(campaign);
  File('${out.path}/campagne.json').writeAsStringSync('$text\n');
  // Le rapport est construit depuis le JSON relu : c'est exactement ce que
  // le test des documents refait.
  File(
    '${out.path}/RYTHME.md',
  ).writeAsStringSync(rhythmMarkdown(jsonDecode(text) as Map<String, Object?>));
  File(
    '${out.path}/STANDARDS.md',
  ).writeAsStringSync(standardsMarkdown(catalog));
  final journals = readJournalFixtures(
    _readJson('$_corePath/test/fixtures/journals.json.gz'),
  );
  File(
    '${out.path}/CAS_TYPES.md',
  ).writeAsStringSync(casesMarkdown(catalog, _profiles(), journals));
  stdout.writeln(
    'kalis_quest $kalisQuestVersion : rapport écrit dans ${out.path} '
    '(${watch.elapsed.inSeconds} s).',
  );
}
