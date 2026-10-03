// Parcours de questions du profil v3 (0.4.0) : arbre adaptatif, questions
// reportées, réponses obligatoires sous condition, nombre de questions vues
// par profil type, tests guidés.
@Timeout(Duration(minutes: 30))
library;

import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

const int samples = 10000;

/// Questions de récupération, reportées pour un débutant.
const List<String> recovery = <String>['sleep', 'stress', 'outside_load'];

/// Questions qui portent une condition de report (`deferWhen`) : les trois
/// de récupération et l'évolution voulue du poids, que seul un débutant
/// d'une discipline au poids du corps peut se voir reporter.
const List<String> deferrable = <String>[
  'sleep',
  'stress',
  'outside_load',
  'body_weight_goal',
];

/// Identifiants des dix tests guidés, dans l'ordre du fichier.
const List<String> testIds = <String>[
  't1_serie_lourde',
  't2_leste',
  't3_max_direct',
  't4_reps_max',
  't5_maintien_max',
  't6_course_6min',
  't7_course_chrono',
  't8_sans_test',
  't9_reps_temps',
  't10_series_repetees',
];

// Conditions du langage du parcours (`tool/parcours_spec.py`).

const Map<String, Object?> opAlways = <String, Object?>{'op': 'always'};

Map<String, Object?> opAll(List<Map<String, Object?>> children) {
  return <String, Object?>{'op': 'all', 'of': children};
}

Map<String, Object?> opAny(List<Map<String, Object?>> children) {
  return <String, Object?>{'op': 'any', 'of': children};
}

Map<String, Object?> opNot(Map<String, Object?> child) {
  return <String, Object?>{'op': 'not', 'of': child};
}

Map<String, Object?> opPresent(String path) {
  return <String, Object?>{'op': 'present', 'path': path};
}

Map<String, Object?> opIn(String path, List<Object?> values) {
  return <String, Object?>{'op': 'in', 'path': path, 'values': values};
}

Map<String, Object?> opAtLeast(String path, String scale, String value) {
  return <String, Object?>{
    'op': 'at_least',
    'path': path,
    'scale': scale,
    'value': value,
  };
}

Map<String, Object?> opMinNumber(String path, num value) {
  return <String, Object?>{'op': 'min_number', 'path': path, 'value': value};
}

Map<String, Object?> opAge(int value) {
  return <String, Object?>{'op': 'age_at_least', 'value': value};
}

/// Champ `disciplines` : une principale et des secondaires à 10 % chacune.
Map<String, Object?> mix(
  String primary, [
  List<String> others = const <String>[],
]) {
  return <String, Object?>{
    'disciplines': <String, Object?>{
      'primary': primary,
      'primaryPct': 100 - 10 * others.length,
      'secondaries': <Object?>[
        for (final other in others)
          <String, Object?>{'discipline': other, 'pct': 10},
      ],
    },
  };
}

/// Champs `streetMode` et `disciplines` d'un profil en mode street.
Map<String, Object?> street(
  StreetStyle primary,
  int streetliftingPct,
  int setsRepsPct,
  int calisthenicsPct,
) {
  final mode = StreetMode(
    primary: primary,
    streetliftingPct: streetliftingPct,
    setsRepsPct: setsRepsPct,
    calisthenicsPct: calisthenicsPct,
  );
  return <String, Object?>{
    'streetMode': mode.toJson(),
    'disciplines': mode.toDisciplineMix().toJson(),
  };
}

void main() {
  final parcoursJson = readJsonObject('data/parcours_v3.json');
  final parcours = ProfileQuestionnaire.fromJson(parcoursJson);
  final fixtures = readJsonObject('test/fixtures/profiles_v3.json');
  final todayYear = fixtures['todayYear']! as int;
  final v3 = <String, Map<String, Object?>>{
    for (final item
        in (fixtures['profiles']! as List<Object?>)
            .cast<Map<String, Object?>>())
      item['key']! as String: item,
  };
  final v2Profiles = readProfileFixtures(
    readJsonObject('test/fixtures/profiles.json'),
  );
  final order = <String>[for (final q in parcours.questions) q.id];

  List<String> idsOf(List<ProfileQuestion> questions) {
    return <String>[for (final q in questions) q.id];
  }

  List<String> seen(
    Map<String, Object?> profile, {
    int since = 2,
    bool includeDeferred = false,
  }) {
    return idsOf(
      parcours.visibleQuestions(
        profile,
        todayYear: todayYear,
        since: since,
        includeDeferred: includeDeferred,
      ),
    );
  }

  List<String> deferred(Map<String, Object?> profile) {
    return idsOf(parcours.deferredQuestions(profile, todayYear: todayYear));
  }

  List<String> testsOf(Map<String, Object?> profile) {
    return <String>[
      for (final t in parcours.eligibleTests(profile, todayYear: todayYear))
        t.id,
    ];
  }

  Map<String, Object?> profileOf(String key) {
    return v3[key]!['profile']! as Map<String, Object?>;
  }

  bool holds(Map<String, Object?> condition, Map<String, Object?> profile) {
    return parcours.evaluate(condition, profile, todayYear: todayYear);
  }

  test('le fichier se charge : version, écrans, questions, tests', () {
    expect(parcours.version, kalisCoreVersion);
    expect(parcours.screens, hasLength(14));
    expect(parcours.questions, hasLength(31));
    expect(parcours.questions.where((q) => q.since == 2), hasLength(17));
    expect(parcours.questions.where((q) => q.since == 3), hasLength(14));
    expect(parcours.tests, hasLength(10));
    expect(parcours.rulesetPresets, isNotEmpty);
    final screens = <String>{
      for (final s in parcours.screens) s['id']! as String,
    };
    for (final q in parcours.questions) {
      expect(screens, contains(q.screen), reason: q.id);
      expect(q.text, isNotEmpty, reason: q.id);
      expect(q.fields, isNotEmpty, reason: q.id);
      expect(q.since == 2 || q.since == 3, isTrue, reason: q.id);
      expect(q.json['id'], q.id, reason: q.id);
      if (q.required) {
        expect(q.skip || q.unknown, isFalse, reason: q.id);
      }
      if (q.kind == 'choice' || q.kind == 'multi') {
        expect(q.options, isNotEmpty, reason: q.id);
      }
      // Une question reportée n'est jamais obligatoire.
      if (q.deferWhen != null) {
        expect(q.required, isFalse, reason: q.id);
        expect(q.requiredWhen, isNull, reason: q.id);
      }
    }
    expect(parcours.question('sleep')!.fields, <String>['sleep']);
    expect(parcours.question('inconnue'), isNull);
    expect(<String>[
      for (final q in parcours.questions)
        if (q.deferWhen != null) q.id,
    ], deferrable);
    expect(
      <String>[
        for (final q in parcours.questions)
          if (q.requiredWhen != null) q.id,
      ],
      <String>['body_weight'],
    );
  });

  test('les questions suivent l\'ordre des écrans', () {
    final screenOrder = <String>[
      for (final s in parcours.screens) s['id']! as String,
    ];
    var last = 0;
    for (final q in parcours.questions) {
      final at = screenOrder.indexOf(q.screen);
      expect(at, greaterThanOrEqualTo(last), reason: q.id);
      last = at;
    }
  });

  test('l\'ordre des questions est celui du fichier', () {
    final fileOrder = <String>[
      for (final q
          in (parcoursJson['questions']! as List<Object?>)
              .cast<Map<String, Object?>>())
        q['id']! as String,
    ];
    expect(order, fileOrder);
    expect(order.toSet(), hasLength(order.length));
    // Les records sont demandés avant les fourchettes, les points faibles
    // après les records.
    expect(
      order.indexOf('benchmarks'),
      lessThan(order.indexOf('movement_levels')),
    );
    expect(order.indexOf('benchmarks'), lessThan(order.indexOf('weak_points')));
    // Quel que soit le profil, les questions rendues gardent cet ordre.
    for (final key in v3.keys) {
      final profile = profileOf(key);
      for (final ids in <List<String>>[
        seen(profile),
        seen(profile, includeDeferred: true),
        seen(profile, since: 3, includeDeferred: true),
        deferred(profile),
      ]) {
        expect(ids, <String>[
          for (final id in order)
            if (ids.contains(id)) id,
        ], reason: key);
      }
    }
  });

  test('les réponses à choix du schéma 3 sont les codes du contrat', () {
    void same(String id, List<String> codes) {
      expect(
        parcours.question(id)!.options.map((o) => o.code).toList(),
        codes,
        reason: id,
      );
    }

    same('training_age', <String>[for (final v in TrainingAge.values) v.code]);
    same('training_gap', <String>[for (final v in TrainingGap.values) v.code]);
    same('sleep', <String>[for (final v in SleepBand.values) v.code]);
    same('stress', <String>[for (final v in StressBand.values) v.code]);
    same('emphasis', <String>[for (final v in TrainingEmphasis.values) v.code]);
    same('body_weight_goal', <String>[
      for (final v in BodyWeightGoal.values) v.code,
    ]);
    same('experience_level', <String>[
      for (final v in ExperienceLevel.values) v.code,
    ]);
    expect(parcours.scales['experience'], <String>[
      for (final v in ExperienceLevel.values) v.code,
    ]);
    expect(parcours.scales['trainingAge'], <String>[
      for (final v in TrainingAge.values) v.code,
    ]);
    // Chaque protocole de test produit une nature de test du contrat.
    for (final t in parcours.tests) {
      final kind = t.benchmarkKind;
      if (kind != null) {
        expect(BenchmarkKind.fromCode(kind), isNotNull, reason: t.id);
        expect(TestKind.fromCode(t.testKind!), isNotNull, reason: t.id);
      }
    }
  });

  test('nombre de questions vues par profil type (oracle du générateur)', () {
    expect(v3.keys.toList(), <String>[
      'v3_debutant_forme_generale',
      'v3_intermediaire_musculation',
      'v3_competiteur_elite_streetlifting',
      'v3_coureuse_10km',
      'v3_sets_reps_avance',
    ]);
    for (final entry in v3.entries) {
      final profile = entry.value['profile']! as Map<String, Object?>;
      final expected = entry.value['expected']! as Map<String, Object?>;
      final ids = seen(profile);
      expect(ids, expected['questionIds'], reason: entry.key);
      expect(ids.length, expected['questions'], reason: entry.key);
      expect(
        seen(profile, since: 3).length,
        expected['newQuestions'],
        reason: entry.key,
      );
      final later = deferred(profile);
      expect(later, expected['deferredIds'], reason: entry.key);
      expect(testsOf(profile), expected['testIds'], reason: entry.key);
      // Avec les questions reportées : les mêmes, plus les reportées, dans
      // l'ordre du fichier.
      expect(seen(profile, includeDeferred: true), <String>[
        for (final id in order)
          if (ids.contains(id) || later.contains(id)) id,
      ], reason: entry.key);
      for (final id in later) {
        expect(ids, isNot(contains(id)), reason: '${entry.key} $id');
      }
      // Même résultat à partir du profil typé.
      final typed = AthleteProfile.fromJson(profile);
      expect(seen(typed.toJson()), ids, reason: entry.key);
      expect(deferred(typed.toJson()), later, reason: entry.key);
      expect(testsOf(typed.toJson()), testsOf(profile), reason: entry.key);
    }
  });

  test('repères du lot : questions à la création par profil type', () {
    // Profil type → [questions à la création, dont nouvelles (schéma 3)].
    const counts = <String, List<int>>{
      'v3_debutant_forme_generale': <int>[16, 0],
      'v3_intermediaire_musculation': <int>[27, 10],
      'v3_competiteur_elite_streetlifting': <int>[29, 12],
      'v3_coureuse_10km': <int>[28, 11],
      'v3_sets_reps_avance': <int>[29, 12],
    };
    for (final entry in counts.entries) {
      final profile = profileOf(entry.key);
      expect(seen(profile), hasLength(entry.value[0]), reason: entry.key);
      expect(
        seen(profile, since: 3),
        hasLength(entry.value[1]),
        reason: entry.key,
      );
    }
    final beginner = profileOf('v3_debutant_forme_generale');
    expect(deferred(beginner), recovery);
    expect(testsOf(beginner), <String>['t8_sans_test']);
    for (final key in counts.keys) {
      if (key != 'v3_debutant_forme_generale') {
        expect(deferred(profileOf(key)), isEmpty, reason: key);
      }
    }
  });

  test('un débutant voit peu de questions, un compétiteur les siennes', () {
    final beginnerProfile = profileOf('v3_debutant_forme_generale');
    final beginner = seen(beginnerProfile);
    final intermediate = seen(profileOf('v3_intermediaire_musculation'));
    final elite = seen(profileOf('v3_competiteur_elite_streetlifting'));
    expect(beginner.length, 16);
    expect(intermediate.length, 27);
    expect(elite.length, 29);
    expect(beginner.length, lessThan(intermediate.length));
    expect(intermediate.length, lessThan(elite.length));
    // À la création, le débutant ne voit aucune question nouvelle : son
    // parcours est celui d'un profil encore vide.
    expect(seen(beginnerProfile, since: 3), isEmpty);
    expect(beginner, seen(<String, Object?>{}));
    for (final id in beginner) {
      expect(parcours.question(id)!.since, 2, reason: id);
    }
    // Ses trois questions de récupération sont reportées, pas perdues.
    expect(deferred(beginnerProfile), recovery);
    expect(seen(beginnerProfile, since: 3, includeDeferred: true), recovery);
    expect(seen(beginnerProfile, includeDeferred: true), hasLength(19));
    for (final hidden in <String>[
      'training_age',
      'training_gap',
      'recent_training',
      'benchmarks',
      'skills',
      'emphasis',
      'events',
      'specialization',
      'weak_points',
      'running_base',
      'sleep',
      'stress',
      'outside_load',
      'body_weight_goal',
      'preferences',
    ]) {
      expect(beginner, isNot(contains(hidden)), reason: hidden);
    }
    expect(
      elite,
      containsAll(<String>[
        'training_age',
        'training_gap',
        'recent_training',
        'benchmarks',
        'skills',
        'events',
        'specialization',
        'weak_points',
        'sleep',
        'stress',
        'outside_load',
        'body_weight_goal',
        'preferences',
      ]),
    );
    // Tout ce que voit le débutant, les autres le voient aussi ; le
    // compétiteur voit tout ce que voit l'intermédiaire, sauf la question
    // propre à la musculation.
    expect(intermediate, containsAll(beginner));
    expect(elite, containsAll(beginner));
    expect(intermediate, contains('emphasis'));
    expect(elite, isNot(contains('emphasis')));
    expect(elite, containsAll(intermediate.where((id) => id != 'emphasis')));
  });

  test('questions reportées : hors de la création, rendues à part', () {
    final empty = <String, Object?>{};
    // Profil encore vide : 16 questions à la création, 19 avec les
    // reportées.
    expect(seen(empty), hasLength(16));
    expect(seen(empty, includeDeferred: true), hasLength(19));
    expect(deferred(empty), recovery);
    expect(seen(empty, since: 3), isEmpty);
    expect(seen(empty, since: 3, includeDeferred: true), recovery);
    for (final id in recovery) {
      expect(seen(empty), isNot(contains(id)), reason: id);
      expect(seen(empty, includeDeferred: true), contains(id), reason: id);
    }
    for (final q in parcours.questions) {
      expect(
        parcours.isDeferred(q, empty, todayYear: todayYear),
        deferrable.contains(q.id),
        reason: q.id,
      );
    }
    // Débutant déclaré : même report.
    final beginner = <String, Object?>{'experience': 'beginner'};
    expect(deferred(beginner), recovery);
    expect(seen(beginner), hasLength(16));
    expect(seen(beginner, includeDeferred: true), hasLength(19));
    // À partir du niveau intermédiaire : rien n'est reporté.
    for (final level in <String>['intermediate', 'advanced', 'elite']) {
      final profile = <String, Object?>{'experience': level};
      expect(deferred(profile), isEmpty, reason: level);
      expect(seen(profile), containsAll(recovery), reason: level);
      expect(
        seen(profile, includeDeferred: true),
        seen(profile),
        reason: level,
      );
      for (final q in parcours.questions) {
        expect(
          parcours.isDeferred(q, profile, todayYear: todayYear),
          isFalse,
          reason: '$level ${q.id}',
        );
      }
    }
  });

  test('réponse obligatoire : toujours, ou sous condition', () {
    final empty = <String, Object?>{};
    final bodyWeight = parcours.question('body_weight')!;
    expect(bodyWeight.required, isFalse);
    expect(bodyWeight.skip, isTrue);
    expect(bodyWeight.requiredWhen, isNotNull);
    bool needsWeight(Map<String, Object?> profile) {
      return parcours.isRequired(bodyWeight, profile, todayYear: todayYear);
    }

    // Profils types : obligatoire en mode street, pas ailleurs.
    final elite = profileOf('v3_competiteur_elite_streetlifting');
    expect(needsWeight(elite), isTrue);
    expect(needsWeight(profileOf('v3_sets_reps_avance')), isTrue);
    expect(needsWeight(profileOf('v3_debutant_forme_generale')), isFalse);
    expect(needsWeight(profileOf('v3_intermediaire_musculation')), isFalse);
    expect(needsWeight(profileOf('v3_coureuse_10km')), isFalse);
    expect(needsWeight(empty), isFalse);
    // Disciplines au poids du corps, en principale ou en secondaire.
    for (final code in <String>[
      'streetlifting',
      'street_workout',
      'calisthenics',
    ]) {
      expect(needsWeight(mix(code)), isTrue, reason: code);
      final secondary = mix('mobility', <String>[code]);
      expect(needsWeight(secondary), isTrue, reason: code);
    }
    for (final code in <String>[
      'musculation',
      'crossfit',
      'cardio',
      'mobility',
      'general_fitness',
    ]) {
      expect(needsWeight(mix(code)), isFalse, reason: code);
    }
    expect(needsWeight(street(StreetStyle.setsReps, 0, 100, 0)), isTrue);
    // Une question `required` l'est toujours ; les autres ne le sont
    // jamais sans condition.
    final profiles = <Map<String, Object?>>[
      empty,
      for (final key in v3.keys) profileOf(key),
    ];
    var mandatory = 0;
    for (final q in parcours.questions) {
      for (final profile in profiles) {
        final needed = parcours.isRequired(q, profile, todayYear: todayYear);
        if (q.required) {
          expect(needed, isTrue, reason: q.id);
        } else if (q.requiredWhen == null) {
          expect(needed, isFalse, reason: q.id);
        }
      }
      if (q.required) {
        mandatory++;
      }
    }
    expect(mandatory, 10);
  });

  test('chaque condition d\'apparition du parcours', () {
    final base = baseProfile().toJson()..remove('experience');
    // Profil neutre : aucune discipline ni objectif qui ouvre une question.
    final plain = <String, Object?>{
      ...base,
      ...mix('mobility'),
      'goals': <Object?>[],
    };
    Map<String, Object?> having(Map<String, Object?> changes) {
      return <String, Object?>{...plain, ...changes};
    }

    Map<String, Object?> level(String code) {
      return <String, Object?>{'experience': code};
    }

    // Sans réponse sur le niveau : parcours le plus court, celui d'un
    // profil vide.
    final shortest = seen(plain);
    expect(shortest, seen(<String, Object?>{}));
    expect(shortest, hasLength(16));
    for (final q in parcours.questions) {
      if (q.since == 3) {
        expect(shortest, isNot(contains(q.id)), reason: q.id);
      }
    }
    expect(shortest, isNot(contains('preferences')));
    expect(seen(having(level('beginner'))), shortest);

    // Niveau (échelle `experience`).
    for (final code in <String>['intermediate', 'advanced', 'elite']) {
      final ids = seen(having(level(code)));
      expect(
        ids,
        containsAll(<String>[
          'training_age',
          'benchmarks',
          'events',
          'sleep',
          'stress',
          'outside_load',
          'body_weight_goal',
          'preferences',
        ]),
        reason: code,
      );
      // À partir du niveau avancé seulement.
      expect(
        ids.contains('recent_training'),
        code != 'intermediate',
        reason: code,
      );
      expect(
        ids.contains('specialization'),
        code != 'intermediate',
        reason: code,
      );
      // Sans discipline de force : pas de points faibles.
      expect(ids, isNot(contains('weak_points')), reason: code);
      expect(ids, isNot(contains('training_gap')), reason: code);
    }

    // Ancienneté → interruption.
    expect(
      seen(having(<String, Object?>{'trainingAge': 'under_6_months'})),
      isNot(contains('training_gap')),
    );
    for (final age in <String>[
      'months_6_to_24',
      'years_2_to_5',
      'over_5_years',
    ]) {
      expect(
        seen(having(<String, Object?>{'trainingAge': age})),
        contains('training_gap'),
        reason: age,
      );
    }

    // Musculation : orientation ; spécialisation dès le niveau
    // intermédiaire.
    expect(seen(having(mix('musculation'))), contains('emphasis'));
    expect(
      seen(having(mix('cardio', <String>['musculation']))),
      contains('emphasis'),
    );
    expect(seen(having(mix('crossfit'))), isNot(contains('emphasis')));
    expect(
      seen(
        having(<String, Object?>{
          ...mix('musculation'),
          ...level('intermediate'),
        }),
      ),
      contains('specialization'),
    );
    expect(
      seen(
        having(<String, Object?>{...mix('musculation'), ...level('beginner')}),
      ),
      isNot(contains('specialization')),
    );
    expect(
      seen(
        having(<String, Object?>{...mix('cardio'), ...level('intermediate')}),
      ),
      isNot(contains('specialization')),
    );

    // Points faibles : avancé ET discipline de force.
    for (final code in <String>[
      'streetlifting',
      'street_workout',
      'calisthenics',
      'musculation',
      'crossfit',
    ]) {
      expect(
        seen(having(<String, Object?>{...mix(code), ...level('advanced')})),
        contains('weak_points'),
        reason: code,
      );
      expect(
        seen(
          having(<String, Object?>{
            ...mix('mobility', <String>[code]),
            ...level('elite'),
          }),
        ),
        contains('weak_points'),
        reason: code,
      );
      expect(
        seen(having(<String, Object?>{...mix(code), ...level('intermediate')})),
        isNot(contains('weak_points')),
        reason: code,
      );
    }
    for (final code in <String>['cardio', 'mobility', 'general_fitness']) {
      expect(
        seen(having(<String, Object?>{...mix(code), ...level('advanced')})),
        isNot(contains('weak_points')),
        reason: code,
      );
    }

    // Figures : calisthénie, streetlifting ou CrossFit, en principale ou en
    // secondaire, ou part de calisthénie du mode street.
    expect(shortest, isNot(contains('skills')));
    for (final code in <String>['calisthenics', 'streetlifting', 'crossfit']) {
      expect(seen(having(mix(code))), contains('skills'), reason: code);
      expect(
        seen(having(mix('musculation', <String>[code]))),
        contains('skills'),
        reason: code,
      );
    }
    for (final code in <String>['musculation', 'street_workout', 'cardio']) {
      expect(seen(having(mix(code))), isNot(contains('skills')), reason: code);
    }
    expect(
      seen(having(street(StreetStyle.setsReps, 0, 100, 0))),
      isNot(contains('skills')),
    );
    expect(
      seen(having(street(StreetStyle.setsReps, 0, 80, 20))),
      contains('skills'),
    );
    expect(
      seen(having(street(StreetStyle.streetlifting, 100, 0, 0))),
      contains('skills'),
    );

    // Échéance : niveau intermédiaire, objectif de performance ou cardio.
    expect(shortest, isNot(contains('events')));
    expect(
      seen(having(<String, Object?>{'goals': base['goals']})),
      contains('events'),
    );
    expect(
      seen(
        having(<String, Object?>{
          'goals': <Object?>[
            <String, Object?>{'id': 'g', 'kind': 'habit'},
          ],
        }),
      ),
      isNot(contains('events')),
    );
    expect(seen(having(mix('cardio'))), contains('events'));
    expect(
      seen(having(mix('mobility', <String>['cardio']))),
      contains('events'),
    );
    // Le profil de référence a un objectif de performance.
    expect(seen(base), contains('events'));

    // Volume de course : cardio, ou une course en vue.
    expect(shortest, isNot(contains('running_base')));
    expect(seen(having(mix('cardio'))), contains('running_base'));
    expect(
      seen(having(mix('musculation', <String>['cardio']))),
      contains('running_base'),
    );
    Map<String, Object?> eventOf(String kind) {
      return <String, Object?>{
        'events': <Object?>[
          <String, Object?>{'id': 'e', 'kind': 'personal_test'},
          <String, Object?>{'id': 'f', 'kind': kind},
        ],
      };
    }

    expect(seen(having(eventOf('race'))), contains('running_base'));
    expect(
      seen(having(eventOf('reps_competition'))),
      isNot(contains('running_base')),
    );

    // Poids visé : niveau intermédiaire, ou discipline au poids du corps.
    // Sans niveau (parcours du débutant), la question est reportée après
    // la première semaine : absente de la création, rendue à part.
    expect(shortest, isNot(contains('body_weight_goal')));
    expect(
      seen(having(mix('musculation')), includeDeferred: true),
      isNot(contains('body_weight_goal')),
    );
    for (final code in <String>[
      'streetlifting',
      'street_workout',
      'calisthenics',
    ]) {
      for (final profile in <Map<String, Object?>>[
        having(mix(code)),
        having(mix('cardio', <String>[code])),
        having(street(StreetStyle.setsReps, 0, 100, 0)),
      ]) {
        expect(
          seen(profile),
          isNot(contains('body_weight_goal')),
          reason: code,
        );
        expect(deferred(profile), contains('body_weight_goal'), reason: code);
        expect(
          seen(profile, includeDeferred: true),
          contains('body_weight_goal'),
          reason: code,
        );
        // Dès le niveau intermédiaire, elle est posée à la création.
        final trained = <String, Object?>{...profile, ...level('intermediate')};
        expect(seen(trained), contains('body_weight_goal'), reason: code);
        expect(
          deferred(trained),
          isNot(contains('body_weight_goal')),
          reason: code,
        );
      }
    }
  });

  test('chaque opérateur de condition, sur un cas vrai et un cas faux', () {
    final empty = <String, Object?>{};
    final one = <String, Object?>{'a': 1};

    // always
    expect(holds(opAlways, empty), isTrue);
    expect(holds(opAlways, one), isTrue);

    // all
    expect(holds(opAll(<Map<String, Object?>>[]), empty), isTrue);
    expect(
      holds(opAll(<Map<String, Object?>>[opAlways, opPresent('a')]), one),
      isTrue,
    );
    expect(
      holds(opAll(<Map<String, Object?>>[opAlways, opPresent('a')]), empty),
      isFalse,
    );
    expect(
      holds(opAll(<Map<String, Object?>>[opPresent('b'), opAlways]), one),
      isFalse,
    );

    // any
    expect(holds(opAny(<Map<String, Object?>>[]), one), isFalse);
    expect(
      holds(opAny(<Map<String, Object?>>[opPresent('b'), opPresent('a')]), one),
      isTrue,
    );
    expect(
      holds(opAny(<Map<String, Object?>>[opPresent('b'), opPresent('c')]), one),
      isFalse,
    );

    // not : une valeur absente rend la condition fausse, sauf sous `not`.
    expect(holds(opNot(opAlways), one), isFalse);
    expect(holds(opNot(opPresent('a')), one), isFalse);
    expect(holds(opNot(opPresent('a')), empty), isTrue);
    expect(holds(opNot(opNot(opPresent('a'))), one), isTrue);

    // present
    expect(holds(opPresent('a'), one), isTrue);
    expect(holds(opPresent('a'), empty), isFalse);
    expect(holds(opPresent('a'), <String, Object?>{'a': null}), isFalse);
    expect(holds(opPresent('a'), <String, Object?>{'a': false}), isTrue);
    expect(holds(opPresent('a'), <String, Object?>{'a': 0}), isTrue);
    // Une liste vide est une réponse (« aucun »), pas une absence.
    expect(holds(opPresent('a'), <String, Object?>{'a': <Object?>[]}), isTrue);
    final nested = <String, Object?>{
      'a': <String, Object?>{'b': 'x', 'c': null},
    };
    expect(holds(opPresent('a.b'), nested), isTrue);
    expect(holds(opPresent('a.c'), nested), isFalse);
    expect(holds(opPresent('a.d'), nested), isFalse);
    expect(holds(opPresent('a.b.c'), nested), isFalse);
    expect(holds(opPresent('a.b'), one), isFalse);

    // in
    final letter = <String, Object?>{'a': 'y', 'n': 2};
    expect(holds(opIn('a', <Object?>['x', 'y']), letter), isTrue);
    expect(holds(opIn('a', <Object?>['x', 'z']), letter), isFalse);
    expect(holds(opIn('a', <Object?>[]), letter), isFalse);
    expect(holds(opIn('b', <Object?>['x', 'y']), letter), isFalse);
    expect(holds(opIn('n', <Object?>[1, 2]), letter), isTrue);
    expect(holds(opIn('n', <Object?>['2']), letter), isFalse);

    // at_least
    Map<String, Object?> level(Object? value) {
      return <String, Object?>{'experience': value};
    }

    final advanced = opAtLeast('experience', 'experience', 'advanced');
    expect(holds(advanced, level('advanced')), isTrue);
    expect(holds(advanced, level('elite')), isTrue);
    expect(holds(advanced, level('intermediate')), isFalse);
    expect(holds(advanced, level('beginner')), isFalse);
    expect(holds(advanced, empty), isFalse);
    expect(holds(advanced, level(null)), isFalse);
    // Une valeur hors de l'échelle, ou qui n'est pas un texte, ne compte pas.
    expect(holds(advanced, level('legend')), isFalse);
    expect(holds(advanced, level(3)), isFalse);
    final lowest = opAtLeast('experience', 'experience', 'beginner');
    expect(holds(lowest, level('beginner')), isTrue);
    expect(holds(lowest, level('legend')), isFalse);
    expect(holds(lowest, empty), isFalse);
    final age = opAtLeast('trainingAge', 'trainingAge', 'years_2_to_5');
    expect(
      holds(age, <String, Object?>{'trainingAge': 'over_5_years'}),
      isTrue,
    );
    expect(
      holds(age, <String, Object?>{'trainingAge': 'months_6_to_24'}),
      isFalse,
    );

    // min_number
    Map<String, Object?> number(Object? value) {
      return <String, Object?>{'n': value};
    }

    expect(holds(opMinNumber('n', 1), number(1)), isTrue);
    expect(holds(opMinNumber('n', 1), number(1.5)), isTrue);
    expect(holds(opMinNumber('n', 1), number(40)), isTrue);
    expect(holds(opMinNumber('n', 1), number(0)), isFalse);
    expect(holds(opMinNumber('n', 1), number(0.5)), isFalse);
    expect(holds(opMinNumber('n', 1.5), number(1)), isFalse);
    expect(holds(opMinNumber('n', 1), number('2')), isFalse);
    expect(holds(opMinNumber('n', 1), number(true)), isFalse);
    expect(holds(opMinNumber('n', 1), number(null)), isFalse);
    expect(holds(opMinNumber('n', 1), empty), isFalse);
    expect(holds(opMinNumber('n', -1), number(0)), isTrue);

    // age_at_least : année du jour − année de naissance.
    Map<String, Object?> born(Object? year) {
      return <String, Object?>{'birthYear': year};
    }

    expect(parcours.evaluate(opAge(65), born(1961), todayYear: 2026), isTrue);
    expect(parcours.evaluate(opAge(65), born(1930), todayYear: 2026), isTrue);
    expect(parcours.evaluate(opAge(65), born(1962), todayYear: 2026), isFalse);
    expect(parcours.evaluate(opAge(65), born(1962), todayYear: 2027), isTrue);
    expect(parcours.evaluate(opAge(65), empty, todayYear: 2026), isFalse);
    expect(
      parcours.evaluate(opAge(65), born('1950'), todayYear: 2026),
      isFalse,
    );
    expect(parcours.evaluate(opAge(65), born(null), todayYear: 2026), isFalse);
  });

  test('chemins avec `[*]` : une liste est parcourue', () {
    final profile = <String, Object?>{
      'items': <Object?>[
        <String, Object?>{'kind': 'u', 'pct': 0},
        null,
        7,
        <String, Object?>{'kind': 'v', 'pct': 30, 'level': 'advanced'},
        <String, Object?>{'other': true},
      ],
      'none': <Object?>[],
      'nulls': <Object?>[null, null],
      'scalar': 3,
      'tags': <Object?>['x', 'y'],
      'group': <String, Object?>{
        'list': <Object?>[
          <String, Object?>{'k': 'deep'},
        ],
      },
    };
    // present
    expect(holds(opPresent('items[*]'), profile), isTrue);
    expect(holds(opPresent('items[*].kind'), profile), isTrue);
    expect(holds(opPresent('items[*].other'), profile), isTrue);
    expect(holds(opPresent('items[*].missing'), profile), isFalse);
    expect(holds(opPresent('none[*]'), profile), isFalse);
    expect(holds(opPresent('nulls[*]'), profile), isFalse);
    expect(holds(opPresent('missing[*]'), profile), isFalse);
    // `[*]` sur autre chose qu'une liste : rien.
    expect(holds(opPresent('scalar[*]'), profile), isFalse);
    expect(holds(opPresent('group[*]'), profile), isFalse);
    // Sans `[*]`, on ne descend pas dans une liste.
    expect(holds(opPresent('items.kind'), profile), isFalse);
    expect(holds(opPresent('none'), profile), isTrue);
    expect(holds(opPresent('group.list[*].k'), profile), isTrue);
    expect(holds(opPresent('group.list[*].z'), profile), isFalse);
    // in
    expect(holds(opIn('items[*].kind', <Object?>['v']), profile), isTrue);
    expect(holds(opIn('items[*].kind', <Object?>['w']), profile), isFalse);
    expect(holds(opIn('tags[*]', <Object?>['y', 'z']), profile), isTrue);
    expect(holds(opIn('tags[*]', <Object?>['z']), profile), isFalse);
    expect(holds(opIn('none[*]', <Object?>['x']), profile), isFalse);
    expect(holds(opIn('group.list[*].k', <Object?>['deep']), profile), isTrue);
    // min_number
    expect(holds(opMinNumber('items[*].pct', 30), profile), isTrue);
    expect(holds(opMinNumber('items[*].pct', 31), profile), isFalse);
    expect(holds(opMinNumber('items[*]', 7), profile), isTrue);
    expect(holds(opMinNumber('items[*]', 8), profile), isFalse);
    // at_least
    expect(
      holds(opAtLeast('items[*].level', 'experience', 'advanced'), profile),
      isTrue,
    );
    expect(
      holds(opAtLeast('items[*].level', 'experience', 'elite'), profile),
      isFalse,
    );
    expect(
      holds(opAtLeast('items[*].kind', 'experience', 'beginner'), profile),
      isFalse,
    );
    // Chemins du parcours réel : discipline secondaire, nature d'un
    // objectif.
    final secondary = opIn('disciplines.secondaries[*].discipline', <Object?>[
      'cardio',
    ]);
    expect(holds(secondary, mix('musculation', <String>['cardio'])), isTrue);
    expect(holds(secondary, mix('cardio', <String>['mobility'])), isFalse);
    expect(holds(secondary, mix('cardio')), isFalse);
    final performance = opIn('goals[*].kind', <Object?>['performance']);
    expect(holds(performance, baseProfile().toJson()), isTrue);
    expect(
      holds(performance, <String, Object?>{'goals': <Object?>[]}),
      isFalse,
    );
  });

  test('« Compléter mon profil » : seulement les questions du schéma 3', () {
    final added3 = <String>[
      for (final q in parcours.questions)
        if (q.since == 3) q.id,
    ];
    expect(added3, hasLength(14));
    for (final p in v2Profiles) {
      final json = p.profile.toSchema3().toJson();
      final all = seen(json, includeDeferred: true);
      final added = seen(json, since: 3, includeDeferred: true);
      expect(added, isNotEmpty, reason: p.key);
      for (final id in added) {
        expect(parcours.question(id)!.since, 3, reason: id);
        expect(all, contains(id), reason: id);
      }
      // Rien d'autre : les questions du schéma 3 visibles, dans l'ordre.
      expect(added, <String>[
        for (final id in all)
          if (added3.contains(id)) id,
      ], reason: p.key);
      // Toujours proposées, quel que soit le profil.
      expect(added, containsAll(recovery), reason: p.key);
      // À la création, `since: 3` ne rend aussi que des questions du
      // schéma 3, sans les reportées.
      final atCreation = seen(json, since: 3);
      final later = deferred(json);
      expect(atCreation, <String>[
        for (final id in added)
          if (!later.contains(id)) id,
      ], reason: p.key);
      // L'ancienneté n'est demandée qu'à partir du niveau intermédiaire.
      final experience = p.profile.experience;
      final confirmed =
          experience != null && experience != ExperienceLevel.beginner;
      expect(added.contains('training_age'), confirmed, reason: p.key);
      expect(all.contains('preferences'), confirmed, reason: p.key);
      expect(later, confirmed ? isEmpty : recovery, reason: p.key);
    }
    // `since: 2` rend tout le parcours.
    for (final key in v3.keys) {
      final profile = profileOf(key);
      expect(seen(profile, since: 2), seen(profile), reason: key);
      for (final id in seen(profile, since: 3)) {
        expect(parcours.question(id)!.since, 3, reason: '$key $id');
      }
      expect(seen(profile, since: 4), isEmpty, reason: key);
    }
  });

  test('`training_age` et `preferences` : cachées pour un débutant', () {
    for (final id in <String>['training_age', 'preferences']) {
      for (final profile in <Map<String, Object?>>[
        <String, Object?>{},
        <String, Object?>{'experience': 'beginner'},
        profileOf('v3_debutant_forme_generale'),
      ]) {
        expect(seen(profile, includeDeferred: true), isNot(contains(id)));
        expect(seen(profile), isNot(contains(id)));
        expect(deferred(profile), isNot(contains(id)));
      }
      for (final level in <String>['intermediate', 'advanced', 'elite']) {
        expect(
          seen(<String, Object?>{'experience': level}),
          contains(id),
          reason: level,
        );
      }
    }
    expect(parcours.question('training_age')!.since, 3);
    expect(parcours.question('preferences')!.since, 2);
  });

  test('dix tests guidés, chacun avec son protocole', () {
    expect(<String>[for (final t in parcours.tests) t.id], testIds);
    for (final t in parcours.tests) {
      expect(t.title, isNotEmpty, reason: t.id);
      expect(
        <String>['creation', 'first_session', 'later'],
        contains(t.stage),
        reason: t.id,
      );
      expect(t.json['id'], t.id, reason: t.id);
      // Prérequis par mouvement : texte du protocole (objet JSON complet).
      expect(t.requires, isNotEmpty, reason: t.id);
      expect(t.requires, t.json['requires'], reason: t.id);
      expect(t.json['forWhom'], isNotEmpty, reason: t.id);
      expect(t.json['safety'], isNotEmpty, reason: t.id);
      expect(t.json['steps'], isNotEmpty, reason: t.id);
      expect(t.json['uncertainty'], isNotEmpty, reason: t.id);
      expect(t.json['refs'], isNotEmpty, reason: t.id);
      final conversion = t.json['conversion']! as Map<String, Object?>;
      expect(conversion['text'], isNotEmpty, reason: t.id);
      // Une nature de test et une nature de valeur, ou aucune des deux.
      expect(t.benchmarkKind == null, t.testKind == null, reason: t.id);
      expect(t.benchmarkKind == null, t.id == 't8_sans_test', reason: t.id);
      expect(t.stage == 'creation', t.id == 't8_sans_test', reason: t.id);
    }
  });

  test('tests guidés : aucun effort maximal sans questionnaire santé '
      'standard ni niveau intermédiaire', () {
    // Un profil vide n'a que « sans test ».
    expect(testsOf(<String, Object?>{}), <String>['t8_sans_test']);
    var testable = 0;
    for (final p in v2Profiles) {
      final json = p.profile.toJson();
      final ids = testsOf(json);
      final outcome = p.profile.healthScreening?.outcome;
      final experience = p.profile.experience;
      if (outcome == HealthScreeningOutcome.standard &&
          experience != null &&
          experience != ExperienceLevel.beginner) {
        expect(ids, isNot(contains('t8_sans_test')), reason: p.key);
        expect(ids, contains('t1_serie_lourde'), reason: p.key);
        expect(ids, contains('t4_reps_max'), reason: p.key);
        expect(ids, contains('t5_maintien_max'), reason: p.key);
        testable++;
      } else {
        expect(ids, <String>['t8_sans_test'], reason: p.key);
      }
    }
    expect(testable, greaterThan(0));
    final base = <String, Object?>{
      ...baseProfile().toJson(),
      'healthScreening': <String, Object?>{
        'questionnaireId': 'kalis-sante-l13-v1',
        'outcome': 'standard',
      },
    };
    // Les âges ci-dessous sont comptés depuis l'année des profils types.
    expect(todayYear, 2026);
    List<String> allowed(Map<String, Object?> changes) {
      return testsOf(<String, Object?>{...base, ...changes});
    }

    const cautious = <String, Object?>{
      'questionnaireId': 'kalis-sante-l13-v1',
      'outcome': 'cautious',
    };
    // Questionnaire standard mais niveau non renseigné ou débutant : aucun
    // test.
    expect(allowed(<String, Object?>{}), <String>['t8_sans_test']);
    expect(allowed(<String, Object?>{'experience': 'beginner'}), <String>[
      't8_sans_test',
    ]);
    // Niveau intermédiaire mais questionnaire prudent, sans réponse ou
    // absent : aucun test.
    expect(
      allowed(<String, Object?>{
        'experience': 'elite',
        'healthScreening': cautious,
      }),
      <String>['t8_sans_test'],
    );
    expect(
      allowed(<String, Object?>{
        'experience': 'elite',
        'healthScreening': <String, Object?>{
          'questionnaireId': 'kalis-sante-l13-v1',
          'outcome': 'not_answered',
        },
      }),
      <String>['t8_sans_test'],
    );
    expect(
      allowed(<String, Object?>{
        'experience': 'elite',
        'healthScreening': null,
      }),
      <String>['t8_sans_test'],
    );
    // Intermédiaire, questionnaire standard, poids connu, musculation.
    expect(allowed(<String, Object?>{'experience': 'intermediate'}), <String>[
      't1_serie_lourde',
      't2_leste',
      't4_reps_max',
      't5_maintien_max',
      't6_course_6min',
      't7_course_chrono',
    ]);
    // Test lesté : le poids de corps est nécessaire.
    expect(
      allowed(<String, Object?>{
        'experience': 'intermediate',
        'bodyWeightKg': null,
      }),
      isNot(contains('t2_leste')),
    );
    // Épreuves de répétitions : sets & reps, street workout, ou une
    // compétition de répétitions en vue.
    const repsTests = <String>['t9_reps_temps', 't10_series_repetees'];
    for (final id in repsTests) {
      expect(
        allowed(<String, Object?>{'experience': 'advanced'}),
        isNot(contains(id)),
      );
    }
    for (final changes in <Map<String, Object?>>[
      mix('street_workout'),
      mix('musculation', <String>['street_workout']),
      street(StreetStyle.streetlifting, 70, 15, 15),
      <String, Object?>{
        'events': <Object?>[
          <String, Object?>{'id': 'e', 'kind': 'reps_competition'},
        ],
      },
    ]) {
      expect(
        allowed(<String, Object?>{'experience': 'advanced', ...changes}),
        containsAll(repsTests),
      );
      expect(
        allowed(<String, Object?>{'experience': 'beginner', ...changes}),
        <String>['t8_sans_test'],
      );
    }
    expect(
      allowed(<String, Object?>{
        'experience': 'advanced',
        ...street(StreetStyle.streetlifting, 100, 0, 0),
      }),
      isNot(contains('t9_reps_temps')),
    );
    // Maximum direct : jamais pour un débutant, jamais sans ancienneté,
    // jamais après 65 ans sans au moins 2 ans de pratique.
    bool direct(Map<String, Object?> changes) {
      return allowed(changes).contains('t3_max_direct');
    }

    expect(direct(<String, Object?>{}), isFalse);
    expect(direct(<String, Object?>{'experience': 'advanced'}), isFalse);
    expect(
      direct(<String, Object?>{
        'experience': 'advanced',
        'trainingAge': 'under_6_months',
      }),
      isFalse,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'beginner',
        'trainingAge': 'over_5_years',
      }),
      isFalse,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'intermediate',
        'trainingAge': 'months_6_to_24',
      }),
      isTrue,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'intermediate',
        'trainingAge': 'months_6_to_24',
        'birthYear': 1958,
      }),
      isFalse,
    );
    // 65 ans tout juste.
    expect(
      direct(<String, Object?>{
        'experience': 'intermediate',
        'trainingAge': 'months_6_to_24',
        'birthYear': 1961,
      }),
      isFalse,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'intermediate',
        'trainingAge': 'months_6_to_24',
        'birthYear': 1962,
      }),
      isTrue,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'intermediate',
        'trainingAge': 'years_2_to_5',
        'birthYear': 1958,
      }),
      isTrue,
    );
    expect(
      direct(<String, Object?>{
        'experience': 'advanced',
        'trainingAge': 'over_5_years',
        'healthScreening': cautious,
      }),
      isFalse,
    );
  });

  test('$samples profils aléatoires : le parcours ne lève jamais, garde '
      'l\'ordre et pose toujours les questions obligatoires', () {
    final r = Random(5001);
    final mandatory = <String>[
      for (final q in parcours.questions)
        if (q.required) q.id,
    ];
    final shortest = seen(<String, Object?>{}).length;
    expect(shortest, 16);
    for (var i = 0; i < samples; i++) {
      final profile = arbitraryAthleteProfile(r);
      final json = profile.toJson();
      final ids = seen(json);
      expect(ids, containsAll(mandatory));
      var last = -1;
      for (final id in ids) {
        final at = order.indexOf(id);
        expect(at, greaterThan(last));
        last = at;
      }
      final added = seen(json, since: 3);
      expect(ids, containsAll(added));
      expect(added, <String>[
        for (final id in ids)
          if (parcours.question(id)!.since == 3) id,
      ]);
      expect(ids.length, lessThanOrEqualTo(order.length));
      // Jamais moins que le parcours d'un profil vide.
      expect(ids.length, greaterThanOrEqualTo(shortest));
      // Questions reportées : celles de récupération, pour un niveau
      // débutant ou non renseigné ; jamais une question obligatoire.
      final experience = profile.experience;
      final later = deferred(json);
      final confirmed =
          experience != null && experience != ExperienceLevel.beginner;
      expect(later, confirmed ? isEmpty : recovery);
      final all = seen(json, includeDeferred: true);
      expect(all, <String>[
        for (final id in order)
          if (ids.contains(id) || later.contains(id)) id,
      ]);
      expect(all.length, ids.length + later.length);
      expect(all.length, greaterThanOrEqualTo(shortest + recovery.length));
      for (final q in parcours.questions) {
        final needed = parcours.isRequired(q, json, todayYear: todayYear);
        if (q.required) {
          expect(needed, isTrue);
        }
        if (needed) {
          expect(later, isNot(contains(q.id)));
        }
      }
      // Tests guidés : « sans test » ou des tests, jamais les deux.
      final tests = testsOf(json);
      expect(tests, isNotEmpty);
      if (tests.contains('t8_sans_test')) {
        expect(tests, hasLength(1));
      }
      final outcome = profile.healthScreening?.outcome;
      expect(
        tests.contains('t8_sans_test'),
        !(confirmed && outcome == HealthScreeningOutcome.standard),
      );
      // Un brouillon vide ne lève pas non plus.
      if (i == 0) {
        expect(seen(<String, Object?>{}), isNotEmpty);
        expect(
          parcours.eligibleTests(<String, Object?>{}, todayYear: todayYear),
          hasLength(1),
        );
      }
    }
  });

  test('lecture stricte du fichier', () {
    expect(
      () => ProfileQuestionnaire.fromJson(<String, Object?>{
        ...parcoursJson,
        'schema': 2,
      }),
      throwsFormatException,
    );
    final broken = <String, Object?>{
      ...parcoursJson,
      'tests': <Object?>[
        <String, Object?>{
          'id': 't',
          'title': 't',
          'stage': 'later',
          'eligible': <String, Object?>{'op': 'inconnue'},
        },
      ],
    };
    expect(() => ProfileQuestionnaire.fromJson(broken), throwsFormatException);
    final badScale = <String, Object?>{
      ...parcoursJson,
      'tests': <Object?>[
        <String, Object?>{
          'id': 't',
          'title': 't',
          'stage': 'later',
          'eligible': <String, Object?>{
            'op': 'at_least',
            'path': 'experience',
            'scale': 'experience',
            'value': 'legend',
          },
        },
      ],
    };
    expect(
      () => ProfileQuestionnaire.fromJson(badScale),
      throwsFormatException,
    );
    // Le même test, avec une condition bien formée, se charge.
    Map<String, Object?> withTest(Map<String, Object?> eligible) {
      return <String, Object?>{
        ...parcoursJson,
        'tests': <Object?>[
          <String, Object?>{
            'id': 't',
            'title': 't',
            'stage': 'later',
            'requires': 'Rien.',
            'eligible': eligible,
          },
        ],
      };
    }

    expect(
      ProfileQuestionnaire.fromJson(
        withTest(opAtLeast('experience', 'experience', 'elite')),
      ).tests.single.id,
      't',
    );
    // Échelle inconnue.
    expect(
      () => ProfileQuestionnaire.fromJson(
        withTest(opAtLeast('experience', 'inconnue', 'elite')),
      ),
      throwsFormatException,
    );
    // Opération inconnue ou échelle inconnue au fond d'une condition
    // composée.
    expect(
      () => ProfileQuestionnaire.fromJson(
        withTest(
          opAll(<Map<String, Object?>>[
            opAlways,
            opNot(<String, Object?>{'op': 'inconnue'}),
          ]),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => ProfileQuestionnaire.fromJson(
        withTest(
          opAny(<Map<String, Object?>>[
            opAlways,
            opAtLeast('experience', 'inconnue', 'elite'),
          ]),
        ),
      ),
      throwsFormatException,
    );
    // Les trois conditions d'une question sont contrôlées.
    final questions = parcoursJson['questions']! as List<Object?>;
    final first = questions.first! as Map<String, Object?>;
    Map<String, Object?> withQuestion(Map<String, Object?> changes) {
      return <String, Object?>{
        ...parcoursJson,
        'questions': <Object?>[
          <String, Object?>{...first, ...changes},
        ],
      };
    }

    expect(
      ProfileQuestionnaire.fromJson(
        withQuestion(<String, Object?>{}),
      ).questions.single.id,
      first['id'],
    );
    for (final key in <String>['when', 'deferWhen', 'requiredWhen']) {
      expect(
        () => ProfileQuestionnaire.fromJson(
          withQuestion(<String, Object?>{
            key: <String, Object?>{'op': 'inconnue'},
          }),
        ),
        throwsFormatException,
        reason: key,
      );
      expect(
        () => ProfileQuestionnaire.fromJson(
          withQuestion(<String, Object?>{
            key: opAtLeast('experience', 'inconnue', 'beginner'),
          }),
        ),
        throwsFormatException,
        reason: key,
      );
      expect(
        ProfileQuestionnaire.fromJson(
          withQuestion(<String, Object?>{key: opPresent('experience')}),
        ).questions,
        hasLength(1),
        reason: key,
      );
    }
    // Deux questions de même identifiant.
    expect(
      () => ProfileQuestionnaire.fromJson(<String, Object?>{
        ...parcoursJson,
        'questions': <Object?>[first, first],
      }),
      throwsFormatException,
    );
  });

  test('évaluation d\'une condition mal formée : FormatException', () {
    final profile = <String, Object?>{'experience': 'elite'};
    // Opération inconnue.
    expect(
      () => holds(<String, Object?>{'op': 'inconnue'}, profile),
      throwsFormatException,
    );
    expect(
      () => holds(opNot(<String, Object?>{'op': 'inconnue'}), profile),
      throwsFormatException,
    );
    expect(
      () => holds(
        opAll(<Map<String, Object?>>[
          opAlways,
          <String, Object?>{'op': 'inconnue'},
        ]),
        profile,
      ),
      throwsFormatException,
    );
    expect(() => holds(<String, Object?>{}, profile), throwsFormatException);
    // Échelle inconnue.
    expect(
      () => holds(opAtLeast('experience', 'inconnue', 'elite'), profile),
      throwsFormatException,
    );
    // Valeur absente de l'échelle : refusée, jamais « toujours vrai ».
    expect(
      () => holds(opAtLeast('experience', 'experience', 'champion'), profile),
      throwsFormatException,
    );
    expect(
      () => holds(
        opAtLeast('experience', 'inconnue', 'elite'),
        const <String, Object?>{},
      ),
      throwsFormatException,
    );
    // La même condition sur une échelle connue s'évalue.
    final known = opAtLeast('experience', 'experience', 'elite');
    expect(holds(known, profile), isTrue);
  });
}
