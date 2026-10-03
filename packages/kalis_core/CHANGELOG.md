# Journal des versions de kalis_core

## 0.4.0 — 03/10/2026 (lot CQ du pipeline « Calibrage des programmes », évolution additive)

Par rapport à 0.3.0, rien n'est retiré, renommé ni déplacé ; aucune borne ne change ; aucune valeur n'est ajoutée à
une énumération d'avant 0.4.0 (un `switch` exhaustif des moteurs 0.1 ou de l'application continue de compiler). Les
énumérations introduites en 0.4.0 sont **ouvertes** : une version mineure pourra leur ajouter des valeurs, leurs
lecteurs prévoient un cas par défaut. Un JSON de 0.3.0 se relit et se réécrit à l'identique. `kalis_plan` 0.1.0,
`kalis_adapt` 0.1.0 et `kalis_quest` 0.1.0 n'ont pas à être modifiés. Additivité contrôlée par un test Python
contre la surface du contrat 0.3.0 (`tool/contract_surface_0_3_0.json`) ; le reste est contrôlé par les tests du
paquet.

Le lot a été relu trois fois de façon indépendante (contrat et code ; parcours vu par un « débutant pressé » ;
parcours et contrat vus par un « coach d'élite ») ; chaque remarque est changée ou expliquée dans
`docs/RELECTURES_CQ.md`. Le 03/10/2026, un quatrième relecteur a audité ces suites contre les sources, et trois
vérificateurs ont recontrôlé les 84 références de `docs/PROFIL_V3.md` (9 corrections). Ce qui suit décrit le contrat
après ces relectures.

- **Profil d'athlète v3 (schéma 3)** : `AthleteProfile.currentSchemaVersion` vaut 3, le schéma 2 reste lu et valide.
  Champs optionnels : `trainingAge`, `trainingGap` (7 tranches), `sleep`, `stress`, `occupationalLoad`, `otherSports`
  (`OtherSport`, dont `mainSport`), `bodyWeightGoal`, `targetBodyWeightKg`, `benchmarks` (`Benchmark`, dont
  `competitionStandard` et la nature `reps_for_time`), `events` (`SeasonEvent`), `skills` (`SkillState`, dont
  `atStepSince`), `weakPoints` (`WeakPoint`), `specialization` (`Specialization`), `recentTraining`
  (`RecentTraining`), `currentPhase`, `emphasis`, `enduranceBase` (`EnduranceBase`), `lifestyleUpdatedOn` ;
  `Limitation.since`, `aggravatedBy` (14 familles de mouvements), `effortDiscomfort`. Migration sans perte ni
  invention : `toSchema3()`, `migrateAthleteProfileJsonToSchema3`. Plusieurs records peuvent porter sur le même
  exercice ; l'étape actuelle d'une figure n'est pas contrôlée par le catalogue. Revue des facteurs :
  `docs/PROFIL_V3.md`.
- **Parcours de questions** : `data/parcours_v3.json` (31 questions : 17 du schéma 2, 14 du schéma 3) et
  `ProfileQuestionnaire` (`visibleQuestions`, `deferredQuestions`, `isDeferred`, `isRequired`, `eligibleTests`) ;
  questions reportées après la première semaine (`deferWhen`) et obligatoires sous condition (`requiredWhen`) ;
  10 protocoles de tests guidés ; conversions `estimateOneRm`, `totalFromExternal`, `externalFromTotal`,
  `riegelSeconds`, `trialSpeed`. Écrit pour le lot CU : `docs/PARCOURS_V3.md`. Questions vues à la création, par
  profil type : débutant en forme générale 16 (aucune nouvelle, 3 reportées ; 16 à 18 selon la discipline) ; intermédiaire musculation 27 (10 nouvelles) ;
  compétiteur élite de streetlifting 29 (12) ; coureuse 28 (11) ; sets & reps avancé 29 (12).
- **Prescriptions avancées** : `ExercisePrescription.technique` (`SetTechnique`, 17 techniques à variantes, dont
  `for_time` ; `lastSetOnly`, `totalSecondsTarget`), `tempo` (`Tempo`), `intensity` (`IntensityTarget` : part du 1RM,
  part d'un test, RIR, part d'une vitesse, lest en part du poids de corps, vitesse ; `value` obligatoire, `eventId`,
  plafond de RIR), `autoregulation` (`AutoregulationRule`, 7 règles dont `stop_on_quality_drop`), `test`
  (`TestSpec`), `dayStress`, `skillTargetId`, `unbroken`, `restMode` ; `SetTarget.role`, `percentOfOneRm`,
  `restSeconds`. `sets` est toujours le nombre de lignes de journal attendues ; les écritures doubles d'une même
  intensité sont contrôlées (`intensity_mismatch`, `set_count`, `reps_mismatch`, `ladder_step`).
- **Groupes d'exercices enchaînés** : `GroupSpec` (7 formats à variantes) dans `DayPrescription.groups` et
  `SessionPlan.groups` ; résultat dans `SessionRecord.groupResults` (`GroupResult`).
- **Journal** : `SetRecord.technique`, `role`, `parts` (`SetPart`), `restBeforeSeconds`, `elapsedSeconds`, `rounds`,
  `quality`, `attemptIndex` ; `SessionRecord.eventId`, `groupResults`. Une série reste **une ligne** : les
  mini-séries d'un cluster, d'un rest-pause, de myo-reps et les paliers d'une dégressive sont ses `parts`. Les
  comptes de séries de `kalis_quest` 0.1.0 et de `kalis_adapt` 0.1.0 restent donc justes.
- **Périodisation** : `SeasonPlan`, `SeasonPhase` (`SeasonPhaseKind`, 10 phases dont `maintenance` et
  `reintroduction` ; `overrides`, `PhaseOverride`), `SeasonRequest`, interface `SeasonPlanner` ; `Pass1Plan.intent`
  (`BlockIntent`), `WeekPrescription.intent` (`WeekIntent`), `DayPrescription.stress` ; `season` (optionnel) dans
  `PlanRequest`, `NextBlockRequest`, `RestructureRequest`, `AdaptInput`, `BlockProposal`, `Proposal` ;
  `SessionPlan.phase`, `weekIntent`, `eventId` ; `AdaptationSummary.volumeTolerance` (`VolumeTolerance`).
- **Spécialisation et figures** : `Specialization`, `SkillState`, `SkillLadder`, `SkillStep`, `StepCriterion`,
  `SkillProgress` ; `Pass1Plan.skillLadders`, `AdaptationSummary.skills`, `AdaptReview.skillStates`,
  `IntraSessionAdvice.stepExerciseId` ; `Catalog.isProgressionStep`, `progressionCandidates`.
- **Compétition** : `SeasonEvent` (une compétition de répétitions n'exige que `mode` ; `dateApproximate`,
  `plannedBodyWeightKg`, `formatKnown`, `heats`, `restBetweenHeatsSeconds`, `elements`, `bestSeconds`,
  `bestTotalReps`, `bestDate`), `CompetitionLift`, `EventStation` (`timeLimitSeconds`, `restAfterSeconds`) ;
  interface `EventDayAdvisor` (`EventDayRequest`, dont `objective` et `targetTotalKg` → `EventDayPlan` :
  `LiftAttempts` et sa montée d'échauffement `warmup` (`WarmupStep`), `AttemptSuggestion`, `AttemptResult` et sa
  cause d'échec `failure`, `PacingSegment` avec `stationIndex` et `round`).
- **Résultats de tests** : `AdaptReview.testResults`, `AdaptationSummary.benchmarks` ; `Proposal.detail`
  (`ProposalDetail`) ; `IntraSessionAdvice.miniSetsLeft`.
- 38 énumérations nouvelles (92 en tout ; aucune valeur ajoutée aux 54 anciennes), 35 types nouveaux (109 types,
  dont 7 à variantes), 38 codes de raison (130 au registre : 21 `plan.*`, dont `plan.skill_plateau` et
  `plan.recent_load`, et 17 `adapt.*`), avec un texte court de Koach proposé pour chacun (`docs/RAISONS_0_4.md`,
  `data/reason_texts_fr_0_4.json`).
- Seul changement visible sans rien demander : `AthleteProfile()` construit sans `schemaVersion` écrit le schéma 3.
  Une application restée en `kalis_core` 0.3.0 refuse un profil au schéma 3 : ne migrer qu'après la mise à jour.

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
