/// Paramètres chiffrés de `kalis_quest`. Chaque valeur est justifiée dans
/// `CONTRAT.md` (§ Paramètres) : mesure de la simulation de rythme,
/// référence citée, ou choix raisonné dit comme tel.
library;

/// Paramètres du moteur de progression.
final class QuestParams {
  /// Paramètres ; les valeurs par défaut sont celles de la livraison.
  const QuestParams({
    this.levelScale = 32,
    this.sessionXp = 100,
    this.comboMin = 3,
    this.comboBonusCap = 10,
    this.unratedQuality = 0.7,
    this.qualityStep = 0.125,
    this.qualityFloor = 0.5,
    this.targetTolerance = 1,
    this.lightFloor = 0.5,
    this.doneCompletion = 0.5,
    this.weekXp = 60,
    this.restXp = 40,
    this.streakNumerator = 3,
    this.streakDenominator = 4,
    this.streakMilestones = const <int>[4, 8, 12, 26, 52, 78, 104, 156],
    this.streakMilestoneXp = const <int>[50, 80, 120, 200, 400, 400, 400, 400],
    this.streakMilestoneKredits = const <int>[
      10,
      15,
      25,
      50,
      100,
      100,
      100,
      100,
    ],
    this.flameSizeWeeks = const <int>[1, 2, 3, 4, 6, 8, 12, 16, 26, 52],
    this.recordXpBase = 10,
    this.recordXpPerPct = 4,
    this.recordXpMax = 30,
    this.recordXpSessionCap = 40,
    this.recordMinGain = 0.005,
    this.recordKredits = 3,
    this.firstTimeEventsPerSession = 3,
    this.milestoneXp = const <int>[30, 30, 30, 100],
    this.milestoneKredits = const <int>[5, 5, 5, 25],
    this.milestoneWeekCapXp = 200,
    this.goalFullGap = 0.10,
    this.goalMinAmbition = 0.2,
    this.goalMinDays = 14,
    this.habitFullWeeks = 8,
    this.dailyXp = 10,
    this.dailyKredits = 2,
    this.restQuestXp = 5,
    this.restQuestKredits = 1,
    this.weeklyQuestXp = 40,
    this.weeklyQuestKredits = 10,
    this.koachQuestXp = 30,
    this.koachQuestKredits = 10,
    this.chapterXp = 100,
    this.chapterKredits = 40,
    this.bossXp = 60,
    this.bossKredits = 25,
    this.chapterShare = 0.75,
    this.bossCompletion = 0.8,
    this.campaignGraceDays = 7,
    this.questRetentionDays = 35,
    this.inTargetShare = 0.6,
    this.inTargetMin = 3,
    this.defaultTypicalSets = 8,
    this.restMobilitySeconds = 300,
    this.koachMobilitySeconds = 600,
    this.weeklyMobilityDays = 2,
    this.mobilityDaySeconds = 60,
    this.mobilityRepSeconds = 3,
    this.weekdayFocusShare = 0.6,
    this.persistentPainSessions = 3,
    this.levelKredits = 5,
    this.levelDecadeKredits = 20,
    this.prestigeKredits = 200,
    this.chestProbability = 0.15,
    this.chestPity = 8,
    this.chestWeekCap = 2,
    this.chestKredits = const <int>[10, 20, 50, 100],
    this.chestShares = const <double>[0.60, 0.30, 0.09, 0.01],
    this.gradeCompletionWeight = 60,
    this.gradeAccuracyWeight = 30,
    this.gradeRecordWeight = 10,
    this.gradeS = 90,
    this.gradeA = 70,
    this.gradeB = 50,
    this.startBonusPerSession = 0,
    this.startBonusCap = 0,
    this.startBonusDays = 28,
    this.retentionFloor = 0.7,
    this.accuracyWindowDays = 56,
    this.accuracyMinSets = 20,
    this.mobilityWindowDays = 28,
    this.mobilityDaysPerWeek = 3,
    this.mobilitySecondsPerWeek = 1800,
    this.cardioWindowDays = 28,
    this.cardioSecondsPerWeek = 9000,
    this.explosiveWindowDays = 56,
    this.explosiveSetsPerWeek = 10,
    this.consistencyWeeks = 12,
    this.skillHoldSeconds = 2,
    this.skillMinReps = 3,
    this.runMinMeters = 1500,
    this.runMaxMeters = 45000,
    this.riegelExponent = 1.06,
    this.predictionHorizonWeeks = 156,
    this.trendCv = 0.2,
    this.trendSdFloorWeeks = 26,
    this.seriesWindowWeeks = 12,
    this.seriesMinPoints = 3,
    this.seriesSdFloor = 0.01,
    this.suggestHorizonDays = 56,
    this.suggestProbability = 0.6,
    this.suggestMinObservations = 12,
    this.suggestMax = 2,
    this.ghostWindowDays = 90,
    this.ghostMaxExercises = 60,
    this.recapTopRecords = 5,
    this.comparisonDays = const <int>[30, 91, 365],
    this.comparisonWindowDays = 28,
  });

  /// Paramètres de la livraison.
  static const QuestParams standard = QuestParams();

  // ---------------------------------------------------------------- niveaux

  /// Échelle de la courbe des niveaux : passer du niveau `n` au suivant
  /// coûte `5 × arrondi(levelScale × n^0,875 / 5)` XP.
  final double levelScale;

  // ----------------------------------------------------------------- effort

  /// XP d'une séance prévue faite en entier, aux flammes visées.
  final int sessionXp;

  /// Longueur à partir de laquelle un combo compte.
  final int comboMin;

  /// Bonus d'XP maximal d'un combo (1 XP par série du combo).
  final int comboBonusCap;

  /// Qualité d'une série de travail sans note quand une cible de flammes
  /// existe.
  final double unratedQuality;

  /// Qualité perdue par flamme au-delà de la tolérance, sous la cible.
  final double qualityStep;

  /// Plancher de la qualité d'une série.
  final double qualityFloor;

  /// Tolérance autour des flammes visées, en flammes.
  final int targetTolerance;

  /// Séance terminée sans `plannedWorkSets` : part du volume du bloc
  /// au-dessus de laquelle elle compte comme complète (séance allégée).
  final double lightFloor;

  /// Réalisation minimale pour qu'une séance compte comme faite
  /// (régularité, série de semaines, quêtes).
  final double doneCompletion;

  // -------------------------------------------------------------- régularité

  /// XP hebdomadaire des séances prévues faites (réalisation complète).
  final int weekXp;

  /// XP hebdomadaire des jours de repos respectés.
  final int restXp;

  /// Semaine réussie : `faites × streakDenominator ≥ prévues ×
  /// streakNumerator` (3/4).
  final int streakNumerator;

  /// Voir [streakNumerator].
  final int streakDenominator;

  /// Longueurs de série récompensées d'un jalon.
  final List<int> streakMilestones;

  /// XP des jalons de série.
  final List<int> streakMilestoneXp;

  /// Krédits des jalons de série.
  final List<int> streakMilestoneKredits;

  /// Longueurs de série à partir desquelles la flamme prend la taille 1,
  /// 2, … 10.
  final List<int> flameSizeWeeks;

  // ----------------------------------------------------------------- records

  /// XP de base d'un record.
  final int recordXpBase;

  /// XP par pour cent de gain d'un record.
  final int recordXpPerPct;

  /// XP maximal d'un record.
  final int recordXpMax;

  /// XP de records maximal par séance.
  final int recordXpSessionCap;

  /// Gain relatif minimal pour qu'un record rapporte de l'XP.
  final double recordMinGain;

  /// Krédits du premier record payé d'une séance.
  final int recordKredits;

  /// Événements « première fois » au plus par séance.
  final int firstTimeEventsPerSession;

  // --------------------------------------------------------------- objectifs

  /// XP des quatre jalons d'un objectif pleinement ambitieux.
  final List<int> milestoneXp;

  /// Krédits des quatre jalons.
  final List<int> milestoneKredits;

  /// XP de jalons maximal par semaine civile.
  final int milestoneWeekCapXp;

  /// Écart relatif entre départ et cible qui vaut un objectif pleinement
  /// ambitieux.
  final double goalFullGap;

  /// Ambition minimale (part de l'XP) d'un objectif payé.
  final double goalMinAmbition;

  /// Durée minimale d'un objectif de performance pour que ses jalons
  /// rapportent de l'XP, en jours.
  final int goalMinDays;

  /// Durée d'un objectif d'habitude pleinement ambitieux, en semaines.
  final int habitFullWeeks;

  // ------------------------------------------------------------------ quêtes

  /// XP d'une quête du jour (jour d'entraînement).
  final int dailyXp;

  /// Krédits d'une quête du jour.
  final int dailyKredits;

  /// XP d'une quête de récupération (jour de repos).
  final int restQuestXp;

  /// Krédits d'une quête de récupération.
  final int restQuestKredits;

  /// XP d'une quête hebdomadaire.
  final int weeklyQuestXp;

  /// Krédits d'une quête hebdomadaire.
  final int weeklyQuestKredits;

  /// XP d'une quête Koach.
  final int koachQuestXp;

  /// Krédits d'une quête Koach.
  final int koachQuestKredits;

  /// XP d'un chapitre de campagne.
  final int chapterXp;

  /// Krédits d'un chapitre de campagne.
  final int chapterKredits;

  /// XP d'un boss de campagne.
  final int bossXp;

  /// Krédits d'un boss de campagne.
  final int bossKredits;

  /// Part des séances du bloc à faire pour terminer le chapitre.
  final double chapterShare;

  /// Réalisation minimale de la séance de boss.
  final double bossCompletion;

  /// Jours de grâce après la fin du bloc pour finir la campagne.
  final int campaignGraceDays;

  /// Jours pendant lesquels une quête finie reste dans l'état.
  final int questRetentionDays;

  /// Part des séries habituelles demandée par la quête « dans la cible ».
  final double inTargetShare;

  /// Plancher de la quête « dans la cible », en séries.
  final int inTargetMin;

  /// Séries par séance supposées avant toute donnée.
  final int defaultTypicalSets;

  /// Durée de la mobilité légère d'un jour de repos, en secondes.
  final int restMobilitySeconds;

  /// Durée de mobilité de la quête Koach, en secondes par semaine.
  final int koachMobilitySeconds;

  /// Jours de mobilité de la quête hebdomadaire.
  final int weeklyMobilityDays;

  /// Durée minimale pour qu'un jour compte comme jour de mobilité, en
  /// secondes.
  final int mobilityDaySeconds;

  /// Durée comptée par répétition d'un exercice de mobilité, en secondes.
  final int mobilityRepSeconds;

  /// Part de semaines sous laquelle un jour de la semaine est proposé par
  /// Koach.
  final double weekdayFocusShare;

  /// Séances de suite au-dessus du seuil de douleur à partir desquelles les
  /// quêtes de performance ne sont plus proposées (règle santé L13).
  final int persistentPainSessions;

  // ----------------------------------------------------------------- Krédits

  /// Krédits par niveau gagné.
  final int levelKredits;

  /// Krédits supplémentaires à chaque dizaine de niveaux.
  final int levelDecadeKredits;

  /// Krédits d'un passage de prestige.
  final int prestigeKredits;

  // ----------------------------------------------------------------- coffres

  /// Probabilité d'un coffre par séance récompensée.
  final double chestProbability;

  /// Garantie : un coffre à la séance de ce rang depuis le dernier coffre.
  final int chestPity;

  /// Coffres au plus par semaine civile.
  final int chestWeekCap;

  /// Contenus possibles, en Krédits.
  final List<int> chestKredits;

  /// Probabilité de chaque contenu.
  final List<double> chestShares;

  // -------------------------------------------------------------------- note

  /// Poids de la réalisation dans la note de séance.
  final int gradeCompletionWeight;

  /// Poids de la justesse des flammes.
  final int gradeAccuracyWeight;

  /// Poids des records.
  final int gradeRecordWeight;

  /// Seuil de la note S.
  final int gradeS;

  /// Seuil de la note A.
  final int gradeA;

  /// Seuil de la note B.
  final int gradeB;

  // ------------------------------------------------------------------ départ

  /// Bonus de départ par séance des [startBonusDays] derniers jours
  /// (0 : aucun bonus, décision du lot G11).
  final int startBonusPerSession;

  /// Plafond du bonus de départ.
  final int startBonusCap;

  /// Fenêtre du bonus de départ, en jours.
  final int startBonusDays;

  // --------------------------------------------------------------- attributs

  /// Plancher de la rétention d'une performance ancienne.
  final double retentionFloor;

  /// Fenêtre de la justesse des flammes, en jours.
  final int accuracyWindowDays;

  /// Séries notées en dessous desquelles la justesse est pondérée.
  final int accuracyMinSets;

  /// Fenêtre du travail de mobilité, en jours.
  final int mobilityWindowDays;

  /// Jours de mobilité par semaine valant le maximum.
  final int mobilityDaysPerWeek;

  /// Secondes de mobilité par semaine valant le maximum.
  final int mobilitySecondsPerWeek;

  /// Fenêtre du travail cardio, en jours.
  final int cardioWindowDays;

  /// Secondes de cardio par semaine valant le maximum (150 minutes).
  final int cardioSecondsPerWeek;

  /// Fenêtre du travail explosif, en jours.
  final int explosiveWindowDays;

  /// Séries explosives par semaine valant le maximum.
  final int explosiveSetsPerWeek;

  /// Semaines closes lues par l'attribut Régularité.
  final int consistencyWeeks;

  /// Tenue minimale pour qu'une figure compte, en secondes.
  final int skillHoldSeconds;

  /// Répétitions minimales pour qu'une figure dynamique compte comme
  /// maîtrisée.
  final int skillMinReps;

  // ------------------------------------------------------------------ course

  /// Distance minimale d'une série de course lue comme performance, en
  /// mètres.
  final double runMinMeters;

  /// Distance maximale, en mètres.
  final double runMaxMeters;

  /// Exposant de la formule de Riegel.
  final double riegelExponent;

  // ------------------------------------------------------------- prédictions

  /// Horizon maximal d'une prédiction, en semaines.
  final int predictionHorizonWeeks;

  /// Coefficient de variation supposé de la tendance.
  final double trendCv;

  /// Plancher de l'écart-type de la tendance : l'erreur de niveau répartie
  /// sur ce nombre de semaines.
  final int trendSdFloorWeeks;

  /// Fenêtre de la tendance lue dans le journal, en semaines.
  final int seriesWindowWeeks;

  /// Points hebdomadaires minimaux pour une tendance lue dans le journal.
  final int seriesMinPoints;

  /// Plancher de l'erreur de niveau lue dans le journal (part de la
  /// valeur).
  final double seriesSdFloor;

  /// Échéance d'un objectif suggéré, en jours.
  final int suggestHorizonDays;

  /// Probabilité d'atteinte visée d'un objectif suggéré.
  final double suggestProbability;

  /// Séries observées minimales pour suggérer un objectif.
  final int suggestMinObservations;

  /// Objectifs suggérés au plus.
  final int suggestMax;

  // ---------------------------------------------------------------- présentation

  /// Ancienneté maximale d'une séance fantôme, en jours.
  final int ghostWindowDays;

  /// Exercices au plus dans le fantôme.
  final int ghostMaxExercises;

  /// Records cités au plus dans le récapitulatif.
  final int recapTopRecords;

  /// Reculs des comparaisons dans le temps, en jours (1 mois, 3 mois,
  /// 1 an).
  final List<int> comparisonDays;

  /// Largeur de la fenêtre comparée, en jours.
  final int comparisonWindowDays;
}
