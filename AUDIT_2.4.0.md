# Audit 2.4.0 — Progression façon jeu

Date : 22 septembre 2026. Version 2.4.0+49 (2.3.0+48 précédente).

## Périmètre

- Nouveaux : `lib/game.dart`, `lib/game_widgets.dart`, `lib/rewards.dart`, `test/game_test.dart`.
- Modifiés : `lib/progression.dart` (`weeks` exposé, barème intact), `lib/store.dart` (réglages, cache `game`, crédits dérivés, bilans, records), `lib/levelup.dart` (pastille seule, `checkLevelUp` ré-exporté), `lib/stats_overview.dart`, `lib/stats_progression.dart`, `lib/session_screen.dart`, `lib/settings_screen.dart`, version (`pubspec.yaml`, `kAppVersion`, `test/visual_capture_test.dart`).

## Base de conception

Revue des preuves (méta-analyses 2022-2025 sur la gamification de l'activité physique, cas Duolingo, Strava, Fitocracy, Apple Fitness, Freeletics, Hevy, Peloton) : effet réel mais modeste et déclinant ; feedback et objectifs adaptatifs les plus robustes ; séries efficaces si pardon ; classements globaux et culpabilisation contre-productifs ; pour la force, ne jamais récompenser le volume brut. D'où : XP inchangés, récompenses en titres et crédits dérivés, repos et deload valorisés, aucune comparaison à autrui.

## Invariants vérifiés par relecture

- Barème d'XP, niveaux (`xpAtLevel`), crédits par niveau, badges et missions : aucun changement (tests `progression_test` pinnés à 980 XP / 215 XP hebdo…). Les crédits dérivés partent de zéro sans données : `wod_acquisition_test` et `store_test` (achat, rechargement) inchangés.
- Écran Parcours : « Recrue » apparaît une seule fois (carte de l'arbre) ; le tuile des titres n'affiche pas le rang ; « Ton arbre de progression », `stats-branch-*`, `badge-*`, « Prochain palier » / « Obtenu », « +40 XP déjà inclus dans ton total. », « Chaque badge rapporte » (dernier élément de la liste) conservés.
- Aperçu et Parcours : chaque zone tappable porte du texte (guideline `labeledTapTargetGuideline`) ; les peintres sont exclus de la sémantique, le radar porte un libellé.
- 320 px / texte 130 % : cartes en `Column` + `Expanded`, `Wrap` pour les métriques, `SingleChildScrollView` horizontal pour les chapitres (le test `find.byType(ListView).last` garde la liste de page comme cible de glissement).
- Animations : `TweenAnimationBuilder`, `AnimationController` à passage unique ; aucun `AnimatedSize`, aucun `Timer` ; `disableAnimations` → durées nulles.
- `markSessionDone(100, 1)` (semaine hors programme, `store_test`) : garde `program.weeks.any` avant `program.week`.

## Points d'attention

- Les attributs utilisent les références Pilotage (préremplies par le programme) : un nouvel utilisateur voit des valeurs par défaut tant qu'il ne les modifie pas.
- `sessionRecords` et `liveRecord` recalculent les meilleures séries à chaque appel (journal de quelques centaines de séances : négligeable).

## Passages du workflow

2. `flutter test` : 11 échecs, deux causes. (a) `settings_screen.dart` indexe des tableaux fixes d'icônes et de descriptions (7 entrées) par section `_Sec` ; la section « Progression et jeu » en faisait 8 → `RangeError` au build de Réglages (8 tests : redesign, screens, programme, ui_refactor). Corrigé : entrée ajoutée à l'index 3, assertion sur l'égalité des longueurs, compteur de modes réel dans « À propos ». (b) `progression_screens_test` fait défiler le Parcours de 8 × 420 px puis cherche le texte final « Chaque badge rapporte » : les cartes campagne / boss / saison ajoutées au Parcours allongeaient la liste au-delà de la portée du test (2 tests). Corrigé : le Parcours garde une tuile « Campagne, boss et saisons » qui ouvre une feuille (`showCampaign`) ; les cartes complètes restent dans l'Aperçu. Durcissements au passage : objectif et série en pleine largeur, titre du personnage en `FittedBox`, libellé de la jauge de récompenses en `Expanded`.


1. `flutter analyze` : une erreur, `lib/game.dart` (score de régularité inféré `num` par l'analyseur) — corrigée par des locales typées `int` et `toInt()`. Tout le reste de la couche jeu analyse proprement.

## Non vérifié dans l'environnement de livraison

- `flutter analyze`, `flutter test`, compilation Android : pas de SDK ici ; le workflow reste le point de contrôle.
- Rendu visuel de l'insigne, du radar et de l'écran de récompenses : pas de capture.
