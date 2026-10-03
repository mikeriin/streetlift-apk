# Sauvegarde CU (voie App, Opus 5.5)

Base : main 9f6b80b (dev6.7.0). Arbre de travail = cette branche (sans .github).

## Fait
- kalis_core 0.4.0 récupéré (etiquettes/kalis_core-v0.4.0) dans packages/kalis_core.
- lib/profile_v3.dart : modèle (DraftV3, conditions, élagage, points faibles, propositions).
- athlete_profile.dart : étapes v3 (experience, recovery), brouillon v3, build schéma 3, migration v2→v3 (AthleteRecord.fromJson), rubriques.
- content_pack.dart : chargement de assets/catalog/parcours_v3.json (copie du paquet).
- Version 6.8.0+107, tests de version mis à jour.

## Fait (suite)
- athlete_profile_flow.dart + part athlete_profile_flow_v3.dart (écrans v3, éditeurs, mode « compléter »).
- guided_tests.dart (propositions, conversion, écrans, carte d'accueil), profile_completion.dart (carte), store (skipped, invite, tests).
- test/cu_profil_v3_test.dart ; g6_profil_test adapté ; integration g6/g7 adaptés (écran experience, recovery).
- Branche claude/ci-cu-rapide (rapide.yml) : essai 1 poussé (d0b7f23).

## Fait (suite 2)
- CI rapide essais 1 à 4 (analyse verte depuis l'essai 3) ; textes 0.4 des codes de raison (lib/plan/reason_texts_0_4.dart) ; check_claims : champs affichés du parcours seulement.
- Docs : README, SUIVI_PROJET, docs/CI_GP.md (section CU) ; ci3d_drive.sh (cible profil_cu_test, G10 sous CI3D_TOUT) ; ci-3d.yml (APK de test précompilé sur la cible CU).
- claude/ci-3d : essai 1 poussé 12:03 UTC (89d64ae).

## Terminé
- Lecture des résultats ci-3d (captures émulateur à regarder), corrections.

## Reste
- main (dev6.8.0) + build signé ; LIVRAISON_CU.md ; DECISIONS_CP section CU ; ETAT_CP (à valider) ; page de suivi (partie Calibrage) ; notification.

- LIVRÉ : main 6467bc2 (dev6.8.0), build 37126824436, pipeline d96272b (ETAT à valider), page de suivi v23.
