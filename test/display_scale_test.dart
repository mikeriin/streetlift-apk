// 6.13.0 — taille d'affichage (Réglages › Apparence) : écran virtuel mis à
// l’échelle, gestes au bon endroit, réglage enregistré seulement s’il change.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/kit/kit.dart';
import 'package:streetlift_tracker/store.dart';

void main() {
  testWidgets('échelle 0,8 : écran virtuel, appui au bon endroit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Size? inside;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KDisplayScale(scale: .8, child: child!),
        home: Builder(
          builder: (context) {
            inside = MediaQuery.sizeOf(context);
            return Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                key: const ValueKey('cible'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(width: 100, height: 100),
              ),
            );
          },
        ),
      ),
    );
    expect(inside, const Size(500, 1000));
    // Cible de 100 × 100 virtuels : 80 × 80 à l'écran, dans le coin.
    final rect = tester.getRect(find.byKey(const ValueKey('cible')));
    expect(rect.width, closeTo(80, .01));
    expect(rect.bottomRight.dx, closeTo(400, .01));
    await tester.tap(find.byKey(const ValueKey('cible')));
    expect(taps, 1);
  });

  testWidgets('100 % : rien n’est ajouté', (tester) async {
    await tester.pumpWidget(
      const KDisplayScale(scale: 1, child: SizedBox(key: ValueKey('x'))),
    );
    expect(find.byType(FittedBox), findsNothing);
  });

  test('réglage : 100 non écrit, valeur inconnue relue à 100', () {
    expect(AppSettings().toJson().containsKey('displaySize'), isFalse);
    final s = AppSettings()..displaySize = 90;
    expect(s.toJson()['displaySize'], 90);
    expect(AppSettings.fromJson(s.toJson()).displaySize, 90);
    expect(AppSettings.fromJson({'displaySize': 73}).displaySize, 100);
    expect(AppSettings.fromJson({'displaySize': '90'}).displaySize, 100);
  });
}
