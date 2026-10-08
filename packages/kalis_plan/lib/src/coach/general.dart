part of 'skeleton.dart';

// ---------------------------------------------------------------------------
// Chemin des autres disciplines (CP2, partie 1) : musculation (hypertrophie),
// force (powerlifting et force générale), course, santé et mobilité,
// conditionnement (CrossFit). Chaque règle cite le principe du référentiel de
// `kalis_bench` (R1 à R6) qui la fonde ; ce qui n'est qu'un choix raisonné est
// dit comme tel (CONTRAT.md, § 13).
// ---------------------------------------------------------------------------

/// Mouvements de compétition de la force athlétique.
abstract final class PowerIds {
  /// Squat barre basse.
  static const String squatLow = 'mu-back-squat-barre-basse';

  /// Squat barre haute.
  static const String squatHigh = 'mu-back-squat-barre-haute';

  /// Développé couché.
  static const String bench = 'mu-developpe-couche-barre';

  /// Soulevé de terre conventionnel.
  static const String deadlift = 'mu-souleve-de-terre-conventionnel';

  /// Soulevé de terre sumo.
  static const String sumo = 'mu-souleve-de-terre-sumo';
}

/// Candidats par emplacement de musculation, du préféré au repli (le premier
/// admissible avec le matériel et les zones du jour est pris).
abstract final class GymPicks {
  /// Squat ou presse (dominante genou).
  static const List<String> squat = <String>[
    PowerIds.squatHigh,
    'mu-hack-squat-machine',
    'mu-presse-cuisses-45',
    'mu-squat-smith-machine',
    'mu-goblet-squat',
    'mu-split-squat-bulgare-halteres',
    'mu-split-squat-bulgare-poids-du-corps',
    'mu-air-squat',
  ];

  /// Squat ou presse pour un débutant (stable, appris vite : R6-P32).
  static const List<String> squatBeginner = <String>[
    'mu-presse-cuisses-45',
    'mu-goblet-squat',
    'mu-squat-smith-machine',
    'mu-presse-cuisses-horizontale',
    'mu-air-squat',
  ];

  /// Seconde dominante genou (unilatéral, presse).
  static const List<String> squatSecond = <String>[
    'mu-presse-cuisses-45',
    'mu-split-squat-bulgare-halteres',
    'mu-fente-arriere-halteres',
    'mu-hack-squat-machine',
    'mu-split-squat',
    'mu-fente-arriere-poids-du-corps',
  ];

  /// Charnière de hanche.
  static const List<String> hinge = <String>[
    'mu-souleve-de-terre-roumain-barre',
    'mu-souleve-de-terre-roumain-halteres',
    'mu-souleve-de-terre-trap-bar',
    'mu-souleve-de-terre-kettlebell',
    'mu-hip-thrust-barre',
    'mu-pont-fessier-pieds-sureleves',
  ];

  /// Fessiers (extension de hanche).
  static const List<String> glutes = <String>[
    'mu-hip-thrust-barre',
    'mu-hip-thrust-machine',
    'mu-hip-thrust-smith',
    'mu-hip-thrust-unilateral',
    'mu-pont-fessier-pieds-sureleves',
    'mu-pont-fessier-sol',
  ];

  /// Ischio-jambiers en position allongée (R6-P4 : leg curl assis).
  static const List<String> hamstring = <String>[
    'mu-leg-curl-assis',
    'mu-leg-curl-couche',
    'mu-curl-ischio-ballon',
    'mu-nordic-hamstring-curl-assiste',
  ];

  /// Quadriceps en isolation.
  static const List<String> quads = <String>[
    'mu-leg-extension',
    'mu-leg-extension-unilateral',
    'mu-reverse-nordic',
  ];

  /// Poussée horizontale.
  static const List<String> press = <String>[
    PowerIds.bench,
    'mu-developpe-couche-halteres',
    'mu-presse-pectorale-convergente',
    'mu-developpe-couche-smith',
    'mu-floor-press-halteres',
    'sw-pompe',
    'sw-pompe-inclinee',
  ];

  /// Poussée horizontale stable pour un débutant.
  static const List<String> pressBeginner = <String>[
    'mu-presse-pectorale-convergente',
    'mu-developpe-couche-halteres',
    'mu-developpe-couche-smith',
    'mu-floor-press-halteres',
    'sw-pompe-inclinee',
  ];

  /// Poussée inclinée.
  static const List<String> incline = <String>[
    'mu-developpe-incline-halteres',
    'mu-developpe-incline-barre',
    'mu-presse-pectorale-inclinee',
    'mu-developpe-incline-smith',
  ];

  /// Poussée verticale.
  static const List<String> overhead = <String>[
    'mu-developpe-halteres-assis',
    'mu-developpe-epaules-machine',
    'mu-developpe-militaire-barre-debout',
    'mu-developpe-kettlebell',
    'mu-developpe-epaules-elastique-debout',
  ];

  /// Tirage vertical.
  static const List<String> vertical = <String>[
    'mu-tirage-vertical-prise-neutre',
    'mu-tirage-vertical-prise-large-pronation',
    'mu-tirage-vertical-machine-convergente',
    'mu-traction-assistee-machine-pronation',
    'sw-traction-pronation',
    'mu-tirage-vertical-elastique',
  ];

  /// Tirage horizontal.
  static const List<String> row = <String>[
    'mu-rowing-poulie-assis-triangle',
    'mu-rowing-poitrine-appuyee-banc-incline-halteres',
    'mu-rowing-machine-poitrine-appuyee',
    'mu-rowing-haltere-unilateral-banc',
    'mu-rowing-barre-pronation',
    'mu-rowing-elastique-assis',
  ];

  /// Pectoraux en position étirée.
  static const List<String> fly = <String>[
    'mu-ecarte-poulie-vis-a-vis-milieu',
    'mu-pec-deck',
    'mu-ecarte-halteres-plat',
    'mu-ecarte-halteres-incline',
  ];

  /// Deltoïde moyen.
  static const List<String> lateral = <String>[
    'mu-elevation-laterale-poulie-unilaterale',
    'mu-elevation-laterale-halteres',
    'mu-elevation-laterale-machine',
    'mu-elevation-laterale-buste-appuye-banc-incline',
    'mu-elevation-laterale-elastique',
  ];

  /// Deltoïde postérieur.
  static const List<String> rear = <String>[
    'mu-oiseau-pec-deck-inverse',
    'mu-face-pull-corde',
    'mu-oiseau-banc-incline',
    'mu-oiseau-halteres',
    'mu-band-pull-apart',
  ];

  /// Biceps en position allongée (R6-P4 : curl incliné).
  static const List<String> biceps = <String>[
    'mu-curl-incline-halteres',
    'mu-bayesian-curl',
    'mu-curl-halteres-alterne',
    'mu-curl-poulie-basse-barre',
    'mu-curl-elastique',
  ];

  /// Triceps en position allongée (R6-P4 : extension au-dessus de la tête).
  static const List<String> triceps = <String>[
    'mu-extension-nuque-poulie-corde',
    'mu-extension-nuque-haltere-deux-mains',
    'mu-extension-nuque-haltere-unilaterale',
    'mu-pushdown-corde',
    'mu-pushdown-elastique',
  ];

  /// Mollets.
  static const List<String> calves = <String>[
    'mu-mollets-debout-machine',
    'mu-mollets-presse',
    'mu-mollets-unilateral-haltere',
    'mu-mollets-poids-du-corps-marche',
  ];

  /// Tronc.
  static const List<String> core = <String>[
    'mu-dead-bug',
    'mu-gainage-ventral-coudes',
    'mu-pallof-press-debout',
    'mu-gainage-lateral-coude',
    'mu-crunch-poulie-genoux',
  ];
}

/// Style « autres disciplines » de l'athlète [a], ou `null` pour le chemin
/// street.
CoachStyle? generalStyleOf(Athlete a) {
  final primary = a.profile.disciplines.primary;
  switch (primary) {
    case TrainingDiscipline.cardio:
      return CoachStyle.endurance;
    case TrainingDiscipline.crossfit:
      return CoachStyle.conditioning;
    case TrainingDiscipline.mobility || TrainingDiscipline.generalFitness:
      return CoachStyle.health;
    case TrainingDiscipline.musculation:
      // Mode prudent du questionnaire de santé ou reprise après plus d'un
      // an d'arrêt : le programme de santé (charges modérées, 3 en
      // réserve, dose minimale ; R5-P7, R5-P28).
      if (a.cautious || a.gapWeeks >= 52) {
        return CoachStyle.health;
      }
      return isPowerProfile(a) ? CoachStyle.strength : CoachStyle.hypertrophy;
    default:
      return null;
  }
}

/// Vrai pour un profil de musculation qui vise la force sur les trois
/// mouvements de base (R6-P8 à P12) : épreuve de force athlétique, objectif
/// de 1RM sur l'un d'eux, ou orientation « force » avec des 1RM connus.
bool isPowerProfile(Athlete a) {
  // (Pas de force athlétique pour un débutant : double progression en
  // corps entier, jamais de série de tête lourde — R5-P3.)
  if (a.level == 0) {
    return false;
  }
  const lifts = <String>{
    PowerIds.squatLow,
    PowerIds.squatHigh,
    PowerIds.bench,
    PowerIds.deadlift,
    PowerIds.sumo,
  };
  for (final e in a.profile.events ?? const <SeasonEvent>[]) {
    if (e.kind == EventKind.strengthCompetition) {
      return true;
    }
  }
  for (final g in a.profile.goals) {
    if (g.metric == GoalMetric.oneRmKg && lifts.contains(g.exerciseId)) {
      return true;
    }
  }
  final known = lifts.where((id) => a.oneRm[id] != null).length;
  return a.profile.emphasis == TrainingEmphasis.strength && known >= 2;
}

// ------------------------------------------------------------ hypertrophie

/// Emplacement d'un modèle de séance de musculation : candidats, rôle,
/// méthode, séries (avant l'ajustement au niveau), groupe prioritaire servi.
typedef _GymSlot = (List<String>, SlotRole, String, int, MuscleGroup?);

const String _cmp = Method.accessoryCompound;
const String _iso = Method.accessoryIsolation;

/// Modèles de séance (R6-P3 à P5) : polyarticulaires d'abord, une
/// isolation en position allongée par muscle (R6-P4), dix séries au plus
/// par muscle et par séance (R6-P1).
const Map<String, List<_GymSlot>> _gymDays = <String, List<_GymSlot>>{
  // Corps entier A : squat, poussée horizontale, tirage vertical, charnière.
  'fbA': <_GymSlot>[
    (GymPicks.squat, SlotRole.main, _cmp, 3, MuscleGroup.quads),
    (GymPicks.press, SlotRole.main, _cmp, 3, MuscleGroup.chest),
    (GymPicks.vertical, SlotRole.secondary, _cmp, 3, MuscleGroup.lats),
    (GymPicks.hinge, SlotRole.secondary, _cmp, 2, MuscleGroup.hamstrings),
    (GymPicks.lateral, SlotRole.accessory, _iso, 2, MuscleGroup.deltMiddle),
    (GymPicks.core, SlotRole.core, Method.accessoryCore, 2, null),
  ],
  // Corps entier B : charnière, poussée verticale, tirage horizontal.
  'fbB': <_GymSlot>[
    (GymPicks.hinge, SlotRole.main, _cmp, 3, MuscleGroup.hamstrings),
    (GymPicks.squatSecond, SlotRole.secondary, _cmp, 2, MuscleGroup.quads),
    (GymPicks.incline, SlotRole.main, _cmp, 3, MuscleGroup.chest),
    (GymPicks.row, SlotRole.secondary, _cmp, 3, MuscleGroup.upperBack),
    (GymPicks.biceps, SlotRole.accessory, _iso, 2, MuscleGroup.biceps),
    (GymPicks.triceps, SlotRole.accessory, _iso, 2, MuscleGroup.triceps),
  ],
  // Corps entier C : presse, développé haltères, tirage, fessiers.
  'fbC': <_GymSlot>[
    (GymPicks.squatSecond, SlotRole.main, _cmp, 3, MuscleGroup.quads),
    (GymPicks.overhead, SlotRole.secondary, _cmp, 2, MuscleGroup.deltAnterior),
    (GymPicks.row, SlotRole.main, _cmp, 3, MuscleGroup.upperBack),
    (GymPicks.glutes, SlotRole.secondary, _cmp, 2, MuscleGroup.glutes),
    (GymPicks.hamstring, SlotRole.accessory, _iso, 2, MuscleGroup.hamstrings),
    (GymPicks.core, SlotRole.core, Method.accessoryCore, 2, null),
  ],
  'upper1': <_GymSlot>[
    (GymPicks.press, SlotRole.main, _cmp, 3, MuscleGroup.chest),
    (GymPicks.row, SlotRole.main, _cmp, 3, MuscleGroup.upperBack),
    (GymPicks.overhead, SlotRole.secondary, _cmp, 3, MuscleGroup.deltAnterior),
    (GymPicks.vertical, SlotRole.secondary, _cmp, 3, MuscleGroup.lats),
    (GymPicks.lateral, SlotRole.accessory, _iso, 3, MuscleGroup.deltMiddle),
    (GymPicks.triceps, SlotRole.accessory, _iso, 2, MuscleGroup.triceps),
    (GymPicks.biceps, SlotRole.accessory, _iso, 2, MuscleGroup.biceps),
  ],
  'upper2': <_GymSlot>[
    (GymPicks.incline, SlotRole.main, _cmp, 3, MuscleGroup.chest),
    (GymPicks.vertical, SlotRole.main, _cmp, 3, MuscleGroup.lats),
    (GymPicks.row, SlotRole.secondary, _cmp, 3, MuscleGroup.upperBack),
    (GymPicks.fly, SlotRole.accessory, _iso, 2, MuscleGroup.chest),
    (GymPicks.lateral, SlotRole.accessory, _iso, 3, MuscleGroup.deltMiddle),
    (GymPicks.rear, SlotRole.accessory, _iso, 2, MuscleGroup.deltPosterior),
    (GymPicks.biceps, SlotRole.accessory, _iso, 2, MuscleGroup.biceps),
    (GymPicks.triceps, SlotRole.accessory, _iso, 2, MuscleGroup.triceps),
  ],
  'lower1': <_GymSlot>[
    (GymPicks.squat, SlotRole.main, _cmp, 3, MuscleGroup.quads),
    (GymPicks.hinge, SlotRole.secondary, _cmp, 3, MuscleGroup.hamstrings),
    (GymPicks.squatSecond, SlotRole.secondary, _cmp, 2, MuscleGroup.quads),
    (GymPicks.hamstring, SlotRole.accessory, _iso, 3, MuscleGroup.hamstrings),
    (GymPicks.calves, SlotRole.accessory, _iso, 3, MuscleGroup.calves),
    (GymPicks.core, SlotRole.core, Method.accessoryCore, 2, null),
  ],
  'lower2': <_GymSlot>[
    (GymPicks.glutes, SlotRole.main, _cmp, 3, MuscleGroup.glutes),
    (GymPicks.squatSecond, SlotRole.main, _cmp, 3, MuscleGroup.quads),
    (GymPicks.hinge, SlotRole.secondary, _cmp, 3, MuscleGroup.hamstrings),
    (GymPicks.quads, SlotRole.accessory, _iso, 2, MuscleGroup.quads),
    (GymPicks.hamstring, SlotRole.accessory, _iso, 2, MuscleGroup.hamstrings),
    (GymPicks.calves, SlotRole.accessory, _iso, 2, MuscleGroup.calves),
  ],
  'push': <_GymSlot>[
    (GymPicks.press, SlotRole.main, _cmp, 3, MuscleGroup.chest),
    (GymPicks.overhead, SlotRole.main, _cmp, 3, MuscleGroup.deltAnterior),
    (GymPicks.incline, SlotRole.secondary, _cmp, 2, MuscleGroup.chest),
    (GymPicks.lateral, SlotRole.accessory, _iso, 3, MuscleGroup.deltMiddle),
    (GymPicks.triceps, SlotRole.accessory, _iso, 3, MuscleGroup.triceps),
  ],
  'pull': <_GymSlot>[
    (GymPicks.vertical, SlotRole.main, _cmp, 3, MuscleGroup.lats),
    (GymPicks.row, SlotRole.main, _cmp, 3, MuscleGroup.upperBack),
    (GymPicks.rear, SlotRole.accessory, _iso, 3, MuscleGroup.deltPosterior),
    (GymPicks.biceps, SlotRole.accessory, _iso, 3, MuscleGroup.biceps),
    (GymPicks.core, SlotRole.core, Method.accessoryCore, 2, null),
  ],
  'legs': <_GymSlot>[
    (GymPicks.squat, SlotRole.main, _cmp, 3, MuscleGroup.quads),
    (GymPicks.hinge, SlotRole.main, _cmp, 3, MuscleGroup.hamstrings),
    (GymPicks.glutes, SlotRole.secondary, _cmp, 3, MuscleGroup.glutes),
    (GymPicks.hamstring, SlotRole.accessory, _iso, 2, MuscleGroup.hamstrings),
    (GymPicks.calves, SlotRole.accessory, _iso, 3, MuscleGroup.calves),
  ],
};

/// Répartition de la semaine (R6-P3) : 2 à 3 jours corps entier ; 4 jours
/// haut / bas ; 5 jours haut / bas puis poussée / tirage / jambes ; 6 jours
/// poussée / tirage / jambes deux fois. Un débutant reste en corps entier
/// jusqu'à 3 jours et passe en haut / bas au-delà.
List<String> _gymSplit(int days, int level) {
  if (days <= 3) {
    return <String>['fbA', 'fbB', 'fbC'].take(days).toList();
  }
  if (days == 4) {
    return const <String>['upper1', 'lower1', 'upper2', 'lower2'];
  }
  if (days == 5) {
    return const <String>['upper1', 'lower1', 'push', 'pull', 'legs'];
  }
  return const <String>['push', 'pull', 'legs', 'upper2', 'lower2', 'upper1']
      .take(days)
      .toList();
}

/// Groupes prioritaires du profil (spécialisation sur un muscle) : +30 à
/// 50 % de séries, en début de séance, deux à trois expositions par semaine
/// (R6-P6) ; pas avant six mois d'entraînement.
Set<MuscleGroup> _priorityGroups(Athlete a) {
  final out = <MuscleGroup>{};
  if (a.level == 0) {
    return out;
  }
  final s = a.profile.specialization;
  if (s != null && s.kind == SpecializationKind.muscle) {
    // Le profil porte un muscle du vocabulaire du catalogue (`muscles`).
    final g = muscleGroupOf[s.muscle];
    if (g != null) {
      out.add(g);
    }
  }
  return out;
}

/// Isolation qui sert le groupe prioritaire [g] (premier emplacement de la
/// séance).
List<String>? _priorityPick(MuscleGroup g) => switch (g) {
  MuscleGroup.glutes => GymPicks.glutes,
  MuscleGroup.deltMiddle => GymPicks.lateral,
  MuscleGroup.deltPosterior => GymPicks.rear,
  MuscleGroup.chest => GymPicks.fly,
  MuscleGroup.biceps => GymPicks.biceps,
  MuscleGroup.triceps => GymPicks.triceps,
  MuscleGroup.hamstrings => GymPicks.hamstring,
  MuscleGroup.quads => GymPicks.quads,
  MuscleGroup.calves => GymPicks.calves,
  MuscleGroup.lats => GymPicks.vertical,
  MuscleGroup.upperBack => GymPicks.row,
  _ => null,
};

void _buildHypertrophy(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  if (days.isEmpty) {
    return;
  }
  final level = a.level;
  final split = _gymSplit(days.length, level);
  final priority = _priorityGroups(a);
  // Séries par exercice (R6-P1 : 6 à 10 séries par muscle et par semaine
  // chez le débutant, 10 à 16 chez l'intermédiaire, 12 à 20 ensuite) :
  // le modèle donne la base ; le débutant en fait une de moins sur les
  // exercices à trois séries, les deux premières semaines comprises
  // (passe 2).
  int setsOf(int base) => level == 0 && base >= 3 ? 2 : base;
  final served = <MuscleGroup, int>{};
  for (var i = 0; i < days.length; i++) {
    final d = days[i];
    final code = split[i % split.length];
    final day = b.days[d]
      ..focus = switch (code) {
        'upper1' || 'upper2' => FocusCodes.upper,
        'lower1' || 'lower2' || 'legs' => FocusCodes.lower,
        'push' => FocusCodes.push,
        'pull' => FocusCodes.pull,
        _ => FocusCodes.fullBody,
      };
    // Échauffement général et montée (R6-P25).
    b.add(
      d,
      const <String>['mo-cars-epaule', 'mo-cat-cow', 'sw-pompe-scapulaire'],
      SlotRole.warmup,
      Method.warmupPrep,
      sets: 1,
    );
    // Groupe prioritaire en premier, deux à trois séances par semaine.
    for (final g in priority) {
      final pick = _priorityPick(g);
      if (pick != null && (served[g] ?? 0) < (days.length >= 5 ? 3 : 2)) {
        final slot = b.add(
          d,
          pick,
          SlotRole.main,
          g == MuscleGroup.glutes ? _cmp : _iso,
          sets: 3,
          note: 'priority',
        );
        if (slot != null) {
          served[g] = (served[g] ?? 0) + 1;
        }
      }
    }
    for (final (candidates, role, method, base, _) in _gymDays[code]!) {
      final pick = level == 0 && identical(candidates, GymPicks.squat)
          ? GymPicks.squatBeginner
          : (level == 0 && identical(candidates, GymPicks.press)
                ? GymPicks.pressBeginner
                : candidates);
      b.add(d, pick, role, method, sets: setsOf(base));
    }
    if (day.slots.length < 3) {
      // Repli : séance trop pauvre avec le matériel du jour.
      b.add(d, GymPicks.core, SlotRole.core, Method.accessoryCore, sets: 2);
    }
  }
}

// ------------------------------------------------------------------ force

/// Squat de compétition de l'athlète : celui qui a un 1RM (barre basse
/// d'abord), sinon la barre haute.
String _powerSquat(Athlete a) {
  for (final id in const <String>[PowerIds.squatLow, PowerIds.squatHigh]) {
    if (a.oneRm[id] != null) {
      return id;
    }
  }
  return PowerIds.squatHigh;
}

/// Soulevé de terre de l'athlète : celui qui a un 1RM (conventionnel
/// d'abord), sinon le conventionnel.
String _powerDeadlift(Athlete a) {
  for (final id in const <String>[PowerIds.deadlift, PowerIds.sumo]) {
    if (a.oneRm[id] != null) {
      return id;
    }
  }
  return PowerIds.deadlift;
}

/// Force athlétique et force générale (R6-P8 à P13) : squat deux à trois
/// fois, couché trois à quatre fois, terre une à deux fois par semaine,
/// séance lourde et séance de volume d'un même mouvement séparées, squat et
/// terre lourds à 72 h l'un de l'autre ; une variante par mouvement sur la
/// phase faible ; accessoires d'hypertrophie en 6 à 12 répétitions.
void _buildPower(_Builder b, Set<int> runDays) {
  final a = b.a;
  final days = <int>[
    for (var d = 0; d < a.dayCount; d++)
      if (!runDays.contains(d)) d,
  ];
  final n = days.length;
  if (n == 0) {
    return;
  }
  final squat = _powerSquat(a);
  final dead = _powerDeadlift(a);
  const bench = PowerIds.bench;
  final adv = a.level >= 2;
  // Bas du dos avec antécédent : la variante du terre est un tirage moins
  // coûteux (trap bar) et le volume du terre reste à une séance (R6-P13,
  // R5-P20).
  final back = a.limitOn(Joint.lumbar) != null;
  int at(int k) => days[k % n];
  // Jours : lourd squat (0), lourd couché (1), lourd terre (2 : à 72 h du
  // squat lourd), volume squat (3).
  final squatHeavy = at(0);
  final benchHeavy = n >= 4 ? at(1) : at(1 % n);
  final deadHeavy = n >= 4 ? at(2) : (n >= 2 ? at(1) : at(0));
  final squatVolume = n >= 4 ? at(3) : (n >= 3 ? at(2) : -1);
  final light = n >= 5 ? at(4) : -1;

  void lift(int d, String id, String method, DayStress stress, {int sets = 4}) {
    if (d < 0) {
      return;
    }
    b.add(
      d,
      <String>[id],
      method == Method.liftHeavy ? SlotRole.main : SlotRole.secondary,
      method,
      sets: sets,
      stress: stress,
    );
  }

  void variant(int d, List<String> ids, String ref, {int sets = 3}) {
    if (d < 0) {
      return;
    }
    b.add(
      d,
      ids,
      SlotRole.secondary,
      Method.liftVariant,
      sets: sets,
      referenceId: ref,
      stress: DayStress.medium,
    );
  }

  for (final d in days) {
    b.days[d].focus = FocusCodes.fullBody;
    b.add(
      d,
      const <String>['mo-cars-epaule', 'mo-cat-cow'],
      SlotRole.warmup,
      Method.warmupPrep,
      sets: 1,
    );
  }
  // Mouvements principaux, du plus lourd au plus léger dans chaque séance
  // (R6-P5 : le mouvement à faire progresser en premier).
  lift(squatHeavy, squat, Method.liftHeavy, DayStress.heavy);
  lift(benchHeavy, bench, Method.liftHeavy, DayStress.heavy);
  lift(deadHeavy, dead, Method.liftHeavy, DayStress.heavy, sets: adv ? 4 : 3);
  // Couché : trois à quatre expositions (R6-P8), volume le jour du squat
  // lourd, léger ou variante ailleurs.
  if (benchHeavy != squatHeavy) {
    lift(squatHeavy, bench, Method.liftVolume, DayStress.medium);
  }
  if (squatVolume >= 0) {
    lift(squatVolume, squat, Method.liftVolume, DayStress.medium);
    variant(
      squatVolume,
      const <String>[
        'mu-developpe-couche-pause',
        'mu-developpe-couche-prise-serree',
        'mu-developpe-couche-larsen',
      ],
      bench,
    );
  }
  if (deadHeavy != benchHeavy && n >= 4) {
    lift(deadHeavy, bench, Method.liftLight, DayStress.light, sets: 3);
  }
  // Variante du terre (phase faible) le jour du couché lourd, chez
  // l'avancé ; sinon le soulevé de terre roumain en accessoire.
  if (adv && !back && benchHeavy != deadHeavy) {
    variant(
      benchHeavy,
      const <String>[
        'mu-souleve-de-terre-pause',
        'mu-souleve-de-terre-deficit',
        'mu-souleve-de-terre-roumain-barre',
      ],
      dead,
    );
  } else {
    b.add(
      squatVolume >= 0 ? squatVolume : squatHeavy,
      back
          ? const <String>[
              'mu-souleve-de-terre-roumain-halteres',
              'mu-hyperextension-45-fessiers',
              'mu-pont-fessier-pieds-sureleves',
            ]
          : const <String>[
              'mu-souleve-de-terre-roumain-barre',
              'mu-souleve-de-terre-roumain-halteres',
            ],
      SlotRole.accessory,
      _cmp,
      sets: 3,
    );
  }
  if (light >= 0) {
    variant(light, const <String>['mu-squat-pause', 'mu-front-squat'], squat);
    lift(light, bench, Method.liftLight, DayStress.light, sets: 3);
  }
  // Accessoires (R6-P10) : tirage horizontal et vertical (équilibre des
  // épaules du couché), triceps, ischio-jambiers, tronc ; arrière d'épaule
  // et coiffe en prévention (R6-P13).
  for (var i = 0; i < n; i++) {
    final d = days[i];
    b.add(
      d,
      i.isEven ? GymPicks.row : GymPicks.vertical,
      SlotRole.accessory,
      _cmp,
      sets: 3,
      keep: true,
    );
    if (d == benchHeavy || d == squatVolume) {
      b.add(d, GymPicks.triceps, SlotRole.accessory, _iso, sets: 2);
    }
    if (d == squatHeavy || d == deadHeavy) {
      b.add(d, GymPicks.hamstring, SlotRole.accessory, _iso, sets: 2);
    }
    b.add(
      d,
      i.isEven ? Picks.rearDelt : Picks.cuff,
      SlotRole.accessory,
      Method.accessoryPrehab,
      sets: 2,
    );
    b.add(
      d,
      const <String>[
        'mu-pallof-press-debout',
        'mu-gainage-ventral-coudes',
        'mu-dead-bug',
        'mu-gainage-lateral-coude',
      ],
      SlotRole.core,
      Method.accessoryCore,
      sets: 2,
      rotate: true,
    );
  }
}

// ------------------------------------------------------------------ santé

/// Étirements statiques de fin de séance (R6-P23 : 2 à 4 fois 30 à 60 s par
/// zone ; R6-P25 : jamais avant l'effort), par rotation.
const List<List<String>> _stretches = <List<String>>[
  <String>['mo-etirement-gastrocnemiens-mur', 'mo-etirement-mollets-marche'],
  <String>['mo-ischio-assis-unilateral', 'mo-ischio-debout-pied-sureleve'],
  <String>['mo-flechisseurs-hanche-semi-agenouille', 'mo-fente-basse-etirement'],
  <String>['mo-etirement-pectoral-cadre-porte', 'mo-etirement-chiot'],
  <String>['mo-figure-4-allonge', 'mo-pigeon-sol'],
];

/// Santé, mobilité, forme générale et perte de poids (R6-P21, P23, P24,
/// P26, P31, P32) : renforcement corps entier deux à trois fois par
/// semaine (8 à 12 répétitions, 2 à 3 en réserve, exercices stables) ;
/// équilibre trois jours par semaine à partir de 65 ans ; marche ou cardio
/// à faible impact vers 150 minutes par semaine ; étirements en fin de
/// séance, cinq jours sur sept pour progresser en amplitude.
void _buildHealth(_Builder b) {
  final a = b.a;
  final n = a.dayCount;
  final senior = a.age >= 65;
  final lose =
      a.profile.bodyWeightGoal == BodyWeightGoal.lose ||
      a.profile.disciplines.primary == TrainingDiscipline.generalFitness;
  // Jours de renforcement : deux ou trois, espacés ; les autres jours
  // (senior) : équilibre, marche, mobilité.
  final strengthDays = spreadDays(a, b.allDays, n >= 4 ? 3 : (n >= 2 ? n : 1));
  final balanceDays = senior ? spreadDays(a, b.allDays, n >= 3 ? 3 : n) : <int>[];
  var stretch = 0;
  for (var d = 0; d < n; d++) {
    final minutes = a.days[d].minutes;
    b.days[d].focus = strengthDays.contains(d)
        ? FocusCodes.fullBody
        : FocusCodes.mobility;
    b.add(
      d,
      const <String>['mo-cars-hanche', 'mo-cars-epaule', 'mo-cat-cow'],
      SlotRole.warmup,
      Method.warmupPrep,
      sets: 1,
    );
    if (balanceDays.contains(d)) {
      // R6-P26 : équilibre, la difficulté progresse avant la charge.
      b.add(
        d,
        const <String>['mo-marche-talons', 'mo-marche-pointes'],
        SlotRole.skill,
        Method.mobility,
        sets: 2,
        note: 'balance',
      );
      b.add(
        d,
        const <String>['mu-step-up-lateral', 'mu-fente-laterale'],
        SlotRole.secondary,
        _cmp,
        sets: 2,
        note: 'balance',
      );
    }
    if (strengthDays.contains(d)) {
      final k = strengthDays.indexOf(d);
      // Jambes : assis-debout (squat sur chaise), presse ou step-up.
      b.add(
        d,
        senior
            ? const <String>['mu-air-squat', 'mu-wall-sit', 'mu-step-up-lateral']
            : (k.isEven ? GymPicks.squatBeginner : GymPicks.squatSecond),
        SlotRole.main,
        _cmp,
        sets: 2,
      );
      // Poussée stable.
      b.add(
        d,
        senior
            ? const <String>[
                'sw-pompe-murale',
                'mu-developpe-pectoral-elastique',
                'sw-pompe-inclinee',
              ]
            : GymPicks.pressBeginner,
        SlotRole.main,
        _cmp,
        sets: 2,
      );
      // Tirage.
      b.add(
        d,
        senior
            ? const <String>[
                'mu-rowing-elastique-assis',
                'mu-tirage-vertical-elastique',
              ]
            : (k.isEven ? GymPicks.row : GymPicks.vertical),
        SlotRole.secondary,
        _cmp,
        sets: 2,
      );
      // Hanches.
      b.add(
        d,
        const <String>[
          'mu-pont-fessier-sol',
          'mu-hip-thrust-machine',
          'mu-pont-fessier-pieds-sureleves',
        ],
        SlotRole.secondary,
        _cmp,
        sets: 2,
      );
      if (!senior && minutes >= 40) {
        b.add(
          d,
          k.isEven ? GymPicks.overhead : GymPicks.hinge,
          SlotRole.accessory,
          _cmp,
          sets: 2,
        );
      }
      b.add(
        d,
        const <String>['mu-dead-bug', 'mu-gainage-ventral-coudes'],
        SlotRole.core,
        Method.accessoryCore,
        sets: 2,
        rotate: true,
      );
    }
    // Cardio à faible impact (R6-P32) ou marche (R6-P21, P26).
    if (lose || senior || !strengthDays.contains(d)) {
      b.add(
        d,
        senior
            ? const <String>['ca-marche-rapide']
            : const <String>[
                'ca-velo-endurance',
                'ca-marche-tapis-incline',
                'ca-rameur-endurance',
                'ca-marche-rapide',
              ],
        SlotRole.conditioning,
        Method.runEasy,
        sets: 1,
        note: 'low_impact',
      );
    }
    // Étirements (R6-P23).
    b.add(
      d,
      _stretches[stretch % _stretches.length],
      SlotRole.mobility,
      Method.mobility,
      sets: 1,
    );
    b.add(
      d,
      _stretches[(stretch + 1) % _stretches.length],
      SlotRole.mobility,
      Method.mobility,
      sets: 1,
    );
    stretch += 2;
  }
}

// ------------------------------------------------------- conditionnement

/// Pièces de conditionnement de la semaine (R6-P27) : format, durée et
/// mouvements, du plus court au plus long ; durées mélangées sur la
/// semaine (court < 7 min, moyen 8 à 15 min, long 20 min et plus).
/// Le code de groupe porte le format : `amrap:<s>`, `emom:<s>:<int>`,
/// `rft:<tours>:<limite s>`, `chipper:<limite s>`,
/// `intervals:<tours>:<intervalle s>`.
const List<(String, List<List<String>>)> _wods = <(String, List<List<String>>)>[
  (
    'amrap:720',
    <List<String>>[
      <String>['cf-wall-ball', 'cf-thruster-halteres'],
      <String>['cf-toes-to-bar-kipping', 'sw-releve-genoux-suspendu'],
      <String>['ca-rameur-intervalles-500m', 'ca-air-bike-endurance'],
    ],
  ),
  (
    'emom:600:60',
    <List<String>>[
      <String>['mu-swing-kettlebell-russe', 'cf-sdhp-kettlebell'],
      <String>['cf-burpee', 'cf-demi-burpee'],
    ],
  ),
  (
    'rft:4:900',
    <List<String>>[
      <String>['ca-rameur-intervalles-500m', 'ca-air-bike-endurance'],
      <String>['cf-box-step-over', 'mu-box-jump'],
      <String>['sw-traction-pronation', 'sw-row-australien-anneaux'],
    ],
  ),
  (
    'intervals:7:60',
    <List<String>>[
      <String>['ca-air-bike-endurance', 'ca-rameur-intervalles-500m'],
    ],
  ),
  (
    'chipper:1500',
    <List<String>>[
      <String>['ca-rameur-intervalles-500m', 'ca-air-bike-endurance'],
      <String>['cf-wall-ball', 'cf-thruster-halteres'],
      <String>['mu-swing-kettlebell-russe', 'cf-sdhp-kettlebell'],
      <String>['cf-box-step-over', 'mu-box-jump'],
      <String>['cf-burpee', 'cf-demi-burpee'],
    ],
  ),
];

/// Conditionnement (CrossFit, R6-P27, P28) : échauffement, bloc de force ou
/// de technique de 15 à 20 minutes, conditionnement de 8 à 20 minutes au
/// format codifié ; haltérophilie lourde seulement à l'état frais ;
/// gymnastique stricte avant le kipping ; jamais deux séances longues et
/// lourdes de suite sur les mêmes schémas.
void _buildConditioning(_Builder b) {
  final a = b.a;
  final n = a.dayCount;
  final squat = a.oneRm[PowerIds.squatHigh] != null
      ? PowerIds.squatHigh
      : (a.oneRm[PowerIds.squatLow] != null
            ? PowerIds.squatLow
            : PowerIds.squatHigh);
  // Bloc de force ou de technique, par rotation : squat lourd, épaulé
  // technique, soulevé de terre, développé, squat avant.
  // (Débutant : séries égales, jamais de série de tête lourde — R5-P3.)
  final strength = <(List<String>, String)>[
    (<String>[squat], a.level == 0 ? Method.liftVolume : Method.liftHeavy),
    (
      const <String>['mu-power-clean', 'mu-power-clean-suspendu'],
      Method.liftLight,
    ),
    (<String>[PowerIds.deadlift], Method.liftVolume),
    (
      const <String>['mu-push-press', 'mu-developpe-militaire-barre-debout'],
      Method.liftVolume,
    ),
    (const <String>['mu-front-squat', 'mu-goblet-squat'], Method.liftVolume),
  ];
  // Muscle-up visé : travail strict deux séances par semaine, à l'état
  // frais (R6-P28 : strict avant kipping).
  final mu = a.aimsAt(Ids.muscleUp);
  final muDays = mu ? spreadDays(a, b.allDays, n >= 4 ? 2 : 1) : <int>[];
  // Pièces : la plus longue loin de la séance de squat lourd.
  final order = <int>[0, 2, 1, 4, 3];
  for (var d = 0; d < n; d++) {
    b.days[d].focus = FocusCodes.conditioning;
    b.add(
      d,
      const <String>['mo-cars-hanche', 'mo-cars-epaule', 'mo-cat-cow'],
      SlotRole.warmup,
      Method.warmupPrep,
      sets: 1,
    );
    if (muDays.contains(d)) {
      _addMuscleUpPractice(b, d, a.reps[Ids.muscleUp] ?? 0);
    }
    // Créneau court : la pièce seule, à la durée du créneau (R6-P27 : une
    // pièce courte de 5 à 10 minutes garde son format) ; le bloc de force
    // à partir de 40 minutes.
    final minutes = a.days[d].minutes;
    if (minutes >= 40) {
      final (ids, method) = strength[d % strength.length];
      b.add(
        d,
        ids,
        method == Method.liftHeavy ? SlotRole.main : SlotRole.secondary,
        method,
        sets: method == Method.liftHeavy ? 4 : 3,
        stress: method == Method.liftHeavy
            ? DayStress.heavy
            : DayStress.medium,
      );
    }
    final (format, moves) = _wods[order[d % order.length]];
    final room = (minutes - (minutes >= 40 ? 25 : 6)) * 60;
    final fitted = _fitWod(format, room);
    for (final m in moves) {
      b.add(
        d,
        m,
        SlotRole.conditioning,
        Method.wod,
        sets: 1,
        group: fitted,
      );
    }
    if (d.isEven && minutes >= 30) {
      b.add(
        d,
        GymPicks.core,
        SlotRole.core,
        Method.accessoryCore,
        sets: 2,
        rotate: true,
      );
    }
  }
}

/// Format de pièce [format] ramené à [seconds] au plus (durée, limite de
/// temps ou nombre de tours), 4 minutes au moins.
String _fitWod(String format, int seconds) {
  final parts = format.split(':');
  final room = seconds < 240 ? 240 : seconds;
  int scaled(int v) {
    final t = v > room ? (room ~/ 60) * 60 : v;
    return t < 240 ? 240 : t;
  }

  switch (parts.first) {
    case 'amrap' || 'chipper':
      return '${parts[0]}:${scaled(int.parse(parts[1]))}';
    case 'emom':
      return '${parts[0]}:${scaled(int.parse(parts[1]))}:${parts[2]}';
    case 'rft':
      final limit = int.parse(parts[2]);
      final rounds = int.parse(parts[1]);
      final t = scaled(limit);
      final r = (rounds * t / limit).floor();
      return 'rft:${r < 2 ? 2 : r}:$t';
    case 'intervals':
      final rounds = int.parse(parts[1]);
      final each = int.parse(parts[2]);
      // Un intervalle d'effort, un de récupération.
      final most = room ~/ (2 * each);
      return 'intervals:${most < rounds ? (most < 3 ? 3 : most) : rounds}:'
          '$each';
    default:
      return format;
  }
}

// ----------------------------------------------------------------- course

/// Course (R6-P14 à P22) : sortie longue le jour le plus long, une séance
/// de qualité par semaine (deux à partir de l'intermédiaire avec quatre
/// séances et plus ; aucune les six premières semaines d'un débutant),
/// footings faciles ailleurs ; deux renforcements courts par semaine
/// (mollets, hanches, R6-P22) en fin de footing ; jamais deux jours
/// intenses de suite.
Set<int> _buildEndurance(_Builder b) {
  final a = b.a;
  final n = a.dayCount;
  final runnable = <int>[
    for (var d = 0; d < n; d++)
      if (a.can(Ids.easyRun, d)) d,
  ];
  if (runnable.isEmpty) {
    return <int>{};
  }
  var long = runnable.first;
  for (final d in runnable) {
    if (a.days[d].minutes >= a.days[long].minutes) {
      long = d;
    }
  }
  int distance(int x, int y) {
    var g = (a.days[x].weekday - a.days[y].weekday).abs();
    if (g > 3) {
      g = 7 - g;
    }
    return g;
  }

  final quality = <int>[];
  final wanted = a.level == 0 ? 1 : (a.level >= 1 && n >= 5 ? 2 : 1);
  for (var k = 0; k < wanted; k++) {
    var best = -1;
    for (final d in runnable) {
      if (d == long || quality.contains(d)) {
        continue;
      }
      // Jamais la veille ni le lendemain de la sortie longue ou d'une autre
      // séance de qualité.
      final near = <int>[long, ...quality].any((o) => distance(o, d) < 2);
      if (near) {
        continue;
      }
      if (best < 0 || distance(d, long) > distance(best, long)) {
        best = d;
      }
    }
    if (best >= 0) {
      quality.add(best);
    }
  }
  // Renforcement : les jours faciles d'abord, puis après une séance de
  // qualité (jamais le jour de la sortie longue) — deux par semaine
  // (R6-P22).
  final strength = <int>[
    for (final d in runnable)
      if (d != long && !quality.contains(d)) d,
    for (final d in quality) d,
  ];
  for (final d in runnable) {
    b.days[d].focus = quality.contains(d)
        ? FocusCodes.cardioIntervals
        : FocusCodes.cardioEndurance;
    b.add(
      d,
      const <String>[
        'ca-educatif-montees-genoux',
        'ca-educatif-talons-fesses',
        'mo-cars-hanche',
      ],
      SlotRole.warmup,
      Method.warmupPrep,
      sets: 1,
    );
    if (d == long) {
      b.add(
        d,
        <String>[Ids.longRun, Ids.easyRun],
        SlotRole.main,
        Method.runLong,
        sets: 1,
      );
    } else if (quality.contains(d)) {
      b.add(
        d,
        <String>[Ids.easyRun],
        SlotRole.warmup,
        Method.runEasy,
        sets: 1,
        note: 'run_warmup',
      );
      b.add(
        d,
        quality.indexOf(d) == 0
            ? const <String>[
                'ca-fractionne-long-1000m',
                'ca-cotes-longues',
                'ca-fartlek',
              ]
            : const <String>['ca-course-seuil-tempo', 'ca-fartlek'],
        SlotRole.main,
        Method.runQuality,
        sets: 4,
        fromWeek: a.level == 0 ? 6 : 0,
      );
    } else {
      b.add(d, <String>[Ids.easyRun], SlotRole.main, Method.runEasy, sets: 1);
    }
  }
  // Renforcement du coureur : deux séances courtes (R6-P22), en fin de
  // footing facile.
  for (final d in strength.take(2)) {
    b
      ..add(
        d,
        const <String>[
          'mu-mollets-unilateral-haltere',
          'mu-mollets-poids-du-corps-marche',
        ],
        SlotRole.accessory,
        Method.accessoryIsolation,
        sets: 2,
        keep: true,
      )
      ..add(
        d,
        const <String>[
          'mu-split-squat',
          'mu-fente-arriere-poids-du-corps',
          'mu-step-up-lateral',
        ],
        SlotRole.accessory,
        Method.accessoryLegs,
        sets: 2,
        keep: true,
      )
      ..add(
        d,
        const <String>[
          'mu-pont-fessier-unilateral',
          'mu-abduction-hanche-couche',
          'mu-clamshell',
        ],
        SlotRole.accessory,
        Method.accessoryCompound,
        sets: 2,
        keep: true,
      );
  }
  return runnable.toSet();
}

// ------------------------------------------------------------ interférence

/// Mouvements lourds du bas du corps (squat et soulevé de terre et leurs
/// variantes à la barre) : ceux que l'interférence avec la course limite.
bool isHeavyLowerLift(String id) =>
    (id.contains('squat') && !id.contains('goblet') && !id.contains('air')) ||
    (id.contains('souleve-de-terre') && !id.contains('roumain-halteres'));

/// Interférence force / endurance (R6-P29, R6-P30) : pas de séance lourde
/// du bas du corps la veille ni le jour d'une sortie longue ou d'une
/// séance de qualité ; la séance lourde devient une séance de volume
/// modéré (méthode `lift.volume`, stress moyen). Choix raisonné sur R6-P30
/// (ordre et délai : 6 h ou jours séparés chez l'avancé).
void _limitInterference(_Builder b) {
  final a = b.a;
  final hard = <int>{
    for (var d = 0; d < a.dayCount; d++)
      if (b.days[d].slots.any(
        (s) => s.method == Method.runLong || s.method == Method.runQuality,
      ))
        d,
  };
  if (hard.isEmpty) {
    return;
  }
  for (var d = 0; d < a.dayCount; d++) {
    final near = hard.contains(d) || hard.any((r) => b.dayBefore(d, r));
    if (!near) {
      continue;
    }
    final slots = b.days[d].slots;
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      if (s.method == Method.liftHeavy && isHeavyLowerLift(s.exerciseId)) {
        slots[i] = SlotSpec(
          exerciseId: s.exerciseId,
          role: s.role,
          method: Method.liftVolume,
          sets: s.sets > 3 ? 3 : s.sets,
          stress: DayStress.medium,
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
      }
    }
  }
}
