// D0.3 et PIPELINE_GP.md §2 : Dart pur — aucun Flutter, `dart:io` seulement
// dans bin/ et les tests, aucune horloge implicite, aucun hasard non seedé.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/ contient des sources', () {
    expect(sources.length, greaterThan(10));
  });

  const forbidden = <String, String>{
    "import 'dart:io'": 'dart:io',
    "import 'dart:ui'": 'dart:ui',
    "import 'dart:html'": 'dart:html',
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

  test('dépendances : aucune hors tests', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec.contains('\ndependencies:'), isFalse);
    expect(pubspec.contains('sdk: flutter'), isFalse);
    expect(pubspec.contains("sdk: '>=3.10.0 <4.0.0'"), isTrue);
  });

  test('la version exportée est celle du pubspec et du CHANGELOG', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: (\S+)$',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    expect(
      File('lib/src/version.dart').readAsStringSync(),
      contains("kalisCoreVersion = '$version'"),
    );
    expect(File('CHANGELOG.md').readAsStringSync(), contains('## $version'));
  });
}
