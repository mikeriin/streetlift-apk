# Kalis Track — Refonte UI 2.4.1

Mise à jour : 24 septembre 2026. Version **2.4.1+50**.

Version corrective : écran de récompenses et affichage du niveau après une
séance. Navigation, dock, palette, catalogue 2.3.0 et couche jeu 2.4.0 sont
inchangés.

## Écran de récompenses (`lib/rewards.dart`) — corrigé

- [x] `checkLevelUp(context, {after})` : le bilan est poussé depuis le contexte du navigateur (toujours monté), plus depuis celui d'une tuile ou d'un écran reconstruit entre-temps.
- [x] `_FinishPage` (`lib/session_screen.dart`) : après `markSessionDone`, la page referme la séance (`nav.pop()`) puis appelle `checkLevelUp` elle-même, en passant la fermeture de sa route (`ModalRoute.completed`). Un bilan n'attend plus l'écran d'origine ; accueil et Arsenal gardent leur appel au retour pour un niveau gagné hors bilan (jour de repos).
- [x] `openProgramDay(nav, week, day)` (`lib/home_screen.dart`) : point d'entrée commun accueil / notification de rappel — historique si la journée est faite, séance sinon, vérification au retour via le navigateur. `main.dart` l'utilise dans `Notif.onOpen`.
- [x] `RewardScreen` : une seule chronologie (`_timeline`, `AnimationController`) pour le compteur, la jauge, les bonus (`_Appear`), la cérémonie et les confettis ; démarrage après la fin de la transition d'entrée **et** la fermeture de la séance, puis `endOfFrame`. Compteur à +0 XP avant le départ ; « Réduire les animations » place la chronologie à 1 immédiatement. Aucun `Timer`, aucune boucle.
- [x] Clé `reward-xp` sur le compteur pour les tests ; `reward-continue` et `reward-ceremony` conservées.

## Affichage du niveau — corrigé

- [x] `lib/store_widget.dart` : `StoreWidget`, `StatelessWidget` dont l'élément (`_StoreElement`) s'abonne au store au montage (`markNeedsBuild`) et se désabonne au démontage. Un widget `const` sous un `ListenableBuilder` n'était jamais reconstruit par son parent.
- [x] `LevelPill` (`levelup.dart`), `_Credits` (`arsenal_screen.dart`), `CharacterCard`, `WeeklyGoalCard`, `StreakCard`, `MainQuestCard`, `SeasonQuests`, `CampaignStrip`, `BossCard`, `SeasonCard`, `SelfCompareCard` (`game_widgets.dart`) étendent `StoreWidget`. Aucun nœud ajouté à l'arbre, aucune clé ni texte modifié.
- [x] `store.game` recalculé dès que `progression` change d'instance (plus de jeu de la veille servi après minuit).
- [x] Sauvegarde : définitions JSON des WODs préchargés mémorisées (`_seedJson`), moitié moins d'encodages à chaque écriture.

## Tests

- [x] `test/reward_flow_test.dart` : huit tests (pastille, crédits, carte hebdo, sonde `StoreWidget` et désabonnement, bilan après ouverture « nue », rappel → séance / historique, décompte de zéro au gain complet, « Réduire les animations »).
- [x] Contrats conservés : `game_test`, `progression_test`, `stats_test`, `progression_screens_test`, `level_fill_test`, `screens_test`, `ui_refactor_test`, `persistence_screen_test`, `motion_test`.

## Validation et livraison

Voir `AUDIT_2.4.1.md`. Aucune analyse, compilation ni test Flutter n'a pu être exécuté ici.

## Historique

Les checklists 1.8.7 à 2.4.0 restent dans `docs/REFONTE_UI_*.md`.
