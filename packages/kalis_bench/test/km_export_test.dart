// Exports du lot KM1 (`lib/src/km/km_export.dart`, lus par la référence
// Python de kalis_adapt 1.0) : saison de référence déterministe et complète,
// sécurité de blocs identique à `safetyFindings` sur la même vue, athlètes
// adversariaux déterministes dont la fiche recouverte agit.
import 'dart:convert';

import 'package:kalis_adapt/simulation.dart' show TruthKind;
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_bench/src/km/km_export.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Profil du banc à la plus petite saison de référence.
const String _key = 'street_02_debutant_surpoids';

/// Champs d'une saison de référence exportée.
const List<String> _seasonFields = <String>[
  'weeks',
  'startDate',
  'benchJson',
  'specJson',
  'profiles',
  'blockWeeks',
  'blocks',
  'sessions',
  'eventDaysByWeek',
  'exerciseIds',
  'infos',
  'truthInits',
];

/// Champs d'une fiche d'exercice exportée, dont ceux ajoutés au lot KM1
/// (critères de sécurité).
const List<String> _infoFields = <String>[
  'id',
  'mode',
  'fraction',
  'groups',
  'groupWeights',
  'zoneLevels',
  'painStopHits',
  'gridStep',
  'gridMinimum',
  'gridDumbbell',
  'slotKind',
  'resistance',
  'groupCredits',
  'impact',
  'technical',
  'level',
  'levelCode',
  'rootId',
  'depth',
  'variantOf',
  'prerequisites',
  'laterality',
  'articularity',
  'contractionMode',
  'equipment',
  'places',
  'jointStress',
  'bodyweightFraction',
  'straightArm',
  'highRisk',
  'moderateRisk',
  'heavyImpact',
];

/// [value] passé par le JSON, comme la référence Python le relit.
Map<String, Object?> _decoded(Object? value) =>
    jsonDecode(jsonEncode(value)) as Map<String, Object?>;

void main() {
  final catalog = loadCatalog();
  final json = readJsonObject('profiles/$_key.json');

  Map<String, Object?> reference() => kmReferenceSeason(
    catalog,
    KalisPlan(),
    json,
    SeasonScenario.base,
    truthSeeds: 1,
  );

  test('saison de référence : deux appels, même JSON ; champs attendus', () {
    final first = reference();
    expect(jsonEncode(first), jsonEncode(reference()));
    final s = _decoded(first);
    expect(s['schema'], kmExportSchema);
    expect(s['key'], _key);
    expect(s['scenario'], SeasonScenario.base.code);
    expect(s.keys, containsAll(_seasonFields));
    final weeks = s['weeks']! as int;
    final sessions = s['sessions']! as List<Object?>;
    expect(sessions, isNotEmpty);
    for (final row in sessions) {
      final r = row! as List<Object?>;
      expect(r, hasLength(5));
      expect(r[0]! as int, lessThan(weeks));
    }
    expect(
      s['blocks']! as List<Object?>,
      hasLength((s['blockWeeks']! as List<Object?>).length),
    );
    expect(s['eventDaysByWeek']! as List<Object?>, hasLength(weeks));
    final ids = <String>[
      for (final id in s['exerciseIds']! as List<Object?>) id! as String,
    ];
    expect(ids, isNotEmpty);
    expect(ids, <String>[...ids]..sort());
    final infos = s['infos']! as List<Object?>;
    expect(infos, isNotEmpty);
    for (final info in infos) {
      final i = info! as Map<String, Object?>;
      expect(ids, contains(i['id']));
      expect(i.keys, containsAll(_infoFields));
    }
    final inits = s['truthInits']! as List<Object?>;
    expect(inits, hasLength(TruthKind.values.length));
    for (final init in inits) {
      final m = init! as Map<String, Object?>;
      expect(m['seed'], 0);
      expect(m['truths']! as Map<String, Object?>, isNotEmpty);
    }
  });

  test('sécurité de blocs : constats de safetyFindings sur la même vue', () {
    final s = _decoded(reference());
    final blocksJson = s['blocks']! as List<Object?>;
    final blockWeeks = <int>[
      for (final w in s['blockWeeks']! as List<Object?>) w! as int,
    ];
    final out = kmSafetyOfBlocks(
      catalog,
      json,
      SeasonScenario.base,
      blocksJson,
      blockWeeks,
    );
    final season = KmSeason(catalog, json, SeasonScenario.base);
    final blocks = <ProgramBlock>[
      for (final b in blocksJson)
        ProgramBlock.fromJson(b! as Map<String, Object?>),
    ];
    final view = ProgramView(
      catalog,
      BenchProgram(
        bench: season.bench,
        adapted: season.adapted,
        request: PlanRequest(
          profile: season.adapted.profile,
          seed: 0,
          startDate: benchStartDate,
          locks: const <PlanLock>[],
        ),
        blocks: kmServedBlocks(blocks, blockWeeks),
        horizonWeeks: season.weeks,
      ),
    );
    final found = safetyFindings(view, season.bench);
    final expected = <Object?>[for (final f in found) f.toJson()];
    expect(out['schema'], kmExportSchema);
    expect(out['key'], _key);
    expect(out['scenario'], SeasonScenario.base.code);
    expect(out['weeks'], s['weeks']);
    expect(out['readWeeks'], view.weeks.length);
    expect(jsonEncode(out['findings']), jsonEncode(expected));
    // Horizon réduit : quatre semaines au plus sont lues.
    final short = kmSafetyOfBlocks(
      catalog,
      json,
      SeasonScenario.base,
      blocksJson,
      blockWeeks,
      weeks: 4,
    );
    expect(short['weeks'], 4);
    expect(short['readWeeks']! as int, lessThanOrEqualTo(4));
  });

  test('surcharges adversariales : lecture et refus', () {
    expect(kmOverridesOf(null), isEmpty);
    final good = <String, Object?>{
      '*': <String, Object?>{'capacity': 1.2, 'slope': 1},
    };
    final read = kmOverridesOf(good);
    expect(read['*'], <String, double>{'capacity': 1.2, 'slope': 1.0});
    final bad = <String, Object?>{'*': <String, Object?>{'capacity': 'x'}};
    expect(() => kmOverridesOf(bad), throwsFormatException);
  });

  test('athlète adversarial : déterministe ; la fiche recouverte agit', () {
    Map<String, Object?> run(Map<String, Object?>? spec) {
      final adversary = <String, Object?>{
        'id': 'km-test',
        'key': _key,
        'scenario': SeasonScenario.base.code,
        'kind': TruthKind.a.name,
        'seed': 0,
        'spec': spec,
      };
      return kmAdversaryRun(catalog, KalisPlan(), json, adversary);
    }

    final first = run(null);
    expect(jsonEncode(first), jsonEncode(run(null)));
    expect(first['id'], 'km-test');
    expect(first['key'], _key);
    expect(first['kind'], TruthKind.a.name);
    expect(first.keys, containsAll(<String>['run', 'findings', 'estimates']));
    final base = first['run']! as Map<String, Object?>;
    expect(base['done']! as int, greaterThan(0));
    // Une absence sur deux en moyenne : moins de séances faites, autant de
    // séances prévues.
    final missedRun = run(<String, Object?>{'missRate': 0.6});
    final missed = missedRun['run']! as Map<String, Object?>;
    expect(missed['planned'], base['planned']);
    expect(missed['done']! as int, lessThan(base['done']! as int));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
