// Lecture des données du banc et exécution : partagé par
// `kalis_bench_cli.dart` (CI) et `run.dart` (ligne de commande complète).
// Seuls les fichiers de `bin/` lisent le disque et l'horloge.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart' show OwnerProgram;

/// Racine du paquet kalis_core (les commandes se lancent depuis la racine
/// de kalis_bench).
const String corePath = '../kalis_core';

/// Valeur de l'option [name], ou `null`.
String? option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at < 0 || at + 1 >= args.length ? null : args[at + 1];
}

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

/// Profils du banc du dossier [dir], triés par nom de fichier.
List<BenchProfile> readProfiles(String dir) {
  final paths = <String>[
    for (final f in Directory(dir).listSync())
      if (f is File && f.path.endsWith('.json')) f.path,
  ]..sort();
  return <BenchProfile>[
    for (final path in paths) BenchProfile.fromJson(readJsonObject(path)),
  ];
}

/// Entrées du banc pour les profils du groupe [scope] (`street`, `autres`
/// ou `tous`).
BenchInputs loadInputs(String scope) {
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final ownerJson = readJsonObject(
    '$corePath/test/fixtures/owner_program_v33.json.gz',
  );
  return BenchInputs(
    catalog: catalog,
    profiles: <BenchProfile>[
      for (final p in readProfiles('profiles'))
        if (scope == 'tous' || p.group == scope) p,
    ],
    owner: OwnerProgram.fromJson(ownerJson),
    ownerPairs: ownerWeekPairs(ownerJson),
  );
}

double _ms(Stopwatch watch) => (watch.elapsedMicroseconds / 100).round() / 10;

/// Fait tourner le banc et écrit le rapport dans [outPath]. Rend le nombre
/// total de violations de sécurité des programmes créés.
int runBench({
  required String outPath,
  required BenchMode mode,
  required String scope,
  required int seed,
}) {
  final total = Stopwatch()..start();
  final inputs = loadInputs(scope);
  final engine = KalisPlan();
  final reports = <ProfileReport>[];
  final timings = <String, Map<String, double>>{};
  for (final profile in inputs.profiles) {
    // Temps de création (premier bloc, passes 1 et 2) sur un moteur neuf.
    final adapted = adaptProfile(profile, catalog: inputs.catalog);
    final request = PlanRequest(
      profile: adapted.profile,
      seed: seed,
      startDate: benchStartDate,
      locks: const <PlanLock>[],
    );
    final create = Stopwatch()..start();
    final fresh = KalisPlan();
    final pass1 = fresh.createPass1(inputs.catalog, request);
    fresh.createPass2(
      inputs.catalog,
      Pass2Request(request: request, pass1: pass1),
    );
    create.stop();
    final all = Stopwatch()..start();
    reports.add(
      evaluateProfile(inputs, engine, profile, mode: mode, seed: seed),
    );
    all.stop();
    timings[profile.key] = <String, double>{
      'createBlockMs': _ms(create),
      'benchMs': _ms(all),
    };
  }
  final files = renderReport(
    inputs,
    reports,
    mode: mode,
    seed: seed,
    scope: scope,
    timingsMs: timings,
  );
  for (final entry in files.entries) {
    final file = File('$outPath/${entry.key}');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(entry.value);
  }
  // Blocs bruts (contrat de `kalis_core`) des programmes créés : ce que le
  // moteur d'évolution reçoit, pour la mise au point des trajectoires.
  for (final profile in inputs.profiles) {
    if (profile.group != 'street') {
      continue;
    }
    final program = generateProgram(
      inputs.catalog,
      engine,
      profile,
      seed: seed,
    );
    final file = File('$outPath/blocs/${profile.key}.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${jsonEncode(<Object?>[for (final b in program.blocks) b.toJson()])}\n',
    );
  }
  total.stop();
  var violations = 0;
  for (final r in reports) {
    violations += r.safety.length;
  }
  stdout.writeln(
    'kalis_bench $kalisBenchVersion : ${reports.length} profils, mode '
    '${mode.code}, $violations violation(s) de sécurité, rapport écrit dans '
    '$outPath (${total.elapsed.inSeconds} s).',
  );
  return violations;
}
