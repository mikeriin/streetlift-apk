/// Paramètres chiffrés de `kalis_plan`. Chaque valeur est justifiée dans
/// `CONTRAT.md` (§ Paramètres) par une référence citée, une mesure
/// (`docs/`), ou dite « choix raisonné ».
library;

/// Poids des composantes de la note d'un programme (D4.2).
///
/// La note de sécurité (récupération, fatigue, articulations) passe avant
/// la note de qualité (priorité lexicographique par paliers de
/// [PlanParams.safetyStep]) ; à palier égal, la note globale départage.
final class ScoreWeights {
  /// Poids par défaut.
  const ScoreWeights({
    this.recovery = 0.6,
    this.fatigueBalance = 0.2,
    this.jointLoad = 0.2,
    this.goalSpecificity = 0.15,
    this.disciplineDosage = 0.13,
    this.muscleVolume = 0.13,
    this.patternBalance = 0.11,
    this.disciplineStructure = 0.10,
    this.timeUse = 0.10,
    this.variety = 0.08,
    this.exerciseFit = 0.06,
    this.stimulusFatigue = 0.05,
    this.preferences = 0.05,
    this.novelty = 0.04,
  });

  /// Sécurité : même muscle sollicité lourdement à moins de 48 h.
  final double recovery;

  /// Sécurité : fatigue systémique répartie sur la semaine.
  final double fatigueBalance;

  /// Sécurité : contrainte restante sur les articulations limitées.
  final double jointLoad;

  /// Qualité : objectifs du profil et mouvements propres à la discipline.
  final double goalSpecificity;

  /// Qualité : part du temps par discipline proche du dosage demandé.
  final double disciplineDosage;

  /// Qualité : volume hebdomadaire par muscle dans sa bande.
  final double muscleVolume;

  /// Qualité : équilibre des schémas (tirage / poussée, chaîne postérieure,
  /// gainage, couverture).
  final double patternBalance;

  /// Qualité : exercices propres à la discipline et structure qu'elle
  /// demande (pratique fréquente des figures, pièce de conditionnement,
  /// répartition facile / intense du cardio, régions de mobilité).
  final double disciplineStructure;

  /// Qualité : temps disponible utilisé.
  final double timeUse;

  /// Qualité : pas de redondance dans une séance ni dans la semaine.
  final double variety;

  /// Qualité : exercices adaptés (mouvement de base de sa famille, ni trop
  /// facile ni assisté sans besoin).
  final double exerciseFit;

  /// Qualité : rapport stimulus / fatigue des exercices.
  final double stimulusFatigue;

  /// Qualité : exercices aimés présents.
  final double preferences;

  /// Qualité : nombre raisonnable de nouveautés techniques.
  final double novelty;

  /// Somme des poids de sécurité.
  double get safetySum => recovery + fatigueBalance + jointLoad;

  /// Somme des poids de qualité.
  double get qualitySum =>
      goalSpecificity +
      disciplineDosage +
      muscleVolume +
      patternBalance +
      disciplineStructure +
      timeUse +
      variety +
      exerciseFit +
      stimulusFatigue +
      preferences +
      novelty;

  /// Codes des composantes, dans l'ordre de [values].
  static const List<String> codes = <String>[
    'recovery',
    'fatigue_balance',
    'joint_load',
    'goal_specificity',
    'discipline_dosage',
    'muscle_volume',
    'pattern_balance',
    'discipline_structure',
    'time_use',
    'variety',
    'exercise_fit',
    'stimulus_fatigue',
    'preferences',
    'novelty',
  ];

  /// Nombre de composantes de sécurité (les premières de [codes]).
  static const int safetyCount = 3;

  /// Poids, dans l'ordre de [codes].
  List<double> get values => <double>[
    recovery,
    fatigueBalance,
    jointLoad,
    goalSpecificity,
    disciplineDosage,
    muscleVolume,
    patternBalance,
    disciplineStructure,
    timeUse,
    variety,
    exerciseFit,
    stimulusFatigue,
    preferences,
    novelty,
  ];

  /// Copie où le poids de la composante [code] est multiplié par [factor]
  /// (analyse de sensibilité). Les poids ne sont pas renormalisés : la note
  /// divise toujours par leur somme.
  ScoreWeights scaled(String code, double factor) {
    final v = values;
    final at = codes.indexOf(code);
    if (at < 0) {
      throw ArgumentError.value(code, 'code', 'composante inconnue');
    }
    v[at] = v[at] * factor;
    return ScoreWeights(
      recovery: v[0],
      fatigueBalance: v[1],
      jointLoad: v[2],
      goalSpecificity: v[3],
      disciplineDosage: v[4],
      muscleVolume: v[5],
      patternBalance: v[6],
      disciplineStructure: v[7],
      timeUse: v[8],
      variety: v[9],
      exerciseFit: v[10],
      stimulusFatigue: v[11],
      preferences: v[12],
      novelty: v[13],
    );
  }
}

/// Paramètres du moteur. [PlanParams.standard] est le réglage livré ; les
/// autres réglages ne servent qu'aux mesures (`docs/SENSIBILITE.md`).
final class PlanParams {
  /// Réglage par défaut.
  const PlanParams({
    this.weights = const ScoreWeights(),
    this.safetyStep = 0.05,
    this.safetyShare = 0.3,
    this.safetyPriority = 1.0,
    this.changePenalty = 0.01,
    this.alternativeTolerance = 0.03,
    this.alternativeMinDistance = 1 / 3,
    this.alternativeHistory = 8,
    this.annealIterations = 1500,
    this.reviewIterations = 500,
    this.alternativeIterations = 1500,
    this.annealStartTemperature = 0.02,
    this.annealEndTemperature = 0.0004,
    this.shortlistPerClass = 6,
    this.lookaheadWidth = 3,
    this.neighbourCount = 12,
    this.maxSlotsPerDay = 12,
    this.minutesPerWorkSlot = 8,
    this.maxWorkSlotsPerDay = 8,
    this.timeUseTarget = 0.85,
    this.secondsPerRep = 3,
    this.transitionSeconds = 45,
    this.recoveryHours = 48,
    this.heavyPrimarySets = 2,
    this.pullToPushRatio = 1.0,
    this.hipToKneeRatio = 0.75,
    this.goalExposures = 2.0,
    this.skillPracticeDays = 3,
    this.cardioHardShare = 0.2,
    this.creditsPerMinute = 0.9,
    this.startLoadFraction = 0.9,
    this.startLoadFractionEstimated = 0.95,
    this.epleyDivisor = 30,
    this.maxEpleyReps = 15,
    this.rotationShare = 0.4,
    this.variantMinSimilarity = 0.45,
    this.generalFitnessResistancePct = 50,
    this.generalFitnessCardioPct = 35,
    this.generalFitnessMobilityPct = 15,
    this.seniorAge = 65,
    this.adultAge = 18,
    this.hardJointDiscomfort = 4,
    this.severeJointDiscomfort = 7,
  });

  /// Réglage livré.
  static const PlanParams standard = PlanParams();

  /// Poids des composantes de la note.
  final ScoreWeights weights;

  /// Largeur d'un palier de sécurité (priorité lexicographique).
  final double safetyStep;

  /// Part de la note de sécurité dans la note globale affichée.
  final double safetyShare;

  /// Poids ajouté à la note de sécurité dans l'objectif de la recherche
  /// (en plus de sa part dans la note globale) : la sécurité y pèse
  /// `(safetyShare + safetyPriority) / (1 − safetyShare)` fois la qualité.
  final double safetyPriority;

  /// Pénalité par emplacement modifié lors d'une régénération (D4.6).
  final double changePenalty;

  /// « Autre proposition » : écart de note toléré avec la meilleure (3 %).
  final double alternativeTolerance;

  /// « Autre proposition » : part minimale d'exercices non verrouillés
  /// différents de chaque proposition déjà montrée (un tiers).
  final double alternativeMinDistance;

  /// « Autre proposition » : nombre de propositions précédentes comparées.
  final int alternativeHistory;

  /// Itérations du recuit simulé à la création.
  final int annealIterations;

  /// Itérations du recuit après une action de revue.
  final int reviewIterations;

  /// Itérations du recuit pour une autre proposition.
  final int alternativeIterations;

  /// Température initiale du recuit (en points de note).
  final double annealStartTemperature;

  /// Température finale du recuit.
  final double annealEndTemperature;

  /// Candidats retenus par classe de discipline à chaque pas glouton.
  final int shortlistPerClass;

  /// Nombre de meilleurs ajouts examinés un coup plus loin (anticipation).
  final int lookaheadWidth;

  /// Voisins d'un exercice examinés par la recherche locale.
  final int neighbourCount;

  /// Nombre maximal d'exercices par séance.
  final int maxSlotsPerDay;

  /// Minutes par exercice hors mobilité : borne le nombre d'exercices
  /// d'une séance (`minutes / minutesPerWorkSlot + 1`).
  final int minutesPerWorkSlot;

  /// Nombre maximal d'exercices hors mobilité par séance.
  final int maxWorkSlotsPerDay;

  /// Part du temps disponible à partir de laquelle une séance est pleine.
  final double timeUseTarget;

  /// Durée d'une répétition, en secondes (hypothèse d'estimation).
  final int secondsPerRep;

  /// Temps de transition entre deux exercices, en secondes.
  final int transitionSeconds;

  /// Délai minimal entre deux sollicitations lourdes d'un même muscle.
  final int recoveryHours;

  /// Nombre de séries directes à partir duquel un muscle est « sollicité
  /// lourdement » dans une séance.
  final int heavyPrimarySets;

  /// Rapport visé séries de tirage / séries de poussée.
  final double pullToPushRatio;

  /// Rapport visé séries de chaîne postérieure / séries à dominante genou.
  final double hipToKneeRatio;

  /// Expositions hebdomadaires visées pour un objectif de performance.
  final double goalExposures;

  /// Jours de pratique visés par semaine pour une figure travaillée.
  final int skillPracticeDays;

  /// Part visée des séances de cardio à haute intensité.
  final double cardioHardShare;

  /// Séries fractionnaires créditées par minute de renforcement (mesuré,
  /// `docs/VALIDATION.md`) : sert à réduire les bandes de volume quand le
  /// temps disponible ne permet pas de les atteindre.
  final double creditsPerMinute;

  /// Facteur de prudence d'une charge de départ déduite d'un niveau
  /// déclaré.
  final double startLoadFraction;

  /// Facteur de prudence d'une charge déduite d'une capacité estimée par
  /// le moteur dynamique.
  final double startLoadFractionEstimated;

  /// Diviseur de la formule d'Epley (1RM = charge × (1 + répétitions / 30)).
  final int epleyDivisor;

  /// Répétitions au-delà desquelles la formule d'Epley n'est plus employée.
  final int maxEpleyReps;

  /// Part des exercices d'assistance renouvelés au bloc suivant.
  final double rotationShare;

  /// Proximité minimale d'une variante « compatible ».
  final double variantMinSimilarity;

  /// Forme générale : part de renforcement, en pour cent.
  final int generalFitnessResistancePct;

  /// Forme générale : part de cardio, en pour cent.
  final int generalFitnessCardioPct;

  /// Forme générale : part de mobilité, en pour cent.
  final int generalFitnessMobilityPct;

  /// Âge à partir duquel le programme est prudent.
  final int seniorAge;

  /// Âge de la majorité (en dessous, programme prudent).
  final int adultAge;

  /// Gêne à partir de laquelle une contrainte forte est interdite.
  final int hardJointDiscomfort;

  /// Gêne à partir de laquelle une contrainte moyenne est interdite.
  final int severeJointDiscomfort;

  /// Copie avec d'autres poids (analyse de sensibilité).
  PlanParams withWeights(ScoreWeights weights) {
    return PlanParams(
      weights: weights,
      safetyStep: safetyStep,
      safetyShare: safetyShare,
      safetyPriority: safetyPriority,
      changePenalty: changePenalty,
      alternativeTolerance: alternativeTolerance,
      alternativeMinDistance: alternativeMinDistance,
      alternativeHistory: alternativeHistory,
      annealIterations: annealIterations,
      reviewIterations: reviewIterations,
      alternativeIterations: alternativeIterations,
      annealStartTemperature: annealStartTemperature,
      annealEndTemperature: annealEndTemperature,
      shortlistPerClass: shortlistPerClass,
      lookaheadWidth: lookaheadWidth,
      neighbourCount: neighbourCount,
      maxSlotsPerDay: maxSlotsPerDay,
      minutesPerWorkSlot: minutesPerWorkSlot,
      maxWorkSlotsPerDay: maxWorkSlotsPerDay,
      timeUseTarget: timeUseTarget,
      secondsPerRep: secondsPerRep,
      transitionSeconds: transitionSeconds,
      recoveryHours: recoveryHours,
      heavyPrimarySets: heavyPrimarySets,
      pullToPushRatio: pullToPushRatio,
      hipToKneeRatio: hipToKneeRatio,
      goalExposures: goalExposures,
      skillPracticeDays: skillPracticeDays,
      cardioHardShare: cardioHardShare,
      creditsPerMinute: creditsPerMinute,
      startLoadFraction: startLoadFraction,
      startLoadFractionEstimated: startLoadFractionEstimated,
      epleyDivisor: epleyDivisor,
      maxEpleyReps: maxEpleyReps,
      rotationShare: rotationShare,
      variantMinSimilarity: variantMinSimilarity,
      generalFitnessResistancePct: generalFitnessResistancePct,
      generalFitnessCardioPct: generalFitnessCardioPct,
      generalFitnessMobilityPct: generalFitnessMobilityPct,
      seniorAge: seniorAge,
      adultAge: adultAge,
      hardJointDiscomfort: hardJointDiscomfort,
      severeJointDiscomfort: severeJointDiscomfort,
    );
  }

  /// Copie avec un autre effort de recherche (mesures de convergence).
  PlanParams withSearchEffort(double factor) {
    return PlanParams(
      weights: weights,
      safetyStep: safetyStep,
      safetyShare: safetyShare,
      safetyPriority: safetyPriority,
      changePenalty: changePenalty,
      alternativeTolerance: alternativeTolerance,
      alternativeMinDistance: alternativeMinDistance,
      alternativeHistory: alternativeHistory,
      annealIterations: (annealIterations * factor).round(),
      reviewIterations: (reviewIterations * factor).round(),
      alternativeIterations: (alternativeIterations * factor).round(),
      annealStartTemperature: annealStartTemperature,
      annealEndTemperature: annealEndTemperature,
      shortlistPerClass: shortlistPerClass,
      lookaheadWidth: lookaheadWidth,
      neighbourCount: neighbourCount,
      maxSlotsPerDay: maxSlotsPerDay,
      minutesPerWorkSlot: minutesPerWorkSlot,
      maxWorkSlotsPerDay: maxWorkSlotsPerDay,
      timeUseTarget: timeUseTarget,
      secondsPerRep: secondsPerRep,
      transitionSeconds: transitionSeconds,
      recoveryHours: recoveryHours,
      heavyPrimarySets: heavyPrimarySets,
      pullToPushRatio: pullToPushRatio,
      hipToKneeRatio: hipToKneeRatio,
      goalExposures: goalExposures,
      skillPracticeDays: skillPracticeDays,
      cardioHardShare: cardioHardShare,
      creditsPerMinute: creditsPerMinute,
      startLoadFraction: startLoadFraction,
      startLoadFractionEstimated: startLoadFractionEstimated,
      epleyDivisor: epleyDivisor,
      maxEpleyReps: maxEpleyReps,
      rotationShare: rotationShare,
      variantMinSimilarity: variantMinSimilarity,
      generalFitnessResistancePct: generalFitnessResistancePct,
      generalFitnessCardioPct: generalFitnessCardioPct,
      generalFitnessMobilityPct: generalFitnessMobilityPct,
      seniorAge: seniorAge,
      adultAge: adultAge,
      hardJointDiscomfort: hardJointDiscomfort,
      severeJointDiscomfort: severeJointDiscomfort,
    );
  }
}
