# Kalis Track — Refonte UI 2.5.0

Mise à jour : 24 septembre 2026. Version **2.5.0+51**.

Le catalogue de WODs devient une boutique de jeu : vitrine éditoriale, essai
du jour, remises hebdomadaires réelles, liste d'envies avec jauge, couvertures
procédurales, fiche produit et révélation au déblocage. Rien d'aléatoire,
aucun compte à rebours truqué, aucun crédit repris.

## Économie (`lib/progression.dart`, `lib/game.dart`, `lib/store.dart`)

- [x] `Progression.creditsForLevel` : 3 offerts, +2 par niveau, +3 tous les 5 niveaux ; strictement supérieur à l'ancien barème à tout niveau (aucun solde ne baisse).
- [x] `GameState` : `fullWeeks` (semaines à trois entraînements), `chapterCredits` (+3), `bossCredits` (+5), `weekCredits` (+1) ; `bonusCredits` = somme.
- [x] `basePrice` (paliers 1-4 crédits) ; `wodCost` = base − vitrine (−1) − essai terminé (−1), plancher 1 ; `discountOf`, `missingFor`, `triedAndDone`.
- [x] `unlocked` ne passe plus par `wodCost` (pas de récursion) ; le prix payé reste figé dans `unlockedWods`.
- [x] Sélections déterministes (`storeClock` remplaçable) : `trialWod` (jour, hors vitrine, niveau ±1, tenté seulement aujourd'hui), `weeklyPicks` / `weeklyIds` (semaine, trois formats, niveau −1 à +2), `recommended()` (jour, niveau ±1, hors essai et vitrine). Caches vidés par `notifyListeners()`.
- [x] `canRun` = possédé ou essai du jour ; `wod_screen.dart` l'utilise pour le chrono, le score et l'accès.
- [x] Liste d'envies : `wishlist`, `wished`, `toggleWish`, `wishedWods`, `wishTarget` ; retirée à l'achat ; sauvegardée dans le document d'état (`wishlist`, format 3, absent = vide) et validée à l'import.
- [x] `untilMidnight`, `daysUntilNewWeek` : minuteurs calculés à partir de la date réelle.

## Vitrine (`lib/wod_store.dart`, nouveau)

- [x] `tierOf` / `tierLabel` / `TierChevrons` : Standard, Avancé, Élite, Légende ; chevrons toujours accompagnés d'un libellé.
- [x] `WodCover` + `_CoverPainter` : dégradé bordeaux, motif par famille (`motifOf` : speed, stack, rings, ticks, rungs, stairs, blocks, ramp, ladder), reflet Élite / Légende, vignette, version assombrie ; `RepaintBoundary`, aucune image.
- [x] `WodPriceTag` / `storeStateOf` : possédé (record), essai offert, prix (barré si remise), « plus que 1 crédit », cadenas ; le rouge sert de fond, jamais de texte sur fond sombre.
- [x] `WodStoreCard` (rail 5:4), `StoreRail` (hauteur naturelle, `SingleChildScrollView` horizontal), `WodHero` (essai du jour 16:9, « Essayer · offert », « Voir la fiche »), `WishGoalCard` (jauge crédits / prix, distance en crédits ou en XP), `CreditsCard` (solde, prochain gain, jauge d'XP, phrase de règle), `showCreditRules` (feuille des gains).
- [x] `UnlockReveal` + `_SheenPainter` : reflet joué une fois (0 → 1), respiration d'échelle ±3,5 %, sans boucle.
- [x] Textes : `storeTagline` (accroche par famille), `storeWhy` (cible et qualité), `trialCountdown`, `weeklyCountdown`.

## Catalogue et fiches

- [x] `wod_catalog.dart` : la vitrine (crédits, prochain objectif, à l'affiche, vitrine de la semaine, à ta mesure, liste d'envies, « Tout le catalogue ») est l'en-tête de la liste sans recherche ni filtre ; un rappel du solde sinon. Titre `WODs · N`, champ unique, tri et filtres inchangés.
- [x] `wod_preview.dart` : page produit (`StatefulWidget`, un seul `ListView`) : couverture avec ruban « Essai du jour » / « Vitrine · −1 », nom, entête, chips (format, niveau et palier, durée, prix, source), Mouvements, Pourquoi ça compte (accroche, cible, record ou consigne), Volume et durée, Muscles. Barre basse : « Lancer le WOD » / « Revenir au chrono », « Essayer · offert jusqu'à minuit » + « Acheter · N crédit(s) », ou « Il te manque … ». Cœur de liste d'envies dans la barre d'app.
- [x] `arsenal_screen.dart` : `WodTile` avec couverture, chevrons, prix et cœur ; menu d'actions (aperçu, lancer ou essayer, liste d'envies) ; bannière `_Credits` avec prochain objectif ou essai du jour.
- [x] Textes de campagne et de niveau alignés sur le barème (`game_widgets.dart`, `stats_progression.dart`).

## Tests

- [x] `test/wod_store_test.dart` : dix tests (voir README).
- [x] `progression_test` (barème), `game_test` (crédits dérivés), `wod_acquisition_test` (WOD hors essai pour le cas sans crédits).
- [x] Contrats conservés : `WODs · 0` / `WODs · 1000`, champ de recherche unique, icône de fermeture unique, « Acheter · N crédit(s) » dans un `FilledButton`, « Lancer le WOD », « Il te manque », « MOUVEMENTS » visible à 320 px, un seul `ListView` sur la fiche, « Achète un WOD » à l'ouverture du catalogue, « Nouvelle séance » et « Catalogue » dans l'Arsenal.

## Validation et livraison

Voir `AUDIT_2.5.0.md`. Aucune analyse, compilation ni test Flutter n'a pu être exécuté ici.

## Historique

Les checklists 1.8.7 à 2.4.1 restent dans `docs/REFONTE_UI_*.md`.
