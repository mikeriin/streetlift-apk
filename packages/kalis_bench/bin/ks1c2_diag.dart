// Diagnostic de mise au point du lot KS1c2 (jamais sur moteurs).
import 'dart:convert';
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'common.dart';

String _slots(Catalog catalog, PlanDay d) => <String>[
  for (final s in d.slots)
    '${s.role.code}/${s.exerciseId}'
        '(${catalog.find(s.exerciseId) == null ? '?' : structureSchemaOf(catalog.find(s.exerciseId)!) ?? '-'})',
].join(', ');

String _type(PlanDay d) {
  final t = d.type;
  if (t == null) return '—';
  return '${t.patterns.map((p) => p.code).join('+')}·${t.quality.code}';
}

void main(List<String> args) {
  final inputs = loadInputs('tous');
  final catalog = inputs.catalog;
  final engine = KalisPlan();
  final out = StringBuffer();
  final full = args.contains('--complet');

  // 1. Profil du constat de KS1A.
  final ks1a = BenchProfile.fromJson(
    readJsonObject('profiles_ks1c2/ks1a_street_5050.json'),
  );
  final p = generateProgram(catalog, engine, ks1a, horizonWeeks: 4);
  final view = ProgramView(catalog, p);
  out.writeln('# KS1A (bloc 0)');
  out.writeln('gabarit ${p.blocks.first.pass1.split?.templateId}');
  for (final d in p.blocks.first.pass1.days) {
    out.writeln('- j${d.dayIndex} ${_type(d)} : ${_slots(catalog, d)}');
    for (final g in principalGapsOfDay(catalog, d)) {
      out.writeln('  ÉCART $g');
    }
  }
  for (final w in view.weeks.take(2)) {
    for (final d in w.days) {
      final s = coachSessionSeconds(
        catalog,
        DayPrescription(
          dayIndex: d.dayIndex,
          items: <ExercisePrescription>[for (final i in d.items) i.p],
        ),
        minutes: d.minutesBudget,
      );
      out.writeln(
        '  s${w.index} j${d.dayIndex} ${(s / 60).toStringAsFixed(0)} min : '
        '${d.items.map((i) => '${i.exercise.id} ${i.p.sets}x${i.p.repsLow}-${i.p.repsHigh}@${i.p.startLoadKg}').join(' ; ')}',
      );
    }
  }

  // 2. Les 34 profils, tous les blocs.
  out.writeln('\n# 34 profils');
  final profiles = <BenchProfile>[
    ...inputs.profiles,
    ...readProfiles('profiles_ks'),
  ];
  var total = 0;
  final signatures = <String, Object?>{};
  for (final b in profiles) {
    final prog = generateProgram(
      catalog,
      engine,
      b,
      horizonWeeks: b.key == structureTestProfile ? 40 : null,
    );
    signatures[b.key] = <Object?>[
      for (final blk in prog.blocks) structureSignatureOf(blk.pass1),
    ];
    for (var k = 0; k < prog.blocks.length; k++) {
      final pass1 = prog.blocks[k].pass1;
      final legacy = structureLegacyTemplates.contains(pass1.split?.templateId);
      for (final d in pass1.days) {
        final gaps = principalGapsOfDay(catalog, d);
        if (gaps.isEmpty) continue;
        total += gaps.where(principalSchemaGap).length;
        out.writeln(
          '- ${legacy ? 'FIGÉ' : 'TYPÉ'} ${b.key} b$k j${d.dayIndex} '
          '${pass1.split?.templateId} ${_type(d)} : ${gaps.join(', ')} | '
          '${_slots(catalog, d)}',
        );
      }
    }
  }
  out.writeln('écarts de schéma, 34 profils : $total');
  File(
    args.isEmpty ? 'signatures.json' : '${args.first}.signatures.json',
  ).writeAsStringSync(jsonEncode(signatures));

  // 3. Grille des profils incomplets (bloc 0, ou tout l'horizon avec
  // --complet).
  out.writeln('\n# Grille');
  final bases = <Map<String, Object?>>[
    readJsonObject('profiles_ks1c2/ks1a_street_5050.json'),
    for (final f in (Directory('profiles_ks').listSync()
          ..sort((x, y) => x.path.compareTo(y.path))))
      if (f is File && f.path.endsWith('.json')) readJsonObject(f.path),
  ];
  final grid = principalGrid(bases);
  var gridGaps = 0;
  var gridDays = 0;
  var gridLegacyMain = 0;
  var failed = 0;
  final byAxis = <String, int>{};
  var shown = 0;
  for (final g in grid) {
    BenchProgram prog;
    try {
      prog = generateProgram(
        catalog,
        engine,
        g,
        horizonWeeks: full ? null : 1,
      );
    } catch (e) {
      failed++;
      out.writeln('- ÉCHEC ${g.key} : $e');
      continue;
    }
    for (var k = 0; k < prog.blocks.length; k++) {
      final pass1 = prog.blocks[k].pass1;
      final legacy = structureLegacyTemplates.contains(pass1.split?.templateId);
      for (final d in pass1.days) {
        gridDays++;
        final gaps = principalGapsOfDay(catalog, d);
        final schema = gaps.where(principalSchemaGap).toList();
        final main = gaps.contains('principal');
        if (schema.isEmpty && !(main && !legacy)) {
          if (main) gridLegacyMain++;
          continue;
        }
        gridGaps++;
        final axes = g.key.split('~');
        for (var i = 1; i < axes.length; i++) {
          byAxis['${axes[0]}~$i:${axes[i]}'] =
              (byAxis['${axes[0]}~$i:${axes[i]}'] ?? 0) + 1;
        }
        if (shown < 150) {
          shown++;
          out.writeln(
            '- ${legacy ? 'FIGÉ' : 'TYPÉ'} ${g.key} b$k j${d.dayIndex} '
            '${pass1.split?.templateId} ${_type(d)} : ${gaps.join(', ')} | '
            '${_slots(catalog, d)}',
          );
        }
      }
    }
  }
  out.writeln(
    'grille : ${grid.length} profils, $gridDays jours, $gridGaps jours en '
    'défaut (schéma, ou principal sur un gabarit typé), $gridLegacyMain '
    'jours figés sans emplacement principal (porteurs secondaires), '
    '$failed échecs',
  );
  final keys = byAxis.keys.toList()..sort();
  for (final k in keys) {
    out.writeln('  $k : ${byAxis[k]}');
  }
  // 4. Douleurs : jours qui changent de type.
  out.writeln('\n# Douleurs (ks_test_ppl6 et ks1a)');
  const zones = <(String, String)>[
    ('shoulder', 'epaule'),
    ('elbow', 'coude'),
    ('wrist_hand', 'poignet'),
    ('knee', 'genou'),
    ('lower_back', 'lombaires'),
  ];
  final combos = <List<(String, String)>>[
    for (final z in zones) <(String, String)>[z],
    <(String, String)>[zones[0], zones[2]],
    <(String, String)>[zones[1], zones[2]],
    <(String, String)>[zones[0], zones[1]],
    <(String, String)>[zones[0], zones[1], zones[2]],
  ];
  for (final basePath in const <String>[
    'profiles_ks/ks_test_ppl6.json',
    'profiles_ks1c2/ks1a_street_5050.json',
  ]) {
    for (final combo in combos) {
      for (final pain in const <int>[4, 6, 8]) {
        final json = Map<String, Object?>.of(readJsonObject(basePath));
        json['key'] =
            '${json['key']}~${combo.map((z) => z.$2).join('+')}~$pain';
        json['injuries'] = <Object?>[
          for (final z in combo)
            <String, Object?>{
              'zone': z.$1,
              'side': 'both',
              'joint': z.$2,
              'discomfort': pain,
              'status': 'current',
              'label': 'gêne',
              'monthsAgo': 1,
            },
        ];
        final bp = BenchProfile.fromJson(json);
        final prog = generateProgram(catalog, engine, bp, horizonWeeks: 1);
        final pass1 = prog.blocks.first.pass1;
        final extra = <String>[
          for (final r in pass1.split?.reasons ?? const <Reason>[])
            if (r.code != ReasonCodes.planDayType &&
                r.code != ReasonCodes.planSplitChosen)
              '${r.code}${r.params}',
        ];
        final gaps = <String>[
          for (final d in pass1.days)
            for (final g in principalGapsOfDay(catalog, d)) 'j${d.dayIndex} $g',
        ];
        out.writeln(
          '- ${bp.key} ${pass1.split?.templateId} : '
          '${pass1.days.map(_type).join(' | ')} ; raisons $extra ; écarts $gaps',
        );
      }
    }
  }

  final path = args.isEmpty || args.first.startsWith('--')
      ? 'ks1c2_diag.md'
      : args.first;
  File(path).writeAsStringSync(out.toString());
  stdout.writeln('écrit $path ; 34 profils : $total ; grille : $gridGaps');
}
