// Diagnostic de mise au point du lot KS1c2 (jamais sur moteurs).
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';

import 'common.dart';

String _slots(Catalog catalog, PlanDay d) => <String>[
  for (final s in d.slots)
    '${s.role.code}/${s.method}/${s.exerciseId}'
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
  for (final b in profiles) {
    final prog = generateProgram(
      catalog,
      engine,
      b,
      horizonWeeks: b.key == structureTestProfile ? 40 : null,
    );
    for (var k = 0; k < prog.blocks.length; k++) {
      final pass1 = prog.blocks[k].pass1;
      for (final d in pass1.days) {
        final gaps = principalGapsOfDay(catalog, d);
        if (gaps.isEmpty) continue;
        total += gaps.length;
        out.writeln(
          '- ${b.key} b$k j${d.dayIndex} ${pass1.split?.templateId} '
          '${_type(d)} : ${gaps.join(', ')} | ${_slots(catalog, d)}',
        );
      }
    }
  }
  out.writeln('total 34 profils : $total');

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
      for (final d in pass1.days) {
        gridDays++;
        final gaps = principalGapsOfDay(catalog, d);
        if (gaps.isEmpty) continue;
        gridGaps++;
        final axes = g.key.split('~');
        for (var i = 1; i < axes.length; i++) {
          byAxis['${axes[0]}~$i:${axes[i]}'] =
              (byAxis['${axes[0]}~$i:${axes[i]}'] ?? 0) + 1;
        }
        if (shown < 150) {
          shown++;
          out.writeln(
            '- ${g.key} b$k j${d.dayIndex} ${pass1.split?.templateId} '
            '${_type(d)} : ${gaps.join(', ')} | ${_slots(catalog, d)}',
          );
        }
      }
    }
  }
  out.writeln(
    'grille : ${grid.length} profils, $gridDays jours, $gridGaps jours en '
    'défaut, $failed échecs',
  );
  final keys = byAxis.keys.toList()..sort();
  for (final k in keys) {
    out.writeln('  $k : ${byAxis[k]}');
  }
  final path = args.isEmpty || args.first.startsWith('--')
      ? 'ks1c2_diag.md'
      : args.first;
  File(path).writeAsStringSync(out.toString());
  stdout.writeln('écrit $path ; 34 profils : $total ; grille : $gridGaps');
}
