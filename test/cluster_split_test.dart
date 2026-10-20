// 6.15.0 — cluster : la cible de la série répartie en blocs, dans les mots
// de la ligne (« 3 reps en 2 blocs : 2 + 1 »).
import 'package:flutter_test/flutter_test.dart';
import 'package:streetlift_tracker/session_screen.dart' show clusterSplit;

void main() {
  test('répartition : les plus gros blocs d’abord, total gardé', () {
    expect(clusterSplit(3, 2), [2, 1]);
    expect(clusterSplit(6, 3), [2, 2, 2]);
    expect(clusterSplit(8, 3), [3, 3, 2]);
    expect(clusterSplit(1, 1), [1]);
  });

  test('cible plus petite que les blocs, ou nulle : un par bloc', () {
    expect(clusterSplit(1, 2), [1, 1]);
    expect(clusterSplit(5, 0), [5]);
  });
}
