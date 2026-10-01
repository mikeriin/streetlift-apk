/// Standards de rang par mouvement (D7.5) : tables de référence, mise à
/// l'échelle par sexe et poids de corps, points de rang.
///
/// Sources, tables publiées et limites : `docs/STANDARDS.md`.
library;

import 'package:kalis_core/kalis_core.dart';

import 'numeric.dart';

/// Ce que mesure le standard d'un mouvement.
enum RankMeasure {
  /// 1RM estimé de charge totale (charge externe + fraction du poids du
  /// corps), en kg.
  load,

  /// Répétitions maximales au poids du corps.
  reps,

  /// Tenue d'une figure : échelle de progressions et de secondes.
  hold,

  /// Course : temps équivalent sur 5 km (formule de Riegel).
  run,
}

/// Échelon d'une figure tenue : l'une des progressions [exerciseIds]
/// tenue [seconds] secondes.
final class HoldRung {
  /// Échelon.
  const HoldRung(this.exerciseIds, this.seconds);

  /// Progressions qui valent cet échelon.
  final List<String> exerciseIds;

  /// Tenue demandée, en secondes.
  final int seconds;
}

/// Mouvement de référence et son standard.
final class RankMovement {
  /// Mouvement de référence.
  const RankMovement({
    required this.id,
    required this.measure,
    required this.sources,
    this.male = const <double>[],
    this.female = const <double>[],
    this.rungs = const <HoldRung>[],
  });

  /// Exercice du catalogue qui porte le rang.
  final String id;

  /// Ce que le standard mesure.
  final RankMeasure measure;

  /// Exercices dont les performances comptent pour ce rang.
  final List<String> sources;

  /// Seuils Bronze, Argent, Or, Platine, Diamant d'un homme au poids de
  /// référence : charge externe ou lest en kg ([RankMeasure.load]),
  /// répétitions ([RankMeasure.reps]), secondes sur 5 km
  /// ([RankMeasure.run]).
  final List<double> male;

  /// Les mêmes seuils pour une femme au poids de référence.
  final List<double> female;

  /// Échelons Bronze … Élite d'une figure tenue ([RankMeasure.hold]).
  final List<HoldRung> rungs;
}

/// Tables de référence et calculs de rang.
abstract final class Standards {
  /// Poids de corps de référence des seuils masculins, en kg.
  static const double maleRefKg = 80;

  /// Poids de corps de référence des seuils féminins, en kg.
  static const double femaleRefKg = 60;

  /// Poids de corps le plus bas pris en compte par la mise à l'échelle.
  static const double minBodyWeightKg = 40;

  /// Poids de corps le plus haut pris en compte par la mise à l'échelle.
  static const double maxBodyWeightKg = 140;

  /// Exposant du poids de corps par rang (Bronze … Élite) pour une charge
  /// totale : `seuil(poids) = seuil(réf) × (poids / réf)^b`. Ajustés sur
  /// les tables Strength Level (cinq premiers) ; 2/3 théorique pour Élite.
  static const List<double> loadExponents = <double>[
    1.21,
    1.04,
    0.92,
    0.82,
    0.74,
    0.67,
  ];

  /// Exposant du poids de corps par rang pour des répétitions au poids du
  /// corps (ajusté sur les tables Strength Level).
  static const List<double> repsExponents = <double>[
    0,
    0,
    -0.11,
    -0.27,
    -0.43,
    -0.50,
  ];

  /// Longueur de 5 km, en mètres.
  static const double runMeters = 5000;

  /// Fraction du poids du corps supposée quand le catalogue n'en donne pas
  /// pour un mouvement lesté de référence.
  static const double defaultFraction = 0;

  /// Les mouvements de référence.
  static const List<RankMovement> movements = <RankMovement>[
    RankMovement(
      id: 'sl-traction-lestee',
      measure: RankMeasure.load,
      sources: <String>['sl-traction-lestee'],
      male: <double>[-2, 14, 33, 54, 75],
      female: <double>[-16, -4, 9, 23, 38],
    ),
    RankMovement(
      id: 'sl-dips-leste',
      measure: RankMeasure.load,
      sources: <String>['sl-dips-leste'],
      male: <double>[5, 26, 52, 81, 111],
      female: <double>[-15, 0, 17, 37, 58],
    ),
    RankMovement(
      id: 'sl-muscle-up-leste',
      measure: RankMeasure.load,
      sources: <String>['sl-muscle-up-leste'],
      male: <double>[-10, 1, 14, 28, 42],
      female: <double>[-12, -4, 6, 16, 27],
    ),
    RankMovement(
      id: 'sl-squat-competition',
      measure: RankMeasure.load,
      sources: <String>['sl-squat-competition'],
      male: <double>[75, 101, 132, 168, 206],
      female: <double>[32, 49, 72, 99, 129],
    ),
    RankMovement(
      id: 'mu-back-squat-barre-haute',
      measure: RankMeasure.load,
      sources: <String>[
        'mu-back-squat-barre-haute',
        'mu-back-squat-barre-basse',
      ],
      male: <double>[75, 101, 132, 168, 206],
      female: <double>[32, 49, 72, 99, 129],
    ),
    RankMovement(
      id: 'mu-souleve-de-terre-conventionnel',
      measure: RankMeasure.load,
      sources: <String>[
        'mu-souleve-de-terre-conventionnel',
        'mu-souleve-de-terre-sumo',
      ],
      male: <double>[89, 119, 155, 196, 239],
      female: <double>[40, 60, 86, 116, 149],
    ),
    RankMovement(
      id: 'mu-developpe-couche-barre',
      measure: RankMeasure.load,
      sources: <String>[
        'mu-developpe-couche-barre',
        'mu-developpe-couche-pause',
      ],
      male: <double>[56, 75, 98, 124, 151],
      female: <double>[19, 31, 47, 66, 88],
    ),
    RankMovement(
      id: 'mu-developpe-militaire-barre-debout',
      measure: RankMeasure.load,
      sources: <String>['mu-developpe-militaire-barre-debout'],
      male: <double>[33, 46, 62, 81, 101],
      female: <double>[12, 20, 31, 43, 57],
    ),
    RankMovement(
      id: 'sw-pompe',
      measure: RankMeasure.reps,
      sources: <String>['sw-pompe'],
      male: <double>[5, 19, 39, 62, 87],
      female: <double>[1, 7, 18, 31, 47],
    ),
    RankMovement(
      id: 'sw-traction-pronation',
      measure: RankMeasure.reps,
      sources: <String>[
        'sw-traction-pronation',
        'sw-traction-supination',
        'sw-traction-neutre',
      ],
      male: <double>[1, 7, 13, 21, 30],
      female: <double>[1, 4, 6, 12, 19],
    ),
    RankMovement(
      id: 'sw-dips-barres-paralleles',
      measure: RankMeasure.reps,
      sources: <String>['sw-dips-barres-paralleles'],
      male: <double>[3, 10, 20, 31, 43],
      female: <double>[1, 5, 9, 18, 29],
    ),
    RankMovement(
      id: 'cd-muscle-up-barre-strict',
      measure: RankMeasure.reps,
      sources: <String>['cd-muscle-up-barre-strict'],
      male: <double>[1, 4, 7, 11, 17],
      female: <double>[1, 3, 4, 9, 13],
    ),
    RankMovement(
      id: 'cs-front-lever',
      measure: RankMeasure.hold,
      sources: <String>[
        'cs-front-lever-tuck',
        'cs-front-lever-tuck-avance',
        'cs-front-lever-une-jambe',
        'cs-front-lever-straddle',
        'cs-front-lever-half-lay',
        'cs-front-lever',
        'cs-front-lever-anneaux',
      ],
      rungs: <HoldRung>[
        HoldRung(<String>['cs-front-lever-tuck'], 10),
        HoldRung(<String>['cs-front-lever-tuck-avance'], 10),
        HoldRung(<String>[
          'cs-front-lever-une-jambe',
          'cs-front-lever-straddle',
          'cs-front-lever-half-lay',
        ], 5),
        HoldRung(<String>['cs-front-lever', 'cs-front-lever-anneaux'], 3),
        HoldRung(<String>['cs-front-lever', 'cs-front-lever-anneaux'], 10),
        HoldRung(<String>['cs-front-lever', 'cs-front-lever-anneaux'], 20),
      ],
    ),
    RankMovement(
      id: 'cs-planche',
      measure: RankMeasure.hold,
      sources: <String>[
        'cs-planche-tuck',
        'cs-planche-tuck-avancee',
        'cs-planche-une-jambe',
        'cs-planche-straddle',
        'cs-planche',
        'cs-planche-parallettes',
        'cs-planche-anneaux',
      ],
      rungs: <HoldRung>[
        HoldRung(<String>['cs-planche-tuck'], 10),
        HoldRung(<String>['cs-planche-tuck-avancee'], 10),
        HoldRung(<String>['cs-planche-une-jambe', 'cs-planche-straddle'], 3),
        HoldRung(<String>['cs-planche-une-jambe', 'cs-planche-straddle'], 10),
        HoldRung(<String>[
          'cs-planche',
          'cs-planche-parallettes',
          'cs-planche-anneaux',
        ], 3),
        HoldRung(<String>[
          'cs-planche',
          'cs-planche-parallettes',
          'cs-planche-anneaux',
        ], 10),
      ],
    ),
    RankMovement(
      id: 'cs-handstand',
      measure: RankMeasure.hold,
      sources: <String>[
        'cs-handstand-ventre-au-mur',
        'cs-handstand-dos-au-mur',
        'cs-handstand',
        'cs-handstand-parallettes',
        'cs-one-arm-handstand',
      ],
      rungs: <HoldRung>[
        HoldRung(<String>[
          'cs-handstand-ventre-au-mur',
          'cs-handstand-dos-au-mur',
        ], 30),
        HoldRung(<String>[
          'cs-handstand-ventre-au-mur',
          'cs-handstand-dos-au-mur',
        ], 60),
        HoldRung(<String>['cs-handstand', 'cs-handstand-parallettes'], 10),
        HoldRung(<String>['cs-handstand', 'cs-handstand-parallettes'], 30),
        HoldRung(<String>['cs-handstand', 'cs-handstand-parallettes'], 60),
        HoldRung(<String>['cs-one-arm-handstand'], 5),
      ],
    ),
    RankMovement(
      id: 'ca-footing-endurance-fondamentale',
      measure: RankMeasure.run,
      sources: <String>[
        'ca-footing-endurance-fondamentale',
        'ca-sortie-longue',
        'ca-course-tapis-endurance',
        'ca-course-seuil-tempo',
      ],
      male: <double>[1889, 1579, 1351, 1184, 1060],
      female: <double>[2127, 1808, 1567, 1384, 1247],
    ),
  ];

  static final Map<String, RankMovement> _bySource = <String, RankMovement>{
    for (final m in movements)
      for (final s in m.sources) s: m,
  };

  static final Map<String, RankMovement> _byId = <String, RankMovement>{
    for (final m in movements) m.id: m,
  };

  /// Mouvement de référence d'identifiant [id], ou `null`.
  static RankMovement? movement(String id) => _byId[id];

  /// Mouvement de référence pour lequel les performances de l'exercice
  /// [exerciseId] comptent, ou `null`.
  static RankMovement? sourceOf(String exerciseId) => _bySource[exerciseId];

  /// Mouvement de référence dont l'exercice [exerciseId] hérite le rang :
  /// celui pour lequel il compte, sinon celui de la même chaîne de
  /// variantes du catalogue (même racine) ; `null` s'il n'en a pas.
  static RankMovement? carrierOf(Catalog catalog, String exerciseId) {
    final direct = _bySource[exerciseId];
    if (direct != null) {
      return direct;
    }
    final e = catalog.find(exerciseId);
    if (e == null) {
      return null;
    }
    for (final m in movements) {
      final c = catalog.find(m.id);
      if (c != null && c.rootId == e.rootId) {
        return m;
      }
    }
    return null;
  }

  /// Poids de corps ramené dans l'intervalle de la mise à l'échelle.
  static double clampBodyWeight(double kg) =>
      clampDouble(kg, minBodyWeightKg, maxBodyWeightKg);

  static List<double> _sexThresholds(
    RankMovement m,
    List<double> reference,
    double refKg,
    double bodyWeightKg,
    double fraction,
  ) {
    final ratio = clampBodyWeight(bodyWeightKg) / refKg;
    final out = <double>[];
    switch (m.measure) {
      case RankMeasure.load:
        final totals = <double>[
          for (final v in reference) v + fraction * refKg,
        ];
        totals.add(totals[4] * sqrt(totals[4] / totals[3]));
        for (var t = 0; t < 6; t++) {
          out.add(totals[t] * power(ratio, loadExponents[t]));
        }
      case RankMeasure.reps:
        final reps = List<double>.of(reference);
        reps.add(reps[4] * sqrt(reps[4] / reps[3]));
        for (var t = 0; t < 6; t++) {
          final v = reps[t] * power(ratio, repsExponents[t]);
          out.add(v < 1 ? 1 : v);
        }
      case RankMeasure.run:
        final speeds = <double>[for (final s in reference) runMeters / s];
        speeds.add(speeds[4] * sqrt(speeds[4] / speeds[3]));
        out.addAll(speeds);
      case RankMeasure.hold:
        break;
    }
    return out;
  }

  /// Seuils Bronze … Élite du mouvement [m] pour le sexe [sex] et le poids
  /// de corps [bodyWeightKg], dans l'unité de la performance : charge
  /// totale en kg, répétitions, vitesse en m/s. [fraction] est la fraction
  /// du poids du corps portée par l'exercice (catalogue). Sexe non
  /// précisé : moyenne géométrique des deux tables. Liste vide pour une
  /// figure tenue.
  static List<double> thresholds(
    RankMovement m,
    Sex sex,
    double bodyWeightKg,
    double fraction,
  ) {
    if (m.measure == RankMeasure.hold) {
      return const <double>[];
    }
    final male = _sexThresholds(m, m.male, maleRefKg, bodyWeightKg, fraction);
    final female = _sexThresholds(
      m,
      m.female,
      femaleRefKg,
      bodyWeightKg,
      fraction,
    );
    final List<double> out;
    switch (sex) {
      case Sex.male:
        out = male;
      case Sex.female:
        out = female;
      case Sex.undisclosed:
        out = <double>[for (var t = 0; t < 6; t++) sqrt(male[t] * female[t])];
    }
    // Garde-fou : seuils strictement croissants, quel que soit le poids.
    for (var t = 1; t < out.length; t++) {
      final floor = out[t - 1] * 1.01;
      if (out[t] < floor) {
        out[t] = floor;
      }
    }
    return out;
  }

  /// Points de rang d'une performance [value] face aux seuils
  /// [thresholds] : 1 = Bronze … 6 = Élite, la partie décimale mesure
  /// l'avancement (logarithmique) vers le rang suivant ; de 0 à 1 sous le
  /// Bronze (part du seuil), plafonné à 7.
  static double pointsOf(List<double> thresholds, double value) {
    if (thresholds.length < 6 || value <= 0) {
      return 0;
    }
    if (value < thresholds[0]) {
      return clampDouble(value / thresholds[0], 0, 0.999);
    }
    for (var t = 0; t < 5; t++) {
      if (value < thresholds[t + 1]) {
        final f =
            ln(value / thresholds[t]) / ln(thresholds[t + 1] / thresholds[t]);
        return t + 1 + clampDouble(f, 0, 0.999);
      }
    }
    final over = ln(value / thresholds[5]) / ln(thresholds[5] / thresholds[4]);
    return 6 + clampDouble(over, 0, 1);
  }

  /// Valeur de la performance qui vaut [points] points (inverse de
  /// [pointsOf] entre 1 et 6).
  static double valueAt(List<double> thresholds, double points) {
    final p = clampDouble(points, 1, 6);
    final t = p.floor();
    if (t >= 6) {
      return thresholds[5];
    }
    final f = p - t;
    return thresholds[t - 1] * power(thresholds[t] / thresholds[t - 1], f);
  }

  /// Points de rang d'une figure tenue : [bestSeconds] rend la meilleure
  /// tenue de chaque progression (0 si jamais tenue). Un échelon est
  /// acquis si l'une de ses progressions est tenue le temps demandé, ou si
  /// une progression d'un échelon plus haut, différente, est tenue au
  /// moins [minHold] secondes.
  static double holdPoints(
    RankMovement m,
    double Function(String exerciseId) bestSeconds,
    int minHold,
  ) {
    double best(HoldRung r) {
      var b = 0.0;
      for (final id in r.exerciseIds) {
        final s = bestSeconds(id);
        if (s > b) {
          b = s;
        }
      }
      return b;
    }

    var tier = 0;
    for (var i = 0; i < m.rungs.length; i++) {
      final rung = m.rungs[i];
      var done = best(rung) >= rung.seconds;
      if (!done) {
        for (var j = i + 1; j < m.rungs.length && !done; j++) {
          final harder = m.rungs[j];
          if (harder.exerciseIds.first != rung.exerciseIds.first &&
              best(harder) >= minHold) {
            done = true;
          }
        }
      }
      if (done) {
        tier = i + 1;
      }
    }
    if (tier >= m.rungs.length) {
      return m.rungs.length.toDouble();
    }
    final next = m.rungs[tier];
    final f = best(next) / next.seconds;
    return tier + clampDouble(f, 0, 0.99);
  }

  /// Rang de [points] points.
  static MovementRankTier tierOf(double points) {
    final t = clampInt(points.floor(), 0, 6);
    return MovementRankTier.values[t];
  }
}
