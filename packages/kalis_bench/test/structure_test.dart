// Critères du lot KS1 (structure de la semaine, CAHIER_KS.md § 9) :
// fonctions de base et mesure du profil de test.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('exigence des mouvements de compétition (§ 11.2)', () {
    expect(structureDemand('sl-muscle-up-leste'), 4);
    expect(structureDemand('sl-traction-lestee'), 3);
    expect(structureDemand('sl-dips-leste'), 2);
    expect(structureDemand('sl-squat-competition'), 1);
    expect(structureDemand('sl-pompe'), 0);
  });

  test('schéma chargé des exercices du catalogue', () {
    final catalog = loadCatalog();
    expect(structureSchemaOf(catalog.exercise('sl-traction-lestee')), 'pull');
    expect(structureSchemaOf(catalog.exercise('sl-dips-leste')), 'push');
    expect(structureSchemaOf(catalog.exercise('sl-squat-competition')), 'legs');
  });

  group('profil de test ks_test_ppl6', () {
    late StructureMeasure m;
    setUpAll(() {
      final profile = BenchProfile.fromJson(
        readJsonObject('profiles_ks/$structureTestProfile.json'),
      );
      final catalog = loadCatalog();
      final program = generateProgram(
        catalog,
        KalisPlan(),
        profile,
        horizonWeeks: 40,
      );
      m = structureMeasureOf(catalog, program, profile);
    });

    test('gabarit ppl6_q à chaque bloc, aucune violation', () {
      expect(m.templates.toSet(), <String>{'ppl6_q'});
      expect(m.safety, 0);
      expect(m.uncovered, isEmpty);
    });

    test('récupération ≥ 0,9 à chaque bloc', () {
      for (final r in m.recoveryScore) {
        expect(r, greaterThanOrEqualTo(structureRecoveryFloor));
      }
    });

    test('contrôles du § 7 tenus (hors durée des séances, limite dite)', () {
      expect(m.testChecks, isNotEmpty);
      for (final e in m.testChecks.entries) {
        if (e.key.contains(' min ')) {
          continue;
        }
        expect(e.value, isTrue, reason: e.key);
      }
    });

    test('rapport : tableau des critères et JSON lisible', () {
      final files = structureReport(
        <StructureMeasure>[m],
        seasonViolations: 0,
      );
      expect(files.keys, containsAll(<String>['STRUCTURE.md', 'structure.json']));
      expect(files['STRUCTURE.md'], contains('ks_test_ppl6'));
      expect(jsonDecode(files['structure.json']!), isA<Map<String, Object?>>());
    });
  });

  test('profils ajoutés au banc (§ 9) lisibles', () {
    final keys = <String>[
      for (final f in Directory('profiles_ks').listSync())
        if (f is File && f.path.endsWith('.json'))
          BenchProfile.fromJson(readJsonObject(f.path)).key,
    ]..sort();
    expect(keys, hasLength(7));
    expect(keys, contains(structureTestProfile));
  });
}
