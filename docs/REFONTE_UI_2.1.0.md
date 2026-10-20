# Kalis Track — Refonte UI 2.1.0

Mise à jour : 21 septembre 2026. Version **2.1.0+42**.

Cette livraison regroupe Suivi, Pilotage, progression et statistiques dans **STATS**, conformément à la nouvelle demande. La navigation principale comporte désormais quatre destinations : **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## STATS — intégré

- [x] Un seul onglet avec quatre rubriques : Aperçu, Parcours, Performances et Historique.
- [x] Aperçu : niveau, rang, barre d’XP, crédits WOD et badges obtenus.
- [x] Indicateurs hebdomadaires : entraînements terminés, séries validées, jours actifs et semaines de régularité.
- [x] Prochain objectif concret avec avancement et récompense ; accès aux quatre défis hebdomadaires.
- [x] Activité sur huit semaines, avec détail chiffré accessible par un appui.
- [x] Arbre de progression à trois branches : Pratique, Rythme et Défis.
- [x] Paliers reliés pour les séances, séries, semaines régulières, WOD, exploration et records.
- [x] États explicites : Obtenu, Prochain palier, À venir ; icônes, libellés et jauges.
- [x] Un appui sur un palier explique son critère, sa progression et son bonus.
- [x] Bonus calculés depuis les données existantes ; consulter un badge ne distribue pas de XP.
- [x] Rangs, prochains crédits et origine des XP regroupés dans le détail du niveau.
- [x] Performances : références de force et d’endurance, cibles, muscles sollicités et meilleurs résultats WOD.
- [x] Modification des références, poids de corps et charges depuis STATS → Performances → Modifier mes références.
- [x] Historique commun : séances du programme, séances personnelles et tentatives WOD.
- [x] Recherche par nom ou note, filtres Tout / Séances / WOD, ordre chronologique.
- [x] Anciennes séances sans date conservées dans l’historique.
- [x] Séries et notes des séances en lecture seule ; scores et notes WOD consultables.
- [x] Les raccourcis du niveau et du dialogue de montée de niveau rejoignent STATS → Parcours.
- [x] Retrait du résumé de progression d’Arsenal ; seul le solde de crédits utile au catalogue y reste visible.
- [x] Rubrique, recherche, filtre et défilement conservés pendant la navigation.
- [x] Rafraîchissement immédiat après validation de données ou changement des références.
- [x] Petits écrans, texte agrandi et libellés pour le lecteur d’écran contrôlés.

## Présentation et fonctionnement conservés

- [x] Bordeaux **#6C1A1A**, silhouette originale du logo, fonds chauds et angles arrondis.
- [x] Programme : J1 à J7 dans l’ordre, autres jours compacts, jour actuel détaillé.
- [x] Slider : appui court pour les détails, long pour choisir, glissement pour naviguer.
- [x] Appui sur une journée pour ouvrir ; appui long pour son résumé.
- [x] « NIV. » et barre d’avancement dans l’en-tête de Programme.
- [x] Calculs de charge, programme, huit modes de séance, séries, notes et chronos.
- [x] XP, crédits, badges, déverrouillages et règles de régularité existants.
- [x] Import / export, stockage, notifications et signature Android.
- [x] Choix de semaine conservé en changeant d’onglet et de thème.

Les jours de récupération ne sont pas présentés comme des entraînements dans les indicateurs. Ils restent comptés dans l’avancement des journées du programme lorsqu’ils sont validés. Les semaines régulières exigent toujours deux jours actifs, sans obligation quotidienne.

## Validation et livraison

Les contrôles sont consignés dans `AUDIT_2.1.0.md` et `validation/2.1.0`. Les captures utilisent un journal de démonstration uniquement dans les tests ; il n’est pas ajouté à l’application.

Le projet et son workflow de compilation sont livrés. Aucun APK ni test sur téléphone physique n’est revendiqué dans cet environnement. Cette réalisation répond directement à la demande ; elle ne constitue pas une validation esthétique de ta part.

## Historique

Les checklists 1.8.7, 2.0.0 et 2.0.1 restent dans `docs/REFONTE_UI_*.md`. Les audits précédents sont conservés.
