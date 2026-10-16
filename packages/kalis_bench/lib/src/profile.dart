/// Profil type du banc : un sur-ensemble du profil d'athlète de
/// `kalis_core` (0.3.0), avec ce qu'un coach demande en plus — tests et
/// records exacts, échéances, points faibles, antécédents, récupération et
/// vie, coupure, spécialisation — et les attentes de coach.
///
/// Format : `docs/PROFILS.md`. L'adaptateur vers `AthleteProfile` est dans
/// `adapter.dart`, isolé, pour être rebranché sur le profil v3.
library;

import 'package:kalis_core/kalis_core.dart';

/// Niveau d'un profil du banc (ordre croissant).
enum BenchLevel {
  /// Débutant.
  beginner('beginner', 'débutant'),

  /// Intermédiaire.
  intermediate('intermediate', 'intermédiaire'),

  /// Avancé.
  advanced('advanced', 'avancé'),

  /// Élite.
  elite('elite', 'élite');

  const BenchLevel(this.code, this.label);

  /// Code stable (JSON).
  final String code;

  /// Nom français.
  final String label;

  /// Niveau d'un code ; [FormatException] s'il est inconnu.
  static BenchLevel fromCode(String code) {
    for (final v in values) {
      if (v.code == code) {
        return v;
      }
    }
    throw FormatException('BenchLevel : code inconnu', code);
  }
}

/// Lecture d'un objet JSON du banc.
Map<String, Object?> benchObject(Object? value, String what) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw FormatException('$what : objet JSON attendu');
}

/// Lecture d'une liste JSON du banc (absente : liste vide).
List<Object?> benchList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return const <Object?>[];
  }
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('$key : liste JSON attendue');
}

/// Lecture d'un texte obligatoire.
String benchString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('$key : texte attendu');
}

/// Lecture d'un texte facultatif.
String? benchStringOrNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('$key : texte attendu');
}

/// Lecture d'un entier obligatoire.
int benchInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('$key : entier attendu');
}

/// Lecture d'un entier facultatif.
int? benchIntOrNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('$key : entier attendu');
}

/// Lecture d'un nombre facultatif.
double? benchDoubleOrNull(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('$key : nombre attendu');
}

/// Lecture d'un nombre obligatoire.
double benchDouble(Map<String, Object?> json, String key) {
  final value = benchDoubleOrNull(json, key);
  if (value == null) {
    throw FormatException('$key : nombre attendu');
  }
  return value;
}

/// Lecture d'une liste de textes (absente : liste vide).
List<String> benchStrings(Map<String, Object?> json, String key) {
  return <String>[
    for (final v in benchList(json, key))
      if (v is String) v else throw FormatException('$key : textes attendus'),
  ];
}

/// Test ou record exact d'un mouvement.
final class BenchRecord {
  /// Record.
  const BenchRecord({
    required this.exerciseId,
    required this.measure,
    required this.value,
    this.distanceMeters,
    this.testedWeeksAgo,
  });

  /// Lit un record.
  factory BenchRecord.fromJson(Map<String, Object?> json) => BenchRecord(
    exerciseId: benchString(json, 'exerciseId'),
    measure: LevelMeasure.fromCode(benchString(json, 'measure')),
    value: benchDouble(json, 'value'),
    distanceMeters: benchDoubleOrNull(json, 'distanceMeters'),
    testedWeeksAgo: benchIntOrNull(json, 'testedWeeksAgo'),
  );

  /// Exercice.
  final String exerciseId;

  /// Grandeur mesurée (1RM : charge externe, lest seul pour un lesté).
  final LevelMeasure measure;

  /// Valeur exacte.
  final double value;

  /// Distance, pour un temps.
  final double? distanceMeters;

  /// Ancienneté du test, en semaines.
  final int? testedWeeksAgo;
}

/// Cible chiffrée d'une échéance ou d'un objectif.
final class BenchTarget {
  /// Cible.
  const BenchTarget({
    required this.exerciseId,
    required this.metric,
    this.targetValue,
    this.loadKg,
    this.distanceMeters,
    this.durationSeconds,
  });

  /// Lit une cible.
  factory BenchTarget.fromJson(Map<String, Object?> json) => BenchTarget(
    exerciseId: benchString(json, 'exerciseId'),
    metric: GoalMetric.fromCode(benchString(json, 'metric')),
    targetValue: benchDoubleOrNull(json, 'targetValue'),
    loadKg: benchDoubleOrNull(json, 'loadKg'),
    distanceMeters: benchDoubleOrNull(json, 'distanceMeters'),
    durationSeconds: benchIntOrNull(json, 'durationSeconds'),
  );

  /// Exercice visé.
  final String exerciseId;

  /// Grandeur visée.
  final GoalMetric metric;

  /// Valeur visée (absente pour une figure à débloquer).
  final double? targetValue;

  /// Charge externe de référence (répétitions à une charge donnée).
  final double? loadKg;

  /// Distance de référence (temps sur une distance).
  final double? distanceMeters;

  /// Durée de référence (distance en une durée).
  final int? durationSeconds;
}

/// Échéance : compétition ou test daté.
final class BenchEvent {
  /// Échéance.
  const BenchEvent({
    required this.id,
    required this.kind,
    required this.label,
    required this.weeksOut,
    required this.priority,
    required this.format,
    required this.targets,
  });

  /// Lit une échéance.
  factory BenchEvent.fromJson(Map<String, Object?> json) => BenchEvent(
    id: benchString(json, 'id'),
    kind: benchString(json, 'kind'),
    label: benchString(json, 'label'),
    weeksOut: benchInt(json, 'weeksOut'),
    priority: benchStringOrNull(json, 'priority') ?? 'A',
    format: benchStringOrNull(json, 'format') ?? 'test',
    targets: <BenchTarget>[
      for (final t in benchList(json, 'targets'))
        BenchTarget.fromJson(benchObject(t, 'targets')),
    ],
  );

  /// Identifiant.
  final String id;

  /// `competition` ou `test`.
  final String kind;

  /// Nom lisible.
  final String label;

  /// Semaines entre le début du programme et l'échéance : elle a lieu
  /// pendant la semaine de rang `weeksOut − 1` (0 = première).
  final int weeksOut;

  /// `A` (prioritaire : pic de forme) ou `B` (secondaire).
  final String priority;

  /// Format de l'épreuve (`streetlifting`, `sets_reps`, `figures`,
  /// `powerlifting`, `course`, `test`).
  final String format;

  /// Cibles chiffrées.
  final List<BenchTarget> targets;
}

/// Objectif daté hors échéance (figure à débloquer, record visé).
final class BenchGoal {
  /// Objectif.
  const BenchGoal({
    required this.id,
    required this.target,
    required this.weeksOut,
  });

  /// Lit un objectif.
  factory BenchGoal.fromJson(Map<String, Object?> json) => BenchGoal(
    id: benchString(json, 'id'),
    target: BenchTarget.fromJson(json),
    weeksOut: benchInt(json, 'weeksOut'),
  );

  /// Identifiant.
  final String id;

  /// Cible.
  final BenchTarget target;

  /// Échéance souhaitée, en semaines.
  final int weeksOut;
}

/// Point faible déclaré.
final class BenchWeakPoint {
  /// Point faible.
  const BenchWeakPoint({
    required this.kind,
    required this.note,
    this.exerciseId,
    this.muscleGroup,
  });

  /// Lit un point faible.
  factory BenchWeakPoint.fromJson(Map<String, Object?> json) => BenchWeakPoint(
    kind: benchString(json, 'kind'),
    note: benchString(json, 'note'),
    exerciseId: benchStringOrNull(json, 'exerciseId'),
    muscleGroup: benchStringOrNull(json, 'muscleGroup'),
  );

  /// `movement`, `muscle` ou `quality`.
  final String kind;

  /// Ce que l'athlète ou son coach en dit.
  final String note;

  /// Mouvement concerné.
  final String? exerciseId;

  /// Groupe musculaire concerné (code de `MuscleGroup`).
  final String? muscleGroup;
}

/// Blessure en cours ou antécédent.
final class BenchInjury {
  /// Blessure.
  const BenchInjury({
    required this.zone,
    required this.side,
    required this.discomfort,
    required this.status,
    required this.label,
    this.joint,
    this.monthsAgo,
  });

  /// Lit une blessure.
  factory BenchInjury.fromJson(Map<String, Object?> json) {
    final joint = benchStringOrNull(json, 'joint');
    return BenchInjury(
      zone: BodyZone.fromCode(benchString(json, 'zone')),
      side: BodySide.fromCode(benchString(json, 'side')),
      discomfort: benchInt(json, 'discomfort'),
      status: benchString(json, 'status'),
      label: benchString(json, 'label'),
      joint: joint == null ? null : Joint.fromCode(joint),
      monthsAgo: benchIntOrNull(json, 'monthsAgo'),
    );
  }

  /// Zone.
  final BodyZone zone;

  /// Côté.
  final BodySide side;

  /// Gêne actuelle, de 0 à 10.
  final int discomfort;

  /// `current` (gêne présente) ou `history` (antécédent).
  final String status;

  /// Description telle que l'athlète la donne (aucun diagnostic du banc).
  final String label;

  /// Articulation suivie par le catalogue.
  final Joint? joint;

  /// Ancienneté de l'épisode, en mois.
  final int? monthsAgo;

  /// Articulation du catalogue concernée (celle déclarée, sinon celle de
  /// la zone), ou `null` si la zone n'en désigne aucune.
  Joint? get catalogJoint => joint ?? jointOfZone[zone];
}

/// Articulation du catalogue que désigne une zone du corps.
const Map<BodyZone, Joint> jointOfZone = <BodyZone, Joint>{
  BodyZone.shoulder: Joint.shoulder,
  BodyZone.elbow: Joint.elbow,
  BodyZone.wristHand: Joint.wrist,
  BodyZone.lowerBack: Joint.lumbar,
  BodyZone.knee: Joint.knee,
  BodyZone.hip: Joint.hip,
  BodyZone.ankleFoot: Joint.ankle,
};

/// Autre sport pratiqué.
final class BenchOtherSport {
  /// Autre sport.
  const BenchOtherSport({
    required this.sport,
    required this.sessionsPerWeek,
    required this.minutesPerSession,
    required this.intensity,
  });

  /// Lit un autre sport.
  factory BenchOtherSport.fromJson(Map<String, Object?> json) =>
      BenchOtherSport(
        sport: benchString(json, 'sport'),
        sessionsPerWeek: benchInt(json, 'sessionsPerWeek'),
        minutesPerSession: benchInt(json, 'minutesPerSession'),
        intensity: benchStringOrNull(json, 'intensity') ?? 'moderate',
      );

  /// Nom du sport.
  final String sport;

  /// Séances par semaine.
  final int sessionsPerWeek;

  /// Minutes par séance.
  final int minutesPerSession;

  /// `easy`, `moderate` ou `hard`.
  final String intensity;
}

/// Récupération et vie.
final class BenchRecovery {
  /// Récupération.
  const BenchRecovery({
    this.sleepHours,
    this.sleepQuality,
    this.stress,
    this.physicalJob = 'none',
    this.energyDeficit = false,
    this.otherSports = const <BenchOtherSport>[],
  });

  /// Lit la récupération (objet absent : valeurs neutres).
  factory BenchRecovery.fromJson(Map<String, Object?>? json) {
    if (json == null) {
      return const BenchRecovery();
    }
    return BenchRecovery(
      sleepHours: benchDoubleOrNull(json, 'sleepHours'),
      sleepQuality: benchIntOrNull(json, 'sleepQuality'),
      stress: benchIntOrNull(json, 'stress'),
      physicalJob: benchStringOrNull(json, 'physicalJob') ?? 'none',
      energyDeficit: json['energyDeficit'] == true,
      otherSports: <BenchOtherSport>[
        for (final s in benchList(json, 'otherSports'))
          BenchOtherSport.fromJson(benchObject(s, 'otherSports')),
      ],
    );
  }

  /// Heures de sommeil habituelles par nuit.
  final double? sleepHours;

  /// Qualité du sommeil, de 1 à 5 (5 = très bonne).
  final int? sleepQuality;

  /// Stress de vie, de 1 (aucun) à 5 (très élevé).
  final int? stress;

  /// Travail physique : `none`, `moderate` ou `heavy`.
  final String physicalJob;

  /// Déficit énergétique en cours (perte de poids voulue).
  final bool energyDeficit;

  /// Autres sports.
  final List<BenchOtherSport> otherSports;
}

/// Attente de coach vérifiable par le banc.
final class BenchCheck {
  /// Attente.
  const BenchCheck({
    required this.id,
    required this.type,
    required this.label,
    required this.params,
  });

  /// Lit une attente.
  factory BenchCheck.fromJson(Map<String, Object?> json) => BenchCheck(
    id: benchString(json, 'id'),
    type: benchString(json, 'type'),
    label: benchString(json, 'label'),
    params: json,
  );

  /// Identifiant dans le profil.
  final String id;

  /// Type de vérification (`expectations.dart`).
  final String type;

  /// Énoncé de l'attente, en français.
  final String label;

  /// Paramètres (l'objet JSON entier).
  final Map<String, Object?> params;
}

/// Profil type du banc.
final class BenchProfile {
  /// Profil.
  BenchProfile({
    required this.key,
    required this.group,
    required this.title,
    required this.summary,
    required this.level,
    required this.trainingAgeMonths,
    required this.core,
    required this.records,
    required this.unknownLevels,
    required this.events,
    required this.goals,
    required this.habitSessionsPerWeek,
    required this.habitWeeks,
    required this.weakPoints,
    required this.injuries,
    required this.recovery,
    required this.breakWeeks,
    required this.priorityExerciseIds,
    required this.maintainExerciseIds,
    required this.simulation,
    required this.expectations,
    required this.checks,
  });

  /// Lit un profil du banc ; [FormatException] si un champ manque ou a un
  /// type inattendu.
  factory BenchProfile.fromJson(Map<String, Object?> json) {
    final schema = benchInt(json, 'schemaVersion');
    if (schema != 1) {
      throw FormatException('profil du banc : schéma non pris en charge');
    }
    final group = benchString(json, 'group');
    if (group != 'street' && group != 'autres') {
      throw FormatException('group : street ou autres attendu', group);
    }
    final recovery = json['recovery'];
    final pause = json['break'];
    final special = json['specialization'];
    final habit = json['habitGoal'];
    final simulation = json['simulation'];
    final expectations = benchObject(json['expectations'], 'expectations');
    return BenchProfile(
      key: benchString(json, 'key'),
      group: group,
      title: benchString(json, 'title'),
      summary: benchString(json, 'summary'),
      level: BenchLevel.fromCode(benchString(json, 'level')),
      trainingAgeMonths: benchInt(json, 'trainingAgeMonths'),
      core: benchObject(json['core'], 'core'),
      records: <BenchRecord>[
        for (final r in benchList(json, 'records'))
          BenchRecord.fromJson(benchObject(r, 'records')),
      ],
      unknownLevels: benchStrings(json, 'unknownLevels'),
      events: <BenchEvent>[
        for (final e in benchList(json, 'events'))
          BenchEvent.fromJson(benchObject(e, 'events')),
      ],
      goals: <BenchGoal>[
        for (final g in benchList(json, 'goals'))
          BenchGoal.fromJson(benchObject(g, 'goals')),
      ],
      habitSessionsPerWeek: habit == null
          ? null
          : benchInt(benchObject(habit, 'habitGoal'), 'sessionsPerWeek'),
      habitWeeks: habit == null
          ? null
          : benchInt(benchObject(habit, 'habitGoal'), 'weeks'),
      weakPoints: <BenchWeakPoint>[
        for (final w in benchList(json, 'weakPoints'))
          BenchWeakPoint.fromJson(benchObject(w, 'weakPoints')),
      ],
      injuries: <BenchInjury>[
        for (final i in benchList(json, 'injuries'))
          BenchInjury.fromJson(benchObject(i, 'injuries')),
      ],
      recovery: BenchRecovery.fromJson(
        recovery == null ? null : benchObject(recovery, 'recovery'),
      ),
      breakWeeks: pause == null
          ? 0
          : benchInt(benchObject(pause, 'break'), 'weeksOff'),
      priorityExerciseIds: special == null
          ? const <String>[]
          : benchStrings(
              benchObject(special, 'specialization'),
              'priorityExerciseIds',
            ),
      maintainExerciseIds: special == null
          ? const <String>[]
          : benchStrings(
              benchObject(special, 'specialization'),
              'maintainExerciseIds',
            ),
      simulation: simulation == null
          ? const <String, Object?>{}
          : benchObject(simulation, 'simulation'),
      expectations: benchStrings(expectations, 'text'),
      checks: <BenchCheck>[
        for (final c in benchList(expectations, 'checks'))
          BenchCheck.fromJson(benchObject(c, 'checks')),
      ],
    );
  }

  /// Clé stable (`street_01_debutant_complet`).
  final String key;

  /// `street` ou `autres`.
  final String group;

  /// Titre lisible.
  final String title;

  /// Portrait en deux ou trois phrases.
  final String summary;

  /// Niveau global.
  final BenchLevel level;

  /// Ancienneté d'entraînement structuré, en mois.
  final int trainingAgeMonths;

  /// Champs du profil `kalis_core` repris tels quels (sexe, année de
  /// naissance, taille, poids, disciplines, mode street, disponibilités,
  /// lieux, matériel, incréments, goûts, expérience, mode, santé).
  final Map<String, Object?> core;

  /// Tests et records exacts.
  final List<BenchRecord> records;

  /// Mouvements dont le niveau est inconnu (« je ne sais pas »).
  final List<String> unknownLevels;

  /// Échéances.
  final List<BenchEvent> events;

  /// Objectifs datés hors échéance.
  final List<BenchGoal> goals;

  /// Objectif d'habitude : séances par semaine.
  final int? habitSessionsPerWeek;

  /// Objectif d'habitude : durée en semaines.
  final int? habitWeeks;

  /// Points faibles.
  final List<BenchWeakPoint> weakPoints;

  /// Blessures et antécédents.
  final List<BenchInjury> injuries;

  /// Récupération et vie.
  final BenchRecovery recovery;

  /// Semaines sans entraînement juste avant le programme (0 : aucune).
  final int breakWeeks;

  /// Spécialisation : mouvements prioritaires.
  final List<String> priorityExerciseIds;

  /// Spécialisation : mouvements à entretenir.
  final List<String> maintainExerciseIds;

  /// Réglages de l'athlète simulé (champs de `AthleteSpec`).
  final Map<String, Object?> simulation;

  /// Attentes de coach, en français.
  final List<String> expectations;

  /// Attentes vérifiables.
  final List<BenchCheck> checks;

  /// Année de naissance.
  int get birthYear => benchInt(core, 'birthYear');

  /// Poids de corps, en kg.
  double? get bodyWeightKg => benchDoubleOrNull(core, 'bodyWeightKg');

  /// Taille, en cm.
  int get heightCm => benchInt(core, 'heightCm');

  /// Indice de masse corporelle, ou `null` sans poids.
  double? get bodyMassIndex {
    final weight = bodyWeightKg;
    if (weight == null) {
      return null;
    }
    final meters = heightCm / 100;
    return weight / (meters * meters);
  }

  /// Échéance prioritaire la plus proche, ou `null`.
  BenchEvent? get mainEvent {
    BenchEvent? best;
    for (final e in events) {
      if (e.priority != 'A') {
        continue;
      }
      if (best == null || e.weeksOut < best.weeksOut) {
        best = e;
      }
    }
    return best;
  }

  /// Mouvements prioritaires : cibles des échéances et des objectifs,
  /// puis mouvements de la spécialisation.
  List<String> get priorityIds {
    final out = <String>[];
    void add(String id) {
      if (!out.contains(id)) {
        out.add(id);
      }
    }

    for (final id in priorityExerciseIds) {
      add(id);
    }
    for (final e in events) {
      for (final t in e.targets) {
        add(t.exerciseId);
      }
    }
    for (final g in goals) {
      add(g.target.exerciseId);
    }
    return out;
  }

  /// Record du mouvement [exerciseId], ou `null`.
  BenchRecord? recordOf(String exerciseId) {
    for (final r in records) {
      if (r.exerciseId == exerciseId) {
        return r;
      }
    }
    return null;
  }
}
