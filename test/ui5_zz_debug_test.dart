// Diagnostic temporaire (retiré avant livraison).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/app_theme.dart';
import 'package:streetlift_tracker/data_control.dart';

void main() {
  testWidgets('diag effacement 320 × 720, 200 %', (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(true),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: inner!,
        ),
        home: const EraseDataDialog(),
      ),
    );
    await tester.pumpAndSettle();
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    for (var i = 0; i < 200 && find.byType(TextField).evaluate().isEmpty; i++) {
      list.position.jumpTo(
        (list.position.pixels + 300).clamp(0.0, list.position.maxScrollExtent),
      );
      await tester.pump();
    }
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    final r = tester.getRect(find.byType(TextField));
    debugPrint('DIAG champ $r');
    debugPrint(
      'DIAG liste px=${list.position.pixels} '
      'max=${list.position.maxScrollExtent} '
      'vp=${list.position.viewportDimension}',
    );
    final sr = tester.getRect(find.byType(Scrollable).first);
    debugPrint('DIAG scrollable $sr');
    final hit = tester.hitTestOnBinding(r.center);
    for (final e in hit.path.take(12)) {
      debugPrint('DIAG hit ${e.target.runtimeType}');
    }
  });
}
