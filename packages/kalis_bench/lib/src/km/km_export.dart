/// Exports du lot KM1 (méthode Koach, `pipeline/cp/CAHIER_KM.md`) : ce que
/// la référence Python de `kalis_adapt` 1.0 lit du banc, sans rien réécrire
/// de mémoire.
///
/// - fiches des exercices du catalogue vues par le modèle de vérité ;
/// - athlètes simulés à vérité connue (tirages de départ) ;
/// - saisons de référence de `kalis_plan` (blocs, calendrier, échéances) ;
/// - traces du modèle de vérité (force, endurance) qui valident son portage ;
/// - mesures du témoin `kalis_adapt` 0.3.1 par saison.
///
/// Ajout pur : aucun fichier existant du banc ne change.
library;

import 'package:kalis_adapt/kalis_adapt.dart';
import 'package:kalis_adapt/simulation.dart';
import 'package:kalis_core/kalis_core.dart';
import 'package:kalis_plan/kalis_plan.dart' show coachPainStopHits;

import '../adapter.dart';
import '../profile.dart';
import '../safety.dart';
import '../season.dart';

/// Version du format des exports KM1.
const int kmExportSchema = 1;

/// Nombre de séances d'un exercice suivies dans les mesures d'estimation.
const int kmEstimateSessions = 24;

/// Fiche d'un exercice telle que le modèle de vérité la lit.
Map<String, Object?> kmExerciseInfo(ExerciseInfo info) {
  final e = info.exercise;
  final kind = enduranceKindOf(info);
  return <String, Object?>{
    'id': e.id,
    'mode': info.mode?.name,
    'fraction': info.fraction,
    'lowerBody': info.lowerBody,
    'groups': <int>[for (final g in info.groups) g.index],
    'groupWeights': info.groupWeights,
    'localFatigue': e.localFatigue,
    'systemicFatigue': e.systemicFatigue,
    'difficulty': e.difficulty,
    'assisted': e.assisted,
    'loadType': e.loadType.name,
    'pattern': e.pattern.name,
    'family': e.family.name,
    'unit': e.unit.name,
    'tendonLoaded': tendonLoaded(info),
    'enduranceKind': kind?.name,
    'zoneLevels': <String, double>{
      for (final z in BodyZone.values) z.code: info.zoneLevel(z),
    },
    'painStopHits': <String>[
      for (final z in BodyZone.values)
        if (coachPainStopHits(e, z)) z.code,
    ],
    'gridStep': info.grid.step,
    'gridMinimum': info.grid.minimum,
    'gridDumbbell': info.grid.dumbbellRule,
  };
}

/// Fiches de tous les exercices du catalogue (grilles de charge par défaut,
/// sans profil).
Map<String, Object?> kmCatalogInfos(Catalog catalog) {
  final book = ExerciseBook(catalog, null);
  final out = <Object?>[];
  for (final e in catalog.exercises) {
    final info = book.find(e.id);
    if (info != null) {
      out.add(kmExerciseInfo(info));
    }
  }
  return <String, Object?>{'schema': kmExportSchema, 'exercises': out};
}

List<double> _truthRow(TruthExercise t) => <double>[
  t.capacity,
  t.curveA,
  t.curveB,
  t.fatigueScale,
  t.holdShare,
  t.slope,
  t.power,
  t.carry,
];

/// Tirages de départ d'un athlète simulé : valide le portage Python de
/// l'initialisation du modèle de vérité.
Map<String, Object?> kmTruthInit(
  Catalog catalog,
  AthleteProfile profile,
  AthleteSpec spec,
  TruthKind kind,
  int seed,
  Iterable<String> ids,
) {
  final book = ExerciseBook(catalog, profile);
  final a = SimAthlete(spec, profile, book, seed, kind: kind);
  final endurance = EnduranceTruth(kind, spec.level, seed);
  final truths = <String, Object?>{};
  for (final id in ids) {
    final t = a.truthOf(id);
    if (t != null) {
      truths[id] = _truthRow(t);
    }
  }
  return <String, Object?>{
    'kind': kind.name,
    'seed': seed,
    'bodyWeightKg': a.bodyWeightKg,
    'sensAcute': a.sensAcute,
    'sensChronic': a.sensChronic,
    'beta': a.beta,
    'noise': a.noise,
    'weeksTrained': a.weeksTrained,
    'endurance': <String, double>{
      'easyMinutes': endurance.easyMinutes,
      'speed': endurance.speed,
      'wod': endurance.wod,
    },
    'truths': truths,
  };
}

/// Saison d'un profil sous un scénario : entrées communes au témoin et à
/// la référence.
final class KmSeason {
  /// Saison du profil [json] sous [scenario].
  KmSeason(Catalog catalog, this.json, this.scenario)
    : base = BenchProfile.fromJson(json),
      scenarioJson = seasonProfileJson(json, scenario),
      weeks = seasonWeeksOf(json, scenario),
      changes = seasonChanges(json, scenario) {
    bench = BenchProfile.fromJson(scenarioJson);
    adapted = adaptProfile(
      BenchProfile.fromJson(
        scenario == SeasonScenario.second ? scenarioJson : json,
      ),
      catalog: catalog,
    );
    specJson = seasonSpecJson(base, scenario);
    spec = athleteFromJson(specJson);
  }

  /// Profil du banc (JSON d'origine).
  final Map<String, Object?> json;

  /// Scénario.
  final SeasonScenario scenario;

  /// Profil du banc d'origine.
  final BenchProfile base;

  /// Profil du banc du scénario (échéances déplacées).
  final Map<String, Object?> scenarioJson;

  /// Durée de la saison, en semaines.
  final int weeks;

  /// Changements de profil en cours de saison.
  final List<ProfileChange> changes;

  /// Profil du banc du scénario.
  late final BenchProfile bench;

  /// Profil des moteurs.
  late final AdaptedProfile adapted;

  /// Réglages de l'athlète simulé.
  late final Map<String, Object?> specJson;

  /// Athlète simulé.
  late final AthleteSpec spec;
}

AdaptationSummary _blankSummary(CivilDate start, int weeks, int sessions) =>
    AdaptationSummary(
      asOf: start.addDays(-1),
      weeksObserved: weeks,
      sessionsPlanned: sessions,
      sessionsCompleted: sessions,
      unlockLevel: UnlockLevel.loadsReps,
      confidence: 0,
      estimates: const <ExerciseEstimate>[],
      pains: const <PainTrend>[],
      avoidedExerciseIds: const <String>[],
      reasons: const <Reason>[],
    );

/// Saison de référence : les blocs que `kalis_plan` écrit seul (résumés
/// d'adaptation vides, comme `SimProgram.block`), les changements de profil
/// du scénario appliqués comme le meneur de simulation les applique. C'est
/// le plan initial et la politique de référence de Koach 1.0 (cahier, § 6).
Map<String, Object?> kmReferenceSeason(
  Catalog catalog,
  PlanEngine plan,
  Map<String, Object?> json,
  SeasonScenario scenario, {
  int truthSeeds = 2,
}) {
  final season = KmSeason(catalog, json, scenario);
  var current = season.adapted.profile;
  final request = PlanRequest(
    profile: current,
    seed: 0,
    startDate: simStartDate,
    locks: const <PlanLock>[],
  );
  final pass1 = plan.createPass1(catalog, request);
  final pass2 = plan.createPass2(
    catalog,
    Pass2Request(request: request, pass1: pass1),
  );
  var block = ProgramBlock(pass1: pass1, pass2: pass2);
  var weekInBlock = 0;
  var blockStart = simStartDate;
  final startDay = simStartDate.dayNumber;
  final blocks = <ProgramBlock>[block];
  final blockWeeks = <int>[0];
  final profiles = <Object?>[
    <String, Object?>{'week': 0, 'label': '', 'profile': current.toJson()},
  ];
  final sessions = <Object?>[];
  final eventDays = <Object?>[];
  var planned = 0;
  for (var g = 0; g < season.weeks; g++) {
    var replan = false;
    for (final c in season.changes) {
      if (c.week != g) {
        continue;
      }
      current = c.apply(current);
      profiles.add(<String, Object?>{
        'week': g,
        'label': c.label,
        'profile': current.toJson(),
      });
      if (c.replan && weekInBlock > 0 && weekInBlock < block.pass1.weeks) {
        replan = true;
      }
    }
    if (weekInBlock >= block.pass1.weeks || replan) {
      blockStart = blockStart.addDays(7 * weekInBlock);
      weekInBlock = 0;
      block = plan
          .nextBlock(
            catalog,
            NextBlockRequest(
              profile: current,
              seed: block.pass1.seed,
              startDate: blockStart,
              previous: block,
              adaptation: _blankSummary(blockStart, g, planned),
              locks: const <PlanLock>[],
            ),
          )
          .block;
      blocks.add(block);
      blockWeeks.add(g);
    }
    WeekPrescription? week;
    for (final w in block.pass2.weeks) {
      if (w.weekIndex == weekInBlock) {
        week = w;
      }
    }
    if (week == null) {
      throw StateError('semaine $weekInBlock absente du bloc');
    }
    final days = <(int, DayPrescription)>[
      for (final d in week.days)
        (scheduledDay(block.pass1, weekInBlock, d.dayIndex), d),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (dayNumber, d) in days) {
      planned++;
      sessions.add(<int>[
        g,
        blocks.length - 1,
        weekInBlock,
        d.dayIndex,
        dayNumber - startDay,
      ]);
    }
    eventDays.add(<int>[
      for (final e in current.events ?? const <SeasonEvent>[])
        e.date.dayNumber - startDay,
    ]);
    weekInBlock++;
  }
  final ids = <String>{};
  for (final b in blocks) {
    for (final w in b.pass2.weeks) {
      for (final d in w.days) {
        for (final it in d.items) {
          ids.add(it.exerciseId);
        }
      }
    }
  }
  final sorted = ids.toList()..sort();
  final book = ExerciseBook(catalog, season.adapted.profile);
  return <String, Object?>{
    'schema': kmExportSchema,
    'key': season.base.key,
    'group': season.base.group,
    'level': season.base.level.index,
    'scenario': scenario.code,
    'weeks': season.weeks,
    'startDate': simStartDate.iso,
    'benchJson': season.scenarioJson,
    'specJson': season.specJson,
    'priorityIds': season.base.priorityIds,
    'profiles': profiles,
    'blockWeeks': blockWeeks,
    'blocks': <Object?>[for (final b in blocks) b.toJson()],
    'sessions': sessions,
    'eventDaysByWeek': eventDays,
    'exerciseIds': sorted,
    'infos': <Object?>[
      for (final id in sorted)
        if (book.find(id) != null) kmExerciseInfo(book.find(id)!),
    ],
    'truthInits': <Object?>[
      for (final kind in TruthKind.values)
        for (var seed = 0; seed < truthSeeds; seed++)
          kmTruthInit(
            catalog,
            season.adapted.profile,
            season.spec,
            kind,
            seed,
            sorted,
          ),
    ],
  };
}

double _round(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Résumé d'une saison simulée du témoin.
Map<String, Object?> kmRunSummary(SimRun run, List<Finding> found) {
  // Capacité vraie d'un exercice à sa première et à sa dernière séance.
  final first = <String, double>{};
  final last = <String, double>{};
  for (final e in run.estimates) {
    first.putIfAbsent(e.exerciseId, () => e.truth);
    last[e.exerciseId] = e.truth;
  }
  // Jour de l'échéance : meilleure valeur réussie et maximum du jour, par
  // exercice (mêmes règles que `CoachMetrics.eventPerformance`).
  final best = <String, double>{};
  final bestExternal = <String, double>{};
  final dayMax = <String, double>{};
  final eventDay = <String, int>{};
  final modes = <String, String>{};
  for (final s in run.sets) {
    if (!(s.eventDay && s.test)) {
      continue;
    }
    final max = s.dayMax;
    if (max == null || max <= 0) {
      continue;
    }
    dayMax[s.exerciseId] = max;
    eventDay[s.exerciseId] = s.simDay;
    modes[s.exerciseId] = s.mode.name;
    final ok = !(s.failed || s.amount < 1);
    final value = s.mode == CapacityMode.loaded
        ? (ok ? s.totalKg ?? 0.0 : 0.0)
        : s.amount.toDouble();
    if (value > (best[s.exerciseId] ?? 0)) {
      best[s.exerciseId] = value;
      if (s.mode == CapacityMode.loaded) {
        bestExternal[s.exerciseId] = s.loadKg ?? 0.0;
      }
    }
    best.putIfAbsent(s.exerciseId, () => 0);
  }
  var gain = 0.0;
  for (final g in run.gain.values) {
    gain += g;
  }
  final codes = <String, int>{};
  for (final f in found) {
    codes[f.code] = (codes[f.code] ?? 0) + 1;
  }
  return <String, Object?>{
    'seed': run.seed,
    'planned': run.sessionsPlanned,
    'done': run.sessionsDone,
    'painAggravations': run.painAggravations,
    'painFlares': run.painFlares,
    'enduranceOveruse': run.enduranceOveruse,
    'worstRunSpike': _round(run.worstRunSpike),
    'violations': found.length,
    'violationCodes': codes,
    'gainMean': run.gain.isEmpty ? null : _round(gain / run.gain.length),
    'gains': <String, double>{
      for (final e in run.gain.entries) e.key: _round(e.value),
    },
    'events': <Object?>[
      for (final id in best.keys)
        <Object?>[
          id,
          modes[id],
          eventDay[id],
          _round(best[id]!),
          bestExternal[id],
          _round(dayMax[id]!),
          first[id] == null ? null : _round(first[id]!),
          last[id] == null ? null : _round(last[id]!),
        ],
    ],
  };
}

/// Accumulateur des erreurs d'estimation par rang de séance de l'exercice.
final class KmEstimateStats {
  /// Accumulateur vide.
  KmEstimateStats();

  /// Par rang (1 à [kmEstimateSessions]) : nombre, somme des erreurs
  /// absolues, somme des erreurs signées, somme des carrés, nombre sous
  /// 3 %, nombre dans l'intervalle à 90 % annoncé.
  final List<List<double>> rows = <List<double>>[
    for (var k = 0; k <= kmEstimateSessions; k++) List<double>.filled(6, 0),
  ];

  /// Premier rang où l'erreur passe sous 3 % (0 : jamais), par exercice et
  /// par saison.
  final List<int> firstUnder = <int>[];

  /// Ajoute les estimations de [run] retenues par [keep].
  void add(SimRun run, bool Function(EstimateRow row) keep) {
    final seen = <String, int>{};
    final ids = <String>{};
    for (final e in run.estimates) {
      if (!keep(e) || e.truth <= 0) {
        continue;
      }
      ids.add(e.exerciseId);
      final k = e.exerciseSession;
      final err = e.capacity / e.truth - 1;
      final abs = err < 0 ? -err : err;
      if (abs < 0.03) {
        seen.putIfAbsent(e.exerciseId, () => k);
      }
      if (k < 1 || k > kmEstimateSessions) {
        continue;
      }
      final r = rows[k];
      r[0] += 1;
      r[1] += abs;
      r[2] += err;
      r[3] += err * err;
      if (abs < 0.03) {
        r[4] += 1;
      }
      if (abs <= 1.6449 * e.relSd) {
        r[5] += 1;
      }
    }
    for (final id in ids) {
      firstUnder.add(seen[id] ?? 0);
    }
  }

  /// Export.
  Map<String, Object?> toJson() => <String, Object?>{
    'bySession': <Object?>[
      for (final r in rows) <double>[for (final v in r) _round(v)],
    ],
    'firstUnder3': firstUnder,
  };
}

/// Mesures du témoin (`kalis_plan` et `kalis_adapt` de ce dépôt, tels que
/// le banc les croise) sur la saison du profil [json] sous [scenario] :
/// [seeds] graines par modèle de vérité, mêmes entrées que
/// `seasonCampaignOf`.
Map<String, Object?> kmWitnessSeason(
  Catalog catalog,
  PlanEngine plan,
  Map<String, Object?> json,
  SeasonScenario scenario, {
  required int seeds,
}) {
  final season = KmSeason(catalog, json, scenario);
  final profile = season.adapted.profile;
  final byTruth = <String, Object?>{};
  for (final truth in TruthKind.values) {
    final summaries = <Object?>[];
    final runs = <SimRun>[];
    final loadedMain = KmEstimateStats();
    final loadedAll = KmEstimateStats();
    final repsAll = KmEstimateStats();
    final holdAll = KmEstimateStats();
    for (var seed = 0; seed < seeds; seed++) {
      final engine = KalisAdapt();
      final run = simulate(
        catalog: catalog,
        spec: season.spec,
        profile: profile,
        seed: seed,
        policy: KalisAdaptPolicy(engine),
        program: SimProgram(catalog, plan, profile, seed: 0),
        weeks: season.weeks,
        loop: engine,
        truthKind: truth,
        changes: season.changes,
      );
      final found = realizedFindings(
        catalog,
        season.bench,
        season.adapted,
        run,
        season.weeks,
      );
      summaries.add(kmRunSummary(run, found));
      loadedMain.add(run, (e) => e.mode == CapacityMode.loaded && e.main);
      loadedAll.add(run, (e) => e.mode == CapacityMode.loaded);
      repsAll.add(run, (e) => e.mode == CapacityMode.reps);
      holdAll.add(run, (e) => e.mode == CapacityMode.hold);
      run.sessions.clear();
      run.blocks.clear();
      run.served.clear();
      run.reviews.clear();
      runs.add(run);
    }
    byTruth[truth.name] = <String, Object?>{
      'runs': summaries,
      'coach': CoachMetrics(runs).toJson(),
      'estimates': <String, Object?>{
        'loadedMain': loadedMain.toJson(),
        'loaded': loadedAll.toJson(),
        'reps': repsAll.toJson(),
        'hold': holdAll.toJson(),
      },
    };
  }
  return <String, Object?>{
    'schema': kmExportSchema,
    'key': season.base.key,
    'scenario': scenario.code,
    'weeks': season.weeks,
    'seeds': seeds,
    'truths': byTruth,
  };
}

/// Trace du modèle de vérité de force : un entraînement scripté (charges,
/// plages et repos tirés d'un générateur seedé, écrits dans la trace) et
/// tout ce que l'athlète simulé répond. Le portage Python rejoue les mêmes
/// entrées et doit retrouver les mêmes sorties.
Map<String, Object?> kmTruthTrace(
  Catalog catalog,
  AthleteProfile profile,
  AthleteSpec spec,
  TruthKind kind,
  int seed,
  List<String> ids, {
  int weeks = 14,
}) {
  final book = ExerciseBook(catalog, profile);
  final a = SimAthlete(spec, profile, book, seed, kind: kind);
  final script = SimRandom.of(seed, 'km-trace');
  final events = <Object?>[];
  final lastLoad = <String, double>{};
  for (var w = 0; w < weeks; w++) {
    for (final d in const <int>[0, 2, 4]) {
      final day = 7 * w + d;
      if (script.next() < 0.1) {
        events.add(<Object?>['skip', day]);
        continue;
      }
      a.advance(day);
      final hc = a.healthCheck(60);
      events.add(<Object?>[
        'day',
        day,
        a.ill,
        a.inPain,
        a.painIntensity,
        a.painUntil,
        a.painZone?.code,
        hc?.toJson(),
      ]);
      var slot = 0;
      for (final id in ids) {
        if (script.next() < 0.25) {
          continue;
        }
        final t = a.truthOf(id);
        if (t == null) {
          continue;
        }
        final slotKey = 'k$slot';
        slot++;
        a.beginExercise(t, slotKey);
        final hold = t.mode == CapacityMode.hold;
        final loaded = t.mode == CapacityMode.loaded;
        final sets = 2 + (script.next() * 3).floor();
        final rows = <Object?>[];
        for (var i = 0; i < sets; i++) {
          final flames = 3 + (script.next() * 7).floor();
          final flamesTarget = script.next() < 0.1 ? 10 : flames;
          int low;
          int high;
          if (hold) {
            low = 10 + (script.next() * 30).floor();
            high = low + (script.next() < 0.5 ? 0 : 10);
          } else {
            low = 1 + (script.next() * 12).floor();
            high =
                low +
                (script.next() < 0.5 ? 0 : 1 + (script.next() * 4).floor());
          }
          double? load;
          if (loaded) {
            final prev = lastLoad[id];
            if (prev == null || script.next() < 0.15) {
              load = a.selfSelect(t, high, Flames.toRir(flamesTarget));
            } else {
              final u = script.next();
              load = u < 0.4
                  ? prev
                  : t.info.grid.next(prev, up: u < 0.8);
            }
            lastLoad[id] = load;
          }
          final rest = 30 + (script.next() * 240).floor();
          final key = '$day|$slotKey|$i';
          final before = a.capacityNow(t, load);
          final reach = a.reachable(t, low, high, Flames.toRir(flamesTarget));
          final ecc = script.next() < 0.05;
          final o = ecc
              ? a.performEccentric(
                  t,
                  loadKg: load,
                  low: low,
                  high: high,
                  flamesTarget: flamesTarget,
                  restSeconds: rest,
                  noiseKey: key,
                )
              : a.perform(
                  t,
                  loadKg: load,
                  low: low,
                  high: high,
                  flamesTarget: flamesTarget,
                  restSeconds: rest,
                  noiseKey: key,
                );
          rows.add(<Object?>[
            i,
            load,
            low,
            high,
            flamesTarget,
            rest,
            ecc,
            before,
            reach,
            o.amount,
            o.flames,
            o.trueRir,
            o.failed,
            a.qualityOf(o),
            t.setFatigue.last,
          ]);
        }
        a.endExercise(t);
        events.add(<Object?>['ex', day, id, slotKey, t.day, t.capacity, rows]);
      }
      final pains = a.sessionPains();
      events.add(<Object?>[
        'end',
        day,
        <Object?>[for (final p in pains) p.toJson()],
        a.painAggravations,
        a.painFlares,
      ]);
    }
    a.endWeek();
    events.add(<Object?>[
      'week',
      w,
      <String, double>{for (final t in a.truths) t.info.id: t.capacity},
      a.painIntensity,
      a.painUntil,
      a.painZone?.code,
      a.painFlares,
    ]);
  }
  return <String, Object?>{
    'kind': kind.name,
    'seed': seed,
    'weeks': weeks,
    'ids': ids,
    'events': events,
  };
}

Map<String, Object?> _doneJson(EnduranceDone d, BodyZone? injured) =>
    <String, Object?>{
      'sets': d.sets,
      'seconds': d.seconds,
      'distanceMeters': d.distanceMeters,
      'reps': d.reps,
      'calories': d.calories,
      'flames': d.flames,
      'success': d.success,
      'injured': injured?.code,
    };

/// Trace du modèle de vérité d'endurance et de conditionnement : séances
/// scriptées sur les prescriptions [runs] et [wods], réponses de la vérité.
Map<String, Object?> kmEnduranceTrace(
  int level,
  TruthKind kind,
  int seed,
  List<ExercisePrescription> runs,
  List<ExercisePrescription> wods, {
  int weeks = 12,
}) {
  final truth = EnduranceTruth(kind, level, seed);
  final script = SimRandom.of(seed, 'km-endurance-trace');
  final events = <Object?>[];
  for (var w = 0; w < weeks; w++) {
    for (final d in const <int>[0, 1, 3, 5]) {
      final day = 7 * w + d;
      final ill = script.next() < 0.05;
      final rates = script.next() < 0.8;
      final pick = script.next();
      final useRun = wods.isEmpty || (runs.isNotEmpty && script.next() < 0.6);
      if (useRun && runs.isNotEmpty) {
        final item = runs[(pick * runs.length).floor() % runs.length];
        final (done, injured) = truth.run(
          item,
          item.sets,
          day,
          0,
          ill: ill,
          rates: rates,
        );
        events.add(<Object?>[
          'run',
          day,
          item.toJson(),
          ill,
          rates,
          _doneJson(done, injured),
        ]);
      } else if (wods.isNotEmpty) {
        final item = wods[(pick * wods.length).floor() % wods.length];
        final share = script.next() < 0.3 ? 0.7 : 1.0;
        final hard = truth.hardStreakBefore(day);
        final (done, injured) = truth.wodPiece(
          item,
          item.sets,
          day,
          0,
          ill: ill,
          rates: rates,
          hardDaysBefore: hard,
          writtenShare: share,
        );
        events.add(<Object?>[
          'wod',
          day,
          item.toJson(),
          ill,
          rates,
          share,
          hard,
          _doneJson(done, injured),
        ]);
      }
      truth.endDay(day);
      events.add(<Object?>[
        'endDay',
        day,
        truth.easyMinutes,
        truth.speed,
        truth.wod,
        truth.overuse,
        truth.worstSpike,
      ]);
    }
  }
  return <String, Object?>{
    'kind': kind.name,
    'seed': seed,
    'level': level,
    'weeks': weeks,
    'events': events,
  };
}
