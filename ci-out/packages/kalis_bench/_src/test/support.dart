// Accès aux données depuis les tests (`dart test` s'exécute à la racine du
// paquet ; kalis_core est le dossier voisin) et fabrique de programmes
// écrits à la main pour éprouver les critères.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/report.dart' show OwnerProgram;

/// Racine du paquet kalis_core.
const String corePath = '../kalis_core';

Catalog? _catalog;

/// Catalogue chargé (une fois par fichier de test).
Catalog loadCatalog() => _catalog ??= Catalog.fromJsonBytes(
  gzip.decode(File('$corePath/data/catalog_v1.json.gz').readAsBytesSync()),
);

/// Objet JSON d'un fichier (décompressé si son nom finit par `.gz`).
Map<String, Object?> readJsonObject(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

/// Les profils du banc, triés par nom de fichier.
List<BenchProfile> loadBenchProfiles() {
  final paths = <String>[
    for (final f in Directory('profiles').listSync())
      if (f is File && f.path.endsWith('.json')) f.path,
  ]..sort();
  return <BenchProfile>[
    for (final path in paths) BenchProfile.fromJson(readJsonObject(path)),
  ];
}

/// Profil du banc de clé [key].
BenchProfile benchProfileOf(String key) =>
    loadBenchProfiles().firstWhere((p) => p.key == key);

/// Entrées du banc (tous les profils, programme du propriétaire).
BenchInputs loadInputs() {
  final ownerJson = readJsonObject(
    '$corePath/test/fixtures/owner_program_v33.json.gz',
  );
  return BenchInputs(
    catalog: loadCatalog(),
    profiles: loadBenchProfiles(),
    owner: OwnerProgram.fromJson(ownerJson),
    ownerPairs: ownerWeekPairs(ownerJson),
  );
}

/// Profil du banc minimal pour les tests de critères : homme de 80 kg,
/// streetlifting, salle complète, trois séances de 90 minutes.
BenchProfile testProfile({
  String level = 'intermediate',
  int birthYear = 1996,
  double weight = 80,
  int height = 180,
  int minutes = 90,
  List<Map<String, Object?>> records = const <Map<String, Object?>>[],
  List<Map<String, Object?>> injuries = const <Map<String, Object?>>[],
  List<Map<String, Object?>> events = const <Map<String, Object?>>[],
  List<Map<String, Object?>> weakPoints = const <Map<String, Object?>>[],
  List<Map<String, Object?>> checks = const <Map<String, Object?>>[],
  int breakWeeks = 0,
  String outcome = 'standard',
}) {
  return BenchProfile.fromJson(<String, Object?>{
    'schemaVersion': 1,
    'key': 'test',
    'group': 'street',
    'title': 'Profil de test',
    'summary': 'Profil fabriqué pour les tests de critères.',
    'level': level,
    'trainingAgeMonths': 24,
    'core': <String, Object?>{
      'sex': 'male',
      'birthYear': birthYear,
      'heightCm': height,
      'bodyWeightKg': weight,
      'disciplines': <String, Object?>{
        'primary': 'streetlifting',
        'primaryPct': 100,
        'secondaries': <Object?>[],
      },
      'availability': <Object?>[
        for (final d in <int>[1, 3, 5, 6])
          <String, Object?>{'weekday': d, 'minutes': minutes},
      ],
      'places': <Object?>['salle'],
      'equipment': <Object?>[
        'barre fixe',
        'barres parallèles',
        'barre basse',
        'ceinture de lest',
        'disques',
        'barre olympique',
        'cage / rack',
        'anneaux',
        'parallettes',
      ],
      'loadIncrements': <Object?>[],
      'likedExerciseIds': <Object?>[],
      'dislikedExerciseIds': <Object?>[],
      'experience': level,
      'guidanceMode': 'assisted',
      'healthScreening': <String, Object?>{
        'questionnaireId': 'kalis-sante-l13-v1',
        'answeredOn': '2026-10-01',
        'outcome': outcome,
      },
    },
    'records': records,
    'events': events,
    'weakPoints': weakPoints,
    'injuries': injuries,
    if (breakWeeks > 0) 'break': <String, Object?>{'weeksOff': breakWeeks},
    'expectations': <String, Object?>{
      'text': <Object?>['Attente de test.'],
      'checks': checks,
    },
  });
}

/// Ligne d'une séance écrite à la main.
final class L {
  /// [sets] séries de [exerciseId].
  const L(
    this.exerciseId,
    this.sets, {
    this.reps = 8,
    this.seconds,
    this.flames = 5,
    this.load,
    this.rest = 120,
    this.kind,
    this.format,
    this.percent,
  });

  /// Exercice.
  final String exerciseId;

  /// Séries.
  final int sets;

  /// Répétitions (ignorées si [seconds] est donné).
  final int reps;

  /// Secondes de tenue.
  final int? seconds;

  /// Flammes visées (`null` : sans cible).
  final int? flames;

  /// Charge externe.
  final double? load;

  /// Repos.
  final int rest;

  /// Rôle des séries.
  final SetKind? kind;

  /// Format.
  final String? format;

  /// Part du 1RM.
  final double? percent;
}

ExercisePrescription _item(Catalog catalog, int day, int n, L l) {
  final e = catalog.exercise(l.exerciseId);
  final weighted = e.loadType == LoadType.addedWeight;
  return ExercisePrescription(
    slotId: 'd$day.$n',
    exerciseId: l.exerciseId,
    sets: l.sets,
    repsLow: l.seconds == null ? l.reps : null,
    repsHigh: l.seconds == null ? l.reps : null,
    secondsLow: l.seconds,
    secondsHigh: l.seconds,
    targetFlames: l.flames,
    restSeconds: l.rest,
    startLoadKg: l.load,
    percentOfOneRm: l.percent,
    toCalibrate: false,
    loadBasis: weighted
        ? LoadBasis.bodyweightPlusExternal
        : (e.bodyweightFraction == null
              ? LoadBasis.external
              : LoadBasis.bodyweight),
    format: l.format,
    kind: l.kind,
    reasons: const <Reason>[],
  );
}

/// Programme écrit à la main : [weeks] donne, pour chaque semaine, sa
/// nature et ses séances (une liste de lignes par jour).
ProgramView handProgram(
  BenchProfile profile,
  List<(WeekKind, List<List<L>>)> weeks, {
  int minutes = 90,
}) {
  final catalog = loadCatalog();
  final adapted = adaptProfile(profile);
  final firstDays = weeks.first.$2;
  final pass1 = Pass1Plan(
    blockId: 'test-b0',
    blockIndex: 0,
    weeks: weeks.length,
    startDate: benchStartDate,
    seed: 0,
    engineVersion: 'test',
    days: <PlanDay>[
      for (var d = 0; d < firstDays.length; d++)
        PlanDay(
          dayIndex: d,
          weekday: d + 1,
          minutesBudget: minutes,
          focus: 'strength.full_body',
          slots: <PlanSlot>[
            for (var n = 0; n < firstDays[d].length; n++)
              PlanSlot(
                slotId: 'd$d.$n',
                exerciseId: firstDays[d][n].exerciseId,
                role: n == 0 ? SlotRole.main : SlotRole.accessory,
                locked: false,
                reasons: const <Reason>[],
              ),
          ],
        ),
    ],
    score: const PlanScore(total: 1, components: <ScoreComponent>[]),
    reasons: const <Reason>[],
  );
  final pass2 = Pass2Plan(
    blockId: 'test-b0',
    engineVersion: 'test',
    weeks: <WeekPrescription>[
      for (var w = 0; w < weeks.length; w++)
        WeekPrescription(
          weekIndex: w,
          kind: weeks[w].$1,
          days: <DayPrescription>[
            for (var d = 0; d < weeks[w].$2.length; d++)
              DayPrescription(
                dayIndex: d,
                items: <ExercisePrescription>[
                  for (var n = 0; n < weeks[w].$2[d].length; n++)
                    _item(catalog, d, n, weeks[w].$2[d][n]),
                ],
              ),
          ],
        ),
    ],
    reasons: const <Reason>[],
  );
  return ProgramView(
    catalog,
    BenchProgram(
      bench: profile,
      adapted: adapted,
      request: PlanRequest(
        profile: adapted.profile,
        seed: 0,
        startDate: benchStartDate,
        locks: const <PlanLock>[],
      ),
      blocks: <ProgramBlock>[ProgramBlock(pass1: pass1, pass2: pass2)],
      horizonWeeks: weeks.length,
    ),
  );
}

/// [n] semaines de montée identiques à [days].
List<(WeekKind, List<List<L>>)> sameWeeks(int n, List<List<L>> days) =>
    <(WeekKind, List<List<L>>)>[
      for (var i = 0; i < n; i++) (WeekKind.build, days),
    ];

/// Codes des constats [findings].
Set<String> codesOf(List<Finding> findings) => <String>{
  for (final f in findings) f.code,
};
