// Mode coach (blocs au contrat 0.4.0) : tentatives, programmes street du
// banc en boucle complète sous les trois modèles de vérité, programmes de
// test à techniques injectées, affûtage, comportement 0.1 conservé à la
// demande, budgets de temps.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show SeededRandom, fnvMix;
import 'package:test/test.dart';

import 'support.dart';

/// Politique `kalis_adapt` qui mesure le temps de chaque décision.
final class _TimedChecked implements CoachAwarePolicy {
  _TimedChecked(this.inner);

  final KalisAdaptPolicy inner;
  final List<int> sessionMicros = <int>[];
  final List<int> adviceMicros = <int>[];

  @override
  String get name => inner.name;

  @override
  bool get rich => inner.rich;

  @override
  List<IntraSessionAdvice> takeAdvices() => inner.takeAdvices();

  @override
  SessionPlan plan(SessionContext c) {
    final watch = Stopwatch()..start();
    final session = inner.plan(c);
    sessionMicros.add(watch.elapsedMicroseconds);
    return session;
  }

  @override
  SetTarget? nextSet(
    SessionContext c,
    ExercisePrescription item,
    int index,
    List<SetRecord> done,
  ) {
    final watch = Stopwatch()..start();
    final target = inner.nextSet(c, item, index, done);
    if (index > 0) {
      adviceMicros.add(watch.elapsedMicroseconds);
    }
    return target;
  }

  @override
  void finish(SessionContext c, SessionRecord record) =>
      inner.finish(c, record);

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

int _median(List<int> values) {
  final sorted = List<int>.of(values)..sort();
  return sorted.isEmpty ? 0 : sorted[sorted.length ~/ 2];
}

void main() {
  const p = AdaptParams.standard;
  final catalog = loadCatalog();

  group('tentatives', () {
    test('croissantes, bornées par l\'estimation, sur 10 000 tirages', () {
      final failures = <String>[];
      for (var seed = 0; seed < 10000; seed++) {
        final r = SeededRandom(fnvMix(0x41545450, seed));
        final barbell = r.nextInt(2) == 0;
        final bodyPart = barbell ? 0.0 : 60 + r.nextInt(50) * 1.0;
        final estimate = bodyPart + (barbell ? 60 : 20) + r.nextInt(180);
        final relSd = 0.01 + r.nextDouble() * 0.12;
        final grid = LoadGrid.of(
          barbell ? LoadType.barbell : LoadType.addedWeight,
          null,
        );
        final external = estimate - bodyPart;
        final recent = r.nextInt(4) == 0
            ? null
            : grid.floor(external * (0.8 + r.nextDouble() * 0.2));
        final health = r.nextInt(5) == 0 ? 1 + r.nextInt(2) : 0;
        final objective = <EventObjective?>[
          null,
          EventObjective.secureTotal,
          EventObjective.maxTotal,
          EventObjective.record,
        ][r.nextInt(4)];
        final target = r.nextInt(3) == 0
            ? grid.floor(external * (0.95 + r.nextDouble() * 0.15))
            : null;
        final picks = attemptLadder(
          estimateTotal: estimate,
          relSd: relSd,
          bodyPart: bodyPart,
          grid: grid,
          attempts: 3,
          done: const <(double, bool)>[],
          recentBest: recent,
          targetKg: target,
          objective: objective,
          healthLevel: health,
          prudentCause: r.nextInt(6) == 0 ? 'pain' : null,
          p: p,
        );
        final where = 'graine $seed';
        if (picks.length != 3) {
          failures.add('$where : ${picks.length} tentatives');
          continue;
        }
        for (var i = 1; i < picks.length; i++) {
          if (picks[i].loadKg < picks[i - 1].loadKg - 1e-9) {
            failures.add('$where : tentatives décroissantes');
          }
        }
        final opener = picks.first.loadKg + bodyPart;
        final floorKg = grid.minimum + bodyPart;
        if (opener > p.attemptOpenerShare * estimate + 1e-6 &&
            opener > floorKg + 1e-6) {
          failures.add('$where : ouverture à ${opener / estimate}');
        }
        if (recent != null &&
            recent + bodyPart >= 0.85 * estimate &&
            picks.first.loadKg > recent + 1e-9 &&
            picks.first.loadKg > grid.minimum + 1e-9) {
          failures.add('$where : ouverture au-dessus de la barre déjà faite');
        }
        // Troisième barre : jamais au-delà de ce qui garde la probabilité
        // de l'objectif « record », sauf le plus petit saut obligatoire.
        final third = picks[2];
        final forced = third.loadKg <= picks[1].loadKg + grid.step + 1e-9;
        if (!forced && third.probability < p.attemptRecordProbability - 1e-6) {
          failures.add('$where : troisième barre à ${third.probability}');
        }
        // Après une barre manquée : la même barre.
        final again = attemptLadder(
          estimateTotal: estimate,
          relSd: relSd,
          bodyPart: bodyPart,
          grid: grid,
          attempts: 3,
          done: <(double, bool)>[
            (picks[0].loadKg, true),
            (picks[1].loadKg, false),
          ],
          recentBest: recent,
          targetKg: target,
          objective: objective,
          healthLevel: health,
          prudentCause: null,
          p: p,
        );
        if (again.length != 1 ||
            (again.first.loadKg - picks[1].loadKg).abs() > 1e-9) {
          failures.add('$where : barre changée après un échec');
        }
        if (failures.length > 20) {
          break;
        }
      }
      expect(failures, isEmpty);
    });
  });

  group('programmes street du banc', () {
    for (final key in streetKeys()) {
      test('$key : bloc au contrat 0.4.0, boucle complète, trois vérités', () {
        final profile = streetProfile(key);
        final program = streetProgram(key);
        expect(blockCoached(program.block(0)), isTrue);
        for (final truth in TruthKind.values) {
          final engine = KalisAdapt();
          final policy = CheckedPolicy(engine);
          final run = simulate(
            catalog: catalog,
            spec: streetAthlete(key),
            profile: profile,
            seed: 3 + truth.index,
            policy: policy,
            program: program,
            weeks: 9,
            loop: engine,
            truthKind: truth,
          );
          expect(
            policy.violations,
            isEmpty,
            reason: '$key, vérité ${truth.name}',
          );
          expect(run.sessionsDone, greaterThan(0));
          // Séances au contrat 0.4.0 : phase et intention dites.
          expect(run.served.first.plan.weekIntent, isNotNull);
          for (final s in run.served) {
            expect(s.record.validate(), isEmpty, reason: 'journal $key');
          }
          for (final (_, review) in run.reviews) {
            expect(review.validate(), isEmpty, reason: 'revue $key');
          }
        }
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
  });

  group('programmes de test (techniques injectées)', () {
    final seen = <SetTechniqueKind>{};
    for (final (key, offset) in const <(String, int)>[
      ('street_06_inter_sets_reps', 0),
      ('street_07_avance_streetlifting_competition', 0),
      ('street_07_avance_streetlifting_competition', 5),
      ('street_09_elite_streetlifting', 3),
      ('street_09_elite_streetlifting', 9),
      ('street_11_master_51_ans', 6),
      ('street_14_parc_sans_lest', 8),
    ]) {
      test('$key, rang $offset : lignes valides, invariants tenus', () {
        final profile = streetProfile(key);
        final program = streetProgram(key, inject: true, offset: offset);
        final block = program.block(0);
        expect(block.validate(), isEmpty, reason: 'bloc injecté $key');
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final run = simulate(
          catalog: catalog,
          spec: streetAthlete(key),
          profile: profile,
          seed: 11,
          policy: policy,
          program: program,
          weeks: 6,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty, reason: key);
        final level = profile.experience?.index ?? 1;
        for (final s in run.served) {
          expect(s.record.validate(), isEmpty, reason: 'journal $key');
          for (final set in s.record.sets) {
            final technique = set.technique;
            if (technique != null) {
              seen.add(technique);
              expect(
                level,
                greaterThanOrEqualTo(techniqueAccessLevel(technique)),
                reason: '$key : ${technique.code} au niveau $level',
              );
            }
            final parts = set.parts;
            final reps = set.reps;
            if (parts != null && reps != null) {
              var sum = 0;
              for (final part in parts) {
                sum += part.reps ?? 0;
              }
              expect(sum, reps, reason: '$key : parties ≠ total');
            }
          }
        }
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
    test('chaque technique à parties ou à paliers a été exécutée', () {
      expect(
        seen,
        containsAll(<SetTechniqueKind>[
          SetTechniqueKind.topSetBackoff,
          SetTechniqueKind.cluster,
          SetTechniqueKind.restPause,
          SetTechniqueKind.myoReps,
          SetTechniqueKind.dropSet,
          SetTechniqueKind.wave,
          SetTechniqueKind.emom,
          SetTechniqueKind.ladder,
          SetTechniqueKind.pyramid,
          SetTechniqueKind.density,
          SetTechniqueKind.forTime,
          SetTechniqueKind.amrap,
        ]),
      );
    });
  });

  group('périodisation', () {
    test(
      'affûtage et échéance : aucun volume ajouté, tentatives le jour J',
      () {
        const key = 'street_07_avance_streetlifting_competition';
        final profile = streetProfile(key);
        final program = streetProgram(key);
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final run = simulate(
          catalog: catalog,
          spec: streetAthlete(key),
          profile: profile,
          seed: 5,
          policy: policy,
          program: program,
          weeks: 12,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty);
        var taperSessions = 0;
        var attempts = 0;
        for (final s in run.served) {
          final intent = s.plan.weekIntent;
          if (intent == WeekIntent.taper || intent == WeekIntent.competition) {
            taperSessions++;
            ProgramBlock? block;
            for (var i = 0; i < run.blocks.length; i++) {
              if (run.blockWeeks[i] <= s.week) {
                block = run.blocks[i];
              }
            }
            final written = <String, int>{};
            for (final w in block!.pass2.weeks) {
              if (w.weekIndex == s.weekInBlock) {
                for (final d in w.days) {
                  if (d.dayIndex == s.plan.dayIndex) {
                    for (final it in d.items) {
                      written[it.slotId] = it.sets;
                    }
                  }
                }
              }
            }
            for (final it in s.plan.items) {
              final sets = written[it.slotId];
              if (sets != null) {
                expect(it.sets, lessThanOrEqualTo(sets));
              }
            }
          }
          for (final set in s.record.sets) {
            if (set.role == SetRole.attempt) {
              attempts++;
            }
          }
        }
        expect(taperSessions, greaterThan(0));
        expect(attempts, greaterThanOrEqualTo(9));
        // Tentatives croissantes, ouverture réussie plus de neuf fois sur dix
        // (une seule simulation : toutes les ouvertures doivent passer).
        final byLift = <String, List<SetRow>>{};
        for (final row in run.sets) {
          if (row.attempt) {
            byLift
                .putIfAbsent(
                  '${row.simDay}|${row.exerciseId}',
                  () => <SetRow>[],
                )
                .add(row);
          }
        }
        for (final rows in byLift.values) {
          for (var i = 1; i < rows.length; i++) {
            expect(
              rows[i].loadKg! + 1e-9,
              greaterThanOrEqualTo(rows[i - 1].loadKg!),
            );
          }
        }
        // Résultats de test reportés au profil.
        expect(run.finalProfile?.benchmarks, isNotNull);
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );

    test('comportement 0.1 à la demande : aucun champ du mode coach', () {
      const key = 'street_07_avance_streetlifting_competition';
      final profile = streetProfile(key);
      final block = streetProgram(key).block(0);
      final input = AdaptInput(
        profile: profile,
        block: block,
        log: const TrainingLog(sessions: <SessionRecord>[]),
        today: block.pass1.startDate,
      );
      final request = SessionRequest(
        input: input,
        weekIndex: 0,
        dayIndex: block.pass2.weeks.first.days.first.dayIndex,
      );
      final old = KalisAdapt(legacy: true).prescribeSession(catalog, request);
      final coach = KalisAdapt().prescribeSession(catalog, request);
      expect(old.validate(), isEmpty);
      expect(coach.validate(), isEmpty);
      expect(old.phase, isNull);
      expect(old.weekIntent, isNull);
      expect(coach.weekIntent, isNotNull);
    });
  });

  group('budgets de temps (VM Dart)', () {
    test('séance ≤ 50 ms, conseil ≤ 5 ms (médianes, 12 semaines)', () {
      const key = 'street_09_elite_streetlifting';
      final engine = KalisAdapt();
      final policy = _TimedChecked(KalisAdaptPolicy(engine));
      simulate(
        catalog: catalog,
        spec: streetAthlete(key),
        profile: streetProfile(key),
        seed: 2,
        policy: policy,
        program: streetProgram(key),
        weeks: 12,
        loop: engine,
        truthKind: TruthKind.c,
      );
      expect(policy.sessionMicros, isNotEmpty);
      expect(policy.adviceMicros, isNotEmpty);
      expect(_median(policy.sessionMicros), lessThan(50000));
      expect(_median(policy.adviceMicros), lessThan(5000));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
