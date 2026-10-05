// Simule un archétype et affiche sa progression.
//
//   dart run kalis_quest:simulate --archetype <nom> --years 3 --seed <n>
//
// Archétypes : debutant_2x, debutant_3x, intermediaire_4x,
// avance_street_4x, expert_6x, irregulier_3x, vacances_5x, maladie_3x
// (suffixe `_tricheur` pour le jumeau qui se surentraîne).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart' show KalisAdapt;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_quest/kalis_quest.dart';
import 'package:kalis_quest/simulation.dart';

const String _corePath = '../kalis_core';

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at < 0 || at + 1 >= args.length ? null : args[at + 1];
}

void main(List<String> args) {
  final name = _option(args, '--archetype');
  if (name == null) {
    stderr.writeln(
      'usage : dart run kalis_quest:simulate --archetype <nom> '
      '[--years 3] [--seed 0]\n'
      'archétypes : ${archetypes.map((a) => a.key).join(', ')}',
    );
    exitCode = 64;
    return;
  }
  final years = int.parse(_option(args, '--years') ?? '3');
  final seed = int.parse(_option(args, '--seed') ?? '0');
  const suffix = '_tricheur';
  final a = name.endsWith(suffix)
      ? cheaterOf(archetypeOf(name.substring(0, name.length - suffix.length)))
      : archetypeOf(name);
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$_corePath/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final profiles = readProfileFixtures(
    jsonDecode(
          File('$_corePath/test/fixtures/profiles.json').readAsStringSync(),
        )
        as Map<String, Object?>,
  );
  final profile = profiles.firstWhere((p) => p.key == a.profileKey).profile;
  final weeks = 52 * years;
  final stage = SimStage(catalog, KalisAdapt().plan, profile, weeks);
  final r = simulateRun(
    engine: KalisQuest(),
    stage: stage,
    a: a,
    seed: seed,
    weeks: weeks,
  );
  stdout.writeln('${a.key} — ${a.note}');
  stdout.writeln('graine $seed, $weeks semaines, profil ${a.profileKey}');
  stdout.writeln('');
  stdout.writeln('semaine  niveau  XP total');
  for (var w = 0; w < weeks; w++) {
    if (w < 4 || (w + 1) % 13 == 0 || w == weeks - 1) {
      stdout.writeln(
        '${(w + 1).toString().padLeft(7)}  '
        '${r.levels[w].toString().padLeft(6)}  '
        '${r.xp[w].toString().padLeft(8)}',
      );
    }
  }
  stdout.writeln('');
  stdout.writeln('niveaux atteints (semaine) : ${r.weekOfLevel}');
  stdout.writeln('XP par origine : ${r.xpBySource}');
  stdout.writeln('Krédits : ${r.kredits} ${r.kreditsBySource}');
  stdout.writeln('quêtes créées : ${r.questsCreated}');
  stdout.writeln('quêtes terminées : ${r.questsDone}');
  stdout.writeln(
    'semaines réussies ${r.weeksSuccess}, en pause ${r.weeksPaused}, '
    'non réussies ${r.weeksFailed} ; meilleure série ${r.bestStreak}',
  );
  stdout.writeln('notes : ${r.grades}');
  stdout.writeln(
    'coffres : ${r.chests} (plus longue attente ${r.maxChestGap} séances)',
  );
  stdout.writeln(
    'séances récompensées ${r.paidSessions} / prévues ${r.plannedSessions} ; '
    'sans récompense pour douleur ${r.painSessions} ; au-delà du programme '
    '${r.extraSessions}',
  );
  stdout.writeln('attributs : ${r.attributes} (meilleurs ${r.attributeBests})');
}
