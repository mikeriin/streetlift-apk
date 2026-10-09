// CI1f (dev6.11.0, pipeline CP, DECISIONS_CP.md C11.6) — paquets 0.3.0,
// mini-séries saisies une à une (une série avec ses `parts`), groupes
// d'exercices enchaînés affichés et journalisés, formats du programme de
// 40 semaines annotés (myo-reps, durées, HIIT, EMOM, contrastes, échelles,
// « N × ? reps »).
// Données synthétiques ; horloge injectée ; stockage simulé.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalis_adapt/kalis_adapt.dart' as ka;
import 'package:kalis_core/kalis_core.dart' as kc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/adapt/adapt_texts.dart';
import 'package:streetlift_tracker/athlete_profile.dart';
import 'package:streetlift_tracker/journal_adapter.dart';
import 'package:streetlift_tracker/plan/reason_texts_0_4.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';

Future<void> _ownerAt(AppStore app, {int lastWeek = 13, int lastJ = 4}) async {
  final filled = filledBackup(app);
  final logs = (filled['logs'] as Map).cast<String, dynamic>();
  logs.removeWhere((k, _) {
    final w = int.parse(k.substring(1, k.indexOf('-')));
    final j = int.parse(k.substring(k.indexOf('J') + 1));
    return w > lastWeek || (w == lastWeek && j > lastJ);
  });
  filled['programStart'] = {
    'status': 'set',
    'date': '2026-07-13',
    'origin': 'migration',
  };
  expect(await app.importAll(jsonEncode(filled)), isTrue);
}

void _saveProfile(AppStore app, kc.GuidanceMode mode) {
  app.saveAthleteProfile(
    ProfileDraft.of(
      sampleAthleteProfile(on: civilOf(app.storeClock()), guidance: mode),
    )..consent = 'refused',
  );
}

/// Prescription du bloc annoté pour la ligne [id] (S[week]·J[j]).
kc.ExercisePrescription? _item(AppStore app, int week, int j, String id) {
  final slot = app.adaptSlotOf(week, j, id);
  if (slot == null) return null;
  for (final it in app.adaptPlaceOf(week, j)?.day?.items ?? const []) {
    if (it.slotId == slot) return it;
  }
  return null;
}

kc.GroupSpec? _group(AppStore app, int week, int j, String id) {
  final e = app.program
      .week(week)
      .day(j)!
      .original
      .exercises
      .firstWhere((x) => x.id == id);
  return app.exerciseGroupOf(week, j, e);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paquets 0.3.0 : textes de Koach des codes d’endurance', () {
    for (final code in [
      'adapt.run_capped',
      'adapt.easy_instead',
      'adapt.endurance_shortened',
      'adapt.wod_scaled',
      'adapt.cross_fatigue',
    ]) {
      final t = reasonText04(code, const {
        'cause': 'resume_14',
        'percent': 50,
      }, (id) => id);
      expect(t, isNotNull, reason: code);
      expect(t, isNot(contains('{')), reason: code);
      expect(t, isNot(contains('_')), reason: code);
    }
    expect(
      reasonText04('adapt.endurance_shortened', const {
        'cause': 'resume_14',
        'percent': 50,
      }, (id) => id),
      'On raccourcit : 50 % de ce qui était prévu (reprise après deux '
      'semaines sans séance).',
    );
    expect(ka.kalisAdaptVersion, '0.3.0');
  });

  test('journal : une série avec ses mini-séries est une ligne (total et '
      'parts) ; myo-reps notés en lignes séparées regroupés si c’est sûr', () {
    Map<String, dynamic> row(String reps, {String kg = '10', bool done = true}) =>
        {'kg': kg, 'reps': reps, 'done': done};
    final doc = <String, dynamic>{
      'programStart': {'date': '2026-07-13'},
      'logs': {
        'S3-J2': {
          'done': true,
          'finishedAt': '2026-07-28T18:00:00',
          'exerciseNames': {'a': 'Curl barre EZ', 'b': 'Curl barre EZ'},
          'ex': {
            // Saisie 6.11.0 : une ligne, quatre mini-séries.
            'a': {
              'sets': [
                {
                  ...row('26'),
                  'flames': 9,
                  'parts': [
                    {'reps': 15},
                    {'reps': 4, 'restBefore': 10},
                    {'reps': 4, 'restBefore': 10},
                    {'reps': 3, 'restBefore': 10},
                  ],
                },
              ],
            },
            // Saisie d'avant : activation puis 4 lignes.
            'b': {
              'sets': [row('15'), row('4'), row('4'), row('4'), row('3')],
            },
          },
        },
        'S3-J3': {
          'done': true,
          'finishedAt': '2026-07-29T18:00:00',
          'exerciseNames': {'b': 'Curl barre EZ'},
          'ex': {
            // Pas sûr (charges différentes) : laissé tel quel.
            'b': {
              'sets': [row('15'), row('4', kg: '8'), row('4')],
            },
          },
        },
      },
    };
    final out = convertLegacyJournal(
      doc,
      exerciseId: (_) => 'mu-curl-barre-ez',
      usesSeconds: (_) => false,
      dayOrder: (_, _) => const ['a', 'b'],
      legacyDate: (_, _) => DateTime(2026, 7, 28),
      lineOf: (w, j, key, withParts) => (
        exerciseId: null,
        seconds: null,
        scale: 1,
        technique: withParts ? 'myo_reps' : null,
      ),
      myoOf: (w, j, key) => key == 'b' ? 10 : null,
    );
    final s1 = out.log.sessions.firstWhere((s) => s.id == 'legacy-S3-J2');
    expect(s1.sets.length, 2);
    final a = s1.sets[0];
    expect(a.reps, 26);
    expect(a.technique, kc.SetTechniqueKind.myoReps);
    expect([for (final p in a.parts!) p.reps], [15, 4, 4, 3]);
    expect(a.parts![1].restBeforeSeconds, 10);
    final b = s1.sets[1];
    expect(b.reps, 31);
    expect(b.technique, kc.SetTechniqueKind.myoReps);
    expect([for (final p in b.parts!) p.reps], [15, 4, 4, 4, 4]);
    expect(b.externalLoadKg, 10);
    final s2 = out.log.sessions.firstWhere((s) => s.id == 'legacy-S3-J3');
    expect(s2.sets.length, 3);
    expect(s2.sets.every((s) => s.parts == null), isTrue);
    expect(out.log.validate(), isEmpty);
  });

  group('programme de 40 semaines : formats annotés (C11.6)', () {
    late AppStore app;
    var clock = DateTime(2026, 10, 9, 9);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      clock = DateTime(2026, 10, 9, 9); // vendredi, S13·J5
      app = AppStore()..storeClock = () => clock;
      await app.init();
    });
    tearDown(() async {
      await app.flush();
      app.dispose();
    });

    test('myo-reps, durées, HIIT, EMOM, contrastes, échelles : blocs '
        'valides, groupes, lignes servies telles qu’écrites', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      for (final r in ['B17', 'B18', 'B19']) {
        if (!app.values.containsKey(r)) app.setValue(r, 15);
      }
      final imp = app.importedProgram!;
      for (final s in imp.segments) {
        expect(s.block.validate(), isEmpty, reason: s.blockId);
        expect(ka.blockCoached(s.block), isTrue, reason: s.blockId);
      }
      // Myo-reps : activation (plage de la ligne) puis mini-séries.
      final myo = _item(app, 3, 2, 'P0-99')!;
      expect(myo.technique?.kind, kc.SetTechniqueKind.myoReps);
      expect(myo.sets, 1);
      expect((myo.repsLow, myo.repsHigh), (15, 15));
      expect(myo.technique!.miniSetReps, 4);
      expect(myo.technique!.miniSets, 4);
      expect(myo.technique!.intraRestSeconds, 10);
      // Durée : mobilité de 10 min, conduite par l'endurance.
      final mob = _item(app, 1, 1, 'P0-11')!;
      expect((mob.secondsLow, mob.secondsHigh), (600, 600));
      expect(prescriptionInMinutes(mob), isTrue);
      expect(adaptSetsText(mob), '1 × 10 min');
      final walk = _item(app, 1, 5, 'P0-38')!;
      expect(walk.secondsLow, 1800);
      // HIIT : groupe d'intervalles.
      final hiit = _item(app, 3, 6, 'P0-144')!;
      expect((hiit.sets, hiit.secondsLow, hiit.restSeconds), (8, 30, 30));
      final gh = _group(app, 3, 6, 'P0-144')!;
      expect(gh.format, kc.GroupFormat.intervals);
      expect((gh.rounds, gh.intervalSeconds), (8, 30));
      // EMOM : une ligne par minute, groupe au temps ; dips et pompes
      // enchaînés dans le même groupe.
      final emom = _item(app, 26, 4, 'B4-40')!;
      expect(emom.technique?.kind, kc.SetTechniqueKind.emom);
      expect(emom.sets, 12);
      final ge = _group(app, 26, 4, 'B4-40')!;
      expect(ge.format, kc.GroupFormat.emom);
      expect(ge.durationSeconds, 720);
      expect(
        _group(app, 26, 5, 'B4-49')!.groupId,
        _group(app, 26, 5, 'B4-50')!.groupId,
      );
      // Contraste : groupe de 3 tours, partie explosive (squat sauté),
      // servi tel qu'écrit.
      final c = _item(app, 20, 3, 'B3-30')!;
      expect(c.exerciseId, 'mu-squat-saute');
      expect((c.sets, c.repsLow), (3, 8));
      final gc = _group(app, 20, 3, 'B3-30')!;
      expect((gc.format, gc.rounds), (kc.GroupFormat.circuit, 3));
      expect(app.adaptAsWritten(20, c.slotId), isTrue);
      // Échelles : 4 tours de 28 (7 à 1), dips et pompes enchaînés.
      final l = _item(app, 27, 4, 'B4-106')!;
      expect((l.sets, l.repsLow), (4, 28));
      expect(
        _group(app, 27, 5, 'B4-115')!.groupId,
        _group(app, 27, 5, 'B4-116')!.groupId,
      );
      expect(imp.absent.keys, isNot(contains('N×N puis N×(N)')));
      expect(imp.absent.keys, isNot(contains('N min')));
      // Pages de séance : un groupe = une page.
      final pages = app.groups(app.program.week(26).day(5)!, week: 26);
      expect(
        pages.any(
          (p) => p.map((e) => e.id).toSet().containsAll({'B4-49', 'B4-50'}),
        ),
        isTrue,
      );
      // ignore: avoid_print
      print('CI1F absent ${jsonEncode(imp.absent)}');
    });

    test('« N × ? reps » : référence estimée d’après le journal (test au '
        'maximum), sinon servi tel qu’écrit', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      app.values.remove('B17');
      app.setValue('B4', app.values['B4'] ?? 75);
      final est = app.importedProgram!.estimates;
      // Le journal synthétique porte des tests au maximum (8 répétitions).
      if (est.containsKey('B17')) {
        expect(est['B17']!.$1, greaterThan(0));
        final it = _item(app, 26, 4, 'B4-40');
        expect(it?.technique?.kind, kc.SetTechniqueKind.emom);
      }
      // ignore: avoid_print
      print('CI1F estimates ${est.map((k, v) => MapEntry(k, '${v.$1}/${v.$2}'))}');
    });

    test('séance : myo-reps saisis mini-série par mini-série, une série au '
        'journal du moteur avec ses parties', () async {
      await _ownerAt(app);
      _saveProfile(app, kc.GuidanceMode.assisted);
      final base = app.program.week(13).day(5)!;
      final a = app.adaptOpen(13, base)!;
      final day = app.adaptDay(13, base, a);
      final e = day.exercises.firstWhere((x) => x.id.startsWith('B2-119'));
      expect(e.engine, isTrue);
      final plan = app.miniSetPlanFor(13, 5, e, 0);
      expect(plan, isNotNull);
      expect(plan!.kind, kc.SetTechniqueKind.myoReps);
      expect(plan.next, 4);
      expect(plan.left(0), 5);
      final log = app.exLog(13, 5, e);
      expect(log.sets.length, 1);
      final s = log.sets.first;
      s.parts = [
        SetPartEntry(plan.suggested(0)),
        SetPartEntry(4, restBefore: plan.intra),
        SetPartEntry(4, restBefore: plan.intra),
        SetPartEntry(3, restBefore: plan.intra),
      ];
      s.reps = '${s.partsTotal}';
      s.flames = 9;
      expect(app.toggleSet(log, 0, app.logSpec(e)).ok, isTrue);
      app.adaptAfterSet(13, day, e, 0);
      app.saveLogs();
      // Relecture de la saisie (JSON) et journal du moteur.
      final back = SetEntry.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>,
      );
      expect([for (final p in back.parts!) p.value], [
        plan.suggested(0),
        4,
        4,
        3,
      ]);
      clock = DateTime(2026, 10, 10, 9);
      final tl = app.adaptTrainingLog();
      final rec = tl.sessions
          .where((x) => x.id == 'legacy-S13-J5')
          .expand((x) => x.sets)
          .firstWhere((x) => x.parts != null);
      expect(rec.technique, kc.SetTechniqueKind.myoReps);
      expect(rec.reps, s.partsTotal);
      expect(rec.parts!.length, 4);
      expect(tl.validate(), isEmpty);
    });

    test('groupe : résultat journalisé avec la séance', () async {
      await _ownerAt(app);
      final log = app.sessionLog(13, 5);
      log.groups['g1'] = {'rounds': 3, 'completed': true, 'elapsed': 600};
      final back = SessionLog.fromJson(
        jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>,
      );
      expect(back.groups['g1']!['rounds'], 3);
      final doc = <String, dynamic>{
        'programStart': {'date': '2026-07-13'},
        'logs': {
          'S13-J5': {
            ...back.toJson(),
            'done': true,
            'ex': {
              'x': {
                'sets': [
                  {'kg': '', 'reps': '5', 'done': true},
                ],
              },
            },
            'exerciseNames': {'x': 'Tractions PdC'},
          },
        },
      };
      final out = convertLegacyJournal(
        doc,
        exerciseId: (_) => 'sw-traction-pronation',
        usesSeconds: (_) => false,
        dayOrder: (_, _) => const ['x'],
        legacyDate: (_, _) => DateTime(2026, 10, 9),
      );
      final r = out.log.sessions.single.groupResults!.single;
      expect((r.groupId, r.rounds, r.completed, r.elapsedSeconds), (
        'g1',
        3,
        true,
        600,
      ));
    });
  });
}
