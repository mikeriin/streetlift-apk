// GÉNÉRÉ par tool/gen_contracts.py depuis tool/contracts_spec.py — ne pas modifier à la main.
part of '../contracts.dart';

/// Codes de raison : identifiants stables, sans texte.
abstract final class ReasonCodes {
  /// Exercice ou séance choisi pour respecter le dosage d'une discipline.
  static const String planDisciplineShare = 'plan.discipline_share';

  /// Couvre un schéma de mouvement qui manquait.
  static const String planMovementCoverage = 'plan.movement_coverage';

  /// Ramène le volume hebdomadaire d'un muscle dans sa plage.
  static const String planMuscleVolume = 'plan.muscle_volume';

  /// Répartit la fatigue entre les séances.
  static const String planFatigueBalance = 'plan.fatigue_balance';

  /// Tient dans le temps disponible ce jour-là.
  static const String planTimeBudget = 'plan.time_budget';

  /// Faisable avec le matériel et le lieu du profil.
  static const String planEquipmentAvailable = 'plan.equipment_available';

  /// Écarté : matériel absent du profil.
  static const String planEquipmentMissing = 'plan.equipment_missing';

  /// Difficulté adaptée au niveau déclaré.
  static const String planLevelMatch = 'plan.level_match';

  /// Écarté : un palier précédent n'est pas acquis.
  static const String planPrerequisiteMissing = 'plan.prerequisite_missing';

  /// Écarté ou remplacé : contrainte sur une articulation limitée.
  static const String planJointLimitation = 'plan.joint_limitation';

  /// Exercice aimé par l'utilisateur.
  static const String planUserLikes = 'plan.user_likes';

  /// Écarté : l'utilisateur n'aime pas cet exercice.
  static const String planUserDislikes = 'plan.user_dislikes';

  /// Remplacé : l'utilisateur ne sait pas le faire.
  static const String planUserCannotDo = 'plan.user_cannot_do';

  /// Ajouté à la demande de l'utilisateur.
  static const String planUserAdded = 'plan.user_added';

  /// Retiré à la demande de l'utilisateur.
  static const String planUserRemoved = 'plan.user_removed';

  /// Variante choisie par l'utilisateur.
  static const String planUserReplaced = 'plan.user_replaced';

  /// Inchangé : validé par l'utilisateur.
  static const String planLockKept = 'plan.lock_kept';

  /// Sert un objectif du profil.
  static const String planGoalSupport = 'plan.goal_support';

  /// Évite une redondance avec un exercice déjà présent.
  static const String planVariety = 'plan.variety';

  /// A bougé parce que le reste du programme a été ré-optimisé.
  static const String planReoptimized = 'plan.reoptimized';

  /// Variante plus facile.
  static const String planVariantEasier = 'plan.variant_easier';

  /// Variante équivalente.
  static const String planVariantEquivalent = 'plan.variant_equivalent';

  /// Variante avec un autre matériel.
  static const String planVariantOtherEquipment =
      'plan.variant_other_equipment';

  /// Charge de départ prudente.
  static const String planStartLoadConservative =
      'plan.start_load_conservative';

  /// Charge à caler sur les premières séances.
  static const String planToCalibrate = 'plan.to_calibrate';

  /// Logique de la semaine (introduction, montée, décharge, test).
  static const String planWeekKind = 'plan.week_kind';

  /// Reprend ou fait progresser un exercice du bloc précédent.
  static const String planProgressionFromPreviousBlock =
      'plan.progression_from_previous_block';

  /// Tient compte du résumé d'adaptation.
  static const String planAdaptationApplied = 'plan.adaptation_applied';

  /// Programme prudent : questionnaire santé en mode prudent.
  static const String planCautiousHealth = 'plan.cautious_health';

  /// Restructuration limitée à cette portée.
  static const String planRestructureScope = 'plan.restructure_scope';

  /// Séries notées plus faciles que la cible.
  static const String adaptFlamesBelowTarget = 'adapt.flames_below_target';

  /// Séries notées plus dures que la cible.
  static const String adaptFlamesAboveTarget = 'adapt.flames_above_target';

  /// Série manquée.
  static const String adaptSetFailed = 'adapt.set_failed';

  /// Charge augmentée.
  static const String adaptLoadUp = 'adapt.load_up';

  /// Charge diminuée.
  static const String adaptLoadDown = 'adapt.load_down';

  /// Répétitions augmentées.
  static const String adaptRepsUp = 'adapt.reps_up';

  /// Répétitions diminuées.
  static const String adaptRepsDown = 'adapt.reps_down';

  /// Séries ajoutées.
  static const String adaptVolumeUp = 'adapt.volume_up';

  /// Séries retirées.
  static const String adaptVolumeDown = 'adapt.volume_down';

  /// Séance de calibrage : la charge se cale.
  static const String adaptCalibration = 'adapt.calibration';

  /// Capacité estimée mise à jour.
  static const String adaptEstimateUpdated = 'adapt.estimate_updated';

  /// Confiance du modèle insuffisante pour proposer davantage.
  static const String adaptLowConfidence = 'adapt.low_confidence';

  /// Niveau de déblocage atteint ou requis.
  static const String adaptUnlockLevel = 'adapt.unlock_level';

  /// Bilan santé bas : séance allégée.
  static const String adaptHealthLow = 'adapt.health_low';

  /// Sommeil mauvais.
  static const String adaptSleepLow = 'adapt.sleep_low';

  /// Moins de temps que prévu.
  static const String adaptTimeShort = 'adapt.time_short';

  /// Douleur signalée : la zone est épargnée.
  static const String adaptPainReported = 'adapt.pain_reported';

  /// Douleur persistante : règle santé L13 (renvoi vers un professionnel).
  static const String adaptPainPersistent = 'adapt.pain_persistent';

  /// Fatigue accumulée élevée.
  static const String adaptFatigueHigh = 'adapt.fatigue_high';

  /// Semaine de décharge proposée.
  static const String adaptDeload = 'adapt.deload';

  /// Stagnation sur un exercice.
  static const String adaptPlateau = 'adapt.plateau';

  /// Exercice régulièrement sauté.
  static const String adaptExerciseSkipped = 'adapt.exercise_skipped';

  /// Séances manquées.
  static const String adaptMissedSessions = 'adapt.missed_sessions';

  /// Reprise après une coupure.
  static const String adaptResumeAfterBreak = 'adapt.resume_after_break';

  /// Séries sans note : non prises en compte.
  static const String adaptNoRating = 'adapt.no_rating';

  /// XP de l'effort réel de la séance (plafonné).
  static const String questXpEffort = 'quest.xp_effort';

  /// XP de régularité.
  static const String questXpConsistency = 'quest.xp_consistency';

  /// XP d'un record.
  static const String questXpRecord = 'quest.xp_record';

  /// XP d'un jalon d'objectif.
  static const String questXpMilestone = 'quest.xp_milestone';

  /// XP d'une quête terminée.
  static const String questXpQuest = 'quest.xp_quest';

  /// Passage de niveau.
  static const String questLevelUp = 'quest.level_up';

  /// Passage de prestige.
  static const String questPrestige = 'quest.prestige';

  /// Nouveau rang sur un mouvement.
  static const String questRankUp = 'quest.rank_up';

  /// Quête Koach ciblant un point faible.
  static const String questWeakPoint = 'quest.weak_point';

  /// Chapitre de campagne lié à un bloc.
  static const String questCampaignChapter = 'quest.campaign_chapter';

  /// Objectif suggéré d'après le profil et les données.
  static const String questGoalSuggested = 'quest.goal_suggested';

  /// Prédiction de date mise à jour.
  static const String questPredictionUpdated = 'quest.prediction_updated';

  /// Notes presque toujours confirmées telles quelles : elles pèsent moins, la
  /// performance réelle pèse davantage.
  static const String adaptRatingsUninformative = 'adapt.ratings_uninformative';

  /// Série repère : dernière série ouverte, autant de répétitions que possible
  /// en gardant la réserve indiquée.
  static const String adaptBenchmarkSet = 'adapt.benchmark_set';

  /// Lieu du jour différent du lieu prévu : exercice remplacé par un équivalent
  /// faisable sur place.
  static const String adaptPlaceChanged = 'adapt.place_changed';

  /// Charge non augmentée (échec non prévu, douleur, bilan bas, plafond de
  /// hausse).
  static const String adaptLoadHeld = 'adapt.load_held';

  /// Plus petit incrément de charge trop grand : la progression passe par les
  /// répétitions.
  static const String adaptIncrementCoarse = 'adapt.increment_coarse';

  /// Forme du jour estimée (bilan santé, fatigue modélisée, séries déjà
  /// faites).
  static const String adaptReadiness = 'adapt.readiness';

  /// Volume hebdomadaire d'un groupe musculaire ajusté d'après la réponse
  /// observée.
  static const String adaptVolumeResponse = 'adapt.volume_response';

  /// Plus petite charge disponible encore trop lourde pour cet exercice : il
  /// est remplacé ou retiré de la séance.
  static const String adaptLoadFloor = 'adapt.load_floor';

  /// Séance faite malgré une douleur déclarée avant la séance : aucune
  /// récompense (ni XP, ni coffre, ni note, ni quête).
  static const String questNoRewardPain = 'quest.no_reward_pain';

  /// Gain d'XP borné par un plafond (`session`, `week`, `records`).
  static const String questXpCapped = 'quest.xp_capped';

  /// Combo : séries consécutives dans la cible, bonus plafonné.
  static const String questCombo = 'quest.combo';

  /// Composantes de la note de séance : réalisation, justesse des flammes,
  /// records.
  static const String questSessionGrade = 'quest.session_grade';

  /// Quête du jour, adaptée au jour (`training`, `rest`, `break`).
  static const String questDaily = 'quest.daily';

  /// Quête de la semaine, bornée par les séances prévues.
  static const String questWeekly = 'quest.weekly';

  /// Boss de campagne : séance de test ou dernière séance du bloc.
  static const String questCampaignBoss = 'quest.campaign_boss';

  /// Quête Koach : exercice du programme le plus souvent écourté ou sauté.
  static const String questLaggingExercise = 'quest.lagging_exercise';

  /// Quête Koach : jour de la semaine le moins régulier.
  static const String questWeekdayFocus = 'quest.weekday_focus';

  /// Part de l'XP de régularité due aux jours de repos respectés.
  static const String questXpRest = 'quest.xp_rest';

  /// Série de semaines réussies (jalon ou longueur atteinte).
  static const String questStreak = 'quest.streak';

  /// Semaine en pause : la série ne bouge pas. `cause` : motif de la pause
  /// déclarée (`vacation`, `illness`, `injury`, `other`) ou `pain` (séance
  /// faite malgré une douleur).
  static const String questStreakPaused = 'quest.streak_paused';

  /// Coffre surprise (tirage, ou garantie après une série de séances sans
  /// coffre).
  static const String questChest = 'quest.chest';

  /// Objectif en retard : une date ou une cible ajustée est proposée.
  static const String questGoalLate = 'quest.goal_late';

  /// Première fois sur un exercice.
  static const String questFirstTime = 'quest.first_time';

  /// Fantôme battu : mieux que la dernière fois (`last`) ou que la meilleure
  /// fois (`best`).
  static const String questGhostBeaten = 'quest.ghost_beaten';

  /// Bonus de départ plafonné (désactivé par défaut).
  static const String questStartBonus = 'quest.start_bonus';

  /// Le bloc réalise une phase du plan de saison, à tant de semaines de
  /// l'échéance.
  static const String planSeasonPhase = 'plan.season_phase';

  /// Affûtage : volume réduit, intensité gardée, avant une échéance.
  static const String planTaper = 'plan.taper';

  /// La saison est construite pour arriver en forme à cette échéance.
  static const String planPeakEvent = 'plan.peak_event';

  /// Ondulation : jour lourd, moyen ou léger.
  static const String planUndulation = 'plan.undulation';

  /// Technique de série choisie pour cet exercice.
  static const String planTechnique = 'plan.technique';

  /// Technique avancée non servie : un prérequis manque (ancienneté, niveau,
  /// test, récupération, gêne).
  static const String planTechniqueWithheld = 'plan.technique_withheld';

  /// Spécialisation : priorité donnée à une cible pendant tant de semaines.
  static const String planSpecialization = 'plan.specialization';

  /// Volume d'entretien du reste pendant une spécialisation ou un affûtage.
  static const String planMaintenanceVolume = 'plan.maintenance_volume';

  /// Étape de la progression d'une figure.
  static const String planSkillStep = 'plan.skill_step';

  /// Figure bloquée à la même étape depuis longtemps : la méthode change (autre
  /// variante, autre dosage).
  static const String planSkillPlateau = 'plan.skill_plateau';

  /// Premier bloc calé sur la charge d'entraînement actuelle déclarée.
  static const String planRecentLoad = 'plan.recent_load';

  /// Test programmé (série d'estimation, maximum, maintien, course).
  static const String planTestScheduled = 'plan.test_scheduled';

  /// Charge ou durée calculée d'après un test ou un record du profil.
  static const String planBenchmarkUsed = 'plan.benchmark_used';

  /// Charge donnée en part du maximum.
  static const String planPercentBased = 'plan.percent_based';

  /// Tient compte d'une réponse de récupération et de vie (sommeil, stress,
  /// métier physique, déficit énergétique).
  static const String planRecoveryProfile = 'plan.recovery_profile';

  /// Zone à antécédent : progression plus prudente des mouvements qui la
  /// chargent.
  static const String planConstraintHistory = 'plan.constraint_history';

  /// Tient compte d'un autre sport : séances lourdes placées à distance.
  static const String planConcurrentSport = 'plan.concurrent_sport';

  /// Volume, intensité ou techniques réglés sur l'ancienneté d'entraînement.
  static const String planTrainingAge = 'plan.training_age';

  /// Reprise après une interruption : redémarrage progressif.
  static const String planReturnFromGap = 'plan.return_from_gap';

  /// Exercice d'assistance choisi pour un point faible déclaré.
  static const String planWeakPoint = 'plan.weak_point';

  /// Travail spécifique d'une épreuve (mouvements, enchaînements, durées de la
  /// compétition).
  static const String planEventSpecific = 'plan.event_specific';

  /// Séries allégées calculées sur la série de tête réalisée.
  static const String adaptBackoffFromTopSet = 'adapt.backoff_from_top_set';

  /// Plafond d'effort atteint : charge abaissée pour garder la réserve prévue.
  static const String adaptRirCap = 'adapt.rir_cap';

  /// Résultat d'un test et son incertitude.
  static const String adaptTestResult = 'adapt.test_result';

  /// Critère de passage tenu : étape suivante de la figure.
  static const String adaptSkillStepUp = 'adapt.skill_step_up';

  /// Mauvais jour ou critère perdu : étape plus facile.
  static const String adaptSkillStepDown = 'adapt.skill_step_down';

  /// Étape gardée : critère non tenu, ou durée minimale à l'étape non atteinte
  /// (tendons).
  static const String adaptSkillHold = 'adapt.skill_hold';

  /// Ajustement limité par l'intention de la phase.
  static const String adaptPhaseRespected = 'adapt.phase_respected';

  /// Affûtage : aucun volume ajouté, intensité gardée.
  static const String adaptTaperNoVolume = 'adapt.taper_no_volume';

  /// Échéance proche : décisions prudentes.
  static const String adaptEventNear = 'adapt.event_near';

  /// Ouverture choisie comme une part du maximum estimé : une barre sûre.
  static const String adaptAttemptOpener = 'adapt.attempt_opener';

  /// Tentative suivante choisie d'après la précédente et l'incertitude du
  /// maximum.
  static const String adaptAttemptNext = 'adapt.attempt_next';

  /// Tentative prudente (incertitude élevée, échec précédent, bilan bas,
  /// pesée).
  static const String adaptAttemptConservative = 'adapt.attempt_conservative';

  /// Stratégie de rythme d'une épreuve de répétitions.
  static const String adaptPacing = 'adapt.pacing';

  /// Tolérance réglée sur une réponse de récupération et de vie du profil.
  static const String adaptRecoveryProfile = 'adapt.recovery_profile';

  /// Charge des tendons surveillée : progression en bras tendus ou en appui
  /// ralentie.
  static const String adaptTendonLoad = 'adapt.tendon_load';

  /// Technique de série exécutée telle que prescrite.
  static const String adaptTechniqueExecuted = 'adapt.technique_executed';

  /// Mini-séries arrêtées (répétitions manquées, plafond atteint, qualité).
  static const String adaptMiniSetStop = 'adapt.mini_set_stop';
}

/// Registre des codes de raison et de leurs paramètres typés.
const List<ReasonSpec> reasonRegistry = <ReasonSpec>[
  ReasonSpec(ReasonCodes.planDisciplineShare, <String, ReasonParamType>{
    'discipline': ReasonParamType.text,
    'pct': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planMovementCoverage, <String, ReasonParamType>{
    'pattern': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planMuscleVolume, <String, ReasonParamType>{
    'muscle': ReasonParamType.text,
    'weeklySets': ReasonParamType.number,
    'targetLow': ReasonParamType.number,
    'targetHigh': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planFatigueBalance, <String, ReasonParamType>{
    'dayIndex': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planTimeBudget, <String, ReasonParamType>{
    'minutes': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planEquipmentAvailable, <String, ReasonParamType>{
    'place': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planEquipmentMissing, <String, ReasonParamType>{
    'equipment': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planLevelMatch, <String, ReasonParamType>{
    'difficulty': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planPrerequisiteMissing, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.planJointLimitation, <String, ReasonParamType>{
    'joint': ReasonParamType.text,
    'discomfort': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planUserLikes, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserDislikes, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserCannotDo, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserAdded, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserRemoved, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserReplaced, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planLockKept, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planGoalSupport, <String, ReasonParamType>{
    'goalId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planVariety, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planReoptimized, <String, ReasonParamType>{
    'scoreBefore': ReasonParamType.number,
    'scoreAfter': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planVariantEasier, <String, ReasonParamType>{
    'difficultyDelta': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planVariantEquivalent, <String, ReasonParamType>{
    'similarity': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planVariantOtherEquipment, <String, ReasonParamType>{
    'equipment': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planStartLoadConservative, <String, ReasonParamType>{
    'fractionOfEstimate': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planToCalibrate, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planWeekKind, <String, ReasonParamType>{
    'kind': ReasonParamType.text,
  }),
  ReasonSpec(
    ReasonCodes.planProgressionFromPreviousBlock,
    <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId},
  ),
  ReasonSpec(ReasonCodes.planAdaptationApplied, <String, ReasonParamType>{
    'proposalKind': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planCautiousHealth, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planRestructureScope, <String, ReasonParamType>{
    'scope': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptFlamesBelowTarget, <String, ReasonParamType>{
    'delta': ReasonParamType.number,
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptFlamesAboveTarget, <String, ReasonParamType>{
    'delta': ReasonParamType.number,
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptSetFailed, <String, ReasonParamType>{
    'missingReps': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptLoadUp, <String, ReasonParamType>{
    'deltaKg': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptLoadDown, <String, ReasonParamType>{
    'deltaKg': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptRepsUp, <String, ReasonParamType>{
    'delta': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptRepsDown, <String, ReasonParamType>{
    'delta': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptVolumeUp, <String, ReasonParamType>{
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptVolumeDown, <String, ReasonParamType>{
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptCalibration, <String, ReasonParamType>{
    'session': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptEstimateUpdated, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'capacity': ReasonParamType.number,
    'standardError': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptLowConfidence, <String, ReasonParamType>{
    'confidence': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptUnlockLevel, <String, ReasonParamType>{
    'level': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptHealthLow, <String, ReasonParamType>{
    'overall': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptSleepLow, <String, ReasonParamType>{
    'sleepQuality': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptTimeShort, <String, ReasonParamType>{
    'minutesAvailable': ReasonParamType.integer,
    'minutesPlanned': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptPainReported, <String, ReasonParamType>{
    'zone': ReasonParamType.text,
    'intensity': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptPainPersistent, <String, ReasonParamType>{
    'zone': ReasonParamType.text,
    'sessions': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptFatigueHigh, <String, ReasonParamType>{
    'readiness': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptDeload, <String, ReasonParamType>{
    'weekIndex': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptPlateau, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'weeks': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptExerciseSkipped, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'times': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptMissedSessions, <String, ReasonParamType>{
    'missed': ReasonParamType.integer,
    'planned': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptResumeAfterBreak, <String, ReasonParamType>{
    'days': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptNoRating, <String, ReasonParamType>{
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questXpEffort, <String, ReasonParamType>{
    'sets': ReasonParamType.integer,
    'capped': ReasonParamType.flag,
  }),
  ReasonSpec(ReasonCodes.questXpConsistency, <String, ReasonParamType>{
    'weeks': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questXpRecord, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'recordKind': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questXpMilestone, <String, ReasonParamType>{
    'goalId': ReasonParamType.text,
    'fraction': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.questXpQuest, <String, ReasonParamType>{
    'questId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questLevelUp, <String, ReasonParamType>{
    'level': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questPrestige, <String, ReasonParamType>{
    'prestige': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questRankUp, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'tier': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questWeakPoint, <String, ReasonParamType>{
    'attribute': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questCampaignChapter, <String, ReasonParamType>{
    'blockIndex': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questGoalSuggested, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.questPredictionUpdated, <String, ReasonParamType>{
    'goalId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptRatingsUninformative, <String, ReasonParamType>{
    'confirmRate': ReasonParamType.number,
    'sets': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptBenchmarkSet, <String, ReasonParamType>{
    'rir': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptPlaceChanged, <String, ReasonParamType>{
    'place': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptLoadHeld, <String, ReasonParamType>{
    'cause': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptIncrementCoarse, <String, ReasonParamType>{
    'stepKg': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptReadiness, <String, ReasonParamType>{
    'readiness': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptVolumeResponse, <String, ReasonParamType>{
    'muscle': ReasonParamType.text,
    'weeklySets': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptLoadFloor, <String, ReasonParamType>{
    'minKg': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.questNoRewardPain, <String, ReasonParamType>{
    'zone': ReasonParamType.text,
    'intensity': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questXpCapped, <String, ReasonParamType>{
    'scope': ReasonParamType.text,
    'cap': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questCombo, <String, ReasonParamType>{
    'length': ReasonParamType.integer,
    'bonus': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questSessionGrade, <String, ReasonParamType>{
    'completion': ReasonParamType.number,
    'accuracy': ReasonParamType.number,
    'records': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questDaily, <String, ReasonParamType>{
    'dayKind': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questWeekly, <String, ReasonParamType>{
    'planned': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questCampaignBoss, <String, ReasonParamType>{
    'blockIndex': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questLaggingExercise, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.questWeekdayFocus, <String, ReasonParamType>{
    'weekday': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questXpRest, <String, ReasonParamType>{
    'days': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questStreak, <String, ReasonParamType>{
    'weeks': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.questStreakPaused, <String, ReasonParamType>{
    'cause': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questChest, <String, ReasonParamType>{
    'guaranteed': ReasonParamType.flag,
  }),
  ReasonSpec(ReasonCodes.questGoalLate, <String, ReasonParamType>{
    'goalId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questFirstTime, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.questGhostBeaten, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'reference': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.questStartBonus, <String, ReasonParamType>{
    'sessions': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planSeasonPhase, <String, ReasonParamType>{
    'phase': ReasonParamType.text,
    'weeksToEvent': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planTaper, <String, ReasonParamType>{
    'volumeFactor': ReasonParamType.number,
    'daysToEvent': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planPeakEvent, <String, ReasonParamType>{
    'eventId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planUndulation, <String, ReasonParamType>{
    'stress': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planTechnique, <String, ReasonParamType>{
    'technique': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planTechniqueWithheld, <String, ReasonParamType>{
    'technique': ReasonParamType.text,
    'cause': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planSpecialization, <String, ReasonParamType>{
    'target': ReasonParamType.text,
    'weeks': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planMaintenanceVolume, <String, ReasonParamType>{
    'muscle': ReasonParamType.text,
    'weeklySets': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planSkillStep, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'stepIndex': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planSkillPlateau, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.planRecentLoad, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'sessions': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planTestScheduled, <String, ReasonParamType>{
    'testKind': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planBenchmarkUsed, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'source': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planPercentBased, <String, ReasonParamType>{
    'pct': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.planRecoveryProfile, <String, ReasonParamType>{
    'factor': ReasonParamType.text,
    'level': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planConstraintHistory, <String, ReasonParamType>{
    'zone': ReasonParamType.text,
    'since': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planConcurrentSport, <String, ReasonParamType>{
    'sport': ReasonParamType.text,
    'sessions': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.planTrainingAge, <String, ReasonParamType>{
    'band': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planReturnFromGap, <String, ReasonParamType>{
    'gap': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planWeakPoint, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'kind': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.planEventSpecific, <String, ReasonParamType>{
    'eventId': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptBackoffFromTopSet, <String, ReasonParamType>{
    'topLoadKg': ReasonParamType.number,
    'pct': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptRirCap, <String, ReasonParamType>{
    'rir': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptTestResult, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'value': ReasonParamType.number,
    'standardError': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptSkillStepUp, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.adaptSkillStepDown, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
  }),
  ReasonSpec(ReasonCodes.adaptSkillHold, <String, ReasonParamType>{
    'exerciseId': ReasonParamType.exerciseId,
    'weeksAtStep': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptPhaseRespected, <String, ReasonParamType>{
    'phase': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptTaperNoVolume, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.adaptEventNear, <String, ReasonParamType>{
    'days': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptAttemptOpener, <String, ReasonParamType>{
    'pct': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptAttemptNext, <String, ReasonParamType>{
    'successProbability': ReasonParamType.number,
  }),
  ReasonSpec(ReasonCodes.adaptAttemptConservative, <String, ReasonParamType>{
    'cause': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptPacing, <String, ReasonParamType>{
    'targetReps': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptRecoveryProfile, <String, ReasonParamType>{
    'factor': ReasonParamType.text,
    'level': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptTendonLoad, <String, ReasonParamType>{
    'zone': ReasonParamType.text,
    'weeks': ReasonParamType.integer,
  }),
  ReasonSpec(ReasonCodes.adaptTechniqueExecuted, <String, ReasonParamType>{
    'technique': ReasonParamType.text,
  }),
  ReasonSpec(ReasonCodes.adaptMiniSetStop, <String, ReasonParamType>{
    'cause': ReasonParamType.text,
  }),
];
