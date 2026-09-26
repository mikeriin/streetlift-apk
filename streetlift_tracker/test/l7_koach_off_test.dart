// L7 — D6 : Koach désactivé = comportement 2.x à l'identique.
//
// Instantané de référence `test/fixtures/l7_2x_snapshot.json.gz`, capturé en
// CI sur l'arbre L4b 2.5.9 inchangé (même calcul, 5 jeux de références et
// d'unités) : charge, libellé, volume, nombre de séries, nature de saisie,
// reps prévues et repos des 1 818 exercices des 40 semaines. Vérifié ici
// pour une installation où Koach n'a jamais servi, puis après une
// utilisation complète de Koach suivie de sa désactivation.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/store.dart';

Map<String, double> _defaults(AppStore app) {
  final p = app.program.pilotage;
  return {
    'B4': p.bodyweight,
    for (final l in p.mainLifts) l.ref: l.oneRm,
    for (final m in p.repMax) m.ref: m.max,
    for (final a in p.accessories) a.ref: a.refLoad,
  };
}

Map<String, (Map<String, double>, bool)> _configs(AppStore app) {
  final base = _defaults(app);
  return {
    'programme': (base, false),
    'programme-lb': (base, true),
    'vide': (<String, double>{}, false),
    'autre': (
      {
        for (final e in base.entries)
          e.key: switch (e.key) {
            'B4' => 80.0,
            'B8' || 'B9' || 'B10' || 'B11' => (e.value * 1.2),
            'B16' || 'B17' || 'B18' || 'B19' || 'B20' =>
              (e.value * 1.1).roundToDouble(),
            _ => e.value * 0.9,
          },
      },
      false,
    ),
    'partiel': ({'B4': 71.5, 'B8': 32.5, 'B17': 30, 'B25': 70}, false),
  };
}

/// Même ligne que l'instantané 2.x, avec en plus les variantes 3.0.0 par
/// semaine ([AppStore.sessionLoad], libellé de la semaine), qui doivent
/// rester égales aux valeurs 2.x quand Koach est désactivé.
List<Object?> _row(AppStore app, int week, Exercise e) {
  final spec = app.logSpec(e);
  final n = app.setCount(e);
  expect(app.sessionLoad(week, e), app.loadFor(e), reason: e.id);
  expect(app.loadLabel(e, week: week), app.loadLabel(e), reason: e.id);
  return [
    e.id,
    app.loadFor(e),
    app.loadLabel(e),
    app.setsLabel(e),
    n,
    spec.kind,
    spec.rowPrefix,
    spec.cluster,
    spec.myo,
    spec.intra,
    spec.seconds,
    app.plannedReps(e, spec, n),
    [for (var i = 0; i < n; i++) app.restAfterSet(e, spec, i, n)],
    app.showKgFor(e, ExerciseLog()),
    app.missingReference(e),
    app.loadNeedsReference(e),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final snapshot =
      jsonDecode(
            utf8.decode(
              gzip.decode(
                File(
                  'test/fixtures/l7_2x_snapshot.json.gz',
                ).readAsBytesSync(),
              ),
            ),
          )
          as Map<String, dynamic>;

  late AppStore app;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    app = AppStore()..storeClock = () => DateTime(2026, 9, 26, 10);
    await app.init();
  });
  tearDown(() => app.dispose());

  void compareAll(String label) {
    for (final entry in _configs(app).entries) {
      final (values, lb) = entry.value;
      app.values
        ..clear()
        ..addAll(values);
      app.refStatus
        ..clear()
        ..addAll({for (final k in values.keys) k: 'set'});
      app.settings.lb = lb;
      final rows = <Object?>[];
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          for (final e in d.exercises) {
            rows.add(_row(app, w.n, e));
          }
        }
      }
      final expected = snapshot[entry.key] as List;
      final actual = jsonDecode(jsonEncode(rows)) as List;
      expect(actual.length, 1818, reason: '$label ${entry.key}');
      for (var i = 0; i < expected.length; i++) {
        expect(
          actual[i],
          expected[i],
          reason: '$label · ${entry.key} · ${(expected[i] as List).first}',
        );
      }
    }
  }

  test('instantané de référence : 5 jeux × 1 818 exercices', () {
    expect(snapshot.keys.toSet(), {
      'programme',
      'programme-lb',
      'vide',
      'autre',
      'partiel',
    });
    for (final rows in snapshot.values) {
      expect(rows as List, hasLength(1818));
    }
  });

  test('Koach jamais activé : charges, séries et saisies identiques à 2.x',
      () {
    expect(app.koach.enabled, isFalse);
    compareAll('jamais activé');
  });

  test('Koach utilisé puis désactivé : identique à 2.x', () {
    app.program.start = DateTime(2026, 7, 13);
    app.startOrigin = 'user';
    app.values.addAll(_defaults(app));
    app.enableKoach();
    // Tout ce qui modifie les charges ou les séries quand Koach est actif.
    app.setKoachEquipment('plate', {'step': 2.5});
    app.setKoachEquipment('dumbbell', {'small': 2, 'threshold': 12, 'large': 4});
    app.setKoachEquipment('pulley', {'step': 5, 'unit': 'lb'});
    app.toggleKoachLock('B8');
    app.koach.painRelief['pull'] = '2026-09-20T18:00:00';
    app.setKoachStructure(true);
    final pull = app.program.week(5).day(1)!.exercises.firstWhere(
      (e) => e.id == 'B1-73',
    );
    app.acceptKoachStructure({
      'id': 'W5|sets|pull',
      'week': 5,
      'kind': 'sets',
      'movement': 'pull',
      'exercise': pull.id,
      'delta': 1,
    });
    app.acceptKoachStructure({
      'id': 'W6|deload',
      'week': 6,
      'kind': 'deload',
      'movement': 'pull',
      'sets': 0.6,
      'load': 0.1,
    });
    expect(app.koachSetCount(5, pull), app.setCount(pull) + 1);
    app.disableKoach();
    expect(app.koachOn, isFalse);
    compareAll('après désactivation');
    // Journal : un exercice ouvert reçoit les séries du programme, aucune
    // difficulté n'est exigée, aucune prescription n'est écrite.
    final log = app.exLog(5, 1, pull);
    expect(log.sets.length, app.setCount(pull));
    log.sets[0].reps = '8';
    expect(
      app.toggleSet(log, 0, app.logSpec(pull), exercise: pull, week: 5).ok,
      isTrue,
    );
    expect(log.prescribed, isNull);
    expect(log.sets[0].effort, isNull);
    expect(app.koachSuggestion(5, 1, pull, log), isNull);
    expect(app.koachWeighInDue, isFalse);
  });
}
