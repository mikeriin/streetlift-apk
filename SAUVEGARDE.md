# Sauvegarde KS1c1 — 0 violation sur les saisons des profils ajoutés (`kalis_plan` 0.4.1)

Session Fable 5.1, effort maximal, démarrée le 16/10/2026 à 02:25 UTC (message sans ligne « Lot : » ; KS1c1 seul lot moteur « à faire », la session Opus lancée le 15/10 vers 23:45 n'avait pas réservé la ligne). Base `moteurs` 2d3a5766 (KM1c3). Contrôle `claude/ci-cp-b`. Pas de SDK Dart dans la session (storage.googleapis.com refusé par le proxy) : mise au point sur la CI par des commits « KS1c1 contrôle (dev) » à arbre réduit (`pk/` + `packages/aa_ks1c1`, script `scratchpad/ks1c1/pousser_ci.sh`).

## Fait

- Ligne KS1c1 « en cours » poussée (`pipeline` 9c72e4d4).
- Lecture : prompt KS1c1, LANCEMENTS, C17.12, LIVRAISON_KS1 (§ 1-3, § 7), `kalis_bench` (safety.dart : `charge_trop_vite` à schéma égal 5 %/semaine, `volume_trop_vite` par groupe : max(réf × 1,2 ; réf + 2) sur les trois semaines précédentes), `kalis_plan` (`_fitLoads`, `_fitVolume`, `_limit`, `seed`, `prescribeBlock`, `nextBlock`, `restructure`), `kalis_adapt/sim/runner.dart` (replan sur `ProfileChange` : `previous: block` entier).
- **Cause 1 établie (charge après échéance avancée)** : à la réécriture du bloc (`nextBlock` avec `previous` = bloc en cours), le prescripteur est amorcé avec les 4 semaines écrites du bloc précédent alors que 2 seulement ont été servies ; la borne de hausse lit la semaine 4 jamais faite (+9,3 % au squat de S9 à S10 sur `ks_01`). **Correction** : `servedWeeksOf` / `servedBlockRequest` dans `engine.dart` (bloc précédent tronqué aux semaines entières entre son début et `startDate`, au moins 1), appliquée dans `KalisPlan.nextBlock` avant les deux chemins ; exportées ; test `coach_test.dart` groupe « KS1c1 — échéance avancée en cours de bloc ».
- Dev CI : `packages/aa_ks1c1` (analyse, format, `coach_test.dart`, diag des saisons des profils ajoutés avec le détail des semaines en cause) ; premier push 47778f7c (02:50 UTC environ).

## En cours

- Attente du run de 47778f7c : vérifier la correction 1 (plus de `charge_trop_vite`), lire le diag de `ks_test_ppl6` douleur_epaule (lombaires S18 7,5/7,0 ; fessiers S19 17,0/16,8) pour établir la cause 2 (hypothèses : `restructure` amorcé sans le bloc précédent (`previous: []`), reprise progressive et `_fitReturn`, arrondi des demi-séries des muscles secondaires).

## Reste à faire

- Cause 2 et correction ; tests ; banc complet élargi aux 7 profils ajoutés sur toutes les graines (`runSeasonCampaign` : `profiles_ks`, `kalis_bench` 0.5.1) ; aucun recul des critères KS1 ; `kalis_plan` 0.4.1 (CHANGELOG, contrat, version) ; relecture ; contrôle complet `claude/ci-cp-b` ; étiquettes ; LIVRAISON_KS1c1 (pipeline + projet) ; ETAT « livré » ; page de suivi ; notification.

## Décisions prises

- Troncature au niveau de `KalisPlan.nextBlock` (les deux chemins, sans changement d'API : les semaines servies se déduisent de `startDate` et de `previous.pass1.startDate`).
