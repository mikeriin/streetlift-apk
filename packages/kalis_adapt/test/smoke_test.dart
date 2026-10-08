// Bout en bout : chaque athlète simulé suit son programme sous
// `kalis_adapt`, boucle complète ; toutes les sorties sont valides et les
// invariants de sécurité tiennent.
import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();

  for (final spec in simAthletes) {
    test('${spec.key} : 8 semaines en boucle complète', () {
      final engine = KalisAdapt();
      final policy = CheckedPolicy(engine);
      final run = simulate(
        catalog: catalog,
        spec: spec,
        profile: profileOf(spec.profileKey),
        seed: 1,
        policy: policy,
        program: programOf(spec.profileKey),
        weeks: 8,
        loop: engine,
      );
      expect(policy.violations, isEmpty);
      expect(run.sessionsDone, greaterThan(4));
      expect(run.sets, isNotEmpty);
      expect(policy.sessions, run.sessionsDone);
    });
  }
}
