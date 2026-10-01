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
