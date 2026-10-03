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

## En cours
- Lecture du code de kalis_plan (traits, scheme, assemble, pass2) et du catalogue street.

## Reste à faire
- Tout le code ; boucles de calibrage ; livraison.
