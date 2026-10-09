// Mode saisons (0.2.0, lot CX) : scénarios imposés, durée des saisons,
// campagne croisée et saison réalisée.
import 'dart:io';

import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

List<Map<String, Object?>> _street() {
  final paths = <String>[
    for (final f in Directory('profiles').listSync())
      if (f is File && f.path.endsWith('.json')) f.path,
  ]..sort();
  return <Map<String, Object?>>[
    for (final path in paths)
      if (readJsonObject(path)['group'] == 'street') readJsonObject(path),
  ];
}

void main() {
  final street = _street();

  test('les dix scénarios imposés, codes uniques', () {
    expect(SeasonScenario.values.map((s) => s.code).toList(), <String>[
      'reference',
      'seances_manquees',
      'maladie',
      'douleur_coude',
      'douleur_epaule',
      'parc_seulement',
      'echeance_avancee',
      'deuxieme_echeance',
      'changement_discipline',
      'course_ajoutee',
    ]);
  });

  test('scénarios de CY : changement de discipline à mi-saison (profils à '
      'discipline secondaire), course ajoutée au profil street hybride', () {
    final catalog = loadCatalog();
    final hybrid = street.where(
      (j) => seasonScenarioApplies(j, SeasonScenario.race),
    );
    expect(hybrid.map((j) => j['key']), <Object?>[
      'street_17_hybride_street_course',
    ]);
    final json = hybrid.single;
    final profile = adaptProfile(
      BenchProfile.fromJson(json),
      catalog: catalog,
    ).profile;
    final race = seasonChanges(json, SeasonScenario.race).single;
    expect(race.week, seasonAddedRaceAnnounce);
    final raced = race.apply(profile);
    expect(
      raced.events!.where((e) => e.kind == EventKind.race).map((e) => e.date),
      contains(eventDate(benchStartDate, seasonAddedRaceWeek)),
    );
    expect(raced.validate(), isEmpty);
    final change = seasonChanges(json, SeasonScenario.discipline).single;
    final swapped = change.apply(profile);
    expect(swapped.disciplines.primary, TrainingDiscipline.cardio);
    expect(
      swapped.disciplines.secondaries.first.discipline,
      TrainingDiscipline.streetWorkout,
    );
    expect(swapped.validate(), isEmpty);
    // Profil au mode street : le dosage reste l'image du mode street.
    for (final j in street) {
      if (!seasonScenarioApplies(j, SeasonScenario.discipline)) {
        continue;
      }
      final p = adaptProfile(BenchProfile.fromJson(j), catalog: catalog).profile;
      final moved = seasonChanges(j, SeasonScenario.discipline).single.apply(p);
      expect(moved.validate(), isEmpty, reason: '${j['key']}');
      expect(
        moved.disciplines.primary,
        p.disciplines.secondaries.first.discipline,
        reason: '${j['key']}',
      );
    }
    expect(
      change.week,
      seasonDisciplineWeek(
        seasonWeeksOf(json, SeasonScenario.discipline),
      ),
    );
  });

  test('saisons de 16 semaines au moins, jusqu\'à une semaine après '
      'l\'échéance', () {
    expect(street, hasLength(17));
    for (final json in street) {
      final key = json['key'];
      final target = seasonTargetWeeks(json);
      for (final scenario in SeasonScenario.values) {
        if (!seasonScenarioApplies(json, scenario)) {
          continue;
        }
        final weeks = seasonWeeksOf(json, scenario);
        expect(weeks, greaterThanOrEqualTo(16), reason: '$key');
        if (target != null) {
          expect(weeks, greaterThan(target), reason: '$key');
        }
      }
      if (target != null && target >= 6) {
        // Échéance avancée : deux semaines plus tôt, apprise en cours de
        // saison.
        expect(
          seasonTargetWeeks(seasonProfileJson(json, SeasonScenario.earlier)),
          target - 2,
          reason: '$key',
        );
        final changes = seasonChanges(json, SeasonScenario.earlier);
        expect(changes, hasLength(1), reason: '$key');
        // Le changement avance bien l'échéance du profil des moteurs.
        final profile = adaptProfile(
          BenchProfile.fromJson(json),
          catalog: loadCatalog(),
        ).profile;
        final from = eventDate(benchStartDate, target);
        final moved = changes.single.apply(profile);
        final before = <String>[
          for (final e in profile.events ?? const <SeasonEvent>[]) e.date.iso,
        ];
        final after = <String>[
          for (final e in moved.events ?? const <SeasonEvent>[]) e.date.iso,
        ];
        if (before.contains(from.iso)) {
          expect(after, contains(from.addDays(-14).iso), reason: '$key');
          expect(after, isNot(contains(from.iso)), reason: '$key');
        }
      }
      expect(seasonChanges(json, SeasonScenario.base), isEmpty);
    }
  });

  test('campagne d\'une saison : couples cx et 0.1, trois vérités, '
      'scénario réservé au couple cx', () {
    final catalog = loadCatalog();
    final json = street.firstWhere(
      (j) => j['key'] == 'street_08_avance_sets_reps_competition',
    );
    final out = seasonCampaignOf(
      catalog,
      KalisPlan(),
      json,
      seeds: 1,
      scenarios: const <SeasonScenario>[
        SeasonScenario.base,
        SeasonScenario.earlier,
      ],
    );
    final scenarios = out['scenarios']! as Map<String, Object?>;
    final base = scenarios['reference']! as Map<String, Object?>;
    final couples = base['couples']! as Map<String, Object?>;
    expect(couples.keys, containsAll(<String>['cx', 'v01']));
    for (final couple in couples.values) {
      expect(
        (couple! as Map<String, Object?>).keys,
        containsAll(<String>['a', 'b', 'c']),
      );
    }
    final earlier = scenarios['echeance_avancee']! as Map<String, Object?>;
    expect((earlier['couples']! as Map<String, Object?>).keys, <String>['cx']);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
