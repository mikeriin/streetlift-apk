// Remplissage générique de la feuille de score (L3b) pour les tests dont le
// WOD dépend des données (essai du jour) : chaque champ vide reçoit [value],
// puis « terminé » est choisi. Les champs déjà remplis (temps du chrono,
// rounds validés) sont laissés tels quels.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> fillScoreSheet(WidgetTester tester, {String value = '1'}) async {
  final fields = find.byType(TextFormField);
  final count = fields.evaluate().length;
  for (var i = 0; i < count; i++) {
    final field = fields.at(i);
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    final text = tester.widget<EditableText>(editable).controller.text;
    if (text.trim().isEmpty) {
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }
  }
  final done = find.byType(RadioListTile<bool>).first;
  await tester.ensureVisible(done);
  await tester.tap(done);
  await tester.pump();
}
