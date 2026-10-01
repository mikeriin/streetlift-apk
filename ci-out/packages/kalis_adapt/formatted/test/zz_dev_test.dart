// Branche de contrôle seulement : formate le paquet, exporte les sources
// formatées dans out-packages/<paquet>/formatted, et écrit des traces de
// simulation (mise au point).
import 'dart:io';
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import '../tool/l7/l7_policy.dart';
import 'support.dart';

/// `kalis_adapt` avec l'état interne du moteur écrit avant chaque séance.
final class _Traced implements SimPolicy {
  _Traced(this.engine, this.out) : inner = KalisAdaptPolicy(engine);

  final KalisAdapt engine;
  final KalisAdaptPolicy inner;
  final StringBuffer out;

  @override
  String get name => inner.name;

  @override
  SessionPlan plan(SessionContext c) {
    final p = engine.params;
    final (ctx, view, replayed) = engine.prepare(
      c.catalog,
      AdaptInput(profile: c.profile, block: c.block, log: c.log, today: c.date),
    );
    final health = readHealth(c.health, p);
    final run = SessionRun(
      ctx,
      replayed.state.fork(),
      day: c.date.dayNumber,
      health: health,
      bodyWeightKg: bodyWeightOf(null, c.profile, p),
      extraRir: health.level * p.healthRirBonus,
      noIncrease: health.level >= 1,
    );
    for (final item in c.prescription.items) {
      final info = ctx.book.find(item.exerciseId);
      if (info == null || info.mode != CapacityMode.loaded) {
        continue;
      }
      final ex = run.begin(info, view.specOf(info, item, c.weekKind));
      final t = ex.track;
      if (t == null) {
        out.writeln('@ ${c.simDay} ${item.exerciseId} sans suivi');
        continue;
      }
      final f = t.filter;
      final last = t.lastLoad;
      String r(double v) => v.toStringAsFixed(3);
      out.writeln(
        '@ ${c.simDay} ${item.exerciseId} sante=${health.level}/${r(health.shift)} '
        'plage=${ex.spec.low}-${ex.spec.high} rir=${ex.spec.rir} '
        'rirEff=${ex.rirEff} incertain=${ex.uncertain} cal=${ex.calibrating} '
        'base=${r(ex.baseShift)} dev=${r(ex.rawDeviation)} '
        'gain=${r(run.state.fatigue.gain)} m=[${r(f.m[0])},${r(f.m[1])},'
        '${r(f.m[2])},${r(f.m[3])}] sd=${r(f.loadSd(ex.nPlan))} '
        'sdHorsJour=${r(f.loadSd(ex.nPlan, withDay: false))} '
        'derniere=$last noUp=${t.noUp} '
        '${last == null ? '' : 'reps(derniere)=${r(run.predictedReps(ex, last, ex.rirEff, 0))} possibles=${r(f.repsPossible(ln2(info.totalLoad(last, run.bodyWeightKg))))}'} '
        'poids=${r(run.state.rater.weight(p))}',
      );
    }
    return inner.plan(c);
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) => inner.nextSet(c, item, index, done);

  @override
  void finish(SessionContext c, SessionRecord record) {
    final p = engine.params;
    final (ctx, view, replayed) = engine.prepare(
      c.catalog,
      AdaptInput(profile: c.profile, block: c.block, log: c.log, today: c.date),
    );
    final run = SessionRun(
      ctx,
      replayed.state.fork(),
      day: c.date.dayNumber,
      health: readHealth(c.health, p),
      bodyWeightKg: bodyWeightOf(record, c.profile, p),
    );
    String? open;
    String r(double v) => v.toStringAsFixed(3);
    for (final set in record.sets) {
      final info = ctx.book.find(set.exerciseId);
      final reps = set.reps;
      if (info == null || info.mode != CapacityMode.loaded || reps == null) {
        continue;
      }
      if (!set.exerciseId.contains('elevation-laterale-halteres') &&
          !set.exerciseId.contains('split-squat')) {
        continue;
      }
      final key = '${set.slotId}|${set.exerciseId}';
      if (key != open) {
        open = key;
        final item = view.item(record.programRef, set.slotId, set.exerciseId);
        run.begin(
          info,
          view.specOf(info, item, c.weekKind, fallback: set.target),
        );
      }
      final ex = run.current!;
      final before = ex.track?.filter;
      final load = set.externalLoadKg ?? 0;
      final total = info.totalLoad(load, run.bodyWeightKg);
      final pre = before == null
          ? ''
          : 'avant m=[${r(before.m[0])},${r(before.m[1])},${r(before.m[2])},'
                '${r(before.m[3])}] fat=${r(before.fatigueNow(p))} '
                'poss=${r(before.repsPossible(ln2(total)))}';
      run.observe(
        loadKg: set.externalLoadKg,
        amount: reps,
        flames: set.flames,
        missed: !set.success,
        target: planOfTarget(set.target, hold: false),
        test: set.kind == SetKind.test,
      );
      final f = ex.track!.filter;
      out.writeln(
        '% ${c.simDay} ${set.exerciseId} $load kg x $reps fl=${set.flames} '
        'cible=${set.target?.repsLow}-${set.target?.repsHigh}/${set.target?.flames} '
        '$pre apres m=[${r(f.m[0])},${r(f.m[1])},${r(f.m[2])},${r(f.m[3])}] '
        'fat=${r(f.fatigueNow(p))} poss=${r(f.repsPossible(ln2(total)))} '
        'sdc=${r(math.sqrt(f.cov[0]))} sdd=${r(math.sqrt(f.cov[15]))}',
      );
    }
    run.closeExercise();
    inner.finish(c, record);
  }

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

double ln2(double x) => math.log(x);

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
            ? _Traced(KalisAdapt(), b)
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
          'fait,flammes,rirVrai,rirVise,echec,principal,ouverte,atteignable',
        );
        for (final s in run.sets) {
          b.writeln(
            '${s.week},${s.weekKind.code},${s.exerciseId},${s.mode.name},'
            '${s.exerciseSession},${s.setIndex},${s.loadKg},${s.targetLow},'
            '${s.targetHigh},${s.amount},${s.flames},'
            '${s.trueRir.toStringAsFixed(1)},${s.wantRir},${s.failed},'
            '${s.main},${s.open},${s.reachable}',
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
