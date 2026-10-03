// PIPELINE_GP.md §2 : Dart pur — aucun Flutter, `dart:io` seulement dans
// bin/ et les tests, aucune horloge implicite, aucun hasard non seedé. Le
// banc lit kalis_core, kalis_plan et kalis_adapt, rien d'autre.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/ contient des sources', () {
    expect(sources.length, greaterThan(8));
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

  test('dépendances : kalis_adapt, kalis_core, kalis_plan par chemin', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final deps = RegExp(r'\ndependencies:\n((?:  .*\n|    .*\n)+)')
        .firstMatch(pubspec)!
        .group(1)!;
    expect(
      deps.trim(),
      'kalis_adapt:\n    path: ../kalis_adapt\n'
      '  kalis_core:\n    path: ../kalis_core\n'
      '  kalis_plan:\n    path: ../kalis_plan',
    );
    expect(pubspec.contains('sdk: flutter'), isFalse);
  });

  test('le banc ne modifie aucun moteur : aucun fichier hors du paquet', () {
    for (final file in sources) {
      final text = file.readAsStringSync();
      expect(text.contains("import '../../"), isFalse, reason: file.path);
      expect(text.contains('package:kalis_quest'), isFalse, reason: file.path);
    }
  });

  test('aucun nom ni extrait des programmes de référence dans le paquet', () {
    // Les références privées ne sont jamais nommées (PIPELINE_CP.md §2) :
    // les documents du paquet n'en donnent que des mesures agrégées.
    final docs = Directory('docs')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    for (final file in <File>[...docs, ...sources]) {
      final text = file.readAsStringSync().toLowerCase();
      expect(text.contains('copyright ©'), isFalse, reason: file.path);
    }
  });
}
