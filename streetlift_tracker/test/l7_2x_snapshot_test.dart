// L7 — Capture de référence du comportement 2.x (arbre L4b 2.5.9 inchangé).
// Exécuté une seule fois en CI sur la base, pour produire l'instantané que
// le test de non-régression « Koach désactivé = 2.x » compare en 3.0.0.
// Charges, libellés, volumes, nombre de séries, nature de saisie, reps
// prévues et repos de chacun des exercices des 40 semaines, pour plusieurs
// jeux de références et d'unités.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('instantané 2.x des 40 semaines', () async {
    SharedPreferences.setMockInitialValues({});
    final app = AppStore()..storeClock = () => DateTime(2026, 9, 26, 10);
    await app.init();
    final base = _defaults(app);
    final configs = <String, (Map<String, double>, bool)>{
      'programme': (base, false),
      'programme-lb': (base, true),
      'vide': (<String, double>{}, false),
      'autre': (
        {
          for (final e in base.entries)
            e.key: switch (e.key) {
              'B4' => 80.0,
              'B8' || 'B9' || 'B10' || 'B11' => (e.value * 1.2),
              'B16' || 'B17' || 'B18' || 'B19' || 'B20' => (e.value * 1.1)
                  .roundToDouble(),
              _ => e.value * 0.9,
            },
        },
        false,
      ),
      'partiel': ({'B4': 71.5, 'B8': 32.5, 'B17': 30, 'B25': 70}, false),
    };
    final out = <String, dynamic>{};
    for (final entry in configs.entries) {
      final (values, lb) = entry.value;
      app.values
        ..clear()
        ..addAll(values);
      app.refStatus
        ..clear()
        ..addAll({for (final k in values.keys) k: 'set'});
      app.settings.lb = lb;
      final rows = <List<Object?>>[];
      for (final w in app.program.weeks) {
        for (final d in w.days) {
          for (final e in d.exercises) {
            final spec = app.logSpec(e);
            final n = app.setCount(e);
            rows.add([
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
            ]);
          }
        }
      }
      out[entry.key] = rows;
    }
    final file = File('../ci-out/l7_2x_snapshot.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(out));
    expect(out['programme'], hasLength(1818));
  });
}
