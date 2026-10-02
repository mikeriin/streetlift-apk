// Simulateur de kalis_core : rapport de contrôle du catalogue, des contrats
// et des jeux de données communs.
//
//   dart run bin/kalis_core_cli.dart --rapport <dossier>
//
// Écrit `kalis_core_rapport.json` et `kalis_core_rapport.txt` dans le
// dossier. Code de sortie 1 si un contrôle échoue.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';

/// Budget de chargement du catalogue (PIPELINE_GP.md §2 et prompt GC).
const int loadBudgetMs = 150;

Map<String, Object?> _readJson(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

Map<String, int> _count<T>(Iterable<T> values, String Function(T) label) {
  final out = <String, int>{};
  for (final v in values) {
    out.update(label(v), (n) => n + 1, ifAbsent: () => 1);
  }
  return Map<String, int>.fromEntries(
    out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

void main(List<String> args) {
  final at = args.indexOf('--rapport');
  if (at < 0 || at + 1 >= args.length) {
    stderr.writeln(
      'usage : dart run bin/kalis_core_cli.dart --rapport <dossier>',
    );
    exitCode = 64;
    return;
  }
  final out = Directory(args[at + 1])..createSync(recursive: true);
  var root = File.fromUri(Platform.script).parent.parent.path;
  if (!File('$root/data/catalog_v1.json.gz').existsSync()) {
    root = Directory.current.path;
  }
  final failures = <String>[];

  // 1. Chargement du catalogue : meilleur et médiane de 9 essais.
  final compressed = File('$root/data/catalog_v1.json.gz').readAsBytesSync();
  final timesMicros = <int>[];
  late Catalog catalog;
  for (var i = 0; i < 9; i++) {
    final watch = Stopwatch()..start();
    catalog = Catalog.fromJsonBytes(gzip.decode(compressed));
    watch.stop();
    timesMicros.add(watch.elapsedMicroseconds);
  }
  timesMicros.sort();
  final bestMs = timesMicros.first / 1000;
  final medianMs = timesMicros[timesMicros.length ~/ 2] / 1000;
  if (bestMs > loadBudgetMs) {
    failures.add('chargement du catalogue : $bestMs ms > $loadBudgetMs ms');
  }

  // 2. Distribution des champs calculés.
  final ex = catalog.exercises;
  final distributions = <String, Object?>{
    'discipline': _count(ex, (e) => e.discipline.code),
    'niveau': _count(ex, (e) => e.level.code),
    'schema': _count(ex, (e) => e.pattern.code),
    'famille': _count(ex, (e) => e.family.code),
    'plan': _count(ex, (e) => e.plane.code),
    'articularite': _count(ex, (e) => e.articularity.code),
    'regime': _count(ex, (e) => e.contractionMode.code),
    'difficulte': _count(ex, (e) => e.difficulty.toString().padLeft(2, '0')),
    'lieu': _count(ex.expand((e) => e.places), (p) => p.code),
    'type_charge': _count(ex, (e) => e.loadType.code),
    'unite': _count(ex, (e) => e.unit.code),
    'lateralite': _count(ex, (e) => e.laterality.code),
    'fatigue_systemique': _count(ex, (e) => '${e.systemicFatigue}'),
    'fatigue_locale': _count(ex, (e) => '${e.localFatigue}'),
    'fraction_source': _count(
      ex,
      (e) => e.bodyweightFraction?.source.code ?? 'aucune',
    ),
    for (final joint in Joint.values)
      'contrainte_${joint.code}': _count(ex, (e) => e.stressOn(joint).code),
  };

  // 3. Jeux de données communs.
  final profiles = readProfileFixtures(
    _readJson('$root/test/fixtures/profiles.json'),
  );
  final journals = readJournalFixtures(
    _readJson('$root/test/fixtures/journals.json.gz'),
  );
  var profileViolations = 0;
  for (final p in profiles) {
    final v = <Violation>[
      ...p.profile.validate(),
      ...catalog.checkProfile(p.profile),
    ];
    profileViolations += v.length;
    for (final violation in v) {
      failures.add('profil ${p.key} : $violation');
    }
  }
  var journalViolations = 0;
  var sessions = 0;
  var sets = 0;
  var unrated = 0;
  var resume = 0;
  final flames = <String, int>{};
  for (final j in journals) {
    final ids = <String>{};
    j.log.collectExerciseIds(ids);
    final v = <Violation>[
      ...j.log.validate(),
      ...catalog.checkExerciseIds(ids),
    ];
    journalViolations += v.length;
    for (final violation in v) {
      failures.add('journal ${j.key} : $violation');
    }
    sessions += j.log.sessions.length;
    resume += j.log.sessions.where((s) => s.resume).length;
    for (final s in j.log.sessions) {
      for (final set in s.sets) {
        sets++;
        final note = set.flames;
        if (note == null) {
          unrated++;
        } else {
          final key = note.toString().padLeft(2, '0');
          flames.update(key, (n) => n + 1, ifAbsent: () => 1);
        }
      }
    }
  }

  // 3 bis. Profil v3 (0.4.0) : profils types, migration, parcours de
  // questions (nombre de questions vues par profil type).
  final parcours = ProfileQuestionnaire.fromJson(
    _readJson('$root/data/parcours_v3.json'),
  );
  final v3Json = _readJson('$root/test/fixtures/profiles_v3.json');
  final v3Profiles = readProfileFixtures(v3Json);
  final todayYear = v3Json['todayYear']! as int;
  final questionCounts = <String, Object?>{};
  for (final p in v3Profiles) {
    final v = <Violation>[
      ...p.profile.validate(),
      ...catalog.checkProfile(p.profile),
    ];
    for (final violation in v) {
      failures.add('profil v3 ${p.key} : $violation');
    }
    final json = p.profile.toJson();
    final all = parcours.visibleQuestions(json, todayYear: todayYear);
    final added = parcours.visibleQuestions(
      json,
      todayYear: todayYear,
      since: 3,
    );
    questionCounts[p.key] = <String, Object?>{
      'questions': all.length,
      'nouvelles': added.length,
      'tests_permis': <String>[
        for (final t in parcours.eligibleTests(json, todayYear: todayYear))
          t.id,
      ],
    };
  }
  var migrationFailures = 0;
  for (final p in profiles) {
    final migrated = p.profile.toSchema3();
    if (migrated.copyWith(schemaVersion: 2) != p.profile ||
        migrated.schema3FieldsPresent.isNotEmpty ||
        migrated.validate().isNotEmpty) {
      migrationFailures++;
      failures.add('migration du profil ${p.key} vers le schéma 3');
    }
  }

  // 4. Contrats : inventaire et conversion des flammes.
  final flameTable = <String, Object?>{
    for (var f = Flames.max; f >= Flames.min; f--) '$f': Flames.toRir(f),
  };
  for (var f = Flames.min; f <= Flames.max; f++) {
    if (Flames.fromRir(Flames.toRir(f)) != f) {
      failures.add('flammes : aller-retour inexact pour $f');
    }
  }

  final report = <String, Object?>{
    'paquet': 'kalis_core',
    'version': kalisCoreVersion,
    'catalogue': <String, Object?>{
      'schema': catalog.schemaVersion,
      'regles_version': catalog.rulesVersion,
      'source_version': catalog.sourceVersion,
      'source_sha256': catalog.sourceSha256,
      'exercices': catalog.length,
      'octets_compresses': compressed.length,
      'chargement_ms_meilleur': bestMs,
      'chargement_ms_mediane': medianMs,
      'chargement_budget_ms': loadBudgetMs,
      'familles_variante_de': ex.where((e) => e.variantOf == null).length,
      'profondeur_max': ex.map((e) => e.depth).reduce((a, b) => a > b ? a : b),
      'avec_prerequis': ex.where((e) => e.prerequisites.isNotEmpty).length,
      'avec_fraction': ex.where((e) => e.bodyweightFraction != null).length,
      'distributions': distributions,
    },
    'contrats': <String, Object?>{
      'types': contractCodecs.length,
      'codes_de_raison': reasonRegistry.length,
      'schemas': <String, Object?>{
        'AthleteProfile': AthleteProfile.currentSchemaVersion,
        'TrainingLog': TrainingLog.currentSchemaVersion,
        'Pass1Plan': Pass1Plan.currentSchemaVersion,
        'Pass2Plan': Pass2Plan.currentSchemaVersion,
        'ProgramBlock': ProgramBlock.currentSchemaVersion,
        'AdaptationSummary': AdaptationSummary.currentSchemaVersion,
        'QuestState': QuestState.currentSchemaVersion,
        'SeasonPlan': SeasonPlan.currentSchemaVersion,
        'EventDayPlan': EventDayPlan.currentSchemaVersion,
      },
      'flammes_vers_rir': flameTable,
    },
    'jeux_de_donnees': <String, Object?>{
      'profils': profiles.length,
      'violations_profils': profileViolations,
      'journaux': journals.length,
      'violations_journaux': journalViolations,
      'seances': sessions,
      'seances_reprise': resume,
      'series': sets,
      'series_sans_note': unrated,
      'flammes': Map<String, int>.fromEntries(
        flames.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      ),
    },
    'profil_v3': <String, Object?>{
      'parcours_version': parcours.version,
      'questions': parcours.questions.length,
      'questions_schema_3': parcours.questions.where((q) => q.since >= 3).length,
      'tests_guides': parcours.tests.length,
      'profils_types': v3Profiles.length,
      'questions_vues': questionCounts,
      'profils_schema_2_migres': profiles.length,
      'echecs_de_migration': migrationFailures,
    },
    'echecs': failures,
  };

  const encoder = JsonEncoder.withIndent('  ');
  File(
    '${out.path}/kalis_core_rapport.json',
  ).writeAsStringSync('${encoder.convert(report)}\n');

  final text = StringBuffer()
    ..writeln('kalis_core $kalisCoreVersion — rapport de contrôle')
    ..writeln()
    ..writeln(
      'Catalogue : ${catalog.length} exercices, base '
      'v${catalog.sourceVersion}, règles ${catalog.rulesVersion}, '
      'schéma ${catalog.schemaVersion}',
    )
    ..writeln(
      'Chargement (décompression comprise) : meilleur '
      '${bestMs.toStringAsFixed(1)} ms, médiane '
      '${medianMs.toStringAsFixed(1)} ms (budget $loadBudgetMs ms)',
    )
    ..writeln(
      'Contrats : ${contractCodecs.length} types, '
      '${reasonRegistry.length} codes de raison',
    )
    ..writeln(
      'Profils types : ${profiles.length} '
      '($profileViolations violation(s))',
    )
    ..writeln(
      'Journaux : ${journals.length}, $sessions séances dont $resume '
      '« reprise », $sets séries dont $unrated sans note '
      '($journalViolations violation(s))',
    )
    ..writeln(
      'Profil v3 : parcours ${parcours.version}, '
      '${parcours.questions.length} questions, '
      '${parcours.tests.length} tests guidés ; ${profiles.length} profils du '
      'schéma 2 migrés ($migrationFailures échec(s))',
    );
  for (final entry in questionCounts.entries) {
    final counts = entry.value! as Map<String, Object?>;
    text.writeln(
      '  ${entry.key.padRight(38)} ${counts['questions']} questions vues, '
      'dont ${counts['nouvelles']} nouvelles',
    );
  }
  text.writeln();
  for (final entry in distributions.entries) {
    text.writeln('${entry.key} :');
    for (final item in (entry.value! as Map<String, int>).entries) {
      text.writeln('  ${item.key.padRight(34)} ${item.value}');
    }
  }
  text
    ..writeln()
    ..writeln(
      failures.isEmpty
          ? 'Tous les contrôles passent.'
          : 'ÉCHECS :\n${failures.join('\n')}',
    );
  File('${out.path}/kalis_core_rapport.txt').writeAsStringSync(text.toString());
  stdout.write(text.toString());
  if (failures.isNotEmpty) {
    exitCode = 1;
  }
}
