# Sauvegarde KS1c1 — 0 violation sur les saisons des profils ajoutés (`kalis_plan` 0.4.1)

Session Fable 5.1, effort maximal, démarrée le 16/10/2026 à 02:25 UTC (message sans ligne « Lot : » ; KS1c1 seul lot moteur « à faire », la session Opus lancée le 15/10 vers 23:45 n'avait pas réservé la ligne). Base `moteurs` 2d3a5766 (KM1c3). Contrôle `claude/ci-cp-b`. Pas de SDK Dart dans la session (storage.googleapis.com refusé par le proxy) : mise au point sur la CI par des commits « KS1c1 contrôle (dev) » à arbre réduit (`pk/` + `packages/aa_ks1c1`, script `scratchpad/ks1c1/pousser_ci.sh`).

## Fait

- Ligne KS1c1 « en cours » poussée (`pipeline` 9c72e4d4).
- Lecture : prompt KS1c1, LANCEMENTS, C17.12, LIVRAISON_KS1 (§ 1-3, § 7), `kalis_bench` (safety.dart : `charge_trop_vite` à schéma égal 5 %/semaine, `volume_trop_vite` par groupe : max(réf × 1,2 ; réf + 2) sur les trois semaines précédentes), `kalis_plan` (`_fitLoads`, `_fitVolume`, `_limit`, `seed`, `prescribeBlock`, `nextBlock`, `restructure`), `kalis_adapt/sim/runner.dart` (replan sur `ProfileChange` : `previous: block` entier).
- **Cause 1 établie (charge après échéance avancée)** : à la réécriture du bloc (`nextBlock` avec `previous` = bloc en cours), le prescripteur est amorcé avec les 4 semaines écrites du bloc précédent alors que 2 seulement ont été servies ; la borne de hausse lit la semaine 4 jamais faite (+9,3 % au squat de S9 à S10 sur `ks_01`). **Correction** : `servedWeeksOf` / `servedBlockRequest` dans `engine.dart` (bloc précédent tronqué aux semaines entières entre son début et `startDate`, au moins 1), appliquée dans `KalisPlan.nextBlock` avant les deux chemins ; exportées ; test `coach_test.dart` groupe « KS1c1 — échéance avancée en cours de bloc ».
- Dev CI : `packages/aa_ks1c1` (analyse, format, `coach_test.dart`, diag des saisons des profils ajoutés avec le détail des semaines en cause) ; premier push 47778f7c (02:50 UTC environ).

## Fait (suite)

- Run 38841712363 (bb7d3d72) : correction 1 vérifiée — 0 `charge_trop_vite` sur `ks_01` à `ks_03` (échéance avancée) ; diag de `ks_test_ppl6` douleur_epaule lu.
- **Cause 2 établie** : les deux `volume_trop_vite` (lombaires S18 7,5/7,0 ; fessiers S19 17,0/16,8) suivent des propositions « volume » (+1 série sur le soulevé de terre roumain) appliquées par le moteur d'évolution aux revues des semaines 16 et 17 (`run.proposals` : 16:volume 17:volume) ; `kalis_adapt/lib/src/review.dart` `_upFits` ne vérifie que le plafond hebdomadaire du groupe, pas la rampe (max(réf × 1,2 ; réf + 2) sur les trois semaines précédentes) ; `kalis_plan` ne voit pas ces prescriptions (`applyProposal` remplace les prescriptions directement). Hors périmètre (prompt : ni `kalis_adapt`) : documenté, test `kalis_bench/test/ks1c1_test.dart` qui le prouve (chaque violation restante suit une proposition volume du même bloc), recommandation au pilotage.
- **Constat sur le banc complet** (saisons.json des contrôles complets, couple cx, 72 000 saisons) : KM2c1 (`kalis_plan` 0.3.1) 854 violations réalisées (830 volume_trop_vite), KS1 1 262 (+408 : `charge_trop_vite` 1 → 469, `street_12` changement_discipline 467 — régression de KS1 non vue par sa livraison, même cause que la correction 1 ; seed 0 : 2 violations `street_12` changement_discipline dans saisons/SECURITE.md du run 38804692527). Le critère « 0 sur 27 × 100 × 3 × 10 » n'était donc tenu ni en 0.3.1 ni en 0.4.0.
- `kalis_plan` 0.4.1 (version, CHANGELOG, CONTRAT § 12.9 et § 12.16), `kalis_bench` 0.5.1 (campagne `runSeasonCampaign` sur `profiles` + `profiles_ks`, `seasonProfileDirs`, test `ks1c1_test.dart`, CHANGELOG).
- Push dev f7f1ab50 : analyse, format (fichiers formatés rendus dans `ci-out/packages/aa_ks1c1/formatted/`), coach_test, ks1c1_test, diag sur les 34 profils.

- Relecture indépendante (Opus) : 0 bloquant, 2 majeurs (M1 note `pain_return` du bloc tronqué → recalculée dans `servedBlockOf` ; M2 test des propositions volume → `changes > 0`, `found` non vide), 9 mineurs (m1 doc chemin 0.1, m2 « API étendue », m3 `createPass1/2` tronquent aussi (`servedPlanRequest`), m4 règle de `startDate` documentée § 12.9, m5 `weeks.length`, m6 cas limites testés, m8 unicité des clés + docs du banc, m9 source des 2 violations `street_12` citée ; m7 laissé). Run dev 7c6a87b4 vert (analyse, format, coach_test 58, ks1c1_test 4, diag 2 violations restantes sur 34 profils).
- Commit `moteurs` 76605c2b (sur 2d3a5766) poussé en arbre complet sur `claude/ci-cp-b` : **contrôle complet en cours** (~1 h 40 avec la campagne des 34 profils).

- Contrôle complet run 38843890798 (76605c2b) : kalis_bench, kalis_adapt, kalis_core, kalis_quest verts ; kalis_plan rouge sur `docs_test` seulement (ligne de version de `docs/PROFILS_TYPES.md` et `docs/COMPARAISON_L10.md`) → fichiers régénérés recopiés depuis `ci-out`, commit amendé 4c11fea0, **second contrôle complet en cours** (poussé 05:30 UTC, fin vers 07:45). Résultats du banc (code identique) exploités : STRUCTURE.md identique à KS1 sauf saisons 6 → 2 ; campagne 34 profils : 27 profils 628 violations (0.3.1 : 854, KS1 : 1 262 ; charge 469 → 0, volume 770 → 609, changement_discipline 691 → 70, echeance_avancee 30 → 17, autres scénarios identiques), 7 ajoutés 703 (toutes volume, ks_test_ppl6 572). Livraison, DECISIONS et page rédigées dans le scratchpad (reste [[RUN]], [[FIN]]).

- Second contrôle complet run 38856060639 (4c11fea0) **vert** (kalis_plan 317 tests, kalis_bench 190, STRUCTURE identique hors saisons 6 → 2). Au push de `moteurs` : KM2c2 livré entre-temps (4910ec13, `kalis_adapt` 1.0.2, `kalis_bench` 0.5.1) → rebase, conflit CHANGELOG résolu (0.5.2 KS1c1 au-dessus de 0.5.1 KM2c2), version 0.5.2 partout ; commit eae158b8 poussé sur `claude/ci-cp-b` : **troisième contrôle complet en cours** (08:20 UTC, fin vers 11:10). Les chiffres de la campagne seront relus sur ce run (kalis_adapt 1.0.2 : a priori sans effet sur le couple cx).

## En cours

- Attente du run de 47778f7c : vérifier la correction 1 (plus de `charge_trop_vite`), lire le diag de `ks_test_ppl6` douleur_epaule (lombaires S18 7,5/7,0 ; fessiers S19 17,0/16,8) pour établir la cause 2 (hypothèses : `restructure` amorcé sans le bloc précédent (`previous: []`), reprise progressive et `_fitReturn`, arrondi des demi-séries des muscles secondaires).

## Reste à faire

- Cause 2 et correction ; tests ; banc complet élargi aux 7 profils ajoutés sur toutes les graines (`runSeasonCampaign` : `profiles_ks`, `kalis_bench` 0.5.1) ; aucun recul des critères KS1 ; `kalis_plan` 0.4.1 (CHANGELOG, contrat, version) ; relecture ; contrôle complet `claude/ci-cp-b` ; étiquettes ; LIVRAISON_KS1c1 (pipeline + projet) ; ETAT « livré » ; page de suivi ; notification.

## Décisions prises

- Troncature au niveau de `KalisPlan.nextBlock` (les deux chemins, sans changement d'API : les semaines servies se déduisent de `startDate` et de `previous.pass1.startDate`).
