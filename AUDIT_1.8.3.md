# Kalis Track 1.8.3 — interface et ouverture

Version de l'application : **1.8.3+35**. Le programme conserve sa version 3.3, d'où le nom inchangé `streetlift_tracker_v33.zip`.

## Changements

- **Historique** : mêmes cartes d'exercices et tableaux de séries que l'exécution, mêmes pages et sélecteur d'exercices, bilan final en consultation. Les données sont copiées à l'ouverture. Aucun préremplissage, champ éditable, chrono, ajout de série, changement de colonne ou bouton de validation n'est disponible. Les charges, répétitions/temps, efforts, vitesses, notes et états enregistrés sont conservés.
- **Archives personnalisées** : le nom sauvegardé reste visible même si le modèle a disparu. Une unité absente des anciennes données n'est pas inventée : la colonne porte alors « Valeur ». « Effort » évite de réinterpréter les valeurs anciennes selon le réglage RIR/RPE actuel.
- **Programme** : titres plus affirmés, accents vert/bleu/jaune de l'exécution, durée estimée mise en avant, silhouettes musculaires plus visibles. Les autres journées restent compactes. Les gestes, le niveau sans rectangle, le logo centré, le calendrier, les séparateurs et la navigation inférieure sont conservés. Aucun liseré gauche ni bouton de démarrage/détails n'est ajouté à la carte du jour.
- **Semaines** : points et capsule active dans l'esprit de la progression d'exécution. Le numéro SX est dans la capsule (30 × 18 px à taille de texte normale), avec une zone tactile de 48 px. Glissement, bornes S1/S40, appui long, calendrier et commandes d'accessibilité conservés.
- **Ouverture** : nom et logo au centre, drapeau français de 36 × 24 px en bas, puis déplacement/réduction du même logo jusqu'à l'en-tête et apparition de l'accueil en fondu. Animation de deux secondes et chargement en parallèle. Si les données tardent, le logo attend au centre puis termine son trajet. « Réduire les animations » supprime le déplacement. L'écran natif préalable utilise le K existant.

## Vérifications

- **127 tests Flutter réussis**, dont navigation, gestes, import/export, estimations, chronos, notifications et conservation des données.
- Nouveaux tests : historique à 320 px avec texte à 130 % dans les deux thèmes ; comparaison des journaux et des sauvegardes avant/après consultation ; valeurs laissées vides ; archives sans modèle ; tenue en secondes sans chrono ; ouverture de deux secondes ; chargement lent ; erreur d'initialisation ; mouvements réduits.
- **4 tests Python réussis** et vérification du programme : 40 semaines, 280 jours, 1 954 exercices programmés, 172 exercices de la base.
- Analyse Flutter : aucun problème signalé.
- Captures des vrais widgets Flutter en clair et sombre, à 390 × 844 px et à 320 × 720 px avec texte à 130 %. Animation capturée sur ses deux secondes. L'aperçu d'historique utilise des saisies de démonstration ; le GIF laisse l'accueil affiché un instant à la fin pour faciliter la lecture.
- Programme, moteur de calcul, format de sauvegarde, identifiant Android, clé de signature et workflow de compilation conservés.

## Installation

Remplacer le ZIP à la racine du dépôt GitHub, puis utiliser **Actions → Build APK**. Installer l'APK obtenu par-dessus l'application existante.

La compilation Android n'a pas été exécutée dans cet environnement, qui ne contient pas le SDK Android. La transition depuis le tout premier écran natif et le rendu final sur le téléphone restent à confirmer avec l'APK généré par GitHub Actions.
