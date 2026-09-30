// 5.8.2 (M7b correction 2) — règle de base du propriétaire (30/09/2026) :
// « TOUS les fonds de la couleur du support ». Chaque affichage 3D de
// l'application reçoit explicitement la couleur de son support (page ou
// carte) ; aucune carte ne sert seulement de cadre à une vue 3D. Contrôle
// sur les sources (tout nouvel écran 3D est couvert sans y penser) ; la
// démarcation réelle est mesurée sur émulateur (CI 3D).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _views = [
  'Mannequin3D',
  'MannequinPlayer',
  'TargetedMannequin',
  'WeeklyMannequin',
  'ExerciseMannequin',
];

/// Arguments d'un appel (texte entre la parenthèse ouvrante et sa fermante).
String _args(String src, int open) {
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    final c = src[i];
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) return src.substring(open + 1, i);
    }
  }
  return src.substring(open + 1);
}

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('chaque vue 3D reçoit la couleur de son support', () {
    final missing = <String>[];
    var calls = 0;
    for (final f in files) {
      final src = f.readAsStringSync();
      for (final name in _views) {
        final call = RegExp('(?<![A-Za-z_])$name\\(');
        for (final m in call.allMatches(src)) {
          final before = src.substring(0, m.start).trimRight();
          // déclarations (const X({, X extends, class X) : ignorées
          if (before.endsWith('const') ||
              before.endsWith('class') ||
              src.startsWith('$name({', m.start)) {
            continue;
          }
          calls++;
          final args = _args(src, m.end - 1);
          if (!args.contains('background:')) {
            final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
            missing.add('${f.path}:$line $name');
          }
        }
      }
    }
    expect(calls, greaterThanOrEqualTo(10));
    expect(missing, isEmpty, reason: 'fond sans couleur du support');
  });

  test('aucune carte ne sert seulement de cadre à une vue 3D', () {
    final frame = RegExp(
      r'KCard\(\s*(key:[^,]*,\s*)?child:\s*(Mannequin3D|MannequinPlayer|'
      r'ExerciseMannequin|TargetedMannequin|WeeklyMannequin)\(',
    );
    final found = [
      for (final f in files)
        for (final m in frame.allMatches(f.readAsStringSync()))
          '${f.path}: ${m.group(2)}',
    ];
    expect(found, isEmpty);
  });
}
