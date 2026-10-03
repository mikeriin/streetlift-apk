// Relecture indépendante de deux règles d'admission : le mode prudent et
// les exercices réservés. Les règles sont réécrites ici à partir du texte
// de CONTRAT.md (§ 3.2) et des seuls champs du catalogue, sans passer par
// le vivier du moteur (`PlanContext`) : une erreur dans la règle du moteur
// ferait échouer ce test.
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

bool _prudent(PlanRequest request) {
  final profile = request.profile;
  final age = request.startDate.year - profile.birthYear;
  final outcome = profile.healthScreening?.outcome;
  return outcome != HealthScreeningOutcome.standard || age >= 65 || age < 18;
}

bool _has(AthleteProfile profile, TrainingDiscipline discipline) =>
    profile.disciplines.primary == discipline ||
    profile.disciplines.secondaries.any((s) => s.discipline == discipline);

/// Ce que le mode prudent interdit (impact, course, fatigue maximale).
String? _forbiddenWhenPrudent(CatalogExercise e) {
  const impact = <MovementPattern>{
    MovementPattern.pliometrie,
    MovementPattern.sprint,
    MovementPattern.halterophilie,
    MovementPattern.cordeASauter,
  };
  if (impact.contains(e.pattern)) {
    return 'impact (${e.pattern.code})';
  }
  if (e.contractionMode == ContractionMode.explosive) {
    return 'explosif';
  }
  if (e.systemicFatigue >= 5) {
    return 'fatigue systémique ${e.systemicFatigue}';
  }
  if (e.discipline == CatalogDiscipline.cardio &&
      (e.jointStress[Joint.ankle] ?? JointStress.low) != JointStress.low) {
    return 'cardio avec appui contraignant pour la cheville';
  }
  return null;
}

/// Ce qui est réservé, pour un exercice ni su ni aimé, hors objectif.
String? _reserved(AthleteProfile profile, CatalogExercise e) {
  const explosive = <MovementPattern>{
    MovementPattern.halterophilie,
    MovementPattern.pliometrie,
    MovementPattern.balistique,
  };
  if (explosive.contains(e.pattern) &&
      !_has(profile, TrainingDiscipline.crossfit)) {
    return '${e.pattern.code} sans CrossFit';
  }
  if (e.family == MovementFamily.cou) {
    return 'travail direct du cou';
  }
  return null;
}

List<String> _check(Catalog catalog, PlanRequest request, Pass1Plan plan) {
  final out = <String>[];
  final profile = request.profile;
  final wanted = <String>{
    ...profile.likedExerciseIds,
    ...?profile.knownExerciseIds,
    for (final l in profile.movementLevels) l.exerciseId,
  };
  for (final day in plan.days) {
    for (final slot in day.slots) {
      final e = catalog.exercise(slot.exerciseId);
      if (_prudent(request)) {
        final why = _forbiddenWhenPrudent(e);
        if (why != null) {
          out.add('prudent : ${e.id} — $why');
        }
      }
      if (profile.goals.isEmpty && !wanted.contains(e.id)) {
        final why = _reserved(profile, e);
        if (why != null) {
          out.add('réservé : ${e.id} — $why');
        }
      }
    }
  }
  return out;
}

void main() {
  final catalog = loadCatalog();

  test('40 profils types, graines 0 à 2 : mode prudent et exercices réservés '
      'relus sans le vivier', () {
    var prudent = 0;
    for (final fixture in loadProfiles()) {
      final engine = KalisPlan();
      for (var seed = 0; seed < 3; seed++) {
        final request = requestFor(fixture.profile, seed: seed);
        if (seed == 0 && _prudent(request)) {
          prudent++;
        }
        final plan = engine.createPass1(catalog, request);
        expect(
          _check(catalog, request, plan),
          isEmpty,
          reason: '${fixture.key}, graine $seed',
        );
      }
    }
    expect(prudent, greaterThanOrEqualTo(5));
  });

  test('600 profils aléatoires : mode prudent et exercices réservés relus '
      'sans le vivier', () {
    final failures = <String>[];
    var prudent = 0;
    for (var seed = 800000; seed < 800600; seed++) {
      final request = randomRequest(catalog, seed);
      if (_prudent(request)) {
        prudent++;
      }
      final plan = KalisPlan().createPass1(catalog, request);
      for (final line in _check(catalog, request, plan)) {
        failures.add('profil $seed — $line');
      }
    }
    expect(failures.take(10).toList(), isEmpty);
    expect(prudent, greaterThan(100));
  }, timeout: const Timeout(Duration(minutes: 10)));
}
