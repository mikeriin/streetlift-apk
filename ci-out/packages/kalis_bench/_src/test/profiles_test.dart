// Profils du banc : format, nombre, adaptateur vers le profil des moteurs.
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final catalog = loadCatalog();
  final profiles = loadBenchProfiles();

  test('au moins 16 profils street et 10 des autres disciplines', () {
    expect(
      profiles.where((p) => p.group == 'street').length,
      greaterThanOrEqualTo(16),
    );
    expect(
      profiles.where((p) => p.group == 'autres').length,
      greaterThanOrEqualTo(10),
    );
    expect(<String>{for (final p in profiles) p.key}.length, profiles.length);
  });

  test('chaque profil a des attentes de coach, écrites et vérifiables', () {
    for (final p in profiles) {
      expect(p.expectations.length, greaterThanOrEqualTo(3), reason: p.key);
      expect(p.checks.length, greaterThanOrEqualTo(4), reason: p.key);
      for (final c in p.checks) {
        expect(checkTypes, contains(c.type), reason: '${p.key} ${c.id}');
        expect(c.label, isNotEmpty);
      }
      expect(
        <String>{for (final c in p.checks) c.id}.length,
        p.checks.length,
        reason: p.key,
      );
    }
  });

  test('adaptateur : profil valide du contrat et connu du catalogue', () {
    for (final p in profiles) {
      final adapted = adaptProfile(p);
      expect(adapted.profile.validate(), isEmpty, reason: p.key);
      expect(catalog.checkProfile(adapted.profile), isEmpty, reason: p.key);
      expect(adapted.profile.createdOn, benchStartDate);
      for (final code in adapted.lost) {
        expect(lostFieldLabels, contains(code), reason: p.key);
      }
    }
  });

  test('adaptateur : records, échéances, gênes', () {
    final p = benchProfileOf('street_07_avance_streetlifting_competition');
    final a = adaptProfile(p).profile;
    final level = a.movementLevels.firstWhere(
      (m) => m.exerciseId == 'sl-traction-lestee',
    );
    expect(level.known, isTrue);
    expect(level.low, 60);
    expect(level.high, 60);
    expect(level.measure, LevelMeasure.oneRmKg);
    final goals = a.goals.where((g) => g.kind == GoalKind.performance).toList();
    expect(goals.length, 4);
    for (final g in goals) {
      // Samedi de la douzième semaine.
      expect(g.targetDate, benchStartDate.addDays(7 * 12 - 2));
      expect(g.targetDate!.weekday, 6);
    }
    expect(horizonOf(p), 12);

    final hurt = benchProfileOf('street_12_antecedent_coude');
    final limitation = adaptProfile(hurt).profile.limitations.single;
    expect(limitation.zone, BodyZone.elbow);
    expect(limitation.discomfort, 3);
    expect(hurt.injuries.single.catalogJoint, Joint.elbow);

    final multi = benchProfileOf('autres_10_contraintes_multiples');
    final adapted = adaptProfile(multi);
    // L'antécédent sans gêne actuelle n'a pas de place dans le profil v2.
    expect(adapted.profile.limitations.length, 1);
    expect(adapted.lost, contains('injury_history'));
    expect(adapted.lost, contains('sleep'));
    expect(adapted.lost, contains('break'));
  });

  test('adaptateur : record nul et niveau inconnu', () {
    final beginner = benchProfileOf('street_01_debutant_complet');
    final a = adaptProfile(beginner).profile;
    final pull = a.movementLevels.firstWhere(
      (m) => m.exerciseId == 'sw-traction-pronation',
    );
    expect(pull.known, isTrue);
    expect(pull.low, 0);
    final unknown = adaptProfile(
      benchProfileOf('autres_01_debutant_musculation'),
    ).profile.movementLevels;
    expect(unknown.every((m) => !m.known && m.low == null), isTrue);
  });

  test('horizon : échéance, objectif daté, défaut', () {
    expect(
      horizonOf(benchProfileOf('street_08_avance_sets_reps_competition')),
      8,
    );
    expect(horizonOf(benchProfileOf('street_10_elite_figures')), 16);
    expect(
      horizonOf(benchProfileOf('street_02_debutant_surpoids')),
      defaultHorizonWeeks,
    );
  });

  test('profil mal formé : erreur de format', () {
    expect(
      () => BenchProfile.fromJson(<String, Object?>{'schemaVersion': 2}),
      throwsFormatException,
    );
    expect(
      () => BenchProfile.fromJson(<String, Object?>{
        'schemaVersion': 1,
        'key': 'x',
        'group': 'ailleurs',
      }),
      throwsFormatException,
    );
  });

  test('le profil élite de streetlifting diffère de celui du propriétaire', () {
    final elite = benchProfileOf('street_09_elite_streetlifting');
    final owner = readJsonObject('$corePath/test/fixtures/profiles.json');
    Map<String, Object?>? ownerProfile;
    for (final f in owner['profiles']! as List<Object?>) {
      final fixture = f! as Map<String, Object?>;
      if (fixture['key'] == 'proprietaire_streetlifting_avance') {
        ownerProfile = fixture['profile']! as Map<String, Object?>;
      }
    }
    expect(ownerProfile, isNotNull);
    expect(elite.bodyWeightKg, isNot(ownerProfile!['bodyWeightKg']));
    for (final l in ownerProfile['movementLevels']! as List<Object?>) {
      final level = l! as Map<String, Object?>;
      final record = elite.recordOf(level['exerciseId']! as String);
      if (record != null) {
        expect(record.value, greaterThan((level['high']! as num).toDouble()));
      }
    }
  });
}
