# Sauvegarde CU (voie App, Opus 5.5)

Base : main 9f6b80b (dev6.7.0). Arbre de travail = cette branche (sans .github).

## Fait
- kalis_core 0.4.0 récupéré (etiquettes/kalis_core-v0.4.0) dans packages/kalis_core.
- lib/profile_v3.dart : modèle (DraftV3, conditions, élagage, points faibles, propositions).
- athlete_profile.dart : étapes v3 (experience, recovery), brouillon v3, build schéma 3, migration v2→v3 (AthleteRecord.fromJson), rubriques.
- content_pack.dart : chargement de assets/catalog/parcours_v3.json (copie du paquet).
- Version 6.8.0+107, tests de version mis à jour.

## En cours
- athlete_profile_flow.dart + part athlete_profile_flow_v3.dart (écrans v3).

## Reste
- Tests guidés (modèle + écran + carte accueil), Compléter mon profil (store, carte, Réglages), tests Dart, test d'intégration CU, docs CI_GP, README, SUIVI, CI rapide puis ci-3d, main, build signé, livraison.
