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
