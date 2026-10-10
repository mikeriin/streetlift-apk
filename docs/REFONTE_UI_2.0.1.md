# Kalis Track — Refonte UI 2.0.1

Mise à jour : 21 septembre 2026. Base : 1.8.7+39. Version : **2.0.1+41** (numéro de compilation Android croissant pour l'APK).

La note manuscrite du 21 septembre précise la refonte : **logo historique conservé**, dominante **#6C1A1A**, Programme simplifié et angles davantage arrondis. Ces précisions remplacent le nouveau monogramme et la présentation de l'accueil de 2.0.0. Le fonctionnement des séances et les données sont conservés.

## Modifications de la note

- [x] Restaurer la silhouette originale du logo ; ne changer que sa couleur. Masque original conservé octet pour octet ; icônes classiques, adaptatives, monochromes, notifications et ouverture assorties.
- [x] Afficher les sept jours dans leur ordre J1 à J7, sans déplacer aujourd'hui en tête.
- [x] Garder les autres jours compacts, avec un cercle vide ou une coche selon leur état.
- [x] Détailler uniquement le jour actuel : titre, durée, exercices, séries, volume et muscles ; texte spécifique pour la récupération.
- [x] Afficher une seule commande de semaine : le slider, sans flèches ni boutons redondants.
- [x] Appui court sur le slider : détails de la semaine. Appui long : choix direct d'une semaine. Glissement : changement de semaine.
- [x] Balayage du contenu vers la droite / gauche : semaine précédente / suivante.
- [x] Appui court sur un jour : séance ou historique si terminée. Appui long : résumé, sans modification des saisies.
- [x] Ajouter « NIV. » à gauche du niveau et une barre d'avancement en dessous. Un appui ouvre la progression.
- [x] Appliquer #6C1A1A aux surfaces d'accent et au logo ; conserver des textes et indicateurs lisibles dans les deux thèmes.
- [x] Augmenter les arrondis des cartes, menus, formulaires, dialogues, panneaux et du dock.
- [x] Conserver le clavier et le lecteur d'écran pour les commandes gestuelles.

La semaine entière tient à l'écran dans le rendu 390 × 844 px. La densité s'adapte aux écrans plus courts ; le défilement reste disponible avec de grands caractères ou un espace insuffisant, sans masquer définitivement de journée.

## Périmètre livré

| Écran | Refonte appliquée | Intégré |
|---|---|---|
| Arsenal | En-tête, création de séances / WOD, progression, cartes et menus | ✓ |
| Suivi | En-tête, accès à l'historique complet, progression, objectifs et muscles | ✓ |
| Programme / accueil | Sept jours ordonnés, séance du jour détaillée, slider simple et gestes | ✓ |
| Pilotage | Hiérarchie des références, cartes et saisie commune | ✓ |
| Réglages | Accueil et six pages de préférences ; thème directement accessible | ✓ |
| Exécution de séance | Carte d'exercice, séries, boutons, progression et chrono | ✓ |
| Historique de séance | Même grammaire que la séance, en lecture seule | ✓ |
| Éditeur de séance | Recherche, formulaires, cartes, huit modes et actions | ✓ |
| Catalogue WOD | Recherche, filtres, cartes et menus harmonisés | ✓ |
| Aperçu WOD | Estimations, mouvements et actions dans le thème commun | ✓ |
| Éditeur WOD | Introduction, champs, formats et enregistrement | ✓ |
| Exécution WOD / résultats | Chrono agrandi, boutons, résultats et dialogues | ✓ |
| Progression / badges | Bandeau bordeaux, cartes, onglets et récompenses | ✓ |
| Lancement | Silhouette historique recolorée, ressources Android et ouverture assortie | ✓ |
| Erreur de démarrage | Thème, cartes et commandes de récupération harmonisés | ✓ |

## Comportements conservés

- [x] Programme, calculs de charges et durées, huit modes d'exécution.
- [x] Séries, validation, RIR/RPE, vitesse, notes et exercices enchaînés.
- [x] Repos automatiques, compte à rebours, temps longs, pause et reprise WOD.
- [x] XP, crédits, badges, déverrouillages, suivi et historique.
- [x] Import / export, persistance, notifications et récupération de données.
- [x] Choix de semaine conservé entre les onglets et lors du changement de thème.
- [x] Niveau, XP et progression réelle conservés ; nouvelle barre explicite.
- [x] Aucun libellé face / dos sur les silhouettes de l'accueil.
- [x] Identifiant Android et clé de signature d'origine.

Les données de démonstration employées par les tests et captures ne sont pas chargées au lancement de l'application.

## Contrôles

Les résultats détaillés, les captures de l'application et les limites de validation sont consignés dans `AUDIT_2.0.1.md` et `validation/2.0.1`.

La vérification sur ton téléphone permettra de juger le ressenti, les notifications système et le rendu de l'icône avec ton lanceur. La version a été réalisée directement à ta demande ; aucune nouvelle validation visuelle de ta part n'est supposée.

## Historique

Les demandes, validations et livraisons antérieures sont conservées dans `docs/REFONTE_UI_1.8.7.md` et dans les audits 1.8.x. La checklist 2.0.0 reste dans `docs/REFONTE_UI_2.0.0.md`.
