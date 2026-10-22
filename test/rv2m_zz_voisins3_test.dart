// RV2 (zone m) : provisoire, suites voisines lancées par le contrôle
// rapide (à retirer avant le dernier commit).
import 'package:flutter_test/flutter_test.dart';

import 'g10_charges_consigne_test.dart' as v0;
import 'g10_evolution_test.dart' as v1;
import 'g10_seance_sans_moteur_test.dart' as v3;
import 'ci1e_programme_40s_test.dart' as v4;
import 'l4_depart_test.dart' as v5;
import 'l5c_couleur_test.dart' as v6;
import 'programme_test.dart' as v7;
import 'redesign_test.dart' as v8;

void main() {
  group('g10_charges_consigne_test', v0.main);
  group('g10_evolution_test', v1.main);
  group('g10_seance_sans_moteur_test', v3.main);
  group('ci1e_programme_40s_test', v4.main);
  group('l4_depart_test', v5.main);
  group('l5c_couleur_test', v6.main);
  group('programme_test', v7.main);
  group('redesign_test', v8.main);
}
