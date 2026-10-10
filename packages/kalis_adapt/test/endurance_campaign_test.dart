// Mesure de la conduite de l'endurance (CA2, partie 1) : course débutante,
// semi-marathon, CrossFit, hybride 50/50 ; 16 semaines × 3 modèles de vérité
// × 20 graines ; trois politiques à programme égal : `kalis_adapt` 0.3.0,
// comportement de 0.2 (lignes servies telles qu'écrites) et un « coach
// simple » (règle des 10 % par semaine sur le temps de course, Buist et al.
// 2008). Le tableau est écrit dans le journal du contrôle (CI) ;
// `CONTRAT.md`, § 12.4, en recopie la lecture.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

const List<(String, int)> _athletes = <(String, int)>[
  ('coureur_cardio_3x45', 0),
  ('semi_marathon', 1),
  ('crossfit_5x60', 1),
  ('homme_40_cardio_musculation_50_50', 1),
];

/// Coach simple : le temps de course de la semaine (sept jours glissants)
/// ne dépasse pas de plus de 10 % celui des sept jours d'avant.
final class _TenPercent implements CoachAwarePolicy {
  _TenPercent(this.book) : inner = KalisAdaptPolicy(KalisAdapt(params: _off));

  static const AdaptParams _off = AdaptParams(enduranceConduct: false);

  final KalisAdaptPolicy inner;
  final ExerciseBook book;

  @override
  String get name => 'regle_10_pourcents';

  @override
  bool get rich => inner.rich;

  @override
  List<IntraSessionAdvice> takeAdvices() => inner.takeAdvices();

  bool _run(String id) {
    final info = book.find(id);
    return info != null && enduranceKindOf(info) == EnduranceKind.run;
  }

  double _seconds(SessionRecord s) {
    var t = 0.0;
    for (final set in s.sets) {
      if (_run(set.exerciseId) && set.kind != SetKind.warmup) {
        t +=
            set.seconds?.toDouble() ??
            ((set.distanceMeters ?? 0) / _off.enduranceRunSpeed);
      }
    }
    return t;
  }

  @override
  SessionPlan plan(SessionContext c) {
    final session = inner.plan(c);
    final day = c.date.dayNumber;
    var last7 = 0.0;
    var prev7 = 0.0;
    for (final s in c.log.sessions) {
      final d = s.date.dayNumber;
      if (d >= day - 7 && d < day) {
        last7 += _seconds(s);
      } else if (d >= day - 14 && d < day - 7) {
        prev7 += _seconds(s);
      }
    }
    var planned = 0.0;
    for (final it in session.items) {
      if (_run(it.exerciseId) && it.kind != SetKind.warmup) {
        planned += prescribedSeconds(it, it.sets, _off.enduranceRunSpeed);
      }
    }
    if (prev7 <= 0 || planned <= 0 || last7 + planned <= 1.1 * prev7) {
      return session;
    }
    var factor = (1.1 * prev7 - last7) / planned;
    if (factor < 0.3) {
      factor = 0.3;
    }
    return session.copyWith(
      items: <ExercisePrescription>[
        for (final it in session.items)
          if (_run(it.exerciseId) && it.kind != SetKind.warmup)
            it.copyWith(
              secondsHigh: it.secondsHigh == null
                  ? null
                  : (it.secondsHigh! * factor).floor(),
              secondsLow: it.secondsLow == null
                  ? null
                  : (it.secondsLow! * factor).floor(),
              distanceMeters: it.distanceMeters == null
                  ? null
                  : (it.distanceMeters! * factor / 100).floor() * 100.0,
            )
          else
            it,
      ],
    );
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) => inner.nextSet(c, item, index, done);

  @override
  void finish(SessionContext c, SessionRecord record) =>
      inner.finish(c, record);

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

final class _Tally {
  int runs = 0;
  int overuse = 0;
  double spikeSum = 0;
  int spikeRuns = 0;
  double runSeconds = 0;
  int weeks = 0;
  int painRises = 0;
}

void main() {
  final catalog = loadCatalog();
  const off = AdaptParams(enduranceConduct: false);

  test('campagne d\'endurance : 0.3.0, 0.2 et règle des 10 %', () {
    final out = StringBuffer()
      ..writeln()
      ..writeln('CAMPAGNE ENDURANCE (CA2, partie 1), 16 semaines')
      ..writeln(
        '| Athlète | Politique | Surcharges / 100 saisons | Pic moyen | '
        'Course (min / sem.) | Hausses sur zone douloureuse |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    var on = 0;
    var before = 0;
    for (final (key, level) in _athletes) {
      final tallies = <String, _Tally>{
        '0.3.0': _Tally(),
        '0.2': _Tally(),
        'regle_10': _Tally(),
      };
      for (final kind in TruthKind.values) {
        for (var seed = 0; seed < 20; seed++) {
          final spec = AthleteSpec(
            key: key,
            profileKey: key,
            level: level,
            weeklyGain: 0.004,
            missRate: seed.isOdd ? 0.2 : 0.08,
            breakFromDay: seed % 3 == 0 ? 50 : null,
            breakDays: seed % 3 == 0 ? 12 : 0,
          );
          for (final entry in tallies.entries) {
            final SimPolicy policy = switch (entry.key) {
              '0.3.0' => KalisAdaptPolicy(KalisAdapt()),
              '0.2' => KalisAdaptPolicy(KalisAdapt(params: off)),
              _ => _TenPercent(ExerciseBook(catalog, profileOf(key))),
            };
            final run = simulate(
              catalog: catalog,
              spec: spec,
              profile: profileOf(key),
              seed: seed,
              policy: policy,
              program: programOf(key),
              weeks: 16,
              truthKind: kind,
            );
            final t = entry.value;
            t.runs += 1;
            t.overuse += run.enduranceOveruse;
            t.painRises += run.painAggravations;
            t.weeks += 16;
            if (run.worstRunSpike > 0) {
              t.spikeSum += run.worstRunSpike;
              t.spikeRuns += 1;
            }
            for (final s in run.runSecondsByWeek.values) {
              t.runSeconds += s;
            }
          }
        }
      }
      for (final entry in tallies.entries) {
        final t = entry.value;
        final injuries = (100 * t.overuse / t.runs).toStringAsFixed(1);
        final spike = t.spikeRuns == 0
            ? '—'
            : (t.spikeSum / t.spikeRuns).toStringAsFixed(2);
        final minutes = (t.runSeconds / 60 / t.weeks).toStringAsFixed(0);
        final rises = (t.painRises / t.runs).toStringAsFixed(2);
        out.writeln(
          '| $key | ${entry.key} | $injuries | $spike | $minutes | $rises |',
        );
      }
      on += tallies['0.3.0']!.overuse;
      before += tallies['0.2']!.overuse;
    }
    print(out);
    // Sur l'ensemble, pas plus de blessures de surcharge qu'en 0.2 (marge
    // d'une par athlète : événements rares).
    expect(on, lessThanOrEqualTo(before + _athletes.length));
  }, timeout: const Timeout(Duration(minutes: 30)));
}
