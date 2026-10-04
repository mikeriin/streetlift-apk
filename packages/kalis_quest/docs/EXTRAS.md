# `QuestOutcome.extras` — données de présentation de kalis_quest

Objet JSON rendu à chaque appel de `KalisQuest.evaluate`, recalculé entièrement depuis le journal, les
registres et l'état : l'application n'a rien à en stocker. `schema` vaut 1 ; les évolutions seront
additives. Aucun texte : des codes, des identifiants du catalogue, des nombres. Dates au format
`AAAA-MM-JJ`.

| Clé | Contenu |
| --- | --- |
| `schema` | Version du format (1). |
| `startedOn` | Jour de démarrage du registre (premier appel). |
| `streak` | Série de semaines : `current`, `best`, `flameSize` (0 à 10, voir ci-dessous), `lastWeek` (`success`, `paused`, `incomplete`, ou `none` avant la première semaine close), `week` : `monday`, `planned` (séances prévues cette semaine, hors pauses), `done`, `needed` (séances à faire pour réussir la semaine : les 3/4, arrondis au-dessus). |
| `recap` | Récapitulatif façon story : `lastWeek` (dernière semaine close, absent avant) et `thisWeek` (semaine en cours). Chacun : `monday`, `closed`, `status`, `sessionsPlanned`, `sessionsDone` (semaine close seulement), `sessions`, `workSets`, `volumeKg` (charge totale × répétitions des exercices chargés), `xp`, `kredits`, `chests`, `questsCompleted`, `levelFrom`, `levelTo` (niveau global : prestige × 100 + niveau), `grades` (`s`, `a`, `b`, `c` : nombre de séances), `bestGrade`, `records` (5 au plus, par gain décroissant : `exerciseId`, `kind`, `value`, `previous`, `gain`). |
| `comparisons` | Comparaisons dans le temps, une par recul (30, 91, 365 jours) : `daysAgo`, `available` (faux si le journal ne remonte pas jusque-là), `now` et `then` (fenêtres de 28 jours : `sessionsPerWeek`, `workSetsPerWeek`, `volumeKgPerWeek`), `exercises` (5 au plus, par progression décroissante : `exerciseId`, `kind`, `now`, `then`, `change`). |
| `ghost` | Fantôme, par exercice (ceux de la séance prévue aujourd'hui, puis ceux des 90 derniers jours, 60 au plus) : `last` (dernière séance) et `best` (meilleure séance) avec `date`, `sessionId`, `score` et `sets` (séries de travail dans l'ordre : `loadKg`, `reps`, `seconds`, `distanceMeters`, `flames`). Les séances faites malgré une douleur n'y figurent pas. |
| `ranks` | Détail par mouvement de référence : `measure` (`load`, `reps`, `hold`, `run`), `points` (rang, 0 à 7), `current` (niveau actuel, performances anciennes diminuées), `value` (meilleure performance : kg de charge externe ou de lest, répétitions, secondes), `valueExerciseId`, `nextValue` (seuil du rang suivant, même unité, au poids de corps du profil), `nextExerciseId` (progression à tenir, figures). |
| `rankOf` | Héritage : pour chaque exercice du bloc en cours et des 28 derniers jours qui a un rang, le mouvement de référence dont il affiche le rang. |
| `grades` | Notes des 10 dernières séances récompensées : `sessionId`, `date`, `grade`, `score` (0 à 100), `combo`. |
| `goals` | Par objectif de performance : `expectedMilestoneDates` (dates prévues des quatre jalons, à intervalles égaux entre la création et l'échéance), `ambition` (part de l'XP de jalon, 0 si les jalons ne sont pas payés). |
| `level` | `xpPerWeek` (rythme des 28 derniers jours), `nextLevelOn` (date du prochain niveau à ce rythme ; absent sans XP récent). |
| `totals` | `sessions` (séances récompensées), `chests`, `questsDone` (par famille). |

**Taille de la flamme** : 1 dès la première semaine réussie, puis un cran de plus à 2, 3, 4, 6, 8, 12,
16, 26 et 52 semaines de suite (`QuestParams.flameSizeWeeks`).

**Score du fantôme** : charge totale × répétitions pour un exercice chargé, sinon répétitions, secondes,
mètres ou calories, sommés sur les séries de travail de l'exercice dans la séance. L'événement `ghost`
(`DelightEvent`) est émis quand le score d'un exercice dépasse celui de la dernière fois ; son code de
raison dit s'il dépasse aussi la meilleure fois.
