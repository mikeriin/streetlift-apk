// RV2 (zone m) : provisoire, suites voisines lancées par le contrôle
// rapide (à retirer avant le dernier commit).
import 'package:flutter_test/flutter_test.dart';

import 'l2_persistence_test.dart' as v0;
import 'l2b_data_control_test.dart' as v1;
import 'g2_retrait_test.dart' as v2;
import 'ui5_installation_test.dart' as v4;
import 'bv11_base_test.dart' as v5;

void main() {
  group('l2_persistence_test', v0.main);
  group('l2b_data_control_test', v1.main);
  group('g2_retrait_test', v2.main);
  group('ui5_installation_test', v4.main);
  group('bv11_base_test', v5.main);
}
