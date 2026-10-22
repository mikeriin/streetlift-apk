// RV2 (zone m) : provisoire, suites voisines lancées par le contrôle
// rapide (à retirer avant le dernier commit).
import 'package:flutter_test/flutter_test.dart';

import 'rv1_revue_test.dart' as v0;
import 'rv1c1_chronos_test.dart' as v1;
import 'kb1_koach105_test.dart' as v2;
import 'kb2_prise_de_main_test.dart' as v3;
import 'kb2c1_popup_test.dart' as v4;
import 'kb2c1_seance_servie_test.dart' as v5;
import 'kb3_koach106_test.dart' as v6;
import 'kb4_koach107_test.dart' as v7;

void main() {
  group('rv1_revue_test', v0.main);
  group('rv1c1_chronos_test', v1.main);
  group('kb1_koach105_test', v2.main);
  group('kb2_prise_de_main_test', v3.main);
  group('kb2c1_popup_test', v4.main);
  group('kb2c1_seance_servie_test', v5.main);
  group('kb3_koach106_test', v6.main);
  group('kb4_koach107_test', v7.main);
}
