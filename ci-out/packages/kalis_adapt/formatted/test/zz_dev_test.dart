// Branche de contrôle seulement : formate le paquet, exporte les sources
// formatées dans out-packages/<paquet>/formatted, et écrit des traces de
// simulation (mise au point).
import 'dart:io';

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import '../tool/l7/l7_policy.dart';
import 'support.dart';

void main() {
  test('export des sources formatées', () {
    final r = Process.runSync('dart', <String>['format', '.']);
    final out = Directory('../../out-packages/kalis_adapt/formatted');
    out.createSync(recursive: true);
    File(
      '${out.path}/format.log',
    ).writeAsStringSync('${r.stdout}\n${r.stderr}');
    for (final dir in <String>['lib', 'test', 'bin', 'tool']) {
      final d = Directory(dir);
      if (!d.existsSync()) {
        continue;
      }
      for (final f in d.listSync(recursive: true)) {
        if (f is File && f.path.endsWith('.dart')) {
          final target = File('${out.path}/${f.path}');
          target.parent.createSync(recursive: true);
          f.copySync(target.path);
        }
      }
    }
  });

  test('traces', () {
    final catalog = loadCatalog();
    final out = Directory('../../out-packages/kalis_adapt/trace');
    out.createSync(recursive: true);
    for (final key in <String>[
      'intermediaire_salle',
      'maison_halteres',
      'calisthenie_parc',
      'debutant_salle',
    ]) {
      final spec = athleteOf(key);
      final profile = profileOf(spec.profileKey);
      final program = programOf(spec.profileKey);
      final b = StringBuffer();
      final block = program.block(0);
      b.writeln('# bloc 0 : ${block.pass1.weeks} semaines');
      for (final w in block.pass2.weeks) {
        b.writeln('## semaine ${w.weekIndex} ${w.kind.code}');
        for (final d in w.days) {
          for (final it in d.items) {
            final e = catalog.find(it.exerciseId)!;
            b.writeln(
              '  j${d.dayIndex} ${it.slotId} ${it.exerciseId} '
              '[${e.loadType.code} ${e.unit.code}] ${it.sets}x'
              '${it.repsLow}-${it.repsHigh} s${it.secondsLow}-${it.secondsHigh} '
              'fl${it.targetFlames} rest${it.restSeconds} '
              'start${it.startLoadKg} cal${it.toCalibrate} '
              'targets${it.setTargets?.length} kind${it.kind?.code}',
            );
          }
        }
        if (w.weekIndex >= 1) {
          break;
        }
      }
      for (final name in <String>['kalis', 'dp', 'l7']) {
        final SimPolicy policy = name == 'kalis'
            ? KalisAdaptPolicy(KalisAdapt())
            : (name == 'dp'
                  ? DoubleProgressionPolicy()
                  : L7Policy(profile.bodyWeightKg ?? 72));
        final run = simulate(
          catalog: catalog,
          spec: spec,
          profile: profile,
          seed: 0,
          policy: policy,
          program: program,
          weeks: 12,
        );
        b.writeln('# politique $name');
        b.writeln(
          'sem,kind,exercice,mode,seance,serie,charge,cibleBas,cibleHaut,'
          'fait,flammes,rirVrai,rirVise,echec,principal,ouverte',
        );
        for (final s in run.sets) {
          b.writeln(
            '${s.week},${s.weekKind.code},${s.exerciseId},${s.mode.name},'
            '${s.exerciseSession},${s.setIndex},${s.loadKg},${s.targetLow},'
            '${s.targetHigh},${s.amount},${s.flames},'
            '${s.trueRir.toStringAsFixed(1)},${s.wantRir},${s.failed},'
            '${s.main},${s.open}',
          );
        }
        b.writeln('# estimations $name');
        for (final e in run.estimates) {
          b.writeln(
            '${e.week},${e.exerciseId},${e.exerciseSession},'
            '${e.capacity.toStringAsFixed(1)},${e.truth.toStringAsFixed(1)},'
            '${e.relSd.toStringAsFixed(3)},'
            '${e.operational.toStringAsFixed(1)},'
            '${e.truthOperational.toStringAsFixed(1)}',
          );
        }
      }
      File('${out.path}/$key.txt').writeAsStringSync(b.toString());
    }
  });
}
