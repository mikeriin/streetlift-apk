# Sauvegarde CI1g

Base : main 9dd09214 (dev6.11.0). Branche de mise au point : claude/ci-ci1g-rapide.

## Fait
- Paquets kalis_plan 0.3.1, kalis_adapt 0.3.1 copiés des étiquettes (identiques), pubspec.lock.
- clearance_first : lib/adapt/clearance.dart (étape bloquante à l'ouverture d'une séance non commencée, carte de rappel sur la page du bilan), AppSettings.medicalClearance (blockId → date), store.clearancePending / confirmClearance.
- Pompe sur barre basse (wristBarPushUp, kWristBarPushUpCue) dans adjustmentText et le panneau du coach ; cause `cap` rédigée ; clearance_first, shoulder_history, knee_shallow en notes de douleur (bouclier).
- Version 6.11.1+114 ; tests test/ci1g_paquets_test.dart ; cible émulateur integration_test/clearance_ci1g_test.dart (ci3d_drive.sh, ci-3d.yml 80 min).

## Reste
- Run rapide vert, contrôle complet claude/ci-3d, docs (CI_GP, README, SUIVI), commit main, build signé, livraison, état, page de suivi, notification.

## Étape 2 (≈ 15:05 UTC)
- Commit candidat b7996b3f (arbre 79bbe549) sur cp-sauvegardes/CI1g-candidat ; contrôle complet poussé sur claude/ci-3d (commit 3c4da716, essai 1).
- Run rapide ciblé vert (ci1g, ci1f, ci1d, ci1c, ci1e, g9, m8 : seul shoulder corrigé ensuite, vert seul). m8_carte_2d en dépassement de délai seulement dans la suite complète du run rapide (vert isolé).
- Reste : lire le résultat du contrôle complet, publier main (avance rapide), build signé, livraison, état, page, notification.
