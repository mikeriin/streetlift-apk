// Règles du mode coach ajoutées par le calibrage CA1 : alerte de
// surmenage, plage servie à la réserve du bloc, séries fractionnées quand
// la plage écrite est hors de portée.
import 'dart:math' as math;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_adapt/src/model.dart'
    show PainState, formAfter, painResumeDays, recentBestOf;
import 'package:kalis_adapt/src/session.dart'
    show coachBarPushUp, coachLowBar, coachWristNeutralSupport;
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Politique contrôlée qui retient, avant chaque séance, la capacité
/// estimée des exercices suivis.
final class _Captured implements CoachAwarePolicy {
  _Captured(KalisAdapt engine, this.ids) : inner = CheckedPolicy(engine);

  final CheckedPolicy inner;
  final Set<String> ids;

  /// Capacité estimée avant la séance, par date et par exercice.
  final Map<String, Map<String, double>> before =
      <String, Map<String, double>>{};

  List<String> get violations => inner.violations;

  @override
  String get name => inner.name;

  @override
  bool get rich => inner.rich;

  @override
  List<IntraSessionAdvice> takeAdvices() => inner.takeAdvices();

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
  void finish(SessionContext c, SessionRecord record) =>
      inner.finish(c, record);

  @override
  SimEstimate? estimate(SessionContext c, String exerciseId, double n) =>
      inner.estimate(c, exerciseId, n);
}

void main() {
  const p = AdaptParams.standard;
  final catalog = loadCatalog();

  group('douleur qui dure ou qui revient (CX, correction 1)', () {
    PainState zone(List<(int, int)> reports) {
      final s = PainState(BodyZone.wristHand, BodySide.right);
      for (final (day, intensity) in reports) {
        s.record(day, intensity);
      }
      return s;
    }

    test('trois sur dix pendant deux semaines : arrêt', () {
      final s = zone(const <(int, int)>[(0, 3), (3, 3), (7, 4), (10, 3)]);
      expect(s.stopAt(10), isNull);
      s.record(14, 3);
      final stop = s.stopAt(14);
      expect(stop, isNotNull);
      expect(stop!.zone, BodyZone.wristHand);
      expect(stop.sessions, 5);
      expect(stop.intensity, 4);
    });

    test('trois séances de suite au-dessus de 3 : arrêt gardé au premier '
        'signalement plus bas (relecture indépendante du code, CA2)', () {
      final s = zone(const <(int, int)>[(0, 4), (2, 4), (4, 4)]);
      expect(s.stopAt(4), isNotNull);
      s.record(6, 2);
      expect(s.stopAt(6), isNotNull);
      expect(s.stopAt(4 + painResumeDays), isNull);
    });

    test('forte plus d\'une semaine : arrêt', () {
      final s = zone(const <(int, int)>[(0, 6), (3, 5)]);
      expect(s.stopAt(3), isNull);
      s.record(7, 5);
      expect(s.stopAt(7), isNotNull);
    });

    test('retour après une accalmie : arrêt dès le premier signalement', () {
      final s = zone(const <(int, int)>[(0, 3), (3, 3), (30, 3)]);
      expect(s.stopAt(30)?.recurrence, isTrue);
      // Un seul signalement léger avant : pas un épisode réel.
      expect(zone(const <(int, int)>[(0, 3), (30, 3)]).stopAt(30), isNull);
    });

    test('deux semaines sans douleur au-dessus de 2 : reprise', () {
      final s = zone(const <(int, int)>[
        (0, 3),
        (3, 3),
        (7, 4),
        (10, 3),
        (14, 3),
        (17, 2),
        (21, 1),
      ]);
      expect(s.stopAt(21), isNotNull);
      expect(s.stopAt(14 + painResumeDays - 1), isNotNull);
      expect(s.stopAt(14 + painResumeDays), isNull);
    });

    test('un signalement levé montre la douleur du journal', () {
      final s = PainState(BodyZone.elbow, BodySide.left)
        ..lastIntensity = 0
        ..lastAboveDay = 10
        ..lastAboveIntensity = 4;
      expect(s.shownIntensity(12, 7), 4);
      expect(s.shownIntensity(18, 7), 0);
    });
  });

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

  group('tenue après un test', () {
    // CX, correction 1 : la borne de hausse d'une tenue laisse toujours
    // servir 55 % du meilleur maintien mesuré (la tenue menton écrite à
    // 17-19 s après un test de 30 s était servie à 5-9 s).
    test('street_01 : la tenue servie rejoint 55 % du test', () {
      const key = 'street_01_debutant_complet';
      const id = 'cs-tenue-menton-barre-pronation';
      final engine = KalisAdapt();
      final policy = CheckedPolicy(engine);
      final run = simulate(
        catalog: catalog,
        spec: streetAthlete(key),
        profile: streetProfile(key),
        seed: 4,
        policy: policy,
        program: streetProgram(key),
        weeks: 12,
        loop: engine,
        truthKind: TruthKind.b,
      );
      expect(policy.violations, isEmpty);
      var best = 0;
      var after = 0;
      var checked = 0;
      for (final r in run.sets) {
        if (r.exerciseId != id) {
          continue;
        }
        if (r.test) {
          if (r.amount > best) {
            best = r.amount.round();
          }
          continue;
        }
        if (best > 0) {
          checked++;
          if (r.targetHigh > after) {
            after = r.targetHigh;
          }
        }
      }
      expect(best, greaterThan(0));
      expect(checked, greaterThan(0));
      expect(after, greaterThanOrEqualTo((best * 0.55).floor()));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('séries fractionnées', () {
    // Plage écrite hors de portée le jour même (record déclaré au-dessus du
    // maximum réel, ou maximum en baisse) : des séries plus courtes et plus
    // nombreuses. Depuis `kalis_plan` 0.2.1 (lot CX), les blocs sont écrits
    // sur le dernier test et la débutante de street_03 reçoit l'échelle de
    // poussée : le cas se cherche sur plusieurs profils et graines, avec un
    // record de pompes surestimé pour street_03 (5 déclarées, 3 réelles).
    test('séries fractionnées : plus de séries, chacune sous le bas de la '
        'plage écrite', () {
      var split = 0;
      for (final key in const <String>[
        'street_03_debutante',
        'street_13_peu_de_temps',
        'street_17_hybride_street_course',
        'street_06_inter_sets_reps',
      ]) {
        final declared = streetProfile(key);
        final profile = key != 'street_03_debutante'
            ? declared
            : declared.copyWith(
                benchmarks: <Benchmark>[
                  for (final b in declared.benchmarks ?? const <Benchmark>[])
                    if (b.exerciseId == 'sw-pompe' &&
                        b.kind == BenchmarkKind.maxReps)
                      b.copyWith(reps: 5)
                    else
                      b,
                ],
              );
        for (final seed in const <int>[4, 0]) {
          final engine = KalisAdapt();
          final policy = _Captured(engine, const <String>{});
          final run = simulate(
            catalog: catalog,
            spec: streetAthlete(key),
            profile: profile,
            seed: seed,
            policy: policy,
            program: SimProgram(catalog, KalisPlan(), profile),
            weeks: 10,
            loop: engine,
            truthKind: TruthKind.b,
          );
          expect(policy.violations, isEmpty, reason: key);
          for (final s in run.served) {
            for (final it in s.plan.items) {
              if (it.kind == SetKind.test) {
                continue;
              }
              final written = _written(run, s, it.slotId);
              final low = written?.repsLow;
              if (written == null ||
                  low == null ||
                  written.exerciseId != it.exerciseId) {
                continue;
              }
              final targets = it.setTargets ?? const <SetTarget>[];
              if (targets.length > written.sets) {
                split++;
                // Jamais plus du double des séries (trois au moins
                // permises), chaque série plus courte que le bas de la
                // plage écrite.
                final most = 2 * written.sets < 3 ? 3 : 2 * written.sets;
                expect(targets.length, lessThanOrEqualTo(most), reason: key);
                for (final t in targets) {
                  expect(t.repsHigh, lessThan(low), reason: key);
                  expect(t.repsHigh, greaterThanOrEqualTo(1), reason: key);
                }
              }
            }
          }
        }
      }
      expect(split, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('test un jour de bilan bas', () {
    // Un test fait un jour de bilan nettement bas, hors compétition, ne
    // fait pas baisser le repère : il n'est rendu que s'il vaut au moins
    // le meilleur repère connu.
    for (final key in const <String>[
      'street_05_inter_calisthenie_front_lever',
      'street_08_avance_sets_reps_competition',
    ]) {
      test('$key : aucun repère abaissé par un test de mauvais jour', () {
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final profile = streetProfile(key);
        final run = simulate(
          catalog: catalog,
          spec: streetAthlete(key),
          profile: profile,
          seed: 4,
          policy: policy,
          program: streetProgram(key),
          weeks: 16,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty);
        double value(Benchmark b) => switch (b.kind) {
          BenchmarkKind.maxReps => (b.reps ?? 0).toDouble(),
          BenchmarkKind.maxHold => (b.seconds ?? 0).toDouble(),
          _ => b.externalLoadKg ?? 0,
        };
        final low = <String>{};
        for (final s in run.served) {
          if (s.record.eventId == null &&
              readHealth(s.record.healthCheck, p).level >= 2) {
            low.add(s.record.date.iso);
          }
        }
        var results = 0;
        for (final (_, review) in run.reviews) {
          final tests = review.testResults ?? const <Benchmark>[];
          for (final b in tests) {
            results++;
            final when = b.date;
            if (when == null || !low.contains(when.iso)) {
              continue;
            }
            for (final k in <Benchmark>[
              ...?profile.benchmarks,
              for (final t in tests)
                if ((t.date?.dayNumber ?? when.dayNumber) < when.dayNumber) t,
            ]) {
              if (k.exerciseId == b.exerciseId && k.kind == b.kind) {
                expect(
                  value(b),
                  greaterThanOrEqualTo(value(k)),
                  reason: '${b.exerciseId} le ${when.iso}',
                );
              }
            }
          }
        }
        expect(results, greaterThan(0));
      }, timeout: const Timeout(Duration(minutes: 10)));
    }
  });

  group('reprise graduée conduite séance par séance (CA2, partie 0)', () {
    test('levée de l\'arrêt datée après deux semaines sous 3 sur 10', () {
      final s = PainState(BodyZone.elbow, BodySide.both);
      for (final (day, intensity) in const <(int, int)>[
        (0, 5),
        (3, 5),
        (7, 5),
        (10, 2),
      ]) {
        s.record(day, intensity);
      }
      expect(s.stopAt(7), isNotNull);
      expect(s.liftedOn(7 + painResumeDays - 1), isNull);
      expect(s.liftedOn(7 + painResumeDays), 7 + painResumeDays);
      expect(s.liftedOn(40), 7 + painResumeDays);
      // Arrêt par trois séances de suite au-dessus du seuil : levée datée
      // même quand le compteur courant a été remis à zéro depuis.
      final r = PainState(BodyZone.wristHand, BodySide.both);
      for (final (day, intensity) in const <(int, int)>[
        (0, 4),
        (2, 4),
        (4, 4),
        (6, 2),
      ]) {
        r.record(day, intensity);
      }
      expect(r.liftedOn(4 + painResumeDays), 4 + painResumeDays);
      // Sans arrêt (un seul signalement léger), aucune levée.
      final t = PainState(BodyZone.elbow, BodySide.both)..record(0, 3);
      expect(t.liftedOn(30), isNull);
    });

    test(
      'meilleur maintien récent : jamais un record d\'avant une coupure',
      () {
        const bests = <(int, int)>[(0, 40), (3, 42), (30, 20), (33, 22)];
        expect(recentBestOf(bests, 35, 14, 28), 22);
        expect(recentBestOf(bests.sublist(0, 2), 5, 14, 28), 42);
        expect(recentBestOf(bests, 70, 14, 28), 0);
      },
    );

    test('street_12, douleur au coude : aucun test ni hausse sur la zone, '
        'reprise jamais au-dessus de l\'écrit', () {
      const key = 'street_12_antecedent_coude';
      final fixtures = readJsonObject('test/fixtures/street_profiles.json.gz');
      final entry = fixtures[key]! as Map<String, Object?>;
      final athlete =
          Map<String, Object?>.of(entry['athlete']! as Map<String, Object?>)
            ..['painZone'] = BodyZone.elbow.code
            ..['painFromDay'] = 28
            ..['painDays'] = 21
            ..['painIntensity'] = 5;
      var returned = 0;
      for (var seed = 0; seed < 4; seed++) {
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final run = simulate(
          catalog: catalog,
          spec: athleteFromJson(athlete),
          profile: streetProfile(key),
          seed: seed,
          policy: policy,
          program: streetProgram(key),
          weeks: 20,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty);
        expect(run.painAggravations, 0, reason: 'graine $seed');
        returned += _returnChecked(run);
        _painDayChecked(run, ExerciseBook(catalog, streetProfile(key)));
        _recentRiseChecked(
          run,
          ExerciseBook(catalog, streetProfile(key)),
          BodyZone.elbow,
          from: 28,
        );
      }
      expect(returned, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 20)));

    test('street_01 : l\'élastique ne change pas dans un sens puis dans '
        'l\'autre d\'une séance à la suivante', () {
      const key = 'street_01_debutant_complet';
      final engine = KalisAdapt();
      final policy = CheckedPolicy(engine);
      final run = simulate(
        catalog: catalog,
        spec: streetAthlete(key),
        profile: streetProfile(key),
        seed: 4,
        policy: policy,
        program: streetProgram(key),
        weeks: 16,
        loop: engine,
        truthKind: TruthKind.b,
      );
      expect(policy.violations, isEmpty);
      final assisted = <String>{
        for (final e in catalog.exercises)
          if (e.assisted) e.id,
      };
      final lastChange = <String, int>{};
      final lastFailed = <String, bool>{};
      var reversals = 0;
      for (final s in run.served) {
        for (final item in s.plan.items) {
          if (!assisted.contains(item.exerciseId)) {
            continue;
          }
          final slot = '${item.slotId}|${item.exerciseId}';
          var change = 0;
          for (final r in item.reasons) {
            if (r.code == ReasonCodes.adaptFlamesBelowTarget) {
              change = -1;
            } else if (r.code == ReasonCodes.adaptFlamesAboveTarget) {
              change = 1;
            }
          }
          final before = lastChange[slot] ?? 0;
          if (change != 0 &&
              before == -change &&
              !(lastFailed[slot] ?? false)) {
            reversals++;
          }
          lastChange[slot] = change;
          lastFailed[slot] = s.record.sets.any(
            (r) => r.slotId == item.slotId && !r.success,
          );
        }
      }
      expect(reversals, 0);
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('street_01, poignet encore à 3/10 pendant l\'arrêt : seul un appui '
        'neutre (parallettes, poignées) charge le poignet', () {
      const key = 'street_01_debutant_complet';
      final fixtures = readJsonObject('test/fixtures/street_profiles.json.gz');
      final entry = fixtures[key]! as Map<String, Object?>;
      final athlete =
          Map<String, Object?>.of(entry['athlete']! as Map<String, Object?>)
            ..['painZone'] = BodyZone.wristHand.code
            ..['painFromDay'] = 42
            ..['painDays'] = 28
            ..['painIntensity'] = 4;
      final book = ExerciseBook(catalog, streetProfile(key));
      var checked = 0;
      for (var seed = 0; seed < 3; seed++) {
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final run = simulate(
          catalog: catalog,
          spec: athleteFromJson(athlete),
          profile: streetProfile(key),
          seed: seed,
          policy: policy,
          program: streetProgram(key),
          weeks: 16,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty);
        final reports = <(int, int)>[];
        for (final s in run.served) {
          final today = <PainReport>[
            ...?s.record.healthCheck?.pains,
          ].where((r) => r.zone == BodyZone.wristHand);
          final hot =
              today.any((r) => r.intensity >= 3) ||
              reports.any(
                (r) => r.$1 >= s.simDay - 5 && r.$1 < s.simDay && r.$2 >= 3,
              );
          final inStop =
              s.plan.reasons.any(_wristStop) ||
              s.plan.adjustments.any((a) => a.reasons.any(_wristStop)) ||
              s.plan.items.any((it) => it.reasons.any(_wristStop));
          if (inStop && hot) {
            checked++;
            for (final item in s.plan.items) {
              final info = book.find(item.exerciseId);
              if (info == null || info.zoneLevel(BodyZone.wristHand) < 0.5) {
                continue;
              }
              expect(
                coachWristNeutralSupport(
                  info.exercise,
                  streetProfile(key).equipment.toSet(),
                ),
                isTrue,
                reason:
                    '${item.exerciseId} servi le ${s.record.date.iso} '
                    'pendant l\'arrêt du poignet',
              );
            }
          }
          for (final r in <PainReport>[
            ...?s.record.healthCheck?.pains,
            ...s.record.pains,
          ]) {
            if (r.zone == BodyZone.wristHand) {
              reports.add((s.simDay, r.intensity));
            }
          }
        }
      }
      expect(checked, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('street_01, première gêne du poignet (3/10 ou plus, avant '
        'l\'arrêt) : la pompe au sol passe sur un appui neutre, mains sur '
        'la barre basse (CY, partie 0)', () {
      const key = 'street_01_debutant_complet';
      final fixtures = readJsonObject('test/fixtures/street_profiles.json.gz');
      final entry = fixtures[key]! as Map<String, Object?>;
      final athlete =
          Map<String, Object?>.of(entry['athlete']! as Map<String, Object?>)
            ..['painZone'] = BodyZone.wristHand.code
            ..['painFromDay'] = 42
            ..['painDays'] = 28
            ..['painIntensity'] = 4;
      final profile = streetProfile(key);
      final equipment = profile.equipment.toSet();
      expect(equipment, contains(coachLowBar));
      final book = ExerciseBook(catalog, profile);
      var swapped = 0;
      for (var seed = 0; seed < 3; seed++) {
        final engine = KalisAdapt();
        final policy = CheckedPolicy(engine);
        final run = simulate(
          catalog: catalog,
          spec: athleteFromJson(athlete),
          profile: profile,
          seed: seed,
          policy: policy,
          program: streetProgram(key),
          weeks: 16,
          loop: engine,
          truthKind: TruthKind.b,
        );
        expect(policy.violations, isEmpty);
        final reports = <(int, int)>[];
        for (final s in run.served) {
          final gene = reports.any(
            (r) => r.$1 >= s.simDay - 13 && r.$1 < s.simDay && r.$2 >= 3,
          );
          if (gene) {
            for (final a in s.plan.adjustments) {
              if (a.kind == AdjustmentKind.exerciseSwapped &&
                  a.replacementExerciseId == coachBarPushUp) {
                swapped++;
              }
            }
            for (final item in s.plan.items) {
              final info = book.find(item.exerciseId);
              if (info == null ||
                  item.kind != SetKind.work ||
                  info.exercise.pattern != MovementPattern.pousseeHorizontale ||
                  info.exercise.stressOn(Joint.wrist) == JointStress.low) {
                continue;
              }
              // (Poussée paume à plat servie une semaine de gêne : seulement
              // faute d'appui neutre faisable — ici, la barre basse existe.)
              expect(
                coachWristNeutralSupport(info.exercise, equipment),
                isTrue,
                reason:
                    '${item.exerciseId} servi le ${s.record.date.iso} '
                    'pendant la gêne du poignet',
              );
            }
          }
          for (final r in <PainReport>[
            ...?s.record.healthCheck?.pains,
            ...s.record.pains,
          ]) {
            if (r.zone == BodyZone.wristHand) {
              reports.add((s.simDay, r.intensity));
            }
          }
        }
      }
      expect(swapped, greaterThan(0));
    }, timeout: const Timeout(Duration(minutes: 10)));
  });

  group('charges (CY, partie 0)', () {
    test('part écrite à 85 % ou plus : jamais servie au-dessus de l\'écrit '
        'par le couloir', () {
      const p0 = AdaptParams.standard;
      expect(p0.coachCorridorHeavyShare, 0.85);
      expect(p0.coachRepLoadShare, closeTo(0.025, 1e-9));
      expect(p0.coachRepGapMax, 4);
    });

    test('programme importé : restructurations sur demande seulement (C11)', () {
      expect(KalisAdapt().restructureImported, isFalse);
      expect(KalisAdapt(restructureImported: true).restructureImported, isTrue);
    });
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

/// Lignes servies en reprise graduée dans [run] ; vérifie qu'aucune n'est un
/// test ni ne sert plus de séries que le bloc n'en écrit.
int _returnChecked(SimRun run) {
  var returned = 0;
  for (final s in run.served) {
    for (final item in s.plan.items) {
      final back = item.reasons.any(
        (r) =>
            r.code == ReasonCodes.adaptLoadHeld &&
            r.params['cause'] == 'pain_return',
      );
      if (!back) {
        continue;
      }
      returned++;
      expect(item.kind, isNot(SetKind.test));
      final written = _written(run, s, item.slotId);
      if (written != null) {
        expect(
          item.sets,
          lessThanOrEqualTo(written.sets),
          reason: '${item.exerciseId} le ${s.record.date.iso}',
        );
      }
    }
  }
  return returned;
}

/// Vérifie qu'aucune séance de [run] ne sert, un jour où une zone est
/// signalée à 5 sur 10 ou plus avant la séance, un exercice qui la charge
/// (contrainte moyenne ou forte) — Silbernagel et al. 2007 (CA2, partie 0).
void _painDayChecked(SimRun run, ExerciseBook book) {
  for (final s in run.served) {
    final pains = s.record.healthCheck?.pains ?? const <PainReport>[];
    for (final pain in pains) {
      if (pain.intensity < 5) {
        continue;
      }
      for (final item in s.plan.items) {
        if (item.kind == SetKind.warmup) {
          continue;
        }
        final info = book.find(item.exerciseId);
        expect(
          info == null || info.zoneLevel(pain.zone) < 0.5,
          isTrue,
          reason:
              '${item.exerciseId} servi le ${s.record.date.iso} '
              '(${pain.zone.code} à ${pain.intensity}/10)',
        );
      }
    }
  }
}

/// Vérifie qu'après le début de la douleur ([from], jour de simulation), la
/// quantité par série servie sur un mouvement sans charge qui charge
/// [zone] ne dépasse jamais de plus de 10 % (une unité au moins) la plus
/// grande série de la séance précédente de ce mouvement (Soligard et al.
/// 2016 ; CA2, partie 0).
void _recentRiseChecked(
  SimRun run,
  ExerciseBook book,
  BodyZone zone, {
  required int from,
}) {
  final lastTop = <String, int>{};
  // La zone n'est connue du moteur qu'après le premier signalement (la
  // douleur du premier jour est dite pendant la séance, après la
  // prescription) : la règle vaut à partir de la séance suivante.
  int? known;
  for (final s in run.served) {
    final recent = s.simDay >= from && known != null && s.simDay > known;
    for (final item in s.plan.items) {
      if (item.kind == SetKind.warmup || item.kind == SetKind.test) {
        continue;
      }
      final info = book.find(item.exerciseId);
      if (info == null || info.zoneLevel(zone) < 0.5) {
        continue;
      }
      final loaded =
          item.percentOfOneRm != null ||
          (item.setTargets ?? const <SetTarget>[]).any(
            (t) => t.loadKg != null && t.loadKg! > 0,
          );
      final before = lastTop[item.exerciseId];
      if (recent && !loaded && before != null && before > 0) {
        var served = item.repsHigh ?? item.secondsHigh ?? 0;
        for (final t in item.setTargets ?? const <SetTarget>[]) {
          final h = t.repsHigh ?? t.secondsHigh ?? 0;
          if (h > served) {
            served = h;
          }
        }
        final grown = (before * 1.1).floor();
        final most = grown > before + 1 ? grown : before + 1;
        expect(
          served,
          lessThanOrEqualTo(most),
          reason: '${item.exerciseId} le ${s.record.date.iso}',
        );
      }
    }
    final tops = <String, int>{};
    for (final set in s.record.sets) {
      if (set.kind == SetKind.warmup) {
        continue;
      }
      final amount = set.reps ?? set.seconds ?? 0;
      if (amount > (tops[set.exerciseId] ?? 0)) {
        tops[set.exerciseId] = amount;
      }
    }
    lastTop.addAll(tops);
    if (known == null &&
        s.simDay >= from &&
        s.record.pains.any((r) => r.zone == zone)) {
      known = s.simDay;
    }
  }
}

/// Vrai pour la raison d'un arrêt du poignet (douleur qui dure).
bool _wristStop(Reason r) =>
    r.code == ReasonCodes.adaptPainPersistent &&
    r.params['zone'] == BodyZone.wristHand.code;
