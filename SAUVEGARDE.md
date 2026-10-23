# Sauvegarde KB5 (Koach 1.0.8 et kalis_plan 0.4.3, dev7.7.0)

Session du 23/10/2026, début 04:37 UTC. Branche de travail locale `kb5` (base `main` ae9d6e1a).

## Fait
- Paquets copiés à l'octet (kalis_adapt lib/assets/pubspec de etiquettes/kalis_adapt-v1.0.7, kalis_plan entier de etiquettes/kalis_plan-v0.4.3) ; asset koach_params_1_0_8.json + fiches 1.0.1 ; pubspec 7.7.0+152, pubspec.lock (versions), kVersion, tests de version.
- lib/koach1/koach_groupes.dart : koachGroupesServis (= ko.groupesServis), koachGroupesDeLaSeance (groupe du moteur si lignes inchangées, sinon recalé), koachTechniqueCoherente (= ko.techniqueCoherente).
- koach1_store.dart : `groups` passés à plan(seance), groupes de la séance servie recalés, diag `groupesRecales` ; aperçu : technique et groupes recalés ; volume_semaine dans kKoachRaisonsDeSeance ; retirée de l'en-tête pour une ligne PR8.
- test/kb5_koach108_test.dart.
- Contrôle rapide vert (run 39904076619, 16 tests KB5, analyse, format) ; relecture indépendante traitée. Contrôle complet claude/ci-3d run 39905071701 (commit 7a2bbc68, arbre b619f51c = kb5 7466e453) en cours depuis 05:19 UTC.

## Reste
- Résultat du contrôle rapide ; cible émulateur integration_test/koach_kb5_test.dart (+ ci3d_drive.sh) ; SUIVI_PROJET.md, CLAUDE.md ; relecture indépendante ; contrôle complet claude/ci-3d ; publication main, build signé, livraison, ETAT, page de suivi, notification.
