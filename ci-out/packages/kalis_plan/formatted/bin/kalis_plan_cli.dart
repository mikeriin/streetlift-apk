// Simulateur de kalis_plan : rejoue les profils types et une population de
// profils aléatoires seedés, mesure, et écrit le rapport.
//
//   dart run bin/kalis_plan_cli.dart --rapport <dossier> [--profils <n>]
//
// Écrit dans <dossier> :
//   PROFILS_TYPES.md  les 40 cas types (copie de référence : docs/) ;
//   COMPARAISON_L10.md  la comparaison au générateur L10 (idem) ;
//   mesures.json      toutes les mesures, lisibles par un programme ;
//   MESURES.md        les mêmes, en tableaux (copie datée : docs/).
//
// Seul ce fichier lit l'horloge (temps de calcul) : le moteur n'en a pas.
import 'dart:convert';
import 'dart:io';

import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_core/testing.dart';
import 'package:kalis_plan/kalis_plan.dart';
import 'package:kalis_plan/report.dart';
import 'package:kalis_plan/testing.dart';

String? _option(List<String> args, String name) {
  final at = args.indexOf(name);
  return at < 0 || at + 1 >= args.length ? null : args[at + 1];
}

Map<String, Object?> _readJson(String path) {
  final bytes = File(path).readAsBytesSync();
  final text = utf8.decode(path.endsWith('.gz') ? gzip.decode(bytes) : bytes);
  return jsonDecode(text) as Map<String, Object?>;
}

double _r(double v, [int digits = 4]) {
  var scale = 1.0;
  for (var i = 0; i < digits; i++) {
    scale *= 10;
  }
  return (v * scale).roundToDouble() / scale;
}

double _ms(int microseconds) => _r(microseconds / 1000, 1);

/// Quantile [p] (de 0 à 1) d'une liste triée.
double _quantile(List<double> sorted, double p) {
  if (sorted.isEmpty) {
    return 0;
  }
  final rank = (p * (sorted.length - 1)).round();
  return sorted[rank];
}

double _mean(Iterable<double> values) {
  var sum = 0.0;
  var n = 0;
  for (final v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

Map<String, Object?> _summary(List<double> values, {int digits = 4}) {
  final sorted = <double>[...values]..sort();
  return <String, Object?>{
    'n': sorted.length,
    'mean': _r(_mean(sorted), digits),
    'min': sorted.isEmpty ? 0 : _r(sorted.first, digits),
    'p05': _r(_quantile(sorted, 0.05), digits),
    'p50': _r(_quantile(sorted, 0.5), digits),
    'p95': _r(_quantile(sorted, 0.95), digits),
    'p99': _r(_quantile(sorted, 0.99), digits),
    'max': sorted.isEmpty ? 0 : _r(sorted.last, digits),
  };
}

int _time(void Function() body) {
  final watch = Stopwatch()..start();
  body();
  watch.stop();
  return watch.elapsedMicroseconds;
}

/// Médiane de trois mesures de [body].
double _median3(void Function() body) {
  final t = <int>[_time(body), _time(body), _time(body)]..sort();
  return _ms(t[1]);
}

PlanSlot _hashedSlot(Pass1Plan plan, String key) {
  final slots = <PlanSlot>[for (final d in plan.days) ...d.slots];
  return slots[fnv1a32(key) % slots.length];
}

/// Part des exercices libres de [b] absents de [a].
double _distance(Pass1Plan a, Pass1Plan b) {
  final before = planExerciseIds(a);
  final after = planExerciseIds(b);
  if (after.isEmpty) {
    return 0;
  }
  return after.where((e) => !before.contains(e)).length / after.length;
}

AdaptationSummary _adaptation(Pass1Plan plan) => AdaptationSummary(
  asOf: plan.startDate.addDays(plan.weeks * 7 - 1),
  weeksObserved: plan.weeks,
  sessionsPlanned: plan.days.length * plan.weeks,
  sessionsCompleted: plan.days.length * plan.weeks,
  unlockLevel: UnlockLevel.blockRestructure,
  confidence: 0.7,
  estimates: const <ExerciseEstimate>[],
  pains: const <PainTrend>[],
  avoidedExerciseIds: const <String>[],
  reasons: const <Reason>[],
);

String _table(List<String> header, List<List<Object?>> rows) {
  final b = StringBuffer()
    ..writeln('| ${header.join(' | ')} |')
    ..writeln('| ${header.map((_) => '---').join(' | ')} |');
  for (final row in rows) {
    b.writeln('| ${row.join(' | ')} |');
  }
  return b.toString();
}

void main(List<String> args) {
  final outPath = _option(args, '--rapport');
  if (outPath == null) {
    stderr.writeln(
      'usage : dart run bin/kalis_plan_cli.dart --rapport <dossier> '
      '[--profils <n>]',
    );
    exitCode = 64;
    return;
  }
  final population = int.tryParse(_option(args, '--profils') ?? '') ?? 1000;
  final out = Directory(outPath)..createSync(recursive: true);
  const core = '../kalis_core';
  final catalog = Catalog.fromJsonBytes(
    gzip.decode(File('$core/data/catalog_v1.json.gz').readAsBytesSync()),
  );
  final fixtures = readProfileFixtures(
    _readJson('$core/test/fixtures/profiles.json'),
  );
  final owner = OwnerProgram.fromJson(
    _readJson('$core/test/fixtures/owner_program_v33.json.gz'),
  );
  final inspector = PlanInspector(catalog);
  const params = PlanParams.standard;
  final total = Stopwatch()..start();
  final measures = <String, Object?>{
    'engineVersion': kalisPlanVersion,
    'catalogVersion': catalog.sourceVersion,
    'rulesVersion': catalog.rulesVersion,
    'fixtures': fixtures.length,
    'population': population,
  };
  final md = StringBuffer()
    ..writeln('# Mesures de kalis_plan $kalisPlanVersion')
    ..writeln()
    ..writeln(
      'Relevé produit par `dart run bin/kalis_plan_cli.dart --rapport '
      '<dossier>` (catalogue ${catalog.sourceVersion}, règles '
      '${catalog.rulesVersion}) : ${fixtures.length} profils types et '
      '$population profils aléatoires seedés (`lib/testing.dart`, graines '
      '500 000 et suivantes). Les temps dépendent de la machine ; tout le '
      'reste est déterministe.',
    )
    ..writeln();

  // ------------------------------------------------------- 1. profils types
  File(
    '${out.path}/PROFILS_TYPES.md',
  ).writeAsStringSync(profilsTypesMarkdown(catalog, KalisPlan(), fixtures));

  File('${out.path}/COMPARAISON_L10.md').writeAsStringSync(
    l10ComparisonMarkdown(
      catalog,
      KalisPlan(),
      fixtures,
      _readJson('docs/data/l10_sorties.json.gz'),
    ),
  );

  final baseline = <String, Pass1Plan>{};
  final fixtureRows = <List<Object?>>[];
  final fixtureJson = <String, Object?>{};
  final kappas = <double>[];
  for (final f in fixtures) {
    final request = PlanRequest(
      profile: f.profile,
      seed: 0,
      startDate: reportStartDate,
      locks: const <PlanLock>[],
    );
    final plan = KalisPlan().createPass1(catalog, request);
    baseline[f.key] = plan;
    final m = inspector.metrics(request, plan);
    final violations = inspector.hardViolations(request, plan);
    if (m.resistanceMinutes > 0) {
      kappas.add(m.majorCredits / m.resistanceMinutes);
    }
    fixtureJson[f.key] = <String, Object?>{
      'score': _r(plan.score.total),
      'components': <String, double>{
        for (final c in plan.score.components) c.code: _r(c.value),
      },
      'violations': violations,
      'metrics': m.toJson(),
      'ownerWeekResemblance': _r(owner.weekResemblance(planExerciseIds(plan))),
    };
    fixtureRows.add(<Object?>[
      '`${f.key}`',
      plan.score.total.toStringAsFixed(3),
      '${(m.timeUse * 100).round()} %',
      (m.dosageError * 100).toStringAsFixed(1),
      '${(m.inBandShare * 100).round()} %',
      '${m.coveredPatterns}/${m.coverablePatterns}',
      m.slots,
      violations.length,
    ]);
  }
  measures['profiles'] = fixtureJson;
  md
    ..writeln('## 1. Profils types')
    ..writeln()
    ..writeln(
      'Note globale, part du temps disponible utilisée, erreur de dosage '
      '(points de pourcentage), groupes musculaires majeurs dans leur bande '
      'de volume (séries réglées de la passe 2), schémas de base couverts '
      'sur ceux que le matériel et le niveau permettent, nombre '
      'd\'exercices, contraintes dures violées.',
    )
    ..writeln()
    ..writeln(
      _table(<String>[
        'Profil',
        'Note',
        'Temps',
        'Dosage',
        'Volume',
        'Schémas',
        'Exercices',
        'Violations',
      ], fixtureRows),
    );

  // --------------------------------------------------------- 2. temps (types)
  final steps = <String, List<double>>{
    'createPass1': <double>[],
    'createPass2': <double>[],
    'full': <double>[],
    'review': <double>[],
    'variants': <double>[],
    'alternative': <double>[],
    'nextBlock': <double>[],
    'restructure': <double>[],
  };
  for (final f in fixtures) {
    final request = PlanRequest(
      profile: f.profile,
      seed: 0,
      startDate: reportStartDate,
      locks: const <PlanLock>[],
    );
    final plan = baseline[f.key]!;
    final slot = _hashedSlot(plan, '${f.key}:temps');
    final p2Request = Pass2Request(request: request, pass1: plan);
    final pass2 = KalisPlan().createPass2(catalog, p2Request);
    final block = ProgramBlock(pass1: plan, pass2: pass2);
    final create = _median3(() => KalisPlan().createPass1(catalog, request));
    final second = _median3(() => KalisPlan().createPass2(catalog, p2Request));
    steps['createPass1']!.add(create);
    steps['createPass2']!.add(second);
    steps['full']!.add(_r(create + second, 1));
    steps['review']!.add(
      _median3(
        () => KalisPlan().review(
          catalog,
          ReviewRequest(
            request: request,
            current: plan,
            action: ReviewAction(
              kind: ReviewKind.cannotDo,
              slotId: slot.slotId,
            ),
          ),
        ),
      ),
    );
    steps['variants']!.add(
      _median3(
        () => KalisPlan().variants(
          catalog,
          VariantsRequest(request: request, current: plan, slotId: slot.slotId),
        ),
      ),
    );
    // « Autre proposition » : la première est déjà calculée (en cache).
    final alternatives = <int>[];
    for (var i = 0; i < 3; i++) {
      final engine = KalisPlan()..createPass1(catalog, request);
      alternatives.add(
        _time(() => engine.createPass1(catalog, request.copyWith(seed: 1))),
      );
    }
    alternatives.sort();
    steps['alternative']!.add(_ms(alternatives[1]));
    steps['nextBlock']!.add(
      _median3(
        () => KalisPlan().nextBlock(
          catalog,
          NextBlockRequest(
            profile: f.profile,
            seed: 0,
            startDate: plan.startDate.addDays(plan.weeks * 7),
            previous: block,
            adaptation: _adaptation(plan),
            locks: const <PlanLock>[],
          ),
        ),
      ),
    );
    steps['restructure']!.add(
      _median3(
        () => KalisPlan().restructure(
          catalog,
          RestructureRequest(
            profile: f.profile,
            seed: 0,
            today: plan.startDate.addDays(7),
            current: block,
            scope: RestructureScope.block,
            fromWeekIndex: 1,
            reasons: const <Reason>[
              Reason(
                code: ReasonCodes.adaptFatigueHigh,
                params: <String, Object?>{'readiness': 0.3},
              ),
            ],
            locks: const <PlanLock>[],
          ),
        ),
      ),
    );
  }
  const stepNames = <String, String>{
    'createPass1': 'Passe 1 (création)',
    'createPass2': 'Passe 2',
    'full': 'Génération complète (passes 1 + 2)',
    'review': 'Régénération après une action de revue',
    'variants': 'Variantes d\'un exercice',
    'alternative': 'Autre proposition',
    'nextBlock': 'Bloc suivant',
    'restructure': 'Restructuration de la fin du bloc',
  };
  measures['timingsFixturesMs'] = <String, Object?>{
    for (final e in steps.entries) e.key: _summary(e.value, digits: 1),
  };
  md
    ..writeln('## 2. Temps de calcul')
    ..writeln()
    ..writeln(
      'Par profil type : médiane de trois exécutions, moteur neuf à chaque '
      'fois, après un premier passage de mise en route. Temps en '
      'millisecondes sur la machine du contrôle (un cœur).',
    )
    ..writeln()
    ..writeln(
      _table(
        <String>['Opération', 'Médiane', '95e centile', 'Maximum'],
        <List<Object?>>[
          for (final e in steps.entries)
            () {
              final s = <double>[...e.value]..sort();
              return <Object?>[
                stepNames[e.key],
                _quantile(s, 0.5).toStringAsFixed(1),
                _quantile(s, 0.95).toStringAsFixed(1),
                s.last.toStringAsFixed(1),
              ];
            }(),
        ],
      ),
    );

  // ----------------------------------------------------------- 3. population
  final scores = <double>[];
  final timeUse = <double>[];
  final inBand = <double>[];
  final dosage = <double>[];
  final patterns = <double>[];
  final createMs = <double>[];
  final reviewMs = <double>[];
  final resemblance = <double>[];
  final collateral = <String, List<double>>{};
  final componentSums = List<double>.filled(ScoreWeights.codes.length, 0);
  final study = InclusionStudy();
  var violated = 0;
  var invalid = 0;
  var fallbackPlans = 0;
  for (var i = 0; i < population; i++) {
    final seed = 500000 + i;
    final request = randomRequest(catalog, seed);
    final engine = KalisPlan();
    late Pass1Plan plan;
    createMs.add(_ms(_time(() => plan = engine.createPass1(catalog, request))));
    if (inspector.hardViolations(request, plan).isNotEmpty) {
      violated++;
    }
    if (plan.validate().isNotEmpty) {
      invalid++;
    }
    final m = inspector.metrics(request, plan);
    scores.add(plan.score.total);
    timeUse.add(m.timeUse);
    inBand.add(m.inBandShare);
    dosage.add(m.dosageError);
    if (m.coverablePatterns > 0) {
      patterns.add(m.coveredPatterns / m.coverablePatterns);
    }
    for (var k = 0; k < componentSums.length; k++) {
      componentSums[k] += plan.score.components[k].value;
    }
    final ids = planExerciseIds(plan);
    resemblance.add(owner.weekResemblance(ids));
    if (plan.days.any(
      (d) => d.slots.any(
        (s) => s.reasons.any(
          (r) =>
              r.code == ReasonCodes.planJointLimitation ||
              r.code == ReasonCodes.planEquipmentAvailable,
        ),
      ),
    )) {
      fallbackPlans++;
    }
    if (isStreetFree(request.profile)) {
      study.add(inspector, request, plan);
    }
    // Revue : une action par profil, à tour de rôle.
    const kinds = <ReviewKind>[
      ReviewKind.cannotDo,
      ReviewKind.dislike,
      ReviewKind.remove,
    ];
    final kind = kinds[i % kinds.length];
    final slot = _hashedSlot(plan, '$seed:revue');
    late ReviewResult result;
    reviewMs.add(
      _ms(
        _time(
          () => result = engine.review(
            catalog,
            ReviewRequest(
              request: request,
              current: plan,
              action: ReviewAction(kind: kind, slotId: slot.slotId),
            ),
          ),
        ),
      ),
    );
    final others = result.diff.changes
        .where(
          (c) =>
              c.slotId != slot.slotId &&
              (c.kind == ChangeKind.exerciseAdded ||
                  c.kind == ChangeKind.exerciseRemoved ||
                  c.kind == ChangeKind.exerciseReplaced ||
                  c.kind == ChangeKind.exerciseMoved),
        )
        .length;
    (collateral[kind.code] ??= <double>[]).add(others.toDouble());
  }
  measures['population_stats'] = <String, Object?>{
    'hardViolationPlans': violated,
    'invalidPlans': invalid,
    'fallbackPlans': fallbackPlans,
    'score': _summary(scores),
    'timeUse': _summary(timeUse),
    'inBandShare': _summary(inBand),
    'dosageError': _summary(dosage),
    'patternCoverage': _summary(patterns),
    'componentMeans': <String, double>{
      for (var k = 0; k < componentSums.length; k++)
        ScoreWeights.codes[k]: _r(componentSums[k] / population),
    },
    'createPass1Ms': _summary(createMs, digits: 1),
    'reviewMs': _summary(reviewMs, digits: 1),
    'collateralChanges': <String, Object?>{
      for (final e in collateral.entries)
        e.key: <String, Object?>{
          'mean': _r(_mean(e.value), 2),
          'zeroShare': _r(
            e.value.where((v) => v == 0).length / e.value.length,
            3,
          ),
          'max': e.value.reduce((a, b) => a > b ? a : b),
        },
    },
  };
  String row(String name, List<double> values, {double scale = 1}) {
    final s = <double>[...values]..sort();
    String f(double v) => (v * scale).toStringAsFixed(scale == 1 ? 3 : 1);
    return '| $name | ${f(_mean(s))} | ${f(_quantile(s, 0.05))} | '
        '${f(_quantile(s, 0.5))} | ${f(_quantile(s, 0.95))} | ${f(s.first)} | '
        '${f(s.last)} |';
  }

  md
    ..writeln('## 3. Population de $population profils aléatoires')
    ..writeln()
    ..writeln(
      'Programmes avec une contrainte dure violée : **$violated** ; '
      'programmes invalides au sens du contrat : **$invalid** ; programmes '
      'avec au moins une séance de repli : $fallbackPlans.',
    )
    ..writeln()
    ..writeln(
      '| Mesure | Moyenne | 5e centile | Médiane | 95e centile | '
      'Minimum | Maximum |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |')
    ..writeln(row('Note globale', scores))
    ..writeln(row('Temps utilisé (%)', timeUse, scale: 100))
    ..writeln(row('Groupes dans leur bande (%)', inBand, scale: 100))
    ..writeln(row('Erreur de dosage (points)', dosage, scale: 100))
    ..writeln(row('Schémas de base couverts (%)', patterns, scale: 100))
    ..writeln(row('Passe 1 (ms)', createMs))
    ..writeln(row('Régénération en revue (ms)', reviewMs))
    ..writeln()
    ..writeln(
      'Diff minimal — changements d\'exercice hors de l\'emplacement visé, '
      'par action de revue :',
    )
    ..writeln()
    ..writeln(
      _table(
        <String>['Action', 'Moyenne', 'Sans aucun autre changement', 'Maximum'],
        <List<Object?>>[
          for (final e in collateral.entries)
            <Object?>[
              '`${e.key}`',
              _mean(e.value).toStringAsFixed(2),
              '${(e.value.where((v) => v == 0).length / e.value.length * 100).round()} %',
              e.value.reduce((a, b) => a > b ? a : b).round(),
            ],
        ],
      ),
    );

  // ------------------------------------------------------- 4. autres propos.
  final ratios = <double>[];
  final distances = <double>[];
  var reached = 0;
  var proposals = 0;
  final distinct = <double>[];
  for (final f in fixtures) {
    final engine = KalisPlan();
    final request = PlanRequest(
      profile: f.profile,
      seed: 0,
      startDate: reportStartDate,
      locks: const <PlanLock>[],
    );
    final shown = <Pass1Plan>[engine.createPass1(catalog, request)];
    final keys = <String>{jsonEncode(planExerciseIds(shown.first).toList())};
    for (var seed = 1; seed <= 7; seed++) {
      final plan = engine.createPass1(catalog, request.copyWith(seed: seed));
      ratios.add(plan.score.total / shown.first.score.total);
      var least = 1.0;
      for (final previous in shown) {
        final d = _distance(previous, plan);
        if (d < least) {
          least = d;
        }
      }
      distances.add(least);
      proposals++;
      if (least >= params.alternativeMinDistance - 1e-9) {
        reached++;
      }
      shown.add(plan);
      keys.add(jsonEncode(planExerciseIds(plan).toList()));
    }
    distinct.add(keys.length.toDouble());
  }
  measures['alternatives'] = <String, Object?>{
    'proposals': proposals,
    'scoreRatio': _summary(ratios),
    'distanceToShown': _summary(distances),
    'reachedThirdShare': _r(reached / proposals, 3),
    'distinctOfEight': _summary(distinct, digits: 1),
  };
  final sortedRatios = <double>[...ratios]..sort();
  final sortedDistances = <double>[...distances]..sort();
  md
    ..writeln('## 4. « Autre proposition »')
    ..writeln()
    ..writeln(
      'Graines 1 à 7 de chaque profil type ($proposals propositions). Note '
      'rapportée à celle de la meilleure : minimum '
      '${sortedRatios.first.toStringAsFixed(4)}, médiane '
      '${_quantile(sortedRatios, 0.5).toStringAsFixed(4)} (plancher du '
      'contrat : ${(1 - params.alternativeTolerance).toStringAsFixed(2)}). '
      'Part d\'exercices absents de chacune des propositions déjà '
      'montrées : médiane '
      '${(_quantile(sortedDistances, 0.5) * 100).round()} %, minimum '
      '${(sortedDistances.first * 100).round()} % ; '
      '**${(reached / proposals * 100).round()} %** des propositions '
      'atteignent le tiers visé. Programmes distincts parmi les huit '
      'premiers : ${_mean(distinct).toStringAsFixed(1)} en moyenne, '
      '${(<double>[...distinct]..sort()).first.round()} au minimum.',
    )
    ..writeln();

  // --------------------------------------------------------- 5. convergence
  const efforts = <double>[0, 0.25, 0.5, 1, 2, 4];
  final convergence = <List<Object?>>[];
  final convergenceJson = <Object?>[];
  double? reference;
  final atOne = <String, double>{};
  for (final effort in efforts) {
    final engineParams = params.withSearchEffort(effort);
    final values = <double>[];
    final times = <double>[];
    var better = 0;
    var worse = 0;
    for (final f in fixtures) {
      final request = PlanRequest(
        profile: f.profile,
        seed: 0,
        startDate: reportStartDate,
        locks: const <PlanLock>[],
      );
      late Pass1Plan plan;
      times.add(
        _ms(
          _time(
            () => plan = KalisPlan(
              params: engineParams,
            ).createPass1(catalog, request),
          ),
        ),
      );
      final objective = inspector.objective(request, plan);
      values.add(objective);
      if (effort == 1) {
        atOne[f.key] = objective;
      } else if (effort > 1 && objective > atOne[f.key]! + 1e-9) {
        better++;
      } else if (effort > 1 && objective < atOne[f.key]! - 1e-9) {
        worse++;
      }
    }
    final mean = _mean(values);
    if (effort == 1) {
      reference = mean;
    }
    convergenceJson.add(<String, Object?>{
      'effort': effort,
      'annealIterations': engineParams.annealIterations,
      'meanObjective': _r(mean, 5),
      'meanMs': _r(_mean(times), 1),
      if (effort > 1) 'profilesImproved': better,
      if (effort > 1) 'profilesWorse': worse,
    });
    convergence.add(<Object?>[
      '× $effort',
      engineParams.annealIterations,
      mean.toStringAsFixed(5),
      _mean(times).toStringAsFixed(1),
      effort > 1 ? better : '—',
      effort > 1 ? worse : '—',
    ]);
  }
  measures['convergence'] = <String, Object?>{
    'rows': convergenceJson,
    'referenceObjective': reference == null ? null : _r(reference, 5),
  };
  md
    ..writeln('## 5. Convergence de la recherche')
    ..writeln()
    ..writeln(
      'Objectif moyen (sécurité + note globale, de 0 à 2) des 40 profils '
      'types selon l\'effort de recuit ; dernières colonnes : profils dont '
      'l\'objectif est au-dessus, puis au-dessous, de celui de l\'effort '
      '× 1.',
    )
    ..writeln()
    ..writeln(
      _table(<String>[
        'Effort',
        'Coups de recuit',
        'Objectif moyen',
        'Temps moyen (ms)',
        'Profils améliorés',
        'Profils dégradés',
      ], convergence),
    );

  // --------------------------------------------------------- 6. sensibilité
  final sensitivity = <List<Object?>>[];
  final sensitivityJson = <String, Object?>{};
  for (final code in ScoreWeights.codes) {
    final cells = <Object?>['`$code`'];
    final entry = <String, Object?>{};
    for (final factor in const <double>[0.8, 1.2]) {
      final engineParams = params.withWeights(
        params.weights.scaled(code, factor),
      );
      final overlaps = <double>[];
      final regrets = <double>[];
      var same = 0;
      for (final f in fixtures) {
        final request = PlanRequest(
          profile: f.profile,
          seed: 0,
          startDate: reportStartDate,
          locks: const <PlanLock>[],
        );
        final plan = KalisPlan(
          params: engineParams,
        ).createPass1(catalog, request);
        // Regret : ce que le programme obtenu avec le poids modifié perd,
        // jugé avec les poids de référence.
        regrets.add(
          inspector.objective(request, baseline[f.key]!) -
              inspector.objective(request, plan),
        );
        final j = jaccard(
          planExerciseIds(baseline[f.key]!),
          planExerciseIds(plan),
        );
        overlaps.add(j);
        if (j > 1 - 1e-12) {
          same++;
        }
      }
      entry['x$factor'] = <String, Object?>{
        'meanJaccard': _r(_mean(overlaps), 3),
        'identicalPlans': same,
        'meanRegret': _r(_mean(regrets), 5),
      };
      cells
        ..add(_mean(overlaps).toStringAsFixed(2))
        ..add(same)
        ..add(_mean(regrets).toStringAsFixed(4));
    }
    sensitivityJson[code] = entry;
    sensitivity.add(cells);
  }
  measures['sensitivity'] = sensitivityJson;
  md
    ..writeln('## 6. Sensibilité aux poids de la note')
    ..writeln()
    ..writeln(
      'Chaque poids multiplié par 0,8 puis 1,2, les autres inchangés : '
      'recouvrement moyen (Jaccard) des exercices avec le programme de '
      'référence sur les 40 profils types, nombre de programmes '
      'identiques, et regret moyen (objectif de référence perdu par le '
      'programme obtenu, sur une échelle de 0 à 2).',
    )
    ..writeln()
    ..writeln(
      _table(<String>[
        'Poids',
        'Jaccard × 0,8',
        'Identiques',
        'Regret',
        'Jaccard × 1,2',
        'Identiques',
        'Regret',
      ], sensitivity),
    );

  // -------------------------------------------- 7. crédits par minute (κ)
  final sortedKappa = <double>[...kappas]..sort();
  measures['creditsPerMinute'] = <String, Object?>{
    'parameter': params.creditsPerMinute,
    'measured': _summary(kappas, digits: 3),
  };
  md
    ..writeln('## 7. Séries créditées par minute de renforcement')
    ..writeln()
    ..writeln(
      'Séries fractionnaires créditées aux groupes majeurs par minute de '
      'renforcement, sur les profils types qui en comportent '
      '(${kappas.length}) : moyenne ${_mean(kappas).toStringAsFixed(2)}, '
      'médiane ${_quantile(sortedKappa, 0.5).toStringAsFixed(2)}, de '
      '${sortedKappa.first.toStringAsFixed(2)} à '
      '${sortedKappa.last.toStringAsFixed(2)}. Paramètre '
      '`creditsPerMinute` : ${params.creditsPerMinute}.',
    )
    ..writeln();

  // ---------------------------------------------------- 8. non-ressemblance
  final self = owner.crossBlockResemblances();
  final byGroup = <String, List<double>>{
    'propriétaire': <double>[],
    'street': <double>[],
    'sans street': <double>[],
  };
  final sessionMax = <double>[];
  for (final f in fixtures) {
    final engine = KalisPlan();
    for (var seed = 0; seed < 4; seed++) {
      final plan = engine.createPass1(
        catalog,
        PlanRequest(
          profile: f.profile,
          seed: seed,
          startDate: reportStartDate,
          locks: const <PlanLock>[],
        ),
      );
      final j = owner.weekResemblance(planExerciseIds(plan));
      final group = f.key.startsWith('proprietaire')
          ? 'propriétaire'
          : (isStreetFree(f.profile) ? 'sans street' : 'street');
      byGroup[group]!.add(j);
      for (final d in plan.days) {
        sessionMax.add(
          owner.sessionResemblance(<String>{
            for (final s in d.slots) s.exerciseId,
          }),
        );
      }
    }
  }
  final findings = study.findings(catalog, owner)
    ..sort((a, b) => b.rate.compareTo(a.rate));
  final over = findings.where((f) => f.overRepresented).toList();
  final overSpecific = over.where((f) => f.ownerSpecific).toList();
  final sortedResemblance = <double>[...resemblance]..sort();
  final sortedSessions = <double>[...sessionMax]..sort();
  measures['ownerResemblance'] = <String, Object?>{
    'limit': ownerWeekResemblanceLimit,
    'ownerWeeks': owner.weeks.length,
    'ownerExercises': owner.exerciseIds.length,
    'ownerAccessories': owner.accessories.length,
    'selfCrossBlock': _summary(self),
    'selfCrossBlockP10': _r(_quantile(self, 0.10)),
    'fixtures': <String, Object?>{
      for (final e in byGroup.entries) e.key: _summary(e.value),
    },
    'population': _summary(resemblance),
    'sessionMax': _summary(sessionMax),
    'streetFreePlans': study.plans,
    'accessoryFindings': <Object?>[for (final f in findings) f.toJson()],
    'overRepresented': <String>[for (final f in over) f.exerciseId],
    'overRepresentedOwnerSpecific': <String>[
      for (final f in overSpecific) f.exerciseId,
    ],
  };
  md
    ..writeln('## 8. Non-ressemblance au programme du propriétaire')
    ..writeln()
    ..writeln(
      'Programme du propriétaire : ${owner.weeks.length} semaines, '
      '${owner.exerciseIds.length} exercices du catalogue, dont '
      '${owner.accessories.length} accessoires. Ressemblance = indice de '
      'Jaccard entre les exercices de la semaine type générée et ceux de '
      'la semaine du propriétaire la plus proche. Le programme du '
      'propriétaire comparé à lui-même, entre semaines de blocs différents : '
      'minimum ${self.first.toStringAsFixed(2)}, premier décile '
      '${_quantile(self, 0.10).toStringAsFixed(2)}, médiane '
      '${_quantile(self, 0.5).toStringAsFixed(2)}. Seuil : '
      '$ownerWeekResemblanceLimit.',
    )
    ..writeln()
    ..writeln(
      _table(
        <String>['Programmes générés', 'Nombre', 'Médiane', 'Maximum'],
        <List<Object?>>[
          for (final e in byGroup.entries)
            () {
              final s = <double>[...e.value]..sort();
              return <Object?>[
                'Profils types — ${e.key} (graines 0 à 3)',
                s.length,
                _quantile(s, 0.5).toStringAsFixed(3),
                s.last.toStringAsFixed(3),
              ];
            }(),
          <Object?>[
            'Population aléatoire',
            sortedResemblance.length,
            _quantile(sortedResemblance, 0.5).toStringAsFixed(3),
            sortedResemblance.last.toStringAsFixed(3),
          ],
        ],
      ),
    )
    ..writeln(
      'Séance par séance (profils types, graines 0 à 3) : ressemblance '
      'maximale avec une séance du propriétaire, médiane '
      '${_quantile(sortedSessions, 0.5).toStringAsFixed(2)}, maximum '
      '${sortedSessions.last.toStringAsFixed(2)}.',
    )
    ..writeln()
    ..writeln(
      'Accessoires du propriétaire chez les ${study.plans} profils '
      'aléatoires sans discipline street : part des profils (où l\'exercice '
      'est admissible) dont le programme le contient, face à l\'exercice '
      'hors programme du propriétaire le plus choisi de la même catégorie. '
      'Sur-représenté = plus de 5 % et plus du double de ce pair. '
      'Accessoires propres au propriétaire (exercices des disciplines '
      'street de la base) sur-représentés : **${overSpecific.length}**'
      '${overSpecific.isEmpty ? '' : ' (${overSpecific.map((f) => '`${f.exerciseId}`').join(', ')})'}'
      ' ; accessoires du fonds commun de la musculation au-dessus de la '
      'même règle : ${over.length - overSpecific.length}'
      '${over.length == overSpecific.length ? '' : ' (${over.where((f) => !f.ownerSpecific).map((f) => '`${f.exerciseId}`').join(', ')})'}.',
    )
    ..writeln()
    ..writeln(
      _table(
        <String>[
          'Accessoire du propriétaire',
          'Propre',
          'Catégorie',
          'Admissible',
          'Choisi',
          'Meilleur pair',
          'Choisi',
        ],
        <List<Object?>>[
          for (final f in <AccessoryFinding>[
            ...findings.where((f) => f.ownerSpecific),
            ...findings.where((f) => !f.ownerSpecific).take(14),
          ])
            <Object?>[
              '`${f.exerciseId}`',
              f.ownerSpecific ? 'oui' : 'non',
              f.category,
              f.admissible,
              '${(f.rate * 100).toStringAsFixed(1)} %',
              f.bestPeerId == null ? '—' : '`${f.bestPeerId}`',
              '${(f.bestPeerRate * 100).toStringAsFixed(1)} %',
            ],
        ],
      ),
    );

  total.stop();
  measures['reportSeconds'] = total.elapsed.inSeconds;
  File('${out.path}/mesures.json').writeAsStringSync(
    '${const JsonEncoder.withIndent(' ').convert(measures)}\n',
  );
  File('${out.path}/MESURES.md').writeAsStringSync(md.toString());
  stdout.writeln(
    'kalis_plan $kalisPlanVersion : rapport écrit dans ${out.path} '
    '(${total.elapsed.inSeconds} s).',
  );
}
