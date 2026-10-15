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

- 17:55 : relecture indépendante (Opus) : 3 bloquants corrigés (pas minimal borné : semaine de charge, hors reprise et prudent, ≥ 3 répétitions à la réserve ; charge fixe seulement sous 80 % du 1RM, hors prudent et reprise, +1 rép. / 2 semaines, jamais à moins d'une en réserve) ; objectif daté à moins de 4 semaines ne remplace pas l'échéance ; eventIds de la saison = toutes les échéances des phases ; répartition de base candidate (profil de test : ppl6_q à chaque bloc). Run 38779114208 : analyse, tests kalis_plan, test structure du banc, formatage : verts. Jaccard max exact 0,188, tolérant 0,250.
- Commits locaux ks1 : 141e52a6 (kalis_core 0.4.4), ba8724d4 (kalis_plan 0.4.0, kalis_bench 0.5.0) sur moteurs 9ac79e40.

## En cours
- Contrôle complet claude/ci-cp-b (commit 33343f2c, arbre de ba8724d4).

## Reste
Publication moteurs (rebase si KM2c1 publié) + étiquettes kalis_core-v0.4.4, kalis_plan-v0.4.0 ; Jaccard des saisons ; livraison (pipeline + projet), ETAT_CP « livré », page de suivi, notification.
