# Sauvegarde RV1

## Fait
- 21/10 12:06 UTC : ETAT « en cours ». Base main 0e063fde (dev7.4.0).
- Revue par 9 sous-agents Opus (zones : séance ; programme importé + plan ; colle Koach ; magasin/sauvegarde ; adaptation 0.x/bilan ; accueil/stats/jeu ; réglages/kit/thèmes/notifications ; profil athlète ; paquets en lecture). Constats bruts : `RV1_CONSTATS.md` (à vérifier un par un).

## Décisions
- 20,41 kg : grille poulie par défaut de `kalis_adapt` en livres (2,5 lb) ; correctif de colle : `athleteProfileForEngines` ajoute `LoadIncrement(cable, 2,5 kg, min 2,5)` si le profil n'en donne pas (même défaut que `kalis_plan` pass2). Bug de paquet signalé (grid.dart:35).
- Intervalles : une ligne par tour dans les deux cas, ligne importée `asWritten`.

## Reste
- Correctifs + tests, cible émulateur `integration_test/rv1_parcours_test.dart`, ci-3d, main dev7.5.0, build, livraison.

## Avancement 13:12 UTC
- Correctifs faits (commit local f969c2a0 sur base main 0e063fde) ; contrôle rapide `claude/ci-ui-rv1-rapide` vert (run 39604545643, 28 suites touchées + rv1).
- Contrôle complet `claude/ci-3d` lancé sur 965e6fd9 (13:10 UTC) ; résultats attendus vers 15:25 UTC.
- Reste : lire ci-out (checks, émulateur, captures rv1_*), corriger si rouge ; publier sur main (avance rapide de 0e063fde), build signé, LIVRAISON_RV1.md (pipeline + projet), ETAT « à valider », page de suivi, notification.

## Avancement 19:20 UTC
- Run 39633654254 (arbre b6bf7e7e) : contrôles et tests verts, build vert (39633654215), cibles RV1 a et b vertes (38 captures chacune, sauvegarde réimportée à l'identique hors `lastLevel` voulu) ; aucun test rouge ; job coupé à 175 min (VM injoignable pour KB1 a, KB3 a, CIF b ; CI1g et suivantes non atteintes).
- Délai du job porté à 300 min (commit 1676c9ee) ; contrôle complet relancé 19:18 (commit ci-3d e0337102).
- Relecture indépendante faite et traitée ; captures lues (deux défauts PR2 corrigés : titre du bilan « S15-J1 », « Fin du programme (S24) »).
- Reste : résultat du run, publication main, build, livraison (brouillon LIVRAISON_RV1.md), page de suivi (scratchpad/page.py), ETAT, notification.
