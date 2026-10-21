# Sauvegarde RV1

## Fait
- 21/10 12:06 UTC : ETAT « en cours ». Base main 0e063fde (dev7.4.0).
- Revue par 9 sous-agents Opus (zones : séance ; programme importé + plan ; colle Koach ; magasin/sauvegarde ; adaptation 0.x/bilan ; accueil/stats/jeu ; réglages/kit/thèmes/notifications ; profil athlète ; paquets en lecture). Constats bruts : `RV1_CONSTATS.md` (à vérifier un par un).

## Décisions
- 20,41 kg : grille poulie par défaut de `kalis_adapt` en livres (2,5 lb) ; correctif de colle : `athleteProfileForEngines` ajoute `LoadIncrement(cable, 2,5 kg, min 2,5)` si le profil n'en donne pas (même défaut que `kalis_plan` pass2). Bug de paquet signalé (grid.dart:35).
- Intervalles : une ligne par tour dans les deux cas, ligne importée `asWritten`.

## Reste
- Correctifs + tests, cible émulateur `integration_test/rv1_parcours_test.dart`, ci-3d, main dev7.5.0, build, livraison.
