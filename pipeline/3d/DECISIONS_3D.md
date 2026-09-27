# Décisions — pipeline mannequin 3D

## Tranchées par le propriétaire (27/09/2026)
Voir `PIPELINE_3D.md` §2 (réponses 1a à 17a). Réglages d'affichage 3D activés par défaut : « Nom du muscle au toucher », « Os visibles ».
Modèle Claude : Opus 5.5 pour tous les lots, effort accru demandé sur M5 (squelette) et M12 (figures).

## Décisions prises par défaut par les lots
(chaque lot ajoute sa section : décision, raison, réversibilité)

### M1 (27/09/2026) — socle 3D (livré, 5.0.0)
- Flutter 3.47.5 (Dart 3.13.4, dernière stable), flutter_scene 0.23.0. Réversible (version épinglée).
- minSdk 21 → 24 : Flutter 3.47 refuse < 23 et vise 24 (conséquence directe de la décision « Flutter ≥ 3.47 ») ; Android 5 et 6 ne reçoivent plus de mise à jour. `verify_android_artifacts.py` attend désormais 24.
- Gradle 8.13 → 8.14.3, Kotlin 2.2.10 → 2.3.20 (minimums de Flutter 3.47), AGP 8.12.1 gardé (AGP 9 imposerait la nouvelle DSL) ; `android.newDsl=false`, `android.builtInKotlin=false` ajoutés par le migrateur Flutter. Identifiant et signature inchangés.
- Dépendances : versions majeures conservées, verrou régénéré. Dépréciations 3.47 migrées sans changement de comportement (RadioGroup, initialValue, onReorderItem, TickerMode.getValuesNotifier, isSemantics).
- flutter_scene 0.23 : basculer `autoTick` sur une `SceneView` montée provoque une erreur (un seul ticker par vue). L'écran Moteur 3D garde un rendu continu ; les lots à scène fixe devront monter une vue dédiée (ou changer de `key`) pour passer en rendu à la demande.
- Fond de scène dessiné dans la scène (ciel uni) : sur fond transparent le halo disparaît. Mappage des tons « linéaire » pour garder les couleurs de la charte ; halo seulement en thème sombre (en clair, le fond dépasserait le seuil du halo).
- CI : émulateur API 35 x86_64 `-gpu swangle_indirect` (OpenGL ES). Flutter GPU y fonctionne (« Compatible », rendu vérifié), mais le rendu logiciel est très lent (≈ 1 image/s) : les images/s de la CI ne représentent pas un téléphone.
- `test/visual_capture_test.dart` (captures facultatives) échoue déjà sur main avant M1 (onglet STATS réorganisé depuis 2.5.0) : non corrigé, hors lot.

- `integration_test` hors du `pubspec.yaml` livré : Flutter 3.47 le référençait dans le registre des plugins de l'APK release (build signé n° 95 en échec). La CI 3D l'ajoute dans sa copie de travail ; `integration_test/` et `test_driver/` exclus de l'analyse principale (comme `tools/perf_device/`). La CI 3D construit aussi un APK profile (même jeu de plugins que la release).
- Bibliothèques natives compressées dans l'APK (`useLegacyPackaging = true`) : avec minSdk 24, AGP les rangeait non compressées (APK universel 73,5 Mo). APK signé 5.0.0 : 35,0 Mo (4.3.1 : 30,3 Mo), +4,7 Mo, dans l'objectif ≤ 10 Mo.
- Blocage CI du 27/09 (quota Actions) levé par le propriétaire : dépôt rendu public.
- CI 3D : `FLUTTER_BEFORE` = version Flutter du ZIP de main (3.47.5 désormais) pour les rendus de référence.

## En attente du propriétaire
- Réponse à M1 : Réglages › À propos › Moteur 3D sur ton téléphone — « Compatible » ou non, et les images/s. Si compatible avec ≥ 45 images/s, le pipeline reprend avec M2 ; sinon options (repli logiciel, autre moteur, arrêt) proposées ici.
