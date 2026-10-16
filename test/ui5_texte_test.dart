// UI5 (refonte UI, R9) : libellés internes des consignes du programme
// affichés sous le nom de la page de l'application.
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/kit/kit.dart';

void main() {
  test('« feuille Pilotage » affichée « Mes références »', () {
    expect(
      contentText('+5 kg sur le 1RM de la feuille Pilotage (muscle-up).'),
      '+5 kg sur le 1RM de Mes références (muscle-up).',
    );
    expect(contentText('Voir la feuille Pilotage.'), 'Voir Mes références.');
    expect(contentText('Squat lourd, 5 × 4.'), 'Squat lourd, 5 × 4.');
  });
}
