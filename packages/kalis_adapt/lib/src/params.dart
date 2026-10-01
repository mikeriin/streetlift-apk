/// Paramètres chiffrés du moteur dynamique. Chaque valeur est justifiée
/// dans `CONTRAT.md`, § Paramètres : référence citée, mesure de simulation,
/// ou « hypothèse » dite comme telle.
library;

/// Paramètres du modèle et des décisions de `kalis_adapt`.
final class AdaptParams {
  /// Réglage par défaut.
  const AdaptParams({
    this.kGeneral = 30,
    this.kLowerBody = 38,
    this.kLogSd = 0.30,
    this.kMin = 12,
    this.kMax = 80,
    this.kLearnMaxFatigue = 0.02,
    this.levelNoise = 0.004,
    this.trendNoise = 0.0015,
    this.trendDamping = 0.97,
    this.daySd = 0.035,
    this.dayCommonShare = 0.5,
    this.observationFloor = 0.01,
    this.rirSdBase = 0.6,
    this.rirSdPerRir = 0.35,
    this.rirSdRepsFrom = 12,
    this.rirSdRepsGain = 0.05,
    this.failExtraReps = 0.5,
    this.failSd = 0.5,
    this.completedSd = 0.5,
    this.openRir = 5,
    this.huber = 2,
    this.rirBias = 0.2,
    this.lazyWindow = 40,
    this.lazyMinSets = 12,
    this.lazyConfirmRate = 0.6,
    this.lazyMinWeight = 0.1,
    this.setFatigueAtFailure = 0.9,
    this.setFatigueRestTau = 150,
    this.setFatigueRirScale = 1.5,
    this.setFatigueRecovery = 0.5,
    this.fatigueRelSd = 0.5,
    this.defaultRestSeconds = 120,
    this.priorSdDeclared = 0.10,
    this.priorSdPlan = 0.15,
    this.priorSdFirstSet = 0.5,
    this.priorSdNeighbour = 0.25,
    this.trendPrior = const <double>[0.010, 0.004, 0.0015, 0.0005],
    this.trendPriorSd = const <double>[0.010, 0.005, 0.003, 0.002],
    this.holdReserveShare = 0.1,
    this.holdSdBase = 0.10,
    this.holdSdPerRir = 0.05,
    this.quantileBase = 0.6,
    this.quantilePerRir = 0.25,
    this.quantileMin = 0,
    this.quantileMax = 0.65,
    this.calibrationSd = 0.06,
    this.calibrationRirBonus = 1,
    this.calibrationSessions = 3,
    this.upMargin = 0.5,
    this.downMargin = 0.5,
    this.maxUpMain = 0.10,
    this.maxUpOther = 0.20,
    this.maxUpCalibration = 0.25,
    this.maxDownSet = 0.15,
    this.maxUpSet = 0.05,
    this.maxUpSetCalibration = 0.10,
    this.adviceGapFlames = 2,
    this.benchmarkWeight = 0.5,
    this.benchmarkRir = 1.5,
    this.benchmarkExtraReps = 6,
    this.benchmarkEveryDays = 6,
    this.benchmarkEveryDaysRated = 0,
    this.benchmarkMaxRir = 3,
    this.tauAcute = 1.2,
    this.tauChronic = 7,
    this.tauFitness = 42,
    this.kappaAcute = 0.004,
    this.kappaChronic = 0.0006,
    this.fatigueGainSd = 1,
    this.fatigueBaselineAlpha = 0.2,
    this.readinessSpan = 0.10,
    this.healthPerPoint = 0.015,
    this.healthNeutral = 4,
    this.sleepHoursNeutral = 6,
    this.sleepPerHour = 0.01,
    this.detailPerItem = 0.01,
    this.detailShare = 0.5,
    this.healthFloor = -0.08,
    this.healthLevel1 = -0.02,
    this.healthLevel2 = -0.04,
    this.healthRirBonus = 0.5,
    this.painThreshold = 3,
    this.painHard = 4,
    this.painSevere = 7,
    this.painRirBonus = 1,
    this.painClearDays = 14,
    this.transferShare = 0.43,
    this.transferMinSimilarity = 0.6,
    this.transferNeighbours = 3,
    this.detrainFromDays = 21,
    this.detrainPerWeek = 0.01,
    this.plateauProbability = 0.8,
    this.plateauMinWeeks = 3,
    this.plateauMinSessions = 4,
    this.volumeMinWeeks = 2,
    this.swapMinWeeks = 4,
    this.sessionRestructureMinWeeks = 4,
    this.blockRestructureMinWeeks = 8,
    this.confidenceLoads = 0.5,
    this.confidenceVolume = 0.65,
    this.confidenceSwap = 0.75,
    this.confidenceSession = 0.8,
    this.confidenceBlock = 0.85,
    this.refusalQuietDays = 28,
    this.deloadReadiness = 0.4,
    this.deloadSessions = 2,
    this.adherenceLow = 0.6,
    this.skipTimes = 3,
    this.timeShortTimes = 3,
    this.repSeconds = 3,
    this.transitionSeconds = 45,
    this.referenceBodyWeightKg = 70,
  });

  /// Réglage par défaut.
  static const AdaptParams standard = AdaptParams();

  // ------------------------------------------------ courbe répétitions ↔ charge

  /// `k` a priori de la courbe `part du 1RM = 1 / (1 + (n − 1) / k)`.
  final double kGeneral;

  /// `k` a priori des polyarticulaires du bas du corps.
  final double kLowerBody;

  /// Écart-type a priori de `ln k` (variabilité entre personnes).
  final double kLogSd;

  /// Borne basse de `k`.
  final double kMin;

  /// Borne haute de `k`.
  final double kMax;

  /// Fatigue intra-séance au-dessus de laquelle une série n'apprend plus
  /// `k` (seule une série fraîche et précise le fait).
  final double kLearnMaxFatigue;

  // ---------------------------------------------------------- modèle d'état

  /// Bruit de niveau, en écart-type de `ln` capacité par racine de semaine.
  final double levelNoise;

  /// Bruit de pente, par racine de semaine.
  final double trendNoise;

  /// Amortissement de la pente, par semaine.
  final double trendDamping;

  /// Écart-type de l'effet de jour (`ln` capacité).
  final double daySd;

  /// Part de la variance de l'effet de jour commune aux exercices d'une
  /// même séance.
  final double dayCommonShare;

  // ------------------------------------------------------------ observation

  /// Plancher du bruit d'observation (`ln` charge).
  final double observationFloor;

  /// Écart-type de l'estimation du RIR à l'échec, en répétitions.
  final double rirSdBase;

  /// Écart-type ajouté par répétition en réserve.
  final double rirSdPerRir;

  /// Répétitions jusqu'à l'échec à partir desquelles le bruit augmente.
  final double rirSdRepsFrom;

  /// Hausse relative du bruit par répétition au-delà.
  final double rirSdRepsGain;

  /// Répétition entamée d'une série ratée (capacité entre r et r + 1).
  final double failExtraReps;

  /// Écart-type d'une série menée à l'échec, en répétitions.
  final double failSd;

  /// Écart-type de la borne « la série a été terminée », en répétitions.
  final double completedSd;

  /// RIR d'une flamme (« 5 et plus ») : borne inférieure.
  final double openRir;

  /// Seuil de Huber, en écarts-types de l'innovation.
  final double huber;

  /// Biais de report : RIR réel = RIR dit × (1 + biais).
  final double rirBias;

  // ------------------------------------------------- notes peu informatives

  /// Fenêtre glissante, en séries notées.
  final int lazyWindow;

  /// Séries notées avant tout jugement.
  final int lazyMinSets;

  /// Part de confirmations pures au-delà de laquelle le poids baisse.
  final double lazyConfirmRate;

  /// Poids plancher d'une note confirmée.
  final double lazyMinWeight;

  // ------------------------------------------------- fatigue intra-séance

  /// Perte relative de répétitions après une série à l'échec, repos nul.
  final double setFatigueAtFailure;

  /// Constante de temps du repos, en secondes.
  final double setFatigueRestTau;

  /// Échelle du RIR dans la fatigue d'une série.
  final double setFatigueRirScale;

  /// Part de la fatigue d'une série encore présente deux séries plus tard.
  final double setFatigueRecovery;

  /// Incertitude relative sur la fatigue prévue.
  final double fatigueRelSd;

  /// Repos supposé quand la prescription n'en donne pas, en secondes.
  final int defaultRestSeconds;

  // ---------------------------------------------------------------- a priori

  /// Écart-type ajouté à une fourchette déclarée.
  final double priorSdDeclared;

  /// Écart-type d'un a priori tiré de la charge de départ du programme.
  final double priorSdPlan;

  /// Écart-type d'un a priori centré sur la première série.
  final double priorSdFirstSet;

  /// Écart-type d'un a priori tiré d'un exercice proche.
  final double priorSdNeighbour;

  /// Pente a priori par semaine, par niveau (débutant → élite).
  final List<double> trendPrior;

  /// Écart-type de la pente a priori, par niveau.
  final List<double> trendPriorSd;

  // ------------------------------------------------------------------ tenues

  /// Part de la tenue maximale que vaut une « répétition en réserve ».
  final double holdReserveShare;

  /// Bruit relatif d'une tenue notée à l'échec.
  final double holdSdBase;

  /// Bruit relatif ajouté par répétition en réserve.
  final double holdSdPerRir;

  // ------------------------------------------------------------ prescription

  /// Quantile prudent : `z = base − parRir × RIR visé`, borné.
  final double quantileBase;

  /// Pente du quantile selon le RIR visé.
  final double quantilePerRir;

  /// Borne basse du quantile.
  final double quantileMin;

  /// Borne haute du quantile.
  final double quantileMax;

  /// Incertitude au-dessus de laquelle l'exercice est en calibrage.
  final double calibrationSd;

  /// RIR ajouté à la cible pendant le calibrage.
  final double calibrationRirBonus;

  /// Séances au plus pendant lesquelles un exercice reste en calibrage.
  final int calibrationSessions;

  /// Marge de hausse, en répétitions au-dessus du haut de plage.
  final double upMargin;

  /// Marge de baisse, en répétitions sous le bas de plage.
  final double downMargin;

  /// Hausse maximale d'une séance à l'autre, mouvement principal.
  final double maxUpMain;

  /// Hausse maximale d'une séance à l'autre, autres exercices.
  final double maxUpOther;

  /// Hausse maximale d'une séance à l'autre pendant le calibrage.
  final double maxUpCalibration;

  /// Baisse maximale d'une série à la suivante.
  final double maxDownSet;

  /// Hausse maximale d'une série à la suivante.
  final double maxUpSet;

  /// Hausse maximale d'une série à la suivante pendant le calibrage.
  final double maxUpSetCalibration;

  /// Écart aux flammes visées qui déclenche un ajustement (D5 : 2 flammes).
  final int adviceGapFlames;

  // ------------------------------------------------------------ série repère

  /// Poids des notes sous lequel une série repère est demandée.
  final double benchmarkWeight;

  /// RIR visé d'une série repère.
  final double benchmarkRir;

  /// Répétitions ouvertes au-dessus de la cible.
  final int benchmarkExtraReps;

  /// Jours au moins entre deux séries repères d'un exercice quand les
  /// notes n'informent plus.
  final int benchmarkEveryDays;

  /// Jours au moins entre deux séries repères d'un exercice quand les
  /// notes informent (0 : jamais de série repère dans ce cas).
  final int benchmarkEveryDaysRated;

  /// RIR visé au-dessus duquel la semaine ne porte pas de série repère.
  final double benchmarkMaxRir;

  // ---------------------------------------------------------- forme, fatigue

  /// Constante de temps de la fatigue aiguë (par groupe), en jours.
  final double tauAcute;

  /// Constante de temps de la fatigue accumulée (globale), en jours.
  final double tauChronic;

  /// Constante de temps de la forme, en jours.
  final double tauFitness;

  /// Effet d'une unité de fatigue aiguë sur `ln` capacité.
  final double kappaAcute;

  /// Effet d'une unité de fatigue accumulée sur `ln` capacité.
  final double kappaChronic;

  /// Écart-type a priori du gain individuel de fatigue.
  final double fatigueGainSd;

  /// Lissage du niveau habituel de fatigue d'un exercice.
  final double fatigueBaselineAlpha;

  /// Baisse de `ln` capacité qui ramène la forme du jour à 0.
  final double readinessSpan;

  // ------------------------------------------------------------ bilan santé

  /// Effet d'un point de « Comment tu te sens ? » sous le neutre.
  final double healthPerPoint;

  /// Réponse neutre (aucun effet à partir de là).
  final int healthNeutral;

  /// Heures de sommeil sous lesquelles la forme baisse.
  final double sleepHoursNeutral;

  /// Effet par heure de sommeil manquante.
  final double sleepPerHour;

  /// Effet d'une réponse de détail basse (1 ou 2 sur 5).
  final double detailPerItem;

  /// Part des réponses de détail ajoutée à la réponse générale.
  final double detailShare;

  /// Plancher de l'effet du bilan.
  final double healthFloor;

  /// Seuil du premier palier d'ajustement.
  final double healthLevel1;

  /// Seuil du second palier d'ajustement.
  final double healthLevel2;

  /// RIR ajouté à la cible au premier palier.
  final double healthRirBonus;

  // ----------------------------------------------------------------- douleur

  /// Intensité au-dessus de laquelle une douleur compte (règle L13 : 3).
  final int painThreshold;

  /// Intensité à partir de laquelle une contrainte forte est écartée.
  final int painHard;

  /// Intensité à partir de laquelle une contrainte moyenne est écartée.
  final int painSevere;

  /// RIR ajouté sur les exercices gardés d'une zone douloureuse.
  final double painRirBonus;

  /// Jours sans signalement après lesquels une zone n'est plus suivie.
  final int painClearDays;

  // -------------------------------------------------- partage entre exercices

  /// Part d'un gain transférée à un exercice proche non pratiqué.
  final double transferShare;

  /// Proximité minimale d'un voisin.
  final double transferMinSimilarity;

  /// Nombre de voisins pris en compte.
  final int transferNeighbours;

  /// Jours sans pratique au-delà desquels la capacité décroît.
  final int detrainFromDays;

  /// Décroissance par semaine au-delà.
  final double detrainPerWeek;

  // ------------------------------------------------------------ propositions

  /// Probabilité d'une pente négative ou nulle qui fait un plateau.
  final double plateauProbability;

  /// Semaines de données d'un exercice avant de parler de plateau.
  final int plateauMinWeeks;

  /// Séances d'un exercice avant de parler de plateau.
  final int plateauMinSessions;

  /// Semaines de données avant les propositions de volume (D5.7).
  final int volumeMinWeeks;

  /// Semaines de données avant un échange d'exercice (D5.7).
  final int swapMinWeeks;

  /// Semaines de données avant une restructuration de séance (1 bloc).
  final int sessionRestructureMinWeeks;

  /// Semaines de données avant une restructuration de bloc (2 blocs).
  final int blockRestructureMinWeeks;

  /// Confiance minimale d'une proposition de charge ou de répétitions.
  final double confidenceLoads;

  /// Confiance minimale d'une proposition de volume ou de décharge.
  final double confidenceVolume;

  /// Confiance minimale d'un échange d'exercice.
  final double confidenceSwap;

  /// Confiance minimale d'une restructuration de séance.
  final double confidenceSession;

  /// Confiance minimale d'une restructuration de bloc.
  final double confidenceBlock;

  /// Jours pendant lesquels une proposition refusée n'est pas refaite.
  final int refusalQuietDays;

  /// Forme du jour sous laquelle une séance compte pour une décharge.
  final double deloadReadiness;

  /// Séances de suite sous ce seuil avant de proposer une décharge.
  final int deloadSessions;

  /// Assiduité sous laquelle une restructuration de bloc est proposée.
  final double adherenceLow;

  /// Fois où un exercice est sauté avant d'être signalé.
  final int skipTimes;

  /// Fois où le temps manque un même jour avant de restructurer la séance.
  final int timeShortTimes;

  // ------------------------------------------------------------------ durées

  /// Durée d'une répétition, en secondes (celle de `kalis_plan`).
  final int repSeconds;

  /// Transition entre deux exercices, en secondes (celle de `kalis_plan`).
  final int transitionSeconds;

  /// Poids de corps de référence quand ni le profil ni la séance n'en
  /// donnent (il ne sert qu'à l'échelle interne des exercices lestés).
  final double referenceBodyWeightKg;
}
