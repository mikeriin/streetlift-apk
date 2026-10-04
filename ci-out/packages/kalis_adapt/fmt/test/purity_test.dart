// D0.3 et PIPELINE_GP.md §2 : Dart pur — aucun Flutter, `dart:io` seulement
// dans bin/, tool/ et les tests, aucune horloge implicite, aucun hasard non
// seedé, kalis_core et kalis_plan pour seules dépendances.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/ contient des sources', () {
    expect(sources.length, greaterThan(15));
  });

  const forbidden = <String, String>{
    "import 'dart:io'": 'dart:io',
    "import 'dart:ui'": 'dart:ui',
    "import 'dart:html'": 'dart:html',
    "import 'dart:isolate'": 'dart:isolate',
    'package:flutter': 'Flutter',
    'DateTime.now': 'horloge implicite',
    'Stopwatch': 'horloge implicite',
    'Random()': 'hasard non seedé',
    'Random.secure': 'hasard non seedé',
    'dart:math\' show Random': 'hasard de dart:math',
    'Platform.': 'plateforme',
  };

  for (final entry in forbidden.entries) {
    test('lib/ sans ${entry.value} (« ${entry.key} »)', () {
      for (final file in sources) {
        expect(
          file.readAsStringSync().contains(entry.key),
          isFalse,
          reason: file.path,
        );
      }
    });
  }

  test(
    'le hasard du simulateur vient de la seule suite seedée de rng.dart',
    () {
      for (final file in sources) {
        final text = file.readAsStringSync();
        expect(text.contains('math.Random'), isFalse, reason: file.path);
        expect(
          RegExp(r'\bRandom\(').hasMatch(text),
          isFalse,
          reason: file.path,
        );
        if (!file.path.contains('/sim/') &&
            !file.path.endsWith('simulation.dart')) {
          expect(text.contains('SimRandom'), isFalse, reason: file.path);
          expect(text.contains('SeededRandom'), isFalse, reason: file.path);
        }
      }
    },
  );

  test('le moteur n\'importe pas le simulateur', () {
    for (final file in sources) {
      if (file.path.contains('/sim/') ||
          file.path.endsWith('simulation.dart') ||
          file.path.endsWith('report.dart')) {
        continue;
      }
      final text = file.readAsStringSync();
      expect(text.contains("sim/"), isFalse, reason: file.path);
      expect(text.contains('simulation.dart'), isFalse, reason: file.path);
    }
  });

  test('dépendances : kalis_core et kalis_plan par chemin, rien d\'autre', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final deps = RegExp(r'\ndependencies:\n((?:  .*\n|    .*\n)+)')
        .firstMatch(pubspec)!
        .group(1)!;
    expect(
      deps.trim(),
      'kalis_core:\n    path: ../kalis_core\n  kalis_plan:\n    path: ../kalis_plan',
    );
    expect(pubspec.contains('sdk: flutter'), isFalse);
    expect(pubspec.contains("sdk: '>=3.10.0 <4.0.0'"), isTrue);
  });

  test('aucun texte d\'interface dans les sorties : des codes de raison', () {
    // Les raisons rendues sont des codes du registre de kalis_core ; le
    // moteur ne construit pas de phrase (D0.4).
    final review = File('lib/src/review.dart').readAsStringSync();
    expect(review.contains('ReasonCodes.'), isTrue);
    for (final file in sources) {
      expect(
        RegExp(r"Reason\(\s*code: '").hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} : code de raison en dur',
      );
    }
  });
}
