// Simulation d'un athlète à vérité connue sous kalis_adapt et sous les
// politiques de référence.
//
//   dart run kalis_adapt:simulate --athlete <json> --weeks 24 --seed <n>
//       [--boucle] [--journal <fichier>]
//
// <json> décrit l'athlète (voir `athleteFromJson`) : `key`, `profileKey`
// (profil type de kalis_core), `level` (0 à 3), `weeklyGain`, et au besoin
// `lazy`, `missRate`, `breakFromDay`, `painZone`… Le nom d'un athlète de la
// campagne (`debutant_salle`, `avance_street`…) est accepté à la place d'un
// fichier. `--boucle` : revue chaque semaine, propositions appliquées, bloc
// suivant d'après le résumé d'adaptation. `--journal` écrit le journal
// produit sous kalis_adapt (relisible par `kalis_adapt:replay`).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';

import '../tool/l7/l7_policy.dart';

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

void main(List<String> args) {
  final source = _option(args, '--athlete');
  if (source == null) {
    stderr.writeln(
      'usage : dart run kalis_adapt:simulate --athlete <json|nom> '
      '--weeks 24 --seed <n> [--boucle] [--journal <fichier>]',
    );
    exitCode = 64;
    return;
  }
  final weeks = int.parse(_option(args, '--weeks') ?? '24');
  final seed = int.parse(_option(args, '--seed') ?? '0');
  final loop = args.contains('--boucle');
  final spec = File(source).existsSync()
      ? athleteFromJson(_readJson(source))
      : athleteOf(source);
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$_corePath/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final profile = readProfileFixtures(
    _readJson('$_corePath/test/fixtures/profiles.json'),
  ).firstWhere((p) => p.key == spec.profileKey).profile;
  final program = SimProgram(catalog, KalisPlan(), profile);
  final engine = KalisAdapt();
  final runs = <SimRun>[
    simulate(
      catalog: catalog,
      spec: spec,
      profile: profile,
      seed: seed,
      policy: KalisAdaptPolicy(engine),
      program: program,
      weeks: weeks,
      loop: loop ? engine : null,
    ),
    simulate(
      catalog: catalog,
      spec: spec,
      profile: profile,
      seed: seed,
      policy: DoubleProgressionPolicy(),
      program: program,
      weeks: weeks,
    ),
    simulate(
      catalog: catalog,
      spec: spec,
      profile: profile,
      seed: seed,
      policy: L7Policy(profile.bodyWeightKg ?? 72),
      program: program,
      weeks: weeks,
    ),
  ];
  final out = <String, Object?>{
    'athlete': athleteToJson(spec),
    'weeks': weeks,
    'seed': seed,
    'loop': loop,
    'policies': <String, Object?>{
      for (final run in runs) run.policy: Metrics(<SimRun>[run]).toJson(),
    },
    if (loop) 'loopMetrics': LoopMetrics(<SimRun>[runs.first]).toJson(),
  };
  stdout.writeln(const JsonEncoder.withIndent(' ').convert(out));
  final journal = _option(args, '--journal');
  if (journal != null) {
    final kalis = runs.first;
    File(journal).writeAsStringSync(
      jsonEncode(<String, Object?>{
        'profileKey': spec.profileKey,
        'today': kalis.sessions.last.date.addDays(1).iso,
        'block': kalis.blocks.last.toJson(),
        'log': TrainingLog(sessions: kalis.sessions).toJson(),
      }),
    );
  }
}
