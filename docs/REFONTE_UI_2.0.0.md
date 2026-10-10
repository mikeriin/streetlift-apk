# Kalis Track — Refonte UI 2.0

Mise à jour : 21 septembre 2026. Base : 1.8.7+39. Version : **2.0.0+40** (numéro de compilation Android croissant pour l'APK).

La demande actuelle autorise une refonte complète de l'UI et des menus, avec une dominante bordeaux sombre, une inspiration Samsung / Apple et un nouveau logo. Elle remplace, pour cette livraison, l'avancement écran par écran. Les validations esthétiques de 1.8.7 restent archivées et ne sont pas présentées comme une validation de ces nouveaux écrans.

## Périmètre livré

| Écran | Refonte appliquée | Intégré |
|---|---|---|
| Arsenal | En-tête, création de séances / WOD, progression, cartes et menus | ✓ |
| Suivi | En-tête, accès à l'historique complet, progression, objectifs et muscles | ✓ |
| Programme / accueil | Séance du jour, semaines, retours directs, résumés et dock | ✓ |
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
| Lancement | Nouveau monogramme, ressources Android et ouverture assortie | ✓ |
| Erreur de démarrage | Thème, cartes et commandes de récupération harmonisés | ✓ |

## Comportements conservés

- [x] Programme, calculs de charges et durées, huit modes d'exécution.
- [x] Séries, validation, RIR/RPE, vitesse, notes et exercices enchaînés.
- [x] Repos automatiques, compte à rebours, temps longs, pause et reprise WOD.
- [x] XP, crédits, badges, déverrouillages, suivi et historique.
- [x] Import / export, persistance, notifications et récupération de données.
- [x] Choix de semaine conservé entre les onglets et lors du changement de thème.
- [x] Niveau rempli par la couleur, sans contour ni gradient.
- [x] Aucun libellé face / dos sur les silhouettes de l'accueil.
- [x] Identifiant Android et clé de signature d'origine.

Les données de démonstration employées par les tests et captures ne sont pas chargées au lancement de l'application.

## Contrôles

Les résultats détaillés, les captures de l'application et les limites de validation sont consignés dans `AUDIT_2.0.0.md` et `validation/2.0.0`.

La vérification sur ton téléphone permettra de juger le ressenti, les notifications système et le rendu de l'icône avec ton lanceur. La version a été réalisée directement à ta demande ; aucune nouvelle validation visuelle de ta part n'est supposée.

## Historique

Les demandes, validations et livraisons antérieures sont conservées dans `docs/REFONTE_UI_1.8.7.md` et dans les audits 1.8.x.
