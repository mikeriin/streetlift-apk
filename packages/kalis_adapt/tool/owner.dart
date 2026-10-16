// Fixture « programme importé du propriétaire » (D5.10) : son programme de
// 40 semaines (`owner_program_v33.json.gz` de kalis_core, lecture seule),
// porté tel quel dans un `ProgramBlock` importé, et un journal de 11
// semaines joué par l'athlète simulé `avance_street` sous `kalis_adapt`.
//
// Le bloc garde la structure du programme : mêmes semaines, mêmes jours,
// mêmes exercices, mêmes séries, mêmes répétitions, mêmes RIR (traduits en
// flammes), mêmes pourcentages. Ne sont pas portés : les exercices sans
// correspondance dans le catalogue et les formats que le contrat ne décrit
// pas par une plage (montées en singles, tours, EMOM) — l'application les
// affichera depuis son propre import ; `skipped` les compte.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/report.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

/// Profil type calqué sur le propriétaire.
const String ownerProfileKey = 'proprietaire_streetlifting_avance';

/// Identifiant du bloc importé.
const String ownerBlockId = 'proprietaire-v33';

/// Semaines de journal de la fixture (la 12ᵉ est en cours, D5.10).
const int ownerWeeksDone = 11;

final RegExp _setsSeconds = RegExp(r'^(\d+)\s*×\s*(\d+)(?:-(\d+))?\s*s\b');
final RegExp _setsReps = RegExp(r'^(\d+)\s*×\s*(\d+)(?:-(\d+))?');
final RegExp _setsMax = RegExp(r'^(\d+)\s*×\s*max');
final RegExp _setsVolume = RegExp(r'^(\d+)\s*×\s*volume');
final RegExp _minutes = RegExp(r'^(\d+)\s*min');
final RegExp _rir = RegExp(r'RIR\s*(\d+(?:[.,]\d+)?)(?:-(\d+))?');
final RegExp _percent = RegExp(r'~\s*(\d+)\s*%');

LoadBasis _basisOf(CatalogExercise e) {
  switch (e.loadType) {
    case LoadType.addedWeight:
      return LoadBasis.bodyweightPlusExternal;
    case LoadType.barbell:
    case LoadType.dumbbells:
    case LoadType.kettlebell:
    case LoadType.machine:
    case LoadType.cable:
    case LoadType.other:
      return LoadBasis.external;
    case LoadType.bodyweight:
      return LoadBasis.bodyweight;
    case LoadType.none:
    case LoadType.band:
      return LoadBasis.unloaded;
  }
}

/// Bloc importé et nombre d'exercices non portés.
(ProgramBlock, int) ownerBlock(
  Catalog catalog,
  AthleteProfile profile,
  Map<String, Object?> program,
) {
  final book = ExerciseBook(catalog, profile);
  final bodyWeight = profile.bodyWeightKg ?? 71.5;
  final declared = <String, double>{};
  for (final level in profile.movementLevels) {
    final low = level.low;
    final high = level.high;
    if (level.known &&
        level.measure == LevelMeasure.oneRmKg &&
        low != null &&
        high != null) {
      declared[level.exerciseId] = (low + high) / 2;
    }
  }
  var skipped = 0;
  final weeksJson = program['weeks']! as List<Object?>;
  // Jours d'entraînement (1 = lundi) qui portent au moins un exercice.
  final dayNumbers = <int>{};
  final weeks = <(int, String, Map<int, List<ExercisePrescription>>)>[];
  final roles = <String, SlotRole>{};
  final slotExercise = <String, String>{};
  final slotDay = <String, int>{};
  for (var w = 0; w < weeksJson.length; w++) {
    final week = weeksJson[w]! as Map<String, Object?>;
    final days = <int, List<ExercisePrescription>>{};
    for (final d in week['days']! as List<Object?>) {
      final day = d! as Map<String, Object?>;
      final number = day['day']! as int;
      final items = <ExercisePrescription>[];
      final used = <String>{};
      for (final x in (day['exercises'] as List<Object?>?) ?? const []) {
        final source = x! as Map<String, Object?>;
        final id = source['catalogId'];
        final exercise = id is String ? catalog.find(id) : null;
        final info = id is String ? book.find(id) : null;
        if (id is! String || exercise == null || info == null) {
          skipped++;
          continue;
        }
        final setsText = '${source['sets']}';
        final intensity = '${source['intensity']}';
        int sets;
        int? repsLow;
        int? repsHigh;
        int? secondsLow;
        int? secondsHigh;
        var test = false;
        final seconds = _setsSeconds.firstMatch(setsText);
        final reps = _setsReps.firstMatch(setsText);
        final max = _setsMax.firstMatch(setsText);
        final volume = _setsVolume.firstMatch(setsText);
        final minutes = _minutes.firstMatch(setsText);
        final timed = exercise.unit == MeasureUnit.seconds;
        if (max != null) {
          sets = int.parse(max.group(1)!);
          test = true;
          if (timed) {
            secondsLow = 1;
            secondsHigh = 600;
          } else {
            repsLow = 1;
            repsHigh = 200;
          }
        } else if (volume != null) {
          sets = int.parse(volume.group(1)!);
          repsLow = 3;
          repsHigh = 60;
        } else if (seconds != null) {
          sets = int.parse(seconds.group(1)!);
          secondsLow = int.parse(seconds.group(2)!);
          secondsHigh = int.parse(seconds.group(3) ?? seconds.group(2)!);
        } else if (reps != null) {
          sets = int.parse(reps.group(1)!);
          repsLow = int.parse(reps.group(2)!);
          repsHigh = int.parse(reps.group(3) ?? reps.group(2)!);
        } else if (minutes != null) {
          sets = 1;
          secondsLow = int.parse(minutes.group(1)!) * 60;
          secondsHigh = secondsLow;
        } else {
          skipped++;
          continue;
        }
        if (sets < 1 || sets > 20) {
          skipped++;
          continue;
        }
        int? flames;
        final rir = _rir.firstMatch(intensity);
        if (test) {
          flames = Flames.failure;
        } else if (rir != null) {
          final a = double.parse(rir.group(1)!.replaceAll(',', '.'));
          final b = rir.group(2) == null ? a : double.parse(rir.group(2)!);
          flames = Flames.fromRir((a + b) / 2);
        }
        double? share;
        final percent = _percent.firstMatch(intensity);
        if (flames == null &&
            percent != null &&
            info.mode == CapacityMode.loaded) {
          // Le programme compte en part du « système » (poids du corps
          // entier + lest) ; le contrat compte en part du 1RM de charge
          // totale (fraction du poids du corps + lest) : conversion par le
          // 1RM déclaré.
          var value = int.parse(percent.group(1)!) / 100;
          final oneRm = declared[id];
          if (info.fraction > 0 && oneRm != null) {
            final external = value * (oneRm + bodyWeight) - bodyWeight;
            value =
                (external + info.fraction * bodyWeight) /
                (oneRm + info.fraction * bodyWeight);
          }
          share = (value * 1000).roundToDouble() / 1000;
          if (share < 0 || share > 1.5) {
            share = null;
          }
        }
        var slotId = 'o$number-$id';
        var suffix = 2;
        while (used.contains(slotId)) {
          slotId = 'o$number-$id-$suffix';
          suffix++;
        }
        used.add(slotId);
        final main = source['main'] == true;
        final role = main
            ? SlotRole.main
            : (source['loadType'] == 'system' || source['loadType'] == 'barbell'
                  ? SlotRole.secondary
                  : (info.mode == null
                        ? SlotRole.mobility
                        : SlotRole.accessory));
        if (main || !roles.containsKey(slotId)) {
          roles[slotId] = role;
        }
        slotExercise[slotId] = id;
        slotDay[slotId] = number;
        final rest = source['restSeconds'];
        items.add(
          ExercisePrescription(
            slotId: slotId,
            exerciseId: id,
            sets: sets,
            repsLow: repsLow,
            repsHigh: repsHigh,
            secondsLow: secondsLow,
            secondsHigh: secondsHigh,
            targetFlames: flames,
            restSeconds: rest is int ? (rest > 900 ? 900 : rest) : null,
            percentOfOneRm: share,
            toCalibrate: false,
            loadBasis: _basisOf(exercise),
            kind: test ? SetKind.test : null,
            reasons: const <Reason>[],
          ),
        );
      }
      if (items.isNotEmpty) {
        days[number] = items;
        dayNumbers.add(number);
      }
    }
    weeks.add((w, '${week['blockKey']}', days));
  }
  final ordered = dayNumbers.toList()..sort();
  final dayIndex = <int, int>{
    for (var i = 0; i < ordered.length; i++) ordered[i]: i,
  };
  final slotIds = slotExercise.keys.toList()..sort();
  final pass1 = Pass1Plan(
    blockId: ownerBlockId,
    blockIndex: 0,
    weeks: weeks.length,
    startDate: simStartDate,
    seed: 0,
    engineVersion: 'import',
    days: <PlanDay>[
      for (final number in ordered)
        PlanDay(
          dayIndex: dayIndex[number]!,
          weekday: number,
          minutesBudget: 90,
          focus: 'imported',
          slots: <PlanSlot>[
            for (final slotId in slotIds)
              if (slotDay[slotId] == number)
                PlanSlot(
                  slotId: slotId,
                  exerciseId: slotExercise[slotId]!,
                  role: roles[slotId]!,
                  locked: true,
                  reasons: const <Reason>[],
                ),
          ],
        ),
    ],
    score: const PlanScore(total: 0, components: <ScoreComponent>[]),
    reasons: const <Reason>[],
  );
  final pass2 = Pass2Plan(
    blockId: ownerBlockId,
    engineVersion: 'import',
    weeks: <WeekPrescription>[
      for (final (index, blockKey, days) in weeks)
        WeekPrescription(
          weekIndex: index,
          kind: blockKey == 'P0' ? WeekKind.intro : WeekKind.build,
          days: <DayPrescription>[
            for (final number in ordered)
              if (days.containsKey(number))
                DayPrescription(
                  dayIndex: dayIndex[number]!,
                  items: days[number]!,
                ),
          ],
        ),
    ],
    reasons: const <Reason>[],
  );
  return (ProgramBlock(pass1: pass1, pass2: pass2), skipped);
}

/// Fixture complète : bloc importé, journal simulé des [ownerWeeksDone]
/// premières semaines, « aujourd'hui » et séance à prescrire.
Map<String, Object?> ownerFixture(
  Catalog catalog,
  AthleteProfile profile,
  Map<String, Object?> program,
) {
  final (block, skipped) = ownerBlock(catalog, profile, program);
  final engine = KalisAdapt();
  final run = simulate(
    catalog: catalog,
    spec: athleteOf('avance_street'),
    profile: profile,
    seed: 0,
    policy: KalisAdaptPolicy(engine),
    program: SimProgram.fixed(catalog, KalisPlan(), profile, block),
    weeks: ownerWeeksDone,
  );
  return <String, Object?>{
    'schemaVersion': 1,
    'description':
        'Programme personnel du propriétaire (40 semaines) importé tel quel '
        'et journal simulé de ses $ownerWeeksDone premières semaines '
        '(athlète `avance_street`, graine 0, séances prescrites par '
        'kalis_adapt). Généré par `bin/kalis_adapt_cli.dart` — ne pas '
        'modifier à la main.',
    'profileKey': ownerProfileKey,
    'today': simStartDate.addDays(7 * ownerWeeksDone).iso,
    'next': <String, Object?>{'weekIndex': ownerWeeksDone, 'dayIndex': 0},
    'skipped': skipped,
    'block': block.toJson(),
    'log': TrainingLog(sessions: run.sessions).toJson(),
  };
}

/// Compte rendu du rejeu de la fixture [fixture] (voir [ownerFixture]).
String ownerReplayMarkdown(
  Catalog catalog,
  AthleteProfile profile,
  Map<String, Object?> fixture,
) {
  final next = fixture['next']! as Map<String, Object?>;
  return replayMarkdown(
    catalog,
    KalisAdapt(),
    title: 'kalis_adapt — rejeu du programme importé du propriétaire',
    profile: profile,
    block: ProgramBlock.fromJson(fixture['block']! as Map<String, Object?>),
    log: TrainingLog.fromJson(fixture['log']! as Map<String, Object?>),
    today: CivilDate.parse(fixture['today']! as String),
    weekIndex: next['weekIndex']! as int,
    dayIndex: next['dayIndex']! as int,
    notes: <String>[
      'Document généré par `dart run bin/kalis_adapt_cli.dart --rapport '
          '<dossier>` à partir de `test/fixtures/proprietaire.json.gz` : le '
          'programme de 40 semaines du propriétaire, importé sans changer '
          'sa structure (D5.10), et un journal **simulé** de ses '
          '$ownerWeeksDone premières semaines (athlète `avance_street`, '
          'graine 0). ${fixture['skipped']} exercices du programme ne sont '
          'pas portés dans la fixture (sans correspondance au catalogue, '
          'ou format hors plage : montées en singles, tours, EMOM). Même '
          'rejeu à la main : `dart run kalis_adapt:replay --journal '
          'test/fixtures/proprietaire.json.gz`.',
    ],
  );
}
