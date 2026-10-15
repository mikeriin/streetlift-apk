# Sauvegarde KS1

Session Opus 5.5 moteurs, lancée le 15/10/2026 vers 15:30 UTC (message sans « Lot : » ; KM2c1 déjà pris par une autre session à 15:29 → KS1).
Pas de SDK Dart dans la session : compilation, formatage et tests via `claude/ci-cp-b` (arbre réduit : `pk/<paquets>` + `packages/aa_fmt` qui formate et rend le diff, `packages/aa_ks1` qui mesure ; outils dans la sauvegarde sous `outils_ks1/` si présents).

## Fait
- Ligne KS1 « en cours » (pipeline 7e4a7f1).
- Mesure de départ 0.3.1 (run 38762777325) : récupération (formule 0.1) 0,17 à 0,87 sur les profils à 4 séances et plus ; couverture : seuls les profils mixtes ks_* manquent (objectifs de répétitions en style lifting, K4) ; temps estimé par le banc 50 à 60 % du créneau.
- kalis_core 0.4.4 (spec + génération + docs + test structure_test.dart), non formaté.
- kalis_plan 0.4.0 : structure.dart (gabarits typés ppl6_q, pp_l5, ul4, fb3, fb2 ; composite mix_q ; placement exhaustif ; choix lexicographique ; type de jour dérivé ; récupération par schéma ; composantes recalées), buildSkeleton refactoré (_construct), saison (targetOf, jalons, 4e bloc en intensification), corrections § 8 (plancher MU, références de charge, pause, squat pause bas, raisons des remplacements), Method.liftFixed.
- Profils ajoutés : packages/kalis_bench/profiles_ks/ (7).

- CI 38767820359 : compilation et banc structure (aa_ks1) ; corrections : note relue = note rendue (scoreOf recalé), plafond d'allègement sur l'intention deload, jambes E avec principal, méthodes douces, test structure_test.dart de kalis_plan, CONTRAT § 12.15, docs/STRUCTURE_SEMAINE.md, banc structure_criteria + runStructureBench.
- 16:45 : gabarits typés généralisés (qualités au plus fort reste sur la suite des schémas : ppl6_q 4+2, ul4 1+3…), pas minimal quand la part visée s'arrondit à +0 kg, CHANGELOG 0.4.0.

## En cours
- Run de contrôle avec mesure avant (AVANT=1, aa_ks0) : fichiers de référence docs/data/ks1/ du banc à produire.

## Reste
Docs régénérées (PROFILS_TYPES, COMPARAISON_L10), kalis_bench 0.5.0, Jaccard, relecture indépendante, CI complète, publication moteurs + étiquettes, livraison, ETAT_CP, suivi, notification.
