# Kalis Track — Refonte UI 2.2.0

Mise à jour : 21 septembre 2026. Version **2.2.0+43**.

Cette livraison applique la nouvelle palette, ajoute les transitions et réserve l’acquisition de nouveaux WOD au catalogue. STATS conserve son suivi unifié. La navigation principale reste **ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Palette, logo et transitions — intégré

- [x] Couleurs de référence : **#6D0808**, **#2D0000**, **#757D6F**, **#EEEAD7**.
- [x] Thèmes clair et sombre, surfaces chaudes et accents sauge, avec nuances de texte adaptées au contraste.
- [x] Forme historique du K conservée ; aucun carré, pastille ou fond coloré derrière le logo dans l’application.
- [x] K crème en mode sombre et bordeaux en mode clair, y compris pendant l’ouverture.
- [x] Icônes Android mises aux couleurs de la palette ; leur fond natif crème est indépendant du logo affiché dans l’application.
- [x] Transitions sobres : onglets et rubriques STATS (240 ms), semaines (240 ms), ouverture / retour de pages (280 / 220 ms sur Android).
- [x] Navigation rapide et retour sans recréer les filtres, saisies ou états conservés.
- [x] Mouvements ajoutés désactivés avec « Réduire les animations » ; sélecteur STATS adapté au réglage système.
- [x] Arrondis de cartes, boutons, menus et fenêtres conservés.

## WOD — acquisition dans le catalogue

- [x] Bouton « Créer un WOD » et écran d’édition supprimés.
- [x] Aucune commande de modification ou duplication de WOD dans les menus.
- [x] Catalogue de 500 WOD avec recherche, filtres et solde de crédits.
- [x] Prix visible, bouton « Acheter », puis état « Acquis » et accès au chrono.
- [x] Achat avec les crédits gagnés dans l’application ; aucune transaction monétaire ajoutée.
- [x] Débit unique, achat conservé après rechargement, tentatives suivantes sans nouveau débit.
- [x] WOD verrouillé : le chrono reste inaccessible tant que l’achat n’est pas effectué.
- [x] Crédits insuffisants : montant manquant indiqué, achat impossible.
- [x] WOD précédemment acquis, anciens WOD personnels et résultats conservés ; aucun effacement de données.
- [x] Création et édition des séances personnelles conservées.

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

- [x] Nouvelle palette bordeaux / sauge / crème, silhouette originale du logo et angles arrondis.
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

Les contrôles sont consignés dans `AUDIT_2.2.0.md` et `validation/2.2.0`. Les captures utilisent un journal de démonstration uniquement dans les tests ; il n’est pas ajouté à l’application.

Le projet et son workflow de compilation sont livrés. Aucun APK ni test sur téléphone physique n’est revendiqué dans cet environnement. Cette réalisation répond directement à la demande ; elle ne constitue pas une validation esthétique de ta part.

## Historique

Les checklists 1.8.7, 2.0.0, 2.0.1 et 2.1.0 restent dans `docs/REFONTE_UI_*.md`. Les audits précédents sont conservés.
