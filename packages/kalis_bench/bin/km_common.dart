// Exports du lot KM1 (méthode Koach) : partagé par `km1.dart` et, sur la
// branche de contrôle, par l'entrée du rapport. Seuls les fichiers de `bin/`
// lisent le disque.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:kalis_adapt/kalis_adapt.dart'
    show EnduranceKind, ExerciseBook, enduranceKindOf;
import 'package:kalis_adapt/simulation.dart' show TruthKind;
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'common.dart';

void _writeGz(String path, Object? value) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(gzip.encode(utf8.encode(jsonEncode(value))));
}

Map<String, Object?> _profileJson(String key) =>
    readSeasonJson().firstWhere((j) => j['key'] == key);

List<Object?> _referenceOf(String key) {
  final inputs = loadInputs('tous');
  final json = _profileJson(key);
  final plan = KalisPlan();
  final out = <Object?>[];
  String? baseBlocks;
  for (final scenario in SeasonScenario.values) {
    if (!seasonScenarioApplies(json, scenario)) {
      continue;
    }
    final season = kmReferenceSeason(inputs.catalog, plan, json, scenario);
    // Les scénarios qui ne changent pas le plan renvoient aux blocs de la
    // saison de référence (fichiers plus petits).
    final text = jsonEncode(season['blocks']);
    if (scenario == SeasonScenario.base) {
      baseBlocks = text;
    } else if (text == baseBlocks) {
      season['blocks'] = null;
      season['blocksAs'] = SeasonScenario.base.code;
    }
    out.add(season);
  }
  return out;
}

List<Object?> _witnessOf(String key, int seeds) {
  final inputs = loadInputs('tous');
  final json = _profileJson(key);
  final plan = KalisPlan();
  return <Object?>[
    for (final scenario in SeasonScenario.values)
      if (seasonScenarioApplies(json, scenario))
        kmWitnessSeason(inputs.catalog, plan, json, scenario, seeds: seeds),
  ];
}

/// Profils et scénarios des traces du modèle de vérité de force.
const List<(String, SeasonScenario)> _traceCases = <(String, SeasonScenario)>[
  ('street_07_avance_streetlifting_competition', SeasonScenario.base),
  ('street_07_avance_streetlifting_competition', SeasonScenario.elbow),
  ('street_05_inter_calisthenie_front_lever', SeasonScenario.shoulder),
  ('street_01_debutant_complet', SeasonScenario.illness),
  ('street_10_elite_figures', SeasonScenario.base),
  ('autres_02_hypertrophie_intermediaire', SeasonScenario.missed),
];

/// Profils des traces du modèle de vérité d'endurance.
const List<String> _enduranceCases = <String>[
  'autres_06_semi_marathon_intermediaire',
  'autres_08_crossfit_intermediaire',
  'street_17_hybride_street_course',
];

List<Object?> _traces() {
  final inputs = loadInputs('tous');
  final catalog = inputs.catalog;
  final plan = KalisPlan();
  final out = <Object?>[];
  for (final (key, scenario) in _traceCases) {
    final json = _profileJson(key);
    final season = KmSeason(catalog, json, scenario);
    final profile = season.adapted.profile;
    final program = generateProgram(
      catalog,
      plan,
      BenchProfile.fromJson(json),
      seed: 0,
    );
    final ids = <String>[];
    for (final b in program.blocks) {
      for (final w in b.pass2.weeks) {
        for (final d in w.days) {
          for (final it in d.items) {
            if (!ids.contains(it.exerciseId) && ids.length < 14) {
              ids.add(it.exerciseId);
            }
          }
        }
      }
    }
    for (final kind in TruthKind.values) {
      for (var seed = 0; seed < 2; seed++) {
        out.add(<String, Object?>{
          'key': key,
          'scenario': scenario.code,
          'specJson': season.specJson,
          'profile': profile.toJson(),
          'trace': kmTruthTrace(catalog, profile, season.spec, kind, seed, ids),
        });
      }
    }
  }
  return out;
}

List<Object?> _enduranceTraces() {
  final inputs = loadInputs('tous');
  final catalog = inputs.catalog;
  final plan = KalisPlan();
  final out = <Object?>[];
  for (final key in _enduranceCases) {
    final json = _profileJson(key);
    final bench = BenchProfile.fromJson(json);
    final program = generateProgram(catalog, plan, bench, seed: 0);
    final book = ExerciseBook(catalog, program.profile);
    final runs = <ExercisePrescription>[];
    final wods = <ExercisePrescription>[];
    for (final b in program.blocks) {
      for (final w in b.pass2.weeks) {
        for (final d in w.days) {
          for (final it in d.items) {
            final info = book.find(it.exerciseId);
            final kind = info == null ? null : enduranceKindOf(info);
            if (it.sets <= 0) {
              continue;
            }
            if (kind == EnduranceKind.run && runs.length < 40) {
              runs.add(it);
            } else if (kind == EnduranceKind.conditioning && wods.length < 40) {
              wods.add(it);
            }
          }
        }
      }
    }
    for (final kind in TruthKind.values) {
      for (var seed = 0; seed < 2; seed++) {
        out.add(<String, Object?>{
          'key': key,
          'trace': kmEnduranceTrace(bench.level.index, kind, seed, runs, wods),
        });
      }
    }
  }
  return out;
}

Object? _readJson(File file) {
  final bytes = file.readAsBytesSync();
  final text = file.path.endsWith('.gz')
      ? utf8.decode(gzip.decode(bytes))
      : utf8.decode(bytes);
  return jsonDecode(text);
}

/// Sécurité des blocs déposés dans [dir] (`*.json.gz`, chacun
/// `{"key", "scenario", "label", "blockWeeks", "blocks"}`) : constats de
/// `safetyFindings`, un objet par fichier, dans l'ordre des noms.
List<Object?> _safetyOfDir(String dir) {
  final inputs = loadInputs('tous');
  final files = <File>[
    for (final f in Directory(dir).listSync())
      if (f is File && f.path.endsWith('.json.gz')) f,
  ]..sort((a, b) => a.path.compareTo(b.path));
  final out = <Object?>[];
  for (final file in files) {
    final entry = benchObject(_readJson(file), file.path);
    final key = benchString(entry, 'key');
    final scenario = kmScenarioOf(benchString(entry, 'scenario'));
    List<int>? blockWeeks;
    if (entry['blockWeeks'] != null) {
      blockWeeks = <int>[
        for (final v in benchList(entry, 'blockWeeks'))
          if (v is int) v else throw FormatException('blockWeeks', v),
      ];
    }
    final blocks = benchList(entry, 'blocks');
    final result = kmSafetyOfBlocks(
      inputs.catalog,
      _profileJson(key),
      scenario,
      blocks,
      blockWeeks,
    );
    out.add(<String, Object?>{
      'file': file.uri.pathSegments.last,
      'key': key,
      'scenario': scenario.code,
      'label': entry['label'],
      'weeks': result['weeks'],
      'blockWeeks': blockWeeks,
      'findings': result['findings'],
      'blocks': blocks,
    });
  }
  return out;
}

/// Saison du témoin sur l'athlète adversarial [adversary].
Map<String, Object?> _adversaryOf(Map<String, Object?> adversary) {
  final inputs = loadInputs('tous');
  return kmAdversaryRun(
    inputs.catalog,
    KalisPlan(),
    _profileJson(benchString(adversary, 'key')),
    adversary,
  );
}

/// Outils du lot KM1 sur les entrées de [inputPath] : sécurité de blocs
/// (`securite/*.json.gz` → `securite_dart.json.gz`) et témoin sur athlètes
/// adversariaux (`adversaires.json` → `adversaires_temoin.json.gz`).
Future<void> _runKm1Tools({
  required String outPath,
  required String inputPath,
  required bool safety,
  required bool adversaries,
  required int parallel,
}) async {
  final safetyDir = Directory('$inputPath/securite');
  if (safety && safetyDir.existsSync()) {
    final dir = safetyDir.path;
    final found = await Isolate.run(() => _safetyOfDir(dir));
    _writeGz('$outPath/securite_dart.json.gz', found);
    stdout.writeln('sécurité de blocs : ${found.length} fichier(s).');
  }
  final adversaryFile = File('$inputPath/adversaires.json');
  if (adversaries && adversaryFile.existsSync()) {
    final list = _readJson(adversaryFile);
    if (list is! List<Object?>) {
      throw FormatException('adversaires.json : liste attendue');
    }
    final entries = <Map<String, Object?>>[
      for (final a in list) benchObject(a, 'adversaires'),
    ];
    final results = List<Object?>.filled(entries.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < entries.length) {
        final k = next++;
        final entry = entries[k];
        results[k] = await Isolate.run(() => _adversaryOf(entry));
      }
    }

    await Future.wait(<Future<void>>[
      for (var i = 0; i < parallel; i++) worker(),
    ]);
    _writeGz('$outPath/adversaires_temoin.json.gz', results);
    stdout.writeln('athlètes adversariaux : ${entries.length}.');
  }
}

/// Écrit les exports KM1 dans [outPath] : fiches du catalogue, saisons de
/// référence, traces du modèle de vérité et, avec [witness], mesures du
/// témoin sur [seeds] graines par modèle de vérité. Avec [exports] faux,
/// seuls les outils sont lancés. Outils (lot KM1, sécurité) : si
/// `[inputPath]/securite/` existe et [safety] est vrai, constats de
/// sécurité des blocs déposés (`securite_dart.json.gz`) ; si
/// `[inputPath]/adversaires.json` existe et [adversaries] est vrai, saisons
/// du témoin sur ces athlètes (`adversaires_temoin.json.gz`).
Future<void> runKm1({
  required String outPath,
  int seeds = 16,
  bool witness = true,
  int parallel = 4,
  bool exports = true,
  bool safety = true,
  bool adversaries = true,
  String inputPath = 'km1_entree',
}) async {
  final watch = Stopwatch()..start();
  await _runKm1Tools(
    outPath: outPath,
    inputPath: inputPath,
    safety: safety,
    adversaries: adversaries,
    parallel: parallel,
  );
  if (!exports) {
    stdout.writeln('outils KM1 (${watch.elapsed.inSeconds} s).');
    return;
  }
  var count = seeds;
  final file = File('km1_seeds.txt');
  if (file.existsSync()) {
    count = int.parse(
      file.readAsStringSync().trim().split(RegExp(r'\s+')).first,
    );
  }
  _writeGz(
    '$outPath/catalogue_infos.json.gz',
    kmCatalogInfos(loadInputs('tous').catalog),
  );
  _writeGz('$outPath/traces_verite.json.gz', await Isolate.run(_traces));
  _writeGz(
    '$outPath/traces_endurance.json.gz',
    await Isolate.run(_enduranceTraces),
  );
  final keys = <String>[for (final j in readSeasonJson()) j['key']! as String];
  var next = 0;
  Future<void> worker() async {
    while (next < keys.length) {
      final key = keys[next++];
      final reference = await Isolate.run(() => _referenceOf(key));
      _writeGz('$outPath/reference/$key.json.gz', reference);
      if (witness) {
        final measured = await Isolate.run(() => _witnessOf(key, count));
        _writeGz('$outPath/temoin/$key.json.gz', measured);
      }
    }
  }

  await Future.wait(<Future<void>>[
    for (var i = 0; i < parallel; i++) worker(),
  ]);
  stdout.writeln(
    'exports KM1 : ${keys.length} profils, $count graines pour le témoin '
    '(${watch.elapsed.inSeconds} s).',
  );
}
