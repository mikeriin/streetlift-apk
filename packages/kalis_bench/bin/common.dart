// Lecture des données du banc et exécution : partagé par
// `kalis_bench_cli.dart` (CI) et `run.dart` (ligne de commande complète).
// Seuls les fichiers de `bin/` lisent le disque et l'horloge.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kalis_adapt/simulation.dart' show TruthKind, athleteFromJson;
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
    // Profil au contrat de `kalis_core` (sortie de l'adaptateur) et
    // réglages de l'athlète simulé : fixtures des tests de `kalis_adapt`.
    final profileFile = File('$outPath/profils/${profile.key}.json');
    profileFile.parent.createSync(recursive: true);
    profileFile.writeAsStringSync(
      '${jsonEncode(<String, Object?>{'profile': program.profile.toJson(), 'athlete': athleteSpecJson(profile)})}\n',
    );
  }
  // Blocs tels que la trajectoire les a suivis (propositions appliquées,
  // blocs suivants construits d'après le résumé d'adaptation) et résumés
  // de fin de semaine : mise au point du croisement.
  for (final r in reports) {
    final t = r.trajectory;
    if (t == null || r.profile.group != 'street') {
      continue;
    }
    final file = File('$outPath/blocs_realises/${r.profile.key}.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${jsonEncode(<String, Object?>{
        'blockWeeks': t.run.blockWeeks,
        'blocks': <Object?>[for (final b in t.run.blocks) b.toJson()],
        'summaries': <Object?>[
          for (final (week, review) in t.run.reviews) <String, Object?>{
              'week': week,
              'summary': review.summary.toJson(),
              'proposals': <Object?>[for (final p in review.proposals) p.toJson()],
            },
        ],
      })}\n',
    );
  }
  // Séries de la trajectoire racontée (mise au point) : chaque séance
  // servie, faite, et ce que le simulateur sait de l'effort réel.
  for (final r in reports) {
    final t = r.trajectory;
    if (t == null || r.profile.group != 'street') {
      continue;
    }
    final file = File('$outPath/series/${r.profile.key}.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${jsonEncode(<String, Object?>{
        'sessions': <Object?>[
          for (final s in t.run.served) <String, Object?>{
              'week': s.week,
              'simDay': s.simDay,
              'plan': s.plan.toJson(),
              'record': s.record.toJson(),
              'advices': <Object?>[for (final a in s.advices) a.toJson()],
            },
        ],
        'rows': <Object?>[
          for (final x in t.run.sets) <Object?>[x.week, x.simDay, x.exerciseId, x.slotId, x.setIndex, x.role?.code, x.technique?.code, x.loadKg, x.totalKg, x.amount, x.targetLow, x.targetHigh, x.wantRir, x.trueRir, x.failed, x.open, x.test, x.dayMax, x.reachable],
        ],
        'estimates': <Object?>[
          for (final e in t.run.estimates) <Object?>[e.week, e.exerciseId, e.capacity, e.truth, e.relSd],
        ],
      })}\n',
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

Map<String, Object?> _campaignOf(String key, int seeds) {
  final inputs = loadInputs('street');
  final bench = inputs.profiles.firstWhere((p) => p.key == key);
  final adapted = adaptProfile(bench, catalog: inputs.catalog);
  return streetCampaignOf(
    inputs.catalog,
    KalisPlan(),
    bench,
    adapted.profile,
    seeds: seeds,
  );
}

/// Lance la campagne du profil [key] dans un isolat (la fermeture ne
/// capture que des valeurs simples).
Future<Map<String, Object?>> _spawnCampaign(String key, int seeds) =>
    Isolate.run(() => _campaignOf(key, seeds));

/// Campagne street (voir `streetCampaignOf`) : un isolat par profil, au
/// plus [parallel] à la fois ; écrit `campagne_street.json` et
/// `CAMPAGNE_STREET.md` dans [outPath]. Le fichier `campaign_seeds.txt` à
/// la racine du paquet, s'il existe, remplace [seeds] (essais rapides).
Future<void> runStreetCampaign({
  required String outPath,
  int seeds = 100,
  int parallel = 4,
}) async {
  final watch = Stopwatch()..start();
  var count = seeds;
  final file = File('campaign_seeds.txt');
  if (file.existsSync()) {
    count = int.parse(
      file.readAsStringSync().trim().split(RegExp(r'\s+')).first,
    );
  }
  final keys = <String>[for (final p in loadInputs('street').profiles) p.key];
  final results = <String, Map<String, Object?>>{};
  var next = 0;
  Future<void> worker() async {
    while (next < keys.length) {
      final key = keys[next++];
      results[key] = await _spawnCampaign(key, count);
    }
  }

  await Future.wait(<Future<void>>[
    for (var i = 0; i < parallel; i++) worker(),
  ]);
  final ordered = <Map<String, Object?>>[for (final k in keys) results[k]!];
  File('$outPath/campagne_street.json').writeAsStringSync(
    '${jsonEncode(<String, Object?>{'benchVersion': kalisBenchVersion, 'seeds': count, 'profiles': ordered})}\n',
  );
  File(
    '$outPath/CAMPAGNE_STREET.md',
  ).writeAsStringSync(streetCampaignMarkdown(ordered));
  stdout.writeln(
    'campagne street : ${keys.length} profils × $count graines × 3 modèles '
    '(${watch.elapsed.inSeconds} s).',
  );
}

/// Profils street bruts (JSON) du dossier `profiles`, triés par nom de
/// fichier.
List<Map<String, Object?>> readStreetJson() {
  final paths = <String>[
    for (final f in Directory('profiles').listSync())
      if (f is File && f.path.endsWith('.json')) f.path,
  ]..sort();
  return <Map<String, Object?>>[
    for (final path in paths)
      if (readJsonObject(path)['group'] == 'street') readJsonObject(path),
  ];
}

/// Saisons racontées (lot CX) : pour chaque profil street, la saison de
/// référence sous le modèle de vérité B (les modèles A et C mesurés à
/// côté) et chaque scénario imposé sous le modèle B. Écrit dans
/// [outPath]/saisons : `<profil>.md` (saison), `<profil>.json` (programme
/// tel que les blocs l'ont réalisé, lu par `tool/panel_export.py`),
/// `scenarios/<profil>_<scénario>.md`, et `SECURITE.md` (violations de
/// sécurité des programmes réalisés).
void writeSeasonExports(String outPath) {
  final inputs = loadInputs('street');
  final catalog = inputs.catalog;
  final plan = KalisPlan();
  final safety = StringBuffer()
    ..writeln('# Sécurité des saisons racontées')
    ..writeln()
    ..writeln(
      'Violations de sécurité (critères calculables du banc) du programme '
      'tel que les blocs l\'ont réalisé, sous le modèle de vérité B, graine '
      '0, saison de référence et scénarios.',
    )
    ..writeln()
    ..writeln('| Profil | Scénario | Violations |')
    ..writeln('| --- | --- | --- |');
  final details = StringBuffer();
  for (final json in readStreetJson()) {
    for (final scenario in SeasonScenario.values) {
      final scenarioJson = seasonProfileJson(json, scenario);
      final bench = BenchProfile.fromJson(scenarioJson);
      final adapted = adaptProfile(
        BenchProfile.fromJson(
          scenario == SeasonScenario.second ? scenarioJson : json,
        ),
        catalog: catalog,
      );
      final weeks = seasonWeeksOf(json, scenario);
      final spec = athleteFromJson(seasonSpecJson(bench, scenario));
      final changes = seasonChanges(json, scenario);
      Trajectory sim(TruthKind truth) => simulateTrajectory(
        catalog,
        plan,
        bench,
        adapted.profile,
        weeks: weeks,
        truth: truth,
        spec: spec,
        changes: changes,
      );
      final main = sim(TruthKind.b);
      final view = ProgramView(
        catalog,
        BenchProgram(
          bench: bench,
          adapted: adapted,
          request: PlanRequest(
            profile: adapted.profile,
            seed: 0,
            startDate: benchStartDate,
            locks: const <PlanLock>[],
          ),
          blocks: servedBlocksOf(main.run),
          horizonWeeks: weeks,
        ),
      );
      final found = safetyFindings(view, bench);
      safety.writeln(
        '| ${bench.key} | ${scenario.code} | ${found.length}'
        '${found.isEmpty ? '' : ' (${found.map((f) => f.code).toSet().join(', ')})'} |',
      );
      for (final f in found) {
        details.writeln(
          '- `${bench.key}`, ${scenario.code}, `${f.code}` : ${f.message}',
        );
      }
      if (scenario == SeasonScenario.base) {
        final others = <Trajectory>[sim(TruthKind.a), sim(TruthKind.c)];
        _write(
          '$outPath/saisons/${bench.key}.md',
          seasonMarkdown(main, catalog, others: others),
        );
        _write(
          '$outPath/saisons/${bench.key}.json',
          '${jsonEncode(programJson(view))}\n',
        );
      } else {
        _write(
          '$outPath/saisons/scenarios/${bench.key}_${scenario.code}.md',
          seasonMarkdown(main, catalog, scenario: scenario),
        );
      }
    }
  }
  if (details.isNotEmpty) {
    safety
      ..writeln()
      ..writeln('## Détail')
      ..writeln()
      ..write(details.toString());
  }
  _write('$outPath/saisons/SECURITE.md', safety.toString());
}

void _write(String path, String text) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(text);
}

Map<String, Object?> _seasonOf(String key, int seeds) {
  final inputs = loadInputs('street');
  final json = readStreetJson().firstWhere((j) => j['key'] == key);
  return seasonCampaignOf(inputs.catalog, KalisPlan(), json, seeds: seeds);
}

/// Saisons croisées (voir `seasonCampaignOf`) : un isolat par profil, au
/// plus [parallel] à la fois ; écrit `saisons.json` et `SAISONS.md` dans
/// [outPath]. Le fichier `season_seeds.txt` à la racine du paquet, s'il
/// existe, remplace [seeds] (essais rapides).
Future<void> runSeasonCampaign({
  required String outPath,
  int seeds = 100,
  int parallel = 4,
}) async {
  final watch = Stopwatch()..start();
  var count = seeds;
  final file = File('season_seeds.txt');
  if (file.existsSync()) {
    count = int.parse(
      file.readAsStringSync().trim().split(RegExp(r'\s+')).first,
    );
  }
  final keys = <String>[for (final j in readStreetJson()) j['key']! as String];
  final results = <String, Map<String, Object?>>{};
  var next = 0;
  Future<void> worker() async {
    while (next < keys.length) {
      final key = keys[next++];
      results[key] = await Isolate.run(() => _seasonOf(key, count));
    }
  }

  await Future.wait(<Future<void>>[
    for (var i = 0; i < parallel; i++) worker(),
  ]);
  final ordered = <Map<String, Object?>>[for (final k in keys) results[k]!];
  _write(
    '$outPath/saisons.json',
    '${jsonEncode(<String, Object?>{'benchVersion': kalisBenchVersion, 'seeds': count, 'profiles': ordered})}\n',
  );
  _write('$outPath/SAISONS.md', seasonCampaignMarkdown(ordered));
  stdout.writeln(
    'saisons croisées : ${keys.length} profils × $count graines × 3 modèles '
    '× ${SeasonScenario.values.length} saisons (${watch.elapsed.inSeconds} s).',
  );
}
