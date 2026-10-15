# Sauvegarde CIF (lot CI final, dev6.18.0)

Base : main 8d1ef051 (dev6.17.3). Lot « en cours depuis 2026-10-15 15:29 UTC » sur `pipeline`.

## Fait
- Points 1 à 9, 11, 12 codés et testés (test/cif_points_test.dart, cif_report_test.dart, cif_seance_test.dart ; cible integration_test/lot_cif_test.dart). Rapide vert (claude/ci-ui-cif-rapide, run 38767033368 + formatage).
- Relecture indépendante prise en compte (jour J daté, allure plausible, miniSetsLeft seulement si la série suivante a un bandeau, épreuves personal_test / date approximative exclues, flammes du dernier bloc d'un cluster).
- Version 6.18.0+127, README, SUIVI, docs/CI_GP.md.
- Contrôle complet lancé sur claude/ci-3d : commit 430d9760, arbre d008a757 (16:17 UTC).

## Reste
- Lire le résultat du contrôle complet (ci-out), corriger si rouge.
- Publier sur main (avance rapide, arbre identique), build signé, livraison, ETAT_CP, page de suivi, notification.
- Point 10 : reporté (pas de SDK Dart dans la session ; la clé ne va jamais en CI).
