# Sauvegarde KB1

Base : main e5d3829 (dev7.1.9). Travail dans un worktree de main (branche locale kb1).

## Fait
- kalis_plan 0.4.2 copié (arbre identique à etiquettes/kalis_plan-v0.4.2) ; kalis_adapt 1.0.4 : lib/, assets/koach/, pubspec.yaml seulement (identiques à 9c81a201), reste retiré (reference/, test/, tool/, docs/, bin/…).
- assets/koach/koach_params_1_0_5.json (SHA-256 d8a492b7…f26d) à la place de 1_0_3 ; pubspec, kKoachParamsAsset, pubspec.lock (1.0.4, 0.4.2), version 7.2.0+140 et tests de version.
- Export du journal moteur : versions du moteur courant, `prise_de_main` si la prise de main vient d'une version d'avant.
- Carte « Structure de la semaine » : changements de type de jour (plan_texts.dart dayTypeChanges / dayTypeChangeText ; plan_screens.dart).
- CI paquets : `dart test` sauté sans test/ (ci-3d.yml, ci-ui.yml).
- Inventaire du code 0.x : rien de mort tant que la bascule est fermée (sous-agent) ; rien retiré dans lib/.

## Reste
- test/kb1_*_test.dart, cible émulateur integration_test/koach_kb1_test.dart + ci3d_drive.sh, formatage (claude/fmt-kb1), CI rapide puis ci-3d, main, build, livraison.
