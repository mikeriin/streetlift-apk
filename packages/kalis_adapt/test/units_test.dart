// Briques du moteur, une à une : grille des charges, filtre, bilan santé,
// modèle de note, fatigue, déblocage, application d'une proposition.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  const p = AdaptParams.standard;

  group('grille des charges', () {
    test('haltères par défaut : 1 kg jusqu\'à 10 kg, puis 2 kg', () {
      final g = LoadGrid.of(LoadType.dumbbells, null);
      expect(g.next(8, up: true), 9);
      expect(g.next(9, up: true), 10);
      expect(g.next(10, up: true), 12);
      expect(g.next(12, up: true), 14);
      expect(g.next(12, up: false), 10);
      expect(g.next(10, up: false), 9);
      expect(g.floor(11.9), 10);
      expect(g.floor(13.99), 12);
      expect(g.floor(0.2), 1);
      expect(g.nearest(10.9), 10);
      expect(g.nearest(11.1), 12);
      expect(g.stepAbove(9), 1);
      expect(g.stepAbove(10), 2);
    });

    test('barre : paire de disques de 1,25 kg ; lest : 1,25 kg', () {
      final bar = LoadGrid.of(LoadType.barbell, null);
      expect(bar.next(60, up: true), 62.5);
      expect(bar.floor(61.9), 60);
      expect(bar.floor(5), 20);
      expect(bar.next(20, up: false), 20);
      final belt = LoadGrid.of(LoadType.addedWeight, null);
      expect(belt.next(10, up: true), 11.25);
      expect(belt.next(0, up: false), 0);
    });

    test('poulie : 2,5 lb', () {
      final g = LoadGrid.of(LoadType.cable, null);
      expect(g.step, closeTo(1.13398, 1e-5));
      expect(
        g.next(10 * 2.5 * poundKg, up: true),
        closeTo(27.5 * poundKg, 1e-9),
      );
      expect(g.floor(20), closeTo(17 * 2.5 * poundKg, 1e-9));
    });

    test('une charge hors grille rejoint la grille dans le sens demandé', () {
      final bar = LoadGrid.of(LoadType.barbell, null);
      expect(bar.next(61, up: true), 62.5);
      expect(bar.next(61, up: false), 60);
      expect(bar.next(15, up: true), 20);
      expect(bar.next(15, up: false), 20);
      final d = LoadGrid.of(LoadType.dumbbells, null);
      expect(d.next(10.5, up: true), 12);
      expect(d.next(10.5, up: false), 10);
    });

    test('les incréments du profil priment', () {
      final profile = profileOf('femme_45_musculation_salle_4x60');
      final g = LoadGrid.of(LoadType.dumbbells, profile);
      expect(g.dumbbellRule, isFalse);
      expect(g.step, 2);
      expect(g.next(8, up: true), 10);
      expect(LoadGrid.of(LoadType.machine, profile).step, 5);
    });
  });

  group('filtre', () {
    CapacityFilter loaded({double sd = 0.25}) => CapacityFilter.fromOneRm(
      logOneRm: 4.6,
      sd: sd,
      v: 0.004,
      vSd: 0.005,
      k: 30,
      kLogSd: 0.3,
      nRef: 9.5,
      day: 0,
    );

    test('a priori : le 1RM et son incertitude sont ceux donnés', () {
      final f = loaded();
      expect(f.capacity, closeTo(99.484, 0.01));
      expect(f.capacityRelSd, closeTo(0.25, 1e-9));
      expect(f.k, closeTo(30, 1e-9));
    });

    test('des séries exactes ramènent l\'estimation vers la vérité', () {
      final f = loaded();
      const truth = 4.75; // ln du 1RM vrai
      for (var s = 0; s < 6; s++) {
        f.beginSession(3 * s + 1, 0, p.daySd, p);
        for (var i = 0; i < 3; i++) {
          // 8 répétitions à l'échec + 2 en réserve : n = 10.
          f.observeLoad(
            logLoad: truth + logShare(10, 30),
            n: 10,
            nSd: 1,
            fatigue: 0,
            p: p,
          );
        }
        f.endSession();
      }
      expect((f.m[0] + f.gRef - truth).abs(), lessThan(0.02));
      // La capacité là où l'exercice est travaillé est bien connue ; le
      // 1RM, extrapolé par la courbe, garde l'incertitude sur k.
      expect(f.loadSd(10, withDay: false), lessThan(0.03));
      expect(f.capacityRelSd, lessThan(0.08));
      expect(f.sessions, 6);
      expect(f.sets, 18);
      expect(f.history.length, 6);
    });

    test('la covariance reste symétrique et positive', () {
      final f = loaded();
      f.beginSession(2, -0.01, p.daySd, p);
      f.observeLoad(logLoad: 4.3, n: 9, nSd: 2, fatigue: 0.1, p: p);
      f.observeLoad(
        logLoad: 4.3,
        n: 7,
        nSd: 0.5,
        fatigue: 0.2,
        p: p,
        bound: true,
      );
      f.observeLoad(
        logLoad: 4.35,
        n: 6.5,
        nSd: 0.5,
        fatigue: 0,
        p: p,
        learnK: true,
      );
      for (var i = 0; i < 4; i++) {
        expect(f.cov[5 * i], greaterThan(0));
        for (var j = 0; j < 4; j++) {
          expect(f.cov[4 * i + j], closeTo(f.cov[4 * j + i], 1e-15));
          // Cauchy-Schwarz : |cov(i, j)|² ≤ var(i) × var(j).
          expect(
            f.cov[4 * i + j] * f.cov[4 * i + j],
            lessThanOrEqualTo(f.cov[5 * i] * f.cov[5 * j] * (1 + 1e-9)),
          );
        }
      }
    });

    test('une borne basse ne fait jamais baisser la capacité', () {
      for (final n in <double>[3, 8, 15, 30]) {
        final f = loaded();
        f.beginSession(1, 0, p.daySd, p);
        final before = f.m[0] + f.m[3];
        f.observeLoad(
          logLoad: 4.3,
          n: n,
          nSd: 0.5,
          fatigue: 0,
          p: p,
          bound: true,
        );
        expect(f.m[0] + f.m[3], greaterThanOrEqualTo(before - 1e-12));
      }
    });

    test('k ne bouge que si la série est dite précise (learnK)', () {
      final f = loaded();
      f.beginSession(1, 0, p.daySd, p);
      final k = f.m[2];
      f.observeLoad(logLoad: 4.2, n: 14, nSd: 1.5, fatigue: 0, p: p);
      expect(f.m[2], k);
      f.observeLoad(
        logLoad: 4.2,
        n: 16,
        nSd: 0.5,
        fatigue: 0,
        p: p,
        learnK: true,
      );
      expect(f.m[2], isNot(k));
      expect(f.k, inInclusiveRange(p.kMin, p.kMax));
    });

    test('sans séance, l\'incertitude croît avec le temps', () {
      final f = loaded(sd: 0.05);
      final before = f.capacityRelSd;
      f.predict(70, p);
      expect(f.capacityRelSd, greaterThan(before));
      // La tendance s'amortit : le niveau prévu reste borné.
      expect(f.m[1], lessThan(0.004));
    });

    test('la copie est indépendante', () {
      final f = loaded();
      final g = f.fork();
      g.beginSession(1, 0, p.daySd, p);
      g.observeLoad(logLoad: 4.5, n: 12, nSd: 1, fatigue: 0, p: p);
      expect(f.m[0], isNot(g.m[0]));
      expect(f.sets, 0);
      expect(f.inSession, isFalse);
    });

    test('fatigue de séance : décroît avec le RIR et le repos, plafonnée', () {
      expect(setFatigueOf(0, 120, p), greaterThan(setFatigueOf(3, 120, p)));
      expect(setFatigueOf(2, 60, p), greaterThan(setFatigueOf(2, 240, p)));
      expect(plannedFatigue(0, 2, 120, p), 0);
      expect(
        plannedFatigue(3, 2, 120, p),
        greaterThan(plannedFatigue(1, 2, 120, p)),
      );
      expect(plannedFatigue(19, 0, 10, p), 0.8);
    });
  });

  group('bilan santé (D5.8)', () {
    test('aucun bilan, ou un bilan sans réponse : aucun effet', () {
      for (final check in <HealthCheck?>[null, const HealthCheck()]) {
        final r = readHealth(check, p);
        expect(r.shift, 0);
        expect(r.level, 0);
        expect(r.answered, 0);
      }
    });

    test('une réponse absente n\'est jamais remplacée par une valeur', () {
      // Sommeil mauvais seul : le terme général (« comment tu te sens »)
      // n'est pas supposé neutre ni bas, il est absent.
      final only = readHealth(const HealthCheck(sleepQuality: 1), p);
      expect(only.answered, 1);
      expect(only.shift, closeTo(-p.detailPerItem, 1e-12));
      // Réponse neutre donnée : même effet de détail, pondéré.
      final both = readHealth(
        const HealthCheck(overall: 4, sleepQuality: 1),
        p,
      );
      expect(both.answered, 2);
      expect(both.shift, closeTo(-p.detailShare * p.detailPerItem, 1e-12));
    });

    test('paliers gradués', () {
      expect(readHealth(const HealthCheck(overall: 5), p).level, 0);
      expect(readHealth(const HealthCheck(overall: 4), p).level, 0);
      expect(readHealth(const HealthCheck(overall: 3), p).level, 0);
      expect(readHealth(const HealthCheck(overall: 2), p).level, 1);
      expect(readHealth(const HealthCheck(overall: 1), p).level, 2);
      final worst = readHealth(
        const HealthCheck(
          overall: 1,
          sleepQuality: 1,
          sleepHours: 2,
          energy: 1,
          mood: 1,
          soreness: 1,
          stress: 1,
          motivation: 1,
          nutrition: 1,
          hydration: 1,
        ),
        p,
      );
      expect(worst.shift, greaterThanOrEqualTo(p.healthFloor));
      expect(worst.level, 2);
      expect(readinessOf(worst.shift, p), inInclusiveRange(0, 1));
    });
  });

  group('modèle de note', () {
    test('notes ordinaires : plein poids', () {
      final r = RatingModel();
      for (var i = 0; i < 40; i++) {
        r.note(i % 3 == 0, p);
      }
      expect(r.weight(p), 1);
    });

    test('confirmations systématiques : le poids tombe au plancher', () {
      final r = RatingModel();
      for (var i = 0; i < 11; i++) {
        r.note(true, p);
      }
      expect(r.weight(p), 1, reason: 'trop peu de séries pour juger');
      for (var i = 0; i < 30; i++) {
        r.note(true, p);
      }
      expect(r.weight(p), p.lazyMinWeight);
      expect(r.window.length, p.lazyWindow);
    });

    test('le bruit croît avec le RIR et avec la longueur de la série', () {
      final r = RatingModel();
      expect(r.rirSd(4, 8, p), greaterThan(r.rirSd(1, 8, p)));
      expect(r.rirSd(2, 25, p), greaterThan(r.rirSd(2, 8, p)));
      expect(r.trueRir(2, p), closeTo(2 * (1 + p.rirBias), 1e-12));
    });
  });

  group('fatigue', () {
    test('une série fatigue ses muscles, puis la fatigue retombe', () {
      final catalog = loadCatalog();
      final book = ExerciseBook(catalog, null);
      ExerciseInfo? squat;
      ExerciseInfo? curl;
      for (final e in catalog.exercises) {
        final info = book.find(e.id)!;
        if (info.mode != CapacityMode.loaded) {
          continue;
        }
        if (e.pattern == MovementPattern.squat) {
          squat ??= info;
        }
        if (e.pattern == MovementPattern.isolationBiceps) {
          curl ??= info;
        }
      }
      final model = FatigueModel(p);
      model.advance(0, p);
      expect(model.rawShift(squat!, p), 0);
      for (var i = 0; i < 5; i++) {
        model.add(squat, effortWeight(1, failed: false));
      }
      final local = model.rawShift(squat, p);
      final other = model.rawShift(curl!, p);
      expect(local, lessThan(0));
      expect(local, lessThan(other), reason: 'fatigue locale');
      model.advance(4, p);
      expect(model.rawShift(squat, p), greaterThan(local));
      model.advance(60, p);
      expect(model.rawShift(squat, p), closeTo(0, 1e-4));
      expect(
        effortWeight(0, failed: true),
        greaterThan(effortWeight(0, failed: false)),
      );
    });
  });

  group('déblocage (D5.7)', () {
    test('rythme : volume, échange, séance, bloc', () {
      expect(unlockLevelFor(0, 0, p), UnlockLevel.loadsReps);
      expect(unlockLevelFor(1, 0, p), UnlockLevel.loadsReps);
      expect(unlockLevelFor(2, 0, p), UnlockLevel.volume);
      expect(unlockLevelFor(3, 0, p), UnlockLevel.volume);
      expect(unlockLevelFor(4, 0, p), UnlockLevel.exerciseSwap);
      expect(unlockLevelFor(30, 0, p), UnlockLevel.exerciseSwap);
      expect(unlockLevelFor(5, 1, p), UnlockLevel.sessionRestructure);
      expect(unlockLevelFor(7, 2, p), UnlockLevel.sessionRestructure);
      expect(unlockLevelFor(8, 2, p), UnlockLevel.blockRestructure);
      expect(unlockLevelFor(3, 2, p), UnlockLevel.volume);
    });

    test('la confiance exigée croît avec le niveau', () {
      var last = 0.0;
      for (final level in UnlockLevel.values) {
        final t = confidenceThreshold(level, p);
        expect(t, greaterThan(last));
        expect(t, lessThan(1));
        last = t;
      }
    });

    test('semaines civiles et jours prévus', () {
      final monday = CivilDate(2026, 10, 5);
      expect(
        weekOfDay(monday.dayNumber),
        weekOfDay(monday.addDays(6).dayNumber),
      );
      expect(
        weekOfDay(monday.addDays(7).dayNumber),
        weekOfDay(monday.dayNumber) + 1,
      );
      final block = programOf('homme_25_musculation_debutant_3x60').block(0);
      for (final d in block.pass1.days) {
        final day = scheduledDay(block.pass1, 1, d.dayIndex);
        expect(CivilDate.fromDayNumber(day).weekday, d.weekday);
        expect(day - block.pass1.startDate.dayNumber, inInclusiveRange(7, 13));
      }
    });
  });

  group('application d\'une proposition', () {
    final block = programOf('homme_25_musculation_debutant_3x60').block(0);
    final item = block.pass2.weeks[1].days[0].items.first;

    Proposal proposal({PlanDiff? diff, ProgramBlock? result}) => Proposal(
      id: 'volume:test@1',
      kind: ProposalKind.volume,
      scope: ProposalScope.exercise,
      createdOn: CivilDate(2026, 10, 11),
      confidence: 0.8,
      unlockLevel: UnlockLevel.volume,
      autoApplicable: true,
      diff: diff,
      block: result,
      reasons: const <Reason>[],
    );

    test('un diff de prescriptions remplace la prescription visée', () {
      final changed = applyProposal(
        block,
        proposal(
          diff: PlanDiff(
            changes: <PlanChange>[
              PlanChange(
                kind: ChangeKind.prescriptionChanged,
                weekIndex: 1,
                dayIndex: 0,
                slotId: item.slotId,
                fromPrescription: item,
                toPrescription: item.copyWith(sets: item.sets + 1),
                reasons: const <Reason>[],
              ),
            ],
          ),
        ),
      );
      expect(changed.validate(), isEmpty);
      expect(changed.pass2.weeks[1].days[0].items.first.sets, item.sets + 1);
      expect(
        changed.pass2.weeks[0].toJson(),
        block.pass2.weeks[0].toJson(),
        reason: 'les autres semaines ne bougent pas',
      );
      expect(changed.pass1, same(block.pass1));
    });

    test('bloc au contrat 0.4.0 : les intentions des semaines restent '
        '(0.2.1)', () {
      final coached = streetProgram('street_08_avance_sets_reps_competition')
          .block(0);
      final target = coached.pass2.weeks[1].days[0].items.first;
      final changed = applyProposal(
        coached,
        proposal(
          diff: PlanDiff(
            changes: <PlanChange>[
              PlanChange(
                kind: ChangeKind.prescriptionChanged,
                weekIndex: 1,
                dayIndex: 0,
                slotId: target.slotId,
                fromPrescription: target,
                toPrescription: target.copyWith(sets: target.sets + 1),
                reasons: const <Reason>[],
              ),
            ],
          ),
        ),
      );
      expect(changed.validate(), isEmpty);
      for (var w = 0; w < coached.pass2.weeks.length; w++) {
        expect(
          changed.pass2.weeks[w].intent,
          coached.pass2.weeks[w].intent,
        );
        expect(changed.pass2.weeks[w].intent, isNotNull);
      }
      expect(
        changed.pass2.weeks[0].toJson(),
        coached.pass2.weeks[0].toJson(),
      );
    });

    test('une restructuration porte son bloc ; sans rien, bloc inchangé', () {
      final other = programOf('femme_45_musculation_salle_4x60').block(0);
      expect(applyProposal(block, proposal(result: other)), same(other));
      expect(applyProposal(block, proposal()), same(block));
      expect(
        applyProposal(
          block,
          proposal(diff: const PlanDiff(changes: <PlanChange>[])),
        ),
        same(block),
      );
    });
  });

  group('athlètes simulés', () {
    test('aller-retour JSON', () {
      for (final a in simAthletes) {
        expect(
          athleteToJson(athleteFromJson(athleteToJson(a))),
          athleteToJson(a),
        );
      }
      expect(simAthletes.length, greaterThanOrEqualTo(6));
      expect(() => athleteOf('inconnu'), throwsArgumentError);
    });

    test('hasard seedé : même clé, même suite', () {
      final a = SimRandom.of(7, 'x');
      final b = SimRandom.of(7, 'x');
      final c = SimRandom.of(8, 'x');
      final va = <double>[for (var i = 0; i < 5; i++) a.gauss()];
      final vb = <double>[for (var i = 0; i < 5; i++) b.gauss()];
      final vc = <double>[for (var i = 0; i < 5; i++) c.gauss()];
      expect(va, vb);
      expect(va, isNot(vc));
    });
  });
}
