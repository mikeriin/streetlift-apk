# Kalis Track 1.8.5 — transition de navigation

Version de l'application : **1.8.5+37**. Le programme reste en version 3.3 et le fichier à remplacer reste `streetlift_tracker_v33.zip`.

## Changements

- La bosse descend jusqu'à une barre plate, puis remonte sous le nouvel onglet. La transition dure 360 ms, avec un court passage entièrement plat. La forme ne glisse plus latéralement.
- La barre inférieure et la bosse sont dessinées comme une seule surface de couleur uniforme et opaque. Seul le fond derrière les icônes utilise un dégradé de transparence.
- L'éclair au toucher a été retiré pour ne pas se superposer à la forme. Les appuis successifs repartent de la hauteur affichée et terminent sur le dernier onglet choisi.
- L'icône Programme conserve sa taille légèrement supérieure : 27 px contre 24 px. Les cinq destinations, leurs libellés et leurs zones tactiles sont conservés.
- Le réglage système « Réduire les animations » affiche immédiatement la nouvelle sélection.

## Vérifications

- **127 tests Flutter réussis**, incluant navigation, thème, calendrier, gestes du Programme, données, historique en lecture seule, chronos, notifications et ouverture animée.
- **4 tests Python réussis** ; données du programme et identité de signature vérifiées.
- Analyse Flutter : aucun problème signalé.
- Rendus des vrais widgets en clair et sombre, à 390 × 844 px et à 320 × 720 px avec texte à 130 %.
- Animation capturée toutes les 40 ms à travers les cinq onglets. Vérification visuelle du passage entièrement plat et de l'aplat commun à la barre et à la bosse. Le GIF présente le thème sombre au-dessus du thème clair.
- Appuis rapides successifs, désactivation des animations et retrait du widget pendant une transition vérifiés sans exception. Avec la réduction des animations, les images immédiatement après la sélection et après 400 ms sont identiques.
- Comparaison du ZIP avec la version 1.8.4 : seuls la navigation, le numéro de version et la documentation changent. Données, calculs, historique, format de sauvegarde, en-tête, ouverture animée, identité Android, clé de signature et workflow sont conservés.

## Installation

Remplacer `streetlift_tracker_v33.zip` à la racine du dépôt GitHub, puis utiliser **Actions → Build APK** et installer l'APK obtenu par-dessus l'application existante.

L'APK n'a pas été compilé ici : cet environnement ne contient pas le SDK Android. Le rendu sur téléphone reste à confirmer après la compilation GitHub Actions.
