// Règles du mode coach ajoutées par le calibrage CA1 : alerte de
// surmenage, plage servie à la réserve du bloc, séries fractionnées quand
// la plage écrite est hors de portée.
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_adapt/src/model.dart' show formAfter;
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Politique contrôlée qui retient, avant chaque séance, la capacité
/// estimée des exercices suivis.
final class _Captured extends CheckedPolicy {
  _Captured(super.engine, this.ids);

  final Set<String> ids;

  /// Capacité estimée avant la séance, par date et par exercice.
  final Map<String, Map<String, double>> before =
      <String, Map<String, double>>{};

  @override
  SessionPlan plan(SessionContext c) {
    final seen = <String, double>{};
    for (final id in ids) {
      final e = inner.estimate(c, id, 1);
      if (e != null) {
        seen[id] = e.capacity;
      }
    }
    before[c.date.iso] = seen;
    return super.plan(c);
  }
}

void main() {
  const p = AdaptParams.standard;
  final catalog = loadCatalog();

  group('alerte de surmenage', () {
    final drop = math.log(1 - p.coachOverreachDrop);
    test('deux séances mesurées de suite sous la référence : alerte', () {
      var form = const <(int, double)>[];
      double? ratio;
      (form, ratio) = formAfter(form, 0, 3.0, p);
      expect(ratio, isNull);
      (form, ratio) = formAfter(form, 3, 3.0 + drop - 0.01, p);
      expect(ratio, isNull);
      (form, ratio) = formAfter(form, 7, 3.0 + drop - 0.02, p);
      expect(ratio, isNotNull);
      expect(ratio, lessThanOrEqualTo(1 - p.coachOverreachDrop));
      // La séance d'alerte devient la référence : pas d'alerte en chaîne.
      expect(form, hasLength(1));
      expect(form.single.$1, 7);
      (form, ratio) = formAfter(form, 10, 3.0 + drop - 0.02, p);
      expect(ratio, isNull);
    });
    test('une seule séance basse, ou un retour au niveau : pas d\'alerte', () {
      var form = const <(int, double)>[];
      double? ratio;
      (form, _) = formAfter(form, 0, 3.0, p);
      (form, _) = formAfter(form, 3, 3.0 + drop - 0.01, p);
      (form, ratio) = formAfter(form, 7, 3.0, p);
      expect(ratio, isNull);
      (form, ratio) = formAfter(form, 10, 3.0 + drop / 2, p);
      expect(ratio, isNull);
      expect(form, hasLength(3));
    });
    test('séances trop espacées : pas d\'alerte', () {
      var form = const <(int, double)>[];
      double? ratio;
      (form, _) = formAfter(form, 0, 3.0, p);
      (form, _) = formAfter(form, 14, 2.8, p);
      (form, ratio) = formAfter(form, p.coachOverreachSpanDays + 1, 2.8, p);
      expect(ratio, isNull);
    });
    test('deux passages le même jour ne comptent qu\'une fois', () {
      var form = const <(int, double)>[];
      double? ratio;
      (form, _) = formAfter(form, 0, 3.0, p);
      (form, _) = formAfter(form, 3, 2.8, p);
      (form, ratio) = formAfter(form, 3, 2.8, p);
      expect(ratio, isNull);
      expect(form, hasLength(2));
    });
  });

  group('plage servie à la réserve du bloc', () {
    // Peu de temps : traction 3 × 4 à 5 puis 3 × 5 à 6 à 2 en réserve, pour
    // un maximum de 6 — le haut de la plage ne laisse pas la réserve.
    test('street_13 : aucune série fixe au-dessus du maximum moins la '
        'réserve', () {
      const key = 'street_13_peu_de_temps';
      const id = 'sw-traction-pronation';
      final engine = KalisAdapt();
      final policy = _Captured(engine, <String>{id});
      final run = simulate(
        catalog: catalog,
        spec: streetAthlete(key),
        profile: streetProfile(key),
        seed: 4,
        policy: policy,
        program: streetProgram(key),
        weeks: 10,
        loop: engine,
        truthKind: TruthKind.b,
      );
      expect(policy.violations, isEmpty);
      var checked = 0;
      for (final s in run.served) {
        final intent = s.plan.weekIntent;
        final build =
            intent == WeekIntent.accumulation ||
            intent == WeekIntent.intensification ||
            intent == WeekIntent.realization;
        final cap = policy.before[s.plan.date.iso]?[id];
        if (!build || cap == null) {
          continue;
        }
        for (final it in s.plan.items) {
          if (it.exerciseId != id ||
              it.kind == SetKind.test ||
              it.technique != null) {
            continue;
          }
          final rir = Flames.toRir(it.targetFlames ?? 3);
          for (final t in it.setTargets ?? const <SetTarget>[]) {
            final high = t.repsHigh;
            if (high == null || t.repsLow != high) {
              continue;
            }
            // Effort affiché honnête : les répétitions servies et la
            // réserve affichée tiennent dans le maximum estimé.
            final shown = Flames.toRir(t.flames ?? it.targetFlames ?? 3);
            expect(
              high + (shown < rir ? shown : rir),
              lessThanOrEqualTo(cap * 1.05 + 1.5),
              reason: '${s.plan.date.iso} : $high répétitions, maximum $cap',
            );
            // Réserve du bloc (2 au moins sur ce mouvement).
            final kept = (cap * 1.05 - 2 + 0.3).floor();
            expect(
              high,
              lessThanOrEqualTo(kept < 1 ? 1 : kept),
              reason: '${s.plan.date.iso} : $high répétitions, maximum $cap',
            );
            checked++;
          }
        }
      }
      expect(checked, greaterThan(10));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('séries fractionnées', () {
    // Débutante : pompe classique écrite 2 × 3 à 6 à 2 en réserve pour un
    // maximum de 3 — des séries plus courtes et plus nombreuses.
    test('street_03 : plage hors de portée, plus de séries, plus '
        'courtes', () {
      const key = 'street_03_debutante';
      const id = 'sw-pompe';
      final engine = KalisAdapt();
      final policy = _Captured(engine, <String>{id});
      final run = simulate(
        catalog: catalog,
        spec: streetAthlete(key),
        profile: streetProfile(key),
        seed: 4,
        policy: policy,
        program: streetProgram(key),
        weeks: 10,
        loop: engine,
        truthKind: TruthKind.b,
      );
      expect(policy.violations, isEmpty);
      var split = 0;
      for (final s in run.served) {
        final cap = policy.before[s.plan.date.iso]?[id];
        for (final it in s.plan.items) {
          if (it.exerciseId != id || it.kind == SetKind.test || cap == null) {
            continue;
          }
          final written = _written(run, s, it.slotId);
          final low = written?.repsLow;
          if (written == null || low == null) {
            continue;
          }
          final targets = it.setTargets ?? const <SetTarget>[];
          if (targets.length > written.sets) {
            split++;
            // Jamais plus du double des séries (trois au moins permises),
            // chaque série plus courte que le bas de la plage écrite.
            final most = 2 * written.sets < 3 ? 3 : 2 * written.sets;
            expect(targets.length, lessThanOrEqualTo(most));
            for (final t in targets) {
              expect(t.repsHigh, lessThan(low));
              expect(t.repsHigh, greaterThanOrEqualTo(1));
            }
          }
        }
      }
      expect(split, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}

/// Prescription écrite par le bloc pour l'emplacement [slotId] de la séance
/// [s], ou `null`.
ExercisePrescription? _written(SimRun run, SimSession s, String slotId) {
  ProgramBlock? block;
  for (var i = 0; i < run.blocks.length; i++) {
    if (i < run.blockWeeks.length && run.blockWeeks[i] <= s.week) {
      block = run.blocks[i];
    }
  }
  if (block == null) {
    return null;
  }
  for (final w in block.pass2.weeks) {
    if (w.weekIndex != s.weekInBlock) {
      continue;
    }
    for (final d in w.days) {
      if (d.dayIndex != s.plan.dayIndex) {
        continue;
      }
      for (final it in d.items) {
        if (it.slotId == slotId) {
          return it;
        }
      }
    }
  }
  return null;
}
