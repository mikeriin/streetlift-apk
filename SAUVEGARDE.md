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

## Boucle 0 (passe complète initiale, 03/10/2026 ≈ 23:20 UTC)
Ancres : (a) = 1 partout ; (c) = 8 (force), 9, 9, 9. Grilles : empreintes conformes.
Notes d'ensemble [force, calisthénie, hypertrophie, santé | relecture documentée] :
01 [7,7,8,7|6] 02 [7,7,7,7|6] 03 [6.5,7,7,8|5] 04 [5,7,6.5,4.5|6] 05 [6,5.5,5,5|5] 06 [7,7,6.5,7|6]
07 [7.5,7,9,9|7] 08 [7,7,8,7|5] 09 [8,8,9,8|7] 10 [4,6.5,7.5,5.5|4] 11 [7,8,7,7|6] 12 [5,8,9,7|6]
13 [6,6,7,6|5] 14 [7,5.5,6,6.5|6] 15 [6.5,6.5,7,6.5|6] 16 [8,8,8,8|7] 17 [7,7,6.5,6|5]
Panel : min 4, moyenne ≈ 6,9 ; relecture documentée : min 4, moyenne ≈ 5,8. Quota de recherches web de la session épuisé (200/200) pendant la relecture documentée.
Notes complètes : /home/claude/cp1/panel/p0 (all.json, corrections.txt).

## Boucle 1 (04/10/2026)
Corrections : trajectoire prévue vers l'objectif, densité plafonnée, poussée en entretien, tirage horizontal gardé, tests visés, tentatives vers l'objectif, course (allures, test chronométré), débutant (négatives, tenue menton, marche), figures (étapes prévues, budget poignet, force regroupée), reprise, coude, textes des règles.
Panel [force, cali, hyper, santé] : 01 [7,8,7,8] 02 [9,7.5,9,8] 03 [7,7,7,7] 04 [7,8,8,5] 05 [8,8,8,8] 06 [9,9,9,8] 07 [8,7,8,8] 08 [8,7,7,8] 09 [8,8,8,8] 10 [5,5,5,5] 11 [8,8,9,9] 12 [9,7,9,9] 13 [8,8,9,9] 14 [8,7,8,8] 15 [9,8,9,8] 16 [7.5,7,8,8] 17 [8,7,8,8] — min 5, moyenne 7,76.
Relecture documentée : 01 6, 02 7, 03 6, 04 7, 05 6, 06 7, 11 7, 12 6, 13 6, 14 7, 15 7, 17 6, 07 7, 08 6, 16 7, 09 7, 10 5 — min 5, moyenne 6,5.
