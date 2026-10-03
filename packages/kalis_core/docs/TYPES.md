# Types des contrats de kalis_core

Fichier généré par `tool/gen_contracts.py` depuis `tool/contracts_spec.py` — ne pas modifier à la main.

Clé JSON = nom du champ. « Optionnel » : la clé est absente du JSON quand la valeur est nulle (jamais de valeur par défaut). Les types racine portent `schemaVersion`.

## Versions de schéma

| Type | Version |
| --- | ---: |
| `AthleteProfile` | 3 |
| `TrainingLog` | 1 |
| `Pass1Plan` | 1 |
| `Pass2Plan` | 1 |
| `ProgramBlock` | 1 |
| `AdaptationSummary` | 1 |
| `AdaptInput` | 1 |
| `SessionRequest` | 1 |
| `AdviceRequest` | 1 |
| `SessionPlan` | 1 |
| `QuestState` | 1 |
| `QuestInput` | 1 |
| `PlanRequest` | 1 |
| `NextBlockRequest` | 1 |
| `RestructureRequest` | 1 |
| `ReviewRequest` | 1 |
| `VariantsRequest` | 1 |
| `Pass2Request` | 1 |
| `SeasonPlan` | 1 |
| `EventDayRequest` | 1 |
| `EventDayPlan` | 1 |
| `SeasonRequest` | 1 |

## Commun

### `Reason`

Code de raison et ses paramètres (aucun texte : les phrases viennent de kalis_koach et de l'application).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `code` | texte | non | longueur ≥ 1 | Identifiant stable du registre des codes de raison. |
| `params` | objet JSON | non | — | Paramètres typés du code (nombres, chaînes, booléens), écrits par clés triées. |

Invariant : `code` figure au registre ; `params` contient exactement les paramètres déclarés, du bon type.

## Profil d'athlète (schémas 2 et 3)

### `DisciplineShare`

Discipline secondaire et son dosage.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `discipline` | `TrainingDiscipline` | non | — | Discipline. |
| `pct` | entier | non | 1 à 99 | Part en pour cent. |

### `DisciplineMix`

Discipline principale et 0 à 2 secondaires dosées (D3.2).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `primary` | `TrainingDiscipline` | non | — | Discipline principale. |
| `primaryPct` | entier | non | 1 à 100 | Part de la principale, en pour cent. |
| `secondaries` | liste de `DisciplineShare` | non | longueur ≤ 2 | Disciplines secondaires. |

Invariant : Somme des parts = 100 ; disciplines distinctes ; la principale a la plus grande part.

### `StreetMode`

Mode street : une principale parmi trois, les deux autres dosées (D3.3).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `primary` | `StreetStyle` | non | — | Composante principale. |
| `streetliftingPct` | entier | non | 0 à 100 | Part du streetlifting. |
| `setsRepsPct` | entier | non | 0 à 100 | Part du sets & reps. |
| `calisthenicsPct` | entier | non | 0 à 100 | Part de la calisthénie. |

Invariant : Somme = 100 ; la principale a la plus grande part, strictement positive.

### `MovementLevel`

Niveau déclaré sur un mouvement : fourchette ou « je ne sais pas » (D3.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice de référence. |
| `measure` | `LevelMeasure` | non | — | Grandeur déclarée. |
| `known` | booléen | non | — | false = « je ne sais pas » (aucune valeur). |
| `low` | nombre | oui | ≥ 0 | Borne basse de la fourchette. |
| `high` | nombre | oui | ≥ 0 | Borne haute de la fourchette. |
| `distanceMeters` | nombre | oui | ≥ 0 | Distance, pour `time_seconds`. |

Invariant : `known` ⇒ `low` ≤ `high` renseignés ; sinon `low` et `high` absents ; `distanceMeters` seulement pour `time_seconds`.

### `Goal`

Objectif : performance chiffrée datée, ou habitude (D3.8).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `id` | texte | non | longueur ≥ 1 | Identifiant stable de l'objectif. |
| `kind` | `GoalKind` | non | — | Performance ou habitude. |
| `origin` | `GoalOrigin` | non | — | Saisi par l'utilisateur ou suggéré par Koach. |
| `createdOn` | jour civil | non | — | Jour de création. |
| `exerciseId` | texte | oui | id du catalogue | Exercice visé (performance). |
| `metric` | `GoalMetric` | oui | — | Grandeur visée (performance). |
| `targetValue` | nombre | oui | ≥ 0 | Valeur cible, dans l'unité de `metric` (charge EXTERNE pour `one_rm_kg` ; absente pour `skill_unlocked`). |
| `distanceMeters` | nombre | oui | ≥ 0 | Distance de référence pour `time_seconds`. |
| `loadKg` | nombre | oui | ≥ 0 | Charge externe de référence pour `max_reps` (« 38 répétitions à 70 kg »). |
| `durationSeconds` | entier | oui | ≥ 1 | Durée de référence pour `distance_meters`. |
| `targetDate` | jour civil | oui | — | Échéance (performance). |
| `sessionsPerWeek` | entier | oui | 1 à 14 | Séances par semaine (habitude). |
| `weeks` | entier | oui | 1 à 104 | Durée en semaines (habitude). |

Invariant : Performance : `exerciseId`, `metric`, `targetDate` renseignés, champs d'habitude absents. Habitude : `sessionsPerWeek` et `weeks` renseignés, champs de performance absents.

### `DaySlot`

Disponibilité d'un jour précis (D3.6).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `weekday` | entier | non | 1 à 7 | Jour ISO : 1 = lundi … 7 = dimanche. |
| `minutes` | entier | non | 10 à 300 | Durée disponible, en minutes. |
| `place` | `Place` | oui | — | Lieu de ce jour-là (absent : n'importe quel lieu du profil). |

### `PlaceEquipment`

Matériel disponible dans un lieu.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `place` | `Place` | non | — | Lieu. |
| `equipment` | liste de texte | non | — | Matériel disponible dans ce lieu (vocabulaire `materiel` de la base). |

### `LoadIncrement`

Plus petit pas de charge disponible pour un type de charge.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `loadType` | `LoadType` | non | — | Type de charge. |
| `stepKg` | nombre | non | 0.05 à 50 | Pas de charge, en kg. |
| `minKg` | nombre | oui | ≥ 0 | Plus petite charge disponible, en kg. |

### `Limitation`

Blessure ou limitation déclarée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `zone` | `BodyZone` | non | — | Zone du corps. |
| `side` | `BodySide` | non | — | Côté. |
| `joint` | `Joint` | oui | — | Articulation concernée, si la zone en désigne une. |
| `discomfort` | entier | non | 0 à 10 | Gêne de 0 à 10. |
| `since` | `ConstraintSince` | oui | — | Depuis quand (0.4.0). Une gêne décrit une contrainte d'entraînement, jamais un diagnostic. |
| `aggravatedBy` | liste de `AggravatingMovement` | oui | longueur ≤ 14 | Familles de mouvements qui la réveillent (0.4.0). |
| `effortDiscomfort` | entier | oui | 0 à 10 | Gêne au plus fort pendant l'effort, de 0 à 10 (0.4.0) ; `discomfort` reste la gêne du moment. |

Invariant : `aggravatedBy` sans doublon.

### `HealthScreeningRef`

Référence au questionnaire santé L13 (aucune réponse n'est copiée ici).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `questionnaireId` | texte | non | longueur ≥ 1 | Identifiant et version du questionnaire. |
| `answeredOn` | jour civil | oui | — | Jour de réponse. |
| `outcome` | `HealthScreeningOutcome` | non | — | Résultat : standard, mode prudent, non répondu. |

### `AthleteProfile`

Profil d'athlète (D3). Schéma 3 depuis 0.4.0 : le schéma 2 reste lu tel quel ; les champs du schéma 3 sont tous optionnels.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 2 | Version du schéma (2 ou 3). |
| `displayName` | texte | oui | longueur ≤ 40 | Prénom ou pseudo, facultatif. |
| `sex` | `Sex` | non | — | Sexe déclaré. |
| `birthYear` | entier | non | 1900 à 2100 | Année de naissance. |
| `heightCm` | entier | non | 100 à 250 | Taille en centimètres. |
| `bodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps en kg, facultatif. |
| `disciplines` | `DisciplineMix` | non | — | Disciplines et dosages. |
| `streetMode` | `StreetMode` | oui | — | Mode street, s'il est activé. |
| `movementLevels` | liste de `MovementLevel` | non | — | Niveaux déclarés par mouvement. |
| `goals` | liste de `Goal` | non | — | Objectifs. |
| `availability` | liste de `DaySlot` | non | longueur 1 à 7 | Jours et durées disponibles. |
| `places` | liste de `Place` | non | longueur 1 à 3 | Lieux d'entraînement. |
| `equipment` | liste de texte | non | — | Matériel disponible, tous lieux confondus (vocabulaire `materiel` de la base). |
| `equipmentByPlace` | liste de `PlaceEquipment` | oui | — | Matériel par lieu, quand il diffère d'un lieu à l'autre (absent : `equipment` vaut partout). |
| `loadIncrements` | liste de `LoadIncrement` | non | — | Incréments de charge par type de charge. |
| `limitations` | liste de `Limitation` | non | — | Blessures et limitations. |
| `likedExerciseIds` | liste de texte | non | id du catalogue | Exercices aimés. |
| `dislikedExerciseIds` | liste de texte | non | id du catalogue | Exercices détestés. |
| `knownExerciseIds` | liste de texte | oui | id du catalogue | Exercices que l'utilisateur a dit savoir faire (revue, D4.5). |
| `cannotDoExerciseIds` | liste de texte | oui | id du catalogue | Exercices que l'utilisateur a dit ne pas savoir faire (revue, D4.5). |
| `experience` | `ExperienceLevel` | oui | — | Niveau global d'expérience déclaré. |
| `guidanceMode` | `GuidanceMode` | non | — | Mode assisté ou libre. |
| `healthScreening` | `HealthScreeningRef` | oui | — | Référence au questionnaire santé. |
| `createdOn` | jour civil | non | — | Jour de création du profil. |
| `updatedOn` | jour civil | non | — | Jour de dernière modification. |
| `trainingAge` | `TrainingAge` | oui | — | Ancienneté de pratique régulière de la discipline principale (schéma 3). |
| `trainingGap` | `TrainingGap` | oui | — | Interruption en cours au moment de répondre (schéma 3) ; ensuite, les coupures se lisent dans le journal. |
| `sleep` | `SleepBand` | oui | — | Durée habituelle de sommeil (schéma 3). |
| `stress` | `StressBand` | oui | — | Stress habituel de la vie hors entraînement (schéma 3). |
| `occupationalLoad` | `OccupationalLoad` | oui | — | Charge physique habituelle du métier ou des journées (schéma 3). |
| `otherSports` | liste de `OtherSport` | oui | longueur ≤ 6 | Autres sports réguliers (schéma 3). Absent : question non posée ou passée ; liste vide : aucun. |
| `bodyWeightGoal` | `BodyWeightGoal` | oui | — | Évolution voulue du poids de corps en ce moment (schéma 3). |
| `benchmarks` | liste de `Benchmark` | oui | longueur ≤ 200 | Tests et records connus (schéma 3). Absent : question non posée ou passée. |
| `events` | liste de `SeasonEvent` | oui | longueur ≤ 20 | Compétitions et tests datés (schéma 3). Absent : question non posée ou passée ; liste vide : aucune échéance. |
| `skills` | liste de `SkillState` | oui | longueur ≤ 30 | Figures visées et étape actuelle, par ordre de priorité (schéma 3). |
| `weakPoints` | liste de `WeakPoint` | oui | longueur ≤ 30 | Points faibles déclarés (schéma 3). |
| `specialization` | `Specialization` | oui | — | Priorité voulue par l'utilisateur (schéma 3). |
| `recentTraining` | liste de `RecentTraining` | oui | longueur ≤ 12 | Charge d'entraînement actuelle par mouvement ou figure (schéma 3). |
| `currentPhase` | `CurrentPhase` | oui | — | Ce que l'utilisateur fait en ce moment (schéma 3). |
| `emphasis` | `TrainingEmphasis` | oui | — | Ce qu'il cherche surtout en musculation (schéma 3). |
| `enduranceBase` | `EnduranceBase` | oui | — | Volume de course actuel (schéma 3). |
| `targetBodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps visé, en kg, quand `bodyWeightGoal` vaut `lose` ou `gain` (schéma 3). |
| `lifestyleUpdatedOn` | jour civil | oui | — | Jour de la dernière réponse aux questions de récupération et de vie (sommeil, stress, métier, autres sports, poids, charge actuelle) (schéma 3) : elles se redemandent de temps en temps. |

Invariant : Jours de `availability` distincts ; lieux, matériel, exercices aimés et détestés sans doublon ; aimés ∩ détestés = ∅.

Invariant : Un seul incrément par type de charge ; `updatedOn` ≥ `createdOn`.

Invariant : Mode street activé ⇒ `disciplines` est l'image du mode street (`StreetMode.toDisciplineMix()`).

Invariant : `equipmentByPlace` : un lieu au plus une fois, parmi `places`, matériel inclus dans `equipment` ; `DaySlot.place` parmi `places` ; su ∩ pas su = ∅.

Invariant : Un champ du schéma 3 renseigné ⇒ `schemaVersion` ≥ 3 ; identifiants d'`events` distincts ; figures visées de `skills` distinctes ; mouvements de `recentTraining` distincts ; les `goalIds` d'une échéance sont des objectifs du profil ; `targetBodyWeightKg` seulement avec `bodyWeightGoal` `lose` ou `gain` ; `weakPoints` distincts (mouvement et nature) ; `lifestyleUpdatedOn` ≥ `createdOn`.

### `OtherSport`

Autre sport pratiqué régulièrement en plus du programme (0.4.0). Sert à placer les séances (pas de coefficient de volume).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `OtherSportKind` | non | — | Sport. |
| `sessionsPerWeek` | entier | non | 1 à 14 | Séances par semaine. |
| `minutesPerSession` | entier | non | 10 à 600 | Durée habituelle d'une séance, en minutes. |
| `weekdays` | liste de entier | oui | longueur ≤ 7 | Jours ISO habituels (1 = lundi … 7 = dimanche), s'ils sont fixes. |
| `regions` | liste de `BodyRegion` | oui | longueur ≤ 5 | Régions sollicitées, quand le sport ne suffit pas à le dire (tous sauf course, vélo, natation, escalade). |
| `hard` | booléen | oui | — | Séances intenses (fractionné, matchs, combats). |
| `mainSport` | booléen | oui | — | C'est le sport principal de l'utilisateur : le programme passe après lui. |

Invariant : `weekdays` : jours de 1 à 7, distincts ; `regions` distinctes.

### `RecentTraining`

Ce que l'utilisateur fait aujourd'hui sur un mouvement ou une figure (0.4.0) : sert à caler le premier bloc sur sa charge réelle.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement ou figure. |
| `sessionsPerWeek` | entier | non | 0 à 14 | Séances par semaine où il est travaillé (0 : pas en ce moment). |
| `hardSets` | `HardSetsBand` | oui | — | Séries dures par semaine sur ce mouvement. |

### `EnduranceBase`

Volume de course actuel (0.4.0) : sert à caler le premier bloc d'un coureur.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `weeklyVolume` | `RunVolumeBand` | non | — | Distance par semaine, en moyenne sur les 4 dernières semaines. |
| `sessionsPerWeek` | entier | non | 0 à 14 | Sorties par semaine. |
| `longRun` | `LongRunBand` | oui | — | Plus longue sortie récente. |

### `Benchmark`

Test ou record sur un exercice (0.4.0) : valeur exacte, datée, avec son origine. Convention de charge : EXTERNE, comme l'utilisateur la lit (lest seul pour un exercice lesté).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `kind` | `BenchmarkKind` | non | — | Nature. |
| `source` | `BenchmarkSource` | non | — | Origine. |
| `date` | jour civil | oui | — | Jour du test ou du record (absent : inconnu). |
| `externalLoadKg` | nombre | oui | -300 à 1000 | Charge externe, en kg (0 : sans charge ; négative : assistance). |
| `reps` | entier | oui | 1 à 1000 | Répétitions réalisées. |
| `rir` | nombre | oui | 0 à 10 | Répétitions en réserve déclarées à la fin de la série (0 : série au maximum ; absent : inconnu). |
| `seconds` | entier | oui | 1 à 86400 | Durée, en secondes (maintien, temps réalisé, durée imposée). |
| `distanceMeters` | nombre | oui | ≥ 1 | Distance, en mètres. |
| `bodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps le jour du test, en kg (exercices au poids du corps ou lestés). |
| `protocolId` | texte | oui | longueur 1 à 40 | Protocole de test guidé suivi (`docs/PARCOURS_V3.md`, § tests guidés). |
| `competitionStandard` | booléen | oui | — | Fait au standard de compétition (amplitude complète, arrêts marqués) ; absent : inconnu. Les tentatives ne se fondent que sur des records au standard. |

Invariant : `load_reps` : charge externe et répétitions (1 répétition, RIR 0 = maximum mesuré) ; `max_reps` : répétitions (charge externe si l'épreuve est lestée, durée si elle est limitée en temps) ; `max_hold` : secondes ; `time_trial`, `distance_trial` : distance et durée ; `reps_for_time` : répétitions imposées et temps réalisé.

Variantes selon `kind` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `load_reps` | `externalLoadKg`, `reps` | `rir` |
| `max_reps` | `reps` | `externalLoadKg`, `seconds` |
| `max_hold` | `seconds` | `externalLoadKg` |
| `time_trial` | `distanceMeters`, `seconds` | — |
| `distance_trial` | `distanceMeters`, `seconds` | — |
| `reps_for_time` | `reps`, `seconds` | `externalLoadKg` |

### `WeakPoint`

Point faible déclaré sur un mouvement (0.4.0). Sert à choisir les exercices d'assistance ; ce n'est pas une douleur (voir `Limitation`).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement concerné. |
| `kind` | `WeakPointKind` | non | — | Où ça bloque. |

## Journal

### `PainReport`

Douleur signalée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `zone` | `BodyZone` | non | — | Zone. |
| `side` | `BodySide` | non | — | Côté. |
| `joint` | `Joint` | oui | — | Articulation, si la zone en désigne une. |
| `intensity` | entier | non | 0 à 10 | Intensité de 0 à 10. |
| `phase` | `PainPhase` | non | — | Avant, pendant ou après la séance. |
| `exerciseId` | texte | oui | id du catalogue | Exercice pendant lequel elle est apparue. |

### `HealthCheck`

Bilan santé de début de séance (D5.8). Chaque question est facultative : une réponse absente reste absente (aucune valeur par défaut). Échelles de 1 à 5 : 5 = état le plus favorable.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `overall` | entier | oui | 1 à 5 | « Comment tu te sens ? » |
| `sleepQuality` | entier | oui | 1 à 5 | Qualité du sommeil. |
| `sleepHours` | nombre | oui | 0 à 24 | Heures de sommeil. |
| `energy` | entier | oui | 1 à 5 | Énergie. |
| `mood` | entier | oui | 1 à 5 | Humeur. |
| `soreness` | entier | oui | 1 à 5 | Courbatures (5 = aucune). |
| `stress` | entier | oui | 1 à 5 | Stress (5 = aucun). |
| `motivation` | entier | oui | 1 à 5 | Motivation. |
| `nutrition` | entier | oui | 1 à 5 | Alimentation. |
| `hydration` | entier | oui | 1 à 5 | Hydratation. |
| `minutesAvailable` | entier | oui | 0 à 600 | Temps disponible aujourd'hui, en minutes. |
| `pains` | liste de `PainReport` | oui | — | Douleurs localisées (absent : question non posée ou sans réponse ; liste vide : aucune douleur). |

### `SetTarget`

Cible prescrite d'une série, telle qu'elle était affichée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `repsLow` | entier | oui | 0 à 1000 | Bas de la plage de répétitions. |
| `repsHigh` | entier | oui | 0 à 1000 | Haut de la plage de répétitions. |
| `secondsLow` | entier | oui | 0 à 86400 | Bas de la plage de temps, en secondes. |
| `secondsHigh` | entier | oui | 0 à 86400 | Haut de la plage de temps, en secondes. |
| `distanceMeters` | nombre | oui | ≥ 0 | Distance visée, en mètres. |
| `calories` | nombre | oui | ≥ 0 | Calories visées. |
| `loadKg` | nombre | oui | -300 à 1000 | Charge externe prescrite, en kg (même convention que `SetRecord.externalLoadKg`). |
| `flames` | entier | oui | 1 à 10 | Flammes visées. |
| `role` | `SetRole` | oui | — | Rôle de la série dans la technique (0.4.0). |
| `percentOfOneRm` | nombre | oui | 0 à 1.5 | Charge de la série, en part du 1RM de charge totale (0.4.0). |
| `restSeconds` | entier | oui | 0 à 900 | Repos après la série, en secondes (0.4.0). |

Invariant : Bornes basses ≤ bornes hautes quand les deux sont renseignées.

### `SetRecord`

Série réalisée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `exerciseOrder` | entier | non | ≥ 0 | Rang de l'exercice dans la séance (0 = premier). |
| `setIndex` | entier | non | ≥ 0 | Rang de la série dans l'exercice (0 = première). |
| `kind` | `SetKind` | non | — | Rôle de la série. |
| `externalLoadKg` | nombre | oui | -300 à 1000 | Charge externe en kg, telle que l'utilisateur la lit : barre et disques compris ; par haltère ou par kettlebell ; valeur affichée d'une machine ou d'une poulie ; lest seul pour un exercice lesté (le poids du corps n'y est jamais ajouté) ; négative = assistance ; absente = aucune. |
| `reps` | entier | oui | 0 à 1000 | Répétitions réalisées (par côté pour un exercice unilatéral). |
| `seconds` | entier | oui | 0 à 86400 | Durée réalisée, en secondes (par côté pour un exercice unilatéral). |
| `distanceMeters` | nombre | oui | ≥ 0 | Distance réalisée, en mètres. |
| `calories` | nombre | oui | ≥ 0 | Calories réalisées. |
| `flames` | entier | oui | 1 à 10 | Note de difficulté de 1 à 10 flammes ; absente = « pas de note ». |
| `success` | booléen | non | — | La série a atteint sa cible. |
| `excluded` | booléen | non | — | Série écartée (incident), gardée au journal, ignorée des moteurs. |
| `slotId` | texte | oui | — | Emplacement du programme dont vient la série. |
| `side` | `BodySide` | oui | — | Côté travaillé (exercice unilatéral) : `both` = une série par côté, comptée une fois ; `left` ou `right` = un seul côté. |
| `target` | `SetTarget` | oui | — | Cible prescrite. |
| `technique` | `SetTechniqueKind` | oui | — | Technique de la série (0.4.0). |
| `role` | `SetRole` | oui | — | Rôle de la série dans la technique (0.4.0). |
| `parts` | liste de `SetPart` | oui | longueur 1 à 120 | Détail de la série (0.4.0) : mini-séries d'un cluster, d'un rest-pause, de myo-reps, paliers d'une dégressive, passages d'un bloc de densité. La série reste une seule ligne ; `reps` (ou `seconds`) en est le total. |
| `restBeforeSeconds` | entier | oui | 0 à 3600 | Repos pris avant la série, en secondes (0.4.0). |
| `elapsedSeconds` | entier | oui | 0 à 86400 | Temps écoulé depuis le début du bloc chronométré, en secondes (AMRAP, EMOM, densité, épreuve pour le temps) (0.4.0). |
| `rounds` | entier | oui | 0 à 1000 | Tours complets réalisés (AMRAP, circuit) (0.4.0). |
| `quality` | entier | oui | 1 à 5 | Propreté déclarée de 1 à 5 (5 = parfaite) pour une figure ou un maintien (0.4.0) ; absente = non notée. |
| `attemptIndex` | entier | oui | 0 à 3 | Rang de la tentative de compétition (0 = ouverture) (0.4.0). |

Invariant : Au moins une mesure parmi `reps`, `seconds`, `distanceMeters`, `calories`.

Invariant : (0.4.0) Quand toutes les `parts` ont des répétitions, leur somme vaut `reps`.

### `TrainingBreak`

Pause déclarée (vacances, maladie…) : ni manquement ni perte de série.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `startDate` | jour civil | non | — | Premier jour de la pause. |
| `endDate` | jour civil | oui | — | Dernier jour de la pause (absent : en cours). |
| `reason` | `BreakReason` | non | — | Motif. |

Invariant : `startDate` ≤ `endDate`.

### `ProgramRef`

Place d'une séance dans le programme.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `blockId` | texte | non | longueur ≥ 1 | Identifiant du bloc. |
| `weekIndex` | entier | non | ≥ 0 | Semaine dans le bloc (0 = première). |
| `dayIndex` | entier | non | ≥ 0 | Rang du jour dans la semaine du bloc, celui de `DayPrescription.dayIndex` (0 = premier). |

### `SessionRecord`

Séance du journal. Dates en jours civils.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `id` | texte | non | longueur ≥ 1 | Identifiant unique de la séance. |
| `date` | jour civil | non | — | Jour civil de la séance. |
| `origin` | `SessionOrigin` | non | — | Origine. |
| `programRef` | `ProgramRef` | oui | — | Place dans le programme. |
| `resume` | booléen | non | — | Marqueur « reprise » (D4.9) : séance neutre, ignorée des moteurs (ni XP, ni statistiques, ni série, ni records). |
| `completed` | booléen | non | — | Séance terminée. |
| `durationMinutes` | entier | oui | 0 à 600 | Durée de la séance, en minutes. |
| `bodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps du jour, en kg. |
| `place` | `Place` | oui | — | Lieu de la séance. |
| `healthCheck` | `HealthCheck` | oui | — | Bilan santé de début de séance. |
| `sets` | liste de `SetRecord` | non | — | Séries, dans l'ordre de réalisation. |
| `pains` | liste de `PainReport` | non | — | Douleurs signalées pendant ou après la séance. |
| `plannedWorkSets` | entier | oui | 0 à 500 | Nombre de séries de travail prescrites pour cette séance, telle qu'elle a été affichée (après l'ajustement du bilan santé, de la douleur, du lieu et du temps du jour) (0.3.0). Sert à `kalis_quest` pour rapporter l'effort au programme : une séance allégée et faite en entier vaut une séance complète. |
| `eventId` | texte | oui | longueur ≥ 1 | Échéance du profil dont cette séance est le jour (0.4.0). |
| `groupResults` | liste de `GroupResult` | oui | longueur ≤ 20 | Résultats des groupes d'exercices enchaînés (0.4.0). |

Invariant : (0.4.0) Un résultat au plus par groupe (`groupResults` : `groupId` distincts).

### `TrainingLog`

Journal de séances.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `sessions` | liste de `SessionRecord` | non | — | Séances, par date croissante. |
| `breaks` | liste de `TrainingBreak` | oui | — | Pauses déclarées. |

Invariant : Identifiants de séance uniques ; dates croissantes (au sens large).

### `GroupResult`

Résultat d'un groupe d'exercices enchaînés (0.4.0) : temps total, tours, répétitions en plus.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `groupId` | texte | non | longueur ≥ 1 | Groupe (`GroupSpec.groupId`). |
| `completed` | booléen | non | — | Le groupe a été fait en entier (dans la limite de temps, s'il y en a une). |
| `elapsedSeconds` | entier | oui | 0 à 86400 | Temps total, en secondes. |
| `rounds` | entier | oui | 0 à 1000 | Tours complets. |
| `extraReps` | entier | oui | 0 à 10000 | Répétitions faites dans le tour entamé. |

### `SetPart`

Partie d'une série (0.4.0) : mini-série d'un cluster, d'un rest-pause ou de myo-reps, palier d'une dégressive, passage d'un bloc de densité. La série reste UNE ligne du journal (`SetRecord`), dont `reps` est le total.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `reps` | entier | oui | 0 à 1000 | Répétitions de la partie. |
| `seconds` | entier | oui | 0 à 86400 | Durée de la partie, en secondes. |
| `externalLoadKg` | nombre | oui | -300 à 1000 | Charge externe de la partie, si elle diffère de celle de la série (dégressive). |
| `restBeforeSeconds` | entier | oui | 0 à 3600 | Repos pris avant la partie, en secondes. |

Invariant : Au moins `reps` ou `seconds`. Quand toutes les parties d'une série ont des répétitions, leur somme est le `reps` de la série (`SetRecord`).

## Interface `plan` (kalis_plan) et prescriptions

### `PlanLock`

Verrou : ce que la revue a figé (D4.6).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `LockKind` | non | — | Nature du verrou. |
| `dayIndex` | entier | oui | ≥ 0 | Jour concerné. |
| `slotId` | texte | oui | — | Emplacement concerné. |
| `exerciseId` | texte | oui | id du catalogue | Exercice concerné. |

Invariant : `keep_slot` : `slotId` et `exerciseId` ; `require_exercise`, `exclude_exercise` : `exerciseId` ; `keep_day` : `dayIndex`.

### `PlanSlot`

Exercice placé dans une séance (passe 1).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `slotId` | texte | non | longueur ≥ 1 | Identifiant stable de l'emplacement dans le bloc. |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `role` | `SlotRole` | non | — | Rôle dans la séance. |
| `locked` | booléen | non | — | Validé par l'utilisateur : ne bouge plus. |
| `reasons` | liste de `Reason` | non | — | Pourquoi cet exercice. |

### `PlanDay`

Séance type d'un jour d'entraînement (passe 1).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `dayIndex` | entier | non | ≥ 0 | Rang du jour d'entraînement dans la semaine (0 = premier). |
| `weekday` | entier | non | 1 à 7 | Jour ISO : 1 = lundi … 7 = dimanche. |
| `minutesBudget` | entier | non | 0 à 300 | Durée prévue, en minutes. |
| `focus` | texte | non | — | Code du thème de la séance. |
| `slots` | liste de `PlanSlot` | non | — | Exercices, dans l'ordre. |

### `ScoreComponent`

Composante de la note d'un programme (D4.2).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `code` | texte | non | longueur ≥ 1 | Code de la composante. |
| `value` | nombre | non | 0 à 1 | Valeur, de 0 à 1. |
| `weight` | nombre | non | ≥ 0 | Poids dans la note. |

### `PlanScore`

Note d'un programme candidat.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `total` | nombre | non | 0 à 1 | Note globale, de 0 à 1. |
| `components` | liste de `ScoreComponent` | non | — | Détail. |

### `Pass1Plan`

Passe 1 : le bloc, ses jours, ses exercices et leurs rôles, sans séries ni répétitions (D4.4). C'est la semaine type du bloc ; la passe 2 fait foi semaine par semaine.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `blockId` | texte | non | longueur ≥ 1 | Identifiant du bloc. |
| `blockIndex` | entier | non | ≥ 0 | Rang du bloc dans le programme (0 = premier). |
| `weeks` | entier | non | 1 à 52 | Durée du bloc, en semaines. `kalis_plan` produit des blocs de 4 à 6 semaines (D4.8) ; un programme importé (celui du propriétaire, D5.10) peut en compter jusqu'à 52. |
| `startDate` | jour civil | non | — | Premier jour du bloc. |
| `seed` | entier | non | ≥ 0 | Graine utilisée. |
| `engineVersion` | texte | non | — | Version de kalis_plan. |
| `days` | liste de `PlanDay` | non | — | Jours d'entraînement. |
| `score` | `PlanScore` | non | — | Note du programme retenu. |
| `reasons` | liste de `Reason` | non | — | Raisons au niveau du bloc. |
| `intent` | `BlockIntent` | oui | — | Intention du bloc : sa place dans la saison (0.4.0). |
| `skillLadders` | liste de `SkillLadder` | oui | longueur ≤ 30 | Échelles de progression des figures travaillées dans le bloc (0.4.0). |

Invariant : `dayIndex` = rang dans `days` ; `slotId` uniques dans le bloc.

### `ReviewAction`

Action de revue de la passe 1 (D4.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `ReviewKind` | non | — | Action. |
| `slotId` | texte | oui | — | Emplacement visé. |
| `dayIndex` | entier | oui | ≥ 0 | Jour visé (ajout). |
| `exerciseId` | texte | oui | id du catalogue | Exercice ajouté. |
| `replacementExerciseId` | texte | oui | id du catalogue | Variante choisie (remplacement). |

Invariant : `can_do`, `cannot_do`, `dislike`, `remove` : `slotId` ; `add` : `dayIndex` et `exerciseId` ; `replace` : `slotId` et `replacementExerciseId`.

### `ProfileDelta`

Ce que la revue apprend sur l'utilisateur (à reporter dans le profil par l'application).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `knownExerciseIds` | liste de texte | non | id du catalogue | « Je sais faire ». |
| `unknownExerciseIds` | liste de texte | non | id du catalogue | « Je ne sais pas faire ». |
| `likedExerciseIds` | liste de texte | non | id du catalogue | Exercices ajoutés parce qu'aimés. |
| `dislikedExerciseIds` | liste de texte | non | id du catalogue | « Je n'aime pas ». |

### `PlanChange`

Changement typé entre deux programmes.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `ChangeKind` | non | — | Nature du changement. |
| `dayIndex` | entier | oui | ≥ 0 | Jour concerné. |
| `weekIndex` | entier | oui | ≥ 0 | Semaine concernée (prescriptions). |
| `slotId` | texte | oui | — | Emplacement concerné. |
| `fromExerciseId` | texte | oui | id du catalogue | Exercice avant. |
| `toExerciseId` | texte | oui | id du catalogue | Exercice après. |
| `fromDayIndex` | entier | oui | ≥ 0 | Jour d'origine (déplacement). |
| `fromPrescription` | `ExercisePrescription` | oui | — | Prescription avant (`prescription_changed`). |
| `toPrescription` | `ExercisePrescription` | oui | — | Prescription après (`prescription_changed`) : appliquer le changement = remplacer la prescription de (`weekIndex`, `dayIndex`, `slotId`) par celle-ci. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `PlanDiff`

Ce qui a bougé entre deux programmes, et pourquoi (D4.6).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `changes` | liste de `PlanChange` | non | — | Changements, dans un ordre stable. |

### `ReviewResult`

Résultat d'une action de revue : programme ré-optimisé, diff, verrous à jour.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `plan` | `Pass1Plan` | non | — | Programme après l'action. |
| `diff` | `PlanDiff` | non | — | Ce qui a bougé. |
| `locks` | liste de `PlanLock` | non | — | Verrous à repasser dans la requête suivante. |
| `profileDelta` | `ProfileDelta` | non | — | Ce que l'action apprend sur l'utilisateur. |

### `Variant`

Variante proposée pour un emplacement.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice proposé. |
| `kind` | `VariantKind` | non | — | Plus facile, équivalente, autre matériel, autre. |
| `similarity` | nombre | non | 0 à 1 | Proximité avec l'exercice remplacé, de 0 à 1. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `VariantSet`

Variantes d'un emplacement : 3 ciblées + toutes (D4.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `slotId` | texte | non | longueur ≥ 1 | Emplacement. |
| `targeted` | liste de `Variant` | non | longueur ≤ 3 | Jusqu'à 3 variantes ciblées. |
| `all` | liste de `Variant` | non | — | Toutes les variantes admissibles, par proximité décroissante. |

### `ExercisePrescription`

Prescription d'un exercice pour une séance (passe 2, D4.7).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `slotId` | texte | non | longueur ≥ 1 | Emplacement. |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `sets` | entier | non | 1 à 20 | Nombre de séries. |
| `repsLow` | entier | oui | 1 à 1000 | Bas de la plage de répétitions. |
| `repsHigh` | entier | oui | 1 à 1000 | Haut de la plage de répétitions. |
| `secondsLow` | entier | oui | 1 à 86400 | Bas de la plage de temps, en secondes. |
| `secondsHigh` | entier | oui | 1 à 86400 | Haut de la plage de temps, en secondes. |
| `distanceMeters` | nombre | oui | ≥ 0 | Distance par série, en mètres. |
| `calories` | nombre | oui | ≥ 0 | Calories par série. |
| `targetFlames` | entier | oui | 1 à 10 | Flammes visées (absent : sans cible de difficulté — mobilité, échauffement). |
| `restSeconds` | entier | oui | 0 à 900 | Repos entre les séries, en secondes (absent : libre). |
| `startLoadKg` | nombre | oui | -300 à 1000 | Charge externe de départ, en kg (prudente ; même convention que `SetRecord.externalLoadKg`). |
| `percentOfOneRm` | nombre | oui | 0 à 1.5 | Charge exprimée en part du 1RM de charge totale, de 0 à 1,5 (programme importé, ou repère du moteur). |
| `toCalibrate` | booléen | non | — | Charge à calibrer sur les premières séances. |
| `loadBasis` | `LoadBasis` | non | — | Ce que désigne la charge. |
| `setTargets` | liste de `SetTarget` | oui | — | Cible série par série, quand les séries diffèrent (montée de calibrage, série lourde puis séries allégées) ; sa longueur est `sets`. Absent : toutes les séries suivent la prescription. |
| `groupId` | texte | oui | — | Groupe d'exercices enchaînés dans la séance (superset, tours, circuit) : même valeur pour les membres du groupe. |
| `format` | texte | oui | — | Code du format du groupe ou de l'exercice (`superset`, `rounds`, `amrap`, `emom`, `intervals`…). |
| `kind` | `SetKind` | oui | — | Rôle des séries (absent : travail) ; `test` pour une séance de test. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |
| `technique` | `SetTechnique` | oui | — | Technique de série (0.4.0) ; absente : séries normales. |
| `tempo` | `Tempo` | oui | — | Tempo des répétitions (0.4.0). |
| `intensity` | `IntensityTarget` | oui | — | Intensité en plage, relative à un test (répétitions max, maintien max, course), à une vitesse ou au poids de corps ; plafond de RIR (0.4.0). |
| `autoregulation` | liste de `AutoregulationRule` | oui | longueur ≤ 3 | Règles d'autorégulation que le moteur dynamique exécute (0.4.0). |
| `test` | `TestSpec` | oui | — | Description du test, quand `kind` vaut `test` (0.4.0). |
| `dayStress` | `DayStress` | oui | — | Ondulation : jour lourd, moyen ou léger pour ce mouvement (0.4.0). |
| `skillTargetId` | texte | oui | id du catalogue | Figure visée dont cet exercice est une étape (0.4.0). |
| `unbroken` | booléen | oui | — | Série indivisible : aucun repos pendant la série (0.4.0). |
| `restMode` | `RestMode` | oui | — | Nature de la récupération (course) (0.4.0). |

Invariant : Une seule famille de mesure : répétitions, temps, distance ou calories ; bornes basses ≤ bornes hautes, renseignées ensemble ; `setTargets`, s'il est présent, a `sets` éléments.

Invariant : (0.4.0) `test` renseigné ⇒ `kind` vaut `test`. `sets` est toujours le nombre de lignes de journal attendues : série de tête et séries allégées (`backoffSets` < `sets`), paliers de vagues (`waves` × longueur de `waveReps`), de pyramide (longueur de `pyramidReps`), marches d'échelle (`ladderCount` × nombre de marches), intervalles d'un EMOM (`intervals`), 1 pour un bloc de densité ou de volume au temps. `sets` restant borné à 20, une technique de plus de 20 lignes (EMOM long, grande échelle) s'écrit comme un groupe (`GroupSpec`). La plage de répétitions est celle d'une ligne : un cluster de `miniSets` × `miniSetReps` y est compris ; vagues, pyramide, échelle : leurs bornes. Deux écritures de la même intensité doivent s'accorder : `percentOfOneRm` dans la plage de `intensity` (`percent_one_rm`), RIR de `targetFlames` dans celle de `intensity` (`rir`), `pct` d'une règle `backoff_from_top_set` égal à `technique.backoffDropPct`.

### `DayPrescription`

Prescriptions d'une séance.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `dayIndex` | entier | non | ≥ 0 | Jour d'entraînement. |
| `items` | liste de `ExercisePrescription` | non | — | Exercices, dans l'ordre. |
| `stress` | `DayStress` | oui | — | Ondulation : séance lourde, moyenne ou légère (0.4.0). |
| `groups` | liste de `GroupSpec` | oui | longueur ≤ 20 | Groupes d'exercices enchaînés de la séance (0.4.0). |

Invariant : (0.4.0) `groups` : `groupId` distincts ; chaque groupe a au moins un membre parmi `items`.

### `WeekPrescription`

Prescriptions d'une semaine du bloc.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `weekIndex` | entier | non | ≥ 0 | Semaine dans le bloc (0 = première). |
| `kind` | `WeekKind` | non | — | Nature de la semaine. |
| `days` | liste de `DayPrescription` | non | — | Séances. |
| `intent` | `WeekIntent` | oui | — | Intention de la semaine (0.4.0) ; `kind` reste renseigné. |

### `Pass2Plan`

Passe 2 : prescriptions par semaine.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `blockId` | texte | non | longueur ≥ 1 | Identifiant du bloc (celui de la passe 1). |
| `engineVersion` | texte | non | — | Version de kalis_plan. |
| `weeks` | liste de `WeekPrescription` | non | — | Semaines du bloc. |
| `reasons` | liste de `Reason` | non | — | Logique du bloc. |

Invariant : `weekIndex` = rang dans `weeks`.

### `ProgramBlock`

Bloc de programme complet (passes 1 et 2), stocké par l'application.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `pass1` | `Pass1Plan` | non | — | Passe 1. |
| `pass2` | `Pass2Plan` | non | — | Passe 2. |

Invariant : Même `blockId` ; autant de semaines de passe 2 que `pass1.weeks` ; `slotId` uniques dans une séance ; chaque séance prescrite renvoie à un jour de la passe 1. La passe 2 fait foi : une semaine peut prescrire un autre exercice que la semaine type pour un emplacement (échange en cours de bloc, semaine de test), ou un emplacement propre à cette semaine.

### `PlanRequest`

Requête de création d'un programme.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `seed` | entier | non | ≥ 0 | Graine (« Autre proposition » = nouvelle graine, D4.3). |
| `startDate` | jour civil | non | — | Premier jour du bloc. |
| `blockWeeks` | entier | oui | 4 à 6 | Durée souhaitée du bloc, en semaines. |
| `locks` | liste de `PlanLock` | non | — | Verrous. |
| `previousBlock` | `ProgramBlock` | oui | — | Bloc précédent. |
| `adaptation` | `AdaptationSummary` | oui | — | Résumé d'adaptation. |
| `season` | `SeasonPlan` | oui | — | Plan de saison en cours (0.4.0). |

### `NextBlockRequest`

Requête du bloc suivant (D4.8).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `seed` | entier | non | ≥ 0 | Graine. |
| `startDate` | jour civil | non | — | Premier jour du nouveau bloc. |
| `previous` | `ProgramBlock` | non | — | Bloc qui se termine. |
| `adaptation` | `AdaptationSummary` | non | — | Résumé d'adaptation. |
| `locks` | liste de `PlanLock` | non | — | Verrous. |
| `season` | `SeasonPlan` | oui | — | Plan de saison en cours (0.4.0). |

### `RestructureRequest`

Requête de restructuration (D5.1 : le moteur dynamique appelle le statique).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `seed` | entier | non | ≥ 0 | Graine. |
| `today` | jour civil | non | — | « Aujourd'hui ». |
| `current` | `ProgramBlock` | non | — | Bloc en cours. |
| `scope` | `RestructureScope` | non | — | Portée. |
| `dayIndex` | entier | oui | ≥ 0 | Jour visé (portée séance). |
| `fromWeekIndex` | entier | oui | ≥ 0 | Première semaine modifiable. |
| `reasons` | liste de `Reason` | non | — | Raisons de la restructuration. |
| `locks` | liste de `PlanLock` | non | — | Verrous. |
| `adaptation` | `AdaptationSummary` | oui | — | Résumé d'adaptation. |
| `season` | `SeasonPlan` | oui | — | Plan de saison en cours (0.4.0). |

Invariant : Portée `session` ⇒ `dayIndex` renseigné.

### `ReviewRequest`

Requête d'action de revue de la passe 1.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `request` | `PlanRequest` | non | — | Requête de création (avec les verrous déjà posés). |
| `current` | `Pass1Plan` | non | — | Programme en cours de revue. |
| `action` | `ReviewAction` | non | — | Action de l'utilisateur. |

### `VariantsRequest`

Requête de variantes pour un emplacement.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `request` | `PlanRequest` | non | — | Requête de création. |
| `current` | `Pass1Plan` | non | — | Programme en cours de revue. |
| `slotId` | texte | non | longueur ≥ 1 | Emplacement. |

### `Pass2Request`

Requête de passe 2.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `request` | `PlanRequest` | non | — | Requête de création. |
| `pass1` | `Pass1Plan` | non | — | Passe 1 validée par l'utilisateur. |

### `BlockProposal`

Bloc proposé et ce qui change par rapport au précédent.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `block` | `ProgramBlock` | non | — | Bloc proposé. |
| `diff` | `PlanDiff` | non | — | Changements par rapport au bloc de référence. |
| `season` | `SeasonPlan` | oui | — | Plan de saison révisé, si le bloc proposé le modifie (0.4.0). |

### `Tempo`

Tempo d'une répétition, en secondes par phase (0.4.0) ; 0 = sans consigne (ou explosif pour la phase concentrique).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `eccentricSeconds` | entier | non | 0 à 30 | Descente (phase excentrique). |
| `bottomPauseSeconds` | entier | non | 0 à 30 | Pause en bas. |
| `concentricSeconds` | entier | non | 0 à 30 | Montée (phase concentrique). |
| `topPauseSeconds` | entier | non | 0 à 30 | Pause en haut. |

### `SetTechnique`

Technique de série et ses paramètres (0.4.0). Sens de `ExercisePrescription.sets` et de la plage de répétitions pour chaque technique : CONTRAT.md §12.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `SetTechniqueKind` | non | — | Technique. |
| `backoffSets` | entier | oui | 1 à 10 | Séries allégées après la série de tête. |
| `backoffDropPct` | nombre | oui | 0 à 0.6 | Baisse de charge des séries allégées, en part de la charge de tête (0,10 = −10 %). |
| `backoffRepsLow` | entier | oui | 1 à 100 | Bas de la plage de répétitions des séries allégées. |
| `backoffRepsHigh` | entier | oui | 1 à 100 | Haut de la plage de répétitions des séries allégées. |
| `miniSets` | entier | oui | 1 à 20 | Mini-séries par série (clusters) ; plafond de mini-séries (rest-pause, myo-reps). |
| `miniSetReps` | entier | oui | 1 à 30 | Répétitions par mini-série. |
| `intraRestSeconds` | entier | oui | 1 à 120 | Repos entre deux mini-séries, en secondes. |
| `totalRepsTarget` | entier | oui | 1 à 1000 | Répétitions totales visées (rest-pause, densité). |
| `drops` | entier | oui | 1 à 6 | Nombre de baisses de charge (dégressive). |
| `dropPct` | nombre | oui | 0.05 à 0.6 | Baisse de charge à chaque palier, en part de la charge précédente. |
| `eccentricLoadPct` | nombre | oui | 0 à 1.5 | Charge de la phase excentrique, en part du 1RM de charge totale (peut dépasser 1). |
| `eccentricOnly` | booléen | oui | — | Négatives seules (la montée est aidée ou sautée). |
| `pairedSlotId` | texte | oui | longueur ≥ 1 | Emplacement de l'exercice explosif enchaîné (contraste). |
| `pairedRestSeconds` | entier | oui | 0 à 900 | Repos avant l'exercice enchaîné, en secondes. |
| `waves` | entier | oui | 1 à 6 | Nombre de vagues. |
| `waveReps` | liste de entier | oui | longueur 1 à 8 | Répétitions de chaque palier d'une vague, dans l'ordre (ex. 3, 2, 1). |
| `waveStepPct` | nombre | oui | 0 à 0.2 | Hausse de charge d'une vague à la suivante, en part de la charge. |
| `durationSeconds` | entier | oui | 10 à 7200 | Durée du bloc, en secondes (AMRAP, densité). |
| `intervalSeconds` | entier | oui | 10 à 900 | Durée d'un intervalle, en secondes (EMOM). |
| `intervals` | entier | oui | 1 à 120 | Nombre d'intervalles (EMOM). |
| `ladderStart` | entier | oui | 1 à 100 | Première marche de l'échelle, en répétitions. |
| `ladderStep` | entier | oui | 1 à 20 | Pas de l'échelle, en répétitions. |
| `ladderTop` | entier | oui | 1 à 100 | Dernière marche de l'échelle, en répétitions. |
| `ladderCount` | entier | oui | 1 à 20 | Nombre d'échelles enchaînées. |
| `pyramidReps` | liste de entier | oui | longueur 2 à 20 | Répétitions de chaque palier de la pyramide, dans l'ordre (ex. 10, 8, 6, 4, 2). |
| `qualityFloor` | entier | oui | 1 à 5 | Propreté minimale (1 à 5) : la pratique s'arrête dès qu'un essai passe dessous. |
| `maxAttempts` | entier | oui | 1 à 30 | Plafond d'essais (pratique de figure). |
| `totalSecondsTarget` | entier | oui | 1 à 3600 | Temps total de maintien à accumuler, en secondes (maintien, pratique de figure). |
| `lastSetOnly` | booléen | oui | — | La technique ne s'applique qu'à la dernière série ; les autres sont normales. |

Invariant : Chaque technique porte exactement ses paramètres (tableau de CONTRAT.md §12) : un paramètre d'une autre technique est une violation.

Invariant : Plages basses ≤ plages hautes, renseignées ensemble ; `ladderStart` ≤ `ladderTop`, écart multiple de `ladderStep` ; répétitions de `waveReps` et de `pyramidReps` de 1 à 100 ; `lastSetOnly` jamais avec `standard`.

Variantes selon `kind` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `standard` | — | — |
| `top_set_backoff` | `backoffSets`, `backoffDropPct` | `backoffRepsLow`, `backoffRepsHigh` |
| `cluster` | `miniSets`, `miniSetReps`, `intraRestSeconds` | — |
| `rest_pause` | `intraRestSeconds` | `miniSets`, `totalRepsTarget` |
| `myo_reps` | `miniSetReps`, `intraRestSeconds` | `miniSets` |
| `drop_set` | `drops`, `dropPct` | — |
| `isometric_hold` | — | `qualityFloor`, `totalSecondsTarget` |
| `accentuated_eccentric` | — | `eccentricLoadPct`, `eccentricOnly` |
| `contrast` | `pairedSlotId` | `pairedRestSeconds` |
| `wave` | `waves`, `waveReps` | `waveStepPct` |
| `amrap` | — | `durationSeconds` |
| `emom` | `intervalSeconds`, `intervals` | — |
| `density` | `durationSeconds` | `totalRepsTarget` |
| `ladder` | `ladderStart`, `ladderStep`, `ladderTop` | `ladderCount` |
| `pyramid` | `pyramidReps` | — |
| `skill_practice` | — | `qualityFloor`, `maxAttempts`, `durationSeconds`, `totalSecondsTarget` |
| `for_time` | `totalRepsTarget` | `durationSeconds` |

### `IntensityTarget`

Intensité visée, en plage ou relative à un test (0.4.0). `ExercisePrescription.percentOfOneRm` et `targetFlames` restent les valeurs simples ; ce type ajoute les plages, les intensités relatives à un test (répétitions max, maintien max), à une vitesse, au poids de corps, et le plafond d'effort.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `basis` | `IntensityBasis` | non | — | Ce que désigne `value`. |
| `value` | nombre | non | 0 à 15 | Valeur visée (ou bas de la plage) : part de 0 à 1,5 pour les bases en part ; répétitions en réserve pour `rir` ; mètres par seconde pour `absolute_speed`. |
| `valueHigh` | nombre | oui | 0 à 15 | Haut de la plage, même unité. |
| `referenceExerciseId` | texte | oui | id du catalogue | Exercice du test de référence, s'il diffère de l'exercice prescrit. |
| `referenceKind` | `BenchmarkKind` | oui | — | Nature du test de référence (`percent_benchmark` : part des répétitions max, du maintien max… ; `speed_fraction` : test de course). |
| `eventId` | texte | oui | longueur ≥ 1 | Échéance dont l'allure visée sert de référence (`speed_fraction` : part de l'allure cible de la course). |
| `rirCap` | nombre | oui | 0 à 10 | Plafond d'effort : ne jamais finir une série avec moins de répétitions en réserve que cette valeur ; la charge est abaissée sinon. |

Invariant : `value` ≤ `valueHigh` ; bases en part (`percent_one_rm`, `percent_benchmark`, `speed_fraction`, `bodyweight_fraction`) : `value` et `valueHigh` ≤ 1,5 ; `rir` : ≤ 10 ; `absolute_speed` : ≤ 15 m/s.

Variantes selon `basis` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `percent_one_rm` | — | `referenceExerciseId` |
| `percent_benchmark` | `referenceKind` | `referenceExerciseId` |
| `rir` | — | — |
| `speed_fraction` | — | `referenceKind`, `referenceExerciseId`, `eventId` |
| `bodyweight_fraction` | — | — |
| `absolute_speed` | — | — |

### `AutoregulationRule`

Règle d'autorégulation portée par une prescription (0.4.0) : le moteur dynamique l'exécute pendant la séance.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `AutoregulationKind` | non | — | Règle. |
| `pct` | nombre | oui | 0 à 1 | Part : baisse appliquée à la série de tête réalisée (`backoff_from_top_set` ; absente : celle de `technique.backoffDropPct`), part du meilleur maintien du jour (`hold_from_best`), pas de correction de charge par répétition d'écart (`load_from_rir`). |
| `rirFloor` | nombre | oui | 0 à 10 | Plancher de répétitions en réserve. |
| `rirCeiling` | nombre | oui | 0 à 10 | Plafond de répétitions en réserve. |
| `minSets` | entier | oui | 0 à 20 | Nombre minimal de séries. |
| `maxSets` | entier | oui | 1 à 30 | Nombre maximal de séries. |
| `repDrop` | entier | oui | 1 à 50 | Chute de répétitions, par rapport à la première série, qui arrête l'exercice. |
| `qualityFloor` | entier | oui | 1 à 5 | Propreté minimale (1 à 5) : l'exercice s'arrête dès qu'une série passe dessous. |

Invariant : `rirFloor` ≤ `rirCeiling` ; `minSets` ≤ `maxSets`.

Variantes selon `kind` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `backoff_from_top_set` | — | `pct`, `rirCeiling`, `minSets`, `maxSets` |
| `load_from_rir` | `rirFloor`, `rirCeiling` | `pct` |
| `stop_at_rir` | `rirFloor` | `minSets`, `maxSets` |
| `stop_on_rep_drop` | `repDrop` | `minSets`, `maxSets` |
| `hold_from_best` | `pct` | — |
| `last_set_amrap` | — | `rirFloor` |
| `stop_on_quality_drop` | `qualityFloor` | `minSets`, `maxSets` |

### `GroupSpec`

Groupe d'exercices enchaînés dans une séance (0.4.0) : ses membres portent le même `groupId`. Quand un groupe est décrit ici, il prime sur le texte libre `ExercisePrescription.format`.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `groupId` | texte | non | longueur ≥ 1 | Identifiant du groupe (celui de `ExercisePrescription.groupId`). |
| `format` | `GroupFormat` | non | — | Format. |
| `rounds` | entier | oui | 1 à 100 | Nombre de tours. |
| `durationSeconds` | entier | oui | 10 à 14400 | Durée du bloc, en secondes (AMRAP, EMOM). |
| `timeCapSeconds` | entier | oui | 10 à 14400 | Limite de temps, en secondes (tours ou suite au meilleur temps). |
| `intervalSeconds` | entier | oui | 5 à 3600 | Durée d'un intervalle, en secondes (EMOM, intervalles). |
| `restBetweenRoundsSeconds` | entier | oui | 0 à 3600 | Repos entre deux tours, en secondes. |
| `targetSeconds` | entier | oui | 1 à 14400 | Temps visé, en secondes. |
| `eventId` | texte | oui | longueur ≥ 1 | Échéance dont ce groupe répète l'épreuve. |

Invariant : Chaque format porte exactement ses paramètres ; `eventId` est libre. Dans une séance (`DayPrescription.groups`, `SessionPlan.groups`) : `groupId` distincts, et chaque groupe a au moins un membre (une prescription qui porte son `groupId`).

Variantes selon `format` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `superset` | — | `rounds`, `restBetweenRoundsSeconds` |
| `circuit` | `rounds` | `restBetweenRoundsSeconds` |
| `rounds_for_time` | `rounds` | `timeCapSeconds`, `targetSeconds`, `restBetweenRoundsSeconds` |
| `amrap` | `durationSeconds` | — |
| `emom` | `intervalSeconds`, `durationSeconds` | — |
| `chipper` | — | `timeCapSeconds`, `targetSeconds` |
| `intervals` | `rounds`, `intervalSeconds` | `restBetweenRoundsSeconds` |

### `TestSpec`

Série ou exercice de test (0.4.0), porté par une prescription dont `kind` vaut `test`.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `TestKind` | non | — | Nature du test. |
| `protocolId` | texte | oui | longueur 1 à 40 | Protocole de test guidé (`docs/PARCOURS_V3.md`, § tests guidés). |
| `targetRir` | nombre | oui | 0 à 5 | Répétitions en réserve à garder (série d'estimation). |
| `attempts` | entier | oui | 1 à 6 | Nombre d'essais au plus (maximum, simulation de tentatives). |
| `benchmarkKind` | `BenchmarkKind` | oui | — | Nature de la valeur à reporter dans le profil (`AdaptReview.testResults`). |

## Interface `adapt` (kalis_adapt)

### `ExerciseEstimate`

Capacité estimée sur un exercice (D5.2).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `unit` | `CapacityUnit` | non | — | Unité de la capacité. |
| `capacity` | nombre | non | ≥ 0 | Capacité estimée, dans l'unité `unit` (1RM de charge TOTALE en kg, répétitions max, tenue max, vitesse). |
| `standardError` | nombre | non | ≥ 0 | Écart-type de l'estimation, même unité. |
| `weeklyTrend` | nombre | non | — | Tendance par semaine, même unité. |
| `observations` | entier | non | ≥ 0 | Nombre de séries utilisées. |
| `lastObservedOn` | jour civil | oui | — | Dernière séance observée. |

### `FatigueState`

État du modèle forme / fatigue.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `fitness` | nombre | non | ≥ 0 | Forme (unités arbitraires du modèle). |
| `fatigue` | nombre | non | ≥ 0 | Fatigue (unités arbitraires du modèle). |
| `readiness` | nombre | non | 0 à 1 | Forme du jour, de 0 à 1. |

### `PainTrend`

Suivi d'une zone douloureuse.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `zone` | `BodyZone` | non | — | Zone. |
| `side` | `BodySide` | non | — | Côté. |
| `sessionsReported` | entier | non | ≥ 0 | Séances où elle a été signalée. |
| `lastIntensity` | entier | non | 0 à 10 | Dernière intensité, de 0 à 10. |
| `consecutiveAboveThreshold` | entier | non | ≥ 0 | Séances de suite au-dessus du seuil de la règle santé L13. |

### `AdaptationSummary`

Résumé d'adaptation : ce que le moteur dynamique a appris (entrée de `PlanEngine.nextBlock`).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `asOf` | jour civil | non | — | Jour du résumé. |
| `weeksObserved` | entier | non | ≥ 0 | Semaines de données réelles. |
| `sessionsPlanned` | entier | non | ≥ 0 | Séances prévues sur la période. |
| `sessionsCompleted` | entier | non | ≥ 0 | Séances terminées (hors « reprise »). |
| `unlockLevel` | `UnlockLevel` | non | — | Niveau de déblocage atteint (D5.7). |
| `confidence` | nombre | non | 0 à 1 | Confiance globale du modèle, de 0 à 1. |
| `estimates` | liste de `ExerciseEstimate` | non | — | Capacités estimées. |
| `fatigue` | `FatigueState` | oui | — | Forme et fatigue. |
| `pains` | liste de `PainTrend` | non | — | Zones douloureuses suivies. |
| `avoidedExerciseIds` | liste de texte | non | id du catalogue | Exercices régulièrement sautés ou refusés. |
| `reasons` | liste de `Reason` | non | — | Faits marquants. |
| `benchmarks` | liste de `Benchmark` | oui | longueur ≤ 200 | Tests réalisés et maxima retenus sur la période (0.4.0) ; leur incertitude est dans `estimates`. |
| `skills` | liste de `SkillProgress` | oui | longueur ≤ 30 | Suivi des figures (0.4.0). |
| `volumeTolerance` | liste de `VolumeTolerance` | oui | longueur ≤ 40 | Volume hebdomadaire toléré par groupe musculaire (0.4.0). |

### `AdaptInput`

Entrée du moteur dynamique.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `block` | `ProgramBlock` | non | — | Bloc en cours. |
| `log` | `TrainingLog` | non | — | Journal complet. |
| `today` | jour civil | non | — | « Aujourd'hui », fourni par l'application. |
| `state` | objet JSON | oui | — | État opaque rendu par le dernier appel (propriété de kalis_adapt). |
| `decisions` | liste de `ProposalDecision` | oui | — | Suites données aux propositions passées (D5.6, D9.2). |
| `season` | `SeasonPlan` | oui | — | Plan de saison en cours (0.4.0). |

### `SessionRequest`

Requête de prescription de la séance du jour.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `input` | `AdaptInput` | non | — | Profil, bloc, journal, « aujourd'hui », état. |
| `weekIndex` | entier | non | ≥ 0 | Semaine dans le bloc. |
| `dayIndex` | entier | non | ≥ 0 | Jour d'entraînement. |
| `healthCheck` | `HealthCheck` | oui | — | Bilan santé du jour (une réponse absente n'est jamais remplacée). |
| `place` | `Place` | oui | — | Lieu du jour, s'il diffère du lieu prévu. |

### `AdviceRequest`

Requête de conseil pour la série suivante.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `input` | `AdaptInput` | non | — | Profil, bloc, journal, « aujourd'hui », état. |
| `session` | `SessionPlan` | non | — | Séance en cours. |
| `done` | liste de `SetRecord` | non | — | Séries déjà faites dans la séance, dans l'ordre. |
| `slotId` | texte | non | longueur ≥ 1 | Emplacement de l'exercice dont on demande la série suivante. |
| `healthCheck` | `HealthCheck` | oui | — | Bilan santé du jour, tel qu'il a été donné à `prescribeSession` (0.2.0 ; une réponse absente n'est jamais remplacée). |

### `ProposalDecision`

Suite donnée par l'utilisateur (ou par le mode assisté) à une proposition.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `proposalId` | texte | non | longueur ≥ 1 | Proposition concernée. |
| `date` | jour civil | non | — | Jour de la décision. |
| `status` | `ProposalStatus` | non | — | Suite donnée. |

### `PersonalRecord`

Record personnel établi sur un exercice.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `kind` | `RecordKind` | non | — | Nature du record. |
| `value` | nombre | non | ≥ 0 | Valeur, dans l'unité de `kind` (charge TOTALE pour `one_rm_kg`). |
| `date` | jour civil | non | — | Jour du record. |
| `sessionId` | texte | oui | — | Séance du record. |
| `previousValue` | nombre | oui | ≥ 0 | Record précédent. |

### `SessionAdjustment`

Ajustement d'une séance (bilan santé, douleur, temps disponible : D5.9).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `AdjustmentKind` | non | — | Nature. |
| `exerciseId` | texte | oui | id du catalogue | Exercice concerné. |
| `replacementExerciseId` | texte | oui | id du catalogue | Exercice de remplacement. |
| `loadFactor` | nombre | oui | 0 à 2 | Facteur appliqué à la charge. |
| `setsDelta` | entier | oui | -20 à 20 | Séries ajoutées (négatif = retirées). |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `SessionPlan`

Prescription de la séance du jour, ajustée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `date` | jour civil | non | — | Jour de la séance. |
| `blockId` | texte | non | longueur ≥ 1 | Bloc. |
| `weekIndex` | entier | non | ≥ 0 | Semaine dans le bloc. |
| `dayIndex` | entier | non | ≥ 0 | Jour d'entraînement. |
| `items` | liste de `ExercisePrescription` | non | — | Exercices prescrits. |
| `adjustments` | liste de `SessionAdjustment` | non | — | Ajustements par rapport au bloc. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |
| `phase` | `SeasonPhaseKind` | oui | — | Phase en cours (0.4.0). |
| `weekIntent` | `WeekIntent` | oui | — | Intention de la semaine (0.4.0). |
| `eventId` | texte | oui | longueur ≥ 1 | Échéance dont c'est le jour (0.4.0). |
| `groups` | liste de `GroupSpec` | oui | longueur ≤ 20 | Groupes d'exercices enchaînés de la séance (0.4.0). |

Invariant : (0.4.0) `groups` : `groupId` distincts ; chaque groupe a au moins un membre parmi `items`.

### `IntraSessionAdvice`

Ajustement intra-séance : conseil pour la série suivante.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `action` | `IntraSessionAction` | non | — | Conseil. |
| `nextLoadKg` | nombre | oui | -300 à 1000 | Charge externe conseillée, en kg. |
| `nextRepsLow` | entier | oui | 0 à 1000 | Bas de la plage conseillée. |
| `nextRepsHigh` | entier | oui | 0 à 1000 | Haut de la plage conseillée. |
| `nextSeconds` | entier | oui | 0 à 86400 | Durée conseillée, en secondes (tenues). |
| `slotId` | texte | oui | — | Emplacement concerné. |
| `restSeconds` | entier | oui | 0 à 900 | Repos conseillé, en secondes. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |
| `miniSetsLeft` | entier | oui | 0 à 50 | Mini-séries conseillées encore à faire dans la série en cours (0.4.0). |
| `stepExerciseId` | texte | oui | id du catalogue | Étape de progression conseillée pour la suite (figure : étape plus facile un mauvais jour) (0.4.0). |

### `Proposal`

Proposition du moteur dynamique (D5.6, D5.7).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `id` | texte | non | longueur ≥ 1 | Identifiant stable. |
| `kind` | `ProposalKind` | non | — | Type. |
| `scope` | `ProposalScope` | non | — | Portée. |
| `createdOn` | jour civil | non | — | Jour de création. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |
| `unlockLevel` | `UnlockLevel` | non | — | Niveau de déblocage requis. |
| `autoApplicable` | booléen | non | — | Applicable automatiquement en mode assisté. |
| `exerciseId` | texte | oui | id du catalogue | Exercice concerné. |
| `diff` | `PlanDiff` | oui | — | Changement de programme proposé. |
| `block` | `ProgramBlock` | oui | — | Bloc résultant, pour une restructuration. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |
| `detail` | `ProposalDetail` | oui | — | Précision de la proposition (0.4.0). |
| `season` | `SeasonPlan` | oui | — | Plan de saison résultant, pour une révision de la saison (0.4.0). |

### `EngineLogEntry`

Entrée du journal du moteur (inspecteur et export du mode dev, D2.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `sequence` | entier | non | ≥ 0 | Rang dans le journal. |
| `date` | jour civil | non | — | Jour. |
| `engine` | texte | non | longueur ≥ 1 | Moteur (`plan`, `adapt`, `quest`). |
| `event` | texte | non | longueur ≥ 1 | Code de l'événement. |
| `confidence` | nombre | oui | 0 à 1 | Confiance de la décision. |
| `reasons` | liste de `Reason` | non | — | Raisons. |
| `data` | objet JSON | non | — | Détail (scores, valeurs du modèle). |

### `AdaptReview`

Résultat d'une revue du moteur dynamique.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `summary` | `AdaptationSummary` | non | — | Résumé d'adaptation. |
| `proposals` | liste de `Proposal` | non | — | Propositions. |
| `state` | objet JSON | non | — | État opaque à repasser au prochain appel. |
| `log` | liste de `EngineLogEntry` | non | — | Entrées de journal du moteur. |
| `records` | liste de `PersonalRecord` | oui | — | Records personnels établis d'après le journal. |
| `testResults` | liste de `Benchmark` | oui | longueur ≤ 200 | Résultats de tests à reporter dans `AthleteProfile.benchmarks` par l'application (0.4.0). |
| `skillStates` | liste de `SkillState` | oui | longueur ≤ 30 | États des figures à reporter dans `AthleteProfile.skills` par l'application (0.4.0). |

## Interface `quest` (kalis_quest)

### `XpEntry`

Écriture du registre d'XP (ajout seul, D7.3).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `sequence` | entier | non | ≥ 0 | Rang dans le registre. |
| `date` | jour civil | non | — | Jour. |
| `source` | `XpSource` | non | — | Origine. |
| `amount` | entier | non | ≥ 0 | XP gagnés (jamais négatifs). |
| `sessionId` | texte | oui | — | Séance à l'origine. |
| `refId` | texte | oui | — | Quête, objectif ou record à l'origine. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `KreditEntry`

Écriture du registre de Krédits (D7.7).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `sequence` | entier | non | ≥ 0 | Rang dans le registre. |
| `date` | jour civil | non | — | Jour. |
| `source` | `KreditSource` | non | — | Origine. |
| `amount` | entier | non | ≥ 0 | Krédits gagnés. |
| `refId` | texte | oui | — | Référence de l'origine. |

### `LevelState`

Niveau et prestige (D7.4).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `level` | entier | non | 1 à 100 | Niveau. |
| `prestige` | entier | non | ≥ 0 | Prestige. |
| `totalXp` | entier | non | ≥ 0 | XP acquis à vie. |
| `xpIntoLevel` | entier | non | ≥ 0 | XP dans le niveau en cours. |
| `xpForNextLevel` | entier | non | ≥ 0 | XP du niveau en cours au suivant. |

### `AttributeScore`

Attribut façon RPG (D7.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `attribute` | `AthleteAttribute` | non | — | Attribut. |
| `value` | nombre | non | 0 à 100 | Valeur, de 0 à 100. |
| `best` | nombre | oui | 0 à 100 | Meilleure valeur atteinte, de 0 à 100 (0.3.0) : elle ne baisse jamais, alors que `value` reflète le niveau actuel. |

### `MovementRank`

Rang sur un mouvement (D7.5).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement. |
| `tier` | `MovementRankTier` | non | — | Rang. |
| `score` | nombre | non | ≥ 0 | Performance normalisée utilisée pour le rang (échelle définie et publiée par kalis_quest : standards par sexe et poids de corps). |
| `nextTierAt` | nombre | oui | ≥ 0 | Performance normalisée du rang suivant, même échelle. |

### `Quest`

Quête (D7.6).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `id` | texte | non | longueur ≥ 1 | Identifiant. |
| `kind` | `QuestKind` | non | — | Famille. |
| `template` | texte | non | longueur ≥ 1 | Code du modèle de quête. |
| `params` | objet JSON | non | — | Paramètres du modèle. |
| `startsOn` | jour civil | non | — | Début. |
| `endsOn` | jour civil | oui | — | Fin. |
| `progress` | nombre | non | ≥ 0 | Avancement. |
| `target` | nombre | non | ≥ 0 | Cible. |
| `status` | `QuestStatus` | non | — | État. |
| `rewardXp` | entier | non | ≥ 0 | XP à la clé. |
| `rewardKredits` | entier | non | ≥ 0 | Krédits à la clé. |
| `reasons` | liste de `Reason` | non | — | Pourquoi cette quête. |

### `Milestone`

Jalon automatique d'un objectif.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `fraction` | nombre | non | 0 à 1 | Part de l'objectif, de 0 à 1. |
| `reachedOn` | jour civil | oui | — | Jour d'atteinte. |

### `Prediction`

Prédiction de la date d'atteinte d'un objectif.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `expectedOn` | jour civil | non | — | Date attendue. |
| `earliestOn` | jour civil | non | — | Borne basse. |
| `latestOn` | jour civil | non | — | Borne haute. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |
| `method` | texte | non | longueur ≥ 1 | Code de la méthode. |

Invariant : `earliestOn` ≤ `expectedOn` ≤ `latestOn`.

### `GoalProgress`

Avancement d'un objectif du profil.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `goalId` | texte | non | longueur ≥ 1 | Objectif. |
| `current` | nombre | non | — | Valeur actuelle, dans l'unité de l'objectif (`Goal.metric` ; séances faites pour une habitude). |
| `target` | nombre | non | — | Valeur cible, même unité. |
| `fraction` | nombre | non | 0 à 1 | Avancement, de 0 à 1. |
| `achievedOn` | jour civil | oui | — | Jour d'atteinte. |
| `milestones` | liste de `Milestone` | non | — | Jalons. |
| `prediction` | `Prediction` | oui | — | Prédiction. |
| `baseline` | nombre | oui | — | Valeur de départ, mesurée à la création de l'objectif, même unité (0.3.0). |
| `overdue` | booléen | oui | — | Vrai si l'objectif est en retard : la date prédite dépasse l'échéance, ou la cible est hors d'atteinte au rythme actuel (0.3.0). |
| `suggestedDate` | jour civil | oui | — | Échéance proposée pour un objectif en retard, cible inchangée (0.3.0). |
| `suggestedTarget` | nombre | oui | ≥ 0 | Cible proposée pour un objectif en retard, échéance inchangée, même unité (0.3.0). |
| `reasons` | liste de `Reason` | oui | — | Pourquoi (prédiction mise à jour, retard) (0.3.0). |

### `DelightEvent`

Événement de plaisir (D8.1).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `DelightKind` | non | — | Nature. |
| `date` | jour civil | non | — | Jour. |
| `sessionId` | texte | oui | — | Séance. |
| `exerciseId` | texte | oui | id du catalogue | Exercice. |
| `recordKind` | `RecordKind` | oui | — | Nature du record. |
| `value` | nombre | oui | — | Valeur atteinte. |
| `previousValue` | nombre | oui | — | Valeur précédente. |
| `grade` | `SessionGrade` | oui | — | Note de séance. |
| `combo` | entier | oui | ≥ 0 | Longueur du combo. |
| `streakWeeks` | entier | oui | ≥ 0 | Série de semaines. |
| `kredits` | entier | oui | ≥ 0 | Krédits du coffre. |
| `reasons` | liste de `Reason` | non | — | Raisons. |

### `QuestState`

État persistant du leveling, stocké par l'application.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `xp` | liste de `XpEntry` | non | — | Registre d'XP. |
| `kredits` | liste de `KreditEntry` | non | — | Registre de Krédits. |
| `quests` | liste de `Quest` | non | — | Quêtes en cours et passées. |
| `lastEvaluatedOn` | jour civil | oui | — | Dernier jour évalué. |
| `data` | objet JSON | non | — | État opaque de kalis_quest. |

Invariant : Registres en ajout seul : `sequence` = rang dans la liste (0, 1, 2…) ; dates croissantes au sens large.

### `QuestClaim`

Déclaration de l'utilisateur : une quête déclarative (récupération d'un jour de repos : sommeil, hydratation, marche légère…) est faite (0.3.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `questId` | texte | non | longueur ≥ 1 | Quête déclarée faite. |
| `date` | jour civil | non | — | Jour de la déclaration. |

### `QuestInput`

Entrée du moteur de leveling.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `log` | `TrainingLog` | non | — | Journal complet. |
| `block` | `ProgramBlock` | oui | — | Bloc en cours. |
| `adaptation` | `AdaptationSummary` | oui | — | Résumé d'adaptation. |
| `state` | `QuestState` | non | — | État précédent. |
| `today` | jour civil | non | — | « Aujourd'hui », fourni par l'application. |
| `seed` | entier | oui | ≥ 0 | Graine de l'utilisateur pour les tirages (coffres, quêtes du jour) ; le moteur la combine à la date. |
| `claims` | liste de `QuestClaim` | oui | — | Quêtes déclaratives que l'utilisateur dit avoir faites depuis le dernier appel (0.3.0). Une déclaration déjà prise en compte peut être redonnée sans effet. |

### `QuestOutcome`

Résultat du moteur de leveling.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `state` | `QuestState` | non | — | Nouvel état (les registres ne perdent jamais d'écriture). |
| `level` | `LevelState` | non | — | Niveau et prestige. |
| `attributes` | liste de `AttributeScore` | non | — | Attributs. |
| `ranks` | liste de `MovementRank` | non | — | Rangs par mouvement. |
| `goals` | liste de `GoalProgress` | non | — | Avancement des objectifs. |
| `events` | liste de `DelightEvent` | non | — | Événements de plaisir nouveaux. |
| `kreditBalance` | entier | non | ≥ 0 | Solde de Krédits. |
| `weekStreak` | entier | oui | ≥ 0 | Série de semaines en cours. |
| `suggestedGoals` | liste de `Goal` | oui | — | Objectifs suggérés par Koach d'après le profil et les données (D3.8), à proposer à l'utilisateur. |
| `records` | liste de `PersonalRecord` | oui | — | Records personnels connus. |
| `extras` | objet JSON | oui | — | Données de présentation propres à kalis_quest (récapitulatif hebdomadaire, comparaisons dans le temps, fantôme), documentées par ce paquet. |

## Saison, compétition, figures, spécialisation (0.4.0)

### `CompetitionLift`

Mouvement d'une compétition de force à tentatives (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement. |
| `attempts` | entier | non | 1 à 4 | Tentatives accordées. |
| `minIncrementKg` | nombre | oui | 0.25 à 10 | Plus petit saut de charge admis entre deux tentatives, en kg. |
| `bestKg` | nombre | oui | -300 à 1000 | Meilleure barre déjà validée, en kg de charge externe (lest seul). |
| `targetKg` | nombre | oui | -300 à 1000 | Barre visée, en kg de charge externe. |

### `EventStation`

Poste d'une épreuve de répétitions (0.4.0) : un exercice, son volume imposé ou son maximum.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `reps` | entier | oui | 1 à 1000 | Répétitions imposées (absent : maximum). |
| `seconds` | entier | oui | 1 à 3600 | Durée imposée d'un maintien, en secondes. |
| `externalLoadKg` | nombre | oui | -300 à 1000 | Lest imposé, en kg. |
| `unbroken` | booléen | oui | — | Série indivisible (aucun repos pendant le poste). |
| `timeLimitSeconds` | entier | oui | 1 à 14400 | Limite de temps propre au poste, en secondes. |
| `restAfterSeconds` | entier | oui | 0 à 3600 | Repos imposé après le poste, en secondes. |

Invariant : `reps` et `seconds` ne sont pas renseignés ensemble.

### `SeasonEvent`

Échéance de la saison (0.4.0) : compétition ou test daté. Les formats varient d'un organisateur à l'autre : rien n'est figé (mouvements, tentatives, postes et temps sont des données).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `id` | texte | non | longueur ≥ 1 | Identifiant stable de l'échéance. |
| `kind` | `EventKind` | non | — | Nature. |
| `priority` | `EventPriority` | non | — | Priorité dans la saison. |
| `date` | jour civil | non | — | Jour de l'échéance. |
| `name` | texte | oui | longueur ≤ 60 | Nom donné par l'utilisateur. |
| `ruleset` | texte | oui | longueur 1 à 40 | Code libre du règlement (`final_rep`, `isf_classic`, `isf_multirep`…), s'il est connu. |
| `weightClassKg` | nombre | oui | 25 à 300 | Limite haute de la catégorie de poids de corps visée, en kg. |
| `openWeightClass` | booléen | oui | — | Catégorie « plus de » : `weightClassKg` est alors la limite basse. |
| `lifts` | liste de `CompetitionLift` | oui | longueur 1 à 6 | Mouvements, dans l'ordre de la compétition (compétition de force). |
| `mode` | `RepsEventMode` | oui | — | Format de l'épreuve de répétitions. |
| `stations` | liste de `EventStation` | oui | longueur 1 à 40 | Postes, dans l'ordre (épreuve de répétitions). |
| `rounds` | entier | oui | 1 à 50 | Nombre de tours de la suite de postes. |
| `timeLimitSeconds` | entier | oui | 10 à 14400 | Limite de temps, en secondes. |
| `distanceMeters` | nombre | oui | ≥ 1 | Distance de la course, en mètres. |
| `targetSeconds` | entier | oui | 1 à 86400 | Temps visé, en secondes. |
| `goalIds` | liste de texte | oui | — | Objectifs du profil que sert cette échéance. |
| `dateApproximate` | booléen | oui | — | La date n'est pas encore fixée au jour près : `date` est une estimation. |
| `plannedBodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps prévu le jour de l'échéance, en kg. |
| `formatKnown` | booléen | oui | — | false : le format de l'épreuve ne sera connu que le jour même (préparation générale). |
| `heats` | entier | oui | 1 à 20 | Nombre de passages prévus dans la journée (manches, tours d'un tableau à élimination). |
| `restBetweenHeatsSeconds` | entier | oui | 0 à 14400 | Repos attendu entre deux passages, en secondes. |
| `elements` | liste de texte | oui | longueur ≤ 40, id du catalogue | Figures ou éléments prévus (freestyle). |
| `bestSeconds` | entier | oui | 1 à 86400 | Meilleur temps déjà réalisé sur cette épreuve, en secondes. |
| `bestTotalReps` | entier | oui | 0 à 100000 | Meilleur total de répétitions déjà réalisé sur cette épreuve. |
| `bestDate` | jour civil | oui | — | Jour de cette meilleure performance. |

Invariant : Compétition de force : `lifts` ; compétition de répétitions : `mode` (et `stations` quand le format est connu) ; course : `distanceMeters`.

Invariant : Mouvements de `lifts` distincts ; `stations` renseigné ⇒ `mode` renseigné ; `goalIds` sans doublon.

Variantes selon `kind` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `strength_competition` | `lifts` | `timeLimitSeconds`, `heats`, `restBetweenHeatsSeconds` |
| `reps_competition` | `mode` | `stations`, `rounds`, `timeLimitSeconds`, `targetSeconds`, `formatKnown`, `heats`, `restBetweenHeatsSeconds`, `bestSeconds`, `bestTotalReps` |
| `freestyle_competition` | — | `timeLimitSeconds`, `heats`, `restBetweenHeatsSeconds`, `elements`, `formatKnown` |
| `race` | `distanceMeters` | `targetSeconds`, `timeLimitSeconds`, `bestSeconds` |
| `other_competition` | — | `lifts`, `mode`, `stations`, `rounds`, `timeLimitSeconds`, `distanceMeters`, `targetSeconds`, `formatKnown`, `heats`, `restBetweenHeatsSeconds`, `elements`, `bestSeconds`, `bestTotalReps` |
| `personal_test` | — | `lifts`, `mode`, `stations`, `rounds`, `timeLimitSeconds`, `distanceMeters`, `targetSeconds`, `elements`, `bestSeconds`, `bestTotalReps` |

### `Specialization`

Spécialisation (0.4.0) : priorité donnée à un mouvement, une figure, un groupe musculaire ou un schéma, et sort du reste.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `kind` | `SpecializationKind` | non | — | Nature de la cible. |
| `exerciseId` | texte | oui | id du catalogue | Mouvement ou figure visé. |
| `muscle` | texte | oui | longueur ≥ 1 | Groupe musculaire visé (vocabulaire `muscles` de la base). |
| `pattern` | `MovementPattern` | oui | — | Schéma de mouvement visé. |
| `weeks` | entier | oui | 2 à 26 | Durée voulue, en semaines (absent : au moteur de la fixer). |
| `maintenance` | `MaintenancePolicy` | oui | — | Sort du reste (absent : au moteur de le fixer). |
| `startedOn` | jour civil | oui | — | Premier jour de la spécialisation en cours. |

Invariant : Exactement la cible de `kind` : `exerciseId` (mouvement, figure), `muscle` ou `pattern`.

Variantes selon `kind` (un champ contrôlé n'est permis que pour les variantes qui le citent) :

| Variante | Champs obligatoires | Champs permis |
| --- | --- | --- |
| `exercise` | `exerciseId` | — |
| `skill` | `exerciseId` | — |
| `muscle` | `muscle` | — |
| `pattern` | `pattern` | — |

### `SkillState`

Où en est l'utilisateur sur une figure (0.4.0) : figure visée, étape actuelle de sa progression (graphe `variante_de` du catalogue), meilleure performance sur cette étape.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `targetExerciseId` | texte | non | id du catalogue | Figure visée. |
| `currentExerciseId` | texte | non | id du catalogue | Étape actuelle (la figure elle-même si elle est acquise). |
| `bestHoldSeconds` | entier | oui | 0 à 3600 | Meilleur maintien propre sur l'étape actuelle, en secondes. |
| `bestReps` | entier | oui | 0 à 1000 | Meilleur nombre de répétitions propres sur l'étape actuelle. |
| `assessedOn` | jour civil | oui | — | Jour de cette mesure. |
| `atStepSince` | `StepTenure` | oui | — | Depuis quand l'utilisateur en est à cette étape (initialise `SkillProgress.weeksAtStep`). |

### `StepCriterion`

Critère de passage d'une étape de figure (0.4.0). Paramétrable : les valeurs sont un usage d'entraîneur, pas une norme.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `holdSeconds` | entier | oui | 1 à 600 | Maintien exigé par série, en secondes. |
| `reps` | entier | oui | 1 à 200 | Répétitions exigées par série. |
| `sets` | entier | non | 1 à 10 | Nombre de séries qui doivent atteindre le critère dans une séance. |
| `minQuality` | entier | oui | 1 à 5 | Propreté minimale déclarée (`SetRecord.quality`, de 1 à 5). |
| `sessions` | entier | oui | 1 à 20 | Nombre de séances de suite où le critère doit être tenu. |
| `minWeeks` | entier | oui | 0 à 52 | Durée minimale à cette étape, en semaines (adaptation des tendons). |

Invariant : Au moins `holdSeconds` ou `reps`.

### `SkillStep`

Étape d'une échelle de figure (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice de l'étape. |
| `criterion` | `StepCriterion` | non | — | Critère pour passer à l'étape suivante (pour la dernière étape : figure acquise). |

### `SkillLadder`

Échelle de progression d'une figure (0.4.0), de la plus facile à la figure visée.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `targetExerciseId` | texte | non | id du catalogue | Figure visée. |
| `steps` | liste de `SkillStep` | non | longueur 1 à 20 | Étapes, dans l'ordre de difficulté. |

Invariant : Étapes distinctes ; la dernière est la figure visée.

### `SkillProgress`

Suivi d'une figure par le moteur dynamique (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `targetExerciseId` | texte | non | id du catalogue | Figure visée. |
| `currentExerciseId` | texte | non | id du catalogue | Étape actuelle. |
| `stepIndex` | entier | non | ≥ 0 | Rang de l'étape actuelle dans l'échelle (0 = première). |
| `weeksAtStep` | entier | non | ≥ 0 | Semaines passées à cette étape. |
| `criterionMet` | booléen | non | — | Le critère de passage est tenu. |
| `bestHoldSeconds` | entier | oui | 0 à 3600 | Meilleur maintien propre sur l'étape, en secondes. |
| `bestReps` | entier | oui | 0 à 1000 | Meilleur nombre de répétitions propres sur l'étape. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `PhaseOverride`

Phase propre à un mouvement, quand elle diffère de la phase générale (0.4.0) : un mouvement peut rester en accumulation pendant que les autres s'intensifient.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement ou figure. |
| `kind` | `SeasonPhaseKind` | non | — | Phase de ce mouvement. |
| `volumeFactor` | nombre | oui | 0 à 2 | Volume visé pour ce mouvement, rapporté à sa pointe. |
| `intensityFactor` | nombre | oui | 0 à 2 | Intensité visée pour ce mouvement, rapportée à sa pointe. |

### `SeasonPhase`

Phase d'un plan de saison (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `index` | entier | non | ≥ 0 | Rang de la phase (0 = première). |
| `kind` | `SeasonPhaseKind` | non | — | Nature. |
| `startDate` | jour civil | non | — | Premier jour de la phase. |
| `weeks` | entier | non | 1 à 26 | Durée, en semaines. |
| `eventId` | texte | oui | — | Échéance que prépare la phase. |
| `volumeFactor` | nombre | oui | 0 à 2 | Volume visé, rapporté au volume de pointe de la saison (1 = pointe). |
| `intensityFactor` | nombre | oui | 0 à 2 | Intensité moyenne visée, rapportée à celle de la phase la plus intense (1 = pointe). |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |
| `overrides` | liste de `PhaseOverride` | oui | longueur ≤ 20 | Mouvements dont la phase diffère de la phase générale. |

Invariant : Mouvements de `overrides` distincts.

### `SeasonPlan`

Plan de saison (0.4.0) : squelette de phases au-dessus des blocs de 4 à 6 semaines (D4.8 inchangé : les blocs restent générés au fil de l'eau).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `createdOn` | jour civil | non | — | Jour de création ou de dernière révision. |
| `engineVersion` | texte | non | — | Version de kalis_plan. |
| `eventIds` | liste de texte | non | — | Échéances du profil prises en compte (`SeasonEvent.id`). |
| `phases` | liste de `SeasonPhase` | non | longueur 1 à 60 | Phases, dans l'ordre. |
| `reasons` | liste de `Reason` | non | — | Logique de la saison. |

Invariant : `index` = rang dans `phases` ; les phases se suivent sans trou ni chevauchement (chacune commence 7 × `weeks` jours après la précédente) ; `eventIds` sans doublon ; l'`eventId` d'une phase est dans `eventIds`.

### `BlockIntent`

Intention d'un bloc (0.4.0) : sa place dans la saison.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `phase` | `SeasonPhaseKind` | non | — | Phase que réalise le bloc. |
| `seasonPhaseIndex` | entier | oui | ≥ 0 | Rang de la phase dans le plan de saison. |
| `eventId` | texte | oui | — | Échéance préparée. |
| `weeksToEvent` | entier | oui | 0 à 104 | Semaines entre le début du bloc et l'échéance. |
| `undulation` | `UndulationModel` | oui | — | Modèle d'ondulation du bloc. |
| `specialization` | `Specialization` | oui | — | Spécialisation servie par le bloc. |

### `VolumeTolerance`

Volume hebdomadaire toléré par un groupe musculaire, appris par le moteur dynamique (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `muscle` | texte | non | longueur ≥ 1 | Groupe musculaire (vocabulaire de `kalis_plan`). |
| `weeklySetsLow` | nombre | non | 0 à 80 | Bas de la plage de séries hebdomadaires bien tolérées. |
| `weeklySetsHigh` | nombre | non | 0 à 80 | Haut de la plage. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |

Invariant : `weeklySetsLow` ≤ `weeklySetsHigh`.

### `AttemptResult`

Tentative déjà faite le jour d'une compétition (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement. |
| `index` | entier | non | 0 à 3 | Rang de la tentative (0 = ouverture). |
| `loadKg` | nombre | non | -300 à 1000 | Charge externe tentée, en kg. |
| `success` | booléen | non | — | Tentative validée. |
| `failure` | `AttemptFailure` | oui | — | Cause de l'échec, si elle est connue. |

Invariant : `failure` seulement pour une tentative manquée (`success` faux).

### `AttemptSuggestion`

Tentative proposée (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `index` | entier | non | 0 à 3 | Rang de la tentative (0 = ouverture). |
| `loadKg` | nombre | non | -300 à 1000 | Charge externe proposée, en kg. |
| `successProbability` | nombre | oui | 0 à 1 | Probabilité de réussite estimée, de 0 à 1. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `WarmupStep`

Marche de la montée d'échauffement avant une tentative ou un test (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `loadKg` | nombre | non | -300 à 1000 | Charge externe, en kg. |
| `reps` | entier | non | 1 à 50 | Répétitions. |
| `restSeconds` | entier | oui | 0 à 900 | Repos après la marche, en secondes. |

### `LiftAttempts`

Tentatives proposées pour un mouvement (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Mouvement. |
| `estimateKg` | nombre | oui | -300 à 1000 | Maximum du jour estimé, en kg de charge externe. |
| `standardErrorKg` | nombre | oui | ≥ 0 | Écart-type de cette estimation, en kg. |
| `attempts` | liste de `AttemptSuggestion` | non | longueur ≤ 4 | Tentatives restantes, dans l'ordre. |
| `warmup` | liste de `WarmupStep` | oui | longueur ≤ 12 | Montée d'échauffement proposée avant l'ouverture. |

Invariant : Charges proposées croissantes au sens large (une charge ne baisse jamais) ; rangs strictement croissants.

### `PacingSegment`

Stratégie de rythme sur un poste d'une épreuve de répétitions (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `exerciseId` | texte | non | id du catalogue | Exercice. |
| `setReps` | liste de entier | non | longueur 1 à 60 | Répétitions prévues par série, dans l'ordre. |
| `restSeconds` | entier | oui | 0 à 900 | Repos prévu entre les séries, en secondes. |
| `targetSeconds` | entier | oui | 1 à 14400 | Temps visé sur ce poste, en secondes. |
| `stationIndex` | entier | oui | 0 à 39 | Rang du poste dans l'épreuve (0 = premier), quand un exercice y revient plusieurs fois. |
| `round` | entier | oui | 0 à 49 | Tour concerné (0 = premier) ; absent : tous les tours. |

Invariant : Répétitions de `setReps` de 1 à 1 000.

### `EventDayRequest`

Requête du jour d'une échéance (0.4.0).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `input` | `AdaptInput` | non | — | Profil, bloc, journal, « aujourd'hui », état. |
| `eventId` | texte | non | longueur ≥ 1 | Échéance du profil (`SeasonEvent.id`). |
| `bodyWeightKg` | nombre | oui | 25 à 300 | Poids de corps du jour (pesée), en kg. |
| `done` | liste de `AttemptResult` | non | — | Tentatives déjà faites, dans l'ordre. |
| `healthCheck` | `HealthCheck` | oui | — | Bilan santé du jour (une réponse absente n'est jamais remplacée). |
| `objective` | `EventObjective` | oui | — | Objectif du jour (compétition de force). |
| `targetTotalKg` | nombre | oui | 0 à 5000 | Total visé, en kg de charge externe. |

### `EventDayPlan`

Plan du jour d'une échéance (0.4.0) : tentatives d'une compétition de force, ou objectif et rythme d'une épreuve de répétitions.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `eventId` | texte | non | longueur ≥ 1 | Échéance. |
| `lifts` | liste de `LiftAttempts` | non | — | Tentatives par mouvement (compétition de force). |
| `pacing` | liste de `PacingSegment` | oui | — | Rythme par poste (épreuve de répétitions). |
| `targetTotalReps` | entier | oui | 0 à 100000 | Objectif de répétitions totales. |
| `targetSeconds` | entier | oui | 1 à 86400 | Objectif de temps, en secondes. |
| `confidence` | nombre | non | 0 à 1 | Confiance, de 0 à 1. |
| `reasons` | liste de `Reason` | non | — | Pourquoi. |

### `SeasonRequest`

Requête de plan de saison (0.4.0) : les échéances sont celles du profil (`AthleteProfile.events`).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `profile` | `AthleteProfile` | non | — | Profil. |
| `seed` | entier | non | ≥ 0 | Graine. |
| `today` | jour civil | non | — | « Aujourd'hui ». |
| `startDate` | jour civil | non | — | Premier jour à planifier. |
| `previous` | `SeasonPlan` | oui | — | Plan de saison en cours, à réviser. |
| `currentBlock` | `ProgramBlock` | oui | — | Bloc en cours. |
| `adaptation` | `AdaptationSummary` | oui | — | Résumé d'adaptation. |

## Énumérations

Le JSON porte le **code** ; l'ordre des valeurs est celui du contrat.

| Enum | Codes | Sens |
| --- | --- | --- |
| `CatalogDiscipline` | `Musculation`, `Street workout`, `Streetlifting`, `Calisthénie statique`, `Calisthénie dynamique`, `CrossFit / WOD`, `Cardio`, `Mobilité` | Discipline d'un exercice dans la base v1.1 (8 valeurs). |
| `ExerciseLevel` | `Débutant`, `Intermédiaire`, `Avancé`, `Élite` | Niveau d'un exercice dans la base (ordre croissant). |
| `MovementPattern` | `adducteurs_abducteurs`, `auto_massage`, `balistique`, `cardio_continu`, `cardio_fractionne`, `charniere_hanche`, `compression`, `conditionnement`, `corde_a_sauter`, `cou`, `equilibre_mains`, `etirement_dynamique`, `etirement_statique`, `extension_genou`, `extension_hanche`, `extension_rachis`, `fente`, `figure_dynamique_poussee`, `figure_dynamique_tirage`, `figure_statique_mixte`, `figure_statique_poussee`, `figure_statique_tirage`, `flexion_genou`, `flexion_hanche`, `flexion_tronc`, `freestyle`, `gainage_anti_extension`, `gainage_anti_flexion_laterale`, `gainage_anti_rotation`, `gymnastique_crossfit`, `halterophilie`, `isolation_biceps`, `isolation_dos`, `isolation_epaules`, `isolation_pectoraux`, `isolation_trapezes`, `isolation_triceps`, `marche`, `mobilite_articulaire`, `mollets`, `pliometrie`, `porte`, `poussee_horizontale`, `poussee_inclinee`, `poussee_verticale_basse`, `poussee_verticale_haute`, `prehension`, `preparation_scapulaire`, `respiration`, `rotation_tronc`, `souplesse`, `sprint`, `squat`, `tirage_horizontal`, `tirage_vertical`, `transition_muscle_up` | Schéma de mouvement calculé (56 valeurs). |
| `MovementFamily` | `cardio`, `conditionnement`, `cou`, `explosif`, `figure_dynamique`, `figure_statique`, `gainage`, `isolation_bras`, `isolation_haut`, `isolation_jambes`, `jambes_genou`, `jambes_hanche`, `mobilite`, `porte`, `poussee`, `recuperation`, `tirage`, `tronc` | Famille de schémas de mouvement (18 valeurs). |
| `MovementPlane` | `sagittal`, `frontal`, `transversal`, `multiple` | Plan dominant du mouvement. |
| `Articularity` | `polyarticulaire`, `monoarticulaire`, `non_applicable` | Poly- ou mono-articulaire ; sans objet pour les tenues, le cardio, la mobilité. |
| `ContractionMode` | `dynamique`, `isometrique`, `excentrique`, `explosif`, `cyclique`, `passif` | Régime de contraction dominant. |
| `Place` | `salle`, `maison`, `exterieur` | Lieu d'entraînement. |
| `Joint` | `epaule`, `coude`, `poignet`, `lombaires`, `genou`, `hanche`, `cheville` | Articulation suivie par les contraintes articulaires (7 valeurs). |
| `JointStress` | `faible`, `moyenne`, `forte` | Niveau de contrainte articulaire (ordre croissant). |
| `LoadType` | `aucune`, `poids_du_corps`, `lest`, `barre`, `halteres`, `kettlebell`, `machine`, `poulie`, `elastique`, `autre` | Type de charge d'un exercice. |
| `MeasureUnit` | `repetitions`, `secondes`, `distance`, `calories` | Unité principale d'une série (distance en mètres). |
| `Laterality` | `bilateral`, `unilateral`, `alterne` | Latéralité de l'exercice. |
| `FractionSource` | `publiee`, `derivee`, `estimee` | Origine de la fraction du poids du corps. |
| `Sex` | `female`, `male`, `undisclosed` | Sexe déclaré (standards de rang, D7.5). |
| `TrainingDiscipline` | `musculation`, `street_workout`, `streetlifting`, `calisthenics`, `crossfit`, `cardio`, `mobility`, `general_fitness` | Discipline d'entraînement du profil (D3.1, 8 valeurs). |
| `StreetStyle` | `streetlifting`, `sets_reps`, `calisthenics` | Composante du mode street (D3.3). |
| `GuidanceMode` | `assisted`, `free` | Mode assisté ou libre (D3.7, D5.6). |
| `BodyZone` | `neck`, `shoulder`, `elbow`, `wrist_hand`, `upper_back`, `lower_back`, `chest`, `abdomen`, `hip`, `thigh`, `knee`, `lower_leg`, `ankle_foot` | Zone du corps (blessures, limitations, douleurs). |
| `BodySide` | `left`, `right`, `both` | Côté du corps. |
| `LevelMeasure` | `max_reps`, `one_rm_kg`, `max_hold_seconds`, `time_seconds` | Mesure d'un niveau déclaré : répétitions max, 1RM de charge externe en kg (lest seul pour un exercice lesté), tenue max, temps sur une distance. |
| `GoalKind` | `performance`, `habit` | Nature d'un objectif (D3.8). |
| `GoalOrigin` | `user`, `suggested` | Objectif saisi ou suggéré par Koach. |
| `GoalMetric` | `one_rm_kg`, `max_reps`, `max_hold_seconds`, `skill_unlocked`, `time_seconds`, `distance_meters` | Grandeur visée par un objectif de performance : 1RM de charge externe en kg, répétitions max (à une charge donnée si `loadKg`), tenue max, figure débloquée, temps sur une distance, distance en une durée. |
| `ExperienceLevel` | `beginner`, `intermediate`, `advanced`, `elite` | Niveau global d'expérience déclaré (ordre croissant). |
| `HealthScreeningOutcome` | `standard`, `cautious`, `not_answered` | Résultat du questionnaire santé L13 (référence, aucune réponse n'est copiée). |
| `SessionOrigin` | `program`, `imported` | Séance du programme, ou reprise de l'ancien journal de l'application. |
| `SetKind` | `warmup`, `work`, `calibration`, `test` | Rôle d'une série. |
| `PainPhase` | `before`, `during`, `after` | Moment où la douleur est signalée. |
| `SlotRole` | `main`, `secondary`, `accessory`, `skill`, `core`, `conditioning`, `mobility`, `warmup`, `cooldown` | Rôle d'un exercice dans la séance. |
| `LockKind` | `keep_slot`, `require_exercise`, `exclude_exercise`, `keep_day` | Verrou posé par la revue (D4.6). |
| `ReviewKind` | `can_do`, `cannot_do`, `dislike`, `add`, `remove`, `replace` | Action de revue de la passe 1 (D4.5). |
| `VariantKind` | `easier`, `equivalent`, `other_equipment`, `other` | Nature d'une variante proposée (3 ciblées + toutes). |
| `ChangeKind` | `exercise_added`, `exercise_removed`, `exercise_replaced`, `exercise_moved`, `order_changed`, `prescription_changed`, `day_added`, `day_removed` | Changement typé d'un diff de programme. |
| `WeekKind` | `intro`, `build`, `deload`, `test` | Nature d'une semaine du bloc. |
| `LoadBasis` | `external`, `bodyweight`, `bodyweight_plus_external`, `unloaded` | Ce que désigne la charge d'une prescription. |
| `RestructureScope` | `session`, `week`, `block` | Portée d'une restructuration. |
| `ProposalKind` | `load`, `reps`, `volume`, `exercise_swap`, `session_restructure`, `block_restructure`, `deload`, `pain_sparing`, `schedule` | Type de proposition du moteur dynamique. |
| `ProposalScope` | `set`, `exercise`, `session`, `week`, `block` | Portée d'une proposition. |
| `UnlockLevel` | `loads_reps`, `volume`, `exercise_swap`, `session_restructure`, `block_restructure` | Niveau de déblocage des propositions (D5.7, ordre croissant). |
| `AdjustmentKind` | `load_reduced`, `sets_reduced`, `exercise_swapped`, `exercise_removed`, `rest_increased`, `load_increased` | Ajustement d'une séance après le bilan santé. |
| `IntraSessionAction` | `keep`, `load_up`, `load_down`, `reps_up`, `reps_down`, `stop_exercise`, `rest_more` | Conseil pour la série suivante. |
| `CapacityUnit` | `one_rm_kg`, `max_reps`, `max_hold_seconds`, `meters_per_second` | Unité de la capacité estimée d'un exercice : 1RM de charge TOTALE en kg (charge externe + fraction du poids du corps), répétitions max, tenue max, vitesse. |
| `ProposalStatus` | `auto_applied`, `accepted`, `refused`, `undone` | Suite donnée à une proposition (D5.6) : appliquée automatiquement, acceptée, refusée, annulée. |
| `XpSource` | `effort`, `consistency`, `record`, `milestone`, `quest` | Origine d'un gain d'XP (D7.2). |
| `AthleteAttribute` | `strength`, `endurance`, `power`, `technique`, `mobility`, `consistency` | Attribut façon RPG (D7.5). |
| `MovementRankTier` | `unranked`, `bronze`, `silver`, `gold`, `platinum`, `diamond`, `elite` | Rang d'un mouvement (ordre croissant). |
| `QuestKind` | `daily`, `weekly`, `campaign`, `koach` | Famille de quête (D7.6). |
| `QuestStatus` | `active`, `completed`, `expired` | État d'une quête. |
| `KreditSource` | `quest`, `chest`, `level_up`, `milestone`, `record` | Origine d'un gain de Krédits. |
| `DelightKind` | `record`, `chest`, `week_streak`, `session_grade`, `combo`, `ghost`, `first_time`, `level_up`, `rank_up`, `goal_milestone`, `quest_completed` | Événement de plaisir (D8.1). Les cinq derniers sont ajoutés en 0.3.0 (première fois, passage de niveau, nouveau rang, jalon d'objectif, quête terminée). |
| `SessionGrade` | `s`, `a`, `b`, `c` | Note de séance. |
| `RecordKind` | `one_rm_kg`, `max_reps`, `max_hold_seconds`, `volume_kg`, `time_seconds`, `distance_meters` | Nature d'un record (même vocabulaire que les niveaux et les objectifs). |
| `BreakReason` | `vacation`, `illness`, `injury`, `other` | Motif d'une pause déclarée. |
| `TrainingAge` | `under_6_months`, `months_6_to_24`, `years_2_to_5`, `over_5_years` | Ancienneté de pratique régulière de la discipline principale, sans compter les arrêts longs (0.4.0, ordre croissant). |
| `TrainingGap` | `none`, `reduced`, `under_3_weeks`, `weeks_3_to_10`, `weeks_10_to_26`, `months_6_to_24`, `over_2_years` | Interruption en cours au moment de répondre (0.4.0) : aucune (entraînement régulier), entraînement allégé depuis quelques semaines, arrêt de moins de 3 semaines, de 3 à 10 semaines, de 10 semaines à 6 mois, de 6 mois à 2 ans, de plus de 2 ans. |
| `HardSetsBand` | `under_5`, `sets_5_to_9`, `sets_10_to_14`, `sets_15_to_20`, `over_20` | Séries dures par semaine sur un mouvement (à 3 répétitions ou moins de l'échec) (0.4.0, ordre croissant). |
| `CurrentPhase` | `volume`, `heavy`, `post_peak`, `unstructured` | Ce que l'utilisateur fait en ce moment (0.4.0) : du volume, du lourd, il sort d'un pic ou d'une compétition, sans structure. |
| `TrainingEmphasis` | `muscle`, `strength`, `both` | Ce que l'utilisateur cherche surtout en musculation (0.4.0) : du muscle, de la force, les deux. |
| `RunVolumeBand` | `none`, `under_10_km`, `km_10_to_20`, `km_20_to_35`, `km_35_to_50`, `over_50_km` | Distance courue par semaine, en moyenne sur les 4 dernières semaines (0.4.0, ordre croissant). |
| `LongRunBand` | `under_30_min`, `min_30_to_60`, `min_60_to_90`, `over_90_min` | Durée de la plus longue sortie récente (0.4.0, ordre croissant). |
| `StepTenure` | `under_1_month`, `months_1_to_3`, `months_3_to_6`, `over_6_months` | Temps passé à l'étape actuelle d'une figure (0.4.0, ordre croissant). |
| `SleepBand` | `under_6_hours`, `hours_6_to_7`, `hours_7_plus` | Durée habituelle de sommeil par nuit (0.4.0). Valeur HABITUELLE : la nuit précédente est dans le bilan de séance (`HealthCheck.sleepHours`). |
| `StressBand` | `low`, `moderate`, `high` | Stress habituel de la vie hors entraînement, ces dernières semaines (0.4.0). Le stress du jour est dans le bilan de séance (`HealthCheck.stress`). |
| `OccupationalLoad` | `seated`, `on_feet`, `heavy` | Charge physique habituelle du métier ou des journées (0.4.0) : assis, debout ou en mouvement, travail physique lourd (port de charges). |
| `BodyWeightGoal` | `lose`, `maintain`, `gain`, `no_goal` | Évolution voulue du poids de corps en ce moment (0.4.0). |
| `OtherSportKind` | `running`, `cycling`, `swimming`, `other_endurance`, `team_sport`, `combat_sport`, `climbing`, `racket_sport`, `other_strength`, `other` | Autre sport pratiqué régulièrement en plus du programme (0.4.0). |
| `BodyRegion` | `lower_body`, `upper_pull`, `upper_push`, `trunk`, `whole_body` | Grande région sollicitée (0.4.0) : jambes, tirage du haut du corps, poussée du haut du corps, tronc, tout le corps. |
| `ConstraintSince` | `under_6_weeks`, `weeks_6_to_12`, `months_3_to_12`, `over_12_months`, `past_resolved` | Ancienneté d'une gêne déclarée (0.4.0) ; `past_resolved` : antécédent ancien, sans gêne actuelle. |
| `AggravatingMovement` | `pull_bent_arm`, `hang_straight_arm`, `push_support`, `straight_arm_support`, `overhead`, `knee_flexion`, `hip_hinge`, `wrist_extension_grip`, `rings`, `running_jumping`, `deep_shoulder_extension`, `axial_loading`, `elbow_lockout`, `explosive_pull` | Famille de mouvements qui réveille une gêne (0.4.0) : tirage bras fléchis ; suspension ou tirage bras tendus ; poussée en appui (pompes, haut du dips) ; appui bras tendus (planche, équilibre) ; au-dessus de la tête ; flexion de genou (squat, fente) ; charnière de hanche ; prise ou poignet en extension ; anneaux ; course ou sauts ; épaule en extension profonde (bas du dips, transition du muscle-up, back lever) ; charge sur le dos (barre lourde) ; coude tendu à fond sous charge ; tirage explosif. |
| `BenchmarkKind` | `load_reps`, `max_reps`, `max_hold`, `time_trial`, `distance_trial`, `reps_for_time` | Nature d'un test ou d'un record (0.4.0) : charge × répétitions (1 répétition = maximum), répétitions max, maintien max, temps sur une distance, distance en une durée, volume imposé au meilleur temps. |
| `BenchmarkSource` | `declared`, `guided_test`, `competition`, `training_set` | Origine d'un test ou d'un record (0.4.0) : déclaré par l'utilisateur, test guidé, compétition, série d'entraînement retenue par le moteur. |
| `EventKind` | `strength_competition`, `reps_competition`, `freestyle_competition`, `race`, `other_competition`, `personal_test` | Nature d'une échéance (0.4.0) : compétition de force à tentatives (streetlifting), compétition de répétitions (sets & reps, endurance de force), freestyle jugé, course, autre compétition, test personnel daté. |
| `EventPriority` | `main`, `secondary`, `preparation` | Priorité d'une échéance dans la saison (0.4.0) : principale (pic de forme), secondaire, préparation (faite sans affûtage). |
| `RepsEventMode` | `max_reps`, `max_reps_in_time`, `for_time`, `max_hold` | Format d'une épreuve de répétitions (0.4.0) : maximum de répétitions, maximum en un temps limité, volume imposé au meilleur temps, maintien le plus long. |
| `WeakPointKind` | `bottom`, `mid_range`, `lockout`, `dead_start`, `transition`, `grip`, `late_set_fatigue`, `balance`, `mobility`, `speed` | Point faible exprimé simplement (0.4.0) : bas du mouvement, milieu, fin (verrouillage), départ arrêté, transition (muscle-up), prise, fatigue en fin de série, équilibre, mobilité, vitesse. |
| `SpecializationKind` | `exercise`, `skill`, `muscle`, `pattern` | Cible d'une spécialisation (0.4.0) : un mouvement, une figure, un groupe musculaire, un schéma de mouvement. |
| `MaintenancePolicy` | `maintain`, `minimal`, `pause` | Sort du reste pendant une spécialisation (0.4.0) : entretenu à volume réduit, dose minimale, mis en pause (hors objectifs). |
| `SetTechniqueKind` | `standard`, `top_set_backoff`, `cluster`, `rest_pause`, `myo_reps`, `drop_set`, `isometric_hold`, `accentuated_eccentric`, `contrast`, `wave`, `amrap`, `emom`, `density`, `ladder`, `pyramid`, `skill_practice`, `for_time` | Technique de série (0.4.0) : normale, série de tête puis séries allégées, clusters, rest-pause, myo-reps, dégressive, isométrie ou maintien, excentrique accentuée, contraste, vagues, AMRAP, EMOM, densité, échelle, pyramide, pratique de figure, volume imposé au meilleur temps. |
| `SetRole` | `straight`, `top`, `back_off`, `wave`, `test`, `attempt`, `warmup`, `rung`, `interval` | Rôle d'une série dans une technique (0.4.0) : normale, série de tête, série allégée, palier de vague, test, tentative de compétition, montée d'échauffement, marche d'échelle ou de pyramide, intervalle. |
| `IntensityBasis` | `percent_one_rm`, `percent_benchmark`, `rir`, `speed_fraction`, `bodyweight_fraction`, `absolute_speed` | Ce que désigne une intensité (0.4.0) : part du 1RM de charge totale ; part d'un test de référence (répétitions max, maintien max…) ; répétitions en réserve ; part d'une vitesse de référence ; lest en part du poids de corps ; vitesse en mètres par seconde. |
| `AutoregulationKind` | `backoff_from_top_set`, `load_from_rir`, `stop_at_rir`, `stop_on_rep_drop`, `hold_from_best`, `last_set_amrap`, `stop_on_quality_drop` | Règle d'autorégulation portée par une prescription (0.4.0) : séries allégées calculées sur la série de tête RÉALISÉE ; charge corrigée quand le RIR sort de sa plage ; arrêt des séries quand le RIR passe sous un plancher ; arrêt quand les répétitions chutent ; durée de maintien tirée du meilleur maintien du jour ; dernière série ouverte ; arrêt quand la propreté passe sous un plancher. |
| `RestMode` | `passive`, `walk`, `jog` | Nature de la récupération entre deux séries ou deux répétitions de course (0.4.0) : arrêt, marche, trot. |
| `GroupFormat` | `superset`, `circuit`, `rounds_for_time`, `amrap`, `emom`, `chipper`, `intervals` | Format d'un groupe d'exercices enchaînés (0.4.0) : superset, circuit (tours, repos entre les tours), tours au meilleur temps, maximum de tours en un temps, un passage par intervalle, suite imposée faite une fois au meilleur temps, intervalles (effort, récupération). |
| `AttemptFailure` | `strength`, `technique`, `judging` | Cause d'une tentative manquée (0.4.0) : force, technique, décision d'arbitre. |
| `EventObjective` | `secure_total`, `max_total`, `record` | Objectif du jour d'une compétition de force (0.4.0) : assurer un total, viser le plus gros total, tenter un record. |
| `TestKind` | `amrap_estimate`, `rep_max`, `one_rm`, `max_reps`, `max_hold`, `time_trial`, `distance_trial`, `attempt_simulation` | Série ou séance de test (0.4.0) : série d'estimation sous-maximale (répétitions + RIR), xRM, maximum sur une répétition, répétitions max, maintien max, temps sur une distance, distance en une durée, simulation de tentatives. |
| `SeasonPhaseKind` | `accumulation`, `intensification`, `realization`, `taper`, `competition`, `transition`, `test`, `deload`, `maintenance`, `reintroduction` | Phase d'un plan de saison (0.4.0) ; `reintroduction` : reprise progressive après une coupure. |
| `WeekIntent` | `intro`, `accumulation`, `intensification`, `realization`, `deload`, `taper`, `test`, `competition`, `transition`, `maintenance` | Intention d'une semaine (0.4.0) ; complète `WeekKind`, qui reste renseigné. |
| `DayStress` | `heavy`, `medium`, `light` | Ondulation dans la semaine (0.4.0) : jour lourd, moyen ou léger, pour une séance ou pour un mouvement. |
| `UndulationModel` | `none`, `weekly`, `daily` | Modèle d'ondulation d'un bloc (0.4.0) : aucune, d'une semaine à l'autre, d'un jour à l'autre. |
| `ProposalDetail` | `skill_step_up`, `skill_step_down`, `technique_change`, `test_scheduled`, `taper_adjust`, `specialization`, `season_update` | Précision d'une proposition du moteur dynamique (0.4.0) ; complète `ProposalKind`, qui reste renseigné. |

## Registre des codes de raison

| Code | Paramètres | Sens |
| --- | --- | --- |
| `plan.discipline_share` | `discipline` (string), `pct` (int) | Exercice ou séance choisi pour respecter le dosage d'une discipline. |
| `plan.movement_coverage` | `pattern` (string) | Couvre un schéma de mouvement qui manquait. |
| `plan.muscle_volume` | `muscle` (string), `weeklySets` (double), `targetLow` (double), `targetHigh` (double) | Ramène le volume hebdomadaire d'un muscle dans sa plage. |
| `plan.fatigue_balance` | `dayIndex` (int) | Répartit la fatigue entre les séances. |
| `plan.time_budget` | `minutes` (int) | Tient dans le temps disponible ce jour-là. |
| `plan.equipment_available` | `place` (string) | Faisable avec le matériel et le lieu du profil. |
| `plan.equipment_missing` | `equipment` (string) | Écarté : matériel absent du profil. |
| `plan.level_match` | `difficulty` (int) | Difficulté adaptée au niveau déclaré. |
| `plan.prerequisite_missing` | `exerciseId` (exercise) | Écarté : un palier précédent n'est pas acquis. |
| `plan.joint_limitation` | `joint` (string), `discomfort` (int) | Écarté ou remplacé : contrainte sur une articulation limitée. |
| `plan.user_likes` | — | Exercice aimé par l'utilisateur. |
| `plan.user_dislikes` | — | Écarté : l'utilisateur n'aime pas cet exercice. |
| `plan.user_cannot_do` | — | Remplacé : l'utilisateur ne sait pas le faire. |
| `plan.user_added` | — | Ajouté à la demande de l'utilisateur. |
| `plan.user_removed` | — | Retiré à la demande de l'utilisateur. |
| `plan.user_replaced` | — | Variante choisie par l'utilisateur. |
| `plan.lock_kept` | — | Inchangé : validé par l'utilisateur. |
| `plan.goal_support` | `goalId` (string) | Sert un objectif du profil. |
| `plan.variety` | — | Évite une redondance avec un exercice déjà présent. |
| `plan.reoptimized` | `scoreBefore` (double), `scoreAfter` (double) | A bougé parce que le reste du programme a été ré-optimisé. |
| `plan.variant_easier` | `difficultyDelta` (int) | Variante plus facile. |
| `plan.variant_equivalent` | `similarity` (double) | Variante équivalente. |
| `plan.variant_other_equipment` | `equipment` (string) | Variante avec un autre matériel. |
| `plan.start_load_conservative` | `fractionOfEstimate` (double) | Charge de départ prudente. |
| `plan.to_calibrate` | — | Charge à caler sur les premières séances. |
| `plan.week_kind` | `kind` (string) | Logique de la semaine (introduction, montée, décharge, test). |
| `plan.progression_from_previous_block` | `exerciseId` (exercise) | Reprend ou fait progresser un exercice du bloc précédent. |
| `plan.adaptation_applied` | `proposalKind` (string) | Tient compte du résumé d'adaptation. |
| `plan.cautious_health` | — | Programme prudent : questionnaire santé en mode prudent. |
| `plan.restructure_scope` | `scope` (string) | Restructuration limitée à cette portée. |
| `adapt.flames_below_target` | `delta` (double), `sets` (int) | Séries notées plus faciles que la cible. |
| `adapt.flames_above_target` | `delta` (double), `sets` (int) | Séries notées plus dures que la cible. |
| `adapt.set_failed` | `missingReps` (int) | Série manquée. |
| `adapt.load_up` | `deltaKg` (double) | Charge augmentée. |
| `adapt.load_down` | `deltaKg` (double) | Charge diminuée. |
| `adapt.reps_up` | `delta` (int) | Répétitions augmentées. |
| `adapt.reps_down` | `delta` (int) | Répétitions diminuées. |
| `adapt.volume_up` | `sets` (int) | Séries ajoutées. |
| `adapt.volume_down` | `sets` (int) | Séries retirées. |
| `adapt.calibration` | `session` (int) | Séance de calibrage : la charge se cale. |
| `adapt.estimate_updated` | `exerciseId` (exercise), `capacity` (double), `standardError` (double) | Capacité estimée mise à jour. |
| `adapt.low_confidence` | `confidence` (double) | Confiance du modèle insuffisante pour proposer davantage. |
| `adapt.unlock_level` | `level` (string) | Niveau de déblocage atteint ou requis. |
| `adapt.health_low` | `overall` (int) | Bilan santé bas : séance allégée. |
| `adapt.sleep_low` | `sleepQuality` (int) | Sommeil mauvais. |
| `adapt.time_short` | `minutesAvailable` (int), `minutesPlanned` (int) | Moins de temps que prévu. |
| `adapt.pain_reported` | `zone` (string), `intensity` (int) | Douleur signalée : la zone est épargnée. |
| `adapt.pain_persistent` | `zone` (string), `sessions` (int) | Douleur persistante : règle santé L13 (renvoi vers un professionnel). |
| `adapt.fatigue_high` | `readiness` (double) | Fatigue accumulée élevée. |
| `adapt.deload` | `weekIndex` (int) | Semaine de décharge proposée. |
| `adapt.plateau` | `exerciseId` (exercise), `weeks` (int) | Stagnation sur un exercice. |
| `adapt.exercise_skipped` | `exerciseId` (exercise), `times` (int) | Exercice régulièrement sauté. |
| `adapt.missed_sessions` | `missed` (int), `planned` (int) | Séances manquées. |
| `adapt.resume_after_break` | `days` (int) | Reprise après une coupure. |
| `adapt.no_rating` | `sets` (int) | Séries sans note : non prises en compte. |
| `quest.xp_effort` | `sets` (int), `capped` (bool) | XP de l'effort réel de la séance (plafonné). |
| `quest.xp_consistency` | `weeks` (int) | XP de régularité. |
| `quest.xp_record` | `exerciseId` (exercise), `recordKind` (string) | XP d'un record. |
| `quest.xp_milestone` | `goalId` (string), `fraction` (double) | XP d'un jalon d'objectif. |
| `quest.xp_quest` | `questId` (string) | XP d'une quête terminée. |
| `quest.level_up` | `level` (int) | Passage de niveau. |
| `quest.prestige` | `prestige` (int) | Passage de prestige. |
| `quest.rank_up` | `exerciseId` (exercise), `tier` (string) | Nouveau rang sur un mouvement. |
| `quest.weak_point` | `attribute` (string) | Quête Koach ciblant un point faible. |
| `quest.campaign_chapter` | `blockIndex` (int) | Chapitre de campagne lié à un bloc. |
| `quest.goal_suggested` | `exerciseId` (exercise) | Objectif suggéré d'après le profil et les données. |
| `quest.prediction_updated` | `goalId` (string) | Prédiction de date mise à jour. |
| `adapt.ratings_uninformative` | `confirmRate` (double), `sets` (int) | Notes presque toujours confirmées telles quelles : elles pèsent moins, la performance réelle pèse davantage. |
| `adapt.benchmark_set` | `rir` (double) | Série repère : dernière série ouverte, autant de répétitions que possible en gardant la réserve indiquée. |
| `adapt.place_changed` | `place` (string) | Lieu du jour différent du lieu prévu : exercice remplacé par un équivalent faisable sur place. |
| `adapt.load_held` | `cause` (string) | Charge non augmentée (échec non prévu, douleur, bilan bas, plafond de hausse). |
| `adapt.increment_coarse` | `stepKg` (double) | Plus petit incrément de charge trop grand : la progression passe par les répétitions. |
| `adapt.readiness` | `readiness` (double) | Forme du jour estimée (bilan santé, fatigue modélisée, séries déjà faites). |
| `adapt.volume_response` | `muscle` (string), `weeklySets` (double) | Volume hebdomadaire d'un groupe musculaire ajusté d'après la réponse observée. |
| `adapt.load_floor` | `minKg` (double) | Plus petite charge disponible encore trop lourde pour cet exercice : il est remplacé ou retiré de la séance. |
| `quest.no_reward_pain` | `zone` (string), `intensity` (int) | Séance faite malgré une douleur déclarée avant la séance : aucune récompense (ni XP, ni coffre, ni note, ni quête). |
| `quest.xp_capped` | `scope` (string), `cap` (int) | Gain d'XP borné par un plafond (`session`, `week`, `records`). |
| `quest.combo` | `length` (int), `bonus` (int) | Combo : séries consécutives dans la cible, bonus plafonné. |
| `quest.session_grade` | `completion` (double), `accuracy` (double), `records` (int) | Composantes de la note de séance : réalisation, justesse des flammes, records. |
| `quest.daily` | `dayKind` (string) | Quête du jour, adaptée au jour (`training`, `rest`, `break`). |
| `quest.weekly` | `planned` (int) | Quête de la semaine, bornée par les séances prévues. |
| `quest.campaign_boss` | `blockIndex` (int) | Boss de campagne : séance de test ou dernière séance du bloc. |
| `quest.lagging_exercise` | `exerciseId` (exercise) | Quête Koach : exercice du programme le plus souvent écourté ou sauté. |
| `quest.weekday_focus` | `weekday` (int) | Quête Koach : jour de la semaine le moins régulier. |
| `quest.xp_rest` | `days` (int) | Part de l'XP de régularité due aux jours de repos respectés. |
| `quest.streak` | `weeks` (int) | Série de semaines réussies (jalon ou longueur atteinte). |
| `quest.streak_paused` | `cause` (string) | Semaine en pause : la série ne bouge pas. `cause` : motif de la pause déclarée (`vacation`, `illness`, `injury`, `other`) ou `pain` (séance faite malgré une douleur). |
| `quest.chest` | `guaranteed` (bool) | Coffre surprise (tirage, ou garantie après une série de séances sans coffre). |
| `quest.goal_late` | `goalId` (string) | Objectif en retard : une date ou une cible ajustée est proposée. |
| `quest.first_time` | `exerciseId` (exercise) | Première fois sur un exercice. |
| `quest.ghost_beaten` | `exerciseId` (exercise), `reference` (string) | Fantôme battu : mieux que la dernière fois (`last`) ou que la meilleure fois (`best`). |
| `quest.start_bonus` | `sessions` (int) | Bonus de départ plafonné (désactivé par défaut). |
| `plan.season_phase` | `phase` (string), `weeksToEvent` (int) | Le bloc réalise une phase du plan de saison, à tant de semaines de l'échéance. |
| `plan.taper` | `volumeFactor` (double), `daysToEvent` (int) | Affûtage : volume réduit, intensité gardée, avant une échéance. |
| `plan.peak_event` | `eventId` (string) | La saison est construite pour arriver en forme à cette échéance. |
| `plan.undulation` | `stress` (string) | Ondulation : jour lourd, moyen ou léger. |
| `plan.technique` | `technique` (string) | Technique de série choisie pour cet exercice. |
| `plan.technique_withheld` | `technique` (string), `cause` (string) | Technique avancée non servie : un prérequis manque (ancienneté, niveau, test, récupération, gêne). |
| `plan.specialization` | `target` (string), `weeks` (int) | Spécialisation : priorité donnée à une cible pendant tant de semaines. |
| `plan.maintenance_volume` | `muscle` (string), `weeklySets` (double) | Volume d'entretien du reste pendant une spécialisation ou un affûtage. |
| `plan.skill_step` | `exerciseId` (exercise), `stepIndex` (int) | Étape de la progression d'une figure. |
| `plan.skill_plateau` | `exerciseId` (exercise) | Figure bloquée à la même étape depuis longtemps : la méthode change (autre variante, autre dosage). |
| `plan.recent_load` | `exerciseId` (exercise), `sessions` (int) | Premier bloc calé sur la charge d'entraînement actuelle déclarée. |
| `plan.test_scheduled` | `testKind` (string) | Test programmé (série d'estimation, maximum, maintien, course). |
| `plan.benchmark_used` | `exerciseId` (exercise), `source` (string) | Charge ou durée calculée d'après un test ou un record du profil. |
| `plan.percent_based` | `pct` (double) | Charge donnée en part du maximum. |
| `plan.recovery_profile` | `factor` (string), `level` (string) | Tient compte d'une réponse de récupération et de vie (sommeil, stress, métier physique, déficit énergétique). |
| `plan.constraint_history` | `zone` (string), `since` (string) | Zone à antécédent : progression plus prudente des mouvements qui la chargent. |
| `plan.concurrent_sport` | `sport` (string), `sessions` (int) | Tient compte d'un autre sport : séances lourdes placées à distance. |
| `plan.training_age` | `band` (string) | Volume, intensité ou techniques réglés sur l'ancienneté d'entraînement. |
| `plan.return_from_gap` | `gap` (string) | Reprise après une interruption : redémarrage progressif. |
| `plan.weak_point` | `exerciseId` (exercise), `kind` (string) | Exercice d'assistance choisi pour un point faible déclaré. |
| `plan.event_specific` | `eventId` (string) | Travail spécifique d'une épreuve (mouvements, enchaînements, durées de la compétition). |
| `adapt.backoff_from_top_set` | `topLoadKg` (double), `pct` (double) | Séries allégées calculées sur la série de tête réalisée. |
| `adapt.rir_cap` | `rir` (double) | Plafond d'effort atteint : charge abaissée pour garder la réserve prévue. |
| `adapt.test_result` | `exerciseId` (exercise), `value` (double), `standardError` (double) | Résultat d'un test et son incertitude. |
| `adapt.skill_step_up` | `exerciseId` (exercise) | Critère de passage tenu : étape suivante de la figure. |
| `adapt.skill_step_down` | `exerciseId` (exercise) | Mauvais jour ou critère perdu : étape plus facile. |
| `adapt.skill_hold` | `exerciseId` (exercise), `weeksAtStep` (int) | Étape gardée : critère non tenu, ou durée minimale à l'étape non atteinte (tendons). |
| `adapt.phase_respected` | `phase` (string) | Ajustement limité par l'intention de la phase. |
| `adapt.taper_no_volume` | — | Affûtage : aucun volume ajouté, intensité gardée. |
| `adapt.event_near` | `days` (int) | Échéance proche : décisions prudentes. |
| `adapt.attempt_opener` | `pct` (double) | Ouverture choisie comme une part du maximum estimé : une barre sûre. |
| `adapt.attempt_next` | `successProbability` (double) | Tentative suivante choisie d'après la précédente et l'incertitude du maximum. |
| `adapt.attempt_conservative` | `cause` (string) | Tentative prudente (incertitude élevée, échec précédent, bilan bas, pesée). |
| `adapt.pacing` | `targetReps` (int) | Stratégie de rythme d'une épreuve de répétitions. |
| `adapt.recovery_profile` | `factor` (string), `level` (string) | Tolérance réglée sur une réponse de récupération et de vie du profil. |
| `adapt.tendon_load` | `zone` (string), `weeks` (int) | Charge des tendons surveillée : progression en bras tendus ou en appui ralentie. |
| `adapt.technique_executed` | `technique` (string) | Technique de série exécutée telle que prescrite. |
| `adapt.mini_set_stop` | `cause` (string) | Mini-séries arrêtées (répétitions manquées, plafond atteint, qualité). |
