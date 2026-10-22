# Kalis Track — Refonte UI 2.4.0

Mise à jour : 22 septembre 2026. Version **2.4.0+49**.

Cette livraison ajoute la couche « jeu » de la progression. Navigation, dock,
palette et catalogue 2.3.0 sont inchangés.

## Modèle dérivé (`lib/game.dart`) — intégré

- [x] Records personnels par nom d'exercice (`exerciseBests`, `recordFor`) : 1RM estimé Epley pour les séries lestées, reps pour le poids de corps, séance en cours exclue.
- [x] Attributs (`CharacterSheet`) : Force / Endurance / Technique / Régularité, 0-100 par courbes par morceaux (`curveScore`), niveau 1-10.
- [x] Série avec boucliers (`StreakInfo`) : règle des deux jours conservée ; +1 bouclier toutes les trois semaines validées, deux en réserve, consommé sur un trou ; semaine en cours neutre.
- [x] Objectifs adaptatifs (`WeeklyGoal`, `sessionGoalFraction`) : moyenne + 1 entre 2 et les journées du programme ; part de séries entre 75 et 100 %.
- [x] Campagne (`computeChapters`, un chapitre par `blockKey`), boss (`computeBosses`, journées `TEST…`), saisons (`computeSeasons`, dix semaines), titres, rareté (`rarityOf`).
- [x] `GameState.compute` : agrégat mis en cache dans le store, invalidé avec la progression ; `bonusCredits` = chapitres bouclés + boss vaincus ; `prestigeOf`.
- [x] `RewardSummary.build` : différence entre deux `Progression` (XP, niveau, badges, défis, records WOD, semaine validée) + records de séries, objectif de séance, crédits.
- [x] `Progression.weeks` exposé (toutes les semaines actives).

## Store — intégré

- [x] `AppSettings` : `celebrations`, `weeklyGoal`, `title` (sérialisés, valeurs par défaut sûres).
- [x] `game`, `displayTitle`, `consumeReward`, `sessionRecords`, `liveRecord` ; `creditsEarned` = barème + `bonusCredits`.
- [x] `markSessionDone` (journée d'entraînement passée à « fait ») et `addWodResult` déposent un `RewardSummary` ; `checkLevelUp` (ré-exporté par `levelup.dart`) l'affiche.

## Écrans — intégré

- [x] `lib/rewards.dart` : `RewardScreen` (compteur, jauge multi-niveau `_XpMeter`, lignes `_Appear` différées sans minuteur, cérémonie `_Ceremony`, confettis `_ConfettiPainter` sur un seul `AnimationController`), repli SnackBar si célébrations désactivées, ancien dialogue conservé pour un niveau gagné hors séance.
- [x] `lib/game_widgets.dart` : `RankInsignia`, `AttributeRadar`, `CharacterCard`, `showCharacterSheet`, `WeeklyGoalCard`/`showWeeklyGoal`, `StreakCard`/`showStreak`, `MainQuestCard`, `SeasonQuests`, `CampaignStrip` (`SingleChildScrollView` horizontal, pas de `ListView` imbriqué), `BossCard`/`showBoss`, `SeasonCard`/`showSeasons`, `SelfCompareCard`, `showTitles`, `RarityChip`.
- [x] STATS · Aperçu : feuille de personnage, objectif + série, quêtes, campagne (chapitres, boss, saison), toi contre toi-même, puis les sections existantes.
- [x] STATS · Parcours : arbre inchangé (clés, textes, « Recrue » une seule fois), rareté sur chaque badge, puis campagne, boss, saison, quêtes de saison, titres, défis, texte final conservé en dernière position.
- [x] Séance : bannière « RECORD » à la validation d'une série, objectif de séance sur le bilan.
- [x] Réglages : « Progression et jeu » (Célébrations, objectif hebdo).

## Tests

- [x] `test/game_test.dart` : courbes, records, boucliers, objectifs, rareté, campagne/boss/saisons sur le programme réel, titres et crédits dérivés, bilan, dépôt/consommation d'un bilan.
- [x] Contrats conservés : `progression_test` (barème, badges, séries), `stats_test`, `progression_screens_test`, `level_fill_test`, `screens_test`, `ui_refactor_test`, `motion_test`.

## Validation et livraison

Voir `AUDIT_2.4.0.md`. Aucune analyse, compilation ni test Flutter n'a pu être exécuté ici.

## Historique

Les checklists 1.8.7 à 2.3.0 restent dans `docs/REFONTE_UI_*.md`.
