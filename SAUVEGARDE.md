# Sauvegarde KB5 (Koach 1.0.8 et kalis_plan 0.4.3, dev7.7.0)

Session du 23/10/2026, début 04:37 UTC. Branche de travail locale `kb5` (base `main` ae9d6e1a).

## Fait
- Paquets copiés à l'octet (kalis_adapt lib/assets/pubspec de etiquettes/kalis_adapt-v1.0.7, kalis_plan entier de etiquettes/kalis_plan-v0.4.3) ; asset koach_params_1_0_8.json + fiches 1.0.1 ; pubspec 7.7.0+152, pubspec.lock (versions), kVersion, tests de version.
- lib/koach1/koach_groupes.dart : koachGroupesServis (= ko.groupesServis), koachGroupesDeLaSeance (groupe du moteur si lignes inchangées, sinon recalé), koachTechniqueCoherente (= ko.techniqueCoherente).
- koach1_store.dart : `groups` passés à plan(seance), groupes de la séance servie recalés, diag `groupesRecales` ; aperçu : technique et groupes recalés ; volume_semaine dans kKoachRaisonsDeSeance ; retirée de l'en-tête pour une ligne PR8.
- test/kb5_koach108_test.dart.
- Contrôle rapide vert (run 39904076619, 16 tests KB5, analyse, format) ; relecture indépendante traitée. Contrôle complet claude/ci-3d run 39905071701 (commit 7a2bbc68, arbre b619f51c = kb5 7466e453) en cours depuis 05:19 UTC ; job « Contrôles, tests et build debug » VERT (05:35), émulateur en cours. Brouillon de livraison dans la sauvegarde (LIVRAISON_KB5_brouillon.md).

## Reste
- Résultat du contrôle rapide ; cible émulateur integration_test/koach_kb5_test.dart (+ ci3d_drive.sh) ; SUIVI_PROJET.md, CLAUDE.md ; relecture indépendante ; contrôle complet claude/ci-3d ; publication main, build signé, livraison, ETAT, page de suivi, notification.

## Avancement 07:42 UTC
- Contrôle complet n°1 (run 39905071701) : contrôles, tests Dart, paquets VERTS ; émulateur : toutes les cibles vertes sauf KB5 (raison cherchée sur l'écran : elle est dans la feuille ⓘ de la carte compacte PR7). Cible corrigée (tap `<id>-instructions`).
- Contrôle complet n°2 : run 39919503229, commit 51885773, arbre 31cade4f = kb5 72a6cf1f. À sa fin (vert) : publier main (avance rapide de ae9d6e1a si main n'a pas bougé, sinon rebase), build signé, livraison (brouillon dans LIVRAISON_KB5_brouillon.md), ETAT « à valider », page de suivi, notification.

## Avancement 10:40 UTC
- Contrôle complet n°2 (run 39919503229, arbre 31cade4f) : contrôles, 1 273 tests Dart, mode dev, paquets VERTS ; émulateur : KB5 a et b VERTS (raison lue dans la feuille ⓘ), RV2, RV1c1, RV1, KB4, CU, G*, M* verts ; à partir de KB3 b : « No supported devices found » (perte de la VM). Ces cibles étaient vertes au run 1 (même lib/).
- Relance des jobs en échec du run 39919503229 demandée à 10:35 UTC (une fois). Captures KB5 du run 2 dans /tmp (non sauvegardées).

## Fin 13:05 UTC
- Publié : main 83a0170e ; build signé 39954106798 vert (APK 12502512401) ; livraison (pipeline + projet), ETAT « à valider » (pipeline 230c9a14), page de suivi republiée (version 69). Lot terminé.
