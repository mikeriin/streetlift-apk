# Sauvegarde KS1c2

## Fait
- Lot marqué « en cours » (pipeline dc97cc9).
- Lecture : cause probable dans `kalis_plan/lib/src/coach/structure.dart` `_buildTyped` : `pushEndurance` (et les autres) n'ajoutent rien sans repère (`dipMax`, `pushMax`, `pullMax` = 0).
- Banc : `kalis_bench/lib/src/principal_criteria.dart` (critère « aucun jour sans son principal », grille 6 repères × 3 santé × 4 niveaux par base) ; profil `profiles_ks1c2/ks1a_street_5050.json` (réplique du profil d'exemple de l'application) ; diagnostic `bin/ks1c2_diag.dart` (dev).
- Pas de SDK Dart dans la session : mise au point par commits « KS1c2 contrôle (dev) » sur `claude/ci-cp-b` (workflow et script dans `dev_ks1c2/`).

## En cours
- Run 1 : diagnostic avant correction.

## Reste
- Correction `_buildTyped` (garantie du principal par schéma, repli prudent, note de calibrage des répétitions, changement de type dit), test qui échoue avant, critère au rapport de structure, docs, versions 0.4.2 / bench suivante, contrôle complet, publication.
