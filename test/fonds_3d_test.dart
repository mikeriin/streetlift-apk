// 5.8.2 (M7b correction 2) — règle de base du propriétaire (30/09/2026) :
// « TOUS les fonds de la couleur du support ». Chaque affichage 3D de
// l'application reçoit explicitement la couleur de son support (page ou
// carte) ; aucune carte ne sert seulement de cadre à une vue 3D. Contrôle
// sur les sources (tout nouvel écran 3D est couvert sans y penser) ; la
// démarcation réelle est mesurée sur émulateur (CI 3D).
//
// M8 (5.9.0, 30/09/2026) : la 3D ne sert plus qu'à la démonstration des
// exercices et à Koach (plus l'écran technique Moteur 3D et l'animation de
// test) ; partout ailleurs, carte 2D des groupes, transparente (fond =
// support par construction).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _views = ['Mannequin3D', 'MannequinPlayer', 'ExerciseMannequin'];

/// Seuls fichiers où la 3D s'affiche (M8).
const _allowed3d = {
  'exercise_mannequin.dart', // démonstration de la fiche (lecteur)
  'exercise_screens.dart', // tête de fiche, si l'exercice a une animation
  'koach_preview_screen.dart', // Koach
  'mannequin_player.dart', // lecteur
  'engine3d.dart', // Réglages › À propos › Moteur 3D (mesure)
  'animation_test_screen.dart', // animation de test (Moteur 3D)
};

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
    expect(calls, greaterThanOrEqualTo(5));
    expect(missing, isEmpty, reason: 'fond sans couleur du support');
  });

  test('aucune carte ne sert seulement de cadre à une vue 3D', () {
    final frame = RegExp(
      r'KCard\(\s*(key:[^,]*,\s*)?child:\s*(Mannequin3D|MannequinPlayer|'
      r'ExerciseMannequin)\(',
    );
    final found = [
      for (final f in files)
        for (final m in frame.allMatches(f.readAsStringSync()))
          '${f.path}: ${m.group(2)}',
    ];
    expect(found, isEmpty);
  });

  test('M8 : la 3D seulement pour la démonstration et Koach', () {
    final outside = <String>[];
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      if (_allowed3d.contains(name) || name == 'mannequin_3d.dart') continue;
      final src = f.readAsStringSync();
      for (final v in _views) {
        if (RegExp('(?<![A-Za-z_])$v\\(').hasMatch(src)) {
          outside.add('$name : $v');
        }
      }
    }
    expect(outside, isEmpty);
  });
}
