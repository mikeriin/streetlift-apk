# Lancements du pipeline « Refonte UI et UX » (UI)

Contexte écrit par la conversation de pilotage, une section par lot. Une section lue ici prime sur le prompt du lot quand ils diffèrent.

## UI0

**Lancé le 10/10/2026 à 11:46** sur feu vert du propriétaire (« Lance ui0 »), après validation du cahier version 3 ; ce feu vert confirme aussi les décisions U1 à U9 (DECISIONS_UI.md U0.10).
- Palettes : les 8 du propriétaire (`inputs/palettes_kalis_track.txt`) ; tableau de référence `inputs/palettes_roles.json`.
- KM1 tourne en parallèle sur `moteurs` : ne touche ni `packages/` ni `moteurs`.
- Aucun autre lot de la voie application ne tourne : `claude/ci-3d` est libre pour UI0.

### Corrections du propriétaire (10/10/2026), déjà intégrées au cahier version 3
- 10:11 : dominantes exactes pour les aplats (`#551515`), texte posé dessus adapté (§5.1).
- 10:26 à 10:52 : rayons cartes 24, menus 20, commandes en pilule ; un élément ne change pas de forme quand il est choisi (§5.3) : à porter dans les jetons et les composants de UI0.
- 11:41 : arborescence des menus validée (§4) ; UI0 fournit `KSearchField` et prévoit, dans le tour de captures, les relevés de parcours de §6.3.

## UI1

**Lancé le 10/10/2026 à 14:55** par le pilotage (C8), en parallèle de UI2, UI3 et UI4, après validation de UI0 (DECISIONS_UI.md U0.11).
- Base : `refonte-ui` 0e5342df. Mode d'emploi du kit : `livraisons/LIVRAISON_UI0.md` §7 (jetons, `KMenuPage`, `KMenuRow`, `showKActionSheet`, `showKListSheet`, `showKConfirm`, `KSearchField`, `KSegmented`, contrôle de zone, tour, captures).
- Contrôle rapide : `claude/ci-ui-ui1-rapide` ; complet : `claude/ci-ui-ui1` (une concurrence par branche : aucune attente sur les autres lots).
- Cahier version 3 : §4 (arborescence, règles R1 à R9, déplacements de ta zone, défauts §4.6) et cibles de parcours §6.3 ; ta partie de `inputs/inventaire_navigation.md`.
- Règle de couleur de UI0 (UI0.8) : texte `encre` ou `accent` seulement sur `fond` ou `surface`. En clair, les commandes posées en `haute` prennent `k.controlPill`.
- KM1 tourne sur `moteurs` : ne touche ni `packages/` ni `moteurs`.
- Points laissés par UI0 dans ta zone : bandeau « Nouveau : 11 questions… » encore sous le dock → `KNotice` dans le flux (C8) ; `SegmentedButton` Material d'Évolution → `KSegmented` ; frise de semaine remplacée par `KSeasonBar` (U7).
- La ligne « Mon programme » est **permanente** (le tour de UI0 mesurait 1 appui par le bouton conditionnel de la carte du moment) : mesure-la sur un profil sans carte du moment.
- Ajoute au tour un profil d'exemple avec une compétition pour mesurer Jour J (cible 3).
- Défaut des récompenses (§4.6) : à toi (`home_screen.dart`), avec test d'intégration.

## UI2

**Lancé le 10/10/2026 à 14:55** par le pilotage (C8), en parallèle de UI1, UI3 et UI4, après validation de UI0 (DECISIONS_UI.md U0.11).
- Base : `refonte-ui` 0e5342df. Mode d'emploi du kit : `livraisons/LIVRAISON_UI0.md` §7 (jetons, `KMenuPage`, `KMenuRow`, `showKActionSheet`, `showKListSheet`, `showKConfirm`, `KSearchField`, `KSegmented`, contrôle de zone, tour, captures).
- Contrôle rapide : `claude/ci-ui-ui2-rapide` ; complet : `claude/ci-ui-ui2` (une concurrence par branche : aucune attente sur les autres lots).
- Cahier version 3 : §4 (arborescence, règles R1 à R9, déplacements de ta zone, défauts §4.6) et cibles de parcours §6.3 ; ta partie de `inputs/inventaire_navigation.md`.
- Règle de couleur de UI0 (UI0.8) : texte `encre` ou `accent` seulement sur `fond` ou `surface`. En clair, les commandes posées en `haute` prennent `k.controlPill`.
- KM1 tourne sur `moteurs` : ne touche ni `packages/` ni `moteurs`.
- Points laissés par UI0 dans ta zone : indicateur de page de la séance encore en rôle historique `action` (secondaire) → `encre` ou `pleine` selon le cas ; tableau des séries → `KSetTable`, barre de repos → `KRestBar` (le message de Koach passe au-dessus, `showKSnack(bottom:)`).
- « Voir la fiche » ouvre la page de fiche existante (`exercise_screens.dart`, fichier de UI4) : tu l'appelles sans modifier ce fichier.
- Mesure au tour : fiche pendant la séance (cible 2), douleur (cible 4), Mes références depuis le ⋮ (cible 2).

## UI3

**Lancé le 10/10/2026 à 14:55** par le pilotage (C8), en parallèle de UI1, UI2 et UI4, après validation de UI0 (DECISIONS_UI.md U0.11).
- Base : `refonte-ui` 0e5342df. Mode d'emploi du kit : `livraisons/LIVRAISON_UI0.md` §7 (jetons, `KMenuPage`, `KMenuRow`, `showKActionSheet`, `showKListSheet`, `showKConfirm`, `KSearchField`, `KSegmented`, contrôle de zone, tour, captures).
- Contrôle rapide : `claude/ci-ui-ui3-rapide` ; complet : `claude/ci-ui-ui3` (une concurrence par branche : aucune attente sur les autres lots).
- Cahier version 3 : §4 (arborescence, règles R1 à R9, déplacements de ta zone, défauts §4.6) et cibles de parcours §6.3 ; ta partie de `inputs/inventaire_navigation.md`.
- Règle de couleur de UI0 (UI0.8) : texte `encre` ou `accent` seulement sur `fond` ou `surface`. En clair, les commandes posées en `haute` prennent `k.controlPill`.
- KM1 tourne sur `moteurs` : ne touche ni `packages/` ni `moteurs`.
- « Records » : `records_screen.dart` (ta zone) n'est appelé nulle part aujourd'hui ; vérifie qu'il affiche des données réelles avant de le brancher, sinon remets-le d'aplomb dans ta zone sans toucher la logique.
- Objectif de la semaine : segments « Adaptatif, 2, 3, 4, 5, 6 », mêmes que ceux de UI4 dans Réglages (valeur 1 déjà enregistrée affichée telle quelle, aucune migration).
- « Mes références » ouvre la page de `pilotage_screen.dart` (fichier de UI4), sans le modifier.

## UI4

**Lancé le 10/10/2026 à 14:55** par le pilotage (C8), en parallèle de UI1, UI2 et UI3, après validation de UI0 (DECISIONS_UI.md U0.11).
- Base : `refonte-ui` 0e5342df. Mode d'emploi du kit : `livraisons/LIVRAISON_UI0.md` §7 (jetons, `KMenuPage`, `KMenuRow`, `showKActionSheet`, `showKListSheet`, `showKConfirm`, `KSearchField`, `KSegmented`, contrôle de zone, tour, captures).
- Contrôle rapide : `claude/ci-ui-ui4-rapide` ; complet : `claude/ci-ui-ui4` (une concurrence par branche : aucune attente sur les autres lots).
- Cahier version 3 : §4 (arborescence, règles R1 à R9, déplacements de ta zone, défauts §4.6) et cibles de parcours §6.3 ; ta partie de `inputs/inventaire_navigation.md`.
- Règle de couleur de UI0 (UI0.8) : texte `encre` ou `accent` seulement sur `fond` ou `surface`. En clair, les commandes posées en `haute` prennent `k.controlPill`.
- KM1 tourne sur `moteurs` : ne touche ni `packages/` ni `moteurs`.
- Tu pars du `settings_screen.dart` de UI0 (sélecteur `KPalettePicker`, « Contraste renforcé », thème en `KSegmented`) : garde-les, déplace-les dans la sous-page « Apparence ».
- Index de recherche `settings_search.dart` (§4.4) et son test ; mesure au tour « Repos par défaut » par la recherche (cible 2) et Mes références (cible 2, contre 3 au départ).
- Objectif de la semaine : segments « Adaptatif, 2, 3, 4, 5, 6 », mêmes que ceux de UI3 dans Stats.
- `SegmentedButton` Material restants de ta zone → `KSegmented`.
