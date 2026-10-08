# Sauvegarde CA2 (kalis_adapt, voie B, Opus 5.5)

Session lancée le 05/10/2026 18:17 UTC (ligne ETAT_CP « en cours depuis 2026-10-05 18:17 UTC », poussée).
Base : `moteurs` 9526ac47 (kalis_plan 0.2.2, kalis_adapt 0.2.2, kalis_bench 0.2.1). CP2 tourne en parallèle (voie A).

## Fait
- Lecture : PIPELINE_CP, DECISIONS_CP (C7-C9, CA1, CX, CX c1), LANCEMENTS (CA2), LIVRAISON_CA1, CX, CX c1, RELECTURE_DOCUMENTEE_CX, notes de la page (m4 lues ; aucune note `m4_*_pilotage` au 05/10 18:40).
- Pas de SDK Dart dans la session (hôte bloqué) : contrôles par `claude/ci-cp-b`.

## En cours — partie 0 (street, kalis_adapt 0.2.3)
1. Conduite sous douleur : reprise graduée suivie jour par jour (gêne > 2/10, pas revenue à la base, ou en hausse → palier précédent) ; levée jamais en semaine verrouillée ; reprise graduée propre à adapt si l'arrêt se lève au milieu d'un bloc qui écrit les mouvements provocants ; dose d'appui du poignet sans hausse ; tests reportés pendant la reprise.
2. Meilleur maintien récent (pas d'avant l'arrêt) pour le plancher de 55 %.
3. Estimation moins prudente (jamais de baisse sur séries faciles), cran d'assistance sans aller-retour, constats CA1/relecture.

## Reste
- Partie 0 : tests, CI, panel, publication 0.2.3.
- Partie 1 : disciplines non street → 0.3.0.

## Avancement 05/10 ~19:45 UTC
- Code partie 0 écrit (non compilé localement) : `lib/src/pain_return.dart` (reprise graduée : palier qui recule si la douleur répond, arrêt gardé sur semaine non chargée, reprise propre au moteur après une levée en milieu de bloc, part 1RM 67,5 % + 2,5 %/palier), session.dart (tests jamais sur zone douloureuse ni en reprise, appui du poignet sensible = dose écrite au plus), coach.dart (doseCapped/inReturn, maintien récent `recentBestOf`, élastique : 2 séances au même cran, montée seulement après échec / 2 séances sous la plage / >2 rép.), advise/coach_advice (verrous en séance), truth.dart (zone réactive après un épisode, modèles B et C : poussées `painFlares`), kalis_bench season (colonne Douleur « hausses / poussées »).
- kalis_adapt 0.2.3 (version.dart, pubspec). Tests ajoutés : coach_rules_test (levée, maintien récent, street_12 coude, street_01 élastique).
- Contrôle dev poussé sur claude/ci-cp-b (commit 55d74554) : outil aa_fmt, graines 4, sans kalis_quest. Script : ci.sh (scratchpad, voir commit).

## Avancement 05/10 ~19:50 UTC
- Contrôle dev 2 (6afd314b, run 37361856152) : kalis_adapt vert, kalis_bench vert, format OK. Hausses sur zone douloureuse : 0 partout (avant : 0,49 pour street_12 scénarios douleur — tests faits sur zone douloureuse).
- Ajouts boucle 1 ter : gain d'affûtage 2 % des tentatives (Travis 2020), CONTRAT § 11.16, CHANGELOG 0.2.3 ; contrôle dev 3 poussé (b02991c6).
- Dérive du panel (ancres p08_a, p14_c) : (a) 1/1/1/1, (c) 9/8/8/8 → pas de dérive. Empreintes des grilles identiques.
- Recherches : sources vérifiées (Silbernagel 2007 via source secondaire, Soligard 2016, ACSM 2009, Travis 2020/2021, Darragh 2025, Halperin 2022, Bosquet 2013 résumé, NSW ACI 2022, Nielsen 2014, Buist 2008, Wang 2023).
- Suite : passe panel complète (17 saisons street, contrôle dev 3), relecture documentée, relecture du code, contrôle full, publication 0.2.3.

## Avancement 05/10 ~20:40 UTC
- Panel passe 1 (13 profils sur dev 2 : 01-06, 08, 10, 11, 13-15, 17) : 11 couples sur 52 à 9 ; corrections nécessaires presque toutes sur le programme écrit (kalis_plan) ; côté adapt : cadence de l'élastique (01), poussée à prise neutre sur poignet douloureux (01, 03). Notes : ca2-outils/notes/p1, p1_corr.md.
- Boucle 2 : cran d'élastique 14 jours au moins (coachAssistMinDays), substitution prise neutre (poignet), relecture indépendante du code (16 constats, corrigés : levée datée sans compteur courant, substitution poignet seule et qui n'en provoque aucune autre, appui neutre sous 6/10, part la plus basse, arrondi vers le bas, conseil du poignet, zone réactive (tolérance qui ne baisse pas, séries des mouvements provocants), taperedAt avant le bloc, gain d'affûtage avant la 1re tentative, semaine de levée comptée à moitié, contrat).
- Contrôle dev 5 poussé (remplace dev 4).
- Reste partie 0 : panel 07, 09, 12, 16 + renote des profils changés (01, 03, 10…) sur dev 5, relecture documentée (7 saisons), contrôle full, publication 0.2.3 (moteurs, étiquette, DECISIONS, ETAT, page de relecture manche 5, notification).

## Avancement 05/10 ~22:15 UTC
- Panel p2 (01, 03, 07, 09, 12, 16 sur dev 7) + p1 : 17 couples sur 68 à 9, minimum 6, moyenne 7,87 (c1 : 23, 5,5, 7,95). Notes : ca2-outils/notes/p1, p2, final_p2.json.
- Relecture documentée (3 Opus, sources web, 8 saisons dev 7) : 01 6,5 ; 03 5,5 ; 06 6,5 ; 07 6,5 ; 08 5,5 ; 10 5 ; 12 7 ; 14 6 (ca2-outils/notes/reldoc). Constat commun : estimations baissées par des séries faciles ou arrêtées tôt, tentatives à 90-92 %.
- Boucle 3 (dev 03e643c6) : série lourde lue avec le biais appris (coachHeavyBoundReps 8), série arrêtée sous la cible lue comme borne (deuxième mesure), bilan bas comparé à la dernière séance d'une semaine de charge (SlotMark.loadedTop / loadedLoadKg), élastique 7 jours.
- Contrôle full f3fe571b annulé par le dev de la boucle 3 (même groupe de concurrence).

## Avancement 05/10 ~22:50 UTC
- Contrôle dev boucle 3 (run 37380907642) : tests verts (243), analyse OK, formatage model.dart corrigé (copie aa_fmt). Banc : échéance 94,4 → 95,0 % du max réel, tentatives 96,6 → 95,3 %, échecs non voulus 0,21 → 0,23 %, écart d'effort 1,085 → 1,069, violations 0,0153 → 0,0135, hausses douloureuses 0. Gain mesuré → boucle gardée.
- Exports p3 (ci8) : changement > 10 % pour 07, 12, 13 (05 à 9,7 %) → renote p3 de 05, 07, 12, 13.

## Avancement 05/10 ~23:08 UTC
- Panel p3 (05, 07, 12, 13 sur la boucle 3) : 19 couples sur 68 à 9, min 6, moyenne 7,85 (final_p3.json) ; street_12 à 9 partout. Corrections nécessaires restantes : programme écrit (CP2).
- Notes de relecture du pilotage sur la manche 4 (auteur relecture-documentee-pilotage, 18:55 UTC, arrivées pendant le lot) lues en entier : constats de sécurité côté conduite (street_12 : dips au poids du corps à 5/10, remplaçant lourd, 2×5 → 2×19 à l'affûtage ; street_10 : appuis gardés pendant des semaines à 3/10+).
- Boucle 4 (sécurité) poussée en dev (2713bccf) : coachPainStop 6→5 (Silbernagel 2007 : douleur pendant l'effort sous 5, vérifié sur source secondaire), coachPainRegress 5→4, remplaçants au même seuil ; arrêt : mouvements à contrainte moyenne au premier palier (50 %, 3 RIR, 67,5 %), retirés après 14 jours d'arrêt si encore ≥3/10 ; remplaçant d'une douleur du jour à 70 % ; zone récente : +10 %/séance au plus (Soligard 2016). Tests ajoutés (_painDayChecked, _recentRiseChecked). Docs CONTRAT § 11.16, CHANGELOG, docs/CALIBRAGE_CA2.md (à compléter boucle 4).
- Contrôles full 44ed6d11 et d3c2d77c annulés par la boucle 4.

## Reprise 06/10 ~14:50 UTC (nouvelle session, Opus)
- Ligne ETAT « en cours depuis 2026-10-06 14:52 UTC » poussée.
- Repris : sauvegarde f2cc415 + `packages/kalis_adapt` du contrôle dev 84d5634 (boucle 4 bis : arrêt du poignet complet, échauffement compris, test reporté si > 2/10 dans la semaine, renvoi vers un professionnel hebdomadaire) + formatage aa_fmt.
- Run 37386808307 (84d5634) rouge : (1) param `intensity` nul sur le report d'un test (douleur de la semaine) → corrigé (max de la semaine) ; (2) `_recentRiseChecked` street_12 : sw-traction-neutre 13 → 16 le jour où la douleur commence → zones douloureuses du jour (> 2/10) comptées « récentes » dans session.dart.
- Contrôle dev 7110d279 poussé (boucle 4 ter). Notes p3 de la session précédente perdues (scratchpad) : résumé ci-dessus fait foi (19/68, min 6).
- Scripts ca2-outils : chemins du scratchpad mis à jour.

## 06/10 ~15:35 UTC
- Contrôle dev 72f83ffe (run 37483415804) : tout vert sauf `_recentRiseChecked` — faux positif du test (douleur du 1er jour dite pendant la séance) → test corrigé (règle à partir de la séance qui suit le 1er signalement).
- Exports boucle 4 ter vs boucle 3 (3ea9ca4a) : changés > 10 % : street_01 (15,6 %), street_10 (18,2 %) ; les autres 0 % (03 : 9,6 %).
- Panel p4 (01, 10 ; ca2-outils/notes/p4) : 01 = F8 C7 H7 S6 (p2 : 8/8/8/8) ; 10 = F7 C5,5 H8 S6 (p2 : 6/6,5/7/7). Côté adapt : élastique jamais changé (série remise à zéro par la plage qui monte) ; arrêt du poignet de 4 bis trop large (planche sur parallettes retirée 7 semaines, poussée perdue chez le débutant).
- Boucle 5 (dernière de la partie 0, C9.2) poussée en dev 6da3c852 : appui neutre au poids du corps gardé au 1er palier pendant l'arrêt du poignet, toute charge externe d'appui retirée ; poussée en extension remplacée par un appui neutre au poids du corps (contrainte ≤ moyenne) ; série de l'élastique comptée à plage montante.
- Recherche partie 1 faite : ca2-outils/recherche_partie1.md.
- Plan partie 1 : module endurance (historique cardio depuis replayed.digests ; pic de sortie ≤ 1,10 × plus longue des 30 j ; jour sans : qualité → facile, −30 % si bilan très bas ; reprise après ≥ 7 j : 70 %, ≥ 14 j : 50 % ; WOD mis à l'échelle ; course la veille → +1 RIR bas du corps ; fatigue croisée du cardio dans le modèle forme-fatigue) ; codes de raison nouveaux via kalis_core 0.4.3 (commit séparé) ; vérité cardio et conditionnement dans sim ; banc autres.

## 06/10 ~16:10 UTC
- Dev boucle 5 (6da3c852, run 37488443459) vert. Exports : 01 12,1 % vs b4, autres < 6 %. Passe 5 (01) : 6,5/7/8/7.
- Partie 0 arrêtée (C9.2) : 19/68, min 5,5, moyenne 7,79. CALIBRAGE_CA2.md, CONTRAT § 11.16, CHANGELOG à jour.
- Contrôle FULL c4df7413 poussé (arbre de publication 0.2.3 ; seuls docs Markdown changeront ensuite).
- Ensuite : publication (moteurs + etiquettes kalis_adapt-v0.2.3, kalis_bench-v0.2.2 si libre), DECISIONS (section CA2, ligne datée), ETAT « en cours — partie 0 publiée (0.2.3) », notification ; puis partie 1 (brouillons scratchpad p1/endurance.dart, endurance_truth.dart — copiés dans ca2-outils/p1).

## Reprise 08/10 ~13:05 UTC (nouvelle session, Opus)
- Ligne ETAT « en cours depuis 2026-10-08 13:05 UTC » poussée. Contrôle FULL c4df7413 (run 37493375872) : vert (243 tests).
- Avant publication, lecture complète des notes p5 (street_01) : santé signale une conduite non sûre pendant l'arrêt du poignet (dips assistés gardés au 1er palier avec douleur 4/10 notée, pompes remplacées par des dips négatifs, semaines 7-15). Correction de sécurité (hors boucle de calibrage) : `hotWrist` dans session.dart — arrêt du poignet + gêne ≥ 3/10 dans les 7 jours → seuls les appuis sur parallettes / poignées restent (échauffement compris), remplaçant de poussée limité à ces appuis (`coachWristNeutralSupport`). Test ajouté (coach_rules_test, street_01 poignet 4/10 j42-70).
- Contrôle dev 3b568f5a poussé sur claude/ci-cp-b. Scripts ca2-outils : chemins du scratchpad de cette session ; aa_fmt pris de 6da3c852.
- Ensuite : si vert → exports street_01, 10 (et autres changés > 10 %) → renote ; docs (CONTRAT § 11.16, CHANGELOG, CALIBRAGE boucles 4-5 + correction) ; contrôle full ; publication 0.2.3 + kalis_bench 0.2.2.

## 08/10 ~14:12 UTC
- Dev d2a5ef43 (run 37786847270) : kalis_adapt 244 tests verts, kalis_bench vert (seul l'outil aa_fmt échoue, attendu). Remplaçant d'une poussée pendant un arrêt du poignet limité aux parallettes / poignées (toujours, pas seulement « chaud »).
- Contrôle FULL ea7d517b poussé (arbre de publication 0.2.3 ; seule la doc Markdown changera). CALIBRAGE_CA2 : boucles 4, 5, correction ; table finale à compléter avec la renote de street_01.
- Partie 1 en cours dans le worktree /home/claude/p1 (branche locale ca2-p1, copiée dans la sauvegarde sous p1-arbre/) : kalis_core 0.4.3 (5 codes de raison, générés + formatés à la main, gen_contracts --check « à jour »), kalis_adapt : endurance.dart, étape 2 ter de session.dart (_enduranceDay), fatigue croisée dans replay.dart, params endurance*, sim/endurance_truth.dart + runner, invariants E1-E3 (support.dart checkEndurance), profils course dans les propriétés, test/endurance_test.dart, CONTRAT § 12 ; kalis_bench : endurance_export.dart (section des trajectoires).
- Sources partie 1 vérifiées : ca2-outils/recherche_partie1.md.

## 08/10 ~15:15 UTC
- Relecture indépendante du code 0.2.3 (Opus) : 12 constats, tous corrigés (deux arbres) ; test d'arrêt gardé ajouté. Dev 74404ad9 (run 37792576775) : 245 tests verts.
- Contrôle FULL d9029a47 poussé (publication 0.2.3, en cours).
- Passe 6 (street_01, 03, 10 ; notes dans ca2-outils/notes/p6) : 01 7/7,5/7/7 ; 03 6,5/6,5/6,5/6 ; 10 7/5/7/6,5. Final partie 0 : 19/68 à 9, min 5, moyenne 7,76 (CALIBRAGE_CA2 à jour).
- Page de relecture : 504 notes, aucune du propriétaire, rien de nouveau depuis la manche 4.
- Partie 1 (p1) : + règle d'élastique « marge large » (SlotMark.wideMargin, coachAssistWideRir 2) demandée par la passe 6 ; versions kalis_adapt 0.3.0, kalis_bench 0.2.3, kalis_core 0.4.3 ; CHANGELOG. panel.py build_autres prêt.
- Suite : full vert → publication 0.2.3 (moteurs, etiquettes kalis_adapt-v0.2.3 et kalis_bench-v0.2.2, DECISIONS, ETAT, notification) ; puis contrôle dev de p1.

## 08/10 ~15:35 UTC
- Relecture de bureau de la partie 1 (Opus, sans SDK) : 21 constats ; corrigés dans p1 : export (id nul), copyWith (null efface, unset garde !), douleur de jambe à 3/10 lue sur l'état, séances comptées et séries utilisables (E2), suite de jours durs, scaled (inchangé détecté, calories, cibles par série retirées), plafond de course (note seulement si changement, tests exclus), pas de cumul avec 1 quinquies et l'étape 2, E1 selon la base d'intensité, tests d'endurance assouplis, zone de surcharge séparée, calories dans la vérité, export faite/écrite comparable, docs. Reste : fixture du propriétaire et docs générés (PROPRIETAIRE.md, MESURES.md, campagne.json) à reprendre de ci-out après le premier contrôle de p1.

## 08/10 ~17:10 UTC
- PUBLIÉ : kalis_adapt 0.2.3 + kalis_bench 0.2.2 (moteurs ff22faa9, etiquettes/…, run full 37796701628). DECISIONS CA2.1-CA2.6, ETAT « en cours — partie 0 publiée », notification envoyée.
- p1 rebasé sur ff22faa9 (git reset, arbre conservé). Dev p1 3c0539bb (run 37811408880) : TOUT VERT (core 328, adapt 250, bench 65, plan 226 ; format OK). Documents régénérés recopiés (MESURES, campagne.json, PROPRIETAIRE, fixture).
- Panel q1 (autres, 10 profils × 4 écoles, 12 appels) lancé sur les exports du run 37811408880 (ci-out c942720). Street : exports quasi identiques (≤ 3,7 %), notes de la partie 0 gardées (règle d'économie).
- Outils : ca2-outils/ci_p1.sh (contrôle depuis /home/claude/p1).

## 08/10 ~17:30 UTC
- Panel q1 (autres, sur dev 3c0539bb) : 40 couples, 0 à 9, min 3, moyenne 5,41 (base 0.1 de CR : moyenne des moyennes ≈ 5,1). Corrections nécessaires : presque toutes sur le programme écrit (kalis_plan 0.2.2, chemin 0.1 : pas d'affûtage ni d'échéance placée, tests de distance maximale, pas d'allures) ; côté conduite : tests de course trop longs → corrigé (test borné converti en course bornée).
- Relecture documentée street (2 sous-agents, notes dans ca2-outils/notes/reldoc_p1) : 01 5, 03 4, 06 6, 07 7, 08 6, 10 5, 12 7. Conduite : élastique jamais changé (série repère qui remettait la série à zéro) → corrigé ; sous-dosage de dips après un mauvais jour (06, 08), estimation du muscle-up trop basse (07) → non traités (limites).
- Contrôle FULL p1 5f9d67d5 poussé (0.3.0 : endurance + test borné + élastique série repère + campagne d'endurance).
- Reste : relecture documentée « autres » sur les exports du full, manche 5 de la page (exports + notes), LIVRAISON_CA2, DECISIONS, ETAT « à valider », page de suivi, publication 0.3.0 + kalis_core 0.4.3 (commit séparé) + kalis_bench 0.2.3, notification.
