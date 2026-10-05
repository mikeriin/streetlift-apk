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
    this.failOutlier = 3,
    this.pivotShiftReps = 2.5,
    this.pivotShiftShare = 0.3,
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
    this.plateauProbability = 0.9,
    this.plateauMinWeeks = 4,
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
    this.swapQuietDays = 21,
    this.deloadReadiness = 0.4,
    this.deloadSessions = 2,
    this.adherenceLow = 0.6,
    this.skipTimes = 3,
    this.timeShortTimes = 3,
    this.repSeconds = 3,
    this.transitionSeconds = 45,
    this.referenceBodyWeightKg = 70,
    this.coachRise = const <double>[0.10, 0.05, 0.05, 0.05],
    this.coachCorridorDown = 0.05,
    this.coachCorridorUp = 0.075,
    this.coachCorridorWiden = 0.025,
    this.coachCensorRir = 2,
    this.coachCurveRir = 3,
    this.coachHoldMaxShare = 0.75,
    this.coachHoldEasyShare = 0.4,
    this.coachHoldUsefulShare = 0.5,
    this.coachAssistGapRir = 2,
    this.coachAssistStepShare = 0.75,
    this.coachAssistStepSd = 0.25,
    this.coachBackoffMinDrop = 0.05,
    this.coachNewExerciseShare = 0.6,
    this.coachOverloadFragileMax = 1.0,
    this.coachDirectGuardRir = 2,
    this.coachProbeDays = 14,
    this.coachTopProbeReps = 3,
    this.coachOverreachDrop = 0.05,
    this.coachOverreachDays = 7,
    this.coachOverreachSpanDays = 21,
    this.coachOverreachCut = 0.4,
    this.coachLowDayRir = 3,
    this.coachBreakDays = 14,
    this.coachBreakSets = 0.8,
    this.biasLearnRate = 0.25,
    this.biasLearnRir = 3,
    this.biasLearnMaxStep = 0.1,
    this.biasMin = 0,
    this.biasMax = 0.6,
    this.coachCorridorUpMax = 0.15,
    this.coachWorstSetSlack = 1.5,
    this.coachBreachRir = 1,
    this.coachBreachCut = 0.025,
    this.coachBreachCutMax = 0.05,
    this.coachEasyGapRir = 2,
    this.coachHistoryRiseFactor = 0.5,
    this.coachHoldRise = const <double>[0.20, 0.15, 0.10, 0.10],
    this.coachHoldRiseSlackSeconds = 1,
    this.coachHoldMaxFloorShare = 0.55,
    this.coachHoldBestDays = 28,
    this.coachTaperGain = 0.02,
    this.coachAssistMinDays = 14,
    this.coachReturnStart = 0.5,
    this.coachReturnStep = 0.1,
    this.coachReturnFloor = 0.4,
    this.coachReturnRir = 3,
    this.coachReturnPain = 2,
    this.coachReturnWatchDays = 84,
    this.coachEventNearDays = 14,
    this.coachEccentricEventDays = 10,
    this.coachStopMinSets = 2,
    this.coachPainRegress = 5,
    this.coachPainStop = 6,
    this.coachPainRegressSets = 0.6,
    this.coachEasyStepShare = 0.05,
    this.attemptOpenerShare = 0.91,
    this.attemptOpenerProbability = 0.95,
    this.attemptSecondProbability = 0.80,
    this.attemptThirdProbability = 0.50,
    this.attemptSecureProbability = 0.70,
    this.attemptRecordProbability = 0.35,
    this.attemptLowHealthShare = 0.02,
    this.attemptRecentDays = 42,
    this.skillSessions = 3,
    this.skillDownSessions = 2,
    this.skillDownShare = 0.5,
    this.skillTenureWeeks = const <int>[2, 8, 18, 30],
    this.skillPainMax = 3,
    this.pacingFirstShare = 0.65,
    this.pacingNextShare = 0.5,
    this.pacingRestSeconds = 15,
    this.toleranceMinWeeks = 3,
    this.trainingSetMaxReps = 6,
    this.trainingSetMaxRir = 3,
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

  /// Seuil, en écarts-types de l'innovation, au-delà duquel une série
  /// manquée (échec, zéro répétition) est tenue pour une saisie douteuse.
  final double failOutlier;

  /// Écart minimal, en répétitions, entre la plage de la séance et le
  /// pivot de la courbe pour que le pivot soit déplacé.
  final double pivotShiftReps;

  /// Le même écart minimal, en part du pivot (les deux doivent être
  /// dépassés).
  final double pivotShiftShare;

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

  /// Jours sans nouvel échange d'exercice après un échange appliqué.
  final int swapQuietDays;

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

  // -------------------------------------------------------------- mode coach

  /// Hausse maximale d'une séance à la suivante du même emplacement, à
  /// répétitions égales, par niveau (débutant → élite), en charge totale.
  final List<double> coachRise;

  /// Couloir sous la part du 1RM écrite par le bloc quand le RIR pilote
  /// la charge (points de 1RM).
  final double coachCorridorDown;

  /// Couloir au-dessus de la part écrite par le bloc.
  final double coachCorridorUp;

  /// Élargissement du haut du couloir par séance où, servie au haut du
  /// couloir, la charge a laissé au moins [coachEasyGapRir] répétitions de
  /// plus que visé (la courbe charge-répétitions de l'athlète est plus
  /// plate que la moyenne : la note d'effort prime sur la part du 1RM).
  final double coachCorridorWiden;

  /// Mode coach : à partir de ce RIR dit, une note ne se lit que comme une
  /// borne basse (« au moins tant en réserve ») : la prédiction des
  /// répétitions restantes se dégrade loin de l'échec et plafonne (Zourdos
  /// et al. 2021 ; Halperin et al. 2022).
  final double coachCensorRir;

  /// Mode coach : réserve dite jusqu'à laquelle une série fraîche renseigne
  /// la forme de la courbe répétitions ↔ charge.
  final double coachCurveRir;

  /// Mode coach : part du maximum du jour qu'un maintien d'entraînement
  /// ne dépasse pas (les maintiens se travaillent sous le maximum, la
  /// propreté d'abord : R4-F9).
  final double coachHoldMaxShare;

  /// Mode coach : part du maintien maximal mesuré sous laquelle une durée
  /// écrite est tenue pour trop facile, et part vers laquelle elle monte
  /// alors (R4-F2 : maintiens à 50–70 % du maximum ; aucune étude ne fixe
  /// de seuil en part de la durée maximale — choix raisonné).
  final double coachHoldEasyShare;

  /// Voir [coachHoldEasyShare].
  final double coachHoldUsefulShare;

  /// Mode coach, exercice assisté (élastique) : écart de réserve, au-delà
  /// de la cible, à partir duquel un cran d'assistance de moins est
  /// conseillé (choix raisonné ; ACSM 2009 : une à deux répétitions de
  /// plus que la cible, deux séances de suite).
  final double coachAssistGapRir;

  /// Mode coach : part de la capacité attendue après un cran d'assistance
  /// de moins (choix raisonné : l'assistance d'un élastique ne se lit pas
  /// en kg, McMaster et Cronin 2010), et écart-type relatif ajouté à
  /// l'estimation quand l'assistance change.
  final double coachAssistStepShare;

  /// Voir [coachAssistStepShare].
  final double coachAssistStepSd;

  /// Mode coach : plus petite baisse de charge des séries allégées quand
  /// le moteur les rapproche de la réserve visée (au moins la moitié de
  /// la baisse écrite ; choix raisonné, R2-P6).
  final double coachBackoffMinDrop;

  /// Mode coach : part de la charge écrite servie à la première séance
  /// d'un exercice jamais fait dont la charge est écrite en part du 1RM
  /// d'un autre mouvement (entrée graduée, R5-P22).
  final double coachNewExerciseShare;

  /// Mode coach : part du 1RM de référence qu'un exercice surchargé
  /// (amplitude partielle) ne dépasse pas sur une zone à antécédent.
  final double coachOverloadFragileMax;

  /// Mode coach, exercice sans charge : réserve minimale (avec la marge de
  /// prudence) sous laquelle les répétitions écrites par le bloc sont
  /// réduites.
  final double coachDirectGuardRir;

  /// Mode coach : jours sans série qui mesure la capacité (toutes les
  /// notes au plafond « loin de l'échec ») au bout desquels la dernière
  /// série devient une série repère (APRE, Mann et al. 2010).
  final int coachProbeDays;

  /// Mode coach : répétitions de plus que la série de tête écrite permises
  /// à une série de tête repère (ouverte).
  final int coachTopProbeReps;

  /// Mode coach, alerte de surmenage : baisse relative de la performance
  /// estimée (deux séances mesurées de suite sous la séance de référence)
  /// qui déclenche une semaine à volume réduit. La baisse durable de
  /// performance est le seul indicateur fiable du surmenage en
  /// musculation (Grandou et al. 2020) ; aucun seuil n'est publié : celui-ci
  /// est un choix du moteur, au-dessus de la variation test-retest médiane
  /// d'un 1RM (4,2 %, Grgic et al. 2020), exigé deux séances de suite.
  final double coachOverreachDrop;

  /// Mode coach, alerte de surmenage : jours à volume réduit.
  final int coachOverreachDays;

  /// Mode coach, alerte de surmenage : étendue maximale, en jours, des
  /// trois séances mesurées comparées.
  final int coachOverreachSpanDays;

  /// Mode coach, alerte de surmenage : part des lignes retirées, intensité
  /// gardée (décharge d'environ 7 jours par la baisse du volume, Bell et
  /// al. 2023 ; baisse de volume de 41 à 60 % à l'affûtage, Bosquet et al.
  /// 2007).
  final double coachOverreachCut;

  /// Mode coach : réserve minimale des séries un jour de bilan nettement
  /// bas.
  final double coachLowDayRir;

  /// Mode coach : coupure, en jours, à partir de laquelle la semaine du
  /// retour est allégée.
  final int coachBreakDays;

  /// Mode coach : part des séries gardée la semaine du retour.
  final double coachBreakSets;

  /// Part de l'écart d'un test (rapporté à [biasLearnRir] répétitions)
  /// portée au biais de note appris.
  final double biasLearnRate;

  /// RIR typique des séries notées, pour convertir un écart de test en
  /// biais.
  final double biasLearnRir;

  /// Correction maximale du biais par test.
  final double biasLearnMaxStep;

  /// Biais de note appris, au moins.
  final double biasMin;

  /// Biais de note appris, au plus.
  final double biasMax;

  /// Haut du couloir élargi, au plus (part du 1RM au-dessus de la part du
  /// bloc).
  final double coachCorridorUpMax;

  /// Marge admise, en répétitions en réserve, entre la cible et la série la
  /// plus dure prévue (quantile prudent) ; jamais moins d'une demi-réserve.
  final double coachWorstSetSlack;

  /// Écart sous le plancher de réserve, en répétitions, qui compte comme
  /// un plafond d'effort dépassé.
  final double coachBreachRir;

  /// Baisse de charge par répétition d'écart quand le plafond d'effort est
  /// dépassé.
  final double coachBreachCut;

  /// Baisse de charge maximale d'une série à la suivante pour ce motif.
  final double coachBreachCutMax;

  /// Réserve de plus que la cible à partir de laquelle la série suivante
  /// peut monter d'un cran.
  final double coachEasyGapRir;

  /// Facteur appliqué aux hausses sur une zone à antécédent récent.
  final double coachHistoryRiseFactor;

  /// Hausse maximale d'une tenue en bras tendus d'une séance à la suivante,
  /// par niveau.
  final List<double> coachHoldRise;

  /// Tolérance de cette hausse, en secondes.
  final int coachHoldRiseSlackSeconds;

  /// Part du meilleur maintien mesuré que la borne de hausse d'une tenue
  /// laisse toujours servir (CX, correction 1 : après un test qui saute, la
  /// tenue écrite à 55-65 % du test était servie à 5-9 s, relecture
  /// documentée et panel, `street_01` ; R4-F2 : 50 à 70 % du maximum).
  final double coachHoldMaxFloorShare;

  /// Fenêtre du « meilleur maintien récent » qui sert de plancher, en jours
  /// (CA2, partie 0 : jamais un record d'avant un arrêt ; la force
  /// isométrique et maximale baisse de façon mesurable après trois à quatre
  /// semaines d'arrêt — Bosquet et al. 2013).
  final int coachHoldBestDays;

  /// Gain du maximum du jour après un affûtage (pendant une semaine
  /// d'affûtage ou de compétition, ou la semaine qui suit), pris en compte
  /// par les
  /// tentatives : 2 %, le bas de la fourchette mesurée chez les
  /// powerlifters (Travis et al. 2020 : +1,8 à 6,4 % selon le mouvement
  /// après un affûtage d'une à deux semaines). Choix prudent (CA2, partie
  /// 0 : tentatives à 90-93 % du maximum du jour, relecture documentée).
  final double coachTaperGain;

  /// Jours au même cran d'assistance avant d'en retirer un autre (CA2,
  /// partie 0 : panel, « un cran d'élastique toutes les deux semaines au
  /// plus » ; règle « 2 pour 2 » de l'ACSM 2009 : deux séances réussies
  /// avant de charger). Choix raisonné.
  final int coachAssistMinDays;

  /// Reprise graduée conduite par le moteur (arrêt levé au milieu d'un
  /// bloc qui écrit les mouvements provocants) : part du volume écrit à la
  /// première semaine de charge (règle de `kalis_plan`, CX correction 1 :
  /// 50 %, puis +10 % par semaine de charge ; Soligard et al. 2016).
  final double coachReturnStart;

  /// Hausse de cette part par semaine de charge.
  final double coachReturnStep;

  /// Plus petite part servie quand le palier recule (douleur qui répond).
  final double coachReturnFloor;

  /// Réserve minimale d'un mouvement en reprise graduée (répétitions).
  final double coachReturnRir;

  /// Gêne au-delà de laquelle le palier de reprise recule (sur 10 :
  /// modèle de surveillance de la douleur, Silbernagel et al. 2007 ; règle
  /// écrite par `kalis_plan` : « 2 sur 10 au plus pendant la séance et
  /// retour à l'état habituel le lendemain »).
  final int coachReturnPain;

  /// Jours après la levée d'un arrêt pendant lesquels la reprise propre au
  /// moteur peut encore s'appliquer (douze semaines, comme le retour d'une
  /// douleur : `painRecurDays`).
  final int coachReturnWatchDays;

  /// Jours avant une échéance principale à partir desquels les décisions
  /// sont prudentes.
  final int coachEventNearDays;

  /// Jours avant une échéance sous lesquels aucun excentrique accentué
  /// n'est servi.
  final int coachEccentricEventDays;

  /// Séries faites avant qu'une règle d'arrêt puisse arrêter l'exercice,
  /// quand la règle ne le dit pas.
  final int coachStopMinSets;

  /// Douleur à partir de laquelle un exercice à contrainte moyenne sur la
  /// zone est allégé (moins de séries, une réserve de plus).
  final int coachPainRegress;

  /// Douleur à partir de laquelle un exercice à contrainte moyenne sur la
  /// zone est écarté.
  final int coachPainStop;

  /// Part des séries gardée quand un exercice est allégé pour une douleur.
  final double coachPainRegressSets;

  /// Hausse maximale d'une série à la suivante quand la série a été notée
  /// nettement plus facile que visé.
  final double coachEasyStepShare;

  // -------------------------------------------------------------- tentatives

  /// Part du maximum estimé que l'ouverture ne dépasse pas.
  final double attemptOpenerShare;

  /// Probabilité de réussite minimale de l'ouverture.
  final double attemptOpenerProbability;

  /// Probabilité de réussite minimale de la deuxième tentative.
  final double attemptSecondProbability;

  /// Probabilité de réussite minimale de la troisième tentative (objectif
  /// « plus gros total »).
  final double attemptThirdProbability;

  /// La même pour l'objectif « assurer un total ».
  final double attemptSecureProbability;

  /// La même pour l'objectif « record ».
  final double attemptRecordProbability;

  /// Part retirée au maximum estimé par palier de bilan bas.
  final double attemptLowHealthShare;

  /// Jours pendant lesquels une barre réussie à l'entraînement compte comme
  /// « déjà faite » pour l'ouverture.
  final int attemptRecentDays;

  // ------------------------------------------------------------------ figures

  /// Séances de suite où le critère d'une étape doit être tenu, quand
  /// l'échelle ne le dit pas.
  final int skillSessions;

  /// Séances de suite sous le critère qui font proposer l'étape plus facile.
  final int skillDownSessions;

  /// Part du critère sous laquelle une séance compte comme manquée.
  final double skillDownShare;

  /// Semaines déjà passées à l'étape, par tranche déclarée au profil.
  final List<int> skillTenureWeeks;

  /// Douleur au-dessus de laquelle une étape ne monte pas.
  final int skillPainMax;

  // ------------------------------------------------- épreuves de répétitions

  /// Part du maximum de la première série d'un poste.
  final double pacingFirstShare;

  /// Part de la série précédente des séries suivantes.
  final double pacingNextShare;

  /// Repos entre deux séries d'un poste, en secondes.
  final int pacingRestSeconds;

  // ---------------------------------------------------------------- tolérance

  /// Semaines de données avant de rendre un volume toléré.
  final int toleranceMinWeeks;

  /// Répétitions au plus d'une série d'entraînement retenue comme repère.
  final int trainingSetMaxReps;

  /// Réserve au plus d'une série d'entraînement retenue comme repère.
  final double trainingSetMaxRir;
}
