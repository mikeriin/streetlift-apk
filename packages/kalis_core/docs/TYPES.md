# Types des contrats de kalis_core

Fichier généré par `tool/gen_contracts.py` depuis `tool/contracts_spec.py` — ne pas modifier à la main.

Clé JSON = nom du champ. « Optionnel » : la clé est absente du JSON quand la valeur est nulle (jamais de valeur par défaut). Les types racine portent `schemaVersion`.

## Versions de schéma

| Type | Version |
| --- | ---: |
| `AthleteProfile` | 2 |
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

## Commun

### `Reason`

Code de raison et ses paramètres (aucun texte : les phrases viennent de kalis_koach et de l'application).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `code` | texte | non | longueur ≥ 1 | Identifiant stable du registre des codes de raison. |
| `params` | objet JSON | non | — | Paramètres typés du code (nombres, chaînes, booléens), écrits par clés triées. |

Invariant : `code` figure au registre ; `params` contient exactement les paramètres déclarés, du bon type.

## Profil d'athlète v2

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

### `HealthScreeningRef`

Référence au questionnaire santé L13 (aucune réponse n'est copiée ici).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `questionnaireId` | texte | non | longueur ≥ 1 | Identifiant et version du questionnaire. |
| `answeredOn` | jour civil | oui | — | Jour de réponse. |
| `outcome` | `HealthScreeningOutcome` | non | — | Résultat : standard, mode prudent, non répondu. |

### `AthleteProfile`

Profil d'athlète v2 (D3).

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 2 | Version du schéma (2). |
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

Invariant : Jours de `availability` distincts ; lieux, matériel, exercices aimés et détestés sans doublon ; aimés ∩ détestés = ∅.

Invariant : Un seul incrément par type de charge ; `updatedOn` ≥ `createdOn`.

Invariant : Mode street activé ⇒ `disciplines` est l'image du mode street (`StreetMode.toDisciplineMix()`).

Invariant : `equipmentByPlace` : un lieu au plus une fois, parmi `places`, matériel inclus dans `equipment` ; `DaySlot.place` parmi `places` ; su ∩ pas su = ∅.

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

Invariant : Au moins une mesure parmi `reps`, `seconds`, `distanceMeters`, `calories`.

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

### `TrainingLog`

Journal de séances.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `schemaVersion` | entier | non | ≥ 1 | Version du schéma (1). |
| `sessions` | liste de `SessionRecord` | non | — | Séances, par date croissante. |
| `breaks` | liste de `TrainingBreak` | oui | — | Pauses déclarées. |

Invariant : Identifiants de séance uniques ; dates croissantes (au sens large).

## Interface `plan` (kalis_plan, G4)

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

Invariant : Une seule famille de mesure : répétitions, temps, distance ou calories ; bornes basses ≤ bornes hautes, renseignées ensemble ; `setTargets`, s'il est présent, a `sets` éléments.

### `DayPrescription`

Prescriptions d'une séance.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `dayIndex` | entier | non | ≥ 0 | Jour d'entraînement. |
| `items` | liste de `ExercisePrescription` | non | — | Exercices, dans l'ordre. |

### `WeekPrescription`

Prescriptions d'une semaine du bloc.

| Champ | Type | Optionnel | Contraintes | Sens |
| --- | --- | --- | --- | --- |
| `weekIndex` | entier | non | ≥ 0 | Semaine dans le bloc (0 = première). |
| `kind` | `WeekKind` | non | — | Nature de la semaine. |
| `days` | liste de `DayPrescription` | non | — | Séances. |

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

## Interface `adapt` (kalis_adapt, G8)

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

## Interface `quest` (kalis_quest, G11)

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
| `DelightKind` | `record`, `chest`, `week_streak`, `session_grade`, `combo`, `ghost` | Événement de plaisir (D8.1). |
| `SessionGrade` | `s`, `a`, `b`, `c` | Note de séance. |
| `RecordKind` | `one_rm_kg`, `max_reps`, `max_hold_seconds`, `volume_kg`, `time_seconds`, `distance_meters` | Nature d'un record (même vocabulaire que les niveaux et les objectifs). |
| `BreakReason` | `vacation`, `illness`, `injury`, `other` | Motif d'une pause déclarée. |

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
