// Critères de sécurité : chaque critère a un cas écrit à la main qui doit
// être signalé et un cas voisin qui ne doit pas l'être.
import 'package:kalis_bench/kalis_bench.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:test/test.dart';

import 'support.dart';

const String traction = 'sw-traction-pronation';
const String tractionLestee = 'sl-traction-lestee';
const String dips = 'sw-dips-barres-paralleles';
const String squat = 'sl-squat-competition';
const String pompe = 'sw-pompe';

Set<String> run(
  BenchProfile p,
  List<(WeekKind, List<List<L>>)> weeks, {
  int minutes = 90,
}) => codesOf(safetyFindings(handProgram(p, weeks, minutes: minutes), p));

void main() {
  final catalog = loadCatalog();
  final base = <List<L>>[
    <L>[const L(traction, 3), const L(dips, 3), const L(squat, 3, load: 60)],
    <L>[const L(traction, 3), const L(pompe, 3), const L(squat, 3, load: 60)],
  ];

  test('un programme sobre ne déclenche aucun critère', () {
    final p = testProfile();
    final weeks = <(WeekKind, List<List<L>>)>[
      (WeekKind.intro, base),
      (WeekKind.build, base),
      (WeekKind.build, base),
      (WeekKind.deload, base),
    ];
    expect(run(p, weeks), isEmpty);
  });

  test('charge_trop_vite : +15 % de charge totale en une semaine', () {
    final p = testProfile(level: 'advanced');
    List<List<L>> week(double load) => <List<L>>[
      <L>[L(tractionLestee, 3, reps: 5, load: load)],
    ];
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, week(20)),
        (WeekKind.build, week(35)),
      ]),
      contains('charge_trop_vite'),
    );
    // +2,5 kg sur 100 kg de charge totale : +2,5 %.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, week(20)),
        (WeekKind.build, week(22.5)),
      ]),
      isNot(contains('charge_trop_vite')),
    );
  });

  test('volume_trop_vite et plafond_volume', () {
    final p = testProfile(level: 'beginner');
    List<List<L>> week(int sets) => <List<L>>[
      <L>[L(traction, sets)],
      <L>[L(traction, sets)],
    ];
    final jump = run(p, <(WeekKind, List<List<L>>)>[
      (WeekKind.build, week(2)),
      (WeekKind.build, week(5)),
    ]);
    expect(jump, contains('volume_trop_vite'));
    expect(jump, isNot(contains('plafond_volume')));
    final high = run(p, sameWeeks(2, week(7)));
    expect(high, contains('plafond_volume'));
    expect(high, isNot(contains('volume_trop_vite')));
    expect(run(p, sameWeeks(2, week(3))), isEmpty);
    // Un seul constat de plafond par groupe, quel que soit le nombre de
    // semaines au-dessus.
    final many = <String>[
      for (final f in safetyFindings(handProgram(p, sameWeeks(4, week(7))), p))
        f.code,
    ];
    final groups = <String>{
      for (final g in MuscleGroup.values)
        if (g.major &&
            CatalogTraits.of(catalog).of(traction).creditOf(g) * 14 / 2 > 12)
          g.code,
    };
    expect(many.where((c) => c == 'plafond_volume').length, groups.length);
  });

  test('règle de montée : retour à la pleine charge après allègement', () {
    final p = testProfile(level: 'beginner');
    List<List<L>> week(int sets) => <List<L>>[
      <L>[L(traction, sets)],
      <L>[L(traction, sets)],
    ];
    // Introduction à 50 % puis pleine charge : admis.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.intro, week(2)),
        (WeekKind.build, week(4)),
      ]),
      isNot(contains('volume_trop_vite')),
    );
    // Introduction à moins de 50 % de la suite : refusé.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.intro, week(1)),
        (WeekKind.build, week(5)),
      ]),
      contains('volume_trop_vite'),
    );
    // Décharge entre deux semaines de charge : la référence reste la
    // semaine de charge.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, week(4)),
        (WeekKind.deload, week(2)),
        (WeekKind.build, week(5)),
      ]),
      isNot(contains('volume_trop_vite')),
    );
    expect(
      rampLimit(
        const <WeekView>[],
        const <double>[],
        0,
        rise: 0.2,
        tolerance: 2,
      ),
      2,
    );
  });

  test('technique_sans_prerequis : format et exercice réservés', () {
    final days = <List<L>>[
      <L>[const L(tractionLestee, 3, reps: 3, load: 20, format: 'cluster')],
    ];
    expect(
      run(testProfile(level: 'beginner'), sameWeeks(1, days)),
      contains('technique_sans_prerequis'),
    );
    expect(
      run(testProfile(level: 'advanced'), sameWeeks(1, days)),
      isNot(contains('technique_sans_prerequis')),
    );
    // Technique structurée de kalis_core 0.4.0 : même règle.
    final structured = <List<L>>[
      <L>[
        const L(
          tractionLestee,
          3,
          reps: 3,
          load: 20,
          technique: SetTechniqueKind.restPause,
        ),
      ],
    ];
    expect(
      run(testProfile(level: 'intermediate'), sameWeeks(1, structured)),
      contains('technique_sans_prerequis'),
    );
    expect(
      run(testProfile(level: 'advanced'), sameWeeks(1, structured)),
      isNot(contains('technique_sans_prerequis')),
    );
    final wave = <List<L>>[
      <L>[
        const L(
          tractionLestee,
          3,
          reps: 3,
          load: 20,
          technique: SetTechniqueKind.wave,
        ),
      ],
    ];
    expect(
      run(testProfile(level: 'intermediate'), sameWeeks(1, wave)),
      contains('technique_sans_prerequis'),
    );
    final supra = <List<L>>[
      <L>[const L('sl-traction-negative-lestee-supramaximale', 2, reps: 2)],
    ];
    expect(
      run(testProfile(level: 'intermediate'), sameWeeks(1, supra)),
      contains('technique_sans_prerequis'),
    );
    expect(
      run(testProfile(level: 'elite'), sameWeeks(1, supra)),
      isNot(contains('technique_sans_prerequis')),
    );
  });

  test('exercice_non_acquis et exercice_trop_avance', () {
    final p = testProfile(
      level: 'beginner',
      records: <Map<String, Object?>>[
        <String, Object?>{
          'exerciseId': traction,
          'measure': 'max_reps',
          'value': 0,
        },
      ],
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 3)],
        ]),
      ),
      contains('exercice_non_acquis'),
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[const L('sw-traction-assistee-elastique', 3)],
        ]),
      ),
      isNot(contains('exercice_non_acquis')),
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[const L('cs-planche', 3, seconds: 5)],
        ]),
      ),
      contains('exercice_trop_avance'),
    );
    expect(
      run(
        testProfile(level: 'advanced'),
        sameWeeks(1, <List<L>>[
          <L>[const L('cs-planche', 3, seconds: 5)],
        ]),
      ),
      isNot(contains('exercice_trop_avance')),
    );
  });

  test('contre_indication : contrainte forte sur une articulation gênée', () {
    final risky = catalog.exercises.firstWhere(
      (e) =>
          e.stressOn(Joint.elbow) == JointStress.high &&
          e.unit == MeasureUnit.repetitions &&
          CatalogTraits.of(catalog).of(e.id).kind.isResistance,
    );
    final safe = catalog.exercises.firstWhere(
      (e) =>
          e.stressOn(Joint.elbow) == JointStress.low &&
          e.unit == MeasureUnit.repetitions &&
          CatalogTraits.of(catalog).of(e.id).kind.isResistance,
    );
    final p = testProfile(
      level: 'elite',
      injuries: <Map<String, Object?>>[
        <String, Object?>{
          'zone': 'elbow',
          'side': 'right',
          'discomfort': 5,
          'status': 'current',
          'label': 'coude douloureux',
        },
      ],
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[L(risky.id, 2)],
        ]),
      ),
      contains('contre_indication'),
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[L(safe.id, 2)],
        ]),
      ),
      isNot(contains('contre_indication')),
    );
    // Sans gêne déclarée, le même exercice passe.
    expect(
      run(
        testProfile(level: 'elite'),
        sameWeeks(1, <List<L>>[
          <L>[L(risky.id, 2)],
        ]),
      ),
      isNot(contains('contre_indication')),
    );
  });

  test('tendon_figures : fréquence et hausse des tenues bras tendus', () {
    final p = testProfile(level: 'beginner');
    List<L> lean(int seconds) => <L>[L('cs-planche-lean', 3, seconds: seconds)];
    expect(
      run(p, sameWeeks(1, <List<L>>[lean(10), lean(10), lean(10)])),
      contains('tendon_figures'),
    );
    expect(
      run(p, sameWeeks(2, <List<L>>[lean(10), lean(10)])),
      isNot(contains('tendon_figures')),
    );
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, <List<L>>[lean(10)]),
        (WeekKind.build, <List<L>>[lean(25)]),
      ]),
      contains('tendon_figures'),
    );
  });

  test('tendon_figures : planche et back lever partagent le budget', () {
    final p = testProfile(level: 'beginner');
    const lean = <L>[L('cs-planche-lean', 3, seconds: 10)];
    const back = <L>[L('cs-back-lever-tuck', 3, seconds: 10)];
    expect(
      run(p, sameWeeks(1, <List<L>>[lean, lean, back])),
      contains('tendon_figures'),
    );
  });

  test('volume_trop_vite : hausse sur deux semaines de charge', () {
    final p = testProfile(level: 'elite');
    List<List<L>> week(int first, int second) => <List<L>>[
      <L>[L(traction, first)],
      <L>[L(traction, second)],
    ];
    // 20, 24 puis 28 séries : chaque pas tient dans +20 %, mais +40 % en
    // deux semaines.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, week(10, 10)),
        (WeekKind.build, week(12, 12)),
        (WeekKind.build, week(14, 14)),
      ]),
      contains('volume_trop_vite'),
    );
    // 20, 23 puis 26 séries : +30 % en deux semaines, admis.
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.build, week(10, 10)),
        (WeekKind.build, week(12, 11)),
        (WeekKind.build, week(13, 13)),
      ]),
      isNot(contains('volume_trop_vite')),
    );
  });

  test('charge_trop_vite : comparée à schéma de répétitions égal', () {
    final p = testProfile(level: 'advanced');
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (
          WeekKind.build,
          <List<L>>[
            <L>[const L(tractionLestee, 3, reps: 5, load: 20)],
          ],
        ),
        (
          WeekKind.build,
          <List<L>>[
            <L>[const L(tractionLestee, 3, reps: 2, load: 35)],
          ],
        ),
      ]),
      isNot(contains('charge_trop_vite')),
    );
  });

  test('contre_indication : contrainte modérée à partir de 6 sur 10', () {
    final moderate = catalog.exercises.firstWhere(
      (e) =>
          e.stressOn(Joint.elbow) == JointStress.moderate &&
          e.unit == MeasureUnit.repetitions &&
          CatalogTraits.of(catalog).of(e.id).kind.isResistance,
    );
    BenchProfile hurt(int discomfort) => testProfile(
      level: 'elite',
      injuries: <Map<String, Object?>>[
        <String, Object?>{
          'zone': 'elbow',
          'side': 'right',
          'discomfort': discomfort,
          'status': 'current',
          'label': 'coude douloureux',
        },
      ],
    );
    final days = sameWeeks(1, <List<L>>[
      <L>[L(moderate.id, 2)],
    ]);
    expect(run(hurt(6), days), contains('contre_indication'));
    expect(run(hurt(5), days), isNot(contains('contre_indication')));
  });

  test('affutage_absent : course seule, mesuré en minutes d\'effort', () {
    final running = catalog.exercises.firstWhere(
      (e) =>
          e.pattern == MovementPattern.cardioContinu &&
          !CatalogTraits.of(catalog).of(e.id).kind.isResistance,
    );
    final p = testProfile(
      events: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'e1',
          'kind': 'competition',
          'label': 'course',
          'weeksOut': 4,
          'targets': <Object?>[
            <String, Object?>{
              'exerciseId': tractionLestee,
              'metric': 'one_rm_kg',
              'targetValue': 60,
            },
          ],
        },
      ],
    );
    List<List<L>> week(int seconds) => <List<L>>[
      <L>[L(running.id, 1, seconds: seconds, flames: null)],
    ];
    expect(run(p, sameWeeks(4, week(1800))), contains('affutage_absent'));
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        ...sameWeeks(3, week(1800)),
        (WeekKind.build, week(900)),
      ]),
      isNot(contains('affutage_absent')),
    );
  });

  test('levier_trop_tot : palier suivant avant le délai du niveau', () {
    final p = testProfile(level: 'intermediate');
    final tuck = <List<L>>[
      <L>[const L('cs-front-lever-tuck', 3, seconds: 10)],
    ];
    final straddle = <List<L>>[
      <L>[const L('cs-front-lever-straddle', 3, seconds: 5)],
    ];
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        ...sameWeeks(3, tuck),
        ...sameWeeks(1, straddle),
      ]),
      contains('levier_trop_tot'),
    );
    expect(run(p, sameWeeks(4, tuck)), isNot(contains('levier_trop_tot')));
  });

  test('echec_risque : échec sur mouvement à risque, quasi-échec débutant', () {
    expect(
      run(
        testProfile(level: 'advanced'),
        sameWeeks(1, <List<L>>[
          <L>[const L('cd-muscle-up-barre-strict', 3, reps: 3, flames: 10)],
        ]),
      ),
      contains('echec_risque'),
    );
    expect(
      run(
        testProfile(level: 'advanced'),
        sameWeeks(1, <List<L>>[
          <L>[const L('cd-muscle-up-barre-strict', 3, reps: 3, flames: 7)],
        ]),
      ),
      isNot(contains('echec_risque')),
    );
    // R5-P27 : au moins 2 répétitions en réserve sur un mouvement à risque
    // élevé, à tout niveau (8 flammes = 1,5 en réserve).
    expect(
      run(
        testProfile(level: 'elite'),
        sameWeeks(1, <List<L>>[
          <L>[const L('cd-muscle-up-barre-strict', 3, reps: 3, flames: 8)],
        ]),
      ),
      contains('echec_risque'),
    );
    // Débutant : aucun échec, même en une seule série sur un mouvement sûr.
    expect(
      run(
        testProfile(level: 'beginner'),
        sameWeeks(1, <List<L>>[
          <L>[const L(pompe, 1, flames: 10)],
        ]),
      ),
      contains('echec_risque'),
    );
    expect(
      run(
        testProfile(level: 'intermediate'),
        sameWeeks(1, <List<L>>[
          <L>[const L(pompe, 1, flames: 10)],
        ]),
      ),
      isNot(contains('echec_risque')),
    );
    expect(
      run(
        testProfile(level: 'beginner'),
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 2, flames: 9)],
        ]),
      ),
      contains('echec_risque'),
    );
    expect(
      run(
        testProfile(level: 'intermediate'),
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 2, flames: 9)],
        ]),
      ),
      isNot(contains('echec_risque')),
    );
  });

  test('seance_trop_longue', () {
    final long = <List<L>>[
      <L>[
        for (final id in <String>[traction, dips, pompe, squat])
          L(id, 5, rest: 180),
      ],
    ];
    final p = testProfile(level: 'advanced');
    expect(
      run(p, sameWeeks(1, long), minutes: 45),
      contains('seance_trop_longue'),
    );
    expect(
      run(p, sameWeeks(1, long), minutes: 90),
      isNot(contains('seance_trop_longue')),
    );
  });

  test('decharge_absente : trop de semaines de charge de suite', () {
    final p = testProfile(level: 'intermediate');
    expect(run(p, sameWeeks(9, base)), contains('decharge_absente'));
    final lightBase = <List<L>>[
      <L>[const L(traction, 1), const L(dips, 1), const L(squat, 1, load: 60)],
      <L>[const L(traction, 1), const L(pompe, 1), const L(squat, 1, load: 60)],
    ];
    final relieved = <(WeekKind, List<List<L>>)>[
      ...sameWeeks(5, base),
      (WeekKind.deload, lightBase),
      ...sameWeeks(3, base),
    ];
    expect(run(p, relieved), isNot(contains('decharge_absente')));
    // Une « décharge » à plein volume n'en est pas une : l'étiquette du
    // moteur ne suffit pas.
    final labelled = <(WeekKind, List<List<L>>)>[
      ...sameWeeks(5, base),
      (WeekKind.deload, base),
      ...sameWeeks(3, base),
    ];
    expect(run(p, labelled), contains('decharge_absente'));
    // Le débutant n'a pas de décharge planifiée avant 12 semaines.
    expect(
      run(testProfile(level: 'beginner'), sameWeeks(9, base)),
      isNot(contains('decharge_absente')),
    );
  });

  test('affutage_absent : volume inchangé la semaine de l\'échéance', () {
    final p = testProfile(
      level: 'advanced',
      events: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'e1',
          'kind': 'competition',
          'label': 'compétition',
          'weeksOut': 6,
          'targets': <Object?>[
            <String, Object?>{
              'exerciseId': tractionLestee,
              'metric': 'one_rm_kg',
              'targetValue': 60,
            },
          ],
        },
      ],
    );
    List<List<L>> week(int sets) => <List<L>>[
      <L>[L(traction, sets), L(dips, sets)],
      <L>[L(traction, sets), L(dips, sets)],
    ];
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.intro, week(4)),
        ...sameWeeks(5, week(4)),
      ]),
      contains('affutage_absent'),
    );
    expect(
      run(p, <(WeekKind, List<List<L>>)>[
        (WeekKind.intro, week(4)),
        ...sameWeeks(4, week(4)),
        (WeekKind.test, week(2)),
      ]),
      isNot(contains('affutage_absent')),
    );
  });

  test('reprise_trop_dure : effort élevé dès la reprise', () {
    final p = testProfile(breakWeeks: 20);
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 2, flames: 8)],
        ]),
      ),
      contains('reprise_trop_dure'),
    );
    expect(
      run(
        p,
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 2, flames: 4)],
        ]),
      ),
      isNot(contains('reprise_trop_dure')),
    );
    expect(
      run(
        testProfile(),
        sameWeeks(1, <List<L>>[
          <L>[const L(traction, 2, flames: 8)],
        ]),
      ),
      isNot(contains('reprise_trop_dure')),
    );
  });

  test('impact_deconseille : senior, mode prudent, débutant en surpoids', () {
    final jump = catalog.exercises.firstWhere(
      (e) => CatalogTraits.of(catalog).of(e.id).impact,
    );
    final days = <List<L>>[
      <L>[L(jump.id, 2)],
    ];
    expect(
      run(testProfile(birthYear: 1955), sameWeeks(1, days)),
      contains('impact_deconseille'),
    );
    expect(
      run(testProfile(outcome: 'cautious'), sameWeeks(1, days)),
      contains('impact_deconseille'),
    );
    final plyo = catalog.exercises.firstWhere(
      (e) => e.pattern == MovementPattern.pliometrie,
    );
    final heavy = testProfile(level: 'beginner', weight: 110, height: 175);
    expect(
      run(
        heavy,
        sameWeeks(1, <List<L>>[
          <L>[L(plyo.id, 2)],
        ]),
      ),
      contains('impact_deconseille'),
    );
    final run5 = catalog.exercises.firstWhere(
      (e) =>
          e.pattern == MovementPattern.cardioContinu &&
          CatalogTraits.of(catalog).of(e.id).impact,
      orElse: () => plyo,
    );
    if (run5.id != plyo.id) {
      expect(
        run(
          heavy,
          sameWeeks(1, <List<L>>[
            <L>[L(run5.id, 1)],
          ]),
        ),
        isNot(contains('impact_deconseille')),
      );
    }
    expect(
      run(testProfile(), sameWeeks(1, days)),
      isNot(contains('impact_deconseille')),
    );
  });

  test('tous les codes rendus sont des critères connus', () {
    final p = testProfile(level: 'beginner', breakWeeks: 30);
    final findings = safetyFindings(
      handProgram(
        p,
        sameWeeks(2, <List<L>>[
          <L>[const L('cs-planche', 9, seconds: 20, flames: 10)],
        ]),
      ),
      p,
    );
    expect(findings, isNotEmpty);
    for (final f in findings) {
      expect(safetyCriteria.containsKey(f.code), isTrue, reason: f.code);
      expect(f.message, isNotEmpty);
      expect(f.toJson()['code'], f.code);
    }
  });
}
