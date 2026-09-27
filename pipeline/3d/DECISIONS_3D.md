# Décisions — pipeline mannequin 3D

## Tranchées par le propriétaire (27/09/2026)
Voir `PIPELINE_3D.md` §2 (réponses 1a à 17a). Réglages d'affichage 3D activés par défaut : « Nom du muscle au toucher », « Os visibles ».
Modèle Claude : Opus 5.5 pour tous les lots, effort accru demandé sur M5 (squelette) et M12 (figures).

## Décisions prises par défaut par les lots
(chaque lot ajoute sa section : décision, raison, réversibilité)

### M1 (27/09/2026) — socle 3D (en cours, bloqué par la CI)
- Flutter 3.47.5 (Dart 3.13.4, dernière stable), flutter_scene 0.23.0. Réversible (version épinglée).
- minSdk 21 → 24 : Flutter 3.47 refuse < 23 et vise 24 (conséquence directe de la décision « Flutter ≥ 3.47 ») ; Android 5 et 6 ne reçoivent plus de mise à jour. `verify_android_artifacts.py` attend désormais 24.
- Gradle 8.13 → 8.14.3, Kotlin 2.2.10 → 2.3.20 (minimums de Flutter 3.47), AGP 8.12.1 gardé (AGP 9 imposerait la nouvelle DSL) ; `android.newDsl=false`, `android.builtInKotlin=false` ajoutés par le migrateur Flutter. Identifiant et signature inchangés.
- Dépendances : versions majeures conservées, verrou régénéré. Dépréciations 3.47 migrées sans changement de comportement (RadioGroup, initialValue, onReorderItem, TickerMode.getValuesNotifier, isSemantics).
- flutter_scene 0.23 : basculer `autoTick` sur une `SceneView` montée provoque une erreur (un seul ticker par vue). L'écran Moteur 3D garde un rendu continu ; les lots à scène fixe devront monter une vue dédiée (ou changer de `key`) pour passer en rendu à la demande.
- Fond de scène dessiné dans la scène (ciel uni) : sur fond transparent le halo disparaît. Mappage des tons « linéaire » pour garder les couleurs de la charte ; halo seulement en thème sombre (en clair, le fond dépasserait le seuil du halo).
- CI : émulateur API 35 x86_64 `-gpu swangle_indirect` (OpenGL ES). Flutter GPU y fonctionne (« Compatible », rendu vérifié), mais le rendu logiciel est très lent (≈ 1 image/s) : les images/s de la CI ne représentent pas un téléphone.
- `test/visual_capture_test.dart` (captures facultatives) échoue déjà sur main avant M1 (onglet STATS réorganisé depuis 2.5.0) : non corrigé, hors lot.

## En attente du propriétaire
- **M1 bloqué — GitHub Actions ne démarre plus aucune tâche** depuis le 27/09/2026 vers 18 h 04 (UTC) : les runs 7 (tâche « Publier ») et 8 (toutes les tâches, relancé une fois) échouent en 2 à 7 s sans machine attribuée ni journal, ce qui correspond à un quota de minutes Actions épuisé ou à une limite de dépenses du compte. Sans CI, impossible de contrôler, de pousser sur `main` ni de produire l'APK signé.
  - Options : (a) augmenter la limite de dépenses ou attendre le renouvellement mensuel des minutes, puis relancer la tâche planifiée (M1 reprendra depuis `claude/ci-3d`) ; (b) rendre le dépôt public (minutes gratuites illimitées) ; (c) arrêter le pipeline.
  - Recommandation : (a). État du travail : ZIP complet sur `claude/ci-3d` (commit 8dc6c7d, passage 8) ; au passage 7, contrôles verts (formatage, analyse, 855 tests Dart, Python, build debug) et rendu réel sur émulateur « Compatible » ; restent à confirmer par la CI : la mesure de fluidité corrigée et la capture en thème clair, puis la publication (main, build signé, page de suivi).
