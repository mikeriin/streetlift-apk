# Programme 1.8.0

Rendus Flutter avec Roboto et Material Icons : Programme en 390×844, 360×760 et 320×760, thèmes clair et sombre ; semaine, estimations et aperçu WOD également rendus et inspectés. Référence de date : S8/J4, avec 24 px de marges système en haut et en bas. Les sept journées tiennent sans défilement à 360 et 390 px ; 18 px de défilement mesurés à 320 px. Les tests de widgets couvrent aussi 320 px et un texte à 130 %.

Le lanceur natif n’a pas changé depuis 1.7.7. La mise en page des cartes de performance et la navigation inférieure sont conservées. Aucune compilation ni installation APK locale. Les scripts temporaires de rendu ne sont pas livrés dans le projet.

## Historique des contrôles antérieurs

# Lancement 1.7.7

Délai d’ouverture minimal de 2 secondes ajouté avant la première image Flutter, en parallèle de l’initialisation. Les ressources natives du drapeau et l’interface de la version 1.7.6 sont conservées. Les contrôles de rendu ci-dessous restent ceux de la version 1.7.6 ; aucun nouveau rendu n’est nécessaire pour cette modification de durée. La durée réelle de l’écran natif n’a pas été mesurée sur un appareil Android local.

---

# Vérification visuelle 1.7.6

18 vues ont été rendues en clair et en sombre, avec Roboto et les icônes Material : Programme, Arsenal, Suivi, séance, progression, réglages, Pilotage, catalogue, aperçu WOD, séance avec RIR, séance avec chrono, éditeur de séance, éditeur WOD, chrono WOD, saisie de résultat, paramètres d’exercice, filtres et réglages des chronos.

Les vues de référence utilisent 390 × 844 avec 24 px d’espace système en haut et en bas. La séance avec RIR utilise 360 × 760. Quatre vues complémentaires (réglages des chronos, chrono WOD, éditeur WOD et paramètres d’exercice) ont également été rendues à 320 × 760 avec texte à 130 %, dans chacun des deux thèmes.

## Dimensions et lisibilité

- Cellules de performance : surface visible mesurée à 36 px ; zone tactile étendue verticalement à 44 px. Chiffres de taille 15, graisse normale et tabulaires.
- Champs de formulaire et listes déroulantes : 40 px à taille de texte normale. Les champs multilignes et textes agrandis grandissent librement.
- Boutons : surface de référence de 36 px, zone tactile de 44 px de haut, alignement sur un axe commun. Les boutons de validation de série ont une cible de 44 × 44.
- Carte initiale « Muscle-up lesté » S8/J1 : 450 px logiques, cinq séries visibles, aucun défilement vertical initial dans les deux vues de référence.
- Repères de progression séparés conservés. Les cellules, icônes de validation et en-têtes de colonne restent centrés sur les mêmes axes.
- Contrôles secondaires moins remplis, fonds des cellules et badges atténués, graisses de textes réduites. Palette et bandeaux précédents conservés.

Les hauteurs des champs sont mesurées via le conteneur de décoration Flutter. Un test d’interaction vérifie qu’un appui dans la marge extérieure de la cellule active le champ, sélectionne la valeur et enregistre la nouvelle saisie. Les tests existants vérifient aussi petits écrans, grands textes, clavier, orientation paysage et conservation de l’état.

Les vues représentatives de séance, réglages, WOD, Arsenal et paramètres ont été inspectées. Les rendus étroits ont motivé le retour à la ligne des aides de formulaire. L’inspection visuelle et les tests Flutter complètent l’analyse statique ; ils ne constituent pas un essai sur téléphone.

## Lancement Android

Les fichiers Android sont identiques à la version 1.7.5 : drapeau bleu, blanc, rouge de 84 × 56 dp centré sur le fond sombre, variantes Android 12 et 13 incluses. La validation des ressources de cette version est conservée dans `launch-resources.json`.

Aucune compilation ni installation APK locale. Les outils temporaires de rendu sont exclus du ZIP.
