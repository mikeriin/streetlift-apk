// G3 — Historique conservé au passage à la base d'exercices v1.1 : mêmes
// séances, mêmes records, mêmes statistiques qu'avant (comparaison chiffrée).
//
// Deux sauvegardes synthétiques au format 6.x (aucune donnée réelle) : le
// programme personnel saisi sur ses 40 semaines (`filledBackup`, comme
// l'historique du propriétaire) et le profil `charge` du banc L6 (charges,
// répétitions et RIR tirés d'une graine fixe). Pour chacune, un relevé
// indépendant de la date du jour : séances terminées et séries validées,
// meilleures performances par exercice, records battus séance par séance,
// groupes musculaires par exercice, séries par groupe et par exercice de
// chaque semaine du programme.
//
// Le relevé de référence `test/fixtures/g3_historique_avant.json` a été
// produit par ce même test sur `main` avant G3 (dev6.1.0, e5cf07f ; run CI
// noté dans le fichier). Sans ce fichier, le test écrit le relevé dans le
// journal (entre G3-RELEVE-DEBUT et G3-RELEVE-FIN) et ne compare rien.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/game.dart';
import 'package:streetlift_tracker/stats_data.dart';
import 'package:streetlift_tracker/store.dart';

import 'l2_fixtures.dart';
import 'support/perf_fixtures.dart';

double _r(double v) => (v * 1000).roundToDouble() / 1000;

Map<String, Object?> releve(AppStore app) {
  final history = statsHistory(app);
  final sessions = {
    for (final h in history)
      h.id: {
        'titre': h.title,
        'series': h.session.ex.values.fold<int>(
          0,
          (n, e) => n + e.sets.where((s) => s.done).length,
        ),
      },
  };
  final bests = exerciseBests(app.logs);
  final keys = bests.keys.toList()..sort();
  final records = <String, Object?>{};
  for (final h in history) {
    final hits = app.sessionRecords(h.id);
    if (hits.isEmpty) continue;
    records[h.id] = [
      for (final r in hits)
        [r.exercise, r.weighted, _r(r.kg), r.reps, _r(r.previous), _r(r.current)],
    ];
  }
  final names = <String>{
    for (final log in app.logs.values) ...log.exerciseNames.values,
  }.toList()..sort();
  final weeks = <String, Object?>{};
  final start = app.program.start ?? app.program.anchorMonday;
  for (var w = 0; w < app.program.weeks.length; w++) {
    final sunday = DateTime(start.year, start.month, start.day + 7 * w + 6, 22);
    final muscles = app.weeklyMuscles(sunday);
    final ex = app.weeklyNames(sunday);
    final exKeys = ex.keys.toList()..sort();
    weeks['S${w + 1}'] = {
      'groupes': {
        for (final g in AppStore.muscleGroups)
          if ((muscles[g] ?? 0) > 0) g: _r(muscles[g]!),
      },
      'exercices': {for (final k in exKeys) k: _r(ex[k]!)},
    };
  }
  return {
    'seances': sessions,
    'meilleures': {
      for (final k in keys)
        k: [
          _r(bests[k]!.bestE1rm),
          _r(bests[k]!.bestKg),
          bests[k]!.bestKgReps,
          bests[k]!.bestReps,
          bests[k]!.weightedSets,
          bests[k]!.bodyweightSets,
        ],
    },
    'records': records,
    'groupes': {for (final n in names) n: app.groupsFor(n)},
    'semaines': weeks,
  };
}

Future<Map<String, Object?>> releveDe(
  Map<String, dynamic> Function(AppStore seed) build,
) async {
  SharedPreferences.setMockInitialValues({});
  final seed = AppStore();
  await seed.init();
  final doc = build(seed);
  SharedPreferences.setMockInitialValues({});
  final app = AppStore();
  await app.init();
  final ok = await app.importAll(jsonEncode(doc));
  expect(ok, isTrue, reason: 'sauvegarde refusée à l’import');
  return releve(app);
}

/// Différences lisibles entre deux relevés (chemin : avant → après).
List<String> diff(Object? a, Object? b, [String path = '']) {
  if (a is Map && b is Map) {
    return [
      for (final k in {...a.keys, ...b.keys})
        ...diff(a[k], b[k], '$path/$k'),
    ];
  }
  if (a is List && b is List) {
    if (a.length != b.length) return ['$path : $a → $b'];
    return [for (var i = 0; i < a.length; i++) ...diff(a[i], b[i], '$path[$i]')];
  }
  if (a is num && b is num) return a == b ? const [] : ['$path : $a → $b'];
  return a == b ? const [] : ['$path : $a → $b'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('historique, records et statistiques identiques avant / après G3', () async {
    final now = {
      'programme_40_semaines': await releveDe(filledBackup),
      'banc_charge': await releveDe((seed) => perfBackup(seed, 'charge')!),
    };
    final golden = File('test/fixtures/g3_historique_avant.json');
    if (!golden.existsSync()) {
      // ignore: avoid_print
      print('G3-RELEVE-DEBUT${jsonEncode(now)}G3-RELEVE-FIN');
      return;
    }
    final before =
        (jsonDecode(golden.readAsStringSync()) as Map<String, dynamic>)['releves'];
    final d = diff(jsonDecode(jsonEncode(before)), jsonDecode(jsonEncode(now)));
    expect(d, isEmpty, reason: d.take(40).join('\n'));
    // Le relevé n'est pas vide : il porte vraiment sur un historique.
    final p = now['programme_40_semaines']!;
    expect((p['seances'] as Map).length, greaterThan(150));
    expect((p['meilleures'] as Map).length, greaterThan(40));
    expect((now['banc_charge']!['records'] as Map), isNotEmpty);
  });
}
