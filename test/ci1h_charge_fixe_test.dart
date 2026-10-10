// CI1h (dev6.11.2, pipeline CP, DECISIONS_CP.md C15) — charge fixe du
// programme et prévision de fin de séance.
//
// Défaut 1 : une ligne du programme de 40 semaines à charge écrite fixe
// (« Squat endurance @ 70 kg », 0 kg de lest d'une ligne au poids du corps)
// est servie à sa charge écrite à chaque série, dans les conseils entre
// séries et dans la prévision ; seules les répétitions bougent ; la
// conduite sous douleur s'applique quand même ; « Dead-hang lesté ou PdC »
// reste libre.
//
// Défaut 2 : la prévision de fin de séance (« La prochaine fois ») et
// l'ouverture d'une séance non commencée passent par le même calcul ; une
// séance future ouverte en avance est prescrite à sa date prévue.
//
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_summary_screen.dart'
    show summaryTargetText;
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

bool _isSquat(String name) => name.startsWith('Squat endurance @ 70');

/// Sauvegarde du propriétaire (programme commencé le 13/07/2026), journal
/// jusqu'à S[lastWeek]·J[lastJ], séries « faciles » : 4 répétitions en
/// réserve partout ; squat endurance à 70 kg × 15.
Future<void> _ownerEasy(
  AppStore app, {
  int lastWeek = 13,
  int lastJ = 4,
}) async {
  final b = filledBackup(app);
  final logs = (b['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ);
  });
  for (final e in logs.entries) {
    final log = (e.value as Map).cast<String, dynamic>();
    final names = (log['exerciseNames'] as Map?)?.cast<String, dynamic>();
    final ex = (log['ex'] as Map).cast<String, dynamic>();
    for (final x in ex.entries) {
      final squat = _isSquat('${names?[x.key] ?? ''}');
      for (final s in ((x.value as Map)['sets'] as List)) {
        final m = s as Map;
        m['rir'] = '4';
        if (squat) {
          m['kg'] = '70';
          m['reps'] = '15';
        }
      }
    }
  }
  // Références du Pilotage du propriétaire (maximums de répétitions,
  // 1RM) : lignes « N × (coef × réf.) reps » portées au moteur.
  final pilot = (b['pilotage'] as Map).cast<String, dynamic>();
  const refs = {
    'B4': 71.5,
    'B8': 55.0,
    'B9': 75.0,
    'B10': 15.0,
    'B11': 120.0,
    'B16': 10.0,
    'B17': 30.0,
    'B18': 70.0,
    'B19': 65.0,
    'B20': 35.0,
  };
  for (final e in refs.entries) {
    pilot.putIfAbsent(e.key, () => e.value);
  }
  b['pilotage'] = pilot;
  b['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(b)), isTrue);
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(
        on: civilOf(app.storeClock()),
        guidance: kc.GuidanceMode.assisted,
      ),
    )..consent = 'refused',
  );
}

/// Exercice servi dont le nom commence par [prefix].
Exercise _served(AppStore app, int week, int j, String prefix) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  return app
      .adaptDay(week, base, a)
      .exercises
      .firstWhere((e) => e.name.startsWith(prefix));
}

/// Charges de toutes les séries d'une prescription.
List<double?> _loads(kc.ExercisePrescription it) => [
  for (var i = 0; i < it.sets; i++) planGoal(it, i).kg,
];

/// Valide la série [i] de [e] avec [reps] et [flames], puis le conseil.
void _validate(
  AppStore app,
  int week,
  int j,
  Exercise e,
  int i,
  String reps,
  int flames,
) {
  final base = app.program.week(week).day(j)!;
  final a = app.sessionAdapt(week, j)!;
  final day = app.adaptDay(week, base, a);
  final log = app.exLog(week, j, e);
  app.adaptPrefill(week, j, e, log);
  log.sets[i].reps = reps;
  log.sets[i].flames = flames;
  expect(app.toggleSet(log, i, app.logSpec(e)).ok, isTrue);
  app.adaptAfterSet(week, day, e, i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 9, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 10, 9, 9); // vendredi, S13·J5
    app = AppStore()..storeClock = () => clock;
    await app.init();
    debugDisableFixedLoad = false;
  });
  tearDown(() async {
    debugDisableFixedLoad = false;
    await app.flush();
    app.dispose();
  });

  group('défaut 1 — charge fixe', () {
    test('inventaire : lignes à charge fixe du programme de 40 semaines, '
        'exception « lesté ou PdC »', () async {
      await _ownerEasy(app);
      final imp = app.importedProgram!;
      var written = 0;
      var choice = 0;
      final byName = <String, (int, double, int)>{};
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          for (final e in d.original.exercises) {
            if (e.load.type != 'fixed') continue;
            written++;
            final kg = importedFixedLoadKg(e);
            if (kg == null) {
              choice++;
              expect(e.name, contains(' ou '));
              continue;
            }
            final slot = imp.slotOf(w.n, d.j, e.id);
            final locked =
                slot != null && imp.fixedLoad['${w.n}|$slot'] != null;
            final x = byName[e.name] ?? (0, kg, 0);
            byName[e.name] = (x.$1 + 1, kg, x.$3 + (locked ? 1 : 0));
          }
        }
      }
      expect(written, 693);
      expect(choice, 34); // « Dead-hang lesté ou PdC »
      expect(byName['Squat endurance @ 70 kg'], (33, 70.0, 33));
      expect(byName['TEST MAX SQUAT @ 70 kg']!.$2, 70.0);
      for (final e in byName.entries) {
        // CI1H| : relevé pour la livraison (ligne, nombre, charge, portées).
        // ignore: avoid_print
        print('CI1H|ligne|${e.key}|${e.value.$1}|${e.value.$2}|${e.value.$3}');
      }
    });

    test('S14·J6 : squat endurance servi à 70 kg (sans la contrainte : '
        'plus lourd, cause confirmée)', () async {
      await _ownerEasy(app, lastJ: 6);
      clock = DateTime(2026, 10, 17, 9); // samedi, S14·J6
      final base = app.program.week(14).day(6)!;
      debugDisableFixedLoad = true;
      final free = app.adaptPlannedSession(14, 6)!;
      final freeSquat = free.items.firstWhere(
        (it) => app.adaptFixedLoad(14, 6, it.slotId, it.exerciseId) == 70,
      );
      // ignore: avoid_print
      print('CI1H|avant|S14J6|squat|${_loads(freeSquat)}|${freeSquat.repsLow}');
      expect(
        _loads(freeSquat).any((kg) => kg != 70),
        isTrue,
        reason: 'le moteur seul règle la charge pour tenir le RIR',
      );
      debugDisableFixedLoad = false;
      expect(app.adaptOpen(14, base), isNotNull);
      final e = _served(app, 14, 6, 'Squat endurance');
      final it = app.adaptItemFor(14, 6, e)!;
      // ignore: avoid_print
      print('CI1H|apres|S14J6|squat|${_loads(it)}|${it.repsLow}');
      expect(_loads(it), everyElement(70.0));
      expect(it.repsHigh, lessThanOrEqualTo(freeSquat.repsHigh!));
      expect(
        it.reasons.any(
          (r) => r.code == 'adapt.load_held' && r.params['cause'] == 'program',
        ),
        isTrue,
      );
      expect(
        adaptReasonText(it.reasons.last),
        'Charge fixée par ton programme : je règle seulement les '
        'répétitions.',
      );

      // Série facile : rien ne change, charge 70 pour la suite.
      final low = app.adaptGoal(14, 6, e, 0)!.low!;
      _validate(app, 14, 6, e, 0, '${low + 3}', 2);
      expect(app.adaptGoal(14, 6, e, 1)!.kg, 70);
      expect(app.adaptGoal(14, 6, e, 1)!.low, low);
      expect(app.exLog(14, 6, e).sets[1].kg, adaptKgField(70));
      // Série trop dure (répétitions manquées) : répétitions abaissées,
      // jamais sous la moitié de la cible ; charge 70.
      _validate(app, 14, 6, e, 1, '${low - 2}', 10);
      final g2 = app.adaptGoal(14, 6, e, 2)!;
      expect(g2.kg, 70);
      expect(g2.low, low - 2);
      expect(g2.low, greaterThanOrEqualTo((low / 2).ceil()));
    });

    test('série très dure : jamais sous la moitié de la cible', () {
      const it = kc.ExercisePrescription(
        slotId: 'j6-squat',
        exerciseId: 'squat',
        sets: 3,
        repsLow: 15,
        repsHigh: 15,
        targetFlames: 5,
        startLoadKg: 70,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.external,
        reasons: <kc.Reason>[],
      );
      const up = kc.IntraSessionAdvice(
        exerciseId: 'squat',
        action: kc.IntraSessionAction.loadUp,
        nextLoadKg: 77.5,
        nextRepsLow: 15,
        nextRepsHigh: 15,
        confidence: .8,
        reasons: <kc.Reason>[],
      );
      final g = planGoal(it, 0);
      SetGoal? n() => planGoal(it, 1);
      // Facile : rien (pas de hausse de charge ni de répétitions).
      final easy = fixedLoadAdvice(
        up,
        item: it,
        kg: 70,
        goal: g,
        done: 20,
        flames: 1,
        next: n(),
        planned: n(),
      );
      expect(easy.action, kc.IntraSessionAction.keep);
      expect(easy.nextLoadKg, isNull);
      // Manquée de loin : la moitié de la cible.
      final hard = fixedLoadAdvice(
        up,
        item: it,
        kg: 70,
        goal: g,
        done: 3,
        flames: 10,
        next: n(),
        planned: n(),
      );
      expect(hard.action, kc.IntraSessionAction.repsDown);
      expect(hard.nextLoadKg, 70);
      expect(hard.nextRepsLow, 8);
      // Plus dure que prévu (2 répétitions en réserve de moins) : -2.
      final rir = fixedLoadAdvice(
        up,
        item: it,
        kg: 70,
        goal: g,
        done: 15,
        flames: 9,
        next: n(),
        planned: n(),
      );
      expect(rir.nextRepsLow, 13);
      expect(rir.nextLoadKg, 70);
      // Douleur : le conseil du moteur passe (allègement compris).
      const pain = kc.IntraSessionAdvice(
        exerciseId: 'squat',
        action: kc.IntraSessionAction.loadDown,
        nextLoadKg: 50,
        confidence: .8,
        reasons: [
          kc.Reason(code: 'adapt.pain_reported', params: {'zone': 'knee'}),
        ],
      );
      expect(
        fixedLoadAdvice(
          pain,
          item: it,
          kg: 70,
          goal: g,
          done: 15,
          flames: 5,
          next: n(),
          planned: n(),
        ).nextLoadKg,
        50,
      );
      // Prescription : charge écrite, répétitions dans la ligne.
      final served = fixedLoadItem(
        it.copyWith(startLoadKg: 77.5, repsLow: 16, repsHigh: 18),
        70,
        it,
      );
      expect(served.startLoadKg, 70);
      expect(served.repsHigh, 15);
      expect(served.repsLow, 15);
      // Allègement d'une douleur : gardé.
      final hurt = fixedLoadItem(
        it.copyWith(
          startLoadKg: 50.0,
          reasons: const [
            kc.Reason(code: 'adapt.pain_reported', params: {'zone': 'knee'}),
          ],
        ),
        70,
        it,
      );
      expect(hurt.startLoadKg, 50);
    });

    test('ligne PdC à charge fixe : jamais de lest, même facile', () async {
      await _ownerEasy(app);
      clock = DateTime(2026, 10, 15, 9); // jeudi, S14·J4
      final base = app.program.week(14).day(4)!;
      final a = app.adaptOpen(14, base)!;
      final day = app.adaptDay(14, base, a);
      final pdc = <Exercise>[];
      for (final e in day.exercises.where((x) => x.engine)) {
        final it = app.adaptItemFor(14, 4, e);
        if (it == null) continue;
        if (app.adaptFixedLoad(14, 4, it.slotId, it.exerciseId) != 0) continue;
        pdc.add(e);
        for (final kg in _loads(it)) {
          expect(kg == null || kg == 0, isTrue, reason: e.name);
        }
      }
      expect(pdc, isNotEmpty);
      final e = pdc.firstWhere(
        (x) => app.adaptItemFor(14, 4, x)!.sets > 1,
        orElse: () => pdc.first,
      );
      final it = app.adaptItemFor(14, 4, e)!;
      final g = planGoal(it, 0);
      _validate(app, 14, 4, e, 0, '${(g.low ?? g.high ?? 5) + 5}', 1);
      for (var i = 1; i < it.sets; i++) {
        final kg = app.adaptGoal(14, 4, e, i)?.kg;
        expect(kg == null || kg == 0, isTrue, reason: e.name);
      }
      // ignore: avoid_print
      print('CI1H|pdc|S14J4|${[for (final x in pdc) x.name]}');
    });

    test(
      'douleur au-dessus du seuil : conduite sous douleur appliquée',
      () async {
        await _ownerEasy(app, lastJ: 6);
        clock = DateTime(2026, 10, 17, 9);
        final base = app.program.week(14).day(6)!;
        app.adaptOpen(14, base);
        final e = _served(app, 14, 6, 'Squat endurance');
        final slot = e.slotId!;
        final squatId = app.adaptItemFor(14, 6, e)!.exerciseId;
        final a = app.adaptAnswer(
          14,
          base,
          const kc.HealthCheck(
            pains: [
              kc.PainReport(
                zone: kc.BodyZone.knee,
                side: kc.BodySide.both,
                intensity: 7,
                phase: kc.PainPhase.before,
              ),
            ],
          ),
        )!;
        final items = a.active.items.where((x) => x.slotId == slot).toList();
        bool painReason(kc.Reason r) =>
            r.code.startsWith('adapt.pain') ||
            (r.code == 'adapt.load_held' &&
                '${r.params['cause']}'.startsWith('pain'));
        // ignore: avoid_print
        print(
          'CI1H|douleur|S14J6|${[for (final it in items) '${it.exerciseId}:${_loads(it)}:${it.reasons.map((r) => r.code).toList()}']}',
        );
        final applied =
            items.isEmpty ||
            items.first.exerciseId != squatId ||
            items.first.reasons.any(painReason) ||
            a.active.reasons.any(painReason);
        expect(applied, isTrue);
        for (final it in items) {
          for (final kg in _loads(it)) {
            expect(kg == null || kg <= 70, isTrue);
          }
        }
      },
    );

    test('« Dead-hang lesté ou PdC » : non verrouillée', () async {
      await _ownerEasy(app);
      final imp = app.importedProgram!;
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          for (final e in d.original.exercises) {
            if (!e.name.startsWith('Dead-hang lesté ou PdC')) continue;
            expect(importedFixedLoadKg(e), isNull);
            final slot = imp.slotOf(w.n, d.j, e.id);
            if (slot != null) {
              expect(imp.fixedLoad['${w.n}|$slot'], isNull);
            }
          }
        }
      }
    });

    for (final (from, to) in const [
      (1, 7),
      (8, 13),
      (14, 19),
      (20, 25),
      (26, 31),
      (32, 36),
      (37, 40),
    ]) {
      test('contrôle global S$from-S$to : journal facile, aucune série '
          'd’une ligne verrouillée hors de sa charge écrite', () async {
        await _ownerEasy(app);
        final imp = app.importedProgram!;
        var checked = 0;
        var off = 0;
        for (var n = from; n <= to; n++) {
          for (final d in app.program.week(n).days) {
            if (d.exercises.isEmpty) continue;
            final plan = app.adaptPlannedSession(n, d.j);
            if (plan == null) continue;
            for (final it in plan.items) {
              final f = imp.fixedLoad['$n|${it.slotId}'];
              if (f == null || f.$1 != it.exerciseId) continue;
              checked++;
              final loaded = fixedLoadApplies(it, f.$2);
              for (final kg in _loads(it)) {
                final ok = loaded && f.$2 > 0
                    ? kg == f.$2
                    : (kg == null || kg == 0);
                if (!ok) off++;
              }
            }
          }
        }
        // ignore: avoid_print
        print('CI1H|global|S$from-S$to|$checked|$off');
        expect(checked, greaterThan(0));
        expect(off, 0);
      });
    }
  });

  group('défaut 2 — prévision de fin de séance', () {
    test('prévision égale à la séance ouverte juste après (S13·J6 → S14, '
        'dont S14·J6 ; S14·J4 → S14·J5…)', () async {
      await _ownerEasy(app, lastJ: 5);
      for (final (w, j) in const [(13, 6), (14, 4), (14, 5)]) {
        clock = app.program.dateFor(w, j).add(const Duration(hours: 18));
        final base = app.program.week(w).day(j)!;
        final a = app.adaptOpen(w, base)!;
        final day = app.adaptDay(w, base, a);
        for (final e in day.exercises.where((x) => x.engine)) {
          final log = app.exLog(w, j, e);
          app.adaptPrefill(w, j, e, log);
          for (var i = 0; i < log.sets.length; i++) {
            if (log.sets[i].reps.isEmpty) log.sets[i].reps = '8';
            log.sets[i].flames = 4;
            app.toggleSet(log, i, app.logSpec(e));
          }
        }
        app.markSessionDone(w, j, true);
        final s = app.adaptSummary(w, base)!;
        final next = [
          for (final x in s.exercises)
            if (x.next != null) x,
        ];
        expect(next, isNotEmpty);
        var compared = 0;
        for (final x in next) {
          expect(x.nextWeek, isNotNull);
          expect(x.nextDate, app.program.dateFor(x.nextWeek!, x.nextJ!));
          final key = app.sessionKey(x.nextWeek!, x.nextJ!);
          final had = app.logs.containsKey(key);
          final tb = app.program.week(x.nextWeek!).day(x.nextJ!)!;
          final opened = app.adaptOpen(x.nextWeek!, tb)!;
          final it = opened.plan.items.firstWhere(
            (i) => i.exerciseId == x.exerciseId,
          );
          final g = planGoal(it, 0);
          expect(
            (g.kg, g.low, g.high),
            (x.next!.kg, x.next!.low, x.next!.high),
            reason: '${x.name} (S${x.nextWeek}·J${x.nextJ})',
          );
          compared++;
          if (!had) app.logs.remove(key);
        }
        // ignore: avoid_print
        print('CI1H|prevision|S${w}J$j|$compared');
        if (w == 13 && j == 6) {
          final squatId = _served(app, 13, 6, 'Squat endurance').catalogId;
          final squat = next.firstWhere((x) => x.exerciseId == squatId);
          expect((squat.nextWeek, squat.nextJ), (14, 6));
          expect(squat.next!.kg, 70);
        }
      }
    });

    test('séance future ouverte la veille puis le jour même : recalculée ; '
        'prescrite à sa date prévue', () async {
      await _ownerEasy(app, lastJ: 6);
      final base = app.program.week(14).day(6)!;
      clock = DateTime(2026, 10, 16, 20); // la veille
      final eve = app.adaptOpen(14, base)!;
      expect(eve.date, '2026-10-16');
      expect(app.adaptPlanDay(14, 6).iso, '2026-10-17');
      expect(eve.plan.toJson(), app.adaptPlannedSession(14, 6)!.toJson());
      clock = DateTime(2026, 10, 17, 9); // le jour même
      final day = app.adaptOpen(14, base)!;
      expect(day.date, '2026-10-17');
      expect(app.adaptPlanDay(14, 6).iso, '2026-10-17');
      expect(day.plan.toJson(), app.adaptPlannedSession(14, 6)!.toJson());
    });

    test('fin de séance : séance visée et date', () {
      final e = AdaptExerciseSummary(
        exerciseId: 'squat',
        name: 'Squat endurance',
        calibrating: false,
        next: const SetGoal(kg: 70, low: 15, high: 15),
        nextWeek: 14,
        nextJ: 6,
        nextDate: DateTime(2026, 10, 17),
      );
      expect(summaryTargetText(e), ' — S14 · J6, samedi 17/10');
    });
  });
}
