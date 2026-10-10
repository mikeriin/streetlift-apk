// Exports du lot KM1 (méthode Koach, pipeline/cp/CAHIER_KM.md) :
//   dart run bin/km1.dart --sortie <dossier> [--graines N] [--sans-temoin]
//       [--outils-seuls] [--sans-securite] [--sans-adversaires]
//       [--entree <dossier>]
// Écrit les fiches du catalogue, les saisons de référence de kalis_plan,
// les traces du modèle de vérité et les mesures du témoin kalis_adapt.
// Outils (dossier d'entrée, km1_entree par défaut) : securite/*.json.gz →
// securite_dart.json.gz (constats de sécurité de blocs exportés) ;
// adversaires.json → adversaires_temoin.json.gz (témoin sur athlètes
// adversariaux). --outils-seuls saute les exports.
import 'dart:io';

import 'common.dart';
import 'km_common.dart';

Future<void> main(List<String> args) async {
  final outPath = option(args, '--sortie');
  if (outPath == null) {
    stderr.writeln(
      'usage : dart run bin/km1.dart --sortie <dossier> [--graines N] '
      '[--sans-temoin] [--outils-seuls] [--sans-securite] '
      '[--sans-adversaires] [--entree <dossier>]',
    );
    exitCode = 64;
    return;
  }
  final seeds = option(args, '--graines');
  await runKm1(
    outPath: outPath,
    seeds: seeds == null ? 16 : int.parse(seeds),
    witness: !args.contains('--sans-temoin'),
    exports: !args.contains('--outils-seuls'),
    safety: !args.contains('--sans-securite'),
    adversaries: !args.contains('--sans-adversaires'),
    inputPath: option(args, '--entree') ?? 'km1_entree',
  );
}
