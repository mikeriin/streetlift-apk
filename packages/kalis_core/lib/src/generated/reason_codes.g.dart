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
  static const String planVariantOtherEquipment = 'plan.variant_other_equipment';

  /// Charge de départ prudente.
  static const String planStartLoadConservative = 'plan.start_load_conservative';

  /// Charge à caler sur les premières séances.
  static const String planToCalibrate = 'plan.to_calibrate';

  /// Logique de la semaine (introduction, montée, décharge, test).
  static const String planWeekKind = 'plan.week_kind';

  /// Reprend ou fait progresser un exercice du bloc précédent.
  static const String planProgressionFromPreviousBlock = 'plan.progression_from_previous_block';

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

}

/// Registre des codes de raison et de leurs paramètres typés.
const List<ReasonSpec> reasonRegistry = <ReasonSpec>[
  ReasonSpec(ReasonCodes.planDisciplineShare, <String, ReasonParamType>{'discipline': ReasonParamType.text, 'pct': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planMovementCoverage, <String, ReasonParamType>{'pattern': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planMuscleVolume, <String, ReasonParamType>{'muscle': ReasonParamType.text, 'weeklySets': ReasonParamType.number, 'targetLow': ReasonParamType.number, 'targetHigh': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.planFatigueBalance, <String, ReasonParamType>{'dayIndex': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planTimeBudget, <String, ReasonParamType>{'minutes': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planEquipmentAvailable, <String, ReasonParamType>{'place': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planEquipmentMissing, <String, ReasonParamType>{'equipment': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planLevelMatch, <String, ReasonParamType>{'difficulty': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planPrerequisiteMissing, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId}),
  ReasonSpec(ReasonCodes.planJointLimitation, <String, ReasonParamType>{'joint': ReasonParamType.text, 'discomfort': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planUserLikes, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserDislikes, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserCannotDo, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserAdded, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserRemoved, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planUserReplaced, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planLockKept, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planGoalSupport, <String, ReasonParamType>{'goalId': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planVariety, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planReoptimized, <String, ReasonParamType>{'scoreBefore': ReasonParamType.number, 'scoreAfter': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.planVariantEasier, <String, ReasonParamType>{'difficultyDelta': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.planVariantEquivalent, <String, ReasonParamType>{'similarity': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.planVariantOtherEquipment, <String, ReasonParamType>{'equipment': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planStartLoadConservative, <String, ReasonParamType>{'fractionOfEstimate': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.planToCalibrate, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planWeekKind, <String, ReasonParamType>{'kind': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planProgressionFromPreviousBlock, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId}),
  ReasonSpec(ReasonCodes.planAdaptationApplied, <String, ReasonParamType>{'proposalKind': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.planCautiousHealth, <String, ReasonParamType>{}),
  ReasonSpec(ReasonCodes.planRestructureScope, <String, ReasonParamType>{'scope': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.adaptFlamesBelowTarget, <String, ReasonParamType>{'delta': ReasonParamType.number, 'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptFlamesAboveTarget, <String, ReasonParamType>{'delta': ReasonParamType.number, 'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptSetFailed, <String, ReasonParamType>{'missingReps': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptLoadUp, <String, ReasonParamType>{'deltaKg': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptLoadDown, <String, ReasonParamType>{'deltaKg': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptRepsUp, <String, ReasonParamType>{'delta': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptRepsDown, <String, ReasonParamType>{'delta': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptVolumeUp, <String, ReasonParamType>{'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptVolumeDown, <String, ReasonParamType>{'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptCalibration, <String, ReasonParamType>{'session': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptEstimateUpdated, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId, 'capacity': ReasonParamType.number, 'standardError': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptLowConfidence, <String, ReasonParamType>{'confidence': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptUnlockLevel, <String, ReasonParamType>{'level': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.adaptHealthLow, <String, ReasonParamType>{'overall': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptSleepLow, <String, ReasonParamType>{'sleepQuality': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptTimeShort, <String, ReasonParamType>{'minutesAvailable': ReasonParamType.integer, 'minutesPlanned': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptPainReported, <String, ReasonParamType>{'zone': ReasonParamType.text, 'intensity': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptPainPersistent, <String, ReasonParamType>{'zone': ReasonParamType.text, 'sessions': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptFatigueHigh, <String, ReasonParamType>{'readiness': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptDeload, <String, ReasonParamType>{'weekIndex': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptPlateau, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId, 'weeks': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptExerciseSkipped, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId, 'times': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptMissedSessions, <String, ReasonParamType>{'missed': ReasonParamType.integer, 'planned': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptResumeAfterBreak, <String, ReasonParamType>{'days': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptNoRating, <String, ReasonParamType>{'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.questXpEffort, <String, ReasonParamType>{'sets': ReasonParamType.integer, 'capped': ReasonParamType.flag}),
  ReasonSpec(ReasonCodes.questXpConsistency, <String, ReasonParamType>{'weeks': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.questXpRecord, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId, 'recordKind': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.questXpMilestone, <String, ReasonParamType>{'goalId': ReasonParamType.text, 'fraction': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.questXpQuest, <String, ReasonParamType>{'questId': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.questLevelUp, <String, ReasonParamType>{'level': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.questPrestige, <String, ReasonParamType>{'prestige': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.questRankUp, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId, 'tier': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.questWeakPoint, <String, ReasonParamType>{'attribute': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.questCampaignChapter, <String, ReasonParamType>{'blockIndex': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.questGoalSuggested, <String, ReasonParamType>{'exerciseId': ReasonParamType.exerciseId}),
  ReasonSpec(ReasonCodes.questPredictionUpdated, <String, ReasonParamType>{'goalId': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.adaptRatingsUninformative, <String, ReasonParamType>{'confirmRate': ReasonParamType.number, 'sets': ReasonParamType.integer}),
  ReasonSpec(ReasonCodes.adaptBenchmarkSet, <String, ReasonParamType>{'rir': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptPlaceChanged, <String, ReasonParamType>{'place': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.adaptLoadHeld, <String, ReasonParamType>{'cause': ReasonParamType.text}),
  ReasonSpec(ReasonCodes.adaptIncrementCoarse, <String, ReasonParamType>{'stepKg': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptReadiness, <String, ReasonParamType>{'readiness': ReasonParamType.number}),
  ReasonSpec(ReasonCodes.adaptVolumeResponse, <String, ReasonParamType>{'muscle': ReasonParamType.text, 'weeklySets': ReasonParamType.number}),
];
