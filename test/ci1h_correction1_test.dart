// CI1h correction 1 (dev6.11.3, pipeline CP, DECISIONS_CP.md C15.9) —
// séance future au jour réel, répétitions écrites des lignes à charge fixe.
//
// Défaut A : dev6.11.2 prescrivait une séance future ouverte en avance à sa
// date prévue avec le journal d'aujourd'hui ; les journées d'avant y
// paraissaient passées et manquées, et le moteur reportait leur test
// (« Dead-hang lesté ou PdC ») en tête de la séance. Correction : au jour
// réel ; la prévision de fin de séance, même calcul, même jour.
//
// Défaut B : le squat endurance de S14·J6 servi à 11 répétitions au lieu de
// 14 écrites. Correction : une ligne à charge fixe sert la charge **et** le
// volume écrits (séries, répétitions ou secondes), sauf douleur, bilan du
// jour bas, reprise après coupure ; conseils entre séries inchangés (CI1h).
//
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

bool _isSquat(String name) => name.startsWith('Squat endurance @ 70');

/// Sauvegarde proche de celle du propriétaire (programme commencé le
/// 13/07/2026), journal jusqu'à S[lastWeek]·J[lastJ] ; séries à [rir]
/// répétitions en réserve ; squat endurance à 70 kg × 15, sauf S13·J6 :
/// [s13kg] × [s13reps] à [s13rir] en réserve. B20 = 32 : la ligne écrite
/// vaut round(1,3 × 32 ÷ 3) = 14 répétitions.
Future<void> _owner(
  AppStore app, {
  int lastWeek = 13,
  int lastJ = 6,
  String rir = '3',
  String s13kg = '77.5',
  String s13reps = '14',
  String s13rir = '1',
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
    final s13j6 = e.key == app.sessionKey(13, 6);
    for (final x in ex.entries) {
      final squat = _isSquat('${names?[x.key] ?? ''}');
      for (final s in ((x.value as Map)['sets'] as List)) {
        final m = s as Map;
        m['rir'] = rir;
        if (squat) {
          m['kg'] = s13j6 ? s13kg : '70';
          m['reps'] = s13j6 ? s13reps : '15';
          if (s13j6) m['rir'] = s13rir;
        }
      }
    }
  }
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
  };
  for (final e in refs.entries) {
    pilot.putIfAbsent(e.key, () => e.value);
  }
  pilot['B20'] = 32.0;
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

/// Lignes écrites de la journée S[week]·J[j] (ajustements de Koach compris).
List<kc.ExercisePrescription> _written(AppStore app, int week, int j) =>
    app.adaptPlaceOf(week, j)!.day!.items;

/// Prescription du squat endurance (ligne à 70 kg) de [plan].
kc.ExercisePrescription _squat(AppStore app, kc.SessionPlan plan) =>
    plan.items.firstWhere(
      (it) => app.adaptFixedLoad(14, 6, it.slotId, it.exerciseId) == 70,
    );

String _codes(List<kc.Reason> rs) => [for (final r in rs) r.code].join(',');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppStore app;
  var clock = DateTime(2026, 10, 11, 7);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    clock = DateTime(2026, 10, 11, 7); // dimanche, veille de S14
    app = AppStore()..storeClock = () => clock;
    await app.init();
    debugDisableFixedLoad = false;
  });
  tearDown(() async {
    debugDisableFixedLoad = false;
    await app.flush();
    app.dispose();
  });

  group('défaut A — séance future au jour réel', () {
    test(
      'S14·J6 ouverte le dimanche d’avant (S14·J1 à J5 pas faites) : '
      'ordre et exercices écrits, pas de dead-hang, squat 70 kg × 14',
      () async {
        await _owner(app);
        final base = app.program.week(14).day(6)!;
        final a = app.adaptOpen(14, base)!;
        expect(a.plan.date.iso, '2026-10-11');
        final writtenSlots = [for (final it in _written(app, 14, 6)) it.slotId];
        final servedSlots = [for (final it in a.plan.items) it.slotId];
        // ignore: avoid_print
        print('CI1H1|A|dimanche|écrit=$writtenSlots|servi=$servedSlots');
        expect(servedSlots, writtenSlots);
        final writtenNames = {for (final e in base.exercises) e.name};
        final served = app.adaptDay(14, base, a).exercises;
        for (final e in served) {
          if (e.name.startsWith('Dead-hang')) {
            expect(writtenNames, contains(e.name));
          }
        }
        final squat = _squat(app, a.plan);
        final w = _written(
          app,
          14,
          6,
        ).firstWhere((x) => x.slotId == squat.slotId);
        expect(w.repsLow, 14, reason: 'round(1,3 × 32 ÷ 3)');
        expect(squat.repsLow, 14);
        expect(squat.repsHigh, 14);
        expect(squat.sets, w.sets);
        for (var i = 0; i < squat.sets; i++) {
          expect(planGoal(squat, i).kg, 70);
          expect(planGoal(squat, i).low, 14);
        }
      },
    );

    test('même séance ouverte le samedi avec J4 et J5 réellement manquées : '
        'le report du test reste possible (moteur inchangé le jour même) ; '
        'cause du défaut A', () async {
      await _owner(app, lastWeek: 14, lastJ: 3);
      clock = DateTime(2026, 10, 17, 9); // samedi, S14·J6
      final base = app.program.week(14).day(6)!;
      final a = app.adaptOpen(14, base)!;
      final writtenSlots = {for (final it in _written(app, 14, 6)) it.slotId};
      final extra = [
        for (final it in a.plan.items)
          if (!writtenSlots.contains(it.slotId)) it,
      ];
      final names = [
        for (final e in app.adaptDay(14, base, a).exercises) e.name,
      ];
      // ignore: avoid_print
      print(
        'CI1H1|A|samedi|ajoutés=${[for (final it in extra) '${it.slotId}:${it.exerciseId}:${it.kind?.name}']}|$names',
      );
      expect(extra, isNotEmpty, reason: 'test de J4 reporté par le moteur');
      expect(extra.first.kind, kc.SetKind.test);
      expect(a.plan.items.first.slotId, extra.first.slotId);
      expect(names.first, startsWith('Dead-hang'));
    });

    test('prévision de fin de séance = séance ouverte juste après, même '
        'jour', () async {
      await _owner(app, lastJ: 5);
      clock = DateTime(2026, 10, 10, 19); // samedi soir, S13·J6 finie
      const w = 13, j = 6;
      final base = app.program.week(w).day(j)!;
      final a = app.adaptOpen(w, base)!;
      final day = app.adaptDay(w, base, a);
      for (final e in day.exercises.where((x) => x.engine)) {
        final log = app.exLog(w, j, e);
        app.adaptPrefill(w, j, e, log);
        for (var i = 0; i < log.sets.length; i++) {
          if (log.sets[i].reps.isEmpty) log.sets[i].reps = '8';
          log.sets[i].flames = 7;
          app.toggleSet(log, i, app.logSpec(e));
        }
      }
      app.markSessionDone(w, j, true);
      final s = app.adaptSummary(w, base)!;
      var compared = 0;
      for (final x in s.exercises) {
        if (x.next == null) continue;
        final tb = app.program.week(x.nextWeek!).day(x.nextJ!)!;
        final opened = app.adaptOpen(x.nextWeek!, tb)!;
        expect(opened.plan.date.iso, '2026-10-10');
        final goals = [
          for (final i in opened.plan.items)
            if (i.exerciseId == x.exerciseId)
              (planGoal(i, 0).kg, planGoal(i, 0).low, planGoal(i, 0).high),
        ];
        expect(
          goals,
          contains((x.next!.kg, x.next!.low, x.next!.high)),
          reason: '${x.name} (S${x.nextWeek}·J${x.nextJ})',
        );
        compared++;
      }
      // ignore: avoid_print
      print('CI1H1|A|prevision|$compared');
      expect(compared, greaterThan(0));
    });
  });

  group('défaut B — volume écrit des lignes à charge fixe', () {
    test('cause des 11 répétitions : prescription du moteur seul (journal '
        'proche du propriétaire), au jour réel et à la date prévue', () async {
      for (final (kg, reps, rir) in const [
        ('77.5', '14', '1'),
        ('77.5', '11', '0'),
        ('77.5', '14', '3'),
      ]) {
        await _owner(app, s13kg: kg, s13reps: reps, s13rir: rir);
        final w = _written(app, 14, 6);
        for (final at in [
          DateTime(2026, 10, 11, 7), // dimanche d'avant (jour réel)
          DateTime(2026, 10, 17, 7), // date prévue (calcul de dev6.11.2)
        ]) {
          clock = at;
          debugDisableFixedLoad = true;
          final free = app.adaptPlannedSession(14, 6)!;
          debugDisableFixedLoad = false;
          final f = _squat(app, free);
          final written = w.firstWhere((x) => x.slotId == f.slotId);
          // Ce que servait dev6.11.2 (charge seule, répétitions plafonnées).
          final ci1h = fixedLoadItem(f, 70, written, holdVolume: false);
          final now = _squat(app, app.adaptPlannedSession(14, 6)!);
          // ignore: avoid_print
          print(
            'CI1H1|B|cause|S13J6=$kg×$reps@rir$rir|jour=${at.day}/10'
            '|écrit=${written.sets}×${written.repsLow}-${written.repsHigh}'
            '|moteur=${f.sets}×${f.repsLow}-${f.repsHigh}@${f.startLoadKg}'
            '|raisons=${_codes(f.reasons)}|séance=${_codes(free.reasons)}'
            '|dev6.11.2=${ci1h.sets}×${ci1h.repsLow}@${ci1h.startLoadKg}'
            '|servi=${now.sets}×${now.repsLow}@${now.startLoadKg}',
          );
          if (at.day == 11) {
            expect(
              (now.sets, now.repsLow, now.repsHigh),
              (written.sets, written.repsLow, written.repsHigh),
            );
            expect(now.startLoadKg, 70);
          }
        }
        await app.flush();
        app.dispose();
        SharedPreferences.setMockInitialValues({});
        clock = DateTime(2026, 10, 11, 7);
        app = AppStore()..storeClock = () => clock;
        await app.init();
      }
    });

    test('lignes PdC à charge fixe : répétitions et séries écrites, même '
        'après des séances dures', () async {
      await _owner(app, lastWeek: 14, lastJ: 3, rir: '0');
      clock = DateTime(2026, 10, 15, 9); // jeudi, S14·J4
      final base = app.program.week(14).day(4)!;
      final a = app.adaptOpen(14, base)!;
      final written = {for (final it in _written(app, 14, 4)) it.slotId: it};
      var checked = 0;
      var held = 0;
      for (final it in a.plan.items) {
        final kg = app.adaptFixedLoad(14, 4, it.slotId, it.exerciseId);
        final w = written[it.slotId];
        if (kg != 0 || w == null || it.kind == kc.SetKind.test) continue;
        if (it.reasons.any(fixedVolumeLowered)) continue;
        checked++;
        // ignore: avoid_print
        print(
          'CI1H1|B|pdc|${it.slotId}|écrit=${w.sets}×${w.repsLow ?? w.secondsLow}'
          '|servi=${it.sets}×${it.repsLow ?? it.secondsLow}',
        );
        expect(
          (it.sets, it.repsLow, it.repsHigh, it.secondsLow, it.secondsHigh),
          (w.sets, w.repsLow, w.repsHigh, w.secondsLow, w.secondsHigh),
          reason: it.slotId,
        );
        for (var i = 0; i < it.sets; i++) {
          final g = planGoal(it, i);
          expect(g.kg == null || g.kg == 0, isTrue, reason: it.slotId);
        }
        held++;
      }
      expect(checked, greaterThan(0));
      expect(held, checked);
    });

    test('règle pure : douleur, bilan bas, reprise après coupure baissent ; '
        'sinon volume écrit', () {
      const written = kc.ExercisePrescription(
        slotId: 'j6-squat',
        exerciseId: 'squat',
        sets: 3,
        repsLow: 14,
        repsHigh: 14,
        targetFlames: 5,
        startLoadKg: 70,
        toCalibrate: false,
        loadBasis: kc.LoadBasis.external,
        reasons: <kc.Reason>[],
      );
      final engine = written.copyWith(
        sets: 2,
        repsLow: 11,
        repsHigh: 11,
        startLoadKg: 77.5,
        reasons: const [kc.Reason(code: 'adapt.reps_down', params: {})],
      );
      final plain = fixedLoadItem(engine, 70, written);
      expect(
        (plain.sets, plain.repsLow, plain.repsHigh, plain.startLoadKg),
        (3, 14, 14, 70.0),
      );
      expect(plain.reasons.any((r) => r.code == 'adapt.reps_down'), isFalse);
      expect(plain.validate(), isEmpty);
      for (final r in const [
        kc.Reason(code: 'adapt.pain_reported', params: {'zone': 'knee'}),
        kc.Reason(code: 'adapt.health_low', params: {'overall': 1}),
        kc.Reason(code: 'adapt.sleep_low', params: {'sleepQuality': 1}),
        kc.Reason(code: 'adapt.resume_after_break', params: {'days': 10}),
        kc.Reason(code: 'adapt.load_held', params: {'cause': 'health'}),
      ]) {
        final low = fixedLoadItem(engine.copyWith(reasons: [r]), 70, written);
        expect((low.sets, low.repsLow), (2, 11), reason: r.code);
      }
      // Douleur posée sur un ajustement de l'exercice seulement (étape 2 bis
      // du moteur) : la baisse reste.
      final adj = fixedLoadItem(
        engine.copyWith(reasons: const []),
        70,
        written,
        adjustmentReasons: const [
          kc.Reason(code: 'adapt.pain_reported', params: {'zone': 'knee'}),
        ],
      );
      expect((adj.sets, adj.repsLow), (2, 11));
      // Conduite d'endurance pour une douleur de jambe : la baisse reste.
      final leg = fixedLoadItem(
        engine.copyWith(
          reasons: const [
            kc.Reason(
              code: 'adapt.endurance_shortened',
              params: {'cause': 'leg_pain'},
            ),
          ],
        ),
        70,
        written,
      );
      expect((leg.sets, leg.repsLow), (2, 11));
      final session = fixedLoadItem(engine, 70, written, sessionLowered: true);
      expect(
        (session.sets, session.repsLow, session.startLoadKg),
        (2, 11, 70.0),
      );
      // Jamais au-delà de la ligne écrite, même quand le moteur baisse.
      final over = fixedLoadItem(
        engine.copyWith(
          repsLow: 16,
          repsHigh: 18,
          reasons: const [
            kc.Reason(code: 'adapt.health_low', params: {'overall': 1}),
          ],
        ),
        70,
        written,
      );
      expect((over.repsLow, over.repsHigh), (14, 14));
    });

    test('dernière séance il y a 8 jours (sans réduction du moteur) : '
        'volume écrit tenu', () async {
      await _owner(app, lastWeek: 12, lastJ: 6, s13kg: '70', s13reps: '15');
      final base = app.program.week(14).day(6)!;
      final a = app.adaptOpen(14, base)!;
      final squat = _squat(app, a.plan);
      final w = _written(
        app,
        14,
        6,
      ).firstWhere((x) => x.slotId == squat.slotId);
      // ignore: avoid_print
      print(
        'CI1H1|B|coupure8|${squat.sets}×${squat.repsLow}@${squat.startLoadKg}'
        '|raisons=${_codes(squat.reasons)}|séance=${_codes(a.plan.reasons)}',
      );
      expect(
        (squat.sets, squat.repsLow, squat.repsHigh),
        (w.sets, w.repsLow, w.repsHigh),
      );
    });

    test('bilan bas : le volume du squat peut baisser, charge 70', () async {
      await _owner(app);
      final base = app.program.week(14).day(6)!;
      app.adaptOpen(14, base);
      final a = app.adaptAnswer(
        14,
        base,
        const kc.HealthCheck(overall: 1, sleepQuality: 1),
      )!;
      final squat = _squat(app, a.active);
      final w = _written(
        app,
        14,
        6,
      ).firstWhere((x) => x.slotId == squat.slotId);
      // ignore: avoid_print
      print(
        'CI1H1|B|bilan_bas|${squat.sets}×${squat.repsLow}@${squat.startLoadKg}'
        '|écrit=${w.sets}×${w.repsLow}|séance=${_codes(a.active.reasons)}',
      );
      expect(a.active.reasons.any(fixedVolumeLowered), isTrue);
      expect(squat.sets, lessThanOrEqualTo(w.sets));
      expect(squat.repsLow!, lessThanOrEqualTo(14));
      for (var i = 0; i < squat.sets; i++) {
        expect(planGoal(squat, i).kg, 70);
      }
    });
  });
}
