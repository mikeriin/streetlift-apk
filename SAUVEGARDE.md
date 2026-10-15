# Sauvegarde CIF (lot CI final, dev6.18.0)

Base : main 8d1ef051 (dev6.17.3). Branche locale `cif`. Lot marqué « en cours depuis 2026-10-15 15:29 UTC » sur `pipeline`.

## Fait (code, non encore contrôlé en CI)
- Point 4 : `adaptReasonText(seconds:)` (série repère en secondes sur un maintien), appels de la séance.
- Point 8 : `clearanceSaysWaiting`, carte « Pas encore » sans répétition.
- Point 3 : `adviceText(exerciseName:)` : `stepExerciseId`, `miniSetsLeft`, arrêt des mini-séries ; `miniSetsLeft` effacé après la dernière série.
- Point 2 : `miniSetPlanFor` nul sur une ligne servie telle qu'écrite ; signature du mémo avec l'ordre des parties.
- Point 12 : `miniSets` décidé sur toutes les lignes ; ligne de consigne du bandeau des mini-séries à place réservée.

## Reste
- Points 1, 5, 6, 7, 9, 11 ; point 10 (journal réel : pas de SDK Dart dans la session → reporté probable).
- Tests `test/cif_*_test.dart`, mise au point sur `claude/ci-ui-cif-rapide`, cibles émulateur 1, 2, 6, version 6.18.0, CI_GP.md, contrôle complet `claude/ci-3d`, publication, build signé, livraison.
