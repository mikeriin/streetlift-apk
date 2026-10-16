# Kalis Track 1.7.7 — ouverture prolongée

Le drapeau français reste affiché **au moins 2 secondes au démarrage**. L’écran sert à la fois d’accueil et de chargement.

Le délai est lancé avant l’initialisation des données et attendu avant la première image de l’application. Le chargement se poursuit donc en parallèle : s’il prend plus de 2 secondes, aucune attente supplémentaire n’est ajoutée. Une erreur d’initialisation reste dirigée vers l’écran de récupération existant. L’ouverture d’une séance depuis une notification garde le même mécanisme.

Le délai s’applique au démarrage de l’application ; un simple retour depuis l’arrière-plan ne le relance pas. Les ressources du drapeau, l’interface affinée de la version 1.7.6, les données et la signature sont conservées. Aucune dépendance n’est ajoutée.

## Vérifications

- Version **1.7.7+31**, Flutter 3.29.3 et Dart 3.7.2.
- Analyse Flutter : aucune anomalie.
- **84 tests Flutter et 4 tests Python réussis.**
- Intégrité du programme, ressources Android et certificat de signature vérifiés.
- Ordre du démarrage relu : délai lancé avant le chargement, attendu avant `runApp`, erreurs et traitement des notifications conservés.

Les tests existants ne mesurent pas la durée du splash natif. L’APK n’a pas été compilé ni lancé dans cet environnement : l’affichage et sa durée restent à vérifier sur le téléphone après compilation.

## Installation

Remplace **streetlift_tracker_v33.zip** à la racine du dépôt, puis lance **Actions → Build APK**. Télécharge l’artefact **kalis-track-apk**, extrais **kalis-track.apk** et installe la mise à jour. Ferme complètement l’application puis relance-la pour voir l’ouverture prolongée.
