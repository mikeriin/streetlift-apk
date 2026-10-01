import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void phone(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Gestes réels sur la liste verticale, sans agrandir la fenêtre ni jumpTo.
Future<void> scrollToAction(
  WidgetTester tester,
  Finder target, {
  bool up = false,
}) async {
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable &&
        (widget.axisDirection == AxisDirection.down ||
            widget.axisDirection == AxisDirection.up),
  );
  for (var i = 0; i < 30 && target.hitTestable().evaluate().isEmpty; i++) {
    expect(vertical, findsAtLeastNWidgets(1));
    await tester.drag(vertical.last, Offset(0, up ? 250 : -250));
    await tester.pumpAndSettle();
  }
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Action atteinte par défilement sur une fenêtre de téléphone',
  );
}

/// 5.5.2 : plus de boutons Précédent / Suivant dans les séances ; une page
/// se change en glissant. Glissement d'une page vers la suivante (ou la
/// précédente avec [back]) sur la vue paginée, puis stabilisation.
Future<void> swipePage(WidgetTester tester, {bool back = false}) async {
  final pager = find.byType(PageView);
  expect(pager, findsOneWidget);
  final width = tester.getSize(pager).width;
  await tester.drag(pager, Offset(back ? width * .8 : -width * .8, 0));
  await tester.pumpAndSettle();
}

/// G3 : comme [scrollToAction], par gestes lents (sans élan) : sur une fiche
/// très longue (texte à 200 %), un geste rapide lance la liste et peut
/// dépasser la cible entre deux vérifications.
Future<void> scrollSlowlyTo(WidgetTester tester, Finder target) async {
  final vertical = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
  for (var i = 0; i < 80 && target.hitTestable().evaluate().isEmpty; i++) {
    expect(vertical, findsAtLeastNWidgets(1));
    await tester.timedDrag(
      vertical.last,
      const Offset(0, -200),
      const Duration(milliseconds: 800),
    );
    await tester.pumpAndSettle();
  }
  expect(
    target.hitTestable(),
    findsOneWidget,
    reason: 'Atteint par défilement lent sur une fenêtre de téléphone',
  );
}
