# Journal des versions de kalis_core

## 0.4.0 — 02/10/2026 (lot CQ du pipeline « Calibrage des programmes », évolution additive)

Rien n'est retiré, renommé ni déplacé ; aucune borne ne change ; aucune valeur n'est ajoutée à une énumération
existante (un `switch` exhaustif des moteurs 0.1 ou de l'application continue de compiler). `kalis_plan` 0.1.0,
`kalis_adapt` 0.1.0 et `kalis_quest` 0.1.0 compilent et passent tous leurs tests sans modification. Un JSON de 0.3.0
se relit et se réécrit à l'identique. Additivité vérifiée par un test contre la surface du contrat 0.3.0.

- **Profil d'athlète v3 (schéma 3)** : `AthleteProfile.currentSchemaVersion` vaut 3, le schéma 2 reste lu et valide.
  Champs optionnels : `trainingAge`, `trainingGap`, `sleep`, `stress`, `occupationalLoad`, `otherSports`
  (`OtherSport`), `bodyWeightGoal`, `benchmarks` (`Benchmark`), `events` (`SeasonEvent`), `skills` (`SkillState`),
  `weakPoints` (`WeakPoint`), `specialization` (`Specialization`), `lifestyleUpdatedOn` ; `Limitation.since`,
  `Limitation.aggravatedBy`. Migration sans perte ni invention : `toSchema3()`,
  `migrateAthleteProfileJsonToSchema3`. Revue des facteurs : `docs/PROFIL_V3.md`.
- **Parcours de questions** : `data/parcours_v3.json` et `ProfileQuestionnaire` (`visibleQuestions`,
  `eligibleTests`) ; 8 protocoles de tests guidés ; conversions `estimateOneRm`, `totalFromExternal`,
  `externalFromTotal`, `riegelSeconds`, `trialSpeed`. Écrit pour le lot CU : `docs/PARCOURS_V3.md`. Débutant :
  20 questions (dont 4 nouvelles) ; compétiteur élite street : 28 (dont 11 nouvelles).
- **Prescriptions avancées** : `ExercisePrescription.technique` (`SetTechnique`, 16 techniques à variantes), `tempo`
  (`Tempo`), `intensity` (`IntensityTarget` : part du 1RM, d'un test, du maintien max, étape de progression,
  vitesse ; plafond de RIR), `autoregulation` (`AutoregulationRule`), `test` (`TestSpec`), `dayStress`,
  `skillTargetId` ; `SetTarget.role`, `percentOfOneRm`, `restSeconds` ; journal : `SetRecord.technique`, `role`,
  `miniSetIndex`, `restBeforeSeconds`, `elapsedSeconds`, `rounds`, `quality`, `attemptIndex` ;
  `SessionRecord.eventId`.
- **Périodisation** : `SeasonPlan`, `SeasonPhase`, `SeasonRequest`, interface `SeasonPlanner` ; `Pass1Plan.intent`
  (`BlockIntent`), `WeekPrescription.intent` (`WeekIntent`), `DayPrescription.stress` ; `season` (optionnel) dans
  `PlanRequest`, `NextBlockRequest`, `RestructureRequest`, `AdaptInput`, `BlockProposal`, `Proposal` ;
  `SessionPlan.phase`, `weekIntent`, `eventId` ; `AdaptationSummary.volumeTolerance` (`VolumeTolerance`).
- **Spécialisation et figures** : `Specialization`, `SkillState`, `SkillLadder`, `SkillStep`, `StepCriterion`,
  `SkillProgress` ; `Pass1Plan.skillLadders`, `AdaptationSummary.skills`, `AdaptReview.skillStates`,
  `IntraSessionAdvice.stepExerciseId` ; `Catalog.isProgressionStep`, `progressionCandidates`.
- **Compétition** : `SeasonEvent`, `CompetitionLift`, `EventStation` ; interface `EventDayAdvisor`
  (`EventDayRequest` → `EventDayPlan` : `LiftAttempts`, `AttemptSuggestion`, `AttemptResult`, `PacingSegment`).
- **Résultats de tests** : `AdaptReview.testResults`, `AdaptationSummary.benchmarks` ; `Proposal.detail`
  (`ProposalDetail`) ; `IntraSessionAdvice.miniSetsLeft`.
- 28 énumérations nouvelles (aucune valeur ajoutée aux anciennes), 28 types nouveaux (102 types), 36 codes de raison
  (128 au registre : 19 `plan.*`, 17 `adapt.*`), avec un texte court de Koach proposé pour chacun
  (`docs/RAISONS_0_4.md`).
- Seul changement visible sans rien demander : `AthleteProfile()` construit sans `schemaVersion` écrit le schéma 3.

## 0.3.0 — 02/10/2026 (lot G11, évolution additive)

Rien n'est retiré ni renommé ; une application écrite pour 0.2.0 fonctionne sans changement.

- `SessionRecord.plannedWorkSets` (optionnel) : nombre de séries de travail prescrites pour la séance telle
  qu'elle a été affichée (après ajustement du bilan santé, de la douleur, du lieu, du temps). `kalis_quest`
  s'en sert pour rapporter l'effort au programme : une séance allégée et faite en entier vaut une séance
  complète. Absent : le moteur s'en passe (voir `kalis_quest/CONTRAT.md`).
- `QuestInput.claims` (optionnel) et type `QuestClaim` : quêtes déclaratives (récupération d'un jour de
  repos) que l'utilisateur dit avoir faites.
- `AttributeScore.best` (optionnel) : meilleure valeur atteinte par un attribut.
- `GoalProgress.baseline`, `overdue`, `suggestedDate`, `suggestedTarget`, `reasons` (optionnels) : départ
  de l'objectif, objectif en retard, date ou cible ajustée proposée.
- `DelightKind` : cinq valeurs en fin de liste — `first_time`, `level_up`, `rank_up`, `goal_milestone`,
  `quest_completed`.
- Dix-sept codes de raison pour le moteur de progression (92 codes au registre) : `quest.no_reward_pain`,
  `quest.xp_capped`, `quest.combo`, `quest.session_grade`, `quest.daily`, `quest.weekly`,
  `quest.campaign_boss`, `quest.lagging_exercise`, `quest.weekday_focus`, `quest.xp_rest`, `quest.streak`,
  `quest.streak_paused`, `quest.chest`, `quest.goal_late`, `quest.first_time`, `quest.ghost_beaten`,
  `quest.start_bonus`.

## 0.2.0 — 01/10/2026 (lot G8, évolution additive)

Rien n'est retiré ni renommé ; une application écrite pour 0.1.0 fonctionne sans changement.

- `AdviceRequest.healthCheck` (optionnel) : le bilan santé du jour, tel qu'il a été donné à
  `prescribeSession`, pour que le conseil de la série suivante parte de la même forme du jour.
- Huit codes de raison pour le moteur dynamique (75 codes au registre) : `adapt.ratings_uninformative`,
  `adapt.benchmark_set`, `adapt.place_changed`, `adapt.load_held`, `adapt.increment_coarse`,
  `adapt.readiness`, `adapt.volume_response`, `adapt.load_floor`.

## 0.1.0 — 01/10/2026 (lot GC)

Première livraison : les contrats sont figés ; les évolutions suivantes sont additives.

- Catalogue : base d'exercices v1.1.0 (1 039 exercices) compilée avec ses champs calculés par règles
  (schéma de mouvement, famille, plan, articularité, régime, difficulté, lieux, contraintes
  articulaires, prérequis, coûts de fatigue, type de charge, fraction du poids du corps, unité,
  latéralité, vecteur musculaire) ; `Catalog` : chargement, index, graphe `variante_de`, proximité.
- Contrats : profil d'athlète v2, journal de séances, échelle des flammes, types d'échange et
  interfaces de `plan`, `adapt`, `quest` (73 types, 54 enums), registre de 67 codes de raison ; chaque
  méthode de moteur prend une requête versionnée.
- Jeux de données communs : 40 profils types, 12 journaux synthétiques, programme du propriétaire
  normalisé, ancien journal et sa conversion.
- Simulateur `bin/kalis_core_cli.dart --rapport <dossier>`.
