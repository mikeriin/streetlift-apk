// Banc à la demande :
//
//   dart run kalis_bench:run --moteur plan|adapt|croisement
//       --profils street|autres|tous --graine <n> --sortie <dossier>
//
// Rapports JSON et Markdown, exports lisibles ; déterministe (graine).
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';

import 'common.dart';

void main(List<String> args) {
  final outPath = option(args, '--sortie');
  final scope = option(args, '--profils') ?? 'tous';
  if (outPath == null ||
      (scope != 'street' && scope != 'autres' && scope != 'tous')) {
    stderr.writeln(
      'usage : dart run kalis_bench:run --moteur plan|adapt|croisement '
      '--profils street|autres|tous --graine <n> --sortie <dossier>',
    );
    exitCode = 64;
    return;
  }
  runBench(
    outPath: outPath,
    mode: BenchMode.fromCode(option(args, '--moteur') ?? 'croisement'),
    scope: scope,
    seed: int.parse(option(args, '--graine') ?? '0'),
  );
}
