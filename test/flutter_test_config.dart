// KB2 (dev7.2.1, DECISIONS_CP.md C17.34) : la bascule de Koach est ouverte
// dans le build (`kKoachBasculeAutorisee`). Les tests des lots d'avant
// décrivent le moteur d'avant (repli de l'arrêt d'urgence et des
// programmes que Koach ne conduit pas) : ils tournent bascule fermée,
// comme à leur lot. Les tests de KB2 (`test/kb2_prise_de_main_test.dart`)
// l'ouvrent eux-mêmes (`debugKoachBasculeAutorisee = true`).
import 'dart:async';

import 'package:streetlift_tracker/store.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugKoachBasculeAutorisee = false;
  await testMain();
}
