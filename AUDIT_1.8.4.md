# Kalis Track 1.8.4 — en-tête et navigation

Version de l'application : **1.8.4+36**. Le programme reste en version 3.3 et le fichier à remplacer reste `streetlift_tracker_v33.zip`.

## Changements

- Suppression des traits horizontaux et des fonds distincts qui encadraient le Programme. L'en-tête reprend le fond du contenu.
- Niveau, logo et calendrier centrés sur le même axe, avec une hauteur visuelle harmonisée. Dans les captures normales, les trois éléments occupent chacun environ 29 px de hauteur visible. Le niveau conserve sa progression, sans rectangle de fond. Son échelle est fixe comme celle des deux icônes ; le texte du contenu continue à respecter l'agrandissement système.
- Léger fondu vers le bas de la navigation. Une forme arrondie en surbrillance suit l'onglet ouvert, avec une transition de 280 ms. Le réglage système de réduction des animations supprime le déplacement.
- Icône Programme légèrement plus grande : 27 px contre 24 px pour les quatre autres. Le fond de sélection appartient uniquement à l'onglet actif. Les zones tactiles et les libellés des cinq onglets restent disponibles.
- Le logo de l'ouverture animée termine son trajet à la nouvelle taille de l'en-tête, avec la même position finale.

## Vérifications

- **127 tests Flutter réussis**, incluant navigation, thème, calendrier, gestes du Programme, données, historique en lecture seule, chronos, notifications et ouverture animée.
- **4 tests Python réussis** ; programme et identité de signature vérifiés.
- Analyse Flutter : aucun problème signalé.
- Rendus des vrais widgets en clair et sombre, à 390 × 844 px et à 320 × 720 px avec texte à 130 %. Les petits écrans permettent toujours de faire défiler la semaine.
- Capture de la navigation au fil des cinq sélections : la surbrillance se déplace et la sélection suit les appuis. Le GIF présente la navigation sombre au-dessus de la navigation claire.
- Données du programme, calculs, format de sauvegarde, historique, identifiant Android, clé de signature et workflow de compilation inchangés.

## Installation

Remplacer le ZIP à la racine du dépôt GitHub, puis utiliser **Actions → Build APK** et installer l'APK obtenu par-dessus l'application existante.

L'APK n'a pas été compilé ici : cet environnement ne contient pas le SDK Android. Le rendu final sur téléphone reste à confirmer après la compilation GitHub Actions.
