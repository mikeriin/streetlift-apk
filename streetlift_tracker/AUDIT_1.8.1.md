# Kalis Track 1.8.1 — Ajustements Programme après tests

Version **1.8.1+33**. Cette mise à jour applique le dernier croquis à l’onglet Programme.

## Affichage et gestes

| Zone | Comportement livré |
|---|---|
| Barre supérieure | Niveau et petite progression sans fond rectangulaire ; logo centré et calendrier à droite. |
| Semaines | Un curseur fin avec le numéro S1…S40 sur la poignée. Glisser change de semaine ; maintenir le numéro ouvre le détail. Le calendrier reste disponible pour choisir une semaine. |
| Cartes | Sept journées compactes ; la séance du jour reste développée et possède un fond teinté et un liseré. Mention « Aujourd’hui », menus ⋮ et boutons Détails / Commencer retirés. |
| Appui court | Ouvre ou reprend la séance. Si elle est terminée, affiche son historique en lecture seule. |
| Appui long | Affiche directement le résumé de la séance : état, exercices, muscles ciblés, volumes et temps avec effort/repos/transitions. Le détail par exercice reste consultable. |
| Récupération | Résumé spécifique sans estimation artificielle ; l’historique sans séries affiche un message explicite. |

La navigation inférieure, les chronos, la progression et le moteur d’estimations de la version 1.8.0 sont conservés. Les calculs et leurs limites restent détaillés dans **AUDIT_1.8.0.md**, inclus dans le projet.

## Vérifications

- **119 tests Flutter réussis**, dont **8 tests de la vue Programme** : appui court, résumé par appui long, historique sans modification des saisies, curseur aux semaines 1 et 40, calendrier, récupération, petits écrans et texte agrandi.
- Analyse Flutter sans anomalie ; **4 tests Python réussis**.
- Rendus Flutter inspectés en clair et sombre à **390×844**, ainsi qu’à **320×720 avec texte à 130 %**. Les sept cartes et la navigation restent visibles sur le cas de référence S10/J4 ; les contenus longs peuvent défiler.
- Données vérifiées : **40 semaines, 280 journées, 1 954 prescriptions et 172 exercices**.
- Identité Android, certificat de signature, données du programme, moteur d’estimations et navigation inférieure comparés à l’archive 1.8.0 de départ et conservés.
- L’appui long sur les cartes n’efface plus aucune donnée.

**L’APK n’a pas été compilé ni installé dans cet environnement.** La compilation Android et le comportement sur téléphone restent à confirmer avec le workflow existant.

## Installation

Remplacer **streetlift_tracker_v33.zip** à la racine du dépôt, puis lancer **Actions → Build APK**. Installer l’APK produit par-dessus l’application existante. Le workflow et la signature restent compatibles.
