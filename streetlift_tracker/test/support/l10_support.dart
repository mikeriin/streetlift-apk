// L10 — données et contrôles partagés des tests du générateur : lecture des
// assets depuis le disque (fonction pure, sans Flutter), profils aléatoires
// à graine fixe, contrôles indépendants des propriétés (KT-050 à KT-057).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:streetlift_tracker/models.dart';
import 'package:streetlift_tracker/profile.dart';
import 'package:streetlift_tracker/program_generator.dart';
import 'package:streetlift_tracker/training_estimate.dart';

Map<String, dynamic> readGz(String path) =>
    jsonDecode(utf8.decode(gzip.decode(File(path).readAsBytesSync())))
        as Map<String, dynamic>;

class L10Data {
  final GenModels models;
  final GenCatalog catalog;
  final GenBase base;
  L10Data(this.models, this.catalog, this.base);

  static L10Data? _cached;
  static L10Data load() =>
      _cached ??= L10Data(
        GenModels.fromJsonString(
          File('assets/program_models.json').readAsStringSync(),
        ),
        GenCatalog.fromContent(
          index: readGz('assets/content/index.json.gz'),
          details: readGz('assets/content/details.json.gz'),
          progressions: readGz('assets/content/progressions.json.gz'),
        ),
        GenBase(
          readGz('assets/programme_v33.json.gz'),
          readGz('assets/koach_program.json.gz'),
        ),
      );

  GeneratedProgram generate(
    GenInputs inputs, {
    int seed = 42,
    int firstWeek = 1,
    int cycle = 0,
    String? forceModel,
  }) => generateProgram(
    models: models,
    catalog: catalog,
    base: base,
    inputs: inputs,
    seed: seed,
    firstWeek: firstWeek,
    cycle: cycle,
    forceModel: forceModel,
  );
}

/// Lundi 5 octobre 2026 : départ fixe des profils de test.
final DateTime kL10Start = DateTime(2026, 10, 5);

/// Profil du propriétaire (migration L8 : épreuve des 4 mouvements lestés,
/// secondaire force 70/30, 6 jours, parc + salle, références du classeur).
GenInputs ownerInputs({DateTime? start}) => GenInputs(
  start: start ?? kL10Start,
  goalPrimary: 'event',
  goalSecondary: 'strength',
  goalWeight: 70,
  eventDate: DateTime(2027, 7, 12),
  eventItems: const ['pull_1rm', 'dip_1rm', 'mu_1rm', 'squat_1rm'],
  weekdays: const [1, 2, 3, 4, 5, 6],
  sessionMinutes: 120,
  places: const {
    'park': ['pullup_bar', 'dip_bars', 'weight_belt'],
    'gym': ['pullup_bar', 'dip_bars', 'barbell', 'rack', 'bench', 'weight_belt'],
  },
  autonomy: 'assisted',
  measures: const {
    'pushups': 65,
    'pullups': 30,
    'squatRatio': 120 / 71.5,
    'pullLoadPct': 55 / 71.5 * 100,
    'dipLoadPct': 75 / 71.5 * 100,
  },
  measureSources: const {
    'pushups': 'measured',
    'pullups': 'measured',
    'squatRatio': 'measured',
    'pullLoadPct': 'measured',
    'dipLoadPct': 'measured',
  },
  references: const {'B4': 71.5, 'B8': 55, 'B9': 75, 'B10': 15, 'B11': 120},
);

const _goals = ['health', 'strength', 'endurance', 'event'];
const _minutes = [10, 15, 20, 25, 30, 40, 45, 60, 75, 90, 120, 150, 180, 240];

/// Profil aléatoire (graine fixée) couvrant tout le contrat des entrées.
GenInputs randomInputs(int seed, GenCatalog catalog) {
  final r = Random(seed);
  bool chance(double p) => r.nextDouble() < p;
  final primary = _goals[r.nextInt(_goals.length)];
  final secondary =
      chance(.5) ? _goals[r.nextInt(_goals.length)] : null;
  final days = <int>{};
  final n = 1 + r.nextInt(7);
  while (days.length < n) {
    days.add(1 + r.nextInt(7));
  }
  final places = <String, List<String>>{};
  final allPlaces = kPlaces.map((p) => p.$1).toList();
  final count = 1 + r.nextInt(3);
  while (places.length < count) {
    final p = allPlaces[r.nextInt(allPlaces.length)];
    final eq = <String>{...?kPlaceDefaults[p]};
    for (final e in kEquipment) {
      if (chance(.15)) eq.add(e.$1);
      if (chance(.1)) eq.remove(e.$1);
    }
    places[p] = eq.toList()..sort();
  }
  final dayPlace = <int, String>{};
  for (final d in days) {
    if (chance(.6)) {
      dayPlace[d] = places.keys.elementAt(r.nextInt(places.length));
    }
  }
  final disliked = <String>[];
  for (var k = r.nextInt(4); k > 0; k--) {
    disliked.add(catalog.all[r.nextInt(catalog.all.length)].nom);
  }
  final pains = <String, int>{};
  for (var k = r.nextInt(3); k > 0; k--) {
    final joints = kZoneToJoint.values.toList();
    pains[joints[r.nextInt(joints.length)]] = r.nextInt(11);
  }
  final measures = <String, double>{};
  if (chance(.8)) measures['pushups'] = r.nextInt(100).toDouble();
  if (chance(.7)) measures['pullups'] = r.nextInt(40).toDouble();
  if (chance(.4)) measures['squatRatio'] = .3 + r.nextDouble() * 2.3;
  if (chance(.15)) measures['pullLoadPct'] = r.nextDouble() * 80;
  if (chance(.15)) measures['dipLoadPct'] = r.nextDouble() * 110;
  final refs = <String, double>{};
  if (chance(.3)) {
    refs['B4'] = 50 + r.nextInt(60).toDouble();
    if (chance(.5)) refs['B8'] = r.nextInt(60).toDouble();
    if (chance(.5)) refs['B9'] = r.nextInt(80).toDouble();
    if (chance(.5)) refs['B11'] = 40 + r.nextInt(160).toDouble();
  }
  final items = <String>{};
  for (var k = 1 + r.nextInt(3); k > 0; k--) {
    items.add(kEventItems[r.nextInt(kEventItems.length)].$1);
  }
  final entries = <String, String>{};
  if (chance(.2)) {
    final chains = catalog.chains.entries.toList();
    final c = chains[r.nextInt(chains.length)];
    entries[c.key] = c.value[r.nextInt(c.value.length)];
  }
  const splits = ['auto', 'auto', 'auto', 'fullbody', 'upper_lower', 'ppl'];
  const focus = ['', 'pullups', 'pushups', 'dips', 'squats'];
  return GenInputs(
    start: kL10Start.add(Duration(days: r.nextInt(7))),
    goalPrimary: primary,
    goalSecondary: secondary == primary ? null : secondary,
    goalWeight: 50 + 10 * r.nextInt(6),
    eventDate:
        primary == 'event'
            ? kL10Start.add(Duration(days: 3 + r.nextInt(330)))
            : null,
    eventItems: primary == 'event' ? (items.toList()..sort()) : const [],
    weekdays: days.toList()..sort(),
    sessionMinutes:
        chance(.5)
            ? _minutes[r.nextInt(_minutes.length)]
            : 10 + r.nextInt(231),
    dayPlace: dayPlace,
    places: places,
    disliked: disliked,
    pains: pains,
    caution: chance(.25),
    autonomy: const ['guided', 'assisted', 'expert'][r.nextInt(3)],
    measures: measures,
    references: refs,
    split: splits[r.nextInt(splits.length)],
    focus: focus[r.nextInt(focus.length)],
    entries: entries,
    calibration: chance(.8),
  );
}

// -------------------------------------------------------------- contrôles

int _maxDiff(GenModels m, GenInputs i, MovementLevels lv, GenExercise e) {
  var d = m.mainDifficulty[lv.levels[e.refMovement] ?? lv.global];
  if (i.caution) d -= 1;
  return d < 1 ? 1 : d;
}

bool _achieved(GenCatalog c, GenInputs i, String id) {
  for (final e in i.entries.entries) {
    final steps = c.chains[e.key];
    if (steps == null) continue;
    final at = steps.indexOf(e.value), k = steps.indexOf(id);
    if (k >= 0 && at >= k) return true;
  }
  return false;
}

/// Durée estimée d'une journée, recalculée avec training_estimate.dart
/// (même règle que l'écran pour des exercices non enchaînés).
double dayMinutes(Map<String, dynamic> day) {
  var total = 0.0;
  var first = true;
  for (final e in day['exercises'] as List) {
    final ex = Exercise.fromJson((e as Map).cast<String, dynamic>());
    final t =
        TrainingEstimator.exercise(
          ex,
          prescription: ex.sets.value ?? '',
        ).elapsed.midpoint;
    total += t;
    if (!first && t > 0) total += 45;
    first = false;
  }
  return total / 60;
}

/// Contrôle les propriétés du contrat L10 ; renvoie la liste des écarts.
List<String> checkProgram(
  L10Data data,
  GenInputs i,
  GeneratedProgram g, {
  String tag = '',
}) {
  final out = <String>[];
  final c = data.catalog;
  final lv = movementLevels(data.models, i);
  final weeks = g.program['weeks'] as List;
  if (g.summary['model'] == 'expert_streetlifting') return out;
  var lastUnload = 0;
  final heavyLast = <String, int>{};
  final ceiling = g.summary['ceiling'] as int;
  final required = <String, int>{};
  final trainingKinds =
      (g.summary['kinds'] as List).where((k) => k != 'REC').length;
  final goal = i.goalPrimary;
  if (goal == 'health') {
    for (final f in const ['squat', 'push', 'pull', 'hinge', 'lunge', 'core']) {
      required[f] = 1;
    }
  } else if (trainingKinds >= 2) {
    final fams = switch (goal) {
      'strength' => const {'squat', 'push', 'pull', 'hinge'},
      'endurance' => {
        switch (i.focus) {
          'pushups' || 'dips' => 'push',
          'squats' => 'squat',
          'pullups' => 'pull',
          _ =>
            {for (final l in i.places.values) ...l}.contains('pullup_bar')
                ? 'pull'
                : 'push',
        },
      },
      'event' => {
        for (final it in i.eventItems)
          switch (it) {
            'pull_1rm' || 'pullups_max' || 'mu_1rm' || 'mu_max' => 'pull',
            'squat_1rm' => 'squat',
            _ => 'push',
          },
      },
      _ => const <String>{},
    };
    for (final f in fams) {
      required[f] = 2;
    }
  }
  for (final w in weeks) {
    final wm = w as Map;
    final n = wm['n'] as int;
    final kind = wm['kind'] as String;
    if (kind == 'deload' || kind == 'taper') lastUnload = n;
    if (n - lastUnload > 6) {
      out.add('$tag S$n : pas de décharge depuis ${n - lastUnload} semaines');
    }
    final volume = <String, int>{};
    final famSessions = <String, int>{};
    for (final d in wm['days'] as List) {
      final dm = (d as Map).cast<String, dynamic>();
      final exs = dm['exercises'] as List;
      if (exs.isEmpty) continue;
      final place = dm['place'] as String;
      final eq = packEquipment(place, i.places[place] ?? const []);
      final dayKind = dm['kind'] as String;
      final fams = <String>{};
      for (final e in exs) {
        final em = (e as Map).cast<String, dynamic>();
        final ex = c.byId[em['exId']];
        if (ex == null) {
          out.add('$tag S$n J${dm['j']} : exercice inconnu ${em['exId']}');
          continue;
        }
        if (!ex.materiel.every(eq.contains)) {
          out.add('$tag S$n J${dm['j']} : matériel absent pour ${ex.id} ($place)');
        }
        for (final p in i.pains.entries) {
          if (p.value > 3 && (ex.joints[p.key] ?? 0) > 1) {
            out.add('$tag S$n : ${ex.id} contre-indiqué (${p.key} ${p.value}/10)');
          }
        }
        if (i.caution && ex.impact) {
          out.add('$tag S$n : ${ex.id} avec impact en mode prudent');
        }
        for (final p in ex.prereq) {
          final pe = c.byId[p];
          if (pe == null || _achieved(c, i, p)) continue;
          if (pe.difficulty > _maxDiff(data.models, i, lv, ex)) {
            out.add('$tag S$n : prérequis $p non atteint pour ${ex.id}');
          }
        }
        if (ex.demo != 'disponible') {
          out.add('$tag S$n : ${ex.id} sans démonstration animée');
        }
        final hard = em['hard'];
        if (hard is int) {
          for (final g2 in em['groups'] as List) {
            volume['$g2'] = (volume['$g2'] ?? 0) + hard;
          }
        }
        final role = em['role'] as String;
        if ((role == 'main' || role == 'accessory') && ex.family != null) {
          fams.add(ex.family!);
        }
        if (em['heavy'] == true && ex.family != null) {
          final abs = (n - 1) * 7 + (dm['j'] as int) - 1;
          final prev = heavyLast[ex.family!];
          if (prev != null && prev != abs && abs - prev < 2) {
            out.add('$tag S$n J${dm['j']} : séances lourdes ${ex.family} à moins de 48 h');
          }
          heavyLast[ex.family!] = abs;
        }
      }
      for (final f in fams) {
        famSessions[f] = (famSessions[f] ?? 0) + 1;
      }
      // Durée : ≤ +10 % toujours ; ≥ −10 % en semaine de charge, sauf
      // volume plafonné (signalé), jour de l'épreuve et récupération.
      final minutes = dayMinutes(dm);
      final avail = i.sessionMinutes.toDouble();
      if (dayKind != 'EVENT' && minutes > avail * 1.1 + 1e-9) {
        out.add('$tag S$n J${dm['j']} : ${minutes.toStringAsFixed(1)} min > +10 % de $avail');
      }
      if (kind == 'load' &&
          dayKind != 'EVENT' &&
          dayKind != 'REC' &&
          dm['capped'] != true &&
          minutes < avail * 0.9 - 1e-9) {
        out.add('$tag S$n J${dm['j']} : ${minutes.toStringAsFixed(1)} min < −10 % de $avail sans plafond signalé');
      }
      if ((dm['estimate'] as int) != (minutes * 60).round()) {
        out.add('$tag S$n J${dm['j']} : durée enregistrée ${dm['estimate']} s ≠ ${(minutes * 60).round()} s');
      }
      // Échauffement : 5 à 10 minutes.
      final warm = <Map<String, dynamic>>[
        for (final e in exs)
          if (const {'warmup', 'mobility', 'ramp'}.contains((e as Map)['role']))
            e.cast<String, dynamic>(),
      ];
      if (dayKind != 'REC') {
        final wmin = dayMinutes({'exercises': warm});
        if (wmin < 5 - 1e-9 || wmin > 10 + 1e-9) {
          out.add('$tag S$n J${dm['j']} : échauffement ${wmin.toStringAsFixed(1)} min');
        }
      }
    }
    for (final e in volume.entries) {
      if (e.value > ceiling) {
        out.add('$tag S$n : ${e.key} ${e.value} séries > plafond $ceiling');
      }
    }
    if (kind == 'load' && i.sessionMinutes >= 30 && !wm.containsKey('event')) {
      final eventWeek = (wm['days'] as List).any(
        (d) => (d as Map)['kind'] == 'EVENT',
      );
      if (!eventWeek) {
        for (final r in required.entries) {
          if ((famSessions[r.key] ?? 0) < r.value) {
            out.add('$tag S$n : ${r.key} travaillé ${famSessions[r.key] ?? 0} fois (< ${r.value})');
          }
        }
      }
    }
  }
  return out;
}
