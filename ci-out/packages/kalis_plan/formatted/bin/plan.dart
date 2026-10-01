// Ligne de commande de kalis_plan.
//
//   dart run kalis_plan:plan --profile <json> --seed <n> --pass 1|2
//       [--locks <json>] [--start AAAA-MM-JJ] [--catalog <catalog.json.gz>]
//
// Écrit le programme (JSON) sur la sortie standard. `--profile` : fichier
// JSON d'un `AthleteProfile` (ou d'un objet `{"profile": …}`) ; `--locks` :
// fichier JSON d'une liste de `PlanLock`. `--pass 1` rend la passe 1 ;
// `--pass 2` rend le bloc complet (`ProgramBlock`).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at < 0 || at + 1 >= args.length ? null : args[at + 1];
}

Object? _readJson(String path) {
  final bytes = File(path).readAsBytesSync();
  return jsonDecode(
    utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes),
  );
}

String _defaultCatalogPath() {
  final root = File.fromUri(Platform.script).parent.parent.path;
  final beside = '$root/../kalis_core/data/catalog_v1.json.gz';
  return File(beside).existsSync()
      ? beside
      : '../kalis_core/data/catalog_v1.json.gz';
}

void main(List<String> args) {
  final profilePath = _option(args, '--profile');
  final pass = int.tryParse(_option(args, '--pass') ?? '1');
  final seed = int.tryParse(_option(args, '--seed') ?? '0');
  if (profilePath == null ||
      seed == null ||
      seed < 0 ||
      (pass != 1 && pass != 2)) {
    stderr.writeln(
      'usage : dart run kalis_plan:plan --profile <json> --seed <n> '
      '--pass 1|2 [--locks <json>] [--start AAAA-MM-JJ] [--catalog <fichier>]',
    );
    exitCode = 64;
    return;
  }
  final catalogPath = _option(args, '--catalog') ?? _defaultCatalogPath();
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File(catalogPath).readAsBytesSync()),
  );
  var profileJson = _readJson(profilePath) as Map<String, Object?>;
  final inner = profileJson['profile'];
  if (inner is Map<String, Object?>) {
    profileJson = inner;
  }
  final locksPath = _option(args, '--locks');
  final locks = <PlanLock>[
    if (locksPath != null)
      for (final item in _readJson(locksPath) as List<Object?>)
        PlanLock.fromJson(item as Map<String, Object?>),
  ];
  final start = _option(args, '--start');
  final request = PlanRequest(
    profile: AthleteProfile.fromJson(profileJson),
    seed: seed,
    startDate: start == null ? CivilDate(2026, 10, 5) : CivilDate.parse(start),
    locks: locks,
  );
  final engine = KalisPlan();
  final pass1 = engine.createPass1(catalog, request);
  final Map<String, Object?> output;
  if (pass == 1) {
    output = pass1.toJson();
  } else {
    final pass2 = engine.createPass2(
      catalog,
      Pass2Request(request: request, pass1: pass1),
    );
    output = ProgramBlock(pass1: pass1, pass2: pass2).toJson();
  }
  stdout.writeln(const JsonEncoder.withIndent(' ').convert(output));
}
