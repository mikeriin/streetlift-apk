// Simulateur de kalis_adapt : campagne de validation sur des athlètes à
// vérité connue, comparaison à la double progression simple et à l'ancien
// moteur L7/L11, boucle complète, temps de calcul.
//
//   dart run bin/kalis_adapt_cli.dart --rapport <dossier>
//       [--graines <n>] [--boucle <n>] [--semaines <n>]
//
// Écrit dans <dossier> :
//   campagne.json   toutes les mesures (copie de référence : docs/data/) ;
//   MESURES.md      les mêmes, en tableaux (copie de référence : docs/) ;
//   proprietaire.json  la fixture du programme importé du propriétaire
//                   (copie de référence : test/fixtures/, compressée) ;
//   PROPRIETAIRE.md son rejeu (copie de référence : docs/).
//
// Par défaut : 200 graines par athlète et par politique, 40 en boucle
// complète, 24 semaines. Le fichier `campaign_seeds.txt` à la racine du
// paquet, s'il existe, remplace le nombre de graines (essais rapides).
//
// Seul ce fichier lit l'horloge (temps de calcul) : le moteur n'en a pas.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/report.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';

import '../tool/l7/l7_policy.dart';
import '../tool/owner.dart';

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

AthleteProfile _profileOf(String key) => readProfileFixtures(
  _readJson('$_corePath/test/fixtures/profiles.json'),
).firstWhere((p) => p.key == key).profile;

/// Campagne d'un athlète : politiques à programme égal, puis boucle
/// complète. S'exécute dans son propre isolat.
Map<String, Object?> _athleteCampaign(
  String key,
  int seeds,
  int loopSeeds,
  int weeks,
) {
  final catalog = _loadCatalog();
  final spec = athleteOf(key);
  final profile = _profileOf(spec.profileKey);
  final program = SimProgram(catalog, KalisPlan(), profile);
  final byPolicy = <String, List<SimRun>>{
    for (final name in reportPolicies) name: <SimRun>[],
  };
  for (var seed = 0; seed < seeds; seed++) {
    final policies = <SimPolicy>[
      KalisAdaptPolicy(KalisAdapt()),
      DoubleProgressionPolicy(),
      L7Policy(profile.bodyWeightKg ?? 72),
      OraclePolicy(),
    ];
    for (final policy in policies) {
      final run = simulate(
        catalog: catalog,
        spec: spec,
        profile: profile,
        seed: seed,
        policy: policy,
        program: program,
        weeks: weeks,
      );
      run.sessions.clear();
      run.blocks.clear();
      byPolicy[policy.name]!.add(run);
    }
  }
  final loops = <SimRun>[];
  for (var seed = 0; seed < loopSeeds; seed++) {
    final engine = KalisAdapt();
    final run = simulate(
      catalog: catalog,
      spec: spec,
      profile: profile,
      seed: seed,
      policy: KalisAdaptPolicy(engine),
      program: program,
      weeks: weeks,
      loop: engine,
    );
    run.sessions.clear();
    run.blocks.clear();
    loops.add(run);
  }
  final kalis = byPolicy['kalis_adapt']!;
  final simple = byPolicy['double_progression']!;
  final old = byPolicy['L7/L11']!;
  var blockCount = 0;
  var blockWeeks = 0;
  while (blockWeeks < weeks) {
    blockWeeks += program.block(blockCount).pass1.weeks;
    blockCount++;
  }
  return <String, Object?>{
    'key': key,
    'profileKey': spec.profileKey,
    'spec': athleteToJson(spec),
    'blocks': blockCount,
    'policies': <String, Object?>{
      for (final e in byPolicy.entries) e.key: Metrics(e.value).toJson(),
    },
    'paired': <String, Object?>{
      'rirMae_vs_double_progression': pairedDifference(
        kalis,
        simple,
        runRirMae,
      ).toJson(),
      'rirMae_vs_L7': pairedDifference(kalis, old, runRirMae).toJson(),
      'gain_vs_double_progression': pairedDifference(
        kalis,
        simple,
        runGain,
      ).toJson(),
      'gain_vs_L7': pairedDifference(kalis, old, runGain).toJson(),
    },
    'loop': LoopMetrics(loops).toJson(),
  };
}

/// Lance la campagne de l'athlète [key] dans un isolat (la fermeture ne
/// capture que des valeurs simples).
Future<Map<String, Object?>> _spawn(
  String key,
  int seeds,
  int loopSeeds,
  int weeks,
) => Isolate.run(() => _athleteCampaign(key, seeds, loopSeeds, weeks));

/// Politique `kalis_adapt` chronométrée (l'horloge reste dans `bin/`).
final class _TimedPolicy implements SimPolicy {
  _TimedPolicy(this.engine) : inner = KalisAdaptPolicy(engine);

  final KalisAdapt engine;
  final KalisAdaptPolicy inner;
  final List<double> prescribe = <double>[];
  final List<double> advise = <double>[];

  @override
  String get name => inner.name;

  @override
  SessionPlan plan(SessionContext c) {
    final clock = Stopwatch()..start();
    final session = inner.plan(c);
    prescribe.add(clock.elapsedMicroseconds / 1000);
    return session;
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    if (index == 0) {
      return inner.nextSet(c, item, index, done);
    }
    final clock = Stopwatch()..start();
    final target = inner.nextSet(c, item, index, done);
    advise.add(clock.elapsedMicroseconds / 1000);
    return target;
  }

  @override
  void finish(SessionContext c, SessionRecord record) =>
      inner.finish(c, record);

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

Map<String, Object?> _quantiles(List<double> values) {
  final sorted = List<double>.of(values)..sort();
  double at(double p) =>
      sorted.isEmpty ? 0 : sorted[(p * (sorted.length - 1)).round()];
  double r(double v) => (v * 1000).roundToDouble() / 1000;
  return <String, Object?>{
    'median': r(at(0.5)),
    'p95': r(at(0.95)),
    'p99': r(at(0.99)),
    'max': r(sorted.isEmpty ? 0 : sorted.last),
    'n': sorted.length,
  };
}

Map<String, Object?> _timings(Catalog catalog, int weeks) {
  const key = 'avance_street';
  final spec = athleteOf(key);
  final profile = _profileOf(spec.profileKey);
  final program = SimProgram(catalog, KalisPlan(), profile);
  // Première simulation non mesurée : le code est compilé à la volée sur
  // la machine de contrôle, d'avance sur téléphone.
  simulate(
    catalog: catalog,
    spec: spec,
    profile: profile,
    seed: 0,
    policy: _TimedPolicy(KalisAdapt()),
    program: program,
    weeks: weeks,
  );
  final engine = KalisAdapt();
  final policy = _TimedPolicy(engine);
  final run = simulate(
    catalog: catalog,
    spec: spec,
    profile: profile,
    seed: 0,
    policy: policy,
    program: program,
    weeks: weeks,
  );
  // Revue et décision à froid sur le journal complet.
  final block = run.blocks.last;
  final log = TrainingLog(sessions: run.sessions);
  final today = run.sessions.last.date.addDays(1);
  final input = AdaptInput(
    profile: profile,
    block: block,
    log: log,
    today: today,
  );
  final reviews = <double>[];
  final colds = <double>[];
  for (var i = 0; i < 20; i++) {
    final warm = Stopwatch()..start();
    engine.review(catalog, input);
    reviews.add(warm.elapsedMicroseconds / 1000);
    final fresh = KalisAdapt();
    final cold = Stopwatch()..start();
    fresh.prescribeSession(
      catalog,
      SessionRequest(input: input, weekIndex: 0, dayIndex: 0),
    );
    colds.add(cold.elapsedMicroseconds / 1000);
  }
  return <String, Object?>{
    'athlete': key,
    'sessions': policy.prescribe.length,
    'advices': policy.advise.length,
    'coldSessions': run.sessions.length,
    'prescribe': _quantiles(policy.prescribe),
    'advise': _quantiles(policy.advise),
    'review': _quantiles(reviews),
    'cold': _quantiles(colds),
    'machine':
        '${Platform.operatingSystem}, ${Platform.numberOfProcessors} cœurs',
  };
}

Future<void> main(List<String> args) async {
  final dir = _option(args, '--rapport');
  if (dir == null) {
    stderr.writeln(
      'usage : dart run bin/kalis_adapt_cli.dart --rapport <dossier> '
      '[--graines <n>] [--boucle <n>] [--semaines <n>]',
    );
    exitCode = 64;
    return;
  }
  final clock = Stopwatch()..start();
  var seeds = int.parse(_option(args, '--graines') ?? '200');
  var loopSeeds = int.parse(_option(args, '--boucle') ?? '40');
  final weeks = int.parse(_option(args, '--semaines') ?? '24');
  final knob = File('campaign_seeds.txt');
  if (knob.existsSync() && _option(args, '--graines') == null) {
    final parts = knob.readAsStringSync().trim().split(RegExp(r'\s+'));
    seeds = int.parse(parts[0]);
    loopSeeds = parts.length > 1 ? int.parse(parts[1]) : seeds;
  }
  Directory(dir).createSync(recursive: true);

  final keys = <String>[for (final a in simAthletes) a.key];
  final results = <String, Map<String, Object?>>{};
  final workers = Platform.numberOfProcessors < 2
      ? 1
      : (Platform.numberOfProcessors > 4 ? 4 : Platform.numberOfProcessors);
  var next = 0;
  Future<void> worker() async {
    while (next < keys.length) {
      final key = keys[next++];
      final s = seeds;
      final l = loopSeeds;
      results[key] = await _spawn(key, s, l, weeks);
      stdout.writeln('  $key : fait (${clock.elapsed.inSeconds} s)');
    }
  }

  await Future.wait(<Future<void>>[for (var i = 0; i < workers; i++) worker()]);

  final catalog = _loadCatalog();
  final campaign = <String, Object?>{
    'engineVersion': kalisAdaptVersion,
    'coreVersion': kalisCoreVersion,
    'planVersion': kalisPlanVersion,
    'weeks': weeks,
    'seeds': seeds,
    'loopSeeds': loopSeeds,
    'athletes': <Object?>[for (final key in keys) results[key]],
    'timings': _timings(catalog, weeks),
  };
  const encoder = JsonEncoder.withIndent(' ');
  File(
    '$dir/campagne.json',
  ).writeAsStringSync('${encoder.convert(campaign)}\n');
  // Relu comme le lira `docs_test` : mêmes types, même texte.
  final reread = jsonDecode(jsonEncode(campaign)) as Map<String, Object?>;
  File('$dir/MESURES.md').writeAsStringSync(campaignMarkdown(reread));
  // Fixture du programme importé du propriétaire et son rejeu.
  final owner = _profileOf(ownerProfileKey);
  final fixture =
      jsonDecode(
            jsonEncode(
              ownerFixture(
                catalog,
                owner,
                _readJson('$_corePath/test/fixtures/owner_program_v33.json.gz'),
              ),
            ),
          )
          as Map<String, Object?>;
  File('$dir/proprietaire.json').writeAsStringSync('${jsonEncode(fixture)}\n');
  File(
    '$dir/PROPRIETAIRE.md',
  ).writeAsStringSync(ownerReplayMarkdown(catalog, owner, fixture));
  stdout.writeln(
    'kalis_adapt $kalisAdaptVersion : rapport écrit dans $dir '
    '(${clock.elapsed.inSeconds} s).',
  );
}
