# Sauvegarde KB6 (session du 25/10/2026, début 07:22 UTC)

Base : `main` bb320350 (dev7.7.2). Branche locale `kb6`.

## Fait
- Paquet `kalis_adapt` 1.0.8 copié à l'octet de `etiquettes/kalis_adapt-v1.0.8` (lib, assets/koach, pubspec) ; asset `koach_params_1_0_9.json` (SHA-256 1a59e675…) ; `pubspec.lock` kalis_adapt 1.0.8 ; tests d'empreinte mis à jour (kb1 : 57 fichiers, 5dbdd56c…).
- Version 7.8.0+155 (pubspec, kVersion, tests G2/G3/KS1A/KM3/KB1/KB5, Python).
- Bilan versé `applique: false` en écrit gardé (`_koachBilanVerse`, `koachBilanNonApplique`) ; ligne de la carte du bilan (`koachTexteFormeNotee`) ; baisse de cible après la 1re série dite (`koachBaisseCible`, `_koachBaisseEcritGarde` dans `koachReasonLine`).
- Remplacer pour aujourd'hui : `dayReplaceOptions` (API `remplacants`), `dayMissingChoices`, `dayDepartFor`, écran groupé + « Pourquoi ? » + « Il me manque : », recherche en dessous ; `remplace` dans `plan(seance)` (`koachLigneRemplacee`, grilles/zones du remplaçant) ; séance commencée sans série : `koachRecommencerPourChangement` (refactor de `koachBilanChoose` → `_koachRecommencer`) ; sinon cible de départ (`cible` du changement, `daySetsAtDepart`).
- Tests : `test/kb6_koach109_test.dart`, `test/ui_kb6_capture_test.dart` ; RV4 bilan haut mis à jour.
- Formatage local : dart 3.13.7 (conda) + `.dart_tool/package_config.json` minimal (languageVersion 3.10) = même résultat que la CI.

## Reste
- Contrôle rapide `claude/ci-ui-kb6-rapide`, corrections.
- Cible émulateur `integration_test/kb6_remplacement_test.dart` + `tools/ci3d_drive.sh`.
- SUIVI_PROJET.md, CLAUDE.md (protocoles), contrôle complet `claude/ci-3d`, publication main, build signé, livraison.
