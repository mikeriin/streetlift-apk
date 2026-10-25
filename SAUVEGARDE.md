# Sauvegarde KB6 (session du 25/10/2026, début 07:22 UTC)

Base : `main` bb320350 (dev7.7.2). Branche locale `kb6`.

## Fait
- Paquet `kalis_adapt` 1.0.8 copié à l'octet de `etiquettes/kalis_adapt-v1.0.8` (lib, assets/koach, pubspec) ; asset `koach_params_1_0_9.json` (SHA-256 1a59e675…) ; `pubspec.lock` kalis_adapt 1.0.8 ; tests d'empreinte mis à jour (kb1 : 57 fichiers, 5dbdd56c…).
- Version 7.8.0+155 (pubspec, kVersion, tests G2/G3/KS1A/KM3/KB1/KB5, Python).
- Bilan versé `applique: false` en écrit gardé (`_koachBilanVerse`, `koachBilanNonApplique`) ; ligne de la carte du bilan (`koachTexteFormeNotee`) ; baisse de cible après la 1re série dite (`koachBaisseCible`, `_koachBaisseEcritGarde` dans `koachReasonLine`).
- Remplacer pour aujourd'hui : `dayReplaceOptions` (API `remplacants`), `dayMissingChoices`, `dayDepartFor`, écran groupé + « Pourquoi ? » + « Il me manque : », recherche en dessous ; `remplace` dans `plan(seance)` (`koachLigneRemplacee`, grilles/zones du remplaçant) ; séance commencée sans série : `koachRecommencerPourChangement` (refactor de `koachBilanChoose` → `_koachRecommencer`) ; sinon cible de départ (`cible` du changement, `daySetsAtDepart`).
- Tests : `test/kb6_koach109_test.dart`, `test/ui_kb6_capture_test.dart` ; RV4 bilan haut mis à jour.
- Formatage local : dart 3.13.7 (conda) + `.dart_tool/package_config.json` minimal (languageVersion 3.10) = même résultat que la CI.

- Contrôle rapide vert (run 40175790392, 17 tests KB6) ; cible émulateur KB6 écrite et inscrite ; cible RV4 adaptée (recherche sous les propositions, séries au format gardé) ; SUIVI_PROJET.md, CLAUDE.md.
- Contrôle complet `claude/ci-3d` run 40176500592 sur 811408ff (lancé 08:24) : contrôles, tests, paquets verts ; émulateur en cours.

## Reste
- Résultat émulateur, publication main (commit dev7.8.0), build signé, livraison, ETAT_CP, notification.

## 13:40 UTC
- Run 40176500592 (811408ff) : contrôles, tests, paquets verts ; émulateur annulé à 300 min (pertes de VM) : KB6 a/b, RV4 a/b et la plupart des cibles vertes ; KB1 a rouge (attendu « 1.0.8-ref.1 » dans `integration_test/koach_kb1_test.dart`, corrigé) ; jamais lancées : CU, G1-G10, M7, M8, mesure.
- Nouveau contrôle complet sur 1aa67411 (seule la cible KB1 change).
