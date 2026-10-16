part of 'contracts.dart';

/// Correspondance entre le mode street et les disciplines du profil.
extension StreetStyleDiscipline on StreetStyle {
  /// Discipline d'entraînement de cette composante du mode street :
  /// « sets & reps » est le street workout en séries et répétitions.
  TrainingDiscipline get discipline {
    switch (this) {
      case StreetStyle.streetlifting:
        return TrainingDiscipline.streetlifting;
      case StreetStyle.setsReps:
        return TrainingDiscipline.streetWorkout;
      case StreetStyle.calisthenics:
        return TrainingDiscipline.calisthenics;
    }
  }
}

/// Lecture du mode street comme un dosage de disciplines.
extension StreetModeMix on StreetMode {
  /// Part de [style], en pour cent.
  int pctOf(StreetStyle style) {
    switch (style) {
      case StreetStyle.streetlifting:
        return streetliftingPct;
      case StreetStyle.setsReps:
        return setsRepsPct;
      case StreetStyle.calisthenics:
        return calisthenicsPct;
    }
  }

  /// Dosage de disciplines équivalent : la principale, puis les deux autres
  /// composantes (dans l'ordre de [StreetStyle]) dont la part est non nulle.
  DisciplineMix toDisciplineMix() {
    return DisciplineMix(
      primary: primary.discipline,
      primaryPct: pctOf(primary),
      secondaries: <DisciplineShare>[
        for (final style in StreetStyle.values)
          if (style != primary && pctOf(style) > 0)
            DisciplineShare(discipline: style.discipline, pct: pctOf(style)),
      ],
    );
  }
}

/// Disciplines de la base couvertes par une discipline du profil.
extension TrainingDisciplineCatalog on TrainingDiscipline {
  /// Disciplines du catalogue où puiser pour cette discipline du profil.
  ///
  /// « Forme générale » n'existe pas dans la base : elle puise dans la
  /// musculation, le street workout, le cardio et la mobilité (choix
  /// raisonné, que `kalis_plan` peut pondérer).
  List<CatalogDiscipline> get catalogDisciplines {
    switch (this) {
      case TrainingDiscipline.musculation:
        return const <CatalogDiscipline>[CatalogDiscipline.musculation];
      case TrainingDiscipline.streetWorkout:
        return const <CatalogDiscipline>[CatalogDiscipline.streetWorkout];
      case TrainingDiscipline.streetlifting:
        return const <CatalogDiscipline>[CatalogDiscipline.streetlifting];
      case TrainingDiscipline.calisthenics:
        return const <CatalogDiscipline>[
          CatalogDiscipline.calisthenicsStatic,
          CatalogDiscipline.calisthenicsDynamic,
        ];
      case TrainingDiscipline.crossfit:
        return const <CatalogDiscipline>[CatalogDiscipline.crossfit];
      case TrainingDiscipline.cardio:
        return const <CatalogDiscipline>[CatalogDiscipline.cardio];
      case TrainingDiscipline.mobility:
        return const <CatalogDiscipline>[CatalogDiscipline.mobility];
      case TrainingDiscipline.generalFitness:
        return const <CatalogDiscipline>[
          CatalogDiscipline.musculation,
          CatalogDiscipline.streetWorkout,
          CatalogDiscipline.cardio,
          CatalogDiscipline.mobility,
        ];
    }
  }
}

/// Articulation suivie désignée par une zone du corps.
extension BodyZoneJoint on BodyZone {
  /// Articulation des contraintes articulaires du catalogue que cette zone
  /// désigne, ou `null` (cou, dos haut, poitrine, abdomen, cuisse, jambe).
  Joint? get joint {
    switch (this) {
      case BodyZone.shoulder:
        return Joint.shoulder;
      case BodyZone.elbow:
        return Joint.elbow;
      case BodyZone.wristHand:
        return Joint.wrist;
      case BodyZone.lowerBack:
        return Joint.lumbar;
      case BodyZone.hip:
        return Joint.hip;
      case BodyZone.knee:
        return Joint.knee;
      case BodyZone.ankleFoot:
        return Joint.ankle;
      case BodyZone.neck:
      case BodyZone.upperBack:
      case BodyZone.chest:
      case BodyZone.abdomen:
      case BodyZone.thigh:
      case BodyZone.lowerLeg:
        return null;
    }
  }
}

/// Lecture du journal par les moteurs.
extension TrainingLogView on TrainingLog {
  /// Séances que les moteurs prennent en compte : toutes sauf les séances
  /// « reprise » (D4.9 : neutres — ni XP, ni statistiques, ni série, ni
  /// records, ni données pour les moteurs).
  Iterable<SessionRecord> get countedSessions =>
      sessions.where((s) => !s.resume);
}

/// Lecture d'une série par les moteurs.
extension SetRecordView on SetRecord {
  /// Vrai si la série porte une note de difficulté. « Pas de note » n'est
  /// jamais remplacé par une valeur.
  bool get isRated => flames != null;

  /// Vrai si les moteurs peuvent utiliser cette série.
  bool get isUsable => !excluded;
}

/// Schéma du profil d'athlète (0.4.0) : le schéma 3 ajoute au schéma 2 des
/// champs tous optionnels. Passer de 2 à 3 ne change que le numéro de
/// schéma : rien n'est perdu, rien n'est inventé (une réponse absente reste
/// absente, D5.8).
extension AthleteProfileSchema on AthleteProfile {
  /// Vrai si le profil est au schéma 3 ou plus.
  bool get isSchema3 => schemaVersion >= 3;

  /// Noms des champs du schéma 3 renseignés (liste vide pour un profil qui
  /// ne porte que des réponses du schéma 2).
  List<String> get schema3FieldsPresent {
    return <String>[
      if (trainingAge != null) 'trainingAge',
      if (trainingGap != null) 'trainingGap',
      if (sleep != null) 'sleep',
      if (stress != null) 'stress',
      if (occupationalLoad != null) 'occupationalLoad',
      if (otherSports != null) 'otherSports',
      if (bodyWeightGoal != null) 'bodyWeightGoal',
      if (benchmarks != null) 'benchmarks',
      if (events != null) 'events',
      if (skills != null) 'skills',
      if (weakPoints != null) 'weakPoints',
      if (specialization != null) 'specialization',
      if (recentTraining != null) 'recentTraining',
      if (currentPhase != null) 'currentPhase',
      if (emphasis != null) 'emphasis',
      if (enduranceBase != null) 'enduranceBase',
      if (targetBodyWeightKg != null) 'targetBodyWeightKg',
      if (lifestyleUpdatedOn != null) 'lifestyleUpdatedOn',
      if (limitations.any(
        (l) =>
            l.since != null ||
            l.aggravatedBy != null ||
            l.effortDiscomfort != null,
      ))
        'limitations',
    ];
  }

  /// Le même profil au schéma 3. Un profil déjà au schéma 3 est rendu tel
  /// quel ; un profil au schéma 2 garde tous ses champs à l'identique et
  /// tous les champs du schéma 3 absents.
  AthleteProfile toSchema3() {
    return isSchema3 ? this : copyWith(schemaVersion: 3);
  }
}

/// Migration du JSON d'un profil d'athlète vers le schéma 3 (0.4.0), sans
/// passer par les types : seule la clé `schemaVersion` change ; toutes les
/// autres clés, connues ou non, sont recopiées telles quelles et dans le
/// même ordre. [FormatException] si `schemaVersion` manque, n'est pas un
/// entier, ou désigne un schéma antérieur au schéma 2 ou postérieur au
/// schéma 3.
Map<String, Object?> migrateAthleteProfileJsonToSchema3(
  Map<String, Object?> json,
) {
  final version = json['schemaVersion'];
  if (version is! int || version < 2 || version > 3) {
    throw FormatException(
      'Profil : schéma 2 ou 3 attendu',
      version?.toString(),
    );
  }
  return <String, Object?>{
    for (final entry in json.entries)
      entry.key: entry.key == 'schemaVersion' ? 3 : entry.value,
  };
}
