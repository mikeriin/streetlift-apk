/// Outils de test de `kalis_plan` : profils aléatoires seedés, valides et
/// cohérents avec le catalogue (tests de propriétés, simulateur, mode dev).
///
/// À n'importer que depuis des tests ou des simulateurs (`bin/`).
library;

import 'package:kalis_core/kalis_core.dart';

import 'src/hash.dart';

const List<String> _gymEquipment = <String>[
  'barre fixe',
  'barres parallèles',
  'barre basse',
  'barre olympique',
  'barre EZ',
  'disques',
  'haltères',
  'kettlebell',
  'élastique',
  'poulie',
  'machine guidée',
  'Smith machine',
  'presse à cuisses',
  'machine à mollets',
  'banc plat',
  'banc inclinable',
  'banc à lombaires',
  'cage / rack',
  'box / plinth',
  'step',
  'tapis',
  'corde à sauter',
  'rameur',
  'vélo / home-trainer',
  'tapis de course',
  'médecine-ball',
  'roue abdominale',
  'rouleau de massage (foam roller)',
  'corde',
];

const List<String> _parkEquipment = <String>[
  'barre fixe',
  'barres parallèles',
  'barre basse',
  'piste ou terrain extérieur',
  'côte ou escaliers',
];

const List<List<String>> _homeEquipment = <List<String>>[
  <String>[],
  <String>['tapis'],
  <String>['tapis', 'élastique'],
  <String>['tapis', 'élastique', 'haltères', 'banc plat'],
  <String>['tapis', 'barre fixe', 'élastique'],
  <String>['tapis', 'kettlebell', 'corde à sauter'],
  <String>['tapis', 'barre fixe', 'anneaux', 'parallettes', 'élastique'],
  <String>['tapis', 'vélo / home-trainer', 'rouleau de massage (foam roller)'],
];

const List<String> _extras = <String>[
  'ceinture de lest',
  'gilet lesté',
  'anneaux',
  'parallettes',
  'sangles de suspension',
  'bâton',
  'ballon de gym',
  'sliders',
  'air bike (assault / echo)',
  'SkiErg',
  'piscine',
  'sac à dos lesté',
  'balle de massage',
  'cônes',
];

const List<int> _minutes = <int>[
  10,
  15,
  20,
  30,
  30,
  40,
  45,
  45,
  60,
  60,
  75,
  90,
  120,
];

/// Profil aléatoire de graine [seed], valide (`validate()` vide) et dont
/// les exercices et le matériel appartiennent à [catalog].
///
/// Couvre large : les 8 disciplines, 0 à 2 secondaires, mode street, 1 à 7
/// jours de 10 à 120 minutes, 1 à 3 lieux, matériel du plus pauvre au plus
/// complet, matériel par lieu, niveaux déclarés ou « je ne sais pas »,
/// objectifs, limitations, goûts, expérience, questionnaire santé, âges de
/// 16 à 80 ans, poids absent.
AthleteProfile randomProfile(Catalog catalog, int seed) {
  final r = SeededRandom(fnvMix(0x50524F46, seed));
  T pick<T>(List<T> values) => values[r.nextInt(values.length)];
  bool chance(int pct) => r.nextInt(100) < pct;
  int between(int low, int high) => low + r.nextInt(high - low + 1);

  final created = CivilDate(2026, 9, 1).addDays(r.nextInt(60));

  // Disciplines.
  StreetMode? street;
  DisciplineMix mix;
  if (chance(15)) {
    final primary = pick(StreetStyle.values);
    final main = 40 + 10 * r.nextInt(7);
    final rest = 100 - main;
    var a = (rest ~/ 10 == 0 ? 0 : r.nextInt(rest ~/ 10 + 1)) * 10;
    var b = rest - a;
    if (a >= main) {
      a = main - 10;
      b = rest - a;
    }
    if (b >= main) {
      b = main - 10;
      a = rest - b;
    }
    final others = <StreetStyle>[
      for (final s in StreetStyle.values)
        if (s != primary) s,
    ];
    final pct = <StreetStyle, int>{primary: main, others[0]: a, others[1]: b};
    street = StreetMode(
      primary: primary,
      streetliftingPct: pct[StreetStyle.streetlifting]!,
      setsRepsPct: pct[StreetStyle.setsReps]!,
      calisthenicsPct: pct[StreetStyle.calisthenics]!,
    );
    mix = street.toDisciplineMix();
  } else {
    final primary = pick(TrainingDiscipline.values);
    final others = <TrainingDiscipline>[
      for (final d in TrainingDiscipline.values)
        if (d != primary) d,
    ];
    final count = r.nextInt(3);
    if (count == 0) {
      mix = DisciplineMix(
        primary: primary,
        primaryPct: 100,
        secondaries: const <DisciplineShare>[],
      );
    } else if (count == 1) {
      final p = 50 + 5 * r.nextInt(10);
      mix = DisciplineMix(
        primary: primary,
        primaryPct: p,
        secondaries: <DisciplineShare>[
          DisciplineShare(discipline: pick(others), pct: 100 - p),
        ],
      );
    } else {
      final first = pick(others);
      final second = pick(<TrainingDiscipline>[
        for (final d in others)
          if (d != first) d,
      ]);
      final p = 40 + 10 * r.nextInt(5);
      final rest = 100 - p;
      var a = 5 * between(1, rest ~/ 5 - 1);
      if (a > p) {
        a = p;
      }
      var b = rest - a;
      if (b > p) {
        b = p;
        a = rest - b;
      }
      mix = DisciplineMix(
        primary: primary,
        primaryPct: p,
        secondaries: <DisciplineShare>[
          DisciplineShare(discipline: first, pct: a),
          DisciplineShare(discipline: second, pct: b),
        ],
      );
    }
  }

  // Lieux et matériel.
  final placeCount = between(1, 3);
  final shuffled = <Place>[...Place.values];
  for (var i = shuffled.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final t = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = t;
  }
  final places = shuffled.sublist(0, placeCount);
  final perPlace = <Place, List<String>>{};
  for (final place in places) {
    switch (place) {
      case Place.gym:
        perPlace[place] = <String>[
          for (final item in _gymEquipment)
            if (chance(92)) item,
        ];
      case Place.outdoor:
        perPlace[place] = <String>[
          for (final item in _parkEquipment)
            if (chance(80)) item,
        ];
      case Place.home:
        perPlace[place] = <String>[...pick(_homeEquipment)];
    }
  }
  final equipment = <String>[];
  for (final place in places) {
    for (final item in perPlace[place]!) {
      if (!equipment.contains(item)) {
        equipment.add(item);
      }
    }
  }
  final extraOwner = pick(places);
  for (final item in _extras) {
    if (chance(8) && !equipment.contains(item)) {
      equipment.add(item);
      perPlace[extraOwner]!.add(item);
    }
  }
  final byPlace = places.length >= 2 && chance(35)
      ? <PlaceEquipment>[
          for (final place in places)
            PlaceEquipment(place: place, equipment: perPlace[place]!),
        ]
      : null;

  // Disponibilités.
  final weekdays = <int>[1, 2, 3, 4, 5, 6, 7];
  for (var i = weekdays.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final t = weekdays[i];
    weekdays[i] = weekdays[j];
    weekdays[j] = t;
  }
  final dayCount = between(1, 7);
  final chosen = weekdays.sublist(0, dayCount)..sort();
  final availability = <DaySlot>[
    for (final w in chosen)
      DaySlot(
        weekday: w,
        minutes: pick(_minutes),
        place: chance(25) ? pick(places) : null,
      ),
  ];

  // Niveaux, objectifs, goûts.
  final all = catalog.exercises;
  final used = <String>{};
  CatalogExercise fresh() {
    for (var i = 0; i < 50; i++) {
      final e = pick(all);
      if (used.add(e.id)) {
        return e;
      }
    }
    return all.firstWhere((e) => used.add(e.id));
  }

  bool adjustable(LoadType type) =>
      type == LoadType.barbell ||
      type == LoadType.dumbbells ||
      type == LoadType.addedWeight ||
      type == LoadType.machine ||
      type == LoadType.cable ||
      type == LoadType.kettlebell;

  final levels = <MovementLevel>[];
  final levelCount = r.nextInt(6);
  for (var i = 0; i < levelCount; i++) {
    final e = fresh();
    final known = chance(85);
    LevelMeasure measure;
    double low;
    double high;
    double? distance;
    if (e.discipline == CatalogDiscipline.cardio &&
        e.unit == MeasureUnit.seconds) {
      measure = LevelMeasure.timeSeconds;
      low = between(600, 3000).toDouble();
      high = low + between(0, 300);
      distance = (1000 * between(2, 10)).toDouble();
    } else if (e.unit == MeasureUnit.seconds) {
      measure = LevelMeasure.maxHoldSeconds;
      low = between(0, 60).toDouble();
      high = low + between(0, 15);
    } else if (e.unit == MeasureUnit.repetitions && adjustable(e.loadType)) {
      measure = LevelMeasure.oneRmKg;
      low = 2.5 * between(2, 80);
      high = low + 2.5 * between(0, 6);
    } else {
      measure = LevelMeasure.maxReps;
      low = between(0, 40).toDouble();
      high = low + between(0, 6);
    }
    levels.add(
      MovementLevel(
        exerciseId: e.id,
        measure: measure,
        known: known,
        low: known ? low : null,
        high: known ? high : null,
        distanceMeters: distance,
      ),
    );
  }

  final goals = <Goal>[];
  final goalCount = r.nextInt(4);
  for (var i = 0; i < goalCount; i++) {
    final id = 'g${i + 1}';
    if (chance(35)) {
      goals.add(
        Goal(
          id: id,
          kind: GoalKind.habit,
          origin: pick(GoalOrigin.values),
          createdOn: created,
          sessionsPerWeek: between(1, 7),
          weeks: between(4, 12),
        ),
      );
      continue;
    }
    final e = pick(all);
    GoalMetric metric;
    double? value;
    double? distance;
    int? duration;
    double? load;
    if (e.discipline == CatalogDiscipline.cardio) {
      if (chance(50)) {
        metric = GoalMetric.timeSeconds;
        value = between(900, 7200).toDouble();
        distance = (1000 * between(3, 21)).toDouble();
      } else {
        metric = GoalMetric.distanceMeters;
        value = (500 * between(4, 30)).toDouble();
        duration = 60 * between(10, 90);
      }
    } else if (chance(15)) {
      metric = GoalMetric.skillUnlocked;
    } else if (e.unit == MeasureUnit.seconds) {
      metric = GoalMetric.maxHoldSeconds;
      value = between(5, 90).toDouble();
    } else if (adjustable(e.loadType) && chance(70)) {
      metric = GoalMetric.oneRmKg;
      value = 2.5 * between(4, 90);
    } else {
      metric = GoalMetric.maxReps;
      value = between(1, 50).toDouble();
      if (adjustable(e.loadType) && chance(30)) {
        load = 2.5 * between(2, 40);
      }
    }
    goals.add(
      Goal(
        id: id,
        kind: GoalKind.performance,
        origin: pick(GoalOrigin.values),
        createdOn: created,
        exerciseId: e.id,
        metric: metric,
        targetValue: value,
        distanceMeters: distance,
        loadKg: load,
        durationSeconds: duration,
        targetDate: created.addDays(between(20, 240)),
      ),
    );
  }

  final liked = <String>[for (var i = r.nextInt(5); i > 0; i--) fresh().id];
  final disliked = <String>[for (var i = r.nextInt(5); i > 0; i--) fresh().id];
  List<String>? known;
  List<String>? cannot;
  if (chance(20)) {
    known = <String>[for (var i = r.nextInt(4); i > 0; i--) fresh().id];
    cannot = <String>[for (var i = r.nextInt(4); i > 0; i--) fresh().id];
  }

  final limitations = <Limitation>[];
  final zones = <BodyZone>{};
  for (var i = chance(70) ? 0 : between(1, 2); i > 0; i--) {
    final zone = pick(BodyZone.values);
    if (!zones.add(zone)) {
      continue;
    }
    limitations.add(
      Limitation(
        zone: zone,
        side: pick(BodySide.values),
        joint: chance(60) ? zone.joint : null,
        discomfort: between(1, 9),
      ),
    );
  }

  final increments = <LoadIncrement>[
    if (chance(60))
      const LoadIncrement(loadType: LoadType.barbell, stepKg: 2.5, minKg: 20),
    if (chance(60))
      const LoadIncrement(loadType: LoadType.dumbbells, stepKg: 2, minKg: 2),
    if (chance(40))
      const LoadIncrement(loadType: LoadType.addedWeight, stepKg: 1.25),
    if (chance(30))
      const LoadIncrement(loadType: LoadType.machine, stepKg: 5, minKg: 5),
  ];

  final outcome = chance(70)
      ? HealthScreeningOutcome.standard
      : pick(HealthScreeningOutcome.values);
  return AthleteProfile(
    sex: pick(Sex.values),
    birthYear: chance(4) ? 2010 : between(1946, 2008),
    heightCm: between(150, 200),
    bodyWeightKg: chance(10) ? null : between(45, 130).toDouble(),
    disciplines: mix,
    streetMode: street,
    movementLevels: levels,
    goals: goals,
    availability: availability,
    places: places,
    equipment: equipment,
    equipmentByPlace: byPlace,
    loadIncrements: increments,
    limitations: limitations,
    likedExerciseIds: liked,
    dislikedExerciseIds: disliked,
    knownExerciseIds: known,
    cannotDoExerciseIds: cannot,
    experience: chance(50) ? null : pick(ExperienceLevel.values),
    guidanceMode: pick(GuidanceMode.values),
    healthScreening: chance(20)
        ? null
        : HealthScreeningRef(
            questionnaireId: 'l13-v1',
            answeredOn: created,
            outcome: outcome,
          ),
    createdOn: created,
    updatedOn: created,
  );
}

/// Requête de création pour le profil aléatoire de graine [seed].
PlanRequest randomRequest(Catalog catalog, int seed, {int planSeed = 0}) {
  final profile = randomProfile(catalog, seed);
  return PlanRequest(
    profile: profile,
    seed: planSeed,
    startDate: CivilDate(2026, 10, 5),
    locks: const <PlanLock>[],
  );
}
