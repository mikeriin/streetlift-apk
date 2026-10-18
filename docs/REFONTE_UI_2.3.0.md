# Kalis Track — Refonte UI 2.3.0

Mise à jour : 22 septembre 2026. Version **2.3.0+48**.

Cette livraison élargit le contenu (WODs, modes d’exécution, exercices) et la
recherche. Le dock 2.2.4, la palette 2.2.3 et tous les écrans restent
inchangés. Navigation : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Catalogue de WODs — intégré

- [x] 1 000 WODs : sélection + première série (`generateWods`, ids `gen0`…) inchangées, deuxième série `generateWodsV2` (500 WODs, ids `genx…`, douze familles, dédoublonnage sur format + mouvements, noms uniques suffixés II / III).
- [x] Toutes les lignes générées suivent les conventions du parseur (`_parseLine`) : `N mouvement`, `400 m run`, `min 1, 4, 7… : …`, `min 1-5 : …`, `5 × (…)`, `8 × (max … en 20 s)`, `AMRAP 8 min : …`, `Repos 2 min`. Points et durées > 0 pour chaque WOD (vérifié par port Python du parseur).
- [x] Niveaux par déciles et coût 1-4 crédits inchangés ; `isGenerated` reconnaît `gen` et `genx`.
- [x] Recherche `lib/search.dart` : `normalizeText`, `SearchQuery` (termes ET, préfixes ≥ 3 lettres, familles de synonymes FR / EN, score titre 3 · méta 2 · corps 1 · notes 0,5), `SearchDoc`, `SearchIndex` (cache par clé).
- [x] Catalogue : puces rapides, section Mouvements (14 motifs sur les lignes normalisées), tri (débloqués puis niveau · pertinence · niveau ↑↓ · durée ↑↓ · nom · nouveautés), pertinence automatique quand une recherche est saisie, rangée des filtres actifs hors puces rapides.
- [x] Contraintes de tests conservées : un seul `TextField` sur l’écran, une seule icône `Icons.close` (bouton effacer de `KSearch`), titre `WODs · N`, `KEmpty` avec « Réinitialiser ».

## Séances personnelles — intégré

- [x] `execModes` : 15 modes ; `modeDefaults` par mode (Tabata 8 × 20 / 10, Death by 20 × 60 s, Densité 10 min × 5, Drop set 3 × 8 + 2, Max 3 séries, Tempo 4 × 6).
- [x] `CustomExercise.setsText / forcedSets / timerSpec / toExercise` : Tabata → chrono `hiit` ; Death by → chrono `emom` ; Densité → chrono `amrap` ; Tenues au max → `tempo: 'Isométrie'` (saisie `holdMax`) ; Tempo → cadence dans `Exercise.tempo` ; Drop set → `series × (1 + paliers)` lignes.
- [x] Éditeur de paramètres : libellés `startReps`, `step`, `tempo`, `drops` ; champs texte génériques (`pyr`, `tempo`) ; validation du tempo ; `_switchMode` applique les défauts du mode aux champs non renseignés.
- [x] Sélecteur d’exercices : recherche partagée, puces groupes + matériel, tri par pertinence (exact > titre > groupe > matériel), compteur, récents, création conservée.

## Données — intégré

- [x] `assets/exercises_db.json.gz` : 505 exercices (172 + 333), triés, sans doublon (comparaison sans accents ni casse), matériels ajoutés : kettlebell, box, corde à sauter, ergomètre, sac lesté, médecine-ball, sangles, battle rope.
- [x] `tools/tests/test_tools.py` : `(1954, 505)` ; tests Flutter : 1 000 WODs, `test/search_test.dart` (normalisation, synonymes, pertinence, cache, deuxième série déterministe, première série intacte).

## Dock — corrigé

- [x] `lib/nav_bar.dart` : plus d’`AnimatedSize` (défaut avec « Réduire les animations », voir `AUDIT_2.3.0.md`) ; un seul `TweenAnimationBuilder` par onglet anime largeur, libellé, opacité et pastille. API, clés, sémantique, `extent` et tests du dock inchangés.

## Validation et livraison

Voir `AUDIT_2.3.0.md`. Aucune analyse, compilation ni test Flutter n’a pu être
exécuté dans l’environnement de livraison ; le workflow GitHub reste le point
de contrôle avant l’APK.

## Historique

Les checklists 1.8.7 à 2.2.4 restent dans `docs/REFONTE_UI_*.md`.
