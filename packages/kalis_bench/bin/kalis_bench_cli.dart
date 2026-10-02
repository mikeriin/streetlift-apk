// Banc complet pour la CI (`ci-paquets.yml`) :
//
//   dart run bin/kalis_bench_cli.dart --rapport <dossier>
//
// Tous les profils, croisement kalis_plan × kalis_adapt, graine 0. Écrit
// dans <dossier> : rapport.json, RAPPORT.md, programmes/<profil>.md et
// .json, trajectoires/<profil>.md. Le code de sortie est 0 même s'il y a
// des violations de sécurité : le banc mesure, il ne bloque pas la CI des
// moteurs qu'il n'a pas le droit de modifier.
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';

import 'common.dart';

void main(List<String> args) {
  final outPath = option(args, '--rapport');
  if (outPath == null) {
    stderr.writeln('usage : dart run bin/kalis_bench_cli.dart --rapport <dossier>');
    exitCode = 64;
    return;
  }
  runBench(
    outPath: outPath,
    mode: BenchMode.croisement,
    scope: 'tous',
    seed: 0,
  );
}
