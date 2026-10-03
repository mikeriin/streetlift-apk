# Sauvegarde CP1 (kalis_plan 0.2.0, street)

Session lancée le 2026-10-03 20:25 UTC (tâche Fable moteurs, sans ligne « Lot : » : CP1 est le seul lot moteur « à faire »).
Clé des références : lue dans le projet claude.ai (`claude/CLE_REFERENCES_CP.md`), absente du message de lancement ; jamais écrite ici.

## Fait
- Accès push vérifié ; CP1 marqué « en cours depuis 2026-10-03 20:27 UTC » (pipeline 588e6f43).
- Empreintes des cinq grilles du panel vérifiées (identiques à PANEL.md).
- Notes de la page de relecture lues (70 documents, tous `relecture-documentee`, manche 0) = RELECTURE_DOCUMENTEE_M0.md.
- Lus en entier : PIPELINE_CP, DECISIONS_CP, PIPELINE_GP, BASELINE_0_1, PANEL, grilles, CRITERES, ETALONNAGE, REFERENTIEL (R1-R5), MESURES_REFERENCES, CONTRAT kalis_plan 0.1, CONTRAT kalis_core (§1-16), profils street (attentes).
- Références déchiffrées dans /tmp/cp-references (hors dépôt).

## Décisions de conception (à consigner dans DECISIONS_CP.md, section CP1)
1. Pas de SDK Dart local : tout passe par claude/ci-cp-a. Boucles de mise au point sur un arbre réduit (sans kalis_quest, tests lourds retirés) + paquet outil `aa_fmt` (formatage en CI, sources formatées recopiées dans ci-out) — jamais sur `moteurs`.
2. Chemin « coach » (nouveau) pour les profils street au schéma 3 ; profils au schéma 2 et disciplines non street : chemin 0.1 inchangé (aucune régression, tests 0.1 intacts).
3. Passe 1 coach = squelette (mouvements, fréquences, rôles des jours) ; passe 2 coach = fonction pure de (profil, saison, passe 1).
4. Saison : calculée à rebours depuis l'échéance (SeasonPlanner), blocs de 4 à 6 semaines calés pour finir sur l'échéance.
5. Notes de coach = codes de raison ; nouveaux codes → kalis_core 0.4.1 (commit séparé, additif).
6. Banc : adaptateur v3, generateProgram passe la saison, export rendu des nouveautés (saison, techniques, règles, échelles) → kalis_bench 0.1.1.

## En cours (22:15 UTC)
- kalis_core 0.4.1 : commit local d6d24460 sur moteurs (non poussé).
- kalis_plan 0.2.0 (non commité, dans l'arbre de la sauvegarde) : lib/src/coach/{athlete,season,model,tables,skeleton,prescribe,coach,audit,texts}.dart, branchement dans engine.dart et inspect.dart, lib/testing.dart (randomCoachProfile), tests coach_test.dart et coach_properties_*.dart, CHANGELOG, docs régénérées (version).
- kalis_bench 0.1.1 (en cours) : adaptateur v3 (lib/src/adapter.dart), export (saison, échelles, règles, techniques), tool/panel_export.py.
- Boucles de mise au point par la CI de contrôle (claude/ci-cp-a, mode réduit) : compile et tests 0.1 verts ; calibrage des volumes et des garde-fous sur le référentiel en cours ; panel pas encore lancé.
- Décisions à consigner : chemin street réservé aux profils schéma 3 avec expérience ET ancienneté (les profils aléatoires 0.1 gardent le chemin 0.1) ; volume sous-maximal (max ≥ 12) et densité à 5 RIR ou plus (hors séries dures) ; plafonds 10/16/20/25 (R1-P1, R5-P13) ; conflit d'attentes street_12 (c1 vs c4).
- Outils hors dépôt : /home/claude/cp1/{ci.sh,ci_wait.sh,sauve.sh,sync_fmt.sh,report.sh,aa_fmt/}.

## Reste à faire
- Finir la mise au point (CI verte en mode réduit puis complet), CONTRAT § 12, NOTES_COACH.md, CALIBRAGE_CP1.md, README ; kalis_bench 0.1.1 (version, CHANGELOG, docs/PROFILS.md) ; panel (ancres, passe initiale, boucles) et relecture documentée ; Jaccard références ; relecture indépendante ; fin de lot (§7).
