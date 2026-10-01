# LIVRAISON G1 correction 1 — Démarrage repris après fermeture (6.0.1+95)

- **Retour du propriétaire (01/10/2026)** : « Fermer entièrement l'app pendant [le démarrage] fait recommencer à la toute première question. Sinon RAS. »
- **main** : 10fed1d (depuis b3a3d73). **CI GP** : run 36822285302 vert (1 022 tests Dart, 10 du mode dev, émulateur G1 a + b). Build signé : run 36823406874.

## Correction
- Brouillon du démarrage (étape et réponses : année, poids, objectifs, jours, durée, lieux, repères, consentement, réponses, gênes, mode et ton) gardé à chaque changement d'étape et au passage en arrière-plan, repris à la réouverture.
- Clé `profile_flow_draft_v1` de la session active (personnelle ou de test), hors sauvegarde ; effacée à l'enregistrement du profil et par « Supprimer les données ».
- Moins de 18 ans : aucun brouillon gardé (celui des étapes précédentes est effacé) ; le test L8 « aucune écriture » reste inchangé.
- Test : `test/g1c1_brouillon_profil_test.dart` (fermeture en cours d'étape, reprise, fin du démarrage, moins de 18 ans, hors sauvegarde).

## À tester
Session de test (5 appuis sur le logo) : avance de quelques questions, ferme complètement l'app, rouvre : reprise à la même question, réponses gardées.

## Limite
La saisie d'un champ texte en cours sur l'étape affichée est gardée seulement si l'app passe en arrière-plan (fermeture normale) ; un arrêt brutal reprend à l'étape avec les réponses validées.
