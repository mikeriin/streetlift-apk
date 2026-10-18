# Kalis Track 1.8.2 — Finitions de Programme

Version **1.8.2+34**, après validation de la maquette.

## Changements

- Barre supérieure de **70 px**, comme la partie utile de la navigation inférieure, avec le même fond et un séparateur fin.
- Curseur dans le bleu de l’application, avec une poignée remplie de **30 × 18 px** et un trait de **2 px** à taille de texte normale. La zone tactile reste de **48 px**, et le numéro s’adapte au texte agrandi.
- Fond teinté de la carte du jour conservé ; liseré de gauche retiré.
- Espacement des cartes resserré pour garder les sept journées visibles sur le petit écran de référence.

Les appuis courts et longs, la navigation du bas et les estimations restent identiques à la version 1.8.1.

## Vérifications

- Analyse Flutter sans anomalie ; **119 tests Flutter réussis** et **4 tests Python réussis**.
- Glissement du curseur, appui long sur son numéro, résumés et ouverture des historiques couverts par les tests existants.
- Rendus réels inspectés en clair et sombre à **390×844** et **320×720 avec texte à 130 %**. Les sept cartes de la référence S10/J4 restent visibles au-dessus de la navigation. Les contenus plus longs peuvent défiler.
- Poignée mesurée à **30 × 18 px** en taille normale et environ **34 × 20 px** avec texte à 130 %.
- Données, moteur de calcul, navigation inférieure, signature Android et workflow comparés à l’archive 1.8.1 et conservés.

**L’APK n’a pas été compilé ni installé ici.** Remplacer **streetlift_tracker_v33.zip** à la racine du dépôt, puis lancer **Actions → Build APK** et installer l’APK produit sur l’application existante.
