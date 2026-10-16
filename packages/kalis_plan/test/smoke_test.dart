// Les 40 profils types : chaque étape rend une valeur valide du contrat et
// respecte les contraintes dures.
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final engine = KalisPlan();
  final inspector = PlanInspector(catalog);

  test('les 40 profils types : passe 1, revue, passe 2 sans violation', () {
    final profiles = loadProfiles();
    expect(profiles.length, 40);
    for (final fixture in profiles) {
      final c = runProfileCase(catalog, engine, fixture);
      expect(c.violations, isEmpty, reason: fixture.key);
      expect(
        inspector.scoreOf(requestFor(fixture.profile), c.pass1).toJson(),
        c.pass1.score.toJson(),
        reason: '${fixture.key} : note relue',
      );
      expect(c.pass1.days.length, fixture.profile.availability.length);
      for (final day in c.pass1.days) {
        expect(day.slots, isNotEmpty, reason: '${fixture.key} jour vide');
        expect(FocusCodes.all, contains(day.focus));
      }
      expect(c.pass2.weeks.length, c.reviewed.weeks);
      expect(c.reviewed.weeks, inInclusiveRange(4, 6));
    }
  });
}
