# Sauvegarde KB1

Base : main e5d3829 (dev7.1.9). Travail dans un worktree de main (branche locale kb1).

## Fait
- kalis_plan 0.4.2 copié (arbre identique à etiquettes/kalis_plan-v0.4.2) ; kalis_adapt 1.0.4 : lib/, assets/koach/, pubspec.yaml seulement (identiques à 9c81a201), reste retiré (reference/, test/, tool/, docs/, bin/…).
- assets/koach/koach_params_1_0_5.json (SHA-256 d8a492b7…f26d) à la place de 1_0_3 ; pubspec, kKoachParamsAsset, pubspec.lock (1.0.4, 0.4.2), version 7.2.0+140 et tests de version.
- Export du journal moteur : versions du moteur courant, `prise_de_main` si la prise de main vient d'une version d'avant.
- Carte « Structure de la semaine » : changements de type de jour (plan_texts.dart dayTypeChanges / dayTypeChangeText ; plan_screens.dart).
- CI paquets : `dart test` sauté sans test/ (ci-3d.yml, ci-ui.yml).
- Inventaire du code 0.x : rien de mort tant que la bascule est fermée (sous-agent) ; rien retiré dans lib/.

- test/kb1_koach105_test.dart, cible émulateur integration_test/koach_kb1_test.dart (ci3d_drive.sh, délai 125 min), formatage fait (claude/fmt-kb1 bc86738).
- Poussé sur claude/ci-ui-kb1-rapide et claude/ci-3d (commit bc86738).

- Relecture indépendante faite (0 bloquant) ; phrases revues, clés uniques, précompilation de la cible KB1.
- Suite Dart complète verte (1 097 tests, run 39120362509) sur 2f178b5 ; contrôle final lancé sur c45cbe4 (claude/ci-3d).

## Reste
- Lire les résultats CI, corriger ; rebase sur main ; push main ; build signé ; livraison ; ETAT ; page de suivi ; notification.
- Run 39121486450 (c45cbe4) : suite Dart et paquets verts ; émulateur : KB1 rouge (export de l'inspecteur dans la session de test non atteint : défilement), KS1A (en-tête « S14 · J5 » depuis PR2), CI1 (panneau du coach dans ⓘ depuis PR7), KM3 (dimanche : aucune séance restante dans la semaine) rouges sur des causes antérieures à KB1 ; CI1e, CI1f : émulateur (connexion VM refusée). Corrigés dans les cibles (17f39fc), contrôle relancé 12:45 UTC.
