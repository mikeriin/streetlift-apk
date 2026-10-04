// D0.3 et PIPELINE_GP.md §2 : Dart pur — aucun Flutter, `dart:io` seulement
// dans bin/ et les tests, aucune horloge implicite, aucun hasard non seedé,
// kalis_core pour seule dépendance.
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

  test('le hasard vient de la seule suite seedée de hash.dart', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(text.contains('math.Random'), isFalse, reason: file.path);
      expect(RegExp(r'\bRandom\(').hasMatch(text), isFalse, reason: file.path);
    }
  });

  test('dépendances : kalis_core par chemin, rien d\'autre', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final deps = RegExp(
      r'\ndependencies:\n((?:  .*\n|    .*\n)+)',
    ).firstMatch(pubspec)!.group(1)!;
    expect(deps.trim(), 'kalis_core:\n    path: ../kalis_core');
    expect(pubspec.contains('sdk: flutter'), isFalse);
    expect(pubspec.contains("sdk: '>=3.10.0 <4.0.0'"), isTrue);
  });

  test('aucun texte d\'interface dans les sorties : des codes de raison', () {
    // Les raisons rendues sont des codes du registre de kalis_core ; le
    // moteur ne construit pas de phrase (D0.4).
    final engine = File('lib/src/engine.dart').readAsStringSync();
    expect(engine.contains('ReasonCodes.'), isTrue);
    for (final file in sources) {
      if (file.path.endsWith('report.dart') ||
          file.path.endsWith('testing.dart')) {
        continue;
      }
      expect(
        RegExp(r"Reason\(\s*code: '").hasMatch(file.readAsStringSync()),
        isFalse,
        reason: '${file.path} : code de raison en dur',
      );
    }
  });
}
