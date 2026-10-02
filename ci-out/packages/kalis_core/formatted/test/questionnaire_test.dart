// Parcours de questions du profil v3 (0.4.0) : arbre adaptatif, nombre de
// questions vues par profil type, tests guidés.
@Timeout(Duration(minutes: 30))
library;

import 'dart:math';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:test/test.dart';

import 'samples.dart';
import 'support.dart';

const int samples = 10000;

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

  List<String> seen(Map<String, Object?> profile, {int since = 2}) => <String>[
    for (final q in parcours.visibleQuestions(
      profile,
      todayYear: todayYear,
      since: since,
    ))
      q.id,
  ];

  test('le fichier se charge : version, écrans, questions, tests', () {
    expect(parcours.version, kalisCoreVersion);
    expect(parcours.screens, hasLength(14));
    expect(parcours.questions.length, greaterThanOrEqualTo(28));
    expect(parcours.tests, hasLength(8));
    expect(parcours.rulesetPresets, isNotEmpty);
    final screens = <String>{
      for (final s in parcours.screens) s['id']! as String,
    };
    for (final q in parcours.questions) {
      expect(screens, contains(q.screen), reason: q.id);
      expect(q.text, isNotEmpty, reason: q.id);
      expect(q.fields, isNotEmpty, reason: q.id);
      expect(q.since == 2 || q.since == 3, isTrue, reason: q.id);
      if (q.required) {
        expect(q.skip || q.unknown, isFalse, reason: q.id);
      }
      if (q.kind == 'choice' || q.kind == 'multi') {
        expect(q.options, isNotEmpty, reason: q.id);
      }
    }
    expect(parcours.question('sleep')!.fields, <String>['sleep']);
    expect(parcours.question('inconnue'), isNull);
  });

  test('les questions suivent l\'ordre des écrans', () {
    final order = <String>[
      for (final s in parcours.screens) s['id']! as String,
    ];
    var last = 0;
    for (final q in parcours.questions) {
      final at = order.indexOf(q.screen);
      expect(at, greaterThanOrEqualTo(last), reason: q.id);
      last = at;
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
    expect(
      v3.keys,
      containsAll(<String>[
        'v3_debutant_forme_generale',
        'v3_intermediaire_musculation',
        'v3_competiteur_elite_streetlifting',
        'v3_coureuse_10km',
      ]),
    );
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
      expect(
        <String>[
          for (final t in parcours.eligibleTests(profile, todayYear: todayYear))
            t.id,
        ],
        expected['testIds'],
        reason: entry.key,
      );
      // Même résultat à partir du profil typé.
      final typed = AthleteProfile.fromJson(profile);
      expect(seen(typed.toJson()), ids, reason: entry.key);
    }
  });

  test('un débutant voit peu de questions, un compétiteur les siennes', () {
    Map<String, Object?> profileOf(String key) =>
        v3[key]!['profile']! as Map<String, Object?>;
    final beginner = seen(profileOf('v3_debutant_forme_generale'));
    final intermediate = seen(profileOf('v3_intermediaire_musculation'));
    final elite = seen(profileOf('v3_competiteur_elite_streetlifting'));
    expect(beginner.length, 20);
    expect(intermediate.length, 25);
    expect(elite.length, 28);
    expect(beginner.length, lessThan(intermediate.length));
    expect(intermediate.length, lessThan(elite.length));
    // Le débutant ne voit que quatre questions nouvelles, à un appui.
    expect(seen(profileOf('v3_debutant_forme_generale'), since: 3), <String>[
      'training_age',
      'sleep',
      'stress',
      'outside_load',
    ]);
    for (final hidden in <String>[
      'training_gap',
      'benchmarks',
      'skills',
      'events',
      'specialization',
      'weak_points',
      'body_weight_goal',
      'preferences',
    ]) {
      expect(beginner, isNot(contains(hidden)), reason: hidden);
    }
    expect(
      elite,
      containsAll(<String>[
        'benchmarks',
        'skills',
        'events',
        'specialization',
        'weak_points',
        'body_weight_goal',
      ]),
    );
    // Tout ce que voit le débutant, les autres le voient aussi.
    expect(intermediate, containsAll(beginner));
    expect(elite, containsAll(intermediate));
  });

  test('chaque condition d\'apparition', () {
    final base = baseProfile().toJson()..remove('experience');
    Map<String, Object?> having(Map<String, Object?> changes) =>
        <String, Object?>{...base, ...changes};
    // Sans réponse sur le niveau : parcours le plus court.
    final shortest = seen(base);
    expect(shortest, isNot(contains('benchmarks')));
    expect(shortest, isNot(contains('preferences')));
    expect(shortest, isNot(contains('training_gap')));
    // baseProfile a un objectif de performance : l'échéance est demandée.
    expect(shortest, contains('events'));
    expect(
      seen(having(<String, Object?>{'goals': <Object?>[]})),
      isNot(contains('events')),
    );
    // Niveau.
    for (final level in <String>['intermediate', 'advanced', 'elite']) {
      final ids = seen(having(<String, Object?>{'experience': level}));
      expect(ids, contains('benchmarks'), reason: level);
      expect(ids, contains('events'), reason: level);
      expect(ids, contains('body_weight_goal'), reason: level);
      expect(ids, contains('preferences'), reason: level);
      expect(
        ids.contains('specialization'),
        level != 'intermediate',
        reason: level,
      );
      expect(
        ids.contains('weak_points'),
        level != 'intermediate',
        reason: level,
      );
    }
    expect(
      seen(having(<String, Object?>{'experience': 'beginner'})),
      isNot(contains('benchmarks')),
    );
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
    // Figures : calisthénie en principale, en secondaire, ou part de
    // calisthénie du mode street.
    expect(shortest, isNot(contains('skills')));
    expect(
      seen(
        having(<String, Object?>{
          'disciplines': <String, Object?>{
            'primary': 'calisthenics',
            'primaryPct': 100,
            'secondaries': <Object?>[],
          },
        }),
      ),
      contains('skills'),
    );
    expect(
      seen(
        having(<String, Object?>{
          'disciplines': <String, Object?>{
            'primary': 'musculation',
            'primaryPct': 70,
            'secondaries': <Object?>[
              <String, Object?>{'discipline': 'calisthenics', 'pct': 30},
            ],
          },
        }),
      ),
      contains('skills'),
    );
    Map<String, Object?> street(int calisthenicsPct) => <String, Object?>{
      'streetMode': <String, Object?>{
        'primary': 'streetlifting',
        'streetliftingPct': 100 - calisthenicsPct,
        'setsRepsPct': 0,
        'calisthenicsPct': calisthenicsPct,
      },
      'disciplines': <String, Object?>{
        'primary': 'streetlifting',
        'primaryPct': 100 - calisthenicsPct,
        'secondaries': <Object?>[
          if (calisthenicsPct > 0)
            <String, Object?>{
              'discipline': 'calisthenics',
              'pct': calisthenicsPct,
            },
        ],
      },
    };
    expect(seen(having(street(0))), isNot(contains('skills')));
    expect(seen(having(street(20))), contains('skills'));
    // Mode street : le poids visé compte (charge totale, catégories).
    expect(shortest, isNot(contains('body_weight_goal')));
    expect(seen(having(street(0))), contains('body_weight_goal'));
    // Points faibles : avancé ET discipline de force.
    expect(
      seen(
        having(<String, Object?>{
          'experience': 'advanced',
          'disciplines': <String, Object?>{
            'primary': 'cardio',
            'primaryPct': 100,
            'secondaries': <Object?>[],
          },
        }),
      ),
      isNot(contains('weak_points')),
    );
  });

  test('« Compléter mon profil » : seulement les questions du schéma 3', () {
    for (final p in v2Profiles) {
      final json = p.profile.toSchema3().toJson();
      final all = seen(json);
      final added = seen(json, since: 3);
      expect(added, isNotEmpty, reason: p.key);
      for (final id in added) {
        expect(parcours.question(id)!.since, 3, reason: id);
        expect(all, contains(id), reason: id);
      }
      // Toujours demandées, quel que soit le profil.
      expect(
        added,
        containsAll(<String>[
          'training_age',
          'sleep',
          'stress',
          'outside_load',
        ]),
        reason: p.key,
      );
    }
  });

  test('tests guidés : aucun effort maximal sans questionnaire santé '
      'standard', () {
    for (final p in v2Profiles) {
      final json = p.profile.toJson();
      final ids = <String>[
        for (final t in parcours.eligibleTests(json, todayYear: todayYear))
          t.id,
      ];
      final outcome = p.profile.healthScreening?.outcome;
      if (outcome == HealthScreeningOutcome.standard) {
        expect(ids, isNot(contains('t8_sans_test')), reason: p.key);
        expect(ids, contains('t4_reps_max'), reason: p.key);
      } else {
        expect(ids, <String>['t8_sans_test'], reason: p.key);
      }
    }
    // Maximum direct : jamais pour un débutant, jamais sans ancienneté,
    // jamais après 65 ans sans au moins 2 ans de pratique.
    final base = <String, Object?>{
      ...baseProfile().toJson(),
      'healthScreening': <String, Object?>{
        'questionnaireId': 'kalis-sante-l13-v1',
        'outcome': 'standard',
      },
    };
    bool direct(Map<String, Object?> changes) => parcours
        .eligibleTests(<String, Object?>{...base, ...changes}, todayYear: 2026)
        .any((t) => t.id == 't3_max_direct');
    expect(direct(<String, Object?>{}), isFalse);
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
        'healthScreening': <String, Object?>{
          'questionnaireId': 'kalis-sante-l13-v1',
          'outcome': 'cautious',
        },
      }),
      isFalse,
    );
  });

  test('$samples profils aléatoires : le parcours ne lève jamais, garde '
      'l\'ordre et pose toujours les questions obligatoires', () {
    final r = Random(5001);
    final always = <String>[
      for (final q in parcours.questions)
        if (q.required) q.id,
    ];
    final order = <String>[for (final q in parcours.questions) q.id];
    for (var i = 0; i < samples; i++) {
      final json = arbitraryAthleteProfile(r).toJson();
      final ids = seen(json);
      expect(ids, containsAll(always));
      var last = -1;
      for (final id in ids) {
        final at = order.indexOf(id);
        expect(at, greaterThan(last));
        last = at;
      }
      final added = seen(json, since: 3);
      expect(ids, containsAll(added));
      expect(ids.length, lessThanOrEqualTo(order.length));
      expect(ids.length, greaterThanOrEqualTo(20));
      final tests = parcours.eligibleTests(json, todayYear: todayYear);
      expect(tests, isNotEmpty);
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
  });
}
