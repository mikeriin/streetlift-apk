# Sauvegarde KB2 correction 1 (dev7.2.2)

Base : main 60e17e2b. Travail sur la branche locale `travail` (même contenu que cette sauvegarde, sans `.github/`).

## Fait
- Cause du constat 4 établie (sonde `test/kb2c1_sonde_test.dart`, run CI UI 39226750025) : `koach.retour_gradue` (groupe « chest », limite 55,8 séries) retire le muscle-up lesté et la traction lestée (0 série) ; l'application retirait en silence les lignes absentes du servi (`adaptDay`). Même résultat avec ou sans alerte : « Plus tard » n'y est pour rien.
- Popup : libellés, codes, message d'entrée (`koach1_widgets.dart`).
- Garde de la séance (`koachGardeSeance`), réponse refusée (état `ecrite`), arrêt d'urgence ramène la séance à l'écrit.

## Fait aussi
- Relecture indépendante traitée (journal coupé sur échec, endurance_retrait motivé, état ecrite périmé le lendemain, ligne à 0 série par la planification laissée retirée).
- Version 7.2.2, tests test/kb2c1_*, cible integration_test/koach_kb2c1_test.dart inscrite dans tools/ci3d_drive.sh ; rapide vert (19 tests).

## Reste
- Tests unitaires et widget `test/kb2c1_*`, cible émulateur `integration_test/koach_kb2c1_test.dart` + `tools/ci3d_drive.sh`.
- Version 7.2.2, contrôle complet ci-3d, main, build signé, livraison, ETAT, page de suivi, notification.
