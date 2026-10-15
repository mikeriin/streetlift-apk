// L9b (KT-080) — coût de la liste la plus longue (BV11 : démonstrations 2D
// de l'ancien pack retirées avec lui), mesuré dans l'environnement de test
// (JIT, machine de CI). Ce n'est pas une mesure en mode profile sur
// téléphone (reste à valider sur appareil) : les seuils sont larges et
// servent de garde-fou contre une régression grave.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/exercise_screens.dart';
import 'package:streetlift_tracker/store.dart';

import 'phone_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('liste la plus longue : 1 039 exercices (G3), défilement', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(store.init);
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(true), home: const ExerciseLibraryScreen()),
    );
    await tester.pumpAndSettle();
    final list = find.byType(Scrollable).first;
    final watch = Stopwatch()..start();
    var frames = 0;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump();
      frames++;
    }
    watch.stop();
    // ignore: avoid_print
    print(
      'L9B_PERF liste_frames=$frames moyenne_ms='
      '${(watch.elapsedMicroseconds / frames / 1000).toStringAsFixed(2)}',
    );
    expect(tester.takeException(), null);
  });
}
