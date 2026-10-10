# Kalis Track — Refonte UI 2.2.4

Mise à jour : 22 septembre 2026. Version **2.2.4+47**.

Cette livraison ne touche qu’à la barre de navigation (`lib/nav_bar.dart`),
issue de la maquette « juste milieu » du canvas One UI 8. Tout le reste de
l’interface 2.2.3 est conservé à l’identique. Navigation :
**ARSENAL · STATS · PROGRAMME · RÉGLAGES**.

## Dock — intégré

- [x] Capsule floutée de 64 px, marges 20 / 8 / 12, rayon 32, fond `surface` à 94 %, contour `line` à 65 %.
- [x] Onglet actif : icône + libellé en capitales (10,5 px, 800, interlettrage 0,5) dans une pastille `accentTint`, texte et icône en `accent`.
- [x] Onglets inactifs : icône seule en `dim`, libellé replié à largeur nulle (`Align(widthFactor: 0)` sous `ClipRect`), donc toujours présent dans l’arbre.
- [x] Largeur de l’onglet actif : 1,9 onglet replié, animée par `TweenAnimationBuilder` (240 ms, `easeOutCubic`) ; `AnimatedSize` révèle le libellé ; `FittedBox` le réduit au lieu de le couper.
- [x] `HeroNavBar.extent` = 84 (8 + 64 + 12), utilisé tel quel par `RootNav` pour l’inset de défilement.
- [x] Conservés : API `HeroNavBar(index:, onTap:)`, clés `nav-$i`, `Semantics` (bouton, sélection, libellé), `Tooltip`, `HapticFeedback.selectionClick`, `BackdropFilter`, largeur maximale 560, respect de « Réduire les animations ».

## Conservé

- [x] Programme, STATS, Arsenal, Réglages, séances, chronos, WOD, XP, crédits, notifications, import / export, signature : inchangés depuis 2.2.3.
- [x] Tests existants : `programme_test` (4 `Text` dans le dock, `BackdropFilter`), `redesign_test` (libellés en capitales sous chaque clé `nav-$i`), `motion_test` et `ui_refactor_test` (navigation par clé) restent applicables sans modification.

## Validation et livraison

Voir `AUDIT_2.2.4.md`. Aucune analyse, compilation ni test Flutter n’a pu être
exécuté dans l’environnement de livraison ; le workflow GitHub reste le point
de contrôle avant l’APK.

## Historique

Les checklists 1.8.7 à 2.2.3 restent dans `docs/REFONTE_UI_*.md`.
