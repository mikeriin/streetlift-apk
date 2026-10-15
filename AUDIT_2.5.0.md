# Audit 2.5.0 — Le WOD Store, façon boutique de jeu

Date : 24 septembre 2026. Version 2.5.0+51 (2.4.1+50 précédente).

## Périmètre

- Nouveaux : `lib/wod_store.dart`, `test/wod_store_test.dart`.
- Modifiés : `lib/store.dart` (prix, remises, essai, vitrine, recommandations, liste d'envies, sauvegarde), `lib/progression.dart` (barème), `lib/game.dart` (crédits dérivés), `lib/wod_catalog.dart` (vitrine), `lib/wod_preview.dart` (page produit, réécrite), `lib/arsenal_screen.dart` (tuile et bannière), `lib/wod_screen.dart` (accès par `canRun`), `lib/game_widgets.dart` et `lib/stats_progression.dart` (textes), tests `progression_test`, `game_test`, `wod_acquisition_test`, version, documents.
- Inchangés : catalogue (1 000 WODs, difficulté par déciles), format de sauvegarde (format 3, clé `wishlist` ajoutée, absente = vide), dépendances, workflow, identité de signature (`tools/verify_project.py --signing` : OK).

## Sources de la conception

Recherche préalable (rapport « Refondre le WOD Store comme une boutique de jeu vidéo, sans manipulation ») : goal-gradient et progrès doté (Kivetz, Urminsky & Zheng, 2006), aversion à la perte sur les gains réels (Rewley et al., 2021), méta-analyses sur la gamification de l'activité physique (Mazeas et al., 2022 ; Nishi et al., 2024), Drop Shop de Zwift (monnaie gagnée à l'effort, dotation de départ, bonus de paliers), wishlist Steam, dark patterns et FTC / Epic (2022). Retenu : dotation, distance au but affichée sans triche, essai du jour, rotation hebdomadaire à remise réelle, page produit éditoriale, rituel de déblocage court et interruptible, rien de retiré, aucun tirage aléatoire.

## Décisions

1. **Barème.** `creditsForLevel(l) = 1 + 2l + 3⌊l/5⌋` : 3 offerts, +2 par niveau, +3 tous les 5 niveaux ; supérieur à l'ancien barème à tout niveau, donc aucun solde ne baisse à la mise à jour (test dédié jusqu'au niveau 80). Chapitre +3, boss +5, semaine à trois entraînements +1 (`GameState.fullWeeks`). Ordre de grandeur pour trois à quatre séances par semaine : quatre à six crédits hebdomadaires, soit un WOD Avancé toutes les deux ou trois séances.
2. **Prix.** Paliers inchangés (1-4). `wodCost` = base − 1 (vitrine) − 1 (essai terminé), plancher 1. Le prix payé est enregistré à l'achat : une remise passée ou future ne modifie jamais un solde.
3. **Essai du jour.** Sélection déterministe par date (FNV-1a sur « trial|jour|id »), hors vitrine, niveau ±1 autour du niveau global de la feuille de personnage, réservée aux WODs jamais tentés ou tentés aujourd'hui : terminer l'essai ne fait pas apparaître un second essai. `canRun` remplace `unlocked` pour l'accès au chrono. Résultats et XP conservés ; le WOD reste verrouillé, à −1 crédit.
4. **Vitrine de la semaine.** Trois WODs de formats différents, clé « weekly|lundi », niveaux −1 à +2 ; indépendante de l'essai (l'essai l'évite, pas l'inverse), donc stable toute la semaine à WODs possédés constants.
5. **Liste d'envies.** Ensemble d'ids persisté dans le document d'état et validé à l'import (chaînes, dédoublonnées). Prochain objectif = le souhait verrouillé le moins cher, avec jauge crédits / prix et distance en crédits ou en XP (`levelProgress`, `nextCredits`). Retiré à l'achat.
6. **Couvertures.** `CustomPainter` seedé par l'id : motif par famille (nom et format), dégradé bordeaux, reflet des paliers Élite et Légende, vignette ; assombrie quand le WOD est hors de portée. Palier signalé par des chevrons et un libellé, jamais par la couleur seule. Le rouge #A61717 reste un fond (contraste insuffisant en texte sur #121212).
7. **Déblocage.** Révélation en place (reflet 900 ms, respiration ±3,5 %, haptique moyenne si activée, SnackBar « gagné à la sueur »), pas d'écran modal ; « Réduire les animations » place l'animation à 1. Une seule facturation et une seule révélation par fiche (`_celebrated`).
8. **Vitrine du catalogue.** En-tête de la liste des résultats ; disparaît dès qu'une recherche ou un filtre est actif. Rails en `SingleChildScrollView` horizontal à hauteur naturelle (pas de hauteur fixe, donc pas de débordement à 130 %). Aucun `Icons.close`, un seul `TextField`.

## Invariants vérifiés par relecture

- `unlocked` ne dépend plus de `wodCost` (qui dépend de la vitrine, qui filtre par `unlocked`) : pas de récursion.
- Caches des sélections vidés par `notifyListeners()` ; changement de jour ou de semaine détecté par la clé, sans notification.
- Contrats de tests conservés : `WODs · 0` / `WODs · 1000`, `TextField` unique, `Icons.close` unique, « Achète un WOD » à l'ouverture, « Acheter · N crédit(s) » dans un `FilledButton` et « Lancer le WOD » unique après achat, « Il te manque » unique, aucun « Acheter · » sans crédits, « MOUVEMENTS » visible et un seul `ListView` sur la fiche à 320 px / 130 %, « Revenir au chrono » depuis le chrono, `wodCost > 0` sur tout le catalogue.
- `wod_acquisition_test` (« sans crédits suffisants ») écarte l'essai du jour, désormais jouable sans achat.
- Contrôle syntaxique de tous les fichiers Dart (grammaire tree-sitter) : aucune erreur.

## Premier passage du workflow (24 septembre 2026, 12 h 46 UTC)

`flutter analyze` : aucun problème. `flutter test` : 184 tests sur 186 ; deux échecs, tous deux dans les tests, corrigés dans cette livraison :

- `reward_flow_test` (« fin de séance ouverte sans vérification au retour ») : la page de récompenses n'était pas trouvée après **une** image. Cause : à la première image d'une page poussée, le `HeroController` de `MaterialApp` la garde hors scène (`route.offstage`) le temps de mesurer les héros, et les chercheurs ignorent les widgets hors scène. Le test attend désormais deux images. Effet de bord corrigé dans l'app : pendant cette image, l'animation d'entrée de la route se présente comme terminée ; `RewardScreen` laisse maintenant passer une image avant de lire l'état réel de l'entrée, sinon le décompte d'un WOD partait pendant le fondu.
- `wod_store_test` (« la vitrine ouvre le catalogue ») : « VITRINE DE LA SEMAINE » introuvable à 390 × 844. Cause : la police de test mesure 1 em par caractère, la carte de crédits et le WOD à l'affiche sont plus hauts qu'en réel, et la liste ne rend visibles que les éléments à l'écran. Le test utilise un écran de 390 × 1800.

## Passages du workflow

- `python3 tools/verify_project.py --signing` : OK (`validation/2.5.0/project.txt`).
- `python3 -m unittest discover -s tools/tests -v` : 4 tests OK (`validation/2.5.0/python-tests.txt`).

## Non vérifié dans l'environnement de livraison

- `flutter analyze`, `flutter test`, compilation Android : pas de SDK ici ; le workflow reste le point de contrôle.
- Rendu des couvertures et fluidité de la révélation sur téléphone.
- Calibrage de l'économie sur la cadence réelle des niveaux : ajuster `creditsForLevel` (pas les prix) si le solde médian dépasse ~8 crédits ou reste à 0 plus d'une semaine.
