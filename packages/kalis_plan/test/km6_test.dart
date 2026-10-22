// Lot KM6 (kalis_plan 0.4.3, DECISIONS_CP.md C17.47) :
// 1. crédits « chest » des tirages (`chestCreditRule`) ;
// 2. un test dont les séries font seules dépasser la rampe de volume d'un
//    groupe que les semaines d'avant ne travaillaient pas perd des
//    tentatives (jamais la dernière), et ce qu'il annonce suit : profil
//    aléatoire 3770 du chemin street (calisthénie avancée, squat de
//    compétition en semaine de test sans jambes avant), révélé par les
//    nouveaux crédits (le L-sit qui créditait les quadriceps n'est plus
//    choisi).
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();

  test(
    'crédits « chest » : tirages 0, muscle-up et pull-over une demi-série',
    () {
      final t = CatalogTraits.of(catalog);
      expect(t.of('sl-traction-lestee').creditOf(MuscleGroup.chest), 0);
      expect(
        t.of('mu-tirage-vertical-triangle').creditOf(MuscleGroup.chest),
        0,
      );
      expect(t.of('sl-muscle-up-leste').creditOf(MuscleGroup.chest), 1);
      expect(t.of('mu-pull-over-haltere').creditOf(MuscleGroup.chest), 1);
      expect(t.of('sl-dips-leste').creditOf(MuscleGroup.chest), 2);
      // Les autres groupes ne changent pas.
      expect(t.of('sl-traction-lestee').creditOf(MuscleGroup.lats), 2);
      expect(t.of('sl-muscle-up-leste').creditOf(MuscleGroup.triceps), 2);
    },
  );

  test('test de squat sans jambes avant : rampe tenue, tentatives dites', () {
    final request = randomCoachRequest(catalog, 3770, planSeed: 0);
    final engine = KalisPlan();
    final p1 = engine.createPass1(catalog, request);
    final p2 = engine.createPass2(
      catalog,
      Pass2Request(request: request, pass1: p1),
    );
    expect(
      coachAudit(catalog, request.profile, request.startDate, [
        ProgramBlock(pass1: p1, pass2: p2),
      ]),
      isEmpty,
    );
    var vus = 0;
    for (final w in p2.weeks) {
      for (final d in w.days) {
        for (final it in d.items) {
          if (it.exerciseId != 'sl-squat-competition' ||
              it.kind != SetKind.test) {
            continue;
          }
          vus++;
          final tries = it.test?.attempts;
          expect(tries == null || tries <= it.sets, isTrue);
          for (final r in it.reasons) {
            expect(r.params['note'], isNot('attempts_plan'));
          }
        }
      }
    }
    expect(vus, greaterThan(0));
    for (final v in p2.validate()) {
      fail('${v.path} ${v.code}');
    }
  });
}
