// D0.3 et PIPELINE_GP.md §2 : Dart pur — aucun Flutter, `dart:io` seulement
// dans bin/, tool/ et les tests, aucune horloge implicite, aucun hasard non
// seedé, kalis_core et kalis_adapt pour seules dépendances ; aucun texte
// d'interface : des codes de raison.
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
    'package:kalis_plan': 'kalis_plan (dépendance non autorisée)',
    'package:kalis_koach': 'kalis_koach (dépendance non autorisée)',
    'DateTime.now': 'horloge implicite',
    'Stopwatch': 'horloge implicite',
    'Random()': 'hasard non seedé',
    'Random.secure': 'hasard non seedé',
    'math.Random': 'hasard de dart:math',
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

  test('le moteur n\'importe ni le simulateur ni les rapports', () {
    for (final file in sources) {
      if (file.path.contains('/sim/') ||
          file.path.endsWith('simulation.dart') ||
          file.path.endsWith('report.dart')) {
        continue;
      }
      final text = file.readAsStringSync();
      expect(text.contains('sim/'), isFalse, reason: file.path);
      expect(text.contains('simulation.dart'), isFalse, reason: file.path);
      expect(text.contains('report.dart'), isFalse, reason: file.path);
      expect(text.contains('SimRng'), isFalse, reason: file.path);
    }
  });

  test('dépendances : kalis_adapt et kalis_core par chemin, rien d\'autre', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final deps = RegExp(r'\ndependencies:\n((?:  .*\n|    .*\n)+)')
        .firstMatch(pubspec)!
        .group(1)!;
    expect(
      deps.trim(),
      'kalis_adapt:\n    path: ../kalis_adapt\n  kalis_core:\n    path: ../kalis_core',
    );
    expect(pubspec.contains('sdk: flutter'), isFalse);
    expect(pubspec.contains("sdk: '>=3.10.0 <4.0.0'"), isTrue);
  });

  test('aucun texte d\'interface dans les sorties : des codes de raison', () {
    final engine = File('lib/src/engine.dart').readAsStringSync();
    expect(engine.contains('ReasonCodes.'), isTrue);
    for (final file in sources) {
      expect(
        RegExp(r"Reason\(\s*code: '").hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} : code de raison en dur',
      );
      expect(
        RegExp(r"_reason\(\s*'").hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} : code de raison en dur',
      );
    }
  });

  test('aucune ligne des anciens fichiers de progression n\'est reprise', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final name in <String>[
        'progression.dart',
        'game.dart',
        'rewards.dart',
      ]) {
        expect(text.contains(name), isFalse, reason: file.path);
      }
    }
  });
}
