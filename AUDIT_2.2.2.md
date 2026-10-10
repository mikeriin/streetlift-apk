# Kalis Track 2.2.2 — Bordeaux et anthracite

Version **2.2.2+45**. Palette fournie par l’utilisateur : #6B0C0C, #A61717, #121212, #1E1E1E, #F4F4F4, #8A8A8A, #388E3C.

## Résultat

Le thème sombre utilise les fonds anthracite et les cartes gris foncé demandés, avec les actions principales en bordeaux. Le mode sombre devient le défaut pour une nouvelle installation ou une sauvegarde sans préférence ; les choix explicites Système, Clair et Sombre existants restent respectés.

Les progressions unies ont une piste contrastée. Le graphique des jours actifs sur huit semaines utilise un dégradé bordeaux → rouge, des contours lisibles, des valeurs chiffrées et un détail accessible. Sa mesure reste les jours actifs : aucun indicateur d’intensité ou de volume n’a été inventé.

Le rouge d’action distingue les commandes sélectionnées, les médailles de record dans STATS et les résultats WOD, et les contours d’alerte des chronomètres. Les chiffres et libellés restent contrastés. Le vert de validation est décliné avec des nuances adaptées aux petits textes. Le K historique garde sa transparence et sa silhouette ; les icônes Android sont recolorées.

Les transitions, séances, règles de calcul, XP, crédits, achats WOD et historiques sont conservés. Aucun paiement ni création de WOD n’est réintroduit.

## Vérification ciblée

- Analyse Flutter : aucun problème.
- **44 tests réussis** : contraste, transitions, conservation de l’état, stockage, préférence de thème, STATS, séances, WOD et affichage du niveau.
- **45 captures Flutter** produites : thèmes clair / sombre, écrans principaux et secondaires, largeurs compactes, graphique d’activité.
- Contraste des rôles textuels de la palette contrôlé à au moins 4,5:1 sur les surfaces principales et champs des deux thèmes.
- 16 fichiers de calculs, chronos, données, dépendances et identité Android identiques à la version 2.2.1. Dans le store, seules les deux valeurs de thème par défaut changent. Rapport : `validation/2.2.2/core-integrity.json`.

La suite complète de 152 tests validée en 2.2.0 n’a pas été relancée ; les tests de cette livraison sont ciblés sur les modifications. Les données des captures sont simulées uniquement dans les tests.

## Livraison

Projet complet dans `streetlift_tracker_v33.zip`, aperçu actualisé et checklist. Aucun APK compilé ici ; utiliser le workflow GitHub habituel après avoir renommé l’archive avec ce nom exact si nécessaire. Aucun essai sur téléphone physique ou en plein soleil n’est revendiqué.
