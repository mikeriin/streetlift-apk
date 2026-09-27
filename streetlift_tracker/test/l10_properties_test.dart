// L10 — tests par propriétés sur 10 000 profils aléatoires (graines 1 à
// 10 000, fixées) : matériel toujours disponible, aucun exercice
// contre-indiqué, prérequis respectés, durée dans ±10 % (volume plafonné
// signalé), volume sous le plafond, mouvements de l'objectif au moins 2 fois
// par semaine (1 fois par type pour « Forme et santé »), décharge au moins
// toutes les 6 semaines, 48 h entre séances lourdes d'une même famille,
// démonstration animée présente, génération déterministe.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'support/l10_support.dart';

void main() {
  final data = L10Data.load();
  const total = 10000;
  const chunk = 1000;
  final models = <String, int>{};
  var capped = 0, sessions = 0;

  for (var from = 1; from <= total; from += chunk) {
    test(
      'profils $from à ${from + chunk - 1}',
      () {
        final failures = <String>[];
        final watch = Stopwatch()..start();
        for (var seed = from; seed < from + chunk; seed++) {
          final inputs = randomInputs(seed, data.catalog);
          final g = data.generate(inputs, seed: seed);
          models[g.summary['model'] as String] =
              (models[g.summary['model'] as String] ?? 0) + 1;
          capped += (g.summary['capped'] as List? ?? const []).length;
          for (final w in g.program['weeks'] as List) {
            for (final d in (w as Map)['days'] as List) {
              if (((d as Map)['exercises'] as List).isNotEmpty) sessions++;
            }
          }
          final issues = checkProgram(data, inputs, g, tag: 'graine $seed');
          failures.addAll(issues.take(3));
          // Déterminisme : une graine sur 50 est rejouée.
          if (seed % 50 == 0) {
            final again = data.generate(inputs, seed: seed);
            if (jsonEncode(again.program) != jsonEncode(g.program)) {
              failures.add('graine $seed : génération non déterministe');
            }
          }
          if (failures.length > 40) break;
        }
        // ignore: avoid_print
        print(
          'L10 propriétés $from-${from + chunk - 1} : '
          '${watch.elapsedMilliseconds} ms ; modèles $models ; '
          'séances $sessions dont $capped plafonnées',
        );
        expect(failures, isEmpty, reason: failures.take(40).join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );
  }
}
