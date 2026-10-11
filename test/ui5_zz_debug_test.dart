// Diagnostic temporaire (retiré avant livraison).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    void dump(String when) {
      debugPrint('DIAG $when');
      for (final f in [
        find.byType(AppBar),
        find.byType(TextField),
        find.byType(Scrollable),
        find.byType(SwitchListTile),
        find.byType(Switch),
        find.text('Supprimer'),
      ]) {
        for (final e in f.evaluate()) {
          final r = e.renderObject;
          if (r is RenderBox && r.hasSize) {
            debugPrint(
              'DIAG ${e.widget.runtimeType} '
              '${r.localToGlobal(Offset.zero) & r.size}',
            );
          }
        }
      }
      final s = find.byType(Scrollable).evaluate();
      for (final e in s) {
        final st = (e as StatefulElement).state as ScrollableState;
        debugPrint(
          'DIAG scroll ${st.widget.axisDirection} '
          'px=${st.position.pixels} max=${st.position.maxScrollExtent} '
          'vp=${st.position.viewportDimension}',
        );
      }
    }

    dump('ouverture');
    final v = find.byType(Scrollable);
    for (var i = 0; i < 10; i++) {
      await tester.drag(v.last, const Offset(0, -250));
      await tester.pumpAndSettle();
    }
    dump('fin');
    debugPrint('DIAG hit ${find.byType(TextField).hitTestable().evaluate().length}');
  });
}
