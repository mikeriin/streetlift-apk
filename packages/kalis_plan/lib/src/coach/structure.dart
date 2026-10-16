part of 'skeleton.dart';

// ------------------------------------------------- structure de la semaine
//
// Lot KS1 (`pipeline/cp/CAHIER_KS.md`) : un coach décide de haut en bas —
// besoins, fréquence, gabarit de semaine, type de chaque jour, exercices,
// charges. Le gabarit devient une variable de décision explicite, choisie
// dans une bibliothèque avant les exercices, par une règle écrite et
// déterministe (§ 3.4) ; chaque jour porte un type (schémas, qualité,
// charge).

/// Codes stables des gabarits de semaine (CAHIER_KS.md § 3.2). Les chemins
/// d'avant 0.4.0 de `kalis_plan` sont des gabarits de la bibliothèque : un
/// profil mono-discipline garde le sien.
abstract final class SplitTemplates {
  /// Deux séances corps entier : force, puis endurance de force.
  static const String fullBody2 = 'fb2';

  /// Trois séances corps entier, qualités selon les parts du profil.
  static const String fullBody3 = 'fb3';

  /// Quatre séances : haut force, bas force, haut endurance, bas endurance.
  static const String upperLower4 = 'ul4';

  /// Six séances : tirage, poussée, jambes en force, puis en endurance de
  /// force (puissance sur le jour jambes quand le muscle-up est visé).
  static const String pushPullLegs6 = 'ppl6_q';

  /// Cinq séances : tirage et poussée dans les deux qualités, un jour
  /// jambes de la qualité dominante.
  static const String pushPullLegs5 = 'pp_l5';

  /// Gabarit composite : les jours de force suivent le chemin
  /// streetlifting, les jours d'endurance le chemin sets & reps (toute
  /// répartition des séances).
  static const String mixed = 'mix_q';

  /// Streetlifting : un mouvement lourd par jour, ondulation par mouvement.
  static const String liftDup = 'lift_dup';

  /// Sets & reps : piliers de répétitions.
  static const String repsPillars = 'reps_pillars';

  /// Calisthénie : figures.
  static const String figures = 'figures';

  /// Débutant : corps entier.
  static const String beginner = 'fb_beginner';

  /// Musculation : hypertrophie.
  static const String hypertrophy = 'gym_split';

  /// Force : squat, couché, terre.
  static const String strength = 'power_dup';

  /// Course et cardio.
  static const String endurance = 'run_week';

  /// Conditionnement.
  static const String conditioning = 'wod_week';

  /// Santé, mobilité, forme générale.
  static const String health = 'health_week';
}

/// Gabarit du chemin de [style].
String templateOfStyle(CoachStyle style) => switch (style) {
  CoachStyle.beginner => SplitTemplates.beginner,
  CoachStyle.reps => SplitTemplates.repsPillars,
  CoachStyle.lifting => SplitTemplates.liftDup,
  CoachStyle.figures => SplitTemplates.figures,
  CoachStyle.hypertrophy => SplitTemplates.hypertrophy,
  CoachStyle.strength => SplitTemplates.strength,
  CoachStyle.endurance => SplitTemplates.endurance,
  CoachStyle.conditioning => SplitTemplates.conditioning,
  CoachStyle.health => SplitTemplates.health,
};

/// Part, en %, à partir de laquelle une discipline secondaire crée ses
/// propres jours ; en dessous, elle reste en compléments (décision du
/// propriétaire, CAHIER_KS.md § 11.1 : « 25 % c'est bien »).
const int coachDayShareMin = 25;

/// Hausse, en points de part, de la qualité de l'échéance en
/// intensification et en réalisation (CAHIER_KS.md § 3.3.2 : 65 à 75 % de
/// spécifique pour un objectif de répétitions, contrat § 12.13 ; même
/// logique pour la force). Choix raisonné : vingt points font passer une
/// répartition 50/50 à 70/30.
const int coachTargetShareRise = 20;

/// Part déclarée de la discipline [d] dans le profil de [a], en %.
int _shareOf(Athlete a, TrainingDiscipline d) {
  final mix = a.profile.disciplines;
  if (mix.primary == d) {
    return mix.primaryPct;
  }
  for (final s in mix.secondaries) {
    if (s.discipline == d) {
      return s.pct;
    }
  }
  return 0;
}

/// Parts (en %) de la force lestée et de l'endurance de force d'un athlète
/// street qui déclare les deux à [coachDayShareMin] % au moins (et peut
/// lester ses mouvements) ; `null` sinon : un profil mono-discipline garde
/// le gabarit de son chemin. La calisthénie secondaire reste servie par
/// les jours de pratique de figure du chemin sets & reps (blocs courts en
/// tête de deux séances : R4-F1, R4-F8 — une figure demande des
/// expositions fréquentes et courtes, pas une séance entière par semaine ;
/// choix raisonné). La spécialisation garde son chemin (R4-H1 à H4).
(int, int)? mixedStreetShares(Athlete a, CoachStyle style) {
  if (a.level == 0 ||
      (style != CoachStyle.lifting && style != CoachStyle.reps) ||
      a.profile.specialization != null ||
      !hasBelt(a)) {
    return null;
  }
  final force = _shareOf(a, TrainingDiscipline.streetlifting);
  final endurance = _shareOf(a, TrainingDiscipline.streetWorkout);
  if (force < coachDayShareMin || endurance < coachDayShareMin) {
    return null;
  }
  return (force, endurance);
}

/// Séances de force et d'endurance sur [n] séances pour des parts [force]
/// et [endurance] : méthode du plus fort reste (Hamilton), à égalité la
/// qualité de la discipline principale ([forceFirst]) ; une séance au
/// moins pour chaque qualité (elle porte des objectifs ou un quart du
/// profil ; CAHIER_KS.md § 3.3.3).
(int, int) coachQualitySessions(
  int n,
  int force,
  int endurance, {
  required bool forceFirst,
}) {
  if (n < 2) {
    return forceFirst ? (1, 0) : (0, 1);
  }
  final total = force + endurance;
  final f = n * force / total;
  final e = n * endurance / total;
  var nf = f.floor();
  var ne = e.floor();
  while (nf + ne < n) {
    final rf = f - nf;
    final re = e - ne;
    if (rf > re + 1e-9 || ((rf - re).abs() <= 1e-9 && forceFirst)) {
      nf++;
    } else {
      ne++;
    }
  }
  if (nf == 0) {
    nf = 1;
    ne = n - 1;
  }
  if (ne == 0) {
    ne = 1;
    nf = n - 1;
  }
  return (nf, ne);
}

/// Nature d'un jour d'un gabarit typé.
enum _Kind {
  pullForce,
  pushForce,
  legsForce,
  pullEndurance,
  pushEndurance,
  legsEndurance,
  upperForce,
  lowerForce,
  upperEndurance,
  lowerEndurance,
  fullForce,
  fullEndurance;

  bool get force =>
      this == pullForce ||
      this == pushForce ||
      this == legsForce ||
      this == upperForce ||
      this == lowerForce ||
      this == fullForce;

  /// Schémas chargés du jour (récupération, placement).
  Set<DayPattern> get schemas => switch (this) {
    pullForce || pullEndurance => const <DayPattern>{DayPattern.pull},
    pushForce || pushEndurance => const <DayPattern>{DayPattern.push},
    legsForce ||
    legsEndurance ||
    lowerForce ||
    lowerEndurance => const <DayPattern>{DayPattern.legs},
    upperForce ||
    upperEndurance => const <DayPattern>{DayPattern.pull, DayPattern.push},
    fullForce || fullEndurance => const <DayPattern>{
      DayPattern.pull,
      DayPattern.push,
      DayPattern.legs,
    },
  };

  /// Schémas écrits au type du jour.
  List<DayPattern> get patterns => switch (this) {
    pullForce || pullEndurance => const <DayPattern>[DayPattern.pull],
    pushForce || pushEndurance => const <DayPattern>[DayPattern.push],
    legsForce ||
    legsEndurance ||
    lowerForce ||
    lowerEndurance => const <DayPattern>[DayPattern.legs],
    upperForce ||
    upperEndurance => const <DayPattern>[DayPattern.pull, DayPattern.push],
    fullForce || fullEndurance => const <DayPattern>[DayPattern.full],
  };

  /// Thème de la séance.
  String get focus => switch (this) {
    pullForce || pullEndurance => FocusCodes.pull,
    pushForce || pushEndurance => FocusCodes.push,
    legsForce ||
    legsEndurance ||
    lowerForce ||
    lowerEndurance => FocusCodes.lower,
    upperForce || upperEndurance => FocusCodes.upper,
    fullForce || fullEndurance => FocusCodes.fullBody,
  };

  /// Rang de durée attendue (le jour le plus court reçoit le type le moins
  /// long : CAHIER_KS.md § 3.5).
  int get length => switch (this) {
    fullForce || fullEndurance || upperForce || upperEndurance => 3,
    pullForce || pullEndurance || pushForce || pushEndurance => 2,
    _ => 1,
  };
}

/// Exigence d'un mouvement de compétition (CAHIER_KS.md § 11.2 : intensité
/// relative × part du 1RM système, complexité technique, risque
/// articulaire). Le muscle-up lesté est classé premier (décision du
/// propriétaire) ; puis la traction lestée (« tirage toujours en premier
/// si c'est le mouvement qui demande le plus de ressources »), le dips
/// lesté et le squat — choix raisonné : à part du 1RM égale, le tirage
/// lesté et le dips engagent le coude et l'épaule en fin d'amplitude
/// (R5-P20, R5-P27), le squat se règle à la barre ; 0 hors des quatre.
int coachLiftDemand(String id) => switch (id) {
  Ids.weightedMuscleUp => 4,
  Ids.weightedPull => 3,
  Ids.weightedDip => 2,
  Ids.squat => 1,
  _ => 0,
};

/// Famille d'un mouvement visé (le mouvement lesté et sa version au poids
/// du corps comptent ensemble pour la fréquence d'exposition), ou `null`.
String? coachLiftFamily(String id) => switch (id) {
  Ids.weightedPull || Ids.pull => 'pull',
  Ids.weightedDip || Ids.dip => 'dip',
  Ids.weightedMuscleUp || Ids.muscleUp => 'muscle_up',
  Ids.squat => 'squat',
  Ids.pushUp => 'push_up',
  _ => null,
};

/// Schéma chargé du mouvement [e] (récupération : CAHIER_KS.md § 3.4.3),
/// ou `null` (tronc, mobilité, cardio).
DayPattern? coachSchemaOf(CatalogExercise e) => switch (e.pattern) {
  MovementPattern.tirageVertical ||
  MovementPattern.tirageHorizontal ||
  MovementPattern.transitionMuscleUp ||
  MovementPattern.figureStatiqueTirage ||
  MovementPattern.figureDynamiqueTirage ||
  MovementPattern.isolationBiceps ||
  MovementPattern.isolationDos => DayPattern.pull,
  MovementPattern.pousseeHorizontale ||
  MovementPattern.pousseeInclinee ||
  MovementPattern.pousseeVerticaleBasse ||
  MovementPattern.pousseeVerticaleHaute ||
  MovementPattern.figureStatiquePoussee ||
  MovementPattern.figureDynamiquePoussee ||
  MovementPattern.equilibreMains ||
  MovementPattern.isolationTriceps ||
  MovementPattern.isolationPectoraux ||
  MovementPattern.isolationEpaules => DayPattern.push,
  MovementPattern.squat ||
  MovementPattern.fente ||
  MovementPattern.charniereHanche ||
  MovementPattern.extensionHanche ||
  MovementPattern.flexionGenou ||
  MovementPattern.extensionGenou ||
  MovementPattern.mollets ||
  MovementPattern.adducteursAbducteurs => DayPattern.legs,
  _ => null,
};

/// Méthodes dont le travail ne compte pas comme une séance dure du schéma :
/// préparation, prévention, mobilité, course facile, tenues faciles, et la
/// pratique technique dosée loin de l'échec (répétitions techniques du
/// muscle-up, travail dynamique d'une figure : 2 à 4 répétitions à 3 en
/// réserve ; R4-F1, R5-P27).
const Set<String> _softMethods = <String>{
  Method.warmupPrep,
  Method.accessoryPrehab,
  Method.mobility,
  Method.runEasy,
  Method.runLong,
  Method.beginnerHold,
  Method.skillEasyHold,
  Method.skillBalance,
  Method.skillDynamic,
  Method.repsTechnique,
};

/// Charge d'un emplacement sur son schéma, pour la récupération : 2 pour
/// un travail lourd, 1 pour un travail moyen, 0 pour un travail léger ou
/// d'appoint. Sans charge écrite, le rôle décide : principal 2,
/// secondaire et figure 1, assistance 0 (les compléments sont dosés loin
/// de l'échec).
int coachSlotLoad(SlotSpec s) {
  if (_softMethods.contains(s.method)) {
    return 0;
  }
  switch (s.stress) {
    case DayStress.heavy:
      return 2;
    case DayStress.medium:
      return 1;
    case DayStress.light:
      return 0;
    case null:
      break;
  }
  return switch (s.role) {
    SlotRole.main => 2,
    SlotRole.secondary || SlotRole.skill => 1,
    _ => 0,
  };
}

/// Récupération d'une semaine type [days] de l'athlète [a] (CAHIER_KS.md
/// § 3.4.3 : aucun schéma chargé lourd deux jours de suite, 48 h au moins
/// entre deux séances dures du même schéma, quelle que soit la qualité) :
/// un jour est dur sur un schéma quand sa charge sur ce schéma atteint 2
/// (un travail lourd, ou deux moyens) ; pour chaque paire de jours
/// consécutifs (le dimanche précède le lundi), le recouvrement est la plus
/// petite des deux charges d'un schéma dur les deux jours. Note : 1 moins
/// deux fois le recouvrement rapporté à la charge totale (même forme que la
/// composante de 0.1), bornée à [0, 1]. Rend aussi le nombre de paires en
/// défaut.
(double, int) coachRecoveryOf(Athlete a, List<DaySpec> days) {
  final loads = <Map<DayPattern, int>>[];
  var total = 0;
  for (final d in days) {
    final m = <DayPattern, int>{};
    for (final s in d.slots) {
      final e = a.catalog.find(s.exerciseId);
      final schema = e == null ? null : coachSchemaOf(e);
      final load = coachSlotLoad(s);
      if (schema == null || load == 0) {
        continue;
      }
      m[schema] = (m[schema] ?? 0) + load;
      total += load;
    }
    loads.add(m);
  }
  if (total == 0 || days.length < 2) {
    return (1.0, 0);
  }
  var overlap = 0;
  var pairs = 0;
  for (var i = 0; i < days.length; i++) {
    for (var j = i + 1; j < days.length; j++) {
      final x = a.days[days[i].dayIndex].weekday;
      final y = a.days[days[j].dayIndex].weekday;
      final gap = ((y - x) % 7 + 7) % 7;
      if (gap != 1 && gap != 6) {
        continue;
      }
      var bad = false;
      for (final schema in loads[i].keys) {
        final u = loads[i][schema]!;
        final v = loads[j][schema] ?? 0;
        if (u >= 2 && v >= 2) {
          overlap += u < v ? u : v;
          bad = true;
        }
      }
      if (bad) {
        pairs++;
      }
    }
  }
  final value = 1 - 2 * overlap / total;
  return (value < 0 ? 0.0 : value, pairs);
}

/// Type d'un jour déduit de ses emplacements (chemins d'avant 0.4.0) :
/// schémas du travail dur (corps entier quand deux des trois schémas
/// chargés y sont), qualité de la méthode qui domine, charge la plus haute.
DayType coachDerivedType(Athlete a, DaySpec day) {
  final weight = <DayPattern, int>{};
  final quality = <DayQuality, int>{};
  var skill = false;
  var run = false;
  DayStress? stress;
  int rank(DayStress? s) => switch (s) {
    DayStress.heavy => 3,
    DayStress.medium => 2,
    DayStress.light => 1,
    null => 0,
  };
  for (final s in day.slots) {
    final e = a.catalog.find(s.exerciseId);
    if (e == null) {
      continue;
    }
    if (s.method == Method.runEasy ||
        s.method == Method.runLong ||
        s.method == Method.runQuality) {
      if (s.note != 'run_extra') {
        run = true;
        quality[DayQuality.run] = (quality[DayQuality.run] ?? 0) + 2;
      }
      continue;
    }
    if (s.role == SlotRole.warmup ||
        s.role == SlotRole.mobility ||
        s.role == SlotRole.core) {
      continue;
    }
    if (s.role == SlotRole.skill &&
        (s.method == Method.skillHold ||
            s.method == Method.skillAttempt ||
            s.method == Method.skillBalance ||
            s.method == Method.skillEasyHold)) {
      skill = true;
    }
    final load = coachSlotLoad(s);
    final schema = coachSchemaOf(e);
    if (schema != null && (load > 0 || s.role != SlotRole.accessory)) {
      weight[schema] = (weight[schema] ?? 0) + (load > 0 ? load : 1);
    }
    final q = switch (s.method) {
      Method.liftHeavy ||
      Method.liftMaintain ||
      Method.repsStrength ||
      Method.liftLight => DayQuality.force,
      Method.liftVolume ||
      Method.liftVariant ||
      Method.liftFixed => DayQuality.volume,
      Method.repsTop ||
      Method.repsVolume ||
      Method.repsDensity ||
      Method.repsEvent => DayQuality.endurance,
      Method.skillHold ||
      Method.skillAttempt ||
      Method.skillDynamic ||
      Method.skillEasyHold ||
      Method.skillBalance ||
      Method.repsTechnique => DayQuality.skill,
      Method.wod => DayQuality.conditioning,
      Method.mobility => DayQuality.recovery,
      // (Musculation : le travail principal est dosé en volume.)
      Method.accessoryCompound ||
      Method.accessoryLegs ||
      Method.accessoryIsolation => DayQuality.volume,
      _ => null,
    };
    if (q != null && s.role != SlotRole.accessory) {
      quality[q] = (quality[q] ?? 0) + (load > 0 ? load : 1);
    }
    if (rank(s.stress) > rank(stress)) {
      stress = s.stress;
    }
  }
  final schemas = <DayPattern>[
    for (final p in const <DayPattern>[
      DayPattern.pull,
      DayPattern.push,
      DayPattern.legs,
    ])
      if ((weight[p] ?? 0) >= 2) p,
  ];
  if (schemas.isEmpty) {
    for (final p in const <DayPattern>[
      DayPattern.pull,
      DayPattern.push,
      DayPattern.legs,
    ]) {
      if ((weight[p] ?? 0) > 0) {
        schemas.add(p);
      }
    }
  }
  final patterns = <DayPattern>[
    if (schemas.length >= 2) DayPattern.full else ...schemas,
    if (skill) DayPattern.skill,
    if (run) DayPattern.run,
  ];
  var best = DayQuality.recovery;
  var most = 0;
  for (final q in DayQuality.values) {
    final v = quality[q] ?? 0;
    if (v > most) {
      most = v;
      best = q;
    }
  }
  return DayType(
    patterns: patterns.isEmpty
        ? const <DayPattern>[DayPattern.recovery]
        : patterns,
    quality: best,
    stress: stress,
  );
}

// --------------------------------------------------------- gabarits typés

/// Gabarit typé de la bibliothèque pour [nf] séances de force et [ne]
/// d'endurance (CAHIER_KS.md § 3.2, § 3.3) : le gabarit fixe la suite des
/// schémas, la répartition au plus fort reste fixe les qualités — les
/// [nf] premières positions de la suite (dans l'ordre d'exigence) sont de
/// force, les autres d'endurance. `pp_l5` : les jambes prennent la qualité
/// dominante. Rend `null` quand la bibliothèque n'a pas de gabarit typé
/// pour ce nombre de séances (le gabarit composite reste seul).
(String, List<_Kind>)? _typedTemplate(int nf, int ne) {
  final n = nf + ne;
  _Kind kindOf(String schema, bool force) => switch (schema) {
    'pull' => force ? _Kind.pullForce : _Kind.pullEndurance,
    'push' => force ? _Kind.pushForce : _Kind.pushEndurance,
    'legs' => force ? _Kind.legsForce : _Kind.legsEndurance,
    'upper' => force ? _Kind.upperForce : _Kind.upperEndurance,
    'lower' => force ? _Kind.lowerForce : _Kind.lowerEndurance,
    _ => force ? _Kind.fullForce : _Kind.fullEndurance,
  };
  List<_Kind> typed(List<String> schemas, int forceCount) {
    final kinds = <_Kind>[
      for (var i = 0; i < schemas.length; i++)
        kindOf(schemas[i], i < forceCount),
    ];
    // Force d'abord (ordre d'exigence), puis endurance, chaque groupe dans
    // l'ordre de la suite.
    return <_Kind>[
      ...kinds.where((k) => k.force),
      ...kinds.where((k) => !k.force),
    ];
  }

  if (nf < 1 || ne < 1) {
    return null;
  }
  if (n == 6) {
    return (
      SplitTemplates.pushPullLegs6,
      typed(const <String>['pull', 'push', 'legs', 'pull', 'push', 'legs'], nf),
    );
  }
  if (n == 5) {
    final legsForce = nf > ne;
    final upper = typed(const <String>[
      'pull',
      'push',
      'pull',
      'push',
    ], nf - (legsForce ? 1 : 0));
    final legs = legsForce ? _Kind.legsForce : _Kind.legsEndurance;
    return (
      SplitTemplates.pushPullLegs5,
      <_Kind>[
        ...upper.where((k) => k.force),
        if (legsForce) legs,
        ...upper.where((k) => !k.force),
        if (!legsForce) legs,
      ],
    );
  }
  if (n == 4) {
    return (
      SplitTemplates.upperLower4,
      typed(const <String>['upper', 'lower', 'upper', 'lower'], nf),
    );
  }
  if (n == 3) {
    return (
      SplitTemplates.fullBody3,
      <_Kind>[
        for (var i = 0; i < nf; i++) _Kind.fullForce,
        for (var i = 0; i < ne; i++) _Kind.fullEndurance,
      ],
    );
  }
  if (n == 2) {
    return (
      SplitTemplates.fullBody2,
      const <_Kind>[_Kind.fullForce, _Kind.fullEndurance],
    );
  }
  return null;
}

/// Écart circulaire, en jours, du jour [i] au jour [j] (1 à 7).
int _gapDays(Athlete a, int i, int j) {
  var g = a.days[j].weekday - a.days[i].weekday;
  if (g <= 0) {
    g += 7;
  }
  return g;
}

/// Placement des types [kinds] (le premier est le plus exigeant) sur les
/// jours [days] (CAHIER_KS.md § 3.5) : recherche exhaustive des ordres
/// (720 au plus), clés comparées dans l'ordre — paires de jours
/// consécutifs qui chargent le même schéma ; le jour le plus exigeant
/// ouvre la rotation, après le plus long repos ; paires force et endurance
/// du même schéma à moins de 72 h ; les types longs sur les jours longs ;
/// à égalité, le premier ordre trouvé (le plus proche de l'ordre du
/// gabarit). Rend le type de chaque jour, dans l'ordre de [days].
List<_Kind> _place(Athlete a, List<int> days, List<_Kind> kinds) {
  final n = days.length;
  // Jour qui ouvre la rotation : celui qui suit le plus long repos.
  var opener = 0;
  var longest = -1;
  for (var i = 0; i < n; i++) {
    final before = _gapDays(a, days[(i - 1 + n) % n], days[i]);
    final gap = n == 1 ? 7 : before;
    if (gap > longest) {
      longest = gap;
      opener = i;
    }
  }
  List<int>? best;
  List<int>? bestKey;
  final perm = <int>[];
  final used = List<bool>.filled(n, false);

  List<int> keyOf(List<int> p) {
    var adjacent = 0;
    var close = 0;
    var fit = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final g1 = _gapDays(a, days[i], days[j]);
        final g = g1 < 7 - g1 ? g1 : 7 - g1;
        final ki = kinds[p[i]];
        final kj = kinds[p[j]];
        final shared = ki.schemas.intersection(kj.schemas).isNotEmpty;
        if (shared && g <= 1) {
          adjacent++;
        }
        if (shared && ki.force != kj.force && g < 3) {
          close++;
        }
      }
      fit += a.days[days[i]].minutes * kinds[p[i]].length;
    }
    return <int>[adjacent, p[opener] == 0 ? 0 : 1, close, -fit];
  }

  bool less(List<int> x, List<int> y) {
    for (var k = 0; k < x.length; k++) {
      if (x[k] != y[k]) {
        return x[k] < y[k];
      }
    }
    return false;
  }

  void search() {
    if (perm.length == n) {
      final key = keyOf(perm);
      if (bestKey == null || less(key, bestKey!)) {
        bestKey = key;
        best = List<int>.of(perm);
      }
      return;
    }
    for (var k = 0; k < n; k++) {
      if (used[k]) {
        continue;
      }
      used[k] = true;
      perm.add(k);
      search();
      perm.removeLast();
      used[k] = false;
    }
  }

  search();
  return <_Kind>[for (final k in best!) kinds[k]];
}

/// Construit les jours typés : chaque type appelle le travail de sa qualité
/// sur ses schémas (CAHIER_KS.md § 3.6), le mouvement le plus exigeant en
/// tête de séance (§ 11.2).
void _buildTyped(_Builder b, List<int> days, List<_Kind> kinds) {
  final a = b.a;
  bool liftable(String id) => days.any((d) => a.can(id, d));
  final elbow = a.limitOn(Joint.elbow);
  final spareElbow = elbow != null && elbow.discomfort >= 2 && elbow.recent;
  final pull = liftable(Ids.weightedPull) && !spareElbow;
  final dip = liftable(Ids.weightedDip);
  final squat = liftable(Ids.squat);
  final mu =
      liftable(Ids.weightedMuscleUp) &&
      !spareElbow &&
      (a.oneRm[Ids.weightedMuscleUp] != null ||
          (a.reps[Ids.muscleUp] ?? 0) >= 5) &&
      a.level >= 2;
  final pullMax = a.reps[Ids.pull] ?? 0;
  final dipMax = a.reps[Ids.dip] ?? 0;
  final pushMax = a.reps[Ids.pushUp] ?? 0;
  final muMax = a.reps[Ids.muscleUp] ?? 0;
  final rowPick = spareElbow
      ? const <String>['mu-rowing-haltere-unilateral-banc', ...Picks.row]
      : Picks.row;
  WeakPointKind? weakOn(String id) {
    for (final w in a.profile.weakPoints ?? const <WeakPoint>[]) {
      if (w.exerciseId == id) {
        return w.kind;
      }
    }
    return null;
  }

  bool weakGrip() =>
      weakOn(Ids.pull) == WeakPointKind.grip ||
      weakOn(Ids.weightedPull) == WeakPointKind.grip;

  // Objectif de répétitions à charge donnée (squat 35 × 70 kg) : ligne à
  // charge fixe (CAHIER_KS.md § 4 ; règle C15.2 de l'application).
  Goal? fixedGoal(String id) {
    for (final g in a.profile.goals) {
      if (g.exerciseId == id &&
          g.metric == GoalMetric.maxReps &&
          g.loadKg != null &&
          g.targetValue != null) {
        return g;
      }
    }
    return null;
  }

  void lift(int d, String id, String method, DayStress stress, {int sets = 4}) {
    b.add(
      d,
      <String>[id],
      method == Method.liftHeavy ? SlotRole.main : SlotRole.secondary,
      method,
      sets: sets == 4 && a.level >= 3 ? 5 : sets,
      stress: stress,
    );
  }

  void variant(int d, String id) {
    final v = _weakVariant(a, id);
    if (v == null) {
      return;
    }
    // (Prise : la suspension se travaille le jour tirage endurance.)
    if (v.$2 == WeakPointKind.grip) {
      return;
    }
    b.add(
      d,
      v.$1,
      SlotRole.secondary,
      Method.liftVariant,
      sets: 3,
      referenceId: id,
      weak: v.$2,
      stress: DayStress.medium,
    );
  }

  void pullForce(int d, {bool lead = true}) {
    if (mu) {
      lift(d, Ids.weightedMuscleUp, Method.liftHeavy, DayStress.heavy, sets: 5);
    }
    if (pull) {
      lift(d, Ids.weightedPull, Method.liftHeavy, DayStress.heavy);
      if (lead) {
        variant(d, Ids.weightedPull);
      }
    } else if (a.can(Ids.pull, d) && pullMax >= 1) {
      // Coude à ménager : tirage au poids du corps en prise neutre, charge
      // graduée (R5-P20, R5-P24).
      b.add(
        d,
        <String>['sw-traction-neutre', 'sw-traction-anneaux', Ids.pull],
        SlotRole.main,
        Method.repsVolume,
        sets: 3,
        stress: DayStress.medium,
        referenceId: Ids.pull,
        note: 'pull_return',
      );
    }
    if (mu && lead) {
      variant(d, Ids.weightedMuscleUp);
    }
  }

  void pushForce(int d, {bool lead = true}) {
    if (dip) {
      lift(d, Ids.weightedDip, Method.liftHeavy, DayStress.heavy);
      if (lead) {
        variant(d, Ids.weightedDip);
      }
    } else if (a.can(Ids.dip, d) && dipMax >= 1) {
      _addRepsPillar(b, d, Ids.dip, Method.repsStrength, max: dipMax);
    }
  }

  void legsForce(int d, {bool lead = true}) {
    if (squat) {
      lift(d, Ids.squat, Method.liftHeavy, DayStress.heavy);
      if (lead) {
        variant(d, Ids.squat);
      }
    } else {
      _addLegs(b, d, main: true);
    }
  }

  void pullEndurance(int d) {
    if (a.can(Ids.pull, d) && pullMax >= 1) {
      // Série de référence (série longue, puis séries allégées) : le
      // mouvement le plus exigeant du jour (R4-G1, R4-G2).
      _addRepsPillar(b, d, Ids.pull, Method.repsTop, max: pullMax);
    }
    if (muMax >= 6 && a.can(Ids.muscleUp, d) && !spareElbow) {
      b.add(
        d,
        <String>[Ids.muscleUp],
        SlotRole.skill,
        Method.repsDensity,
        sets: 6,
        stress: DayStress.light,
      );
    } else if (muMax >= 1 && !spareElbow) {
      _addMuscleUpPractice(b, d, muMax);
    }
    if (weakGrip()) {
      // Point faible « prise » : suspension longue (CAHIER_KS.md § 4).
      b.add(
        d,
        const <String>['sw-dead-hang', 'sl-dead-hang-leste'],
        SlotRole.secondary,
        Method.skillEasyHold,
        sets: 3,
        referenceId: Ids.pull,
        weak: WeakPointKind.grip,
      );
    }
  }

  void pushEndurance(int d) {
    if (a.can(Ids.dip, d) && dipMax >= 1) {
      _addRepsPillar(b, d, Ids.dip, Method.repsTop, max: dipMax);
    }
    if (a.can(Ids.pushUp, d) && pushMax >= 1) {
      final dense = pushMax >= 10;
      b.add(
        d,
        <String>[Ids.pushUp],
        SlotRole.secondary,
        dense ? Method.repsDensity : Method.repsVolume,
        sets: dense ? 6 : 4,
        stress: DayStress.medium,
      );
    }
  }

  void legsEndurance(int d) {
    final goal = fixedGoal(Ids.squat);
    if (squat && goal != null) {
      b.add(
        d,
        <String>[Ids.squat],
        SlotRole.main,
        Method.liftFixed,
        sets: 3,
        stress: DayStress.medium,
      );
    } else if (squat) {
      // (Le squat de volume est le travail principal du jour.)
      b.add(
        d,
        <String>[Ids.squat],
        SlotRole.main,
        Method.liftVolume,
        sets: a.level >= 3 ? 5 : 4,
        stress: DayStress.medium,
      );
    } else {
      _addLegs(b, d, main: true);
    }
    // Puissance quand le muscle-up est visé : tirage explosif léger, loin
    // de l'échec (CAHIER_KS.md § 3.2, `ppl6_q`).
    if (!spareElbow &&
        muMax >= 1 &&
        (a.aimsAt(Ids.muscleUp) || a.aimsAt(Ids.weightedMuscleUp))) {
      b.add(
        d,
        const <String>[
          'cd-traction-explosive-poitrine-barre',
          'sw-traction-chest-to-bar',
        ],
        SlotRole.skill,
        Method.skillDynamic,
        sets: 3,
        referenceId: Ids.pull,
        support: true,
      );
    }
  }

  void rows(int d, {int sets = 3, bool keep = false}) {
    b.add(
      d,
      a.can(Ids.weightedPull, d) ? rowPick : Picks.bodyweightRow,
      SlotRole.accessory,
      Method.accessoryCompound,
      sets: sets,
      keep: keep,
    );
  }

  void prehab(int d) {
    b.add(
      d,
      Picks.rearDelt,
      SlotRole.accessory,
      Method.accessoryPrehab,
      sets: 2,
    );
    b.add(d, Picks.cuff, SlotRole.accessory, Method.accessoryPrehab, sets: 2);
  }

  for (var i = 0; i < days.length; i++) {
    final d = days[i];
    final kind = kinds[i];
    b.days[d].focus = kind.focus;
    final legs = kind.schemas.contains(DayPattern.legs);
    final upper =
        kind.schemas.contains(DayPattern.pull) ||
        kind.schemas.contains(DayPattern.push);
    if (upper) {
      b.add(d, Picks.hangPrep, SlotRole.warmup, Method.warmupPrep, sets: 2);
    }
    switch (kind) {
      case _Kind.pullForce:
        pullForce(d);
        rows(d);
        if (!spareElbow && a.level >= 2) {
          b.add(
            d,
            Picks.curl,
            SlotRole.accessory,
            Method.accessoryIsolation,
            sets: 2,
          );
        }
      case _Kind.pushForce:
        pushForce(d);
        b.add(
          d,
          const <String>[
            'sl-pompe-lestee-gilet',
            'sl-pompe-lestee-disque-dos',
            'sw-pompe-declinee',
          ],
          SlotRole.secondary,
          Method.accessoryCompound,
          sets: 3,
          stress: DayStress.medium,
        );
        prehab(d);
      case _Kind.legsForce:
        legsForce(d);
        b.add(
          d,
          Picks.hinge,
          SlotRole.accessory,
          Method.accessoryCompound,
          sets: 3,
        );
        _addCore(b, d, sets: 3);
      case _Kind.pullEndurance:
        pullEndurance(d);
        rows(d, keep: true);
      case _Kind.pushEndurance:
        pushEndurance(d);
        b.add(
          d,
          const <String>[
            'mu-pushdown-corde',
            'mu-extension-nuque-haltere-unilaterale',
            'mu-pushdown-elastique',
          ],
          SlotRole.accessory,
          Method.accessoryIsolation,
          sets: 2,
        );
        b.add(
          d,
          Picks.cuff,
          SlotRole.accessory,
          Method.accessoryPrehab,
          sets: 2,
        );
      case _Kind.legsEndurance:
        legsEndurance(d);
        b.add(
          d,
          Picks.gymSingleLeg,
          SlotRole.accessory,
          Method.accessoryLegs,
          sets: 2,
        );
        _addCore(b, d);
      case _Kind.upperForce:
        pullForce(d);
        pushForce(d);
        rows(d);
      case _Kind.lowerForce:
        legsForce(d);
        b.add(
          d,
          Picks.hinge,
          SlotRole.accessory,
          Method.accessoryCompound,
          sets: 3,
        );
        _addCore(b, d, sets: 3);
      case _Kind.upperEndurance:
        pullEndurance(d);
        pushEndurance(d);
        rows(d, keep: true);
      case _Kind.lowerEndurance:
        legsEndurance(d);
        b.add(
          d,
          Picks.gymSingleLeg,
          SlotRole.accessory,
          Method.accessoryLegs,
          sets: 2,
        );
        _addCore(b, d);
      case _Kind.fullForce:
        // Deux jours de force : le second passe en volume sur le tirage et
        // le squat (séance lourde et séance de volume séparées, R2-P7,
        // R3-P3).
        final second = kinds.sublist(0, i).contains(_Kind.fullForce);
        if (second) {
          if (mu) {
            lift(d, Ids.weightedMuscleUp, Method.liftLight, DayStress.light);
          }
          if (pull) {
            lift(d, Ids.weightedPull, Method.liftVolume, DayStress.medium);
          }
          if (dip) {
            lift(d, Ids.weightedDip, Method.liftHeavy, DayStress.heavy);
          }
          if (squat) {
            lift(d, Ids.squat, Method.liftVolume, DayStress.medium);
          }
        } else {
          pullForce(d, lead: false);
          if (dip) {
            lift(d, Ids.weightedDip, Method.liftVolume, DayStress.medium);
          }
          legsForce(d, lead: false);
        }
        rows(d);
      case _Kind.fullEndurance:
        pullEndurance(d);
        pushEndurance(d);
        if (legs) {
          _addLegs(b, d, main: false);
        }
        rows(d, keep: true);
    }
    // KS1c2 : aucun jour typé sans son principal, sur tous les états du
    // profil (repères absents, questionnaire non rempli, prudent).
    final served = _ensurePrincipal(b, d, kind, spareElbow: spareElbow);
    if (upper && !legs) {
      _addCore(b, d);
    }
    // (Mobilité en fin de séance, le jour jambes de l'endurance.)
    if (kind == _Kind.legsEndurance || kind == _Kind.lowerEndurance) {
      b.add(
        d,
        Picks.mobility,
        SlotRole.mobility,
        Method.mobility,
        sets: 1,
        rotate: true,
      );
    }
    if (served) {
      b.days[d].type = DayType(
        patterns: kind.patterns,
        quality: kind.force ? DayQuality.force : DayQuality.endurance,
        stress: kind.force ? DayStress.heavy : DayStress.medium,
      );
    } else {
      // Aucun exercice du schéma possible (douleur, matériel) : le jour
      // prend le type de ce qu'il porte, et la raison est dite.
      b.days[d].type = coachDerivedType(a, b.days[d]);
      b.dayReasons[d] = _unservedReasons(a, kind);
    }
  }
}

/// Méthodes d'un travail porteur qu'un emplacement secondaire peut garder en
/// devenant le principal du jour (KS1c2) : séries de répétitions, séries
/// chargées, polyarticulaire d'assistance (pompe lestée d'un jour de
/// poussée sans dips, jambes d'un jour sans squat) ; jamais une isolation,
/// une préparation, une prévention ou une figure.
const Set<String> _promotableMethods = <String>{
  Method.repsTop,
  Method.repsStrength,
  Method.repsVolume,
  Method.repsDensity,
  Method.liftHeavy,
  Method.liftVolume,
  Method.liftLight,
  Method.liftFixed,
  Method.accessoryLegs,
  Method.accessoryCompound,
  Method.beginnerMain,
};

/// Schéma chargé de l'emplacement [s], ou `null`.
DayPattern? _schemaOfSlot(Athlete a, SlotSpec s) {
  final e = a.catalog.find(s.exerciseId);
  return e == null ? null : coachSchemaOf(e);
}

/// Schémas qu'un jour de nature [kind] doit porter (CAHIER_KS.md § 3.1) :
/// le sien ; tirage et poussée pour un jour du haut ; les trois pour un
/// corps entier (dont deux au moins portés).
List<DayPattern> _requiredSchemas(_Kind kind) => switch (kind) {
  _Kind.upperForce || _Kind.upperEndurance => const <DayPattern>[
    DayPattern.pull,
    DayPattern.push,
  ],
  _Kind.fullForce || _Kind.fullEndurance => const <DayPattern>[
    DayPattern.pull,
    DayPattern.push,
    DayPattern.legs,
  ],
  _ => kind.schemas.toList(),
};

/// Vrai si le jour [d] a un travail porteur (principal ou secondaire) du
/// schéma [p].
bool _carries(_Builder b, int d, DayPattern p) => b.days[d].slots.any(
  (s) =>
      (s.role == SlotRole.main || s.role == SlotRole.secondary) &&
      _schemaOfSlot(b.a, s) == p,
);

/// Vrai si le jour [d] a un emplacement principal d'un des schémas [ps].
bool _hasMain(_Builder b, int d, List<DayPattern> ps) => b.days[d].slots.any(
  (s) => s.role == SlotRole.main && ps.contains(_schemaOfSlot(b.a, s)),
);

/// Vrai si le jour [d] tient la règle « aucun jour sans son principal »
/// pour la nature [kind] (même règle que le critère du banc, `kalis_bench`
/// `principalGapsOfDay`) : un principal d'un de ses schémas, chacun de ses
/// schémas porté (deux des trois pour un corps entier).
bool _principalHeld(_Builder b, int d, _Kind kind) {
  final required = _requiredSchemas(kind);
  if (!_hasMain(b, d, required)) {
    return false;
  }
  final carried = required.where((p) => _carries(b, d, p)).length;
  final full = kind == _Kind.fullForce || kind == _Kind.fullEndurance;
  return full ? carried >= 2 : carried == required.length;
}

/// Place l'emplacement [slot] (le dernier du jour [d]) après la
/// préparation et les principaux déjà écrits : le principal ouvre la
/// séance (CAHIER_KS.md § 11.2).
void _moveToHead(_Builder b, int d, SlotSpec slot) {
  final slots = b.days[d].slots;
  slots.remove(slot);
  var at = 0;
  for (var i = 0; i < slots.length; i++) {
    if (slots[i].role == SlotRole.warmup || slots[i].role == SlotRole.main) {
      at = i + 1;
    }
  }
  slots.insert(at, slot);
}

/// Principal de repli du schéma [p] au jour [d] d'une qualité de force
/// ([force]) ou d'endurance de force (KS1c2) — le travail que le jour aurait
/// reçu avec un repère, dosé sans repère par les règles existantes de la
/// passe 2 : au poids du corps, plage de répétitions à réserve visée (force :
/// 4 à 6 répétitions à 2 en réserve ; endurance : 5 à 8 à 3 en réserve,
/// double progression ; `_repsStrength`, `_repsVolume`), et une première
/// série de mesure proposée en semaine 1 (note `reps_calibrate`). Trois
/// séries en mode prudent et chez le débutant, quatre sinon (ACSM 2009 :
/// une à trois séries au début, plusieurs ensuite). Rend l'emplacement, ou
/// `null` si aucun exercice du schéma n'est possible ce jour.
SlotSpec? _principalFallback(
  _Builder b,
  int d,
  DayPattern p,
  bool force, {
  required bool spareElbow,
}) {
  final a = b.a;
  final sets = a.cautious || a.level == 0 ? 3 : 4;
  final method = force ? Method.repsStrength : Method.repsVolume;
  final stress = force ? DayStress.heavy : DayStress.medium;
  switch (p) {
    case DayPattern.pull:
      if (spareElbow) {
        // Coude à ménager : prise neutre, dosage du retour (R5-P20, R5-P24).
        return b.add(
          d,
          const <String>[
            'sw-traction-neutre',
            'sw-traction-anneaux',
            Ids.pull,
          ],
          SlotRole.main,
          Method.repsVolume,
          sets: 3,
          stress: DayStress.medium,
          referenceId: Ids.pull,
          note: 'pull_return',
        );
      }
      return b.add(
            d,
            const <String>[Ids.pull, 'sw-traction-neutre', 'sw-traction-anneaux'],
            SlotRole.main,
            method,
            sets: sets,
            stress: stress,
            note: 'reps_calibrate',
          ) ??
          b.add(
            d,
            <String>[...Picks.assistedPull, ...Picks.bodyweightRow],
            SlotRole.main,
            Method.repsVolume,
            sets: sets,
            stress: DayStress.medium,
            note: 'reps_calibrate',
          );
    case DayPattern.push:
      return b.add(
        d,
        force
            ? <String>[
                Ids.dip,
                ...Picks.hardPushUp,
                Ids.pushUp,
                ...Picks.easyPushUp,
              ]
            : <String>[Ids.dip, Ids.pushUp, ...Picks.easyPushUp],
        SlotRole.main,
        method,
        sets: sets,
        stress: stress,
        note: 'reps_calibrate',
      );
    case DayPattern.legs:
      return b.add(
        d,
        <String>[
          ...Picks.gymSingleLeg.take(2),
          ..._bodyweightLegsFor(a),
          ...Picks.bodyweightLegsSecond,
          ...Picks.beginnerSquat,
        ],
        SlotRole.main,
        Method.accessoryLegs,
        sets: sets,
      );
    default:
      return null;
  }
}

/// Garantit au jour typé [d] de nature [kind] son principal (KS1c2 ;
/// CAHIER_KS.md § 3.6 : « un jour sans principal est une erreur d'audit,
/// pas un jour à remplir »). N'agit que si le jour ne tient pas la règle :
/// un jour qui la tient reste identique à 0.4.1. Dans l'ordre : chaque
/// schéma non porté reçoit son principal de repli ; sans principal, le
/// premier travail porteur secondaire d'un de ses schémas devient le
/// principal ; sinon un principal de repli s'ajoute. Rend `false` si aucun
/// exercice du schéma n'est possible (le jour change alors de type).
bool _ensurePrincipal(
  _Builder b,
  int d,
  _Kind kind, {
  required bool spareElbow,
}) {
  if (_principalHeld(b, d, kind)) {
    return true;
  }
  final required = _requiredSchemas(kind);
  final full = kind == _Kind.fullForce || kind == _Kind.fullEndurance;
  final missing = <DayPattern>[
    for (final p in required)
      if (!_carries(b, d, p)) p,
  ];
  final carried = required.length - missing.length;
  if (!full || carried < 2) {
    for (final p in missing) {
      final slot = _principalFallback(
        b,
        d,
        p,
        kind.force,
        spareElbow: spareElbow,
      );
      if (slot != null) {
        _moveToHead(b, d, slot);
      }
    }
  }
  if (!_hasMain(b, d, required)) {
    final slots = b.days[d].slots;
    final at = slots.indexWhere(
      (s) =>
          s.role == SlotRole.secondary &&
          _promotableMethods.contains(s.method) &&
          required.contains(_schemaOfSlot(b.a, s)),
    );
    if (at >= 0) {
      final s = slots[at];
      final promoted = SlotSpec(
        exerciseId: s.exerciseId,
        role: SlotRole.main,
        method: s.method,
        sets: s.sets,
        stress: s.stress,
        referenceId: s.referenceId,
        skillTargetId: s.skillTargetId,
        group: s.group,
        weak: s.weak,
        fromWeek: s.fromWeek,
        untilWeek: s.untilWeek,
        note: s.note,
        support: s.support,
        keep: s.keep,
      );
      slots[at] = promoted;
      _moveToHead(b, d, promoted);
    } else {
      for (final p in required) {
        final slot = _principalFallback(
          b,
          d,
          p,
          kind.force,
          spareElbow: spareElbow,
        );
        if (slot != null) {
          _moveToHead(b, d, slot);
          break;
        }
      }
    }
  }
  return _principalHeld(b, d, kind);
}

/// Raisons d'un jour qui change de type faute d'exercice possible de son
/// schéma (KS1c2) : la zone à ménager la plus gênante quand le profil en
/// déclare, sinon le matériel qui manque au mouvement de base du schéma.
List<Reason> _unservedReasons(Athlete a, _Kind kind) {
  CoachLimit? worst;
  for (final l in a.limits) {
    if (worst == null || l.discomfort > worst.discomfort) {
      worst = l;
    }
  }
  if (worst != null) {
    return <Reason>[
      reason(ReasonCodes.planJointLimitation, <String, Object?>{
        'joint': worst.joint?.code ?? worst.zone.code,
        'discomfort': worst.discomfort,
      }),
    ];
  }
  final base = switch (_requiredSchemas(kind).first) {
    DayPattern.pull => Ids.pull,
    DayPattern.push => Ids.dip,
    _ => Ids.squat,
  };
  final e = a.catalog.find(base);
  var missing = _requiredSchemas(kind).first.code;
  for (final item in e?.equipment ?? const <String>[]) {
    if (!a.profile.equipment.contains(item)) {
      missing = item;
      break;
    }
  }
  return <Reason>[
    reason(ReasonCodes.planEquipmentMissing, <String, Object?>{
      'equipment': missing,
    }),
  ];
}

/// Gabarit composite : les jours de force reçoivent le chemin streetlifting,
/// les autres le chemin sets & reps. Les jours de force sont les plus
/// espacés de la semaine (choix raisonné : 48 h entre deux séances lourdes,
/// R4-F10, R5-P22).
void _buildMixed(_Builder b, Set<int> runDays, int nf) {
  final a = b.a;
  final free = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  final forceDays = spreadDays(a, free, nf).toSet();
  final enduranceDays = <int>{
    for (final d in free)
      if (!forceDays.contains(d)) d,
  };
  _buildLifting(b, runDays, skip: enduranceDays);
  _buildReps(b, runDays, skip: forceDays);
  for (final d in free) {
    final derived = coachDerivedType(a, b.days[d]);
    b.days[d].type = DayType(
      patterns: derived.patterns,
      quality: forceDays.contains(d) ? DayQuality.force : DayQuality.endurance,
      stress: derived.stress,
    );
  }
}

// ------------------------------------------------------- choix du gabarit

/// Mesures d'un gabarit candidat, comparées dans l'ordre lexicographique
/// du § 3.4 (sans compensation) : sécurité, couverture, récupération,
/// spécificité, temps, préférences.
final class SplitMeasure {
  /// Mesures.
  const SplitMeasure({
    required this.uncovered,
    required this.recovery,
    required this.recoveryPairs,
    required this.specific,
    required this.timeOff,
    required this.noMain,
    required this.liked,
  });

  /// Objectifs sans emplacement porteur.
  final int uncovered;

  /// Récupération ([coachRecoveryOf]).
  final double recovery;

  /// Paires de jours consécutifs qui chargent le même schéma.
  final int recoveryPairs;

  /// Mouvements visés exposés deux jours par semaine au moins.
  final int specific;

  /// Séances hors de ± 15 % du temps disponible.
  final int timeOff;

  /// Séances sans emplacement principal.
  final int noMain;

  /// Exercices aimés présents.
  final int liked;

  /// Vrai si ce candidat passe avant [other].
  bool before(SplitMeasure other) {
    if (uncovered != other.uncovered) {
      return uncovered < other.uncovered;
    }
    final pass = recovery >= coachRecoveryFloor - 1e-9;
    final otherPass = other.recovery >= coachRecoveryFloor - 1e-9;
    if (pass != otherPass) {
      return pass;
    }
    if (recoveryPairs != other.recoveryPairs) {
      return recoveryPairs < other.recoveryPairs;
    }
    if (specific != other.specific) {
      return specific > other.specific;
    }
    final time = timeOff + noMain;
    final otherTime = other.timeOff + other.noMain;
    if (time != otherTime) {
      return time < otherTime;
    }
    return liked > other.liked;
  }
}

/// Seuil de la récupération d'une semaine (CAHIER_KS.md § 3.4.3 et § 9).
const double coachRecoveryFloor = 0.9;

/// Objectifs de performance de [a] sans emplacement porteur dans [days]
/// (même lien que la raison `plan.goal_support` : exercice, figure visée ou
/// mouvement de référence) ; un emplacement réservé à quelques semaines
/// compte (le contrôle par semaine est celui du banc).
List<Goal> coachUncoveredGoals(Athlete a, List<DaySpec> days) {
  final out = <Goal>[];
  for (final g in a.profile.goals) {
    final id = g.exerciseId;
    if (g.kind != GoalKind.performance || id == null) {
      continue;
    }
    var ok = false;
    for (final d in days) {
      for (final s in d.slots) {
        if (s.exerciseId == id ||
            s.skillTargetId == id ||
            s.referenceId == id) {
          ok = true;
        }
      }
    }
    if (!ok) {
      out.add(g);
    }
  }
  return out;
}

/// Durée estimée de la séance [d] du squelette, en secondes (même compte que
/// le complément de fin de séance).
double _skeletonSeconds(_Builder b, int d) {
  final minutes = b.a.days[d].minutes;
  var t = minutes * 9.0 > 480 ? 480.0 : minutes * 9.0;
  for (final s in b.days[d].slots) {
    t += _slotSeconds(b.a, s);
  }
  return t;
}

SplitMeasure _measure(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <DaySpec>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) b.days[d],
  ];
  final (recovery, pairs) = coachRecoveryOf(a, days);
  final families = <String>{
    for (final g in a.profile.goals)
      if (g.exerciseId != null && coachLiftFamily(g.exerciseId!) != null)
        coachLiftFamily(g.exerciseId!)!,
    for (final e in a.profile.events ?? const <SeasonEvent>[])
      for (final l in e.lifts ?? const <CompetitionLift>[])
        if (coachLiftFamily(l.exerciseId) != null)
          coachLiftFamily(l.exerciseId)!,
  };
  var specific = 0;
  for (final f in families) {
    var n = 0;
    for (final d in days) {
      if (d.slots.any(
        (s) =>
            coachLiftFamily(s.exerciseId) == f &&
            (s.role == SlotRole.main ||
                s.role == SlotRole.secondary ||
                s.role == SlotRole.skill),
      )) {
        n++;
      }
    }
    if (n >= 2) {
      specific++;
    }
  }
  var timeOff = 0;
  var noMain = 0;
  for (final d in days) {
    final ratio =
        _skeletonSeconds(b, d.dayIndex) / (a.days[d.dayIndex].minutes * 60);
    if (ratio < 0.85 || ratio > 1.15) {
      timeOff++;
    }
    if (!d.slots.any((s) => s.role == SlotRole.main)) {
      noMain++;
    }
  }
  final liked = <String>{
    for (final d in days)
      for (final s in d.slots)
        if (a.profile.likedExerciseIds.contains(s.exerciseId)) s.exerciseId,
  };
  return SplitMeasure(
    uncovered: coachUncoveredGoals(a, days).length,
    recovery: recovery,
    recoveryPairs: pairs,
    specific: specific,
    timeOff: timeOff,
    noMain: noMain,
    liked: liked.length,
  );
}

// ------------------------------------------- composantes recalées du score

/// Séances lourdes par schéma et par semaine (R4-F10 : débutant 2,
/// intermédiaire 2 à 3, avancé 3, élite 3 à 4 ; la borne haute).
const List<int> coachHardSessionsPerSchema = <int>[2, 3, 3, 4];

/// Charge des schémas du chemin street (lot KS1, CAHIER_KS.md § 3.4 : la
/// composante de 0.1 reste à 1 pour un athlète sans gêne, même à 23 séries
/// de tirage vertical par semaine) : part des séances dures d'un schéma
/// au-delà de [coachHardSessionsPerSchema] (R4-F10) ; 1 quand chaque schéma
/// tient dans sa borne.
double coachSchemaLoadOf(Athlete a, List<DaySpec> days) {
  final limit = coachHardSessionsPerSchema[a.level.clamp(0, 3)];
  var hard = 0;
  var excess = 0;
  for (final schema in const <DayPattern>[
    DayPattern.pull,
    DayPattern.push,
    DayPattern.legs,
  ]) {
    var n = 0;
    for (final d in days) {
      var load = 0;
      for (final s in d.slots) {
        final e = a.catalog.find(s.exerciseId);
        if (e != null && coachSchemaOf(e) == schema) {
          load += coachSlotLoad(s);
        }
      }
      if (load >= 2) {
        n++;
      }
    }
    hard += n;
    if (n > limit) {
      excess += n - limit;
    }
  }
  return hard == 0 ? 1.0 : 1 - excess / hard;
}

/// Répartition de la charge dure dans la semaine (lot KS1) : séries dures
/// par séance (méthodes qui comptent pour la récupération) ; une séance
/// légère à la moitié de la plus lourde est une ondulation voulue (R2-P7,
/// R3-P3), en dessous la note baisse jusqu'à 0 pour une séance sans
/// travail dur (constat K3 : un jour sans principal). Choix raisonné.
double coachHardBalanceOf(List<DaySpec> days) {
  final work = <int>[];
  for (final d in days) {
    if (d.slots.every(
      (s) =>
          s.method == Method.runEasy ||
          s.method == Method.runLong ||
          s.method == Method.runQuality ||
          s.method == Method.mobility ||
          s.method == Method.warmupPrep,
    )) {
      continue;
    }
    var n = 0;
    for (final s in d.slots) {
      if (coachSlotLoad(s) > 0) {
        n += s.sets;
      }
    }
    // (Un jour sans travail dur — récupération, technique, prévention — ne
    // fait pas partie de la répartition de la charge dure.)
    if (n > 0) {
      work.add(n);
    }
  }
  if (work.length < 2) {
    return 1;
  }
  var most = 0;
  var least = 1 << 30;
  for (final n in work) {
    if (n > most) {
      most = n;
    }
    if (n < least) {
      least = n;
    }
  }
  if (most == 0) {
    return 1;
  }
  final ratio = least / most;
  return ratio >= 0.5 ? 1.0 : ratio / 0.5;
}

/// Préférences (lot KS1) : part des exercices aimés admissibles que le
/// programme place (quatre au plus attendus), et part des exercices sus
/// (six au plus) — la composante de 0.1 comptait les exercices aimés du
/// vivier de recherche, pas ceux du programme du chemin street.
double coachPreferencesOf(Athlete a, List<DaySpec> days) {
  final present = <String>{
    for (final d in days)
      for (final s in d.slots) s.exerciseId,
  };
  bool admissible(String id) {
    for (var d = 0; d < a.dayCount; d++) {
      if (a.can(id, d)) {
        return true;
      }
    }
    return false;
  }

  double share(Iterable<String> ids, int most) {
    final wanted = <String>[
      for (final id in ids)
        if (a.catalog.contains(id) && admissible(id)) id,
    ];
    if (wanted.isEmpty) {
      return 1;
    }
    final seen = wanted.where(present.contains).length;
    final need = wanted.length < most ? wanted.length : most;
    return seen >= need ? 1.0 : seen / need;
  }

  return 0.5 * share(a.profile.likedExerciseIds, 4) +
      0.5 * share(a.profile.knownExerciseIds ?? const <String>[], 6);
}
