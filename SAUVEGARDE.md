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

## Boucle 2 (04/10/2026 ≈ 02:30 UTC)
Corrections : repère calé sur le dernier test (plus de progrès supposé), accord répétitions/%/réserve (R2-P2), muscle-up lesté en séries de 3 + 2e exposition, étape suivante des figures sous condition (plus d'avance au calendrier), 3e exposition de la seconde figure, pas deux jours de tirage consécutifs (≤ intermédiaire), reprise longue (cycle entier à 2 RIR, montée lente, blocs de 6 semaines), tests des variantes et de la première traction à l'échéance, séance facile à J−2, amorçage à J−2 (force), dernier lourd à J−7/J−10, tentatives (3e = 2e + 2,5 à 5 kg), entretien du squat hors objectif, compléments limités, textes des règles.
Panel [force, cali, hyper, santé | doc] : 01 [8,8,9,9|7] 02 [8,8,9,9|7] 03 [7,8,8,8|6] 04 [8,8,8,7|7] 05 [8,8,8,8|6] 06 [9,9,9,9|7] 07 [9,9,9,9|8] 08 [8,8,8,8|7] 09 [9,8,9,9|8] 10 [8,7,8,9|7] 11 [8,8,8,8|6] 12 [8,7,8,9|7] 13 [8,9,9,9|7] 14 [9,8,8,8|7] 15 [9,9,9,9|8] 16 [9,9,9,9|7] 17 [8,9,8,8|6]
Panel : min 7, moyenne 8,38 ; relecture documentée : min 6, moyenne 6,94. Banc : 0 violation street, attentes tenues sauf street_12 c1 (conflit documenté).
Notes complètes : /home/claude/cp1/panel/p2.

## Boucle 3 (04/10/2026 ≈ 03:40 UTC)
Corrections : repère relevé seulement après un test de l'exercice (tests de dips et de pompes ajoutés, reprise par paliers aux tests), 1RM de travail affiché sur un seul repère, descentes freinées au contrôle (plafond propre R5-P8) dès la semaine 2, tirage assisté 3 séries, étape actuelle des figures prioritaire sur l'étape facile, critère de passage mesurable, tests en tête de séance et sur le geste visé, semaine du test à 2 séries, pas de simple lourd hors épreuve de force, premier bloc toujours en construction, muscle-up après la traction quand l'objectif est la traction, textes (douleur, calibrage, parallettes).
[force, cali, hyper, santé | doc] : 01 [8,9,8,9|7] 02 [9,9,9,8|7] 03 [7,8,7,8|6] 04 [9,9,9,9|6] 05 [8,9,9,9|7] 06 [9,9,9,9|8] 07 [9,9,9,9|8] 08 [8,8,9,9|7] 09 [9,9,9,8|8] 10 [9,9,9,9|7] 11 [8,9,9,8|7] 12 [8,8,8,8|8] 13 [9,9,9,9|8] 14 [9,8,9,9|7] 15 [9,9,9,9|8] 16 [9.5,9,9,9.5|8] 17 [8,8,8,9|7]
Panel : min 7, moyenne 8,68 ; relecture documentée : min 6, moyenne 7,29. Banc : 0 violation street.
Notes : /home/claude/cp1/panel/p3.

## Boucle 4 (04/10/2026 ≈ 03:35 UTC)
Corrections : charge lestée sous le poids du corps calibrée à la réserve (1RM « réconcilié » retiré), séance facile à J−2 d'un test, répétition générale à une série par atelier, affûtage linéaire avant une échéance datée, petits records (< 6) en double progression, montée lente des reprises longues, compléments plafonnés, rampe du total de séries dures, étape suivante des figures en tentatives sous condition, intervalles de course à l'allure visée.
Panel renoté pour 01, 02, 03, 05, 08, 09, 11, 12, 14, 17 (notes de la boucle 3 reprises pour les autres, export changé de moins de 10 %).
[force, cali, hyper, santé | doc] : 01 [8,9,8,9|8] 02 [9,9,9,9|7] 03 [8,9,8,8|7] 04 [9,9,9,9|7] 05 [9,9,9,9|7] 06 [9,9,9,9|8] 07 [9,9,9,9|8] 08 [9,9,9,9|7] 09 [9,8,9,9|8] 10 [9,9,9,9|7] 11 [8,8,8,9|7] 12 [9,8,9,9|7] 13 [9,9,9,9|7] 14 [9,8,9,9|7] 15 [9,9,9,9|8] 16 [9.5,9,9,9.5|7] 17 [9,8,9,9|7]
Panel : min 8, moyenne 8,84 ; relecture documentée : min 7, moyenne 7,29. Banc : 0 violation street, attentes tenues sauf street_12 c1.
Notes : /home/claude/cp1/panel/p4.

## Boucle 5 (04/10/2026)
Corrections : essai strict avant la descente chronométrée (débutant), tirage du débutant plafonné (2 séries assistées les jours de descentes, descentes allongées au bloc 2), pompes en descente freinée dès la semaine 1 (objectif pompes), affûtage −45 % et note calée sur les séries dures réelles, étiquette de réserve « sur la dernière série » (export), lest réglé sur le lest du 1RM quand il est proche du poids du corps, coude à ménager : dips d'abord, poignet en fin de séance, troisième exposition légère de traction (jour écarté), mollets et rebonds (hybride course), avant-bras (antécédent coude/poignet), partiels à 95–105 % monotones, veille de test sans tirage, repos-pause (objectif ≥ 15 rép.), notes : objectif ambitieux, stratégie de série maximale, montée avant maintien maximal, suivi (perte de poids), figures élite un cran au-dessus en dynamique.
Panel renoté : 01, 03, 04, 06, 10, 12, 14, 17 (4 écoles), 09 et 11 (force, calisthénie, hypertrophie) ; relecture documentée : 17 profils.
[force, cali, hyper, santé | doc] : 01 [8,9,9,8|7] 02 [9,9,9,9|8] 03 [8,9,9,8|8] 04 [8,8,8,7.5|7] 05 [9,9,9,9|7] 06 [8,8,8,9|8] 07 [9,9,9,9|8] 08 [9,9,9,9|7] 09 [8,9,9,9|8] 10 [9,9,9,9|7] 11 [9,8,9,9|7] 12 [8,9,9,9|8] 13 [9,9,9,9|7] 14 [9,8,9,9|7] 15 [9,9,9,9|8] 16 [9.5,9,9,9.5|8] 17 [9,9,9,9|6]
Panel : min 7,5, moyenne 8,79 ; relecture documentée : min 6, moyenne 7,41. Banc : 0 violation street, attentes tenues sauf street_12 c1.
Notes : /home/claude/cp1/panel/p5.

## Boucle 6 (04/10/2026)
Corrections : reprise longue — semaine 1 à la moitié des séries dures puis hausses de 20 % au plus (plein volume en semaine 5), 3 RIR tout le premier bloc ; débutant — deux séries par exercice les deux premières semaines, descentes freinées en tête de séance, tenue menton à partir de la semaine 3, affûtage court (−30 %), essai strict à chaque test, note « plusieurs tractions depuis zéro » ; repos-pause réécrit (3 relances au plus, un seul mouvement par semaine, à partir de la 2e semaine du bloc) ; lest proche du poids du corps : échelle abaissée ; rappel lourd à J−4/J−6 avant un test daté de 1RM ; rebonds en dose fixe ; repère affiché sur le bas de la plage.
Panel renoté : 01, 03, 04, 06 (4 écoles) ; 09, 11, 12, 14 (force, calisthénie) ; relecture documentée : 17 profils.
[force, cali, hyper, santé | doc] : 01 [9,9,8,9|8] 02 [9,9,9,9|8] 03 [9,9,8,9|7] 04 [8,8,8,8|7] 05 [9,9,9,9|6] 06 [9,8,9,9|7] 07 [9,9,9,9|8] 08 [9,9,9,9|7] 09 [9,9,9,9|7] 10 [9,9,9,9|6] 11 [9,9,9,9|6] 12 [8,9,9,9|7] 13 [9,9,9,9|7] 14 [9,9,9,9|7] 15 [9,9,9,9|7] 16 [9.5,9,9,9.5|7] 17 [9,9,9,9|7]
Panel : min 8, moyenne 8,90 ; relecture documentée : min 6, moyenne 7,0 (05, 10, 11 : export inchangé, note 7 → 6 : dispersion du jury). Banc : 0 violation street, attentes tenues sauf street_12 c1.
Notes : /home/claude/cp1/panel/p6.

## Boucle 7 = passe finale complète (04/10/2026)
Corrections : reprise — montée +10 à 15 % (17 → 19 → 22 → 25 → 29), série d'entrée écrite sur la ligne, repère d'un exercice non testé gelé ; débutant — descentes 3 séries un seul jour au bloc 2 ; exposition légère de traction jamais le lendemain d'un jour de tirage ; seuils de douleur renvoyés à la règle unique ; textes (approche du test, objectif ambitieux depuis zéro).
Passe complète : 17 profils × 4 écoles + relecture documentée des 17 profils.
[force, cali, hyper, santé | doc] : 01 [9,9,9,9|8] 02 [9,9,9,8|8] 03 [9,9,9,9|7] 04 [9,9,9,9|7] 05 [9,9,9,9|7] 06 [9,9,9,9|7] 07 [9,9,9,9|8] 08 [9,8,9,9|7] 09 [9,9,9,9|8] 10 [9,9,9,9|7] 11 [9,9,8,9|7] 12 [8,9,9,9|7] 13 [9,9,9,9|8] 14 [9,8,9,9|7] 15 [9,9,9,9|8] 16 [9,9,9,9|8] 17 [8,9,8,9|7]
Panel : min 8, moyenne 8,90 (61 notes sur 68 à 9) ; relecture documentée : min 7, moyenne 7,41. Banc : 0 violation street, attentes tenues sauf street_12 c1.
Notes : /home/claude/cp1/panel/p7. Reste : tests, docs, CI complète, fin de lot.

## État à l'arrêt (04/10/2026) — fin de lot NON faite
Arrêt avant publication : la lecture du résultat du contrôle complet (`claude/ci-cp-a`, commit dcb1fdd7, mode complet) a été refusée par le contrôle d'autorisations de la session. Décision du propriétaire attendue (voir notification).
Fait : moteur final (cet arbre), tests d'invariants, CONTRAT § 9 et § 12, NOTES_COACH, CALIBRAGE_CP1, banc 0.1.1, relecture indépendante traitée, propriétés vertes sur le contrôle rapide 9150139b (10 240 profils), formatage resynchronisé, analyse complémentaire chiffrée sur `cp-references` (51a4f609).
Notes finales : panel min 8, moyenne 8,97 (66/68 à 9) ; relecture documentée min 7, moyenne 7,41 ; 0 violation street ; attentes tenues sauf street_12 c1.
Reste à faire : lire le contrôle complet (doit être vert) ; commit « Kalis Track moteurs (CP1) : kalis_plan 0.2.0 » sur `moteurs` après rebase ; étiquettes kalis_plan-v0.2.0, kalis_bench-v0.1.1, kalis_core-v0.4.1 ; LIVRAISON_CP1.md (brouillon : `cp1_reprise/LIVRAISON_head.md` + `table_notes.md` + `LIVRAISON_tail.md`, jetons @…@ à remplir : run, commits, attentes par profil, non-ressemblance propriétaire) ; `CP1_M0_TRAITEMENT.md` ; DECISIONS_CP section CP1 ; ETAT_CP ; manche 1 de la page de relecture et notes ; page de suivi ; notification. Le dossier `cp1_reprise/` de cette sauvegarde n'appartient pas au paquet : ne pas le publier sur `moteurs`.

## Fin de lot (04/10/2026)

Lot publié : moteurs d0d60018, étiquettes kalis_plan-v0.2.0 / kalis_bench-v0.1.1 / kalis_core-v0.4.1, contrôle complet run 37185013127 vert, pipeline 8f32f8fb (LIVRAISON_CP1.md, DECISIONS section CP1, ETAT), page de relecture manche 1 + 119 notes, page de suivi. Statut : livré — cible non atteinte, voie A par délégation du propriétaire. Rien à reprendre.
