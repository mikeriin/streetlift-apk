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

## En cours
- Corrections d'après la CI rapide.

## Reste
- Tests guidés (modèle + écran + carte accueil), Compléter mon profil (store, carte, Réglages), tests Dart, test d'intégration CU, docs CI_GP, README, SUIVI, CI rapide puis ci-3d, main, build signé, livraison.
