import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/levelup.dart';
import 'package:streetlift_tracker/ui.dart';

void main() {
  testWidgets('Niv. précède le niveau et la barre représente son avancement', (
    tester,
  ) async {
    for (final progress in [0.0, .6, 1.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(true),
          home: Scaffold(
            body: Center(
              child: LevelProgressNumber(level: 10, progress: progress),
            ),
          ),
        ),
      );
      expect(find.text('Niv.'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(
        tester.getRect(find.text('Niv.')).right,
        lessThan(tester.getRect(find.text('10')).left),
      );
      final bar = find.byType(KProgressBar);
      expect(tester.widget<KProgressBar>(bar).value, progress);
      expect(
        tester.getRect(bar).top,
        greaterThan(tester.getRect(find.text('10')).bottom),
      );
      expect(tester.takeException(), null);
    }
  });
}
