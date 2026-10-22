// Lot KS1c1 : sécurité des saisons des profils ajoutés et du profil
// `street_12` (changement de discipline), graine 0, modèle de vérité B —
// les cas des violations relevées par KS1 (`LIVRAISON_KS1.md` § 3.4).
import 'dart:io';

import 'package:kalis_adapt/simulation.dart' show TruthKind, athleteFromJson;
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

/// Saison réalisée (vérité B, graine 0) du profil [json] sous [scenario] :
/// constats de sécurité et simulation.
(List<Finding>, Trajectory) _season(
  Catalog catalog,
  Map<String, Object?> json,
  SeasonScenario scenario,
) {
  final scenarioJson = seasonProfileJson(json, scenario);
  final bench = BenchProfile.fromJson(scenarioJson);
  final adapted = adaptProfile(
    BenchProfile.fromJson(
      scenario == SeasonScenario.second ? scenarioJson : json,
    ),
    catalog: catalog,
  );
  final weeks = seasonWeeksOf(json, scenario);
  final main = simulateTrajectory(
    catalog,
    KalisPlan(),
    bench,
    adapted.profile,
    weeks: weeks,
    truth: TruthKind.b,
    spec: athleteFromJson(seasonSpecJson(bench, scenario)),
    changes: seasonChanges(json, scenario),
  );
  final view = ProgramView(
    catalog,
    BenchProgram(
      bench: bench,
      adapted: adapted,
      request: PlanRequest(
        profile: adapted.profile,
        seed: 0,
        startDate: benchStartDate,
        locks: const <PlanLock>[],
      ),
      blocks: servedBlocksOf(main.run),
      horizonWeeks: weeks,
    ),
  );
  return (safetyFindings(view, bench), main);
}

void main() {
  final catalog = loadCatalog();
  Map<String, Object?> profile(String dir, String key) =>
      readJsonObject('$dir/$key.json');

  test('échéance avancée : plus de hausse de charge après la réécriture du '
      'bloc (ks_01 à ks_03 ; KS1 : 4 violations, 0.3.1 : 4)', () {
    for (final key in const <String>[
      'ks_01_streetlifting_sets_reps_4_seances',
      'ks_02_streetlifting_sets_reps_5_seances',
      'ks_03_streetlifting_sets_reps_6_seances',
    ]) {
      final (found, _) = _season(
        catalog,
        profile('profiles_ks', key),
        SeasonScenario.earlier,
      );
      expect(found, isEmpty, reason: key);
    }
  });

  test('changement de discipline à mi-saison : plus de hausse de charge '
      'après la réécriture du bloc (street_12 ; KS1 : 2 violations)', () {
    final (found, _) = _season(
      catalog,
      profile('profiles', 'street_12_antecedent_coude'),
      SeasonScenario.discipline,
    );
    expect(found, isEmpty);
  });

  test('profil de test, douleur à l\'épaule : les violations qui restent '
      'suivent toutes une proposition « volume » appliquée par le moteur '
      'd\'évolution dans le même bloc (cause hors de kalis_plan, '
      'LIVRAISON_KS1c1.md § 3)', () {
    final (found, main) = _season(
      catalog,
      profile('profiles_ks', 'ks_test_ppl6'),
      SeasonScenario.shoulder,
    );
    final starts = main.run.blockWeeks;
    // Résidu documenté : tant que le moteur d'évolution ne borne pas ses
    // propositions « volume » par la rampe du groupe, ces violations
    // restent ; quand il le fera, ce test est à mettre à jour (plus de
    // violation attendue).
    expect(found, isNotEmpty);
    for (final f in found) {
      expect(f.code, 'volume_trop_vite', reason: f.message);
      final week = f.week!;
      var blockStart = 0;
      for (final s in starts) {
        if (s <= week) {
          blockStart = s;
        }
      }
      // Propositions « volume » appliquées dans le bloc avant la semaine
      // en cause, qui ont changé au moins une prescription.
      final applied = main.run.proposals.where(
        (p) =>
            p.kind == ProposalKind.volume &&
            p.changes > 0 &&
            p.week >= blockStart &&
            p.week < week,
      );
      expect(applied, isNotEmpty, reason: f.message);
    }
  });

  test('tous les profils ajoutés, tous les scénarios : seules restent les '
      'violations de volume du profil de test sous douleur à l\'épaule', () {
    final paths = <String>[
      for (final f in Directory('profiles_ks').listSync())
        if (f is File && f.path.endsWith('.json')) f.path,
    ]..sort();
    final left = <String>[];
    for (final path in paths) {
      final json = readJsonObject(path);
      for (final scenario in SeasonScenario.values) {
        if (!seasonScenarioApplies(json, scenario)) {
          continue;
        }
        final (found, _) = _season(catalog, json, scenario);
        for (final f in found) {
          left.add('${json['key']} ${scenario.code} ${f.code}');
        }
      }
    }
    expect(
      left.where(
        (l) => !l.startsWith('ks_test_ppl6 douleur_epaule volume_trop_vite'),
      ),
      isEmpty,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
