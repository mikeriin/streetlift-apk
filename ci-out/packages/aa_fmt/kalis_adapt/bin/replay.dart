// Rejeu d'un journal par kalis_adapt : résumé d'adaptation, capacités
// estimées, propositions, records, séance prescrite, journal du moteur.
//
//   dart run kalis_adapt:replay --journal <json> [--cle <clé>]
//       [--semaine <n>] [--jour <n>] [--sortie <fichier>]
//
// <json> (ou <json>.gz) est :
// - une fixture « bloc + journal » : `profileKey` (profil type de
//   kalis_core) ou `profile`, `block`, `log`, `today`, et facultativement
//   `next` {weekIndex, dayIndex} — par exemple
//   `test/fixtures/proprietaire.json.gz`, le programme importé du
//   propriétaire ;
// - ou le fichier des journaux synthétiques de kalis_core
//   (`../kalis_core/test/fixtures/journals.json.gz`) : `--cle` choisit le
//   journal (par défaut le premier) ; le bloc est alors celui que
//   kalis_plan crée pour le profil, et les estimations sont comparées à la
//   vérité du journal.
//
// `--semaine` et `--jour` (à partir de 1) désignent la séance à prescrire.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/report.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';

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
  final path = _option(args, '--journal');
  if (path == null) {
    stderr.writeln(
      'usage : dart run kalis_adapt:replay --journal <json> [--cle <clé>] '
      '[--semaine <n>] [--jour <n>] [--sortie <fichier>]',
    );
    exitCode = 64;
    return;
  }
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$_corePath/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final profiles = readProfileFixtures(
    _readJson('$_corePath/test/fixtures/profiles.json'),
  );
  AthleteProfile profileOf(String key) =>
      profiles.firstWhere((p) => p.key == key).profile;

  var json = _readJson(path);
  final truth = <String, double>{};
  String title;
  final journals = json['journals'];
  if (journals is List<Object?>) {
    final key = _option(args, '--cle');
    Map<String, Object?>? picked;
    for (final j in journals) {
      final journal = j! as Map<String, Object?>;
      if (key == null || journal['key'] == key) {
        picked = journal;
        break;
      }
    }
    if (picked == null) {
      stderr.writeln('journal inconnu : $key');
      exitCode = 66;
      return;
    }
    final rawTruth = picked['truth'];
    final weeks = picked['weeks'];
    if (rawTruth is Map<String, Object?> && weeks is int) {
      for (final e in rawTruth.entries) {
        final t = e.value;
        if (t is Map<String, Object?>) {
          final start = t['capacityStart'];
          final gain = t['weeklyGain'];
          if (start is num && gain is num) {
            truth[e.key] = (start * (1 + gain * weeks)).toDouble();
          }
        }
      }
    }
    title = 'kalis_adapt — rejeu du journal `${picked['key']}`';
    json = picked;
  } else {
    title = 'kalis_adapt — rejeu de `$path`';
  }
  final profileKey = json['profileKey'];
  final rawProfile = json['profile'];
  final profile = rawProfile is Map<String, Object?>
      ? AthleteProfile.fromJson(rawProfile)
      : profileOf(profileKey! as String);
  final log = TrainingLog.fromJson(json['log']! as Map<String, Object?>);
  final rawBlock = json['block'];
  final block = rawBlock is Map<String, Object?>
      ? ProgramBlock.fromJson(rawBlock)
      : SimProgram(catalog, KalisPlan(), profile).block(0);
  final rawToday = json['today'];
  final today = rawToday is String
      ? CivilDate.parse(rawToday)
      : (log.sessions.isEmpty
            ? block.pass1.startDate
            : log.sessions.last.date.addDays(1));
  final next = json['next'];
  int? weekIndex;
  int? dayIndex;
  if (next is Map<String, Object?>) {
    weekIndex = next['weekIndex'] as int?;
    dayIndex = next['dayIndex'] as int?;
  }
  final week = _option(args, '--semaine');
  final day = _option(args, '--jour');
  if (week != null && day != null) {
    weekIndex = int.parse(week) - 1;
    dayIndex = int.parse(day) - 1;
  }
  final text = replayMarkdown(
    catalog,
    KalisAdapt(),
    title: title,
    profile: profile,
    block: block,
    log: log,
    today: today,
    weekIndex: weekIndex,
    dayIndex: dayIndex,
    truth: truth,
  );
  final output = _option(args, '--sortie');
  if (output == null) {
    stdout.write(text);
  } else {
    File(output).writeAsStringSync(text);
  }
}
