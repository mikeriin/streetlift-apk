// Non-ressemblance au programme personnel du propriétaire (D4.1) : le
// moteur ne le lit pas, ses programmes lui ressemblent moins que ses propres
// blocs ne se ressemblent, et ses accessoires propres ne sont pas
// sur-représentés chez les profils sans discipline street.
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final owner = OwnerProgram.fromJson(
    readJsonObject('$corePath/test/fixtures/owner_program_v33.json.gz'),
  );
  final inspector = PlanInspector(catalog);

  test('le fichier du propriétaire est lu : semaines, exercices, blocs', () {
    expect(owner.weeks.length, greaterThanOrEqualTo(36));
    expect(owner.exerciseIds.length, greaterThanOrEqualTo(40));
    expect(owner.accessories, isNotEmpty);
    for (final id in owner.exerciseIds) {
      expect(catalog.contains(id), isTrue, reason: id);
    }
  });

  test('le seuil est le premier décile de la ressemblance du programme avec '
      'lui-même', () {
    final self = owner.crossBlockResemblances();
    final p10 = self[((self.length - 1) * 0.10).round()];
    expect(p10, closeTo(ownerWeekResemblanceLimit, 0.01));
    // Le programme se ressemble bien plus à lui-même : médiane.
    expect(self[self.length ~/ 2], greaterThan(0.5));
  });

  test('aucun moteur ne lit le programme du propriétaire', () {
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('report.dart')) {
        continue;
      }
      final text = file.readAsStringSync();
      for (final word in <String>['v33', 'owner_program', 'OwnerProgram']) {
        expect(text.contains(word), isFalse, reason: '${file.path} : $word');
      }
    }
  });

  test('profils types, graines 0 à 3 : ressemblance sous le seuil', () {
    for (final fixture in loadProfiles()) {
      final engine = KalisPlan();
      for (var seed = 0; seed < 4; seed++) {
        final plan = engine.createPass1(
          catalog,
          requestFor(fixture.profile, seed: seed),
        );
        expect(
          owner.weekResemblance(planExerciseIds(plan)),
          lessThan(ownerWeekResemblanceLimit),
          reason: '${fixture.key}, graine $seed',
        );
      }
    }
  });

  test('600 profils aléatoires : ressemblance sous le seuil, aucun accessoire '
      'propre au propriétaire sur-représenté sans discipline street', () {
    final study = InclusionStudy();
    var worst = 0.0;
    for (var seed = 700000; seed < 700600; seed++) {
      final request = randomRequest(catalog, seed);
      final plan = KalisPlan().createPass1(catalog, request);
      final j = owner.weekResemblance(planExerciseIds(plan));
      if (j > worst) {
        worst = j;
      }
      if (isStreetFree(request.profile)) {
        study.add(inspector, request, plan);
      }
    }
    expect(worst, lessThan(ownerWeekResemblanceLimit));
    expect(study.plans, greaterThan(100));
    final findings = study.findings(catalog, owner);
    expect(findings.length, greaterThan(10));
    final over = <String>[
      for (final f in findings)
        if (f.ownerSpecific && f.overRepresented)
          '${f.exerciseId} ${f.rate} (pair ${f.bestPeerId} ${f.bestPeerRate})',
    ];
    expect(over, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
