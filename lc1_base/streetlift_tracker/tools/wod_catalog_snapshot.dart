// Instantané du catalogue de WODs embarqué (préchargés + générés), pour
// comparer les définitions avant/après une modification du générateur.
//
//   dart run tools/wod_catalog_snapshot.dart > catalogue.jsonl
//
// Une ligne JSON par WOD, dans l'ordre du catalogue, sans résultats ni
// niveau (recalculé par l'application). Dernière ligne : résumé par type et
// par format explicite, et liste des WODs dont les notes énoncent un score.
import 'dart:convert';

import 'package:streetlift_tracker/wod_generator.dart';
import 'package:streetlift_tracker/wod_models.dart';

void main() {
  final seeds = allSeedWods();
  final all = <Wod>[
    ...seeds,
    ...generateWods(generatedCount(seeds.length)),
    ...generateWodsV2(generatedCountV2),
  ];
  final byType = <String, int>{};
  final byFormat = <String, int>{};
  final scored = <String>[];
  for (final w in all) {
    final json = w.toJson()
      ..remove('results')
      ..remove('level');
    stdout(jsonEncode(json));
    byType.update(w.type, (v) => v + 1, ifAbsent: () => 1);
    final format = json['format'];
    final kind = format is Map ? format['kind'] as String : '-';
    byFormat.update(kind, (v) => v + 1, ifAbsent: () => 1);
    if (RegExp(r'score', caseSensitive: false).hasMatch(w.notes)) {
      scored.add(w.id);
    }
  }
  stdout(
    jsonEncode({
      'summary': {
        'count': all.length,
        'ids': all.map((w) => w.id).toSet().length,
        'byType': byType,
        'byFormat': byFormat,
        'notesWithScore': scored,
      },
    }),
  );
}

// ignore: avoid_print
void stdout(String line) => print(line);
