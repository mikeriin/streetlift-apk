# Sauvegarde CI1h — correction 1 (C15.9)

Base : main 9ef40dad (dev6.11.2). Branche de travail locale ci1h-c1 (contenu de cette sauvegarde, sans .github).

## Fait
- ETAT_CP : ligne CI1h « en cours depuis 2026-10-11 05:30 UTC (correction 1) ».
- Défaut A : `adaptPlanDay` retiré ; `adaptPlannedSession` et `_adaptReprescribe` au jour réel (`_adaptInput` sans `day`).
- Défaut B : `fixedLoadItem` tient séries/répétitions/secondes écrites (sauf douleur, `fixedVolumeLowered` : health_low, sleep_low, time_short, resume_after_break, load_held health*, ou raisons de séance) ; repli charge seule si hors contrat ; `_fixedConstrain` retire `setsReduced` des séries rétablies.
- Version 6.11.3+116 (pubspec, kVersion, tests G2/G3, test python).
- Tests : `test/ci1h_correction1_test.dart` (nouveau), `ci1h_charge_fixe_test.dart` adapté.
- Relecture indépendante (sous-agent) traitée : exceptions par exercice (raisons de la prescription ou de ses ajustements), bilan bas donné au niveau séance seulement, cibles prolongées et technique écrite, retrait d un seul setsReduced.
- CI rapide : `claude/ci-ci1h-c1-rapide` essai 2 poussé (essai 1 : analyse — `!` inutiles —, test nullable).

- Contrôle complet claude/ci-3d lancé (commit de contrôle de6edbc2, arbre f3b6f3c1) ; candidat main e351f274 (parent 9ef40dad, message /tmp). Livraison rédigée (brouillon local).

## Reste
- Lire résultats CI rapide, corriger (format.patch), cause des 11 répétitions (relevés CI1H1|B|cause).
- Contrôle complet claude/ci-3d, main, build signé, livraison, ETAT, page de suivi, notification.
