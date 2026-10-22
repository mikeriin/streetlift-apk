// RV2 (zone k) : provisoire : suites voisines de Koach lancées par le
// contrôle rapide (retiré avant le dernier commit).
import 'package:flutter_test/flutter_test.dart';

import 'kb1_koach105_test.dart' as kb1;
import 'kb2_prise_de_main_test.dart' as kb2;
import 'kb2c1_popup_test.dart' as kb2c1p;
import 'kb2c1_seance_servie_test.dart' as kb2c1s;
import 'kb3_koach106_test.dart' as kb3;
import 'kb4_koach107_test.dart' as kb4;
import 'km3_koach_test.dart' as km3;
import 'km3_seance_ecran_test.dart' as km3e;
import 'rv1_revue_test.dart' as rv1;
import 'rv1c1_chronos_test.dart' as rv1c1;

void main() {
  group('kb1', kb1.main);
  group('kb2', kb2.main);
  group('kb2c1p', kb2c1p.main);
  group('kb2c1s', kb2c1s.main);
  group('kb3', kb3.main);
  group('kb4', kb4.main);
  group('km3', km3.main);
  group('km3e', km3e.main);
  group('rv1', rv1.main);
  group('rv1c1', rv1c1.main);
}
