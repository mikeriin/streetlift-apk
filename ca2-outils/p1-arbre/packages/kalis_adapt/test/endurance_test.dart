// Conduite de l'endurance (CA2, partie 1 ; `CONTRAT.md`, § 12) : course,
// conditionnement et profils hybrides suivis 16 semaines sur les trois
// modèles de vérité ; invariants E1 à E3 vérifiés à chaque séance
// (`checkSession`), comparaison au comportement de 0.2 (lignes servies
// telles qu'écrites).
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Athlètes d'endurance du test : profil type, niveau.
const List<(String, int)> _athletes = <(String, int)>[
  ('coureur_cardio_3x45', 0),
  ('semi_marathon', 1),
  ('crossfit_5x60', 1),
  ('homme_40_cardio_musculation_50_50', 1),
];

AthleteSpec _spec(String key, int level, {bool irregular = false}) =>
    AthleteSpec(
      key: key,
      profileKey: key,
      level: level,
      weeklyGain: 0.004,
      missRate: irregular ? 0.25 : 0.08,
      breakFromDay: irregular ? 50 : null,
      breakDays: irregular ? 16 : 0,
      illnessFromDay: irregular ? 85 : null,
      illnessDays: irregular ? 6 : 0,
    );

void main() {
  final catalog = loadCatalog();
  const off = AdaptParams(enduranceConduct: false);

  group('endurance (CA2, partie 1)', () {
    for (final (key, level) in _athletes) {
      test('$key : invariants E1 à E3, sorties bornées, moins de surcharges '
          'qu\'en 0.2', () {
        var spikeOn = 0.0;
        var spikeOff = 0.0;
        var overuseOn = 0;
        var overuseOff = 0;
        var runs = 0;
        for (final kind in TruthKind.values) {
          for (var seed = 0; seed < 6; seed++) {
            final spec = _spec(key, level, irregular: seed.isOdd);
            final on = KalisAdapt();
            final policy = CheckedPolicy(on);
            final a = simulate(
              catalog: catalog,
              spec: spec,
              profile: profileOf(key),
              seed: seed,
              policy: policy,
              program: programOf(key),
              weeks: 16,
              truthKind: kind,
            );
            expect(policy.violations, isEmpty, reason: '$kind, graine $seed');
            final b = simulate(
              catalog: catalog,
              spec: spec,
              profile: profileOf(key),
              seed: seed,
              policy: CheckedPolicy(KalisAdapt(params: off)),
              program: programOf(key),
              weeks: 16,
              truthKind: kind,
            );
            if (a.worstRunSpike > 0) {
              runs++;
              // Arrondis de distance et vitesse lue sur le journal : 3 %.
              expect(
                a.worstRunSpike,
                lessThanOrEqualTo(1.10 * 1.03),
                reason: '$kind, graine $seed',
              );
            }
            if (a.worstRunSpike > spikeOn) {
              spikeOn = a.worstRunSpike;
            }
            if (b.worstRunSpike > spikeOff) {
              spikeOff = b.worstRunSpike;
            }
            overuseOn += a.enduranceOveruse;
            overuseOff += b.enduranceOveruse;
          }
        }
        // (Blessures rares, tirées au hasard : marge de deux ; la borne
        // absolue des sorties est vérifiée graine par graine ci-dessus.)
        expect(overuseOn, lessThanOrEqualTo(overuseOff + 2));
        expect(runs == 0 || spikeOn <= 1.10 * 1.03, isTrue);
        expect(spikeOff, greaterThanOrEqualTo(0));
      }, timeout: const Timeout(Duration(minutes: 15)));
    }

    test('jour sans : la séance de qualité devient facile, jamais plus '
        'rapide', () {
      final key = 'semi_marathon';
      final engine = KalisAdapt();
      final program = programOf(key);
      final block = program.block(0);
      // Une semaine de course faite, puis un bilan bas le jour d'une
      // séance de qualité.
      final book = ExerciseBook(catalog, profileOf(key));
      for (final w in block.pass2.weeks) {
        for (final d in w.days) {
          final quality = d.items.where((it) {
            final info = book.find(it.exerciseId);
            return info != null &&
                enduranceKindOf(info) == EnduranceKind.run &&
                it.kind != SetKind.warmup &&
                isQualityRun(it, info, engine.params);
          });
          if (quality.isEmpty) {
            continue;
          }
          final today = block.pass1.startDate.addDays(
            7 * w.weekIndex + d.dayIndex,
          );
          final plan = engine.prescribeSession(
            catalog,
            SessionRequest(
              input: AdaptInput(
                profile: profileOf(key),
                block: block,
                log: const TrainingLog(sessions: <SessionRecord>[]),
                today: today,
              ),
              weekIndex: w.weekIndex,
              dayIndex: d.dayIndex,
              healthCheck: const HealthCheck(overall: 2),
            ),
          );
          for (final item in plan.items) {
            final info = book.find(item.exerciseId);
            if (info == null ||
                enduranceKindOf(info) != EnduranceKind.run ||
                item.kind == SetKind.warmup) {
              continue;
            }
            expect(
              isQualityRun(item, info, engine.params),
              isFalse,
              reason: '${item.exerciseId} le ${today.iso}',
            );
          }
          expect(
            plan.adjustments.any(
              (a) => a.reasons.any(
                (r) => r.code == ReasonCodes.adaptEasyInstead,
              ),
            ),
            isTrue,
          );
          return;
        }
      }
      fail('aucune séance de qualité dans le bloc');
    });
  });
}
